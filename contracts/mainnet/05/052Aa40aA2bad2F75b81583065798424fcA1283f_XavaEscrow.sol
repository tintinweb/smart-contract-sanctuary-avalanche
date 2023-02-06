pragma solidity ^0.8.0;
// SPDX-License-Identifier: AGPL-3.0-only
/// DISCLAIMER ///

/// USE AT YOUR OWN RISK, AS YOU WOULD ANY OPEN-SOURCE SMART CONTRACT/// 

// This open-source software is provided "as-is", developed by Ledger Agnostic Solutions DAO LLC ("LAS")
// as a consulting project for a client. LAS claims no responsiblity to how this open source software is used. 
// Although thoroughly audited, LAS provides no guarantee funds stored in this software are 100% secure 
// from potential unforseen security vulnerabilities or unintended use by an owner.

// Anyone can deploy open-source smart contracts, and for this contract specifically, 
// any deployer may not know what new owner / manager the deployed owner elects to upgrade to


// It is STRONGLY reccomended (when using an ownership pattern like this) to make the owner field a multisig contract address, not an EOA

/// END OF DISCLAIMER ///

contract XavaEscrow {

    // reverts when the contract is paused and a native token deposit is attempted
    error Paused();
    // reverts when only owner can call a function 
    error BadOwner();
    // reverts when only manager can call a function
    error BadManager();

    uint256 public ownerBalance;
    mapping(address => uint256) public withdrawEscrowBalances;

    address owner;
    address manager;

    // pause can only prevent deposits from occuring
    bool paused;

    constructor(address _owner, address _manager) {
        owner = _owner;
        manager = _manager;

    }

    modifier OnlyOwner() {
        if(msg.sender != owner) revert BadOwner();
        _;
    }

    modifier OnlyManager() {
        if(msg.sender != manager) revert BadManager();
        _;
    }

    event Deposit(address indexed who, uint256 amount);
    event Withdrawal(address indexed who, uint256 amount);

    receive() external payable {
        if (paused) revert Paused();
        emit Deposit(msg.sender, msg.value);
        ownerBalance += msg.value;
    }

    /*/////////////////////////////
            ESCROW LOGIC
    /////////////////////////////*/

    event WithdrawalInitiated(address indexed who, uint256 balanceBefore, uint256 balanceAfter, uint256 withdrawalSize);


    /// @param who - address for which to credit withdrawl 
    /// @param withdrawAmount - total amount to be moved from the user  into withdraw escrow
    function initiateWithdrawal(
        address who, 
        uint256 withdrawAmount
        ) external OnlyManager {

        ownerBalance -= withdrawAmount;
        withdrawEscrowBalances[who] += withdrawAmount;
    }

    function withdraw(uint256 amount) external {
        emit Withdrawal(msg.sender, amount);

        if(msg.sender == owner) revert("use ownerWithdraw() if owner");

        // adheres to checks-before-effects interaction to prevent reentrancy 
        // solidity ^0.8.0 safemath automatically reverts on underflow
        withdrawEscrowBalances[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);
    } 
   

    /*/////////////////////////////
            MANAGERIAL LOGIC
    /////////////////////////////*/

    event OwnerChanged(address indexed oldOwer, address indexed newOwner);
    event ManagerChanged(address indexed oldManager, address indexed newManager);

    function pause() external OnlyOwner {
        paused = true;
    }

    function unpause() external OnlyOwner {
        paused = false;
    }

    function changeOwner(address payable newOwner) external OnlyOwner {
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }


    function changeManager(address newManager) external OnlyOwner {
        emit ManagerChanged(manager, newManager);
        manager = newManager;
    }

    function ownerWithdraw(uint256 amount, address to) external OnlyOwner {
        // enforces no more than 50% of owner balance can be withdrawn at a time 
        // prevents fat-finger error 
        uint256 fiftyPercent = (1000 * ownerBalance) / 2000;
        require(amount <= fiftyPercent);

        ownerBalance -= amount;

        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer Failed!");
    }
}