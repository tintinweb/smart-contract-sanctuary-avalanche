/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-05
*/

pragma solidity ^0.8.0;

contract BatchETHSender {
    function batchTransfer(address payable[] memory recipients, uint256 amount) public payable {
        require(msg.value == amount * recipients.length, "Insufficient ETH balance.");
        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amount);
        }
    }
}