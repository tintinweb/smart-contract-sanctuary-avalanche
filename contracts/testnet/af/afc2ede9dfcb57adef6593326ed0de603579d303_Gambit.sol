/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-21
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
        uint matchNumber;
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


    mapping (string => MatchBet) public matchesBets;

    struct global {
        uint256 nextDayPot;
        uint256 finalPot;
        uint256 treasuryPot;
        uint256 foundersClubPot;
        uint256 minBet;
        uint256 initialPot;
    }


    global public pots; 

    uint256 winnerCut = 60;
    uint256 perfectScoreCut = 10;
    uint256 nextDayCut = 10;
    uint256 finalCut = 5;
    uint256 treasuryCut = 10;
    uint256 foundersClubCut = 5;
   
    

    constructor(Match[] memory _matches) {
        require(_matches.length > 0, "Array of matches is Empty");
        owner = payable(msg.sender);

        for (uint256 i = 0; i < _matches.length; i++) {
            matches[_matches[i].id].id = _matches[i].id;
            matches[_matches[i].id].matchNumber = _matches[i].matchNumber;
            matches[_matches[i].id].matchDate = _matches[i].matchDate;
            matches[_matches[i].id].closingTime = _matches[i].closingTime;
            matches[_matches[i].id].homeTeam = _matches[i].homeTeam;
            matches[_matches[i].id].homeTeamScore = _matches[i].homeTeamScore;
            matches[_matches[i].id].homeTeamWinner = _matches[i].homeTeamWinner;
            matches[_matches[i].id].awayTeam = _matches[i].awayTeam;
            matches[_matches[i].id].awayTeamScore = _matches[i].awayTeamScore;
            matches[_matches[i].id].awayTeamWinner = _matches[i].awayTeamWinner;
            matches[_matches[i].id].isTie = _matches[i].isTie;
            matches[_matches[i].id].isClosed = _matches[i].isClosed;
            matches[_matches[i].id].isClaimable = _matches[i].isClaimable;
            matches[_matches[i].id].isCancelled = _matches[i].isCancelled;
        }

        pots.nextDayPot = 0;
        pots.finalPot = 0;
        pots.treasuryPot = 0;
        pots.foundersClubPot = 0;
        pots.minBet = 1 ether;
        pots.initialPot = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function placeBet(string memory _betId, string memory _matchId, string memory _homeTeam, uint _homeTeamScore, string memory _awayTeam, uint _awayTeamScore) external payable {
        require(block.timestamp < matches[_matchId].closingTime && !matches[_matchId].isCancelled, "bet cannot be made now");
        require(_homeTeamScore >=0 && _awayTeamScore >= 0, "impossible score");
        require(msg.value >= pots.minBet, "bet amount too low");
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

        pots.nextDayPot += betAmount*nextDayCut/100;
        pots.finalPot += betAmount*finalCut/100;
        pots.treasuryPot += betAmount*treasuryCut/100;
        pots.foundersClubPot += betAmount*foundersClubCut/100;

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

        pots.nextDayPot -= refund*nextDayCut/100;
        pots.finalPot -= refund*finalCut/100;
        pots.treasuryPot -= refund*treasuryCut/100;
        pots.foundersClubPot -= refund*foundersClubCut/100;

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
        pots.initialPot += msg.value;
    }

    function fundInitialPotWithNextDayPot() external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        pots.initialPot += pots.nextDayPot;
    }

    function distributeInitialPot(string[] memory _matches) external onlyOwner {    
        require(msg.sender == owner, "Only Owner function");    
        uint totalAvax;
        for (uint i=0; i < _matches.length; i++){
            totalAvax += matchesBets[_matches[i]].avaxPot;
        }

        for (uint i=0; i < _matches.length; i++){
            uint distribution = matchesBets[_matches[i]].avaxPot/totalAvax;
            uint initialPotForMatch = pots.initialPot*distribution;

            matchesBets[_matches[i]].winnersPot += initialPotForMatch*winnerCut/100;
            matchesBets[_matches[i]].perfectScorePot += initialPotForMatch*perfectScoreCut/100; 

            pots.nextDayPot += initialPotForMatch*nextDayCut/100;
            pots.finalPot += initialPotForMatch*finalCut/100;
            pots.treasuryPot += initialPotForMatch*treasuryCut/100;
            pots.foundersClubPot += initialPotForMatch*foundersClubCut/100;
        }

    }

    function setMinBet(uint256 _minBet) external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        require(_minBet >= 1 ether, "this would be a very small bet amount");
        pots.minBet = _minBet;
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
        uint treasuryPotWD = pots.treasuryPot;
        uint foundersClubPotWD = pots.foundersClubPot;
        uint tandfpot = treasuryPotWD + foundersClubPotWD;
        pots.treasuryPot -= treasuryPotWD;
        pots.foundersClubPot -= foundersClubPotWD;
        payable(msg.sender).transfer(tandfpot);
    }

 

    /* function viewMatchPots(string memory _matchId) external view onlyOwner returns (uint, uint, uint, uint, uint){
        require(msg.sender == owner, "Only Owner function");
        return (matchesBets[_matchId].winnersPot, matchesBets[_matchId].perfectScorePot, matchesBets[_matchId].matchWinnersAvax, matchesBets[_matchId].perfectScoreWinnersAvax, matchesBets[_matchId].avaxPot);
    } */
    
    function viewBet(string memory _matchId, address _address) external view onlyOwner returns (string memory, uint, string memory, uint, string memory, uint){
        require(msg.sender == owner, "Only Owner function");
        return (matchesBets[_matchId].betsByAddress[_address].matchId,matchesBets[_matchId].betsByAddress[_address].amount,matchesBets[_matchId].betsByAddress[_address].homeTeam,matchesBets[_matchId].betsByAddress[_address].homeTeamScore,matchesBets[_matchId].betsByAddress[_address].awayTeam, matchesBets[_matchId].betsByAddress[_address].awayTeamScore);   
    }

    function viewMatchDates(string memory _matchId) external view onlyOwner returns (string memory, uint, string memory, uint, uint, uint) {
        require(msg.sender == owner, "Only Owner function");
        string memory _homeTeam = matches[_matchId].homeTeam;
        uint _homeScore = matches[_matchId].homeTeamScore;
        string memory _awayTeam = matches[_matchId].awayTeam;
        uint _awayScore = matches[_matchId].awayTeamScore;
        uint _matchDate = matches[_matchId].matchDate;
        uint _closingTime = matches[_matchId].closingTime;
        return (_homeTeam, _homeScore, _awayTeam, _awayScore, _matchDate, _closingTime);
    }
}