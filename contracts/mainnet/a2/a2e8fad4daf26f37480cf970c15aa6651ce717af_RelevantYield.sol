/**
 *Submitted for verification at snowtrace.io on 2022-10-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function isOwner(address account) public view returns (bool) {
        return account == owner();
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");
    
        return c;
        }
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
        return c;
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

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r,bytes32 s) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution,uint256 _minHoldAmount) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;        
    function claimDividendFor(address shareholder) external;
    function holdAmount() external view returns(uint256);
    function getShareholderInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256);
    function getAccountInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256);
    function updateDividendDistributor(address token, address _router) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    IJoeRouter02 router;
    
    address[] shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;
    mapping (address => Share) public shares;
    
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    
    uint256 public minPeriod = 1 days; // amount of time for min distribution to accumalate, once over it sends after x amount automatically.
    uint256 public minHoldAmount = 100 * (10**9); // 100 tokens for Avax rewards
    uint256 public minDistribution = 0.1 * (10 ** 18); // .1 Avax for auto claim
    uint256 public balance;
    
    uint256 currentIndex;
    

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }
    
    modifier updateBalance() {
        balance = address(this).balance; _;
    }
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    
    constructor (address _router) {
        _token = msg.sender;
        router = IJoeRouter02(_router);
    }

    function updateDividendDistributor(address token, address _router) public override onlyToken {
        _token = token;
        router = IJoeRouter02(_router);
    }

    function getShareholderInfo(address shareholder) external view override returns (uint256, uint256, uint256, uint256) {
        return (
            totalShares,
            totalDistributed,
            shares[shareholder].amount,
            shares[shareholder].totalRealised       
        );
    }

    function holdAmount() external view override returns(uint256) {
        return minHoldAmount;
    }

    function getAccountInfo(address shareholder) external view override returns(uint256 pendingReward, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable){
        pendingReward = getUnpaidEarnings(shareholder);
        lastClaimTime = shareholderClaims[shareholder];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldAmount) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution * (10**18);
        minHoldAmount = _minHoldAmount * (10**9);
        emit DistributionCriteriaUpdated(minPeriod, minDistribution, minHoldAmount);
    }
    
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
        distributeDividend(shareholder);
            }
    
        if(amount > minHoldAmount && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount <= minHoldAmount && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
    
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            
        emit ShareUpdated(shareholder, amount);
    }
    
    function deposit() external payable override updateBalance{
        
        uint256 amount = address(this).balance - balance;
    
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            
        emit Deposit(amount);
    }
    
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
    
        if(shareholderCount == 0) { return; }
    
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
    
        uint256 iterations = 0;
        uint256 count = 0;
    
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
    
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
                count++;
            }
    
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
            
        emit DividendsProcessed(iterations, count, currentIndex);
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
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
                    
            emit Distribution(shareholder, amount);
            }
    }


    function claimDividend() public {
        distributeDividend(msg.sender);
    }
    
    function claimDividendFor(address shareholder) public override {
        distributeDividend(shareholder);
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
        
    event DistributionCriteriaUpdated(uint256 minPeriod, uint256 minDistribution, uint256 minHoldAmount);
    event ShareUpdated(address shareholder, uint256 amount);
    event Deposit(uint256 amount);
    event Distribution(address shareholder, uint256 amount);
    event DividendsProcessed(uint256 iterations, uint256 count, uint256 index);
}



contract RelevantYield is IERC20, Context, Ownable {
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public pair;
    IJoeRouter02 public router;
    IDividendDistributor public distributor;
    string constant _name = "Relevant Yield";
    string constant _symbol = "RYLD";
    uint8 constant _decimals = 9;

    uint256 constant _initialSupply = 20_000_000; // put supply amount here
    uint256 _totalSupply = _initialSupply * (1**_decimals); // total supply amount
    // uint256 public _maxTxAmount = (_totalSupply * (1)) / (100);
    mapping(address => bool) lpPairs;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) authorizations;
    mapping(address => uint256) buycooldown;
    mapping(address => uint256) sellcooldown;
    mapping(address => bool) public _isBlacklisted;
    struct ILaunch {
        uint256 launchedAt;
        uint256 antiBlocks;
        bool launched;
        bool launchProtection;
    }
    ILaunch public wenLaunch;

    struct Icooldown {
        bool buycooldownEnabled;
        bool sellcooldownEnabled;
        uint256 cooldown;
        uint256 cooldownLimit;
    }
    Icooldown public cooldownInfo =
        Icooldown({
            buycooldownEnabled: true,
            sellcooldownEnabled: true,
            cooldown: 30 seconds,
            cooldownLimit: 60 seconds
        }); 
    struct IFees {
        uint256 liquidityFee;
        uint256 buybackFee;
        uint256 reflectionFee;
        uint256 marketingFee;
        uint256 totalFee;
    }
    IFees public BuyFees;
    IFees public SellFees;
    IFees public TransferFees;
    IFees public MaxFees =
        IFees({
            reflectionFee: 5,
            buybackFee: 5,
            liquidityFee: 5,
            marketingFee: 5,
            totalFee: 20
        });
    struct ItxSettings {
        uint256 maxTxAmount;
        uint256 maxWalletAmount;
        bool txLimits;
    }

    ItxSettings public txSettings;
    uint256 feeDenominator = 100;
    uint256 public sellMultiplier;
    uint256 public constant maxSellMultiplier = 3;
    uint256 marketingFees;
    uint256 liquidityFeeAccumulator;
    bool public feeEnabled;
    bool public autoLiquifyEnabled;
    bool inSwap;
    bool public autoClaimEnabled;
    bool swapEnabled;
    bool autoBuybackEnabled;
    bool public fundRewards;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;
    uint256 distributorGas = 500000;
    uint256 swapThreshold = _totalSupply / 4000; // 0.025%
    uint256 lastSwap;
    uint256 public swapInterval = 30 seconds;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    modifier authorized() {
        require(isAuthorized(_msgSender()), "!AUTHORIZED");
        _;
    }
    constructor() {
        authorizations[_msgSender()] = true;
        router = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        pair = IJoeFactory(router.factory()).createPair(router.WAVAX(), address(this));
        lpPairs[pair] = true;
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[_msgSender()][address(router)] = type(uint256).max;
        distributor = new DividendDistributor(address(router));        
        isFeeExempt[address(this)] = true;
        isFeeExempt[_msgSender()] = true;
        isTxLimitExempt[_msgSender()] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = owner();
        marketingFeeReceiver = owner();
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function updateRouter(address _router, address _pair) external onlyOwner {
        router = IJoeRouter02(_router);
        pair = _pair;
    }    
    
    function setLpPair(address pairs, bool enabled) public onlyOwner {
        lpPairs[pairs] = enabled;
    }

    function updateDividendDistributor(address token, address _router) public onlyOwner{
        distributor.updateDividendDistributor(token, _router);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address sender, address spender, uint256 amount) private {
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function limits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && tx.origin != owner()
            && !isAuthorized(from)
            && !isAuthorized(to)
            && to != address(0xdead)
            && to != address(0)
            && from != address(this);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        if(limits(sender, recipient)){
            checkLaunched(sender);
            if(wenLaunch.launched){
                if(lpPairs[sender] || lpPairs[recipient]){
                    if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient]){
                        checkTxLimit(sender, amount);
                    }
                }
                if(!lpPairs[recipient] && recipient != address(router)){
                    if(!isTxLimitExempt[recipient]){
                        require(balanceOf(recipient) + amount <= txSettings.maxWalletAmount);
                    }
                }
            }
        }

        if (shouldSwapBack()) {
            swapBack();
        }
        if (shouldAutoBuyback()) {
            triggerAutoBuyback();
        }

        if(wenLaunch.launched){
            if(limits(sender, recipient)) {
                verifyUser(sender, recipient);
            }
        }

        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] += amountReceived;

        if (!isDividendExempt[sender] && balanceOf(sender) >= holdAmount()) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient] && balanceOf(recipient) >= holdAmount() ) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        if (autoClaimEnabled) {
            try distributor.process(distributorGas) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function verifyUser(address from, address to) internal {
        require(!_isBlacklisted[to]);
        require(!_isBlacklisted[from]);
        if (wenLaunch.launchProtection) {
            if (lpPairs[from] && to != address(router) && !isFeeExempt[to]) {
                if (block.number <= wenLaunch.launchedAt + wenLaunch.antiBlocks) {
                    _setSniperStatus(to, true);
              }
            } else {
                wenLaunch.launchProtection = false;
            }
        }
        if (lpPairs[from] && to != address(router) && !isFeeExempt[to] && cooldownInfo.buycooldownEnabled) {
            require(buycooldown[to] < block.timestamp);
            buycooldown[to] = block.timestamp + (cooldownInfo.cooldown);
        } else if (!lpPairs[from] && !isFeeExempt[from] && cooldownInfo.sellcooldownEnabled){
                require(sellcooldown[from] <= block.timestamp);
                sellcooldown[from] = block.timestamp + (cooldownInfo.cooldown);
        } 
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setSellMultiplier(uint256 SM) external authorized {
        require(SM <= maxSellMultiplier);
        sellMultiplier = SM;
    }

    function checkLaunched(address sender) internal view {
        require(wenLaunch.launched || isAuthorized(sender), "Pre-Launch Protection");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= txSettings.maxTxAmount || isTxLimitExempt[sender],"TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return feeEnabled && !isFeeExempt[sender];
    }

    function sellingFee() internal view returns (uint256) {
        return SellFees.totalFee * sellMultiplier;
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if (isFeeExempt[sender] || isFeeExempt[receiver]) {
            return amount;
        }
        uint256 totalFee;
        if (lpPairs[receiver]) {
            if(sellMultiplier >= 2){
                totalFee = sellingFee();
            } else {
                totalFee = SellFees.totalFee;
            }
        } else if(lpPairs[sender]){
            totalFee = BuyFees.totalFee;
        } else {
            totalFee = TransferFees.totalFee;
        }

        uint256 feeAmount = (amount * totalFee) / feeDenominator;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        if (receiver == pair && autoLiquifyEnabled) {
            liquidityFeeAccumulator =
                liquidityFeeAccumulator +
                ((feeAmount * (BuyFees.liquidityFee + SellFees.liquidityFee)) /
                    ((BuyFees.totalFee + SellFees.totalFee) +
                        (BuyFees.liquidityFee + SellFees.liquidityFee)));
        }

        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            !lpPairs[msg.sender] &&
            !inSwap &&
            swapEnabled &&
            block.timestamp >= lastSwap + swapInterval &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        lastSwap = block.timestamp;
        if (liquidityFeeAccumulator >= swapThreshold && autoLiquifyEnabled) {
            liquidityFeeAccumulator = liquidityFeeAccumulator - swapThreshold;
            uint256 amountToLiquify = swapThreshold / 2;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WAVAX();

            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                amountToLiquify,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amountAvax = address(this).balance - (balanceBefore);

            router.addLiquidityAVAX{value: amountAvax}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );

            emit AutoLiquify(amountAvax, amountToLiquify);
        } else {
            uint256 amountToSwap = swapThreshold;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WAVAX();

            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amountAvax = address(this).balance - (balanceBefore);

            uint256 amountAvaxReflection = (amountAvax *
                (BuyFees.reflectionFee + SellFees.reflectionFee)) /
                (BuyFees.totalFee + SellFees.totalFee);
            uint256 amountAvaxMarketing = (amountAvax *
                (BuyFees.marketingFee + SellFees.marketingFee)) /
                (BuyFees.totalFee + SellFees.totalFee);

            if(fundRewards){
                try distributor.deposit{value: amountAvaxReflection}() {} catch {}
                (bool success, ) = payable(marketingFeeReceiver).call{
                value: amountAvaxMarketing,
                gas: 30000
            }("");
            if (success) {
                marketingFees += amountAvaxMarketing;
            }
            } else {
                payable(marketingFeeReceiver).transfer(amountAvaxMarketing);
                marketingFees += amountAvaxMarketing;
            }

            emit SwapBack(amountToSwap, amountAvax);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            autoBuybackEnabled &&
            autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number &&
            address(this).balance >= autoBuybackAmount;
    }

    function buybackWEI(uint256 amount) external authorized {
        _buyback(amount);
    }

    function buybackAvax(uint256 amount) external authorized {
        _buyback(amount * (10**18));
    }

    function manualDeposit(uint256 amount) external onlyOwner {
        try distributor.deposit{value: amount}() {} catch {}
    }

    function _buyback(uint256 amount) internal {
        buyTokens(amount, marketingFeeReceiver);
        emit Buyback(amount);
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator + autoBuybackAmount;
        if (autoBuybackAccumulator > autoBuybackCap) {
            autoBuybackEnabled = false;
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = address(this);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
        emit AutoBuybackSettingsUpdated(_enabled, _cap, _amount, _period);
    }

    function launch(uint256 blockAmount) public onlyOwner{
        require(blockAmount <= 5);
        require(wenLaunch.launched);
        swapEnabled = true;
        autoLiquifyEnabled = true;
        autoClaimEnabled = true;   
        wenLaunch.launchedAt = block.number;
        wenLaunch.antiBlocks = blockAmount;
        wenLaunch.launched = true;
        wenLaunch.launchProtection = true;
        setBuyFees(5, 0, 0, 0);
        setSellFees(5, 0, 0, 0);
        setTransferFees(1,1,1,1);
        setTxLimit(1,100);
        setMaxWallet(2,100);
        fundRewards = true;
        feeEnabled = true;
        emit Launch();
    }

    function setTxLimit(uint256 percent, uint256 divisor) public authorized {
        require(percent >= 1 && divisor <= 1000);
        txSettings.maxTxAmount = (_totalSupply * (percent)) / (divisor);
        emit TxLimitUpdated(txSettings.maxTxAmount);
    }

    function setMaxWallet(uint256 percent, uint256 divisor) public authorized {
        require(percent >= 1 && divisor <= 1000);
        txSettings.maxWalletAmount = (_totalSupply * percent) / divisor;
        emit WalletLimitUpdated(txSettings.maxWalletAmount);
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
        emit DividendExemptUpdated(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit FeeExemptUpdated(holder, exempt);
    }

    function setSniperStatus(address account, bool blacklisted) external onlyOwner {
        _setSniperStatus(account, blacklisted);
    }

    function _setSniperStatus(address account, bool blacklisted) internal {
        if(lpPairs[account] || account == address(this) || account == address(router) || isFeeExempt[account]) {revert();}
        
        if (blacklisted == true) {
            _isBlacklisted[account] = true;
        } else {
            _isBlacklisted[account] = false;
        }    
    }
    function setIsTxLimitExempt(address holder, bool exempt) external authorized{
        isTxLimitExempt[holder] = exempt;
        emit TxLimitExemptUpdated(holder, exempt);
    }

    function setBuyFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee) public authorized {
        require(_liquidityFee <= MaxFees.liquidityFee && _reflectionFee <= MaxFees.reflectionFee && _marketingFee <= MaxFees.marketingFee && _buybackFee <= MaxFees.buybackFee);
        BuyFees = IFees({
            liquidityFee: _liquidityFee,
            buybackFee: _buybackFee,
            reflectionFee: _reflectionFee,
            marketingFee: _marketingFee,
            totalFee: _liquidityFee + _buybackFee + _reflectionFee + _marketingFee
        });
    }

    function FeesEnabled(bool _enabled) external onlyOwner {
        feeEnabled = _enabled;
        emit areFeesEnabled(_enabled);
    }

    function setSellFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee) public authorized {
        require(_liquidityFee <= MaxFees.liquidityFee && _reflectionFee <= MaxFees.reflectionFee && _marketingFee <= MaxFees.marketingFee && _buybackFee <= MaxFees.buybackFee);
        SellFees = IFees({
            liquidityFee: _liquidityFee,
            buybackFee: _buybackFee,
            reflectionFee: _reflectionFee,
            marketingFee: _marketingFee,
            totalFee: _liquidityFee + _buybackFee + _reflectionFee + _marketingFee
        });
    }

    function setTransferFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee) public authorized {
        require(_liquidityFee <= MaxFees.liquidityFee && _reflectionFee <= MaxFees.reflectionFee && _marketingFee <= MaxFees.marketingFee && _buybackFee <= MaxFees.buybackFee);
        TransferFees = IFees({
            liquidityFee: _liquidityFee,
            buybackFee: _buybackFee,
            reflectionFee: _reflectionFee,
            marketingFee: _marketingFee,
            totalFee: _liquidityFee + _buybackFee + _reflectionFee + _marketingFee
        });
    }

    function decreaseMaxFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee) public authorized {
        require(_liquidityFee <= MaxFees.liquidityFee && _reflectionFee <= MaxFees.reflectionFee && _marketingFee <= MaxFees.marketingFee && _buybackFee <= MaxFees.buybackFee);
        MaxFees = IFees({
            liquidityFee: _liquidityFee,
            buybackFee: _buybackFee,
            reflectionFee: _reflectionFee,
            marketingFee: _marketingFee,
            totalFee: _liquidityFee + _buybackFee + _reflectionFee + _marketingFee
        });
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        emit FeeReceiversUpdated(_autoLiquidityReceiver, _marketingFeeReceiver);
    }

    function setCooldownEnabled(bool onoff, bool offon, uint256 amount) external onlyOwner {
        require(amount <= cooldownInfo.cooldownLimit);
        cooldownInfo.buycooldownEnabled = onoff;
        cooldownInfo.sellcooldownEnabled = offon;       
        cooldownInfo.cooldown = amount;

    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized{
        swapEnabled = _enabled;
        swapThreshold = (_totalSupply * (_amount)) / (10000);
        emit SwapBackSettingsUpdated(_enabled, _amount);
    }

    function setAutoLiquifyEnabled(bool _enabled) external authorized {
        autoLiquifyEnabled = _enabled;
        emit AutoLiquifyUpdated(_enabled);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldReq) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _minHoldReq);
    }

    function setDistributorSettings(uint256 gas, bool _autoClaim) external authorized {
        require(gas <= 1000000);
        distributorGas = gas;
        autoClaimEnabled = _autoClaim;
        emit DistributorSettingsUpdated(gas, _autoClaim);
    }

    function getAccumulatedFees() external view returns (uint256) {
        return marketingFees;
    }

    function getCoolDownSettings() public view returns(bool, bool, uint256, uint256) {
        return(cooldownInfo.buycooldownEnabled, cooldownInfo.sellcooldownEnabled, cooldownInfo.cooldown, cooldownInfo.cooldownLimit);
    }
        
    function getBlacklistStatus(address account) external view returns(bool) {
        return _isBlacklisted[account];
    }

    function getAutoBuybackSettings() external view returns (bool,uint256,uint256,uint256,uint256,uint256){
        return ( autoBuybackEnabled, autoBuybackCap, autoBuybackAccumulator, autoBuybackAmount, autoBuybackBlockPeriod, autoBuybackBlockLast);
    }

    function getAutoLiquifySettings() external view returns (bool, uint256) {
        return (autoLiquifyEnabled, liquidityFeeAccumulator);
    }

    function getSwapBackSettings() external view returns (bool, uint256) {
        return (swapEnabled, swapThreshold);
    }

    function getShareholderInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256) {
        return distributor.getShareholderInfo(shareholder);
    }

    function getAccountInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256) {
        return distributor.getAccountInfo(shareholder);
    }
    function holdAmount() public view returns(uint256) {
        return distributor.holdAmount();
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage <= 100);
        uint256 amountAvax = address(this).balance;
        payable(marketingFeeReceiver).transfer(
            (amountAvax * amountPercentage) / 100
        );
    }

    function clearStuckToken(address to) external onlyOwner {
        uint256 _balance = balanceOf(address(this));
        _basicTransfer(address(this), to, _balance);
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function airDropTokens(address[] memory addresses, uint256[] memory amounts) external onlyOwner{
        require(addresses.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < addresses.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _basicTransfer(msg.sender, addresses[i], amounts[i]*10**_decimals);
        }
    }

    function claimDividend() public {
        distributor.claimDividendFor(msg.sender);
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    event Authorized(address adr);
    event Unauthorized(address adr);
    event Launch();
    event AutoLiquify(uint256 amountAvax, uint256 amountToken);
    event SwapBack(uint256 amountToken, uint256 amountAvax);
    event Buyback(uint256 amountAvax);
    event AutoBuybackSettingsUpdated(bool enabled, uint256 cap, uint256 amount, uint256 period);
    event TxLimitUpdated(uint256 amount);
    event WalletLimitUpdated(uint256 amount);
    event DividendExemptUpdated(address holder, bool exempt);
    event FeeExemptUpdated(address holder, bool exempt);
    event TxLimitExemptUpdated(address holder, bool exempt);
    event FeeReceiversUpdated(address autoLiquidityReceiver, address marketingFeeReceiver);
    event SwapBackSettingsUpdated(bool enabled, uint256 amount);
    event areFeesEnabled(bool _enabled);
    event AutoLiquifyUpdated(bool enabled);
    event DistributorSettingsUpdated(uint256 gas, bool autoClaim);
    event WalletBanStatusUpdated(address user, bool banned);
}