/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-08
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;

library ModularArray {
    // useful to create array with undefined length and where it's possible to add an element at any index

    // use underlying element (type value of "element" can be change to use address or bytes for exemple)
    struct UnderlyingElement {
        uint element;
        uint index;
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

            _array.array[_nbIndex] = UnderlyingElement(_element, _nbIndex, true, lastElement.index, nextElement.index);

            lastElement.next = _nbIndex;
            nextElement.last = _nbIndex;
        } else {
            _array.firstIndex = _nbIndex;
            _array.array[_nbIndex] = UnderlyingElement(_element, _nbIndex, true, 0, 0);
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
                _array.array[_nbIndex] = UnderlyingElement(_element, _nbIndex, true, 0, nextElement.index);

                _array.firstIndex = _nbIndex;
                nextElement.last = _nbIndex;
            } else {
                _array.array[_nbIndex] = UnderlyingElement(_element, _nbIndex, true, lastElement.index, nextElement.index);
            
                lastElement.next = _nbIndex;
                nextElement.last = _nbIndex;
            }
        } else {
            _array.firstIndex = _nbIndex;
            _array.array[_nbIndex] = UnderlyingElement(_element, _nbIndex, true, 0, 0);
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
            lastElement.next = nextElement.index;
            nextElement.last = lastElement.index;
        }

        _array.totalElementsNumber--;
        element.index = 0;
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

    function getElementIndex(ModularArrayStruct storage _array, uint _element) internal view returns (uint) {
        uint[] memory array = getWholeArray(_array);
        for (uint i=0; i < array.length; i++) {
            if (array[i] == _element) return i;
        }
        return 0;
    }

    function resetArray(ModularArrayStruct storage _array) internal {
        _array.totalElementsNumber = 0;
    }
}

interface IWarfareUnit {
    function ownerOf(uint) external view returns (address);
}

contract WarfareUnitGameStatePredictionComponent {
    using ModularArray for ModularArray.ModularArrayStruct;

    // basic structur to store all important information about attackers necessary to make calculations
    struct Attacker {
        uint fightEntry;
        uint lp;
        
        uint[] targetsList;
        
        uint dmgPerSecond;
        
        uint predictedDeathTime;
    }

    // tempory / memory data type to avoid stack too deep during internal calculations
    struct AttackerTemporyData {
        uint[] _targetPosition;
        uint[] _cumulatedDamage;
        uint[] _deathTime;
        uint[] _lps;
    }

    uint uniqueId;
    mapping (uint => uint) public firstFightEntry; // first fight entry timestamp for every pools id
    mapping (uint => uint) public currentAttackersNumber; // current attackers number (in terms of different players, not units) for every pools id

    uint public MAX_UNITS_PER_OWNER = 10; // max number of different attackers in a single fight per address (packed attackers are counted as 1 unit)
    uint public MAX_ATTACKERS_OWNERS = 5; // max number of different attackers owners in a single fight

    mapping (uint => Attacker) public attackersIndex; // associate unique id to each attackers to handle them easily 
    mapping (address => mapping (uint => uint)) public referenceTreeAttackers; // reference for each attackers unique id from their nft contract address and then their token id (address => uint) 
    mapping (uint => uint) public poolIdReference; // reference each unique id to its current pool;
    mapping (uint => mapping (address => uint)) public deployedUnitPerAddress; // different attackers (non packed) amount in a single fight for each address and for each pool id

    mapping (uint => mapping (uint => uint)) public elementIndex; // current index for each element in the whole array of "attackers" (attackers.getWholeArray()) for each pool id
    mapping (uint => ModularArray.ModularArrayStruct) public attackers; // attackers list sorted by their fight entry (first entry <=> first index) for each pool id
    mapping (uint => uint) public lastDeathTime; // last death time for each pool

    constructor () {
        _addAttacker(0, address(0), 0, 0,400, new uint[](0), 3);
        _addAttacker(0, address(0), 0, 100,500, new uint[](0), 2);
        _addAttacker(0, address(0), 0, 200,500, new uint[](0), 1);
        _addAttacker(0, address(0), 0, 50,150, new uint[](0), 4);
        _addAttacker(0, address(0), 0, 400,970, new uint[](0), 2);
    }

    function _completeTargetList(uint _poolId, uint[] memory _targetList) internal view returns (uint[] memory) {
        uint[] memory attackersList = attackers[_poolId].getWholeArray();
        if (_targetList.length < attackersList.length) {
            uint[] memory completedTargetsList = new uint[](attackersList.length);

            for (uint i=_targetList.length; i < attackersList.length; i++) {
                completedTargetsList[i] = attackersList[i];
            }
            return completedTargetsList;
        }
        return _targetList;
    } 

    function addAttacker(uint _poolId, address _contractReference, uint _tokenIdReference, uint _fightEntry, uint _lp, uint[] memory _targetsList, uint _dmgPerSecond) public returns (uint _id) {
        _id = _addAttacker(_poolId, _contractReference, _tokenIdReference, _fightEntry, _lp, _targetsList, _dmgPerSecond);
        _update(_poolId);
    }

    function addAttackers(uint _poolId, address[] memory _contractReference, uint[] memory _tokenIdReference, uint[] memory _fightEntry, uint[] memory _lp, uint[][] memory _targetsList, uint[] memory _dmgPerSecond) public returns (uint[] memory) {
        uint[] memory _id = new uint[](_contractReference.length);
        for (uint n=0; n < _contractReference.length; n++) {
            _id[n] = _addAttacker(_poolId, _contractReference[n], _tokenIdReference[n], _fightEntry[n], _lp[n], _targetsList[n], _dmgPerSecond[n]);
        }
        _update(_poolId);
        return _id;
    }

    function _addAttacker(uint _poolId, address _contractReference, uint _tokenIdReference, uint _fightEntry, uint _lp, uint[] memory _targetsList, uint _dmgPerSecond) internal returns (uint) {
        require(deployedUnitPerAddress[_poolId][msg.sender] + 1 <= MAX_UNITS_PER_OWNER, "max unit number reached");
        require(currentAttackersNumber[_poolId] + 1 <= MAX_ATTACKERS_OWNERS, "max commanders in this fight reached");
        
        if (_targetsList.length != 0) {
            _targetsList = _completeTargetList(_poolId, _targetsList);
        }

        // set the new Attacker object created from the input datas
        attackersIndex[uniqueId] = Attacker(_fightEntry, _lp, _targetsList, _dmgPerSecond, 0);

        // retreive the index and set at the rigth place the new element (in croissant fight entry order)
        (bool _addAfterElement, uint _element) = getFightEntryElement(_fightEntry, _poolId);
        if (_addAfterElement) attackers[_poolId].addAfterElement(_element, uniqueId);
        else attackers[_poolId].addBeforeElement(_element, uniqueId);

        // set the first timestamp fight entry
        if (firstFightEntry[_poolId] > _fightEntry || firstFightEntry[_poolId] == 0) firstFightEntry[_poolId] = _fightEntry;

        // set the reference of the attacker linked to its nft contract address and token id reference
        referenceTreeAttackers[_contractReference][_tokenIdReference] = uniqueId;

        poolIdReference[uniqueId] = _poolId;

        uniqueId++;
        deployedUnitPerAddress[_poolId][msg.sender]++;
        
        return uniqueId-1;
    }

    function removeAttacker(uint _poolId, address _contractReference, uint _tokenIdReference) public {
        _removeAttacker(_poolId, _contractReference, _tokenIdReference);
        _update(_poolId);
    }

    function removeAttackers(uint _poolId, address[] calldata _contractReference, uint[] calldata _tokenIdReference) public {
        for (uint n=0; n < _contractReference.length; n++) {
            _removeAttacker(_poolId, _contractReference[n], _tokenIdReference[n]);
        }
        _update(_poolId);
    }

    function _removeAttacker(uint _poolId, address _contractReference, uint _tokenIdReference) internal {
        require(getPoolId(_contractReference,_tokenIdReference) == _poolId, "wrong pool");
        
        uint _uniqueId = referenceTreeAttackers[_contractReference][_tokenIdReference];

        attackers[_poolId].removeFromElement(_uniqueId);

        // reset values ..
        referenceTreeAttackers[_contractReference][_tokenIdReference] = 0;
        deployedUnitPerAddress[_poolId][msg.sender]--;
        currentAttackersNumber[_poolId]--;
        poolIdReference[_uniqueId] = 0;
    }

    // update attacker pool to remove dead attackers (at block.timestamp), update element index (see in getTargetsFromIteration()) and replace firstFightEntry if necessary
    function updateAttackerPool(uint _poolId) internal {        
        uint[] memory _areaFightPools = attackers[_poolId].getWholeArray();
        uint _firstFightEntry;
        for (uint i=0; i < _areaFightPools.length; i++) {
            // if he is already dead
            if (attackersIndex[_areaFightPools[i]].predictedDeathTime < block.timestamp && attackersIndex[_areaFightPools[i]].predictedDeathTime != 0) {
                attackers[_poolId].removeFromElement(_areaFightPools[i]);
            // else, update firstFightEntry if necessary
            } else {
                if (_firstFightEntry > attackersIndex[_areaFightPools[i]].fightEntry || _firstFightEntry == 0) firstFightEntry[_poolId] = attackersIndex[_areaFightPools[i]].fightEntry;
            }
            elementIndex[_poolId][_areaFightPools[i]] = i;
        }
        firstFightEntry[_poolId] = _firstFightEntry;
    }

    function cal(uint _a) public pure returns (uint) { return _a; }

    function _update(uint _poolId) public returns (uint, uint) {
        updateAttackerPool(_poolId);

        // attackers unique ids only are > 0 (because initialized at 1); when an attacker is dead, his unique id is set to 0 (its avoid the creatin of another array)
        uint[] memory _attackersUniqueIds = attackers[_poolId].getWholeArray();

        // one data type to store others one to avoid stack too deep error
        AttackerTemporyData memory _data = AttackerTemporyData(
            new uint[](_attackersUniqueIds.length), 
            new uint[](_attackersUniqueIds.length),
            new uint[](_attackersUniqueIds.length),
            _getLpsFromUniqueIds(_attackersUniqueIds));

        uint _closestDeathTime; // closest death time computed (to kill the closest death time unique id)
        uint _closestDeathTimeAttackerIndex; // linked to closest death time to kill the closest death time attacker index
        
        // internal variable used for logistical calculation
        bool _attack;
        uint _targetId;

        uint time = firstFightEntry[_poolId];

        for (uint i=0; i < _attackersUniqueIds.length; i++) {

            // compute all the death time for each attackers
            for (uint n=0; n < _attackersUniqueIds.length; n++) {
                if (_data._lps[n] > 0) {
                    // retreive if attacker "n" can attack and if so, the target id of the attacked unit
                    (_attack, _targetId) = getTargetsFromIteration(_attackersUniqueIds[n], _data._targetPosition[n], _attackersUniqueIds, _poolId);

                    if (_attack) {
                        // compute all delta time between "time" and fight entry of the attacker, the targeted unit and then get the max of these two delta
                        uint _deltaTimeAttacker = cal(attackersIndex[_attackersUniqueIds[n]].fightEntry > time ? attackersIndex[_attackersUniqueIds[n]].fightEntry - time : 0);
                        uint _deltaTimeTargeted = cal(attackersIndex[_attackersUniqueIds[_targetId]].fightEntry > time ? attackersIndex[_attackersUniqueIds[_targetId]].fightEntry - time : 0);
                        uint _highestDeltaTime = cal(_deltaTimeAttacker > _deltaTimeTargeted ? _deltaTimeAttacker : _deltaTimeTargeted);
                        
                        cal(_data._lps[_targetId]);

                        if (cal(_data._deathTime[_targetId]) == 0) { // if there is no death time predicted ..
                            _data._deathTime[_targetId] = cal((_data._lps[_targetId] / attackersIndex[_attackersUniqueIds[n]].dmgPerSecond) + _highestDeltaTime);
                            _data._cumulatedDamage[_targetId] += cal(attackersIndex[_attackersUniqueIds[n]].dmgPerSecond);
                        } else {
                            // if the assailled unit death time is under the max figth entry, go to the next attacker
                            if (_highestDeltaTime >= _data._deathTime[_targetId]) {
                                continue;
                            }
                            _data._cumulatedDamage[_targetId] += cal(attackersIndex[_attackersUniqueIds[n]].dmgPerSecond);
                            _data._deathTime[_targetId] = cal(((_data._deathTime[_targetId] - _deltaTimeAttacker) / _data._cumulatedDamage[_targetId]) + (_deltaTimeAttacker));
                        }

                        // replace the closest death time by this one if it's the smallest value
                        if (_data._deathTime[_targetId] < _closestDeathTime || _closestDeathTime == 0) {
                            _closestDeathTime = cal(_data._deathTime[_targetId]);
                            _closestDeathTimeAttackerIndex = cal(_targetId);
                        }

                    }
                }
            }

            // kill the attacker who have the closest death time and add the time to the kill to "time"
            _data._lps[cal(_closestDeathTimeAttackerIndex)] = 0;
            time += cal(_closestDeathTime);
            attackersIndex[cal(_attackersUniqueIds[_closestDeathTimeAttackerIndex])].predictedDeathTime = time; // store the predicted death time value

            if (i == _attackersUniqueIds.length - 2) {
                lastDeathTime[_poolId] = time;
            }

            // remove lp for all the attacked unit (but not dead yet)
            { // avoid stack too deep
            uint _dmg;
            for (uint n=0; n < _attackersUniqueIds.length; n++) {
                uint _entry = attackersIndex[_attackersUniqueIds[n]].fightEntry;
                if (_entry <= time) { // if this unit may have received damage (entered the fight before the closest death time added above (and already added to "time"))
                    _dmg = (time - _entry) * _data._cumulatedDamage[n];
                    if (_dmg < _data._lps[n]) {
                        _data._lps[n] -= cal(_dmg);
                    } else _data._lps[n] = 0;
                }

                _data._cumulatedDamage[n] = 0;
                _data._deathTime[n] = 0;
            }
            }

            // add 1 to target position of all the attackers who had the killed unit as target
            for (uint n=0; n < _attackersUniqueIds.length; n++) {
                (_attack, _targetId) = getTargetsFromIteration(_attackersUniqueIds[n], _data._targetPosition[n], _attackersUniqueIds, _poolId);
                if (_data._lps[_targetId] == 0 && _attack) {
                    _data._targetPosition[n] += 1;
                }
            }

            // reset cloest death time and attacker index for the next iteration
            _closestDeathTime = 0;
            _closestDeathTimeAttackerIndex = 0;
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

    // return the target of "_uniqueId" at the iteration "_i" (uint) and if he is attacking (bool)
    function getTargetsFromIteration(uint _uniqueId, uint _i, uint[] memory _attackersUniqueIds, uint _poolId) public view returns (bool, uint) {
        if (attackersIndex[_uniqueId].targetsList.length != 0) {
            if (attackersIndex[_uniqueId].targetsList.length-1 >= _i) {
                return (true, attackersIndex[_uniqueId].targetsList[_i]);
            } else {
                return (false, 0);
            }
        } else {
            if (_attackersUniqueIds.length-1 >= _i) { 
                if (_attackersUniqueIds[_i] == _uniqueId) {
                    if (_attackersUniqueIds.length-1 > _i) {
                        return (true, _i+1);
                    } else {
                        return (false, 0);
                    }
                } else {
                    if (elementIndex[_poolId][_uniqueId] < _i) {
                        if (_attackersUniqueIds.length-1 > _i) {
                            return (true, _i+1);
                        } else {
                            return (false, 0);
                        }
                    } else {
                        return (true, _i);
                    }
                }
            } else {
                return (false, 0);
            }
        }
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

    function get(uint _poolId) public view returns (uint[] memory) {
        return attackers[_poolId].getWholeArray();
    }

}