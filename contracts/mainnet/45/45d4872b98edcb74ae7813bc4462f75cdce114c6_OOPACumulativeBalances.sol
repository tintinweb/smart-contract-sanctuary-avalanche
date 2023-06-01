// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


interface ITraitsLookUp {
    function countOopaStakedV2 (address user) external view returns (uint256 amount);
    function countOopaLockedV2 (address user) external view returns (uint256 amount);
    function countOopaLocked (address user) external view returns (uint256 amount);
}

interface IOOPA {
    function balanceOf(address _owner) external view returns (uint256);
}

contract OOPACumulativeBalances {

    ITraitsLookUp constant public LOOK_UP = ITraitsLookUp(0x3Af8D3cE23A90c4DbCa516cd3fC17CFA80365727);
    IOOPA constant public OOPA = IOOPA(0xb5d5B4cD4303d985D83C228644b9Ed10930a8152);

    function balanceOf(address _owner) external view returns (uint) {
        uint balance;
        balance+= LOOK_UP.countOopaStakedV2(_owner);
        balance+= LOOK_UP.countOopaLockedV2(_owner);
        balance+= LOOK_UP.countOopaLocked(_owner);
        balance+= OOPA.balanceOf(_owner);
        return balance;
    } 



}