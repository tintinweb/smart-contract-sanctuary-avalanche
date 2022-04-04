// SPDX-License-Identifier: UNLICENSED
/*
    ██████╗  █████╗ ██████╗ ██╗  ██╗    ███████╗ ██████╗ ██████╗ ███████╗███████╗████████╗
    ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝    ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝╚══██╔══╝
    ██║  ██║███████║██████╔╝█████╔╝     █████╗  ██║   ██║██████╔╝█████╗  ███████╗   ██║   
    ██║  ██║██╔══██║██╔══██╗██╔═██╗     ██╔══╝  ██║   ██║██╔══██╗██╔══╝  ╚════██║   ██║   
    ██████╔╝██║  ██║██║  ██║██║  ██╗    ██║     ╚██████╔╝██║  ██║███████╗███████║   ██║   
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝             
*/

pragma solidity ^0.8.11;

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnerRecoveryUpgradeable.sol";
import "./UniverseImplementationPointerUpgradeable.sol";
import "./LiquidityPoolManagerImplementationPointerUpgradeable.sol";

contract PlanetsManagerUpgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    OwnerRecoveryUpgradeable,
    ReentrancyGuardUpgradeable,
    UniverseImplementationPointerUpgradeable,
    LiquidityPoolManagerImplementationPointerUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct PlanetInfoEntity {
        PlanetEntity planet;
        uint256 id;
        uint256 pendingRewards;
        uint256 rewardPerDay;
        uint256 compoundDelay;
    }

    struct PlanetEntity {
        uint256 id;
        string name;
        uint256 creationTime;
        uint256 lastProcessingTimestamp;
        uint256 rewardMult;
        uint256 planetValue;
        uint256 totalClaimed;
        bool exists;
        bool isMerged;
    }

    struct TierStorage {
        uint256 rewardMult;
        uint256 amountLockedInTier;
        bool exists;
    }

    CountersUpgradeable.Counter private _planetCounter;
    mapping(uint256 => PlanetEntity) private _planets;
    mapping(uint256 => TierStorage) private _tierTracking;
    uint256[] _tiersTracked;

    uint256 public rewardPerDay;
    uint256 public creationMinPrice;
    uint256 public compoundDelay;
    uint256 public processingFee;

    uint24[6] public tierLevel;
    uint16[6] public tierSlope;

    uint256 private constant ONE_DAY = 86400;
    uint256 private _totalValueLocked;

    uint256 public burnedFromRenaming;
    uint256 public burnedFromMerging;
    uint256 public burnedFromCompounding;
    uint256 public burnedFromNARTCompounding;
    uint256 public burnedFromClaiming;
    uint256 public burnedFromNARTClaiming;

    address[] public boostingList;

    modifier onlyPlanetOwner() {
        address sender = _msgSender();
        require(
            sender != address(0),
            "Planets: Cannot be from the zero address"
        );
        require(
            isOwnerOfPlanets(sender),
            "Planets: No Planet owned by this account"
        );
        require(
            !liquidityPoolManager.isFeeReceiver(sender),
            "Planets: Fee receivers cannot own Planets"
        );
        _;
    }

    modifier checkPermissions(uint256 _planetId) {
        address sender = _msgSender();
        require(planetExists(_planetId), "Planets: This planet doesn't exist");
        require(
            isOwnerOfPlanet(sender, _planetId),
            "Planets: You do not control this Planet"
        );
        _;
    }

    modifier checkPermissionsMultiple(uint256[] memory _planetIds) {
        address sender = _msgSender();
        for (uint256 i = 0; i < _planetIds.length; i++) {
            require(
                planetExists(_planetIds[i]),
                "Planets: This planet doesn't exist"
            );
            require(
                isOwnerOfPlanet(sender, _planetIds[i]),
                "Planets: You do not control this Planet"
            );
        }
        _;
    }

    modifier universeSet() {
        require(
            address(universe) != address(0),
            "Planets: Universe is not set"
        );
        _;
    }

    function initialize() external initializer {
        __ERC721_init("Dark Forest Ecosystem", "DFES");
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        changeNodeMinPrice(42_000 * (10**18)); // 42,000 NART
        changeProcessingFee(30); // 30%
        changeTierSystem(
            [100000, 105000, 110000, 120000, 130000, 140000],
            [1000, 500, 100, 50, 10, 0]
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function renamePlanet(uint256 _planetId, string memory planetName)
        external
        nonReentrant
        onlyPlanetOwner
        checkPermissions(_planetId)
        whenNotPaused
        universeSet
    {
        require(
            bytes(planetName).length > 1 && bytes(planetName).length < 32,
            "Planets: Incorrect name length, must be between 2 to 31"
        );
        PlanetEntity storage planet = _planets[_planetId];
        require(planet.planetValue > 0, "Error: Planet is empty");
        (uint256 newPlanetValue, uint256 feeAmount) = getProcessingFee(
            planet.planetValue,
            5
        );
        logTier(planet.rewardMult, -int256(feeAmount));
        burnedFromRenaming += feeAmount;
        planet.planetValue = newPlanetValue;
        planet.name = planetName;
    }

    function mergePlanets(uint256[] memory _planetIds, string memory planetName)
        external
        nonReentrant
        onlyPlanetOwner
        checkPermissionsMultiple(_planetIds)
        whenNotPaused
        returns (uint256)
    {
        address account = _msgSender();
        require(
            _planetIds.length > 1,
            "PlanetsManager: At least 2 Planets must be selected in order for the merge to work"
        );
        uint256 lowestTier = 0;
        uint256 lowestId = 0;
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _planetIds.length; i++) {
            PlanetEntity storage planetFromIds = _planets[_planetIds[i]];
            require(
                isProcessable(planetFromIds),
                "PlanetsManager: For the process to work, all selected planets must be compoundable. Try again later."
            );
            
            _compoundReward(planetFromIds.id);
            
            if (lowestTier == 0) {
                lowestTier = planetFromIds.rewardMult;
            } else if (lowestTier > planetFromIds.rewardMult) {
                lowestTier = planetFromIds.rewardMult;
            }
            
            if (lowestId == 0) {
                lowestId = planetFromIds.id;
            } else if (lowestId > planetFromIds.id) {
                lowestId = planetFromIds.id;
            }
            
            totalValue += planetFromIds.planetValue;
            
            _burn(planetFromIds.id);
        }
        require(
            lowestTier >= tierLevel[0],
            "PlanetsManager: Something went wrong with the tiers"
        );
        require(
            lowestId > 0,
            "PlanetsManager: Something went wrong with the lowest id"
        );
        
        (uint256 newPlanetValue, uint256 feeAmount) = getProcessingFee(
            totalValue,
            2
        );
        burnedFromMerging += feeAmount;

        universe.accountReward(account, newPlanetValue);
        
        uint256 currentPlanetId = _createPlanetWithTokens(
            planetName,
            newPlanetValue,
            lowestId
        );
        require(
            currentPlanetId == lowestId,
            "Current Planet should match the lowest number of your Planet"
        );
        
        PlanetEntity storage planet = _planets[currentPlanetId];
        planet.isMerged = true;
        if (lowestTier != tierLevel[0]) {
            logTier(planet.rewardMult, -int256(planet.planetValue));
            planet.rewardMult = lowestTier;
            logTier(planet.rewardMult, int256(planet.planetValue));
        }
        removeFromBoostingList(account);
        return currentPlanetId;
    }

    function createPlanetWithTokens(
        string memory planetName,
        uint256 planetValue
    ) external nonReentrant whenNotPaused returns (uint256) {
        // Increment the total number of tokens
        _planetCounter.increment();

        return _createPlanetWithTokens(
                planetName,
                planetValue,
                _planetCounter.current()
            );
    }

    function _createPlanetWithTokens(
        string memory planetName,
        uint256 planetValue,
        uint256 newPlanetId
    ) private universeSet returns (uint256) {
        address sender = _msgSender();

        require(
            bytes(planetName).length > 1 && bytes(planetName).length < 32,
            "Planets: Incorrect name length, must be between 2 to 31"
        );
        require(
            planetValue >= creationMinPrice,
            "Planets: Planet value set below minimum"
        );
        require(
            isNameAvailable(sender, planetName),
            "Planets: Name not available"
        );
        require(
            universe.balanceOf(sender) >= creationMinPrice,
            "Planets: Balance too low for creation"
        );

        universe.accountBurn(sender, planetValue);

        uint256 currentTime = block.timestamp;

        
        _totalValueLocked += planetValue;
        logTier(tierLevel[0], int256(planetValue));

        
        _planets[newPlanetId] = PlanetEntity({
            id: newPlanetId,
            name: planetName,
            creationTime: currentTime,
            lastProcessingTimestamp: currentTime,
            rewardMult: tierLevel[0],
            planetValue: planetValue,
            totalClaimed: 0,
            exists: true,
            isMerged: false
        });

        
        _mint(sender, newPlanetId);


        return newPlanetId;
    }

    function cashoutReward(uint256 _planetId)
        external
        nonReentrant
        onlyPlanetOwner
        checkPermissions(_planetId)
        whenNotPaused
        universeSet
    {
        uint256 reward = _getPlanetCashoutRewards(_planetId);
        _cashoutReward(reward);
    }

    function cashoutAll()
        external
        nonReentrant
        onlyPlanetOwner
        whenNotPaused
        universeSet
    {
        address account = _msgSender();
        uint256 rewardsTotal = 0;

        uint256[] memory planetsOwned = getPlanetIdsOf(account);
        for (uint256 i = 0; i < planetsOwned.length; i++) {
            rewardsTotal += _getPlanetCashoutRewards(planetsOwned[i]);
        }
        _cashoutReward(rewardsTotal);
    }

    function compoundReward(uint256 _planetId)
        external
        nonReentrant
        onlyPlanetOwner
        checkPermissions(_planetId)
        whenNotPaused
        universeSet
    {
        _compoundReward(_planetId);
    }

    function _compoundReward(uint256 _planetId)
        private
    {
        (
            uint256 amountToCompound,
            uint256 feeAmount
        ) = _getPlanetCompoundRewards(_planetId);
        require(
            amountToCompound > 0,
            "Planets: You must wait until you can compound again"
        );
        if (feeAmount > 0) {
            burnedFromNARTCompounding += feeAmount;
            // universe.liquidityReward(feeAmount);
        }
    }

    function compoundAll()
        external
        nonReentrant
        onlyPlanetOwner
        whenNotPaused
        universeSet
    {
        address account = _msgSender();
        uint256 feesAmount = 0;
        uint256 amountsToCompound = 0;
        uint256[] memory planetsOwned = getPlanetIdsOf(account);
        uint256[] memory planetsAffected = new uint256[](planetsOwned.length);

        for (uint256 i = 0; i < planetsOwned.length; i++) {
            (
                uint256 amountToCompound,
                uint256 feeAmount
            ) = _getPlanetCompoundRewards(planetsOwned[i]);
            if (amountToCompound > 0) {
                planetsAffected[i] = planetsOwned[i];
                feesAmount += feeAmount;
                amountsToCompound += amountToCompound;
            } else {
                delete planetsAffected[i];
            }
        }

        require(amountsToCompound > 0, "Planets: No rewards to compound");
        if (feesAmount > 0) {
            burnedFromNARTCompounding += feesAmount;
            // universe.liquidityReward(feesAmount);
        }
    }

    function _getPlanetCashoutRewards(uint256 _planetId)
        private
        returns (uint256)
    {
        PlanetEntity storage planet = _planets[_planetId];

        if (!isProcessable(planet)) {
            return 0;
        }

        uint256 reward = calculateReward(planet);
        planet.totalClaimed += reward;

        if (planet.rewardMult != tierLevel[0]) {
            logTier(planet.rewardMult, -int256(planet.planetValue));
            logTier(tierLevel[0], int256(planet.planetValue));
        }

        planet.rewardMult = tierLevel[0];
        planet.lastProcessingTimestamp = block.timestamp;
        return reward;
    }

    function _getPlanetCompoundRewards(uint256 _planetId)
        private
        returns (uint256, uint256)
    {
        PlanetEntity storage planet = _planets[_planetId];

        if (!isProcessable(planet)) {
            return (0, 0);
        }

        uint256 reward = calculateReward(planet);
        if (reward > 0) {
            (uint256 amountToCompound, uint256 feeAmount) = getProcessingFee(
                reward,
                26
            );
            _totalValueLocked += amountToCompound;

            logTier(planet.rewardMult, -int256(planet.planetValue));

            planet.lastProcessingTimestamp = block.timestamp;
            planet.planetValue += amountToCompound;
            (uint256 multInc, bool isOver3) = increaseMultiplier(planet.rewardMult);
            planet.rewardMult += multInc;
            logTier(planet.rewardMult, int256(planet.planetValue));

            if (isOver3) addToBoostingList(msg.sender);

            return (amountToCompound, feeAmount);
        }

        return (0, 0);
    }

    function addToBoostingList(address account) private {
        for (uint256 i = 0; i < boostingList.length; i++)
            if (boostingList[i] == account) return;
        boostingList[boostingList.length] = account;
    }

    function removeFromBoostingList(address account) private {
        for (uint256  i = 0; i < boostingList.length; i++) {
            if (boostingList[i] == account) {
                boostingList[i] = boostingList[boostingList.length - 1];
                boostingList.pop();
                return;
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override{
        super._transfer(from, to, tokenId);
        removeFromBoostingList(from);
    }

    function _cashoutReward(uint256 amount) private {
        require(
            amount > 0,
            "Planets: You don't have enough reward to cash out"
        );
        address to = _msgSender();
        (uint256 amountToReward, uint256 feeAmount) = getProcessingFee(
            amount,
            30
        );
        universe.accountReward(to, amountToReward);
        uint256 burnAmount = feeAmount * 25 / 30;
        uint256 LPAmount = feeAmount - burnAmount;
        burnedFromNARTClaiming += burnAmount;
        universe.liquidityReward(LPAmount);
    }

    function logTier(uint256 mult, int256 amount) private {
        TierStorage storage tierStorage = _tierTracking[mult];
        if (tierStorage.exists) {
            require(
                tierStorage.rewardMult == mult,
                "Planets: rewardMult does not match in TierStorage"
            );
            uint256 amountLockedInTier = uint256(
                int256(tierStorage.amountLockedInTier) + amount
            );
            require(
                amountLockedInTier >= 0,
                "Planets: amountLockedInTier cannot underflow"
            );
            tierStorage.amountLockedInTier = amountLockedInTier;
        } else {
            
            require(
                amount > 0,
                "Planets: Fatal error while creating new TierStorage. Amount cannot be below zero."
            );
            _tierTracking[mult] = TierStorage({
                rewardMult: mult,
                amountLockedInTier: uint256(amount),
                exists: true
            });
            _tiersTracked.push(mult);
        }
    }

    function getProcessingFee(uint256 rewardAmount, uint256 _feeAmount)
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

    function increaseMultiplier(uint256 prevMult)
        private
        view
        returns (uint256, bool)
    {
        if (prevMult >= tierLevel[5]) {
            return (tierSlope[5], true);
        } else if (prevMult >= tierLevel[4]) {
            return (tierSlope[4], true);
        } else if (prevMult >= tierLevel[3]) {
            return (tierSlope[3], true);
        } else if (prevMult >= tierLevel[2]) {
            return (tierSlope[2], false);
        } else if (prevMult >= tierLevel[1]) {
            return (tierSlope[1], false);
        } else {
            return (tierSlope[0], false);
        }
    }

    function isProcessable(PlanetEntity memory planet)
        private
        view
        returns (bool)
    {
        return
            block.timestamp >= planet.lastProcessingTimestamp + compoundDelay;
    }

    function calculateReward(PlanetEntity memory planet)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                planet.planetValue,
                planet.rewardMult,
                block.timestamp - planet.lastProcessingTimestamp,
                rewardPerDay
            );
    }

    function rewardPerDayFor(PlanetEntity memory planet)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                planet.planetValue,
                planet.rewardMult,
                ONE_DAY,
                rewardPerDay
            );
    }

    function _calculateRewardsFromValue(
        uint256 _planetValue,
        uint256 _rewardMult,
        uint256 _timeRewards,
        uint256 _rewardPerDay
    ) private pure returns (uint256) {
        uint256 rewards = (_timeRewards * _rewardPerDay) / 1000000;
        uint256 rewardsMultiplicated = (rewards * _rewardMult) / 100000;
        return (rewardsMultiplicated * _planetValue) / 100000;
    }

    function planetExists(uint256 _planetId) private view returns (bool) {
        require(_planetId > 0, "Planets: Id must be higher than zero");
        PlanetEntity memory planet = _planets[_planetId];
        if (planet.exists) {
            return true;
        }
        return false;
    }

    function calculateTotalDailyEmission() external view returns (uint256) {
        uint256 dailyEmission = 0;
        for (uint256 i = 0; i < _tiersTracked.length; i++) {
            TierStorage memory tierStorage = _tierTracking[_tiersTracked[i]];
            dailyEmission += _calculateRewardsFromValue(
                tierStorage.amountLockedInTier,
                tierStorage.rewardMult,
                ONE_DAY,
                rewardPerDay
            );
        }
        return dailyEmission;
    }

    function totalValueLocked() external view returns (uint256) {
        return _totalValueLocked - 42000000000000000000000000000;
    }

    function isNameAvailable(address account, string memory planetName)
        public
        view
        returns (bool)
    {
        uint256[] memory planetsOwned = getPlanetIdsOf(account);
        for (uint256 i = 0; i < planetsOwned.length; i++) {
            PlanetEntity memory planet = _planets[planetsOwned[i]];
            if (keccak256(bytes(planet.name)) == keccak256(bytes(planetName))) {
                return false;
            }
        }
        return true;
    }

    function isOwnerOfPlanets(address account) public view returns (bool) {
        return balanceOf(account) > 0;
    }

    function isOwnerOfPlanet(address account, uint256 _planetId)
        public
        view
        returns (bool)
    {
        uint256[] memory planetIdsOf = getPlanetIdsOf(account);
        for (uint256 i = 0; i < planetIdsOf.length; i++) {
            if (planetIdsOf[i] == _planetId) {
                return true;
            }
        }
        return false;
    }

    function getPlanetIdsOf(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256 numberOfPlanets = balanceOf(account);
        uint256[] memory planetIds = new uint256[](numberOfPlanets);
        for (uint256 i = 0; i < numberOfPlanets; i++) {
            uint256 planetId = tokenOfOwnerByIndex(account, i);
            require(
                planetExists(planetId),
                "Planets: This planet doesn't exist"
            );
            planetIds[i] = planetId;
        }
        return planetIds;
    }

    function getPlanetsByIds(uint256[] memory _planetIds)
        external
        view
        returns (PlanetInfoEntity[] memory)
    {
        PlanetInfoEntity[] memory planetsInfo = new PlanetInfoEntity[](
            _planetIds.length
        );
        for (uint256 i = 0; i < _planetIds.length; i++) {
            uint256 planetId = _planetIds[i];
            PlanetEntity memory planet = _planets[planetId];
            planetsInfo[i] = PlanetInfoEntity(
                planet,
                planetId,
                calculateReward(planet),
                rewardPerDayFor(planet),
                compoundDelay
            );
        }
        return planetsInfo;
    }

    function changeNodeMinPrice(uint256 _creationMinPrice) public onlyOwner {
        require(
            _creationMinPrice > 0,
            "Planets: Minimum price to create a Planet must be above 0"
        );
        creationMinPrice = _creationMinPrice;
    }

    function changeRewardPerDay() public onlyOwner {
        
        rewardPerDay = 34724;
    }

    function changeTierSystem(
        uint24[6] memory _tierLevel,
        uint16[6] memory _tierSlope
    ) public onlyOwner {
        require(
            _tierLevel.length == 6,
            "Planets: newTierLevels length has to be 6"
        );
        require(
            _tierSlope.length == 6,
            "Planets: newTierSlopes length has to be 6"
        );
        tierLevel = _tierLevel;
        tierSlope = _tierSlope;
    }

    function changeProcessingFee(uint8 _processingFee) public onlyOwner {
        require(_processingFee <= 30, "Cashout fee can never exceed 30%");
        processingFee = _processingFee;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function burn(uint256 _planetId)
        external
        virtual
        nonReentrant
        onlyPlanetOwner
        whenNotPaused
        checkPermissions(_planetId)
    {
        _burn(_planetId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    {
        PlanetEntity storage planet = _planets[tokenId];
        planet.exists = false;
        logTier(planet.rewardMult, -int256(planet.planetValue));
        ERC721Upgradeable._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}