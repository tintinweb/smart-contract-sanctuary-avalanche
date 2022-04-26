pragma solidity 0.6.11;

import "./YetiMath.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

interface IveYETI {
    function totalYeti() external view returns (uint256);
    function getTotalYeti(address _user) external view returns (uint256);
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}



contract veYETIEmissions is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public yetiToken;
    IveYETI public veYETI;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);


    modifier onlyVeYeti() {
        require(msg.sender == address(veYETI));
        _;
    }


    // ========== EXTERNAL FUNCTIONS ==========


    bool private addressSet;
    function initialize(IERC20 _YETI, IveYETI _VEYETI) external {
        require(!addressSet, "Addresses already set");

        // require caller is yeti team multisig (only commented out right now to run tests)
        //require(msg.sender == 0xf572455BE31BF54Cc7D0c6D69B60813171bb7b12);

        addressSet = true;
        _transferOwnership(msg.sender);
        yetiToken = _YETI;
        veYETI = _VEYETI;
    }


    // update user rewards at the time of staking or unstakeing
    function updateUserRewards(address _user) external onlyVeYeti {
        _updateReward(_user);
    }


    // collect pending farming reward
    // approves veYETI to pull in the rewards for the user
    function getReward(address _user) external onlyVeYeti returns (uint) {
        _updateReward(_user);
        uint256 reward = earned(_user);
        if (reward > 0) {
            rewards[_user] = 0;
            yetiToken.approve(address(veYETI), reward);
            emit RewardPaid(_user, reward);
        }
        return reward;
    }


    /* Used to update reward rate by the owner
     * Owner can only update reward to a reward such that
     * there is enough Yeti in the contract to emit
     * _reward Yeti tokens across _duration
    */
    function notifyRewardAmount(uint256 _reward, uint256 _duration) external onlyOwner {
        _updateReward(address(0));
        require(
            (yetiToken.balanceOf(address(this)) >= _reward),
            "Insufficient YETI in contract");

        rewardRate = _reward.div(_duration);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(_duration);

        emit RewardAdded(_reward);
    }


    //  ========== INTERNAL FUNCTIONS ==========

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }


    //  ========== PUBLIC VIEW FUNCTIONS ==========


    function lastTimeRewardApplicable() public view returns (uint256) {
        return YetiMath._min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (veYETI.totalYeti() == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(veYETI.totalYeti())
        );
    }

    // earned Yeti Emissions
    function earned(address account) public view returns (uint256) {
        return
        veYETI.getTotalYeti(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    // returns how much Yeti you would earn depositing _amount for _time
    function rewardToEarn(uint _amount, uint _time) public view returns (uint256) {
        if (veYETI.totalYeti() == 0) {
            return rewardRate.mul(_time);
        }
        return rewardRate.mul(_time).mul(_amount).div(veYETI.totalYeti().add(_amount));
    }

}