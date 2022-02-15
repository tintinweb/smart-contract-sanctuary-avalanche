// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/**
 * @title TransactionProof
 * @dev Store & retrieve existence of a string in a map
 */
contract MovementProof {
  struct Movement {
    uint256 timestamp;
    bool isValid;
  }

  address public owner;
  bool public paused;
  mapping(string => Movement) public proofs;
  mapping(address => bool) public moderators;
  mapping(string => uint16) public version;
  uint8 public moderatorsCount;

  event ProofAdded(string indexed indexedHash, string hash, uint256 timestamp);
  event ProofInvalidated(
    string indexed indexedHash,
    string hash,
    uint256 timestamp
  );
  event ModeratorGranted(address indexed adr, uint256 timestamp);
  event ModeratorRevoked(address indexed adr, uint256 timestamp);
  event OwnershipTransferred(address indexed adr, uint256 timestamp);
  event ContractPaused(uint256 timestamp);
  event ContractResumed(uint256 timestamp);
  event VersionChanged(string indexed businessIdentifier, uint16 version);

  /**
    Set the contract init variables
    the contract is deployed by owner (superAdmin)
    */
  constructor() {
    owner = msg.sender;
    paused = true;
    moderatorsCount = 0;
  }

  modifier onlyOneProof(string memory hash) {
    require(
      !proofs[hash].isValid && proofs[hash].timestamp == 0,
      "The proof should be added only once"
    );
    _;
  }

  modifier onlyMultipleProofs(string[] memory hashes) {
    require(hashes.length > 0, "At least one proof required");
    _;
  }

  modifier onlyPaused() {
    require(paused == true, "Only with contract in paused state");
    _;
  }

  modifier onlyRunning() {
    require(paused == false, "Only with contract in running state");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  modifier onlyModerators() {
    require(
      moderators[msg.sender] == true,
      "Only moderators can call this function"
    );
    _;
  }

  modifier onlyWithNoModerators() {
    require(moderatorsCount == 0, "Only with all moderators access revoked");
    _;
  }

  function createProof(string memory hash) public onlyModerators onlyRunning {
    insertValidProof(hash);
  }

  function createBatchedProofs(string[] memory hashes)
    public
    onlyModerators
    onlyRunning
    onlyMultipleProofs(hashes)
  {
    for (uint32 i = 0; i < hashes.length; i++) {
      string memory hash = hashes[i];
      insertValidProof(hash);
    }
  }

  function invalidateProof(string memory hash)
    public
    onlyModerators
    onlyRunning
  {
    insertInvalidProof(hash);
  }

  function invalidateBatchedProofs(string[] memory hashes)
    public
    onlyModerators
    onlyRunning
    onlyMultipleProofs(hashes)
  {
    for (uint32 i = 0; i < hashes.length; i++) {
      string memory hash = hashes[i];
      insertInvalidProof(hash);
    }
  }

  function syncBatchedProofs(
    string[] memory validHashes,
    string[] memory invalidHashes
  ) public {
    require(
      validHashes.length + invalidHashes.length > 0,
      "Neet at least one proof to sync"
    );
    if (validHashes.length > 0) {
      createBatchedProofs(validHashes);
    }
    if (invalidHashes.length > 0) {
      invalidateBatchedProofs(invalidHashes);
    }
  }

  function insertValidProof(string memory hash) private onlyOneProof(hash) {
    proofs[hash] = Movement(block.timestamp, true);
    emit ProofAdded(hash, hash, block.timestamp);
  }

  function insertInvalidProof(string memory hash) private {
    if (proofs[hash].isValid) {
      proofs[hash].isValid = false;
    } else {
      proofs[hash].timestamp = block.timestamp;
    }
    emit ProofInvalidated(hash, hash, block.timestamp);
  }

  /* `verifyBatchedProof` check valadity all hashes provided
   * `hashes` String array of proofs to check
   * `isValid` Boolean used for comparison
   *  return `true` if all proof have the same validity as the one provided
   *  otherwise return `false`
   */
  function verifyBatchedProof(string[] memory hashes, bool isValid)
    public
    view
    onlyMultipleProofs(hashes)
    returns (bool)
  {
    for (uint32 i = 0; i < hashes.length; i++) {
      if (checkProofValidity(hashes[i]) != isValid) {
        return false;
      }
    }
    return true;
  }

  function checkProofValidity(string memory hash) private view returns (bool) {
    return proofs[hash].isValid;
  }

  function pause() public onlyOwner {
    paused = true;
    emit ContractPaused(block.timestamp);
  }

  function resume() public onlyOwner {
    paused = false;
    emit ContractResumed(block.timestamp);
  }

  function transferOwnership(address adr) public onlyOwner {
    owner = adr;
    emit OwnershipTransferred(adr, block.timestamp);
  }

  function dropOwnership() public onlyOwner onlyPaused onlyWithNoModerators {
    transferOwnership(address(0));
  }

  function changeVersion(string memory businessIdentifier)
    public
    onlyModerators
    onlyRunning
    returns (uint16)
  {
    version[businessIdentifier] += 1;
    emit VersionChanged(businessIdentifier, version[businessIdentifier]);
    return version[businessIdentifier];
  }

  function grantModerator(address adr) public onlyOwner {
    moderators[adr] = true;
    moderatorsCount += 1;
    emit ModeratorGranted(adr, block.timestamp);
  }

  function revokeModerator(address adr) public onlyOwner {
    moderators[adr] = false;
    moderatorsCount -= 1;
    emit ModeratorRevoked(adr, block.timestamp);
  }
}