// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./PaymentSplitter.sol";
import "./INodeManager.sol";
import "./IJoeRouter02.sol";
import "./IJoeFactory.sol";

pragma solidity 0.8.4;

contract VaporNodes is ERC20, Ownable, PaymentSplitter {
    using SafeMath for uint256;

    address public joePair;
    address public joeRouterAddress = 0x2D99ABD9008Dc933ff5c0CD271B88309593aB921; // TraderJoe Router

    address public teamPool;
    address public rewardsPool;

    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public teamPoolFee;
    uint256 public cashoutFee;
    uint256 public totalFees;
    uint256 public antiWhale = 75000;
    uint256 public amount_ = 10000000000000000000000000000000000000;

    uint256 public swapTokensAmount;
    uint256 public totalClaimed = 0;
    bool public isTradingEnabled = true;
    bool public swapLiquifyEnabled = true;

    IJoeRouter02 private joeRouter;
    INodeManager private nodeManager;
    uint256 private rwSwap;
    bool private swapping = false;

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateJoeRouter(
        address indexed newAddress,
        address indexed oldAddress
    );

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(
        address indexed newLiquidityWallet,
        address indexed oldLiquidityWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event Cashout(
        address indexed account,
        uint256 amount,
        uint256 indexed blockTime
    );

    event Compound(
        address indexed account,
        uint256 amount,
        uint256 indexed blockTime
    );
        // Anti Whale
    function _beforeTokenTransfer(address from, address, uint256 amount) internal view override {
        require(amount <= antiWhale*10**18 || !automatedMarketMakerPairs[from], "You are not permitted to transfer more than 100,000 tokens");
    }
    
    constructor(
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory fees,
        uint256 swapAmount
    )
        ERC20("VaporNodes", "VPND")
        PaymentSplitter(payees, shares)
    {
        require(
            addresses[0] != address(0) && addresses[1] != address(0) && addresses[2] != address(0),
            "CONSTR:1"
        );
        teamPool = addresses[0];
        rewardsPool = addresses[1];
        nodeManager = INodeManager(addresses[2]);

        require(joeRouterAddress != address(0), "CONSTR:2");
        IJoeRouter02 _joeRouter = IJoeRouter02(joeRouterAddress);

        address _joePair = IJoeFactory(_joeRouter.factory())
        .createPair(address(this), _joeRouter.WAVAX());

        joeRouter = _joeRouter;
        joePair = _joePair;

        _setAutomatedMarketMakerPair(_joePair, true);

        require(
            fees[0] != 0 && fees[1] != 0 && fees[2] != 0 && fees[3] != 0,
            "CONSTR:3"
        );
        teamPoolFee = fees[0];
        rewardsFee = fees[1];
        liquidityPoolFee = fees[2];
        cashoutFee = fees[3];
        rwSwap = fees[4];

        totalFees = rewardsFee.add(liquidityPoolFee).add(teamPoolFee);

        require(swapAmount > 0, "CONSTR:7");
        swapTokensAmount = swapAmount * (10**18);
    }

    function migrate(address[] memory addresses_, uint256[] memory balances_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
            _mint(addresses_[i], balances_[i]);
        }
    }
    
    function updateNodePrice(uint256 value) external onlyOwner {
        amount_ = value;
    }
    
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function updateJoeRouterAddress(address newAddress) external onlyOwner {
        require(
            newAddress != address(joeRouter),
            "TKN:1"
        );
        emit UpdateJoeRouter(newAddress, address(joeRouter));
        IJoeRouter02 _joeRouter = IJoeRouter02(newAddress);
        address _joePair = IJoeFactory(joeRouter.factory()).createPair(
            address(this),
            _joeRouter.WAVAX()
        );
        joePair = _joePair;
        joeRouterAddress = newAddress;
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateTeamPool(address payable newVal) external onlyOwner {
        teamPool = newVal;
    }

    function updateRewardsPool(address payable newVal) external onlyOwner {
        rewardsPool = newVal;
    }

    function updateRewardsFee(uint256 newVal) external onlyOwner {
        rewardsFee = newVal;
        totalFees = rewardsFee.add(liquidityPoolFee).add(teamPoolFee);
    }

    function updateLiquidityFee(uint256 newVal) external onlyOwner {
        liquidityPoolFee = newVal;
        totalFees = rewardsFee.add(liquidityPoolFee).add(teamPoolFee);
    }

    function updateTeamFee(uint256 newVal) external onlyOwner {
        teamPoolFee = newVal;
        totalFees = rewardsFee.add(liquidityPoolFee).add(teamPoolFee);
    }

    function updateCashoutFee(uint256 newVal) external onlyOwner {
        cashoutFee = newVal;
    }

    function updateRwSwapFee(uint256 newVal) external onlyOwner {
        rwSwap = newVal;
    }

    function updateSwapLiquify(bool newVal) external onlyOwner {
        swapLiquifyEnabled = newVal;
    }

    function updateIsTradingEnabled(bool newVal) external onlyOwner {
        isTradingEnabled = newVal;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != joePair,
            "TKN:2"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value)
        external
        onlyOwner
    {
        isBlacklisted[account] = value;
    }

    // Private methods

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN:3"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "BLACKLISTED"
        );
        require(from != address(0), "ERC20:1");
        _beforeTokenTransfer(from, to, amount);
        require(to != address(0), "ERC20:2");
        if (from != owner() && to != joePair && to != address(joeRouter) && to != address(this) && from != address(this)) {
            require(isTradingEnabled, "TRADING_DISABLED");
        }
        super._transfer(from, to, amount);
    }

    function swapAndSendToFee(address destination, uint256 tokens) private {
        uint256 initialAVAXBalance = address(this).balance;

        swapTokensForAVAX(tokens);
        uint256 newBalance = (address(this).balance).sub(initialAVAXBalance);
        payable(destination).transfer(newBalance);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForAVAX(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForAVAX(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();

        _approve(address(this), address(joeRouter), tokenAmount);

        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of AVAX
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(joeRouter), tokenAmount);

        // add the liquidity
        joeRouter.addLiquidityAVAX{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    // External node methods

    function createNodeWithTokens(string memory name, uint256 amount_) external {
        address sender = _msgSender();
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NC:1"
        );
        require(
            sender != address(0),
            "NC:2"
        );
        require(!isBlacklisted[sender], "BLACKLISTED");
        require(
            sender != teamPool && sender != rewardsPool,
            "NC:4"
        );
        require(
            balanceOf(sender) >= amount_,
            "NC:5"
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquifyEnabled &&
            !swapping &&
            sender != owner() &&
            !automatedMarketMakerPairs[sender]
        ) {
            swapping = true;

            uint256 teamTokens = contractTokenBalance
                .mul(teamPoolFee)
                .div(100);

            swapAndSendToFee(teamPool, teamTokens);

            uint256 rewardsPoolTokens = contractTokenBalance
                .mul(rewardsFee)
                .div(100);

            uint256 rewardsTokenstoSwap = rewardsPoolTokens.mul(rwSwap).div(
                100
            );

            swapAndSendToFee(rewardsPool, rewardsTokenstoSwap);

            super._transfer(
                address(this),
                rewardsPool,
                rewardsPoolTokens.sub(rewardsTokenstoSwap)
            );

            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(
                100
            );

            swapAndLiquify(swapTokens);
            swapTokensForAVAX(balanceOf(address(this)));

            swapping = false;
        }
        super._transfer(sender, address(this), amount_);
        nodeManager.createNode(sender, name, amount_);
    }

    function cashoutReward(uint256 blocktime) external {
        address sender = _msgSender();
        require(
            sender != address(0),
            "CASHOUT:1"
        );
        require(
            !isBlacklisted[sender],
            "BLACKLISTED"
        );
        require(
            sender != teamPool && sender != rewardsPool,
            "CASHOUT:3"
        );
        uint256 rewardAmount = nodeManager.getNodeReward(sender, blocktime);
        require(
            rewardAmount > 0,
            "CASHOUT:4"
        );

        if (swapLiquifyEnabled) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(rewardsPool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(rewardsPool, sender, rewardAmount);
        nodeManager.cashoutNodeReward(sender, blocktime);
        totalClaimed += rewardAmount;

        emit Cashout(sender, rewardAmount, blocktime);
    }

    function cashoutAll() external {
        address sender = _msgSender();
        require(
            sender != address(0),
            "CASHOUT:5"
        );
        require(
            !isBlacklisted[sender],
            "BLACKLISTED"
        );
        require(
            sender != teamPool && sender != rewardsPool,
            "CASHOUT:7"
        );
        uint256 rewardAmount = nodeManager.getAllNodesRewards(sender);
        require(
            rewardAmount > 0,
            "CASHOUT:8"
        );
        if (swapLiquifyEnabled) {
            uint256 feeAmount;
            if (cashoutFee > 0) {
                feeAmount = rewardAmount.mul(cashoutFee).div(100);
                swapAndSendToFee(rewardsPool, feeAmount);
            }
            rewardAmount -= feeAmount;
        }
        super._transfer(rewardsPool, sender, rewardAmount);
        nodeManager.cashoutAllNodesRewards(sender);
        totalClaimed += rewardAmount;

        emit Cashout(sender, rewardAmount, 0);
    }

    function compoundNodeRewards(uint256 blocktime) external {
        address sender = _msgSender();
        require(
            sender != address(0),
            "COMP:1"
        );
        require(
            !isBlacklisted[sender],
            "BLACKLISTED"
        );
        require(
            sender != teamPool && sender != rewardsPool,
            "COMP:2"
        );
        uint256 rewardAmount = nodeManager.getNodeReward(sender, blocktime);
        require(
            rewardAmount > 0,
            "COMP:3"
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquifyEnabled &&
            !swapping &&
            sender != owner() &&
            !automatedMarketMakerPairs[sender]
        ) {
            swapping = true;

            uint256 teamTokens = contractTokenBalance
                .mul(teamPoolFee)
                .div(100);

            swapAndSendToFee(teamPool, teamTokens);

            uint256 rewardsPoolTokens = contractTokenBalance
                .mul(rewardsFee)
                .div(100);

            uint256 rewardsTokenstoSwap = rewardsPoolTokens.mul(rwSwap).div(
                100
            );

            swapAndSendToFee(rewardsPool, rewardsTokenstoSwap);

            super._transfer(
                address(this),
                rewardsPool,
                rewardsPoolTokens.sub(rewardsTokenstoSwap)
            );

            uint256 swapTokens = contractTokenBalance.mul(liquidityPoolFee).div(
                100
            );

            swapAndLiquify(swapTokens);
            swapTokensForAVAX(balanceOf(address(this)));

            swapping = false;
        }
        super._transfer(rewardsPool, address(this), rewardAmount);
        nodeManager.compoundNodeReward(sender, blocktime, rewardAmount);

        emit Compound(sender, rewardAmount, blocktime);
    }
}