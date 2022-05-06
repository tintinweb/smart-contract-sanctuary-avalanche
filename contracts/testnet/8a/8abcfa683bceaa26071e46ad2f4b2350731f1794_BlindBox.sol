/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    constructor () internal {
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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IEXOR {
    function randomnessRequest(
        uint256 _consumerSeed,
        uint256 _feePaid,
        address _feeToken
    ) external;
}

contract EXORRequestIDBase {

    //special process for proxy
    bytes32 public _keyHash;

    function makeVRFInputSeed(
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns ( uint256 ) {

        return uint256(keccak256(abi.encode(_userSeed, _requester, _nonce)));
    }

    function makeRequestId(
        uint256 _vRFInputSeed
    ) internal view returns (bytes32) {

        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

abstract contract EXORConsumerBase is EXORRequestIDBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ================================================== STATE VARIABLES ================================================== */
    // @notice requesting times of this consumer
    uint256 private nonces;
    // @notice reward address
    address public feeToken;
    // @notice EXORandomness address
    address private EXORAddress;
    // @notice appointed data source map
    mapping(address => bool) public datasources;

    bool private onlyInitEXOROnce;


    /* ================================================== CONSTRUCTOR ================================================== */

    function initEXORConsumerBase (
        address  _EXORAddress,
        address _feeToken,
        address _datasource
    ) public {
        require(!onlyInitEXOROnce, "exorBase already initialized");
        onlyInitEXOROnce = true;

        EXORAddress = _EXORAddress;
        feeToken = _feeToken;
        datasources[_datasource] = true;


    }

    /* ================================================== MUTATIVE FUNCTIONS ================================================== */
    // @notice developer needs to overwrites this function, and the total gas used is limited less than 200K
    //         it will be emitted when a bot put a random number to this consumer
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal virtual;

    // @notice developer needs to call this function in his own logic contract, to ask for a random number with a unique request id
    // @param _seed seed number generated from logic contract
    // @param _fee reward number given for this single request
    function requestRandomness(
        uint256 _seed,
        uint256 _fee
    )
    internal
    returns (
        bytes32 requestId
    )
    {
        IERC20(feeToken).safeApprove(EXORAddress, 0);
        IERC20(feeToken).safeApprove(EXORAddress, _fee);

        IEXOR(EXORAddress).randomnessRequest(_seed, _fee, feeToken);

        uint256 vRFSeed  = makeVRFInputSeed(_seed, address(this), nonces);
        nonces = nonces.add(1);
        return makeRequestId(vRFSeed);
    }

    // @notice only EXORandomness contract can call this function
    // @param requestId a specific request id
    // @param randomness a random number
    function rawFulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) external {
        require(msg.sender == EXORAddress, "Only EXORandomness can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

contract BlindBox is Ownable, ReentrancyGuard, EXORConsumerBase{
    using SafeMath for uint;
    using SafeERC20 for IERC20;


    uint private saleIDCounter;

    bool private onlyInitOnce;

    //data source
    //test
    //0x898527f28d6abe526308a6d18157ed1249c5bf1e
    //0xA275CfbD3549D80AE9e2Fed25B97EEA84A45e93E
    //0x75bf996d1348773144E8BFe674243192BFe48B83

    //main net
    //0x21407CE76B98955F1155f8a92eC2B1adaa0CC993
    //0xE8f5c57a5a2C0b3706F4a895E2018BEa38a47A1f
    //0xe31f0B7272E2EF4161d5a0f76040Fc464be55E4c
    //0xa6c3aD36705E007D183177e091d44643D04a74E8
    function init(address newOwner,address _EXORAddress, address _feeToken, address _datasource)  public {

        require(!onlyInitOnce, "already initialized");
        onlyInitOnce = true;
        initEXORConsumerBase(_EXORAddress,_feeToken,_datasource);
        _transferOwnership(newOwner);

    }



    //2021.9.26 only support erc721
    struct BaseSale {
        //erc721 tokenId
        uint256[] tokenIds;

        //contract address
        address contractAddress;

        // the sale setter
        address seller;

        //trading
        uint trading;

        // address of token to pay
        address payTokenAddress;
        // price of token to pay
        uint price;
        // address of receiver
        address receiver;
        uint startTime;
        uint endTime;
        // whether the sale is available
        bool isAvailable;
    }

    struct BlindBoxSale {
        BaseSale base;
        // max number of token could be bought from an address
        uint purchaseLimitation;
    }

    //async purchase
    struct BlindOrder {

        uint saleID;

        uint amount;

        //exo req id
        bytes32 requestId;

        //exo random number
        uint256 randomness;
    }


    // whitelist to set sale
    mapping(address => bool) public whitelist;
    // Payment whitelist for the address of ERC20
    mapping(address => bool) private paymentWhitelist;
    // sale ID -> blindBox sale
    mapping(uint => BlindBoxSale) blindBoxSales;
    // sale ID -> mapping(address => how many tokens have bought)
    mapping(uint => mapping(address => uint)) blindBoxSaleIDToPurchaseRecord;

    //storage reqId for query caller's address and  BlindOrder
    mapping(bytes32 => address) requestIdAndAddress;

    //reqId -> order
    mapping(bytes32 => BlindOrder) consumerOrders;

    address public serverAddress;

    // sale ID -> server hash
    mapping(bytes32 => uint)  serverHashMap;

    event SetWhitelist(address _member, bool _isAdded);
    event PaymentWhitelistChange(address erc20Addr, bool jurisdiction);
    event SetBlindBoxSale(uint _saleID, address _blindBoxSaleSetter, address _payTokenAddress,
        uint _price, address _receiver, uint _purchaseLimitation, uint _startTime, uint _endTime);
    event UpdateBlindBoxSale(uint _saleID, address _operator, address _newPayTokenAddress,
        uint _newPrice, address _newReceiver, uint _newPurchaseLimitation, uint _newStartTime, uint _newEndTime);
    event CancelBlindBoxSale(uint _saleID, address _operator);
    event BlindBoxSaleExpired(uint _saleID, address _operator);
    //v2.0 add reqId attribute
    event Purchase(uint _saleID, address _buyer, uint _remainNftTotal, address _payTokenAddress, uint _totalPayment,bytes32 _reqId);
    event AddTokens(uint256[] _tokenIds,uint _saleID);


    //extends from EXORConsumerBase
    event RequestNonce(uint256 indexed nonce);

    event PurchaseSuccess(uint _saleID, address _buyer, uint _remainNftTotal, address _payTokenAddress, uint _totalPayment,
        bytes32 _requestId, uint256 _randomness,uint[] _tokenIds);

    event DataSourceChanged(address indexed datasource, bool indexed allowed);

    //align BlindBox's nftTotal by tokenId's size
    event AlignTotalsSuccess(uint _saleID,uint  nftTotal);

    //exo timer
    uint256 public timer;


    modifier onlyWhitelist() {
        require(whitelist[msg.sender],
            "the caller isn't in the whitelist");
        _;
    }

    modifier onlyPaymentWhitelist(address erc20Addr) {
        require(paymentWhitelist[erc20Addr],
            "the pay token address isn't in the whitelist");
        _;
    }

    function setWhitelist(address _member, bool _status) external onlyOwner {
        whitelist[_member] = _status;
        emit SetWhitelist(_member, _status);
    }
    /**
     * @dev Public function to set the payment whitelist only by the owner.
     * @param erc20Addr address address of erc20 for paying
     * @param jurisdiction bool in or out of the whitelist
     */
    function setPaymentWhitelist(address erc20Addr, bool jurisdiction) public onlyOwner {
        paymentWhitelist[erc20Addr] = jurisdiction;
        emit PaymentWhitelistChange(erc20Addr, jurisdiction);
    }

    // set blindBox sale by the member in whitelist
    // NOTE: set 0 duration if you don't want an endTime
    function setBlindBoxSale(

        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration,
        address _contractAddress//add contract address
    ) external nonReentrant onlyWhitelist onlyPaymentWhitelist(_payTokenAddress) {
        // 1. check the validity of params
        _checkBlindBoxSaleParams(_price, _startTime, _purchaseLimitation);

        // 2.  build blindBox sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }

        BaseSale memory baseSale;
        baseSale.seller = msg.sender;
        baseSale.trading = 0;
        baseSale.payTokenAddress = _payTokenAddress;
        baseSale.price = _price;
        baseSale.receiver = _receiver;
        baseSale.startTime = _startTime;
        baseSale.endTime = endTime;
        baseSale.isAvailable = true;
        baseSale.contractAddress = _contractAddress;



        BlindBoxSale memory blindBoxSale = BlindBoxSale({
            base : baseSale,
            purchaseLimitation : _purchaseLimitation
            });

        // 3. store blindBox sale
        uint currentSaleID = saleIDCounter;
        saleIDCounter = saleIDCounter.add(1);
        blindBoxSales[currentSaleID] = blindBoxSale;
        emit SetBlindBoxSale(currentSaleID, blindBoxSale.base.seller,
            blindBoxSale.base.payTokenAddress, blindBoxSale.base.price, blindBoxSale.base.receiver, blindBoxSale.purchaseLimitation,
            blindBoxSale.base.startTime, blindBoxSale.base.endTime);
    }



    //admin add token to blindboxSale
    function addTokenIdToBlindBoxSale(uint _saleID,address _contractAddress, uint256[] memory _tokenIds) external onlyWhitelist{

        BlindBoxSale storage blindBoxSale = blindBoxSales[_saleID];

        require(blindBoxSale.base.startTime > now,
            "it's not allowed to update the blindBox sale after the start of it");

        require(blindBoxSale.base.seller == msg.sender,
            "the blindBox sale can only be updated by its setter");

        require(blindBoxSale.base.contractAddress==_contractAddress,
            "the contract and saleId doesn't match");


        IERC721 tokenAddressCached = IERC721(blindBoxSale.base.contractAddress);
        for(uint i = 0; i < _tokenIds.length; i++) {
            uint256  tokenId = _tokenIds[i];
            require(tokenAddressCached.ownerOf(tokenId) == blindBoxSale.base.seller,
                "unmatched ownership of target ERC721 token");
            blindBoxSale.base.tokenIds.push(tokenId);
        }

        emit AddTokens(_tokenIds,_saleID);
    }

    // update the blindBox sale before starting
    // NOTE: set 0 duration if you don't want an endTime
    function updateBlindBoxSale(
        uint _saleID,
        address _payTokenAddress,
        uint _price,
        address _receiver,
        uint _purchaseLimitation,
        uint _startTime,
        uint _duration
    ) external nonReentrant onlyWhitelist onlyPaymentWhitelist(_payTokenAddress) {
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        // 1. make sure that the blindBox sale doesn't start
        require(blindBoxSale.base.startTime > now,
            "it's not allowed to update the blindBox sale after the start of it");
        require(blindBoxSale.base.isAvailable,
            "the blindBox sale has been cancelled");
        require(blindBoxSale.base.seller == msg.sender,
            "the blindBox sale can only be updated by its setter");

        // 2. check the validity of params to update
        _checkBlindBoxSaleParams( _price, _startTime, _purchaseLimitation);

        // 3. update blindBox sale
        uint endTime;
        if (_duration != 0) {
            endTime = _startTime.add(_duration);
        }



        blindBoxSale.base.payTokenAddress = _payTokenAddress;
        blindBoxSale.base.price = _price;
        blindBoxSale.base.receiver = _receiver;
        blindBoxSale.base.startTime = _startTime;
        blindBoxSale.base.endTime = endTime;
        blindBoxSale.purchaseLimitation = _purchaseLimitation;
        blindBoxSales[_saleID] = blindBoxSale;
        emit UpdateBlindBoxSale(_saleID, blindBoxSale.base.seller,
            blindBoxSale.base.payTokenAddress, blindBoxSale.base.price, blindBoxSale.base.receiver, blindBoxSale.purchaseLimitation,
            blindBoxSale.base.startTime, blindBoxSale.base.endTime);
    }

    // cancel the blindBox sale
    function cancelBlindBoxSale(uint _saleID) external onlyWhitelist {
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        require(blindBoxSale.base.isAvailable,
            "the blindBox sale isn't available");
        require(blindBoxSale.base.seller == msg.sender,
            "the blindBox sale can only be cancelled by its setter");

        blindBoxSales[_saleID].base.isAvailable = false;
        emit CancelBlindBoxSale(_saleID, msg.sender);
    }

    uint256 oraclePrice;

    function setOraclePrice(uint256 _oraclePrice) public onlyOwner{
        oraclePrice = _oraclePrice;
    }
    //generate reqId and send req to ex oracle
    function sendOracleReq(uint amount) private returns (bytes32 requestId){

        //10 nft gas : 0.0005 special process 500000000000000
        uint256 price = oraclePrice * amount;

        //used order count change exor fee
        bytes32 reqId = requestRandomness(timer,price);//60000000000000000 is 0.06 exor token
        timer = timer + 1;
        emit RequestNonce(timer);
        return reqId;
    }

    /**
    * Enable or Disable a datasource
    */
    function changeDataSource(address _datasource, bool _boolean) external onlyOwner {
        datasources[_datasource] = _boolean;
        emit DataSourceChanged(_datasource, _boolean);
    }


    function setServerAddress(address targetAddress) public onlyOwner{
        serverAddress = targetAddress;
    }


    //step2 pay and purchase
    //新版本 function purchase() external nonReentrant
    // rush to purchase by anyone
    function purchase(uint _saleID, uint _amount,bytes32 hash,uint8 v, bytes32 r, bytes32 s) external nonReentrant {

        require(ecrecover(hash, v, r, s) == serverAddress,"verify server sign failed") ;

        require(serverHashMap[hash] != _saleID,"sign hash repeat") ;

        //msg.sender获取order对象
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        // check the validity
        require(_amount > 0,
            "amount should be > 0");
        require(blindBoxSale.base.isAvailable,
            "the blindBox sale isn't available");
        require(blindBoxSale.base.seller != msg.sender,
            "the setter can't make a purchase from its own blindBox sale");
        uint currentTime = now;
        require(currentTime >= blindBoxSale.base.startTime,
            "the blindBox sale doesn't start");

        // check whether the end time arrives
        if (blindBoxSale.base.endTime != 0 && blindBoxSale.base.endTime <= currentTime) {
            // the blindBox sale has been set an end time and expired
            blindBoxSales[_saleID].base.isAvailable = false;
            emit BlindBoxSaleExpired(_saleID, msg.sender);
            return;
        }

        //compute curent tokenIds sub current tranding
        uint remainingAmount = blindBoxSales[_saleID].base.tokenIds.length - blindBoxSales[_saleID].base.trading;

        // check  remain amount is enough
        require(_amount <= remainingAmount ,
            "insufficient amount of token for this trade");


        // check the purchase record of the buyer
        uint newPurchaseRecord = blindBoxSaleIDToPurchaseRecord[_saleID][msg.sender].add(_amount);
        require(newPurchaseRecord <= blindBoxSale.purchaseLimitation,
            "total amount to purchase exceeds the limitation of an address");



        // pay the receiver
        blindBoxSaleIDToPurchaseRecord[_saleID][msg.sender] = newPurchaseRecord;
        uint totalPayment = blindBoxSale.base.price.mul(_amount);
        IERC20(blindBoxSale.base.payTokenAddress).safeTransferFrom(msg.sender, blindBoxSale.base.receiver, totalPayment);


        //fronzen trading amount
        blindBoxSales[_saleID].base.trading = blindBoxSales[_saleID].base.trading + _amount;
        uint newRemainingAmount = blindBoxSales[_saleID].base.tokenIds.length - blindBoxSales[_saleID].base.trading;

        if ( newRemainingAmount == 0) {
            blindBoxSales[_saleID].base.isAvailable = false;
        }


        //pay erc20 success , create BlindOrder
        BlindOrder memory order;
        order.saleID = _saleID;
        order.amount = _amount;

        bytes32 reqId = sendOracleReq(_amount);
        order.requestId = reqId;

        //storage user's address and order
        consumerOrders[reqId] = order;
        //storage requestId and user's address for auth
        requestIdAndAddress[reqId] = msg.sender;

        serverHashMap[hash] = _saleID;
        emit Purchase(_saleID, msg.sender, newRemainingAmount, blindBoxSale.base.payTokenAddress, totalPayment,reqId);
    }



    //ex oracle's callback function,process lottery
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {

        address  userAddress = requestIdAndAddress[requestId];

        require(userAddress != address(0), "the target order  doesn't exist");

        BlindOrder storage order = consumerOrders[requestId];

        order.randomness = randomness;


        uint[] memory tokenIDsRecord = new uint[](order.amount);

        uint tokenSize = blindBoxSales[order.saleID].base.tokenIds.length;

        for (uint i = 0; i < order.amount; i++) {
            uint index = randomness % tokenSize;

            uint256 tokenId = blindBoxSales[order.saleID].base.tokenIds[index];

            // call other contract use tokenId and sender address
            IERC721(blindBoxSales[order.saleID].base.contractAddress).safeTransferFrom(
                blindBoxSales[order.saleID].base.seller,
                requestIdAndAddress[requestId],
                tokenId);

            //for event
            tokenIDsRecord[i] = tokenId;
            //array tail -> array[index]
            blindBoxSales[order.saleID].base.tokenIds[index] = blindBoxSales[order.saleID].base.tokenIds[tokenSize-1];
            tokenSize--;
            //array tail pop
            blindBoxSales[order.saleID].base.tokenIds.pop();
        }


        //sub trading value
        blindBoxSales[order.saleID].base.trading = blindBoxSales[order.saleID].base.trading - order.amount;

        uint remainNftTotal = blindBoxSales[order.saleID].base.tokenIds.length - blindBoxSales[order.saleID].base.trading;

        address payTokenAddress = blindBoxSales[order.saleID].base.payTokenAddress;

        uint totalPayment = blindBoxSales[order.saleID].base.price.mul(order.amount);

        uint rSaleId = order.saleID;
        // remove consumerOrders and requestIdAndAddress
        delete requestIdAndAddress[requestId];
        delete consumerOrders[requestId];


        emit PurchaseSuccess(rSaleId,userAddress,remainNftTotal,payTokenAddress,totalPayment,requestId, randomness,tokenIDsRecord);


    }

    //special process for proxy
    function setKeyHash() external onlyOwner {

        _keyHash = 0;
    }


    // read method
    function getBlindBoxSaleTokenRemaining(uint _saleID) public view returns (uint){
        // check whether the blindBox sale ID exists
        BlindBoxSale memory blindBoxSale = _getBlindBoxSaleByID(_saleID);
        return blindBoxSale.base.tokenIds.length - blindBoxSale.base.trading;
    }

    function getBlindBoxSalePurchaseRecord(uint _saleID, address _buyer) public view returns (uint){
        // check whether the blindBox sale ID exists
        _getBlindBoxSaleByID(_saleID);
        return blindBoxSaleIDToPurchaseRecord[_saleID][_buyer];
    }

    function getBlindBoxSale(uint _saleID) public view returns (BlindBoxSale memory){
        return _getBlindBoxSaleByID(_saleID);
    }


    /**
     * @dev Public function to query whether the target erc20 address is in the payment whitelist.
     * @param erc20Addr address target address of erc20 to query about
     */
    function getPaymentWhitelist(address erc20Addr) public view returns (bool){
        return paymentWhitelist[erc20Addr];
    }

    function _getBlindBoxSaleByID(uint _saleID) internal view returns (BlindBoxSale memory blindBoxSale){
        blindBoxSale = blindBoxSales[_saleID];
        require(blindBoxSale.base.seller != address(0),
            "the target blindBox sale doesn't exist");
    }

    function _checkBlindBoxSaleParams(
        uint _price,
        uint _startTime,
        uint _purchaseLimitation
    ) internal {


        require(_price > 0,
            "the price or the initial price must be > 0");

        require(_startTime >= now,
            "startTime must be >= now");

        require(_purchaseLimitation > 0,
            "purchaseLimitation must be > 0");

    }





}