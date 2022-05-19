/**
 *Submitted for verification at snowtrace.io on 2022-05-19
*/

pragma solidity ^0.8.0;

contract setNumberContract{
    address reserved;
    uint256 public number;
    
    function setNumber(uint256 _number) public {
        number = _number + 1;
    }
}