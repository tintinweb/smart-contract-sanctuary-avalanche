// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DestinationChainMock {
    uint8 public number;

    address public immutable diamondContract;

    constructor(address _diamondContract) {
        diamondContract = _diamondContract;
    }

    function store(uint8 _num) public returns (uint8) {
        require(
            msg.sender == diamondContract,
            "DestinationChainMock: caller is not the diamond contract"
        );
        number = _num;
        return number;
    }
}