/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-30
*/

// SPDX-License-Identifier : MIT

pragma solidity ^0.8.10;

contract bytesDecodeEncode {
    

    struct MyStruct {
        string name; 
        uint[2] nums;
    }


    function encode(
        uint x, 
        address addr,
        uint[] calldata arr,
        MyStruct calldata myStruct
    ) external pure returns (bytes memory) {
        return abi.encode(x, addr, arr, myStruct);
    } 
    

    function decode(bytes calldata data) external pure returns (
        uint x, 
        address addr,
        uint[] memory arr,
        MyStruct memory myStruct) {
        (x, addr, arr, myStruct) = abi.decode(data, (uint, address, uint[], MyStruct));
    }
}