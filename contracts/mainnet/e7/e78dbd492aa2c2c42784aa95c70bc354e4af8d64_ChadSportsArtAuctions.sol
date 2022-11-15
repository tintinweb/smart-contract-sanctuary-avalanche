// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title Chad Unique Collection.
/// @author Memepanze
/// @notice ERC721 Mint contract for Chad Sports Unique Collection.
contract ChadSportsArtAuctions is ERC721, ERC721Enumerable, ERC721URIStorage, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    /// @notice Token URI
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 32;

    /// @notice royalties recipient address
    address public _recipient;

    // E V E N T S

    /// @notice Emitted on withdrawBalance() 
    event BalanceWithdraw(address to, uint amount);

    // E R R O R

    error Chad__TransferFailed();

    constructor() ERC721("Chad Sports Art Auctions", "CHADART") {
        setBaseURI("ipfs://bafybeigcz2awf734a2xjxwbt63fbaznjifh4ajhsleu3fcigoq4yng3zxy/");
        mint(msg.sender, 32);
    }

    /// @notice Loop through the mint amount to mint ERC721 tokens
    function mint(address _to, uint256 _mintAmount) public payable onlyOwner {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply <= maxSupply);

        for (uint256 i; i < _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    /// @notice Transfer a batch of NFTs
    /// @param from The sender
    /// @param from The receiver
    /// @param tokenIds An array of tokenIds to transfer
    function safeBatchTranferFrom(
        address from,
        address to,
        uint256[] memory tokenIds
    ) external nonReentrant {
        for(uint i; i < tokenIds.length; i++){
            require(_isApprovedOrOwner(_msgSender(), tokenIds[i]), "ERC721: caller is not token owner or approved");
            _safeTransfer(from, to, tokenIds[i], "");
        }   
    }

    /// @notice Admin function to allow the Owner to transfer all the NFTs to an address
    /// @param from The sender
    /// @param from The receiver
    function safeBatchTranferFromAll(
        address from,
        address to
    ) external nonReentrant {
        for(uint i; i < maxSupply; i++){
            require(_isApprovedOrOwner(_msgSender(), i), "ERC721: caller is not token owner or approved");
            _safeTransfer(from, to, i, "");
        }
    }

    /// @notice Set a new base URI to update metadata
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice Token URI for a token id
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                );
    }

    /// @notice Withdraw the contract balance to the contract owner
    /// @param _to Recipient of the withdrawal
    function withdrawBalance(address _to) external onlyOwner nonReentrant {
        uint amount = address(this).balance;
        bool sent;

        (sent, ) = _to.call{value: amount}("");
        if (!sent) {
            revert Chad__TransferFailed();
        }

        emit BalanceWithdraw(_to, amount);
    }

    // R O Y A L T I E S

    /// @dev Royalties implementation.

    /**
     * @dev EIP2981 royalties implementation: set the recepient of the royalties fee to 'newRecepient'
     * Maintain flexibility to modify royalties recipient (could also add basis points).
     *
     * Requirements:
     *
     * - `newRecepient` cannot be the zero address.
     */

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0));
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 6) / 100);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}