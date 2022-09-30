/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract Bookmark {

    address private constant MARKET = 0x20D46d105104AFba67190061FFb71aa2aDDF2614;

    struct Bookmarks {
        uint[] ordersId;
        mapping (uint => bool) orderStatus;
        mapping (uint => uint) orderIndex;
    }

    mapping (address => Bookmarks) private bookmarks;

    function addBookmark(uint _orderId) external {
        require(bookmarks[msg.sender].orderStatus[_orderId] == false, "order alreay bookmarked!");
        (bool result, bytes memory data) = MARKET.call(abi.encodeWithSignature(
            "totalOrdersCount()"
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

        bookmarks[msg.sender].ordersId[bookmarks[msg.sender].orderIndex[_orderId]] =  bookmarks[msg.sender].ordersId[(bookmarks[msg.sender].ordersId).length - 1];
        bookmarks[msg.sender].ordersId.pop();
        
        delete bookmarks[msg.sender].orderStatus[_orderId];
        delete bookmarks[msg.sender].orderIndex[_orderId];
    }
    
    function getBookmarksId(address _user) external view returns(uint[] memory) {
        return bookmarks[_user].ordersId;
    }

    function getBookmarkStatus(
        address _user,
        uint _orderId
    ) external view returns(bool) {
        return bookmarks[_user].orderStatus[_orderId];
    }

}