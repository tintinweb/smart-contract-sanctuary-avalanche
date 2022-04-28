/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-27
*/

// This library is used to check merkle proofs very efficiently. Each additional proof element adds ~1000 gas
library MerkleLib {

    // This is the main function that will be called by contracts. It assumes the leaf is already hashed, as in,
    // it is not raw data but the hash of that. This is because the leaf data could be any combination of hashable
    // datatypes, so we let contracts hash the data themselves to keep this function simple
    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        bytes32 currentHash = leaf;

        // the proof is all siblings of the ancestors of the leaf (including the sibling of the leaf itself)
        // each iteration of this loop steps one layer higher in the merkle tree
        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = parentHash(currentHash, proof[i]);
        }

        // does the result match the expected root? if so this leaf was committed to when the root was posted
        // else we must assume the data was not included
        return currentHash == root;
    }

    function parentHash(bytes32 a, bytes32 b) public pure returns (bytes32) {
        // the convention is that the inputs are sorted, this removes ambiguity about tree structure
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

}