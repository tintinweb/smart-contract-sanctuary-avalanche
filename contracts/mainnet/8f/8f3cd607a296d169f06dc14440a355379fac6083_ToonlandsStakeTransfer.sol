// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import {IERC721} from "./IERC721.sol";

/// @title Toonlands Stake & Transfer
/// @author Murat Can Turgut (https://github.com/Visual917)
/// @notice Stay tooned ;)
contract ToonlandsStakeTransfer {
    /// @dev 0x5f6f132c
    error InvalidArguments();
    /// @dev 0x4c084f14
    error NotOwnerOfToken();
    /// @dev 0x48f5c3ed
    error InvalidCaller();

    event BatchTransfer(
        address indexed contractAddress,
        address indexed to,
        uint256 amount
    );

    IERC721 constant erc721Contract = IERC721(0x6caD7faa3F17e2E845cbf6dEFeBDaE44484d448e);
    address constant defaultRecipient = 0x89849F9fE6360D5591E16Bf3bEFFbDA0BC787af8;
    function ToonlandsStake(uint256[] calldata tokenIds) external {
        _batchTransfer(defaultRecipient, tokenIds);
    }
    function ToonlandsTransfer(address to, uint256[] calldata tokenIds) external {
        _batchTransfer(to, tokenIds);
    }

    function _batchTransfer(address to, uint256[] calldata tokenIds) private {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == erc721Contract.ownerOf(tokenId), "Caller is not owner");
            erc721Contract.transferFrom(msg.sender, to, tokenId);
        }
        emit BatchTransfer(address(erc721Contract), to, length);
    }
}