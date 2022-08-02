/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-01
*/

pragma solidity ^0.8.15;

// SPDX-License-Identifier: MIT

contract OTCDeployer{

    string public Version = "v-1.0.1";
    address payable Owner;

    mapping(address => address[]) public OTCLists;
    mapping(address => bool) public OTCStates;
    address[] PendingOwners;
    address[] RunningOwners;
    address[] FinishedOwners;

    constructor(){
    }

    modifier OnlyOwner(){
        require(Owner == msg.sender,"Needs Owner Priviliges");
        _;
    }
    
    function ChangeOwner(address _Owner) public OnlyOwner returns(bool success){
        Owner = payable(_Owner);
        return true;
    }

    function CreateOTC() public returns(bool success){
        OTC NewOTC = new OTC();
        address NewAddress = address(NewOTC);
        OTCLists[msg.sender].push(NewAddress);
        OTCStates[NewAddress] = false;
        PendingOwners.push(msg.sender);
        return true;
    }

//    function FinishOTC(address OTCOWner) public returns(bool success){
//       DeleteFromArray(RunningOwners[OTCOWner],0);
//        DeleteFromArray(PendingOwners[OTCOWner],0);
//        return true;
//    }

//   function DeleteFromArray(address[] memory Array,uint Index) private returns(bool success)
//    {
//        Array[Index] = Array[Array.length - 1];
//        Array.pop();
//        return true;
//    }
}






contract OTC{
    address public DeployerAddress;
    string public Version;
    address payable Owner;
    address Admin = 0x5D5DB5E63d5bBc814d366734fC218dB95DfEEee3;
    string[] SaleData;

//    constructor(address payable _Owner, string memory _Version){
//        Owner = _Owner;
//        Version = _Version;
//        DeployerAddress = msg.sender;
//    }

    modifier OnlyOwner(){
        require(Owner == msg.sender,"Needs Owner Priviliges");
        _;
    }
     
    modifier OnlyAdmin(){
        require(Owner == msg.sender,"Needs Admin Priviliges");
        _;
    }

    function ChangeOwner(address _Owner) public OnlyOwner returns(bool success){
        Owner = payable(_Owner);
        return true;
    }

    function ChangeAdmin(address _Admin) public OnlyAdmin returns(bool success){
        Admin = payable(_Admin);
        return true;
    }
}