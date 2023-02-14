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
    PolygonMumbai,
    ArbitrumGoerli,
    FantomTestnet,
    HarmonyTestnet
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingMachineWithProofs} from '../voting/interfaces/IVotingMachineWithProofs.sol';
import {IVotingMachineDataHelper} from './interfaces/IVotingMachineDataHelper.sol';
import {IBaseVotingStrategy} from '../../interfaces/IBaseVotingStrategy.sol';

contract VotingMachineDataHelper is IVotingMachineDataHelper {
  function getProposalsData(
    IVotingMachineWithProofs votingMachine,
    uint256[] calldata proposalIds,
    address user
  ) external view returns (Proposal[] memory) {
    Proposal[] memory proposals = new Proposal[](proposalIds.length);
    IVotingMachineWithProofs.ProposalWithoutVotes memory proposalWithoutVotes;
    IVotingMachineWithProofs.Vote memory vote;

    for (uint256 i = 0; i < proposalIds.length; i++) {
      IVotingMachineWithProofs.ProposalState state = votingMachine
        .getProposalState(proposalIds[i]);

      if (state > IVotingMachineWithProofs.ProposalState.NotCreated) {
        proposalWithoutVotes = votingMachine.getProposalById(proposalIds[i]);

        if (user != address(0x0)) {
          vote = votingMachine.getUserProposalVote(user, proposalIds[i]);
        }

        proposals[i] = Proposal({
          proposalData: proposalWithoutVotes,
          votedInfo: VotedInfo({
            support: vote.support,
            votingPower: vote.votingPower
          }),
          votingAssets: IBaseVotingStrategy(
            address(proposalWithoutVotes.strategy)
          ).getVotingAssetList()
        });
      } else {
        proposals[i] = Proposal({
          proposalData: IVotingMachineWithProofs.ProposalWithoutVotes({
            id: proposalIds[i],
            forVotes: 0,
            againstVotes: 0,
            startTime: 0,
            endTime: 0,
            votingEndedBlock: 0,
            l1BlockHash: '',
            strategy: votingMachine.getVotingStrategy(),
            sentToL1: false,
            creationBlockNumber: 0,
            votingEndedTimestamp: 0
          }),
          votedInfo: VotedInfo({support: false, votingPower: 0}),
          votingAssets: IBaseVotingStrategy(
            address(votingMachine.getVotingStrategy())
          ).getVotingAssetList()
        });
      }
    }

    return proposals;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseVotingStrategy} from '../../../interfaces/IBaseVotingStrategy.sol';
import {IVotingMachineWithProofs} from '../../voting/interfaces/IVotingMachineWithProofs.sol';

interface IVotingMachineDataHelper {
  struct VotedInfo {
    bool support;
    uint248 votingPower;
  }

  struct Proposal {
    IVotingMachineWithProofs.ProposalWithoutVotes proposalData;
    VotedInfo votedInfo;
    address[] votingAssets;
  }

  function getProposalsData(IVotingMachineWithProofs votingMachine, uint256[] calldata proposalIds, address user)
    external
    view
    returns (Proposal[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRootsWarehouse} from './IRootsWarehouse.sol';

interface IL2VotingStrategy {
  /**
   * @notice method to get the RootsWarehouse contract
   * @return RootsWarehouse contract
   **/
  function ROOTS_WAREHOUSE() external view returns (IRootsWarehouse);

  /**
   * @notice method to get the AAVE Token contract address
   * @return AAVE Token contract address
   **/
  function AAVE() external view returns (address);

  /**
   * @notice method to get STK_AAVE Token contract address
   * @return STK_AAVE Token contract address
   **/
  function STK_AAVE() external view returns (address);

  /**
   * @notice method to get the exchange rate precision. Taken from stkTokenV3 contract
   * @return exchange rate precission
   **/
  function EXCHANGE_RATE_PRECISION() external view returns (uint256);

  /**
   * @notice method to get the slot of the stkAave exchange rate in the stkAave contract
   * @return stkAave exchange rate slot
   **/
  function STK_AAVE_EXCHANGE_RATE_SLOT() external view returns (uint256);

  /**
   * @notice method to check that the roots for all the tokens in the voting strategy have been registered. Including
             the registry of the stkAave exchange rate slot
   * @param blockHash hash of the block from where the roots have been registered.
   **/
  function hasRequiredRoots(bytes32 blockHash) external view;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {StateProofVerifier} from '../libs/StateProofVerifier.sol';

interface IRootsWarehouse {
  /**
   * @notice method to get the storage roots of an account (token) in a certain blockHash
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @return state root hash of the account on the blockHash specified
   **/
  function getStorageRoots(address account, bytes32 blockHash)
    external
    view
    returns (bytes32);

  /**
   * @notice method to process the storage root from an account on a blockHash.
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @param blockHeaderRLP rlp encoded block header. At same block where the blockHash was taken
   * @param accountStateProofRLP rlp encoded account state proof, taken in same block as blockHash
   * @return the storage root
   **/
  function processStorageRoot(
    address account,
    bytes32 blockHash,
    bytes memory blockHeaderRLP,
    bytes memory accountStateProofRLP
  ) external returns (bytes32);

  /**
   * @notice method to get the storage value at a certain slot and blockHash for a certain address
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @param slot hash of the explicit storage placement where the value to get is found.
   * @param storageProof generated proof containing the storage, at blockHash
   * @return an object containing the slot value at the specified storage slot
   **/
  function getStorage(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes memory storageProof
  ) external view returns (StateProofVerifier.SlotValue memory);

  /**
   * @notice method to register the storage value at a certain slot and blockHash for a certain address
   * @param account address of the token to get the storage roots from
   * @param blockHash hash of the block from where the roots are generated
   * @param slot hash of the explicit storage placement where the value to get is found.
   * @param storageProof generated proof containing the storage, at blockHash
   **/
  function processStorageSlot(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes calldata storageProof
  ) external;

  /**
   * @notice method to get the value from storage at a certain blockHash, previously registered.
   * @param blockHash hash of the block from where the roots are generated
   * @param account address of the token to get the storage roots from
   * @param slot hash of the explicit storage placement where the value to get is found.
   * @return numeric slot value of the slot. The value must be decoded to get the actual stored information
   **/
  function getRegisteredSlot(
    bytes32 blockHash,
    address account,
    bytes32 slot
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRootsWarehouse} from './IRootsWarehouse.sol';
import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IL2VotingStrategy} from './IL2VotingStrategy.sol';

interface IVotingMachineWithProofs {
  /**
   * @notice object containing the information of a bridged vote
   * @param support indicates if vote is in favor or against the proposal
   * @param votingTokens list of token addresses that the voter will use for voting
   **/
  struct BridgedVote {
    bool support;
    address[] votingTokens;
  }

  /// @notice enum delimiting the possible states a proposal can have on the voting machine
  enum ProposalState {
    NotCreated,
    Active,
    Finished,
    WaitingForFinality,
    SentToL1
  }

  /**
   * @notice Object with vote information
   * @param support boolean indicating if the vote is in favor or against a proposal
   * @param votingPower the power used for voting
   **/
  struct Vote {
    bool support;
    uint248 votingPower;
  }

  /**
   * @notice Object containing a proposal information
   * @param id numeric identification of the proposal
   * @param strategy address of the voting strategy used on the proposal
   * @param sentToL1 boolean indication if the proposal results have been sent back to L1 governance
   * @param l1BlockHash hash of the block on L1 from the block when the proposal was activated for voting (sent to voting machine)
            this blockHash is used to delimit from when the voting power is accounted for voting
   * @param startTime timestamp of the start of voting on the proposal
   * @param endTime timestamp when the voting on the proposal finishes (startTime + votingDuration)
   * @param votingEndedTimestamp timestamp indicating when the vote has been closed
   * @param forVotes votes cast in favor of the proposal
   * @param againstVotes votes cast against the proposal
   * @param creationBlockNumber blockNumber from when the proposal has been created in votingMachine
   * @param votingEndedBlock block from when the vote has been closed
   * @param votes mapping indication for every voter of the proposal the information of that vote
   **/
  struct Proposal {
    uint256 id;
    IL2VotingStrategy strategy;
    bool sentToL1;
    bytes32 l1BlockHash;
    uint48 startTime;
    uint48 endTime;
    uint48 votingEndedTimestamp;
    uint128 forVotes;
    uint128 againstVotes;
    uint256 creationBlockNumber;
    uint256 votingEndedBlock;
    mapping(address => Vote) votes;
  }

  /**
   * @notice Object containing a proposal information
   * @param id numeric identification of the proposal
   * @param strategy address of the voting strategy used on the proposal
   * @param sentToL1 boolean indication if the proposal results have been sent back to L1 governance
   * @param l1BlockHash hash of the block on L1 from the block when the proposal was activated for voting (sent to voting machine)
            this blockHash is used to delimit from when the voting power is accounted for voting
   * @param startTime timestamp of the start of voting on the proposal
   * @param endTime timestamp when the voting on the proposal finishes (startTime + votingDuration)
   * @param votingEndedTimestamp timestamp indicating when the vote has been closed
   * @param forVotes votes cast in favor of the proposal
   * @param againstVotes votes cast against the proposal
   * @param creationBlockNumber blockNumber from when the proposal has been created in votingMachine
   * @param votingEndedBlock block from when the vote has been closed
   **/
  struct ProposalWithoutVotes {
    uint256 id;
    IL2VotingStrategy strategy;
    bool sentToL1;
    bytes32 l1BlockHash;
    uint48 startTime;
    uint48 endTime;
    uint48 votingEndedTimestamp;
    uint128 forVotes;
    uint128 againstVotes;
    uint256 creationBlockNumber;
    uint256 votingEndedBlock;
  }

  /**
   * @notice vote configuration passed from l1
   * @param votingDuration duration in seconds of the vote for a proposal
   * @param l1ProposalBlockHash block hash of the proposal on l1 from the block when proposal was activated
   **/
  struct ProposalVoteConfiguration {
    uint24 votingDuration;
    //    uint40 creationTime; TODO: for now we will not use. should be to check that it has not been to long since bridged
    bytes32 l1ProposalBlockHash;
  }

  /**
   * @notice Object with the necessary information to process a vote
   * @param underlyingAsset address of the token on L1, used for voting
   * @param slot base storage position where the balance on underlyingAsset contract resides on L1. (Normally position 0)
   * @param proof bytes of the generated proof on L1 with the slot information of underlying asset.
   **/
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
   * @param strategy address of the voting strategy contract used for the voting on this proposal
   **/
  event ProposalVoteCreated(
    uint256 indexed proposalId,
    bytes32 indexed l1BlockHash,
    uint256 startTime,
    uint256 endTime,
    address strategy
  );

  /**
   * @notice emitted when voting on a proposal is closed
   * @param proposalId numeric id of the closed proposal
   * @param endedBlock block where the proposal voting was closed
   **/
  event ProposalVoteClosed(uint256 indexed proposalId, uint256 endedBlock);

  /**
   * @notice emitted when the results of a vote on a proposal are sent to L1
   * @param proposalId numeric id of the proposal which results are sent to L1
   * @param forVotes votes cast in favor of proposal
   * @param againstVotes votes cast against the proposal
   **/
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
   **/
  event VoteEmitted(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    uint256 votingPower
  );

  /**
   * @notice emitted when a new address for the RootsWarehouse contract has been set
   * @param newRootsWarehouse address of the new RootsWarehouse
   **/
  event RootsWarehouseUpdated(address indexed newRootsWarehouse);

  /**
   * @notice emitted when a new address for the VotingStrategy contract has been set
   * @param newVotingStrategy address of the new VotingStrategy
   **/
  event VotingStrategyUpdated(address indexed newVotingStrategy);

  /**
   * @notice emitted when a voting configuration of a proposal gets received. Meaning that has been bridged successfully
   * @param proposalId id of the proposal bridged to start the vote on
   * @param blockHash hash of the block on L1 when the proposal was activated for voting
   * @param votingDuration duration in seconds of the vote
   * @param voteCreated boolean indicating if the vote has been created or not.
   * @dev the vote will only be created automatically if when the configuration is bridged, all necessary roots
          have been registered already.
   **/
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
   * @param votingTokens list of token addresses that the voter will use for voting
   **/
  event VoteBridged(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    address[] votingTokens
  );

  /**
   * @notice method to get the domain type hash for permits digest
   * @return hash of domain string
   **/
  function DOMAIN_TYPEHASH() external view returns (bytes32);

  /**
   * @notice method to get the vote submitted type hash for permits digest
   * @return hash of vote submitted string
   **/
  function VOTE_SUBMITTED_TYPEHASH() external view returns (bytes32);

  /**
   * @notice method to get the contract name for permits digest
   * @return contract name string
   **/
  function NAME() external view returns (string memory);

  /**
    * @notice method to get the number of blocks used to mark finality on a vote (that need to pass) after the vote is closed,
              before being able to send the voting results to L1
    * @return number of blocks to vote finality
    **/
  function BLOCKS_TO_FINALITY() external view returns (uint256);

  /**
   * @notice method to get the address of the current RootsWarehouse contract
   * returns the address of the RootsWarehouse contract
   **/
  function getRootsWarehouse() external view returns (IRootsWarehouse);

  /**
   * @notice method to get the address of the current VotingStrategy contract
   * returns the address of the VotingStrategy contract
   **/
  function getVotingStrategy() external view returns (IL2VotingStrategy);

  /**
   * @notice method to get a proposal information specified by its id
   * @param proposalId id of the proposal to retrieve
   * @return the proposal information without the users vote
   **/
  function getProposalById(uint256 proposalId)
    external
    view
    returns (ProposalWithoutVotes memory);

  /**
   * @notice method to get the state of a proposal specified by its id
   * @param proposalId id of the proposal to retrieve the state of
   * @return the state of the proposal
   **/
  function getProposalState(uint256 proposalId)
    external
    view
    returns (ProposalState);

  /**
   * @notice method to get the voting configuration of a proposal specified by its id
   * @param proposalId id of the proposal to retrieve the voting configuration from
   * @return the proposal vote configuration object
   **/
  function getProposalVoteConfiguration(uint256 proposalId)
    external
    view
    returns (ProposalVoteConfiguration memory);

  /**
   * @notice method to get the information of a bridged vote for a proposal from a voter
   * @param proposalId id of the proposal to retrieve the vote information from
   * @param voter address of that emitted the bridging of the vote
   **/
  function getBridgedVoteInfo(uint256 proposalId, address voter)
    external
    view
    returns (BridgedVote memory);

  /**
   * @notice method to get the vote set by a user on a proposal specified by its id
   * @param user address of the user that voted
   * @param proposalId id of the proposal to retrieve the vote from
   **/
  function getUserProposalVote(address user, uint256 proposalId)
    external
    view
    returns (Vote memory);

  // TODO: revisit naming
  /**
    * @notice method to start a vote on a proposal specified by its id.
    * @param proposalId id of the proposal to start the vote on.
    * @return the id of the proposal that had the vote started on.
    * @dev this method can be called by anyone, requiring that the appropriate conditions are met.
           basically that the proper roots have been registered.
           It can also be called internally when the bridged message is received and the the required roots
           have been registered
    **/
  function createVote(uint256 proposalId) external returns (uint256);

  /**
    * @notice method to cast a vote on a proposal specified by its id
    * @param proposalId id of hte proposal on which the vote will be cast
    * @param support boolean indicating if the vote is in favor or against the proposal
    * @param votingBalanceProofs list of objects containing the information necessary to vote using the tokens
             allowed on the voting strategy.
    * @dev A vote does not need to use all the tokens allowed, can be a subset
    **/
  function submitVote(
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external;

  /**
   * @notice Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   * @param votingBalanceProofs list of voting assets proofs
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    bool support,
    VotingBalanceProof[] calldata votingBalanceProofs,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice method to close a vote on a proposal specified by its id
   * @param proposalId id of the proposal to close the vote on
   **/
  function closeVote(uint256 proposalId) external;

  /**
   * @notice method to send the voting results on a proposal back to L1
   * @param proposalId id of the proposal to send the voting result to L1
   * @dev This method will trigger the bridging flow
   **/
  function sendVoteResult(uint256 proposalId) external;

  /**
   * @notice method to set a new RootsWarehouse contract
   * @param newRootsWarehouse address of the new RootsWarehouse contract
   **/
  function setRootsWarehouse(IRootsWarehouse newRootsWarehouse) external;

  /**
   * @notice method to set a new VotingStrategy contract
   * @param newVotingStrategy address of the new VotingStrategy contract
   **/
  function setVotingStrategy(IL2VotingStrategy newVotingStrategy) external;

  /**
   * @notice method to calculate the slot hash of the balance of a holder
   * @param holder address of the balance holder
   * @param balanceMappingPosition base position of the storage slot of the balance on a token contract
   * @return the balance slot hash
   * @dev normally the base position of the balance is 0
   **/
  function slotOfAddressUint256Mapping(
    address holder,
    uint256 balanceMappingPosition
  ) external pure returns (bytes32);

  /**
   * @notice method to calculate the slot hash of the balance of a holder
   * @param proposalId id of the proposal to vote on
   * @param voter address that wants to vote on proposal
   * @param votingBalanceProofs list of objects containing the information necessary to vote using the tokens
            allowed on the voting strategy.
   **/
  function submitBridgedVote(
    uint256 proposalId,
    address voter,
    VotingBalanceProof[] calldata votingBalanceProofs
  ) external;
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
   * @param blockHash blockHash of when we want to get the weighted power. Optional parameter
   */
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power,
    bytes32 blockHash
  ) external view returns (uint256);
}