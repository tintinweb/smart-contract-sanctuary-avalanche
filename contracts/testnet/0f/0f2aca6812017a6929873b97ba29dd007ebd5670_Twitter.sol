/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

library Types {
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
        TweetType tweetType;
        string text;
        uint timestamp;
        address[] likes;
        uint[] comments;
        int retweetId;
    }

    enum TweetType {
        Tweet,
        Comment,
        Retweet
    }
}

interface ITwitteable {

    event AccountCreatedEvent(
        address from,
        string nickname
    );
    
    /**
     * @notice Emits when a user tweets, comment or retweet
     */
    event TweetEvent(
        address from,
        uint tweetId,
        Types.TweetType tweetType
    );

    event LikeEvent(
        address from,
        address owner,
        uint tweetId
    );

    event FollowEvent(
        address from,
        address to
    );

    error EmptyStringError();
    error NickNameAlreadyTakenError();
    error UnexistentTweetError();
    error TweetAlreadyLikedError();
    error AddressNotFollowedError();
    error SelfOperationError();
    error AlreadyFollowedError();
    error UnexistentAccountError();
    error AccountAlreadyCreatedError();

    function tweet(string memory _text) external;

    function _getTweets(address owner) 
        external 
        view 
        returns (uint[] memory);

    function _getTweetCount(address owner) 
        external  
        view 
        returns (uint);

    function follow(address _addressToFollow) external;

    function _getFollowings(address owner) 
        external 
        view 
        returns (address[] memory);

    function unfollow(address _addressToUnfollow, uint _followingId) external;

    function createAccount(string calldata _nickname) external;

    function _getTweet(uint _id) 
        external 
        view 
        returns (
            address, 
            uint, 
            string memory, 
            uint,
            Types.TweetType
        );

    function like(uint _tweetId) external;

    function _getLikes(uint _tweetId) 
        external 
        view 
        returns (uint);

    function comment(uint _tweetId, string memory _text) external;

    function _getComments(uint _tweetId) 
        external 
        view 
        returns (uint[] memory);

    function _getCommentsCount(uint _tweetId) 
        external 
        view 
        returns (uint);
    
    function retweet(uint _tweetId) external;

    function changeNickname(string calldata _newNickname) external;

    function _isNicknameAvailable(string calldata _nickname) 
        external 
        view 
        returns(bool);

    function _isAccountCreated(address _owner) 
        external 
        view 
        returns (bool);

    function _isTweetLiked(uint _id, address _address) 
        external 
        view 
        returns (bool);

    function _getAccountNickname(address _owner) 
        external 
        view 
        returns(string memory);

    function _getFollowersCount(address _owner) 
        external 
        view 
        returns(uint);

    function _getAddressForNickname(string calldata _nickname) 
        external 
        view 
        returns(address);
}
    

contract Twitter is ITwitteable {

    /* ========== STATE VARIABLES ========== */

    mapping (address => Types.Account) private _accounts;
    mapping (address => bool) private _accountsCreated;
    mapping (address => mapping(uint => bool)) private _accountsLikes;
    mapping (uint => bool) private _tweetsIds;
    mapping (string => address) private _nicknames;
    
    Types.Tweet[] private allTweets;

    function tweet(string memory _text) 
        external 
        override 
        accountExists(msg.sender) 
    {
        uint id = writeTweet({
            _text: _text, 
            _retweetId: -1, 
            _tweetType: Types.TweetType.Tweet
        });
        emit TweetEvent({
            from: msg.sender, 
            tweetId: id, 
            tweetType: Types.TweetType.Tweet
        });
    }

    function writeTweet(string memory _text, int _retweetId, Types.TweetType _tweetType)
        internal
        notEmpty(_text, "tweet") 
        returns (uint) 
    {
        uint id = allTweets.length;
        address[] memory likes;
        uint[] memory comments;
        Types.Tweet memory _twit = Types.Tweet({
            owner: msg.sender, 
            id: id, 
            tweetType: _tweetType, 
            text: _text, 
            timestamp: block.timestamp, 
            likes: likes, 
            comments: comments, 
            retweetId: _retweetId
        });
        allTweets.push(_twit);
        _accounts[msg.sender].tweets.push(id);
        _tweetsIds[id] = true;
        return id;
    }

    function _getTweets(address owner) 
        external 
        override 
        accountExists(owner) 
        view 
        returns (uint[] memory) 
    {
        return _accounts[owner].tweets;
    }

    function _getTweetCount(address owner) 
        external 
        override 
        accountExists(owner) 
        view 
        returns (uint) 
    {
        return _accounts[owner].tweets.length;
    }

    function follow(address _addressToFollow) 
        external 
        override 
        accountExists(msg.sender) 
        notFollowing(msg.sender, _addressToFollow) 
        notSelf(msg.sender, _addressToFollow) 
        accountExists(_addressToFollow) 
    { 
        _accounts[msg.sender].followings.push(_addressToFollow);
        _accounts[msg.sender].isFollowing[_addressToFollow] = true;
        _accounts[_addressToFollow].followersCount++;
        emit FollowEvent(msg.sender, _addressToFollow);
    }

    function _getFollowings(address owner) 
        external 
        override 
        accountExists(owner) 
        view 
        returns (address[] memory) 
    {
        return _accounts[owner].followings;
    }

    function unfollow(address _addressToUnfollow, uint _followingId) 
        external 
        override 
        accountExists(msg.sender) 
        accountExists(_addressToUnfollow) 
        isFollowing(msg.sender, _addressToUnfollow)
    {
        _accounts[msg.sender].isFollowing[_addressToUnfollow] = false;
        removeFollowing(_followingId);
        _accounts[_addressToUnfollow].followersCount--;
    }

    function removeFollowing(uint _index) 
        internal 
    {
        uint len = _accounts[msg.sender].followings.length;
        require(_index < len, "Invalid following id");
        _accounts[msg.sender].followings[_index] = _accounts[msg.sender].followings[len - 1];
        _accounts[msg.sender].followings.pop();
    }

    function createAccount(string calldata _nickname) 
        external 
        override 
        notEmpty(_nickname, "nickname") 
        accountNotExists 
        nicknameNotExists(_nickname) 
    {
        Types.Account storage newAccount = _accounts[msg.sender];
        newAccount.owner = msg.sender;
        newAccount.nickname = _nickname;
        _nicknames[_nickname] = msg.sender;
        _accountsCreated[msg.sender] = true;
        emit AccountCreatedEvent(msg.sender, _nickname);
    }

    function _getTweet(uint _id) 
        external 
        override 
        view 
        returns (
            address, 
            uint, 
            string memory, 
            uint,
            Types.TweetType
        )  
    {
        Types.Tweet storage _tweet = allTweets[_id];
        return (_tweet.owner, _tweet.id, _tweet.text, _tweet.timestamp, _tweet.tweetType);
    }

    function like(uint _tweetId) 
        external 
        override 
        accountExists(msg.sender) 
        tweetExists(_tweetId) 
        notLiked(_tweetId) 
    {
        Types.Tweet storage tw = allTweets[_tweetId];
        tw.likes.push(msg.sender);
        _accountsLikes[msg.sender][_tweetId] = true;
        emit LikeEvent(msg.sender, tw.owner, _tweetId);
    }

    function _getLikes(uint _tweetId) 
        external 
        override 
        tweetExists(_tweetId) 
        view 
        returns (uint) 
    {
        return allTweets[_tweetId].likes.length;
    }

    function comment(uint _tweetId, string memory _text)
        external
        override 
        notEmpty(_text, "comment") 
        accountExists(msg.sender) 
        tweetExists(_tweetId) 
    {
        uint id = writeTweet({
            _text: _text, 
            _retweetId: -1, 
            _tweetType: Types.TweetType.Comment
        });
        allTweets[_tweetId].comments.push(id);
        emit TweetEvent({
            from: msg.sender, 
            tweetId: id, 
            tweetType: Types.TweetType.Comment
        });
    }

    function _getComments(uint _tweetId) 
        external 
        override 
        tweetExists(_tweetId) 
        view 
        returns (uint[] memory) 
    {
        uint[] memory comments = allTweets[_tweetId].comments;
        return comments;
    }

    function _getCommentsCount(uint _tweetId) 
        external 
        override 
        tweetExists(_tweetId) 
        view 
        returns (uint) 
    {
        uint commentsCount = allTweets[_tweetId].comments.length;
        return commentsCount;
    }
    
    function retweet(uint _tweetId) 
        external 
        override 
        accountExists(msg.sender) 
        tweetExists(_tweetId) 
    {
        string memory _text = allTweets[_tweetId].text;
        uint id = writeTweet({
            _text: _text, 
            _retweetId: int(_tweetId), 
            _tweetType: Types.TweetType.Retweet
        });
        emit TweetEvent({
            from: msg.sender, 
            tweetId: id, 
            tweetType: Types.TweetType.Retweet
        });
    }

    function changeNickname(string calldata _newNickname) 
        external
        override 
        accountExists(msg.sender) 
        notEmpty(_newNickname, "nickname") 
        nicknameNotExists(_newNickname) 
    {
        string memory _oldNickname = _accounts[msg.sender].nickname;
        _accounts[msg.sender].nickname = _newNickname;
        _nicknames[_newNickname] = msg.sender;
        _nicknames[_oldNickname] = address(0);
    }

    function _isNicknameAvailable(string calldata _nickname)
        external
        override 
        view 
        notEmpty(_nickname, "nickname")
        returns(bool) 
    {
        return _nicknames[_nickname] == address(0);
    }

    function _isAccountCreated(address _owner) 
        external 
        override 
        view 
        returns (bool) 
    {
        return _accountsCreated[_owner];
    }

    function _isTweetLiked(uint _id, address _address) 
        external
        override
        view
        accountExists(_address)
        tweetExists(_id)
        returns (bool) 
    {
        return _accountsLikes[_address][_id];
    }

    function _getAccountNickname(address _owner)
        external
        override 
        view
        accountExists(_owner)
        returns(string memory) 
    {
        return _accounts[_owner].nickname;
    }

    function _getFollowersCount(address _owner)
        external
        override 
        view
        accountExists(_owner) 
        returns(uint) 
    {
        return _accounts[_owner].followersCount;
    }

    function _getAddressForNickname(string calldata _nickname) 
        external 
        override 
        view 
        returns(address) 
    {
        return _nicknames[_nickname];
    }

    /* ========== MODIFIERS ========== */
    
    modifier accountNotExists() {
        if (_accountsCreated[msg.sender]) revert AccountAlreadyCreatedError();
        _;
    }

    modifier accountExists(address _owner) {
        if (!_accountsCreated[_owner]) revert UnexistentAccountError();
        _;
    }

    modifier notFollowing(address _sender, address _addressToFollow) {
        if (_accounts[_sender].isFollowing[_addressToFollow]) revert AlreadyFollowedError();
        _;
    }

    modifier notSelf(address _sender, address _other) {
        if (_sender == _other) revert SelfOperationError();
        _;
    }

    modifier isFollowing(address _sender, address _addressToFollow) {
        if (!_accounts[_sender].isFollowing[_addressToFollow]) revert AddressNotFollowedError();
        _;
    }

    modifier notLiked(uint _tweetId) {
        if (_accountsLikes[msg.sender][_tweetId]) revert TweetAlreadyLikedError();
        _;
    }

    modifier tweetExists(uint _tweetId) {
        if (!_tweetsIds[_tweetId]) revert UnexistentTweetError();
        _;
    }

    modifier nicknameNotExists(string calldata _nickname) {
        if (_nicknames[_nickname] != address(0)) revert NickNameAlreadyTakenError();
        _;
    }

    modifier notEmpty(string memory _str, string memory metadata) {
        if (bytes(_str).length == 0) revert EmptyStringError();
        _;
    }
}