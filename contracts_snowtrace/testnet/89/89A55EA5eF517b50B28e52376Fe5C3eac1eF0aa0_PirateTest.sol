// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "RoyaltiesV2Impl.sol";
import "LibPart.sol";
import "LibRoyaltiesV2.sol";

contract PirateTest is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 4 ether; // Avax
    uint256 public maxSupply = 6000;
    uint256 public maxMintAmount = 3;
    bool public paused = false;
    address public royaltiesAddress = 0x33b885f796679A7e45138AD87D26f96d029bf321;
    address payable royaltiesAddressPayable = payable(royaltiesAddress);
    uint256 public startTime = 10000; // fix after deploy contract

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(string memory _initBaseURI) ERC721("SeaMan", "SEAM")
    {
        setBaseURI(_initBaseURI); // Uri ipfs stokage img & json
        mint(msg.sender, 3);      // Quantity NFT to Team
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
        require(block.timestamp >= startTime);

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            setRoyalties(supply+i,royaltiesAddressPayable,500);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        startTime = _newStartTime;
    }

 function setAddressRoyalties (address _newRoyaltiesAddress) public onlyOwner {
        royaltiesAddressPayable = payable(_newRoyaltiesAddress);
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints ) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId,_royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}