// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract JoeCallTest {

  function run(bytes calldata data) public payable {
    address joepegs = 0xaE079eDA901F7727D0715aff8f82BA8295719977;
    (bool success, bytes memory _data) = joepegs.call{value: msg.value}(data);
    require(success, "something failed");
  }

  function claim() public {
    payable(msg.sender).transfer(address(this).balance);
  }

}