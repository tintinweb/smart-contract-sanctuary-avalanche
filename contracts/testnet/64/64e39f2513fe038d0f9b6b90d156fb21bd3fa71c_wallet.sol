/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;
contract wallet{

    address payable public owner=payable(msg.sender);

    function deposit() payable public{
    }

    function withdraw(address payable sendto,uint amount) public{
        require(owner==msg.sender,"You don't have the authority to withdraw funds!");
        sendto.transfer(amount);
    }
    function Balance() public view returns(uint){
        return address(this).balance;
    }

    function transferOWnerShip(address payable newOwner ) public{
        require(owner==msg.sender,"Who the fuck are you?");
        require(newOwner != address(0),"Invalid !");
        owner=newOwner;
    }
}