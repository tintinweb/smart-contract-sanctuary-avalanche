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

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IEthereumLightClient.sol";
import "./LightClientStore.sol";
import "./common/Helpers.sol";
import "./common/Constants.sol";
import "./common/Types.sol";

contract EthereumLightClient is IEthereumLightClient, LightClientStore, Ownable {
    event OptimisticUpdate(uint256 slot, bytes32 executionStateRoot);
    event FinalityUpdate(uint256 slot, bytes32 executionStateRoot);
    event SyncCommitteeUpdated(uint256 period, bytes32 sszRoot, bytes32 poseidonRoot);
    event ForkVersionUpdated(uint64 epoch, bytes4 forkVersion);

    constructor(
        uint256 genesisTime,
        bytes32 genesisValidatorsRoot,
        uint64[] memory _forkEpochs,
        bytes4[] memory _forkVersions,
        uint64 _finalizedSlot,
        bytes32 syncCommitteeRoot,
        bytes32 syncCommitteePoseidonRoot,
        address _zkVerifier
    )
        LightClientStore(
            genesisTime,
            genesisValidatorsRoot,
            _forkEpochs,
            _forkVersions,
            _finalizedSlot,
            syncCommitteeRoot,
            syncCommitteePoseidonRoot,
            _zkVerifier
        )
    {}

    function latestFinalizedSlotAndCommitteeRoots()
        external
        view
        returns (uint64 slot, bytes32 currentRoot, bytes32 nextRoot)
    {
        return (finalizedSlot, currentSyncCommitteeRoot, nextSyncCommitteeRoot);
    }

    function optimisticExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot) {
        return (optimisticExecutionStateRoot, optimisticSlot);
    }

    function finalizedExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot) {
        return (finalizedExecutionStateRoot, finalizedSlot);
    }

    function updateForkVersion(uint64 epoch, bytes4 forkVersion) external onlyOwner {
        require(forkVersion != bytes4(0), "bad fork version");
        forkEpochs.push(epoch);
        forkVersions.push(forkVersion);
        emit ForkVersionUpdated(epoch, forkVersion);
    }

    function processLightClientForceUpdate() external onlyOwner {
        require(currentSlot() > finalizedSlot + UPDATE_TIMEOUT, "timeout not passed");
        require(bestValidUpdate.attestedHeader.beacon.slot > 0, "no best valid update");

        // Forced best update when the update timeout has elapsed.
        // Because the apply logic waits for finalizedHeader.beacon.slot to indicate sync committee fin,
        // the attestedHeader may be treated as finalizedHeader in extended periods of non-fin
        // to guarantee progression into later sync committee periods according to isBetterUpdate().
        if (bestValidUpdate.finalizedHeader.beacon.slot <= finalizedSlot) {
            bestValidUpdate.finalizedHeader = bestValidUpdate.attestedHeader;
        }
        applyFinalityUpdate(bestValidUpdate);
        delete bestValidUpdate;
    }

    function processLightClientUpdate(LightClientUpdate memory update) public {
        bool quorumReached = hasSupermajority(update.syncAggregate.participation);
        bool betterUpdate = isBetterUpdate(update, bestValidUpdate);
        require(betterUpdate || quorumReached, "quorum not reached");
        validateLightClientUpdate(update);

        // Update the best update in case we have to force-update to it if the timeout elapses
        if (betterUpdate) {
            bestValidUpdate = update;
        }
        // Apply optimistic update
        if (quorumReached && update.attestedHeader.beacon.slot > optimisticSlot) {
            applyOptimisticUpdate(update);
        }
        // Apply finality update
        if (
            quorumReached &&
            (update.finalizedHeader.beacon.slot > finalizedSlot ||
                (hasNextSyncCommittee(update) && nextSyncCommitteeRoot == bytes32(0)))
        ) {
            applyFinalityUpdate(update);
            delete bestValidUpdate;
        }
    }

    function validateLightClientUpdate(LightClientUpdate memory update) private view {
        // Verify sync committee has sufficient participants
        require(update.syncAggregate.participation > MIN_SYNC_COMMITTEE_PARTICIPANTS, "not enough participation");
        // Verify update does not skip a sync committee period
        require(
            currentSlot() > update.attestedHeader.beacon.slot &&
                update.attestedHeader.beacon.slot > update.finalizedHeader.beacon.slot,
            "bad slot"
        );
        uint64 storePeriod = computeSyncCommitteePeriodAtSlot(finalizedSlot);

        // Verify update is relavant
        uint64 updateAttestedPeriod = computeSyncCommitteePeriodAtSlot(update.attestedHeader.beacon.slot);
        bool updateHasNextSyncCommittee = nextSyncCommitteeRoot == bytes32(0) &&
            hasNextSyncCommitteeProof(update) &&
            updateAttestedPeriod == storePeriod;
        // Since sync committee update prefers older header (see isBetterUpdate), an update either
        // needs to have a newer header or it should have sync committee update.
        require(
            update.attestedHeader.beacon.slot > finalizedSlot || updateHasNextSyncCommittee,
            "bad att slot or committee"
        );

        // Verify that the finalityBranch, if present, confirms finalizedHeader
        // to match the finalized checkpoint root saved in the state of attestedHeader.
        // Note that the genesis finalized checkpoint root is represented as a zero hash.
        if (!hasFinalityProof(update)) {
            require(isEmpty(update.finalizedHeader), "no fin proof");
        } else {
            // genesis block header
            if (update.finalizedHeader.beacon.slot == 0) {
                require(isEmpty(update.finalizedHeader), "genesis header should be empty");
            } else {
                bool isValidFinalityProof = Helpers.isValidMerkleBranch(
                    Helpers.hashTreeRoot(update.finalizedHeader.beacon),
                    update.finalityBranch,
                    FINALIZED_ROOT_INDEX,
                    update.attestedHeader.beacon.stateRoot
                );
                require(isValidFinalityProof, "bad fin proof");
                verifyExecutionPayload(update.finalizedHeader, "finalized");
            }
        }

        // Verify that the update's nextSyncCommittee, if present, actually is the next sync committee
        // saved in the state of the update's attested header
        if (!hasNextSyncCommitteeProof(update)) {
            require(
                update.nextSyncCommitteeRoot == bytes32(0) && update.nextSyncCommitteePoseidonRoot == bytes32(0),
                "no next sync committee proof"
            );
        } else {
            if (updateAttestedPeriod == storePeriod && nextSyncCommitteeRoot != bytes32(0)) {
                require(update.nextSyncCommitteeRoot == nextSyncCommitteeRoot, "bad next sync committee");
            }
            bool validSyncCommitteeProof = Helpers.isValidMerkleBranch(
                update.nextSyncCommitteeRoot,
                update.nextSyncCommitteeBranch,
                NEXT_SYNC_COMMITTEE_INDEX,
                update.attestedHeader.beacon.stateRoot
            );
            require(validSyncCommitteeProof, "bad next sync committee proof");
            bool validCommitteeRootMappingProof = zkVerifier.verifySyncCommitteeRootMappingProof(
                update.nextSyncCommitteeRoot,
                update.nextSyncCommitteePoseidonRoot,
                update.nextSyncCommitteeRootMappingProof
            );
            require(validCommitteeRootMappingProof, "bad next sync committee root mapping proof");
        }

        // Verify optimistic execution payload
        verifyExecutionPayload(update.attestedHeader, "optimistic");

        // Verify sync committee signature ZK proof
        verifyCommitteeSignature(update.signatureSlot, update.attestedHeader.beacon, update.syncAggregate);
    }

    function verifyCommitteeSignature(
        uint64 signatureSlot,
        BeaconBlockHeader memory header,
        SyncAggregate memory syncAggregate
    ) public view {
        uint64 storePeriod = computeSyncCommitteePeriodAtSlot(finalizedSlot);
        uint64 updateSigPeriod = computeSyncCommitteePeriodAtSlot(signatureSlot);
        if (nextSyncCommitteeRoot != bytes32(0)) {
            require(updateSigPeriod == storePeriod || updateSigPeriod == storePeriod + 1, "bad sig period 2");
        } else {
            require(updateSigPeriod == storePeriod, "bad sig period 1");
        }

        bytes4 forkVersion = computeForkVersion(computeEpochAtSlot(signatureSlot));
        bytes32 domain = computeDomain(forkVersion);
        bytes32 signingRoot = computeSigningRoot(header, domain);
        bytes32 activeSyncCommitteePoseidonRoot;
        if (updateSigPeriod == storePeriod) {
            require(currentSyncCommitteePoseidonRoot == syncAggregate.poseidonRoot, "bad poseidon root");
            activeSyncCommitteePoseidonRoot = currentSyncCommitteePoseidonRoot;
        } else {
            require(nextSyncCommitteePoseidonRoot == syncAggregate.poseidonRoot, "bad poseidon root");
            activeSyncCommitteePoseidonRoot = nextSyncCommitteePoseidonRoot;
        }
        require(
            zkVerifier.verifySignatureProof(
                signingRoot,
                activeSyncCommitteePoseidonRoot,
                syncAggregate.participation,
                syncAggregate.commitment,
                syncAggregate.proof
            ),
            "bad bls sig proof"
        );
    }

    function verifyExecutionPayload(HeaderWithExecution memory h, string memory name) private pure {
        ExecutionPayload memory exec = h.execution;
        bool valid = Helpers.isValidMerkleBranch(h.executionRoot, EXECUTION_PAYLOAD_ROOT_INDEX, h.beacon.bodyRoot);
        require(valid, string.concat("bad exec root proof ", name));
        valid = Helpers.isValidMerkleBranch(exec.stateRoot, EXECUTION_STATE_ROOT_LOCAL_INDEX, h.executionRoot.leaf);
        require(valid, string.concat("bad exec state root proof ", name));
    }

    function applyOptimisticUpdate(LightClientUpdate memory update) private {
        HeaderWithExecution memory h = update.attestedHeader;
        bytes32 stateRoot = h.execution.stateRoot.leaf;
        optimisticExecutionStateRoot = stateRoot;
        optimisticSlot = h.beacon.slot;
        emit OptimisticUpdate(h.beacon.slot, stateRoot);
    }

    function applyFinalityUpdate(LightClientUpdate memory update) private {
        uint64 updateSlot = update.finalizedHeader.beacon.slot;
        uint64 storePeriod = computeSyncCommitteePeriodAtSlot(finalizedSlot);
        uint64 updateFinalizedPeriod = computeSyncCommitteePeriodAtSlot(updateSlot);
        if (nextSyncCommitteeRoot == bytes32(0)) {
            require(updateFinalizedPeriod == storePeriod, "mismatch period");
            nextSyncCommitteeRoot = update.nextSyncCommitteeRoot;
            nextSyncCommitteePoseidonRoot = update.nextSyncCommitteePoseidonRoot;
            emit SyncCommitteeUpdated(updateFinalizedPeriod + 1, nextSyncCommitteeRoot, nextSyncCommitteePoseidonRoot);
        } else if (updateFinalizedPeriod == storePeriod + 1) {
            currentSyncCommitteeRoot = nextSyncCommitteeRoot;
            currentSyncCommitteePoseidonRoot = nextSyncCommitteePoseidonRoot;
            nextSyncCommitteeRoot = update.nextSyncCommitteeRoot;
            nextSyncCommitteePoseidonRoot = update.nextSyncCommitteePoseidonRoot;
            emit SyncCommitteeUpdated(updateFinalizedPeriod + 1, nextSyncCommitteeRoot, nextSyncCommitteePoseidonRoot);
        }
        bytes32 updateExecStateRoot = update.finalizedHeader.execution.stateRoot.leaf;
        if (updateSlot > finalizedSlot) {
            finalizedExecutionStateRoot = updateExecStateRoot;
            finalizedSlot = updateSlot;
            emit FinalityUpdate(updateSlot, updateExecStateRoot);
            return;
        }
    }

    /*
     * https://github.com/ethereum/consensus-specs/blob/dev/specs/altair/light-client/sync-protocol.md#is_better_update
     */
    function isBetterUpdate(
        LightClientUpdate memory newUpdate,
        LightClientUpdate memory oldUpdate
    ) private pure returns (bool) {
        // Old update doesn't exist
        if (oldUpdate.syncAggregate.participation == 0) {
            return newUpdate.syncAggregate.participation > 0;
        }

        // Compare supermajority (> 2/3) sync committee participation
        bool newHasSupermajority = hasSupermajority(newUpdate.syncAggregate.participation);
        bool oldHasSupermajority = hasSupermajority(oldUpdate.syncAggregate.participation);
        if (newHasSupermajority != oldHasSupermajority) {
            // the new update is a better one if new has supermajority but old doesn't
            return newHasSupermajority && !oldHasSupermajority;
        }
        if (!newHasSupermajority && newUpdate.syncAggregate.participation != oldUpdate.syncAggregate.participation) {
            // a better update is the one with higher participation when both new and old doesn't have supermajority
            return newUpdate.syncAggregate.participation > oldUpdate.syncAggregate.participation;
        }

        // Compare presence of relevant sync committee
        bool newHasSyncCommittee = hasRelavantSyncCommittee(newUpdate);
        bool oldHasSyncCommittee = hasRelavantSyncCommittee(oldUpdate);
        if (newHasSyncCommittee != oldHasSyncCommittee) {
            return newHasSyncCommittee;
        }

        // Compare indication of any fin
        bool newHasFinality = hasFinalityProof(newUpdate);
        bool oldHasFinality = hasFinalityProof(oldUpdate);
        if (newHasFinality != oldHasFinality) {
            return newHasFinality;
        }

        // Compare sync committee fin
        if (newHasFinality) {
            bool newHasCommitteeFinality = computeSyncCommitteePeriodAtSlot(newUpdate.finalizedHeader.beacon.slot) ==
                computeSyncCommitteePeriodAtSlot(newUpdate.attestedHeader.beacon.slot);
            bool oldHasCommitteeFinality = computeSyncCommitteePeriodAtSlot(oldUpdate.finalizedHeader.beacon.slot) ==
                computeSyncCommitteePeriodAtSlot(oldUpdate.attestedHeader.beacon.slot);
            if (newHasCommitteeFinality != oldHasCommitteeFinality) {
                return newHasCommitteeFinality;
            }
        }

        // Tiebreaker 1: Sync committee participation beyond supermajority
        if (newUpdate.syncAggregate.participation != oldUpdate.syncAggregate.participation) {
            return newUpdate.syncAggregate.participation > oldUpdate.syncAggregate.participation;
        }

        // Tiebreaker 2: Prefer older data (fewer changes to best)
        if (newUpdate.attestedHeader.beacon.slot != oldUpdate.attestedHeader.beacon.slot) {
            return newUpdate.attestedHeader.beacon.slot < oldUpdate.attestedHeader.beacon.slot;
        }

        return newUpdate.signatureSlot < oldUpdate.signatureSlot;
    }

    function hasRelavantSyncCommittee(LightClientUpdate memory update) private pure returns (bool) {
        return
            hasNextSyncCommitteeProof(update) &&
            computeSyncCommitteePeriodAtSlot(update.attestedHeader.beacon.slot) ==
            computeSyncCommitteePeriodAtSlot(update.signatureSlot);
    }

    function hasNextSyncCommitteeProof(LightClientUpdate memory update) private pure returns (bool) {
        return update.nextSyncCommitteeBranch.length > 0;
    }

    function hasNextSyncCommittee(LightClientUpdate memory update) private pure returns (bool) {
        return
            hasNextSyncCommitteeProof(update) &&
            hasFinalityProof(update) &&
            computeSyncCommitteePeriodAtSlot(update.finalizedHeader.beacon.slot) ==
            computeSyncCommitteePeriodAtSlot(update.attestedHeader.beacon.slot);
    }

    function hasFinalityProof(LightClientUpdate memory update) private pure returns (bool) {
        return update.finalityBranch.length > 0;
    }

    function hasSupermajority(uint64 participation) private pure returns (bool) {
        return participation * 3 >= SYNC_COMMITTEE_SIZE * 2;
    }

    function currentSlot() private view returns (uint64) {
        return uint64((block.timestamp - GENESIS_TIME) / SLOT_LENGTH_SECONDS);
    }

    function computeForkVersion(uint64 epoch) private view returns (bytes4) {
        for (uint256 i = forkVersions.length - 1; i >= 0; i--) {
            if (epoch >= forkEpochs[i]) {
                return forkVersions[i];
            }
        }
        revert("fork versions not set");
    }

    function computeSyncCommitteePeriodAtSlot(uint64 slot) private pure returns (uint64) {
        return computeSyncCommitteePeriod(computeEpochAtSlot(slot));
    }

    function computeEpochAtSlot(uint64 slot) private pure returns (uint64) {
        return slot / SLOTS_PER_EPOCH;
    }

    function computeSyncCommitteePeriod(uint64 epoch) private pure returns (uint64) {
        return epoch / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
    }

    /**
     * https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#compute_domain
     */
    function computeDomain(bytes4 forkVersion) public view returns (bytes32) {
        return DOMAIN_SYNC_COMMITTEE | (sha256(abi.encode(forkVersion, GENESIS_VALIDATOR_ROOT)) >> 32);
    }

    // computeDomain(forkVersion, genesisValidatorsRoot)
    function computeSigningRoot(BeaconBlockHeader memory header, bytes32 domain) public pure returns (bytes32) {
        return sha256(bytes.concat(Helpers.hashTreeRoot(header), domain));
    }
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

import "./common/Types.sol";
import "../verifiers/interfaces/IBeaconVerifier.sol";

abstract contract LightClientStore {
    // beacon chain genesis information
    uint256 immutable GENESIS_TIME;
    bytes32 immutable GENESIS_VALIDATOR_ROOT;

    uint64 public finalizedSlot;
    bytes32 public finalizedExecutionStateRoot;

    uint64 public optimisticSlot;
    bytes32 public optimisticExecutionStateRoot;

    bytes32 public currentSyncCommitteeRoot;
    bytes32 public currentSyncCommitteePoseidonRoot;
    bytes32 public nextSyncCommitteeRoot;
    bytes32 public nextSyncCommitteePoseidonRoot;

    LightClientUpdate public bestValidUpdate;

    // fork versions
    uint64[] public forkEpochs;
    bytes4[] public forkVersions;

    // zk verifier
    IBeaconVerifier public zkVerifier; // contract too big. need to move this one out

    constructor(
        uint256 genesisTime,
        bytes32 genesisValidatorsRoot,
        uint64[] memory _forkEpochs,
        bytes4[] memory _forkVersions,
        uint64 _finalizedSlot,
        bytes32 syncCommitteeRoot,
        bytes32 syncCommitteePoseidonRoot,
        address _zkVerifier
    ) {
        GENESIS_TIME = genesisTime;
        GENESIS_VALIDATOR_ROOT = genesisValidatorsRoot;
        forkEpochs = _forkEpochs;
        forkVersions = _forkVersions;
        finalizedSlot = _finalizedSlot;
        currentSyncCommitteeRoot = syncCommitteeRoot;
        currentSyncCommitteePoseidonRoot = syncCommitteePoseidonRoot;
        zkVerifier = IBeaconVerifier(_zkVerifier);
    }
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