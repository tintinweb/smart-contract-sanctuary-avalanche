/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract gasTest{
    struct Post{
        int256 post_id;
        string content;
        address wallet_address;
    }

    int256 p_count = 1;

    Post[] public post ; 

    function postadd(string memory content) public {
        address check = msg.sender;
        post.push(Post(p_count, content, check));
        p_count = p_count+1;
    }

    function TotalCount() public view returns(int256) {
            return p_count;
        }
}