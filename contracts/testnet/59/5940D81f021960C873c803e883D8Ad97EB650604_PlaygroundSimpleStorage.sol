/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // comment

// contract SimpleStorage {
//     // boolean, uint, int, string, address, bytes
//     bool hasFavoriteNumber = true;
//     uint256 favoriteNumber = 5;
//     string favoriteNumberInText = "Five";
//     int256 favoriteInt = -5;
//     address myAddress = 0x3F81e3a202746d00061748F2b73dC33e743d7488;
//     bytes32 favoriteBytes = "cat"; // 0x...follow by whole host of numbers.
// }

contract PlaygroundSimpleStorage {
    // automatically initialized with the value 0. werid I know.
    uint256 favoriteNumber; 

    mapping(uint256 => string) public numberToString;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //uint256[] public favoriteNumberList;
    People[] public people;


    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        // if a view function is called within here, it would also cost extra gas. e.g. retreieve() below.
        // (Because this function changes a state/storage of the contract.
        // Apparently comments don't cost extra gas.
    }

    // view, pure (no modification of state)
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        numberToString[_favoriteNumber] = _name;
    }

    function addOne() public {
        favoriteNumber = favoriteNumber + 1;
    }
}