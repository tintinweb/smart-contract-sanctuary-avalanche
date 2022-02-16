/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;

contract MappingManagementComponent {
    
    enum RegionType {
        FOREST,
        DEEP_FOREST,
        MOUNTAIN,
        PLAIN,
        LAKE
    }

    struct Region {
        bool init;

        // REGION REFERENCE

        address _contract;
        uint referenceId;

        // BASIC STATS

        RegionType _type;
        uint cellCount;
        uint[] cellsId; // pool id in game state prediction

        // TERRITORY UNIT

        uint[] territoryUnitCellsId; // pool id in game state prediction

        // BONUS

        uint speedBoost; // base 10000
    }

    struct TerritoryUnitRef {
        address _contractRef;
        uint _tokenId;
    }

    uint public totalCells;
    uint public totalRegions;

    mapping (uint => Region) public regionMapping; // all regions are mapped from their id in this contract to their reference stat
    mapping (uint => uint) public cellMapping; // all regions are mapped
    mapping (uint => TerritoryUnitRef) public territoryUnitCells; // map all cells id to territory unit ref

    constructor (uint[] memory _a, bool[] memory _b, address _ref) {
        addRegion(0xd9145CCE52D386f254917e481eB44e9943F39138, 0, 0, 0);
        // [0,1,2] [true,true,true]
        addCellsToRegion(_a, _b, 0);

        setTerritoryUnitRef(0, _ref, 0);
        setTerritoryUnitRef(1, _ref, 1);
        setTerritoryUnitRef(2, _ref, 2);
    }

    function addRegion(address _contract, uint _referenceId, uint _type, uint _speedBoost) public returns (uint) {
        regionMapping[totalRegions] = Region(true, _contract, _referenceId, RegionType(_type), 0, new uint[](0), new uint[](0), _speedBoost);
        
        totalRegions++;
        return totalRegions-1;
    }

    function removeRegion(uint _regionId) external {
        require(regionMapping[_regionId].init, "region not initialized");

        delete(regionMapping[totalRegions]);
        
        totalRegions--;
    }

    function addCellsToRegion(uint[] memory _cellsId, bool[] memory _isTerritory, uint _regionId) public {
        require(_cellsId.length == _isTerritory.length);
        require(regionMapping[_regionId].init, "region not initialized");

        for (uint i=0; i < _cellsId.length; i++) {
            cellMapping[totalCells] = _regionId;
            totalCells++;
            regionMapping[_regionId].cellsId.push(_cellsId[i]);
            if (_isTerritory[i]) regionMapping[_regionId].territoryUnitCellsId.push(_cellsId[i]);
        }

        regionMapping[_regionId].cellCount += _cellsId.length;
    }

    function setTerritoryUnitRef(uint _cellId, address _contractRef, uint _tokenIdRef) public {
        territoryUnitCells[_cellId] = TerritoryUnitRef(_contractRef, _tokenIdRef);
    }

    /**
        @param _cellsIndex is the index of each cell to remove in the cellsId in the region
     */
    function removeBasicCellsFromRegion(uint[] calldata _cellsIndex, uint _regionId) external {
        require(regionMapping[_regionId].init, "region not initialized");

        for (uint i=0; i < _cellsIndex.length; i++) {
            regionMapping[_regionId].cellsId[_cellsIndex[i]] = regionMapping[_regionId].cellsId[regionMapping[_regionId].cellsId.length - 1];
            regionMapping[_regionId].cellsId.pop();
        }
        
        totalCells -= _cellsIndex.length;
        regionMapping[_regionId].cellCount -= _cellsIndex.length;
    }

    /**
        @param _cellsIndex is the index of each cell to remove in the territoryUnitCellsId in the region
     */
    function removeTerritoryUnitCellsFromRegion(uint[] calldata _cellsIndex, uint _regionId) external {
        require(regionMapping[_regionId].init, "region not initialized");

        for (uint i=0; i < _cellsIndex.length; i++) {
            regionMapping[_regionId].territoryUnitCellsId[_cellsIndex[i]] = regionMapping[_regionId].territoryUnitCellsId[regionMapping[_regionId].territoryUnitCellsId.length - 1];
            regionMapping[_regionId].territoryUnitCellsId.pop();
        }
        
        totalCells -= _cellsIndex.length;
        regionMapping[_regionId].cellCount -= _cellsIndex.length;
    }

    function getRegionIdFromCellId(uint _cellId) external view returns (uint) {
        return cellMapping[_cellId];
    }

    function getTerritoryUnitCellsFromRegion(uint _regionId) external view returns (uint[] memory) {
        return regionMapping[_regionId].territoryUnitCellsId;
    }

    function getTerritoryUnitRefFromCellsId(uint _cellId) external view returns (address, uint) {
        return (territoryUnitCells[_cellId]._contractRef, territoryUnitCells[_cellId]._tokenId);
    }

    function getCellBonus(uint _cellId) external view returns (uint) {
        return regionMapping[cellMapping[_cellId]].speedBoost;
    }
}

contract TUBasicCastle {

    /* 
        basic stats for each token id
        /!/ each stat is the initial state and can be modified without changing here
    */
    struct initialStats {
        uint lp;
        uint dmg;
        uint healingPerSec;
        uint fightTime;
    }

    struct statLog {
        uint timestamp;
        uint lp;
        uint dmg;
    }

    mapping (uint => initialStats) public tokenIdStats; // mapping of all stats for each token id

    mapping (uint => uint[]) public _ownersLog; // every timestamp change of owners
    mapping (uint => mapping (uint => address)) public _ownersTimestampLog; // associate for each token id, each timestamp log, an owner address

    mapping (uint => uint[]) public _statsLog; // every timestamp change of stats
    mapping (uint => mapping (uint => statLog)) public _statsTimestampLog; // associate for each token id, each timestamp log, a stat struct

    mapping (uint => address) public baseOwner; // base owner for each token id
    mapping (uint => statLog) public baseStats; // base stats for each token id

    uint public totalUnit;


    constructor () {
        addNewOwnerChangeLog(0, 0x11a9263cF30a098ba360db39b4EEd8B45f8a25df, 100);
        addNewOwnerChangeLog(1, 0x11a9263cF30a098ba360db39b4EEd8B45f8a25df, 150);
        addNewOwnerChangeLog(2, 0x487C050eabeC9e1bB522F52468B7eAF901007316, 130);
    }

    function mint(address _to, uint _lp, uint _dmg, uint _healingPerSec, uint _fightTime) external {
        tokenIdStats[totalUnit] = initialStats(_lp, _dmg, _healingPerSec, _fightTime);
        baseOwner[totalUnit] = _to;
        baseStats[totalUnit] = statLog(block.timestamp, _lp, _dmg);

        totalUnit++;
    }

    function resetPassedLog(uint _tokenId) public {
        uint maxTimestamp;
        uint offset;
        uint arrayLength = _ownersLog[_tokenId].length;

        {
        uint[] storage _ownerslogs = _ownersLog[_tokenId];
        address maxTimestampValue;
        
        for (uint i=0; i < arrayLength; i++) {
            uint _i = i - offset;
            if (_ownerslogs[_i] <= block.timestamp) {
                if (_ownerslogs[_i] > maxTimestamp) {
                    maxTimestampValue = _ownersTimestampLog[_tokenId][_ownerslogs[_i]];
                    maxTimestamp = _ownerslogs[_i];
                }

                _ownerslogs[_i] = _ownerslogs[_ownerslogs.length-1];
                _ownerslogs.pop();
                offset += 1;
            }
        }

        if (_ownerslogs.length == arrayLength - offset) {
            _ownerslogs.push(maxTimestamp);
            _ownersTimestampLog[_tokenId][maxTimestamp] = maxTimestampValue;
        }
        }

        maxTimestamp = 0;
        offset = 0;
        
        uint[] storage _statslogs = _statsLog[_tokenId];
        statLog memory _maxTimestampValue;
        arrayLength = _statslogs.length;

        for (uint i=0; i < arrayLength; i++) {
            uint _i = i - offset;
            if (_statslogs[_i] <= block.timestamp) {
                if (_statslogs[_i] > maxTimestamp) {
                    _maxTimestampValue = _statsTimestampLog[_tokenId][_statslogs[_i]];
                    maxTimestamp = _statslogs[_i];
                }

                _statslogs[_i] = _statslogs[_statslogs.length-1];
                _statslogs.pop();
                offset += 1;
            }
        }

        if (_statslogs.length == arrayLength - offset) {
            _statslogs.push(maxTimestamp);
            _statsTimestampLog[_tokenId][maxTimestamp] = _maxTimestampValue;
        }

    }

    function getOwnerFromTimestamp(uint _tokenId, uint _timestamp) public view returns (address) {
        if (_ownersLog[_tokenId].length == 0)
            return address(0);
        else if (_ownersLog[_tokenId].length == 1)
            return _ownersTimestampLog[_tokenId][_ownersLog[_tokenId][0]];
        uint maxTimestamp;
        for (uint i=0; i < _ownersLog[_tokenId].length; i++) {
            if (_ownersLog[_tokenId][i] < _timestamp && (_ownersLog[_tokenId][i] > maxTimestamp || maxTimestamp == 0)) {
                maxTimestamp = _ownersLog[_tokenId][i];
            }
        }

        return _ownersTimestampLog[_tokenId][maxTimestamp];
    }

    function getOwner(uint _tokenId) external view returns (address) {
        return getOwnerFromTimestamp(_tokenId, block.timestamp);
    }

    function getUnitLpFromTimestamp(uint _tokenId, uint _timestamp) public view returns (uint) {
        if (_statsLog[_tokenId].length == 0) {
            return getLpWithHealing(_tokenId, baseStats[_tokenId].timestamp, _timestamp, baseStats[_tokenId].lp);
        } else {
            uint maxTimestamp;
            for (uint i=0; i < _statsLog[_tokenId].length; i++) {
                if (_statsLog[_tokenId][i] < _timestamp && (_statsLog[_tokenId][i] > maxTimestamp || maxTimestamp == 0)) {
                    maxTimestamp = _statsLog[_tokenId][i];
                }
            }

            return getLpWithHealing(_tokenId, maxTimestamp, _timestamp, _statsTimestampLog[_tokenId][maxTimestamp].lp);
        }
    }

    function getUnitLp(uint _tokenId) external view returns (uint) {
        return getUnitLpFromTimestamp(_tokenId, block.timestamp);
    }

    function getLpWithHealing(uint _tokenId, uint _timestampA, uint _timestampB, uint _baseLp) public view returns (uint) {
        if (_baseLp != tokenIdStats[_tokenId].lp) {
            require(_timestampA < _timestampB);
            uint totalHealed = tokenIdStats[_tokenId].healingPerSec * (_timestampA - _timestampB);
            if (_baseLp + totalHealed >= tokenIdStats[_tokenId].lp)
                return tokenIdStats[_tokenId].lp;
            else
                return _baseLp + totalHealed;
        } else return _baseLp;
    }

    function addNewOwnerChangeLog(uint _tokenId, address _newOwner, uint _timestamp) public {
        _ownersLog[_tokenId].push(_timestamp);
        _ownersTimestampLog[_tokenId][_timestamp] = _newOwner;
    }

    function addStatsLog(uint _tokenId, uint _lp, uint _dmg, uint _timestamp) external {
        _statsLog[_tokenId].push(_timestamp);
        _statsTimestampLog[_tokenId][_timestamp] = statLog(_timestamp, _lp, _dmg);
    }
}

interface IMappingManagerComponent {
    function getTerritoryUnitCellsFromRegion(uint _regionId) external view returns (uint[] memory);
    function getTerritoryUnitRefFromCellsId(uint _cellId) external view returns (address, uint);
}

interface ITerritoryUnit {
    function getOwner(uint _tokenId) external view returns (address);
}

contract RegionCore {

    uint public minted;

    enum Status {
        CONTROLLED, // everything is controlled by one address
        TEAM_CONTROLLED, // everything is controlled with some alliance members
        NOT_FULLY_CONTROLLED, // there are some neutral territories units ..
        CONTROLLED_UNDER_CONFLICT, // there are some enemy territories units ..
        WAR_ZONE, // every enemies have the same number of territories units
        NEUTRAL // fully neutral
    }

    IMappingManagerComponent public mappingManagerContract;

    mapping (uint => mapping (uint => uint)) public territoryUnit; // Mapping from region nft id (tokenId) to all its territory units global ids indexed (ex : 0 => 1232, 1 => 204)

    constructor(address _mappingManagerContract) {
        mappingManagerContract = IMappingManagerComponent(_mappingManagerContract);
    }

    function cal(uint _a) public pure returns (uint) {
        return _a;
    }

    function cal2(address _a) public pure returns (address) {
        return _a;
    }

    function ownerOf(uint _regionId) external returns (address) {
        uint[] memory _territoryUnits = mappingManagerContract.getTerritoryUnitCellsFromRegion(_regionId);

        uint unitToOwn = cal((_territoryUnits.length / 2) + 1);
        uint totalUnit = cal(_territoryUnits.length);
        uint totalDistinctOwner;

        uint maxOwn;
        address addrMaxOwn;

        address[] memory _unitOwners = new address[](totalUnit);
        address[] memory _distinctOwners = new address[](totalUnit);
        uint[] memory _distinctOwnersValue = new uint[](totalUnit);

        for (uint i=0; i < totalUnit; i++) {
            (address _addressRef, uint _tokenId) = mappingManagerContract.getTerritoryUnitRefFromCellsId(_territoryUnits[i]);
            address _owner = cal2(ITerritoryUnit(_addressRef).getOwner(_tokenId));

            for (uint n=0; n < totalUnit; n++) {
                if (cal2(_unitOwners[n]) == _owner) {
                    break;
                } else if (n == totalUnit - 1) {
                    _distinctOwners[totalDistinctOwner] = _owner;
                    _distinctOwnersValue[totalDistinctOwner] += 1;

                    if (cal(_distinctOwnersValue[totalDistinctOwner]) > cal(maxOwn)) {
                        maxOwn = cal(_distinctOwnersValue[totalDistinctOwner]);
                        addrMaxOwn = cal2(_owner);
                    }

                    totalDistinctOwner += 1;
                }
            }

            _unitOwners[i] = cal2(_owner);
        }

        if (cal(maxOwn) >= cal(unitToOwn)) return addrMaxOwn;
        else return address(0);
    }
}