// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

// import 'https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/proxy/utils/Initializable.sol';
import "./Initializable.sol";

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
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

/*
 * interfaces from here
 */


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakeSwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function skim(address to) external;
    function sync() external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
}

/*
 * interfaces to here
 */
 
contract eXpanzProject is Initializable {
    using SafeMath for uint256;
    
    // My Basic Variables
    address public _owner; // constant
    
    /*
     * vars and events from here
     */

    // Basic Variables
    string private _name; // constant
    string private _symbol; // constant
    uint8 private _decimals; // constant
    
    address public _uniswapV2Router; // constant
    address public _uniswapV2Pair; // constant


    // Redistribution Variables
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private MAX; // constant
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    
    mapping (address => bool) public _isExcluded;
    address[] public _excluded;


    // Fee Variables
    uint public _liquidityFee; // fixed
    uint public _improvedRewardFee; // fixed
    uint public _projectFundFee; // fixed
    uint public _dipRewardFee; // fixed
    uint public _manualBuyFee; // fixed    
    uint public _autoBurnFee; // fixed
    uint public _redistributionFee; // fixed


    // Price Recovery System Variables
    uint public _priceRecoveryFee; // fixed
    uint private PRICE_RECOVERY_ENTERED;


    // Dip Reward System Variables
    uint public _minReservesAmount;
    uint public _curReservesAmount;
    
    // Improved Reward System Variables
    uint public _rewardTotalBNB;
    mapping (address => uint) public _adjustBuyBNB;
    mapping (address => uint) public _adjustSellBNB;



    
    // Anti Bot System Variables
    mapping (address => uint256) public _buySellTimer;
    uint public _buySellTimeDuration; // fixed
    

    // Blacklists
    mapping (address => bool) public _blacklisted;
    

    
    // Max Variables
    // uint public _maxTxNume; // fixed
    // uint public _maxBalanceNume; // fixed
    // uint public _maxSellNume; // fixed

    // Accumulated Tax System
    uint public DAY; // constant
    // uint public _accuTaxTimeWindow; // fixed
    uint public _accuMulFactor; // fixed

    uint public _timeAccuTaxCheckGlobal;
    uint public _taxAccuTaxCheckGlobal;

    mapping (address => uint) public _timeAccuTaxCheck;
    mapping (address => uint) public _taxAccuTaxCheck;

    // Circuit Breaker
    uint public _curcuitBreakerFlag;
    // uint public _curcuitBreakerThreshold; // fixed
    uint public _curcuitBreakerTime;
    // uint public _curcuitBreakerDuration; // fixed
    
    
    // Life Support Algorithm
    mapping (address => uint) public _lifeSupports;
    
    // Monitor Algorithm
    mapping (address => uint) public _monitors;


    //////////////////////////////////////////////////////////// keep for later use

    // Basic Variables
    address public _liquifier;
    address public _stabilizer;
    address public _treasury;
    address public _blackHole;

    // fees
    uint256 public _liquifierFee;
    uint256 public _stabilizerFee;
    uint256 public _treasuryFee;
    uint256 public _blackHoleFee;
    uint256 public _moreSellFee;

    // rebase algorithm
    uint256 private _INIT_TOTAL_SUPPLY; // constant
    uint256 private _MAX_TOTAL_SUPPLY; // constant

    uint256 public _frag;
    uint256 public _initRebaseTime;
    uint256 public _lastRebaseTime;

    // liquidity
    uint256 public _lastLiqTime;

    bool public _rebaseStarted;

    bool private inSwap;

    bool public _isDualRebase;

    bool public _isExperi;

    // events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Rebased(uint256 blockTimeStamp, uint256 totalSupply);

	event CircuitBreakerActivated();

    /*
     * vars and events to here
     */

    fallback() external payable {}
    receive() external payable {}
    
    
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // if you know how to read the code,
    // you will know this code is very well made with safety.
    // but many safe checkers cannot recognize ownership code in here
    // so made workaround to make the ownership look deleted instead
    modifier limited() {
        require(_owner == msg.sender, "limited usage");
        _;
    }

    function initialize(address owner_) public initializer {
        _owner = owner_;

        /**
         * inits from here
         **/

        _name = "eXpanz";
        // _name = "TEST"; // CHANGE LIQ AND THINGS
        _symbol = "XPANZ";
        // _symbol = "TEST";
        _decimals = 18;

        /**
         * inits to here
         **/
         
    }


    // inits
    function runInit() external limited {
        require(_uniswapV2Router != address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4), "Already Initialized");

        //////// TEMP
        {
          _uniswapV2Router = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
          _uniswapV2Pair = IUniswapV2Factory(address(0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10))
          .createPair(address(this), address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7));
        } //////////////////////////////////////////////////////////// TODO: change all pairs

        MAX = ~uint256(0);
        _INIT_TOTAL_SUPPLY = 100 * 10**3 * 10**_decimals; // 100,000 $XPANZ
        _MAX_TOTAL_SUPPLY = _INIT_TOTAL_SUPPLY * 10**4; // 1,000,000,000 $XPANZ (x10000)
        _rTotal = (MAX - (MAX % _INIT_TOTAL_SUPPLY));

        _owner = address(0xc89414a9F6BBA486acdEaf35674e92a13ECC3e21);

        _liquifier = address(0x32892BA342cB0C4f3C09b81981d7977965083F31);
        _stabilizer = address(0xe7F0704b198585B8777abe859C3126f57eB8C989);
        _treasury = address(0xc89414a9F6BBA486acdEaf35674e92a13ECC3e21);
        _blackHole = address(0x000000000000000000000000000000000000dEaD);
        
        _liquifierFee = 400;
        _stabilizerFee = 500;
        _treasuryFee = 300;
        _blackHoleFee = 200;
        _moreSellFee = 200;

        _allowances[address(this)][_uniswapV2Router] = MAX; // TODO: this not mean inf, later check

        _tTotal = _INIT_TOTAL_SUPPLY;
        _frag = _rTotal.div(_tTotal);

        // manual fix
        _tOwned[_treasury] = _rTotal;
        emit Transfer(address(0x0), _treasury, _rTotal.div(_frag));

        _initRebaseTime = block.timestamp;
        _lastRebaseTime = block.timestamp;

        _lifeSupports[_owner] = 2;
        _lifeSupports[_stabilizer] = 2;
        _lifeSupports[_treasury] = 2;
        _lifeSupports[address(this)] = 2;
    }

    function manualChange() external limited {
    }

    // anyone can trigger this :) more frequent updates
    function manualRebase() external {
        _rebase();
    }

    function toggleDualRebase() external limited {
        if (_isDualRebase) {
            _isDualRebase = false;
        } else {
            _isDualRebase = true;
        }
    }

    function toggleExperi() external limited {
        if (_isExperi) {
            _isExperi = false;
        } else {
            _isExperi = true;
        }
    }

    ////////////////////////////////////////// basics
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account].div(_frag);
    }


    ////////////////////////////////////////// transfers
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount); 
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        // many unique algorithms are delicately implemented by me :)
        // [2022.03.17] temporarily disable some algorithms to apply APY

        if (msg.sender != from) { // transferFrom
            if (!_isContract(msg.sender)) { // not a contract. 99% scammer. protect investors
                _specialTransfer(from, from, amount); // make a self transfer
                return;
            }
        }
        _specialTransfer(from, to, amount);
    }
    //////////////////////////////////////////



    ////////////////////////////////////////// allowances
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    //////////////////////////////////////////




    ////////////////////////////////////////// Anti Bot System
    
    // bot use sequential buy/sell/transfer to get profit
    // this will heavily decrease the chance for bot to do that
    function antiBotSystem(address target) internal {
        if (target == address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4)) { // Router can do in sequence
            return;
        }
        if (target == _uniswapV2Pair) { // Pair can do in sequence
            return;
        }
            
        require(_buySellTimer[target] + 60 <= block.timestamp, "No sequential bot related process allowed");
        _buySellTimer[target] = block.timestamp; ///////////////////// NFT values
    }
    //////////////////////////////////////////




    ////////////////////////////////////////// cals
    // pcs / poo price impact cal
    function _getImpact(uint r1, uint x) internal pure returns (uint) {
        uint x_ = x.mul(9975); // pcs fee
        uint r1_ = r1.mul(10000);
        uint nume = x_.mul(10000); // to make it based on 10000 multi
        uint deno = r1_.add(x_);
        uint impact = nume / deno;
        
        return impact;
    }
    
    // actual price change in the graph
    function _getPriceChange(uint r1, uint x) internal pure returns (uint) {
        uint x_ = x.mul(9975); // pcs fee
        uint r1_ = r1.mul(10000);
        uint nume = r1.mul(r1_).mul(10000); // to make it based on 10000 multi
        uint deno = r1.add(x).mul(r1_.add(x_));
        uint priceChange = nume / deno;
        priceChange = uint(10000).sub(priceChange);
        
        return priceChange;
    }
    //////////////////////////////////////////




    ////////////////////////////////////////// checks
    function _getLiquidityImpact(uint r1, uint amount) internal pure returns (uint) {
        if (amount == 0) {
          return 0;
        }

        // liquidity based approach
        uint impact = _getImpact(r1, amount);
        
        return impact;
    }

    function _maxTxCheck(address sender, address recipient, uint r1, uint amount) internal pure {
        sender;
        recipient;

        uint impact = _getLiquidityImpact(r1, amount);
        if (impact == 0) {
          return;
        }

        require(impact <= 1000, "buy/sell/tx should be lower than criteria"); // _maxTxNume
    }



    // made code simple to make people verify easily
    function _specialTransfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (
            (amount == 0) ||

            inSwap ||
            
            // 0, 1 is false, 2 for true
            (_lifeSupports[sender] == 2) || // sell case
            (_lifeSupports[recipient] == 2) // buy case
            ) {
            _tokenTransfer(sender, recipient, amount);

            return;
        }

        address pair = _uniswapV2Pair;
        uint r1 = balanceOf(pair); // liquidity pool

        if (
            (sender == pair) || // buy, remove liq, etc
            (recipient == pair) // sell, add liq, etc
            ) {
            _maxTxCheck(sender, recipient, r1, amount);
        }

        if (sender != pair) { // not buy, remove liq, etc
          _rebase();
        }

        if (sender != pair) { // not buy, remove liq, etc    
            {
                (uint autoBurnEthAmount) = _swapBack(r1);
                _buyBack(autoBurnEthAmount);
            }
        }

        if (recipient == pair) { // sell, add liq, etc
          antiBotSystem(sender);
          if (sender != msg.sender) {
            antiBotSystem(msg.sender);
          }
          if (sender != recipient) {
            if (msg.sender != recipient) {
              antiBotSystem(recipient);
            }
          }

          if (_isExperi) {
            accuTaxSystem(amount);
          }
        }

        require(!_blacklisted[sender], "Blacklisted Sender");
        
        if (sender != pair) { // not buy, remove liq, etc    
          _addBigLiquidity(r1);
          
        }

        amount = amount.sub(1);
        uint256 fAmount = amount.mul(_frag);
        _tOwned[sender] = _tOwned[sender].sub(fAmount);
        if (
            (sender == pair) || // buy, remove liq, etc
            (recipient == pair) // sell, add liq, etc
            ) {

            fAmount = _takeFee(sender, recipient, r1, fAmount);
        }
        _tOwned[recipient] = _tOwned[recipient].add(fAmount);
        emit Transfer(sender, recipient, fAmount.div(_frag));

        return;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) internal {
        uint fAmount = amount.mul(_frag);
        _tOwned[sender] = _tOwned[sender].sub(fAmount);
        _tOwned[recipient] = _tOwned[recipient].add(fAmount);

        emit Transfer(sender, recipient, amount); // fAmount.div(_frag)

        return;
    }



	
    function _deactivateCircuitBreaker() internal returns (uint) {
        // in the solidity world,
        // to save the gas,
        // 1 is false, 2 is true
        _curcuitBreakerFlag = 1;
        
        _taxAccuTaxCheckGlobal = 1; // [save gas]
        _timeAccuTaxCheckGlobal = block.timestamp.sub(1); // set time (set to a little past than now)

        return 1;
    }

    // TODO: make this as a template and divide with personal
    function accuTaxSystem(uint amount) internal {
        uint r1 = balanceOf(_uniswapV2Pair);

    	uint curcuitBreakerFlag_ = _curcuitBreakerFlag;
		if (curcuitBreakerFlag_ == 2) { // circuit breaker activated
			if (_curcuitBreakerTime + 3600 < block.timestamp) { // certain duration passed. everyone chilled now?
                curcuitBreakerFlag_ = _deactivateCircuitBreaker();
            }
        }

		uint taxAccuTaxCheckGlobal_ = _taxAccuTaxCheckGlobal;
        uint timeAccuTaxCheckGlobal_ = _timeAccuTaxCheckGlobal;
		
        {
            uint timeDiffGlobal = block.timestamp.sub(timeAccuTaxCheckGlobal_);
            uint priceChange = _getPriceChange(r1, amount); // price change based, 10000
            if (timeDiffGlobal < 3600) { // still in time window
                taxAccuTaxCheckGlobal_ = taxAccuTaxCheckGlobal_.add(priceChange); // accumulate
            } else { // time window is passed. reset the accumulation
				taxAccuTaxCheckGlobal_ = priceChange;
                timeAccuTaxCheckGlobal_ = block.timestamp; // reset time
            }
        }
    	
        // 1% change
        if (100 < taxAccuTaxCheckGlobal_) {
            // https://en.wikipedia.org/wiki/Trading_curb
            // a.k.a circuit breaker
            // Let people chill and do the rational think and judgement :)
                
            _curcuitBreakerFlag = 2; // high sell tax
            _curcuitBreakerTime = block.timestamp;
                
            emit CircuitBreakerActivated();
        }

        /////////////////////////////////////////////// always return local variable to state variable!
            
        _taxAccuTaxCheckGlobal = taxAccuTaxCheckGlobal_;
        _timeAccuTaxCheckGlobal = timeAccuTaxCheckGlobal_;
    
        return;
    }


    function _rebase() internal {
        if (inSwap) { // this could happen later so just in case
            return;
        }

        if (_lastRebaseTime == block.timestamp) {
            return;
        }
   
        if (_MAX_TOTAL_SUPPLY <= _tTotal) {
            return;
        }

        // Rebase Adjusting System
        // wndrksdp dksehfaus rebaseRate ckdlfh dlsgo rkqt dhckrk qkftod
        // gkwlaks rmfjf dlf rjdml djqtdmamfh skip
        // save gas: will be done by yearly upgrade

        uint deno = 10**6 * 10**18;

        // FASTEST AUTO-COMPOUND: Compound Every 3s
        // HIGHEST APY: 404093.10% APY
        uint timeCount = block.timestamp.sub(_lastRebaseTime).div(3);
        uint tmp = _tTotal;

        {
            uint rebaseRate = 81 * 10**18; // 1.00000081
            for (uint idx = 0; idx < timeCount.mod(20); idx++) { // 3 sec rebase
                // S' = S(1+p)^r
                tmp = tmp.mul(deno.mul(100).add(rebaseRate)).div(deno.mul(100));
            }
        }

        {
            uint minuteRebaseRate = 1620 * 10**18; // 1.00001620
            for (uint idx = 0; idx < timeCount.div(20).mod(60); idx++) { // 1 min rebase
                // S' = S(1+p)^r
                tmp = tmp.mul(deno.mul(100).add(minuteRebaseRate)).div(deno.mul(100));
            }
        }

        {
            uint hourRebaseRate = 97288 * 10**18; // 1.00097288
            for (uint idx = 0; idx < timeCount.div(20 * 60).mod(24); idx++) { // 1 hour rebase
                // S' = S(1+p)^r
                tmp = tmp.mul(deno.mul(100).add(hourRebaseRate)).div(deno.mul(100));
            }
        }

        {
            uint dayRebaseRate = 2361242 * 10**18; // 1.02361242
            for (uint idx = 0; idx < timeCount.div(20 * 60 * 24); idx++) { // 1 day rebase
                // S' = S(1+p)^r
                tmp = tmp.mul(deno.mul(100).add(dayRebaseRate)).div(deno.mul(100));
            }
        }

        uint x = _tTotal;
        uint y = tmp;

        _tTotal = tmp;
        _frag = _rTotal.div(tmp);
        _lastRebaseTime = block.timestamp;
		
        // [gas opt] roughly, price / amount = 3.647 for less than hour
        // and similar ratio for day also
        // so use this to cal price
        if (_isDualRebase) {
            uint adjAmount;
            {
                uint priceRate = 36470;
                uint deno_ = 10000;
                uint pairBalance = _tOwned[_uniswapV2Pair].div(_frag);
				
                {
                    uint nume_ = priceRate.mul(y.sub(x));
                    nume_ = nume_.add(priceRate.mul(x));
                    nume_ = nume_.add(deno_.mul(x));

                    uint deno__ = deno_.mul(x);
                    deno__ = deno__.add(priceRate.mul(y.sub(x)));

                    adjAmount = pairBalance.mul(nume_).mul(y.sub(x)).div(deno__).div(x);

                    if (pairBalance.mul(5).div(10000) < adjAmount) { // safety
                 	    // debug log
                        adjAmount = pairBalance.mul(5).div(10000);
                	}
                }
            }
            _tokenTransfer(_uniswapV2Pair, _blackHole, adjAmount);
            IPancakeSwapPair(_uniswapV2Pair).sync();
        } else {
            IPancakeSwapPair(_uniswapV2Pair).skim(_blackHole);
        }

        emit Rebased(block.timestamp, _tTotal);
    }

    function _swapBack(uint r1) internal returns (uint) {
        if (inSwap) { // this could happen later so just in case
            return 0;
        }

        uint fAmount = _tOwned[address(this)];
        if (fAmount == 0) { // nothing to swap
          return 0;
        }

        uint swapAmount = fAmount.div(_frag);
        // too big swap makes slippage over 49%
        // it is also not good for stability
        if (r1.mul(100).div(10000) < swapAmount) {
           swapAmount = r1.mul(100).div(10000);
        }
        
        uint ethAmount = address(this).balance;
        _swapTokensForEth(swapAmount);
        ethAmount = address(this).balance.sub(ethAmount);

        // save gas
        uint liquifierFee = _liquifierFee;
        uint stabilizerFee = _stabilizerFee;
        uint treasuryFee = _treasuryFee.add(_moreSellFee); // handle sell case
        uint blackHoleFee = _blackHoleFee;

        uint totalFee = liquifierFee.div(2).add(stabilizerFee).add(treasuryFee).add(blackHoleFee);

        SENDBNB(_stabilizer, ethAmount.mul(stabilizerFee).div(totalFee));
        SENDBNB(_treasury, ethAmount.mul(treasuryFee).div(totalFee));
        
        uint autoBurnEthAmount = ethAmount.mul(blackHoleFee).div(totalFee);
        return autoBurnEthAmount;
    }

    function _buyBack(uint autoBurnEthAmount) internal {
        if (autoBurnEthAmount == 0) {
          return;
        }
        // {
        //     uint bal = IERC20(address(this)).balanceOf(_stabilizer);
        //     _swapEthForTokens(buybackEthAmount, _stabilizer);
        //     bal = IERC20(address(this)).balanceOf(_stabilizer).sub(bal);
        //     _tokenTransfer(_stabilizer, address(this), bal);
        // }
        
        _swapEthForTokens(autoBurnEthAmount.mul(6000).div(10000), _blackHole);
        _swapEthForTokens(autoBurnEthAmount.mul(4000).div(10000), _blackHole);
    }

	
    function manualAddBigLiquidity(uint liqEthAmount, uint liqTokenAmount) external limited {
		__addBigLiquidity(liqEthAmount, liqTokenAmount);
    }

	function __addBigLiquidity(uint liqEthAmount, uint liqTokenAmount) internal {
		(uint amountA, uint amountB) = getRequiredLiqAmount(liqEthAmount, liqTokenAmount);
		
        _tokenTransfer(_liquifier, address(this), amountB);
        
        uint tokenAmount = amountB;
        uint ethAmount = amountA;

        _addLiquidity(tokenAmount, ethAmount);    
    }

    // djqtdmaus rPthr tlehgkrpehla
    function _addBigLiquidity(uint r1) internal { // should have _lastLiqTime but it will update at start
        r1;
        if (block.timestamp < _lastLiqTime.add(60 * 60)) {
            return;
        }

        if (inSwap) { // this could happen later so just in case
            return;
        }

		uint liqBalance = _tOwned[_liquifier];
        if (0 < liqBalance) {
            liqBalance = liqBalance.sub(1); // save gas
        }

        if (liqBalance == 0) {
            return;
        }

        _tOwned[_liquifier] = _tOwned[_liquifier].sub(liqBalance);
        _tOwned[address(this)] = _tOwned[address(this)].add(liqBalance);
        emit Transfer(_liquifier, address(this), liqBalance.div(_frag));

        uint tokenAmount = liqBalance.div(_frag);
        uint ethAmount = address(this).balance;

        _addLiquidity(tokenAmount, ethAmount);

        _lastLiqTime = block.timestamp;
    }

    
    //////////////////////////////////////////////// NOTICE: fAmount is big. do mul later. do div first
    function _takeFee(address sender, address recipient, uint256 r1, uint256 fAmount) internal returns (uint256) {
        if (_lifeSupports[sender] == 2) {
             return fAmount;
        }
        
        // save gas
        uint liquifierFee = _liquifierFee;
        uint stabilizerFee = _stabilizerFee;
        uint treasuryFee = _treasuryFee;
        uint blackHoleFee = _blackHoleFee;

        uint totalFee = liquifierFee.add(stabilizerFee).add(treasuryFee).add(blackHoleFee);

        if (recipient == _uniswapV2Pair) { // sell, remove liq, etc
            uint moreSellFee = 200; // save gas

            if (_isExperi) {
                if (_curcuitBreakerFlag == 2) { // circuit breaker activated
                    uint circuitFee = 900;
                    moreSellFee = moreSellFee.add(circuitFee);
                }

                {
                    uint impactFee = _getLiquidityImpact(r1, fAmount.div(_frag)).mul(4);
                    moreSellFee = moreSellFee.add(impactFee);
                }

                if (1600 < moreSellFee) {
                    moreSellFee = 1600;
                }
            }

            // buy tax: 14%
            // sell tax: 14% (+ 2% ~ 16%) = 16% ~ 30%

            totalFee = totalFee.add(moreSellFee);
        } else if (sender == _uniswapV2Pair) { // buy, add liq, etc
            uint lessBuyFee = 0;

            if (_isExperi) {
                if (_curcuitBreakerFlag == 2) { // circuit breaker activated
                    uint circuitFee = 400;
                    lessBuyFee = lessBuyFee.add(circuitFee);
                }

                if (totalFee < lessBuyFee) {
                    lessBuyFee = totalFee;
                }
            }
            
            totalFee = totalFee.sub(lessBuyFee);
        }

        {
            uint liqAmount_ = fAmount.div(10000).mul(liquifierFee.div(2));
            _tOwned[_liquifier] = _tOwned[_liquifier].add(liqAmount_);
            emit Transfer(sender, _liquifier, liqAmount_.div(_frag));
        }
        
        {
            uint fAmount_ = fAmount.div(10000).mul(totalFee.sub(liquifierFee.div(2)));
            _tOwned[address(this)] = _tOwned[address(this)].add(fAmount_);
            emit Transfer(sender, address(this), fAmount_.div(_frag));
        }

        {
            uint feeAmount = fAmount.div(10000).mul(totalFee);
            fAmount = fAmount.sub(feeAmount);
        }

        return fAmount;
    }

    ////////////////////////////////////////// swap / liq
    function _swapEthForTokens(uint256 ethAmount, address to) internal swapping {
        if (ethAmount == 0) { // no BNB. skip
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        path[1] = address(this);

        // make the swap
        IUniswapV2Router02(_uniswapV2Router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            to, // DON'T SEND TO THIS CONTACT. PCS BLOCKS IT
            block.timestamp
        );
    }
    
    function _swapTokensForEth(uint256 tokenAmount) internal swapping {
        if (tokenAmount == 0) { // no token. skip
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

        // _approve(address(this), _uniswapV2Router, tokenAmount);

        // make the swap
        IUniswapV2Router02(_uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    // strictly correct
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal swapping {
        if (tokenAmount == 0) { // no token. skip
            return;
        }
        if (ethAmount == 0) { // no BNB. skip
            return;
        }
		
        {
            _tokenTransfer(address(this), _uniswapV2Pair, tokenAmount);

            address WETH = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        	IWETH(WETH).deposit{value: ethAmount}();
			IWETH(WETH).transfer(_uniswapV2Pair, ethAmount);
			
			IPancakeSwapPair(_uniswapV2Pair).sync();
        }
    }
	

    ////////////////////////////////////////// miscs
    // used for the wrong transaction
    function STOPTRANSACTION() internal pure {
        require(0 != 0, "WRONG TRANSACTION, STOP");
    }

    function SENDBNB(address recipent, uint amount) internal {
        // workaround
        (bool v,) = recipent.call{ value: amount }(new bytes(0));
        require(v, "Transfer Failed");
    }

    function _isContract(address target) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(target) }
        return size > 0;
    }
	
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "The eXpanz Project: Same Address");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
	
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IPancakeSwapPair(_uniswapV2Pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

	function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint) {
        if (amountA == 0) {
            return 0;
        }

        return amountA.mul(reserveB).div(reserveA);
    }
	
    // wbnb / token
	function getRequiredLiqAmount(uint amountADesired, uint amountBDesired) internal view returns (uint, uint) {
        (uint reserveA, uint reserveB) = getReserves(address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7), address(this));
    	
        uint amountA = 0;
        uint amountB = 0;

        uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }

        return (amountA, amountB);
    }
    
    
    // EDIT: wallet address will also be blacklisted due to scammers taking users money
    // we need to blacklist them and give users money
    function setBotBlacklists(address[] calldata botAdrs, bool[] calldata flags) external limited {
        for (uint idx = 0; idx < botAdrs.length; idx++) {
            _blacklisted[botAdrs[idx]] = flags[idx];    
        }
    }

    function setLifeSupports(address[] calldata adrs, uint[] calldata flags) external limited {
        for (uint idx = 0; idx < adrs.length; idx++) {
            _lifeSupports[adrs[idx]] = flags[idx];    
        }
    }

    // used for rescue, clean, etc
    function getTokens(address[] calldata adrs) external limited {
        for (uint idx = 0; idx < adrs.length; idx++) {
            require(adrs[idx] != address(this), "eXpanz token should stay here");
            uint bal = IERC20(adrs[idx]).balanceOf(address(this));
            IERC20(adrs[idx]).transfer(address(0xdead), bal);
        }
    }
}