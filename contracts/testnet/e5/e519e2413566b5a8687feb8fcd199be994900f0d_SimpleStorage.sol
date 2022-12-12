/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

// contracts are similar to classes in other programming languages
contract SimpleStorage {
    // boolean, uint, int, address, bytes
    uint256 favoriteNumber;

    People[] public people;

    mapping(string=>uint256) public nameToFavoriteNumber;

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public{
        favoriteNumber=_favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public{
        people.push(People({favoriteNumber: _favoriteNumber,name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}