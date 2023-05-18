/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Factory {
    event CreateWallet(address indexed owner, uint256 nonce);

    function createWallet(address owner, uint256 nonce) external {
        emit CreateWallet(owner, nonce);
    }
}

contract Wallet {
    event ExecTransaction(
        bytes32 indexed hash,
        uint256 gasUsed,
        bool success,
        bytes data
    );

    event Receive(address indexed sender, uint256 amount);

    function execTransaction(
        bytes32 hash,
        uint256 gasUsed,
        bool success,
        bytes calldata data
    ) external {
        emit ExecTransaction(hash, gasUsed, success, data);
    }

    function _receive(address sender, uint256 amount) external {
        emit Receive(sender, amount);
    }
}

contract SgReceiver {
    struct Transaction {
        address owner;
        address tokenIn;
        address tokenOut;
        address receiver;
        uint256 amountOutMin;
        bytes32 relayersRoot;
    }

    event Deposit(
        bytes32 indexed _hash,
        address indexed _owner,
        Transaction _transaction,
        uint256 _balance,
        uint256 _total
    );

    function deposit(
        bytes32 _hash,
        address _owner,
        Transaction calldata _transaction,
        uint256 _balance,
        uint256 _total
    ) external {
        emit Deposit(_hash, _owner, _transaction, _balance, _total);
    }
}

contract ERC20 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    function transfer(address _from, address _to, uint256 _amount) external {
        emit Transfer(_from, _to, _amount);
    }
}

contract ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    function transfer(address _from, address _to, uint256 _tokenId) external {
        emit Transfer(_from, _to, _tokenId);
    }
}

contract Deployer {
    event Deploy(address _contract);
    
    constructor() {
        emit Deploy(address(new Factory()));
        emit Deploy(address(new Wallet()));
        emit Deploy(address(new SgReceiver()));
        emit Deploy(address(new ERC20()));
        emit Deploy(address(new ERC721()));
    }
}