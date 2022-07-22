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
abstract contract Deployed is Context {
    
    function setA(uint) public returns (uint) {}

    function ret() public pure returns (uint[7] memory) {}
    
}
contract Existing_seer  {
    
    Deployed dc;
    
    function existing(address _t) public {
        dc = Deployed(_t);
    }
 
    function getTokenPrice() public view returns (uint[7] memory) {
        return dc.ret();
    }
    
    function setA(uint _val) public returns (uint result) {
        dc.setA(_val);
        return _val;
    }
    
}