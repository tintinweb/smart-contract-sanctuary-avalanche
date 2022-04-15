/**
 *Submitted for verification at snowtrace.io on 2022-04-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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
// File: github/TheGrandNobody/eternal-contracts/contracts/governance/Timelock.sol




/**
 * @title Timelock contract 
 * @author Taken from Compound Finance (COMP) and tweaked/detailed by Nobody (me)
 * @notice A timelock contract queues and executes proposals made through the Eternal Fund contract
 */
 contract Timelock is ITimelock {

/////–––««« Variables: Constants »»»––––\\\\\
    
    // The period of time any proposal action is given to be executed once the queuing period is over
    uint256 public constant GRACE_PERIOD = 14 days;
    // The lower bound for the minimum amount of time the contract must wait before queuing a proposal
    uint256 public constant MINIMUM_DELAY = 2 days;
    // The upper bound for the minimum amount of time the contract must wait before queuing a proposal
    uint256 public constant MAXIMUM_DELAY = 30 days;

/////–––««« Variables: Addresses »»»––––\\\\\
    
    // The address of this contract's fund
    address private fund;
    // The address of the next fund (stored here until it accepts the role)
    address private pendingFund;

/////–––««« Variables: Queuing »»»––––\\\\\

    // The minimum amount of time the contract must wait before queuing a proposal
    uint256 private delay;
    // Determines whether a given transaction hash is queued or not
    mapping (bytes32 => bool) private queuedTransactions;

    // Fallback function
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

/////–––««« Constructor »»»––––\\\\\

    constructor(address _fund, uint256 _delay) {
        require(_delay >= MINIMUM_DELAY, "Delay must exceed minimum delay");
        require(_delay <= MAXIMUM_DELAY, "Delay can't exceed maximum delay");

        fund = _fund;
        delay = _delay;
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the period of time any proposal action is given to be executed once the queuing period is over.
     * @return The grace period constant
     */
    function viewGracePeriod() external pure override returns (uint256){
        return GRACE_PERIOD;
    }

    /**
     * @notice View the minimum amount of time the contract must wait before queuing a proposal.
     * @return The delay variable
     */
    function viewDelay() external view override returns(uint256) {
        return delay;
    }

    /**
     * @notice View the current fund. 
     * @return The current fund address
     */
    function viewFund() external view override returns (address) {
        return fund;
    }

    /**
     * @notice View the current pending fund.
     * @return The current pending fund address
     */
    function viewPendingFund() external view override returns (address) {
        return pendingFund;
    }

    /**
     * @notice View whether a given transaction hash is queued or not.
     * @return True if the transaction is queued, otherwise false
     */
    function queuedTransaction(bytes32 hash) external view override returns (bool) {
        return queuedTransactions[hash];
    }

/////–––««« Timelock logic functions »»»––––\\\\\

    /**
     * @notice Updates the amount of time the contract must wait before queuing a proposal.
     * @param _delay The new value of the delay
     * 
     * Requirements:
     *
     * - Only callable by this contract
     * - The new delay value cannot be inferior to its lower bound
     * - The new delay value cannot exceed its upper bound
     */
    function setDelay(uint256 _delay) public {
        require(msg.sender == address(this), "Call must come from Timelock");
        require(_delay >= MINIMUM_DELAY, "Delay must exceed minimum delay");
        require(_delay <= MAXIMUM_DELAY, "Delay can't exceed maximum delay");
        delay = _delay;

        emit NewDelay(delay);
    }

    /**
     * @notice Accepts the offer of having the admin role.
     * 
     * Requirements:
     *
     * - Only callable by an an address who was offered the role of fund
     */
    function acceptFund() public override {
        require(msg.sender == pendingFund, "Only callable by a pending Fund");
        fund = msg.sender;
        pendingFund = address(0);

        emit NewAdmin(fund);
    }

    /**
     * @notice Offers the role of admin to a given user.
     * @param _pendingFund The address of the specified user
     * 
     * Requirements:
     *
     * - Only callable by this contract
     */
    function setPendingFund(address _pendingFund) public {
        require(msg.sender == address(this), "Call must come from Timelock");
        pendingFund = _pendingFund;

        emit NewPendingAdmin(pendingFund);
    }

    /**
     * @notice Queues a given proposal's action.
     * @param target The address of the contract whose function is being called
     * @param value The amount of AVAX being transferred in this transaction
     * @param signature The function signature of this proposal's action
     * @param data The function parameters of this proposal's action
     * @param eta The estimated minimum UNIX time (in seconds) at which this transaction is to be executed 
     * @return The transaction hash of this proposal's action
     * 
     * Requirements:
     *
     * - Only callable by the fund
     * - The estimated time of action must be greater than or equal to the minimum delay time
     */
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) public override returns (bytes32) {
        require(msg.sender == fund, "Call must come from the fund");
        require(eta >= block.timestamp + delay, "Delay is not over yet");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    /**
     * @notice Dequeues a given proposal's action.
     * @param target The address of the contract whose function is being called
     * @param value The amount of AVAX being transferred in this transaction
     * @param signature The function signature of this proposal's action
     * @param data The function parameters of this proposal's action
     * @param eta The estimated minimum UNIX time (in seconds) at which this transaction is to be executed 
     * 
     * Requirements:
     *
     * - Only callable by the fund
     */
    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) public override {
        require(msg.sender == fund, "Call must come from the fund");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    /**
     * @notice Executes a given proposal's action.
     * @param target The address of the contract whose function is being called
     * @param value The amount of AVAX being transferred in this transaction
     * @param signature The function signature of this proposal's action
     * @param data The function parameters of this proposal's action
     * @param eta The estimated minimum UNIX time (in seconds) at which this transaction is to be executed 
     * @return The variable returned from executing the function call
     * 
     * Requirements:
     *
     * - Only callable by the fund
     * - The transaction must be in the queue
     * - The delay period of execution must be over
     * - The transaction must be executed within the grace period
     */
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) public payable override returns (bytes memory) {
        require(msg.sender == fund, "Call must come from the fund");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Transaction hasn't been queued");
        require(block.timestamp >= eta, "Transaction delay not over");
        require(block.timestamp <= eta + GRACE_PERIOD, "Transaction is stale");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Transaction execution reverted");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
}