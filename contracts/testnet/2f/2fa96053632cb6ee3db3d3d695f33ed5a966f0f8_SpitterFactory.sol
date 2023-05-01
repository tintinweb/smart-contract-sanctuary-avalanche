// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./lib/StringUtils.sol";

contract SpitterENS {
    mapping(bytes32 => address) public registered;

    function registerName(string memory name) external {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        require(registered[nameHash] == address(0), "name registered");
        require(StringUtils.strlen(name) <= 30, "len");
        registered[nameHash] = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SpitterServer.sol";

contract SpitterFactory {
    address public immutable ens;
    mapping(bytes32 => Server) private _serverHashes;
    Server[] private _allServers;

    struct Server {
        string name;
        address contractAddress;
        bool isWhitelisted;
        bool isBlackisted;
        address admin;
    }

    constructor(address _ens) {
        ens = _ens;
    }

    function getAllServers() public view returns(Server[] memory){
        return _allServers;
    }

    function createServer(Server memory serverSettings) external returns (address newServer) {
        bytes32 salt_ = keccak256(abi.encodePacked(serverSettings.name));
        require(_serverHashes[salt_].contractAddress == address(0), "name used");

        if (serverSettings.isBlackisted || serverSettings.isWhitelisted) {
            require(serverSettings.admin != address(0), "not admin");
        }
        newServer = address(
            new SpitterServer{salt : salt_}(
            serverSettings.isWhitelisted,
            serverSettings.isBlackisted,
            serverSettings.admin,
            ens
            )
        );
        serverSettings.contractAddress = newServer;
        _allServers.push(serverSettings);
        _serverHashes[salt_] = serverSettings;
    }

    function getServerByName(string memory name) external view returns (Server memory) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        return _serverHashes[nameHash];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SpitterENS.sol";
import "./lib/StringUtils.sol";

contract SpitterServer {
    event SetAccount(address indexed account);
    event Post(address indexed account, uint256 indexed postId);
    event Like(address indexed account, uint256 indexed postId);
    event LikeResponse(address indexed account, uint256 indexed postId, uint256 indexed responseId);
    event Respond(address indexed account, uint256 indexed postId);
    event Follow(address indexed account, address indexed followed);

    bool public immutable isWhitelisted;
    bool public immutable isBlacklisted;
    address public admin;
    SpitterENS public immutable ens;
    address public immutable factory;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    mapping(address => Account) private _accounts;
    mapping(address => mapping(address => bool)) private _followed;
    mapping(uint256 => Response[]) private _responses;

    Publication[] private _feed;
    uint256 private _feedLength;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyAccount() {
        require(_accounts[msg.sender].user != address(0), "only account");
        _;
    }

    modifier addressWhitelisted() {
        if (isWhitelisted) {
            require(whitelist[msg.sender], "not in whitelist");
        }
        _;
    }

    modifier addressNotBlackListed() {
        if (isBlacklisted) {
            require(!blacklist[msg.sender], "in blacklist");
        }
        _;
    }

    struct Account {
        address user;
        string profilePic;
        string name;
        string description;
        address[] followers;
        address[] followed;
        uint128 followersCount;
        uint128 followedCount;
        uint256[] posts;
        bool verified;
    }

    struct Publication {
        uint256 id;
        address user;
        uint64 timestamp;
        string text;
        uint96 likes;
        uint96 responsesCount;
    }

    struct Response {
        address user;
        uint256 id;
        uint64 timestamp;
        string text;
        uint96 likes;
    }

    constructor(bool _isWhitelisted, bool _isBlacklisted, address _admin, address _ens) {
        isWhitelisted = _isWhitelisted;
        isBlacklisted = _isBlacklisted;
        admin = _admin;
        factory = msg.sender;
        ens = SpitterENS(_ens);
        whitelist[admin] = true;
    }

    function responses(uint256 postId) external view returns (Response[] memory) {
        return _responses[postId];
    }

    function accounts(address user) public view returns (Account memory) {
        return _accounts[user];
    }

    function feed() external view returns (Publication[] memory feed_) {
        feed_ = _feed;
    }

    function whitelistAddress(address user) external onlyAdmin {
        require(user != msg.sender, "invalid addr");
        require(isWhitelisted, "server not whitelisted");
        whitelist[user] = true;
    }

    function blacklistAddress(address user) external onlyAdmin {
        require(user != msg.sender, "invalid addr");
        require(isBlacklisted, "server not whitelisted");
        uint256[] memory postIds = _accounts[user].posts;
        uint256 l = postIds.length;
        for (uint256 i = 0; i < l;) {
            delete _feed[postIds[i]];
            unchecked {
                ++i;
            }
        }

        delete _accounts[user];
        blacklist[user] = true;
    }

    function setAccount(string memory profilePic, string memory name, string memory description)
        external
        addressWhitelisted
    {
        if (isWhitelisted) require(whitelist[msg.sender], "not in whitelist");
        address nameOwner = ens.registered(keccak256(abi.encodePacked(name)));
        require(nameOwner == address(0) || nameOwner == msg.sender, "name used");
        require(StringUtils.strlen(name) <= 30 && StringUtils.strlen(description) <= 100, "len");
        Account memory newAccount;
        newAccount.user = msg.sender;
        newAccount.profilePic = profilePic;
        newAccount.name = name;
        newAccount.description = description;
        newAccount.verified = nameOwner == msg.sender;
        _accounts[msg.sender] = newAccount;
        emit SetAccount(msg.sender);
    }

    function post(string memory text) external addressNotBlackListed onlyAccount {
        require(StringUtils.strlen(text) <= 500, "len");
        Publication memory newPublication;
        newPublication.text = text;
        newPublication.timestamp = uint64(block.timestamp);
        newPublication.user = msg.sender;
        newPublication.id = _feedLength;
        _feed.push(newPublication);
        _accounts[msg.sender].posts.push(_feedLength);
        _feedLength++;
        emit Post(msg.sender, newPublication.id);
    }

    function likePost(uint256 postId) external addressNotBlackListed onlyAccount {
        _feed[postId].likes++;
    }

    function likeResponse(uint256 postId, uint256 responseId) external addressNotBlackListed onlyAccount {
        _responses[postId][responseId].likes++;
        emit LikeResponse(msg.sender, postId, responseId);
    }

    function respondPost(uint256 postId, string memory text) external addressNotBlackListed onlyAccount {
        Response memory newResponse;
        newResponse.timestamp = uint64(block.timestamp);
        newResponse.text = text;
        newResponse.user = msg.sender;
        newResponse.id = _responses[postId].length;
        _responses[postId].push(newResponse);
        _feed[postId].responsesCount++;
        emit Respond(msg.sender, postId);
    }

    function follow(address user) external addressNotBlackListed onlyAccount {
        require(!_followed[msg.sender][user], "account already followed");
        require(_accounts[user].user != address(0), "not account");
        _accounts[msg.sender].followed.push(user);
        _accounts[msg.sender].followedCount++;
        _accounts[user].followers.push(msg.sender);
        _accounts[user].followersCount++;
        emit Follow(msg.sender, user);
    }
}

// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}