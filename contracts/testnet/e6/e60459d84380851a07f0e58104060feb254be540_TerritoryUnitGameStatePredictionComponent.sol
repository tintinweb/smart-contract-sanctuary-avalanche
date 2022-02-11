/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-10
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

contract TerritoryUnitGameStatePredictionComponent {
    using ModularArray for ModularArray.ModularArrayStruct;

    // basic structur to store all important information about attackers necessary to make calculations
    struct Attacker {
        uint fightEntry;

        uint lp;
        uint dmg;
        
        uint predictedDeathTime;
        uint killedByUniqueId;
    }

    uint uniqueId = 1;
    mapping (uint => uint) public firstFightEntry; // first fight entry timestamp for every pools id
    mapping (uint => uint) public currentAttackersNumber; // current attackers number (in terms of different players, not units) for every pools id

    uint public MAX_UNITS_PER_OWNER = 15; // max number of different attackers in a single fight per address (packed attackers are counted as 1 unit)
    uint public MAX_ATTACKERS_OWNERS = 20; // max number of different attackers owners in a single fight

    mapping (uint => Attacker) public attackersIndex; // associate unique id to each attackers to handle them easily 
    mapping (address => mapping (uint => uint)) public referenceTreeAttackers; // reference for each attackers unique id from their nft contract address and then their token id (address => uint) 
    mapping (uint => uint) public poolIdReference; // reference each unique id to its current pool;
    mapping (uint => mapping (address => uint)) public deployedUnitPerAddress; // different attackers (non packed) amount in a single fight for each address and for each pool id

    mapping (uint => mapping (uint => uint)) public elementIndex; // current index for each element in the whole array of "attackers" (attackers.getWholeArray()) for each pool id
    mapping (uint => ModularArray.ModularArrayStruct) public attackers; // attackers list sorted by their fight entry (first entry <=> first index) for each pool id
    mapping (uint => uint) public lastDeathTime; // last death time for each pool

    mapping (uint => uint) public finalPoolPossesor;

    uint private DECIMALS = 10000;

    constructor () {
        _addAttacker(0, address(0), 0, block.timestamp + 0, 100, 2);
        _addAttacker(0, address(0), 0, block.timestamp + 100, 150, 3);
    }

    function _addAttacker(uint _poolId, address _contractReference, uint _tokenIdReference, uint _fightEntry, uint _lp, uint _dmg) public returns (uint) {
        require(deployedUnitPerAddress[_poolId][msg.sender] + 1 <= MAX_UNITS_PER_OWNER, "max unit number reached");
        require(currentAttackersNumber[_poolId] + 1 <= MAX_ATTACKERS_OWNERS, "max commanders in this fight reached");
        
        // set the new Attacker object created from the input datas
        attackersIndex[uniqueId] = Attacker(_fightEntry, _lp, _dmg, 0, 0);
        
        if (currentAttackersNumber[_poolId] > 0) {
            // retreive the index and set at the rigth place the new element (in croissant fight entry order)
            (bool _addAfterElement, uint _element) = getFightEntryElement(_fightEntry, _poolId);
            if (_addAfterElement) attackers[_poolId].addAfterElement(_element, uniqueId);
            else attackers[_poolId].addBeforeElement(_element, uniqueId);
        } else {
            finalPoolPossesor[_poolId] = uniqueId;
        }

        // set the first timestamp fight entry
        if (firstFightEntry[_poolId] > _fightEntry || firstFightEntry[_poolId] == 0) firstFightEntry[_poolId] = _fightEntry;

        // set the reference of the attacker linked to its nft contract address and token id reference
        referenceTreeAttackers[_contractReference][_tokenIdReference] = uniqueId;

        poolIdReference[uniqueId] = _poolId;

        uniqueId++;
        deployedUnitPerAddress[_poolId][msg.sender]++;
        currentAttackersNumber[_poolId]++;

        return uniqueId-1;
    }

    function _removeAttacker(uint _poolId, address _contractReference, uint _tokenIdReference) public {
        require(getPoolId(_contractReference,_tokenIdReference) == _poolId, "wrong pool");
        
        uint _uniqueId = referenceTreeAttackers[_contractReference][_tokenIdReference];

        attackers[_poolId].removeFromElement(_uniqueId);

        // reset values ..
        referenceTreeAttackers[_contractReference][_tokenIdReference] = 0;
        deployedUnitPerAddress[_poolId][msg.sender]--;
        currentAttackersNumber[_poolId]--;
        poolIdReference[_uniqueId] = 0;
    }

    function getWinningUnitFromTimestamp(uint _poolId, uint _timestamp) public view returns (uint) {
        uint[] memory _areaFightPools = attackers[_poolId].getWholeArray();

        uint lastIndex;
        uint lastTimestamp;
        for (uint n=0; n < _areaFightPools.length; n++) {
            if (attackersIndex[_areaFightPools[n]].predictedDeathTime > lastTimestamp && attackersIndex[_areaFightPools[n]].predictedDeathTime <= _timestamp) {
                lastTimestamp = attackersIndex[_areaFightPools[n]].predictedDeathTime;
                lastIndex = _areaFightPools[n];
            }
        }

        if (lastTimestamp == 0) {
            return finalPoolPossesor[_poolId];
        } else {
            return attackersIndex[lastIndex].killedByUniqueId;
        }
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

    function get() public view returns (uint[] memory) {
        return attackers[0].getWholeArray();
    }

    function _update(uint _poolId) public {
        updateAttackerPool(_poolId);

        // attackers unique ids only are > 0 (because initialized at 1); when an attacker is dead, his unique id is set to 0 (its avoid the creatin of another array)
        uint[] memory _attackersUniqueIds = attackers[_poolId].getWholeArray();

        uint[] memory _lps = _getLpsFromUniqueIds(_attackersUniqueIds);

        uint time;

        uint deathScoreA;
        uint deathScoreB;

        uint finalPoolPossesorLp = attackersIndex[finalPoolPossesor[_poolId]].lp;

        for (uint i=0; i < _attackersUniqueIds.length; i++) {

            
            deathScoreA = finalPoolPossesorLp / attackersIndex[_attackersUniqueIds[i]].dmg;
            deathScoreB = _lps[_attackersUniqueIds[i]] / attackersIndex[finalPoolPossesor[_poolId]].dmg;

            time = attackersIndex[_attackersUniqueIds[i]].fightEntry;

            if (deathScoreB > deathScoreA) { // Attacker B win
                attackersIndex[finalPoolPossesor[_poolId]].predictedDeathTime = time; // store the predicted death time value

                _lps[_attackersUniqueIds[i]] -= ((DECIMALS - ((deathScoreA * DECIMALS) / (deathScoreB * DECIMALS))) * _lps[_attackersUniqueIds[i]]) / DECIMALS;
                finalPoolPossesor[_poolId] = _attackersUniqueIds[i]; // update the final pool possesor (at this moment)
                finalPoolPossesorLp = _lps[_attackersUniqueIds[i]];
            } else if (deathScoreB < deathScoreA) { // Attacker A win
                attackersIndex[_attackersUniqueIds[i]].predictedDeathTime = time; // store the predicted death time value

                finalPoolPossesorLp -= ((DECIMALS - ((deathScoreA * DECIMALS) / (deathScoreB * DECIMALS))) * finalPoolPossesorLp) / DECIMALS;
            } else { // both loose
                attackersIndex[finalPoolPossesor[_poolId]].predictedDeathTime = time; // store the predicted death time value
                attackersIndex[_attackersUniqueIds[i]].predictedDeathTime = time; // store the predicted death time value

                finalPoolPossesor[_poolId] = 0; // nobody got the pool
                finalPoolPossesorLp = 0;
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
}