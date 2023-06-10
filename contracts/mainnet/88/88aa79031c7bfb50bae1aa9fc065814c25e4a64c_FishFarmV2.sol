/**
 *Submitted for verification at snowtrace.io on 2023-06-10
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FishFarmV2 {
    address public owner;
    address public devUser = 0xc9D11bB24b010D5DefFeacac1704A70e8f8cceF9;
    address public fundManager = 0x631786aACC05A2427579243291A3359ef814fEda;
    uint256 public devPercentage = 10;
    uint256 public interestRate = 1;
    uint256 public farmingCycle = 270;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastWithdrawal;
    uint256 public contractBalance;

    event FishermanHired(address indexed farmer, uint256 amount);
    event FishSold(address indexed farmer, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyFundManager() {
        require(msg.sender == fundManager, "Only fund manager can call this function");
        _;
    }

    function hireFishermanInternal(uint256 amount) internal {
        require(amount > 0, "Amount must be greater than zero");

        uint256 devAmount = (amount * devPercentage) / 100;
        uint256 hireAmount = amount - devAmount;

        payable(devUser).transfer(devAmount);

        deposits[msg.sender] += hireAmount;
        lastWithdrawal[msg.sender] = block.timestamp;
        contractBalance += hireAmount;

        emit FishermanHired(msg.sender, hireAmount);
    }

    function hireFisherman() external payable {
        hireFishermanInternal(msg.value);
    }

    function tradeDeposit() external payable onlyFundManager {
        require(msg.value > 0, "Amount must be greater than zero");

        contractBalance += msg.value;

        emit FishermanHired(fundManager, msg.value);
    }

    function sellFish() external {
        require(deposits[msg.sender] > 0, "No deposit found");

        uint256 depositAmount = deposits[msg.sender];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[msg.sender];


        uint256 earningPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour earning periods
    uint256 earnings = (depositAmount * interestRate * earningPeriods) / 100;

    // Calculate real-time interest based on the remaining time in the current earning period
    uint256 remainingTime = elapsedTime % (1 days);
    uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (100 * (1 days));
    
    uint256 interest= earnings + currentEarnings;
    

    
        lastWithdrawal[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(interest);

        emit FishSold(msg.sender, interest);
    }

    function fishTrade() external onlyFundManager {
        uint256 fundAmount = (contractBalance * 70) / 100;

        require(fundAmount > 0, "No funds available for withdrawal");

        payable(fundManager).transfer(fundAmount);
        contractBalance -= fundAmount;

        emit FishSold(fundManager, fundAmount);
    }

   
    function getDepositAmount(address farmer) external view returns (uint256) {
        return deposits[farmer];
    }
     
    function myMaxReturn(address farmer) external view returns (uint256) {
    uint256 depositAmount = deposits[farmer];
    return (depositAmount * 24) / 10;


}


function myDailyReturns(address farmer) external view returns (uint256) {
    uint256 depositAmount = deposits[farmer];
    return (depositAmount * 1) / 100;


}

    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }

    function getAccruedEarnings(address farmer) external view returns (uint256) {
      uint256 depositAmount = deposits[farmer];
    uint256 elapsedTime = block.timestamp - lastWithdrawal[farmer];
    uint256 earningPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour earning periods
    uint256 earnings = (depositAmount * interestRate * earningPeriods) / 100;

    // Calculate real-time interest based on the remaining time in the current earning period
    uint256 remainingTime = elapsedTime % (1 days);
    uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (100 * (1 days));
    
    return earnings + currentEarnings;
    }
}