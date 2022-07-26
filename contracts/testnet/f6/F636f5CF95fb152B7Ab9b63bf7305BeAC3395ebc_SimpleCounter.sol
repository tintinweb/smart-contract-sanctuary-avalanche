/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract SimpleCounter {
    uint public count = 0;
    event Logger(string message, uint timestamp, uint curcount);
    
    function increment() public returns(uint) {
        count += 1;
        emit Logger("add 1", block.timestamp, count);
        return count;
    }

    function addInteger(uint intToAdd) public returns(uint) {
        count += intToAdd;
        emit Logger("add x", block.timestamp, count);
        return count;
    }

    function multiplyInteger(uint intToMultiply) public returns(uint) {
        count = count * intToMultiply;
        emit Logger("multiply x", block.timestamp, count);
        return count;
    }

    function reset() public returns(uint) {
        count = 0;
        emit Logger("reset", block.timestamp, count);
        return count;
    }
}