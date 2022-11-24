/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    address owner;
    
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the smart contract owner!");
        _;
    }

    event Deposited(address from, uint amount);

    function depositMoney() public payable {
        emit Deposited(msg.sender, msg.value);
    }

    // Use transfer method to withdraw an amount of money and for updating automatically the balance
    function withdrawMoney(address _to, uint _value) public  {
        payable(_to).transfer(_value);
    }

    // Getter smart contract Balance
    function getSmartContractBalance() external view returns(uint) {
        return address(this).balance;
    }

}