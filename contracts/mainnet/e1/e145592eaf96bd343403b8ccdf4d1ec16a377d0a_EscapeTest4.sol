/**
 *Submitted for verification at snowtrace.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT

//contract created by ZombieBits @ZombieBitsNFT


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


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}


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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)


pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}



// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)



// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

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

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


pragma solidity >=0.7.0 <0.9.0;

contract EscapeTest4 is ERC1155, Ownable {

  //sets max immutable total supply of all collection
  uint public constant MAX_TOKENS = 10000;
  //start collection at 0 minted
  uint public numMinted = 0;
  //sets the current edition max for the mintEdition single toggle function
  uint public MAXeditionToggle = 10;
  //sets the max tokens for current range mint function
  uint public MAXrangeToggle = 10;
  //sets price for single edition mint function
  uint public price = 0.005 ether;
  //sets price for range function
  uint public priceRANGE = 0.005 ether;
  //sets the lowest token allowed in range
  uint public low = 0;
//sets the highest token allowed in range
  uint public high = 2;
  //sets the current token to mint in single mint
  uint public CurrentEdition = 1;
//sets the max per wallet tracked using Edition Mint
  uint public MaxPerWallet_EditionMint = 3;

  uint public WalletTrackLevel = 1;

  //sets the current token IDs (editions) that are available in current minting
  //if not using all slots- set the others to the SAME token & turn off the other supplys to 0 or match it
  uint public E1 = 1;
  uint public E2 = 2;
  uint public E3 = 3;
  uint public E4 = 4;
  uint public E5 = 5;
  uint public E6 = 6;
  uint public E7 = 7;
  uint public E8 = 8;
  uint public E9 = 9;
  uint public E10 = 10;

//sets max supply of each 10 current IDs during the current minting (if not using all 10 spots- set the others to 0)
  uint public maxE1 = 10;
  uint public maxE2 = 20;
  uint public maxE3 = 30;
  uint public maxE4 = 40;
  uint public maxE5 = 50;
  uint public maxE6 = 60;
  uint public maxE7 = 70;
  uint public maxE8 = 80;
  uint public maxE9 = 90;
  uint public maxE10 = 100;

//sets price of each 10 current IDs minting
  uint public priceE1 = .01 ether;
  uint public priceE2 = .01 ether;
  uint public priceE3 = .01 ether;
  uint public priceE4 = .01 ether;
  uint public priceE5 = .01 ether;
  uint public priceE6 = .01 ether;
  uint public priceE7 = .01 ether;
  uint public priceE8 = .01 ether;
  uint public priceE9 = .01 ether;
  uint public priceE10 = .01 ether;


   bytes32 public Merkle1;
    bytes32 public Merkle2;
     bytes32 public Merkle3;
      bytes32 public Merkle4;
       bytes32 public Merkle5;
        bytes32 public Merkle6;
         bytes32 public Merkle7;
          bytes32 public Merkle8;
           bytes32 public Merkle9;
            bytes32 public Merkle10;

  bytes32 public MerkleRange;
  bytes32 public MerkleEdition;

  // Sale state:
  // 0: Closed
  // 1: Open 
  uint256 public mintEditionSaleToggle = 0;
  uint256 public mintRangeSaleToggle = 0;
  uint256 public mintMultiSaleToggle = 0;
  uint256 public GatedmintEditionSaleToggle = 0;
  uint256 public GatedmintRangeSaleToggle = 0;


  string private _contractUri = "ipfs://";

  string public name = "EscapeTest4";
  string public symbol = "ETEST4";

 mapping (address => uint256) public FLEX_EDITION_ALLOWED;

//10 wallet tracking sales - then move to manual toggles (costs gas) to load the specific arrays
    mapping (address => uint) public NumMinted1;
    mapping (address => uint) public NumMinted2;
    mapping (address => uint) public NumMinted3;
    mapping (address => uint) public NumMinted4;
    mapping (address => uint) public NumMinted5;
    mapping (address => uint) public NumMinted6;
    mapping (address => uint) public NumMinted7;
    mapping (address => uint) public NumMinted8;
    mapping (address => uint) public NumMinted9;
    mapping (address => uint) public NumMinted10;
    mapping (address => uint) public NumMinted_FLEX_Edition;


  constructor() public ERC1155("ipfs://QmRMWG2scMV9wtb3ZEsbhvFM58CexfLvEp7CFjCWU2izM9/{id}.json") {}
    


//allows minting of only 1 specific edition at a set max supply- turn all other sales off and only use this for specific exact control
  function mintEDITION(uint EditionNum, uint amount) public payable {
    require(mintEditionSaleToggle == 1, "edition mint is not open");
    _internalMint(EditionNum, amount);
  }

//allows gating of the single edition mint function
  function GATEDmintEDITION(uint EditionNum, uint amount,bytes32[] calldata MerkleProofEdition) public payable {
    require(GatedmintEditionSaleToggle == 1, "edition mint is not open");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(MerkleProofEdition, MerkleEdition, leaf), "Invalid proof.");
    _internalMint(EditionNum, amount);

  }

  //allows minting of RANGE of tokens i.e 1-20 with a set SHARED total supply and SHARED price
  function mintRANGE(uint EditionNum, uint amount) public payable {
    require(mintRangeSaleToggle == 1, "range edition mint is not open");
    _internalMintRange(EditionNum, amount);
  }

   function GATEDmintRANGE(uint EditionNum, uint amount,bytes32[] calldata MerkleProofRange) public payable {
    require(GatedmintRangeSaleToggle == 1, "range edition mint is not open");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(MerkleProofRange, MerkleRange, leaf), "Invalid proof.");
    _internalMintRange(EditionNum, amount);
  }

  //allows minting of 10 different editions as defined by e1, e2, e3, etc with diff prices and supplies
  function mintCLAIMfromAvail(uint EditionNum, uint amount) public payable {
    require(mintMultiSaleToggle == 1, "multi sale from available mint is not open");
    _internalMintAvail(EditionNum, amount);
  }

  function GATEDmintCLAIMfromAvail(uint EditionNum, uint amount) public payable {
    require(mintMultiSaleToggle == 1, "multi sale from available mint is not open");
    _internalMintAvail(EditionNum, amount);
  }

  function _internalMint(uint EditionNum, uint amount) internal {
    incrementNumMinted(amount);
    if (EditionNum >= 0) {
      checkPayment(price * amount);
      _checkEdition(amount, EditionNum);
    } else {
      revert("Invalid pass type");
    }
    _mint(msg.sender, EditionNum, amount, "");
  }

  function _internalMintRange(uint EditionNum, uint amount) internal {
    incrementNumMinted(amount);
    if (EditionNum >= 0) {
      checkPayment(priceRANGE * amount);
      _checkEditionRange(amount, EditionNum);
    } else {
      revert("Invalid pass type");
    }
    _mint(msg.sender, EditionNum, amount, "");
  }

  

  function _internalMintAvail(uint EditionNum, uint amount) internal {
    incrementNumMinted(amount);
    if (EditionNum == E1) {
      checkPayment(priceE1 * amount);
      _checkEdition1(amount, EditionNum);  
    }
    else if (EditionNum == E2) {
        checkPayment(priceE2 * amount);
        _checkEdition2(amount, EditionNum);
    } 
    else if (EditionNum == E3) {
        checkPayment(priceE3 * amount);
        _checkEdition3(amount, EditionNum);
    }
    else if (EditionNum == E4) {
        checkPayment(priceE4 * amount);
        _checkEdition4(amount, EditionNum);
    }
    else if (EditionNum == E5) {
        checkPayment(priceE5 * amount);
        _checkEdition5(amount, EditionNum);
    }
    else if (EditionNum == E6) {
        checkPayment(priceE6 * amount);
        _checkEdition6(amount, EditionNum);
    }
    else if (EditionNum == E7) {
        checkPayment(priceE7 * amount);
        _checkEdition7(amount, EditionNum);
    }
    else if (EditionNum == E8) {
        checkPayment(priceE8 * amount);
        _checkEdition8(amount, EditionNum);
    }
    else if (EditionNum == E9) {
        checkPayment(priceE9 * amount);
        _checkEdition9(amount, EditionNum);
    }
    else if (EditionNum == E10) {
        checkPayment(priceE10 * amount);
        _checkEdition10(amount, EditionNum);
    }
    
    
    else {
      revert("Invalid pass type");
    }
    _mint(msg.sender, EditionNum, amount, "");
  }

    function checkPayment(uint amountRequired) internal {
    require(msg.value >= amountRequired, "Not enough funds sent");
  }

  function incrementNumMinted(uint amount) internal {
    numMinted = numMinted + amount;
    require(numMinted <= MAX_TOKENS, "Minting would exceed max tokens");
  }


function _checkEdition(uint256 amount, uint EditionNum) internal {
    require(EditionNum == CurrentEdition, "wrong edition");
    require(amount > 0 && amount <= MAXeditionToggle, "more than edition max allowed");
    MAXeditionToggle -= amount;
  
  }

function _checkWalletTrackLevel(uint256 amount) internal {
  if (WalletTrackLevel == 1){
    NumMinted1[msg.sender] = NumMinted1[msg.sender] + amount;
        require(NumMinted1[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 2){
    NumMinted2[msg.sender] = NumMinted2[msg.sender] + amount;
        require(NumMinted2[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 3){
    NumMinted3[msg.sender] = NumMinted3[msg.sender] + amount;
        require(NumMinted3[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 4){
    NumMinted4[msg.sender] = NumMinted4[msg.sender] + amount;
        require(NumMinted4[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 5){
    NumMinted5[msg.sender] = NumMinted5[msg.sender] + amount;
        require(NumMinted5[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 6){
    NumMinted6[msg.sender] = NumMinted6[msg.sender] + amount;
        require(NumMinted6[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 7){
    NumMinted7[msg.sender] = NumMinted7[msg.sender] + amount;
        require(NumMinted7[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 8){
    NumMinted8[msg.sender] = NumMinted8[msg.sender] + amount;
        require(NumMinted8[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 9){
    NumMinted9[msg.sender] = NumMinted9[msg.sender] + amount;
        require(NumMinted9[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  else if (WalletTrackLevel == 10){
    NumMinted10[msg.sender] = NumMinted10[msg.sender] + amount;
        require(NumMinted10[msg.sender] <= MaxPerWallet_EditionMint, "Cannot mint more than your allowance");
  }
  //choose 0-this allows use of the ADJUSTABLE FLEX per wallet and amounts- costs gas use function to adjust-- increase NumMinted_FLEX_Edition for those who minted before
  else if (WalletTrackLevel == 0){
    NumMinted_FLEX_Edition[msg.sender] = NumMinted_FLEX_Edition[msg.sender] + amount;
    require(NumMinted_FLEX_Edition[msg.sender] <= FLEX_EDITION_ALLOWED[msg.sender], "Cannot mint more than your allowance")
  ;}
  else {
      revert("Invalid Wallet Tracker");
    }

}

  function _checkEditionRange(uint256 amount, uint EditionNum) internal {
    require(EditionNum >= low, "wrong edition- not in range");
    require(EditionNum <= high, "wrong edition- not in range");
    require(amount > 0 && amount <= MAXrangeToggle, "more than edition range allowed");
    MAXrangeToggle -= amount; 
  }

  function _checkEdition1(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E1, "wrong edition");
    require(amount > 0 && amount <= maxE1, "more than edition range allowed");
    maxE1 -= amount; 
  }

  function _checkEdition2(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E2, "wrong edition");
    require(amount > 0 && amount <= maxE2, "more than edition range allowed");
    maxE2 -= amount; 
  }
  function _checkEdition3(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E3, "wrong edition");
    require(amount > 0 && amount <= maxE3, "more than edition range allowed");
    maxE3 -= amount; 
  }
  function _checkEdition4(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E4, "wrong edition");
    require(amount > 0 && amount <= maxE4, "more than edition range allowed");
    maxE4 -= amount; 
  }
  function _checkEdition5(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E5, "wrong edition");
    require(amount > 0 && amount <= maxE5, "more than edition range allowed");
    maxE5 -= amount; 
  }
  function _checkEdition6(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E6, "wrong edition");
    require(amount > 0 && amount <= maxE6, "more than edition range allowed");
    maxE6 -= amount; 
  }
  function _checkEdition7(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E7, "wrong edition");
    require(amount > 0 && amount <= maxE7, "more than edition range allowed");
    maxE7 -= amount; 
  }
  function _checkEdition8(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E8, "wrong edition");
    require(amount > 0 && amount <= maxE8, "more than edition range allowed");
    maxE8 -= amount; 
  }
  function _checkEdition9(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E9, "wrong edition");
    require(amount > 0 && amount <= maxE9, "more than edition range allowed");
    maxE9 -= amount; 
  }
  function _checkEdition10(uint256 amount, uint EditionNum) internal {
    require(EditionNum == E10, "wrong edition");
    require(amount > 0 && amount <= maxE10, "more than edition range allowed");
    maxE10 -= amount; 
  }

  function ownerMint(uint EditionNum, uint amount) public onlyOwner {
    incrementNumMinted(amount);
    _mint(msg.sender, EditionNum, amount, "");
  }



  function setMintEditionToggle(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 1, "Invalid state");
    mintEditionSaleToggle = newState;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setBaseUri(string calldata newUri) public onlyOwner {
    _setURI(newUri);
  }

  function setContractUri(string calldata newUri) public onlyOwner {
    _contractUri = newUri;
  }

  function setPrice(uint newPrice) public onlyOwner {
    price = newPrice;
  }

  function setPriceRange(uint newPriceRange) public onlyOwner {
    priceRANGE = newPriceRange;
  }

     function setLOW(uint newLOW) public onlyOwner {
    low = newLOW;
  }

     function setHIGH(uint newHIGH) public onlyOwner {
    high = newHIGH;
  }

  function setMAXeditionToggle(uint newMAX) public onlyOwner {
    MAXeditionToggle = newMAX;
  }

  function setE1(uint newE1) public onlyOwner {
    E1 = newE1;
  }

  function setE2(uint newE2) public onlyOwner {
    E2 = newE2;
  }

  function setE3(uint newE3) public onlyOwner {
    E3 = newE3;
  }

  function setE4(uint newE4) public onlyOwner {
    E4 = newE4;
  }

  function setE5(uint newE5) public onlyOwner {
    E5 = newE5;
  }

  function setE6(uint newE6) public onlyOwner {
    E6 = newE6;
  }

  function setE7(uint newE7) public onlyOwner {
    E7 = newE7;
  }

  function setE8(uint newE8) public onlyOwner {
    E8 = newE8;
  }

  function setE9(uint newE9) public onlyOwner {
    E9 = newE9;
  }

  function setE10(uint newE10) public onlyOwner {
    E10 = newE10;
  }

   function setmaxE1(uint newmaxE1) public onlyOwner {
    maxE1 = newmaxE1;
  }

  function setmaxE2(uint newmaxE2) public onlyOwner {
    maxE2 = newmaxE2;
  }

  function setmaxE3(uint newmaxE3) public onlyOwner {
    maxE3 = newmaxE3;
  }

  function setmaxE4(uint newmaxE4) public onlyOwner {
    maxE4 = newmaxE4;
  }

  function setmaxE5(uint newmaxE5) public onlyOwner {
    maxE5 = newmaxE5;
  }

  function setmaxE6(uint newmaxE6) public onlyOwner {
    maxE6 = newmaxE6;
  }

  function setmaxE7(uint newmaxE7) public onlyOwner {
    maxE7 = newmaxE7;
  }

  function setmaxE8(uint newmaxE8) public onlyOwner {
    maxE8 = newmaxE8;
  }

  function setmaxE9(uint newmaxE9) public onlyOwner {
    maxE9 = newmaxE9;
  }

  function setmaxE10(uint newmaxE10) public onlyOwner {
    maxE10 = newmaxE10;
  }

  function setpriceE1(uint newpriceE1) public onlyOwner {
    priceE1 = newpriceE1;
  }

  function setpriceE2(uint newpriceE2) public onlyOwner {
    priceE2 = newpriceE2;
  }

  function setpriceE3(uint newpriceE3) public onlyOwner {
    priceE3 = newpriceE3;
  }

  function setpriceE4(uint newpriceE4) public onlyOwner {
    priceE4 = newpriceE4;
  }

  function setpriceE5(uint newpriceE5) public onlyOwner {
    priceE5 = newpriceE5;
  }

  function setpriceE6(uint newpriceE6) public onlyOwner {
    priceE6 = newpriceE6;
  }

  function setpriceE7(uint newpriceE7) public onlyOwner {
    priceE7 = newpriceE7;
  }

  function setpriceE8(uint newpriceE8) public onlyOwner {
    priceE8 = newpriceE8;
  }

  function setpriceE9(uint newpriceE9) public onlyOwner {
    priceE9 = newpriceE9;
  }

  function setpriceE10(uint newpriceE10) public onlyOwner {
    priceE10 = newpriceE10;
  }


  function setMAXrangeToggle(uint newMAX) public onlyOwner {
    MAXrangeToggle = newMAX;
  }

  function setCurrentEdition(uint newEdition) public onlyOwner {
    CurrentEdition = newEdition;
  }

  function setMerkle1(bytes32 newMerkle1) public onlyOwner {
    Merkle1 = newMerkle1;
    }

    function setMerkle2(bytes32 newMerkle2) public onlyOwner {
    Merkle2 = newMerkle2;
    }
    function setMerkle3(bytes32 newMerkle3) public onlyOwner {
    Merkle3 = newMerkle3;
    }
    function setMerkle4(bytes32 newMerkle4) public onlyOwner {
    Merkle4 = newMerkle4;
    }
    function setMerkle5(bytes32 newMerkle5) public onlyOwner {
    Merkle5 = newMerkle5;
    }
    function setMerkle6(bytes32 newMerkle6) public onlyOwner {
    Merkle6 = newMerkle6;
    }
    function setMerkle7(bytes32 newMerkle7) public onlyOwner {
    Merkle7 = newMerkle7;
    }
    function setMerkle8(bytes32 newMerkle8) public onlyOwner {
    Merkle8 = newMerkle8;
    }
    function setMerkle9(bytes32 newMerkle9) public onlyOwner {
    Merkle9 = newMerkle9;
    }
    function setMerkle10(bytes32 newMerkle10) public onlyOwner {
    Merkle10 = newMerkle10;
    }
    function setMerkleRange(bytes32 newMerkleRange) public onlyOwner {
    MerkleRange = newMerkleRange;
    }

    function setMerkleEdition(bytes32 newMerkleEdition) public onlyOwner {
    MerkleEdition = newMerkleEdition;
    }

    function setWalletTrackLevel(uint newWalletTrackLevel) public onlyOwner {
    WalletTrackLevel = newWalletTrackLevel;
    }

     function setGatedMintEditionSaleToggle(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 1, "Invalid state");
    GatedmintEditionSaleToggle = newState;
  }

   function setGatedMintRangeSaleToggle(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 1, "Invalid state");
    GatedmintRangeSaleToggle = newState;
  }

  function setMintRangeSaleToggle(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 1, "Invalid state");
    mintRangeSaleToggle = newState;
  }

  function setMintMultiSaleToggle(uint newState) public onlyOwner {
    require(newState >= 0 && newState <= 1, "Invalid state");
    mintMultiSaleToggle = newState;
  }

  function editFLEX_EDITION_ALLOWED(address[] memory _a, uint256[] memory _amount) public onlyOwner {
    for(uint256 i; i < _a.length; i++){
    FLEX_EDITION_ALLOWED[_a[i]] = _amount[i];
    }
  }

  function editNumMinted_FLEX_Edition(address[] memory _a, uint256[] memory _amount) public onlyOwner {
    for(uint256 i; i < _a.length; i++){
    NumMinted_FLEX_Edition[_a[i]] = _amount[i];
    }
  }


  function contractURI() public view returns (string memory) {
    return _contractUri;
  }
}