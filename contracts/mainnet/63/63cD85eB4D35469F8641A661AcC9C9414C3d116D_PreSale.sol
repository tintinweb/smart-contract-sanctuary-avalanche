/**
 *Submitted for verification at snowtrace.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PreSale is Ownable {

    using SafeMath for uint256;

    struct UserInfo {
        address buyer;
        uint256 rctokenAmount;
    }

    address public Recipient;
    IERC20 public PTOKEN;
    IERC20 public RCTOKEN = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    uint256 public RCTOKEN_DECIMAL = 6;

    uint256 public tokenPrice = 1.2 * 10;
    uint256 public minBuyLimit = 50 * 10 ** RCTOKEN_DECIMAL;
    uint256 public maxBuyLimit = 1500 * 10 ** RCTOKEN_DECIMAL;

    uint256 public softCap = 50000 * 10 ** RCTOKEN_DECIMAL;
    uint256 public hardCap = 100000 * 10 ** RCTOKEN_DECIMAL;

    uint256 public totalRaisedAmount = 0; // total USDC raised by sale
    uint256 public totaltokenSold = 0;

    uint256 public startTime;
    uint256 public endTime;
    bool public isPrivate;
    bool public claimOpened;
    bool public contractPaused; // circuit breaker

    mapping(address => bool) public whiteListed;
    mapping(address => uint256) private _totalPaid;
    mapping(address => UserInfo) public userinfo;

    event Deposited(uint amount);
    event Claimed(address receiver, uint amount);

    constructor(uint256 _startTime, uint256 _endTime) {
        require(_startTime > block.timestamp, 'past timestamp');
        Recipient = msg.sender;
        startTime = _startTime;
        if(_endTime > _startTime + 1 days) {
            endTime = _endTime;
        } else {
            endTime = _startTime + 7 days;
        }
    }

    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }
    
    function setPresaleToken(address tokenaddress) external onlyOwner {
        require( tokenaddress != address(0) );
        PTOKEN = IERC20(tokenaddress);
    }

    function setRecipient(address recipient) external onlyOwner {
        Recipient = recipient;
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function setMinBuyLimit(uint256 amount) external onlyOwner {
        minBuyLimit = amount;    
    }

    function setMaxBuyLimit(uint256 amount) external onlyOwner {
        maxBuyLimit = amount;    
    }
    
    function updateCap(uint256 _hardcap, uint256 _softcap) external onlyOwner {
        softCap = _softcap;
        hardCap = _hardcap;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, 'past timestamp');
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > startTime, 'should be bigger than start time');
        endTime = _endTime;
    }

    function openClaim(address pTokenaddress) external onlyOwner {
        require( pTokenaddress != address(0) );
        require(!claimOpened, 'Already opened');
        require(block.timestamp > endTime, 'Presale not over yet');
        PTOKEN = IERC20(pTokenaddress);
        claimOpened = true;
    }

    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }

    function toggleSale() external onlyOwner returns (bool) {
        isPrivate = !isPrivate;
        return isPrivate;
    }

    function addMultipleAccountsToWhiteList(address[] calldata _accounts, bool _value) public onlyOwner {
        for(uint256 i = 0; i < _accounts.length; i++) {
            whiteListed[_accounts[i]] = _value;
        }
    }

    function addWhiteList(address _account) public onlyOwner {
        whiteListed[_account] = true;
    }
    
    function removeWhiteList(address _account) public onlyOwner {
        whiteListed[_account] = false;
    }

    function deposit(uint256 amount) public checkIfPaused {
        require(block.timestamp > startTime, 'Sale has not started');
        require(block.timestamp < endTime, 'Sale has ended');
        require(totalRaisedAmount <= hardCap, 'HardCap exceeded');
        require(
                _totalPaid[msg.sender].add(amount) <= maxBuyLimit
                && _totalPaid[msg.sender].add(amount) >= minBuyLimit,
                "Investment Amount Invalid."
        );
        if(isPrivate) {
            require(whiteListed[msg.sender], 'Private sale');
        }
        
        if (userinfo[msg.sender].buyer == address(0)) {
            UserInfo memory l;
            l.buyer = msg.sender;
            l.rctokenAmount = amount;
            userinfo[msg.sender] = l;
        }
        else {
            userinfo[msg.sender].rctokenAmount += amount;
        }

        totalRaisedAmount = totalRaisedAmount.add(amount);
        uint256 tokenAmount = amount.div(tokenPrice);
        totaltokenSold = totaltokenSold.add(tokenAmount);
        _totalPaid[msg.sender] = _totalPaid[msg.sender].add(amount);
        IERC20(RCTOKEN).transferFrom(msg.sender, address(this), amount);
        emit Deposited(amount);
    }

    function claim() public {
        UserInfo storage l = userinfo[msg.sender];
        require(claimOpened, "Claim not open yet");
        require(l.buyer == msg.sender, "You are not allowed to claim");
        require(l.rctokenAmount > 0, "Invaild");
        
        uint256 amount = l.rctokenAmount.div(tokenPrice);
        l.rctokenAmount = 0;
        require(amount <= PTOKEN.balanceOf(address(this)), "Insufficient balance");
        PTOKEN.transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function getUnsoldTokens(address token, address to) external onlyOwner {
        require(block.timestamp > endTime, "You cannot get tokens until the presale is closed.");
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)) );
    }

    function getUserRemainingAllocation(address account) external view returns ( uint256 ) {
        return maxBuyLimit.sub(_totalPaid[account]);
    }
}