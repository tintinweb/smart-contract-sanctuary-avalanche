//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
contract Storage {
    uint256 public x;
    function setX() public {
        x=6;
    }
    function getX() public view returns(uint256){
        return x;
    }
}