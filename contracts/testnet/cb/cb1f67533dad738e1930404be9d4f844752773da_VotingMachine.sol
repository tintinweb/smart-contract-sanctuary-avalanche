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
pragma solidity ^0.8.8;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainForwarder {
  /**
   * @dev object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @dev object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    CrossChainUtils.Chains[] chainIds;
  }

  /**
   * @dev object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param dstChainId id of the destination chain using our own nomenclature
   */
  struct BridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    CrossChainUtils.Chains destinationChainId;
  }

  /**
   * @dev emitted when a bridge adapter failed to send a message
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   * @param returndata bytes with error information
   */
  event AdapterFailed(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message,
    bytes returndata
  );

  /**
   * @dev emitted when a message is successfully forwarded through a bridge adapter
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   */
  event MessageForwarded(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message
  );

  /**
   * @dev emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /// @dev method to get the current sent message nonce
  function currentNonce() external view returns (uint256);

  /**
   * @dev method to check if a message has been previously forwarded.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   */
  function isMessageForwarded(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    bytes memory message
  ) external view returns (bool);

  /**
   * @dev method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   */
  function forwardMessage(
    CrossChainUtils.Chains destinationChainId,
    address destination,
    bytes memory message
  ) external;

  /**
   * @dev method called to re forward a previously sent message.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   */
  function retryMessage(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    bytes memory message
  ) external;

  /**
   * @dev method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(
    BridgeAdapterConfigInput[] memory bridgeAdapters
  ) external;

  /**
   * @dev method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(BridgeAdapterToDisable[] memory bridgeAdapters)
    external;

  /**
   * @dev method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @dev method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @dev method to get all the bridge adapters of a chain
   * @param chainId id of the chain we want to get the adateprs from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getBridgeAdaptersByChain(CrossChainUtils.Chains chainId)
    external
    view
    returns (ChainIdBridgeConfig[] memory);

  /**
   * @dev method to get if a sender is approved
   * @param sender address that we want to check if approved
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';

interface ICrossChainManager is ICrossChainForwarder, ICrossChainReceiver {
  /**
   * @dev method called to initialize the proxy
   * @param owner address of the owner of the cross chain manager
   * @param guardian address of the guardian of the cross chain manager
   * @param clEmergencyOracle address of the chainlink emergency oracle
   * @param initialRequiredConfirmations number of confirmations the messages need to be accepted as valid
   * @param receiverBridgeAdaptersToAllow array of addresses of the bridge adapters that can receive messages
   * @param forwarderBridgeAdaptersToEnable array specifying for every bridgeAdapter, the destinations it can have
   * @param sendersToApprove array of addresses to allow as forwarders
   */
  function initialize(
    address owner,
    address guardian,
    address clEmergencyOracle,
    uint256 initialRequiredConfirmations,
    address[] memory receiverBridgeAdaptersToAllow,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    address[] memory sendersToApprove
  ) external;

  /**
   * @dev method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(
    address erc20Token,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
  * @dev method to check if there is a new emergency state, indicated by chainlink emergency oracle.
         This method is callable by anyone as a new emergency will be determined by the oracle, and this way
         it will be easier / faster to enter into emergency.
  */
  function solveEmergency(
    uint256 newConfirmations,
    uint120 newValidityTimestamp,
    address[] memory receiverBridgeAdaptersToAllow,
    address[] memory receiverBridgeAdaptersToDisallow,
    address[] memory sendersToApprove,
    address[] memory sendersToRemove,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    BridgeAdapterToDisable[] memory forwarderBridgeAdaptersToDisable
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainReceiver {
  /**
   * @dev object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   */
  struct InternalBridgedMessageStateWithoutAdapters {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
  }
  /**
   * @dev object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   * @param bridgedByAdapter list of bridge adapters that have bridged the message
   */
  struct InternalBridgedMessage {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
    mapping(address => bool) bridgedByAdapter;
  }

  /**
   * @dev emitted when a message has reached the necessary number of confirmations
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated
   * @param message bytes confirmed
   */
  event MessageConfirmed(
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message
  );

  /**
   * @dev emitted when a message has been received successfully
   * @param internalId message id assigned on the manager, used for internal purposes: hash(to, from, message)
   * @param bridgeAdapter address of the bridge adapter who received the message (deployed on current network)
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated (CrossChainManager on origin chain)
   * @param message bytes bridged
   * @param confirmations number of current confirmations for this message
   */
  event MessageReceived(
    bytes32 internalId,
    address indexed bridgeAdapter,
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message,
    uint256 confirmations
  );

  /**
   * @dev emitted when a bridge adapter gets disallowed
   * @param brigeAdapter address of the disallowed bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed brigeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   */
  event ConfirmationsUpdated(uint256 newConfirmations);

  /**
   * @dev emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   */
  event NewInvalidation(uint256 invalidTimestamp);

  /// @dev method to get the needed confirmations for a message to be accepted as valid
  function requiredConfirmations() external view returns (uint256);

  /// @dev method to get the timestamp from where the messages will be valid
  function validityTimestamp() external view returns (uint120);

  /**
   * @dev method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the brige adapter to check
   * @return boolean indicating if brige adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(address bridgeAdapter)
    external
    view
    returns (bool);

  /**
   * @dev  method to get the internal message information
   * @param internalId hash(originChain + payload) identifying the message internally
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getInternalMessageState(bytes32 internalId)
    external
    view
    returns (InternalBridgedMessageStateWithoutAdapters memory);

  /**
   * @dev method to get if message has been received by bridge adapter
   * @param internalId id of the message as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * return array of addresses
   */
  function isInternalMessageReceivedByAdapter(
    bytes32 internalId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @dev method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp timestamp where all the previous unconfirmed messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(uint120 newValidityTimestamp)
    external;

  /**
   * @dev method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations new number of needed confirmations
   */
  function updateConfirmations(uint256 newConfirmations) external;

  /**
   * @dev method that registers a received message, updates the confirmations, and sets it as valid if number
   of confirmations has been reached.
   * @param payload bytes of the payload, containing the information to operate with it
   */
  function receiveCrossChainMessage(
    bytes memory payload,
    CrossChainUtils.Chains originChainId
  ) external;

  /**
   * @dev method to add bridge adapters to the allowed list
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function allowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;

  /**
   * @dev method to remove bridge adapters from the allowed list
   * @param bridgeAdapters array of bridge adapter addresses to remove from the allow list
   */
  function disallowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;
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
pragma solidity ^0.8.0;

import {ICrossChainManager} from 'ghost-crosschain-infra/contracts/interfaces/ICrossChainManager.sol';
import {IVotingMachine, CrossChainUtils} from './interfaces/IVotingMachine.sol';
import {VotingMachineWithProofs, IRootsWarehouse, IBaseVotingStrategy, IVotingMachineWithProofs} from './VotingMachineWithProofs.sol';
import {IBaseReceiverPortal} from 'ghost-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';

contract VotingMachine is
  IBaseReceiverPortal,
  IVotingMachine,
  VotingMachineWithProofs
{
  address public immutable CROSS_CHAIN_MANAGER;
  CrossChainUtils.Chains public immutable L1_VOTING_PORTAL_CHAIN_ID;

  address internal _l1VotingPortal;

  constructor(
    address crossChainManager,
    address l1VotingPortal,
    CrossChainUtils.Chains l1VotingPortalChainId,
    IRootsWarehouse rootsWarehouse,
    IBaseVotingStrategy votingStrategy
  ) VotingMachineWithProofs(rootsWarehouse, votingStrategy) {
    CROSS_CHAIN_MANAGER = crossChainManager;
    L1_VOTING_PORTAL_CHAIN_ID = l1VotingPortalChainId;

    _updateL1VotingPortal(l1VotingPortal);
  }

  function updateL1VotingPortal(address l1VotingPortal) external onlyOwner {
    _updateL1VotingPortal(l1VotingPortal);
  }

  function getL1VotingPortal() external view returns (address) {
    return _l1VotingPortal;
  }

  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external {
    require(
      msg.sender == CROSS_CHAIN_MANAGER &&
        originSender == _l1VotingPortal &&
        originChainId == L1_VOTING_PORTAL_CHAIN_ID,
      'WRONG_MESSAGE_ORIGIN'
    );

    (uint256 proposalId, bytes32 blockHash, uint24 votingDuration) = abi.decode(
      message,
      (uint256, bytes32, uint24)
    );

    _proposalsReadyForCreation[proposalId] = IVotingMachineWithProofs
      .CreateVoteConfig({
        votingDuration: votingDuration,
        l1ProposalBlockHash: blockHash
      });

    address[] memory votingAssets = IBaseVotingStrategy(
      address(_votingStrategy)
    ).getVotingAssetList();
    if (hasAvailableRootsForAssets(blockHash, votingAssets)) {
      createVote(proposalId);
    }
  }

  function _updateL1VotingPortal(address l1VotingPortal) internal {
    _l1VotingPortal = l1VotingPortal;

    emit L1VotingPortalUpdated(l1VotingPortal);
  }

  /**
   * @dev method to send the vote result to the voting portal on governance chain
   * @param proposalId id of the proposal voted on
   * @param forVotes votes in favor of the proposal
   * @param againstVotes votes against the proposal
   */
  function _sendVoteResults(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal override {
    ICrossChainManager(CROSS_CHAIN_MANAGER).forwardMessage(
      L1_VOTING_PORTAL_CHAIN_ID,
      _l1VotingPortal,
      abi.encode(proposalId, forVotes, againstVotes)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {StateProofVerifier} from './libs/StateProofVerifier.sol';
import {IVotingMachineWithProofs, IRootsWarehouse, IBaseVotingStrategy, CrossChainUtils} from './interfaces/IVotingMachineWithProofs.sol';

abstract contract VotingMachineWithProofs is IVotingMachineWithProofs, Ownable {
  /// @inheritdoc IVotingMachineWithProofs
  uint256 public constant BLOCKS_TO_FINALITY = 20;

  mapping(uint256 => Proposal) private _proposals;

  IRootsWarehouse internal _rootsWarehouse;

  IBaseVotingStrategy internal _votingStrategy;

  mapping(uint256 => CreateVoteConfig) _proposalsReadyForCreation;

  constructor(
    IRootsWarehouse newRootsWarehouse,
    IBaseVotingStrategy newVotingStrategy
  ) Ownable() {
    _setRootsWarehouse(newRootsWarehouse);
    _setVotingStrategy(newVotingStrategy);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function isProposalReadyForCreation(uint256 proposalId)
    external
    view
    returns (CreateVoteConfig memory)
  {
    return _proposalsReadyForCreation[proposalId];
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getRootsWarehouse() external view returns (IRootsWarehouse) {
    return _rootsWarehouse;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getVotingStrategy() external view returns (IBaseVotingStrategy) {
    return _votingStrategy;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function createVote(uint256 proposalId) public returns (uint256) {
    CreateVoteConfig memory voteConfig = _proposalsReadyForCreation[proposalId];

    Proposal storage newProposal = _proposals[proposalId];

    require(
      _getProposalState(newProposal) == ProposalState.NotCreated,
      'DUPLICATED_PROPOSAL'
    );

    IBaseVotingStrategy currentVotingStrategy = _votingStrategy;
    address[] memory votingAssets = IBaseVotingStrategy(
      address(currentVotingStrategy)
    ).getVotingAssetList();
    require(votingAssets.length != 0, 'NO_VOTING_ASSETS');

    require(
      hasAvailableRootsForAssets(voteConfig.l1ProposalBlockHash, votingAssets),
      'ROOT_STATE_HASH_NOT_AVAILABLE'
    );

    uint256 startTime = _getCurrentTimeRef();
    uint256 endTime = startTime + voteConfig.votingDuration;

    newProposal.id = proposalId;
    newProposal.l1BlockHash = voteConfig.l1ProposalBlockHash;
    newProposal.startTime = startTime;
    newProposal.endTime = endTime;
    newProposal.strategy = currentVotingStrategy;

    emit ProposalCreated(
      proposalId,
      voteConfig.l1ProposalBlockHash,
      startTime,
      endTime,
      address(currentVotingStrategy)
    );

    return newProposal.id;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function hasAvailableRootsForAssets(
    bytes32 blockHash,
    address[] memory votingAssets
  ) public view returns (bool) {
    uint256 hasRoots;
    for (uint256 i = 0; i < votingAssets.length; i++) {
      if (
        (_rootsWarehouse.getStorageRoots(votingAssets[i], blockHash)) !=
        bytes32(0)
      ) {
        hasRoots++;
      }
    }

    return hasRoots == votingAssets.length;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function submitVote(
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == ProposalState.Active,
      'PROPOSAL_NOT_IN_ACTIVE_STATE'
    );

    Vote storage vote = proposal.votes[msg.sender];
    require(vote.votingPower == 0, 'VOTE_ALREADY_EXISTS');

    uint256 votingPower;
    StateProofVerifier.SlotValue memory balanceVotingPower;
    for (uint256 i = 0; i < votingBalanceProofs.length; i++) {
      balanceVotingPower = _rootsWarehouse.getStorage(
        votingBalanceProofs[i].underlyingAsset,
        _proposals[proposalId].l1BlockHash,
        slotOfAddressUint256Mapping(msg.sender, votingBalanceProofs[i].slot),
        votingBalanceProofs[i].proof
      );
      // TODO: I don't know, looks useless
      require(balanceVotingPower.exists, 'USER_BALANCE_DOES_NOT_EXISTS');

      if (balanceVotingPower.value != 0) {
        votingPower += _votingStrategy.getWeightedPower(
          votingBalanceProofs[i].underlyingAsset,
          votingBalanceProofs[i].slot,
          balanceVotingPower.value
        );
      }
    }
    require(votingPower != 0, 'USER_VOTING_BALANCE_IS_ZERO');

    if (support) {
      proposal.forVotes += votingPower;
    } else {
      proposal.againstVotes += votingPower;
    }

    vote.support = support;
    vote.votingPower = uint248(votingPower);

    emit VoteEmitted(proposalId, msg.sender, support, votingPower);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getUserProposalVote(address user, uint256 proposalId)
    external
    view
    returns (Vote memory)
  {
    return _proposals[proposalId].votes[user];
  }

  /// @inheritdoc IVotingMachineWithProofs
  function closeVote(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == ProposalState.Finished,
      'INVALID_STATE_TO_CLOSE_VOTE'
    );
    proposal.votingEndedBlock = block.number;

    emit ProposalVoteClosed(proposalId, block.number);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function sendVoteResult(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];

    require(
      _getProposalState(proposal) == ProposalState.WaitingForFinality,
      'INVALID_STATE_TO_SEND_RESULTS'
    );
    require(
      (block.number - BLOCKS_TO_FINALITY) > proposal.votingEndedBlock,
      'NOT_ENOUGH_BLOCKS_TO_FINAL'
    );

    uint256 forVotes = proposal.forVotes;
    uint256 againstVotes = proposal.againstVotes;

    _sendVoteResults(proposalId, forVotes, againstVotes);

    proposal.sentToL1 = true;
    emit ProposalResultsSent(proposalId, forVotes, againstVotes);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalById(uint256 proposalId)
    external
    view
    returns (ProposalWithoutVotes memory)
  {
    Proposal storage proposal = _proposals[proposalId];
    ProposalWithoutVotes memory proposalWithoutVotes = ProposalWithoutVotes({
      id: proposal.id,
      l1BlockHash: proposal.l1BlockHash,
      startTime: proposal.startTime,
      endTime: proposal.endTime,
      forVotes: proposal.forVotes,
      againstVotes: proposal.againstVotes,
      votingEndedBlock: proposal.votingEndedBlock,
      strategy: proposal.strategy,
      sentToL1: proposal.sentToL1
    });

    return proposalWithoutVotes;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function slotOfAddressUint256Mapping(
    address holder,
    uint256 balanceMappingPosition
  ) public pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          bytes32(uint256(uint160(holder))),
          balanceMappingPosition
        )
      );
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalState(uint256 proposalId)
    external
    view
    returns (ProposalState)
  {
    return _getProposalState(_proposals[proposalId]);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function setRootsWarehouse(IRootsWarehouse newRootsWarehouse)
    external
    onlyOwner
  {
    _setRootsWarehouse(newRootsWarehouse);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function setVotingStrategy(IBaseVotingStrategy newVotingStrategy)
    external
    onlyOwner
  {
    _setVotingStrategy(newVotingStrategy);
  }

  function _sendVoteResults(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal virtual;

  function _setRootsWarehouse(IRootsWarehouse newRootsWarehouse) internal {
    address oldRootsWarehouse = address(_rootsWarehouse);
    _rootsWarehouse = newRootsWarehouse;
    emit RootsWarehouseUpdated(oldRootsWarehouse, address(newRootsWarehouse));
  }

  function _setVotingStrategy(IBaseVotingStrategy newVotingStrategy) internal {
    address oldVotingStrategy = address(_votingStrategy);
    _votingStrategy = newVotingStrategy;
    emit VotingStrategyUpdated(oldVotingStrategy, address(newVotingStrategy));
  }

  function _getProposalState(Proposal storage proposal)
    internal
    view
    returns (ProposalState)
  {
    if (proposal.endTime == 0) {
      return ProposalState.NotCreated;
    } else if (_getCurrentTimeRef() <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.sentToL1) {
      return ProposalState.SentToL1;
    } else if (proposal.votingEndedBlock == 0) {
      return ProposalState.Finished;
    } else {
      return ProposalState.WaitingForFinality;
    }
  }

  function _getCurrentTimeRef() internal view returns (uint256) {
    return block.timestamp;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {StateProofVerifier} from '../libs/StateProofVerifier.sol';

interface IRootsWarehouse {
  function getStorageRoots(address account, bytes32 blockHash)
    external
    view
    returns (bytes32);

  function processStorageRoot(
    address account,
    bytes32 blockHash,
    bytes memory blockHeaderRLP,
    bytes memory accountStateProofRLP
  ) external returns (bytes32);

  function getStorage(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes memory storageProof
  ) external view returns (StateProofVerifier.SlotValue memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IBaseReceiverPortal} from 'ghost-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';

interface IVotingMachine is IBaseReceiverPortal {
  event L1VotingPortalUpdated(address indexed l1VotingPortal);

  function L1_VOTING_PORTAL_CHAIN_ID()
    external
    view
    returns (CrossChainUtils.Chains);

  function CROSS_CHAIN_MANAGER() external view returns (address);

  function updateL1VotingPortal(address l1VotingPortal) external;

  function getL1VotingPortal() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseVotingStrategy} from '../../../interfaces/IBaseVotingStrategy.sol';
import {IRootsWarehouse} from './IRootsWarehouse.sol';
import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';

interface IVotingMachineWithProofs {
  enum ProposalState {
    NotCreated,
    Active,
    Finished,
    WaitingForFinality,
    SentToL1
  }

  struct Vote {
    bool support;
    uint248 votingPower;
  }

  struct Proposal {
    uint256 id;
    bytes32 l1BlockHash; // l1 block hash when the proposal was created
    uint256 startTime;
    uint256 endTime;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 votingEndedBlock;
    bool sentToL1;
    IBaseVotingStrategy strategy;
    mapping(address => Vote) votes;
  }
  struct ProposalWithoutVotes {
    uint256 id;
    bytes32 l1BlockHash; // l1 block hash when the proposal was created
    uint256 startTime;
    uint256 endTime;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 votingEndedBlock;
    bool sentToL1;
    IBaseVotingStrategy strategy;
  }

  struct CreateVoteConfig {
    uint24 votingDuration;
    //    uint40 creationTime; TODO: for now we will not use. should be to check that it has not been to long since bridged
    bytes32 l1ProposalBlockHash;
  }

  struct VotingBalanceProof {
    address underlyingAsset;
    uint128 slot;
    bytes proof;
  }

  event ProposalCreated(
    uint256 indexed proposalId,
    bytes32 indexed l1BlockHash,
    uint256 startTime,
    uint256 endTime,
    address strategy
  );

  event ProposalVoteClosed(uint256 indexed proposalId, uint256 endedBlock);

  event ProposalResultsSent(
    uint256 indexed proposalId,
    uint256 forVotes,
    uint256 againstVotes
  );

  /**
   * @dev emitted when a vote is registered
   * @param proposalId Id of the proposal
   * @param voter address of the voter
   * @param support boolean, true = vote for, false = vote against
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(
    uint256 indexed proposalId,
    address indexed voter,
    bool support,
    uint256 votingPower
  );

  event RootsWarehouseUpdated(
    address oldRootsWarehouse,
    address newRootsWarehouse
  );

  event VotingStrategyUpdated(
    address oldVotingStrategy,
    address newVotingStrategy
  );

  event L2SideBridgeUpdated(address oldL2SideBridge, address newL2SideBridge);

  function BLOCKS_TO_FINALITY() external view returns (uint256);

  function getRootsWarehouse() external view returns (IRootsWarehouse);

  function getVotingStrategy() external view returns (IBaseVotingStrategy);

  function hasAvailableRootsForAssets(
    bytes32 blockHash,
    address[] memory votingAssets
  ) external view returns (bool);

  function slotOfAddressUint256Mapping(
    address holder,
    uint256 balanceMappingPosition
  ) external pure returns (bytes32);

  function createVote(uint256 proposalId) external returns (uint256);

  function submitVote(
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external;

  function getUserProposalVote(address user, uint256 proposalId)
    external
    view
    returns (Vote memory);

  function closeVote(uint256 proposalId) external;

  function sendVoteResult(uint256 proposalId) external;

  function setRootsWarehouse(IRootsWarehouse newRootsWarehouse) external;

  function setVotingStrategy(IBaseVotingStrategy newVotingStrategy) external;

  function getProposalById(uint256 proposalId)
    external
    view
    returns (ProposalWithoutVotes memory);

  function getProposalState(uint256 proposalId)
    external
    view
    returns (ProposalState);

  function isProposalReadyForCreation(uint256 proposalId)
    external
    view
    returns (CreateVoteConfig memory);
}

// SPDX-License-Identifier: MIT

/**
 * Copied from https://github.com/lorenzb/proveth/blob/c74b20e/onchain/ProvethVerifier.sol
 * with minor performance and code style-related modifications.
 */
pragma solidity ^0.8.0;

import {RLPReader} from './RLPReader.sol';

library MerklePatriciaProofVerifier {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for bytes;

  /// @dev Validates a Merkle-Patricia-Trie proof.
  ///      If the proof proves the inclusion of some key-value pair in the
  ///      trie, the value is returned. Otherwise, i.e. if the proof proves
  ///      the exclusion of a key from the trie, an empty byte array is
  ///      returned.
  /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
  /// @param path is the key of the node whose inclusion/exclusion we are
  ///        proving.
  /// @param stack is the stack of MPT nodes (starting with the root) that
  ///        need to be traversed during verification.
  /// @return value whose inclusion is proved or an empty byte array for
  ///         a proof of exclusion
  function extractProofValue(
    bytes32 rootHash,
    bytes memory path,
    RLPReader.RLPItem[] memory stack
  ) internal pure returns (bytes memory value) {
    bytes memory mptKey = _decodeNibbles(path, 0);
    uint256 mptKeyOffset = 0;

    bytes32 nodeHashHash;
    RLPReader.RLPItem[] memory node;

    RLPReader.RLPItem memory rlpValue;

    if (stack.length == 0) {
      // Root hash of empty Merkle-Patricia-Trie
      require(
        rootHash ==
          0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421
      );
      return new bytes(0);
    }

    // Traverse stack of nodes starting at root.
    for (uint256 i = 0; i < stack.length; i++) {
      // We use the fact that an rlp encoded list consists of some
      // encoding of its length plus the concatenation of its
      // *rlp-encoded* items.

      // The root node is hashed with Keccak-256 ...
      if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
        revert();
      }
      // ... whereas all other nodes are hashed with the MPT
      // hash function.
      if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
        revert();
      }
      // We verified that stack[i] has the correct hash, so we
      // may safely decode it.
      node = stack[i].toList();

      if (node.length == 2) {
        // Extension or Leaf node

        bool isLeaf;
        bytes memory nodeKey;
        (isLeaf, nodeKey) = _merklePatriciaCompactDecode(node[0].toBytes());

        uint256 prefixLength = _sharedPrefixLength(
          mptKeyOffset,
          mptKey,
          nodeKey
        );
        mptKeyOffset += prefixLength;

        if (prefixLength < nodeKey.length) {
          // Proof claims divergent extension or leaf. (Only
          // relevant for proofs of exclusion.)
          // An Extension/Leaf node is divergent iff it "skips" over
          // the point at which a Branch node should have been had the
          // excluded key been included in the trie.
          // Example: Imagine a proof of exclusion for path [1, 4],
          // where the current node is a Leaf node with
          // path [1, 3, 3, 7]. For [1, 4] to be included, there
          // should have been a Branch node at [1] with a child
          // at 3 and a child at 4.

          // Sanity check
          if (i < stack.length - 1) {
            // divergent node must come last in proof
            revert();
          }

          return new bytes(0);
        }

        if (isLeaf) {
          // Sanity check
          if (i < stack.length - 1) {
            // leaf node must come last in proof
            revert();
          }

          if (mptKeyOffset < mptKey.length) {
            return new bytes(0);
          }

          rlpValue = node[1];
          return rlpValue.toBytes();
        } else {
          // extension
          // Sanity check
          if (i == stack.length - 1) {
            // shouldn't be at last level
            revert();
          }

          if (!node[1].isList()) {
            // rlp(child) was at least 32 bytes. node[1] contains
            // Keccak256(rlp(child)).
            nodeHashHash = node[1].payloadKeccak256();
          } else {
            // rlp(child) was less than 32 bytes. node[1] contains
            // rlp(child).
            nodeHashHash = node[1].rlpBytesKeccak256();
          }
        }
      } else if (node.length == 17) {
        // Branch node

        if (mptKeyOffset != mptKey.length) {
          // we haven't consumed the entire path, so we need to look at a child
          uint8 nibble = uint8(mptKey[mptKeyOffset]);
          mptKeyOffset += 1;
          if (nibble >= 16) {
            // each element of the path has to be a nibble
            revert();
          }

          if (_isEmptyBytesequence(node[nibble])) {
            // Sanity
            if (i != stack.length - 1) {
              // leaf node should be at last level
              revert();
            }

            return new bytes(0);
          } else if (!node[nibble].isList()) {
            nodeHashHash = node[nibble].payloadKeccak256();
          } else {
            nodeHashHash = node[nibble].rlpBytesKeccak256();
          }
        } else {
          // we have consumed the entire mptKey, so we need to look at what's contained in this node.

          // Sanity
          if (i != stack.length - 1) {
            // should be at last level
            revert();
          }

          return node[16].toBytes();
        }
      }
    }
  }

  /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the RLP item.
  ///      Merkle-Patricia-Tries use a weird "hash function" that outputs
  ///      *variable-length* hashes: If the item is shorter than 32 bytes,
  ///      the MPT hash is the item. Otherwise, the MPT hash is the
  ///      Keccak-256 hash of the item.
  ///      The easiest way to compare variable-length byte sequences is
  ///      to compare their Keccak-256 hashes.
  /// @param item The RLP item to be hashed.
  /// @return Keccak-256(MPT-hash(item))
  function _mptHashHash(RLPReader.RLPItem memory item)
    private
    pure
    returns (bytes32)
  {
    if (item.len < 32) {
      return item.rlpBytesKeccak256();
    } else {
      return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
    }
  }

  function _isEmptyBytesequence(RLPReader.RLPItem memory item)
    private
    pure
    returns (bool)
  {
    if (item.len != 1) {
      return false;
    }
    uint8 b;
    uint256 memPtr = item.memPtr;
    assembly {
      b := byte(0, mload(memPtr))
    }
    return b == 0x80; /* empty byte string */
  }

  function _merklePatriciaCompactDecode(bytes memory compact)
    private
    pure
    returns (bool isLeaf, bytes memory nibbles)
  {
    require(compact.length > 0);
    uint256 first_nibble = (uint8(compact[0]) >> 4) & 0xF;
    uint256 skipNibbles;
    if (first_nibble == 0) {
      skipNibbles = 2;
      isLeaf = false;
    } else if (first_nibble == 1) {
      skipNibbles = 1;
      isLeaf = false;
    } else if (first_nibble == 2) {
      skipNibbles = 2;
      isLeaf = true;
    } else if (first_nibble == 3) {
      skipNibbles = 1;
      isLeaf = true;
    } else {
      // Not supposed to happen!
      revert();
    }
    return (isLeaf, _decodeNibbles(compact, skipNibbles));
  }

  function _decodeNibbles(bytes memory compact, uint256 skipNibbles)
    private
    pure
    returns (bytes memory nibbles)
  {
    require(compact.length > 0);

    uint256 length = compact.length * 2;
    require(skipNibbles <= length);
    length -= skipNibbles;

    nibbles = new bytes(length);
    uint256 nibblesLength = 0;

    for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
      if (i % 2 == 0) {
        nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 4) & 0xF);
      } else {
        nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 0) & 0xF);
      }
      nibblesLength += 1;
    }

    assert(nibblesLength == nibbles.length);
  }

  function _sharedPrefixLength(
    uint256 xsOffset,
    bytes memory xs,
    bytes memory ys
  ) private pure returns (uint256) {
    uint256 i;
    for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
      if (xs[i + xsOffset] != ys[i]) {
        return i;
      }
    }
    return i;
  }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.8.0;

library RLPReader {
  uint8 constant STRING_SHORT_START = 0x80;
  uint8 constant STRING_LONG_START = 0xb8;
  uint8 constant LIST_SHORT_START = 0xc0;
  uint8 constant LIST_LONG_START = 0xf8;
  uint8 constant WORD_SIZE = 32;

  struct RLPItem {
    uint256 len;
    uint256 memPtr;
  }

  struct Iterator {
    RLPItem item; // Item that's being iterated over.
    uint256 nextPtr; // Position of the next item in the list.
  }

  /*
   * @dev Returns the next element in the iteration. Reverts if it has not next element.
   * @param self The iterator.
   * @return The next element in the iteration.
   */
  function next(Iterator memory self) internal pure returns (RLPItem memory) {
    require(hasNext(self));

    uint256 ptr = self.nextPtr;
    uint256 itemLength = _itemLength(ptr);
    self.nextPtr = ptr + itemLength;

    return RLPItem(itemLength, ptr);
  }

  /*
   * @dev Returns true if the iteration has more elements.
   * @param self The iterator.
   * @return true if the iteration has more elements.
   */
  function hasNext(Iterator memory self) internal pure returns (bool) {
    RLPItem memory item = self.item;
    return self.nextPtr < item.memPtr + item.len;
  }

  /*
   * @param item RLP encoded bytes
   */
  function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
    uint256 memPtr;
    assembly {
      memPtr := add(item, 0x20)
    }

    return RLPItem(item.length, memPtr);
  }

  /*
   * @dev Create an iterator. Reverts if item is not a list.
   * @param self The RLP item.
   * @return An 'Iterator' over the item.
   */
  function iterator(RLPItem memory self)
    internal
    pure
    returns (Iterator memory)
  {
    require(isList(self));

    uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
    return Iterator(self, ptr);
  }

  /*
   * @param the RLP item.
   */
  function rlpLen(RLPItem memory item) internal pure returns (uint256) {
    return item.len;
  }

  /*
   * @param the RLP item.
   * @return (memPtr, len) pair: location of the item's payload in memory.
   */
  function payloadLocation(RLPItem memory item)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 offset = _payloadOffset(item.memPtr);
    uint256 memPtr = item.memPtr + offset;
    uint256 len = item.len - offset; // data length
    return (memPtr, len);
  }

  /*
   * @param the RLP item.
   */
  function payloadLen(RLPItem memory item) internal pure returns (uint256) {
    (, uint256 len) = payloadLocation(item);
    return len;
  }

  /*
   * @param the RLP item containing the encoded list.
   */
  function toList(RLPItem memory item)
    internal
    pure
    returns (RLPItem[] memory)
  {
    require(isList(item));

    uint256 items = numItems(item);
    RLPItem[] memory result = new RLPItem[](items);

    uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 dataLen;
    for (uint256 i = 0; i < items; i++) {
      dataLen = _itemLength(memPtr);
      result[i] = RLPItem(dataLen, memPtr);
      memPtr = memPtr + dataLen;
    }

    return result;
  }

  // @return indicator whether encoded payload is a list. negate this function call for isData.
  function isList(RLPItem memory item) internal pure returns (bool) {
    if (item.len == 0) return false;

    uint8 byte0;
    uint256 memPtr = item.memPtr;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < LIST_SHORT_START) return false;
    return true;
  }

  /*
   * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
   * @return keccak256 hash of RLP encoded bytes.
   */
  function rlpBytesKeccak256(RLPItem memory item)
    internal
    pure
    returns (bytes32)
  {
    uint256 ptr = item.memPtr;
    uint256 len = item.len;
    bytes32 result;
    assembly {
      result := keccak256(ptr, len)
    }
    return result;
  }

  /*
   * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
   * @return keccak256 hash of the item payload.
   */
  function payloadKeccak256(RLPItem memory item)
    internal
    pure
    returns (bytes32)
  {
    (uint256 memPtr, uint256 len) = payloadLocation(item);
    bytes32 result;
    assembly {
      result := keccak256(memPtr, len)
    }
    return result;
  }

  /** RLPItem conversions into data types **/

  // @returns raw rlp encoding in bytes
  function toRlpBytes(RLPItem memory item)
    internal
    pure
    returns (bytes memory)
  {
    bytes memory result = new bytes(item.len);
    if (result.length == 0) return result;

    uint256 ptr;
    assembly {
      ptr := add(0x20, result)
    }

    copy(item.memPtr, ptr, item.len);
    return result;
  }

  // any non-zero byte except "0x80" is considered true
  function toBoolean(RLPItem memory item) internal pure returns (bool) {
    require(item.len == 1);
    uint256 result;
    uint256 memPtr = item.memPtr;
    assembly {
      result := byte(0, mload(memPtr))
    }

    // SEE Github Issue #5.
    // Summary: Most commonly used RLP libraries (i.e Geth) will encode
    // "0" as "0x80" instead of as "0". We handle this edge case explicitly
    // here.
    if (result == 0 || result == STRING_SHORT_START) {
      return false;
    } else {
      return true;
    }
  }

  function toAddress(RLPItem memory item) internal pure returns (address) {
    // 1 byte for the length prefix
    require(item.len == 21);

    return address(uint160(toUint(item)));
  }

  function toUint(RLPItem memory item) internal pure returns (uint256) {
    require(item.len > 0 && item.len <= 33);

    (uint256 memPtr, uint256 len) = payloadLocation(item);

    uint256 result;
    assembly {
      result := mload(memPtr)

      // shfit to the correct location if neccesary
      if lt(len, 32) {
        result := div(result, exp(256, sub(32, len)))
      }
    }

    return result;
  }

  // enforces 32 byte length
  function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
    // one byte prefix
    require(item.len == 33);

    uint256 result;
    uint256 memPtr = item.memPtr + 1;
    assembly {
      result := mload(memPtr)
    }

    return result;
  }

  function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
    require(item.len > 0);

    (uint256 memPtr, uint256 len) = payloadLocation(item);
    bytes memory result = new bytes(len);

    uint256 destPtr;
    assembly {
      destPtr := add(0x20, result)
    }

    copy(memPtr, destPtr, len);
    return result;
  }

  /*
   * Private Helpers
   */

  // @return number of payload items inside an encoded list.
  function numItems(RLPItem memory item) private pure returns (uint256) {
    if (item.len == 0) return 0;

    uint256 count = 0;
    uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
    uint256 endPtr = item.memPtr + item.len;
    while (currPtr < endPtr) {
      currPtr = currPtr + _itemLength(currPtr); // skip over an item
      count++;
    }

    return count;
  }

  // @return entire rlp item byte length
  function _itemLength(uint256 memPtr) private pure returns (uint256) {
    uint256 itemLen;
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) itemLen = 1;
    else if (byte0 < STRING_LONG_START)
      itemLen = byte0 - STRING_SHORT_START + 1;
    else if (byte0 < LIST_SHORT_START) {
      assembly {
        let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
        memPtr := add(memPtr, 1) // skip over the first byte

        /* 32 byte word size */
        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
        itemLen := add(dataLen, add(byteLen, 1))
      }
    } else if (byte0 < LIST_LONG_START) {
      itemLen = byte0 - LIST_SHORT_START + 1;
    } else {
      assembly {
        let byteLen := sub(byte0, 0xf7)
        memPtr := add(memPtr, 1)

        let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
        itemLen := add(dataLen, add(byteLen, 1))
      }
    }

    return itemLen;
  }

  // @return number of bytes until the data
  function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < STRING_SHORT_START) return 0;
    else if (
      byte0 < STRING_LONG_START ||
      (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)
    ) return 1;
    else if (byte0 < LIST_SHORT_START)
      // being explicit
      return byte0 - (STRING_LONG_START - 1) + 1;
    else return byte0 - (LIST_LONG_START - 1) + 1;
  }

  /*
   * @param src Pointer to source
   * @param dest Pointer to destination
   * @param len Amount of memory to copy from the source
   */
  function copy(
    uint256 src,
    uint256 dest,
    uint256 len
  ) private pure {
    if (len == 0) return;

    // copy as many word sizes as possible
    for (; len >= WORD_SIZE; len -= WORD_SIZE) {
      assembly {
        mstore(dest, mload(src))
      }

      src += WORD_SIZE;
      dest += WORD_SIZE;
    }

    if (len > 0) {
      // left over bytes. Mask is used to remove unwanted bytes from the word
      uint256 mask = 256**(WORD_SIZE - len) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask)) // zero out src
        let destpart := and(mload(dest), mask) // retrieve the bytes
        mstore(dest, or(destpart, srcpart))
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {RLPReader} from './RLPReader.sol';
import {MerklePatriciaProofVerifier} from './MerklePatriciaProofVerifier.sol';

/**
 * @title A helper library for verification of Merkle Patricia account and state proofs.
 */
library StateProofVerifier {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for bytes;

  uint256 constant HEADER_STATE_ROOT_INDEX = 3;
  uint256 constant HEADER_NUMBER_INDEX = 8;
  uint256 constant HEADER_TIMESTAMP_INDEX = 11;

  struct BlockHeader {
    bytes32 hash;
    bytes32 stateRootHash;
    uint256 number;
    uint256 timestamp;
  }

  struct Account {
    bool exists;
    uint256 nonce;
    uint256 balance;
    bytes32 storageRoot;
    bytes32 codeHash;
  }

  struct SlotValue {
    bool exists;
    uint256 value;
  }

  /**
   * @notice Parses block header and verifies its presence onchain within the latest 256 blocks.
   * @param _headerRlpBytes RLP-encoded block header.
   */
  function verifyBlockHeader(bytes memory _headerRlpBytes, bytes32 _blockHash)
    internal
    pure
    returns (BlockHeader memory)
  {
    BlockHeader memory header = parseBlockHeader(_headerRlpBytes);
    require(header.hash == _blockHash, 'blockhash mismatch');
    // ensure that the block is actually in the blockchain
    // require(header.hash == blockhash(header.number), "blockhash mismatch"); // TODO: remember that I commented this
    return header;
  }

  /**
   * @notice Parses RLP-encoded block header.
   * @param _headerRlpBytes RLP-encoded block header.
   */
  function parseBlockHeader(bytes memory _headerRlpBytes)
    internal
    pure
    returns (BlockHeader memory)
  {
    BlockHeader memory result;
    RLPReader.RLPItem[] memory headerFields = _headerRlpBytes
      .toRlpItem()
      .toList();

    require(headerFields.length > HEADER_TIMESTAMP_INDEX);

    result.stateRootHash = bytes32(
      headerFields[HEADER_STATE_ROOT_INDEX].toUint()
    );
    result.number = headerFields[HEADER_NUMBER_INDEX].toUint();
    result.timestamp = headerFields[HEADER_TIMESTAMP_INDEX].toUint();
    result.hash = keccak256(_headerRlpBytes);

    return result;
  }

  /**
   * @notice Verifies Merkle Patricia proof of an account and extracts the account fields.
   *
   * @param _addressHash Keccak256 hash of the address corresponding to the account.
   * @param _stateRootHash MPT root hash of the Ethereum state trie.
   */
  function extractAccountFromProof(
    bytes32 _addressHash, // keccak256(abi.encodePacked(address))
    bytes32 _stateRootHash,
    RLPReader.RLPItem[] memory _proof
  ) internal pure returns (Account memory) {
    bytes memory acctRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
      _stateRootHash,
      abi.encodePacked(_addressHash),
      _proof
    );
    Account memory account;

    if (acctRlpBytes.length == 0) {
      return account;
    }

    RLPReader.RLPItem[] memory acctFields = acctRlpBytes.toRlpItem().toList();
    require(acctFields.length == 4);

    account.exists = true;
    account.nonce = acctFields[0].toUint();
    account.balance = acctFields[1].toUint();
    account.storageRoot = bytes32(acctFields[2].toUint());
    account.codeHash = bytes32(acctFields[3].toUint());

    return account;
  }

  /**
   * @notice Verifies Merkle Patricia proof of a slot and extracts the slot's value.
   *
   * @param _slotHash Keccak256 hash of the slot position.
   * @param _storageRootHash MPT root hash of the account's storage trie.
   */
  function extractSlotValueFromProof(
    bytes32 _slotHash,
    bytes32 _storageRootHash,
    RLPReader.RLPItem[] memory _proof
  ) internal pure returns (SlotValue memory) {
    bytes memory valueRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
      _storageRootHash,
      abi.encodePacked(_slotHash),
      _proof
    );

    SlotValue memory value;

    if (valueRlpBytes.length != 0) {
      value.exists = true;
      value.value = valueRlpBytes.toRlpItem().toUint();
    }

    return value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseVotingStrategy {
  /**
   * @dev object storing the information of the asset used for the voting strategy
   * @param baseStorageSlot initial slot for the balance of the specified token.
            From that slot, by adding the address of the user, the correct balance can be taken.
   * @param weight determines the importance of the token on the vote.
   */
  struct VotingAssetConfig {
    uint128 baseStorageSlot;
    uint128 weight;
  }

  /**
   * @dev emitted when an asset is added for the voting strategy
   * @param asset address of the token to be added
   * @param storageSlot storage position of the start of the balance mapping
   * @param weight percentage of importance that the asset will have in the vote
   */
  event VotingAssetAdd(
    address indexed asset,
    uint128 storageSlot,
    uint128 weight
  );

  /**
   * @dev method to get the precision of the weights used.
   * @return the weight precision
   */
  function WEIGHT_PRECISION() external view returns (uint128);

  /**
   * @dev method to get the addresses of the assets that can be used for voting
   * @return list of addresses of assets
   */
  function getVotingAssetList() external view returns (address[] memory);

  /**
   * @dev method to get the configuration for voting of an asset
   * @param asset address of the asset to get the configuration from
   * @return object with the asset configuration containing the base storage slot, and the weight
   */
  function getVotingAssetConfig(address asset)
    external
    view
    returns (VotingAssetConfig memory);

  /**
   * @dev method to get the power of an asset, after applying the configured weight for said asset
   * @param asset address of the token to get the weighted power
   * @param baseStorageSlot storage position of the start of the balance mapping
   * @param power balance of a determined asset to be weighted for the vote
   */
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power
  ) external view returns (uint256);
}