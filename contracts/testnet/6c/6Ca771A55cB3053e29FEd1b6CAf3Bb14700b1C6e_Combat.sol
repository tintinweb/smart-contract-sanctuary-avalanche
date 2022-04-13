// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "Structs.sol";
import "UsefulFunc.sol";
import "Database.sol";

contract Combat is Database {
    // Fighter p1;
    // Fighter p2;
    // Fighter player;
    // Fighter mob;

    constructor() {}

    function start(uint256 _playerId, uint256 _tierLevel) public {
        require(mapFighters[_playerId].cd < block.timestamp, "On cooldown...");
        require(mapFighters[_playerId].level <= _tierLevel, "Too low level...");
        // generate mob
        uint256 mobId = randMod(3) + 3 * _tierLevel;
        startFight(getFighter(_playerId), getMob(mobId), _tierLevel);
    }

    function startFight(
        Fighter memory _p1,
        Fighter memory _p2,
        uint256 _tierLevel
    ) public {
        Fighter memory p1;
        Fighter memory p2;
        Fighter memory player;
        Fighter memory mob;
        Tier memory tier = mapTier[_tierLevel];
        CombatHistory memory combatHistory;
        bool p1attacks = true;
        (p1, p2) = whoStarts(_p1, _p2);
        (player, mob) = initFight(_p1, _p2);
        while (p1.currentHp > 0 && p2.currentHp > 0) {
            initRound();
            p1attacks = true;
            if (p1.currentHp > 0) {
                combatHistory.combatPhases[
                    combatHistory.combatPhasesSize
                ] = p1AttackPhase(p1, p2);
                combatHistory.combatPhasesSize++;
                // combatHistory.combatPhases.push(p1AttackPhase(p1, p2));
                // combatHistory.combatPhasesSize += 1;
            }
            p1attacks = false;
            if (p2.currentHp > 0) {
                combatHistory.combatPhases[
                    combatHistory.combatPhasesSize
                ] = p2AttackPhase(p2, p1);
                combatHistory.combatPhasesSize++;
            }
            endRound();
        }
        endFight(player, combatHistory, tier);
    }

    //////// COMBAT PHASES

    function p1AttackPhase(Fighter memory _p1, Fighter memory _p2)
        public
        returns (CombatPhase memory)
    {
        (uint256 dmg, CombatPhase memory ap) = getDmg(_p1);
        if (_p2.currentHp - dmg <= 0) _p2.currentHp = 0;
        else _p2.currentHp -= dmg;
        return ap;
    }

    function p2AttackPhase(Fighter memory _p1, Fighter memory _p2)
        public
        returns (CombatPhase memory)
    {
        (uint256 dmg, CombatPhase memory ap) = getDmg(_p2);
        if (_p1.currentHp - dmg <= 0) _p1.currentHp = 0;
        else _p1.currentHp -= dmg;
        return ap;
    }

    function initFight(Fighter memory _p1, Fighter memory _p2)
        public
        pure
        returns (Fighter memory, Fighter memory)
    {
        if (_p1.fighterType == fighterType.player) return (_p1, _p2);
        else return (_p2, _p1);
    }

    function initRound() public {}

    function endRound() public {}

    function endFight(
        Fighter memory _player,
        CombatHistory memory _combatHistory,
        Tier memory _tier
    ) public {
        modifyPlayerState(_player, _combatHistory, _tier);
        // reset elements ?
        // delete p1;
        // delete p2;
        // delete player;
        // delete mob;
        // delete combatHistory;
        // p1attacks = true;
    }

    // END COMBAT PHASES

    //////// COMBAT ACTIONS

    function getDmg(Fighter memory _attacker)
        public
        returns (uint256, CombatPhase memory)
    {
        // randomSkill
        SkillOwned memory randomSkillOwned = getRandomSkillOwned(_attacker.id);
        Skill memory randomSkill = getSkill(randomSkillOwned.id);
        // calculateDmg
        uint256 actionDmg = getSkillDmg(randomSkill.id, randomSkillOwned.level);
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

    function modifyPlayerState(
        Fighter memory _fighter,
        CombatHistory memory _combatHistory,
        Tier memory _tier
    ) public {
        _fighter = addXp(_fighter, 50);
        _fighter.cd = block.timestamp + _tier.cd;
        setFighter(_fighter);
        pushCombatHistory(_fighter.id, _combatHistory.combatPhases);
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
        uint256 id;
        fighterType fighterType;
        string name;
        uint256 level;
        uint256 xp;
        uint256 currentHp;
        uint256 stamina;
        uint256 str;
        uint256 agi;
        uint256 intel;
        uint256 points;
        uint256 newSkill;
        uint256 cd;
    }

    struct SkillOwned {
        uint256 id;
        uint256 level;
    }

    struct Skill {
        uint256 id;
        string name;
        skillType skillType;
        uint256 dmg;
        uint256 dmgPerLevel;
        //SkillStatus skillStatus;
        //skillDmg skillDmg;
    }

    struct SkillStatus {
        uint256 id;
        string name;
        uint256 dmg;
    }

    struct CombatPhase {
        uint256 attackerId;
        fighterType fighterType;
        uint256 skillOwnedId;
        uint256 dmgDone;
    }

    struct CombatHistory {
        uint256 combatPhasesSize;
        CombatPhase[] combatPhases;
    }

    struct Tier {
        uint256 cost;
        uint256 cd;
        uint256 minReward;
        uint256 maxReward;
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

    function getMaxHpFromStamina(uint256 _stamina)
        internal
        pure
        returns (uint256)
    {
        return _stamina * 5 + 50;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "Structs.sol";
import "UsefulFunc.sol";

contract Database is Structs, UsefulFunc {
    mapping(uint256 => Tier) public mapTier;
    mapping(uint256 => Skill) public mapSkills;
    mapping(uint256 => Fighter) public mapMobs;
    mapping(uint256 => SkillOwned[]) public mapMobSkills;
    mapping(uint256 => SkillOwned[]) public mapFighterSkills;
    mapping(uint256 => Fighter) public mapFighters;
    uint256 public fighterSize = 0;
    uint256 public mobSize = 0;
    uint256 public combatIdNonce = 0;
    uint256[] public levelTiers;

    // change int256 with string ?
    mapping(uint256 => CombatPhase[]) public mapCombatPhases;
    mapping(uint256 => uint256[]) public mapCombatHistory;

    constructor() {
        // Adding Skills
        addSkill(0, "Hammerstrike", skillType.str, 20, 5);
        addSkill(1, "Backstab", skillType.agi, 20, 5);
        addSkill(2, "Fireball", skillType.intel, 20, 5);

        // Adding Tiers
        uint256 baseCd = 0;
        mapTier[1] = Tier(0, baseCd, 50, 100);
        mapTier[2] = Tier(100, baseCd, 175, 250);
        mapTier[3] = Tier(200, baseCd, 300, 400);
        mapTier[4] = Tier(350, baseCd, 475, 600);
        mapTier[5] = Tier(500, baseCd, 650, 800);
        mapTier[6] = Tier(700, baseCd, 650, 1100);
        mapTier[7] = Tier(900, baseCd, 800, 1450);
        mapTier[8] = Tier(1100, baseCd, 950, 1750);
        mapTier[9] = Tier(1350, baseCd, 1100, 2100);
        mapTier[10] = Tier(1700, baseCd, 1350, 2600);

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

    function addSkillPoints(uint256 _fighterId, uint256[] memory list) public {
        uint256 sum;
        Fighter storage fighter = mapFighters[_fighterId];
        for (uint256 i = 0; i < list.length; i++) sum += list[i];
        require(fighter.points <= sum, "Number of points is too high.");
        fighter.stamina += list[0];
        fighter.str;
        fighter.agi;
        fighter.intel;
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
        uint256 _attackerId,
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

    function getCombatHistory(uint256 _indexHistory)
        public
        view
        returns (uint256[] memory)
    {
        return mapCombatHistory[_indexHistory];
    }

    function getFighter(uint256 _index) public view returns (Fighter memory) {
        return mapFighters[_index];
    }

    function getMob(uint256 _index) public view returns (Fighter memory) {
        return mapMobs[_index];
    }

    function setFighter(Fighter memory fighter) public {
        mapFighters[fighter.id] = fighter;
    }

    function getSkillOwned(uint256 _index)
        public
        view
        returns (SkillOwned[] memory)
    {
        return mapFighterSkills[_index];
    }

    function getSkill(uint256 _index) public view returns (Skill memory) {
        return mapSkills[_index];
    }

    function getSkillDmg(uint256 _index, uint256 _level)
        public
        view
        returns (uint256)
    {
        Skill memory skill = mapSkills[_index];
        return skill.dmg + _level * skill.dmgPerLevel;
    }

    function getRandomSkillOwned(uint256 _fighterIndex)
        public
        returns (SkillOwned memory)
    {
        uint256 randomSkillIndex = randMod(getSkillOwned(_fighterIndex).length);
        return getSkillOwned(_fighterIndex)[randomSkillIndex];
    }

    function addSkill(
        uint256 _id,
        string memory _name,
        skillType _skillType,
        uint256 _dmg,
        uint256 _dmgPerLevel
    ) internal {
        mapSkills[_id] = Skill(_id, _name, _skillType, _dmg, _dmgPerLevel);
    }

    function randChar(string memory _name, uint256 points) internal {
        Fighter memory fighter;

        uint256 str = 0;
        uint256 intel = 0;
        uint256 agi = 0;
        uint256 stamina = 0;
        for (uint256 i = 0; i < points; i++) {
            uint256 r = randMod(5);
            if (r == 0) str += 1;
            else if (r == 1) intel += 1;
            else if (r == 2) agi += 1;
            else stamina += 1;
        }
        uint256 currentHp = getMaxHpFromStamina(stamina);

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

        uint256 str = 0;
        uint256 intel = 0;
        uint256 agi = 0;
        uint256 stamina = 0;
        for (uint256 i = 0; i < points; i++) {
            uint256 r = randMod(5);
            if (r == 0) str += 1;
            else if (r == 1) intel += 1;
            else if (r == 2) agi += 1;
            else stamina += 1;
        }
        uint256 currentHp = getMaxHpFromStamina(stamina);

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