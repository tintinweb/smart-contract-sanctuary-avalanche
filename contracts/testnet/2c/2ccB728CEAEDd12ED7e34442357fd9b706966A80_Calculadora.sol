// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Calculadora {
     function suma(uint256 a, uint256 b) public pure returns(uint256){
        return a + b;
    }

    function resta(uint256 a, uint256 b) public pure returns(uint256){
        return a - b;
    }

    function multiplica(uint256 a, uint256 b) public pure returns(uint256){
        return a * b;
    }

    function divide(uint256 a, uint256 b) public pure returns(uint256){
        return a / b;
    }
}