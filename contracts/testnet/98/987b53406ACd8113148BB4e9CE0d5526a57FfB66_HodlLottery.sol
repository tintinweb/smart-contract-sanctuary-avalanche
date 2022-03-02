/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-01
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: artifacts/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.7;

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
    uint256 private _statusSelectWinner;
    uint256 private _statusGivePriceToWinner;

    constructor() {
        _status = _NOT_ENTERED;
        _statusSelectWinner = _NOT_ENTERED;
        _statusGivePriceToWinner = _NOT_ENTERED;
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

    modifier nonReentrantSelectWinner() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusSelectWinner != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusSelectWinner = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusSelectWinner = _NOT_ENTERED;
    }

    modifier nonReentrantGivePriceToWinner() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_statusGivePriceToWinner != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _statusGivePriceToWinner = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _statusGivePriceToWinner = _NOT_ENTERED;
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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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

        _afterTokenTransfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

// File: artifacts/HodlNFT.sol


pragma solidity ^0.8.7;






contract HodlNFT is ERC721, Ownable {
    address private RewardWallet;
   
    event SetHodlNFTPrice(address addr, uint256 newNFTPrice);
    event SetBaseURI(address addr, string newUri);
    event SetHodlNFTURI(address addr, string newUri);
    event SetRewardWalletAddress(address addr, address rewardWallet);

    using Strings for uint256;

    uint256 private HODL_NFT_PRICE                          = 10;     //HODL token

    using Counters for Counters.Counter;
    Counters.Counter private _hodlTokenCounter;
    
    string private _baseURIExtended;

    string private hodlNFTURI;

    /**
    * @dev Throws if called by any account other than the multi-signer.
    */
    // modifier onlyMultiSignWallet() {
    //     require(owner() == _msgSender(), "Multi-signer: caller is not the multi-signer");
    //     _;
    // }
    
    constructor() ERC721("HODL NFT","HNFT") {
        _baseURIExtended = "https://ipfs.infura.io/";
    }

    function setRewardWalletAddress(address _newRewardWallet) external onlyOwner{
        RewardWallet = _newRewardWallet;
        emit SetRewardWalletAddress(msg.sender, _newRewardWallet);
    }

    //Set, Get Price Func
    function setHodlNFTPrice(uint256 _newNFTValue) external onlyOwner{
        HODL_NFT_PRICE = _newNFTValue;
        emit SetHodlNFTPrice(msg.sender, _newNFTValue);
    }

    function getHodlNFTPrice() external view returns(uint256){
        return HODL_NFT_PRICE;
    }

    function getHodlNFTURI() external view returns(string memory){
        return hodlNFTURI;
    }

    function setHodlNFTURI(string memory _hodlNFTURI) external onlyOwner{
        hodlNFTURI = _hodlNFTURI;
        emit SetHodlNFTURI(msg.sender, hodlNFTURI);
    }

   /**
    * @dev Mint NFT by customer
    */
    function mintNFT(address sender) external returns (uint256) {

        require( msg.sender == RewardWallet, "you can't mint from other account");

        // Incrementing ID to create new token
        uint256 newHodlNFTID = _hodlTokenCounter.current();
        _hodlTokenCounter.increment();

        _safeMint(sender, newHodlNFTID);
        return newHodlNFTID;
    }

    /**
     * @dev Return the base URI
     */
     function _baseURI() internal override view returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * @dev Set the base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIExtended = baseURI_;
        emit SetBaseURI(msg.sender, baseURI_);
    }
}
// File: artifacts/HodlLottery.sol

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract HodlLottery is Ownable, ReentrancyGuard {
    // 2 kinds of lottery
    enum LOTTERY_TYPE {
        LOTTERY_WEEKLY,
        LOTTERY_BI_DAILY
    }

    // lottery status
    enum LOTTERY_STATUS {
        LOTTERY_START,
        LOTTERY_CLOSED,
        LOTTERY_PICKED,
        LOTTERY_PRIZED
    }

    // team funds wallet address
    address payable constant _teamFundsWallet       = payable(0xbAB8E9cA493E21d5A3f3e84877Ba514c405be0e1);

    // private seed data for claculating picked number
    uint256 private constant    MAX_UINT_VALUE = (2**255 - 1 + 2**255);
    uint256 private             pri_seedValue;
    string private              pri_seedString;
    address private             pri_seedAddress;

    // distribution percentage of funds
    uint256 constant REWARD_FOR_TEAM_FUND           = 1;                        // 10% goes to team funds
    uint256 constant REWARD_FOR_REWARD_POOL         = 9;                        // 90% goes to rewards pool
    uint256 constant LOTTERY_FEE                    = 1;                        // 10% goes to team funds

    // price of ticket
    uint256 PRICE_TICKET_WEEKLY                     = 1 * 10 ** 17;             // 0.1 AVAX
    uint256 PRICE_TICKET_BI_DAILY                   = 3 * 10 ** 16;             // 0.03 AVAX

    // lottery loop time
    uint256 WEEKLY_LOOP_TIME                        = 60 * 60 * 24 * 7;         // 7 days
    uint256 BI_DAILY_LOOP_TIME                      = 60 * 60 * 24 * 2;         // 2 days

    // this is for first lottery
    uint256 constant TEMPORARY_TIME                 = 60 * 60 * 5;                  // 5 hour

    // when user buy ticket, NFT is minted
    HodlNFT public nftContract;

    // this is for get user ticket numbers
    struct Ticket_Address {
        uint256 timestamp;
        uint16 startNumber;
        uint16 count;
    }

    // lottery history struct user won
    struct Lottery_History {
        address addr;
        uint256 id;
        uint256 timestamp;
        uint256 winnerPrize;
    }

    // return ticket status
    struct Ret_Ticket_Status {
        LOTTERY_STATUS status;
        uint256 totalCount;
        uint256 poolAmount;
    }

    // there are 2 kinds of lottery
    // weekly lottery: per week
    // bi-daily lottery: per bi-daily
    struct Lottery_Info {
        uint256 lotteryID;                                              // lottery id
        LOTTERY_STATUS lotteryStatus;                                   // current status of lottery
        uint256 lotteryTimeStamp;                                       // lottery time stamp
        uint256 poolAmount;                                             // all amount of inputed AVAX
        uint16[] ids;                                                   // start ids of tickes user bought
        uint16 winnerID;
        uint256 winnerTicketID;
        uint256 winnerPrize;
        mapping(uint16 => address) members;                             // address of start id
        mapping(address => Ticket_Address[]) historyOfMember;
        mapping(uint16 => uint16) ticketsOfMember;                      // ticket ids of members
    }

    // lottery infos of weekly lottery
    mapping(uint256 => Lottery_Info) internal allWeeklyLotteryInfos;

    // lottery infos of bi-daily lottery
    mapping(uint256 => Lottery_Info) internal allBiDailyLotteryInfos;

    // last available lottery id
    uint256 public weeklyLotteryCounter;
    uint256 public biDailyLotteryCounter;

    // this is sum of total payout
    uint256 public totalMarketcap;

    // invest amount current site was paid
    uint256 private totalInvestments;

    // all events
    event Received (address, uint);
    event Fallback (address, uint);
    event SetWeeklyTicketPrice (uint256);
    event SetBiDailyTicketPrice (uint256);
    event ChangeLotteryInfo (LOTTERY_TYPE, uint256, LOTTERY_STATUS, uint256);
    event ClearLotteryInfo (LOTTERY_TYPE, uint256);
    event CreateWeeklyLotteryInfo (LOTTERY_TYPE, uint, LOTTERY_STATUS);
    event BuyTicket (address, uint256, uint16);
    event LogAllSeedValueChanged (address indexed, uint256 indexed, uint256, string, address);
    event SelectWinner (LOTTERY_TYPE, uint256, LOTTERY_STATUS);
    event GivePriceToWinner(LOTTERY_TYPE, address, uint256);
    event SetWeeklyLoopTime (uint256);
    event SetBiDailyLoopTime (uint256);
    event SetTotalInvestment (uint256);

    // contructor
    constructor (
        uint256 _seedValue,
        string memory _seedString,
        address _seedAddress,
        address _nftContract
     )
    {
        pri_seedValue = _seedValue;
        pri_seedString = _seedString;
        pri_seedAddress = _seedAddress;

        weeklyLotteryCounter = 0;
        biDailyLotteryCounter = 0;

        nftContract = HodlNFT(_nftContract);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable { 
        emit Fallback(msg.sender, msg.value);
    }

    function setWeeklyTicketPrice (uint256 _ticketPrice) external onlyOwner {
        PRICE_TICKET_WEEKLY = _ticketPrice;
        emit SetWeeklyTicketPrice (_ticketPrice);
    }

    function getWeeklyTicketPrice () external view returns (uint256) {
        return PRICE_TICKET_WEEKLY;
    }

    function setBiDailyTicketPrice (uint256 _ticketPrice) external onlyOwner {
        PRICE_TICKET_BI_DAILY = _ticketPrice;
        emit SetBiDailyTicketPrice (_ticketPrice);
    }

    function getBiDailyTicketPrice () external view returns (uint256) {
        return PRICE_TICKET_BI_DAILY;
    }

    function setWeeklyLoopTime (uint256 _time) external onlyOwner {
        WEEKLY_LOOP_TIME = _time;
        emit SetWeeklyLoopTime (WEEKLY_LOOP_TIME);
    }

    function getWeeklyLoopTime () external view returns (uint256) {
        return WEEKLY_LOOP_TIME;
    }

    function setBiDailyLoopTime (uint256 _time) external onlyOwner {
        BI_DAILY_LOOP_TIME = _time;
        emit SetBiDailyLoopTime (BI_DAILY_LOOP_TIME);
    }

    function getBiDailyLoopTime () external view returns (uint256) {
        return BI_DAILY_LOOP_TIME;
    }

    function setTotalInvestment (uint256 _value) external onlyOwner {
        totalInvestments = _value;
        emit SetTotalInvestment (totalInvestments);
    }

    function getTotalInvestment () external view returns (uint256) {
        return totalInvestments;
    }

    // admin can oly change status and timestamp of started lottery
    function changeLotteryInfo (LOTTERY_TYPE _lotteryType, uint256 _lotteryID, LOTTERY_STATUS _status, uint256 _timestamp) external onlyOwner {
        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allWeeklyLotteryInfos[_lotteryID];
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allBiDailyLotteryInfos[_lotteryID];
        }
        require(lottoInfo.lotteryStatus == LOTTERY_STATUS.LOTTERY_START, "admin can't change data");

        lottoInfo.lotteryStatus = _status;
        lottoInfo.lotteryTimeStamp = _timestamp;

        emit ChangeLotteryInfo (_lotteryType, _lotteryID, _status, _timestamp);
    }

    // admin can remove lottery
    function clearLotteryInfo (LOTTERY_TYPE _lotteryType, uint256 _lotteryID) external onlyOwner {
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            delete allWeeklyLotteryInfos[_lotteryID];
            weeklyLotteryCounter --;
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            delete allBiDailyLotteryInfos[_lotteryID];
            biDailyLotteryCounter --;
        }

        emit ClearLotteryInfo (_lotteryType, _lotteryID);
    }

    // only owner can create new lottery
    function createNewLotteryInfo (LOTTERY_TYPE lottery_type) external onlyOwner {
        require (lottery_type <= LOTTERY_TYPE.LOTTERY_BI_DAILY, "This lottery doesn't exist");
        Lottery_Info storage newLottery;
        uint256 nLotteryTime = block.timestamp + TEMPORARY_TIME;
        if (lottery_type == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            if (weeklyLotteryCounter > 0) {
                require(allWeeklyLotteryInfos[weeklyLotteryCounter - 1].lotteryStatus == LOTTERY_STATUS.LOTTERY_PRIZED, "Previous lottery doesn't complete.");
                nLotteryTime = allWeeklyLotteryInfos[weeklyLotteryCounter - 1].lotteryTimeStamp + WEEKLY_LOOP_TIME;
            }
            newLottery = allWeeklyLotteryInfos[weeklyLotteryCounter];
            newLottery.lotteryID = weeklyLotteryCounter;
            weeklyLotteryCounter ++;
        }
        else {
            if (biDailyLotteryCounter > 0) {
                require(allBiDailyLotteryInfos[biDailyLotteryCounter - 1].lotteryStatus == LOTTERY_STATUS.LOTTERY_PRIZED, "Previous lottery doesn't complete.");
                nLotteryTime = allBiDailyLotteryInfos[biDailyLotteryCounter - 1].lotteryTimeStamp + BI_DAILY_LOOP_TIME;
            }
            newLottery = allBiDailyLotteryInfos[biDailyLotteryCounter];
            newLottery.lotteryID = biDailyLotteryCounter;
            biDailyLotteryCounter ++;
        }
        newLottery.lotteryStatus = LOTTERY_STATUS.LOTTERY_START;
        newLottery.lotteryTimeStamp = nLotteryTime;
        // newLottery.startTimeStamp = 0;
        newLottery.poolAmount = 0;
        newLottery.ids.push(1);
        newLottery.members[1] = address(msg.sender);
        newLottery.ticketsOfMember[1] = 0;

        emit CreateWeeklyLotteryInfo (lottery_type, newLottery.lotteryID, LOTTERY_STATUS.LOTTERY_START);
    }

    // Get remain time of last lottery
    function getLotteryRemainTime(LOTTERY_TYPE _lotteryType, uint256 _lotteryID) external view returns(uint256) {
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            if (allWeeklyLotteryInfos[_lotteryID].lotteryTimeStamp <= block.timestamp) {
                return 0;
            }
            return allWeeklyLotteryInfos[_lotteryID].lotteryTimeStamp - block.timestamp;
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            if (allBiDailyLotteryInfos[_lotteryID].lotteryTimeStamp <= block.timestamp) {
                return 0;
            }
            return allBiDailyLotteryInfos[_lotteryID].lotteryTimeStamp - block.timestamp;
        }
    }

    // set lottery status after lottery time
    function setLotteryStatus(LOTTERY_TYPE _lotteryType, uint256 _lotteryID) external onlyOwner returns(bool) {
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            require(allWeeklyLotteryInfos[_lotteryID].lotteryStatus == LOTTERY_STATUS.LOTTERY_START, "This Lottery Status is not Start.");
            require(allWeeklyLotteryInfos[_lotteryID].ids.length > 1, "User has to buy Ticket");
            if (allWeeklyLotteryInfos[weeklyLotteryCounter - 1].lotteryTimeStamp <= block.timestamp) {
                allWeeklyLotteryInfos[_lotteryID].lotteryStatus = LOTTERY_STATUS.LOTTERY_CLOSED;
                allWeeklyLotteryInfos[_lotteryID].lotteryTimeStamp = block.timestamp;
            }
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            require(allBiDailyLotteryInfos[_lotteryID].lotteryStatus == LOTTERY_STATUS.LOTTERY_START, "This Lottery Status is not Start.");
            require(allBiDailyLotteryInfos[_lotteryID].ids.length > 1, "User has to buy Ticket");
            if (allBiDailyLotteryInfos[biDailyLotteryCounter - 1].lotteryTimeStamp <= block.timestamp) {
                allBiDailyLotteryInfos[_lotteryID].lotteryStatus = LOTTERY_STATUS.LOTTERY_CLOSED;
                allBiDailyLotteryInfos[_lotteryID].lotteryTimeStamp = block.timestamp;
            }
        }
        return true;
    }

    // get full information of _lotteryID
    function getLottoryInfo(LOTTERY_TYPE _lotteryType, uint256 _lotteryID) external view returns(
        uint256,    // startingTimestamp
        uint16,     // winnerID
        address,    // winnerAddress
        uint256,    // PoolAmountInAVAX
        uint16,     // NumberOfLottoMembers
        uint256     // winnerPrize
    )
    {
        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allWeeklyLotteryInfos[_lotteryID];
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allBiDailyLotteryInfos[_lotteryID];
        }
        uint256 lotteryTimeStamp = lottoInfo.lotteryTimeStamp;
        uint16 winnerID = lottoInfo.winnerID;
        address winnerAddress = lottoInfo.members[lottoInfo.winnerID];
        uint256 poolAmount = lottoInfo.poolAmount;
        uint16 NumberOfLottoMembers = uint16(lottoInfo.ids.length - 1);
        uint256 winnerPrize = lottoInfo.winnerPrize;
        return (
            lotteryTimeStamp,
            winnerID,
            winnerAddress,
            poolAmount,
            NumberOfLottoMembers,
            winnerPrize
        );
    }

    function buyTicket(LOTTERY_TYPE _lotteryType, uint16 _numberOfTickets) external payable {
        uint256 payAmount;
        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(weeklyLotteryCounter > 0, "There is no lottery");
            lottoInfo = allWeeklyLotteryInfos[weeklyLotteryCounter - 1];
            payAmount = PRICE_TICKET_WEEKLY * _numberOfTickets;
        }
        else {
            require(biDailyLotteryCounter > 0, "There is no lottery");
            lottoInfo = allBiDailyLotteryInfos[biDailyLotteryCounter - 1];
            payAmount = PRICE_TICKET_BI_DAILY * _numberOfTickets;
        }
        require(lottoInfo.lotteryTimeStamp >= block.timestamp, "Time is up");
        require(lottoInfo.lotteryStatus == LOTTERY_STATUS.LOTTERY_START, "Lottery doesn't start.");

        // pay AVAX for ticket
        require(msg.value == payAmount, "no enough balance");
        _teamFundsWallet.transfer(payAmount * REWARD_FOR_TEAM_FUND / 10);
        payable(address(this)).transfer(payAmount * REWARD_FOR_REWARD_POOL / 10);
        lottoInfo.poolAmount += payAmount * REWARD_FOR_REWARD_POOL / 10;
        
        // insert data into lottery info
        uint16 numTickets = _numberOfTickets;
        for (uint i = 0; i < numTickets; i ++) {
            nftContract.mintNFT(msg.sender);
        }
        uint16 lastID = lottoInfo.ids[lottoInfo.ids.length - 1];
        uint16 newID = lastID + lottoInfo.ticketsOfMember[lastID];

        // first 10 users can get 2 times chance than others
        if (lottoInfo.ids.length <= 10) {
            numTickets = _numberOfTickets * 2;
        }
        
        lottoInfo.ids.push(newID);
        lottoInfo.members[newID] = address(msg.sender);
        lottoInfo.ticketsOfMember[newID] = numTickets;
        lottoInfo.historyOfMember[msg.sender].push (Ticket_Address({startNumber: newID, count: numTickets, timestamp: block.timestamp}));

        emit BuyTicket(msg.sender, weeklyLotteryCounter - 1, numTickets);
    }
    
    // Generate random number base on seed and timestamp.
    function randomNumberGenerate(LOTTERY_TYPE _lotteryType) private view returns (uint16) {
        // random hash from seed data
        uint randomHash = uint(keccak256(abi.encodePacked(pri_seedValue, pri_seedString, pri_seedAddress, 
                                        block.timestamp, block.difficulty, block.number)));

        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            lottoInfo = allWeeklyLotteryInfos[weeklyLotteryCounter - 1];
        }
        else {
            lottoInfo = allBiDailyLotteryInfos[biDailyLotteryCounter - 1];
        }
        require(lottoInfo.lotteryStatus == LOTTERY_STATUS.LOTTERY_CLOSED, "Lottery doesn't close.");

        // generate random number
        uint16 lastID = uint16(lottoInfo.ids.length - 1);
        uint16 totalMembers = lottoInfo.ids[lastID] + lottoInfo.ticketsOfMember[lastID] - 1;
        uint256 maxValue = MAX_UINT_VALUE / totalMembers;
        uint16 randomNum = uint16(randomHash / maxValue) + 1;
        if (randomNum > totalMembers) {
            randomNum = 1;
        }

        return randomNum;
    }

    // only user can change seed data
    function updateSeeds(uint256 _seedValue, string memory _seedString, address _seedAddress ) external onlyOwner returns(bool) {
        // seed value check
        require(_seedValue != 0 && _seedValue != pri_seedValue, 
            "The seed value can't be 0 value and can't be the same as the previous one.");

        // seed address check
        require(_seedAddress != address(0) && _seedAddress != pri_seedAddress, 
            "The seed Address can't be 0 Address and can't be the same as the previous one.");

        // seed string check
        require(keccak256(abi.encodePacked(_seedString)) != 0 && 
            keccak256(abi.encodePacked(_seedString)) != keccak256(abi.encodePacked(pri_seedString)), 
            "The seed String can't be 0 String and can't be the same as the previous one.");

        emit LogAllSeedValueChanged(msg.sender, block.timestamp, _seedValue, _seedString, _seedAddress);

        pri_seedValue = _seedValue;
        pri_seedString = _seedString;
        pri_seedAddress = _seedAddress;

        return true;
    }

    // get winnder id
    function selectWinner(LOTTERY_TYPE _lotteryType) external nonReentrantSelectWinner onlyOwner returns(uint16) {
        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            lottoInfo = allWeeklyLotteryInfos[weeklyLotteryCounter - 1];
        }
        else {
            lottoInfo = allBiDailyLotteryInfos[biDailyLotteryCounter - 1];
        }
        require(lottoInfo.lotteryStatus == LOTTERY_STATUS.LOTTERY_CLOSED, "This lotteryID does not close.");
        require(lottoInfo.ids.length > 1, "user does not exist");
        
        uint16 winnerIDKey = randomNumberGenerate(_lotteryType);

        // binary search
        /* initialize variables:
            low : index of smallest value in current subarray of id array
            high: index of largest value in current subarray of id array
            mid : average of low and high in current subarray of id array */
        uint256 mid;

        uint256 low = 1;         // set initial value for low
        uint256 high = lottoInfo.ids.length - 1;  // set initial value for high

        /* perform binary search */
        while (low <= high) {
            mid = low + (high - low)/2; // update mid
            
            if ((winnerIDKey >= lottoInfo.ids[mid]) && 
                (winnerIDKey < lottoInfo.ids[mid] + lottoInfo.ticketsOfMember[lottoInfo.ids[mid]]))
            {
                break; // find winnerID
            }
            else if (lottoInfo.ids[mid] > winnerIDKey) { // search left subarray for val
                high = mid - 1;  // update high
            }
            else if (lottoInfo.ids[mid] < winnerIDKey) { // search right subarray for val
                low = mid + 1;        // update low
            }
        }

        lottoInfo.winnerID = lottoInfo.ids[mid];
        lottoInfo.winnerTicketID = winnerIDKey;
        lottoInfo.lotteryStatus = LOTTERY_STATUS.LOTTERY_PICKED; // Now, we know winnerID.

        emit SelectWinner(_lotteryType, lottoInfo.lotteryID, lottoInfo.lotteryStatus);
        return lottoInfo.winnerID;
    }

    // give AVAX to winner
    function givePriceToWinner(LOTTERY_TYPE _lotteryType, uint256 _lotteryID) external nonReentrantGivePriceToWinner payable returns(bool) {
        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allWeeklyLotteryInfos[_lotteryID];
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allBiDailyLotteryInfos[_lotteryID];
        }
        
        uint16 winnerID = lottoInfo.winnerID;
        require(lottoInfo.lotteryStatus == LOTTERY_STATUS.LOTTERY_PICKED, "Lottery has not been picked.");
        require(msg.sender == lottoInfo.members[winnerID], "You are not Winner of this lottery");
        require(lottoInfo.poolAmount > 1, "Lottery Pool is empty!");

        // send prize AVAX to winner
        uint256 winnerPrize = lottoInfo.poolAmount * (10 - LOTTERY_FEE) / 10;
        payable(msg.sender).transfer(winnerPrize);
        totalMarketcap = totalMarketcap + winnerPrize;
        winnerPrize = lottoInfo.poolAmount * LOTTERY_FEE / 10;
        _teamFundsWallet.transfer(winnerPrize);

        lottoInfo.winnerPrize = lottoInfo.poolAmount * (10 - LOTTERY_FEE) / 10;
        lottoInfo.lotteryStatus = LOTTERY_STATUS.LOTTERY_PRIZED;

        emit GivePriceToWinner(_lotteryType, msg.sender, lottoInfo.winnerPrize);
        return true;
    }

    // get ticket number and timestamp user bought
    function getTicketNumbersOfAddress(address _addr, LOTTERY_TYPE _lotteryType, uint256 _lotteryID) external view returns (Ticket_Address[] memory){
        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allWeeklyLotteryInfos[_lotteryID];
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allBiDailyLotteryInfos[_lotteryID];
        }

        return lottoInfo.historyOfMember[_addr];
    }

    // get lottery history user won
    function getLotteryHistory(address _addr, LOTTERY_TYPE _lotteryType) external view returns (Lottery_History[] memory) {
        uint256 _index = 0;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            Lottery_History[] memory retInfo = new Lottery_History[](weeklyLotteryCounter);
            require(weeklyLotteryCounter > 0, "This lotteryID does not exist.");
            for (uint256 i = 0; i < weeklyLotteryCounter; i ++) {
                uint16 winnerID = allWeeklyLotteryInfos[i].winnerID;
                if (allWeeklyLotteryInfos[i].members[winnerID] == _addr) {
                    retInfo[_index] = Lottery_History({addr: _addr, id: allBiDailyLotteryInfos[i].winnerTicketID, timestamp: allBiDailyLotteryInfos[i].lotteryTimeStamp, winnerPrize: allBiDailyLotteryInfos[i].winnerPrize});
                    _index ++;
                }
            }
            return retInfo;
        }
        else {
            Lottery_History[] memory retInfo = new Lottery_History[](biDailyLotteryCounter);
            require(biDailyLotteryCounter > 0, "This lotteryID does not exist.");
            for (uint256 i = 0; i < biDailyLotteryCounter; i ++) {
                uint16 winnerID = allBiDailyLotteryInfos[i].winnerID;
                if (allBiDailyLotteryInfos[i].members[winnerID] == _addr) {
                    retInfo[_index] = Lottery_History({addr: _addr, id: allBiDailyLotteryInfos[i].winnerTicketID, timestamp: allBiDailyLotteryInfos[i].lotteryTimeStamp, winnerPrize: allBiDailyLotteryInfos[i].winnerPrize});
                    _index ++;
                }
            }
            return retInfo;
        }
    }

    // fetch all lottery winner informations
    function getAllLotteryWinners(LOTTERY_TYPE _lotteryType) external view returns (Lottery_History[] memory) {
        uint256 _index = 0;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            Lottery_History[] memory retInfo = new Lottery_History[](weeklyLotteryCounter);
            require(weeklyLotteryCounter > 0, "This lotteryID does not exist.");
            for (uint256 i = 0; i < weeklyLotteryCounter; i ++) {
                uint16 winnerID = allWeeklyLotteryInfos[i].winnerID;
                retInfo[_index] = Lottery_History({addr: allWeeklyLotteryInfos[i].members[winnerID], id: allWeeklyLotteryInfos[i].winnerTicketID, timestamp: allBiDailyLotteryInfos[i].lotteryTimeStamp, winnerPrize: allBiDailyLotteryInfos[i].winnerPrize});
                _index ++;
            }
            return retInfo;
        }
        else {
            Lottery_History[] memory retInfo = new Lottery_History[](biDailyLotteryCounter);
            require(biDailyLotteryCounter > 0, "This lotteryID does not exist.");
            for (uint256 i = 0; i < biDailyLotteryCounter; i ++) {
                uint16 winnerID = allBiDailyLotteryInfos[i].winnerID;
                retInfo[_index] = Lottery_History({addr: allBiDailyLotteryInfos[i].members[winnerID], id: allBiDailyLotteryInfos[i].winnerTicketID, timestamp: allBiDailyLotteryInfos[i].lotteryTimeStamp, winnerPrize: allBiDailyLotteryInfos[i].winnerPrize});
                _index ++;
            }
            return retInfo;
        }
    }

    // get current lottery status of _lotteryID
    function getLotteryStatus(LOTTERY_TYPE _lotteryType, uint256 _lotteryID) external view returns(Ret_Ticket_Status memory) {
        Ret_Ticket_Status memory ret_ticket;
        Lottery_Info storage lottoInfo;
        if (_lotteryType == LOTTERY_TYPE.LOTTERY_WEEKLY) {
            require(_lotteryID < weeklyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allWeeklyLotteryInfos[_lotteryID];
            ret_ticket.status = allWeeklyLotteryInfos[_lotteryID].lotteryStatus;
            ret_ticket.poolAmount = allWeeklyLotteryInfos[_lotteryID].poolAmount;
        }
        else {
            require(_lotteryID < biDailyLotteryCounter, "This lotteryID does not exist.");
            lottoInfo = allBiDailyLotteryInfos[_lotteryID];
            ret_ticket.status = allBiDailyLotteryInfos[_lotteryID].lotteryStatus;
            ret_ticket.poolAmount = allBiDailyLotteryInfos[_lotteryID].poolAmount;
        }
        uint16 lastID = lottoInfo.ids[lottoInfo.ids.length - 1];
        ret_ticket.totalCount = lastID + lottoInfo.ticketsOfMember[lastID];

        return ret_ticket;
    }
}