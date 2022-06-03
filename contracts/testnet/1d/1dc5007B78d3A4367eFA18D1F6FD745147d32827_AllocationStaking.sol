// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IAdmin.sol";
import "./interfaces/IDistribution.sol";

contract AllocationStaking is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSA for bytes32;

    struct StakeRecord {
        uint256 id; // Stake id, NOT UNIQUE OVER ALL USERS, unique only among user's other stakes.
        uint256 index; // Index of the StakeRecord in the user.stakeIds array.
        uint256 amount; // Stake amount
        uint256 rewardDebt; // Current reward debt.
        uint256 tokensUnlockTime; // When stake tokens will unlock
        // Keep in mind, that multiplier might not be up to date
        // For example, if user's stake went into 14 days lock period after the initial unlock and he didn't manually relock it.
        // Or if getStakeMultiplierPercent was modified on contract upgrade.
        uint256 stakeMultiplierPercent; // Reward multiplier percent, applied to withdrawals
    }

    // Info of each user.
    struct UserInfo {
        uint256 totalAmount; // How many LP tokens the user has provided in all his stakes.
        uint256 totalRewarded; // How many tokens user got rewarded in total
        uint256 stakesCount; // How many new deposits user made overall
        uint256[] stakeIds; // User's current (not fully withdrawn) stakes ids
        mapping(uint256 => StakeRecord) stakes; // Stake's id to the StakeRecord mapping
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 lastRewardTimestamp; // Last timstamp that ERC20s distribution occurs.
        uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
        uint256 totalDeposits; // Total amount of tokens deposited at the moment (staked)
        uint256 emptyTimestamp; // When pool's totalDeposits became empty. Used for accounting of missed rewards, that weren't issued.
        uint256 uniqueUsers; // How many unique users there are in the pool
    }

    // State of the contract
    enum ContractState {
        Operating,
        Halted
    }

    // Time to relock the stake after it's unlock
    uint256 public constant RELOCK_DAYS = 14;

    // Address of the ERC20 Token contract.
    IERC20Upgradeable public erc20;
    // Distribution contract address who can mint tokens
    IDistribution public distribution;
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut;
    // Total rewards not issued caused by empty pools
    uint256 public missedRewards;
    // Total amount of missed rewards tokens minted
    uint256 public missedRewardsMinted;
    // Precision of deposit fee
    uint256 public depositFeePrecision;
    // Percent of deposit fee, must be >= depositFeePrecision.div(100) and less than depositFeePrecision
    uint256 public depositFeePercent;
    // Share of the deposit fee, that will go to the staking pool in percents
    uint256 public depositFeePoolSharePercent;
    // Amount of the deposit fee collected and ready to claim by the owner
    uint256 public depositFeeCollected;
    // Total AVAT redistributed between people staking
    uint256 public totalAvatRedistributed;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when staking starts.
    uint256 public startTimestamp;
    // Total amount of tokens burned from the wallet
    mapping(address => uint256) public totalBurnedFromUser;
    // Time when withdraw is allowed after the stake unlocks
    uint256 public withdrawAllowedDays;
    // Admin contract
    IAdmin public admin;
    // Contract state
    ContractState public contractState;

    // Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 withdrawAmount, uint256 rewardAmount);
    event Rewards(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 amount);
    event Restake(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 unlockTime);
    event DepositFeeSet(uint256 depositFeePercent, uint256 depositFeePrecision);
    event CompoundedEarnings(address indexed user, uint256 indexed pid, uint256 indexed stakeIndex, uint256 amountAdded, uint256 totalDeposited);
    event FeeTaken(address indexed user, uint256 indexed pid, uint256 amount, uint256 poolShare);
    event EmergencyMint(address indexed recipient, uint256 amount);

    // Call can be processed only when the contract is in operating state
    modifier onlyOperating() {
        require(contractState == ContractState.Operating, "Contract is not operating currently");
        _;
    }

    function initialize(
        IERC20Upgradeable _erc20,
        IDistribution _distribution,
        uint256 _startTimestamp,
        uint256 _depositFeePercent,
        uint256 _depositFeePrecision,
        uint256 _depositFeePoolSharePercent,
        uint256 _withdrawAllowedDays
    ) public initializer {
        __Ownable_init();

        erc20 = _erc20;
        distribution = _distribution;

        startTimestamp = _startTimestamp;
        contractState = ContractState.Operating;

        setDepositFeeInternal(_depositFeePercent, _depositFeePrecision);
        depositFeePoolSharePercent = _depositFeePoolSharePercent;

        withdrawAllowedDays = _withdrawAllowedDays;
    }

    // Number of LP pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        require(poolInfo.length > 0 || _lpToken == erc20, "First pool's lp token must be a reward token");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // Push new PoolInfo
        poolInfo.push(PoolInfo({lpToken: _lpToken, allocPoint: _allocPoint, lastRewardTimestamp: lastRewardTimestamp, accERC20PerShare: 0, totalDeposits: 0, emptyTimestamp: lastRewardTimestamp, uniqueUsers: 0}));
    }

    // Set deposit fee
    function setDepositFee(uint256 _depositFeePercent, uint256 _depositFeePrecision) public onlyOwner {
        setDepositFeeInternal(_depositFeePercent, _depositFeePrecision);
    }

    // Set deposit fee internal
    function setDepositFeeInternal(uint256 _depositFeePercent, uint256 _depositFeePrecision) internal {
        require(_depositFeePercent >= _depositFeePrecision.div(100) && _depositFeePercent <= _depositFeePrecision);
        depositFeePercent = _depositFeePercent;
        depositFeePrecision = _depositFeePrecision;
        emit DepositFeeSet(depositFeePercent, depositFeePrecision);
    }

    // Claim all collected fees and send them to the recipient. Can only be called by the owner.
    function claimCollectedFees(address _recipient) external onlyOwner {
        require(depositFeeCollected > 0, "Zero fees to collect");
        erc20.transfer(_recipient, depositFeeCollected);
        depositFeeCollected = 0;
    }

    // Update the given pool's ERC20 allocation point. Can only be called by the owner. Always prefer to call with _withUpdate set to true.
    function setAllocation(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Sets new ERC20 minter address
    function setDistribution(IDistribution _distribution) public onlyOwner {
        distribution = _distribution;
    }

    // Gets reward multiplier for the stake duration
    // For 14 days ti's 0x
    // For 30 days it's 1x
    // For 45 days it's 1.5x
    // For 60 days it's 2x
    function getStakeMultiplierPercent(uint256 stakeDays) public pure returns (uint256) {
        // When you change stake days values, make sure you change the RELOCK_DAYS if needed;
        // Also be aware that restake assumes, that 0 multiplier means 14 days stake.
        require(stakeDays == 1 || stakeDays == 2 || stakeDays == 3 || stakeDays == 4, "Stake duration must equal to 14, 30, 45 or 60 days");
        return stakeDays >= 2 ? (stakeDays * 100) / 2 : 0;
    }

    // Calculate iAVAT amount for the user
    function getiAVATAmount(address _user) public view returns (uint256 iavat) {
        UserInfo storage user = userInfo[0][_user];
        for (uint256 i = 0; i < user.stakeIds.length; i++) {
            StakeRecord storage stake = user.stakes[user.stakeIds[i]];
            // We don't count the stake if it's on automatic 14 days relock
            if (block.timestamp > stake.tokensUnlockTime.add(withdrawAllowedDays.mul(1 days))) {
                continue;
            }
            iavat = iavat.add(stake.amount.mul(stake.stakeMultiplierPercent).div(100));
        }
    }

    // Get user's stakes count
    function userStakesCount(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.stakeIds.length;
    }

    // Return user's stakes array
    function getUserStakes(uint256 _pid, address _user) public view returns (StakeRecord[] memory stakeArray) {
        UserInfo storage user = userInfo[_pid][_user];
        stakeArray = new StakeRecord[](user.stakeIds.length);
        for (uint256 i = 0; i < user.stakeIds.length; i++) {
            stakeArray[i] = user.stakes[user.stakeIds[i]];
        }
    }

    // Return user's specific stake
    function getUserStake(
        uint256 _pid,
        address _user,
        uint256 _stakeId
    ) public view returns (StakeRecord memory) {
        UserInfo storage user = userInfo[_pid][_user];
        require(user.stakes[_stakeId].id == _stakeId, "Stake with this id does not exist");
        return user.stakes[_stakeId];
    }

    // Return user's stake ids array
    function getUserStakeIds(uint256 _pid, address _user) public view returns (uint256[] memory) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.stakeIds;
    }

    // View function to see deposited LP for a particular user's stake.
    function deposited(
        uint256 _pid,
        address _user,
        uint256 _stakeId
    ) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        StakeRecord storage stake = user.stakes[_stakeId];
        require(stake.id == _stakeId, "Stake with this id does not exist");
        return stake.amount;
    }

    // View function to see total deposited LP for a user.
    function totalDeposited(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.totalAmount;
    }

    // View function to see pending ERC20s for a user's stake.
    function pending(
        uint256 _pid,
        address _user,
        uint256 _stakeId
    ) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        StakeRecord storage stake = user.stakes[_stakeId];
        require(stake.id == _stakeId, "Stake with this id does not exist");

        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.totalDeposits;

        // Compute pending ERC20s
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 totalReward = distribution.countRewardAmount(pool.lastRewardTimestamp, block.timestamp);
            uint256 poolReward = totalReward.mul(pool.allocPoint).div(totalAllocPoint);
            accERC20PerShare = accERC20PerShare.add(poolReward.mul(1e36).div(lpSupply));
        }
        return stake.amount.mul(accERC20PerShare).div(1e36).sub(stake.rewardDebt);
    }

    // View function to see total pending ERC20s for a user.
    function totalPending(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];

        uint256 pendingAmount = 0;
        for (uint256 i = 0; i < user.stakeIds.length; i++) {
            pendingAmount = pendingAmount.add(pending(_pid, _user, user.stakeIds[i]));
        }
        return pendingAmount;
    }

    // View function for total reward the contract has yet to pay out.
    // NOTE: this is not necessarily the sum of all pending sums on all pools and users
    //      example 1: when one pool has no LP supply
    function totalPoolPending() external view returns (uint256) {
        if (block.timestamp <= startTimestamp) {
            return 0;
        }

        return distribution.countRewardAmount(startTimestamp, block.timestamp).sub(paidOut).sub(missedRewards);
    }

    // Calculate pool's estimated APR. Returns APR in percents * 100.
    function getPoolAPR(uint256 _pid) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 reward = distribution.countRewardAmount(block.timestamp, block.timestamp.add(365 days));
        return reward.mul(pool.allocPoint).div(totalAllocPoint).mul(1e4).div(pool.totalDeposits);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        updatePoolWithFee(_pid, 0);
    }

    // Function to update pool with fee to redistribute amount between other stakers
    function updatePoolWithFee(uint256 _pid, uint256 _depositFee) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastTimestamp = block.timestamp;

        if (lastTimestamp <= pool.lastRewardTimestamp) {
            lastTimestamp = pool.lastRewardTimestamp;
        }

        uint256 lpSupply = pool.totalDeposits;

        if (lpSupply == 0) {
            pool.lastRewardTimestamp = lastTimestamp;

            if (lastTimestamp > startTimestamp) {
                uint256 contractMissed = distribution.countRewardAmount(pool.emptyTimestamp, block.timestamp);
                missedRewards = missedRewards.add(contractMissed.mul(pool.allocPoint).div(totalAllocPoint));
                pool.emptyTimestamp = lastTimestamp;
            }

            return;
        }
        // Add to the reward fee taken, and distribute to all users staking at the moment.
        uint256 reward = distribution.countRewardAmount(pool.lastRewardTimestamp, lastTimestamp);
        uint256 erc20Reward = reward.mul(pool.allocPoint).div(totalAllocPoint).add(_depositFee);

        pool.accERC20PerShare = pool.accERC20PerShare.add(erc20Reward.mul(1e36).div(lpSupply));

        pool.lastRewardTimestamp = lastTimestamp;
    }

    // Check if it's the withdrawAllowedDays time window
    function isWithdrawAllowedTime(uint256 tokensUnlockTime) internal view returns (bool) {
        uint256 relockEpochTime = withdrawAllowedDays.add(RELOCK_DAYS).mul(1 days);
        uint256 timeSinceUnlock = block.timestamp.sub(tokensUnlockTime);
        return timeSinceUnlock.mod(relockEpochTime) < withdrawAllowedDays.mul(1 days);
    }

    // Deposit LP tokens to stake for ERC20 allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        uint256 stakeDays
    ) public onlyOperating {
        require(_amount > 0, "Should deposit positive amount");
        require(_pid < poolInfo.length, "Pool with such id does not exist");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 depositAmount = _amount;
        uint256 feePoolShare = 0;

        // Only for the main pool take fees
        if (_pid == 0) {
            uint256 depositFee = _amount.mul(depositFeePercent).div(depositFeePrecision);
            depositAmount = _amount.sub(depositFee);

            feePoolShare = depositFee.mul(depositFeePoolSharePercent).div(100);
            depositFeeCollected = depositFeeCollected.add(depositFee.sub(feePoolShare));
            // Update accounting around burning
            burnFromUser(msg.sender, feePoolShare);
            emit FeeTaken(msg.sender, _pid, depositFee, feePoolShare);
        }

        // Update pool including fee for people staking
        updatePoolWithFee(_pid, feePoolShare);

        // Safe transfer lpToken from user
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        // Add deposit to total deposits
        pool.totalDeposits = pool.totalDeposits.add(depositAmount);

        if (pool.totalDeposits > 0) {
            // we are not updating missedRewards here because it must've been done in the updatePoolWithFee
            pool.emptyTimestamp = 0;
        }

        // Increment if this is a new user of the pool
        if (user.stakesCount == 0) {
            pool.uniqueUsers = pool.uniqueUsers.add(1);
        }

        // Initialize a new stake record
        uint256 stakeId = user.stakesCount;
        require(user.stakes[stakeId].id == 0, "New stake record is not empty");

        StakeRecord storage stake = user.stakes[stakeId];
        // Set stake id
        stake.id = stakeId;
        // Set stake index in the user.stakeIds array
        stake.index = user.stakeIds.length;
        // Add deposit to user's amount
        stake.amount = depositAmount;
        // Update user's total amount
        user.totalAmount = user.totalAmount.add(depositAmount);
        // Compute reward debt
        stake.rewardDebt = stake.amount.mul(pool.accERC20PerShare).div(1e36);
        // Set lockup time
        stake.tokensUnlockTime = block.timestamp.add(stakeDays.mul(1 days));
        // Set reward multiplier
        stake.stakeMultiplierPercent = getStakeMultiplierPercent(stakeDays);

        // Push user's stake id
        user.stakeIds.push(stakeId);
        // Increase users's overall stakes count
        user.stakesCount = user.stakesCount.add(1);

        // Emit relevant event
        emit Deposit(msg.sender, _pid, stake.id, depositAmount);
    }

    // Withdraw LP tokens from pool.
    function withdraw(uint256 _pid, uint256 _stakeId) public onlyOperating {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        StakeRecord storage stake = user.stakes[_stakeId];
        uint256 amount = stake.amount;

        require(stake.tokensUnlockTime <= block.timestamp, "Stake is not unlocked yet.");
        require(amount > 0, "Can't withdraw without an existing stake");

        // Withdraw can be called only for withdrawAllowedDays after the unlock and relocks for RELOCK_DAYS after.
        require(isWithdrawAllowedTime(stake.tokensUnlockTime), "Can only withdraw during the allowed time window after the unlock");

        // Update pool
        updatePool(_pid);

        // Compute user's pending amount
        uint256 pendingAmount = stake.amount.mul(pool.accERC20PerShare).div(1e36).sub(stake.rewardDebt);

        // Transfer pending amount to user
        erc20MintAndTransfer(msg.sender, pendingAmount);
        user.totalRewarded = user.totalRewarded.add(pendingAmount);
        user.totalAmount = user.totalAmount.sub(amount);

        stake.amount = 0;
        stake.rewardDebt = stake.amount.mul(pool.accERC20PerShare).div(1e36);

        // Transfer withdrawal amount to user (with fee being withdrawalFeeDepositAmount)
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        pool.totalDeposits = pool.totalDeposits.sub(amount);

        if (pool.totalDeposits == 0 && block.timestamp > startTimestamp) {
            pool.emptyTimestamp = block.timestamp;
        }

        // Clean stake data since it's always a full withdraw
        {
            uint256 lastStakeId = user.stakeIds[user.stakeIds.length - 1];

            user.stakeIds[stake.index] = lastStakeId;
            user.stakeIds.pop();
            user.stakes[lastStakeId].index = stake.index;

            delete user.stakes[stake.id];
        }

        emit Withdraw(msg.sender, _pid, _stakeId, amount, pendingAmount);
    }

    // Collect staking rewards
    function collect(uint256 _pid, uint256 _stakeId) public onlyOperating {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        StakeRecord storage stake = user.stakes[_stakeId];
        require(stake.amount > 0, "Can't withdraw without an existing stake");

        // Update pool
        updatePool(_pid);

        // Compute user's pending amount
        uint256 pendingAmount = stake.amount.mul(pool.accERC20PerShare).div(1e36).sub(stake.rewardDebt);

        // Transfer pending amount to user
        erc20MintAndTransfer(msg.sender, pendingAmount);
        user.totalRewarded = user.totalRewarded.add(pendingAmount);
        stake.rewardDebt = stake.amount.mul(pool.accERC20PerShare).div(1e36);

        emit Rewards(msg.sender, _pid, _stakeId, pendingAmount);
    }

    // Change stake's lockup time
    function restake(
        uint256 _pid,
        uint256 _stakeId,
        uint256 _stakeDays
    ) public onlyOperating {
        UserInfo storage user = userInfo[_pid][msg.sender];
        StakeRecord storage stake = user.stakes[_stakeId];

        require(stake.id == _stakeId, "Stake with this id does not exist");
        require(stake.amount > 0, "Stake is empty");
        require(stake.tokensUnlockTime <= block.timestamp || stake.stakeMultiplierPercent == 0, "Can't restake before the unlock time");

        uint256 newStakeMultiplier = getStakeMultiplierPercent(_stakeDays);
        stake.tokensUnlockTime = block.timestamp.add(_stakeDays.mul(1 days));
        stake.stakeMultiplierPercent = newStakeMultiplier;

        emit Restake(msg.sender, _pid, _stakeId, stake.tokensUnlockTime);
    }

    // Function to compound earnings into deposit
    function compound(uint256 _pid, uint256 _stakeId) public onlyOperating {
        require(_pid == 0, "Can only compound in the primary pool (_pid == 0)");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        StakeRecord storage stake = user.stakes[_stakeId];
        require(stake.id == _stakeId, "Stake with this id does not exist");

        require(stake.amount > 0, "User does not have anything staked");

        // Update pool
        updatePool(_pid);

        // Compute compounding amount
        uint256 pendingAmount = stake.amount.mul(pool.accERC20PerShare).div(1e36).sub(stake.rewardDebt);
        uint256 fee = pendingAmount.mul(depositFeePercent).div(depositFeePrecision);
        uint256 amountCompounding = pendingAmount.sub(fee);

        require(amountCompounding > 0, "Nothing to compound yet");

        uint256 feePoolShare = fee.mul(depositFeePoolSharePercent).div(100);
        depositFeeCollected = depositFeeCollected.add(fee.sub(feePoolShare));

        // Update accounting around burns
        burnFromUser(msg.sender, feePoolShare);
        emit FeeTaken(msg.sender, _pid, fee, feePoolShare);
        // Update pool including fee for people currently staking
        updatePoolWithFee(_pid, feePoolShare);

        // Mint the tokens to the contract address, because we consider it a stake
        distribution.mintTokens(address(this), pendingAmount);

        // Increase amount user is staking
        stake.amount = stake.amount.add(amountCompounding);
        stake.rewardDebt = stake.amount.mul(pool.accERC20PerShare).div(1e36);

        // Update user's total amount
        user.totalAmount = user.totalAmount.add(amountCompounding);

        // Increase pool's total deposits
        pool.totalDeposits = pool.totalDeposits.add(amountCompounding);
        emit CompoundedEarnings(msg.sender, _pid, _stakeId, amountCompounding, stake.amount);
    }

    // Transfer ERC20 and update the required ERC20 to payout all rewards
    function erc20MintAndTransfer(address _to, uint256 _amount) internal {
        uint256 erc20Balance = erc20.balanceOf(address(this)).sub(depositFeeCollected).sub(poolInfo[0].totalDeposits);
        if (_amount > erc20Balance) {
            distribution.mintTokens(address(this), _amount.sub(erc20Balance));
        }
        erc20.transfer(_to, _amount);
        paidOut += _amount;
    }

    // Internal function to burn amount from user and do accounting
    function burnFromUser(address user, uint256 amount) internal {
        totalBurnedFromUser[user] = totalBurnedFromUser[user].add(amount);
        totalAvatRedistributed = totalAvatRedistributed.add(amount);
    }

    // Function to fetch deposits and earnings at one call for multiple users for passed pool id.
    function getTotalPendingAndDepositedForUsers(address[] memory users, uint256 pid) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory deposits = new uint256[](users.length);
        uint256[] memory earnings = new uint256[](users.length);

        // Get deposits and earnings for selected users
        for (uint256 i = 0; i < users.length; i++) {
            UserInfo storage user = userInfo[pid][users[i]];

            deposits[i] = totalDeposited(pid, users[i]);
            // Sum for all user's stakes
            for (uint256 j = 0; j < user.stakeIds.length; j++) {
                earnings[i] = earnings[i].add(pending(pid, users[i], user.stakeIds[j]));
            }
        }

        return (deposits, earnings);
    }

    // Mint reward that was not paid out when pool was empty
    function emergencyMint(address _recipient) external onlyOwner {
        uint256 amount = missedRewards.sub(missedRewardsMinted);
        require(amount > 0, "There are no missed rewards for minting");

        distribution.mintTokens(_recipient, amount);
        missedRewardsMinted = missedRewardsMinted.add(amount);

        emit EmergencyMint(_recipient, amount);
    }

    // Function to set admin contract by owner
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Cannot set zero address as admin.");
        admin = IAdmin(_admin);
    }

    // Halt contract's operations
    function halt() external onlyOwner {
        contractState = ContractState.Halted;
    }

    // Resume contract's operation
    function resume() external onlyOwner {
        contractState = ContractState.Operating;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IAdmin {
    function isAdmin(address user) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface IDistribution {
    function mintTokens(address to, uint256 amount) external;

    function countRewardAmount(uint256 start_, uint256 end_) external view returns (uint256);
}