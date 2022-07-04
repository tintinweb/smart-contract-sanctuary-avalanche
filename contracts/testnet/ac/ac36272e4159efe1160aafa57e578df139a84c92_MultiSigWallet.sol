/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-03
*/

// SPDX-License-Identifier: Unliscenced

pragma solidity 0.7.5;
pragma abicoder v2;

contract MultiSigWallet {
    
    struct TransferRequest {
        address fromAddr;
        address payable toAddr;
        uint amount;
        uint approvals;
        bool complete;
    }
    
    // todo add events and emit
    
    address[] public owners;
    uint approvalLimit;
    TransferRequest[] transferReqs;

    mapping(address => uint) balance;
    mapping(address => bool) isOwner;
    mapping(address => mapping(uint => bool)) approvals;
    
    modifier onlyOwners() {
        require(isOwner[msg.sender], "Address not owner");
        _;
    }
    
    constructor(address[] memory _owners, uint _approvalLimit) {
        require(_owners.length >= _approvalLimit, "The number of required approvals cannot exceed the number of approvers");
        owners = _owners;
        approvalLimit = _approvalLimit;
        for (uint i=0; i<_owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
    }
    
    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }
    
    function createTransfer(uint amount, address payable recipient) public onlyOwners {
        require(msg.sender != recipient, "Don't transfer money to yourself");
        transferReqs.push(TransferRequest(msg.sender, recipient, amount, 0, false));
    } 
    
    function approve(uint id) public onlyOwners {
        require(!approvals[msg.sender][id], "You already approved this transfer");
        require(!transferReqs[id].complete, "Transfer is already complete");
        require(balance[transferReqs[id].fromAddr] >= transferReqs[id].amount, "Balance not sufficient");
        
        // approve by msg.sender
        approvals[msg.sender][id] = true;
        transferReqs[id].approvals += 1;
        
        // execute transfer
        if (transferReqs[id].approvals >= approvalLimit) {
            balance[transferReqs[id].fromAddr] -= transferReqs[id].amount;
            transferReqs[id].toAddr.transfer(transferReqs[id].amount);
            transferReqs[id].complete = true;
        }
    }
    
    /* Getter below */
    function getTransferRequests() public view returns (TransferRequest[] memory) {
        return transferReqs;
    }
    
    function getBalance() public view returns (uint) {
        return balance[msg.sender];
    }
    
}