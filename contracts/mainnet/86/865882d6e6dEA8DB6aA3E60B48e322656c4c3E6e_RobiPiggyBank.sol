/**
 *Submitted for verification at snowtrace.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
    ROBI PIGGY BANK
*/

contract RobiPiggyBank {

    event Deposit(address depositor, uint amout, uint year);
    event Withdraw(address depositor, uint amout, uint year);

    mapping (address => mapping(uint => uint)) private deposits;
    uint public dday = 1658613600;
    uint private secondsInAYear = 3600*24*365;

    constructor(){}

    /*
        Money deposited in this account will be withdrawable only after the dday of given year
        example: deposit(2030) will be available for withdraw only after dday in 2030
    */
    function deposit(uint year) external payable{
        require( year >= 2022 && year <= 2042, 'Year must be >= 2022 and <= 2042');
        deposits[msg.sender][year] += msg.value;
        emit Deposit(msg.sender, msg.value, year);
    }

    function withdraw(uint year) external{
        uint totalDeposit = deposits[msg.sender][year];

        require( canWithdraw(year), 'Cannot withdraw for now, wait untill the dday of the given year');
        require( totalDeposit>0, 'Nothing to withdraw for this year');
        
        payable(msg.sender).transfer(totalDeposit);
        deposits[msg.sender][year]=0;
        emit Withdraw(msg.sender, totalDeposit, year);
    }

    function canWithdraw(uint year) public view returns(bool){
        require(year>=2022,'year must be >= 2022');
        return (block.timestamp >= ((year-2022)* secondsInAYear + dday));
    }

    function getDeposit(address depositor, uint year) external view returns(uint){
        return deposits[depositor][year];
    }

}