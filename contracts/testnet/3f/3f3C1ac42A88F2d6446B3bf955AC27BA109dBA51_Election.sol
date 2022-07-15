// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Election {
    string public electionName;
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votes;
    mapping(address => bool) public isCandidate;
    mapping(address => string) public candidateNames;
    address[] public voters;
    address[] public candidates;
    address public owner;
    bool public forceClosed = false;
    uint256 public electionEndTime;
    uint256 public electionStartTime;
    // New candidate fee: 0.05 ETH
    uint256 public candidateFee = 0.05 * 10**18;

    constructor(
        address _owner,
        string memory _electionName,
        uint256 _electionEndTime
    ) {
        owner = _owner;
        electionName = _electionName;
        electionEndTime = _electionEndTime;
        electionStartTime = block.timestamp;
    }

    function runForElection(string memory _candidateName)
        public
        payable
        onlyElectionRunning
    {
        require(
            isCandidate[msg.sender] == false,
            "You are already a candidate!"
        );
        require(msg.value >= candidateFee, "Candidate fee not met.");
        isCandidate[msg.sender] = true;
        candidateNames[msg.sender] = _candidateName;
        candidates.push(msg.sender);
    }

    function vote(address _candidate) public payable onlyElectionRunning {
        require(
            hasVoted[msg.sender] == false,
            "You have already voted for somebody!"
        );
        require(
            isCandidate[_candidate] == true,
            "That person is not a candidate."
        );
        votes[_candidate] += 1;
        hasVoted[msg.sender] = true;
        voters.push(msg.sender);
    }

    function seeRevenue() public view returns (uint256) {
        return address(this).balance;
    }

    function getNumVotes(address _candidate) public view returns (uint256) {
        return votes[_candidate];
    }

    function getCandidates() public view returns (address[] memory) {
        return candidates;
    }

    function withdrawRevenue() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getVoters() public view returns(address[] memory) {
        return voters;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "This function is restricted to the owner."
        );
        _;
    }

    modifier onlyElectionRunning() {
        assert(isClosed() == false);
        _;
    }

    function close() public onlyOwner {
        forceClosed = true;
        electionEndTime = block.timestamp;
    }

    function isClosed() public view returns (bool) {
        return forceClosed == true || block.timestamp > electionEndTime;
    }

    // Returns an array of the candidates with the highest number of votes.
    // If there isn't a tie, the return array will have a length of 1.
    // If there is a tie, it will be longer than one.
    // Why did I bother coding this into my contract? Well, I thought it would be a fun challenge :)
    function getHighestVotes() public view returns (address[] memory) {
        assert(candidates.length > 0);
        if (candidates.length == 1) {
            address[] memory highest = new address[](1);
            highest[0] = candidates[0];
            return highest;
        }
        address[] memory highest = new address[](1);
        highest[0] = candidates[0];

        for (uint256 i = 1; i < candidates.length; i++) {
            if (votes[candidates[i]] > votes[highest[0]]) {
                highest = new address[](1);
                highest[0] = candidates[i];
            } else if (votes[candidates[i]] == votes[highest[0]]) {
                address[] memory temp = new address[](highest.length + 1);
                for (uint256 j; j < highest.length; j++) {
                    temp[j] = highest[j];
                }
                temp[highest.length] = candidates[i];
                highest = temp;
            }
        }
        return highest;
    }
}