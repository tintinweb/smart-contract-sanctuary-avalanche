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
pragma solidity ^0.8.0;

import {CrossChainMandateUtils} from 'aave-crosschain-mandates/contracts/CrossChainMandateUtils.sol';
import {IMandateProviderProcessor} from 'aave-crosschain-mandates/contracts/interfaces/IMandateProviderProcessor.sol';
import {IMandateProvider} from 'aave-crosschain-mandates/contracts/interfaces/IMandateProvider.sol';
import {IMandateProviderDataHelper} from "./interfaces/IMandateProviderDataHelper.sol";

contract MandateProviderDataHelper is IMandateProviderDataHelper {
  function getPayloadsData(IMandateProviderProcessor mandateProvider, uint40[] calldata payloadsIds)
    external
    view
    returns (Payload[] memory)
    {
      Payload[] memory payloads = new Payload[](payloadsIds.length);
      IMandateProviderProcessor.Payload memory payload;

      for (uint256 i = 0; i < payloadsIds.length; i++) {
        payload = mandateProvider.getPayloadById(payloadsIds[i]);

        payloads[i] = Payload({
          id: payloadsIds[i],
          state: payload.state,
          createdAt: payload.createdAt,
          queuedAt: payload.queuedAt,
          executedAt: payload.executedAt,
          cancelledAt: payload.cancelledAt
        });
      }

      return payloads;
    }

  function getExecutorConfigs(IMandateProviderProcessor mandateProvider, CrossChainMandateUtils.AccessControl[] calldata accessLevels)
    external
    view
    returns (ExecutorConfig[] memory)
    {
      ExecutorConfig[] memory executorConfigs = new ExecutorConfig[](accessLevels.length);
      IMandateProvider.ExecutorConfig memory executorConfig;

      for (uint256 i = 0; i < accessLevels.length; i++) {
        executorConfig = mandateProvider.getExecutorSettingsByAccessControl(accessLevels[i]);

        executorConfigs[i] = ExecutorConfig({
          accessLevel: accessLevels[i],
          executor: executorConfig.executor,
          delay: executorConfig.delay,
          gracePeriod: executorConfig.gracePeriod
        });
      }

      return executorConfigs;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainMandateUtils} from 'aave-crosschain-mandates/contracts/CrossChainMandateUtils.sol';
import {IMandateProviderProcessor} from 'aave-crosschain-mandates/contracts/interfaces/IMandateProviderProcessor.sol';
import {IMandateProvider} from 'aave-crosschain-mandates/contracts/interfaces/IMandateProvider.sol';

interface IMandateProviderDataHelper {
  struct Payload {
    uint256 id;
    IMandateProvider.PayloadState state;
    uint40 createdAt;
    uint40 queuedAt;
    uint40 executedAt;
    uint40 cancelledAt;
  }

  struct ExecutorConfig {
    CrossChainMandateUtils.AccessControl accessLevel;
    address executor;
    uint48 delay;
    uint48 gracePeriod;
  }

  function getPayloadsData(IMandateProviderProcessor mandateProvider, uint40[] calldata payloadsIds)
    external
    view
    returns (Payload[] memory);

  function getExecutorConfigs(IMandateProviderProcessor mandateProvider, CrossChainMandateUtils.AccessControl[] calldata accessLevels)
    external
    view
    returns (ExecutorConfig[] memory);
}