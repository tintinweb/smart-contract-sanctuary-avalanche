// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILendingModule.sol";
import "./interfaces/ILendingManager.sol";
import "../common/library/Modifier.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract LendingManager is ILendingManager, Ownable, Modifier {
    using SafeERC20 for IERC20;

    ILendingModule public module;
    AggregatorV3Interface public borrowedAssetPriceFeed;
    
    address public core;
    address public immutable suppliedAsset;
    address public immutable borrowedAsset;
    // track the borrow amount without the debt interest
    uint256 public borrowAmount;

    // Precision to compute percentage (Max Basis Points)
    uint16 public constant MAX_BPS = 10000;
    // Leverage LTV threshold
    uint256 public constant MIN_LTV = 4800;
    // Target ltv
    uint256 public constant TARGET_LTV = 5000;
    // Deleverage LTV threshold
    uint256 public constant MAX_LTV = 5200;

    event Panic(uint256 withdrawnAmount);

    /**
    @dev used to restrict execution of functions to the core  
     */
    modifier onlyOwnerOrCore() {
        require((owner()) != address(0), "owner not initialized");
        require(core != address(0), "core not initialized");
        require(msg.sender == owner() || msg.sender == core, "only core or owner");
        _;
    }

    /**
    @dev used to prevent updating the module or the core if the module is not empty
     */
    modifier onlyIfEmptyModule() {
        require(isModuleEmpty(), "module not empty");
        _;
    }

    /**
    @param _module The address of the lending module
    @param _suppliedAsset The address of the asset supplied on Aave (WBTC)
    @param _borrowedAsset The address of the asset borrowed on Aave (USDC) 
    @param _borrowedAssetPriceFeed The address of the chainkink price feed of the borrowed asset
     */
    constructor(address _module, address _suppliedAsset, address _borrowedAsset, address _borrowedAssetPriceFeed) {
        module = ILendingModule(_module);
        borrowedAssetPriceFeed = AggregatorV3Interface(_borrowedAssetPriceFeed);

        suppliedAsset = _suppliedAsset;
        borrowedAsset = _borrowedAsset;
    }

    /** admin **/

    /**
    @notice Set a new core. The old one will not have access right after the new one has been set.
    @param _core The address of the new core
     */
    function setCore(address _core) external onlyOwner onlyNotZeroAddress(_core) onlyIfEmptyModule {
        core = _core;
    }

    /**
    @notice Set a new lending module.
    @param _module The address of the new lending module
     */
    function setModule(address _module) external onlyOwner onlyNotZeroAddress(_module) onlyIfEmptyModule {
        module = ILendingModule(_module);
    }

    /**
    @notice Set a new price feed for the borrowed asset
    @param _borrowedAssetPriceFeed The address of the chainlink price feed of the borrowed asset
     */
    function setBorrowedAssetPriceFeed(address _borrowedAssetPriceFeed) external onlyOwner onlyNotZeroAddress(_borrowedAssetPriceFeed) onlyIfEmptyModule {
        borrowedAssetPriceFeed = AggregatorV3Interface(_borrowedAssetPriceFeed);
    }

    /**
    @notice Query if there is liquidity in the module
    @return True if there is no liquidity and false otherwise
     */
    function isModuleEmpty() public view returns (bool) {
        return getSupplyBalance() == uint256(0) && getBorrowBalance() == uint256(0) && borrowAmount == uint256(0);
    }

    /** core **/

    /**
    @notice Supply WBTC
    @param amount The amount of WBTC to supply
     */
    function supply(uint256 amount) external onlyOwnerOrCore {
        IERC20(suppliedAsset).transferFrom(core, address(module), amount);
        module.supply(amount);
    }

    /**
    @notice Withdraw WBTC
    @param amount The amount of WBTC to withdraw
     */
    function withdraw(uint256 amount) external onlyOwnerOrCore {
        module.withdraw(amount);
        IERC20(suppliedAsset).transferFrom(address(module), core, amount);
    }

    /**
    @notice Borrow the maximum amount of USDC so that the LTV equals the traget LTV (50%)
     */
    function borrowMax() external onlyOwnerOrCore returns (uint256) {
        require(getCurrentLtv() < MIN_LTV, "LTV > MIN_LTV");
        uint256 currentSupplyBalanceBase = module.getSupplyBalanceBase();
        uint256 currentBorrowBalanceBase = module.getBorrowBalanceBase();
        uint256 targetBorrowBalanceBase = currentSupplyBalanceBase * TARGET_LTV / MAX_BPS;
        // Check preventing revert due to negative amountBase
        if (targetBorrowBalanceBase <= currentBorrowBalanceBase) {
            return 0;
        }
        // The usd amount to borrow to meet the target ltv
        uint256 amountBase = targetBorrowBalanceBase - currentBorrowBalanceBase;
        // The token amount to borrow to meet the target ltv
        uint256 amount = _baseAmountToTokenAmount(borrowedAsset, amountBase);
        borrowAmount += amount;
        module.borrow(amount);
        IERC20(borrowedAsset).transferFrom(address(module), core, amount);
        return amount;
    }

    /**
    @notice Repay a given amount of the borrowed USDC. Note that it does not repay the interest.
    @param amount The amount of USDC to repay
     */
    function repay(uint256 amount) external onlyOwnerOrCore {
        require(amount <= borrowAmount, "amount > borrowAmount");
        IERC20(borrowedAsset).transferFrom(core, address(module), amount);
        module.repay(amount);
        borrowAmount -= amount;
    }

    /**
    @notice Repay a given amount of the borrowed interest
    @param amount The amount of USDC to repay
     */
    function repayBorrowInterest(uint256 amount) external onlyOwnerOrCore {
        require(amount <= getBorrowInterestAmount(), "amount too big");
        IERC20(borrowedAsset).transferFrom(core, address(module), amount);
        module.repay(amount);
    }

    /**
    @notice Harvest the rewards (WAWAX) accrued from supplying and borrowing assets
     */
    function harvest() external onlyOwnerOrCore returns (uint256) {
        uint256 amount = module.harvest();
        IERC20(suppliedAsset).transferFrom(address(module), core, amount);
        return amount;
    }

    /**
    @notice Repay all (borrowed amount and interest) and withdraw all the supplied WBTC
     */
    function panic() external onlyOwnerOrCore {
        // Repay borrow
        uint256 borrowBalance = getBorrowBalance();
        if (borrowBalance > 0) {
            IERC20(borrowedAsset).transferFrom(core, address(module), borrowBalance);
            module.repay(borrowBalance);
        }
        borrowAmount = 0;

        // withdraw supplied asset
        uint256 supplyBalance = module.getSupplyBalance();
        if (supplyBalance > 0) {
            module.withdraw(supplyBalance);
            IERC20(suppliedAsset).transferFrom(address(module), core, supplyBalance);
        }
        
        emit Panic(supplyBalance);
    }

    /**
    @return The amount of interst generated by the borrow
     */
    function getBorrowInterestAmount() public view returns (uint256) {
        uint256 currentVariableDebt = getBorrowBalance();
        if (currentVariableDebt <= borrowAmount) {
            return 0;
        }
        else {
            return currentVariableDebt - borrowAmount;
        }
    }

    /**
    @notice Return the amount of tokens that need to be repaid to have the LTV equal the target LTV (50%)
    @return 0 if no need to deleverage and more than 0 if need to deleverage 
     */
    function getDeleverageAmount() external view returns (uint256) {
        uint256 currentSupplyBalanceBase = module.getSupplyBalanceBase();
        uint256 currentBorrowBalanceBase = module.getBorrowBalanceBase();
        uint256 targetBorrowBalanceBase = currentSupplyBalanceBase * TARGET_LTV / MAX_BPS;
        // Check preventing revert due to negative amountBase
        if (currentBorrowBalanceBase <= targetBorrowBalanceBase) {
            return 0;
        }
        // The usd amount to borrow to meet the target ltv
        uint256 amountBase = currentBorrowBalanceBase - targetBorrowBalanceBase;
        // The token amount to borrow to meet the target ltv
        return _baseAmountToTokenAmount(borrowedAsset, amountBase);
    }

    /**
    @return The amount of supplied WBTC 
     */
    function getSupplyBalance() public view returns (uint256) {
        return module.getSupplyBalance();
    }

    /**
    @return The amount of borrowed USDC
     */
    function getBorrowBalance() public view returns (uint256) {
        return module.getBorrowBalance(borrowedAsset);
    }

    /**
    @return The amount in dollars of supplied WBTC
     */
    function getSupplyBalanceBase() public view returns (uint256) {
        return module.getSupplyBalanceBase();
    }

    /**
    @return The amount in dollars of borrowed USDC
     */
    function getBorrowBalanceBase() public view returns (uint256) {
        return module.getBorrowBalanceBase();
    }

    /**
    @return The current loan to value of the positions
     */
    function getCurrentLtv() public view returns (uint256) {
        uint256 currentSupplyBalanceBase = module.getSupplyBalanceBase();
        uint256 currentBorrowBalanceBase = module.getBorrowBalanceBase();
        if (currentSupplyBalanceBase == 0) {
            return 0;
        }
        return (MAX_BPS * currentBorrowBalanceBase) / currentSupplyBalanceBase;
    }

    /** helpers **/

    /**
    @dev Return the current chainlink price of the borrowed asset
    @return The price of the borrowed asset
     */
    function borrowedAssetPrice() public view returns (uint256) {
        (, int price, , ,) = borrowedAssetPriceFeed.latestRoundData();
        return (uint256(price));
    }

    /**
    @dev Convert an amount in dollars to an amount in tokens
    @param asset The address of the asset
    @param amountBase The amount in dollars that need to be converted in tokens
    @return The amount of token that correspond to the given amount of dollars 
     */
    function _baseAmountToTokenAmount(address asset, uint256 amountBase) internal view returns (uint256) {
        uint256 assetPrice = borrowedAssetPrice();
        uint256 assetDecimals = 10 ** IERC20Metadata(asset).decimals();
        // amountBase and chainlinkPrice both have 8 decimals so no need to deal with decimals
        return amountBase * assetDecimals / assetPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../dex/interface/IDex.sol";

interface ILendingModule {
    
    /** admin **/

    function manager() external view returns (address);
    function setManager(address _manager) external;
    function dex() external view returns (IDex);
    function setDexModule(address _dex) external;

    /** manager **/

    function supply(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function borrow(uint256 amount) external;
    function repay(uint256 amount) external;
    function harvest() external returns (uint256);
    function getSupplyBalance() external view returns (uint256);
    function getBorrowBalance(address asset) external view returns (uint256);
    function getSupplyBalanceBase() external view returns (uint256);
    function getBorrowBalanceBase() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILendingModule.sol";

interface ILendingManager {

    /** admin **/

    function core() external view returns (address);
    function setCore(address _core) external;
    function module() external view returns (ILendingModule);
    function setModule(address _module) external;
    function setBorrowedAssetPriceFeed(address _borrowedAssetPriceFeed) external;

    /** core **/

    function TARGET_LTV() external view returns (uint256);
    function MIN_LTV() external view returns (uint256);
    function MAX_LTV() external view returns (uint256);
    function supply(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function borrowMax() external returns (uint256);
    function repay(uint256 amount) external;
    function repayBorrowInterest(uint256 amount) external;
    function harvest() external returns (uint256);
    function panic() external;
    function isModuleEmpty() external view returns (bool);
    function getBorrowInterestAmount() external view returns (uint256);
    function getDeleverageAmount() external view returns (uint256);
    function getSupplyBalance() external view returns (uint256);
    function getBorrowBalance() external view returns (uint256);
    function getSupplyBalanceBase() external view returns (uint256);
    function getBorrowBalanceBase() external view returns (uint256);
    function getCurrentLtv() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

contract Modifier {
    modifier onlyNotZeroAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }

    modifier onlyStrictlyPositiveAmount(uint256 amount) {
        require(amount > uint256(0), "amount < 0");
        _;
    }
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

pragma solidity ^0.8.0;

/**
 * Interface which is a face for Dex handlers implementations. On each chain we might use different
 * dex to swap tokens so we need to abstract generic interface.
 */

interface IDex {
    function swap(uint256 _amountIn, address _in, address _out, address _to) external returns (uint[] memory amounts);
    function swap(uint256 _amountIn, uint256 _amountOutMin, address _in, address _out, address _to) external returns (uint[] memory amounts);
    function setRoutes(address[][] memory _routes) external;
    function deleteRoutes(address[][] memory _routes) external;
    function getRoute(address _in, address _out) external view returns (address[] memory route);
    function swapPreview(uint256 _amountIn, address _in, address _out) external view returns (uint amountOut);
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