// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



contract Blogpost {
    struct Post {
        string title;
        string content;
        address author;
    }

    Post[] public posts;

    function createPost(string memory _title, string memory _content) public {
        Post memory newPost = Post({
            title: _title,
            content: _content,
            author: msg.sender
        });
        posts.push(newPost);
    }

    function getAllPosts() public view returns (Post[] memory) {
        return posts;
    }
}