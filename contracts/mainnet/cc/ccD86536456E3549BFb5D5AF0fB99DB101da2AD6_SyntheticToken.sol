// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./access/Manageable.sol";
import "./lib/WadRayMath.sol";
import "./storage/SyntheticTokenStorage.sol";

/**
 * @title Synthetic Token contract
 */
contract SyntheticToken is ReentrancyGuard, Manageable, SyntheticTokenStorageV1 {
    using WadRayMath for uint256;

    string public constant VERSION = "1.0.0";

    uint256 public constant BLOCKS_PER_YEAR = 2336000;

    /// @notice Emitted when synthetic token is issued
    event SyntheticTokenIssued(address indexed account, address indexed to, uint256 amount, uint256 fee);

    /// @notice Emitted when synthetic's debt is repayed
    event DebtRepayed(address indexed account, uint256 amount, uint256 fee);

    /**
     * @dev Throws if synthetic token doesn't exist
     */
    modifier onlyIfSyntheticTokenExists() {
        require(controller.isSyntheticTokenExists(this), "synthetic-inexistent");
        _;
    }

    /**
     * @dev Throws if synthetic token isn't enabled
     */
    modifier onlyIfSyntheticTokenIsActive() {
        require(isActive, "synthetic-inactive");
        _;
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        IController _controller,
        IDebtToken _debtToken,
        uint256 _interestRate,
        uint256 _maxTotalSupplyInUsd
    ) public initializer {
        require(address(_debtToken) != address(0), "debt-token-is-null");
        require(_decimals == _debtToken.decimals(), "debt-decimals-is-not-the-same");
        require(address(_controller) != address(0), "controller-address-is-zero");

        __Manageable_init();

        controller = _controller;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        debtToken = _debtToken;
        isActive = true;
        interestRate = _interestRate;
        maxTotalSupplyInUsd = _maxTotalSupplyInUsd;
    }

    /// @notice Emitted when max total supply is updated
    event MaxTotalSupplyUpdated(uint256 oldMaxTotalSupply, uint256 newMaxTotalSupply);

    /// @notice Emitted when active flag is updated
    event SyntheticTokenActiveUpdated(bool oldActive, bool newActive);

    /// @notice Emitted when interest rate is updated
    event InterestRateUpdated(uint256 oldInterestRate, uint256 newInterestRate);

    function interestRatePerBlock() external view virtual override returns (uint256) {
        return interestRate / BLOCKS_PER_YEAR;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "amount-exceeds-allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, allowance[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = allowance[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "decreased-allowance-below-zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "transfer-from-the-zero-address");
        require(recipient != address(0), "transfer-to-the-zero-address");

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "transfer-amount-exceeds-balance");
        unchecked {
            balanceOf[sender] = senderBalance - amount;
        }
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) private onlyIfSyntheticTokenIsActive {
        require(account != address(0), "mint-to-the-zero-address");
        uint256 _newTotalSupplyInUsd = controller.masterOracle().convertToUsd(this, totalSupply + amount);
        require(_newTotalSupplyInUsd <= maxTotalSupplyInUsd, "surpass-max-total-supply");

        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "burn-from-the-zero-address");

        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "burn-amount-exceeds-balance");
        unchecked {
            balanceOf[account] = accountBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "approve-from-the-zero-address");
        require(spender != address(0), "approve-to-the-zero-address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Lock collateral and mint synthetic token
     * @param _amount The amount to mint
     */
    function issue(uint256 _amount, address _to)
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists
        onlyIfSyntheticTokenIsActive
    {
        require(_amount > 0, "amount-is-zero");

        address _account = _msgSender();

        accrueInterest();

        (, , , , uint256 _issuableInUsd) = controller.debtPositionOf(_account);

        IMasterOracle _masterOracle = controller.masterOracle();

        require(_amount <= _masterOracle.convertFromUsd(this, _issuableInUsd), "not-enough-collateral");

        uint256 _debtFloorInUsd = controller.debtFloorInUsd();

        if (_debtFloorInUsd > 0) {
            require(
                _masterOracle.convertToUsd(this, debtToken.balanceOf(_account) + _amount) >= _debtFloorInUsd,
                "debt-lt-floor"
            );
        }

        uint256 _issueFee = controller.issueFee();
        uint256 _amountToIssue = _amount;
        uint256 _feeAmount;
        if (_issueFee > 0) {
            _feeAmount = _amount.wadMul(_issueFee);
            _mint(address(controller.treasury()), _feeAmount);
            _amountToIssue -= _feeAmount;
        }

        _mint(_to, _amountToIssue);
        debtToken.mint(_account, _amount);

        emit SyntheticTokenIssued(_account, _to, _amount, _feeAmount);
    }

    /**
     * @notice Send synthetic token to decrease debt
     * @dev The msg.sender is the payer and the account beneficied
     * @param _onBehalfOf The account that will have debt decreased
     * @param _amount The amount of synthetic token to burn (should consider the repay fee)
     */
    function repay(address _onBehalfOf, uint256 _amount) external override whenNotShutdown nonReentrant {
        require(_amount > 0, "amount-is-zero");

        accrueInterest();

        address _payer = _msgSender();

        uint256 _repayFee = controller.repayFee();
        uint256 _amountToRepay = _amount;
        uint256 _feeAmount;
        if (_repayFee > 0) {
            _amountToRepay = _amount.wadDiv(1e18 + _repayFee);
            _feeAmount = _amount - _amountToRepay;
            _transfer(_payer, address(controller.treasury()), _feeAmount);
        }

        uint256 _debtFloorInUsd = controller.debtFloorInUsd();

        if (_debtFloorInUsd > 0) {
            uint256 _newDebtInUsd = controller.masterOracle().convertToUsd(
                this,
                debtToken.balanceOf(_onBehalfOf) - _amountToRepay
            );
            require(_newDebtInUsd == 0 || _newDebtInUsd >= _debtFloorInUsd, "debt-lt-floor");
        }

        _burn(_payer, _amountToRepay);
        debtToken.burn(_onBehalfOf, _amountToRepay);

        emit DebtRepayed(_onBehalfOf, _amount, _feeAmount);
    }

    /**
     * @notice Mint synthetic token
     * @param _to The account to mint to
     * @param _amount The amount to mint
     */
    function mint(address _to, uint256 _amount) external override onlyController {
        _mint(_to, _amount);
    }

    /**
     * @notice Burn synthetic token
     * @param _from The account to burn from
     * @param _amount The amount to burn
     */
    function burn(address _from, uint256 _amount) external override onlyController {
        _burn(_from, _amount);
    }

    /**
     * @notice Update max total supply (in USD)
     * @param _newMaxTotalSupplyInUsd The new max total supply (in USD)
     */
    function updateMaxTotalSupplyInUsd(uint256 _newMaxTotalSupplyInUsd) external override onlyGovernor {
        uint256 _currentMaxTotalSupplyInUsd = maxTotalSupplyInUsd;
        require(_newMaxTotalSupplyInUsd != _currentMaxTotalSupplyInUsd, "new-same-as-current");
        emit MaxTotalSupplyUpdated(_currentMaxTotalSupplyInUsd, _newMaxTotalSupplyInUsd);
        maxTotalSupplyInUsd = _newMaxTotalSupplyInUsd;
    }

    /**
     * @notice Enable/Disable the Synthetic Token
     */
    function toggleIsActive() external override onlyGovernor {
        bool _isActive = isActive;
        emit SyntheticTokenActiveUpdated(_isActive, !_isActive);
        isActive = !_isActive;
    }

    /**
     * @notice Update interest rate (APR)
     */
    function updateInterestRate(uint256 _newInterestRate) external onlyGovernor {
        accrueInterest();
        uint256 _currentInterestRate = interestRate;
        require(_newInterestRate != _currentInterestRate, "new-same-as-current");
        emit InterestRateUpdated(_currentInterestRate, _newInterestRate);
        interestRate = _newInterestRate;
    }

    /**
     * @notice Accrue interest
     */
    function accrueInterest() public {
        uint256 _interestAmountAccrued = debtToken.accrueInterest();

        if (_interestAmountAccrued > 0) {
            // Note: We can save some gas by incrementing only and mint all accrued amount later
            _mint(address(controller.treasury()), _interestAmountAccrued);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/Context.sol";
import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../interface/IGovernable.sol";
import "../interface/IController.sol";

/**
 * @title Reusable contract that handles accesses
 */
abstract contract Manageable is Context, Initializable {
    /**
     * @notice Controller contract
     */
    IController public controller;

    // solhint-disable-next-line func-name-mixedcase
    function __Manageable_init() internal initializer {}

    /**
     * @notice Requires that the caller is the Controller contract
     */
    modifier onlyController() {
        require(_msgSender() == address(controller), "not-controller");
        _;
    }

    /**
     * @notice Requires that the caller is the Controller contract
     */
    modifier onlyGovernor() {
        require(_msgSender() == governor(), "not-governor");
        _;
    }

    modifier whenNotPaused() {
        require(!controller.paused(), "paused");
        _;
    }

    modifier whenNotShutdown() {
        require(!controller.everythingStopped(), "not-shutdown");
        _;
    }

    function governor() public view returns (address _governor) {
        _governor = IGovernable(address(controller)).governor();
    }

    /**
     * @notice Update Controller contract
     * @param _controller The new Controller contract
     */
    function setController(IController _controller) external onlyGovernor {
        require(address(_controller) != address(0), "new-controller-address-is-zero");
        controller = _controller;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuard is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./oracle/IMasterOracle.sol";
import "./IPausable.sol";
import "./ISyntheticToken.sol";
import "./IDepositToken.sol";
import "./ITreasury.sol";
import "./IRewardsDistributor.sol";

/**
 * @notice Controller interface
 */
interface IController is IPausable {
    function debtFloorInUsd() external returns (uint256);

    function depositFee() external returns (uint256);

    function issueFee() external returns (uint256);

    function withdrawFee() external returns (uint256);

    function repayFee() external returns (uint256);

    function isSyntheticTokenExists(ISyntheticToken _syntheticToken) external view returns (bool);

    function isDepositTokenExists(IDepositToken _depositToken) external view returns (bool);

    function depositTokenOf(IERC20 _underlying) external view returns (IDepositToken);

    function getDepositTokens() external view returns (address[] memory);

    function getSyntheticTokens() external view returns (address[] memory);

    function getRewardsDistributors() external view returns (IRewardsDistributor[] memory);

    function debtOf(address _account) external view returns (uint256 _debtInUsd);

    function depositOf(address _account) external view returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd);

    function debtPositionOf(address _account)
        external
        view
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        );

    function addSyntheticToken(address _synthetic) external;

    function removeSyntheticToken(ISyntheticToken _synthetic) external;

    function addDepositToken(address _depositToken) external;

    function removeDepositToken(IDepositToken _depositToken) external;

    function liquidate(
        ISyntheticToken _syntheticToken,
        address _account,
        uint256 _amountToRepay,
        IDepositToken _depositToken
    ) external;

    function swap(
        ISyntheticToken _syntheticTokenIn,
        ISyntheticToken _syntheticTokenOut,
        uint256 _amountIn
    ) external returns (uint256 _amountOut);

    function updateMasterOracle(IMasterOracle _newOracle) external;

    function updateDebtFloor(uint256 _newDebtFloorInUsd) external;

    function updateDepositFee(uint256 _newDepositFee) external;

    function updateIssueFee(uint256 _newIssueFee) external;

    function updateWithdrawFee(uint256 _newWithdrawFee) external;

    function updateRepayFee(uint256 _newRepayFee) external;

    function updateSwapFee(uint256 _newSwapFee) external;

    function updateLiquidatorLiquidationFee(uint256 _newLiquidatorLiquidationFee) external;

    function updateProtocolLiquidationFee(uint256 _newProtocolLiquidationFee) external;

    function updateMaxLiquidable(uint256 _newMaxLiquidable) external;

    function updateTreasury(ITreasury _newTreasury, bool _withMigration) external;

    function treasury() external view returns (ITreasury);

    function masterOracle() external view returns (IMasterOracle);

    function addToDepositTokensOfAccount(address _account) external;

    function removeFromDepositTokensOfAccount(address _account) external;

    function addToDebtTokensOfAccount(address _account) external;

    function removeFromDebtTokensOfAccount(address _account) external;

    function getDepositTokensOfAccount(address _account) external view returns (address[] memory);

    function getDebtTokensOfAccount(address _account) external view returns (address[] memory);

    function addRewardsDistributor(IRewardsDistributor _distributor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";
import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISyntheticToken.sol";

interface IDebtToken is IERC20, IERC20Metadata {
    function syntheticToken() external view returns (ISyntheticToken);

    function accrueInterest() external returns (uint256 _interestAmountAccrued);

    function debtIndex() external returns (uint256 _debtIndex);

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";
import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IDepositToken is IERC20, IERC20Metadata {
    function underlying() external view returns (IERC20);

    function collateralizationRatio() external view returns (uint256);

    function unlockedBalanceOf(address _account) external view returns (uint256);

    function lockedBalanceOf(address _account) external view returns (uint256);

    function minDepositTime() external view returns (uint256);

    function lastDepositOf(address _account) external view returns (uint256);

    function deposit(uint256 _amount, address _onBehalfOf) external;

    function withdraw(uint256 _amount, address _to) external;

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function seize(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function updateCollateralizationRatio(uint128 _newCollateralizationRatio) external;

    function isActive() external view returns (bool);

    function toggleIsActive() external;

    function maxTotalSupplyInUsd() external view returns (uint256);

    function updateMaxTotalSupplyInUsd(uint256 _newMaxTotalSupplyInUsd) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPausable {
    function paused() external returns (bool);

    function everythingStopped() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ISyntheticToken.sol";
import "./IDepositToken.sol";

/**
 * @notice Reward Distributor interface
 */
interface IRewardsDistributor {
    function rewardToken() external view returns (IERC20);

    function tokenSpeeds(IERC20 _token) external view returns (uint256);

    function tokensAccruedOf(address _account) external view returns (uint256);

    function updateBeforeMintOrBurn(IERC20 _token, address _account) external;

    function updateBeforeTransfer(
        IERC20 _token,
        address _from,
        address _to
    ) external;

    function claimRewards(address _account) external;

    function claimRewards(address _account, IERC20[] memory _tokens) external;

    function claimRewards(address[] memory _accounts, IERC20[] memory _tokens) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";
import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IDebtToken.sol";

interface ISyntheticToken is IERC20, IERC20Metadata {
    function isActive() external view returns (bool);

    function maxTotalSupplyInUsd() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function interestRatePerBlock() external view returns (uint256);

    function debtToken() external view returns (IDebtToken);

    function mint(address _to, uint256 amount) external;

    function burn(address _from, uint256 amount) external;

    function updateMaxTotalSupplyInUsd(uint256 _newMaxTotalSupply) external;

    function toggleIsActive() external;

    function updateInterestRate(uint256 _newInterestRate) external;

    function issue(uint256 _amount, address _to) external;

    function repay(address _onBehalfOf, uint256 _amount) external;

    function accrueInterest() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";

interface ITreasury {
    function pull(address _to, uint256 _amount) external;

    function migrateTo(address _newTreasury) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/token/ERC20/IERC20.sol";
import "./IPriceProvider.sol";

interface IMasterOracle {
    function convertToUsd(IERC20 _asset, uint256 _amount) external view returns (uint256 _amountInUsd);

    function convertFromUsd(IERC20 _asset, uint256 _amountInUsd) external view returns (uint256 _amount);

    function convert(
        IERC20 _assetIn,
        IERC20 _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceProvider {
    function update(bytes calldata _assetData) external;

    function getPriceInUsd(bytes calldata _assetData)
        external
        view
        returns (uint256 _priceInUsd, uint256 _lastUpdatedAt);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Math library
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */
library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * WAD + b / 2) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * RAY + b / 2) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256) {
        return ((WAD_RAY_RATIO / 2) + a) / WAD_RAY_RATIO;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a * WAD_RAY_RATIO;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interface/ISyntheticToken.sol";
import "../interface/IDebtToken.sol";

abstract contract SyntheticTokenStorageV1 is ISyntheticToken {
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;
    string public symbol;

    uint256 public totalSupply;
    uint256 public maxTotalSupplyInUsd;

    uint8 public decimals;

    /**
     * @notice Non-transferable token that represents users' debts
     */
    IDebtToken public debtToken;

    /**
     * @notice If a vsAsset isn't active, it disables minting new tokens
     */
    bool public isActive;

    /**
     * @notice Interest rate
     * @dev Use 0.1e18 for 10% APR
     */
    uint256 public interestRate;
}