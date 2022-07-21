// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract PrizeBond is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    address public myChance;

    enum Assets { DAI, USDT, USDC }

    Counters.Counter private _tokenIdCounter;

    mapping(uint256=>Assets) assetTypes;

    modifier onlyMyChance() {
        require(msg.sender == myChance);
        _;
    }

    constructor() ERC721("PrizeBond", "PB") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://my-chance.io/api/token";
    }

    function getAssetType(uint256 tokenId) public view returns(Assets) {
        return assetTypes[tokenId];
    }

    function setMyChance(address _myChanceAdd) external onlyOwner{ 
        myChance = _myChanceAdd;
    }

    function safeMint(address to, Assets asset) external onlyMyChance returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        assetTypes[tokenId] = asset;
        return tokenId;
    }

    function safeBurn(uint256 tokenId) external onlyMyChance {
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}