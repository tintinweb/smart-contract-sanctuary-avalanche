/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Keccak256Test {

    function hash(string calldata str) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }

    function hash(uint256 data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    function hash(uint256[] calldata data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    function hash(uint256 data, string calldata str) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data, str));
    }

    function hash(string calldata str, uint256 data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(str, data));
    }
    
    function hash(bytes calldata _bytes, uint256 data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_bytes, data));
    }

    function hash(bytes calldata _bytes) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_bytes));
    }

    function hash(address data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    function hash(address[] calldata data) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }

    function hash(address[] calldata _data, bytes calldata _data2, uint256 value) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_data,_data2,value));
    }

}