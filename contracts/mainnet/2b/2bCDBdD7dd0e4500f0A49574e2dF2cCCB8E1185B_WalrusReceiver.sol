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

interface IXWalrus {
    function mint(uint256 amountWalrus) external;
}

contract WalrusReceiver is Ownable {

    // Walrus Token Address
    address public constant walrus = 0x395908aeb53d33A9B8ac35e148E9805D34A555D3;
    address public constant xWalrus = 0x2dc3Bb328000553D1D64ec1BEF00572F62B5Ec7C;

    // Walrus prizePool
    address public prizePool = 0x30c0328A9b427E7450DBB625f977F914D46AC5b5;

    // Farm Token
    address public walrusDrip = 0x8Df13374BE2c07528e0dB86084668d22d7Be31A9;

    // Amount To Burn
    uint256 public toBurn = 25;
    uint256 public toPrizePool = 10;

    // Already entered Trigger
    bool private entered = false;

    function setWalrusDrip(address walrusDrip_) external onlyOwner {
        require(
            walrusDrip_ != address(0),
            'Zero Address'
        );
        walrusDrip = walrusDrip_;
    }

    function setPrizePool(address prizePool_) external onlyOwner {
        require(
            prizePool_ != address(0),
            'Zero Address'
        );
        prizePool = prizePool_;
    }

    function setBurnAllocation(uint toBurn_) external onlyOwner {
        require(
            toBurn_ <= 100,
            'ToBurn Too High'
        );
        toBurn = toBurn_;
    }

    function setPrizePoolAllocation(uint forPrizePool_) external onlyOwner {
        require(
            forPrizePool_ <= 100,
            'ToBurn Too High'
        );
        toPrizePool = forPrizePool_;
    }

    function trigger() external {
        
        // return if entered to prevent infinite loop
        if (entered) {
            return;
        }

        // enter
        entered = true;

        // fetch balance
        uint balance = IERC20(walrus).balanceOf(address(this));
        if (balance == 0) {
            return;
        }

        // split up amount to burn and reward
        uint amountToBurn = ( balance * toBurn ) / 100;
        uint amountForprizePool = ( balance * toPrizePool ) / 100;
        uint toReward = balance - ( amountToBurn + amountForprizePool );

        // add to prizePool
        if (amountForprizePool > 0) {
            // approve and mint xWalrus
            IERC20(walrus).approve(xWalrus, amountForprizePool);
            IXWalrus(xWalrus).mint(amountForprizePool);

            // send amount to prizePool
            IERC20(xWalrus).transfer(prizePool, IERC20(xWalrus).balanceOf(address(this)));
        }

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

        // exit
        entered = false;
    }
}