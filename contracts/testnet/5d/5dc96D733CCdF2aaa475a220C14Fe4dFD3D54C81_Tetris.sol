/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Tetris {

    struct Score {
        string id; 
        uint level;
        uint score;
        uint line;
        uint256 st;
        uint keyStore;
    }

    struct Rank {
        address addr; 
        uint level;
        uint score;
        uint line;
        uint256 st;
    }

    mapping(address => mapping(string => Score)) Scores;
    mapping(address => string[] ) Scoreids;

    mapping(address => uint) clientsMap;
    address[] clients;


    function addScore(string memory id , uint score, uint lines, uint level, uint256 st) public {
        Score storage sender = Scores[msg.sender][id];
        sender.id = id;
        sender.score = score;
        sender.line = sender.line + lines;
        sender.level = level;
        sender.st = st;

        if (sender.keyStore == 0){
            sender.keyStore = 1;
            Scoreids[msg.sender].push(id);
        }

        if ( clientsMap[msg.sender] == 0 ) {
            clientsMap[msg.sender] = 1;
            clients.push(msg.sender);
        }
        
    }

    function getScore() public view returns(Score[] memory ){
        Score[] memory allScores = new Score[](Scoreids[msg.sender].length);
        uint arrayLength = Scoreids[msg.sender].length;
        for (uint i=0; i<arrayLength; i++) {
            Score memory singleScore;
            string memory tmpid = Scoreids[msg.sender][i];
            singleScore.id = tmpid;
            singleScore.score = Scores[msg.sender][tmpid].score;
            singleScore.level = Scores[msg.sender][tmpid].level;
            singleScore.line = Scores[msg.sender][tmpid].line;
            singleScore.st = Scores[msg.sender][tmpid].st;
            allScores[i] = singleScore;
        }
        return allScores;
    }

    function getRank() public view returns(Rank[] memory) {
        Rank[] memory allRank = new Rank[](clients.length);
        uint clientLength = clients.length;
        for(uint i = 0; i<clientLength;i++){
            Rank memory singleRank;

            uint clientThisHigh = 0;
            uint clientThisHighId = 0;
            uint clientThisLength = Scoreids[clients[i]].length;
            for(uint j = 0; j < clientThisLength; j++) {
                if (Scores[clients[i]][Scoreids[clients[i]][j]].score > clientThisHigh) {
                    clientThisHigh = Scores[clients[i]][Scoreids[clients[i]][j]].score;
                    clientThisHighId = j;
                }
            }

            singleRank.addr = clients[i];
            singleRank.score = Scores[clients[i]][Scoreids[clients[i]][clientThisHighId]].score;
            singleRank.level =Scores[clients[i]][Scoreids[clients[i]][clientThisHighId]].level;
            singleRank.line = Scores[clients[i]][Scoreids[clients[i]][clientThisHighId]].line;
            singleRank.st = Scores[clients[i]][Scoreids[clients[i]][clientThisHighId]].st;

            allRank[i] = singleRank;
        }

        return allRank;
    } 

    function getidstest() public view returns(string[] memory) {
        return Scoreids[msg.sender];
    }

    function getclientstest() public view returns(address[] memory) {
        return clients;
    }
    
}