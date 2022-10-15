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
    address public ticketReceiver = 0x81DC56032e76eE14B3c76445da4e96D03397ecC3;

    // Farm Token
    address public walrusDrip = 0x8Df13374BE2c07528e0dB86084668d22d7Be31A9;

    // Amount To Burn
    uint256 public toBurn = 25;
    uint256 public toPrizePool = 10;


    function setWalrusDrip(address walrusDrip_) external onlyOwner {
        require(
            walrusDrip_ != address(0),
            'Zero Address'
        );
        walrusDrip = walrusDrip_;
    }

    function setTicketReceiver(address ticketReceiver_) external onlyOwner {
        require(
            ticketReceiver_ != address(0),
            'Zero Address'
        );
        ticketReceiver = ticketReceiver_;
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

        // fetch balance
        uint balance = IERC20(walrus).balanceOf(address(this));
        if (balance == 0) {
            return;
        }

        // split up amount to burn and reward
        uint amountToBurn = ( balance * toBurn ) / 100;
        uint amountForPrizePool = ( balance * toPrizePool ) / 100;

        // add to prizePool
        if (amountForPrizePool > 0) {
            // send amount to ticket receiver
            IERC20(walrus).transfer(ticketReceiver, amountForPrizePool);
        }

        // burn amount
        if (amountToBurn > 0) {
            IWalrus(walrus).burn(amountToBurn);
        }

        // amount to reward
        uint toReward = IERC20(walrus).balanceOf(address(this));

        // reward amount
        if (toReward > 0) {
            IERC20(walrus).transfer(walrusDrip, toReward);
        }

        // trigger farm distributor
        IWalrusDrip(walrusDrip).trigger();
    }
}