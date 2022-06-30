/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-30
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File contracts/interfaces/IAMBInformationReceiver.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IAMBInformationReceiver {
    function onInformationReceived(bytes32 messageId, bool status, bytes calldata result) external;
}


// File contracts/interfaces/IHomeAMB.sol


pragma solidity ^0.8.12;

interface IHomeAMB {
    function requireToGetInformation(bytes32 _requestSelector, bytes calldata _data) external returns (bytes32);
}


// File contracts/AMBInformationReceiverStorage.sol


pragma solidity ^0.8.12;

contract AMBInformationReceiverStorage {
    IHomeAMB immutable bridge;
    
    enum Status {
        Unknown,
        Pending,
        Ok,
        Failed
    }
    
    mapping(bytes32 => Status) public status;
    bytes32 public lastMessageId;
    
    constructor(IHomeAMB _bridge) {
        bridge = _bridge;
    }
    
}


// File contracts/BasicAMBInformationReceiver.sol


pragma solidity ^0.8.12;


abstract contract BasicAMBInformationReceiver is IAMBInformationReceiver, AMBInformationReceiverStorage {
    function onInformationReceived(bytes32 _messageId, bool _status, bytes memory _result) external override {
        require(msg.sender == address(bridge));
        if (_status) {
            onResultReceived(_messageId, _result);
        }
        status[_messageId] = _status ? Status.Ok : Status.Failed;
    }
    
    function onResultReceived(bytes32 _messageId, bytes memory _result) virtual internal;
}


// File contracts/SimpleGetBalaceInvoker.sol


pragma solidity ^0.8.12;

contract SimpleGetBalaceInvoker is BasicAMBInformationReceiver {
    mapping(bytes32 => uint256) public response;

    constructor(IHomeAMB _bridge) AMBInformationReceiverStorage(_bridge) {}
    
    function requestBalance(address _account) external {
        bytes32 selector = keccak256("eth_getBalance(address)");
        bytes memory data = abi.encode(_account);
        lastMessageId = bridge.requireToGetInformation(selector, data);
        
        status[lastMessageId] = Status.Pending;
    }

    function onResultReceived(bytes32 _messageId, bytes memory _result) internal override {
        require(_result.length == 32);
        response[_messageId] = abi.decode(_result, (uint256));
    }
}