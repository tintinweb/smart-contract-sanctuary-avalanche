/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-17
*/

pragma solidity 0.8.7;



contract EthSender {
  function sendEthAtTime(uint time, address payable recipient) external payable {
    require(block.timestamp >= time, "Too soon");
    recipient.transfer(msg.value);
  }
}