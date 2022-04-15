/**
 *Submitted for verification at snowtrace.io on 2022-04-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: github/TheGrandNobody/eternal-contracts/contracts/interfaces/ITimelock.sol

/**
 * @dev Timelock interface
 * @author Nobody (me)
 * @notice Methods are used for all timelock-related functions
 */
interface ITimelock {
    // View the amount of time that a proposal must remain in queue
    function viewDelay() external view returns (uint256);
    // View the amount of time give to a proposal to be executed
    function viewGracePeriod() external pure returns (uint256);
    // View the address of the contract in line to be the next Eternal Fund
    function viewPendingFund() external view returns (address);
    // View the current Eternal Fund address
    function viewFund() external view returns (address);
    // View whether a given transaction hash is currently in queue
    function queuedTransaction(bytes32 hash) external view returns (bool);
    // Accepts the offer of becoming the Eternal Fund
    function acceptFund() external;
    // Queues all of a proposal's actions
    function queueTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external returns (bytes32);
    // Cancels all of a proposal's actions
    function cancelTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external;
    // Executes all of a proposal's actions
    function executeTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external payable returns (bytes memory);

    // Signals a transfer of admin roles
    event NewAdmin(address indexed newAdmin);
    // Signals the role of admin being offered to an individual
    event NewPendingAdmin(address indexed newPendingAdmin);
    // Signals an update of the minimum amount of time a proposal must wait before being queued
    event NewDelay(uint256 indexed newDelay);
    // Signals a proposal being canceled
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    // Signals a proposal being executed
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    // Signals a proposal being queued
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
}
// File: github/TheGrandNobody/eternal-contracts/contracts/interfaces/IEternalStorage.sol

/**
 * @dev Eternal Storage interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's variable storage
 */
interface IEternalStorage {
    // Scalar setters
    function setUint(bytes32 entity, bytes32 key, uint256 value) external;
    function setInt(bytes32 entity, bytes32 key, int256 value) external;
    function setAddress(bytes32 entity, bytes32 key, address value) external;
    function setBool(bytes32 entity, bytes32 key, bool value) external;
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external;

    // Scalar getters
    function getUint(bytes32 entity, bytes32 key) external view returns (uint256);
    function getInt(bytes32 entity, bytes32 key) external view returns (int256);
    function getAddress(bytes32 entity, bytes32 key) external view returns (address);
    function getBool(bytes32 entity, bytes32 key) external view returns (bool);
    function getBytes(bytes32 entity, bytes32 key) external view returns (bytes32);

    // Array setters
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external;
    function setIntArrayValue(bytes32 key, uint256 index, int256 value) external;
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external;
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external;
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external;

    // Array getters
    function getUintArrayValue(bytes32 key, uint256 index) external view returns (uint256);
    function getIntArrayValue(bytes32 key, uint256 index) external view returns (int256);
    function getAddressArrayValue(bytes32 key, uint256 index) external view returns (address);
    function getBoolArrayValue(bytes32 key, uint256 index) external view returns (bool);
    function getBytesArrayValue(bytes32 key, uint256 index) external view returns (bytes32);

    //Array Deleters
    function deleteUint(bytes32 key, uint256 index) external;
    function deleteInt(bytes32 key, uint256 index) external;
    function deleteAddress(bytes32 key, uint256 index) external;
    function deleteBool(bytes32 key, uint256 index) external;
    function deleteBytes(bytes32 key, uint256 index) external;

    //Array Length
    function lengthUint(bytes32 key) external view returns (uint256);
    function lengthInt(bytes32 key) external view returns (uint256);
    function lengthAddress(bytes32 key) external view returns (uint256);
    function lengthBool(bytes32 key) external view returns (uint256);
    function lengthBytes(bytes32 key) external view returns (uint256);
}
// File: github/TheGrandNobody/eternal-contracts/contracts/interfaces/IEternalFund.sol

/**
 * @dev Eternal Fund interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's governance functions
 */
interface IEternalFund {
    // Delegates the message sender's vote balance to a given user
    function delegate(address delegatee) external;
    // Determine the number of votes of a given account prior to a given block
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
    // Gets the current votes balance for a given account
    function getCurrentVotes(address account) external view returns (uint256);
    // Transfer part of a given delegates' voting balance to another new delegate
    function moveDelegates(address srcRep, address dstRep, uint256 amount) external;

    // Signals a change of a given user's delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    // Signals a change of a given delegate's vote balance
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
}
// File: github/TheGrandNobody/eternal-contracts/contracts/governance/EternalFund.sol

/**
 * @title The Eternal Fund contract
 * @author Taken from Compound Finance (COMP) and tweaked/detailed by Nobody (me)
 * @notice The Eternal Fund serves as the governing body of Eternal
 */
contract EternalFund is IEternalFund, Context {

/////–––««« Variables: Interfaces and Addresses »»»––––\\\\\
    // The name of this contract
    string public constant name = "Eternal Fund";
    // The keccak256 hash of the Eternal Token address
    bytes32 public immutable entity;

    // The timelock interface
    ITimelock public timelock;
    // The Eternal token interface
    IERC20 public eternal;
    // The Eternal storage interface
    IEternalStorage public eternalStorage;
    // The address of the Governor Guardian
    address public guardian;

/////–––««« Variable: Voting »»»––––\\\\\

    // The total number of proposals
    uint256 public proposalCount;

    // Holds all proposal data
    struct Proposal {
        uint256 id;                              // Unique id for looking up a proposal
        address proposer;                        // Creator of the proposal
        uint256 eta;                             // The timestamp that the proposal will be available for execution, set once the vote succeeds
        address[] targets;                       // The ordered list of target addresses for calls to be made
        uint256[] values;                        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        string[] signatures;                     // The ordered list of function signatures to be called
        bytes[] calldatas;                       // The ordered list of calldata to be passed to each call
        uint256 startTime;                       // The timestamp at which voting begins: holders must delegate their votes prior to this time
        uint256 endTime;                         // The timestamp at which voting ends: votes must be cast prior to this block
        uint256 startBlock;                      // The block at which voting began: holders must have delegated their votes prior to this block
        uint256 forVotes;                        // Current number of votes in favor of this proposal
        uint256 againstVotes;                    // Current number of votes in opposition to this proposal
        bool canceled;                           // Flag marking whether the proposal has been canceled
        bool executed;                           // Flag marking whether the proposal has been executed
        mapping (address => Receipt) receipts;   // Receipts of ballots for the entire set of voters
    }

    // Ballot receipt record for a voter
    struct Receipt {
        bool hasVoted;       // Whether or not a vote has been cast
        bool support;        // Whether or not the voter supports the proposal
        uint256 votes;        // The number of votes the voter had, which were cast
    }

    // Possible states that a proposal may be in
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

    // The official record of all proposals ever proposed
    mapping (uint256 => Proposal) public proposals;
    // The latest proposal for each proposer
    mapping (address => uint256) public latestProposalIds;

/////–––««« Variables: Voting by signature »»»––––\\\\\

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    // The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

/////–––««« Events »»»––––\\\\\

    // Emitted when a new proposal is created
    event ProposalCreated(uint256 id, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startTime, uint256 endTime, string description);
    // Emitted when the first vote is cast in a proposal
    event StartBlockSet(uint256 proposalId, uint256 startBlock);
    // Emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);
    // Emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    // Emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);
    // Emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

/////–––««« Constructor »»»––––\\\\\

    constructor (address _guardian, address _eternalStorage, address _eternal, address _timelock) {
        guardian = _guardian;
        eternalStorage = IEternalStorage(_eternalStorage);
        eternal = IERC20(_eternal);
        timelock = ITimelock(_timelock);

        entity = keccak256(abi.encodePacked(_eternal));
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\
    /** 
     * @notice The number of votes required in order for a voter to become a proposer.
     * @return 0.5 percent of the initial supply 
     */
    function proposalThreshold() public pure returns (uint256) { 
        return 5 * (10 ** 7) * (10 ** 18); // 50 000 000ETRNL = initially 0.5% (increases over time due to deflation)
    } 

    /**
     * @notice View the maximum number of operations that can be included in a proposal.
     * @return The maximum number of actions per proposal
     */
    function proposalMaxOperations() public pure returns (uint256) { 
        return 15; 
    }

    /**
     * @notice View the delay before voting on a proposal may take place, once proposed.
     * @return 1 day (in seconds)
     */
    function votingDelay() public pure returns (uint256) { 
        return 1 days; 
    }

    /**
     * @notice The duration of voting on a proposal, in blocks.
     * @return 3 days (in seconds)
     */
    function votingPeriod() public pure returns (uint256) { 
        return 3 days; 
    }

/////–––««« Governance logic functions »»»––––\\\\\

    /**
     * @notice Initiates a proposal.
     * @param targets An ordered list of contract addresses used to make the calls
     * @param values A list of values passed in each call
     * @param signatures A list of function signatures used to make the calls
     * @param calldatas A list of function parameter hashes used to make the calls
     * @param description A description of the proposal
     * @return The current proposal count
     *
     * Requirements:
     * 
     * - Proposer must have a voting balance equal to at least 0.5 percent of the initial ETRNL supply
     * - All lists must have the same length
     * - Lists must contain at least one element but no more than 15 elements
     * - Proposer can only have one live proposal at a time
     */
    function propose(address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint256) {
        require(getPriorVotes(msg.sender, block.number - 1) > proposalThreshold(), "Vote balance below threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Arity mismatch in proposal");
        require(targets.length != 0, "Must provide actions");
        require(targets.length <= proposalMaxOperations(), "Too many actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active && proposersLatestProposalState != ProposalState.Pending, "One live proposal per proposer");
        }

        uint256 startTime = block.timestamp + votingDelay();
        uint256 endTime = block.timestamp + votingPeriod() + votingDelay();

        proposalCount += 1;
        proposals[proposalCount].id = proposalCount;
        proposals[proposalCount].proposer = msg.sender;
        proposals[proposalCount].eta = 0;
        proposals[proposalCount].targets = targets;
        proposals[proposalCount].values = values;
        proposals[proposalCount].signatures = signatures;
        proposals[proposalCount].calldatas = calldatas;
        proposals[proposalCount].startTime = startTime;
        proposals[proposalCount].startBlock = 0;
        proposals[proposalCount].endTime = endTime;
        proposals[proposalCount].forVotes = 0;
        proposals[proposalCount].againstVotes = 0;
        proposals[proposalCount].canceled = false;
        proposals[proposalCount].executed = false;

        latestProposalIds[msg.sender] = proposalCount;

        emit ProposalCreated(proposalCount, msg.sender, targets, values, signatures, calldatas, startTime, endTime, description);
        return proposalCount;
    }

    /**
     * @notice Queues all of a given proposal's actions into the timelock contract.
     * @param proposalId The id of the specified proposal
     *
     * Requirements:
     *
     * - The proposal needs to have passed
     */
    function queue(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "Proposal state must be Succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp + timelock.viewDelay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    /**
     * @notice Queues an individual proposal action into the timelock contract.
     * @param target The address of the contract whose function is being called
     * @param value The amount of AVAX being transferred in this transaction
     * @param signature The function signature of this proposal's action
     * @param data The function parameters of this proposal's action
     * @param eta The estimated minimum UNIX time (in seconds) at which this transaction is to be executed 
     * 
     * Requirements:
     *
     * - The transaction should not have been queued
     */
    function _queueOrRevert(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) private {
        require(!timelock.queuedTransaction(keccak256(abi.encode(target, value, signature, data, eta))), "Proposal action already queued");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Executes all of a given's proposal's actions.
     * @param proposalId The id of the specified proposal
     * 
     * Requirements:
     *
     * - The proposal must already be in queue
     */
    function execute(uint256 proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "Proposal is not queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancels all of a given proposal's actions.
     * @param proposalId The id of the specified proposal
     * 
     * Requirements:
     *
     * - The proposal should not have been executed
     * - The proposer's vote balance should be below the threshold
     */
    function cancel(uint proposalId) public {
        ProposalState _state = state(proposalId);
        require(_state != ProposalState.Executed, "Cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold(), "Proposer above threshold");

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice View a given proposal's lists of actions.
     * @param proposalId The id of the specified proposal
     * @return targets The proposal's targets
     * @return values The proposal's values
     * @return signatures The proposal's signatures
     * @return calldatas The proposal's calldatas
     */
    function getActions(uint256 proposalId) public view returns (address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice View a given proposal's ballot receipt for a given voter.
     * @param proposalId The id of the specified proposal
     * @param voter The address of the specified voter
     * @return The ballot receipt of that voter for the proposal
     */
    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice View the state of a given proposal.
     * @param proposalId The id of the specified proposal
     * @return The state of the proposal
     *
     * Requirements:
     *
     * - Proposal must exist
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Invalid proposal id");
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
        } else if (block.timestamp >= proposal.eta + timelock.viewGracePeriod()) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Casts a vote for a given proposal.
     * @param proposalId The id of the specified proposal
     * @param support Whether the user is in support of the proposal or not
     */
    function castVote(uint256 proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    /**
     * @notice Casts a vote through signature.
     * @param proposalId The id of teh specified proposal
     * @param support Whether the user is in support of the proposal or not
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     * 
     * Requirements:
     *
     * - Must be a valid signature
     */
    function castVoteBySig(uint256 proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        uint chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly { chainId := chainid() }

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), chainId, address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    /**
     * @notice Casts a vote for a given voter and proposal.
     * @param voter The address of the specified voter
     * @param proposalId The id of the specified proposal
     * @param support Whether the voter is in support of the proposal or not
     *
     * Requirements:
     *
     * - Voting period for the proposal needs to be ongoing 
     * - The voter must not have already voted
     */
    function _castVote(address voter, uint256 proposalId, bool support) private {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.startBlock == 0) {
            proposal.startBlock = block.number - 1;
            emit StartBlockSet(proposalId, block.number);
        }
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Voter already voted");
        uint256 votes = getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = proposal.forVotes + votes;
        } else {
            proposal.againstVotes = proposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    /**
     * @notice Allow the Eternal Fund to take over control of the timelock contract.
     *
     * Requirements:
     *
     * - Only callable by the current guardian
     */
    function __acceptFund() public {
        require(msg.sender == guardian, "Caller must be the guardian");
        timelock.acceptFund();
    }

    /**
     * @notice Renounce the role of guardianship.
     *
     * Requirements:
     *
     * - Only callable by the current guardian
     */
    function __abdicate() public {
        require(msg.sender == guardian, "Caller must be the guardian");
        guardian = address(0);
    }

    /**
     * @notice Queues the transaction which will give governing power to the Eternal Fund.
     *
     * Requirements:
     *
     * - Only callable by the current guardian
     */
    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "Caller must be the guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    /**
     * @notice Executes the transaction which will give governing power to the Eternal Fund. 
     *
     * Requirements:
     *
     * - Only callable by the current guardian
     */
    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint256 eta) public {
        require(msg.sender == guardian, "Caller must be the guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

/////–––««« Governance-related functions »»»––––\\\\\

    /**
     * @notice Gets the current votes balance for a given account.
     * @param account The address of the specified account
     * @return The current number of votes of the account
     */
    function getCurrentVotes(address account) public view override returns (uint256) {
        uint256 nCheckpoints = eternalStorage.getUint(entity, keccak256(abi.encodePacked("numCheckpoints", account)));
        return eternalStorage.getUint(entity, keccak256(abi.encodePacked("votes", account, nCheckpoints - 1)));
    }

    /**
     * @notice Determine the number of votes of a given account prior to a given block.
     * @param account The address of specified account
     * @param blockNumber The number of the specified block
     * @return The number of votes of the account before/by this block
     *
     * Requirements:
     * 
     * - The given block must be finalized
     */
    function getPriorVotes(address account, uint256 blockNumber) public view override returns (uint256) {
        require(blockNumber < block.number, "Block is not yet finalized");
        uint256 nCheckpoints = eternalStorage.getUint(entity, keccak256(abi.encodePacked("numCheckpoints", account)));

        if (nCheckpoints == 0) {
            // No checkpoints means no votes
            return 0;
        } else if (eternalStorage.getUint(entity, keccak256(abi.encodePacked("blocks", account, nCheckpoints - 1))) <= blockNumber) {
            // Votes for the most recent checkpoint
            return eternalStorage.getUint(entity, keccak256(abi.encodePacked("votes", account, nCheckpoints - 1)));
        } else if (eternalStorage.getUint(entity, keccak256(abi.encodePacked("blocks", account, uint256(0)))) > blockNumber) {
            // Only having checkpoints after the given block number means no votes
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            uint256 thisBlock = eternalStorage.getUint(entity, keccak256(abi.encodePacked("blocks", account, center)));
            if (thisBlock == blockNumber) {
                return eternalStorage.getUint(entity, keccak256(abi.encodePacked("votes", account, center)));
            } else if (thisBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return eternalStorage.getUint(entity, keccak256(abi.encodePacked("votes", account, lower)));
    }

    /**
     * @notice Delegates the message sender's vote balance to a given user.
     * @param delegatee The address of the user to whom the vote balance is being added to
     */
    function delegate(address delegatee) external override {
        bytes32 _delegate = keccak256(abi.encodePacked("delegates", _msgSender()));
        address currentDelegate = eternalStorage.getAddress(entity, _delegate);
        uint256 delegatorBalance = eternal.balanceOf(_msgSender());

        eternalStorage.setAddress(entity, _delegate, delegatee);

        emit DelegateChanged(_msgSender(), currentDelegate, delegatee);

        moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
     * @notice Transfer part of a given delegates' voting balance to another new delegate.
     * @param srcRep The delegate from whom we are deducting votes
     * @param dstRep The delegate to whom we are transferring votes
     * @param amount The specified amount of votes
     */
    function moveDelegates(address srcRep, address dstRep, uint256 amount) public override {
        require(_msgSender() == address(this) || _msgSender() == address(eternal), "Only callable by Eternal");
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = eternalStorage.getUint(entity, keccak256(abi.encodePacked("numCheckpoints", srcRep)));
                uint256 srcRepOld = srcRepNum > 0 ? eternalStorage.getUint(entity, keccak256(abi.encodePacked("votes", srcRep, srcRepNum - 1))) : 0;
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = eternalStorage.getUint(entity, keccak256(abi.encodePacked("numCheckpoints", dstRep)));
                uint256 dstRepOld = dstRepNum > 0 ? eternalStorage.getUint(entity, keccak256(abi.encodePacked("votes", dstRep, dstRepNum - 1))) : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * @notice Update a given user's voting balance for the current block.
     * @param delegatee The address of the specified user
     * @param nCheckpoints The number of times the voting balance of the user has been updated
     * @param oldVotes The old voting balance of the user
     * @param newVotes The new voting balance of the user
     */
    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes,uint256 newVotes) private {
        if (nCheckpoints > 0 && eternalStorage.getUint(entity, keccak256(abi.encodePacked("blocks", delegatee, nCheckpoints - 1))) == block.number) {
            eternalStorage.setUint(entity, keccak256(abi.encodePacked("votes", delegatee, nCheckpoints - 1)), newVotes);
        } else {
            eternalStorage.setUint(entity, keccak256(abi.encodePacked("votes", delegatee, nCheckpoints)), newVotes);
            eternalStorage.setUint(entity, keccak256(abi.encodePacked("blocks", delegatee, nCheckpoints)), block.number);
            eternalStorage.setUint(entity, keccak256(abi.encodePacked("numCheckpoints", delegatee)), nCheckpoints + 1);
        }
        
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
}