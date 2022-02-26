/**
 *Submitted for verification at snowtrace.io on 2022-02-26
*/

// SPDX-License-Identifier: UNLICENSIED

// Some Test Contract

pragma solidity ^0.8.5;

// ------------------------------------------------------------- //

library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math : addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "Math : subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Math : multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Math : division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

// ------------------------------------------------------------- //

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

// ------------------------------------------------------------- //

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// ------------------------------------------------------------- //

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// ------------------------------------------------------------- //

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// ------------------------------------------------------------- //

contract Virus is IERC20, Auth {
    using Math for uint256;

    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Virus";
    string constant _symbol = "Virus";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxWalletSize = (_totalSupply * 1) / 100; 
    uint256 public _minTransferForInfection = 1 * (10 ** _decimals); 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    
    mapping (address => bool) isFeeExempt;
    mapping (address => address) public infector;
    mapping (address => uint256) public totalInfected;
    mapping (address => uint256) public totalRewards;
    mapping (address => bool) public isInfected;
    mapping (address => bool) isBlacklisted;

    // Sell - Not Infected Fees (20%)
    // Buy - Not Infected Fees (20%)

    uint256 devFeesNotInfected = 2;
    uint256 marketingFeesNotInfected = 18;
    uint256 totalFeesNotInfected = 20;

    // Sell - Infected Fees (15%)

    uint256 liquidityFees = 3;
    uint256 devFees = 2;
    uint256 marketingFees = 10;
    uint256 totalFees = 15;

    // Buy - Infected Fees (5%)
    // These fees are distributed to your infector

    uint256 infectedFees = 5;

    // Fee Denominator

    uint256 feeDenominator = 100;


    uint256 public minSupplyForInfectionReward = (_totalSupply * 1) / 1000;
    
    address private marketingFeesReceiver = 0xE14EE18c160101756aEaE203FB92F67716B3Cf15;
    address private devFeesReceiver = 0xE14EE18c160101756aEaE203FB92F67716B3Cf15;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%
    uint256 public lastSwapTime = block.timestamp;
    uint256 public swapTimeLock = 15 minutes;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event InfectedBonus(address indexed feesTo , address indexed feesFrom , uint value);
    event Infected(address indexed infected,address indexed infector);

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[pair] = true;
        isFeeExempt[address(router)] = true;

        isInfected[_owner] = true;
        
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }    

        if (recipient != pair && recipient != DEAD) {
            require(isFeeExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize, "Transfer amount exceeds the bag size.");
            require(!isBlacklisted[sender], "Blacklisted.");
        }

        uint256 amountReceived = amount; 

// ------------------------------------------------------------- //
        
        if(sender == pair) { // Buy

            if(!isFeeExempt[recipient]) {

                if(isInfected[recipient]) { // if Infected Buy
                amountReceived = takeInfectedFees(recipient,amount);
                }
                else if(!isInfected[recipient]) { // if Not Infected Buy
                amountReceived = takeNotInfectedFees(recipient,amount);
                }
            }

        } else if(recipient == pair) { // Sell

            if(!isFeeExempt[sender]) { 

                require(!isBlacklisted[sender], "You're Blacklisted.");

                if(isInfected[sender]) { // if Infected Sell
                amountReceived = takeSellInfectedFees(sender, amount);
                }
                else if(!isInfected[sender]) { // if Not Infected Sell
                amountReceived = takeNotInfectedFees(sender, amount);
                } 
            }

        } else if(isInfected[recipient]==false) {
            if(amount >= _minTransferForInfection) {
                isInfected[recipient] = true;
                infector[recipient] = sender;
                emit Infected(recipient,sender);
            }
        } 

// ------------------------------------------------------------- //
        
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeInfectedFees(address from,uint256 amount) internal returns(uint) {
        uint256 infectionTokens = infectedFees * amount / feeDenominator;
        if(_balances[infector[from]] > minSupplyForInfectionReward) {
            _balances[infector[from]] = _balances[infector[from]].add(infectionTokens);
            totalRewards[infector[from]] = totalRewards[infector[from]].add(infectionTokens);
            if(_balances[from] <= 1e9){
            totalInfected[infector[from]] = totalInfected[infector[from]].add(1);
            }
            emit InfectedBonus(infector[from],from,infectionTokens);
        } else {
             _balances[marketingFeesReceiver] = _balances[marketingFeesReceiver].add(infectionTokens);
            emit InfectedBonus(marketingFeesReceiver,from,infectionTokens);
        }

        return amount - infectionTokens;
    }
    
    function shouldTakeFees(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    // Take Infected Fees

    function takeSellInfectedFees(address sender, uint256 amount) internal returns (uint256) {
        uint256 feesAmount = amount.mul(totalFees).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feesAmount);
        emit Transfer(sender, address(this), feesAmount);

        return amount.sub(feesAmount);
    }

    // Take Not Infected Fees

    function takeNotInfectedFees(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeNotInfectedAmount = amount.mul(totalFeesNotInfected).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeNotInfectedAmount);
        emit Transfer(sender, address(this), feeNotInfectedAmount);

        return amount.sub(feeNotInfectedAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && block.timestamp > lastSwapTime + swapTimeLock
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        lastSwapTime = block.timestamp;
        uint256 amountToLiquify = swapThreshold.mul(liquidityFees).div(totalFees).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountAVAX = address(this).balance.sub(balanceBefore);
        uint256 totalAVAXFee = totalFees.sub(liquidityFees.div(2));
        uint256 amountAVAXLiquidity = amountAVAX.mul(liquidityFees).div(totalAVAXFee).div(2);
        uint256 amountAVAXDev = amountAVAX.mul(devFees).div(totalAVAXFee);
        uint256 amountAVAXMarketing = amountAVAX - amountAVAXLiquidity - amountAVAXDev;

        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeesReceiver).call{value: amountAVAXMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected AVAX transfer");
        (bool DevSuccess, /* bytes memory data */) = payable(devFeesReceiver).call{value: amountAVAXDev, gas: 30000}("");
        require(DevSuccess, "receiver rejected AVAX transfer");
        addLiquidity(amountToLiquify, amountAVAXLiquidity);
    }

    function addLiquidity(uint256 tokenAmount, uint256 AVAXAmount) private {
        if(tokenAmount > 0){
                router.addLiquidityAVAX{value: AVAXAmount}(
                    address(this),
                    tokenAmount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
                emit AutoLiquify(AVAXAmount, tokenAmount);
            }
    }

    function setMaxWallet(uint256 amount) external onlyOwner() {
        require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }   

    function setMinimumBalanceForInfection(uint256 amount) external onlyOwner {
        minSupplyForInfectionReward = amount;
    } 

    function setMinTransferForInfection(uint256 amount) external onlyOwner() {
        require(amount <= 1*(10**_decimals) );
        _minTransferForInfection = amount; 
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setInfectedFees(uint256 newFee) external onlyOwner {
        infectedFees = newFee; 
    }

    function setFees(uint256 _liquidityFees, uint256 _devFees, uint256 _marketingFees, uint256 _feeDenominator) external onlyOwner {
        liquidityFees = _liquidityFees;
        devFees = _devFees;
        marketingFees = _marketingFees;
        totalFees = _liquidityFees.add(_devFees).add(_marketingFees);
        feeDenominator = _feeDenominator;
    }

    function setFeeReceiver(address _marketingFeesReceiver, address _devFeesReceiver) external onlyOwner {
        marketingFeesReceiver = _marketingFeesReceiver;
        devFeesReceiver = _devFeesReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function manualSend() external onlyOwner {
        uint256 contractAVAXBalance = address(this).balance;
        payable(marketingFeesReceiver).transfer(contractAVAXBalance);
    }

    function transferForeignToken(address _token) public onlyOwner {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        payable(marketingFeesReceiver).transfer(_contractBalance);
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function setSwapBackTimeLock(uint256 time) public onlyOwner {
        require(time >= 0, "No Negative Time, Pal. Thanks Shogun!");
        swapTimeLock = time * 1 minutes;
    }

    function Infect(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount >= _minTransferForInfection);
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        isInfected[recipient] = true;
        infector[recipient] = sender;
        emit Infected(recipient,sender);
        return true;
    }

    function addBlacklist(address user) public onlyOwner {
        isBlacklisted[user] = true;
    }

    function removeBlacklist(address user) public onlyOwner {
        isBlacklisted[user] = false;
    }
    
    event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);
}