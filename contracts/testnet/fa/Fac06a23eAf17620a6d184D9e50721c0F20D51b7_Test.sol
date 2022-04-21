/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test {
    function recover(uint32 c, uint256 a, uint8 v, bytes32 r, bytes32 s)
    public
    pure
    returns (address)
    {
        bytes32 messageHash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(c, a))
        ));
        return ecrecover(messageHash, v, r, s);
    }

    function hash(uint32 c, uint256 a)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(c, a))
        ));
    }

    function message(uint32 c, uint256 a)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(c, a));
    }
}