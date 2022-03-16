// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Restricted.sol";

import "./Glow.sol";
import "./Skeleton.sol";
import "./AttributesPets.sol";
import "./Pets.sol";

contract MagicForest is IERC721Receiver, Pausable, Restricted {

    struct Stake {
        address owner;
        uint256 lastValue; // Last claim for Rangers, last $GLOW per alpha for Skeletons (updated on level / alpha change)
        uint64 lastClaim; // For rangers only, real last claim (from the user, not updated on level / alpha change)
        uint64 blockNumber;
        uint256 unclaimed;
    }

    struct SkeletonIndices {
        uint16 byAlpha;
        uint16 byOwner;
    }

    event TokenStaked(address indexed owner, uint256 indexed tokenId);
    event TokenClaimed(address indexed owner, uint256 indexed tokenId, uint256 earned, bool unstaked);
    event RangerUnstaked(address indexed owner, uint256 indexed tokenId, bool stolen);

    Glow     public glow;
    Skeleton public skeleton;
    Pets     public pets;

    mapping(uint16 => Stake)   public stakes;
    mapping(address => uint16) public numberStakedOf;
    
    mapping(uint8 => uint16[])   public skeletonsByAlpha;
    mapping(address => uint16[]) public skeletonsByOwner;

    mapping(uint16 => SkeletonIndices) private skeletonIndices;

    uint256 public totalAlphaStaked = 0;
    uint256 public unaccountedRewards = 0;
    uint256 public glowPerAlpha = 0;

    uint256 public constant DAILY_GLOW_RATE = 5000 ether;
    uint256 public constant MINIMUM_TO_EXIT = 2 minutes; // 2 days for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    uint8   public constant GLOW_CLAIM_TAX_PERCENTAGE = 20;
    uint256 public          MAXIMUM_GLOBAL_GLOW = 2400000000 ether;

    uint256 public totalGlowEarned;
    uint256 public lastRangerClaimTimestamp;

    uint256 public totalRangerStaked;
    uint256 public totalSkeletonStaked;
    
    uint8[5] productionSpeedByLevel = [0, 5, 10, 20, 30];

    // Claim is disabled while the liquidity is not added
    bool public claimEnabled;
    bool public rescueEnabled;

    uint32  public sessionDuration = 1 hours;
    uint32  public sessionBegining;
    uint256 public lastSessionClaimNumber;
    uint256 public sessionClaimNumber;
    uint256[6] public claimingFeeValues= [0, 1 wei, 2 wei, 3 wei, 4 wei, 5 wei];
    // [0, 0.01 ether, 0.02 ether, 0.03 ether, 0.04 ether, 0.05 ether]  for real launch <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    uint256[6] public claimingFeeTresholds = [10, 100, 1000, 10000, 100000, type(uint256).max];

    /**
     * @param _skeleton Reference to the Skeleton NFT contract
     * @param _glow Rseference to the $GLOW token contract
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
        for (uint256 i; i < tokenIds.length;) {
            _stakeOne(_msgSender(), tokenIds[i]);
            unchecked{++i;}
        }
        numberStakedOf[_msgSender()] += uint16(tokenIds.length);
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
            uint256 petId = pets.rangerTokenToPetToken(tokenId);
            if (petId != 0) pets.transferFrom(account, address(this), petId);
        } else  {
            AttributesPets.Boost memory walletBoost = pets.getWalletBoost(account);
            uint8 virtualAlpha = _getVirtualAlpha(alphaIndex, level, walletBoost.alphaAugmentation);
            _stakeSkeleton(account, tokenId, virtualAlpha);
        }
    }

    /**
     * Stakes a Ranger
     * @param account the address of the staker
     * @param tokenId Id of the Ranger to stake
     */
    function _stakeRanger(address account, uint16 tokenId) internal whenNotPaused _updateEarnings {
        stakes[tokenId] = Stake(account, block.timestamp, uint64(block.timestamp), uint64(block.number), 0);
        totalRangerStaked++;
        emit TokenStaked(account, tokenId);
    }

    /**
     * Stakes a Skeleton
     * @param account the address of the staker
     * @param tokenId Id of the Skeleton to stake
     * @param virtualAlpha Virtual alpha of the skeleton (alpha + level + boost)
     */
    function _stakeSkeleton(address account, uint16 tokenId, uint8 virtualAlpha) internal {
        stakes[tokenId] = Stake(account, glowPerAlpha, 0, 0, 0);
        _addToSkeletonsByAlpha(virtualAlpha, tokenId);
        _addToSkeletonsByOwner(account, tokenId);
        totalAlphaStaked += virtualAlpha;
        totalSkeletonStaked++;
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
        uint16 numberStaked = numberStakedOf[_msgSender()];
        uint256 lastWalletAssociation = pets.lastWalletAssociation(_msgSender());

        if (unstake) numberStakedOf[_msgSender()] -= uint16(tokenIds.length);

        uint256 owed;
        for (uint256 i; i < tokenIds.length;) {
            (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenIds[i]);
            if (isRanger) {
                owed += _claimRanger(
                    tokenIds[i],
                    unstake,
                    level,
                    walletBoost,
                    lastGlowTransfer,
                    numberStaked,
                    lastWalletAssociation
                );
            } else {
                owed += _claimSkeleton(
                    tokenIds[i],
                    unstake,
                    _getVirtualAlpha(alphaIndex, level, walletBoost.alphaAugmentation)
                );
            }
            unchecked{++i;}
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
        uint256 lastWalletAssociation
    ) internal returns (uint256 owed) {
        require(skeleton.ownerOf(tokenId) == address(this), "Not in Magic Forest");

        Stake memory stake = stakes[tokenId];

        require(stake.owner == _msgSender(), "Not your token");

        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        
        owed = _calculateRangerRewards(
            level,
            stake.lastValue,
            walletBoost,
            rangerBoost,
            lastGlowTransfer,
            numberStaked,
            lastWalletAssociation
        ) + stake.unclaimed;

        if (unstake) {
            require(
                block.timestamp - stake.lastClaim >= _getMinimumToExit(rangerBoost.unstakeCooldownAugmentation, walletBoost.globalUnstakeCooldownAugmentation),
                "Need to wait some days before unstake"
            );

            uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(stake.blockNumber), tokenId)));
            if (_isStolen(rangerBoost.stolenProbabilityAugmentation, rangerBoost.stolenProbabilityReduction, walletBoost.globalUnstakeStealAugmentation, seed)) {
                // All $GLOW stolen
                _paySkeletonTax(owed);
                owed = 0;
                emit RangerUnstaked(stake.owner, tokenId, true);
            } else {
                emit RangerUnstaked(stake.owner, tokenId, false);
            }

            skeleton.transferFrom(address(this), _msgSender(), tokenId);
            uint256 petToken = pets.rangerTokenToPetToken(tokenId);
            if (petToken != 0) pets.transferFrom(address(this), _msgSender(), petToken);
            
            delete stakes[tokenId];
            totalRangerStaked--;
        } else {
            uint256 glowTaxed = (owed * _getClaimTaxPercentage(rangerBoost.claimTaxReduction)) / 100;
            _paySkeletonTax(glowTaxed);
            owed -= glowTaxed;
            stakes[tokenId].lastValue = block.timestamp;
            stakes[tokenId].lastClaim = uint64(block.timestamp);
            stakes[tokenId].blockNumber = uint64(block.number);
            stakes[tokenId].unclaimed = 0;
        }
        
        emit TokenClaimed(stake.owner, tokenId, owed, unstake);
    }

    function _claimSkeleton(uint16 tokenId, bool unstake, uint8 virtualAlpha) internal returns (uint256 owed) {
        require(skeleton.ownerOf(tokenId) == address(this), "Not in Magic Forest");

        Stake memory stake = stakes[tokenId];

        require(stake.owner == _msgSender(), "Not your token");

        owed = _calculateSkeletonRewards(virtualAlpha, stake.lastValue) + stake.unclaimed;

        if (unstake) {
            totalAlphaStaked -= virtualAlpha;
            skeleton.transferFrom(address(this), _msgSender(), tokenId);
            _removeFromSkeletonsByAlpha(virtualAlpha, tokenId);
            _removeFromSkeletonsByOwner(stake.owner, tokenId);
            delete stakes[tokenId];
            totalSkeletonStaked--;
        } else {
            stakes[tokenId].lastValue= glowPerAlpha;
            stakes[tokenId].unclaimed = 0;
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

    /* CALLS FROM OTHER CONTRACTS */

    function updateSkeletonStakes(address account, uint8 newAlphaAugmentation, uint8 oldAlphaAugmentation) external {
        require(_msgSender() == address(pets) , "Only for Pets here");
        for (uint256 i; i < skeletonsByOwner[account].length;) {
            uint16 tokenId = skeletonsByOwner[account][i];
            (, uint8 alphaIndex, uint8 level) = getTokenStats(tokenId);
            uint8 oldVirtualAlpha = _getVirtualAlpha(alphaIndex, level, oldAlphaAugmentation);
            uint8 newVirtualAlpha = _getVirtualAlpha(alphaIndex, level, newAlphaAugmentation);
            _updateSkeletonAlpha(tokenId, oldVirtualAlpha, newVirtualAlpha);
            unchecked{++i;}
        }
    }

    function beforeUpgradeLevel(uint16 tokenId) external {
        require(_msgSender() == address(skeleton), "Only for Skeleton here");
        (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenId);
        Stake memory stake = stakes[tokenId];
        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(stake.owner);
        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        if (isRanger) {
            uint256 owed = stakes[tokenId].unclaimed +_calculateRangerRewards(
                level,
                stake.lastValue,
                walletBoost,
                rangerBoost,
                glow.lastTransfer(stake.owner),
                numberStakedOf[stake.owner],
                pets.lastWalletAssociation(stake.owner)
            );
            uint256 maxGlow = _inventoryLimit(level);
            stakes[tokenId].unclaimed =  owed > maxGlow ? maxGlow : owed;
            stakes[tokenId].lastValue = block.timestamp;
        } else {
            uint8 oldVirtualAlpha = _getVirtualAlpha(alphaIndex, level, walletBoost.alphaAugmentation);
            uint8 newVirtualAlpha = _getVirtualAlpha(alphaIndex, level + 1, walletBoost.alphaAugmentation);
            _updateSkeletonAlpha(tokenId, oldVirtualAlpha, newVirtualAlpha);
        }

    }

    function _updateSkeletonAlpha(uint16 tokenId, uint8 oldVirtualAlpha, uint8 newVirtualAlpha) internal {
        _removeFromSkeletonsByAlpha(oldVirtualAlpha, tokenId);
        totalAlphaStaked -= oldVirtualAlpha;
        _addToSkeletonsByAlpha(newVirtualAlpha, tokenId);
        totalAlphaStaked += newVirtualAlpha;
        stakes[tokenId].unclaimed += _calculateSkeletonRewards(oldVirtualAlpha, stakes[tokenId].lastValue);
        stakes[tokenId].lastValue = glowPerAlpha;        
    }

    /* STRUCTURES MANIPULATIONS */

    function _removeFromSkeletonsByAlpha(uint8 alpha, uint16 tokenId) internal {
        uint16 lastTokenId = skeletonsByAlpha[alpha][skeletonsByAlpha[alpha].length - 1];
        skeletonsByAlpha[alpha][skeletonIndices[tokenId].byAlpha] = lastTokenId; // Shuffle last Skeleton to current position
        skeletonIndices[lastTokenId].byAlpha = skeletonIndices[tokenId].byAlpha;
        skeletonsByAlpha[alpha].pop(); // Remove duplicate
        skeletonIndices[tokenId].byAlpha = 0; // Delete old mapping
    }

    function _addToSkeletonsByAlpha(uint8 alpha, uint16 tokenId) internal {
        skeletonIndices[tokenId].byAlpha = uint16(skeletonsByAlpha[alpha].length);
        skeletonsByAlpha[alpha].push(tokenId);
    }

    function _removeFromSkeletonsByOwner(address account, uint16 tokenId) internal {
        uint16 lastTokenId = skeletonsByOwner[account][skeletonsByOwner[account].length - 1];
        skeletonsByOwner[account][skeletonIndices[tokenId].byOwner] = lastTokenId; // Shuffle last Skeleton to current position
        skeletonIndices[lastTokenId].byOwner = skeletonIndices[tokenId].byOwner;
        skeletonsByOwner[account].pop(); // Remove duplicate
        skeletonIndices[tokenId].byOwner = 0; // Delete old mapping
    }

    function _addToSkeletonsByOwner(address account, uint16 tokenId) internal {
        skeletonIndices[tokenId].byOwner = uint16(skeletonsByOwner[account].length);
        skeletonsByOwner[account].push(tokenId);
    }

    /* READING */

    function calculateRewards(uint16 tokenId) external view returns (uint256 owed) {
        Stake memory stake = stakes[tokenId];
        if (stake.owner == address(0)) return 0;
        (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenId);
        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(stake.owner);
        owed = stake.unclaimed;
        if (isRanger) {
            AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
            owed += _calculateRangerRewards(
                level,
                stake.lastValue,
                walletBoost,
                rangerBoost,
                glow.lastTransfer(stake.owner),
                numberStakedOf[stake.owner],
                pets.lastWalletAssociation(stake.owner)
            );
        } else {
            owed += _calculateSkeletonRewards(
                _getVirtualAlpha(alphaIndex, level, walletBoost.alphaAugmentation),
                stake.lastValue
            );
        }
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return stakes[uint16(tokenId)].owner;
    }

    function getActualOwner(uint256 tokenId) public view returns (address) {
        address currentOwner = skeleton.ownerOf(tokenId);
        return currentOwner == address(this) ? getStaker(tokenId) : currentOwner;
    }

    function getDailyGlowRate(uint256 tokenId) external view returns (uint256 dailyGlowRate) {
        (bool isRanger,, uint8 level) = getTokenStats(tokenId);
        if (!isRanger) return 0;
        address tokenOwner = getActualOwner(tokenId);
        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(tokenOwner);
        uint256 lastGlowTransfer = glow.lastTransfer(tokenOwner);
        uint16 numberStaked = numberStakedOf[tokenOwner];
        (, dailyGlowRate) = _getDailyGlowrate(level, walletBoost, rangerBoost, lastGlowTransfer, numberStaked);
    }

    function getClaimTaxPercentage(uint256 tokenId) external view returns(uint256) {
        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        return _getClaimTaxPercentage(rangerBoost.claimTaxReduction);
    }

    function getMinimumToExit(uint256 tokenId) public view returns(uint256){
        (bool isRanger,,) = getTokenStats(tokenId);
        if (!isRanger) return 0;

        address tokenOwner = getActualOwner(tokenId);
        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(tokenOwner);

        return _getMinimumToExit(rangerBoost.unstakeCooldownAugmentation, walletBoost.globalUnstakeCooldownAugmentation);
    }

    function timeRemainingBeforeExit(uint256 tokenId) external view returns (uint256) {
        uint256 minimumToExit = getMinimumToExit(tokenId);
        uint256 lastClaim = stakes[uint16(tokenId)].lastClaim;
        
        if (block.timestamp - lastClaim >= minimumToExit) return 0;
        return minimumToExit - (block.timestamp - lastClaim);
    }

    /**
     * Returns the current claiming fee, depending the current claim frequency.
     * @return claimingFee The current claiming fee.
     */
    function getClaimingFee() public view returns (uint256) {
        if (sessionBegining == 0) return claimingFeeValues[2];
        else if (block.timestamp - sessionBegining > sessionDuration) return claimingFeeValues[0];
        else {
            for (uint256 i; i < 5;) {
                if (lastSessionClaimNumber < claimingFeeTresholds[i]) return claimingFeeValues[i];
                unchecked{++i;}
            }
            return claimingFeeValues[5];
        }
    }

    /**
     * Returns the limit of the inventory of the token.
     * Only Rangers have an inventory limit.
     * For Skeletons, the function returns 0 (even if the limit is +inf).
     * @param tokenId The id of the token.
     * @return inventoryLimit The limit of the inventory of the token.
     */
    function getInventoryLimit(uint256 tokenId) external view returns (uint256) {
        (bool isRanger, uint8 level,) = getTokenStats(tokenId);
        return isRanger ? _inventoryLimit(level) : 0;
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
        if (totalAlphaStaked == 0) return address(0);
        uint256 bucket = seed % totalAlphaStaked;
        uint256 cumulative;
        seed >>= 32;
        
        for (uint8 i; i <= 20;) {
            cumulative += skeletonsByAlpha[i].length * i;
            if (bucket < cumulative) {
                return stakes[skeletonsByAlpha[i][seed % skeletonsByAlpha[i].length]].owner;
            }
            unchecked{++i;}
        }
        return address(0);
    }

    /* INTERNAL COMPUTATIONS */

    function _calculateRangerRewards(
        uint8 level,
        uint256 lastClaim,
        AttributesPets.Boost memory walletBoost,
        AttributesPets.Boost memory rangerBoost,
        uint256 lastGlowTransfer,
        uint16 numberStaked,
        uint256 lastWalletAssociation
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
        uint256 maxGlow = _inventoryLimit(level);
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
        return alphaIndex + alphaAugmentation + level - 1  + (level  == 5 ? 1 : 0);
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
        uint8 unstakeStealAugmentation,
        uint8 unstakeStealReduction,
        uint8 globalUnstakeStealAugmentation,
        uint256 seed
    ) internal pure returns (bool) {
        uint256 treshold = _chanceToGetStolen(unstakeStealAugmentation, unstakeStealReduction, globalUnstakeStealAugmentation);
        return seed % 100 < treshold;
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

    function _inventoryLimit(uint8 level) internal pure returns (uint256) {
        return 5000 ether * level;
    }

    /* TOKEN TRANSFERS */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Cannot send tokens to MagicForest directly");
    }

    /**
     * In case of emergency (dysfunction in the staking) you can rescue your tokens.
     * In the worst case, admins can rescue stuck tokens.
     * @dev Should pause the game before enabling rescue mode.
     * @param tokenIds List of tokens to rescue.
     * @param rescuePets To rescue pets associated or not.
     */
    function emergencyRescue(uint16[] calldata tokenIds, bool rescuePets) external {
        require(rescueEnabled, "Emergency rescue is not enabled");
        address staker;
        for (uint256 i; i < tokenIds.length;) {
            staker = stakes[tokenIds[i]].owner;
            if (staker == address(0)) {
                require(isController(_msgSender()), "Only admins can rescue stuck tokens");
            } else {
                require(staker == _msgSender(), "You did not staked this token");
            }
            skeleton.transferFrom(address(this), _msgSender(), tokenIds[i]);
            if (rescuePets) {
                uint256 petToken = pets.rangerTokenToPetToken(tokenIds[i]);
                if (petToken != 0) pets.transferFrom(address(this), _msgSender(), petToken);
            }
            unchecked{++i;}
        }
    }

    /* MONEY TRANSFERS */

    function withdraw() external onlyController {
        payable(owner()).transfer(address(this).balance);
    }

    function getTokenBalance(address _token) public view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function withdrawToken(address _token) public onlyController {
        IERC20(_token).transferFrom(address(this), owner(), IERC20(_token).balanceOf(address(this)));
    }

    /* GAME MANAGEMENT */

    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    function toggleClaimEnabled() external onlyController {
        claimEnabled = !claimEnabled;
    }

    function toggleRescueEnabled() external onlyController {
        rescueEnabled = !rescueEnabled;
    }

    function setMaximumGlobalGlow(uint256 _maximumGlobalGlow) external onlyController {
        MAXIMUM_GLOBAL_GLOW = _maximumGlobalGlow;
    }

    function setClaimingFees(uint256[] calldata values, uint256[] calldata tresholds, uint32 duration) external onlyController {
        sessionDuration = duration;
        for (uint256 i; i < values.length;) {
            claimingFeeValues[i] = values[i];
            claimingFeeTresholds[i] = tresholds[i];
            unchecked{++i;}
        }
    }

    /* ADDRESSES SETTERS */

    function setGlow(address _glow) public onlyController {
        glow = Glow(_glow);
    }

    function setSkeleton(address _skeleton) public onlyController {
        skeleton = Skeleton(_skeleton);
    }

    function setPets(address _pets) public onlyController {
        pets = Pets(_pets);
    }
}