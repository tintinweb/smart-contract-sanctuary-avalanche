/**
 *Submitted for verification at snowtrace.io on 2023-04-15
*/

// SPDX-License-Identifier: MIT
//
//
//  /$$$$$$   /$$$$$$  /$$$$$$$         /$$$$$$   /$$                /$$      /$$                          
// /$$__  $$ /$$__  $$| $$__  $$       /$$__  $$ | $$               | $$     |__/                          
// | $$  \__/| $$  \ $$| $$  \ $$      | $$  \__//$$$$$$    /$$$$$$ | $$   /$$ /$$ /$$$$$$$   /$$$$$$       
// |  $$$$$$ | $$  | $$| $$$$$$$       |  $$$$$$|_  $$_/   |____  $$| $$  /$$/| $$| $$__  $$ /$$__  $$      
//  \____  $$| $$  | $$| $$__  $$       \____  $$ | $$      /$$$$$$$| $$$$$$/ | $$| $$  \ $$| $$  \ $$      
// /$$  \ $$| $$  | $$| $$  \ $$        /$$  \ $$ | $$ /$$ /$$__  $$| $$_  $$ | $$| $$  | $$| $$  | $$      
// |  $$$$$$/|  $$$$$$/| $$$$$$$/      |  $$$$$$/ |  $$$$/|  $$$$$$$| $$ \  $$| $$| $$  | $$|  $$$$$$$      
// \______/  \______/ |_______/        \______/   \___/   \_______/|__/  \__/|__/|__/  |__/ \____  $$      
//                                                                                          /$$  \ $$      
//                                                                                         |  $$$$$$/      
//  SOB Staking v0.1 By 0xUrkel                                                             \______/    

pragma solidity ^0.8.0;

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract SOBStaking {
    Token public SOBToken;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakedTime;
    uint256 public totalStaked;
    uint256 public constant stakingFee = 100; // 1% staking fee
    uint256 public constant rewardRate = 100; // 1% reward rate
    uint256 public constant rewardInterval = 1 weeks; // 1 week reward interval
    //Call (774) 538-9935 for a good time
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event RewardClaimed(address indexed staker, uint256 amount);

    constructor(address _SOBToken) {
        SOBToken = Token(_SOBToken);
    }

    function stake(uint256 _amount) external {
        require(SOBToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");

        uint256 fee = (_amount * stakingFee) / 10000; // Calculate the staking fee
        uint256 stakedAmount = _amount - fee; // Calculate the amount of tokens to be staked

        require(SOBToken.approve(address(this), _amount), "Approval failed"); // Approve the contract to transfer tokens from the sender's account

        require(SOBToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        stakedBalance[msg.sender] += stakedAmount;
        lastStakedTime[msg.sender] = block.timestamp;
        totalStaked += stakedAmount;

        emit Staked(msg.sender, stakedAmount);
    }
    //To Do
    // Laundry
    // Dishes
    // Buy english muffins

    function unstake(uint256 _amount) external {
        require(stakedBalance[msg.sender] >= _amount, "Insufficient staked balance");

        uint256 fee = (_amount * stakingFee) / 10000; // Calculate the staking fee
        uint256 unstakedAmount = _amount - fee; // Calculate the amount of tokens to be unstaked

        stakedBalance[msg.sender] -= _amount;
        totalStaked -= _amount;

        require(SOBToken.transfer(msg.sender, unstakedAmount), "Token transfer failed");

        emit Unstaked(msg.sender, unstakedAmount);
    }

    function claimReward() external {
        require(stakedBalance[msg.sender] > 0, "No staked balance");

        uint256 reward = calculateReward(msg.sender);
        lastStakedTime[msg.sender] = block.timestamp;
        
        require(SOBToken.transfer(msg.sender, reward), "Token transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address _staker) public view returns (uint256) {
        uint256 stakedTime = block.timestamp - lastStakedTime[_staker];
        uint256 stakedAmount = stakedBalance[_staker];

        return (stakedAmount * rewardRate * stakedTime) / (10000 * rewardInterval);
    }
        //That's all, no widthdraw so stake and get the rewards or tokens will just stay locked in the contract out of circualtion
        //Did I do that?

}