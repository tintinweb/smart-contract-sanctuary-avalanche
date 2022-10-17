/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Forwarder  {

    address payable public immutable owner;
    bool private isPermanentDisabled;
    bool private isDepositsAllowed; 

    constructor() {
        owner = payable(msg.sender);
        isDepositsAllowed = true;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function permanentDisable() external ownerOnly {
        require(isPermanentDisabled == false, "forwarder already disabled");
        isPermanentDisabled = true;
    }

    function toggleDepositStatus(bool status) external ownerOnly {
        isDepositsAllowed = status;
    }

    function isForwarderDepositable() external view returns (bool) {
        return (!isPermanentDisabled && isDepositsAllowed);
    }

    receive() external payable {
        require(isDepositsAllowed == true && isPermanentDisabled == false, "deposits are disbled");
        owner.transfer(msg.value);
    }

    fallback(bytes calldata _input) external payable returns (bytes memory _output) {
        require(_input.length == 0, "no input data allowed");

        return "";
    }

}