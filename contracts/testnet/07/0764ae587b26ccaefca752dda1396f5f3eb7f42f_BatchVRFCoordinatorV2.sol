/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library VRFTypes {
  // ABI-compatible with VRF.Proof.
  // This proof is used for VRF V2.
  struct Proof {
    uint256[2] pk;
    uint256[2] gamma;
    uint256 c;
    uint256 s;
    uint256 seed;
    address uWitness;
    uint256[2] cGammaWitness;
    uint256[2] sHashWitness;
    uint256 zInv;
  }

  // ABI-compatible with VRFCoordinatorV2.RequestCommitment.
  // This is only used for VRF V2.
  struct RequestCommitment {
    uint64 blockNum;
    uint64 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
    address sender;
  }
}

/**
 * @title BatchVRFCoordinatorV2
 * @notice The BatchVRFCoordinatorV2 contract acts as a proxy to write many random responses to the
 *   provided VRFCoordinatorV2 contract efficiently in a single transaction.
 */
contract BatchVRFCoordinatorV2 {
  VRFCoordinatorV2 public immutable COORDINATOR;

  event ErrorReturned(uint256 indexed requestId, string reason);
  event RawErrorReturned(uint256 indexed requestId, bytes lowLevelData);

  constructor(address coordinatorAddr) {
    COORDINATOR = VRFCoordinatorV2(coordinatorAddr);
  }

  //uint256 public rc;
  uint256 length;


  function fulfillRandomWords(VRFTypes.Proof[] memory proofs, VRFTypes.RequestCommitment[] memory rcs) external {
    require(proofs.length == rcs.length, "input array arg lengths mismatch");
    
    //proofData = proofs;
    //rcData = rcs;
    length = rcs.length;
    for (uint256 i = 0; i < proofs.length; i++) {
      
    }
  }

  /**
   * @notice Returns the proving key hash associated with this public key.
   * @param publicKey the key to return the hash of.
   */
  function hashOfKey(uint256[2] memory publicKey) internal pure returns (bytes32) {
    return keccak256(abi.encode(publicKey));
  }

  /**
   * @notice Returns the request ID of the request associated with the given proof.
   * @param proof the VRF proof provided by the VRF oracle.
   */
  function getRequestIdFromProof(VRFTypes.Proof memory proof) internal pure returns (uint256) {
    bytes32 keyHash = hashOfKey(proof.pk);
    return uint256(keccak256(abi.encode(keyHash, proof.seed)));
  }
}

interface VRFCoordinatorV2 {
  function fulfillRandomWords(VRFTypes.Proof memory proof, VRFTypes.RequestCommitment memory rc)
    external
    returns (uint96);
}