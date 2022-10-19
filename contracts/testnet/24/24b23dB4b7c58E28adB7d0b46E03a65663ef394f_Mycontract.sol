/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-18
*/

// SPDX-License-Identifier:ChawyRD
pragma solidity ^0.8.17;

contract Mycontract{
    address public Owner;

    constructor()payable{
        Owner=msg.sender;
    }

    modifier check(){
        require(Owner==msg.sender,"you cant withdraw!");
        _;
    }

    receive()payable external{}
    
    function withdraw() payable external check{
        address payable Receiver =payable(msg.sender);
        Receiver.transfer(address(this).balance);
    }

}