/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-10
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
    function depositCollateral() external payable;
    function withdrawCollateral() external payable;
    function totalBalance() external view returns (uint256);
}


// File contracts/interfaces/IAvalaunchMarketplace.sol

pragma solidity ^0.6.12;

interface IAvalaunchMarketplace {
    function listPortions(address owner, uint256[] calldata portions, uint256[] calldata prices) external;
    function removePortions(address owner, uint256[] calldata portions) external;
    function approveSale(address sale) external;
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


// File contracts/sales/AvalaunchSaleV2.sol

pragma solidity 0.6.12;










contract AvalaunchSaleV2 is Initializable {

    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using SafeMath for uint256;

    // Pointer allocation staking contract
    IAllocationStaking public allocationStaking;
    // Pointer to sales factory contract
    ISalesFactory public factory;
    // Pointer to admin contract
    IAdmin public admin;
    // Pointer to collateral contract
    ICollateral public collateral;
    // Pointer to marketplace contract
    IAvalaunchMarketplace public marketplace;
    // Pointer to dexalot portfolio contract
    IDexalotPortfolio public dexalotPortfolio;
    // Official sale mod
    address public moderator;

    // Sale Phases
    enum Phases { Idle, Registration, Validator, Staking, Booster }
    // Portion States
    enum PortionStates { Available, Withdrawn, WithdrawnToDexalot, OnMarket, Sold }

    struct Sale {
        IERC20 token;                        // Official sale token
        Phases phase;                        // Current phase of sale
        bool isCreated;                      // Sale creation marker
        bool earningsWithdrawn;              // Earnings withdrawal marker
        bool leftoverWithdrawn;              // Leftover withdrawal marker
        bool tokensDeposited;                // Token deposit marker
        uint256 tokenPriceInAVAX;            // Sale token's price in AVAX
        uint256 amountOfTokensToSell;        // Amount of tokens to sell
        uint256 totalTokensSold;             // Amount of sold tokens
        uint256 totalAVAXRaised;             // Total AVAX amount raised
        uint256 saleEnd;                     // Sale end timestamp
    }

    struct Participation {
        uint256 amountBought;                // Amount of tokens bought
        uint256 amountAVAXPaid;              // Amount of $AVAX paid for tokens
        uint256 timeParticipated;            // Timestamp of participation time
        uint256 phaseId;                     // Phase user is registered for
        uint256[] portionAmounts;            // Amount of tokens for each portion
        PortionStates[] portionStates;       // State of each portion
        uint256 boostedAmountAVAXPaid;       // Amount of $AVAX paid for boost
        uint256 boostedAmountBought;         // Amount of tokens bought with boost
    }

    // Sale state structure
    Sale public sale;
    // Mapping user to his participation
    mapping(address => Participation) public userToParticipation;
    // User to phase for which he registered
    mapping(address => uint256) public addressToPhaseRegisteredFor;
    // Mapping if user is participated or not
    mapping(address => bool) public isParticipated;
    // Number of sale registrants
    uint256 public numberOfRegistrants;
    // Times when portions are getting unlocked
    uint256[] public vestingPortionsUnlockTime;
    // Percent of the participation user can withdraw
    uint256[] public vestingPercentPerPortion;
    // Number of users participated in the sale
    uint256 public numberOfParticipants;
    // Number of vested token portions
    uint256 public numberOfVestedPortions;
    // Precision for percent for portion vesting
    uint256 public portionVestingPrecision;
    // Registration deposit AVAX, deposited during the registration, returned after the participation.
    uint256 public registrationDepositAVAX;
    // Accounting total AVAX collected, after sale end admin can withdraw this
    uint256 public registrationFees;
    // Timestamp of sale.tokenPriceInAvax latest update
    uint256 public lastPriceUpdateTimestamp;
    // First vested portion's Dexalot unlock timestamp
    uint256 public dexalotUnlockTime;
    // Sale setter lock flag
    bool public isLockOn;

    // Empty global arrays for cheaper participation initialization
    PortionStates[] private _emptyPortionStates;
    uint256[] private _emptyUint256;

    // Events
    event SaleCreated(uint256 tokenPriceInAVAX, uint256 amountOfTokensToSell, uint256 saleEnd);
    event TokensSold(address user, uint256 amount);
    event UserRegistered(address user, uint256 phaseId);
    event NewTokenPriceSet(uint256 newPrice);
    event RegistrationAVAXRefunded(address user, uint256 amountRefunded);
    event TokensWithdrawn(address user, uint256 amount);
    event TokensWithdrawnToDexalot(address user, uint256 amount);
    event LockActivated(uint256 time);
    event ParticipationBoosted(address user, uint256 amountAVAX, uint256 amountTokens);
    event PhaseChanged(Phases phase);

    // Restricting calls only to moderator
    modifier onlyModerator() {
        require(msg.sender == moderator, "Only moderator.");
        _;
    }

    // Restricting calls only to sale admin
    modifier onlyAdmin() {
        require(admin.isAdmin(msg.sender), "Only admin.");
        _;
    }

    // Restricting calls only to collateral contract
    modifier onlyCollateral() {
        require(msg.sender == address(collateral), "Only collateral.");
        _;
    }

    // Restricting setter calls after gate closing
    modifier ifUnlocked() {
        require(!isLockOn, "Lock active.");
        _;
    }

    function initialize(
        address _admin,
        address _allocationStaking,
        address _collateral,
        address _marketplace,
        address _moderator
    ) external initializer {
        require(_admin != address(0));
        require(_allocationStaking != address(0));
        require(_collateral != address(0));
        require(_marketplace != address(0));
        require(_moderator != address(0));

        factory = ISalesFactory(msg.sender);
        admin = IAdmin(_admin);
        allocationStaking = IAllocationStaking(_allocationStaking);
        collateral = ICollateral(_collateral);
        marketplace = IAvalaunchMarketplace(_marketplace);
        moderator = _moderator;
    }

    /**
     * @notice Function to set vesting params
     * @param _unlockingTimes is array of unlock times for each portion
     * @param _percents are percents of purchased tokens that are distributed among portions
     */
    function setVestingParams(
        uint256[] calldata _unlockingTimes,
        uint256[] calldata _percents
    )
    external
    onlyAdmin
    {
        require(_unlockingTimes.length == _percents.length);
        require(vestingPercentPerPortion.length == 0 && vestingPortionsUnlockTime.length == 0, "Already set.");
        require(portionVestingPrecision != 0, "Sale params not set.");

        // Set number of vested portions
        numberOfVestedPortions = _unlockingTimes.length;
        // Create empty arrays with slot number of numberOfVestedPortions
        _emptyPortionStates = new PortionStates[](numberOfVestedPortions);
        _emptyUint256 = new uint256[](numberOfVestedPortions);

        // Require that locking times are later than sale end
        require(_unlockingTimes[0] > sale.saleEnd, "Invalid first unlock time.");
        // Use precision to make sure percents of portions align
        uint256 precision = portionVestingPrecision;
        // Set vesting portions percents and unlock times
        for (uint256 i = 0; i < numberOfVestedPortions; i++) {
            if (i > 0) {
                // Each portion unlock time must be latter than previous
                require(_unlockingTimes[i] > _unlockingTimes[i-1], "Invalid unlock time.");
            }
            vestingPortionsUnlockTime.push(_unlockingTimes[i]);
            vestingPercentPerPortion.push(_percents[i]);
            precision = precision.sub(_percents[i]);
        }
        require(precision == 0, "Invalid percentage calculation.");
    }

    /**
     * @notice Function to shift vested portion unlock times by admin
     * @param timeToShift is amount of time to add to all portion unlock times
     */
    function shiftVestingUnlockTimes(uint256 timeToShift) external onlyAdmin {
        require(timeToShift > 0, "Invalid shift time.");
        bool movable;
        // Shift the unlock time for each portion
        for (uint256 i = 0; i < numberOfVestedPortions; i++) {
            // Shift only portions that time didn't reach yet
            if (!movable && block.timestamp < vestingPortionsUnlockTime[i]) movable = true;
            // Each portion is after the previous so once movable flag is active all latter portions may be shifted
            if (movable) vestingPortionsUnlockTime[i] = vestingPortionsUnlockTime[i].add(timeToShift);
        }
    }

    /**
     * @notice Function to set fundamental sale parameters
     * @param _token is official sale token, may be set asynchronously too
     * @param _tokenPriceInAVAX is token price in $AVAX, dynamically set by admin every 'n' minutes
     * @param _amountOfTokensToSell is amount of tokens that will be deposited to sale contract and available to buy
     * @param _saleEnd is timestamp of sale end
     * @param _portionVestingPrecision is precision rate for vested portion percents
     */
    function setSaleParams(
        address _token,
        uint256 _tokenPriceInAVAX,
        uint256 _amountOfTokensToSell,
        uint256 _saleEnd,
        uint256 _portionVestingPrecision,
        uint256 _registrationDepositAVAX
    )
    external
    onlyAdmin
    {
        require(!sale.isCreated, "Sale already created.");
        require(_portionVestingPrecision >= 100, "Invalid vesting precision.");
        require(
            _tokenPriceInAVAX != 0 && _amountOfTokensToSell != 0 && _saleEnd > block.timestamp,
            "Invalid input."
        );

        // Set sale params
        sale.isCreated = true;
        sale.token = IERC20(_token);
        sale.tokenPriceInAVAX = _tokenPriceInAVAX;
        sale.amountOfTokensToSell = _amountOfTokensToSell;
        sale.saleEnd = _saleEnd;

        // Set portion vesting precision
        portionVestingPrecision = _portionVestingPrecision;
        registrationDepositAVAX = _registrationDepositAVAX;

        // Emit event
        emit SaleCreated(
            sale.tokenPriceInAVAX,
            sale.amountOfTokensToSell,
            sale.saleEnd
        );
    }

    /**
     * @notice Function to shift sale end timestamp
     */
    function shiftSaleEnd(uint256 timeToShift) external onlyAdmin {
        sale.saleEnd = sale.saleEnd.add(timeToShift);
    }

    /**
     * @notice Function to set Dexalot parameters
     * @param _dexalotPortfolio is official Dexalot Portfolio contract address
     * @param _dexalotUnlockTime is unlock time for first portion withdrawal to Dexalot Portfolio
     * @dev Optional feature to enable user portion withdrawals directly to Dexalot Portfolio
     */
    function setDexalotParameters(
        address _dexalotPortfolio,
        uint256 _dexalotUnlockTime
    )
    external
    onlyAdmin
    ifUnlocked
    {
        require(_dexalotPortfolio != address(0) && _dexalotUnlockTime >= sale.saleEnd);
        dexalotPortfolio = IDexalotPortfolio(_dexalotPortfolio);
        dexalotUnlockTime = _dexalotUnlockTime;
    }

    /**
     * @notice Function to shift dexalot unlocking time
     */
    function shiftDexalotUnlockTime(uint256 timeToShift) external onlyAdmin {
        dexalotUnlockTime = dexalotUnlockTime.add(timeToShift);
    }

    /**
     * @notice Function to retroactively set sale token address
     * @param saleToken is official token of the project
     * @dev Retroactive calls are option for teams which do not have token at the moment of sale launch
     */
    function setSaleToken(
        address saleToken
    )
    external
    onlyAdmin
    ifUnlocked
    {
        require(address(saleToken) != address(0));
        sale.token = IERC20(saleToken);
    }

    /**
     * @notice Function to register for the upcoming sale
     * @param signature is pass for sale registration provided by admins
     * @param signatureExpirationTimestamp is timestamp after which signature is no longer valid
     * @param phaseId is id of phase user is registering for
     */
    function registerForSale(
        bytes memory signature,
        uint256 signatureExpirationTimestamp,
        uint256 phaseId
    )
    external
    payable
    {
        // Sale registration validity checks
        require(msg.value == registrationDepositAVAX, "Invalid deposit amount.");
        // Register only for validator or staking phase
        require(phaseId > uint8(Phases.Registration) && phaseId < uint8(Phases.Booster), "Invalid phase id.");
        require(sale.phase == Phases.Registration, "Must be called during registration phase.");
        require(block.timestamp <= signatureExpirationTimestamp, "Signature expired.");
        require(addressToPhaseRegisteredFor[msg.sender] == 0, "Already registered.");

        // Make sure signature is signed by admin, with proper parameters
        checkSignatureValidity(
            keccak256(abi.encodePacked(signatureExpirationTimestamp, msg.sender, phaseId, address(this))),
            signature
        );

        // Set user's registration phase
        addressToPhaseRegisteredFor[msg.sender] = phaseId;

        // Locking tokens for participants of staking phase until the sale ends
        if (phaseId == uint8(Phases.Staking)) {
            allocationStaking.setTokensUnlockTime(
                0,
                msg.sender,
                sale.saleEnd
            );
        }
        // Increment number of registered users
        numberOfRegistrants++;
        // Increase earnings from registration fees
        registrationFees += msg.value;
        // Emit event
        emit UserRegistered(msg.sender, phaseId);
    }

    /**
     * @notice Function to update token price in $AVAX to match real time value of token
     * @param price is token price in $AVAX to be set
     * @dev To help us reduce reliance on $AVAX volatility, oracle will update price during sale every 'n' minutes (n>=5)
     */
    function updateTokenPriceInAVAX(uint256 price) external onlyAdmin {
        // Compute 30% of the current token price
        uint256 thirtyPercent = sale.tokenPriceInAVAX.mul(30).div(100);
        // Require that new price is under 30% difference compared to current
        require(
            sale.tokenPriceInAVAX.add(thirtyPercent) > price && sale.tokenPriceInAVAX - thirtyPercent < price,
            "Price out of range."
        );
        require(lastPriceUpdateTimestamp + 5 minutes < block.timestamp);
        // Set new token price via internal call
        _setNewTokenPrice(price);
    }

    /**
     * @notice Function to set new token price by admin
     * @dev Works only until setter lock becomes active
     */
    function overrideTokenPrice(uint256 price) external onlyAdmin ifUnlocked {
        // Set new token price via internal call
        _setNewTokenPrice(price);
    }

    /**
     * @notice Function for internal set of token price in $AVAX
     */
    function _setNewTokenPrice(uint256 price) internal {
        // Update parameters
        sale.tokenPriceInAVAX = price;
        lastPriceUpdateTimestamp = block.timestamp;
        // Emit event
        emit NewTokenPriceSet(price);
    }

    /**
     * @notice Function to deposit sale tokens
     * @dev Only sale moderator may deposit
     */
    function depositTokens() external onlyModerator ifUnlocked {
        // Require that setSaleParams was called
        require(sale.isCreated && address(sale.token) != address(0));

        // Mark that tokens are deposited
        sale.tokensDeposited = true;

        // Perform safe transfer
        sale.token.safeTransferFrom(
            msg.sender,
            address(this),
            sale.amountOfTokensToSell
        );
    }

    /**
     * @notice Function to auto-participate for user via collateral
     */
    function autoParticipate(
        address user,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 phaseId
    ) external payable onlyCollateral {
        _participate(user, amount, amountXavaToBurn, phaseId);
    }

    /**
     * @notice Function to boost user's participation via collateral
     */
    function boostParticipation(
        address user,
        uint256 amountXavaToBurn
    ) external payable onlyCollateral {
        _participate(user, 0, amountXavaToBurn, uint256(Phases.Booster));
    }

    /**
     * @notice Function to participate in sale manually
     */
    function participate(
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 phaseId,
        bytes calldata signature
    ) external payable {
        require(msg.sender == tx.origin, "Only direct calls.");
        // Make sure admin signature is valid
        checkSignatureValidity(
            keccak256(abi.encodePacked(msg.sender, amount, amountXavaToBurn, phaseId, address(this))),
            signature
        );
        _participate(msg.sender, amount, amountXavaToBurn, phaseId);
    }

    /**
     * @notice Function to participate in sale with multiple variants
     * @param user is user who participates in a sale
     * @param amount is maximal amount of tokens allowed for user to buy
     * @param amountXavaToBurn is amount of xava to be burned from user's stake
     * @param phaseId is round phase id user registered for (Validator, Staking or Booster)
     * @dev Regular participation by direct call is considered usual flow and it is applicable on 2 rounds - Validator and Staking
     * * Main diff is that on Staking round participation user's $XAVA is getting burned in small amount
     * * These rounds can be participated automatically too if user signs up for it and deposits $AVAX to Collateral contract
     * * Collateral contract will be performing automatic participations for users who signed up
     * * Booster round is 3rd one, available only for users who participated in one of first 2 rounds
     * * In booster round, it is possible to participate only through collateral, on user's demand
     * * This function is checking for different cases based on round type (isBooster) and caller (isCollateralCaller)
     */
    function _participate(
        address user,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 phaseId
    ) internal {
        // Make sure selected phase is ongoing and is round phase (Validator, Staking, Booster)
        require(phaseId > 1 && phaseId == uint8(sale.phase), "Invalid phase.");

        bool isCollateralCaller = msg.sender == address(collateral);
        bool isBooster = phaseId == uint8(Phases.Booster);

        if (!isBooster) { // Normal flow
            // User must have registered for the phase in advance
            require(addressToPhaseRegisteredFor[user] == phaseId, "Not registered for this phase.");
            // Check user haven't participated before
            require(!isParticipated[user], "Already participated.");
        } else { // Booster flow
            // Check user has participated before
            require(isParticipated[user], "Only participated users.");
        }

        // Compute the amount of tokens user is buying
        uint256 amountOfTokensBuying =
            (msg.value).mul(uint(10) ** IERC20Metadata(address(sale.token)).decimals()).div(sale.tokenPriceInAVAX);

        if (!isCollateralCaller) { // Non-collateral flow
            // Must buy more than 0 tokens
            require(amountOfTokensBuying > 0, "Can't buy 0 tokens.");
            // Check in terms of user allo
            require(amountOfTokensBuying <= amount, "Exceeding allowance.");
        }

        // Require that amountOfTokensBuying is less than sale token leftover cap
        require(amountOfTokensBuying <= sale.amountOfTokensToSell.sub(sale.totalTokensSold), "Out of tokens.");
        // Increase amount of sold tokens
        sale.totalTokensSold = sale.totalTokensSold.add(amountOfTokensBuying);
        // Increase amount of AVAX raised
        sale.totalAVAXRaised = sale.totalAVAXRaised.add(msg.value);

        Participation storage p = userToParticipation[user];
        if (!isBooster) { // Normal flow
            // Initialize user's participation
            _initParticipationForUser(user, amountOfTokensBuying, msg.value, block.timestamp, phaseId);
        } else { // Booster flow
            // Check that user already participated
            require(p.boostedAmountBought == 0, "Already boosted.");
        }

        if (phaseId == uint8(Phases.Staking) || isBooster) {
            // Burn XAVA from user
            allocationStaking.redistributeXava(
                0,
                user,
                amountXavaToBurn
            );
        }

        uint256 lastPercent; uint256 lastAmount;
        // Compute portion amounts
        for(uint256 i = 0; i < numberOfVestedPortions; i++) {
            if (lastPercent != vestingPercentPerPortion[i]) {
                lastPercent = vestingPercentPerPortion[i];
                lastAmount = amountOfTokensBuying.mul(lastPercent).div(portionVestingPrecision);
            }
            p.portionAmounts[i] += lastAmount;
        }

        if (!isBooster) { // Normal flow
            // Mark user is participated
            isParticipated[user] = true;
            // Increment number of participants in the Sale
            numberOfParticipants++;
            // Decrease of available registration fees
            registrationFees = registrationFees.sub(registrationDepositAVAX);
            // Transfer registration deposit amount in AVAX back to the users
            sale.token.safeTransfer(user, registrationDepositAVAX);
            // Trigger events
            emit RegistrationAVAXRefunded(user, registrationDepositAVAX);
            emit TokensSold(user, amountOfTokensBuying);
        } else { // Booster flow
            // Add msg.value to boosted avax paid
            p.boostedAmountAVAXPaid = msg.value;
            // Add amountOfTokensBuying as boostedAmount
            p.boostedAmountBought = amountOfTokensBuying;
            // Emit participation boosted event
            emit ParticipationBoosted(user, msg.value, amountOfTokensBuying);
        }
    }

    /**
     * @notice Function to withdraw unlocked portions to wallet or Dexalot portfolio
     * @dev This function will deal with specific flow differences on withdrawals to wallet or dexalot
     * * First portion has different unlocking time for regular and dexalot withdraw
     */
    function withdrawMultiplePortions(uint256[] calldata portionIds, bool toDexalot) external {

        if (toDexalot) {
            require(address(dexalotPortfolio) != address(0) && dexalotUnlockTime != 0, "Dexalot withdraw not supported.");
            // Means first portion is unlocked for dexalot
            require(block.timestamp >= dexalotUnlockTime, "Dexalot withdraw locked.");
        }

        uint256 totalToWithdraw = 0;

        // Retrieve participation from storage
        Participation storage p = userToParticipation[msg.sender];

        for (uint256 i = 0; i < portionIds.length; i++) {
            uint256 portionId = portionIds[i];
            require(portionId < numberOfVestedPortions, "Invalid portion id.");

            bool eligible;
            if (
                p.portionStates[portionId] == PortionStates.Available && p.portionAmounts[portionId] > 0 && (
                    vestingPortionsUnlockTime[portionId] <= block.timestamp || (portionId == 0 && toDexalot)
                )
            ) eligible = true;

            if (eligible) {
                // Mark portion as withdrawn to dexalot
                if (!toDexalot) p.portionStates[portionId] = PortionStates.Withdrawn;
                else p.portionStates[portionId] = PortionStates.WithdrawnToDexalot;

                // Compute amount withdrawing
                uint256 amountWithdrawing = p
                    .amountBought
                    .mul(vestingPercentPerPortion[portionId])
                    .div(portionVestingPrecision);
                // Withdraw percent which is unlocked at that portion
                totalToWithdraw = totalToWithdraw.add(amountWithdrawing);
            }
        }

        if (totalToWithdraw > 0) {
            // Transfer tokens to user
            sale.token.safeTransfer(msg.sender, totalToWithdraw);
            // Trigger an event
            emit TokensWithdrawn(msg.sender, totalToWithdraw);
            // For Dexalot withdraw approval must be made through fe
            if (toDexalot) {
                // Deposit tokens to dexalot contract - Withdraw from sale contract
                dexalotPortfolio.depositTokenFromContract(
                    msg.sender, getTokenSymbolBytes32(), totalToWithdraw
                );
                // Trigger an event
                emit TokensWithdrawnToDexalot(msg.sender, totalToWithdraw);
            }
        }
    }

    /**
     * @notice Function to add available portions to market
     * @param portions are an array of portion ids
     * @param prices are an array of portion prices
     */
    function addPortionsToMarket(uint256[] calldata portions, uint256[] calldata prices) external {
        require(portions.length == prices.length);
        for(uint256 i = 0; i < portions.length; i++) {
            Participation storage p = userToParticipation[msg.sender];
            uint256 portionId = portions[i];
            require(
                p.portionStates[portionId] == PortionStates.Available && p.portionAmounts[portionId] > 0,
                "Portion unavailable."
            );
            p.portionStates[portionId] = PortionStates.OnMarket;
        }
        marketplace.listPortions(msg.sender, portions, prices);
    }

    /**
     * @notice Function to remove portions from market
     */
    function removePortionsFromMarket(uint256[] calldata portions) external {
        for(uint256 i = 0; i < portions.length; i++) {
            Participation storage p = userToParticipation[msg.sender];
            require(p.portionStates[portions[i]] == PortionStates.OnMarket, "Portion not on market.");
            p.portionStates[portions[i]] = PortionStates.Available;
        }
        marketplace.removePortions(msg.sender, portions);
    }

    /**
     * @notice Function to transfer portions from seller to buyer
     * @dev Called by marketplace only
     */
    function transferPortions(address seller, address buyer, uint256[] calldata portions) external {
        require(msg.sender == address(marketplace), "Marketplace only.");
        Participation storage pSeller = userToParticipation[seller];
        Participation storage pBuyer = userToParticipation[buyer];
        // Initialize portions for user if hasn't participated the sale
        if(pBuyer.amountBought == 0) {
            _initParticipationForUser(buyer, 0, 0, 0, 0);
        }
        for(uint256 i = 0; i < portions.length; i++) {
            uint256 portionId = portions[i];
            require(pSeller.portionStates[portionId] == PortionStates.OnMarket, "Portion unavailable.");
            pSeller.portionStates[portionId] = PortionStates.Sold;
            PortionStates portionState = pBuyer.portionStates[portionId];
            /* case 1: portion with same id is on market
               case 2: portion is available
               case 3: portion is unavailable (withdrawn or sold) */
            require(portionState != PortionStates.OnMarket, "Can't buy portion with same id you listed on market.");
            if (portionState == PortionStates.Available) {
                pBuyer.portionAmounts[portionId] += pSeller.portionAmounts[portionId];
            } else {
                pBuyer.portionAmounts[portionId] = pSeller.portionAmounts[portionId];
                pBuyer.portionStates[portionId] = PortionStates.Available;
            }
        }
    }

    /**
     * @notice External function to withdraw earnings and/or leftover
     */
    function withdrawEarningsAndLeftover(bool earnings, bool leftover) external onlyModerator {
        // Make sure sale ended
        require(block.timestamp >= sale.saleEnd);
        // Perform withdrawals
        if (earnings) withdrawEarningsInternal();
        if (leftover) withdrawLeftoverInternal();
    }

    /**
     * @notice Internal function to withdraw earnings
     */
    function withdrawEarningsInternal() internal  {
        // Make sure moderator can't withdraw twice
        require(!sale.earningsWithdrawn);
        sale.earningsWithdrawn = true;
        // Earnings amount of the moderator in AVAX
        uint256 totalProfit = sale.totalAVAXRaised;
        // Perform AVAX safe transfer
        safeTransferAVAX(msg.sender, totalProfit);
    }

    /**
     * @notice Internal function to withdraw leftover
     */
    function withdrawLeftoverInternal() internal {
        // Make sure moderator can't withdraw twice
        require(!sale.leftoverWithdrawn);
        sale.leftoverWithdrawn = true;
        // Amount of tokens which are not sold
        uint256 leftover = sale.amountOfTokensToSell.sub(sale.totalTokensSold);
        if (leftover > 0) {
            sale.token.safeTransfer(msg.sender, leftover);
        }
    }

    /**
     * @notice Function to withdraw registration fees by admin
     * @dev only after sale has ended and there is fund leftover
     */
    function withdrawRegistrationFees() external onlyAdmin {
        require(block.timestamp >= sale.saleEnd, "Sale isn't over.");
        require(registrationFees > 0, "No fees accumulated.");
        // Transfer AVAX to the admin wallet
        safeTransferAVAX(msg.sender, registrationFees);
        // Set registration fees to zero
        registrationFees = 0;
    }

    /**
     * @notice Function to withdraw all unused funds by admin
     */
    function withdrawUnusedFunds() external onlyAdmin {
        uint256 balanceAVAX = address(this).balance;
        uint256 totalReservedForRaise = sale.earningsWithdrawn ? 0 : sale.totalAVAXRaised;
        // Transfer funds to admin wallet
        safeTransferAVAX(
            msg.sender,
            balanceAVAX.sub(totalReservedForRaise.add(registrationFees))
        );
    }

    /**
     * @notice Function to get participation for passed user address
     */
    function getParticipationAmountsAndStates(address user)
    external
    view
    returns (uint256[] memory, PortionStates[] memory) {
        Participation memory p = userToParticipation[user];
        return (
            p.portionAmounts,
            p.portionStates
        );
    }

    /**
     * @notice Function to get vesting info
     */
    function getVestingInfo() external view returns (uint256[] memory, uint256[] memory) {
        return (vestingPortionsUnlockTime, vestingPercentPerPortion);
    }

    /**
     * @notice Function to remove stuck tokens from contract
     */
    function removeStuckTokens(address token, address beneficiary, uint256 amount) external onlyAdmin {
        // Require that token address does not match with sale token
        require(token != address(sale.token));
        // Safe transfer token from sale contract to beneficiary
        IERC20(token).safeTransfer(beneficiary, amount);
    }

    /**
     * @notice Function to switch between sale phases by admin
     */
    function changePhase(Phases _phase) external onlyAdmin {
        // switch the currently active phase
        sale.phase = _phase;
        // Emit relevant event
        emit PhaseChanged(_phase);
    }

    /**
     * @notice Function which locks setters after initial configuration
     * @dev Contract lock can be activated only once and never unlocked
     */
    function activateLock() external onlyAdmin ifUnlocked {
        // Lock the setters
        isLockOn = true;
        // Emit relevant event
        emit LockActivated(block.timestamp);
    }

    /**
     * @notice function to initialize participation structure for user
     */
    function _initParticipationForUser(
        address user,
        uint256 amountBought,
        uint256 amountAVAXPaid,
        uint256 timeParticipated,
        uint256 phaseId
    ) internal {
        userToParticipation[user] = Participation({
            amountBought: amountBought,
            amountAVAXPaid: amountAVAXPaid,
            timeParticipated: timeParticipated,
            phaseId: phaseId,
            portionAmounts: _emptyUint256,
            portionStates: _emptyPortionStates,
            boostedAmountAVAXPaid: 0,
            boostedAmountBought: 0
        });
    }

    /**
     * @notice Function to verify admin signed signatures
     */
    function checkSignatureValidity(bytes32 hash, bytes memory signature) internal view {
        require(
            admin.isAdmin(hash.toEthSignedMessageHash().recover(signature)),
            "Invalid signature."
        );
    }

    /**
    * @notice Function to perform AVAX safe transfer
     */
    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
    }

    /**
     * @notice Function to parse token symbol as bytes32
     */
    function getTokenSymbolBytes32() internal view returns (bytes32 _symbol) {
        // Get token symbol
        string memory symbol = IERC20Metadata(address(sale.token)).symbol();
        // Parse token symbol to bytes32
        assembly {
            _symbol := mload(add(symbol, 32))
        }
    }

    /**
     * @notice Function to handle receiving AVAX
     */
    receive() external payable {}
}