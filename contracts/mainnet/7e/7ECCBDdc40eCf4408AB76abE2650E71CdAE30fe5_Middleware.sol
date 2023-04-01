/**
 *Submitted for verification at snowtrace.io on 2023-03-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
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

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

  
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


abstract contract VotingContract {
    function createBallot(string memory name,string[] memory _choices,uint256 offset) public virtual;
    function vote(address account, uint256 ballotId, uint256 choiceId, uint256 amount) external virtual;
}

abstract contract MembershipContract {
    function isMember(address member) virtual external view returns (bool);
    function subscribe(address member) external virtual;
    function unSubscribe(address member) external virtual;
}

abstract contract HandlerContract {
    function getTransaction(uint256 _txId) virtual external view 
        returns(address _owner, uint256 _amount, uint256 _timestamp);
    function getLockedFund(address account) virtual external view 
        returns(address _owner, uint256 _amount, uint256 _timestamp);
    function queue(address _owner, uint256 _amount) external virtual returns (uint256);
    function cancel(uint256 _txId, address _owner) external virtual returns(uint256);
    function execute(uint256 _txId) external virtual returns(address, uint256);
    function withdraw(address account) external virtual returns(uint256, uint256);
}

abstract contract VeZeusContract {
    function stake(address account, uint256 amount) external virtual;
    function unStake(address account) external virtual returns(uint256);
    function withdrawVeZeus(address account) external virtual returns(uint256);
    function totalZeusStaked() external view virtual returns(uint256);
    function profitPerSecond(address account) external view virtual returns(uint256);
    function getZeusStaked(address account) external view virtual returns(uint256);
}

contract Middleware {
    using SafeMath for uint;

    address public currentBallotCreator;
    address public admin;
    address public collector = 0x67dD4EA99CE6453f28DA3b08d0257063189121e6;
    address public vzeusCollector = 0x67dD4EA99CE6453f28DA3b08d0257063189121e6;

    uint256 public waitingTime = 60; //1 minute pending time
    uint256 public maxDeposit = 2;
    uint256 public minDeposit = 1;
    uint256 public lastRun;
    mapping(address => uint256) public lastInit;
    uint256[4] public lockupPayoutPercentages = [60,70, 80];
    mapping(address => uint256) public timeBeforeStaking;
    mapping(address => uint256) public userLatestTxId;

    address public votingContractAddress;
    address public membershipContractAddress;
    address public handlerContractAddress;
    address public veZeusContractAddress;
    VotingContract votingContract;
    MembershipContract membershipContract;
    HandlerContract handlerContract;
    VeZeusContract veZeusContract;
    ERC20 USDC = ERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    ERC20 VEZEUS = ERC20(0x13F88dfA55fb50F9BE742869EC5f35D16d6B7a8f);
    ERC20 Zeus = ERC20(0x8C3633eE619a42d3755327C2524E4d108838c47f);

    constructor(address _votingContractAddress, address _membershipContractAddress, 
        address _handlerContractAddress, address _veContractAddress) {
        admin = msg.sender;
        votingContractAddress = _votingContractAddress;
        membershipContractAddress = _membershipContractAddress;
        handlerContractAddress = _handlerContractAddress;
        veZeusContractAddress = _veContractAddress;
        votingContract = VotingContract(_votingContractAddress);
        membershipContract = MembershipContract(_membershipContractAddress);
        handlerContract = HandlerContract(_handlerContractAddress);
        veZeusContract = VeZeusContract(_veContractAddress);
        
    }

    function updateTokens(address _usdc, address _vezeus, address _zeus) external onlyAdmin{
        USDC = ERC20(_usdc);
        VEZEUS = ERC20(_vezeus);
        Zeus = ERC20(_zeus);
    }

    function updateVotingContract(address _votingContractAddress
    ) external onlyAdmin {
        votingContractAddress = _votingContractAddress;
        votingContract = VotingContract(_votingContractAddress);
    }

    function updateMembershipContract(address _membershipContractAddress
    ) external onlyAdmin {
        membershipContractAddress = _membershipContractAddress;
        membershipContract = MembershipContract(_membershipContractAddress);
    }

    function updateHandlerContract(address _handlerContractAddress
    ) external onlyAdmin {
        handlerContractAddress = _handlerContractAddress;
        handlerContract = HandlerContract(_handlerContractAddress);
    }

    function updateVeZeusContract(address _veContractAddress
    ) external onlyAdmin {
        veZeusContractAddress = _veContractAddress;
        veZeusContract = VeZeusContract(_veContractAddress);
    }

    function totalZeusStaked() external view returns(uint256) {
        return veZeusContract.totalZeusStaked();
    }

    function totalVeZeusReward(address account) external view returns(uint256) {
        return veZeusContract.profitPerSecond(account);
    }

     function getZeusStaked(address account) external view returns(uint256) {
        return veZeusContract.getZeusStaked(account);
    }

    function initialize(uint256 amount) external {
        address account = msg.sender;
        uint256 _lastInit = lastInit[account];
        uint256 diff = lastRun - _lastInit;
        if(lastRun > 0 && _lastInit > 0){
            require(lastRun > _lastInit && diff >= 60, "Queue:Existing data"); //prevent multiple queing by users
        }
        uint256 waitTime = timeBeforeStaking[account];
        require(block.timestamp >= waitTime + 180, "Interval error"); //User can only trigger staking every 3 minutes
        require(amount >= minDeposit, "min:Amount not within constraint");
        require(account != address(0), "Invalid address");
        uint256 usdcAmount = amount.mul(10**6);
        USDC.transferFrom(account, collector, usdcAmount);
         //ensure user has not exceeded max stake amount
        (,uint256 _amount,) = handlerContract.getLockedFund(account);
        require(_amount+amount <= maxDeposit, "max:Amount not within constraint");
        uint256 txnId = handlerContract.queue(account, amount);
        userLatestTxId[account] = txnId;
        timeBeforeStaking[account] = block.timestamp;
        lastInit[account] = block.timestamp;
    }

    function userUsdcStaked(address account) external view returns(uint256){
        (,uint256 amount,) = handlerContract.getLockedFund(account);
        return amount;
    }

    function stake(uint256 amount) external {
        address account = msg.sender;
        bool isMember = membershipContract.isMember(account);
        require(amount > 0, "Invalid amount");
        require(isMember, "Not subscribed");
        uint256 zeusAmount = amount.mul(10**18);
        Zeus.transferFrom(account, collector, zeusAmount);
        veZeusContract.stake(account, amount);

    }

     function unStake() external {
        address account = msg.sender;
        uint256 amount = veZeusContract.unStake(account);
        uint256 zeusAmount = amount * 10**18;
        Zeus.transferFrom(collector, account, zeusAmount);
    }

    function subscribed(address account) external view returns(bool){
        return membershipContract.isMember(account);
    }

    function vote(uint ballotId, uint256 choiceId, uint256 amount) external {
        address account = msg.sender;
        bool isMember = membershipContract.isMember(account);
        require(isMember, "Not subscribed");
        uint256 veZeusAmount = amount.mul(10**18);
        VEZEUS.transferFrom(account, vzeusCollector, veZeusAmount);
        votingContract.vote(account,ballotId,choiceId,amount);
    }

    function cancelTransaction(uint256 _txId) public {
        address account = msg.sender;
        uint256 amount = handlerContract.cancel(_txId, account);
        uint256 usdcAmount = amount.mul(10**6);
        USDC.transferFrom(collector, account, usdcAmount);
        lastInit[account] = lastRun - 60;
    }

    function executeTransaction(uint256[] memory _txIds) public {
        for(uint256 i = 0; i < _txIds.length; i++){
            (address account,) = handlerContract.execute(_txIds[i]);
            membershipContract.subscribe(account);
        }
        lastRun = block.timestamp;
    }

    function updateCollector(address _collector) external onlyAdmin{
        collector = _collector;
    }

    function withdrawUSDC() external {
        address account = msg.sender;
        (uint256 amount, uint256 timestamp) = handlerContract.withdraw(account);
        uint256 usdcAmount = amount.mul(10**6);
        uint256 payableAmount;
        if(block.timestamp < (timestamp + 30 days)) {
            payableAmount = usdcAmount - (lockupPayoutPercentages[0].div(100) * usdcAmount);
        }
        if(block.timestamp >= timestamp.add(30 days) && block.timestamp < timestamp.add(60 days)){
            payableAmount = usdcAmount - (lockupPayoutPercentages[1].div(100) * usdcAmount);
        }
        if(block.timestamp >= timestamp.add(60 days) && block.timestamp < timestamp.add(90 days)){
            payableAmount = usdcAmount - (lockupPayoutPercentages[2].div(100) * usdcAmount);
        }
        if(block.timestamp >= timestamp.add(90 days)){
            payableAmount = usdcAmount;
        }
        
        USDC.transferFrom(collector, account, payableAmount);
        membershipContract.unSubscribe(account);
    }

    function withdrawVEZEUS() external {
        address account = msg.sender;
        uint256 amount = veZeusContract.withdrawVeZeus(account);
        VEZEUS.transferFrom(collector, account, amount);
    }

    function getAccountTransactions(uint256 _txId) view public 
        returns(address _owner, uint256 _amount, uint256 _timestamp){
        return handlerContract.getTransaction(_txId);
    }

    function setCurrentBallotCreator(address _creator) external onlyAdmin {
        currentBallotCreator = _creator;
    }

    function setMaxAndMinDeposit(uint256 max, uint256 min) external onlyAdmin{
        maxDeposit = max;
        minDeposit = min;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized");
        _;
    }
    modifier ballotCreator(){
        require(msg.sender == admin || msg.sender == currentBallotCreator, "unauthorized");
        _;
    }
}