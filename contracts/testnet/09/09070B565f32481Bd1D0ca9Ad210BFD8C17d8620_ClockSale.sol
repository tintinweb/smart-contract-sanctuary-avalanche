/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-19
*/

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

// File: @openzeppelin/contracts/interfaces/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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

// File: Addresses.sol



pragma solidity ^0.8.0;


contract Addresses is Ownable {
    address[] contracts;
    mapping(address => bool) verified;

    modifier exists(address contractAddr) {
        require(existingContract(contractAddr), "The contract does not exist");
        _;
    }

    modifier doesNotExist(address contractAddr) {
        require(!existingContract(contractAddr), "The contract already exists");
        _;
    }

    function existingContract(address contractAddr) public view returns (bool) {
        uint256 i;
        uint256 length = contracts.length;
        for (i = 0; i < length; ++i) {
            if (contracts[i] == contractAddr) {
                return true;
            }
        }
        return false;
    }

    function addContract(address contractAddr)
        external
        doesNotExist(contractAddr)
        onlyOwner
    {
        contracts.push(contractAddr);
    }

    function removeContract(address contractAddr)
        external
        exists(contractAddr)
        onlyOwner
    {
        uint256 i;
        uint256 length = contracts.length;
        for (i = 0; i < length; ++i) {
            if (contracts[i] == contractAddr) {
                break;
            }
        }
        require(i < length, "Not Found the Contract");
        contracts[i] = contracts[length - 1];
        contracts.pop();
        verified[contractAddr] = false;
    }

    function verify(address contractAddr)
        external
        exists(contractAddr)
        onlyOwner
    {
        require(
            verified[contractAddr] == false,
            "The contract is already verified"
        );
        verified[contractAddr] = true;
    }

    function getContracts() external view returns (address[] memory) {
        return contracts;
    }

    function getVerifiedContracts() external view returns (address[] memory) {
        address[] memory verifiedContracts;
        uint256 i;
        uint256 length = contracts.length;
        uint256 vlength = 0;
        for (i = 0; i < length; ++i) {
            if (verified[contracts[i]]) {
                verifiedContracts[vlength++] = contracts[i];
            }
        }
        return verifiedContracts;
    }

    function isVerified(address contractAddr) external view returns (bool) {
        return verified[contractAddr];
    }
}

// File: ClockSaleBase.sol



pragma solidity ^0.8.0;




interface AddressesInterface {
    function existingContract(address contractAddr)
        external
        view
        returns (bool);

    function isVerified(address contractAddr) external view returns (bool);
}

/// @title Sale Core
/// @dev Contains models, variables, and internal methods for the sale.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockSaleBase {
    // Represents an sale on an NFT
    struct Sale {
        // Address of Smart Contract
        // address contractAddr;
        // Current owner of NFT
        address seller;
        // Price (in wei) at beginning of sale
        uint128 price;
        uint256 startedAt;
    }

    struct Auction {
        address auctioneer;
        uint128 price;
        uint256 duration;
        uint256 startedAt;
    }

    struct Offer {
        // Address of Offerer
        address offerer;
        // Offering price
        uint256 price;
        uint256 time;
    }

    struct Bid {
        // Address of Offerer
        address bidder;
        // Offering price
        uint256 price;
        uint256 time;
    }

    struct Royalty {
        address destination;
        uint256 profit;
    }

    // Map from token ID to their corresponding sale.
    mapping(address => mapping(uint256 => Sale)) tokenIdToSales;
    mapping(address => mapping(uint256 => Auction)) tokenIdToAuctions;

    // Save Sale Token Ids by Contract Addresses
    mapping(address => uint256[]) public saleTokenIds;
    mapping(address => uint256[]) public auctionTokenIds;
    // Sale Token Ids by Seller Addresses
    mapping(address => mapping(address => uint256[]))
        private saleTokenIdsBySeller;
    mapping(address => mapping(address => uint256[]))
        private auctionTokenIdsBySeller;
    // Offers
    mapping(address => mapping(uint256 => Offer[])) offers;
    mapping(address => mapping(uint256 => Bid[])) bids;
    //Royalty
    // mapping(address => Royalty[]) royalty;
    /*
    address public firstroyalty = 0x10B708FF9F5d20109CfA91e729a84404351c86C7;
    address public secondroyalty = 0x8E0AFCE03755eDA5A0fC6fA93f15835EaA1867C6;
    address public thirdroyalty = 0x30e5dD834FF5855b07fAb357F74F9b0Ab2744f6e;
    */

    // address public royaltyContract = 0x10B708FF9F5d20109CfA91e729a84404351c86C7;
    address public dev = 0x10B708FF9F5d20109CfA91e729a84404351c86C7;
    address public addressesContractAddr;

    event SaleCreated(
        address contractAddr,
        uint256 tokenId,
        uint256 price,
        uint256 time
    );
    event SaleSuccessful(
        address contractAddr,
        uint256 tokenId,
        uint256 totalPrice,
        address winner
    );
    event SaleCancelled(address contractAddr, uint256 tokenId);
    event SendSuccessful(
        address contractAddr,
        uint256 tokenId,
        address destination
    );
    event OfferCreated(
        address contractAddr,
        uint256 tokenId,
        address offerer,
        uint256 price,
        uint256 time
    );
    event OfferCanceled(address contractAddr, uint256 tokenId, address offerer);
    event OfferAccepted(address contractAddr, uint256 tokenId, address offerer);
    event RoyaltiesPaid(address contractAddr, uint256 tokenId, uint256 royalty);
    event AuctionCreated(
        address contractAddr,
        uint256 tokenId,
        uint256 price,
        uint256 time
    );
    event AuctionCancelled(address contractAddr, uint256 tokenId);
    event BidCreated(
        address contractAddr,
        uint256 tokenId,
        address bidder,
        uint256 price,
        uint256 time
    );
    event BidCanceled(address contractAddr, uint256 tokenId, address bidder);
    event BidAccepted(address contractAddr, uint256 tokenId, address bidder);

    modifier onSale(address contractAddr, uint256 tokenId) {
        require(tokenIdToSales[contractAddr][tokenId].price > 0, "Not On Sale");
        _;
    }

    modifier notOnSale(address contractAddr, uint256 tokenId) {
        require(
            tokenIdToSales[contractAddr][tokenId].price == 0,
            "Already On Sale"
        );
        _;
    }

    modifier onAuction(address contractAddr, uint256 tokenId) {
        require(
            tokenIdToAuctions[contractAddr][tokenId].price > 0,
            "Not On Auction"
        );
        _;
    }

    modifier notOnAuction(address contractAddr, uint256 tokenId) {
        require(
            tokenIdToAuctions[contractAddr][tokenId].price == 0,
            "Already On Auction"
        );
        _;
    }

    modifier owningToken(address contractAddr, uint256 _tokenId) {
        ERC721 nftContract = ERC721(contractAddr);
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "Not owner of that token"
        );
        _;
    }

    modifier onlySeller(address contractAddr, uint256 tokenId) {
        require(
            tokenIdToSales[contractAddr][tokenId].seller == msg.sender,
            "Caller is not seller"
        );
        _;
    }

    modifier onlyBuyer(address contractAddr, uint256 tokenId) {
        require(
            tokenIdToSales[contractAddr][tokenId].seller != msg.sender,
            "Caller is seller"
        );
        _;
    }

    modifier onlyAuctioneer(address contractAddr, uint256 tokenId) {
        require(
            tokenIdToAuctions[contractAddr][tokenId].auctioneer == msg.sender,
            "Caller is not auctioneer"
        );
        _;
    }

    modifier onlyBidder(address contractAddr, uint256 tokenId) {
        require(
            tokenIdToAuctions[contractAddr][tokenId].auctioneer != msg.sender,
            "Caller is auctioneer"
        );
        _;
    }

    modifier hasOffer(address contractAddr, uint256 tokenId) {
        require(
            _hasOffer(contractAddr, tokenId, msg.sender) == true,
            "You haven't got any offer for this token"
        );
        _;
    }

    modifier hasNoOffer(address contractAddr, uint256 tokenId) {
        require(
            _hasOffer(contractAddr, tokenId, msg.sender) == false,
            "You already have offer for this token"
        );
        _;
    }

    modifier hasBid(address contractAddr, uint256 tokenId) {
        require(
            _hasBid(contractAddr, tokenId, msg.sender) == true,
            "You haven't got any offer for this token"
        );
        _;
    }

    modifier hasNoBid(address contractAddr, uint256 tokenId) {
        require(
            _hasBid(contractAddr, tokenId, msg.sender) == false,
            "You already have offer for this token"
        );
        _;
    }

    modifier exists(address contractAddr) {
        require(
            addressesContractAddr != address(0),
            "Addresses Contract is not set yet"
        );
        require(
            AddressesInterface(addressesContractAddr).existingContract(
                contractAddr
            ) == true,
            "The Contract does not exist"
        );
        _;
    }

    modifier verified(address contractAddr) {
        require(
            AddressesInterface(addressesContractAddr).isVerified(
                contractAddr
            ) == true,
            "The Contract is not verified"
        );
        _;
    }

    function _hasOffer(
        address contractAddr,
        uint256 tokenId,
        address addr
    ) internal view returns (bool) {
        uint256 i;
        uint256 length = offers[contractAddr][tokenId].length;
        for (i = 0; i < length; ++i) {
            if (offers[contractAddr][tokenId][i].offerer == addr) {
                return true;
            }
        }
        return false;
    }

    function _hasBid(
        address contractAddr,
        uint256 tokenId,
        address addr
    ) internal view returns (bool) {
        uint256 i;
        uint256 length = bids[contractAddr][tokenId].length;
        for (i = 0; i < length; ++i) {
            if (bids[contractAddr][tokenId][i].bidder == addr) {
                return true;
            }
        }
        return false;
    }

    /// @dev Adds an sale to the list of open sales. Also fires the
    ///  SaleCreated event.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId The ID of the token to be put on sale.
    /// @param _sale Sale to add.
    function _addSale(
        address contractAddr,
        uint256 _tokenId,
        Sale memory _sale
    ) internal {
        // Require that all sales have a duration of
        // at least one minute. (Keeps our math from getting hairy!)

        tokenIdToSales[contractAddr][_tokenId] = _sale;
        saleTokenIds[contractAddr].push(_tokenId);
        saleTokenIdsBySeller[_sale.seller][contractAddr].push(_tokenId);

        emit SaleCreated(
            contractAddr,
            uint256(_tokenId),
            uint256(_sale.price),
            block.timestamp
        );
    }

    function _addAuction(
        address contractAddr,
        uint256 _tokenId,
        Auction memory _auction
    ) internal {
        // Require that all sales have a duration of
        // at least one minute. (Keeps our math from getting hairy!)

        tokenIdToAuctions[contractAddr][_tokenId] = _auction;
        auctionTokenIds[contractAddr].push(_tokenId);
        auctionTokenIdsBySeller[_auction.auctioneer][contractAddr].push(
            _tokenId
        );

        emit AuctionCreated(
            contractAddr,
            uint256(_tokenId),
            uint256(_auction.price),
            block.timestamp
        );
    }

    /// @dev Cancels an sale unconditionally.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId - ID of the token price we are canceling.
    function _cancelSale(address contractAddr, uint256 _tokenId) internal {
        _transfer(
            contractAddr,
            tokenIdToSales[contractAddr][_tokenId].seller,
            _tokenId
        );
        _removeSale(contractAddr, _tokenId);
        emit SaleCancelled(contractAddr, _tokenId);
    }

    function _cancelAuction(address contractAddr, uint256 _tokenId) internal {
        _transfer(
            contractAddr,
            tokenIdToAuctions[contractAddr][_tokenId].auctioneer,
            _tokenId
        );
        _removeAuction(contractAddr, _tokenId);
        emit AuctionCancelled(contractAddr, _tokenId);
    }

    function _purchase(
        address contractAddr,
        uint256 _tokenId,
        address seller,
        uint256 _buyPrice,
        uint256 price
    ) internal {
        // The bid is good! Remove the sale before sending the fees
        // to the sender so we can't have a reentrancy attack.
        uint256 saleValue;
        // Transfer proceeds to seller (if there are any!)
        uint256 devProfit;
        if (price > 0) {
            // Calculate the saler's cut.
            // (NOTE: _computeCut() is guaranteed to return a
            // value <= price, so this subtraction can't go negative.)
            // uint256 salerCut = _computeCut(price);
            // uint256 sellerProceeds = price - salerCut;
            // NOTE: Doing a transfer() in the middle of a complex
            // method like this is generally discouraged because of
            // reentrancy attacks and DoS attacks if the seller is
            // a contract with an invalid fallback function. We explicitly
            // guard against reentrancy attacks by removing the sale
            // before calling transfer(), and the only thing the seller
            // can DoS is the sale of their own asset! (And if it's an
            // accident, they can call cancelSale(). )
            if (_buyPrice > price) {
                devProfit = _buyPrice - price;
                // payable(dev).transfer(_buyPrice - price);
            }
            if (hasRoyalty(contractAddr)) {
                saleValue = _deduceRoyalties(contractAddr, _tokenId, price);
            } else {
                saleValue = price;
            }
            devProfit += price / 50;
            payable(dev).transfer(devProfit);
            payable(seller).transfer(saleValue - price / 50);
        }
    }

    /// @dev Computes the price and transfers winnings.
    /// Does NOT transfer ownership of token.
    function _buy(
        address contractAddr,
        uint256 _tokenId,
        uint256 _buyPrice
    ) internal returns (uint256) {
        // Get a reference to the sale struct
        Sale storage sale = tokenIdToSales[contractAddr][_tokenId];
        // Check that the buy is greater than or equal to the current price
        uint256 price = sale.price;
        require(
            _buyPrice >= price,
            "Buy price should be bigger than current price"
        );

        // Grab a reference to the seller before the sale struct
        // gets deleted.

        _removeSale(contractAddr, _tokenId);

        _purchase(contractAddr, _tokenId, sale.seller, _buyPrice, price);

        return price;
    }

    /// @dev Removes an sale from the list of open sales.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId - ID of NFT on sale.
    function _removeSale(address contractAddr, uint256 _tokenId) internal {
        uint256 i;
        uint256 length = saleTokenIds[contractAddr].length;
        for (i = 0; i < length; ++i) {
            if (saleTokenIds[contractAddr][i] == _tokenId) {
                break;
            }
        }
        require(i < length, "No sale for this NFT");
        saleTokenIds[contractAddr][i] = saleTokenIds[contractAddr][length - 1];
        saleTokenIds[contractAddr].pop();
        Sale storage sale = tokenIdToSales[contractAddr][_tokenId];
        length = saleTokenIdsBySeller[sale.seller][contractAddr].length;
        for (
            i = 0;
            saleTokenIdsBySeller[sale.seller][contractAddr][i] != _tokenId;
            ++i
        ) {}
        saleTokenIdsBySeller[sale.seller][contractAddr][
            i
        ] = saleTokenIdsBySeller[sale.seller][contractAddr][length - 1];
        saleTokenIdsBySeller[sale.seller][contractAddr].pop();
        delete tokenIdToSales[contractAddr][_tokenId];
        length = offers[contractAddr][_tokenId].length;
        for (i = 0; i < length; ++i) {
            payable(address(offers[contractAddr][_tokenId][i].offerer))
                .transfer(offers[contractAddr][_tokenId][i].price);
        }
        delete offers[contractAddr][_tokenId];
    }

    function _removeAuction(address contractAddr, uint256 _tokenId) internal {
        uint256 i;
        uint256 length = auctionTokenIds[contractAddr].length;
        for (i = 0; i < length; ++i) {
            if (auctionTokenIds[contractAddr][i] == _tokenId) {
                break;
            }
        }
        require(i < length, "No auction for this NFT");
        auctionTokenIds[contractAddr][i] = auctionTokenIds[contractAddr][
            length - 1
        ];
        auctionTokenIds[contractAddr].pop();
        Auction storage auction = tokenIdToAuctions[contractAddr][_tokenId];
        length = auctionTokenIdsBySeller[auction.auctioneer][contractAddr]
            .length;
        for (
            i = 0;
            auctionTokenIdsBySeller[auction.auctioneer][contractAddr][i] !=
            _tokenId;
            ++i
        ) {}
        auctionTokenIdsBySeller[auction.auctioneer][contractAddr][
            i
        ] = auctionTokenIdsBySeller[auction.auctioneer][contractAddr][
            length - 1
        ];
        auctionTokenIdsBySeller[auction.auctioneer][contractAddr].pop();
        delete tokenIdToAuctions[contractAddr][_tokenId];
        length = bids[contractAddr][_tokenId].length;
        for (i = 0; i < length; ++i) {
            payable(address(bids[contractAddr][_tokenId][i].bidder)).transfer(
                bids[contractAddr][_tokenId][i].price
            );
        }
        delete bids[contractAddr][_tokenId];
    }

    // function setRoyalty(
    //     address contractAddr,
    //     address[] calldata dests,
    //     uint256[] calldata profits
    // ) external {
    //     require(
    //         dests.length == profits.length,
    //         "Length of Addresses and Profits are different"
    //     );
    //     uint256 i;
    //     uint256 length = dests.length;
    //     uint256 sum = 0;
    //     for (i = 0; i < length; ++i) {
    //         sum += profits[i];
    //     }
    //     require(sum < 9500, "Total Sum of profit exceeds 95%");
    //     delete royalty[contractAddr];
    //     for (i = 0; i < length; ++i) {
    //         royalty[contractAddr].push(Royalty(dests[i], profits[i]));
    //     }
    // }

    // function getRoyalty(address contractAddr)
    //     public
    //     view
    //     returns (address[] memory, uint256[] memory)
    // {
    //     uint256 length = royalty[contractAddr].length;
    //     address[] memory dests = new address[](length);
    //     uint256[] memory profits = new uint256[](length);
    //     uint256 i;
    //     for (i = 0; i < length; ++i) {
    //         dests[i] = royalty[contractAddr][i].destination;
    //         profits[i] = royalty[contractAddr][i].profit;
    //     }
    //     return (dests, profits);
    // }

    /// @param contractAddr - Address of current Smart Contract
    function getSaleTokens(address contractAddr)
        public
        view
        returns (uint256[] memory)
    {
        return saleTokenIds[contractAddr];
    }

    function getAuctionTokens(address contractAddr)
        public
        view
        returns (uint256[] memory)
    {
        return auctionTokenIds[contractAddr];
    }

    /// @param contractAddr - Address of current Smart Contract
    function getSaleCnt(address contractAddr) public view returns (uint256) {
        return saleTokenIds[contractAddr].length;
    }

    function getAuctionCnt(address contractAddr) public view returns (uint256) {
        return auctionTokenIds[contractAddr].length;
    }

    /// @param contractAddr - Address of current Smart Contract
    function balanceOf(address contractAddr, address owner)
        public
        view
        returns (uint256)
    {
        ERC721 nftContract = ERC721(contractAddr);
        return nftContract.balanceOf(owner);
    }

    /// @param contractAddr - Address of current Smart Contract
    /// @param index - Index of token
    function tokenOfOwnerByIndex(
        address contractAddr,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        ERC721Enumerable nftContract = ERC721Enumerable(contractAddr);
        return nftContract.tokenOfOwnerByIndex(owner, index);
    }

    function ownerOf(address contractAddr, uint256 _tokenId)
        public
        view
        returns (address)
    {
        ERC721 nftContract = ERC721(contractAddr);
        return nftContract.ownerOf(_tokenId);
    }

    /// @param contractAddr - Address of current Smart Contract
    function tokenURI(address contractAddr, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        ERC721 nftContract = ERC721(contractAddr);
        return nftContract.tokenURI(tokenId);
    }

    function getSaleTokensBySeller(address seller, address contractAddr)
        public
        view
        returns (uint256[] memory)
    {
        return saleTokenIdsBySeller[seller][contractAddr];
    }

    function getAuctionTokensBySeller(address auctioneer, address contractAddr)
        public
        view
        returns (uint256[] memory)
    {
        return auctionTokenIdsBySeller[auctioneer][contractAddr];
    }

    /// @dev Escrows the NFT, assigning ownership to this contract.
    /// Throws if the escrow fails.
    /// @param _owner - Current owner address of token to escrow.
    /// @param _tokenId - ID of token whose approval to verify.
    function _escrow(
        address contractAddr,
        address _owner,
        uint256 _tokenId
    ) internal {
        // it will throw if transfer fails
        ERC721 nftContract = ERC721(contractAddr);
        nftContract.transferFrom(_owner, address(this), _tokenId);
    }

    function _transfer(
        address contractAddr,
        address _receiver,
        uint256 _tokenId
    ) internal {
        // it will throw if transfer fails
        ERC721 nftContract = ERC721(contractAddr);
        nftContract.transferFrom(address(this), _receiver, _tokenId);
    }

    function _send(
        address contractAddr,
        address _sender,
        address _receiver,
        uint256 _tokenId
    ) internal {
        ERC721 nftContract = ERC721(contractAddr);
        nftContract.transferFrom(_sender, _receiver, _tokenId);
        emit SendSuccessful(contractAddr, _tokenId, _receiver);
    }

    function _createOffer(
        address contractAddr,
        uint256 tokenId,
        address offerer,
        uint256 price
    ) internal {
        offers[contractAddr][tokenId].push(Offer(address(0), 0, 0));
        uint256 length = offers[contractAddr][tokenId].length;
        uint256 i;
        for (
            i = length - 1;
            i > 0 && offers[contractAddr][tokenId][i - 1].price > price;
            --i
        ) {
            offers[contractAddr][tokenId][i] = offers[contractAddr][tokenId][
                i - 1
            ];
        }
        offers[contractAddr][tokenId][i] = Offer(
            offerer,
            price,
            block.timestamp
        );
        emit OfferCreated(
            contractAddr,
            tokenId,
            offerer,
            price,
            block.timestamp
        );
    }

    function _bid(
        address contractAddr,
        uint256 tokenId,
        address bidder,
        uint256 price
    ) internal {
        bids[contractAddr][tokenId].push(Bid(bidder, price, block.timestamp));
        emit BidCreated(contractAddr, tokenId, bidder, price, block.timestamp);
    }

    function acceptOffer(address contractAddr, uint256 _tokenId)
        external
        exists(contractAddr)
        onSale(contractAddr, _tokenId)
        onlySeller(contractAddr, _tokenId)
    {
        uint256 offerLength = offers[contractAddr][_tokenId].length;
        require(offerLength > 0, "There is no offer on this token");
        address buyer = offers[contractAddr][_tokenId][offerLength - 1].offerer;
        uint256 price = offers[contractAddr][_tokenId][offerLength - 1].price;
        offers[contractAddr][_tokenId].pop();

        _removeSale(contractAddr, _tokenId);

        _purchase(
            contractAddr,
            _tokenId,
            tokenIdToSales[contractAddr][_tokenId].seller,
            price,
            price
        );

        _transfer(contractAddr, buyer, _tokenId);

        emit OfferAccepted(contractAddr, _tokenId, buyer);
    }

    function acceptBid(address contractAddr, uint256 _tokenId)
        external
        exists(contractAddr)
        onAuction(contractAddr, _tokenId)
        onlyAuctioneer(contractAddr, _tokenId)
    {
        uint256 bidlength = bids[contractAddr][_tokenId].length;
        require(bidlength > 0, "There is no bid on this auction");
        address buyer = bids[contractAddr][_tokenId][bidlength - 1].bidder;
        uint256 price = bids[contractAddr][_tokenId][bidlength - 1].price;
        bids[contractAddr][_tokenId].pop();

        _removeAuction(contractAddr, _tokenId);

        _purchase(
            contractAddr,
            _tokenId,
            tokenIdToAuctions[contractAddr][_tokenId].auctioneer,
            price,
            price
        );

        _transfer(contractAddr, buyer, _tokenId);

        emit BidAccepted(contractAddr, _tokenId, buyer);
    }

    /// @notice Checks if NFT contract implements the ERC-2981 interface
    /// @param _contract - the address of the NFT contract to query
    /// @return true if ERC-2981 interface is supported, false otherwise
    function hasRoyalty(address _contract) public view returns (bool) {
        bool success = IERC2981(_contract).supportsInterface(0x2a55205a); //_INTERFACE_ID_ERC2981=0x2a55205a
        return success;
    }

    function getRoyalty(address contractAddr, uint256 tokenId)
        external
        view
        exists(contractAddr)
        returns (address, uint256)
    {
        require(
            hasRoyalty(contractAddr) == true,
            "The contract does not have royalty"
        );
        (address recipient, uint256 royalty) = IERC2981(contractAddr)
            .royaltyInfo(tokenId, 10000);
        return (recipient, royalty);
    }

    /// @notice Transfers royalties to the rightsowner if applicable
    /// @param tokenId - the NFT assed queried for royalties
    /// @param grossSaleValue - the price at which the asset will be sold
    /// @return netSaleAmount - the value that will go to the seller after
    ///         deducting royalties
    function _deduceRoyalties(
        address contractAddr,
        uint256 tokenId,
        uint256 grossSaleValue
    ) internal returns (uint256 netSaleAmount) {
        // Get amount of royalties to pays and recipient
        (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(
            contractAddr
        ).royaltyInfo(tokenId, grossSaleValue);
        // Deduce royalties from sale value
        uint256 netSaleValue = grossSaleValue - royaltiesAmount;
        // Transfer royalties to rightholder if not zero
        if (royaltiesAmount > 0) {
            payable(royaltiesReceiver).transfer(royaltiesAmount);
        }
        // Broadcast royalties payment
        emit RoyaltiesPaid(contractAddr, tokenId, royaltiesAmount);
        return netSaleValue;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: ClockSale.sol



pragma solidity ^0.8.0;




/// @title Clock sale for non-fungible tokens.
/// @notice We omit a fallback function to prevent accidental sends to this contract.
contract ClockSale is Pausable, ClockSaleBase, Ownable {
    /// @dev The ERC-165 interface signature for ERC-721.
    ///  Ref: https://github.com/ethereum/EIPs/issues/165
    ///  Ref: https://github.com/ethereum/EIPs/issues/721
    // bytes4 constant InterfaceSignature_ERC721 = bytes4(0x9a20483d);

    /// @dev Remove all Ether from the contract, which is the owner's cuts
    ///  as well as any Ether sent directly to the contract address.
    ///  Always transfers to the NFT contract, but can be called either by
    ///  the owner or the NFT contract.

    /// @dev Creates and begins a new sale.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId - ID of token to sale, sender must be owner.
    /// @param price - Price of item (in wei) at beginning of sale.
    ///  price and ending price (in seconds).
    function createSale(
        address contractAddr,
        uint256 _tokenId,
        uint256 price
    )
        external
        virtual
        exists(contractAddr)
        verified(contractAddr)
        whenNotPaused
        owningToken(contractAddr, _tokenId)
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the sale struct.
        require(price == uint256(uint128(price)));

        _escrow(contractAddr, msg.sender, _tokenId);
        Sale memory sale = Sale(msg.sender, uint128(price), block.timestamp);
        _addSale(contractAddr, _tokenId, sale);
    }

    function createAuction(
        address contractAddr,
        uint256 _tokenId,
        uint256 price,
        uint256 duration
    )
        external
        virtual
        exists(contractAddr)
        verified(contractAddr)
        whenNotPaused
        owningToken(contractAddr, _tokenId)
    {
        // Sanity check that no inputs overflow how many bits we've allocated
        // to store them in the sale struct.
        require(price == uint256(uint128(price)));

        _escrow(contractAddr, msg.sender, _tokenId);
        Auction memory auction = Auction(
            msg.sender,
            uint128(price),
            duration,
            block.timestamp
        );
        _addAuction(contractAddr, _tokenId, auction);
    }

    /// @dev Buys on an open sale, completing the sale and transferring
    ///  ownership of the NFT if enough Ether is supplied.
    /// @param contractAddr - Address of current Smart Contract
    /// @param tokenId - ID of token to buy on.
    function buy(address contractAddr, uint256 tokenId)
        external
        payable
        virtual
        exists(contractAddr)
        whenNotPaused
        onSale(contractAddr, tokenId)
        onlyBuyer(contractAddr, tokenId)
    {
        // _buy will throw if the buy or funds transfer fails
        uint256 price = _buy(contractAddr, tokenId, msg.value);
        _transfer(contractAddr, msg.sender, tokenId);
        // Tell the world!
        emit SaleSuccessful(contractAddr, tokenId, price, msg.sender);
    }

    /// @dev Cancels an sale that hasn't been won yet.
    ///  Returns the NFT to original owner.
    /// @notice This is a state-modifying function that can
    ///  be called while the contract is paused.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId - ID of token on sale
    function cancelSale(address contractAddr, uint256 _tokenId)
        external
        exists(contractAddr)
        onSale(contractAddr, _tokenId)
        onlySeller(contractAddr, _tokenId)
    {
        _cancelSale(contractAddr, _tokenId);
    }

    function cancelAuction(address contractAddr, uint256 _tokenId)
        external
        exists(contractAddr)
        onAuction(contractAddr, _tokenId)
        onlyAuctioneer(contractAddr, _tokenId)
    {
        _cancelAuction(contractAddr, _tokenId);
    }

    /// @dev Cancels an sale when the contract is paused.
    ///  Only the owner may do this, and NFTs are returned to
    ///  the seller. This should only be used in emergencies.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId - ID of the NFT on sale to cancel.
    function cancelSaleWhenPaused(address contractAddr, uint256 _tokenId)
        external
        exists(contractAddr)
        whenPaused
        onlyOwner
        onSale(contractAddr, _tokenId)
    {
        _cancelSale(contractAddr, _tokenId);
    }

    /// @dev Returns sale info for an NFT on sale.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId - ID of NFT on sale.
    function getSale(address contractAddr, uint256 _tokenId)
        external
        view
        exists(contractAddr)
        onSale(contractAddr, _tokenId)
        returns (address seller, uint256 price)
    {
        Sale storage sale = tokenIdToSales[contractAddr][_tokenId];
        return (sale.seller, sale.price);
    }

    function getAuction(address contractAddr, uint256 _tokenId)
        external
        view
        exists(contractAddr)
        onAuction(contractAddr, _tokenId)
        returns (
            address auctioneer,
            uint256 price,
            uint256 startedAt,
            uint256 duration
        )
    {
        Auction storage auction = tokenIdToAuctions[contractAddr][_tokenId];
        return (
            auction.auctioneer,
            auction.price,
            auction.startedAt,
            auction.duration
        );
    }

    /// @dev Returns the current price of an sale.
    /// @param contractAddr - Address of current Smart Contract
    /// @param _tokenId - ID of the token price we are checking.
    function getCurrentPrice(address contractAddr, uint256 _tokenId)
        external
        view
        exists(contractAddr)
        onSale(contractAddr, _tokenId)
        returns (uint256)
    {
        return tokenIdToSales[contractAddr][_tokenId].price;
    }

    function transfer(
        address contractAddr,
        address _receiver,
        uint256 _tokenId
    )
        external
        virtual
        exists(contractAddr)
        whenNotPaused
        owningToken(contractAddr, _tokenId)
    {
        _send(contractAddr, msg.sender, _receiver, _tokenId);
    }

    function createOffer(address contractAddr, uint256 tokenId)
        external
        payable
        exists(contractAddr)
        onSale(contractAddr, tokenId)
        onlyBuyer(contractAddr, tokenId)
        hasNoOffer(contractAddr, tokenId)
    {
        require(
            msg.value < tokenIdToSales[contractAddr][tokenId].price,
            "Price should be lower than listing price"
        );
        _createOffer(contractAddr, tokenId, msg.sender, msg.value);
    }

    function bid(address contractAddr, uint256 tokenId)
        external
        payable
        exists(contractAddr)
        onAuction(contractAddr, tokenId)
        onlyBidder(contractAddr, tokenId)
        hasNoBid(contractAddr, tokenId)
    {
        require(
            block.timestamp <=
                tokenIdToAuctions[contractAddr][tokenId].startedAt +
                    tokenIdToAuctions[contractAddr][tokenId].duration,
            "Auction is already finished"
        );
        require(
            msg.value > tokenIdToAuctions[contractAddr][tokenId].price,
            "Bid in current price range"
        );
        uint256 bidLength = bids[contractAddr][tokenId].length;
        require(
            bidLength == 0 ||
                bids[contractAddr][tokenId][bidLength - 1].price < msg.value,
            "You should bid on higher price"
        );
        _bid(contractAddr, tokenId, msg.sender, msg.value);
    }

    function getOffers(address contractAddr, uint256 tokenId)
        external
        view
        exists(contractAddr)
        onSale(contractAddr, tokenId)
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 length = offers[contractAddr][tokenId].length;
        address[] memory offerers = new address[](length);
        uint256[] memory prices = new uint256[](length);
        uint256[] memory times = new uint256[](length);
        uint256 i;
        for (i = 0; i < length; ++i) {
            offerers[i] = offers[contractAddr][tokenId][i].offerer;
            prices[i] = offers[contractAddr][tokenId][i].price;
            times[i] = offers[contractAddr][tokenId][i].time;
        }
        return (offerers, prices, times);
    }

    function getBids(address contractAddr, uint256 tokenId)
        external
        view
        exists(contractAddr)
        onAuction(contractAddr, tokenId)
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 length = bids[contractAddr][tokenId].length;
        address[] memory bidders = new address[](length);
        uint256[] memory prices = new uint256[](length);
        uint256[] memory times = new uint256[](length);
        uint256 i;
        for (i = 0; i < length; ++i) {
            bidders[i] = bids[contractAddr][tokenId][i].bidder;
            prices[i] = bids[contractAddr][tokenId][i].price;
            times[i] = bids[contractAddr][tokenId][i].time;
        }
        return (bidders, prices, times);
    }

    function cancelOffer(address contractAddr, uint256 tokenId)
        external
        exists(contractAddr)
        onSale(contractAddr, tokenId)
        hasOffer(contractAddr, tokenId)
    {
        uint256 length = offers[contractAddr][tokenId].length;
        uint256 i;
        for (
            i = 0;
            i < length &&
                offers[contractAddr][tokenId][i].offerer != msg.sender;
            ++i
        ) {}
        require(i < length, "You haven't got offer");
        payable(address(msg.sender)).transfer(
            offers[contractAddr][tokenId][i].price
        );
        for (; i < length - 1; ++i) {
            offers[contractAddr][tokenId][i] = offers[contractAddr][tokenId][
                i + 1
            ];
        }
        offers[contractAddr][tokenId].pop();
        emit OfferCanceled(contractAddr, tokenId, msg.sender);
    }

    function cancelBid(address contractAddr, uint256 tokenId)
        external
        exists(contractAddr)
        onAuction(contractAddr, tokenId)
        hasBid(contractAddr, tokenId)
    {
        uint256 length = bids[contractAddr][tokenId].length;
        uint256 i;
        for (
            i = 0;
            i < length && bids[contractAddr][tokenId][i].bidder != msg.sender;
            ++i
        ) {}
        require(i < length, "You haven't got bid");
        payable(address(msg.sender)).transfer(
            bids[contractAddr][tokenId][i].price
        );
        for (; i < length - 1; ++i) {
            bids[contractAddr][tokenId][i] = bids[contractAddr][tokenId][i + 1];
        }
        bids[contractAddr][tokenId].pop();
        emit BidCanceled(contractAddr, tokenId, msg.sender);
    }

    function setAddressesContractAddr(address contractAddr) external {
        addressesContractAddr = contractAddr;
    }
}