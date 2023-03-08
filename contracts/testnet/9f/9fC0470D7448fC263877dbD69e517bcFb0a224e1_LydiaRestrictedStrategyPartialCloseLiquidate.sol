pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./RebaseLibrary.sol";

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
  /// @notice Balance per ERC-20 token per account in shares.
  function balanceOf(address, address) external view returns (uint256);

  /// @dev Helper function to represent an `amount` of `token` in shares.
  /// @param token The ERC-20 token.
  /// @param amount The `token` amount.
  /// @param roundUp If the result `share` should be rounded up.
  /// @return share The token amount represented in shares.
  function toShare(
    address token,
    uint256 amount,
    bool roundUp
  ) external view returns (uint256 share);

  /// @dev Helper function to represent shares back into the `token` amount.
  /// @param token The ERC-20 token.
  /// @param share The amount of shares.
  /// @param roundUp If the result should be rounded up.
  /// @return amount The share amount back into native representation.
  function toAmount(
    address token,
    uint256 share,
    bool roundUp
  ) external view returns (uint256 amount);

  /// @notice Registers this contract so that users can approve it for BentoBox.
  function registerProtocol() external;

  /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
  /// @param token The ERC-20 token to deposit.
  /// @param from which account to pull the tokens.
  /// @param to which account to push the tokens.
  /// @param amount Token amount in native representation to deposit.
  /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
  /// @return amountOut The amount deposited.
  /// @return shareOut The deposited amount represented in shares.
  function deposit(
    address token,
    address from,
    address to,
    uint256 amount,
    uint256 share
  ) external payable returns (uint256 amountOut, uint256 shareOut);

  /// @notice Withdraws an amount of `token` from a user account.
  /// @param token_ The ERC-20 token to withdraw.
  /// @param from which user to pull the tokens.
  /// @param to which user to push the tokens.
  /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
  /// @param share Like above, but `share` takes precedence over `amount`.
  function withdraw(
    address token_,
    address from,
    address to,
    uint256 amount,
    uint256 share
  ) external returns (uint256 amountOut, uint256 shareOut);

  /// @notice Transfer shares from a user account to another one.
  /// @param token The ERC-20 token to transfer.
  /// @param from which user to pull the tokens.
  /// @param to which user to push the tokens.
  /// @param share The amount of `token` in shares.
  function transfer(
    address token,
    address from,
    address to,
    uint256 share
  ) external;

  /// @dev Reads the Rebase `totals`from storage for a given token
  function totals(address token) external view returns (Rebase memory total);

  /// @dev Approves users' BentoBox assets to a "master" contract.
  function setMasterContractApproval(
    address user,
    address masterContract,
    bool approved,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function harvest(
    address token,
    bool balance,
    uint256 maxChangeAmount
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @notice Trident pool interface.
interface IPool {
  /// @notice Executes a swap from one token to another.
  /// @dev The input tokens must've already been sent to the pool.
  /// @param data ABI-encoded params that the pool requires.
  /// @return finalAmountOut The amount of output tokens that were sent to the user.
  function swap(bytes calldata data) external returns (uint256 finalAmountOut);

  /// @notice Executes a swap from one token to another with a callback.
  /// @dev This function allows borrowing the output tokens and sending the input tokens in the callback.
  /// @param data ABI-encoded params that the pool requires.
  /// @return finalAmountOut The amount of output tokens that were sent to the user.
  function flashSwap(bytes calldata data) external returns (uint256 finalAmountOut);

  /// @notice Mints liquidity tokens.
  /// @param data ABI-encoded params that the pool requires.
  /// @return liquidity The amount of liquidity tokens that were minted for the user.
  function mint(bytes calldata data) external returns (uint256 liquidity);

  /// @notice Burns liquidity tokens.
  /// @dev The input LP tokens must've already been sent to the pool.
  /// @param data ABI-encoded params that the pool requires.
  /// @return withdrawnAmounts The amount of various output tokens that were sent to the user.
  function burn(bytes calldata data) external returns (TokenAmount[] memory withdrawnAmounts);

  /// @notice Burns liquidity tokens for a single output token.
  /// @dev The input LP tokens must've already been sent to the pool.
  /// @param data ABI-encoded params that the pool requires.
  /// @return amountOut The amount of output tokens that were sent to the user.
  function burnSingle(bytes calldata data) external returns (uint256 amountOut);

  /// @return A unique identifier for the pool type.
  function poolIdentifier() external pure returns (bytes32);

  /// @return An array of tokens supported by the pool.
  function getAssets() external view returns (address[] memory);

  /// @notice Simulates a trade and returns the expected output.
  /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
  /// @param data ABI-encoded params that the pool requires.
  /// @return finalAmountOut The amount of output tokens that will be sent to the user if the trade is executed.
  function getAmountOut(bytes calldata data) external view returns (uint256 finalAmountOut);

  /// @notice Simulates a trade and returns the expected output.
  /// @dev The pool does not need to include a trade simulator directly in itself - it can use a library.
  /// @param data ABI-encoded params that the pool requires.
  /// @return finalAmountIn The amount of input tokens that are required from the user if the trade is executed.
  function getAmountIn(bytes calldata data) external view returns (uint256 finalAmountIn);

  function pools(address token00, address token01) external view returns (address[] memory);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function getReserves()
    external
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint32 _blockTimestampLast
    );

  function transfer(address to, uint256 value) external returns (bool);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function swapFee() external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  /// @dev This event must be emitted on all swaps.
  event Swap(
    address indexed recipient,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  /// @dev This struct frames output tokens for burns.
  struct TokenAmount {
    address token;
    uint256 amount;
  }
}

// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.6;

interface IStrategy {
  /// @dev Execute worker strategy.
  /// @param user The original user that is interacting with the operator.
  /// @param debt The user's total debt, for better decision making context.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(address user, uint256 debt, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import { IPool } from "./IPool.sol";

/// @notice Trident pool router interface.
interface ITridentRouter {
  struct Path {
    address pool;
    bytes data;
  }

  struct ExactInputSingleParams {
    uint256 amountIn;
    uint256 amountOutMinimum;
    address pool;
    address tokenIn;
    bytes data;
  }

  struct ExactInputParams {
    address tokenIn;
    uint256 amountIn;
    uint256 amountOutMinimum;
    Path[] path;
  }

  struct TokenInput {
    address token;
    bool native;
    uint256 amount;
  }

  struct InitialPath {
    address tokenIn;
    address pool;
    bool native;
    uint256 amount;
    bytes data;
  }

  struct PercentagePath {
    address tokenIn;
    address pool;
    uint64 balancePercentage; // Multiplied by 10^6. 100% = 100_000_000
    bytes data;
  }

  struct Output {
    address token;
    address to;
    bool unwrapBento;
    uint256 minAmount;
  }

  struct ComplexPathParams {
    InitialPath[] initialPath;
    PercentagePath[] percentagePath;
    Output[] output;
  }

  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

  function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

  function exactInputSingleWithNativeToken(ExactInputSingleParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  function exactInputWithNativeToken(ExactInputParams calldata params) external payable returns (uint256 amountOut);

  function complexPath(ComplexPathParams calldata params) external payable;

  function addLiquidity(
    TokenInput[] calldata tokenInput,
    address pool,
    uint256 minLiquidity,
    bytes calldata data
  ) external payable returns (uint256 liquidity);

  function burnLiquidity(
    address pool,
    uint256 liquidity,
    bytes calldata data,
    IPool.TokenAmount[] calldata minWithdrawals
  ) external payable;

  function burnLiquiditySingle(
    address pool,
    uint256 liquidity,
    bytes calldata data,
    uint256 minWithdrawal
  ) external payable;
}

// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.6;

import "./IPool.sol";

interface IWorker {
  /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external;

  /// @dev Re-invest whatever the worker is working on.
  function reinvest() external;

  /// @dev Return the amount of wei to get back if we are to liquidate the position.
  function health(uint256 id) external view returns (uint256);

  /// @dev Liquidate the given position to token. Send all token back to its Vault.
  function liquidate(uint256 id) external;

  /// @dev SetStretegy that be able to executed by the worker.
  function setStrategyOk(address[] calldata strats, bool isOk) external;

  /// @dev Set address that can be reinvest
  function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

  /// @dev LP token holds by worker
  function lpToken() external view returns (IPool);

  /// @dev Base Token that worker is working on
  function baseToken() external view returns (address);

  /// @dev Farming Token that worker is working on
  function farmingToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.6;

struct Rebase {
  uint128 elastic;
  uint128 base;
}

/// @notice A rebasing library
library RebaseLibrary {
  /// @notice Calculates the base value in relationship to `elastic` and `total`.
  function toBase(Rebase memory total, uint256 elastic) internal pure returns (uint256 base) {
    if (total.elastic == 0) {
      base = elastic;
    } else {
      base = (elastic * total.base) / total.elastic;
    }
  }

  /// @notice Calculates the elastic value in relationship to `base` and `total`.
  function toElastic(Rebase memory total, uint256 base) internal pure returns (uint256 elastic) {
    if (total.base == 0) {
      elastic = base;
    } else {
      elastic = (base * total.elastic) / total.base;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";

import "../../interfaces/IPool.sol";
import "../../interfaces/ITridentRouter.sol";
import "../../interfaces/IBentoBox.sol";

import "../../interfaces/IStrategy.sol";
import "../../interfaces/IWorker.sol";
import "../../../utils/SafeToken.sol";

contract LydiaRestrictedStrategyPartialCloseLiquidate is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, IStrategy {
  using SafeToken for address;
  using SafeMath for uint256;

  ITridentRouter public router;
  IBentoBoxMinimal public bento;
  mapping(address => bool) public okWorkers;

  event LydiaRestrictedStrategyPartialCloseLiquidateEvent(
    address indexed baseToken,
    address indexed farmToken,
    uint256 amountToLiquidate,
    uint256 amountToRepayDebt
  );

  /// @notice require that only allowed workers are able to do the rest of the method call
  modifier onlyWhitelistedWorkers() {
    require(okWorkers[msg.sender], "LydiaRestrictedStrategyPartialCloseLiquidate::onlyWhitelistedWorkers:: bad worker");
    _;
  }

  /// @dev Create a new liquidate strategy instance.
  /// @param _router The PancakeSwap Router smart contract.
  function initialize(ITridentRouter _router, IBentoBoxMinimal _bento) public initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    router = _router;
    bento = _bento;
  }

  /// @dev Execute worker strategy. Take LP token. Return  BaseToken.
  /// @param data Extra calldata information passed along to this strategy.
  function execute(
    address, /* user */
    uint256 debt,
    bytes calldata data
  ) external override onlyWhitelistedWorkers nonReentrant {
    // 1. Decode variables from extra data & load required variables.
    // - maxLpTokenToLiquidate -> maximum lpToken amount that user want to liquidate.
    // - maxDebtRepayment -> maximum BTOKEN amount that user want to repaid debt.
    // - minBaseToken -> minimum baseToken amount that user want to receive.
    (uint256 maxLpTokenToLiquidate, uint256 maxDebtRepayment, uint256 minBaseToken) = abi.decode(
      data,
      (uint256, uint256, uint256)
    );
    IWorker worker = IWorker(msg.sender);
    address baseToken = worker.baseToken();
    address farmingToken = worker.farmingToken();
    IPool lpToken = IPool(address(worker.lpToken()));
    uint256 lpTokenToLiquidate = Math.min(address(lpToken).myBalance(), maxLpTokenToLiquidate);
    uint256 lessDebt = Math.min(maxDebtRepayment, debt);
    uint256 baseTokenBefore = baseToken.myBalance();
    // 2. Approve router to do their stuffs.
    address(lpToken).safeApprove(address(bento), uint256(-1));
    farmingToken.safeApprove(address(bento), uint256(-1));
    bento.setMasterContractApproval(
      address(this),
      address(router),
      true,
      0,
      0x0000000000000000000000000000000000000000000000000000000000000000,
      0x0000000000000000000000000000000000000000000000000000000000000000
    );

    // 3. Remove some LP back to BaseToken and farming tokens as we want to return some of the position.
    router.burnLiquiditySingle(address(lpToken), lpTokenToLiquidate, abi.encode(baseToken, msg.sender, true), 0);
    // 4. Return all baseToken back to the original caller.
    uint256 baseTokenAfter = baseToken.myBalance();
    require(
      baseTokenAfter.sub(baseTokenBefore).sub(lessDebt) >= minBaseToken,
      "LydiaRestrictedStrategyPartialCloseLiquidate::execute:: insufficient baseToken received"
    );
    SafeToken.safeTransfer(baseToken, msg.sender, baseTokenAfter);
    address(lpToken).safeTransfer(msg.sender, lpToken.balanceOf(address(this)));
    // 5. Reset approve for safety reason.
    address(lpToken).safeApprove(address(bento), 0);
    farmingToken.safeApprove(address(bento), 0);
    bento.setMasterContractApproval(
      address(this),
      address(router),
      false,
      0,
      0x0000000000000000000000000000000000000000000000000000000000000000,
      0x0000000000000000000000000000000000000000000000000000000000000000
    );

    emit LydiaRestrictedStrategyPartialCloseLiquidateEvent(baseToken, farmingToken, lpTokenToLiquidate, lessDebt);
  }

  function setWorkersOk(address[] calldata workers, bool isOk) external onlyOwner {
    for (uint256 idx = 0; idx < workers.length; idx++) {
      okWorkers[workers[idx]] = isOk;
    }
  }
}

// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.6;

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
  function balanceOf(address token, address user) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(user);
  }

  function myBalance(address token) internal view returns (uint256) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    // solhint-disable-next-line avoid-low-level-calls
    require(isContract(token), "!contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    // solhint-disable-next-line avoid-low-level-calls
    require(isContract(token), "!not contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
  }

  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    require(isContract(token), "!not contract");
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
  }

  function safeTransferETH(address to, uint256 value) internal {
    // solhint-disable-next-line no-call-value
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "!safeTransferETH");
  }

  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}