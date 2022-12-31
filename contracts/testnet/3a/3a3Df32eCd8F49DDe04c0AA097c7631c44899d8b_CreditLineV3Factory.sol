// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Context} from '../../../../@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
  function isTrustedForwarder(address forwarder)
    public
    view
    virtual
    returns (bool);

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[0:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {
  AccessControlEnumerable
} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {
  ERC2771Context
} from '../../../@jarvis-network/synthereum-contracts/contracts/common/ERC2771Context.sol';
import {Context} from '../../../@openzeppelin/contracts/utils/Context.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {SynthereumFactoryAccess} from '../../common/libs/FactoryAccess.sol';
import {
  ILendingCreditLineManager
} from '../../lending-module/interfaces/ILendingCreditLineManager.sol';
import {
  ISynthereumFactoryVersioning
} from '../../core/interfaces/IFactoryVersioning.sol';
import {
  ILendingCreditLineStorageManager
} from '../../lending-module/interfaces/ILendingCreditLineStorageManager.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  SynthereumInterfaces,
  FactoryInterfaces
} from '../../core/Constants.sol';
import {ExplicitERC20} from '../../base/utils/ExplicitERC20.sol';
import {ICreditLineV3} from './interfaces/ICreditLineV3.sol';
import {
  ICreditLineLendingTransfer
} from './interfaces/ICreditLineLendingTransfer.sol';
import {CreditLineLogicV3} from './logic/CreditLineLogicV3.sol';
import {ConfiguratorLogicV3} from './logic/ConfiguratorLogicV3.sol';
import {CreditLineStorageV3} from './CreditLineStorageV3.sol';
import {DataTypes} from './DataTypes.sol';

/**
 * @title
 * @notice
 */
contract CreditLineV3 is
  CreditLineStorageV3,
  ICreditLineV3,
  ICreditLineLendingTransfer,
  ReentrancyGuard,
  AccessControlEnumerable,
  ERC2771Context
{
  using SafeERC20 for IERC20;
  using ExplicitERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using CreditLineLogicV3 for DataTypes.UserPositionData;
  using CreditLineLogicV3 for DataTypes.ConfigurationData;
  using ConfiguratorLogicV3 for DataTypes.ConfigurationData;

  //----------------------------------------
  // Constants
  //----------------------------------------

  string public constant override typology = 'SELF-MINTING';

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier notEmergencyShutdown() {
    require(
      configurationData.emergencyShutdownTimestamp == 0,
      'Contract emergency shutdown'
    );
    _;
  }

  modifier isEmergencyShutdown() {
    require(
      configurationData.emergencyShutdownTimestamp != 0,
      'Contract not emergency shutdown'
    );
    _;
  }

  modifier onlyCollateralisedPosition(address sponsor) {
    require(
      positions[sponsor].depositedCollateral > 0,
      'Position has no collateral'
    );
    _;
  }

  modifier onlyLendingCreditLineManager() {
    require(
      msg.sender ==
        configurationData.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingCreditLineManager
        ),
      'Not allowed'
    );
    _;
  }

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  constructor(DataTypes.PositionManagerParams memory _positionManagerData)
    nonReentrant
  {
    configurationData.initialize(
      _positionManagerData.synthereumFinder,
      _positionManagerData.collateralToken,
      _positionManagerData.syntheticToken,
      _positionManagerData.lendingCreditLineManager,
      _positionManagerData.lendingCreditLineStorageManager,
      _positionManagerData.priceFeedIdentifier,
      _positionManagerData.minSponsorTokens,
      _positionManagerData.capMint,
      _positionManagerData.liquidationReward,
      _positionManagerData.collateralRequirement,
      _positionManagerData.version
    );
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _positionManagerData.roles.admin);
    _setupRole(MAINTAINER_ROLE, _positionManagerData.roles.maintainer);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  function deposit(uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
  {
    DataTypes.UserPositionData storage positionData =
      _getPositionData(_msgSender());

    positionData.depositTo(
      globalPositionData,
      configurationData,
      collateralAmount,
      _msgSender(),
      _msgSender()
    );
  }

  function depositTo(address sponsor, uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
  {
    DataTypes.UserPositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      configurationData,
      collateralAmount,
      sponsor,
      _msgSender()
    );
  }

  function withdraw(uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    DataTypes.UserPositionData storage positionData =
      _getPositionData(_msgSender());
    positionData.withdraw(
      globalPositionData,
      configurationData,
      collateralAmount,
      _msgSender()
    );
    return (collateralAmount);
  }

  function borrow(uint256 collateralAmount, uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 feeAmount)
  {
    DataTypes.UserPositionData storage positionData = positions[_msgSender()];
    feeAmount = positionData.borrow(
      globalPositionData,
      configurationData,
      collateralAmount,
      numTokens,
      _msgSender()
    );
  }

  function redeem(uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    DataTypes.UserPositionData storage positionData =
      _getPositionData(_msgSender());
    amountWithdrawn = positionData.redeem(
      globalPositionData,
      configurationData,
      numTokens,
      _msgSender()
    );
  }

  function repay(uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
  {
    DataTypes.UserPositionData storage positionData =
      _getPositionData(_msgSender());
    positionData.repay(
      globalPositionData,
      configurationData,
      numTokens,
      _msgSender()
    );
  }

  function liquidate(address sponsor, uint256 maxTokensToLiquidate)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (
      uint256 tokensLiquidated,
      uint256 collateralLiquidated,
      uint256 collateralReward
    )
  {
    // Retrieve Position data for sponsor
    DataTypes.UserPositionData storage positionToLiquidate =
      _getPositionData(sponsor);

    // try to liquidate it - reverts if is properly collateralised
    (
      collateralLiquidated,
      tokensLiquidated,
      collateralReward
    ) = positionToLiquidate.liquidate(
      configurationData,
      globalPositionData,
      maxTokensToLiquidate,
      sponsor,
      _msgSender()
    );
  }

  function transferToLendingManager(uint256 bearingAmount)
    external
    override
    onlyLendingCreditLineManager
    returns (uint256 amountTransferred)
  {
    address interestAddr =
      configurationData.lendingCreditLineStorageManager.getInterestBearingToken(
        address(this)
      );
    (amountTransferred, ) = IERC20(interestAddr).explicitSafeTransfer(
      address(configurationData.lendingCreditLineManager),
      bearingAmount
    );
  }

  function transferToProtocolReceiver(uint256 bearingAmount)
    external
    override
    onlyLendingCreditLineManager
    returns (uint256 amountTransferred)
  {
    address interestAddr =
      configurationData.lendingCreditLineStorageManager.getInterestBearingToken(
        address(this)
      );
    address recipient =
      configurationData.synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.ProtocolReceiver
      );
    (amountTransferred, ) = IERC20(interestAddr).explicitSafeTransfer(
      recipient,
      bearingAmount
    );
  }

  function setMinSponsorTokens(uint256 minSponsorTokens)
    external
    onlyMaintainer
  {
    configurationData._setMinSponsorTokens(minSponsorTokens);
  }

  function setLiquidationReward(uint256 liqReward) external onlyMaintainer {
    configurationData._setLiquidationReward(liqReward);
  }

  function setCollateralRequirement(uint256 percentage)
    external
    onlyMaintainer
  {
    configurationData._setCollateralRequirement(percentage);
  }

  function setCapMintAmount(uint256 capMintAmount) external onlyMaintainer {
    configurationData._setCapMintAmount(capMintAmount);
  }

  function settleEmergencyShutdown()
    external
    override
    isEmergencyShutdown()
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    DataTypes.UserPositionData storage positionData = positions[_msgSender()];
    amountWithdrawn = positionData.settleEmergencyShutdown(
      globalPositionData,
      configurationData,
      _msgSender()
    );
  }

  function emergencyShutdown()
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 timestamp, uint256 price)
  {
    return configurationData.emergencyShutdown();
  }

  function deleteSponsorPosition(address sponsor) external override {
    require(
      _msgSender() == address(this),
      'Only the contract can invoke this function'
    );
    delete positions[sponsor];
  }

  function getMinSponsorTokens()
    external
    view
    override
    returns (uint256 amount)
  {
    amount = configurationData._getMinSponsorTokens();
  }

  function getCapMintAmount() external view override returns (uint256 capMint) {
    capMint = configurationData._getCapMintAmount();
  }

  function getLiquidationReward()
    external
    view
    override
    returns (uint256 rewardPct)
  {
    rewardPct = configurationData._getLiquidationReward();
  }

  function getCollateralRequirement()
    external
    view
    override
    returns (uint256 collReq)
  {
    collReq = configurationData._getCollateralRequirement();
  }

  function getPositionData(address sponsor)
    external
    view
    override
    returns (uint256 collateralAmount, uint256 tokensAmount)
  {
    return (
      positions[sponsor].depositedCollateral,
      positions[sponsor].tokensOutstanding
    );
  }

  function getPendingInterest(address eoaAddress)
    external
    view
    returns (uint256 collateralAmount, uint256 collateralReservedForJRTBuyBack)
  {
    (collateralAmount, collateralReservedForJRTBuyBack) = lendingManager()
      .getPendingInterest(address(this), eoaAddress);
  }

  function getGlobalPositionData()
    external
    view
    override
    returns (uint256 totCollateral, uint256 totTokensOutstanding)
  {
    totCollateral = globalPositionData.totalPositionCollateral;
    totTokensOutstanding = globalPositionData.totalTokensOutstanding;
  }

  function collateralCoverage(address sponsor)
    external
    view
    override
    returns (bool isOverCollateralized, uint256 collateralCoveragePercentage)
  {
    (isOverCollateralized, collateralCoveragePercentage) = configurationData.collateralCoverage(positions[sponsor]);
  }

  function liquidationPrice(address sponsor)
    external
    view
    override
    returns (uint256)
  {
    return configurationData.liquidationPrice(positions[sponsor]);
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = configurationData.synthereumFinder;
  }

  function syntheticToken() external view override returns (IERC20 synthToken) {
    synthToken = configurationData.tokenCurrency;
  }

  function collateralToken() public view override returns (IERC20 collateral) {
    collateral = configurationData.collateralToken;
  }

  function lendingManager()
    public
    view
    override
    returns (ILendingCreditLineManager lendingCreditLineManager)
  {
    lendingCreditLineManager = configurationData.lendingCreditLineManager;
  }

  function lendingStorageManager()
    public
    view
    override
    returns (ILendingCreditLineStorageManager lendingCreditLineStorageManager)
  {
    lendingCreditLineStorageManager = configurationData
      .lendingCreditLineStorageManager;
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(configurationData.tokenCurrency)).symbol();
  }

  function version() external view override returns (uint8 contractVersion) {
    contractVersion = configurationData.version;
  }

  function priceIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = configurationData.priceIdentifier;
  }

  function emergencyShutdownTime()
    external
    view
    override
    isEmergencyShutdown()
    returns (uint256 time)
  {
    time = configurationData.emergencyShutdownTimestamp;
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      configurationData.synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.TrustedForwarder
      )
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------
  function _getPositionData(address sponsor)
    internal
    view
    onlyCollateralisedPosition(sponsor)
    returns (DataTypes.UserPositionData storage)
  {
    return positions[sponsor];
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumFactoryVersioning
} from '../../core/interfaces/IFactoryVersioning.sol';
import {
  SynthereumInterfaces,
  FactoryInterfaces
} from '../../core/Constants.sol';

/** @title Library to use for controlling the access of a functions from the factories
 */
library SynthereumFactoryAccess {
  /**
   *@notice Revert if caller is not a Pool factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactory(ISynthereumFinder _finder) internal view {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
      );
    uint8 numberOfPoolFactories =
      factoryVersioning.numberOfFactoryVersions(FactoryInterfaces.PoolFactory);
    require(
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfPoolFactories,
        FactoryInterfaces.PoolFactory
      ),
      'Not allowed'
    );
  }

  /**
   *@notice Revert if caller is not a CreditLine factory
   * @param _finder Synthereum finder
   */
  function _onlySelfMintingFactory(ISynthereumFinder _finder) internal view {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
      );
    uint8 numberOfCreditLineFactories =
      factoryVersioning.numberOfFactoryVersions(
        FactoryInterfaces.SelfMintingFactory
      );
    require(
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfCreditLineFactories,
        FactoryInterfaces.SelfMintingFactory
      ),
      'Not allowed'
    );
  }

  /**
   * @notice Revert if caller is not a Pool factory or a Fixed rate factory
   * @param _finder Synthereum finder
   */
  function _onlyPoolFactoryOrFixedRateFactory(ISynthereumFinder _finder)
    internal
    view
  {
    ISynthereumFactoryVersioning factoryVersioning =
      ISynthereumFactoryVersioning(
        _finder.getImplementationAddress(SynthereumInterfaces.FactoryVersioning)
      );
    uint8 numberOfPoolFactories =
      factoryVersioning.numberOfFactoryVersions(FactoryInterfaces.PoolFactory);
    uint8 numberOfFixedRateFactories =
      factoryVersioning.numberOfFactoryVersions(
        FactoryInterfaces.FixedRateFactory
      );
    bool isPoolFactory =
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfPoolFactories,
        FactoryInterfaces.PoolFactory
      );
    if (isPoolFactory) {
      return;
    }
    bool isFixedRateFactory =
      _checkSenderIsFactory(
        factoryVersioning,
        numberOfFixedRateFactories,
        FactoryInterfaces.FixedRateFactory
      );
    if (isFixedRateFactory) {
      return;
    }
    revert('Sender must be a Pool or FixedRate factory');
  }

  /**
   * @notice Check if sender is a factory
   * @param _factoryVersioning SynthereumFactoryVersioning contract
   * @param _numberOfFactories Total number of versions of a factory type
   * @param _factoryKind Type of the factory
   * @return isFactory True if sender is a factory, otherwise false
   */
  function _checkSenderIsFactory(
    ISynthereumFactoryVersioning _factoryVersioning,
    uint8 _numberOfFactories,
    bytes32 _factoryKind
  ) private view returns (bool isFactory) {
    uint8 counterFactory;
    for (uint8 i = 0; counterFactory < _numberOfFactories; i++) {
      try _factoryVersioning.getFactoryVersion(_factoryKind, i) returns (
        address factory
      ) {
        if (msg.sender == factory) {
          isFactory = true;
          break;
        } else {
          counterFactory++;
          if (counterFactory == _numberOfFactories) {
            isFactory = false;
          }
        }
      } catch {}
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ManagerDataTypes} from '../ManagerDataTypes.sol';

interface ILendingCreditLineManager {
  event BatchBuyback(
    uint256 indexed collateralIn,
    uint256 JRTOut,
    address receiver
  );
  event Buyback(uint256 indexed collateralIn, uint256 JRTOut, address receiver);

  event ProtocolFeesClaimed(
    uint256 indexed collateralOut,
    address receiver,
    address colleteralToken
  );

  event CommissionClaim(
    uint256 indexed collateralOut,
    address receiver,
    address interestBearingToken
  );

  /**
   * @notice deposits collateral into the creditLine's associated
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of collateral to deposit
   * @param _feesAmount the amount of fees apply from the deposit amount
   * @param _recipient the address that deposit the collateral
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function deposit(
    uint256 _amount,
    uint256 _feesAmount,
    address _recipient
  ) external returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice withdraw collateral from the creditLine's associated
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of interest tokens withdraw
   * @param _recipient the address receiving the collateral from money market
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function withdraw(uint256 _amount, address _recipient)
    external
    returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice withdraw user collateral from the creditLine's associated and send it to the receiver
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of interest tokens withdraw
   * @param _recipient the address that colletaral will be taken
   * @param _receiver the address receiving the collateral from money market
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function withdrawTo(
    uint256 _amount,
    address _recipient,
    address _receiver
  ) external returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice withdraw collateral from the creditLine's associated
   * @dev calculates and return the generated interest since last state-changing operation
   * @param _amount of fees to apply to the recipient
   * @param _recipient the address receiving the collateral from money market
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function applyProtocolFees(uint256 _amount, address _recipient)
    external
    returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice batches calls to redeem creditLineData.jrtInterest from multiple creditLines
   * @notice and executes a swap to buy Jarvis Reward Token
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLines array of creditLines address to redeem collateral from
   * @param _collateralAddress address of the creditLines collateral token (all creditLines must have the same collateral)
   * @param _swapParams encoded bytes necessary for the swap module
   */
  function batchBuyback(
    address[] calldata _creditLines,
    address _collateralAddress,
    bytes calldata _swapParams
  ) external;

  /**
   * @notice call to redeem creditLineData.jrtInterest from creditLine
   * @notice and executes a swap to buy Jarvis Reward Token
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLine address to redeem collateral from
   * @param _collateralAddress address of the creditLines collateral token
   * @param _swapParams encoded bytes necessary for the swap module
   */
  function claimBuyBack(
    address _creditLine,
    address _collateralAddress,
    bytes calldata _swapParams
  ) external;

  /**
   * @notice batches calls to redeem creditLineData.commissionInterest from multiple creditLines
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLines array of creditLines to redeem commissions from
   */
  function batchClaimCommission(address[] calldata _creditLines) external;

  /**
   * @notice call to redeem creditLineData.commissionInterest from a creditLine
   * @dev calculates and update the generated interest since last state-changing operation
   * @param _creditLine address of creditLines to redeem commissions from
   */
  function claimCommission(address _creditLine) external;

  /**
   * @notice batches calls to redeem creditLineData.protocolFees from multiple creditLines
   * @dev calculates and update the state regarding the protocolFees
   * @param _creditLines array of creditLines to redeem commissions from
   */
  function batchClaimProtocolFees(address[] calldata _creditLines) external;

  /**
   * @notice call to redeem creditLineData.protocolFees from a creditLine
   * @dev calculates and update the state regarding the protocolFees
   * @param _creditLine address of creditLines to redeem commissions from
   */
  function claimProtocolFees(address _creditLine) external;

  /**
   * @notice sets the address of the implementation of a lending module and its extraBytes
   * @param _id associated to the lending module to be set
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    ManagerDataTypes.LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice Add a swap module to the whitelist
   * @param _swapModule Swap module to add
   */
  function addSwapProtocol(address _swapModule) external;

  /**
   * @notice Remove a swap module from the whitelist
   * @param _swapModule Swap module to remove
   */
  function removeSwapProtocol(address _swapModule) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a creditLine collateral on the lending storage manager
   * @param _creditLine creditLine address to set shares on
   * @param _commissionInterestShare share of total interest generated assigned to the commissionner
   * @param _jrtInterestShare share of the total user's interest used to buyback jrt from an AMM
   * @param _protocolFeesPercentage share of the total dao interest generated assigned to the dao
   */
  function setShares(
    address _creditLine,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare,
    uint64 _protocolFeesPercentage
  ) external;

  /**
   * @notice migrates liquidity from one lending module (and money market), to a new one
   * @dev calculates and return the generated interest since last state-changing operation.
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _newInterestBearingToken address of the interest token of the new money market
   * @return migrateReturnValues check struct
   */
  function migrateLendingModule(
    string memory _newLendingID,
    address _newInterestBearingToken
  ) external returns (ManagerDataTypes.MigrateReturnValues memory);

  /**
   * @notice returns the conversion between interest token and collateral of a specific money market
   * @param _creditLine reference creditLine to check conversion
   * @param _interestTokenAmount amount of interest token to calculate conversion on
   * @return collateralAmount amount of collateral after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function interestTokenToCollateral(
    address _creditLine,
    uint256 _interestTokenAmount
  ) external view returns (uint256 collateralAmount, address interestTokenAddr);

  /**
   * @notice returns pending collateral interest and the buyback interest of a EOA from the last update
   * @dev does not update state, buy back interest only available for user
   * @param _creditLine reference creditLine to check accumulated interest
   * @param _eoaAddress address of the EOA to check interest
   * @return collateralInterest amount pending of collateral interest generated
   * @return buyBackInterest amount of pending buyback interest generated for the user
   */
  function getPendingInterest(address _creditLine, address _eoaAddress)
    external
    view
    returns (uint256 collateralInterest, uint256 buyBackInterest);

  /**
   * @notice returns the conversion between collateral and interest token of a specific money market
   * @param _creditLine reference creditLine to check conversion
   * @param _collateralAmount amount of collateral to calculate conversion on
   * @return interestTokenAmount amount of interest token after conversion
   * @return interestTokenAddr address of the associated interest token
   */
  function collateralToInterestToken(
    address _creditLine,
    uint256 _collateralAmount
  )
    external
    view
    returns (uint256 interestTokenAmount, address interestTokenAddr);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external;

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version) external;

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    returns (address factory);

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfFactoryVersions(bytes32 factoryType)
    external
    view
    returns (uint8 numberOfVersions);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ManagerDataTypes} from '../ManagerDataTypes.sol';

interface ILendingCreditLineStorageManager {
  /**
   * @notice sets a ILendingModule implementer info
   * @param _id string identifying a specific ILendingModule implementer
   * @param _lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string calldata _id,
    ManagerDataTypes.LendingInfo calldata _lendingInfo
  ) external;

  /**
   * @notice Add a swap module to the whitelist
   * @param _swapModule Swap module to add
   */
  function addSwapProtocol(address _swapModule) external;

  /**
   * @notice Remove a swap module from the whitelist
   * @param _swapModule Swap module to remove
   */
  function removeSwapProtocol(address _swapModule) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param _collateral collateral address associated to the swap module
   * @param _swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address _collateral, address _swapModule) external;

  /**
   * @notice set shares on interest generated by a creditLine collateral on the lending storage manager
   * @param _creditLine creditLine address to set shares on
   * @param _commissionInterestShare share of total interest generated assigned to the commissioner address
   * @param _jrtInterestShare share of total user interest used to buyback jrt from an AMM
   * @param _protocolFeesPercentage share of user collateral assigned to the protocol
   */
  function setShares(
    address _creditLine,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare,
    uint64 _protocolFeesPercentage
  ) external;

  /**
   * @notice store data for lending manager associated to a creditLine
   * @param _lendingID string identifying the associated ILendingModule implementer
   * @param _creditLine creditLine address to set info
   * @param _collateralToken collateral address of the creditLine
   * @param _interestBearingToken address of the interest token in use
   * @param _commissionInterestShare share of total interest generated assigned to the commissioner address
   * @param _jrtInterestShare share of the total user interest used to buyback jrt from an AMM
   * @param _protocolFeesPercentage share of user collateral assigned to the protocol
   */
  function setCreditLineInfo(
    string calldata _lendingID,
    address _creditLine,
    address _collateralToken,
    address _interestBearingToken,
    uint64 _commissionInterestShare,
    uint64 _jrtInterestShare,
    uint64 _protocolFeesPercentage
  ) external;

  /**
   * @notice sets new lending info on a creditLine
   * @dev used when migrating liquidity from one lending module (and money market), to a new one
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param _newLendingID id associated to the new lending module info
   * @param _creditLine address of the creditLine whose associated lending module is being migrated
   * @param _newInterestBearingToken address of the interest token of the new Lending Module (can be set blank)
   * @return creditLineData with the updated state
   * @return lendingInfo of the new lending module
   */
  function migrateLendingModule(
    string calldata _newLendingID,
    address _creditLine,
    address _newInterestBearingToken
  )
    external
    returns (
      ManagerDataTypes.CreditLineInfo memory,
      ManagerDataTypes.LendingInfo memory
    );

  /**
   * @notice updates storage of a creditLine
   * @dev should be callable only by LendingManager after state-changing operations
   * @param _creditLine address of the creditLine to update values
   * @param _user  address of user to update
   * @param _amount amount of colletaral to deposit/withdraw
   * @param _currentBalance amount of token in the lending module
   * @param _protocolFees amount of protocol fees to apply (if not 0 fees apply)
   * @param _isDeposit boolean to identify the function to call
   * @return newUserDeposit new user deposited value
   * @return newTotalDeposit new total deposited value
   */
  function updateValues(
    address _creditLine,
    address _user,
    uint256 _amount,
    uint256 _currentBalance,
    uint256 _protocolFees,
    bool _isDeposit
  ) external returns (uint256 newUserDeposit, uint256 newTotalDeposit);

  /**
   * @notice refresh state for interest calculation
   * @param _creditLine address of the creditLine to update
   * @param _currentBalance amount of token in the lending module
   */
  function refreshInterestRate(address _creditLine, uint256 _currentBalance)
    external;

  /**
   * @notice refresh state when commission interest are claimed
   * @param _creditLine address of the creditLine to update
   * @param _amount of token claimed
   */
  function updateCommissionInterest(address _creditLine, uint256 _amount)
    external;

  /**
   * @notice refresh state when protocol fees are claimed
   * @param _creditLine address of the creditLine to update
   * @param _amount of token claimed
   */
  function updateProtocolFees(address _creditLine, uint256 _amount) external;

  /**
   * @notice refresh state for interest calculation
   * @param _creditLine address of the creditLine to update
   * @param _user address of the user that claim
   * @param _amount amount of token claimed
   */
  function updateBuybackInterest(
    address _creditLine,
    address _user,
    uint256 _amount
  ) external;

  /**
   * @notice calculate the current pending rewards
   * @param _currentBalance current balance deposited in the lending module
   * @param _creditLine address of the creditLine
   * @param _eoaAddress address of the EOA
   * @return collateralInterest amount of pending collateral
   * @return buyBackInterest amount of pending collateral reserved for buy back
   */
  function getPendingInterest(
    uint256 _currentBalance,
    address _creditLine,
    address _eoaAddress
  ) external view returns (uint256 collateralInterest, uint256 buyBackInterest);

  /**
   * @notice Returns info about a supported lending module
   * @param _id Name of the module
   * @return lendingInfo Address and bytes associated to the lending mdodule
   */
  function getLendingModule(string calldata _id)
    external
    view
    returns (ManagerDataTypes.LendingInfo memory lendingInfo);

  /**
   * @notice reads CreditLineInfo of a creditLine
   * @param _creditLine address of the creditLine to read storage
   * @return creditLineInfo creditLine struct info
   */
  function getCreditLineStorage(address _creditLine)
    external
    view
    returns (ManagerDataTypes.CreditLineInfo memory creditLineInfo);

  /**
   * @notice reads UserInterestData of a user for a specific creditLine
   * @param _creditLine address of the creditLine
   * @param _user address of the user to read storage
   * @return userInterestData UserInterestData struct info
   */
  function getUserInterestData(address _creditLine, address _user)
    external
    view
    returns (ManagerDataTypes.UserInterestData memory userInterestData);

  /**
   * @notice reads creditLineStorage and LendingInfo of a creditLine
   * @param _creditLine address of the creditLine to read storage
   * @return creditLineInfo creditLine struct info
   * @return lendingInfo information of the lending module associated with the creditLine
   */
  function getCreditLineData(address _creditLine)
    external
    view
    returns (
      ManagerDataTypes.CreditLineInfo memory creditLineInfo,
      ManagerDataTypes.LendingInfo memory lendingInfo
    );

  /**
   * @notice reads lendingStorage and LendingInfo of a creditLine
   * @param _creditLine address of the creditLine to read storage
   * @return lendingStorage information of the addresses of collateral and intrestToken
   * @return lendingInfo information of the lending module associated with the creditLine
   */
  function getLendingData(address _creditLine)
    external
    view
    returns (
      ManagerDataTypes.LendingStorage memory lendingStorage,
      ManagerDataTypes.LendingInfo memory lendingInfo
    );

  /**
   * @notice Return the list containing every swap module supported
   * @return List of swap modules
   */
  function getSwapModules() external view returns (address[] memory);

  /**
   * @notice reads the JRT Buyback module associated to a collateral
   * @param _collateral address of the collateral to retrieve module
   * @return swapModule address of interface implementer of the IJRTSwapModule
   */
  function getCollateralSwapModule(address _collateral)
    external
    view
    returns (address swapModule);

  /**
   * @notice reads the interest beaaring token address associated to a creditLine
   * @param _creditLine address of the creditLine to retrieve interest token
   * @return interestTokenAddr address of the interest token
   */
  function getInterestBearingToken(address _creditLine)
    external
    view
    returns (address interestTokenAddr);

  /**
   * @notice reads the shares used for splitting interests between creditLine user, user buyback and commission
   * @param _creditLine address of the creditLine to retrieve interest token
   * @return commissionInterestShare Percentage of interests claimable by the commission
   * @return jrtInterestShare Percentage of interests used for the user's buyback
   * @return protocolFeesPercentage Percentage of fees claimable by the procotol
   */
  function getShares(address _creditLine)
    external
    view
    returns (
      uint256 commissionInterestShare,
      uint256 jrtInterestShare,
      uint256 protocolFeesPercentage
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
interface IMintableBurnableERC20 is IERC20 {
  /**
   * @notice Burns a specific amount of the caller's tokens.
   * @dev This method should be permissioned to only allow designated parties to burn tokens.
   */
  function burn(uint256 value) external;

  /**
   * @notice Mints tokens and adds them to the balance of the `to` address.
   * @dev This method should be permissioned to only allow designated parties to mint tokens.
   */
  function mint(address to, uint256 value) external returns (bool);

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant DaoTreasure = 'DaoTreasure';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant PrinterProxy = 'PrinterProxy';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
  bytes32 public constant LendingCreditLineManager = 'LendingCreditLineManager';
  bytes32 public constant LendingCreditLineStorageManager =
    'LendingCreditLineStorageManager';
  bytes32 public constant CommissionReceiver = 'CommissionReceiver';
  bytes32 public constant BuybackProgramReceiver = 'BuybackProgramReceiver';
  bytes32 public constant LendingRewardsReceiver = 'LendingRewardsReceiver';
  bytes32 public constant LiquidationRewardReceiver =
    'LiquidationRewardReceiver';
  bytes32 public constant JarvisToken = 'JarvisToken';
  bytes32 public constant ProtocolReceiver = 'ProtocolReceiver';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant CreditLineFactory = 'CreditLineFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title ExplicitERC20
 * @author Set Protocol
 *
 * Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExplicitERC20 {
  using SafeERC20 for IERC20;

  /**
   * When given allowance, transfers a token from the "_from" to the "_to" of quantity "_quantity".
   * Returning the real amount removed from sender's balance
   *
   * @param _token ERC20 token
   * @param _from  The account to transfer tokens from
   * @param _to The account to transfer tokens to
   * @param _quantity The quantity to transfer
   * @return amountTransferred Real amount removed from user balance
   * @return newBalance Final balance of the sender after transfer
   */
  function explicitSafeTransferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _quantity
  ) internal returns (uint256 amountTransferred, uint256 newBalance) {
    uint256 existingBalance = _token.balanceOf(_from);

    _token.safeTransferFrom(_from, _to, _quantity);

    newBalance = _token.balanceOf(_from);

    amountTransferred = existingBalance - newBalance;
  }

  /**
   * Transfers a token from the sender to the "_to" of quantity "_quantity".
   * Returning the real amount removed from sender's balance
   *
   * @param _token ERC20 token
   * @param _to The account to transfer tokens to
   * @param _quantity The quantity to transfer
   * @return amountTransferred Real amount removed from user balance
   * @return newBalance Final balance of the sender after transfer
   */
  function explicitSafeTransfer(
    IERC20 _token,
    address _to,
    uint256 _quantity
  ) internal returns (uint256 amountTransferred, uint256 newBalance) {
    uint256 existingBalance = _token.balanceOf(address(this));

    _token.safeTransfer(_to, _quantity);

    newBalance = _token.balanceOf(address(this));

    amountTransferred = existingBalance - newBalance;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  IStandardERC20,
  IERC20
} from '../../../base/interfaces/IStandardERC20.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';
import {
  IEmergencyShutdown
} from '../../../common/interfaces/IEmergencyShutdown.sol';
import {ITypology} from '../../../common/interfaces/ITypology.sol';
import {
  ILendingCreditLineManager
} from '../../../lending-module/interfaces/ILendingCreditLineManager.sol';
import {
  ILendingCreditLineStorageManager
} from '../../../lending-module/interfaces/ILendingCreditLineStorageManager.sol';

interface ICreditLineV3 is
  ITypology,
  IEmergencyShutdown,
  ISynthereumDeployment
{
  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event Borrowing(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );

  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(
    address indexed caller,
    uint256 settlementPrice,
    uint256 shutdownTimestamp
  );
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  event Liquidation(
    address indexed sponsor,
    address indexed liquidator,
    uint256 liquidatedTokens,
    uint256 liquidatedCollateral,
    uint256 collateralReward,
    uint256 liquidationTime
  );

  /**
   * @notice Transfers `collateralAmount` into the caller's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of collateral token
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function deposit(uint256 collateralAmount) external;

  /**
   * @notice Transfers `collateralAmount` into the specified sponsor's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of collateralCurrency.
   * @param sponsor the sponsor to credit the deposit to.
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function depositTo(address sponsor, uint256 collateralAmount) external;

  /**
   * @notice Transfers `collateralAmount` from the sponsor's position to the sponsor.
   * @dev Reverts if the withdrawal puts this position's collateralization ratio below the collateral requirement
   * @param collateralAmount is the amount of collateral to withdraw.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function withdraw(uint256 collateralAmount)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Pulls `collateralAmount` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
   * Mints new debt tokens by creating a new position or by augmenting an existing position.
   * @dev Can only be called by a token sponsor. This contract must be approved to spend at least `collateralAmount` of
   * `collateralCurrency`.
   * @param collateralAmount is the number of collateral tokens to collateralize the position with
   * @param numTokens is the number of debt tokens to mint to sponsor.
   * @return feeAmount incurred fees in collateral token.
   */
  function borrow(uint256 collateralAmount, uint256 numTokens)
    external
    returns (uint256 feeAmount);

  /**
   * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of collateral
   * @dev Can only be called by a token sponsor - This contract must be approved to spend at least `numTokens` of
   * `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function redeem(uint256 numTokens) external returns (uint256 amountWithdrawn);

  /**
   * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back collateral.
   * This is done by a sponsor to increase position CR.
   * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt.
   */
  function repay(uint256 numTokens) external;

  /**
   * @notice Liquidate sponsor position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param sponsor Address of sponsor to be liquidated.
   * @param maxTokensToLiquidate Max number of synthetic tokens to be liquidated
   * @return tokensLiquidated Amount of debt tokens burned
   * @return collateralLiquidated Amount of received collateral equal to the value of tokens liquidated
   * @return collateralReward Amount of received collateral as reward for the liquidation
   */
  function liquidate(address sponsor, uint256 maxTokensToLiquidate)
    external
    returns (
      uint256 tokensLiquidated,
      uint256 collateralLiquidated,
      uint256 collateralReward
    );

  /**
   * @notice When in emergency shutdown state all token holders and sponsor can redeem their tokens and
   * remaining collateral at the current price defined by the on-chain oracle
   * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the resolved settlement value of
   * collateral. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
   * @dev This contract must have the Burner role for the `tokenCurrency`.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function settleEmergencyShutdown() external returns (uint256 amountWithdrawn);

  // /**
  //  * @notice trim any excess funds in the contract to the excessTokenBeneficiary address
  //  * @return amount the amount of tokens trimmed
  //  */
  // function trimExcess(IERC20 token) external returns (uint256 amount);

  /**
   * @notice Delete a TokenSponsor position. This function can only be called by the contract itself.
   * @param sponsor address of the TokenSponsor.
   */
  function deleteSponsorPosition(address sponsor) external;

  /**
   * @notice Returns the minimum amount of tokens a sponsor must mint
   * @return amount the value
   */
  function getMinSponsorTokens() external view returns (uint256 amount);

  /**
   * @notice Returns the cap mint amount of the derivative contract
   * @return capMint cap mint amount
   */
  function getCapMintAmount() external view returns (uint256 capMint);

  /**
   * @notice Returns the liquidation rewrd percentage of the derivative contract
   * @return rewardPct liquidator reward percentage
   */
  function getLiquidationReward() external view returns (uint256 rewardPct);

  /**
   * @notice Returns the over collateralization percentage of the derivative contract
   * @return collReq percentage of overcollateralization
   */
  function getCollateralRequirement() external view returns (uint256 collReq);

  /**
   * @notice Accessor method for a sponsor's position.
   * @param sponsor address whose position data is retrieved.
   * @return collateralAmount amount of collateral of the sponsor's position.
   * @return tokensAmount amount of outstanding tokens of the sponsor's position.
   */
  function getPositionData(address sponsor)
    external
    view
    returns (uint256 collateralAmount, uint256 tokensAmount);

  /**
   * @notice Accessor method for contract's global position (aggregate).
   * @return totCollateral total amount of collateral deposited by lps
   * @return totTokensOutstanding total amount of outstanding tokens.
   */
  function getGlobalPositionData()
    external
    view
    returns (uint256 totCollateral, uint256 totTokensOutstanding);

  /**
   * @notice Returns if sponsor position is overcollateralized and the percentage of coverage of the collateral according to the last price
   * @return isOverCollateralized bool that is true if position is overcollaterlized, otherwise false 
   * @return collateralCoveragePercentage percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage(address sponsor)
    external
    view
    returns (bool isOverCollateralized, uint256 collateralCoveragePercentage);

  /**
   * @notice Returns liquidation price of a position
   * @param sponsor address whose liquidation price is calculated.
   * @return liquidationPrice
   */
  function liquidationPrice(address sponsor)
    external
    view
    returns (uint256 liquidationPrice);

  /**
   * @notice Get synthetic token price identifier as represented by the oracle interface
   * @return identifier Synthetic token price identifier
   */
  function priceIdentifier() external view returns (bytes32 identifier);

  /**
   * @notice Get the block number when the emergency shutdown was called
   * @return time Block time
   */
  function emergencyShutdownTime() external view returns (uint256 time);

  /**
   * @notice Get address and instance of the lendingManage attach to the creditLine
   * @return creditLineManager the address/instance
   */
  function lendingManager()
    external
    view
    returns (ILendingCreditLineManager creditLineManager);

  /**
   * @notice Get address and instance of the lending storage manager of creditLines
   * @return creditLineStorageManager the address/instance
   */
  function lendingStorageManager()
    external
    view
    returns (ILendingCreditLineStorageManager creditLineStorageManager);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title CreditLine interface for making creditLine lending manager interacting with the creditLine
 */
interface ICreditLineLendingTransfer {
  
   /**
   * @notice Transfer a bearing amount to the lending manager
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   * @return bearingAmountOut Real bearing amount transferred to the lending manager
   */
  function transferToLendingManager(uint256 _bearingAmount)
    external
    returns (uint256 bearingAmountOut);

  /**
   * @notice Transfer a bearing amount to the protocol receiver
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   * @return bearingAmountOut Real bearing amount transferred to the lending manager
   */
  function transferToProtocolReceiver(uint256 _bearingAmount)
    external
    returns (uint256 bearingAmountOut);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  SafeERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeMath} from '../../../../@openzeppelin/contracts/utils/math/SafeMath.sol';
import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {WadRayMath} from '../../../base/utils/WadRayMath.sol';
import {
  IMintableBurnableERC20
} from '../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  ICreditLineControllerV3
} from '../interfaces/ICreditLineControllerV3.sol';
import {SynthereumInterfaces} from '../../../core/Constants.sol';
import {
  ISynthereumPriceFeed
} from '../../../oracle/common/interfaces/IPriceFeed.sol';
import {CreditLineV3} from '../CreditLineV3.sol';
import {DataTypes} from '../DataTypes.sol';
import {ConfiguratorLogicV3} from './ConfiguratorLogicV3.sol';

library CreditLineLogicV3 {
  using SafeMath for uint256;
  using WadRayMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IStandardERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using CreditLineLogicV3 for DataTypes.UserPositionData;
  using CreditLineLogicV3 for DataTypes.GlobalPositionData;
  using CreditLineLogicV3 for DataTypes.ConfigurationData;
  using ConfiguratorLogicV3 for DataTypes.ConfigurationData;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event Borrowing(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );

  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(
    address indexed caller,
    uint256 settlementPrice,
    uint256 shutdownTimestamp
  );
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  event Liquidation(
    address indexed sponsor,
    address indexed liquidator,
    uint256 liquidatedTokens,
    uint256 liquidatedCollateral,
    uint256 collateralReward,
    uint256 liquidationTime
  );

  //----------------------------------------
  // External functions
  //----------------------------------------

  function depositTo(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 collateralAmount,
    address sponsor,
    address msgSender
  ) external {
    require(collateralAmount > 0, 'Invalid collateral amount');

    configurationData.collateralToken.safeTransferFrom(
      msgSender,
      address(configurationData.lendingCreditLineManager),
      collateralAmount
    );

    // Deposit into the lending module
    (uint256 newUserDeposit, uint256 newTotalDeposit) =
      configurationData.lendingCreditLineManager.deposit(
        collateralAmount,
        0,
        sponsor
      );

    _updateCollateralBalances(
      positionData,
      globalPositionData,
      newUserDeposit,
      newTotalDeposit
    );

    emit Deposit(sponsor, collateralAmount);
  }

  function withdraw(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 collateralAmount,
    address msgSender
  ) external {
    require(collateralAmount > 0, 'Invalid collateral amount');

    (uint256 newUserDeposit, uint256 newTotalDeposited) =
      configurationData.lendingCreditLineManager.withdraw(
        collateralAmount,
        msgSender
      );

    // Update collateral balances
    // Reverts if the resulting position is not properly collateralized
    _updateCollateralBalancesCheckCR(
      positionData,
      globalPositionData,
      configurationData,
      newUserDeposit,
      newTotalDeposited
    );

    emit Withdrawal(msgSender, collateralAmount);
  }

  function borrow(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 collateralAmount,
    uint256 numTokens,
    address msgSender
  ) external returns (uint256 feeAmount) {
    // Update fees status - percentage is retrieved from Credit Line Controller
    feeAmount = _calculateFeesAmount(configurationData, numTokens);

    positionData._checkBorrowPosition(
      configurationData,
      feeAmount,
      collateralAmount,
      numTokens,
      msgSender
    );

    positionData._increaseTokensOutStanding(
      globalPositionData,
      configurationData,
      numTokens
    );

    uint256 newUserDeposit;
    uint256 newTotalDeposit;
    if (collateralAmount > 0) {
      configurationData.collateralToken.safeTransferFrom(
        msgSender,
        address(configurationData.lendingCreditLineManager),
        collateralAmount
      );
      (newUserDeposit, newTotalDeposit) = configurationData
        .lendingCreditLineManager
        .deposit(collateralAmount, feeAmount, msgSender);
    } else {
      (newUserDeposit, newTotalDeposit) = configurationData
        .lendingCreditLineManager
        .applyProtocolFees(feeAmount, msgSender);
    }

    _updateCollateralBalances(
      positionData,
      globalPositionData,
      newUserDeposit,
      newTotalDeposit
    );

    // mint corresponding synthetic tokens to the caller's address.
    configurationData.tokenCurrency.mint(msgSender, numTokens);

    emit Borrowing(msgSender, collateralAmount, numTokens, feeAmount);
  }

  function redeem(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 numTokens,
    address sponsor
  ) external returns (uint256 collateralRedeemed) {
    require(
      numTokens <= positionData.tokensOutstanding,
      'Invalid token amount'
    );

    (uint256 collateralInterest, ) =
      configurationData.lendingCreditLineManager.getPendingInterest(
        address(this),
        sponsor
      );

    collateralRedeemed = (
      positionData.depositedCollateral.add(collateralInterest)
    )
      .mul(numTokens)
      .div(positionData.tokensOutstanding);

    (uint256 newUserDeposit, uint256 newTotalDeposited) =
      configurationData.lendingCreditLineManager.withdraw(
        collateralRedeemed,
        sponsor
      );

    // If redemption returns all tokens the sponsor has then we can delete their position. Else, downsize.
    if (positionData.tokensOutstanding == numTokens) {
      positionData._deleteSponsorPosition(globalPositionData, sponsor);
    } else {
      // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
      positionData._decreaseTokensOutStanding(globalPositionData, numTokens);
      require(
        positionData.tokensOutstanding >= configurationData.minSponsorTokens,
        'Below minimum sponsor position'
      );
    }

    _updateCollateralBalancesCheckCR(
      positionData,
      globalPositionData,
      configurationData,
      newUserDeposit,
      newTotalDeposited
    );

    _pullAndburnTokens(configurationData, sponsor, numTokens);

    emit Redeem(sponsor, collateralRedeemed, numTokens);
  }

  function repay(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 numTokens,
    address msgSender
  ) external {
    require(
      numTokens <= positionData.tokensOutstanding,
      'Invalid token amount'
    );

    positionData._decreaseTokensOutStanding(globalPositionData, numTokens);
    require(
      positionData.tokensOutstanding >= configurationData.minSponsorTokens,
      'Below minimum sponsor position'
    );

    _pullAndburnTokens(configurationData, msgSender, numTokens);

    emit Repay(msgSender, numTokens, positionData.tokensOutstanding);
  }

  function liquidate(
    DataTypes.UserPositionData storage positionToLiquidate,
    DataTypes.ConfigurationData storage configurationData,
    DataTypes.GlobalPositionData storage globalPositionData,
    uint256 numSynthTokens,
    address sponsorToLiquidated,
    address msgSender
  )
    external
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    DataTypes.ExecuteLiquidationData memory executeLiquidationData =
      _calculateLiquidationData(
        positionToLiquidate,
        configurationData,
        globalPositionData,
        numSynthTokens,
        sponsorToLiquidated
      );

    // transfer tokens from liquidator to here and burn them
    _pullAndburnTokens(
      configurationData,
      msgSender,
      executeLiquidationData.tokensToLiquidate
    );

    (uint256 newSponsorDeposit, uint256 newTotalDeposited) =
      configurationData.lendingCreditLineManager.withdrawTo(
        executeLiquidationData.collateralLiquidated,
        sponsorToLiquidated,
        msgSender
      );

    // reduce position
    _reducePosition(
      positionToLiquidate,
      globalPositionData,
      executeLiquidationData.tokensToLiquidate,
      newSponsorDeposit,
      newTotalDeposited
    );

    emit Liquidation(
      sponsorToLiquidated,
      msgSender,
      executeLiquidationData.tokensToLiquidate,
      executeLiquidationData.collateralLiquidated,
      executeLiquidationData.liquidatorReward,
      block.timestamp
    );

    // return values
    return (
      executeLiquidationData.collateralLiquidated,
      executeLiquidationData.tokensToLiquidate,
      executeLiquidationData.liquidatorReward
    );
  }

  function _calculateLiquidationData(
    DataTypes.UserPositionData storage positionToLiquidate,
    DataTypes.ConfigurationData storage configurationData,
    DataTypes.GlobalPositionData storage globalPositionData,
    uint256 numSynthTokens,
    address sponsorToLiquidated
  )
    internal
    returns (DataTypes.ExecuteLiquidationData memory executeLiquidationData)
  {
    uint8 collateralDecimals =
      _getCollateralDecimals(configurationData.collateralToken);
    uint256 priceRate = _getOraclePrice(configurationData);

    // get pending collateral interest from sponsor
    (uint256 collateralInterest, ) =
      configurationData.lendingCreditLineManager.getPendingInterest(
        address(this),
        sponsorToLiquidated
      );

    // make sure position is undercollateralised
    require(
      !configurationData._checkCollateralization(
        positionToLiquidate.depositedCollateral.add(collateralInterest),
        positionToLiquidate.tokensOutstanding,
        priceRate,
        collateralDecimals
      ),
      'Position is properly collateralised'
    );

    // calculate tokens to liquidate
    executeLiquidationData.tokensToLiquidate = positionToLiquidate
      .tokensOutstanding > numSynthTokens
      ? numSynthTokens
      : positionToLiquidate.tokensOutstanding;

    // calculate collateral value of those tokens
    executeLiquidationData
      .collateralValueLiquidatedTokens = _calculateCollateralAmount(
      executeLiquidationData.tokensToLiquidate,
      priceRate,
      collateralDecimals
    );

    // calculate proportion of collateral liquidated from position
    executeLiquidationData.collateralLiquidated = executeLiquidationData
      .tokensToLiquidate
      .wadDiv(positionToLiquidate.tokensOutstanding)
      .wadMul(positionToLiquidate.depositedCollateral.add(collateralInterest));

    // compute final liquidation outcome
    if (
      executeLiquidationData.collateralLiquidated >
      executeLiquidationData.collateralValueLiquidatedTokens
    ) {
      // position is still capitalised - liquidator profits
      executeLiquidationData.liquidatorReward = (
        executeLiquidationData.collateralLiquidated.sub(
          executeLiquidationData.collateralValueLiquidatedTokens
        )
      )
        .wadMul(configurationData._getLiquidationReward());
      executeLiquidationData.collateralLiquidated = executeLiquidationData
        .collateralValueLiquidatedTokens
        .add(executeLiquidationData.liquidatorReward);
    }
  }

  function emergencyShutdown(DataTypes.ConfigurationData storage self)
    external
    returns (uint256 timestamp, uint256 price)
  {
    require(
      msg.sender ==
        self.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.Manager
        ),
      'Caller must be a Synthereum manager'
    );

    timestamp = block.timestamp;
    price = self._getOraclePrice();

    // store timestamp
    self.emergencyShutdownTimestamp = timestamp;
    self.emergencyShutdownPrice = price;
    emit EmergencyShutdown(msg.sender, price, timestamp);
  }

  function settleEmergencyShutdown(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    address msgSender
  ) external returns (uint256 amountWithdrawn) {
    // copy value
    uint256 emergencyShutdownPrice = configurationData.emergencyShutdownPrice;
    IMintableBurnableERC20 tokenCurrency = configurationData.tokenCurrency;
    uint256 depositedCollateral = positionData.depositedCollateral;
    uint256 totalCollateral = globalPositionData.totalPositionCollateral;

    // Get caller's tokens balance
    uint256 tokensToRedeem = tokenCurrency.balanceOf(msgSender);

    // calculate amount of underlying collateral entitled to them, with oracle emergency price
    uint256 totalRedeemableCollateral =
      tokensToRedeem.mul(emergencyShutdownPrice);

    // If the caller is a sponsor with outstanding collateral they are also entitled to their excess collateral after their debt.
    if (depositedCollateral > 0) {
      // Calculate the underlying entitled to a token sponsor. This is collateral - debt
      uint256 tokenDebtValueInCollateral =
        positionData.tokensOutstanding.mul(emergencyShutdownPrice);

      // accrued to withdrawable collateral eventual excess collateral after debt
      if (tokenDebtValueInCollateral < depositedCollateral) {
        totalRedeemableCollateral = totalRedeemableCollateral.add(
          depositedCollateral.sub(tokenDebtValueInCollateral)
        );
      }

      CreditLineV3(address(this)).deleteSponsorPosition(msgSender);
      emit EndedSponsorPosition(msgSender);
    }

    // Take the min of the remaining collateral and the collateral "owed". If the contract is undercapitalized,
    // the caller will get as much collateral as the contract can pay out.
    amountWithdrawn = totalCollateral > totalRedeemableCollateral
      ? totalCollateral
      : totalRedeemableCollateral;

    // Decrement total contract collateral and outstanding debt.
    globalPositionData.totalPositionCollateral = totalCollateral.sub(
      amountWithdrawn
    );
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToRedeem);

    emit SettleEmergencyShutdown(msgSender, amountWithdrawn, tokensToRedeem);

    // Transfer tokens & collateral and burn the redeemed tokens.
    configurationData.collateralToken.safeTransfer(msgSender, amountWithdrawn);
    tokenCurrency.safeTransferFrom(msgSender, address(this), tokensToRedeem);
    tokenCurrency.burn(tokensToRedeem);
  }


  function collateralCoverage(
    DataTypes.ConfigurationData storage self,
    DataTypes.UserPositionData storage positionData
  ) external view returns (bool isOverCollateralized, uint256 collateralCoveragePercentage) {
    uint256 priceRate = _getOraclePrice(self);
    uint8 collateralDecimals = _getCollateralDecimals(self.collateralToken);
    uint256 positionCollateral = positionData.depositedCollateral;
    uint256 positionTokens = positionData.tokensOutstanding;
    isOverCollateralized =
      _checkCollateralization(
        self,
        positionCollateral,
        positionTokens,
        priceRate,
        collateralDecimals
      );

    uint256 collateralRequirementPrc = self._getCollateralRequirement();

    uint256 overCollateralValue =
      _getOverCollateralizationLimit(
        _calculateCollateralAmount(
          positionData.tokensOutstanding,
          priceRate,
          collateralDecimals
        ),
      collateralRequirementPrc
    );

    uint256 coverageRatio = positionCollateral.wadDiv(overCollateralValue);

    collateralCoveragePercentage = collateralRequirementPrc.wadMul(coverageRatio);
  }

  function liquidationPrice(
    DataTypes.ConfigurationData storage self,
    DataTypes.UserPositionData storage positionData
  ) external view returns (uint256 liqPrice) {
    // liquidationPrice occurs when totalCollateral is entirely occupied in the position value * collateral requirement
    // positionCollateral = positionTokensOut * liqPrice * collRequirement
    uint8 collateralDecimals = _getCollateralDecimals(self.collateralToken);
    liqPrice = positionData.depositedCollateral
      .wadDiv(self._getCollateralRequirement())
      .mul(10**(18 - collateralDecimals))
      .div(positionData.tokensOutstanding);
  }

  function feeInfo(DataTypes.ConfigurationData storage configurationData)
    external
    view
    returns (
      uint256 commissionInterestShare,
      uint256 jrtInterestShare,
      uint256 protocolFeesPercentage
    )
  {
    return configurationData._getFeeInfo();
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  function _checkBorrowPosition(
    DataTypes.UserPositionData storage positionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 feeAmount,
    uint256 collateralAmount,
    uint256 numTokens,
    address msgSender
  ) internal {
    uint256 priceRate = _getOraclePrice(configurationData);
    uint8 collateralDecimals =
      _getCollateralDecimals(configurationData.collateralToken);

    // get pending collateral interest from sponsor
    (uint256 collateralInterest, ) =
      configurationData.lendingCreditLineManager.getPendingInterest(
        address(this),
        msgSender
      );

    uint256 totalCollateral =
      positionData
        .depositedCollateral
        .add(collateralAmount)
        .add(collateralInterest)
        .sub(feeAmount);
    if (positionData.tokensOutstanding == 0) {
      require(
        _checkCollateralization(
          configurationData,
          totalCollateral,
          numTokens,
          priceRate,
          collateralDecimals
        ),
        'Insufficient Collateral'
      );
      require(
        numTokens >= configurationData.minSponsorTokens,
        'Below minimum sponsor position'
      );
      emit NewSponsor(msgSender);
    } else {
      require(
        _checkCollateralization(
          configurationData,
          totalCollateral,
          positionData.tokensOutstanding.add(numTokens),
          priceRate,
          collateralDecimals
        ),
        'Insufficient Collateral'
      );
    }
  }

  function _calculateFeesAmount(
    DataTypes.ConfigurationData storage configurationData,
    uint256 numTokens
  ) internal returns (uint256 feeAmount) {
    uint256 priceRate = configurationData._getOraclePrice();
    uint8 collateralDecimals =
      _getCollateralDecimals(configurationData.collateralToken);
    (, , uint256 protocolFees) = configurationData._getFeeInfo();

    feeAmount = _calculateCollateralAmount(
      numTokens,
      priceRate,
      collateralDecimals
    )
      .wadMul(protocolFees);
  }

  function _increaseTokensOutStanding(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 numTokens
  ) internal {
    positionData.tokensOutstanding = positionData.tokensOutstanding.add(
      numTokens
    );
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .add(numTokens);

    _checkMintLimit(globalPositionData, configurationData);
  }

  function _decreaseTokensOutStanding(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    uint256 numTokens
  ) internal {
    positionData.tokensOutstanding = positionData.tokensOutstanding.sub(
      numTokens
    );
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(numTokens);
  }

  function _pullAndburnTokens(
    DataTypes.ConfigurationData storage configurationData,
    address eoaAddress,
    uint256 amount
  ) internal {
    configurationData.tokenCurrency.safeTransferFrom(
      eoaAddress,
      address(this),
      amount
    );
    configurationData.tokenCurrency.burn(amount);
  }

  function _updateCollateralBalances(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    uint256 newUserCollateral,
    uint256 newTotalDeposit
  ) internal {
    positionData.depositedCollateral = newUserCollateral;
    globalPositionData.totalPositionCollateral = newTotalDeposit;
  }

  // Remove the withdrawn collateral from the position and then check its CR
  function _updateCollateralBalancesCheckCR(
    DataTypes.UserPositionData storage positionData,
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData,
    uint256 userDepositedAmount,
    uint256 totalAmount
  ) internal {
    positionData._updateCollateralBalances(
      globalPositionData,
      userDepositedAmount,
      totalAmount
    );
    require(
      _checkCollateralization(
        configurationData,
        userDepositedAmount,
        positionData.tokensOutstanding,
        _getOraclePrice(configurationData),
        _getCollateralDecimals(configurationData.collateralToken)
      ),
      'CR is not sufficiently high after the withdraw - try less amount'
    );
  }

  // Deletes a sponsor's position and updates global counters. Does not make any external transfers.
  function _deleteSponsorPosition(
    DataTypes.UserPositionData storage positionToLiquidate,
    DataTypes.GlobalPositionData storage globalPositionData,
    address sponsor
  ) internal returns (uint256) {
    // Remove the collateral and outstanding from the overall total position.
    globalPositionData.totalPositionCollateral = globalPositionData
      .totalPositionCollateral
      .sub(positionToLiquidate.depositedCollateral);
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(positionToLiquidate.tokensOutstanding);

    // delete position entry from storage
    CreditLineV3(address(this)).deleteSponsorPosition(sponsor);

    emit EndedSponsorPosition(sponsor);

    // Return unlocked amount of collateral
    return positionToLiquidate.depositedCollateral;
  }

  function _reducePosition(
    DataTypes.UserPositionData storage positionToLiquidate,
    DataTypes.GlobalPositionData storage globalPositionData,
    uint256 tokensToLiquidate,
    uint256 newUserDeposit,
    uint256 newTotalDeposited
  ) internal {
    // reduce token position
    positionToLiquidate._decreaseTokensOutStanding(
      globalPositionData,
      tokensToLiquidate
    );

    _updateCollateralBalances(
      positionToLiquidate,
      globalPositionData,
      newUserDeposit,
      newTotalDeposited
    );
  }

  function _checkCollateralization(
    DataTypes.ConfigurationData storage configurationData,
    uint256 collateral,
    uint256 numTokens,
    uint256 oraclePrice,
    uint8 collateralDecimals
  ) internal view returns (bool) {
    // calculate the min collateral of numTokens with chainlink
    uint256 thresholdValue =
      _calculateCollateralAmount(numTokens, oraclePrice, collateralDecimals);

    thresholdValue = _getOverCollateralizationLimit(
      thresholdValue,
      configurationData._getCollateralRequirement()
    );

    return collateral >= thresholdValue;
  }

  /**
   * @notice Retrun the on-chain oracle price for a pair
   * @return priceRate Latest rate of the pair
   */
  function _getOraclePrice(
    DataTypes.ConfigurationData storage configurationData
  ) internal view returns (uint256 priceRate) {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        configurationData.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.PriceFeed
        )
      );
    priceRate = priceFeed.getLatestPrice(configurationData.priceIdentifier);
  }

  function _getFeeInfo(DataTypes.ConfigurationData storage configurationData)
    internal
    view
    returns (
      uint256 commissionInterestShare,
      uint256 jrtInterestShare,
      uint256 protocolFeesPercentage
    )
  {
    (
      commissionInterestShare,
      jrtInterestShare,
      protocolFeesPercentage
    ) = configurationData.lendingCreditLineStorageManager.getShares(
      address(this)
    );
  }

  function _checkMintLimit(
    DataTypes.GlobalPositionData storage globalPositionData,
    DataTypes.ConfigurationData storage configurationData
  ) internal view {
    require(
      globalPositionData.totalTokensOutstanding <=
        configurationData._getCapMintAmount(),
      'Total amount minted overcomes mint limit'
    );
  }

  function _getCollateralDecimals(IStandardERC20 collateralToken)
    internal
    view
    returns (uint8 decimals)
  {
    decimals = collateralToken.decimals();
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token
   * @param numTokens Amount of synthetic tokens from which you want to calculate collateral amount
   * @param priceRate On-chain price rate
   * @return collateralAmount Amount of collateral after on-chain oracle conversion
   */
  function _calculateCollateralAmount(
    uint256 numTokens,
    uint256 priceRate,
    uint256 collateraDecimals
  ) internal pure returns (uint256 collateralAmount) {
    collateralAmount = numTokens.wadMul(priceRate).div(
      10**(18 - collateraDecimals)
    );
  }

  function _getOverCollateralizationLimit(
    uint256 collateral,
    uint256 collateralRequirementPrc
  ) internal pure returns (uint256) {
    return collateral.wadMul(collateralRequirementPrc);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  ILendingCreditLineManager
} from '../../../lending-module/interfaces/ILendingCreditLineManager.sol';
import {
  ILendingCreditLineStorageManager
} from '../../../lending-module/interfaces/ILendingCreditLineStorageManager.sol';
import {
  ISynthereumPriceFeed
} from '../../../oracle/common/interfaces/IPriceFeed.sol';
import {SynthereumInterfaces} from '../../../core/Constants.sol';
import {DataTypes} from '../DataTypes.sol';

library ConfiguratorLogicV3 {
  //----------------------------------------
  // Events
  //----------------------------------------
  event SetCapMintAmount(uint256 capMintAmount);
  event SetLiquidationReward(uint256 liquidationReward);
  event SetCollateralRequirement(uint256 collateralRequirement);
  event SetMinSponsorTokens(uint256 minSponsorTokens);

  //----------------------------------------
  // External functions
  //----------------------------------------

  function initialize(
    DataTypes.ConfigurationData storage self,
    ISynthereumFinder _finder,
    IStandardERC20 _collateralToken,
    IMintableBurnableERC20 _tokenCurrency,
    ILendingCreditLineManager _lendingCreditLineManager,
    ILendingCreditLineStorageManager _lendingCreditLineStorageManager,
    bytes32 _priceIdentifier,
    uint256 _minSponsorTokens,
    uint256 _capMint,
    uint256 _liquidationReward,
    uint256 _collateralRequirement,
    uint8 _version
  ) external {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );

    require(
      priceFeed.isPriceSupported(_priceIdentifier),
      'Price identifier not supported'
    );
    require(
      _collateralToken.decimals() <= 18,
      'Collateral has more than 18 decimals'
    );
    require(
      _tokenCurrency.decimals() == 18,
      'Synthetic token has more or less than 18 decimals'
    );
    self.priceIdentifier = _priceIdentifier;
    self.synthereumFinder = _finder;
    self.collateralToken = _collateralToken;
    self.tokenCurrency = _tokenCurrency;
    self.lendingCreditLineManager = _lendingCreditLineManager;
    self.lendingCreditLineStorageManager = _lendingCreditLineStorageManager;
    self.minSponsorTokens = _minSponsorTokens;
    self.capMint = _capMint;
    self.collateralRequirement = _collateralRequirement;
    self.liquidationReward = _liquidationReward;
    self.version = _version;
  }

  //----------------------------------------
  // Interal functions
  //----------------------------------------

  function _setLiquidationReward(
    DataTypes.ConfigurationData storage self,
    uint256 liqReward
  ) internal {
    require(
      self.liquidationReward != liqReward,
      'Liquidation reward is the same'
    );
    require(
      liqReward < 10**18,
      'Liquidation reward must be between 0 and 100%'
    );
    self.liquidationReward = liqReward;
    emit SetLiquidationReward(liqReward);
  }

  function _getLiquidationReward(DataTypes.ConfigurationData memory self)
    internal
    view
    returns (uint256 liqRewardPercentage)
  {
    liqRewardPercentage = self.liquidationReward;
  }

  function _setCollateralRequirement(
    DataTypes.ConfigurationData storage self,
    uint256 percentage
  ) internal {
    require(
      self.collateralRequirement != percentage,
      'Collateral requirement is the same'
    );
    require(
      percentage > 10**18,
      'Overcollateralisation must be bigger than 100%'
    );
    self.collateralRequirement = percentage;
    emit SetCollateralRequirement(percentage);
  }

  function _getCollateralRequirement(DataTypes.ConfigurationData memory self)
    internal
    view
    returns (uint256 collateralRequirement)
  {
    collateralRequirement = self.collateralRequirement;
  }

  function _setCapMintAmount(
    DataTypes.ConfigurationData storage self,
    uint256 capMintAmount
  ) internal {
    require(self.capMint != capMintAmount, 'Cap mint amount is the same');
    self.capMint = capMintAmount;
    emit SetCapMintAmount(capMintAmount);
  }

  function _getCapMintAmount(DataTypes.ConfigurationData memory self)
    internal
    view
    returns (uint256 capMint)
  {
    capMint = self.capMint;
  }

  function _setMinSponsorTokens(
    DataTypes.ConfigurationData storage self,
    uint256 minSponsorTokens
  ) internal {
    require(
      self.minSponsorTokens != minSponsorTokens,
      'Min sponsor token is the same'
    );
    self.minSponsorTokens = minSponsorTokens;
    emit SetMinSponsorTokens(minSponsorTokens);
  }

  function _getMinSponsorTokens(DataTypes.ConfigurationData memory self)
    internal
    view
    returns (uint256 minSponsorTokens)
  {
    minSponsorTokens = self.minSponsorTokens;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {DataTypes} from './DataTypes.sol';

contract CreditLineStorageV3 {
  // Maps user addresses to their positions. Each user can have only one position.
  mapping(address => DataTypes.UserPositionData) internal positions;

  DataTypes.GlobalPositionData internal globalPositionData;

  DataTypes.ConfigurationData internal configurationData;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {IPool} from '../../lending-module/interfaces/IAaveV3.sol';
import {
  ILendingCreditLineManager
} from '../../lending-module/interfaces/ILendingCreditLineManager.sol';
import {
  ILendingCreditLineStorageManager
} from '../../lending-module/interfaces/ILendingCreditLineStorageManager.sol';

library DataTypes {
  struct Roles {
    address admin;
    address maintainer;
  }

  // Represents a single sponsor's position. All collateral is held by this contract.
  // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
  struct UserPositionData {
    uint256 tokensOutstanding;
    uint256 depositedCollateral;
  }

  struct GlobalPositionData {
    // Keep track of the total tokens across all positions
    uint256 totalTokensOutstanding;
    // Keep track of the total collateral across all positions
    uint256 totalPositionCollateral;
  }

  struct ConfigurationData {
    // SynthereumFinder contract
    ISynthereumFinder synthereumFinder;
    // Collateral token
    IStandardERC20 collateralToken;
    // Synthetic token created by this contract.
    IMintableBurnableERC20 tokenCurrency;
    ILendingCreditLineManager lendingCreditLineManager;
    ILendingCreditLineStorageManager lendingCreditLineStorageManager;
    // Unique identifier for DVM price feed ticker.
    bytes32 priceIdentifier;
    // Minimum number of tokens in a sponsor's position.
    uint256 minSponsorTokens;
    // Expiry price pulled from Chainlink in the case of an emergency shutdown.
    uint256 emergencyShutdownPrice;
    // Timestamp used in case of emergency shutdown.
    uint256 emergencyShutdownTimestamp;
    uint256 capMint;
    uint256 liquidationReward;
    uint256 collateralRequirement;
    // The excessTokenBeneficiary of any excess tokens added to the contract.
    address excessTokenBeneficiary;
    // Version of the self-minting derivative
    uint8 version;
  }

  /**
   * @notice Construct the PerpetualPositionManager.
   * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
   * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
   * can mint new tokens, which could be used to steal all of this contract's locked collateral.
   * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
   * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
   * total supply is 0 prior to construction of this contract.
   * @param collateralAddress ERC20 token used as collateral for all positions.
   * @param tokenAddress ERC20 token used as synthetic token.
   * @param synthereumFinder The SynthereumFinder contract
   * @param creditLineManager The CreditLineManager contract
   * @param creditLineStorageManager The CreditLineStorageManager contract
   * @param priceFeedIdentifier registered in the ChainLink Oracle for the synthetic.
   * @param minSponsorTokens minimum amount of collateral that must exist at any time in a position.
   * @param capMint Mint cap amount for self-minting derivative
   * @param liquidationReward Percentage of reward for correct liquidation by a liquidator
   * @param collateralRequirement Over collateralization percentage for self-minting derivative
   * @param excessTokenBeneficiary Beneficiary to send all excess token balances that accrue in the contract.
   * @param version Version of the self-minting derivative
   */
  struct PositionManagerParams {
    Roles roles;
    IStandardERC20 collateralToken;
    IMintableBurnableERC20 syntheticToken;
    ISynthereumFinder synthereumFinder;
    ILendingCreditLineManager lendingCreditLineManager;
    ILendingCreditLineStorageManager lendingCreditLineStorageManager;
    bytes32 priceFeedIdentifier;
    uint256 minSponsorTokens;
    uint256 capMint;
    uint256 liquidationReward;
    uint256 collateralRequirement;
    uint8 version;
  }

  struct LiquidationData {
    address sponsor;
    address liquidator;
    uint256 liquidationTime;
    uint256 numTokensBurnt;
    uint256 liquidatedCollateral;
  }

  struct ExecuteLiquidationData {
    uint256 tokensToLiquidate;
    uint256 collateralValueLiquidatedTokens;
    uint256 collateralLiquidated;
    uint256 liquidatorReward;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

library ManagerDataTypes {
  struct Roles {
    address admin;
    address maintainer;
  }

  struct UserInterestData {
    uint256 accDiscountRate; // User's accDiscountRate use to calculate total user's balance
    uint256 pendingJrtBuybackInterest; // Interest amount that can be claim for the jrt buy back
  }

  struct CreditLineInfo {
    bytes32 lendingModuleId; // hash of the lending module id associated with the LendingInfo the creditLine currently is using
    address collateralToken; // collateral address of the creditLine
    address interestBearingToken; // interest token address of the creditLine
    uint256 commissionInterest; // Interest amount that can be claim for the commissionner
    uint256 protocolFees; // Interest amount that can be claim for the protocol
    uint256 balanceTracker;
    uint256 accRate;
    uint64 commissionInterestShare; // percentage of interests took from new rewards
    uint64 protocolFeesPercentage; // percentage of interests took mint/redeem/repay user action
    uint64 jrtInterestShare; // percentage of interests used for splitting jrt interests and collateral for the users
  }

  struct LendingStorage {
    address collateralToken; // address of the collateral token of a creditLine
    address interestToken; // address of interest token of a creditLine
  }

  struct LendingInfo {
    address lendingModule; // address of the ILendingModule interface implementer
    bytes args; // encoded args the ILendingModule implementer might need
  }

  struct ReturnValues {
    uint256 interest; //accumulated creditLine interest since last state-changing operation;
    uint256 commissionInterest; //acccumulated dao interest since last state-changing operation;
    uint256 tokensOut; //amount of collateral used for a money market operation
    uint256 tokensTransferred; //amount of tokens finally transfered/received from money market (after eventual fees)
    uint256 prevTotalCollateral; //total collateral in the creditLine before new operation
  }

  struct MigrateReturnValues {
    uint256 prevTotalCollateral; // prevDepositedCollateral collateral deposited (without last interests) before the migration
    uint256 actualTotalCollateral; // actualCollateralDeposited collateral deposited after the migration
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumDeployment {
  /**
   * @notice Get Synthereum finder of the pool/self-minting derivative
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return contractVersion Returns the version of this pool/self-minting derivative
   */
  function version() external view returns (uint8 contractVersion);

  /**
   * @notice Get the collateral token of this pool/self-minting derivative
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool/self-minting derivative
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IEmergencyShutdown {
  /**
   * @notice Shutdown the pool or self-minting-derivative in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    returns (uint256 timestamp, uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ITypology {
  /**
   * @notice Return typology of the contract
   */
  function typology() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(
        iszero(b),
        iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
      ) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(
        iszero(b),
        iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
      ) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/** @title Interface for interacting with the SelfMintingController
 */
interface ICreditLineControllerV3 {
  /**
   * @notice Allow to set collateralRequirement percentage on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param collateralRequirements Over collateralization percentage for self-minting derivatives
   */
  function setCollateralRequirement(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata collateralRequirements
  ) external;

  /**
   * @notice Allow to set capMintAmount on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capMintAmounts Mint cap amounts for self-minting derivatives
   */
  function setCapMintAmount(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capMintAmounts
  ) external;

  /**
   * @notice Allow to set fee percentages on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param feePercentages fee percentages for self-minting derivatives
   */
  function setFeePercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata feePercentages
  ) external;

  /**
   * @notice Update the addresses and weight of recipients for generated fees
   * @param selfMintingDerivatives Derivatives to update
   * @param feeRecipients A two-dimension array containing for each derivative the addresses of fee recipients
   * @param feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata selfMintingDerivatives,
    address[][] calldata feeRecipients,
    uint32[][] calldata feeProportions
  ) external;

  /**
   * @notice Update the liquidation reward percentage
   * @param selfMintingDerivatives Derivatives to update
   * @param _liquidationRewards Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationRewardPercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata _liquidationRewards
  ) external;

  /**
   * @notice Gets the over collateralization percentage of a self-minting derivative
   * @param selfMintingDerivative Derivative to read value of
   * @return the collateralRequirement percentage
   */
  function getCollateralRequirement(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Gets the set liquidtion reward percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return liquidation Reward percentage
   */
  function getLiquidationRewardPercentage(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Gets the set CapMintAmount of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return capMintAmount Limit amount for minting
   */
  function getCapMintAmount(address selfMintingDerivative)
    external
    view
    returns (uint256 capMintAmount);

  /**
   * @notice Gets the fee percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return feePercentage value
   */
  function feePercentage(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Returns fee recipients info
   * @return Addresses, weigths and total of weigtht
   */
  function feeRecipientsInfo(address selfMintingDerivative)
    external
    view
    returns (
      address[] memory,
      uint32[] memory,
      uint256
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumPriceFeed {
  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param _priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 _priceIdentifier)
    external
    view
    returns (uint256 price);

  /**
   * @notice Return if price identifier is supported
   * @param _priceIdentifier Price feed identifier
   * @return isSupported True if price is supported otherwise false
   */
  function isPriceSupported(bytes32 _priceIdentifier)
    external
    view
    returns (bool isSupported);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IPool {
  struct ReserveConfigurationMap {
    uint256 data;
  }

  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param _asset The address of the underlying asset to supply
   * @param _amount The amount to be supplied
   * @param _onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param _referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address _asset,
    uint256 _amount,
    address _onBehalfOf,
    uint16 _referralCode
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param _asset The address of the underlying asset to withdraw
   * @param _amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param _to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address _asset,
    uint256 _amount,
    address _to
  ) external returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param _asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address _asset)
    external
    view
    returns (ReserveData memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  BaseControlledMintableBurnableERC20
} from '../../tokens/BaseControlledMintableBurnableERC20.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  ILendingCreditLineManager
} from '../../lending-module/interfaces/ILendingCreditLineManager.sol';
import {
  ILendingCreditLineStorageManager
} from '../../lending-module/interfaces/ILendingCreditLineStorageManager.sol';
import {CreditLineV3} from './CreditLineV3.sol';
import {DataTypes} from './DataTypes.sol';

/**
 * @title Self-Minting Contract creator.
 * @notice Factory contract to create new self-minting derivative
 */
contract CreditLineV3Creator {
  struct Params {
    DataTypes.Roles roles;
    IStandardERC20 collateralToken;
    string lendingID;
    string syntheticName;
    string syntheticSymbol;
    bytes32 priceFeedIdentifier;
    uint256 liquidationPercentage;
    uint256 capMintAmount;
    uint256 collateralRequirement;
    uint256 minSponsorTokens;
    uint64 commissionInterestShare;
    address interestBearingToken;
    uint64 jrtInterestShare;
    address syntheticToken;
    uint64 protocolFeesPercentage;
    uint8 version;
  }

  // Address of Synthereum Finder
  ISynthereumFinder public immutable synthereumFinder;

  //----------------------------------------
  // Events
  //----------------------------------------

  event newCreditLine(
    address indexed creditLine,
    address collateralToken,
    address syntheticToken,
    uint8 version
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the Perpetual contract.
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   */
  constructor(address _synthereumFinder) {
    synthereumFinder = ISynthereumFinder(_synthereumFinder);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Creates an instance of creditLine
   * @param params is a `ConstructorParams` object from creditLine.
   * @return creditLine address of the deployed contract.
   */
  function createSelfMintingDerivative(Params calldata params)
    public
    virtual
    returns (address creditLine)
  {
    _validateSyntheticToken(
      params.syntheticName,
      params.syntheticSymbol,
      params.syntheticToken
    );

    creditLine = address(new CreditLineV3(_convertParams(params)));

    _registerCreditLineToLendingModule(creditLine, params);

    emit newCreditLine(
      creditLine,
      address(params.collateralToken),
      address(params.syntheticToken),
      params.version
    );
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  // Converts createPerpetual params to constructor params.
  function _convertParams(Params calldata params)
    internal
    view
    returns (DataTypes.PositionManagerParams memory constructorParams)
  {
    constructorParams.synthereumFinder = synthereumFinder;

    require(params.roles.admin != address(0), 'Admin cannot be address(0)');
    require(
      params.roles.maintainer != address(0),
      'Maintainer cannot be address(0)'
    );
    constructorParams.roles = params.roles;

    constructorParams.syntheticToken = IMintableBurnableERC20(
      address(params.syntheticToken)
    );
    constructorParams.collateralToken = params.collateralToken;
    constructorParams.lendingCreditLineManager = getLendingCreditLineManager();
    constructorParams
      .lendingCreditLineStorageManager = getLendingCreditLineStorageManager();
    constructorParams.priceFeedIdentifier = params.priceFeedIdentifier;
    constructorParams.minSponsorTokens = params.minSponsorTokens;
    constructorParams.capMint = params.capMintAmount;
    constructorParams.liquidationReward = params.liquidationPercentage;
    constructorParams.collateralRequirement = params.collateralRequirement;
    constructorParams.version = params.version;
  }

  /** @notice Sets the controller values for a self-minting derivative
   * @param params is a `ConstructorParams` object from creditLine.
   * This value is updatable
   */
  function _registerCreditLineToLendingModule(
    address creditLine,
    Params calldata params
  ) internal {
    ILendingCreditLineStorageManager lendingCreditLineStorageManager =
      getLendingCreditLineStorageManager();

    lendingCreditLineStorageManager.setCreditLineInfo(
      params.lendingID,
      creditLine,
      address(params.collateralToken),
      address(params.interestBearingToken),
      params.commissionInterestShare,
      params.jrtInterestShare,
      params.protocolFeesPercentage
    );
  }

  function _validateSyntheticToken(
    string memory syntheticName,
    string memory syntheticSymbol,
    address syntheticToken
  ) internal {
    // Create a new synthetic token using the params.
    require(bytes(syntheticName).length != 0, 'Missing synthetic name');
    require(bytes(syntheticSymbol).length != 0, 'Missing synthetic symbol');
    require(
      syntheticToken != address(0),
      'Synthetic token address cannot be 0x00'
    );

    BaseControlledMintableBurnableERC20 tokenCurrency =
      BaseControlledMintableBurnableERC20(syntheticToken);
    require(
      keccak256(abi.encodePacked(tokenCurrency.name())) ==
        keccak256(abi.encodePacked(syntheticName)),
      'Wrong synthetic token name'
    );
    require(
      keccak256(abi.encodePacked(tokenCurrency.symbol())) ==
        keccak256(abi.encodePacked(syntheticSymbol)),
      'Wrong synthetic token symbol'
    );
  }

  function getLendingCreditLineStorageManager()
    internal
    view
    returns (ILendingCreditLineStorageManager)
  {
    return
      ILendingCreditLineStorageManager(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingCreditLineStorageManager
        )
      );
  }

  function getLendingCreditLineManager()
    internal
    view
    returns (ILendingCreditLineManager)
  {
    return
      ILendingCreditLineManager(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingCreditLineManager
        )
      );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from '../../@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IMintableBurnableERC20} from './interfaces/IMintableBurnableERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
abstract contract BaseControlledMintableBurnableERC20 is
  IMintableBurnableERC20,
  ERC20
{
  uint8 private _decimals;

  /**
   * @notice Constructs the ERC20 token contract
   * @param _tokenName Name of the token
   * @param _tokenSymbol Token symbol
   * @param _tokenDecimals Number of decimals for token
   */
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  ) ERC20(_tokenName, _tokenSymbol) {
    _setupDecimals(_tokenDecimals);
  }

  /**
   * @notice Add Minter role to an account
   * @param account Address to which Minter role will be added
   */
  function addMinter(address account) external virtual;

  /**
   * @notice Add Burner role to an account
   * @param account Address to which Burner role will be added
   */
  function addBurner(address account) external virtual;

  /**
   * @notice Add Admin role to an account
   * @param account Address to which Admin role will be added
   */
  function addAdmin(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  function addAdminAndMinterAndBurner(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  /**
   * @notice Self renounce the address calling the function from minter role
   */
  function renounceMinter() external virtual;

  /**
   * @notice Self renounce the address calling the function from burner role
   */
  function renounceBurner() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin role
   */
  function renounceAdmin() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin, minter and burner role
   */
  function renounceAdminAndMinterAndBurner() external virtual;

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals()
    public
    view
    virtual
    override(ERC20, IMintableBurnableERC20)
    returns (uint8)
  {
    return _decimals;
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {
  ISynthereumCollateralWhitelist
} from '../../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {FactoryConditions} from '../../common/FactoryConditions.sol';
import {CreditLineV3Creator} from './CreditLineV3Creator.sol';

/** @title Contract factory of self-minting derivatives
 */
contract CreditLineV3Factory is
  IDeploymentSignature,
  ReentrancyGuard,
  FactoryConditions,
  CreditLineV3Creator
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public immutable override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the CreditLineFactory contract
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   */
  constructor(address _synthereumFinder)
    CreditLineV3Creator(_synthereumFinder)
  {
    deploymentSignature = this.createSelfMintingDerivative.selector;
  }

  /**
   * @notice Check if the sender is the deployer and deploy a new creditLine contract
   * @param params is a `ConstructorParams` object from creditLine.
   * @return creditLine address of the deployed contract.
   */
  function createSelfMintingDerivative(Params calldata params)
    public
    override
    onlyDeployer(synthereumFinder)
    nonReentrant
    returns (address creditLine)
  {
    checkDeploymentConditions(
      synthereumFinder,
      params.collateralToken,
      params.priceFeedIdentifier
    );
    creditLine = super.createSelfMintingDerivative(params);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides signature of function for deployment
 */
interface IDeploymentSignature {
  /**
   * @notice Returns the bytes4 signature of the function used for the deployment of a contract in a factory
   * @return signature returns signature of the deployment function
   */
  function deploymentSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title An interface to track a whitelist of addresses.
 */
interface ISynthereumCollateralWhitelist {
  /**
   * @notice Adds an address to the whitelist.
   * @param newCollateral the new address to add.
   */
  function addToWhitelist(address newCollateral) external;

  /**
   * @notice Removes an address from the whitelist.
   * @param collateralToRemove The existing address to remove.
   */
  function removeFromWhitelist(address collateralToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param collateralToCheck The address to check.
   * @return True if `collateralToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(address collateralToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all addresses that are currently included in the whitelist.
   * @return The list of addresses on the whitelist.
   */
  function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title An interface to track a whitelist of identifiers.
 */
interface ISynthereumIdentifierWhitelist {
  /**
   * @notice Adds an identifier to the whitelist.
   * @param newIdentifier the new identifier to add.
   */
  function addToWhitelist(bytes32 newIdentifier) external;

  /**
   * @notice Removes an identifier from the whitelist.
   * @param identifierToRemove The existing identifier to remove.
   */
  function removeFromWhitelist(bytes32 identifierToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param identifierToCheck The address to check.
   * @return True if `identifierToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(bytes32 identifierToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all identifiers that are currently included in the whitelist.
   * @return The list of identifiers on the whitelist.
   */
  function getWhitelist() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../base/interfaces/IStandardERC20.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {
  ISynthereumCollateralWhitelist
} from '../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';

/** @title Contract to use iniside factories for checking deployment data
 */
contract FactoryConditions {
  /**
   * @notice Check if the sender is the deployer
   */
  modifier onlyDeployer(ISynthereumFinder _synthereumFinder) {
    address deployer =
      _synthereumFinder.getImplementationAddress(SynthereumInterfaces.Deployer);
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    _;
  }

  /**
   * @notice Check if the sender is the deployer and if identifier and collateral are supported
   * @param _synthereumFinder Synthereum finder
   * @param _collateralToken Collateral token to check if it's in the whithelist
   * @param _priceFeedIdentifier Identifier to check if it's in the whithelist
   */
  function checkDeploymentConditions(
    ISynthereumFinder _synthereumFinder,
    IStandardERC20 _collateralToken,
    bytes32 _priceFeedIdentifier
  ) internal view {
    address deployer =
      _synthereumFinder.getImplementationAddress(SynthereumInterfaces.Deployer);
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    ISynthereumCollateralWhitelist collateralWhitelist =
      ISynthereumCollateralWhitelist(
        _synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.CollateralWhitelist
        )
      );
    require(
      collateralWhitelist.isOnWhitelist(address(_collateralToken)),
      'Collateral not supported'
    );
    ISynthereumIdentifierWhitelist identifierWhitelist =
      ISynthereumIdentifierWhitelist(
        _synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.IdentifierWhitelist
        )
      );
    require(
      identifierWhitelist.isOnWhitelist(_priceFeedIdentifier),
      'Identifier not supported'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControlEnumerable {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {
  EnumerableMap
} from '../../@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
contract SynthereumFactoryVersioning is
  ISynthereumFactoryVersioning,
  AccessControlEnumerable
{
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => EnumerableMap.UintToAddressMap) private factories;

  //----------------------------------------
  // Events
  //----------------------------------------

  event AddFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event SetFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event RemoveFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------
  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external override onlyMaintainer {
    require(factory != address(0), 'Factory cannot be address 0');
    bool isNewVersion = factories[factoryType].set(version, factory);
    if (isNewVersion) {
      emit AddFactory(factoryType, version, factory);
    } else {
      emit SetFactory(factoryType, version, factory);
    }
  }

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version)
    external
    override
    onlyMaintainer
  {
    EnumerableMap.UintToAddressMap storage selectedFactories =
      factories[factoryType];
    address factoryToRemove = selectedFactories.get(version);
    selectedFactories.remove(version);
    emit RemoveFactory(factoryType, version, factoryToRemove);
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    override
    returns (address factory)
  {
    factory = factories[factoryType].get(version);
  }

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfFactoryVersions(bytes32 factoryType)
    external
    view
    override
    returns (uint8 numberOfVersions)
  {
    numberOfVersions = uint8(factories[factoryType].length());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}