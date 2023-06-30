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

interface IBlockChunks {
    // historicalRoots(chainId, startBlockNumber) is 0 unless (startBlockNumber % 128 == 0)
    // historicalRoots(chainId, startBlockNumber) holds the hash of
    //   prevHash || root || numFinal
    // where
    // - prevHash is the parent hash of block startBlockNumber
    // - root is the partial Merkle root of blockhashes of block numbers
    //   [startBlockNumber, startBlockNumber + 128)
    //   where unconfirmed block hashes are 0's
    // - numFinal is the number of confirmed consecutive roots in [startBlockNumber, startBlockNumber + 128)
    function historicalRoots(uint64 chainId, uint32 startBlockNumber) external view returns (bytes32);

    event UpdateEvent(uint64 chainId, uint32 startBlockNumber, bytes32 prevHash, bytes32 root, uint32 numFinal);

    struct BlockHashWitness {
        uint64 chainId;
        uint32 blkNum;
        bytes32 claimedBlkHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[7] merkleProof;
    }

    // update blocks in the "backward" direction, anchoring on a "recent" end blockhash from anchor contract
    // * startBlockNumber must be a multiple of 128
    // * for now always endBlockNumber = startBlockNumber + 127 (full update on every 128 blocks chunk)
    function updateRecent(uint64 chainId, bytes calldata proofData) external;

    // update older blocks in "backwards" direction, anchoring on more recent trusted blockhash
    // must be batch of 128 blocks
    function updateOld(uint64 chainId, bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external;

    function isBlockHashValid(BlockHashWitness calldata witness) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISlotValueVerifier {
    struct SlotInfo {
        uint64 chainId;
        bytes32 addrHash;
        bytes32 blkHash;
        bytes32 slotKey;
        bytes32 slotValue;
        uint32 blkNum;
    }

    function verifySlotValue(
        uint64 chainId,
        bytes calldata proofData,
        bytes calldata blkVerifyInfo
    ) external view returns (SlotInfo memory slotInfo);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IZkpVerifier {
    function verifyRaw(bytes calldata proofData) external view returns (bool r);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISlotValueVerifier.sol";
import "./interfaces/IZkpVerifier.sol";
import "../chunk-sync/interfaces/IBlockChunks.sol";

contract SlotValueVerifier is ISlotValueVerifier, Ownable {
    uint32 constant PUBLIC_BYTES_START_IDX = 10 * 32;

    // retrieved from proofData, to align the fields with circuit...
    struct ProofData {
        bytes32 blkHash;
        bytes32 addrHash;
        bytes32 slotKey;
        bytes32 slotValue;
        uint32 blkNum;
    }

    mapping(uint64 => address) public verifierAddresses; // chainid => snark verifier contract address
    address public BlockChunks;

    event UpdateVerifierAddress(uint64 chainId, address newAddress);
    event UpdateBlockChunks(address newAddress);

    constructor(address _blocChunks) {
        BlockChunks = _blocChunks;
    }

    function updateVerifierAddress(uint64 _chainId, address _verifierAddress) external onlyOwner {
        verifierAddresses[_chainId] = _verifierAddress;
        emit UpdateVerifierAddress(_chainId, _verifierAddress);
    }

    function updateBlockChunks(address _BlockChunks) external onlyOwner {
        BlockChunks = _BlockChunks;
        emit UpdateBlockChunks(_BlockChunks);
    }

    function verifySlotValue(
        uint64 chainId,
        bytes calldata proofData,
        bytes calldata blkVerifyInfo
    ) external view returns (SlotInfo memory slotInfo) {
        require(verifyRaw(chainId, proofData));

        (bytes32 prevHash, uint32 numFinal, bytes32[7] memory merkleProof) = getFromBlkVerifyInfo(blkVerifyInfo);
        ProofData memory data = getProofData(proofData);

        IBlockChunks.BlockHashWitness memory witness = IBlockChunks.BlockHashWitness({
            chainId: chainId,
            blkNum: data.blkNum,
            claimedBlkHash: data.blkHash,
            prevHash: prevHash,
            numFinal: numFinal,
            merkleProof: merkleProof
        });
        require(IBlockChunks(BlockChunks).isBlockHashValid(witness), "invalid blkHash");

        slotInfo.chainId = chainId;
        slotInfo.blkHash = data.blkHash;
        slotInfo.addrHash = data.addrHash;
        slotInfo.blkNum = data.blkNum;
        slotInfo.slotKey = data.slotKey;
        slotInfo.slotValue = data.slotValue;
    }

    function verifyRaw(uint64 chainId, bytes calldata proofData) private view returns (bool) {
        require(verifierAddresses[chainId] != address(0), "chain verifier not set");
        return (IZkpVerifier)(verifierAddresses[chainId]).verifyRaw(proofData);
    }

    function getFromBlkVerifyInfo(
        bytes calldata blkVerifyInfo
    ) internal pure returns (bytes32 prevHash, uint32 numFinal, bytes32[7] memory merkleProof) {
        require(blkVerifyInfo.length == 8 * 32 + 4, "incorrect blkVerifyInfo");
        prevHash = bytes32(blkVerifyInfo[:32]);
        numFinal = uint32(bytes4(blkVerifyInfo[32:36]));

        for (uint8 idx = 0; idx < 6; idx++) {
            merkleProof[idx] = bytes32(blkVerifyInfo[36 + 32 * idx:36 + 32 * (idx + 1)]);
        }

        merkleProof[6] = bytes32(blkVerifyInfo[36 + 32 * 6:36 + 32 * (6 + 1)]);
    }

    // groth16 proof + public inputs
    // public inputs:
    //  block hash
    //  contractAddrHash
    //  slot key
    //  slot value
    //  block number
    function getProofData(bytes calldata proofData) internal pure returns (ProofData memory data) {
        data.blkHash = bytes32(
            (uint256(bytes32(proofData[PUBLIC_BYTES_START_IDX:PUBLIC_BYTES_START_IDX + 32])) << 128) |
                uint128(bytes16(proofData[PUBLIC_BYTES_START_IDX + 32 + 16:PUBLIC_BYTES_START_IDX + 2 * 32]))
        );
        data.addrHash = bytes32(
            (uint256(bytes32(proofData[PUBLIC_BYTES_START_IDX + 2 * 32:PUBLIC_BYTES_START_IDX + 3 * 32])) << 128) |
                uint128(bytes16(proofData[PUBLIC_BYTES_START_IDX + 3 * 32 + 16:PUBLIC_BYTES_START_IDX + 4 * 32]))
        );
        data.slotKey = bytes32(
            (uint256(bytes32(proofData[PUBLIC_BYTES_START_IDX + 4 * 32:PUBLIC_BYTES_START_IDX + 5 * 32])) << 128) |
                uint128(bytes16(proofData[PUBLIC_BYTES_START_IDX + 5 * 32 + 16:PUBLIC_BYTES_START_IDX + 6 * 32]))
        );
        data.slotValue = bytes32(
            (uint256(bytes32(proofData[PUBLIC_BYTES_START_IDX + 6 * 32:PUBLIC_BYTES_START_IDX + 7 * 32])) << 128) |
                uint128(bytes16(proofData[PUBLIC_BYTES_START_IDX + 7 * 32 + 16:PUBLIC_BYTES_START_IDX + 8 * 32]))
        );
        data.blkNum = uint32(bytes4(proofData[PUBLIC_BYTES_START_IDX + 9 * 32 - 4:PUBLIC_BYTES_START_IDX + 9 * 32]));
    }
}