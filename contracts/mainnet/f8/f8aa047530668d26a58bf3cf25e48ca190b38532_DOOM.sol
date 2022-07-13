/**
 *Submitted for verification at snowtrace.io on 2022-07-12
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: contracts/JoeV2Router.sol



pragma solidity ^0.8.0;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}


// pragma solidity >=0.6.2;

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

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/finance/PaymentSplitter.sol


// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;




/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// File: contracts/ProtoRouter.sol



/*
MIT License

Copyright (c) 2018 requestnetworks
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFTOKENEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.0;






/** CONTRACT PROTOROUTER */
interface ProtoRouter {
    function runStable() external;
}
// File: contracts/DOOM.sol



/*
MIT License

Copyright (c) 2018 requestnetworks
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFTOKENEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.0;







/** CONTRACT DOOM */
contract DOOM is ERC20, Ownable, ReentrancyGuard {
    mapping(address => bool) public ammPairs;

    mapping(address => bool) public maluser;

    mapping(address => bool) public exproto;

    ERC20 public stableToken =
        ERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);

    IJoeRouter02 public router;
    address public pair;

    ProtoRouter public protoRouter;

    uint8 public distriRatio;
    uint8 public allocateProtocol;
    uint8 public allocateLP;
    uint8 public allocateOutput;
    uint16 public allocateBurn;

    uint256 public mulRatio = 1;
    uint256 public divRatio = 1;

    bool public processing = false;
    bool public auth = false;
    bool public authLP = false;
    uint256 public minSwapAm = 0;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 typee;
    }

    struct RewardNodeEntity {
        uint256 price;
        uint256 rewardPerSecond;
    }

    mapping(address => NodeEntity[]) public nodesOfUser;
    mapping(uint256 => RewardNodeEntity) public nodeTypes;

    uint256 public totalNodesCreated = 0;
    uint256 public totalNodeTypes = 0;
    uint256 public totalRewardStacked = 0;

    uint256 public minimumClaimInterval = 0;
    uint256 public maintenanceInterval = 0;

    string[] public nodeNames = [
        "AAAA",
        "BBBB",
        "CCCC",
        "DDDD",
        "EEEE",
        "FFFF"
    ];

    uint16 nameIndex = 0;

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);

    event Exclude(address indexed _account, bool isExcluded);

    event CreationNode(
        address indexed creator,
        uint8 indexed level,
        uint256 creationTime
    );

    event CashoutNode(address indexed user, uint256 time, uint256 amount);
    event CashoutAll(address indexed user, uint256 time, uint256 amount);

    constructor(
        address[] memory _addresses,
        uint256[] memory _balances,
        uint8[] memory _allocation,
        uint16 _allocateBurn,
        uint256[] memory _nodePrices,
        uint256[] memory _rewardPerNodes
    ) ERC20("DOOM", "DOOM") {
        require(
            _addresses.length > 0 && _balances.length > 0,
            "CONSTRUCTOR: array length must be greater than zero"
        );
        require(
            _addresses.length == _balances.length,
            "CONSTRUCTOR: arrays length mismatch"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _balances[i] * (10**6));
        }
        IJoeRouter02 v2Router = IJoeRouter02(
            0x60aE616a2155Ee3d9A68541Ba4544862310933d4
        );
        pair = IJoeFactory(v2Router.factory()).createPair(
            address(this),
            address(stableToken)
        );
        ammPairs[pair] = true;
        router = v2Router;
        approveRouterSpend((10**10) * (10**6));
        exclude(address(this), true);
        exclude(owner(),true);
        exclude(address(router),true);
        exclude(pair,true);
        exclude(address(protoRouter),true);
        require(_allocation[0] != 0 && _allocation[1] != 0, "CONSTR: Fees equal 0");
        allocateBurn = _allocateBurn;
        allocateProtocol = _allocation[0];
        allocateLP = _allocation[1];
        allocateOutput = _allocation[2];
        require(
            _rewardPerNodes.length == _nodePrices.length,
            "ARRAY TYPES AND PARAMETERS NOT SAME LENGTH"
        );
        require(_nodePrices.length > 0, "NODE ARRAY EMPTY");
        for (uint256 i = 0; i < _nodePrices.length; i++) {
            totalNodeTypes++;
            nodeTypes[totalNodeTypes] = RewardNodeEntity(
                _nodePrices[i] * (10**6),
                _rewardPerNodes[i]
            );
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            sender != address(0),
            "TRANSFER: transfer from the zero address"
        );
        require(!maluser[sender], "MALUSER DETECTED");
        if (ammPairs[recipient] && !exproto[sender]) {
            if (allocateOutput > 0 && allocateOutput <= 100) {
                uint256 allocateAmount = (amount * allocateOutput) / 100;
                _transfer(sender,address(protoRouter), allocateAmount);
                amount -= allocateAmount;
            }
        }
        super._transfer(sender, recipient, amount);
    }


    function createNode(
        address _account,
        string memory _nodeName,
        uint256 _type
    ) private returns (uint256) {
        require(
            isNameAvailable(_account, _nodeName),
            "CREATE NODE: Name not available"
        );
        require(
            testStr(_nodeName),
            "NAME NOT VALID (Only alphanumeric character allowed)"
        );
        require(nodeTypes[_type].rewardPerSecond > 0, "TYPE NOT VALID");
        uint256 creaTime = block.timestamp;
        nodesOfUser[_account].push(
            NodeEntity({
                name: _nodeName,
                creationTime: creaTime,
                lastClaimTime: creaTime,
                typee: _type
            })
        );
        totalNodesCreated++;
        return creaTime;
    }

    function isNameAvailable(address _account, string memory nodeName)
        public
        view
        returns (bool)
    {
        NodeEntity[] memory nodes = nodesOfUser[_account];
        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    }

    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "COLLECT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) public view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low) / 2;
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function testStr(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length > 13) return false;

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (
                !(char >= 0x30 && char <= 0x39) &&
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A) &&
                !(char == 0x2E)
            ) return false;
        }

        return true;
    }

    function collectNodeReward(address _account, uint256 _nodeIndex)
        private
        returns (uint256)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        if (checkActivity(_account)) {
            return 0;
        }
        NodeEntity[] storage nodes = nodesOfUser[_account];
        require(
            _nodeIndex < nodes.length,
            "NODE: CREATIME must be higher than zero"
        );
        NodeEntity storage node = nodes[_nodeIndex];
        uint256 nowTime = block.timestamp;
        uint256 rewardUnit = (nowTime - node.lastClaimTime);
        require(
            rewardUnit > minimumClaimInterval,
            "CLAIM NOT ELIGIBLE, WAIT BEFORE ELIGIBILITY"
        );
        uint256 rewardNode = computeRewardAvailable(
            node.lastClaimTime,
            nodeTypes[node.typee].rewardPerSecond
        );
        node.lastClaimTime = nowTime;
        return rewardNode;
    }

    function collectAllNodesReward(address _account) private returns (uint256) {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        if (checkActivity(_account)) {
            return 0;
        }
        NodeEntity[] storage nodes = nodesOfUser[_account];
        uint256 numberOfNodes = nodes.length;
        NodeEntity storage node;
        uint256 rewardsTotal = 0;
        uint256 nowTime = block.timestamp;
        uint256 rewardUnit;
        for (uint256 i = 0; i < numberOfNodes; i++) {
            node = nodes[i];
            rewardUnit = nowTime - node.lastClaimTime;
            if (rewardUnit > minimumClaimInterval) {
                rewardsTotal += computeRewardAvailable(
                    node.lastClaimTime,
                    nodeTypes[node.typee].rewardPerSecond
                );
                node.lastClaimTime = nowTime;
            }
        }
        totalRewardStacked += rewardsTotal;
        return rewardsTotal;
    }

    function computeRewardAvailable(
        uint256 _lastClaimTime,
        uint256 _rewardPerSecond
    ) public view returns (uint256) {
        return (block.timestamp - _lastClaimTime) * _rewardPerSecond;
    }

    function computeTotalRewardSecond(address _account)
        external
        view
        returns (uint256)
    {
        uint256 total = 0;
        if (_isNodeOwner(_account)) {
            NodeEntity[] storage nodes = nodesOfUser[_account];
            for (uint256 i = 0; i < nodes.length; i++) {
                total += nodeTypes[nodes[i].typee].rewardPerSecond;
            }
        }
        return total;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function createBatch(address[] memory _nodes, uint256 _type)
        public
        onlyOwner
    {
        require(nodeTypes[_type].rewardPerSecond > 0, "LEVEL NOT VALID");
        uint256 creaTime = block.timestamp;
        for (uint256 i = 0; i < _nodes.length; i++) {
            nodesOfUser[_nodes[i]].push(
                NodeEntity({
                    name: nodeNames[nameIndex++ % nodeNames.length],
                    creationTime: creaTime,
                    lastClaimTime: creaTime,
                    typee: _type
                })
            );
            totalNodesCreated++;
        }
    }

    function removeNodes(address[] memory noders) public onlyOwner {
        for (uint256 i = 0; i < noders.length; i++) {
            totalNodesCreated -= nodesOfUser[noders[i]].length;
            delete nodesOfUser[noders[i]];
        }
    }

    function checkActivity(address _account) internal returns (bool) {
        if (isMaintenanceOn()) {
            NodeEntity[] memory nodes = nodesOfUser[_account];
            if (
                nodes[nodes.length - 1].creationTime + maintenanceInterval <
                block.timestamp
            ) {
                totalNodesCreated -= nodes.length;
                delete nodes;
                return true;
            }
        }
        return false;
    }

    function createNewEntity(
        uint256 _nodeprice,
        uint256 _nodeRewardPerSecond
    ) public onlyOwner {
        totalNodeTypes++;
        nodeTypes[totalNodeTypes] = RewardNodeEntity(
            _nodeprice,
            _nodeRewardPerSecond
        );
    }

    function updateEntity(
        uint256 _nodeType,
        uint256 _nodeprice,
        uint256 _nodeRewardPerSecond
    ) public onlyOwner {
        nodeTypes[_nodeType] = RewardNodeEntity(
            _nodeprice,
            _nodeRewardPerSecond
        );
    }

    function getRewardAmountOf(address _account) public view returns (uint256) {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        NodeEntity[] memory nodes = nodesOfUser[_account];
        NodeEntity memory node;
        nodesCount = nodes.length;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodes.length; i++) {
            node = nodes[i];
            rewardsTotal += computeRewardAvailable(
                node.lastClaimTime,
                nodeTypes[node.typee].rewardPerSecond
            );
        }
        return rewardsTotal;
    }

    function getNodeRewardByCreatime(address _account, uint256 _creationTime)
        external
        view
        returns (uint256)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        NodeEntity[] storage nodes = nodesOfUser[_account];
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewards = computeRewardAvailable(
            node.lastClaimTime,
            nodeTypes[node.typee].rewardPerSecond
        );
        return rewards;
    }

    function getNodeRewardAmountOf(address _account, uint256 _nodeIndex)
        public
        view
        returns (uint256)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        NodeEntity[] storage nodes = nodesOfUser[_account];
        require(
            _nodeIndex < nodes.length,
            "Index greater than node array size"
        );
        NodeEntity storage node = nodes[_nodeIndex];
        uint256 rewards = computeRewardAvailable(
            node.lastClaimTime,
            nodeTypes[node.typee].rewardPerSecond
        );
        return rewards;
    }

    function getNodeNumberOf(address _account) public view returns (uint256) {
        return nodesOfUser[_account].length;
    }

    function getNodeNumberOfType(address _account, uint256 _type)
        public
        view
        returns (uint256)
    {
        require(
            _isNodeOwner(_account),
            "GET NODE NUMBER TYPE OF : NO NODE OWNER"
        );
        NodeEntity[] memory nodes = nodesOfUser[_account];
        uint256 cpt = 0;
        for (uint256 i = 0; i < nodes.length; i++) {
            if (nodes[i].typee == _type) {
                cpt++;
            }
        }
        return cpt;
    }

    function getNodeNameOf(address _account, uint256 _nodeIndex)
        public
        view
        returns (string memory)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        require(
            _nodeIndex < nodesOfUser[_account].length,
            "Index greater than node array size"
        );
        return nodesOfUser[_account][_nodeIndex].name;
    }

    function getNodeCreatimeOf(address _account, uint256 _nodeIndex)
        public
        view
        returns (uint256)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        require(
            _nodeIndex < nodesOfUser[_account].length,
            "Index greater than node array size"
        );
        return nodesOfUser[_account][_nodeIndex].creationTime;
    }

    function getNodeLastClaimOf(address _account, uint256 _nodeIndex)
        public
        view
        returns (uint256)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        require(
            _nodeIndex < nodesOfUser[_account].length,
            "Index greater than node array size"
        );
        return nodesOfUser[_account][_nodeIndex].lastClaimTime;
    }

    function getNodeTypeOf(address _account, uint256 _nodeIndex)
        public
        view
        returns (uint256)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        require(
            _nodeIndex < nodesOfUser[_account].length,
            "Index greater than node array size"
        );
        return nodesOfUser[_account][_nodeIndex].typee;
    }

    function _isNodeOwner(address _account) public view returns (bool) {
        return nodesOfUser[_account].length > 0;
    }

    function getPriceOfNode(uint8 _type) public view returns (uint256) {
        return nodeTypes[_type].price;
    }

    function getrewardOfNode(uint8 _type) public view returns (uint256) {
        return nodeTypes[_type].rewardPerSecond;
    }

    function getNodeClaimEligibility(address _account, uint256 _nodeIndex)
        external
        view
        returns (bool)
    {
        require(_isNodeOwner(_account), "GET REWARD OF: NO NODE OWNER");
        require(
            _nodeIndex < nodesOfUser[_account].length,
            "Index greater than node array size"
        );
        return
            block.timestamp - nodesOfUser[_account][_nodeIndex].lastClaimTime >
            minimumClaimInterval;
    }

    function updateDico(string[] memory _newDico) public onlyOwner {
        nodeNames = _newDico;
    }

    function updateMaintenanceInterval(uint256 _newVal) public onlyOwner {
        maintenanceInterval = _newVal;
    }

    function isMaintenanceOn() public view returns (bool) {
        return maintenanceInterval > 0;
    }

    function updateMinimumClaimInterval(uint256 _newVal) public onlyOwner {
        minimumClaimInterval = _newVal;
    }

    function updatePair(address _pair, bool _value) public onlyOwner {
        ammPairs[_pair] = _value;
        exclude(pair,true);
    }

    function updateMaluser(address _account, bool _value) public onlyOwner {
        maluser[_account] = _value;
    }

    function isPair(address _pair) public view returns (bool) {
        return ammPairs[_pair];
    }

    function isMaluser(address _account) public view returns (bool) {
        return maluser[_account];
    }

    function updateV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(router),
            "TKN: The router already has that address"
        );
        emit UpdateRouter(newAddress, address(router));
        router = IJoeRouter02(newAddress);
        exclude(address(router),true);
    }

    function updateProtocol(ProtoRouter _newVal) public onlyOwner {
        protoRouter = _newVal;
        exclude(address(protoRouter),true);
    }

    function updateStableToken(ERC20 _newVal) public onlyOwner {
        stableToken = _newVal;
    }

    function exclude(address _account, bool excluded) public onlyOwner {
        exproto[_account] = excluded;

        emit Exclude(_account, excluded);
    }

    function protectAgainstMaluser(address _account, bool value)
        public
        onlyOwner
    {
        maluser[_account] = value;
    }

    function isExcluded(address _account) public view returns (bool) {
        return exproto[_account];
    }

    function swapAndLiquify(uint256 _stableTokens) private {
        uint256 stableHalf = _stableTokens;
        uint256 DOOMHalf = computeStableValueInDOOM(_stableTokens);
        addLiquidity(DOOMHalf, stableHalf);
    }

    function addLiquidity(uint256 DOOMAmount, uint256 stableAmount) private {
        router.addLiquidity(
            address(this),
            address(stableToken),
            DOOMAmount,
            stableAmount,
            0,
            0,
            address(0),
            block.timestamp
        );
    }

    function computeDOOMValueInStable(uint256 _DOOMAmount) public view returns (uint256){
        uint256 nbDOOM = this.balanceOf(pair);
        uint256 nbStable = stableToken.balanceOf(pair);
        if (nbDOOM > nbStable) {
            return _DOOMAmount/(nbDOOM/nbStable);
        }
        return _DOOMAmount*(nbStable/nbDOOM);
    }

    function computeStableValueInDOOM(uint256 _stableAmount) public view returns (uint256){
        uint256 nbDOOM = this.balanceOf(pair);
        uint256 nbStable = stableToken.balanceOf(pair);
        if (nbDOOM > nbStable) {
            return _stableAmount*(nbDOOM/nbStable);
        }
        return _stableAmount/(nbStable/nbDOOM);
    }

    function createStableNode(string memory name, uint8 _type)
        public
        nonReentrant
    {
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!maluser[sender], "NODE CREATION: Maluser address");
        uint256 nodePrice = getPriceOfNode(_type);
        require(nodePrice != 0, "PRICE CANNOT BE ZERO");
        require(
            this.balanceOf(sender) >= nodePrice,
            "NODE CREATION: DOOM balance too low for creation."
        );
        _transfer(sender, address(this), nodePrice);
        _transfer(address(this), 0x000000000000000000000000000000000000dEaD, (nodePrice*allocateBurn)/10000);
        uint256 nodePriceStable = computeDOOMValueInStable(nodePrice);
        require(
            stableToken.balanceOf(sender) >= nodePriceStable,
            "NODE CREATION: Stable token balance too low for creation."
        );
        stableToken.transferFrom(sender, address(this), nodePriceStable);
        uint256 contractStableBalance = stableToken.balanceOf(address(this));
        bool swapAmOk = contractStableBalance >= minSwapAm;
        if (swapAmOk && auth && !processing) {
            processing = true;
            if (!authLP) {
                stableToken.transfer(
                    address(protoRouter),
                    contractStableBalance
                );
            } else {
                uint256 allocateLPTokens = (contractStableBalance *
                    allocateLP) / 100;
                swapAndLiquify(allocateLPTokens);
                stableToken.transfer(
                    address(protoRouter),
                    stableToken.balanceOf(address(this))
                );
            }
            protoRouter.runStable();
            processing = false;
        }
        uint256 creationTime = createNode(sender, name, _type);
        emit CreationNode(sender, _type, creationTime);
    }

    function createForUser(
        address _account,
        string memory name,
        uint8 _type
    ) public onlyOwner {
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        require(
            _account != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!maluser[_account], "NODE CREATION: Maluser address");
        uint256 creationTime = createNode(_account, name, _type);
        emit CreationNode(_account, _type, creationTime);
    }

    function collectReward(uint256 index) public nonReentrant {
        address sender = _msgSender();
        require(sender != address(0), "CSHT: creation from the zero address");
        require(!maluser[sender], "CSHT: Maluser address");
        uint256 rewardAmount = getNodeRewardAmountOf(sender, index);
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );
        _mint(address(this), rewardAmount);
        collectNodeReward(sender, index);
        this.transfer(sender, rewardAmount);
        emit CashoutNode(sender, block.timestamp, rewardAmount);
    }

    function collectAll() public nonReentrant {
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!maluser[sender], "CSHT: Maluser address");
        uint256 rewardAmount = getRewardAmountOf(sender);
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );
        _mint(address(this), rewardAmount);
        collectAllNodesReward(sender);
        this.transfer(sender, rewardAmount);
        emit CashoutAll(sender, block.timestamp, rewardAmount);
    }

    function updateStablePriceRatio(uint256 _newMul, uint256 _newDiv)
        public
        onlyOwner
    {
        mulRatio = _newMul;
        divRatio = _newDiv;
    }

    function updateAllocations(
        uint8 _proto,
        uint8 _LP,
        uint8 _output
    ) public onlyOwner {
        allocateProtocol = _proto;
        allocateLP = _LP;
        allocateOutput = _output;
    }

    function updateSwapData(
        bool _swap,
        bool _liqui,
        uint256 _minAmount
    ) public onlyOwner {
        auth = _swap;
        authLP = _liqui;
        minSwapAm = _minAmount;
    }

    function approveRouterSpend(uint256 _amount) public onlyOwner {
        _approve(address(this), address(router), _amount*(10**6));
        stableToken.approve(address(router), _amount*(10**6));
    }
}