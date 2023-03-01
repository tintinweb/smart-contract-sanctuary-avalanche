// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IPrizeBondAVAX.sol';
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract PrizeBondAVAX is ERC721Enumerable, Ownable, IPrizeBondAVAX {
    using Counters for Counters.Counter;
    
    address public myChance;
    address public myChanceMigrated;

    Counters.Counter private _tokenIdCounter;

    modifier onlyMyChance() {
        require(msg.sender == myChance || msg.sender == myChanceMigrated, "Invalid caller");
        _;
    }

    constructor() ERC721("PrizeBondAvax", "PBA") {}

    string baseUri = "https://backend.my-chance.io/api/AVAX/token/";

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setMyChance(address _myChance, address _myChanceMigration) external onlyOwner { 
        require(_myChance != address(0) && _myChanceMigration != address(0), "Invalid addresses"); 
        myChance = _myChance;
        myChanceMigrated = _myChanceMigration;
    }

    function safeMint(address to) external onlyMyChance returns(uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }

    function safeBurn(uint256 tokenId) external onlyMyChance {
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}