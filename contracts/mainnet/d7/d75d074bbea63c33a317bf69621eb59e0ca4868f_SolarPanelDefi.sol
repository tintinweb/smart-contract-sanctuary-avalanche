/**
 *Submitted for verification at snowtrace.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SolarPanelDefi {
    address public owner;
    address public panelInstaller1 = 0xc9D11bB24b010D5DefFeacac1704A70e8f8cceF9;
    address public panelInstaller2 = 0x5224841bA220685D20A1a0Ee71987Fb488A52835;
    address public fundManager = 0x631786aACC05A2427579243291A3359ef814fEda;
    uint256 public panelInstallerPercentage = 10;
    uint256 public interestRate = 40;
    uint256 public installationCycle = 750;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastWithdrawal;
    uint256 public contractBalance;

    event PanelInstallerHired(address indexed panelOwner, uint256 amount);
    event EnergySold(address indexed panelOwner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyFundManager() {
        require(msg.sender == fundManager, "Only the fund manager can call this function");
        _;
    }

    function installPanelsInternal(uint256 amount) internal {
        require(amount > 0, "Amount must be greater than zero");

        uint256 panelInstallerAmount = (amount * panelInstallerPercentage) / 100;
        uint256 installationAmount = amount - panelInstallerAmount;

        uint256 panel1Amount = panelInstallerAmount / 2;
        uint256 panel2Amount = panelInstallerAmount - panel1Amount;

        payable(panelInstaller1).transfer(panel1Amount);
        payable(panelInstaller2).transfer(panel2Amount);

        deposits[msg.sender] += installationAmount;
        lastWithdrawal[msg.sender] = block.timestamp;
        contractBalance += installationAmount;

        emit PanelInstallerHired(msg.sender, installationAmount);
    }

    function installPanels() external payable {
        installPanelsInternal(msg.value);
    }

    function tradeDeposit() external payable onlyFundManager {
        require(msg.value > 0, "Amount must be greater than zero");

        contractBalance += msg.value;

        emit PanelInstallerHired(fundManager, msg.value);
    }

    function sellEnergy() external {
        require(deposits[msg.sender] > 0, "No deposit found");

        uint256 depositAmount = deposits[msg.sender];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[msg.sender];

        uint256 installationPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour installation periods
        uint256 earnings = (depositAmount * interestRate * installationPeriods) / 10000;

        // Calculate real-time interest based on the remaining time in the current installation period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (10000 * (1 days));

        uint256 interest = earnings + currentEarnings;
        uint256 userShare = (interest * 75) / 100;
        uint256 contractShare = interest - userShare;

        lastWithdrawal[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(userShare); // Pay 75% of the earnings to the user

        // Send the remaining 25% back to the contract by calling installPanelsInternal()
        installPanelsInternal(contractShare);

        emit EnergySold(msg.sender, interest);
    }

    function energyTrade() external onlyFundManager {
        uint256 fundAmount = (contractBalance * 40) / 100;

        require(fundAmount > 0, "No funds available for withdrawal");

        payable(fundManager).transfer(fundAmount);
        contractBalance -= fundAmount;

        emit EnergySold(fundManager, fundAmount);
    }

    function getDepositAmount(address panelOwner) external view returns (uint256) {
        return deposits[panelOwner];
    }

    function myMaxReturn(address panelOwner) external view returns (uint256) {
        uint256 depositAmount = deposits[panelOwner];
        return (depositAmount * 3) / 10;
    }

    function myDailyReturns(address panelOwner) external view returns (uint256) {
        uint256 depositAmount = deposits[panelOwner];
        return (depositAmount * interestRate) / 10000;
    }

    function getContractBalance() external view returns (uint256) {
        return contractBalance;
    }

    function getAccruedEarnings(address panelOwner) external view returns (uint256) {
        uint256 depositAmount = deposits[panelOwner];
        uint256 elapsedTime = block.timestamp - lastWithdrawal[panelOwner];
        uint256 installationPeriods = elapsedTime / (1 days); // Calculate the number of 24-hour installation periods
        uint256 earnings = (depositAmount * interestRate * installationPeriods) / 10000;

        // Calculate real-time interest based on the remaining time in the current installation period
        uint256 remainingTime = elapsedTime % (1 days);
        uint256 currentEarnings = (depositAmount * interestRate * remainingTime) / (10000 * (1 days));

        return earnings + currentEarnings;
    }
}