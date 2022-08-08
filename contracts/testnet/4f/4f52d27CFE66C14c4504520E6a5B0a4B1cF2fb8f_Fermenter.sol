/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-07
*/

//SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;

/**
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}


// This is a Dough => Dough staking contract, epoch based

pragma solidity ^0.8.0;


// TODO  dont hardcode taxes
interface IDough is IERC20 {
    function mint(address receiver, uint256 amount) external;
    function burn(uint256 amount) external;
}

contract Fermenter is Ownable {

    uint256 constant EPOCHDUR =  6 hours;

    uint256 constant rewardPrecision = 10**18;
    // Contains stake
    struct MetaStake {
        // Last time claimed
        uint256 lastIndex;
        // Total claimable (update?)
        uint256 claimable;
        // amount staked (not compounding)
        uint256 staked;
    }

    struct DelayPayout {
        // timestamp when unlocks
        uint256 time;
        // To  claim
        uint256 amount;
    }
    // Whole thing
    struct StakeSnapshot {
        // Timestamp   
        uint256 time;
        // to claim for 1 ether staked
        uint256 perShare;
    }
    // Ref dough
    IDough public token;
    // Total value staked
    uint256 public tvs;
    // Total rewards - claimed?
    uint256 paidOut;
    // Total rewards
    uint256 accumReward;

    mapping(address => MetaStake) public stakeMap;
   
    StakeSnapshot[] public snapshots;

    mapping(address => DelayPayout) public delayed;

    constructor(address tokaddress) {
        token = IDough(tokaddress);
         StakeSnapshot memory snap = StakeSnapshot({
            time: block.timestamp,
            perShare: 0
        });
        snapshots.push(snap);
    }

// global Functions affecting the state of all users
    // Last 
    function getIndex() public view returns (uint256){
        return snapshots.length - 1;
    }
    // Current end time
    function getEndTime() public view returns (uint256) {
        return snapshots[getIndex()].time + EPOCHDUR;
    }
    // Total staked for user
    function getStake(address user) public view returns (uint256) {
        return stakeMap[user].staked;
    }
    // Incentivize? 
    function advanceEpoch() public {
        // Check
        require(block.timestamp - snapshots[getIndex()].time >= EPOCHDUR, "Staker: Epoch has not passed");
        //  Full rewards
        uint256 epochRewards = token.balanceOf(address(this)) + paidOut - tvs - accumReward;
        uint256 perShare;
        
        if (tvs > 0) {
            //distribute epoch reward via shares
            accumReward += epochRewards;
            perShare = epochRewards * rewardPrecision / tvs + snapshots[getIndex()].perShare;
        } else {
            //forward epoch reward to next epoch
            perShare = snapshots[getIndex()].perShare /* + 0*/;
        }
        StakeSnapshot memory snap = StakeSnapshot({
            time: block.timestamp,
            perShare: perShare
        });
        snapshots.push(snap);
    }

    modifier optionalAdvance() {
        if ( block.timestamp - snapshots[getIndex()].time >= EPOCHDUR) {
            advanceEpoch();
        }
        _;
    }


// functions affecting individual users


    /**
    * @dev Must be called before updating staked value
    *
    */
    function _updateStake(address user) private {
        MetaStake storage refUser = stakeMap[user];
        uint256 lastIndex = refUser.lastIndex;
        uint256 rewardPer = snapshots[getIndex()].perShare - snapshots[lastIndex].perShare;
        uint256 totalReward = rewardPer * refUser.staked / rewardPrecision;
        refUser.claimable += totalReward;
        refUser.lastIndex = getIndex();
    }

    function getClaimable(address user) external view returns (uint256) {
        return stakeMap[user].claimable;
    }

    function getEstimate(address user) external view returns (uint256) {
        if (tvs > 0 && stakeMap[user].staked > 0) {
            uint256 epochRewards = token.balanceOf(address(this)) + paidOut - tvs - accumReward;
            return epochRewards * stakeMap[user].staked / tvs;
        } else {
            return 0;
        }
    }

    function stake(uint256 amount) optionalAdvance external {
        // uint256 spendable = token.allowance(msg.sender, address(this));
        // require(spendable >= amount, "Allowance insufficient");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Staker: Token deposit reverted");
        _updateStake(msg.sender);
        stakeMap[msg.sender].staked += amount;
        tvs += amount;
    }

    function withdraw() optionalAdvance external {
        _updateStake(msg.sender);
        uint256 amount = stakeMap[msg.sender].claimable;
        stakeMap[msg.sender].claimable = 0;
        paidOut += amount;
        token.transfer(msg.sender, amount);
    }

    function unstakeNow(uint256 amount) optionalAdvance external {
        require(stakeMap[msg.sender].staked >= amount, "Staker: Insufficient Funds staked");
        _updateStake(msg.sender);
        stakeMap[msg.sender].staked -= amount;
        tvs -= amount;
        uint256 halfTax = amount * 375 / 1000;
        uint256 topay = amount - 2*halfTax;
        //implicit self deposit of halTax (through balance)
        token.burn(halfTax);
        token.transfer(msg.sender, topay);
    }

    function unstakeDelay(uint256 amount, uint256 lvl) optionalAdvance external {
        uint256[3] memory halfTaxRate = [uint256(250), uint256(125), uint256(0)];
        require(lvl <= 2, "Staker: Invalid Delay choice");
        require(stakeMap[msg.sender].staked >= amount, "Staker: Insufficient Funds staked");
        // TODO Should we allow mulitple delays? 
        require(delayed[msg.sender].amount == 0, "Staker: Time Delay Slot already full");
        _updateStake(msg.sender);
        // Stop earning on unstaked tokens
        stakeMap[msg.sender].staked -= amount;
        tvs -= amount;
        uint256 halfTax = amount * halfTaxRate[lvl] / 1000;
        uint256 topay = amount - 2*halfTax;
        //implicit self deposit of halTax (through balance)
        token.burn(halfTax);
        delayed[msg.sender].amount = topay;
        // 2, 4 or 6 days / 25, 12.5, 0 % Taxes
        delayed[msg.sender].time = block.timestamp + (1 days)*(lvl + 1);
        //token.transfer(msg.sender, topay);
    }

    function getDelayedAmount(address user) external view returns (uint256) {
        return delayed[user].amount;
    }

    function getDelayedTime(address user) external view returns (uint256) {
        return delayed[user].time;
    }

    function withdrawDelayed() external {
        uint256 amount = delayed[msg.sender].amount;
        require(amount > 0, "Fermenter: No delayed funds to withdraw");
        require(block.timestamp >= delayed[msg.sender].time, "Fermenter: Delay has not passed");
        delayed[msg.sender].amount = 0;
        token.transfer(msg.sender, amount);
    }
}