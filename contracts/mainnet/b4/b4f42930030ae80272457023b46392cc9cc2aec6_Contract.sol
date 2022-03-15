/**
 *Submitted for verification at snowtrace.io on 2022-03-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface Market {
    function owner() external returns (address);
    function withdrawBalance() external;
    function transferOwnership(address newOwner) external;
    function withdrawableBalance() external returns (uint256);
}

contract Contract {

    address public owner;
    address immutable market;

    mapping(address => uint256) partners;
    mapping(address => uint256) claimed;
    uint256 public withdrawn;

    constructor() {
        owner = msg.sender;
        market = 0x770a4C7f875fb63013a6Db43fF6AF9980fcEb3b8;

        partners[0xc899b9992397601c5e84FF238ac9DcA286B6dAc6] = 50000;
        partners[0x0e1E482af12f84fBcEA5806F61059CcDe3230813] = 50000;
    }

    function setOwner(address newOwner) external {
        require(msg.sender == owner, "");

        owner = newOwner;
    }

    function emergencyWithdraw() external {
        require(msg.sender == owner, "");

        payable(msg.sender).transfer(address(this).balance);
    }

    function revoke() external {
        require(msg.sender == owner, "");

        Market(market).transferOwnership(msg.sender);
    }

    function change(address from, address to) public {
        require(from == msg.sender, "");
        require(partners[to] == 0, "");

        claimed[to] = claimed[from];
        partners[to] = partners[from];

        delete partners[from];
        delete claimed[from];
    }

    function claimable(address partner) external view returns (uint256) {
        uint256 _withdrawn = withdrawn + market.balance;
        return (_withdrawn * partners[partner]) / 100000 -  claimed[partner];
    }

    function claim() external {
        uint256 withdrawable = Market(market).withdrawableBalance();
        if (withdrawable > 0.5 ether) {
            withdrawn += withdrawable;
            Market(market).withdrawBalance();
        }
        
        uint256 share = partners[msg.sender];

        uint256 amount = ((withdrawn * share) / 100000) -  claimed[msg.sender];

        claimed[msg.sender] += amount;

        payable(msg.sender).transfer(amount); 

    }

    function deposit() external payable {
        withdrawn += msg.value;
    }

    fallback() external payable {}

}