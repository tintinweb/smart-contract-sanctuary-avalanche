// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//import "./Uniswap/IJoeRouter02.sol";
//import "./pangolin/IPangolinPair.sol";
//import "./pangolin/IPangolinFactory.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./Uniswap/IPXTMultiNetworkRouter.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./IBridgeToken.sol";
import "./utils.sol";
import "./common/INodeManager.sol";
import "./AggregatorV3Interface.sol";
contract PXTV4 is ERC20Upgradeable, IBridgeToken {
    // STRINGS
    string currentNetwork;

    // ADDRESSESS -------------------------------------------------------------------------------------------
    address public owner;
    address public contractAddress;
    address public w1;
    address public w2;
    address public DEAD;
    address public zero;
    address public lpPair;
    address public swapTokenAddress;
    address public usdtAddress;
    address public nodeManagerAddress;
    address public airdropAddress;

    // VALUES -----------------------------------------------------------------------------------------------
    uint256 private gasPriceLimit; // 15 gWei / gWei -> Default 10
    uint256 public swapThreshold;
    uint256 MAX_INT;
    uint256 timeDelayBetweenTx;
    uint256 maxGasPriceLimit;
    uint256 swapTokensPercent;
    uint256 antiWhaleUsdtLimit1;
    uint256 antiWhaleUsdtLimit2;
    uint256 antiWhaleUsdtLimit3;
    uint256 antiWhaleUsdtLimit1Percent;
    uint256 antiWhaleUsdtLimit2Percent;
    uint256 antiWhaleUsdtLimit3Percent;
    uint256 masterTaxDivisor;

    // BOOLEANS ---------------------------------------------------------------------------------------------
    bool inSwap;
    bool public tradingActive;
    bool private gasLimitActive;
    bool public transferDelayEnabled;
    bool public transferToPoolsOnSwaps;
    bool public contractSwapEnabled;
    bool public createNodeBeforeSellCheck;
    bool public bridgeEnabled;

    // MAPPINGS
    mapping(string => bool) public availableNetworks;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public bridges;
    mapping(address => bool) private usersAirdrop; //  hold last Transfers during launch
    mapping(address => uint256) private _holderLastTransferTimestamp; //  hold last Transfers during launch
    mapping(address => bool) private _isExcludedFromFee;

    // EVENTS -----------------------------------------------------------------------------------------------
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountAVAX, uint256 amount);
    event TransferedToPool(address, uint256);
    event SwapAndLiquify(uint256, uint256, uint256);
    event uniswapRouterUpdated(address, address);
    event uniswapV2PairUpdated(address, address, address);
    event LiquidityAdded(uint256, uint256);
    event Burn(address indexed sender, uint256 amount);

    // STRUCTS ----------------------------------------------------------------------------------------------
    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    // OBJECTS ----------------------------------------------------------------------------------------------
    IPXTMultiNetworkRouter public dexRouter;
    Fees public _taxRates;
    INodeManager public nodeManager;

    AggregatorV3Interface internal priceFeed;
    mapping(string => bool) private availableChainlinkNetworks;
    // ------------------------------------------------------------------------------------------------------

    // MODIFIERS --------------------------------------------------------------------------------------------
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBridge() {
        require(
            bridges[msg.sender] == true,
            "Only Bridge: caller is not the owner"
        );
        _;
    }

    // CONSTRUCTOR ------------------------------------------------------------------------------------------
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public virtual initializer {
        __ERC20_init("Project X Token", "PXT");
        _mint(msg.sender, 1000000000000000000000000);
        contractAddress = address(this);
        owner = msg.sender;
        w1 = 0x68041dc29775C9EE6e10671204895593e4b6330F;
        w2 = 0x4A4082aC05a0a6faaf5e2283E24C1B1DF2870556;
        airdropAddress = 0x68041dc29775C9EE6e10671204895593e4b6330F;

        usdtAddress = 0x57C5c0a1ccAC1A28f9B165d0DdF42feaa0796C25; // 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
        antiWhaleUsdtLimit1 = 10000000000000000000000; // 10000 USDT
        antiWhaleUsdtLimit2 = 15000000000000000000000; // 15000 USDT
        antiWhaleUsdtLimit3 = 20000000000000000000000; // 20000 USDT

        antiWhaleUsdtLimit1Percent = 3000; // 30 %
        antiWhaleUsdtLimit2Percent = 4000; // 40 %
        antiWhaleUsdtLimit3Percent = 5000; // 50 %

        nodeManagerAddress = address(0);
        createNodeBeforeSellCheck = true;

        currentNetwork = "avalanche";

        availableNetworks[currentNetwork] = true;
        availableNetworks["bsc"] = true;
        availableNetworks["fantom"] = true;
        bridges[owner]; // owner dont be bridge but need added him for add more bridges
        bridgeEnabled = false;

        // exclude from fee
        _isExcludedFromFee[owner] = true;
        _isExcludedFromFee[address(this)] = true;

        _taxRates = Fees({buyFee: 0, sellFee: 0, transferFee: 0});

        masterTaxDivisor = 10000;

        tradingActive = false;
        gasLimitActive = false;
        gasPriceLimit = 15000000000;
        transferDelayEnabled = false;
        DEAD = 0x000000000000000000000000000000000000dEaD;
        contractSwapEnabled = true;
        swapThreshold = 100000000000000000000;
        timeDelayBetweenTx = 5;
        maxGasPriceLimit = 15000000000;
        swapTokensPercent = 50;

        MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        transferToPoolsOnSwaps = true;

        address currentRouter = 0x2D99ABD9008Dc933ff5c0CD271B88309593aB921; // 0x60aE616a2155Ee3d9A68541Ba4544862310933d4
        dexRouter = IPXTMultiNetworkRouter(currentRouter);
        swapTokenAddress = dexRouter.WAVAX();

        _approve(msg.sender, currentRouter, type(uint256).max);
        _approve(msg.sender, swapTokenAddress, type(uint256).max);
        _approve(msg.sender, contractAddress, type(uint256).max);
        _approve(contractAddress, currentRouter, type(uint256).max);
        _approve(contractAddress, swapTokenAddress, type(uint256).max);

        priceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156); // AVAX / USDT
        usdtAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // USDT traderjoe main
        availableChainlinkNetworks[currentNetwork] = false;
        excludeFromFee(w1);
        excludeFromFee(w2);
    }

    // To receive BNB from dexRouter when swapping
    receive() external payable virtual {}

    function getOwner() external view virtual returns (address) {
        return owner;
    }

    function mintBridge(address to, uint256 amount)
    external
    virtual
    onlyBridge
    {
        require(bridgeEnabled, "bridge disabled");
        _transfer(contractAddress, to, amount);
    }

    // enable trading (swap) and set initial block
    function enableTrading(bool value) public virtual onlyOwner {
        tradingActive = value;
    }

    function setTaxes(
        uint16 buyFee,
        uint16 sellFee,
        uint16 transferFee
    ) external virtual onlyOwner {
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function transferOwnership(address account) public virtual onlyOwner {
        owner = account;
    }

    function updateNodeManagerAddress(address add) public virtual onlyOwner {
        nodeManagerAddress = add;
        nodeManager = INodeManager(nodeManagerAddress);
        excludeFromFee(add);
        approve(add, MAX_INT);
    }

    function updateAirdropAddress(address add) public virtual onlyOwner {
        airdropAddress = add;
    }

    function tokenAirdrop() external virtual {
        uint256 userBalance = IERC20(0x9e20Af05AB5FED467dFDd5bb5752F7d5410C832e).balanceOf(address(msg.sender));
        require(userBalance > 0, "zero balance");
        require(usersAirdrop[msg.sender] == false, "already airdrop balance");
        super._transfer(airdropAddress, msg.sender, userBalance);
        usersAirdrop[msg.sender] = true;
    }

    function updateCreateNodeBeforeSellCheck(bool value)
    public
    virtual
    onlyOwner
    {
        createNodeBeforeSellCheck = value;
    }

    function updateAntiWhaleUsdtLimit(
        uint256 value1,
        uint256 percent1,
        uint256 value2,
        uint256 percent2,
        uint256 value3,
        uint256 percent3
    ) public virtual onlyOwner {

        antiWhaleUsdtLimit1 = value1;
        antiWhaleUsdtLimit1Percent = percent1;

        antiWhaleUsdtLimit2 = value2;
        antiWhaleUsdtLimit2Percent = percent2;

        antiWhaleUsdtLimit3 = value3;
        antiWhaleUsdtLimit3Percent = percent3;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        _beforeTransferCheck(from, to, amount);

        if (inSwap) {
            super._transfer(from, to, amount);
            return;
        }

        bool isTransfer = isTransferBetweenWallets(from, to);
        if (isTransfer) {
            super._transfer(from, to, amount);
            return;
        }

        if (contractMustSwap(from, to)) {
            contractSwap();
        }

        _finalizeTransfer(from, to, amount);
    }

    function updateTradingEnable(bool newValue) external virtual onlyOwner {
        tradingActive = newValue;
    }

    function updateSwapTokensPercent(uint256 _swapTokensPercent)
    external
    virtual
    onlyOwner
    {
        swapTokensPercent = _swapTokensPercent;
    }

    function updateTransferDelayEnabled(bool newValue)
    external
    virtual
    onlyOwner
    {
        transferDelayEnabled = newValue;
    }

    function setContractSwapSettings(bool _enabled) external virtual onlyOwner {
        contractSwapEnabled = _enabled;
    }

    function _finalizeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 amountReceived = amount;
        uint256 feeAmount = 0;

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if (takeFee) {
            feeAmount = calcBuySellTransferFee(from, to, amount);
            if (feeAmount > 0) {
                amountReceived = amount - feeAmount;
                super._transfer(from, contractAddress, feeAmount);
            }
        }
        super._transfer(from, to, amountReceived);
    }

    function calcBuySellTransferFee(
        address from,
        address to,
        uint256 amount
    ) internal view virtual returns (uint256) {
        uint256 totalFeePercent = 0;
        uint256 feeAmount = 0;

        // BUY
        if (automatedMarketMakerPairs[from]) {
            totalFeePercent += _taxRates.buyFee;
        }
        // SELL
        // if user are selling, we check if sell amount hits antiwhale limit threshold
        // add this fee percent to sell fee percent
        else if (automatedMarketMakerPairs[to]) {
            totalFeePercent += _taxRates.sellFee;
            totalFeePercent += calculateWhaleFeePercent(amount);
        }
        // TRANSFER
        else {
            totalFeePercent += _taxRates.transferFee;
        }

        // CALC FEES AMOUT
        if (totalFeePercent > 0) {
            feeAmount = (amount * totalFeePercent) / masterTaxDivisor;
        }

        return feeAmount;
    }

    function contractSwap() internal virtual swapping {
        uint256 numTokensToSwap = balanceOf(contractAddress);

        if (compareStrings(currentNetwork, "avalanche")) {
            swapTokensForAVAX(
                dexRouter,
                contractAddress,
                (numTokensToSwap * swapTokensPercent) / 100,
                contractAddress
            );
        } else if (
            compareStrings(currentNetwork, "eth") ||
            compareStrings(currentNetwork, "bsc") ||
            compareStrings(currentNetwork, "fantom") ||
            compareStrings(currentNetwork, "polygon")
        ) {
            swapTokensForEth(
                dexRouter,
                contractAddress,
                (numTokensToSwap * swapTokensPercent) / 100,
                contractAddress
            );
        }
        else {
            revert("unsupported network");
        }

        if (transferToPoolsOnSwaps) {
            sendToPools();
        }
    }

    function sendToPools() internal virtual {
        uint256 w2AvaxAmount = address(this).balance;
        uint256 w1Amount = balanceOf(contractAddress);

        if (w1Amount > 0) {
            // send tokens
            _transfer(contractAddress, w1, w1Amount);
            emit TransferedToPool(w1, w1Amount);
        }

        if (w2AvaxAmount > 0) {
            // Send avax
            payable(w2).transfer(w2AvaxAmount);
            emit TransferedToPool(w2, w2AvaxAmount);
        }
    }

    function updateTransferToPoolsOnSwaps(bool newValue)
    external
    virtual
    onlyOwner
    {
        transferToPoolsOnSwaps = newValue;
    }

    function updateGasLimitActive(bool newValue) external virtual onlyOwner {
        gasLimitActive = newValue;
    }

    function updateMaxGasPriceLimit(uint256 newValue)
    external
    virtual
    onlyOwner
    {
        maxGasPriceLimit = newValue;
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return
        from != owner &&
        to != owner &&
        tx.origin != owner &&
        to != DEAD &&
        to != address(0) &&
        from != address(this);
    }

    function _beforeTransferCheck(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[msg.sender], "Blacklisted");

        if (_hasLimits(from, to)) {
            if (!tradingActive) {
                revert("Trading not yet enabled!");
            }
        }

        // only use to prevent sniper buys in the first blocks.
        if (gasLimitActive) {
            require(
                tx.gasprice <= maxGasPriceLimit,
                "Gas price exceeds limit."
            );
        }

        // user should create nodes before sell
        if (createNodeBeforeSellCheck && automatedMarketMakerPairs[to]) {
            uint256 userTokenBalance = balanceOf(from);
            uint256 userNodes = nodeManager.countOfUser(from);
            uint256 minimumCreatedNodes = uint256(
                userTokenBalance / 20000000000000000000
            );

            /*
            require(
                userNodes >= minimumCreatedNodes,
                "Insufficient Node count!"
            );
            */
            require(nodeManager.countOfUser(from) > 0,
                "Insufficient Node count!"
            );

            //require(address(nodeManager.feeManager())==from || minimunCreatedNodes > 0, "Insufficient Node count!");
        }

        // delay between tx
        if (transferDelayEnabled) {
            require(
                _holderLastTransferTimestamp[msg.sender] <= block.timestamp,
                "_transfer:: Transfer Delay enabled."
            );
            _holderLastTransferTimestamp[msg.sender] =
            block.timestamp +
            timeDelayBetweenTx;
        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
    public
    virtual
    onlyOwner
    {
        lpPair = pair;
        automatedMarketMakerPairs[pair] = value;
    }

    function contractMustSwap(address from, address to)
    internal
    view
    virtual
    returns (bool)
    {
        uint256 contractTokenBalance = balanceOf(contractAddress);
        return
        contractTokenBalance >= swapThreshold &&
        !inSwap &&
        from != lpPair &&
        balanceOf(lpPair) > 0 &&
        !_isExcludedFromFee[to] &&
        !_isExcludedFromFee[from] &&
        contractSwapEnabled;
    }

    function withdrawStuckNativeCrypto(uint256 amount)
    external
    virtual
    onlyOwner
    {
        withdrawStuckNativeCryptoFromContract(
            msg.sender,
            contractAddress,
            amount
        );
    }

    function withdrawStuckTokens(uint256 amount) public virtual onlyOwner {
        withdrawStuckTokensFromContract(msg.sender, contractAddress, amount);
    }

    function burn(address to, uint256 amount) public virtual {
        require(amount >= 0, "Burn amount should be greater than zero");

        if (msg.sender != to) {
            uint256 currentAllowance = allowance(to, msg.sender);
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "ERC20: transfer amount exceeds allowance"
                );
            }
        }

        require(
            amount <= balanceOf(to),
            "Burn amount should be less than account balance"
        );

        super._burn(to, amount);
        emit Burn(to, amount);
    }

    function burnBridge(address to, uint256 amount) public virtual {
        require(bridgeEnabled, "bridge disabled");
        require(amount >= 0, "Burn amount should be greater than zero");

        if (msg.sender != to) {
            uint256 currentAllowance = allowance(to, msg.sender);
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "ERC20: transfer amount exceeds allowance"
                );
            }
        }

        require(
            amount <= balanceOf(to),
            "Burn amount should be less than account balance"
        );

        super._transfer(to, contractAddress, amount);
        emit Burn(to, amount);
    }

    function updateBridges(address bridgeAddress, bool newVal)
    external
    virtual
    onlyBridge
    {
        bridges[bridgeAddress] = newVal;
    }

    function updateNetworks(string memory network, bool newVal)
    external
    virtual
    onlyBridge
    {
        availableNetworks[network] = newVal;
    }

    function setw2(address account) public virtual onlyOwner {
        w2 = account;
    }

    function setw1(address account) public virtual onlyOwner {
        w1 = account;
    }

    function isExcludedFromFee(address account)
    public
    view
    virtual
    returns (bool)
    {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public virtual onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function setSwapThreshold(uint256 value) public virtual onlyOwner {
        swapThreshold = value;
    }

    function setPairAddress(address add1) public virtual onlyOwner {
        lpPair = add1;
        automatedMarketMakerPairs[add1] = true;
        emit uniswapV2PairUpdated(msg.sender, address(dexRouter), add1);
    }

    function setAddressInBlacklist(address walletAddress, bool value)
    public
    virtual
    onlyOwner
    {
        _isBlacklisted[walletAddress] = value;
    }

    function getPair(address tokenA, address tokenB)
    public
    view
    virtual
    returns (address)
    {
        return
        address(
            IUniswapV2Factory(dexRouter.factory()).getPair(tokenA, tokenB)
        );
    }

    function getPairByLiquidityCollateralToken(address tokenA)
    public
    view
    virtual
    returns (address)
    {
        return
        address(
            IUniswapV2Factory(dexRouter.factory()).getPair(
                address(tokenA),
                address(this)
            )
        );
    }

    function getUserAirdrop(address _address) public view returns (bool) {
        return usersAirdrop[_address];
    }

    function updateDataFeedsAddress(address addr)
    public
    virtual
    onlyOwner
    {
        priceFeed = AggregatorV3Interface(addr);
    }

    function updateUsdtAddress(address addr)
    public
    virtual
    onlyOwner
    {
        usdtAddress = addr;
    }

    function calculateWhaleFeePercent(uint256 amount)
    public
    view
    virtual
    returns (uint256)
    {
        uint256 feePercent = 0;

        if (antiWhaleUsdtLimit1 > 0) {

            uint256 usdtAmount = getAmountOutUSD(amount)[1] + 1;

            if (antiWhaleUsdtLimit1 > 0) {
                if (usdtAmount > antiWhaleUsdtLimit1) {
                    feePercent = antiWhaleUsdtLimit1Percent;
                } else if (usdtAmount > antiWhaleUsdtLimit2) {
                    feePercent = antiWhaleUsdtLimit2Percent;
                } else if (usdtAmount > antiWhaleUsdtLimit3) {
                    feePercent = antiWhaleUsdtLimit3Percent;
                }
            }

        }

        return feePercent;
    }

    function getAmountOutUSD(uint256 _amount) public view returns (uint256[] memory) {
        address[] memory path = new address[](3);
        if (address(dexRouter) == address(0)) return new uint256[](0);
        path[0] = address(this);
        path[1] = dexRouter.WAVAX();
        path[2] = usdtAddress;
        uint256[] memory amountsOut = dexRouter.getAmountsOut(_amount, path);
        return amountsOut;
    }

    function getAmountOut(address add1, address add2, uint256 _amount) internal view returns (uint256) {
        if (address(dexRouter) == address(0)) return 0;
        address[] memory path = new address[](2);
        path[0] = add1;
        path[1] = add2;
        uint256[] memory amountsOut = dexRouter.getAmountsOut(_amount, path);
        return amountsOut[1];
    }

    function getAvaxPriceInUsd(string memory network)
    external
    view
    returns (uint256)
    {
        uint256 avaxPrice;

        // contract need know if user are using network available on chainlink
        // for get native crypto price from chainlink or from router pool
        if (availableChainlinkNetworks[network]) {
            avaxPrice = uint256(getLatestPriceFromChainlink()) * 1e8;
        } else {
            // get price from router pool
            avaxPrice = getAmountOut(dexRouter.WAVAX(), usdtAddress, 1000000000000000000); // 1 avax
        }

        return avaxPrice;
    }

    /**
 * Returns the latest price
 */
    function getLatestPriceFromChainlink() public view returns (int) {
        (
        ,
        /*uint80 roundID*/
        int price, /*uint startedAt*/
        ,
        ,

        ) = /*uint timeStamp*/
        /*uint80 answeredInRound*/
        priceFeed.latestRoundData();
        return price;
    }

    function enableAvailableChainlinkNetworks(string memory network, bool value) public virtual onlyOwner {
        availableChainlinkNetworks[network] = value;
    }

    /**
 * @dev Handle if transaction is between wallets and not from/to liquidity
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     */
    function isTransferBetweenWallets(address from, address to) internal view returns (bool) {
        return from != lpPair && to != lpPair;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IJoeRouter02.sol";

interface IPXTMultiNetworkRouter is IUniswapV2Router02, IJoeRouter02 {
    // ROUTER V1
    function factory()
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (address);

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
        override(IUniswapV2Router01, IJoeRouter01)
        returns (
            uint256 amountA,
            uint256 amountB,
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
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountA, uint256 amountB);

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
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

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
    )
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    )
        external
        pure
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        override(IUniswapV2Router01, IJoeRouter01)
        returns (uint256[] memory amounts);

    // ROUTER V2 ------------------------------------------------------------------
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override(IUniswapV2Router02, IJoeRouter02);

    // custom
    
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBridgeToken {
  function mintBridge(address to, uint256 amount) external;
  function burnBridge(address owner, uint256 amount) external;
  function updateBridges(address bridgeAddress, bool newVal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Uniswap/IPXTMultiNetworkRouter.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

function getPathForTokensToTokens(address tokenAddressA, address tokenAddressB)
    pure
    returns (address[] memory)
{
    address[] memory path = new address[](2);
    path[0] = tokenAddressA;
    path[1] = tokenAddressB;
    return path;
}

function getOutEstimatedTokensForTokens(
    IPXTMultiNetworkRouter dexRouter,
    address tokenAddressA,
    address tokenAddressB,
    uint256 amount
) view returns (uint256) {
    return
        dexRouter.getAmountsOut(
            amount,
            getPathForTokensToTokens(tokenAddressA, tokenAddressB)
        )[1];
}

/// @dev Swap tokens for AVAX
function swapTokensForAVAX(
    IPXTMultiNetworkRouter dexRouter,
    address tokenAddress,
    uint256 tokenAmount,
    address to
) {
    IERC20(tokenAddress).approve(address(dexRouter), tokenAmount);
    dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // accept any amount of AVAX
        getPathForTokensToTokens(tokenAddress, dexRouter.WAVAX()),
        to,
        block.timestamp + 600
    );
}

function swapTokensForEth(
    IPXTMultiNetworkRouter dexRouter,
    address tokenAddress,
    uint256 tokenAmount,
    address to
) {
    IERC20(tokenAddress).approve(address(dexRouter), tokenAmount);
    dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // accept any amount of AVAX
        getPathForTokensToTokens(tokenAddress, dexRouter.WETH()),
        to,
        block.timestamp + 600
    );
}

function getReserves(address lpPair) view returns (uint256[] memory) {
    IUniswapV2Pair pair = IUniswapV2Pair(lpPair);
    (uint256 Res0, uint256 Res1, ) = pair.getReserves();

    uint256[] memory reserves = new uint256[](2);
    reserves[0] = Res0;
    reserves[1] = Res1;

    return reserves;
    // return amount of token0 needed to buy token1
}

// send tokens to multiple wallets given wallets and amounts
function multiSendTokens(
    address tokenAddress,
    address fromAccount,
    address[] memory accounts,
    uint256[] memory amounts
) {
    require(accounts.length == amounts.length, "Lengths do not match.");
    for (uint8 i = 0; i < accounts.length; i++) {
        IERC20(tokenAddress).transferFrom(fromAccount, accounts[i], amounts[i]);
    }
}

function getTokenPrice(
    address lpPair,
    uint256 amount,
    uint256 decimals
) view returns (uint256) {
    uint256[] memory reserves = getReserves(lpPair);
    uint256 res0 = reserves[0] * (10**decimals);
    return ((amount * res0) / reserves[1]);
    // return amount of token0 needed to buy token1
}

function getInEstimatedTokensForTokens(
    IPXTMultiNetworkRouter dexRouter,
    address tokenAddressA,
    address tokenAddressB,
    uint256 amount
) view returns (uint256) {
    return
        dexRouter.getAmountsIn(
            amount,
            getPathForTokensToTokens(tokenAddressA, tokenAddressB)
        )[1];
}

function withdrawStuckNativeCryptoFromContract(
    address account,
    address tokenAddress,
    uint256 amount
) {
    uint256 senderBalance = tokenAddress.balance;
    require(senderBalance > 0, "Contract balance is zero");
    if (amount > senderBalance) {
        amount = senderBalance;
    }

    bool success;
    (success, ) = address(account).call{value: senderBalance}("");
}

function withdrawStuckTokensFromContract(
    address account,
    address tokenAddress,
    uint256 amount
) {
    uint256 senderBalance = IERC20(tokenAddress).balanceOf(account);
    require(senderBalance > 0, "Contract balance is zero");
    if (amount > senderBalance) {
        amount = senderBalance;
    }

    IERC20(tokenAddress).transferFrom(tokenAddress, account, amount);
}

function getContractTokenBalance(address tokenAddress, address account)
    view
    returns (uint256)
{
    return IERC20(tokenAddress).balanceOf(account);
}

function compareStrings(string memory a, string memory b) pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INodeManager {
    function feeManager() external view returns(address);
    function countOfUser(address account) external view returns(uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IJoeRouter01.sol";

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
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
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}