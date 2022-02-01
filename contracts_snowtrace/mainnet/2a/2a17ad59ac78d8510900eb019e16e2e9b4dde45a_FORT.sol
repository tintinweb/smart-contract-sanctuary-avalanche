// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./DividendPayingToken.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IDex.sol";

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract FORT is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;

    bool private swapping;
    bool public swapEnabled = true;
    bool public tradingEnabled;
    uint256 public startTradingBlock;

    FortDividendTracker public dividendTracker;

    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet = 0x2E89172405295cC912278757fc472B00aDd2bD88;
    address public devWallet = 0x95C03f91a2b196341f135cC93154D1538Aa68b9c;
    address public operationsWallet = 0xD0aa874c8c140F695e9107Fa8678062F70D302da;
    address public buybackWallet = 0x31829489EE5292554Dde76FC4660AedbE3d31926;

    uint256 public swapTokensAtAmount = 2_500_000_000 * 10**9;
    uint256 public maxWalletBalance = 30_000_000_000 * 10**9;
    uint256 public maxBuyAmount = 30_000_000_000 * 10**9;
    uint256 public maxSellAmount = 10_000_000_000 * 10**9;

    string private currentRewardToken;

    ///////////////
    //   Fees    //
    ///////////////

    struct Taxes {
        uint256 rewards;
        uint256 marketing;
        uint256 liquidity;
        uint256 operations;
        uint256 buyback;
        uint256 dev;
    }

    Taxes public buyTaxes = Taxes(3, 5, 1, 1, 2, 1);
    Taxes public sellTaxes = Taxes(3, 5, 1, 1, 2, 1);

    ////////////////
    //  Anti Bot  //
    ////////////////

    mapping(address => bool) public _isBot;
    mapping(address => uint256) public lastSell;
    uint256 private antiBotBlocks;
    uint256 public coolDownTime = 60;
    uint256 private launchtax;
    uint256 public coolDownBalance = 1_000_000_000 * 10**9;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    ///////////////
    //   Events  //
    ///////////////

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        address indexed processor
    );

    constructor() ERC20("Fort", "FORT") {
        router = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(devWallet, true);
        excludeFromFees(operationsWallet, true);
        excludeFromFees(buybackWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1e12 * (10**9));
    }

    function setUpDividendTracker(address payable _dividendTracker) external onlyOwner {
        dividendTracker = FortDividendTracker(_dividendTracker);
        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(deadWallet, true);
        dividendTracker.excludeFromDividends(address(router), true);
    }

    receive() external payable {}

    /// @notice Manual claim the dividends after claimWait is passed
    ///    This can be useful during low volume days.

    function setDividendConfig(
        bool claim,
        address excludeAcc,
        bool shouldExclude,
        address rewardToken,
        uint256 minBal
    ) external onlyOwner {
        if (claim) dividendTracker.processAccount(payable(msg.sender), false);
        dividendTracker.excludeFromDividends(excludeAcc, shouldExclude);
        dividendTracker.setRewardToken(rewardToken);
        dividendTracker.setMinBalanceForDividends(minBal);
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            msg.sender,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Fort: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    ///////////////////////
    //  Setter Functions //
    ///////////////////////
    function setWallets(
        address marketing,
        address dev,
        address buyBack,
        address operations
    ) external onlyOwner {
        marketingWallet = marketing;
        devWallet = dev;
        buybackWallet = buyBack;
        operationsWallet = operations;
    }

    function setBuyTaxes(
        uint256 _rewards,
        uint256 _marketing,
        uint256 _liquidity,
        uint256 _operations,
        uint256 _buyback,
        uint256 _dev
    ) external onlyOwner {
        buyTaxes = Taxes(_rewards, _marketing, _liquidity, _operations, _buyback, _dev);
    }

    function setSellTaxes(
        uint256 _rewards,
        uint256 _marketing,
        uint256 _liquidity,
        uint256 _operations,
        uint256 _buyback,
        uint256 _dev
    ) external onlyOwner {
        sellTaxes = Taxes(_rewards, _marketing, _liquidity, _operations, _buyback, _dev);
    }

    function setMaxSettings(
        uint256 _mxWalletBalance,
        uint256 _swapTokensAt,
        uint256 _mxBuy,
        uint256 _mxSell
    ) external onlyOwner {
        maxWalletBalance = _mxWalletBalance * 10**9;
        swapTokensAtAmount = _swapTokensAt * 10**9;
        maxBuyAmount = _mxBuy * 10**decimals();
        maxSellAmount = _mxSell * 10**decimals();
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, marketing and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setCooldownTime(uint256 timeInSeconds, uint256 balance) external onlyOwner {
        coolDownTime = timeInSeconds;
        coolDownBalance = balance * 10**decimals();
    }

    function setTradingEnabled(
        bool _enabled,
        uint256 _deadline,
        uint256 _launchtax
    ) external onlyOwner {
        tradingEnabled = _enabled;
        antiBotBlocks = _deadline;
        launchtax = _launchtax;
        if (startTradingBlock == 0 && _enabled == true) startTradingBlock = block.number;
    }

    function setBot(address bot, bool value) external onlyOwner {
        _isBot[bot] = value;
    }

    function setAntiBotBlocks(uint256 numberOfBlocks) external onlyOwner {
        antiBotBlocks = numberOfBlocks;
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "Fort: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    ////////////////////////
    // Transfer Functions //
    ////////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBot[from] && !_isBot[to], "C:\\<windows95\\system32> kill bot");
        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(tradingEnabled, "Trading no active");
            if (!automatedMarketMakerPairs[to]) {
                require(
                    balanceOf(to) + (amount) <= maxWalletBalance,
                    "Balance is exceeding maxWalletBalance"
                );
            }
            if (!automatedMarketMakerPairs[from] && balanceOf(from) >= coolDownBalance) {
                uint256 timePassed = block.timestamp - lastSell[from];
                require(timePassed > coolDownTime, "Cooldown is active. Please wait");
                lastSell[from] = block.timestamp;
            }
            if (automatedMarketMakerPairs[from]) {
                require(amount <= maxBuyAmount, "You are exceeding maxBuyAmount");
            }
            if (!automatedMarketMakerPairs[from]) {
                require(amount <= maxSellAmount, "You are exceeding maxSellAmount");
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        uint256 swapTax = sellTaxes.rewards +
            sellTaxes.marketing +
            sellTaxes.liquidity +
            sellTaxes.dev +
            sellTaxes.operations +
            sellTaxes.buyback;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            if (swapTax > 0) {
                swapAndLiquify(swapTokensAtAmount, swapTax);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            bool beforeTradingFee = block.number <= startTradingBlock + antiBotBlocks;
            uint256 swapAmt;
            if (automatedMarketMakerPairs[to] && !beforeTradingFee) {
                swapAmt = (amount * swapTax) / 100;
            } else if (automatedMarketMakerPairs[from] && !beforeTradingFee) {
                swapAmt =
                    (amount *
                        (buyTaxes.rewards +
                            buyTaxes.marketing +
                            buyTaxes.liquidity +
                            buyTaxes.dev +
                            buyTaxes.operations +
                            buyTaxes.buyback)) /
                    100;
            } else if (beforeTradingFee) {
                swapAmt = (amount * launchtax) / 100;
            }

            amount = amount - (swapAmt);
            super._transfer(from, address(this), swapAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}

        if (!swapping) {
            try dividendTracker.process() returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    tx.origin
                );
            } catch {}
        }
    }

    function swapAndLiquify(uint256 tokens, uint256 swapTax) private {
        // Split the contract balance into halves
        uint256 denominator = swapTax * 2;
        uint256 tokensToAddLiquidityWith = (tokens * sellTaxes.liquidity) / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForBNB(toSwap);

        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance = deltaBalance / (denominator - sellTaxes.liquidity);
        uint256 bnbToAddLiquidityWith = unitBalance * sellTaxes.liquidity;

        if (bnbToAddLiquidityWith > 0) {
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
        }

        // Send BNB to marketingWallet
        uint256 marketingWalletAmt = unitBalance * 2 * sellTaxes.marketing;
        if (marketingWalletAmt > 0) {
            payable(marketingWallet).sendValue(marketingWalletAmt);
        }
        // Send BNB to operations
        uint256 operationsAmt = unitBalance * 2 * sellTaxes.operations;
        if (operationsAmt > 0) {
            payable(operationsWallet).sendValue(operationsAmt);
        }

        // Send BNB to buyback
        uint256 buybackAmt = unitBalance * 2 * sellTaxes.buyback;
        if (buybackAmt > 0) {
            payable(buybackWallet).sendValue(buybackAmt);
        }

        // Send BNB to dev
        uint256 devAmt = unitBalance * 2 * sellTaxes.dev;
        if (devAmt > 0) {
            payable(devWallet).sendValue(devAmt);
        }
        // Send BNB to rewardsContract
        uint256 dividends = unitBalance * 2 * sellTaxes.rewards;
        if (dividends > 0) {
            (bool success, ) = address(dividendTracker).call{ value: dividends }("");
            if (success) emit SendDividends(tokens, dividends);
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityAVAX{ value: ethAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}