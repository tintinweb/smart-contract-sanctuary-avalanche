// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "Structs.sol";
import "UsefulFunc.sol";
import "Database.sol";

contract Combat is Database {
    Fighter p1;
    Fighter p2;
    Fighter player;
    Fighter mob;
    bool p1attacks = true;
    CombatHistory combatHistory;

    constructor() {
        // (p1, p2) = whoStarts(getFighter(0), getFighter(1));
    }

    function getp1() public view returns (Fighter memory) {
        return p1;
    }

    function getp2() public view returns (Fighter memory) {
        return p2;
    }

    function getLenCmb() public view returns (CombatHistory memory) {
        return combatHistory;
    }

    function start(int256 _playerId, int256 _mobId) public {
        startFight(getFighter(_playerId), getMob(_mobId));
    }

    function startFight(Fighter memory _p1, Fighter memory _p2) public {
        initFight(_p1, _p2);
        while (p1.currentHp > 0 && p2.currentHp > 0) {
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
        }
        endFight();
    }

    //////// COMBAT PHASES

    function p1AttackPhase() public {
        (int256 dmg, CombatPhase memory ap) = getDmg(p1);
        if (p2.currentHp - dmg <= 0) p2.currentHp = 0;
        else p2.currentHp -= dmg;
        combatHistory.combatPhasesSize += 1;
        combatHistory.combatPhases.push(ap);
    }

    function p2AttackPhase() public {
        (int256 dmg, CombatPhase memory ap) = getDmg(p2);
        if (p1.currentHp - dmg <= 0) p1.currentHp = 0;
        else p1.currentHp -= dmg;
        combatHistory.combatPhasesSize += 1;
        combatHistory.combatPhases.push(ap);
    }

    function initFight(Fighter memory _p1, Fighter memory _p2) public {
        (p1, p2) = whoStarts(_p1, _p2);
        if (_p1.fighterType == fighterType.player) {
            player = p1;
            mob = p2;
        } else {
            player = p2;
            mob = p1;
        }
    }

    function initRound() public {}

    function endRound() public {}

    function endFight() public {
        modifyPlayerState(player);
        // reset elements
        delete p1;
        delete p2;
        delete player;
        delete mob;
        delete combatHistory;
        p1attacks = true;
    }

    // END COMBAT PHASES

    //////// COMBAT ACTIONS

    function getDmg(Fighter memory _attacker)
        public
        returns (int256, CombatPhase memory)
    {
        // randomSkill
        SkillOwned memory randomSkillOwned = getRandomSkillOwned(_attacker.id);
        Skill memory randomSkill = getSkill(randomSkillOwned.id);
        // calculateDmg
        int256 actionDmg = getSkillDmg(randomSkill.id, randomSkillOwned.level);
        // create CombatPhase
        CombatPhase memory ap = CombatPhase(
            _attacker.id,
            _attacker.fighterType,
            randomSkillOwned.id,
            actionDmg
        );
        return (actionDmg, ap);
    }

    // END COMBAT ACTIONS

    //////// OTHERS

    function modifyPlayerState(Fighter memory _fighter) public {
        addXp(_fighter, 50);
        setFighter(_fighter);
        pushCombatHistory(_fighter.id, combatHistory.combatPhases);
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
        npc
    }
    struct Fighter {
        int256 id;
        fighterType fighterType;
        string name;
        uint256 level;
        uint256 xp;
        int256 currentHp;
        int256 stamina;
        int256 str;
        int256 agi;
        int256 intel;
        uint256 points;
        uint256 newSkill;
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

    struct CombatPhase {
        int256 attackerId;
        fighterType fighterType;
        int256 skillOwnedId;
        int256 dmgDone;
    }

    struct CombatHistory {
        int256 combatPhasesSize;
        CombatPhase[] combatPhases;
    }

    struct Tier {
        int256 cost;
        int256 minReward;
        int256 maxReward;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract UsefulFunc {
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
    mapping(int256 => Tier) public mapTier;
    mapping(int256 => Skill) public mapSkills;
    mapping(int256 => Fighter) public mapMobs;
    mapping(int256 => SkillOwned[]) public mapMobSkills;
    mapping(int256 => SkillOwned[]) public mapFighterSkills;
    mapping(int256 => Fighter) public mapFighters;
    int256 public fighterSize = 0;
    int256 public mobSize = 0;
    uint256 public combatIdNonce = 0;
    uint256[] public levelTiers;

    // change int256 with string ?
    mapping(uint256 => CombatPhase[]) public mapCombatPhases;
    mapping(int256 => uint256[]) public mapCombatHistory;

    constructor() {
        // Adding Skills
        createSkills();

        // Adding Tiers
        mapTier[1] = Tier(0, 50, 100);
        mapTier[2] = Tier(100, 175, 250);
        mapTier[3] = Tier(200, 300, 400);
        mapTier[4] = Tier(350, 475, 600);
        mapTier[5] = Tier(500, 650, 800);
        mapTier[6] = Tier(700, 650, 1100);
        mapTier[7] = Tier(900, 800, 1450);
        mapTier[8] = Tier(1100, 950, 1750);
        mapTier[9] = Tier(1350, 1100, 2100);
        mapTier[10] = Tier(1700, 1350, 2600);

        // Adding Levels
        // 0
        levelTiers.push(50);
        levelTiers.push(100);
        levelTiers.push(120);
        levelTiers.push(140);
        levelTiers.push(160);
        // 5
        levelTiers.push(180);
        levelTiers.push(220);
        levelTiers.push(260);
        levelTiers.push(300);
        levelTiers.push(340);
        // 10
        levelTiers.push(400);
        levelTiers.push(460);
        levelTiers.push(520);
        levelTiers.push(580);
        levelTiers.push(640);
        // 15
        levelTiers.push(700);
        levelTiers.push(800);
        levelTiers.push(900);
        levelTiers.push(1000);
        levelTiers.push(1100);
        // 20
        levelTiers.push(1500);

        // Adding 2 random chars
        randChar("koj", 20);
        randChar("abli", 20);

        // Adding 3 random mobs
        randMob("Boar", 18);
        randMob("Wolf", 20);
        randMob("Fox", 22);
    }

    function rest(Fighter memory _fighter) public {
        mapFighters[_fighter.id].currentHp = getMaxHpFromStamina(
            _fighter.stamina
        );
    }

    function addXp(Fighter memory _fighter, uint256 _xp)
        public
        view
        returns (Fighter memory)
    {
        uint256 newXp = _fighter.xp + _xp;
        bool levelUp = newXp >= levelTiers[_fighter.level];
        if (levelUp) {
            _fighter.xp = newXp - levelTiers[_fighter.level];
            _fighter.points += 5;
            _fighter.newSkill++;
            _fighter.level++;
        } else {
            _fighter.xp = newXp;
        }

        return _fighter;
    }

    function pushCombatHistory(
        int256 _attackerId,
        CombatPhase[] memory combatPhases
    ) public {
        combatIdNonce++;
        uint256 combatId = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, combatIdNonce)
            )
        );
        mapCombatHistory[_attackerId].push(combatId);
        CombatPhase[] storage cp = mapCombatPhases[combatId];
        for (uint256 i = 0; i < combatPhases.length; i++)
            cp.push(combatPhases[i]);
    }

    function getCombatPhase(uint256 _combatId)
        public
        view
        returns (CombatPhase[] memory)
    {
        return mapCombatPhases[_combatId];
    }

    function getCombatHistory(int256 _indexHistory)
        public
        view
        returns (uint256[] memory)
    {
        return mapCombatHistory[_indexHistory];
    }

    function createSkills() internal {
        addSkill(0, "Hammerstrike", skillType.str, 20, 5);
        addSkill(1, "Backstab", skillType.agi, 20, 5);
        addSkill(2, "Fireball", skillType.intel, 20, 5);
    }

    function getFighter(int256 _index) public view returns (Fighter memory) {
        return mapFighters[_index];
    }

    function getMob(int256 _index) public view returns (Fighter memory) {
        return mapMobs[_index];
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

        // SkillOwned[] storage skills = mapFighterSkills[fighter.id];
        mapFighterSkills[fighter.id].push(SkillOwned(1, 1));
        mapFighterSkills[fighter.id].push(SkillOwned(2, 1));
        mapFighterSkills[fighter.id].push(SkillOwned(3, 1));

        mapFighters[fighter.id] = fighter;
        fighterSize += 1;
    }

    function randMob(string memory _name, uint256 points) internal {
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

        fighter.id = mobSize;
        fighter.fighterType = fighterType.npc;
        fighter.name = _name;
        fighter.str = str;
        fighter.intel = intel;
        fighter.agi = agi;
        fighter.stamina = stamina;
        fighter.currentHp = currentHp;

        mapMobSkills[fighter.id].push(SkillOwned(1, 1));

        mapMobs[fighter.id] = fighter;
        mobSize += 1;
    }
}