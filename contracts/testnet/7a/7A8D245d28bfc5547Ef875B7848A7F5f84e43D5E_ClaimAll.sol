/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them lowd in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {


    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    /**
     * Call when init cloned Contract
     */
    function initOwnable() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    /*    function renounceOwnership() public virtual onlyOwner {
     *   emit OwnershipTransferred(_owner, address(0));
     *   _owner = address(0);
     *   }
    */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface Pool {
    function pendingRewardByToken(address _user, IERC20 _token) external view returns (uint256);
    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256[] memory, IERC20[] memory);
    function withdraw2(address _caller,uint256 _amount) external;
    // The reward token
    function rewardTokens() external view returns (IERC20[] memory);
}

contract ClaimAll is Ownable, ReentrancyGuard {
    uint256 constant ONE_MONTH = 2592000;

    uint256 public first_month;
    uint256 public second_month;
    uint256 public thirst_month;

    struct Reward {
        uint256 locking_reward;
        uint256 claimed;
    }

    address[] public pools;
    address[] public farms;
    mapping(address => Reward) public reward;

    address public month_reward_token;

    constructor  (address _reward_token){
        month_reward_token = _reward_token;
    }

    function setPools(address[] memory _pools) external {
        pools = _pools;
    }
    function setFarms(address[] memory _farms) external {
        farms = _farms;
    }

    function addPool(address pool) external {
        pools.push(pool);
    }

    function addFarm(address farm) external {
        farms.push(farm);
    }

    function setAllMonth(uint256 _first) public onlyOwner{
        first_month = _first;
        second_month = _first + ONE_MONTH;
        thirst_month = _first + ONE_MONTH + ONE_MONTH;
    }
    function setFirstMonth(uint256 _first) public onlyOwner{
        first_month = _first;
    }
    function setSecondMonth(uint256 _second) public onlyOwner{

        second_month = _second;

    }
    function setThirstMonth(uint256 _thirst) public onlyOwner{
        thirst_month = _thirst;
    }


    function setLockedReward(address[] memory _users, uint256[] memory _amounts) external onlyOwner {
        require(_users.length == _amounts.length, "Wrong format CSV");
        for(uint i = 0; i < _users.length; i++){
            address _user = _users[i];
            uint256 _amount = _amounts[i];
            reward[_user].locking_reward = _amount;
            // reward[_user].claimed = 0; // reset claimed amount
        }
    }
    

    function releaseReward() public view returns(uint256){
        uint256 _claimable = 0;

        if(block.timestamp >= thirst_month) {
            _claimable = reward[msg.sender].locking_reward ;
        }else if(block.timestamp >= second_month) {
            _claimable = reward[msg.sender].locking_reward * 2 / 3;
        }else if(block.timestamp >= first_month) {
            _claimable = reward[msg.sender].locking_reward / 3;
        }

        _claimable = _claimable - reward[msg.sender].claimed;

        return _claimable;
    }

    function remainLockedReward() external view returns(uint256) {
        return reward[msg.sender].locking_reward - reward[msg.sender].claimed;
    }

    // Call this function from frontend
    function claimAllPools() external nonReentrant{
        for(uint256 i=0; i < pools.length; i++){
            (uint256[] memory pendingReward, ) = Pool(pools[i]).pendingReward(msg.sender);
            
            if(pendingReward[0] > 0){

                Pool(pools[i]).withdraw2(msg.sender, 0); //Harvest
            }

        }

        uint _pending = releaseReward();
        reward[msg.sender].claimed += _pending;
        IERC20(month_reward_token).transfer(msg.sender, _pending);

    }
    // Call this function from frontend
    function claimAllFarms() external nonReentrant{
        for(uint i=0; i < farms.length; i++){
            (uint256[] memory pendingReward, ) = Pool(farms[i]).pendingReward(msg.sender);

            if(pendingReward[0] > 0){
                Pool(farms[i]).withdraw2(msg.sender, 0); //Harvest
            }
        }


        uint _pending = releaseReward();
        reward[msg.sender].claimed += _pending;
        IERC20(month_reward_token).transfer(msg.sender, _pending);

    }

    function rewardsAllPools() external view returns(uint){
        uint256 sum = 0;

        for(uint256 i=0; i < pools.length; i++){
            (uint256[] memory pendingReward, ) = Pool(pools[i]).pendingReward(msg.sender);
            
            sum = sum + pendingReward[0] ;

        }

        return sum ;
    }

    function rewardsAllFarms() external view returns(uint){
        uint256 sum = 0;
        for(uint i=0; i < farms.length; i++){
            (uint256[] memory pendingReward, ) = Pool(farms[i]).pendingReward(msg.sender);
            sum = sum + pendingReward[0] ;
        }

        return sum ;
    }

    function rewards(address pool) external view returns (uint256[] memory, IERC20[] memory){
        return Pool(pool).pendingReward(msg.sender);
    }

    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        uint256 balance = IERC20(month_reward_token).balanceOf(address(this));

        require(balance >= _amount, "ClaimAll: Withdraw Amount exceed Balance");

        IERC20(month_reward_token).transfer(msg.sender, _amount);
    }
}