/**
 *Submitted for verification at snowtrace.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

/**
 *Submitted for verification at snowtrace.io on 2022-02-06
*/

// File: @openzeppelin/contracts/utils/Address.sol
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol
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


// File: @openzeppelin/contracts/security/Pausable.sol
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.9;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
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

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

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

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}




// File: NodeManager.sol

pragma solidity ^0.8.0;

contract AstroNodeManager is Ownable, Pausable {
    using SafeMath for uint256;

    struct Astronaut {
        bool exists;
        uint256 nodes;
        uint256 donatedNodes; //this is the number of nodes I have received in donations
        uint256 nodesIDonated; //this is the number of nodes I have donated to others
        uint256 claimsNodes;
        uint256 claimsDonated;
        uint256 lastUpdate; //this is the timestamp of when the rewards were last updated
    }

    mapping(address => Astronaut) public astronauts;

    IERC20 public buzzToken;
    IERC20 public avax;
    IJoeRouter02 private router;


    uint256 public dailyInterest;
    uint256 public rewardBoost;
    uint256 public nodeCost;
    uint256 public nodeBase;
    uint256 totalNodes = 0;
    uint256 totalNodesDonated = 0;
    uint256 totalNodesCompounded = 0;
    uint256 public claimTax = 15;
    uint256 public treasuryShare = 3;
    uint256 public marketingShare = 4;
    uint256 public lpShare = 2;

    address public lpPairAddress;
    address public treasuryAddress;
    address public marketingAddress;
    

    uint256 private constant MAX_UINT256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    address public joeRouterAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; // TraderJoe Router

    bool public isLive = false;
    bool public isSwapEnabled = true;

    address [] public astronautsAddresses;

    constructor(
        uint256 _nodeBase,
        uint256 _nodeCost,
        uint256 _dailyInterest,
        address _treasuryAddress,
        address _marketingAddress,
        IERC20 _buzzToken,
        IERC20 _avax,
        uint256 _treasuryShare,
        uint256 _marketingShare,
        uint256 _lpShare,
        address _lpPairAddress,
        uint256 _rewardBoost

    ) {
        nodeBase = _nodeBase;
        nodeCost = _nodeCost;
        dailyInterest = _dailyInterest;
        treasuryAddress = _treasuryAddress;
        marketingAddress = _marketingAddress;
        buzzToken = IERC20(_buzzToken);
        avax = IERC20(_avax);
        treasuryShare = _treasuryShare;
        marketingShare = _marketingShare;
        lpShare = _lpShare;
        lpPairAddress = _lpPairAddress;
        rewardBoost = _rewardBoost;

        router = IJoeRouter02(joeRouterAddress);

        setAllowance(true);

    }

    fallback() external payable { }

    receive() external payable { }

    event TransferEvent(IERC20 indexed token, address to, uint256 amount);
    event TransferFromEvent(IERC20 indexed token, address from, address to, uint256 amount);

    function currentDailyRewards() external view returns (uint256) {
        uint256 dailyRewards = nodeBase * dailyInterest;
        return dailyRewards;
    }

    function getMyInterestWithBoost() external view returns (uint256) {
        uint256 boostedInterest = calculateRewardBoost(msg.sender);
        return nodeBase *boostedInterest;
    }

    function getRewardBoost() external view returns (uint256) {
        uint256 currentRewardBoost = nodeBase * rewardBoost;
        return currentRewardBoost;
    }

    function getOwnedNodes() external view returns (uint256) {
        uint256 ownedNodes = astronauts[msg.sender].nodes + astronauts[msg.sender].donatedNodes;
        return ownedNodes;
    }

    function getMyDonatedNodes() external view returns (uint256) {
        uint256 myDonatedNodes = astronauts[msg.sender].nodesIDonated;
        return myDonatedNodes;
    }

    function getOwnedNodesByAddress(address astronaut) external view returns (uint256) {
        uint256 ownedNodes = astronauts[astronaut].nodes + astronauts[astronaut].donatedNodes;
        return ownedNodes;
    }

    function getMyDonatedNodesByAddress(address astronaut) external view returns (uint256) {
        uint256 myDonatedNodes = astronauts[astronaut].nodesIDonated;
        return myDonatedNodes;
    }

    function getTotalNodes() external view returns (uint256) {
        return totalNodes;
    }

    function getTotalNodesDonated() external view returns (uint256) {
        return totalNodesDonated;
    }

    function getClaimTax() external view returns (uint256) {
        return claimTax;
    }

    function _transfer(IERC20 token, address account, uint256 amount) private {
        buzzToken.transfer(account, amount);
        emit TransferEvent(token, account, amount);
    }

    function _transferFrom(IERC20 token, address from, address to, uint256 amount) private {
        buzzToken.transferFrom(from, to, amount);
        emit TransferFromEvent(token, from, to, amount);
    }

    function setPlatformState(bool _isLive) external onlyOwner{
        isLive = _isLive;
    }

    function setSwapState(bool _isEnabled) external onlyOwner{
        isSwapEnabled = _isEnabled;
    }

    function setTreasuryShare(uint256 _treasuryShare) external onlyOwner{
        treasuryShare = _treasuryShare;
    }

    function setMarketingShare(uint256 _marketingShare) external onlyOwner{
        marketingShare = _marketingShare;
    }

    function setLpShare(uint256 _lpShare) external onlyOwner{
        lpShare = _lpShare;
    }

    function getLpShare() external view returns(uint256){
        return lpShare;
    }

    function setClaimTax(uint256 _claimTaxNode) external onlyOwner {
        claimTax = _claimTaxNode;
    }

    function setRewardBoost(uint256 newRewardBoost) external onlyOwner {
        updateAllClaims();
        rewardBoost = newRewardBoost;
    }

    function updateAllClaims() internal {
        uint256 i;
        for(i=0; i<astronautsAddresses.length; i++){
            address _address = astronautsAddresses[i];
            updateClaims(_address);
        }
    }

    function setAllowance(bool active) public onlyOwner {
        buzzToken.approve(address(buzzToken), (active ? MAX_UINT256 : 0));
        buzzToken.approve(address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4), (active ? MAX_UINT256 : 0));
        buzzToken.approve(address(this), (active ? MAX_UINT256 : 0));
    }

    function setNodeCost(uint256 newNodeCost) external onlyOwner {
        nodeCost = newNodeCost;
    }

    function setDailyInterest(uint256 newInterest) external onlyOwner {
        updateAllClaims();
        dailyInterest = newInterest;
    }

    //This is used as the base for node calculations in ETH
    function setNodeBase(uint256 newBase) external onlyOwner {
        nodeBase = newBase;
    }

    function getBuzzBalance() external view returns (uint256) {
	    return buzzToken.balanceOf(lpPairAddress);
    }

    function getPrice() public view returns (uint256) {
        uint256 buzzTokenBalance = buzzToken.balanceOf(lpPairAddress);
        uint256 avaxBalance = avax.balanceOf(lpPairAddress);
        require(buzzTokenBalance > 0, "divison by zero error");
        uint256 price = avaxBalance * 1e30 / buzzTokenBalance;
        return price;
    }

    function setTokenAddr(address tokenAddress) external onlyOwner{
        buzzToken = IERC20(tokenAddress);
    }

    function setLpPairAddr(address pairAddress) external onlyOwner{
        lpPairAddress = pairAddress;
    }

    function setTreasuryAddr(address _treasuryAddress) external onlyOwner{
        treasuryAddress = _treasuryAddress;
    }

    function setMarketingAddr(address _marketingAddress) external onlyOwner{
        marketingAddress = _marketingAddress;
    }

    function buyNode(uint256 _amount) external {  
        require(isLive, "Platform is offline");
        uint256 nodesOwned = astronauts[msg.sender].nodes + astronauts[msg.sender].donatedNodes + _amount;
        require(astronauts[msg.sender].donatedNodes > 0, "You must be gifted an AstroNode first");
        require(nodesOwned < 100, "Max AstroNodes Owned");
        Astronaut memory astronaut;
        if(astronauts[msg.sender].exists){
            astronaut = astronauts[msg.sender];
        } else {
            astronaut = Astronaut(true, 0, 0, 0, 0, 0, 0);
            astronautsAddresses.push(msg.sender);
        }
        if(isSwapEnabled){
            uint256 transactionTotal = nodeCost * _amount;
            uint256 toMarketing = transactionTotal.mul(marketingShare).div(100); 
            uint256 toTreasury = transactionTotal.mul(treasuryShare).div(100);
            uint256 toRewards = transactionTotal - toMarketing - toTreasury;
            uint256 toAddToLp = toRewards.mul(lpShare).div(100);

            _transferFrom(buzzToken, msg.sender, address(this), transactionTotal);

            swapAndSendToAddress(address(treasuryAddress), toTreasury);
            swapAndSendToAddress(address(marketingAddress), toMarketing);

            
            //Trigger the add to LP
            _transfer(buzzToken, address(buzzToken), toAddToLp);
        }


        astronauts[msg.sender] = astronaut;
        updateClaims(msg.sender);
        astronauts[msg.sender].nodes += _amount;
        totalNodes += _amount;
    }

    function awardNode(address _address, uint256 _amount) external {
        require(isLive, "Platform is offline");
        require(_amount < 2, "Can only donate 1 AstroNode at a time");
        uint256 nodesOwned = astronauts[_address].nodes + astronauts[_address].donatedNodes + _amount;
        require(nodesOwned < 100, "Max AstroNodes Owned");
        require(_address != _msgSender(), "You cannot donate a node to yourself");
        Astronaut memory astronaut;
        Astronaut memory astronautSender;

        //Get the receiver Astronaut object
        if(astronauts[_address].exists){
            astronaut = astronauts[_address];
            require(astronaut.donatedNodes == 0, "This Astronaut has already received a donation. Please find another to donate to.");
        } else {
            astronaut = Astronaut(true, 0, 0, 0, 0, 0, block.timestamp);
            astronautsAddresses.push(_address);
        }

        //Get the sender Astronaut object so we can update how many they have donated outwards
        if(astronauts[msg.sender].exists){
            astronautSender = astronauts[msg.sender];
        } else {
            astronautSender = Astronaut(true, 0, 0, 0, 0, 0, block.timestamp);
            astronautsAddresses.push(msg.sender);
        }

        if(isSwapEnabled){
            uint256 transactionTotal = nodeCost * _amount;
            uint256 toMarketing = transactionTotal.mul(marketingShare).div(100); 
            uint256 toTreasury = transactionTotal.mul(treasuryShare).div(100);
            uint256 toRewards = transactionTotal - toMarketing - toTreasury;
            uint256 toAddToLp = toRewards.mul(lpShare).div(100);

            _transferFrom(buzzToken, msg.sender, address(this), transactionTotal);

            swapAndSendToAddress(address(treasuryAddress), toTreasury);
            swapAndSendToAddress(address(marketingAddress), toMarketing);
            
            //Trigger the add to LP
            _transfer(buzzToken, address(buzzToken), toAddToLp);
        }


        astronauts[_address] = astronaut;
        astronauts[msg.sender] = astronautSender;
        updateClaims(_address);
        updateClaims(msg.sender);
        astronauts[_address].donatedNodes += _amount;
        astronauts[msg.sender].nodesIDonated += _amount;
        astronauts[msg.sender].nodes += _amount;

        totalNodes += _amount;
        totalNodesDonated += _amount;
    }

    function swapAndSendToAddress(address destination, uint256 tokens) private {
        uint256 initialAVAXBalance = address(this).balance;

        swapLeftSideForRightSide(tokens);
        uint256 newBalance = (address(this).balance).sub(initialAVAXBalance);
        payable(destination).transfer(newBalance);
    }

    function swapLeftSideForRightSide(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(buzzToken);
        path[1] = router.WAVAX();

        buzzToken.approve(address(router), tokenAmount);

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function compoundNode() external {
        uint256 pendingClaims = getTotalClaimable();
        uint256 nodesOwned = astronauts[msg.sender].nodes + astronauts[msg.sender].donatedNodes;
        require(pendingClaims > nodeCost, "Not enough pending BUZZ to compound");
        require(nodesOwned < 100, "Max AstroNodes Owned");
        updateClaims(msg.sender);
        if (astronauts[msg.sender].claimsNodes < nodeCost) {
            astronauts[msg.sender].claimsNodes += astronauts[msg.sender].claimsDonated;
            astronauts[msg.sender].claimsDonated = 0;        
        } 
        astronauts[msg.sender].claimsNodes -= nodeCost;
        astronauts[msg.sender].nodes++;
        totalNodes++;
        totalNodesCompounded++;
    }

    function calculateRewardBoost(address _address) internal view returns (uint256) {
        uint256 newReward = dailyInterest + (astronauts[_address].nodesIDonated * rewardBoost);
        return newReward;
    }

    function updateClaims(address _address) internal {
        uint256 time = block.timestamp;
        uint256 timerFrom = astronauts[_address].lastUpdate;
        uint256 dailyInterestAfterBoost = calculateRewardBoost(msg.sender);

        //Dividing by 10**5 so that we can handle fractional percentages. NodeCost is a 10**18 value already
        if (timerFrom > 0)
            astronauts[_address].claimsNodes += astronauts[_address].nodes * (nodeCost / (10 ** 5)) * dailyInterestAfterBoost * (time - timerFrom) / 8640000;
            astronauts[_address].claimsDonated += astronauts[_address].donatedNodes * (nodeCost / (10 ** 5)) * dailyInterestAfterBoost * (time - timerFrom) / 8640000;
            astronauts[_address].lastUpdate = time;
    }

    function getTotalClaimable() public view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 timerFrom = astronauts[msg.sender].lastUpdate;
        if (timerFrom <= 0) {
            timerFrom = time;
        }

        uint256 dailyInterestAfterBoost = calculateRewardBoost(msg.sender);

        uint256 pendingRewards = astronauts[msg.sender].nodes * (nodeCost / (10 ** 5)) * dailyInterestAfterBoost * (time - timerFrom) / 8640000;
        uint256 pendingDonatedRewards = astronauts[msg.sender].donatedNodes * (nodeCost / (10 ** 5)) * dailyInterestAfterBoost * (time - timerFrom) / 8640000;
        uint256 pending = pendingRewards + pendingDonatedRewards;
        uint256 existing = astronauts[msg.sender].claimsNodes + astronauts[msg.sender].claimsDonated;
        return existing + pending;
        
	}

    function getClaimTaxEstimate() external view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 dailyInterestAfterBoost = calculateRewardBoost(msg.sender);

        uint256 pendingRewards = astronauts[msg.sender].nodes * (nodeCost / (10 ** 5)) * dailyInterestAfterBoost * (time - astronauts[msg.sender].lastUpdate) / 8640000;
        uint256 pendingDonatedRewards = astronauts[msg.sender].donatedNodes * (nodeCost / (10 ** 5)) * dailyInterestAfterBoost * (time - astronauts[msg.sender].lastUpdate) / 8640000;
        uint256 claimableRewards = pendingRewards + astronauts[msg.sender].claimsNodes;
        uint256 claimableDonatedRewards = pendingDonatedRewards + astronauts[msg.sender].claimsDonated;
        uint256 nodeClaimTax = claimableRewards / 100 * claimTax;
        return nodeClaimTax;
	}

    function calculateClaimTax() public returns (uint256) {
        updateClaims(msg.sender);
        uint256 calculatedClaimTax = astronauts[msg.sender].claimsNodes / 100 * claimTax;
        return calculatedClaimTax;
    }

    function claim() external {
        require(astronauts[msg.sender].exists, "Sender must be an Astronaut to claim yields");

        updateClaims(msg.sender);
        uint256 tax = calculateClaimTax();
		uint256 reward = astronauts[msg.sender].claimsNodes + astronauts[msg.sender].claimsDonated;
        uint256 toTreasury = tax;
        uint256 toAstronaut = reward - tax;
		if (reward > 0) {
            astronauts[msg.sender].claimsNodes = 0;
            astronauts[msg.sender].claimsDonated = 0;
            _transfer(buzzToken, msg.sender, toAstronaut);
            _transfer(buzzToken, address(treasuryAddress), toTreasury);
		}
	}

}