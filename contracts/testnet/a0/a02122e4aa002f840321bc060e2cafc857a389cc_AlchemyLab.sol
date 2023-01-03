// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
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

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
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

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
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
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
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

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Tokens/RawMaterialNFT.sol";
import "./Utils/Rentable.sol";

contract LandRegistry is Ownable, Rentable {
    RawMaterialNFT public immutable RawMaterialNftContract;
    uint128 public maxLevel; 
    uint128 public renameCost = 1 ether;
    // tokenID => information
    mapping(uint256 => LandInfo) public LandInfoRegistry;
    // level => totalRequirement
    mapping(uint256 => LevelRequirements) public LevelUpCosts;
    mapping(uint256 => bytes32) public shopNames;
    mapping(bytes32 => bool) isNameTaken;

    struct LandInfo {
        uint128 level;
        uint128 landType;
    }

    struct LevelRequirements {
        uint256 avaxCost;
        bytes32 constructionMaterialsInfo;
    }

    error MaxLevelAchieved();
    error NotEnoughAvax();
    error NameAlreadyTaken();
    error OnlyLandOwner();
    error RecipeNotSet();

    event MaxLevelChanged(uint256 newMaxLevel);
    event NamingCostsChanged(uint256 newNamingCost);
    event NewLevelRequirements(uint256 level);
    event ShopNameChanged(uint256 tokenId);
    event LandInfoChanged(uint256 total);
    event LandLevelUp(uint256 tokenId);

    modifier onlyLandOwner(uint256 _tokenId) {
        if (
            (
                msg.sender == SmolApaLandNFTContract.ownerOf(_tokenId)
                    && ListedLandsForRent[_tokenId].endDate < block.timestamp
            )
                || (
                    ListedLandsForRent[_tokenId].rentee == msg.sender
                        && ListedLandsForRent[_tokenId].endDate > block.timestamp
                )
        ) {
            _;
        }
        else {
            revert OnlyLandOwner();
        }
    }

    constructor(address _smolApaLandAddress, address _feeAggregator, address _rawMaterialNFT)
        Rentable(_smolApaLandAddress, _feeAggregator)
    {
        RawMaterialNftContract = RawMaterialNFT(_rawMaterialNFT);
    }

    function setMaxLevel(uint256 _maxLevel) external onlyOwner {
        require(_maxLevel > maxLevel);
        maxLevel = uint128(_maxLevel);
        emit MaxLevelChanged(_maxLevel);
    }

    function setNamingCost(uint256 _newCost) external onlyOwner {
        renameCost = uint128(_newCost);
        emit NamingCostsChanged(_newCost);
    }

    function setLevelUpCosts(LevelRequirements[] calldata costs) external onlyOwner {
        if (costs.length != maxLevel) {
            revert();
        }
        for (uint256 level = 0; level < costs.length;) {
            LevelUpCosts[level] = costs[level];
            emit NewLevelRequirements(level);
            unchecked {
                ++level;
            }
        }
    }

    function setShopName(bytes32 _name, uint256 _tokenId) external payable onlyLandOwner(_tokenId) {
        if (msg.value < renameCost) {
            revert NotEnoughAvax();
        }
        if (isNameTaken[_name] == true) {
            revert NameAlreadyTaken();
        }
        isNameTaken[_name] = true;
        delete isNameTaken[shopNames[_tokenId]]; // remove the old name from takenDict
        shopNames[_tokenId] = _name;
        emit ShopNameChanged(_tokenId);
    }

    function setLandInfo(LandInfo[] calldata info) external onlyOwner {
        for (uint256 index = 0; index < 200;) {
            LandInfoRegistry[index] = info[index];
            unchecked {
                ++index;
            }
        }
        emit LandInfoChanged(200);
    }

    function setLandInfoSingle(LandInfo calldata info, uint index) external onlyOwner {
        LandInfoRegistry[index] = info;
        emit LandInfoChanged(1);
    }

    function levelUpSmolLand(uint256 _tokenId) external payable onlyLandOwner(_tokenId) {
        if (++LandInfoRegistry[_tokenId].level > maxLevel) {
            revert MaxLevelAchieved();
        }

        (uint256[] memory materialTypes, uint256[] memory materialAmount, uint256 levelCost) =
            getLevelUpCostData(_tokenId);
        if (levelCost > msg.value) {
            revert NotEnoughAvax();
        }

        RawMaterialNftContract.batchBurnRawMaterial(materialTypes, materialAmount, msg.sender);
        FeeAggregator.transfer(msg.value);
        emit LandLevelUp(_tokenId);
    }


    function getLevelUpCostData(uint256 _tokenId) internal view returns (uint256[] memory materialTypes, uint256[] memory materialAmount, uint256 levelCost) {
        levelCost = LevelUpCosts[LandInfoRegistry[_tokenId].level].avaxCost;
        bytes32 materialData = LevelUpCosts[LandInfoRegistry[_tokenId].level].constructionMaterialsInfo;
        (materialTypes, materialAmount) = getMaterialsFromRecipe(materialData); 

    }

    function getMaterialsFromRecipe(bytes32 recipe)
        internal
        pure
        returns (uint256[] memory types, uint256[] memory amounts)
    {
        uint256 len = uint8(recipe[0]);
        if(len == 0) {
            revert RecipeNotSet();
        }
        types = new uint[](len);
        amounts = new uint[](len);
        uint256 outterIndex;
        for (uint256 index; index < len; index++) {
            bytes1 higher = recipe[++outterIndex];
            bytes1 lower = recipe[++outterIndex];
            bytes2 materialType = higher | (bytes2(lower) >> 8); // higher becomes BB00, since bytes are left allinged
            types[index] = uint16(materialType);
            amounts[index] = uint8(recipe[++outterIndex]);
        }
    }

    function getLeases(uint256 _tokenId) external view returns (Lease memory) {
        return ListedLandsForRent[_tokenId];
    }
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../Tokens/RawMaterialNFT.sol";
import "../LandRegistery.sol";
import "../Utils/Constants.sol";
import "../Tokens/Blueprints.sol";
import "../Tokens/GearNFT.sol";
import "../Utils/FeeCollector.sol";
import "../Utils/CoalConsumer.sol";

contract AlchemyLab is FeeCollector, Ownable, CoalConsumer {
    Blueprint public immutable BlueprintContract;
    RawMaterialNFT public immutable RawMaterialNftContract;
    // landTokenId => slot => address => Order
    mapping(address => mapping(uint256 => Order)) JobsDictionary;
    mapping(uint256 => mapping(uint256 => uint256)) public slotInfo;

    error JobNotFound();
    error TooSoon();
    error WrongSlot();
    error NoMoreFreeSlots();
    error WrongBlueprint();
    error RecipeNotSet();
    error SlotOccupied();

    event BrewStarted(uint256 blueprintId, uint256 landTokenId, uint256 slotId);
    event PotionBrewed(uint256 jobId);

    struct Order {
        uint32 completedTimeStamp;
        uint16 blueprintId;
    }

    constructor(
        address _smolApaLandAddress,
        address _feeAggregator,
        address _rawMaterialNftContract,
        address _landRegistery,
        address _blueprintAddress
    )
        Ownable()
        FeeCollector(_smolApaLandAddress, _feeAggregator, _landRegistery, LaboratoryType)
        CoalConsumer(_rawMaterialNftContract)
    {
        RawMaterialNftContract = RawMaterialNFT(_rawMaterialNftContract);
        BlueprintContract = Blueprint(_blueprintAddress);
    }

    function startCrafting(uint256 _blueprintId, uint256 _landTokenId, uint256 _slotId) external payable {
        (uint256 level, uint256 landType) = LandRegistryContract.LandInfoRegistry(_landTokenId);
        if (landType != LandType) {
            revert WrongLand();
        }
        // pick a slot as long as it doesnt exceed the max. slot size
        uint256 maxSlots = getMaxSlots(level);
        if (_slotId >= maxSlots) {
            revert WrongSlot();
        }

        uint256 completedTimeStamp = block.timestamp + determineCraftingTime(level);
        if (slotInfo[_landTokenId][_slotId] > block.timestamp) {
            revert SlotOccupied();
        }

        slotInfo[_landTokenId][_slotId] = completedTimeStamp; // update the timeslot

        handleFees(_landTokenId);

        if (_blueprintId > COMMON_SCHEMATIC || _blueprintId < COMMON_FORMULA) {
            revert WrongBlueprint();
        }

        useCoal(1, _landTokenId);

        (uint256[] memory types, uint256[] memory amounts) = getRequiredMaterials(_blueprintId);
        RawMaterialNftContract.batchBurnRawMaterial(types, amounts, msg.sender);
        BlueprintContract.burnBlueprint(_blueprintId, msg.sender);
        uint256 jobId = _landTokenId * 100 + _slotId;
        JobsDictionary[msg.sender][jobId] = Order(uint32(completedTimeStamp), uint16(_blueprintId));
        emit BrewStarted(_blueprintId, _landTokenId, _slotId);
    }

    function getMaxSlots(uint256 _level) internal pure returns (uint256 maxSlot) {
        maxSlot = _level; // TODO get slot per level
    }

    function claim(uint256 _landTokenId, uint256 _slotId) external {
        uint256 jobId = _landTokenId * 100 + _slotId;
        Order storage order = JobsDictionary[msg.sender][jobId];
        if (order.completedTimeStamp > block.timestamp) {
            revert TooSoon();
        }
        if (order.completedTimeStamp == 0) {
            revert JobNotFound();
        }
        uint256 potionType = order.blueprintId;
        delete JobsDictionary[msg.sender][jobId];
        RawMaterialNftContract.mintRawMaterial(potionType, 1, msg.sender);
        emit PotionBrewed(jobId);
    }

    function getRequiredMaterials(uint256 _blueprintId)
        internal
        view
        returns (uint256[] memory types, uint256[] memory amounts)
    {
        uint256 blueprintIndex = _blueprintId % 200; // example 2206 -> index = 6 , category 2206 - 6 = 2200
        uint256 blueprintCategory = _blueprintId - blueprintIndex; //
        bytes32 blueprintRequirements = BlueprintContract.blueprints(blueprintCategory, blueprintIndex - 1); // -1 is necessary because blueprints 
        //bytes32[] starts from 0 and the blueprintId is always RARITY + x: for example if blueprintId is 3001 the recipe is in
        // position 0 and blueprintIndex will be 1 in this case which will produce an error
        return getMaterialsFromRecipe(blueprintRequirements);
    }

    function getMaterialsFromRecipe(bytes32 recipe)
        internal
        pure
        returns (uint256[] memory types, uint256[] memory amounts)
    {
        uint256 len = uint8(recipe[0]);
        if(len == 0) {
            revert RecipeNotSet();
        }
        types = new uint[](len);
        amounts = new uint[](len);
        uint256 outterIndex;
        for (uint256 index; index < len; index++) {
            bytes1 higher = recipe[++outterIndex];
            bytes1 lower = recipe[++outterIndex];
            bytes2 materialType = higher | (bytes2(lower) >> 8); // higher becomes BB00, since bytes are left allinged
            types[index] = uint16(materialType);
            amounts[index] = uint8(recipe[++outterIndex]);
        }
    }

    function determineCraftingTime(uint256 level) internal pure returns (uint256 time) {
        uint256 baseTime = 24 hours;
        if (level == 1) {
            return baseTime;
        } else if (level == 2) {
            return (baseTime - 15 minutes);
        } else if (level == 3) {
            return (baseTime - 30 minutes);
        } else if (level == 4) {
            return (baseTime - 45 minutes);
        } else if (level == 5) {
            return (baseTime - 60 minutes);
        } else if (level == 6) {
            return (baseTime - 75 minutes);
        } else if (level == 7) {
            return (baseTime - 90 minutes);
        } else if (level == 8) {
            return (baseTime - 105 minutes);
        } else if (level == 9) {
            return (baseTime - 120 minutes);
        } else {
            return (baseTime - 240 minutes);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../Utils/Constants.sol";

contract Blueprint is ERC1155, Ownable {
    mapping(uint256 => bytes32[]) public blueprints;

    mapping(address => bool) public GameEngine;

    error GameEngineOnly();

    event BlueprintsExtended(uint256 category, bytes32 info);

    constructor(string memory uri) ERC1155(uri) Ownable() {}

    /// @notice mints a blueprint in the given rarity category
    /// @dev callable by a game engine (only Academy)
    /// @param category The rarity category of the blueprints (schematics or formulas) such as COMMON, RARE, ...
    function mintBlueprint(uint256 category, uint256 _seed, address _user) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        // a random item from the list of blueprints will choosen
        uint256 moduloLimit = blueprints[category].length;
        uint256 result = (_seed % moduloLimit) + 1; // 0 will produce a false result since category name (3000) etc doesnt correspond to a recipe
        uint256 blueprintId = category + result;
        _mint(_user, blueprintId, 1, bytes(""));
    }

    function burnBlueprint(uint256 _tokenType, address _user) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        _burn(_user, _tokenType, 1);
    }

    /// @notice adds a blueprint to the given categories list
    /// @dev the order matters and it will define the blueprintId (which has to match the gearTemplate) so the shifting of items is not possible
    /// @param _category the rariry category of the blueprints (schematics or formulas) such as COMMON, RARE, ...
    function addBlueprint(bytes32 _x, uint256 _category) external onlyOwner {
        blueprints[_category].push(_x);
        emit BlueprintsExtended(_category, _x);
    }

    function setBlueprints(bytes32[] memory _x, uint256 _category) external onlyOwner {
        blueprints[_category] = _x;
        for (uint256 index = 0; index < _x.length; ++index) {
            emit BlueprintsExtended(_category, _x[index]);
        }
    }

    function editBlueprint(bytes32 _recipe, uint256 _category, uint _index) external onlyOwner {
        blueprints[_category][_index] = _recipe;
        emit BlueprintsExtended(_category, _recipe);
    }

    function setGameEngine(address _gameEngine, bool _value) external onlyOwner {
        GameEngine[_gameEngine] = _value;
    }

    function setUri(string calldata _uri) external onlyOwner {
        _setURI(_uri);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract GearNFT is ERC721, Ownable {
    using Strings for uint256;

    mapping(uint256 => bytes32) public GearInfo; // tokenId => gearData
    // [attribute_len]  [item_type_higher_byte]  [item_type_lower_byte] [attr1]        [attr2]                  [attr3]               [attr4]
    // [2]              [0x12]                   [0xAD]                 [armor/weapon] [current_durability: 2]  [base_durability: 90] [dmg/amor]

    mapping(uint256 => bytes32) public GearInfoTemplate; // gearType => gearMetadata
    // [attribute_len]  [item_type_higher_byte]  [item_type_lower_byte]  [attr1]        [attr1_range]         [attr2]                [attr2_range]
    // [2]              [0x12]                   [0xAD]                  [base_dmg: 4]  [dmg_roll_modulo: 2]  [base_durability: 90]  [base_durability_roll_modulo: 30]

    
    // [attribute_len]  [item_type_higher_byte]  [item_type_lower_byte]  [attr1]                    [attr1_range]                 [attr2]                [attr2_range]
    // [2]              [0x12]                   [0xAD]                  [base_durability: 80]      [durability_roll_modulo: 20]  [base_durability: 90]  [base_durability_roll_modulo: 30]
    mapping(uint256 => bytes32) public RepairInfo; // gearType => repairMaterials
    mapping(uint256 => bytes32) public RecycleInfo; // gearType => recycleMaterials
    mapping(address => bool) public GameEngine; // starts from 1;

    uint256 public supply;
    string public baseUri;

    error GameEngineOnly();
    error RecipeMismatch();

    event GearAttributes(uint256 tokenId, bytes32 attributes);
    event GearAttributeTemplateAdded(uint256 gearType, bytes32 attributes);
    event RepairInfoAdded(uint256 gearType, bytes32 attributes);
    event RecycleInfoAdded(uint256 gearType, bytes32 attributes);
    event DEBUG(string name, uint val);

    constructor(string memory _name, string memory _symbol, string memory _baseUri) ERC721(_name, _symbol) Ownable() {
        baseUri = _baseUri;
    }

    function setGameEngine(address _gameEngine, bool _value) external onlyOwner {
        GameEngine[_gameEngine] = _value;
    }

    function mintGear(uint256 gearType, address user, uint256 seed) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        uint256 nextTokenId = supply++;
        _mint(user, nextTokenId);

        GearInfo[nextTokenId] = calculateGearStats(gearType, seed);
        emit GearAttributes(nextTokenId, GearInfo[nextTokenId]);
    }

    function calculateGearStats(uint256 gearType, uint256 seed) internal view returns (bytes32 attributes) {
        bytes32 template = GearInfoTemplate[gearType];
        bytes32 localConstant = 0xFFFFFF0000000000000000000000000000000000000000000000000000000000;
        attributes |= (localConstant & template); // get len and item type ( 3 bytes)
        bytes1 maxDurability = bytes1(uint8(template[3]) + uint8(seed % uint8(template[4])));
        attributes |= (bytes32(maxDurability) >> (8 * 3)); // max durability
        attributes |= (bytes32(maxDurability) >> (8 * 4)); // current durability, starts from 100/100

        uint256 len = (uint8(attributes[0]) - 1) * 2 ; // skip durability
        uint256 outerIndex = 4;
        for (uint256 index = 4; index < len + 4;) {
            bytes1 attribute = bytes1(uint8(template[index + 1]) + uint8(seed % uint8(template[index + 2])));
            attributes |= (bytes32(attribute) >> (8 * (++outerIndex)));
            index+=2;
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        uint256 gearType = uint8(GearInfo[tokenId][0]);
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, gearType.toString())) : "";
    }


    function setBaseUri(string calldata _baseUri) external onlyOwner() {
        baseUri = _baseUri;
    }

    function burnGear(uint256 tokenId) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        _burn(tokenId);
    }

    function addGearInfoTemplate(uint256 gearType, bytes32 info) external onlyOwner {
        GearInfoTemplate[gearType] = info;
        emit GearAttributeTemplateAdded(gearType, info);
    }

    function addGearRepairInfo(uint256 gearType, bytes32 info) external onlyOwner {
        RepairInfo[gearType] = info;
        emit RepairInfoAdded(gearType, info);
    }

    function addGearRecycleInfo(uint256 gearType, bytes32 info) external onlyOwner {
        RecycleInfo[gearType] = info;
        emit RecycleInfoAdded(gearType, info);
    }

    function setGearInfo(uint256 gearNFTId, bytes32 _info) external {
        // TODO this for repairs but the caller contract should emit an event for this
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        GearInfo[gearNFTId] = _info;
    }

    function getGearQuality(uint256 _targetMaterial) public pure returns (uint256) {
        if (_targetMaterial > 2200) {
            return 0; // TODO complete the list
        } else {
            return 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RawMaterialNFT is ERC1155, Ownable {
    uint256 public constant BROWSER_MINT_LIMIT = 200;
    mapping(address => bool) public GameEngine; // starts from 1;
    mapping(uint256 => bool) public BrowserGameMintable;
    // TokenType => Amount produced (Always use with +1)
    mapping(uint256 => uint256) public AmountProduced;
    BrowserGameLimits public browserGameLimits;

    error GameEngineOnly();
    error BrowserGameAdminOnly();
    error BrowserGameMaterialOnly();
    error TooManyMintsToday();

    struct BrowserGameLimits {
        address admin;
        uint16 dailyLimit;
        uint64 startTimestamp;
    }

    constructor(string memory uri) ERC1155(uri) {}

    function setUri(string calldata newuri) external onlyOwner {
        _setURI(newuri);
    }

    function setGameEngine(address _gameEngine, bool _value) external onlyOwner {
        GameEngine[_gameEngine] = _value;
    }

    function setBrowserGameLimits(address _admin, uint256 _dailyLimit) external onlyOwner {
        browserGameLimits = BrowserGameLimits(_admin, uint16(_dailyLimit), uint64(block.timestamp));
    }

    function setAmountProduced(uint256 _type, uint256 _amount) external onlyOwner {
        // TODO: Whats that ?
        AmountProduced[_type] = _amount;
    }

    function mintRawMaterial(uint256 _type, uint256 _amount, address _user) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        _mint(_user, _type, _amount, bytes(""));
    }

    function batchMintRawMaterial(uint256[] calldata _types, uint256[] calldata _amounts, address _user) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        _mintBatch(_user, _types, _amounts, bytes(""));
    }

    function burnRawMaterial(uint256 _type, uint256 _amount, address _user) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        _burn(_user, _type, _amount);
    }

    function batchBurnRawMaterial(uint256[] calldata _types, uint256[] calldata _amounts, address _user) external {
        if (!GameEngine[msg.sender]) {
            revert GameEngineOnly();
        }
        _burnBatch(_user, _types, _amounts);
    }

    function mintBrowserGameRawMaterial(uint256 _type, uint256 _amount, address _user) external {
        if (!BrowserGameMintable[_type]) {
            revert BrowserGameMaterialOnly();
        }
        if (browserGameLimits.admin != msg.sender) {
            revert BrowserGameAdminOnly();
        }

        if (block.timestamp > browserGameLimits.startTimestamp + 1 days) {
            // reset
            browserGameLimits.startTimestamp = uint64(block.timestamp);
            browserGameLimits.dailyLimit = 0;
        }

        if (browserGameLimits.dailyLimit > BROWSER_MINT_LIMIT) {
            revert TooManyMintsToday();
        }

        browserGameLimits.dailyLimit++;
        _mint(_user, _type, _amount, bytes(""));
    }

    function setBrowserGameMintables(uint256 _materialType, bool _value) external onlyOwner {
        BrowserGameMintable[_materialType] = _value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Tokens/RawMaterialNFT.sol";
import "./Constants.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CoalConsumer is Constants, Ownable {
    RawMaterialNFT public immutable RawMaterialNFTContract;
    //LandTokenId => balance
    mapping(uint256 => uint256) CoalBalance;

    // TODO events

    constructor(address _RawMaterialNftContract) {
        RawMaterialNFTContract = RawMaterialNFT(_RawMaterialNftContract);
    }

    function depositCoal(uint256 _amount, uint256 _landTokenId) external {
        CoalBalance[_landTokenId] += _amount;
        RawMaterialNFTContract.burnRawMaterial(COAL_ORE, _amount, msg.sender);
    }

    function useCoal(uint256 _amount, uint256 _landTokenId) internal {
        CoalBalance[_landTokenId] -= _amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Constants {
    uint256 public constant BASE_PROTOCOL_FEE_PERCENTAGE = 40;
    uint256 public constant BASE_ADVENTURE_FEE_PERCENTAGE = 20;
    // LAND TYPES
    uint256 public constant MineType = 100;
    uint256 public constant GardenType = 200;
    uint256 public constant WorkshopType = 300;
    uint256 public constant SmelterType = 400;
    uint256 public constant MarketType = 500;
    uint256 public constant ForgeType = 600;
    uint256 public constant AcademyType = 700;
    uint256 public constant KitchenType = 800;
    uint256 public constant LaboratoryType = 900;
    // MINE
    uint256 public constant STONE_ORE = MineType + 1;
    uint256 public constant COAL_ORE = MineType + 2;
    uint256 public constant SALT_CRYSTAL = MineType + 3;
    uint256 public constant QUARTZ_ORE = MineType + 4;
    uint256 public constant IRON_ORE = MineType + 5;
    uint256 public constant DARK_SILVER_ORE = MineType + 6;
    uint256 public constant METEORITE_ORE = MineType + 7;
    // GARDEN
    uint256 public constant DAISY = GardenType + 1;
    uint256 public constant LILY = GardenType + 2;
    uint256 public constant TULIP = GardenType + 3;
    uint256 public constant ROSE = GardenType + 4;
    uint256 public constant LOTUS = GardenType + 5;
    uint256 public constant LETTUCE = GardenType + 6;
    uint256 public constant PEPPER = GardenType + 7;
    uint256 public constant ONION = GardenType + 8;
    uint256 public constant POTATOES = GardenType + 9;
    uint256 public constant DRAGON_FRUIT = GardenType + 10;

    // FORAGING
    uint256 public constant ELDERBERRY = GardenType + 11;
    uint256 public constant MUSHROOM = GardenType + 12;
    // FISHING
    uint256 public constant FISH1 = 400;
    uint256 public constant FISH2 = 401;
    uint256 public constant FISH3 = 402;
    uint256 public constant FISH4 = 403;
    uint256 public constant FISH5 = 404;
    uint256 public constant FISH6 = 405;
    uint256 public constant FISH7 = 406;
    uint256 public constant FISH8 = 407;
    uint256 public constant FISH9 = 408;
    uint256 public constant FISH10 = 409;

    // HUNTING
    uint256 public constant VENISON = 510;
    uint256 public constant HIDE = 511;

    //FOREST
    uint256 public constant WOOD = 512;

    // WORKSHOP
    uint256 public constant PLANK = WorkshopType + 1;
    uint256 public constant GLASS = WorkshopType + 2;
    uint256 public constant OIL = WorkshopType + 3;
    uint256 public constant LEATHER = WorkshopType + 4;
    uint256 public constant PAPER = WorkshopType + 5;
    uint256 public constant SALT = WorkshopType + 6;
    uint256 public constant DAISY_EXTRACT = WorkshopType + 7;
    uint256 public constant LILY_EXTRACT = WorkshopType + 8;
    uint256 public constant TULIP_EXTRACT = WorkshopType + 9;
    uint256 public constant ROSE_EXTRACT = WorkshopType + 10;
    uint256 public constant LOTUS_EXTRACT = WorkshopType + 11;
    // SMELTER
    uint256 public constant STONE_BLOCK = SmelterType + 1;
    uint256 public constant QUARTZ_INGOT = SmelterType + 2;
    uint256 public constant IRON_INGOT = SmelterType + 3;
    uint256 public constant DARK_SILVER_INGOT = SmelterType + 4;
    uint256 public constant METEORITE_INGOT = SmelterType + 5;
    uint256 public constant STEEL_INGOT = SmelterType + 6;
    uint256 public constant HARDENED_DARK_SILVER_INGOT = SmelterType + 7;
    uint256 public constant HARDENED_METEORITE_INGOT = SmelterType + 8;
    // CHEST
    uint256 public constant CHEST_NFT_TYPE = 999;
    uint256 public constant KEY_NFT_TYPE = 998;
    uint256 public constant AIRDROP_CHEST_NFT_TYPE = 997;
    // BLUEPRINTS
    uint256 public constant COMMON_FORMULA = 2000;
    uint256 public constant RARE_FORMULA = 2200;
    uint256 public constant LEGENDARY_FORMULA = 2400;
    uint256 public constant COMMON_SCHEMATIC = 3000;
    uint256 public constant RARE_SCHEMATIC = 3200;
    uint256 public constant LEGENDARY_SCHEMATIC = 3400;
    // Potions
    uint256 public constant HEALING_POTION = 2201;
    uint256 public constant TRAIT_POTION = 2202;
    uint256 public constant TRAIT_FREEZE_POTION = 2203;
    uint256 public constant TRAIT_DEFREEZE_POTION = 2204;

    // Kitchen
    uint256 public constant COMMON_KITCHEN_RECIPE = 4000;
    uint256 public constant RARE_KITCHEN_RECIPE = 4100;
    uint256 public constant LEGENDARY_KITCHEN_RECIPE = 4200;

    uint256 public constant COMMON_FOOD = COMMON_KITCHEN_RECIPE / 100;
    uint256 public constant RARE_FOOD = RARE_KITCHEN_RECIPE / 100;
    uint256 public constant LEGENDARY_FOOD = LEGENDARY_KITCHEN_RECIPE / 100;

    // CHARACTER TRAITS
    uint256 public constant NO_TRAIT = 0;
    uint256 public constant NUMBER_OF_TRAITS = 6;
    uint256 public constant NUMBER_OF_TRAIT_TYPES = 5;
    uint256 public constant NUMBER_OF_ATTRIBUTES = 3;
    uint256 public constant NUMBER_OF_FOOD_BONUSES = 3;

    uint256 public constant STR_ATTRIBUTE_INDEX = 0;
    uint256 public constant HEALTH_ATTRIBUTE_INDEX = 1;
    uint256 public constant LUCK_ATTRIBUTE_INDEX = 2;
    uint256 public constant STR_TRAIT_INDEX = 3;
    uint256 public constant HEALTH_TRAIT_INDEX = 4;
    uint256 public constant LUCK_TRAIT_INDEX = 5;
    uint256 public constant INTELLIGENCE_TRAIT_INDEX = 6;
    uint256 public constant HUNGER_TRAIT_INDEX = 7;
    uint256 public constant SPEED_BONUS_INDEX = 8;
    uint256 public constant CRITICAL_HIT_BONUS_INDEX = 9;
    uint256 public constant DODGE_BONUS_INDEX = 10;

    uint256 public constant STRONG = 1;
    uint256 public constant ROBUST = 2;
    uint256 public constant HERCULEAN = 3;
    uint256 public constant TENDER = 4;
    uint256 public constant FRAGILE = 5;
    uint256 public constant PUNY = 6;

    uint256 public constant FIT = 11;
    uint256 public constant HEARTHY = 12;
    uint256 public constant WHOLE_BODY = 13;
    uint256 public constant SICK = 14;
    uint256 public constant FEEBLE = 15;
    uint256 public constant INFIRM = 16;

    uint256 public constant LUCKY = 21;
    uint256 public constant FORTUNATE = 22;
    uint256 public constant GOLDEN = 23;
    uint256 public constant MISERABLE = 24;
    uint256 public constant CURSED = 25;
    uint256 public constant ILL_OMENED = 26;

    uint256 public constant HUNGRY = 31;
    uint256 public constant GORGING = 32;
    uint256 public constant GLUTTONOUS = 33;
    uint256 public constant INAPPETETIC = 34;
    uint256 public constant FRUGAL = 35;
    uint256 public constant SPARTAN = 36;

    uint256 public constant SMART = 41;
    uint256 public constant GIFTED = 42;
    uint256 public constant GENIUS = 43;
    uint256 public constant SLOW = 44;
    uint256 public constant DUMB = 45;
    uint256 public constant BRAIN_DAMAGED = 46;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "./Constants.sol";
import "../LandRegistery.sol";

contract FeeCollector is Constants {
    address payable public immutable FeeAggregator;
    uint256 public immutable LandType;
    IERC721 public immutable SmolApaLandNFTContract;
    LandRegistry public immutable LandRegistryContract;
    mapping(uint256 => uint256) public FeeInfo;
    mapping(uint256 => uint256) public ShopBalance;
    uint256 protocolBalance;

    error OnlyTokenOwner();
    error CostNotCovered();
    error WrongLand();
    error OnlyOwnerOrRenter();
    error FeeNotSet();

    event LandFeeWithdrawn(uint256 tokenId);
    event FeeSet(uint256 tokenId, uint256 newFee);

    constructor(address _smolApaLandAddress, address _feeAggregator, address _landRegistery, uint256 _landType) {
        SmolApaLandNFTContract = IERC721(_smolApaLandAddress);
        FeeAggregator = payable(_feeAggregator);
        LandRegistryContract = LandRegistry(_landRegistery);
        LandType = _landType;
    }

    modifier onlyLandOwner(uint256 _tokenId) {
        if (
            (
                msg.sender == SmolApaLandNFTContract.ownerOf(_tokenId)
                    && LandRegistryContract.getLeases(_tokenId).endDate < block.timestamp
            )
                || (
                    LandRegistryContract.getLeases(_tokenId).rentee == msg.sender
                        && LandRegistryContract.getLeases(_tokenId).endDate > block.timestamp
                )
        ) {
            _;
        }
        else { revert OnlyOwnerOrRenter(); }

    }

    function withdrawLandFee(uint256 _landTokenId) external onlyLandOwner(_landTokenId) {
        uint256 fee = ShopBalance[_landTokenId];
        delete ShopBalance[_landTokenId];
        payable(msg.sender).transfer(fee);
        emit LandFeeWithdrawn(_landTokenId); // TODO check if the msg.value is visible thru the graph
    }

    function withdrawProtocolFee() external {
        uint256 balance = protocolBalance;
        protocolBalance = 0;
        FeeAggregator.transfer(balance);
    }

    function setFee(uint256 _landTokenId, uint256 _fee) external onlyLandOwner(_landTokenId) {
        (,uint256 landType) = LandRegistryContract.LandInfoRegistry(_landTokenId);
        // land type has to match
        if (landType != LandType) {
            revert WrongLand();
        }

        FeeInfo[_landTokenId] = _fee;
        emit FeeSet(_landTokenId, _fee);
    }

    function handleFees(uint256 _landTokenId) internal {
        uint256 fee = FeeInfo[_landTokenId];
        if(fee <= 0) {
            revert FeeNotSet();
        }
        if (msg.value < fee) {
            revert CostNotCovered();
        }
        uint shopOwnerFee =  (fee * (100 - BASE_PROTOCOL_FEE_PERCENTAGE)) / 100;
        ShopBalance[_landTokenId] += shopOwnerFee;
        protocolBalance += (fee - shopOwnerFee);
        // TODO : We should be able to infer this within the graph
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "./Constants.sol";

contract Rentable is Constants {
    address payable public immutable FeeAggregator;
    IERC721 public immutable SmolApaLandNFTContract;
    mapping(uint256 => Lease) public ListedLandsForRent;
    mapping(address => uint256) public renterBalance;
    uint256 protocolBalance;

    error OnlyTokenOwner();
    error CostNotCovered();
    error WrongLand();
    error CantRentLongerThanMonth();
    error PropertyAlreadyRented();
    error NotRentable();

    struct Lease {
        uint32 period;
        address rentee;
        uint32 endDate;
        uint128 rent;
    }

    constructor(address _smolApaLandAddress, address _feeAggregator) {
        SmolApaLandNFTContract = IERC721(_smolApaLandAddress);
        FeeAggregator = payable(_feeAggregator);
    }

    function setRentContract(uint256 _landTokenId, uint256 _period, uint256 _rent) external {
        if (msg.sender != SmolApaLandNFTContract.ownerOf(_landTokenId)) {
            revert OnlyTokenOwner();
        }

        if (_period > 30 days) {
            revert CantRentLongerThanMonth();
        }

        ListedLandsForRent[_landTokenId].period = uint32(_period);
        ListedLandsForRent[_landTokenId].rent = uint128(_rent);
    }

    function rentProperty(uint256 _landTokenId) external payable {
        Lease memory rentalAgreement = ListedLandsForRent[_landTokenId];

        if (msg.value < rentalAgreement.rent) {
            revert CostNotCovered();
        }

        if (rentalAgreement.rent == 0) {
            revert NotRentable();
        }
        if (rentalAgreement.endDate > block.timestamp) {
            revert PropertyAlreadyRented();
        }
        rentalAgreement.rentee = msg.sender;
        rentalAgreement.endDate = uint32(block.timestamp + rentalAgreement.period);
        ListedLandsForRent[_landTokenId] = rentalAgreement;
        handleRent(rentalAgreement.rent);
    }

    function handleRent(uint256 _rent) internal {
        renterBalance[msg.sender] += (_rent * (100 - BASE_PROTOCOL_FEE_PERCENTAGE)) / 100;
        protocolBalance += (_rent * BASE_PROTOCOL_FEE_PERCENTAGE) / 100;
    }

    function claimRent() external {
        uint256 rent = renterBalance[msg.sender];
        delete renterBalance[msg.sender];
        payable(msg.sender).transfer(rent);
    }

    function withdrawProtocolFee() external {
        uint256 balance = protocolBalance;
        protocolBalance = 0;
        FeeAggregator.transfer(balance);
    }
}