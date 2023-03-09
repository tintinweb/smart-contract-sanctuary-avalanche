/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Election {

    struct Candidate {
        string name;
        uint voteCount;
        uint id;
    }

    struct Voter{
        bool authorized;
        bool voted;
        uint vote;
    }

    struct ElectionInfo {
        string name;
        string description;
        uint startDate;
        uint endDate;
        uint nbCandidates;
    }

    struct ElectionResult {
        uint nbCandidates;
        uint nbVotes;
        uint nbEligibleVoters; //Number of people allowed to vote
        Candidate[] candidatesResult;
    }

    string public electionName;
    string public electionDescription;
    address public owner;
    uint public startDate;
    uint public endDate;
    uint nbEligibleVoters;
    uint public totalVotes;

    uint public candidateIndex = 0;

    mapping( address => Voter) public voters;
    Candidate[] public Candidates;

    ///------------------------------------------------MODIFIERS------------------------------------------------///
    modifier ownerOnly(){
        require(msg.sender == owner, "Only owner of contract can do this manipulation");
        _;
    }

    //block.timestamp in seconds !
    modifier electionOngoing(){
        require(block.timestamp >= startDate && block.timestamp < endDate, "Election not available at this time");
        _;
    }

    modifier electionFinished(){
        require(block.timestamp > endDate, "Election not ended yet");
        _;
    }

    ///------------------------------------------------CONSTRUCTOR------------------------------------------------///
    constructor(string memory _name, string memory _description, uint _startDate,  uint _endDate, uint _nbEligibleVoters ){   
        require(_startDate > block.timestamp, "Start date already passed");   //Check if start date is not already passed   
        owner = msg.sender;
        electionName = _name;
        electionDescription = _description;
        startDate = _startDate;
        endDate = _endDate;
        nbEligibleVoters = _nbEligibleVoters;
    }

    ///------------------------------------------------METHODS------------------------------------------------///
    function addCandidate(string memory _name) ownerOnly public{
        Candidates.push(Candidate(_name,0, candidateIndex));
        candidateIndex++;
    }
     
    function authorized(address _person) ownerOnly public {
        voters[_person].authorized = true;
    }

    function vote(uint _candidateId) electionOngoing public {
        //One address can only vote once
        require(!voters[msg.sender].voted);
        require(!voters[msg.sender].authorized);

        voters[msg.sender].vote = _candidateId;
        voters[msg.sender].voted = true;

        Candidates[_candidateId].voteCount += 1;
        totalVotes += 1;
    }

    function getCandidates () public view returns (Candidate[] memory){
        return Candidates;
    }

    function getElectionInfo () public view returns (ElectionInfo memory) {
        uint nbCandidates = Candidates.length;
        return ElectionInfo(electionName, electionDescription,startDate, endDate, nbCandidates);
    }

    function getElectionResult () public view returns (ElectionResult memory) {
        uint nbCandidates = Candidates.length;
        return ElectionResult(nbCandidates,totalVotes,nbEligibleVoters,Candidates);
    }

       function getElected() electionFinished public view returns (Candidate memory) {
        require(Candidates.length > 0, "No candidates found");

        uint highestVoteCount = 0;
        uint winningCandidateIndex = 0;

        for (uint i = 0; i < Candidates.length; i++) {
            if (Candidates[i].voteCount > highestVoteCount) {
                highestVoteCount = Candidates[i].voteCount;
                winningCandidateIndex = i;
            }
        }

        return Candidates[winningCandidateIndex];
    }

    function getAbstentionRate() electionFinished public view returns (uint) {
        uint nbVoters = 0;

        for (uint i = 0; i < Candidates.length; i++) {
            nbVoters += Candidates[i].voteCount;
        }

        if (nbVoters == 0) {
            return 100; // everyone abstained
        } else {
            return ((nbEligibleVoters - nbVoters) * 100) / nbEligibleVoters;
        }
    }

    function getAbstentionNb() electionFinished public view returns (uint) {
        return nbEligibleVoters - totalVotes;
    }

    function getNbVoters() electionFinished public view returns (uint) {
        return totalVotes;
    }

 

    function isElectionFinished() public view returns (bool) {
        return block.timestamp > endDate;
    }

    function destroyContract() ownerOnly electionFinished public  {
        selfdestruct(payable(owner));
    }

}