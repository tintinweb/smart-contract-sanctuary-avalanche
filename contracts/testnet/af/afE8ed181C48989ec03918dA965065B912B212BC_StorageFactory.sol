/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to       
    }
    mapping(uint=> Voter) public voters;
    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    function setVoter(Voter memory _voter, uint _index) public {
        voters[_index] = _voter;
    }
    function getVoter(uint _index) public view returns(Voter memory){
        return voters[_index];
    }
}

contract StorageFactory{
    Storage[] public storages;

    function create() public{
        Storage contractInstance = new Storage();
        storages.push(contractInstance);
    }

    function getContractAddress(uint _index) public view returns(address){
        return address(storages[_index]);
    }

    function setNumberAt(uint _index, uint _number) public{
        storages[_index].store(_number);
    }

     function getNumberAt(uint _index) public view returns(uint){
        return storages[_index].retrieve();
    }

    function setVoter(uint _weight, bool _voted, address _delegate, uint _votersIndex, uint _contractIndex) public {
        Storage.Voter memory tempVoter = Storage.Voter({weight: _weight, voted:_voted, delegate:_delegate});
        storages[_contractIndex].setVoter(tempVoter, _votersIndex);
    }
    function getVoter(uint _votersIndex, uint _contractIndex) public view returns(Storage.Voter memory){
        return storages[_contractIndex].getVoter(_votersIndex);
    }
}