// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

/**
 * @title MovementProof
 * @author Alex Legal
 * @notice Store & retrieve proof of existence of a string in a map with the ability
 * to flag them as `Valid` or `Invalid`.
 * The proof is a signature of a Movement.
 */
contract MovementProof {
  /**
   * @dev This struct stores a validity flag and the timestamp
   * of when the Movement proof is set.
   */
  struct Movement {
    uint256 timestamp;
    bool isValid;
  }

  // Contract Owner
  address public owner;

  // Contract running state
  bool public paused;

  // Store the Movements proof validity
  mapping(string => Movement) public proofs;

  // Store moderators access rights. `true` if `address` can call the contract
  mapping(address => bool) public moderators;

  // Store the current ledger version for each business identifier
  mapping(string => uint16) public version;

  // Store the number of moderator with access right
  uint8 public moderatorsCount;

  /**
   * @dev Emitted when a proof is added and flagged as Valid
   *
   * @param indexedHash The indexed hash
   * @param hash the hash
   * @param timestamp The current block timestamp.
   */
  event ProofAdded(string indexed indexedHash, string hash, uint256 timestamp);

  /**
   * @dev Emitted when a proof is added and flagged as Invalid
   *
   * @param indexedHash The indexed hash
   * @param hash the hash
   * @param timestamp The current block timestamp.
   */
  event ProofInvalidated(
    string indexed indexedHash,
    string hash,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a Moderator is granted access
   *
   * @param adr The address of the Moderator
   * @param timestamp The current block timestamp.
   */
  event ModeratorGranted(address indexed adr, uint256 timestamp);

  /**
   * @dev Emitted when a Moderator is revoked
   *
   * @param adr The address of the Moderator
   * @param timestamp The current block timestamp.
   */
  event ModeratorRevoked(address indexed adr, uint256 timestamp);

  /**
   * @dev Emitted when the contract ownership is transferred
   *
   * @param adr The address of the new Owner
   * @param timestamp The current block timestamp.
   */
  event OwnershipTransferred(address indexed adr, uint256 timestamp);

  /**
   * @dev Emitted when the contract is paused
   *
   * @param timestamp The current block timestamp.
   */
  event ContractPaused(uint256 timestamp);

  /**
   * @dev Emitted when the contract is resumed
   *
   * @param timestamp The current block timestamp.
   */
  event ContractResumed(uint256 timestamp);

  /**
   * @dev Emitted when version changes
   * @param timestamp The current block timestamp.
   */
  event VersionChanged(
    string indexed businessIdentifier,
    uint16 version,
    uint256 timestamp
  );

  /**
   * @dev Set the contract initial variables
   * the contract is deployed by owner (superAdmin)
   */
  constructor() {
    owner = msg.sender;
    paused = true;
    moderatorsCount = 0;
  }

  /**
   * @dev This modifier reverts if the a proof is added twice.
   */
  modifier onlyOneProof(string memory hash) {
    require(proofs[hash].timestamp == 0, "The proof should be added only once");
    _;
  }

  /**
   * @dev This modifier reverts if the `hashes` array is empty.
   */
  modifier onlyMultipleProofs(string[] memory hashes) {
    require(hashes.length > 0, "At least one proof required");
    _;
  }

  /**
   * @dev This modifier reverts if the the contract is running.
   */
  modifier onlyPaused() {
    require(paused == true, "Only with contract in paused state");
    _;
  }

  /**
   * @dev This modifier reverts if the the contract is paused.
   */
  modifier onlyRunning() {
    require(paused == false, "Only with contract in running state");
    _;
  }

  /**
   * @dev This modifier reverts if the caller is not the contract Owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  /**
   * @dev This modifier reverts if the caller is not a Moderator.
   */
  modifier onlyModerators() {
    require(
      moderators[msg.sender] == true,
      "Only moderators can call this function"
    );
    _;
  }

  /**
   * @dev This modifier reverts if at least one valid Moderator exists.
   */
  modifier onlyWithNoModerators() {
    require(moderatorsCount == 0, "Only with all moderators access revoked");
    _;
  }

  /**
   * @dev Create a proof for the supplied string.
   *
   * @param hash The proof to create and to flagged as Valid
   */
  function createProof(string memory hash) public onlyModerators onlyRunning {
    insertValidProof(hash);
  }

  /**
   * @dev Create a proofs for the supplied array of string.
   *
   * @param hashes The list of proof to create and to flagged as Valid
   */
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

  /**
   * @dev Create a proof of an invalid movement for the supplied string.
   *
   * @param hash The proof to create and to flagged as Invalid
   */
  function invalidateProof(string memory hash)
    public
    onlyModerators
    onlyRunning
  {
    insertInvalidProof(hash);
  }

  /**
   * @dev Create proofs for the supplied array of string.
   *
   * @param hashes The list of proof to create and to flag as Invalid
   */
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

  /**
   * @dev Create proofs for the supplied arrays of string.
   *
   * @param validHashes The list of proof to create and to flag as Valid
   * @param invalidHashes The list of proof to create and to flag as Invalid
   */
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

  /**
   * @dev Internal convenience to insert a Valid Proof
   */
  function insertValidProof(string memory hash) private onlyOneProof(hash) {
    proofs[hash] = Movement(block.timestamp, true);
    emit ProofAdded(hash, hash, block.timestamp);
  }

  /**
   * @dev Internal convenience to insert an Invalid Proof
   */
  function insertInvalidProof(string memory hash) private {
    proofs[hash].isValid = false;
    if (proofs[hash].timestamp == 0) {
      proofs[hash].timestamp = block.timestamp;
    }
    emit ProofInvalidated(hash, hash, block.timestamp);
  }

  /**
   * @dev check validity for all hashes provided
   *
   * @param hashes string array of proofs to verify
   * @param isValid Boolean used for comparison
   * @return `true` if all proof have the same validity as the one provided
   * otherwise return `false`
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

  /**
   * @dev Internal convenience to verify a single Proof validity
   */
  function checkProofValidity(string memory hash) private view returns (bool) {
    return proofs[hash].isValid;
  }

  /**
   * @dev Change the contract state to `Pause`
   */
  function pause() public onlyOwner {
    paused = true;
    emit ContractPaused(block.timestamp);
  }

  /**
   * @dev Change the contract state to `Running`
   */
  function resume() public onlyOwner {
    paused = false;
    emit ContractResumed(block.timestamp);
  }

  /**
   * @dev Transfer the contract ownership to the supplied address
   *
   * @param adr address of the new Owner
   */
  function transferOwnership(address adr) public onlyOwner {
    owner = adr;
    emit OwnershipTransferred(adr, block.timestamp);
  }

  /**
   * @dev Drop the contract ownership.
   * @notice Ownership transferred to the blackhole address
   */
  function dropOwnership() public onlyOwner onlyPaused onlyWithNoModerators {
    transferOwnership(address(0));
  }

  /**
   * @dev Increment the version number of a business identifier
   *
   * @param businessIdentifier Business identifier of the business identifier
   */
  function changeVersion(string memory businessIdentifier)
    public
    onlyModerators
    onlyRunning
    returns (uint16)
  {
    version[businessIdentifier] += 1;
    emit VersionChanged(
      businessIdentifier,
      version[businessIdentifier],
      block.timestamp
    );
    return version[businessIdentifier];
  }

  /**
   * @dev Add a contract Moderator
   *
   * @param adr address of the new Moderator
   */
  function grantModerator(address adr) public onlyOwner {
    moderators[adr] = true;
    moderatorsCount += 1;
    emit ModeratorGranted(adr, block.timestamp);
  }

  /**
   * @dev Remove a contract Moderator
   *
   * @param adr address of the Moderator to remove
   */
  function revokeModerator(address adr) public onlyOwner {
    moderators[adr] = false;
    moderatorsCount -= 1;
    emit ModeratorRevoked(adr, block.timestamp);
  }
}