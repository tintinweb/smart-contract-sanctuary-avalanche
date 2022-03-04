//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./FoodTruck.sol";
import "./Upgrade.sol";
import "./HotDog.sol";
import "./HotDoggeriaProgression.sol";

contract HotDoggeria is HotDoggeriaProgression, ReentrancyGuard {
    using SafeMath for uint256;

    // Constants
    uint256 public constant YIELD_HDPS = 16666666666666667; // HotDog cooked per second per unit of yield
    uint256 public constant CLAIM_HOTDOG_CONTRIBUTION_PERCENTAGE = 10;
    uint256 public constant CLAIM_HOTDOG_BURN_PERCENTAGE = 10;
    uint256 public constant MAX_FATIGUE = 100000000000000;

    uint256 public startTime;

    // Staking

    struct StakedFoodTruck {
        address owner;
        uint256 tokenId;
        uint256 startTimestamp;
        bool staked;
    }

    struct StakedFoodTruckInfo {
        uint256 foodTruckId;
        uint256 upgradeId;
        uint256 foodTruckHDPM;
        uint256 upgradeHDPM;
        uint256 hotDog;
        uint256 fatigue;
        uint256 timeUntilFatigued;
    }

    mapping(uint256 => StakedFoodTruck) public stakedFoodTrucks; // tokenId => StakedFoodTruck
    mapping(address => mapping(uint256 => uint256))
        private ownedFoodTruckStakes; // (address, index) => tokenid
    mapping(uint256 => uint256) private ownedFoodTruckStakesIndex; // tokenId => index in its owner's stake list
    mapping(address => uint256) public ownedFoodTruckStakesBalance; // address => stake count

    mapping(address => uint256) public fatiguePerMinute; // address => fatigue per minute in the hot doggeria
    mapping(uint256 => uint256) private foodTruckFatigue; // tokenId => fatigue
    mapping(uint256 => uint256) private foodTruckHotDog; // tokenId => hotDog

    mapping(address => uint256[4]) private numberOfFoodTrucks; // address => [number of regular food trucks, number of master food trucks]
    mapping(address => uint256) private totalHDPM; // address => total HDPM

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

    struct RestingFoodTruck {
        address owner;
        uint256 tokenId;
        uint256 endTimestamp;
        bool present;
    }

    struct RestingFoodTruckInfo {
        uint256 tokenId;
        uint256 endTimestamp;
    }

    mapping(uint256 => RestingFoodTruck) public restingFoodTrucks; // tokenId => RestingFoodTruck
    mapping(address => mapping(uint256 => uint256))
        private ownedRestingFoodTrucks; // (user, index) => resting food truck id
    mapping(uint256 => uint256) private restingFoodTrucksIndex; // tokenId => index in its owner's cooldown list
    mapping(address => uint256) public restingFoodTrucksBalance; // address => cooldown count

    // Var

    FoodTruck public foodTruck;
    Upgrade public upgrade;
    HotDog public hotDog;
    address public freezerAddress;

    constructor(
        FoodTruck _foodTruck,
        Upgrade _upgrade,
        HotDog _hotDog,
        Juice _juice,
        address _freezerAddress
    ) HotDoggeriaProgression(_juice) {
        foodTruck = _foodTruck;
        upgrade = _upgrade;
        hotDog = _hotDog;
        freezerAddress = _freezerAddress;
    }

    // Views

    function _getUpgradeStakedForFoodTruck(address _owner, uint256 _foodTruckId)
        internal
        view
        returns (uint256)
    {
        uint256 index = ownedFoodTruckStakesIndex[_foodTruckId];
        return ownedUpgradeStakes[_owner][index];
    }

    function getFatiguePerMinuteWithModifier(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 fatigueSkillModifier = getFatigueSkillModifier(_owner);
        return fatiguePerMinute[_owner].mul(fatigueSkillModifier).div(100);
    }

    function _getGoldFoodTruckNumber(address _owner)
        internal
        view
        returns (uint256)
    {
        return numberOfFoodTrucks[_owner][1];
    }

    function _getDiamondFoodTruckNumber(address _owner)
        internal
        view
        returns (uint256)
    {
        return numberOfFoodTrucks[_owner][2];
    }

    function _getSpecialFoodTruckNumber(address _owner)
        internal
        view
        returns (uint256)
    {
        return numberOfFoodTrucks[_owner][3];
    }

    /**
     * Returns the current Food Truck's fatigue
     */
    function getFatigueAccruedForFoodTruck(
        uint256 _tokenId,
        bool checkOwnership
    ) public view returns (uint256) {
        StakedFoodTruck memory stakedFoodTruck = stakedFoodTrucks[_tokenId];
        require(stakedFoodTruck.staked, "This token isn't staked");
        if (checkOwnership) {
            require(
                stakedFoodTruck.owner == _msgSender(),
                "You don't own this token"
            );
        }

        uint256 fatigue = ((block.timestamp - stakedFoodTruck.startTimestamp) *
            getFatiguePerMinuteWithModifier(stakedFoodTruck.owner)) / 60;
        fatigue += foodTruckFatigue[_tokenId];
        if (fatigue > MAX_FATIGUE) {
            fatigue = MAX_FATIGUE;
        }
        return fatigue;
    }

    /**
     * Returns the timestamp of when the Food Truck will be fatigued
     */
    function timeUntilFatiguedCalculation(
        uint256 _startTime,
        uint256 _fatigue,
        uint256 _fatiguePerMinute
    ) public pure returns (uint256) {
        return _startTime + (60 * (MAX_FATIGUE - _fatigue)) / _fatiguePerMinute;
    }

    function getTimeUntilFatigued(uint256 _tokenId, bool checkOwnership)
        public
        view
        returns (uint256)
    {
        StakedFoodTruck memory stakedFoodTruck = stakedFoodTrucks[_tokenId];
        require(stakedFoodTruck.staked, "This token isn't staked");
        if (checkOwnership) {
            require(
                stakedFoodTruck.owner == _msgSender(),
                "You don't own this token"
            );
        }
        return
            timeUntilFatiguedCalculation(
                stakedFoodTruck.startTimestamp,
                foodTruckFatigue[_tokenId],
                getFatiguePerMinuteWithModifier(stakedFoodTruck.owner)
            );
    }

    /**
     * Returns the timestamp of when the Food Truck will be fully rested
     */
    function restingTimeCalculation(
        uint256 _foodTruckType,
        uint256 _masterFoodTruckType,
        uint256 _fatigue
    ) public pure returns (uint256) {
        uint256 maxTime = 43200; //12*60*60
        if (_foodTruckType == _masterFoodTruckType) {
            maxTime = maxTime / 2; // master Food Trucks rest half of the time of regular Food Trucks
        }

        if (_fatigue > MAX_FATIGUE / 2) {
            return (maxTime * _fatigue) / MAX_FATIGUE;
        }

        return maxTime / 2; // minimum rest time is half of the maximum time
    }

    function getRestingTime(uint256 _tokenId, bool checkOwnership)
        public
        view
        returns (uint256)
    {
        StakedFoodTruck memory stakedFoodTruck = stakedFoodTrucks[_tokenId];
        require(stakedFoodTruck.staked, "This token isn't staked");
        if (checkOwnership) {
            require(
                stakedFoodTruck.owner == _msgSender(),
                "You don't own this token"
            );
        }

        return
            restingTimeCalculation(
                foodTruck.getType(_tokenId),
                foodTruck.GOLD_FOOD_TRUCK_TYPE(),
                getFatigueAccruedForFoodTruck(_tokenId, false)
            );
    }

    function getHotDogAccruedForManyFoodTrucks(uint256[] calldata _tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory output = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            output[i] = _getHotDogAccruedForFoodTruck(_tokenIds[i], false);
        }
        return output;
    }

    /**
     * Returns food trucks's hot dog from foodTruckHotDog mapping
     */
    function hotDogAccruedCalculation(
        uint256 _initialHotDog,
        uint256 _deltaTime,
        uint256 _hdpm,
        uint256 _modifier,
        uint256 _fatigue,
        uint256 _fatiguePerMinute
    ) public pure returns (uint256) {
        if (_fatigue >= MAX_FATIGUE) {
            return _initialHotDog;
        }

        uint256 a = (_deltaTime *
            _hdpm *
            YIELD_HDPS *
            _modifier *
            (MAX_FATIGUE - _fatigue)) / (100 * MAX_FATIGUE);
        uint256 b = (_deltaTime *
            _deltaTime *
            _hdpm *
            YIELD_HDPS *
            _modifier *
            _fatiguePerMinute) / (100 * 2 * 60 * MAX_FATIGUE);
        if (a > b) {
            return _initialHotDog + a - b;
        }

        return _initialHotDog;
    }

    function _getModifier(address _owner, uint256 _foodTruckType)
        internal
        view
        returns (uint256)
    {
        uint256 goldFoodTruckSkillModifier = getFoodTruckSkillModifier(
            _owner,
            _getGoldFoodTruckNumber(_owner)
        );

        uint256 diamondFoodTruckSkillModifier = getFoodTruckSkillModifier(
            _owner,
            _getDiamondFoodTruckNumber(_owner)
        );

        uint256 specialFoodTruckSkillModifier = getFoodTruckSkillModifier(
            _owner,
            _getSpecialFoodTruckNumber(_owner)
        );

        if (_foodTruckType == foodTruck.DIAMOND_FOOD_TRUCK_TYPE()) {
            return diamondFoodTruckSkillModifier;
        } else if (_foodTruckType == foodTruck.SPECIAL_FOOD_TRUCK_TYPE()) {
            return specialFoodTruckSkillModifier;
        } else if (_foodTruckType == foodTruck.GOLD_FOOD_TRUCK_TYPE()) {
            return goldFoodTruckSkillModifier;
        } else {
            return 100;
        }
    }

    function _getHotDogAccruedForFoodTruck(
        uint256 _tokenId,
        bool checkOwnership
    ) internal view returns (uint256) {
        StakedFoodTruck memory stakedFoodTruck = stakedFoodTrucks[_tokenId];
        address owner = stakedFoodTruck.owner;
        uint256 foodTruckType = foodTruck.getType(_tokenId);

        require(stakedFoodTruck.staked, "This token isn't staked");
        if (checkOwnership) {
            require(owner == _msgSender(), "You don't own this token");
        }

        // if Food TruckFatigue = MAX_FATIGUE it means that Food TruckHotDog already has the correct value for the HotDog, since it didn't produce HotDog since last update
        uint256 foodTruckFatigueLastUpdate = foodTruckFatigue[_tokenId];
        if (foodTruckFatigueLastUpdate == MAX_FATIGUE) {
            return foodTruckHotDog[_tokenId];
        }

        uint256 timeUntilFatigued = getTimeUntilFatigued(_tokenId, false);

        uint256 endTimestamp;
        if (block.timestamp >= timeUntilFatigued) {
            endTimestamp = timeUntilFatigued;
        } else {
            endTimestamp = block.timestamp;
        }

        uint256 hdpm = foodTruck.getYield(_tokenId);
        uint256 upgradeId = _getUpgradeStakedForFoodTruck(owner, _tokenId);

        if (upgradeId > 0) {
            hdpm += upgrade.getYield(upgradeId);
        }

        uint256 delta = endTimestamp - stakedFoodTruck.startTimestamp;
        uint256 _modifier = _getModifier(owner, foodTruckType);

        return
            hotDogAccruedCalculation(
                foodTruckHotDog[_tokenId],
                delta,
                hdpm,
                _modifier,
                foodTruckFatigueLastUpdate,
                getFatiguePerMinuteWithModifier(owner)
            );
    }

    /**
     * Calculates the total HDPM staked for a pizzeria.
     * This will also be used in the fatiguePerMinute calculation
     */
    function getTotalHDPM(address _owner) public view returns (uint256) {
        return totalHDPM[_owner];
    }

    function gameStarted() public view returns (bool) {
        return startTime != 0 && block.timestamp >= startTime;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        require(!gameStarted(), "game already started");
        startTime = _startTime;
    }

    /**
     * Updates the Fatigue per Minute
     * This function is called in _updateState
     */

    function fatiguePerMinuteCalculation(uint256 _hdpm)
        public
        pure
        returns (uint256)
    {
        // NOTE: fatiguePerMinute[_owner] = 8610000000 + 166000000  * totalHDPM[_owner] + -220833 * totalHDPM[_owner]* totalHDPM[_owner]  + 463 * totalHDPM[_owner]*totalHDPM[_owner]*totalHDPM[_owner];
        uint256 a = 463;
        uint256 b = 220833;
        uint256 c = 166000000;
        uint256 d = 8610000000;
        if (_hdpm == 0) {
            return d;
        }
        return d + c * _hdpm + a * _hdpm * _hdpm * _hdpm - b * _hdpm * _hdpm;
    }

    function _updatefatiguePerMinute(address _owner) internal {
        fatiguePerMinute[_owner] = fatiguePerMinuteCalculation(
            totalHDPM[_owner]
        );
    }

    /**
     * This function updates Food TruckHotDog and Food TruckFatigue mappings
     * Calls _updatefatiguePerMinute
     * Also updates startTimestamp for Food Trucks
     * It should be used whenever the HDPM changes
     */
    function _updateState(address _owner) internal {
        uint256 foodTruckBalance = ownedFoodTruckStakesBalance[_owner];
        for (uint256 i = 0; i < foodTruckBalance; i++) {
            uint256 tokenId = ownedFoodTruckStakes[_owner][i];
            StakedFoodTruck storage stakedFoodTruck = stakedFoodTrucks[tokenId];
            if (
                stakedFoodTruck.staked &&
                block.timestamp > stakedFoodTruck.startTimestamp
            ) {
                foodTruckHotDog[tokenId] = _getHotDogAccruedForFoodTruck(
                    tokenId,
                    false
                );

                foodTruckFatigue[tokenId] = getFatigueAccruedForFoodTruck(
                    tokenId,
                    false
                );

                stakedFoodTruck.startTimestamp = block.timestamp;
            }
        }
        _updatefatiguePerMinute(_owner);
    }

    //Claim
    function _claimHotDog(address _owner) internal {
        uint256 totalClaimed = 0;

        uint256 freezerSkillModifier = getFreezerSkillModifier(_owner);
        uint256 burnSkillModifier = getBurnSkillModifier(_owner);

        uint256 foodTruckBalance = ownedFoodTruckStakesBalance[_owner];

        for (uint256 i = 0; i < foodTruckBalance; i++) {
            uint256 foodTruckId = ownedFoodTruckStakes[_owner][i];

            totalClaimed += _getHotDogAccruedForFoodTruck(foodTruckId, true); // also checks that msg.sender owns this token

            delete foodTruckHotDog[foodTruckId];

            foodTruckFatigue[foodTruckId] = getFatigueAccruedForFoodTruck(
                foodTruckId,
                false
            ); // bug fix for fatigue

            stakedFoodTrucks[foodTruckId].startTimestamp = block.timestamp;
        }

        uint256 taxAmountFreezer = (totalClaimed *
            (CLAIM_HOTDOG_CONTRIBUTION_PERCENTAGE - freezerSkillModifier)) /
            100;
        uint256 taxAmountBurn = (totalClaimed *
            (CLAIM_HOTDOG_BURN_PERCENTAGE - burnSkillModifier)) / 100;

        totalClaimed = totalClaimed - taxAmountFreezer - taxAmountBurn;

        hotDog.mint(_msgSender(), totalClaimed);
        hotDog.mint(freezerAddress, taxAmountFreezer);
    }

    function claimHotDog() public nonReentrant whenNotPaused {
        address owner = _msgSender();
        _claimHotDog(owner);
    }

    function unstakeFoodTrucksAndUpgrades(
        uint256[] calldata _foodTruckIds,
        uint256[] calldata _upgradeIds
    ) public nonReentrant whenNotPaused {
        address owner = _msgSender();
        // Check 1:1 correspondency between Food Truck and upgrade
        require(
            ownedFoodTruckStakesBalance[owner] - _foodTruckIds.length >=
                ownedUpgradeStakesBalance[owner] - _upgradeIds.length,
            "Needs at least food truck for each tool"
        );

        _claimHotDog(owner);

        for (uint256 i = 0; i < _upgradeIds.length; i++) {
            //unstake upgrades
            uint256 upgradeId = _upgradeIds[i];

            require(
                stakedUpgrades[upgradeId].owner == owner,
                "You don't own this tool"
            );
            require(
                stakedUpgrades[upgradeId].staked,
                "Tool needs to be staked"
            );

            totalHDPM[owner] -= upgrade.getYield(upgradeId);
            upgrade.transferFrom(address(this), owner, upgradeId);

            _removeUpgrade(upgradeId);
        }

        for (uint256 i = 0; i < _foodTruckIds.length; i++) {
            //unstake Food Trucks
            uint256 foodTruckId = _foodTruckIds[i];

            require(
                stakedFoodTrucks[foodTruckId].owner == owner,
                "You don't own this token"
            );
            require(
                stakedFoodTrucks[foodTruckId].staked,
                "Chef needs to be staked"
            );

            if (
                foodTruck.getType(foodTruckId) ==
                foodTruck.GOLD_FOOD_TRUCK_TYPE()
            ) {
                numberOfFoodTrucks[owner][1]--;
            }
            if (
                foodTruck.getType(foodTruckId) ==
                foodTruck.DIAMOND_FOOD_TRUCK_TYPE()
            ) {
                numberOfFoodTrucks[owner][2]--;
            }
            if (
                foodTruck.getType(foodTruckId) ==
                foodTruck.SPECIAL_FOOD_TRUCK_TYPE()
            ) {
                numberOfFoodTrucks[owner][3]--;
            } else {
                numberOfFoodTrucks[owner][0]--;
            }

            totalHDPM[owner] -= foodTruck.getYield(foodTruckId);

            _moveFoodTruckToCooldown(foodTruckId);
        }

        _updateState(owner);
    }

    // Stake

    /**
     * This function updates stake Food Trucks and upgrades
     * The upgrades are paired with the Food Truck the upgrade will be applied
     */
    function stakeMany(
        uint256[] calldata _foodTruckIds,
        uint256[] calldata _upgradeIds
    ) public nonReentrant whenNotPaused {
        require(gameStarted(), "The game has not started");

        address owner = _msgSender();

        uint256 maxNumberFoodTrucks = getMaxNumberFoodTrucks(owner);
        uint256 foodTrucksAfterStaking = _foodTruckIds.length +
            numberOfFoodTrucks[owner][0] +
            numberOfFoodTrucks[owner][1];
        require(
            maxNumberFoodTrucks >= foodTrucksAfterStaking,
            "You can't stake that many Food Trucks"
        );

        // Check 1:1 correspondency between Food Truck and upgrade
        require(
            ownedFoodTruckStakesBalance[owner] + _foodTruckIds.length >=
                ownedUpgradeStakesBalance[owner] + _upgradeIds.length,
            "Needs at least Food Truck for each tool"
        );

        for (uint256 i = 0; i < _foodTruckIds.length; i++) {
            //stakes Food Truck
            uint256 foodTruckId = _foodTruckIds[i];

            require(
                foodTruck.ownerOf(foodTruckId) == owner,
                "You don't own this token"
            );
            require(
                foodTruck.getType(foodTruckId) > 0,
                "Chef not yet revealed"
            );
            require(
                !stakedFoodTrucks[foodTruckId].staked,
                "Chef is already staked"
            );

            _addFoodTruckToHotDoggeria(foodTruckId, owner);

            if (
                foodTruck.getType(foodTruckId) ==
                foodTruck.GOLD_FOOD_TRUCK_TYPE()
            ) {
                numberOfFoodTrucks[owner][1]++;
            } else {
                numberOfFoodTrucks[owner][0]++;
            }

            totalHDPM[owner] += foodTruck.getYield(foodTruckId);

            foodTruck.transferFrom(owner, address(this), foodTruckId);
        }
        uint256 maxLevelUpgrade = getMaxLevelUpgrade(owner);
        for (uint256 i = 0; i < _upgradeIds.length; i++) {
            //stakes upgrades
            uint256 upgradeId = _upgradeIds[i];

            require(
                upgrade.ownerOf(upgradeId) == owner,
                "You don't own this tool"
            );
            require(
                !stakedUpgrades[upgradeId].staked,
                "Tool is already staked"
            );
            require(
                upgrade.getLevel(upgradeId) <= maxLevelUpgrade,
                "You can't equip that tool"
            );

            upgrade.transferFrom(owner, address(this), upgradeId);
            totalHDPM[owner] += upgrade.getYield(upgradeId);

            _addUpgradeToHotDoggeria(upgradeId, owner);
        }
        _updateState(owner);
    }

    function _addFoodTruckToHotDoggeria(uint256 _tokenId, address _owner)
        internal
    {
        stakedFoodTrucks[_tokenId] = StakedFoodTruck({
            owner: _owner,
            tokenId: _tokenId,
            startTimestamp: block.timestamp,
            staked: true
        });
        _addStakeToOwnerEnumeration(_owner, _tokenId);
    }

    function _addUpgradeToHotDoggeria(uint256 _tokenId, address _owner)
        internal
    {
        stakedUpgrades[_tokenId] = StakedUpgrade({
            owner: _owner,
            tokenId: _tokenId,
            staked: true
        });
        _addUpgradeToOwnerEnumeration(_owner, _tokenId);
    }

    function _addStakeToOwnerEnumeration(address _owner, uint256 _tokenId)
        internal
    {
        uint256 length = ownedFoodTruckStakesBalance[_owner];
        ownedFoodTruckStakes[_owner][length] = _tokenId;
        ownedFoodTruckStakesIndex[_tokenId] = length;
        ownedFoodTruckStakesBalance[_owner]++;
    }

    function _addUpgradeToOwnerEnumeration(address _owner, uint256 _tokenId)
        internal
    {
        uint256 length = ownedUpgradeStakesBalance[_owner];
        ownedUpgradeStakes[_owner][length] = _tokenId;
        ownedUpgradeStakesIndex[_tokenId] = length;
        ownedUpgradeStakesBalance[_owner]++;
    }

    function _moveFoodTruckToCooldown(uint256 _foodTruckId) internal {
        address owner = stakedFoodTrucks[_foodTruckId].owner;

        uint256 endTimestamp = block.timestamp +
            getRestingTime(_foodTruckId, false);
        restingFoodTrucks[_foodTruckId] = RestingFoodTruck({
            owner: owner,
            tokenId: _foodTruckId,
            endTimestamp: endTimestamp,
            present: true
        });

        delete foodTruckFatigue[_foodTruckId];
        delete stakedFoodTrucks[_foodTruckId];
        _removeStakeFromOwnerEnumeration(owner, _foodTruckId);
        _addCooldownToOwnerEnumeration(owner, _foodTruckId);
    }

    // Cooldown
    function _removeUpgrade(uint256 _upgradeId) internal {
        address owner = stakedUpgrades[_upgradeId].owner;

        delete stakedUpgrades[_upgradeId];

        _removeUpgradeFromOwnerEnumeration(owner, _upgradeId);
    }

    function withdrawFoodTrucks(uint256[] calldata _foodTruckIds)
        public
        nonReentrant
        whenNotPaused
    {
        for (uint256 i = 0; i < _foodTruckIds.length; i++) {
            uint256 _foodTruckId = _foodTruckIds[i];
            RestingFoodTruck memory resting = restingFoodTrucks[_foodTruckId];

            require(resting.present, "Food Truck is not resting");
            require(
                resting.owner == _msgSender(),
                "You don't own this Food Truck"
            );
            require(
                block.timestamp >= resting.endTimestamp,
                "Food Truck is still resting"
            );

            _removeFoodTruckFromCooldown(_foodTruckId);
            foodTruck.transferFrom(address(this), _msgSender(), _foodTruckId);
        }
    }

    function reStakeRestedFoodTrucks(uint256[] calldata _foodTruckIds)
        public
        nonReentrant
        whenNotPaused
    {
        address owner = _msgSender();

        uint256 maxNumberFoodTrucks = getMaxNumberFoodTrucks(owner);
        uint256 foodTrucksAfterStaking = _foodTruckIds.length +
            numberOfFoodTrucks[owner][0] +
            numberOfFoodTrucks[owner][1];
        require(
            maxNumberFoodTrucks >= foodTrucksAfterStaking,
            "You can't stake that many Food Trucks"
        );

        for (uint256 i = 0; i < _foodTruckIds.length; i++) {
            //stakes Food Truck
            uint256 _foodTruckId = _foodTruckIds[i];

            RestingFoodTruck memory resting = restingFoodTrucks[_foodTruckId];

            require(resting.present, "Food Truck is not resting");
            require(resting.owner == owner, "You don't own this Food Truck");
            require(
                block.timestamp >= resting.endTimestamp,
                "Food Truck is still resting"
            );

            _removeFoodTruckFromCooldown(_foodTruckId);

            _addFoodTruckToHotDoggeria(_foodTruckId, owner);

            if (
                foodTruck.getType(_foodTruckId) ==
                foodTruck.GOLD_FOOD_TRUCK_TYPE()
            ) {
                numberOfFoodTrucks[owner][1]++;
            } else {
                numberOfFoodTrucks[owner][0]++;
            }

            totalHDPM[owner] += foodTruck.getYield(_foodTruckId);
        }
        _updateState(owner);
    }

    function _addCooldownToOwnerEnumeration(address _owner, uint256 _tokenId)
        internal
    {
        uint256 length = restingFoodTrucksBalance[_owner];
        ownedRestingFoodTrucks[_owner][length] = _tokenId;
        restingFoodTrucksIndex[_tokenId] = length;
        restingFoodTrucksBalance[_owner]++;
    }

    function _removeStakeFromOwnerEnumeration(address _owner, uint256 _tokenId)
        internal
    {
        uint256 lastTokenIndex = ownedFoodTruckStakesBalance[_owner] - 1;
        uint256 tokenIndex = ownedFoodTruckStakesIndex[_tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedFoodTruckStakes[_owner][lastTokenIndex];

            ownedFoodTruckStakes[_owner][tokenIndex] = lastTokenId;
            ownedFoodTruckStakesIndex[lastTokenId] = tokenIndex;
        }

        delete ownedFoodTruckStakesIndex[_tokenId];
        delete ownedFoodTruckStakes[_owner][lastTokenIndex];
        ownedFoodTruckStakesBalance[_owner]--;
    }

    function _removeUpgradeFromOwnerEnumeration(
        address _owner,
        uint256 _tokenId
    ) internal {
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

    function _removeFoodTruckFromCooldown(uint256 _foodTruckId) internal {
        address owner = restingFoodTrucks[_foodTruckId].owner;
        delete restingFoodTrucks[_foodTruckId];
        _removeCooldownFromOwnerEnumeration(owner, _foodTruckId);
    }

    function _removeCooldownFromOwnerEnumeration(
        address _owner,
        uint256 _tokenId
    ) internal {
        uint256 lastTokenIndex = restingFoodTrucksBalance[_owner] - 1;
        uint256 tokenIndex = restingFoodTrucksIndex[_tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedRestingFoodTrucks[_owner][
                lastTokenIndex
            ];
            ownedRestingFoodTrucks[_owner][tokenIndex] = lastTokenId;
            restingFoodTrucksIndex[lastTokenId] = tokenIndex;
        }

        delete restingFoodTrucksIndex[_tokenId];
        delete ownedRestingFoodTrucks[_owner][lastTokenIndex];
        restingFoodTrucksBalance[_owner]--;
    }

    function stakeOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < ownedFoodTruckStakesBalance[_owner],
            "owner index out of bounds"
        );
        return ownedFoodTruckStakes[_owner][_index];
    }

    function batchedStakesOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (StakedFoodTruckInfo[] memory) {
        if (_offset >= ownedFoodTruckStakesBalance[_owner]) {
            return new StakedFoodTruckInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= ownedFoodTruckStakesBalance[_owner]) {
            outputSize = ownedFoodTruckStakesBalance[_owner] - _offset;
        }
        StakedFoodTruckInfo[] memory outputs = new StakedFoodTruckInfo[](
            outputSize
        );

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 foodTruckId = stakeOfOwnerByIndex(_owner, _offset + i);
            uint256 upgradeId = _getUpgradeStakedForFoodTruck(
                _owner,
                foodTruckId
            );
            uint256 foodTruckHDPM = foodTruck.getYield(foodTruckId);
            uint256 upgradeHDPM;
            if (upgradeId > 0) {
                upgradeHDPM = upgrade.getYield(upgradeId);
            }

            outputs[i] = StakedFoodTruckInfo({
                foodTruckId: foodTruckId,
                upgradeId: upgradeId,
                foodTruckHDPM: foodTruckHDPM,
                upgradeHDPM: upgradeHDPM,
                hotDog: _getHotDogAccruedForFoodTruck(foodTruckId, false),
                fatigue: getFatigueAccruedForFoodTruck(foodTruckId, false),
                timeUntilFatigued: getTimeUntilFatigued(foodTruckId, false)
            });
        }

        return outputs;
    }

    function cooldownOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        returns (uint256)
    {
        require(
            _index < restingFoodTrucksBalance[_owner],
            "owner index out of bounds"
        );
        return ownedRestingFoodTrucks[_owner][_index];
    }

    function batchedCooldownsOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (RestingFoodTruckInfo[] memory) {
        if (_offset >= restingFoodTrucksBalance[_owner]) {
            return new RestingFoodTruckInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= restingFoodTrucksBalance[_owner]) {
            outputSize = restingFoodTrucksBalance[_owner] - _offset;
        }
        RestingFoodTruckInfo[] memory outputs = new RestingFoodTruckInfo[](
            outputSize
        );

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 tokenId = cooldownOfOwnerByIndex(_owner, _offset + i);

            outputs[i] = RestingFoodTruckInfo({
                tokenId: tokenId,
                endTimestamp: restingFoodTrucks[tokenId].endTimestamp
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./HotDog.sol";

contract FoodTruck is ERC721Enumerable, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    struct FoodTruckInfo {
        uint256 tokenId;
        uint256 foodTruckType;
    }

    // CONSTANTS

    uint256 public constant FOOD_TRUCK_PRICE_WHITELIST = 1 ether;
    uint256 public constant FOOD_TRUCK_PRICE_AVAX = 1.25 ether;

    uint256 public constant WHITELIST_FOOD_TRUCKS = 7500;
    uint256 public constant FOOD_TRUCKS_PER_HOTDOG_MINT_LEVEL = 5000;

    uint256 public constant MAXIMUM_MINTS_PER_WHITELIST_ADDRESS = 10;

    uint256 public constant NUM_GEN0_FOOD_TRUCKS = 10_000;
    uint256 public constant NUM_GEN1_FOOD_TRUCKS = 10_000;

    uint256 public constant FOOD_TRUCK_TYPE = 1;
    uint256 public constant GOLD_FOOD_TRUCK_TYPE = 2;
    uint256 public constant DIAMOND_FOOD_TRUCK_TYPE = 3;
    uint256 public constant SPECIAL_FOOD_TRUCK_TYPE = 4;

    uint256 public constant FOOD_TRUCK_YIELD = 1;
    uint256 public constant GOLD_FOOD_TRUCK_YIELD = 3;
    uint256 public constant DIAMOND_FOOD_TRUCK_YIELD = 6;
    uint256 public constant SPECIAL_FOOD_TRUCK_YIELD = 9;

    uint256 public constant PROMOTIONAL_FOOD_TRUCKS = 20;

    // VAR

    // external contracts
    HotDog public hotDog;
    address public hotDoggeriaAddress;

    // metadata URI
    string public BASE_URI;

    // foodTruck type definitions (normal, gold, diamond or special?)
    mapping(uint256 => uint256) public tokenTypes; // maps tokenId to its type
    mapping(uint256 => uint256) public typeYields; // maps foodTruck type to yield

    // mint tracking
    uint256 public foodTrucksMintedWithAVAX;
    uint256 public foodTrucksMintedWithHOTDOG;
    uint256 public foodTrucksMintedWhitelist;
    uint256 public foodTrucksMintedPromotional;
    uint256 public foodTrucksMinted = 50; // First 50 ids are reserved for the promotional foodTrucks

    // mint control timestamps
    uint256 public startTimeWhitelist;
    uint256 public startTimeAVAX;
    uint256 public startTimeHOTDOG;

    // HOTDOG mint price tracking
    uint256 public currentHOTDOGMintCost = 20_000 * 1e18;

    // whitelist
    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistClaimed;

    // EVENTS

    event onFoodTruckCreated(uint256 tokenId);
    event onFoodTruckRevealed(uint256 tokenId, uint256 foodTruckType);

    /**
     * requires pizza, foodTruckType oracle address
     * pizza: for liquidity bootstrapping and spending on foodTrucks
     */
    constructor(HotDog _hotDog, string memory _BASE_URI)
        ERC721("Hot Dog Game FoodTrucks", "HOTDOG-GAME-FOODTRUCK")
    {
        require(address(_hotDog) != address(0));

        // set required contract references
        hotDog = _hotDog;

        // set base uri
        BASE_URI = _BASE_URI;

        // initialize token yield values for each foodTruck type
        typeYields[FOOD_TRUCK_TYPE] = FOOD_TRUCK_YIELD;
        typeYields[GOLD_FOOD_TRUCK_TYPE] = GOLD_FOOD_TRUCK_YIELD;
        typeYields[DIAMOND_FOOD_TRUCK_TYPE] = DIAMOND_FOOD_TRUCK_YIELD;
        typeYields[SPECIAL_FOOD_TRUCK_TYPE] = SPECIAL_FOOD_TRUCK_YIELD;
    }

    // VIEWS

    // minting status

    function mintingStartedWhitelist() public view returns (bool) {
        return startTimeWhitelist != 0 && block.timestamp >= startTimeWhitelist;
    }

    function mintingStartedAVAX() public view returns (bool) {
        return startTimeAVAX != 0 && block.timestamp >= startTimeAVAX;
    }

    function mintingStartedHOTDOG() public view returns (bool) {
        return startTimeHOTDOG != 0 && block.timestamp >= startTimeHOTDOG;
    }

    // metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function getYield(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "token does not exist");
        return typeYields[tokenTypes[_tokenId]];
    }

    function getType(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "token does not exist");
        return tokenTypes[_tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseURI(), "/", tokenId.toString()));
    }

    // override

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        // pizzeria must be able to stake and unstake
        if (hotDoggeriaAddress != address(0) && _operator == hotDoggeriaAddress)
            return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    // ADMIN

    function setHotDoggeriaAddress(address _hotDoggeriaAddress)
        external
        onlyOwner
    {
        hotDoggeriaAddress = _hotDoggeriaAddress;
    }

    function setHotDog(address _hotDog) external onlyOwner {
        hotDog = HotDog(_hotDog);
    }

    function setStartTimeWhitelist(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimeWhitelist = _startTime;
    }

    function setStartTimeAVAX(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimeAVAX = _startTime;
    }

    function setStartTimeHOTDOG(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimeHOTDOG = _startTime;
    }

    function setBaseURI(string calldata _BASE_URI) external onlyOwner {
        BASE_URI = _BASE_URI;
    }

    /**
     * @dev merkle root for WL wallets
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev allows owner to send ERC20s held by this contract to target
     */
    function forwardERC20s(
        IERC20 _token,
        uint256 _amount,
        address target
    ) external onlyOwner {
        _token.safeTransfer(target, _amount);
    }

    /**
     * @dev allows owner to withdraw AVAX
     */
    function withdrawAVAX(uint256 _amount) external payable onlyOwner {
        require(address(this).balance >= _amount, "not enough AVAX");
        address payable to = payable(_msgSender());
        (bool sent, ) = to.call{value: _amount}("");
        require(sent, "Failed to send AVAX");
    }

    // MINTING

    function _createFoodTruck(address to, uint256 tokenId) internal {
        require(
            foodTrucksMinted <= NUM_GEN0_FOOD_TRUCKS + NUM_GEN1_FOOD_TRUCKS,
            "cannot mint anymore Food Trucks"
        );
        _safeMint(to, tokenId);

        emit onFoodTruckCreated(tokenId);
    }

    function _createFoodTrucks(uint256 qty, address to) internal {
        for (uint256 i = 0; i < qty; i++) {
            foodTrucksMinted += 1;
            _createFoodTruck(to, foodTrucksMinted);
        }
    }

    /**
     * @dev as an anti cheat mechanism, an external automation will generate the NFT metadata and set the foodTruck types via rng
     * - Using an external source of randomness ensures our mint cannot be cheated
     * - The external automation is open source and can be found on pizza game's github
     * - Once the mint is finished, it is provable that this randomness was not tampered with by providing the seed
     * - Food Truck type can be set only once
     */
    function setFoodTruckType(uint256[] calldata _foodTruckIds) external {
        require(
            _foodTruckIds.length <= 10,
            "you can reveal only 10 food trucks at a time"
        );
        for (uint256 i = 0; i < _foodTruckIds.length; i++) {
            uint256 tokenId = _foodTruckIds[i];
            require(
                tokenTypes[tokenId] == 0,
                "that token's type has already been set"
            );

            uint256 points = random(101);
            if (points <= 89) {
                tokenTypes[tokenId] = FOOD_TRUCK_TYPE;
                emit onFoodTruckRevealed(tokenId, FOOD_TRUCK_TYPE);
            }
            if (points > 89 && points <= 99) {
                tokenTypes[tokenId] = GOLD_FOOD_TRUCK_TYPE;
                emit onFoodTruckRevealed(tokenId, GOLD_FOOD_TRUCK_TYPE);
            }
            if (points == 100) {
                tokenTypes[tokenId] = DIAMOND_FOOD_TRUCK_TYPE;
                emit onFoodTruckRevealed(tokenId, DIAMOND_FOOD_TRUCK_TYPE);
            }
        }
    }

    function setSpecialFoodTruckType(uint256 tokenId, uint256 foodTruckType)
        external
        onlyOwner
    {
        require(
            tokenTypes[tokenId] == 0,
            "that token's type has already been set"
        );

        require(
            foodTruckType == FOOD_TRUCK_TYPE ||
                foodTruckType == GOLD_FOOD_TRUCK_TYPE ||
                foodTruckType == DIAMOND_FOOD_TRUCK_TYPE ||
                foodTruckType == SPECIAL_FOOD_TRUCK_TYPE,
            "invalid foodTruck type"
        );

        tokenTypes[tokenId] = foodTruckType;
        emit onFoodTruckRevealed(tokenId, foodTruckType);
    }

    /**
     * @dev Promotional GEN0 minting
     * Can mint maximum of PROMOTIONAL_FOOD_TRUCKS
     * All foodTrucks minted are from the same foodTruckType
     */
    function mintPromotional(
        uint256 qty,
        uint256 foodTruckType,
        address target
    ) external onlyOwner {
        require(qty > 0, "quantity must be greater than 0");
        require(
            (foodTrucksMintedPromotional + qty) <= PROMOTIONAL_FOOD_TRUCKS,
            "you can't mint that many right now"
        );
        require(
            foodTruckType == FOOD_TRUCK_TYPE ||
                foodTruckType == GOLD_FOOD_TRUCK_TYPE ||
                foodTruckType == DIAMOND_FOOD_TRUCK_TYPE ||
                foodTruckType == SPECIAL_FOOD_TRUCK_TYPE,
            "invalid foodTruck type"
        );

        for (uint256 i = 0; i < qty; i++) {
            foodTrucksMintedPromotional += 1;
            require(
                tokenTypes[foodTrucksMintedPromotional] == 0,
                "that token's type has already been set"
            );
            tokenTypes[foodTrucksMintedPromotional] = foodTruckType;
            emit onFoodTruckRevealed(
                foodTrucksMintedPromotional,
                foodTruckType
            );
            _createFoodTruck(target, foodTrucksMintedPromotional);
        }
    }

    /**
     * @dev Whitelist GEN0 minting
     * We implement a hard limit on the whitelist foodTrucks.
     */
    function mintWhitelist(bytes32[] calldata _merkleProof, uint256 qty)
        external
        payable
        whenNotPaused
    {
        // check most basic requirements
        require(merkleRoot != 0, "missing root");
        require(mintingStartedWhitelist(), "cannot mint right now");
        require(!mintingStartedAVAX(), "whitelist minting is closed");

        // check if address belongs in whitelist
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "this address does not have permission"
        );

        // check more advanced requirements
        require(
            qty > 0 && qty <= MAXIMUM_MINTS_PER_WHITELIST_ADDRESS,
            "quantity must be between 1 and 4"
        );
        require(
            (foodTrucksMintedWhitelist + qty) <= WHITELIST_FOOD_TRUCKS,
            "you can't mint that many right now"
        );
        require(
            (whitelistClaimed[_msgSender()] + qty) <=
                MAXIMUM_MINTS_PER_WHITELIST_ADDRESS,
            "this address can't mint any more whitelist foodTrucks"
        );

        // check price
        require(
            msg.value >= FOOD_TRUCK_PRICE_WHITELIST * qty,
            "not enough AVAX"
        );

        foodTrucksMintedWhitelist += qty;
        whitelistClaimed[_msgSender()] += qty;

        // mint foodTrucks
        _createFoodTrucks(qty, _msgSender());
    }

    /**
     * @dev GEN0 minting
     */
    function mintFoodTruckWithAVAX(uint256 qty) external payable whenNotPaused {
        require(mintingStartedAVAX(), "cannot mint right now");
        require(qty > 0 && qty <= 10, "quantity must be between 1 and 10");
        require(
            (foodTrucksMintedWithAVAX + qty) <=
                (NUM_GEN0_FOOD_TRUCKS -
                    foodTrucksMintedWhitelist -
                    PROMOTIONAL_FOOD_TRUCKS),
            "you can't mint that many right now"
        );

        // calculate the transaction cost
        uint256 transactionCost = FOOD_TRUCK_PRICE_AVAX * qty;
        require(msg.value >= transactionCost, "not enough AVAX");

        foodTrucksMintedWithAVAX += qty;

        // mint foodTrucks
        _createFoodTrucks(qty, _msgSender());
    }

    /**
     * @dev GEN1 minting
     */
    function mintFoodTruckWithHOTDOG(uint256 qty) external whenNotPaused {
        require(mintingStartedHOTDOG(), "cannot mint right now");
        require(qty > 0 && qty <= 10, "quantity must be between 1 and 10");
        require(
            (foodTrucksMintedWithHOTDOG + qty) <= NUM_GEN1_FOOD_TRUCKS,
            "you can't mint that many right now"
        );

        // calculate transaction costs
        uint256 transactionCostHOTDOG = currentHOTDOGMintCost * qty;
        require(
            hotDog.balanceOf(_msgSender()) >= transactionCostHOTDOG,
            "not enough HOTDOG"
        );

        // raise the mint level and cost when this mint would place us in the next level
        // if you mint in the cost transition you get a discount =)
        if (
            foodTrucksMintedWithHOTDOG <= FOOD_TRUCKS_PER_HOTDOG_MINT_LEVEL &&
            foodTrucksMintedWithHOTDOG + qty > FOOD_TRUCKS_PER_HOTDOG_MINT_LEVEL
        ) {
            currentHOTDOGMintCost = currentHOTDOGMintCost * 2;
        }

        foodTrucksMintedWithHOTDOG += qty;

        // spend pizza
        hotDog.burn(_msgSender(), transactionCostHOTDOG);

        // mint foodTrucks
        _createFoodTrucks(qty, _msgSender());
    }

    // Returns information for multiples foodTrucks
    function batchedFoodTrucksOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (FoodTruckInfo[] memory) {
        if (_offset >= balanceOf(_owner)) {
            return new FoodTruckInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= balanceOf(_owner)) {
            outputSize = balanceOf(_owner) - _offset;
        }
        FoodTruckInfo[] memory foodTrucks = new FoodTruckInfo[](outputSize);

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, _offset + i); // tokenOfOwnerByIndex comes from IERC721Enumerable

            foodTrucks[i] = FoodTruckInfo({
                tokenId: tokenId,
                foodTruckType: tokenTypes[tokenId]
            });
        }

        return foodTrucks;
    }

    function random(uint256 number) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % number;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./HotDog.sol";
import "./Juice.sol";

contract Upgrade is ERC721Enumerable, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    struct UpgradeInfo {
        uint256 tokenId;
        uint256 level;
        uint256 yield;
    }
    // Struct

    struct Level {
        uint256 supply;
        uint256 maxSupply;
        uint256 priceHotDog;
        uint256 priceJuice;
        uint256 yield;
    }

    // Var

    HotDog hotDog;
    Juice juice;
    address public hotDoggeriaAddress;

    string public BASE_URI;

    uint256 public startTime;

    mapping(uint256 => Level) public levels;
    uint256 currentLevelIndex;

    uint256 public upgradesMinted = 0;

    uint256 public constant LP_TAX_PERCENT = 2;

    mapping(uint256 => uint256) private tokenLevel;

    // Events

    event onUpgradeCreated(uint256 level);

    // Constructor

    constructor(
        HotDog _hotDog,
        Juice _juice,
        string memory _BASE_URI
    ) ERC721("HotDog Game FoodTruck Tools", "HOTDOG-GAME-FOODTRUCK-TOOL") {
        hotDog = _hotDog;
        juice = _juice;
        BASE_URI = _BASE_URI;

        // first three upgrades
        levels[0] = Level({
            supply: 0,
            maxSupply: 2500,
            priceHotDog: 3000 * 1e18,
            priceJuice: 50 * 1e18,
            yield: 1
        });
        levels[1] = Level({
            supply: 0,
            maxSupply: 2200,
            priceHotDog: 10000 * 1e18,
            priceJuice: 80 * 1e18,
            yield: 3
        });
        levels[2] = Level({
            supply: 0,
            maxSupply: 2000,
            priceHotDog: 20000 * 1e18,
            priceJuice: 110 * 1e18,
            yield: 5
        });
        currentLevelIndex = 2;
    }

    // Views

    function mintingStarted() public view returns (bool) {
        return startTime != 0 && block.timestamp > startTime;
    }

    function getYield(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "token does not exist");
        return levels[tokenLevel[_tokenId]].yield;
    }

    function getLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "token does not exist");
        return tokenLevel[_tokenId];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 levelFixed = tokenLevel[_tokenId] + 1;
        return string(abi.encodePacked(_baseURI(), "/", levelFixed.toString()));
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        if (hotDoggeriaAddress != address(0) && _operator == hotDoggeriaAddress)
            return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    // ADMIN

    function addLevel(
        uint256 _maxSupply,
        uint256 _priceHotDog,
        uint256 _priceJuice,
        uint256 _yield
    ) external onlyOwner {
        currentLevelIndex++;
        levels[currentLevelIndex] = Level({
            supply: 0,
            maxSupply: _maxSupply,
            priceHotDog: _priceHotDog,
            priceJuice: _priceJuice,
            yield: _yield
        });
    }

    function changeLevel(
        uint256 _index,
        uint256 _maxSupply,
        uint256 _priceHotDog,
        uint256 _priceJuice,
        uint256 _yield
    ) external onlyOwner {
        require(_index <= currentLevelIndex, "invalid level");
        levels[_index] = Level({
            supply: 0,
            maxSupply: _maxSupply,
            priceHotDog: _priceHotDog,
            priceJuice: _priceJuice,
            yield: _yield
        });
    }

    function setHotDog(HotDog _hotDog) external onlyOwner {
        hotDog = _hotDog;
    }

    function setJuice(Juice _juice) external onlyOwner {
        juice = _juice;
    }

    function setHotDoggeriaAddress(address _hotDoggeriaAddress)
        external
        onlyOwner
    {
        hotDoggeriaAddress = _hotDoggeriaAddress;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "startTime must be in future");
        require(!mintingStarted(), "minting already started");
        startTime = _startTime;
    }

    function setBaseURI(string calldata _BASE_URI) external onlyOwner {
        BASE_URI = _BASE_URI;
    }

    function forwardERC20s(
        IERC20 _token,
        uint256 _amount,
        address target
    ) external onlyOwner {
        _token.safeTransfer(target, _amount);
    }

    // Minting

    function _createUpgrades(
        uint256 qty,
        uint256 level,
        address to
    ) internal {
        for (uint256 i = 0; i < qty; i++) {
            upgradesMinted += 1;
            levels[level].supply += 1;
            tokenLevel[upgradesMinted] = level;
            _safeMint(to, upgradesMinted);
            emit onUpgradeCreated(level);
        }
    }

    function mintUpgrade(uint256 _level, uint256 _qty) external whenNotPaused {
        require(mintingStarted(), "Tools sales are not open");
        require(_qty > 0 && _qty <= 10, "quantity must be between 1 and 10");
        require(_level <= currentLevelIndex, "invalid level");
        require(
            (levels[_level].supply + _qty) <= levels[_level].maxSupply,
            "you can't mint that many right now"
        );

        uint256 transactionCostHotDog = levels[_level].priceHotDog * _qty;
        uint256 transactionCostJuice = levels[_level].priceJuice * _qty;
        require(
            hotDog.balanceOf(_msgSender()) >= transactionCostHotDog,
            "not have enough HOTDOG"
        );
        require(
            juice.balanceOf(_msgSender()) >= transactionCostJuice,
            "not have enough JUICE"
        );

        _createUpgrades(_qty, _level, _msgSender());

        hotDog.burn(
            _msgSender(),
            (transactionCostHotDog * (100 - LP_TAX_PERCENT)) / 100
        );
        juice.burn(
            _msgSender(),
            (transactionCostJuice * (100 - LP_TAX_PERCENT)) / 100
        );

        hotDog.transferForUpgradesFees(
            _msgSender(),
            (transactionCostHotDog * LP_TAX_PERCENT) / 100
        );
        juice.transferForUpgradesFees(
            _msgSender(),
            (transactionCostJuice * LP_TAX_PERCENT) / 100
        );
    }

    // Returns information for multiples upgrades
    function batchedUpgradesOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (UpgradeInfo[] memory) {
        if (_offset >= balanceOf(_owner)) {
            return new UpgradeInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= balanceOf(_owner)) {
            outputSize = balanceOf(_owner) - _offset;
        }
        UpgradeInfo[] memory upgrades = new UpgradeInfo[](outputSize);

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, _offset + i); // tokenOfOwnerByIndex comes from IERC721Enumerable

            upgrades[i] = UpgradeInfo({
                tokenId: tokenId,
                level: tokenLevel[tokenId],
                yield: levels[tokenLevel[tokenId]].yield
            });
        }
        return upgrades;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HotDog is ERC20("HotDog", "HOTDOG"), Ownable {
    uint256 public constant ONE_HOTDOG = 1e18;
    uint256 public constant NUM_PROMOTIONAL_HOTDOG = 500_000;
    uint256 public constant NUM_HOTDOG_JUICE_LP = 20_000_000;

    uint256 public NUM_HOTDOG_AVAX_LP = 30_000_000;

    address public freezerAddress;
    address public hotDoggeriaAddress;
    address public foodTruckAddress;
    address public upgradeAddress;

    bool public promotionalHotDogMinted = false;
    bool public avaxLPHotDogMinted = false;
    bool public juiceLPHotDogMinted = false;

    // ADMIN

    /**
     * hot doggeria  yields hot dog
     */
    function setHotDoggeriaddress(address _hotDoggeriaAddress)
        external
        onlyOwner
    {
        hotDoggeriaAddress = _hotDoggeriaAddress;
    }

    function setFreezerAddress(address _freezerAddress) external onlyOwner {
        freezerAddress = _freezerAddress;
    }

    function setUpgradeAddress(address _upgradeAddress) external onlyOwner {
        upgradeAddress = _upgradeAddress;
    }

    /**
     * chef consumes hot dog
     * chef address can only be set once
     */
    function setFoodTruckAddress(address _foodTruckAddress) external onlyOwner {
        require(
            address(foodTruckAddress) == address(0),
            "food truck address already set"
        );
        foodTruckAddress = _foodTruckAddress;
    }

    function mintPromotionalHotDog(address _to) external onlyOwner {
        require(
            !promotionalHotDogMinted,
            "promotional hot dog has already been minted"
        );
        promotionalHotDogMinted = true;
        _mint(_to, NUM_PROMOTIONAL_HOTDOG * ONE_HOTDOG);
    }

    function mintAvaxLPHotDog() external onlyOwner {
        require(!avaxLPHotDogMinted, "avax hot dog LP has already been minted");
        avaxLPHotDogMinted = true;
        _mint(owner(), NUM_HOTDOG_AVAX_LP * ONE_HOTDOG);
    }

    function mintJuiceLPHotDog() external onlyOwner {
        require(
            !juiceLPHotDogMinted,
            "juice hot dog LP has already been minted"
        );
        juiceLPHotDogMinted = true;
        _mint(owner(), NUM_HOTDOG_JUICE_LP * ONE_HOTDOG);
    }

    function setNumHotDogAvaxLp(uint256 _numHotDogAvaxLp) external onlyOwner {
        NUM_HOTDOG_AVAX_LP = _numHotDogAvaxLp;
    }

    // external

    function mint(address _to, uint256 _amount) external {
        require(
            hotDoggeriaAddress != address(0) &&
                foodTruckAddress != address(0) &&
                freezerAddress != address(0) &&
                upgradeAddress != address(0),
            "missing initial requirements"
        );
        require(
            _msgSender() == hotDoggeriaAddress,
            "msgsender does not have permission"
        );
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(
            foodTruckAddress != address(0) &&
                freezerAddress != address(0) &&
                upgradeAddress != address(0),
            "missing initial requirements"
        );
        require(
            _msgSender() == foodTruckAddress ||
                _msgSender() == freezerAddress ||
                _msgSender() == upgradeAddress,
            "msgsender does not have permission"
        );
        _burn(_from, _amount);
    }

    function transferToFreezer(address _from, uint256 _amount) external {
        require(freezerAddress != address(0), "missing initial requirements");
        require(
            _msgSender() == freezerAddress,
            "only the freezer contract can call transferToFreezer"
        );
        _transfer(_from, freezerAddress, _amount);
    }

    function transferForUpgradesFees(address _from, uint256 _amount) external {
        require(upgradeAddress != address(0), "missing initial requirements");
        require(
            _msgSender() == upgradeAddress,
            "only the upgrade contract can call transferForUpgradesFees"
        );
        _transfer(_from, upgradeAddress, _amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Juice.sol";

contract HotDoggeriaProgression is Context, Ownable, Pausable {
    // Constants
    uint256[20] public JUICE_LEVELS = [
        0,
        100 * 1e18,
        250 * 1e18,
        450 * 1e18,
        700 * 1e18,
        1000 * 1e18,
        1350 * 1e18,
        1750 * 1e18,
        2200 * 1e18,
        2700 * 1e18,
        3250 * 1e18,
        3850 * 1e18,
        4500 * 1e18,
        5200 * 1e18,
        5950 * 1e18,
        6750 * 1e18,
        7600 * 1e18,
        8500 * 1e18,
        9450 * 1e18,
        10450 * 1e18
    ];
    uint256 public MAX_JUICE_AMOUNT = JUICE_LEVELS[JUICE_LEVELS.length - 1];
    uint256 public constant BURN_ID = 0;
    uint256 public constant FATIGUE_ID = 1;
    uint256 public constant FREEZER_ID = 2;
    uint256 public constant GOLD_FOOD_TRUCK_ID = 3;
    uint256 public constant UPGRADES_ID = 4;
    uint256 public constant FOOD_TRUCKS_ID = 5;
    uint256 public constant DIAMOND_FOOD_TRUCK_ID = 6;
    uint256 public constant SPECIAL_FOOD_TRUCK_ID = 7;
    uint256 public constant BASE_COST_RESPEC = 50 * 1e18;
    uint256[8] public MAX_SKILL_LEVEL = [3, 3, 2, 2, 5, 5, 6, 7];

    Juice public juice;

    uint256 public levelTime;

    mapping(address => uint256) public juiceDeposited; // address => total amount of juice deposited
    mapping(address => uint256) public skillPoints; // address => skill points available
    mapping(address => uint256[8]) public skillsLearned; // address => skill learned.

    constructor(Juice _juice) {
        juice = _juice;
    }

    // EVENTS

    event receivedSkillPoints(address owner, uint256 skillPoints);
    event skillLearned(address owner, uint256 skillGroup, uint256 skillLevel);
    event respec(address owner, uint256 level);

    // Views

    /**
     * Returns the level based on the total juice deposited
     */
    function _getLevel(address _owner) internal view returns (uint256) {
        uint256 totalJuice = juiceDeposited[_owner];

        for (uint256 i = 0; i < JUICE_LEVELS.length - 1; i++) {
            if (totalJuice < JUICE_LEVELS[i + 1]) {
                return i + 1;
            }
        }
        return JUICE_LEVELS.length;
    }

    /**
     * Returns a value representing the % of fatigue after reducing
     */
    function getFatigueSkillModifier(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 fatigueSkill = skillsLearned[_owner][FATIGUE_ID];

        if (fatigueSkill == 3) {
            return 80;
        } else if (fatigueSkill == 2) {
            return 85;
        } else if (fatigueSkill == 1) {
            return 92;
        } else {
            return 100;
        }
    }

    /**
     * Returns a value representing the % that will be reduced from the claim burn
     */
    function getBurnSkillModifier(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 burnSkill = skillsLearned[_owner][BURN_ID];

        if (burnSkill == 3) {
            return 8;
        } else if (burnSkill == 2) {
            return 6;
        } else if (burnSkill == 1) {
            return 3;
        } else {
            return 0;
        }
    }

    /**
     * Returns a value representing the % that will be reduced from the freezer share of the claim
     */
    function getFreezerSkillModifier(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 freezerSkill = skillsLearned[_owner][FREEZER_ID];

        if (freezerSkill == 2) {
            return 9;
        } else if (freezerSkill == 1) {
            return 4;
        } else {
            return 0;
        }
    }

    /**
     * Returns the multiplier for $PIZZA production based on the number of masterchefs and the skill points spent
     */
    function getFoodTruckSkillModifier(
        address _owner,
        uint256 _masterFoodTruckNumber
    ) public view returns (uint256) {
        uint256 goldFoodTruckSkill = skillsLearned[_owner][GOLD_FOOD_TRUCK_ID];
        uint256 diamondFoodTruckSkill = skillsLearned[_owner][
            DIAMOND_FOOD_TRUCK_ID
        ];
        uint256 specialFoodTruckSkill = skillsLearned[_owner][
            SPECIAL_FOOD_TRUCK_ID
        ];

        if (goldFoodTruckSkill == 2 && _masterFoodTruckNumber >= 5) {
            return 110;
        } else if (diamondFoodTruckSkill == 6 && _masterFoodTruckNumber >= 1) {
            return 117;
        } else if (specialFoodTruckSkill == 7 && _masterFoodTruckNumber >= 1) {
            return 124;
        } else if (goldFoodTruckSkill >= 1 && _masterFoodTruckNumber >= 2) {
            return 103;
        } else {
            return 100;
        }
    }

    /**
     * Returns the max level upgrade that can be staked based on the skill points spent
     */
    function getMaxLevelUpgrade(address _owner) public view returns (uint256) {
        uint256 upgradesSkill = skillsLearned[_owner][UPGRADES_ID];

        if (upgradesSkill == 0) {
            return 1; //level id starts at 0, so here are first and second tiers
        } else if (upgradesSkill == 1) {
            return 4;
        } else if (upgradesSkill == 2) {
            return 6;
        } else if (upgradesSkill == 3) {
            return 8;
        } else if (upgradesSkill == 4) {
            return 11;
        } else {
            return 100;
        }
    }

    /**
     * Returns the max number of chefs that can be staked based on the skill points spent
     */
    function getMaxNumberFoodTrucks(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 foodTrucksSkill = skillsLearned[_owner][FOOD_TRUCKS_ID];

        if (foodTrucksSkill == 0) {
            return 10;
        } else if (foodTrucksSkill == 1) {
            return 15;
        } else if (foodTrucksSkill == 2) {
            return 20;
        } else if (foodTrucksSkill == 3) {
            return 30;
        } else if (foodTrucksSkill == 4) {
            return 50;
        } else {
            return 20000;
        }
    }

    // Public views

    /**
     * Returns the Pizzeria level
     */
    function getLevel(address _owner) public view returns (uint256) {
        return _getLevel(_owner);
    }

    /**
     * Returns the $JUICE deposited in the current level
     */
    function getJuiceDeposited(address _owner) public view returns (uint256) {
        uint256 level = _getLevel(_owner);
        uint256 totalJuice = juiceDeposited[_owner];

        return totalJuice - JUICE_LEVELS[level - 1];
    }

    /**
     * Returns the amount of juice required to level up
     */
    function getJuiceToNextLevel(address _owner) public view returns (uint256) {
        uint256 level = _getLevel(_owner);
        if (level == JUICE_LEVELS.length) {
            return 0;
        }
        return JUICE_LEVELS[level] - JUICE_LEVELS[level - 1];
    }

    /**
     * Returns the amount of skills points available to be spent
     */
    function getSkillPoints(address _owner) public view returns (uint256) {
        return skillPoints[_owner];
    }

    /**
     * Returns the current skills levels for each skill group
     */
    function getSkillsLearned(address _owner)
        public
        view
        returns (
            uint256 burn,
            uint256 fatigue,
            uint256 freezer,
            uint256 goldFoodTruck,
            uint256 diamondFoodTruck,
            uint256 specialFoodTruck,
            uint256 upgrades,
            uint256 foodTrucks
        )
    {
        uint256[8] memory skills = skillsLearned[_owner];

        burn = skills[BURN_ID];
        fatigue = skills[FATIGUE_ID];
        freezer = skills[FREEZER_ID];
        goldFoodTruck = skills[GOLD_FOOD_TRUCK_ID];
        diamondFoodTruck = skills[DIAMOND_FOOD_TRUCK_ID];
        specialFoodTruck = skills[SPECIAL_FOOD_TRUCK_ID];
        upgrades = skills[UPGRADES_ID];
        foodTrucks = skills[FOOD_TRUCKS_ID];
    }

    // External

    /**
     * Burns deposited $JUICE and add skill point if level up.
     */
    function depositJuice(uint256 _amount) external whenNotPaused {
        require(levelStarted(), "You can't level yet");
        require(
            _getLevel(_msgSender()) < JUICE_LEVELS.length,
            "already at max level"
        );
        require(juice.balanceOf(_msgSender()) >= _amount, "not enough JUICE");

        if (_amount + juiceDeposited[_msgSender()] > MAX_JUICE_AMOUNT) {
            _amount = MAX_JUICE_AMOUNT - juiceDeposited[_msgSender()];
        }

        uint256 levelBefore = _getLevel(_msgSender());
        juiceDeposited[_msgSender()] += _amount;
        uint256 levelAfter = _getLevel(_msgSender());
        skillPoints[_msgSender()] += levelAfter - levelBefore;

        if (levelAfter == JUICE_LEVELS.length) {
            skillPoints[_msgSender()] += 1;
        }

        emit receivedSkillPoints(_msgSender(), levelAfter - levelBefore);

        juice.burn(_msgSender(), _amount);
    }

    /**
     *  Spend skill point based on the skill group and skill level. Can only spend 1 point at a time.
     */
    function spendSkillPoints(uint256 _skillGroup, uint256 _skillLevel)
        external
        whenNotPaused
    {
        require(skillPoints[_msgSender()] > 0, "Not enough skill points");
        require(_skillGroup <= 5, "Invalid Skill Group");
        require(
            _skillLevel >= 1 && _skillLevel <= MAX_SKILL_LEVEL[_skillGroup],
            "Invalid Skill Level"
        );

        uint256 currentSkillLevel = skillsLearned[_msgSender()][_skillGroup];
        require(
            _skillLevel == currentSkillLevel + 1,
            "Invalid Skill Level jump"
        ); //can only level up 1 point at a time

        skillsLearned[_msgSender()][_skillGroup] = _skillLevel;
        skillPoints[_msgSender()]--;

        emit skillLearned(_msgSender(), _skillGroup, _skillLevel);
    }

    /**
     *  Resets skills learned for a fee
     */
    function resetSkills() external whenNotPaused {
        uint256 level = _getLevel(_msgSender());
        uint256 costToRespec = level * BASE_COST_RESPEC;
        require(level > 1, "you are still at level 1");
        require(
            juice.balanceOf(_msgSender()) >= costToRespec,
            "not enough JUICE"
        );

        skillsLearned[_msgSender()][BURN_ID] = 0;
        skillsLearned[_msgSender()][FATIGUE_ID] = 0;
        skillsLearned[_msgSender()][FREEZER_ID] = 0;
        skillsLearned[_msgSender()][GOLD_FOOD_TRUCK_ID] = 0;
        skillsLearned[_msgSender()][DIAMOND_FOOD_TRUCK_ID] = 0;
        skillsLearned[_msgSender()][SPECIAL_FOOD_TRUCK_ID] = 0;
        skillsLearned[_msgSender()][UPGRADES_ID] = 0;
        skillsLearned[_msgSender()][FOOD_TRUCKS_ID] = 0;

        skillPoints[_msgSender()] = level - 1;

        if (level == 20) {
            skillPoints[_msgSender()]++;
        }

        juice.burn(_msgSender(), costToRespec);

        emit respec(_msgSender(), level);
    }

    // Admin

    function levelStarted() public view returns (bool) {
        return levelTime != 0 && block.timestamp >= levelTime;
    }

    function setLevelStartTime(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        require(!levelStarted(), "leveling already started");
        levelTime = _startTime;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Supply cap of 15,000,000
contract Juice is ERC20Capped(15_000_000 * 1e18), Ownable {
    address public upgradeAddress;
    address public hotDoggeriaAddress;

    constructor() ERC20("Juice", "JUICE") {}

    function setUpgradeAddress(address _upgradeAddress) external onlyOwner {
        upgradeAddress = _upgradeAddress;
    }

    function setHotDoggeriaAddressAddress(address _hotDoggeriaAddress)
        external
        onlyOwner
    {
        hotDoggeriaAddress = _hotDoggeriaAddress;
    }

    // external

    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0));
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(
            upgradeAddress != address(0) && hotDoggeriaAddress != address(0),
            "missing initial requirements"
        );
        require(
            _msgSender() == upgradeAddress ||
                _msgSender() == hotDoggeriaAddress,
            "msgsender does not have permission"
        );
        _burn(_from, _amount);
    }

    function transferForUpgradesFees(address _from, uint256 _amount) external {
        require(upgradeAddress != address(0), "missing initial requirements");
        require(
            _msgSender() == upgradeAddress,
            "only the upgrade contract can call transferForUpgradesFees"
        );
        _transfer(_from, upgradeAddress, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}