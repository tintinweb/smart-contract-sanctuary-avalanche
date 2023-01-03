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
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    //if (msg.sender != vrfCoordinator) {
    //  revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    //}
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "../Tokens/RawMaterialNFT.sol";
import "../LandRegistery.sol";
import "../Utils/Constants.sol";
import "../Utils/FeeCollector.sol";
import "../Utils/CoalConsumer.sol";

abstract contract RefinementBase is FeeCollector, Ownable, CoalConsumer {
    RawMaterialNFT public immutable RawMaterialNftContract;
    // Address => jobID => Job
    mapping(address => mapping(uint256 => Job)) JobsDictionary;
    mapping(uint256 => mapping(uint256 => uint256)) public slotInfo;
    mapping(uint256 => bytes32) public recipes;
    // ResourceType => RequiredShopLevel
    mapping(uint256 => uint256) public OutcomeDictionary;

    error JobNotFound();
    error TooSoon();
    error WrongSlot();
    error NoMoreFreeSlots();
    error LevelTooLow();
    error InvalidResource();
    error SlotOccupied();
    error RecipeNotSet();

    event OutcomeDictionarySet(uint256 targetResource, uint256 tresholdlevel);
    event RecipeSet(uint256 targetResource, bytes32 recipe);
    event CraftingStarted(uint256 targetResource, uint256 landTokenId, uint256 slotId);
    event Info(string x, uint y);

    struct Job {
        uint32 completedTimeStamp;
        uint32 targetMaterial;
        uint16 gearType;
    }

    constructor(
        address _smolApaLandAddress,
        address _feeAggregator,
        address _rawMaterialNftContract,
        address _landRegistery,
        uint256 _landType
    )
        FeeCollector(_smolApaLandAddress, _feeAggregator, _landRegistery, _landType)
        CoalConsumer(_rawMaterialNftContract)
    {
        RawMaterialNftContract = RawMaterialNFT(_rawMaterialNftContract);
    }

    function setOutcomeDictionary(uint256 _targetResource, uint256 _tresholdlevel) external onlyOwner { // TODO better name this
        OutcomeDictionary[_targetResource] = _tresholdlevel;
        emit OutcomeDictionarySet(_targetResource, _tresholdlevel);
    }

    function setRecipe(uint256 _targetMaterial, bytes32 _recipe) external onlyOwner {
        recipes[_targetMaterial] = _recipe;
        emit RecipeSet(_targetMaterial, _recipe);
    }

    function startCrafting(uint256 _targetResource, uint256 _landTokenId, uint256 _slotId) external payable {
        (uint256 level, uint256 landType) = LandRegistryContract.LandInfoRegistry(_landTokenId);
        if (landType != LandType) {
            revert WrongLand();
        }
        // pick an arbitrary slot as long as it doesnt exceed the max. slot size
        uint256 maxSlots = getMaxSlots(level);
        if (_slotId >= maxSlots) {
            revert WrongSlot();
        }

        if (OutcomeDictionary[_targetResource] > level) {
            revert LevelTooLow();
        }

        if (OutcomeDictionary[_targetResource] == 0) {
            revert InvalidResource();
        }

        if (slotInfo[_landTokenId][_slotId] > block.timestamp) {
            revert SlotOccupied();
        }

        useCoal(1, _landTokenId);
        handleFees(_landTokenId);

        (uint256[] memory types, uint256[] memory amounts) = getMaterialsFromRecipe(recipes[_targetResource]);
        RawMaterialNftContract.batchBurnRawMaterial(types, amounts, msg.sender);
        uint256 completedTimeStamp = block.timestamp + determineCraftingTime(level);
        slotInfo[_landTokenId][_slotId] = completedTimeStamp; // update the timeslot
        uint256 jobId = _landTokenId * 100 + _slotId;
        JobsDictionary[msg.sender][jobId] = Job(uint32(completedTimeStamp), uint32(_targetResource), 0);
        emit CraftingStarted(_targetResource, _landTokenId, _slotId); // TODO Fees should be inferred from the graph
    }

    function getMaterialsFromRecipe(bytes32 recipe)
        internal
        pure
        returns (uint256[] memory types, uint256[] memory amounts)
    {
        uint256 len = uint8(recipe[0]);
        if( len == 0) {
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

    function claim(uint256 _landTokenId, uint256 _slotId) external virtual;
    function determineCraftingTime(uint256 level) internal pure virtual returns (uint256);
    function getMaxSlots(uint256 _level) internal pure virtual returns (uint256 maxSlot);
    function getSuccessChances(uint256 _targetResource, uint256 _level) internal view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../../Utils/VRFConsumerV2.sol";
import "../RefinementBase.sol";
import "../../Utils/Constants.sol";

contract Workshop is RefinementBase, VRFConsumerV2Ownable {
    mapping(uint256 => Request) PlayerRequest;

    event Claimed(address user, uint256 jobId);

    constructor(
        address _smolApaLandAddress,
        address _feeAggregator,
        address _rawMaterialNftContract,
        address _landRegistery,
        uint64 subscriptionId
    )
        RefinementBase(_smolApaLandAddress, _feeAggregator, _rawMaterialNftContract, _landRegistery, WorkshopType)
        VRFConsumerV2Ownable(subscriptionId)
    {}

    struct Request {
        address userAddress;
        uint32 requestedMaterial;
        uint32 jobId;
    }

    function getMaxSlots(uint256 _level) internal pure override returns (uint256) {
        if (_level <= 3) {
            return 1;
        } else if (_level <= 7) {
            return 2;
        } else {
            return 3;
        }
    }

    function claim(uint256 _landTokenId, uint256 _slotId) external override {
        (uint256 level, uint256 landType) = LandRegistryContract.LandInfoRegistry(_landTokenId);
        if (landType != LandType) {
            revert WrongLand();
        }
        uint256 jobId = _landTokenId * 100 + _slotId;
        Job memory job = JobsDictionary[msg.sender][jobId];

        if (job.completedTimeStamp > block.timestamp) {
            revert TooSoon();
        }

        if (job.completedTimeStamp == 0) {
            revert JobNotFound();
        }

        delete JobsDictionary[msg.sender][jobId];

        if (level != 10) {
            RawMaterialNftContract.mintRawMaterial(job.targetMaterial, 1, msg.sender);
            emit Claimed(msg.sender, jobId);
        } else {
            uint256 s_requestId = COORDINATOR.requestRandomWords(
                keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords
            );

            PlayerRequest[s_requestId] = Request(msg.sender, job.targetMaterial, uint32(jobId));
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        Request memory vrfRequest = PlayerRequest[requestId];

        uint256 dropChance = getSuccessChances(vrfRequest.requestedMaterial, vrfRequest.requestedMaterial);

        if (dropChance > (randomWords[0] % 100)) {
            RawMaterialNftContract.mintRawMaterial(vrfRequest.requestedMaterial, 2, vrfRequest.userAddress);
        } else {
            RawMaterialNftContract.mintRawMaterial(vrfRequest.requestedMaterial, 1, vrfRequest.userAddress);
        }
        emit Claimed(vrfRequest.userAddress, vrfRequest.jobId);

        delete PlayerRequest[requestId];
    }

    function determineCraftingTime(uint256 _level) internal pure override returns (uint256) {
        uint256 baseTime = 24 hours;

        if (_level == 2) {
            (baseTime -= 15 minutes);
        } else if (_level == 3) {
            (baseTime -= 30 minutes);
        } else if (_level == 4) {
            (baseTime -= 45 minutes);
        } else if (_level == 5) {
            (baseTime -= 60 minutes);
        } else if (_level == 6) {
            (baseTime -= 75 minutes);
        } else if (_level == 7) {
            (baseTime -= 90 minutes);
        } else if (_level == 8) {
            (baseTime -= 105 minutes);
        } else if (_level == 9) {
            (baseTime -= 120 minutes);
        } else if (_level == 10) {
            (baseTime -= 240 minutes);
        }

        return baseTime;
    }

    function getSuccessChances(uint256, uint256) internal pure override returns (uint256) {
        return 5;
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

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract VRFConsumerV2Ownable is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //address constant vrfCoordinatorFuji_ = 0x78a0D48cC87Ea0444e521475FCbE84A799090D75;
    // TODO REPLACE WITH THE ACTUAL FUJI COORDINATOR
    address constant vrfCoordinatorFuji_ = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 constant keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant callbackGasLimit = 300000;

    // The default is 3, but you can set this higher.
    uint16 constant requestConfirmations = 1;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant numWords = 1;

    event randomWordGenerated(uint256);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinatorFuji_) Ownable() {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorFuji_);
        s_subscriptionId = subscriptionId;
    }
}