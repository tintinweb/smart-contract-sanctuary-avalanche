/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-19
*/

// File: pooria/test.sol





pragma solidity 0.8.15;



contract Hash {



    string public owner;



    constructor(string memory _str) {

        owner = _str;

    }



    function keccak(uint _num) external pure returns(bytes32) { // 22082 gas, _num = 250

        return keccak256(abi.encode(_num));

    }



    function sha(uint _num) external pure returns(bytes32) { // 22938 gas, _num = 250

        return sha256(abi.encode(_num));

    }



    function ripe(uint _num) external pure returns(bytes20) { // 23290 gas, _num = 250

        return ripemd160(abi.encode(_num));

    }



}