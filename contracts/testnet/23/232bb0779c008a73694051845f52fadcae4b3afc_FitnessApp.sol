/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract FitnessApp {

    mapping(address => mapping(uint256 => bool)) public subscriptions;

    uint256 public constant YEARLY_SUBSCRIPTION_PRICE = 0.1 ether;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }

    function subscribe(uint256 _year) payable external {
        require(msg.value == YEARLY_SUBSCRIPTION_PRICE, "WRONG AMOUNT SENT");
        require(!subscriptions[msg.sender][_year], "ALREADY SUBSCRIBED FOR THAT YEAR");
        subscriptions[msg.sender][_year] = true;
    }

    function payOut(uint256 _currentYear, address _receiver, uint256 _amount) onlyOwner external {
        require(subscriptions[_receiver][_currentYear], "USER IS NOT SUBSCRIBED");
        payable(_receiver).transfer(_amount);
    }

    receive() external payable {
    }


}