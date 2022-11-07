/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract CarbonStaking is Ownable {

    using SafeMath for uint256;

    IERC20 public Carbon;

    uint256 public SAPY = 21 * 10**11;
    uint256 public Delta = 28935;
    uint256 public FAPY = 3 * 10**11;
    uint256 public denominator = 10**13;
    uint256 public series = 31536000;

    uint256 public startTime;
    uint256 public EndTime;        //Two Years
    uint256 public StakedTimeLimit;

    struct record {
        address _user;
        uint256 _totalAmount;
        uint256 _tobeRewarded;
        // uint256[] _multiAmount;
        // uint256[] _MultiApys;
        // uint256[] _multiTime;
        uint256 _StakedCount;
    }

    mapping (address => record) public _userData;

    uint256 public totalStaked;
    bool public paused;

    constructor() {
        startTime = block.timestamp;
        EndTime = startTime + 60 minutes;
        StakedTimeLimit = startTime + 30 minutes;
        Carbon = IERC20(0x44a00f525F4893aece727D354c68Eb4BecfBF1D8);
    }

    function stake(uint256 _amount) public {
        require(!paused,"Error: Staking is Currently Paused Now!!");

        if(block.timestamp > StakedTimeLimit) {
            revert("Error: Staking Time Over!!");
        }

        address account = msg.sender;
        
        Carbon.transferFrom(account, address(this), _amount);

        _userData[account]._user = account;
        _userData[account]._totalAmount += _amount;
        // _userData[account]._MultiApys.push(getApy());
        // _userData[account]._multiTime.push(block.timestamp);
        // _userData[account]._multiAmount.push(_amount);
        _userData[account]._StakedCount++;

        uint256 rPAmount = perSec(_amount);

        uint256 sdelta = EndTime - block.timestamp;
        uint256 TobeRewarded =  rPAmount * sdelta;

        _userData[account]._tobeRewarded += TobeRewarded;

        totalStaked += _amount;
    }

    function unstake() public {
        require(!paused,"Error: Staking is Currently Paused Now!!");

        if(block.timestamp < EndTime) {
            revert("Error: Can't Unstake Now!!");
        }

        address account = msg.sender;
        uint256 stakedAmount = _userData[account]._totalAmount;
        uint256 toBeRewarded = _userData[account]._tobeRewarded;
        uint256 totalTransferable = stakedAmount + toBeRewarded;

        require(stakedAmount > 0,"Error: No Record Found!");

        Carbon.transfer(account,totalTransferable);

        _userData[account]._totalAmount = 0;
        // _userData[account]._MultiApys.push(0);
        // _userData[account]._multiTime.push(0);
        // _userData[account]._multiAmount.push(0);
        _userData[account]._StakedCount = 0; 
        _userData[account]._tobeRewarded = 0;

    }

    function perSec(uint _amount) internal view  returns (uint) {
        uint runningApy = getApy();
        uint Factor = ( _amount * runningApy ) / denominator;
        uint RewardAmount = Factor.div(series);
        return RewardAmount;
    }

    function getApy() public view returns (uint256) {
        uint sec = block.timestamp - startTime;
        uint fac = Delta * sec;
        uint res = SAPY - fac;
        return res < FAPY ? FAPY : res;
    }

    // function getUserMApys(address account) public view returns (uint256[] memory) {
    //     return _userData[account]._MultiApys;
    // }

    // function getUserMAmount(address account) public view returns (uint256[] memory) {
    //     return _userData[account]._multiAmount;
    // }

    // function getUserMTime(address account) public view returns (uint256[] memory) {
    //     return _userData[account]._multiTime; 
    // }

    function setPauser(bool _status) public onlyOwner {
        paused = _status;
    }

    //Use this in Emergency Case
    function setTimer(
        uint256 _start,
        uint256 _end,
        uint256 _stake    
    ) public onlyOwner {
        startTime = _start;
        EndTime = _end;
        StakedTimeLimit = _stake;
    }

    function rescueFunds() public onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Error: Transaction Failed!");
    }   

    function rescueTokens(IERC20 token) public onlyOwner {
        uint _tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender,_tokenBalance);
    }

    function setCarbon(address _token) public onlyOwner {
        Carbon = IERC20(_token);
    }


}