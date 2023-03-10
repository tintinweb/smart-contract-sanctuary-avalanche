/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-09
*/

// SPDX-License-Identifier: GPL-3.0-only

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.17;

contract Authorization {
    address public owner;
    address public newOwner;
    mapping(address => bool) public isPermitted;
    event Authorize(address user);
    event Deauthorize(address user);
    event StartOwnershipTransfer(address user);
    event TransferOwnership(address user);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier auth {
        require(isPermitted[msg.sender], "Action performed by unauthorized address.");
        _;
    }
    function transferOwnership(address newOwner_) external onlyOwner {
        newOwner = newOwner_;
        emit StartOwnershipTransfer(newOwner_);
    }
    function takeOwnership() external {
        require(msg.sender == newOwner, "Action performed by unauthorized address.");
        owner = newOwner;
        newOwner = address(0x0000000000000000000000000000000000000000);
        emit TransferOwnership(owner);
    }
    function permit(address user) external onlyOwner {
        isPermitted[user] = true;
        emit Authorize(user);
    }
    function deny(address user) external onlyOwner {
        isPermitted[user] = false;
        emit Deauthorize(user);
    }
}

pragma solidity 0.8.17;


contract SC_TradeConfigStore is Authorization {

    address public router;
    uint256 public fee;
    address public feeTo;
    SC_TradeConfigStore public newConfigStore;

    event SetRouter(address router);
    event SetFee(uint256 fee);
    event SetFeeTo(address feeTo);
    event Upgrade(SC_TradeConfigStore newConfigStore);

    constructor(address _router, uint256 _fee, address _feeTo) {
        router = _router;
        fee = _fee;
        feeTo = _feeTo;
    }
    function setRouter(address _router) external onlyOwner {
        router = _router;
        emit SetRouter(_router);
    }
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }
    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }
    function upgrade(SC_TradeConfigStore _newConfigStore) external onlyOwner {
        newConfigStore = _newConfigStore;
        emit Upgrade(_newConfigStore);
    }

    function getTradeParam() external view returns (address _router, uint256 _fee) {
        _router = router;
        _fee = fee;
    }
}
pragma solidity 0.8.17;

interface IOSWAP_HybridRouter2 {

    function registry() external view returns (address);
    function WETH() external view returns (address);

    function getPathIn(address[] calldata pair, address tokenIn) external view returns (address[] memory path);
    function getPathOut(address[] calldata pair, address tokenOut) external view returns (address[] memory path);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata pair,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (address[] memory path, uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata pair,
        address tokenOut,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (address[] memory path, uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (address[] memory path, uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (address[] memory path, uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (address[] memory path, uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (address[] memory path, uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external;

    function getAmountsInStartsWith(uint amountOut, address[] calldata pair, address tokenIn, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsInEndsWith(uint amountOut, address[] calldata pair, address tokenOut, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsOutStartsWith(uint amountIn, address[] calldata pair, address tokenIn, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsOutEndsWith(uint amountIn, address[] calldata pair, address tokenOut, bytes calldata data) external view returns (uint[] memory amounts);
}

pragma solidity 0.8.17;

// import "@openswap/sdk/contracts/router/interfaces/IOSWAP_HybridRouter2.sol"; // need solidity 0.8.17



// import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";




contract SC_TradeVault is
    ReentrancyGuard /*, ERC721Holder*/
{
    using SafeERC20 for IERC20;

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "value < 0");
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "value > int256.max");
        return int256(value);
    }

    function _transferFrom(
        IERC20 asset,
        address from,
        uint256 amount
    ) internal returns (uint256 balance) {
        balance = asset.balanceOf(address(this));
        asset.safeTransferFrom(from, address(this), amount);
        balance = asset.balanceOf(address(this)) - balance;
    }

    modifier onlyEndUser() {
        require(
            (tx.origin == msg.sender && !Address.isContract(msg.sender)),
            "Not from end user"
        );
        _;
    }

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256("OpenSwap")
    bytes32 public constant NAME_HASH =
        0xccf0ed8d136d82190c405c1be2cf07fff31d482a66996af4f69b3259174a23ba;
    // keccak256(bytes('1'))
    bytes32 public constant VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint256 nonce,address baseToken,address quoteToken,uint256 buyPrice,uint256 sellPrice,uint256 tradeLotSize,uint256 maxCount,uint256 startDate,uint256 endDate)"
        );
    // keccak256(abi.encode(EIP712_TYPEHASH, NAME_HASH, VERSION_HASH, chainId, address(this)));
    bytes32 immutable DOMAIN_SEPARATOR;

    event AddLiquidity(
        address indexed owner,
        IERC20 indexed srcToken,
        uint256 amount,
        uint256 balance
    );
    event RemoveLiquidity(
        address indexed owner,
        IERC20 indexed srcToken,
        uint256 amount,
        uint256 balance
    );
    event Swap(
        address indexed owner,
        address indexed bot,
        bytes32 indexed id,
        uint256 inAmount,
        uint256 outAmount,
        uint256 srcTokenBalance,
        uint256 outTokenBalance
    );
    event VoidOrder(
        address indexed owner,
        address indexed bot,
        uint256 indexed nonce
    );
    event UpdateConfigStore(SC_TradeConfigStore newConfigStore);

    enum TradeAction {
        Buy,
        Sell
    }

    struct Order {
        uint256 nonce;
        IERC20 baseToken;
        IERC20 quoteToken;
        uint256 buyPrice;
        uint256 sellPrice;
        uint256 tradeLotSize; // max amount per trade
        uint256 maxCount;
        uint256 startDate;
        uint256 endDate;
    }

    struct SwapInfo {
        TradeAction action;
        uint256 inAmount;
        address[] pair;
        uint256 deadline;
    }

    struct SwapTokensInfo {
        IERC20 srcToken;
        IERC20 outToken;
        uint256 price;
    }

    mapping(bytes32 => uint256) public counts;
    mapping(address => uint256) public voidedNonce;
    mapping(address => mapping(IERC20 => uint256)) public lpBalances; // lpBalances[owner][token] = balance
    mapping(address => uint256) public lpFeeBalances; // lpFeeBalances[owner] = balance
    mapping(IERC20 => uint256) public tokenBalances; //

    IERC20 public immutable feeToken;
    uint256 public totalLpFeeBalance;
    // uint256 public protocolFeeCollected;

    SC_TradeConfigStore public configStore;

    constructor(IERC20 _feeToken, SC_TradeConfigStore _configStore) {
        feeToken = _feeToken;
        configStore = _configStore;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_TYPEHASH,
                NAME_HASH,
                VERSION_HASH,
                chainId,
                address(this)
            )
        );
    }

    function updateConfigStore() external {
        configStore = configStore.newConfigStore();
        emit UpdateConfigStore(configStore);
    }

    function addLiquidity(
        IERC20 srcToken,
        uint256 amount,
        uint256 fee
    ) external nonReentrant {
        uint256 srcTokenBalance = srcToken.balanceOf(address(this));
        amount = _transferFrom(srcToken, msg.sender, amount);
        feeToken.safeTransferFrom(msg.sender, address(this), fee);
        srcTokenBalance = srcToken.balanceOf(address(this)) - srcTokenBalance;
        if (srcTokenBalance < amount) {
            // fee on transfer token
            amount = srcTokenBalance;
        }
        lpBalances[msg.sender][srcToken] += amount;
        tokenBalances[srcToken] += amount;
        lpFeeBalances[msg.sender] += fee;
        totalLpFeeBalance += fee;
        emit AddLiquidity(
            msg.sender,
            srcToken,
            amount,
            lpBalances[msg.sender][srcToken]
        );
    }

    function removeLiquidity(
        IERC20 srcToken,
        uint256 amount,
        uint256 fee
    ) external nonReentrant {
        // Order storage order = orders[srcToken][msg.sender];
        require(
            amount <= lpBalances[msg.sender][srcToken],
            "Insufficient balance"
        );
        require(fee <= lpFeeBalances[msg.sender], "Insufficient fee balance");
        lpBalances[msg.sender][srcToken] -= amount;
        tokenBalances[srcToken] -= amount;
        lpFeeBalances[msg.sender] -= fee;
        totalLpFeeBalance -= fee;
        srcToken.safeTransfer(msg.sender, amount);
        emit RemoveLiquidity(
            msg.sender,
            srcToken,
            amount,
            lpBalances[msg.sender][srcToken]
        );
    }

    function recover(bytes32 paramHash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) {
            return (address(0));
        }
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // paramHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", paramHash));
            return ecrecover(paramHash, v, r, s);
        }
    }

    function hashOrder(Order calldata order) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            ORDER_TYPEHASH,
                            order.nonce,
                            order.baseToken,
                            order.quoteToken,
                            order.buyPrice,
                            order.sellPrice,
                            order.tradeLotSize,
                            order.maxCount,
                            order.startDate,
                            order.endDate
                        )
                    )
                )
            );
    }

    function hashVoidOrder(uint256 nonce) public view returns (bytes32 hash) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        hash = keccak256(abi.encodePacked(chainId, address(this), nonce));
    }

    function voidOrder(bytes calldata signatures, uint256 nonceToVoid)
        external
        onlyEndUser
        nonReentrant
    {
        bytes32 hash = hashVoidOrder(nonceToVoid);
        address owner = recover(hash, signatures);
        require(owner != address(0), "Invalid signer");
        require(voidedNonce[owner] < nonceToVoid, "Invlid nonce");
        voidedNonce[owner] = nonceToVoid;
        emit VoidOrder(owner, msg.sender, nonceToVoid);
    }

    function getSwapTokensInfo(TradeAction action, Order calldata order)
        internal
        pure
        returns (SwapTokensInfo memory swapTokensInfo)
    {
        if (action == TradeAction.Buy) {
            swapTokensInfo = SwapTokensInfo({
                srcToken: order.quoteToken,
                outToken: order.baseToken,
                price: 1 / order.buyPrice
            });
        } else {
            swapTokensInfo = SwapTokensInfo({
                srcToken: order.baseToken,
                outToken: order.quoteToken,
                price: order.sellPrice
            });
        }
    }

    function swapExactTokensForTokens(
        bytes calldata signatures,
        SwapInfo calldata swapInfo,
        Order calldata order
    ) external onlyEndUser nonReentrant /*returns (uint256[] memory amounts) */
    {
        require(
            address(order.baseToken) != address(order.quoteToken),
            "Same tokens"
        );

        bytes32 id = hashOrder(order);
        address owner = recover(id, signatures);
        require(owner != address(0), "Invalid signer");

        counts[id]++;
        require(voidedNonce[owner] < order.nonce, "Expired nonce");
        require(counts[id] <= order.maxCount, "Max count reached");
        require(
            order.startDate <= block.timestamp &&
                block.timestamp <= order.endDate,
            "Order not started / expired"
        );

        SwapTokensInfo memory swapTokensInfo = getSwapTokensInfo(
            swapInfo.action,
            order
        );
        require(
            swapInfo.inAmount <= lpBalances[owner][swapTokensInfo.srcToken],
            "Insufficient balance"
        );

        lpBalances[owner][swapTokensInfo.srcToken] -= swapInfo.inAmount;
        tokenBalances[swapTokensInfo.srcToken] -= swapInfo.inAmount;
        address router;
        {
            uint256 fee;
            (router, fee) = configStore.getTradeParam();
            require(lpFeeBalances[owner] >= fee, "not enough fee");
            lpFeeBalances[owner] -= fee;
            totalLpFeeBalance -= fee;
            // protocolFeeCollected += fee;
        }
        uint256 outTokenBalance = swapTokensInfo.outToken.balanceOf(
            address(this)
        );
        swapTokensInfo.srcToken.approve(router, swapInfo.inAmount);
        {
            uint256 minOutAmount = (swapInfo.inAmount * swapTokensInfo.price) / 10e18;
            IOSWAP_HybridRouter2(router).swapExactTokensForTokens(
                swapInfo.inAmount,
                minOutAmount,
                swapInfo.pair,
                address(swapTokensInfo.srcToken),
                address(this),
                swapInfo.deadline,
                "0x"
            );
            outTokenBalance = swapTokensInfo.outToken.balanceOf(address(this)) - outTokenBalance;
            require(outTokenBalance >= minOutAmount, "Insufficient output");
            if (swapInfo.action == TradeAction.Buy) {
                require(swapInfo.inAmount <= order.tradeLotSize, "excceeded lot size");
            }
            else {
                require(outTokenBalance <= order.tradeLotSize, "excceeded lot size");
            }
        }
        lpBalances[owner][swapTokensInfo.outToken] += outTokenBalance;
        tokenBalances[swapTokensInfo.outToken] += outTokenBalance;

        emit Swap(
            owner,
            msg.sender,
            id,
            swapInfo.inAmount,
            outTokenBalance,
            lpBalances[owner][swapTokensInfo.srcToken],
            lpBalances[owner][swapTokensInfo.outToken]
        );
    }

    function redeemFund(IERC20 token) external {
        if (token == feeToken) {
            uint256 amount = feeToken.balanceOf(address(this)) -
                tokenBalances[feeToken] -
                totalLpFeeBalance;
            // protocolFeeCollected = 0;
            feeToken.safeTransfer(configStore.feeTo(), amount);
        } else {
            uint256 amount = token.balanceOf(address(this)) -
                tokenBalances[token];
            token.safeTransfer(configStore.feeTo(), amount);
        }
    }
}