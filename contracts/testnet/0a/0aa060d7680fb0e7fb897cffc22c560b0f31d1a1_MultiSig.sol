/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract MultiSig {
    address[] public owners;
    uint public transactionCount;
    uint public required;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
        bytes data;
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;

    receive() payable external {
        emit Deposit(msg.sender, msg.value);
    }

    function getOwners() view public returns(address[] memory) {
        return owners;
    }

    function getTransactionIds(bool pending, bool executed) view public returns(uint[] memory) {
        uint count = getTransactionCount(pending, executed);
        uint[] memory txIds = new uint[](count);
        uint runningCount = 0;
        for(uint i = 0; i < transactionCount; i++) {
            if(pending && !transactions[i].executed ||
                executed && transactions[i].executed) {
                txIds[runningCount] = i;
                runningCount++;
            }
        }
        return txIds;
    }

    function getTransactionCount(bool pending, bool executed) view public returns(uint) {
        uint count = 0;
        for(uint i = 0; i < transactionCount; i++) {
            if(pending && !transactions[i].executed ||
                executed && transactions[i].executed) {
                count++;
            }
        }
        return count;
    }

    function executeTransaction(uint transactionId) public {
        require(isConfirmed(transactionId));
        emit Execution(transactionId);
        Transaction storage _tx = transactions[transactionId];
        (bool success, ) = _tx.destination.call{ value: _tx.value }(_tx.data);
        require(success, "Failed to execute transaction");
        _tx.executed = true;
    }

    function isConfirmed(uint transactionId) public view returns(bool) {
        return getConfirmationsCount(transactionId) >= required;
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint) {
        uint count;
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function getConfirmations(uint transactionId) public view returns(address[] memory) {
        address[] memory confirmed = new address[](getConfirmationsCount(transactionId));
        uint runningConfirmed;
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[transactionId][owners[i]]) {
                confirmed[runningConfirmed] = owners[i];
                runningConfirmed++;
            }
        }
        return confirmed;
    }

    function isOwner(address addr) private view returns(bool) {
        for(uint i = 0; i < owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address payable dest, uint value, bytes memory data) public {
        uint id = addTransaction(dest, value, data);
        confirmTransaction(id);
        emit Submission(id);
    }

    function confirmTransaction(uint transactionId) public {
        require(isOwner(msg.sender));
        emit Confirmation(msg.sender, transactionId);
        confirmations[transactionId][msg.sender] = true;
        if(isConfirmed(transactionId)) {
            executeTransaction(transactionId);
        }
    }

    function addTransaction(address payable destination, uint value, bytes memory data) public returns(uint) {
        transactions[transactionCount] = Transaction(destination, value, false, data);
        transactionCount += 1;
        return transactionCount - 1;
        
    }

    constructor(address[] memory _owners, uint _confirmations) {
        require(_owners.length > 0);
        require(_confirmations > 0);
        require(_confirmations <= _owners.length);
        owners = _owners;
        required = _confirmations;
    }
}