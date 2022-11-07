// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';

library CrossChainMandateUtils {
  enum AccessControl {
    Level_null, // to not use 0
    Level_1, // LEVEL_1 - short executor before, listing assets, changes of assets params, updates of the protocol etc
    Level_2 // LEVEL_2 - long executor before, mandate provider updates
  }
  // should fit into uint256 imo
  struct Payload {
    // our own id for the chain, rationality is optimize the space, because chainId by the standard can be uint256,
    //TODO: the limit of enum is 256, should we care about it, or we will never reach this point?
    CrossChainUtils.Chains chain;
    AccessControl accessLevel;
    address mandateProvider; // address which holds the logic to execute after success proposal voting
    uint40 payloadId; // number of the payload placed to mandateProvider, max is: ~10¹²
    uint40 __RESERVED; // reserved for some future needs
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {IMandateProvider, CrossChainUtils, CrossChainMandateUtils} from './interfaces/IMandateProvider.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {IExecutor} from './interfaces/IExecutor.sol';

contract MandateProvider is
  OwnableWithGuardian,
  IMandateProvider,
  Initializable
{
  uint256 internal _expirationDelay;

  uint40 internal _payloadsCount;

  mapping(CrossChainMandateUtils.AccessControl => ExecutorConfig)
    internal _accessLevelToExecutorConfig;

  mapping(uint40 => Payload) internal _payloads;

  function initialize(
    address owner,
    address guardian,
    uint256 expirationDelay,
    UpdateExecutorInput[] calldata executors
  ) external initializer {
    require(executors.length != 0, 'SHOULD_BE_AT_LEAST_ONE_EXECUTOR');

    _updateExpirationDelay(expirationDelay);
    _updateExecutors(executors);

    _updateGuardian(guardian);
    _transferOwnership(owner);
  }

  /// @inheritdoc IMandateProvider
  function updateExpirationDelay(uint256 expirationDelay) external onlyOwner {
    _updateExpirationDelay(expirationDelay);
  }

  /// @inheritdoc IMandateProvider
  function createPayload(ExecutionAction[] calldata actions, bytes32 ipfsHash)
    external
    returns (uint40)
  {
    require(actions.length != 0, 'INVALID_EMPTY_TARGETS');

    uint40 payloadId = _payloadsCount++;
    Payload storage newPayload = _payloads[payloadId];
    newPayload.creator = msg.sender;
    newPayload.state = PayloadState.Created;
    newPayload.createdAt = uint40(block.timestamp);
    newPayload.ipfsHash = ipfsHash;

    CrossChainMandateUtils.AccessControl maximumAccessLevelRequired;
    for (uint256 i = 0; i < actions.length; i++) {
      require(
        _accessLevelToExecutorConfig[actions[i].accessLevel].executor !=
          address(0),
        'EXECUTOR_WAS_NOT_SPECIFIED_FOR_REQUESTED_ACCESS_LEVEL'
      );

      newPayload.actions.push(actions[i]);

      if (actions[i].accessLevel > newPayload.maximumAccessLevelRequired) {
        maximumAccessLevelRequired = actions[i].accessLevel;
      }
    }
    newPayload.maximumAccessLevelRequired = maximumAccessLevelRequired;

    emit PayloadCreated(
      payloadId,
      msg.sender,
      actions,
      maximumAccessLevelRequired,
      ipfsHash
    );
    return payloadId;
  }

  /// @inheritdoc IMandateProvider
  function executePayload(uint40 payloadId) external {
    Payload storage payload = _payloads[payloadId];

    require(
      payload.state == PayloadState.Queued,
      'PAYLOAD_NOT_IN_STATE_QUEUED'
    );

    // @dev check that this payload satisfied to all time conditions of the highest level of access control defined
    ExecutorConfig storage executorConfig = _accessLevelToExecutorConfig[
      payload.maximumAccessLevelRequired
    ];
    uint256 executionTime = payload.queuedAt + executorConfig.delay;
    require(block.timestamp > executionTime, 'TIMELOCK_NOT_FINISHED');
    require(
      block.timestamp < executionTime + executorConfig.gracePeriod,
      'GRACE_PERIOD_FINISHED'
    );

    for (uint256 i = 0; i < payload.actions.length; i++) {
      ExecutionAction storage action = payload.actions[i];
      IExecutor executor = IExecutor(
        _accessLevelToExecutorConfig[action.accessLevel].executor
      );

      executor.executeTransaction{value: action.value}(
        action.target,
        action.value,
        action.signature,
        action.callData,
        action.withDelegateCall
      );
    }

    payload.executedAt = uint40(block.timestamp);
    payload.state = PayloadState.Executed;

    emit PayloadExecuted(payloadId);
  }

  /// @inheritdoc IMandateProvider
  function cancelPayload(uint40 payloadId) external onlyGuardian {
    Payload storage payload = _payloads[payloadId];

    PayloadState payloadState = payload.state;
    require(
      uint256(payloadState) < uint256(PayloadState.Executed) &&
        uint256(payloadState) >= uint256(PayloadState.Created),
      'ONLY_BEFORE_EXECUTION'
    );
    payload.state = PayloadState.Cancelled;
    payload.cancelledAt = uint40(block.timestamp);

    emit PayloadCancelled(payloadId);
  }

  /// @inheritdoc IMandateProvider
  function updateExecutors(UpdateExecutorInput[] calldata executors)
    external
    onlyOwner
  {
    _updateExecutors(executors);
  }

  /// @inheritdoc IMandateProvider
  function getPayloadById(uint40 payloadId)
    external
    view
    returns (Payload memory payload)
  {
    return _payloads[payloadId];
  }

  /// @inheritdoc IMandateProvider
  function getPayloadsCount() external view returns (uint40) {
    return _payloadsCount;
  }

  /// @inheritdoc IMandateProvider
  function getExpirationDelay() external view returns (uint256) {
    return _expirationDelay;
  }

  /// @inheritdoc IMandateProvider
  function getExecutorSettingsByAccessControl(
    CrossChainMandateUtils.AccessControl accessControl
  ) external view returns (ExecutorConfig memory) {
    return _accessLevelToExecutorConfig[accessControl];
  }

  /**
   * @dev method to queue a payload
   * @param payloadId id of the payload that needs to be queued
   * payload can be queued
   */
  function _queuePayload(uint40 payloadId) internal {
    Payload storage payload = _payloads[payloadId];
    require(
      payload.state == PayloadState.Created,
      'PAYLOAD_NOT_IN_STATE_CREATED'
    );

    require(
      payload.createdAt + _expirationDelay > block.timestamp,
      'PAYLOAD_EXPIRED'
    );

    payload.state = PayloadState.Queued;
    payload.queuedAt = uint40(block.timestamp);

    emit PayloadQueued(payloadId);
  }

  /**
   * @dev add new executor configs
   * @param executors array of UpdateExecutorInput with needed executor configurations
   */
  function _updateExecutors(UpdateExecutorInput[] memory executors) internal {
    for (uint256 i = 0; i < executors.length; i++) {
      _accessLevelToExecutorConfig[executors[i].accessLevel] = executors[i]
        .executorConfig;

      emit ExecutorSet(
        executors[i].accessLevel,
        executors[i].executorConfig.executor,
        executors[i].executorConfig.delay,
        executors[i].executorConfig.gracePeriod
      );
    }
  }

  /// @dev updates expiration delay time in seconds
  function _updateExpirationDelay(uint256 newExpirationDelay) internal {
    _expirationDelay = newExpirationDelay;
    emit ExpirationDelayUpdated(newExpirationDelay);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {MandateProvider} from './MandateProvider.sol';
import {IMandateProviderProcessor, CrossChainUtils, IBaseReceiverPortal} from './interfaces/IMandateProviderProcessor.sol';

/// this contract knows how to decode message and receive message from CrossChainManager to pass it to mandate provider
/// contract is immutable because if we need different config we will deploy a different adapter.
contract MandateProviderProcessor is
  MandateProvider,
  IMandateProviderProcessor
{
  address public immutable MESSAGE_ORIGINATOR;
  address public immutable MESSAGE_REGISTRY;

  CrossChainUtils.Chains public immutable ORIGIN_CHAIN_ID;

  /// TODO: not entirely sure if this should go into initialize and not be immutable
  /**
   * @param messageRegistry address of the contract that will push the messages to this portal
   * @param messageOriginator address of the contract where the message originates (mainnet governance)
   * @param originChainId the id of the network where the messages originate from
   */
  constructor(
    address messageRegistry,
    address messageOriginator,
    CrossChainUtils.Chains originChainId
  ) {
    MESSAGE_REGISTRY = messageRegistry;
    MESSAGE_ORIGINATOR = messageOriginator;
    ORIGIN_CHAIN_ID = originChainId;
  }

  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external {
    require(
      msg.sender == MESSAGE_REGISTRY &&
        originSender == MESSAGE_ORIGINATOR &&
        originChainId == ORIGIN_CHAIN_ID,
      'WRONG_MESSAGE_ORIGIN'
    );

    uint40 payloadId = abi.decode(message, (uint40));

    _queuePayload(payloadId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExecutor {
  /**
   * @dev emitted when an action got executed
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @dev Function, called by Governance, that executes a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    bool withDelegatecall
  ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';

import {CrossChainMandateUtils} from '../CrossChainMandateUtils.sol';

interface IMandateProvider {
  /// Enum indicating the possible payload states
  enum PayloadState {
    None, // state 0 left as empty
    Created,
    Queued,
    Executed,
    Cancelled
  }

  /**
   * @dev holds configuration of the executor
   * @param executor address of the executor
   * @param delay time in seconds between queuing and execution
   * @param gracePeriod time in seconds where the proposal can be executed (from executionTime) before it expires
   */
  struct ExecutorConfig {
    address executor;
    uint48 delay;
    uint48 gracePeriod;
  }

  /**
   * @dev Object containing the information necessary to set a new executor
   * @param accessLevel level of access that the executor will be assigned to
   * @param executor address of the executor to assign
   * @param delay time in seconds between queuing and execution
   * @param gracePeriod time in seconds where the proposal can be executed (from executionTime) before it expires
   */
  struct UpdateExecutorInput {
    CrossChainMandateUtils.AccessControl accessLevel;
    ExecutorConfig executorConfig;
  }

  /**
   * @dev Object containing the information necessary to define a payload action
   * @param target address of the contract that needs to be executed
   * @param value value amount that needs to be sent to the executeTransaction method
   * @param signature method signature that will be executed
   * @param callData data needed for the execution of the signature
   * @param withDelegateCall boolean indicating if execution needs to be delegated
   * @param accessLevel access level of the executor needed for the execution
   */
  struct ExecutionAction {
    address target;
    bool withDelegateCall;
    CrossChainMandateUtils.AccessControl accessLevel;
    uint256 value;
    string signature;
    bytes callData;
  }

  /**
   * @dev Object
   * @param creator address of the createPayload method caller
   * @param maximumAccessLevelRequired min level needed to be able to execute all actions
   * @param state indicates the current state of the payload
   * @param createdAt time indicating when payload has been created // max is: 1.099511628×10¹² (ie 34'865 years)
   * @param queuedAt time indicating when payload has been queued  // max is: 1.099511628×10¹² (ie 34'865 years)
   * @param executedAt time indicating when a payload has been executed  // max is: 1.099511628×10¹² (ie 34'865 years)
   * @param ipfsHash hash pointing to the payload metadata hosted on ipfs
   * @param actions array of actions to be executed
   */
  struct Payload {
    address creator;
    CrossChainMandateUtils.AccessControl maximumAccessLevelRequired;
    PayloadState state;
    uint40 createdAt;
    uint40 queuedAt;
    uint40 executedAt;
    uint40 cancelledAt;
    bytes32 ipfsHash;
    ExecutionAction[] actions;
  }

  /**
   * @dev Event emitted when an executor has been set for a determined access level
   * @param accessLevel level of access that the executor will be set to
   * @param executor address that will be set for the determined access level
   * @param delay time in seconds between queuing and execution
   * @param gracePeriod time in seconds where the proposal can be executed (from executionTime) before it expires
   */
  event ExecutorSet(
    CrossChainMandateUtils.AccessControl indexed accessLevel,
    address executor,
    uint48 delay,
    uint48 gracePeriod
  );

  /**
   * @dev Event emitted when a payload has been created
   * @param payloadId id of the payload created
   * @param creator address pertaining to the caller of the method createPayload
   * @param actions array of the actions conforming the payload
   * @param maximumAccessLevelRequired maximum level of the access control
   * @param ipfsHash hash pointing the the payload metadata information hosted on ipfs
   */
  event PayloadCreated(
    uint40 indexed payloadId,
    address indexed creator,
    ExecutionAction[] actions,
    CrossChainMandateUtils.AccessControl indexed maximumAccessLevelRequired,
    bytes32 ipfsHash
  );

  /**
   * @dev Event emitted when block hash aggregator gets updated
   * @param newBridgeAggregator address of the new bridge aggregator
   */
  event BridgeAggregatorUpdated(address newBridgeAggregator);

  /**
   * @dev Event emitted when a payload has been executed
   * @param payloadId id of the payload being enqueued
   */
  event PayloadExecuted(uint40 payloadId);

  /**
   * @dev Event emitted when a payload has been queued
   * @param payloadId id of the payload being enqueued
   */
  event PayloadQueued(uint40 payloadId);

  /**
   * @dev Event emitted when cancelling a payload
   * @param payloadId id of the cancelled payload
   */
  event PayloadCancelled(uint40 payloadId);

  /**
   * @dev Event emitted when updating the expiration delay
   * @param expirationDelay time in seconds of the new expiration delay
   */
  event ExpirationDelayUpdated(uint256 expirationDelay);

  /**
   * @dev method to initialize the contract with starter params. Only callable by proxy
   * @param owner address of the owner of the contract. with permissions to call certain methods
   * @param guardian address of the guardian. With permissions to call certain methods
   * @param expirationDelay time in seconds of the delay with which a payload will expire
   * @param executors array of executor configurations
   */
  function initialize(
    address owner,
    address guardian,
    uint256 expirationDelay,
    UpdateExecutorInput[] calldata executors
  ) external;

  /**
   * @dev get the time in seconds needed for a payload to be expired since it was created
   */
  function getExpirationDelay() external view returns (uint256);

  /**
   * @dev method to update the expiration delay time in seconds
   * @param expirationDelay new time in seconds of the expiration delay
   */
  function updateExpirationDelay(uint256 expirationDelay) external;

  /**
   * @dev get a previously created payload object
   * @param payloadId id of the payload to retrieve
   */
  function getPayloadById(uint40 payloadId)
    external
    view
    returns (Payload memory payload);

  /**
   * @dev get the total count of payloads created
   */
  function getPayloadsCount() external view returns (uint40);

  /**
   * @dev method that will create a Payload object for every action sent
   * @param actions array of actions that will conform this proposal payload
   * @param ipfsHash hash where the metadata for the proposal payload is hosted
   */
  function createPayload(ExecutionAction[] calldata actions, bytes32 ipfsHash)
    external
    returns (uint40);

  /**
   * @dev method to execute a payload
   * @param payloadId id of the payload that needs to be executed
   */
  function executePayload(uint40 payloadId) external;

  /**
   * @dev method to cancel a payload
   * @param payloadId id of the payload that needs to be canceled
   */
  function cancelPayload(uint40 payloadId) external;

  /**
   * @dev method to add executors and its configuration
   * @param executors array of UpdateExecutorInput objects
   */
  function updateExecutors(UpdateExecutorInput[] calldata executors) external;

  /**
   * @dev method to get the executor configuration assigned to the specified level
   * @param accessControl level of which we want to get the grace period from
   */
  function getExecutorSettingsByAccessControl(
    CrossChainMandateUtils.AccessControl accessControl
  ) external view returns (ExecutorConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IBaseReceiverPortal} from 'ghost-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';
import {IMandateProvider} from './IMandateProvider.sol';

interface IMandateProviderProcessor is IBaseReceiverPortal, IMandateProvider {
  /// @dev get contract address from where the messages are pushed into the portal
  function MESSAGE_REGISTRY() external view returns (address);

  /// @dev get chain id of the message originator network
  function ORIGIN_CHAIN_ID() external view returns (CrossChainUtils.Chains);

  /// @dev get address of the message sender in originator network
  function MESSAGE_ORIGINATOR() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CrossChainUtils {
  enum Chains {
    Null_network, // to not use 0
    EthMainnet,
    Polygon,
    Avalanche,
    Harmony,
    Arbitrum,
    Fantom,
    Optimism,
    Goerli,
    AvalancheFuji,
    OptimismGoerli,
    PolygonMumbai
  }
}

pragma solidity ^0.8.0;

import '../CrossChainUtils.sol';

/// @dev interface needed by the portals on the receiving side to be able to receive bridged messages
interface IBaseReceiverPortal {
  /**
   * @dev method called by CrossChainManager when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import {IWithGuardian} from './interfaces/IWithGuardian.sol';
import {Ownable} from '../oz-common/Ownable.sol';

abstract contract OwnableWithGuardian is Ownable, IWithGuardian {
  address private _guardian;

  constructor() {
    _updateGuardian(_msgSender());
  }

  modifier onlyGuardian() {
    _checkGuardian();
    _;
  }

  modifier onlyOwnerOrGuardian() {
    _checkOwnerOrGuardian();
    _;
  }

  function guardian() public view override returns (address) {
    return _guardian;
  }

  /// @inheritdoc IWithGuardian
  function updateGuardian(address newGuardian) external override onlyGuardian {
    _updateGuardian(newGuardian);
  }

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function _updateGuardian(address newGuardian) internal {
    address oldGuardian = _guardian;
    _guardian = newGuardian;
    emit GuardianUpdated(oldGuardian, newGuardian);
  }

  function _checkGuardian() internal view {
    require(guardian() == _msgSender(), 'ONLY_BY_GUARDIAN');
  }

  function _checkOwnerOrGuardian() internal view {
    require(_msgSender() == owner() || _msgSender() == guardian(), 'ONLY_BY_OWNER_OR_GUARDIAN');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IWithGuardian {
  /**
   * @dev Event emitted when guardian gets updated
   * @param oldGuardian address of previous guardian
   * @param newGuardian address of the new guardian
   */
  event GuardianUpdated(address oldGuardian, address newGuardian);

  /**
   * @dev get guardian address;
   */
  function guardian() external view returns (address);

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function updateGuardian(address newGuardian) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
   *
   * _Available since v4.8._
   */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), 'Address: call to non-contract');
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason or using the provided one.
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
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

/**
 * @dev OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/tree/8b778fa20d6d76340c5fac1ed66c80273f05b95a
 *
 * BGD Labs adaptations:
 * - Added a constructor disabling initialization for implementation contracts
 * - Linting
 */

pragma solidity ^0.8.2;

import '../oz-common/Address.sol';

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   * @custom:oz-retyped-from bool
   */
  uint8 private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
   */
  event Initialized(uint8 version);

  /**
   * @dev OPINIONATED. Generally is not a good practise to allow initialization of implementations
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) ||
        (!Address.isContract(address(this)) && _initialized == 1),
      'Initializable: contract is already initialized'
    );
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
   * used to initialize parent contracts.
   *
   * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
   * initialization step. This is essential to configure modules that are added through upgrades and that require
   * initialization.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   */
  modifier reinitializer(uint8 version) {
    require(
      !_initializing && _initialized < version,
      'Initializable: contract is already initialized'
    );
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} and {reinitializer} modifiers, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing, 'Initializable: contract is not initializing');
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   */
  function _disableInitializers() internal virtual {
    require(!_initializing, 'Initializable: contract is initializing');
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }
}