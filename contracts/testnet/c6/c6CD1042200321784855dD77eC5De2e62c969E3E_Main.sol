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
    function initialize(address newOnwer) external;
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

    function setKey(address _key) public onlyOwner {
        key = _key;
    }

    function creatCollection(string memory collectionMetadata, uint size) external payable  {
        if(msg.sender != owner())
            require(msg.value == flatFee, "Main: insufficient flat fee");
        address subFactory = createClone(marketFactory);
        // MarketFactory subFactory = new MarketFactory();
        userCollectionInfo[msg.sender].push(subFactory);
        IMarketFactory(subFactory).initialize(address(this));
        IMarketFactory(subFactory).setSize(size);
        IMarketFactory(subFactory).setCollectionInfo(collectionMetadata);
        IMarketFactory(subFactory).setMarketplace(address(this));
        IMarketFactory(subFactory).transferOwnership(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}