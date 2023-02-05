//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "soliditool/contracts/Utils.sol";

contract NamePicker {
    // Admin variables
    address public owner;
    address public admin;

    // The list of names
    string[] private names;

    // The number of names in the list
    uint public nameCount;

    // Only certain addresses can call certain functions
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == admin, "Only the owner or admin can call this function");
        _;
    }

    // Events emitted
    event nameAdded(string indexed name);
    event nameRemoved(string indexed name);
    event pickedNewRandomName(string indexed name);

    constructor() {
        owner = msg.sender;
        admin = 0x0FAd74EF878Ed65Dd40b71Ea586738DF94cF1360;
    }

    // Function to add a name to the list
    function addName(string memory _name) public onlyOwnerOrAdmin {
        names.push(_name);
        nameCount++;

        emit nameAdded(_name);
    }

    // Function to remove a name from the list
    //Use the findString function to check if a name exists inside the array
    function removeName(string memory _name) public onlyOwnerOrAdmin returns (bool) {
        uint index = Utils.findString(names, _name);
        require(index < names.length, "Name does not exists");

        for (uint i = index; i < names.length - 1; i++) {
            names[i] = names[i + 1];
        }
        names.pop();
        nameCount -= 1;
        emit nameRemoved(_name);
        return true;

    }

    // Count how many names are in the list
    function namesInArray() public view returns (uint) {
        return names.length;
    }

    // Function to pick a random name from the list
    function pickRandomName() public returns (string memory) {
        require(nameCount > 0, "Cannot pick a name from an empty list");
        uint randomIndex = Utils.pseudoRandom();
        string memory randomName = names[randomIndex % nameCount];
        emit pickedNewRandomName(randomName);
        return randomName;

        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
Soliditool v1.0.0— keep your code clean and streamlined import it at the top of your smart contract.

import "soliditool/contracts/Utils.sol";
 */


library Utils {

    /**
    Function to compare 2 strings
    Use the compareStrings function with 2 parameters, it will compare them and return a bool value.
    For example:
    compareStrings("blue", "red") will return false.
     */
    
    function compareStrings(string memory firstString, string memory secondString) internal pure returns (bool) {
        return keccak256(bytes(firstString)) == keccak256(bytes(secondString));
    }

    /**
    Function to generate a pseudo random number
    WARNING: This function does not return a real random value, this function is to be used for testing ONLY and not in production 
    where a real random number is needed.
     */
    function pseudoRandom() public view returns (uint) {
        bytes32 blockHash = blockhash(block.number - 1);
        return uint(keccak256(abi.encodePacked(block.timestamp, uint(blockHash))));
    }

    /**
    Function to find the index matching a string in an array
    This function takes a string as a parameter and loops through an array of strings. 
    It then returns the index of the matching string (if it exists), or the 420 code if it does not exist.
     */
    function findString(string[] memory array, string memory _string) internal pure returns (uint) {
        for (uint i = 0; i < array.length; i++) {
            string memory stringToFind = array[i];
            bool exists = Utils.compareStrings(stringToFind, _string);
            if (exists == true) {
                return i;
            }
        }
        return uint(420);
    }

   /**
    Function to find the index matching a uint in an array
    This function takes a uint as a parameter and loops through an array of uints. 
    It then returns the index of the matching uint (if it exists), or the 90909090 code if it does not exist.
     */
    function findUint(uint[] memory array, uint _number) internal pure returns (uint) {
        for (uint i = 0; i < array.length; i++) {
            uint uintToFind = array[i];
            if (_number == uintToFind) {
                return i;
            }
        }
        return uint(90909090);
    }

    /**
    Function to find the index matching a int in an array
    This function takes a int as a parameter and loops through an array of ints. 
    It then returns the index of the matching int (if it exists), or the 90909090 code if it does not exist.
     */
    function findInt(int[] memory array, int _number) internal pure returns (uint) {
        for (uint i = 0; i < array.length; i++) {
            int intToFind = array[i];
            if (_number == intToFind) {
                return i;
            }
        }
        return uint(90909090);
    }
}