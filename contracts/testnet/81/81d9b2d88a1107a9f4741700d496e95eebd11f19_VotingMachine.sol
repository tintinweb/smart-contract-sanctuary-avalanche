// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICrossChainController} from 'aave-crosschain-infra/contracts/interfaces/ICrossChainController.sol';
import {IVotingMachine, IBaseReceiverPortal, IVotingPortal} from './interfaces/IVotingMachine.sol';
import {VotingMachineWithProofs, IDataWarehouse, IVotingStrategy, IVotingMachineWithProofs} from './VotingMachineWithProofs.sol';
import {Errors} from '../libraries/Errors.sol';
import {BaseGasLimit, IBaseGasLimit} from '../BaseGasLimit.sol';

/**
 * @title VotingMachine
 * @author BGD Labs
 * @notice this contract contains the logic to communicate with governance chain.
 * @dev This contract implements the abstract contract VotingMachineWithProofs
 * @dev This contract can receive messages of types Proposal and Vote from governance chain, and send voting results
        back.
 */
contract VotingMachine is
  BaseGasLimit,
  VotingMachineWithProofs,
  IVotingMachine
{
  /// @inheritdoc IVotingMachine
  address public immutable CROSS_CHAIN_CONTROLLER;

  /// @inheritdoc IVotingMachine
  uint256 public immutable L1_VOTING_PORTAL_CHAIN_ID;

  // address of the L1 VotingPortal contract
  address internal _l1VotingPortal;

  /**
   * @param crossChainController address of the CrossChainController contract deployed on current chain. This contract
            is the one responsible to send here the voting configurations once they are bridged.
   * @param gasLimit max number of gas to spend on receiving chain (L1) when sending back the voting results
   * @param l1VotingPortalChainId id of the L1 chain where the voting portal is deployed
   * @param votingStrategy address of the new VotingStrategy contract
   **/
  constructor(
    address crossChainController,
    uint256 gasLimit,
    uint256 l1VotingPortalChainId,
    IVotingStrategy votingStrategy
  ) VotingMachineWithProofs(votingStrategy) BaseGasLimit(gasLimit) {
    require(
      crossChainController != address(0),
      Errors.INVALID_VOTING_MACHINE_CROSS_CHAIN_CONTROLLER
    );
    require(l1VotingPortalChainId > 0, Errors.INVALID_VOTING_PORTAL_CHAIN_ID);
    CROSS_CHAIN_CONTROLLER = crossChainController;
    L1_VOTING_PORTAL_CHAIN_ID = l1VotingPortalChainId;
  }

  /// @inheritdoc IVotingMachine
  function updateL1VotingPortal(address l1VotingPortal) external onlyOwner {
    _updateL1VotingPortal(l1VotingPortal);
  }

  /// @inheritdoc IVotingMachine
  function getL1VotingPortal() external view returns (address) {
    return _l1VotingPortal;
  }

  /// @inheritdoc IBaseReceiverPortal
  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory messageWithType
  ) external {
    require(
      msg.sender == CROSS_CHAIN_CONTROLLER &&
        originSender == _l1VotingPortal &&
        originChainId == L1_VOTING_PORTAL_CHAIN_ID,
      Errors.WRONG_MESSAGE_ORIGIN
    );

    try this.decodeMessage(messageWithType) returns (
      IVotingPortal.MessageType messageType,
      bytes memory message
    ) {
      bytes memory empty;
      if (messageType == IVotingPortal.MessageType.Proposal) {
        try this.decodeProposalMessage(message) returns (
          uint256 proposalId,
          bytes32 blockHash,
          uint24 votingDuration
        ) {
          _createBridgedProposalVote(proposalId, blockHash, votingDuration);
          emit MessageReceived(
            originSender,
            originChainId,
            true,
            messageType,
            message,
            empty
          );
        } catch (bytes memory decodingError) {
          emit MessageReceived(
            originSender,
            originChainId,
            false,
            messageType,
            message,
            decodingError
          );
        }
      } else if (messageType == IVotingPortal.MessageType.Vote) {
        try this.decodeVoteMessage(message) returns (
          uint256 proposalId,
          address voter,
          bool support,
          VotingAssetWithSlot[] memory votingAssetsWithSlot
        ) {
          _registerBridgedVote(
            proposalId,
            voter,
            support,
            votingAssetsWithSlot
          );
          emit MessageReceived(
            originSender,
            originChainId,
            true,
            messageType,
            message,
            empty
          );
        } catch (bytes memory decodingError) {
          emit MessageReceived(
            originSender,
            originChainId,
            false,
            messageType,
            message,
            decodingError
          );
        }
      }
    } catch (bytes memory decodingError) {
      emit IncorrectTypeMessageReceived(
        originSender,
        originChainId,
        messageWithType,
        decodingError
      );
    }
  }

  /// @inheritdoc IVotingMachine
  function decodeVoteMessage(
    bytes memory message
  )
    external
    pure
    returns (uint256, address, bool, VotingAssetWithSlot[] memory)
  {
    return abi.decode(message, (uint256, address, bool, VotingAssetWithSlot[]));
  }

  /// @inheritdoc IVotingMachine
  function decodeProposalMessage(
    bytes memory message
  ) external pure returns (uint256, bytes32, uint24) {
    return abi.decode(message, (uint256, bytes32, uint24));
  }

  /// @inheritdoc IVotingMachine
  function decodeMessage(
    bytes memory message
  ) external pure returns (IVotingPortal.MessageType, bytes memory) {
    return abi.decode(message, (IVotingPortal.MessageType, bytes));
  }

  /// @inheritdoc IBaseGasLimit
  function updateGasLimit(uint256 gasLimit) external override onlyOwner {
    _updateGasLimit(gasLimit);
  }

  /**
   * @notice method to update the L1 VotingPortal contract address
   * @param l1VotingPortal address of the new L1 VotingPortal contract
   **/
  function _updateL1VotingPortal(address l1VotingPortal) internal {
    require(l1VotingPortal != address(0), Errors.INVALID_L1_VOTING_PORTAL);
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
    ICrossChainController(CROSS_CHAIN_CONTROLLER).forwardMessage(
      L1_VOTING_PORTAL_CHAIN_ID,
      _l1VotingPortal,
      getGasLimit(),
      abi.encode(proposalId, forVotes, againstVotes)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IBaseCrossChainController.sol';

/**
 * @title ICrossChainController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the ICrossChainControllerMainnet contract
 */
interface ICrossChainController is IBaseCrossChainController {
  /**
   * @notice method called to initialize the proxy
   * @param owner address of the owner of the cross chain controller
   * @param guardian address of the guardian of the cross chain controller
   * @param initialRequiredConfirmations number of confirmations the messages need to be accepted as valid
   * @param receiverBridgeAdaptersToAllow array of addresses of the bridge adapters that can receive messages
   * @param forwarderBridgeAdaptersToEnable array specifying for every bridgeAdapter, the destinations it can have
   * @param sendersToApprove array of addresses to allow as forwarders
   */
  function initialize(
    address owner,
    address guardian,
    ConfirmationInput[] memory initialRequiredConfirmations,
    ReceiverBridgeAdapterConfigInput[] memory receiverBridgeAdaptersToAllow,
    ForwarderBridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    address[] memory sendersToApprove
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from 'aave-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';
import {IVotingPortal} from '../../../interfaces/IVotingPortal.sol';
import {IVotingMachineWithProofs} from './IVotingMachineWithProofs.sol';

/**
 * @title IVotingMachine
 * @author BGD Labs
 * @notice interface containing the methods definitions of the VotingMachine contract
 */
interface IVotingMachine is IBaseReceiverPortal {
  /**
   * @notice emitted when a cross chain message gets received
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param delivered flag indicating if message has been delivered
   * @param messageType type of the received message
   * @param message bytes containing the necessary information of a user vote
   * @param reason bytes with the revert information
   */
  event MessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    IVotingPortal.MessageType messageType,
    bytes message,
    bytes reason
  );

  /**
   * @notice emitted when a cross chain message does not have the correct type for voting machine
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param message bytes containing the necessary information of a proposal vote
   * @param reason bytes with the revert information
   */
  event IncorrectTypeMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bytes message,
    bytes reason
  );

  /**
   * @notice emitted when the L1 VotingPortal contract address gets updated
   * @param l1VotingPortal new address of the L1 VotingPortal contract address
   */
  event L1VotingPortalUpdated(address indexed l1VotingPortal);

  /**
   * @notice method to get the chain id of the origin / receiving chain (L1)
   * @return the chainId
   */
  function L1_VOTING_PORTAL_CHAIN_ID() external view returns (uint256);

  /**
   * @notice method to get the address of the CrossChainController contract deployed on current chain
   * @return the CrossChainController contract address
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice method to update the L1 VotingPortal contract address
   * @param l1VotingPortal address of the new L1 VotingPortal contract
   */
  function updateL1VotingPortal(address l1VotingPortal) external;

  /**
   * @notice method to get the address of the L1 VotingPortal contract
   * @return the address of the L1 VotingPortal contract
   */
  function getL1VotingPortal() external view returns (address);

  /**
   * @notice method to decode a message from from governance chain
   * @param message encoded message with message type
   * @return messageType and governance underlying message
   */
  function decodeMessage(
    bytes memory message
  ) external view returns (IVotingPortal.MessageType, bytes memory);

  /**
   * @notice method to decode a vote message
   * @param message encoded vote message
   * @return information to vote on a proposal, including proposalId, voter, support, votingTokens
   */
  function decodeVoteMessage(
    bytes memory message
  )
    external
    view
    returns (
      uint256,
      address,
      bool,
      IVotingMachineWithProofs.VotingAssetWithSlot[] memory
    );

  /**
   * @notice method to decode a proposal message from from governance chain
   * @param message encoded proposal message
   * @return information to start a proposal vote, including proposalId, blockHash and votingDuration
   */
  function decodeProposalMessage(
    bytes memory message
  ) external view returns (uint256, bytes32, uint24);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {SafeCast} from 'solidity-utils/contracts/oz-common/SafeCast.sol';
import {StateProofVerifier} from './libs/StateProofVerifier.sol';
import {IVotingMachineWithProofs, IDataWarehouse, IVotingStrategy} from './interfaces/IVotingMachineWithProofs.sol';
import {IBaseVotingStrategy} from '../../interfaces/IBaseVotingStrategy.sol';
import {Errors} from '../libraries/Errors.sol';
import {SlotUtils} from '../libraries/SlotUtils.sol';
import {EIP712} from 'openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol';
import {ECDSA} from 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';

/**
 * @title VotingMachineWithProofs
 * @author BGD Labs
 * @notice this contract contains the logic to vote on a bridged proposal. It uses registered proofs to calculate the
           voting power of the users. Once the voting is finished it will send the results back to the governance chain.
 * @dev Abstract contract that is implemented on VotingMachine contract
 */
abstract contract VotingMachineWithProofs is
  IVotingMachineWithProofs,
  EIP712,
  Ownable
{
  using SafeCast for uint256;

  /// @inheritdoc IVotingMachineWithProofs
  bytes32 public constant VOTE_SUBMITTED_TYPEHASH =
    keccak256(
      'SubmitVote(uint256 proposalId,address voter,bool support,VotingAssetWithSlot[] votingAssetsWithSlot)'
    );

  /// @inheritdoc IVotingMachineWithProofs
  string public constant NAME = 'Aave Voting Machine';

  /// @inheritdoc IVotingMachineWithProofs
  IVotingStrategy public immutable VOTING_STRATEGY;

  /// @inheritdoc IVotingMachineWithProofs
  IDataWarehouse public immutable DATA_WAREHOUSE;

  // (proposalId => proposal information) stores the information of the proposals
  mapping(uint256 => Proposal) internal _proposals;

  // (proposalId => proposal vote configuration) stores the configuration for voting on each proposal
  mapping(uint256 => ProposalVoteConfiguration)
    internal _proposalsVoteConfiguration;

  // saves the ids of the proposals that have been bridged for a vote.
  uint256[] internal _proposalsVoteConfigurationIds;

  // (voter => proposalId => voteInfo) stores the information for the bridged votes
  mapping(address => mapping(uint256 => BridgedVote)) internal _bridgedVotes;

  /**
   * @param votingStrategy address of the new VotingStrategy contract
   */
  constructor(IVotingStrategy votingStrategy) Ownable() EIP712(NAME, 'V1') {
    require(
      address(votingStrategy) != address(0),
      Errors.INVALID_VOTING_STRATEGY
    );
    VOTING_STRATEGY = votingStrategy;
    DATA_WAREHOUSE = votingStrategy.DATA_WAREHOUSE();
  }

  /// @inheritdoc IVotingMachineWithProofs
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return _domainSeparatorV4();
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getBridgedVoteInfo(
    uint256 proposalId,
    address voter
  ) external view returns (BridgedVote memory) {
    return _bridgedVotes[voter][proposalId];
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalVoteConfiguration(
    uint256 proposalId
  ) external view returns (ProposalVoteConfiguration memory) {
    return _proposalsVoteConfiguration[proposalId];
  }

  /// @inheritdoc IVotingMachineWithProofs
  function startProposalVote(uint256 proposalId) external returns (uint256) {
    ProposalVoteConfiguration memory voteConfig = _proposalsVoteConfiguration[
      proposalId
    ];
    require(
      voteConfig.l1ProposalBlockHash != bytes32(0),
      Errors.MISSING_PROPOSAL_BLOCK_HASH
    );
    Proposal storage newProposal = _proposals[proposalId];

    require(
      _getProposalState(newProposal) == ProposalState.NotCreated,
      Errors.PROPOSAL_VOTE_ALREADY_CREATED
    );

    VOTING_STRATEGY.hasRequiredRoots(voteConfig.l1ProposalBlockHash);

    uint40 startTime = _getCurrentTimeRef();
    uint40 endTime = startTime + voteConfig.votingDuration;

    newProposal.id = proposalId;
    newProposal.l1BlockHash = voteConfig.l1ProposalBlockHash;
    newProposal.creationBlockNumber = block.number;
    newProposal.startTime = startTime;
    newProposal.endTime = endTime;

    emit ProposalVoteStarted(
      proposalId,
      voteConfig.l1ProposalBlockHash,
      startTime,
      endTime
    );

    return proposalId;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function submitVoteBySignature(
    uint256 proposalId,
    address voter,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    VotingAssetWithSlot[]
      memory underlyingAssetsWithSlot = new VotingAssetWithSlot[](
        votingBalanceProofs.length
      );
    for (uint256 i = 0; i < votingBalanceProofs.length; i++) {
      underlyingAssetsWithSlot[i] = VotingAssetWithSlot({
        underlyingAsset: votingBalanceProofs[i].underlyingAsset,
        slot: votingBalanceProofs[i].slot
      });
    }

    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          VOTE_SUBMITTED_TYPEHASH,
          proposalId,
          voter,
          support,
          underlyingAssetsWithSlot
        )
      )
    );
    address signer = ECDSA.recover(digest, v, r, s);

    require(signer == voter && signer != address(0), Errors.INVALID_SIGNATURE);
    _submitVote(signer, proposalId, support, votingBalanceProofs);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function settleVoteFromPortal(
    uint256 proposalId,
    address voter,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external {
    BridgedVote memory bridgedVote = _bridgedVotes[voter][proposalId];

    require(
      bridgedVote.votingAssetsWithSlot.length == votingBalanceProofs.length,
      Errors.INVALID_NUMBER_OF_PROOFS_FOR_VOTING_TOKENS
    );

    // check that the proofs are of the voter assets
    for (uint256 i = 0; i < bridgedVote.votingAssetsWithSlot.length; i++) {
      bool assetFound;
      for (uint256 j = 0; j < votingBalanceProofs.length; j++) {
        if (
          votingBalanceProofs[j].underlyingAsset ==
          bridgedVote.votingAssetsWithSlot[i].underlyingAsset &&
          votingBalanceProofs[j].slot ==
          bridgedVote.votingAssetsWithSlot[i].slot
        ) {
          assetFound = true;
          break;
        }
      }

      require(assetFound, Errors.PROOFS_NOT_FOR_VOTING_TOKENS);
    }

    _submitVote(voter, proposalId, bridgedVote.support, votingBalanceProofs);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function submitVote(
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external {
    _submitVote(msg.sender, proposalId, support, votingBalanceProofs);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getUserProposalVote(
    address user,
    uint256 proposalId
  ) external view returns (Vote memory) {
    return _proposals[proposalId].votes[user];
  }

  /// @inheritdoc IVotingMachineWithProofs
  function closeAndSendVote(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == ProposalState.Finished,
      Errors.PROPOSAL_VOTE_NOT_FINISHED
    );

    proposal.votingClosedAndSentBlockNumber = block.number;
    proposal.votingClosedAndSentTimestamp = _getCurrentTimeRef();

    uint256 forVotes = proposal.forVotes;
    uint256 againstVotes = proposal.againstVotes;

    proposal.sentToGovernance = true;

    _sendVoteResults(proposalId, forVotes, againstVotes);

    emit ProposalResultsSent(proposalId, forVotes, againstVotes);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalById(
    uint256 proposalId
  ) external view returns (ProposalWithoutVotes memory) {
    Proposal storage proposal = _proposals[proposalId];
    ProposalWithoutVotes memory proposalWithoutVotes = ProposalWithoutVotes({
      id: proposal.id,
      l1BlockHash: proposal.l1BlockHash,
      startTime: proposal.startTime,
      endTime: proposal.endTime,
      creationBlockNumber: proposal.creationBlockNumber,
      forVotes: proposal.forVotes,
      againstVotes: proposal.againstVotes,
      votingClosedAndSentBlockNumber: proposal.votingClosedAndSentBlockNumber,
      votingClosedAndSentTimestamp: proposal.votingClosedAndSentTimestamp,
      sentToGovernance: proposal.sentToGovernance
    });

    return proposalWithoutVotes;
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalState(
    uint256 proposalId
  ) external view returns (ProposalState) {
    return _getProposalState(_proposals[proposalId]);
  }

  /// @inheritdoc IVotingMachineWithProofs
  function getProposalsVoteConfigurationIds(
    uint256 skip,
    uint256 size
  ) external view returns (uint256[] memory) {
    uint256 proposalListLength = _proposalsVoteConfigurationIds.length;
    if (proposalListLength == 0 || proposalListLength <= skip) {
      return new uint256[](0);
    } else if (proposalListLength < size + skip) {
      size = proposalListLength - skip;
    }

    uint256[] memory ids = new uint256[](size);
    for (uint256 i = 0; i < size; i++) {
      ids[i] = _proposalsVoteConfigurationIds[
        proposalListLength - skip - i - 1
      ];
    }
    return ids;
  }

  /**
    * @notice method to cast a vote on a proposal specified by its id
    * @param voter address with the voting power
    * @param proposalId id of the proposal on which the vote will be cast
    * @param support boolean indicating if the vote is in favor or against the proposal
    * @param votingBalanceProofs list of objects containing the information necessary to vote using the tokens
             allowed on the voting strategy.
    * @dev A vote does not need to use all the tokens allowed, can be a subset
    */
  function _submitVote(
    address voter,
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) internal {
    Proposal storage proposal = _proposals[proposalId];
    require(
      _getProposalState(proposal) == ProposalState.Active,
      Errors.PROPOSAL_VOTE_NOT_IN_ACTIVE_STATE
    );

    Vote storage vote = proposal.votes[voter];
    require(vote.votingPower == 0, Errors.PROPOSAL_VOTE_ALREADY_EXISTS);

    uint256 votingPower;
    StateProofVerifier.SlotValue memory balanceVotingPower;
    for (uint256 i = 0; i < votingBalanceProofs.length; i++) {
      for (uint256 j = i + 1; j < votingBalanceProofs.length; j++) {
        require(
          votingBalanceProofs[i].slot != votingBalanceProofs[j].slot ||
            votingBalanceProofs[i].underlyingAsset !=
            votingBalanceProofs[j].underlyingAsset,
          Errors.VOTE_ONCE_FOR_ASSET
        );
      }

      balanceVotingPower = DATA_WAREHOUSE.getStorage(
        votingBalanceProofs[i].underlyingAsset,
        proposal.l1BlockHash,
        SlotUtils.getAccountSlotHash(voter, votingBalanceProofs[i].slot),
        votingBalanceProofs[i].proof
      );

      require(balanceVotingPower.exists, Errors.USER_BALANCE_DOES_NOT_EXISTS);

      if (balanceVotingPower.value != 0) {
        votingPower += IVotingStrategy(address(VOTING_STRATEGY)).getVotingPower(
          votingBalanceProofs[i].underlyingAsset,
          votingBalanceProofs[i].slot,
          balanceVotingPower.value,
          proposal.l1BlockHash
        );
      }
    }
    require(votingPower != 0, Errors.USER_VOTING_BALANCE_IS_ZERO);

    if (support) {
      proposal.forVotes += votingPower.toUint128();
    } else {
      proposal.againstVotes += votingPower.toUint128();
    }

    vote.support = support;
    vote.votingPower = votingPower.toUint248();

    emit VoteEmitted(proposalId, voter, support, votingPower);
  }

  /**
   * @notice method to send the voting results on a proposal back to L1
   * @param proposalId id of the proposal to send the voting result to L1
   * @dev This method should be implemented to trigger the bridging flow
   */
  function _sendVoteResults(
    uint256 proposalId,
    uint256 forVotes,
    uint256 againstVotes
  ) internal virtual;

  /**
   * @notice method to get the state of a proposal specified by its id
   * @param proposal the proposal to retrieve the state of
   * @return the state of the proposal
   */
  function _getProposalState(
    Proposal storage proposal
  ) internal view returns (ProposalState) {
    if (proposal.endTime == 0) {
      return ProposalState.NotCreated;
    } else if (_getCurrentTimeRef() <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.sentToGovernance) {
      return ProposalState.SentToGovernance;
    } else {
      return ProposalState.Finished;
    }
  }

  /**
   * @notice method to get the timestamp of a block casted to uint40
   * @return uint40 block timestamp
   */
  function _getCurrentTimeRef() internal view returns (uint40) {
    return uint40(block.timestamp);
  }

  /**
   * @notice method that registers a proposal configuration and creates the voting if it can. If not it will register the
             the configuration for later creation.
   * @param proposalId id of the proposal bridged to start the vote on
   * @param blockHash hash of the block on L1 when the proposal was activated for voting
   * @param votingDuration duration in seconds of the vote
   */
  function _createBridgedProposalVote(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) internal {
    require(
      blockHash != bytes32(0),
      Errors.INVALID_VOTE_CONFIGURATION_BLOCKHASH
    );
    require(
      votingDuration > 0,
      Errors.INVALID_VOTE_CONFIGURATION_VOTING_DURATION
    );
    require(
      _proposalsVoteConfiguration[proposalId].l1ProposalBlockHash == bytes32(0),
      Errors.PROPOSAL_VOTE_CONFIGURATION_ALREADY_BRIDGED
    );

    _proposalsVoteConfiguration[proposalId] = IVotingMachineWithProofs
      .ProposalVoteConfiguration({
        votingDuration: votingDuration,
        l1ProposalBlockHash: blockHash
      });
    _proposalsVoteConfigurationIds.push(proposalId);

    bool created;
    try this.startProposalVote(proposalId) {
      created = true;
    } catch (bytes memory) {}

    emit ProposalVoteConfigurationBridged(
      proposalId,
      blockHash,
      votingDuration,
      created
    );
  }

  /**
   * @notice method that registers a vote on a proposal from a specific voter, contained in a bridged message
             from governance chain
   * @param proposalId id of the proposal bridged to start the vote on
   * @param voter address that wants to emit the vote
   * @param support indicates if vote is in favor or against the proposal
   * @param votingAssetsWithSlot list of token addresses with base slots that the voter will use for voting
   */
  function _registerBridgedVote(
    uint256 proposalId,
    address voter,
    bool support,
    VotingAssetWithSlot[] memory votingAssetsWithSlot
  ) internal {
    // It also only allows to register the vote when proposal is active.
    // To retry to register a vote (after it fails) the message will need to be retried from the cross chain controller
    require(
      _getProposalState(_proposals[proposalId]) == ProposalState.Active,
      Errors.PROPOSAL_VOTE_CAN_NOT_BE_REGISTERED
    );
    require(voter != address(0), Errors.INVALID_VOTER);
    require(votingAssetsWithSlot.length > 0, Errors.NO_BRIDGED_VOTING_ASSETS);
    require(
      _bridgedVotes[voter][proposalId].votingAssetsWithSlot.length == 0,
      Errors.VOTE_ALREADY_BRIDGED
    );
    _bridgedVotes[voter][proposalId].support = support;
    for (uint256 i = 0; i < votingAssetsWithSlot.length; i++) {
      require(
        IBaseVotingStrategy(address(VOTING_STRATEGY)).isTokenSlotAccepted(
          votingAssetsWithSlot[i].underlyingAsset,
          votingAssetsWithSlot[i].slot
        ),
        Errors.INVALID_BRIDGED_VOTING_TOKEN
      );
      for (uint256 j = i + 1; j < votingAssetsWithSlot.length; j++) {
        require(
          votingAssetsWithSlot[j].underlyingAsset !=
            votingAssetsWithSlot[i].underlyingAsset ||
            votingAssetsWithSlot[j].slot != votingAssetsWithSlot[i].slot,
          Errors.BRIDGED_REPEATED_ASSETS
        );
      }

      _bridgedVotes[voter][proposalId].votingAssetsWithSlot.push(
        votingAssetsWithSlot[i]
      );
    }

    emit VoteBridged(proposalId, voter, support, votingAssetsWithSlot);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author BGD Labs
 * @notice Defines the error messages emitted by the different contracts of the Aave Governance V3
 */
library Errors {
  string public constant VOTING_PORTALS_COUNT_NOT_0 = '1'; // to be able to rescue voting portals count must be 0
  string public constant AT_LEAST_ONE_PAYLOAD = '2'; // to create a proposal, it must have at least one payload
  string public constant VOTING_PORTAL_NOT_APPROVED = '3'; // the voting portal used to vote on proposal must be approved
  string public constant PROPOSITION_POWER_IS_TOO_LOW = '4'; // proposition power of proposal creator must be equal or higher than the specified threshold for the access level
  string public constant PROPOSAL_NOT_IN_CREATED_STATE = '5'; // proposal should be in the CREATED state
  string public constant PROPOSAL_NOT_IN_ACTIVE_STATE = '6'; // proposal must be in an ACTIVE state
  string public constant PROPOSAL_NOT_IN_QUEUED_STATE = '7'; // proposal must be in a QUEUED state
  string public constant VOTING_START_COOLDOWN_PERIOD_NOT_PASSED = '8'; // to activate a proposal vote, the cool down delay must pass
  string public constant INVALID_VOTING_TOKENS = '9'; // can not vote with more tokens than are allowed
  string public constant CALLER_NOT_A_VALID_VOTING_PORTAL = '10'; // only an allowed voting portal can queue a proposal
  string public constant QUEUE_COOLDOWN_PERIOD_NOT_PASSED = '11'; // to execute a proposal a cooldown delay must pass
  string public constant PROPOSAL_NOT_IN_THE_CORRECT_STATE = '12'; // proposal must be created but not executed yet to be able to be canceled
  string public constant CALLER_NOT_GOVERNANCE = '13'; // caller must be governance
  string public constant VOTER_ALREADY_VOTED_ON_PROPOSAL = '14'; // voter can only vote once per proposal using voting portal
  string public constant WRONG_MESSAGE_ORIGIN = '15'; // received message must come from registered source address, chain id, CrossChainController
  string public constant NO_VOTING_ASSETS = '16'; // Strategy must have voting assets
  string public constant PROPOSAL_VOTE_ALREADY_CREATED = '17'; // vote on proposal can only be created once
  string public constant INVALID_SIGNATURE = '18'; // submitted signature is not valid
  string public constant INVALID_NUMBER_OF_PROOFS_FOR_VOTING_TOKENS = '19'; // Need all the necessary proofs to validate the voting tokens
  string public constant PROOFS_NOT_FOR_VOTING_TOKENS = '20'; // provided proofs must be from the voting tokens selected (bridged from governance chain)
  string public constant PROPOSAL_VOTE_NOT_FINISHED = '21'; // proposal vote must be finished
  string public constant PROPOSAL_VOTE_NOT_IN_ACTIVE_STATE = '22'; // proposal vote must be in active state
  string public constant PROPOSAL_VOTE_ALREADY_EXISTS = '23'; // proposal vote already exists
  string public constant VOTE_ONCE_FOR_ASSET = '24'; // an asset can only be used once per vote
  string public constant USER_BALANCE_DOES_NOT_EXISTS = '25'; // to vote an user must have balance in the token the user is voting with
  string public constant USER_VOTING_BALANCE_IS_ZERO = '26'; // to vote an user must have some balance between all the tokens selected for voting
  string public constant MISSING_AAVE_ROOTS = '27'; // must have AAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_ROOTS = '28'; // must have stkAAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_SLASHING_EXCHANGE_RATE = '29'; // must have stkAAVE slashing exchange rate registered to use strategy
  string public constant UNPROCESSED_STORAGE_ROOT = '30'; // root must be registered beforehand
  string public constant NOT_ENOUGH_MSG_VALUE = '31'; // method was not called with enough value to execute the call
  string public constant FAILED_ACTION_EXECUTION = '32'; // action failed to execute
  string public constant SHOULD_BE_AT_LEAST_ONE_EXECUTOR = '33'; // at least one executor is needed
  string public constant INVALID_EMPTY_TARGETS = '34'; // target of the payload execution must not be empty
  string public constant EXECUTOR_WAS_NOT_SPECIFIED_FOR_REQUESTED_ACCESS_LEVEL =
    '35'; // payload executor must be registered for the specified payload access level
  string public constant PAYLOAD_NOT_IN_QUEUED_STATE = '36'; // payload must be en the queued state
  string public constant TIMELOCK_NOT_FINISHED = '37'; // delay has not passed before execution can be called
  string public constant PAYLOAD_NOT_IN_THE_CORRECT_STATE = '38'; // payload must be created but not executed yet to be able to be canceled
  string public constant PAYLOAD_NOT_IN_CREATED_STATE = '39'; // payload must be in the created state
  string public constant MISSING_A_AAVE_ROOTS = '40'; // must have aAAVE roots registered to use strategy
  string public constant MISSING_PROPOSAL_BLOCK_HASH = '41'; // block hash for this proposal was not bridged before
  string public constant PROPOSAL_VOTE_CONFIGURATION_ALREADY_BRIDGED = '42'; // configuration for this proposal bridged already
  string public constant INVALID_VOTING_PORTAL_ADDRESS = '43'; // voting portal address can't be 0x0
  string public constant INVALID_POWER_STRATEGY = '44'; // 0x0 is not valid as the power strategy
  string public constant INVALID_EXECUTOR_ADDRESS = '45'; // executor address can't be 0x0
  string public constant EXECUTOR_ALREADY_SET_IN_DIFFERENT_LEVEL = '46'; // executor address already being used as executor of a different level
  string public constant INVALID_VOTING_DURATION = '47'; // voting duration can not be bigger than the time it takes to execute a proposal
  string public constant VOTING_DURATION_NOT_PASSED = '48'; // at least votingDuration should have passed since voting started for a proposal to be queued
  string public constant INVALID_PROPOSAL_ACCESS_LEVEL = '49'; // the bridged proposal access level does not correspond with the maximum access level required by the payload
  string public constant PAYLOAD_NOT_CREATED_BEFORE_PROPOSAL = '50'; // payload must be created before proposal
  string public constant INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS = '51';
  string public constant INVALID_MESSAGE_ORIGINATOR_ADDRESS = '51';
  string public constant INVALID_ORIGIN_CHAIN_ID = '52';
  string public constant INVALID_ACTION_TARGET = '54';
  string public constant INVALID_ACTION_ACCESS_LEVEL = '55';
  string public constant INVALID_EXECUTOR_ACCESS_LEVEL = '56';
  string public constant INVALID_VOTING_PORTAL_CROSS_CHAIN_CONTROLLER = '57';
  string public constant INVALID_VOTING_PORTAL_VOTING_MACHINE = '58';
  string public constant INVALID_VOTING_PORTAL_GOVERNANCE = '59';
  string public constant INVALID_VOTING_MACHINE_CHAIN_ID = '60';
  string public constant G_INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS = '61';
  string public constant G_INVALID_IPFS_HASH = '62';
  string public constant G_INVALID_PAYLOAD_ACCESS_LEVEL = '63';
  string public constant G_INVALID_PAYLOADS_CONTROLLER = '64';
  string public constant G_INVALID_PAYLOAD_CHAIN = '65';
  string public constant POWER_STRATEGY_HAS_NO_TOKENS = '66'; // power strategy should at least have
  string public constant INVALID_VOTING_CONFIG_ACCESS_LEVEL = '67';
  string public constant VOTING_DURATION_TOO_SMALL = '68';
  string public constant INVALID_MINIMUM_VOTING_DURATION = '69';
  string public constant NO_BRIDGED_VOTING_ASSETS = '70';
  string public constant VOTE_ALREADY_BRIDGED = '71';
  string public constant INVALID_VOTER = '72';
  string public constant INVALID_DATA_WAREHOUSE = '73';
  string public constant INVALID_VOTING_MACHINE_CROSS_CHAIN_CONTROLLER = '75';
  string public constant INVALID_L1_VOTING_PORTAL = '76';
  string public constant INVALID_VOTING_PORTAL_CHAIN_ID = '77';
  string public constant INVALID_VOTING_STRATEGY = '78';
  string public constant INVALID_VOTING_ASSETS_WITH_SLOT = '79'; // Token slot is not defined on the strategy
  string public constant PROPOSAL_VOTE_CAN_NOT_BE_REGISTERED = '80'; // to register a bridged vote proposal vote must be in NotCreated or Active state
  string public constant INVALID_VOTE_CONFIGURATION_BLOCKHASH = '81';
  string public constant INVALID_VOTE_CONFIGURATION_VOTING_DURATION = '82';
  string public constant INVALID_GAS_LIMIT = '83';
  string public constant INVALID_VOTING_CONFIGS = '84'; // a lvl2 voting configuration must be sent to initializer
  string public constant INVALID_EXECUTOR_DELAY = '85';
  string public constant INVALID_BRIDGED_VOTING_TOKEN = '86'; // A bridged voting token must be on the strategy list
  string public constant BRIDGED_REPEATED_ASSETS = '87'; // bridged voting tokens must be unique
  string public constant CAN_NOT_VOTE_WITH_REPEATED_ASSETS = '88'; // voting tokens to bridge must be unique
  string public constant REPEATED_STRATEGY_ASSET = '89';
  string public constant EMPTY_ASSET_STORAGE_SLOTS = '90';
  string public constant REPEATED_STRATEGY_ASSET_SLOT = '91';
  string public constant INVALID_EXECUTION_TARGET = '92';
  string public constant MISSING_VOTING_CONFIGURATIONS = '93'; // voting configurations for lvl1 and lvl2 must be included on initialization
  string public constant INVALID_PROPOSITION_POWER = '94';
  string public constant INVALID_QUORUM = '95';
  string public constant INVALID_DIFFERENTIAL = '96';
  string public constant ETH_TRANSFER_FAILED = '97';
  string public constant INVALID_INITIAL_VOTING_CONFIGS = '98'; // initial voting configurations can not be of the same level
  string public constant INVALID_ACHIEVABLE_VOTING_PARTICIPATION = '99'; // achievable voting participation can't be 0
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseGasLimit} from '../interfaces/IBaseGasLimit.sol';
import {Errors} from './libraries/Errors.sol';

abstract contract BaseGasLimit is IBaseGasLimit {
  /// @inheritdoc IBaseGasLimit
  uint256 public constant MAX_GAS_LIMIT = 4_000_000;

  /// @inheritdoc IBaseGasLimit
  uint256 public constant MIN_GAS_LIMIT = 400_000;

  // gas limit used for sending the vote result
  uint256 private _gasLimit;

  constructor(uint256 gasLimit) {
    _updateGasLimit(gasLimit);
  }

  /// @inheritdoc IBaseGasLimit
  function getGasLimit() public view returns (uint256) {
    return _gasLimit;
  }

  /// @inheritdoc IBaseGasLimit
  function updateGasLimit(uint256 gasLimit) external virtual;

  /**
   * @notice method to update the gasLimit
   * @param gasLimit the new gas limit
   */
  function _updateGasLimit(uint256 gasLimit) internal {
    require(
      gasLimit <= MAX_GAS_LIMIT && gasLimit >= MIN_GAS_LIMIT,
      Errors.INVALID_GAS_LIMIT
    );
    _gasLimit = gasLimit;

    emit GasLimitUpdated(gasLimit);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';
import {IRescuable} from 'solidity-utils/contracts/utils/interfaces/IRescuable.sol';

/**
 * @title IBaseCrossChainController
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainController contract
 */
interface IBaseCrossChainController is IRescuable, ICrossChainForwarder, ICrossChainReceiver {

}

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

import {IBaseReceiverPortal} from 'aave-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';
import {IVotingMachineWithProofs} from '../contracts/voting/interfaces/IVotingMachineWithProofs.sol';

/**
 * @title IVotingPortal
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the VotingPortal contract
 */
interface IVotingPortal is IBaseReceiverPortal {
  /**
   * @notice enum containing the different type of messages that can be bridged
   * @paran Null empty state
   * @param Proposal indicates that the message is to bridge a proposal configuration
   * @param Vote indicates that the message is to bridge a vote
   */
  enum MessageType {
    Null,
    Proposal,
    Vote
  }

  /**
   * @notice emitted when a vote message is received
   * @param originSender address that sent the message on the origin chain
   * @param originChainId id of the chain where the message originated
   * @param delivered flag indicating if message has been delivered
   * @param message bytes containing the necessary information to queue the bridged proposal id
   * @param reason bytes with the revert information
   */
  event VoteMessageReceived(
    address indexed originSender,
    uint256 indexed originChainId,
    bool indexed delivered,
    bytes message,
    bytes reason
  );

  /**
   * @notice get the chain id where the voting machine which is deployed
   * @return network id
   */
  function VOTING_MACHINE_CHAIN_ID() external view returns (uint256);

  /**
   * @notice gets the address of the voting machine on the destination network
   * @return voting machine address
   */
  function VOTING_MACHINE() external view returns (address);

  /**
   * @notice gets the address of the connected governance
   * @return governance address
   */
  function GOVERNANCE() external view returns (address);

  /**
   * @notice gets the address of the CrossChainController deployed on current network
   * @return CrossChainController address
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice method to bridge the vote configuration to voting chain, so a vote can be started.
   * @param proposalId id of the proposal bridged to start the vote on
   * @param blockHash hash of the block on L1 when the proposal was activated for voting
   * @param votingDuration duration in seconds of the vote
   */
  function forwardStartVotingMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external;

  /**
   * @notice method to bridge a vote to the voting chain
   * @param proposalId id of the proposal bridged to start the vote on
   * @param voter address that wants to emit the vote
   * @param support indicates if vote is in favor or against the proposal
   * @param votingAssetsWithSlot list of token addresses with the base storage slot that the voter will use for voting
   * @dev a voter can only vote once on a proposal. This is so funds don't get depleted when sending vote to the
          voting machine, as messages are paid by the system
   */
  function forwardVoteMessage(
    uint256 proposalId,
    address voter,
    bool support,
    IVotingMachineWithProofs.VotingAssetWithSlot[] memory votingAssetsWithSlot
  ) external;

  /**
   * @notice method to get if a voter voted on a proposal
   * @param proposalId id of the proposal to get if the voter voted on it
   * @param voter address to check if voted on proposal
   * @return flag indicating if a voter voted on proposal
   */
  function didVoterVoteOnProposal(
    uint256 proposalId,
    address voter
  ) external view returns (bool);

  /**
   * @notice method to decode a message from from voting machine chain
   * @param message encoded message with message type
   * @return proposalId, forVotes, againstVotes from the decoded message
   */
  function decodeMessage(
    bytes memory message
  ) external pure returns (uint256, uint128, uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDataWarehouse} from './IDataWarehouse.sol';
import {IVotingStrategy} from './IVotingStrategy.sol';

/**
 * @title IVotingMachine
 * @author BGD Labs
 * @notice interface containing the objects, events and method definitions of the VotingMachine contract
 */
interface IVotingMachineWithProofs {
  /**
   * @notice Object to use over submitVoteBySignature and in case of bridging for protect against wrong roots inclusion
   * @param underlyingAsset address of the token on L1, used for voting
   * @param slot base storage position where the balance on underlyingAsset contract resides on L1. (Normally position 0)
   */
  struct VotingAssetWithSlot {
    address underlyingAsset;
    uint128 slot;
  }

  /**
   * @notice object containing the information of a bridged vote
   * @param support indicates if vote is in favor or against the proposal
   * @param votingAssetsWithSlots list of token addresses with storage slots, that the voter will use for voting
   */
  struct BridgedVote {
    bool support;
    VotingAssetWithSlot[] votingAssetsWithSlot;
  }

  /// @notice enum delimiting the possible states a proposal can have on the voting machine
  enum ProposalState {
    NotCreated,
    Active,
    Finished,
    SentToGovernance
  }

  /**
   * @notice Object with vote information
   * @param support boolean indicating if the vote is in favor or against a proposal
   * @param votingPower the power used for voting
   */
  struct Vote {
    bool support;
    uint248 votingPower;
  }

  /**
   * @notice Object containing a proposal information
   * @param id numeric identification of the proposal
   * @param sentToGovernance boolean indication if the proposal results have been sent back to L1 governance
   * @param l1BlockHash hash of the block on L1 from the block when the proposal was activated for voting (sent to voting machine)
            this block hash is used to delimit from when the voting power is accounted for voting
   * @param startTime timestamp of the start of voting on the proposal
   * @param endTime timestamp when the voting on the proposal finishes (startTime + votingDuration)
   * @param votingClosedAndSentTimestamp timestamp indicating when the vote has been closed and sent to governance chain
   * @param forVotes votes cast in favor of the proposal
   * @param againstVotes votes cast against the proposal
   * @param creationBlockNumber blockNumber from when the proposal has been created in votingMachine
   * @param votingClosedAndSentBlockNumber block from when the vote has been closed and sent to governance chain
   * @param votes mapping indication for every voter of the proposal the information of that vote
   */
  struct Proposal {
    uint256 id;
    bool sentToGovernance;
    bytes32 l1BlockHash;
    uint40 startTime;
    uint40 endTime;
    uint40 votingClosedAndSentTimestamp;
    uint128 forVotes;
    uint128 againstVotes;
    uint256 creationBlockNumber;
    uint256 votingClosedAndSentBlockNumber;
    mapping(address => Vote) votes;
  }

  /**
   * @notice Object containing a proposal information
   * @param id numeric identification of the proposal
   * @param sentToGovernance boolean indication if the proposal results have been sent back to L1 governance
   * @param l1BlockHash hash of the block on L1 from the block when the proposal was activated for voting (sent to voting machine)
            this block hash is used to delimit from when the voting power is accounted for voting
   * @param startTime timestamp of the start of voting on the proposal
   * @param endTime timestamp when the voting on the proposal finishes (startTime + votingDuration)
   * @param votingClosedAndSentTimestamp timestamp indicating when the vote has been closed and sent to governance chain
   * @param forVotes votes cast in favor of the proposal
   * @param againstVotes votes cast against the proposal
   * @param creationBlockNumber blockNumber from when the proposal has been created in votingMachine
   * @param votingClosedAndSentBlockNumber block from when the vote has been closed and sent back to governance chain
   */
  struct ProposalWithoutVotes {
    uint256 id;
    bool sentToGovernance;
    bytes32 l1BlockHash;
    uint40 startTime;
    uint40 endTime;
    uint40 votingClosedAndSentTimestamp;
    uint128 forVotes;
    uint128 againstVotes;
    uint256 creationBlockNumber;
    uint256 votingClosedAndSentBlockNumber;
  }

  /**
   * @notice vote configuration passed from l1
   * @param votingDuration duration in seconds of the vote for a proposal
   * @param l1ProposalBlockHash block hash of the proposal on l1 from the block when proposal was activated
   */
  struct ProposalVoteConfiguration {
    uint24 votingDuration;
    bytes32 l1ProposalBlockHash;
  }

  /**
   * @notice Object with the necessary information to process a vote
   * @param underlyingAsset address of the token on L1, used for voting
   * @param slot base storage position where the balance on underlyingAsset contract resides on L1. (Normally position 0)
   * @param proof bytes of the generated proof on L1 with the slot information of underlying asset.
   */
  struct VotingBalanceProof {
    address underlyingAsset;
    uint128 slot;
    bytes proof;
  }

  /**
   * @notice emitted when a proposal is created
   * @param proposalId numeric id of the created proposal
   * @param l1BlockHash block hash from the block on l1 from when the proposal was activated for voting
   * @param startTime timestamp when the proposal was created and ready for voting
   * @param endTime timestamp of when the voting period ends. (startTime + votingDuration)
   */
  event ProposalVoteStarted(
    uint256 indexed proposalId,
    bytes32 indexed l1BlockHash,
    uint256 startTime,
    uint256 endTime
  );

  /**
   * @notice emitted when the results of a vote on a proposal are sent to L1
   * @param proposalId numeric id of the proposal which results are sent to L1
   * @param forVotes votes cast in favor of proposal
   * @param againstVotes votes cast against the proposal
   */
  event ProposalResultsSent(
    uint256 indexed proposalId,
    uint256 forVotes,
    uint256 againstVotes
  );

  /**
   * @notice emitted when a vote is registered
   * @param proposalId Id of the proposal
   * @param voter address of the voter
   * @param support boolean, true = vote for, false = vote against
   * @param votingPower Power of the voter/vote
   */
  event VoteEmitted(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    uint256 votingPower
  );

  /**
   * @notice emitted when a voting configuration of a proposal gets received. Meaning that has been bridged successfully
   * @param proposalId id of the proposal bridged to start the vote on
   * @param blockHash hash of the block on L1 when the proposal was activated for voting
   * @param votingDuration duration in seconds of the vote
   * @param voteCreated boolean indicating if the vote has been created or not.
   * @dev the vote will only be created automatically if when the configuration is bridged, all necessary roots
          have been registered already.
   */
  event ProposalVoteConfigurationBridged(
    uint256 indexed proposalId,
    bytes32 indexed blockHash,
    uint24 votingDuration,
    bool indexed voteCreated
  );

  /**
   * @notice emitted when a voting configuration of a proposal gets received. Meaning that has been bridged successfully
   * @param proposalId id of the proposal bridged to start the vote on
   * @param voter address that wants to emit the vote
   * @param support indicates if vote is in favor or against the proposal
   * @param votingAssetsWithSlot list of tokens with base slots that the voter will use for voting
   */
  event VoteBridged(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    VotingAssetWithSlot[] votingAssetsWithSlot
  );

  /**
   * @notice method to get the DataWarehouse contract
   * @return DataWarehouse contract
   */
  function DATA_WAREHOUSE() external view returns (IDataWarehouse);

  /**
   * @notice method to get the VotingStrategy contract
   * @return VotingStrategy contract
   */
  function VOTING_STRATEGY() external view returns (IVotingStrategy);

  /**
   * @notice Get the v4 compatible domain separator
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice method to get the vote submitted type hash for permits digest
   * @return hash of vote submitted string
   */
  function VOTE_SUBMITTED_TYPEHASH() external view returns (bytes32);

  /**
   * @notice method to get the contract name for permits digest
   * @return contract name string
   */
  function NAME() external view returns (string memory);

  /**
   * @notice method to get a proposal information specified by its id
   * @param proposalId id of the proposal to retrieve
   * @return the proposal information without the users vote
   */
  function getProposalById(
    uint256 proposalId
  ) external view returns (ProposalWithoutVotes memory);

  /**
   * @notice method to get the state of a proposal specified by its id
   * @param proposalId id of the proposal to retrieve the state of
   * @return the state of the proposal
   */
  function getProposalState(
    uint256 proposalId
  ) external view returns (ProposalState);

  /**
   * @notice method to get the voting configuration of a proposal specified by its id
   * @param proposalId id of the proposal to retrieve the voting configuration from
   * @return the proposal vote configuration object
   */
  function getProposalVoteConfiguration(
    uint256 proposalId
  ) external view returns (ProposalVoteConfiguration memory);

  /**
  * @notice method to get a paginated list of proposalIds. The proposals are taken from a list of proposals that have
            received vote configuration from governance chain
  * @param skip number of proposal ids to skip. from latest in the list of proposal ids with voting configuration
  * @param size length of proposal ids to ask for.
  * @return list of proposal ids
  * @dev This is mainly used to get a list of proposals that require automation in some step of the proposal live cycle.
  */
  function getProposalsVoteConfigurationIds(
    uint256 skip,
    uint256 size
  ) external view returns (uint256[] memory);

  /**
   * @notice method to get the information of a bridged vote for a proposal from a voter
   * @param proposalId id of the proposal to retrieve the vote information from
   * @param voter address of that emitted the bridging of the vote
   * @return the information of a bridged vote (support and voting assets)
   */
  function getBridgedVoteInfo(
    uint256 proposalId,
    address voter
  ) external view returns (BridgedVote memory);

  /**
   * @notice method to get the vote set by a user on a proposal specified by its id
   * @param user address of the user that voted
   * @param proposalId id of the proposal to retrieve the vote from
   * @return the vote (support and voting power) emitted
   */
  function getUserProposalVote(
    address user,
    uint256 proposalId
  ) external view returns (Vote memory);

  /**
    * @notice method to start a vote on a proposal specified by its id.
    * @param proposalId id of the proposal to start the vote on.
    * @return the id of the proposal that had the vote started on.
    * @dev this method can be called by anyone, requiring that the appropriate conditions are met.
           basically that the proper roots have been registered.
           It can also be called internally when the bridged message is received and the the required roots
           have been registered
    */
  function startProposalVote(uint256 proposalId) external returns (uint256);

  /**
    * @notice method to cast a vote on a proposal specified by its id
    * @param proposalId id of the proposal on which the vote will be cast
    * @param support boolean indicating if the vote is in favor or against the proposal
    * @param votingBalanceProofs list of objects containing the information necessary to vote using the tokens
             allowed on the voting strategy.
    * @dev A vote does not need to use all the tokens allowed, can be a subset
    */
  function submitVote(
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external;

  /**
   * @notice Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param voter the voter address
   * @param support boolean, true = vote for, false = vote against
   * @param votingBalanceProofs list of voting assets proofs
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   */
  function submitVoteBySignature(
    uint256 proposalId,
    address voter,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice method to close a vote on a proposal specified by its id and send the results back to governance
   * @param proposalId id of the proposal to close the vote on and send the voting result to governance
   * @dev This method will trigger the bridging flow
   */
  function closeAndSendVote(uint256 proposalId) external;

  /**
   * @notice method to settle a vote on a proposal originated on the governance chain
   * @param proposalId id of the proposal to vote on
   * @param voter address that wants to vote on proposal
   * @param votingBalanceProofs list of objects containing the information necessary to vote using the tokens
            allowed on the voting strategy.
   */
  function settleVoteFromPortal(
    uint256 proposalId,
    address voter,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
  /**
   * @dev Returns the downcasted uint248 from uint256, reverting on
   * overflow (when the input is greater than largest uint248).
   *
   * Counterpart to Solidity's `uint248` operator.
   *
   * Requirements:
   *
   * - input must fit into 248 bits
   *
   * _Available since v4.7._
   */
  function toUint248(uint256 value) internal pure returns (uint248) {
    require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
    return uint248(value);
  }

  /**
   * @dev Returns the downcasted uint240 from uint256, reverting on
   * overflow (when the input is greater than largest uint240).
   *
   * Counterpart to Solidity's `uint240` operator.
   *
   * Requirements:
   *
   * - input must fit into 240 bits
   *
   * _Available since v4.7._
   */
  function toUint240(uint256 value) internal pure returns (uint240) {
    require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
    return uint240(value);
  }

  /**
   * @dev Returns the downcasted uint232 from uint256, reverting on
   * overflow (when the input is greater than largest uint232).
   *
   * Counterpart to Solidity's `uint232` operator.
   *
   * Requirements:
   *
   * - input must fit into 232 bits
   *
   * _Available since v4.7._
   */
  function toUint232(uint256 value) internal pure returns (uint232) {
    require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
    return uint232(value);
  }

  /**
   * @dev Returns the downcasted uint224 from uint256, reverting on
   * overflow (when the input is greater than largest uint224).
   *
   * Counterpart to Solidity's `uint224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   *
   * _Available since v4.2._
   */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
    return uint224(value);
  }

  /**
   * @dev Returns the downcasted uint216 from uint256, reverting on
   * overflow (when the input is greater than largest uint216).
   *
   * Counterpart to Solidity's `uint216` operator.
   *
   * Requirements:
   *
   * - input must fit into 216 bits
   *
   * _Available since v4.7._
   */
  function toUint216(uint256 value) internal pure returns (uint216) {
    require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
    return uint216(value);
  }

  /**
   * @dev Returns the downcasted uint208 from uint256, reverting on
   * overflow (when the input is greater than largest uint208).
   *
   * Counterpart to Solidity's `uint208` operator.
   *
   * Requirements:
   *
   * - input must fit into 208 bits
   *
   * _Available since v4.7._
   */
  function toUint208(uint256 value) internal pure returns (uint208) {
    require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
    return uint208(value);
  }

  /**
   * @dev Returns the downcasted uint200 from uint256, reverting on
   * overflow (when the input is greater than largest uint200).
   *
   * Counterpart to Solidity's `uint200` operator.
   *
   * Requirements:
   *
   * - input must fit into 200 bits
   *
   * _Available since v4.7._
   */
  function toUint200(uint256 value) internal pure returns (uint200) {
    require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
    return uint200(value);
  }

  /**
   * @dev Returns the downcasted uint192 from uint256, reverting on
   * overflow (when the input is greater than largest uint192).
   *
   * Counterpart to Solidity's `uint192` operator.
   *
   * Requirements:
   *
   * - input must fit into 192 bits
   *
   * _Available since v4.7._
   */
  function toUint192(uint256 value) internal pure returns (uint192) {
    require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
    return uint192(value);
  }

  /**
   * @dev Returns the downcasted uint184 from uint256, reverting on
   * overflow (when the input is greater than largest uint184).
   *
   * Counterpart to Solidity's `uint184` operator.
   *
   * Requirements:
   *
   * - input must fit into 184 bits
   *
   * _Available since v4.7._
   */
  function toUint184(uint256 value) internal pure returns (uint184) {
    require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
    return uint184(value);
  }

  /**
   * @dev Returns the downcasted uint176 from uint256, reverting on
   * overflow (when the input is greater than largest uint176).
   *
   * Counterpart to Solidity's `uint176` operator.
   *
   * Requirements:
   *
   * - input must fit into 176 bits
   *
   * _Available since v4.7._
   */
  function toUint176(uint256 value) internal pure returns (uint176) {
    require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
    return uint176(value);
  }

  /**
   * @dev Returns the downcasted uint168 from uint256, reverting on
   * overflow (when the input is greater than largest uint168).
   *
   * Counterpart to Solidity's `uint168` operator.
   *
   * Requirements:
   *
   * - input must fit into 168 bits
   *
   * _Available since v4.7._
   */
  function toUint168(uint256 value) internal pure returns (uint168) {
    require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
    return uint168(value);
  }

  /**
   * @dev Returns the downcasted uint160 from uint256, reverting on
   * overflow (when the input is greater than largest uint160).
   *
   * Counterpart to Solidity's `uint160` operator.
   *
   * Requirements:
   *
   * - input must fit into 160 bits
   *
   * _Available since v4.7._
   */
  function toUint160(uint256 value) internal pure returns (uint160) {
    require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
    return uint160(value);
  }

  /**
   * @dev Returns the downcasted uint152 from uint256, reverting on
   * overflow (when the input is greater than largest uint152).
   *
   * Counterpart to Solidity's `uint152` operator.
   *
   * Requirements:
   *
   * - input must fit into 152 bits
   *
   * _Available since v4.7._
   */
  function toUint152(uint256 value) internal pure returns (uint152) {
    require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
    return uint152(value);
  }

  /**
   * @dev Returns the downcasted uint144 from uint256, reverting on
   * overflow (when the input is greater than largest uint144).
   *
   * Counterpart to Solidity's `uint144` operator.
   *
   * Requirements:
   *
   * - input must fit into 144 bits
   *
   * _Available since v4.7._
   */
  function toUint144(uint256 value) internal pure returns (uint144) {
    require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
    return uint144(value);
  }

  /**
   * @dev Returns the downcasted uint136 from uint256, reverting on
   * overflow (when the input is greater than largest uint136).
   *
   * Counterpart to Solidity's `uint136` operator.
   *
   * Requirements:
   *
   * - input must fit into 136 bits
   *
   * _Available since v4.7._
   */
  function toUint136(uint256 value) internal pure returns (uint136) {
    require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
    return uint136(value);
  }

  /**
   * @dev Returns the downcasted uint128 from uint256, reverting on
   * overflow (when the input is greater than largest uint128).
   *
   * Counterpart to Solidity's `uint128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   *
   * _Available since v2.5._
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint120 from uint256, reverting on
   * overflow (when the input is greater than largest uint120).
   *
   * Counterpart to Solidity's `uint120` operator.
   *
   * Requirements:
   *
   * - input must fit into 120 bits
   *
   * _Available since v4.7._
   */
  function toUint120(uint256 value) internal pure returns (uint120) {
    require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
    return uint120(value);
  }

  /**
   * @dev Returns the downcasted uint112 from uint256, reverting on
   * overflow (when the input is greater than largest uint112).
   *
   * Counterpart to Solidity's `uint112` operator.
   *
   * Requirements:
   *
   * - input must fit into 112 bits
   *
   * _Available since v4.7._
   */
  function toUint112(uint256 value) internal pure returns (uint112) {
    require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
    return uint112(value);
  }

  /**
   * @dev Returns the downcasted uint104 from uint256, reverting on
   * overflow (when the input is greater than largest uint104).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 104 bits
   *
   * _Available since v4.7._
   */
  function toUint104(uint256 value) internal pure returns (uint104) {
    require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
    return uint104(value);
  }

  /**
   * @dev Returns the downcasted uint96 from uint256, reverting on
   * overflow (when the input is greater than largest uint96).
   *
   * Counterpart to Solidity's `uint96` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   *
   * _Available since v4.2._
   */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
    return uint96(value);
  }

  /**
   * @dev Returns the downcasted uint88 from uint256, reverting on
   * overflow (when the input is greater than largest uint88).
   *
   * Counterpart to Solidity's `uint88` operator.
   *
   * Requirements:
   *
   * - input must fit into 88 bits
   *
   * _Available since v4.7._
   */
  function toUint88(uint256 value) internal pure returns (uint88) {
    require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
    return uint88(value);
  }

  /**
   * @dev Returns the downcasted uint80 from uint256, reverting on
   * overflow (when the input is greater than largest uint80).
   *
   * Counterpart to Solidity's `uint80` operator.
   *
   * Requirements:
   *
   * - input must fit into 80 bits
   *
   * _Available since v4.7._
   */
  function toUint80(uint256 value) internal pure returns (uint80) {
    require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
    return uint80(value);
  }

  /**
   * @dev Returns the downcasted uint72 from uint256, reverting on
   * overflow (when the input is greater than largest uint72).
   *
   * Counterpart to Solidity's `uint72` operator.
   *
   * Requirements:
   *
   * - input must fit into 72 bits
   *
   * _Available since v4.7._
   */
  function toUint72(uint256 value) internal pure returns (uint72) {
    require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
    return uint72(value);
  }

  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   *
   * _Available since v2.5._
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint56 from uint256, reverting on
   * overflow (when the input is greater than largest uint56).
   *
   * Counterpart to Solidity's `uint56` operator.
   *
   * Requirements:
   *
   * - input must fit into 56 bits
   *
   * _Available since v4.7._
   */
  function toUint56(uint256 value) internal pure returns (uint56) {
    require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
    return uint56(value);
  }

  /**
   * @dev Returns the downcasted uint48 from uint256, reverting on
   * overflow (when the input is greater than largest uint48).
   *
   * Counterpart to Solidity's `uint48` operator.
   *
   * Requirements:
   *
   * - input must fit into 48 bits
   *
   * _Available since v4.7._
   */
  function toUint48(uint256 value) internal pure returns (uint48) {
    require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
    return uint48(value);
  }

  /**
   * @dev Returns the downcasted uint40 from uint256, reverting on
   * overflow (when the input is greater than largest uint40).
   *
   * Counterpart to Solidity's `uint40` operator.
   *
   * Requirements:
   *
   * - input must fit into 40 bits
   *
   * _Available since v4.7._
   */
  function toUint40(uint256 value) internal pure returns (uint40) {
    require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
    return uint40(value);
  }

  /**
   * @dev Returns the downcasted uint32 from uint256, reverting on
   * overflow (when the input is greater than largest uint32).
   *
   * Counterpart to Solidity's `uint32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   *
   * _Available since v2.5._
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint24 from uint256, reverting on
   * overflow (when the input is greater than largest uint24).
   *
   * Counterpart to Solidity's `uint24` operator.
   *
   * Requirements:
   *
   * - input must fit into 24 bits
   *
   * _Available since v4.7._
   */
  function toUint24(uint256 value) internal pure returns (uint24) {
    require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
    return uint24(value);
  }

  /**
   * @dev Returns the downcasted uint16 from uint256, reverting on
   * overflow (when the input is greater than largest uint16).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   *
   * _Available since v2.5._
   */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
    return uint16(value);
  }

  /**
   * @dev Returns the downcasted uint8 from uint256, reverting on
   * overflow (when the input is greater than largest uint8).
   *
   * Counterpart to Solidity's `uint8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits
   *
   * _Available since v2.5._
   */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
    return uint8(value);
  }

  /**
   * @dev Converts a signed int256 into an unsigned uint256.
   *
   * Requirements:
   *
   * - input must be greater than or equal to 0.
   *
   * _Available since v3.0._
   */
  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, 'SafeCast: value must be positive');
    return uint256(value);
  }

  /**
   * @dev Returns the downcasted int248 from int256, reverting on
   * overflow (when the input is less than smallest int248 or
   * greater than largest int248).
   *
   * Counterpart to Solidity's `int248` operator.
   *
   * Requirements:
   *
   * - input must fit into 248 bits
   *
   * _Available since v4.7._
   */
  function toInt248(int256 value) internal pure returns (int248 downcasted) {
    downcasted = int248(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
  }

  /**
   * @dev Returns the downcasted int240 from int256, reverting on
   * overflow (when the input is less than smallest int240 or
   * greater than largest int240).
   *
   * Counterpart to Solidity's `int240` operator.
   *
   * Requirements:
   *
   * - input must fit into 240 bits
   *
   * _Available since v4.7._
   */
  function toInt240(int256 value) internal pure returns (int240 downcasted) {
    downcasted = int240(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
  }

  /**
   * @dev Returns the downcasted int232 from int256, reverting on
   * overflow (when the input is less than smallest int232 or
   * greater than largest int232).
   *
   * Counterpart to Solidity's `int232` operator.
   *
   * Requirements:
   *
   * - input must fit into 232 bits
   *
   * _Available since v4.7._
   */
  function toInt232(int256 value) internal pure returns (int232 downcasted) {
    downcasted = int232(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
  }

  /**
   * @dev Returns the downcasted int224 from int256, reverting on
   * overflow (when the input is less than smallest int224 or
   * greater than largest int224).
   *
   * Counterpart to Solidity's `int224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   *
   * _Available since v4.7._
   */
  function toInt224(int256 value) internal pure returns (int224 downcasted) {
    downcasted = int224(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
  }

  /**
   * @dev Returns the downcasted int216 from int256, reverting on
   * overflow (when the input is less than smallest int216 or
   * greater than largest int216).
   *
   * Counterpart to Solidity's `int216` operator.
   *
   * Requirements:
   *
   * - input must fit into 216 bits
   *
   * _Available since v4.7._
   */
  function toInt216(int256 value) internal pure returns (int216 downcasted) {
    downcasted = int216(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
  }

  /**
   * @dev Returns the downcasted int208 from int256, reverting on
   * overflow (when the input is less than smallest int208 or
   * greater than largest int208).
   *
   * Counterpart to Solidity's `int208` operator.
   *
   * Requirements:
   *
   * - input must fit into 208 bits
   *
   * _Available since v4.7._
   */
  function toInt208(int256 value) internal pure returns (int208 downcasted) {
    downcasted = int208(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
  }

  /**
   * @dev Returns the downcasted int200 from int256, reverting on
   * overflow (when the input is less than smallest int200 or
   * greater than largest int200).
   *
   * Counterpart to Solidity's `int200` operator.
   *
   * Requirements:
   *
   * - input must fit into 200 bits
   *
   * _Available since v4.7._
   */
  function toInt200(int256 value) internal pure returns (int200 downcasted) {
    downcasted = int200(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
  }

  /**
   * @dev Returns the downcasted int192 from int256, reverting on
   * overflow (when the input is less than smallest int192 or
   * greater than largest int192).
   *
   * Counterpart to Solidity's `int192` operator.
   *
   * Requirements:
   *
   * - input must fit into 192 bits
   *
   * _Available since v4.7._
   */
  function toInt192(int256 value) internal pure returns (int192 downcasted) {
    downcasted = int192(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
  }

  /**
   * @dev Returns the downcasted int184 from int256, reverting on
   * overflow (when the input is less than smallest int184 or
   * greater than largest int184).
   *
   * Counterpart to Solidity's `int184` operator.
   *
   * Requirements:
   *
   * - input must fit into 184 bits
   *
   * _Available since v4.7._
   */
  function toInt184(int256 value) internal pure returns (int184 downcasted) {
    downcasted = int184(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
  }

  /**
   * @dev Returns the downcasted int176 from int256, reverting on
   * overflow (when the input is less than smallest int176 or
   * greater than largest int176).
   *
   * Counterpart to Solidity's `int176` operator.
   *
   * Requirements:
   *
   * - input must fit into 176 bits
   *
   * _Available since v4.7._
   */
  function toInt176(int256 value) internal pure returns (int176 downcasted) {
    downcasted = int176(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
  }

  /**
   * @dev Returns the downcasted int168 from int256, reverting on
   * overflow (when the input is less than smallest int168 or
   * greater than largest int168).
   *
   * Counterpart to Solidity's `int168` operator.
   *
   * Requirements:
   *
   * - input must fit into 168 bits
   *
   * _Available since v4.7._
   */
  function toInt168(int256 value) internal pure returns (int168 downcasted) {
    downcasted = int168(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
  }

  /**
   * @dev Returns the downcasted int160 from int256, reverting on
   * overflow (when the input is less than smallest int160 or
   * greater than largest int160).
   *
   * Counterpart to Solidity's `int160` operator.
   *
   * Requirements:
   *
   * - input must fit into 160 bits
   *
   * _Available since v4.7._
   */
  function toInt160(int256 value) internal pure returns (int160 downcasted) {
    downcasted = int160(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
  }

  /**
   * @dev Returns the downcasted int152 from int256, reverting on
   * overflow (when the input is less than smallest int152 or
   * greater than largest int152).
   *
   * Counterpart to Solidity's `int152` operator.
   *
   * Requirements:
   *
   * - input must fit into 152 bits
   *
   * _Available since v4.7._
   */
  function toInt152(int256 value) internal pure returns (int152 downcasted) {
    downcasted = int152(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
  }

  /**
   * @dev Returns the downcasted int144 from int256, reverting on
   * overflow (when the input is less than smallest int144 or
   * greater than largest int144).
   *
   * Counterpart to Solidity's `int144` operator.
   *
   * Requirements:
   *
   * - input must fit into 144 bits
   *
   * _Available since v4.7._
   */
  function toInt144(int256 value) internal pure returns (int144 downcasted) {
    downcasted = int144(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
  }

  /**
   * @dev Returns the downcasted int136 from int256, reverting on
   * overflow (when the input is less than smallest int136 or
   * greater than largest int136).
   *
   * Counterpart to Solidity's `int136` operator.
   *
   * Requirements:
   *
   * - input must fit into 136 bits
   *
   * _Available since v4.7._
   */
  function toInt136(int256 value) internal pure returns (int136 downcasted) {
    downcasted = int136(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
  }

  /**
   * @dev Returns the downcasted int128 from int256, reverting on
   * overflow (when the input is less than smallest int128 or
   * greater than largest int128).
   *
   * Counterpart to Solidity's `int128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   *
   * _Available since v3.1._
   */
  function toInt128(int256 value) internal pure returns (int128 downcasted) {
    downcasted = int128(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
  }

  /**
   * @dev Returns the downcasted int120 from int256, reverting on
   * overflow (when the input is less than smallest int120 or
   * greater than largest int120).
   *
   * Counterpart to Solidity's `int120` operator.
   *
   * Requirements:
   *
   * - input must fit into 120 bits
   *
   * _Available since v4.7._
   */
  function toInt120(int256 value) internal pure returns (int120 downcasted) {
    downcasted = int120(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
  }

  /**
   * @dev Returns the downcasted int112 from int256, reverting on
   * overflow (when the input is less than smallest int112 or
   * greater than largest int112).
   *
   * Counterpart to Solidity's `int112` operator.
   *
   * Requirements:
   *
   * - input must fit into 112 bits
   *
   * _Available since v4.7._
   */
  function toInt112(int256 value) internal pure returns (int112 downcasted) {
    downcasted = int112(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
  }

  /**
   * @dev Returns the downcasted int104 from int256, reverting on
   * overflow (when the input is less than smallest int104 or
   * greater than largest int104).
   *
   * Counterpart to Solidity's `int104` operator.
   *
   * Requirements:
   *
   * - input must fit into 104 bits
   *
   * _Available since v4.7._
   */
  function toInt104(int256 value) internal pure returns (int104 downcasted) {
    downcasted = int104(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
  }

  /**
   * @dev Returns the downcasted int96 from int256, reverting on
   * overflow (when the input is less than smallest int96 or
   * greater than largest int96).
   *
   * Counterpart to Solidity's `int96` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   *
   * _Available since v4.7._
   */
  function toInt96(int256 value) internal pure returns (int96 downcasted) {
    downcasted = int96(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
  }

  /**
   * @dev Returns the downcasted int88 from int256, reverting on
   * overflow (when the input is less than smallest int88 or
   * greater than largest int88).
   *
   * Counterpart to Solidity's `int88` operator.
   *
   * Requirements:
   *
   * - input must fit into 88 bits
   *
   * _Available since v4.7._
   */
  function toInt88(int256 value) internal pure returns (int88 downcasted) {
    downcasted = int88(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
  }

  /**
   * @dev Returns the downcasted int80 from int256, reverting on
   * overflow (when the input is less than smallest int80 or
   * greater than largest int80).
   *
   * Counterpart to Solidity's `int80` operator.
   *
   * Requirements:
   *
   * - input must fit into 80 bits
   *
   * _Available since v4.7._
   */
  function toInt80(int256 value) internal pure returns (int80 downcasted) {
    downcasted = int80(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
  }

  /**
   * @dev Returns the downcasted int72 from int256, reverting on
   * overflow (when the input is less than smallest int72 or
   * greater than largest int72).
   *
   * Counterpart to Solidity's `int72` operator.
   *
   * Requirements:
   *
   * - input must fit into 72 bits
   *
   * _Available since v4.7._
   */
  function toInt72(int256 value) internal pure returns (int72 downcasted) {
    downcasted = int72(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
  }

  /**
   * @dev Returns the downcasted int64 from int256, reverting on
   * overflow (when the input is less than smallest int64 or
   * greater than largest int64).
   *
   * Counterpart to Solidity's `int64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   *
   * _Available since v3.1._
   */
  function toInt64(int256 value) internal pure returns (int64 downcasted) {
    downcasted = int64(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
  }

  /**
   * @dev Returns the downcasted int56 from int256, reverting on
   * overflow (when the input is less than smallest int56 or
   * greater than largest int56).
   *
   * Counterpart to Solidity's `int56` operator.
   *
   * Requirements:
   *
   * - input must fit into 56 bits
   *
   * _Available since v4.7._
   */
  function toInt56(int256 value) internal pure returns (int56 downcasted) {
    downcasted = int56(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
  }

  /**
   * @dev Returns the downcasted int48 from int256, reverting on
   * overflow (when the input is less than smallest int48 or
   * greater than largest int48).
   *
   * Counterpart to Solidity's `int48` operator.
   *
   * Requirements:
   *
   * - input must fit into 48 bits
   *
   * _Available since v4.7._
   */
  function toInt48(int256 value) internal pure returns (int48 downcasted) {
    downcasted = int48(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
  }

  /**
   * @dev Returns the downcasted int40 from int256, reverting on
   * overflow (when the input is less than smallest int40 or
   * greater than largest int40).
   *
   * Counterpart to Solidity's `int40` operator.
   *
   * Requirements:
   *
   * - input must fit into 40 bits
   *
   * _Available since v4.7._
   */
  function toInt40(int256 value) internal pure returns (int40 downcasted) {
    downcasted = int40(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
  }

  /**
   * @dev Returns the downcasted int32 from int256, reverting on
   * overflow (when the input is less than smallest int32 or
   * greater than largest int32).
   *
   * Counterpart to Solidity's `int32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   *
   * _Available since v3.1._
   */
  function toInt32(int256 value) internal pure returns (int32 downcasted) {
    downcasted = int32(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
  }

  /**
   * @dev Returns the downcasted int24 from int256, reverting on
   * overflow (when the input is less than smallest int24 or
   * greater than largest int24).
   *
   * Counterpart to Solidity's `int24` operator.
   *
   * Requirements:
   *
   * - input must fit into 24 bits
   *
   * _Available since v4.7._
   */
  function toInt24(int256 value) internal pure returns (int24 downcasted) {
    downcasted = int24(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
  }

  /**
   * @dev Returns the downcasted int16 from int256, reverting on
   * overflow (when the input is less than smallest int16 or
   * greater than largest int16).
   *
   * Counterpart to Solidity's `int16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   *
   * _Available since v3.1._
   */
  function toInt16(int256 value) internal pure returns (int16 downcasted) {
    downcasted = int16(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
  }

  /**
   * @dev Returns the downcasted int8 from int256, reverting on
   * overflow (when the input is less than smallest int8 or
   * greater than largest int8).
   *
   * Counterpart to Solidity's `int8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits
   *
   * _Available since v3.1._
   */
  function toInt8(int256 value) internal pure returns (int8 downcasted) {
    downcasted = int8(value);
    require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
  }

  /**
   * @dev Converts an unsigned uint256 into a signed int256.
   *
   * Requirements:
   *
   * - input must be less than or equal to maxInt256.
   *
   * _Available since v3.0._
   */
  function toInt256(uint256 value) internal pure returns (int256) {
    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
    require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
    return int256(value);
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
  function verifyBlockHeader(
    bytes memory _headerRlpBytes,
    bytes32 _blockHash
  ) internal pure returns (BlockHeader memory) {
    BlockHeader memory header = parseBlockHeader(_headerRlpBytes);
    require(header.hash == _blockHash, 'blockhash mismatch');
    return header;
  }

  /**
   * @notice Parses RLP-encoded block header.
   * @param _headerRlpBytes RLP-encoded block header.
   */
  function parseBlockHeader(
    bytes memory _headerRlpBytes
  ) internal pure returns (BlockHeader memory) {
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

/**
 * @title IBaseVotingStrategy
 * @author BGD Labs
 * @notice interface containing the objects, events and method definitions of the BaseVotingStrategy contract
 */
interface IBaseVotingStrategy {
  /**
   * @notice object storing the information of the asset used for the voting strategy
   * @param storageSlots list of slots for the balance of the specified token.
            From that slot, by adding the address of the user, the correct balance can be taken.
   */
  struct VotingAssetConfig {
    uint128[] storageSlots;
  }

  /**
   * @notice emitted when an asset is added for the voting strategy
   * @param asset address of the token to be added
   * @param storageSlots array of storage positions of the balance mapping
   */
  event VotingAssetAdd(address indexed asset, uint128[] storageSlots);

  /**
   * @notice method to get the AAVE token address
   * @return AAVE token contract address
   */
  function AAVE() external view returns (address);

  /**
   * @notice method to get the A_AAVE token address
   * @return A_AAVE token contract address
   */
  function A_AAVE() external view returns (address);

  /**
   * @notice method to get the stkAAVE token address
   * @return stkAAVE token contract address
   */
  function STK_AAVE() external view returns (address);

  /**
   * @notice method to get the slot of the balance of the AAVE and stkAAVE
   * @return AAVE and stkAAVE base balance slot
   */
  function BASE_BALANCE_SLOT() external view returns (uint128);

  /**
   * @notice method to get the slot of the balance of the AAVE aToken
   * @return AAVE aToken base balance slot
   */
  function A_AAVE_BASE_BALANCE_SLOT() external view returns (uint128);

  /**
   * @notice method to get the slot of the AAVE aToken delegation state
   * @return AAVE aToken delegation state slot
   */
  function A_AAVE_DELEGATED_STATE_SLOT() external view returns (uint128);

  /**
   * @notice method to check if a token and slot combination is accepted
   * @param token address of the token to check
   * @param slot number of the token slot
   * @return flag indicating if the token slot is accepted
   */
  function isTokenSlotAccepted(
    address token,
    uint128 slot
  ) external view returns (bool);

  /**
   * @notice method to get the addresses of the assets that can be used for voting
   * @return list of addresses of assets
   */
  function getVotingAssetList() external view returns (address[] memory);

  /**
   * @notice method to get the configuration for voting of an asset
   * @param asset address of the asset to get the configuration from
   * @return object with the asset configuration containing the list of storage slots
   */
  function getVotingAssetConfig(
    address asset
  ) external view returns (VotingAssetConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SlotUtils {
  /**
   * @notice method to calculate the slot hash of the a mapping indexed by account
   * @param account address of the balance holder
   * @param balanceMappingPosition base position of the storage slot of the balance on a token contract
   * @return the slot hash
   */
  function getAccountSlotHash(
    address account,
    uint256 balanceMappingPosition
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          bytes32(uint256(uint160(account))),
          balanceMappingPosition
        )
      );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.19;

import {ECDSA} from "./ECDSA.sol";
import {ShortStrings, ShortString} from "../ShortStrings.sol";
import {IERC5267} from "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {IERC-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _name which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     *
     * _Available since v5.0._
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Name() internal view returns (string memory) {
        return _name.toStringWithFallback(_nameFallback);
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: By default this function reads _version which is an immutable value.
     * It only reads from storage if necessary (in case the value is too large to fit in a ShortString).
     *
     * _Available since v5.0._
     */
    // solhint-disable-next-line func-name-mixedcase
    function _EIP712Version() internal view returns (string memory) {
        return _version.toStringWithFallback(_versionFallback);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.19;

import {Strings} from "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseGasLimit
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the BaseGasLimit contract
 */
interface IBaseGasLimit {
  /**
   * @notice emitted when gas limit gets updated
   * @param gasLimit the new gas limit
   */
  event GasLimitUpdated(uint256 indexed gasLimit);

  /**
   * @notice method to get the maximum gas limit
   * @return the max gas limit
   */
  function MAX_GAS_LIMIT() external view returns (uint256);

  /**
   * @notice method to get the maximum gas limit
   * @return the max gas limit
   */
  function MIN_GAS_LIMIT() external view returns (uint256);

  /**
   * @notice method to update the gasLimit
   * @param gasLimit the new gas limit
   * @dev this method should have a owner gated permission. But responsibility is relegated to inheritance
   */
  function updateGasLimit(uint256 gasLimit) external;

  /**
   * @notice method to get the gasLimit
   * @return gasLimit the new gas limit
   */
  function getGasLimit() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Transaction, Envelope} from '../libs/EncodingUtils.sol';

/**
 * @title ICrossChainForwarder
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainForwarder contract
 */
interface ICrossChainForwarder {
  /**
   * @notice object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @notice object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param destinationChainId id of the destination chain using our own nomenclature
   */
  struct ForwarderBridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    uint256 destinationChainId;
  }

  /**
   * @notice emitted when a transaction is successfully forwarded through a bridge adapter
   * @param envelopeId internal id of the envelope
   * @param envelope the Envelope type data
   */
  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);

  /**
   * @notice emitted when a transaction forwarding is attempted through a bridge adapter
   * @param transactionId id of the forwarded transaction
   * @param envelopeId internal id of the envelope
   * @param encodedTransaction object intended to be bridged
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param adapterSuccessful adapter was able to forward the message
   * @param returnData bytes with error information
   */
  event TransactionForwardingAttempted(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    bytes encodedTransaction,
    uint256 destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed adapterSuccessful,
    bytes returnData
  );

  /**
   * @notice emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    uint256 indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @notice emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /**
   * @notice method to get the current valid envelope nonce
   * @return the current valid envelope nonce
   */
  function getCurrentEnvelopeNonce() external view returns (uint256);

  /**
   * @notice method to get the current valid transaction nonce
   * @return the current valid transaction nonce
   */
  function getCurrentTransactionNonce() external view returns (uint256);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelope the Envelope type data
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(Envelope memory envelope) external view returns (bool);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelopeId the hashed id of the envelope
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(bytes32 envelopeId) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transaction the Transaction type data
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(Transaction memory transaction) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transactionId hashed id of the transaction
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(bytes32 transactionId) external view returns (bool);

  /**
   * @notice method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   * @return internal id of the envelope and transaction
   */
  function forwardMessage(
    uint256 destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external returns (bytes32, bytes32);

  /**
   * @notice method called to re forward a previously sent envelope.
   * @param envelope the Envelope type data
   * @param gasLimit gas cost on receiving side of the message
   * @return the transaction id that has the retried envelope
   * @dev This method will send an existing Envelope using a new Transaction.
   * @dev This method should be used when the intention is to send the Envelope as if it was a new message. This way on
          the Receiver side it will start from 0 to count for the required confirmations. (usual use case would be for
          when an envelope has been invalidated on Receiver side, and needs to be retried as a new message)
   */
  function retryEnvelope(Envelope memory envelope, uint256 gasLimit) external returns (bytes32);

  /**
   * @notice method to retry forwarding an already forwarded transaction
   * @param encodedTransaction the encoded Transaction data
   * @param gasLimit limit of gas to spend on forwarding per bridge
   * @param bridgeAdaptersToRetry list of bridge adapters to be used for the transaction forwarding retry
   * @dev This method will send an existing Transaction with its Envelope to the specified adapters.
   * @dev Should be used when some of the bridges on the initial forwarding did not work (out of gas),
          and we want the Transaction with Envelope to still account for the required confirmations on the Receiver side
   */
  function retryTransaction(
    bytes memory encodedTransaction,
    uint256 gasLimit,
    address[] memory bridgeAdaptersToRetry
  ) external;

  /**
   * @notice method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(ForwarderBridgeAdapterConfigInput[] memory bridgeAdapters) external;

  /**
   * @notice method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(BridgeAdapterToDisable[] memory bridgeAdapters) external;

  /**
   * @notice method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @notice method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @notice method to get all the bridge adapters of a chain
   * @param chainId id of the chain we want to get the adateprs from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @notice method to get if a sender is approved
   * @param sender address that we want to check if approved
   * @return boolean indicating if the address has been approved as sender
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';
import {Transaction, Envelope} from '../libs/EncodingUtils.sol';

/**
 * @title ICrossChainReceiver
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainReceiver contract
 */
interface ICrossChainReceiver {
  /**
   * @notice object with information to set new required confirmations
   * @param chainId id of the origin chain
   * @param requiredConfirmations required confirmations to set a message as confirmed
   */
  struct ConfirmationInput {
    uint256 chainId;
    uint8 requiredConfirmations;
  }

  /**
   * @notice object with information to set new validity timestamp
   * @param chainId id of the origin chain
   * @param validityTimestamp new timestamp in seconds to set as validity point
   */
  struct ValidityTimestampInput {
    uint256 chainId;
    uint120 validityTimestamp;
  }

  /**
   * @notice object with necessary information to allow new bridge adapters
   * @param chainIds array of ids of the chains the adapter will receive messages from
   * @param bridgeAdapter address of the bridge adapter to add
   */
  struct ReceiverBridgeAdapterConfigInput {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object containing the receiver configuration
   * @param requiredConfirmation number of bridges that are needed to make a bridged message valid from origin chain
   * @param validityTimestamp all messages originated but not finally confirmed before this timestamp per origin chain, are invalid
   */
  struct ReceiverConfiguration {
    uint8 requiredConfirmation;
    uint120 validityTimestamp;
  }

  /**
   * @notice object with full information of the receiver configuration for a chain
   * @param configuration object containing the specifications of the receiver for a chain
   * @param allowedBridgeAdapters stores if a bridge adapter is allowed for a chain
   */
  struct ReceiverConfigurationFull {
    ReceiverConfiguration configuration;
    EnumerableSet.AddressSet allowedBridgeAdapters;
  }

  /**
   * @notice object that stores the internal information of the transaction
   * @param confirmations number of times that this transaction has been bridged
   * @param firstBridgedAt timestamp in seconds indicating the first time a transaction was received
   */
  struct TransactionStateWithoutAdapters {
    uint8 confirmations;
    uint120 firstBridgedAt;
  }
  /**
   * @notice object that stores the internal information of the transaction with bridge adapters state
   * @param confirmations number of times that this transactions has been bridged
   * @param firstBridgedAt timestamp in seconds indicating the first time a transaction was received
   * @param bridgedByAdapter list of bridge adapters that have bridged the message
   */
  struct TransactionState {
    uint8 confirmations;
    uint120 firstBridgedAt;
    mapping(address => bool) bridgedByAdapter;
  }

  /**
   * @notice object with the current state of an envelope
   * @param confirmed boolean indicating if the bridged message has been confirmed by the infrastructure
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   */
  enum EnvelopeState {
    None,
    Confirmed,
    Delivered
  }

  /**
   * @notice emitted when a transaction has been received successfully
   * @param transactionId id of the transaction
   * @param envelopeId id of the envelope
   * @param originChainId id of the chain where the envelope originated
   * @param transaction the Transaction type data
   * @param bridgeAdapter address of the bridge adapter who received the message (deployed on current network)
   * @param confirmations number of current confirmations for this message
   */
  event TransactionReceived(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    uint256 indexed originChainId,
    Transaction transaction,
    address indexed bridgeAdapter,
    uint8 confirmations
  );

  /**
   * @notice emitted when an envelope has been delivery attempted
   * @param envelopeId id of the envelope
   * @param envelope the Envelope type data
   * @param isDelivered flag indicating if the message has been delivered successfully
   */
  event EnvelopeDeliveryAttempted(bytes32 envelopeId, Envelope envelope, bool isDelivered);

  /**
   * @notice emitted when a bridge adapter gets updated (allowed or disallowed)
   * @param bridgeAdapter address of the updated bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   * @param chainId id of the chain updated
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed bridgeAdapter,
    bool indexed allowed,
    uint256 indexed chainId
  );

  /**
   * @notice emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   * @param chainId id of the chain updated
   */
  event ConfirmationsUpdated(uint8 newConfirmations, uint256 indexed chainId);

  /**
   * @notice emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   * @param chainId id of the chain updated
   */
  event NewInvalidation(uint256 invalidTimestamp, uint256 indexed chainId);

  /**
   * @notice method to get the current allowed bridge adapters for a chain
   * @param chainId id of the chain to get the allowed bridge adapter list
   * @return the list of allowed bridge adapters
   */
  function getAllowedBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (address[] memory);

  /**
   * @notice method to get the current supported chains (at least one allowed bridge adapter)
   * @return list of supported chains
   */
  function getSupportedChains() external view returns (uint256[] memory);

  /**
   * @notice method to get the current configuration of a chain
   * @param chainId id of the chain to get the configuration from
   * @return the specified chain configuration object
   */
  function getConfigurationByChain(
    uint256 chainId
  ) external view returns (ReceiverConfiguration memory);

  /**
   * @notice method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the bridge adapter to check
   * @param chainId id of the chain to check
   * @return boolean indicating if bridge adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(
    address bridgeAdapter,
    uint256 chainId
  ) external view returns (bool);

  /**
   * @notice  method to get the current state of a transaction
   * @param transactionId the id of transaction
   * @return number of confirmations of internal message identified by the transactionId and the updated timestamp
   */
  function getTransactionState(
    bytes32 transactionId
  ) external view returns (TransactionStateWithoutAdapters memory);

  /**
   * @notice  method to get the internal transaction information
   * @param transaction Transaction type data
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getTransactionState(
    Transaction memory transaction
  ) external view returns (TransactionStateWithoutAdapters memory);

  /**
   * @notice method to get the internal state of an envelope
   * @param envelope the Envelope type data
   * @return the envelope current state, containing if it has been confirmed and delivered
   */
  function getEnvelopeState(Envelope memory envelope) external view returns (EnvelopeState);

  /**
   * @notice method to get the internal state of an envelope
   * @param envelopeId id of the envelope
   * @return the envelope current state, containing if it has been confirmed and delivered
   */
  function getEnvelopeState(bytes32 envelopeId) external view returns (EnvelopeState);

  /**
   * @notice method to get if transaction has been received by bridge adapter
   * @param transactionId id of the transaction as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * @return boolean indicating if the message has been received
   */
  function isTransactionReceivedByAdapter(
    bytes32 transactionId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @notice method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp array of objects containing the chain and timestamp where all the previous unconfirmed
            messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(
    ValidityTimestampInput[] memory newValidityTimestamp
  ) external;

  /**
   * @notice method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations array of objects with the chainId and the new number of needed confirmations
   */
  function updateConfirmations(ConfirmationInput[] memory newConfirmations) external;

  /**
   * @notice method that receives a bridged transaction and tries to deliver the contents to destination if possible
   * @param encodedTransaction bytes containing the bridged information
   * @param originChainId id of the chain where the transaction originated
   */
  function receiveCrossChainMessage(
    bytes memory encodedTransaction,
    uint256 originChainId
  ) external;

  /**
   * @notice method to deliver an envelope to its destination
   * @param envelope the Envelope typed data
   * @dev to deliver an envelope, it needs to have been previously confirmed and not delivered
   */
  function deliverEnvelope(Envelope memory envelope) external;

  /**
   * @notice method to add bridge adapters to the allowed list
   * @param bridgeAdaptersInput array of objects with the new bridge adapters and supported chains
   */
  function allowReceiverBridgeAdapters(
    ReceiverBridgeAdapterConfigInput[] memory bridgeAdaptersInput
  ) external;

  /**
   * @notice method to remove bridge adapters from the allowed list
   * @param bridgeAdaptersInput array of objects with the bridge adapters and supported which should not be supported anymore
   */
  function disallowReceiverBridgeAdapters(
    ReceiverBridgeAdapterConfigInput[] memory bridgeAdaptersInput
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @title IRescuable
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the Rescuable contract
 */
interface IRescuable {
  /**
   * @notice emitted when erc20 tokens get rescued
   * @param caller address that triggers the rescue
   * @param token address of the rescued token
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event ERC20Rescued(
    address indexed caller,
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /**
   * @notice emitted when native tokens get rescued
   * @param caller address that triggers the rescue
   * @param to address that will receive the rescued tokens
   * @param amount quantity of tokens rescued
   */
  event NativeTokensRescued(address indexed caller, address indexed to, uint256 amount);

  /**
   * @notice method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;

  /**
   * @notice method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
   * @notice method that defines the address that is allowed to rescue tokens
   * @return the allowed address
   */
  function whoCanRescue() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {StateProofVerifier} from '../libs/StateProofVerifier.sol';

/**
 * @title IDataWarehouse
 * @author BGD Labs
 * @notice interface containing the methods definitions of the DataWarehouse contract
 */
interface IDataWarehouse {
  /**
   * @notice event emitted when a storage root has been processed successfully
   * @param caller address that called the processStorageRoot method
   * @param account address where the root is generated
   * @param blockHash hash of the block where the root was generated
   */
  event StorageRootProcessed(
    address indexed caller,
    address indexed account,
    bytes32 indexed blockHash
  );

  /**
   * @notice event emitted when a storage root has been processed successfully
   * @param caller address that called the processStorageSlot method
   * @param account address where the slot is processed
   * @param blockHash hash of the block where the storage proof was generated
   * @param slot storage location to search
   * @param value storage information on the specified location
   */
  event StorageSlotProcessed(
    address indexed caller,
    address indexed account,
    bytes32 indexed blockHash,
    bytes32 slot,
    uint256 value
  );

  /**
   * @notice method to get the storage roots of an account (token) in a certain block hash
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @return state root hash of the account on the block hash specified
   */
  function getStorageRoots(
    address account,
    bytes32 blockHash
  ) external view returns (bytes32);

  /**
   * @notice method to process the storage root from an account on a block hash.
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @param blockHeaderRLP rlp encoded block header. At same block where the block hash was taken
   * @param accountStateProofRLP rlp encoded account state proof, taken in same block as block hash
   * @return the storage root
   */
  function processStorageRoot(
    address account,
    bytes32 blockHash,
    bytes memory blockHeaderRLP,
    bytes memory accountStateProofRLP
  ) external returns (bytes32);

  /**
   * @notice method to get the storage value at a certain slot and block hash for a certain address
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @param slot hash of the explicit storage placement where the value to get is found.
   * @param storageProof generated proof containing the storage, at block hash
   * @return an object containing the slot value at the specified storage slot
   */
  function getStorage(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes memory storageProof
  ) external view returns (StateProofVerifier.SlotValue memory);

  /**
   * @notice method to register the storage value at a certain slot and block hash for a certain address
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @param slot hash of the explicit storage placement where the value to get is found.
   * @param storageProof generated proof containing the storage, at block hash
   */
  function processStorageSlot(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes calldata storageProof
  ) external;

  /**
   * @notice method to get the value from storage at a certain block hash, previously registered.
   * @param blockHash hash of the block from where the roots are generated
   * @param account address of the token to get the storage roots from
   * @param slot hash of the explicit storage placement where the value to get is found.
   * @return numeric slot value of the slot. The value must be decoded to get the actual stored information
   */
  function getRegisteredSlot(
    bytes32 blockHash,
    address account,
    bytes32 slot
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDataWarehouse} from './IDataWarehouse.sol';

/**
 * @title IVotingStrategy
 * @author BGD Labs
 * @notice interface containing the methods definitions of the VotingStrategy contract
 */
interface IVotingStrategy {
  /**
   * @notice method to get the DataWarehouse contract
   * @return DataWarehouse contract
   */
  function DATA_WAREHOUSE() external view returns (IDataWarehouse);

  /**
   * @notice method to get the exchange rate precision. Taken from stkTokenV3 contract
   * @return exchange rate precission
   */
  function STK_AAVE_SLASHING_EXCHANGE_RATE_PRECISION()
    external
    view
    returns (uint256);

  /**
   * @notice method to get the slot of the stkAave exchange rate in the stkAave contract
   * @return stkAave exchange rate slot
   */
  function STK_AAVE_SLASHING_EXCHANGE_RATE_SLOT()
    external
    view
    returns (uint256);

  /**
   * @notice method to get the power scale factor of the delegated balances
   * @return power scale factor
   */
  function POWER_SCALE_FACTOR() external view returns (uint256);

  /**
   * @notice method to get the power of an asset
   * @param asset address of the token to get the power
   * @param storageSlot storage position of the balance mapping
   * @param power balance of a determined asset to be used for the vote
   * @param blockHash block hash of when we want to get the power. Optional parameter
   * @return voting power of the specified asset
   */
  function getVotingPower(
    address asset,
    uint128 storageSlot,
    uint256 power,
    bytes32 blockHash
  ) external view returns (uint256);

  /**
   * @notice method to check that the roots for all the tokens in the voting strategy have been registered. Including
             the registry of the stkAave exchange rate slot
   * @param blockHash hash of the block from where the roots have been registered.
   */
  function hasRequiredRoots(bytes32 blockHash) external view;
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
  function iterator(
    RLPItem memory self
  ) internal pure returns (Iterator memory) {
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
  function payloadLocation(
    RLPItem memory item
  ) internal pure returns (uint256, uint256) {
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
  function toList(
    RLPItem memory item
  ) internal pure returns (RLPItem[] memory) {
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
  function rlpBytesKeccak256(
    RLPItem memory item
  ) internal pure returns (bytes32) {
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
  function payloadKeccak256(
    RLPItem memory item
  ) internal pure returns (bytes32) {
    (uint256 memPtr, uint256 len) = payloadLocation(item);
    bytes32 result;
    assembly {
      result := keccak256(memPtr, len)
    }
    return result;
  }

  /** RLPItem conversions into data types **/

  // @returns raw rlp encoding in bytes
  function toRlpBytes(
    RLPItem memory item
  ) internal pure returns (bytes memory) {
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
  function copy(uint256 src, uint256 dest, uint256 len) private pure {
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
      uint256 mask = 256 ** (WORD_SIZE - len) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask)) // zero out src
        let destpart := and(mload(dest), mask) // retrieve the bytes
        mstore(dest, or(destpart, srcpart))
      }
    }
  }
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
  function _mptHashHash(
    RLPReader.RLPItem memory item
  ) private pure returns (bytes32) {
    if (item.len < 32) {
      return item.rlpBytesKeccak256();
    } else {
      return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
    }
  }

  function _isEmptyBytesequence(
    RLPReader.RLPItem memory item
  ) private pure returns (bool) {
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

  function _merklePatriciaCompactDecode(
    bytes memory compact
  ) private pure returns (bool isLeaf, bytes memory nibbles) {
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

  function _decodeNibbles(
    bytes memory compact,
    uint256 skipNibbles
  ) private pure returns (bytes memory nibbles) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.19;

import {StorageSlot} from "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.19;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.19;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

using EnvelopeUtils for Envelope global;
using TransactionUtils for Transaction global;

/**
 * @notice Object with the necessary information to define a unique envelope
 * @param nonce sequential (unique) numeric indicator of the Envelope creation
 * @param origin address that originated the bridging of a message
 * @param destination address where the message needs to be sent
 * @param originChainId id of the chain where the message originated
 * @param destinationChainId id of the chain where the message needs to be bridged
 * @param message bytes that needs to be bridged
 */
struct Envelope {
  uint256 nonce;
  address origin;
  address destination;
  uint256 originChainId;
  uint256 destinationChainId;
  bytes message;
}

/**
 * @notice Object containing the information of an envelope for internal usage
 * @param data bytes of the encoded envelope
 * @param id hash of the encoded envelope
 */
struct EncodedEnvelope {
  bytes data;
  bytes32 id;
}

/**
 * @title EnvelopeUtils library
 * @author BGD Labs
 * @notice Defines utility functions for Envelopes
 */
library EnvelopeUtils {
  /**
   * @notice method that encodes an Envelope and generates its id
   * @param envelope object with the routing information necessary to send a message to a destination chain
   * @return object containing the encoded envelope and the envelope id
   */
  function encode(Envelope memory envelope) internal pure returns (EncodedEnvelope memory) {
    EncodedEnvelope memory encodedEnvelope;
    encodedEnvelope.data = abi.encode(envelope);
    encodedEnvelope.id = getId(encodedEnvelope.data);
    return encodedEnvelope;
  }

  /**
   * @notice method to decode and encoded envelope to its raw parameters
   * @param envelope bytes with the encoded envelope data
   * @return object with the decoded envelope information
   */
  function decode(bytes memory envelope) internal pure returns (Envelope memory) {
    return abi.decode(envelope, (Envelope));
  }

  /**
   * @notice method to get an envelope's id
   * @param envelope object with the routing information necessary to send a message to a destination chain
   * @return hash id of the envelope
   */
  function getId(Envelope memory envelope) internal pure returns (bytes32) {
    EncodedEnvelope memory encodedEnvelope = encode(envelope);
    return encodedEnvelope.id;
  }

  /**
   * @notice method to get an envelope's id
   * @param envelope bytes with the encoded envelope data
   * @return hash id of the envelope
   */
  function getId(bytes memory envelope) internal pure returns (bytes32) {
    return keccak256(envelope);
  }
}

/**
 * @notice Object with the necessary information to send an envelope to a bridge
 * @param nonce sequential (unique) numeric indicator of the Transaction creation
 * @param encodedEnvelope bytes of an encoded envelope object
 */
struct Transaction {
  uint256 nonce;
  bytes encodedEnvelope;
}

/**
 * @notice Object containing the information of a transaction for internal usage
 * @param data bytes of the encoded transaction
 * @param id hash of the encoded transaction
 */
struct EncodedTransaction {
  bytes data;
  bytes32 id;
}

/**
 * @title TransactionUtils library
 * @author BGD Labs
 * @notice Defines utility functions for Transactions
 */
library TransactionUtils {
  /**
   * @notice method that encodes a Transaction and generates its id
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return object containing the encoded transaction and the transaction id
   */
  function encode(
    Transaction memory transaction
  ) internal pure returns (EncodedTransaction memory) {
    EncodedTransaction memory encodedTransaction;
    encodedTransaction.data = abi.encode(transaction);
    encodedTransaction.id = getId(encodedTransaction.data);
    return encodedTransaction;
  }

  /**
   * @notice method that encodes a Transaction and generates its id
   * @param transaction encoded transaction object
   * @return object containing the encoded transaction and the transaction id
   */
  function decode(bytes memory transaction) internal pure returns (Transaction memory) {
    return abi.decode(transaction, (Transaction));
  }

  /**
   * @notice method to get an transaction id
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return hash id of the transaction
   */
  function getId(Transaction memory transaction) internal pure returns (bytes32) {
    EncodedTransaction memory encodedTransaction = encode(transaction);
    return encodedTransaction.id;
  }

  /**
   * @notice method to get an transaction id
   * @param transaction encoded transaction object
   * @return hash id of the transaction
   */
  function getId(bytes memory transaction) internal pure returns (bytes32) {
    return keccak256(transaction);
  }

  /**
   * @notice method to get the envelope information from the transaction object
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return object with decoded information of the envelope in the transaction
   */
  function getEnvelope(Transaction memory transaction) internal pure returns (Envelope memory) {
    return EnvelopeUtils.decode(transaction.encodedEnvelope);
  }

  /**
   * @notice method to get the envelope id from the transaction object
   * @param transaction object with the information necessary to send an envelope to a bridge
   * @return hash id of the envelope on a transaction
   */
  function getEnvelopeId(Transaction memory transaction) internal pure returns (bytes32) {
    return EnvelopeUtils.getId(transaction.encodedEnvelope);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.19;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.19;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
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
     * _Available since v5.0._
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
     * _Available since v5.0._
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
     * _Available since v5.0._
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
     * _Available since v5.0._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}