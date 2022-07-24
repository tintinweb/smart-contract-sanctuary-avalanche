/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-22
*/

pragma solidity ^0.8.0;

contract FanFiMock {

    struct User{
        uint256 stakeAmount;
        uint256 unstakeTimestamp;
        uint256 reward;
        uint256 schemeID;
    }

    mapping(address => User) users;
    
    event Stake(address indexed userAddress, uint256 stakeAmount, uint256 schemeID);
    event Unstake(address indexed userAddress, uint256 unstakeAmount, uint256 schemeID);
    event Redeem(address indexed userAddress, uint256 redeemAmount, uint256 schemeID);

    function getUser(address userAddress) external view returns(User memory) {
        return users[userAddress];
    }

    function stake(uint256 amount, uint256 schemeID) external {
        require(users[msg.sender].stakeAmount == 0 && users[msg.sender].unstakeTimestamp == 0, "Staking is already active");
        User memory user;
        user.stakeAmount = amount;
        user.schemeID = schemeID;
        users[msg.sender] = user;
        emit Stake(msg.sender, amount, schemeID);
    }

    function unstake() external {
        User memory user = users[msg.sender];
        uint unstakeAmount = user.stakeAmount;
        require(unstakeAmount > 0, "Staking is not active");
        delete user.stakeAmount;
        user.reward = 100;
        user.unstakeTimestamp = block.timestamp;
        users[msg.sender] = user;
        emit Unstake(msg.sender, unstakeAmount, user.schemeID);
    }

    function redeem() external {
        User memory user = users[msg.sender];
        require(user.unstakeTimestamp > 0, "No redeemable rewards");
        uint reward = user.reward;
        uint schemeID = user.schemeID;
        delete users[msg.sender];
        emit Redeem(msg.sender, reward, schemeID);
    }


}