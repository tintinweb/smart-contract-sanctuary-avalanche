/**
 *Submitted for verification at snowtrace.io on 2022-04-24
*/

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/*
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


// File @openzeppelin/contracts/access/[email protected]




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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]




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


// File @openzeppelin/contracts/utils/[email protected]




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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]





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


// File @openzeppelin/contracts/utils/cryptography/[email protected]




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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]




/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File contracts/external/IERC677Receiver.sol




/// @title Interface for ERC677 token receiver
interface IERC677Receiver {
    /// @dev Called by a token to indicate a transfer into the callee
    /// @param _from The account that has sent the token
    /// @param _amount The amount of tokens sent
    /// @param _data The extra data being passed to the receiving contract
    function onTokenTransfer(
        address _from,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bool success);
}


// File contracts/external/IWETH9.sol




/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Calling deposit with msg.value returns the token
    function deposit() external payable;

    /// @notice Calling withdraw returns eth to the caller
    function withdraw(uint256) external;
}


// File contracts/exchange41/interfaces/IAmm.sol



/// @title An interface for the internal AMM that trades with the users of an exchange.
///
/// @notice When a user trades on an exchange, the AMM will automatically take the opposite position, effectively
/// acting like a market maker in a traditional order book market.
///
/// An AMM can execute any hedging or arbitraging strategies internally. For example, it can trade with a spot market
/// such as Uniswap to hedge a position.
interface IAmm {
    /// @notice Takes a position in token1 against token0. Can only be called by the exchange to take the opposite
    /// position to a trader. The trade can fail for several different reasons: its hedging strategy failed, it has
    /// insufficient funds, out of gas, etc.
    ///
    /// @param _assetAmount The position to take in asset. Positive for long and negative for short.
    /// @param _oraclePrice The reference price for the trade.
    /// @param _isClosingTraderPosition Whether the trade is for closing a trader's position partially or fully.
    /// @return stableAmount The amount of stable amount received or paid.
    function trade(
        int256 _assetAmount,
        int256 _oraclePrice,
        bool _isClosingTraderPosition
    ) external returns (int256 stableAmount);

    /// @notice Returns the asset price that this AMM quotes for trading with it.
    /// @return assetPrice The asset price that this AMM quotes for trading with it
    function getAssetPrice() external view returns (int256 assetPrice);
}


// File contracts/exchange41/interfaces/IOracle.sol



/// @title An interface for interacting with oracles such as Chainlink, Uniswap V2/V3 TWAP, Band etc.
/// @notice This interface allows fetching prices for two tokens.
interface IOracle {
    /// @notice Address of the first token this oracle adapter supports.
    function token0() external view returns (address);

    /// @notice Address of the second token this oracle adapter supports.
    function token1() external view returns (address);

    /// @notice Returns the price of a supported token, relatively to the other token.
    function getPrice(address _token) external view returns (int256);
}


// File contracts/exchange41/interfaces/IExchangeLedger.sol




/// @title Futureswap V4.1 exchange for a single pair of tokens.
///
/// @notice An API for an exchange that manages leveraged trades for one pair of tokens.  One token
/// is called "asset" and it's address is returned by `assetToken()`. The other token is called
/// "stable" and it's address is returned by `stableToken()`.  Exchange is mostly symmetrical with
/// regard to how "asset" and "stable" are treated.
///
/// The exchange only deals with abstract accounting. It requires a trusted setup with a TokenRouter
/// to do actual transfers of ERC20's. The two basic operations are
///
///  - Trade: Implemented by `changePosition()`, requires collateral to be deposited by caller.
///  - Liquidation bot(s): Implemented by `liquidate()`.
///
interface IExchangeLedger {
    /// @notice Restricts exchange functionality.
    enum ExchangeState {
        // All functions are operational.
        NORMAL,
        // Only allow positions to be closed and liquidity removed.
        PAUSED,
        // No operations all allowed.
        STOPPED
    }

    /// @notice Emitted on all trades/liquidations containing all information of the update.
    /// @param cpd The `ChangePositionData` struct that contains all information collected.
    event PositionChanged(ChangePositionData cpd);

    /// @notice Emitted when exchange config is updated.
    event ExchangeConfigChanged(ExchangeConfig previousConfig, ExchangeConfig newConfig);

    /// @notice Emitted when the exchange state is updated.
    /// @param previousState the old state.
    /// @param previousPausePrice the oracle price the exchange is paused at.
    /// @param newState the new state.
    /// @param newPausePrice the new oracle price in case the exchange is paused.
    event ExchangeStateChanged(
        ExchangeState previousState,
        int256 previousPausePrice,
        ExchangeState newState,
        int256 newPausePrice
    );

    /// @notice Emitted when exchange hook is updated.
    event ExchangeHookAddressChanged(address previousHook, address newHook);

    /// @notice Emitted when AMM used by the exchange is updated.
    event AmmAddressChanged(address previousAmm, address newAmm);

    /// @notice Emitted when the TradeRouter authorized by the exchange is updated.
    event TradeRouterAddressChanged(address previousTradeRouter, address newTradeRouter);

    /// @notice Emitted when an ADL happens against the pool.
    /// @param deltaAsset How much asset transferred to pool.
    /// @param deltaStable How much stable transferred to pool.
    event AmmAdl(int256 deltaAsset, int256 deltaStable);

    /// @notice Emitted if the hook call fails.
    /// @param reason Revert reason.
    /// @param cpd The change position data of this trade.
    event OnChangePositionHookFailed(string reason, ChangePositionData cpd);

    /// @notice Emmitted when a tranche is ADL'd.
    /// @param tranche This risk tranche
    /// @param trancheIdx The id of the tranche that was ADL'd.
    /// @param assetADL Amount of asset ADL'd against this tranche.
    /// @param stableADL Amount of stable ADL'd againt this tranche.
    /// @param totalTrancheShares Total amount of shares in this tranche.
    event TrancheAutoDeleveraged(
        uint8 tranche,
        uint32 trancheIdx,
        int256 assetADL,
        int256 stableADL,
        int256 totalTrancheShares
    );

    /// @notice Represents a payout of `amount` with recipient `to`.
    struct Payout {
        address to;
        uint256 amount;
    }

    /// @dev Data tracked throughout changePosition and used in the `PositionChanged` event.
    struct ChangePositionData {
        // The address of the trader whose position is being changed.
        address trader;
        // The liquidator address is only non zero if this is a liquidation.
        address liquidator;
        // Whether or not this change is a request to close the trade.
        bool isClosing;
        // The change in asset that we are being asked to make to the position.
        int256 deltaAsset;
        // The change in stable that we are being asked to make to the position.
        int256 deltaStable;
        // A bound for the amount in stable paid / received for making the change.
        // Note: If this is set to zero no bounds are enforced.
        // Note: This is set to zero for liquidations.
        int256 stableBound;
        // Oracle price
        int256 oraclePrice;
        // Time used to compute funding.
        uint256 time;
        // Time fee charged.
        int256 timeFeeCharged;
        // Funding paid from longs to shorts (negative if other direction).
        int256 dfrCharged;
        // The amount of stable tokens being paid to liquidity providers as a trade fee.
        int256 tradeFee;
        // The amount of asset the position had before changing it.
        int256 startAsset;
        // The amount of stable the position had before changing it.
        int256 startStable;
        // The amount of asset the position had after changing it.
        int256 totalAsset;
        // The amount of stable the position had after changing it.
        int256 totalStable;
        // The amount of stable tokens being paid to the trader.
        int256 traderPayment;
        // The amount of stable tokens being paid to the liquidator.
        int256 liquidatorPayment;
        // The amount of stable tokens being paid to the treasury.
        int256 treasuryPayment;
        // The price at which the trade was executed.
        int256 executionPrice;
    }

    /// @dev Exchange config parameters
    struct ExchangeConfig {
        // The trade fee to be charged in percent for a trade range: [0, 1 ether]
        int256 tradeFeeFraction;
        // The time fee to be charged in percent for a trade range: [0, 1 ether]
        int256 timeFee;
        // The maximum leverage that the exchange allows before a trade becomes liquidatable, range: [0, 200 ether),
        // 0 (inclusive) to 200x leverage (exclusive)
        uint256 maxLeverage;
        // The minimum of collateral (stable token amount) a position needs to have. If a position falls below this
        // number it becomes liquidatable
        uint256 minCollateral;
        // The percentage of the trade fee being paid to the treasury, range: [0, 1 ether]
        int256 treasuryFraction;
        // A fee for imbalacing the exchange, range: [0, 1 ether].
        int256 dfrRate;
        // A fee that is paid to a liquidator for liquidating a trade expressed as percentage of remaining collateral,
        // range: [0, 1 ether]
        int256 liquidatorFrac;
        // A maximum amount of stable tokens that a liquidator can receive for a liquidation.
        int256 maxLiquidatorFee;
        // A fee that is paid to a liquidity providers if a trade gets liquidated expressed as percentage of
        // remaining collateral, range: [0, 1 ether]
        int256 poolLiquidationFrac;
        // A maximum amount of stable tokens that the liquidity providers can receive for a liquidation.
        int256 maxPoolLiquidationFee;
        // A fee that a trade experiences if its causing other trades to get ADL'ed, range: [0, 1 ether].
        int256 adlFeePercent;
    }

    /// @notice Returns the current state of the exchange. See description on ExchangeState for details.
    function exchangeState() external view returns (ExchangeState);

    /// @notice Returns the price that exchange was paused at.
    /// If the exchange got paused, this price overrides the oracle price for liquidations and liquidity
    /// providers redeeming their liquidity.
    function pausePrice() external view returns (int256);

    /// @notice Address of the amm this exchange calls to take the opposite of trades.
    function amm() external view returns (IAmm);

    /// @notice Changes a traders position in the exchange.
    /// @param deltaStable The amount of stable to change the position by.
    /// Positive values will add stable to the position (move stable token from the trader) into the exchange
    /// Negative values will remove stable from the position and send the trader tokens
    /// @param deltaAsset  The amount of asset the position should be changed by.
    /// @param stableBound The maximum/minimum amount of stable that the user is willing to pay/receive for the
    /// `deltaAsset` change.
    /// If the user is buying asset (deltaAsset > 0), the user will have to choose a maximum negative number that he is
    /// going to be in debt for.
    /// If the user is selling asset (deltaAsset < 0) the user will have to choose a minimum positive number of stable
    /// that he wants to be credited with.
    /// @return the payouts that need to be made, plus serialized of the `ChangePositionData` struct
    function changePosition(
        address trader,
        int256 deltaStable,
        int256 deltaAsset,
        int256 stableBound,
        int256 oraclePrice,
        uint256 time
    ) external returns (Payout[] memory, bytes memory);

    /// @notice Liquidates a trader's position.
    /// For a position to be liquidatable, it needs to either have less collateral (stable) left than
    /// ExchangeConfig.minCollateral or exceed a leverage higher than ExchangeConfig.maxLeverage.
    /// If this is a case, anyone can liquidate the position and receive a reward.
    /// @param trader The trader to liquidate.
    /// @return The needed payouts plus a serialized `ChangePositionData`.
    function liquidate(
        address trader,
        address liquidator,
        int256 oraclePrice,
        uint256 time
    ) external returns (Payout[] memory, bytes memory);

    /// @notice Position for a particular trader.
    /// @param trader The address to use for obtaining the position.
    /// @param price The oracle price at which to evaluate funding/
    /// @param time The time at which to evaluate the funding (0 means no funding).
    function getPosition(
        address trader,
        int256 price,
        uint256 time
    )
    external
    view
    returns (
        int256 asset,
        int256 stable,
        uint32 trancheIdx
    );

    /// @notice Returns the position of the AMM in the exchange.
    /// @param price The oracle price at which to evaluate funding.
    /// @param time The time at which to evaluate the funding (0 means no funding).
    function getAmmPosition(int256 price, uint256 time)
    external
    view
    returns (int256 stableAmount, int256 assetAmount);

    /// @notice Updates the config of the exchange, can only be performed by the voting executor.
    function setExchangeConfig(ExchangeConfig calldata _config) external;

    /// @notice Update the exchange state.
    /// Is used to PAUSE or STOP the exchange. When PAUSED, trades cannot open, liquidity cannot be added, and a
    /// fixed oracle price is set. When STOPPED no user actions can occur.
    function setExchangeState(ExchangeState _state, int256 _pausePrice) external;

    /// @notice Update the exchange hook.
    function setHook(address _hook) external;

    /// @notice Update the AMM used in the exchange.
    function setAmm(address _amm) external;

    /// @notice Update the TradeRouter authorized for this exchange.
    function setTradeRouter(address _tradeRouter) external;
}


// File contracts/lib/Utils.sol



// BEGIN STRIP
// Used in `FsUtils.Log` which is a debugging tool.

// END STRIP

library FsUtils {
    function nonNull(address _address) internal pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    // Slither sees this function is not used, but it is convenient to have it around, as it
    // actually provides better error messages than `nonNull` above.
    // slither-disable-next-line dead-code
    function nonNull(address _address, string memory message) internal pure returns (address) {
        require(_address != address(0), message);
        return _address;
    }
}

// Contracts deriving from this contract will have a public pure function
// that returns a gitCommitHash at the moment it was compiled.
contract GitCommitHash {
    // A purely random string that's being replaced in a prod build by
    // the git hash at build time.
    uint256 public immutable gitCommitHash =
    852658842061751148811627154423765012439508971448;
}


// File contracts/upgrade/FsAdmin.sol



/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract FsAdmin {
    /// @notice The admin of the VotingExecutor, the admin can call the execute method
    ///         directly. Admin will be phased out
    address public admin;

    /// @notice A newly proposed admin. Admin is handed over to an address and needs to be confirmed
    ///         before a new admin becomes live. This prevents using an unusable address as a new admin
    address public proposedNewAdmin;

    /// @notice Initializes the VotingExecutor with a given admin, can only be called once
    /// @param _admin The admin of the VotingExectuor, see field description for more detail
    function initializeFsAdmin(address _admin) internal {
        //slither-disable-next-line missing-zero-check
        admin = nonNullAdmin(_admin);
    }

    /// @notice Remove the admin from the contract, can only be called by the current admin
    function removeAdmin() external onlyAdmin {
        emit AdminRemoved(admin);
        admin = address(0);
    }

    /// @notice Propose a new admin, the new address has to call acceptAdmin for adminship to be handed over
    /// @param _newAdmin The newly proposed admin
    function proposeNewAdmin(address _newAdmin) external onlyAdmin {
        //slither-disable-next-line missing-zero-check
        proposedNewAdmin = nonNullAdmin(_newAdmin);
        emit NewAdminProposed(_newAdmin);
    }

    /// @notice Accept adminship over the contract. This can only be called by a proposed admin
    function acceptAdmin() external {
        require(msg.sender == proposedNewAdmin, "Invalid caller");
        address oldAdmin = admin;
        admin = msg.sender;
        proposedNewAdmin = address(0);
        emit AdminAccepted(oldAdmin, msg.sender);
    }

    /// @dev Prevents calling from any address except the admin address
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function nonNullAdmin(address _address) private pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    /// @notice Emitted if adminship is revoked from the contract
    /// @param admin The address that gave up adminship
    event AdminRemoved(address admin);

    /// @notice Emitted when a new admin address is proposed
    /// @param newAdmin The new admin address
    event NewAdminProposed(address newAdmin);

    /// @notice Emitted when a new admin address has accepted adminship
    /// @param oldAdmin The old admin address
    /// @param newAdmin The new admin address
    event AdminAccepted(address oldAdmin, address newAdmin);
}


// File contracts/exchange41/TokenVault.sol




/// @title TokenVault implementation.
/// @notice TokenVault is the only contract in the Futureswap system that stores ERC20 tokens, including both collateral
/// and liquidity. Each exchange has its own instance of TokenVault, which provides isolation of the funds between
/// different exchanges and adds an additional layer of protection in case one exchange gets compromised.
/// Users are not meant to interact with this contract directly. For each exchange, only the TokenRouter and the
/// corresponding implementation of IAmm (for example, SpotMarketAmm) are authorized to withdraw funds. If new versions
/// of these contracts become available, then they can be approved and the old ones disapproved.
///
/// @dev We decided to make TokenVault non-upgradable. The implementation is very simple and in case of an emergency
/// recovery of funds, the VotingExecutor (which should be the owner of TokenVault) can approve arbitrary addresses
/// to withdraw funds.
contract TokenVault is Ownable, FsAdmin, GitCommitHash {
    using SafeERC20 for IERC20;

    /// @notice Mapping to track addresses that are approved to move funds from this vault.
    mapping(address => bool) public isApproved;

    /// @notice When the TokenVault is frozen, no transfer of funds in or out of the contract can happen.
    bool isFrozen;

    /// @notice Requires caller to be an approved address.
    modifier onlyApprovedAddress() {
        require(isApproved[msg.sender], "Not an approved address");
        _;
    }

    /// @notice Emitted when approvals for `userAddress` changes. Reports the value before the change in
    /// `previousApproval` and the value after the change in `currentApproval`.
    event VaultApprovalChanged(
        address indexed userAddress,
        bool previousApproval,
        bool currentApproval
    );

    /// @notice Emitted when `amount` tokens are transfered from the TokenVault to the `recipient`.
    event VaultTokensTransferred(address recipient, address token, uint256 amount);

    /// @notice Emitted when the vault is frozen/unfrozen.
    event VaultFreezeStateChanged(bool previousFreezeState, bool freezeState);

    constructor(address _admin) {
        initializeFsAdmin(_admin);
    }

    /// @notice Changes the approval status of an address. If an address is approved, it's allowed to move funds from
    /// the vault. Can only be called by the VotingExecutor.
    ///
    /// @param userAddress The address to change approvals for. Can't be the zero address.
    /// @param approved Whether to approve or disapprove the address.
    function setAddressApproval(address userAddress, bool approved) external onlyOwner {
        // This does allow an arbitrary address to be approved to withdraw funds from the vault but this risk
        // is mitigated as only the owner can call this function. As long as the owner is the VotingExecutor,
        // which is controlled by governance, no single individual would be able to approve a malicious address.
        // slither-disable-next-line missing-zero-check
        userAddress = FsUtils.nonNull(userAddress);
        bool previousApproval = isApproved[userAddress];

        if (previousApproval == approved) {
            return;
        }

        isApproved[userAddress] = approved;
        emit VaultApprovalChanged(userAddress, previousApproval, approved);
    }

    /// @notice Transfers the given amount of token from the vault to a given address.
    /// This can only be called by an approved address.
    ///
    /// @param recipient The address to transfer tokens to.
    /// @param token Which token to transfer.
    /// @param amount The amount to transfer, represented in the token's underlying decimals.
    function transfer(
        address recipient,
        address token,
        uint256 amount
    ) external onlyApprovedAddress {
        require(!isFrozen, "Vault is frozen");

        emit VaultTokensTransferred(recipient, token, amount);
        // There's no risk of a malicious token being passed here, leading to reentrancy attack
        // because:
        // (1) Only approved addresses can call this method to move tokens from the vault.
        // (2) Only tokens associated with the exchange would ever be moved.
        // OpenZeppelin safeTransfer doesn't return a value and will revert if any issue occurs.
        IERC20(token).safeTransfer(recipient, amount);
    }

    /// @notice For security we allow admin/voting to freeze/unfreeze the vault this allows an admin
    /// to freeze funds, but not move them.
    function setIsFrozen(bool _isFrozen) external {
        if (isFrozen == _isFrozen) {
            return;
        }

        require(msg.sender == owner() || msg.sender == admin, "Only owner or admin");
        emit VaultFreezeStateChanged(isFrozen, _isFrozen);
        isFrozen = _isFrozen;
    }
}


// File contracts/exchange41/TradeRouter.sol













/// @title The outward facing API of the trading functions of the exchange.
/// This contract has a single responsibility to deal with ERC20/ETH. This way the `ExchangeLedger`
/// code does not contain any code related to ERC20 and only deals with abstract balances.
/// The benefits of this design are
/// 1) The code that actually touches the valuables of users is simple, verifiable and
///    non-upgradeable. Making it easy to audit and safe to infinite approve.
/// 2) We can easily specialize the API for important special cases (close) without adding
///    noise to more complicated `ExchangeLedger` code. On some L2's (Arbitrum) tx cost is dominated by
///    calldata and specializing important use cases can save a significant amount on tx cost.
/// 3) Easy "view" function for changePosition. By calling the exchange ledger (using callstatic) from
///    this address, the frontend can see the result of potential trade without needing approval
///    for the necessary funds.
/// 4) Easy testability of different components. The exchange logic can be tested without the
///    need of tests to setup ERC20's and liquidity.
contract TradeRouter is Ownable, EIP712, IERC677Receiver, GitCommitHash {
    using SafeERC20 for IERC20;

    IWETH9 public immutable wethToken;
    IExchangeLedger public immutable exchangeLedger;
    IERC20 public immutable stableToken;
    IERC20 public immutable assetToken;
    TokenVault public immutable tokenVault;
    IOracle public oracle;

    /// @notice Keeps track of the nonces used by each trader that interacted with the contract using
    /// changePositionOnBehalfOf. Users can get a new nonce to use in the signature of their message by calling
    /// nonce(userAddress).
    mapping(address => uint256) public nonce;

    /// @notice Struct to be used together with an ERC677 transferAndCall to pass data to the onTokenTransfer function
    /// in this contract. Note that this struct only contains deltaAsset and stableBound, since the deltaStable comes as
    /// the `amount` transferred in transferAndCall.
    struct ChangePositionInputData {
        int256 deltaAsset;
        int256 stableBound;
    }

    /// @notice Emitted when trader's position changed (except if it is the result of a liquidation).
    event TraderPositionChanged(
        address indexed trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound
    );

    /// @notice Emitted when a `trader` was successfully liquidated by a `liquidator`.
    event TraderLiquidated(address indexed trader, address indexed liquidator);

    /// @notice Emitted when payments to different actors are successfully done.
    event PayoutsTransferred(IExchangeLedger.Payout[] payouts);

    /// @notice Emitted when the oracle address changes.
    event OracleChanged(address oldOracle, address newOracle);

    /// @param _exchangeLedger An instance of IExchangeLedger that will trust this TradeRouter.
    /// @param _wethToken Address of WETH token.
    /// @param _tokenVault The TokenVault that will store the tokens for this TradeRouter. TokenVault needs trust this
    /// contract.
    /// @param _oracle An instance of IOracle to use for pricing in liquidations and change position.
    /// @param _assetToken ERC20 that represents the "asset" in the exchange.
    /// @param _stableToken ERC20 that represents the "stable" in the exchange.
    constructor(
        address _exchangeLedger,
        address _wethToken,
        address _tokenVault,
        address _oracle,
        address _assetToken,
        address _stableToken
    ) EIP712("Futureswap TradeRouter", "1") {
        exchangeLedger = IExchangeLedger(FsUtils.nonNull(_exchangeLedger));
        wethToken = IWETH9(FsUtils.nonNull(_wethToken));
        assetToken = IERC20(FsUtils.nonNull(_assetToken));
        stableToken = IERC20(FsUtils.nonNull(_stableToken));
        tokenVault = TokenVault(FsUtils.nonNull(_tokenVault));
        oracle = IOracle(FsUtils.nonNull(_oracle));
    }

    /// @notice Updates the oracle the TokenRouter uses for trades, can only be performed
    /// by the voting executor.
    function setOracle(address _oracle) external onlyOwner {
        if (address(oracle) == _oracle) {
            return;
        }
        address oldOracle = address(oracle);
        oracle = IOracle(FsUtils.nonNull(_oracle));
        emit OracleChanged(oldOracle, _oracle);
    }

    /// @notice Gets the asset price from the oracle associated to this contract.
    function getPrice() external view returns (int256) {
        return oracle.getPrice(address(assetToken));
    }

    /// @notice Allow ETH to be sent to this contract for unwrapping WETH only.
    receive() external payable {
        require(msg.sender == address(wethToken), "Wrong sender");
    }

    /// @notice Changes a trader's position.
    /// @param deltaAsset  The amount of asset the position should be changed by.
    /// @param deltaStable The amount of stable to change the position by
    /// Positive values will add stable to the position and move stable token from the trader into the TokenVault.
    /// Negative values will remove stable from the position and send the trader tokens from the TokenVault.
    /// @param stableBound The maximum/minimum amount of stable that the user is willing to pay/receive for the
    /// deltaAsset change
    /// If the user is buying asset (deltaAsset > 0), they will have to choose a maximum negative number that they are
    /// going to be in debt for.
    /// If the user is selling asset (deltaAsset < 0), they will have to choose a minimum positive number of stable that
    /// they wants to be credited with.
    function changePosition(
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound
    ) public returns (bytes memory) {
        address trader = msg.sender;
        if (deltaStable > 0) {
            // slither-disable-next-line safe-cast
            stableToken.safeTransferFrom(trader, address(tokenVault), uint256(deltaStable));
        }
        return
        doChangePosition(
            trader,
            deltaAsset,
            deltaStable,
            stableBound,
            false /* useETH */
        );
    }

    /// @notice Changes a trader's position, same as `changePosition`, but using a compacted data representation to save
    /// gas cost.
    /// @param packedData Contains `deltaAsset`, `deltaStable` and `stableBound` packed in the following format:
    /// 112 bits for deltaAsset (signed) and 112 bits for deltaStable (signed)
    /// 8 bits for stableBound exponent (unsigned) and 24 bits for stableBound mantissa (signed)
    /// stableBound is obtained by doing mantissa * (2 ** exponent).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionPacked(uint256 packedData) external returns (bytes memory) {
        (int256 deltaAsset, int256 deltaStable, int256 stableBound) = unpack(packedData);
        return changePosition(deltaAsset, deltaStable, stableBound);
    }

    /// @notice Closes the trader's current position.
    /// @dev This helper function is useful to save gas in L2 chains where call data is the dominating cost factor (for
    /// example, Arbitrum).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function closePosition() external returns (bytes memory) {
        return changePosition(0, 0, 0);
    }

    /// @notice Changes a trader's position, using the IERC677 transferAndCall flow on the stable token contract.
    /// @param from This is the sender of the transferAndCall transaction and is used as the trader.
    /// @param amount This is the amount transferred during transferAndCall and is used as the deltaStable.
    /// @param data Needs to be an encoded version of `ChangePositionInputData`.
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(msg.sender == address(stableToken), "Wrong token");
        // slither-disable-next-line safe-cast
        require(amount <= uint256(type(int256).max), "`amount` is over int256.max");

        ChangePositionInputData memory cpid = abi.decode(data, (ChangePositionInputData));
        stableToken.safeTransfer(address(tokenVault), amount);

        // We checked that `amount` fits into `int256` above.
        // slither-disable-next-line safe-cast
        doChangePosition(
            from,
            cpid.deltaAsset,
            int256(amount),
            cpid.stableBound,
            false /* useETH */
        );
        return true;
    }

    /// @notice Changes a trader's position, same as `changePosition`, but allows users to pay their collateral in ETH
    /// instead of WETH (only valid for exchanges that use WETH as collateral).
    /// The value in `deltaStable` needs to match the amount of ETH sent in the transaction.
    /// @dev The ETH received is converted to WETH and stored into the TokenVault. The whole system operates with ERC20,
    /// not ETH.
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionWithEth(
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound
    ) public payable returns (bytes memory) {
        require(stableToken == wethToken, "Exchange doesn't accept ETH");
        address trader = msg.sender;
        if (deltaStable > 0) {
            uint256 amount = msg.value;
            // slither-disable-next-line safe-cast
            require(amount == uint256(deltaStable), "msg.value doesn't match deltaStable");
            wethToken.deposit{ value: amount }();
            IERC20(wethToken).safeTransfer(address(tokenVault), amount);
        } else {
            require(msg.value == 0, "msg.value doesn't match deltaStable");
        }
        return
        doChangePosition(
            trader,
            deltaAsset,
            deltaStable,
            stableBound,
            true /* useETH */
        );
    }

    /// @notice Changes a trader's position, same as `changePositionWithEth`, but using a compacted data representation
    /// to save gas cost.
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionWithEthPacked(uint256 packed) external payable returns (bytes memory) {
        (int256 deltaAsset, int256 deltaStable, int256 stableBound) = unpack(packed);
        return changePositionWithEth(deltaAsset, deltaStable, stableBound);
    }

    /// @notice Closes the trader's current position, and returns ETH instead of WETH in exchanges that use WETH as
    /// collateral.
    /// @dev This helper function is useful to save gas in L2 chains where call data is the dominating cost factor (for
    /// example, Arbitrum).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function closePositionWithEth() external payable returns (bytes memory) {
        return changePositionWithEth(0, 0, 0);
    }

    /// @notice Change's a trader's position, same as in changePosition, but can be called by any arbitrary contract
    /// that the trader trusts.
    /// @param trader The trader to change position to.
    /// @param deltaAsset see deltaAsset in `changePosition`.
    /// @param deltaStable see deltaStable in `changePosition`.
    /// @param stableBound see stableBound in `changePosition`.
    /// @param extraHash Can be used to verify extra data from the calling contract.
    /// @param signature A signature created using `trader` private keys. The signed message needs to have the following
    /// data:
    ///    address of the trader which is signing the message.
    ///    deltaAsset, deltaStable, stableBound (parameters that determine the trade).
    ///    extraHash (the same as the parameter passed above).
    ///    nonce: unique number used to ensure that the message can't be replayed. Can be obtained by calling
    ///           `nonce(trader)` in this contract.
    ///    address of the sender (to ensure that only the contract authorized by the trader can execute this).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionOnBehalfOf(
        address trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound,
        bytes32 extraHash,
        bytes calldata signature
    ) external returns (bytes memory) {
        // Capture trader's address at top of stack to prevent stack to deep.
        address traderTmp = trader;

        // _hashTypedDataV4 combines the hash of this message with a hash specific to this
        // contract and chain, such that this message cannot be replayed.
        bytes32 digest =
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "changePositionOnBehalfOf(address trader,int256 deltaAsset,int256 deltaStable,int256 stableBound,bytes32 extraHash,uint256 nonce,address sender)"
                    ),
                    traderTmp,
                    deltaAsset,
                    deltaStable,
                    stableBound,
                // extraHash can be used to verify extra data from the calling contract.
                    extraHash,
                // Use a unique nonce to ensure that the message cannot be replayed.
                    nonce[traderTmp],
                // Including msg.sender ensures only the signer authorized Ethereum account can execute.
                    msg.sender
                )
            )
        );
        address signer = ECDSA.recover(digest, signature);
        require(signer == trader, "Not signed by trader");
        nonce[trader]++;

        if (deltaStable > 0) {
            // slither-disable-next-line safe-cast
            stableToken.safeTransferFrom(trader, address(tokenVault), uint256(deltaStable));
        }
        return
        doChangePosition(
            trader,
            deltaAsset,
            deltaStable,
            stableBound,
            false /* useETH */
        );
    }

    /// @notice Liquidates `trader` if its position is liquidatable and pays out to the different actors involved (the
    /// liquidator, the pool and the trader).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function liquidate(address trader) external returns (bytes memory) {
        address liquidator = msg.sender;
        int256 oraclePrice = oracle.getPrice(address(assetToken));
        (IExchangeLedger.Payout[] memory payouts, bytes memory changePositionData) =
        exchangeLedger.liquidate(trader, liquidator, oraclePrice, block.timestamp);
        transferPayouts(
            payouts,
            false /* useETH */
        );
        emit TraderLiquidated(trader, liquidator);
        return changePositionData;
    }

    function doChangePosition(
        address trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound,
        bool useETH
    ) private returns (bytes memory) {
        int256 oraclePrice = oracle.getPrice(address(assetToken));
        (IExchangeLedger.Payout[] memory payouts, bytes memory changePositionData) =
        exchangeLedger.changePosition(
            trader,
            deltaAsset,
            deltaStable,
            stableBound,
            oraclePrice,
            block.timestamp
        );
        transferPayouts(payouts, useETH);
        emit TraderPositionChanged(trader, deltaAsset, deltaStable, stableBound);
        return changePositionData;
    }

    function transferPayouts(IExchangeLedger.Payout[] memory payouts, bool useETH) private {
        // If the TokenVault doesn't have enough `stableToken` to make all the payments, the whole transaction reverts.
        // This can only happen if (1) There is a *bug* in the accounting (2) Liquidations don't happen on time and
        // bankrupt trades deplete the TokenVault (this is highly unlikely).
        for (uint256 i = 0; i < payouts.length; i++) {
            IExchangeLedger.Payout memory payout = payouts[i];
            if (payout.to == address(0) || payout.amount == 0) {
                continue;
            }

            if (useETH && stableToken == wethToken && payout.to == msg.sender) {
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                tokenVault.transfer(address(this), address(wethToken), payout.amount);
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                wethToken.withdraw(payout.amount);
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                Address.sendValue(payable(payout.to), payout.amount);
            } else {
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                tokenVault.transfer(payout.to, address(stableToken), payout.amount);
            }
        }

        emit PayoutsTransferred(payouts);
    }

    // public for testing
    function unpack(uint256 packed)
    public
    pure
    returns (
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound
    )
    {
        // slither-disable-next-line safe-cast
        deltaAsset = int112(uint112(packed));
        // slither-disable-next-line safe-cast
        deltaStable = int112(uint112(packed >> 112));
        // slither-disable-next-line safe-cast
        uint8 stableBoundExp = uint8(packed >> 224);
        // slither-disable-next-line safe-cast
        int256 stableBoundMantissa = int24(uint24(packed >> 232));
        stableBound = stableBoundMantissa << stableBoundExp;
    }
}