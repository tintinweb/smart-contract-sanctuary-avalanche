// Winery
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// Open Zeppelin libraries for controlling upgradability and access.
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Vintner.sol";
import "./Upgrade.sol";
import "./VintageWine.sol";

interface IWineryProgression {
    function getFatigueSkillModifier(address owner)
        external
        view
        returns (uint256);

    function getBurnSkillModifier(address owner)
        external
        view
        returns (uint256);

    function getCellarSkillModifier(address owner)
        external
        view
        returns (uint256);

    function getMasterVintnerSkillModifier(
        address owner,
        uint256 masterVintnerNumber
    ) external view returns (uint256);

    function getMaxLevelUpgrade(address owner) external view returns (uint256);

    function getMaxNumberVintners(address owner)
        external
        view
        returns (uint256);

    // function getMafiaModifier(address owner) external view returns (uint256);
    function getVintageWineStorage(address owner)
        external
        view
        returns (uint256);
}

// interface IMafia {
//     function mafiaIsActive() external view returns (bool);
//     function mafiaCurrentPenalty() external view returns (uint256);
// }

contract Winery is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // Constants
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 public constant CLAIM_VINTAGEWINE_CONTRIBUTION_PERCENTAGE = 10;
    uint256 public constant CLAIM_VINTAGEWINE_BURN_PERCENTAGE = 10;
    uint256 public constant MAX_FATIGUE = 100000000000000;

    // Staking

    mapping(uint256 => address) public stakedVintners; // tokenId => owner

    mapping(address => uint256) public fatiguePerMinute; // address => fatigue per minute in the winery
    mapping(address => uint256) public wineryFatigue; // address => fatigue
    mapping(address => uint256) public wineryVintageWine; // address => vintage
    mapping(address => uint256) public totalPPM; // address => total VPM
    mapping(address => uint256) public startTimeStamp; // address => startTimeStamp

    mapping(address => uint256[2]) public numberOfStaked; // address => [number of vintners, number of master vintners]

    mapping(uint256 => address) public stakedUpgrades; // tokenId => owner

    // Enumeration
    mapping(address => mapping(uint256 => uint256)) public ownedVintnerStakes; // (address, index) => tokenid
    mapping(uint256 => uint256) public ownedVintnerStakesIndex; // tokenId => index in its owner's stake list
    mapping(address => uint256) public ownedVintnerStakesBalance; // address => stake count

    mapping(address => mapping(uint256 => uint256)) public ownedUpgradeStakes; // (address, index) => tokenid
    mapping(uint256 => uint256) public ownedUpgradeStakesIndex; // tokenId => index in its owner's stake list
    mapping(address => uint256) public ownedUpgradeStakesBalance; // address => stake count

    // Fatigue cooldowns
    mapping(uint256 => uint256) public restingVintners; // tokenId => timestamp until rested. 0 if is not resting

    // Var

    uint256 public yieldPPS; // vintage per second per unit of yield

    uint256 public startTime;

    uint256 public grapeResetCost; // 1 Grape is the cost per VPM

    uint256 public unstakePenalty; // Everytime someone unstake they need to pay this tax from the unclaimed amount

    uint256 public fatigueTuner;

    Vintner public vintner;
    Upgrade public upgrade;
    VintageWine public vintageWine;
    IGrape public grape;
    address public cellarAddress;
    IWineryProgression public wineryProgression;

    // IMafia public mafia;
    // address public mafiaAddress;

    function initialize(
        Vintner _vintner,
        Upgrade _upgrade,
        VintageWine _vintageWine,
        address _grape,
        address _cellarAddress,
        address _wineryProgression
    ) public initializer {
        vintner = _vintner;
        grape = IGrape(_grape);
        upgrade = _upgrade;
        vintageWine = _vintageWine;
        cellarAddress = _cellarAddress;
        wineryProgression = IWineryProgression(_wineryProgression);

        yieldPPS = 4166666666666667; // vintage per second per unit of yield
        startTime;
        grapeResetCost = 1e18; // 1 Grape is the cost per VPM
        unstakePenalty = 1000 * 1e18; // Everytime someone unstake they need to pay this tax from the unclaimed amount
        fatigueTuner = 100;

        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Setters
    function setVintageWine(VintageWine _vintageWine) external onlyOwner {
        vintageWine = _vintageWine;
    }

    function setCellarAddress(address _cellarAddress) external onlyOwner {
        cellarAddress = _cellarAddress;
    }

    // function setVintner(Vintner _vintner) external onlyOwner {
    //     vintner = _vintner;
    // }

    // function setUpgrade(Upgrade _upgrade) external onlyOwner {
    //     upgrade = _upgrade;
    // }

    function setYieldPPS(uint256 _yieldPPS) external onlyOwner {
        yieldPPS = _yieldPPS;
    }

    function setGrapeResetCost(uint256 _grapeResetCost) external onlyOwner {
        grapeResetCost = _grapeResetCost;
    }

    function setUnstakePenalty(uint256 _unstakePenalty) external onlyOwner {
        unstakePenalty = _unstakePenalty;
    }

    function setFatigueTuner(uint256 _fatigueTuner) external onlyOwner {
        fatigueTuner = _fatigueTuner;
    }

    function setGrape(address _grape) external onlyOwner {
        grape = IGrape(_grape);
    }

    function setWineryProgression(address _wineryProgression)
        external
        onlyOwner
    {
        wineryProgression = IWineryProgression(_wineryProgression);
    }

    // function setMafia(address _mafia) external onlyOwner {
    //     mafiaAddress = _mafia;
    //     mafia = IMafia(_mafia);
    // }
    // Calculations

    /**
     * Updates the Fatigue per Minute
     * This function is called in _updateState
     */

    function fatiguePerMinuteCalculation(uint256 _ppm)
        public
        pure
        returns (uint256)
    {
        // NOTE: fatiguePerMinute[_owner] = 8610000000 + 166000000  * totalPPM[_owner] + -220833 * totalPPM[_owner]* totalPPM[_owner]  + 463 * totalPPM[_owner]*totalPPM[_owner]*totalPPM[_owner];
        uint256 a = 463;
        uint256 b = 220833;
        uint256 c = 166000000;
        uint256 d = 8610000000;
        if (_ppm == 0) {
            return 0;
        }
        return d + c * _ppm + a * _ppm * _ppm * _ppm - b * _ppm * _ppm;
    }

    /**
     * Returns the timestamp of when the entire winery will be fatigued
     */
    function timeUntilFatiguedCalculation(
        uint256 _startTime,
        uint256 _fatigue,
        uint256 _fatiguePerMinute
    ) public pure returns (uint256) {
        if (_fatiguePerMinute == 0) {
            return _startTime + 31536000; // 1 year in seconds, arbitrary long duration
        }
        return _startTime + (60 * (MAX_FATIGUE - _fatigue)) / _fatiguePerMinute;
    }

    /**
     * Returns the timestamp of when the vintner will be fully rested
     */
    function restingTimeCalculation(
        uint256 _vintnerType,
        uint256 _masterVintnerType,
        uint256 _fatigue
    ) public pure returns (uint256) {
        uint256 maxTime = 43200; //12*60*60
        if (_vintnerType == _masterVintnerType) {
            maxTime = maxTime / 2; // master vintners rest half of the time of regular vintners
        }

        if (_fatigue > MAX_FATIGUE / 2) {
            return (maxTime * _fatigue) / MAX_FATIGUE;
        }

        return maxTime / 2; // minimum rest time is half of the maximum time
    }

    /**
     * Returns vintner's vintageWine from vintnerVintageWine mapping
     */
    function vintageWineAccruedCalculation(
        uint256 _initialVintageWine,
        uint256 _deltaTime,
        uint256 _ppm,
        uint256 _modifier,
        uint256 _fatigue,
        uint256 _fatiguePerMinute,
        uint256 _yieldPPS
    ) public pure returns (uint256) {
        if (_fatigue >= MAX_FATIGUE) {
            return _initialVintageWine;
        }

        uint256 a = (_deltaTime *
            _ppm *
            _yieldPPS *
            _modifier *
            (MAX_FATIGUE - _fatigue)) / (100 * MAX_FATIGUE);
        uint256 b = (_deltaTime *
            _deltaTime *
            _ppm *
            _yieldPPS *
            _modifier *
            _fatiguePerMinute) / (100 * 2 * 60 * MAX_FATIGUE);
        if (a > b) {
            return _initialVintageWine + a - b;
        }

        return _initialVintageWine;
    }

    // Views

    function getFatiguePerMinuteWithModifier(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 fatigueSkillModifier = wineryProgression
            .getFatigueSkillModifier(_owner);
        return
            (fatiguePerMinute[_owner] * fatigueSkillModifier * fatigueTuner) /
            (100 * 100);
    }

    // function getCommonVintnerNumber(address _owner)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return numberOfStaked[_owner][0];
    // }

    function getMasterVintnerNumber(address _owner)
        public
        view
        returns (uint256)
    {
        return numberOfStaked[_owner][1];
    }

    /**
     * Returns the current vintner's fatigue
     */
    function getFatigueAccrued(address _owner) public view returns (uint256) {
        uint256 fatigue = ((block.timestamp - startTimeStamp[_owner]) *
            getFatiguePerMinuteWithModifier(_owner)) / 60;
        fatigue += wineryFatigue[_owner];
        if (fatigue > MAX_FATIGUE) {
            fatigue = MAX_FATIGUE;
        }
        return fatigue;
    }

    function getTimeUntilFatigued(address _owner)
        public
        view
        returns (uint256)
    {
        return
            timeUntilFatiguedCalculation(
                startTimeStamp[_owner],
                wineryFatigue[_owner],
                getFatiguePerMinuteWithModifier(_owner)
            );
    }

    function getRestingTime(uint256 _tokenId, address _owner)
        public
        view
        returns (uint256)
    {
        return
            restingTimeCalculation(
                vintner.getType(_tokenId),
                vintner.MASTER_VINTNER_TYPE(),
                getFatigueAccrued(_owner)
            );
    }

    function getVintageWineAccrued(address _owner)
        public
        view
        returns (uint256)
    {
        // if fatigueLastUpdate = MAX_FATIGUE it means that wineryVintageWine already has the correct value for the vintageWine, since it didn't produce vintageWine since last update
        uint256 fatigueLastUpdate = wineryFatigue[_owner];
        if (fatigueLastUpdate == MAX_FATIGUE) {
            return wineryVintageWine[_owner];
        }

        uint256 timeUntilFatigued = getTimeUntilFatigued(_owner);

        uint256 endTimestamp;
        if (block.timestamp >= timeUntilFatigued) {
            endTimestamp = timeUntilFatigued;
        } else {
            endTimestamp = block.timestamp;
        }

        uint256 ppm = getTotalPPM(_owner);

        uint256 masterVintnerSkillModifier = wineryProgression
            .getMasterVintnerSkillModifier(
                _owner,
                getMasterVintnerNumber(_owner)
            );

        uint256 delta = endTimestamp - startTimeStamp[_owner];

        uint256 newVintageWineAmount = vintageWineAccruedCalculation(
            wineryVintageWine[_owner],
            delta,
            ppm,
            masterVintnerSkillModifier,
            fatigueLastUpdate,
            getFatiguePerMinuteWithModifier(_owner),
            yieldPPS
        );

        uint256 maxVintageWine = wineryProgression.getVintageWineStorage(
            _owner
        );

        if (newVintageWineAmount > maxVintageWine) {
            return maxVintageWine;
        }
        return newVintageWineAmount;
    }

    /**
     * Calculates the total VPM staked for a winery.
     * This will also be used in the fatiguePerMinute calculation
     */
    function getTotalPPM(address _owner) public view returns (uint256) {
        return totalPPM[_owner];
    }

    function _updatefatiguePerMinute(address _owner) internal {
        uint256 ppm = totalPPM[_owner];
        if (ppm == 0) {
            delete wineryFatigue[_owner];
        }
        fatiguePerMinute[_owner] = fatiguePerMinuteCalculation(ppm);
    }

    //Claim
    function _claimVintageWine(address _owner) internal {
        uint256 cellarSkillModifier = wineryProgression.getCellarSkillModifier(
            _owner
        );
        uint256 burnSkillModifier = wineryProgression.getBurnSkillModifier(
            _owner
        );

        uint256 totalClaimed = getVintageWineAccrued(_owner);

        delete wineryVintageWine[_owner];

        wineryFatigue[_owner] = getFatigueAccrued(_owner);

        startTimeStamp[_owner] = block.timestamp;

        uint256 taxAmountCellar = (totalClaimed *
            (CLAIM_VINTAGEWINE_CONTRIBUTION_PERCENTAGE - cellarSkillModifier)) /
            100;
        uint256 taxAmountBurn = (totalClaimed *
            (CLAIM_VINTAGEWINE_BURN_PERCENTAGE - burnSkillModifier)) / 100;

        // uint256 taxAmountMafia = 0;
        // if(mafiaAddress != address(0) && mafia.mafiaIsActive()){
        //     uint256 mafiaSkillModifier = wineryProgression.getMafiaModifier(_owner);
        //     uint256 penalty = mafia.mafiaCurrentPenalty();
        //     if(penalty < mafiaSkillModifier){
        //         taxAmountMafia = 0;
        //     } else {
        //         taxAmountMafia = totalClaimed * (penalty - mafiaSkillModifier) / 100;
        //     }
        // }

        // totalClaimed = totalClaimed - taxAmountCellar - taxAmountBurn - taxAmountMafia;
        totalClaimed = totalClaimed - taxAmountCellar - taxAmountBurn;

        vintageWine.mint(_owner, totalClaimed);
        vintageWine.mint(cellarAddress, taxAmountCellar);
    }

    function claimVintageWine() public {
        address owner = msg.sender;
        _claimVintageWine(owner);
    }

    function _updateState(address _owner) internal {
        wineryVintageWine[_owner] = getVintageWineAccrued(_owner);

        wineryFatigue[_owner] = getFatigueAccrued(_owner);

        startTimeStamp[_owner] = block.timestamp;
    }

    //Resets fatigue and claims
    //Will need to approve grape first
    function resetFatigue() public {
        address _owner = msg.sender;
        uint256 ppm = getTotalPPM(_owner);
        uint256 costToReset = ppm * grapeResetCost;
        require(grape.balanceOf(_owner) >= costToReset, "not enough GRAPE");

        grape.transferFrom(address(_owner), DEAD_ADDRESS, costToReset);

        wineryVintageWine[_owner] = getVintageWineAccrued(_owner);
        startTimeStamp[_owner] = block.timestamp;
        delete wineryFatigue[_owner];
    }

    function _taxUnstake(address _owner, uint256 _taxableAmount) internal {
        uint256 totalClaimed = getVintageWineAccrued(_owner);
        uint256 penaltyCost = _taxableAmount * unstakePenalty;
        require(
            totalClaimed >= penaltyCost,
            "Not enough Vintage to pay the unstake penalty."
        );

        wineryVintageWine[_owner] = totalClaimed - penaltyCost;

        wineryFatigue[_owner] = getFatigueAccrued(_owner);

        startTimeStamp[_owner] = block.timestamp;
    }

    function unstakeVintnersAndUpgrades(
        uint256[] calldata _vintnerIds,
        uint256[] calldata _upgradeIds
    ) public {
        address owner = msg.sender;
        // Check 1:1 correspondency between vintner and upgrade
        require(
            numberOfStaked[owner][0] + numberOfStaked[owner][1] >=
                _vintnerIds.length,
            "Invalid number of vintners"
        );
        require(
            ownedUpgradeStakesBalance[owner] >= _upgradeIds.length,
            "Invalid number of tools"
        );
        require(
            numberOfStaked[owner][0] +
                numberOfStaked[owner][1] -
                _vintnerIds.length >=
                ownedUpgradeStakesBalance[owner] - _upgradeIds.length,
            "Needs at least vintner for each tool"
        );

        uint256 upgradeLength = _upgradeIds.length;
        uint256 vintnerLength = _vintnerIds.length;

        _taxUnstake(owner, upgradeLength + vintnerLength);

        for (uint256 i = 0; i < upgradeLength; i++) {
            //unstake upgrades
            uint256 upgradeId = _upgradeIds[i];

            require(
                stakedUpgrades[upgradeId] == owner,
                "You don't own this tool"
            );

            upgrade.transferFrom(address(this), owner, upgradeId);

            totalPPM[owner] -= upgrade.getYield(upgradeId);

            _removeUpgrade(upgradeId, owner);
        }

        for (uint256 i = 0; i < vintnerLength; i++) {
            //unstake vintners
            uint256 vintnerId = _vintnerIds[i];

            require(
                stakedVintners[vintnerId] == owner,
                "You don't own this token"
            );
            require(restingVintners[vintnerId] == 0, "Vintner is resting");

            if (vintner.getType(vintnerId) == vintner.MASTER_VINTNER_TYPE()) {
                numberOfStaked[owner][1]--;
            } else {
                numberOfStaked[owner][0]--;
            }

            totalPPM[owner] -= vintner.getYield(vintnerId);

            _moveVintnerToCooldown(vintnerId, owner);
        }

        _updatefatiguePerMinute(owner);
    }

    // Stake

    /**
     * This function updates stake vintners and upgrades
     * The upgrades are paired with the vintner the upgrade will be applied
     */
    function stakeMany(
        uint256[] calldata _vintnerIds,
        uint256[] calldata _upgradeIds
    ) public {
        require(gameStarted(), "The game has not started");

        address owner = msg.sender;

        uint256 maxNumberVintners = wineryProgression.getMaxNumberVintners(
            owner
        );
        uint256 vintnersAfterStaking = _vintnerIds.length +
            numberOfStaked[owner][0] +
            numberOfStaked[owner][1];
        require(
            maxNumberVintners >= vintnersAfterStaking,
            "You can't stake that many vintners"
        );

        // Check 1:1 correspondency between vintner and upgrade
        require(
            vintnersAfterStaking >=
                ownedUpgradeStakesBalance[owner] + _upgradeIds.length,
            "Needs at least vintner for each tool"
        );

        _updateState(owner);

        uint256 vintnerLength = _vintnerIds.length;
        for (uint256 i = 0; i < vintnerLength; i++) {
            //stakes vintner
            uint256 vintnerId = _vintnerIds[i];

            require(
                vintner.ownerOf(vintnerId) == owner,
                "You don't own this token"
            );
            require(vintner.getType(vintnerId) > 0, "Vintner not yet revealed");

            if (vintner.getType(vintnerId) == vintner.MASTER_VINTNER_TYPE()) {
                numberOfStaked[owner][1]++;
            } else {
                numberOfStaked[owner][0]++;
            }

            totalPPM[owner] += vintner.getYield(vintnerId);

            _addVintnerToWinery(vintnerId, owner);

            vintner.transferFrom(owner, address(this), vintnerId);
        }
        uint256 maxLevelUpgrade = wineryProgression.getMaxLevelUpgrade(owner);
        uint256 upgradeLength = _upgradeIds.length;
        for (uint256 i = 0; i < upgradeLength; i++) {
            //stakes upgrades
            uint256 upgradeId = _upgradeIds[i];

            require(
                upgrade.ownerOf(upgradeId) == owner,
                "You don't own this tool"
            );
            require(
                upgrade.getLevel(upgradeId) <= maxLevelUpgrade,
                "You can't equip that tool"
            );

            totalPPM[owner] += upgrade.getYield(upgradeId);

            _addUpgradeToWinery(upgradeId, owner);

            upgrade.transferFrom(owner, address(this), upgradeId);
        }
        _updatefatiguePerMinute(owner);
    }

    function withdrawVintners(uint256[] calldata _vintnerIds) public {
        address owner = msg.sender;
        uint256 vintnerLength = _vintnerIds.length;
        for (uint256 i = 0; i < vintnerLength; i++) {
            uint256 _vintnerId = _vintnerIds[i];

            require(restingVintners[_vintnerId] != 0, "Vintner is not resting");
            require(
                stakedVintners[_vintnerId] == owner,
                "You don't own this vintner"
            );
            require(
                block.timestamp >= restingVintners[_vintnerId],
                "Vintner is still resting"
            );

            _removeVintnerFromCooldown(_vintnerId, owner);

            vintner.transferFrom(address(this), owner, _vintnerId);
        }
    }

    function reStakeRestedVintners(uint256[] calldata _vintnerIds) public {
        address owner = msg.sender;

        uint256 maxNumberVintners = wineryProgression.getMaxNumberVintners(
            owner
        );
        uint256 vintnersAfterStaking = _vintnerIds.length +
            numberOfStaked[owner][0] +
            numberOfStaked[owner][1];
        require(
            maxNumberVintners >= vintnersAfterStaking,
            "You can't stake that many vintners"
        );

        _updateState(owner);

        uint256 vintnerLength = _vintnerIds.length;
        for (uint256 i = 0; i < vintnerLength; i++) {
            //stakes vintner
            uint256 _vintnerId = _vintnerIds[i];

            require(restingVintners[_vintnerId] != 0, "Vintner is not resting");
            require(
                stakedVintners[_vintnerId] == owner,
                "You don't own this vintner"
            );
            require(
                block.timestamp >= restingVintners[_vintnerId],
                "Vintner is still resting"
            );

            delete restingVintners[_vintnerId];

            if (vintner.getType(_vintnerId) == vintner.MASTER_VINTNER_TYPE()) {
                numberOfStaked[owner][1]++;
            } else {
                numberOfStaked[owner][0]++;
            }

            totalPPM[owner] += vintner.getYield(_vintnerId);
        }
        _updatefatiguePerMinute(owner);
    }

    function _addVintnerToWinery(uint256 _tokenId, address _owner) internal {
        stakedVintners[_tokenId] = _owner;
        uint256 length = ownedVintnerStakesBalance[_owner];
        ownedVintnerStakes[_owner][length] = _tokenId;
        ownedVintnerStakesIndex[_tokenId] = length;
        ownedVintnerStakesBalance[_owner]++;
    }

    function _addUpgradeToWinery(uint256 _tokenId, address _owner) internal {
        stakedUpgrades[_tokenId] = _owner;
        uint256 length = ownedUpgradeStakesBalance[_owner];
        ownedUpgradeStakes[_owner][length] = _tokenId;
        ownedUpgradeStakesIndex[_tokenId] = length;
        ownedUpgradeStakesBalance[_owner]++;
    }

    function _moveVintnerToCooldown(uint256 _vintnerId, address _owner)
        internal
    {
        uint256 endTimestamp = block.timestamp +
            getRestingTime(_vintnerId, _owner);
        restingVintners[_vintnerId] = endTimestamp;
    }

    function _removeVintnerFromCooldown(uint256 _vintnerId, address _owner)
        internal
    {
        delete restingVintners[_vintnerId];
        delete stakedVintners[_vintnerId];

        uint256 lastTokenIndex = ownedVintnerStakesBalance[_owner] - 1;
        uint256 tokenIndex = ownedVintnerStakesIndex[_vintnerId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedVintnerStakes[_owner][lastTokenIndex];

            ownedVintnerStakes[_owner][tokenIndex] = lastTokenId;
            ownedVintnerStakesIndex[lastTokenId] = tokenIndex;
        }

        delete ownedVintnerStakesIndex[_vintnerId];
        delete ownedVintnerStakes[_owner][lastTokenIndex];
        ownedVintnerStakesBalance[_owner]--;
    }

    function _removeUpgrade(uint256 _upgradeId, address _owner) internal {
        delete stakedUpgrades[_upgradeId];

        uint256 lastTokenIndex = ownedUpgradeStakesBalance[_owner] - 1;
        uint256 tokenIndex = ownedUpgradeStakesIndex[_upgradeId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedUpgradeStakes[_owner][lastTokenIndex];

            ownedUpgradeStakes[_owner][tokenIndex] = lastTokenId;
            ownedUpgradeStakesIndex[lastTokenId] = tokenIndex;
        }

        delete ownedUpgradeStakesIndex[_upgradeId];
        delete ownedUpgradeStakes[_owner][lastTokenIndex];
        ownedUpgradeStakesBalance[_owner]--;
    }

    // Admin

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

    // Aggregated views
    struct StakedVintnerInfo {
        uint256 vintnerId;
        uint256 vintnerPPM;
        bool isResting;
        uint256 endTimestamp;
    }

    function batchedStakesOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (StakedVintnerInfo[] memory) {
        if (_offset >= ownedVintnerStakesBalance[_owner]) {
            return new StakedVintnerInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= ownedVintnerStakesBalance[_owner]) {
            outputSize = ownedVintnerStakesBalance[_owner] - _offset;
        }
        StakedVintnerInfo[] memory outputs = new StakedVintnerInfo[](
            outputSize
        );

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 vintnerId = ownedVintnerStakes[_owner][_offset + i];

            outputs[i] = StakedVintnerInfo({
                vintnerId: vintnerId,
                vintnerPPM: vintner.getYield(vintnerId),
                isResting: restingVintners[vintnerId] > 0,
                endTimestamp: restingVintners[vintnerId]
            });
        }

        return outputs;
    }

    struct StakedToolInfo {
        uint256 toolId;
        uint256 toolPPM;
    }

    function batchedToolsOfOwner(
        address _owner,
        uint256 _offset,
        uint256 _maxSize
    ) public view returns (StakedToolInfo[] memory) {
        if (_offset >= ownedUpgradeStakesBalance[_owner]) {
            return new StakedToolInfo[](0);
        }

        uint256 outputSize = _maxSize;
        if (_offset + _maxSize >= ownedUpgradeStakesBalance[_owner]) {
            outputSize = ownedUpgradeStakesBalance[_owner] - _offset;
        }
        StakedToolInfo[] memory outputs = new StakedToolInfo[](outputSize);

        for (uint256 i = 0; i < outputSize; i++) {
            uint256 toolId = ownedUpgradeStakes[_owner][_offset + i];

            outputs[i] = StakedToolInfo({
                toolId: toolId,
                toolPPM: upgrade.getYield(toolId)
            });
        }

        return outputs;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// Chef
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./libraries/ERC2981.sol";

contract Vintner is Ownable, Pausable, RoyaltiesAddon, ERC2981 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    struct VintnerInfo {
        uint256 tokenId;
        uint256 vintnerType;
    }

    // CONSTANTS

    uint256 public constant VINTNER_PRICE_AVAX = 2.5 ether;
    uint256 public constant VINTNER_PRICE_GRAPE = 50 * 1e18;

    uint256 public WHITELIST_VINTNERS = 2700;
    uint256 public constant NUM_VINTNERS = 10_000;

    uint256 public constant VINTNER_TYPE = 1;
    uint256 public constant MASTER_VINTNER_TYPE = 2;

    uint256 public constant VINTNER_YIELD = 1;
    uint256 public constant MASTER_VINTNER_YIELD = 3;

    uint256 public constant PROMOTIONAL_VINTNERS = 50;

    // VAR
    // external contracts
    IERC20 public grapeAddress;
    // address public wineryAddress;
    address public vintnerTypeOracleAddress;

    // metadata URI
    string public BASE_URI;
    uint256 private royaltiesFees;

    // vintner type definitions (normal or master?)
    mapping(uint256 => uint256) public tokenTypes; // maps tokenId to its type
    mapping(uint256 => uint256) public typeYields; // maps vintner type to yield

    // mint tracking
    uint256 public vintnerPublicMinted;
    uint256 public vintnersMintedWhitelist;
    uint256 public vintnersMintedPromotional;
    uint256 public vintnersMinted = 50; // First 50 ids are reserved for the promotional vintners

    // mint control timestamps
    uint256 public startTimeWhitelist;
    uint256 public startTime;

    // whitelist
    address public couponSigner;
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
    mapping(address => uint256) public whitelistClaimed;

    // EVENTS

    event onVintnerCreated(uint256 tokenId);
    event onVintnerRevealed(uint256 tokenId, uint256 vintnerType);

    /**
     * requires vintageWine, vintnerType oracle address
     * vintageWine: for liquidity bootstrapping and spending on vintners
     * vintnerTypeOracleAddress: external vintner generator uses secure RNG
     */
    constructor(
        address _grapeAddress,
        address _couponSigner,
        address _vintnerTypeOracleAddress,
        string memory _BASE_URI
    ) ERC721("The Vintners", "The VINTNERS") {
        couponSigner = _couponSigner;
        require(_vintnerTypeOracleAddress != address(0));

        // set required contract references
        grapeAddress = IERC20(_grapeAddress);
        vintnerTypeOracleAddress = _vintnerTypeOracleAddress;

        // set base uri
        BASE_URI = _BASE_URI;

        // initialize token yield values for each vintner type
        typeYields[VINTNER_TYPE] = VINTNER_YIELD;
        typeYields[MASTER_VINTNER_TYPE] = MASTER_VINTNER_YIELD;
    }

    // VIEWS

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // minting status

    function mintingStartedWhitelist() public view returns (bool) {
        return startTimeWhitelist != 0 && block.timestamp >= startTimeWhitelist;
    }

    function mintingStarted() public view returns (bool) {
        return startTime != 0 && block.timestamp >= startTime;
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
        return
            string(
                abi.encodePacked(_baseURI(), "/", tokenId.toString(), ".json")
            );
    }

    // override

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        // winery must be able to stake and unstake
        if (wineryAddress != address(0) && _operator == wineryAddress)
            return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    // ADMIN

    function setGrapeAddress(address _grapeAddress) external onlyOwner {
        grapeAddress = IERC20(_grapeAddress);
    }

    function setWineryAddress(address _wineryAddress) external onlyOwner {
        wineryAddress = _wineryAddress;
        super._setWineryAddress(_wineryAddress);
    }

    function setvintnerTypeOracleAddress(address _vintnerTypeOracleAddress)
        external
        onlyOwner
    {
        vintnerTypeOracleAddress = _vintnerTypeOracleAddress;
    }

    function setStartTimeWhitelist(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTimeWhitelist = _startTime;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(
            _startTime >= block.timestamp,
            "startTime cannot be in the past"
        );
        startTime = _startTime;
    }

    function setBaseURI(string calldata _BASE_URI) external onlyOwner {
        BASE_URI = _BASE_URI;
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
        (bool sent, ) = to.call{ value: _amount }("");
        require(sent, "Failed to send AVAX");
    }

    // MINTING

    function _createVintner(address to, uint256 tokenId) internal {
        require(vintnersMinted <= NUM_VINTNERS, "cannot mint anymore vintners");
        _safeMint(to, tokenId);

        emit onVintnerCreated(tokenId);
    }

    function _createVintners(uint256 qty, address to) internal {
        for (uint256 i = 0; i < qty; i++) {
            vintnersMinted += 1;
            _createVintner(to, vintnersMinted);
        }
    }

    /**
     * @dev as an anti cheat mechanism, an external automation will generate the NFT metadata and set the vintner types via rng
     * - Using an external source of randomness ensures our mint cannot be cheated
     * - The external automation is open source and can be found on vintageWine game's github
     * - Once the mint is finished, it is provable that this randomness was not tampered with by providing the seed
     * - Vintner type can be set only once
     */
    function setVintnerType(uint256 tokenId, uint256 vintnerType) external {
        require(
            _msgSender() == vintnerTypeOracleAddress,
            "msgsender does not have permission"
        );
        require(
            tokenTypes[tokenId] == 0,
            "that token's type has already been set"
        );
        require(
            vintnerType == VINTNER_TYPE || vintnerType == MASTER_VINTNER_TYPE,
            "invalid vintner type"
        );

        tokenTypes[tokenId] = vintnerType;
        emit onVintnerRevealed(tokenId, vintnerType);
    }

    /**
     * @dev Promotional minting
     * Can mint maximum of PROMOTIONAL_VINTNERS
     * All vintners minted are from the same vintnerType
     */
    function mintPromotional(
        uint256 qty,
        uint256 vintnerType,
        address target
    ) external onlyOwner {
        require(qty > 0, "quantity must be greater than 0");
        require(
            (vintnersMintedPromotional + qty) <= PROMOTIONAL_VINTNERS,
            "you can't mint that many right now"
        );
        require(
            vintnerType == VINTNER_TYPE || vintnerType == MASTER_VINTNER_TYPE,
            "invalid vintner type"
        );

        for (uint256 i = 0; i < qty; i++) {
            vintnersMintedPromotional += 1;
            require(
                tokenTypes[vintnersMintedPromotional] == 0,
                "that token's type has already been set"
            );
            tokenTypes[vintnersMintedPromotional] = vintnerType;
            _createVintner(target, vintnersMintedPromotional);
        }
    }

    /**
     * @dev Whitelist minting
     * We implement a hard limit on the whitelist vintners.
     */

    function setWhitelistMintCount(uint256 qty) external onlyOwner {
        require(qty > 0, "quantity must be greater than 0");
        WHITELIST_VINTNERS = qty;
    }

    /**
     * * Set Coupon Signer
     * @dev Set the coupon signing wallet
     * @param couponSigner_ The new coupon signing wallet address
     */
    function setCouponSigner(address couponSigner_) external onlyOwner {
        couponSigner = couponSigner_;
    }

    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "Zero Address");
        return signer == couponSigner;
    }

    function mintWhitelist(
        uint256 qty,
        uint256 allotted,
        Coupon memory coupon
    ) external whenNotPaused {
        // check most basic requirements
        require(mintingStartedWhitelist(), "cannot mint right now");
        require(
            qty + whitelistClaimed[_msgSender()] < allotted + 1,
            "Exceeds Max Allotted"
        );

        // Create digest to verify against signed coupon
        bytes32 digest = keccak256(abi.encode(allotted, _msgSender()));

        // Verify digest against signed coupon
        require(_isVerifiedCoupon(digest, coupon), "Invalid Coupon");

        vintnersMintedWhitelist += qty;
        whitelistClaimed[_msgSender()] += qty;

        // mint vintners
        _createVintners(qty, _msgSender());
    }

    /**
     * @dev Mint with Avax
     */
    function mintVintnerWithAVAX(uint256 qty) external payable whenNotPaused {
        require(mintingStarted(), "cannot mint right now");

        require(qty > 0 && qty <= 20, "Exceeds number of mints allowed");
        require(
            (vintnerPublicMinted + qty) <=
                (NUM_VINTNERS - vintnersMintedWhitelist - PROMOTIONAL_VINTNERS),
            "Exceeds number of total mints allowed"
        );

        // calculate the transaction cost
        uint256 transactionCost = VINTNER_PRICE_AVAX * qty;
        require(msg.value >= transactionCost, "not enough AVAX");

        vintnerPublicMinted += qty;

        // mint vintners
        _createVintners(qty, _msgSender());
    }

    /**
     * @dev Mint with Grape
     */
    function mintVintnerWithGrape(uint256 qty) external whenNotPaused {
        require(mintingStarted(), "cannot mint right now");

        require(qty > 0 && qty <= 20, "Exceeds number of mints allowed");
        require(
            (vintnerPublicMinted + qty) <=
                (NUM_VINTNERS - vintnersMintedWhitelist - PROMOTIONAL_VINTNERS),
            "Exceeds number of total mints allowed"
        );

        // calculate the transaction cost
        uint256 transactionCost = VINTNER_PRICE_GRAPE * qty;
        require(
            grapeAddress.balanceOf(_msgSender()) >= transactionCost,
            "not enough Grape"
        );

        grapeAddress.transferFrom(_msgSender(), address(this), transactionCost);

        vintnerPublicMinted += qty;

        // mint vintners
        _createVintners(qty, _msgSender());
    }

    /// @dev sets royalties address
    /// for royalties addon
    /// for 2981
    function setRoyaltiesAddress(address _royaltiesAddress) public onlyOwner {
        super._setRoyaltiesAddress(_royaltiesAddress);
    }

    /// @dev sets royalties fees
    function setRoyaltiesFees(uint256 _royaltiesFees) public onlyOwner {
        royaltiesFees = _royaltiesFees;
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (tokenId > 0)
            return (royaltiesAddress, (value * royaltiesFees) / 100);
        else return (royaltiesAddress, 0);
    }

    // Returns information for multiples vintners
    // function batchedVintnersOfOwner(
    //     address _owner,
    //     uint256 _offset,
    //     uint256 _maxSize
    // ) public view returns (VintnerInfo[] memory) {
    //     if (_offset >= balanceOf(_owner)) {
    //         return new VintnerInfo[](0);
    //     }

    //     uint256 outputSize = _maxSize;
    //     if (_offset + _maxSize >= balanceOf(_owner)) {
    //         outputSize = balanceOf(_owner) - _offset;
    //     }
    //     VintnerInfo[] memory vintners = new VintnerInfo[](outputSize);

    //     for (uint256 i = 0; i < outputSize; i++) {
    //         uint256 tokenId = tokenOfOwnerByIndex(_owner, _offset + i); // tokenOfOwnerByIndex comes from IERC721Enumerable

    //         vintners[i] = VintnerInfo({
    //             tokenId: tokenId,
    //             vintnerType: tokenTypes[tokenId]
    //         });
    //     }

    //     return vintners;
    // }
}

// Tool
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./VintageWine.sol";

import "./libraries/ERC2981.sol";

interface IGrape {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getOwner() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Upgrade is Ownable, Pausable, RoyaltiesAddon, ERC2981 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    struct UpgradeInfo {
        uint256 tokenId;
        uint256 level;
        uint256 _yield;
    }
    // Struct

    struct Level {
        uint256 supply;
        uint256 maxSupply;
        uint256 priceVintageWine;
        uint256 priceGrape;
        uint256 yield;
    }

    // Var

    VintageWine vintageWine;
    IGrape grape;
    // address public wineryAddress;

    string public BASE_URI;
    uint256 private royaltiesFees;

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
        VintageWine _vintageWine,
        address _grape,
        string memory _BASE_URI
    )
        ERC721(
            "Vintner Tools",
            "VINTNER-TOOLS"
        )
    {
        vintageWine = _vintageWine;
        grape = IGrape(_grape);
        BASE_URI = _BASE_URI;

        // first three upgrades
        levels[0] = Level({
            supply: 0,
            maxSupply: 2500,
            priceVintageWine: 300 * 1e18,
            priceGrape: 20 * 1e18,
            yield: 1
        });
        levels[1] = Level({
            supply: 0,
            maxSupply: 2200,
            priceVintageWine: 600 * 1e18,
            priceGrape: 50 * 1e18,
            yield: 3
        });
        levels[2] = Level({
            supply: 0,
            maxSupply: 2000,
            priceVintageWine: 1000 * 1e18,
            priceGrape: 80 * 1e18,
            yield: 5
        });
        currentLevelIndex = 2;
    }

    // Views

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

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
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    "/",
                    levelFixed.toString(),
                    ".json"
                )
            );
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        if (wineryAddress != address(0) && _operator == wineryAddress)
            return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    // ADMIN

    function addLevel(
        uint256 _maxSupply,
        uint256 _priceVintageWine,
        uint256 _priceGrape,
        uint256 _yield
    ) external onlyOwner {
        currentLevelIndex++;
        levels[currentLevelIndex] = Level({
            supply: 0,
            maxSupply: _maxSupply,
            priceVintageWine: _priceVintageWine,
            priceGrape: _priceGrape,
            yield: _yield
        });
    }

    function changeLevel(
        uint256 _index,
        uint256 _maxSupply,
        uint256 _priceVintageWine,
        uint256 _priceGrape,
        uint256 _yield
    ) external onlyOwner {
        require(_index <= currentLevelIndex, "invalid level");
        levels[_index] = Level({
            supply: 0,
            maxSupply: _maxSupply,
            priceVintageWine: _priceVintageWine,
            priceGrape: _priceGrape,
            yield: _yield
        });
    }

    function setVintageWine(VintageWine _vintageWine) external onlyOwner {
        vintageWine = _vintageWine;
    }

    function setGrape(address _grape) external onlyOwner {
        grape = IGrape(_grape);
    }

    function setWineryAddress(address _wineryAddress) external onlyOwner {
        wineryAddress = _wineryAddress;
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

        uint256 transactionCostVintageWine = levels[_level].priceVintageWine *
            _qty;
        uint256 transactionCostGrape = levels[_level].priceGrape * _qty;
        require(
            vintageWine.balanceOf(_msgSender()) >= transactionCostVintageWine,
            "not have enough VINTAGE"
        );
        require(
            grape.balanceOf(_msgSender()) >= transactionCostGrape,
            "not have enough GRAPE"
        );

        _createUpgrades(_qty, _level, _msgSender());

        vintageWine.burn(
            _msgSender(),
            (transactionCostVintageWine * (100 - LP_TAX_PERCENT)) / 100
        );
        grape.transferFrom(_msgSender(), address(this), transactionCostGrape);
        grape.burn((transactionCostGrape * (100 - LP_TAX_PERCENT)) / 100);

        vintageWine.transferForUpgradesFees(
            _msgSender(),
            (transactionCostVintageWine * LP_TAX_PERCENT) / 100
        );
    }

    /// @dev sets royalties address
    /// for royalties addon
    /// for 2981
    function setRoyaltiesAddress(address _royaltiesAddress) public onlyOwner {
        super._setRoyaltiesAddress(_royaltiesAddress);
    }

    /// @dev sets royalties fees
    function setRoyaltiesFees(uint256 _royaltiesFees) public onlyOwner {
        royaltiesFees = _royaltiesFees;
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (tokenId > 0)
            return (royaltiesAddress, (value * royaltiesFees) / 100);
        else return (royaltiesAddress, 0);
    }

    // // Returns information for multiples upgrades
    // function batchedUpgradesOfOwner(
    //     address _owner,
    //     uint256 _offset,
    //     uint256 _maxSize
    // ) public view returns (UpgradeInfo[] memory) {
    //     if (_offset >= balanceOf(_owner)) {
    //         return new UpgradeInfo[](0);
    //     }

    //     uint256 outputSize = _maxSize;
    //     if (_offset + _maxSize >= balanceOf(_owner)) {
    //         outputSize = balanceOf(_owner) - _offset;
    //     }
    //     UpgradeInfo[] memory upgrades = new UpgradeInfo[](outputSize);

    //     for (uint256 i = 0; i < outputSize; i++) {
    //         uint256 tokenId = tokenOfOwnerByIndex(_owner, _offset + i); // tokenOfOwnerByIndex comes from IERC721Enumerable

    //         upgrades[i] = UpgradeInfo({
    //             tokenId: tokenId,
    //             level: tokenLevel[tokenId],
    //             _yield: levels[tokenLevel[tokenId]].yield
    //         });
    //     }
    //     return upgrades;
    // }
}

// Pizza Token
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VintageWine is ERC20("Vintage", "VINTAGE"), Ownable {
    // uint256 public constant ONE_VINTAGEWINE = 1e18;
    // uint256 public constant NUM_PROMOTIONAL_VINTAGEWINE = 500_000;
    // uint256 public constant NUM_VINTAGEWINE_USDC_LP = 50_000_000;

    // uint256 public NUM_VINTAGEWINE_AVAX_LP = 30_000_000;

    address public cellarAddress;
    address public wineryAddress;
    // address public vintnerAddress;
    address public upgradeAddress;

    // bool public promotionalVintageWineMinted = false;
    // bool public avaxLPVintageWineMinted = false;
    // bool public USDCLPVintageWineMinted = false;

    // ADMIN

    /**
     * winery yields vintageWine
     */
    function setWineryAddress(address _wineryAddress) external onlyOwner {
        wineryAddress = _wineryAddress;
    }

    function setCellarAddress(address _cellarAddress) external onlyOwner {
        cellarAddress = _cellarAddress;
    }

    function setUpgradeAddress(address _upgradeAddress) external onlyOwner {
        upgradeAddress = _upgradeAddress;
    }

    /**
     * vintner consumes vintageWine
     * vintner address can only be set once
     */
    // function setVintnerAddress(address _vintnerAddress) external onlyOwner {
    //     require(
    //         address(vintnerAddress) == address(0),
    //         "vintner address already set"
    //     );
    //     vintnerAddress = _vintnerAddress;
    // }

    function mintVintageWine(address _to, uint256 amount)
        external
        onlyOwner
    {
        _mint(_to, amount);
    }

    // function mintPromotionalVintageWine(address _to) external onlyOwner {
    //     require(
    //         !promotionalVintageWineMinted,
    //         "promotional vintageWine has already been minted"
    //     );
    //     promotionalVintageWineMinted = true;
    //     _mint(_to, NUM_PROMOTIONAL_VINTAGEWINE * ONE_VINTAGEWINE);
    // }

    // function mintAvaxLPVintageWine() external onlyOwner {
    //     require(
    //         !avaxLPVintageWineMinted,
    //         "avax vintageWine LP has already been minted"
    //     );
    //     avaxLPVintageWineMinted = true;
    //     _mint(owner(), NUM_VINTAGEWINE_AVAX_LP * ONE_VINTAGEWINE);
    // }

    // function mintUSDCLPVintageWine() external onlyOwner {
    //     require(
    //         !USDCLPVintageWineMinted,
    //         "USDC vintageWine LP has already been minted"
    //     );
    //     USDCLPVintageWineMinted = true;
    //     _mint(owner(), NUM_VINTAGEWINE_USDC_LP * ONE_VINTAGEWINE);
    // }

    // function setNumVintageWineAvaxLp(uint256 _numVintageWineAvaxLp)
    //     external
    //     onlyOwner
    // {
    //     NUM_VINTAGEWINE_AVAX_LP = _numVintageWineAvaxLp;
    // }

    // external

    function mint(address _to, uint256 _amount) external {
        require(
            wineryAddress != address(0) &&
                // vintnerAddress != address(0) &&
                cellarAddress != address(0) &&
                upgradeAddress != address(0),
            "missing initial requirements"
        );
        require(
            _msgSender() == wineryAddress,
            "msgsender does not have permission"
        );
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(
            // vintnerAddress != address(0) &&
            cellarAddress != address(0) && upgradeAddress != address(0),
            "missing initial requirements"
        );
        require(
            // _msgSender() == vintnerAddress ||
            _msgSender() == cellarAddress || _msgSender() == upgradeAddress,
            "msgsender does not have permission"
        );
        _burn(_from, _amount);
    }

    function transferToCellar(address _from, uint256 _amount) external {
        require(cellarAddress != address(0), "missing initial requirements");
        require(
            _msgSender() == cellarAddress,
            "only the cellar contract can call transferToCellar"
        );
        _transfer(_from, cellarAddress, _amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @title IERC2981
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981 {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

interface RoyaltiesInterface {
    function claimCommunity(address collectionAddress, uint256 tokenId)
        external;
}

abstract contract RoyaltiesAddon is ERC721 {
    address public royaltiesAddress;
    address public wineryAddress;

    /**
     * @dev internal set royalties address
     * @param _royaltiesAddress address of the Royalties.sol
     */
    function _setRoyaltiesAddress(address _royaltiesAddress) internal {
        royaltiesAddress = _royaltiesAddress;
    }

    function _setWineryAddress(address _wineryAddress) internal {
        wineryAddress = _wineryAddress;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the royalties get auto claim on transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (
            from != wineryAddress &&
            to != wineryAddress &&
            royaltiesAddress != address(0) &&
            from != address(0) &&
            !Address.isContract(from)
        ) {
            RoyaltiesInterface(royaltiesAddress).claimCommunity(
                address(this),
                tokenId
            );
        }
    }
}

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981 is ERC165, IERC2981 {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
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
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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