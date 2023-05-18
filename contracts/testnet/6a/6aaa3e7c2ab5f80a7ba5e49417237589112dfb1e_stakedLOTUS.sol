// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC4626, ERC20} from "./ERC4626.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";

contract stakedLOTUS is ERC4626 {
    uint256 public storedTotalDeposits; //avoid inflation attack

    mapping(address => uint256) public timeCanUnlock;

    error StartTimer();

    constructor(ERC20 token_) ERC4626(token_, "stakedLOTUS", "stakedLOTUS") {}

    modifier checkTimer() {
        if (timeCanUnlock[msg.sender] == 0) revert StartTimer();

        if (
            block.timestamp > timeCanUnlock[msg.sender] &&
            block.timestamp - timeCanUnlock[msg.sender] < 1 days
        ) _;

        revert StartTimer();
    }

    function startTimer() external {
        timeCanUnlock[msg.sender] = block.timestamp + 1 days;
    }

    function totalAssets() public view override returns (uint256) {
        return
            storedTotalDeposits +
            (asset.balanceOf(address(this)) - storedTotalDeposits);
    }

    function beforeWithdraw(
        uint256 assets,
        uint256 shares
    ) internal override checkTimer {
        super.beforeWithdraw(assets, shares);

        timeCanUnlock[msg.sender] = 0;

        storedTotalDeposits -= assets;
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        timeCanUnlock[msg.sender] = 0;

        storedTotalDeposits += assets;

        super.afterDeposit(assets, shares);
    }
}