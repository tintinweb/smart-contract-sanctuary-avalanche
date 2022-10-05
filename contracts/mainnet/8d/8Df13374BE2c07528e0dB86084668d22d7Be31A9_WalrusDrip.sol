//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";

interface IFarm {
    function depositRewards(uint256 amount) external;
}

contract WalrusDrip is Ownable {

    /** Constants */
    address public constant walrus = 0x395908aeb53d33A9B8ac35e148E9805D34A555D3;
    uint256 public constant bountyDenom = 10**5;

    /** Farm To Receive Rewards */
    address public farm;

    /** Percent out of 10^18 of rewards per second */
    uint256 public percentPerSecond = 289351851851;

    /** 50% Is Largest Percent In One Trigger */
    uint256 public largestPercentPerTrigger = 5 * 10**17;

    /** Timestamp of last reward */
    uint256 public lastReward;

    /** Bounty Percentage */
    uint256 public bountyPercent = 500;

    constructor(address farm_) {
        lastReward = block.timestamp;
        farm = farm_;
    }

    function resetRewardTimer() external onlyOwner {
        lastReward = block.timestamp;
    }

    function setFarm(address newFarm) external onlyOwner {
        require(newFarm != address(0), 'Zero Address');
        farm = newFarm;
    }

    function setEmissionPercentPerSecond(uint newDaily) external onlyOwner {
        percentPerSecond = newDaily;
    }

    function setLargestPercentPerTrigger(uint newLargest) external onlyOwner {
        largestPercentPerTrigger = newLargest;
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function withdrawAmount(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function setBountyPercent(uint newPercent) external onlyOwner {
        require(newPercent <= bountyDenom / 2, 'Bounty Too High');
        bountyPercent = newPercent;
    }

    function trigger() external {

        // amount to reward
        uint amount = amountToDistribute();

        // bounty percent
        uint bounty = ( amount * bountyPercent ) / bountyDenom;
    
        // reset timer
        lastReward = block.timestamp;

        // process bounty
        if (bounty > 0) {
            amount = amount - bounty;
            _send(msg.sender, bounty);
        }

        // send reward to the vault
        _send(farm, amount);
    }

    function balanceOf() public view returns (uint256) {
        return IERC20(walrus).balanceOf(address(this));
    }

    function timeSince() public view returns (uint256) {
        return lastReward < block.timestamp ? block.timestamp - lastReward : 0;
    }

    function amountToDistribute() public view returns (uint256) {
        uint percent = timeSince() * percentPerSecond;
        if (percent > largestPercentPerTrigger) {
            percent = largestPercentPerTrigger;
        }
        return ( balanceOf() * percent ) / 10**18;
    }

    function amountPerSecond() public view returns (uint256) {
        return ( balanceOf() * percentPerSecond ) / 10**18;
    }

    function currentBounty() public view returns (uint256) {
        return ( amountToDistribute() * bountyPercent ) / bountyDenom;
    }

    function _send(address to, uint amount) internal {
        uint bal = IERC20(walrus).balanceOf(address(this));
        if (amount > bal) {
            amount = bal;
        }
        if (amount == 0) {
            return;
        }
        if (to == farm) {
            IERC20(walrus).approve(farm, amount);
            IFarm(farm).depositRewards(amount);
        } else {
            IERC20(walrus).transfer(to, amount);
        }
    }
}