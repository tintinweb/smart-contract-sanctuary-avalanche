/**
 *Submitted for verification at snowtrace.io on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Lottery {
    address public owner;
    address payable[] public players;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
    }

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function enter() public payable {
        require(msg.value > .01 ether);

        //address of player entering lottery
        players.push(payable(msg.sender));

    }


    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

        function pickWinner() public onlyOwner {
            uint index = getRandomNumber() % players.length;
            players[index].transfer(address(this).balance);

            lotteryHistory[lotteryId] = players[index];
            lotteryId++;


            //reset contract state
            players = new address payable[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;

    }

    function getBalance () public view returns (uint) {
        return  address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

     


}