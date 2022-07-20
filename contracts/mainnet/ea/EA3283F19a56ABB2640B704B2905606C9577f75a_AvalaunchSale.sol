/**
 *Submitted for verification at snowtrace.io on 2022-07-20
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IAdmin.sol

pragma solidity 0.6.12;

interface IAdmin {
    function isAdmin(address user) external view returns (bool);
}


// File contracts/interfaces/ISalesFactory.sol

pragma solidity 0.6.12;

interface ISalesFactory {
    function isSaleCreatedThroughFactory(address sale) external view returns (bool);
}


// File contracts/interfaces/IAllocationStaking.sol

pragma solidity 0.6.12;

interface IAllocationStaking {
    function redistributeXava(uint256 _pid, address _user, uint256 _amountToBurn) external;
    function deposited(uint256 _pid, address _user) external view returns (uint256);
    function setTokensUnlockTime(uint256 _pid, address _user, uint256 _tokensUnlockTime) external;
}


// File contracts/interfaces/IERC20Metadata.sol


pragma solidity ^0.6.12;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata {
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


// File contracts/interfaces/IDexalotPortfolio.sol

pragma solidity ^0.6.12;

/**
 * IDexalotPortfolio contract.
 * Date created: 28.1.22.
 */
interface IDexalotPortfolio {
    function depositTokenFromContract(address _from, bytes32 _symbol, uint _quantity) external;
}


// File contracts/interfaces/ICollateral.sol

pragma solidity ^0.6.12;

interface ICollateral {
    function saleAutoBuyers(address user, address sale) external view returns (bool);
    function depositCollateral() external payable;
    function withdrawCollateral() external payable;
    function totalBalance() external view returns (uint256);
}


// File @openzeppelin/contracts/cryptography/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/math/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;



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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}


// File contracts/sales/AvalaunchSale.sol

pragma solidity 0.6.12;









contract AvalaunchSale is Initializable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Pointer to Allocation staking contract, where burnXavaFromUser will be called.
    IAllocationStaking public allocationStakingContract;
    // Pointer to sales factory contract
    ISalesFactory public factory;
    // Admin contract
    IAdmin public admin;
    // Avalaunch collateral contract
    ICollateral public collateral;
    // Pointer to dexalot portfolio smart-contract
    IDexalotPortfolio public dexalotPortfolio;

    struct Sale {
        // Token being sold
        IERC20 token;
        // Is sale created
        bool isCreated;
        // Are earnings withdrawn
        bool earningsWithdrawn;
        // Is leftover withdrawn
        bool leftoverWithdrawn;
        // Have tokens been deposited
        bool tokensDeposited;
        // Address of sale owner
        address saleOwner;
        // Price of the token quoted in AVAX
        uint256 tokenPriceInAVAX;
        // Amount of tokens to sell
        uint256 amountOfTokensToSell;
        // Total tokens being sold
        uint256 totalTokensSold;
        // Total AVAX Raised
        uint256 totalAVAXRaised;
        // Sale end time
        uint256 saleEnd;
        // Price of the token quoted in USD
        uint256 tokenPriceInUSD;
    }

    // Participation structure
    struct Participation {
        uint256 amountBought;
        uint256 amountAVAXPaid;
        uint256 timeParticipated;
        uint256 roundId;
        bool[] isPortionWithdrawn;
        bool[] isPortionWithdrawnToDexalot;
        bool isParticipationBoosted;
        uint256 boostedAmountAVAXPaid;
        uint256 boostedAmountBought;
    }

    // Round structure
    struct Round {
        uint256 startTime;
        uint256 maxParticipation;
    }

    struct Registration {
        uint256 registrationTimeStarts;
        uint256 registrationTimeEnds;
        uint256 numberOfRegistrants;
    }

    // Sale
    Sale public sale;
    // Registration
    Registration public registration;
    // Number of users participated in the sale.
    uint256 public numberOfParticipants;
    // Array storing IDS of rounds (IDs start from 1, so they can't be mapped as array indexes
    uint256[] public roundIds;
    // Mapping round Id to round
    mapping(uint256 => Round) public roundIdToRound;
    // Mapping user to his participation
    mapping(address => Participation) public userToParticipation;
    // User to round for which he registered
    mapping(address => uint256) public addressToRoundRegisteredFor;
    // mapping if user is participated or not
    mapping(address => bool) public isParticipated;
    // Times when portions are getting unlocked
    uint256[] public vestingPortionsUnlockTime;
    // Percent of the participation user can withdraw
    uint256[] public vestingPercentPerPortion;
    //Precision for percent for portion vesting
    uint256 public portionVestingPrecision;
    // Added configurable round ID for staking round
    uint256 public stakingRoundId;
    // Added configurable round ID for staking round
    uint256 public boosterRoundId;
    // Max vesting time shift
    uint256 public maxVestingTimeShift;
    // Registration deposit AVAX, which will be paid during the registration, and returned back during the participation.
    uint256 public registrationDepositAVAX;
    // Accounting total AVAX collected, after sale admin can withdraw this
    uint256 public registrationFees;
    // Price update percent threshold
    uint8 updateTokenPriceInAVAXPercentageThreshold;
    // Price update time limit
    uint256 updateTokenPriceInAVAXTimeLimit;
    // Token price in AVAX latest update timestamp
    uint256 updateTokenPriceInAVAXLastCallTimestamp;
    // If Dexalot Withdrawals are supported
    bool public supportsDexalotWithdraw;
    // Represent amount of seconds before 0 portion unlock users can at earliest move their tokens to dexalot
    uint256 public dexalotUnlockTime;
    // Sale setter gate flag
    bool public gateClosed;

    // Restricting calls only to sale owner
    modifier onlySaleOwner() {
        require(msg.sender == sale.saleOwner, "Restricted to sale owner.");
        _;
    }

    // Restricting calls only to sale admin
    modifier onlyAdmin() {
        require(
            admin.isAdmin(msg.sender),
            "Restricted to admins."
        );
        _;
    }

    // Restricting setter calls after gate closing
    modifier onlyIfGateOpen() {
        require(!gateClosed, "Gate is closed.");
        _;
    }

    // Events
    event TokensSold(address user, uint256 amount);
    event UserRegistered(address user, uint256 roundId);
    event TokenPriceSet(uint256 newPrice);
    event MaxParticipationSet(uint256 roundId, uint256 maxParticipation);
    event TokensWithdrawn(address user, uint256 amount);
    event SaleCreated(
        address saleOwner,
        uint256 tokenPriceInAVAX,
        uint256 amountOfTokensToSell,
        uint256 saleEnd,
        uint256 tokenPriceInUSD
    );
    event RegistrationTimeSet(
        uint256 registrationTimeStarts,
        uint256 registrationTimeEnds
    );
    event RoundAdded(
        uint256 roundId,
        uint256 startTime,
        uint256 maxParticipation
    );
    event RegistrationAVAXRefunded(address user, uint256 amountRefunded);
    event TokensWithdrawnToDexalot(address user, uint256 amount);
    event GateClosed(uint256 time);
    event ParticipationBoosted(address user, uint256 amountAVAX, uint256 amountTokens);

    // Constructor replacement for upgradable contracts
    function initialize(
        address _admin,
        address _allocationStaking,
        address _collateral
    ) public initializer {
        require(_admin != address(0));
        require(_allocationStaking != address(0));
        require(_collateral != address(0));
        admin = IAdmin(_admin);
        factory = ISalesFactory(msg.sender);
        allocationStakingContract = IAllocationStaking(_allocationStaking);
        collateral = ICollateral(_collateral);
    }

    /// @notice         Function to set vesting params
    function setVestingParams(
        uint256[] memory _unlockingTimes,
        uint256[] memory _percents,
        uint256 _maxVestingTimeShift
    )
        external
        onlyAdmin
    {
        require(
            vestingPercentPerPortion.length == 0 &&
            vestingPortionsUnlockTime.length == 0
        );
        require(_unlockingTimes.length == _percents.length);
        require(portionVestingPrecision > 0, "Sale params not set.");
        require(_maxVestingTimeShift <= 30 days, "Maximal shift is 30 days.");

        // Set max vesting time shift
        maxVestingTimeShift = _maxVestingTimeShift;

        uint256 sum;

        // Require that locking times are later than sale end
        require(_unlockingTimes[0] > sale.saleEnd, "Unlock time must be after the sale ends.");

        // Set vesting portions percents and unlock times
        for (uint256 i = 0; i < _unlockingTimes.length; i++) {
            if(i > 0) {
                require(_unlockingTimes[i] > _unlockingTimes[i-1], "Unlock time must be greater than previous.");
            }
            vestingPortionsUnlockTime.push(_unlockingTimes[i]);
            vestingPercentPerPortion.push(_percents[i]);
            sum = sum.add(_percents[i]);
        }

        require(sum == portionVestingPrecision, "Percent distribution issue.");
    }

    /// @notice     Admin function to shift vesting unlocking times
    function shiftVestingUnlockingTimes(uint256 timeToShift)
        external
        onlyAdmin
    {
        require(
            timeToShift > 0 && timeToShift < maxVestingTimeShift,
            "Invalid shift time."
        );

        // Time can be shifted only once.
        maxVestingTimeShift = 0;

        // Shift the unlock time
        for (uint256 i = 0; i < vestingPortionsUnlockTime.length; i++) {
            vestingPortionsUnlockTime[i] = vestingPortionsUnlockTime[i].add(
                timeToShift
            );
        }
    }

    /// @notice     Admin function to set sale parameters
    function setSaleParams(
        address _token,
        address _saleOwner,
        uint256 _tokenPriceInAVAX,
        uint256 _amountOfTokensToSell,
        uint256 _saleEnd,
        uint256 _portionVestingPrecision,
        uint256 _stakingRoundId,
        uint256 _registrationDepositAVAX,
        uint256 _tokenPriceInUSD
    )
        external
        onlyAdmin
    {
        require(!sale.isCreated, "Sale already created.");
        require(
            _saleOwner != address(0),
            "Invalid sale owner address."
        );
        require(
            _tokenPriceInAVAX != 0 &&
            _amountOfTokensToSell != 0 &&
            _saleEnd > block.timestamp &&
            _tokenPriceInUSD != 0,
            "Invalid input."
        );
        require(_portionVestingPrecision >= 100, "Should be at least 100");
        require(_stakingRoundId > 0, "Invalid staking round id.");

        // Set params
        sale.token = IERC20(_token);
        sale.isCreated = true;
        sale.saleOwner = _saleOwner;
        sale.tokenPriceInAVAX = _tokenPriceInAVAX;
        sale.amountOfTokensToSell = _amountOfTokensToSell;
        sale.saleEnd = _saleEnd;
        sale.tokenPriceInUSD = _tokenPriceInUSD;

        // Deposit in AVAX, sent during the registration
        registrationDepositAVAX = _registrationDepositAVAX;
        // Set portion vesting precision
        portionVestingPrecision = _portionVestingPrecision;
        // Set staking round id
        stakingRoundId = _stakingRoundId;
        // Set booster round id
        boosterRoundId = _stakingRoundId.add(1);

        // Emit event
        emit SaleCreated(
            sale.saleOwner,
            sale.tokenPriceInAVAX,
            sale.amountOfTokensToSell,
            sale.saleEnd,
            sale.tokenPriceInUSD
        );
    }

    /// @notice  If sale supports early withdrawals to Dexalot.
    function setAndSupportDexalotPortfolio(
        address _dexalotPortfolio,
        uint256 _dexalotUnlockTime
    )
    external
    onlyAdmin
    {
        require(address(dexalotPortfolio) == address(0x0), "Dexalot Portfolio already set.");
        require(_dexalotPortfolio != address(0x0), "Invalid address.");
        dexalotPortfolio = IDexalotPortfolio(_dexalotPortfolio);
        dexalotUnlockTime = _dexalotUnlockTime;
        supportsDexalotWithdraw = true;
    }

    // @notice     Function to retroactively set sale token address after initial contract creation has passed.
    //             Added as an option for teams which are not having token at the moment of sale launch.
    function setSaleToken(
        address saleToken
    )
        external
        onlyAdmin
        onlyIfGateOpen
    {
        sale.token = IERC20(saleToken);
    }


    /// @notice     Function to set registration period parameters
    function setRegistrationTime(
        uint256 _registrationTimeStarts,
        uint256 _registrationTimeEnds
    )
        external
        onlyAdmin
        onlyIfGateOpen
    {
        // Require that the sale is created
        require(sale.isCreated);
        require(
            _registrationTimeStarts >= block.timestamp &&
                _registrationTimeEnds > _registrationTimeStarts
        );
        require(_registrationTimeEnds < sale.saleEnd);

        if (roundIds.length > 0) {
            require(
                _registrationTimeEnds < roundIdToRound[roundIds[0]].startTime
            );
        }

        // Set registration start and end time
        registration.registrationTimeStarts = _registrationTimeStarts;
        registration.registrationTimeEnds = _registrationTimeEnds;

        emit RegistrationTimeSet(
            registration.registrationTimeStarts,
            registration.registrationTimeEnds
        );
    }

    /// @notice     Setting rounds for sale.
    function setRounds(
        uint256[] calldata startTimes,
        uint256[] calldata maxParticipations
    )
        external
        onlyAdmin
    {
        require(sale.isCreated);
        require(
            startTimes.length == maxParticipations.length,
            "Invalid array lengths."
        );
        require(roundIds.length == 0, "Rounds set already.");
        require(startTimes.length > 0);

        uint256 lastTimestamp = 0;

        require(startTimes[0] > registration.registrationTimeEnds);
        require(startTimes[0] >= block.timestamp);

        for (uint256 i = 0; i < startTimes.length; i++) {
            require(startTimes[i] < sale.saleEnd);
            require(maxParticipations[i] > 0);
            require(startTimes[i] > lastTimestamp);
            lastTimestamp = startTimes[i];

            // Compute round Id
            uint256 roundId = i + 1;

            // Push id to array of ids
            roundIds.push(roundId);

            // Create round
            Round memory round = Round(startTimes[i], maxParticipations[i]);

            // Map round id to round
            roundIdToRound[roundId] = round;

            // Fire event
            emit RoundAdded(roundId, round.startTime, round.maxParticipation);
        }
    }

    /// @notice     Registration for sale.
    /// @param      signature is the message signed by the backend
    /// @param      roundId is the round for which user expressed interest to participate
    function registerForSale(
        bytes memory signature,
        uint256 signatureExpirationTimestamp,
        uint256 roundId
    )
        external
        payable
    {
        require(
            msg.value == registrationDepositAVAX,
            "Registration deposit doesn't match."
        );
        require(roundId != 0, "Invalid round id.");
        require(roundId <= roundIds.length, "Invalid round id");
        require(
            block.timestamp >= registration.registrationTimeStarts &&
                block.timestamp <= registration.registrationTimeEnds,
            "Registration gate is closed."
        );
        require(
            checkRegistrationSignature(signature, signatureExpirationTimestamp, msg.sender, roundId),
            "Invalid signature."
        );
        require(block.timestamp < signatureExpirationTimestamp, "Signature expired.");
        require(
            addressToRoundRegisteredFor[msg.sender] == 0,
            "User already registered."
        );

        // Rounds are 1,2,3
        addressToRoundRegisteredFor[msg.sender] = roundId;
        // Special cases for staking round
        if (roundId == stakingRoundId) {
            // Lock users stake
            allocationStakingContract.setTokensUnlockTime(
                0,
                msg.sender,
                sale.saleEnd
            );
        }
        // Increment number of registered users
        registration.numberOfRegistrants++;
        // Increase earnings from registration fees
        registrationFees = registrationFees.add(msg.value);
        // Emit Registration event
        emit UserRegistered(msg.sender, roundId);
    }

    /// @notice     Admin function, to update token price before sale to match the closest $ desired rate.
    /// @dev        This will be updated with an oracle during the sale every N minutes, so the users will always
    ///             pay initialy set $ value of the token. This is to reduce reliance on the AVAX volatility.
    function updateTokenPriceInAVAX(uint256 price) external onlyAdmin {
        // Zero check on the first set
        if(sale.tokenPriceInAVAX != 0) {
            // Require that function params are properly set
            require(
                updateTokenPriceInAVAXTimeLimit != 0 && updateTokenPriceInAVAXPercentageThreshold != 0,
                "Params not set."
            );

            // Require that the price does not differ more than 'N%' from previous one
            uint256 maxPriceChange = sale.tokenPriceInAVAX.mul(updateTokenPriceInAVAXPercentageThreshold).div(100);
            require(
                price < sale.tokenPriceInAVAX.add(maxPriceChange) &&
                price > sale.tokenPriceInAVAX.sub(maxPriceChange),
                "Price too different from the previous."
            );

            // Require that 'N' time has passed since last call
            require(
                updateTokenPriceInAVAXLastCallTimestamp.add(updateTokenPriceInAVAXTimeLimit) < block.timestamp,
                "Not enough time passed since last call."
            );
        }

        // Set latest call time to current timestamp
        updateTokenPriceInAVAXLastCallTimestamp = block.timestamp;

        // Allowing oracle to run and change the sale value
        sale.tokenPriceInAVAX = price;
        emit TokenPriceSet(price);
    }

    /// @notice     Admin function to postpone the sale
    function postponeSale(uint256 timeToShift) external onlyAdmin {
        require(
            block.timestamp < roundIdToRound[roundIds[0]].startTime,
            "1st round already started."
        );
        // Iterate through all registered rounds and postpone them
        for (uint256 i = 0; i < roundIds.length; i++) {
            Round storage round = roundIdToRound[roundIds[i]];
            // Require that timeToShift does not extend sale over it's end
            require(
                round.startTime.add(timeToShift) < sale.saleEnd,
                "Start time can not be greater than end time."
            );
            // Postpone sale
            round.startTime = round.startTime.add(timeToShift);
        }
    }

    /// @notice     Function to extend registration period
    function extendRegistrationPeriod(uint256 timeToAdd) external onlyAdmin {
        require(
            registration.registrationTimeEnds.add(timeToAdd) <
                roundIdToRound[roundIds[0]].startTime,
            "Registration period overflows sale start."
        );

        registration.registrationTimeEnds = registration
            .registrationTimeEnds
            .add(timeToAdd);
    }

    /// @notice     Admin function to set max participation cap per round
    function setCapPerRound(uint256[] calldata rounds, uint256[] calldata caps)
        external
        onlyAdmin
    {
        // Require that round has not already started
        require(
            block.timestamp < roundIdToRound[roundIds[0]].startTime,
            "Rounds started."
        );
        require(rounds.length == caps.length, "Array size mismatch.");

        // Set max participation per round
        for (uint256 i = 0; i < rounds.length; i++) {
            require(caps[i] > 0, "Invalid cap.");

            Round storage round = roundIdToRound[rounds[i]];
            round.maxParticipation = caps[i];

            emit MaxParticipationSet(rounds[i], round.maxParticipation);
        }
    }

    // Function to asynchronously set the amount of tokens to sell
    function setAmountOfTokensToSell(uint256 _amountOfTokensToSell, uint256 _tokenPriceInUSD) external onlySaleOwner onlyIfGateOpen {
        sale.tokenPriceInUSD = _tokenPriceInUSD;
        sale.amountOfTokensToSell = _amountOfTokensToSell;
    }

    // Function for owner to deposit tokens, can be called only once.
    function depositTokens() external onlySaleOwner onlyIfGateOpen {
        // Require that setSaleParams was called
        require(sale.isCreated);

        // Require that tokens are not deposited
        require(!sale.tokensDeposited);

        // Mark that tokens are deposited
        sale.tokensDeposited = true;

        // Perform safe transfer
        sale.token.safeTransferFrom(
            msg.sender,
            address(this),
            sale.amountOfTokensToSell
        );
    }

    // Participate function for collateral auto-buy
    function autoParticipate(
        address user,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId
    ) external payable {
        require(msg.sender == address(collateral), "Only collateral.");
        _participate(user, msg.value, amount, amountXavaToBurn, roundId);
    }

    // Participate function for manual participation
    function participate(
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId,
        bytes calldata signature
    ) external payable {
        require(msg.sender == tx.origin, "Only direct calls.");
        // Require that user doesn't have autoBuy activated
        require(!collateral.saleAutoBuyers(address(this), msg.sender), "Cannot participate manually, autoBuy activated.");
        // Verify the signature
        require(
            checkParticipationSignature(
                signature,
                msg.sender,
                amount,
                amountXavaToBurn,
                roundId
            ),
            "Invalid signature."
        );

        _participate(msg.sender, msg.value, amount, amountXavaToBurn, roundId);
    }

    // Function to participate in the sales
    function _participate(
        address user,
        uint256 amountAVAX,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId
    ) internal {

        require(roundId != 0, "Round can not be 0.");

        require(
            amount <= roundIdToRound[roundId].maxParticipation,
            "Crossing max participation."
        );

        // User must have registered for the round in advance
        require(
            addressToRoundRegisteredFor[user] == roundId,
            "Invalid round."
        );

        // Check user haven't participated before
        require(!isParticipated[user], "Already participated.");

        // Get current active round
        uint256 currentRound = getCurrentRound();

        // Assert that
        require(
            roundId == currentRound,
            "Invalid round."
        );

        // Compute the amount of tokens user is buying
        uint256 amountOfTokensBuying =
            (amountAVAX).mul(uint(10) ** IERC20Metadata(address(sale.token)).decimals()).div(sale.tokenPriceInAVAX);

        // Must buy more than 0 tokens
        require(amountOfTokensBuying > 0, "Can't buy 0 tokens");

        // Check in terms of user allo
        require(
            amountOfTokensBuying <= amount,
            "Exceeding allowance."
        );

        // Require that amountOfTokensBuying is less than sale token leftover cap
        require(
            amountOfTokensBuying <= sale.amountOfTokensToSell.sub(sale.totalTokensSold),
            "Not enough tokens to sell."
        );

        // Increase amount of sold tokens
        sale.totalTokensSold = sale.totalTokensSold.add(amountOfTokensBuying);

        // Increase amount of AVAX raised
        sale.totalAVAXRaised = sale.totalAVAXRaised.add(amountAVAX);

        // Empty bool array used to be set as initial for 'isPortionWithdrawn' and 'isPortionWithdrawnToDexalot'
        // Size determined by number of sale portions
        bool[] memory _empty = new bool[](
            vestingPortionsUnlockTime.length
        );

        // Create participation object
        Participation memory p = Participation({
            amountBought: amountOfTokensBuying,
            amountAVAXPaid: amountAVAX,
            timeParticipated: block.timestamp,
            roundId: roundId,
            isPortionWithdrawn: _empty,
            isPortionWithdrawnToDexalot: _empty,
            isParticipationBoosted: false,
            boostedAmountAVAXPaid: 0,
            boostedAmountBought: 0
        });

        // Staking round only.
        if (roundId == stakingRoundId) {
            // Burn XAVA from this user.
            allocationStakingContract.redistributeXava(
                0,
                user,
                amountXavaToBurn
            );
        }

        // Add participation for user.
        userToParticipation[user] = p;
        // Mark user is participated
        isParticipated[user] = true;
        // Increment number of participants in the Sale.
        numberOfParticipants++;
        // Decrease of available registration fees
        registrationFees = registrationFees.sub(registrationDepositAVAX);
        // Transfer registration deposit amount in AVAX back to the users.
        safeTransferAVAX(user, registrationDepositAVAX);

        emit RegistrationAVAXRefunded(user, registrationDepositAVAX);
        emit TokensSold(user, amountOfTokensBuying);
    }

    // Function to boost user's sale participation
    function boostParticipation(
        address user,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId
    ) external payable {
        require(msg.sender == address(collateral), "Only collateral.");
        require(roundId == boosterRoundId && roundId == getCurrentRound(), "Invalid round.");

        // Check user has participated before
        require(isParticipated[user], "User needs to participate first.");

        Participation storage p = userToParticipation[user];
        require(!p.isParticipationBoosted, "Participation already boosted.");
        // Mark participation as boosted
        p.isParticipationBoosted = true;

        // Compute the amount of tokens user is buying
        uint256 amountOfTokensBuying =
            (msg.value).mul(uint(10) ** IERC20Metadata(address(sale.token)).decimals()).div(sale.tokenPriceInAVAX);

        require(amountOfTokensBuying <= amount, "Exceeding allowance.");

        // Require that amountOfTokensBuying is less than sale token leftover cap
        require(
            amountOfTokensBuying <= sale.amountOfTokensToSell.sub(sale.totalTokensSold),
            "Not enough tokens to sell."
        );

        require(
            amountOfTokensBuying <= roundIdToRound[boosterRoundId].maxParticipation,
            "Crossing max participation."
        );

        // Add msg.value to boosted avax paid
        p.boostedAmountAVAXPaid = msg.value;
        // Add amountOfTokensBuying as boostedAmount
        p.boostedAmountBought = amountOfTokensBuying;

        // Increase total amount avax paid
        p.amountAVAXPaid = p.amountAVAXPaid.add(msg.value);
        // Increase total amount of tokens bought
        p.amountBought = p.amountBought.add(amountOfTokensBuying);

        // Increase amount of sold tokens
        sale.totalTokensSold = sale.totalTokensSold.add(amountOfTokensBuying);

        // Increase amount of AVAX raised
        sale.totalAVAXRaised = sale.totalAVAXRaised.add(msg.value);

        // Burn / Redistribute XAVA from this user.
        allocationStakingContract.redistributeXava(
            0,
            user,
            amountXavaToBurn
        );

        // Emit participation boosted event
        emit ParticipationBoosted(user, p.boostedAmountAVAXPaid, p.boostedAmountBought);
    }

    // Expose function where user can withdraw multiple unlocked portions at once.
    function withdrawMultiplePortions(uint256 [] calldata portionIds) external {
        uint256 totalToWithdraw = 0;

        // Retrieve participation from storage
        Participation storage p = userToParticipation[msg.sender];

        for(uint i=0; i < portionIds.length; i++) {
            uint256 portionId = portionIds[i];
            require(portionId < vestingPercentPerPortion.length);

            if (
                !p.isPortionWithdrawn[portionId] &&
                vestingPortionsUnlockTime[portionId] <= block.timestamp
            ) {
                // Mark participation as withdrawn
                p.isPortionWithdrawn[portionId] = true;
                // Compute amount withdrawing
                uint256 amountWithdrawing = p
                    .amountBought
                    .mul(vestingPercentPerPortion[portionId])
                    .div(portionVestingPrecision);
                // Withdraw percent which is unlocked at that portion
                totalToWithdraw = totalToWithdraw.add(amountWithdrawing);
            }
        }

        if(totalToWithdraw > 0) {
            // Transfer tokens to user
            sale.token.safeTransfer(msg.sender, totalToWithdraw);
            // Trigger an event
            emit TokensWithdrawn(msg.sender, totalToWithdraw);
        }
    }

    /// Expose function where user can withdraw multiple unlocked portions to Dexalot Portfolio at once
    /// @dev first portion can be deposited before it's unlocking time, while others can only after
    function withdrawMultiplePortionsToDexalot(uint256 [] calldata portionIds) external {

        // Security check
        performDexalotChecks();

        uint256 totalToWithdraw = 0;

        // Retrieve participation from storage
        Participation storage p = userToParticipation[msg.sender];

        for(uint i=0; i < portionIds.length; i++) {
            uint256 portionId = portionIds[i];
            require(portionId < vestingPercentPerPortion.length);

            bool eligible;

            if(!p.isPortionWithdrawn[portionId]) {
                if(portionId > 0) {
                    if(vestingPortionsUnlockTime[portionId] <= block.timestamp) {
                        eligible = true;
                    }
                } else { // if portion id == 0
                    eligible = true;
                } // modifier checks for portionId == 0 case
            }

            if(eligible) {
                // Mark participation as withdrawn
                p.isPortionWithdrawn[portionId] = true;
                // Mark portion as withdrawn to dexalot
                p.isPortionWithdrawnToDexalot[portionId] = true;
                // Compute amount withdrawing
                uint256 amountWithdrawing = p
                    .amountBought
                    .mul(vestingPercentPerPortion[portionId])
                    .div(portionVestingPrecision);
                // Withdraw percent which is unlocked at that portion
                totalToWithdraw = totalToWithdraw.add(amountWithdrawing);
            }
        }

        if(totalToWithdraw > 0) {
            // Transfer tokens to user's wallet prior to dexalot deposit
            sale.token.safeTransfer(msg.sender, totalToWithdraw);

            // Deposit tokens to dexalot contract - Withdraw from sale contract
            dexalotPortfolio.depositTokenFromContract(
                msg.sender, getTokenSymbolBytes32(), totalToWithdraw
            );

            // Trigger an event
            emit TokensWithdrawnToDexalot(msg.sender, totalToWithdraw);
        }
    }

    // Internal function to handle safe transfer
    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
    }

    /// Function to withdraw all the earnings and the leftover of the sale contract.
    function withdrawEarningsAndLeftover() external onlySaleOwner {
        withdrawEarningsInternal();
        withdrawLeftoverInternal();
    }

    // Function to withdraw only earnings
    function withdrawEarnings() external onlySaleOwner {
        withdrawEarningsInternal();
    }

    // Function to withdraw only leftover
    function withdrawLeftover() external onlySaleOwner {
        withdrawLeftoverInternal();
    }

    // Function to withdraw earnings
    function withdrawEarningsInternal() internal  {
        // Make sure sale ended
        require(block.timestamp >= sale.saleEnd);

        // Make sure owner can't withdraw twice
        require(!sale.earningsWithdrawn);
        sale.earningsWithdrawn = true;
        // Earnings amount of the owner in AVAX
        uint256 totalProfit = sale.totalAVAXRaised;

        safeTransferAVAX(msg.sender, totalProfit);
    }

    // Function to withdraw leftover
    function withdrawLeftoverInternal() internal {
        // Make sure sale ended
        require(block.timestamp >= sale.saleEnd);

        // Make sure owner can't withdraw twice
        require(!sale.leftoverWithdrawn);
        sale.leftoverWithdrawn = true;

        // Amount of tokens which are not sold
        uint256 leftover = sale.amountOfTokensToSell.sub(sale.totalTokensSold);

        if (leftover > 0) {
            sale.token.safeTransfer(msg.sender, leftover);
        }
    }

    // Function after sale for admin to withdraw registration fees if there are any left.
    function withdrawRegistrationFees() external onlyAdmin {
        require(block.timestamp >= sale.saleEnd, "Require that sale has ended.");
        require(registrationFees > 0, "No earnings from registration fees.");

        // Transfer AVAX to the admin wallet.
        safeTransferAVAX(msg.sender, registrationFees);
        // Set registration fees to be 0
        registrationFees = 0;
    }

    // Function where admin can withdraw all unused funds.
    function withdrawUnusedFunds() external onlyAdmin {
        uint256 balanceAVAX = address(this).balance;

        uint256 totalReservedForRaise = sale.earningsWithdrawn ? 0 : sale.totalAVAXRaised;

        safeTransferAVAX(
            msg.sender,
            balanceAVAX.sub(totalReservedForRaise.add(registrationFees))
        );
    }

    /// @notice     Get current round in progress.
    ///             If 0 is returned, means sale didn't start or it's ended.
    function getCurrentRound() public view returns (uint256) {
        uint256 i = 0;
        if (block.timestamp < roundIdToRound[roundIds[0]].startTime) {
            return 0; // Sale didn't start yet.
        }

        while (
            (i + 1) < roundIds.length &&
            block.timestamp > roundIdToRound[roundIds[i + 1]].startTime
        ) {
            i++;
        }

        if (block.timestamp >= sale.saleEnd) {
            return 0; // Means sale is ended
        }

        return roundIds[i];
    }

    /// @notice     Check signature user submits for registration.
    /// @param      signature is the message signed by the trusted entity (backend)
    /// @param      user is the address of user which is registering for sale
    /// @param      roundId is the round for which user is submitting registration
    function checkRegistrationSignature(
        bytes memory signature,
        uint256 signatureExpirationTimestamp,
        address user,
        uint256 roundId
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(signatureExpirationTimestamp, user, roundId, address(this))
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return admin.isAdmin(messageHash.recover(signature));
    }

    /// @notice     Check who signed the message
    /// @param      signature is the message allowing user to participate in sale
    /// @param      user is the address of user for which we're signing the message
    /// @param      amount is the maximal amount of tokens user can buy
    /// @param      roundId is the Id of the round user is participating.
    function checkParticipationSignature(
        bytes memory signature,
        address user,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                user,
                amount,
                amountXavaToBurn,
                roundId,
                address(this)
            )
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return admin.isAdmin(messageHash.recover(signature));
    }

    /// @notice     Function to get participation for passed user address
    function getParticipation(address _user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool[] memory,
            bool[] memory,
            bool,
            uint256,
            uint256
        )
    {
        Participation memory p = userToParticipation[_user];
        return (
            p.amountBought,
            p.amountAVAXPaid,
            p.timeParticipated,
            p.roundId,
            p.isPortionWithdrawn,
            p.isPortionWithdrawnToDexalot,
            p.isParticipationBoosted,
            p.boostedAmountBought,
            p.boostedAmountAVAXPaid
        );
    }

    /// @notice     Function to get number of registered users for sale
    function getNumberOfRegisteredUsers() external view returns (uint256) {
        return registration.numberOfRegistrants;
    }

    /// @notice     Function to get all info about vesting.
    function getVestingInfo()
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        return (vestingPortionsUnlockTime, vestingPercentPerPortion);
    }

    /// @notice     Function to remove stuck tokens from sale contract
    function removeStuckTokens(
        address token,
        address beneficiary
    )
        external
        onlyAdmin
    {
        // Require that token address does not match with sale token
        require(token != address(sale.token), "Can't withdraw sale token.");
        // Safe transfer token from sale contract to beneficiary
        IERC20(token).safeTransfer(beneficiary, IERC20(token).balanceOf(address(this)));
    }

    /// @notice     Function to set params for updatePriceInAVAX function
    function setUpdateTokenPriceInAVAXParams(
        uint8 _updateTokenPriceInAVAXPercentageThreshold,
        uint256 _updateTokenPriceInAVAXTimeLimit
    )
        external
        onlyAdmin
        onlyIfGateOpen
    {
        // Require that arguments don't equal zero
        require(
            _updateTokenPriceInAVAXTimeLimit != 0 && _updateTokenPriceInAVAXPercentageThreshold != 0,
            "Can't set zero value."
        );
        // Require that percentage threshold is less or equal 100%
        require(
            _updateTokenPriceInAVAXPercentageThreshold <= 100,
            "Threshold can't be higher than 100%."
        );
        // Set new values
        updateTokenPriceInAVAXPercentageThreshold = _updateTokenPriceInAVAXPercentageThreshold;
        updateTokenPriceInAVAXTimeLimit = _updateTokenPriceInAVAXTimeLimit;
    }

    /// @notice     Function to secure dexalot portfolio interactions
    function performDexalotChecks() internal view {
        require(
            supportsDexalotWithdraw,
            "Dexalot Portfolio not supported."
        );
        require(
            block.timestamp >= dexalotUnlockTime,
            "Dexalot Portfolio not unlocked."
        );
    }

    /// @notice     Function to get sale.token symbol and parse as bytes32
    function getTokenSymbolBytes32() internal view returns (bytes32 _symbol) {
        // get token symbol as string memory
        string memory symbol = IERC20Metadata(address(sale.token)).symbol();
        // parse token symbol to bytes32 format - to fit dexalot function interface
        assembly {
            _symbol := mload(add(symbol, 32))
        }
    }

    /// @notice     Function close setter gate after all params are set
    function closeGate() external onlyAdmin onlyIfGateOpen {
        // Require that sale is created
        require(sale.isCreated, "Sale not created.");
        // Require that sale token is set
        require(address(sale.token) != address(0), "Token not set.");
        // Require that tokens were deposited
        require(sale.tokensDeposited, "Tokens not deposited.");
        // Require that token price updating params are set
        require(
            updateTokenPriceInAVAXPercentageThreshold != 0 && updateTokenPriceInAVAXTimeLimit != 0,
            "Params for updating AVAX price not set."
        );
        // Require that registration times are set
        require(
            registration.registrationTimeStarts != 0 && registration.registrationTimeEnds != 0,
            "Registration params not set."
        );

        // Close the gate
        gateClosed = true;
        emit GateClosed(block.timestamp);
    }

    // Function to act as a fallback and handle receiving AVAX.
    receive() external payable {}
}