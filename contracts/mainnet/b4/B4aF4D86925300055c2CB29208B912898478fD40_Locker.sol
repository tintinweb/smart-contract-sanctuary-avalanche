/**
 *Submitted for verification at snowtrace.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface TokenContract {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function basicTransfer(address from, address to, uint256 amount) external;
}


contract Locker {
    TokenContract public _tokenContract;
    address public creator;
    bool public initialized;

    constructor() {
       creator = msg.sender;
    }

    modifier onlyOwner() {
        require(address(_tokenContract) == msg.sender, "Only native contract may call.");
        _;
    }

    receive() external payable {
        revert(); // Reject all native currency.
    }

    function setToken(address token) external {
        require(!initialized, "Already initialized.");
        require(msg.sender == creator, "Only creator may call.");
        lockerToken = token;
        _tokenContract = TokenContract(token);
    }

    function initialize(address _pairToken) external {
        require(tx.origin == creator);
        require(!initialized);
        pairToken = _pairToken;
        IERC20_PairToken = IERC20(_pairToken);
        initialized = true;
    }

    function withdrawForeignToken(address account, address _token) external onlyOwner {
        require(_token != address(_tokenContract), "Cannot withdraw locker designated token.");
        IERC20 token = IERC20(_token);
        token.transfer(account, token.balanceOf(address(this)));
    }

//===============================================================================================================
//===============================================================================================================

    uint256 lpUnlockTime;
    address pair;

    address pairToken;
    IERC20 public IERC20_PairToken;

    function lockLP(uint256 timeInSeconds) external onlyOwner {
        lpUnlockTime = block.timestamp + timeInSeconds;
    }

    function getRemainingLPLockTime() external view returns (uint256) {
        if (block.timestamp > lpUnlockTime) {
            return 0;
        } else {
            return(lpUnlockTime - block.timestamp);
        }
    }

    function extendLPLockBySetTime(uint256 time) public onlyOwner {
        require(time > lpUnlockTime && time > block.timestamp, "Must be after current lock time.");
        lpUnlockTime = time;
    }

    function extendLPLockBySeconds(uint256 timeInSeconds) external onlyOwner {
        extendLPLockBySetTime(lpUnlockTime + timeInSeconds);
    }

    function withdrawLiquidity(address account) external onlyOwner {
        require(block.timestamp > lpUnlockTime, "Lock time not expired yet.");
        IERC20_PairToken.transfer(account, IERC20_PairToken.balanceOf(address(this)));
    }

//===============================================================================================================
//===============================================================================================================
    
    address public lockerToken;
    mapping (address => bool) private lockEnabled;
    mapping (address => uint256) private tokensLocked;
    mapping (address => uint256) private tokensUnlockTime;

    function lockInitialTokens(address account, uint256 amount, uint256 timeInSeconds) external onlyOwner {
        require(lockEnabled[account] == false, "Lock already created!");
        _tokenContract.basicTransfer(account, address(this), amount);
        tokensLocked[account] = amount;
        tokensUnlockTime[account] = block.timestamp + timeInSeconds;
        lockEnabled[account] = true;
    }

    function lockAdditionalTokens(address account, uint256 amount) external onlyOwner {
        require(lockEnabled[account] == true, "Can only call after lock has been created.");
        _tokenContract.basicTransfer(account, address(this), amount);
        tokensLocked[account] += amount;
    }

    function getRemainingTokenLockTime(address account) external view returns (uint256) {
        if (block.timestamp > tokensUnlockTime[account]) {
            return 0;
        } else {
            return(tokensUnlockTime[account] - block.timestamp);
        }
    }

    function getLockedTokenAmount(address account) external view returns (uint256) {
        if (tokensLocked[account] == 0) {
            return 0;
        } else {
            return tokensLocked[account] / (10**_tokenContract.decimals());
        }
    }

    function getRawLockedAmount(address account) external view returns (uint256) {
        return tokensLocked[account];
    }

    function extendTokenLockBySetTime(address account, uint256 time) public onlyOwner {
        require(time > tokensUnlockTime[account] && time > block.timestamp, "Must be after current lock time, and not in the past.");
        tokensUnlockTime[account] = time;
    }

    function extendTokenLockBySeconds(address account, uint256 timeInSeconds) external onlyOwner {
        extendTokenLockBySetTime(account, tokensUnlockTime[account] + timeInSeconds);
    }

    function withdrawTokens(address account) external onlyOwner {
        require(lockEnabled[account] == true && tokensLocked[account] > 0, "Lock not enabled or no tokens to withdraw.");
        require(block.timestamp > tokensUnlockTime[account], "Lock has not expired yet.");
        uint256 withdrawAmount = tokensLocked[account];
        delete tokensLocked[account];
        delete tokensUnlockTime[account];
        delete lockEnabled[account];
        _tokenContract.basicTransfer(address(this), account, withdrawAmount);
    }
}