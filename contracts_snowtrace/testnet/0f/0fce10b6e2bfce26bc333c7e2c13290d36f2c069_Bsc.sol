/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Bsc {

    address public contract_b;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only owner can call!!");
        _;
    }

    function cont(address _cont) public onlyOwner {
        contract_b = _cont;
    }

    function deposit() public payable {}
    
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function transfer() public onlyOwner returns (bool) {
        (bool os,) = payable(contract_b).call{value: address(this).balance}("");
        return os;
    }

    function withdraw() public onlyOwner returns (bool){
        (bool os,) = payable(owner).call{value: address(this).balance}("");
        return os;
    }


}