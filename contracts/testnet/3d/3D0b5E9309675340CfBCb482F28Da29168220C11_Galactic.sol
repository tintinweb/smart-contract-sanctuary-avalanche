/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Galactic {
    // name it: spaceship generated?
    // todo: earth address for some reason is hashed
    event NonceGenerated(
        string indexed earthAddress, address indexed moonAddress,  uint indexed purposeIdx,  uint networkIdx, uint256 fare);

    string[] purposes; 
    string[] networks;

    uint constant numDecimals = 9;
    uint baseFee = 10;

    
    //  todo make the following onlyOwner
    function addPurpose(string memory newPurpose) public {
        purposes.push(newPurpose);
    }

    function updateFee(uint newFee) public {
        baseFee = newFee;
    }

    function addNetwork(string memory network) public {
        networks.push(network);
    }

    function getNetworks() public view returns (string[] memory) {
        return networks;
    }

    function getPurposes() public view returns (string[] memory) {
        return purposes;
    }

    // todo: use bytes
    function generateNonce(string memory earthAddress, uint networkIdx, uint purposeIdx) public {
        // todo validate purpose network combination
        // todo validate length of earthAddress, maybe even pass min length as a parameter
        // also pass the symbol as a parameter?

        // todo simulating randomness here, but in reality this should be done via
        // chainlink VRF
        uint randomFee = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        // this is max + min and min. todo: parameterize
        randomFee = (randomFee % 10 ** numDecimals) + baseFee;
        emit NonceGenerated(earthAddress, msg.sender, networkIdx, purposeIdx,  randomFee);
    }
}