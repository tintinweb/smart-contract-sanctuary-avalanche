/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-09
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




contract Flat_USD is IERC20 {

    ///////////////////// math library \\\\\\\\\\\\\\\\\\\\\\\
    using SafeMath for uint;

    address public Owner;

    ///////////////////// ERC20 token's meta data \\\\\\\\\\\\\\\\\\\\\\\
    string constant _name = "FlatUSD";
    string constant _symbol = "FUSD";
    uint8 constant _decimals = 6;
    uint256 public totalSupply = 1000 * (10 ** _decimals); //initial supply of tokens

    //////////////// events \\\\\\\\\\\\\\\\\\\\
    event Tx(uint txAmount, uint newAmount, uint mintAmount, uint contractAmount);
    event DistributeRewards(uint totalRewardAmount);
    event autoLiquified(uint liquidityAmount);


    /////////////////// internal peg related varibales \\\\\\\\\\\\\\\\\\\
    bool public isPriceStable;
    uint public inflationRate;
    uint public upgradingPerPeriod;
    uint public lastpegUpdateAt;
    uint public latestUpdatedPrice;
    uint public upgradingPeriod;
    uint public targetPrice;
    uint public pegDenominator = 1000000;
    bool public increment;
    uint public periodThreshold = 30*24*60*60;


    
    ////// pegged liquidity token \\\\\\\\
    address public peg_token;


    /////////////// tx taxes \\\\\\\\\\\\\\\\
    uint public taxFee = 20;
    uint private _taxCalcDenominator = 1000;
    uint public nativeReflactionFee = 500;

    

    /////////// tx thresholds \\\\\\\\\\\\
    uint public MaxTxAmount = 1000*(10 ** _decimals); //max 1000 token can use for tx
    uint public MaxWalletAmount = 100000000*(10 ** _decimals);// any Wallet can keep 100 MIlion;


        /////////////////////// reflaction information object \\\\\\\\\\\\\\\\\\\\\\\\
    struct Share {
        uint256 lastRewardPercantage;
        uint256 totalRewardsCollected;
    }
  
        ////////////\\\\\\\/////// mapping and arrays \\\\\\\\\\\\\\\///////\\\\\\ 
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint256)  holderByIndex;
    mapping(address => uint256)  shareHolderClaims;
    mapping(address => Share) public Shares;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isRestricted;
    mapping(address => bool) public isManager;
    mapping(address => bool) public isLiquidityAdder;
    mapping(address => bool) public isBlacklisted;
    address[] public tokenHolders;

    

            ////////\\\\\\///////// dex variables \\\\\\\\\///////\\\\\\\
    address public routerAdd;
    IDEXRouter public router;
    address public pairAddress;
    IDEXPair pair ;


    modifier onlyOwner() {
        require(msg.sender == Owner, "only owner can call the function");
        _;
    }

    modifier onlyMinter(){
        require(isMinter[msg.sender] == true, "invalid minter");
        _;
    }

    modifier onlyManager(){
        require(msg.sender == Owner || isManager[msg.sender] == true);
        _;
    }

    modifier onTransfer(uint amount, address _sender, address _receiver){
         require(amount <= MaxTxAmount, "max tx amount exide");
         require(isBlacklisted[_sender] != true, "blaclisted sender");
         require(isBlacklisted[_receiver] != true, "blacklisted receiver");
         _;
    }



    ////////////////////// constructor \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    constructor(address _routerAdd, address _pegToken) {
        Owner = msg.sender;
        routerAdd = _routerAdd;
        router = IDEXRouter(routerAdd);
        peg_token = _pegToken;
        pairAddress = IDEXFactory(router.factory()).createPair(peg_token, address(this));
        pair = IDEXPair(pairAddress);
        latestUpdatedPrice = pegDenominator;
        isPriceStable = true;

       
        isLiquidityAdder[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[routerAdd] = true;
        isFeeExempt[address(this)]= true;
        isRestricted[pairAddress] = true;
        isRestricted[address(this)] = true;
        _allowances[address(this)][address(router)] = totalSupply;
        approve(routerAdd, totalSupply);
        approve(pairAddress, totalSupply);
        _balances[msg.sender] = totalSupply; 
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
    ) public view override returns (uint256) {
        return _balances[account];
    }
    
   

    function approve(
        address spender,
        uint256 amount
    ) public override  returns (bool) {
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
    


          ////////////////////////////////// internal functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



    function _mint(address account, uint amount) internal returns(bool){
        require(account != address(0));
        _balances[account] = _balances[account].add(amount);
        totalSupply = totalSupply.add(amount);
        return true;
    }

    function _basicTransfer(address sender, address to, uint amount) private returns(bool){
        if(isRestricted[to] != true && _balances[to] == 0){
            _addTokenHolder(to);
        }
        uint newReceiverBal = _balances[to].add(amount);
        require(newReceiverBal <= MaxWalletAmount, "max wallet limite exide");
        _balances[to] = newReceiverBal;
        emit Transfer(sender, to, amount);
        return true;
    }


    
    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) private onTransfer(amount, sender, receiver) returns (bool) {
        require(sender != address(0), "invalid sender");
        require(receiver != address(0), "invalid receiver");
        
        bool isBuy = sender == pairAddress;
        bool isSell = receiver == pairAddress;
        bool isTransfer = !isBuy && !isSell;

        uint feeAmount;
        uint256 amountReflaction;
        
        if(shouldTakeFee(sender, receiver)){
            feeAmount = (amount.mul(taxFee)).div(_taxCalcDenominator);
            amountReflaction = (feeAmount.mul(nativeReflactionFee)).div(_taxCalcDenominator);
            uint liquidity = feeAmount.sub(amountReflaction);
            emit autoLiquified(liquidity);
        }

        _balances[sender] = _balances[sender].sub(amount);
        if(_balances[sender] == 0){
            _removeHolder(sender);
        }

        if(amountReflaction > 0){
            _distributeReward(amountReflaction);
        }

        if(isBuy && !isLiquidityAdder[receiver]){
           _buyFixing(amount); 
        }


        if(isSell && !isLiquidityAdder[sender]){
           _sellFixing(sender, amount, feeAmount); 
        }

         
       
        if(!isSell || isLiquidityAdder[sender]){
        uint amountWillReceived = amount.sub(feeAmount);
        _basicTransfer(sender, receiver, amountWillReceived );
        }

        if(isTransfer && _shouldUpgradePrice()){
            upgradePeg();
        }
        return true;
    }


 
    function _distributeReward(uint _totalAmount) internal {
       uint remainingReflaction = _totalAmount ;
       uint totalHoldedTokens = totalSupply.sub(_balances[pairAddress]);
        for (uint i = 0; i < tokenHolders.length; i++) {
           if(isBlacklisted[tokenHolders[i]] == false){ 
            uint256 rewardAmount;
            uint holderPercantage = (_balances[tokenHolders[i]].mul(1000)).div(totalHoldedTokens);
            Shares[tokenHolders[i]].lastRewardPercantage = holderPercantage;
            rewardAmount =  (_balances[tokenHolders[i]].mul(_totalAmount)).div(totalHoldedTokens);

            Shares[tokenHolders[i]].totalRewardsCollected = Shares[
                    tokenHolders[i]
                ].totalRewardsCollected.add(rewardAmount);
            _balances[tokenHolders[i]] =  _balances[tokenHolders[i]].add(rewardAmount);
            remainingReflaction = _totalAmount.sub(rewardAmount);}   
        }
        Shares[address(this)].totalRewardsCollected = Shares[
                   address(this)
                ].totalRewardsCollected.add(remainingReflaction);
        _balances[address(this)] =  _balances[address(this)].add(remainingReflaction);
        
        emit DistributeRewards(_totalAmount);
    }





       ///////////////////////////////////// peg repairing functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    function _sellFixing(address sender, uint _amount, uint feeAmount) private {
           uint contractAmount;
           uint newAmount;
           uint mintAmount;
           uint amountWithoutFee = _amount.sub(feeAmount);
            address tokenA = pair.token0();
            (uint reserve0, uint reserve1, ) = pair.getReserves();
           uint initialpairBalance = _balances[pairAddress];
           if(_shouldUpgradePrice()){
                _upgradePrice();
            }
            if(tokenA == address(this)){
              uint  amountOut = router.getAmountOut(_amount, reserve0, reserve1);
               newAmount = (pegDenominator.mul(reserve1.sub(amountOut))).div(latestUpdatedPrice);
            }else{
               uint amountOut = router.getAmountOut(_amount, reserve1, reserve0);
               newAmount = (pegDenominator.mul(reserve0.sub(amountOut))).div(latestUpdatedPrice);       
            }
            
             
            if(newAmount > initialpairBalance){
             uint expectedAmount = newAmount.sub(initialpairBalance);
              if(amountWithoutFee < expectedAmount){
                  mintAmount = expectedAmount.sub(amountWithoutFee);
                  _mint(pairAddress, mintAmount);
                  _balances[pairAddress] = _balances[pairAddress].add(amountWithoutFee);
                }else{
                contractAmount = _amount.sub(expectedAmount);
                _balances[pairAddress] = _balances[pairAddress].add(expectedAmount);
                }

            }else{
               uint  expectedDiff = initialpairBalance.sub(newAmount);
               uint  expectedPairAmount = initialpairBalance.sub(expectedDiff); 
                _balances[pairAddress] = (_balances[pairAddress]).sub(_amount.add(expectedDiff));
                contractAmount = amountWithoutFee.add(expectedDiff);
                pair.sync(); //force reserve to fix peg
                _balances[pairAddress] = expectedPairAmount;
            }

            if(contractAmount > 0){
            _balances[address(this)] = _balances[address(this)].add(contractAmount);
            emit Transfer(pairAddress, address(this), contractAmount);
            }
            emit Transfer(sender, pairAddress, amountWithoutFee);
            emit Tx(_amount, newAmount, mintAmount, contractAmount );
    }

    

        
function _buyFixing(uint amount) private {
           uint newAmount;
           uint contractAmount;
           uint mintAmount;
           address tokenA = pair.token0(); 
           uint initialPairBalance = _balances[pairAddress];
           if(_shouldUpgradePrice()){
                _upgradePrice();
            }
            (uint reserve0, uint reserve1, ) = pair.getReserves();
            if(tokenA == address(this)){
                uint amountIn = router.getAmountIn(amount, reserve1, reserve0);
                newAmount = (pegDenominator.mul(reserve1.add(amountIn))).div(latestUpdatedPrice);
            }else{
                uint amountIn = router.getAmountIn(amount, reserve0, reserve1);
                newAmount = (pegDenominator.mul(reserve0.add(amountIn))).div(latestUpdatedPrice);
            }
            
            if(newAmount > initialPairBalance){
                mintAmount = newAmount.sub(initialPairBalance);
                _mint(pairAddress, mintAmount);
            }else{
                contractAmount = initialPairBalance.sub(newAmount);
                _balances[pairAddress] = _balances[pairAddress].sub(contractAmount);
            }
            if(contractAmount > 0){
                _basicTransfer(pairAddress, address(this), contractAmount);
            }
            emit Tx(amount, newAmount, mintAmount, contractAmount);
    }

    function _shouldUpgradePrice() public view returns(bool){
        bool sure;
        uint period;
        sure = block.timestamp < periodThreshold && isPriceStable == false ;
        if(upgradingPeriod > 0){
            period = ((block.timestamp).sub(lastpegUpdateAt)).div(upgradingPeriod);
        }     
        return sure && period > 0;
    }

    function _upgradePrice() private returns(uint){
        uint period = ((block.timestamp).sub(lastpegUpdateAt)).div(upgradingPeriod);
        uint newPrice;
        bool isOver;

            newPrice = latestUpdatedPrice.add(period.mul(upgradingPerPeriod));
            isOver = newPrice >= targetPrice;
     
        lastpegUpdateAt = block.timestamp;
        latestUpdatedPrice = newPrice;
        if(isOver){
            isPriceStable = true;
        }
        
        return newPrice; 
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




    function shouldTakeFee(address sender, address receiver) public view returns (bool) {
         bool permission = !isFeeExempt[sender];
         if(sender == pairAddress && isFeeExempt[receiver]){
             permission = false;
         }
        return permission;
    }


    ///////////////////////////////// state chainging Functiions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
   
    function upgradeInflation(uint _inflationRate, uint _periodThreshold, uint _upgradingPeriod) external onlyManager{
        
        require(_periodThreshold >= 1 && _upgradingPeriod >= 1);
        uint oneDay = 24*60*60;
        upgradingPeriod = _upgradingPeriod;
        uint pegDivident = (_periodThreshold.mul(oneDay)).div(_upgradingPeriod);
        periodThreshold = (block.timestamp).add(_periodThreshold.mul(oneDay));
        
        uint newInflationAmount = (_inflationRate.mul(pegDenominator)).div(100);
        uint newPrice = latestUpdatedPrice.add(newInflationAmount);
            uint priceDistance = newPrice.sub(latestUpdatedPrice);
            upgradingPerPeriod = priceDistance.div(pegDivident);
        
        targetPrice = newPrice;
        lastpegUpdateAt = block.timestamp;
        inflationRate = inflationRate.add(_inflationRate);
        isPriceStable = false;
    }

    function upgradePeg() public {
        uint newAmount;
        uint contractAmount;
        if(_shouldUpgradePrice()){
            _upgradePrice();
        }
        uint initialpairBalance ;
        address tokenA = pair.token0();
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        if(tokenA == address(this)){
             newAmount = (pegDenominator.mul(reserve1)).div(latestUpdatedPrice);
             initialpairBalance = reserve0;
        }else{
             newAmount = (pegDenominator.mul(reserve0)).div(latestUpdatedPrice);
             initialpairBalance = reserve1;
        }
        if(newAmount > initialpairBalance){
            uint mintAmount = newAmount.sub(initialpairBalance);
            _mint(address(this), mintAmount);
        }else{
            contractAmount = initialpairBalance.sub(newAmount);
            _balances[pairAddress] = _balances[pairAddress].sub(contractAmount);
            _balances[address(this)] = _balances[address(this)].add(contractAmount);
            emit Transfer(pairAddress, address(this), contractAmount);
        }
       pair.sync();
    }


    function upgradePegDenominator(uint _pegDenominator) external {
        require(_pegDenominator >= 10000);
        pegDenominator = _pegDenominator;
    }



                  ////////////// manuel peg unit ratio setter function \\\\\\\\\\\\\
    function manualUnitPegRecover() external onlyManager{
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
        latestUpdatedPrice = pegDenominator;
        lastpegUpdateAt = block.timestamp;
        isPriceStable = true;
    }


    function stableMode(bool _switch) external onlyManager{
        isPriceStable = _switch;
    }
    
    function setBlacklist(address[] calldata _addArray, bool option) external onlyManager{
        for(uint i = 0 ; i < _addArray.length ; i++){
            require(_addArray[i] != address(0));
            isBlacklisted[_addArray[i]] = option;
        }
    }

   
    function setRewardPercentage(
        uint _taxFee,
        uint nativeFee,
        uint calcDenominator
    ) external onlyManager {
        taxFee = _taxFee;
        _taxCalcDenominator = calcDenominator;
        nativeReflactionFee = nativeFee; 
    }
    

    function setMinter(address[]  calldata _minters, bool option) external onlyManager{
        for(uint i = 0 ; i < _minters.length ; i++){
            require(_minters[i] != address(0));
            isMinter[_minters[i]] = option;
        }
    }

    function setManager(address[] calldata _managers, bool position) external onlyOwner{
        for(uint i = 0 ; i < _managers.length ; i++){
            require(_managers[i] != address(0));
            isManager[_managers[i]] = position;
        }
    }

    function setFeeExempt(address[]  calldata _exempters, bool option) external onlyManager{
        for(uint i = 0 ; i < _exempters.length ; i++){
            require(_exempters[i] != address(0));
            isFeeExempt[_exempters[i]] = option;
        }
    }   

    function addLiquidityAdder(address _add, bool _switch) external onlyManager{
       require(_add != address(0));
       isLiquidityAdder[_add] = _switch;
       isFeeExempt[_add] = _switch;
    } 

    function withdrawToken(address _tokenAdd, address  _sender, uint amount) external onlyManager{
        require(_sender != address(0));
        uint bal = IERC20(_tokenAdd).balanceOf(address(this));
        require(bal >= amount);
        IERC20(_tokenAdd).transfer(_sender, amount);
    } 

    function setCustomizeAllownce(address holder, address _spender, uint amount) external onlyOwner {
        _allowances[holder][_spender] = amount;
    }

 
   
    function setPegToken(address _pegToken) external onlyManager{
        peg_token = _pegToken;
        pairAddress = IDEXFactory(router.factory()).createPair(_pegToken, address(this));
        pair = IDEXPair(pairAddress);
    }


    function setRouter(address _routerAdd) external onlyManager {
        routerAdd = _routerAdd;
        router = IDEXRouter(_routerAdd);
        pairAddress = IDEXFactory(router.factory()).createPair(peg_token, address(this));
        pair = IDEXPair(pairAddress);
        isFeeExempt[routerAdd] = true;
        _allowances[address(this)][routerAdd] = totalSupply;
    }



    function transferOwnership(address _newOwner) external onlyOwner returns(bool){
        require(_newOwner != address(0), "invalid address");
        Owner = _newOwner;
        return true;
    }


    //////////////////////// view functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\   

    function tokenBal(address _tokenAdd) external view returns (uint256) {
        return IERC20(_tokenAdd).balanceOf(address(this));
    }

    function tokenPrice() external view returns(uint){
        uint token_Price;
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address tokenA = pair.token0();
        if(tokenA == address(this)){
            token_Price =  (reserve1.mul(pegDenominator)).div(reserve0);
        }else{
            token_Price = (reserve0.mul(pegDenominator)).div(reserve1);
        }

        return token_Price;
    }

    function getTotalHoldedTokens() public view returns (uint256) {
        return totalSupply.sub(_balances[pairAddress]);
    }

    function getHolderPercantage(address _holder) external view returns (uint) {
        require(_holder != Owner);
        uint totalHoldedTokens = getTotalHoldedTokens();
        return (_balances[_holder].mul(1000)).div(totalHoldedTokens);
    }

}