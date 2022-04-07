/**
 *Submitted for verification at snowtrace.io on 2022-04-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface HighPoint {
    function balanceOf(address who) external view returns (uint256);

    function checkSwapThreshold() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}

contract HighPointRebaseResolver {
    address public immutable HIGHPOINT;

    constructor(address _highpoint) {
        HIGHPOINT = _highpoint;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        canExec = HighPoint(HIGHPOINT).balanceOf(0x8a0271333150dEaa50371dDBfe5404A9ef7dACE5) >= HighPoint(HIGHPOINT).checkSwapThreshold();

        execPayload = abi.encodeWithSelector(
            HighPoint.transfer.selector,
            0x8a0271333150dEaa50371dDBfe5404A9ef7dACE5,
            0
        );
    }
}