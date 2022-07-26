// Winery
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

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

interface IWinery {
    function skillPoints(address owner) external view returns (uint256);

    function skillsLearned(address owner, uint256 index)
        external
        view
        returns (uint256);

    function grapeDeposited(address owner) external view returns (uint256);
}

contract WineryProgression is Ownable {
    // Constants
    uint256 public constant BURN_ID = 0;
    uint256 public constant FATIGUE_ID = 1;
    uint256 public constant CELLAR_ID = 2;
    uint256 public constant MASTERVINTNER_ID = 3;
    uint256 public constant UPGRADES_ID = 4;
    uint256 public constant VINTNERS_ID = 5;
    uint256 public constant STORAGE_ID = 6;
    // uint256 public constant MAFIA_ID = 7;

    uint256[30] public grapeLevels = [
        0,
        20 * 1e18,
        48 * 1e18,
        83 * 1e18,
        125 * 1e18,
        175 * 1e18,
        235 * 1e18,
        310 * 1e18,
        400 * 1e18,
        510 * 1e18,
        641 * 1e18,
        805 * 1e18,
        1001 * 1e18,
        1213 * 1e18,
        1497 * 1e18,
        1851 * 1e18,
        2276 * 1e18,
        2772 * 1e18,
        3322 * 1e18,
        3932 * 1e18,
        4694 * 1e18,
        5608 * 1e18,
        6658 * 1e18,
        7877 * 1e18,
        9401 * 1e18,
        11229 * 1e18,
        13363 * 1e18,
        15801 * 1e18,
        18545 * 1e18,
        21593 * 1e18
    ];

    uint256 public maxGrapeAmount = grapeLevels[grapeLevels.length - 1];
    uint256 public baseCostRespect = 25 * 1e18;

    uint256[4] public burnSkillValue = [0, 3, 6, 12];
    uint256[6] public fatigueSkillValue = [100, 92, 85, 80, 70, 50];
    uint256[3] public cellarSkillValue = [0, 4, 12];
    uint256[3] public masterVintnerSkillValue = [100, 103, 120];
    uint256[6] public upgradesSkillValue = [1, 2, 3, 4, 6, 100];
    uint256[6] public vintnersSkillValue = [5, 10, 15, 30, 50, 20000];
    uint256[6] public vintageWineStorageSkillValue = [
        1000 * 1e18,
        1500 * 1e18,
        3000 * 1e18,
        10000 * 1e18,
        30000 * 1e18,
        200000 * 1e18
    ];
    // uint256[4] public mafiaModSkillValue = [0,3,6,10];

    uint256[7] public MAX_SKILL_LEVEL = [
        burnSkillValue.length - 1,
        fatigueSkillValue.length - 1,
        cellarSkillValue.length - 1,
        masterVintnerSkillValue.length - 1,
        upgradesSkillValue.length - 1,
        vintnersSkillValue.length - 1,
        vintageWineStorageSkillValue.length - 1
        // mafiaModSkillValue.length - 1
    ];

    IGrape public grape;

    uint256 public levelTime;

    mapping(address => uint256) public grapeDeposited; // address => total amount of grape deposited
    mapping(address => uint256) public skillPoints; // address => skill points available
    mapping(address => uint256[7]) public skillsLearned; // address => skill learned.

    constructor(address _grape) {
        grape = IGrape(_grape);
    }

    // EVENTS

    event receivedSkillPoints(address owner, uint256 skillPoints);
    event skillLearned(address owner, uint256 skillGroup, uint256 skillLevel);
    event respec(address owner, uint256 level);

    // Setters
    function setburnSkillValue(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        burnSkillValue[_index] = _value;
    }

    function setfatigueSkillValue(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        fatigueSkillValue[_index] = _value;
    }

    function setcellarSkillValue(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        cellarSkillValue[_index] = _value;
    }

    function setmasterVintnerSkillValue(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        masterVintnerSkillValue[_index] = _value;
    }

    function setupgradesSkillValue(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        upgradesSkillValue[_index] = _value;
    }

    function setvintnersSkillValue(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        vintnersSkillValue[_index] = _value;
    }

    function setvintageWineStorageSkillValue(uint256 _index, uint256 _value)
        external
        onlyOwner
    {
        vintageWineStorageSkillValue[_index] = _value;
    }

    // function setmafiaModSkillValue(uint256 _index, uint256 _value) external onlyOwner {
    //     mafiaModSkillValue[_index] = _value;
    // }

    function setGrape(address _grape) external onlyOwner {
        grape = IGrape(_grape);
    }

    function setBaseCostRespect(uint256 _baseCostRespect) external onlyOwner {
        baseCostRespect = _baseCostRespect;
    }

    function setGrapeLevels(uint256 _index, uint256 _newValue)
        external
        onlyOwner
    {
        require(_index < grapeLevels.length, "invalid index");
        grapeLevels[_index] = _newValue;

        if (_index == (grapeLevels.length - 1)) {
            maxGrapeAmount = grapeLevels[grapeLevels.length - 1];
        }
    }

    // Views

    /**
     * Returns the level based on the total grape deposited
     */
    function _getLevel(address _owner) internal view returns (uint256) {
        uint256 totalGrape = grapeDeposited[_owner];
        uint256 maxId = grapeLevels.length - 1;

        for (uint256 i = 0; i < maxId; i++) {
            if (totalGrape < grapeLevels[i + 1]) {
                return i + 1;
            }
        }
        return grapeLevels.length;
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
        return fatigueSkillValue[fatigueSkill];
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
        return burnSkillValue[burnSkill];
    }

    /**
     * Returns a value representing the % that will be reduced from the cellar share of the claim
     */
    function getCellarSkillModifier(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 cellarSkill = skillsLearned[_owner][CELLAR_ID];
        return cellarSkillValue[cellarSkill];
    }

    /**
     * Returns the multiplier for $VINTAGEWINE production based on the number of mastervintners and the skill points spent
     */
    function getMasterVintnerSkillModifier(
        address _owner,
        uint256 _masterVintnerNumber
    ) public view returns (uint256) {
        uint256 masterVintnerSkill = skillsLearned[_owner][MASTERVINTNER_ID];

        if (masterVintnerSkill == 2 && _masterVintnerNumber >= 5) {
            return masterVintnerSkillValue[2];
        } else if (masterVintnerSkill >= 1 && _masterVintnerNumber >= 2) {
            return masterVintnerSkillValue[1];
        } else {
            return masterVintnerSkillValue[0];
        }
    }

    /**
     * Returns the max level upgrade that can be staked based on the skill points spent
     */
    function getMaxLevelUpgrade(address _owner) public view returns (uint256) {
        uint256 upgradesSkill = skillsLearned[_owner][UPGRADES_ID];
        return upgradesSkillValue[upgradesSkill];
    }

    /**
     * Returns the max number of vintners that can be staked based on the skill points spent
     */
    function getMaxNumberVintners(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 vintnersSkill = skillsLearned[_owner][VINTNERS_ID];
        return vintnersSkillValue[vintnersSkill];
    }

    /**
     * Returns the modifier for mafia mechanic
     */
    // function getMafiaModifier(address _owner) public view returns (uint256) {
    //     uint256 mafiaModSkill = skillsLearned[_owner][MAFIA_ID];
    //     return mafiaModSkillValue[mafiaModSkill];
    // }

    /**
     * Returns the max storage for vintageWine in the winery
     */
    function getVintageWineStorage(address _owner)
        public
        view
        returns (uint256)
    {
        uint256 vintageWineStorageSkill = skillsLearned[_owner][STORAGE_ID];
        return vintageWineStorageSkillValue[vintageWineStorageSkill];
    }

    // Public views

    /**
     * Returns the Winery level
     */
    function getLevel(address _owner) public view returns (uint256) {
        return _getLevel(_owner);
    }

    /**
     * Returns the $GRAPE deposited in the current level
     */
    function getGrapeDeposited(address _owner) public view returns (uint256) {
        uint256 level = _getLevel(_owner);
        uint256 totalGrape = grapeDeposited[_owner];
        if (level == grapeLevels.length) {
            return 0;
        }

        return totalGrape - grapeLevels[level - 1];
    }

    /**
     * Returns the amount of grape required to level up
     */
    function getGrapeToNextLevel(address _owner) public view returns (uint256) {
        uint256 level = _getLevel(_owner);
        if (level == grapeLevels.length) {
            return 0;
        }
        return grapeLevels[level] - grapeLevels[level - 1];
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
            uint256 cellar,
            uint256 mastervintner,
            uint256 upgrades,
            uint256 vintners,
            uint256 vintageWineStorage
        )
    // uint256 mafiaMod
    {
        uint256[7] memory skills = skillsLearned[_owner];

        burn = skills[BURN_ID];
        fatigue = skills[FATIGUE_ID];
        cellar = skills[CELLAR_ID];
        mastervintner = skills[MASTERVINTNER_ID];
        upgrades = skills[UPGRADES_ID];
        vintners = skills[VINTNERS_ID];
        vintageWineStorage = skills[STORAGE_ID];
        // mafiaMod = skills[MAFIA_ID];
    }

    // External

    /**
     * Burns deposited $GRAPE and add skill point if level up.
     */
    function depositGrape(uint256 _amount) external {
        address sender = msg.sender;
        require(levelStarted(), "You can't level yet");
        require(_getLevel(sender) < grapeLevels.length, "already at max level");
        require(grape.balanceOf(sender) >= _amount, "not enough GRAPE");

        if (_amount + grapeDeposited[sender] > maxGrapeAmount) {
            _amount = maxGrapeAmount - grapeDeposited[sender];
        }

        grape.transferFrom(sender, address(this), _amount);
        grape.burn(_amount);
        // grape.burn(sender, _amount);

        uint256 levelBefore = _getLevel(sender);
        grapeDeposited[sender] += _amount;
        uint256 levelAfter = _getLevel(sender);
        skillPoints[sender] += levelAfter - levelBefore;

        if (levelAfter == grapeLevels.length) {
            skillPoints[sender] += 1;
        }

        emit receivedSkillPoints(sender, levelAfter - levelBefore);
    }

    /**
     *  Spend skill point based on the skill group and skill level. Can only spend 1 point at a time.
     */
    function spendSkillPoints(uint256 _skillGroup, uint256 _skillLevel)
        external
    {
        address sender = msg.sender;

        require(skillPoints[sender] > 0, "Not enough skill points");
        require(
            _skillGroup <= MAX_SKILL_LEVEL.length - 1,
            "Invalid Skill Group"
        );
        require(
            _skillLevel >= 1 && _skillLevel <= MAX_SKILL_LEVEL[_skillGroup],
            "Invalid Skill Level"
        );

        uint256 currentSkillLevel = skillsLearned[sender][_skillGroup];
        require(
            _skillLevel == currentSkillLevel + 1,
            "Invalid Skill Level jump"
        ); //can only level up 1 point at a time

        skillsLearned[sender][_skillGroup] = _skillLevel;
        skillPoints[sender]--;

        emit skillLearned(sender, _skillGroup, _skillLevel);
    }

    /**
     *  Resets skills learned for a fee
     */
    function resetSkills() external {
        address sender = msg.sender;
        uint256 level = _getLevel(sender);
        uint256 costToRespec = level * baseCostRespect;
        require(level > 1, "you are still at level 1");
        require(grape.balanceOf(sender) >= costToRespec, "not enough GRAPE");

        grape.transferFrom(sender, address(this), costToRespec);
        grape.burn(costToRespec);
        // grape.burn(sender, costToRespec);

        skillsLearned[sender][BURN_ID] = 0;
        skillsLearned[sender][FATIGUE_ID] = 0;
        skillsLearned[sender][CELLAR_ID] = 0;
        skillsLearned[sender][MASTERVINTNER_ID] = 0;
        skillsLearned[sender][UPGRADES_ID] = 0;
        skillsLearned[sender][VINTNERS_ID] = 0;
        skillsLearned[sender][STORAGE_ID] = 0;
        // skillsLearned[sender][MAFIA_ID] = 0;

        skillPoints[sender] = level - 1;

        if (level == grapeLevels.length) {
            skillPoints[sender] += 1;
        }

        emit respec(sender, level);
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

    // In case we rebalance the leveling costs this fixes the skill points to correct players
    function fixSkillPoints(address _player) public {
        uint256 level = _getLevel(_player);
        uint256 currentSkillPoints = skillPoints[_player];
        // uint256 totalSkillsLearned = skillsLearned[_player][BURN_ID] + skillsLearned[_player][FATIGUE_ID] + skillsLearned[_player][CELLAR_ID] + skillsLearned[_player][MASTERVINTNER_ID] + skillsLearned[_player][UPGRADES_ID] + skillsLearned[_player][VINTNERS_ID] + skillsLearned[_player][STORAGE_ID] + skillsLearned[_player][MAFIA_ID];
        uint256 totalSkillsLearned = skillsLearned[_player][BURN_ID] +
            skillsLearned[_player][FATIGUE_ID] +
            skillsLearned[_player][CELLAR_ID] +
            skillsLearned[_player][MASTERVINTNER_ID] +
            skillsLearned[_player][UPGRADES_ID] +
            skillsLearned[_player][VINTNERS_ID] +
            skillsLearned[_player][STORAGE_ID];

        uint256 correctSkillPoints = level - 1;
        if (level == grapeLevels.length) {
            // last level has 2 skill points
            correctSkillPoints += 1;
        }
        if (correctSkillPoints > currentSkillPoints + totalSkillsLearned) {
            skillPoints[_player] +=
                correctSkillPoints -
                currentSkillPoints -
                totalSkillsLearned;
        }
    }

    // WINERY MIGRATION
    // IWinery public oldWinery;
    // mapping(address => bool) public updateOnce; // owner => has updated

    // function checkIfNeedUpdate(address _owner) public view returns (bool) {
    //     if (updateOnce[_owner]) {
    //         return false; // does not need update if already updated
    //     }

    //     uint256 oldGrapeDeposited = oldWinery.grapeDeposited(_owner);

    //     if (oldGrapeDeposited > 0) {
    //         return true; // if the player deposited any grape it means he interacted with the Winery improvements
    //     }

    //     return false;
    // }

    // function setOldWinery(address _oldWinery) external onlyOwner {
    //     oldWinery = IWinery(_oldWinery);
    // }

    // function updateDataFromOldWinery(address _owner) external {
    //     require(checkIfNeedUpdate(_owner), "Owner dont need to update");
    //     updateOnce[_owner] = true;

    //     grapeDeposited[_owner] = oldWinery.grapeDeposited(_owner);

    //     skillPoints[_owner] = oldWinery.skillPoints(_owner);

    //     uint256 burnSkillId = oldWinery.skillsLearned(_owner, 0);
    //     uint256 fatigueSkillId = oldWinery.skillsLearned(_owner, 1);
    //     uint256 cellarSkillId = oldWinery.skillsLearned(_owner, 2);
    //     uint256 mastervintnerSkillId = oldWinery.skillsLearned(_owner, 3);
    //     uint256 upgradeSkillId = oldWinery.skillsLearned(_owner, 4);
    //     uint256 vintnerSkillId = oldWinery.skillsLearned(_owner, 5);

    //     skillsLearned[_owner] = [
    //         burnSkillId,
    //         fatigueSkillId,
    //         cellarSkillId,
    //         mastervintnerSkillId,
    //         upgradeSkillId,
    //         vintnerSkillId,
    //         0
    //     ];

    //     fixSkillPoints(_owner); // Fix skill points because of rebalance
    // }
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