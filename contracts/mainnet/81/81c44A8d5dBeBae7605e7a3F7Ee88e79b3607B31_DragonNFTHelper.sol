/**
 *Submitted for verification at snowtrace.io on 2022-03-17
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT


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



 


pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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



 


pragma solidity ^0.8.0;

////import "./IERC165.sol";

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



 


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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



 


pragma solidity ^0.8.0;

////import "../IERC721.sol";

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



 


pragma solidity ^0.8.0;

////import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}



 


pragma solidity ^0.8.0;

////import "./IERC721.sol";
////import "./IERC721Receiver.sol";
////import "./extensions/IERC721Metadata.sol";
////import "../../utils/Address.sol";
////import "../../utils/Context.sol";
////import "../../utils/Strings.sol";
////import "../../utils/introspection/ERC165.sol";

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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
}



 


pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
library EnumerableSet {
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



 


pragma solidity ^0.8.0;

////import "./IAccessControl.sol";
////import "../utils/Context.sol";
////import "../utils/Strings.sol";
////import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}



 


pragma solidity ^0.8.0;

////import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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



 


pragma solidity ^0.8.0;

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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



 


pragma solidity ^0.8.0;

////import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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



 


pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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



 


pragma solidity ^0.8.0;

////import "./IERC20.sol";
////import "./extensions/IERC20Metadata.sol";
////import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}



 


pragma solidity ^0.8.0;

////import "./IAccessControlEnumerable.sol";
////import "./AccessControl.sol";
////import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}



 


pragma solidity ^0.8.0;

////import "../ERC20.sol";
////import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}



 


pragma solidity ^0.8.0;

////import "../ERC20.sol";
////import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}



 


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



 


pragma solidity ^0.8.0;

////import "../ERC20.sol";
////import "../extensions/ERC20Burnable.sol";
////import "../extensions/ERC20Pausable.sol";
////import "../../../access/AccessControlEnumerable.sol";
////import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}



 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC20PresetMinterPauserEx is ERC20PresetMinterPauser
{

    using Counters for Counters.Counter;
    Counters.Counter public lastEventSeqNum;

    event TransferEx(address indexed from, address indexed to, uint256 value,uint256 indexed eventSeqNum);

    constructor(string memory name,string memory symbol)
        ERC20PresetMinterPauser(name,symbol)
    {

    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override    {
        lastEventSeqNum.increment();
        emit TransferEx(from,to,amount,lastEventSeqNum.current());
    }
}


 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;


interface PlayerStatusQueryInterface
{
    function stakingAmount(address stakedTokenAddr, address account, address nftAddress) view external returns(uint256);
    function rewardFoodsAmount(address stakedTokenAddr, address account, address nftAddress)view external returns(uint256);
}

contract PlayerStatusQueryMock is PlayerStatusQueryInterface
{
    constructor() {
    }

    function stakingAmount(address /*stakedTokenAddr*/,address /*account*/, address /*nftAddress*/) pure public override returns(uint256) {
        return 0;
    }

    function rewardFoodsAmount(address /*stakedTokenAddr*/,address /*account*/, address /*nftAddress*/) pure external override returns(uint256){
        return 0;
    }
}


 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

library MathEx
{
    function randRaw(uint256 number) public view returns(uint256) {
        if (number == 0) {
            return 0;
        }
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random % number;
    }

    function rand(uint256 number, uint256 seed) public view returns(uint256) {
        if (number == 0) {
            return 0;
        }
        uint256 random = uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.timestamp)));
        return random % number;
    }

    function randEx(uint256 seed) public view returns(uint256) {
        if (seed==0){
            return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        }else{
            return uint256(keccak256(abi.encodePacked(seed,block.difficulty, block.timestamp)));
        }
    }

    function scopeRandR(uint256 beginNumber,uint256 endNumber, uint256 rnd) public pure returns(uint256){
        if (endNumber <= beginNumber) {
            return beginNumber;
        }
        return (rnd % (endNumber-beginNumber+1))+beginNumber;
    }

//            }
//        }
//
//        uint256 parityPoint=rand(totalRarityProbability,seed);
//        for (uint256 i=0;i<6;++i){
//            if (parityPoint<probabilities[i]){
//                return i;
//            }
//        }
//
//        return 0;
//    }

    function probabilisticRandom6R(uint256 [6] memory probabilities, uint256 rnd) pure public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<6;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=rnd % totalRarityProbability;
        for (uint256 i=0;i<6;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }


    function probabilisticRandom4R(uint256 [4] memory probabilities, uint256 rnd) pure public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<4;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=rnd % totalRarityProbability;
        for (uint256 i=0;i<4;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }

    function probabilisticRandom5R(uint256 [5] memory probabilities, uint256 rnd) pure public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<5;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=rnd % totalRarityProbability;
        for (uint256 i=0;i<5;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }

}



 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "./ERC20PresetMinterPauserEx.sol";


contract ChestToken is ERC20PresetMinterPauserEx
{
    uint256 immutable public kind;

    constructor(uint256 kind_,string memory name, string memory symbol)
    ERC20PresetMinterPauserEx(name, symbol)
    {
        kind=kind_;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}




 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
////import "./MathEx.sol";
////import "./PlayerStatusQueryInterface.sol";

struct HatchCostInfo
{
    uint256 rubyCost;
    uint256 CSTCost;
}

struct FamilyDragonInfo
{
    uint256 dragonId;
    uint256 fatherDragonId;
    uint256 montherDragonId;
}

struct HeredityInfo
{
    uint256 id;  //eggNFT id , not dragonNFT Id
    FamilyDragonInfo fatherFamily;
    FamilyDragonInfo motherFamily;
}

struct Scope
{
    uint256 beginValue;
    uint256 endValue;
}


uint256 constant SUPER_CHEST=0;  //super chest and egg use
uint256 constant NORMAL_CHEST=1; //normal chest use
uint256 constant FOOD_CHEST=2;  //food chest use

uint256 constant NORMAL_RARITY = 0;
uint256 constant GOOD_RARITY = 1;
uint256 constant RARE_RARITY = 2;
uint256 constant EPIC_RARITY = 3;
uint256 constant LEGEND_RARITY = 4;
uint256 constant RARITY_MAX = 4;


uint256 constant PARTS_HEAD = 0;
uint256 constant PARTS_BODY = 1;
uint256 constant PARTS_LIMBS = 2;
uint256 constant PARTS_WINGS = 3;

uint256 constant ELEMENT_FIRE = 0x01;
uint256 constant ELEMENT_WATER = 0x02;
uint256 constant ELEMENT_LAND = 0x04;
uint256 constant ELEMENT_WIND = 0x08;
uint256 constant ELEMENT_LIGHT = 0x10;
uint256 constant ELEMENT_DARK = 0x20;

uint256 constant FRACTION_INT_BASE = 10000;

uint256 constant STAKING_NESTS_SUPPLY = 6;
uint256 constant HATCHING_NESTS_SUPPLY= 6;

uint256 constant MAX_STAKING_CST_WEIGHT_DELTA=FRACTION_INT_BASE/STAKING_NESTS_SUPPLY;
uint256 constant MAX_STAKING_CST_POWER_BYONE=4631;
uint256 constant MAX_STAKING_CST_POWER = MAX_STAKING_CST_POWER_BYONE*STAKING_NESTS_SUPPLY;

uint256 constant CLASS_NONE =0;
uint256 constant CLASS_ULTIMA = 0x01;
uint256 constant CLASS_FLASH = 0x02;
uint256 constant CLASS_OLYMPUS = 0x04;


uint256 constant DEFAULT_HATCH_TIMES = 5;

uint256 constant HATCH_MAX_TIMES =7  ;

uint256 constant DEFAULT_HATCHING_DURATION = 5 days;


interface IRandomHolder
{
    function getSeed() view external returns(uint256) ;
}


contract MetaInfoDb is AccessControlEnumerable
{
    address public CSTAddress; //CST token address
    address public rubyAddress; //RUBY token address
    address [3] public chestAddressArray; //Chest token address.0:super;1:normal;2:food

    address public dragonNFTAddr; //DragonNFT address
    address public eggNFTAddr;//EggNFT address
    address public accountInfoAddr; //AccountInfo contract

    address public CSTBonusPoolAddress;
    uint256 public CSTBonusPoolRate; //20%

    address public CSTOrganizeAddress;
    uint256 public CSTOrganizeRate; //10%

    address public CSTTeamAddress;
    uint256 public CSTTeamRate; //20%

    address public RUBYBonusPoolAddress;
    uint256 public RUBYBonusPoolRate; //20%

    address public RUBYOrganizeAddress;
    uint256 public RUBYOrganizeRate; //10%

    address public RUBYTeamAddress;
    uint256 public RUBYTeamRate; //20%

    address public USDBonusPoolAddress;
    uint256 public USDBonusPoolRate; //70%

    address public USDOrganizeAddress;
    uint256 public USDOrganizeRate; //10%

    address public USDTeamAddress;
    uint256 public USDTeamRate; //20%

    address public marketFeesReceiverAddress;

    //marketParams
    // feesRate >0 && <FRACTION_INT_BASE
    uint256 public marketFeesRate;


    uint256 [RARITY_MAX+1] [FOOD_CHEST] public rarityProbabilityFloatArray;


    Scope [RARITY_MAX+1] public stakingCSTPowerArray; 
    Scope [RARITY_MAX+1] public stakingRubyPowerArray;


    HatchCostInfo[HATCH_MAX_TIMES] public hatchCostInfos;

    uint256 public defaultHatchingDuration;

    Scope [RARITY_MAX+1] public lifeValueScopeArray;
    Scope [RARITY_MAX+1] public attackValueScopeArray;
    Scope [RARITY_MAX+1] public defenseValueScopeArray;
    Scope [RARITY_MAX+1] public speedValueScopeArray;

    mapping(uint256/** id */=>uint256 [4]) public partsLib; //index=0:head ; index=1:body ; index=2:limbs ; index=3:wings
    mapping(uint256/** id */=>uint256) public skillsLib;

    uint256 [6][2] public partsLibProb;
    uint256 [6][2] public skillsLibProb;
 
    uint256 [6] public elementProbArray;
    uint256 [6] public elementIdArray;

    uint256 [6] public elementHeredityProbArray;


    uint256 [5/**rarity */][5/**star */] [5/**rarity */] public starUpdateTable;


    uint256 [5/**rarity */] public qualityFactors;

    uint256 [RARITY_MAX+1] public outputFoodProbabilityArray;
    Scope [RARITY_MAX+1] public outputFoodScopeArray;

    address public playerStatusQueryInterface;

    uint256 [5] public rewardHatchingNestsCST;

    IRandomHolder private randomHolder;

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
        _;
    }

    constructor(address CSTAddr,address rubyAddr,address [3] memory chestAddrArray,address playerStatusQueryInterface_){
        CSTAddress=CSTAddr;
        rubyAddress=rubyAddr;
        chestAddressArray=chestAddrArray;
        playerStatusQueryInterface=playerStatusQueryInterface_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        rarityProbabilityFloatArray=[
            [600,365,30,5,0],  //super chest and egg
            [684,300,15,1,0]   //normal chest
        ];

        hatchCostInfos[0]=HatchCostInfo(3200000 ether,10 gwei);
        hatchCostInfos[1]=HatchCostInfo(6400000 ether,10 gwei);
        hatchCostInfos[2]=HatchCostInfo(9600000 ether,10 gwei);
        hatchCostInfos[3]=HatchCostInfo(16000000 ether,10 gwei);
        hatchCostInfos[4]=HatchCostInfo(25600000 ether,10 gwei);
        hatchCostInfos[5]=HatchCostInfo(41600000 ether,10 gwei);
        hatchCostInfos[6]=HatchCostInfo(67200000 ether,10 gwei);

        defaultHatchingDuration=DEFAULT_HATCHING_DURATION;







        
        elementProbArray=[20,20,20,20,10,10];
        elementIdArray=[ELEMENT_FIRE, ELEMENT_WATER, ELEMENT_LAND, ELEMENT_WIND,
                        ELEMENT_LIGHT, ELEMENT_DARK];

        elementHeredityProbArray=[30,30,10,10,10,10];

        partsLib[ELEMENT_FIRE]=[9,9,9,9];
        partsLib[ELEMENT_WATER]=[9,9,9,9];
        partsLib[ELEMENT_LAND]=[9,9,9,9];
        partsLib[ELEMENT_WIND]=[9,9,9,9];
        partsLib[ELEMENT_LIGHT]=[9,9,9,9];
        partsLib[ELEMENT_DARK]=[9,9,9,9];

        partsLibProb=[
                [0, 10, 90, 0, 0, 0],
                [40, 10, 50, 0, 0, 0]
        ];

        skillsLib[ELEMENT_FIRE]=20;
        skillsLib[ELEMENT_WATER]=20;
        skillsLib[ELEMENT_LAND]=20;
        skillsLib[ELEMENT_WIND]=20;
        skillsLib[ELEMENT_LIGHT]=20;
        skillsLib[ELEMENT_DARK]=20;

        skillsLibProb=[
                [0, 10, 90, 0, 0, 0],
                [40, 10, 50, 0, 0, 0]
        ];






        qualityFactors=[0,0,1,2,3];

        marketFeesRate=425;//4.25%
        marketFeesReceiverAddress=_msgSender();

        CSTBonusPoolRate=8000; //80%
        CSTOrganizeRate=1000; //10%
        CSTTeamRate=2000; //20%
        RUBYBonusPoolRate=2000; //20%
        RUBYOrganizeRate=1000; //10%
        RUBYTeamRate=2000; //20%
        USDBonusPoolRate=7000; //70%
        USDOrganizeRate=1000; //10%
        USDTeamRate=2000; //20%

        outputFoodProbabilityArray=[790,160,40,10,0];
        outputFoodScopeArray[NORMAL_RARITY]=Scope(2000 wei,9999 wei);
        outputFoodScopeArray[GOOD_RARITY]=Scope(10000 wei , 50000 wei);
        outputFoodScopeArray[RARE_RARITY]=Scope(50001 wei , 99999 wei);
        outputFoodScopeArray[EPIC_RARITY]=Scope(100000 wei , 299999 wei);
        outputFoodScopeArray[LEGEND_RARITY]=Scope(0,0);

        rewardHatchingNestsCST=[3000 gwei, 4500 gwei, 15000 gwei, 30000 gwei, 45000 gwei];

    }

    function initAttr() external onlyAdmin {
        stakingCSTPowerArray[NORMAL_RARITY]=Scope(1,1);//1
        stakingCSTPowerArray[GOOD_RARITY]=Scope(2,9);//2~9
        stakingCSTPowerArray[RARE_RARITY]=Scope(10,19);//10~19
        stakingCSTPowerArray[EPIC_RARITY]=Scope(20,29);//20~29
        stakingCSTPowerArray[LEGEND_RARITY]=Scope(30,40);//30~40

        stakingRubyPowerArray[NORMAL_RARITY]=Scope(10,15);//10~15
        stakingRubyPowerArray[GOOD_RARITY]=Scope(16,20);//16~20
        stakingRubyPowerArray[RARE_RARITY]=Scope(21,25);//21~25
        stakingRubyPowerArray[EPIC_RARITY]=Scope(26,30);//26~30
        stakingRubyPowerArray[LEGEND_RARITY]=Scope(31,40);//31~40


        lifeValueScopeArray[NORMAL_RARITY]=Scope(540,600);
        lifeValueScopeArray[GOOD_RARITY]=Scope(810,900);
        lifeValueScopeArray[RARE_RARITY]=Scope(960,1440);
        lifeValueScopeArray[EPIC_RARITY]=Scope(1260,2340);
        lifeValueScopeArray[LEGEND_RARITY]=Scope(2350,3000);
        
        attackValueScopeArray[NORMAL_RARITY]=Scope(90,110);
        attackValueScopeArray[GOOD_RARITY]=Scope(135,165);
        attackValueScopeArray[RARE_RARITY]=Scope(160,240);
        attackValueScopeArray[EPIC_RARITY]=Scope(210,390);
        attackValueScopeArray[LEGEND_RARITY]=Scope(395,500);

        defenseValueScopeArray[NORMAL_RARITY]=Scope(72,88);
        defenseValueScopeArray[GOOD_RARITY]=Scope(108,132);
        defenseValueScopeArray[RARE_RARITY]=Scope(128,192);
        defenseValueScopeArray[EPIC_RARITY]=Scope(168,312);
        defenseValueScopeArray[LEGEND_RARITY]=Scope(320,420);

        speedValueScopeArray[NORMAL_RARITY]=Scope(9,11);
        speedValueScopeArray[GOOD_RARITY]=Scope(13,17);
        speedValueScopeArray[RARE_RARITY]=Scope(16,24);
        speedValueScopeArray[EPIC_RARITY]=Scope(21,39);
        speedValueScopeArray[LEGEND_RARITY]=Scope(40,50);
        
    }

    function initStarTable() external onlyAdmin {
        

        starUpdateTable[NORMAL_RARITY]=[
            [1,0,0,0,0],
            [1,0,0,0,0],
            [2,0,0,0,0],
            [2,0,0,0,0],
            [3,0,0,0,0]
        ];

        starUpdateTable[GOOD_RARITY]=[
            [2,0,0,0,0],
            [2,0,0,0,0],
            [2,1,0,0,0],
            [2,2,0,0,0],
            [2,3,0,0,0]
        ];

        starUpdateTable[RARE_RARITY]=[
            [3,1,0,0,0],
            [3,1,0,0,0],
            [3,2,0,0,0],
            [3,2,0,0,0],
            [3,3,0,0,0]
        ];

        starUpdateTable[EPIC_RARITY]=[
            [4,1,0,0,0],
            [4,1,0,0,0],
            [4,2,0,0,0],
            [4,2,0,0,0],
            [2,4,0,0,0]
        ];

        starUpdateTable[LEGEND_RARITY]=[
            [4,1,0,0,0],
            [4,2,0,0,0],
            [2,4,0,0,0],
            [0,6,0,0,0],
            [0,6,0,0,0]
        ];

    }

    function queryRewardHatchingNestsCST(uint256 stakingCTSAmount) view public returns(uint256){
        for (uint256 i=0;i<5;++i){
            if (stakingCTSAmount<rewardHatchingNestsCST[i]){
                return i;
            }
        }
        return 5;
    }

    function setRewardHatchingNestsCST(uint256 [5] memory nestsCSTs) external onlyAdmin {
        rewardHatchingNestsCST=nestsCSTs;
    }

    function setPlayerStatusQueryInterface(address playerStatusQueryInterface_) external onlyAdmin {
        playerStatusQueryInterface=playerStatusQueryInterface_;
    }

    function setDefaultHatchingDuration(uint256 hatchingDuration) external onlyAdmin {
        defaultHatchingDuration=hatchingDuration;
    }

    function getOutputFoodProbabilityArray() view public returns(uint256 [RARITY_MAX+1] memory){
        return outputFoodProbabilityArray;
    }

    function setOutputFoodProbabilityArray(uint256 [RARITY_MAX+1] memory outputFoodProbabilityArray_) external onlyAdmin {
        outputFoodProbabilityArray=outputFoodProbabilityArray_;
    }

    function setRandomHolderInterface(address randomHolder_) external onlyAdmin {
        randomHolder=IRandomHolder(randomHolder_);
    }

    function setMarketFeesRate(uint256 marketFeesRate_) external onlyAdmin {
        require(marketFeesRate_<FRACTION_INT_BASE,"MetaInfoDb: marketFeesRate invalid");
        marketFeesRate=marketFeesRate_;
    }

    function setMarketFeesReceiverAddress(address marketFeesReceiverAddress_) external onlyAdmin {
        marketFeesReceiverAddress=marketFeesReceiverAddress_;
    }

    function setChestTokenAddress(uint256 kind,address chestAddr) external onlyAdmin {
        require(kind < chestAddressArray.length, "MetaInfoDb: index out of bound");
        chestAddressArray[kind]=chestAddr;
    }

    function setRarityParam(uint256 kind,uint256 rarity,uint256 probabilityFloat) external onlyAdmin {
        require(rarity<=LEGEND_RARITY);
        rarityProbabilityFloatArray[kind][rarity]=probabilityFloat;
    }

    function allRarityProbabilities() view public returns(uint256 [5] memory){
        return rarityProbabilityFloatArray[0];
    }

    function allNormalChestRarityProbabilities() view public returns(uint256 [5] memory){
        return rarityProbabilityFloatArray[1];
    }

    function setHatchCostInfo(uint256 index,uint256 rubyCost,uint256 CSTCost) external onlyAdmin {
        require(index<HATCH_MAX_TIMES,"MetaInfo: index must less then HATCH_MAX_TIMES");
        hatchCostInfos[index]=HatchCostInfo(rubyCost, CSTCost);
    }

    function getElementHeredityProbArray() view public returns(uint256 [6] memory){
        return elementHeredityProbArray;
    }

    function setElementHeredityProbArray(uint256 [6] memory probs) external onlyAdmin {
        elementHeredityProbArray=probs;
    }

    function allElementProbabilities() view public returns(uint256 [6] memory){
        return elementProbArray;
    }

    function getElementId(uint256 index) view public returns(uint256){
        return elementIdArray[index];
    }

    function getPartsLibCount(uint256 elementId) view public returns(uint256 [4] memory){
        return partsLib[elementId];
    }

    function getPartsProb(uint256 index) view public returns(uint256 [6] memory){
        return partsLibProb[index];
    }

    function getSkillsProb(uint256 index) view public returns(uint256 [6] memory){
        return skillsLibProb[index];
    }

    function setCSTAddr(address addr) external onlyAdmin {
        CSTAddress = addr;
    }

    function setRubyAddr(address addr) external onlyAdmin {
        rubyAddress = addr;
    }


    function setDragonNFTAddr(address addr) external onlyAdmin {
        dragonNFTAddr = addr;
    }

    function setEggNFTAddr(address addr) external onlyAdmin {
        eggNFTAddr = addr;
    }

    function setAccountInfoAddr(address addr) external onlyAdmin {
        accountInfoAddr = addr;
    }

    function setCSTBonusPoolAddress(address addr) external onlyAdmin {
        CSTBonusPoolAddress = addr;
    }
    function setCSTBonusPoolRate(uint256 rate) external onlyAdmin {
        CSTBonusPoolRate = rate;
    }

    function setCSTOrganizeAddress(address addr) external onlyAdmin {
        CSTOrganizeAddress = addr;
    }

    function setCSTOrganizeRate(uint256 rate) external onlyAdmin {
        CSTOrganizeRate = rate;
    }

    function setCSTTeamAddress(address addr) external onlyAdmin {
        CSTTeamAddress = addr;
    }
    function setCSTTeamRate(uint256 rate) external onlyAdmin {
        CSTTeamRate = rate;
    }

    function setRUBYBonusPoolAddress(address addr) external onlyAdmin {
        RUBYBonusPoolAddress = addr;
    }
    function setRUBYBonusPoolRate(uint256 rate) external onlyAdmin {
        RUBYBonusPoolRate = rate;
    }

    function setRUBYOrganizeAddress(address addr) external onlyAdmin {
        RUBYOrganizeAddress = addr;
    }
    function setRUBYOrganizeRate(uint256 rate) external onlyAdmin {
        RUBYOrganizeRate = rate;
    }

    function setRUBYTeamAddress(address addr) external onlyAdmin {
        RUBYTeamAddress = addr;
    }
    function setRUBYTeamRate(uint256 rate) external onlyAdmin {
        RUBYTeamRate = rate;
    }

    function setUSDBonusPoolAddress(address addr) external onlyAdmin {
        USDBonusPoolAddress = addr;
    }
    function setUSDBonusPoolRate(uint256 rate) external onlyAdmin {
        USDBonusPoolRate = rate;
    }

    function setUSDOrganizeAddress(address addr) external onlyAdmin {
        USDOrganizeAddress = addr;
    }
    function setUSDOrganizeRate(uint256 rate) external onlyAdmin {
        USDOrganizeRate = rate;
    }

    function setUSDTeamAddress(address addr) external onlyAdmin {
        USDTeamAddress = addr;
    }
    function setUSDTeamRate(uint256 rate) external onlyAdmin {
        USDTeamRate = rate;
    }

    function getStarUpdateTable(uint256 rarity,uint256 star) view public returns(uint256[5] memory){
        return starUpdateTable[rarity][star];
    }

    function setStarUpdateTable(uint256 rarity, uint256 star, uint256 [RARITY_MAX+1] memory rarityTable) external onlyAdmin {
        starUpdateTable[rarity][star]=rarityTable;
    }

    function setStakingCSTPowerArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        stakingCSTPowerArray[rarity]=Scope(lower, upper);
    }

    function setStakingRubyPowerArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        stakingRubyPowerArray[rarity]=Scope(lower, upper);
    }

    function setLifeValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        lifeValueScopeArray[rarity]=Scope(lower, upper);
    }
    
    function setAttackValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        attackValueScopeArray[rarity]=Scope(lower, upper);
    }

    function setDefenseValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        defenseValueScopeArray[rarity]=Scope(lower, upper);
    }

    function setSpeedValueScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        speedValueScopeArray[rarity]=Scope(lower, upper);
    }

    function setElementProbArray(uint256 element, uint256 prob) external onlyAdmin {
        elementProbArray[element]=prob;
    }

    function setQualityFactors(uint256 rarity, uint256 factor) external onlyAdmin {
        qualityFactors[rarity]=factor;
    }

    function setOutputFoodScopeArray(uint256 rarity, uint256 lower, uint256 upper) external onlyAdmin {
        outputFoodScopeArray[rarity]=Scope(lower, upper);
    }

    function setSkillsLib(uint256 elementId,uint256 count) external onlyAdmin {
        skillsLib[elementId]=count;
    }

    function setPartsLib(uint256 elementId,uint256 [4] memory counts) external onlyAdmin {
        partsLib[elementId]=counts;
    }

    function setPartsLibProb(uint256 index, uint256 [6] memory probs) external onlyAdmin {
        partsLibProb[index]=probs;
    }

    function setSkillsLibProb(uint256 index, uint256 [6] memory probs) external onlyAdmin {
        skillsLibProb[index]=probs;
    }



    function rand3() public view returns(uint256) {
        return MathEx.randEx(randomHolder.getSeed());
    }

    function calcRandRarity(uint256 kind) view public returns(uint256){
        return probabilisticRandom5(rarityProbabilityFloatArray[kind]);
    }

    function calcRandRarityR(uint256 kind, uint256 rnd) view public returns(uint256){
        return MathEx.probabilisticRandom5R(rarityProbabilityFloatArray[kind], rnd);
    }

    function isValidSignature(bytes32 messageHash, address publicKey, uint8 v, bytes32 r, bytes32 s) public pure returns(bool){
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address addr = ecrecover(prefixedHash, v, r, s);
        return (addr==publicKey);
    }

    function scopeRand(uint256 beginNumber,uint256 endNumber) public view returns(uint256){
        return MathEx.rand(endNumber-beginNumber+1,randomHolder.getSeed())+beginNumber;
    }


    function probabilisticRandom4(uint256 [4] memory probabilities) view public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<4;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=MathEx.rand(totalRarityProbability,randomHolder.getSeed());
        for (uint256 i=0;i<4;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }


    function probabilisticRandom5(uint256 [5] memory probabilities) view  public returns(uint256/**index*/){

        uint256 totalRarityProbability=0;
        for (uint256 i=0;i<5;++i){
            totalRarityProbability+=probabilities[i];
            if (i>0){
                probabilities[i]+=probabilities[i-1];
            }
        }

        uint256 parityPoint=MathEx.rand(totalRarityProbability,randomHolder.getSeed());
        for (uint256 i=0;i<5;++i){
            if (parityPoint<probabilities[i]){
                return i;
            }
        }

        return 0;
    }
}



 


pragma solidity ^0.8.0;

////import "../ERC721.sol";
////import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}



 


pragma solidity ^0.8.0;

////import "../ERC721.sol";
////import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}



 


pragma solidity ^0.8.0;

////import "../ERC721.sol";
////import "./IERC721Enumerable.sol";

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



 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
////import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
////import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
////import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
////import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract PresetMinterPauserAutoIdNFT is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;
    Counters.Counter public lastEventSeqNum;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    event TransferEx(address indexed from, address indexed to, uint256 tokenId,uint256 indexed eventSeqNum);

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require((!_isContract(msg.sender)) && (msg.sender == tx.origin), "contract not allowed");
        _;
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer(from,to,tokenId);

        lastEventSeqNum.increment();
        emit TransferEx(from, to, tokenId,lastEventSeqNum.current());
    }

    function _mint(address to, uint256 tokenId) internal virtual override{
        super._mint(to,tokenId);

        lastEventSeqNum.increment();
        emit TransferEx(address(0), to, tokenId,lastEventSeqNum.current());
    }

    function _burn(uint256 tokenId) internal virtual override{
        lastEventSeqNum.increment();
        address owner = ERC721.ownerOf(tokenId);

        super._burn(tokenId);

        emit TransferEx(owner, address(0), tokenId,lastEventSeqNum.current());
    }
}



 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "./@openzeppelin/contracts/access/AccessControl.sol";
////import "./@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
////import "./@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "./@openzeppelin/contracts/utils/Address.sol";
////import "./@openzeppelin/contracts/utils/Counters.sol";
////import "./MetaInfoDb.sol";
////import "./ChestToken.sol";
////import "./@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
////import "./PlayerStatusQueryInterface.sol";

contract AccountInfo is AccessControl
{
    using EnumerableSet for EnumerableSet.UintSet;
    using Address for address;
    address public metaInfoDbAddr;
    address public signPublicKey ;
    address public rubyAddress;

    using Counters for Counters.Counter;
    Counters.Counter public lastEventSeqNum;

    struct Info{
        address account;
        uint256 foodPoints;

        uint256 hatchingNests;
    }

    mapping(address=>Info) public infos;
    mapping(address=>mapping(string =>string)) extInfos;

    mapping(bytes32=>uint256) public usedSignatures;

    mapping(address=>EnumerableSet.UintSet) hatchingNestsSet ;

    mapping(bytes16=>uint256) public rubyActionUUIDs;

    event AccountCreated(address indexed account,uint256 foodPoint,uint256 hatchingNests,uint256 indexed eventSeqNum);
    // event AccountFoodsChanged(address account,uint256 foodPoint,bytes16 actionUUID,uint256 indexed eventSeqNum);
    event AccountFoodsChanged(address account,uint256 foodPointChanged,bool isAdded,uint256 foodPoint,bytes16 actionUUID,uint256 indexed eventSeqNum);
    event AccountHatchingNestsCountChanged(address account,uint256 hatchingNests,uint256 indexed eventSeqNum);
    event AccountHatchingNestsUsed(address account,uint256 eggTokenId,uint256 indexed eventSeqNum);
    event AccountHatchingNestsFree(address account,uint256 eggTokenId,uint256 indexed eventSeqNum);

    event AccountExtInfoChanged(address account,string name,string value,uint256 eventSeqNum);

    event AccountRubyChanged(address account,uint256 rubyAmount,bytes16 actionUUID,uint256 eventSeqNum);

    modifier notContract() {
        require(!msg.sender.isContract() && (msg.sender == tx.origin), "contract not allowed");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must have admin role.");
        _;
    }

    constructor(address metaInfoDbAddr_,address rubyTokenAddr,address signPublicKey_){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        rubyAddress=rubyTokenAddr;
        signPublicKey=signPublicKey_;
        resetAddress(metaInfoDbAddr_);

    }

    function newAccountIfNotExists(address account) public {
        if (infos[account].account==address(0)) {
            infos[account]=Info(account, 0, 1);
            lastEventSeqNum.increment();
            emit AccountCreated(account,0,1,lastEventSeqNum.current());
        }
    }

    function newAccount(address account,uint256 foodPoints_,uint256 hatchingNests_/* default 1 */,uint256 expiresAt, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(infos[account].account==address(0),"AccountInfo: account exists");

        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())){
            require(expiresAt > block.timestamp, "AccountInfo: time expired");
            bytes32 messageHash =  keccak256(
                abi.encodePacked(
                    signPublicKey,
                    account,
                    foodPoints_,
                    hatchingNests_,
                    "newAccount",
                    address(this),
                    expiresAt
                )
            );
            MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
            bool isValidSignature = metaInfo.isValidSignature(messageHash,signPublicKey,_v,_r,_s);
            require(isValidSignature,"AccountInfo: signature error");
        }

        infos[account]=Info(account,foodPoints_,hatchingNests_);

        lastEventSeqNum.increment();
        emit AccountCreated(account,foodPoints_,hatchingNests_,lastEventSeqNum.current());
    }

    function getRewardHatchingNestsByStaking(address account) view  public returns(uint256){
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        uint256 cstStakingCount =  PlayerStatusQueryInterface(metaInfo.playerStatusQueryInterface()).stakingAmount(metaInfo.CSTAddress(), account, metaInfo.dragonNFTAddr());
        return metaInfo.queryRewardHatchingNestsCST(cstStakingCount);
    }

    function mintRuby(uint256 amount, bytes16 actionUUID,uint8 _v, bytes32 _r, bytes32 _s) public{
        newAccountIfNotExists(_msgSender());
        require(rubyActionUUIDs[actionUUID]==0,"AccountInfo: action of mintRuby has been executed");

        bytes32 messageHash =  keccak256(
                abi.encodePacked(
                    signPublicKey,
                    amount,
                    actionUUID,
                    "mint",
                    address(this)
                )
        );
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        bool isValidSignature = metaInfo.isValidSignature(messageHash,signPublicKey,_v,_r,_s);
        require(isValidSignature,"signature error");

        rubyActionUUIDs[actionUUID]=block.timestamp;
        ERC20PresetMinterPauser(rubyAddress).mint(_msgSender(),amount);

        lastEventSeqNum.increment();
        emit AccountRubyChanged(_msgSender(),amount,actionUUID,lastEventSeqNum.current());
    }

    function burnRuby(uint256 amount, bytes16 actionUUID, uint8 _v, bytes32 _r, bytes32 _s) public{
        newAccountIfNotExists(_msgSender());
        require(rubyActionUUIDs[actionUUID]==0,"AccountInfo: action of burnRuby has been executed");

        bytes32 messageHash =  keccak256(
                abi.encodePacked(
                    signPublicKey,
                    amount,
                    actionUUID,
                    "burn",
                    address(this)
                )
        );
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        bool isValidSignature = metaInfo.isValidSignature(messageHash,signPublicKey,_v,_r,_s);
        require(isValidSignature,"signature error");

        rubyActionUUIDs[actionUUID]=block.timestamp;
        ERC20Burnable(rubyAddress).burnFrom(_msgSender(), amount);

        lastEventSeqNum.increment();
        emit AccountRubyChanged(_msgSender(),amount,actionUUID,lastEventSeqNum.current());
    }

    function removeFoodPoints(address account,uint256 value, bytes16 actionUUID, uint8 _v, bytes32 _r, bytes32 _s) public{
        newAccountIfNotExists(account);
        // require(infos[account].account!=address(0),"AccountInfo: no such account");
        bytes32 messageHash =  keccak256(
            abi.encodePacked(
                signPublicKey,
                account,
                value,
                actionUUID,
                "removeFoodPoints",
                address(this)
            )
        );
        require(usedSignatures[messageHash]==0,"AccountInfo: action has been executed");
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())){
            MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
            bool isValidSignature = metaInfo.isValidSignature(messageHash,signPublicKey,_v,_r,_s);
            require(isValidSignature,"AccountInfo: signature error");
        }
        usedSignatures[messageHash]=block.timestamp;
        infos[account].foodPoints-=value;
        lastEventSeqNum.increment();
        // emit AccountFoodsChanged(account,infos[account].foodPoints,actionUUID,lastEventSeqNum.current());
        emit AccountFoodsChanged(account,value,false,infos[account].foodPoints,actionUUID,lastEventSeqNum.current());
    }

    function addFoodPoints(address account,uint256 value, bytes16 actionUUID, uint8 _v, bytes32 _r, bytes32 _s) public{
        newAccountIfNotExists(account);
        // require(infos[account].account!=address(0),"AccountInfo: no such account");
            bytes32 messageHash =  keccak256(
                abi.encodePacked(
                    signPublicKey,
                    account,
                    value,
                    actionUUID,
                    "addFoodPoints",
                    address(this)
                )
            );
        require(usedSignatures[messageHash]==0,"AccountInfo: action has been executed");
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())){
            MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
            bool isValidSignature = metaInfo.isValidSignature(messageHash,signPublicKey,_v,_r,_s);
            require(isValidSignature,"AccountInfo: signature error");
        }
        usedSignatures[messageHash]=block.timestamp;
        infos[account].foodPoints+=value;
        lastEventSeqNum.increment();
        // emit AccountFoodsChanged(account,infos[account].foodPoints,actionUUID,lastEventSeqNum.current());
        emit AccountFoodsChanged(account,value,true,infos[account].foodPoints,actionUUID,lastEventSeqNum.current());
    }

    function foodPoints(address account) view public returns(uint256) {
        return infos[account].foodPoints;
    }

    function openFoodChest(address account) public notContract {
        newAccountIfNotExists(account);
        // require(infos[account].account!=address(0),"AccountInfo: no such account");
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        ChestToken chestToken=ChestToken(metaInfo.chestAddressArray(FOOD_CHEST));
        require(chestToken.balanceOf(_msgSender())>0,"AccountInfo: not enough Food Chest");


        uint256 index=metaInfo.probabilisticRandom5(metaInfo.getOutputFoodProbabilityArray());
        (uint256 beginValue,uint256 endValue)=metaInfo.outputFoodScopeArray(index);
        uint256 amount=metaInfo.scopeRand(beginValue,endValue);

        chestToken.burnFrom(_msgSender(), 1);
        infos[account].foodPoints+=amount;
        lastEventSeqNum.increment();
        // emit AccountFoodsChanged(account,infos[account].foodPoints,bytes16(0),lastEventSeqNum.current());
        emit AccountFoodsChanged(account,amount,true,infos[account].foodPoints,bytes16(0),lastEventSeqNum.current());
    }

    function hatchingNests(address account) view public returns(uint256 [] memory) {
        return hatchingNestsSet[account].values();
    }

    function hasRewardHatchingNestsWorking(address account) view external returns(bool){
        return hatchingNests(account).length>infos[account].hatchingNests;
    }

    function hatchingNestsCount(address account) view public returns(uint256){
        uint256 rewardNests=getRewardHatchingNestsByStaking(account);
        if (infos[account].hatchingNests+rewardNests == 0) {
            return 1;
        }
        return infos[account].hatchingNests+rewardNests;
    }


    //EggNFT contract call it 
    function putInHatchingNest(address account, uint256 eggTokenId) public onlyAdmin returns(bool){
        newAccountIfNotExists(account);
        // require(infos[account].account!=address(0),"AccountInfo: no such account");
        require(hatchingNestsCount(account)>hatchingNestsSet[account].length(),"AccountInfo: no enought HatchingNests");
        bool ret = hatchingNestsSet[account].add(eggTokenId);
        lastEventSeqNum.increment();
        emit AccountHatchingNestsUsed(account,eggTokenId,lastEventSeqNum.current());
        return ret;
    }

    //EggNFT contract call it 
    function takeOutHatchingNest(address account, uint256 eggTokenId) public onlyAdmin returns(bool){
        newAccountIfNotExists(account);
        // require(infos[account].account!=address(0),"AccountInfo: no such account");
        bool ret= hatchingNestsSet[account].remove(eggTokenId);
        lastEventSeqNum.increment();
        emit AccountHatchingNestsFree(account,eggTokenId,lastEventSeqNum.current());
        return ret;
    }

    //manager interfaces
    function setSignPublicKey(address signPublicKey_) external onlyAdmin {
        signPublicKey = signPublicKey_;
    }

    function setExtInfo(address account,string memory name,string memory value) public onlyAdmin {
        newAccountIfNotExists(account);
        // require(infos[account].account!=address(0),"AccountInfo: no such account");
        extInfos[account][name]=value;
        lastEventSeqNum.increment();
        emit AccountExtInfoChanged(account,name,value,lastEventSeqNum.current());
    }

    function resetAddress(address metaInfoDbAddr_) public onlyAdmin {

        metaInfoDbAddr =metaInfoDbAddr_;
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);

        _setupRole(DEFAULT_ADMIN_ROLE, metaInfo.eggNFTAddr());
    }

    function addHatchingNests(address account,uint256 nestsCount) public onlyAdmin {
        newAccountIfNotExists(account);
        // require(infos[account].account!=address(0),"AccountInfo: no such account");
        require(infos[account].hatchingNests+nestsCount<=HATCHING_NESTS_SUPPLY,"AccountInfo: hatchingNests must less than HATCHING_NESTS_SUPPLY");
        infos[account].hatchingNests+=nestsCount;

        lastEventSeqNum.increment();
        emit AccountHatchingNestsCountChanged(account,infos[account].hatchingNests,lastEventSeqNum.current());
    }

}



 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Address.sol";
////import "./PresetMinterPauserAutoIdNFT.sol";
////import "./MetaInfoDb.sol";
////import "./ChestToken.sol";
////import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";

uint256 constant ID=0;
uint256 constant FATHER_ID=1;
uint256 constant MOTHER_ID=2;
uint256 constant CLASS=3;
uint256 constant LEVEL=4;
uint256 constant STAR=5;
uint256 constant HATCH_TIMES=6;
uint256 constant RARITY=7;
uint256 constant INIT_STAKING_CST_POWER=8;
uint256 constant INIT_STAKING_RUBY_POWER=9;
uint256 constant LIFE_VALUE=10;
uint256 constant ATTACK_VALUE=11;
uint256 constant DEFENSE_VALUE=12;
uint256 constant SPEED_VALUE=13;

uint256 constant ELEMENT_ID=0;
uint256 constant SKILL_ID=1;
uint256 constant PARTS_IDS=2;
uint256 constant PARTS_HEAD_ID=PARTS_IDS+PARTS_HEAD;
uint256 constant PARTS_BODY_ID=PARTS_IDS+PARTS_BODY;
uint256 constant PARTS_LIMBS_ID=PARTS_IDS+PARTS_LIMBS;
uint256 constant PARTS_WINGS_ID=PARTS_IDS+PARTS_WINGS;

uint256 constant INFO_FIELDS_COUNT=SPEED_VALUE+1;
uint256 constant INFO_FIELDSEX_COUNT=PARTS_WINGS_ID+1;

contract DragonNFT is PresetMinterPauserAutoIdNFT
{
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    using Counters for Counters.Counter;

    address public metaInfoDbAddr;
    address public signPublicKey;

    mapping(bytes32=>uint256) public usedSignatures;

    mapping(uint256/** tokenId */=>uint256 [INFO_FIELDS_COUNT])  public fields;
    mapping(uint256/** tokenId */=>uint256 [INFO_FIELDSEX_COUNT])  public fieldsEx;

    mapping(uint256/** tokenId */=>uint256 [INFO_FIELDS_COUNT])  public fieldsTomb;
    mapping(uint256/** tokenId */=>uint256 [INFO_FIELDSEX_COUNT])  public fieldsExTomb;


    mapping(uint256/**rarity id */=>uint256/*total*/) public balanceInRarity;

    uint256 private _currentInfoId;
    uint256 [5/**star */] public levelOfStar;

    event NewDragonMinted(uint256 [INFO_FIELDS_COUNT] info, uint256 [INFO_FIELDSEX_COUNT] infoEx,uint256 indexed eventSeqNum);
    event DragonBurned(uint256 tokenId,uint256 indexed eventSeqNum);
    event DragonHatchTimesChanged(uint256 tokenId,uint256 hatchTimes,uint256 indexed eventSeqNum);
    event DragonStarChanged(uint256 tokenId,uint256 star,uint256 indexed eventSeqNum);
    event DragonStateChanged(uint256 tokenId,uint256 level, uint256 life,uint256 attack,uint256 defense,uint256 speed,uint256 rubyPower,bytes16 actionUUID,uint256 indexed eventSeqNum);

    function allFields(uint256 tokenId) view public returns(uint256 [INFO_FIELDS_COUNT] memory, uint256 [INFO_FIELDSEX_COUNT] memory){
        return (fields[tokenId], fieldsEx[tokenId]);
    }

    constructor(address eggNFTAddr,address metaInfoDbAddr_,string memory baseTokenURI,address signPublicKey_)
    PresetMinterPauserAutoIdNFT("DeDragon Dragon NFT","DDRN",baseTokenURI)
    {
        metaInfoDbAddr =metaInfoDbAddr_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, eggNFTAddr);
        _setupRole(MINTER_ROLE, address(this));
        signPublicKey = signPublicKey_;
        levelOfStar = [5, 15, 25, 35, 45];
    }


    function setSignPublicKey(address signPublicKey_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DragonNFT: must have admin role");
        signPublicKey = signPublicKey_;
    }


    function stakingCSTPower(uint256 tokenId) view public returns(uint256){
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        uint256 [INFO_FIELDS_COUNT] storage info=fields[tokenId];
        uint256 qf=metaInfo.qualityFactors(info[RARITY]);
        return info[INIT_STAKING_CST_POWER]+(info[LEVEL]-1)*info[INIT_STAKING_CST_POWER]*qf+((((info[LEVEL]/5)^2+(info[LEVEL]/5))/2)*(4^qf))*qf;
    }

    function stakingCSTWeight(uint256 tokenId) view public returns(uint256){
        uint256 weight = stakingCSTPower(tokenId)*FRACTION_INT_BASE/MAX_STAKING_CST_POWER;
        if (weight>MAX_STAKING_CST_WEIGHT_DELTA){
            weight=MAX_STAKING_CST_WEIGHT_DELTA;
        }
        return weight+FRACTION_INT_BASE;
    }

    function getFields(uint256 tokenId) view public returns(uint256[INFO_FIELDS_COUNT] memory){
        return fields[tokenId][ID] > 0 ? fields[tokenId] : fieldsTomb[tokenId];
    }

    function getFieldsEx(uint256 tokenId) view public returns(uint256[INFO_FIELDSEX_COUNT] memory){
        return fields[tokenId][ID] > 0 ? fieldsEx[tokenId] : fieldsExTomb[tokenId];
    }

    function initDragonInfo(uint256 id,uint256 class,uint256 kind, uint256 fatherId,uint256 motherId,uint256 rnd) internal {
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);

        uint256 [INFO_FIELDS_COUNT] storage info=fields[id];
        info[ID]=id;
        info[CLASS]=class;
        info[LEVEL]=1;
        info[HATCH_TIMES]=HATCH_MAX_TIMES;
        info[FATHER_ID] = fatherId;
        info[MOTHER_ID]= motherId;

        info[RARITY]=metaInfo.calcRandRarityR(kind, rnd);
        balanceInRarity[info[RARITY]]+=1;
        {
            (uint256 beginCST,uint256 endCST)=metaInfo.stakingCSTPowerArray(info[RARITY]);
            info[INIT_STAKING_CST_POWER]=MathEx.scopeRandR(beginCST,endCST, rnd/10);

            (uint256 beginRuby,uint256 endRuby)=metaInfo.stakingRubyPowerArray(info[RARITY]);
            info[INIT_STAKING_RUBY_POWER]=MathEx.scopeRandR(beginRuby,endRuby, rnd/100);
        }
        {
            (uint256 beginLife,uint256 endLife)=metaInfo.lifeValueScopeArray(info[RARITY]);
            info[LIFE_VALUE]=MathEx.scopeRandR(beginLife,endLife,rnd/1000);

            (uint256 beginAttack,uint256 endAttack)=metaInfo.attackValueScopeArray(info[RARITY]);
            info[ATTACK_VALUE]=MathEx.scopeRandR(beginAttack,endAttack, rnd/1e4);

            (uint256 beginDefense,uint256 endDefense) = metaInfo.defenseValueScopeArray(info[RARITY]);
            info[DEFENSE_VALUE]=MathEx.scopeRandR(beginDefense,endDefense, rnd/1e5);

            (uint256 beginSpeed,uint256 endSpeed) = metaInfo.speedValueScopeArray(info[RARITY]);
            info[SPEED_VALUE]=MathEx.scopeRandR(beginSpeed,endSpeed, rnd/1e6);
        }

    }

    //Only EggNFT or admin can call the function
    function mintUlitma (address to,uint256 count) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "DragonNFT: must have minter role to mintUlitma");
        for(uint256 i=0;i<count;++i){
            _mintUlitma(to,SUPER_CHEST,i);
        }
    }

    function _mintUlitma(address to,uint256 kind,uint256 seed) internal returns(uint256){
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        uint256 rnd = MathEx.randEx(seed);

        _currentInfoId=0;
        PresetMinterPauserAutoIdNFT(this).mint(to);
        require(_currentInfoId!=0,"DragonNFT: mint id error");
        uint256 [INFO_FIELDSEX_COUNT] storage infoEx=fieldsEx[_currentInfoId];

        initDragonInfo(_currentInfoId,CLASS_ULTIMA,kind,0,0,rnd/1e6);
        {

            infoEx[ELEMENT_ID]=metaInfo.getElementId(MathEx.probabilisticRandom6R(metaInfo.allElementProbabilities(), rnd));

            uint256 [4] memory partsCounts=metaInfo.getPartsLibCount(infoEx[ELEMENT_ID]);
            infoEx[PARTS_HEAD_ID]=(rnd / 10) % partsCounts[PARTS_HEAD] + 1;
            infoEx[PARTS_BODY_ID]=(rnd / 100) % partsCounts[PARTS_BODY] + 1;
            infoEx[PARTS_LIMBS_ID]=(rnd / 1000) % partsCounts[PARTS_LIMBS] + 1;
            infoEx[PARTS_WINGS_ID]=(rnd / 1e4) % partsCounts[PARTS_WINGS] + 1;

            uint256 skillsCount=metaInfo.skillsLib(infoEx[ELEMENT_ID]);
            infoEx[SKILL_ID]=(rnd / 1e5) % skillsCount + 1;
        }

        lastEventSeqNum.increment();
        emit NewDragonMinted(fields[_currentInfoId],fieldsEx[_currentInfoId],lastEventSeqNum.current());
        return  _currentInfoId;
    }

    function mintByChest(address to,uint256 chestKind) public notContract{

        require(chestKind==0||chestKind==1,"DragonNFT:chest type must be 0 or 1");
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        ChestToken chestToken=ChestToken(metaInfo.chestAddressArray(chestKind));
        require(chestToken.balanceOf(_msgSender())>0,"DragonNFT: not enough Chest");
        chestToken.burnFrom(_msgSender(), 1);
        _mintUlitma(to,chestKind,0);
    }



    function getHeredityInfo(uint256 tokenId) view public returns(HeredityInfo memory){
        uint256[INFO_FIELDS_COUNT] memory info = getFields(tokenId);
        return genHeredityInfo(tokenId,info[FATHER_ID],info[MOTHER_ID]);
    }

    function genHeredityInfo(uint256 tokenId,uint256 fatherTokenId,uint256 motherTokenId )view  public returns(HeredityInfo memory){
        HeredityInfo memory info;
        info.id=tokenId;
        uint256[INFO_FIELDS_COUNT] memory infoFather = getFields(fatherTokenId);
        uint256[INFO_FIELDS_COUNT] memory infoMother = getFields(motherTokenId);
        info.fatherFamily=FamilyDragonInfo(fatherTokenId,infoFather[FATHER_ID],infoFather[MOTHER_ID]);
        info.motherFamily=FamilyDragonInfo(motherTokenId,infoMother[FATHER_ID],infoMother[MOTHER_ID]);
        return info;
    }



    function selectFromHeredityR(uint256 fatherTokenId,uint256 motherTokenId, uint256 rnd) view internal returns(uint256/** tokenId */) {
        require(fatherTokenId!=0 && motherTokenId!=0, "DragonNFT: parent id must be none zero");
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        uint256 [6] memory elements=metaInfo.getElementHeredityProbArray();
        HeredityInfo memory fatherFamily=getHeredityInfo(fatherTokenId);
        HeredityInfo memory motherFamily=getHeredityInfo(motherTokenId);
        uint256 [6] memory dragons=[fatherTokenId,motherTokenId,
                                    fatherFamily.fatherFamily.dragonId!=0?fatherFamily.fatherFamily.dragonId:fatherTokenId,
                                    fatherFamily.motherFamily.dragonId!=0?fatherFamily.motherFamily.dragonId:fatherTokenId,
                                    motherFamily.fatherFamily.dragonId!=0?motherFamily.fatherFamily.dragonId:motherTokenId,
                                    motherFamily.motherFamily.dragonId!=0?motherFamily.motherFamily.dragonId:motherTokenId
                                    ];
        uint256 index=MathEx.probabilisticRandom6R(elements, rnd);
        return dragons[index];
    }







    function genPartsFromHeredityR(uint256 fatherTokenId,uint256 motherTokenId,uint256 selectTokenId,uint256 partsIndex, uint256 rnd) view internal returns(uint256){
        uint256 [6] memory parts = [uint256(0),0,0,0,0,0];

        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);

        if (selectTokenId!=fatherTokenId && selectTokenId!=motherTokenId){
            parts=metaInfo.getPartsProb(0);
        }else{
            parts=metaInfo.getPartsProb(1);
        }

        uint256 index=MathEx.probabilisticRandom6R(parts, rnd);
        uint256 [INFO_FIELDSEX_COUNT] memory infoExSel = getFieldsEx(selectTokenId);

        if (index==0 ){
            //return infoExs[selectTokenId].partsIds[partsIndex];
            return infoExSel[PARTS_IDS+partsIndex];
        }else if(index==1){
            if (selectTokenId!=fatherTokenId && selectTokenId!=motherTokenId){
                //return infoExs[selectTokenId].partsIds[partsIndex];
                return infoExSel[PARTS_IDS+partsIndex];
            }else{
                HeredityInfo memory family=getHeredityInfo(selectTokenId);
                uint256 [INFO_FIELDSEX_COUNT] memory infoExFather = getFieldsEx(family.fatherFamily.dragonId);
                uint256 [INFO_FIELDSEX_COUNT] memory infoExMother = getFieldsEx(family.motherFamily.dragonId);

                if (infoExFather[ELEMENT_ID]==infoExSel[ELEMENT_ID]){
                    return infoExFather[PARTS_IDS+partsIndex];
                }
                if (infoExMother[ELEMENT_ID]==infoExSel[ELEMENT_ID]){
                    return infoExMother[PARTS_IDS+partsIndex];
                }

            }
        }

        return rnd/10 % (metaInfo.partsLib(infoExSel[ELEMENT_ID],partsIndex))+1;

    }





    function genSkillsFromHeredityR(uint256 fatherTokenId,uint256 motherTokenId,uint256 selectTokenId, uint256 rnd) view internal returns(uint256){
        uint256 [6] memory parts = [uint256(0),0,0,0,0,0];

        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        if (selectTokenId!=fatherTokenId && selectTokenId!=motherTokenId){
            parts=metaInfo.getSkillsProb(0);
        }else{
            parts=metaInfo.getSkillsProb(1);
        }
        uint256 index=MathEx.probabilisticRandom6R(parts, rnd);
        uint256 [INFO_FIELDSEX_COUNT] memory infoExSel = getFieldsEx(selectTokenId);

        if (index==0 ){
            return infoExSel[SKILL_ID];
        }else if(index==1){
            if (selectTokenId!=fatherTokenId && selectTokenId!=motherTokenId){
                return infoExSel[SKILL_ID];
            }else{
                HeredityInfo memory family=getHeredityInfo(selectTokenId);
                uint256 [INFO_FIELDSEX_COUNT] memory infoExFather = getFieldsEx(family.fatherFamily.dragonId);
                uint256 [INFO_FIELDSEX_COUNT] memory infoExMother = getFieldsEx(family.motherFamily.dragonId);
                if (infoExFather[ELEMENT_ID]==infoExSel[ELEMENT_ID]){
                    return infoExFather[SKILL_ID];
                }
                if (infoExMother[ELEMENT_ID]==infoExSel[ELEMENT_ID]){
                    return infoExMother[SKILL_ID];
                }
            }
        }

        return rnd/10 % metaInfo.skillsLib(infoExSel[ELEMENT_ID]) + 1;
    }




    function mint(uint256 class,uint256 fatherTokenId,uint256 motherTokenId,address to) public returns(uint256 ){
        require(hasRole(MINTER_ROLE, _msgSender()), "DragonNFT: must have minter role to mint");
        require(class!=CLASS_ULTIMA,"DragonNFT: must call mintUlitma for Ulitma");
        require((fields[fatherTokenId][ID] > 0 || fieldsTomb[fatherTokenId][ID] > 0) && (fields[motherTokenId][ID] > 0 || fieldsTomb[motherTokenId][ID] > 0),"DragonNFT: parent id not exists");

        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        uint256 rnd = metaInfo.rand3();

        uint256 selDragonId=selectFromHeredityR(fatherTokenId,motherTokenId, rnd);
        _currentInfoId=0;
        super.mint(to);
        require(_currentInfoId!=0,"DragonNFT: mint id error");
        uint256 [INFO_FIELDSEX_COUNT] storage infoEx=fieldsEx[_currentInfoId];
        initDragonInfo(_currentInfoId,class,SUPER_CHEST,fatherTokenId, motherTokenId,rnd/1e7);

        {
            uint256 [INFO_FIELDSEX_COUNT] memory infoExSel = getFieldsEx(selDragonId);
            infoEx[ELEMENT_ID]=infoExSel[ELEMENT_ID];

            infoEx[PARTS_IDS+PARTS_HEAD]=genPartsFromHeredityR(fatherTokenId,motherTokenId,selDragonId,PARTS_HEAD, rnd/100);
            infoEx[PARTS_IDS+PARTS_BODY]=genPartsFromHeredityR(fatherTokenId,motherTokenId,selDragonId,PARTS_BODY, rnd/1000);
            infoEx[PARTS_IDS+PARTS_LIMBS]=genPartsFromHeredityR(fatherTokenId,motherTokenId,selDragonId,PARTS_LIMBS, rnd/1e4);
            infoEx[PARTS_IDS+PARTS_WINGS]=genPartsFromHeredityR(fatherTokenId,motherTokenId,selDragonId,PARTS_WINGS, rnd/1e5);

            infoEx[SKILL_ID]=genSkillsFromHeredityR(fatherTokenId,motherTokenId,selDragonId,rnd/1e6);
        }

        lastEventSeqNum.increment();
        emit NewDragonMinted(fields[_currentInfoId],fieldsEx[_currentInfoId],lastEventSeqNum.current());

        return _currentInfoId;
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override{
        if (from==address(0)){ //mint
            _currentInfoId=tokenId;
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }


    function subHatchTimes(uint256 tokenId) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "DragonNFT: must have minter role to subHatchTimes");
        fields[tokenId][HATCH_TIMES]-=1;

        lastEventSeqNum.increment();
        emit DragonHatchTimesChanged(tokenId,fields[tokenId][HATCH_TIMES],lastEventSeqNum.current());
    }

    function hatchCostInfo(uint256 tokenId) view public returns(HatchCostInfo memory){
        require(fields[tokenId][HATCH_TIMES]>0,"DragonNFT: No enough hatch times");

        uint256 hatchCount = HATCH_MAX_TIMES - fields[tokenId][HATCH_TIMES];
        (uint256 CSTCost,uint256 rubyCost)=MetaInfoDb(metaInfoDbAddr).hatchCostInfos(hatchCount);
        return HatchCostInfo(CSTCost,rubyCost);
    }


    function updateStar(uint256 dragonTokenId,uint256 [] calldata foodDragonTokenIds/** dragonNFT as food */) external {
        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);

        uint256 [INFO_FIELDS_COUNT] storage info=fields[dragonTokenId];

        require(info[LEVEL] >= levelOfStar[info[STAR]], "DragonNFT: level too low to updateStar");
        require(info[STAR] < 5, "DragonNFT: reach top star level");

        uint256 [5] memory foodDragons=metaInfo.getStarUpdateTable(info[RARITY],info[STAR]);

        uint256 k=0;
        for (uint256 i=0;i<5;++i){
            for (uint256 j=0;j<foodDragons[i];++j){
                uint256 tokenId=foodDragonTokenIds[k++];
                require (fields[tokenId][RARITY]==i,"DragonNFT:  the rarity does not match to updateStar");
                require (ownerOf(tokenId)==_msgSender(),"DragonNFT: Not your NFT");
                _burn(tokenId);
            }
        }
        fields[dragonTokenId][STAR] += 1;

        lastEventSeqNum.increment();
        emit DragonStarChanged(dragonTokenId,fields[dragonTokenId][STAR],lastEventSeqNum.current());
    }


    function isApprovedOrOwner(address spender, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(spender,tokenId);
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
        uint256  rarity = fields[tokenId][RARITY];
        if (balanceInRarity[rarity]>1){
            balanceInRarity[rarity]-=1;
        }
        fieldsTomb[tokenId] = fields[tokenId];
        fieldsExTomb[tokenId] = fieldsEx[tokenId];
        delete fields[tokenId];
        delete fieldsEx[tokenId];

        lastEventSeqNum.increment();
        emit DragonBurned(tokenId,lastEventSeqNum.current());
        //delete infoExs[tokenId];
        //delete heredityInfos[tokenId];
    }



    function updateStateBatch(uint256[] calldata stateArray,uint256[] calldata oldStateArray,uint256 expiresAt, bytes16 actionUUID, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(stateArray.length % 7 == 0, "DragonNFT: wrong length of data");
        require(expiresAt > block.timestamp, "time expired");
{
        bytes32 messageHash =  keccak256(
            abi.encodePacked(
                signPublicKey,
                stateArray,
                actionUUID,
                "updateState",
                address(this),
                expiresAt
            )
        );
        require(usedSignatures[messageHash]==0,"AccountInfo: action has been executed");
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())){
            bool isValidSignature = MetaInfoDb(metaInfoDbAddr).isValidSignature(messageHash,signPublicKey,_v,_r,_s);
            require(isValidSignature,"signature error");
        }
        usedSignatures[messageHash]=block.timestamp;
}
        for (uint256 i=0; i<stateArray.length; ) {
            uint256 tokenId = stateArray[i];
            require(oldStateArray[i++]==tokenId,"");
            uint256 [INFO_FIELDS_COUNT] storage info=fields[tokenId];

            require(info[LEVEL]==oldStateArray[i]);
            info[LEVEL]=stateArray[i++];
            require(info[LIFE_VALUE]==oldStateArray[i]);
            info[LIFE_VALUE]=stateArray[i++];
            require(info[ATTACK_VALUE]==oldStateArray[i]);
            info[ATTACK_VALUE]=stateArray[i++];
            require(info[DEFENSE_VALUE]==oldStateArray[i]);
            info[DEFENSE_VALUE]=stateArray[i++];
            require(info[SPEED_VALUE]==oldStateArray[i]);
            info[SPEED_VALUE]=stateArray[i++];
            require(info[INIT_STAKING_RUBY_POWER]==oldStateArray[i]);
            info[INIT_STAKING_RUBY_POWER]=stateArray[i++];

            lastEventSeqNum.increment();
            emit  DragonStateChanged(tokenId,
                    info[LEVEL],info[LIFE_VALUE],info[ATTACK_VALUE],info[DEFENSE_VALUE],info[SPEED_VALUE],info[INIT_STAKING_RUBY_POWER],
                    actionUUID,
                    lastEventSeqNum.current());
        }
    }

}



 


pragma solidity ^0.8.0;

////import "../ERC721.sol";
////import "../extensions/ERC721Enumerable.sol";
////import "../extensions/ERC721Burnable.sol";
////import "../extensions/ERC721Pausable.sol";
////import "../../../access/AccessControlEnumerable.sol";
////import "../../../utils/Context.sol";
////import "../../../utils/Counters.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC721PresetMinterPauserAutoId is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}



 


pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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



 

//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
////import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
////import "@openzeppelin/contracts/utils/Address.sol";
////import "./PresetMinterPauserAutoIdNFT.sol";
////import "./DragonNFT.sol";
////import "./MetaInfoDb.sol";
////import "./AccountInfo.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";

struct EggInfo {
    uint256 id;
    uint256 timestamp;
    uint256 hatchingBeginTime;
    uint256 remainingHatchDuration;
}


contract EggNFT is PresetMinterPauserAutoIdNFT
{
    using Address for address;
    address public metaInfoDbAddr;

    using Counters for Counters.Counter;

    mapping(uint256=>EggInfo) public infos;
    mapping(uint256=>HeredityInfo) public heredityInfos;

    uint256 private _currentInfoId;
    
    uint256 [5] public hatchingDurationArray;

    event NewEggMinted( EggInfo info, HeredityInfo heredityInfo,uint256 indexed eventSeqNum);
    event EggBurned( uint256 tokenId,uint256 indexed eventSeqNum);
    event EggHatchingStarted(uint256 tokenId,uint256 indexed eventSeqNum);
    event EggHatchingStopped(uint256 tokenId,uint256 indexed eventSeqNum);

    event NewDragonHatched(uint256 [INFO_FIELDS_COUNT] info, uint256 [INFO_FIELDSEX_COUNT] infoEx,uint256 indexed eventSeqNum);

    constructor(address metaInfoDbAddr_,string memory baseTokenURI)
    PresetMinterPauserAutoIdNFT("DeDragon Egg NFT","DDEN",baseTokenURI)
    {
        metaInfoDbAddr = metaInfoDbAddr_;
        _setupRole(MINTER_ROLE, address(this));
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        hatchingDurationArray=[50000, 100000, 150000, 200000, 300000];
    }


    function remainingHatchDuration(uint256 tokenId) view public returns(uint256){
        require(_exists(tokenId), "EggNFT: token must be minted");
        EggInfo storage eggInfo  = infos[tokenId];
        if (eggInfo.hatchingBeginTime==0){
            return eggInfo.remainingHatchDuration;
        }else{
            uint256 hatchingBeginTime=eggInfo.hatchingBeginTime;
            if (block.timestamp<eggInfo.hatchingBeginTime){
                hatchingBeginTime=block.timestamp;
            }
            uint256 hatchingPeriod = block.timestamp-hatchingBeginTime;
            if (eggInfo.remainingHatchDuration>hatchingPeriod){
                return eggInfo.remainingHatchDuration-hatchingPeriod;
            }else{
                return 0;
            }
        }
    }

    function startHatching(uint256 tokenId) public{
        require(_exists(tokenId), "EggNFT: the token must be minted");
        require(ownerOf(tokenId)==_msgSender(),"EggNFT: the token not yours");
        require(infos[tokenId].hatchingBeginTime==0,"EggNFT: the token has been hatching");
        require(infos[tokenId].timestamp > 1, "EggNFT: born and broken");
        
        infos[tokenId].hatchingBeginTime=block.timestamp;

        AccountInfo accountInfo=AccountInfo(MetaInfoDb(metaInfoDbAddr).accountInfoAddr());
        accountInfo.putInHatchingNest(_msgSender(), tokenId);

        lastEventSeqNum.increment();
        emit EggHatchingStarted(tokenId,lastEventSeqNum.current());
    }

    function stopHatching(uint256 tokenId) public{
        require(_exists(tokenId), "EggNFT: the token must be minted");
        require(ownerOf(tokenId)==_msgSender(),"EggNFT: the token not yours");
        require(infos[tokenId].hatchingBeginTime!=0,"EggNFT: the token has not been hatching");
        
        EggInfo storage eggInfo  = infos[tokenId]; 
        eggInfo.remainingHatchDuration=remainingHatchDuration(tokenId);
        eggInfo.hatchingBeginTime=0;

        AccountInfo accountInfo=AccountInfo(MetaInfoDb(metaInfoDbAddr).accountInfoAddr());
        accountInfo.takeOutHatchingNest(_msgSender(), tokenId);

        lastEventSeqNum.increment();
        emit EggHatchingStopped(tokenId,lastEventSeqNum.current());
    }


    function hatchNow(uint256 tokenId) public notContract {
        stopHatching(tokenId);
        require(infos[tokenId].hatchingBeginTime==0, "EggNFT: the token is hatching");
        require(remainingHatchDuration(tokenId)==0,"EggNFT: hatching not end");
        require(infos[tokenId].timestamp > 1, "EggNFT: born and broken");

        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        HeredityInfo storage info=heredityInfos[tokenId];

        delete infos[tokenId];
        _burn(tokenId);

        DragonNFT dragonNFT=DragonNFT(metaInfo.dragonNFTAddr());
        uint256 dragonId=dragonNFT.mint(CLASS_NONE,info.fatherFamily.dragonId,info.motherFamily.dragonId,_msgSender());

        lastEventSeqNum.increment();
        emit NewDragonHatched(dragonNFT.getFields(dragonId),dragonNFT.getFieldsEx(dragonId),lastEventSeqNum.current());

        lastEventSeqNum.increment();
        emit EggBurned(tokenId,lastEventSeqNum.current());

    }


    function mint(uint256 fatherTokenId,uint256 motherTokenId,address to) public notContract {
        DragonNFT dragonNFT=DragonNFT(MetaInfoDb(metaInfoDbAddr).dragonNFTAddr());
        require(dragonNFT.ownerOf(fatherTokenId)==_msgSender(),"EggNFT: father is not yours");
        require(dragonNFT.ownerOf(motherTokenId)==_msgSender(),"EggNFT: mother is not yours");

        require(!isCloseRelativeWith(fatherTokenId,motherTokenId),"EggNFT: Inbreeding is prohibited");

        HatchCostInfo memory hatchCostInfoFather = dragonNFT.hatchCostInfo(fatherTokenId);
        HatchCostInfo memory hatchCostInfoMonther = dragonNFT.hatchCostInfo(motherTokenId);

        MetaInfoDb metaInfo=MetaInfoDb(metaInfoDbAddr);
        uint256 totalCst=hatchCostInfoFather.CSTCost+hatchCostInfoMonther.CSTCost;
        uint256 totalRuby=hatchCostInfoFather.rubyCost+hatchCostInfoMonther.rubyCost;
        require(ERC20Burnable(metaInfo.CSTAddress()).balanceOf(_msgSender())>=totalCst,"No enought CST");
        require(ERC20Burnable(metaInfo.rubyAddress()).balanceOf(_msgSender())>=totalRuby,"No enought RUBY");

        {
        uint256 rubyBonusAmount=totalRuby*metaInfo.RUBYBonusPoolRate()/FRACTION_INT_BASE;
        uint256 rubyOrgAmount=totalRuby*metaInfo.RUBYOrganizeRate()/FRACTION_INT_BASE;
        uint256 rubyTeamAmount=totalRuby*metaInfo.RUBYTeamRate()/FRACTION_INT_BASE;
        IERC20(metaInfo.rubyAddress()).transferFrom(_msgSender(),metaInfo.RUBYBonusPoolAddress(),rubyBonusAmount);
        IERC20(metaInfo.rubyAddress()).transferFrom(_msgSender(),metaInfo.RUBYOrganizeAddress(),rubyOrgAmount);
        IERC20(metaInfo.rubyAddress()).transferFrom(_msgSender(),metaInfo.RUBYTeamAddress(),rubyTeamAmount);
        ERC20Burnable(metaInfo.rubyAddress()).burnFrom(_msgSender(), totalRuby-rubyBonusAmount-rubyOrgAmount-rubyTeamAmount);

        uint256 cstBonusAmount=totalCst*metaInfo.CSTBonusPoolRate()/FRACTION_INT_BASE;
        uint256 cstOrgAmount=totalCst*metaInfo.CSTOrganizeRate()/FRACTION_INT_BASE;
        IERC20(metaInfo.CSTAddress()).transferFrom(_msgSender(),metaInfo.CSTBonusPoolAddress(),cstBonusAmount);
        IERC20(metaInfo.CSTAddress()).transferFrom(_msgSender(),metaInfo.CSTOrganizeAddress(),cstOrgAmount);
        IERC20(metaInfo.CSTAddress()).transferFrom(_msgSender(),metaInfo.CSTTeamAddress(),totalCst-cstBonusAmount-cstOrgAmount);
        //ERC20Burnable(metaInfo.CSTAddress()).burnFrom(_msgSender(), totalCst-cstBonusAmount-cstOrgAmount);
        }

        dragonNFT.subHatchTimes(fatherTokenId);
        dragonNFT.subHatchTimes(motherTokenId);

        _currentInfoId=0;
        PresetMinterPauserAutoIdNFT(this).mint(to);
        require(_currentInfoId!=0,"EggNFT: mint id error");
        uint256 duration = metaInfo.defaultHatchingDuration();
        uint256 dragonNum = dragonNFT.totalSupply();
        for (uint256 i=0; i<hatchingDurationArray.length; i++) {
            if (dragonNum < hatchingDurationArray[hatchingDurationArray.length-1-i] && duration > 1 days) {
                duration -= 1 days;
            }
        }

        infos[_currentInfoId]=EggInfo(_currentInfoId,block.timestamp,0,duration);
        heredityInfos[_currentInfoId]=dragonNFT.genHeredityInfo(_currentInfoId,fatherTokenId,motherTokenId);

        lastEventSeqNum.increment();
        emit NewEggMinted(infos[_currentInfoId],heredityInfos[_currentInfoId],lastEventSeqNum.current());
    }

    function getHatchingDurationArray() view public returns(uint256 [5] memory) {
        return hatchingDurationArray;
    }

    function setHatchingDurationArray(uint256 [5] memory hatchingDurationArray_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "EggNFT: must have admin role to setHatchingDurationArray");
        hatchingDurationArray=hatchingDurationArray_;
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override{
        if (from==address(0)){
            _currentInfoId=tokenId;
        }
        require(infos[tokenId].hatchingBeginTime==0, "EggNFT: the token is hatching");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isCloseRelativeWith(uint256 tokenId1,uint256 tokenId2) view public returns(bool){
        DragonNFT dragonNFT=DragonNFT(MetaInfoDb(metaInfoDbAddr).dragonNFTAddr());
        HeredityInfo memory hinfo=dragonNFT.getHeredityInfo(tokenId1);
        uint256 [7] memory ids=[
            tokenId1,
            hinfo.fatherFamily.dragonId,
            hinfo.fatherFamily.fatherDragonId,
            hinfo.fatherFamily.montherDragonId,
            hinfo.motherFamily.dragonId,
            hinfo.motherFamily.fatherDragonId,
            hinfo.motherFamily.montherDragonId
        ];
        HeredityInfo memory hinfo2=dragonNFT.getHeredityInfo(tokenId2);
        uint256 [7] memory ids2=[
            tokenId2,
            hinfo2.fatherFamily.dragonId,
            hinfo2.fatherFamily.fatherDragonId,
            hinfo2.fatherFamily.montherDragonId,
            hinfo2.motherFamily.dragonId,
            hinfo2.motherFamily.fatherDragonId,
            hinfo2.motherFamily.montherDragonId
        ];

        for (uint256 j=0;j<7;++j){
            uint256 id=ids2[j];
            if (id == 0) continue;
            for (uint256 i=0;i<7;++i){
                if (ids[i] == 0) continue;
                if (id==ids[i]){
                    return true;
                }
            }
        }
        return false;
    }

}



//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//CryptoSteam @2021,All rights reserved
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.

pragma solidity ^0.8.0;

////import "./DragonNFT.sol";
////import "./EggNFT.sol";
////import "@openzeppelin/contracts/utils/math/Math.sol";
////import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

    struct DragonInfo{
        uint256 id;   //0

        uint256 class ;
        uint256 level;
        uint256 star;
        uint256 hatchTimes;

        uint256 rarity;

        uint256 stakingCSTPower;
        uint256 initialStakingRubyPower;

        uint256 lifeValue;
        uint256 attackValue;
        uint256 defenseValue;
        uint256 speedValue;

        uint256 elementId;
        uint256 skillId;
        uint256 [4] partsIds;

    }


    struct DragonBriefInfo
    {
        uint256 id;
        uint256 elementId;
        uint256 [4] partsIds;
        uint256 rarity;
        uint256 class ;
        uint256 level;
        uint256 star;
        uint256 hatchTimes;
    }


contract DragonNFTHelper
{
    address public immutable metaInfoDbAddress;
    address public immutable dragonNFTAddress;
    address public immutable eggNFTAddress;

    constructor(address metaInfoDbAddr, address dragonNFTAddr, address eggNFTAddr){
        metaInfoDbAddress=metaInfoDbAddr;
        dragonNFTAddress=dragonNFTAddr;
        eggNFTAddress=eggNFTAddr;
    }


    function briefInfos(uint256 tokenId) view public returns(DragonBriefInfo memory){
        (uint256 [INFO_FIELDS_COUNT] memory info, uint256 [INFO_FIELDSEX_COUNT] memory infoEx)=DragonNFT(dragonNFTAddress).allFields(tokenId);
        return DragonBriefInfo(
            info[ID],infoEx[ELEMENT_ID],
            [infoEx[PARTS_HEAD_ID],infoEx[PARTS_BODY_ID],infoEx[PARTS_LIMBS_ID],infoEx[PARTS_WINGS_ID]],
            info[RARITY],
            info[CLASS],info[LEVEL],info[STAR],
            info[HATCH_TIMES]
        );
    }

    function infos(uint256 tokenId) view public returns(DragonInfo memory){
        (uint256 [INFO_FIELDS_COUNT] memory info, uint256 [INFO_FIELDSEX_COUNT] memory infoEx)=DragonNFT(dragonNFTAddress).allFields(tokenId);
        return DragonInfo(info[ID],info[CLASS],info[LEVEL],info[STAR],info[HATCH_TIMES],info[RARITY],
            DragonNFT(dragonNFTAddress).stakingCSTPower(tokenId),info[INIT_STAKING_RUBY_POWER],
            info[LIFE_VALUE],info[ATTACK_VALUE],info[DEFENSE_VALUE],info[SPEED_VALUE],infoEx[ELEMENT_ID],infoEx[SKILL_ID],
            [infoEx[PARTS_HEAD_ID],infoEx[PARTS_BODY_ID],infoEx[PARTS_LIMBS_ID],infoEx[PARTS_WINGS_ID]]);
    }

    function listIds(address user,uint256 beginIndex,uint256 count) view public returns(uint256 [] memory){
        uint256 balance=DragonNFT(dragonNFTAddress).balanceOf(user);
        require(beginIndex+count<=balance,"DragonNFTHelper: Invalid beginIndex pr count");

        uint256 [] memory ids=new uint256[](count);
        uint256 curIdx=0;
        for (uint256 i=beginIndex;i<beginIndex+count;++i){
            uint256 tokenId=DragonNFT(dragonNFTAddress).tokenOfOwnerByIndex(user,i);
            ids[curIdx++]=tokenId;
        }
        return ids;
    }

    function listByIndex(address user,uint256 beginIndex,uint256 count) view external returns(DragonBriefInfo [] memory){
        return list(listIds(user,beginIndex,count));
    }

    function list(uint256 [] memory tokenIds) view public returns(DragonBriefInfo [] memory){
        DragonBriefInfo [] memory binfos=new DragonBriefInfo [](tokenIds.length);
        for (uint256 i=0;i<tokenIds.length;++i){
            binfos[i]=briefInfos(tokenIds[i]);
        }
        return binfos;
    }

    function listEggNFT(uint256 [] memory tokenIds) view external returns(EggInfo [] memory){
        EggInfo [] memory eggInfos=new EggInfo [](tokenIds.length);
        for (uint256 i=0;i<tokenIds.length;++i){
            (uint256 id,uint256 timestamp,uint256 hatchingBeginTime,uint256 remainingHatchDuration) = EggNFT(eggNFTAddress).infos(tokenIds[i]);
            eggInfos[i] = EggInfo(id,timestamp,hatchingBeginTime,remainingHatchDuration);
        }
        return eggInfos;
    }

    function getPartsIds(uint256 tokenId) view public returns(uint256 [4] memory){
        (, uint256 [INFO_FIELDSEX_COUNT] memory infoEx)=DragonNFT(dragonNFTAddress).allFields(tokenId);
        return [infoEx[PARTS_HEAD_ID],infoEx[PARTS_BODY_ID],infoEx[PARTS_LIMBS_ID],infoEx[PARTS_WINGS_ID]];
    }

    function findParentIds(uint256 tokenId) view  public returns(uint256,uint256){
        (uint256 [INFO_FIELDS_COUNT] memory info, )=DragonNFT(dragonNFTAddress).allFields(tokenId);
        return (info[FATHER_ID],info[MOTHER_ID]);
    }

    function rarityOf(uint256 tokenId) view public returns(uint256){
        return DragonNFT(dragonNFTAddress).fields(tokenId,RARITY);
    }

    function getNFTIds(address nftAddr, uint256 beginIndex, uint256 length) view public returns(uint256[] memory) {
        ERC721Enumerable nft = ERC721Enumerable(nftAddr);
        uint256 totalSupply = nft.totalSupply();
        uint256 endIndex=Math.min(totalSupply,beginIndex+length);

        uint256[] memory ids = new uint256[](endIndex-beginIndex);
        for(uint256 i=beginIndex;i<endIndex;++i){
            ids[i-beginIndex] = nft.tokenByIndex(i);
        }
        return ids;
    }
}