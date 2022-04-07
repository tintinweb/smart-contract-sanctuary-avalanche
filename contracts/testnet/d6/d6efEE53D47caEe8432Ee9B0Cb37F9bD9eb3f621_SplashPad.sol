/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-07
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-30
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-09
*/

/*! ether.chain3.sol | (c) 2020 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | SPDX-License-Identifier: MIT License */

pragma solidity 0.6.8;


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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

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


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract GOwner {
    address payable public grand_owner;

    event GrandOwnershipTransferred(address indexed previous_owner, address indexed new_owner);

    constructor() public {
        grand_owner = msg.sender;
    }

    function transferGrandOwnership(address payable _to) external {
        require(msg.sender == grand_owner, "Access denied (only grand owner)");
        
        grand_owner = _to;
    }

 
}

contract SplashPad is Ownable, GOwner, Pausable {
    struct User {
        uint256 payouts;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 withdrawTime;
        bool isAlreadyDeposited;
    }

    mapping(address => User) public users;                    // 1 => 1%
                 // 1 => 1%

    uint256 public total_withdraw;
    IERC20 public lpToken;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
   
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(IERC20 _lpToken) public {
      lpToken=_lpToken;
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(!users[_addr].isAlreadyDeposited,"User Already deposited");
        users[_addr].isAlreadyDeposited=true;
        lpToken.transferFrom(msg.sender,address(this),_amount);
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;
        users[_addr].withdrawTime=block.timestamp;
        emit NewDeposit(_addr, _amount);
    }
    function deposit(uint256 _amount)  external whenNotPaused {
        _deposit(msg.sender, _amount);
    }

    function claim() external whenNotPaused {
        uint256 to_payout =this.getWaterReward(msg.sender);

        // Deposit payout
        if(to_payout > 0) {
            to_payout =users[msg.sender].payouts;
            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

        }

        // require(to_payout > 0, "Zero payout");
        
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;
        users[msg.sender].withdrawTime=block.timestamp;
        users[msg.sender].deposit_payouts=0;
        users[msg.sender].deposit_time=uint40(block.timestamp);
        to_payout=waterToUsd(to_payout);
        lpToken.transfer(msg.sender,to_payout);
        // payable(msg.sender).transfer(to_payout);
        
        emit Withdraw(msg.sender, to_payout);
    }

    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
   function getPercentage(address _addr)public view returns(uint256){
       uint256 percentage=(block.timestamp - users[_addr].withdrawTime)*100 / 1 weeks;
       if(percentage<300){
           return percentage;
       }else{
           return 300;
       }
   }
    function payoutOf(address _addr) view internal returns(uint256 payout) {
            payout = ((users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 100)) - users[_addr].deposit_payouts;
    }
    function getWaterReward(address _addr)view external returns(uint256){
        (uint256 reward)=payoutOf(_addr);
        if(getPercentage(_addr)==1){
        reward=reward*getPercentage(_addr);
        return waterToUsd(reward);
        }else if(getPercentage(_addr)==2){
            reward=reward*getPercentage(_addr)-users[_addr].deposit_amount*7/100;
            return waterToUsd(reward);
        }else if(getPercentage(_addr)==3){
            reward= reward*getPercentage(_addr)-users[_addr].deposit_amount*21/100;
            return waterToUsd(reward);
        }
    }
    function waterToUsd(uint256 _amount) internal view returns (uint256) {
    uint256 contractBalance=lpToken.balanceOf(address(this));
    uint256 convertedPrice=contractBalance/10000;
    return (convertedPrice*_amount)/1 ether;
    }
    /*
        Only external call
    */
    function userInfo(address _addr) view external returns( uint40 deposit_time, uint256 deposit_amount, uint256 payouts) {
        return (users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts);
    }
}