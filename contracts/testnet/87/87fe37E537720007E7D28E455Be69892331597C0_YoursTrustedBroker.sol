/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity^0.8.12;

contract YoursTrustedBroker{
    using SafeMath for uint256;
    address payable public Owner;
    uint256 protocolFee = 5;
    uint256 rebateFee = 95;
    uint256 Base = 100;

    constructor () {
        Owner = payable(msg.sender);
    } 

    modifier OnlyOwner(){
        require(msg.sender == Owner);
        _;
    }

    struct Transaction{
        address broker;
        address user;
        uint256 startPrice;
        uint256 percentChange;
        string tokenName;
        uint256 finalPrice;
        uint256 fee;
        bool approved;
    }

    // Transaction[] public Transactions;
    mapping (address => bool) brokerVerified;
    mapping (address => mapping (address => Transaction[])) public AllTransactions;
    mapping (address => mapping (address => uint256)) public TransactionsCount;

    // Broker onboarding 
    function onBoardBroker() payable public returns(bool){
        require(msg.value == 1e15, "Minimum Broker Boarding Fee is 0.001ETH");
        require(brokerVerified[msg.sender] == false, "Already Verified Broker");
        brokerVerified[msg.sender] = true;
        return true;
    }

    // Broker Sending Transaction to User 
    function createPrediction(address user, uint256 startPrice,uint256 percentChange, string memory tokenName, uint256 finalPrice, uint256 fee) public returns(bool){
        require(brokerVerified[msg.sender] == true, "Verify Before Creating Prediction");
        require(msg.sender != user, "Cannot send transactions with in");
        Transaction memory transact = Transaction(
            msg.sender,
            user,
            startPrice,
            percentChange,
            tokenName,
            finalPrice,
            fee,
            false
        );
        AllTransactions[msg.sender][user].push(transact);
        TransactionsCount[msg.sender][user] += 1;
        return true;
    }

    // User accepting Transaction and Paying Fee 
    function acceptPrediction(address broker, uint256 index) payable public returns(bool){
        Transaction memory transact = AllTransactions[broker][msg.sender][index];
        require(!transact.approved, " Transaction Already Approved");
        require(msg.sender == transact.user, "Only user can approve transaction");
        require(msg.value >= transact.fee, "Need to Pay the Fee to reveal Prediction");
        transact.approved = true;
        AllTransactions[broker][msg.sender][index] = transact;
        return true;
    }

    // Result 
    function getResult(address broker, address user, uint256 minPrice, uint256 maxPrice, uint256 index) payable public returns(bool){
        Transaction memory transact = AllTransactions[broker][msg.sender][index];
        require(transact.approved, " Transaction Not Approved");
        bool forwardFundsToUser = false;
        if (((transact.startPrice > transact.finalPrice) && (transact.finalPrice > minPrice)) || (transact.startPrice < transact.finalPrice) && (transact.finalPrice < maxPrice)){
            forwardFundsToUser = true;
        }
        else{
            forwardFundsToUser = false;
        }

        if (forwardFundsToUser){ // Return User Funds Back to User 
            payable(user).transfer(transact.fee.mul(rebateFee).div(Base));
        } 
        else{ // Return Funds to Broker 
            payable(broker).transfer(transact.fee.mul(rebateFee).div(Base));
        }
        Owner.transfer(transact.fee.mul(protocolFee).div(100));
    }
}

library SafeMath {
    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}