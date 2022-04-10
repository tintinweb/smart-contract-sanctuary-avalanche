//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

import "./Farmer.sol";
import "./Upgrade.sol";
import "./Crop.sol";
import "./FarmProgressionV3.sol";
import "./LocustGod.sol";

contract FarmV3 is FarmProgressionV3, ReentrancyGuard {
    using SafeMath for uint256;

    // Constants
    uint256 public constant CLAIM_CROP_CONTRIBUTION_PERCENTAGE = 10;
    uint256 public constant CLAIM_CROP_BURN_PERCENTAGE = 10;
    uint256 public MAX_FATIGUE = 200000000000000;

    uint256 public yieldPPS = 16666666666666666; // crop cooked per second per unit of yield

    uint256 public startTime;

    // Staking

    struct StakedFarmer {
        address owner;
        uint256 tokenId;
        uint256 startTimestamp;
        bool staked;
    }

    struct StakedFarmerInfo {
        uint256 farmersId;
        uint256 upgradeId;
        uint256 farmersPPM;
        uint256 upgradePPM;
        uint256 crop;
        uint256 fatigue;
        uint256 timeUntilFatigued;
    }

    mapping(uint256 => StakedFarmer) public stakedFarmers; // tokenId => StakedFarmer
    mapping(address => mapping(uint256 => uint256)) private ownedFarmerStakes; // (address, index) => tokenid
    mapping(uint256 => uint256) private ownedFarmerStakesIndex; // tokenId => index in its owner's stake list
    mapping(address => uint256) public ownedFarmerStakesBalance; // address => stake count

    mapping(address => uint256) public fatiguePerMinute; // address => fatigue per minute in the farm
    mapping(uint256 => uint256) private farmersFatigue; // tokenId => fatigue
    mapping(uint256 => uint256) private farmersCrop; // tokenId => crop

    mapping(address => uint256[2]) private numberOfFarmers; // address => [number of regular Farmers, number of owners]
    mapping(address => uint256) private totalPPM; // address => total PPM

    struct StakedUpgrade {
        address owner;
        uint256 tokenId;
        bool staked;
    }

    mapping(uint256 => StakedUpgrade) public stakedUpgrades; // tokenId => StakedUpgrade
    mapping(address => mapping(uint256 => uint256)) private ownedUpgradeStakes; // (address, index) => tokenid
    mapping(uint256 => uint256) private ownedUpgradeStakesIndex; // tokenId => index in its owner's stake list
    mapping(address => uint256) public ownedUpgradeStakesBalance; // address => stake count

    // Fatigue cooldowns

    struct RestingFarmer {
        address owner;
        uint256 tokenId;
        uint256 endTimestamp;
        bool present;
    }

    struct RestingFarmerInfo {
        uint256 tokenId;
        uint256 endTimestamp;
    }
    
    mapping(uint256 => RestingFarmer) public restingFarmers; // tokenId => RestingFarmer
    mapping(address => mapping(uint256 => uint256)) private ownedRestingFarmers; // (user, index) => resting farmers id
    mapping(uint256 => uint256) private restingFarmersIndex; // tokenId => index in its owner's cooldown list
    mapping(address => uint256) public restingFarmersBalance; // address => cooldown count

    // Var

    Farmer public farmers;
    Upgrade public upgrade;
    Crop public crop;
    LocustGod public locustgod;
    address public barnAddress;
    
    constructor(Farmer _farmers, Upgrade _upgrade, Crop _crop, Milk _milk, LocustGod _locustgod, address _barnAddress) FarmProgressionV3 (_milk) {
        farmers = _farmers;
        upgrade = _upgrade;
        crop = _crop;
        locustgod = _locustgod;
        barnAddress = _barnAddress;
    }

    // Views

    function _getUpgradeStakedForFarmer(address _owner, uint256 _farmersId) internal view returns (uint256) {
        uint256 index = ownedFarmerStakesIndex[_farmersId];
        return ownedUpgradeStakes[_owner][index];
    }

    function getFatiguePerMinuteWithModifier(address _owner) public view returns (uint256) {
        uint256 fatigueSkillModifier = getFatigueSkillModifier(_owner);
        return fatiguePerMinute[_owner].mul(fatigueSkillModifier).div(100);
    }

    function _getLandOwnerNumber(address _owner) internal view returns (uint256) {
        return numberOfFarmers[_owner][1];
    }

    /**
     * Returns the current farmers's fatigue
     */
    function getFatigueAccruedForFarmer(uint256 _tokenId, bool checkOwnership) public view returns (uint256) {
        StakedFarmer memory stakedFarmer = stakedFarmers[_tokenId];
        require(stakedFarmer.staked, "This token isn't staked");
        if (checkOwnership) {
            require(stakedFarmer.owner == _msgSender(), "You don't own this token");
        }

        uint256 fatigue = (block.timestamp - stakedFarmer.startTimestamp) * getFatiguePerMinuteWithModifier(stakedFarmer.owner) / 60;
        fatigue += farmersFatigue[_tokenId];
        if (fatigue > MAX_FATIGUE) {
            fatigue = MAX_FATIGUE;
        }
        return fatigue;
    }

    /**
     * Returns the timestamp of when the farmers will be fatigued
     */
    function timeUntilFatiguedCalculation(uint256 _startTime, uint256 _fatigue, uint256 _fatiguePerMinute) public view returns (uint256) {
        return _startTime + 60 * ( MAX_FATIGUE - _fatigue ) / _fatiguePerMinute;
    }

    function getTimeUntilFatigued(uint256 _tokenId, bool checkOwnership) public view returns (uint256) {
        StakedFarmer memory stakedFarmer = stakedFarmers[_tokenId];
        require(stakedFarmer.staked, "This token isn't staked");
        if (checkOwnership) {
            require(stakedFarmer.owner == _msgSender(), "You don't own this token");
        }
        return timeUntilFatiguedCalculation(stakedFarmer.startTimestamp, farmersFatigue[_tokenId], getFatiguePerMinuteWithModifier(stakedFarmer.owner));
    }

    /**
     * Returns the timestamp of when the farmers will be fully rested
     */
     function restingTimeCalculation(uint256 _farmersType, uint256 _landOwnerType, uint256 _fatigue) public view returns (uint256) {
        uint256 maxTime = 43200; //12*60*60
        if( _farmersType == _landOwnerType){
            maxTime = maxTime / 2; // owners rest half of the time of regular Farmers
        }

        if(_fatigue > MAX_FATIGUE / 2){
            return maxTime * _fatigue / MAX_FATIGUE;
        }

        return maxTime / 2; // minimum rest time is half of the maximum time
    }
    function getRestingTime(uint256 _tokenId, bool checkOwnership) public view returns (uint256) {
        StakedFarmer memory stakedFarmer = stakedFarmers[_tokenId];
        require(stakedFarmer.staked, "This token isn't staked");
        if (checkOwnership) {
            require(stakedFarmer.owner == _msgSender(), "You don't own this token");
        }

        return restingTimeCalculation(farmers.getType(_tokenId), farmers.LAND_OWNER_TYPE(), getFatigueAccruedForFarmer(_tokenId, false));
    }

    function getCropAccruedForManyFarmers(uint256[] calldata _tokenIds) public view returns (uint256[] memory) {
        uint256[] memory output = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            output[i] = getCropAccruedForFarmer(_tokenIds[i], false);
        }
        return output;
    }

    /**
     * Returns farmers's crop from farmersCrop mapping
     */
     function cropAccruedCalculation(uint256 _initialCrop, uint256 _deltaTime, uint256 _ppm, uint256 _modifier, uint256 _fatigue, uint256 _fatiguePerMinute, uint256 _yieldPPS) public view returns (uint256) {
        if(_fatigue >= MAX_FATIGUE){
            return _initialCrop;
        }

        uint256 a = _deltaTime * _ppm * _yieldPPS * _modifier * (MAX_FATIGUE - _fatigue) / ( 100 * MAX_FATIGUE);
        uint256 b = _deltaTime * _deltaTime * _ppm * _yieldPPS * _modifier * _fatiguePerMinute / (100 * 2 * 60 * MAX_FATIGUE);
        if(a > b){
            return _initialCrop + a - b;
        }

        return _initialCrop;
    }
    function getCropAccruedForFarmer(uint256 _tokenId, bool checkOwnership) public view returns (uint256) {
        StakedFarmer memory stakedFarmer = stakedFarmers[_tokenId];
        address owner = stakedFarmer.owner;
        require(stakedFarmer.staked, "This token isn't staked");
        if (checkOwnership) {
            require(owner == _msgSender(), "You don't own this token");
        }

        // if farmersFatigue = MAX_FATIGUE it means that farmersCrop already has the correct value for the crop, since it didn't produce crop since last update
        uint256 farmersFatigueLastUpdate = farmersFatigue[_tokenId];
        if(farmersFatigueLastUpdate == MAX_FATIGUE){
            return farmersCrop[_tokenId];
        }

        uint256 timeUntilFatigued = getTimeUntilFatigued(_tokenId, false);

        uint256 endTimestamp;
        if(block.timestamp >= timeUntilFatigued){
            endTimestamp = timeUntilFatigued;
        } else {
            endTimestamp = block.timestamp;
        }

        uint256 ppm = farmers.getYield(_tokenId);
        uint256 upgradeId = _getUpgradeStakedForFarmer(owner, _tokenId);

        if(upgradeId > 0){
            ppm += upgrade.getYield(upgradeId);
        }

        uint256 landOwnerSkillModifier = getLandOwnerSkillModifier(owner, _getLandOwnerNumber(owner));

        uint256 delta = endTimestamp - stakedFarmer.startTimestamp;

        return cropAccruedCalculation(farmersCrop[_tokenId], delta, ppm, landOwnerSkillModifier, farmersFatigueLastUpdate, getFatiguePerMinuteWithModifier(owner), yieldPPS);
    }

    /**
     * Calculates the total PPM staked for a farm. 
     * This will also be used in the fatiguePerMinute calculation
     */
    function getTotalPPM(address _owner) public view returns (uint256) {
        return totalPPM[_owner];
    }

    function gameStarted() public view returns (bool) {
        return startTime != 0 && block.timestamp >= startTime;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require (_startTime >= block.timestamp, "startTime cannot be in the past");
        require(!gameStarted(), "game already started");
        startTime = _startTime;
    }

    /**
     * Updates the Fatigue per Minute
     * This function is called in _updateState
     */

    function fatiguePerMinuteCalculation(uint256 _ppm) public pure returns (uint256) {
        // NOTE: fatiguePerMinute[_owner] = 8610000000 + 166000000  * totalPPM[_owner] + -220833 * totalPPM[_owner]* totalPPM[_owner]  + 463 * totalPPM[_owner]*totalPPM[_owner]*totalPPM[_owner]; 
        uint256 a = 463;
        uint256 b = 220833;
        uint256 c = 166000000;
        uint256 d = 8610000000;
        if(_ppm == 0){
            return d;
        }
        return d + c * _ppm + a * _ppm * _ppm * _ppm - b * _ppm * _ppm;
    }

    function _updatefatiguePerMinute(address _owner) internal {
        fatiguePerMinute[_owner] = fatiguePerMinuteCalculation(totalPPM[_owner]);
    }

    /**
     * This function updates farmersCrop and farmersFatigue mappings
     * Calls _updatefatiguePerMinute
     * Also updates startTimestamp for Farmers
     * It should be used whenever the PPM changes
     */
    function _updateState(address _owner) internal {
        uint256 farmersBalance = ownedFarmerStakesBalance[_owner];
        for (uint256 i = 0; i < farmersBalance; i++) {
            uint256 tokenId = ownedFarmerStakes[_owner][i];
            StakedFarmer storage stakedFarmer = stakedFarmers[tokenId];
            if (stakedFarmer.staked && block.timestamp > stakedFarmer.startTimestamp) {
                farmersCrop[tokenId] = getCropAccruedForFarmer(tokenId, false);

                farmersFatigue[tokenId] = getFatigueAccruedForFarmer(tokenId, false);

                stakedFarmer.startTimestamp = block.timestamp;
            }
        }
        _updatefatiguePerMinute(_owner);
    }

    //Claim
    function _claimCrop(address _owner) internal {
        uint256 totalClaimed = 0;

        uint256 barnSkillModifier = getBarnSkillModifier(_owner);
        uint256 burnSkillModifier = getBurnSkillModifier(_owner);

        uint256 farmersBalance = ownedFarmerStakesBalance[_owner];

        for (uint256 i = 0; i < farmersBalance; i++) {
            uint256 farmersId = ownedFarmerStakes[_owner][i];

            totalClaimed += getCropAccruedForFarmer(farmersId, true); // also checks that msg.sender owns this token

            delete farmersCrop[farmersId];

            farmersFatigue[farmersId] = getFatigueAccruedForFarmer(farmersId, false); // bug fix for fatigue

            stakedFarmers[farmersId].startTimestamp = block.timestamp;
        }

        uint256 taxAmountBarn = totalClaimed * (CLAIM_CROP_CONTRIBUTION_PERCENTAGE - barnSkillModifier) / 100;
        uint256 taxAmountBurn = totalClaimed * (CLAIM_CROP_BURN_PERCENTAGE - burnSkillModifier) / 100;

        totalClaimed = totalClaimed - taxAmountBarn - taxAmountBurn;
        if (!locustgod.isLocustActive()) {
            crop.mint(_msgSender(), totalClaimed);
            crop.mint(barnAddress, taxAmountBarn);
        }
        locustgod.checkAndStart();
    }

    function claimCrop() public nonReentrant whenNotPaused {
        address owner = _msgSender();
        _claimCrop(owner);
    }

    function unstakeFarmersAndUpgrades(uint256[] calldata _farmersIds, uint256[] calldata _upgradeIds) public nonReentrant whenNotPaused {
        address owner = _msgSender();
        // Check 1:1 correspondency between farmers and upgrade
        require(ownedFarmerStakesBalance[owner] - _farmersIds.length >= ownedUpgradeStakesBalance[owner] - _upgradeIds.length, "Needs at least farmers for each tool");

        _claimCrop(owner);
        
        for (uint256 i = 0; i < _upgradeIds.length; i++) { //unstake upgrades
            uint256 upgradeId = _upgradeIds[i];

            require(stakedUpgrades[upgradeId].owner == owner, "You don't own this tool");
            require(stakedUpgrades[upgradeId].staked, "Tool needs to be staked");

            totalPPM[owner] -= upgrade.getYield(upgradeId);
            upgrade.transferFrom(address(this), owner, upgradeId);

            _removeUpgrade(upgradeId);
        }

        for (uint256 i = 0; i < _farmersIds.length; i++) { //unstake Farmers
            uint256 farmersId = _farmersIds[i];

            require(stakedFarmers[farmersId].owner == owner, "You don't own this token");
            require(stakedFarmers[farmersId].staked, "Farmer needs to be staked");

            if(farmers.getType(farmersId) == farmers.LAND_OWNER_TYPE()){
                numberOfFarmers[owner][1]--; 
            } else {
                numberOfFarmers[owner][0]--; 
            }

            totalPPM[owner] -= farmers.getYield(farmersId);

            _moveFarmerToCooldown(farmersId);
        }

        _updateState(owner);
    }

    // Stake

     /**
     * This function updates stake Farmers and upgrades
     * The upgrades are paired with the farmers the upgrade will be applied
     */
    function stakeMany(uint256[] calldata _farmersIds, uint256[] calldata _upgradeIds) public nonReentrant whenNotPaused {
        require(gameStarted(), "The game has not started");

        address owner = _msgSender();

        uint256 maxNumberFarmers = getMaxNumberFarmers(owner);
        uint256 FarmersAfterStaking = _farmersIds.length + numberOfFarmers[owner][0] + numberOfFarmers[owner][1];
        require(maxNumberFarmers >= FarmersAfterStaking, "You can't stake that many Farmers");

        // Check 1:1 correspondency between farmers and upgrade
        require(ownedFarmerStakesBalance[owner] + _farmersIds.length >= ownedUpgradeStakesBalance[owner] + _upgradeIds.length, "Needs at least farmers for each tool");

        _claimCrop(owner); // Fix bug for incorrect time for upgrades

        for (uint256 i = 0; i < _farmersIds.length; i++) { //stakes farmers
            uint256 farmersId = _farmersIds[i];

            require(farmers.ownerOf(farmersId) == owner, "You don't own this token");
            require(farmers.getType(farmersId) > 0, "Farmer not yet revealed");
            require(!stakedFarmers[farmersId].staked, "Farmer is already staked");

            _addFarmerToFarm(farmersId, owner);

            if(farmers.getType(farmersId) == farmers.LAND_OWNER_TYPE()){
                numberOfFarmers[owner][1]++; 
            } else {
                numberOfFarmers[owner][0]++; 
            }

            totalPPM[owner] += farmers.getYield(farmersId);

            farmers.transferFrom(owner, address(this), farmersId);
        }
        uint256 maxLevelUpgrade = getMaxLevelUpgrade(owner);
        for (uint256 i = 0; i < _upgradeIds.length; i++) { //stakes upgrades
            uint256 upgradeId = _upgradeIds[i];

            require(upgrade.ownerOf(upgradeId) == owner, "You don't own this tool");
            require(!stakedUpgrades[upgradeId].staked, "Tool is already staked");
            require(upgrade.getLevel(upgradeId) <= maxLevelUpgrade, "You can't equip that tool");

            upgrade.transferFrom(owner, address(this), upgradeId);
            totalPPM[owner] += upgrade.getYield(upgradeId);

             _addUpgradeToFarm(upgradeId, owner);
        }
        _updateState(owner);
    }

    function _addFarmerToFarm(uint256 _tokenId, address _owner) internal {
        stakedFarmers[_tokenId] = StakedFarmer({
            owner: _owner,
            tokenId: _tokenId,
            startTimestamp: block.timestamp,
            staked: true
        });
        _addStakeToOwnerEnumeration(_owner, _tokenId);
    }

    function _addUpgradeToFarm(uint256 _tokenId, address _owner) internal {
        stakedUpgrades[_tokenId] = StakedUpgrade({
            owner: _owner,
            tokenId: _tokenId,
            staked: true
        });
        _addUpgradeToOwnerEnumeration(_owner, _tokenId);
    }


    function _addStakeToOwnerEnumeration(address _owner, uint256 _tokenId) internal {
        uint256 length = ownedFarmerStakesBalance[_owner];
        ownedFarmerStakes[_owner][length] = _tokenId;
        ownedFarmerStakesIndex[_tokenId] = length;
        ownedFarmerStakesBalance[_owner]++;
    }

    function _addUpgradeToOwnerEnumeration(address _owner, uint256 _tokenId) internal {
        uint256 length = ownedUpgradeStakesBalance[_owner];
        ownedUpgradeStakes[_owner][length] = _tokenId;
        ownedUpgradeStakesIndex[_tokenId] = length;
        ownedUpgradeStakesBalance[_owner]++;
    }

    function _moveFarmerToCooldown(uint256 _farmersId) internal {
        address owner = stakedFarmers[_farmersId].owner;

        uint256 endTimestamp = block.timestamp + getRestingTime(_farmersId, false);
        restingFarmers[_farmersId] = RestingFarmer({
            owner: owner,
            tokenId: _farmersId,
            endTimestamp: endTimestamp,
            present: true
        });

        delete farmersFatigue[_farmersId];
        delete stakedFarmers[_farmersId];
        _removeStakeFromOwnerEnumeration(owner, _farmersId);
        _addCooldownToOwnerEnumeration(owner, _farmersId);
    }

    // Cooldown
    function _removeUpgrade(uint256 _upgradeId) internal {
        address owner = stakedUpgrades[_upgradeId].owner;

        delete stakedUpgrades[_upgradeId];

        _removeUpgradeFromOwnerEnumeration(owner, _upgradeId);
    }

    function withdrawFarmers(uint256[] calldata _farmersIds) public nonReentrant whenNotPaused {
        for (uint256 i = 0; i < _farmersIds.length; i++) {
            uint256 _farmersId = _farmersIds[i];
            RestingFarmer memory resting = restingFarmers[_farmersId];

            require(resting.present, "Farmer is not resting");
            require(resting.owner == _msgSender(), "You don't own this farmers");
            require(block.timestamp >= resting.endTimestamp, "Farmer is still resting");

            _removeFarmerFromCooldown(_farmersId);
            farmers.transferFrom(address(this), _msgSender(), _farmersId);
        }
    }

    function reStakeRestedFarmers(uint256[] calldata _farmersIds) public nonReentrant whenNotPaused {
        address owner = _msgSender();

        uint256 maxNumberFarmers = getMaxNumberFarmers(owner);
        uint256 FarmersAfterStaking = _farmersIds.length + numberOfFarmers[owner][0] + numberOfFarmers[owner][1];
        require(maxNumberFarmers >= FarmersAfterStaking, "You can't stake that many Farmers");

        for (uint256 i = 0; i < _farmersIds.length; i++) { //stakes farmers
            uint256 _farmersId = _farmersIds[i];

            RestingFarmer memory resting = restingFarmers[_farmersId];

            require(resting.present, "Farmer is not resting");
            require(resting.owner == owner, "You don't own this farmers");
            require(block.timestamp >= resting.endTimestamp, "Farmer is still resting");

            _removeFarmerFromCooldown(_farmersId);

            _addFarmerToFarm(_farmersId, owner);

            if(farmers.getType(_farmersId) == farmers.LAND_OWNER_TYPE()){
                numberOfFarmers[owner][1]++; 
            } else {
                numberOfFarmers[owner][0]++; 
            }

            totalPPM[owner] += farmers.getYield(_farmersId);
        }
        _updateState(owner);
    }

    function _addCooldownToOwnerEnumeration(address _owner, uint256 _tokenId) internal {
        uint256 length = restingFarmersBalance[_owner];
        ownedRestingFarmers[_owner][length] = _tokenId;
        restingFarmersIndex[_tokenId] = length;
        restingFarmersBalance[_owner]++;
    }

    function _removeStakeFromOwnerEnumeration(address _owner, uint256 _tokenId) internal {
        uint256 lastTokenIndex = ownedFarmerStakesBalance[_owner] - 1;
        uint256 tokenIndex = ownedFarmerStakesIndex[_tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedFarmerStakes[_owner][lastTokenIndex];

            ownedFarmerStakes[_owner][tokenIndex] = lastTokenId;
            ownedFarmerStakesIndex[lastTokenId] = tokenIndex;
        }

        delete ownedFarmerStakesIndex[_tokenId];
        delete ownedFarmerStakes[_owner][lastTokenIndex];
        ownedFarmerStakesBalance[_owner]--;
    }

    function _removeUpgradeFromOwnerEnumeration(address _owner, uint256 _tokenId) internal {
        uint256 lastTokenIndex = ownedUpgradeStakesBalance[_owner] - 1;
        uint256 tokenIndex = ownedUpgradeStakesIndex[_tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedUpgradeStakes[_owner][lastTokenIndex];

            ownedUpgradeStakes[_owner][tokenIndex] = lastTokenId;
            ownedUpgradeStakesIndex[lastTokenId] = tokenIndex;
        }

        delete ownedUpgradeStakesIndex[_tokenId];
        delete ownedUpgradeStakes[_owner][lastTokenIndex];
        ownedUpgradeStakesBalance[_owner]--;
    }

    function _removeFarmerFromCooldown(uint256 _farmersId) internal {
        address owner = restingFarmers[_farmersId].owner;
        delete restingFarmers[_farmersId];
        _removeCooldownFromOwnerEnumeration(owner, _farmersId);
    }

    function _removeCooldownFromOwnerEnumeration(address _owner, uint256 _tokenId) internal {
        uint256 lastTokenIndex = restingFarmersBalance[_owner] - 1;
        uint256 tokenIndex = restingFarmersIndex[_tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedRestingFarmers[_owner][lastTokenIndex];
            ownedRestingFarmers[_owner][tokenIndex] = lastTokenId;
            restingFarmersIndex[lastTokenId] = tokenIndex;
        }

        delete restingFarmersIndex[_tokenId];
        delete ownedRestingFarmers[_owner][lastTokenIndex];
        restingFarmersBalance[_owner]--;
    }

    function stakeOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < ownedFarmerStakesBalance[_owner], "owner index out of bounds");
        return ownedFarmerStakes[_owner][_index];
    }

    function batchedStakesOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (StakedFarmerInfo[] memory) {
        if (_offset >= ownedFarmerStakesBalance[_owner]) {
            return new StakedFarmerInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= ownedFarmerStakesBalance[_owner]) {
            outputSize = ownedFarmerStakesBalance[_owner] - _offset;
        }
        StakedFarmerInfo[] memory outputs = new StakedFarmerInfo[](outputSize);

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 farmersId = stakeOfOwnerByIndex(_owner, _offset + i);
            uint256 upgradeId = _getUpgradeStakedForFarmer(_owner, farmersId);
            uint256 farmersPPM = farmers.getYield(farmersId);
            uint256 upgradePPM;
            if(upgradeId > 0){
                upgradePPM = upgrade.getYield(upgradeId);
            }

            outputs[i] = StakedFarmerInfo({
                farmersId: farmersId,
                upgradeId: upgradeId,
                farmersPPM: farmersPPM,
                upgradePPM: upgradePPM, 
                crop: getCropAccruedForFarmer(farmersId, false),
                fatigue: getFatigueAccruedForFarmer(farmersId, false),
                timeUntilFatigued: getTimeUntilFatigued(farmersId, false)
            });
        }

        return outputs;
    }


    function cooldownOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < restingFarmersBalance[_owner], "owner index out of bounds");
        return ownedRestingFarmers[_owner][_index];
    }

    function batchedCooldownsOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (RestingFarmerInfo[] memory) {
        if (_offset >= restingFarmersBalance[_owner]) {
            return new RestingFarmerInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= restingFarmersBalance[_owner]) {
            outputSize = restingFarmersBalance[_owner] - _offset;
        }
        RestingFarmerInfo[] memory outputs = new RestingFarmerInfo[](outputSize);

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 tokenId = cooldownOfOwnerByIndex(_owner, _offset + i);

            outputs[i] = RestingFarmerInfo({
                tokenId: tokenId,
                endTimestamp: restingFarmers[tokenId].endTimestamp
            });
        }

        return outputs;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setMaxFatigue(uint256 maxFatigue) external onlyOwner {
        MAX_FATIGUE = maxFatigue;
    }


    // FarmV3
    function setCrop(Crop _crop) external onlyOwner {
        crop = _crop;
    }
    function setBarnAddress(address _barnAddress) external onlyOwner {
        barnAddress = _barnAddress;
    }
    function setFarmer(Farmer _farmers) external onlyOwner {
        farmers = _farmers;
    }
    function setLocustGod(LocustGod _locustgod) external onlyOwner {
        locustgod = _locustgod;
    }
    function setUpgrade(Upgrade _upgrade) external onlyOwner {
        upgrade = _upgrade;
    }
    function setYieldPPS(uint256 _yieldPPS) external onlyOwner {
        yieldPPS = _yieldPPS;
    }
}