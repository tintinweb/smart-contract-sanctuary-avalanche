/**
 *Submitted for verification at snowtrace.io on 2022-04-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MockTarget {

    uint public x;
    address public addr;
    uint public y;    
    int private count = 0;

    function incrementCounter() public {
        count += 1;
    }
    function decrementCounter() public {
        count -= 1;
    }
    function setX(uint newX) public {
        x = newX;
    }
    function setY(uint newY) public {
        y = newY;
    }

    function getCount() public view returns (int) {
        return count;
    }
}