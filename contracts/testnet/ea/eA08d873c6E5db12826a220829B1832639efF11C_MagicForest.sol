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

    //PIPICACA IL FAUT FAIRE UN MAPPING ADDDR -> nombre NFT STAKED

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event AdventurerClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event HunterClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the Hunter NFT contract
    Skeleton public skeleton;
    // reference to the $GLOW contract for minting $GLOW earnings
    Glow public glow;

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
    uint256 public constant GLOW_CLAIM_TAX_PERCENTAGE = 20;
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


    Pets public pets;
    


    /**
     * @param _skeleton reference to the Skeleton NFT contract
     * @param _glow reference to the $GLOW token
     */
    constructor(address _glow, address _skeleton) {
        setGlow(_glow);
        setSkeleton(_skeleton);
    }

    function setMAXIMUM_GLOBAL_GLOW(uint256 _MAXIMUM_GLOBAL_GLOW)
        external
        onlyController
    {
        MAXIMUM_GLOBAL_GLOW = _MAXIMUM_GLOBAL_GLOW;
    }

    //if its wrong
    function setClaimingFee(uint256 _newfee) external onlyController {
        CLAIMING_FEE = _newfee;
    }



    /** STAKING */

    /**
     * Adds Adventurers and Hunters to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Adventurer and Hunters to stake
     */
    function addManyToBarnAndPack(address account, uint16[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            addToBarnAndPack(account, tokenIds[i]);
        }
    }

    /**
     * Adds one Adventurer or Hunter to the Barn or Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Adventurer or Hunter to stake
     */
    function addToBarnAndPack(address account, uint16 tokenId) public onlyEOA noReentrency {
        require(
            (account == _msgSender() && account == tx.origin) ||
                _msgSender() == address(skeleton),
            "DONT GIVE YOUR TOKENS AWAY"
        );
        
        if (_msgSender() != address(skeleton)) {
            // dont do this step if its a mint + stake
            require(
                skeleton.ownerOf(tokenId) == _msgSender(),
                "AINT YO TOKEN"
            );
            skeleton.transferFrom(_msgSender(), address(this), tokenId);
        }

        if (isRanger(tokenId))
            _addAdventurerToBarn(account, tokenId);
        else _addHunterToPack(account, tokenId);

        uint256 petId = pets.rangerTokenToPetToken(tokenId);
        if(petId != 0){
            pets.transferFrom(_msgSender(), address(this), petId);
        }

        walletToNumberStaked[_msgSender()] ++;

    }

    /**
     * adds a single Adventurer to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Adventurer to add to the Barn
     */
    function _addAdventurerToBarn(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        barn[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        totalAdventurerStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Hunter to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Hunter to add to the Pack
     */
    function _addHunterToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForHunter(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 10 to 5
        packIndices[tokenId] = pack[alpha].length; // Store the location of the hunter in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(glowPerAlpha)
            })
        ); // Add the hunter to the Pack
        emit TokenStaked(account, tokenId, glowPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $GLOW earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Adventurer it will require it has 2 days worth of $GLOW unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromBarnAndPack(uint16[] memory tokenIds, bool unstake)
        external
        payable
        whenNotPaused
        onlyEOA
        noReentrency 
        _updateEarnings
    {
        //payable with the tax
        require(
            msg.value >= tokenIds.length * CLAIMING_FEE,
            "you didnt pay tax"
        );
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(unstake) walletToNumberStaked[_msgSender()]--;
            if (isRanger(tokenIds[i]))
                owed += _claimAdventurerFromBarn(tokenIds[i], unstake);
            else owed += _claimHunterFromPack(tokenIds[i], unstake);
        }
        //fee transfer

        if (owed == 0) return;
        glow.mint(_msgSender(), owed);
    }

    function calculateRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        if (skeleton.getTokenTraits(tokenId).isRanger) {
            Stake memory stake = barn[tokenId];
            if (totalGlowEarned < MAXIMUM_GLOBAL_GLOW) {
                owed =
                    ((block.timestamp - stake.value) * DAILY_GLOW_RATE) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0; // $GLOW production stopped already
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * DAILY_GLOW_RATE) /
                    1 days; // stop earning additional $GLOW if it's all been earned
            }
        } else {
            uint256 alpha = _alphaForHunter(tokenId);
            Stake memory stake = pack[alpha][packIndices[tokenId]];
            owed = (alpha) * (glowPerAlpha - stake.value);
        }
    }

    /**
     * realize $GLOW earnings for a single Adventurer and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Hunters
     * if unstaking, there is a 50% chance all $GLOW is stolen
     * @param tokenId the ID of the Adventurer to claim earnings from
     * @param unstake whether or not to unstake the Adventurer
     * @return owed - the amount of $GLOW earned
     */
    function _claimAdventurerFromBarn(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = barn[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(
            !(unstake && block.timestamp - stake.value < getMinimumToExit(tokenId)),
            "GONNA BE COLD WITHOUT TWO DAY'S GLOW"
        );

        uint256 dailyGlowRate = getDailyGlowrate(tokenId);
        uint256 glowClaimtaxPercentage = getClaimTaxPercentage(tokenId);

        if (totalGlowEarned < MAXIMUM_GLOBAL_GLOW) {
            owed = ((block.timestamp - stake.value) * dailyGlowRate) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $GLOW production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * dailyGlowRate) /
                1 days; // stop earning additional $GLOW if it's all been earned
        }
        if (unstake) {
            if (isStolen(tokenId)) {
                // 50% chance of all $GLOW stolen
                _payHunterTax(owed);
                owed = 0;
            }
            skeleton.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Adventurer
            uint256 petToken = pets.rangerTokenToPetToken(tokenId);
            if(petToken != 0){
                pets.transferFrom(address(this), _msgSender(), petToken);
            }
            delete barn[tokenId];
            totalAdventurerStaked -= 1;
        } else {
            _payHunterTax((owed * glowClaimtaxPercentage) / 100); // percentage tax to staked hunters
            owed = (owed * (100 - glowClaimtaxPercentage)) / 100; // remainder goes to Adventurer owner
            barn[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }


        // limit adventurer wage based on their level
        uint8 level = getLevel(tokenId);
        uint256 maxGlow = 5000 ether * level;
        if(owed > maxGlow){
            owed = maxGlow;
        }
        
        emit AdventurerClaimed(tokenId, owed, unstake);
    }


    function getClaimTaxPercentage(uint256 tokenId) public view returns(uint256){
        AttributesPets.Boost memory boostToken = pets.getBoostToken(tokenId);
        assert(boostToken.claimTaxReduction <= 20);
        return GLOW_CLAIM_TAX_PERCENTAGE - boostToken.claimTaxReduction;
    }



    function getMinimumToExit(uint256 tokenId) public view returns(uint256){
            AttributesPets.Boost memory boostToken = pets.getBoostToken(tokenId);
            return (MINIMUM_TO_EXIT * (100+boostToken.unstakeCooldownAugmentation))/100;
    }

    function getDailyGlowrate(uint256 tokenId) public view returns(uint256){
        
        uint256 totalBoost = 100;

        // bonus of increase in $GLOW production
        
        AttributesPets.Boost memory boostToken = pets.getBoostToken(tokenId);
        totalBoost += boostToken.productionSpeed;

        // increase adventurer wage based on their level
        uint8 level = getLevel(tokenId); //CHIER 
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
            totalBoost += boostToken.productionSpeedByNFTStaked[0];
        }else if (walletToNumberStaked[_msgSender()] <= 10){
            totalBoost += boostToken.productionSpeedByNFTStaked[1];
        }else if (walletToNumberStaked[_msgSender()] <= 20){
            totalBoost += boostToken.productionSpeedByNFTStaked[2];
        }else{
            totalBoost += boostToken.productionSpeedByNFTStaked[3];
        }

        uint256 lastTransferTime = glow.lastTransfer(_msgSender());

        if(block.timestamp  - lastTransferTime <= 1 days){
            totalBoost += boostToken.productionSpeedByTimeWithoutTransfer[0];
        }else if (block.timestamp  - lastTransferTime <= 2 days){
            totalBoost += boostToken.productionSpeedByTimeWithoutTransfer[1];
        }else if (block.timestamp  - lastTransferTime <= 3 days){
            totalBoost += boostToken.productionSpeedByTimeWithoutTransfer[2];
        }else{
            totalBoost += boostToken.productionSpeedByTimeWithoutTransfer[3];
        }

        AttributesPets.Boost memory boostWallet = pets.getBoostWallet(msg.sender);
        totalBoost += boostWallet.globalProductionSpeed;

        if(walletToNumberStaked[_msgSender()] <= 9){
            totalBoost += boostToken.globalProductionSpeedByNFTStaked[0];
        }else if (walletToNumberStaked[_msgSender()] <= 19){
            totalBoost += boostToken.globalProductionSpeedByNFTStaked[1];
        }else if (walletToNumberStaked[_msgSender()] <= 29){
            totalBoost += boostToken.globalProductionSpeedByNFTStaked[2];
        }else{
            totalBoost += boostToken.globalProductionSpeedByNFTStaked[3];
        }


        uint256 dailyGlowRate = DAILY_GLOW_RATE * totalBoost / 100;

        return dailyGlowRate;

    }


    /**
     * realize $GLOW earnings for a single Hunter and optionally unstake it
     * Hunters earn $GLOW proportional to their Alpha rank
     * @param tokenId the ID of the hunter to claim earnings from
     * @param unstake whether or not to unstake the Hunter
     * @return owed - the amount of $GLOW earned
     */
    function _claimHunterFromPack(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            skeleton.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PACK"
        );
        uint256 alpha = _alphaForHunter(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (glowPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            skeleton.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Hunter
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Hunter to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(glowPerAlpha)
            }); // reset stake
        }
        emit HunterClaimed(tokenId, owed, unstake);
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


    function isRanger(uint256 tokenId)
        public
        view
        returns (bool ranger)
    {
        (ranger, , , , , , , , , ) = skeleton.tokenTraits(tokenId);
    }

    function getLevel(uint256 tokenId)
        public
        view
        returns (uint8 level)
    {
        (, , , , , , , , , level) = skeleton.tokenTraits(tokenId);
    }

    /**
     * gets the alpha score for a Hunter
     * @param tokenId the ID of the Hunter to get the alpha score for
     * @return the alpha score of the Hunter (5-8)
     */
    function _alphaForHunter(uint256 tokenId) internal view returns (uint8) {
        (, , , , , , , , , uint8 alphaIndex) = skeleton.tokenTraits(tokenId);
        AttributesPets.Boost memory boostWallet = pets.getBoostWallet(msg.sender); 
        uint8 alphaFromLevel = getLevel(tokenId)  + (getLevel(tokenId)  == 5 ? 1 : 0) - 1;

        return MAX_ALPHA - alphaIndex + boostWallet.alphaAugmentation + alphaFromLevel; // alpha index is 0-3
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
    function isStolen(uint256 tokenId) internal view returns (bool) {
        AttributesPets.Boost memory boostToken = pets.getBoostToken(tokenId);
        
        uint256 randomNumber =  uint256(keccak256(abi.encodePacked(msg.sender,blockhash(block.number - 1), block.timestamp, tokenId)));
        uint256 treshold = 50 - boostToken.unstakeStealReduction + boostToken.unstakeStealAugmentation;
        return uint16(randomNumber & 0xFFFF) % 100 < treshold;
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