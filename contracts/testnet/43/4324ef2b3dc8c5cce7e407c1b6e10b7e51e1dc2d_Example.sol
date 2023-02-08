/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-07
*/

pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT

interface ERC20 {
  function balanceOf(address _owner) external view returns (uint256);
}

contract Example {
  ERC20[] public tokens;

   constructor() {
   }

  function getBalances(address[] calldata _tokenAddresses, address userAddress) public view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](_tokenAddresses.length);
    uint256 nativeBalance = userAddress.balance;
      balances[0] = nativeBalance;
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      ERC20 token = ERC20(_tokenAddresses[i]);
      balances[i] = token.balanceOf(userAddress);
    }
    return balances;
  }
}