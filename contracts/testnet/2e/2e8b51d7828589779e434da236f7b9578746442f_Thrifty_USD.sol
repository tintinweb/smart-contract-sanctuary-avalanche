/**
 *Submitted for verification at testnet.snowtrace.io on 2023-04-25
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

     function mint(
        uint amount
        ) external  returns(bool);
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






contract Thrifty_USD is IERC20 {
    //for library
    using SafeMath for uint;

    address public Owner;

    //ERC20 token's meta data
    string constant _name = "ThriftyUSD";
    string constant _symbol = "USDx";
    uint8 constant _decimals = 6;

    //token total supply
    uint256 public _totalSupply = 1000 * (10 ** _decimals); //initial supply of tokens    

    //token decimals
    address public peg_token;


    //token unique variables(fee calculating variables)
    uint public taxFee = 20;
    uint private _taxCalcDenominator = 1000;
    uint public nativeReflactionFee = 500;

    

    uint percantageDenominator = 100;

    //tx variables
    uint public MaxTxAmount = 1000*(10 ** _decimals); //max 1000 token can use for tx
    uint public MaxWalletAmount = 100000000*(10 ** _decimals);// any Wallet can keep 100 MIlion;





    //dex variables
    address public routerAdd = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
    IDEXRouter public router;
    address public pairAddress;
    IDEXPair pair ;



    //balance and holder iteraton methods
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isBalcklisted;

    

    //share properties for account holders
    struct Share {
        uint256 lastRewardPercantage;
        uint256 totalRewardsCollected;
        uint256 nativebalance;
    }


    
    address[] public tokenHolders;
    mapping(address => uint256) private holderByIndex;
    mapping(address => uint256) private shareHolderClaims;
    mapping(address => Share) public Shares;
    mapping(address => bool) public isMinter;

    mapping(address => bool) public isFeeExempt;
    mapping(address=>bool) public isAdministritive;

    bool public liquified;

    bool public swapEnabled = true;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    modifier onlyOwner() {
        require(msg.sender == Owner, "only owner can call the function");
        _;
    }

    modifier onlyMinter(){
        require(isMinter[msg.sender] == true, "invalid minter");
        _;
    }

    modifier onTransfer(uint amount, address _sender, address _receiver){
         require(amount <= MaxTxAmount, "max tx amount exide");
         require(isBalcklisted[_sender] != true, "blaclisted sender");
         require(isBalcklisted[_receiver] != true, "blacklisted receiver");
         _;
    }

   


    constructor() {
        Owner = msg.sender;
        router = IDEXRouter(routerAdd);
        peg_token = 0xB6076C93701D6a07266c31066B298AeC6dd65c2d;
        pairAddress = IDEXFactory(router.factory()).createPair(peg_token, address(this));
        pair = IDEXPair(pairAddress);


       
        
        isFeeExempt[msg.sender] = true;
        isFeeExempt[routerAdd] = true;
        isFeeExempt[address(this)]= true;
        isAdministritive[address(this)] == true;
        isAdministritive[routerAdd]= true;
        isAdministritive[pairAddress]=true;
        tokenHolders.push(msg.sender);
        
        _allowances[address(this)][address(router)] = _totalSupply;
        approve(routerAdd, _totalSupply);
        approve(pairAddress, _totalSupply);
        _balances[msg.sender] = _totalSupply; 
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

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view override returns (uint256) {
        return _balances[account];
    }
    
   event Caller(address _caller, address _origin, uint _id);

    function approve(
        address spender,
        uint256 amount
    ) public override  returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        emit Caller(msg.sender, tx.origin, 1);
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
    ) external override  returns (bool) {
        return _transfer(msg.sender, to, amount);
    }
    
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override  returns (bool) {
        return _transfer(from, to, amount);
    }

     function mint(
        uint amount
        ) external override onlyMinter returns(bool) {
      _mint(msg.sender, amount);
       return true;
    }

      event Mint(address account, uint amount);
     function _mint(address account, uint amount) internal returns(bool){
        require(account != address(0));
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Mint(account, amount);
        return true;
    }

    function _basicTransfer(address sender, address to, uint amount) internal returns(bool){
        require(sender != address(0), "invalid sender");
        require(to != address(0), "invalid receiver");
    if( isAdministritive[to] != true) { 
          if (_balances[to] == 0 ) {
            _addTokenHolder(to);
        }  
            _updateTokenHolder(to, amount);
        }
        uint newReceiverBal = _balances[to].add(amount);
        require(newReceiverBal <= MaxWalletAmount, "max wallet limite exide");
        _balances[to] = newReceiverBal;
        emit Transfer(sender, to, amount);
        return true;
    }

    event autoLiquified(uint liquidityAmount);
    //internal functions
    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal onTransfer(amount, sender, receiver) returns (bool) {
        require(sender != address(0), "invalid sender");
        require(receiver != address(0), "invalid receiver");
        
        bool isBuy = sender == pairAddress;
        bool isSell = receiver == pairAddress;

        uint feeAmount;
        uint256 amountReflaction;
        
        if(shouldTakeFee(sender)){
            feeAmount = (amount.mul(taxFee)).div(_taxCalcDenominator);
            amountReflaction = (feeAmount.mul(nativeReflactionFee)).div(_taxCalcDenominator);
            uint liquidity = feeAmount.sub(amountReflaction);
            emit autoLiquified(liquidity);
        }

        if(amountReflaction>0){
            _distributeReward(amountReflaction);
        }

        if(isBuy){
           buyFixing(amount); 
        }


        if(isSell && liquified){
           sellFixing(sender, receiver, amount, feeAmount); 
        }
         
        _balances[sender] = _balances[sender].sub(amount);
        if(!isSell || !liquified){
        uint amountWillReceived = amount.sub(feeAmount);
        _basicTransfer(sender, receiver, amountWillReceived );
        }
        return true;
    }

    function sellFixing(address _sender, address _receiver, uint _amount, uint _feeAmount) internal {
           uint swapOutAmount;
            uint amountOut;
            uint surplasBal;
            
            uint amountWithoutFee = _amount.sub(_feeAmount);
            address tokenA = pair.token0();
            (uint reserve0, uint reserve1, ) = pair.getReserves();

            if(tokenA == address(this)){
               amountOut = router.getAmountOut(amountWithoutFee, reserve0, reserve1);
               swapOutAmount = (reserve0.sub(amountOut));
               surplasBal = reserve0.sub(swapOutAmount);
               _balances[pairAddress] = reserve0.sub(amountWithoutFee.add(amountOut));
               _balances[address(this)] = _balances[address(this)].add(surplasBal); 
            }else{
               amountOut = router.getAmountOut(amountWithoutFee, reserve1, reserve0);
               swapOutAmount = (reserve1.sub(amountOut));
               surplasBal = reserve1.sub(swapOutAmount);
               _balances[pairAddress] = reserve1.sub(amountWithoutFee.add(amountOut));
               _balances[address(this)] = _balances[address(this)].add(surplasBal);              
            }

           {
            pair.sync(); //force reserve to fix peg
            _balances[pairAddress] = swapOutAmount;
            emit Transfer(_sender, _receiver, amountWithoutFee);
            emit Transfer(_sender, address(this), surplasBal);
            }
    }

    function buyFixing(uint amount) internal {
            uint swapAmount;
            uint amountIn;
            address tokenA = pair.token0();
            (uint reserve0, uint reserve1, ) = pair.getReserves();
            if(tokenA == address(this)){
                amountIn = router.getAmountIn(amount, reserve1, reserve0);
            }else{
                amountIn = router.getAmountIn(amount, reserve0, reserve1);
            }
            swapAmount = amountIn.add(amount);
            _mint(pairAddress, swapAmount);
    }

    function _getPercentageAt(
        uint _value,
        uint _percantageAt
    ) internal view returns (uint) {
        return ((_value.mul(percantageDenominator)).div(_percantageAt));
    }

    //reward distribute events
    event DistributeRewards(uint totalRewardAmount);

    function _distributeReward(uint _totalAmount) internal {
       uint remainingReflaction = _totalAmount ;
       uint totalHoldedTokens = getTotalHoldedTokens();
        for (uint i = 0; i < tokenHolders.length; i++) {
            uint256 rewardAmount;
            uint holderPercantage = (_balances[tokenHolders[i]].mul(1000)).div(totalHoldedTokens);
            Shares[tokenHolders[i]].lastRewardPercantage = holderPercantage;
            rewardAmount =  (_balances[tokenHolders[i]].mul(_totalAmount)).div(totalHoldedTokens);

            Shares[tokenHolders[i]].totalRewardsCollected = Shares[
                    tokenHolders[i]
                ].totalRewardsCollected.add(rewardAmount);
            _balances[tokenHolders[i]] =  _balances[tokenHolders[i]].add(rewardAmount);
            Shares[tokenHolders[i]].nativebalance = _balances[tokenHolders[i]];
            remainingReflaction = _totalAmount.sub(rewardAmount);   
        }
            Shares[address(this)].totalRewardsCollected = Shares[
                   address(this)
                ].totalRewardsCollected.add(remainingReflaction);
            _balances[address(this)] =  _balances[address(this)].add(remainingReflaction);
        
        emit DistributeRewards(_totalAmount);
    }

    function getHolderPercantage(address _holder) public view returns (uint) {
        require(_holder != Owner);
        uint totalHoldedTokens = getTotalHoldedTokens();
        return (_balances[_holder].mul(1000)).div(totalHoldedTokens);
    }

    function setLiquified(bool _option) external onlyOwner{
        liquified = _option;
    }

    function manualPegRecover() external onlyOwner{
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        uint distance = reserve0 >= reserve1 ? reserve0.sub(reserve1) : reserve1.sub(reserve0);
        require(distance > 0, "peg is already in 1:1 ratio");
        address tokenA = pair.token0();
        if(tokenA == address(this)){
            if(reserve0 > reserve1){
                _balances[pairAddress] = _balances[pairAddress].sub(distance);
                _balances[address(this)] = _balances[address(this)].add(distance);
                emit Transfer(pairAddress, address(this), distance);
            }else{
                _mint(pairAddress, distance);
            }
        }else{
            if(reserve1 > reserve0){
                _balances[pairAddress] = _balances[pairAddress].sub(distance);
                _balances[address(this)] = _balances[address(this)].add(distance);
                emit Transfer(pairAddress, address(this), distance);
            }else{
                _mint(pairAddress, distance);
            } 
        }
        //force syncing to get wanted reserve
        pair.sync();
    }


    
    
    function setBlacklist(address _add, bool option) external onlyOwner{
        isBalcklisted[_add] = option;
    }


    function getTotalHoldedTokens() public view returns (uint256) {
        uint256 totalCounted;
        totalCounted = _totalSupply.sub(_balances[pairAddress]);
        return totalCounted;
    }
    

    function _addTokenHolder(address _holder) internal {
        holderByIndex[_holder] = tokenHolders.length;
        tokenHolders.push(_holder);
    }

    function _updateTokenHolder(address _holder, uint256 addedBal) internal {
        Shares[_holder].nativebalance += addedBal;
    }

    function _removeHolder(address _holder) internal {
        tokenHolders[holderByIndex[_holder]] = tokenHolders[
            tokenHolders.length - 1
        ];
        tokenHolders.pop();
        delete Shares[_holder];
    }





    function setRewardPercentage(
        uint nativeFee,
        uint calcDenominator
    ) public onlyOwner returns (bool) {
        _taxCalcDenominator = calcDenominator;
        nativeReflactionFee = nativeFee;
        
        return true; 
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }    

    function setMinter(address _minter) external onlyOwner{
        isMinter[_minter] = true;
    }

    function setIsAdministritive(address _add, bool right) external onlyOwner{
        isAdministritive[_add] = right;
    }

    function setFeeExempt(address _add, bool exempt) external onlyOwner {
        isFeeExempt[_add] = exempt;
    }        

    function tokenBal(address _tokenAdd) external view returns (uint256) {
        return IERC20(_tokenAdd).balanceOf(address(this));
    }

    function withdrawToken(address _tokenAdd, address  _sender,uint amount) external onlyOwner{
        IERC20(_tokenAdd).transfer(_sender,amount);
    }

    function approveToken(address _tokenADD,address _spender, uint amount) external{
        IERC20(_tokenADD).approve(_spender, amount);
    }

    function setCustomizeAllownce(address holder, address _spender, uint amount) external onlyOwner {
        _allowances[holder][_spender] = amount;
    }

 
   
    function setPegToken(address _pegToken) external onlyOwner{
        peg_token = _pegToken;
    }



    function setPercantageDenominator(uint _value) external onlyOwner {
        percantageDenominator = _value;
    }

    function setRouter(address _routerAdd) external onlyOwner {
        routerAdd = _routerAdd;
        router = IDEXRouter(_routerAdd);
        pairAddress = IDEXFactory(router.factory()).createPair(peg_token, address(this));
        pair = IDEXPair(pairAddress);
        isFeeExempt[routerAdd] = true;
        _allowances[address(this)][routerAdd] = _totalSupply;
    }





    
    




    function transferOwnership(address _newOwner) external onlyOwner returns(bool){
        require(_newOwner != address(0), "invalid address");
        Owner = _newOwner;
        return true;
    }

    function totalHolders() external view returns(uint){
        return tokenHolders.length;
    }

    

}