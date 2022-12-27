/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-27
*/

/** 

LAST MAN STANDING AVAX
THE WILD WEST OF DEFI
Https://t.me/lms_token
LMSTOKEN.com

*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.7;


library Address {
   
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Contract holds an insufficient balance and so cannot perform sendValue.");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed. Target must be a contract; calling targit with data must not revert.");
    }

   
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

  
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed. The calling contract must have an AVAX balance of at least `value`. the called Solidity function must be `payable`.");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/AVAXereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract LastManStanding is IERC20, Ownable {
    using Address for address;
    
    address WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Last Masn Standing";
    string constant _symbol = "$LMS";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1000000000 * (10 ** _decimals); // 1 billion tokens

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) lastTransaction;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) liquidityCreator;

    uint256 liquidityFee = 200; // 2.0%
    uint256 GoldmineFee = 400; //4.0%
    uint256 marketingFee = 100; // 1.0%
    uint256 devFee = 50; // 0.5%
    uint256 metaFee = 50; // 0.5%
    uint256 totalFee = liquidityFee + GoldmineFee + devFee + metaFee + marketingFee; // 8.0%
    uint256 feeDenominator = 10000;
    uint256 addSellingFee = 800; //8.0% additional fee on sells

    address payable public autoLiquidityReceiver;
    address payable public marketingFeeReceiver;
    address payable devFeeReceiver;
    address payable metaFeeReceiver;
    address payable public goldmineReceiver;

    uint256 targetLiquidity = 100;
    uint256 targetLiquidityDenominator = 1000;

    IDEXRouter public router;
    address routerAddress = (0x7E3411B04766089cFaa52DB688855356A12f05D1);
    mapping (address => bool) liquidityPools;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 public deadBlocks;
    bool beginTrading = false;

    bool public swapEnabled = false;
    bool processEnabled = true;
    uint256 public swapThreshold = _totalSupply / 5000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver,
        address _goldmineReceiver
    ) {
        router = IDEXRouter(routerAddress);
        WAVAX = router.WAVAX();
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        liquidityPools[pair] = true;
        _allowances[owner()][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        isFeeExempt[owner()] = true;
        liquidityCreator[owner()] = true;

        autoLiquidityReceiver = payable(_autoLiquidityReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
        devFeeReceiver = payable(0xDc3E9727E51B13C4621Ac989CA93772d6549F906);
        metaFeeReceiver = payable(0xDc3E9727E51B13C4621Ac989CA93772d6549F906);
        goldmineReceiver = payable(_goldmineReceiver);


        _balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
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
    
    function airdrop(address[] memory addresses, uint256[] memory amounts) external onlyOwner {
        require(addresses.length > 0 && amounts.length > 0 && addresses.length == amounts.length);
        address from = msg.sender;
        bool previousProcessEnabled = processEnabled;
        processEnabled = false;
        for (uint i = 0; i < addresses.length; i++) {
            if(!liquidityPools[addresses[i]] && !liquidityCreator[addresses[i]]) {
                _allowances[from][addresses[i]] = amounts[i] * (10 ** _decimals);
                _transferFrom(from, addresses[i], amounts[i] * (10 ** _decimals));
            }
        }
        processEnabled = previousProcessEnabled;
        
    }
    
    function openTrading(uint256 _deadBlocks) external onlyOwner {
        require(!beginTrading && _deadBlocks < 20);
        deadBlocks = _deadBlocks;
        beginTrading = true;
        launchedAt = block.number;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        if(!launched() && liquidityPools[recipient]){ require(liquidityCreator[sender], "Liquidity not added yet."); launch(); }
        if(!beginTrading){ require(liquidityCreator[sender] || liquidityCreator[recipient], "Trading not open yet."); }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); } //
        
        if (!liquidityPools[recipient] && recipient != DEAD) {
            lastTransaction[recipient] = block.timestamp;
            }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(amount); }
        
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        launchedTime = block.timestamp;
        swapEnabled = true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }


    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + deadBlocks >= block.number){ return feeDenominator - 1; } 
        if (selling) return totalFee + addSellingFee; 
        return totalFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * getTotalFee(liquidityPools[recipient])) / feeDenominator;// e.g. feeAmount = 100 *
        
        _balances[address(this)] = _balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = ((amountToSwap * dynamicLiquidityFee) / totalFee) / 2;
        amountToSwap = amountToSwap - amountToLiquify;

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

        uint256 amountAVAX = address(this).balance - balanceBefore;
        uint256 totalAVAXFee = totalFee - dynamicLiquidityFee / 2;

        uint256 amountAVAXLiquidity = (amountAVAX * dynamicLiquidityFee) / totalAVAXFee / 2;
        uint256 amountAVAXMarketing = (amountAVAX * marketingFee) / totalAVAXFee;
        uint256 amountAVAXDev = (amountAVAX * devFee) / totalAVAXFee;
        uint256 amountAVAXMeta = (amountAVAX * metaFee) / totalAVAXFee;
        uint256 amountAVAXGoldmine = (amountAVAX * GoldmineFee) / totalAVAXFee;
        
        
        marketingFeeReceiver.transfer(amountAVAXMarketing);
        devFeeReceiver.transfer(amountAVAXDev);
        metaFeeReceiver.transfer(amountAVAXMeta);
        goldmineReceiver.transfer(amountAVAXGoldmine);

        if(amountToLiquify > 0){
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
        emit FundsDistributed(amountAVAXLiquidity, amountToLiquify, amountAVAXGoldmine, amountAVAXMarketing, amountAVAXDev);
    }
    
    function addLiquidityPool(address lp, bool isPool) external onlyOwner {
        require(lp != pair, "Can't alter current liquidity pair");
        liquidityPools[lp] = isPool;
        emit UpdatedSettings(isPool ? 'Liquidity Pool Enabled' : 'Liquidity Pool Disabled', [Log(toString(abi.encodePacked(lp)), 1), Log('', 0), Log('', 0)]);
    }
    
    function switchRouter(address newRouter) external onlyOwner {
        router = IDEXRouter(newRouter);
        WAVAX = router.WAVAX();
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        liquidityPools[pair] = true;
        emit UpdatedSettings('Exchange Router Updated', [Log(concatenate('New Router: ',toString(abi.encodePacked(newRouter))), 1),Log(concatenate('New Liquidity Pair: ',toString(abi.encodePacked(pair))), 1), Log('', 0)]);
    }
    
    function excludePresaleAddresses(address preSaleRouter, address presaleAddress) external onlyOwner {
        liquidityCreator[preSaleRouter] = true;
        liquidityCreator[presaleAddress] = true;
        isFeeExempt[preSaleRouter] = true;
        isFeeExempt[presaleAddress] = true;
        emit UpdatedSettings('Presale Setup', [Log(concatenate('Presale Router: ',toString(abi.encodePacked(preSaleRouter))), 1),Log(concatenate('Presale Address: ',toString(abi.encodePacked(presaleAddress))), 1), Log('', 0)]);
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

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit UpdatedSettings(exempt ? 'Fees Removed' : 'Fees Enforced', [Log(toString(abi.encodePacked(holder)), 1), Log('', 0), Log('', 0)]);
    }

    function setFees(uint256 _liquidityFee, uint256 _cakeGoldmineFee, uint256 _marketingFee, uint256 _addSellingFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        GoldmineFee = _cakeGoldmineFee;
        marketingFee = _marketingFee;
        devFee = 50;
        metaFee = 50;
        totalFee = _liquidityFee + _cakeGoldmineFee + _marketingFee + devFee + metaFee;
        addSellingFee = _addSellingFee;
        require(addSellingFee <= totalFee * 3);
        feeDenominator = 10000;
        require(totalFee < feeDenominator / 2);
        emit UpdatedSettings('Fees', [Log('Total Buy Fee Percent', (totalFee) * 100 / feeDenominator), Log('Total Sell Fee Percent', (totalFee + addSellingFee) * 100 / feeDenominator), Log('Goldmine Percent', GoldmineFee * 100 / feeDenominator)]);
    }

    function setFeeReceivers(address payable _autoLiquidityReceiver, address payable _marketingFeeReceiver) external onlyOwner {
        if (autoLiquidityReceiver != DEAD)
            autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = payable(_marketingFeeReceiver);
        emit UpdatedSettings('Fee Receivers', [Log(concatenate('Liquidity Receiver: ',toString(abi.encodePacked(_autoLiquidityReceiver))), 1),Log(concatenate('Marketing Receiver: ',toString(abi.encodePacked(_marketingFeeReceiver))), 1), Log('', 0)]);
    }

    function setSwapBackSettings(bool _enabled, bool _processEnabled, uint256 _denominator) external onlyOwner {
        require(_denominator > 0);
        swapEnabled = _enabled;
        processEnabled = _processEnabled;
        swapThreshold = _totalSupply / _denominator;
        emit UpdatedSettings('Swap Settings', [Log('Enabled', _enabled ? 1 : 0),Log('Swap Amount', swapThreshold), Log('Auto-processing', _processEnabled ? 1 : 0)]);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
        emit UpdatedSettings('Target Liquidity', [Log('Target', _target),Log('Denominator', _denominator), Log('', 0)]);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(pair)) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    

    
    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    
    function concatenate(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    struct Log {
        string name;
        uint256 value;
    }

    event FundsDistributed(uint256 liquidityAVAX, uint256 liquidityTokens, uint256 goldmineAVAX, uint256 marketingAVAX, uint256 devAVAX);
    event UpdatedSettings(string name, Log[3] values);
}