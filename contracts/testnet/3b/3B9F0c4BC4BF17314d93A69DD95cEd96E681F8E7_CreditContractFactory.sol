/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-13
*/

pragma solidity>0.4.99<=0.8.14;
//SPDX-License-Identifier: UNLICENSED

contract CreditContractFactory {
    CreditContract[] public deployedContracts;

    function createContract() public {
        CreditContract newContract = new CreditContract(msg.sender);
        deployedContracts.push(newContract);
    }

    function getDeployedContracts() public view returns (CreditContract[] memory) {
        return deployedContracts;
    }
}

contract CreditContract {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(address creator) {
        manager = creator;
    }
}