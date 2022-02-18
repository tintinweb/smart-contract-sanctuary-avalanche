// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Controllable.sol";
import "./Restricted.sol";

import "./Skeleton.sol";
import "./Glow.sol";
import "./AttributesPets.sol";
import "./Pets.sol";

contract MagicForest is Controllable, IERC721Receiver, Pausable, Restricted {
    // maximum alpha score for a Hunter
    uint8 public constant MAX_ALPHA = 10;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address indexed owner, uint256 tokenId, uint256 value);
    event RangerClaimed(uint256 indexed tokenId, uint256 earned, bool unstaked);
    event SkeletonClaimed(uint256 indexed tokenId, uint256 earned, bool unstaked);

    Glow public glow;
    Skeleton public skeleton;
    Pets public pets;

    mapping(address => uint256) public walletToNumberStaked;
    // maps tokenId to stake
    mapping(uint256 => Stake) public barn;
    // maps alpha to all hunter stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Hunter in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no hunters are staked
    uint256 public unaccountedRewards = 0;
    // amount of $GLOW due for each alpha point staked
    uint256 public glowPerAlpha = 0;

    // adventurer earn 5000 $GLOW per day
    uint256 public constant DAILY_GLOW_RATE = 5000 ether;
    // adventurer must have 2 days worth of $GLOW to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // hunters take a 20% tax on all $GLOW claimed
    uint8 public constant GLOW_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $GLOW earned through staking
    uint256 public MAXIMUM_GLOBAL_GLOW = 2400000000 ether;
    //tax on claim
    uint256 public CLAIMING_FEE = 0.01 ether;

    // amount of $GLOW earned so far
    uint256 public totalGlowEarned;
    // number of Adventurer staked in the Barn
    uint256 public totalAdventurerStaked;
    // the last time $GLOW was claimed
    uint256 public lastClaimTimestamp;
    
    /**
     * @param _skeleton reference to the Skeleton NFT contract
     * @param _glow reference to the $GLOW token
     */
    constructor(address _glow, address _skeleton) {
        setGlow(_glow);
        setSkeleton(_skeleton);
    }

    function setMAXIMUM_GLOBAL_GLOW(uint256 _MAXIMUM_GLOBAL_GLOW) external onlyController {
        MAXIMUM_GLOBAL_GLOW = _MAXIMUM_GLOBAL_GLOW;
    }

    function setClaimingFee(uint256 _newfee) external onlyController {
        CLAIMING_FEE = _newfee;
    }


    /** STAKING */

    /**
     * Stakes Rangers and Skeletons in the MagicForest
     * @param tokenIds the IDs of the Rangers and Skeletons to stake
     */
    function stakeMany(uint16[] memory tokenIds) external onlyEOA noReentrency {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stakeOne(_msgSender(), tokenIds[i]);
        }
        walletToNumberStaked[_msgSender()] += tokenIds.length;
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
            uint8 virtualAlpha = _getVirtualAlpha(alphaIndex, level, walletBoost);
            _stakeSkeleton(account, tokenId, virtualAlpha);
        }

        uint256 petId = pets.rangerTokenToPetToken(tokenId);
        if (petId != 0){
            pets.transferFrom(account, address(this), petId);
        }
    }

    /**
     * Stakes a Ranger
     * @dev Rangers go to barn
     * @param account the address of the staker
     * @param tokenId Id of the Ranger to stake
     */
    function _stakeRanger(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        barn[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        totalAdventurerStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * Stakes a Skeleton
     * @dev Skeletons go to pack
     * @param account the address of the staker
     * @param tokenId Id of the Skeleton to stake
     * @param virtualAlpha Virtual alpha of the skeleton (alpha + level + boost)
     */
    function _stakeSkeleton(address account, uint256 tokenId, uint8 virtualAlpha) internal {
        totalAlphaStaked += virtualAlpha; // Portion of earnings ranges from 10 to 5
        packIndices[tokenId] = pack[virtualAlpha].length; // Store the location of the hunter in the Pack
        pack[virtualAlpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(glowPerAlpha)
            })
        ); // Add the skeleton to the Pack
        emit TokenStaked(account, tokenId, glowPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

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
        _updateEarnings
    {
        //payable with the tax
        require(msg.value >= tokenIds.length * CLAIMING_FEE, "You didn't pay tax");

        AttributesPets.Boost memory walletBoost = pets.getWalletBoost(_msgSender());

        if (unstake) walletToNumberStaked[_msgSender()] -= tokenIds.length;

        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenIds[i]);
            if (isRanger) {
                owed += _claimRanger(tokenIds[i], unstake, level, walletBoost);
            } else {
                uint8 virtualAlpha = _getVirtualAlpha(alphaIndex, level, walletBoost);
                owed += _claimSkeleton(tokenIds[i], unstake, virtualAlpha);
            }
        }

        if (owed > 0) glow.mint(_msgSender(), owed);
    }

    function calculateRewards(uint256 tokenId) external view returns (uint256 owed) {
        AttributesPets.Boost memory walletBoost;
        (bool isRanger, uint8 alphaIndex, uint8 level) = getTokenStats(tokenId);
        if (isRanger) {
            AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
            return _calculateRangerRewards(level, barn[tokenId].value, walletBoost, rangerBoost);
        } else {
            uint8 virtualAlpha = _getVirtualAlpha(alphaIndex, level, walletBoost);
            return _calculateSkeletonRewards(virtualAlpha, pack[virtualAlpha][packIndices[tokenId]].value);
        }
    }

    function _calculateRangerRewards(
        uint8 level,
        uint80 stakeValue,
        AttributesPets.Boost memory walletBoost,
        AttributesPets.Boost memory rangerBoost
    ) internal view returns(uint256) {
        uint256 dailyGlowRate = _getDailyGlowrate(level, walletBoost, rangerBoost);

        if (totalGlowEarned < MAXIMUM_GLOBAL_GLOW) {
            return ((block.timestamp - stakeValue) * dailyGlowRate) / 1 days;
        } else if (stakeValue > lastClaimTimestamp) {
            // $GLOW production stopped already
            return 0; 
        } else {
            // Stop earning additional $GLOW if it's all been earned
            return ((lastClaimTimestamp - stakeValue) * dailyGlowRate) / 1 days;
        }
    }

    function _calculateSkeletonRewards(uint8 virtualAlpha, uint80 stakeValue) internal view returns(uint256) {
        return virtualAlpha * (glowPerAlpha - stakeValue);
    }

    /**
     * realize $GLOW earnings for a single Adventurer and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Hunters
     * if unstaking, there is a 50% chance all $GLOW is stolen
     * @param tokenId the ID of the Adventurer to claim earnings from
     * @param unstake whether or not to unstake the Adventurer
     * @return owed - the amount of $GLOW earned
     */
    function _claimRanger(
        uint256 tokenId,
        bool unstake,
        uint8 level,
        AttributesPets.Boost memory walletBoost
    ) internal returns (uint256 owed) {
        require(skeleton.ownerOf(tokenId) == address(this), "Not in Magic Forest");

        Stake memory stake = barn[tokenId];

        require(stake.owner == _msgSender(), "Not your token");

        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);

        owed = _calculateRangerRewards(level, barn[tokenId].value, walletBoost, rangerBoost);

        if (unstake) {
            require(
                block.timestamp - stake.value < _getMinimumToExit(rangerBoost),
                "Need to wait some days before unstake"
            );

            if (isStolen(tokenId, rangerBoost)) {
                // 50% chance of all $GLOW stolen
                _payHunterTax(owed);
                owed = 0;
            }

            skeleton.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Ranger
            uint256 petToken = pets.rangerTokenToPetToken(tokenId);
            if (petToken != 0) {
                pets.transferFrom(address(this), _msgSender(), petToken); // send back the pet
            }
            delete barn[tokenId];
            totalAdventurerStaked--;
        } else {
            uint256 glowClaimtaxPercentage = getClaimTaxPercentage(tokenId);
            _payHunterTax((owed * glowClaimtaxPercentage) / 100); // percentage tax to staked hunters
            owed = (owed * (100 - glowClaimtaxPercentage)) / 100; // remainder goes to Adventurer owner
            barn[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }

        // limit adventurer wage based on their level
        uint256 maxGlow = 5000 ether * level;
        owed = owed > maxGlow ? maxGlow : owed;
        
        emit RangerClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $GLOW earnings for a single Skeleton and optionally unstake it
     * Skeletons earn $GLOW proportional to their Alpha rank and level
     * @param tokenId the ID of the hunter to claim earnings from
     * @param unstake whether or not to unstake the Hunter
     * @return owed - the amount of $GLOW earned
     */
    function _claimSkeleton(uint256 tokenId, bool unstake, uint8 virtualAlpha) internal returns (uint256 owed) {
        require(skeleton.ownerOf(tokenId) == address(this), "Not in Magic Forest");

        Stake memory stake = pack[virtualAlpha][packIndices[tokenId]];

        require(stake.owner == _msgSender(), "Not your token");
        owed = _calculateSkeletonRewards(virtualAlpha, stake.value);
        if (unstake) {
            totalAlphaStaked -= virtualAlpha; // Remove Alpha from total staked
            skeleton.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Hunter
            Stake memory lastStake = pack[virtualAlpha][pack[virtualAlpha].length - 1];
            pack[virtualAlpha][packIndices[tokenId]] = lastStake; // Shuffle last Hunter to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[virtualAlpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
        } else {
            pack[virtualAlpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(glowPerAlpha)
            }); // reset stake
        }
        emit SkeletonClaimed(tokenId, owed, unstake);
    }


    function getClaimTaxPercentage(uint256 tokenId) public view returns(uint256){
        AttributesPets.Boost memory boostToken = pets.getRangerBoost(tokenId);
        assert(boostToken.claimTaxReduction <= 20);
        return GLOW_CLAIM_TAX_PERCENTAGE - boostToken.claimTaxReduction;
    }

    function getClaimTaxPercentage(AttributesPets.Boost memory rangerBoost) internal pure returns(uint8) {
        assert(rangerBoost.claimTaxReduction <= 20);
        return GLOW_CLAIM_TAX_PERCENTAGE - rangerBoost.claimTaxReduction;
    }

    function getMinimumToExit(uint256 tokenId) external view returns(uint256){
        AttributesPets.Boost memory rangerBoost = pets.getRangerBoost(tokenId);
        return _getMinimumToExit(rangerBoost);
    }

    function _getMinimumToExit(AttributesPets.Boost memory rangerBoost) internal pure returns(uint256) {
        return (MINIMUM_TO_EXIT * (100 + rangerBoost.unstakeCooldownAugmentation)) / 100;
    }

    function _getDailyGlowrate(
        uint8 level,
        AttributesPets.Boost memory walletBoost,
        AttributesPets.Boost memory rangerBoost
    ) internal view returns(uint256){
        
        uint256 totalBoost = 100;

        // bonus of increase in $GLOW production
        
        totalBoost += rangerBoost.productionSpeed;

        // increase adventurer wage based on their level
        if(level == 2){
            totalBoost += 5;
        }else if(level == 3){
            totalBoost += 10;
        }else if(level == 4){
            totalBoost += 20;
        }else if(level == 5){
            totalBoost += 30;
        }

        // bonus based on the number of nfts staked
        if(walletToNumberStaked[_msgSender()] <= 5){
            totalBoost += rangerBoost.productionSpeedByNFTStaked[0];
        }else if (walletToNumberStaked[_msgSender()] <= 10){
            totalBoost += rangerBoost.productionSpeedByNFTStaked[1];
        }else if (walletToNumberStaked[_msgSender()] <= 20){
            totalBoost += rangerBoost.productionSpeedByNFTStaked[2];
        }else{
            totalBoost += rangerBoost.productionSpeedByNFTStaked[3];
        }

        uint256 lastTransferTime = glow.lastTransfer(_msgSender());

        if(block.timestamp  - lastTransferTime <= 1 days){
            totalBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[0];
        }else if (block.timestamp  - lastTransferTime <= 2 days){
            totalBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[1];
        }else if (block.timestamp  - lastTransferTime <= 3 days){
            totalBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[2];
        }else{
            totalBoost += rangerBoost.productionSpeedByTimeWithoutTransfer[3];
        }

        totalBoost += walletBoost.globalProductionSpeed;

        if(walletToNumberStaked[_msgSender()] <= 9){
            totalBoost += rangerBoost.globalProductionSpeedByNFTStaked[0];
        }else if (walletToNumberStaked[_msgSender()] <= 19){
            totalBoost += rangerBoost.globalProductionSpeedByNFTStaked[1];
        }else if (walletToNumberStaked[_msgSender()] <= 29){
            totalBoost += rangerBoost.globalProductionSpeedByNFTStaked[2];
        }else{
            totalBoost += rangerBoost.globalProductionSpeedByNFTStaked[3];
        }


        uint256 dailyGlowRate = DAILY_GLOW_RATE * totalBoost / 100;

        return dailyGlowRate;

    }


    /**
     * add $GLOW to claimable pot for the Pack
     * @param amount $GLOW to add to the pot
     */
    function _payHunterTax(uint256 amount) internal {
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
     * tracks $GLOW earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalGlowEarned < MAXIMUM_GLOBAL_GLOW) {
            totalGlowEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalAdventurerStaked *
                    DAILY_GLOW_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */


    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyController {
        if (_paused) _pause();
        else _unpause();
    }

    function setGlow(address _glow) public onlyController {
        glow = Glow(_glow);
    }

    function setSkeleton(address _skeleton) public onlyController {
        skeleton = Skeleton(_skeleton);
    }

    /** READ ONLY */

    function getTokenStats(uint256 tokenId) public view returns(bool isRanger, uint8 alphaIndex, uint8 level) {
        (isRanger, , , , , , , , alphaIndex, level) = skeleton.tokenTraits(tokenId);
    }

    /**
     * Computes the alpha score used for rewards computation
     * @param alphaIndex Actual alpha score
     * @param level Level of the skeleton
     * @param walletBoost Wallet boost of the pet equiped
     * @return the virtual alpha score
     */
    function _getVirtualAlpha(
        uint8 alphaIndex,
        uint8 level,
        AttributesPets.Boost memory walletBoost
    ) internal pure returns (uint8) {
        uint8 alphaFromLevel = level - 1  + (level  == 5 ? 1 : 0);
        return MAX_ALPHA - alphaIndex + walletBoost.alphaAugmentation + alphaFromLevel; // alpha index is 0-3
    }

    /*
     * chooses a random Hunter thief when a newly minted token is stolen
     * @param seed a random value to choose a Hunter from
     * @return the owner of the randomly selected Hunter thief
     */
    function randomHunterOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Hunters with the same alpha score
        for (uint256 i = 0; i <= 20; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Hunter with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param tokenId a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function isStolen(uint256 tokenId, AttributesPets.Boost memory rangerBoost) internal view returns (bool) {
        uint256 randomNumber =  uint256(keccak256(abi.encodePacked(_msgSender(), blockhash(block.number - 1), tokenId)));
        uint256 treshold = _chanceToGetStolen(rangerBoost);
        return uint16(randomNumber & 0xFFFF) % 100 < treshold;
    }

    function _chanceToGetStolen(AttributesPets.Boost memory rangerBoost) internal pure returns(uint8) {
        return 50 - rangerBoost.unstakeStealReduction + rangerBoost.unstakeStealAugmentation;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdraw() external onlyController {
        payable(owner()).transfer(address(this).balance);
    }

    function setPets(address _pets) public onlyController{
        pets = Pets(_pets);
    }
    
}