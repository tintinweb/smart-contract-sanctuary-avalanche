/**
 *Submitted for verification at snowtrace.io on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract SpotBotTokenDistributionContract {
    address public owner;
    address public erc721Contract;
    address public erc1155Contract;
    uint256 public tokenID;

    constructor(address _erc721Contract, address _erc1155Contract) {
        owner = msg.sender;
        erc721Contract = _erc721Contract;
        erc1155Contract = _erc1155Contract;
        tokenID = 3; // Default tokenID to be distributed
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function depositNFT(uint256 _tokenID) external {
        ERC721 erc721 = ERC721(erc721Contract);
        require(erc721.ownerOf(_tokenID) == msg.sender, "You do not own the specified ERC721 token.");

        erc721.transferFrom(msg.sender, address(this), _tokenID);

        ERC1155 erc1155 = ERC1155(erc1155Contract);
        erc1155.safeTransferFrom(address(this), msg.sender, tokenID, 3, bytes(""));
    }

    function withdrawNFT(uint256 _tokenID) external onlyOwner {
        ERC721 erc721 = ERC721(erc721Contract);
        erc721.transferFrom(address(this), msg.sender, _tokenID);
    }

    function depositERC1155(uint256 amount, uint256 _tokenID) external onlyOwner {
        ERC1155 erc1155 = ERC1155(erc1155Contract);
        erc1155.safeTransferFrom(msg.sender, address(this), _tokenID, amount, bytes(""));
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function changeERC721Contract(address newERC721Contract) external onlyOwner {
        erc721Contract = newERC721Contract;
    }

    function changeERC1155Contract(address newERC1155Contract) external onlyOwner {
        erc1155Contract = newERC1155Contract;
    }

    function changeTokenID(uint256 newTokenID) external onlyOwner {
        tokenID = newTokenID;
    }
}