// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IExecutor.sol";
import "./ProposalValidator.sol";
import "../lotteryGame/Constants.sol";

/**
 * @title Executor and Validator Contract
 * @dev Contract:

 *- Validate Proposal creations/ cancellation
  - Validate Vote Quorum and Vote success on proposal
  - Execute successful proposals' transactions.
 **/
contract Executor is ProposalValidator, IExecutor {
    using SafeERC20 for IERC20;
    /// @notice LINK token address
    IERC20 public immutable linkToken;
    uint256 public executionPeriod;

    // @notice creator address => proposal id => LinkTokensInfo
    mapping(address => mapping (uint256 => LinkTokensInfo)) public linkTokenPerUser;
    mapping(address => uint256[]) public userProposalIds;

    address private _admin;
    address private _pendingAdmin;
     /// @notice Factory address
    address private _lotteryFactory;

    /**
     * @dev Constructor
     * @param admin admin address, that can call the main functions, (should be Governance contract)
     * @param executionPeriod_ time after `delay` while a proposal can be executed
     * @param propositionThreshold_ minimum percentage of supply needed to submit a proposal
     * @param votingDuration_ duration in seconds of the voting period
     * @param voteDifferential_ percentage of supply that `for` votes need to be over `against`
     *   in order for the proposal to pass
     * @param minimumQuorum_ minimum percentage of the supply in FOR-voting-power need for a proposal to pass
     **/
    constructor(
        address admin,
        uint256 executionPeriod_,
        uint256 propositionThreshold_,
        uint256 votingDuration_,
        uint256 voteDifferential_,
        uint256 minimumQuorum_,
        address lotteryFactory_
    )
        ProposalValidator(
            propositionThreshold_,
            votingDuration_,
            voteDifferential_,
            minimumQuorum_
        )
    {
        require(admin != address(0) && lotteryFactory_ != address(0), "ADDRESS_ZERO");
        _admin = admin;
        _lotteryFactory = lotteryFactory_;

        executionPeriod = executionPeriod_;
        emit NewAdmin(admin);

        linkToken = IERC20(LINK_TOKEN);
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

    /// @notice set LotteryFactory contract address
    /// @param lotteryFactory_ LotteryFactory address
    function setLotteryFactory(address lotteryFactory_) external onlyTimelock {
        require(lotteryFactory_ != address(0), "ZERO_ADDRESS");
        _lotteryFactory = lotteryFactory_;
    }

    /**
     * @notice Setting a new pending admin (that can then become admin)
     * Can only be called by this executor (i.e via proposal)
     * @param newPendingAdmin address of the new admin
     **/
    function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
        _pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(newPendingAdmin);
    }

    /**
     * @notice Set minimumQuorum
     * @dev can be changed only via proposal
     * @param _minimumQuorum percentage of min quorum need to proposal passed
     **/
    function setMinimumQuorum(uint256 _minimumQuorum) public onlyTimelock {
        minimumQuorum = _minimumQuorum;
    }

    /**
     * @notice Set voteDifferential
     * @dev can be changed only via proposal
     * @param _voteDifferential percentage of differential of votes between for and against votes
     **/
    function setVoteDifferential(uint256 _voteDifferential)
        public
        onlyTimelock
    {
        voteDifferential = _voteDifferential;
    }

    /**
     * @notice Set votingDuration
     * @dev can be changed only via proposal
     * @param _votingDuration time in seconds of voting period
     **/
    function setVotingDuration(uint256 _votingDuration) public onlyTimelock {
        votingDuration = _votingDuration;
    }

    /**
     * @notice Set proposition threshold
     * @dev can be changed only via proposal
     * @param propositionThreshold_ number in percents of the proposition threshold
     **/
    function setPropositionThreshold(uint256 propositionThreshold_) public onlyTimelock {
        propositionThreshold = propositionThreshold_;
    }

    /**
     * @notice Set execution period
     * @dev can be changed only via proposal
     * @param executionPeriod_ time in seconds of execution period
     **/
    function setExecutionPeriod(uint256 executionPeriod_) public onlyTimelock {
        executionPeriod = executionPeriod_;
    }

    /// @notice deposit LINK tokens to Executor contract
    /// @dev can be called only by governance
    /// @param proposalCreator address of proposal creator
    /// @param amount quantity of LINK upkeep need to be funded with 
    /// @param proposalId created proposal id
    function depositLinks(address proposalCreator, uint256 amount, uint256 proposalId)
        external
        override
        onlyAdmin
    {
        linkTokenPerUser[proposalCreator][proposalId].amount = amount;
        linkTokenPerUser[proposalCreator][proposalId].governance = msg.sender;   

        userProposalIds[proposalCreator].push(proposalId);
        linkToken.safeTransferFrom(proposalCreator, address(this), amount);
        linkToken.safeIncreaseAllowance(_lotteryFactory, amount);
    }

    /// @notice withdraw LINK tokens by the proposal creator
    /// @dev can be called only when proposal is failed/not executed/canceled
    /// @param proposalId id of proposal need to withdraw link tokens from
    function withdrawLinks(uint256 proposalId) external override {
        address proposalCreator = msg.sender;
        LinkTokensInfo memory info = linkTokenPerUser[proposalCreator][proposalId];
        require(
            !info.isWithdrawed,
            "ALREADY_WITHDRAW"
        );
        IGovernance.ProposalState proposalState = IGovernance(info.governance).getProposalState(
            proposalId
        );
        if (
            proposalState == IGovernance.ProposalState.Canceled ||
            proposalState == IGovernance.ProposalState.Failed ||
            proposalState == IGovernance.ProposalState.Expired 
        ) {
            linkTokenPerUser[proposalCreator][proposalId].isWithdrawed = true;
            linkToken.safeTransfer(
                proposalCreator,
                info.amount
            );
        }
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
     * @notice Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view override returns (address) {
        return _admin;
    }

    /**
     * @notice Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view override returns (address) {
        return _pendingAdmin;
    }

    /**
     * @notice Checks whether a proposal is over its execution period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over execution period
     **/
    function isProposalOverExecutionPeriod(
        IGovernance governance,
        uint256 proposalId
    )
        external
        view
        override
        returns (bool)
    {
        IGovernance.ProposalWithoutVotes memory proposal = governance
            .getProposalById(proposalId);

        return (block.timestamp > proposal.executionTime + executionPeriod);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

import "./interfaces/IGovernance.sol";
import "./interfaces/IGovernanceStrategy.sol";
import "./interfaces/IProposalValidator.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant WINNERS_LIMIT = 10;
uint256 constant BENEFICIARY_LIMIT = 100;
address constant VRF_COORDINATOR = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
address constant KEEPERS_REGISTRY = 0x409CF388DaB66275dA3e44005D182c12EeAa12A0;
address constant LINK_TOKEN = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
address constant UPKEEP_REGISTRATION = 0xb3532682f7905e06e746314F6b12C1e988B94aDB;
uint256 constant HUNDRED_PERCENT_WITH_PRECISONS = 10_000;
uint256 constant MIN_LINK_TOKENS_NEEDDED = 5_000_000_000_000_000_000;
uint256 constant DECIMALS = 10**18;
uint8 constant MIN_LINK = 5;

string constant ERROR_INCORRECT_LENGTH = "0x1";
string constant ERROR_INCORRECT_PERCENTS_SUM = "0x2";
string constant ERROR_DEACTIVATED_GAME = "0x3";
string constant ERROR_CALLER_FEE_CANNOT_BE_MORE_100 = "0x4";
string constant ERROR_TIMELOCK_IN_DURATION_IS_ACTIVE = "0x5";
string constant ERROR_DATE_TIME_TIMELOCK_IS_ACTIVE = "0x6";
string constant ERROR_LIMIT_UNDER = "0x7";
string constant ERROR_INCORRECT_PERCENTS_LENGTH = "0x8";
string constant ERROR_NOT_READY_TO_START = "0x9";
string constant ERROR_NOT_ACTIVE_OR_STARTED = "0xa";
string constant ERROR_PARTICIPATE_ALREADY = "0xb";
string constant ERROR_INVALID_PARTICIPATE = "0xc";
string constant ERROR_LIMIT_EXEED = "0xd";
string constant ERROR_ALREADY_DEACTIVATED = "0xe";
string constant ERROR_GAME_STARTED = "0xf";
string constant ERROR_NO_SUBSCRIPTION = "0x10";
string constant ERROR_NOT_ACTIVE = "0x11";
string constant ERROR_ZERO_ADDRESS = "0x12";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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