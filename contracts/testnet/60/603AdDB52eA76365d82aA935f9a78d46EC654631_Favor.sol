// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

uint256 constant BASE = 10000;

contract Favor is IERC165, IERC1155, IERC1155MetadataURI {
    event Minted(bytes32 indexed groupID, uint256 indexed id, uint256 supply);
    event GroupAdded(bytes32 indexed groupID);
    event ManagerChanged(address from, address to);
    event CommissionChanged(uint256 from, uint256 to);

    struct Group {
        address[] members;
        uint256[] shares;
        uint256 total;
    }

    struct Token {
        mapping(address => uint256) balance;
        bytes32 groupID;
    }

    struct State {
        // Contract manager
        address manager;
        // Default commission
        uint256 commission;
        // MetadataURI pattern
        string metadataURI;
        // GroupID => Group
        mapping(bytes32 => Group) groups;
        // TokenID => Token
        mapping(uint256 => Token) tokens;
        // Account => Operator => Approved
        mapping(address => mapping(address => bool)) approvals;
    }

    State private state;

    modifier onlyManager() {
        require(msg.sender == state.manager, "only manager");
        _;
    }

    constructor(uint256 commission, string memory metadataURI) {
        state.manager = msg.sender;
        state.commission = commission;
        state.metadataURI = metadataURI;
    }

    function configure(
        address manager,
        uint256 commission,
        string calldata metadataURI
    ) external onlyManager {
        require(manager != address(0), "invalid manager");
        state.metadataURI = metadataURI;
        if (state.manager != manager) {
            state.manager = manager;
            emit ManagerChanged(state.manager, manager);
        }
        if (state.commission != commission) {
            state.commission = commission;
            emit CommissionChanged(state.commission, commission);
        }
    }

    function getGroup(bytes32 groupID) external view returns (Group memory) {
        return state.groups[groupID];
    }

    function getTokenGroup(uint256 id) external view returns (Group memory) {
        return state.groups[state.tokens[id].groupID];
    }

    function mint(
        uint256 id,
        address spender,
        address reciever,
        uint256 payment,
        IERC20 erc20,
        bytes32 groupID
    ) external onlyManager {
        _mint(id, spender, reciever, payment, erc20, groupID);
    }

    function mint(
        uint256 id,
        address spender,
        address reciever,
        uint256 payment,
        IERC20 erc20,
        address[] calldata members,
        uint256[] calldata shares
    ) external onlyManager {
        bytes32 groupID = _addGroup(members, shares);
        _mint(id, spender, reciever, payment, erc20, groupID);
    }

    function _mint(
        uint256 id,
        address spender,
        address reciever,
        uint256 payment,
        IERC20 erc20,
        bytes32 groupID
    ) internal {
        require(address(erc20) != address(0), "zero erc20");
        require(spender != address(0), "zero spender");
        Group storage group = state.groups[groupID];
        require(group.total > 0, "group not found");
        Token storage token = state.tokens[id];
        require(token.groupID == 0 || token.groupID == groupID, "wrong group");
        uint256 allowed = erc20.allowance(spender, address(this));
        require(allowed >= payment, "insufficient allowance");
        uint256 commission = (payment * state.commission) / BASE;
        if (commission > 0) {
            bool ok = erc20.transferFrom(spender, state.manager, commission);
            require(ok, "transfer failed");
            unchecked {
                payment -= commission;
            }
        }
        for (uint256 i = 0; i < group.members.length; ++i) {
            uint256 amount = (payment * group.shares[i]) / group.total;
            bool ok = erc20.transferFrom(spender, group.members[i], amount);
            require(ok, "transfer failed");
        }
        token.groupID = groupID;
        token.balance[reciever] = 1;
        emit Minted(groupID, id, 1);
        emit TransferSingle(spender, address(0), reciever, id, 1);
    }

    function _addGroup(address[] calldata members, uint256[] calldata shares)
        internal
        returns (bytes32)
    {
        require(members.length == shares.length, "unzippable");
        bytes32 groupID = keccak256(abi.encode(members, shares));
        Group storage group = state.groups[groupID];
        if (group.total == 0) {
            for (uint256 i = 0; i < members.length; ++i) {
                group.members.push(members[i]);
                group.shares.push(shares[i]);
                group.total += shares[i];
            }
            emit GroupAdded(groupID);
        }
        return groupID;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId;
    }

    function uri(uint256)
        external
        view
        override(IERC1155MetadataURI)
        returns (string memory)
    {
        return state.metadataURI;
    }

    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(IERC1155)
        returns (uint256)
    {
        require(account != address(0), "balance of zero");
        return state.tokens[id].balance[account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(IERC1155)
    {
        require(msg.sender != operator, "self approval");
        if (approved) {
            state.approvals[msg.sender][operator] = true;
        } else {
            delete state.approvals[msg.sender][operator];
        }
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override(IERC1155)
        returns (bool)
    {
        return state.approvals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(IERC1155) {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "requires owner/approved"
        );
        require(to != address(0), "transfer to the zero");
        Token storage token = state.tokens[id];
        uint256 balance = token.balance[from];
        require(balance >= amount, "insufficient balance");
        unchecked {
            token.balance[from] = balance - amount;
        }
        token.balance[to] += amount;
        _checkReceived(msg.sender, from, to, id, amount, data);
        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(IERC1155) {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "requires owner/approved"
        );
        require(ids.length == amounts.length, "length mismatch");
        require(to != address(0), "transfer to the zero");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            Token storage token = state.tokens[id];
            uint256 balance = token.balance[from];
            require(balance >= amount, "insufficient balance");
            unchecked {
                token.balance[from] = balance - amount;
            }
            token.balance[to] += amount;
        }
        _checkBatchReceived(msg.sender, from, to, ids, amounts, data);
        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function _checkReceived(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.code.length == 0) return;
        try
            IERC1155Receiver(to).onERC1155Received(
                operator,
                from,
                id,
                amount,
                data
            )
        returns (bytes4 response) {
            if (response != IERC1155Receiver.onERC1155Received.selector) {
                revert("tokens rejected");
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("to non ERC1155Receiver");
        }
    }

    function _checkBatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.code.length == 0) return;
        try
            IERC1155Receiver(to).onERC1155BatchReceived(
                operator,
                from,
                ids,
                amounts,
                data
            )
        returns (bytes4 response) {
            if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                revert("tokens rejected");
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("to non ERC1155Receiver");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    uint public unlockTime;
    address payable public owner;

    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) payable {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );

        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}