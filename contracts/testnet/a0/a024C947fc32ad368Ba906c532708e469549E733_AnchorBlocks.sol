// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IEthereumLightClient.sol";
import "./interfaces/IAnchorBlocks.sol";

import "./common/Helpers.sol";
import "./common/Constants.sol";
import "./common/Types.sol";

uint256 constant EXECUTION_BLOCK_LEFT_PREFIX_LEN = 4;

contract AnchorBlocks is IAnchorBlocks, Ownable {
    // BlockHashWitness is the RLP code that witnesses the generation of block hash given the ParentHash field
    struct BlockHashWitness {
        bytes left;
        bytes right;
    }

    event AnchorBlockUpdated(uint256 blockNum, bytes32 blockHash);

    IEthereumLightClient public lightClient;
    // execution block number => execution block hash
    mapping(uint256 => bytes32) public blocks;
    uint256 public latestBlockNum;

    constructor(address _lightClient) {
        lightClient = IEthereumLightClient(_lightClient);
    }

    /// @notice Updates an "anchor block" of a specific block number to the contract state
    function processUpdate(LightClientOptimisticUpdate memory hb) external {
        (uint256 blockNum, bytes32 blockHash) = verifyHeadBlock(hb);
        require(blockHash != bytes32(0), "empty blockHash");
        doUpdate(blockNum, blockHash);
    }

    /// @notice Updates an "anchor block" of a specific block number to the contract state
    /// @dev It is possible that an attested block doesn't collect enough sync committee signatures in its corresponding
    /// signature slot and thus cannot be used in an anchor update. In that case, the updater can pick a later block
    /// that has enough sigs, and supply a chainProof to show that the block they want to sync can chain to the head block.
    function processUpdateWithChainProof(
        LightClientOptimisticUpdate memory hb,
        bytes32 blockHash,
        BlockHashWitness[] memory chainProof
    ) external {
        require(chainProof.length > 0, "invalid proof length");
        (uint256 headBlockNum, bytes32 headBlockHash) = verifyHeadBlock(hb);
        uint256 blockNum = headBlockNum - chainProof.length;
        verifyChainProof(blockHash, chainProof, headBlockHash);
        doUpdate(blockNum, blockHash);
    }

    function verifyHeadBlock(LightClientOptimisticUpdate memory hb) private view returns (uint256, bytes32) {
        require(hasSupermajority(hb.syncAggregate.participation), "quorum not reached");
        verifyExecutionPayload(hb.attestedHeader);
        lightClient.verifyCommitteeSignature(hb.signatureSlot, hb.attestedHeader.beacon, hb.syncAggregate);
        HeaderWithExecution memory h = hb.attestedHeader;
        uint256 blockNum = Helpers.revertEndian(uint256(h.execution.blockNumber.leaf));
        return (blockNum, h.execution.blockHash.leaf);
    }

    function verifyExecutionPayload(HeaderWithExecution memory h) private pure {
        bool valid = Helpers.isValidMerkleBranch(h.executionRoot, EXECUTION_PAYLOAD_ROOT_INDEX, h.beacon.bodyRoot);
        require(valid, "bad exec root proof");
        verifyMerkleProof(h.execution.blockNumber, EXECUTION_BLOCK_NUMBER_LOCAL_INDEX, h.executionRoot.leaf);
        verifyMerkleProof(h.execution.blockHash, EXECUTION_BLOCK_HASH_LOCAL_INDEX, h.executionRoot.leaf);
    }

    function doUpdate(uint256 blockNum, bytes32 blockHash) private {
        require(blocks[blockNum] == bytes32(0), "block hash already exists");
        blocks[blockNum] = blockHash;
        if (blockNum > latestBlockNum) {
            latestBlockNum = blockNum;
        }
        emit AnchorBlockUpdated(blockNum, blockHash);
    }

    function verifyChainProof(
        bytes32 blockHash,
        BlockHashWitness[] memory chainProof,
        bytes32 headBlockHash
    ) private pure {
        bytes32 h = blockHash;
        for (uint256 i = 0; i < chainProof.length; i++) {
            // small hack to save some RLP encoding:
            // We only care about whether the given blockHash can somehow combine with something to hash into headBlockHash.
            // The RLP oding of a block always has 3 bytes for total length prefix and 1 byte (0xa0) for bytes32's length
            // prefix; and the ParentHash field is always the first element. So there are always 8 bytes preceding ParentHash.
            require(chainProof[i].left.length == EXECUTION_BLOCK_LEFT_PREFIX_LEN, "invalid left len");
            h = keccak256(bytes.concat(chainProof[i].left, h, chainProof[i].right));
        }
        require(h == headBlockHash, "invalid chainProof");
    }

    function verifyMerkleProof(LeafWithBranch memory proof, uint256 index, bytes32 root) private pure {
        require(Helpers.isValidMerkleBranch(proof, index, root), "bad proof");
    }

    function hasSupermajority(uint64 participation) private pure returns (bool) {
        return participation * 3 >= SYNC_COMMITTEE_SIZE * 2;
    }

    function setLightClient(address _lightClient) external onlyOwner {
        lightClient = IEthereumLightClient(_lightClient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// light client security params
uint256 constant MIN_SYNC_COMMITTEE_PARTICIPANTS = 1;
uint256 constant UPDATE_TIMEOUT = 86400;

// beacon chain constants
uint256 constant FINALIZED_ROOT_INDEX = 105;
uint256 constant NEXT_SYNC_COMMITTEE_INDEX = 55;
uint256 constant SYNC_COMMITTEE_SIZE = 512;
uint64 constant SLOTS_PER_EPOCH = 32;
uint64 constant EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
bytes32 constant DOMAIN_SYNC_COMMITTEE = bytes32(uint256(0x07) << 248);
uint256 constant SLOT_LENGTH_SECONDS = 12;

// https://github.com/ethereum/consensus-specs/blob/dev/specs/capella/light-client/sync-protocol.md
// beaconBodyRoot -> stateRoot gindex: 2 << 7 | 9 * 2 << 3 | 2
uint256 constant EXECUTION_STATE_ROOT_INDEX = 402;
// beaconBodyRoot -> blockHash gindex: 2 << 7 | 9 * 2 << 3 | 12
uint256 constant EXECUTION_BLOCK_HASH_INDEX = 412;

// the following indices are gindices counting from the executionPayloadRoot
// beaconBodyRoot -> executionPayloadRoot gindex: 2 << 4 | 9
uint256 constant EXECUTION_PAYLOAD_ROOT_INDEX = 25;
// executionPayloadRoot -> stateRoot gindex: 2 << 4 | 2
uint256 constant EXECUTION_STATE_ROOT_LOCAL_INDEX = 18;
// executionPayloadRoot -> blockNumber gindex: 2 << 4 | 6
uint256 constant EXECUTION_BLOCK_NUMBER_LOCAL_INDEX = 22;
// executionPayloadRoot -> blockHash gindex: 2 << 4 | 12
uint256 constant EXECUTION_BLOCK_HASH_LOCAL_INDEX = 28;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Types.sol";

library Helpers {
    function isValidMerkleBranch(LeafWithBranch memory lwb, uint256 index, bytes32 root) internal pure returns (bool) {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(lwb.leaf, lwb.branch, index);
        return root == restoredMerkleRoot;
    }

    function isValidMerkleBranch(
        bytes32 leaf,
        bytes32[] memory branch,
        uint256 index,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, branch, index);
        return root == restoredMerkleRoot;
    }

    function concatMerkleBranches(bytes32[] memory a, bytes32[] memory b) internal pure returns (bytes32[] memory) {
        bytes32[] memory c = new bytes32[](a.length + b.length);
        for (uint256 i = 0; i < a.length + b.length; i++) {
            if (i < a.length) {
                c[i] = a[i];
            } else {
                c[i] = b[i - a.length];
            }
        }
        return c;
    }

    function restoreMerkleRoot(bytes32 leaf, bytes32[] memory branch, uint256 index) internal pure returns (bytes32) {
        bytes32 value = leaf;
        for (uint256 i = 0; i < branch.length; i++) {
            if ((index / (2 ** i)) % 2 == 1) {
                value = sha256(bytes.concat(branch[i], value));
            } else {
                value = sha256(bytes.concat(value, branch[i]));
            }
        }
        return value;
    }

    function hashTreeRoot(BeaconBlockHeader memory header) internal pure returns (bytes32) {
        bytes32 left = sha256(
            bytes.concat(
                sha256(bytes.concat(bytes32(revertEndian(header.slot)), bytes32(revertEndian(header.proposerIndex)))),
                sha256(bytes.concat(header.parentRoot, header.stateRoot))
            )
        );
        bytes32 right = sha256(
            bytes.concat(
                sha256(bytes.concat(header.bodyRoot, bytes32(0))),
                sha256(bytes.concat(bytes32(0), bytes32(0)))
            )
        );
        return sha256(bytes.concat(left, right));
    }

    function revertEndian(uint256 x) internal pure returns (uint256) {
        uint256 res;
        for (uint256 i = 0; i < 32; i++) {
            res = (res << 8) | (x & 0xff);
            x >>= 8;
        }
        return res;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../../verifiers/interfaces/IBeaconVerifier.sol";

struct LightClientOptimisticUpdate {
    // Header attested to by the sync committee
    HeaderWithExecution attestedHeader;
    // Sync committee aggregate signature participation & zk proof
    SyncAggregate syncAggregate;
    // Slot at which the aggregate signature was created (untrusted)
    uint64 signatureSlot;
}

struct LightClientUpdate {
    // Header attested to by the sync committee
    HeaderWithExecution attestedHeader;
    HeaderWithExecution finalizedHeader;
    // merkle branch from finalized beacon header root to attestedHeader.stateRoot
    bytes32[] finalityBranch;
    bytes32 nextSyncCommitteeRoot;
    bytes32[] nextSyncCommitteeBranch;
    bytes32 nextSyncCommitteePoseidonRoot;
    IBeaconVerifier.Proof nextSyncCommitteeRootMappingProof;
    // Sync committee aggregate signature participation & zk proof
    SyncAggregate syncAggregate;
    // Slot at which the aggregate signature was created (untrusted)
    uint64 signatureSlot;
}

struct HeaderWithExecution {
    BeaconBlockHeader beacon;
    ExecutionPayload execution;
    // merkle branch from execution payload root to beacon block root
    LeafWithBranch executionRoot;
}

function isEmpty(HeaderWithExecution memory header) pure returns (bool) {
    return header.beacon.stateRoot == bytes32(0);
}

// only contains the fields we care about in execution payload
struct ExecutionPayload {
    // merkle branch from execution state root to execution payload root
    LeafWithBranch stateRoot;
    // merkle branch from execution block hash to execution payload root
    LeafWithBranch blockHash;
    // merkle branch from execution block number to execution payload root
    LeafWithBranch blockNumber;
}

function isEmpty(ExecutionPayload memory payload) pure returns (bool) {
    return
        payload.stateRoot.leaf == bytes32(0) &&
        payload.blockHash.leaf == bytes32(0) &&
        payload.blockNumber.leaf == bytes32(0);
}

struct LeafWithBranch {
    bytes32 leaf;
    bytes32[] branch;
}

struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}

struct SyncAggregate {
    uint64 participation;
    bytes32 poseidonRoot;
    uint256 commitment;
    IBeaconVerifier.Proof proof;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IAnchorBlocks {
    function blocks(uint256 blockNum) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../common/Types.sol";

interface IEthereumLightClient {
    function optimisticExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot);

    function finalizedExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot);

    // reverts if check fails
    function verifyCommitteeSignature(
        uint64 signatureSlot,
        BeaconBlockHeader memory header,
        SyncAggregate memory syncAggregate
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IBeaconVerifier {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[2] commitment;
    }

    function verifySignatureProof(
        bytes32 signingRoot,
        bytes32 syncCommitteePoseidonRoot,
        uint256 participation,
        uint256 commitment,
        Proof memory p
    ) external view returns (bool);

    function verifySyncCommitteeRootMappingProof(
        bytes32 sszRoot,
        bytes32 poseidonRoot,
        Proof memory p
    ) external view returns (bool);
}