// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Factory.sol";

interface IMarketFactory {
    function _tokenIds() external view returns (uint256);
    function uri(uint256 tokenId) external view returns (string memory);
}

contract Main is Ownable {
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
        require(msg.sender != owner() && msg.value == flatFee, "Main: insufficient flat fee");
        MarketFactory subFactory = new MarketFactory();
        userCollectionInfo[msg.sender].push(address(subFactory));
        subFactory.setSize(size);
        subFactory.setCollectionInfo(collectionMetadata);
        subFactory.setMarketplace(address(this));
        subFactory.transferOwnership(msg.sender);
    }
}