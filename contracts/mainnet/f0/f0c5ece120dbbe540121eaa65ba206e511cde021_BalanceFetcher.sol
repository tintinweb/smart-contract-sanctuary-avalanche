/**
 *Submitted for verification at snowtrace.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IERC20 {
  function balanceOf(address _owner) external view returns(uint256);
}

contract BalanceFetcher {
  function getBalances(address _owner, address[] calldata _tokens) external view returns (uint256[] memory balances) {
    balances = new uint256[](_tokens.length);
    
    for(uint256 i = 0; i < _tokens.length; i++) {
      if(!isContract(_tokens[i])) {
        continue;
      }
      try IERC20(_tokens[i]).balanceOf(_owner) returns(uint256 balance) {
        balances[i] = balance;
      } catch {}
    }
  }

  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}