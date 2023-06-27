// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library TransferHelper {
    function safeApprove( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("approve(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "approve failed" );
    }

    function safeTransferFrom( address token, address from, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transferFrom failed" );
    }

    function safeTransfer( address token, address to, uint256 value ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "transfer failed" );
    }

    function safeTransferFromERC721( address token, address from, address to, uint256 tokenId ) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from, to, tokenId));
        require( success && (data.length == 0 || abi.decode(data, (bool))), "ERC721 safeTransferFrom failed" );
    }

    function balanceOf( address token, address account ) public returns (uint256 balance){
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("balanceOf(address)", account));
        require(success,"balanceOf failed");
        balance = abi.decode(data, (uint256));
    }
}