/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Gambit {
    event BetEvent(
        address addy,
        uint256 amount,
        string matchId,
        string homeTeam,
        uint256 homeTeamScore,
        string awayTeam,
        uint256 awayTeamScore
    );

    struct Bet {
        string betId;
        address addy;
        uint256 amount;
        string matchId;
        string homeTeam;
        uint256 homeTeamScore;
        bool homeTeamWinner;
        string awayTeam;
        uint256 awayTeamScore;
        bool awayTeamWinner;
        bool isTie;
        bool isMatchWinner;
        bool isPerfectScoreWinner;
        uint256 gambitPoints;
        uint prizeMatchWinner;
        uint prizePerfectScoreWinner;
        bool isClaimed;
    }

    struct Match {
        string id;
        uint8 matchNumber;
        uint256 matchDate;
        uint256 closingTime;
        string homeTeam;
        uint256 homeTeamScore;
        bool homeTeamWinner;
        string awayTeam;
        uint256 awayTeamScore;
        bool awayTeamWinner;
        bool isTie;
        bool isClosed;
        bool isClaimable;
        bool isCancelled;
    }

    struct MatchBet {
        mapping(address => Bet) betsByAddress;
        mapping (address => Bet) winners;
        address[] winnersAddress;
        Bet[] bets;
        uint matchWinners;
        uint perfectScoreWinners;
        uint256 winnersPot;
        uint256 perfectScorePot;
        uint256 betsQ;
        uint matchWinnersAvax;
        uint perfectScoreWinnersAvax;
        uint avaxPot;
    }

     address payable private owner;

 
    mapping (string => Match) private matches;


    mapping (string => MatchBet) private matchesBets;

    struct global {
        uint256 nextDayPot;
        uint256 finalPot;
        uint256 treasuryPot;
        uint256 foundersClubPot;
        uint256 minBet;
        uint256 initialPot;
        
    }


    global globalV; 

    uint256 winnerCut = 60;
    uint256 perfectScoreCut = 10;
    uint256 nextDayCut = 10;
    uint256 finalCut = 5;
    uint256 treasuryCut = 10;
    uint256 foundersClubCut = 5;
   
    
    uint private timeClose = 30 minutes;

    constructor(Match[] memory _matches) {
        require(_matches.length > 0, "Array of matches is Empty");
        owner = payable(msg.sender);
        for (uint256 i = 0; i < _matches.length; i++) {
            _matches[i].closingTime = _matches[i].matchDate - timeClose;
            matches[_matches[i].id] = _matches[i];
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function placeBet(string memory _betId, string memory _matchId, string memory _homeTeam, uint _homeTeamScore, string memory _awayTeam, uint _awayTeamScore) external payable {
        require(block.timestamp < matches[_matchId].closingTime && !matches[_matchId].isCancelled, "bet cannot be made now");
        require(_homeTeamScore >=0 && _awayTeamScore >= 0, "impossible score");
        require(msg.value >= globalV.minBet, "bet amount too low");
        require(matchesBets[_matchId].betsByAddress[msg.sender].amount == 0, "bet already made");
        require (msg.sender != owner, "Owner can't make a bet");
        
        uint betAmount = msg.value;

        matchesBets[_matchId].betsByAddress[msg.sender].betId = _betId;
        matchesBets[_matchId].betsByAddress[msg.sender].addy = msg.sender;
        matchesBets[_matchId].betsByAddress[msg.sender].amount = betAmount;
        matchesBets[_matchId].betsByAddress[msg.sender].matchId = _matchId;
        matchesBets[_matchId].betsByAddress[msg.sender].homeTeam = _homeTeam;
        matchesBets[_matchId].betsByAddress[msg.sender].homeTeamScore = _homeTeamScore;
        matchesBets[_matchId].betsByAddress[msg.sender].homeTeamWinner = _homeTeamScore < _awayTeamScore ? false : _homeTeamScore == _awayTeamScore ? false : true;
        matchesBets[_matchId].betsByAddress[msg.sender].awayTeam = _awayTeam;
        matchesBets[_matchId].betsByAddress[msg.sender].awayTeamScore = _awayTeamScore;
        matchesBets[_matchId].betsByAddress[msg.sender].awayTeamWinner = _awayTeamScore < _homeTeamScore ? false : _awayTeamScore == _homeTeamScore ? false : true;
        matchesBets[_matchId].betsByAddress[msg.sender].isTie = _homeTeamScore == _awayTeamScore ? true : false;
        matchesBets[_matchId].betsByAddress[msg.sender].isMatchWinner = false;
        matchesBets[_matchId].betsByAddress[msg.sender].isPerfectScoreWinner = false;
        matchesBets[_matchId].betsByAddress[msg.sender].gambitPoints = 1;
        matchesBets[_matchId].betsByAddress[msg.sender].prizeMatchWinner = 0;
        matchesBets[_matchId].betsByAddress[msg.sender].prizePerfectScoreWinner = 0;
        matchesBets[_matchId].betsByAddress[msg.sender].isClaimed = false;
        matchesBets[_matchId].bets.push(matchesBets[_matchId].betsByAddress[msg.sender]);

        matchesBets[_matchId].avaxPot += betAmount;
        matchesBets[_matchId].winnersPot += betAmount*winnerCut/100;
        matchesBets[_matchId].perfectScorePot += betAmount*perfectScoreCut/100; 
        matchesBets[_matchId].betsQ++;

        globalV.nextDayPot += betAmount*nextDayCut/100;
        globalV.finalPot += betAmount*finalCut/100;
        globalV.treasuryPot += betAmount*treasuryCut/100;
        globalV.foundersClubPot += betAmount*foundersClubCut/100;

        emit BetEvent(msg.sender, betAmount, _matchId, _homeTeam, _homeTeamScore, _awayTeam, _awayTeamScore);
    }   

    function claimWin(string memory _matchId) external {
        require(!matches[_matchId].isClosed, "Sorry, The match is closed for withdraw");
        require(matches[_matchId].isClaimable, "The match is not finished or claimable jet, please wait");
        require(matchesBets[_matchId].winners[msg.sender].isMatchWinner, "You are not a winner");
        require(matchesBets[_matchId].winners[msg.sender].prizeMatchWinner > 0 || !matchesBets[_matchId].winners[msg.sender].isClaimed, "Your funds has been already withdrawn");
        
        uint prizeMatchWinner = matchesBets[_matchId].winners[msg.sender].prizeMatchWinner;
        uint prizePerfectScoreWinner = matchesBets[_matchId].winners[msg.sender].prizePerfectScoreWinner;
        matchesBets[_matchId].winners[msg.sender].prizeMatchWinner = 0;
        matchesBets[_matchId].winners[msg.sender].prizePerfectScoreWinner = 0;
        matchesBets[_matchId].winners[msg.sender].isClaimed = true;

        matchesBets[_matchId].winnersPot -= prizeMatchWinner;
        matchesBets[_matchId].perfectScorePot -= prizePerfectScoreWinner;
        uint totalPrize = prizeMatchWinner + prizePerfectScoreWinner;
        payable(msg.sender).transfer(totalPrize);
    }

    function withDrawFunds(string memory _matchId) external {
        require(matches[_matchId].isCancelled, "The match is not cancelled, you can't withdraw funds");
        require(!matches[_matchId].isClosed, "Sorry, The match is closed for withdraw");
        uint refund = matchesBets[_matchId].betsByAddress[msg.sender].amount;
        matchesBets[_matchId].betsByAddress[msg.sender].amount = 0;
        

        matchesBets[_matchId].winnersPot -= refund*winnerCut/100;
        matchesBets[_matchId].perfectScorePot -= refund*perfectScoreCut/100; 
        matchesBets[_matchId].betsQ--;

        globalV.nextDayPot -= refund*nextDayCut/100;
        globalV.finalPot -= refund*finalCut/100;
        globalV.treasuryPot -= refund*treasuryCut/100;
        globalV.foundersClubPot -= refund*foundersClubCut/100;

        payable(msg.sender).transfer(refund);
    }

    function setResult(string memory _matchId, uint _homeTeamScore, uint _awayTeamScore) external onlyOwner {
        matches[_matchId].homeTeamScore = _homeTeamScore;
        matches[_matchId].awayTeamScore = _awayTeamScore;
        bool _hTeamWinner = _homeTeamScore < _awayTeamScore ? false : _homeTeamScore == _awayTeamScore ? false : true;
        matches[_matchId].homeTeamWinner = _hTeamWinner;
        bool _aTeamWinner = _awayTeamScore < _homeTeamScore ? false : _awayTeamScore == _homeTeamScore ? false : true;
        matches[_matchId].awayTeamWinner = _aTeamWinner;
        bool _tie = _homeTeamScore == _awayTeamScore ? true : false;
        matches[_matchId].isTie = _tie;
        
        for (uint i=0; i < matchesBets[_matchId].bets.length; i++){
            if ((matchesBets[_matchId].bets[i].homeTeamWinner == _hTeamWinner && matchesBets[_matchId].bets[i].awayTeamWinner == _aTeamWinner) || (matchesBets[_matchId].bets[i].isTie == _tie)){
                if (matchesBets[_matchId].bets[i].homeTeamScore == _homeTeamScore && matchesBets[_matchId].bets[i].awayTeamScore == _awayTeamScore){
                    matchesBets[_matchId].bets[i].isMatchWinner = true;
                    matchesBets[_matchId].bets[i].isPerfectScoreWinner = true;
                    matchesBets[_matchId].bets[i].gambitPoints += 2;
                    
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = true;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = true;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].gambitPoints += 2;
                    
                    matchesBets[_matchId].winners[matchesBets[_matchId].bets[i].addy] = matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy];
                    matchesBets[_matchId].winnersAddress.push(matchesBets[_matchId].bets[i].addy);

                    matchesBets[_matchId].matchWinners++;
                    matchesBets[_matchId].perfectScoreWinners++;
                    matchesBets[_matchId].matchWinnersAvax += matchesBets[_matchId].bets[i].amount;
                    matchesBets[_matchId].perfectScoreWinnersAvax += matchesBets[_matchId].bets[i].amount;
                } else {
                    matchesBets[_matchId].bets[i].isMatchWinner = true;
                    matchesBets[_matchId].bets[i].isPerfectScoreWinner = false;
                    matchesBets[_matchId].bets[i].gambitPoints += 1;

                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = true;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = false;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].gambitPoints += 1;

                    matchesBets[_matchId].winners[matchesBets[_matchId].bets[i].addy] = matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy];
                    matchesBets[_matchId].winnersAddress.push(matchesBets[_matchId].bets[i].addy);

                    matchesBets[_matchId].matchWinners++;
                    matchesBets[_matchId].matchWinnersAvax += matchesBets[_matchId].bets[i].amount;
                }
            } else {
                matchesBets[_matchId].bets[i].isMatchWinner = false;
                matchesBets[_matchId].bets[i].isPerfectScoreWinner = false;
                matchesBets[_matchId].bets[i].prizeMatchWinner = 0;
                matchesBets[_matchId].bets[i].prizePerfectScoreWinner = 0;

                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = false;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = false;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].prizeMatchWinner = 0;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].prizePerfectScoreWinner = 0;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isClaimed = true;

            }
        }

        for (uint i=0; i< matchesBets[_matchId].winnersAddress.length; i++){
            if (matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].isMatchWinner && matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].isPerfectScoreWinner){
                uint betAmount = matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].amount;
                uint matchWinnerPrize = betAmount / matchesBets[_matchId].matchWinnersAvax * matchesBets[_matchId].winnersPot;
                uint perfectScoreWinnerPrize = betAmount / matchesBets[_matchId].perfectScoreWinnersAvax * matchesBets[_matchId].perfectScorePot;
                matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].prizeMatchWinner = matchWinnerPrize;
                matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].prizePerfectScoreWinner = perfectScoreWinnerPrize;
            } else if (matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].isMatchWinner){
                uint betAmount = matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].amount;
                uint matchWinnerPrize = betAmount / matchesBets[_matchId].matchWinnersAvax * matchesBets[_matchId].winnersPot;
                matchesBets[_matchId].winners[matchesBets[_matchId].winnersAddress[i]].prizeMatchWinner = matchWinnerPrize;
            }
            
        }

        matches[_matchId].isClaimable = true;
        
    }

    function cancelMatch (string memory _matchId) external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        matches[_matchId].isCancelled = true;
    }

    function closeMatch (string memory _matchId) external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        matches[_matchId].isClosed = true;
        matches[_matchId].isClaimable = false;
    }

    function fundInitialPot() external payable onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        globalV.initialPot += msg.value;
    }

    function fundInitialPotWithNextDayPot() external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        globalV.initialPot += globalV.nextDayPot;
    }

    function distributeInitialPot(string[] memory _matches) external onlyOwner {    
        require(msg.sender == owner, "Only Owner function");    
        uint totalAvax;
        for (uint i=0; i < _matches.length; i++){
            totalAvax += matchesBets[_matches[i]].avaxPot;
        }

        for (uint i=0; i < _matches.length; i++){
            uint distribution = matchesBets[_matches[i]].avaxPot/totalAvax;
            uint initialPotForMatch = globalV.initialPot*distribution;

            matchesBets[_matches[i]].winnersPot += initialPotForMatch*winnerCut/100;
            matchesBets[_matches[i]].perfectScorePot += initialPotForMatch*perfectScoreCut/100; 

            globalV.nextDayPot += initialPotForMatch*nextDayCut/100;
            globalV.finalPot += initialPotForMatch*finalCut/100;
            globalV.treasuryPot += initialPotForMatch*treasuryCut/100;
            globalV.foundersClubPot += initialPotForMatch*foundersClubCut/100;
        }

    }

    function setMinBet(uint256 _minBet) external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        require(_minBet >= 1 ether, "this would be a very small bet amount");
        globalV.minBet = _minBet;
    }


    function withDrawBalance() public payable onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withDrawPots() public payable onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        uint treasuryPotWD = globalV.treasuryPot;
        uint foundersClubPotWD = globalV.foundersClubPot;
        uint tandfpot = treasuryPotWD + foundersClubPotWD;
        globalV.treasuryPot -= treasuryPotWD;
        globalV.foundersClubPot -= foundersClubPotWD;
        payable(msg.sender).transfer(tandfpot);
    }

    function viewPots() external view onlyOwner returns (string memory){
        require(msg.sender == owner, "Only Owner function");
        return string(abi.encodePacked("ndp->" , globalV.nextDayPot , "-fp->" , globalV.finalPot , "-tp->" , globalV.treasuryPot , "-fcp->" , globalV.foundersClubPot , "-ip" , globalV.initialPot));
    }

    function viewMatch(string memory _matchId) external view onlyOwner returns (string memory){
        require(msg.sender == owner, "Only Owner function");
        return matches[_matchId].id;   
    }
    
    function viewBet(string memory _matchId, address _address) external view onlyOwner returns (uint){
        require(msg.sender == owner, "Only Owner function");
        return matchesBets[_matchId].betsByAddress[_address].amount;   
    }
}