// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller"s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

// MerkleDistributor for distributing SDT
contract FeeDistributor {
    bytes32[] public merkleRoots;
    uint256 public lastRoot;

    address public token;

    address public authority;

    event Claimed(
        uint256 merkleIndex,
        uint256 index,
        address account,
        uint256 amount
    );

    bool public isPaused;

    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMap;

    constructor(address _authority, address _token) {
        authority = _authority;
        isPaused = true;
        token = _token;
    }

    function getIndex() public view returns (uint256){
        return merkleRoots.length - 1;
    }

    function setAuthority(address _account) public {
        require(msg.sender == authority, "Not authorized.");
        authority = _account;
    }

    function pause() public {
        require(msg.sender == authority, "Not authorized.");
        require(!isPaused, "Distributor already paused.");
        isPaused = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public {
        require(msg.sender == authority, "Not authorized.");
        require(isPaused, "Distributor must be paused.");
        require(_merkleRoot != 0x00, "Merkle root is null.");
        merkleRoots.push(_merkleRoot);
        isPaused = false;
    }

    function isClaimed(uint256 merkleIndex, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 merkleIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[merkleIndex][claimedWordIndex] =
            claimedBitMap[merkleIndex][claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external {
        require(!isPaused, "Cannot claim when paused.");
        uint256 merkleIndex = merkleRoots.length - 1;
        require(!isClaimed(merkleIndex, index), "Already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        require(verify(merkleProof, merkleRoots[merkleIndex], node), "Invalid proof.");

        // Mark as claimed and send the token.
        _setClaimed(merkleIndex, index);
        IERC20(token).transfer(msg.sender, amount);

        emit Claimed(merkleIndex, index, msg.sender, amount);
    }

    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}