/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MyContract {
    string private value;

    function getValue() public view returns (string memory){
        return value;
    }

    function setValue(string memory _value) public {
        value = _value;
    }
}