// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


contract EstimateGasFeature {

    struct ERC20Pair {
        address token;
        uint256 amount;
    }

    function estimateGasBatchBuyWithETH(bytes calldata tradeBytes) external payable returns(uint256) {
        assembly {
            mstore(0, 0x5d578816)
            calldatacopy(0x20, 0x1c, sub(calldatasize(), 0x4))
            if delegatecall(gas(), address(), 0x4, calldatasize(), 0, 0) {
                mstore(0, gas())
                return(0, 0x20)
            }
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    function estimateGasBatchBuyWithERC20s(
        ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external payable returns(uint256) {
        assembly {
            mstore(0, 0x5d578816)
            calldatacopy(0x20, 0x1c, sub(calldatasize(), 0x4))
            if delegatecall(gas(), address(), 0x4, calldatasize(), 0, 0) {
                mstore(0, gas())
                return(0, 0x20)
            }
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }
}