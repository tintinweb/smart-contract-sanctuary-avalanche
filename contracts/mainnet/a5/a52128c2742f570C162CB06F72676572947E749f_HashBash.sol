/**
 *Submitted for verification at snowtrace.io on 2022-12-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract HashBash {
    address public owner;                   // bigPoppa


    mapping (uint8 => bytes32) hashMash;    // mapping of all hashed answers
    mapping (address => mapping(uint8 => string)) userAnswers;
    uint public triviaDay;
    // uint public initime;                    // keeps the normies in check at least

    modifier bigPoppa {
        require(msg.sender == owner, '!owner');
        _;
    }

    constructor(bytes32[12] memory hash_mash) {
        owner = msg.sender;
        // initime = _initime;
        for (uint8 i = 0; i < hash_mash.length; i++) hashMash[i] = hash_mash[i];
    }

    function guess(uint8 pick, string calldata luckyGuess) external {
        userAnswers[msg.sender][pick] = luckyGuess;
    }

    function setDay(uint day_) external bigPoppa {
        triviaDay = day_;
    }

    function userGuesses(uint8 pick) public view returns(string memory){
        return userAnswers[msg.sender][pick];
    }

    function feelingLucky(uint8 pick) view public returns(bool){
        string memory answer = userAnswers[msg.sender][pick];
        return keccak256(abi.encode(answer)) == hashMash[pick];
    }

    function hashString(string calldata toHash) public pure returns(bytes32){
        return keccak256(abi.encode(toHash));
    }

    function swapHash(uint8 item, bytes32 hashedItem) public bigPoppa {
        hashMash[item] = hashedItem;
    }

    function transferOwnership(address _owner) public bigPoppa {
        owner = _owner;
    }
}