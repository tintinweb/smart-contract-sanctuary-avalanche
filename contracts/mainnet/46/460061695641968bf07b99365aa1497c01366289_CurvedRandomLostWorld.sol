/**
 *Submitted for verification at snowtrace.io on 2022-03-03
*/

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/utilities/IERC721EnumerableMintable.sol
pragma solidity ^0.8.10;

/**
 * @title IERC721EnumerableMintable
 * @author 0xLostArchitect
 *
 * @dev Interface for a mintable ERC721
 */
interface IERC721EnumerableMintable {
    function mint(address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}


// File contracts/interfaces/IERC721EnumerableMintable.sol
pragma solidity ^0.8.10;


// File contracts/utilities/IRandomNumberGenerator.sol
pragma solidity ^0.8.10;

/**
 * @title IRandomNumberGenerator
 * @author 0xLostArchitect
 *
 * @dev Interface for a contract that generates a random number
 */
interface IRandomNumberGenerator {
    function generateRandomNumber() external returns (uint256);
}


// File contracts/interfaces/IRandomNumberGenerator.sol
pragma solidity ^0.8.10;


// File contracts/RoyaltyDeterminers/IRoyaltyDeterminer.sol
pragma solidity ^0.8.10;

/**
 * @title IRoyaltyDeterminer
 * @author 0xLostArchitect
 *
 * @notice Determines what address to grant the royalty to
 */
interface IRoyaltyDeterminer {
    function determineRoyalty(bytes calldata royaltyInformation, address minter)
        external
        pure
        returns (address);
}


// File contracts/interfaces/IRoyaltyDeterminer.sol
pragma solidity ^0.8.10;


// File @openzeppelin/contracts/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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


// File @openzeppelin/contracts/token/ERC721/[email protected]
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;


/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal initializer {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal initializer {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}


// File contracts/structs/VerificationParams.sol
pragma solidity ^0.8.10;

/**
 * @dev Struct used for Signature Verification
 *
 * @dev See {SignatureVerifierBase}
 * {address} to_ - The `msg.sender` the signature was signed for
 * {address} for_ - What contract the signature is to be used on
 * {bytes} data_ - Variable byte data that will be verified in order to get the signature
 * {uint256} nonce_ - A nonce for uniqueness
 * {bytes} signature - The signature provided with the data to be unpacked to get the signer
 */
struct VerificationParams {
    address to_;
    address for_;
    bytes data_;
    uint256 nonce_;
    bytes signature;
}


// File contracts/factories/ISignatureProxyBeaconFactory.sol
pragma solidity ^0.8.10;

/**
 * @title ISignatureProxyBeaconFactory
 * @author 0xLostArchitect
 *
 * @notice Interface for a ProxyBeaconFactory with a single `create` function
 */
interface ISignatureProxyBeaconFactory {
    function create(bytes calldata signatureData_, bytes calldata data)
        external
        returns (address);
}


// File contracts/interfaces/ISignatureProxyBeaconFactory.sol
pragma solidity ^0.8.10;


// File @openzeppelin/contracts-upgradeable/access/[email protected]
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]
// OpenZeppelin Contracts v4.4.0 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;




/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
    uint256[49] private __gap;
}


// File contracts/inheritable/UpgradeableBase.sol
pragma solidity ^0.8.10;

// External


/**
 * @title UpgradeableBase
 * @author 0xLostArchitect
 *
 * @notice Abstract contract that underlies any LostWorlds contract that will be upgradeable
 *
 * @dev Two primary pieces of functionality:
 * - Set up proper inheritance
 * - Set an initial `DEFAULT_ADMIN_ROLE` for `msg.sender`
 *
 * Inherits:
 * - Initializable - All upgradeable contracts should follow `initializability` pattern as opposed to `constructor` based
 * - AccessControlEnumerableUpgradeable - All LostWorlds contract should have RBAC
 */
abstract contract UpgradeableBase is
    Initializable,
    AccessControlEnumerableUpgradeable
{
    // Add to protect against UUPS threat
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initiailization function called from the Proxy pattern
     *
     * @dev Call from any contract in it's initialization function that inherits this contract
     * @dev WARNING: Due to the use of `msg.sender`, this should NOT be used in any contract that is created via a factory
     *
     * @dev Sets up a base `DEFAULT_ADMIN_ROLE` for the `msg.sender`
     */
    function __UpgradeableBase_init() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}


// File contracts/storage/ERC721EnumerableMintableStorage.sol
pragma solidity ^0.8.10;

/**
 * @title ERC721EnumerableMintableStorage
 * @author 0xLostArchitect
 *
 * @notice Storage for any ERC721EnumerableMintableStorage
 */
contract ERC721EnumerableMintableStorage {
    /* CONSTANTS */
    /**
     * @dev MINTER_ROLE only granted to a single contract that can mint this 721
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /* STATE VARIABLES */
    /**
     * @dev Base imageURI used for the ERC721's image in its metadata
     */
    string public imageURI;
}


// File contracts/utilities/ERC721EnumerableMintable.sol
pragma solidity ^0.8.10;

// External


// Inherits


/**
 * @title ERC721EnumerableMintable
 * @author 0xLostArchitect
 *
 * @notice Contract that implements a permissioned ERC721
 *
 * @dev Used for royalty tokens in the LostWorlds system
 *
 * Inherits:
 * - ERC721EnumerableUpgradeable - Base enumerable 721 functionality
 * - ERC721EnumerableMintableStorage - Use `storage` pattern to put all structs, state variables, and events elsewhere for upgradeability
 * - UpgradeableBase - For upgradeability on the contract
 */
contract ERC721EnumerableMintable is
    ERC721EnumerableUpgradeable,
    ERC721EnumerableMintableStorage,
    UpgradeableBase
{
    /* Libraries */
    using StringsUpgradeable for *;

    /**
     * @dev Initialization function
     *
     * @dev No need to use `__UpgradeableBase_init` because `msg.sender` is the factory
     *
     * @param name - Name for the 721
     * @param symbol - Symbol for the 721
     * @param imageURI_ - Link to the external image
     * @param minter - The address for the initial MINTER_ROLE
     */
    function initialize(
        string memory name,
        string memory symbol,
        string memory imageURI_,
        address minter
    ) public initializer {
        // Set up initial ERC721
        __ERC721_init(name, symbol);

        // Set the imageURI
        imageURI = imageURI_;

        // Set up the MINTER_ROLE
        _setupRole(MINTER_ROLE, minter);
    }

    /**
     * @notice Mints a new token with `tokenId` for `to`.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 tokenId)
        external
        virtual
        onlyRole(MINTER_ROLE)
    {
        _mint(to, tokenId);
    }

    /**
     * @notice Returns a JSON URI for this `tokenId`
     *
     * @dev Constructs the entire JSON out of configurable libraries
     * @dev Follows UNISwap V3 `NFTDescriptor` model
     * @dev Uses `data:application/json` so a `fetch` to the `URL` just returns the data itself
     *
     * @param tokenId- The tokenId to the get the metadata for
     * @return {string} - A data URL will all the metadata inside of a wrapped JSON
     *
     * Requirements:
     *
     * -The `tokenId` exists, i.e. has been minted
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json,",
                    '{"name":"',
                    name(),
                    '", "symbol":"',
                    symbol(),
                    '", "tokenId":',
                    StringsUpgradeable.toString(tokenId),
                    ', "image": "',
                    imageURI,
                    '"}'
                )
            );
    }

    /* Support for ERC165 */
    /**
     * @notice Overrides `supportInterface` to account for all inherited packages
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721EnumerableUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


// File contracts/structs/CompletionStruct.sol
pragma solidity ^0.8.10;

/**
 * @dev Used for completion events in the LostWorlds Ecosystem
 */
struct CompletionStruct {
    address completionChecker;
    address completionExecutor;
    bytes preExecuteStep;
}


// File contracts/inheritable/ICompleter.sol
pragma solidity ^0.8.10;

// Structs

/**
 * @title ICompleter
 * @author 0xLostArchitect
 *
 * @dev Interface for the Completer
 */
interface ICompleter {
    function registerCompletionStruct(
        CompletionStruct calldata completionStruct
    ) external;

    function checkCompletionForAddress(address address_, bytes memory data)
        external
        view
        returns (bool);

    function executeCompletion(
        bytes calldata checkData,
        bytes calldata completionData
    ) external payable;
}


// File contracts/interfaces/ICompleter.sol
pragma solidity ^0.8.10;


// File contracts/CompletionCheckers/ICompletionChecker.sol
pragma solidity ^0.8.10;

/**
 * @title ICompletionChecker
 * @author 0xLostArchitect
 *
 * @notice Interface to check some condition on an address to be used in the context of a `Completer`
 */
interface ICompletionChecker {
    function checkCompletion(address, bytes calldata)
        external
        view
        returns (bool);
}


// File contracts/interfaces/ICompletionChecker.sol
pragma solidity ^0.8.10;


// File contracts/CompletionExecutors/ICompletionExecutor.sol
pragma solidity ^0.8.10;

/**
 * @title ICompletionChecker
 * @author 0xLostArchitect
 *
 * @notice Interface to execute some completion event to be used in the context of a `Completer`
 */
interface ICompletionExecutor {
    function executeCompletion(bytes calldata data) external payable;
}


// File contracts/interfaces/ICompletionExecutor.sol
pragma solidity ^0.8.10;


// File contracts/storage/CompleterStorage.sol
pragma solidity ^0.8.10;

/**
 * @title CompleterStorage
 * @author 0xLostArchitect
 *
 * @dev Storage for any Completer contract
 */
contract CompleterStorage {
    /* STATE VARIABLES */

    /**
     * @dev Maps an address that wants some completion struct to its completion struct
     *
     * @dev The most basic example is the marketplace's "big pay day".
     * @dev The marketplace registers itself on every LostWorld that has a big day
     */
    mapping(address => CompletionStruct) public completionStructs;

    /* EVENTS */

    /**
     * @dev Emitted upon the successful register of a new completion struct
     *
     * {address} register - The contract that wants to register on this completer
     * {address} completionChecker - The address of the contract that checks for the completion status
     * {address} completionChecker - The address of the contract that actually executes the completion struct
     */
    event RegisteredCompletionStruct(
        address register,
        address completionChecker,
        address completionExecutor
    );

    /**
     * @dev Emitted upon the successful unregister of a new completion struct
     *
     * {address} register - The contract that unregistered itself
     */
    event UnregisteredCompletionStruct(address register);

    /**
     * @dev Emitted upon the successful completion of a new completion struct
     *
     * {address} register - The contract that just executed its completion
     */
    event ExecutedCompletionStruct(address register);
}


// File contracts/inheritable/Completer.sol
pragma solidity ^0.8.10;

// External

// Interfaces



// Inherits

/**
 * @title Completer
 * @author 0xLostArchitect
 *
 * @notice A contract that is capable of storing different checks and execution action items depending on its state
 *
 * @dev This implementation was initially used for the big payday functionality of the `LostWorldsMarketplace`, but opens up quite
 * @dev a variety of interesting use cases for either individual or collective completion conditions.
 *
 * Inherits:
 * - CompleterStorage - Use `storage` pattern to put all structs, state variables, and events elsewhere for upgradeability
 * - ICompleter - Ensure the interface is always held
 */
contract Completer is CompleterStorage, ICompleter {
    /**
     * @notice Used to register a new completion for `msg.sender`
     *
     * @dev This should only be called by a contract
     *
     * @dev See {LostWorldsMarketplace-registerNewCompleter} for an example implementation
     *
     * @param completionStruct - The struct that represents what this `msg.sender` wants to register
     *
     * Requirements:
     *
     * - `msg.sender` hasn't yet registered an event
     *
     * Emits:
     *
     * - RegisteredCompletionStruct(msg.sender, completionChecker, completionExector);
     */
    function registerCompletionStruct(
        CompletionStruct calldata completionStruct
    ) external {
        require(
            completionStructs[msg.sender].completionChecker == address(0),
            "RCS::completion-struct-exists"
        );
        completionStructs[msg.sender] = completionStruct;

        emit RegisteredCompletionStruct(
            msg.sender,
            completionStruct.completionChecker,
            completionStruct.completionExecutor
        );
    }

    /**
     * @notice Used to unregister the completionStruct for `msg.sender`
     *
     * Requirements:
     *
     * - `msg.sender` has an event registered
     *
     * Emits:
     *
     * - UnregisteredCompletionStruct(msg.sender);
     */
    function unregisterCompletionStruct() external {
        require(
            completionStructs[msg.sender].completionChecker != address(0),
            "RCS::completion-struct-exists"
        );

        delete completionStructs[msg.sender];

        emit UnregisteredCompletionStruct(msg.sender);
    }

    /**
     * @notice Determines whether or not `address_` has completed its check
     *
     * @param address_ - The address to check the completion of
     * @param data_ - The data potentially needed for the completionCheck
     *
     * @return bool - Whether or not the check is complete
     */
    function checkCompletionForAddress(address address_, bytes memory data_)
        public
        view
        returns (bool)
    {
        return
            ICompletionChecker(completionStructs[address_].completionChecker)
                .checkCompletion(address(this), data_);
    }

    /**
     * @notice Executes the completion for `msg.sender`
     *
     * @param checkData - Any data needed for the check
     * @param completionData - Any data potentially needed for the completionEvENT
     *
     * Requirements:
     *
     * - `msg.sender` has something registered
     * - `msg.sender` has completed its check
     *
     * Emits:
     *
     * - ExecutedCompletionStruct(msg.sender)
     */
    function executeCompletion(
        bytes calldata checkData,
        bytes calldata completionData
    ) external payable {
        require(
            completionStructs[msg.sender].completionChecker != address(0),
            "EC::non-existent "
        );
        require(
            checkCompletionForAddress(msg.sender, checkData),
            "EC::not-complete"
        );

        /*
         * Unpack whatever needs to be done immediately before `executionCompletion`
         */
        (address target, bytes memory functionData) = abi.decode(
            completionStructs[msg.sender].preExecuteStep,
            (address, bytes)
        );

        AddressUpgradeable.functionCall(target, functionData);

        // Always send the balance to the execute step
        ICompletionExecutor(completionStructs[msg.sender].completionExecutor)
            .executeCompletion{value: address(this).balance}(completionData);

        emit ExecutedCompletionStruct(msg.sender);
    }

    /**
     * @dev Set up a `recieve` function so that the contract can recieve the gas token of the chain
     */
    receive() external payable virtual {}
}


// File contracts/VariationSelectors/IVariationSelector.sol
pragma solidity ^0.8.10;

/**
 * @title IVariationSelector
 * @author 0xLostArchitect
 *
 * @notice Interface for a contract that selects a variation id based off of a tokenId
 */
interface IVariationSelector {
    function selectVariation(uint256 tokenId) external view returns (uint256);
}


// File contracts/DividendHandlers/IDividendHandler.sol
pragma solidity ^0.8.10;

/**
 * @title IDividendHandler
 * @author OxLostArchitect
 *
 * @notice Interface to handle a collection of dividends for a list of `tokenIds`
 */
interface IDividendHandler {
    function handleDividend(uint256[] calldata tokenIds) external payable;
}


// File contracts/inheritable/ISingleByteHandler.sol
pragma solidity ^0.8.10;

/**
 * @title ISingleByteHandler
 * @author 0xLostArchitect
 *
 * @notice Broad interface that defines a single function used to `interpret` one piece of byte data
 *
 * @dev Often inherited by `library`-style contracts that only implement a single function (namely, `interpretBytes`),
 * @dev for a very specific purpose, such as constructing a semi-parseable string to be used in a tokenURI
 */
interface ISingleByteHandler {
    function interpretBytes(bytes calldata)
        external
        pure
        returns (string memory);
}


// File contracts/inheritable/ITwoBytesHandler.sol
pragma solidity ^0.8.10;

/**
 * @title ITwoBytesHandler
 * @author 0xLostArchitect
 *
 * @notice Broad interface that defines a single function used to `interpret` two pieces of byte data
 *
 * @dev Often inherited by `library`-style contracts that only implement a single function (namely, `interpretBytes`),
 * @dev for a very specific purpose, such as constructing a semi-parseable string to be used in a tokenURI
 */
interface ITwoBytesHandler {
    function interpretBytes(bytes calldata, bytes calldata)
        external
        pure
        returns (string memory);
}


// File contracts/SignatureVerifiers/ISignatureVerifier.sol
pragma solidity ^0.8.10;

// Structs

/**
 * @title ISignatureVerifier
 * @author 0xLostArchitect
 *
 * @notice Interface to interact with a contract that produces message hashes and verifies signatures
 */
interface ISignatureVerifier {
    /* Used for getting the hash messaged needed for the signature verification */
    function getMessageHash(
        address to_,
        address for_,
        bytes calldata data_,
        uint256 nonce_
    ) external pure returns (bytes32);

    function getSignerFromVerificationParams(
        address to_,
        address for_,
        bytes calldata data_,
        uint256 nonce_,
        bytes calldata signature
    ) external pure returns (address);

    function verifySignature(VerificationParams calldata, address)
        external
        view;
}


// File contracts/structs/AddressHolder.sol
pragma solidity ^0.8.10;

// Inheritable






/**
 * @dev Used to hold the addresses of all the configurable addresses
 *
 * @dev This struct is less about compact management of information and more for decreasing number of variables on the stack
 */
struct AddressHolder {
    IRoyaltyDeterminer royaltyDeterminer;
    ISingleByteHandler variationInterpreter;
    ISingleByteHandler contextInterpreter;
    ISingleByteHandler metadataInterpreter;
    ITwoBytesHandler imageInformationInterpreter;
    ISignatureVerifier signatureVerifier;
    IDividendHandler dividendHandler;
    IVariationSelector variationSelector;
}


// File contracts/structs/QuantityRange.sol
pragma solidity ^0.8.10;

/**
 * @dev Represents the `value` of something up to a certain limit
 *
 * {uint256} upperLimit - The upper limit for this range
 * {uint256} value - The value to be used for this range
 */
struct QuantityRange {
    uint256 upperLimit;
    uint256 value;
}


// File contracts/structs/InitializationParams.sol
pragma solidity ^0.8.10;

/**
 * @dev Describes the struct needed to initialize any LostWorld
 *
 * {string} name_ - Name for the 721
 * {string} symbol_ - Symbol for the 721
 * {bytes} imageLinkInformation_ - The information needed to form the imageLink
 * {bytes} metadata_ - The information needed to form the metadata
 * {bytes} royaltyDeterminerInformation_ - The information needed to determine the royalties on every mint
 * {bytes} signatureData_ - The data needed in the `TokenFactory`
 * {string} royaltyTokenImageURI_ - The imageURI used on the royaltyToken
 * {address} admin_ - The initial admin for the `LostWorld`
 * {address} wallet_ - The wallet to send the AVAX to on purchase
 * {uint16} royaltyBeeps_ - The basis points to be used for the royalty on this LostWorld
 * {ISignatureProxyBeaconFactory} tokenFactory_ - The address of the token factory needed for the royalty token
 */
struct InitializationParams {
    string name_;
    string symbol_;
    bytes imageLinkInformation_;
    bytes metadata_;
    bytes royaltyDeterminerInformation_;
    bytes signatureData_;
    string royaltyTokenImageURI_;
    address admin_;
    address wallet_;
    uint16 royaltyBeeps_;
    ISignatureProxyBeaconFactory tokenFactory_;
}


// File contracts/structs/Variation.sol
pragma solidity ^0.8.10;

/**
 * @dev Describes a single NFT within a LostWorld with its own unique data
 *
 * {uint16} amount - The amount of this variation the LostWorld has
 * {bytes} data - Some variable amount of byte data associated with the variation itself
 */
struct Variation {
    uint16 amount;
    bytes data;
}


// File contracts/storage/LostWorldBaseStorage.sol
pragma solidity ^0.8.10;

// interfaces


// Structs




/**
 * @title LostWorldBaseStorage
 * @author 0xLostArchitect
 *
 * @notice Storage for any LostWorldBase
 */
abstract contract LostWorldBaseStorage {
    /* CONSTANTS */

    /**
     @dev Used interface used to implement ERC2981
     */
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev RBAC Role to determine who is a valid signer for this world
     */
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /* STATE VARIABLES */

    /**
     * @dev The metadata used by the `metadataInterpreter` to describe metadata for the entire LostWorld
     */
    bytes public metadata;

    /**
     * @dev The information passed to the `royaltyDeterminer` to determine who recieves the NFT royalty for a given mint
     */
    bytes public royaltyDeterminerInformation;

    /**
     * @dev Determines which address determines the royalty
     */
    IRoyaltyDeterminer public royaltyDeterminer;

    /**
     * @dev Address that interprets the variation
     */
    ISingleByteHandler public variationInterpreter;

    /**
     * @dev Address that interprets the context
     */
    ISingleByteHandler public contextInterpreter;

    /**
     * @dev Address that interprets the metadata
     */
    ISingleByteHandler public metadataInterpreter;

    /**
     * @dev Address that handles all image information
     */
    ITwoBytesHandler public imageInformationInterpreter;

    /**
     * @dev Address that determines + verifies the signatures
     */
    ISignatureVerifier public signatureVerifier;

    /**
     * @dev Address to send dividends to
     */
    IDividendHandler public dividendHandler;

    /**
     * @dev Address that will select which variation a tokenId belongs to
     */
    IVariationSelector public variationSelector;

    /**
     * @dev Byte information that holds all links holding images for this LostWorld
     */
    bytes public imageLinkInformation;

    /**
     * @dev Wallet to pay on every mint
     */
    address public wallet;

    /**
     * @dev Basis points to use as the royalty
     */
    uint256 public royaltyBeeps;

    /**
     * @dev Array of all variations used for this `LostWorld`
     *
     * @dev Keep as array in order to iterate
     */
    Variation[] internal _variations;

    /**
     * @dev Basis points to reflect to share holders on all mints
     */
    QuantityRange[] internal _dividendLevels;

    /**
     * @dev The index of the dividend index
     */
    uint256 internal _dividendLevelIndex;

    /**
     * @dev Map a tokenId to the context in which it was minted
     */
    mapping(uint256 => bytes) public tokenMintContext;

    /**
     * @dev Address of the token that holds royalties for this `LostWorld`
     */
    IERC721EnumerableMintable public royaltyToken;

    /**
     * @dev The max supply of all tokens for this `LostWorld`
     */
    uint256 public maxSupply;

    /* EVENTS */

    /**
     * @dev Emitted on initialization with all constructors passed in
     */
    event Initialized(
        InitializationParams initializationParams_,
        AddressHolder addressHolder_,
        Variation[] variations_,
        QuantityRange[] dividendLevels
    );

    /**
     * @dev Emitted when we have a new dividend level
     */
    event NewDividendLevelIndex(uint256);
}


// File contracts/LostWorlds/LostWorldBase.sol
pragma solidity ^0.8.10;

// External




// Structs

// Interfaces

// Needs

// Inherits



/**
 * @title LostWorldsBase
 * @author 0xLostArchitect
 *
 * @dev Abstract contract to common functionality needed for LostWorlds
 *
 * @dev Derived implementations should implement both pricing mechanisms and token selection mechanisms.
 *
 * Inherits:
 * - Completer - To allow for completion events to be registered on the 721
 * - ERC721EnumerableUpgradeable - To provide base 721 functionality
 * - ERC165StorageUpgradeable - To register interfaces (such as IERC2981 - Royalty Standard)
 * - LostWordsBaseStorage - Use `storage` pattern to put all structs, state variables, and events elsewhere for upgradeability
 * - UpgradeableBase - For RBAC + initializability
 */
abstract contract LostWorldBase is
    Completer,
    ERC721EnumerableUpgradeable,
    ERC165StorageUpgradeable,
    LostWorldBaseStorage,
    UpgradeableBase
{
    /* Libraries */
    using StringsUpgradeable for *;

    /* Abstract functions */

    /**
     * @dev Internal function determine if the LostWorld is at full mint
     */
    function isFullyMinted() public view virtual returns (bool);

    /**
     * @dev Internal function used to calculate how much something costs to mint
     *
     * @dev No argument name is given with the idea being that the overriding function could pass in a count, a tokenId, etc
     */
    function getCostToMint(uint256) public view virtual returns (uint256);

    /**
     * @dev Internal function used to do the core minting state management
     *
     * @dev Most implementations should include the minting itself, the ids returned, and any pricing state management
     *
     * @dev No argument name is given with the idea being that the overriding function could pass in a count, a tokenId, etc
     */
    function _mintAndGetTokenIds(bytes calldata, uint256)
        internal
        virtual
        returns (uint256[] memory);

    /**
     * @dev Initialization function for any LostWorld
     *
     * @dev NOTE: Any LostWorld that overrides this base should call this function
     *
     * @param initializationParams_ - Contains all static attributes, initial RBAC, and royalty information
     * @param addressHolder_ - Contains addresses for all external libraries used
     * @param variations_ - All the variation information for the LostWorld
     * @param dividendLevels_ - The dividendLevels for the LostWorld
     */
    function __LostWorldBase_init(
        InitializationParams calldata initializationParams_,
        AddressHolder calldata addressHolder_,
        Variation[] calldata variations_,
        QuantityRange[] calldata dividendLevels_
    ) internal initializer {
        // Call super
        __ERC721_init(
            initializationParams_.name_,
            initializationParams_.symbol_
        );

        // Ensures ERC2981 standard (royalties)
        _registerInterface(_INTERFACE_ID_ERC2981);

        // Set all state attributes
        _initializeLostWorlds(initializationParams_, addressHolder_);

        // Create the variations + maxSupply
        uint256 supply;
        for (uint256 i; i < variations_.length; i++) {
            _variations.push(variations_[i]);
            supply += variations_[i].amount;
        }
        maxSupply = supply;

        // Create the dividendLevels
        for (uint256 i; i < dividendLevels_.length; i++)
            _dividendLevels.push(dividendLevels_[i]);

        // Emit an initialization event
        emit Initialized(
            initializationParams_,
            addressHolder_,
            variations_,
            dividendLevels_
        );
    }

    /**
     * @dev Internal function to handle `initializationParams_` and all external `libraries` used
     *
     * @param initializationParams_ - Contains all static attributes, initial RBAC, and royalty information
     * @param addressHolder_ - Contains addresses for all external libraries used
     */
    function _initializeLostWorlds(
        InitializationParams calldata initializationParams_,
        AddressHolder calldata addressHolder_
    ) internal {
        // Set consistent attributes
        metadata = initializationParams_.metadata_;
        royaltyDeterminerInformation = initializationParams_
            .royaltyDeterminerInformation_;
        imageLinkInformation = initializationParams_.imageLinkInformation_;
        wallet = initializationParams_.wallet_;
        royaltyBeeps = initializationParams_.royaltyBeeps_;

        // Set access control
        _setupRole(DEFAULT_ADMIN_ROLE, initializationParams_.admin_);
        _setupRole(SIGNER_ROLE, initializationParams_.admin_);

        /*
         * Make a royalty token on the fly with this method to ensure proper RBAC is maintained.
         * The difficulty is that we only want this contract to be able to `mint` the royalty token,
         * so therefore it must be set up from this token itself.
         *
         * The two arguments to create include the signature to prove that this contract has permissions
         * to use the factory, and the second is the information needed for instantiation of the royaltytoken.
         */
        royaltyToken = IERC721EnumerableMintable(
            initializationParams_.tokenFactory_.create(
                initializationParams_.signatureData_,
                abi.encodeWithSelector(
                    ERC721EnumerableMintable.initialize.selector,
                    initializationParams_.name_,
                    initializationParams_.symbol_,
                    initializationParams_.royaltyTokenImageURI_,
                    address(this)
                )
            )
        );

        // Set addresses for all external libraries used
        royaltyDeterminer = addressHolder_.royaltyDeterminer;
        variationInterpreter = addressHolder_.variationInterpreter;
        contextInterpreter = addressHolder_.contextInterpreter;
        metadataInterpreter = addressHolder_.metadataInterpreter;
        imageInformationInterpreter = addressHolder_
            .imageInformationInterpreter;
        signatureVerifier = addressHolder_.signatureVerifier;
        dividendHandler = addressHolder_.dividendHandler;
        variationSelector = addressHolder_.variationSelector;
    }

    /**
     * @notice Mint LostWorlds
     *
     * @dev Use a `template` style design pattern consisting of:
     * - Verification
     * - Price to mint
     * - Which token ids to select
     * - How to handle the dividends
     *
     * @param verificationParams - The params needed to verify the signature and supply the `contextData`
     * @param value - Value needed for minting, keeping it broad enough to be interpreted by a derived contract
     */
    function mint(VerificationParams calldata verificationParams, uint256 value)
        external
        payable
    {
        require(!isFullyMinted(), "M::fully-minted");
        signatureVerifier.verifySignature(verificationParams, msg.sender);

        // Handle proper cost
        uint256 total = getCostToMint(value);
        require(msg.value >= total, "M::insufficient-funds");

        // Call implementation to get what tokenIds where minted
        uint256[] memory tokenIds = _mintAndGetTokenIds(
            verificationParams.data_,
            value
        );

        // Handle all dividends
        uint256 dividendAmount = (msg.value *
            _dividendLevels[_dividendLevelIndex].value) / 10000;

        if (dividendAmount > 0)
            dividendHandler.handleDividend{value: dividendAmount}(tokenIds);

        // Update the _dividendLevelIndex if we've hit the limit
        if (totalSupply() == _dividendLevels[_dividendLevelIndex].upperLimit) {
            _dividendLevelIndex++;
            emit NewDividendLevelIndex(_dividendLevelIndex);
        }

        // Send payment to LostWallet
        AddressUpgradeable.sendValue(
            payable(wallet),
            msg.value - dividendAmount
        );
    }

    /* Accessors */

    /**
     * @notice View function to return all variations
     */
    function dividendLevels() external view returns (QuantityRange[] memory) {
        return _dividendLevels;
    }

    /**
     * @notice View function to return all variations
     */
    function variations() external view returns (Variation[] memory) {
        return _variations;
    }

    /**
     * @notice Returns a JSON URI for this `tokenId`
     *
     * @dev Constructs the entire JSON out of configurable libraries
     * @dev Follows UNISwap V3 `NFTDescriptor` model
     * @dev Uses `data:application/json` so a `fetch` to the `URL` just returns the data itself
     *
     * @param tokenId- The tokenId to the get the metadata for
     * @return {string} - A data URL will all the metadata inside of a wrapped JSON
     *
     * Requirements:
     *
     * -The `tokenId` exists, i.e. has been minted
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory tokenMetadata = metadataInterpreter.interpretBytes(
            metadata
        );

        string memory tokenContext = contextInterpreter.interpretBytes(
            tokenMintContext[tokenId]
        );

        bytes memory variationData = _variations[
            variationSelector.selectVariation(tokenId)
        ].data;

        string memory tokenVariation = variationInterpreter.interpretBytes(
            variationData
        );

        // Ensure we add a common after every call because the libraries just return their information
        return
            string(
                abi.encodePacked(
                    "data:application/json,",
                    abi.encodePacked(
                        '{"tokenId":',
                        StringsUpgradeable.toString(tokenId),
                        ",",
                        bytes(tokenMetadata).length > 0
                            ? string(abi.encodePacked(tokenMetadata, ","))
                            : "",
                        bytes(tokenContext).length > 0
                            ? string(abi.encodePacked(tokenContext, ","))
                            : "",
                        bytes(tokenVariation).length > 0
                            ? string(abi.encodePacked(tokenVariation, ","))
                            : "",
                        imageInformationInterpreter.interpretBytes(
                            imageLinkInformation,
                            variationData
                        ),
                        "}"
                    )
                )
            );
    }

    /**
     * @notice Returns royalty info for the NFT
     *
     * @dev Given that every token corresponds to a corresponding NFT Royalty Token, check the owner of that token to determine royalties
     * @dev Regardless of the variation, take `royaltyBeeps` of the sale
     *
     * @param tokenId - The tokenId to get the royalty of
     * @param _salePrice - The price of the sale
     * @return address - The address to send the royalty to
     * @return royaltyAmount - The amount to send to send the royaltyReciever
     */
    function royaltyInfo(uint256 tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        return (
            royaltyToken.ownerOf(tokenId),
            (_salePrice * royaltyBeeps) / 10000
        );
    }

    /* Support for ERC165 */
    /**
     * @notice Overrides `supportInterface` to account for all inherited packages
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165StorageUpgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


// File contracts/LostWorlds/ICurvedLostWorldBase.sol
pragma solidity ^0.8.10;

// Structs

/**
 * @title ICurvedLostWorldBase
 * @author 0xLostArchitect
 *
 * @notice Interface for the `CurvedLostWorldBase` that has price ranges
 */
interface ICurvedLostWorldBase {
    function priceRanges() external view returns (QuantityRange[] memory);

    function tokensLeftInRange() external view returns (uint256);
}


// File contracts/storage/CurvedLostWorldBaseStorage.sol
pragma solidity ^0.8.10;

// Structs

/**
 * @title CurvedLostWorldBaseStorage
 * @author 0xLostArchitect
 *
 * @notice Storage for any CurvedLostWorldBase
 *
 * @dev Adds information just needed for pricing information
 */
contract CurvedLostWorldBaseStorage {
    /* CONSTANTS */

    /**
     * @dev Constant to register to show that that `PRICE_RANGES` interface is implemented
     *
     * @dev `bytes4(keccack256("priceRanges()")) == 0x01518409`
     */
    bytes4 internal constant _INTERFACE_PRICE_RANGES = 0x01518409;

    /* STATE VARIABLES */

    /**
     * @dev The index of the current price range to be used for pricing
     */
    uint256 internal _priceRangeIndex;

    /**
     * @dev Array of all the different PriceRanges used for this `LostWorld`
     */
    QuantityRange[] internal _priceRanges;

    /* EVENTS */

    /**
     * @dev Emitted when we have a new price range
     */
    event NewPriceRangeIndex(uint256);
}


// File contracts/LostWorlds/CurvedLostWorldBase.sol
pragma solidity ^0.8.10;

// Inherits



/**
 * @title CurvedLostWorldBase
 * @author 0xLostArchitect
 *
 * @notice Abstract contract that implements a LostWorldBase with a method for pricing
 *
 * @dev Contract stays abstract because all LostWorlds need both a method for pricing and for id selection,
 * @dev and this contract only implements the former.
 *
 * @dev See {LostWorldBase}
 *
 * @dev Name `curved` is used because it prices its assets on a bonding `curve`
 * @dev This are no inherent rules on how the curve should be implemented, and care should be taken off-chain
 * @dev to ensure the proper values are initialized.
 *
 * @dev Theoretically, any `one-of-one` could use this pattern
 *
 * Inherits:
 * - CurvedLostWorldBaseStorage - Use `storage` pattern to put all structs, state variables, and events elsewhere for upgradeability
 * - LostWorldBase - Implements all LostWorldBase functionality
 * - ICurvedLostWorldBase - To ensure interface compatibility
 */
abstract contract CurvedLostWorldBase is
    CurvedLostWorldBaseStorage,
    LostWorldBase,
    ICurvedLostWorldBase
{
    /**
     * @dev Initialization function for any CurvedLostWorld
     *
     * @dev See {LostWorldBase-__LostWorldBase_init}
     *
     * @dev Responsibilities:
     * - Call base initialization function
     * - Register the needed interface
     * - Set up the actual price ranges
     *
     * @param priceRanges_ -  Needed to initialize the price ranges for the bonding curve mechanism
     */
    function __CurvedLostWorldBase_init(
        InitializationParams calldata initializationParams_,
        AddressHolder calldata addressHolder_,
        Variation[] calldata variations_,
        QuantityRange[] calldata dividendLevels_,
        QuantityRange[] calldata priceRanges_
    ) internal initializer {
        __LostWorldBase_init(
            initializationParams_,
            addressHolder_,
            variations_,
            dividendLevels_
        );

        // Register its interface
        _registerInterface(_INTERFACE_PRICE_RANGES);

        // Create the priceRanges
        for (uint256 i; i < priceRanges_.length; i++)
            _priceRanges.push(priceRanges_[i]);
    }

    /**
     * @notice View function to return all priceRanges
     */
    function priceRanges() external view returns (QuantityRange[] memory) {
        return _priceRanges;
    }

    /**
     * @notice Determine how many tokens are left in the current price range
     */
    function tokensLeftInRange() public view returns (uint256) {
        return _priceRanges[_priceRangeIndex].upperLimit - totalSupply();
    }
}


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File contracts/inheritable/BitmapHolder.sol
pragma solidity ^0.8.7;

// External

/**
 * @title BitmapHolder
 * @author 0xLostArchitect
 *
 * @notice Contract that wraps a bitmap that holds a set amount of unique id's
 *
 * @dev In the LostWorlds Ecosystem, this is used to allow random concrete distributions of `variations` in a
 * @dev space + time efficient manner. By viewing the implementation, one can see that it allows for bounded selection
 * @dev of a potentially random id from id's that are still available (i.e. bits not yet set).
 *
 * @dev In theory, this could serve as the basis for a variety of other use cases. It is NOT meant to replace a general `BitMap` library,
 * @dev but rather serve this use case of needing a not-yet-selected id.
 */
contract BitmapHolder {
    /* Libraries */

    // NOTE: Just needed for `min` functionality
    using MathUpgradeable for *;

    /**
     * @dev An array of `uint256` that serve as bitmaps, ultimately manipulated by masking + bitwise operations
     *
     * @dev top 8 bits ("originalPosition") - the original position in `bitMappings`, providing the offset for an id down the line
     * @dev next 8 bits ("maxBitPosition") - the maximum bit position of this bitmap, which allows us to determine when the bitmap is full
     * @dev bottom 240 bits ("bitmap") - the actual bitmap holding up to `maxBitPosition + 1` id's
     */
    uint256[] internal _bitMappings;

    /**
     * @dev Initialization function for the BitmapHolder
     *
     * @dev Determine the number of bit mappings to make based off of the `maxSupply`
     *
     * @dev An entity looking to hold quantity T will need `ceiling(T / 240)` uint256 to represent all of the different id's possible
     */
    function _makeBitMapping(uint256 maxSupply) internal {
        // Track how many units are still needed
        uint256 remaining = maxSupply;

        // Track the original position inside the array for offsetting reasons downstream
        uint256 index;

        // Iterate until no more units are needed
        while (remaining > 0) {
            /*
             * Base entry has its first 8 bits occupied by the `index`,
             * the next 8 bits describe how many bits are used by the packed `bitmap`,
             * and the last 240 bits are the actual bitmap.
             *
             * Increase the index, and do a bitwise OR with the `maxbits` needed offset to the proper position
             *
             * NOTE: Use `239` because `maxBitPosition` INCLUDES `0` as a valid bit!
             */
            _bitMappings.push(index++ | (remaining.min(239) << 8));

            // Ensure no overflow
            remaining -= remaining.min(240);
        }
    }

    /**
     * @dev Gets the base information needed for a new id
     *
     * @param seed - Ideally some `random` number to seed the process
     * @return uint256 - The index into `_bitmappings`
     * @return uint256 - The position with the nested bitmap stored at the `index` returned
     */
    function _getBitMapInfoForNewId(uint256 seed)
        internal
        view
        returns (uint256, uint256)
    {
        /*
         * Select one of the buckets that contains all available token ids
         *
         * The implementation is predicted on the idea that every element in `_bitMappings`
         * always has > 0 available id's, which allows the claim that we are 0(240) in searching an id.
         */
        uint256 bitmapMappingIndex = seed % _bitMappings.length;

        /*
         * As every element actually contains the three elements explained above, we need to unmask anytime
         * we want to use an individual component.
         *
         * - Shift 8 bits to get the max bit position (set by `remaining.min(239) << 8)` above)
         * - Cast to 8 bits to only keep relevant information
         * - Convert back to uint256 for more efficient Solidity handling
         */
        uint256 _maxBitPosition = uint256(
            uint8(_bitMappings[bitmapMappingIndex] >> 8)
        );

        /*
         * Move the bitMapping up 16 bits to get just the `bitmap`
         *
         * As the first 16 bits are occupied by the `index` and `max bit position`, just getting the top
         * 240 is sufficient to extract the actual bitmap
         */
        uint256 _bitmap = _bitMappings[bitmapMappingIndex] >> 16;

        // The id (which is really just a `position` in the bitmap) to ultimately return
        uint256 position;

        // Get a valid index inside this `bitmap` to check first
        uint256 originalBitMappingIndex = seed % _maxBitPosition;

        // We keep shifting the index ("walking the bitmap") until we iterate over every potential index
        for (uint256 i; i < _maxBitPosition; i++) {
            /*
             * Offset the original selection by whatever index we're on.
             * Use modulo so we can wrap around to make the range [0, _maxBitPosition)
             */
            position = (originalBitMappingIndex + i) % _maxBitPosition;

            /*
             * If the result of the `bitwise AND` is zero, we know that that bit
             * has not been set yet in the bitmap, indicating an available index.
             */
            if (_bitmap & (1 << position) == 0) break;
        }

        return (bitmapMappingIndex, position);
    }

    /**
     * @dev The main internal function to be used to manipulate the bitmap
     *
     * @param seed - The initial number used to select which index of `bitMappings` and a starting position for our id selection
     * @return uint256 - The id that was selected and available
     */
    function _getIdAndUpdateBitMap(uint256 seed) internal returns (uint256) {
        // First get the bitmap + position
        (uint256 bitmapIndex, uint256 position) = _getBitMapInfoForNewId(seed);

        /*
         * Update the `bitMapping`
         *
         * - `bit = 1 << position` gets the position inside the bitmap itself
         * - `<< 16` properly places it inside the packed uint256
         */
        uint256 newBitMapping = _bitMappings[bitmapIndex] |
            ((1 << position) << 16);

        // Extract the max bit position
        uint256 maxBitPosition = uint256(uint8(newBitMapping >> 8));

        /*
         * Get the actual index by:
         * - taking the original position in `_bitMappings` (calculated by getting the first 8 bits from the bitmapping)
         * - multiplying it by the `maxBitPosition` of that bitmap + 1 (See below),
         * - adding the recently determined `position` inside the bitmap
         *
         * NOTE: We use `maxBitPosition + 1` because we want overflow into the next range.
         *
         * Example: uint8(newBitMapping) = 1, maxBitPosition = 239, position = 0
         *
         * By adding one, we ensure we end up in the range [240, ...), gauranteeing we don't overwrite
         * any index from the first range from `_bitMappings`
         */
        uint256 index = uint8(newBitMapping) * (maxBitPosition + 1) + position;

        /*
         * At this point, the new `bitmap` can potentially be full or not, and we need to keep our predicate that
         * all members of `_bitMappings` have > 0 index available.
         *
         * To check:
         * - Get just the `bitmap` from the `bitMapping` (by shifting 16)
         * - Capture what the highest possible value for this `bitmap` is (see below)
         * - If those are equal, we delete it from the array (using  Solidity "pop + swap model")
         *
         * In the case where this is no overflow, simply rewrite to storage.
         *
         * NOTE: We use this `- 1` construct because we want one less than the value of the maximimum represents a full bitmap
         *
         * Example: newBitMapping >> 16 = 1, maxBitPosition = 1
         *
         * Since `maxBitPosition` represents one bit higher than what this bitMapping can hold (given that it uses the 0 slot!),
         * the max value of this bitmap should be `1`. Therefore, we end up with `(1 << 1) - 1 == 1`, which is exactly what was desired.
         *
         */
        if ((newBitMapping >> 16) == ((1 << maxBitPosition) - 1)) {
            _bitMappings[bitmapIndex] = _bitMappings[_bitMappings.length - 1];
            _bitMappings.pop();
        } else {
            _bitMappings[bitmapIndex] = newBitMapping;
        }

        return index;
    }

    /**
     * @notice Public getter function
     */
    function bitMappings() external view returns (uint256[] memory) {
        return _bitMappings;
    }
}


// File contracts/storage/RandomLostWorldStorage.sol
pragma solidity ^0.8.10;

/**
 * @title RandomLostWorldStorage
 * @author 0xLostArchitect
 *
 * @notice Unique storage for any RandomLostWorld
 *
 * @dev On any extension of a `RandomLostWorld`, we need to ensure all of its storage values
 * @dev are accounted for to ensure proper upgradeability patterns, e.g. anything from `LostWorldBaseStorage`
 */
contract RandomLostWorldStorage {
    /* STATE VARIABLES */

    /**
     * @dev Address of the random number generator
     */
    address public randomNumberGenerator;
}


// File contracts/LostWorlds/CurvedRandomLostWorld.sol
pragma solidity ^0.8.10;

// Interfaces



// Inherits



/**
 * @title CurvedRandomLostWorld
 * @author 0xLostArchitect
 *
 * @notice This contract implements a LostWorld with curved pricing and random minting
 *
 * @dev As this contract inherits from `CurvedLostWorldBase`,
 * @dev the only thing needed to be implemented is the id selection mechanism, which is handled by the `BitmapHolder`
 *
 * Inherits:
 * - BitmapHolder - To effeciently store which id's have been selected
 * - RandomLostWorldStorage - Use `storage` pattern to put all structs, state variables, and events elsewhere for upgradeability
 * - CurvedLostWorldBase - To implement curved pricing on a LostWorld
 */
contract CurvedRandomLostWorld is
    BitmapHolder,
    RandomLostWorldStorage,
    CurvedLostWorldBase
{
    /**
     * @dev Initialization function for any CurvedRandomLostWorld
     *
     * @dev See {CurvedLostWorldBase-__CurvedLostWorldBase_init}
     *
     * @dev Responsibilities:
     * - Call base initialization function
     * - Add the number generator
     * - Make the initial bitmapping
     *
     * @param randomNumberGenerator_ -  Address of a contract to provide a seed for id generation
     */
    function initialize(
        InitializationParams calldata initializationParams_,
        AddressHolder calldata addressHolder_,
        Variation[] calldata variations_,
        QuantityRange[] calldata dividendLevels_,
        QuantityRange[] calldata priceRanges_,
        address randomNumberGenerator_
    ) public initializer {
        // Call super
        __CurvedLostWorldBase_init(
            initializationParams_,
            addressHolder_,
            variations_,
            dividendLevels_,
            priceRanges_
        );

        randomNumberGenerator = randomNumberGenerator_;

        // Max supply was set in {LostWorldBase-__LostWorldBase_init}
        _makeBitMapping(maxSupply);
    }

    /**
     * @dev Determine the total price for minting a certain `count` of tokens
     *
     * @dev Given the id selection mechanism, the implementation of the `uint256` is how many of random tokens are desired
     *
     * @param count - how many tokens are to be minted
     * @return uint256 - the total price for minting this `count` of tokens
     */
    function getCostToMint(uint256 count)
        public
        view
        override
        returns (uint256)
    {
        return count * _priceRanges[_priceRangeIndex].value;
    }

    /**
     * @notice Determine if this LostWorld is fully minted
     *
     * @dev The notion relies on the base predicate laid out in {BitmapHolder},
     * @dev namely, that any and all members of `_bitMappings` must have > 0 available id's.
     *
     * @dev This pattern is chosen over something such as checking `totalSupply` due to the unexpected effects
     * @dev of burning a 721.
     */
    function isFullyMinted() public view override returns (bool) {
        return _bitMappings.length == 0;
    }

    /**
     * @dev Principal function to both mint and update any pricing information
     *
     * @param contextData - The context data to store for future metadata use
     * @param count - The desired number of tokens
     * @return uint256[] - All token id's that were just minted
     *
     * Requirements:
     *
     * - `_bitMappings` still has members
     * - The `count` is less than the tokens in this range
     *
     * (Potentially) Emits:
     *
     * NewPriceRangeIndex(_priceRangeIndex)
     */
    function _mintAndGetTokenIds(bytes calldata contextData, uint256 count)
        internal
        override
        returns (uint256[] memory)
    {
        require(_bitMappings.length > 0, "M::fully-minted");
        require(count <= tokensLeftInRange(), "M::price-range-full");

        // Get initial random number
        uint256 randomNumber = IRandomNumberGenerator(randomNumberGenerator)
            .generateRandomNumber();

        // Store all `tokenIds` minted to use later in bulk call to `dividendHandler`
        uint256[] memory tokenIds = new uint256[](count);

        for (uint256 i; i < count; i++) {
            // Ensure each iteration has new entropy
            randomNumber = uint256(keccak256(abi.encode(randomNumber, i)));

            // Get the id
            uint256 tokenId = _getIdAndUpdateBitMap(randomNumber);

            // Mint the token
            _mint(msg.sender, tokenId);

            // Grant Royalty
            address royaltyReciever = IRoyaltyDeterminer(royaltyDeterminer)
                .determineRoyalty(royaltyDeterminerInformation, msg.sender);

            // Mint the royalty token
            royaltyToken.mint(royaltyReciever, tokenId);

            // Update the context
            tokenMintContext[tokenId] = contextData;

            // Add to list of tokens that will be sent to the `dividendHandler`
            tokenIds[i] = tokenId;
        }

        // Update the `_priceRangeIndex` if we've hit the limit
        if (totalSupply() == _priceRanges[_priceRangeIndex].upperLimit) {
            _priceRangeIndex++;
            emit NewPriceRangeIndex(_priceRangeIndex);
        }

        return tokenIds;
    }
}