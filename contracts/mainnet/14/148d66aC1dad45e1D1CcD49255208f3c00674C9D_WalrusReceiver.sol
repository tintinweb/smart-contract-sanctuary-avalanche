//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";

interface IWalrus {
    function burn(uint amount) external;
}

interface IWalrusDrip {
    function trigger() external;
}

contract WalrusReceiver is Ownable {

    // Walrus Token Address
    address public constant walrus = 0x395908aeb53d33A9B8ac35e148E9805D34A555D3;

    // Farm Token
    address public walrusDrip;

    // Amount To Burn
    uint256 public toBurn = 25;

    function setWalrusDrip(address walrusDrip_) external onlyOwner {
        require(
            walrusDrip_ != address(0),
            'Zero Address'
        );
        walrusDrip = walrusDrip_;
    }

    function setBurnAllocation(uint toBurn_) external onlyOwner {
        require(
            toBurn_ <= 100,
            'ToBurn Too High'
        );
        toBurn = toBurn_;
    }

    function trigger() external {

        // fetch balance
        uint balance = IERC20(walrus).balanceOf(address(this));
        if (balance == 0) {
            return;
        }

        // split up amount to burn and reward
        uint amountToBurn = ( balance * toBurn ) / 100;
        uint toReward = balance - amountToBurn;

        // burn amount
        if (amountToBurn > 0) {
            IWalrus(walrus).burn(amountToBurn);
        }

        // reward amount
        if (toReward > 0) {
            IERC20(walrus).transfer(walrusDrip, toReward);
        }

        // trigger farm distributor
        IWalrusDrip(walrusDrip).trigger();
    }
}