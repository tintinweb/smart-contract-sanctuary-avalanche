/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-21
*/

pragma solidity 0.8.6;



contract MockTarget {
    
    uint public x;
    address public addr;
    uint public y;


    function setX(uint newX) public {
        x = newX;
    }

    function setY(uint newY) public {
        y = newY;
    }


    receive() external payable {}
}