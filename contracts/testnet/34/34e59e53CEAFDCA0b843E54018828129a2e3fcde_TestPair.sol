/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestPair {
    event FlashSwap(
        address indexed sender,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event RegularSwap(
        address indexed sender,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external {
        if (data.length > 0) {
            emit FlashSwap(msg.sender, amount0Out, amount1Out, to);
        } else {
            emit RegularSwap(msg.sender, amount0Out, amount1Out, to);
        }
    }
}