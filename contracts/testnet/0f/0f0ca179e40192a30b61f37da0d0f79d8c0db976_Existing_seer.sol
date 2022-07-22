/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-22
*/

// SPDX-License-Identifier: (Unlicense)
pragma solidity 0.8.13;
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
    function getTokenPrice() public returns (uint[7] memory) {}
    function a() public pure returns (uint) {}
    
}
contract Existing_seer  {
    
    over_og dc;
    
    function existing(address _t) public {
        dc = over_og(_t);
    }
 
    function getTokenPrice() public view returns (uint result) {
        return dc.a();
    }
    
    function setA(uint _val) public returns (uint result) {
        dc.setA(_val);
        return _val;
    }
    
}