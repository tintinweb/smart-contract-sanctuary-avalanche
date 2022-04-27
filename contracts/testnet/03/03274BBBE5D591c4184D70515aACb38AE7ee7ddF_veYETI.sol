pragma solidity 0.8.13;

import "../Interfaces/IERC20_8.sol";
import "../Interfaces/IveYETI_8.sol";


interface IEmitter {
    function updateUserRewards(address _user) external;
}


contract veYETI is IveYETI {

    uint256 constant _1e18 = 1e18;
    uint256 constant _totalYetiSupply = 500e24;

    IERC20 public yetiToken;
    address yetiController;

    // Global Stats:
    uint256 public totalYeti;
    uint256 public accumulationRate; // veYETI accumulated per second per staked YETI

    // With an accumulation of 0.015 veYETI per YETI per hour, accumulationRate would be 25e13 veYETI per YETI per second. 
    // 25e13 * (entire YETI supply = 500,000,000e18) * 86400 seconds per day * 4 * 365 = 1.5768e49
    // Max uint = 1.1579e77 so the veYETI max is not close to that. To get veYETI balance actually it is / 1e36. 

    bool isSetup;


    /* UserInfo:
        -totalYeti is the total amount of YETI that the user has staked
        -yetiStakes[x] is the amount of YETI staked on rewarder with address x
        -lastUpdate is when all the variables were last updated for the user.
         This is the last time the user called update()
        -lastTotalVeYeti is the user's total veYETI balance at the last update
    */
    struct UserInfo {
        uint256 totalYeti;
        mapping(address => uint256) yetiStakes;

        uint256 lastUpdate;
        uint256 lastTotalVeYeti;
    }

    struct RewarderUpdate {
        address rewarder;
        uint256 amount;
        bool isIncrease;
    }

    mapping(address => bool) isWhitelistedContract;
    mapping(address => UserInfo) users; // info on each user's staked YETI

    // ===== NEW VARIABLES =====

    IEmitter emitter;

    event UpdatedWhitelistedContracts(address _contractAddress, bool _isWhitelisted);


    modifier onlyYetiController() {
        require(msg.sender == address(yetiController), "veYETI: Caller is not YetiController");
        _;
    }


    function setup(IERC20 _yeti, address _yetiController, uint256 _accumulationRate) external {
        require(!isSetup, "veYETI: already setup");
        yetiToken = _yeti;
        yetiController = _yetiController;
        accumulationRate = _accumulationRate;
        isSetup = true;
    }


    // ============= OnlyController External Mutable Functions =============


    function updateWhitelistedCallers(address _contractAddress, bool _isWhitelisted) external onlyYetiController {
        isWhitelistedContract[_contractAddress] = _isWhitelisted;
        emit UpdatedWhitelistedContracts(_contractAddress, _isWhitelisted);
    }


    // ============= External Mutable Functions  =============


    /** Can use update() to:
      * stake or unstake more YETI overall and/or
      * reallocate current YETI to be staked on different rewarders
    */ 
    function update(RewarderUpdate[] memory _yetiAdjustments) external {
        _requireValidCaller();

        emitter.updateUserRewards(msg.sender); // @RoboYeti: just added

        UserInfo storage userInfo = users[msg.sender];

        (bool _isStakeIncrease, uint256 _stakeAmount) = _getAmountChange(_yetiAdjustments);

        // update user's lastTotalVeYeti
        // accounts for penalty if _stake is false (net un-stake)
        _accumulate(msg.sender, _isStakeIncrease);

        // update Yeti stakes on each rewarder
        _allocate(msg.sender, _yetiAdjustments);

        // update global totalYeti, totalYeti for user, and pull in or send back YETI
        // based on if user is adding to or removing from their stake
        _handleStaking(userInfo, _isStakeIncrease, _stakeAmount);

        userInfo.lastUpdate = block.timestamp;
    }


    // ============= Public/External View Functions  =============


    // returns how much veYETI a user currently has accumulated on a rewarder
    function getUserYetiOnRewarder(address _user, address _rewarder) external view override returns (uint256) {
        return users[_user].yetiStakes[_rewarder];
    }


    // returns how much veYETI a user currently has accumulated on a rewarder
    function getVeYetiOnRewarder(address _user, address _rewarder) external view override returns (uint256) {
        UserInfo storage userInfo = users[_user];
        if (userInfo.totalYeti == 0) {
            return 0;
        }
        uint256 currentVeYeti = getTotalVeYeti(_user);
        return currentVeYeti * userInfo.yetiStakes[_rewarder] / userInfo.totalYeti;
    }


    // get user's total accumulated veYETI balance (across all rewarders)
    function getTotalVeYeti(address _user) public view returns (uint256) {
        UserInfo storage userInfo = users[_user];
        uint256 dt = block.timestamp - userInfo.lastUpdate;
        uint256 veGrowth = userInfo.totalYeti * accumulationRate * dt;
        return userInfo.lastTotalVeYeti + veGrowth;
    }


    // ============= Internal Mutable Functions  =============


    /**
     * accumulate/update user's lastTotalVeYeti balance
     */
    function _accumulate(address _user, bool _isStakeIncrease) internal {
        UserInfo storage userInfo = users[_user];

        if (_isStakeIncrease) {
            // calculate total veYETI gained since last update time
            // and update lastTotalveYETI accordingly
            uint256 dt = block.timestamp - userInfo.lastUpdate;
            uint256 veGrowth = userInfo.totalYeti * accumulationRate * dt;
            userInfo.lastTotalVeYeti = userInfo.lastTotalVeYeti + veGrowth;
        } else {
            // lose all accumulated veYETI if unstaking
            userInfo.lastTotalVeYeti = 0;
        }
    }


    /**
     * allocate Yeti to rewarders
     */
    function _allocate(address _user, RewarderUpdate[] memory _yetiAdjustments) internal {
        UserInfo storage userInfo = users[_user];
        uint256 nAdjustments = _yetiAdjustments.length;

        // update Yeti allocations
        for (uint i; i < nAdjustments; i++) {

            address rewarder = _yetiAdjustments[i].rewarder;
            bool isIncrease = _yetiAdjustments[i].isIncrease;
            uint256 amount = _yetiAdjustments[i].amount;

            if (isIncrease) {
                userInfo.yetiStakes[rewarder] += amount;
            } else {
                require(userInfo.yetiStakes[rewarder] >= amount, "veYETI: insufficient Yeti staked on rewarder");
                userInfo.yetiStakes[rewarder] -= amount;
            }
        }
    }


    /**
     * send in or send out staked YETI from this contract
     * and update user's and global variables
     */
    function _handleStaking(UserInfo storage userInfo, bool _isIncreaseStake, uint _amount) internal {
        if (_amount > 0) {

            if (_isIncreaseStake) {
                // pull in YETI tokens to stake
                require(yetiToken.transferFrom(msg.sender, address(this), _amount));
                userInfo.totalYeti += _amount;
                totalYeti += _amount;
            } else {
                require(userInfo.totalYeti >= _amount, "veYETI: insufficient Yeti for user to unstake");
                userInfo.totalYeti -= _amount;
                totalYeti -= _amount;
                // unstake and send user back YETI tokens
                yetiToken.transfer(msg.sender, _amount);
            }
        }
        // sanity check:
        require(totalYeti <= _totalYetiSupply, "more Yeti staked in this contract than the total supply");
    }


    // ============= Internal View Functions  =============


    /**
     * Checks that caller is either an EOA or a whitelisted contract
     */
    function _requireValidCaller() internal view {
        if (msg.sender != tx.origin) {
            // called by contract
            require(isWhitelistedContract[msg.sender], 
                "veYETI: update() can only be called by EOAs or whitelisted contracts");
        }
    }


    // ============= Internal Pure Functions  =============


    /**
     * gets the total net change across all adjustments
     * returns (true, absoluteDiff) if the net change if positive and 
     * returns (false, absoluteDiff) if the net change is negative
     */
    function _getAmountChange(RewarderUpdate[] memory _adjustments) internal pure returns (bool, uint256) {
        uint yetiIncrease = 0;
        uint yetiDecrease = 0;
        uint n = _adjustments.length;
        for (uint i = 0; i < n; i++)  {
            if (_adjustments[i].isIncrease) {
                yetiIncrease += _adjustments[i].amount;
            } else {
                yetiDecrease += _adjustments[i].amount;
            }
        }
        return _getDiff(yetiIncrease, yetiDecrease);
    }


    /**
     * gets the total absolute difference
     * returns (true, absoluteDiff) if if diff >= 0 positive and 
     * returns (false, absoluteDiff) if otherwise
     */
    function _getDiff(uint256 _a, uint256 _b) internal pure returns (bool isPositive, uint256 diff) {
        if (_a >= _b) {
            return (true, _a - _b);
        }
        return (false, _b - _a);
    }

    function getAccumulationRate() external view override returns (uint256) {
        return accumulationRate;
    }


    // ========= NEW FUNCTIONS =========


    // get user's total staked YETI balance
    function getTotalYeti(address _user) public view returns (uint256) {
        return users[_user].totalYeti;
    }


    // set emitter
    function setEmitter(IEmitter _emitter) external {
        require(address(emitter) == address(0), "emitter already set");

        // require caller is yeti team multisig (only commented out right now to run tests)
        //require(msg.sender == 0xf572455BE31BF54Cc7D0c6D69B60813171bb7b12);

        emitter = _emitter;
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface IveYETI {
    function updateWhitelistedCallers(address _contractAddress, bool _isWhitelisted) external;
    function getVeYetiOnRewarder(address _user, address _rewarder) external view returns (uint256);
    function getUserYetiOnRewarder(address _user, address _rewarder) external view returns (uint256);
    function getAccumulationRate() external view returns (uint256);
}