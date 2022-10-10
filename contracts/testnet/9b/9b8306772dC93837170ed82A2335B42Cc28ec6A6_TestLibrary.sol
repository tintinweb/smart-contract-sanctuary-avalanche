pragma solidity ^0.5.15;

library TestLibrary {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }

    function libID() pure external returns (string memory) {
        return "0x0416B9A530c972dAa1280B4cE00b19E0b449df17";
    }
}