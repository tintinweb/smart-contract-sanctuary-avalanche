/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-30
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract MySmartContract {
    mapping(bytes32 => address) identifierToExchange;
    address owner;

    constructor() {
        owner = msg.sender;
    }

function mintIdentifier(string memory _string, address _exchange) public {
    bytes memory _stringBytes = bytes(_string);
    bytes32 _identifier = sha256(_stringBytes);
    require(msg.sender == owner, "Only the owner can mint identifiers");
    require(_exchange != address(0), "Invalid address passed as exchange contract");
        // Check if the identifier already exists in the mapping
    require(identifierToExchange[_identifier] == address(0), "Identifier already exists");
    identifierToExchange[_identifier] = _exchange;
}

function deleteIdentifier(string memory _string) public {
    bytes memory _stringBytes = bytes(_string);
    bytes32 _identifier = sha256(_stringBytes);
    require(msg.sender == owner, "Only the owner can delete identifiers");
    delete identifierToExchange[_identifier];
    }

function getExchange(string memory _string) public view returns (address) {
    bytes memory _stringBytes = bytes(_string);
    bytes32 _identifier = sha256(_stringBytes);
    return identifierToExchange[_identifier];
    }
  
}