// SPDX-License-Identifier: UNLICENSED
/*
/*
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@&(,///....,***(*(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@///*,///((((((((((/,((*,.**##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@&(/((*(*,///(((((////*,.   ,/**////(//*(/#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@##%%%%%%%%#/(%%%#(/* ,/(#((((((((((((////////**%&@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@&**%%&&&&&&%%%#,,///*,**,//######(((((((//(/***,.... (@@@@@@@@@@@@@@@@@@@@@
/* @@@@@%(*.//#@@@@@@&&%%(**(/,/(/,/,*(####(/*,,*****(((###***. *%/*%@@@@@@@@@@@@@@
/* @@@@@%*      /%%(%&&@&%#(*,#%%%%%%((/.     ,***(#%&@@@@&%#(((*, .#@@@@@@@@@@@@@@
/* @@@@@@@       ,%%.#%#(#%&&&%(*#%%%&&(##*   ,****(#%&&&&&&%#(///*,..,*%@@@@@@@@@@
/* @@@@@@@..      (%%*(%#/%%%&&&@&#/#%%/.,##.  .******(####/,...    .///**,&@@@@@@@
/* @@@@@@@#**,*.  /###,(#/#%%%%%%%&%##/./((%#.   .....     ,*.  ,*(((///**.  #@@@@@
/* @@@@@@@@@&/.   ,##((%%%//#%%%%%%%%%&%%%##%(.     ,//////#%&@@@&#((//****./,&@@@@
/* @@@@@@@@@@@@@@@@@@@@@&%/*#####%%%%%##%%##&&(/##############((((////******...,@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@&((######(/,   .,#&&%*  .*((((((((/////*////*,,,,**,(@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#(((/,..    ,///##(,. ,/((((((/**,.,*****,   #@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#    .   /###((*,,,*/////////***,.,      &@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,. ,   (((((((/*......*,...,..,///%@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%    .,**////.      ,/*,/&&&@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/*
/*    Web:     https://rides.finance
 */

pragma solidity ^0.8.11;

// Optimizations:
// - Cleaner code, uses modifiers instead of repetitive code
// - Properly isolated contracts
// - Uses external instead of public (less gas)
// - Add liquidity once instead of dumping coins constantly (less gas)
// - Accept any amount for node, not just round numbers
// - Safer, using reetrancy protection and more logical-thinking code

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnerRecoveryUpgradeable.sol";
import "./RideImplementationPointerUpgradeable.sol";
import "./LiquidityPoolManagerImplementationPointerUpgradeable.sol";

contract GaragesManagerUpgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    OwnerRecoveryUpgradeable,
    ReentrancyGuardUpgradeable,
    RideImplementationPointerUpgradeable,
    LiquidityPoolManagerImplementationPointerUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct GarageInfoEntity {
        GarageEntity garage;
        uint256 id;
        uint256 pendingRewards;
        uint256 rewardPerDay;
        uint256 compoundDelay;
    }

    struct GarageEntity {
        uint256 id;
        string name;
        uint256 creationTime;
        uint256 lastProcessingTimestamp;
        uint256 rewardMult;
        uint256 garageValue;
        uint256 totalClaimed;
        bool exists;
    }

    struct TierStorage {
        uint256 rewardMult;
        uint256 amountLockedInTier;
        bool exists;
    }

    CountersUpgradeable.Counter private _garageCounter;
    mapping(uint256 => GarageEntity) private _garages;
    mapping(uint256 => TierStorage) private _tierTracking;
    uint256[] _tiersTracked;

    uint256 public rewardPerDay;
    uint256 public creationMinPrice;
    uint256 public compoundDelay;
    uint256 public processingFee;

    uint24[6] public tierLevel;
    uint16[6] public tierSlope;

    uint256 private constant ONE_DAY = 86400;
    uint256 public totalValueLocked;

    modifier onlyGarageOwner() {
        address sender = _msgSender();
        require(
            sender != address(0),
            "Garages: Cannot be from the zero address"
        );
        require(
            isOwnerOfGarages(sender),
            "Garages: No Garage owned by this account"
        );
        require(
            !liquidityPoolManager.isFeeReceiver(sender),
            "Garages: Fee receivers cannot own Garages"
        );
        _;
    }

    modifier checkPermissions(uint256 _garageId) {
        address sender = _msgSender();
        require(garageExists(_garageId), "Garages: This garage doesn't exist");
        require(
            isOwnerOfGarage(sender, _garageId),
            "Garages: You do not control this Garage"
        );
        _;
    }

    modifier rideSet() {
        require(
            address(ride) != address(0),
            "Garages: Ride is not set"
        );
        _;
    }

    event Compound(
        address indexed account,
        uint256 indexed garageId,
        uint256 amountToCompound
    );
    event Cashout(
        address indexed account,
        uint256 indexed garageId,
        uint256 rewardAmount
    );

    event CompoundAll(
        address indexed account,
        uint256[] indexed affectedGarages,
        uint256 amountToCompound
    );
    event CashoutAll(
        address indexed account,
        uint256[] indexed affectedGarages,
        uint256 rewardAmount
    );

    event Create(
        address indexed account,
        uint256 indexed newGarageId,
        uint256 amount
    );

    function initialize() external initializer {
        __ERC721_init("Ride Ecosystem", "GARAGE");
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        // Initialize contract
        changeRewardPerDay(46299); // 4% per day
        changeNodeMinPrice(42_000 * (10**18)); // 42,000 RIDES
        changeCompoundDelay(14400); // 4h
        changeProcessingFee(28); // 28%
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
        // return Strings.strConcat(
        //     _baseTokenURI(),
        //     Strings.uint2str(tokenId)
        // );

        // ToDo: fix this
        // To fix: https://andyhartnett.medium.com/solidity-tutorial-how-to-store-nft-metadata-and-svgs-on-the-blockchain-6df44314406b
        // Base64 support for names coming: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2884/files
        //string memory tokenURI = "test";
        //_setTokenURI(newGarageId, tokenURI);

        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function createGarageWithTokens(
        string memory garageName,
        uint256 garageValue
    ) external nonReentrant whenNotPaused rideSet returns (uint256) {
        address sender = _msgSender();

        require(
            bytes(garageName).length > 3 && bytes(garageName).length < 32,
            "Garages: Name size invalid"
        );
        require(
            garageValue >= creationMinPrice,
            "Garages: Garage value set below creationMinPrice"
        );
        require(
            isNameAvailable(sender, garageName),
            "Garages: Name not available"
        );
        require(
            ride.balanceOf(sender) >= creationMinPrice,
            "Garages: Balance too low for creation"
        );

        // Burn the tokens used to mint the NFT
        ride.accountBurn(sender, garageValue);

        // Send processing fee to liquidity
        (, uint256 feeAmount) = getProcessingFee(garageValue);
        ride.liquidityReward(feeAmount);

        // Increment the total number of tokens
        _garageCounter.increment();

        uint256 newGarageId = _garageCounter.current();
        uint256 currentTime = block.timestamp;

        // Add this to the TVL
        totalValueLocked += garageValue;
        logTier(tierLevel[0], int256(garageValue));

        // Add Garage
        _garages[newGarageId] = GarageEntity({
            id: newGarageId,
            name: garageName,
            creationTime: currentTime,
            lastProcessingTimestamp: currentTime,
            rewardMult: tierLevel[0],
            garageValue: garageValue,
            totalClaimed: 0,
            exists: true
        });

        // Assign the Garage to this account
        _mint(sender, newGarageId);

        emit Create(sender, newGarageId, garageValue);

        return newGarageId;
    }

    function cashoutReward(uint256 _garageId)
        external
        nonReentrant
        onlyGarageOwner
        checkPermissions(_garageId)
        whenNotPaused
        rideSet
    {
        address account = _msgSender();
        uint256 reward = _getGarageCashoutRewards(_garageId);
        _cashoutReward(reward);

        emit Cashout(account, _garageId, reward);
    }

    function cashoutAll()
        external
        nonReentrant
        onlyGarageOwner
        whenNotPaused
        rideSet
    {
        address account = _msgSender();
        uint256 rewardsTotal = 0;

        uint256[] memory garagesOwned = getGarageIdsOf(account);
        for (uint256 i = 0; i < garagesOwned.length; i++) {
            rewardsTotal += _getGarageCashoutRewards(garagesOwned[i]);
        }
        _cashoutReward(rewardsTotal);

        emit CashoutAll(account, garagesOwned, rewardsTotal);
    }

    function compoundReward(uint256 _garageId)
        external
        nonReentrant
        onlyGarageOwner
        checkPermissions(_garageId)
        whenNotPaused
        rideSet
    {
        address account = _msgSender();

        (
            uint256 amountToCompound,
            uint256 feeAmount
        ) = _getGarageCompoundRewards(_garageId);
        require(
            amountToCompound > 0,
            "Garages: You must wait until you can compound again"
        );
        if (feeAmount > 0) {
            ride.liquidityReward(feeAmount);
        }

        emit Compound(account, _garageId, amountToCompound);
    }

    function compoundAll()
        external
        nonReentrant
        onlyGarageOwner
        whenNotPaused
        rideSet
    {
        address account = _msgSender();
        uint256 feesAmount = 0;
        uint256 amountsToCompound = 0;
        uint256[] memory garagesOwned = getGarageIdsOf(account);
        uint256[] memory garagesAffected = new uint256[](garagesOwned.length);

        for (uint256 i = 0; i < garagesOwned.length; i++) {
            (
                uint256 amountToCompound,
                uint256 feeAmount
            ) = _getGarageCompoundRewards(garagesOwned[i]);
            if (amountToCompound > 0) {
                garagesAffected[i] = garagesOwned[i];
                feesAmount += feeAmount;
                amountsToCompound += amountToCompound;
            } else {
                delete garagesAffected[i];
            }
        }

        require(amountsToCompound > 0, "Garages: No rewards to compound");
        if (feesAmount > 0) {
            ride.liquidityReward(feesAmount);
        }

        emit CompoundAll(account, garagesAffected, amountsToCompound);
    }

    // Private reward functions

    function _getGarageCashoutRewards(uint256 _garageId)
        private
        returns (uint256)
    {
        GarageEntity storage garage = _garages[_garageId];
        uint256 reward = calculateReward(garage);
        garage.totalClaimed += reward;

        if (garage.rewardMult != tierLevel[0]) {
            logTier(garage.rewardMult, -int256(garage.garageValue));
            logTier(tierLevel[0], int256(garage.garageValue));
        }

        garage.rewardMult = tierLevel[0];
        garage.lastProcessingTimestamp = block.timestamp;
        return reward;
    }

    function _getGarageCompoundRewards(uint256 _garageId)
        private
        returns (uint256, uint256)
    {
        GarageEntity storage garage = _garages[_garageId];

        if (!isCompoundable(garage)) {
            return (0, 0);
        }

        uint256 reward = calculateReward(garage);
        if (reward > 0) {
            (uint256 amountToCompound, uint256 feeAmount) = getProcessingFee(
                reward
            );
            totalValueLocked += amountToCompound;

            logTier(garage.rewardMult, -int256(garage.garageValue));

            garage.lastProcessingTimestamp = block.timestamp;
            garage.garageValue += amountToCompound;
            garage.rewardMult += increaseMultiplier(garage.rewardMult);

            logTier(garage.rewardMult, int256(garage.garageValue));

            return (amountToCompound, feeAmount);
        }

        return (0, 0);
    }

    function _cashoutReward(uint256 amount) private {
        require(
            amount > 0,
            "Garages: You don't have enough reward to cash out"
        );
        address to = _msgSender();
        (uint256 amountToReward, uint256 feeAmount) = getProcessingFee(amount);
        ride.accountReward(to, amountToReward);
        // Send the fee to the contract where liquidity will be added later on
        ride.liquidityReward(feeAmount);
    }

    function logTier(uint256 mult, int256 amount) private {
        TierStorage storage tierStorage = _tierTracking[mult];
        if (tierStorage.exists) {
            require(
                tierStorage.rewardMult == mult,
                "Garages: rewardMult does not match in TierStorage"
            );
            uint256 amountLockedInTier = uint256(
                int256(tierStorage.amountLockedInTier) + amount
            );
            require(
                amountLockedInTier >= 0,
                "Garages: amountLockedInTier cannot underflow"
            );
            tierStorage.amountLockedInTier = amountLockedInTier;
        } else {
            // Tier isn't registered exist, register it
            require(
                amount > 0,
                "Garages: Fatal error while creating new TierStorage. Amount cannot be below zero."
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

    function getProcessingFee(uint256 rewardAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 feeAmount = 0;
        if (processingFee > 0) {
            feeAmount = (rewardAmount * processingFee) / 100;
        }
        return (rewardAmount - feeAmount, feeAmount);
    }

    function increaseMultiplier(uint256 prevMult)
        private
        view
        returns (uint256)
    {
        if (prevMult >= tierLevel[5]) {
            return tierSlope[5];
        } else if (prevMult >= tierLevel[4]) {
            return tierSlope[4];
        } else if (prevMult >= tierLevel[3]) {
            return tierSlope[2];
        } else if (prevMult >= tierLevel[2]) {
            return tierSlope[2];
        } else if (prevMult >= tierLevel[1]) {
            return tierSlope[1];
        } else {
            return tierSlope[0];
        }
    }

    function isCompoundable(GarageEntity memory garage)
        private
        view
        returns (bool)
    {
        return
            block.timestamp >= garage.lastProcessingTimestamp + compoundDelay;
    }

    function calculateReward(GarageEntity memory garage)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                garage.garageValue,
                garage.rewardMult,
                block.timestamp - garage.lastProcessingTimestamp,
                rewardPerDay
            );
    }

    function rewardPerDayFor(GarageEntity memory garage)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                garage.garageValue,
                garage.rewardMult,
                ONE_DAY,
                rewardPerDay
            );
    }

    function _calculateRewardsFromValue(
        uint256 _garageValue,
        uint256 _rewardMult,
        uint256 _timeRewards,
        uint256 _rewardPerDay
    ) private pure returns (uint256) {
        uint256 rewards = (_timeRewards * _rewardPerDay) / 1000000;
        uint256 rewardsMultiplicated = (rewards * _rewardMult) / 100000;
        return (rewardsMultiplicated * _garageValue) / 100000;
    }

    function garageExists(uint256 _garageId) private view returns (bool) {
        require(_garageId > 0, "Garages: Id must be higher than zero");
        GarageEntity memory garage = _garages[_garageId];
        if (garage.exists) {
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
                ONE_DAY,
                rewardPerDay
            );
        }
        return dailyEmission;
    }

    function isNameAvailable(address account, string memory garageName)
        public
        view
        returns (bool)
    {
        uint256[] memory garagesOwned = getGarageIdsOf(account);
        for (uint256 i = 0; i < garagesOwned.length; i++) {
            GarageEntity memory garage = _garages[garagesOwned[i]];
            if (keccak256(bytes(garage.name)) == keccak256(bytes(garageName))) {
                return false;
            }
        }
        return true;
    }

    function isOwnerOfGarages(address account) public view returns (bool) {
        return balanceOf(account) > 0;
    }

    function isOwnerOfGarage(address account, uint256 _garageId)
        public
        view
        returns (bool)
    {
        uint256[] memory garageIdsOf = getGarageIdsOf(account);
        for (uint256 i = 0; i < garageIdsOf.length; i++) {
            if (garageIdsOf[i] == _garageId) {
                return true;
            }
        }
        return false;
    }

    function getGarageIdsOf(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256 numberOfGarages = balanceOf(account);
        uint256[] memory garageIds = new uint256[](numberOfGarages);
        for (uint256 i = 0; i < numberOfGarages; i++) {
            uint256 garageId = tokenOfOwnerByIndex(account, i);
            require(
                garageExists(garageId),
                "Garages: This garage doesn't exist"
            );
            garageIds[i] = garageId;
        }
        return garageIds;
    }

    function getGaragesByIds(uint256[] memory _garageIds)
        external
        view
        returns (GarageInfoEntity[] memory)
    {
        GarageInfoEntity[] memory garagesInfo = new GarageInfoEntity[](
            _garageIds.length
        );
        for (uint256 i = 0; i < _garageIds.length; i++) {
            uint256 garageId = _garageIds[i];
            GarageEntity memory garage = _garages[garageId];
            garagesInfo[i] = GarageInfoEntity(
                garage,
                garageId,
                calculateReward(garage),
                rewardPerDayFor(garage),
                compoundDelay
            );
        }
        return garagesInfo;
    }

    // Owner functions

    function changeNodeMinPrice(uint256 _creationMinPrice) public onlyOwner {
        require(
            _creationMinPrice > 0,
            "Garages: Minimum price to create a Garage must be above 0"
        );
        creationMinPrice = _creationMinPrice;
    }

    function changeCompoundDelay(uint256 _compoundDelay) public onlyOwner {
        require(
            _compoundDelay > 0,
            "Garages: compoundDelay must be greater than 0"
        );
        compoundDelay = _compoundDelay;
    }

    function changeRewardPerDay(uint256 _rewardPerDay) public onlyOwner {
        require(
            _rewardPerDay > 0,
            "Garages: rewardPerDay must be greater than 0"
        );
        rewardPerDay = _rewardPerDay;
    }

    function changeTierSystem(
        uint24[6] memory _tierLevel,
        uint16[6] memory _tierSlope
    ) public onlyOwner {
        require(
            _tierLevel.length == 6,
            "Garages: newTierLevels length has to be 6"
        );
        require(
            _tierSlope.length == 6,
            "Garages: newTierSlopes length has to be 6"
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

    // Mandatory overrides

    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    {
        ERC721Upgradeable._burn(tokenId);
        ERC721URIStorageUpgradeable._burn(tokenId);
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