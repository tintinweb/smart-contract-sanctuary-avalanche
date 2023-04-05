// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AppSurd is IERC20 {
    string public constant name = "app.surd";
    string public constant symbol = "asurd";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply = 100_000_000 * (10 ** uint256(decimals));

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public marketingWallet = 0xab9da3BbC27FaBf394B0B4D514e4F27af5a378A4;
    uint256 public commissionRate = 10;

    uint256 public maxPurchaseAmount;
    bool public lockSales;
    address public owner;

    mapping(address => bool) public frozenAccounts;
    mapping(address => uint256) public lockedTokens;

    mapping(address => bool) public blockedAddresses;
    uint256 public discountRate;

    address public developmentFund;
    uint256 public developmentFundPercentage;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    event TokensLocked(address indexed account, uint256 amount);
    event TokensUnlocked(address indexed account, uint256 amount);
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event AddressBlocked(address indexed account);
    event AddressUnblocked(address indexed account);
    event DiscountRateChanged(uint256 newDiscountRate);
    event DevelopmentFundChanged(address indexed newDevelopmentFund);
    event DevelopmentFundPercentageChanged(uint256 newDevelopmentFundPercentage);
    event Airdropped(address indexed recipient, uint256 amount);
    constructor() {
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        maxPurchaseAmount = _totalSupply;
        lockSales = false;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 discountedAmount = _applyDiscount(amount);
        _transfer(msg.sender, recipient, discountedAmount);
        return true;
    }

    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)     public override returns (bool) {
        uint256 discountedAmount = _applyDiscount(amount);
        _transfer(sender, recipient, discountedAmount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(!lockSales || msg.sender == owner, "Sales are locked");
        require(!blockedAddresses[sender], "Sender address is blocked");
        require(!blockedAddresses[recipient], "Recipient address is blocked");
        require(!frozenAccounts[sender], "Sender account is frozen");
        require(!frozenAccounts[recipient], "Recipient account is frozen");
        require(amount <= maxPurchaseAmount, "Amount exceeds the maximum purchase amount");

        uint256 commission = (amount * commissionRate) / 100;
        uint256 developmentFundAmount = (amount * developmentFundPercentage) / 100;
        uint256 netAmount = amount - commission - developmentFundAmount;

        _balances[sender] -= amount;
        _balances[recipient] += netAmount;
        _balances[marketingWallet] += commission;
        _balances[developmentFund] += developmentFundAmount;

        emit Transfer(sender, recipient, netAmount);
        emit Transfer(sender, marketingWallet, commission);
        emit Transfer(sender, developmentFund, developmentFundAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMaxPurchaseAmount(uint256 newMaxPurchaseAmount) public onlyOwner {
        maxPurchaseAmount = newMaxPurchaseAmount;
    }

    function toggleLockSales() public onlyOwner {
        lockSales = !lockSales;
    }

    function lockTokens(address account, uint256 amount) public onlyOwner {
        require(_balances[account] >= amount, "Not enough tokens to lock");
        _balances[account] -= amount;
        lockedTokens[account] += amount;
        emit TokensLocked(account, amount);
    }

    function unlockTokens(address account, uint256 amount) public onlyOwner {
        require(lockedTokens[account] >= amount, "Not enough tokens to unlock");
        lockedTokens[account] -= amount;
        _balances[account] += amount;
        emit TokensUnlocked(account, amount);
    }

    function freezeAccount(address account) public onlyOwner {
        frozenAccounts[account] = true;
        emit AccountFrozen(account);
    }

    function unfreezeAccount(address account) public onlyOwner {
        frozenAccounts[account] = false;
        emit AccountUnfrozen(account);
    }

    function blockAddress(address account) public onlyOwner {
        blockedAddresses[account] = true;
        emit AddressBlocked(account);
    }

    function unblockAddress(address account) public onlyOwner {
        blockedAddresses[account] = false;
        emit AddressUnblocked(account);
    }

    function setDiscountRate(uint256 newDiscountRate) public onlyOwner {
        require(newDiscountRate <= 100, "Invalid discount rate");
        discountRate = newDiscountRate;
        emit DiscountRateChanged(newDiscountRate);
    }

    function _applyDiscount(uint256 amount) internal view returns (uint256) {
        return (amount * (100 - discountRate)) / 100;
    }

    function setDevelopmentFund(address newDevelopmentFund) public onlyOwner {
        require(newDevelopmentFund != address(0), "Invalid address");
        developmentFund = newDevelopmentFund;
        emit DevelopmentFundChanged(newDevelopmentFund);
    }

    function setDevelopmentFundPercentage(uint256 newDevelopmentFundPercentage) public onlyOwner {
        require(newDevelopmentFundPercentage <= 100, "Invalid percentage");
        developmentFundPercentage = newDevelopmentFundPercentage;
        emit DevelopmentFundPercentageChanged(newDevelopmentFundPercentage);
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner, recipients[i], amounts[i]);
            emit Airdropped(recipients[i], amounts[i]);
        }
    }
}