/**
 *Submitted for verification at snowtrace.io on 2023-02-17
*/

/**
 *Submitted for verification at snowtrace.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Flipflop {
    bytes32 private constant PANIC = keccak256(bytes("PANIC"));
    address public constant ownooor = 0x05cF59dd28EAEf2Aa18A461BF4C4973fD06C2e3C;
    address public constant panicooor = 0xF312197F0f39ae4EF067adf962A453cCC153F54e;
    bool public panicked = false;
    bool public mustPanic = false;

    event Panic(address);

    modifier onlyOwnooor() {
        require(tx.origin == ownooor, "You are not the ownooor sir");
        _;
    }

    modifier onlyPanicooor() {
        require(tx.origin == panicooor, "You are not the panicooor sir");
        _;
    }

    modifier notPanicked() {
        require(panicked == false, "We are panicked sir");
        _;
    }

    function checkTriggeringRule(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded)
    {
        if (keccak256(checkData) == PANIC) {
            return mustPanic;
        }
        return false;
    }

    function panic() external payable notPanicked onlyPanicooor {
        panicked = true;
        emit Panic(msg.sender);
    }

    function reset() external onlyOwnooor {
        panicked = false;
        mustPanic = false;
    }

    function setMustPanic(bool _mustPanic) external onlyOwnooor {
        mustPanic = _mustPanic;
    }
}