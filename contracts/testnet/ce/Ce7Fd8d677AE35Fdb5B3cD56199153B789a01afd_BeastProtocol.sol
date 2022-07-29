/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-28
*/

// File: contracts/BEASTv2.sol

//SPDX-License-Identifier: MIT
/* 

 */
// o/
pragma solidity 0.8.15;
//interfaces
interface IPancakeV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IPancakeV2Router02 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// contracts
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
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
    function getTime() public view returns (uint) {
        return block.timestamp;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
}
contract BeastProtocol is ERC20, Ownable {
//custom
    IPancakeV2Router02 public pancakeV2Router;
//bool
    bool public sendToMarketing = true;
    bool public sendToFund = true;
    bool public sendToCompany = true;
    bool public sendToLiquidity = true;
    bool public limitSells = true;
    bool public limitBuys = true;
    bool public feeStatus = true;
    bool public buyFeeStatus = true;
    bool public sellFeeStatus = true;
    bool public maxWallet = true;
    bool public marketActive;
//address
    address public pancakeV2Pair;
    address public marketingAddress = 0x38bc3778BC4C2780D4A72DD4E3a16980746979B4;
    address public companyAddress = 0x118dd27621157767Cd7C1138B54Ef05E19B4E55F;
    address public fundAddress = 0x20DdD59b4F2Fc1E6C0A075D01a56D604372fE28F;
    address public liquidityAddress = 0xf8bEF1b1a20E502e0Ee3359cf74E4f338aa926C7;
//uint
    uint public buyMarketingFee = 200;
    uint public sellMarketingFee = 400;
    uint public buyCompanyFee = 75;
    uint public sellCompanyFee = 100;
    uint public buyLiquidityFee = 300;
    uint public sellLiquidityFee = 400;
    uint public buyFundFee = 425;
    uint public sellFundFee = 600;
    uint public totalBuyFee = buyMarketingFee + buyCompanyFee + buyLiquidityFee + buyFundFee;
    uint public totalSellFee = sellMarketingFee + sellCompanyFee + sellLiquidityFee + sellFundFee;
    uint public maxBuyTxAmount; // 1% tot supply (constructor)
    uint public maxSellTxAmount;// 1% tot supply (constructor)
    uint public maxWalletAmount; // 1% supply (constructor)
    uint public minimumTokensBeforeSend = 7_500 * 10 ** decimals();
    uint private startTimeForSwap;
    uint private marketActiveAt;
    mapping (address => bool) public excludedFromMaxWallet;
    event ExcludedFromMaxWalletChanged(address indexed user, bool state);
    event MaxWalletChanged(bool state, uint amount);
//struct
    struct userData {uint lastBuyTime;}
//mapping
    mapping (address => bool) public permissionToMessage;
    mapping (address => bool) public premarketUser;
    mapping (address => bool) public VestedUser;
    mapping (address => bool) public excludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => userData) public userLastTradeData;
//events
    event FundFeeCollected(uint amount);
    event MarketingFeeCollected(uint amount);
    event CompanyFeeCollected(uint amount);
    event LiquidityFeeCollected(uint amount);
    event PancakeRouterUpdated(address indexed newAddress, address indexed newPair);
    event PancakePairUpdated(address indexed newAddress, address indexed newPair);
    event TokenRemovedFromContract(address indexed tokenAddress, uint amount);
    event BnbRemovedFromContract(uint amount);
    event MarketStatusChanged(bool status, uint date);
    event LimitSellChanged(bool status);
    event LimitBuyChanged(bool status);
    event MinimumWeiChanged(uint amount);
    event MaxSellChanged(uint amount);
    event MaxBuyChanged(uint amount);
    event FeesChanged(uint buyLiquidityFee, uint buyMarketingFee, uint buyCompanyFee,
                      uint sellLiquidityFee, uint sellMarketingFee, uint sellCompanyFee);
    event FeesAddressesChanged(address marketing, address fund, address dev, address liquidity);
    event FeesStatusChanged(bool feesActive, bool buy, bool sell);
    event MinimumTokensBeforeSendChanged(uint amount);
    event PremarketUserChanged(bool status, address indexed user);
    event ExcludeFromFeesChanged(bool status, address indexed user);
    event AutomatedMarketMakerPairsChanged(bool status, address indexed target);
    event EditPowerUser(address indexed user, bool status);
// constructor
    constructor() ERC20("Beast Protocol", "BEAST") {
        uint total_supply = 75_000_000 * 10 ** decimals();
        // set gvars, change this to mainnet traderjoe router 
        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0x3705aBF712ccD4fc56Ee76f0BD3009FD4013ad75);
        pancakeV2Router = _pancakeV2Router;
        maxSellTxAmount = total_supply / 100; // 1% supply
        maxBuyTxAmount = total_supply / 100; // 1% supply
        maxWalletAmount = total_supply * 12 / 1000; // 1.2% supply
        //spawn pair
        pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
        .createPair(address(this), _pancakeV2Router.WAVAX());
        // mappings
        excludedFromFees[address(this)] = true;
        excludedFromFees[owner()] = true;
        excludedFromFees[companyAddress] = true;
        excludedFromFees[fundAddress] = true;
        excludedFromFees[marketingAddress] = true;
        excludedFromFees[liquidityAddress] = true;
        excludedFromMaxWallet[address(this)] = true;
        excludedFromMaxWallet[owner()] = true;
        excludedFromMaxWallet[companyAddress] = true;
        excludedFromMaxWallet[fundAddress] = true;
        excludedFromMaxWallet[marketingAddress] = true;
        excludedFromMaxWallet[liquidityAddress] = true;
        excludedFromMaxWallet[pancakeV2Pair] = true;
        premarketUser[owner()] = true;
        automatedMarketMakerPairs[pancakeV2Pair] = true;
        _mint(owner(), total_supply); // mint is used only here
    }
    receive() external payable {}
    function updatePancakeV2Router(address newAddress, bool _createPair, address _pair) external onlyOwner {
        pancakeV2Router = IPancakeV2Router02(newAddress);
        if(_createPair) {
            address _pancakeV2Pair = IPancakeV2Factory(pancakeV2Router.factory())
                .createPair(address(this), pancakeV2Router.WAVAX());
            pancakeV2Pair = _pancakeV2Pair;
            emit PancakePairUpdated(newAddress,pancakeV2Pair);
        } else {
            pancakeV2Pair = _pair;
        }
        emit PancakeRouterUpdated(newAddress,pancakeV2Pair);
    }
    // to take leftover(tokens) from contract
    function transferToken(address _token, address _to, uint _value) external onlyOwner returns(bool _sent){
        if(_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        } 
        _sent = IERC20(_token).transfer(_to, _value);
        emit TokenRemovedFromContract(_token, _value);
    }
    // to take leftover(bnb) from contract
    function transferBNB() external onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit BnbRemovedFromContract(balance);
    }
//switch functions
    function switchMarketActive(bool _state) external onlyOwner {
        marketActive = _state;
        if(_state) {
            marketActiveAt = block.timestamp;
        }
        emit MarketStatusChanged(_state, block.timestamp);
    }
    function switchLimitSells(bool _state) external onlyOwner {
        limitSells = _state;
        emit LimitSellChanged(_state);
    }
    function switchLimitBuys(bool _state) external onlyOwner {
        limitBuys = _state;
        emit LimitBuyChanged(_state);
    }
//set functions
    function setsendFeeStatus(bool marketing, bool fund, bool company, bool liquidity) external onlyOwner {
        sendToMarketing = marketing;
        sendToCompany = company;
        sendToFund = fund;
        sendToLiquidity = liquidity;
    }
    function setFeesAddress(address marketing, address company, address fund, address liquidity) external onlyOwner {
        marketingAddress = marketing;
        companyAddress = company;
        fundAddress = fund;
        liquidityAddress = liquidity;
        emit FeesAddressesChanged(marketing,company,fund,liquidity);
    }
    function setMaxSellTxAmount(uint _value) external onlyOwner {
        maxSellTxAmount = _value*10**decimals();
        require(maxSellTxAmount >= totalSupply() / 1000,"maxSellTxAmount should be at least 0.1% of total supply.");
        emit MaxSellChanged(_value);
    }
    function setMaxBuyTxAmount(uint _value) external onlyOwner {
        maxBuyTxAmount = _value*10**decimals();
        require(maxBuyTxAmount >= totalSupply() / 1000,"maxBuyTxAmount should be at least 0.1% of total supply.");
        emit MaxBuyChanged(maxBuyTxAmount);

    }
    function setMaxWallet(bool state, uint amount) external onlyOwner {
        maxWallet = state;
        maxWalletAmount = amount;
        require(maxWalletAmount >= totalSupply() / 100,"max wallet min amount: 1%");
        emit MaxWalletChanged(state,amount);
    }
    function setFee(bool is_buy, uint company, uint marketing, uint liquidity, uint fund) external onlyOwner {
        if(is_buy) {
            buyCompanyFee = company;
            buyMarketingFee = marketing;
            buyLiquidityFee = liquidity;
            buyFundFee = fund;
            totalBuyFee = buyMarketingFee + buyCompanyFee + buyLiquidityFee + buyFundFee;
        } else {
            sellCompanyFee = company;
            sellMarketingFee = marketing;
            sellLiquidityFee = liquidity;
            sellFundFee = fund;
            totalSellFee = sellMarketingFee + sellCompanyFee + sellLiquidityFee + sellFundFee;
        }
        require(totalBuyFee <= 1000,"total buy fees cannot be over 10%");
        require(totalSellFee <= 1500,"Total fees cannot be over 15%");
        emit FeesChanged(buyLiquidityFee,buyMarketingFee,buyCompanyFee,
                      sellLiquidityFee,sellMarketingFee,sellCompanyFee);
    }
    function setFeeStatus(bool buy, bool sell, bool _state) external onlyOwner {
        feeStatus = _state;
        buyFeeStatus = buy;
        sellFeeStatus = sell;
        emit FeesStatusChanged(_state,buy,sell);
    }
    function setMinimumTokensBeforeSend(uint amount) external onlyOwner {
        minimumTokensBeforeSend = amount;
        emit MinimumTokensBeforeSendChanged(amount);
    }
// mappings functions
    modifier sameSize(uint list1,uint list2) {
        require(list1 == list2,"lists must have same size");
        _;
    }
    function editPowerUser(address target, bool state) external onlyOwner {
        excludedFromFees[target] = state;
        excludedFromMaxWallet[target] = state;
        premarketUser[target] = state;
        emit EditPowerUser(target,state);
    }
    function editExcludedFromMaxWallet(address user, bool state) external onlyOwner {
        excludedFromMaxWallet[user] = state;
        emit ExcludedFromMaxWalletChanged(user,state);
    }
    function editPremarketUser(address _target, bool _status) external onlyOwner {
        premarketUser[_target] = _status;
        emit PremarketUserChanged(_status,_target);
    }
    function editExcludedFromFees(address _target, bool _status) external onlyOwner {
        excludedFromFees[_target] = _status;
        emit ExcludeFromFeesChanged(_status,_target);
    }
    function editMultiPremarketUser(address[] memory _address, bool[] memory _states) external onlyOwner sameSize(_address.length,_states.length) {
        for(uint i=0; i< _states.length; i++){
            premarketUser[_address[i]] = _states[i];
            emit PremarketUserChanged(_states[i],_address[i]);
        }
    }
    function editMultiExcludedFromMaxWallet(address[] memory _address, bool[] memory _states) external onlyOwner sameSize(_address.length,_states.length) {
        for(uint i=0; i< _states.length; i++){
            excludedFromMaxWallet[_address[i]] = _states[i];
            emit ExcludedFromMaxWalletChanged(_address[i],_states[i]);
        }
    }
    function editMultiExcludedFromFees(address[] memory _address, bool[] memory _states) external onlyOwner sameSize(_address.length,_states.length) {
        for(uint i=0; i< _states.length; i++){
            excludedFromFees[_address[i]] = _states[i];
            emit ExcludeFromFeesChanged(_states[i],_address[i]);
        }
    }
    function editAutomatedMarketMakerPairs(address _target, bool _status) external onlyOwner {
        automatedMarketMakerPairs[_target] = _status;
        emit AutomatedMarketMakerPairsChanged(_status,_target);
    }
// operational functions
    function KKAirdrop(address[] memory _address, uint[] memory _amount) external onlyOwner sameSize(_address.length,_amount.length) {
        for(uint i=0; i< _amount.length; i++){
            super._transfer(owner(), _address[i], _amount[i] *10**decimals());
        }
        // events from ERC20
    }
    function collectFees(uint caBalance) private {
            //Marketing
            if(sendToMarketing) {
                uint marketingTokens = caBalance * sellMarketingFee / totalSellFee;
                super._transfer(address(this),marketingAddress,marketingTokens);
                emit MarketingFeeCollected(marketingTokens);
            }
            //Fund
            if(sendToFund) {
                uint fundTokens = caBalance * sellFundFee / totalSellFee;
                super._transfer(address(this),fundAddress,fundTokens);
                emit FundFeeCollected(fundTokens);
            }
            //Company
            if(sendToCompany) {
                uint companyTokens = caBalance * sellCompanyFee / totalSellFee;
                super._transfer(address(this),companyAddress,companyTokens);
                emit CompanyFeeCollected(companyTokens);
            }
            //Liquidity
            if(sendToLiquidity) {
                uint liquidityTokens = caBalance * sellLiquidityFee / totalSellFee;
                super._transfer(address(this),liquidityAddress,liquidityTokens);
                emit CompanyFeeCollected(liquidityTokens);
            }
    }
    function _transfer(address from, address to, uint amount) internal override {
        uint trade_type = 0;
    // market status flag
        if(!marketActive) {
            require(premarketUser[from],"cannot trade before the market opening");
        }
    // tx limits
        //buy
        if(automatedMarketMakerPairs[from]) {
            trade_type = 1;
            // limits
            if(!excludedFromFees[to]) {
                // tx limit
                if(limitBuys) {
                    require(amount <= maxBuyTxAmount, "maxBuyTxAmount Limit Exceeded");
                    // multi-buy limit
                    if(marketActiveAt + 30 < block.timestamp) {
                        require(marketActiveAt + 7 < block.timestamp,"You cannot buy at launch.");
                        require(userLastTradeData[to].lastBuyTime + 3 <= block.timestamp,"You cannot do multi-buy orders.");
                        userLastTradeData[to].lastBuyTime = block.timestamp;
                    }
                }
            }
        }
        //sell
        else if(automatedMarketMakerPairs[to]) {
            trade_type = 2;
            // limits
            if(!excludedFromFees[from]) {
                // tx limit
                if(limitSells) {
                require(amount <= maxSellTxAmount, "maxSellTxAmount Limit Exceeded");
                }
            }
        }
        // max wallet
        if(maxWallet) {
            require(balanceOf(to) + amount <= maxWalletAmount || excludedFromMaxWallet[to],"maxWallet limit");
        }
    // fees management
        if(feeStatus) {
            // buy
            if(trade_type == 1 && buyFeeStatus && !excludedFromFees[to]) {
                uint txFees = amount * totalBuyFee / 10000;
                amount -= txFees;
                super._transfer(from, address(this), txFees);
            }
            //sell
            else if(trade_type == 2 && sellFeeStatus && !excludedFromFees[from]) {
                uint txFees = amount * totalSellFee / 10000;
                amount -= txFees;
                super._transfer(from, address(this), txFees);
            }
            // no wallet to wallet tax
        }
        // fees redistribution
        uint caBalance = balanceOf(address(this));
        if(caBalance > minimumTokensBeforeSend) { collectFees(caBalance);}
        // transfer tokens
        super._transfer(from, to, amount);
    }
    //heheboi.gif
}