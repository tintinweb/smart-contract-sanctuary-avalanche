/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TraitStorage {

    struct Trait {
        string name;
        string png;
    }

    mapping(uint8 => Trait) public traitData;

    function uploadTrait(uint8 traitId, Trait calldata trait) external {
         traitData[traitId] = Trait(
                trait.name,
                trait.png
         );
    }
}