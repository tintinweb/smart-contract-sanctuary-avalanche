/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-22
*/

// SPDX-License-Identifier: (Unlicense)
pragma solidity 0.8.4;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract over_og is Context {
    function setA(uint) public returns (uint) {}
    
    function a() public pure returns (uint) {}
}
contract Existing  {
    address t = 0xAE8546999A5d2c95a99C5b9D0cc4878C645dc402;
    over_og dc =  over_og(t);
    function existing(address _t) public {
        dc = over_og(_t);
    }
    function getA() public view returns (uint result) {
        return dc.a();
    }
    
}