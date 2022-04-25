// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;


import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Royalty.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Base64.sol";
import "./Pausable.sol";



import "./OwnerRecovery.sol";
import "./PyramidPointer.sol";
import "./LiquidityPoolManagerPointer.sol";

error ZeroAddressError();
error PermissionDenied();
error PyramidDoesNotExist();

struct PyramidEntity {
  uint256 id;
  string name;
  uint256 creationTime;
  uint256 lastProcessingTimestamp;
  uint256 rewardMult;
  uint256 pyramidValue;
  uint256 totalClaimed;
  bool exists;
  bool isMerged;
}

struct PyramidInfoEntity {
  PyramidEntity pyramid;
  uint256 id;
  uint256 pendingRewards;
  uint256 rewardPerDay;
  uint256 compoundDelay;
  uint256 pendingRewardsGross;
  uint256 rewardPerDayGross;
}

struct Tier {
  uint32 level;
  uint32 slope;
  uint32 dailyAPR;
  uint32 claimFee;
  uint32 claimBurnFee;
  uint32 compoundFee;
  string name;
  string imageURI;
}

contract PyramidsManager is
  ERC721,
  ERC721Enumerable,
  ERC721Royalty,
  Pausable,
  Ownable,
  OwnerRecovery,
  ReentrancyGuard,
  PyramidPointer,
  LiquidityPoolManagerPointer
{
  using Counters for Counters.Counter;

  struct TierStorage {
    uint256 rewardMult;
    uint256 amountLockedInTier;
    bool exists;
  }

  Counters.Counter private _pyramidCounter;
  mapping(uint256 => PyramidEntity) private _pyramids;
  mapping(uint256 => TierStorage) private _tierTracking;
  uint256[] _tiersTracked;

  uint256 public creationMinPrice;
  uint256 public compoundDelay;
  uint256 public processingFee;

  Tier[4] public tiers;

  uint256 public totalValueLocked;

  uint256 public burnedFromRenaming;
  uint256 public burnedFromMerging;

  address public whitelist;

  modifier onlyPyramidOwner() {
    address sender = _msgSender();
    if (sender == (address(0))) revert ZeroAddressError();
    if (!isOwnerOfPyramids(sender)) revert PermissionDenied();
    _;
  }

  modifier checkPermissions(uint256 _pyramidId) {
    address sender = _msgSender();
    if (!pyramidExists(_pyramidId)) revert PyramidDoesNotExist();
    if (!isApprovedOrOwnerOfPyramid(sender, _pyramidId))
      revert PermissionDenied();
    _;
  }

  modifier checkPermissionsMultiple(uint256[] memory _pyramidIds) {
    address sender = _msgSender();
    for (uint256 i = 0; i < _pyramidIds.length; i++) {
      if (!pyramidExists(_pyramidIds[i])) revert PyramidDoesNotExist();
      if (!isApprovedOrOwnerOfPyramid(sender, _pyramidIds[i]))
        revert PermissionDenied();
    }
    _;
  }

  modifier verifyName(string memory pyramidName) {
    require(
      bytes(pyramidName).length > 1 && bytes(pyramidName).length < 32,
      "Pyramids: Incorrect name length, must be between 2 to 31"
    );
    _;
  }

  modifier onlyWhitelist() {
    address sender = _msgSender();
    if (sender == address(0)) revert ZeroAddressError();
    if (sender != whitelist) revert PermissionDenied();
    _;
  }

  event Compound(
    address indexed account,
    uint256 indexed pyramidId,
    uint256 amountToCompound
  );
  event Cashout(
    address indexed account,
    uint256 indexed pyramidId,
    uint256 rewardAmount
  );

  event CompoundAll(
    address indexed account,
    uint256[] indexed affectedPyramids,
    uint256 amountToCompound
  );
  event CashoutAll(
    address indexed account,
    uint256[] indexed affectedPyramids,
    uint256 rewardAmount
  );

  event Create(
    address indexed account,
    uint256 indexed newPyramidId,
    uint256 amount
  );

  event Rename(
    address indexed account,
    string indexed previousName,
    string indexed newName
  );

  event Merge(
    uint256[] indexed pyramidIds,
    string indexed name,
    uint256 indexed previousTotalValue
  );

  constructor()ERC721("Pyramid Money", "PRMDNFT") {
    IPyramid _pyramid=IPyramid(0xecaE6dB9f0F6562B3aa595266E3b2b5A5356F763);
    address _whitelist = 0x34c51efE611C1319C1a8039BaB002f3f5809eFA1;
    ILiquidityPoolManager _lpManager =ILiquidityPoolManager(0x6cbEb1d3a09bB4AB75B48EE45aa07D23b9bF9b2A);
    pyramid = _pyramid;
    whitelist = _whitelist;
    liquidityPoolManager = _lpManager;
    changeNodeMinPrice(42_000 * (10**18)); // 42,000 brb
    changeCompoundDelay(43200); // 12h
    changeProcessingFee(2); // 2%

    string
      memory ipfsBaseURI = "ipfs://QmSiikJn6mPevMg9zsyPmRnSy2KqvhKPZ5huubCTZnFZV3/";
    Tier[4] memory _tiers = [
      Tier({
        level: 2000,
        slope: 500,
        dailyAPR: 13,
        claimFee: 40,
        claimBurnFee: 0,
        compoundFee: 0,
        name: "Bronze",
        imageURI: string(abi.encodePacked(ipfsBaseURI, "bronze.jpg"))
      }),
      Tier({
        level: 4000,
        slope: 500,
        dailyAPR: 18,
        claimFee: 20,
        claimBurnFee: 0,
        compoundFee: 0,
        name: "Silver",
        imageURI: string(abi.encodePacked(ipfsBaseURI, "silver.jpg"))
      }),
      Tier({
        level: 8000,
        slope: 500,
        dailyAPR: 25,
        claimFee: 10,
        claimBurnFee: 0,
        compoundFee: 0,
        name: "Gold",
        imageURI: string(abi.encodePacked(ipfsBaseURI, "gold.jpg"))
      }),
      Tier({
        level: 16000,
        slope: 0,
        dailyAPR: 33,
        claimFee: 5,
        claimBurnFee: 0,
        compoundFee: 0,
        name: "Diamond",
        imageURI: string(abi.encodePacked(ipfsBaseURI, "diamond.jpg"))
      })
    ];

    changeTiers(_tiers);
    setDefaultRoyalty(msg.sender, 1500); // 25% NFT sale royalties
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
    public
    onlyOwner
  {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    PyramidEntity memory _pyramid = _pyramids[tokenId];
    (uint256 tier, string memory _type, string memory image) = getTierMetadata(
      _pyramid.rewardMult
    );

    bytes memory dataURI = abi.encodePacked(
      '{"name": "',
      _pyramid.name,
      '", "image": "',
      image,
      '", "attributes": [',
      '{"trait_type": "tier", "value": "',
      Strings.toString(tier),
      '"}, {"trait_type": "type", "value": "',
      _type,
      '"}, {"trait_type": "tokens", "value": "',
      Strings.toString(_pyramid.pyramidValue / (10**18)),
      '"}]}'
    );

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(dataURI)
        )
      );
  }

  function renamePyramid(uint256 _pyramidId, string memory pyramidName)
    external
    nonReentrant
    onlyPyramidOwner
    checkPermissions(_pyramidId)
    whenNotPaused
    verifyName(pyramidName)
  {
    address account = _msgSender();
    PyramidEntity storage pyramid = _pyramids[_pyramidId];
    require(pyramid.pyramidValue > 0, "Error: Pyramid is empty");
    (uint256 newPyramidValue, uint256 feeAmount) = getPercentageOf(
      pyramid.pyramidValue,
      processingFee // 2% processing fee for renaming pyramids
    );
    logTier(pyramid.rewardMult, -int256(feeAmount));
    burnedFromRenaming += feeAmount;
    pyramid.pyramidValue = newPyramidValue;
    string memory previousName = pyramid.name;
    pyramid.name = pyramidName;
    emit Rename(account, previousName, pyramidName);
  }

  function mergePyramids(
    uint256[] memory _pyramidIds,
    string memory pyramidName
  )
    external
    nonReentrant
    onlyPyramidOwner
    checkPermissionsMultiple(_pyramidIds)
    whenNotPaused
    verifyName(pyramidName)
  {
    address account = _msgSender();
    require(
      _pyramidIds.length > 1,
      "PyramidsManager: At least 2 Pyramids must be selected in order for the merge to work"
    );

    uint256 lowestTier = 0;
    uint256 totalValue = 0;

    for (uint256 i = 0; i < _pyramidIds.length; i++) {
      PyramidEntity storage pyramidFromIds = _pyramids[_pyramidIds[i]];
      require(
        isProcessable(pyramidFromIds),
        "PyramidsManager: For the process to work, all selected pyramids must be compoundable. Try again later."
      );

      // Compound the pyramid
      compoundReward(pyramidFromIds.id);

      // Use this tier if it's lower than current
      if (lowestTier == 0) {
        lowestTier = pyramidFromIds.rewardMult;
      } else if (lowestTier > pyramidFromIds.rewardMult) {
        lowestTier = pyramidFromIds.rewardMult;
      }

      // Additionate the locked value
      totalValue += pyramidFromIds.pyramidValue;

      // Burn the pyramid permanently
      _burn(pyramidFromIds.id);
    }
    require(
      lowestTier >= tiers[0].level,
      "PyramidsManager: Something went wrong with the tiers"
    );

    (uint256 newPyramidValue, uint256 feeAmount) = getPercentageOf(
      totalValue,
      processingFee // Burn 2% from the value of across the final amount
    );
    burnedFromMerging += feeAmount;

    // Mint the amount to the user
    pyramid.accountReward(account, newPyramidValue);

    // Create the pyramid (which will burn that amount)
    uint256 currentPyramidId = createPyramidWithTokens(
      pyramidName,
      newPyramidValue
    );

    // Set tier, logTier and increase
    PyramidEntity storage _pyramid = _pyramids[currentPyramidId];
    _pyramid.isMerged = true;
    if (lowestTier != tiers[0].level) {
      logTier(_pyramid.rewardMult, -int256(_pyramid.pyramidValue));
      _pyramid.rewardMult = lowestTier;
      logTier(_pyramid.rewardMult, int256(_pyramid.pyramidValue));
    }

    emit Merge(_pyramidIds, pyramidName, totalValue);
  }

  function createPyramidWithTokens(
    string memory pyramidName,
    uint256 pyramidValue
  )
    public
    nonReentrant
    whenNotPaused
    verifyName(pyramidName)
    returns (uint256)
  {
    return _createPyramidWithTokens(_msgSender(), pyramidName, pyramidValue, 0);
  }

  function whitelistCreatePyramidWithTokens(
    string memory pyramidName,
    uint256 pyramidValue,
    address account,
    uint256 tierLevel
  )
    external
    nonReentrant
    whenNotPaused
    verifyName(pyramidName)
    onlyWhitelist
    returns (uint256)
  {
    uint256 pyramidId = _createPyramidWithTokens(
      account,
      pyramidName,
      pyramidValue,
      tierLevel
    );

    return pyramidId;
  }

  function _createPyramidWithTokens(
    address sender,
    string memory pyramidName,
    uint256 pyramidValue,
    uint256 tierLevel
  ) private returns (uint256) {
    require(
      pyramidValue >= creationMinPrice,
      "Pyramids: Pyramid value set below minimum"
    );
    require(
      isNameAvailable(sender, pyramidName),
      "Pyramids: Name not available"
    );
    require(
      pyramid.balanceOf(sender) >= pyramidValue,
      "Pyramids: Balance too low for creation"
    );

    // Burn the tokens used to mint the NFT
    pyramid.accountBurn(sender, pyramidValue);

    // Increment the total number of tokens
    _pyramidCounter.increment();

    uint256 newPyramidId = _pyramidCounter.current();
    uint256 currentTime = block.timestamp;

    // Add this to the TVL
    totalValueLocked += pyramidValue;
    logTier(tiers[tierLevel].level, int256(pyramidValue));

    // Add Pyramid
    _pyramids[newPyramidId] = PyramidEntity({
      id: newPyramidId,
      name: pyramidName,
      creationTime: currentTime,
      lastProcessingTimestamp: currentTime,
      rewardMult: tiers[tierLevel].level,
      pyramidValue: pyramidValue,
      totalClaimed: 0,
      exists: true,
      isMerged: false
    });

    // Assign the Pyramid to this account
    _mint(sender, newPyramidId);

    emit Create(sender, newPyramidId, pyramidValue);

    return newPyramidId;
  }

  function cashoutReward(uint256 _pyramidId)
    external
    nonReentrant
    onlyPyramidOwner
    checkPermissions(_pyramidId)
    whenNotPaused
  {
    address account = _msgSender();
    (
      uint256 amountToReward,
      uint256 feeAmount,
      uint256 feeBurnAmount
    ) = _getPyramidCashoutRewards(_pyramidId);
    _cashoutReward(amountToReward, feeAmount, feeBurnAmount);

    emit Cashout(account, _pyramidId, amountToReward);
  }

  function cashoutAll() external nonReentrant onlyPyramidOwner whenNotPaused {
    address account = _msgSender();
    uint256 rewardsTotal = 0;
    uint256 feesTotal = 0;
    uint256 feeBurnTotal = 0;

    uint256[] memory pyramidsOwned = getPyramidIdsOf(account);
    for (uint256 i = 0; i < pyramidsOwned.length; i++) {
      (
        uint256 amountToReward,
        uint256 feeAmount,
        uint256 feeBurnAmount
      ) = _getPyramidCashoutRewards(pyramidsOwned[i]);
      rewardsTotal += amountToReward;
      feesTotal += feeAmount;
      feeBurnTotal += feeBurnAmount;
    }
    _cashoutReward(rewardsTotal, feesTotal, feeBurnTotal);

    emit CashoutAll(account, pyramidsOwned, rewardsTotal);
  }

  function compoundReward(uint256 _pyramidId)
    public
    nonReentrant
    onlyPyramidOwner
    checkPermissions(_pyramidId)
    whenNotPaused
  {
    address account = _msgSender();

    (uint256 amountToCompound, uint256 feeAmount) = _getPyramidCompoundRewards(
      _pyramidId
    );
    require(
      amountToCompound > 0,
      "Pyramids: You must wait until you can compound again"
    );
    if (feeAmount > 0) {
      pyramid.liquidityReward(feeAmount);
    }

    emit Compound(account, _pyramidId, amountToCompound);
  }

  function compoundAll() external nonReentrant onlyPyramidOwner whenNotPaused {
    address account = _msgSender();
    uint256 feesAmount = 0;
    uint256 amountsToCompound = 0;
    uint256[] memory pyramidsOwned = getPyramidIdsOf(account);
    uint256[] memory pyramidsAffected = new uint256[](pyramidsOwned.length);

    for (uint256 i = 0; i < pyramidsOwned.length; i++) {
      (
        uint256 amountToCompound,
        uint256 feeAmount
      ) = _getPyramidCompoundRewards(pyramidsOwned[i]);
      if (amountToCompound > 0) {
        pyramidsAffected[i] = pyramidsOwned[i];
        feesAmount += feeAmount;
        amountsToCompound += amountToCompound;
      } else {
        delete pyramidsAffected[i];
      }
    }

    require(amountsToCompound > 0, "Pyramids: No rewards to compound");
    if (feesAmount > 0) {
      pyramid.liquidityReward(feesAmount);
    }

    emit CompoundAll(account, pyramidsAffected, amountsToCompound);
  }

  // Private reward functions

  function _getPyramidCashoutRewards(uint256 _pyramidId)
    private
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    PyramidEntity storage pyramid = _pyramids[_pyramidId];

    if (!isProcessable(pyramid)) {
      return (0, 0, 0);
    }

    uint256 reward = calculateReward(pyramid);
    pyramid.totalClaimed += reward;

    (
      uint256 takeAsFeePercentage,
      uint256 burnFromFeePercentage
    ) = getCashoutDynamicFee(pyramid.rewardMult);
    (uint256 amountToReward, uint256 takeAsFee) = getPercentageOf(
      reward,
      takeAsFeePercentage + burnFromFeePercentage
    );
    (, uint256 burnFromFee) = getPercentageOf(reward, burnFromFeePercentage);

    (, uint256 currentTier) = getTier(pyramid.rewardMult);
    uint256 nextTier;
    if (currentTier > 0) {
      nextTier = currentTier - 1;
    } else {
      nextTier = 0;
    }
    logTier(pyramid.rewardMult, -int256(pyramid.pyramidValue));
    pyramid.rewardMult = tiers[nextTier].level;
    logTier(pyramid.rewardMult, int256(pyramid.pyramidValue));
    pyramid.lastProcessingTimestamp = block.timestamp;

    return (amountToReward, takeAsFee, burnFromFee);
  }

  function _getPyramidCompoundRewards(uint256 _pyramidId)
    private
    returns (uint256, uint256)
  {
    PyramidEntity storage pyramid = _pyramids[_pyramidId];

    if (!isProcessable(pyramid)) {
      return (0, 0);
    }

    uint256 reward = calculateReward(pyramid);
    if (reward > 0) {
      uint256 compoundFee = getCompoundDynamicFee(pyramid.rewardMult);
      (uint256 amountToCompound, uint256 feeAmount) = getPercentageOf(
        reward,
        compoundFee
      );
      totalValueLocked += amountToCompound;

      logTier(pyramid.rewardMult, -int256(pyramid.pyramidValue));

      pyramid.lastProcessingTimestamp = block.timestamp;
      pyramid.pyramidValue += amountToCompound;
      pyramid.rewardMult += increaseMultiplier(pyramid.rewardMult);

      logTier(pyramid.rewardMult, int256(pyramid.pyramidValue));

      return (amountToCompound, feeAmount);
    }

    return (0, 0);
  }

  function _cashoutReward(
    uint256 amountToReward,
    uint256 feeAmount,
    uint256 feeBurnAmount
  ) private {
    require(
      amountToReward > 0,
      "Pyramids: You don't have enough reward to cash out"
    );
    address to = _msgSender();
    pyramid.accountReward(to, amountToReward);
    // Send the fee to the contract where liquidity will be added later on
    pyramid.liquidityReward(feeAmount);
    if (feeBurnAmount > 0) {
      pyramid.accountBurn(address(liquidityPoolManager), feeBurnAmount);
    }
  }

  function logTier(uint256 mult, int256 amount) private {
    TierStorage storage tierStorage = _tierTracking[mult];
    if (tierStorage.exists) {
      require(
        tierStorage.rewardMult == mult,
        "Pyramids: rewardMult does not match in TierStorage"
      );
      uint256 amountLockedInTier = uint256(
        int256(tierStorage.amountLockedInTier) + amount
      );
      tierStorage.amountLockedInTier = amountLockedInTier;
    } else {
      // Tier isn't registered exist, register it
      require(
        amount > 0,
        "Pyramids: Fatal error while creating new TierStorage. Amount cannot be below zero."
      );
      _tierTracking[mult] = TierStorage({
        rewardMult: mult,
        amountLockedInTier: uint256(amount),
        exists: true
      });
      _tiersTracked.push(mult);
    }
  }

  // Private view functions

  function getPercentageOf(uint256 rewardAmount, uint256 _feeAmount)
    private
    pure
    returns (uint256, uint256)
  {
    uint256 feeAmount = 0;
    if (_feeAmount > 0) {
      feeAmount = (rewardAmount * _feeAmount) / 100;
    }
    return (rewardAmount - feeAmount, feeAmount);
  }

  function getTier(uint256 mult) public view returns (Tier memory, uint256) {
    Tier memory _tier;
    for (int256 i = int256(tiers.length - 1); i >= 0; i--) {
      _tier = tiers[uint256(i)];
      if (mult >= _tier.level) {
        return (_tier, uint256(i));
      }
    }
    return (_tier, 0);
  }

  function increaseMultiplier(uint256 prevMult) private view returns (uint256) {
    (Tier memory tier, ) = getTier(prevMult);
    return tier.slope;
  }

  function getTieredRevenues(uint256 mult) private view returns (uint256) {
    (Tier memory tier, ) = getTier(mult);
    return tier.dailyAPR;
  }

  function getTierMetadata(uint256 prevMult)
    private
    view
    returns (
      uint256,
      string memory,
      string memory
    )
  {
    (Tier memory tier, uint256 tierIndex) = getTier(prevMult);
    return (tierIndex + 1, tier.name, tier.imageURI);
  }

  function getCashoutDynamicFee(uint256 mult)
    private
    view
    returns (uint256, uint256)
  {
    (Tier memory tier, ) = getTier(mult);
    return (tier.claimFee, tier.claimBurnFee);
  }

  function getCompoundDynamicFee(uint256 mult) private view returns (uint256) {
    (Tier memory tier, ) = getTier(mult);
    return (tier.compoundFee);
  }

  function isProcessable(PyramidEntity memory pyramid)
    private
    view
    returns (bool)
  {
    return block.timestamp >= pyramid.lastProcessingTimestamp + compoundDelay;
  }

  function calculateReward(PyramidEntity memory pyramid)
    private
    view
    returns (uint256)
  {
    return
      _calculateRewardsFromValue(
        pyramid.pyramidValue,
        pyramid.rewardMult,
        block.timestamp - pyramid.lastProcessingTimestamp
      );
  }

  function rewardPerDayFor(PyramidEntity memory pyramid)
    private
    view
    returns (uint256)
  {
    return
      _calculateRewardsFromValue(
        pyramid.pyramidValue,
        pyramid.rewardMult,
        1 days
      );
  }

  function _calculateRewardsFromValue(
    uint256 _pyramidValue,
    uint256 _rewardMult,
    uint256 _timeRewards
  ) private view returns (uint256) {
    uint256 numOfDays = ((_timeRewards * 1e10) / 1 days);
    uint256 yieldPerDay = getTieredRevenues(_rewardMult);
    return (numOfDays * yieldPerDay * _pyramidValue) / (1000 * 1e10);
  }

  function pyramidExists(uint256 _pyramidId) private view returns (bool) {
    require(_pyramidId > 0, "Pyramids: Id must be higher than zero");
    PyramidEntity memory pyramid = _pyramids[_pyramidId];
    if (pyramid.exists) {
      return true;
    }
    return false;
  }

  // Public view functions

  function calculateTotalDailyEmission() external view returns (uint256) {
    uint256 dailyEmission = 0;
    for (uint256 i = 0; i < _tiersTracked.length; i++) {
      TierStorage memory tierStorage = _tierTracking[_tiersTracked[i]];
      dailyEmission += _calculateRewardsFromValue(
        tierStorage.amountLockedInTier,
        tierStorage.rewardMult,
        1 days
      );
    }
    return dailyEmission;
  }

  function isNameAvailable(address account, string memory pyramidName)
    public
    view
    returns (bool)
  {
    uint256[] memory pyramidsOwned = getPyramidIdsOf(account);
    for (uint256 i = 0; i < pyramidsOwned.length; i++) {
      PyramidEntity memory pyramid = _pyramids[pyramidsOwned[i]];
      if (keccak256(bytes(pyramid.name)) == keccak256(bytes(pyramidName))) {
        return false;
      }
    }
    return true;
  }

  function isOwnerOfPyramids(address account) public view returns (bool) {
    return balanceOf(account) > 0;
  }

  function isApprovedOrOwnerOfPyramid(address account, uint256 _pyramidId)
    public
    view
    returns (bool)
  {
    return _isApprovedOrOwner(account, _pyramidId);
  }

  function getPyramidIdsOf(address account)
    public
    view
    returns (uint256[] memory)
  {
    uint256 numberOfPyramids = balanceOf(account);
    uint256[] memory pyramidIds = new uint256[](numberOfPyramids);
    for (uint256 i = 0; i < numberOfPyramids; i++) {
      uint256 pyramidId = tokenOfOwnerByIndex(account, i);
      require(pyramidExists(pyramidId), "Pyramids: This pyramid doesn't exist");
      pyramidIds[i] = pyramidId;
    }
    return pyramidIds;
  }

  function getPyramidsByIds(uint256[] memory _pyramidIds)
    external
    view
    returns (PyramidInfoEntity[] memory)
  {
    PyramidInfoEntity[] memory pyramidsInfo = new PyramidInfoEntity[](
      _pyramidIds.length
    );

    for (uint256 i = 0; i < _pyramidIds.length; i++) {
      uint256 pyramidId = _pyramidIds[i];
      PyramidEntity memory pyramid = _pyramids[pyramidId];
      (
        uint256 takeAsFeePercentage,
        uint256 burnFromFeePercentage
      ) = getCashoutDynamicFee(pyramid.rewardMult);
      uint256 pendingRewardsGross = calculateReward(pyramid);
      uint256 rewardsPerDayGross = rewardPerDayFor(pyramid);
      (uint256 amountToReward, ) = getPercentageOf(
        pendingRewardsGross,
        takeAsFeePercentage + burnFromFeePercentage
      );
      (uint256 amountToRewardDaily, ) = getPercentageOf(
        rewardsPerDayGross,
        takeAsFeePercentage + burnFromFeePercentage
      );
      pyramidsInfo[i] = PyramidInfoEntity(
        pyramid,
        pyramidId,
        amountToReward,
        amountToRewardDaily,
        compoundDelay,
        pendingRewardsGross,
        rewardsPerDayGross
      );
    }
    return pyramidsInfo;
  }

  // Owner functions

  function changeNodeMinPrice(uint256 _creationMinPrice) public onlyOwner {
    require(
      _creationMinPrice > 0,
      "Pyramids: Minimum price to create a Pyramid must be above 0"
    );
    creationMinPrice = _creationMinPrice;
  }

  function changeCompoundDelay(uint256 _compoundDelay) public onlyOwner {
    require(
      _compoundDelay > 0,
      "Pyramids: compoundDelay must be greater than 0"
    );
    compoundDelay = _compoundDelay;
  }

  function changeTiers(Tier[4] memory _tiers) public onlyOwner {
    require(_tiers.length == 4, "Pyramids: new Tiers length has to be 4");
    for (uint256 i = 0; i < _tiers.length; i++) {
      tiers[i] = _tiers[i];
    }
  }

  function changeProcessingFee(uint256 _fee) public onlyOwner {
    require(_fee < 100, "Pyramids: Processing Fee cannot be 100%");
    processingFee = _fee;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  // Mandatory overrides

  function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable, ERC721Royalty)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}