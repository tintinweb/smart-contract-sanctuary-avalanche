/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-20
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT License
pragma solidity 0.6.8;

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


contract MultipleDepositsSplashpads {
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

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount needs to be > 0");
        address _addr = msg.sender;
        //Add to user
        users[_addr].deposits += _amount;
        users[_addr].lastDepositTime = block.timestamp;
        users[_addr].lastClaimTime = block.timestamp;
        users[_addr].lastRollTime = block.timestamp;
        users[_addr].depositsIds.push(depositsCount);
        users[_addr].depositsCount++;

        //Add new deposit
        deposits[depositsCount].id = depositsCount;
        deposits[depositsCount].deposit = _amount;
        deposits[depositsCount].owner = _addr;
        deposits[depositsCount].payout = 0;
        deposits[depositsCount].depositTime = block.timestamp;
        deposits[depositsCount].claimTime = block.timestamp;
        deposits[depositsCount].rollTime = block.timestamp;

        //Global stat
        totalDeposits += _amount;
        depositsCount++;

        lpTokenContractAddress.transferFrom(_addr,address(this),_amount);
    }

    function claim(uint256 _depositId) external {
        address _addr = msg.sender;
        require(deposits[_depositId].owner == _addr, "Not the owner");
        
        //Get rewards
        uint256 rewards = getRewards(_depositId);
        require(rewards > 0, "No rewards");

        //Update Deposit
        deposits[_depositId].payout += rewards;
        deposits[_depositId].claimTime = block.timestamp;
        deposits[_depositId].rollTime = block.timestamp;

        //Update User
        users[_addr].payouts += rewards;
        users[_addr].lastClaimTime = block.timestamp;

        //Update global
        totalPayouts += rewards;
    }

    function roll(uint256 _depositId) external {
        address _addr = msg.sender;
        require(deposits[_depositId].owner == _addr, "Not the owner");

        //Roll
        uint256 rewards = getRewards(_depositId);
        require(rewards > 0, "No rewards");
        deposits[_depositId].payout += rewards;
        deposits[_depositId].rollTime = block.timestamp;
        users[_addr].payouts += rewards;
        users[_addr].lastRollTime = block.timestamp;

        //Add to existing deposit
        deposits[_depositId].deposit += rewards;
        users[_addr].deposits += rewards;


        //Global stat
        totalDeposits += rewards;
        totalPayouts += rewards;
    }

    function claimAll() external {
        address _addr = msg.sender;
        require(users[_addr].depositsCount > 0, "No deposits");

        uint256 _totalrewards = 0;

        //Loop through deposits of user
        for (uint256 i = 0; i < users[_addr].depositsCount; i++) {
            uint256 _depositId = users[_addr].depositsIds[i];
            uint256 _rewards = getRewards(_depositId);
            _totalrewards += _rewards;
            deposits[_depositId].payout += _rewards;
            deposits[_depositId].claimTime = block.timestamp;
            deposits[_depositId].rollTime = block.timestamp;
        }

        //Update stats
        users[_addr].lastClaimTime = block.timestamp;
        users[_addr].payouts += _totalrewards;
        totalPayouts += _totalrewards;
    }

    function rollAll() external {
        address _addr = msg.sender;
        require(users[_addr].depositsCount > 0, "No deposits");

        uint256 _totalrewards = 0;

        //Loop through deposits of user
        for (uint256 i = 0; i < users[_addr].depositsCount; i++) {
            uint256 _depositId = users[_addr].depositsIds[i];
            uint256 _rewards = getRewards(_depositId);
            _totalrewards += _rewards;
            deposits[_depositId].payout += _rewards;
            deposits[_depositId].rollTime = block.timestamp;
            deposits[_depositId].deposit += _rewards;
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
}