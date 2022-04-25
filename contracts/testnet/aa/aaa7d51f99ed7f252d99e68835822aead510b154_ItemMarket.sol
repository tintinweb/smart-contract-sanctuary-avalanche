/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

interface IWAVAX {
    function withdraw(uint wad) external;
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
}

contract ItemMarket {

    ERC1155 immutable public itemContract;
    IWAVAX immutable public wavax;

    uint256 public orderIdCounter;

    //itemId => orders
    mapping (uint256 => Order[]) public orders;

    struct Order {
        uint128 pricePerItem;
        uint32 quantity;    
        uint32 deadline;    //will break in 2106
        uint32 id;
        bool isBid;         //true for bid, false for ask
        address caller;
    }

    constructor(address _itemContract, address _wavaxContract) {
        itemContract = ERC1155(_itemContract);
        wavax = IWAVAX(_wavaxContract);
    }

    event FilledBid(address indexed buyer, address indexed seller, uint256 indexed itemId, uint32 orderId, uint256 amountPaid, uint32 quantityFilled);
    event FilledAsk(address indexed buyer, address indexed seller, uint256 indexed itemId, uint32 orderId, uint256 amountPaid, uint32 quantityFilled);
    event NewOrder(uint256 indexed itemId, Order order);
    event CanceledOrder(uint256 indexed itemId, Order order);

    /**
      * @dev sender fills desired order. orderIndex is used to guarantee that between signing and finality the Order[] order has not changed
      * @param _itemId The item id of desired Item
      * @param _orderId order id of the Order to fill
      * @param _orderIndex used to guarantee accurate filling
      * @param _quantity amount to fill
      * @return Returns true if successfully filled. false if we had to cancel the order due to deadline
      */
    function fillOrder(
        uint256 _itemId, 
        uint32 _orderId, 
        uint256 _orderIndex, 
        uint32 _quantity
    ) payable external returns(bool) {
        require(_quantity > 0, "Must fill more than 0");

        Order memory order = orders[_itemId][_orderIndex];
        require(order.id == _orderId, "Order id different");

        require(order.quantity >= _quantity, "Order would be over-filled");

        if (block.timestamp > order.deadline) {
            //Refund user some gas for taking the L on deadline being passed
            //Also cleans up Order array
            removeOrder(_itemId, _orderIndex);
            return false;
        }

        //reverts on overflow
        uint256 totalPaid = order.pricePerItem * _quantity;

        address buyer = order.caller;  //the one with $
        address seller = msg.sender; //the one with item

        if (order.isBid) {
            //optional - gas benefit only if this isnt being checked on frontend
            require(wavax.allowance(buyer, address(this)) >= totalPaid, "WAVAX allowance too small");
            require(wavax.balanceOf(buyer) >= totalPaid, "WAVAX balance too small");
        } else {
            require(msg.value == totalPaid, "Value not correct");
            buyer = msg.sender;
            seller = order.caller;
        }

        require(itemContract.balanceOf(seller, _itemId) >= _quantity, "Seller cannot fill order");
        require(itemContract.isApprovedForAll(seller, address(this)), "Market needs Item allowance");

        //if we aren't deleting the order remove quantity sold
        if (order.quantity == _quantity) {
            removeOrder(_itemId, _orderIndex);
        } else {
            orders[_itemId][_orderIndex].quantity -= _quantity;
        }

        if (order.isBid) {
            //TODO: potentially find any asks by order caller and adjust

            //Get WAVAX from bidder
            wavax.transferFrom(order.caller, address(this), totalPaid);
            //Convert to AVAX
            wavax.withdraw(totalPaid);
            
            emit FilledBid(buyer, seller, _itemId, _orderId, totalPaid, _quantity);
        } else {
            emit FilledAsk(buyer, seller, _itemId, _orderId, totalPaid, _quantity);
        }

        //Transfer item(s) from seller to buyer
        itemContract.safeTransferFrom(seller, buyer, _itemId, _quantity, "");
        //Payout AVAX for the items
        payable(seller).transfer(totalPaid);

        return true;
    }

    /**
      * @dev Adds an order to the Order list
      * @param _itemId The item id of desired Item
      * @param _pricePerItem Price each item will be filled at
      * @param _quantity Amount to buy/sell
      * @param _deadline Deadline in epoch seconds
      * @param _isBid If true: is a bid (Buy Order) if false: is an ask (Sell Order)
      * @return order that was created
      */
    function addOrder(
        uint256 _itemId, 
        uint128 _pricePerItem, 
        uint32 _quantity, 
        uint32 _deadline, 
        bool _isBid
    ) external returns(Order memory) {

        if (_isBid) {
            uint256 paid = _pricePerItem*_quantity;
            require(wavax.balanceOf(msg.sender) >= paid, "Doesn't have wavax quantity");
            require(wavax.allowance(msg.sender, address(this)) >= paid, "WAVAX allowance too small");
        } else {
            require(itemContract.balanceOf(msg.sender, _itemId) >= _quantity, "Doesn't have item quantity");
            require(itemContract.isApprovedForAll(msg.sender, address(this)), "Market needs Item allowance");
        }

        //inc order ids so we have unique ids
        uint32 _orderId = uint32(orderIdCounter++);

        Order memory order;
        order.pricePerItem = _pricePerItem;
        order.quantity = _quantity;
        order.deadline = _deadline;
        order.caller = msg.sender;
        order.id = _orderId;
        order.isBid = _isBid;

        orders[_itemId].push(order);

        emit NewOrder(_itemId, order);
        
        return order;
    }

    /**
      * @dev cancels order if caller is order owner. 
      * @param _itemId Item id of order
      * @param _orderId Order id to cancel
      * @param _orderIndex index of the order in the Order[]
      */
    function cancelOrder(
        uint256 _itemId, 
        uint32 _orderId, 
        uint256 _orderIndex
    ) public {
        Order memory _foundOrder = orders[_itemId][_orderIndex];

        require(_foundOrder.id == _orderId, "Order id changed");
        require(_foundOrder.caller == msg.sender, "Not order owner");

        removeOrder(_itemId, _orderIndex);

        emit CanceledOrder(_itemId, _foundOrder);
    }

    function removeOrder(
        uint256 _itemId, 
        uint256 _index
    ) internal {
        uint256 len = orders[_itemId].length;
        require(_index < len, "Invalid index");
        // Move the last element into the place to delete
        orders[_itemId][_index] = orders[_itemId][len - 1];
        // Remove the last element
        orders[_itemId].pop();
    }


    /*
      VIEW
    */

    /**
      * @dev not very gas efficient, orders should be found using getOrders()
      */
    function getOrder(
        uint256 _itemId, 
        uint32 _orderId
    ) external view returns(uint, Order memory) {
        require(_orderId != 0, "Invalid order");
        Order[] memory _orders = orders[_itemId];
        uint256 len = orders[_itemId].length;

        for (uint i=0; i<len; i++) {
            Order memory _order = _orders[i];
            if (_order.id == _orderId) return (i, _order);
        }

        revert("Order not found");
    }

    /**
      * @dev Returns all Orders for a certain item id
      */
    function getOrders(
        uint256 _itemId
    ) external view returns(Order[] memory) {
        return orders[_itemId];
    }

    receive() external payable {}

}