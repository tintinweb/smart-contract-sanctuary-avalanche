/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    modifier validateuint(uint number) {
        require(number != type(uint256).max, "Error, uint overflow");
        _;
    }

    uint256 counter = 0;
    mapping(uint => Pool) public poolMapping;
    struct Pool {
        uint id;
        uint number;
    }
    event newPoolEmit(uint id, uint inputNum, uint newPoolNumber);

    function getId() private returns(uint) {
        return ++counter; 
    }

    function store(uint256 inputNum) public validateuint(inputNum){
        uint id = getId();
        Pool storage newPool = poolMapping[id];
        newPool.id = id;
        newPool.number = inputNum;
        emit newPoolEmit(id ,inputNum, newPool.number);
    }
    
}