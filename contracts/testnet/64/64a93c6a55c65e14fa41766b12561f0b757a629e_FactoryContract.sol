/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.23 <0.9.0;

contract FactoryContract {

    ChildContract[] private _contracts;

    function createChildContract(string memory name) public {
        ChildContract child = new ChildContract(name, msg.sender);
        _contracts.push(child);
    }

    function allContracts() public view returns (ChildContract[] memory)
    {
        return _contracts;
    }

    function deleteContract(ChildContract childContractAddress) public  //delete on the basis of element
    {
        for (uint i=0;i<=_contracts.length-1;i++){
            if (_contracts[i]==childContractAddress) {
                _contracts[i] = _contracts[_contracts.length-1];
                _contracts.pop();
            }
        }
    }
}

contract ChildContract { // random child contract
    string public name;
    address public owner;

    constructor(
        string memory _name,
        address _owner
    ) public {
        name = _name;
        owner = _owner;
    }
    
}