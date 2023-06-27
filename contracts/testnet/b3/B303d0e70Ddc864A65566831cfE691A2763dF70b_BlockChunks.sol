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
import "./interfaces/IBlockChunks.sol";
import "../verifiers/interfaces/IZkpVerifier.sol";
import "../light-client/interfaces/IAnchorBlocks.sol";

uint8 constant TREE_DEPTH = 7;
uint32 constant NUM_LEAVES = 2 ** 7;

// array indices for reading from the ZKP calldata
uint32 constant PUBLIC_BYTES_START_IDX = 10 * 32; // the first 10 32bytes are groth16 proof (A/B/C/Commitment)

contract BlockChunks is IBlockChunks, Ownable {
    mapping(uint64 => address) public verifierAddresses; // chainid => snark verifier contract address
    mapping(uint64 => address) public anchorBlockProviders; // chainid => anchorBlockProvider

    // historicalRoots[chainId][startBlockNumber] is 0 unless (startBlockNumber % NUM_LEAVES == 0)
    // historicalRoots[chainId][startBlockNumber] holds the hash of
    //   prevHash || root || numFinal
    // where
    // - prevHash is the parent hash of block startBlockNumber
    // - root is the partial Merkle root of blockhashes of block numbers
    //   [startBlockNumber, startBlockNumber + NUM_LEAVES)
    //   where unconfirmed block hashes are 0's
    // - numFinal is the number of confirmed consecutive roots in [startBlockNumber, startBlockNumber + NUM_LEAVES)
    mapping(uint64 => mapping(uint32 => bytes32)) internal _historicalRoots; // chainid => (startBlockNumber => root)

    event UpdateVerifierAddress(uint64 chainId, address newAddress);
    event UpdateAnchorBlockProvider(uint64 chainId, address newAddress);

    function updateVerifierAddress(uint64 _chainId, address _verifierAddress) external onlyOwner {
        verifierAddresses[_chainId] = _verifierAddress;
        emit UpdateVerifierAddress(_chainId, _verifierAddress);
    }

    function updateAnchorBlockProvider(uint64 _chainId, address _provider) external onlyOwner {
        anchorBlockProviders[_chainId] = _provider;
        emit UpdateAnchorBlockProvider(_chainId, _provider);
    }

    function verifyRaw(uint64 chainId, bytes calldata proofData) private view returns (bool) {
        require(verifierAddresses[chainId] != address(0), "chain verifier not set");
        return (IZkpVerifier)(verifierAddresses[chainId]).verifyRaw(proofData);
    }

    function historicalRoots(uint64 chainId, uint32 startBlockNumber) public view returns (bytes32) {
        return _historicalRoots[chainId][startBlockNumber];
    }

    // after the groth16 proof are the public fields chunkRoot, prevHash, endHash (each in two uint128 represented in 256 bits), startBlockNum, endBlockNum
    function getBoundaryBlockData(
        bytes calldata proofData
    )
        internal
        pure
        returns (bytes32 chunkRoot, bytes32 prevHash, bytes32 endHash, uint32 startBlockNum, uint32 endBlockNum)
    {
        chunkRoot = bytes32(
            (uint256(bytes32(proofData[PUBLIC_BYTES_START_IDX:PUBLIC_BYTES_START_IDX + 32])) << 128) |
                uint128(bytes16(proofData[PUBLIC_BYTES_START_IDX + 32 + 16:PUBLIC_BYTES_START_IDX + 2 * 32]))
        );
        prevHash = bytes32(
            (uint256(bytes32(proofData[PUBLIC_BYTES_START_IDX + 2 * 32:PUBLIC_BYTES_START_IDX + 3 * 32])) << 128) |
                uint128(bytes16(proofData[PUBLIC_BYTES_START_IDX + 3 * 32 + 16:PUBLIC_BYTES_START_IDX + 4 * 32]))
        );
        endHash = bytes32(
            (uint256(bytes32(proofData[PUBLIC_BYTES_START_IDX + 4 * 32:PUBLIC_BYTES_START_IDX + 5 * 32])) << 128) |
                uint128(bytes16(proofData[PUBLIC_BYTES_START_IDX + 5 * 32 + 16:PUBLIC_BYTES_START_IDX + 6 * 32]))
        );
        startBlockNum = uint32(bytes4(proofData[PUBLIC_BYTES_START_IDX + 7 * 32 - 4:PUBLIC_BYTES_START_IDX + 7 * 32]));
        endBlockNum = uint32(bytes4(proofData[PUBLIC_BYTES_START_IDX + 8 * 32 - 4:PUBLIC_BYTES_START_IDX + 8 * 32]));
    }

    // update blocks in the "backward" direction, anchoring on a "recent" end blockhash from anchor contract
    // * startBlockNumber must be a multiple of NUM_LEAVES
    // * for now always endBlockNumber = startBlockNumber + NUM_LEAVES - 1 (full update on every NUM_LEAVES blocks chunk)
    function updateRecent(uint64 chainId, bytes calldata proofData) external {
        (
            bytes32 chunkRoot,
            bytes32 prevHash,
            bytes32 endHash,
            uint32 startBlockNum,
            uint32 endBlockNum
        ) = getBoundaryBlockData(proofData);

        require(endBlockNum == startBlockNum + NUM_LEAVES - 1, "need 128 blks");
        require(startBlockNum % NUM_LEAVES == 0, "need start from 128x");

        require(anchorBlockProviders[chainId] != address(0), "chain anchor provider not set");
        require(IAnchorBlocks(anchorBlockProviders[chainId]).blocks(endBlockNum) == endHash, "endHash not correct");

        require(verifyRaw(chainId, proofData), "proof not valid");

        _historicalRoots[chainId][startBlockNum] = keccak256(abi.encodePacked(prevHash, chunkRoot, NUM_LEAVES));
        emit UpdateEvent(chainId, startBlockNum, prevHash, chunkRoot, NUM_LEAVES);
    }

    // update older blocks in "backwards" direction, anchoring on more recent trusted blockhash
    // must be batch of NUM_LEAVES blocks
    function updateOld(uint64 chainId, bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external {
        (
            bytes32 chunkRoot,
            bytes32 prevHash,
            bytes32 endHash,
            uint32 startBlockNum,
            uint32 endBlockNum
        ) = getBoundaryBlockData(proofData);

        require(startBlockNum % NUM_LEAVES == 0, "need start from 128x");
        require(endBlockNum - startBlockNum == NUM_LEAVES - 1, "need 128 blks");

        require(
            historicalRoots(chainId, endBlockNum + 1) == keccak256(abi.encodePacked(endHash, nextRoot, nextNumFinal)),
            "endHash not correct"
        );
        require(verifyRaw(chainId, proofData), "proof not valid");

        _historicalRoots[chainId][startBlockNum] = keccak256(abi.encodePacked(prevHash, chunkRoot, NUM_LEAVES));
        emit UpdateEvent(chainId, startBlockNum, prevHash, chunkRoot, NUM_LEAVES);
    }

    function isBlockHashValid(BlockHashWitness calldata witness) public view returns (bool) {
        require(witness.claimedBlkHash != 0x0, "claimedBlkHash not present"); // "Claimed block hash cannot be 0"
        uint32 side = witness.blkNum % NUM_LEAVES;
        uint32 startBlockNumber = witness.blkNum - side;
        bytes32 merkleRoot = historicalRoots(witness.chainId, startBlockNumber);
        require(merkleRoot != 0, "blk history not stored yet"); // "Merkle root must be stored already"
        // compute Merkle root of blockhash
        bytes32 root = witness.claimedBlkHash;
        for (uint8 depth = 0; depth < TREE_DEPTH; depth++) {
            // 0 for left, 1 for right
            if ((side >> depth) & 1 == 0) {
                root = keccak256(abi.encodePacked(root, witness.merkleProof[depth]));
            } else {
                root = keccak256(abi.encodePacked(witness.merkleProof[depth], root));
            }
        }
        return (merkleRoot == keccak256(abi.encodePacked(witness.prevHash, root, witness.numFinal)));
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

interface IAnchorBlocks {
    function blocks(uint256 blockNum) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IZkpVerifier {
    function verifyRaw(bytes calldata proofData) external view returns (bool r);
}