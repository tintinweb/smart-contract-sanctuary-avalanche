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
    function res() public pure returns (uint[7] memory) {}
    
}
contract Existing  {
    
    over_og dc;
    
    function existing(address _t) public {
        dc = over_og(_t);
    }
    function getA() public view returns (uint[7] memory) {
        return dc.res();
    }
    
}