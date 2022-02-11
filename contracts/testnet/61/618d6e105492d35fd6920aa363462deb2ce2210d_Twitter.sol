// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ITwitteable.sol";

contract Twitter is ITwitteable {

    mapping (address => Types.Account) accounts;
    mapping (address => bool) accountsCreated;
    mapping (address => mapping(uint => bool)) accountsLikes;
    mapping (uint => bool) tweetsIds;
    mapping (string => address) nicknames;
    
    Types.Tweet[] allTweets;

    modifier accountNotExists() {
        require(!accountsCreated[msg.sender], "Twitter account already created");
        _;
    }

    modifier accountExists(address _owner) {
        require(accountsCreated[_owner], "Twitter account does not exists");
        _;
    }

    modifier isNotFollowing(address _sender, address _addressToFollow) {
        require(!accounts[_sender].isFollowing[_addressToFollow], "Address already followed");
        _;
    }

    modifier notSelf(address _sender, address _other) {
        require(_sender != _other, "Operation cannot be performed with self");
        _;
    }

    modifier isFollowing(address _sender, address _addressToFollow) {
        require(accounts[_sender].isFollowing[_addressToFollow], "Address not followed");
        _;
    }

    modifier notLiked(uint _tweetId) {
        require(!accountsLikes[msg.sender][_tweetId], "Tweet already liked");
        _;
    }

    modifier tweetExists(uint _tweetId) {
        require(tweetsIds[_tweetId], "The tweet does not exists");
        _;
    }

    modifier nicknameNotExists(string memory _nickname) {
        require(nicknames[_nickname] == address(0), "The nickname is already taken");
        _;
    }

    modifier notEmpty(string memory _str, string memory metadata) {
        require(bytes(_str).length != 0, string(abi.encodePacked(metadata, " cannot be empty")));
        _;
    }

    function tweet(string memory _text) external override accountExists(msg.sender) {
        uint id = writeTweet(_text, -1);
        emit TweetEvent(msg.sender, id, 0);
    }

    function writeTweet(string memory _text, int _retweetId) notEmpty(_text, "tweet") internal returns (uint) {
        uint id = allTweets.length;
        address[] memory likes;
        uint[] memory comments;
        Types.Tweet memory _twit = Types.Tweet(msg.sender, id, _text, block.timestamp, likes, comments, _retweetId);
        allTweets.push(_twit);
        accounts[msg.sender].tweets.push(id);
        tweetsIds[id] = true;
        return id;
    }

    function _getTweets(address owner) external override accountExists(owner) view returns (uint[] memory) {
        return accounts[owner].tweets;
    }

    function _getTweetCount(address owner) external override accountExists(owner) view returns (uint) {
        return accounts[owner].tweets.length;
    }

    function follow(address _addressToFollow) external override accountExists(msg.sender) isNotFollowing(msg.sender, _addressToFollow) notSelf(msg.sender, _addressToFollow) accountExists(_addressToFollow) { 
        accounts[msg.sender].followings.push(_addressToFollow);
        accounts[msg.sender].isFollowing[_addressToFollow] = true;
        accounts[_addressToFollow].followersCount++;
        emit FollowEvent(msg.sender, _addressToFollow);
    }

    function _getFollowings(address owner) external override accountExists(owner) view returns (address[] memory) {
        return accounts[owner].followings;
    }

    function unfollow(address _addressToUnfollow, uint _followingId) external override accountExists(msg.sender) accountExists(_addressToUnfollow) isFollowing(msg.sender, _addressToUnfollow) {
        accounts[msg.sender].isFollowing[_addressToUnfollow] = false;
        removeFollowing(_followingId);
        accounts[_addressToUnfollow].followersCount--;
    }

    function removeFollowing(uint _index) internal {
        uint len = accounts[msg.sender].followings.length;
        require(_index < len, "Invalid following id");
        accounts[msg.sender].followings[_index] = accounts[msg.sender].followings[len - 1];
        accounts[msg.sender].followings.pop();
    }

    function createAccount(string memory _nickname) external override notEmpty(_nickname, "nickname") accountNotExists nicknameNotExists(_nickname) {
        Types.Account storage newAccount = accounts[msg.sender];
        newAccount.owner = msg.sender;
        newAccount.nickname = _nickname;
        nicknames[_nickname] = msg.sender;
        accountsCreated[msg.sender] = true;
        emit AccountCreatedEvent(msg.sender, _nickname);
    }

    function _getTweet(uint _id) external override view returns (address, uint, string memory, uint)  {
        Types.Tweet storage _tweet = allTweets[_id];
        return (_tweet.owner, _tweet.id, _tweet.text, _tweet.timestamp);
    }

    function like(uint _tweetId) external override accountExists(msg.sender) tweetExists(_tweetId) notLiked(_tweetId) {
        Types.Tweet storage tw = allTweets[_tweetId];
        tw.likes.push(msg.sender);
        accountsLikes[msg.sender][_tweetId] = true;
        emit LikeEvent(msg.sender, tw.owner, _tweetId);
    }

    function _getLikes(uint _tweetId) external override tweetExists(_tweetId) view returns (uint) {
        return allTweets[_tweetId].likes.length;
    }

    function comment(uint _tweetId, string memory _text) notEmpty(_text, "comment") external override accountExists(msg.sender) tweetExists(_tweetId) {
        uint id = writeTweet(_text, -1);
        allTweets[_tweetId].comments.push(id);
        emit TweetEvent(msg.sender, id, 1);
    }

    function _getComments(uint _tweetId) external override tweetExists(_tweetId) view returns (uint[] memory) {
        uint[] memory comments = allTweets[_tweetId].comments;
        return comments;
    }

    function _getCommentsCount(uint _tweetId) external override tweetExists(_tweetId) view returns (uint) {
        uint commentsCount= allTweets[_tweetId].comments.length;
        return commentsCount;
    }
    
    function retweet(uint _tweetId) external override accountExists(msg.sender) tweetExists(_tweetId) {
        string memory _text = allTweets[_tweetId].text;
        uint id = writeTweet(_text, int(_tweetId));
        emit TweetEvent(msg.sender, id, 2);
    }

    function changeNickname(string memory _newNickname) external override accountExists(msg.sender) notEmpty(_newNickname, "nickname") nicknameNotExists(_newNickname) {
        string memory _oldNickname = accounts[msg.sender].nickname;
        accounts[msg.sender].nickname = _newNickname;
        nicknames[_newNickname] = msg.sender;
        nicknames[_oldNickname] = address(0);
    }

    function _isNicknameAvailable(string memory _nickname) notEmpty(_nickname, "nickname") external override view returns(bool) {
        return nicknames[_nickname] == address(0);
    }

    function _isAccountCreated(address _owner) external override view returns (bool) {
        return accountsCreated[_owner];
    }

    function _isTweetLiked(uint _id, address _address) external override accountExists(_address) tweetExists(_id) view returns (bool) {
        return accountsLikes[_address][_id];
    }

    function _getAccountNickname(address _owner) accountExists(_owner) external override view returns(string memory) {
        return accounts[_owner].nickname;
    }

    function _getFollowersCount(address _owner) accountExists(_owner) external override view returns(uint) {
        return accounts[_owner].followersCount;
    }

    function _getAddressForNickname(string memory _nickname) external override view returns(address) {
        return nicknames[_nickname];
    }
}