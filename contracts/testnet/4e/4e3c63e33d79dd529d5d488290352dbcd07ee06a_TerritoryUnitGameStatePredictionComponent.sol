/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-13
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;

library ModularArray {
    // useful to create array with undefined length and where it's possible to add an element at any index

    // use underlying element (type value of "element" can be change to use address or bytes for exemple)
    struct UnderlyingElement {
        uint element;
        bool init;

        uint last;
        uint next;
    }

    // create a modular array
    struct ModularArrayStruct {
        mapping (uint => UnderlyingElement) array;
        mapping (uint => uint) associatedIndexFromElement;
        uint firstIndex;
        uint nbIndex;
        uint totalElementsNumber;
    }

    // add any element just after an index (0: last index "_index", 1: new index with "_element" value)
    function addAfterIndex(ModularArrayStruct storage _array, uint _index, uint _element) internal returns (uint) {
        uint _nbIndex = _array.nbIndex;
        _array.associatedIndexFromElement[_element] = _nbIndex;

        if (_array.totalElementsNumber > 0) {
            require(_array.array[_index].init == true, "Wrong indexing matching");

            UnderlyingElement storage lastElement = _array.array[_index];
            UnderlyingElement storage nextElement = _array.array[lastElement.next];

            _array.array[_nbIndex] = UnderlyingElement(_element, true, _index, lastElement.next);

            lastElement.next = _nbIndex;
            nextElement.last = _nbIndex;
        } else {
            _array.firstIndex = _nbIndex;
            _array.array[_nbIndex] = UnderlyingElement(_element, true, 0, 0);
        }

        _array.nbIndex++;
        _array.totalElementsNumber++;
        return _nbIndex;
    }

    // /!/ EVERY ELEMENTS MUST BE DIFFERENT (like unique index)
    function addAfterElement(ModularArrayStruct storage _array, uint _elementIndex, uint _element) internal returns (uint) {
        return addAfterIndex(_array, _array.associatedIndexFromElement[_elementIndex], _element);
    }

    // add any element just before an index (0: last index "_index", 1: new index with "_element" value)
    function addBeforeIndex(ModularArrayStruct storage _array, uint _index, uint _element) internal returns (uint) {
        uint _nbIndex = _array.nbIndex;
        _array.associatedIndexFromElement[_element] = _nbIndex;

        if (_array.totalElementsNumber > 0) {
            require(_array.array[_index].init == true, "Wrong indexing matching");

            UnderlyingElement storage nextElement = _array.array[_index];
            UnderlyingElement storage lastElement = _array.array[nextElement.last];
            
            if (_array.firstIndex == _index) {
                _array.array[_nbIndex] = UnderlyingElement(_element, true, 0, _index);

                _array.firstIndex = _nbIndex;
                nextElement.last = _nbIndex;
            } else {
                _array.array[_nbIndex] = UnderlyingElement(_element, true, nextElement.last, _index);
            
                lastElement.next = _nbIndex;
                nextElement.last = _nbIndex;
            }
        } else {
            _array.firstIndex = _nbIndex;
            _array.array[_nbIndex] = UnderlyingElement(_element, true, 0, 0);
        }

        _array.nbIndex++;
        _array.totalElementsNumber++;
        return _nbIndex;
    }

    // /!/ EVERY ELEMENTS MUST BE DIFFERENT (like unique index)
    function addBeforeElement(ModularArrayStruct storage _array, uint _elementIndex, uint _element) internal returns (uint) {
        return addBeforeIndex(_array, _array.associatedIndexFromElement[_elementIndex], _element);
    }

    // remove an element by its index 
    function removeFromIndex(ModularArrayStruct storage _array, uint _index) internal {
        require(_array.array[_index].init == true, "Wrong indexing matching");
        require(_array.totalElementsNumber > 0, "Can't remove non existent indexes");
        UnderlyingElement storage element = _array.array[_index];
        UnderlyingElement storage lastElement = _array.array[element.last];
        UnderlyingElement storage nextElement = _array.array[element.next];

        _array.associatedIndexFromElement[element.element] = 0;

        if (_array.firstIndex == _index) {
            _array.firstIndex = element.next;
            lastElement.last = 0;
        } else {
            lastElement.next = element.next;
            nextElement.last = element.last;
        }

        _array.totalElementsNumber--;
        element.init = false;
    }

    // /!/ EVERY ELEMENTS MUST BE DIFFERENT (like unique index)
    function removeFromElement(ModularArrayStruct storage _array, uint _element) internal {
        removeFromIndex(_array, _array.associatedIndexFromElement[_element]);
    }

    // return the whole array
    // - "_excludedIndex" = -1 to not exclude index
    function getWholeArray(ModularArrayStruct storage _array) internal view returns (uint[] memory) {
        uint[] memory _fullArray = new uint[](_array.totalElementsNumber);
        UnderlyingElement memory _currentElement = _array.array[_array.firstIndex];
        for (uint i=0; i < _array.totalElementsNumber; i++) {
            _fullArray[i] = _currentElement.element;
            _currentElement = _array.array[_currentElement.next];
        }
        return _fullArray;
    }

    function getElementIndex(ModularArrayStruct storage _array, uint _element) internal view returns (uint[] memory, uint) {
        uint[] memory array = getWholeArray(_array);
        for (uint i=0; i < array.length; i++) {
            if (array[i] == _element) return (array, i);
        }
        return (array, 0);
    }

    function resetArray(ModularArrayStruct storage _array) internal {
        _array.totalElementsNumber = 0;
    }
}

interface IWarfareUnit {
    function addDamageLog(uint _tokenId, uint _amount, uint _timestamp) external;
}

interface ITerritoryUnit {
    function addNewOwnerChangeLog(uint _tokenId, address _newOwner, uint _timestamp) external;
    function addDamageLog(uint _tokenId, uint _amount, uint _timestamp) external;
    function packNewUnit(address _contractReference, uint _tokenId, uint _timestamp) external;
}

contract TerritoryUnitGameStatePredictionComponent {
    using ModularArray for ModularArray.ModularArrayStruct;

    // basic structur to store all important information about attackers necessary to make calculations
    struct Attacker {
        uint fightEntry;

        uint lp;
        uint dmg;
        
        uint predictedDeathTime;
        bool killedByTerritoryUnit;

        uint packedTime;
    }

    struct PoolInfo {
        TerritoryUnit territoryUnit;
    }

    struct TerritoryUnit {
        uint FIGHT_TIME;
        uint lp;
        uint dmg;

        address contractReference;
        uint tokenId;
    }

    struct UnitReference {
        address contractReference;
        uint tokenId;
    }

    uint uniqueId = 1;
    mapping (uint => uint) public currentAttackersNumber; // current attackers number (in terms of different players, not units) for every pools id

    uint public MAX_ATTACKERS_OWNERS = 20; // max number of unit who are / will be fighting in one pool

    mapping (uint => Attacker) public attackersIndex; // associate unique id to each attackers to handle them easily 
    mapping (uint => uint) public poolIdReference; // reference each unique id to its current pool;
    mapping (uint => mapping (address => uint)) public deployedUnitPerAddress; // different attackers (non packed) amount in a single fight for each address and for each pool id

    mapping (uint => mapping (uint => uint)) public elementIndex; // current index for each element in the whole array of "attackers" (attackers.getWholeArray()) for each pool id
    mapping (uint => ModularArray.ModularArrayStruct) public attackers; // attackers list sorted by their fight entry (first entry <=> first index) for each pool id
    mapping (uint => uint) public lastDeathTime; // last death time for each pool

    mapping (address => mapping (uint => uint)) public referenceTreeAttackers; // reference for each attackers unique id from their nft contract address and then their token id (address => uint) 
    mapping (uint => UnitReference) public unitReference;

    mapping (uint => PoolInfo) public poolsIndex; // associate each pool id to its stats

    uint private DECIMALS = 10000;

    constructor () {
        updatePoolStats(0, address(0), 0, 50, 1500, 4);

        _addAttacker(0, address(40), address(0), 0, block.timestamp + 10, 1000, 2);
        _addAttacker(0, address(1424), address(0), 0, block.timestamp + 11, 1200, 3);
        _addAttacker(0, address(24242), address(0), 0, block.timestamp + 200, 1000, 4);
        _addAttacker(0, address(3424), address(0), 0, block.timestamp + 300, 1100, 5);
    }

    function updatePoolStats(uint _poolId, address _contractReference, uint _tokenId, uint _fightTime, uint _lp, uint _dmg) public {
        poolsIndex[_poolId] = PoolInfo(TerritoryUnit(_fightTime, _lp, _dmg, _contractReference, _tokenId));
    }

    function _addAttacker(uint _poolId, address _sender, address _contractReference, uint _tokenIdReference, uint _fightEntry, uint _lp, uint _dmg) public returns (uint) {
        require(deployedUnitPerAddress[_poolId][_sender] == 0, "this address already have an unit on this fight pool");
        require(currentAttackersNumber[_poolId] + 1 <= MAX_ATTACKERS_OWNERS, "max commanders in this fight reached");
        
        // set the new Attacker object created from the input datas
        attackersIndex[uniqueId] = Attacker(_fightEntry, _lp, _dmg, 0, false, 0);
        
        // retreive the index and set at the rigth place the new element (in croissant fight entry order)
        (bool _addAfterElement, uint _element) = getFightEntryElement(_fightEntry, _poolId);
        if (_addAfterElement) attackers[_poolId].addAfterElement(_element, uniqueId);
        else attackers[_poolId].addBeforeElement(_element, uniqueId);

        // set the reference of the attacker linked to its nft contract address and token id reference
        referenceTreeAttackers[_contractReference][_tokenIdReference] = uniqueId;
        unitReference[uniqueId] = UnitReference(_contractReference, _tokenIdReference);

        poolIdReference[uniqueId] = _poolId;

        uniqueId++;
        deployedUnitPerAddress[_poolId][_sender] = 1;
        currentAttackersNumber[_poolId]++;

        return uniqueId-1;
    }

    function _removeAttacker(uint _poolId, address _contractReference, uint _tokenIdReference) public {
        require(getPoolId(_contractReference,_tokenIdReference) == _poolId, "wrong pool");
        
        uint _uniqueId = referenceTreeAttackers[_contractReference][_tokenIdReference];
        uint _unitCurrentlyAttacked = getUnitAttackedForUniqueIdAndTimestamp(_poolId, _uniqueId, block.timestamp);

        // if the unit is currently attacking another unit, apply some damage to the both units
        if (_unitCurrentlyAttacked != 0) {
            uint predictedDeathTimeA = cal(attackersIndex[_uniqueId].predictedDeathTime);
            uint predictedDeathTimeB = cal(attackersIndex[_unitCurrentlyAttacked].predictedDeathTime);
            uint deltaFighting;
            uint fightTime = getFightTime(_poolId);

            // compute how much time both unit were fighting
            if (predictedDeathTimeA < predictedDeathTimeB) {
                deltaFighting = fightTime - (predictedDeathTimeA - block.timestamp);
            } else {
                deltaFighting = fightTime - (predictedDeathTimeB - block.timestamp);
            }
            
            // compute the ratio of damage both unit will take (if they were fighting almost during fightTime, the ratio will be nearly 1 (they take all their damages))
            uint timeRatio = cal((DECIMALS * deltaFighting) / fightTime);

            // compute both strenght
            uint deathScoreA = cal(attackersIndex[_uniqueId].lp / attackersIndex[_unitCurrentlyAttacked].dmg);
            uint deathScoreB = cal(attackersIndex[_unitCurrentlyAttacked].lp / attackersIndex[_uniqueId].dmg);

            if (deathScoreA < deathScoreB) {
                // damage ratio to not remove the same amount of lp as the weakest unit
                uint damageRatio = cal((DECIMALS * deathScoreA) / deathScoreB);
                
                attackersIndex[_uniqueId].lp -= cal((timeRatio * attackersIndex[_uniqueId].lp) / DECIMALS); // "_uniqueId" unit lp is just his lp * the time ratio because if the ratio were "1", he was killed
                attackersIndex[_unitCurrentlyAttacked].lp -= cal((damageRatio * timeRatio * attackersIndex[_unitCurrentlyAttacked].lp) / (DECIMALS * DECIMALS)); 
            } else {
                // damage ratio to not remove the same amount of lp as the weakest unit
                uint damageRatio = cal((DECIMALS * deathScoreB) / deathScoreA);

                attackersIndex[_uniqueId].lp -= cal((damageRatio * timeRatio * attackersIndex[_uniqueId].lp) / (DECIMALS * DECIMALS));
                attackersIndex[_unitCurrentlyAttacked].lp -= cal((timeRatio * attackersIndex[_unitCurrentlyAttacked].lp) / DECIMALS); // "_unitCurrentlyAttacked" unit lp is just his lp * the time ratio because if the ratio were "1", he was killed
            }

        } else if (attackersIndex[_uniqueId].predictedDeathTime <= block.timestamp) {
            revert("Unit already dead");
        }

        attackers[_poolId].removeFromElement(_uniqueId);

        // reset values ..
        deployedUnitPerAddress[_poolId][msg.sender] = 0;
        currentAttackersNumber[_poolId]--;
        poolIdReference[_uniqueId] = 0;
    }

    // get current unit who the unit "_uniqueId" is attacking at timestamp "_timestamp"
    function getUnitAttackedForUniqueIdAndTimestamp(uint _poolId, uint _uniqueId, uint _timestamp) public view returns (uint attackingUnit) {
        // if the unit is currently fighting (or at least in the pool fight and not dead)
        if (attackersIndex[_uniqueId].fightEntry <= _timestamp && (attackersIndex[_uniqueId].predictedDeathTime > _timestamp || attackersIndex[_uniqueId].predictedDeathTime == 0)) {
            uint winningUnit = getWinningUnitFromTimestamp(_poolId, _timestamp); // get the current possesor of the fight pool at "_timestamp"

            if (winningUnit == _uniqueId) { // if "uniqueId" unit is possesing the pool, it can only be attacking the next attacker to arrive
                uint[] memory _areaFightPools;
                uint _id;

                (_areaFightPools, _id) = attackers[_poolId].getElementIndex(_uniqueId) ;

                
                for (uint i=_id; i < _areaFightPools.length - 1; i++) {
                    if (attackersIndex[_areaFightPools[i+1]].fightEntry <= _timestamp && attackersIndex[_areaFightPools[i+1]].predictedDeathTime > _timestamp) { // if the next attacker is fighting, it's the current unit attacked ..
                        attackingUnit = _areaFightPools[i+1];
                        break;
                    }
                }
            } else { // else, it is just in fight with the current pool possesor
                attackingUnit = winningUnit;
            }
        }
    }

    function getWinningUnitFromTimestamp(uint _poolId, uint _timestamp) public view returns (uint) {
        if (currentAttackersNumber[_poolId] == 0) {
            return 0;
        }
        uint[] memory _areaFightPools = attackers[_poolId].getWholeArray();
        uint fightTime = getFightTime(_poolId);

        for (uint n=0; n < _areaFightPools.length; n++) {
            if (n == 0 && attackersIndex[_areaFightPools[n]].fightEntry <= _timestamp && attackersIndex[_areaFightPools[n]].predictedDeathTime >= _timestamp) {
                return _areaFightPools[n]; 
            } 
            else if (attackersIndex[_areaFightPools[n]].fightEntry + fightTime <= _timestamp && (attackersIndex[_areaFightPools[n]].predictedDeathTime >= _timestamp || attackersIndex[_areaFightPools[n]].predictedDeathTime == 0)) {
                return _areaFightPools[n];
            }
        }
    } 

    // update attacker pool to remove dead attackers (at block.timestamp)
    function updateAttackerPool(uint _poolId) internal {        
        uint[] memory _areaFightPools = attackers[_poolId].getWholeArray();
        for (uint i=0; i < _areaFightPools.length; i++) {
            // if he is already dead
            if (attackersIndex[_areaFightPools[i]].predictedDeathTime < block.timestamp && attackersIndex[_areaFightPools[i]].predictedDeathTime != 0) {
                attackers[_poolId].removeFromElement(_areaFightPools[i]);
                currentAttackersNumber[_poolId]--;
            }
        }
    }

    function packUnit(uint _lpA, uint _dmgA, uint _lpB, uint _dmgB) public pure returns (uint, uint) {
        return (_lpA + _lpB, _dmgA + _dmgB);
    }

    function get() public view returns (uint[] memory) {
        return attackers[0].getWholeArray();
    }

    function cal(uint _a) public pure returns (uint) {
        return _a;
    }

    function _update(uint _poolId) public {
        updateAttackerPool(_poolId);

        uint[] memory _attackersUniqueIds = attackers[_poolId].getWholeArray();

        uint[] memory _lps = _getLpsFromUniqueIds(_attackersUniqueIds);

        uint fightTime = getFightTime(_poolId);

        uint time;

        uint deathScoreMainUnit; // death score of the main unit (territory unit who is always in the pool)
        uint deathScoreB;

        uint mainUnitLp = poolsIndex[_poolId].territoryUnit.lp; // lp of the main unit (territory unit who is always in the pool)

        for (uint i=1; i < _attackersUniqueIds.length; i++) {
            cal(i);
            uint _uniqueId = _attackersUniqueIds[i];

            // compute the "strenght" of each fighter
            deathScoreMainUnit = cal(mainUnitLp / attackersIndex[_uniqueId].dmg);
            deathScoreB = cal(_lps[i] / poolsIndex[_poolId].territoryUnit.dmg);

            // compute the death time and add the fight time
            time = cal(attackersIndex[_uniqueId].fightEntry) + fightTime;

            if (deathScoreB > deathScoreMainUnit) { // Attacker B win, the territory unit is given to B

                // reduce the lp of the unit who survive
                _lps[i] = cal(((DECIMALS - ((deathScoreMainUnit * DECIMALS) / (deathScoreB))) * _lps[i]) / DECIMALS);

                // log a lp changement into the 2 fighter contract
                //IWarfareUnit(unitReference[_uniqueId].contractReference).addDamageLog(unitReference[_uniqueId].tokenId, _lps[i], time);

                //ITerritoryUnit(poolsIndex[_poolId].territoryUnit.contractReference).packNewUnit(unitReference[_uniqueId].contractReference, unitReference[_uniqueId].tokenId, time);

                mainUnitLp = _lps[i];
                attackersIndex[_uniqueId].packedTime = time;
            } else { // territory unit win
                attackersIndex[_uniqueId].predictedDeathTime = time; // store the predicted death time value
                attackersIndex[_uniqueId].killedByTerritoryUnit = true;

                // reduce the lp of the unit who survive
                mainUnitLp = cal(((DECIMALS - ((deathScoreB * DECIMALS) / (deathScoreMainUnit))) * mainUnitLp) / DECIMALS);

                // log a lp changement into the 2 fighter contract
                //IWarfareUnit(unitReference[_uniqueId].contractReference).addDamageLog(unitReference[_uniqueId].tokenId, 0, time);
                //ITerritoryUnit(poolsIndex[_poolId].territoryUnit.contractReference).addDamageLog(poolsIndex[_poolId].territoryUnit.tokenId, mainUnitLp, time);
            }
            
            if (time > lastDeathTime[_poolId]) {
                lastDeathTime[_poolId] = time;
            }
        }
    }

    function getFightEntryElement(uint _fightEntry, uint _poolId) public view returns (bool, uint) {
        uint[] memory _areaFightPools = attackers[_poolId].getWholeArray();

        // not initialized, so the index doesn't matter
        if (_areaFightPools.length == 0) {
            return (true, 0);
        }

        for (uint i=0; i < _areaFightPools.length; i++) {
            if (i == 0 && attackersIndex[_areaFightPools[i]].fightEntry > _fightEntry) { // if the first element is higher than _fightEntry, we can place it directly as the first element
                return (false, _areaFightPools[i]);
            }
            if (i != (_areaFightPools.length - 1)) { // if we can have ("i+1")
                if (attackersIndex[_areaFightPools[i]].fightEntry <= _fightEntry && attackersIndex[_areaFightPools[i+1]].fightEntry >= _fightEntry) {
                    return (true, _areaFightPools[i]);
                }
            } else { // else, this is the last index, place it "before the last if it's smaller than the last
                if (attackersIndex[_areaFightPools[i]].fightEntry >= _fightEntry) {
                    return (false, _areaFightPools[i]);
                }
            }
        }
        // else, its index is the last index
        return (true, _areaFightPools[_areaFightPools.length-1]);
    }

    // return all "lp" value of a whole array
    function _getLpsFromUniqueIds(uint[] memory _attackersUniqueIds) public view returns (uint[] memory) {
        uint[] memory _lps = new uint[](_attackersUniqueIds.length);
        for (uint i=0; i < _attackersUniqueIds.length; i++) {
            _lps[i] = attackersIndex[_attackersUniqueIds[i]].lp;
        }
        return _lps;
    }

    function isDead(address _contractReference, uint _tokenIdReference, uint _timestamp) external view returns (bool) {
        uint _predictedDeathTime = attackersIndex[referenceTreeAttackers[_contractReference][_tokenIdReference]].predictedDeathTime;
        return (_predictedDeathTime < _timestamp);
    }

    function isFighting(address _contractReference, uint _tokenIdReference, uint _timestamp) external view returns (bool) {
        return (lastDeathTime[referenceTreeAttackers[_contractReference][_tokenIdReference]] != 0 && _timestamp < lastDeathTime[referenceTreeAttackers[_contractReference][_tokenIdReference]]);
    }

    // return 0 if this reference doesn't have death time (not initialized or won the fight)
    function getDeathTime(address _contractReference, uint _tokenIdReference) external view returns (uint) {
        return attackersIndex[referenceTreeAttackers[_contractReference][_tokenIdReference]].predictedDeathTime;
    }

    function getPoolId(address _contractReference, uint _tokenIdReference) public view returns (uint) {
        return poolIdReference[referenceTreeAttackers[_contractReference][_tokenIdReference]];
    }

    function getFightTime(uint _poolId) internal view returns (uint) {
        return poolsIndex[_poolId].territoryUnit.FIGHT_TIME;
    }
}