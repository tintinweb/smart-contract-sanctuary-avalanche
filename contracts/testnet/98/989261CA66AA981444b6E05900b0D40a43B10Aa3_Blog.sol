// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Blog {
    string private greeting;
    struct Post {
        uint id;
        string title;
        string content;
        uint upvotes;
        uint downvotes;
    }

    mapping(uint => Post) public posts;
    uint public postCount;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function createPost(string memory _title, string memory _content) public {
        postCount++;
        posts[postCount] = Post(postCount, _title, _content, 0, 0);
    }

    function upvotePost(uint _id) public {
        require(_id > 0 && _id <= postCount, "Invalid post ID.");
        posts[_id].upvotes++;
    }

    function downvotePost(uint _id) public {
        require(_id > 0 && _id <= postCount, "Invalid post ID.");
        posts[_id].downvotes++;
    }
}