// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

contract ArcadeManager {
    // We received only 3 tokens
    IERC20 public BUSDToken;
    IERC20 public DAIToken;
    IERC20 public BONKToken;

    address payable public owner;
    address payable public manager;

    // Interest rate when doing transaction 
    uint public interestRate; // If we want to set it as 0.001% we will set it as 100000

    // Keep track of tokens
    uint public BUSDTotalSupply;
    uint public DAITotalSupply;
    uint public BONKTotalSupply;

    // Events
    event SetToken(IERC20 tokenFrom, address tokenTo, uint time);
    event SetManager(address manager, uint time);
    event SetInterestRate(address user, uint interestRate, uint time);
    event Deposit(address token, uint amount, uint time);
    event DistributeReward(address token, address user, uint amount, uint time);
    event Withdraw(address token, address user, uint amount, uint time);


    constructor(address _BUSDToken, address _DAIToken, address _BONKToken, address _manager, uint _interestRate) {
        owner = payable(msg.sender);
        BUSDToken = IERC20(_BUSDToken);
        DAIToken = IERC20(_DAIToken);
        BONKToken = IERC20(_BONKToken);
        manager = payable(_manager);
        interestRate = _interestRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "not authorized");
        _;
    }

    // Need to be test
    modifier onlyVIP() {
        bool result;
        if (msg.sender == owner || msg.sender == manager) {
            result = true;
        }else {
            result = false;
        }
        require(result, "not authorized");
        _;
    }

    // Owner Function Only
    function setInterestRate(uint _interestRate) external onlyOwner {
        emit SetInterestRate(msg.sender, _interestRate, block.timestamp);
        interestRate = _interestRate;
    }

    function setManagerAddress(address _manager) external onlyOwner {
        emit SetManager(_manager, block.timestamp);
        manager = payable(_manager);   
    }

    function setBONKToken(address _token) external onlyOwner {
        emit SetToken(BONKToken, _token, block.timestamp);
        BONKToken = IERC20(_token);
    }

    function setDAIToken(address _token) external onlyOwner {
        emit SetToken(DAIToken, _token, block.timestamp);
        DAIToken = IERC20(_token);
    }

    function setBUSDToken(address _token) external onlyOwner {
        emit SetToken(BUSDToken, _token, block.timestamp);
        BUSDToken = IERC20(_token);
    }

    // Let user deposit token to arcade
    function deposit(address _token, uint _amount) external {
        require(_amount > 0, "Deposit amount cannot be zero");
        IERC20 convert = IERC20(_token);
        if (convert == BONKToken) {
            emit Deposit(_token, _amount, block.timestamp);
            BONKToken.transferFrom(msg.sender, address(this), _amount);
            BONKTotalSupply += _amount;
        } else if (convert == BUSDToken) {
            emit Deposit(_token, _amount, block.timestamp);
            BUSDToken.transferFrom(msg.sender, address(this), _amount);
            BUSDTotalSupply += _amount;
        } else if (convert == DAIToken) {
            emit Deposit(_token, _amount, block.timestamp);
            DAIToken.transferFrom(msg.sender, address(this), _amount);
            DAITotalSupply += _amount;
        } else {
            revert("Token's address mismatched");
        }
    }

    // Send token to user as reward
    function distributeReward(address _token, address _user, uint _amount) external onlyVIP {
        require(_amount > 0, "Reward amount cannot be zero");
        // Calculate service charge
        //uint serviceCharge = _amount.div(interestRate);
        uint serviceCharge = _amount / interestRate;
        uint totalAmount = _amount - serviceCharge;
        // Check whether it exceed supply or not
        IERC20 convert = IERC20(_token);
        if (convert == BONKToken) {
            bool overload = _amount > BONKTotalSupply;
            if (overload) {
                revert("The amount of distribute exceed supply");
            }
            emit DistributeReward(_token, _user, _amount, block.timestamp);
            BONKTotalSupply -= totalAmount;
            BONKToken.transfer(_user, totalAmount); // Transfer to said user
        } else if (convert == BUSDToken) {
            bool overload = _amount > BUSDTotalSupply;
            if (overload) {
                revert("The amount of distribute exceed supply");
            }
            emit DistributeReward(_token, _user, _amount, block.timestamp);
            BUSDTotalSupply -= totalAmount;
            BUSDToken.transfer(_user, totalAmount);
        } else if (convert == DAIToken) {
            bool overload = _amount > DAITotalSupply;
            if (overload) {
                revert("The amount of distribute exceed supply");
            }
            emit DistributeReward(_token, _user, _amount, block.timestamp);
            DAITotalSupply -= totalAmount;
            DAIToken.transfer(_user, totalAmount);
        } else {
            revert("Token's address mismatched");
        }
    }

    // Withdraw 
     function withdraw(address _token, address _user, uint _amount) external onlyOwner{
        require(_amount > 0, "Withdraw amount cannot be zero");
        // Check whether it exceed supply or not
        IERC20 convert = IERC20(_token);
        if (convert == BONKToken) {
            bool overload = _amount > BONKTotalSupply;
            if (overload) {
                revert("The amount of withdraw exceed supply");
            }
            emit Withdraw(_token, _user, _amount, block.timestamp);
            BONKTotalSupply -= _amount;
            BONKToken.transfer(_user, _amount); // Transfer to said user
        } else if (convert == BUSDToken) {
            bool overload = _amount > BUSDTotalSupply;
            if (overload) {
                revert("The amount of withdraw exceed supply");
            }
            emit Withdraw(_token, _user, _amount, block.timestamp);
            BUSDTotalSupply -= _amount;
            BUSDToken.transfer(_user, _amount);
        } else if (convert == DAIToken) {
            bool overload = _amount > DAITotalSupply;
            if (overload) {
                revert("The amount of withdraw exceed supply");
            }
            emit Withdraw(_token, _user, _amount, block.timestamp);
            DAITotalSupply -= _amount;
            DAIToken.transfer(_user, _amount);
        } else {
            revert("Token's address mismatched");
        }
    }


}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}