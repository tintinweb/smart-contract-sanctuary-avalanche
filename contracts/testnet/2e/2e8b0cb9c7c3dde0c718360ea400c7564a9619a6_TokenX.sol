/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-06
*/

//it is a testing contract for print and reflaction token as tax fee

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
}

//interface for WAVAX
interface IWAVAX is IERC20 {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract TokenX is IERC20 {
    //for library
    using SafeMath for uint;

    address public Owner;

    //ERC20 token's meta data
    string constant _name = "TokenX";
    string constant _symbol = "TX";
    uint8 constant _decimals = 6;

    //token decimals
    address public WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;
    address public USDC = 0x5425890298aed601595a70AB815c96711a31Bc65;

    IERC20 printToken = IERC20(USDC);

    //token unique variables(fee calculating variables)
    uint public taxFee = 100;
    uint private _taxCalcDenominator = 1000;
    uint public nativeTokenFee = 200;
    uint private liquidityNativeTokenFee = 100;
    uint public liquiidtyFee = 200;
    uint private totalDistributeWAVAXTokenFee = 700;
    uint public printTokenFee = 200;
    uint private liquidityWAVAXFee = 100;
    uint private marketingWAVAXFee = 400;
    uint percantageDenominator = 10000;

    //dex variables
    address public ROUTER = 0x2D99ABD9008Dc933ff5c0CD271B88309593aB921;
    IDEXRouter public router;
    address public pair;

    //token total supply
    uint256 public _totalSupply = 10000 * (10 ** _decimals); //initial supply of tokens

    //balance and holder iteraton methods
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    //reward helpers
    address public MARKETINGADD = 0x3Caf97F5Bd858B0D6B8c2135BB7781319d6B91ae;
    uint256 public rewardDenominator = 1000;
    uint256 public printTokenDecimal = 6;

    //share properties for account holders
    struct Share {
        uint256 lastRewardPercantage;
        uint256 totalUSDTRewards;
        uint256 totalNativeRewards;
        uint256 nativebalance;
    }

    address[] private freeOfTaxes;
    address[] private tokenHolders;
    mapping(address => uint256) private holderByIndex;
    mapping(address => uint256) private shareHolderClaims;
    mapping(address => Share) public Shares;

    modifier onlyOwner() {
        require(msg.sender == Owner, "only owner can call the function");
        _;
    }

    modifier printPaymentFirst() {
        if (msg.sender != Owner) {
            if (Shares[msg.sender].totalUSDTRewards > 0) {
                printToken.transfer(
                    msg.sender,
                    Shares[msg.sender].totalUSDTRewards
                );
                Shares[msg.sender].totalUSDTRewards = 0;
            }
        }
        _;
    }

    constructor() {
        Owner = msg.sender;
        router = IDEXRouter(0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901);
        pair = IDEXFactory(router.factory())
            .createPair(WAVAX, address(this));
        _allowances[address(this)][ROUTER] = _totalSupply;
        WAVAX = router.WAVAX();
    

        approve(pair, _totalSupply);
        _balances[msg.sender] = _totalSupply;
        freeOfTaxes.push(msg.sender);
        freeOfTaxes.push(address(this));
        freeOfTaxes.push(ROUTER);
        freeOfTaxes.push(pair);
    }

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
    ) external view override returns (uint256) {
        return _balances[account];
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
    ) external override printPaymentFirst returns (bool) {
                if(isFeeExempt(msg.sender) == true){
           return _basicTransfer(msg.sender, to, amount);
        }
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override printPaymentFirst returns (bool) {
        if(isFeeExempt(msg.sender) == true){
           return _basicTransfer(from, to, amount);
        }
        return _transfer(from, to, amount);
    }

    function _basicTransfer(address sender, address to, uint amount) internal returns(bool){
        require(sender != address(0), "invalid sender");
        require(to != address(0), "invalid sender");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[to] = _balances[to].add(amount);
        return true;
    }

    

    //internal functions
    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) public returns (bool) {
        require(sender != address(0), "invalid sender");
        require(receiver != address(0), "invalid sender");
        require(amount > 999, "amount is too short to transfer");
        _balances[sender] -= amount;

        uint feeAmount = 0;
        uint256 WAVAXForPrintToken = 0;

        uint256 amountNative = 0;

        if (isFeeExempt(sender) != true) {
            feeAmount = (amount.mul(taxFee)).div(_taxCalcDenominator);
        }
        uint amountWillReceived = amount.sub(feeAmount);
        if (_balances[receiver] == 0) {
            _addTokenHolder(receiver);
        } else {
            _updateTokenHolder(receiver, amountWillReceived);
        }

        _balances[receiver] += amountWillReceived;

        if (feeAmount > 0) {
            // uint256 distributePrintToken = (taxForAmount*printTokenFee)/_taxCalcDenominator;
            uint256 distributeWAVAXToken = (
                feeAmount.mul(totalDistributeWAVAXTokenFee)
            ).div(_taxCalcDenominator);

            uint256 WAVAX_by_swap = swapTokensForAVAX(distributeWAVAXToken);
            if (printTokenFee > 0) {
                WAVAXForPrintToken = (
                    WAVAX_by_swap.mul(
                        _getPercentageAt(
                            printTokenFee,
                            totalDistributeWAVAXTokenFee
                        )
                    )
                ).div(percantageDenominator);
                uint printRewardAmounts = _tokenPrint(WAVAXForPrintToken);
                _distributeToken(printRewardAmounts, 2); //params 2 indicate for printreward distributions
            }

            uint256 WAVAXForMarketing = (
                WAVAX_by_swap.mul(
                    _getPercentageAt(
                        marketingWAVAXFee,
                        totalDistributeWAVAXTokenFee
                    )
                )
            ).div(percantageDenominator);

            uint256 WAVAXForLiquidity = WAVAX_by_swap.sub(
                WAVAXForMarketing.add(WAVAXForPrintToken)
            );
            uint256 LIQUIDITyNativeToken = (
                (feeAmount.mul(liquiidtyFee)).div(_taxCalcDenominator)
            ).div(2);

            payable(MARKETINGADD).transfer(WAVAXForMarketing);

            AddTokenLiquidity(WAVAXForLiquidity, LIQUIDITyNativeToken);

            if (nativeTokenFee > 0) {
                amountNative = (feeAmount.mul(nativeTokenFee)).div(
                    _taxCalcDenominator
                );
                _distributeToken(amountNative, 1);
            }
        }

        return true;
    }

    function _getPercentageAt(
        uint _value,
        uint _percantageAt
    ) internal view returns (uint) {
        return ((_value.mul(percantageDenominator)).div(_percantageAt));
    }

    //reward distribute events
    event DistributeRewards(uint totalRewardAmount);

    function _distributeToken(uint _totalAmount, uint num) internal {
        //1 for native token  2 for print token
        uint256 totalHoldedTokens = getTotalHoldedTokens();
        for (uint i = 0; i < tokenHolders.length; i++) {
            uint holderPercantage = Shares[tokenHolders[i]]
                .lastRewardPercantage == 0
                ? _getPercentageAt(
                    _balances[tokenHolders[i]],
                    totalHoldedTokens
                )
                : Shares[tokenHolders[i]].lastRewardPercantage;
            Shares[tokenHolders[i]].lastRewardPercantage = holderPercantage;
            uint256 rewardAmount = (_totalAmount.mul(holderPercantage)).div(
                100
            );
            if (num == 1) {
                Shares[tokenHolders[i]].totalNativeRewards = Shares[
                    tokenHolders[i]
                ].totalNativeRewards.add(rewardAmount);
                _balances[tokenHolders[i]] = _balances[tokenHolders[i]].add(
                    rewardAmount
                );
            }
            if (num == 2) {
                Shares[tokenHolders[i]].totalUSDTRewards = Shares[
                    tokenHolders[i]
                ].totalUSDTRewards.add(rewardAmount);
            }
        }
        emit DistributeRewards(_totalAmount);
    }

    function getHolderPercantage(address _holder) public view returns (uint) {
        require(_holder != Owner);
        uint totalHoldedTokens = getTotalHoldedTokens();
        return _getPercentageAt(_balances[_holder], totalHoldedTokens);
    }

    //liquidity event
    event Liquified(uint amoun1, uint amount2, uint liquid);

    function AddTokenLiquidity(
        uint256 WavaxAmount,
        uint256 tokenAmount
    ) public {
        _allowances[address(this)][ROUTER] = tokenAmount;

        (uint amountA, uint amountB, uint liquidity) = router.addLiquidityAVAX{
            value: WavaxAmount
        }(address(this), tokenAmount, 0, 0, Owner, block.timestamp);
        emit Liquified(amountA, amountB, liquidity);
    }

    // swap WAVAX event
    event SwapTokensForAVAX(
        uint _tokenAmount,
        uint _avaxAmount,
        address[] path
    );

    function swapTokensForAVAX(uint256 tokenAmount) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();
        uint initialBal = IWAVAX(WAVAX).balanceOf(address(this));
        _allowances[address(this)][ROUTER] = tokenAmount;
        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint finalBal = IWAVAX(WAVAX).balanceOf(address(this));
        uint avaxBySwap = finalBal - initialBal;
        emit SwapTokensForAVAX(tokenAmount, avaxBySwap, path);
        return avaxBySwap;
    }

    //printing events
    event Printed(uint256 _printAmount);

    function _tokenPrint(uint256 valueWAVAX) public returns (uint256) {
        uint256 balanceBefore = printToken.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = USDC;

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: valueWAVAX
        }(0, path, address(this), block.timestamp);

        uint256 amount = printToken.balanceOf(address(this)) - balanceBefore;

        emit Printed(amount);
        return amount;
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

    function isFeeExempt(address _sender) public onlyOwner view returns (bool) {
        for (uint i = 0; i < freeOfTaxes.length; i++) {
            if (_sender == freeOfTaxes[i]) {
                return true;
            }
        }
        return false;
    }

    function setFeeExempt(address _add) public {
        freeOfTaxes.push(_add);
    }

    function getTotalHoldedTokens() public view returns (uint256) {
        uint256 totalCounted;
        for (uint i = 0; i < tokenHolders.length; i++) {
            totalCounted += _balances[tokenHolders[i]];
        }

        return totalCounted;
    }

    function setRewardPercentage(
        uint nativeFee,
        uint nativeLiq,
        uint printTokens,
        uint WAVAXLIQ,
        uint marketingLiq,
        uint calcDenominator
    ) public onlyOwner returns (bool) {
        _taxCalcDenominator = calcDenominator;
        nativeTokenFee = nativeFee;
        liquidityNativeTokenFee = nativeLiq;
        totalDistributeWAVAXTokenFee = printTokens + WAVAXLIQ + marketingLiq;
        printTokenFee = printTokens;
        liquidityWAVAXFee = WAVAXLIQ;
        marketingWAVAXFee = marketingLiq;
        return (_taxCalcDenominator ==
            nativeFee + nativeLiq + printTokens + WAVAXLIQ + marketingLiq);
    }

    function PrintTokenBal(address _holder) public view returns (uint256) {
        return IERC20(printToken).balanceOf(_holder);
    }

    function setPercantageDenominator(uint _value) external onlyOwner {
        percantageDenominator = _value;
    }

    function setRouter(address _routerAdd) external onlyOwner {
        ROUTER = _routerAdd;
        router = IDEXRouter(_routerAdd);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        freeOfTaxes.push(_routerAdd);
        freeOfTaxes.push(pair);
    }

    function setWAVAX(address _WAVAXAdd) external onlyOwner {
        pair = IDEXFactory(router.factory()).createPair(
            _WAVAXAdd,
            address(this)
        );
        WAVAX = router.WAVAX();
    }

    function WAVAXBal(address _holder) public view returns (uint256) {
        return IWAVAX(WAVAX).balanceOf(_holder);
    }

    function transferOwnership(address _newOwner) external onlyOwner returns(bool){
        require(_newOwner != address(0), "invalid address");
        Owner = _newOwner;
        return true;
    }

    function TransferAVAX(
        address payable recipient,
        uint256 amount
    ) internal onlyOwner {
        require(
            recipient != address(0),
            "Cannot withdraw the AVAX balance to the zero address"
        );
        recipient.transfer(amount);
    }
}