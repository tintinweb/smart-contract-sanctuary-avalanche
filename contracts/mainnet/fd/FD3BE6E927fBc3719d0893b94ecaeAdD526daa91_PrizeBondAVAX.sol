// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IPrizeBondAVAX.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract PrizeBondAVAX is ERC721, ERC721Enumerable, Ownable, IPrizeBondAVAX {
    using Counters for Counters.Counter;
    
    address public myChance;

    Counters.Counter private _tokenIdCounter;

    modifier onlyMyChance() {
        require(msg.sender == myChance, "Invalid caller");
        _;
    }

    constructor() ERC721("PrizeBondAvax", "PBA") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://my-chance-avax.io/api/token";
    }

    function setMyChance(address _myChanceAdd) external onlyOwner{ 
        myChance = _myChanceAdd;
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}