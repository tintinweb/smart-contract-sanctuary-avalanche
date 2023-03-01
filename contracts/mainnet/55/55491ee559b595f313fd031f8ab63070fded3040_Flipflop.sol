/**
 *Submitted for verification at snowtrace.io on 2023-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Flipflop {
    bytes32 private constant PANIC = keccak256(bytes("PANIC"));
    address public constant ownooor = 0x0952082F15A762A9B21C73607303558B0e4bbE04;
    address public constant panicooor = 0x423b7E25459E147bc7e0AD3Ad370BA6DC5DE4494;
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
            return !panicked && mustPanic;
        }
        return false;
    }

    function panic() external payable notPanicked onlyPanicooor {
        panicked = true;
        mustPanic = false;
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