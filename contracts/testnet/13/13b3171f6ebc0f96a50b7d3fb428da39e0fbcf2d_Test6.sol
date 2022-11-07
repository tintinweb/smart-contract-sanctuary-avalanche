/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-05
*/

// File: test6.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 reflectionToken = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d);
    address WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public reflectionTokenDecimals = 6;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 10 * (10 ** reflectionTokenDecimals);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901);
        _token = msg.sender;
    }

    function getMinPeriod() external view  returns (uint256) {
        return minPeriod ;
    }


    function GetDistribution() external view  returns (uint256) {
        return minDistribution ;
    }
    
     
    function setReflectionToken(address _reflectionToken, uint256 _reflectionTokenDecimals)
        external
        onlyToken
    {
        reflectionToken = IERC20( _reflectionToken);
        reflectionTokenDecimals = _reflectionTokenDecimals;
        minDistribution = 10 * (10 ** reflectionTokenDecimals);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }
        
        else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore =reflectionToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(reflectionToken);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = reflectionToken.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            reflectionToken.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Test6 is IERC20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;

    address public reflectionToken = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d; 
    address public WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    address DexPoolAddress1 = 0x0000000000000000000000000000000000000000;
    address DexPoolAddress2 = 0x0000000000000000000000000000000000000000;

    address public DexPair = 0x0000000000000000000000000000000000000000;
    
    address ROUTERADDR = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;

    string constant _name = "TEST6";
    string constant _symbol = "TEST";
    uint8 constant _decimals = 18;

    uint256 public _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(1000).mul(10);
    uint256 public _maxWallet = _totalSupply.div(1000).mul(30);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) public _isFree;
  
    bool public TransferEnabled = true;
 
    uint256  public buyReflectionFee = 0;
    uint256  public buyBurnFee = 50;
    uint256  public buyMarketingFee = 40;
    uint256  public buyDevFee = 10;
    uint256  public totalBuyFee = 100;

    uint256  public sellReflectionFee = 100;
    uint256  public sellBurnFee = 20;
    uint256  public sellMarketingFee = 20;
    uint256  public sellDevFee = 10;
    uint256  public totalSellFee = 150;

    uint256  public transferReflectionFee = 0;
    uint256  public transferBurnFee = 0;
    uint256  public transferMarketingFee = 0;
    uint256  public transferDevFee = 0;
    uint256  public totalTransferFee = 0;

    uint256  feeDenominator = 1000;

    address public marketingFeeReceiver=0xF877eaa759D512D784288cb09E6D5c034551e5dD;
    address public devFeeReceiver=0xF877eaa759D512D784288cb09E6D5c034551e5dD;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    DividendDistributor distributor;
    address public distributorAddress;

    uint256 distributorGas = 600000;

    bool public swapEnabled = true;

    uint256 public swapPercentMax = 100;
    uint256 public swapThresholdMax = _totalSupply / 50;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(ROUTERADDR);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WAVAX = router.WAVAX();
        distributor = new DividendDistributor(ROUTERADDR);
        distributorAddress = address(distributor);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
      
        approve(ROUTERADDR, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
        
       require( TransferEnabled || isAuthorized(msg.sender) || isAuthorized(sender),"Transfers are Disabled");
        
        uint256 currentFeeAmount = 0;
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        address routerAddress = ROUTERADDR;

        bool isSell=recipient== pair|| recipient == routerAddress ||  recipient == DexPoolAddress1 ||  recipient == DexPoolAddress2;
        
        checkTxLimit(sender, amount);
        
        if (!isSell && !_isFree[recipient]){
            require((_balances[recipient] + amount) < _maxWallet, "Max wallet has been triggered");
        }
                
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        currentFeeAmount = amount - amountReceived;
     
        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalSellFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return totalSellFee; }
        if(selling){ return totalSellFee; }
        return totalSellFee;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 buyFeeAmount = amount.mul(totalBuyFee).div(feeDenominator);
        uint256 sellFeeAmount = amount.mul(totalSellFee).div(feeDenominator);        
        uint256 transferFeeAmount = amount.mul(totalTransferFee).div(feeDenominator);

        bool isBuy = sender == DexPoolAddress1 || sender == DexPoolAddress2 || sender == pair || sender == ROUTERADDR ; 
        bool isSell = receiver == DexPoolAddress1 || receiver == DexPoolAddress2 || receiver == pair || receiver == ROUTERADDR ;

        setFindDexPair(sender);

        if (isBuy){           
            _balances[address(this)] = _balances[address(this)].add(buyFeeAmount);
            emit Transfer(sender, address(this), buyFeeAmount);

            return amount.sub(buyFeeAmount);      
        } 

        else if (isSell){
            _balances[address(this)] = _balances[address(this)].add(sellFeeAmount);
            emit Transfer(sender, address(this), sellFeeAmount);
                        
            return amount.sub(sellFeeAmount);        
        }

        else {
            _balances[address(this)] = _balances[address(this)].add(transferFeeAmount);
            emit Transfer(sender, address(this), transferFeeAmount);
              
            return amount.sub(transferFeeAmount);
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

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public authorized {
        require(launchedAt == 0, "Already launched. Wen moon?");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }
    
    function setMaxWallet(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
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

    function setTransferEnabled(bool _enabled) public onlyOwner {
        TransferEnabled = _enabled;
    }
    
    function unSetFree(address holder) public onlyOwner {
        _isFree[holder] = false;
    }
    
    function checkFree(address holder) public view onlyOwner returns(bool){
        return _isFree[holder];
    }

    function setBuyFees(      
        uint256 _buyReflectionFee,
        uint256 _buyBurnFee,
        uint256 _buyMarketingFee,
        uint256 _buyDevFee

    ) external authorized {
        buyReflectionFee = _buyReflectionFee;
        buyBurnFee = _buyBurnFee;
        buyMarketingFee = _buyMarketingFee;
        buyDevFee = _buyDevFee;
        totalBuyFee = _buyReflectionFee.add(_buyBurnFee).add(_buyMarketingFee).add(_buyDevFee);
        require(totalBuyFee < feeDenominator / 5);       
    }

    function setSellFees(    
        uint256 _sellReflectionFee, 
        uint256 _sellBurnFee,
        uint256 _sellMarketingFee,
        uint256 _sellDevFee

    ) external authorized {
        sellReflectionFee = _sellReflectionFee;
        sellBurnFee = _sellBurnFee;
        sellMarketingFee = _sellMarketingFee;
        sellDevFee = _sellDevFee;
        totalSellFee = _sellReflectionFee.add(_sellBurnFee).add(_sellMarketingFee).add(_sellDevFee);
        require(totalSellFee < feeDenominator / 5);
    }

    function setTransFees(     
        uint256 _transferReflectionFee,
        uint256 _transferBurnFee,
        uint256 _transferMarketingFee,
        uint256 _transferDevFee

    ) external authorized {
        transferReflectionFee = _transferReflectionFee;
        transferBurnFee = _transferBurnFee;
        transferMarketingFee = _transferMarketingFee;
        transferDevFee = _transferDevFee;
        totalTransferFee = _transferReflectionFee.add(_transferBurnFee).add(_transferMarketingFee).add(transferDevFee);
        require(totalTransferFee < feeDenominator / 5);
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _devFeeReceiver) external authorized {
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 850000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function setReflectionToken(address _reflectionToken, uint256 _reflectionTokenDecimals) external authorized {
        reflectionToken = address(_reflectionToken);
        distributor.setReflectionToken(reflectionToken, _reflectionTokenDecimals);       
    }

    function setDexPoolAddress1(address _DexPoolAddress) external authorized {
        DexPoolAddress1 = address(_DexPoolAddress);
    }

    function setDexPoolAddress2(address _DexPoolAddress) external authorized {
        DexPoolAddress2 = address(_DexPoolAddress);
    }

    function setFindDexPair(address _PairPoolAddress) internal {
        DexPair  = _PairPoolAddress;
    } 
    
    function setdistributorAddress(address _distributorAddress) external authorized{
        distributorAddress  = address(_distributorAddress);
    } 

    function createNewDistributor() external authorized{
        distributor = new DividendDistributor(ROUTERADDR);
        distributorAddress = address(distributor);
    } 

    function getDexPoolAddress1() external view returns (address) {
        return DexPoolAddress1 ;
    }

    function getDexPoolAddress2() external view returns (address) {
        return DexPoolAddress2 ;
    }

    function getReflectionToken() external view returns (address) {
        return reflectionToken ;
    }

    function getFindDexPair() external view returns (address) {
        return DexPair ;
    } 

    function getMinPeriod() external view  returns (uint256) {
        return distributor.getMinPeriod() ;
    }

    function getSwapAmount(uint256 _transferAmount)
        public
        view
        returns (uint256) {
        uint256 amountFromTxnPercMax = _transferAmount.mul(swapPercentMax).div(100);
        return
        amountFromTxnPercMax > swapThresholdMax
            ? swapThresholdMax
            : amountFromTxnPercMax;
    }

    function GetDistribution() external view  returns (uint256) {
        return distributor.GetDistribution() ;
    }
 
}