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
    function getTokenPrice() public view returns(uint[7] memory result) {}
    function a() public pure returns (uint) {}
}
contract Existing  {
    address t = 0x843814aF5229F4627FfEA5fC4cDd4208a25577c3;
    over_og dc =  over_og(t);
    function existing(address _t) public {
        dc = over_og(_t);
    }
    function getEm() public view returns (uint[7] memory result) {
        return dc.getTokenPrice();
    }
    
}