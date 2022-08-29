// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../../interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IUniswapRouterETH.sol";
import "../../interfaces/IMasterChef.sol";
import "../../common/ADivestStrategy2.sol";
import "../../interfaces/IVectorPoolHelper.sol";

/**
 * @dev Implementation of a strategy to get yields from farming LP Pools in SpookySwap.
 * SpookySwap is an automated market maker (“AMM”) that allows two tokens to be exchanged on Fantom's Opera Network.
 *
 * This strategy deposits whatever funds it receives from the vault into the selected masterChef pool.
 * Rewards from providing liquidity are farmed every few minutes, sold and divested.
 * The corresponding pair of assets are bought and more liquidity is added to the masterChef pool.
 *
 * Expect the amount of divestment token to grow over time.
 */
contract RaiderVectorDivest is ADivestStrategy2 {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address private MAIN_STAKING = 0x8B3d9F0017FA369cD8C164D0Cc078bf4cA588aE5;

  IVectorPoolHelper public poolContract;

  constructor(
    address _uniRouter,
    address _WNATIVE,
    address[] memory _rewardTokens,
    address _depositToken,
    uint8 _poolId,
    address _divestToken,
    address _vault,
    address _treasury,
    address _poolManager
  )
    ADivestStrategy2(
      _uniRouter,
      _WNATIVE,
      _rewardTokens,
      _depositToken,
      _poolId,
      _divestToken,
      _vault,
      _treasury,
      _poolManager
    )
  {
    poolContract = IVectorPoolHelper(_poolManager);
  }

  function giveAdditionalAllowances() internal override {
    IERC20(depositToken).safeApprove(MAIN_STAKING, type(uint256).max);
  }

  function removeAdditionalAllowances() internal override {
    IERC20(depositToken).safeApprove(MAIN_STAKING, 0);
  }

  function poolDeposit(uint256 amount) internal override {
    poolContract.deposit(amount);
  }

  function poolWithdraw(uint256 amount) internal override {
    poolContract.withdraw(amount, 0);
  }

  function getPoolReward() internal override {
    poolContract.getReward();
  }

  function poolBalance(address _address)
    internal
    view
    override
    returns (uint256)
  {
    return poolContract.balance(_address);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapRouterETH {
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMasterChef {
  function poolLength() external view returns (uint256);

  function setBooPerSecond(uint256 _rewardTokenPerSecond) external;

  function getMultiplier(uint256 _from, uint256 _to)
    external
    view
    returns (uint256);

  function pendingBOO(uint256 _pid, address _user)
    external
    view
    returns (uint256);

  function massUpdatePools() external;

  function updatePool(uint256 _pid) external;

  function deposit(uint256 _pid, uint256 _amount) external;

  function withdraw(uint256 _pid, uint256 _amount) external;

  function userInfo(uint256 _pid, address _user)
    external
    view
    returns (uint256, uint256);

  function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IUniswapRouterETH.sol";

/**
 * @dev Implementation of a strategy to get yields from farming LP Pools in SpookySwap.
 * SpookySwap is an automated market maker (“AMM”) that allows two tokens to be exchanged on Fantom's Opera Network.
 *
 * This strategy deposits whatever funds it receives from the vault into the selected masterChef pool.
 * Rewards from providing liquidity are farmed every few minutes, sold and divested.
 * The corresponding pair of assets are bought and more liquidity is added to the masterChef pool.
 *
 * Expect the amount of divestment token to grow over time.
 */
abstract contract ADivestStrategy2 is Ownable, Pausable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  /**
   * @dev Tokens Used:
   * {WNATIVE} - Required for liquidity routing when doing swaps.
   * {rewardToken} - Token generated by staking our funds.
   * {depositToken} - LP Token that the strategy maximizes.
   * {divestToken} - Token that the strategy maximizes.
   */
  address public WNATIVE;
  address[] public rewardTokens;
  address public depositToken;
  address public divestToken;

  /**
   * @dev Third Party Contracts:
   * {uniRouter} - the uniRouter for target DEX
   * {masterChef} - masterChef / staking contract for the rewards pool
   * {poolId} - masterChef pool id for the rewards pool
   */
  address public uniRouter;
  // address public masterChef;
  address public poolManager;
  uint8 public poolId;

  /**
   * @dev Raider Contracts:
   * {treasury} - Address of the Raider treasury
   * {vault} - Address of the vault that controls the strategy's funds.
   */
  address public treasury;
  address public vault;

  /**
   * @dev Distribution of fees earned. This allocations relative to the % implemented on
   * Current implementation separates 5% for fees. Can be changed through the constructor
   * Inputs in constructor should be ratios between the Fee and Max Fee, divisble into percents by 10000
   *
   * {callFee} - Percent of the totalFee reserved for the harvester (1000 = 10% of total fee: 0.7% by default)
   * {treasuryFee} - Percent of the totalFee taken by maintainers of the software (9000 = 90% of total fee: 4.5% by default)
   * {securityFee} - Fee taxed when a user withdraws funds. Taken to prevent flash deposit/harvest attacks.
   * These funds are redistributed to stakers in the pool.
   *
   * {totalFee} - divided by 10,000 to determine the % fee. Set to 5% by default and
   * lowered as necessary to provide users with the most competitive APY.
   *
   * {MAX_FEE} - Maximum fee allowed by the strategy. Hard-capped at 5%.
   * {PERCENT_DIVISOR} - Constant used to safely calculate the correct percentages.
   */

  uint256 public callFee = 1000;
  uint256 public treasuryFee = 9000;
  uint256 public securityFee = 10;
  uint256 public totalFee = 500;
  uint256 public constant MAX_FEE = 700;
  uint256 public constant PERCENT_DIVISOR = 10000;

  /**
   * @dev Routes we take to swap tokens using PanrewardTokenSwap.
   * {rewardTokenToWNATIVERoute} - Route we take to get from {rewardToken} into {WNATIVE}.
   * {rewardTokenToDivestRoute} - Route we take to divest
   */
  // address[] public rewardTokenToWNATIVERoute;
  // address[] public rewardTokenToDivestRoute;

  /**
   * {StratHarvest} Event that is fired each time someone harvests the strat.
   * {TotalFeeUpdated} Event that is fired each time the total fee is updated.
   * {CallFeeUpdated} Event that is fired each time the call fee is updated.
   */
  event StratHarvest(address indexed harvester);
  event TotalFeeUpdated(uint256 newFee);
  event CallFeeUpdated(uint256 newCallFee, uint256 newTreasuryFee);

  /////////////////////////// NEW

  mapping(address => uint256) public cumulativeDeposits;
  mapping(address => uint256) public cumulativeWithdrawals;

  struct Harvest {
    uint256 totalSupply;
    uint256 harvestAmount;
    uint256 totalHarvested;
    uint256 shareValue;
    uint256 summedShareValue;
    // uint256 averageHarvestAmount;
    // uint256 averageNumberOfShares;
  }

  Harvest[] harvests;

  struct User {
    uint256 entryPosition;
    bool isActive;
  }

  mapping(address => User) public userEntryPositions;

  /////////////////////////// NEW

  /**
   * @dev Keep track of the token holders so that we can distribute reward IOUs.
   *
   * Note: these mappings are only updated when the the AUM of the strategy
   * changes.
   */
  uint256 private _totalHolders;
  mapping(uint256 => address) private _holders;

  mapping(address => address[]) public rewardTokenToDivestRoutes;

  uint256 private _totalDivested; // the total amount the contract has divested, used to calc each distribution

  /**
   * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
   * @notice see documentation for each variable above its respective declaration.
   */
  constructor(
    address _uniRouter,
    address _WNATIVE,
    address[] memory _rewardTokens,
    address _depositToken,
    uint8 _poolId,
    address _divestToken,
    address _vault,
    address _treasury,
    address _poolManager
  ) {
    uniRouter = _uniRouter;
    WNATIVE = _WNATIVE;
    rewardTokens = _rewardTokens;
    depositToken = _depositToken;
    divestToken = _divestToken;
    poolId = _poolId;
    vault = _vault;
    treasury = _treasury;
    poolManager = _poolManager;

    // Extracts reward tokens into a mapping
    extractRewardTokens(_rewardTokens);

    giveAllowances();
  }

  /* ========== External Functions ========== */

  receive() external payable {}

  /**
   * @dev updates the total fee, capped at 5%
   */
  function updateTotalFee(uint256 _totalFee) external onlyOwner returns (bool) {
    require(_totalFee <= MAX_FEE, "Fee Too High");
    totalFee = _totalFee;
    emit TotalFeeUpdated(totalFee);
    return true;
  }

  /**
   * @dev updates the call fee and adjusts the treasury fee to cover the difference
   */
  function updateCallFee(uint256 _callFee) external onlyOwner returns (bool) {
    callFee = _callFee;
    treasuryFee = PERCENT_DIVISOR.sub(callFee);
    emit CallFeeUpdated(callFee, treasuryFee);
    return true;
  }

  function updateTreasury(address newTreasury)
    external
    onlyOwner
    returns (bool)
  {
    treasury = newTreasury;
    return true;
  }

  /**
   * @dev Withdraws funds and sents them back to the vault.
   * It withdraws {depositToken} from the masterChef.
   * The available {depositToken} minus fees is returned to the vault.
   */
  function withdraw(uint256 _amount) external {
    require(msg.sender == vault, "!vault");

    // Harvest and distribute IOUs before changing the split, this charges fees as well
    harvest();

    uint256 pairBal = IERC20(depositToken).balanceOf(address(this));

    if (pairBal < _amount) {
      poolWithdraw(_amount.sub(pairBal));
      pairBal = IERC20(depositToken).balanceOf(address(this));
    }

    if (pairBal > _amount) {
      pairBal = _amount;
    }
    uint256 withdrawFee = pairBal.mul(securityFee).div(PERCENT_DIVISOR);
    IERC20(depositToken).safeTransfer(vault, pairBal.sub(withdrawFee));

    // move the security fee into the treasury
    IERC20(depositToken).safeTransfer(treasury, withdrawFee);
  }

  /**
   * @dev Withdraws divestment and sends back to the vault.
   * The vault is responsible for sending these tokens to the user.
   *
   * Note: this function will always call distribute so that the
   * math is correct.
   *
   * Note: IOU tokens should have been burned / minted in the Vault withdraw/deposit
   */
  function withdrawDivestedTokens(address _account) external returns (uint256) {
    require(msg.sender == vault, "!vault");

    // Harvest and record
    harvest();

    // If this user doesn't exist, create them, this MUST be after the harvest as it depends on length
    if (!userEntryPositions[_account].isActive) {
      userEntryPositions[_account] = User(harvests.length - 1, true);
      return 0;
    }

    // Get balance of IOUs
    uint256 calculatedOwed = calculatePayout(_account);
    uint256 owed = calculatedOwed;
    uint256 divestTokenBalance = IERC20(divestToken).balanceOf(address(this));

    if (calculatedOwed > divestTokenBalance) {
      owed = divestTokenBalance;
    }

    // Reset the user position
    userEntryPositions[_account].entryPosition = harvests.length - 1;

    // Transfer to vault
    IERC20(divestToken).safeTransfer(vault, owed);

    return owed;
  }

  /**
   * @dev Unpauses the strat.
   */
  function unpause() external onlyOwner {
    _unpause();

    giveAllowances();

    deposit();
  }

  /* ========== Public Functions ========== */

  function getDivestToken() public view returns (address) {
    return divestToken;
  }

  /**
   * @dev Function that puts the funds to work.
   * It gets called whenever someone deposits in the strategy's vault contract.
   * It deposits {depositToken} in the masterChef to farm {rewardToken}
   */
  function deposit() public whenNotPaused {
    require(
      msg.sender == vault || msg.sender == address(this),
      "!vault | !strategy"
    );
    uint256 pairBal = IERC20(depositToken).balanceOf(address(this));

    // Depositing must happen before harvest in-case the pool token is the same as the divest token
    if (pairBal > 0) {
      poolDeposit(pairBal);
    }
  }

  /**
   * @dev Core function of the strat, in charge of collecting and divesting rewards.
   * 1. It claims rewards from the masterChef.
   * 2. It charges the system fees to simplify the split.
   * 3. It swaps the {rewardToken} token for the {divestToken}
   */
  function harvest() public whenNotPaused {
    getPoolReward();
    chargeAllFees();
    uint256 harvestAmount = divestAll();
    recordHarvest(harvestAmount);
    emit StratHarvest(msg.sender);
  }

  function recordHarvest(uint256 harvestAmount) internal {
    uint256 totalHarvested = 0;
    uint256 originalNumHarvests = harvests.length;
    uint256 shareValue = 0;
    uint256 summedShareValue = 0;
    uint256 totalSupply = IERC20(vault).totalSupply();

    if (originalNumHarvests > 0 && harvestAmount > 0) {
      Harvest memory previous = harvests[harvests.length - 1];

      totalHarvested = previous.totalHarvested + harvestAmount;

      shareValue = (harvestAmount * 1 ether) / totalSupply;
      summedShareValue = previous.summedShareValue + shareValue;
    }

    harvests.push(
      Harvest({
        totalSupply: totalSupply,
        harvestAmount: harvestAmount,
        totalHarvested: totalHarvested,
        shareValue: shareValue,
        summedShareValue: summedShareValue
      })
    );
  }

  function calculatePayout(address _user) public view returns (uint256) {
    // If there aren't any harvests or a user isn't active, return 0
    if (harvests.length == 0 || !userEntryPositions[_user].isActive) {
      return 0;
    }

    // Here's where you do the maths and shit with averages
    uint256 entryPosition = userEntryPositions[_user].entryPosition;
    Harvest memory startHarvest = harvests[entryPosition];
    Harvest memory endHarvest = harvests[harvests.length - 1];

    if (endHarvest.summedShareValue < startHarvest.summedShareValue) {
      return 0;
    }

    uint256 summedShareValue = endHarvest.summedShareValue -
      startHarvest.summedShareValue;
    uint256 numShares = IERC20(vault).balanceOf(_user);

    return (summedShareValue * numShares) / 1 ether;
  }

  /**
   * @dev Function to calculate the total underlaying {depositToken} held by the strat.
   * It takes into account both the funds in hand, as the funds allocated in the masterChef.
   */
  function totalLPBalance() public view returns (uint256) {
    return balanceOfLpPair().add(balanceOfPool());
  }

  /**
   * @dev It calculates how much {depositToken} the contract holds.
   */
  function balanceOfLpPair() public view returns (uint256) {
    return IERC20(depositToken).balanceOf(address(this));
  }

  /**
   * @dev It calculates how much {depositToken} the strategy has allocated in the masterChef
   */
  function balanceOfPool() public view returns (uint256) {
    return poolBalance(address(this));
  }

  /**
   * @dev Pauses deposits. Withdraws all funds from the masterChef, leaving rewards behind
   */
  function panic() public onlyOwner {
    pause();
    poolWithdraw(balanceOfPool());
  }

  /**
   * @dev Pauses the strat.
   */
  function pause() public onlyOwner {
    _pause();
    removeAllowances();
  }

  /* ========== Internal Functions ========== */

  /**
   * @dev Takes out fees from the rewards. Set by constructor
   * callFeeToUser is set as a percentage of the fee,
   * as is treasuryFeeToVault
   */
  function chargeFees(address rewardToken) internal {
    address[] memory rewardTokenToWNATIVERoute = new address[](2);
    rewardTokenToWNATIVERoute[0] = rewardToken;
    rewardTokenToWNATIVERoute[1] = WNATIVE;

    uint256 toWNATIVE = IERC20(rewardToken)
      .balanceOf(address(this))
      .mul(totalFee)
      .div(PERCENT_DIVISOR);

    if (toWNATIVE == 0) {
      return;
    }

    IUniswapRouterETH(uniRouter)
      .swapExactTokensForTokensSupportingFeeOnTransferTokens(
        toWNATIVE,
        0,
        rewardTokenToWNATIVERoute,
        address(this),
        block.timestamp.add(600)
      );

    uint256 WNATIVEBal = IERC20(WNATIVE).balanceOf(address(this));

    uint256 callFeeToUser = WNATIVEBal.mul(callFee).div(PERCENT_DIVISOR);
    IERC20(WNATIVE).safeTransfer(msg.sender, callFeeToUser);

    uint256 treasuryFeeToVault = WNATIVEBal.mul(treasuryFee).div(
      PERCENT_DIVISOR
    );
    IERC20(WNATIVE).safeTransfer(treasury, treasuryFeeToVault);
  }

  function chargeAllFees() internal {
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address rewardToken = rewardTokens[i];
      chargeFees(rewardToken);
    }
  }

  /**
   * @dev Swaps {rewardToken} for {divestToken}
   */
  function divest(address rewardToken) internal {
    uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
    uint256 prevDivestTokenBalance = IERC20(divestToken).balanceOf(
      address(this)
    );

    if (rewardTokenBalance == 0) {
      return;
    }

    IUniswapRouterETH(uniRouter)
      .swapExactTokensForTokensSupportingFeeOnTransferTokens(
        rewardTokenBalance,
        0,
        rewardTokenToDivestRoutes[rewardToken],
        address(this),
        block.timestamp.add(600)
      );

    uint256 currDivestTokenBalance = IERC20(divestToken).balanceOf(
      address(this)
    );

    // Update the total amount we've divested
    _totalDivested += currDivestTokenBalance.sub(prevDivestTokenBalance);
  }

  /**
   * @dev Swaps all reward tokens for divest tokens - necessary for strategies that have multiple rewards
   */
  function divestAll() internal returns (uint256) {
    uint256 originalDivestTokenBalance = IERC20(divestToken).balanceOf(
      address(this)
    );

    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address rewardToken = rewardTokens[i];
      divest(rewardToken);
    }

    uint256 newDivestTokenBalance = IERC20(divestToken).balanceOf(
      address(this)
    );

    return newDivestTokenBalance - originalDivestTokenBalance;
  }

  function giveAllowances() internal {
    // TODO @cstoneham - clean up
    IERC20(depositToken).safeApprove(poolManager, type(uint256).max);

    // Approve all reward tokens
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address rewardToken = rewardTokens[i];
      IERC20(rewardToken).safeApprove(uniRouter, type(uint256).max);
    }

    IERC20(divestToken).safeApprove(uniRouter, 0);
    IERC20(divestToken).safeApprove(uniRouter, type(uint256).max);

    // Call to override-able function for additional allowances
    giveAdditionalAllowances();
  }

  function removeAllowances() internal {
    // TODO @cstoneham - clean up
    IERC20(depositToken).safeApprove(poolManager, 0);

    // Approve all reward tokens
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      address rewardToken = rewardTokens[i];
      IERC20(rewardToken).safeApprove(uniRouter, type(uint256).max);
    }

    IERC20(divestToken).safeApprove(uniRouter, 0);

    // Call to override-able function for additional allowances
    removeAdditionalAllowances();
  }

  function extractRewardTokens(address[] memory _rewardTokens) internal {
    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      address rewardToken = _rewardTokens[i];

      if (divestToken == WNATIVE) {
        rewardTokenToDivestRoutes[rewardToken] = [rewardToken, WNATIVE];
      } else if (divestToken != rewardToken) {
        rewardTokenToDivestRoutes[rewardToken] = [
          rewardToken,
          WNATIVE,
          divestToken
        ];
      }
    }
  }

  function getRewardTokenRoute(address _token)
    internal
    view
    returns (address[] memory)
  {
    return rewardTokenToDivestRoutes[_token];
  }

  /* ========== Abstract Functions ========== */

  function giveAdditionalAllowances() internal virtual {}

  function removeAdditionalAllowances() internal virtual {}

  function poolDeposit(uint256 amount) internal virtual;

  function poolWithdraw(uint256 amount) internal virtual;

  function getPoolReward() internal virtual;

  function poolBalance(address _address)
    internal
    view
    virtual
    returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVectorPoolHelper {
  function deposit(uint256 amount) external;

  function stake(uint256 _amount) external;

  function withdraw(uint256 amount, uint256 minAmount) external;

  function getReward() external;

  function pendingPTP() external view returns (uint256 pendingTokens);

  function balance(address _address) external view returns (uint256);
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