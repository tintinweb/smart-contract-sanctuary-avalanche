/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
//By: 0xUrkel Labs
contract HighLow {
    uint256 public currentNumber;
    mapping(address => uint256) public balances;
    address payable public owner;
    address payable public player;
    uint256 constant MINIMUM_BET = 10000000000000000; // 0.1 ether in wei
    bytes32 constant high_hash = keccak256("high");
    bytes32 constant low_hash = keccak256("low");
    constructor() public {
        owner = payable(msg.sender);
        player = payable(msg.sender);
        currentNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
    }

    function guess(string memory _guess) public payable {
        require(msg.value >= MINIMUM_BET, "The minimum bet is 0.1 ether.");
        require(balances[msg.sender] >= msg.value, "You do not have enough funds.");
        require(msg.sender != owner, "The owner cannot play the game.");
        bytes32 guess_hash = keccak256(abi.encodePacked(_guess));
        uint256 nextNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        if ((guess_hash == high_hash && nextNumber > currentNumber || guess_hash == low_hash && nextNumber < currentNumber)) {
            player.transfer(msg.value);
        } else {
            balances[msg.sender] -= msg.value;
    }
    currentNumber = nextNumber;
}

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw funds.");
        owner.transfer(address(this).balance);
    }
}