/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-27
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-13
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.9;

// import "./IExecutor.sol";

interface IGovernance {
    /**
     * @dev List of available states of proposal
     * @param Pending When the proposal is creted and the votingDelay is not passed
     * @param Canceled When the proposal is calceled
     * @param   Active When the proposal is on voting
     * @param  Failed Whnen the proposal is not passes the quorum
     * @param  Succeeded When the proposal is passed
     * @param   Expired When the proposal is expired (the execution period passed)
     * @param  Executed When the proposal is executed
     **/
    enum ProposalState {
        Pending,
        Canceled,
        Active,
        Failed,
        Succeeded,
        Expired,
        Executed
    }

    /**
     * @dev Struct of a votes
     * @param support is the user suport proposal or not
     * @param votingPower amount of voting  power
     * @param submitTimestamp date when vote was submitted
     **/
    struct Vote {
        bool support;
        uint248 votingPower;
        uint256 submitTimestamp;
    }

    /**
     * @dev Struct of a proposal with votes
     * @param id Id of the proposal
     * @param creator Creator address
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block.timestamp when the proposal was started
     * @param endTimestamp block.timestamp when the proposal will ended
     * @param executionTime block.timestamp of the minimum time when the propsal can be execution, if set 0 it can't be executed yet
     * @param forVotes amount of For votes
     * @param againstVotes amount of Against votes
     * @param executed true is proposal is executes, false if proposal is not executed
     * @param canceled true is proposal is canceled, false if proposal is not canceled
     * @param strategy the address of governanceStrategy contract for current proposal voting power calculation
     * @param ipfsHash IPFS hash of the proposal
     * @param lottoVotes lotto tokens voting power portion
     * @param gameVotes game tokens voting power portion
     * @param votes the Vote struct where is hold mapping of users who voted for the proposal
     **/
    struct Proposal {
        uint256 id;
        address creator;
        IExecutor executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        bytes32 ipfsHash;
        uint256 lottoVotes;
        uint256 gameVotes;
        mapping(address => Vote) votes;
    }

    /**
     * @dev Struct of a proposal without votes
     * @param id Id of the proposal
     * @param creator Creator address
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block.timestamp when the proposal was started
     * @param endTimestamp block.timestamp when the proposal will ended
     * @param executionTime block.timestamp of the minimum time when the propsal can be execution, if set 0 it can't be executed yet
     * @param forVotes amount of For votes
     * @param againstVotes amount of Against votes
     * @param executed true is proposal is executes, false if proposal is not executed
     * @param canceled true is proposal is canceled, false if proposal is not canceled
     * @param strategy the address of governanceStrategy contract for current proposal voting power calculation
     * @param ipfsHash IPFS hash of the proposal
     * @param lottoVotes lotto tokens voting power portion
     * @param gameVotes game tokens voting power portion
     **/
    struct ProposalWithoutVotes {
        uint256 id;
        address creator;
        IExecutor executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        bytes32 ipfsHash;
        uint256 lottoVotes;
        uint256 gameVotes;
    }

    /**
     * @dev emitted when a new proposal is created
     * @param id Id of the proposal
     * @param creator address of the creator
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block number when vote starts
     * @param endTimestamp block number when vote ends
     * @param strategy address of the governanceStrategy contract
     * @param ipfsHash IPFS hash of the proposal
     **/
    event ProposalCreated(
        uint256 id,
        address indexed creator,
        IExecutor indexed executor,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 executionTimestamp,
        address strategy,
        bytes32 ipfsHash
    );

    /**
     * @dev emitted when a proposal is canceled
     * @param id Id of the proposal
     **/
    event ProposalCanceled(uint256 id);

    /**
     * @dev emitted when a proposal is executed
     * @param id Id of the proposal
     * @param initiatorExecution address of the initiator of the execution transaction
     **/
    event ProposalExecuted(uint256 id, address indexed initiatorExecution);
    /**
     * @dev emitted when a vote is registered
     * @param id Id of the proposal
     * @param voter address of the voter
     * @param support boolean, true = vote for, false = vote against
     * @param votingPower Power of the voter/vote
     **/
    event VoteEmitted(
        uint256 id,
        address indexed voter,
        bool support,
        uint256 votingPower
    );

    /**
     * @dev emitted when a new governance strategy set
     * @param newStrategy address of new strategy
     * @param initiatorChange msg.sender address
     **/
    event GovernanceStrategyChanged(
        address indexed newStrategy,
        address indexed initiatorChange
    );

    /**
     * @dev emitted when a votingDelay is changed
     * @param newVotingDelay new voting delay in seconds
     * @param initiatorChange msg.sender address
     **/
    event VotingDelayChanged(
        uint256 newVotingDelay,
        address indexed initiatorChange
    );

    /**
     * @dev emitted when a executor is authorized
     * @param executor new address of executor
     **/
    event ExecutorAuthorized(address executor);
    /**
     * @dev emitted when a executor is unauthorized
     * @param executor  address of executor
     **/
    event ExecutorUnauthorized(address executor);

    /**
     * @dev emitted when a community reward percent is changed
     * @param communityReward  percent of community reward
     **/
    event CommunityRewardChanged(uint256 communityReward);

    /**
     * @dev emitted when a governance reward percent is changed
     * @param governanceReward  percent of governance reward
     **/
    event GovernanceRewardChanged(uint256 governanceReward);

    /**
     * @dev Creates a Proposal (needs Voting Power of creator > propositionThreshold)
     * @param executor - The Executor contract that will execute the proposal
     * @param targets - list of contracts called by proposal's associated transactions
     * @param values - list of value in wei for each propoposal's associated transaction
     * @param signatures - list of function signatures (can be empty) to be used when created the callData
     * @param calldatas - list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param ipfsHash - IPFS hash of the proposal
     **/
    function createProposal(
        IExecutor executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bytes32 ipfsHash
    ) external returns (uint256);

    /**
     * @dev Cancels a Proposal,
     * either at anytime by guardian
     * or when proposal is Pending/Active and threshold of creator no longer reached
     * @param proposalId id of the proposal
     **/
    function cancelProposal(uint256 proposalId) external;

    /**
     * @dev Execute the proposal (If Proposal Succeeded)
     * @param proposalId id of the proposal to execute
     **/
    function executeProposal(uint256 proposalId) external payable;

    /**
     * @dev Function allowing msg.sender to vote for/against a proposal
     * @param proposalId id of the proposal
     * @param support boolean, true = vote for, false = vote against
     **/
    function submitVote(uint256 proposalId, bool support) external;

    /**
     * @dev Set new GovernanceStrategy
     * @notice owner should be a  executor, so needs to make a proposal
     * @param governanceStrategy new Address of the GovernanceStrategy contract
     **/
    function setGovernanceStrategy(address governanceStrategy) external;

    /**
     * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
     * @notice owner should be a  executor, so needs to make a proposal
     * @param votingDelay new voting delay in seconds
     **/
    function setVotingDelay(uint256 votingDelay) external;

    /**
     * @dev Add new addresses to the list of authorized executors
     * @notice owner should be a  executor, so needs to make a proposal
     * @param executors list of new addresses to be authorized executors
     **/
    function authorizeExecutors(address[] calldata executors) external;

    /**
     * @dev Remove addresses from the list of authorized executors
     * @notice owner should be a  executor, so needs to make a proposal
     * @param executors list of addresses to be removed as authorized executors
     **/
    function unauthorizeExecutors(address[] calldata executors) external;

    /**
     * @dev Let the guardian abdicate from its priviledged rights.Set _guardian address as zero address
     * @notice can be called only by _guardian
     **/
    function abdicate() external;

    /**
     * @dev Getter of the current GovernanceStrategy address
     * @return The address of the current GovernanceStrategy contract
     **/
    function getGovernanceStrategy() external view returns (address);

    /**
     * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
     * Different from the voting duration
     * @return The voting delay in seconds
     **/
    function getVotingDelay() external view returns (uint256);

    /**
     * @dev Returns whether an address is an authorized executor
     * @param executor address to evaluate as authorized executor
     * @return true if authorized, false is not authorized
     **/
    function isExecutorAuthorized(address executor)
        external
        view
        returns (bool);

    /**
     * @dev Getter the address of the guardian, that can mainly cancel proposals
     * @return The address of the guardian
     **/
    function getGuardian() external view returns (address);

    /**
     * @dev Getter of the proposal count (the current number of proposals ever created)
     * @return the proposal count
     **/
    function getProposalsCount() external view returns (uint256);

    /**
     * @dev Getter of a proposal by id
     * @param proposalId id of the proposal to get
     * @return the proposal as ProposalWithoutVotes memory object
     **/
    function getProposalById(uint256 proposalId)
        external
        view
        returns (ProposalWithoutVotes memory);

    /**
     * @dev Getter of the Vote of a voter about a proposal
     * @notice Vote is a struct: ({bool support, uint248 votingPower})
     * @param proposalId id of the proposal
     * @param voter address of the voter
     * @return The associated Vote memory object
     **/
    function getVoteOnProposal(uint256 proposalId, address voter)
        external
        view
        returns (Vote memory);

    /**
     * @dev Get the current state of a proposal
     * @param proposalId id of the proposal
     * @return The current state if the proposal
     **/
    function getProposalState(uint256 proposalId)
        external
        view
        returns (ProposalState);
}

pragma solidity 0.8.9;

// import "./IGovernance.sol";

interface IExecutor {
    /**
     * @dev emitted when a new pending admin is set
     * @param newPendingAdmin address of the new pending admin
     **/
    event NewPendingAdmin(address newPendingAdmin);

    /**
     * @dev emitted when a new admin is set
     * @param newAdmin address of the new admin
     **/
    event NewAdmin(address newAdmin);

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param resultData the actual callData used on the target
     **/
    event ExecutedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bytes resultData
    );

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view returns (address);

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view returns (address);

    /**
     * @dev Checks whether a proposal is over its grace period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over grace period
     **/
    function isProposalOverExecutionPeriod(
        IGovernance governance,
        uint256 proposalId
    ) external view returns (bool);

    /**
     * @dev Getter of execution period constant
     * @return grace period in seconds
     **/
    function executionPeriod() external view returns (uint256);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 executionTime
    ) external payable returns (bytes memory);
}

pragma solidity 0.8.9;

// import "./IGovernance.sol";

interface IProposalValidator {
    /**
     * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
     * @param governance Governance Contract
     * @param user Address of the proposal creator
     * @return boolean, true if can be created
     **/
    function validateCreatorOfProposal(
        IGovernance governance,
        address user,
        uint256 blockTimestamp
    ) external view returns (bool);

    /**
     * @dev Called to validate the cancellation of a proposal
     * @param governance Governance Contract
     * @param user Address of the proposal creator
     * @return boolean, true if can be cancelled
     **/
    function validateProposalCancellation(
        IGovernance governance,
        address user,
        uint256 blockTimestamp
    ) external view returns (bool);

    /**
     * @dev Returns whether a user has enough Proposition Power to make a proposal.
     * @param governance Governance Contract
     * @param user Address of the user to be challenged.
     * @return true if user has enough power
     **/
    function isPropositionPowerEnough(
        IGovernance governance,
        address user,
        uint256 blockTimestamp
    ) external view returns (bool);

    /**
     * @dev Returns the minimum Proposition Power needed to create a proposition.
     * @param governance Governance Contract
     * @return minimum Proposition Power needed
     **/
    function getMinimumPropositionPowerNeeded(IGovernance governance)
        external
        view
        returns (uint256);

    /**
     * @dev Returns whether a proposal passed or not
     * @param governance Governance Contract
     * @param proposalId Id of the proposal to set
     * @return true if proposal passed
     **/
    function isProposalPassed(IGovernance governance, uint256 proposalId)
        external
        view
        returns (bool);

    /**
     * @dev Check whether a proposal has reached quorum, ie has enough FOR-voting-power
     * @param governance Governance Contract
     * @param proposalId Id of the proposal to verify
     * @return voting power needed for a proposal to pass
     **/
    function isQuorumValid(IGovernance governance, uint256 proposalId)
        external
        view
        returns (bool);

    /**
     * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
     * FOR VOTES - AGAINST VOTES > VOTE_DIFFERENTIAL * voting supply
     * @param governance Governance Contract
     * @param proposalId Id of the proposal to verify
     * @return true if enough For-Votes
     **/
    function isVoteDifferentialValid(IGovernance governance, uint256 proposalId)
        external
        view
        returns (bool);

    /**
     * @dev Calculates the minimum amount of Voting Power needed for a proposal to Pass
     * @param votingSupply Total number of oustanding voting tokens
     * @return voting power needed for a proposal to pass
     **/
    function getMinimumVotingPowerNeeded(uint256 votingSupply)
        external
        view
        returns (uint256);

    /**
     * @dev Get proposition threshold constant value
     * @return the proposition threshold value (100 <=> 1%)
     **/
    function propositionThreshold() external view returns (uint256);

    /**
     * @dev Get voting duration constant value
     * @return the voting duration value in seconds
     **/
    function votingDuration() external view returns (uint256);

    /**
     * @dev Get the vote differential threshold constant value
     * to compare with % of for votes/total supply - % of against votes/total supply
     * @return the vote differential threshold value (100 <=> 1%)
     **/
    function voteDifferential() external view returns (uint256);

    /**
     * @dev Get quorum threshold constant value
     * to compare with % of for votes/total supply
     * @return the quorum threshold value (100 <=> 1%)
     **/
    function minimumQuorum() external view returns (uint256);

    /**
     * @dev precision helper: 100% = 10000
     * @return one hundred percents with chosen precision
     **/
    function ONE_HUNDRED_WITH_PRECISION() external view returns (uint256); // solhint-disable-line func-name-mixedcase
}

pragma solidity 0.8.9;

interface IGovernanceStrategy {
    /**
     * @dev Returns the total supply of Outstanding Voting Tokens
     **/
    function getTotalVotingSupply() external view returns (uint256);

    /**
     * @dev Returns the Vote Power of a user for a specific block timestamp.
     * @param user Address of the user.
     * @param blockTimestamp target timestamp
     * @return lottoPower lotto vote number
     * @return gamePower game vote number
     * @return totalVotingPower total vote number
     **/
    function getVotingPowerAt(address user, uint256 blockTimestamp)
        external
        view
        returns (
            uint256 lottoPower,
            uint256 gamePower,
            uint256 totalVotingPower
        );
}

// import "./interfaces/IGovernance.sol";
// import "./interfaces/IGovernanceStrategy.sol";
// import "./interfaces/IProposalValidator.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Proposal Validator Contract, inherited by  Governance Executors
 * @dev Validates/Invalidations propositions state modifications.
 * Proposition Power functions: Validates proposition creations/ cancellation
 * Voting Power functions: Validates success of propositions.
 **/
contract ProposalValidator is IProposalValidator {
    /// propositionThreshold
    uint256 public propositionThreshold;
    /// votingDuration
    uint256 public votingDuration;
    /// voteDifferential
    uint256 public voteDifferential;
    /// minimumQuorum
    uint256 public minimumQuorum;
    /// ONE_HUNDRED_WITH_PRECISION
    uint256 public constant ONE_HUNDRED_WITH_PRECISION = 10000; // Equivalent to 100%, but scaled for precision

    /**
     * @dev Constructor
     * @param _propositionThreshold minimum percentage of supply needed to submit a proposal
     * - In ONE_HUNDRED_WITH_PRECISION units
     * @param _votingDuration duration in seconds of the voting period
     * @param _voteDifferential percentage of supply that `for` votes need to be over `against`
     *   in order for the proposal to pass
     * - In ONE_HUNDRED_WITH_PRECISION units
     * @param _minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
     * - In ONE_HUNDRED_WITH_PRECISION units
     **/
    constructor(
        uint256 _propositionThreshold,
        uint256 _votingDuration,
        uint256 _voteDifferential,
        uint256 _minimumQuorum
    ) {
        propositionThreshold = _propositionThreshold;
        votingDuration = _votingDuration;
        voteDifferential = _voteDifferential;
        minimumQuorum = _minimumQuorum;
    }

    /**
     * @dev Called to validate a proposal (e.g when creating new proposal in Governance)
     * @param governance Governance Contract
     * @param user Address of the proposal creator
     * @return boolean, true if can be created
     **/
    function validateCreatorOfProposal(
        IGovernance governance,
        address user,
        uint256 blockTimestamp
    ) external view override returns (bool) {
        return isPropositionPowerEnough(governance, user, blockTimestamp);
    }

    /**
     * @dev Called to validate the cancellation of a proposal
     * Needs to creator to have lost proposition power threashold
     * @param governance Governance Contract
     * @param user Address of the proposal creator
     * @return boolean, true if can be cancelled
     **/
    function validateProposalCancellation(
        IGovernance governance,
        address user,
        uint256 blockTimestamp
    ) external view override returns (bool) {
        return !isPropositionPowerEnough(governance, user, blockTimestamp);
    }

    /**
     * @dev Returns whether a user has enough Proposition Power to make a proposal.
     * @param governance Governance Contract
     * @param user Address of the user to be challenged.
     * @return true if user has enough power
     **/
    function isPropositionPowerEnough(
        IGovernance governance,
        address user,
        uint256 blockTimestamp
    ) public view override returns (bool) {
        IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
            governance.getGovernanceStrategy()
        );
        (, , uint256 votingPower) = currentGovernanceStrategy.getVotingPowerAt(
            user,
            blockTimestamp
        );
        return votingPower >= getMinimumPropositionPowerNeeded(governance);
    }

    /**
     * @dev Returns the minimum Proposition Power needed to create a proposition.
     * @param governance Governance Contract
     * @return minimum Proposition Power needed
     **/
    function getMinimumPropositionPowerNeeded(IGovernance governance)
        public
        view
        override
        returns (uint256)
    {
        IGovernanceStrategy currentGovernanceStrategy = IGovernanceStrategy(
            governance.getGovernanceStrategy()
        );
        return
            (currentGovernanceStrategy.getTotalVotingSupply() *
                propositionThreshold) / ONE_HUNDRED_WITH_PRECISION;
    }

    /**
     * @dev Returns whether a proposal passed or not
     * @param governance Governance Contract
     * @param proposalId Id of the proposal to set
     * @return true if proposal passed
     **/
    function isProposalPassed(IGovernance governance, uint256 proposalId)
        external
        view
        override
        returns (bool)
    {
        return (isQuorumValid(governance, proposalId) &&
            isVoteDifferentialValid(governance, proposalId));
    }

    /**
     * @dev Calculates the minimum amount of Voting Power needed for a proposal to Pass
     * @param votingSupply Total number of oustanding voting tokens
     * @return voting power needed for a proposal to pass
     **/
    function getMinimumVotingPowerNeeded(uint256 votingSupply)
        public
        view
        override
        returns (uint256)
    {
        return (votingSupply * minimumQuorum) / ONE_HUNDRED_WITH_PRECISION;
    }

    /**
     * @dev Check whether a proposal has reached quorum, has enough FOR-voting-power
     * @param governance Governance Contract
     * @param proposalId Id of the proposal to verify
     * @return voting power needed for a proposal to pass
     **/
    function isQuorumValid(IGovernance governance, uint256 proposalId)
        public
        view
        override
        returns (bool)
    {
        IGovernance.ProposalWithoutVotes memory proposal = governance
            .getProposalById(proposalId);
        uint256 votingSupply = IGovernanceStrategy(proposal.strategy)
            .getTotalVotingSupply();

        return proposal.forVotes >= getMinimumVotingPowerNeeded(votingSupply);
    }

    /**
     * @dev Check whether a proposal has enough extra FOR-votes than AGAINST-votes
     * FOR VOTES % - AGAINST VOTES % > VOTE_DIFFERENTIAL % * voting supply
     * @param governance Governance Contract
     * @param proposalId Id of the proposal to verify
     * @return true if enough For-Votes
     **/
    function isVoteDifferentialValid(IGovernance governance, uint256 proposalId)
        public
        view
        override
        returns (bool)
    {
        IGovernance.ProposalWithoutVotes memory proposal = governance
            .getProposalById(proposalId);
        uint256 votingSupply = IGovernanceStrategy(proposal.strategy)
            .getTotalVotingSupply();

        uint256 forVotes = (proposal.forVotes * ONE_HUNDRED_WITH_PRECISION) /
            votingSupply;
        uint256 againstVotes = (proposal.againstVotes *
            ONE_HUNDRED_WITH_PRECISION) / votingSupply;

        return (forVotes > againstVotes + voteDifferential);
    }
}

pragma solidity 0.8.9;

// import "./ProposalValidator.sol";
// import "./interfaces/IGovernance.sol";
// import "./interfaces/IExecutor.sol";

/**
 * @title Executor and Validator Contract
 * @dev Contract:

 *- Validate Proposal creations/ cancellation
  - Validate Vote Quorum and Vote success on proposal
  - Execute successful proposals' transactions.
 **/
contract Executor is ProposalValidator, IExecutor {
    uint256 public executionPeriod;

    address private _admin;
    address private _pendingAdmin;

    /**
     * @dev Constructor
     * @param admin admin address, that can call the main functions, (should be Governance contract)
     * @param _executionPeriod time after `delay` while a proposal can be executed
     * @param propositionThreshold minimum percentage of supply needed to submit a proposal
     * @param voteDuration duration in seconds of the voting period
     * @param voteDifferential percentage of supply that `for` votes need to be over `against`
     *   in order for the proposal to pass
     * @param minimumQuorum minimum percentage of the supply in FOR-voting-power need for a proposal to pass
     **/
    constructor(
        address admin,
        uint256 _executionPeriod,
        uint256 propositionThreshold,
        uint256 voteDuration,
        uint256 voteDifferential,
        uint256 minimumQuorum
    )
        ProposalValidator(
            propositionThreshold,
            voteDuration,
            voteDifferential,
            minimumQuorum
        )
    {
        require(admin != address(0), "ADDRESS_ZERO");
        _admin = admin;

        executionPeriod = _executionPeriod;
        emit NewAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ONLY_BY_ADMIN");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(this), "ONLY_BY_THIS_TIMELOCK");
        _;
    }

    modifier onlyPendingAdmin() {
        require(msg.sender == _pendingAdmin, "ONLY_BY_PENDING_ADMIN");
        _;
    }

    /**
     * @dev Function enabling pending admin to become admin
     * Can only be called by pending admin
     **/
    function acceptAdmin() public onlyPendingAdmin {
        _admin = msg.sender;
        _pendingAdmin = address(0);

        emit NewAdmin(msg.sender);
    }

    /**
     * @dev Set executionPeriod
     * @notice can be changed only via proposal
     * @param _executionPeriod time after `delay` while a proposal can be executed
     **/
    function setExecutionPeriod(uint256 _executionPeriod) public onlyTimelock {
        executionPeriod = _executionPeriod;
    }

    /**
     * @dev Set propositionThreshold
     * @notice can be changed only via proposal
     * @param _propositionThreshold minimum percentage of supply needed to submit a proposal
     **/
    function setPropositionThreshold(uint256 _propositionThreshold)
        public
        onlyTimelock
    {
        propositionThreshold = _propositionThreshold;
    }

    /**
     * @dev Setting a new pending admin (that can then become admin)
     * Can only be called by this executor (i.e via proposal)
     * @param newPendingAdmin address of the new admin
     **/
    function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
        _pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(newPendingAdmin);
    }

    /**
     * @dev Set minimumQuorum
     * @notice can be changed only via proposal
     * @param _minimumQuorum percentage of min quorum need to proposal passed
     **/
    function setMinimumQuorum(uint256 _minimumQuorum) public onlyTimelock {
        minimumQuorum = _minimumQuorum;
    }

    /**
     * @dev Set voteDifferential
     * @notice can be changed only via proposal
     * @param _voteDifferential percentage of differential of votes between for and against votes
     **/
    function setVoteDifferential(uint256 _voteDifferential)
        public
        onlyTimelock
    {
        voteDifferential = _voteDifferential;
    }

    /**
     * @dev Set votingDuration
     * @notice can be changed only via proposal
     * @param _votingDuration time in seconds of voting period
     **/
    function setVotingDuration(uint256 _votingDuration) public onlyTimelock {
        votingDuration = _votingDuration;
    }

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @return the callData executed as memory bytes
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime
    ) public payable override onlyAdmin returns (bytes memory) {
        bytes32 actionHash = keccak256(
            abi.encode(target, value, signature, data, executionTime)
        );
        require(block.timestamp >= executionTime, "TIMELOCK_NOT_FINISHED");
        require(
            block.timestamp <= executionTime + executionPeriod,
            "EXECUTION_PERIOD_FINISHED"
        );

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        bool success;
        bytes memory resultData;
        // solhint-disable-next-line avoid-low-level-calls
        (success, resultData) = target.call{value: value}(callData);
        require(success, "FAILED_ACTION_EXECUTION");

        emit ExecutedAction(
            actionHash,
            target,
            value,
            signature,
            data,
            executionTime,
            resultData
        );

        return resultData;
    }

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view override returns (address) {
        return _admin;
    }

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view override returns (address) {
        return _pendingAdmin;
    }

    /**
     * @dev Checks whether a proposal is over its execution period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over execution period
     **/
    function isProposalOverExecutionPeriod(
        IGovernance governance,
        uint256 proposalId
    ) external view override returns (bool) {
        IGovernance.ProposalWithoutVotes memory proposal = governance
            .getProposalById(proposalId);

        return (block.timestamp > proposal.executionTime + executionPeriod);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}