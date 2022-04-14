/**
 *Submitted for verification at snowtrace.io on 2022-04-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract HotPotato {
    address[] public hotPotatoHolders;

    constructor() {
        hotPotatoHolders.push(msg.sender);
    }

    function passPotato() public {
        require(whoIsHoldingThePotato() != msg.sender, "Can't pass to yourself");
        hotPotatoHolders.push(msg.sender);
    }

    function whoIsHoldingThePotato() public view returns (address) {
        //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 - 0
        //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 - 1
        //0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db - 2
        return hotPotatoHolders[hotPotatoHolders.length - 1];
    }
}