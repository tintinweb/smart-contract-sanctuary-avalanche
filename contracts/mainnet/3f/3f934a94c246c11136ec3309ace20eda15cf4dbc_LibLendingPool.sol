// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IPool.sol";
import "./IERC20.sol";

library LibLendingPool {
    IPool constant lendingPool = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    function supply(address token, uint256 supplyAmount) external {
        lendingPool.supply(token, supplyAmount, address(this), 0);
    }

    function withdraw(address token, uint256 withdrawalAmount, address to) external {
        lendingPool.withdraw(token, withdrawalAmount, to);
    }
    
    function approve(address _token, uint256 amount) external {
        IERC20(_token).approve(address(lendingPool), amount);
    }
}