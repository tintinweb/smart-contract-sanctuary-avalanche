// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract JoeCallTest {

  function run(bytes calldata data) public payable {
    address joepegsAdapter = 0x8F7E2d1e7E7B2B0BB91F93A4c6a255795bF03181;
    (bool success, bytes memory _data) = joepegsAdapter.call{value: msg.value}(data);
    require(success, "something failed");
  }

  function claim() public {
    payable(msg.sender).transfer(address(this).balance);
  }

}