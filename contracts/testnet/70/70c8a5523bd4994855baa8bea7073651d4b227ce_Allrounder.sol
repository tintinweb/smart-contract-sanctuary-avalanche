/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-24
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

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}



//IDEXRouter interface to integrate Tarder Joe(liquidity pool) router
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

    function swapExactTokensForTokens(
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

    //////// intefaces of stable usd token mint function  \\\\\\\\
interface Istable is IERC20 {
    function mint(
        uint amount
        ) external  returns(bool);
}


interface IPrinter {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(bool _usdTokenLiquidity, uint _liquidityPercentage) external payable   returns(uint) ;
    function avaxSwap(address _tokenAdd, uint tokenAmount) external   returns(uint);
    function shareHolderBal(address _tokenAdd, address shareHolder) external view returns(uint);
    function claimPrintReflaction(address _tokenAdd, address _sender) external;
    function printBal() external view  returns(uint);
}

contract Printer is IPrinter {

    ///////// using libraries \\\\\\\\\
    using SafeMath for uint256;

    address  _callerToken;  // authority contract which can regulate this 
    address  printTokenAddress; // printing token address
    address  nativeCoin; // native Wrraped coin address 
    address  routerAddress; //dex router address
    
         //////////////// contract instances \\\\\\\\\\\\\\\\\\
    IERC20 printToken;     
    Istable liquidityAddingToken;
    IDEXRouter router;
      
    mapping (address => mapping(address => uint256)) shareholderClaims;  // USd reward claiming mapping

    uint256 public totalRewardReflaction; // total printing token amount of Usd
    uint256 public totalRewardDistributed;  // to be shown in UI
    uint256 public totalPayableReward;  // total claimable reward amount



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
      shareholderClaims[printTokenAddress][shareholder] = shareholderClaims[printTokenAddress][shareholder].add(amount);
      totalPayableReward = totalPayableReward.add(amount);
      emit  HolderRewardAdded(shareholder, amount);
    }

    function shareHolderBal(address _tokenAdd, address shareHolder) external view override returns(uint){
    return shareholderClaims[_tokenAdd][shareHolder];
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

    function claimPrintReflaction(address _tokenAdd, address _sender) external{
        require(shareholderClaims[_tokenAdd][_sender] >0, "insufficinet balances");
        uint amount = shareholderClaims[_tokenAdd][_sender];
        shareholderClaims[_tokenAdd][_sender] = 0;
        totalRewardDistributed = totalRewardDistributed.add(amount);
        totalPayableReward = totalPayableReward.sub(amount);
        printToken.transfer( _sender, amount) ;
        emit TransferPrint(address(this), _sender, amount);
    }

}




contract Allrounder is IERC20 {

    ///////////////////// math library \\\\\\\\\\\\\\\\\\\\\\\
    using SafeMath for uint;

    address public Owner;

    ///////////////////// ERC20 token's meta data \\\\\\\\\\\\\\\\\\\\\\\
    string constant _name = "Allrounder";
    string constant _symbol = "ALR";
    uint8 constant _decimals = 18;
    uint constant   maxSupply = 1000000000*(10**_decimals); // 1 bilion hardcoded;
    uint public totalSupply = (maxSupply.mul(90)).div(100); // initial supply 0.9 bilion

    //////////////// events \\\\\\\\\\\\\\\\\\\\

        ///////////////////////////////////////trading mode \\\\\\\\\\\\\\\\\\\\\\\\\\\\
    bool public printingMode;
    bool public nativeReflaction;
    bool public printTokenLiquidity;
    bool public antibotMode;
    bool public transferTax;
    uint public mode;

        ////////////////////////////////// additional token info \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    address  nativeCoin;
    address public printToken = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d;
    address  selfliquidityTokenAdd;
    address  usdLiquidityTokenAdd;
    address public tfusdAdd = 0x0802d4944BDB973d9aE3bA20feb708DA7BFC93EE ;

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
    uint contractReflactionPortion = 900;
    uint gurdianLpRewardFee = 10; //1% of token liquidity;
    uint basicModeTaxDenominator = 10000000; // 0.00001% tax will be deducted at basicMode
    uint largeSellFee = 30; // large amount of sell 0.1% of totalSupply
    uint mediumSellFee = 30; // medium amount of sell 0.05% of totalSupply
    uint HFTFee = 30; //High frequency trade fee (if anyone trade within short time period below 24 hours)
    uint quickSellFee = 20; //quick sell like if anyone sell within a week
    uint antibotFee = 500;
    // storing on buy swaping tax amount to swap later on sell
    uint public  reserveMarketingCollection; 
    uint  reserveTreseryCollection;
    uint  reservePrintingCollection;
    
    //thresholds
    uint  LPDriverThreshold = (maxSupply.mul(10)).div(_taxCalcDenominator);  // 1% of totalSupply
    uint  MaxWalletAmount = (maxSupply.mul(10)).div(_taxCalcDenominator);
    uint  MaxTxAmount = (MaxWalletAmount.mul(200)).div(_taxCalcDenominator);
    uint  largeSellAmountThreshold = maxSupply.div(1000); // 0.1% of totalSupply
    uint  mediumSellAmountThreshold = maxSupply.div(2000); // 0.05% of totalsupply
    uint  HFTTimingThreshold = 1*60*60; // 1 hour
    uint  quickSellTimingThreshold = 7*24*60*60; // in a week;
    uint  boosterThreshold = 1000000*(10**_decimals); // peg booster threshold 
    
    //price goes up variables
    uint pegBoostingRate = 250;
    uint appreciateRate = 250;
    uint public reserveBooster;

    
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



    mapping(address => balanceInfo)  _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    // token internal mapping
    mapping(address => bool) public isWhitelisted;
    mapping(address => vestingInfo) public isAddedVesting;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool)  isGurdian;
    mapping(address => bool)  isManager;
    mapping(address => bool)  isExcludeReWard;
    mapping(address => bool)  isMaxExempt;
    //reflaction related mapping
    mapping(address => uint256) private holderByIndex;
    mapping(address => uint256) private shareHolderClaims;
    mapping(address => Share) public Shares;
    address[]  tokenHolders;
    
    uint  NumberOfGurdian;
    uint constant MaxNumberOfGurdian = 20;
    



    //tax fee receiver
    address  marketingFeeReceiver = 0xE938F2776dC76f3cD70e17c62f5Cd0Bb3dAD9f23;
    address  treseryFeeReceiver   = 0xE938F2776dC76f3cD70e17c62f5Cd0Bb3dAD9f23;



    Printer printer;
    address public printerAddress;
    
    //dex variables
    address public routerAddress;
    IDEXRouter  router;
    IDEXPair lTank;
    address public tAddress;
    bool  swapEnabled = true;

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
        if(isAddedVesting[sender].isvesting == true && receipient == tAddress){
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
        if (msg.sender != address(this)) {
            uint amount = printer.shareHolderBal(printToken, msg.sender);
            if ( amount > 0) {
                Shares[msg.sender].totalUSDTRewards = 0;
                try printer.claimPrintReflaction(printToken, msg.sender) {} catch {}
                
            }
        }
        _;
    }

    modifier lpdriver(bool permission){
        if(_balances[address(this)].balance > LPDriverThreshold && mode != 3 && permission == true){
            _lpDriver();
        }
        _;
    }

 

 
constructor(address _routerAddress) {
        Owner = msg.sender;
        routerAddress = _routerAddress;
        router = IDEXRouter(routerAddress);
        nativeCoin = router.WAVAX();
        tAddress = IDEXFactory(router.factory()).createPair(router.WAVAX(), address(this));
        lTank = IDEXPair(tAddress);

        printer = new Printer(routerAddress, printToken, router.WAVAX());
        printerAddress = address(printer);
        isFeeExempt[msg.sender] = true;
        isFeeExempt[routerAddress] = true;
        isFeeExempt[address(this)]= true;
        isFeeExempt[printerAddress] = true;
        isWhitelisted[msg.sender] = true;
        isWhitelisted[tAddress] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[printerAddress] = true;
        isMaxExempt[printerAddress] = true;
        isMaxExempt[tAddress] = true;
        isMaxExempt[msg.sender] = true;
        isMaxExempt[address(this)] = true;
       
        tokenHolders.push(msg.sender);
        
        _allowances[address(this)][address(router)] = maxSupply;
        approve(routerAddress, maxSupply);
        approve(tAddress, maxSupply);
        _balances[msg.sender].balance = totalSupply; 
    }

    receive() external payable { }

    ////////////// standard function of IERC20Metadata and IER20 interface \\\\\\\\\\\\\\\\\\\\
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
    ) public view override  returns (uint256) {
        return _balances[account].balance;
    }
    


    function approve(
        address spender,
        uint256 amount
    ) public override printPaymentFirst  returns (bool) {
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
    ) external override onlyValidSender(msg.sender, to, amount)   returns (bool) {

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
        if(_balances[to].balance == 0 && to != tAddress && to != address(this)) {       
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
     ) internal printPaymentFirst  returns (bool) {
        require(from != address(0), "invalid sender");
        require(to != address(0), "invalid receiver");
        require(isMaxExempt[from] ? true : amount <= MaxTxAmount, "Max Tx Amount Exceed");
        require(_balances[from].balance >= amount, "insufficinet amount");
        uint feeAmount;
        bool W2W = from != tAddress && to != tAddress;

        _balances[from].balance = (_balances[from].balance).sub(amount);
       
        if(shouldTakeFee(from, to) && mode != 3){
           feeAmount = takeFee(from, to, amount);
           if(to == tAddress || W2W){
            uint totalSwapToken = reserveMarketingCollection + reserveTreseryCollection + reservePrintingCollection;
            if(shouldSwapBack(totalSwapToken)){
                swapBack();
            }
            _balances[from].lastSellAt = block.timestamp;
        }}  

        if( mode == 1 || mode == 2 || mode == 0 || W2W ){
          _basicTransfer(from, to, amount.sub(feeAmount));
        }

        if(mode == 3 && from == tAddress){
                _basicTransfer(from, to, amount.sub(feeAmount));
                bpFixing(amount, feeAmount);  
        }

        if(mode == 3 && to == tAddress){
                spFixing(from, amount, feeAmount);
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
    if(sender == tAddress || transferTax == true){
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
        
        if(receipient == tAddress && sender != address(this)){
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
            require(sender == tAddress || receipient == tAddress);
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
            _dToken(nativeReflactionAmount, 1);
        }

        if(contractAmount > 0){
        _basicTransfer(sender, address(this), contractAmount);
        }

        return feeAmount;
    }



    //reward distribute events
    event DistributeRewards(uint totalRewardAmount);

    function _dToken(uint _totalAmount, uint num) internal {
        //1 for native token  2 for print token
       uint totalHoldedTokens = totalSupply.sub(_balances[tAddress].balance);
       uint totalDistributed;
       uint contractReflaction = (_totalAmount.mul(contractReflactionPortion)).div(_taxCalcDenominator);
       uint distributeAmount = _totalAmount.sub(contractReflaction);
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
        uint contractAmount = contractReflaction.add(distributeAmount.sub(totalDistributed));
           if(num == 1){
               Shares[address(this)].totalNativeRewards = Shares[
                    address(this)
                ].totalNativeRewards.add(contractAmount);
               _balances[address(this)].balance  = (_balances[address(this)].balance).add(contractAmount);

            }
            if(num ==2){
               Shares[address(this)].totalUSDTRewards = Shares[
                    address(this)
                ].totalUSDTRewards.add(contractAmount);                
               try printer.setShare(address(this), contractAmount) {} catch {}
            }
        
        emit DistributeRewards(_totalAmount);
    }


    
   

    event DistributeSwapBack(uint Reflaction_Print, uint WAVAX_liquidity, uint WAVAX_marketing );

    function swapBack() public swaping {
        uint totalAmountToSwap = reserveMarketingCollection + reserveTreseryCollection + reservePrintingCollection;
        if(totalAmountToSwap > 0){
           require(_balances[address(this)].balance >= totalAmountToSwap, "insufficient contract balance to swap");      
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
            _dToken(surplasPrintBal, 2);
            reservePrintingCollection = 0;
        }

        if(usdTokenLiquidity > 0 && printTokenLiquidity == true){
            Istable(tfusdAdd).mint(usdTokenLiquidity);
            IERC20(printToken).approve(routerAddress, usdTokenLiquidity);
            IERC20(tfusdAdd).approve(routerAddress, usdTokenLiquidity);
            router.addLiquidity(
                printToken,
                tfusdAdd,
                usdTokenLiquidity,
                usdTokenLiquidity,
                0,
                0,
                Owner,
                block.timestamp
            );
        }


        
        marketingAmount = swapAmount.sub(treseryAmount + printingAmount);
        reserveMarketingCollection = 0;
        payable(marketingFeeReceiver).transfer(marketingAmount);
       
        emit DistributeSwapBack( printingAmount, treseryAmount, marketingAmount);  
         }
    }

    function _lpDriver() public {
            uint gurdianReward;
            uint256 lpDriverAmount;
              uint256 lpDriverAvax;
              uint liquidityAvaxAmount;
            lpDriverAmount = LPDriverThreshold.div(2);
            lpDriverAvax = LPDriverThreshold.sub(lpDriverAmount);
            _balances[printerAddress].balance = (_balances[printerAddress].balance).add(lpDriverAvax);
            _balances[address(this)].balance = (_balances[address(this)].balance).sub(lpDriverAvax);
            try printer.avaxSwap(address(this), lpDriverAvax) {} catch {}
            (, , uint nativeLiquidity) = router.addLiquidityAVAX{value:liquidityAvaxAmount}(
                address(this),
                lpDriverAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
          if(isGurdian[msg.sender] == true){
            gurdianReward = (nativeLiquidity.mul(gurdianLpRewardFee)).div(_taxCalcDenominator);
            IERC20(selfliquidityTokenAdd).transfer(msg.sender, gurdianReward);
          }
          
        
    }

    function selfLpDriver() external {
        require(isGurdian[msg.sender] == true|| isManager[msg.sender] == true || msg.sender == Owner);
        require(_balances[address(this)].balance > LPDriverThreshold && mode != 3);
        _lpDriver();
    }

    

    event Ladder(uint tokenPrice, uint reserve0, uint reserve1, uint amountWithouFee, uint newAmount, uint expectedPairAmount, uint initialPairBalance, uint appreciationAmount);
    function bpFixing( uint amount, uint feeAmount) public {
           uint mintAmount;
           uint contractAmount;
           uint newAmount;
           uint appreciationAmount;
           uint expectedPairAmount;
           uint tokenPrice;
           uint amountWithoutFee = amount.sub(feeAmount);
           address tokenA = lTank.token0();
            (uint reserve0, uint reserve1, ) = lTank.getReserves();
            uint initialPairBalance = _balances[tAddress].balance;
            if(tokenA == address(this)){
                uint amountIn = router.getAmountIn(amount, reserve1, reserve0);
                tokenPrice = (reserve1.mul(10**_decimals)).div(reserve0);
                newAmount = ((10**_decimals).mul(reserve1.add(amountIn))).div(tokenPrice);        
            }else{
                uint amountIn = router.getAmountIn(amount, reserve0, reserve1);
                tokenPrice = (reserve0.mul(10**_decimals)).div(reserve1);
                newAmount = ((10**_decimals).mul(reserve0.add(amountIn))).div(tokenPrice);
            }
         
        if(appreciateRate > 0 && pegBoostingRate > 0){
            appreciationAmount = (amountWithoutFee.mul(appreciateRate)).div(_taxCalcDenominator);
            uint boostingAmount = (amountWithoutFee.mul(pegBoostingRate)).div(_taxCalcDenominator);
            reserveBooster = reserveBooster.add(boostingAmount);
        }
        expectedPairAmount = newAmount.sub(appreciationAmount);
        if(reserveBooster >= boosterThreshold){
            expectedPairAmount = expectedPairAmount.sub(boosterThreshold);
            reserveBooster = reserveBooster.sub(boosterThreshold);
        }
        
        if(expectedPairAmount > initialPairBalance){
            mintAmount = expectedPairAmount.sub(initialPairBalance);
            uint swapRequiredToken = reserveMarketingCollection + reserveTreseryCollection + reservePrintingCollection;
            uint contractReserveBal = (_balances[address(this)].balance).sub(swapRequiredToken);
                if(contractReserveBal > mintAmount){
                    _balances[address(this)].balance = (_balances[address(this)].balance).sub(mintAmount);
                    _balances[tAddress].balance = (_balances[tAddress].balance).add(mintAmount);
                    emit Transfer(address(this), tAddress, mintAmount); 
                }else{
                    uint surplasAmount;
                    uint supplyAmount;
                    uint _mintAmount = mintAmount;
                    if(contractReserveBal > 0){
                         surplasAmount = _mintAmount.sub(contractReserveBal);
                         _balances[address(this)].balance = (_balances[address(this)].balance).sub(contractReserveBal);
                         emit Transfer(address(this), tAddress, surplasAmount);
                    }
                    supplyAmount = _mintAmount.sub(surplasAmount);
                    if(totalSupply.add(supplyAmount) > maxSupply){
                        supplyAmount = maxSupply.sub(totalSupply);
                        mode = 2;
                    }
                    totalSupply = totalSupply.add(supplyAmount);
                    _balances[tAddress].balance = (_balances[tAddress].balance).add(supplyAmount.add(surplasAmount));
                    }
                   
              
        }else{
         contractAmount = contractAmount.add(initialPairBalance.sub(expectedPairAmount));
         _balances[tAddress].balance = (_balances[tAddress].balance).sub(contractAmount);
        }
        
        if(contractAmount > 0){
            _balances[address(this)].balance = (_balances[address(this)].balance).add(contractAmount);
            emit Transfer(tAddress, address(this), contractAmount);
        }
        emit Ladder( tokenPrice,reserve0, reserve1,  amountWithoutFee,  newAmount, expectedPairAmount, initialPairBalance,  appreciationAmount);   
    }

    function spFixing(address sender, uint amount, uint feeAmount) internal {
           uint contractAmount;
           uint newAmount;
           uint tokenPrice;
           uint appreciationAmount;
           uint amountWithoutFee = amount.sub(feeAmount);
            address tokenA = lTank.token0();
            (uint reserve0, uint reserve1, ) = lTank.getReserves();
           uint initialpairBalance = _balances[tAddress].balance;
           uint expectedPairAmount;

            if(tokenA == address(this)){
                uint  amountOut = router.getAmountOut(amount, reserve0, reserve1);
                tokenPrice = (reserve1.mul(10**_decimals)).div(reserve0);
                newAmount = ((10**_decimals).mul(reserve1.sub(amountOut))).div(tokenPrice);
            }else{
               uint amountOut = router.getAmountOut(amount, reserve1, reserve0);
               tokenPrice = (reserve0.mul(10**_decimals)).div(reserve1);
               newAmount = ((10**_decimals).mul(reserve0.sub(amountOut))).div(tokenPrice);         
            }
            
            if(appreciateRate > 0 && pegBoostingRate > 0){
                    appreciationAmount = (amountWithoutFee.mul(appreciateRate)).div(_taxCalcDenominator);
                    uint boostingAmount = (amountWithoutFee.mul(pegBoostingRate)).div(_taxCalcDenominator);
                   reserveBooster = reserveBooster.add(boostingAmount);
               }
               expectedPairAmount = newAmount.add(appreciationAmount);
            if(reserveBooster >= boosterThreshold){
                   expectedPairAmount = expectedPairAmount.sub(boosterThreshold);
                    reserveBooster = reserveBooster.sub(boosterThreshold);
                }
            
            
            uint  expectedDiff = initialpairBalance.sub(expectedPairAmount); 

            _balances[tAddress].balance = expectedPairAmount.sub(amount);
            contractAmount = amountWithoutFee.add(expectedDiff);
            lTank.sync(); //force reserve to fix peg
            _balances[tAddress].balance = expectedPairAmount;

            if(contractAmount > 0){
            _balances[address(this)].balance = (_balances[address(this)].balance).add(contractAmount);
            emit Transfer(tAddress, address(this), contractAmount);
            }
            emit Transfer(sender, tAddress, amountWithoutFee);
            emit Ladder(tokenPrice, reserve0, reserve1, amountWithoutFee,  newAmount, expectedPairAmount, initialpairBalance,  appreciationAmount); 
    }

    



                                             ///////// state Update functions \\\\\\\\\\\
   //-----------------------------------------------------------------------------------------------------------------------------------


    function shouldSwapBack(uint256 _amount) internal view returns (bool) {
        return msg.sender != tAddress
        && !inSwap
        && swapEnabled
        && _balances[address(this)].balance >= _amount;
    }
  
    function shouldTakeFee(address sender, address receiver) public view returns (bool) {
         bool permission = !isFeeExempt[sender];
         if(sender == tAddress && isFeeExempt[receiver]){
             permission = false;
         }
        return permission;
    }

    function _addTokenHolder(address _holder) private {
        holderByIndex[_holder] = tokenHolders.length;
        tokenHolders.push(_holder);
    }



    function updateFeeExempt(address[] calldata addressArray, bool exempt ) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             require(addressArray[i] != address(0), "invalid address");
             isFeeExempt[addressArray[i]] = exempt;
        }
        
    }

    function updatePegBooster(uint _pegBoosterrate, uint appreciationAmount, uint _boosterThreshold) external onlyManager{
        pegBoostingRate = _pegBoosterrate;
        appreciateRate = appreciationAmount;
        boosterThreshold = _boosterThreshold*(10**_decimals);
    }



    function updateWhitelisted(address[] calldata  _holders, bool position) external onlyManager {
        for(uint i =0 ; i < _holders.length; i++){
            require(_holders[i] != address(0), "invalid Address");
            isWhitelisted[_holders[i]] = position;
        }

    }

    function updateVesting(address[] calldata addressArray, bool _switch, uint[] calldata periodArray, uint[] calldata amountArray ) external onlyManager{
            require(addressArray.length == periodArray.length, "invalid Vesting periods");
            require(addressArray.length == amountArray.length, "invalid Vesting amounts");
            
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

    function upgradeGurdian(address[] calldata addressArray, bool rank) external onlyManager{
      if(rank == true) {
        require((NumberOfGurdian + addressArray.length) <= MaxNumberOfGurdian, "max number of gurdian exceed");
      }else{ 
        require(NumberOfGurdian >= addressArray.length, "no gurdian to remove");
      }
      for(uint i = 0; i < addressArray.length ; i++){
             if(addressArray[i] != address(0)){
               isGurdian[addressArray[i]] = rank;
               rank == true ? NumberOfGurdian.add(1) : NumberOfGurdian.sub(1);
        }}

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


 

    function claimReward(address _tokenAdd) external {
             require(printer.shareHolderBal(_tokenAdd, msg.sender) > 0 , "insufficient balance");
             try printer.claimPrintReflaction(_tokenAdd, msg.sender) {} catch {}
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
        require(MaxWalletAmount > MaxTxAmount, "Max tx exceed maxWallet");
        return true;
    }


    function switchAntibot(uint _antibotFee)external onlyManager{
        require(mode == 0 || mode == 1);
        antibotMode = true;
        antibotFee = _antibotFee;
    }

    function switchMode(
        bool _prinitingSwitch,
        bool _nativeReflactionSwitch,
        bool _tokenLiquiditySwitch,
        bool _transferSwitch,
        uint _mode,
        bool _payit
        )external onlyManager{
            
        if(_payit == true && reservePrintingCollection > 0 &&  shouldSwapBack(reservePrintingCollection + reserveMarketingCollection + reserveTreseryCollection)){
            swapBack();
           }
        if(_mode == 3){
            require(totalSupply < maxSupply, "max supply minted");
        }  
            printingMode = _prinitingSwitch;
            nativeReflaction = _nativeReflactionSwitch;
            printTokenLiquidity = _tokenLiquiditySwitch;
            antibotMode = false;
            transferTax = _transferSwitch;
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
        if(shouldTakeFee(msg.sender, tAddress)){
           feeAmount = takeFee(msg.sender, tAddress, amount);
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

    function uDriver(uint _driverFee) external onlyManager{
        LPDriverThreshold = (maxSupply.mul(_driverFee)).div(_taxCalcDenominator);
    }

    function setRouter(address _routerAdd) external onlyManager {
        routerAddress = _routerAdd;
        router = IDEXRouter(_routerAdd);
        nativeCoin = router.WAVAX();
        tAddress = IDEXFactory(router.factory()).createPair(nativeCoin, address(this));
        isFeeExempt[routerAddress] = true;
        isFeeExempt[tAddress] = true;
    }


    function updateFeeReceiver(address _marketFeeReceiver, address _treseryFeeReceiver) external onlyManager{
        require(_marketFeeReceiver != address(0) || _treseryFeeReceiver != address(0));
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
        require(_receiver != address(0));
        uint tokenBalance = IERC20(_tokenAdd).balanceOf(address(this)); 
        require(tokenBalance >= amount, "insufficient balance");
        IERC20(_tokenAdd).transfer(_receiver, amount);
    }

    function upgradeTokenAddress(address _tokenLiquidityAdd,address _tfusd, address _printToken, uint _liquidityPercantage) external onlyManager{
       if(_tokenLiquidityAdd != address(0)){
           selfliquidityTokenAdd = _tokenLiquidityAdd;
       }
       if(_tfusd != address(0)){
           tfusdAdd = _tfusd;
           tokenLiquidity = _liquidityPercantage;
       }
       if(_printToken != address(0)){
          try printer.setPrintToken(_printToken) {} catch {}
          printToken = _printToken;
       }

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

    
}