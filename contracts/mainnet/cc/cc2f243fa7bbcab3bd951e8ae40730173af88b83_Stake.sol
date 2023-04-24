/**
 *Submitted for verification at snowtrace.io on 2023-04-24
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: SafeMath.sol


pragma solidity = 0.8.10;
/* @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behaviour in high-level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with a custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with a custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with a custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: stake.sol


// Freebie life finance (c) Corporation Inc
// Staking Contract with stable APR!

pragma solidity ^0.8.10;



interface ERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address _owner)external view returns(uint256);
    function transfer(address _to, uint256 _value)external returns(bool);
    function approve(address _spender, uint256 _value)external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value)external returns(bool);    
    function allowance(address _owner, address _spender)external view returns(uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Stake is ERC20{
    IERC20 public token;
    using SafeMath for uint256;
    address public creator;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string public name = "Stake Freebie Token";
    string public symbol = "sFRB";
    uint public decimals = 18;
    uint256 public _totalSupply;
    address private sPool;

    //for Staking
    bool public stakingOn = false;
    bool public whiteListOn = true;
    mapping(address => bool) public whitelist;

    //10 days staking
    mapping(address => uint256) public lockTime10;
    mapping(address => uint256) public stakedAmount10;
    mapping(address => uint256) public stakeRewards10;

    //30 days staking
    mapping(address => uint256) public lockTime30;
    mapping(address => uint256) public stakedAmount30;
    mapping(address => uint256) public stakeRewards30;

    //60 days staking
    mapping(address => uint256) public lockTime60;
    mapping(address => uint256) public stakedAmount60;
    mapping(address => uint256) public stakeRewards60;
    
    uint256 public TotalRewordsHolded;

    modifier ownerOnly {
        if (msg.sender == creator) {
            _;
        }
    }

    constructor(address _token) {
        token = IERC20(_token);
        creator = msg.sender;
        sPool = address(this);
        _totalSupply = 1000000000000000000000000;
        _balances[sPool] = _totalSupply;
    }

    function totalSupply() external override view returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner)external override view returns(uint256 _returnedBalance){
        _returnedBalance = _balances[_owner];
        return _returnedBalance;
    }

    function _transfer(address _from, address _to, uint256 amount) internal {
      require(_from != address(0), "BEP20: Transfer from zero address");
      require(_to != address(0), "BEP20: Transfer to the zero address");
      _balances[_from] = _balances[_from].sub(amount);
      _balances[_to] = _balances[_to].add(amount);
      emit Transfer(_from, _to, amount);
    }

    function transfer(address _to, uint256 _value)external override returns(bool){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
      require(owner != address(0), "BEP20: approve from the zero address");
      require(spender != address(0), "BEP20: approve to the zero address");
      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
    }

    function approve(address _spender, uint256 _value)external override returns(bool success) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)external override returns(bool success){
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, _allowances[_from][msg.sender].sub(_value));
        return true;
    }

    function allowance(address _owner, address _spender)external override view returns(uint256 remaining){
        return _allowances[_owner][_spender];
    }

    function stakingLive(bool _liveStaking)public ownerOnly returns(bool _stakingstatus){
        stakingOn = _liveStaking;
        _stakingstatus = stakingOn;
        return _stakingstatus;
    }
    
    function whitelistActive(bool _activeWhitelist)public ownerOnly returns(bool _whiteliststatus){
        whiteListOn = _activeWhitelist;
        _whiteliststatus = stakingOn;
        return _whiteliststatus;
    }   

    function addToWL(address[] memory _addWLaddress) external ownerOnly {
        for(uint i; i < _addWLaddress.length; i++) {
            require(_addWLaddress[i] != address(0));
            whitelist[_addWLaddress[i]] = true;
        }
    }

    function RemoveFromWL(address[] memory _removeWLaddress) external ownerOnly {
        for(uint i; i < _removeWLaddress.length; i++) {
            require(_removeWLaddress[i] != address(0));
            whitelist[_removeWLaddress[i]] = false;
        }
    }

    function addRewardsBalance(uint256 _addRewards)public returns(uint256 _added){
        token.transferFrom(msg.sender, sPool, _addRewards);
        _added = token.balanceOf(sPool);
        return _added;
    }

    function stakeTKN10(uint256 _stakeAmount) public returns(uint256 _sTokenAmount) {
        require(stakingOn, "Staking not active right now!");
        if (lockTime10[msg.sender] > 0) {
            require(lockTime10[msg.sender] > block.timestamp, "Please unstake and collect your rewards first!");
        }
        require(token.balanceOf(msg.sender) >= _stakeAmount, "Not enough tokens balance");
        require(_stakeAmount <= token.allowance(msg.sender, sPool), "Please approve Staking amount!");
        uint256 rewards;
        uint256 stakeTKNs = _stakeAmount;
        if (lockTime10[msg.sender] > 0 && lockTime10[msg.sender] > block.timestamp) {
            TotalRewordsHolded = TotalRewordsHolded.sub(stakeRewards10[msg.sender]);
            _stakeAmount = _stakeAmount.add(stakedAmount10[msg.sender]);
        } 
        if (whiteListOn) {
            require(whitelist[msg.sender], "You are not in Whitelist!");
            require(_stakeAmount >= 100000000000000000000, "Minimum to stake is 100 tokens");
            token.transferFrom(msg.sender, sPool, stakeTKNs);
        } else {
            token.transferFrom(msg.sender, sPool, stakeTKNs);
        }
        lockTime10[msg.sender] = block.timestamp.add(864000); //(864000 sec),10 days, amount in seconds
        rewards = _stakeAmount.add(_stakeAmount.div(20)); //5% rewards add to staked amount
        stakeRewards10[msg.sender] = rewards;
        stakedAmount10[msg.sender] = _stakeAmount;
        TotalRewordsHolded = TotalRewordsHolded.add(stakeRewards10[msg.sender]);
        _sTokenAmount = _stakeAmount;
        return _sTokenAmount;
    }

    function reStakeTKN10() public returns(uint256 _sTokenAmount) {
        require(stakingOn, "Staking not active right now!");
        require(lockTime10[msg.sender] > 0 && lockTime10[msg.sender] < block.timestamp, "You can't reStake now!");
        uint256 rewards;         
        rewards = stakeRewards10[msg.sender].div(20); //5% rewards add to staked amount
        lockTime10[msg.sender] = block.timestamp.add(864000); //(864000 sec),10 days, amount in seconds
        stakeRewards10[msg.sender] = stakeRewards10[msg.sender].add(rewards);
        TotalRewordsHolded = TotalRewordsHolded.add(rewards);
        _sTokenAmount = stakeRewards10[msg.sender];
        return _sTokenAmount;
    }

    function UnStakeTokens10()public returns(uint256 _tokenAmount) {
        require(stakeRewards10[msg.sender] > 0, "Your staking rewards is zero!");
        uint256 _UnStakeAmount = stakeRewards10[msg.sender];
        if (lockTime10[msg.sender] < block.timestamp) {
            _transfer(sPool, msg.sender, _UnStakeAmount);
        } else {
            _UnStakeAmount = _UnStakeAmount.div(2); // -50% because withdraw before lock period ended
            _transfer(sPool, msg.sender, _UnStakeAmount);
            TotalRewordsHolded = TotalRewordsHolded.sub(stakeRewards10[msg.sender].sub(_UnStakeAmount));
        }        
        stakedAmount10[msg.sender] = 0;
        stakeRewards10[msg.sender] = 0;
        lockTime10[msg.sender] = 0;
        _tokenAmount = _UnStakeAmount;
        return _tokenAmount;
    }

//30 days staking
    function stakeTKN30(uint256 _stakeAmount) public returns(uint256 _sTokenAmount) {
        require(stakingOn, "Staking not active right now!");
        if (lockTime30[msg.sender] > 0) {
            require(lockTime30[msg.sender] > block.timestamp, "Please unstake and collect your rewards first!");
        }
        require(token.balanceOf(msg.sender) >= _stakeAmount, "Not enough tokens balance");
        require(_stakeAmount <= token.allowance(msg.sender, sPool), "Please approve Staking amount!");
        uint256 rewards;
        uint256 stakeTKNs = _stakeAmount;
        if (lockTime30[msg.sender] > 0 && lockTime30[msg.sender] > block.timestamp) {
            TotalRewordsHolded = TotalRewordsHolded.sub(stakeRewards30[msg.sender]);
            _stakeAmount = _stakeAmount.add(stakedAmount30[msg.sender]);
        } 
        if (whiteListOn) {
            require(whitelist[msg.sender], "You are not in Whitelist!");
            require(_stakeAmount >= 100000000000000000000, "Minimum to stake is 100 tokens");
            token.transferFrom(msg.sender, sPool, stakeTKNs);
        } else {
            token.transferFrom(msg.sender, sPool, stakeTKNs);
        }
        lockTime30[msg.sender] = block.timestamp.add(2592000); //(2592000 sec),One month, amount in seconds
        rewards = _stakeAmount.add(_stakeAmount.div(5)); //20% rewards add to staked amount
        stakeRewards30[msg.sender] = rewards;
        stakedAmount30[msg.sender] = _stakeAmount;
        TotalRewordsHolded = TotalRewordsHolded.add(stakeRewards30[msg.sender]);
        _sTokenAmount = _stakeAmount;
        return _sTokenAmount;
    }

    function reStakeTKN30() public returns(uint256 _sTokenAmount) {
        require(stakingOn, "Staking not active right now!");
        require(lockTime30[msg.sender] > 0 && lockTime30[msg.sender] < block.timestamp, "You can't reStake now!");
        uint256 rewards;         
        rewards = stakeRewards30[msg.sender].div(5); //20% rewards add to staked amount
        lockTime30[msg.sender] = block.timestamp.add(2592000); //(2592000 sec),30 days, amount in seconds
        stakeRewards30[msg.sender] = stakeRewards30[msg.sender].add(rewards);
        TotalRewordsHolded = TotalRewordsHolded.add(rewards);
        _sTokenAmount = stakeRewards30[msg.sender];
        return _sTokenAmount;
    }

    function UnStakeTokens30()public returns(uint256 _tokenAmount) {
        require(stakeRewards30[msg.sender] > 0, "Your staking rewards is zero!");
        uint256 _UnStakeAmount = stakeRewards30[msg.sender];
        if (lockTime30[msg.sender] < block.timestamp) {
            _transfer(sPool, msg.sender, _UnStakeAmount);
        } else {
            _UnStakeAmount = _UnStakeAmount.div(2); // -50% because withdraw before locking period is finish
            _transfer(sPool, msg.sender, _UnStakeAmount);
            TotalRewordsHolded = TotalRewordsHolded.sub(stakeRewards30[msg.sender].sub(_UnStakeAmount));
        }        
        stakedAmount30[msg.sender] = 0;
        stakeRewards30[msg.sender] = 0;
        lockTime30[msg.sender] = 0;
        _tokenAmount = _UnStakeAmount;
        return _tokenAmount;
    }

//60 days staking
    function stakeTKN60(uint256 _stakeAmount) public returns(uint256 _sTokenAmount) {
        require(stakingOn, "Staking not active right now!");
        if (lockTime60[msg.sender] > 0) {
            require(lockTime60[msg.sender] > block.timestamp, "Please unstake and collect your rewards first!");
        }
        require(token.balanceOf(msg.sender) >= _stakeAmount, "Not enough tokens balance");
        require(_stakeAmount <= token.allowance(msg.sender, sPool), "Please approve Staking amount!");
        uint256 rewards;
        uint256 stakeTKNs = _stakeAmount;
        if (lockTime60[msg.sender] > 0 && lockTime60[msg.sender] > block.timestamp) {
            TotalRewordsHolded = TotalRewordsHolded.sub(stakeRewards60[msg.sender]);
            _stakeAmount = _stakeAmount.add(stakedAmount60[msg.sender]);
        } 
        if (whiteListOn) {
            require(whitelist[msg.sender], "You are not in Whitelist!");
            require(_stakeAmount >= 100000000000000000000, "Minimum to stake is 100 tokens");
            token.transferFrom(msg.sender, sPool, stakeTKNs);
        } else {
            token.transferFrom(msg.sender, sPool, stakeTKNs);
        }
        lockTime60[msg.sender] = block.timestamp.add(5184000); //(5184000 sec),Two month, amount in seconds
        rewards = _stakeAmount.add(_stakeAmount.div(2)); //50% rewards add to staked amount
        stakeRewards60[msg.sender] = rewards;
        stakedAmount60[msg.sender] = _stakeAmount;
        TotalRewordsHolded = TotalRewordsHolded.add(stakeRewards60[msg.sender]);
        _sTokenAmount = _stakeAmount;
        return _sTokenAmount;
    }

    function reStakeTKN60() public returns(uint256 _sTokenAmount) {
        require(stakingOn, "Staking not active right now!");
        require(lockTime60[msg.sender] > 0 && lockTime60[msg.sender] < block.timestamp, "You can't reStake now!");
        uint256 rewards;         
        rewards = stakeRewards60[msg.sender].div(2); //50% rewards add to staked amount
        lockTime60[msg.sender] = block.timestamp.add(5184000); //(5184000 sec),60 days, amount in seconds
        stakeRewards60[msg.sender] = stakeRewards60[msg.sender].add(rewards);
        TotalRewordsHolded = TotalRewordsHolded.add(rewards);
        _sTokenAmount = stakeRewards60[msg.sender];
        return _sTokenAmount;
    }

    function UnStakeTokens60()public returns(uint256 _tokenAmount) {
        require(stakeRewards60[msg.sender] > 0, "Your staking rewards is zero!");
        uint256 _UnStakeAmount = stakeRewards60[msg.sender];
        if (lockTime60[msg.sender] < block.timestamp) {
            _transfer(sPool, msg.sender, _UnStakeAmount);
        } else {
            _UnStakeAmount = _UnStakeAmount.div(2); // -50% because withdraw before locking period is finish
            _transfer(sPool, msg.sender, _UnStakeAmount);
            TotalRewordsHolded = TotalRewordsHolded.sub(stakeRewards60[msg.sender].sub(_UnStakeAmount));
        }        
        stakedAmount60[msg.sender] = 0;
        stakeRewards60[msg.sender] = 0;
        lockTime60[msg.sender] = 0;
        _tokenAmount = _UnStakeAmount;
        return _tokenAmount;
    }

    function tokenTransfer(address _to, uint256 _trfrAmount)internal {
        token.transfer(_to, _trfrAmount);
    }

    function swapSTokenToToken(uint256 _swapAmount)public returns(uint256 _swapped) {
        require(_swapAmount <= _balances[msg.sender], "Not enought balanse of sFRB!");
        _transfer(msg.sender, sPool, _swapAmount);
        uint256 TotalStakedTokens = token.balanceOf(sPool);
        if (TotalStakedTokens < TotalRewordsHolded) {
            uint256 ratio;
            ratio = TotalStakedTokens.div(TotalRewordsHolded);
            _swapAmount = _swapAmount.mul(ratio);
        }
        tokenTransfer(msg.sender, _swapAmount);
        TotalRewordsHolded = TotalRewordsHolded.sub(_swapAmount);
        _swapped = _swapAmount;
        return _swapped;
    }
}