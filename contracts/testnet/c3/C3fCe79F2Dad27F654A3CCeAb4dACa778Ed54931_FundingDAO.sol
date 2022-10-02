// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interfaces/IFundingNFT.sol";

error NotHaveRightToVote();
error ProposalIsNotActive();
error ProposalStillActive();
error onlyLeaderCall();
error onlyFunderCall();
error NotCommunityMember();
error AlreadyVoted();
error FundIsEnoughForThisProposal();
error FundingStillActive();

contract FundingDAO {
    struct Community {
        uint16 id;
        string name;
        string description;
        address leader;
        bool isElectionOpen;
        address[] members;
        uint256[] proposals; // proposalIds
    }

    struct Proposal {
        uint256 id;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline; // Deadline for the voting.
        uint256 fundingDeadline; // Deadline for the funding.
        uint256 requiredBudget; // Budget needed to implement.
        string problem;
        string howToRegenerate;
        uint16 community; // Id to Community.
        Goal[] goals;
        mapping(address => bool) voters;
        mapping(address => uint256) fundsBy;
        uint256 funds;
        bool executed;
        ProposalStatus status;
    } // reporting

    enum ProposalStatus {
        NOT_STARTED,
        CONTINUE,
        FINISHED
    }
    //crossover
    enum Vote {
        YES,
        NO
    }

    enum Goal {
        NO_PROVERTY,
        ZERO_HUNGER,
        GOOD_HEALTH_AND_WELL_BEING,
        QUALITY_EDUCATION,
        GENDER_QUALITY,
        GREEN_WATER,
        AFFORDABLE_AND_CLEAN_ENERGY,
        DEVENT_WORK_AND_ECONOMIC_GROWTH,
        INDUSTRY_INNOVATION_AND_INFTRASTRUCTURE,
        REDUCES_INEQUALITIES,
        SUSTAINABLE_CITIES_AND_COMMUNITIES,
        RESPONSIBLE_CONSUPTION_AND_PRODUCTION,
        CLIMATE_ACTION,
        LIFE_BELOW_WATER,
        LIFE_ON_LAND,
        PEACT_JUSTICE_AND_STRONG_INSTITUTIONS,
        PARTNERSHIPS_FOR_THE_GOALS
    }
    //hyperstructures zora jacob?
    uint256 proposalCounts;
    mapping(uint256 => Proposal) public proposals;

    uint16 communityCounts;
    mapping(uint16 => Community) public communities;
    mapping(address => uint16) public communityMembers;

    mapping(address => uint256) public membersTheVote; // leader choosing
    mapping(address => bool) public isMemberVoted;
    /**
     *  Community Id To Proposal array.
     *  Let users know, which proposals who created.
     */
    IFundingNFT fundingNFT;

    event memberLeftTheCommunity(address member);
    event communityCreated(uint16 id);
    event proposalCreated(uint256 id);

    modifier onlyLeader() {
        if (!fundingNFT.isLeader(msg.sender)) revert onlyLeaderCall();
        _;
    }

    modifier onlyMembers(uint16 communityId) {
        if (communityMembers[msg.sender] != communityId)
            revert NotCommunityMember();
        _;
    }

    modifier activeProposal(uint256 proposalId) {
        if (block.timestamp < proposals[proposalId].deadline)
            revert ProposalIsNotActive();
        _;
    }

    modifier finishedProposal(uint256 proposalId) {
        if (block.timestamp > proposals[proposalId].deadline)
            revert ProposalStillActive();
        _;
    }

    modifier fundingFinished(uint256 proposalId) {
        if (block.timestamp > proposals[proposalId].fundingDeadline)
            revert FundingStillActive();
        _;
    }

    modifier needFund(uint256 proposalId) {
        if (
            proposals[proposalId].funds + msg.value >
            proposals[proposalId].requiredBudget
        ) revert FundIsEnoughForThisProposal();
        _;
    }

    constructor(address _fundingNFT) {
        fundingNFT = IFundingNFT(_fundingNFT);
    }

    function createCommunity(
        string memory _name,
        string memory _description,
        address[4] calldata membersAddresses
    ) external {
        Community storage newCommunity = communities[communityCounts];
        newCommunity.id = communityCounts;
        newCommunity.name = _name;
        newCommunity.description = _description;
        communityMembers[msg.sender] = communityCounts;
        newCommunity.members.push(msg.sender);
        for (uint256 i; i < membersAddresses.length; i++) {
            newCommunity.members.push(membersAddresses[i]);
        }
        emit communityCreated(communityCounts);
        communityCounts++;
    }

    function startALeaderElection() external {
        Community storage community = communities[communityMembers[msg.sender]];
        require(community.isElectionOpen == false, "Election already open.");
        community.isElectionOpen = true;
    }

    function voteForLeader(address leaderAddress) external {
        Community storage community = communities[communityMembers[msg.sender]];
        require(
            community.id == communityMembers[leaderAddress],
            "Leader must be in your community."
        );
        require(community.isElectionOpen == true, "Election is not open.");
        require(isMemberVoted[msg.sender] == false, "Member already voted.");
        isMemberVoted[msg.sender] = true;
        membersTheVote[leaderAddress] += 1;
        if (community.leader != address(0)) {}
        if (membersTheVote[leaderAddress] * 2 > community.members.length) {
            community.leader = leaderAddress;
            fundingNFT.setLeader(leaderAddress);
            community.isElectionOpen = false;
        }
    }

    function addMembersToCommunity(address[] calldata memberAddresses)
        external
        onlyLeader
    {
        fundingNFT.setMembers(memberAddresses);
        for (uint256 i; i < memberAddresses.length; i++) {
            communities[communityMembers[msg.sender]].members.push(
                memberAddresses[i]
            );
        }
    }

    function leftTheCommunity(uint16 communityId)
        external
        onlyMembers(communityId)
    {
        fundingNFT.exitTheCommunity();
        delete communityMembers[msg.sender];
    }

    function createProposal(
        uint256 _requiredBudget,
        string memory _problem,
        string memory howTo,
        Goal[] calldata goals
    ) external onlyLeader {
        Community storage community = communities[communityMembers[msg.sender]];
        Proposal storage newProposal = proposals[proposalCounts];
        newProposal.id = proposalCounts;
        newProposal.deadline = block.timestamp + 2 days;
        newProposal.requiredBudget = _requiredBudget;
        newProposal.problem = _problem;
        newProposal.howToRegenerate = howTo;
        newProposal.community = communityMembers[msg.sender];
        for (uint256 i; i < goals.length; i++) {
            newProposal.goals.push(goals[i]);
        }
        community.proposals.push(newProposal.id);
        emit proposalCreated(proposalCounts);
        proposalCounts++;
    }

    function voteToProposal(uint256 proposalId, Vote vote)
        external
        activeProposal(proposalId)
    {
        require(
            fundingNFT.balanceOf(msg.sender) > 0,
            "You don't have any NFT."
        );
        Proposal storage proposal = proposals[proposalId];
        require(
            communities[proposal.community].leader !=
                communities[communityMembers[msg.sender]].leader,
            "You can't vote your own proposal."
        );
        if (proposal.voters[msg.sender] == true) {
            revert AlreadyVoted();
        }
        if (vote == Vote.YES) {
            proposal.yesVotes += 1;
        }
        if (vote == Vote.NO) {
            proposal.noVotes += 1;
        }
    }

    function executeProposal(uint256 proposalIndex)
        external
        finishedProposal(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(
            communities[proposal.community].leader == msg.sender,
            "The person who opened can execute."
        );
        require(
            proposal.yesVotes > proposal.noVotes,
            "Proposal couldn't pass the vote."
        );
        require(!proposal.executed, "Already executed.");
        proposal.executed = true;
        proposal.fundingDeadline = block.timestamp + 10 days;
    }

    function changeProposalStatus(uint256 proposalIndex, ProposalStatus _status)
        external
        onlyLeader
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.executed == true, "Proposal is not executed.");
        proposal.status = _status;
    }

    function fundToProposal(uint256 proposalIndex)
        external
        payable
        needFund(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.executed, "Proposal is not executed.");
        proposal.funds += msg.value;
        proposal.fundsBy[msg.sender] += msg.value;
        uint256 difference = proposal.funds - proposal.requiredBudget;
        if (difference > 0) {
            proposal.funds = proposal.requiredBudget;
            proposal.fundsBy[msg.sender] -= difference;
            (bool success, ) = msg.sender.call{value: difference}("");
            require(success, "Failed to sent.");
        }
    }

    function getFundsFromProposal(uint256 proposalIndex)
        external
        payable
        finishedProposal(proposalIndex)
        fundingFinished(proposalIndex)
        onlyLeader
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(
            msg.sender == communities[proposal.community].leader,
            "Nonauthorized!"
        );
        (bool success, ) = communities[proposal.community].leader.call{
            value: proposal.funds
        }("");
        require(success, "Failed to sent.");
    }

    function refundFunders(uint256 proposalIndex, uint256 _amount)
        external
        payable
        finishedProposal(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.executed == false, "Project already executed.");
        require(proposal.fundsBy[msg.sender] > 0, "You have no funds.");
        proposal.fundsBy[msg.sender] -= _amount;
        proposal.funds -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to sent.");
    }

    function getCommunity(uint16 communityId)
        external
        view
        returns (
            uint16 id,
            string memory name,
            string memory description,
            address leader,
            address[] memory members
        )
    // uint256[] memory proposalIds
    {
        Community storage community = communities[communityId];
        return (
            community.id,
            community.name,
            community.description,
            community.leader,
            community.members
            // community.proposals //*/!
        );
    }

    function getCommunitiesProposals(uint16 communityId)
        external
        view
        returns (uint256[] memory)
    {
        Community storage community = communities[communityId];
        return community.proposals;
    }

    function getLeaderOfTheCommunity(uint16 communityId)
        external
        view
        returns (address)
    {
        require(
            communities[communityId].leader != address(0),
            "There is no leader."
        );
        return communities[communityId].leader;
    }

    function getProposalGoals(uint256 proposalId)
        external
        view
        returns (Goal[] memory goals)
    {
        return proposals[proposalId].goals;
    }

    function getProposalStatus(uint256 proposalId)
        external
        view
        returns (ProposalStatus)
    {
        return proposals[proposalId].status;
    }

    function isProposalExecuted(uint256 proposalId)
        external
        view
        returns (bool)
    {
        return proposals[proposalId].executed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFundingNFT {
    error OnlyLeaderCanCallTheFunction();
    error OnlyMembersCanCallTheFunction();
    error MemberHasAlreadyHasNFT();
    error YouCanHaveJustOneNFT();
    error InsufficientFunds();

    enum Breed {
        CommunityMemberNFT,
        CommunityLeaderNFT
    }

    enum Person {
        USER,
        MEMBER,
        LEADER
    }

    /**
     *  The caller can only be owner of the contract.
     *  User in given address will qualify for mint leader NFT.
     */
    function setLeader(address leaderAddress) external;

    /**
     *  The caller can only be a leader.
     *  Users in member addresses array will qualify for mint member NFT.
     */
    function setMembers(address[] calldata memberAddresses) external;

    function mintFunderNFT() external;

    /**
     *  Owner of the contract must run setLeader before the function.
     *  The caller can only be a leader.
     */
    function mintLeaderNFT() external;

    /**
     *  One leader must run setMembers function before the function.
     *  The caller can only be a member.
     */
    function mintMemberNFT() external;

    /**
     *  Only members can exit their communities.
     *  If a member run this function their NFT's are burns.
     *  And they lose their voting rights.
     */
    function exitTheCommunity() external;

    function isFunder(address funderAddress) external view returns (bool);

    /**
     *  Is given address a leader?
     */
    function isLeader(address leaderAddress) external view returns (bool);

    /**
     *  Is given address a member?
     */
    function isMember(address memberAddress) external view returns (bool);

    function getTokenId(address tokenOwner) external view returns (uint256);

    function getTokenUris(uint256 index) external view returns (string memory);

    function getTokenCounter() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getUserStatus() external view returns (Person);
}