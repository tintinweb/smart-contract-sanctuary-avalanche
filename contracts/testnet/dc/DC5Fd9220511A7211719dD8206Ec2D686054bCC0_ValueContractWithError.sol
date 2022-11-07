/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8;

contract ValueContractWithError {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    uint256 public value;
    uint256 public value2;

    event updateValue(uint256 value);
    event updateValue2(uint256 value);

    function setValue(uint256 newValue) public {
        value = newValue;

        emit updateValue(newValue);
    }

    function setValue2(uint256 newValue) public {
        value2 = newValue;

        emit updateValue2(newValue);
    }

    function customError() public pure {
        require(false, "Some custom error happened on contract");
    }

    function arithmeticError(uint256 a) public pure returns (uint256) {
        uint256 b = a - 100;
        return b;
    }
}