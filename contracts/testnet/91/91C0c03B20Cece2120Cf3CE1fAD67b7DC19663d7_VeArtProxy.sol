// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVeArtProxy {
    function _tokenURI(
        uint _tokenId,
        uint _balanceOf,
        uint _locked_end,
        uint _value
    ) external pure returns (string memory output);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

import {IVeArtProxy} from "contracts/interfaces/IVeArtProxy.sol";

contract VeArtProxy is IVeArtProxy, Initializable {
    function initialize() external initializer {}

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 _value
    ) external pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" width="2362" height="2362" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" fill-rule="evenodd" xmlns:v="https://vecta.io/nano"><style><![CDATA[.B{fill:#fff}.C{font-family:Arial}.D{fill-rule:nonzero}.E{font-weight:bold}.F{fill:#0a0a0a}.G{font-size:83.324px}.H{font-size:33.33px}.I{font-size:138.876px}]]></style><defs><linearGradient id="A" gradientUnits="userSpaceOnUse" x1="1175.32" y1="2250.81" x2="1175.32" y2="104.031"><stop offset="0" stop-color="#9e4429"/><stop offset=".502" stop-color="#633"/><stop offset="1" stop-color="#f7344b"/></linearGradient><linearGradient id="B" gradientUnits="userSpaceOnUse" x1="1135.27" y1="1296.91" x2="1224.2" y2="874.415"><stop offset="0" stop-color="#ffdc00"/><stop offset=".341" stop-color="#ffdc00"/><stop offset="1" stop-color="#e62618"/></linearGradient><linearGradient id="C" gradientUnits="userSpaceOnUse" x1="1490.91" y1="1231.57" x2="1376.6" y2="1198.92"><stop offset="0" stop-color="#ffbd14"/><stop offset="1" stop-color="#b51100"/></linearGradient></defs><path fill="url(#A)" d="M317 2273h1716c126 0 229-74 229-165V248c0-91-103-165-229-165H317C191 83 88 157 88 248v1860c0 91 103 165 229 165z"/><path fill="#6eb544" d="M1146 1995c11 7-8 8 8 4l8-4c-13-8-1-12-17 0z"/><path fill="#4f5346" d="M1815 1720c17 12 3 6 16 0-5-3 3-12-16 0z"/><path fill="#8d8928" d="M1529 1251c14 0 12-5 1-8-13-4-5 8-1 8z"/><path fill="#87a789" d="M1744 1853c15 10 1 7 16 0-14-8-3-9-16 0z"/><path fill="#287941" d="M1209 1284c12-16 8 0 0-16-9 17-9 1 0 16z"/><path fill="#625d44" d="M1533 1979c15 10 3 5 14 0-13-7 11-8-8-4l-7 4z"/><path d="M1881 77c-20 78-87 232-307 288 0 0 98-170 106-288h201zM464 106s32 229 340 294c0 0-150-204-126-302 0 0-181 9-214 7h0z" class="F"/><path d="M524 107c8 57 48 188 241 260-11-13-135-185-119-272l-123 13zm1262-30c-8 64-44 154-171 224 6-11 75-135 78-224h93z" fill="#17323f"/><path d="M419 1550h1530c60 0 110 47 110 105v419c0 58-49 105-110 105H419c-60 0-110-47-110-105v-419c0-58 49-105 110-105z" class="F"/><path fill="#1f1f1f" d="M846 2275l6-20 326-1057 19 1075 8-1-19-1075 372 1082 8-1-373-1084 797 1054c1-3 2-7 2-10l-793-1049 1046 731v-10l-1042-728 1027 317v-8l-1025-316 1041-21v-8l-1041 21 1044-358v-8l-1047 359 1059-796v-10l-1074 808L1509 82l-8 1-316 1061-20-1076-8 1 19 1078L805 71l-8 1 371 1078L373 95c-1 3-3 5-4 8l800 1062L112 842v8l1042 319-1052 20v8l1052-20L92 1541v8l1064-365L95 1986v10l1066-806-726 1036v14l732-1045-333 1080 8-1z"/><g class="F"><path d="M767 75l382 1040L318 107v8l836 1039L89 867v11l1028 287-1014 64v10l1015-54-1007 398 1014-379-1000 845 1013-829-671 1030c4 6 8 12 14 16l674-1035-269 1040 22-1 267-1034 53 1040 21-2-53-1039 400 1046 21-2-402-1052 890 1083v-33l-874-1063 1063 678v-24l-1052-670 1054 284v-21l-1049-282 1016-77-1017 56 996-455-1003 435 1024-877-1063 882 281-1041-15 2-276 998m-14 92l7 1 7-2 6-4 5-6 3-7 1-7-2-8-2-4-9 7-10-7 4-15h-4v3l-10 2-4 2 7 9-7 10-11-3-1 5 2 7 4 6 6 5 7 3h0z" class="D"/><path d="M238 1109h445c36 0 65 27 65 60v33c0 33-29 60-65 60H238c-36 0-65-27-65-60v-33c0-33 29-60 65-60z"/></g><path d="M500 605c0-84 20-116 118-116s118 32 118 116-20 116-118 116-118-32-118-116zm59 0c0 50 8 66 60 66 51 0 60-17 60-66 0-50-8-66-60-66-51 0-60 17-60 66zm273 63h138v48H773V494h60v174zm226-174v222h-60V494h60zm101 133c-50 0-66-22-66-67 0-44 14-66 66-66h142v50h-130c-14 0-19 5-19 20 0 14 5 20 19 20h72c50 0 65 21 65 66s-15 67-65 67h-148v-50h136c13 0 19-6 19-21s-6-20-19-20h-72 0zm366 25V494h55v222h-73l-108-152v152h-55V494h71l111 158zm304-25h-145v42h146v48h-206V495h206v48h-146v42h145v43zm191-26l77 115h-66l-63-91h-38v91h-60V494h60v90h38l64-90h63l-75 107zM324 627c-50 0-66-22-66-67 0-44 14-66 66-66h142v50H336c-14 0-19 5-19 20 0 14 5 20 19 20h72c50 0 65 21 65 66s-15 67-65 67H260v-50h136c13 0 19-6 19-21s-6-20-19-20h-72 0z" class="B"/><g class="D"><path fill="#fb9d12" d="M1962 818h-15l-21-51-9 51h-15l13-76h15l21 51 9-51h15l-13 76h0zm64-31h-29l-5 31h-15l13-76h48l-2 13h-33l-3 20h29l-2 13zm74-32h-23l-11 64h-15l11-64h-22l2-13h60l-2 13z"/><path fill="#ccf" d="M1677 817c-1 0-2 0-2-1l2-10c0-1 1-1 2-1 6 0 10-1 12-2s3-3 3-6-1-7-3-13c-2-5-3-9-4-10-2-6-3-10-3-13s1-6 2-9 3-4 6-6c5-3 12-4 20-4 1 0 2 0 2 1l-2 10c0 1-1 1-2 1-8 0-12 2-12 6 0 3 2 9 5 18s5 15 5 19c0 15-11 22-32 22h0zm-67-1l-4-46s0-1 1-1h8c1 0 1 0 1 1l2 35 10-34v-1h1 8c1 0 1 0 1 1l-17 47s0 1-1 1h-9s-1 0-1-1h0zm53-20h-12l-2 13h15c1 0 1 0 1 1l-1 6s0 1-1 1l-24 1c-1 0-1 0-1-1l7-47s0-1 1-1l21-1c1 0 1 0 1 1l-1 6s0 1-1 1h-12l-2 12h12c1 0 1 0 1 1l-1 6s0 1-1 1h0zm116-53l-10 73c0 1-1 1-2 1l-12 1c-1 0-1 0-1-1l-13-52-4 51c0 1-1 1-2 1h-12c-1 0-1 0-1-1l10-73c0-1 1-1 2-1h12 1v1l12 49 4-48c0-1 1-1 2-1h12c1 0 2 0 2 1h0zm46 41l-19 1-3 20 23-1c1 0 2 0 2 1l-2 10c0 1-1 1-2 1l-37 1c-1 0-1 0-1-1l10-73c0-1 1-1 2-1l33-1c1 0 2 1 2 1l-2 10c0 1-1 1-2 1h-20l-3 18h19c1 0 2 0 2 1l-2 10c0 1-1 1-2 1h0zm65 32c0 1 0 1-2 1h-13c-1 0-1 0-1-1l-13-36-5 36c0 1-1 1-2 1h-12c-1 0-1 0-1-1l10-73v-1h1 12c1 0 2 0 2 1l-5 33 17-32c0-1 1-1 2-1h13c1 0 2 0 2 1v1l-20 33 15 39h0z"/></g><path d="M1181 788c230 0 416 186 416 416s-186 416-416 416-416-186-416-416 186-416 416-416z" class="B"/><path fill="#fed425" d="M1579 1205c0-220-178-397-397-397-220 0-397 178-397 397 0 220 178 397 397 397 220 0 397-178 397-397z"/><path d="M1175 1193l-118-362c-38 13-74 31-106 54l223 307zm-114-363l118 362V811c-41 0-80 7-118 19zm121-19v381l118-363c-37-12-77-18-118-18zm121 19l-118 363 225-309c-32-23-68-41-107-54zm110 56l-225 309 310-225c-11-15-24-30-38-43-15-15-31-28-48-41zm87 87l-310 225 365-119c-13-39-32-74-55-107zm56 110l-365 119h384c0-41-7-81-19-119zm19 122h-385l366 119c12-37 18-77 18-119h0zm-19 122l-366-119 312 227c23-32 42-69 55-108zm-57 110l-312-227 227 312c16-12 32-25 46-39s27-30 39-46zm-88 87l-227-312 119 366c39-13 75-31 108-55zm-111 56l-119-366v385c42 0 82-6 119-18zm-123 18v-385l-119 365c37 12 77 19 119 19zm-122-20l119-365-225 310c32 24 68 42 107 55zm-109-57l225-310-309 225c12 17 26 33 41 48 14 14 28 26 43 38zm-86-88l309-225-363 118c12 39 31 74 54 107zm-55-110l363-118H787h0c0 41 6 81 18 118zm-18-122h381l-362-118c-12 37-19 77-19 118zm20-121l362 118-308-223c-23 32-42 68-54 106zm56-109l308 223-223-307c-16 12-31 25-45 39s-27 29-39 45zm601-50c73 73 117 173 117 284s-45 211-117 284c-73 73-173 117-284 117s-211-45-284-117c-73-73-117-173-117-284s45-211 117-284c73-73 173-117 284-117s211 45 284 117z" class="D"/><g fill="none" stroke="#fb9d12" stroke-width="8.165"><path d="M1180 1203l116-380"/><path d="M1180 1203l228-326"/><path d="M1180 1203l317-239"/><path d="M1180 1203l376-130m-376 130l398-7m-398 7l380 116"/><path d="M1180 1203l326 228"/><path d="M1180 1203l239 317"/><path d="M1180 1203l129 376m-129-376l7 397m-7-397l-116 380"/><path d="M1180 1203l-228 325"/><path d="M1180 1203l-317 239"/><path d="M1180 1203l-376 129"/><path d="M1180 1203l-397 7m397-7l-380-116m380 116L855 975"/><path d="M1180 1203L941 885"/><path d="M1180 1203l-129-376"/><path d="M1180 1203l-7-398"/></g><g class="B"><path fill-opacity=".329" d="M1459 918l-559 559c38 37 83 67 133 87l517-516c-20-50-53-93-90-130h0z"/><path fill-opacity=".439" d="M1569 1290l-299 299c148-34 265-151 299-299zM958 882L848 997c-19 31-31 58-41 91l264-261c-34 9-80 31-113 54h0zm449-9l-552 552c6 9 13 18 20 26l557-559c-9-7-17-13-26-19z"/></g><path fill="#fed425" d="M1468 1195c0-159-129-288-288-288s-288 129-288 288 129 288 288 288 288-129 288-288z"/><path d="M1464 1195c0-78-32-150-83-201s-122-83-201-83c-78 0-150 32-201 83s-83 122-83 201c0 78 32 150 83 201s122 83 201 83c78 0 150-32 201-83s83-122 83-201zm-78-206c53 53 85 126 85 206 0 81-33 154-86 206-53 53-126 85-206 85-81 0-154-33-206-86-53-53-85-126-85-206 0-81 33-154 86-206 53-53 126-85 206-85 81 0 154 33 206 86z" class="D"/><path fill="#fb9d12" d="M908 1211c0-159 129-288 288-288 76 0 144 29 196 77-53-57-128-92-211-92-159 0-288 129-288 288 0 83 36 159 92 211-48-51-77-120-77-196h0z"/><path fill="#fdf995" d="M1472 1194c-15 171-146 293-316 288-4-1-17-1-17-1 89-52 100-214 100-214l188-268c34 56 51 124 45 195h0z"/><path d="M1474 1194c-7 86-44 160-101 212-56 51-132 81-217 79h-1c-4-1-16-1-16-1l-1-5c88-51 98-211 98-212v-1l188-268 2-3 2 3c17 29 31 61 38 94 7 32 10 65 7 99h0v3zm-105 208c55-50 91-122 99-206h0v-3c3-34 0-68-7-100s-20-62-36-89l-185 264c-1 11-13 156-94 211 3 0 7 1 9 1 84 2 158-27 213-77z" class="D"/><path fill="url(#B)" d="M909 1088l17 95c2 9 6 18 12 25l51 55c8 9 19 14 31 15l70 6h10l214-27c6-1 13-3 18-6l52-30c9-5 16-13 20-22l41-93c3-7 5-15 4-23l-5-90c-1-15-9-29-21-37l-86-59c-11-8-25-10-38-7l-111 24c-4 1-9 1-13 1l-158-9c-20-1-38 10-46 28l-60 126c-4 9-6 19-4 29h0z"/><path fill="url(#C)" d="M1391 1386c20-70 22-159 21-202l39-88-3-50c19 46 27 96 22 149-6 72-34 138-78 188l-2 4z"/><path d="M1033 1183c-3-1-7-4-9-8-5-7-6-15-1-19 4-3 12 0 17 7 2 4 4 7 4 11m139-14c1-3 3-7 6-10 6-6 14-8 18-5 4 4 2 12-4 18-3 3-7 5-10 6m-277-83l17 95h0c1 4 2 8 4 11 2 4 4 7 7 10h0l51 55h0c4 4 8 7 13 9s10 4 15 4l65 5c-11-10-15-21-17-27-20 0-34-1-34-1l1-10s75 8 113-18l2-1h2s118 24 212-30c2-4 10-19 6-40l10-2c5 29-8 48-8 48l-2 1c-34 20-70 29-104 34-1 5-3 15-10 26l58-7h0c3 0 5-1 8-2s5-2 8-3h0l52-30c4-2 7-5 10-8s5-7 7-11h0l41-93h0l3-9c1-3 1-7 1-10h0l-3-58-59-15-208 14 154-62 88 8 23 35-1-12h0c0-6-2-13-5-18-3-6-8-10-13-14l-86-59h0c-5-3-10-6-16-7s-11-1-17 0l-111 24h0c-2 0-5 1-7 1h0-7 0l-158-9c-9 0-17 2-24 6s-13 10-17 18h0l-12 26 5-3 139 62-138-14-37 21-8 18-5 28-3-10c-1 3-2 7-3 10-1 4-1 9 0 13h0zm316 231s81 40 175-50c2-23 2-44 3-61-2 3-4 6-7 9-4 4-8 8-13 11l-52 30h0c-3 2-6 3-10 4-3 1-7 2-11 2h0l-72 9c-8 7-19 13-34 17l7-14-94 12c4 7 7 11 7 11-11-2-20-5-28-8h-1 0-6-6 0l-70-6c-7-1-13-2-19-5s-11-7-16-12h0l-51-55h0c-4-4-6-8-9-13-2-5-4-10-5-15h0l-17-95h0c-1-6-1-11 0-17s2-11 5-16l5-10-14-44 49-30 20-43h0c5-10 12-18 21-24 9-5 20-8 31-8l158 9h0 5 0c2 0 4 0 6-1h0l111-24c7-2 15-2 22 0 7 1 14 4 20 9h0l86 59c7 5 13 11 17 18s6 15 7 24h0l2 33 3 4-2-1 1 21c8 22 14 44 18 68 4 25 5 51 2 77-3 36-12 71-25 103s-31 62-54 87l-2 4-8-3c2-7 4-15 6-23-118 86-185 28-185 28l4-5s65 56 183-33c4-19 7-39 9-58 1-5 1-10 1-15-95 87-177 47-177 46l3-6zm-114-42l106-13c3-9 6-19 5-27-38 1-68-4-76-5-13 8-29 13-45 16 0 9 5 20 10 29zm66-115h0 0zm-150 22h0 0zm-40 12l19-74 1-2h-4c-43-5-76-29-79-60l122-10 20-2 60-5c0 5 0 10-1 16 8-3 19-5 34-2-2-5-2-10-3-15l132-3 22-1 64-1c1 41-47 76-107 77h0-10 0c-7 0-14-1-20-2-35-6-63-24-75-48v1c-20-6-35 0-40 3-9 19-28 35-54 45l112-13h3l80 37-4 10-79-37-164 19-18 70-10-3zm419 99c-3 24-6 49-12 73 17-22 32-46 43-73 13-31 21-65 24-101 2-26 1-51-2-75-2-12-4-24-7-36h0 0c0 4 0 9-1 13s-2 8-4 12h0l-36 80c0 26 0 65-5 106z" class="D"/><path fill="#cc000a" d="M1180 1287c-8 94-91 163-184 155-4 0-7-1-11-1-15-2-29-6-42-12-4-2-9-4-13-6-39-21-69-57-82-100h12c13 1 24 5 35 10 0-2 1-4 1-6 2-10 6-19 11-27 21 40 62 69 110 73 21 2 42-1 61-8 48-18 84-63 88-117 1-6 1-13 0-19l10 1c3 10 4 19 5 30 1 9 1 19 0 28h0z"/><path d="M1183 1290c-5 47-28 87-61 115-34 29-79 44-126 40h0c-2 0-4 0-5-1-2 0-4 0-5-1-8-1-15-3-22-5s-14-5-21-8h0l-6-3c-2-1-5-2-7-3h0c-20-11-38-25-52-43-14-17-25-37-32-59l-1-4h4 6 6 0l18 3c5 1 9 3 14 5 0-1 0-2 1-2 1-5 3-10 5-14 2-5 4-9 7-13l3-4 2 4c11 20 26 37 45 49 18 12 40 20 63 22h0c10 1 20 1 30-1 10-1 20-4 29-7h0c24-9 45-25 60-45s24-43 27-70h0v-9-9-3h3l10 1h2l1 2c3 10 4 20 5 30h0c1 10 1 19 0 29v3h0zm-65 111c33-28 55-68 59-114v-3h0c1-8 1-17 0-25h0c-1-9-2-18-4-27l-4-1v6 10h0c-2 27-12 52-28 73s-38 37-63 47h0c-10 4-20 6-30 8-10 1-21 2-32 1h0c-24-2-46-10-65-23-18-12-33-28-44-47-1 3-3 5-4 8-2 4-3 9-4 13h0c0 1 0 2-1 3 0 1 0 2-1 3l-1 4-4-2c-5-3-11-5-16-6-6-2-11-3-17-3h0-6-2c7 20 17 38 30 53 14 17 31 31 50 41h0c2 1 4 2 7 3l6 3h0c6 3 13 5 20 7s14 4 21 5c2 0 3 0 5 1 2 0 4 0 5 1h0c46 4 89-11 122-39z" class="D"/><path fill="#fe0003" d="M1177 1260c-19 63-72 111-142 118-4 0-7 1-11 1-15 1-30-1-44-4-5-1-9-2-14-4-28-9-49-20-69-40 2-10 4-14 8-24 23 39 62 61 110 65 21 2 42-1 61-8 48-18 84-63 88-117 1-6 1-13 0-19l10 1c3 10 1 21 2 31z"/><path d="M1573 1204c0-108-44-206-115-277s-169-115-277-115-206 44-277 115-115 169-115 277 44 206 115 277 169 115 277 115 206-44 277-115 115-169 115-277zm-106-285c73 73 118 174 118 285s-45 212-118 285-174 118-285 118-212-45-285-118-118-174-118-285 45-212 118-285 174-118 285-118 212 45 285 118z" class="D"/><path d="M1507 1022c10 26 18 52 22 80l3 23c0 2 7 1 7-2-3-28-9-55-17-81-2-7-5-15-8-22-1-2-8 0-7 2h0 0zm-254 216c1 7-2 14-7 19-1 1 0 2 1 3s3 0 4-1c6-6 9-14 8-21 0-1-1-2-2-2s-3 1-3 2h0 0zm-171 34c2 1 3 4 5 6s5 4 8 6c5 4 11 7 17 9 1 0 3 0 4-1s1-2-1-2c-6-2-11-6-17-9-3-2-5-3-7-6-2-2-3-4-5-6-1-1-3 0-4 0-1 1-1 2 0 2h0 0zm166 23l-3 32v2c0 1 0-1 0 0v1c0 1 0 3-1 4 0 3-1 5-1 8l-3 16c-2 10-5 20-9 30-1 1-1 2-1 3 0 0-1 2 0 1 0 1-1 1-1 2-1 2-2 5-3 7-2 5-5 9-8 13-2 3-3 5-5 8 0 0 1-1 0 0l-1 1-2 2c-1 1-2 3-3 4-4 5-9 10-14 14-2 2-2 6 0 8s6 2 8 0c9-9 17-17 24-27 6-9 11-19 16-29 8-20 13-41 16-63 2-13 3-25 4-38 0-3-3-6-6-6s-6 3-6 6h0 0zm7-252c-8 12-16 25-22 38-1 3-1 6 2 8 3 1 6 1 8-2 6-13 14-26 22-38 2-3 1-7-2-8-3-2-6-1-8 2h0zm26 4c-1 2-1 4-2 6 0 1-1 2-1 3 0 0-1 2 0 1 0 1 0 1-1 1-2 4-4 8-6 11-2 4-4 7-6 11-1 2-2 4-4 5-1 1-1 2-2 2l-1 1-1 1c-2 2-3 6 0 8 2 2 6 3 8 0 12-15 20-31 26-48 1-3-1-6-4-7s-6 1-7 4h0 0zm-247 15c-4 6-6 13-9 20-1 3 1 6 4 7s6-1 7-4 2-6 3-8c0 1 0 1-1 1 1-4 3-7 5-10 1-3 1-6-2-8-3-1-6-1-8 2h0 0zm-21-4c-6 13-11 26-17 39-1 3-1 6 2 8 3 1 7 1 8-2 6-13 11-26 17-39 1-3 1-6-2-8-2-1-7-1-8 2h0zm-10-128c34 0 69 1 103 3 10 1 19 1 29 1 3 0 6-1 8-2s4-2 5-4c1-1 1-3 0-5-1-1-4-2-6-2-34-2-68-3-103-4-10 0-19 0-29-1-3 0-6 0-8 2-2 1-4 2-5 4-1 1-1 3 0 5 1 1 4 2 6 2h0 0zm388 147c2 0-2 0-1 0h1c1 0 2 1 3 1s1 0 1 1c1 0 2 1 0 0 1 0 2 1 3 1l9 6c-1 0-1-1-1-1l15 15c3 4 10 3 14 1 3-1 8-6 5-9-5-6-11-12-18-17-7-6-15-9-24-10-2 0-6 1-8 1-2 1-4 2-5 4s-1 3 0 5c2 2 4 2 6 2h0 0z" class="B"/><path fill="#17323f" d="M0 0h2362v2362H0V0zm290 135h1784c85 0 154 69 154 154v1801c0 85-69 154-154 154H290c-85 0-154-69-154-154V289c0-85 69-154 154-154z"/><path d="M1333 218c0 83-67 150-150 150s-150-67-150-150 67-150 150-150 150 67 150 150z" class="F"/><path fill="#e84142" d="M1313 217c0 73-59 131-131 131-73 0-132-59-132-131 0-73 59-132 132-132s131 59 131 132z"/><path d="M1139 277h-30c-6 0-10 0-11-1-2-1-3-3-3-6 0-2 1-5 5-10l74-131c3-6 5-8 7-9s5-1 7 0 4 4 7 9l15 27h0c3 6 5 9 6 12s1 7 0 11c-1 3-3 6-6 12l-39 69h0c-3 6-5 9-8 11-3 3-6 4-9 5s-7 1-14 1h0zm76 0h43c6 0 10 0 11-1 2-1 3-4 3-6s-1-5-4-10l-22-37h0c-3-5-5-8-6-9-2-1-5-1-7 0s-4 4-7 9l-22 37h0c-3 5-5 8-5 10s1 5 3 6 5 1 11 1z" class="B"/><text x="457" y="1726" class="B C E G">LOCKED AMOUNT:</text><text x="456" y="1909" class="B C E G">VOTE POWER:</text><text x="457" y="2085" class="B C E G">LOCK DURATION:</text><text x="458" y="1769" fill="#999" class="C H">SNEK TOKENS LOCKED INSIDE</text><text x="462" y="1951" fill="#999" class="C H">CURRENT VOTES ALLOWED</text><text x="458" y="2128" fill="#999" class="C H">DAYS REMAINING UNTIL FULL MATURITY</text><text x="1261" y="1739" class="B C E I">';
        output = string(
            abi.encodePacked(output, toString(_value / 1e18), '</text><text x="1264" y="1919" class="B C E I">')
        );
        output = string(
            abi.encodePacked(output, toString(_balanceOf / 1e18), '</text><text x="1264" y="2095" class="B C E I">')
        );
        output = string(
            abi.encodePacked(
                output,
                toString(_locked_end / 86400),
                '</text><text x="238" y="1217" font-size="91.445" class="B C E">'
            )
        );
        output = string(
            abi.encodePacked(
                output,
                "ID: ",
                toString(_tokenId),
                '</text><path d="M2099 281h-17l5-19c-3-1-5-3-5-6 0-4 4-7 9-7s9 3 9 7c0 3-2 5-5 6l5 19h0zm26-51h-69c-6 0-12 4-12 9v51c0 5 5 9 12 9h69c6 0 12-4 12-9v-51c0-5-5-9-12-9zm-59-22c0-11 10-21 23-21s23 9 23 21v23h12v-23c0-17-16-31-35-31s-35 14-35 31v23h12v-23zm33 73h-17l5-19c-3-1-5-3-5-6 0-4 4-7 9-7s9 3 9 7c0 3-2 5-5 6l5 19h0zm26-51h-69c-6 0-12 4-12 9v51c0 5 5 9 12 9h69c6 0 12-4 12-9v-51c0-5-5-9-12-9zm-59-22c0-11 10-21 23-21s23 9 23 21v23h12v-23c0-17-16-31-35-31s-35 14-35 31v23h12v-23z" class="B D"/></svg>'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        toString(_tokenId),
                        '", "description": "SNEK locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
    }
}