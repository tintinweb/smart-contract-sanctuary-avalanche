/**
 *Submitted for verification at snowtrace.io on 2022-11-29
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

contract CircleFarm is Ownable, IERC20 {

    // name and symbol for tokenized contract
    string private constant _name = 'CSHARE LP Farm';
    string private constant _symbol = 'CSHARE FARM';
    uint8 private constant _decimals = 18;

    // Farming Token
    address public immutable token;

    // Reward Token
    address public constant reward = 0xa4CEE7A8Bf66A9FA0E1447950792E603bDdA9CAb;

    // User Info
    struct UserInfo {
        uint256 amount;
        uint256 totalExcluded;
    }
    // Address => UserInfo
    mapping ( address => UserInfo ) public userInfo;

    // Tracks Dividends
    uint256 public totalRewards;
    uint256 private totalShares;
    uint256 private dividendsPerShare;
    uint256 private constant precision = 10**18;

    constructor(
        address token_
    ){
        require(
            token_ != address(0),  
            'Zero Address'
        );
        token = token_;

        emit Transfer(address(0), msg.sender, 0);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) { 
        return totalShares; 
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) { 
        return userInfo[account].amount;
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address, address) external pure override returns (uint256) { 
        return 0; 
    }
    
    /** Token Name */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256) public override returns (bool) {
        emit Approval(msg.sender, spender, 0);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address recipient, uint256) external override returns (bool) {
        _claimReward(msg.sender);
        emit Transfer(msg.sender, recipient, 0);
        return true;
    }

    /** Transfer Function */
    function transferFrom(address, address recipient, uint256) external override returns (bool) {
        _claimReward(msg.sender);
        emit Transfer(msg.sender, recipient, 0);
        return true;
    }

    function withdrawForeignToken(address token_) external onlyOwner {
        require(
            token != token_,
            'Cannot Withdraw Farm Token'
        );
        require(
            IERC20(token_).transfer(
                msg.sender,
                IERC20(token_).balanceOf(address(this))
            ),
            'Failure On Token Withdraw'
        );
    }

    function claimRewards() external {
        _claimReward(msg.sender);
    }

    function withdraw(uint256 amount) external {
        require(
            amount <= userInfo[msg.sender].amount,
            'Insufficient Amount'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        if (userInfo[msg.sender].amount > 0) {
            _claimReward(msg.sender);
        }

        totalShares -= amount;
        userInfo[msg.sender].amount -= amount;
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].amount);

        require(
            IERC20(token).transfer(msg.sender, amount),
            'Failure On Token Transfer To Sender'
        );

        emit Transfer(msg.sender, address(0), amount);
    }

    function emergencyWithdraw() external {
        require(
            userInfo[msg.sender].amount > 0,
            'Insufficient Amount'
        );

        // decrement amount from supply and user
        uint bal = userInfo[msg.sender].amount;
        totalShares -= bal;
        userInfo[msg.sender].amount = 0;
        emit Transfer(msg.sender, address(0), bal);

        // send token to user
        require(
            IERC20(token).transfer(msg.sender, bal),
            'Failure On Token Transfer To Sender'
        );
    }

    function deposit(uint256 amount) external {
        if (userInfo[msg.sender].amount > 0) {
            _claimReward(msg.sender);
        }

        // transfer in tokens
        uint received = _transferIn(token, amount);
        
        // update data
        totalShares += received;
        userInfo[msg.sender].amount += received;
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].amount);
        emit Transfer(address(0), msg.sender, received);
    }

    function depositRewards(uint256 amount) external {
        uint received = _transferIn(reward, amount);
        totalRewards += received;
        if (totalShares > 0) {
            dividendsPerShare += ( precision * received ) / totalShares;
        }
    }

    function _claimReward(address user) internal {

        // exit if zero value locked
        if (userInfo[user].amount == 0) {
            return;
        }

        // fetch pending rewards
        uint256 amount = pendingShare(user);

        // fetch balance of rewards
        uint256 rewardBalance = IERC20(reward).balanceOf(address(this));
        if (amount > rewardBalance) {
            amount = rewardBalance;
        }

        // update total excluded
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].amount);
        
        // exit if zero rewards
        if (amount == 0) {
            return;
        }

        // transfer reward to user
        require(
            IERC20(reward).transfer(user, amount),
            'Failure On Token Claim'
        );
    }

    function _transferIn(address _token, uint256 amount) internal returns (uint256) {
        uint before = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        uint After = IERC20(_token).balanceOf(address(this));
        require(
            After > before,
            'Error On Transfer From'
        );
        return After - before;
    }

    function pendingShare(address shareholder) public view returns (uint256) {
        if(userInfo[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(userInfo[shareholder].amount);
        uint256 shareholderTotalExcluded = userInfo[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return ( share * dividendsPerShare ) / precision;
    }
}