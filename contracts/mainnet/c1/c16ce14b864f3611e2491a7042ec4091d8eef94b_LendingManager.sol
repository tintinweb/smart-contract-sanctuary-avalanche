// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILendingModule.sol";
import "./interfaces/ILendingManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract LendingManager is ILendingManager, Ownable {
    using SafeERC20 for IERC20;

    // states
    address private coreManager;
    ILendingModule private lendingModule;

    address public immutable suppliedAsset;

    // constants
    uint16 public constant MAX_BPS = 10000;
    uint256 public constant MIN_LTV = 4800;
    uint256 public constant TARGET_LTV = 5000;
    uint256 public constant MAX_LTV = 5200;

    // map asset -> chainlink price feed
    mapping(address => address) private priceFeeds;

    // track the borrow amount without the debt interest
    uint256 public borrowAmount;

    modifier onlyCoreManager() {
        require(coreManager != address(0), "coreManager not set");
        require(msg.sender == coreManager, "!coreManager");
        _;
    }

    constructor(address _lendingModule, address _suppliedAsset, address[] memory _assets, address[] memory _priceFeeds) {
        lendingModule = ILendingModule(_lendingModule);

        suppliedAsset = _suppliedAsset;

        require(_assets.length == _priceFeeds.length, "not same length");
        for(uint256 i = 0; i < _assets.length; i++) {
            priceFeeds[_assets[i]] = _priceFeeds[i];
        }
    }

    /** owner **/

    function getCoreManager() public view returns (address) {
        return coreManager;
    }

    function setCoreManager(address _stratManager) public onlyOwner {
        require(_stratManager != address(0), "invalid address");
        coreManager = _stratManager;
    }

    function getLendingModule() public view returns (address) {
        return address(lendingModule);
    }

    // Set the active lending module
    // (for now the lending manager does not support to interacte with two lending module at the same time)
    function setLendingModule(address _lendingModule) public onlyOwner {
        require(_lendingModule != address(0), "invalid address");
        lendingModule = ILendingModule(_lendingModule);
    }

    function getPriceFeed(address asset) public view returns (address) {
        return priceFeeds[asset];
    }

    function addPriceFeeds(address[] calldata _assets, address[] calldata _priceFeeds) public onlyOwner {
        require(_assets.length == _priceFeeds.length, "not same length");
        for(uint256 i = 0; i < _assets.length; i++) {
            priceFeeds[_assets[i]] = _priceFeeds[i];
        }
    }

    function removePriceFeeds(address[] calldata _assets) public onlyOwner {
        for(uint256 i = 0; i < _assets.length; i++) {
            priceFeeds[_assets[i]] = address(0);
        }
    }

    /** core **/

    function supplyMax() public onlyCoreManager {
        uint256 amount = IERC20(suppliedAsset).balanceOf(coreManager);
        IERC20(suppliedAsset).transferFrom(coreManager, address(lendingModule), amount);
        lendingModule.supply(amount);
    }

    function withdraw(uint256 amount) public onlyCoreManager {
        lendingModule.withdraw(amount);
        IERC20(suppliedAsset).transferFrom(address(lendingModule), coreManager, amount);
    }

    function withdrawMax() public onlyCoreManager {
        uint256 amount = lendingModule.getSupplyBalance();
        lendingModule.withdraw(amount);
        IERC20(suppliedAsset).transferFrom(address(lendingModule), coreManager, amount);
    }

    function borrowMax(address asset) public onlyCoreManager returns (uint256) {
        require(getCurrentLtv() < MIN_LTV, "LTV > MIN_LTV");
        uint256 currentSupplyBalanceBase = lendingModule.getSupplyBalanceBase();
        uint256 currentBorrowBalanceBase = lendingModule.getBorrowBalanceBase();
        uint256 targetBorrowBalanceBase = currentSupplyBalanceBase * TARGET_LTV / MAX_BPS;
        // Check preventing revert due to negative amountBase
        if (targetBorrowBalanceBase <= currentBorrowBalanceBase) {
            return 0;
        }
        // The usd amount to borrow to meet the target ltv
        uint256 amountBase = targetBorrowBalanceBase - currentBorrowBalanceBase;
        // The token amount to borrow to meet the target ltv
        uint256 amount = _baseAmountToTokenAmount(asset, amountBase);
        borrowAmount += amount;
        lendingModule.borrow(asset, amount);
        IERC20(asset).transferFrom(address(lendingModule), coreManager, amount);
        return amount;
    }

    function repay(address asset, uint256 amount) public onlyCoreManager {
        require(amount <= borrowAmount, "amount > borrowAmount");
        IERC20(asset).transferFrom(coreManager, address(lendingModule), amount);
        lendingModule.repay(asset, amount);        
        borrowAmount -= amount;
    }

    function repayBorrowInterest(address asset) public onlyCoreManager {
        uint256 amount = getBorrowInterestAmount(asset);
        IERC20(asset).transferFrom(coreManager, address(lendingModule), amount);
        lendingModule.repay(asset, amount);        
    }

    function repayMax(address asset) public onlyCoreManager {
        uint256 amount = lendingModule.getBorrowBalance(asset);
        IERC20(asset).transferFrom(coreManager, address(lendingModule), amount);
        lendingModule.repay(asset, amount);
        borrowAmount = 0;
    }

    function deleverage(address asset) public onlyCoreManager {
        require(getCurrentLtv() > MAX_LTV, "LTV < MAX_LTV");
        uint256 amount = IERC20(asset).balanceOf(coreManager);
        IERC20(asset).transferFrom(coreManager, address(lendingModule), amount);
        lendingModule.repay(asset, amount);        
        borrowAmount -= amount;
    }

    function harvest() public onlyCoreManager returns (uint256) {
        uint256 amount = lendingModule.harvest();
        IERC20(suppliedAsset).transferFrom(address(lendingModule), coreManager, amount);
        return amount;
    }

    function getBorrowInterestAmount(address asset) public view returns (uint256) {
        uint256 currentVariableDebt = lendingModule.getBorrowBalance(asset);
        if (currentVariableDebt <= borrowAmount) {
            return 0;
        }
        else {
            return currentVariableDebt - borrowAmount;
        }
    }

    // Return the amount of tokens that need to be repaid to have the LTV equal the target LTV
    // If amount returned > zero -> need to deleverage
    // If amount returned == zero -> no need to deleverage
    function getDeleverageAmount(address asset) public view returns (uint256) {
        uint256 currentSupplyBalanceBase = lendingModule.getSupplyBalanceBase();
        uint256 currentBorrowBalanceBase = lendingModule.getBorrowBalanceBase();
        uint256 targetBorrowBalanceBase = currentSupplyBalanceBase * TARGET_LTV / MAX_BPS;
        // Check preventing revert due to negative amountBase
        if (currentBorrowBalanceBase <= targetBorrowBalanceBase) {
            return 0;
        }
        // The usd amount to borrow to meet the target ltv
        uint256 amountBase = currentBorrowBalanceBase - targetBorrowBalanceBase;
        // The token amount to borrow to meet the target ltv
        return _baseAmountToTokenAmount(asset, amountBase);
    }

    /** getters **/

    // TODO: check it returns the underlying amount
    function getSupplyBalance() public view returns (uint256) {
        return lendingModule.getSupplyBalance();
    }

    // TODO: check it returns the underlying amount
    function getBorrowBalance(address asset) public view returns (uint256) {
        return lendingModule.getBorrowBalance(asset);
    }

    function getSupplyBalanceBase() public view returns (uint256) {
        return lendingModule.getSupplyBalanceBase();
    }

    function getBorrowBalanceBase() public view returns (uint256) {
        return lendingModule.getBorrowBalanceBase();
    }

    function getCurrentLtv() public view returns (uint256) {
        uint256 currentSupplyBalanceBase = lendingModule.getSupplyBalanceBase();
        uint256 currentBorrowBalanceBase = lendingModule.getBorrowBalanceBase();
        if (currentSupplyBalanceBase == 0) {
            return 0;
        }
        return (MAX_BPS * currentBorrowBalanceBase) / currentSupplyBalanceBase;
    }

    /** helpers **/

    function chainlinkPriceAndDecimals(address asset) public view returns (uint256, uint256) {
        //TODO: price feed return an error or revert if the asset is not listed ?
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeeds[asset]);

        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        uint256 decimals = 10 ** priceFeed.decimals();

        return (uint256(price), decimals);
    }

    function _baseAmountToTokenAmount(address asset, uint256 amountBase) internal view returns (uint256) {
        (uint256 chainlinkPrice, ) = chainlinkPriceAndDecimals(asset);
        uint256 assetDecimals = 10 ** IERC20Metadata(asset).decimals();
        // Remark: amountBase and chainlinkPrice both have 8 decimals so no need to deal with decimals
        return amountBase * assetDecimals / chainlinkPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingModule {
    function getLendingManager() external view returns (address);

    function setLendingManager(address _lendingManager) external;

    function getDexModule() external view returns (address);

    // TODO: setter for the dex module

    function supply(uint256 amount) external;

    function withdraw(uint256 amount) external;
    
    function borrow(address asset, uint256 amount) external;

    function repay(address asset, uint256 amount) external;

    function harvest() external returns (uint256);

    function getSupplyBalance() external view returns (uint256);

    function getBorrowBalance(address asset) external view returns (uint256);

    function getSupplyBalanceBase() external view returns (uint256);

    function getBorrowBalanceBase() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILendingModule.sol";

// Remark: The lending manager takes care of transfering the funds between the core manager and the active module
interface ILendingManager {
    function getCoreManager() external view returns (address);

    function setCoreManager(address _stratManager) external;

    function getLendingModule() external view returns (address);

    function setLendingModule(address _lendingModule) external;

    function getPriceFeed(address asset) external view returns (address);

    function addPriceFeeds(address[] calldata _assets, address[] calldata _priceFeeds) external;

    function removePriceFeeds(address[] calldata _assets) external;

    function TARGET_LTV() external returns (uint256);

    function MIN_LTV() external returns (uint256);

    function MAX_LTV() external returns (uint256);

    // supply to the lending protocol all the tokens that have been deposited on the core manager
    function supplyMax() external;

    function withdraw(uint256 amount) external;

    // withdraw the full collateral from the lending protocol if there is no active borrow
    function withdrawMax() external;

    // borrow the maximum amount such that the LTV is 50%
    function borrowMax(address asset) external returns (uint256);

    // repay a part of the debt
    // useful when a user exit the start
    function repay(address asset, uint256 amount) external;

    // repay the borrow interest only
    // to use with getBorrowInterestAmount
    function repayBorrowInterest(address asset) external;

    // repay the borrow and the borrow interest according there is enough liquidity in the core
    // to use with getBorrowBalance
    function repayMax(address asset) external;

    // get the current LTV back the target LTV if it is above 50%
    // to use with getDeleverageAmount
    function deleverage(address asset) external;

    // claim rewards, swap them for wanted asset and send them to the core
    function harvest() external returns (uint256);

    // return the debt interest amount
    function getBorrowInterestAmount(address asset) external view returns (uint256);

    // return the amount that has to be repaid to get the LTV back to the target LTV
    function getDeleverageAmount(address asset) external view returns (uint256);

    // return the amount of token in collateral
    function getSupplyBalance() external returns (uint256);

    // return the amount of borrowed token
    function getBorrowBalance(address asset) external view returns (uint256);

    // return the collateral amount in USD
    function getSupplyBalanceBase() external view returns (uint256);

    // return the borrow amount in USD
    function getBorrowBalanceBase() external view returns (uint256);

    // return the current LTV (with a factor 100 to avoid rounding error, i.e., if the return value is 5000 it means that the LTV is 50%)
    function getCurrentLtv() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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