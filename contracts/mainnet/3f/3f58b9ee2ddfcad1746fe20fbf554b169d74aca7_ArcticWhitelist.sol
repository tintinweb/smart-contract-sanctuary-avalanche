/**
 *Submitted for verification at snowtrace.io on 2022-02-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


contract ArcticWhitelist {

    uint16 public maxWhitelistedAddresses;

    mapping(address => bool) public whitelistedAddresses;

    uint16 public numAddressesWhitelisted;

    constructor(uint16 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses =  _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {

        require(!whitelistedAddresses[msg.sender], "You have already been whitelisted");

        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Address limit reached");
        
        whitelistedAddresses[msg.sender] = true;
        
        numAddressesWhitelisted += 1;
    }
}