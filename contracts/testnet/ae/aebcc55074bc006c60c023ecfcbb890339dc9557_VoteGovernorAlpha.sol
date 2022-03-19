/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-18
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File contracts/VoteGovernorAlpha.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract VoteGovernorAlpha {
    // @notice The name of this contract
    string private name;
    uint256 private votingDelay;
    uint256 private votingPeriod;
    uint256 private proposalThreshold;
    uint256 private votingThreshold;

    function getName() public view returns (string memory) {
        return name;
    }

    // @notice The number of votes required in order for a voter to become a proposer
    function getProposalThreshold() public view returns (uint256) { return proposalThreshold; }

    // @notice The number of votes required in order for a voter to vote on a proposal
    function getVotingThreshold() public view returns (uint256) { return votingThreshold; }

    // @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    // @notice The delay before voting on a proposal may take place, once proposed
    function getVotingDelay() public view returns (uint256) { return votingDelay; }

    // @notice The duration of voting on a proposal, in blocks
    function getVotingPeriod() public view returns (uint256) { return votingPeriod; }

    // @notice The address of the Pangolin Protocol Timelock
    VoteTimelockInterface public timelock;

    // @notice The address of the Pangolin governance token
    VoteTokenInterface public voteToken;

    // @notice The address of the Governor Guardian
    address public guardian;

    // @notice The total number of proposals
    uint256 public proposalCount;

    struct Proposal {
        // @notice Unique id for looking up a proposal
        uint256 id;

        // @notice THe title of the proposal
        string title;

        // @notice Creator of the proposal
        address proposer;

        // @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;

        // @notice the ordered list of target addresses for calls to be made
        address[] targets;

        // @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        // @notice The ordered list of function signatures to be called
        string[] signatures;

        // @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // @notice The timestamp at which voting begins: holders must delegate their votes prior to this time
        uint256 startTime;

        // @notice The timestamp at which voting ends: votes must be cast prior to this block
        uint256 endTime;

        // @notice The block at which voting began: holders must have delegated their votes prior to this block
        uint256 startBlock;

        // @notice Current number of votes in favor of this proposal
        uint256 forVotes;

        // @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;

        // @notice Flag marking whether the proposal has been canceled
        bool canceled;

        // @notice Flag marking whether the proposal has been executed
        bool executed;

        // @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    // @notice Ballot receipt record for a voter
    struct Receipt {
        // @notice Whether or not a vote has been cast
        bool hasVoted;

        // @notice Whether or not the voter supports the proposal
        bool support;

        // @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    // @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    // @notice The official record of all proposals ever proposed
    mapping (uint256 => Proposal) public proposals;

    // @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    // @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    // @notice An event emitted when a new proposal is created
    // event ProposalCreated(address govAddress, uint256 proposalId, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint256 startTime, uint256 endTime, string title, string description);
    event ProposalCreated(address govAddress, uint256 proposalId, address proposer, uint256 startTime, uint256 endTime, string title, string description);

    // @notice An event emitted when the first vote is cast in a proposal
    event StartBlockSet(address govAddress, uint256 proposalId, uint256 startBlock);

    // @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address govAddress, address voter, uint256 proposalId, bool support, uint256 votes);

    // @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(address govAddress, uint256 proposalId);

    // @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(address govAddress, uint256 proposalId, uint256 eta);

    // @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(address govAddress, uint256 proposalId);

    constructor(string memory _name, address _voteTimelock, address _voteToken, address _guardian, uint256 _votingDelay, 
            uint256 _votingPeriod, uint256 _proposalThreshold, uint256 _votingThreshold) {
        name = _name;
        timelock = VoteTimelockInterface(_voteTimelock);
        voteToken = VoteTokenInterface(_voteToken);
        guardian = _guardian;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        votingThreshold = _votingThreshold;
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, 
            string memory title, string memory description) public returns (uint) {
        require(voteToken.getPriorVotes(msg.sender, block.number - 1) > proposalThreshold, "GovernorAlpha::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
        //for phase one, we will allow non-transaction proposals.
        //require(targets.length != 0, "GovernorAlpha::propose: must provide actions"); 
        require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint256 startTime = block.timestamp + votingDelay;
        uint256 endTime = block.timestamp + votingPeriod + votingDelay;

        proposalCount++;
        //Proposal storage newProposal = proposals[proposalCount++];
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title           = title;
        newProposal.proposer        = msg.sender;
        newProposal.eta             = 0;
        newProposal.targets         = targets;
        newProposal.values          = values;
        newProposal.signatures      = signatures;
        newProposal.calldatas       = calldatas;
        newProposal.startTime       = startTime;
        newProposal.startBlock      = 0;
        newProposal.endTime         = endTime;
        newProposal.forVotes        = 0;
        newProposal.againstVotes    = 0;
        newProposal.canceled        = false;
        newProposal.executed        = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        // emit ProposalCreated(address(this), newProposal.id, msg.sender, targets, values, signatures, calldatas, startTime, endTime, title, description);
        emit ProposalCreated(address(this), newProposal.id, msg.sender, startTime, endTime, title, description);
        return newProposal.id;
    }

    function getProposalData(uint256 proposalId) public view 
        returns (
            uint256 proposalId_,
            string memory proposalTitle_,
            address proposer_,
            uint256 startTime_,
            uint256 endTime_,
            uint256 startBlock_,
            uint256 forVotes_,
            uint256 againstVotes_,
            bool canceled_,
            bool executed_,
            ProposalState state_
        ) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::getProposalData: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        proposalId_ = proposal.id;
        proposalTitle_ = proposal.title;
        proposer_ = proposal.proposer;
        startTime_ = proposal.startTime;
        endTime_ = proposal.endTime;
        startBlock_ = proposal.startBlock;
        forVotes_ = proposal.forVotes;
        againstVotes_ = proposal.againstVotes;
        canceled_ = proposal.canceled;
        executed_ = proposal.executed;
        state_ = state(proposalId);
    }

    function queue(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp + timelock.delay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(address(this), proposalId, eta);
    }

    function _queueOrRevert(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint256 proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(address(this), proposalId);
    }

    function cancel(uint256 proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(voteToken.getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold, "GovernorAlpha::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(address(this), proposalId);
    }

    function getActions(uint256 proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + timelock.GRACE_PERIOD()) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint256 proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint256 proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint256 proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.startBlock == 0) {
            proposal.startBlock = block.number - 1;
            emit StartBlockSet(address(this), proposalId, block.number);
        }
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
        uint96 votes = voteToken.getPriorVotes(voter, proposal.startBlock);
        require(votes >= votingThreshold, "Not enough tokens to vote");

        if (support) {
            proposal.forVotes = proposal.forVotes + votes;
        } else {
            proposal.againstVotes = proposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(address(this), voter, proposalId, support, votes);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "GovernorAlpha::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "GovernorAlpha::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface VoteTimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external returns (bytes32);
    function cancelTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external;
    function executeTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external payable returns (bytes memory);
}

interface VoteTokenInterface {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}