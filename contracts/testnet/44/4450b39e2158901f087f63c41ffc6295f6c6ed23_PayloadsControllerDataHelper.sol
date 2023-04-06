// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseReceiverPortal
 * @author BGD Labs
 * @notice interface defining the method that needs to be implemented by all receiving portals, as its the one that
           will be called when a received message gets confirmed
 */
interface IBaseReceiverPortal {
  /**
   * @notice method called by CrossChainController when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';
import {IPayloadsController} from '../payloads/interfaces/IPayloadsController.sol';
import {IPayloadsControllerCore} from '../payloads/interfaces/IPayloadsControllerCore.sol';
import {IPayloadsControllerDataHelper} from './interfaces/IPayloadsControllerDataHelper.sol';

/**
 * @title PayloadsControllerDataHelper
 * @author BGD Labs
 * @notice this contract contains the logic to get the payloads and to retreive the executor configs.
 */
contract PayloadsControllerDataHelper is IPayloadsControllerDataHelper {
  /// @inheritdoc IPayloadsControllerDataHelper
  function getPayloadsData(
    IPayloadsController payloadsController,
    uint40[] calldata payloadsIds
  ) external view returns (Payload[] memory) {
    Payload[] memory payloads = new Payload[](payloadsIds.length);
    IPayloadsController.Payload memory payload;

    for (uint256 i = 0; i < payloadsIds.length; i++) {
      payload = payloadsController.getPayloadById(payloadsIds[i]);
      payloads[i] = Payload({id: payloadsIds[i], payloadData: payload});
    }

    return payloads;
  }

  /// @inheritdoc IPayloadsControllerDataHelper
  function getExecutorConfigs(
    IPayloadsController payloadsController,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (ExecutorConfig[] memory) {
    ExecutorConfig[] memory executorConfigs = new ExecutorConfig[](
      accessLevels.length
    );
    IPayloadsControllerCore.ExecutorConfig memory executorConfig;

    for (uint256 i = 0; i < accessLevels.length; i++) {
      executorConfig = payloadsController.getExecutorSettingsByAccessControl(
        accessLevels[i]
      );
      executorConfigs[i] = ExecutorConfig({
        accessLevel: accessLevels[i],
        config: executorConfig
      });
    }

    return executorConfigs;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../../payloads/PayloadsControllerUtils.sol';
import {IPayloadsController} from '../../payloads/interfaces/IPayloadsController.sol';
import {IPayloadsControllerCore} from '../../payloads/interfaces/IPayloadsControllerCore.sol';

/**
 * @title IPayloadsControllerDataHelper
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the PayloadsControllerDataHelper contract
 */
interface IPayloadsControllerDataHelper {
  /**
   * @notice Object storing the payload data along with its id
   * @param id identifier of the payload
   * @param payloadData payload body
   */
  struct Payload {
    uint256 id;
    IPayloadsController.Payload payloadData;
  }

  /**
   * @notice Object storing the config of the executor
   * @param accessLevel access level
   * @param config executor config
   */
  struct ExecutorConfig {
    PayloadsControllerUtils.AccessControl accessLevel;
    IPayloadsControllerCore.ExecutorConfig config;
  }

  /**
   * @notice method to get proposals list
   * @param payloadsController instance of the payloads controller
   * @param payloadsIds list of the ids of payloads to get
   * @return list of the payloads
   */
  function getPayloadsData(
    IPayloadsController payloadsController,
    uint40[] calldata payloadsIds
  ) external view returns (Payload[] memory);

  /**
   * @notice method to get executor configs for certain accessLevels
   * @param payloadsController instance of the payloads controller
   * @param accessLevels list of the accessLevels for which configs should be returned
   * @return list of the executor configs
   */
  function getExecutorConfigs(
    IPayloadsController payloadsController,
    PayloadsControllerUtils.AccessControl[] calldata accessLevels
  ) external view returns (ExecutorConfig[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PayloadsControllerUtils {
  /// @notice enum with supported access levels
  enum AccessControl {
    Level_null, // to not use 0
    Level_1, // LEVEL_1 - short executor before, listing assets, changes of assets params, updates of the protocol etc
    Level_2 // LEVEL_2 - long executor before, payloads controller updates
  }

  /**
   * @notice Object containing the necessary payload information.
   * @param chain
   * @param accessLevel
   * @param payloadsController
   * @param payloadId
   */
  struct Payload {
    uint256 chain;
    AccessControl accessLevel;
    address payloadsController; // address which holds the logic to execute after success proposal voting
    uint40 payloadId; // number of the payload placed to payloadsController, max is: ~10¹²
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from 'aave-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';
import {IPayloadsControllerCore} from './IPayloadsControllerCore.sol';

/**
 * @title IPayloadsController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the PayloadsController contract
 */
interface IPayloadsController is IBaseReceiverPortal, IPayloadsControllerCore {
  /**
   * @notice get contract address from where the messages come
   * @return address of the message registry
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice get chain id of the message originator network
   * @return chain id of the originator network
   */
  function ORIGIN_CHAIN_ID() external view returns (uint256);

  /**
   * @notice get address of the message sender in originator network
   * @return address of the originator contract
   */
  function MESSAGE_ORIGINATOR() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../PayloadsControllerUtils.sol';

/**
 * @title IPayloadsControllerCore
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the IPayloadsControllerCore contract
 */
interface IPayloadsControllerCore {
  /// @notice Enum indicating the possible payload states
  enum PayloadState {
    None, // state 0 left as empty
    Created,
    Queued,
    Executed,
    Cancelled
  }

  /**
   * @notice holds configuration of the executor
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
   * @notice Object containing the information necessary to set a new executor
   * @param accessLevel level of access that the executor will be assigned to
   * @param executor address of the executor to assign
   * @param delay time in seconds between queuing and execution
   * @param gracePeriod time in seconds where the proposal can be executed (from executionTime) before it expires
   */
  struct UpdateExecutorInput {
    PayloadsControllerUtils.AccessControl accessLevel;
    ExecutorConfig executorConfig;
  }

  /**
   * @notice Object containing the information necessary to define a payload action
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
    PayloadsControllerUtils.AccessControl accessLevel;
    uint256 value;
    string signature;
    bytes callData;
  }

  /**
   * @notice Object containing a payload information
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
    PayloadsControllerUtils.AccessControl maximumAccessLevelRequired;
    PayloadState state;
    uint40 createdAt;
    uint40 queuedAt;
    uint40 executedAt;
    uint40 cancelledAt;
    bytes32 ipfsHash;
    ExecutionAction[] actions;
  }

  /**
   * @notice Event emitted when an executor has been set for a determined access level
   * @param accessLevel level of access that the executor will be set to
   * @param executor address that will be set for the determined access level
   * @param delay time in seconds between queuing and execution
   * @param gracePeriod time in seconds where the proposal can be executed (from executionTime) before it expires
   */
  event ExecutorSet(
    PayloadsControllerUtils.AccessControl indexed accessLevel,
    address executor,
    uint48 delay,
    uint48 gracePeriod
  );

  /**
   * @notice Event emitted when a payload has been created
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
    PayloadsControllerUtils.AccessControl indexed maximumAccessLevelRequired,
    bytes32 ipfsHash
  );

  /**
   * @notice Event emitted when block hash aggregator gets updated
   * @param newBridgeAggregator address of the new bridge aggregator
   */
  event BridgeAggregatorUpdated(address newBridgeAggregator);

  /**
   * @notice Event emitted when a payload has been executed
   * @param payloadId id of the payload being enqueued
   */
  event PayloadExecuted(uint40 payloadId);

  /**
   * @notice Event emitted when a payload has been queued
   * @param payloadId id of the payload being enqueued
   */
  event PayloadQueued(uint40 payloadId);

  /**
   * @notice Event emitted when cancelling a payload
   * @param payloadId id of the cancelled payload
   */
  event PayloadCancelled(uint40 payloadId);

  /**
   * @notice Event emitted when updating the expiration delay
   * @param expirationDelay time in seconds of the new expiration delay
   */
  event ExpirationDelayUpdated(uint40 expirationDelay);

  /**
   * @notice method to initialize the contract with starter params. Only callable by proxy
   * @param owner address of the owner of the contract. with permissions to call certain methods
   * @param guardian address of the guardian. With permissions to call certain methods
   * @param expirationDelay time in seconds of the delay with which a payload will expire
   * @param executors array of executor configurations
   */
  function initialize(
    address owner,
    address guardian,
    uint40 expirationDelay,
    UpdateExecutorInput[] calldata executors
  ) external;

  /**
   * @notice get the time in seconds needed for a payload to be expired since it was created
   * @return expiration delay in seconds
   */
  function getExpirationDelay() external view returns (uint40);

  /**
   * @notice method to update the expiration delay time in seconds
   * @param expirationDelay new time in seconds of the expiration delay
   */
  function updateExpirationDelay(uint40 expirationDelay) external;

  /**
   * @notice get a previously created payload object
   * @param payloadId id of the payload to retrieve
   * @return payload information
   */
  function getPayloadById(
    uint40 payloadId
  ) external view returns (Payload memory payload);

  /**
   * @notice get the total count of payloads created
   * @return number of payloads
   */
  function getPayloadsCount() external view returns (uint40);

  /**
   * @notice method that will create a Payload object for every action sent
   * @param actions array of actions that will conform this proposal payload
   * @param ipfsHash hash where the metadata for the proposal payload is hosted
   * @return id of the created payload
   */
  function createPayload(
    ExecutionAction[] calldata actions,
    bytes32 ipfsHash
  ) external returns (uint40);

  /**
   * @notice method to execute a payload
   * @param payloadId id of the payload that needs to be executed
   */
  function executePayload(uint40 payloadId) external;

  /**
   * @notice method to cancel a payload
   * @param payloadId id of the payload that needs to be canceled
   */
  function cancelPayload(uint40 payloadId) external;

  /**
   * @notice method to add executors and its configuration
   * @param executors array of UpdateExecutorInput objects
   */
  function updateExecutors(UpdateExecutorInput[] calldata executors) external;

  /**
   * @notice method to get the executor configuration assigned to the specified level
   * @param accessControl level of which we want to get the grace period from
   * @return executor configuration
   */
  function getExecutorSettingsByAccessControl(
    PayloadsControllerUtils.AccessControl accessControl
  ) external view returns (ExecutorConfig memory);
}