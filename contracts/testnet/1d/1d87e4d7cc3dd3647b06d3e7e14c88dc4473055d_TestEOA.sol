/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IEOA {
  function purchaseBundle(uint256 random) external payable;
}

contract TestEOA {
  
  constructor() public {
    
  }

  /**
   * @dev Returns the bep token owner.
   */
  function test(address addrSC, uint256 random) external payable {
    IEOA(addrSC).purchaseBundle(random);
  }

}