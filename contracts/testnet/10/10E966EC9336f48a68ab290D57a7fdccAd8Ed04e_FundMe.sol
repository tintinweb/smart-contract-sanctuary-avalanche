/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract FundMe {

    mapping(address => uint256) public addressToFunds;
    address[] public funders;
    address public owner;
    uint256 public locked_funds;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        addressToFunds[msg.sender] += msg.value;
        locked_funds += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addressToFunds[funders[i]] = 0;
        }
        locked_funds = 0;
        funders = new address[](0);
    }
}