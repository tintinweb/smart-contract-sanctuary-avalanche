/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.11;


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


    function mint(address _to, uint _lp, uint _dmg, uint _healingPerSec, uint _fightTime) external {
        tokenIdStats[totalUnit] = initialStats(_lp, _dmg, _healingPerSec, _fightTime);
        baseOwner[totalUnit] = _to;
        baseStats[totalUnit] = statLog(block.timestamp, _lp, _dmg);

        totalUnit++;
    }

    function get() public view returns (uint[] memory) {
        return _ownersLog[0];
    }

    function cal(uint _a) public pure returns (uint) {
        return _a;
    }

    function cal2(address _a) public pure returns (address) {
        return _a;
    }

    function resetPassedLog(uint _tokenId) public {
        uint maxTimestamp;
        for (uint i=0; i < _ownersLog[_tokenId].length; i++) {
            cal(i);
            if (cal(_ownersLog[_tokenId][i]) <= block.timestamp) {

                if (cal(_ownersLog[_tokenId][i]) > cal(maxTimestamp)) {
                    baseOwner[_tokenId] = cal2(_ownersTimestampLog[_tokenId][_ownersLog[_tokenId][i]]);
                    maxTimestamp = cal(_ownersLog[_tokenId][i]);
                }

                _ownersLog[_tokenId][i] = cal(_ownersLog[_tokenId][_ownersLog[_tokenId].length-1]);
                _ownersLog[_tokenId].pop();
            }
        }

        maxTimestamp = 0;
        for (uint i=0; i < _statsLog[_tokenId].length; i++) {
            if (_statsLog[_tokenId][i] <= block.timestamp) {

                if (_statsLog[_tokenId][i] > maxTimestamp) {
                    baseStats[_tokenId] = _statsTimestampLog[_tokenId][_statsLog[_tokenId][i]];
                    maxTimestamp = _statsLog[_tokenId][i];
                }

                _statsLog[_tokenId][i] = _statsLog[_tokenId][_statsLog[_tokenId].length-1];
                _statsLog[_tokenId].pop();
            }
        }
    }

    function getOwnerFromTimestamp(uint _tokenId, uint _timestamp) public view returns (address) {
        if (_ownersLog[_tokenId].length == 0) {
            return baseOwner[_tokenId];
        } else {
            uint maxTimestamp;
            for (uint i=0; i < _ownersLog[_tokenId].length; i++) {
                if (_ownersLog[_tokenId][i] < _timestamp && (_ownersLog[_tokenId][i] > maxTimestamp || maxTimestamp == 0)) {
                    maxTimestamp = _ownersLog[_tokenId][i];
                }
            }

            return _ownersTimestampLog[_tokenId][maxTimestamp];
        }
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

    function addNewOwnerChangeLog(uint _tokenId, address _newOwner, uint _timestamp) external {
        _ownersLog[_tokenId].push(_timestamp);
        _ownersTimestampLog[_tokenId][_timestamp] = _newOwner;
    }

    function addStatsLog(uint _tokenId, uint _lp, uint _dmg, uint _timestamp) external {
        _statsLog[_tokenId].push(_timestamp);
        _statsTimestampLog[_tokenId][_timestamp] = statLog(_timestamp, _lp, _dmg);
    }
}