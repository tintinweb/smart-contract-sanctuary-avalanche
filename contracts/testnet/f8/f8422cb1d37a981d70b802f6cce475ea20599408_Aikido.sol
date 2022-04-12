/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
*/

// File: contracts/StreetBrawlerz/interfaces/IBallot.sol


pragma solidity 0.8.12;

interface IBallot {
    function forceUnvote(address _user) external;
    function vote(address user, uint256 vefight) external;
    function unvote(address user, uint256 vefight) external;
    function count() external;
}
// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: contracts/StreetBrawlerz/veFight.sol


pragma solidity 0.8.12;



// solhint-disable-next-line
contract veFight {
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "veFIGHT";
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "veFIGHT";

    address public immutable FIGHT;

    /*///////////////////////////////////////////////////////////////
                           FIGHT/VEFIGHT GENERATION
    //////////////////////////////////////////////////////////////*/

    struct GenerationDetails {
        uint128 maxRatio;
        uint64 generationRateNumerator;
        uint64 generationRateDenominator;
    }

    GenerationDetails public genDetails;

    mapping(address => uint256) public fightBalanceOf;
    mapping(address => uint256) private veFightBalance;
    mapping(address => uint256) private userSnapshot;

    /*///////////////////////////////////////////////////////////////
                              VOTING
    //////////////////////////////////////////////////////////////*/

    address[] public arrValidBallots;
    mapping(address => bool) public validBallots;
    mapping(address => mapping(address => bool)) public hasUserVoted;

    /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error InvalidAmount();
    error InvalidProposal();

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    event UpdatedOwner(address indexed owner);
    event AddedBallot(address indexed ballot);
    event RemovedBallot(address indexed ballot);

    /*///////////////////////////////////////////////////////////////
                            CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _fightAddress,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator,
        uint256 _maxRatio
    ) {
        owner = msg.sender;

        FIGHT = _fightAddress;

        genDetails = GenerationDetails({
            maxRatio: uint128(_maxRatio),
            generationRateNumerator: uint64(_generationRateNumerator),
            generationRateDenominator: uint64(_generationRateDenominator)
        });
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setGenerationDetails(
        uint256 _maxRatio,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator
    ) external onlyOwner {
        GenerationDetails storage gen = genDetails;
        gen.maxRatio = uint128(_maxRatio);
        gen.generationRateNumerator = uint64(_generationRateNumerator);
        gen.generationRateDenominator = uint64(_generationRateDenominator);
    }

    /*///////////////////////////////////////////////////////////////
                               BALLOTS
    //////////////////////////////////////////////////////////////*/

    modifier onlyBallot() {
        if (!validBallots[msg.sender]) revert Unauthorized();
        _;
    }

    function addBallot(address ballot) external onlyOwner {
        if (!validBallots[ballot]) {
            arrValidBallots.push(ballot);
            validBallots[ballot] = true;
            emit AddedBallot(ballot);
        }
    }

    function removeBallot(uint256 index) external onlyOwner {
        address removed = arrValidBallots[index];

        arrValidBallots[index] = arrValidBallots[arrValidBallots.length - 1];
        arrValidBallots.pop();

        delete validBallots[removed];

        emit RemovedBallot(removed);
    }

    function _forceUncastAllVotes() internal {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            address ballot = arrValidBallots[i];
            delete hasUserVoted[ballot][msg.sender];

            IBallot(ballot).forceUnvote(msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    function setHasVoted(address user) external onlyBallot {
        hasUserVoted[msg.sender][user] = true;
    }

    function unsetHasVoted(address user) external onlyBallot {
        delete hasUserVoted[msg.sender][user];
    }

    /*///////////////////////////////////////////////////////////////
                               STAKING
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount) external {
        //slither-disable-next-line incorrect-equality
        if (genDetails.maxRatio == 0) revert Unauthorized();

        // Reset veFight calculations
        veFightBalance[msg.sender] = balanceOf(msg.sender);
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            fightBalanceOf[msg.sender] += amount;
        }

        // slither-disable-next-line unchecked-transfer
        IERC20(FIGHT).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        if (fightBalanceOf[msg.sender] < amount) revert InvalidAmount();

        // Reset veFight calculations
        delete veFightBalance[msg.sender];
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            fightBalanceOf[msg.sender] -= amount;
        }

        _forceUncastAllVotes();

        // slither-disable-next-line unchecked-transfer
        IERC20(FIGHT).transfer(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                               veFight
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address account) public view returns (uint256) {
        GenerationDetails memory gen = genDetails;

        uint256 fightBalance = fightBalanceOf[account];

        uint256 veBalance = veFightBalance[account] +
            ((fightBalance * gen.generationRateNumerator) *
                (block.timestamp - userSnapshot[account])) /
            gen.generationRateDenominator;

        uint256 maxVe = gen.maxRatio * fightBalance;
        if (veBalance > maxVe) {
            return maxVe;
        } else {
            return veBalance;
        }
    }

    function hasUserVotedAny(address account) external view returns (bool) {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            if (hasUserVoted[arrValidBallots[i]][account]) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// File: contracts/StreetBrawlerz/Fight.sol


pragma solidity 0.8.12;


contract Fight is ERC20 {
    address public owner;

    // whitelist for minting mechanisms
    mapping(address => bool) public zones;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);

    constructor() ERC20("FIGHT", "FIGHT") {
        owner = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                            Zones - can mint
    //////////////////////////////////////////////////////////////*/

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            zones[_zones[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(address zone) external onlyOwner {
        delete zones[zone];
    }

    /*///////////////////////////////////////////////////////////////
                                MINT / BURN
    //////////////////////////////////////////////////////////////*/

    function mint(address receiver, uint256 amount) external onlyZone {
        _mint(receiver, amount);
    }

    function burn(address from, uint256 amount) external onlyZone {
        _burn(from, amount);
    }
}

// File: contracts/StreetBrawlerz/Brawler.sol


pragma solidity 0.8.12;






//slither-disable-next-line locked-ether
contract StreetBrawlerzNFT is ERC721 {
    address public owner;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public immutable MAX_PER_ADDRESS;
    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MINT_COST;
    uint256 public immutable WL_MINT_COST;
    uint256 public immutable LEGENDARY_ID_START;

    /*///////////////////////////////////////////////////////////////
                              SALE DETAILS
    //////////////////////////////////////////////////////////////*/

    uint256 public reserved;
    uint256 public preSaleOpenTime;
    bytes32 public freeMerkleRoot;
    bytes32 public wlMerkleRoot;
    mapping(address => uint256) public freeRedeemed;
    mapping(address => uint256) public wlRedeemed;

    /*///////////////////////////////////////////////////////////////
                                BRAWLERZ
    //////////////////////////////////////////////////////////////*/

    struct Brawler {
        uint200 level; // capped by zone
        uint16 prestige;
        uint8 strength;
        uint8 agility;
        uint8 stamina;
        uint8 intelligence;
        uint8 productivity;
    }

    mapping(uint256 => Brawler) public brawlers;
    uint256 public brawlersLength;
    uint256 public brawlerMaxAttributeValue;

    mapping(uint256 => uint256) public indexer;

    string public baseURI;
    string public imageURL;

    /*///////////////////////////////////////////////////////////////
                             
    //////////////////////////////////////////////////////////////*/

    // whitelist for leveling up
    mapping(address => bool) public zones;

    // unlabeled data [key -> tokenid -> data] for potential future zones
    mapping(string => mapping(uint256 => bytes32)) public unlabeledData;

    // unlabeled data [key -> data] for potential future zones
    mapping(string => bytes32) public unlabeledGlobalData;

    /*///////////////////////////////////////////////////////////////
                            BRAWLERZ NAMES
    //////////////////////////////////////////////////////////////*/

    uint256 public nameFee;
    mapping(bytes32 => bool) public takenNames;
    mapping(uint256 => string) public brawlerzNames;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);
    event LevelUp(uint256 tokenId);
    event NameChange(uint256 tokenId);
    event UpdatedNameFee(uint256 namefee);
    event Rebirth(uint256 tokenId);
    event UnlabeledData(string key, uint256 tokenId);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MintLimit();
    error InsufficientAmount();
    error Unauthorized();
    error InvalidTokenID();
    error MaxLength25();
    error OnlyEOAAllowed();
    error NameTaken();
    error OnlyLvL100();
    error TooSoon();
    error ReservedAmountInvalid();
    error OnlyAlphanumeric();

    constructor() ERC721("Street Brawlerz", "BRAWL") {
        owner = msg.sender;

        MINT_COST = 1.2 ether;
        WL_MINT_COST = 1 ether;
        MAX_SUPPLY = 3333;
        MAX_PER_ADDRESS = 10;
        LEGENDARY_ID_START = 3324;
        
        nameFee = 0.1 ether;
        brawlerMaxAttributeValue = 10;

        unchecked {
            preSaleOpenTime = type(uint256).max - 30 minutes;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    modifier onlyOwnerOrZone() {
        if (msg.sender != owner && !zones[msg.sender]) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function setBrawlerMaxAttributeValue(uint256 _BrawlerMaxAttributeValue) external onlyOwner {
        brawlerMaxAttributeValue = _BrawlerMaxAttributeValue;
    }

    function setNameChangeFee(uint256 _nameFee) external onlyOwner {
        nameFee = _nameFee;
        emit UpdatedNameFee(_nameFee);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setImageURL(string calldata _imageURL) external onlyOwner {
        imageURL = _imageURL;
    }

    function setSaleDetails( uint256 _preSaleOpenTime, bytes32 _wlMerkleRoot, bytes32 _freeMerkleRoot, uint256 _reserved ) external onlyOwner {
        preSaleOpenTime = _preSaleOpenTime;

        freeMerkleRoot = _freeMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;

        reserved = _reserved;
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                    BRAWLERZ VALID ZONES/ADVENTURES
    //////////////////////////////////////////////////////////////*/

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            zones[_zones[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(address _zone) external onlyOwner {
        delete zones[_zone];
    }

    /*///////////////////////////////////////////////////////////////
                            Unlabeled Data
    //////////////////////////////////////////////////////////////*/

    function setGlobalData(string calldata _key, bytes32 _data) external onlyOwnerOrZone {
        unlabeledGlobalData[_key] = _data;
    }

    function unsetGlobalData(string calldata _key) external onlyOwnerOrZone {
        delete unlabeledGlobalData[_key];
    }

    function getGlobalData(string calldata _key) external view returns (bytes32) {
        return unlabeledGlobalData[_key];
    }

    function setData( string calldata _key, uint256 _tokenId, bytes32 _data ) external onlyOwnerOrZone {
        unlabeledData[_key][_tokenId] = _data;

        emit UnlabeledData(_key, _tokenId);
    }

    function unsetData(string calldata _key, uint256 _tokenId) external onlyOwnerOrZone {
        delete unlabeledData[_key][_tokenId];
    }

    function getData(string calldata _key, uint256 _tokenId) external view returns (bytes32) {
        return unlabeledData[_key][_tokenId];
    }

    function getBrawlerWithData(string[] calldata _keys, uint256 _tokenId) external view returns (Brawler memory brawler, bytes32[] memory arrData) {
        brawler = brawlers[_tokenId];

        uint256 length = _keys.length;
        arrData = new bytes32[](length);

        for (uint256 i; i < length; ) {
            arrData[i] = unlabeledData[_keys[i]][_tokenId];
            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        BRAWLERZ LEVEL SYSTEM
    //////////////////////////////////////////////////////////////*/

    function rebirth(uint256 _tokenId) external {
        Brawler memory brawler = brawlers[_tokenId];

        if (ownerOf(_tokenId) != msg.sender) revert Unauthorized();
        if (brawler.level < 100) revert OnlyLvL100();

        uint256 _BrawlerMaxAttributeValue = brawlerMaxAttributeValue;

        unchecked {
            if (brawler.strength < _BrawlerMaxAttributeValue) {
                brawlers[_tokenId].strength = uint8(brawler.strength + 1);
            }

            if (brawler.intelligence < _BrawlerMaxAttributeValue) {
                brawlers[_tokenId].intelligence = uint8(brawler.intelligence + 1);
            }

            if (brawler.agility < _BrawlerMaxAttributeValue) {
                brawlers[_tokenId].agility = uint8(brawler.agility + 1);
            }

            if (brawler.stamina < _BrawlerMaxAttributeValue) {
                brawlers[_tokenId].stamina = uint8(brawler.stamina + 1);
            }

            if (brawler.productivity < _BrawlerMaxAttributeValue) {
                brawlers[_tokenId].productivity = uint8(brawler.productivity + 1);
            }

            ++brawlers[_tokenId].prestige;
        }

        brawlers[_tokenId].level = 1;

        delete unlabeledData["LEVEL_GAUGE_KEY"][_tokenId];

        emit Rebirth(_tokenId);
    }

    function levelUp(uint256 tokenId) external onlyZone {
        // max level is checked on zone
        unchecked {
            ++(brawlers[tokenId].level);
        }
        emit LevelUp(tokenId);
    }

    function changeBrawlerName(uint256 tokenId, string calldata _newName) external onlyZone returns (uint256) {
        bytes memory newName = bytes(_newName);
        uint256 newLength = newName.length;

        if (newLength > 25) revert MaxLength25();

        // Checks it's only alphanumeric characters
        for (uint256 i; i < newLength; ) {
            bytes1 char = newName[i];

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2E) //.
            ) {
                revert OnlyAlphanumeric();
            }
            unchecked {
                ++i;
            }
        }

        // Checks new name uniqueness
        bytes32 nameHash = keccak256(newName);
        if (takenNames[nameHash]) revert NameTaken();

        // Free previous name
        takenNames[keccak256(bytes(brawlerzNames[tokenId]))] = false;

        // Reserve name
        takenNames[nameHash] = true;
        brawlerzNames[tokenId] = _newName;

        emit NameChange(tokenId);

        return nameFee;
    }

    /*///////////////////////////////////////////////////////////////
                          BRAWLERZ GENERATION
    //////////////////////////////////////////////////////////////*/

    function enoughRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number)
                    )
                )
            );
    }

    //slither-disable-next-line weak-prng
    function generate( uint256 seed, uint256 minAttributeValue, uint256 randCap) internal pure returns (Brawler memory) {
        unchecked {
            return
                Brawler({
                    strength: uint8(
                        ((seed >> (8 * 1)) % randCap) + minAttributeValue
                    ),
                    agility: uint8(
                        ((seed >> (8 * 2)) % randCap) + minAttributeValue
                    ),
                    stamina: uint8(
                        ((seed >> (8 * 3)) % randCap) + minAttributeValue
                    ),
                    intelligence: uint8(
                        ((seed >> (8 * 4)) % randCap) + minAttributeValue
                    ),
                    productivity: uint8(
                        ((seed >> (8 * 5)) % randCap) + minAttributeValue
                    ),
                    level: 1,
                    prestige: 0
                });
        }
    }

    function _mintBrawlers(uint256 numberOfMints, uint256 preTotalBrawlers) internal {
        uint256 seed = enoughRandom();

        uint256 _indexerLength;
        unchecked {
            _indexerLength = MAX_SUPPLY - preTotalBrawlers;
        }

        for (uint256 i; i < numberOfMints; ) {
            seed >>= i;

            // Find the next available tokenID
            //slither-disable-next-line weak-prng
            uint256 index = seed % _indexerLength;
            uint256 tokenId = indexer[index];

            if (tokenId == 0) {
                tokenId = index;
            }

            // Swap the picked tokenId for the last element
            unchecked {
                --_indexerLength;
            }

            uint256 last = indexer[_indexerLength];
            if (last == 0) {
                // this _indexerLength value had not been picked before
                indexer[index] = _indexerLength;
            } else {
                // this _indexerLength value had been picked and swapped before
                indexer[index] = last;
            }

            // Mint Brawler and generate its attributes
            _mint(msg.sender, tokenId);

            if (tokenId >= LEGENDARY_ID_START) {
                brawlers[tokenId] = generate(seed, 5, 6);
            } else {
                brawlers[tokenId] = generate(seed, 1, 10);
            }

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            BRAWLERZ MINTING
    //////////////////////////////////////////////////////////////*/

    function _handleMint(uint256 numberOfMints) internal {
        // solhint-disable-next-line
        if (msg.sender != tx.origin) revert OnlyEOAAllowed();

        unchecked {
            uint256 totalBrawlers = brawlersLength + numberOfMints;

            if (
                numberOfMints > MAX_PER_ADDRESS ||
                totalBrawlers > (MAX_SUPPLY - reserved)
            ) revert MintLimit();

            _mintBrawlers(numberOfMints, totalBrawlers - numberOfMints);
            brawlersLength = totalBrawlers;
        }
    }

    function freeMint( uint256 numberOfMints, uint256 index, uint256 totalGiven, bytes32[] memory proof) external {
        unchecked {
            if (block.timestamp < preSaleOpenTime + 30 minutes)
                revert TooSoon();
        }

        if (freeRedeemed[msg.sender] + numberOfMints > totalGiven)
            revert Unauthorized();
        if (reserved < numberOfMints) revert ReservedAmountInvalid();

        if (
            !MerkleProof.verify(
                proof,
                freeMerkleRoot,
                keccak256(abi.encodePacked(index, msg.sender, totalGiven))
            )
        ) revert Unauthorized();

        unchecked {
            freeRedeemed[msg.sender] += numberOfMints;
            reserved -= numberOfMints;
        }

        _handleMint(numberOfMints);
    }

    function whitelistMint(uint256 numberOfMints, uint256 index, uint256 totalGiven, bytes32[] memory proof) external payable {
        unchecked {
            if (block.timestamp < preSaleOpenTime) 
                revert TooSoon();
        }
        if (wlRedeemed[msg.sender] + numberOfMints > totalGiven) 
            revert Unauthorized();

        if (WL_MINT_COST * numberOfMints > msg.value) revert InsufficientAmount();

        if (!MerkleProof.verify(
                proof,
                wlMerkleRoot,
                keccak256(abi.encodePacked(index, msg.sender, totalGiven))
            )
        ) revert Unauthorized();

        unchecked {
            wlRedeemed[msg.sender] += numberOfMints;
        }

        _handleMint(numberOfMints);
    }

    function normalMint(uint256 numberOfMints) external payable {
        unchecked {
            if (block.timestamp < preSaleOpenTime + 30 minutes)
                revert TooSoon();
        }
        if (MINT_COST * numberOfMints > msg.value) revert InsufficientAmount();

        _handleMint(numberOfMints);
    }

    /*///////////////////////////////////////////////////////////////
                          BRAWLERZ VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getBrawler(uint256 tokenId) external view returns (Brawler memory) {
        return brawlers[tokenId];
    }

    function getBrawlerName(uint256 tokenId) public view returns (string memory name) {
        name = brawlerzNames[tokenId];

        if (bytes(name).length == 0) {
            name = string(bytes.concat("Street Brawler #", bytes(_toString(tokenId))));
        }
    }

    function _getTraits(Brawler memory brawler) internal pure returns (string memory) {
        return
            string(
                bytes.concat(
                    '{"trait_type": "prestige", "value": ',
                    bytes(_toString(brawler.prestige)),
                    "},",
                    '{"trait_type": "strength", "value": ',
                    bytes(_toString(brawler.strength)),
                    "},",
                    '{"trait_type": "agility", "value": ',
                    bytes(_toString(brawler.agility)),
                    "},",
                    '{"trait_type": "stamina", "value": ',
                    bytes(_toString(brawler.stamina)),
                    "},",
                    '{"trait_type": "intelligence", "value": ',
                    bytes(_toString(brawler.intelligence)),
                    "},",
                    '{"trait_type": "productivity", "value": ',
                    bytes(_toString(brawler.productivity)),
                    "}"
                )
            );
    }

    function _jsonString(uint256 tokenId) external view returns (string memory) {
        Brawler memory brawler = brawlers[tokenId];

        //slither-disable-next-line incorrect-equality
        if (brawler.level == 0) revert InvalidTokenID();

        return
            string(
                bytes.concat(
                    '{"name":"',
                    bytes(getBrawlerName(tokenId)),
                    '", "description":"Brawler", "attributes":[',
                    '{"trait_type": "level", "value": ',
                    bytes(_toString(brawler.level)),
                    "},",
                    bytes(_getTraits(brawler)),
                    "],",
                    '"image":"',
                    bytes(imageURL),
                    bytes(_toString(tokenId)),
                    '.png"}'
                )
            );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        //slither-disable-next-line incorrect-equality
        if (brawlers[tokenId].level == 0) revert InvalidTokenID();

        return string(bytes.concat(bytes(baseURI), bytes(_toString(tokenId))));
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        //slither-disable-next-line incorrect-equality
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
            //slither-disable-next-line weak-prng
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
// File: contracts/StreetBrawlerz/Zone.sol


pragma solidity 0.8.12;





library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

abstract contract Zone {
    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    address public immutable FIGHT;
    address public immutable VE_FIGHT;
    address public immutable BRAWLER;

    /*///////////////////////////////////////////////////////////////
                                BRAWLERZ
    //////////////////////////////////////////////////////////////*/
    string public LEVEL_GAUGE_KEY;

    mapping(uint256 => address) public brawlerOwners;
    mapping(uint256 => uint256) public brawlerBaseShare;
    mapping(address => uint256) public rewards;

    address public owner;
    address public ballot;
    bool public emergency;

    /*///////////////////////////////////////////////////////////////
                        Accounting/Rewards NFT
    //////////////////////////////////////////////////////////////*/
    uint256 public emissionRate;

    uint256 public totalBaseShare;
    uint256 public lastUpdatedTime;
    uint256 public rewardPerShareStored;

    mapping(address => uint256) public baseSharesBalance;
    mapping(address => uint256) public userRewardPerSharePaid;
    mapping(address => uint256) public userMaxFightGeneration;

    mapping(address => uint256) public generatedPerShareStored;
    mapping(uint256 => uint256) public tokenCapFilledPerShare;

    uint256 public fightLevelCapRatio;

    /*///////////////////////////////////////////////////////////////
                        Accounting/Rewards veFIGHT
    //////////////////////////////////////////////////////////////*/
    uint256 public bonusEmissionRate;

    uint256 public totalVeShare;
    uint256 public lastBonusUpdatedTime;
    uint256 public bonusRewardPerShareStored;

    mapping(address => uint256) public veSharesBalance;
    mapping(address => uint256) public userBonusRewardPerSharePaid;
    mapping(address => uint256) public veFightBalance;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error UnfitBrawler();
    error WrongTokenID();
    error NoBrawlerStaked();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatedOwner(address indexed owner);
    event UpdatedBallot(address indexed ballot);
    event UpdatedEmission(uint256 emissionRate);

    /*///////////////////////////////////////////////////////////////
                           CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    constructor(
        address fight,
        address vefight,
        address brawler
    ) {
        owner = msg.sender;

        FIGHT = fight;
        VE_FIGHT = vefight;
        BRAWLER = brawler;

        fightLevelCapRatio = 3;
        LEVEL_GAUGE_KEY = "LEVEL_GAUGE_KEY";
        lastUpdatedTime = block.timestamp;
        lastBonusUpdatedTime = block.timestamp;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyBallotOrOwner() {
        if (msg.sender != owner && msg.sender != ballot) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function enableEmergency() external onlyOwner {
        // no going back
        emergency = true;
    }

    function setBallot(address _ballot) external onlyOwner {
        ballot = _ballot;
        emit UpdatedBallot(_ballot);
    }

    function setEmissionRate(uint256 _emissionRate) external onlyOwner {
        _updateBaseRewardPerShareStored();

        emissionRate = _emissionRate;
        emit UpdatedEmission(_emissionRate);
    }

    function setBonusEmissionRate(uint256 _bonusEmissionRate)
        external
        onlyBallotOrOwner
    {
        _updateBonusRewardPerShareStored();

        bonusEmissionRate = _bonusEmissionRate;
    }

    function setFightLevelCapRatio(uint256 _fightLevelCapRatio) external onlyOwner {
        fightLevelCapRatio = _fightLevelCapRatio;
    }

    /*///////////////////////////////////////////////////////////////
                        BRAWLER GENERATION CAP
    //////////////////////////////////////////////////////////////*/

    function getUserBonusGeneratedFight(
        address account,
        uint256 _totalUserBonusShares
    ) public view returns (uint256, uint256) {
        // userMaxFightGeneration gets updated at _updateAccountBaseReward which happens before this is called
        uint256 cappedFight = userMaxFightGeneration[account] / 1e12;
        uint256 generatedFight = ((_totalUserBonusShares *
            (bonusRewardPerShare() - userBonusRewardPerSharePaid[account])) /
            1e18);

        return (
            generatedFight > cappedFight ? cappedFight : generatedFight,
            generatedFight
        );
    }

    function getUserGeneratedFight(address account, uint256 _totalUserBaseShares)
        public
        view
        returns (uint256, uint256)
    {
        uint256 cappedFight = userMaxFightGeneration[account] / 1e12;
        uint256 generatedFight = ((_totalUserBaseShares *
            (baseRewardPerShare() - userRewardPerSharePaid[account])) / 1e18);

        return (
            generatedFight > cappedFight ? cappedFight : generatedFight,
            generatedFight
        );
    }

    function _updateBrawlerGenerationData(
        address _account,
        uint256 _totalAccountKindShares,
        bool isBonus
    ) internal returns (uint256) {
        uint256 cappedFight;
        uint256 generatedFight;

        if (isBonus) {
            (cappedFight, generatedFight) = getUserBonusGeneratedFight(
                _account,
                _totalAccountKindShares
            );

            // Makes calculations easier, since we don't need to add another
            //    state keeping track of generatedPerVeshare
            generatedPerShareStored[_account] += FixedPointMathLib.mulDivUp(
                generatedFight,
                1e12,
                baseSharesBalance[_account]
            );
        } else {
            (cappedFight, generatedFight) = getUserGeneratedFight(
                _account,
                _totalAccountKindShares
            );
            generatedPerShareStored[_account] += FixedPointMathLib.mulDivUp(
                generatedFight,
                1e12,
                _totalAccountKindShares
            );
        }
        return cappedFight;
    }

    /*///////////////////////////////////////////////////////////////
                           REWARDS ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function _updateAccountRewards(address _account) internal {
        _updateAccountBaseReward(_account, baseSharesBalance[_account]);
        _updateAccountBonusReward(_account, veSharesBalance[_account]);
    }

    /*///////////////////////////////////////////////////////////////
                           BASE REWARDS
    //////////////////////////////////////////////////////////////*/

    function baseRewardPerShare() public view returns (uint256) {
        uint256 _totalBaseShare = totalBaseShare;
        //slither-disable-next-line incorrect-equality
        if (_totalBaseShare == 0) {
            return rewardPerShareStored;
        }
        return
            rewardPerShareStored +
            (((block.timestamp - lastUpdatedTime) * emissionRate * 1e18) /
                _totalBaseShare);
    }

    function _updateBaseRewardPerShareStored() internal {
        rewardPerShareStored = baseRewardPerShare();
        lastUpdatedTime = block.timestamp;
    }

    function _updateAccountBaseReward(
        address _account,
        uint256 _totalAccountShares
    ) internal {
        _updateBaseRewardPerShareStored();

        if (_totalAccountShares > 0) {
            uint256 cappedFight = _updateBrawlerGenerationData(
                _account,
                _totalAccountShares,
                false
            );

            unchecked {
                rewards[_account] += cappedFight;
            }
            userMaxFightGeneration[_account] -= cappedFight * 1e12;
        }

        userRewardPerSharePaid[_account] = rewardPerShareStored;
    }

    /*///////////////////////////////////////////////////////////////
                           BONUS REWARDS
    //////////////////////////////////////////////////////////////*/

    function bonusRewardPerShare() public view returns (uint256) {
        uint256 _totalVeShare = totalVeShare;
        //slither-disable-next-line incorrect-equality
        if (_totalVeShare == 0) {
            return bonusRewardPerShareStored;
        }
        return
            bonusRewardPerShareStored +
            (((block.timestamp - lastBonusUpdatedTime) *
                bonusEmissionRate *
                1e18) / _totalVeShare);
    }

    function _updateBonusRewardPerShareStored() internal {
        bonusRewardPerShareStored = bonusRewardPerShare();
        lastBonusUpdatedTime = block.timestamp;
    }

    function _updateAccountBonusReward(
        address _account,
        uint256 _totalAccountShares
    ) internal {
        _updateBonusRewardPerShareStored();

        if (_totalAccountShares > 0) {
            uint256 cappedFight = _updateBrawlerGenerationData(
                _account,
                _totalAccountShares,
                true
            );

            unchecked {
                rewards[_account] += cappedFight;
            }
            userMaxFightGeneration[_account] -= cappedFight * 1e12;
        }
        userBonusRewardPerSharePaid[_account] = bonusRewardPerShareStored;
    }

    /*///////////////////////////////////////////////////////////////
                    NAMES & LEVELING
    //////////////////////////////////////////////////////////////*/

    function payAction(uint256 fightRequired, bool useOwnRewards) internal {
        if (useOwnRewards) {
            uint256 _rewards = rewards[msg.sender];

            // Pays from the pending rewards
            if (_rewards >= fightRequired) {
                unchecked {
                    rewards[msg.sender] -= fightRequired;
                    fightRequired = 0;
                }
            } else if (_rewards > 0) {
                delete rewards[msg.sender];
                unchecked {
                    fightRequired -= _rewards;
                }
            }
        }

        // Sender pays for action. Will revert, if not enough balance
        if (fightRequired > 0) {
            Fight(FIGHT).burn(msg.sender, fightRequired);
        }
    }

    function changeBrawlerName(
        uint256 tokenId,
        string calldata name,
        bool useOwnRewards
    ) external {
        if (useOwnRewards) {
            _updateAccountRewards(msg.sender);
        }

        // Check brawler ownership
        address zoneBrawlerOwner = brawlerOwners[tokenId];
        if (zoneBrawlerOwner != msg.sender) {
            // Saves gas in certain paths
            if (StreetBrawlerzNFT(BRAWLER).ownerOf(tokenId) != msg.sender) {
                revert WrongTokenID();
            }
        }

        payAction(
            StreetBrawlerzNFT(BRAWLER).changeBrawlerName(tokenId, name), // returns price
            useOwnRewards
        );
    }

    function _getLevelUpCost(uint256 level) internal pure returns (uint256) {
        unchecked {
            ++level;

            if (level == 100) {
                return 598 ether;
            }
            // x**(1.43522) / 7.5 for x >= 21 where x is next level
            // packing costs in 7 bits
            else if (level > 1 && level < 21) {
                return (level * 1e18) >> 1;
            } else if (level >= 21 && level < 51) {
                return
                    ((0x1223448501f3c74e1b3464c172c54a9426488901e3c70d183058a >>
                        (7 * (level - 21))) & 127) * 1e18;
            } else if (level >= 51 && level < 81) {
                return
                    ((0x23c68b0e14180f9ebc76e9c376cd5a3262c17ae5ab15a9509d325 >>
                        (7 * (level - 51))) & 127) * 1e18;
            } else if (level >= 81 && level < 101) {
                return
                    ((0xc58705ebb6ed59af5aad3a5467ce9b2e549 >>
                        (7 * (level - 81))) & 127) * 1e18;
            } else {
                return type(uint256).max;
            }
        }
    }

    //slither-disable-next-line reentrancy-no-eth
    function levelUp(uint256 tokenId, bool useOwnRewards) external {
        StreetBrawlerzNFT IBRAWLER = StreetBrawlerzNFT(BRAWLER);
        if (useOwnRewards) {
            _updateAccountRewards(msg.sender);
        }

        // Check brawler ownership
        address zoneBrawlerOwner = brawlerOwners[tokenId];
        if (zoneBrawlerOwner != msg.sender) {
            // Saves gas in certain paths
            if (IBRAWLER.ownerOf(tokenId) != msg.sender) {
                revert WrongTokenID();
            }
        }

        StreetBrawlerzNFT.Brawler memory brawler = IBRAWLER.getBrawler(tokenId);

        // Update owners shares if brawler is staked
        if (zoneBrawlerOwner == msg.sender) {
            // Updated above if true
            if (!useOwnRewards) {
                _updateAccountRewards(msg.sender);
            }

            // Fill brawler gauge so we can find whats the remaining
            (, uint256 remainingGauge, ) = _updateBrawlerGaugeFill(tokenId);

            // Calculate the baseShare that we need to subtract from the user and total
            uint256 prevBrawlerShare = _calculateBaseShare(brawler);
            unchecked {
                ++brawler.level;
            }
            // Calculate the baseShare that we need to add to the user and total
            uint256 newBrawlerShare = _calculateBaseShare(brawler);

            // Calculate new baseShares
            uint256 diff = newBrawlerShare - prevBrawlerShare;
            unchecked {
                uint256 newBaseShare = baseSharesBalance[msg.sender] + diff;
                baseSharesBalance[msg.sender] = newBaseShare;

                totalBaseShare += diff;

                // Update new value of veShares
                _updateVeShares(newBaseShare, 0, false);
            }

            uint256 boostFill = 0;
            uint256 userMax = userMaxFightGeneration[msg.sender];
            if (userMax < remainingGauge) {
                boostFill = remainingGauge - userMax;
            }

            // Update the new cap
            userMaxFightGeneration[msg.sender] += (_getGaugeLimit(brawler.level) *
                1e12 -
                (remainingGauge - boostFill));

            // Make sure getLevelUpCost is passed its current level
            unchecked {
                --brawler.level;
            }
        }

        payAction(getLevelUpCost(brawler.level), useOwnRewards);

        IBRAWLER.levelUp(tokenId);

        // Reset Brawler internal gauge
        IBRAWLER.setData(LEVEL_GAUGE_KEY, tokenId, 0);
    }

    /*///////////////////////////////////////////////////////////////
                    STAKE / UNSTAKE NFT && CLAIM FIGHT
    //////////////////////////////////////////////////////////////*/

    function enter(uint256[] calldata tokenIds) external {
        if (emergency) revert Unauthorized();

        _updateAccountRewards(msg.sender);

        uint256 prevBaseShares = baseSharesBalance[msg.sender];
        uint256 _baseShares = prevBaseShares;
        uint256 numTokens = tokenIds.length;

        uint256 fightCapIncrease;

        uint256 _generatedPerShareStored = generatedPerShareStored[msg.sender];
        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Resets this brawler generation tracking
            tokenCapFilledPerShare[tokenId] = _generatedPerShareStored;

            (
                StreetBrawlerzNFT.Brawler memory brawler,
                uint256 brawlerGauge,
                uint256 gaugeLimit
            ) = _getBrawlerAndGauge(tokenId);

            if (!canEnter(brawler)) revert UnfitBrawler();

            unchecked {
                // Increment user shares
                _baseShares += _calculateBaseShare(brawler);
            }

            // Update the maximum FIGHT this user can generate
            fightCapIncrease += (gaugeLimit - brawlerGauge);

            // Brawler Accounting
            brawlerOwners[tokenId] = msg.sender;
            StreetBrawlerzNFT(BRAWLER).transferFrom(msg.sender, address(this), tokenId);

            unchecked {
                ++i;
            }
        }

        baseSharesBalance[msg.sender] = _baseShares;
        unchecked {
            userMaxFightGeneration[msg.sender] += fightCapIncrease;

            totalBaseShare = totalBaseShare + _baseShares - prevBaseShares;
        }

        _updateVeShares(_baseShares, 0, false);
    }

    //slither-disable-next-line reentrancy-no-eth
    function exit(uint256[] calldata tokenIds) external {
        if (emergency) revert Unauthorized();

        _updateAccountRewards(msg.sender);

        uint256 prevBaseShares = baseSharesBalance[msg.sender];
        uint256 _baseShares = prevBaseShares;
        uint256 numTokens = tokenIds.length;

        uint256 fightCapDecrease;
        uint256 userMax = userMaxFightGeneration[msg.sender];

        uint256[] memory rTokensRemaining = new uint256[](tokenIds.length);
        uint256[] memory rTokensLimit = new uint256[](tokenIds.length);

        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Can the user unstake this brawler
            if (brawlerOwners[tokenId] != msg.sender) revert WrongTokenID();

            (
                uint256 _brawlerShare,
                uint256 _remainingGauge,
                uint256 _gaugeLimit
            ) = _updateBrawlerGaugeFill(tokenId);

            // Decrement user shares
            _baseShares -= _brawlerShare;

            // Update the maximum FIGHT this user can generate
            fightCapDecrease += _remainingGauge;

            // To fill gauge later
            rTokensRemaining[i] = _remainingGauge;
            rTokensLimit[i] = _gaugeLimit;

            // Brawler Accounting
            //slither-disable-next-line costly-loop
            delete brawlerOwners[tokenId];
            StreetBrawlerzNFT(BRAWLER).transferFrom(address(this), msg.sender, tokenId);

            unchecked {
                ++i;
            }
        }

        baseSharesBalance[msg.sender] = _baseShares;

        if (userMax < fightCapDecrease) {
            // Being boosted, we need to go back and refill uncapped tokens
            refill(
                tokenIds,
                rTokensRemaining,
                rTokensLimit,
                fightCapDecrease - userMax
            );
            delete userMaxFightGeneration[msg.sender];
        } else if (_baseShares == 0) {
            delete userMaxFightGeneration[msg.sender];
        } else {
            userMaxFightGeneration[msg.sender] -= fightCapDecrease;
        }

        unchecked {
            totalBaseShare = totalBaseShare + _baseShares - prevBaseShares;
        }
        _updateVeShares(_baseShares, 0, false);
    }

    function refill(
        uint256[] calldata tokenIds,
        uint256[] memory remaining,
        uint256[] memory limit,
        uint256 leftover
    ) internal {
        uint256 length = tokenIds.length;

        for (uint256 i; i < length; ) {
            if (remaining[i] != 0) {
                if (leftover > remaining[i]) {
                    StreetBrawlerzNFT(BRAWLER).setData(
                        LEVEL_GAUGE_KEY,
                        tokenIds[i],
                        bytes32(limit[i] / 1e12)
                    );
                    leftover -= remaining[i];
                } else {
                    StreetBrawlerzNFT(BRAWLER).setData(
                        LEVEL_GAUGE_KEY,
                        tokenIds[i],
                        bytes32((limit[i] - remaining[i] + leftover) / 1e12)
                    );
                    leftover = 0;
                    break;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function emergencyExit(uint256[] calldata tokenIds, address user) external {
        if (!emergency) revert Unauthorized();

        uint256 numTokens = tokenIds.length;
        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Can the user unstake this brawler
            if (brawlerOwners[tokenId] != user) revert WrongTokenID();

            //slither-disable-next-line costly-loop
            delete brawlerOwners[tokenId];
            StreetBrawlerzNFT(BRAWLER).transferFrom(address(this), user, tokenId);

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            CLAIMING
    //////////////////////////////////////////////////////////////*/

    function claimable(address _account) external view returns (uint256) {
        uint256 cappedFight = userMaxFightGeneration[_account] / 1e12;

        (uint256 gen, ) = getUserGeneratedFight(
            _account,
            baseSharesBalance[_account]
        );
        (uint256 bonusGen, ) = getUserBonusGeneratedFight(
            _account,
            veSharesBalance[_account]
        );

        gen += bonusGen;
        cappedFight = gen > cappedFight ? cappedFight : gen;

        unchecked {
            return rewards[_account] + cappedFight;
        }
    }

    function claim() external {
        _updateAccountRewards(msg.sender);

        uint256 _accountRewards = rewards[msg.sender];
        delete rewards[msg.sender];

        Fight(FIGHT).mint(msg.sender, _accountRewards);
    }

    /*///////////////////////////////////////////////////////////////
                            VOTE veFIGHT 
    //////////////////////////////////////////////////////////////*/

    function _calcVeShare(uint256 accountTotalBaseShares, uint256 vefight)
        internal
        pure
        returns (uint256)
    {
        return FixedPointMathLib.sqrt(accountTotalBaseShares * vefight);
    }

    //slither-disable-next-line reentrancy-no-eth
    function _updateVeShares(
        uint256 baseShares,
        uint256 veFightAmount,
        bool incrementVeFightAmount
    ) internal {
        uint256 beforeVeShare = veSharesBalance[msg.sender];
        if (veFightAmount > 0) {
            // Ballot checks if the user has the veFight amount necessary, otherwise reverts
            if (incrementVeFightAmount) {
                //slither-disable-next-line reentrancy-benign
                IBallot(ballot).vote(msg.sender, veFightAmount);
                unchecked {
                    veFightBalance[msg.sender] += veFightAmount;
                }
            } else {
                //slither-disable-next-line reentrancy-benign
                IBallot(ballot).unvote(msg.sender, veFightAmount);
                veFightBalance[msg.sender] -= veFightAmount;
            }
        }

        uint256 currentVeShare = _calcVeShare(
            baseShares,
            veFightBalance[msg.sender]
        );
        veSharesBalance[msg.sender] = currentVeShare;

        unchecked {
            totalVeShare = totalVeShare + currentVeShare - beforeVeShare;
        }
    }

    function vote(uint256 veFightAmount, bool recount) external {
        _updateAccountBonusReward(msg.sender, veSharesBalance[msg.sender]);

        _updateVeShares(baseSharesBalance[msg.sender], veFightAmount, true);

        if (recount) IBallot(ballot).count();
    }

    function unvote(uint256 veFightAmount, bool recount) external {
        _updateAccountBonusReward(msg.sender, veSharesBalance[msg.sender]);

        _updateVeShares(baseSharesBalance[msg.sender], veFightAmount, false);

        if (recount) IBallot(ballot).count();
    }

    function forceUnvote(address user) external {
        if (msg.sender != ballot) revert Unauthorized();

        uint256 userVeShares = veSharesBalance[user];
        _updateAccountBonusReward(user, userVeShares);

        totalVeShare -= userVeShares;
        delete veSharesBalance[user];
        delete veFightBalance[user];
    }

    /*///////////////////////////////////////////////////////////////
                    HELPER GAUGE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // _remaining is scaled with 1e12
    function _updateBrawlerGaugeFill(uint256 tokenId)
        internal
        returns (
            uint256 _brawlerShare,
            uint256 _remaining,
            uint256
        )
    {
        uint256 _generatedPerShareStored = generatedPerShareStored[msg.sender];

        // Resets this brawler generation tracking
        uint256 filledCapPerShare = _generatedPerShareStored -
            tokenCapFilledPerShare[tokenId];

        tokenCapFilledPerShare[tokenId] = _generatedPerShareStored;

        (
            StreetBrawlerzNFT.Brawler memory brawler,
            uint256 prevBrawlerGauge,
            uint256 gaugeLimit
        ) = _getBrawlerAndGauge(tokenId);

        _brawlerShare = _calculateBaseShare(brawler);

        uint256 fightGeneratedAndBurned = prevBrawlerGauge +
            filledCapPerShare *
            _brawlerShare;

        uint256 currentGauge = fightGeneratedAndBurned > gaugeLimit
            ? gaugeLimit
            : fightGeneratedAndBurned;

        // Update the BRAWLER gauge
        StreetBrawlerzNFT(BRAWLER).setData(
            LEVEL_GAUGE_KEY,
            tokenId,
            bytes32(currentGauge / 1e12)
        );

        return (_brawlerShare, (gaugeLimit - currentGauge), gaugeLimit);
    }

    function _getGaugeLimit(uint256 level) internal view returns (uint256) {
        if (level == 1) return 1.5 ether;
        if (level == 100) return 294 ether;
        unchecked {
            return fightLevelCapRatio * _getLevelUpCost(level - 1);
        }
    }

    function _getBrawlerAndGauge(uint256 _tokenId)
        internal
        view
        returns (
            StreetBrawlerzNFT.Brawler memory,
            uint256, // brawlerGauge
            uint256 // gaugeLimit
        )
    {
        string[] memory arrData = new string[](1);
        arrData[0] = LEVEL_GAUGE_KEY;
        (StreetBrawlerzNFT.Brawler memory brawler, bytes32[] memory _data) = StreetBrawlerzNFT(
            BRAWLER
        ).getBrawlerWithData(arrData, _tokenId);

        return (
            brawler,
            uint256(_data[0]) * 1e12,
            _getGaugeLimit(brawler.level) * 1e12
        );
    }

    function getBrawlerAndGauge(uint256 tokenId)
        external
        view
        returns (
            StreetBrawlerzNFT.Brawler memory brawler,
            uint256 brawlerGauge,
            uint256 gaugeLimit
        )
    {
        (brawler, brawlerGauge, gaugeLimit) = _getBrawlerAndGauge(tokenId);
        return (brawler, brawlerGauge / 1e12, gaugeLimit / 1e12);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getLevelUpCost(uint256 currentLevel)
        public
        pure
        returns (uint256)
    {
        return _getLevelUpCost(currentLevel);
    }

    /*///////////////////////////////////////////////////////////////
                    ZONE SPECIFIC FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function canEnter(StreetBrawlerzNFT.Brawler memory brawler)
        public
        pure
        virtual
        returns (bool)
    {} // solhint-disable-line

    function _calculateBaseShare(StreetBrawlerzNFT.Brawler memory brawler)
        internal
        pure
        virtual
        returns (uint256)
    {} // solhint-disable-line
}

// File: contracts/StreetBrawlerz/zones/Aikido.sol


pragma solidity 0.8.12;



contract Aikido is Zone {
    constructor(
        address fight,
        address vefight,
        address brawler
    ) Zone(fight, vefight, brawler) {}

    // solhint-disable-next-line
    function canEnter(StreetBrawlerzNFT.Brawler memory brawler)
        public
        pure
        override
        returns (bool)
    {
        return true;
    }

    function _calculateBaseShare(StreetBrawlerzNFT.Brawler memory brawler)
        internal
        pure
        override
        returns (uint256)
    {
        unchecked {
            return uint256(brawler.strength) * uint256(brawler.level);
        }
    }
}