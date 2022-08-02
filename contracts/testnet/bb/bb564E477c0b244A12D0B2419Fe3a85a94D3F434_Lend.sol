// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Lend {
    function withdraw() public payable {
        require(block.timestamp < 1659627763, "Time conditions are not met");
    }

    function getAvailableTime() external pure returns (uint256 time) {
        return 1659627763;
    }

    function paymentStatus() external pure returns (string memory status) {
        return "waiting";
    }
}