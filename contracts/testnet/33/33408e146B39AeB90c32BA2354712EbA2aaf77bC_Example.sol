/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-02
*/

// SPDX-License-Identifier: GPL-3:0 

pragma solidity >=0.5.11 <= 0.8.10;

contract Example{
    
    struct ExampleInformation{
        string projectID;
        string projectHash;
    }
    
    mapping (string => ExampleInformation) infoExample;

    constructor(){
        
    }
    
    function readData(string memory ID) view public returns(string memory, string memory){
       return(infoExample[ID].projectID, infoExample[ID].projectHash); 
    }
    

    function writeData(string memory _projectID, string memory _projectHash) public{
        ExampleInformation storage data = infoExample[_projectID];
        data.projectID = _projectID;
        data.projectHash = _projectHash;
    }
}