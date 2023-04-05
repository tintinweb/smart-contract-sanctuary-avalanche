// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BatchSafeTransferFrom {

    // @notice "batchSafeTransferFrom" function is used to transfer tokens from one address to another
    function batchSafeTransferFrom(address contractAddress, address from, address to, uint256[] calldata tokenIds) external {
        IERC721 contractInstance = IERC721(contractAddress);

        for (uint i = 0; i < tokenIds.length; i++) {
            contractInstance.safeTransferFrom(from, to, tokenIds[i], abi.encodePacked(contractAddress));
        }
    }
}

// @notice "ERC721" interface is used to interact with the token contract
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}