/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-23
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract MultiSigWallet {

    /**
        Note -> Create a overall info in the ui about Total tx created AND tx executed AND ether sent
    */

    uint8 public immutable required;

    mapping(address => bool) admins;
    address[] allAdmins;

    struct Tx {
        uint amount;
        address to;
        bool executed;
    }
    Tx[] txs;

    mapping(uint => mapping(address => bool)) sig;
    mapping(uint => uint) totalSigs;

    event NewTxCreated(uint indexed txId, address indexed creator, uint indexed time);
    event TxExecuted(uint indexed txId, address indexed executer, uint indexed time);
    event SignedTx(uint indexed txId, address indexed signer, uint indexed time);
    event UnSigndTtx(uint indexed txId, address indexed unSigner, uint indexed time);
    event Deposited(uint indexed amount, address indexed sender, uint indexed time);

    constructor(uint8 _num, address[] memory _admins) payable {
        require(_admins.length > 0, "Invalid array of admins");
        require(_num > 1 && _num <= _admins.length, "Required number is invalid");

        for (uint i; i < _admins.length; i++) {
            address adminAddr = _admins[i];
            require(adminAddr != address(0), "Zero address error");
            require(admins[adminAddr] == false, "Duplicate admin");

            admins[adminAddr] = true;
            allAdmins.push(adminAddr);
        }

        required = _num;
    }

    receive() external payable {
        emit Deposited(msg.value, msg.sender, block.timestamp);
    }

    function isAdmin(address _target) external view returns(bool) {
        return admins[_target];
    }

    function getAllAdmins() external view returns(address[] memory) {
        return allAdmins;
    }

    function getTx(uint _txId) external view returns(Tx memory) {
        return txs[_txId];
    }
    
    function getAllTxs() external view returns(Tx[] memory) {
        return txs;
    }

    function getSig(uint _txId, address _signer) external view returns(bool) {
        return sig[_txId][_signer];
    }

    function getTxTotalSignatures(uint _txId) external view returns(uint) {
        return totalSigs[_txId];
    }

    function deposit() external payable {
        require(msg.value > 0, "Zero ether value!");

        emit Deposited(msg.value, msg.sender, block.timestamp);
    }

    modifier onlyAdmins() {
        require(admins[msg.sender] == true, "Only admin");
        _;
    }

    bool lock;
    modifier NonReentrant() {
        require(lock == false, "Locked!");
        lock = true;
        _;
        lock = false;
    }

    // Note: We can do the same as below off-chain with events and it is better 
    // the below approach is gas-insufficient and it is only for testing purpose
    uint public totalTxExecuted;
    uint public totalEtherSent;
    modifier updateInfo(uint _txId) {
        require(_txId < txs.length, "Invalid Tx id");
        _;
        Tx memory txInfo = txs[_txId];
        totalEtherSent += txInfo.amount;
        totalTxExecuted += 1;
    }
    //

    function createNewTx(uint _amount, address _to) external onlyAdmins {
        uint size;
        assembly {
            size := extcodesize(_to)
        }
        require(size == 0, "Address Cannot Be A Contract!");

        Tx memory newTx = Tx({amount: _amount, to: _to, executed: false});

        txs.push(newTx);

        emit NewTxCreated(txs.length - 1, msg.sender, block.timestamp);
    }

    function signTx(uint _txId) external onlyAdmins {
        Tx memory txData = txs[_txId];

        require(_txId < txs.length, "Invalid Tx id");
        require(txData.executed == false, "Tx Already Executed");
        require(sig[_txId][msg.sender] == false, "Already Signed");

        sig[_txId][msg.sender] = true;
        totalSigs[_txId] += 1;

        emit SignedTx(_txId, msg.sender, block.timestamp);
    }

    function unsignTx(uint _txId) external onlyAdmins {
        Tx memory txData = txs[_txId];

        require(_txId < txs.length, "Invalid Tx id");
        require(txData.executed == false, "Tx Already Executed");
        require(sig[_txId][msg.sender] == true, "Already unSigned");

        sig[_txId][msg.sender] = false;
        totalSigs[_txId] -= 1;

        emit UnSigndTtx(_txId, msg.sender, block.timestamp);
    }

    function executeTx(uint _txId) external onlyAdmins NonReentrant updateInfo(_txId) {
        Tx storage txData = txs[_txId];
        require(txData.executed == false, "Tx Already Executed");
        require(totalSigs[_txId] >= required, "Insufficent Tx Signs");

        txData.executed = true;

        (bool result,) = payable(txData.to).call{value: txData.amount}("");
        require(result == true, "Something Went Wrong");

        emit TxExecuted(_txId, msg.sender, block.timestamp);
    }

}