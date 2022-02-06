/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    

    uint256 counter = 0;
    mapping(uint => Pool) public poolMapping;
    struct Pool {
        uint id;
        uint number;
        CaleeTracker calee;
    }
    event newPoolEmit(uint id, uint inputNum, uint newPoolNumber, CaleeTracker indexed newCaleeAddress);

    function getId() private returns(uint) {
        return ++counter; 
    }

    function createStore(uint256 inputNum) public {
        CaleeTracker caleeTracker;
        caleeTracker = new CaleeTracker();

        uint id = getId();
        Pool storage newPool = poolMapping[id];
        newPool.id = id;
        newPool.number = inputNum;
        newPool.calee = caleeTracker;
        emit newPoolEmit(id ,inputNum, newPool.number, caleeTracker);
    }
}

contract CaleeTracker {
    uint256 iddd=1;
}