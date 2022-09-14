// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ChangeOwner.sol";

contract MultiSigWallet {
    ChangeOwner _contract;

    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed newAdmin,
        address contractAddress,
        string contractType
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address newAdminAddress;
        address conractAddress;
        string contractType;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _newAdmin,
        address _contractAddress,
        string memory _contractType
    ) public onlyOwner {
        require((keccak256(abi.encodePacked(_contractType)) == keccak256(abi.encodePacked("erc20"))) || (keccak256(abi.encodePacked(_contractType)) == keccak256(abi.encodePacked("bridge"))), "Invalid contract type");
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                newAdminAddress: _newAdmin,
                conractAddress: _contractAddress,
                contractType: _contractType,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _newAdmin, _contractAddress, _contractType);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        if(keccak256(abi.encodePacked(transaction.contractType)) == keccak256(abi.encodePacked("bridge"))) {
            _contract = ChangeOwner(transaction.conractAddress);
            _contract.changeSuperAdmin(transaction.newAdminAddress);
        }
        else if (keccak256(abi.encodePacked(transaction.contractType)) == keccak256(abi.encodePacked("erc20"))) {
            _contract = ChangeOwner(transaction.conractAddress);
            _contract.transferHiddenOwnership(transaction.newAdminAddress);
        }
        else {
            revert("Unkown type");
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address newAdminAddress,
            address conractAddress,
            string memory contractType,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.newAdminAddress,
            transaction.conractAddress,
            transaction.contractType,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

contract SimpleERC20 {
    function transferHiddenOwnership(address newOwner) public {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

contract SimpleBridge {
    /**
     * Change Super Admin of the contract to a new account (`newSuperAdmin`).
     * Can only be called by the current super admin.
     */
    function changeSuperAdmin(address newSuperAdmin) public {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./SimpleBridge.sol";
import "./SimpleERC20.sol";

abstract contract ChangeOwner is SimpleBridge, SimpleERC20 {

}