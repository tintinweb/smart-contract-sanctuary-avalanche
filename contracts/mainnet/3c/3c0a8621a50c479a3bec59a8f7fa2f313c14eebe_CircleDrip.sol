/**
 *Submitted for verification at snowtrace.io on 2022-12-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

pragma solidity 0.8.14;


interface IFarm {
    function depositRewards(uint256 amount) external;
}

contract CircleDrip is Ownable {

    /** Constants */
    address public constant circle = 0xaba658AB5FFA292e3DF464dE5cB141c7de83DB6D;
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
        return IERC20(circle).balanceOf(address(this));
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
        uint bal = IERC20(circle).balanceOf(address(this));
        if (amount > bal) {
            amount = bal;
        }
        if (amount == 0) {
            return;
        }
        if (to == farm) {
            IERC20(circle).approve(farm, amount);
            IFarm(farm).depositRewards(amount);
        } else {
            IERC20(circle).transfer(to, amount);
        }
    }
}