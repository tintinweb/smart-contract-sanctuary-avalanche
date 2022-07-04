/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract TestKeccak256 {


    function getKeccak256(address _account, uint256 _amount) external pure returns(bytes32) {
          bytes32 node = keccak256(abi.encodePacked(_account, _amount));
          return node;
    }


    function getAmountKeccak256(uint256 _amount) external pure returns(bytes32) {
          bytes32 amount = keccak256(abi.encodePacked(_amount));
          return amount;
    }


    function getNotDecodedAmount(uint256 _amountIn) external pure returns (uint256 USDCtoReceive) {
        return _amountIn;
    }

}