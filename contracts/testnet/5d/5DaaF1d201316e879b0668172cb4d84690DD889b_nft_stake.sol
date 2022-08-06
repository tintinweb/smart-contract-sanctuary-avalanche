library Array {
    function removeElement(uint256[] storage _array, uint256 _element) public {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}
/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-30
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC1155/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
 abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File contracts/nft_stake.sol


pragma solidity ^0.8.7;

pragma solidity ^0.8.7;


contract nft_stake {
    IERC1155 public parentNFT;
    uint256 public time = block.timestamp;
    uint256 public usersCount = 0;
    struct  NodeEntity {
    	address account;
    	uint256 timestamp;
        uint256 amount;
        uint256 tokenId;
        uint256 stake;
    	}
    struct Stake_1 {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }
    struct Stake_2 {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }
    struct Stake_3 {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => NodeEntity[]) public _nodesOfUser;
    mapping(address => Stake_1[]) public stakes_1;
    mapping(address => Stake_2[]) public stakes_2;
    mapping(address => Stake_3[]) public stakes_3;

    // map staker to total staking time
	
    mapping(address => uint256[]) public stakingTime_1;
    mapping(address => uint256[]) public stakingTime_2;
    mapping(address => uint256[]) public stakingTime_3; 
    
    constructor() {
        parentNFT = IERC1155(0x02EE497eB889605dca8800b44C404aBa9ae42D5a); // Change it to your NFT contract addr

	NodeEntity[] storage _nodes = _nodesOfUser[msg.sender];
    }
    
    function stake(uint256 _tokenId, uint256 _amount) public{
    	address _sender = msg.sender;
	NodeEntity[] storage _nodes = _nodesOfUser[msg.sender];



	
	
		
    	if (_tokenId == 1) {
    	NodeEntity storage _node = _nodes[usersCount];
		uint j;
        	while (j < _amount) {
        	_nodes.push(NodeEntity({account:msg.sender,timestamp: 0,amount:0,tokenId:0,stake:0}));
		 _node = _nodes[_nodes.length];
		_node.tokenId = 1;
		_node.amount += 1;
		_node.timestamp += block.timestamp;
		_node.stake +=1;
		usersCount++;
        	j++;
	}
	}
        if (_tokenId == 2) {
        	NodeEntity storage _node = _nodes[usersCount];
        	uint j;
          	while (j < _amount) {
        	_nodes.push(NodeEntity({account:msg.sender,timestamp: 0,amount:0,tokenId:0,stake:0}));
		 _node = _nodes[_nodes.length];
		_node.tokenId = 2;
		_node.amount += 1;
		_node.timestamp += block.timestamp;
		_node.stake +=1;
		usersCount++;
        	j++;
	}
	}
	
        if (_tokenId == 3) {
        	NodeEntity storage _node = _nodes[usersCount];
        	
        	uint j;
        	while (j < _amount) {
			_nodes.push(NodeEntity({account:msg.sender,timestamp: 0,amount:0,tokenId:0,stake:0}));
			 _node = _nodes[_nodes.length];
			_node.tokenId = 3;
			_node.amount += 1;
			_node.timestamp += block.timestamp;
			_node.stake +=1;
			usersCount++;
			j++;
	}
	
		
        }
	}
 
    
    function unstake(uint256 _tokenId, uint8 _amount) public {
    	address _sender = msg.sender;
    	NodeEntity[] storage _nodes = _nodesOfUser[msg.sender];

	    if (_tokenId == 1) {
	    NodeEntity storage _node = _nodes[0];
			uint j;
			while (j < _nodes.length  && _amount !=0) {
			if (_node.tokenId == 1){
				_node = _nodes[j];
				_node.amount -= 1;
				_node.timestamp = 0;
				_node.stake -= 1;
			   if (_node.amount == 0){
			    		delete _nodes[j];
			    	}
			    j++;
			}

		}
	}
		if (_tokenId == 2) {
		NodeEntity storage _node = _nodes[0];

			uint j;
			while (j < _nodes.length  && _amount !=0) {
			if (_node.tokenId == 2){
				_node = _nodes[j];
				_node.amount -= 1;
				_node.stake -=1;
			   if (_node.amount == 0){
			    		delete _nodes[j];
			    	}
			    j++;
			}

		}
	}
		if (_tokenId == 3) {
		NodeEntity storage _node = _nodes[0];

			uint j;
			while (j < _nodes.length  && _amount !=0) {
				if (_node.tokenId == 3 ){
					_node = _nodes[j];
					_node.amount -= 1;
					_node.stake -= 1;
				if (_node.amount == 0){
			    		delete _nodes[j];
			    	}
			    j++;
			}

		}
	}
	}
		
      
    
     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}