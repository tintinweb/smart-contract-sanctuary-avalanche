// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";

struct OrderInfo {
    uint256 orderId; // incrementing uint256 starting from 0
    uint256 orderType; // 1: sale order, 2: auction order
    uint256 orderState; // 1: open, 2: filled, 3: cancelled
    uint256 tokenId;
    address quoteToken;
    uint256 price;
    uint256 endTime;
    address seller;
    address buyer;
    uint256 bids;
    address lastBidder;
    uint256 lastBid;
    uint256 createTime;
    uint256 updateTime;
}

contract Marketplace {
    using Address for address;
    using SafeMath for uint256;

    address private nftAddress;
    bytes internal constant MARKET_DATA = bytes("Roiland Market");

    OrderInfo[] internal orders;
    uint256[] internal openOrders;
    mapping(uint256 => uint256) internal openOrderToIndex;

    event OrderForSale(address _seller, uint256 indexed _orderId, uint256 indexed _tokenId, address indexed _quoteToken, uint256 _price);
    event OrderForAuction(address _seller, uint256 indexed _orderId, uint256 indexed _tokenId, address indexed _quoteToken, uint256 _price, uint256 _endTime);
    event OrderBid(address indexed _seller, address indexed _buyer, uint256 indexed _orderId, uint256 _price);
    event OrderFilled(address _seller, address indexed _buyer, uint256 indexed _orderId, address indexed _quoteToken, uint256 _price);
    event OrderCancelled(address indexed _seller, uint256 indexed _orderId);
    event OrderPriceChanged(address indexed _seller, uint256 indexed _orderId, uint256 _oldPrice, uint256 _newPrice);
    event ERC721TokenReceived(address indexed _operator, address indexed _from, address indexed _tokenAddress, uint256 _tokenId, bytes _data);
    
    function createOrderForSale(uint256 _tokenId, address _quoteToken, uint256 _price) external returns (uint256) {
        require(_price > 0, "price cannot be zero");
        require(_quoteToken == address(0) || _quoteToken.isContract(), "invalid address for quote token");
        require(!msg.sender.isContract(), "caller must be external wallet");

        uint256 orderId = _createOrder(1, _tokenId, _quoteToken, _price, 0);
        emit OrderForSale(msg.sender, orderId, _tokenId, _quoteToken, _price);

        return orderId;
    }

    function createOrderForAuction(uint256 _tokenId, address _quoteToken, uint256 _price, uint256 _endTime) external returns (uint256) {
        require(_price > 0, "price cannot be zero");
        require(_endTime > block.timestamp, "end time cannot be in the past");
        require(_quoteToken == address(0) || _quoteToken.isContract(), "invalid address for quote token");
        require(!msg.sender.isContract(), "caller must be external wallet");

        uint256 orderId = _createOrder(2, _tokenId, _quoteToken, _price, _endTime);
        emit OrderForAuction(msg.sender, orderId, _tokenId, _quoteToken, _price, _endTime);

        return orderId;
    }

    function buyForOrder(uint256 _orderId) external payable {
        require(orders[_orderId].orderType == 1 && orders[_orderId].orderState == 1, "invalid order");
        require(!msg.sender.isContract(), "caller must be external wallet");

        _buyForOrder(_orderId);
    }

    function bidForOrder(uint256 _orderId, uint256 _value) external payable {
        require(orders[_orderId].orderType == 2 && orders[_orderId].orderState == 1, "invalid order");
        require(orders[_orderId].endTime > block.timestamp && _value >= orders[_orderId].price && _value > orders[_orderId].lastBid, "invalid bid");
        require(!msg.sender.isContract(), "caller must be external wallet");

        _bidForOrder(_orderId, _value);
    }

    function cancelOrder(uint256 _orderId) external {
        require(orders[_orderId].orderState == 1, "invalid order state");
        require(msg.sender == orders[_orderId].seller, "caller is not the seller");

        _cancelOrder(_orderId);
    }

    function chanageOrderPrice(uint256 _orderId, uint256 _price) external {
        require(orders[_orderId].orderState == 1, "invalid order state");
        require(msg.sender == orders[_orderId].seller, "caller is not the seller");

        if(orders[_orderId].orderType == 2) {
            require(orders[_orderId].lastBidder == address(0) && orders[_orderId].endTime > block.timestamp, "cannot change auction price");
        }

        uint256 oldPrice = orders[_orderId].price;
        orders[_orderId].price = _price;
        orders[_orderId].updateTime = block.timestamp;

        emit OrderPriceChanged(msg.sender, _orderId, oldPrice, _price);
    }

    function settleOrderForAuction(uint256 _orderId) external payable {
        require(orders[_orderId].orderType == 2 && orders[_orderId].endTime < block.timestamp, "invalid order");

        _settleOrderForAuction(_orderId);
    }

    function _createOrder(uint256 _orderType, uint256 _tokenId, address _quoteToken, uint256 _price, uint256 _endTime) internal returns (uint256) {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId, MARKET_DATA);

        OrderInfo memory newOrder;
        newOrder.orderId = orders.length;
        newOrder.orderType = _orderType;
        newOrder.orderState = 1;
        newOrder.tokenId = _tokenId;
        newOrder.quoteToken = _quoteToken;
        newOrder.price = _price;
        newOrder.endTime = _endTime;
        newOrder.seller = msg.sender;
        newOrder.createTime = block.timestamp;
        newOrder.updateTime = block.timestamp;
        
        orders.push(newOrder);
        openOrderToIndex[newOrder.orderId] = openOrders.length;
        openOrders.push(newOrder.orderId);

        return newOrder.orderId;
    }

    function _cancelOrder(uint256 _orderId) internal {
        if(orders[_orderId].orderType == 2) {
            require(orders[_orderId].lastBidder == address(0), "cannot cancel auction order");
        }

        orders[_orderId].orderState = 3;
        orders[_orderId].updateTime = block.timestamp;
        if(openOrderToIndex[_orderId] != openOrders.length.sub(1)) {
            uint256 index = openOrderToIndex[_orderId];
            openOrders[index] = openOrders[openOrders.length.sub(1)];
            openOrderToIndex[openOrders[index]] = index;
        }
        openOrderToIndex[_orderId] = 0;
        openOrders.pop();

        emit OrderCancelled(orders[_orderId].seller, _orderId);
    }

    function _buyForOrder(uint256 _orderId) internal {
        if(orders[_orderId].quoteToken == address(0)) {
            require(msg.value == orders[_orderId].price, "invalid msg value for eth");
        } else {
            require(msg.value == 0, "invalid msg value for token");
            uint256 beforeBalance = IERC20(orders[_orderId].quoteToken).balanceOf(address(this));
            require(IERC20(orders[_orderId].quoteToken).transferFrom(msg.sender, address(this), orders[_orderId].price), "token transfer failed");
            require(IERC20(orders[_orderId].quoteToken).balanceOf(address(this)).sub(beforeBalance) == orders[_orderId].price, "non-standard ERC20 token not supported");
        }

        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, orders[_orderId].tokenId, MARKET_DATA);

        orders[_orderId].orderState = 2;
        orders[_orderId].buyer = msg.sender;
        orders[_orderId].updateTime = block.timestamp;
        if(openOrderToIndex[_orderId] != openOrders.length.sub(1)) {
            uint256 index = openOrderToIndex[_orderId];
            openOrders[index] = openOrders[openOrders.length.sub(1)];
            openOrderToIndex[openOrders[index]] = index;
        }
        openOrderToIndex[_orderId] = 0;
        openOrders.pop();

        emit OrderFilled(orders[_orderId].seller, orders[_orderId].buyer, _orderId, orders[_orderId].quoteToken, orders[_orderId].price);
    }

    function _bidForOrder(uint256 _orderId, uint256 _value) internal {
        if(orders[_orderId].quoteToken == address(0)) {
            require(msg.value == _value, "invalid msg value for eth");
        } else {
            require(msg.value == 0, "invalid msg value for token");
            uint256 beforeBalance = IERC20(orders[_orderId].quoteToken).balanceOf(address(this));
            require(IERC20(orders[_orderId].quoteToken).transferFrom(msg.sender, address(this), _value), "token transfer failed");
            require(IERC20(orders[_orderId].quoteToken).balanceOf(address(this)).sub(beforeBalance) == _value, "non-standard ERC20 token not supported");
        }

        if(orders[_orderId].lastBidder != address(0)) {
            if(orders[_orderId].quoteToken == address(0)) {
                (bool success, ) = payable(orders[_orderId].lastBidder).call{ value: orders[_orderId].lastBid }("");
                require(success, "eth refund failed in auction");
            } else {
                require(IERC20(orders[_orderId].quoteToken).transfer(orders[_orderId].lastBidder, orders[_orderId].lastBid), "token refund failed in auction");
            }
        }

        orders[_orderId].lastBidder = msg.sender;
        orders[_orderId].lastBid = _value;
        orders[_orderId].bids = orders[_orderId].bids.add(1);
        orders[_orderId].updateTime = block.timestamp;

        emit OrderBid(orders[_orderId].seller, msg.sender, _orderId, _value);
    }

    function _settleOrderForAuction(uint256 _orderId) internal {
        if(orders[_orderId].lastBidder == address(0)) {
            _cancelOrder(_orderId);
        } else {
            IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, orders[_orderId].tokenId, MARKET_DATA);

            orders[_orderId].orderState = 2;
            orders[_orderId].buyer = msg.sender;
            orders[_orderId].updateTime = block.timestamp;
            if(openOrderToIndex[_orderId] != openOrders.length.sub(1)) {
                uint256 index = openOrderToIndex[_orderId];
                openOrders[index] = openOrders[openOrders.length.sub(1)];
                openOrderToIndex[openOrders[index]] = index;
            }
            openOrderToIndex[_orderId] = 0;
            openOrders.pop();

            emit OrderFilled(orders[_orderId].seller, orders[_orderId].buyer, _orderId, orders[_orderId].quoteToken, orders[_orderId].price);
        }
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4) {
        emit ERC721TokenReceived(_operator, _from, msg.sender, _tokenId, _data);
        return this.onERC721Received.selector;
    }
}