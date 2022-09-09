/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

contract Bookmark {

    address private constant MARKET = 0x3037dDEB99Ec8164cea4D8fe0DD652dFb3B9BF3b;

    struct Bookmarks {
        uint[] ordersId;
        mapping (uint => bool) orderStatus;
        mapping (uint => uint) orderIndex;
    }

    mapping (address => Bookmarks) private bookmarks;

    function addBookmark(uint _orderId) external {
        require(bookmarks[msg.sender].orderStatus[_orderId] == false, "order alreay bookmarked!");
        (bool result, bytes memory data) = MARKET.call(abi.encodeWithSignature(
            "totalERC721OrdersCount()"
        ));
        require(result == true, "error.");
        uint amount = abi.decode(data, (uint));
        require(_orderId > 0 && _orderId <= amount, "invalid order id.");

        bookmarks[msg.sender].orderIndex[_orderId] = bookmarks[msg.sender].ordersId.length;
        bookmarks[msg.sender].ordersId.push(_orderId);
        bookmarks[msg.sender].orderStatus[_orderId] = true;
    }

    function deleteBookmark(uint _orderId) external {
        require(bookmarks[msg.sender].orderStatus[_orderId] == true, "nothing found to delete!");

        delete bookmarks[msg.sender].orderStatus[_orderId];
        delete bookmarks[msg.sender].ordersId[bookmarks[msg.sender].orderIndex[_orderId]];
        delete bookmarks[msg.sender].orderIndex[_orderId];
    }
    
    function getBookmarksId() external view returns(uint[] memory) {
        return bookmarks[msg.sender].ordersId;
    }

    function getBookmarkStatus(uint _orderId) external view returns(bool) {
        return bookmarks[msg.sender].orderStatus[_orderId];
    }

}