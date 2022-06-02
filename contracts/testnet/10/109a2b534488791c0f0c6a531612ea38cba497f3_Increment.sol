/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-02
*/

pragma solidity 0.8.6;



contract Increment {
    
    uint public x;
    address public addr;

    function increment(uint newX) public {
        x += newX;
    }

    receive() external payable {}
}