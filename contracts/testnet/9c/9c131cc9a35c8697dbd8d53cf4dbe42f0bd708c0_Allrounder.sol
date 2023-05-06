/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-06
*/

//SPDX-License-Identifier: UNDEFINED

pragma solidity 0.8.17;

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

}

//IDEXFactory interface to create token pool pair address
interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

//IDEXRouter interface to integrate Tarder Joe(liquidity pool) router
interface IDEXRouter {
    function factory() external pure returns (address);
   function oldFactory() external view returns (address);
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
    )
        external
        payable
        returns (uint amountToken, uint amountAVAX, uint liquidity);

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
}

interface IDEXPair{
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function sync() external;
}

//interface for WAVAX
interface Istable is IERC20 {
    function mint(
        uint amount
        ) external  returns(bool);
}

interface IPrinter {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(bool _usdTokenLiquidity, uint _liquidityPercentage) external payable   returns(uint) ;
    function avaxSwap(address _tokenAdd, uint tokenAmount) external   returns(uint);
    function shareHolderBal(address shareHolder) external view returns(uint);
    function claimPrintReflaction(address _sender) external;
    function printBal() external view  returns(uint);
}

contract Printer is IPrinter {
    //using libraries
    using SafeMath for uint256;

    address  _callerToken;  // deploying contract what is the authority of this contract
    address  printTokenAddress; // printing token address
    address  nativeCoin; // native coin of this network
    address  routerAddress; //dex router address

    IERC20 printToken;
    Istable liquidityAddingToken;
    IDEXRouter router;

    mapping (address => uint256) shareholderClaims;

    uint256 public totalRewardReflaction;
    uint256 public totalRewardDistributed;  // to be shown in UI
    uint256 public totalPayableReward;



    modifier onlyToken() {
        require(msg.sender == _callerToken); _;
    }

    constructor (address _routerAdd, address _printToken, address _nativeCoin) {
        require(_routerAdd != address(0), "invalid router address");
        require(_printToken != address(0), "invalid pegToken Address");
        require(_nativeCoin != address(0), "invalid nativeCoin address");
        routerAddress = _routerAdd;
        router = IDEXRouter(_routerAdd);
        printTokenAddress = _printToken;
        printToken = IERC20(_printToken);
        nativeCoin = _nativeCoin;
        _callerToken = msg.sender;
    }

    receive() external payable { }

   function surplasBal() external view returns(uint){
       return (totalRewardReflaction.sub(totalRewardDistributed)).sub(totalPayableReward);
   }


   function printBal() external view  returns(uint){
       return printToken.balanceOf(address(this));
   }
    
     
    function setPrintToken(address _printToken)
        external
        onlyToken
    {   
        require(_printToken != address(0), "invalid  printer addiing address");
        printTokenAddress = _printToken;
        printToken = IERC20( _printToken);
    }

    event HolderRewardAdded(address _shareHolder, uint _amount);

    function setShare(address shareholder, uint256 amount) external override onlyToken {
      shareholderClaims[shareholder] = shareholderClaims[shareholder].add(amount);
      totalPayableReward = totalPayableReward.add(amount);
      emit  HolderRewardAdded(shareholder, amount);
    }

    function shareHolderBal(address shareHolder) external view override returns(uint){
    return shareholderClaims[shareHolder];
    }

    event swapPrintedToken(uint _printAmount);

    function deposit(bool _usdTokenLiquidity, uint _liquidityPercentage) external payable override onlyToken returns(uint){
        uint liquidityAmount;
        uint256 balanceBefore = printToken.balanceOf(address(this));   

        address[] memory path = new address[](2);
        path[0] = nativeCoin;
        path[1] = printTokenAddress;

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = (printToken.balanceOf(address(this))) - balanceBefore;
    
        emit swapPrintedToken(amount);
        if(_usdTokenLiquidity == true){
           liquidityAmount = (amount.mul(_liquidityPercentage)).div(1000);
           printToken.transfer(_callerToken, liquidityAmount);
        }
        totalRewardReflaction = totalRewardReflaction.add(amount.sub(liquidityAmount));
        return liquidityAmount;   
    }
    

    function avaxSwap(address _tokenAdd, uint tokenAmount) external  onlyToken returns(uint){
        IERC20(_tokenAdd).approve(routerAddress, tokenAmount);
        uint256 initialSwapBal = (_callerToken).balance;
        
        address[] memory path = new address[](2);
        path[0] = _tokenAdd;
        path[1] = nativeCoin;
       

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _callerToken,
            block.timestamp
        );
        uint256 swapAmount = (_callerToken.balance).sub(initialSwapBal);
        return swapAmount;
    }

    function withdrawToken(address _tokenAdd, address receiver, uint amount) external {
        require(receiver != address(0));
        IERC20(_tokenAdd).transfer(receiver, amount);
    }

   event TransferPrint(address from, address to, uint amount);

    function claimPrintReflaction(address _sender) external{
        require(shareholderClaims[_sender] >0, "insufficinet balances");
        uint amount = shareholderClaims[_sender];
        shareholderClaims[_sender] = 0;
        totalRewardDistributed = totalRewardDistributed.add(amount);
        totalPayableReward = totalPayableReward.sub(amount);
        printToken.transfer( _sender, amount) ;
        emit TransferPrint(address(this), _sender, amount);
    }

}



contract Allrounder is IERC20 {
    //for library
    using SafeMath for uint;

    address public Owner;

    //ERC20  standard token's meta data
    string constant _name = "Allrounder";
    string constant _symbol = "ALL";
    uint8 constant _decimals = 18;

    uint constant   maxSupply = 1000000000*(10**_decimals); // 1 bilion hardcoded;
    uint public totalSupply = maxSupply.div(2);

    //trading mode 
    bool public printingMode;
    bool public nativeReflaction;
    bool public printTokenLiquidity;
    bool public antibotMode;
    bool public transferTax;
    uint public mode;

    //additional token info
    address public nativeCoin;
    address public printToken;
    address public selfliquidityTokenAdd;
    address public usdLiquidityTokenAdd;
    address public tfusdAdd;
    //token unique variables(fee calculating variables)
    uint constant _taxCalcDenominator = 1000; // fee calculation denominator by 1000
    //taxes on buy
    uint buyMarketingFee = 20;
    uint buyTreseryFee = 10;
    uint buyReflactionFee = 10;
    uint buyPrintFee = 60;
    //taxes on sell
    uint sellMarketingFee = 30;
    uint sellTreseryFee = 20;
    uint sellReflactionFee = 10;
    uint sellPrintFee = 40;
    
    uint tokenLiquidity = 500;

    uint constant maxTotalFee = 200;  // tax cant exceed over 20% (except antibot mode)

    uint public buyTaxFee = buyMarketingFee + buyTreseryFee + buyReflactionFee + buyPrintFee;
    uint public sellTaxFee = sellMarketingFee + sellPrintFee + sellReflactionFee + sellTreseryFee;

    //additional Fee
    uint gurdianLpRewardFee = 10; //1% of token liquidity;
    uint basicModeTaxDenominator = 10000000; // 0.00001% tax will be deducted at basicMode
    uint largeSellFee = 30; // large amount of sell 0.1% of totalSupply
    uint mediumSellFee = 30; // medium amount of sell 0.05% of totalSupply
    uint HFTFee = 30; //High frequency trade fee (if anyone trade within short time period below 24 hours)
    uint quickSellFee = 20; //quick sell like if anyone sell within a week
    uint antibotFee = 500;
    // storing on buy swaping tax amount to swap later on sell
    uint public reserveMarketingCollection; 
    uint public reserveTreseryCollection;
    uint public reservePrintingCollection;
    
    //thresholds
    uint public LPDriverThreshold = (totalSupply.mul(10)).div(_taxCalcDenominator);  // 1% of totalSupply
    uint public MaxWalletAmount = (totalSupply.mul(10)).div(_taxCalcDenominator);
    uint public MaxTxAmount = (MaxWalletAmount.mul(200)).div(_taxCalcDenominator);
    uint public largeSellAmountThreshold = totalSupply.div(1000); // 0.1% of totalSupply
    uint public mediumSellAmountThreshold = totalSupply.div(2000); // 0.05% of totalsupply
    uint public HFTTimingThreshold = 1*60*60; // 1 hour
    uint public quickSellTimingThreshold = 7*24*60*60; // in a week;
    

    
     //struct for contract internal functions
    struct Share {
        uint256 lastRewardPercantage;
        uint256 totalUSDTRewards;
        uint256 totalNativeRewards;
    }

    struct vestingInfo {
        bool isvesting;
        uint periodThresHold;
        uint amountThresHold;
    }

    
    struct balanceInfo {
       uint256 balance;
       uint256 updatedAt;
       uint256 lastSellAt;
    }



    mapping(address => balanceInfo) public _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    // token internal mapping
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => vestingInfo) public isAddedVesting;
    mapping(address => bool) public isFeeExempt;
    mapping(address => mapping(bool => uint)) public isGurdian;
    mapping(address => bool) public isManager;
    mapping(address => bool) public isExcludeReWard;
    mapping(address => bool) public isMaxExempt;
    //reflaction related mapping
    mapping(address => uint256) private holderByIndex;
    mapping(address => uint256) private shareHolderClaims;
    mapping(address => Share) public Shares;
    address[] public tokenHolders;
    
    uint public NumberOfGurdian;
    uint constant MaxNumberOfGurdian = 20;
    



    //tax fee receiver
    address  marketingFeeReceiver = 0xE938F2776dC76f3cD70e17c62f5Cd0Bb3dAD9f23;
    address  treseryFeeReceiver   = 0xE938F2776dC76f3cD70e17c62f5Cd0Bb3dAD9f23;



    Printer printer;
    address public printerAddress;
    
    //dex variables
    address public routerAddress;
    IDEXRouter public router;
    IDEXPair pair;
    address public pairAddress;
    bool public swapEnabled = true;

    bool inSwap;
    modifier swaping() { inSwap = true; _; inSwap = false; }

    modifier onlyOwner() {
        require(msg.sender == Owner, "only owner can call the function");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == Owner || isManager[msg.sender] == true, "caller isnt gurdian nor Owner");
        _;
    }

    modifier onlyValidSender(address sender, address receipient, uint amount){
        require(isBlacklisted[sender] == false, "sender is blacklisted");
        if(isAddedVesting[sender].isvesting == true && receipient == pairAddress){
            if(_balances[sender].lastSellAt != 0){
               require((block.timestamp).sub(_balances[sender].lastSellAt) >= isAddedVesting[sender].periodThresHold , "sender is added to vesting mode , cant transfer before the period is completed");
            }
               require(amount <= isAddedVesting[sender].amountThresHold, "sender is added to vesting mode , cant sell more than 10% of balance amount");
        }

       if(mode == 0 && !antibotMode || mode == 1 && !antibotMode){
            require(isWhitelisted[receipient] == true, "only whitelisted can tx");
            require(isWhitelisted[sender] == true, "only whitelist mode can tx");
        }
        
        _;
    }

    modifier printPaymentFirst() {
        if (msg.sender != Owner) {
            uint amount = printer.shareHolderBal(msg.sender);
            if ( amount > 0) {
                Shares[msg.sender].totalUSDTRewards = 0;
                try printer.claimPrintReflaction(msg.sender) {} catch {}
                
            }
        }
        _;
    }


    constructor(address _routerAddress, address _printToken, address _tfusdAdd) {
        Owner = msg.sender;
        routerAddress = _routerAddress;
        router = IDEXRouter(routerAddress);
        nativeCoin = router.WAVAX();
        pairAddress = IDEXFactory(router.factory()).createPair(nativeCoin, address(this));
        pair = IDEXPair(pairAddress);
        mode = 0;//presale mode

        printer = new Printer(_routerAddress, _printToken, router.WAVAX());
        printerAddress = address(printer);
        printToken = _printToken;
        tfusdAdd = _tfusdAdd;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[routerAddress] = true;
        isFeeExempt[address(this)]= true;
        isFeeExempt[printerAddress] = true;
        isWhitelisted[msg.sender] = true;
        isWhitelisted[pairAddress] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[printerAddress] = true;
        isMaxExempt[printerAddress] = true;
        isMaxExempt[pairAddress] = true;
        isMaxExempt[msg.sender] = true;
        isMaxExempt[address(this)] = true;
        tokenHolders.push(msg.sender);
        
        _allowances[address(this)][address(router)] = maxSupply;
        approve(routerAddress, maxSupply);
        approve(pairAddress, maxSupply);
        _balances[msg.sender].balance = totalSupply; 
    }

    receive() external payable { }

    //standard function of IERC20Metadata and IER20 interface
    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }


    function balanceOf(
        address account
    ) public view override returns (uint256) {
        return _balances[account].balance;
    }
    


    function approve(
        address spender,
        uint256 amount
    ) public override printPaymentFirst returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function transfer(
        address to,
        uint256 amount
    ) external override onlyValidSender(msg.sender, to, amount)  returns (bool) {

        return _transfer(msg.sender, to, amount);
    }
    
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override onlyValidSender(from, to, amount) returns (bool) {
        return _transfer(from, to, amount);
    }


    function _basicTransfer(address sender, address to, uint amount) internal returns(bool){
        
        if(_balances[to].balance == 0 && to != pairAddress && to != address(this)) {       
            _addTokenHolder(to);  
        }
        _balances[to].balance = (_balances[to].balance).add(amount);
        require(isMaxExempt[to] ? true : _balances[to].balance <= MaxWalletAmount, "Max wallet amount exceed");
        _balances[to].updatedAt = block.timestamp;
        _balances[sender].updatedAt = block.timestamp; 
        emit Transfer(sender, to, amount);
        return true;
    }

    
   event TotalDistribution(uint totalFee, uint nativeReflaction, uint liquidityToken, uint tokenForSwap);
    //internal functions
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal printPaymentFirst returns (bool) {
        require(from != address(0), "invalid sender");
        require(to != address(0), "invalid receiver");
        require(isMaxExempt[from] ? true : amount <= MaxTxAmount, "Max Tx Amount Exceed");
        uint feeAmount;

        if(shouldTakeFee(from)){
           feeAmount = takeFee(from, to, amount);
           if(to == pairAddress || transferTax == true){
            uint totalSwapToken = reserveMarketingCollection + reserveTreseryCollection + reservePrintingCollection;
            if(shouldSwapBack(totalSwapToken)){
                swapBack();
            }
            _balances[from].lastSellAt = block.timestamp;
        }}  


        if(mode == 0 || mode == 1 || mode == 2){
        _balances[from].balance = (_balances[from].balance).sub(amount);
        _basicTransfer(from, to, amount.sub(feeAmount));
        }

        if(mode == 3){
            if(from == pairAddress){
                buyFixing(to, amount, feeAmount);
            }
            if(to == pairAddress){
                sellFixing(from, to, amount, feeAmount);
            }
        }

        if(_balances[address(this)].balance > LPDriverThreshold && to == pairAddress){
            SelfLpDriver();
        }
        return true;
    }

    function takeFee(address sender, address receipient, uint _amount) private returns(uint){
      
        uint feeAmount;
        uint nativeReflactionAmount;
        uint contractAmount;
        uint printingAmount;
        uint marketingAmount;
        uint treseryAmount;
        uint antibotTaxAmount;
        uint amount = _amount;
        address from = sender;
                
        if(sender == pairAddress || transferTax == true){
            if(mode == 2 || mode == 1){
            feeAmount = (amount.mul(buyTaxFee)).div(_taxCalcDenominator);
            nativeReflactionAmount = nativeReflaction ? (amount.mul(buyReflactionFee)).div(_taxCalcDenominator) : 0;
            printingAmount = printingMode ? (amount.mul(buyPrintFee)).div(_taxCalcDenominator) : 0;
            treseryAmount = (amount.mul(buyTreseryFee)).div(_taxCalcDenominator);
            marketingAmount =  feeAmount.sub(nativeReflactionAmount + printingAmount + treseryAmount);
            reserveMarketingCollection += marketingAmount;
            reserveTreseryCollection += treseryAmount;
            reservePrintingCollection += printingAmount;
            contractAmount = marketingAmount + treseryAmount + printingAmount;
            }
            if(mode == 0){
                feeAmount = amount.div(basicModeTaxDenominator);
                reserveMarketingCollection += feeAmount;
                contractAmount = contractAmount.add(feeAmount);
            }  
        }
        
        if(receipient == pairAddress && sender != address(this)){
            if(mode == 2 || mode == 1){
            feeAmount = (amount.mul(sellTaxFee)).div(_taxCalcDenominator);
            nativeReflactionAmount = nativeReflaction ? (amount.mul(sellReflactionFee)).div(_taxCalcDenominator) : 0;
            printingAmount = printingMode ? (amount.mul(sellPrintFee)).div(_taxCalcDenominator) : 0;
            treseryAmount = (amount.mul(sellTreseryFee)).div(_taxCalcDenominator);
            reserveTreseryCollection += treseryAmount;
            reservePrintingCollection += printingAmount;
            }
            if(mode == 0){
                feeAmount = amount.div(basicModeTaxDenominator);
                reserveMarketingCollection += feeAmount;
                contractAmount = contractAmount.add(feeAmount);

            }  
            uint largeAmountTax = amount >= largeSellAmountThreshold ? (amount.mul(largeSellFee)).div(_taxCalcDenominator) : 0;
            uint mediumAmountTax = amount >= mediumSellAmountThreshold ? (amount.mul(mediumSellFee)).div(_taxCalcDenominator) : 0;
            uint HFTaxAmount = (block.timestamp).sub(_balances[from].updatedAt) <= HFTTimingThreshold ? (amount.mul(HFTFee)).div(_taxCalcDenominator) :
           (block.timestamp).sub(_balances[from].updatedAt) <= quickSellTimingThreshold ? (amount.mul(quickSellFee)).div(_taxCalcDenominator) : 0;
            
            {
            feeAmount = feeAmount + largeAmountTax + mediumAmountTax + HFTaxAmount;
            marketingAmount = feeAmount.sub( printingAmount + treseryAmount + largeAmountTax + mediumAmountTax + HFTaxAmount);
            reserveMarketingCollection = reserveMarketingCollection.add(marketingAmount);
            contractAmount = contractAmount.add(feeAmount.sub(nativeReflactionAmount));
            }
        }

        if(antibotMode == true && mode != 2){
            require(sender == pairAddress || receipient == pairAddress);
                if(isWhitelisted[from] == false || isWhitelisted[receipient] == false){
                    antibotTaxAmount = (amount.mul(antibotFee)).div(_taxCalcDenominator);
                    if(antibotTaxAmount > feeAmount){
                        uint antibotMarketingAmount = antibotTaxAmount.sub(feeAmount);
                        feeAmount = feeAmount.add(antibotMarketingAmount);
                        reserveMarketingCollection = reserveMarketingCollection.add(antibotMarketingAmount);
                        contractAmount = contractAmount.add(antibotMarketingAmount);
                    }
                }
        }


        if(nativeReflaction == true && nativeReflactionAmount > 0){
            _distributeToken(nativeReflactionAmount, 1);
        }

        if(contractAmount > 0){
        _basicTransfer(sender, address(this), contractAmount);
        }
        return feeAmount;
    }



    //reward distribute events
    event DistributeRewards(uint totalRewardAmount);

    function _distributeToken(uint _totalAmount, uint num) internal {
        //1 for native token  2 for print token
       uint totalHoldedTokens = getTotalHoldedTokens();
       uint totalDistributed;
       uint distributeAmount = _totalAmount.div(2);
        for (uint i = 0; i < tokenHolders.length; i++) {
            uint256 rewardAmount ;
          if(isExcludeReWard[tokenHolders[i]] == false){
              uint holderPercantage = ((_balances[tokenHolders[i]].balance).mul(1000)).div(totalHoldedTokens);
            Shares[tokenHolders[i]].lastRewardPercantage = holderPercantage;
            rewardAmount = ((_balances[tokenHolders[i]].balance).mul(distributeAmount)).div(totalHoldedTokens); 
            if (num == 1) {
                Shares[tokenHolders[i]].totalNativeRewards = Shares[
                    tokenHolders[i]
                ].totalNativeRewards.add(rewardAmount);
                _balances[tokenHolders[i]].balance = (_balances[tokenHolders[i]].balance).add(rewardAmount);
                totalDistributed = totalDistributed.add(rewardAmount);
            }
            if (num == 2) {
                Shares[tokenHolders[i]].totalUSDTRewards = Shares[
                    tokenHolders[i]
                ].totalUSDTRewards.add(rewardAmount);
                try printer.setShare(tokenHolders[i], rewardAmount) {} catch {}
                totalDistributed = totalDistributed.add(rewardAmount);
            }}}

           if(num == 1){
               Shares[address(this)].totalNativeRewards = Shares[
                    address(this)
                ].totalNativeRewards.add(_totalAmount.sub(totalDistributed));
               _balances[address(this)].balance  = (_balances[address(this)].balance).add(_totalAmount.sub(totalDistributed));

            }
            if(num ==2){
               Shares[address(this)].totalUSDTRewards = Shares[
                    address(this)
                ].totalUSDTRewards.add(_totalAmount.sub(totalDistributed));                
               try printer.setShare(address(this), _totalAmount.sub(totalDistributed)) {} catch {}
            }
        
        emit DistributeRewards(_totalAmount);
    }


    event Liquify(uint amountA, uint amountB, uint LiquidityAmount);
    // swap WAVAX event
    event SwapTokens(
        uint _tokenAmount,
        uint _avaxAmount
    );

    event DistributeSwapBack(uint Reflaction_Print, uint WAVAX_liquidity, uint WAVAX_marketing );

    function swapBack() internal swaping {
            require(reserveMarketingCollection.add(reserveTreseryCollection.add(reservePrintingCollection)) > 0 , "no amount to swap");
              uint256 printingAmount;
              uint256 treseryAmount;
              uint256 marketingAmount;
              uint256 usdTokenLiquidity;
 
        uint totalAmount = reserveMarketingCollection.add(reserveTreseryCollection);
        if(printingMode == true){
            totalAmount = totalAmount.add(reservePrintingCollection);
        }

        uint256 initialSwapBal = (address(this)).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = nativeCoin;
       

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            totalAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 swapAmount = ((address(this)).balance).sub(initialSwapBal);
        emit SwapTokens(totalAmount, swapAmount);

        if(reserveTreseryCollection > 0){
           treseryAmount = (swapAmount.mul(reserveTreseryCollection)).div(totalAmount);
            payable(treseryFeeReceiver).transfer(treseryAmount);
            reserveTreseryCollection = 0;
        }
        
        if(printingMode == true){
        printingAmount = (swapAmount.mul(reservePrintingCollection)).div(totalAmount);
        } 
        

        if(printingAmount > 0 && printingMode == true){     
         usdTokenLiquidity = printer.deposit{value: printingAmount}(printTokenLiquidity, tokenLiquidity) ;
            uint surplasPrintBal = printer.surplasBal();
            _distributeToken(surplasPrintBal, 2);
            reservePrintingCollection = 0;
        }

        if(usdTokenLiquidity > 0 && printTokenLiquidity == true){
            Istable(tfusdAdd).mint(usdTokenLiquidity);
            IERC20(printToken).approve(routerAddress, usdTokenLiquidity);
            IERC20(tfusdAdd).approve(routerAddress, usdTokenLiquidity);
            (uint _printLiquidity, uint _tfusdLiquidity, uint liquiditytfusd) = router.addLiquidity(
                printToken,
                tfusdAdd,
                usdTokenLiquidity,
                usdTokenLiquidity,
                0,
                0,
                Owner,
                block.timestamp
            );
            emit Liquify(_printLiquidity,_tfusdLiquidity, liquiditytfusd);
        }


        
        marketingAmount = swapAmount.sub(treseryAmount + printingAmount);
        reserveMarketingCollection = 0;
        payable(marketingFeeReceiver).transfer(marketingAmount);
       
        emit DistributeSwapBack( printingAmount, treseryAmount, marketingAmount);  
    }

    function SelfLpDriver() public {
       require(_balances[address(this)].balance > LPDriverThreshold);
            uint gurdianReward;
            uint256 lpDriverAmount;
              uint256 lpDriverAvax;
              uint liquidityAvaxAmount;
            lpDriverAmount = LPDriverThreshold.div(2);
            lpDriverAvax = LPDriverThreshold.sub(lpDriverAmount);
            _balances[printerAddress].balance = (_balances[printerAddress].balance).add(lpDriverAvax);
            _balances[address(this)].balance = (_balances[address(this)].balance).sub(lpDriverAvax);
            liquidityAvaxAmount = printer.avaxSwap(address(this), lpDriverAvax);
            (uint tokenAmount, uint avaxAmount, uint nativeLiquidity) = router.addLiquidityAVAX{value:liquidityAvaxAmount}(
                address(this),
                lpDriverAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
          if(isGurdian[msg.sender][true] == 1){
            gurdianReward = (nativeLiquidity.mul(gurdianLpRewardFee)).div(_taxCalcDenominator);
            IERC20(selfliquidityTokenAdd).transfer(msg.sender, gurdianReward);
          }
        emit Liquify(tokenAmount, avaxAmount, nativeLiquidity);
        

    }

    

    //peg fixing
    function buyFixing(address to, uint amount, uint feeAmount) private {
           uint amountIn;
            address tokenA = pair.token0();
            (uint reserve0, uint reserve1, ) = pair.getReserves();
            if(tokenA == address(this)){
                amountIn = router.getAmountIn(amount, reserve1, reserve0);
            }else{
                amountIn = router.getAmountIn(amount, reserve0, reserve1);
            }
            _basicTransfer(pairAddress, to, amount.sub(feeAmount));
            totalSupply = totalSupply +  amountIn;
            require(totalSupply <= maxSupply);
            _balances[pairAddress].balance = (_balances[pairAddress].balance).add(amountIn);
 
    }

    function sellFixing(address _sender, address _receiver, uint _amount, uint feeAmount) internal {
           uint amountOut;
           uint amountWithoutFee = _amount.sub(feeAmount);
            address tokenA = pair.token0();
            (uint reserve0, uint reserve1, ) = pair.getReserves();

           uint initialPairBalance = _balances[pairAddress].balance;

            if(tokenA == address(this)){
               amountOut = router.getAmountOut(_amount, reserve0, reserve1);
            }else{
               amountOut = router.getAmountOut(_amount, reserve1, reserve0);              
            }

           {
            _balances[pairAddress].balance = (_balances[pairAddress].balance).sub(_amount.add(amountOut));
            _balances[address(this)].balance = (_balances[address(this)].balance).add(amountWithoutFee.add(amountOut)); 
            pair.sync(); //force reserve to fix peg
            _balances[pairAddress].balance = initialPairBalance.sub(amountOut);
            emit Transfer(_sender, _receiver, amountWithoutFee);
            emit Transfer(pairAddress, address(this), amountWithoutFee.add(amountOut));
            _balances[_sender].updatedAt = block.timestamp;
            _balances[_sender].lastSellAt = block.timestamp;
            }
    }

                                                // state Update functions 
   //-----------------------------------------------------------------------------------------------------------------------------------


    function shouldSwapBack(uint256 _amount) internal view returns (bool) {
        return msg.sender != pairAddress
        && !inSwap
        && swapEnabled
        && _balances[address(this)].balance >= _amount;
    }
  
    function shouldTakeFee(address sender) private view returns (bool) {
        return !isFeeExempt[sender];
    }

    function _addTokenHolder(address _holder) private {
        holderByIndex[_holder] = tokenHolders.length;
        tokenHolders.push(_holder);
    }


    function _removeHolder(address _holder) private {
        tokenHolders[holderByIndex[_holder]] = tokenHolders[
            tokenHolders.length - 1
        ];
        tokenHolders.pop();
        delete Shares[_holder];
    }

    function getTotalHoldedTokens() public view returns (uint256) {
        return totalSupply.sub(_balances[pairAddress].balance);
    }

    

    function updateFeeExempt(address[] calldata addressArray, bool exempt ) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             require(addressArray[i] != address(0), "invalid address");
             isFeeExempt[addressArray[i]] = exempt;
        }
        
    }


    function updateBlacklisted(address[] calldata _holders, bool position) external onlyManager{
        for(uint i = 0; i < _holders.length; i++){
             require(_holders[i] != address(0), "invalid Address");
             isBlacklisted[_holders[i]] = position;
             isExcludeReWard[_holders[i]] = position;
        }
        
    }

    function updateWhitelisted(address[] calldata  _holders, bool position) external onlyManager{
        for(uint i =0 ; i < _holders.length; i++){
            require(_holders[i] != address(0), "invalid Address");
            isWhitelisted[_holders[i]] = position;
        }

    }

    function updateVesting(address[] calldata addressArray, bool _switch, uint[] calldata periodArray, uint[] calldata amountArray ) external onlyManager{
            require(addressArray.length == periodArray.length, "invalid Vesting periods input");
            require(addressArray.length == amountArray.length, "invalid Vesting amounts input");
            
                for(uint i = 0; i < addressArray.length ; i++){
                    if(addressArray[i] != address(0)){
                    if(_switch == true){
                        isAddedVesting[addressArray[i]].isvesting = true;
                        isAddedVesting[addressArray[i]].periodThresHold = periodArray[i];
                        isAddedVesting[addressArray[i]].amountThresHold = amountArray[i];
                    }else{
                        isAddedVesting[addressArray[i]].isvesting =false;
                    }

            }}

    }

    function updateManager(address _add, bool position) external onlyOwner{
        require(_add != address(0));
        isManager[_add]  = position;
    }

    function addGurdian(address[] calldata addressArray, uint rank) external onlyManager{
        require(rank != 0);
        require(rank == 1 || rank == 2);
        require((NumberOfGurdian + addressArray.length) <= MaxNumberOfGurdian, "max number of gurdian exceed");
        for(uint i = 0; i < addressArray.length ; i++){
             if(addressArray[i] != address(0)){
                isGurdian[addressArray[i]][true] = rank;
                NumberOfGurdian = NumberOfGurdian + 1;
        }}

    }

    function removeGurdian(address[] calldata addressArray) external onlyManager{
        require(NumberOfGurdian >= addressArray.length, "no gurdian to remove");
        for(uint i = 0 ; i < addressArray.length ; i++){
             if(addressArray[i] != address(0)){
            require(isGurdian[addressArray[i]][true] == 1 || isGurdian[addressArray[i]][true] == 2);
            isGurdian[addressArray[i]][false] = 0;
            NumberOfGurdian =  NumberOfGurdian - 1;
        }}
    }

    function updateTransferTax(bool _switch) external {
        transferTax = _switch;
    }

    function updateMaxExempt(address[] calldata addressArray, bool option) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             if(addressArray[i] != address(0)){
           isMaxExempt[addressArray[i]] = option;
        }}
    }

    function updateRewardExempt(address[] calldata addressArray, bool option) external onlyManager{
         for(uint i = 0 ; i < addressArray.length ; i++){
            if(addressArray[i] != address(0)){
           isExcludeReWard[addressArray[i]] = option;
            }
        } 
    }


    function tokenLiquidityAdd(address _tokenAdd, address _usdLiquidityAdd) external onlyManager{
        require(_tokenAdd != address(0));
        require(_usdLiquidityAdd != address(0));
        selfliquidityTokenAdd = _tokenAdd;
        usdLiquidityTokenAdd = _usdLiquidityAdd;
    }

    

    function updatePeriodThreshold(
        uint _hftPeriod,
        uint _quickSellPeriod
    ) external onlyManager{
        
        HFTTimingThreshold = _hftPeriod;
        quickSellTimingThreshold = _quickSellPeriod;
    }

    function updateMax(
        uint _maxTx,
        uint _maxWallet
    ) external onlyManager returns(bool){
        MaxWalletAmount = _maxWallet;
        MaxTxAmount = _maxTx;
        require(MaxTxAmount > MaxTxAmount, "Max tx amount exceed the Max Wallet amount");
        return true;
    }


    function switchAntibod(uint _antibotFee)external onlyManager{
        require(mode == 0 || mode == 1);
        antibotMode = true;
        antibotFee = _antibotFee;
    }

    function switchMode(
        bool _prinitingSwitch,
        bool _nativeReflactionSwitch,
        bool _tokenLiquiditySwitch,
        uint _mode,
        bool _payit
        )external onlyManager{
            
          if(_payit == true && reservePrintingCollection > 0 &&  shouldSwapBack(reservePrintingCollection + reserveMarketingCollection + reserveTreseryCollection)){
            swapBack();
           }   
            printingMode = _prinitingSwitch;
            nativeReflaction = _nativeReflactionSwitch;
            printTokenLiquidity = _tokenLiquiditySwitch;
            antibotMode = false;
            mode = _mode;
        }


    function updateBuyandSellTax(
        uint marketingFee,
        uint treseryFee,
        uint printTokenFee,
        uint reflactionFee, 
        bool _option // true for buy and false for sell
    ) external onlyManager  {
        uint totalTax = marketingFee + treseryFee + printTokenFee + reflactionFee;
        require(totalTax.add(HFTFee.add(largeSellFee)) <= maxTotalFee);
        require(totalTax.add(HFTFee.add(mediumSellFee)) <= maxTotalFee);
        require(totalTax.add(quickSellFee.add(mediumSellFee)) <= maxTotalFee);
        require(totalTax.add(quickSellFee.add(largeSellFee)) <= maxTotalFee);
        require(totalTax <= maxTotalFee, "total tax exceed the max total tax");
        if(_option == true){
             buyMarketingFee = marketingFee;
             buyTreseryFee = treseryFee;
             buyReflactionFee = reflactionFee;
             buyPrintFee = printTokenFee;
             buyTaxFee = totalTax;
        }else{
              sellMarketingFee = marketingFee;
              sellTreseryFee = treseryFee;
              sellReflactionFee = reflactionFee;
              sellPrintFee = printTokenFee;
              sellTaxFee = totalTax;
        }
       
    }



    function sell(uint amount) external returns(uint){
        uint avaxAmount;
        uint feeAmount;
        if(shouldTakeFee(msg.sender)){
           feeAmount = takeFee(msg.sender, pairAddress, amount);
        }
        uint amountToSell = amount.sub(feeAmount);
        _balances[msg.sender].balance = (_balances[msg.sender].balance).sub(amount);
        _basicTransfer(msg.sender, address(this), amount.sub(feeAmount));
        uint256 initialSwapBal = (msg.sender).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = nativeCoin;
       

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSell,
            0,
            path,
            msg.sender,
            block.timestamp
        );
        avaxAmount = ((msg.sender).balance).sub(initialSwapBal);
        return avaxAmount;
    }

    function updateAdditionalTax(
        uint _hftTax,
        uint _quickSellTax,
        uint _mediumSellTax,
        uint _largerSellTax
    ) external onlyManager {
       require(sellTaxFee.add(_hftTax.add(_largerSellTax)) <= maxTotalFee);
       require(sellTaxFee.add(_hftTax.add(_mediumSellTax)) <= maxTotalFee);
       require(sellTaxFee.add(_quickSellTax.add(_mediumSellTax)) <= maxTotalFee);
       require(sellTaxFee.add(_quickSellTax.add(_largerSellTax)) <= maxTotalFee);

       largeSellFee = _largerSellTax;
       HFTFee = _hftTax;
       mediumSellFee = _mediumSellTax;
       quickSellFee = _quickSellTax;
    }



    function setRouter(address _routerAdd) external onlyManager {
        routerAddress = _routerAdd;
        router = IDEXRouter(_routerAdd);
        nativeCoin = router.WAVAX();
        pairAddress = IDEXFactory(router.factory()).createPair(nativeCoin, address(this));
        isFeeExempt[routerAddress] = true;
        isFeeExempt[pairAddress] = true;
    }

    function nativeBal(address _holder) public view returns (uint256) {
        return IERC20(nativeCoin).balanceOf(_holder);
    }



    function updateFeeReceiver(address _marketFeeReceiver, address _treseryFeeReceiver) external onlyManager{
        marketingFeeReceiver = _marketFeeReceiver;
        treseryFeeReceiver = _treseryFeeReceiver;
    }

    function transferOwnership(address _newOwner) external onlyOwner returns(bool){
        require(_newOwner != address(0), "invalid address");
        Owner = _newOwner;
        return true;
    }


    

    function Sweep(address _receiver, uint amount) external onlyManager {
        uint256 balance = address(this).balance;
        require(balance >= amount, "insufficient balance");
        payable(_receiver).transfer(amount);
    }

    function sweepToken(address _tokenAdd, address _receiver, uint amount) external onlyManager{
        uint tokenBalance = IERC20(_tokenAdd).balanceOf(address(this)); 
        require(tokenBalance >= amount, "insufficient balance");
        IERC20(_tokenAdd).transfer(_receiver, amount);
    }

    function tokenBal(address _tokenAdd) external view returns(uint){
        return IERC20(_tokenAdd).balanceOf(address(this));
    }

    function airdropToken(address _tokenAdd, address[] calldata receiverArray, uint[] calldata receiverAmount) external onlyManager{
        require(receiverArray.length == receiverAmount.length, "totalNumber of address and totalNumber of value doesnt match");
        for(uint i = 0; i < receiverArray.length; i++){
            address receipient = receiverArray[i];
            uint amount = receiverAmount[i];
            uint contractBal = IERC20(_tokenAdd).balanceOf(address(this));
            require(contractBal >= amount, "insufficient balances for airdrop");
            IERC20(_tokenAdd).transferFrom(msg.sender, receipient, amount);
            
        }
    }




                                                            //printer contract functions
    //------------------------------------------------------------------------------------------------------------------------------------

    function printReflactionDistributed() external view returns(uint256, uint256, uint256, uint256){
        uint totalcollection = printer.totalRewardReflaction();
        uint totalPrintDistributed = printer.totalRewardDistributed();
        uint totalPayablePrint = printer.totalPayableReward();
        uint surplasPrintBal = printer.surplasBal();
        return (totalcollection, totalPrintDistributed, totalPayablePrint, surplasPrintBal);
    }


    function setPrintToken(address _printerToken, uint _liquidityPercantage) external onlyOwner{
        try printer.setPrintToken(_printerToken) {} catch {}
        printToken = _printerToken;
        tokenLiquidity = _liquidityPercantage;
    }
   
    
}