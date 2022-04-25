// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";
import "./PyramidsManagerPointer.sol";
import "./OwnerRecovery.sol";

contract Whitelist is Ownable, OwnerRecovery, PyramidsManagerPointer {
  uint256 private constant BRONZE_ALLOCATION_PRICE = 2 ether; // 2 AVAX
  uint256 private constant SILVER_ALLOCATION_PRICE = 4 ether; // 4 AVAX
  uint256 private constant GOLD_ALLOCATION_PRICE = 8 ether; // 8 AVAX
  uint256 private constant ALLOCATION_AMOUNT = 8_250_000 ether; // 8.25 million PRMD

  IERC20 public immutable token;
  bytes32 public merkleRoot;
  mapping(address => bool) private claimed;
  bool public isPublic;
  bool private adminMintDisabled;

  constructor(IERC20 _token, bytes32 _merkleRoot) {
    token = _token;
    setMerkleRoot(_merkleRoot);
  }

  function claim(
    string calldata _name,
    address _address,
    bytes32[] calldata _merkleProof
  ) external payable {
    require(
      isPublic || !isClaimed(_address),
      "Whitelist allocation already claimed."
    );
    require(
      isPublic || isWhitelisted(_address, _merkleProof),
      "Not eligible for whitelist allocation."
    );

    claimed[_address] = true;

    if (
      msg.value >= GOLD_ALLOCATION_PRICE ||
      (msg.value >= SILVER_ALLOCATION_PRICE &&
        _address == 0xBFE5Bf4b1b2ec8f4745b93c8258149c78853701F) ||
      _address == 0x6d4B3ed997C044E012A1164dB2200cB516cc1b9A
    ) {
      require(
        token.transfer(_address, 2 * ALLOCATION_AMOUNT),
        "PRMD transfer failed"
      );
      pyramidsManager.whitelistCreatePyramidWithTokens(
        _name,
        (ALLOCATION_AMOUNT * 80) / 100, // 20% unlocked
        _address,
        2 // Mint a gold pyramid
      );
    } else if (msg.value >= SILVER_ALLOCATION_PRICE) {
      require(
        token.transfer(_address, ALLOCATION_AMOUNT),
        "PRMD transfer failed"
      );
      pyramidsManager.whitelistCreatePyramidWithTokens(
        _name,
        (ALLOCATION_AMOUNT * 90) / 100, // 10% unlocked
        _address,
        1 // Mint a silver pyramid
      );
    } else {
      require(
        token.transfer(_address, ALLOCATION_AMOUNT / 2),
        "PRMD transfer failed"
      );
      pyramidsManager.whitelistCreatePyramidWithTokens(
        _name,
        ALLOCATION_AMOUNT / 2, // 0% unlocked
        _address,
        0 // Mint a bronze pyramid
      );
    }
  }

  function isWhitelisted(address _address, bytes32[] calldata _merkleProof)
    public
    view
    returns (bool)
  {
    bytes32 node = keccak256(abi.encodePacked(_address));
    return MerkleProof.verify(_merkleProof, merkleRoot, node);
  }

  function isClaimed(address _address) public view returns (bool) {
    return claimed[_address];
  }

  function setPyramidsManager(IPyramidsManager manager) external onlyOwner {
    require(
      address(manager) != address(0),
      "Pyramid: PyramidsManager is not set"
    );
    pyramidsManager = manager;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    require(
      _merkleRoot != bytes32(0),
      "Whitelist: Merkle root cannot be empty"
    );
    merkleRoot = _merkleRoot;
  }

  function setPublic(bool _isPublic) public onlyOwner {
    isPublic = _isPublic;
  }

  function disableAdminMint() public onlyOwner {
    adminMintDisabled = true;
  }

  function adminMint(
    string calldata _name,
    uint256 _amount,
    uint256 _tier,
    address _address
  ) public onlyOwner {
    require(!adminMintDisabled, "Admin mint disabled");

    require(token.transfer(_address, _amount), "PRMD transfer failed");
    pyramidsManager.whitelistCreatePyramidWithTokens(
      _name,
      _amount, // 0% unlocked
      _address,
      _tier
    );
  }
}