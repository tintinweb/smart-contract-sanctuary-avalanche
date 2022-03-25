//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Soda.sol";

interface IPizzeriaV3 {
    function skillPoints(address owner) external view returns (uint256);
    function skillsLearned(address owner, uint256 index) external view returns (uint256);
    function sodaDeposited(address owner) external view returns (uint256);
}

contract PizzeriaProgressionV4 is Ownable {

    // Constants
    uint256 public constant BURN_ID = 0;
    uint256 public constant FATIGUE_ID = 1;
    uint256 public constant FREEZER_ID = 2;
    uint256 public constant MASTERCHEF_ID = 3;
    uint256 public constant UPGRADES_ID = 4;
    uint256 public constant CHEFS_ID = 5;
    uint256 public constant STORAGE_ID = 6;
    uint256 public constant MAFIA_ID = 7;

    uint256[30] public sodaLevels = [0, 20 * 1e18, 48 * 1e18, 83 * 1e18, 125 * 1e18, 175 * 1e18, 235 * 1e18, 310 * 1e18, 400 * 1e18, 
        510 * 1e18, 641 * 1e18, 805 * 1e18, 1001 * 1e18, 1213 * 1e18, 1497 * 1e18, 1851 * 1e18, 2276 * 1e18, 2772 * 1e18, 3322 * 1e18, 3932 * 1e18,
        4694 * 1e18, 5608 * 1e18, 6658 * 1e18, 7877 * 1e18, 9401 * 1e18, 11229 * 1e18, 13363 * 1e18, 15801 * 1e18, 18545 * 1e18, 21593 * 1e18];

    uint256 public maxSodaAmount = sodaLevels[sodaLevels.length - 1];
    uint256 public baseCostRespect = 25 * 1e18;

    uint256[4] public burnSkillValue = [0,3,6,8];
    uint256[6] public fatigueSkillValue = [100,92,85,80,70,50];
    uint256[3] public freezerSkillValue = [0,4,9];
    uint256[3] public masterChefSkillValue = [100,103,110];
    uint256[6] public upgradesSkillValue = [1,4,6,8,11,100];
    uint256[6] public chefsSkillValue = [10,15,20,30,50,20000];
    uint256[6] public pizzaStorageSkillValue = [6000 * 1e18, 15000 * 1e18, 50000 * 1e18, 100000 * 1e18, 300000 * 1e18, 500000 * 1e18];
    uint256[4] public mafiaModSkillValue = [0,3,6,10];

    uint256[8] public MAX_SKILL_LEVEL = [
        burnSkillValue.length - 1,
        fatigueSkillValue.length - 1,
        freezerSkillValue.length - 1,
        masterChefSkillValue.length - 1,
        upgradesSkillValue.length - 1,
        chefsSkillValue.length - 1,
        pizzaStorageSkillValue.length - 1,
        mafiaModSkillValue.length - 1
    ];

    Soda public soda;

    uint256 public levelTime;

    mapping(address => uint256) public sodaDeposited; // address => total amount of soda deposited
    mapping(address => uint256) public skillPoints; // address => skill points available
    mapping(address => uint256[8]) public skillsLearned; // address => skill learned.

    constructor(Soda _soda) {
        soda = _soda;
    }

    // EVENTS

    event receivedSkillPoints(address owner, uint256 skillPoints);
    event skillLearned(address owner, uint256 skillGroup, uint256 skillLevel);
    event respec(address owner, uint256 level);

    // Setters
    function setburnSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        burnSkillValue[_index] = _value;
    }
    function setfatigueSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        fatigueSkillValue[_index] = _value;
    }
    function setfreezerSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        freezerSkillValue[_index] = _value;
    }
    function setmasterChefSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        masterChefSkillValue[_index] = _value;
    }
    function setupgradesSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        upgradesSkillValue[_index] = _value;
    }
    function setchefsSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        chefsSkillValue[_index] = _value;
    }
    function setpizzaStorageSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        pizzaStorageSkillValue[_index] = _value;
    }
    function setmafiaModSkillValue(uint256 _index, uint256 _value) external onlyOwner {
        mafiaModSkillValue[_index] = _value;
    }
    
    function setSoda(Soda _soda) external onlyOwner {
        soda = _soda;
    }

    function setBaseCostRespect(uint256 _baseCostRespect) external onlyOwner {
        baseCostRespect = _baseCostRespect;
    }

    function setSodaLevels(uint256 _index, uint256 _newValue) external onlyOwner {
        require (_index < sodaLevels.length, "invalid index");
        sodaLevels[_index] = _newValue;

        if(_index == (sodaLevels.length - 1)){
            maxSodaAmount = sodaLevels[sodaLevels.length - 1];
        }
    }

    // Views

    /**
    * Returns the level based on the total soda deposited
    */
    function _getLevel(address _owner) internal view returns (uint256) {
        uint256 totalSoda = sodaDeposited[_owner];
        uint256 maxId = sodaLevels.length - 1;

        for (uint256 i = 0; i < maxId; i++) {
            if (totalSoda < sodaLevels[i+1]) {
                    return i+1;
            }
        }
        return sodaLevels.length;
    }

    /**
    * Returns a value representing the % of fatigue after reducing
    */
    function getFatigueSkillModifier(address _owner) public view returns (uint256) {
        uint256 fatigueSkill = skillsLearned[_owner][FATIGUE_ID];
        return fatigueSkillValue[fatigueSkill];
    }

    /**
    * Returns a value representing the % that will be reduced from the claim burn
    */
    function getBurnSkillModifier(address _owner) public view returns (uint256) {
        uint256 burnSkill = skillsLearned[_owner][BURN_ID];
        return burnSkillValue[burnSkill];
    }

    /**
    * Returns a value representing the % that will be reduced from the freezer share of the claim
    */
    function getFreezerSkillModifier(address _owner) public view returns (uint256) {
        uint256 freezerSkill = skillsLearned[_owner][FREEZER_ID];
        return freezerSkillValue[freezerSkill];
    }

    /**
    * Returns the multiplier for $PIZZA production based on the number of masterchefs and the skill points spent
    */
    function getMasterChefSkillModifier(address _owner, uint256 _masterChefNumber) public view returns (uint256) {
        uint256 masterChefSkill = skillsLearned[_owner][MASTERCHEF_ID];

        if(masterChefSkill == 2 && _masterChefNumber >= 5){
            return masterChefSkillValue[2];
        } else if (masterChefSkill >= 1 && _masterChefNumber >= 2){
            return masterChefSkillValue[1];
        } else {
            return masterChefSkillValue[0];
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
    * Returns the max number of chefs that can be staked based on the skill points spent
    */
    function getMaxNumberChefs(address _owner) public view returns (uint256) {
        uint256 chefsSkill = skillsLearned[_owner][CHEFS_ID];
        return chefsSkillValue[chefsSkill];
    }

    /**
    * Returns the modifier for mafia mechanic
    */
    function getMafiaModifier(address _owner) public view returns (uint256) {
        uint256 mafiaModSkill = skillsLearned[_owner][MAFIA_ID];
        return mafiaModSkillValue[mafiaModSkill];
    }

    /**
    * Returns the max storage for pizza in the pizzeria
    */
    function getPizzaStorage(address _owner) public view returns (uint256) {
        uint256 pizzaStorageSkill = skillsLearned[_owner][STORAGE_ID];
        return pizzaStorageSkillValue[pizzaStorageSkill];
    }

    // Public views

    /**
    * Returns the Pizzeria level
    */
    function getLevel(address _owner) public view returns (uint256) {
        return _getLevel(_owner);
    }

    /**
    * Returns the $SODA deposited in the current level
    */
    function getSodaDeposited(address _owner) public view returns (uint256) {
        uint256 level = _getLevel(_owner);
        uint256 totalSoda = sodaDeposited[_owner];
        if(level == sodaLevels.length){
            return 0;
        }

        return totalSoda - sodaLevels[level-1];
    }

    /**
    * Returns the amount of soda required to level up
    */
    function getSodaToNextLevel(address _owner) public view returns (uint256) {
        uint256 level = _getLevel(_owner);
        if(level == sodaLevels.length){
            return 0;
        }
        return sodaLevels[level] - sodaLevels[level-1];
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
    function getSkillsLearned(address _owner) public view returns (
        uint256 burn,
        uint256 fatigue,
        uint256 freezer,
        uint256 masterchef,
        uint256 upgrades,
        uint256 chefs,     
        uint256 pizzaStorage,     
        uint256 mafiaMod     
    ) {
        uint256[8] memory skills = skillsLearned[_owner];

        burn = skills[BURN_ID];
        fatigue = skills[FATIGUE_ID]; 
        freezer = skills[FREEZER_ID]; 
        masterchef = skills[MASTERCHEF_ID]; 
        upgrades = skills[UPGRADES_ID];
        chefs = skills[CHEFS_ID]; 
        pizzaStorage = skills[STORAGE_ID]; 
        mafiaMod = skills[MAFIA_ID]; 
    }

    // External

    /**
    * Burns deposited $SODA and add skill point if level up.
    */
    function depositSoda(uint256 _amount) external {
        address sender = msg.sender;
        require(levelStarted(), "You can't level yet");
        require (_getLevel(sender) < sodaLevels.length, "already at max level");
        require (soda.balanceOf(sender) >= _amount, "not enough SODA");

        if(_amount + sodaDeposited[sender] > maxSodaAmount){
            _amount = maxSodaAmount - sodaDeposited[sender];
        }

        soda.burn(sender, _amount);

        uint256 levelBefore = _getLevel(sender);
        sodaDeposited[sender] += _amount;
        uint256 levelAfter = _getLevel(sender);
        skillPoints[sender] += levelAfter - levelBefore;

        if(levelAfter == sodaLevels.length){
            skillPoints[sender] += 1;
        }

        emit receivedSkillPoints(sender, levelAfter - levelBefore);
    }

    /**
    *  Spend skill point based on the skill group and skill level. Can only spend 1 point at a time.
    */
    function spendSkillPoints(uint256 _skillGroup, uint256 _skillLevel) external {
        address sender = msg.sender;

        require(skillPoints[sender] > 0, "Not enough skill points");
        require (_skillGroup <= MAX_SKILL_LEVEL.length - 1, "Invalid Skill Group");
        require(_skillLevel >= 1 && _skillLevel <= MAX_SKILL_LEVEL[_skillGroup], "Invalid Skill Level");
        
        uint256 currentSkillLevel = skillsLearned[sender][_skillGroup];
        require(_skillLevel == currentSkillLevel + 1, "Invalid Skill Level jump"); //can only level up 1 point at a time

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
        require (level > 1, "you are still at level 1");
        require (soda.balanceOf(sender) >= costToRespec, "not enough SODA");

        soda.burn(sender, costToRespec);

        skillsLearned[sender][BURN_ID] = 0;
        skillsLearned[sender][FATIGUE_ID] = 0;
        skillsLearned[sender][FREEZER_ID] = 0;
        skillsLearned[sender][MASTERCHEF_ID] = 0;
        skillsLearned[sender][UPGRADES_ID] = 0;
        skillsLearned[sender][CHEFS_ID] = 0;
        skillsLearned[sender][STORAGE_ID] = 0;
        skillsLearned[sender][MAFIA_ID] = 0;

        skillPoints[sender] = level - 1;

        if(level == sodaLevels.length){
            skillPoints[sender] += 1;
        }

        emit respec(sender, level);

    }

    // Admin

    function levelStarted() public view returns (bool) {
        return levelTime != 0 && block.timestamp >= levelTime;
    }

    function setLevelStartTime(uint256 _startTime) external onlyOwner {
        require (_startTime >= block.timestamp, "startTime cannot be in the past");
        require(!levelStarted(), "leveling already started");
        levelTime = _startTime;
    }


    // In case we rebalance the leveling costs this fixes the skill points to correct players
    function fixSkillPoints(address _player) public {
        uint256 level = _getLevel(_player);
        uint256 currentSkillPoints = skillPoints[_player];
        uint256 totalSkillsLearned = skillsLearned[_player][BURN_ID] + skillsLearned[_player][FATIGUE_ID] + skillsLearned[_player][FREEZER_ID] + skillsLearned[_player][MASTERCHEF_ID] + skillsLearned[_player][UPGRADES_ID] + skillsLearned[_player][CHEFS_ID] + skillsLearned[_player][STORAGE_ID] + skillsLearned[_player][MAFIA_ID];

        uint256 correctSkillPoints = level - 1;
        if(level == sodaLevels.length){ // last level has 2 skill points
            correctSkillPoints += 1;
        }
        if(correctSkillPoints > currentSkillPoints + totalSkillsLearned){
            skillPoints[_player] += correctSkillPoints - currentSkillPoints - totalSkillsLearned;
        }
    }

        // PIZZERIA MIGRATION
    IPizzeriaV3 public oldPizzeria;
    mapping(address => bool) public updateOnce; // owner => has updated

    function checkIfNeedUpdate(address _owner) public view returns (bool) {
        if(updateOnce[_owner]){
            return false; // does not need update if already updated
        }

        uint256 oldSodaDeposited = oldPizzeria.sodaDeposited(_owner);

        if(oldSodaDeposited > 0){
            return true; // if the player deposited any soda it means he interacted with the Pizzeria improvements
        }

        return false;

    }

    function setOldPizzeria(address _oldPizzeria) external onlyOwner {
        oldPizzeria = IPizzeriaV3(_oldPizzeria);
    }

    function updateDataFromOldPizzeria(address _owner) external {
        require (checkIfNeedUpdate(_owner), "Owner dont need to update");
        updateOnce[_owner] = true;

        sodaDeposited[_owner] = oldPizzeria.sodaDeposited(_owner);

        skillPoints[_owner] = oldPizzeria.skillPoints(_owner);

        uint256 burnSkillId = oldPizzeria.skillsLearned(_owner, 0);
        uint256 fatigueSkillId = oldPizzeria.skillsLearned(_owner, 1);
        uint256 freezerSkillId = oldPizzeria.skillsLearned(_owner, 2);
        uint256 masterchefSkillId = oldPizzeria.skillsLearned(_owner, 3);
        uint256 upgradeSkillId = oldPizzeria.skillsLearned(_owner, 4);
        uint256 chefSkillId = oldPizzeria.skillsLearned(_owner, 5);
        
        skillsLearned[_owner] = [burnSkillId, fatigueSkillId, freezerSkillId, masterchefSkillId, upgradeSkillId, chefSkillId, 0, 0];

        fixSkillPoints(_owner); // Fix skill points because of rebalance
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Supply cap of 15,000,000
contract Soda is ERC20Capped(15_000_000 * 1e18), Ownable {

    address public upgradeAddress;
    address public pizzeriaAddress;

    constructor() ERC20("Soda", "SODA") {}

    function setUpgradeAddress(address _upgradeAddress) external onlyOwner {
        upgradeAddress = _upgradeAddress;
    }

    function setPizzeriaAddress(address _pizzeriaAddress) external onlyOwner {
        pizzeriaAddress = _pizzeriaAddress;
    }

    // external

    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0));
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(upgradeAddress != address(0) && pizzeriaAddress != address(0), "missing initial requirements");
        require(_msgSender() == upgradeAddress || _msgSender() == pizzeriaAddress, "msgsender does not have permission");
        _burn(_from, _amount);
    }

    function transferForUpgradesFees(address _from, uint256 _amount) external {
        require(upgradeAddress != address(0), "missing initial requirements");
        require(_msgSender() == upgradeAddress, "only the upgrade contract can call transferForUpgradesFees");
        _transfer(_from, upgradeAddress, _amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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