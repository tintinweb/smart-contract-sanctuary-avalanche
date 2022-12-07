/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-07
*/

//SPDX-License-Identifier: None
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

    event ClaimBetEvent(
        address addy,
        string matchId,
        uint betAmount,
        uint prizeMatchWinner,
        uint prizePerfectScoreWinner,
        uint totalPrize
    );

     event ResultEvent(
        string matchId,
        uint matchWinners,
        uint perfectScoreWinners,
        uint matchWinnersAvax,
        uint perfectScoreWinnersAvax
    );

    event RefundBetEvent(
        address addy,
        string matchId,
        uint refund
    );

    event LogEvent(
        address addy,
        string variable,
        uint valueint,
        string valueS,
        bool valueB
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

    struct BetValidation {
        string betId;
        address addy;
        string matchId;
        uint256 amount;
        bool isMatchWinner;
        bool isPerfectScoreWinner;
        uint prizeMatchWinner;
        uint prizePerfectScoreWinner;
        bool isClaimed;
    }

    struct Match {
        string id;
        uint matchDate;
        uint closingTime;
        string homeTeam;
        uint homeTeamScore;
        bool homeTeamWinner;
        string awayTeam;
        uint awayTeamScore;
        bool awayTeamWinner;
        bool isTie;
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

    mapping (string => MatchBet) public matchesBets;
    mapping (string => Match) public matches;
    mapping (address => BetValidation) public betsAddress;

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

    constructor() {
        owner = payable(msg.sender);
        pots.nextDayPot = 0;
        pots.finalPot = 0;
        pots.treasuryPot = 0;
        pots.foundersClubPot = 0;
        pots.minBet = 0.5 ether;
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
        emit LogEvent(msg.sender, "betAmount", betAmount, "NA", false);

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
        matchesBets[_matchId].betsByAddress[msg.sender].isClaimed = false;
        matchesBets[_matchId].bets.push(matchesBets[_matchId].betsByAddress[msg.sender]);

        betsAddress[msg.sender].betId = _betId;
        betsAddress[msg.sender].addy = msg.sender;
        betsAddress[msg.sender].matchId = _matchId;
        betsAddress[msg.sender].amount = betAmount;
        betsAddress[msg.sender].isMatchWinner = false;
        betsAddress[msg.sender].isPerfectScoreWinner = false;
        betsAddress[msg.sender].isClaimed = false;



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
        //require(!matches[_matchId].isClosed, "Sorry, The match is closed for withdraw");
        require(matches[_matchId].isClaimable, "The match is not claimable");
        require(matchesBets[_matchId].betsByAddress[msg.sender].isMatchWinner, "You are not a winner");
        require(!matchesBets[_matchId].betsByAddress[msg.sender].isClaimed, "Your funds has been already withdrawn");

        if (matchesBets[_matchId].betsByAddress[msg.sender].isMatchWinner && matchesBets[_matchId].betsByAddress[msg.sender].isPerfectScoreWinner){
            
            uint _betAmount = matchesBets[_matchId].betsByAddress[msg.sender].amount;
            uint _matchWinnerAvax = matchesBets[_matchId].matchWinnersAvax;
            uint _winnersPot = matchesBets[_matchId].winnersPot;
            uint _prizeMatchWinner = (_betAmount * _winnersPot / _matchWinnerAvax);

            uint _perfectScoreWinnersAvax = matchesBets[_matchId].perfectScoreWinnersAvax;
            uint _perfectScorePot = matchesBets[_matchId].perfectScorePot;
            uint _perfectScoreWinnerPrize = (_betAmount * _perfectScorePot / _perfectScoreWinnersAvax);

            uint _totalPrize = _prizeMatchWinner + _perfectScoreWinnerPrize;

            matchesBets[_matchId].betsByAddress[msg.sender].prizeMatchWinner += _prizeMatchWinner;
            matchesBets[_matchId].betsByAddress[msg.sender].prizePerfectScoreWinner += _perfectScoreWinnerPrize;
            matchesBets[_matchId].betsByAddress[msg.sender].isClaimed = true;
            //emit ResultBetEvent(msg.sender, _matchId, _prizeMatchWinner, _perfectScoreWinnerPrize, _betAmount);

            //matchesBets[_matchId].winnersPot -= _prizeMatchWinner;
            //matchesBets[_matchId].perfectScorePot -= _perfectScoreWinnerPrize;

            payable(msg.sender).transfer(_totalPrize);
            emit ClaimBetEvent(msg.sender, _matchId, _betAmount, _prizeMatchWinner, _perfectScoreWinnerPrize, _totalPrize);

        } else if (matchesBets[_matchId].betsByAddress[msg.sender].isMatchWinner && !matchesBets[_matchId].betsByAddress[msg.sender].isPerfectScoreWinner){
            
            uint _betAmount = matchesBets[_matchId].betsByAddress[msg.sender].amount;
            uint _matchWinnerAvax = matchesBets[_matchId].matchWinnersAvax;
            uint _winnersPot = matchesBets[_matchId].winnersPot;
            uint _prizeMatchWinner = (_betAmount * _winnersPot / _matchWinnerAvax);
            

            matchesBets[_matchId].betsByAddress[msg.sender].prizeMatchWinner += _prizeMatchWinner;
            matchesBets[_matchId].betsByAddress[msg.sender].isClaimed = true;
            
            //matchesBets[_matchId].winnersPot -= _prizeMatchWinner;

            payable(msg.sender).transfer(_prizeMatchWinner);
            emit ClaimBetEvent(msg.sender, _matchId, _betAmount, _prizeMatchWinner, 0, _prizeMatchWinner);
        } 
    }

    function withDrawFunds(string memory _matchId) external {
        require(matches[_matchId].isCancelled, "The match is not cancelled, you can't withdraw funds");
        //require(!matches[_matchId].isClosed, "Sorry, The match is closed for withdraw");
        require(matches[_matchId].isClaimable, "The match is not claimable");
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
        emit RefundBetEvent(msg.sender, _matchId, refund);
    }

    function setResult(string memory _matchId, uint _homeTeamScore, uint _awayTeamScore) external onlyOwner {
        require(!matches[_matchId].isClaimable, "The result is already seated");
        matches[_matchId].homeTeamScore = _homeTeamScore;
        matches[_matchId].awayTeamScore = _awayTeamScore;
        bool _hTeamWinner = _homeTeamScore < _awayTeamScore ? false : _homeTeamScore == _awayTeamScore ? false : true;
        matches[_matchId].homeTeamWinner = _hTeamWinner;
        bool _aTeamWinner = _awayTeamScore < _homeTeamScore ? false : _awayTeamScore == _homeTeamScore ? false : true;
        matches[_matchId].awayTeamWinner = _aTeamWinner;
        bool _tie = _homeTeamScore == _awayTeamScore ? true : false;
        matches[_matchId].isTie = _tie;

        matchesBets[_matchId].matchWinners = 0;
        matchesBets[_matchId].perfectScoreWinners = 0;
        matchesBets[_matchId].matchWinnersAvax = 0;
        matchesBets[_matchId].perfectScoreWinnersAvax = 0;


        for (uint i=0; i < matchesBets[_matchId].bets.length; i++){
            if (matchesBets[_matchId].bets[i].homeTeamWinner == _hTeamWinner && matchesBets[_matchId].bets[i].awayTeamWinner == _aTeamWinner && matchesBets[_matchId].bets[i].isTie == _tie ){
                if (matchesBets[_matchId].bets[i].homeTeamScore == _homeTeamScore && matchesBets[_matchId].bets[i].awayTeamScore == _awayTeamScore){
                    //matchesBets[_matchId].bets[i].isMatchWinner = true;
                    //matchesBets[_matchId].bets[i].isPerfectScoreWinner = true;
                    //matchesBets[_matchId].bets[i].gambitPoints = 3;

                    betsAddress[matchesBets[_matchId].bets[i].addy].matchId = _matchId;
                    betsAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = true;
                    betsAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = true;
                
                    
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = true;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = true;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].gambitPoints = 3;
                    
                    //matchesBets[_matchId].winners[matchesBets[_matchId].bets[i].addy] = matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy];
                    //matchesBets[_matchId].winnersAddress.push(matchesBets[_matchId].bets[i].addy);

                    matchesBets[_matchId].matchWinners++;
                    matchesBets[_matchId].perfectScoreWinners++;
                    matchesBets[_matchId].matchWinnersAvax += matchesBets[_matchId].bets[i].amount;
                    matchesBets[_matchId].perfectScoreWinnersAvax += matchesBets[_matchId].bets[i].amount;
                } else {
                    //matchesBets[_matchId].bets[i].isMatchWinner = true;
                    //matchesBets[_matchId].bets[i].isPerfectScoreWinner = false;
                    //matchesBets[_matchId].bets[i].gambitPoints = 2;

                    betsAddress[matchesBets[_matchId].bets[i].addy].matchId = _matchId;
                    betsAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = true;
                    betsAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = false;

                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = true;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = false;
                    matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].gambitPoints = 2;

                    //matchesBets[_matchId].winners[matchesBets[_matchId].bets[i].addy] = matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy];
                    //matchesBets[_matchId].winnersAddress.push(matchesBets[_matchId].bets[i].addy);

                    matchesBets[_matchId].matchWinners++;
                    matchesBets[_matchId].matchWinnersAvax += matchesBets[_matchId].bets[i].amount;
                }
            } else {
                //matchesBets[_matchId].bets[i].isMatchWinner = false;
                //matchesBets[_matchId].bets[i].isPerfectScoreWinner = false;
                //matchesBets[_matchId].bets[i].prizeMatchWinner = 0;
                //matchesBets[_matchId].bets[i].prizePerfectScoreWinner = 0;

                betsAddress[matchesBets[_matchId].bets[i].addy].matchId = _matchId;
                betsAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = false;
                betsAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = false;

                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isMatchWinner = false;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isPerfectScoreWinner = false;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].prizeMatchWinner = 0;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].prizePerfectScoreWinner = 0;
                matchesBets[_matchId].betsByAddress[matchesBets[_matchId].bets[i].addy].isClaimed = true;

                betsAddress[matchesBets[_matchId].bets[i].addy].prizeMatchWinner = 0;
                betsAddress[matchesBets[_matchId].bets[i].addy].prizePerfectScoreWinner = 0;
                betsAddress[matchesBets[_matchId].bets[i].addy].isClaimed = true;

            }
        }

        matches[_matchId].isClaimable = true;

        emit ResultEvent(_matchId,matchesBets[_matchId].matchWinners, matchesBets[_matchId].perfectScoreWinners,matchesBets[_matchId].matchWinnersAvax, matchesBets[_matchId].perfectScoreWinnersAvax);
        
    }

    function cancelMatch (string memory _matchId) external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        matches[_matchId].isCancelled = true;
    }

    function closeMatch (string memory _matchId) external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        //matches[_matchId].isClosed = true;
        matches[_matchId].isClaimable = false;
    }
    
    function createMatches (Match[] memory _matches) external onlyOwner {
        require(_matches.length > 0, "Array of matches is Empty");
         for (uint256 i = 0; i < _matches.length; i++) {
            matches[_matches[i].id].id = _matches[i].id;
            //matches[_matches[i].id].matchNumber = _matches[i].matchNumber;
            matches[_matches[i].id].matchDate = _matches[i].matchDate;
            matches[_matches[i].id].closingTime = _matches[i].closingTime;
            matches[_matches[i].id].homeTeam = _matches[i].homeTeam;
            matches[_matches[i].id].homeTeamScore = _matches[i].homeTeamScore;
            matches[_matches[i].id].homeTeamWinner = _matches[i].homeTeamWinner;
            matches[_matches[i].id].awayTeam = _matches[i].awayTeam;
            matches[_matches[i].id].awayTeamScore = _matches[i].awayTeamScore;
            matches[_matches[i].id].awayTeamWinner = _matches[i].awayTeamWinner;
            matches[_matches[i].id].isTie = _matches[i].isTie;
            //matches[_matches[i].id].isClosed = _matches[i].isClosed;
            matches[_matches[i].id].isClaimable = _matches[i].isClaimable;
            matches[_matches[i].id].isCancelled = _matches[i].isCancelled;
        } 
    }

    function fundInitialPot() external payable onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        pots.initialPot += msg.value;
    }

    function fundInitialPotWithNextDayPot() external onlyOwner {
        require(msg.sender == owner, "Only Owner function");
        pots.initialPot += pots.nextDayPot;
    }

    function distributeInitialPot(string memory _matchId) external payable onlyOwner {    
        require(msg.sender == owner, "Only Owner function");    
        uint totalAvax = msg.value;

        matchesBets[_matchId].winnersPot += totalAvax*70/100;
        matchesBets[_matchId].perfectScorePot += totalAvax*30/100;

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
}