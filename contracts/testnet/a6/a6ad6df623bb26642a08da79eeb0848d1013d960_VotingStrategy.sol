// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum DelegationMode {
  NO_DELEGATION,
  VOTING_DELEGATED,
  PROPOSITION_DELEGATED,
  FULL_POWER_DELEGATED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseVotingStrategy} from '../interfaces/IBaseVotingStrategy.sol';
import {Errors} from './libraries/Errors.sol';

/**
 * @title BaseVotingStrategy
 * @author BGD Labs
 * @notice This contract contains the base logic of a voting strategy, being on governance chain or voting machine chain.
 */
abstract contract BaseVotingStrategy is IBaseVotingStrategy {
  uint128 public constant WEIGHT_PRECISION = 100;

  /// @dev on the constructor we get all the voting assets and emit the different asset configurations
  constructor() {
    address[] memory votingAssetList = getVotingAssetList();

    // Check that voting strategy at least has one asset
    require(votingAssetList.length != 0, Errors.NO_VOTING_ASSETS);

    for (uint256 i; i < votingAssetList.length; i++) {
      VotingAssetConfig memory votingAssetConfig = getVotingAssetConfig(
        votingAssetList[i]
      );
      emit VotingAssetAdd(
        votingAssetList[i],
        votingAssetConfig.baseStorageSlot,
        votingAssetConfig.weight
      );
    }
  }

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetList() public view virtual returns (address[] memory);

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetConfig(
    address asset
  ) public view virtual returns (VotingAssetConfig memory);

  /// @inheritdoc IBaseVotingStrategy
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power,
    bytes32,
    address
  ) public view virtual returns (uint256) {
    VotingAssetConfig memory votingAssetConfig = getVotingAssetConfig(asset);
    if (votingAssetConfig.baseStorageSlot == baseStorageSlot) {
      return (power * votingAssetConfig.weight) / WEIGHT_PRECISION;
    }
    return 0;
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
  string public constant VOTING_CONFIG_IS_NOT_ACTIVE = '4'; // to create proposal the configuration associated with the access level must be active
  string public constant PROPOSITION_POWER_IS_TOO_LOW = '5'; // proposition power of proposal creator must be equal or higher than the specified threshold for the access level
  string public constant REQUESTED_ACCESS_LEVEL_IS_TOO_LOW = '6'; // access level should be at least as high as the level required to execute the proposal payload
  string public constant PROPOSAL_NOT_IN_CREATED_STATE = '7'; // proposal should be in the CREATED state
  string public constant PROPOSAL_NOT_IN_ACTIVE_STATE = '8'; // proposal must be in an ACTIVE state
  string public constant PROPOSAL_NOT_IN_QUEUED_STATE = '9'; // proposal must be in a QUEUED state
  string public constant VOTING_START_COOLDOWN_PERIOD_NOT_PASSED = '10'; // to activate a proposal vote, the cool down delay must pass
  string public constant TO_MANY_TOKENS_FOR_VOTING = '11'; // can not vote with more tokens than are allowed
  string public constant CALLER_NOT_A_VALID_VOTING_PORTAL = '12'; // only an allowed voting portal can queue a proposal
  string public constant QUEUE_COOLDOWN_PERIOD_NOT_PASSED = '13'; // to execute a proposal a cooldown delay must pass
  string public constant PROPOSAL_NOT_IN_THE_CORRECT_STATE = '14'; // proposal must be created but not executed yet to be able to be canceled
  string public constant CALLER_NOT_GOVERNANCE = '15'; // caller must be governance
  string public constant VOTER_ALREADY_VOTED_ON_PROPOSAL = '16'; // voter can only vote once per proposal using voting portal
  string public constant WRONG_MESSAGE_ORIGIN = '17'; // received message must come from registered source address, chain id, CrossChainController
  string public constant NO_VOTING_ASSETS = '18'; // Strategy must have voting assets
  string public constant WRONG_ENCODED_PROPOSAL_MESSAGE = '19'; // bridged proposal message is not following the appropriate format
  string public constant WRONG_ENCODED_VOTE_MESSAGE = '20'; // bridged vote message is not following the correct format
  string public constant WRONG_ENCODED_MESSAGE_RECEIVED = '21'; // the type of the bridged message is not accepted. Should be PROPOSAL or VOTE
  string public constant PROPOSAL_VOTE_ALREADY_CREATED = '22'; // vote on proposal can only be created once
  string public constant INVALID_SIGNATURE = '23'; // submitted signature is not valid
  string public constant PORTAL_VOTE_WITH_NO_VOTING_TOKENS = '24'; // voting portal vote needs to specify which voting tokens to use
  string public constant PROOFS_NOT_FOR_VOTING_TOKENS = '25'; // provided proofs must be from the voting tokens selected (bridged from governance chain)
  string public constant PROPOSAL_VOTE_NOT_FINISHED = '26'; // proposal vote must be finished
  string public constant PROPOSAL_VOTE_NOT_IN_ACTIVE_STATE = '27'; // proposal vote must be in active state
  string public constant PROPOSAL_VOTE_ALREADY_EXISTS = '28'; // proposal vote already exists
  string public constant VOTE_ONCE_FOR_ASSET = '29'; // an asset can only be used once per vote
  string public constant USER_BALANCE_DOES_NOT_EXISTS = '30'; // to vote an user must have balance in the token the user is voting with
  string public constant USER_VOTING_BALANCE_IS_ZERO = '31'; // to vote an user must have some balance between all the tokens selected for voting
  string public constant MISSING_AAVE_ROOTS = '32'; // must have AAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_ROOTS = '33'; // must have stkAAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_EXCHANGE_RATE = '34'; // must have stkAAVE exchange rate registered to use strategy
  string public constant UNPROCESSED_STORAGE_ROOT = '35'; // root must be registered beforehand
  string public constant NOT_ENOUGH_MSG_VALUE = '36'; // method was not called with enough value to execute the call
  string public constant FAILED_ACTION_EXECUTION = '37'; // action failed to execute
  string public constant SHOULD_BE_AT_LEAST_ONE_EXECUTOR = '38'; // at least one executor is needed
  string public constant INVALID_EMPTY_TARGETS = '39'; // target of the payload execution must not be empty
  string public constant EXECUTOR_WAS_NOT_SPECIFIED_FOR_REQUESTED_ACCESS_LEVEL =
    '40'; // payload executor must be registered for the specified payload access level
  string public constant PAYLOAD_NOT_IN_QUEUED_STATE = '41'; // payload must be en the queued state
  string public constant TIMELOCK_NOT_FINISHED = '42'; // delay has not passed before execution can be called
  string public constant GRACE_PERIOD_FINISHED = '43'; // time frame for execution has passed
  string public constant PAYLOAD_NOT_IN_THE_CORRECT_STATE = '44'; // payload must be created but not executed yet to be able to be canceled
  string public constant PAYLOAD_NOT_IN_CREATED_STATE = '45'; // payload must be in the created state
  string public constant PAYLOAD_EXPIRED = '46'; // delay after payload creation has passed so payload can not be queued
  string public constant MISSING_A_AAVE_ROOTS = '34'; // must have aAAVE roots registered to use strategy
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
pragma solidity ^0.8.0;

import {BaseVotingStrategy, IBaseVotingStrategy} from '../BaseVotingStrategy.sol';
import {StateProofVerifier} from './libs/StateProofVerifier.sol';
import {IVotingStrategy, IDataWarehouse} from './interfaces/IVotingStrategy.sol';
import {DelegationMode} from 'aave-token-v3/DelegationAwareBalance.sol';
import {Errors} from '../libraries/Errors.sol';
import {SlotUtils} from '../libraries/SlotUtils.sol';

/**
 * @title VotingStrategy
 * @author BGD Labs
 * @notice This contracts overrides the base voting strategy to return specific assets used on the strategy.
 * @dev These tokens will be used to get the weighted voting power for proposal voting
 */
contract VotingStrategy is BaseVotingStrategy, IVotingStrategy {
  /// @inheritdoc IVotingStrategy
  IDataWarehouse public immutable DATA_WAREHOUSE;

  // TODO: set correct ones
  /// @inheritdoc IVotingStrategy
  address public constant AAVE = 0x64033B2270fd9D6bbFc35736d2aC812942cE75fE; // TODO: Sepolia aave token

  /// @inheritdoc IVotingStrategy
  address public constant STK_AAVE = 0xA4FDAbdE9eF3045F0dcF9221bab436B784B7e42D; // TODO: Sepolia stk aave token

  /// @inheritdoc IVotingStrategy
  address public constant A_AAVE = 0x7d9EB767eEc260d1bCe8C518276a894aE5535F04; //TODO: Sepolia a aave token

  /// @inheritdoc IVotingStrategy
  uint256 public constant STK_AAVE_EXCHANGE_RATE_PRECISION = 1e18;

  /// @inheritdoc IVotingStrategy
  uint256 public constant STK_AAVE_EXCHANGE_RATE_SLOT = 81;

  /// @inheritdoc IVotingStrategy
  uint256 public constant A_AAVE_DELEGATED_STATE_SLOT = 64;

  /// @inheritdoc IVotingStrategy
  uint256 public constant POWER_SCALE_FACTOR = 1e10;

  //  address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  //  address public constant A_AAVE = 0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B;
  //  address public constant STK_AAVE = 0x4da27a545c0c5B758a6BA100e3a049001de870f5;

  /**
   * @param dataWarehouse address of the DataWarehouse contract used to store roots
   */
  constructor(address dataWarehouse) BaseVotingStrategy() {
    DATA_WAREHOUSE = IDataWarehouse(dataWarehouse);
  }

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetList()
    public
    pure
    override
    returns (address[] memory)
  {
    address[] memory votingAssets = new address[](2);

    votingAssets[0] = AAVE;
    //    votingAssets[1] = STK_AAVE;
    votingAssets[1] = A_AAVE;

    return votingAssets;
  }

  /// @inheritdoc IBaseVotingStrategy
  function getVotingAssetConfig(
    address asset
  ) public pure override returns (VotingAssetConfig memory) {
    VotingAssetConfig memory votingAssetConfig;

    if (asset == A_AAVE) {
      votingAssetConfig.baseStorageSlot = uint128(52);
    }
    votingAssetConfig.weight = WEIGHT_PRECISION;
    return votingAssetConfig;
  }

  /// @inheritdoc IBaseVotingStrategy
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power,
    bytes32 blockHash,
    address voter
  ) public view override returns (uint256) {
    VotingAssetConfig memory votingAssetConfig = getVotingAssetConfig(asset);

    if (asset == STK_AAVE) {
      if (baseStorageSlot == votingAssetConfig.baseStorageSlot) {
        uint256 exchangeRateSlotValue = DATA_WAREHOUSE.getRegisteredSlot(
          blockHash,
          asset,
          bytes32(STK_AAVE_EXCHANGE_RATE_SLOT)
        );

        // casting to uint216 as exchange rate is saved in first 27 bytes of slot
        uint256 exchangeRate = uint256(uint216(exchangeRateSlotValue));

        // Shifting to take into account how stk aave token balances is structured
        uint256 votingPower = uint72(power >> (104 + 72)) * POWER_SCALE_FACTOR; // stored delegated voting power has 0 decimals

        DelegationMode delegationMode = DelegationMode(
          uint8(power >> (104 + 72 + 72))
        );

        if (
          delegationMode != DelegationMode.VOTING_DELEGATED &&
          delegationMode != DelegationMode.FULL_POWER_DELEGATED
        ) {
          // adding user token balance if is not delegating his voting power
          votingPower +=
            (STK_AAVE_EXCHANGE_RATE_PRECISION * uint104(power)) /
            exchangeRate;
        }

        return (votingPower * votingAssetConfig.weight) / WEIGHT_PRECISION;
      }
    } else if (asset == AAVE) {
      if (baseStorageSlot == votingAssetConfig.baseStorageSlot) {
        // Shifting to take into account how aave token v3 balances is structured
        uint256 votingPower = uint72(power >> (104 + 72)) * POWER_SCALE_FACTOR; // stored delegated voting power has 0 decimals

        DelegationMode delegationMode = DelegationMode(
          uint8(power >> (104 + 72 + 72))
        );

        if (
          delegationMode != DelegationMode.VOTING_DELEGATED &&
          delegationMode != DelegationMode.FULL_POWER_DELEGATED
        ) {
          votingPower += uint104(power); // adding user token balance if is not delegating his voting power
        }

        return (votingPower * votingAssetConfig.weight) / WEIGHT_PRECISION;
      }
    } else if (asset == A_AAVE) {
      uint256 votingPower;
      if (baseStorageSlot == A_AAVE_DELEGATED_STATE_SLOT) {
        // Shifting to take into account how aave a token delegation balances is structured
        votingPower = uint72(power >> 72) * POWER_SCALE_FACTOR; //stored delegated voting power has 0 decimals
      } else if (baseStorageSlot == votingAssetConfig.baseStorageSlot) {
        // need to get first 120 as its where balance is stored
        uint256 powerBalance = uint256(uint120(power));

        // next uint8 is for delegationMode
        DelegationMode delegationMode = DelegationMode(uint8(power >> (120)));
        if (
          delegationMode != DelegationMode.VOTING_DELEGATED &&
          delegationMode != DelegationMode.FULL_POWER_DELEGATED
        ) {
          votingPower += powerBalance; // adding user token balance if is not delegating his voting power
        }
      }

      return (votingPower * votingAssetConfig.weight) / WEIGHT_PRECISION;
    }

    return 0;
  }

  // @inheritdoc IVotingStrategy
  function hasRequiredRoots(bytes32 blockHash) external view {
    require(
      DATA_WAREHOUSE.getStorageRoots(AAVE, blockHash) != bytes32(0),
      Errors.MISSING_AAVE_ROOTS
    );
    require(
      DATA_WAREHOUSE.getStorageRoots(STK_AAVE, blockHash) != bytes32(0),
      Errors.MISSING_STK_AAVE_ROOTS
    );
    require(
      DATA_WAREHOUSE.getStorageRoots(A_AAVE, blockHash) != bytes32(0),
      Errors.MISSING_A_AAVE_ROOTS
    );
    require(
      DATA_WAREHOUSE.getRegisteredSlot(
        blockHash,
        STK_AAVE,
        bytes32(STK_AAVE_EXCHANGE_RATE_SLOT)
      ) > 0,
      Errors.MISSING_STK_AAVE_EXCHANGE_RATE
    );
  }
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
 * @notice interface containing the methods definitions of the L2VotingStrategy contract
 */
interface IVotingStrategy {
  /**
   * @notice method to get the DataWarehouse contract
   * @return DataWarehouse contract
   */
  function DATA_WAREHOUSE() external view returns (IDataWarehouse);

  /**
   * @notice method to get the AAVE Token contract address
   * @return AAVE Token contract address
   */
  function AAVE() external view returns (address);

  /**
   * @notice method to get the A_AAVE Token contract address
   * @return A_AAVE Token contract address
   */
  function A_AAVE() external view returns (address);

  /**
   * @notice method to get STK_AAVE Token contract address
   * @return STK_AAVE Token contract address
   */
  function STK_AAVE() external view returns (address);

  /**
   * @notice method to get the exchange rate precision. Taken from stkTokenV3 contract
   * @return exchange rate precission
   */
  function STK_AAVE_EXCHANGE_RATE_PRECISION() external view returns (uint256);

  /**
   * @notice method to get the slot of the stkAave exchange rate in the stkAave contract
   * @return stkAave exchange rate slot
   */
  function STK_AAVE_EXCHANGE_RATE_SLOT() external view returns (uint256);

  /**
   * @notice method to get the slot of the AAVE aToken delegation state
   * @return AAVE aToken delegation state slot
   */
  function A_AAVE_DELEGATED_STATE_SLOT() external view returns (uint256);

  /**
   * @notice method to get the power scale factor of the delegated balances
   * @return power scale factor
   */
  function POWER_SCALE_FACTOR() external view returns (uint256);

  /**
   * @notice method to check that the roots for all the tokens in the voting strategy have been registered. Including
             the registry of the stkAave exchange rate slot
   * @param blockHash hash of the block from where the roots have been registered.
   */
  function hasRequiredRoots(bytes32 blockHash) external view;
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
    // ensure that the block is actually in the blockchain
    // require(header.hash == blockhash(header.number), "blockhash mismatch"); // TODO: remember that I commented this
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
   * @param baseStorageSlot initial slot for the balance of the specified token.
            From that slot, by adding the address of the user, the correct balance can be taken.
   * @param weight determines the importance of the token on the vote.
   */
  struct VotingAssetConfig {
    uint128 baseStorageSlot;
    uint128 weight;
  }

  /**
   * @notice emitted when an asset is added for the voting strategy
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
   * @notice method to get the precision of the weights used.
   * @return the weight precision
   */
  function WEIGHT_PRECISION() external view returns (uint128);

  /**
   * @notice method to get the addresses of the assets that can be used for voting
   * @return list of addresses of assets
   */
  function getVotingAssetList() external view returns (address[] memory);

  /**
   * @notice method to get the configuration for voting of an asset
   * @param asset address of the asset to get the configuration from
   * @return object with the asset configuration containing the base storage slot, and the weight
   */
  function getVotingAssetConfig(
    address asset
  ) external view returns (VotingAssetConfig memory);

  /**
   * @notice method to get the power of an asset, after applying the configured weight for said asset
   * @param asset address of the token to get the weighted power
   * @param baseStorageSlot storage position of the start of the balance mapping
   * @param power balance of a determined asset to be weighted for the vote
   * @param blockHash block hash of when we want to get the weighted power. Optional parameter
   * @param voter address of the voter to get the power from
   * @return weighted power of the specified asset
   */
  function getWeightedPower(
    address asset,
    uint128 baseStorageSlot,
    uint256 power,
    bytes32 blockHash,
    address voter
  ) external view returns (uint256);
}