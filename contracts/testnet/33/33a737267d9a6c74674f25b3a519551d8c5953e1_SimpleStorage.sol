/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SimpleStorage {

    uint256 currentYear= 2022;

    struct People {
        string name;
        uint256 birthYear;
    }

    People[] public peopleList;

    mapping(string => uint256) public nameToBirthYear;

    function addPerson(string memory _name,uint256 _birthYear) public {
        peopleList.push(People(_name,_birthYear));
        nameToBirthYear[_name] = _birthYear;
    }

    function changeCurrentYear(uint256 _newYear) public {
        currentYear=_newYear;
    }

    function getCurrentYear() public view returns(uint256) {
        return currentYear;
    }

    function getPersonAge(string memory _name) public view returns(uint256) {
        uint256 personAge = currentYear-nameToBirthYear[_name];
        return personAge;
    }

}