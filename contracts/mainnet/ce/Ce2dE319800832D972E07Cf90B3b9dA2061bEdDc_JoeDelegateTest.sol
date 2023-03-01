// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract JoeDelegateTest {

  function run(bytes calldata data) public payable {
    address joepegs = 0xaE079eDA901F7727D0715aff8f82BA8295719977;
    (bool success, bytes memory data) = joepegs.delegatecall(data);
    require(success, "something failed");
  }

}