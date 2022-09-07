/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-06
*/

pragma solidity ^0.5.1;
contract Payment{ 
    address Account2;
    address Owner;

    constructor() public{
        Account2 = 0x583031D1113aD414F02576BD6afaBfb302140225;
        Owner = msg.sender;
    }

    function () payable external{}
    function deposit() payable public{
        address(uint160(Account2)).transfer(1 ether);
    }

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
}