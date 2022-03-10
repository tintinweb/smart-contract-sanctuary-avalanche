/**
 *Submitted for verification at snowtrace.io on 2022-03-10
*/

pragma solidity ^0.8.0;

abstract contract IDino {
    struct ReferralUser {
        uint256 totalEggs;
        uint256 totalRewards;
    }
    mapping(address => ReferralUser) public referrals;
}

contract ReferralContest {
    
    IDino dinoToken;
    
    // number of register
    uint public numberOfPlayers;

    bool public paused;

    address private owner;

    struct Player {
        string pseudo;
        uint index;
    }

    mapping(uint => address) public playerPerIndex;
    mapping(address => Player) public indexPerPlayer;

    modifier isNotPaused {
        require(!paused, "ERR: Dino Camp is paused.");
        _;
    }

    constructor(IDino _dinoToken) {
        dinoToken = _dinoToken;
        numberOfPlayers = 0;
        paused = false;
        owner = msg.sender;
    }

    function register(string memory pseudo) public isNotPaused {
        require(indexPerPlayer[msg.sender].index == 0, "already registered!");

        (uint256 totalEggs,) = getScore(msg.sender);
        require(totalEggs > 0, "You must have referred at least one person");
        
        numberOfPlayers += 1;
        playerPerIndex[numberOfPlayers] = msg.sender;
        indexPerPlayer[msg.sender] = Player(pseudo, numberOfPlayers);
    }

    function getScore(address account) public view returns(uint256, uint256) {
        return dinoToken.referrals(account);
    }

    function getRank(address account) public view returns(uint256)  {
        (uint256 myEggs,) = getScore(account);
        uint256 rank = 1;
        for (uint256 i = 1; i < numberOfPlayers + 1; i++) {
            if (account != playerPerIndex[i]) {
                (uint256 totalEggs,) = getScore(playerPerIndex[i]);
                if (myEggs < totalEggs) {
                    rank ++;
                }
            }
        }

        return rank;
    }

    function getLeaderboard() view public returns(uint256, uint256, uint256) {
        uint256 top1 = 0;
        uint256 top2 = 0;
        uint256 top3 = 0;

        uint256 score1 = 0;
        uint256 score2 = 0;
        uint256 score3 = 0;
        
        for (uint256 i = 1; i <= numberOfPlayers; i++) {
            (uint256 score,) = getScore(playerPerIndex[i]);
            if (score >= score1) {
                score3 = score2;
                top3 = top2;
                
                score2 = score1;
                top2 = top1;
                
                score1 = score;
                top1 = i;
                
            } else if (score >= score2) {
                score3 = score2;
                top3 = top2;

                score2 = score;
                top2 = i;
            } else if (score >= score3) {
                score3 = score;
                top3 = i;
            }
        }
        return (top1, top2, top3);
    }

    function getLeaderboard(uint256 start, uint256 end) view public returns(uint256, uint256, uint256) {
        uint256 top1 = 0;
        uint256 top2 = 0;
        uint256 top3 = 0;

        uint256 score1 = 0;
        uint256 score2 = 0;
        uint256 score3 = 0;
        
        for (uint256 i = start; i <= end; i++) {
            (uint256 score,) = getScore(playerPerIndex[i]);
            if (score >= score1) {
                score3 = score2;
                top3 = top2;
                
                score2 = score1;
                top2 = top1;
                
                score1 = score;
                top1 = i;
                
            } else if (score >= score2) {
                score3 = score2;
                top3 = top2;

                score2 = score;
                top2 = i;
            } else if (score >= score3) {
                score3 = score;
                top3 = i;
            }
        }
        return (top1, top2, top3);
    }

    function setPaused(bool _paused) external {
        require(msg.sender == owner, "ERR: You need to be the owner");
        paused = _paused;
    }
}