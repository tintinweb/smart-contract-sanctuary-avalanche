/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.6.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
contract BlackList is Ownable {
    
    mapping(address=>bool) public blackList;

    

 
          modifier noBlackList(){
   require(!blackList[msg.sender]==true,"No Blacklist calls");
   _;
  }
 function removeFromBlackList(address[] memory blackListAddress) public onlyOwner {
    for(uint256 i;i<blackListAddress.length;i++){
      blackList[blackListAddress[i]]=false;
    }
  }
  function addToBlackList(address[] memory blackListAddress) public onlyOwner {
    for(uint256 i;i<blackListAddress.length;i++){
        blackList[blackListAddress[i]]=true;
    }
  }
}
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

contract MultipleDepositsSplashpads is Ownable,Pausable, BlackList {
    struct Deposit {
        uint256 id;
        uint256 deposit;
        address owner;
        uint256 payout;
        uint256 depositTime;
        uint256 claimTime;
        uint256 rollTime;
    }
    struct User {
        uint256 payouts;
        uint256 deposits;
        uint256 lastDepositTime;
        uint256 lastClaimTime;
        uint256 lastRollTime;
        uint256[] depositsIds;
        uint256 depositsCount;
    }
    mapping(address => User) public users;
    mapping(uint256 => Deposit) public deposits;

    uint256 public depositsCount;
    uint256 public totalDeposits;
    uint256 public totalPayouts;
    uint256 public fee=10;
    uint256 private dividend;

   IERC20 public lpTokenContractAddress;

    constructor(IERC20 _lpTokenContractAddress) public {
        totalDeposits = 0;
        totalPayouts = 0;
        depositsCount = 0;
        lpTokenContractAddress=_lpTokenContractAddress;
    }

    function getDepositsIds(address _addr)
        public
        view
        returns (uint256[] memory _depositsIds)
    {
        _depositsIds = users[_addr].depositsIds;
    }

    function getRewards(uint256 _depositId) public view returns (uint256 _rewards) {
        _rewards = calculateRewards(deposits[_depositId].deposit, block.timestamp, deposits[_depositId].claimTime) - calculateRewards(deposits[_depositId].deposit, deposits[_depositId].rollTime, deposits[_depositId].claimTime);
    }

    function calculateRewards(uint256 _deposits, uint256 _atTime, uint256 _claimTime) private pure returns(uint256 _rewards){
        uint256 _timeElasped = _atTime - _claimTime;
        uint256 _bracket = 10 seconds;
        if(_timeElasped > 0){
            _rewards = _deposits * _timeElasped / 1 days * 1 / 100;
        }
        if(_timeElasped >= 1 * _bracket){
            _rewards += _deposits * (_timeElasped - _bracket) / 1 days * 2 / 100 - _deposits * (_timeElasped - _bracket) / 1 days * 1 / 100;
        }
        if(_timeElasped >= 2 * _bracket){
            _rewards += _deposits * (_timeElasped - 2 * _bracket) / 1 days * 3 / 100 - _deposits * (_timeElasped - 2 * _bracket) / 1 days * 2 / 100;
        }
    }

    function getPercentage(uint256 _depositId) public view returns (uint256 percentage) {
        uint256 _timeSinceLastWithdraw = block.timestamp - deposits[_depositId].claimTime;
        uint256 _bracket = 10 seconds;
        if(_timeSinceLastWithdraw < 1*_bracket){
            percentage = 1;
        } else if(_timeSinceLastWithdraw < 2*_bracket){
            percentage = 2;
        } else {
            percentage = 3;
        }
    }

    function getDeposit(uint256 _depositId)
        public
        view
        returns (
            uint256 id,
            uint256 deposit,
            address owner,
            uint256 payout,
            uint256 depositTime,
            uint256 claimTime,
            uint256 rollTime,
            uint256 percentage,
            uint256 rewardsAvailable
        )
    {
        id = deposits[_depositId].id;
        deposit = deposits[_depositId].deposit;
        owner = deposits[_depositId].owner;
        payout = deposits[_depositId].payout;
        depositTime = deposits[_depositId].depositTime;
        claimTime = deposits[_depositId].claimTime;
        rollTime = deposits[_depositId].rollTime;
        percentage = getPercentage(_depositId);
        rewardsAvailable = getRewards(_depositId);
    }

    function deposit(uint256 _amount) external whenNotPaused noBlackList {
        require(_amount > 0, "Amount needs to be > 0");
        uint256 Lpfee=(_amount*fee)/dividend;
        uint256 amountAfterFeeDeduction=_amount-Lpfee;
        address _addr = msg.sender;
        //Add to user
        users[_addr].deposits += amountAfterFeeDeduction;
        users[_addr].lastDepositTime = block.timestamp;
        users[_addr].lastClaimTime = block.timestamp;
        users[_addr].lastRollTime = block.timestamp;
        users[_addr].depositsIds.push(depositsCount);
        users[_addr].depositsCount++;

        //Add new deposit
        deposits[depositsCount].id = depositsCount;
        deposits[depositsCount].deposit = amountAfterFeeDeduction;
        deposits[depositsCount].owner = _addr;
        deposits[depositsCount].payout = 0;
        deposits[depositsCount].depositTime = block.timestamp;
        deposits[depositsCount].claimTime = block.timestamp;
        deposits[depositsCount].rollTime = block.timestamp;
        lpTokenContractAddress.transferFrom(_addr,address(this),_amount);
        //Global stat
        totalDeposits += amountAfterFeeDeduction;
        depositsCount++;

    }

    function claim(uint256 _depositId) external whenNotPaused noBlackList{
        address _addr = msg.sender;
        require(deposits[_depositId].owner == _addr, "Not the owner");
        
        //Get rewards
        uint256 rewards = getRewards(_depositId);
        uint256 Lpfee=(rewards*fee)/dividend;
        uint256 amountAfterFeeDeduction=rewards-Lpfee;
        require(rewards > 0, "No rewards");

        //Update Deposit
        deposits[_depositId].payout += amountAfterFeeDeduction;
        deposits[_depositId].claimTime = block.timestamp;
        deposits[_depositId].rollTime = block.timestamp;

        //Update User
        users[_addr].payouts += amountAfterFeeDeduction;
        users[_addr].lastClaimTime = block.timestamp;
        lpTokenContractAddress.transfer(_addr,amountAfterFeeDeduction);
        //Update global
        totalPayouts += amountAfterFeeDeduction;
    }

    function roll(uint256 _depositId) external whenNotPaused noBlackList {
        address _addr = msg.sender;
        require(deposits[_depositId].owner == _addr, "Not the owner");

        //Roll
        uint256 rewards = getRewards(_depositId);
        uint256 Lpfee=(rewards*fee)/dividend;
        uint256 amountAfterFeeDeduction=rewards-Lpfee;
        require(rewards > 0, "No rewards");
        deposits[_depositId].payout += amountAfterFeeDeduction;
        deposits[_depositId].rollTime = block.timestamp;
        users[_addr].payouts += amountAfterFeeDeduction;
        users[_addr].lastRollTime = block.timestamp;

        //Add to existing deposit
        deposits[_depositId].deposit += amountAfterFeeDeduction;
        users[_addr].deposits += amountAfterFeeDeduction;


        //Global stat
        totalDeposits += amountAfterFeeDeduction;
        totalPayouts += amountAfterFeeDeduction;
    }

    function claimAll() external whenNotPaused noBlackList{
        address _addr = msg.sender;
        require(users[_addr].depositsCount > 0, "No deposits");

        uint256 _totalrewards = 0;

        //Loop through deposits of user
        for (uint256 i = 0; i < users[_addr].depositsCount; i++) {
            uint256 _depositId = users[_addr].depositsIds[i];
            uint256 _rewards = getRewards(_depositId);
            uint256 Lpfee=(_rewards*fee)/dividend;
            uint256 amountAfterFeeDeduction=_rewards-Lpfee;
            _totalrewards += amountAfterFeeDeduction;
            deposits[_depositId].payout += amountAfterFeeDeduction;
            deposits[_depositId].claimTime = block.timestamp;
            deposits[_depositId].rollTime = block.timestamp;
        }

        //Update stats
        users[_addr].lastClaimTime = block.timestamp;
        users[_addr].payouts += _totalrewards;
        totalPayouts += _totalrewards;
        lpTokenContractAddress.transfer(_addr,_totalrewards);

    }

    function rollAll() external whenNotPaused noBlackList{
        address _addr = msg.sender;
        require(users[_addr].depositsCount > 0, "No deposits");

        uint256 _totalrewards = 0;

        //Loop through deposits of user
        for (uint256 i = 0; i < users[_addr].depositsCount; i++) {
            uint256 _depositId = users[_addr].depositsIds[i];
            uint256 _rewards = getRewards(_depositId);
            uint256 Lpfee=(_rewards*fee)/dividend;
            uint256 amountAfterFeeDeduction=_rewards-Lpfee;
            _totalrewards += amountAfterFeeDeduction;
            deposits[_depositId].payout += amountAfterFeeDeduction;
            deposits[_depositId].rollTime = block.timestamp;
            deposits[_depositId].deposit += amountAfterFeeDeduction;
        }

        //Update Stats
        users[_addr].deposits += _totalrewards;
        users[_addr].lastRollTime = block.timestamp;
        users[_addr].payouts += _totalrewards;
        totalPayouts += _totalrewards;
        totalDeposits += _totalrewards;
    }

    function getBlock () public view returns(uint256) {
        return block.timestamp;
    }
      function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
}