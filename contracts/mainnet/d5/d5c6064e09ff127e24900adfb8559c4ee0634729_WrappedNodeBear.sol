// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./IERC721Receiver.sol";
import "./ERC2981PerTokenRoyalties.sol";
import "./Strings.sol";

contract WrappedNodeBear is
    Context,
    Ownable,
    ERC721Enumerable,
    IERC721Receiver,
    ERC2981PerTokenRoyalties
{
    using Strings for uint256;
    address public bearAddress = 0x81933BA6aE1Bf39eAcE71519f35fB33fE4d72554;
    ERC721 private bears;
    address public royaltyRecipient = 0x75b88F030c6870e366fe5EFB0Ab51B5877F0F795;
    uint256 public contractRoyalties = 1000; //10%
    string public baseExtension = ".json";

    string public _baseTokenURI;
    bool public tokenURIFrozen = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        bears = ERC721(bearAddress);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function wrapBears(uint256[] memory ids) public {
        require(
            bears.isApprovedForAll(_msgSender(), address(this)) == true,
            "Must approve contract"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(_msgSender() == bears.ownerOf(id), "Need to own Bear");
            bears.safeTransferFrom(_msgSender(), address(this), id, "0x00");
            _safeMint(_msgSender(), id);
            _setTokenRoyalty(id, royaltyRecipient, contractRoyalties);
        }
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Metadata frozen");
        _baseTokenURI = uri;
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
}