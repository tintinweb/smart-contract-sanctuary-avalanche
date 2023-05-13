// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


/// @title A contract for Xena
/// @author Hayate
/// @notice NFT Minting
contract Xenatest  {
   string[] public instructions;    

    constructor() {
    }    
    function getInstruction() external view returns (string[] memory) {
        return instructions;
    }
    function addInstruction(string memory newInstruction) external {
        instructions.push(newInstruction);
    }
}