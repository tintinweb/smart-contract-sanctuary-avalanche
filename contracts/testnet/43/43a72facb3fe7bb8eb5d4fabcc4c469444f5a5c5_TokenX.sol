/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-03
*/

//it is a testing contract for print and reflaction token as tax fee



//SPDX-License-Identifier: UNDEFINED
 

pragma solidity 0.8.17;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

//interface for WAVAX
interface IWAVAX is IERC20{
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}












contract TokenX is IERC20 {

    address public Owner ;

    //ERC20 token's meta data
    string constant _name = "TokenX";
    string constant _symbol = "TX";
    uint8 constant _decimals = 6;


//token decimals 
    address public  WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c ;
    address public USDC = 0x5425890298aed601595a70AB815c96711a31Bc65;

    IERC20 printToken = IERC20(USDC);


 
  

    //token unique variables(fee calculating variables)
    uint public taxFee = 100;
    uint private _taxCalcDenominator = 1000;
    uint public nativeTokenFee = 200;
    uint private liquidityNativeTokenFee = 100;
    uint private totalDistributeWAVAXTokenFee = 700;
     uint public printTokenFee = 200;
    uint private liquidityWAVAXFee = 100;
    uint private marketingWAVAXFee = 400;

  
   
   //dex variables
   address public ROUTER = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
   IDEXRouter public router;
   address public pair;
 

    //token total supply 
    uint256 public _totalSupply = 10000*(10**_decimals);  //initial supply of tokens

    //balance and holder iteraton methods
    mapping(address => uint256) _balances;
    mapping(address=>mapping(address=>uint256))_allowances;

    //reward helpers
    address public MARKETINGADD = 0x3Caf97F5Bd858B0D6B8c2135BB7781319d6B91ae;
    uint256 public rewardDenominator = 1000;
   uint256 public printTokenDecimal = 6;


     //share properties for account holders
    struct Share {
        uint256 rewardPercantage;
        uint256 totalUSDTRewards;
        uint256 totalNativeRewards;
        uint256 nativebalance;
    }

    address[] private tokenHolders;
   mapping(address => uint256) private holderByIndex;
   mapping(address => uint256)private  shareHolderClaims;
   mapping(address => Share) public Shares;

  modifier onlyOwner(){
       require(msg.sender == Owner, "only owner can call the function");
       _;
  }

    constructor(){
        Owner = msg.sender;
        router  = IDEXRouter(0x2D99ABD9008Dc933ff5c0CD271B88309593aB921);
        pair = IDEXFactory(0xE4A575550C2b460d2307b82dCd7aFe84AD1484dd).createPair(WAVAX, address(this));
        _allowances[address(this)][ROUTER] = _totalSupply;
        WAVAX = router.WAVAX();
        
        approve(pair, _totalSupply);
        _balances[msg.sender] = _totalSupply;
       
    }

    //standard function of IERC20Metadata and IER20 interface
  function name() external   override pure returns (string memory){
      return _name;
  }
    function symbol() external pure override returns (string memory){
     return _symbol;
    }
     function decimals() external pure  override returns (uint8){
         return _decimals;
     }
function totalSupply() external view override returns (uint256){
    return _totalSupply;
}


function balanceOf(address account) external view override returns(uint256){
    return _balances[account];
}


function approve(address spender, uint256 amount) public  override returns(bool){
     _allowances[msg.sender][spender]= amount;
     emit Approval(msg.sender, spender, amount);
     return true;
}

function allowance(address holder, address spender) external view override returns(uint256){
    return _allowances[holder][spender];
}

function transfer(address to, uint256 amount) external  override returns(bool){
    return _transfer(msg.sender, to, amount);
}

function basicTransfer(address to, uint amount) external {
    require(to != address(0), "invalid address");
    _balances[msg.sender] -= amount;
    _balances[msg.sender] += amount;
}

function transferFrom(address from, address to , uint256 amount) external  override returns(bool){
    return _transfer(from,to, amount);
}



    event Tx(uint256 value);
      //internal functions 
     function _transfer(address sender, address receiver, uint256 amount) internal returns(bool){
         require(sender != address(0), "invalid sender");
         require(receiver != address(0), "invalid sender");
         _balances[sender] -= amount;

        uint feeAmount = 0;
        
         feeAmount = (amount*taxFee)/_taxCalcDenominator;
        uint amountWillReceived = amount - feeAmount;
        if(_balances[receiver] == 0){
            _addTokenHolder(receiver, amountWillReceived);
        }
        _updateTokenHolder(receiver, amountWillReceived);
        _balances[receiver] += amountWillReceived;

        // uint256 distributePrintToken = (taxForAmount*printTokenFee)/_taxCalcDenominator;
        uint256 distributeWAVAXToken = (feeAmount*totalDistributeWAVAXTokenFee)/_taxCalcDenominator;
       
          uint256 WAVAXAmount =  tokenToWAVAX(distributeWAVAXToken);
          if(printTokenFee > 0){
              uint256 WAVAXForPrintToken = WAVAXAmount*((printTokenFee*totalDistributeWAVAXTokenFee)/_taxCalcDenominator);
              _distributePrintToken(WAVAXForPrintToken);
          }

        uint256 WAVAXForMarketing = WAVAXAmount*((marketingWAVAXFee*totalDistributeWAVAXTokenFee)/_taxCalcDenominator);
        uint256 WAVAXForLiquidity = WAVAXAmount*((liquidityWAVAXFee*totalDistributeWAVAXTokenFee)/_taxCalcDenominator);
        uint256 LIQUIDITyNativeToken = (feeAmount*liquidityNativeTokenFee)/_taxCalcDenominator;
        
        IWAVAX(WAVAX).transfer(MARKETINGADD, WAVAXForMarketing);

        AddTokenLiquidity(WAVAXForLiquidity,LIQUIDITyNativeToken);


        if(nativeTokenFee >0){
              uint256 amounts =  (feeAmount*nativeTokenFee)/_taxCalcDenominator;
            uint256 rewardPerShare = amounts/rewardDenominator;
            uint256 totolHoldedTokens = getTotalHoldedTokens();
         for(uint i =0; i< tokenHolders.length; i++){
             uint256 holderPercantage = (Shares[tokenHolders[i]].nativebalance/totolHoldedTokens)/rewardDenominator;
             uint256 rewardAmount = holderPercantage*rewardPerShare;
             _balances[tokenHolders[i]] += rewardAmount;
             Shares[tokenHolders[i]].totalNativeRewards += rewardAmount;
             }
          }
          
              emit Tx(WAVAXAmount);
              return true;
     }

     //liquidity event
     event Liquified(uint amoun1, uint amount2, uint liquid); 

     function AddTokenLiquidity(uint256 WavaxAmount, uint256 tokenAmount) public {
         _allowances[address(this)][ROUTER] = tokenAmount;
        
           (uint amountA, uint amountB, uint liquidity) = router
            .addLiquidityAVAX{value: WavaxAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                Owner,
                block.timestamp
            );
             emit Liquified(amountA,amountB, liquidity );
     }

    // swap WAVAX event
    function tokenToWAVAX(uint256 _tokenAmount) internal returns(uint256) { 
        _allowances[address(this)][ROUTER] = _tokenAmount;
         uint256 balanceBefore = IWAVAX(WAVAX).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = IWAVAX(WAVAX).balanceOf(address(this)) - balanceBefore;
        return amount;

    }



    

     function _distributePrintToken(uint256 wavaxAmount) internal {
           uint256 printAmount = _tokenPrint(wavaxAmount);
           uint256 rewardPerShare = printAmount/rewardDenominator;
           uint256 totolHoldedTokens = getTotalHoldedTokens();
         for(uint i =0; i< tokenHolders.length; i++){
             uint256 holderPercantage = (Shares[tokenHolders[i]].nativebalance/totolHoldedTokens)/rewardDenominator;
             Shares[tokenHolders[i]].rewardPercantage = holderPercantage;
             uint256 rewardAmount = holderPercantage*rewardPerShare;
             printToken.transfer(tokenHolders[i], rewardAmount);
             Shares[tokenHolders[i]].totalUSDTRewards += rewardAmount;
         }
         
         }


     //printing events
     event Printed(uint256 _printAmount);

    function _tokenPrint(uint256 valueWAVAX)  public returns(uint256){
        uint256 balanceBefore = printToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(printToken);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value:valueWAVAX }(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = printToken.balanceOf(address(this)) - balanceBefore;

      emit Printed(amount);
      return amount;
    }
     
     function _addTokenHolder(address _holder, uint256 balance) internal {
           holderByIndex[_holder] = tokenHolders.length;
           tokenHolders.push(_holder);
           Shares[_holder].nativebalance = balance;
    }

    function _updateTokenHolder(address _holder, uint256 addedBal) internal {
        Shares[_holder].nativebalance += addedBal;
    }

    function _removeHolder(address _holder) internal {
        tokenHolders[holderByIndex[_holder]] = tokenHolders[tokenHolders.length -1];
        tokenHolders.pop();
        delete Shares[_holder];
    }

    function getTotalHoldedTokens() public view returns(uint256){
         uint256 totalCounted;
        for(uint i =0; i < tokenHolders.length; i++){
          totalCounted +=  Shares[tokenHolders[i]].nativebalance;
        }

        return totalCounted;
    }

      function setRewardPercentage(uint nativeFee, uint nativeLiq, uint printTokens, uint WAVAXLIQ, uint marketingLiq, uint calcDenominator) onlyOwner public returns(bool){
        _taxCalcDenominator = calcDenominator;
        nativeTokenFee = nativeFee;
        liquidityNativeTokenFee = nativeLiq;
        totalDistributeWAVAXTokenFee = printTokens + WAVAXLIQ + marketingLiq;
        printTokenFee = printTokens;
        liquidityWAVAXFee = WAVAXLIQ;
        marketingWAVAXFee = marketingLiq;
        return (_taxCalcDenominator == nativeFee + nativeLiq + printTokens + WAVAXLIQ + marketingLiq);
    }
    
          
   function PrintTokenBal(address _holder) public view returns(uint256){
       return IERC20(printToken).balanceOf(_holder);
   }

     


    function WAVAXBal(address _holder) public view  returns(uint256){
       return IWAVAX(WAVAX).balanceOf(_holder);
    }

    function TransferAVAX(address payable recipient, uint256 amount) internal onlyOwner {
        require(recipient != address(0), "Cannot withdraw the AVAX balance to the zero address");
        recipient.transfer(amount);
    }
    

}