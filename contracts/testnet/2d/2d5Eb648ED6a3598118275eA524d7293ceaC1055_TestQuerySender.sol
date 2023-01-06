/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface TestRecipient {
    function getAddress(uint256 num) external returns(address);
}

struct Call {
    address to;
    bytes data;
}

interface IInterchainQueryRouter {
    function query(
        uint32 _destinationDomain,
        Call calldata call,
        bytes calldata callback
    ) external;
}

interface IOutbox {
    function dispatch(
        uint32 destinationDomainId,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external returns (uint256);
}

contract TestQuerySender {
    uint32 public originDomainId;
    uint32 public destinationDomainId;
    address public recipientAddress;
    IInterchainQueryRouter public queryRouter;
    IOutbox public outbox;

    address public queryResult;
    event QuerySent(uint32 destinationDomainId, address recipientAddress, uint256 num);
    event QueryReceived(address result);

    modifier onlyQueryRouter() {
        require(msg.sender == address(queryRouter), "error_onlyQueryRouter");
        _;
    }

    /**
     * @param _originDomainId - the domain id of the chain the message is sent from
     * @param _destinationDomainId - the domain id of the chain the message is send to
     * @param _recipientAddress - the address of the recipient contract
     * @param _queryRouter - hyperlane query router for the origin chain
     * @param _outboxAddress - hyperlane core address for the chain where recipient contract is deployed
     */
    constructor(uint32 _originDomainId, uint32 _destinationDomainId, address _recipientAddress, address _queryRouter, address _outboxAddress) {
        originDomainId = _originDomainId;
        destinationDomainId = _destinationDomainId;
        recipientAddress = _recipientAddress;
        outbox = IOutbox(_outboxAddress);
        queryRouter = IInterchainQueryRouter(_queryRouter);
    }

    function queryNumber(uint256 num) public {
        queryRouter.query(
            destinationDomainId,
            Call({to: recipientAddress, data: abi.encodeCall(TestRecipient.getAddress, (num))}),
            abi.encodePacked(this.handleQueryAddressResult.selector)
        );
        emit QuerySent(destinationDomainId, recipientAddress, num);
    }

    function handleQueryAddressResult(address _result) public { // onlyQueryRouter
        queryResult = _result;
        emit QueryReceived(_result);
        // dispatchMessage(_result);
    }

    function dispatchMessage(address _message) public {
        outbox.dispatch(
            destinationDomainId,
            _addressToBytes32(recipientAddress),
            abi.encode(_message)
        );
    }

    function _addressToBytes32(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}