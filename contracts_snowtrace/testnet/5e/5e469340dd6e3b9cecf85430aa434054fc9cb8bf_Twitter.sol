/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Twitter {

    mapping (address => Account) accounts;
    mapping (address => bool) accountsCreated;
    mapping (address => mapping(uint => bool)) accountsLikes;
    mapping (uint => bool) tweetsIds;
    mapping (string => bool) nicknames;

    event NewTweet(Tweet);
    
    Tweet[] allTweets;

    struct Account {
        address owner;
        string nickname;
        address[] followings;
        uint[] tweets;
        mapping (address => bool) isFollowing;
        uint followersCount;
    }

    struct Tweet {
        address owner;
        uint id;
        string text;
        uint timestamp;
        address[] likes;
        uint[] comments;
        int retweetId;
    }

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
        require(!nicknames[_nickname], "The nickname is already taken");
        _;
    }

    modifier notEmpty(string memory _str, string memory metadata) {
        require(bytes(_str).length != 0, string(abi.encodePacked(metadata, " cannot be empty")));
        _;
    }

    function tweet(string memory _text) public accountExists(msg.sender) {
        writeTweet(_text, -1);
    }

    function writeTweet(string memory _text, int _retweetId) notEmpty(_text, "tweet") internal returns (uint) {
        uint id = allTweets.length;
        address[] memory likes;
        uint[] memory comments;
        Tweet memory _twit = Tweet(msg.sender, id, _text, block.timestamp, likes, comments, _retweetId);
        allTweets.push(_twit);
        accounts[msg.sender].tweets.push(id);
        tweetsIds[id] = true;
        emit NewTweet(_twit);
        return id;
    }

    function _getTweets(address owner) public accountExists(owner) view returns (uint[] memory) {
        return accounts[owner].tweets;
    }

    function _getTweetCount(address owner) public accountExists(owner) view returns (uint) {
        return accounts[owner].tweets.length;
    }

    function follow(address _addressToFollow) public accountExists(msg.sender) isNotFollowing(msg.sender, _addressToFollow) notSelf(msg.sender, _addressToFollow) accountExists(_addressToFollow) { 
        accounts[msg.sender].followings.push(_addressToFollow);
        accounts[msg.sender].isFollowing[_addressToFollow] = true;
        accounts[_addressToFollow].followersCount++;
    }

    function _getFollowings(address owner) public accountExists(owner) view returns (address[] memory) {
        return accounts[owner].followings;
    }

    function unfollow(address _addressToUnfollow, uint _followingId) public accountExists(msg.sender) accountExists(_addressToUnfollow) isFollowing(msg.sender, _addressToUnfollow) {
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

    function createAccount(string memory _nickname) public notEmpty(_nickname, "nickname") accountNotExists nicknameNotExists(_nickname) {
        Account storage newAccount = accounts[msg.sender];
        newAccount.owner = msg.sender;
        newAccount.nickname = _nickname;
        nicknames[_nickname] = true;
        accountsCreated[msg.sender] = true;
    }

    function _getTweet(uint _id) public view returns (address, uint, string memory, uint)  {
        Tweet storage _tweet = allTweets[_id];
        return (_tweet.owner, _tweet.id, _tweet.text, _tweet.timestamp);
    }

    function like(uint _tweetId) public accountExists(msg.sender) tweetExists(_tweetId) notLiked(_tweetId) {
        allTweets[_tweetId].likes.push(msg.sender);
        accountsLikes[msg.sender][_tweetId] = true;
    }

    function _getLikes(uint _tweetId) public tweetExists(_tweetId) view returns (uint) {
        return allTweets[_tweetId].likes.length;
    }

    function comment(uint _tweetId, string memory _text) notEmpty(_text, "comment") public accountExists(msg.sender) tweetExists(_tweetId) {
        uint id = writeTweet(_text, -1);
        allTweets[_tweetId].comments.push(id);
    }

    function _getComments(uint _tweetId) public tweetExists(_tweetId) view returns (uint[] memory) {
        uint[] memory comments = allTweets[_tweetId].comments;
        return comments;
    }

    function _getCommentsCount(uint _tweetId) public tweetExists(_tweetId) view returns (uint) {
        uint commentsCount= allTweets[_tweetId].comments.length;
        return commentsCount;
    }
    
    function retweet(uint _tweetId) public accountExists(msg.sender) tweetExists(_tweetId) {
        string memory _text = allTweets[_tweetId].text;
        writeTweet(_text, int(_tweetId));
    }

    function changeNickname(string memory _newNickname) public accountExists(msg.sender) notEmpty(_newNickname, "nickname") nicknameNotExists(_newNickname) {
        string memory _oldNickname = accounts[msg.sender].nickname;
        accounts[msg.sender].nickname = _newNickname;
        nicknames[_newNickname] = true;
        nicknames[_oldNickname] = false;
    }

    function _isNicknameAvailable(string memory _nickname) notEmpty(_nickname, "nickname") public view returns(bool) {
        return !nicknames[_nickname];
    }

    function _isAccountCreated(address _owner) public view returns (bool) {
        return accountsCreated[_owner];
    }

    function _likedTweet(uint _id, address _address) public accountExists(_address) tweetExists(_id) view returns (bool) {
        return accountsLikes[_address][_id];
    }

    function _getAccountNickname(address _owner) accountExists(_owner) public view returns(string memory) {
        return accounts[_owner].nickname;
    }

    function _getFollowersCount(address _owner) accountExists(_owner) public view returns(uint) {
        return accounts[_owner].followersCount;
    }
}