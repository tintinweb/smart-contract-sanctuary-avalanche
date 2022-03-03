// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Restricted.sol";

import "./Glow.sol";
import "./Skeleton.sol";
import "./AttributesPets.sol";
import "./Pets.sol";

contract MagicForest is IERC721Receiver, Pausable, Restricted {

    struct RangerStake {
        uint16 tokenId;
        uint32 lastClaim;
        address owner;
    }

    struct SkeletonStake {
        uint16 tokenId;
        uint256 lastGlowPerAlpha;
        uint256 unclaimed;
        address owner;
    }

    event TokenStaked(address indexed owner, uint256 indexed tokenId);
    event TokenClaimed(address indexed owner, uint256 indexed tokenId, uint256 earned, bool unstaked);
    event RangerUnstaked(address indexed owner, uint256 indexed tokenId, bool stolen);

    Glow public glow;
    Skeleton public skeleton;
    Pets public pets;

    mapping(address => uint16[]) public skeletonsByOwner;
    mapping(uint16 => uint16) public skeletonsByOwnerIndices;
    mapping(address => uint16) public walletToNumberStaked;
    // maps tokenId to stake
    mapping(uint16 => RangerStake) public rangerStakes;
    // maps alpha to all hunter stakes with that alpha
    mapping(uint16 => SkeletonStake[]) public skeletonStakes;
    // tracks location of each Hunter in Pack
    mapping(uint16 => uint256) public skeletonStakesIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no hunters are staked
    uint256 public unaccountedRewards = 0;
    // amount of $GLOW due for each alpha point staked
    uint256 public glowPerAlpha = 0;

    // adventurer earn 5000 $GLOW per day
    uint256 public constant DAILY_GLOW_RATE = 5000 ether;
    // adventurer must have 2 days worth of $GLOW to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 minutes; // 2 days for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    // hunters take a 20% tax on all $GLOW claimed
    uint8 public constant GLOW_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $GLOW earned through staking
    uint256 public MAXIMUM_GLOBAL_GLOW = 2400000000 ether;

    // amount of $GLOW earned so far
    uint256 public totalGlowEarned;
    // the last time $GLOW was claimed
    uint256 public lastRangerClaimTimestamp;

    uint256 public totalRangerStaked;
    uint256 public totalSkeletonStaked;
    
    uint8[5] productionSpeedByLevel = [0, 5, 10, 20, 30];

    // Claim is disabled while the liquidity is not added
    bool public claimEnabled;

    uint32 public sessionDuration = 1 hours;
    uint32 public sessionBegining;
    uint256 public lastSessionClaimNumber;
    uint256 public sessionClaimNumber;
    uint256[6] public claimingFeeValues= [0, 1 wei, 2 wei, 3 wei, 4 wei, 5 wei];
    // [0, 0.01 ether, 0.02 ether, 0.03 ether, 0.04 ether, 0.05 ether]  for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    uint256[6] public claimingFeeTresholds = [10, 100, 1000, 10000, 100000, type(uint256).max];

    /**
     * @param _skeleton reference to the Skeleton NFT contract
     * @param _glow reference to the $GLOW token
     */
    constructor(address _glow, address _skeleton) {
        setGlow(_glow);
        setSkeleton(_skeleton);
    }

    /* STAKING */

    /**
     * Stakes Rangers and Skeletons in the MagicForest
     * @param tokenIds the IDs of the Rangers and Skeletons to stake
     */
    function stakeMany(uint16[] memory tokenIds)
        external
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stakeOne(_msgSender(), tokenIds[i]);
        }
        walletToNumberStaked[_msgSender()] += uint16(tokenIds.length);
    }

    /**
     * Internal function to stake one Ranger or Skeleton in the MagicForest
     * @param account the address of the staker
     * @param tokenId the ID of the Adventurer or Hunter to stake
     */
    function _stakeOne(address account, uint16 tokenId) internal {
        require(skeleton.ownerOf(tokenId) == account, "Not your token");

        skeleton.transferFrom(account, address(this), tokenId);
        
        (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenId);
        if (isRanger) {
            _stakeRanger(account, tokenId);
        } else  {
            AttributesPets.Boost memory walletBoost = pets.getWalletBoost(account);
            uint8 virtualAlpha = _getVirtualAlpha(alphaIndex, level, walletBoost.alphaAugmentation);
            _stakeSkeleton(account, tokenId, virtualAlpha);
        }

        uint256 petId = pets.rangerTokenToPetToken(tokenId);
        if (petId != 0) pets.transferFrom(account, address(this), petId);
    }

    /**
     * Stakes a Ranger
     * @dev Rangers go to barn
     * @param account the address of the staker
     * @param tokenId Id of the Ranger to stake
     */
    function _stakeRanger(address account, uint16 tokenId) internal whenNotPaused _updateEarnings {
        rangerStakes[tokenId] = RangerStake(tokenId, uint32(block.timestamp), account);
        totalRangerStaked++;
        emit TokenStaked(account, tokenId);
    }

    /**
     * Stakes a Skeleton
     * @dev Skeletons go to pack
     * @param account the address of the staker
     * @param tokenId Id of the Skeleton to stake
     * @param virtualAlpha Virtual alpha of the skeleton (alpha + level + boost)
     */
    function _stakeSkeleton(address account, uint16 tokenId, uint8 virtualAlpha) internal {
        totalAlphaStaked += virtualAlpha;
        _addToSkeletonStakes(virtualAlpha, SkeletonStake(uint16(tokenId), glowPerAlpha, 0, account));
        totalSkeletonStaked++;
        _addToSkeletonsByOwner(account, tokenId);
        emit TokenStaked(account, tokenId);
    }

    /* CLAIMING / UNSTAKING */

    /**
     * realize $GLOW earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Adventurer it will require it has 2 days worth of $GLOW unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimMany(uint16[] memory tokenIds, bool unstake)
        external
        payable
        whenNotPaused
        onlyEOA
        noReentrency
        notBlacklisted 
        _updateEarnings
    {
        require(claimEnabled, "Claiming not yet available");
        require(msg.value >= tokenIds.length * getClaimingFee(), "You didn't pay tax");

        _updateClaimingSession(uint32(block.timestamp));

        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(_msgSender());
        uint256 lastGlowTransfer = glow.lastTransfer(_msgSender());
        uint16 numberStaked = walletToNumberStaked[_msgSender()];
        uint32 lastWalletAssociation = pets.lastWalletAssociation(_msgSender());

        if (unstake) walletToNumberStaked[_msgSender()] -= uint16(tokenIds.length);

        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenIds[i]);
            if (isRanger) {
                owed += _claimRanger(tokenIds[i], unstake, level, walletBoost, lastGlowTransfer, numberStaked, lastWalletAssociation);
            } else {
                uint8 virtualAlpha = _getVirtualAlpha(alphaIndex, level, walletBoost.alphaAugmentation);
                owed += _claimSkeleton(tokenIds[i], unstake, virtualAlpha);
            }
        }

        if (owed > 0) glow.mint(_msgSender(), owed);
    }

    function _claimRanger(
        uint16 tokenId,
        bool unstake,
        uint8 level,
        AttributesPets.Boost memory walletBoost,
        uint256 lastGlowTransfer,
        uint16 numberStaked,
        uint32 lastWalletAssociation
    ) internal returns (uint256 owed) {
        require(skeleton.ownerOf(tokenId) == address(this), "Not in Magic Forest");

        RangerStake memory stake = rangerStakes[tokenId];

        require(stake.owner == _msgSender(), "Not your token");

        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        
        owed = _calculateRangerRewards(level, stake.lastClaim, walletBoost, rangerBoost, lastGlowTransfer, numberStaked, lastWalletAssociation);

        if (unstake) {
            require(
                block.timestamp - stake.lastClaim >= _getMinimumToExit(rangerBoost.unstakeCooldownAugmentation, walletBoost.globalUnstakeCooldownAugmentation),
                "Need to wait some days before unstake"
            );

            if (_isStolen(tokenId, rangerBoost.stolenProbabilityAugmentation, rangerBoost.stolenProbabilityReduction, walletBoost.globalUnstakeStealAugmentation)) {
                // 50% chance of all $GLOW stolen
                _paySkeletonTax(owed);
                owed = 0;
                emit RangerUnstaked(stake.owner, tokenId, true);
            } else {
                emit RangerUnstaked(stake.owner, tokenId, false);
            }

            skeleton.transferFrom(address(this), _msgSender(), tokenId);
            uint256 petToken = pets.rangerTokenToPetToken(tokenId);
            if (petToken != 0) {
                pets.transferFrom(address(this), _msgSender(), petToken);
            }
            delete rangerStakes[tokenId];
            totalRangerStaked--;
        } else {
            uint256 glowTaxed = (owed * _getClaimTaxPercentage(rangerBoost.claimTaxReduction)) / 100;
            _paySkeletonTax(glowTaxed);
            owed -= glowTaxed;
            rangerStakes[tokenId].lastClaim = uint32(block.timestamp);
        }
        
        emit TokenClaimed(stake.owner, tokenId, owed, unstake);
    }

    function _claimSkeleton(uint16 tokenId, bool unstake, uint8 virtualAlpha) internal returns (uint256 owed) {
        require(skeleton.ownerOf(tokenId) == address(this), "Not in Magic Forest");

        SkeletonStake memory stake = skeletonStakes[virtualAlpha][skeletonStakesIndices[tokenId]];

        require(stake.owner == _msgSender(), "Not your token");

        owed = _calculateSkeletonRewards(virtualAlpha, stake.lastGlowPerAlpha) + stake.unclaimed;

        if (unstake) {
            totalAlphaStaked -= virtualAlpha; // Remove Alpha from total staked
            skeleton.transferFrom(address(this), _msgSender(), tokenId);
            _removeFromSkeletonStakes(virtualAlpha, tokenId);
            _removeFromSkeletonsByOwner(stake.owner, tokenId);
            totalSkeletonStaked--;
        } else {
            skeletonStakes[virtualAlpha][skeletonStakesIndices[tokenId]].lastGlowPerAlpha = glowPerAlpha;
            skeletonStakes[virtualAlpha][skeletonStakesIndices[tokenId]].unclaimed = 0;
        }

        emit TokenClaimed(stake.owner, tokenId, owed, unstake);
    }

    /**
     * Add $GLOW to claimable pot for the Pack
     * @param amount $GLOW to add to the pot
     */
    function _paySkeletonTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked hunters
            unaccountedRewards += amount; // keep track of $GLOW due to hunters
            return;
        }
        // makes sure to include any unaccounted $GLOW
        glowPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * Tracks $GLOW earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalGlowEarned < MAXIMUM_GLOBAL_GLOW) {
            totalGlowEarned +=
                ((block.timestamp - lastRangerClaimTimestamp) *
                    totalRangerStaked *
                    DAILY_GLOW_RATE) /
                1 days;
            lastRangerClaimTimestamp = block.timestamp;
        }
        _;
    }

    function updateSkeletonStakes(address account, uint8 newAlphaAugmentation, uint8 oldAlphaAugmentation) external {
        require(_msgSender() == address(pets), "Only for Pets here");
        for (uint16 i = 0; i < skeletonsByOwner[account].length; i++) {
            uint16 tokenId = skeletonsByOwner[account][i];
            (, uint8 alphaIndex, uint8 level) = getTokenStats(tokenId);
            uint8 oldVirtualAlpha = _getVirtualAlpha(alphaIndex, level, oldAlphaAugmentation);
            SkeletonStake memory stake = _removeFromSkeletonStakes(oldVirtualAlpha, tokenId);
            stake.unclaimed += _calculateSkeletonRewards(oldVirtualAlpha, stake.lastGlowPerAlpha);
            stake.lastGlowPerAlpha = glowPerAlpha;
            _addToSkeletonStakes(_getVirtualAlpha(alphaIndex, level, newAlphaAugmentation), stake);
        }
        totalAlphaStaked -= oldAlphaAugmentation * skeletonsByOwner[account].length;
        totalAlphaStaked += newAlphaAugmentation * skeletonsByOwner[account].length;
    } 

    /* STRUCTURES MANIPULATIONS */

    function _removeFromSkeletonStakes(uint8 alpha, uint16 tokenId) internal returns (SkeletonStake memory stake) {
        stake = skeletonStakes[alpha][skeletonStakesIndices[tokenId]];
        SkeletonStake memory lastStake = skeletonStakes[alpha][skeletonStakes[alpha].length - 1];
        skeletonStakes[alpha][skeletonStakesIndices[tokenId]] = lastStake; // Shuffle last Skeleton to current position
        skeletonStakesIndices[lastStake.tokenId] = skeletonStakesIndices[tokenId];
        skeletonStakes[alpha].pop(); // Remove duplicate
        delete skeletonStakesIndices[tokenId]; // Delete old mapping
    }

    function _addToSkeletonStakes(uint8 alpha, SkeletonStake memory stake) internal {
        skeletonStakesIndices[stake.tokenId] = skeletonStakes[alpha].length;
        skeletonStakes[alpha].push(stake);
    }

    function _removeFromSkeletonsByOwner(address account, uint16 tokenId) internal {
        uint16 lastTokenId = skeletonsByOwner[account][skeletonsByOwner[account].length - 1];
        skeletonsByOwner[account][skeletonsByOwnerIndices[tokenId]] = lastTokenId; // Shuffle last Skeleton to current position
        skeletonsByOwnerIndices[lastTokenId] = skeletonsByOwnerIndices[tokenId];
        skeletonsByOwner[account].pop(); // Remove duplicate
        delete skeletonsByOwnerIndices[tokenId]; // Delete old mapping
    }

    function _addToSkeletonsByOwner(address account, uint16 tokenId) internal {
        skeletonsByOwnerIndices[tokenId] = uint16(skeletonsByOwner[account].length);
        skeletonsByOwner[account].push(tokenId);
    }

    /* READING */

    function calculateRewards(uint16 tokenId) external view returns (uint256) {
        (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenId);
        if (isRanger) {
            RangerStake memory stake = rangerStakes[tokenId];
            if (stake.tokenId == tokenId) {
                AttributesPets.Boost memory walletBoost = pets.getWalletBoost(stake.owner);
                AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
                uint256 lastGlowTransfer = glow.lastTransfer(stake.owner);
                uint16 numberStaked = walletToNumberStaked[stake.owner];
                uint32 lastWalletAssociation = pets.lastWalletAssociation(stake.owner);
                return _calculateRangerRewards(
                    level,
                    stake.lastClaim,
                    walletBoost,
                    rangerBoost,
                    lastGlowTransfer,
                    numberStaked,
                    lastWalletAssociation
                );
            } else {
                return 0;
            }
        } else {
            for (uint8 virtualAlpha = alphaIndex; virtualAlpha <= 20; virtualAlpha++) {
                if (skeletonStakes[virtualAlpha].length > skeletonStakesIndices[tokenId]) {
                    SkeletonStake memory stake = skeletonStakes[virtualAlpha][skeletonStakesIndices[tokenId]];
                    if (stake.tokenId == tokenId) {
                        return _calculateSkeletonRewards(virtualAlpha, stake.lastGlowPerAlpha) + stake.unclaimed;
                    }
                }
            }
            return 0;
        }
    }

    function getDailyGlowRate(uint256 tokenId) external view returns (uint256 dailyGlowRate) {
        (bool isRanger,, uint8 level) = getTokenStats(tokenId);
        if (!isRanger) return 0;
        address tokenOwner = rangerStakes[uint16(tokenId)].owner;
        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(tokenOwner);
        uint256 lastGlowTransfer = glow.lastTransfer(tokenOwner);
        uint16 numberStaked = walletToNumberStaked[tokenOwner];
        (, dailyGlowRate) = _getDailyGlowrate(level, walletBoost, rangerBoost, lastGlowTransfer, numberStaked);
    }

    function getClaimTaxPercentage(uint256 tokenId) external view returns(uint256) {
        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        return _getClaimTaxPercentage(rangerBoost.claimTaxReduction);
    }

    function getMinimumToExit(uint16 tokenId) external view returns(uint256){

        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        
        RangerStake memory stake = rangerStakes[tokenId];
        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(stake.owner);

        return _getMinimumToExit(rangerBoost.unstakeCooldownAugmentation, walletBoost.globalUnstakeCooldownAugmentation);
    }

    function getClaimingFee() public view returns (uint256) {
        if (sessionBegining == 0) return claimingFeeValues[2];
        else if (block.timestamp - sessionBegining > sessionDuration) return claimingFeeValues[0];
        else {
            for (uint8 i = 0; i < 5; i++) {
                if (lastSessionClaimNumber < claimingFeeTresholds[i]) return claimingFeeValues[i];
            }
            return claimingFeeValues[5];
        }
    }

    function getTokenStats(uint256 tokenId) public view returns (bool isRanger, uint8 alphaIndex, uint8 level) {
        (isRanger, level, , , , , , , alphaIndex) = skeleton.tokenTraits(tokenId);
    }

    /**
     * Chooses a random Skeleton thief when a newly minted token is stolen
     * @dev Only called by the contract Skeleton
     * @param seed a random value to choose a Skelton from
     * @return the owner of the randomly selected Skeleton thief
     */
    function randomSkeletonOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Hunters with the same alpha score
        for (uint8 i = 0; i <= 20; i++) {
            cumulative += skeletonStakes[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Hunter with that alpha score
            return skeletonStakes[i][seed % skeletonStakes[i].length].owner;
        }
        return address(0x0);
    }

    /* INTERNAL COMPUTATIONS */

    function _calculateRangerRewards(
        uint8 level,
        uint32 lastClaim,
        AttributesPets.Boost memory walletBoost,
        AttributesPets.Boost memory rangerBoost,
        uint256 lastGlowTransfer,
        uint16 numberStaked,
        uint32 lastWalletAssociation
    ) internal view returns (uint256 owed) {
        (uint256 dailyGlowRateWithoutWalletBoost, uint256 dailyGlowRateWithWalletBoost) = _getDailyGlowrate(
            level,
            walletBoost,
            rangerBoost,
            lastGlowTransfer,
            numberStaked
        );

        if (totalGlowEarned < MAXIMUM_GLOBAL_GLOW) {
            if (lastWalletAssociation > lastClaim) {
                // Rewards since the wallet pet was equipped
                owed += ((block.timestamp - lastWalletAssociation) * dailyGlowRateWithWalletBoost) / 1 days; 
                // Rewards until the wallet pet was equipped
                owed += ((lastWalletAssociation - lastClaim) * dailyGlowRateWithoutWalletBoost) / 1 days; 
            } else {
                owed += ((block.timestamp - lastClaim) * dailyGlowRateWithWalletBoost) / 1 days; 
            }
        } else if (lastClaim > lastRangerClaimTimestamp) {
            // $GLOW production stopped already
            owed = 0; 
        } else { // Stop earning additional $GLOW if it's all been earned
            if (lastWalletAssociation >= lastRangerClaimTimestamp) { // Wallet pet equipped after the $GLOW production stopped
                owed = ((lastRangerClaimTimestamp - lastClaim) * dailyGlowRateWithoutWalletBoost) / 1 days;
            } else {
                // Rewards since the wallet pet was equipped
                owed += ((lastRangerClaimTimestamp - lastWalletAssociation) * dailyGlowRateWithWalletBoost) / 1 days; 
                // Rewards until the wallet pet was equipped
                owed += ((lastWalletAssociation - lastClaim) * dailyGlowRateWithoutWalletBoost) / 1 days;
            }
            
        }

        // Limit adventurer wage based on their level (limited inventory)
        uint256 maxGlow = 5000 ether * level;
        owed = owed > maxGlow ? maxGlow : owed;
    }

    function _calculateSkeletonRewards(uint8 virtualAlpha, uint256 lastGlowPerAlpha) internal view returns (uint256) {
        return virtualAlpha * (glowPerAlpha - lastGlowPerAlpha);
    }

    /**
     * Computes the alpha score used for rewards computation
     * @param alphaIndex Actual alpha score
     * @param level Level of the skeleton
     * @param alphaAugmentation Alpha augmentation of the wallet boost of the pet equiped
     * @return the virtual alpha score
     */
    function _getVirtualAlpha(
        uint8 alphaIndex,
        uint8 level,
        uint8 alphaAugmentation
    ) internal pure returns (uint8) {
        uint8 alphaFromLevel = level - 1  + (level  == 5 ? 1 : 0);
        return alphaIndex + alphaAugmentation + alphaFromLevel;
    }

    function _getClaimTaxPercentage(uint8 claimTaxReduction) internal pure returns (uint8) {
        assert(claimTaxReduction <= 20);
        return GLOW_CLAIM_TAX_PERCENTAGE - claimTaxReduction;
    }

    function _getMinimumToExit(
        uint8 unstakeCooldownAugmentation,
        uint8 globalUnstakeCooldownAugmentation
    ) internal pure returns(uint256) {
        return (MINIMUM_TO_EXIT * (100 + unstakeCooldownAugmentation + globalUnstakeCooldownAugmentation)) / 100;
    }

    /**
     * Computes daily glow rates
     * @param level Level of the ranger
     * @param walletBoost Boost of the pet associated to the wallet of the owner
     * @param rangerBoost Boost of the pet associated to the ranger
     * @param lastGlowTransfer Timestamp of the last $GLOW transfer of the owner
     * @param numberStaked Number of tokens staked by the owner
     * @return (dailyGlowRateWithoutWalletBoost, dailyGlowRateWithWalletBoost) - 
     * Daily $GLOW rates of the token if the wallet boost is not equipped, and if it is equipped
     */
    function _getDailyGlowrate(
        uint8 level,
        AttributesPets.Boost memory walletBoost,
        AttributesPets.Boost memory rangerBoost,
        uint256 lastGlowTransfer,
        uint16 numberStaked
    ) internal view returns (uint256, uint256) {
        
        uint256 percentageWithoutWalletBoost = 100;

        // Bonus of increase in $GLOW production
        percentageWithoutWalletBoost += rangerBoost.productionSpeed;

        // Increase adventurer wage based on their level
        percentageWithoutWalletBoost += productionSpeedByLevel[level-1];

        // Bonus based on the number of NFTs staked
        if (numberStaked <= 5) {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByNFTStaked[0];
        }else if (numberStaked <= 10) {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByNFTStaked[1];
        } else if (numberStaked <= 20) {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByNFTStaked[2];
        } else {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByNFTStaked[3];
        }

        // Bonus based on the time spent without selling $GLOW
        if (block.timestamp - lastGlowTransfer <= 1 days) {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[0];
        } else if (block.timestamp - lastGlowTransfer <= 2 days) {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[1];
        } else if (block.timestamp - lastGlowTransfer <= 3 days) {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[2];
        } else {
            percentageWithoutWalletBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[3];
        }

        uint256 percentageWithWalletBoost = percentageWithoutWalletBoost;

        // Wallet bonus based on the number of NFTs staked
        if (numberStaked <= 9) {
            percentageWithWalletBoost += walletBoost.globalProductionSpeedByNFTStaked[0];
        } else if (numberStaked <= 19) {
            percentageWithWalletBoost += walletBoost.globalProductionSpeedByNFTStaked[1];
        } else if (numberStaked <= 29) {
            percentageWithWalletBoost += walletBoost.globalProductionSpeedByNFTStaked[2];
        } else {
            percentageWithWalletBoost += walletBoost.globalProductionSpeedByNFTStaked[3];
        }

        // Wallet bonus of increase in $GLOW production
        percentageWithWalletBoost += walletBoost.globalProductionSpeed;

        return ((DAILY_GLOW_RATE * percentageWithoutWalletBoost) / 100, (DAILY_GLOW_RATE * percentageWithWalletBoost) / 100);
    }

    function _chanceToGetStolen(
        uint8 unstakeStealAugmentation,
        uint8 unstakeStealReduction,
        uint8 globalUnstakeStealAugmentation
    ) internal pure returns(uint8) {
        return 50 + unstakeStealAugmentation - unstakeStealReduction + globalUnstakeStealAugmentation;
    }

    function _isStolen(
        uint256 tokenId,
        uint8 unstakeStealAugmentation,
        uint8 unstakeStealReduction,
        uint8 globalUnstakeStealAugmentation
    ) internal view returns (bool) {
        uint256 randomNumber =  uint256(keccak256(abi.encodePacked(_msgSender(), blockhash(block.number - 1), tokenId)));
        uint256 treshold = _chanceToGetStolen(unstakeStealAugmentation, unstakeStealReduction, globalUnstakeStealAugmentation);
        return uint16(randomNumber & 0xFFFF) % 100 < treshold;
    }

    function _updateClaimingSession(uint32 claimingTimestamp) internal {
        if (claimingTimestamp - sessionBegining > sessionDuration) {
            sessionBegining = (claimingTimestamp / sessionDuration) * sessionDuration;
            if (claimingTimestamp - sessionBegining > 2 * sessionDuration) {
                lastSessionClaimNumber = (sessionBegining == 0) ? claimingFeeTresholds[2] : 0;
            } else {
                lastSessionClaimNumber = sessionClaimNumber;
            }
            sessionClaimNumber = 0;
        }
        sessionClaimNumber++;
    }

    /* TOKEN TRANSFERS */

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to MagicForest directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    /* MONEY TRANSFERS */

    function withdraw() external onlyController {
        payable(owner()).transfer(address(this).balance);
    }

    /* GAME MANAGEMENT */

    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    function toggleClaimEnabled() external onlyController {
        claimEnabled = !claimEnabled;
    }

    function setMaximumGlobalGlow(uint256 _maximumGlobalGlow) external onlyController {
        MAXIMUM_GLOBAL_GLOW = _maximumGlobalGlow;
    }

    function setClaimingFees(uint256[] calldata values, uint256[] calldata tresholds, uint32 duration) external onlyController {
        sessionDuration = duration;
        for (uint8 i = 0; i < values.length; i++) {
            claimingFeeValues[i] = values[i];
            claimingFeeTresholds[i] = tresholds[i];
        }
    }

    /* ADDRESSES SETTERS */

    function setGlow(address _glow) public onlyController {
        glow = Glow(_glow);
    }

    function setSkeleton(address _skeleton) public onlyController {
        skeleton = Skeleton(_skeleton);
    }

    function setPets(address _pets) public onlyController{
        pets = Pets(_pets);
    }
}