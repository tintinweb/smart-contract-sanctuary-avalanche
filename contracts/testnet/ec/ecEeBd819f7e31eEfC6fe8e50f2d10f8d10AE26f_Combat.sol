// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "Structs.sol";
import "UsefulFunc.sol";
import "Database.sol";

contract Combat is Database {
    Fighter p1;
    Fighter p2;
    int256 public dmgTest = 0;
    int256 public counter = 0;
    bool p1attacks = true;
    AttackPhase[] combatSummary;

    constructor() {
        // (p1, p2) = whoStarts(getFighter(0), getFighter(1));
    }

    function getp1() public view returns (Fighter memory) {
        return p1;
    }

    function getp2() public view returns (Fighter memory) {
        return p2;
    }

    function getLenCmb() public view returns (AttackPhase[] memory) {
        return combatSummary;
    }

    function start() public {
        startFight(getFighter(0), getFighter(1));
    }

    function startFight(Fighter memory _p1, Fighter memory _p2) public {
        initFight(_p1, _p2);
        while (p1.currentHp > 0 && p2.currentHp > 0 && counter < 10) {
            initRound();
            p1attacks = true;
            if (p1.currentHp > 0) {
                p1AttackPhase();
            }
            p1attacks = false;
            if (p2.currentHp > 0) {
                p2AttackPhase();
            }
            endRound();
            counter++;
        }
        endFight();
    }

    //////// COMBAT PHASES

    function p1AttackPhase() public {
        (int256 dmg, AttackPhase memory ap) = getDmg(p1);
        if (p2.currentHp - dmg <= 0) p2.currentHp = 0;
        else p2.currentHp -= dmg;
        combatSummary.push(ap);
    }

    function p2AttackPhase() public {
        (int256 dmg, AttackPhase memory ap) = getDmg(p2);
        if (p1.currentHp - dmg <= 0) p1.currentHp = 0;
        else p1.currentHp -= dmg;
        combatSummary.push(ap);
    }

    function initFight(Fighter memory _p1, Fighter memory _p2) public {
        (p1, p2) = whoStarts(_p1, _p2);
    }

    function initRound() public {}

    function endRound() public {}

    function endFight() public {
        if (p1.fighterType == fighterType.player) setFighter(p1);
        if (p2.fighterType == fighterType.player) setFighter(p2);
    }

    // END COMBAT PHASES

    //////// COMBAT ACTIONS

    function getDmg(Fighter memory _attacker)
        public
        returns (int256, AttackPhase memory)
    {
        // randomSkill
        SkillOwned memory randomSkillOwned = getRandomSkillOwned(_attacker.id);
        Skill memory randomSkill = getSkill(randomSkillOwned.id);
        // calculateDmg
        int256 actionDmg = getSkillDmg(randomSkill.id, randomSkillOwned.level);
        // create AttackPhase
        AttackPhase memory ap = AttackPhase(
            _attacker.id,
            _attacker.fighterType,
            randomSkillOwned.id,
            actionDmg
        );
        return (actionDmg, ap);
    }

    // END COMBAT ACTIONS

    //////// OTHERS

    function getAttacker() public view returns (Fighter memory) {
        if (p1attacks) return p1;
        else return p2;
    }

    function getDefender() public view returns (Fighter memory) {
        if (!p1attacks) return p1;
        else return p2;
    }

    function whoStarts(Fighter memory char1, Fighter memory char2)
        public
        returns (Fighter memory, Fighter memory)
    {
        if (char1.agi > char2.agi) {
            return (char1, char2);
        } else if (char1.agi < char2.agi) {
            return (char2, char1);
        } else {
            uint256 rdn = randMod(2);
            if (rdn == 0) return (char1, char2);
            else return (char2, char1);
        }
    }

    // END OTHERS
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Structs {
    enum skillType {
        str,
        agi,
        intel
    }
    enum skillDmg {
        normal,
        crit
    }
    enum skillEffect {
        dot,
        hot,
        lifesteal
    }
    enum fighterType {
        player,
        mob,
        rare
    }
    struct Fighter {
        int256 id;
        fighterType fighterType;
        string name;
        int256 level;
        int256 xp;
        int256 currentHp;
        int256 stamina;
        int256 str;
        int256 agi;
        int256 intel;
    }

    struct SkillList {
        mapping(int256 => SkillOwned[]) skills;
        int256 skillSize;
    }

    struct SkillOwned {
        int256 id;
        int256 level;
    }

    struct Skill {
        int256 id;
        string name;
        skillType skillType;
        int256 dmg;
        int256 dmgPerLevel;
        //SkillStatus skillStatus;
        //skillDmg skillDmg;
    }

    struct SkillStatus {
        int256 id;
        string name;
        int256 dmg;
    }

    struct AttackPhase {
        int256 attackerId;
        fighterType fighterType;
        int256 skillOwnedId;
        int256 dmgDone;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "Structs.sol";

contract UsefulFunc is Structs {
    int256 randNonce = 0;

    function randMod(uint256 _mod) internal returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % _mod;
    }

    function getMaxHpFromStamina(int256 _stamina) public pure returns (int256) {
        return _stamina * 5 + 50;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "Structs.sol";
import "UsefulFunc.sol";

contract Database is Structs, UsefulFunc {
    mapping(int256 => Skill) public mapSkills;

    mapping(int256 => SkillOwned[]) public mapFighterSkills;

    mapping(int256 => Fighter) public mapFighters;
    int256 public fighterSize = 0;

    constructor() {
        // Adding Skills
        createSkills();

        // Adding 2 random chars
        randChar("koj", 20);
        randChar("abli", 20);
    }

    function createSkills() internal {
        addSkill(0, "Hammerstrike", skillType.str, 20, 5);
        addSkill(1, "Backstab", skillType.agi, 20, 5);
        addSkill(2, "Fireball", skillType.intel, 20, 5);
    }

    function getFighter(int256 _index) public view returns (Fighter memory) {
        return mapFighters[_index];
    }

    function setFighter(Fighter memory fighter) public {
        mapFighters[fighter.id] = fighter;
    }

    function getSkillOwned(int256 _index)
        public
        view
        returns (SkillOwned[] memory)
    {
        return mapFighterSkills[_index];
    }

    function getSkill(int256 _index) public view returns (Skill memory) {
        return mapSkills[_index];
    }

    function getSkillDmg(int256 _index, int256 _level)
        public
        view
        returns (int256)
    {
        Skill memory skill = mapSkills[_index];
        return skill.dmg + _level * skill.dmgPerLevel;
    }

    function getRandomSkillOwned(int256 _fighterIndex)
        public
        returns (SkillOwned memory)
    {
        uint256 randomSkillIndex = randMod(getSkillOwned(_fighterIndex).length);
        return getSkillOwned(_fighterIndex)[randomSkillIndex];
    }

    function addSkill(
        int256 _id,
        string memory _name,
        skillType _skillType,
        int256 _dmg,
        int256 _dmgPerLevel
    ) internal {
        mapSkills[_id] = Skill(_id, _name, _skillType, _dmg, _dmgPerLevel);
    }

    function randChar(string memory _name, uint256 points) internal {
        Fighter memory fighter;

        int256 str = 0;
        int256 intel = 0;
        int256 agi = 0;
        int256 stamina = 0;
        for (uint256 i = 0; i < points; i++) {
            uint256 r = randMod(5);
            if (r == 0) str += 1;
            else if (r == 1) intel += 1;
            else if (r == 2) agi += 1;
            else stamina += 1;
        }
        int256 currentHp = getMaxHpFromStamina(stamina);

        fighter.id = fighterSize;
        fighter.fighterType = fighterType.player;
        fighter.name = _name;
        fighter.str = str;
        fighter.intel = intel;
        fighter.agi = agi;
        fighter.stamina = stamina;
        fighter.currentHp = currentHp;

        SkillOwned[] storage skills = mapFighterSkills[fighter.id];
        mapFighterSkills[fighter.id].push(SkillOwned(1, 1));
        mapFighterSkills[fighter.id].push(SkillOwned(2, 1));
        mapFighterSkills[fighter.id].push(SkillOwned(3, 1));

        mapFighters[fighter.id] = fighter;
        fighterSize += 1;
    }
}