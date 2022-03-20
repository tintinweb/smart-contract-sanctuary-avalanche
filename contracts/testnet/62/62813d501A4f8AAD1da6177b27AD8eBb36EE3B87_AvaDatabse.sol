/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-19
*/

// File: AvaDatabase.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract AvaDatabse {



    struct RoundInfo {

        uint roundID;

        mapping(address => uint) playedGames;

        mapping(address => uint) wonGames;

        mapping(address => uint) playedAmount;

        mapping(address => uint) wonAmount;

        mapping(address => uint) lostAmount;

    }



    address[] public users;

    mapping(address => bool) added;

    mapping(address => bool) isGame;



    address public owner;

    uint public currentRoundID;

    RoundInfo[] public rounds;



    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }

    

    constructor() {

        owner = msg.sender;

    }



    function addGame(address _gameAddress) external onlyOwner{

        isGame[_gameAddress] = true;

    }



    

    function removeGame(address _gameAddress) external onlyOwner{

        isGame[_gameAddress] = false;

    }





    function updateStatistics(address player, bool isWin, uint _playedAmount, uint _wonAmount) public {

        require(isGame[msg.sender]);

        RoundInfo storage roundInfo = rounds[currentRoundID];

        if(!added[player]) {

            users.push(player);

            added[player] = true;

        }

        roundInfo.playedGames[player]++;

        if(isWin){

            roundInfo.wonGames[player]++;

            roundInfo.playedAmount[player] += _playedAmount;

            roundInfo.wonAmount[player] += _wonAmount;

        }

        else {

            roundInfo.playedAmount[player] += _playedAmount;

            roundInfo.lostAmount[player] += _playedAmount;

        }

    }



    function getInfoOfUser(address player, uint roundID) external view returns (uint gameNo, uint wonNo, uint lostNo, uint playedAmn,uint wonAmn,uint lostAmn){

        RoundInfo storage roundInfo = rounds[roundID];

        gameNo = roundInfo.playedGames[player];

        wonNo = roundInfo.wonGames[player];

        lostNo = roundInfo.playedGames[player] - roundInfo.wonGames[player];

        playedAmn = roundInfo.playedAmount[player];

        wonAmn = roundInfo.wonAmount[player];

        lostAmn = roundInfo.lostAmount[player];

    }



    function getTotalInfo(uint roundID) external view returns (uint gameNo, uint wonNo, uint lostNo, uint playedAmn,uint wonAmn,uint lostAmn){

        RoundInfo storage roundInfo = rounds[roundID];

        for(uint i = 0; i < users.length; i++) {

            gameNo += roundInfo.playedGames[users[i]];

            wonNo += roundInfo.wonGames[users[i]];

            lostNo += roundInfo.playedGames[users[i]] - roundInfo.wonGames[users[i]];

            playedAmn += roundInfo.playedAmount[users[i]];

            wonAmn += roundInfo.wonAmount[users[i]];

            lostAmn += roundInfo.lostAmount[users[i]];

        }

    }



    function startNewRound() external {

        require(isGame[msg.sender] || msg.sender == owner);

        currentRoundID++;

    }

}