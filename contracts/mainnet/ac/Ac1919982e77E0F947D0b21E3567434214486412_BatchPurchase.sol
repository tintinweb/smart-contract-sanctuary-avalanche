// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./CampfireMarket.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BatchPurchase is Ownable, ReentrancyGuard, IERC721Receiver {

  bool private _active;
  address private _marketContractAddress;

  constructor() {
    _active = true;
  }

  function run(
    address[] memory _sellers, 
    address[] memory _contractAddresses, 
    uint256[] memory _tokenIds, 
    uint256[] memory _prices, 
    uint256[] memory _expirations, 
    bytes32[] memory _salts, 
    bytes[] memory _signatures
  ) public nonReentrant payable {
    require(_active, "BatchPurchase: Contract is not active.");

    uint256 totalPrice = 0;
    for (uint256 index = 0; index < _prices.length; index++) {
      totalPrice += _prices[index];
    }
    require(totalPrice != 0, "Total price cannot be 0.");
    require(msg.value >= totalPrice, "Not enough AVAX sent.");

    CampfireMarket market = CampfireMarket(payable(_marketContractAddress));

    for (uint256 index = 0; index < _prices.length; index++) {
      market.purchase{value:_prices[index]}(
        _sellers[index],
        _contractAddresses[index], 
        _tokenIds[index], 
        _prices[index], 
        _expirations[index], 
        _salts[index], 
        _signatures[index]
      );

      IERC721 nft = IERC721(_contractAddresses[index]);

      nft.transferFrom(address(this), msg.sender, _tokenIds[index]);
    }
  }

  function setMarketContract(address marketContractAddress_) public onlyOwner {
    _marketContractAddress = marketContractAddress_;
  }

  function setActive(bool active_) public onlyOwner {
    _active = active_;
  }

  receive() external payable {}

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  // NOTE: Probably never need to call this, but adding just in case!
  function removeStuck(address nftContract, uint256 tokenId) public onlyOwner {
    IERC721 nft = IERC721(nftContract);
    nft.transferFrom(address(this), owner(), tokenId);
  }

  function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes calldata data) external override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Royalties is IERC721 {

  function royaltyInfo(
    uint256 _tokenId, 
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CampfireStaking is Ownable, ReentrancyGuard {
  uint256 private _totalNftsStaked;
  uint256 private _totalBlockEntries;

  address private _wavaxAddress;
  address private _keeperAddress;
  uint256 private _maxStake;

  mapping (address => uint256) private _totalNftsStakedForAccount;
  mapping (address => bool) private _partners;
  mapping (address => bool) private _managers;
  mapping (address => uint256) private _blockEntries;

  mapping (address => mapping (uint256 => bool)) _staked;
  mapping (address => mapping (uint256 => address)) private _stakers;
  // mapping (address => StakedNFT[]) private _stakedNFTs;

  mapping (address => mapping (address => bool)) private _approvals;

  mapping (bytes32 => StakedNFT) private _stakedNFTs;
  mapping (address => bytes32[]) private _stakedNFTHashes;


  struct StakedNFT {
    address contractAddress;
    uint256 tokenId;
  }

  constructor() {
    _managers[msg.sender] = true;
    _maxStake = 250;
  }

  modifier onlyManager() {
    require(_managers[msg.sender], "Campfire Staking: Caller is not the manager");
    _;
  }

  function addManager(address _newManager) public onlyManager {
    _managers[_newManager] = true;
  }

  function removeManager(address _manager) public onlyManager {
    _managers[_manager] = false;
  }

  function addPartner(address _contractAddress) public onlyManager {
    _partners[_contractAddress] = true;
  }

  function isPartner(address _contractAddress) public view returns (bool) {
    if (_contractAddress == 0x5e4504663AB2a8060715A1D1f162873F39DF9abf) { // OUTLAWS
      return true;
    } else {
      return _partners[_contractAddress];
    }
  }

  function stakeSet(address _contractAddress, uint256[] memory _tokenIds) public nonReentrant {
    require(_tokenIds.length <= 15, "Campfire Staking: You can't stake more than 15 at a time.");
    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(msg.sender);
    for (uint256 index = 0; index < _tokenIds.length; index++) {
      uint256 _tokenId = _tokenIds[index];
      _stake(_contractAddress, _tokenId, (accountNftsStaked + index));
    }
  }

  function stake(address _contractAddress, uint256 _tokenId) public nonReentrant {
    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(msg.sender);
    _stake(_contractAddress, _tokenId, accountNftsStaked);
  }

  function _stake(address _contractAddress, uint256 _tokenId, uint256 accountNftsStaked) private {
    require(isPartner(_contractAddress), "Campfire Staking: This project is not a parter.");

    IERC721 nft = IERC721(_contractAddress);
    require(nft.ownerOf(_tokenId) == msg.sender, "Campfire Staking: You don't own that NFT.");

    if (isStaked(_contractAddress, _tokenId)) {
      if (_stakers[_contractAddress][_tokenId] == msg.sender) {
        require(false, "Campfire Staking: You cannot stake an NFT more than once.");
      } else {
        address originalOwner = _stakers[_contractAddress][_tokenId];
        uint256 currentForOriginal = getNumberStaked(originalOwner);

        resetTotalsFor(originalOwner, currentForOriginal);

        _stakers[_contractAddress][_tokenId] = msg.sender;
      }
    }
    
    if (_totalNftsStakedForAccount[msg.sender] > 0 && block.number < _blockEntries[msg.sender]) {
      if (_totalNftsStakedForAccount[msg.sender] > accountNftsStaked) {
        resetTotalsFor(msg.sender, accountNftsStaked);
      }

      uint256 avaxRewards = _availableAVAXRewards(msg.sender, accountNftsStaked);
      uint256 wavaxRewards = _availableWAVAXRewards(msg.sender, accountNftsStaked);

      _totalBlockEntries -= _blockEntries[msg.sender] * _totalNftsStakedForAccount[msg.sender];

      if (wavaxRewards > 0) {
        IERC20 wavax = IERC20(_wavaxAddress);
        wavax.transfer(msg.sender, wavaxRewards);
      }
      if (avaxRewards > 0) {
        payable(msg.sender).transfer(avaxRewards);
      }
    } else if (_totalNftsStakedForAccount[msg.sender] > 0) {
      _totalBlockEntries -= _blockEntries[msg.sender] * _totalNftsStakedForAccount[msg.sender];
    }

    _totalNftsStaked += 1;
    _totalNftsStakedForAccount[msg.sender] += 1;

    _blockEntries[msg.sender] = block.number;
    _totalBlockEntries += block.number * _totalNftsStakedForAccount[msg.sender];

    bytes32 nftHash = keccak256(abi.encodePacked(msg.sender, _contractAddress, _tokenId));

    _stakedNFTs[nftHash] = StakedNFT(_contractAddress, _tokenId);
    _stakedNFTHashes[msg.sender].push(nftHash);

    _stakers[_contractAddress][_tokenId] = msg.sender;

    require(_totalNftsStakedForAccount[msg.sender] <= _maxStake, "Campfire Staking: You have hit the max staked limit.");

    _staked[_contractAddress][_tokenId] = true;
  }

  function isStaked(address _contractAddress, uint256 _tokenId) public view returns (bool) {
    return _staked[_contractAddress][_tokenId];
  }

  function totalStaked() public view returns (uint256) {
    return _totalNftsStaked;
  }

  function totalStakedFor(address staker) public view returns (uint256) {
    return _totalNftsStakedForAccount[staker];
  }
  
  function totalBlockEntries() public view returns (uint256) {
    return _totalBlockEntries;
  }

  function blockEntriesFor(address staker) public view returns (uint256) {
    return _blockEntries[staker];
  }

  function unstake(address _contractAddress, uint256 _tokenId) public nonReentrant {
    IERC721 nft = IERC721(_contractAddress);

    address nftOwner = nft.ownerOf(_tokenId);
    require(msg.sender == nftOwner, "Campfire Staking: You don't own that NFT.");
    require(isStaked(_contractAddress, _tokenId), "Campfire Staking: That NFT is not currently staked.");

    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(msg.sender);

    if (_totalNftsStakedForAccount[msg.sender] > accountNftsStaked) {
      resetTotalsFor(msg.sender, accountNftsStaked);
    }

    uint256 avaxRewards = _availableAVAXRewards(msg.sender, accountNftsStaked);
    uint256 wavaxRewards = _availableWAVAXRewards(msg.sender, accountNftsStaked);

    _totalBlockEntries -= _blockEntries[msg.sender] * _totalNftsStakedForAccount[msg.sender];
    
    _totalNftsStaked -= 1;
    _totalNftsStakedForAccount[msg.sender] -= 1;
    
    _blockEntries[msg.sender] = block.number;
    _totalBlockEntries += block.number * _totalNftsStakedForAccount[msg.sender];

    _staked[_contractAddress][_tokenId] = false;

    IERC20 wavax = IERC20(_wavaxAddress);

    if (wavaxRewards > 0) {
      wavax.transfer(msg.sender, wavaxRewards);
    }
    if (avaxRewards > 0) {
      payable(msg.sender).transfer(avaxRewards);
    }
  }

  function unclaimedBlocks() public view returns (uint256) {
    uint256 totalUnclaimedBlocks = (block.number * _totalNftsStaked) - _totalBlockEntries;
    return totalUnclaimedBlocks;
  }

  function claim() public nonReentrant {
    _claim(msg.sender);
  }

  function claimFor(address account) public {
    require(msg.sender == _keeperAddress || _approvals[account][msg.sender], "Campfire Staking: You don't have permission to do that.");

    _claim(account);
  }

  function _claim(address account) private {
    require(_totalNftsStakedForAccount[account] > 0, "Campfire Staking: You are not staked.");

    // IMPORTANT: Rely on real value here, not cached!
    uint256 accountNftsStaked = getNumberStaked(account);

    if (_totalNftsStakedForAccount[account] > accountNftsStaked) {
      resetTotalsFor(account, accountNftsStaked);
    }

    uint256 avaxRewards = _availableAVAXRewards(account, accountNftsStaked);
    uint256 wavaxRewards = _availableWAVAXRewards(account, accountNftsStaked);

    _totalBlockEntries -= _blockEntries[account] * _totalNftsStakedForAccount[account];

    _blockEntries[account] = block.number;
    _totalBlockEntries += block.number * _totalNftsStakedForAccount[account];

    IERC20 wavax = IERC20(_wavaxAddress);

    if (wavaxRewards > 0) {
      wavax.transfer(account, wavaxRewards);
    }
    if (avaxRewards > 0) {
      payable(account).transfer(avaxRewards);
    }
  }

  function resetTotalsFor(address account, uint256 accountNftsStaked) private {
    _totalBlockEntries -= (_blockEntries[account] * _totalNftsStakedForAccount[account]);
    _totalNftsStaked -= _totalNftsStakedForAccount[account];
    _totalNftsStakedForAccount[account] = accountNftsStaked;
    _totalBlockEntries += (_blockEntries[account] * _totalNftsStakedForAccount[account]);
    _totalNftsStaked += _totalNftsStakedForAccount[account];
  }

  // NOTE: The next two methods are convenience methods for the UI --> not to be used internally
  function availableAVAXRewards(address account) public view returns (uint256) {
    uint256 accountNftsStaked = getNumberStaked(account);
    uint256 available = address(this).balance;
    return _rewardsCalc(account, available, accountNftsStaked);
  }

  function availableWAVAXRewards(address account) public view returns (uint256) {
    uint256 accountNftsStaked = getNumberStaked(account);
    IERC20 wavax = IERC20(_wavaxAddress);
    uint256 available = wavax.balanceOf(address(this));
    return _rewardsCalc(account, available, accountNftsStaked);
  }

  function _availableAVAXRewards(address account, uint256 accountNftsStaked) private view returns (uint256) {
    uint256 available = address(this).balance;
    return _rewardsCalc(account, available, accountNftsStaked);
  }

  function _availableWAVAXRewards(address account, uint256 accountNftsStaked) private view returns (uint256) {
    IERC20 wavax = IERC20(_wavaxAddress);
    uint256 available = wavax.balanceOf(address(this));
    return _rewardsCalc(account, available, accountNftsStaked);
  }


  function _rewardsCalc(address account, uint256 available, uint256 accountNftsStaked) private view returns (uint256) {
      uint256 totalUnclaimedBlocks = (block.number * _totalNftsStaked) - _totalBlockEntries;

     if (totalUnclaimedBlocks > 0) {
      uint256 accountUnclaimedBlocks = (block.number * accountNftsStaked) - (_blockEntries[account] * accountNftsStaked);
      uint256 reward = (available * accountUnclaimedBlocks) / totalUnclaimedBlocks;
      return reward;
    } else {
      return 0;
    }
  }

  function getNumberStaked(address staker) public view returns (uint256) {
    uint256 numberStaked = 0;
    for (uint256 index = 0; index < _stakedNFTHashes[staker].length; index++) {
      bytes32 nftHash = _stakedNFTHashes[staker][index];
      StakedNFT memory stakedNFT = _stakedNFTs[nftHash];

      if (isStaked(stakedNFT.contractAddress, stakedNFT.tokenId)) {
        IERC721 nft = IERC721(stakedNFT.contractAddress);
        if (nft.ownerOf(stakedNFT.tokenId) == staker) {
          numberStaked += 1;
        }
      }
    }
    return numberStaked;
  }

  function setWAVAX(address wavaxAddress_) public onlyOwner {
    _wavaxAddress = wavaxAddress_;
  }

  function setKeeper(address keeperAddress_) public onlyOwner {
    _keeperAddress = keeperAddress_;
  }

  function setMaxStake(uint256 maxStake_) public onlyOwner {
    _maxStake = maxStake_;
  }

  function approve(address manager, bool approved) public {
    _approvals[msg.sender][manager] = approved;
  }

  receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IERC721Royalties.sol";
import "./CampfireStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CampfireMarket is Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  mapping (bytes32 => bool) private _saltUsed;
  mapping (bytes32 => bool) private _saltCancelled;

  address private _stakingContractAddress;
  address private _wavaxAddress;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  bool private _active;

  // kind = 1 for PurchaseListed
  // kind = 2 for AcceptOffer
  event Sale(
    address indexed buyer,
    address indexed seller,
    address indexed nftContractAddress,
    uint256 nftTokenId,
    uint256 price,
    uint kind,
    bytes32 salt
  );


  // kind = 1 for Listing
  // kind = 2 for Offer
  event Cancel(
    address indexed creator,
    address indexed nftContractAddress,
    uint256 nftTokenId,
    uint256 price,
    uint kind,
    bytes32 salt
  );

  constructor() {
    _active = true;
  }

  function purchase(address _seller, address _contractAddress, uint256 _tokenId, uint256 _price, uint256 _expiration, bytes32 _salt, bytes memory _signature) public nonReentrant payable {
    require(_active, "Campfire Market: Contract is not active.");
    require(!_saltUsed[_salt], "Campfire Market: Salt has already been used.");
    require(!_saltCancelled[_salt], "Campfire Market: Listing has been cancelled.");
    require(block.timestamp <= _expiration, "Campfire Market: This listing has expired.");

    require(!CampfireStaking(payable(_stakingContractAddress)).isStaked(_contractAddress, _tokenId), "Campfire Market: Cannot sell staked NFTs.");
    
    IERC721Royalties nft = IERC721Royalties(_contractAddress);
    address currentNFTOwner = nft.ownerOf(_tokenId);

    bytes32 hash = keccak256(abi.encodePacked(_seller, _contractAddress, _tokenId, _price, _expiration, _salt));
    address signer = hash.toEthSignedMessageHash().recover(_signature);
    require(signer == currentNFTOwner && currentNFTOwner == _seller, "Campfire Market: Signature does not match.");
    require(msg.value >= _price, "Campfire Market: Not enough AVAX sent.");

    _saltUsed[_salt] = true;
    nft.safeTransferFrom(currentNFTOwner, msg.sender, _tokenId);

    if (nft.supportsInterface(_INTERFACE_ID_ERC2981)) {
      (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(_tokenId, _price);
      payable(receiver).transfer(royaltyAmount);

      payable(owner()).transfer(msg.value / 100);
      payable(_stakingContractAddress).transfer(msg.value / 100);

      uint256 remainder = msg.value - (royaltyAmount + ((msg.value * 2) / 100));
      payable(currentNFTOwner).transfer(remainder);
    } else {
      payable(currentNFTOwner).transfer((msg.value * 98) / 100);
      payable(owner()).transfer(msg.value / 100);
      payable(_stakingContractAddress).transfer(msg.value / 100);
    }

    emit Sale(msg.sender, signer, _contractAddress, _tokenId, _price, 1, _salt);
  }

  function acceptOffer(address _buyer, address _contractAddress, uint256 _tokenId, uint256 _price, uint256 _expiration, bytes32 _salt, bytes memory _signature) public nonReentrant {
    require(_active, "Campfire Market: Contract is not active.");
    require(!_saltUsed[_salt], "Campfire Market: Salt has already been used.");
    require(!_saltCancelled[_salt], "Campfire Market: Offer has been cancelled.");
    require(block.timestamp <= _expiration, "Campfire Market: This offer has expired.");

    require(!CampfireStaking(payable(_stakingContractAddress)).isStaked(_contractAddress, _tokenId), "Campfire Market: Cannot sell staked NFTs.");

    bytes32 hash = keccak256(abi.encodePacked(_buyer, _contractAddress, _tokenId, _price, _expiration, _salt));
    address signer = hash.toEthSignedMessageHash().recover(_signature);
    require(signer == _buyer, "Campfire Market: Signature does not match.");

    IERC20 wavax = IERC20(_wavaxAddress);
    require(wavax.balanceOf(_buyer) >= _price, "Campfire Market: Buyer doesn't have enough WAVAX.");

    IERC721Royalties nft = IERC721Royalties(_contractAddress);

    _saltUsed[_salt] = true;

    nft.safeTransferFrom(msg.sender, _buyer, _tokenId);
    
    if (nft.supportsInterface(_INTERFACE_ID_ERC2981)) {
      (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(_tokenId, _price);
      wavax.transferFrom(_buyer, receiver, royaltyAmount);

      wavax.transferFrom(_buyer, owner(), (_price / 100));
      wavax.transferFrom(_buyer, _stakingContractAddress, (_price / 100));

      uint256 remainder = _price - (royaltyAmount + ((_price * 2) / 100));
      wavax.transferFrom(_buyer, msg.sender, remainder);
    } else {
      wavax.transferFrom(_buyer, msg.sender, ((_price * 98) / 100));
      wavax.transferFrom(_buyer, owner(), (_price / 100));
      wavax.transferFrom(_buyer, _stakingContractAddress, (_price / 100));
    }

    emit Sale(signer, msg.sender, _contractAddress, _tokenId, _price, 2, _salt);
  }

  function cancelListing(address _seller, address _contractAddress, uint256 _tokenId, uint256 _price, uint256 _expiration, bytes32 _salt, bytes memory _signature) public nonReentrant {
    bytes32 hash = keccak256(abi.encodePacked(_seller, _contractAddress, _tokenId, _price, _expiration, _salt));
    address signer = hash.toEthSignedMessageHash().recover(_signature);
    require(msg.sender == signer && signer == _seller, "Campfire Market: You didn't create that listing.");
    
    _saltCancelled[_salt] = true;
    emit Cancel(signer, _contractAddress, _tokenId, _price, 1, _salt);
  }

  function cancelOffer(address _buyer, address _contractAddress, uint256 _tokenId, uint256 _price, uint256 _expiration, bytes32 _salt, bytes memory _signature) public nonReentrant {
    bytes32 hash = keccak256(abi.encodePacked(_buyer, _contractAddress, _tokenId, _price, _expiration, _salt));
    address signer = hash.toEthSignedMessageHash().recover(_signature);
    require((msg.sender == signer) && (signer == _buyer), "Campfire Market: You didn't create that offer.");
    
    _saltCancelled[_salt] = true;
    emit Cancel(signer, _contractAddress, _tokenId, _price, 2, _salt);
  }

  function saltUsed(bytes32 salt) public view returns (bool) {
    return _saltUsed[salt];
  }

  function hasBeenCancelled(bytes32 salt) public view returns (bool) {
    return _saltCancelled[salt];
  }

  function setStakingContract(address stakingContractAddress_) public onlyOwner {
    _stakingContractAddress = stakingContractAddress_;
  }

  function setWAVAX(address wavaxAddress_) public onlyOwner {
    _wavaxAddress = wavaxAddress_;
  }

  function setActive(bool active_) public onlyOwner {
    _active = active_;
  }

  receive() external payable {}

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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