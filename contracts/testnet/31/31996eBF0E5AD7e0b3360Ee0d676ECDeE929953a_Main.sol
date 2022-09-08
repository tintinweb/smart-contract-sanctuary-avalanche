// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
// import "./Factory.sol";
import "./CloneFactory.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


   function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

interface IMarketFactory {
    function _tokenIds() external view returns (uint256);
    function uri(uint256 tokenId) external view returns (string memory);
    function setSize(uint _size) external;
    function setCollectionInfo (string memory _uri) external;
    function setMarketplace (address _marketplace) external;
    function transferOwnership(address newOwner) external;
}

contract Main is Ownable, CloneFactory {
    address public key;
    address public marketFactory;

    uint public flatFee = 15 * 10 ** 16;       // default fee 0.15 avax
    mapping(address=>address[]) public userCollectionInfo;
    mapping (address=>bool) _ableToCreatePrivateNFTforSale;
    
    constructor(){}

    function setFlatFee(uint _fee) public onlyOwner {
        flatFee = _fee;
    }

    function AbleToCreatePrivateNFTforSale(address user) external view returns(bool) {
        return _ableToCreatePrivateNFTforSale[user];
    }

    function setAbleToCreatePrivateNFTforSale(address user, bool flag) external {
        _ableToCreatePrivateNFTforSale[user] = flag;
    }

    function setMarketFactory(address factory) external onlyOwner {
        marketFactory = factory;
    }

    function creatCollection(string memory collectionMetadata, uint size) external payable  {
        if(msg.sender != owner())
            require(msg.value == flatFee, "Main: insufficient flat fee");
        address subFactory = createClone(marketFactory);
        // MarketFactory subFactory = new MarketFactory();
        userCollectionInfo[msg.sender].push(subFactory);
        IMarketFactory(subFactory).setSize(size);
        IMarketFactory(subFactory).setCollectionInfo(collectionMetadata);
        IMarketFactory(subFactory).setMarketplace(address(this));
        IMarketFactory(subFactory).transferOwnership(msg.sender);
    }
}