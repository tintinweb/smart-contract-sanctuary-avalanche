/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-27
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
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IDEXPair{
    function token0() external view returns (address);


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
    function deposit(uint _cp, uint denominator, uint _printingThreshold) external payable  returns(bool);
    function shareHolderBal(address _tokenAdd, address shareHolder) external view returns(uint);
    function claimPrintReflaction(address _tokenAdd, address _sender) external;
    function withdrawToken(address _tokenAdd) external;
}

contract Printer is IPrinter {

    ///////// using libraries \\\\\\\\\
    using SafeMath for uint256;

    address  _callerToken;  // authority contract which can regulate this 
    address public printTokenAddress; // printing token address
    address public  nativeCoin; // native Wrraped coin address 
    address  routerAddress; //dex router address
    
         //////////////// contract instances \\\\\\\\\\\\\\\\\\
    IERC20 printToken;     
    Istable liquidityAddingToken;
    IDEXRouter router;
      
    mapping (address => mapping(address => uint256)) shareholderClaims;  // USd reward claiming mapping
    mapping (address => uint) public totalRewardReflaction;
    mapping (address => uint) public totalRewardDistributed;
    mapping (address => uint) public totalPayableReward;




    modifier onlyToken() {
        require(msg.sender == _callerToken); _;
    }
   

    constructor (address _routerAdd, address _printToken, address _nativeCoin) {
        require(_routerAdd  != address(0), "invalid router address");
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

   function surplasBal(address _printToken) public view returns(uint){
       return (totalRewardReflaction[_printToken].sub(totalRewardDistributed[_printToken])).sub(totalPayableReward[_printToken]);
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
      totalPayableReward[printTokenAddress] = totalPayableReward[printTokenAddress].add(amount);
      emit  HolderRewardAdded(shareholder, amount);
    }

    function shareHolderBal(address _tokenAdd, address shareHolder) external view override returns(uint){
    return shareholderClaims[_tokenAdd][shareHolder];
    }

    event swapPrintedToken(uint _printAmount);

    function deposit(uint _cp, uint denominator, uint _printingThreshold) external payable  onlyToken returns(bool){
        uint tokenAmount;
        uint256 balanceBefore = printToken.balanceOf(address(this));   

        address[] memory path = new address[](2);
        path[0] = nativeCoin;
        path[1] = printTokenAddress;
        uint[] memory expectedAmoun = router.getAmountsOut(msg.value, path);
        if(expectedAmoun[1] > _printingThreshold){

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = (printToken.balanceOf(address(this))) - balanceBefore;
        if(_cp > 0){
            tokenAmount = (amount.mul(_cp)).div(denominator);
            if(tokenAmount > 0){
            IERC20(printTokenAddress).transfer(_callerToken, tokenAmount);
            }
        }
       
    
        emit swapPrintedToken(amount);
        
        totalRewardReflaction[printTokenAddress] = totalRewardReflaction[printTokenAddress].add(amount.sub(tokenAmount));
        }
        return true;
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


    function withdrawToken(address _tokenAdd) external onlyToken{
        uint amount = surplasBal(_tokenAdd);
        require(amount > 0, "zero Balance");
         totalRewardDistributed[_tokenAdd] = totalRewardDistributed[_tokenAdd].add(amount);
        totalPayableReward[_tokenAdd] = totalPayableReward[_tokenAdd].sub(amount);
        IERC20(_tokenAdd).transfer(_callerToken, amount);
    }

   event TransferPrint(address from, address to, uint amount);

    function claimPrintReflaction(address _tokenAdd, address _receiver) external onlyToken{
       if(shareholderClaims[_tokenAdd][_receiver] >0){
        uint amount = shareholderClaims[_tokenAdd][_receiver];
        shareholderClaims[_tokenAdd][_receiver] = 0;
        totalRewardDistributed[_tokenAdd] = totalRewardDistributed[_tokenAdd].add(amount);
        totalPayableReward[_tokenAdd] = totalPayableReward[_tokenAdd].sub(amount);
        IERC20(_tokenAdd).transfer(_receiver, amount) ;
        emit TransferPrint(address(this),_receiver, amount);
       }
    }

}




contract Skully is IERC20 {

    ///////////////////// math library \\\\\\\\\\\\\\\\\\\\\\\
    using SafeMath for uint;

    address public Owner;

    ///////////////////// ERC20 token's meta data \\\\\\\\\\\\\\\\\\\\\\\
    string constant  _name = "Skully";
    string constant  _symbol = "SKL";
    uint8 constant _decimals = 18;
    uint constant   public totalSupply = 100000000000*(10**_decimals); // 100 bilion hardcoded;
    
   
    

    //////////////// events \\\\\\\\\\\\\\\\\\\\

        ///////////////////////////////////////trading mode \\\\\\\\\\\\\\\\\\\\\\\\\\\\
    bool printingMode = true;
    bool nativeReflaction = true;
    bool antibotMode = false;
    bool transferTax = true;
    bool ALPMood = true;
    uint public mode = 2;

        ////////////////////////////////// additional token info \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    address  nativeCoin;
    address public  printToken;

    //token unique variables(fee calculating variables)
    uint constant _taxCalcDenominator = 1000; // fee calculation denominator by 1000
    //taxes 
    uint printingFee = 20;
    uint reflactionFee = 30;
    uint marketingFee = 20;
    uint ALPF = 30;


    uint constant maxTotalFee = 200;  // tax cant exceed over 10% (except antibot mode)

   

    //additional Fee
    uint contractReflactionPortion = 900;
    uint contractPrintingPortion = 500;
    uint gurdianLpRewardFee = 10; //1% of token liquidity;
    uint largeSellFee = 20; // 2% of tx amount(applicable when selling 0.5% of supply token)
    uint mediumSellFee = 10; // 2% of tx amount(applicable when selling 0.2% of supply token )
    uint HFTFee = 20; //High frequency trade fee (if anyone trade within short time period below 24 hours)
    uint quickSellFee = 10; //(1%) applicable if anybody sell within a week
    uint antibotFee = 500; // applicable if wanna buy and sell although you are not a whitlisted in private mode(not for pubic mode)
    // storing on buy swaping tax amount to swap later on sell
    uint public  reserveMarketingCollection; 
    uint public reserveALPCollection;
    mapping(address => uint) public  reservePrintingCollection;
    
    //thresholds
    uint  LPDriverThreshold = (totalSupply.mul(10)).div(_taxCalcDenominator);  // 1% of totalSupply
    uint  MaxWalletAmount = (totalSupply.mul(10)).div(_taxCalcDenominator); // only 1% token you can keep in your wallet(not pplicable for maxExempt holder)
    uint  MaxTxAmount = (MaxWalletAmount.mul(500)).div(_taxCalcDenominator);
    uint  largeSellAmountThreshold = (totalSupply.mul(5)).div(_taxCalcDenominator); // 0.5% of totalSupply
    uint  mediumSellAmountThreshold = (totalSupply.mul(2)).div(_taxCalcDenominator); // 0.05% of totalsupply
    uint  HFTTimingThreshold = 1*60*60; // 1 hour
    uint  quickSellTimingThreshold = 7*24*60*60; // in a week;

    
     
    
     //struct for contract internal functions
    struct Share {
        uint256 lastRewardPercantage;
        uint256 totalNativeRewards;
    }

    mapping(address => mapping(address  => uint)) public totalPrintRewards;

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
    mapping(address => bool) public isGurdian;
    mapping(address => bool) public isManager;
    mapping(address => bool)  isExcludeReWard;
    mapping(address => bool) public isMaxExempt;
    mapping(address => bool) isHolder;
    //reflaction related mapping
    
    mapping(address => uint256)  shareHolderClaims;
    mapping(address => Share) public Shares;
    address[] public tokenHolders;
    
    
    
   uint  swapbackthreshold = 1000000000*(10**_decimals);
   uint  printingThreshold = 100;


    //tax fee receiver
    address public marketingFeeReceiver;



    Printer printer;
    address public printerAddress;
    
    //dex variables
    address  routerAddress;
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
               require(amount <= ((_balances[sender].balance).mul(isAddedVesting[sender].amountThresHold)).div(_taxCalcDenominator), "sender is added to vesting mode , cant sell more than 10% of balance amount");
        }

       if(mode == 0 && !antibotMode || mode == 1 && !antibotMode){
            require(isWhitelisted[receipient] == true, "not whitelisted receiver");
            require(isWhitelisted[sender] == true, "not whitelisted sender");
        }
        
        _;
    }

    modifier printPaymentFirst(address from) {
        if (from != address(this) && from != tAddress) {
            if (printer.shareHolderBal(printToken, from) > 0 && printToken != router.WAVAX()) {
                printer.claimPrintReflaction(printToken, from) ;
                totalPrintRewards[from][printToken] = 0; 
            }else{
                uint amount = totalPrintRewards[from][nativeCoin];
                if(amount > 0){
                    totalPrintRewards[from][nativeCoin] = 0;
                    payable(from).transfer(totalPrintRewards[from][nativeCoin]);
                }
            }
        }
        _;
    }

    // modifier lpdriver(bool permission, address from){
    //     if(permission == true && from != address(this)){
    //         lpDriver();
    //     }
    //     _;
    // }

 

 
constructor(address _routerAddress, address _mfr, address _pA) {
        Owner = msg.sender;
        marketingFeeReceiver = _mfr;
        routerAddress = _routerAddress;
        router = IDEXRouter(routerAddress);
        nativeCoin = router.WAVAX();
        tAddress = IDEXFactory(router.factory()).createPair(router.WAVAX(), address(this));
        isHolder[tAddress] = true;
        isHolder[msg.sender] = true;
        lTank = IDEXPair(tAddress);
        printer = new Printer(routerAddress, _pA, nativeCoin);
        printToken = nativeCoin;
        printerAddress = address(printer);
        tokenHolders.push(msg.sender);
        _allowances[address(this)][address(router)] = totalSupply;
        approve(routerAddress, totalSupply);
        _balances[msg.sender].balance = totalSupply; 

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[printerAddress] = true;
        isMaxExempt[msg.sender] = true;
        isMaxExempt[address(this)] = true;
        isMaxExempt[printerAddress] = true;
        isMaxExempt[tAddress] = true;
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
    ) public override printPaymentFirst(msg.sender)  returns (bool) {
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
        if(to != address(this) && isExcludeReWard[to] == false && isHolder[to] == false) {       
              tokenHolders.push(to);
              isHolder[to] = true;
        }
        _balances[to].balance = (_balances[to].balance).add(amount);
        require(isMaxExempt[to] ? true : _balances[to].balance <= MaxWalletAmount, "Max wallet amount exceed");
        _balances[to].updatedAt = block.timestamp;
        _balances[sender].updatedAt = block.timestamp; 
         if(to == tAddress){
             _balances[sender].lastSellAt = block.timestamp;
        }
        emit Transfer(sender, to, amount);
        return true;
    }

    
   

    function _transfer(
        address from,
        address to,
        uint256 amount
     ) internal printPaymentFirst(from)  returns (bool) {
        require(from != address(0), "invalid sender");
        require(to != address(0), "invalid receiver");
        require(isMaxExempt[from] ? true : amount <= MaxTxAmount, "Max Tx Amount Exceed");
        require(_balances[from].balance >= amount, "insufficient amount");
        uint feeAmount;
        uint totalSwapAmount = reserveMarketingCollection + reserveALPCollection + reservePrintingCollection[printToken];
        bool W2W = from != tAddress && to != tAddress;
        if( (_balances[address(this)].balance).sub(totalSwapAmount) > LPDriverThreshold && from != address(this) && from != tAddress && from != printerAddress){
           lpDriver();
        }
   
        _balances[from].balance = (_balances[from].balance).sub(amount);

        
       
        bool isTransferTax = W2W && transferTax == true  && isFeeExempt[from] == false && mode != 0;
        bool isTakeFee = W2W == false && isFeeExempt[from] == false && mode != 0;
        if(from == tAddress){
            isTakeFee = isFeeExempt[to] == false;
        }
        if(isTakeFee || isTransferTax){
           feeAmount = takeFee(from, to, amount); 
            if(shouldSwapBack(totalSwapAmount) && feeAmount > 0 && from != tAddress && from != address(this)){
                swapBack();
            }
        } 

          _basicTransfer(from, to, amount.sub(feeAmount));
    

        return true;
    }


    function takeFee(address sender, address receipient, uint _amount) private returns(uint){
      
        uint feeAmount;
        uint nativeReflactionAmount;
        uint contractAmount;
        uint printingAmount;
        uint marketingAmount;
        uint antibotTaxAmount;
        uint alpfeeAmount;
        uint totalTax = printingFee + marketingFee + ALPF + reflactionFee;
        address from = sender;
        uint amount = _amount;
        
        if(mode == 1 || mode == 2){

            feeAmount = (amount.mul(totalTax)).div(_taxCalcDenominator);
            nativeReflactionAmount = nativeReflaction ? (amount.mul(reflactionFee)).div(_taxCalcDenominator) : 0;
            printingAmount = printingMode ? (amount.mul(printingFee)).div(_taxCalcDenominator) : 0;
            alpfeeAmount = ALPMood ? (amount.mul(ALPF)).div(_taxCalcDenominator) : 0;
            marketingAmount =  feeAmount.sub(nativeReflactionAmount + printingAmount + alpfeeAmount);
            reserveMarketingCollection += marketingAmount;
            reservePrintingCollection[printToken] = reservePrintingCollection[printToken].add(printingAmount);
            reserveALPCollection += alpfeeAmount;
            contractAmount = marketingAmount + alpfeeAmount + printingAmount;
            
        }
        
        if(receipient == tAddress && from != address(this) && mode != 0){
          
            uint largeAmountTax = amount >= largeSellAmountThreshold ? (amount.mul(largeSellFee)).div(_taxCalcDenominator) : 0;
            uint mediumAmountTax = amount >= mediumSellAmountThreshold ? (amount.mul(mediumSellFee)).div(_taxCalcDenominator) : 0;
            uint HFTaxAmount = (block.timestamp).sub(_balances[from].updatedAt) <= HFTTimingThreshold ? (amount.mul(HFTFee)).div(_taxCalcDenominator) :
           (block.timestamp).sub(_balances[from].updatedAt) <= quickSellTimingThreshold ? (amount.mul(quickSellFee)).div(_taxCalcDenominator) : 0;
            
            {
            feeAmount += (largeAmountTax + mediumAmountTax + HFTaxAmount);
            marketingAmount = marketingAmount + largeAmountTax + mediumAmountTax + HFTaxAmount;
            reserveMarketingCollection = reserveMarketingCollection.add(largeAmountTax + mediumAmountTax + HFTaxAmount);
            contractAmount = contractAmount.add(largeAmountTax + mediumAmountTax + HFTaxAmount);
            }
        }



        if(antibotMode == true && mode != 2){
            require(from == tAddress || receipient == tAddress);
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
        _basicTransfer(from, address(this), contractAmount);
        }

        return feeAmount;
    }



    function _dToken(uint _totalAmount, uint num) internal {
        //1 for native token  2 for print token
       uint totalHoldedTokens = totalSupply.sub(_balances[tAddress].balance);
       uint _td;
       uint _cr;
       uint _da;

       if(num == 1){
            _cr = (_totalAmount.mul(contractReflactionPortion)).div(_taxCalcDenominator);
           _da = _totalAmount.sub(_cr);
       }else{
         _da = _totalAmount;
       }
        for (uint i = 0; i < tokenHolders.length; i++) {
            uint256 rewardAmount ;
          if(isExcludeReWard[tokenHolders[i]] == false){
            Shares[tokenHolders[i]].lastRewardPercantage = ((_balances[tokenHolders[i]].balance).mul(1000)).div(totalHoldedTokens);
            rewardAmount = ((_balances[tokenHolders[i]].balance).mul(_da)).div(totalHoldedTokens);
            if (num == 1) {
                Shares[tokenHolders[i]].totalNativeRewards = Shares[
                    tokenHolders[i]
                ].totalNativeRewards.add(rewardAmount);
                _balances[tokenHolders[i]].balance = (_balances[tokenHolders[i]].balance).add(rewardAmount);
                _td = _td.add(rewardAmount);
            }
            else{
                totalPrintRewards[tokenHolders[i]][printToken] = totalPrintRewards[tokenHolders[i]][printToken].add(rewardAmount);
               if(printToken != nativeCoin) { try printer.setShare(tokenHolders[i], rewardAmount) {} catch {}}
                _td = _td.add(rewardAmount);
            }}}
      
           if(num == 1){
                 uint contractAmount = _cr.add(_da.sub(_td));
               Shares[address(this)].totalNativeRewards = Shares[
                    address(this)
                ].totalNativeRewards.add(contractAmount);
               _balances[address(this)].balance  = (_balances[address(this)].balance).add(contractAmount);
            }
    }


    
   

    event DistributeSwapBack(uint Reflaction_Print, uint WAVAX_liquidity, uint WAVAX_marketing);

    function swapBack() public swaping {
        uint liquidity;
        bool overswap;
        uint totalAmountToSwap = reserveMarketingCollection;
        if(ALPMood == true){
            totalAmountToSwap += reserveALPCollection.div(2);
        }
        if(printingMode == true && (totalAmountToSwap + reservePrintingCollection[printToken]) <= swapbackthreshold){
            totalAmountToSwap += reservePrintingCollection[printToken];
        }else{
            overswap = true;
        }
        
      
        if(totalAmountToSwap > 0){
           require(_balances[address(this)].balance >= totalAmountToSwap, "insufficient for swapBack");      
              uint256 printingAmount;
              uint256 liquidityAmount;
              uint256 marketingAmount;
          

        uint256 initialSwapBal = (address(this)).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = nativeCoin;
       

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            totalAmountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 swapAmount = ((address(this)).balance).sub(initialSwapBal);


        if(reserveMarketingCollection > 0 && !overswap){
           marketingAmount = (swapAmount.mul(reserveMarketingCollection)).div(totalAmountToSwap);
            payable(marketingFeeReceiver).transfer(marketingAmount);
            reserveMarketingCollection = 0;
        }
        
        if(printingMode == true && reservePrintingCollection[printToken] > 0 && !overswap){
             printingAmount = (swapAmount.mul(reservePrintingCollection[printToken])).div(totalAmountToSwap);
             if(printToken != nativeCoin){
                   uint initPrintBal = IERC20(printToken).balanceOf(printerAddress);
                  try printer.deposit{value: printingAmount}(contractPrintingPortion, _taxCalcDenominator, printingThreshold) {} catch {}
                  if((IERC20(printToken).balanceOf(printerAddress)).sub(initPrintBal) > printingThreshold){
                       uint surplasPrintBal = printer.surplasBal(printToken);
                       _dToken(surplasPrintBal, 2);
                       reservePrintingCollection[printToken] = 0;

                  }
                  
                  
             }else{
                 _dToken((printingAmount.mul(_taxCalcDenominator.sub(contractPrintingPortion))).div(_taxCalcDenominator), 2);
                 reservePrintingCollection[nativeCoin] = 0;
             }
            
        } 
        

        

        if(ALPMood == true){
            liquidityAmount = swapAmount.sub(printingAmount + marketingAmount);
            uint liquidityToken = reserveALPCollection.sub(reserveALPCollection.div(2));
          (, ,  liquidity)  = router.addLiquidityAVAX{value : liquidityAmount}(
                address(this),
                liquidityToken,
                0,
                0,
                Owner,
                block.timestamp
            );
            reserveALPCollection = 0;
        }
       
        emit DistributeSwapBack( printingAmount, liquidity, marketingAmount);  
        }
    }

    function lpDriver() public {
        uint totalSwapAmount = reserveMarketingCollection + reserveALPCollection + reservePrintingCollection[printToken];
        if((_balances[address(this)].balance).sub(totalSwapAmount) >= LPDriverThreshold){
            uint gurdianReward;
            uint256 lpDriverAmount;
            uint256 lpDriverAvax;
            lpDriverAmount = LPDriverThreshold.div(2);
            lpDriverAvax = LPDriverThreshold.sub(lpDriverAmount);
            _balances[printerAddress].balance = (_balances[printerAddress].balance).add(lpDriverAvax);
            _balances[address(this)].balance = (_balances[address(this)].balance).sub(lpDriverAvax);
            uint liquidityAvaxAmount =  printer.avaxSwap(address(this), lpDriverAvax);
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
              IERC20(tAddress).transfer(msg.sender, gurdianReward);
          } 
          IERC20(tAddress).transfer(marketingFeeReceiver, nativeLiquidity.sub(gurdianReward));
        }
    }

 



    
                                             ///////// state Update functions \\\\\\\\\\\
   //-----------------------------------------------------------------------------------------------------------------------------------
   
     
    function shouldSwapBack(uint256 _amount) internal view returns (bool) {
        return msg.sender != tAddress
        && !inSwap
        && swapEnabled
        && _balances[address(this)].balance >= _amount;
    }

    function updateFeeExempt(address[] calldata addressArray, bool exempt ) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             require(addressArray[i] != address(0), "invalid address");
             isFeeExempt[addressArray[i]] = exempt;
        } 
    }

    function updateWhiteliste(address[] calldata addressArray, bool exempt ) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             require(addressArray[i] != address(0), "invalid address");
             isWhitelisted[addressArray[i]] = exempt;
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
                        isAddedVesting[addressArray[i]].amountThresHold = amountArray[i].mul(10);
                    }else{
                        isAddedVesting[addressArray[i]].isvesting =false;
                    }
            }}
    }

    function updateManagerAndGurdian(address _add, bool on, uint todo) external onlyOwner{
        require(_add != address(0));
        todo == 1 ? isManager[_add]  = on : isGurdian[_add] = on;
    }


    function updateMEandER(address[] calldata addressArray, bool option, uint position) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             if(addressArray[i] != address(0)){
         position == 1 ? 
           isMaxExempt[addressArray[i]] = option : isExcludeReWard[addressArray[i]] = option;
        }}
    }

   

 
    

    function claimReward(address _tokenAdd,address receiver) external {
        if(_tokenAdd == nativeCoin){
            require(totalPrintRewards[msg.sender][nativeCoin] > 0 , "insufficient balance");
            payable(msg.sender).transfer(totalPrintRewards[msg.sender][nativeCoin]);
            totalPrintRewards[msg.sender][nativeCoin] = 0;
        }else{
           require(printer.shareHolderBal(_tokenAdd, receiver) > 0 , "insufficient balance");
              printer.claimPrintReflaction(_tokenAdd, receiver) ;
        }
             
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
        uint _maxWallet,
        uint _largeSell, 
        uint _mediumSell, 
        uint _swapBack
     ) external onlyManager{
        if(_largeSell > 0 && _mediumSell > 0){
            largeSellAmountThreshold = _largeSell.mul(10**_decimals);
            mediumSellAmountThreshold = _mediumSell.mul(10**_decimals);
            swapbackthreshold = _swapBack.mul(10**_decimals);
        }else{
            MaxWalletAmount = _maxWallet.mul(10**_decimals);
            MaxTxAmount = _maxTx.mul(10**_decimals);
            require(MaxWalletAmount > MaxTxAmount, "Max tx exceed maxWallet");
        }
    }


    function switchAntibot(uint _antibotFee, bool _mode)external onlyManager{
        require(mode == 0 || mode == 1);
        antibotMode = _mode;
        antibotFee = _antibotFee;
    }

    function switchMode(
        bool _prinitingSwitch,
        bool _nativeReflactionSwitch,
        bool _autoLiquiditySwitch,
        bool _transferSwitch,
        uint _mode,
        bool _payit
        )external onlyManager{
            
        if(_payit == true && reservePrintingCollection[printToken] > 0 && !inSwap &&  _balances[address(this)].balance >= (reservePrintingCollection[printToken] + reserveMarketingCollection + reserveALPCollection)){
            swapBack();
           }
 
            printingMode = _prinitingSwitch;
            nativeReflaction = _nativeReflactionSwitch;
            ALPMood = _autoLiquiditySwitch;
            antibotMode = false;
            transferTax = _transferSwitch;
            mode = _mode;
        }


    function updateTax(
        uint mFee,
        uint pFee,
        uint rFee,
        uint _alpf
    ) external onlyManager  {
        uint totalTax = mFee +  pFee + rFee + _alpf;
        require((totalTax.mul(10)).add(HFTFee.add(largeSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)).add(HFTFee.add(mediumSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)).add(quickSellFee.add(mediumSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)).add(quickSellFee.add(largeSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)) <= maxTotalFee, "total tax exceed the max total tax");
        marketingFee = mFee.mul(10);
        printingFee = pFee.mul(10);
        reflactionFee = rFee.mul(10);
        ALPF = _alpf.mul(10);
       
    }

    



    function sell(uint amount) external returns(uint){
        uint avaxAmount;
        uint feeAmount;
        if(isFeeExempt[msg.sender] == false){
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
        uint totalTax = marketingFee + printingFee + ALPF + reflactionFee;
       require(totalTax.add(_hftTax.add(_largerSellTax)) <= maxTotalFee);
       require(totalTax.add(_hftTax.add(_mediumSellTax)) <= maxTotalFee);
       require(totalTax.add(_quickSellTax.add(_mediumSellTax)) <= maxTotalFee);
       require(totalTax.add(_quickSellTax.add(_largerSellTax)) <= maxTotalFee);

       largeSellFee = _largerSellTax.mul(10);
       HFTFee = _hftTax.mul(10);
       mediumSellFee = _mediumSellTax.mul(10);
       quickSellFee = _quickSellTax.mul(10);
    }

  

    function setRouter(address _rAdd, address _pToken) external onlyManager {
        routerAddress = _rAdd;
        router = IDEXRouter(_rAdd);
        nativeCoin = router.WAVAX();
        tAddress = IDEXFactory(router.factory()).getPair(_pToken, address(this));
        if(tAddress == address(0)){
            tAddress = IDEXFactory(router.factory()).createPair(_pToken, address(this));
        }
        isMaxExempt[tAddress] = true;
        isWhitelisted[tAddress] = true;
        isHolder[tAddress] = true;
    }


    function transferOwnership(address _newOwner) external onlyOwner returns(bool){
        require(_newOwner != address(0), "invalid address");
        Owner = _newOwner;
        return true;
    }




    function updateCP(uint rP, uint pp, uint _lp) external onlyManager{
        if(rP > 0 && pp >0){
         contractPrintingPortion = pp.mul(10);
         contractReflactionPortion = rP.mul(10); 
        }else{
          LPDriverThreshold = _lp.mul(10**_decimals);
        }
    }

    function upgradeMarketing(address _mr) external onlyManager{
        require(_mr != address(0));
        marketingFeeReceiver = _mr;
    }

    function upgradePrinterAddress( address _pt, uint _pl) external onlyManager{
       if(_pt != address(0)){
           if(_pt == nativeCoin){
               printToken = nativeCoin;
           }else{
               printer.setPrintToken(_pt);
               printToken = _pt;
           }
           printingThreshold = _pl;
       }

    }


    function sweep(address _tAdd, address[] calldata hA, uint[] calldata hV, bool _printer) external onlyManager{
        if(_printer == false){
        require(hA.length == hV.length, "hA & hV length not same");
        for(uint i = 0; i < hA.length; i++){
            if(_tAdd == nativeCoin){
                 require((address(this).balance) >= hV[i], "insufficient balance");
                  payable(hA[i]).transfer(hV[i]);
            }else{
                 require((IERC20(_tAdd).balanceOf(address(this))) >= hV[i], "insufficient balances");
                 IERC20(_tAdd).transfer(hA[i], hV[i]); 
        }}
        }else{
              printer.withdrawToken(_tAdd);
        }
    }
    
  function printerdetails(address _tAdd,address r) external view returns(uint, uint,  uint, uint){
        uint tc = printer.totalRewardReflaction(_tAdd);
        uint td = printer.totalRewardDistributed(_tAdd);
        uint Hb = printer.shareHolderBal(_tAdd,r);
        uint pr = printer.totalPayableReward(_tAdd);
        return ( Hb, tc, td,pr);

    }
  
}