/**
 *Submitted for verification at snowtrace.io on 2022-05-20
*/

pragma solidity 0.8.13;

interface Token {
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface Pair {
    function sync() external;
}

// SPDX-License-Identifier: MIT

contract PairHelpers {

    function transferAndSync(address pair, address token, uint256 amount) external {
        Token(token).transferFrom(msg.sender, pair, amount);
        Pair(pair).sync();
    }

}