/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

contract EscrowUnsafe {

    event DepositReceived(bytes32 indexed escrowID, address indexed depositor, address beneficiary,address approver, uint amount );
    event Approved(bytes32 indexed escrowID,uint timestamp);
    event Terminated(bytes32 indexed escrowID,uint timestamp);

    uint nonce;
    address owner; // to make it ownable 

    struct escrow {
        uint amount;
        address depositor;
        address beneficiary;
        address approver;
        bool approved;
        bool active;
    }
    mapping(bytes32 => escrow) escrowRegistry;

    constructor() {
        owner == msg.sender;
    }

    // Deposit funds in contract and set benediciary, approver of the funds
    function deposit(address _beneficiary, address _approver) external payable {
        address _depositor = msg.sender;
        uint _amount = msg.value;
        bytes32 _escrowID = keccak256(abi.encodePacked(nonce, _depositor));
        escrowRegistry[_escrowID].amount = _amount;
        escrowRegistry[_escrowID].depositor = _depositor;
        escrowRegistry[_escrowID].beneficiary = _beneficiary;
        escrowRegistry[_escrowID].approver = _approver;
        escrowRegistry[_escrowID].active = true;
        nonce+=1;
        emit DepositReceived(_escrowID, _depositor, _beneficiary, _approver, _amount);
    }

    // Approve the transcation by approver for transfering funds
    function approve(bytes32 _escrowID) external {
        require(msg.sender == escrowRegistry[_escrowID].approver, "Only approver can call");
        require(escrowRegistry[_escrowID].active == true, "Only active escorws can be approved");
        escrowRegistry[_escrowID].approved = true;
        emit Approved(_escrowID, block.timestamp);
    }
// Withdraw funds via beneficiary 
    function withdrawFunds(bytes32 _escrowID) external {
        address caller = msg.sender;
        require(caller == escrowRegistry[_escrowID].beneficiary, "Only beneficiary can withdraw");
        require(escrowRegistry[_escrowID].active, "Only active escrows can be withdrawn, this is already inactive");
        require(escrowRegistry[_escrowID].approved, "Only approved escrows can be withdrawn");
         (bool result, ) = caller.call{value: escrowRegistry[_escrowID].amount}(
            "");
         escrowRegistry[_escrowID].amount = 0;
         escrowRegistry[_escrowID].active = false;
        require(result, "transfer failed");
        emit Terminated(_escrowID,block.timestamp);
   }

    // Cancel escrow via depositor 
    function cancelEscrow(bytes32 _escrowID) external {
        address caller = msg.sender;
        require(caller == escrowRegistry[_escrowID].depositor,"Only depositor can cancel");
        require(escrowRegistry[_escrowID].active,"only active escrows can be cancelled, this is already inactive");
        require(!escrowRegistry[_escrowID].approved,"only not approved escrows can be cancelled");
           (bool result, ) = caller.call{value: escrowRegistry[_escrowID].amount}(
            ""
        );
        escrowRegistry[_escrowID].amount = 0;
        escrowRegistry[_escrowID].active = false;
        require(result, "transfer failed");
        emit Terminated(_escrowID, block.timestamp);
        
    }
    /*
     * Utility functions this function would never be in this kind of contract.
     * This is here to avoid getting funds stuck in the contract while testing.
     */
    function transferBalance() external {
        require(msg.sender == owner, "only owner function");
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
}