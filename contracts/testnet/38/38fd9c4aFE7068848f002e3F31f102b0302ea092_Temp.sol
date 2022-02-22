//SPDX-License-Identifier: MIT

import "./libs...ERC721.sol";
import "./libs...Counters.sol";
import "./libs...Context.sol";
import "./libs...IERC20.sol";
import "./libs...Strings.sol";
import "./libs...IERC20.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

library RemovableArray {
    // Iterable mapping from address to uint;
    struct UintArray {
        uint256[] keys;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function size(UintArray storage uintArray) public view returns (uint256) {
        return uintArray.keys.length;
    }

    function isExisting(UintArray storage uintArray, uint256 key) public view returns (bool) {
        return uintArray.inserted[key];
    }

    function add(
        UintArray storage uintArray,
        uint256 key
    ) public {
        uintArray.indexOf[key] = uintArray.keys.length;
        uintArray.keys.push(key);
        uintArray.inserted[key] = true;
    }

    function remove(UintArray storage uintArray, uint256 key) public {
        if (!uintArray.inserted[key]) {
            return;
        }

        delete uintArray.inserted[key];

        uint256 index = uintArray.indexOf[key];
        uint256 lastIndex = uintArray.keys.length - 1;
        uint256 lastKey = uintArray.keys[lastIndex];

        uintArray.indexOf[lastKey] = index;
        delete uintArray.indexOf[key];

        uintArray.keys[index] = lastKey;
        uintArray.keys.pop();
    }
}

contract Temp is ERC721, Ownable {
    using RemovableArray for RemovableArray.UintArray;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    IERC20 public marvel;

    struct MarketItem {
        address owner;
        uint256 price;
        uint256 nodeType;
        uint256 boost;
        bool sold;
    }

    mapping (address => RemovableArray.UintArray) private _idsOfAccount; 

    mapping (uint256 => string) private _tokenURIs;

    mapping (address => mapping (uint256 => uint256)) private _rewardBoosts; // account => nodetype => boost

    mapping(uint256 => MarketItem) private idToMarketItem;

    uint256 public maximumNum = 15;
    uint256 public numOfNodeTypes = 0;

    string public baseTokenURI;

    constructor() ERC721("tokenName", "symbol") {
        
    }

    function mintNFT(string memory metadataURI, uint256 price, uint256 nodeType, uint256 boost) public returns (uint256)
    {
        require(boost > 0, "Boost should be greater than 0.");
        require(price > 0, "Price should be greater than 0.");
        require(nodeType > 0, "Transfer Error: Node Type should be greater than 0");

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(msg.sender, id);
        _setTokenURI(id, metadataURI);
        if (nodeType > numOfNodeTypes) numOfNodeTypes = nodeType;
        idToMarketItem[id] =  MarketItem({
            owner: msg.sender,
            price: price,
            nodeType: nodeType,
            boost: boost,
            sold: false
        });
        addIDToAddress(msg.sender, id);
        _rewardBoosts[msg.sender][nodeType-1] += boost;
        return id;
    }

    function _transfer(
            address from,
            address to,
            uint256 tokenID
        ) internal override 
    {
        require(from!=address(0), "Transfer Error: From address couldn't be zero address");
        require(to!=address(0), "Transfer Error: To address couldn't be zero address");
        require(_idsOfAccount[from].isExisting(tokenID), "Transfer Error: Token id is not owned by from address");
        
        MarketItem storage _item = idToMarketItem[tokenID];
        uint256 nodeType = _item.nodeType;
        
        super._transfer(from, to, tokenID);
        
        removeIDFromAddress(from, tokenID);
        _rewardBoosts[from][nodeType-1] -= _item.boost; 
        addIDToAddress(to, tokenID);
        _rewardBoosts[to][nodeType-1] += _item.boost;
        _item.owner = to;
    }

    function buyNFT(uint256 tokenId) public {
        MarketItem storage _item = idToMarketItem[tokenId];
        require(!_item.sold, "Buy NFT: You can't buy this NFT");

        // transfer marvel token to seller
        marvel.transferFrom(msg.sender, _item.owner, _item.price);

        _transfer(_item.owner, msg.sender, tokenId);
        _item.sold = true;
    }

    function sellNFT(uint256 tokenId) public {
        MarketItem storage _item = idToMarketItem[tokenId];
        require(_item.owner==msg.sender, "You are not the owner of this NFT.");
        _item.sold = false;
    }

    function getBoostsOfAccount(address account) public view returns(uint256[] memory) {
        uint256[] memory boosts = new uint256[](numOfNodeTypes);
        // uint256[] memory ids = getIdsOfAddress(account);
        for(uint256 i=0; i<numOfNodeTypes; i++) {
            boosts[i] += _rewardBoosts[account][i];
        }
        return boosts;
    }

    function setMarvelToken(address value) public onlyOwner {
        marvel = IERC20(value);
    }

    function getCurrentTokenID() public view returns (uint256) {
        return _tokenIds.current();
    }

    function addIDToAddress(address account, uint256 id) private {
        require(account!=address(0), "Address couldn't be zero.");
        _idsOfAccount[account].add(id);
    }

    function removeIDFromAddress(address account, uint256 id) private {
        require(account!=address(0), "Address couldn't be zero.");
        _idsOfAccount[account].remove(id);
    }

    function getIdsOfAddress(address account) public view returns(uint256[] memory) {
        require(account!=address(0), "Address couldn't be zero.");
        return _idsOfAccount[account].keys;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(baseTokenURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseTokenURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
}