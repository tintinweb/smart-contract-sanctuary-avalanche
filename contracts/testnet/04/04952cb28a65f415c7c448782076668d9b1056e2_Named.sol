/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-18
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract Named {
    string public name;

    function setName(string memory _name) public {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }
    
}