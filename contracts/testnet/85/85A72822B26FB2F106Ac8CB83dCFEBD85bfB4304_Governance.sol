// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IGovernanceStrategy.sol";
import "./interfaces/IExecutor.sol";
import "./interfaces/IProposalValidator.sol";
import "./interfaces/IGovernance.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/ILotteryGameFactory.sol";

/**
 * @title Governance contract
 * @dev Main point of interaction with Lotto governance

 *- Create a Proposal
  - Cancel a Proposal
  - Execute a Proposal
  - Submit Vote to a Proposal
  Available Proposal States : Pending => Active => Succeeded(/Failed) => Executed(/Expired).
  The transition  "Canceled" can appear while the State is not set as Executed/Expired
  
 *1. When the Proposal is created it has Pending state
  2. After is the time exeed the votingDelay value Proposal become Active so available for voting
  3. When the voting period is finished Proposal become or Succeeded or Failed. It depends on if the voteDifference was achived or not
  4. After the proposal was Succeeded proposal can be executed immediately. After it will be executed state turn to Executed
  5. If the executionPeriod was passed and transaction was not executed it recieve Expired state and can't be executed anymore
*/
contract Governance is Ownable, IGovernance {
    using SafeMath for uint256;
    uint256 constant public MIN_LINK = 5 ether;

    struct CreateVars {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 previousProposalsCount;
    }

    uint256 public communityReward;
    uint256 public governanceReward;

    address private _governanceStrategy;
    uint256 private _votingDelay;

    uint256 private _proposalsCount;
    mapping(uint256 => Proposal) private _proposals;
    mapping(address => bool) private _authorizedExecutors;

    address private _guardian;

    modifier onlyGuardian() {
        require(
            msg.sender == _guardian,
            "Governance: caller is not the guardian"
        );
        _;
    }

    /**
     * @dev Constructor - set initial parameters
     * @param governanceStrategy - The whitelisted strategy to calculate voting power
     * @param votingDelay - delay before voting will be unlocked and proposal state changed from Pending ro Active
     * @param guardian - the address of guardian who will be able to cancel proposal
     * @param executors - list of executors
     **/
    constructor(
        address governanceStrategy,
        uint256 votingDelay,
        address guardian,
        address[] memory executors
    ) {
        _setGovernanceStrategy(governanceStrategy);
        _setVotingDelay(votingDelay);
        _guardian = guardian;

        authorizeExecutors(executors);
    }

    /**
     * @dev Creates a Proposal (needs Voting Power of creator > Threshold)
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
        string memory ipfsHash
    ) external override returns (uint256) {
        require(targets.length != 0, "Governance: targets is empty");
         require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "Governance: Inconsistent params length"
        );

        require(
            isExecutorAuthorized(address(executor)),
            "Governance: Executor is not authorized"
        );

        require(
            IProposalValidator(address(executor)).validateCreatorOfProposal(
                this,
                msg.sender,
                block.timestamp - 1
            ),
            "Governance: There is not enought voting power to create proposition"
        );

        CreateVars memory vars;
        vars.startTimestamp = block.timestamp + _votingDelay;
        vars.endTimestamp =
            vars.startTimestamp +
            IProposalValidator(address(executor)).votingDuration();

        vars.previousProposalsCount = _proposalsCount;

        Proposal storage newProposal = _proposals[vars.previousProposalsCount];

        newProposal.id = vars.previousProposalsCount;
        newProposal.creator = msg.sender;
        newProposal.executor = executor;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startTimestamp = vars.startTimestamp;
        newProposal.endTimestamp = vars.endTimestamp;
        newProposal.executionTime = vars.endTimestamp + 1;
        newProposal.strategy = _governanceStrategy;
        newProposal.ipfsHash = ipfsHash;
        _proposalsCount++;

        emit ProposalCreated(
            vars.previousProposalsCount,
            msg.sender,
            executor,
            targets,
            values,
            signatures,
            calldatas,
            vars.startTimestamp,
            vars.endTimestamp,
            vars.endTimestamp + 1,
            _governanceStrategy,
            ipfsHash
        );

        // new lottery proposal should be created as a one separated option
        if (_isNewLotteryCreating(signatures[0], calldatas[0])) {
            executor.depositLinks(msg.sender, MIN_LINK, newProposal.id);
        }

        return newProposal.id;
    }


    function _isNewLotteryCreating( 
        string memory signature_,
        bytes memory calldata_
    ) private pure returns(bool){
       bytes4 selector = ILotteryGameFactory.createLottery.selector;
        if(bytes(signature_).length == 0){
            return bytes4(calldata_) == selector;
        }
        else{
            return bytes4(abi.encodeWithSignature(signature_)) == selector;
        }
    }
    /**
     * @dev Cancels a Proposal.
     * - Callable by the _guardian with relaxed conditions, or by anybody if the conditions of
     *   cancellation on the executor are fulfilled, hence is the creator will not hold the proposionThreshold on his wallet
     * @param proposalId id of the proposal
     **/
    function cancelProposal(uint256 proposalId) external override {
        ProposalState state = getProposalState(proposalId);
        require(
            state != ProposalState.Executed &&
                state != ProposalState.Canceled &&
                state != ProposalState.Expired,
            "Governance: Cancellation is not available"
        );

        Proposal storage proposal = _proposals[proposalId];
        require(
            msg.sender == _guardian ||
                IProposalValidator(address(proposal.executor))
                    .validateProposalCancellation(
                        this,
                        proposal.creator,
                        block.timestamp - 1
                    ),
            "Governance: Cancellation is not available"
        );
        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /**
     * @dev Execute the proposal (If Proposal is Succeeded)
     * @param proposalId id of the proposal to execute
     **/
    function executeProposal(uint256 proposalId) external payable override {
        require(
            getProposalState(proposalId) == ProposalState.Succeeded,
            "Governance: Allowed to execute only succeed proposal"
        );
        Proposal storage proposal = _proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            proposal.executor.executeTransaction{value: proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.executionTime
            );
        }
        emit ProposalExecuted(proposalId, msg.sender);
    }

    /**
     * @dev Function allowing msg.sender to vote for/against a proposal
     * @param proposalId id of the proposal
     * @param support boolean, true = vote for, false = vote against
     **/
    function submitVote(uint256 proposalId, bool support) external override {
        return _submitVote(msg.sender, proposalId, support);
    }

    /**
     * @dev Set new GovernanceStrategy, allowed to call by onlyOwner
     * @notice owner should be a executor, so needs to make a proposal
     * @param governanceStrategy new Address of the GovernanceStrategy contract
     **/
    function setGovernanceStrategy(address governanceStrategy)
        external
        override
        onlyOwner
    {
        _setGovernanceStrategy(governanceStrategy);
    }

    /**
     * @dev Set new community reward percent, allowed to call by onlyOwner
     * @notice owner should be a executor, so needs to make a proposal.
     * communityReward  will be the same for each game (including main one)
     * @param communityReward_ new percent of the community reward
     **/
    function setCommunityReward(uint256 communityReward_) external onlyOwner {
        communityReward = communityReward_;
        emit CommunityRewardChanged(communityReward_);
    }

    /**
     * @dev Set new governance reward percent, allowed to call by onlyOwner
     * @notice owner should be a executor, so needs to make a proposal.
     * governanceReward  will be the same for each game (including main one)
     * @param governanceReward_ new percent of the governance reward
     **/
    function setGovernanceReward(uint256 governanceReward_) external onlyOwner {
        governanceReward = governanceReward_;
        emit GovernanceRewardChanged(governanceReward_);
    }

    /**
     * @dev Set new Voting Delay (delay before a newly created proposal can be voted on), allowed to call by onlyOwner
     * @notice owner should be a executor, so needs to make a proposal
     * @param votingDelay new voting delay in terms of blocks
     **/
    function setVotingDelay(uint256 votingDelay) external override onlyOwner {
        _setVotingDelay(votingDelay);
    }

    /**
     * @dev Add new addresses to the list of authorized executors, allowed to call by onlyOwner
     * @notice owner should be a executor, so needs to make a proposal
     * @param executors list of new addresses to be authorized executors
     **/
    function authorizeExecutors(address[] memory executors)
        public
        override
        onlyOwner
    {
        for (uint256 i = 0; i < executors.length; i++) {
            _authorizeExecutor(executors[i]);
        }
    }

    /**
     * @dev Remove addresses from the list of authorized executors
     * @notice owner should be a executor, so needs to make a proposal
     * @param executors list of addresses to be removed as authorized executors
     **/
    function unauthorizeExecutors(address[] memory executors)
        public
        override
        onlyOwner
    {
        for (uint256 i = 0; i < executors.length; i++) {
            _unauthorizeExecutor(executors[i]);
        }
    }

    /**
     * @dev Let the guardian abdicate from its priviledged rights. Set address of _guardian as zero address
     * @notice can be called only by _guardian
     **/
    function abdicate() external override onlyGuardian {
        _guardian = address(0);
    }

    /**
     * @dev Getter of the current GovernanceStrategy address
     * @return The address of the current GovernanceStrategy contract
     **/
    function getGovernanceStrategy() external view override returns (address) {
        return _governanceStrategy;
    }

    /**
     * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
     * Different from the voting duration
     * @return The voting delay in seconds
     **/
    function getVotingDelay() external view override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev Returns whether an address is an authorized executor
     * @param executor_ address to evaluate as authorized executor
     * @return true - if authorized, false - is not authorized
     **/
    function isExecutorAuthorized(address executor_)
        public
        view
        override
        returns (bool)
    {
        return _authorizedExecutors[executor_];
    }

    /**
     * @dev Getter the address of the guardian, that can mainly cancel proposals
     * @return The address of the guardian
     **/
    function getGuardian() external view override returns (address) {
        return _guardian;
    }

    /**
     * @dev Getter of the proposal count (the current number of proposals ever created)
     * @return the proposal count
     **/
    function getProposalsCount() external view override returns (uint256) {
        return _proposalsCount;
    }

    /**
     * @dev Getter of a proposal by id
     * @param proposalId id of the proposal to get
     * @return the proposal as struct ProposalWithoutVotes
     **/
    function getProposalById(uint256 proposalId)
        external
        view
        override
        returns (ProposalWithoutVotes memory)
    {
        Proposal storage proposal = _proposals[proposalId];
        ProposalWithoutVotes
            memory proposalWithoutVotes = ProposalWithoutVotes({
                id: proposal.id,
                creator: proposal.creator,
                executor: proposal.executor,
                targets: proposal.targets,
                values: proposal.values,
                signatures: proposal.signatures,
                calldatas: proposal.calldatas,
                startTimestamp: proposal.startTimestamp,
                endTimestamp: proposal.endTimestamp,
                executionTime: proposal.executionTime,
                forVotes: proposal.forVotes,
                againstVotes: proposal.againstVotes,
                executed: proposal.executed,
                canceled: proposal.canceled,
                strategy: proposal.strategy,
                ipfsHash: proposal.ipfsHash,
                lottoVotes: proposal.lottoVotes,
                gameVotes: proposal.gameVotes
            });

        return proposalWithoutVotes;
    }

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
        override
        returns (Vote memory)
    {
        return _proposals[proposalId].votes[voter];
    }

    /**
     * @dev Get the current state of a proposal
     * @param proposalId id of the proposal
     * @return The current state of the proposal
     **/
    function getProposalState(uint256 proposalId)
        public
        view
        override
        returns (ProposalState)
    {
        require(
            _proposalsCount > proposalId,
            "Governance: Invalid proposal ID"
        );
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTimestamp) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTimestamp) {
            return ProposalState.Active;
        } else if (
            !IProposalValidator(address(proposal.executor)).isProposalPassed(
                this,
                proposalId
            )
        ) {
            return ProposalState.Failed;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (
            proposal.executor.isProposalOverExecutionPeriod(this, proposalId)
        ) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Succeeded;
        }
    }

    function _submitVote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal {
        require(
            getProposalState(proposalId) == ProposalState.Active,
            "Governance:Voting is closed"
        );
        Proposal storage proposal = _proposals[proposalId];
        Vote storage vote = proposal.votes[voter];

        require(vote.votingPower == 0, "Governance: Vote already submitted");

        (
            uint256 lotto,
            uint256 game,
            uint256 votingPower
        ) = IGovernanceStrategy(proposal.strategy).getVotingPowerAt(
                voter,
                proposal.startTimestamp
            );

        require(votingPower > 0, "Governance: You have none voting power");

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        }

        vote.support = support;
        vote.votingPower = uint248(votingPower);
        vote.submitTimestamp = block.timestamp;

        proposal.lottoVotes += lotto;
        proposal.gameVotes += game;

        emit VoteEmitted(proposalId, voter, support, votingPower);
    }

    function _setGovernanceStrategy(address governanceStrategy) internal {
        _governanceStrategy = governanceStrategy;

        emit GovernanceStrategyChanged(governanceStrategy, msg.sender);
    }

    function _setVotingDelay(uint256 votingDelay) internal {
        _votingDelay = votingDelay;

        emit VotingDelayChanged(votingDelay, msg.sender);
    }

    function _authorizeExecutor(address executor_) internal {
        _authorizedExecutors[executor_] = true;
        emit ExecutorAuthorized(executor_);
    }

    function _unauthorizeExecutor(address executor_) internal {
        _authorizedExecutors[executor_] = false;
        emit ExecutorUnauthorized(executor_);
    }
}

// SPDX-License-Identifier:MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IGovernance.sol";

interface IExecutor {
    /**
     * @notice Struct for track LINK tokens balance when creating proposal
     * @param amount amount of LINK tokens in Executor balance
     * @param isWithdrawed is Link tokens withdraw to the owner address
     * @param governance address of Governance contract
     **/
    struct LinkTokensInfo {
        uint256 amount;
        bool isWithdrawed;
        address governance;
    }

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

    /// @notice deposit LINK tokens to Executor contract 
    /// @dev can be called by the governance contract only
    /// @param proposalCreator address of proposal creator
    /// @param amount quantity of LINK upkeep is funded
    /// @param proposalId created proposal id
    function depositLinks(address proposalCreator, uint256 amount, uint256 proposalId) external;

    /// @notice withdraw LINK tokens by the proposal creator
    /// @dev can be called only when proposal is failed/not executed/canceled
    /// @param proposalId id of proposal need to withdraw link tokens from
    function withdrawLinks(uint256 proposalId) external;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IGovernance.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IExecutor.sol";

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
        string ipfsHash;
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
        string ipfsHash;
        uint256 lottoVotes;
        uint256 gameVotes;
    }

    /**
     * @notice Struct for create proposal
     * @param targets - list of contracts called by proposal's associated transactions
     * @param values - list of value in wei for each propoposal's associated transaction
     * @param signatures - list of function signatures (can be empty) to be used when created the callData
     * @param calldatas - list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param ipfsHash - IPFS hash of the proposal
     */
    struct CreatingProposal {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        string ipfsHash;
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
        string ipfsHash
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
        string memory ipfsHash
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
     * @param executor_ address to evaluate as authorized executor
     * @return true if authorized, false is not authorized
     **/
    function isExecutorAuthorized(address executor_)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ICustomLotteryGame.sol";

/// @title Define interface for LotteryGameFactory contract
interface ILotteryGameFactory {
    /// @dev store info about status of lottery game (autorized or not)
    /// @param isAuthorized true if lottery game is created
    /// @param gameId lottery game id
    struct LotteryGameInfo {
        bool isAuthorized;
        uint256 gameId;
    }

    /// @dev emitted when a game is created
    /// @param game struct of info about the game
    event CreatedLottery(
        ICustomLotteryGame.Game game
    );

    /// @dev emitted when a game is deleted
    /// @param deletedGameAddress address of the deleted game
    event DeletedLottery(address indexed deletedGameAddress);

    /// @notice creating new instance of CustomLotteryGame contract
    
    /// param game struct of info about the game
    /// @param name string of the upkeep to be registered
    /// @param encryptedEmail email address of upkeep contact
    /// @param gasLimit amount of gas to provide the target contract when performing upkeep
    /// @param checkData data passed to the contract when checking for upkeep
    /// @param amount quantity of LINK upkeep is funded with (specified in Juels)
    /// @param source application sending this request
    function createLottery(
       bytes calldata constructorParam,
        string memory name,
        bytes memory encryptedEmail,
        uint32 gasLimit,
        bytes memory checkData,
        uint96 amount,
        uint8 source
    ) external returns (address);

    /// @dev deleting lottery game (the game is invalid)
    /// @param game address of the required game to delete
    function deleteLottery(address game) external;

    /// @dev allow the user to enter in a few additional games at one transaction
    /// @param gamesList list of games addresses
    function entryMultipleGames(address[] memory gamesList)
        external;

    /// @dev approve of game tokens for selected games at one transaction
    /// @param gamesList list of games addresses
    function approveForMultipleGames(address[] memory gamesList)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* solhint-disable var-name-mixedcase */
interface ICustomLotteryGame {
    /// @notice store more detailed info about the additional game
    /// @param VRFGasLimit amount of the gas limit for VRF
    /// @param countOfWinners number of winners
    /// @param participantsLimit limit of users that can be in game
    /// @param participantsCount number of user that are already in game
    /// @param participationFee amount of fee for user to enter the game
    /// @param callerFeePercents amount of fee percentage for caller of the game
    /// @param gameDuration timestamp how long the game should be going
    /// @param isDeactivated bool value is the game is deactibated (true) or not (false)
    /// @param callerFeeCollector address of the caller fee percentage
    /// @param lotteryName the name of the lottery game
    /// @param descriptionIPFS ipfs hash with lottery description
    /// @param winnersPercentages array of winners percentage
    /// @param benefeciaryPercentage array of beneficiary reward percentage
    /// @param subcriptorsList array of subscriptors
    /// @param benefeciaries array of lottery beneficiaries
    struct Game {
        uint32 VRFGasLimit;
        uint256 countOfWinners;
        uint256 participantsLimit;
        uint256 participantsCount;
        uint256 participationFee;
        uint256 callerFeePercents;
        uint256 gameDuration;
        bool isDateTimeRequired;
        bool isDeactivated;
        address callerFeeCollector;
        string lotteryName;
        string descriptionIPFS;
        uint256[] winnersPercentages;
        uint256[] benefeciaryPercentage;
        address[] subcriptorsList;
        address[] benefeciaries;
    }

    struct EmptyTypes {
        address[] emptyAddr;
        uint256[] emptyUInt;
    }

    /// @notice store lottery (rounds) info
    /// @param rewardPool address of the reward pool
    /// @param isActive is active
    /// @param id lottery id
    /// @param participationFee paricipation fee for user to enter lottery
    /// @param startedAt timestamp when the lottery is started
    /// @param finishedAt timestamp when the lottery is finished
    /// @param rewards amount of the rewards
    /// @param winningPrize array of amount for each winner
    /// @param beneficiariesPrize array of amount for each beneficiary
    /// @param participants array of lottery participants
    /// @param winners array of lottery winners
    /// @param beneficiaries array of lottery beneficiaries
    struct Lottery {
        address rewardPool;
        bool isActive;
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 rewards;
        uint256[] winningPrize;
        uint256[] beneficiariesPrize;
        address[] participants;
        address[] winners;
        address[] beneficiaries;
    }

    /// @notice store subscription info
    /// @param isExist is user subscribe
    /// @param isRevoked is user unsubscribe
    /// @param balance user balance of withdrawn money in subscription after a round
    /// @param lastCheckedGameId the game (round) id from which will be active yser`s subscription
    struct Subscription {
        bool isExist;
        bool isRevoked;
        uint256 balance;
        uint256 lastCheckedGameId;
    }

    /// @notice store game options info
    /// @param countOfParticipants number of participants in a round
    /// @param winnersIndexes array of winners indexes
    struct GameOptionsInfo {
        uint256 countOfParticipants;
        uint256[] winnersIndexes;
    }

    /// @notice store chainlink parameters info
    /// @param requestConfirmations amount of confiramtions for VRF
    /// @param subscriptionId subscription id for VRF
    /// @param keyHash The gas lane to use, which specifies the maximum gas price to bump to while VRF
    struct ChainlinkParameters {
        uint16 requestConfirmations;
        uint64 subscriptionId;
        bytes32 keyHash;
    }

    /// @notice store winning prize info
    /// @param totalWinningPrize amount of total winning prize of jeckpot
    /// @param callerFee percentage of caller fee for jeckpot
    /// @param governanceFee percentage of game tokens as a governance rewatds from jeckpot
    /// @param communityFee percentage of game tokens as a community rewatds from jeckpot
    /// @param governanceReward amount of game tokens as a governance rewatds from jeckpot
    /// @param communityReward amount of game tokens as a community rewatds from jeckpot
    /// @param totalReward percentage of total rewards from jeckpot
    /// @param beneficiariesPrize percentage of beneficiary prize of jeckpot
    /// @param totalWinningPrizeExludingFees amount of total winning prize without fees of jeckpot
    struct WinningPrize {
        uint256 totalWinningPrize;
        uint256 callerFee;
        uint256 governanceFee;
        uint256 communityFee;
        uint256 governanceReward;
        uint256 communityReward;
        uint256 totalReward;
        uint256 beneficiariesPrize;
        uint256 totalWinningPrizeExludingFees;
    }

    /// @notice store all chenging params for the game
    /// @dev this pending params are setted to the game from the next round
    /// @param isDeactivated is game active or not
    /// @param participationFee  participation fee for the game
    /// @param winnersNumber count of winners
    /// @param winnersPercentages array of percenages for winners
    /// @param limitOfPlayers participants limit
    /// @param callerFeePercents caller fee percntages
    struct Pending {
        bool isDeactivated;
        uint256 participationFee;
        uint256 winnersNumber;
        uint256 limitOfPlayers;
        uint256 callerFeePercents;
        uint256[] winnersPercentages;
    }

    /// @notice store info about time when lottery is unlocked
    /// @dev should be in unix, so need to take care about conversion into required timezone
    /// @param daysUnlocked day of week when game is unlock
    /// @param hoursStartUnlock start hour when game is unlocking
    /// @param unlockDurations unlock duration starting from hoursStartUnlock
    struct TimelockInfo {
        uint8[] daysUnlocked;
        uint8[] hoursStartUnlock;
        uint256[] unlockDurations;
    }

    /// @notice emitted when called fullfillBytes
    /// @param requestId encoded request id
    /// @param data encoded data
    event RequestFulfilled(bytes32 indexed requestId, bytes indexed data);

    /// @notice emitted when the game is started
    /// @param id the game id
    /// @param startedAt timestamp when game is started
    event GameStarted(uint256 indexed id, uint256 indexed startedAt);

    /// @notice emitted when the game is finished
    /// @param id the game id
    /// @param startedAt timestamp when game is started
    /// @param finishedAt timestamp when game is finished
    /// @param participants array of games participants
    /// @param winners array of winners
    /// @param participationFee participation fee for users to enter to the game
    /// @param winningPrize array of prizes for each winner
    /// @param rewards amount of jeckpot rewards
    /// @param rewardPool reward pool of the game
    event GameFinished(
        uint256 id,
        uint256 startedAt,
        uint256 finishedAt,
        address[] indexed participants,
        address[] indexed winners,
        uint256 participationFee,
        uint256[] winningPrize,
        uint256 rewards,
        address indexed rewardPool
    );

    /// @notice emitted when a game duration is change
    /// @param gameDuration timestamp of the game duration
    event ChangedGameDuration(uint256 gameDuration);

    /// @notice emitted when a game amount of winners is change
    /// @param winnersNumber new amount of winners
    /// @param winnersPercentages new percentage
    event ChangedWinners(uint256 winnersNumber, uint256[] winnersPercentages);

    /// @notice Enter game for following one round
    /// @dev participant address is msg.sender
    function entryGame() external;

    /// @notice Enter game for following one round
    /// @dev participatinonFee will be charged from msg.sender
    /// @param participant address of the participant
    function entryGame(address participant) external;

    /// @notice start created game
    /// @param VRFGasLimit_ price for VRF
    /// @param amount of LINK tokens
    function startGame(uint32 VRFGasLimit_, uint96 amount) external;

    /// @notice deactivation game
    /// @dev if the game is deactivated cannot be called entryGame()  and subcribe()
    function deactivateGame() external;

    /// @notice get participation fee for LotteryGameFactory contract
    function getParticipationFee() external view returns (uint256);
}