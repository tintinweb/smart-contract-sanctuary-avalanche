/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ValueContract {
    uint256 public value;

    function setValue(uint256 _value) public {
        value = _value;
    }

    function getValue() external view returns (uint256) {
        return value;
    }

    function checkValue() public payable {
        // require(msg.value != value, "Value sent didn't match the expected value");
        address receiver = address(payable(0xd74f09A800976ccF29857C3DcFB7829d988dE98c));
        sendViaCall(payable(receiver));
    }

    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, string(data));
    }
}