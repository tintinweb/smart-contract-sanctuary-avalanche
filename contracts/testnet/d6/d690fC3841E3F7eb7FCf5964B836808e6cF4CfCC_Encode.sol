// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
pragma abicoder v2;


/// @title A LayerZero example sending a cross chain message from a source chain to a destination chain to increment a counter
contract Encode {
   
   function encode(address _receive, uint256 amount) public view returns(bytes memory){
       return abi.encode(_receive, amount);
   }

}