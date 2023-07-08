// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDataWarehouse} from './interfaces/IDataWarehouse.sol';
import {StateProofVerifier} from './libs/StateProofVerifier.sol';
import {RLPReader} from './libs/RLPReader.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title DataWarehouse
 * @author BGD Labs
 * @notice This contract stores account state roots and allows proving against them
 */
contract DataWarehouse is IDataWarehouse {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  // account address => (block hash => Account state root hash)
  mapping(address => mapping(bytes32 => bytes32)) internal _storageRoots;

  // account address => (block hash => (slot => slot value))
  mapping(address => mapping(bytes32 => mapping(bytes32 => uint256)))
    internal _slotsRegistered;

  /// @inheritdoc IDataWarehouse
  function getStorageRoots(
    address account,
    bytes32 blockHash
  ) external view returns (bytes32) {
    return _storageRoots[account][blockHash];
  }

  /// @inheritdoc IDataWarehouse
  function getRegisteredSlot(
    bytes32 blockHash,
    address account,
    bytes32 slot
  ) external view returns (uint256) {
    return _slotsRegistered[account][blockHash][slot];
  }

  /// @inheritdoc IDataWarehouse
  function processStorageRoot(
    address account,
    bytes32 blockHash,
    bytes memory blockHeaderRLP,
    bytes memory accountStateProofRLP
  ) external returns (bytes32) {
    StateProofVerifier.BlockHeader memory decodedHeader = StateProofVerifier
      .verifyBlockHeader(blockHeaderRLP, blockHash);
    // The path for an account in the state trie is the hash of its address
    bytes32 proofPath = keccak256(abi.encodePacked(account));
    StateProofVerifier.Account memory accountData = StateProofVerifier
      .extractAccountFromProof(
        proofPath,
        decodedHeader.stateRootHash,
        accountStateProofRLP.toRlpItem().toList()
      );

    _storageRoots[account][blockHash] = accountData.storageRoot;

    emit StorageRootProcessed(msg.sender, account, blockHash);

    return accountData.storageRoot;
  }

  /// @inheritdoc IDataWarehouse
  function getStorage(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes memory storageProof
  ) public view returns (StateProofVerifier.SlotValue memory) {
    bytes32 root = _storageRoots[account][blockHash];
    require(root != bytes32(0), Errors.UNPROCESSED_STORAGE_ROOT);

    // The path for a storage value is the hash of its slot
    bytes32 proofPath = keccak256(abi.encodePacked(slot));
    StateProofVerifier.SlotValue memory slotData = StateProofVerifier
      .extractSlotValueFromProof(
        proofPath,
        root,
        storageProof.toRlpItem().toList()
      );

    return slotData;
  }

  /// @inheritdoc IDataWarehouse
  function processStorageSlot(
    address account,
    bytes32 blockHash,
    bytes32 slot,
    bytes calldata storageProof
  ) external {
    StateProofVerifier.SlotValue memory storageSlot = getStorage(
      account,
      blockHash,
      slot,
      storageProof
    );

    _slotsRegistered[account][blockHash][slot] = storageSlot.value;

    emit StorageSlotProcessed(
      msg.sender,
      account,
      blockHash,
      slot,
      storageSlot.value
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