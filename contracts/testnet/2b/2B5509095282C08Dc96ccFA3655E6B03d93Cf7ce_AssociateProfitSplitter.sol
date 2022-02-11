// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;


contract AssociateProfitSplitter {
    
    address payable employee_one;
    address payable employee_two;
    address payable employee_three;
    

    constructor() public {
        employee_one = payable(address(0x3ad7f8C28257C2CEC8E8E3F9Af690575779120c6));
        employee_two = payable(address(0x3ad7f8C28257C2CEC8E8E3F9Af690575779120c6));
        employee_three = payable(address(0x3ad7f8C28257C2CEC8E8E3F9Af690575779120c6));
    }

    function balance() public view returns(uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        uint amount = msg.value / 3;
        employee_one.transfer(amount);
        employee_two.transfer(amount);
        employee_three.transfer(amount);
        msg.sender.transfer(msg.value - amount * 3);
    }


    function fallback () external payable {
        deposit();
    }
}