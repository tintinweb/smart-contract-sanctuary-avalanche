//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./BoringERC20.sol";
import "./Libraries.sol";

// Adapted from MasterChefJoeV2 and Police And Thieves Vault
contract ParticleInfuser is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;
    using BoringERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Reward
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }


    IERC20 public lpToken; // Address of LP token contract.
    uint256 public lastRewardTimestamp; // Last timestamp that Reward distribution occurs.
    uint256 public accRewardTokenPerShare; // Accumulated Reward per share, times 1e12. See below.

    uint256 public baseRate = 17361111111111100; // 1500 * 1e18 / 86400

    uint256 public bonusEndTimestamp; // deadline of the vault

    IERC20 public rewardToken;
    // Reward tokens created per second.
    uint256 public manualRewardPerSecond;
    uint256 public rewardMultiplier = 5; // Multipler for the calculated emission per second
    uint256 public rewardMultiplierDivision = 10; // Multipler for the calculated emission per second

    uint256 public initialLPValue; // Initial number of LP tokens of AVAX-PIZZA
    uint256 public initialLPAvax; // Initial number of AVAX deposited in the LP

    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    
    function setStakeToken(IERC20 _stakeToken) external onlyOwner {
        require(!fountainStarted(), "Fountain is running");
        lpToken = _stakeToken;
    }

    function setRewardToken(IERC20 _rewardToken) external onlyOwner {
        require(!fountainStarted(), "Fountain is running");
        rewardToken = _rewardToken;
    }

    function setStartTimeStamp(uint256 _startTimestamp) external onlyOwner {
        require(!fountainStarted(), "Fountain is running");
        lastRewardTimestamp = _startTimestamp;
    }

        /// The block when rewards will end
    function setBonusEndTimestamp(uint256 _bonusEndTimestamp) external onlyOwner {
        require(_bonusEndTimestamp > bonusEndTimestamp, 'new bonus end block must be greater than current');
        bonusEndTimestamp = _bonusEndTimestamp;
    }

    // Returns calculated or manual rewards per second
    function getRewardPerSecond() public view returns (uint256) {
        if(manualRewardPerSecond > 0){
            return manualRewardPerSecond;
        }
        uint256 lpSupply = lpToken.balanceOf(address(this));

        return rewardPerSecondCalculation(lpSupply, initialLPValue, initialLPAvax, rewardMultiplier, rewardMultiplierDivision, baseRate);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndTimestamp) {
            return _to.sub(_from);
        } else if (_from >= bonusEndTimestamp) {
            return 0;
        } else {
            return bonusEndTimestamp.sub(_from);
        }
    }

    function fountainStarted() public view returns (bool) {
        return lastRewardTimestamp != 0 && bonusEndTimestamp != 0;
    }

    function rewardBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function depositedBalance() public view returns (uint256) {
        return lpToken.balanceOf(address(this));
    }

    // View function to see pending Token on frontend.
    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardToken = accRewardTokenPerShare;
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if (block.timestamp > lastRewardTimestamp && lpSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardTimestamp, block.timestamp);
            uint256 tokenReward = multiplier.mul(getRewardPerSecond());
            accRewardToken = accRewardToken.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accRewardToken).div(1e12).sub(user.rewardDebt);
    }

    function setInitialLPValue(uint256 _initialLPValue) external onlyOwner {
        initialLPValue = _initialLPValue;
    }

    function setInitialLPAvax(uint256 _initialLPAvax) external onlyOwner {
        initialLPAvax = _initialLPAvax;
    }

    function setRewardMultiplier(uint256 _rewardMultiplier) external onlyOwner {
        rewardMultiplier = _rewardMultiplier;
    }

    function setRewardMultiplierDivision(uint256 _rewardMultiplierDivision) external onlyOwner {
        rewardMultiplierDivision = _rewardMultiplierDivision;
    }
    
    function setBaseRate(uint256 _baseRate) external onlyOwner {
        baseRate = _baseRate;
    }
    
    
    function rewardPerSecondCalculation(uint256 _lpSupply, uint256 _initialLPValue, uint256 _initialLPAvax, uint256 _rewardMultiplier, uint256 _rewardMultiplierDivision, uint256 _baseRate) public pure returns (uint256) {
        if(_lpSupply == 0){
            return 0;
        }
        
        if(_initialLPValue == 0 || _initialLPAvax == 0 || _rewardMultiplier == 0 || _rewardMultiplierDivision == 0) {
            return _baseRate;
        }
        return _baseRate + _rewardMultiplier.mul(_lpSupply).mul(_initialLPAvax).div(_initialLPValue.mul(_rewardMultiplierDivision).mul(86400));
        
    }
    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public whenNotPaused {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = lpToken.balanceOf(address(this));

        if (lpSupply == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardTimestamp, block.timestamp);
        accRewardTokenPerShare = accRewardTokenPerShare.add(multiplier.mul(getRewardPerSecond()).mul(1e12).div(lpSupply));
        lastRewardTimestamp = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for Reward allocation.
    function deposit(uint256 _amount) public whenNotPaused nonReentrant {
        require(fountainStarted(), "You can't deposit yet");
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTokenTransfer(msg.sender, pending);
                emit Harvest(msg.sender, pending);
            }
        }
        
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accRewardTokenPerShare).div(1e12);

        if(_amount > 0) {
            lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        }
        emit Deposit(msg.sender, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) public whenNotPaused nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool();

        // Harvest Reward
        uint256 pending = user.amount.mul(accRewardTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeTokenTransfer(msg.sender, pending);
            emit Harvest(msg.sender, pending);
        }

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(accRewardTokenPerShare).div(1e12);

        if(_amount > 0) {
            lpToken.safeTransfer(address(msg.sender), _amount);
        }
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Safe Reward transfer function, just in case if rounding error causes pool to not have enough Reward.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (_amount > rewardBal) {
            rewardToken.safeTransfer(_to, rewardBal);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }

    function depositRewards(uint256 _amount) external {
        require(_amount > 0, 'Deposit value must be greater than 0.');
        rewardToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit DepositRewards(_amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardToken.balanceOf(address(this)), 'not enough rewards');
        // Withdraw rewards
        rewardToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    function setManualRewardPerSecond(uint256 _manualRewardPerSecond) external onlyOwner {
        manualRewardPerSecond = _manualRewardPerSecond;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

}