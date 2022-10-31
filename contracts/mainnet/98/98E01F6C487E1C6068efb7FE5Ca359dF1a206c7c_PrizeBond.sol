// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IPrizeBond.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract PrizeBond is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    
    address public myChance;
    address public myChanceMigrated;

    enum Assets { DAI, USDT, USDC }

    Counters.Counter private _tokenIdCounter;

    mapping(uint256=>Assets) assetTypes;

    modifier onlyMyChance() {
        require(msg.sender == myChance || msg.sender == myChanceMigrated);
        _;
    }

    constructor() ERC721("PrizeBond", "PB") {}

    string baseUri = "https://my-chance.io/api/STABLE/token/";

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function getAssetType(uint256 tokenId) public view returns(Assets) {
        return assetTypes[tokenId];
    }

    function setMyChance(address _myChance, address _myChanceMigration) external onlyOwner{ 
        myChance = _myChance;
        myChanceMigrated = _myChanceMigration;
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