/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MaritimeSamples{
  address public owner;

    struct Sample{
        string sampleID;
        string state;
        string URI;
    }
    
    Sample [] public samples;

   event SampleCreated(string sampleID, string state, string URI);
   event StateChanged(string sampleID, string state);

    constructor(){
        owner=msg.sender;
    }

    modifier onlyOwner {
    require(msg.sender == owner);
    _;
    }

    function changeOwner(address newOwner) public onlyOwner{
        owner = newOwner;
    }

   
    function insertSample(string memory sampleID, string memory state, string memory URI) public onlyOwner{
        samples.push(Sample(sampleID, state, URI));
        emit SampleCreated(sampleID, state, URI);
    }

    function changeState(string memory sampleID, string memory new_state) public onlyOwner{
        for(uint i=0; i <samples.length; i++)
        {
            if(keccak256(bytes(samples[i].sampleID)) == keccak256(bytes(sampleID)))
            {
                samples[i] = Sample(samples[i].sampleID, new_state, samples[i].URI);
                emit StateChanged(sampleID, new_state);
            }
        }
    }

    function getAllSamples() public onlyOwner view returns(Sample[] memory) {
        uint lastSample = samples.length;
        uint _counter=0;
        
        Sample[] memory res = new Sample[](lastSample);

        for(uint256 i=0; i<lastSample; i++){
            res[_counter] = samples[i];
            _counter++;
        }
        return res;
    }
}