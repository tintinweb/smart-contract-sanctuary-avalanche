// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./NODERewardManagementV2.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IJoeRouter02.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MTestV2 is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    NODERewardManagementV2 public nodeRewardManager;
    IJoeRouter02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public treasury;
    uint256 public rewardsFee;          // 100 = 1.00%
    uint256 public liquidityPoolFee;    // 100 = 1.00%
    uint256 public rewardsPool;         // available balance for rewards

    uint256 public sellFee;             // 100 = 1.00%
    uint256 public buyFee;              // 100 = 1.00%
    uint256 public maxSellFee;
    uint256 public maxBuyFee;

    uint256 public rwSwap;              // 100 = 1.00%; percent of rewards to swap to AVAX
    bool private swapping;
    bool public swapAndLiquifyEnabled;
    uint256 public swapTokensAmount;
    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public  automatedMarketMakerPairs;
    mapping (address => bool) private isExcludedFromFee;

    struct FeeRecipient {
        address recipient;
        uint256 basisPoints;
        bool sellToNative;
    }

    mapping(uint256 => FeeRecipient) public FeeRecipients;
    uint256 feeRecipientCount;
    uint256 totalFeeBasisPoints;
    uint256 totalFeeBasisPointsToSwap;
    bool isOpen;
    mapping(address => address) public Referrals;
    mapping(address => uint256) public ReferralIncome;
    uint256 public referralRateForBuySell;          // 100 = 1.00%
    uint256 public referralRateForNodeCreation;     // 100 = 1.00%
    uint256 public referralRateForNodeRewards;      // 100 = 1.00%
    uint256 public minTokensForReferral;
    uint256 public minNodesForReferral;

    uint256 public nodeCreateProcessFee;            // 100 = 1.00%
    address public nodeCreateProcessFeeRecipient;   // stabilator contract0
    uint256 public rewardProcessFee;                // 100 = 1.00%
    address public rewardProcessFeeRecipient;       // stabilator contract0
    uint256 public totalProcessFees;

    address public uniswapV2PairForSwap;
    address public uniswapV2RouterForSwap;
    bool public useSwapExactTokensForAVAXSupportingFeeOnTransferTokensForSwap;
    address public uniswapV2PairForLiquidity;
    address public uniswapV2RouterForLiquidity;
    bool public useSwapExactTokensForAVAXSupportingFeeOnTransferTokensForLiquidity;

    function initialize(address _treasury, address[] memory addresses, 
        uint256[] memory basisPoints, bool[] memory sellToNative, uint256 swapAmount,
        uint256 _rewardsFee, uint256 _liquidityPoolFee, uint256 _sellFee, uint256 _buyFee,
        bool _swapAndLiquifyEnabled) public initializer 
    {
        require(_treasury != address(0), "TREASURY_IS_0");
        require(addresses.length == basisPoints.length && basisPoints.length == sellToNative.length, "ARRAY_LENGTH_MISTMATCH");        
        require(_sellFee < 2001, "SELLFEE_>2000");
        require(_buyFee < 2001, "BUYFEE_>2000");
        __ERC20_init("MTestV2", "MTestV2");
        OwnableUpgradeable.__Ownable_init();
        
        for(uint256 x; x < addresses.length; x++) {
            FeeRecipients[feeRecipientCount].recipient = addresses[x];
            FeeRecipients[feeRecipientCount].basisPoints = basisPoints[x];
            FeeRecipients[feeRecipientCount].sellToNative = sellToNative[x];
            feeRecipientCount++;
            totalFeeBasisPoints += basisPoints[x];
            totalFeeBasisPointsToSwap += sellToNative[x] ? basisPoints[x] : 0;
            isExcludedFromFee[addresses[x]] = true;
        }

        treasury = _treasury;

        rewardsFee = _rewardsFee; 
        liquidityPoolFee = _liquidityPoolFee; 
        sellFee = _sellFee; 
        buyFee = _buyFee;
        maxBuyFee = _buyFee;
        maxSellFee = _sellFee;

        _mint(treasury, 250000000 * (10 ** 18));

        require(swapAmount > 0, "SWAP_IS_ZERO");
        swapTokensAmount = swapAmount * (10**18);
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
    }

    receive() external payable { }

    /***** ERC20 TRANSFERS *****/

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _spendAllowance(sender, _msgSender(), amount);
        _transfer(sender, recipient, amount);        
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(isOpen || from == owner() || to == owner() ||
            proxyToApproved[from] || proxyToApproved[to], "NOT_OPEN");        
        require(from != address(0), "FROM_IS_ZERO");
        require(to != address(0), "TO_IS_ZERO");
        require(from == owner() || to == owner() || (!isBlacklisted[from] && !isBlacklisted[to]), "BLACKLISTED");

        uint256 fee;
        address referral;
        bool isBuyOrSell;
        uint256 transferAmount = amount;

        //sell
        if (!isExcludedFromFee[from] &&  automatedMarketMakerPairs[to]) {
            require(nodeRewardManager._isNodeOwner(from), "MUST_HAVE_BRAIN");
            fee = sellFee;
            referral = Referrals[from];
            isBuyOrSell = true;
        }

        //buy
        if (!isExcludedFromFee[to] &&  automatedMarketMakerPairs[from]) {
            fee = buyFee;
            referral = Referrals[to];
            isBuyOrSell = true;
        }

        if (fee > 0) {
            uint256 feeAmount = amount * fee / 10000;
            transferAmount -= feeAmount;
            super._transfer(from, address(this), feeAmount);
        }
        // referral
        if (isBuyOrSell && referralRateForBuySell > 0) {
            referral = referral == address(0) || balanceOf(referral) < minTokensForReferral
                ||nodeRewardManager._getNodeNumberOf(referral) < minNodesForReferral
                ? address(this) : referral;
            uint256 referralAmount = amount * referralRateForBuySell / 10000;
            ReferralIncome[referral] += referralAmount;
            transferAmount -= referralAmount;
            super._transfer(from, referral, referralAmount);
        }

        super._transfer(from, to, transferAmount);
    }

    /***** MUTATIVE *****/

    function setReferral(address referral) external {
        require(_msgSender() != referral, "SAME_ADDRESS");
        Referrals[_msgSender()] = referral;
    }

    /***** OWNER ONLY *****/

    function openTrading() external onlyOwner {
        require(isOpen != true, "ALREADY_OPEN");
        isOpen = true;
    }

    /*** referrals ***/

    function setMinTokensForReferral(uint256 amount) external onlyOwner {
        minTokensForReferral = amount;
    }

    function setMinNodesForReferral(uint256 amount) external onlyOwner {
        minNodesForReferral = amount;
    }

    function setReferralRateForBuySell(uint256 value) external onlyOwner {
        require(value < 1001, "VALUE>1000");
        maxBuyFee = maxBuyFee - referralRateForBuySell + value;
        maxSellFee = maxSellFee - referralRateForBuySell + value;
        referralRateForBuySell = value;
    }

    function setReferralRateForNodeCreation(uint256 value) external onlyOwner {
        require(value < 1001, "VALUE>1000");
        referralRateForNodeCreation = value;
    }

    function setReferralRateForNodeRewards(uint256 value) external onlyOwner {
        require(value < 1001, "VALUE>1000");
        referralRateForNodeRewards = value;
    }

    /*** process fee (stabilators) ***/
    // 100 = 1.00%
    function setProcessFeeConfig(uint256 _nodeCreateProcessFee, uint256 _rewardProcessFee) external onlyOwner {
        require(_nodeCreateProcessFee < 1001, "VALUE>1000");
        require(_rewardProcessFee < 1001, "VALUE>1000");
        nodeCreateProcessFee = _nodeCreateProcessFee; 
        rewardProcessFee = _rewardProcessFee;        
    }

    function addFeeRecipient(address recipient, uint256 basisPoints, bool sellToNative) external onlyOwner {
        FeeRecipients[feeRecipientCount].recipient = recipient;
        FeeRecipients[feeRecipientCount].basisPoints = basisPoints;
        FeeRecipients[feeRecipientCount].sellToNative = sellToNative;
        feeRecipientCount++;
        totalFeeBasisPoints += basisPoints;
        totalFeeBasisPointsToSwap += sellToNative ? basisPoints : 0;
    }

    function editFeeRecipient(uint256 id, address recipient, uint256 basisPoints, bool sellToNative) external onlyOwner {
        require(id < feeRecipientCount, "INVALID_ID");
        totalFeeBasisPoints = totalFeeBasisPoints - FeeRecipients[id].basisPoints + basisPoints;
        totalFeeBasisPointsToSwap -= FeeRecipients[id].sellToNative ? FeeRecipients[id].basisPoints : 0;
        totalFeeBasisPointsToSwap += sellToNative ? basisPoints : 0;
        FeeRecipients[id].recipient = recipient;
        FeeRecipients[id].basisPoints = basisPoints;
        FeeRecipients[id].sellToNative = sellToNative;
    }

    function setNodeManagement(address nodeManagement) external onlyOwner {
        nodeRewardManager = NODERewardManagementV2(nodeManagement);
    }

    function updateSwapTokensAmount(uint256 value) external onlyOwner {
        swapTokensAmount = value;
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "ADDRESS_IS_0");
        treasury = _treasury;
    }

    // 1000 = 10.00%
    function updateRewardsFee(uint256 value) external onlyOwner {
        require(value < 101, "VALUE>100");
        rewardsFee = value;
    }

    // 1000 = 10.00%
    function updateLiquidityPoolFee(uint256 value) external onlyOwner {
        require(value < 2001, "VALUE>2000");
        liquidityPoolFee = value;
    }

    // 1000 = 10.00%
    function updateSellFee(uint256 value) external onlyOwner {
        require(value < 2001, "VALUE>2000");
        maxSellFee = maxSellFee - sellFee + value;
        sellFee = value;
    }

    // 1000 = 10.00%
    function updateBuyFee(uint256 value) external onlyOwner {
        require(value < 2001, "VALUE>2000");
        maxBuyFee = maxBuyFee - buyFee + value;
        buyFee = value;
    }

    // 1000 = 10.00%
    function updateRwSwapFee(uint256 value) external onlyOwner {
        rwSwap = value;
    }

    function blacklistMalicious(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;
    }

    function excludedFromFee(address _address) external view returns(bool) {
        return isExcludedFromFee[_address];
    }

    function setExcludedFromFee(address account, bool value) external onlyOwner {
        isExcludedFromFee[account] = value;
    }

    function setSwapAndLiquifyEnabled(bool newVal) external onlyOwner {
        swapAndLiquifyEnabled = newVal;
    }

    function setProxyState(address proxyAddress, bool value) external onlyOwner {
        proxyToApproved[proxyAddress] = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(automatedMarketMakerPairs[pair] != value, "AMM_ALREADY_SET");
        automatedMarketMakerPairs[pair] = value;  
        isExcludedFromFee[pair] = value;      
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setSwapPairAndRouter(address pair, address router, bool _useSwapExactTokensForAVAXSupportingFeeOnTransferTokens) external onlyOwner {
        require(pair != address(0), "PAIR_IS_ZERO");
        require(router != address(0), "ROUTER_IS_ZERO");
        uniswapV2PairForSwap = pair;
        uniswapV2RouterForSwap = router;
        isExcludedFromFee[router] = true;
        useSwapExactTokensForAVAXSupportingFeeOnTransferTokensForSwap = _useSwapExactTokensForAVAXSupportingFeeOnTransferTokens;
    }

    function setLiquidityPairAndRouter(address pair, address router, bool _useSwapExactTokensForAVAXSupportingFeeOnTransferTokens) external onlyOwner {
        require(pair != address(0), "PAIR_IS_ZERO");
        require(router != address(0), "ROUTER_IS_ZERO");
        uniswapV2PairForLiquidity = pair;
        uniswapV2RouterForLiquidity = router;
        isExcludedFromFee[router] = true;
        useSwapExactTokensForAVAXSupportingFeeOnTransferTokensForLiquidity = _useSwapExactTokensForAVAXSupportingFeeOnTransferTokens;
    }

    function manualSwapAndLiquify() external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this)) >  rewardsPool 
            ?  balanceOf(address(this)) -  rewardsPool : 0;

        // amount for rewards
        uint256 rewardAmount = contractTokenBalance * rewardsFee / 10000;
        uint256 rewardAmountToSwap = rewardAmount * rwSwap / 10000;
        uint256 liquidityAmount = contractTokenBalance * liquidityPoolFee / 10000;
        uint256 liquidityAmountToSwap = liquidityAmount / 2;
        uint256 remainder = contractTokenBalance - rewardAmount - liquidityAmount;
        uint256 remainderToSwap = totalFeeBasisPoints > 0
            ? remainder * totalFeeBasisPointsToSwap / totalFeeBasisPoints
            : 0;
        uint256 totalAmountToSwap = rewardAmountToSwap + liquidityAmountToSwap + remainderToSwap;
        uint256 receivedAVAX = _swap(totalAmountToSwap);

        // add liquidity
        if (totalAmountToSwap > 0) {
            _addLiquidity(liquidityAmountToSwap, receivedAVAX * liquidityAmountToSwap / totalAmountToSwap);
        }

        // send to fee recipients
        uint256 remainderAVAX = totalAmountToSwap > 0
            ? receivedAVAX * remainderToSwap / totalAmountToSwap
            : 0;
        uint256 remainderAVAXBalance = remainderAVAX;
        remainder -= remainderToSwap;
        uint256 totalFeeBasisPointsNotToSwap = totalFeeBasisPoints - totalFeeBasisPointsToSwap;
        uint256 remainderBalance = remainder;
        for(uint256 x; x < feeRecipientCount; x++) {
            if (FeeRecipients[x].sellToNative) {
                uint256 amount = totalFeeBasisPointsToSwap > 0
                    ? remainderAVAX * FeeRecipients[x].basisPoints / totalFeeBasisPointsToSwap
                    : 0;
                amount = amount > remainderAVAXBalance ? remainderAVAXBalance : amount;
                (bool sent, bytes memory data) = FeeRecipients[x].recipient.call{value: amount}("");
                require(sent, "FAILED_TO_SEND");
                remainderAVAXBalance -= amount;
            } else {
                uint256 amount = totalFeeBasisPointsNotToSwap > 0
                    ? remainder * FeeRecipients[x].basisPoints / totalFeeBasisPointsNotToSwap
                    : 0;
                amount = amount > remainderBalance ? remainderBalance : amount;
                super._transfer(address(this),FeeRecipients[x].recipient, amount);
                remainderBalance -= amount;
            }
        }
        rewardsPool = balanceOf(address(this));
        emit ManualSwapAndLiquify(_msgSender(), contractTokenBalance);
    }   

    function withdrawAVAX() external nonReentrant onlyApproved {
        require(treasury != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        (bool sent, ) = treasury.call{value: bal}("");
        require(sent, "FAILED_SENDING_FUNDS");
        emit WithdrawAVAX(_msgSender(), bal);
    }

    function withdrawTokens(address _token) external nonReentrant onlyApproved {
        require(treasury != address(0), "TREASURY_NOT_SET");
        IERC20Upgradeable(_token).safeTransfer(
            treasury,
            IERC20Upgradeable(_token).balanceOf(address(this))
        );
    }

    /***** PRIVATE *****/

    function _swap(uint256 tokens) private returns(uint256) {
        uint256 initialETHBalance = address(this).balance;
        _swapTokensForEth(tokens);
        return (address(this).balance) - (initialETHBalance);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IRouter(uniswapV2RouterForSwap).WAVAX();

        _approve(address(this), address(uniswapV2RouterForSwap), tokenAmount);

        if (useSwapExactTokensForAVAXSupportingFeeOnTransferTokensForSwap) {
            IRouter(uniswapV2RouterForSwap).swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        } else {
            IRouter(uniswapV2RouterForSwap).swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        if (tokenAmount == 0 || ethAmount == 0) return;
        // approve token transfer to cover all possible scenarios
        _approve(address(this), uniswapV2RouterForLiquidity, tokenAmount);

        // add the liquidity
        if (useSwapExactTokensForAVAXSupportingFeeOnTransferTokensForLiquidity) {
            IRouter(uniswapV2RouterForLiquidity).addLiquidityAVAX{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                treasury,
                block.timestamp
            );
        } else {
            IRouter(uniswapV2RouterForLiquidity).addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                treasury,
                block.timestamp
            );        
        }
    }

    function _toString(uint256 value) internal pure returns (bytes memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return buffer;
    }

    /***** MUTATIVE (NODE) *****/

    function createNodeWithTokens(string memory name) public {
        require(bytes(name).length > 3 && bytes(name).length < 32, "NAME_SIZE_INVALID");
        require(!isBlacklisted[_msgSender()], "BLACKLISTED");
        require(balanceOf(_msgSender()) >= nodeRewardManager.nodePrice(), "INSUFFICIENT_BALANCE");

        // referral
        uint256 referralAmount;
        if (referralRateForNodeCreation > 0) {
            address referral = Referrals[_msgSender()] == address(0) || balanceOf(Referrals[_msgSender()]) < minTokensForReferral
                || nodeRewardManager._getNodeNumberOf(Referrals[_msgSender()]) < minNodesForReferral 
                ? address(this) : Referrals[_msgSender()];
            referralAmount = nodeRewardManager.nodePrice() * referralRateForNodeCreation / 10000;
            if (referralAmount > 0) {
                ReferralIncome[referral] += referralAmount;
                IERC20Upgradeable(address(this)).safeTransferFrom(_msgSender(), referral, referralAmount);
            }
        }
        // validator
        uint256 processFee;
        if (nodeCreateProcessFee > 0 && nodeCreateProcessFeeRecipient != address(0)) {
            processFee = nodeRewardManager.nodePrice() * nodeCreateProcessFee / 10000;
            if (processFee > 0) {
                totalProcessFees += processFee;
                IERC20Upgradeable(address(this)).safeTransferFrom(_msgSender(), nodeCreateProcessFeeRecipient, processFee);
            }
        }

        IERC20Upgradeable(address(this)).safeTransferFrom(_msgSender(), address(this), nodeRewardManager.nodePrice() - referralAmount - processFee);
        nodeRewardManager.createNode(_msgSender(), name);

        uint256 contractTokenBalance = balanceOf(address(this)) >  rewardsPool 
            ?  balanceOf(address(this)) -  rewardsPool : 0;
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapAndLiquifyEnabled &&
            !swapping &&
            _msgSender() != owner() &&
            !automatedMarketMakerPairs[_msgSender()]
        ) {
            swapping = true;
            // amount for rewards
            uint256 rewardAmount = contractTokenBalance * rewardsFee / 10000;
            uint256 liquidityAmount = contractTokenBalance * liquidityPoolFee / 10000;
            uint256 liquidityAmountToSwap = liquidityAmount / 2;
            uint256 remainder = contractTokenBalance - rewardAmount - liquidityAmount;
            uint256 remainderToSwap = totalFeeBasisPoints > 0 
                ? remainder * totalFeeBasisPointsToSwap / totalFeeBasisPoints
                : 0;
            uint256 totalAmountToSwap = (rewardAmount * rwSwap / 10000) + liquidityAmountToSwap + remainderToSwap;
            uint256 receivedAVAX = _swap(totalAmountToSwap);

            // add liquidity
            if (totalAmountToSwap > 0) {
                _addLiquidity(liquidityAmountToSwap, receivedAVAX * liquidityAmountToSwap / totalAmountToSwap);
            }

            // send to fee recipients
            uint256 remainderAVAX = totalAmountToSwap > 0
                ? receivedAVAX * remainderToSwap / totalAmountToSwap
                : 0;
            uint256 remainderAVAXBalance = remainderAVAX;
            remainder -= remainderToSwap;
            uint256 totalFeeBasisPointsNotToSwap = totalFeeBasisPoints - totalFeeBasisPointsToSwap;
            uint256 remainderBalance = remainder;
            for(uint256 x; x < feeRecipientCount; x++) {
                if (FeeRecipients[x].sellToNative) {
                    uint256 amount = totalFeeBasisPointsToSwap > 0
                        ? remainderAVAX * FeeRecipients[x].basisPoints / totalFeeBasisPointsToSwap
                        : 0;
                    amount = amount > remainderAVAXBalance ? remainderAVAXBalance : amount;
                    (bool sent, bytes memory data) = FeeRecipients[x].recipient.call{value: amount}("");
                    require(sent, "FAILED_TO_SEND");
                    remainderAVAXBalance -= amount;
                } else {
                    uint256 amount = totalFeeBasisPointsNotToSwap > 0
                        ? remainder * FeeRecipients[x].basisPoints / totalFeeBasisPointsNotToSwap
                        : 0;
                    amount = amount > remainderBalance ? remainderBalance : amount;
                    super._transfer(address(this), FeeRecipients[x].recipient, amount);
                    remainderBalance -= amount;
                }
            }
            // all non-reward tokens removed. Remainder is rewards pool
            rewardsPool = balanceOf(address(this));
            swapping = false;
        }
        emit CreateNodeWithTokens(_msgSender(), name);
    }

    function setNodeCreateProcessFeeRecipient(address value) external onlyOwner {
        nodeCreateProcessFeeRecipient = value;
        emit SetNodeCreateProcessFeeRecipient(_msgSender(), value);
    }

    function setRewardProcessFeeRecipient(address value) external onlyOwner {
        rewardProcessFeeRecipient = value;
        emit SetRewardProcessFeeRecipient(_msgSender(), value);
    }

    function addToRewardsPool(uint256 amount) external onlyApproved {
        transfer(address(this), amount);
        rewardsPool += amount;
        emit AddRewardsToPool(_msgSender(), amount);
    }

    function removeFromRewardsPool(uint256 amount) external onlyApproved {
        require(rewardsPool > 0 && rewardsPool >= amount, "INSUFFICIENT_REWARDS");
        rewardsPool -= amount;    
        _transfer(address(this), treasury, amount);
        emit RemoveFromRewardsPool(address(this), amount);
    }

    function cashoutReward(uint256 blocktime) external {
        require(!isBlacklisted[_msgSender()], "BLACKLISTED");
        require(_msgSender() != treasury, "TREASURY_CANNOT_CASHOUT");
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(_msgSender(), blocktime);
        require(rewardAmount > 0, "NO_REWARDS");
        nodeRewardManager._cashoutNodeReward(_msgSender(), blocktime);

        //referral
        uint256 referralAmount;
        if (referralRateForNodeRewards > 0) {
            address referral = Referrals[_msgSender()] == address(0)  || balanceOf(Referrals[_msgSender()]) < minTokensForReferral
                || nodeRewardManager._getNodeNumberOf(Referrals[_msgSender()]) < minNodesForReferral
                ? address(this) : Referrals[_msgSender()];
            referralAmount = rewardAmount * referralRateForNodeRewards / 10000;
            if (referralAmount > 0) {
                ReferralIncome[referral] += referralAmount;
                IERC20Upgradeable(address(this)).safeTransfer(referral, referralAmount);
            }
        }
        //validator
        uint256 processFee;
        if (rewardProcessFee > 0 && rewardProcessFeeRecipient != address(0)) {
            processFee = rewardAmount * rewardProcessFee / 10000;
            if (processFee > 0) {
                totalProcessFees += processFee;
                IERC20Upgradeable(address(this)).safeTransfer(rewardProcessFeeRecipient, processFee);
            }
        }

        IERC20Upgradeable(address(this)).safeTransfer(_msgSender(), rewardAmount - referralAmount - processFee);
        rewardsPool -= rewardAmount;
        emit CashoutReward(_msgSender(), rewardAmount);
    }

    function cashoutAll() public {
        require(!isBlacklisted[_msgSender()], "BLACKLISTED");
        require(_msgSender() != treasury, "TREASURY_NOT_ALLOWED");
        uint256 rewardAmount = nodeRewardManager._getRewardAmountOf(_msgSender());
        require(rewardAmount > 0, "NO_REWARDS");
        nodeRewardManager._cashoutAllNodesReward(_msgSender());

        uint256 referralAmount;
        //referral
        if (referralRateForNodeRewards > 0) {
            address referral = Referrals[_msgSender()] == address(0) || balanceOf(Referrals[_msgSender()]) < minTokensForReferral
                || nodeRewardManager._getNodeNumberOf(Referrals[_msgSender()]) < minNodesForReferral
                ? address(this) : Referrals[_msgSender()];
            referralAmount = rewardAmount * referralRateForNodeRewards / 10000;
            if (referralAmount > 0) {
                ReferralIncome[referral] += referralAmount;
                IERC20Upgradeable(address(this)).safeTransfer(referral, referralAmount);
            }
        }
        uint256 processFee;
        //validator
        if (rewardProcessFee > 0 && rewardProcessFeeRecipient != address(0)) {
            processFee = rewardAmount * rewardProcessFee / 10000;
            if (processFee > 0) { 
                totalProcessFees += processFee;
                IERC20Upgradeable(address(this)).safeTransfer(rewardProcessFeeRecipient, processFee);
            }
        }
        IERC20Upgradeable(address(this)).safeTransfer(_msgSender(), rewardAmount - referralAmount - processFee);
        rewardsPool -= rewardAmount;
        emit CashoutAll(_msgSender(), rewardAmount);
    }

    function compound(uint256 amount) external {
        require(amount > 0, "AMOUNT_IS_ZERO");
        uint256 nodePrice = nodeRewardManager.nodePrice();
        require(amount % nodePrice == 0, "AMOUNT_NOT_MULTIPLIER");

        cashoutAll();
        require(balanceOf(_msgSender()) >= amount, "BALANCE_INSUFFICIENT");
        bytes memory basic = bytes.concat("BRAIN-", _toString(block.timestamp), _toString(nodeRewardManager._getNodeNumberOf(_msgSender())));
        for (uint256 i = 1; i <= amount / nodePrice; i++) {
          string memory name = string(bytes.concat(basic, _toString(i)));
          createNodeWithTokens(name);
        }
        emit Compound(_msgSender(), amount);
    }

    function renameNode(string memory oldName, string memory newName) external {
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO_NODE_OWNER");
        require(bytes(newName).length > 3 && bytes(newName).length < 32, "NAME_SIZE_INVALID");
        nodeRewardManager._renameNode(_msgSender(), oldName, newName);
        emit RenameNode(_msgSender(), oldName, newName);
    }

    function transferNode(address to, string calldata nodeName) external {
        nodeRewardManager._transferNode(_msgSender(), to, nodeName);
        emit TransferNode(_msgSender(), to, nodeName);
    }

    /***** MODIFIERS & EVENTS *****/

    modifier onlyApproved() {
        require(proxyToApproved[_msgSender()] == true || _msgSender() == owner(), "onlyProxy");
        _;
    }       

    event OpenTrading(address indexed user);
    event WithdrawAVAX(address indexed sender, uint256 indexed balance);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event CreateNodeWithTokens(address indexed user, string indexed name);
    event CashoutReward(address indexed user, uint256 indexed rewardAmount);
    event CashoutAll(address indexed user, uint256 indexed amount);
    event Compound(address indexed user, uint256 indexed amount);
    event RenameNode(address indexed user, string indexed oldName, string indexed newName);
    event ManualSwapAndLiquify(address indexed user, uint256 indexed contractTokenBalance);
    event AddRewardsToPool(address indexed user, uint256 indexed amount);
    event RemoveFromRewardsPool(address indexed user, uint256 indexed amount);
    event SetNodeCreateProcessFeeRecipient(address indexed user, address indexed value);
    event SetRewardProcessFeeRecipient(address indexed user, address indexed value);
    event SetRouter(address indexed router, bool indexed value);
    event TransferNode(address indexed user, address indexed to, string indexed nodeName);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IVesting.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NODERewardManagementV2 is Ownable {
    using Strings for uint256;

    address[] public Admins;
    mapping(address => bool) public AdminByAddr;
    IVesting vesting;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
    }

    mapping(address => uint256[]) public NodeIDsByUser;
    mapping(uint256 => NodeEntity) public NodesByID;
    mapping(string => bool) public NodeNames;

    uint256 public nodePrice;
    uint256 public rewardPerNode;
    address public token;
    uint256 public totalNodesCreated;
    uint256 public totalRewardStaked;
    uint256 public claimTime;
    uint256 public rewardsPerMinute;
    bool public cashoutEnabled;
    bool public bypassIsNodeOwner = true;
    bool public autoDistri = true;          // for parity with existing token contract calls
    uint256 public gasForDistribution;      // for parity with existing token contract calls
    uint256 public lastDistributionCount;   // for parity with existing token contract calls

    constructor(uint256 _nodePrice, uint256 _rewardPerNode, uint256 _claimTime) {
        nodePrice = _nodePrice;
        rewardsPerMinute =  _rewardPerNode / (24 * 60);
        rewardPerNode = _rewardPerNode;
        claimTime = _claimTime;
        Admins.push(msg.sender);
        AdminByAddr[msg.sender] = true;
    }

    /**************/
    /*   VIEWS    */
    /**************/

    function _getRewardAmountOfNode(address account, uint256 nodeIndex) external view nodeOwner(account) returns(uint256) {
        require(NodeIDsByUser[account].length > nodeIndex, "INVALID_INDEX");
        return _availableClaimableAmount(NodesByID[NodeIDsByUser[account][nodeIndex]].lastClaimTime) + 
                NodesByID[NodeIDsByUser[account][nodeIndex]].rewardAvailable;
    }

    function _getRewardAvailable(address account, uint256 nodeIndex) external view nodeOwner(account) returns(uint256) {
        require(NodeIDsByUser[account].length > nodeIndex, "INVALID_INDEX");
        return NodesByID[NodeIDsByUser[account][nodeIndex]].rewardAvailable;
    }

    function _getAvailableClaimAmount(address account, uint256 nodeIndex) external view nodeOwner(account) returns(uint256) {
        require(NodeIDsByUser[account].length > nodeIndex, "INVALID_INDEX");
        return _availableClaimableAmount(NodesByID[NodeIDsByUser[account][nodeIndex]].lastClaimTime);
    }

    function _getRewardAmountOf(address account) external view nodeOwner(account) returns(uint256) {
        uint256 rewardCount;
        for (uint256 x; x < NodeIDsByUser[account].length; x++) {
            rewardCount += _availableClaimableAmount(NodesByID[NodeIDsByUser[account][x]].lastClaimTime) + 
                NodesByID[NodeIDsByUser[account][x]].rewardAvailable;
        }
        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime) external view nodeOwner(account) returns(uint256) {
        require(_creationTime > 0, "CREATIONTIME_IS_ZERO");
        require(NodeIDsByUser[account].length > 0, "NO_NODES_FOR_CASHOUT");
        NodeEntity memory node = _getNodeWithCreationTime(account, _creationTime);
        return _availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable;
    }

    function _getNodesRewardAvailable(address account) external view nodeOwner(account) returns(string memory) {
        NodeEntity memory node = NodesByID[NodeIDsByUser[account][0]];
        string memory _rewardsAvailable = uint2str(_availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable);
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            node = NodesByID[NodeIDsByUser[account][x]];
            _rewardsAvailable = string(abi.encodePacked(_rewardsAvailable, "#", 
                uint2str(_availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable)));
        }
        return _rewardsAvailable;
    }

    function _getNodesPendingClaimableAmount(address account) external view nodeOwner(account) returns(string memory) {
        string memory pendingClaimableAmount = uint2str(_pendingClaimableAmount(NodesByID[NodeIDsByUser[account][0]].lastClaimTime));
        for (uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            pendingClaimableAmount = string(abi.encodePacked(pendingClaimableAmount,"#", 
                uint2str(_pendingClaimableAmount(NodesByID[NodeIDsByUser[account][x]].lastClaimTime))));
        }
        return pendingClaimableAmount;
    }

    function _getNodeRewardAmountOf(address account, uint256 creationTime) external view nodeOwner(account) returns (uint256) {
        return _getNodeWithCreationTime(account, creationTime).rewardAvailable;
    }

    function _getNodesNames(address account) external view nodeOwner(account) returns(string memory) {
        string memory names = NodesByID[NodeIDsByUser[account][0]].name;
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            names = string(abi.encodePacked(names, "#", NodesByID[NodeIDsByUser[account][x]].name));
        }
        return names;
    }

    function _getNodesCreationTime(address account) external view nodeOwner(account) returns(string memory) {
        string memory creationTimes = uint2str(NodesByID[NodeIDsByUser[account][0]].creationTime);
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            creationTimes = string(abi.encodePacked(creationTimes, "#", 
                uint2str(NodesByID[NodeIDsByUser[account][x]].creationTime)));
        }
        return creationTimes;
    }

    function _getNodesLastClaimTime(address account) external view nodeOwner(account) returns(string memory) {
        string memory _lastClaimTimes = uint2str(NodesByID[NodeIDsByUser[account][0]].lastClaimTime);
        for(uint256 x = 1; x < NodeIDsByUser[account].length; x++) {
            _lastClaimTimes = string(abi.encodePacked(_lastClaimTimes, "#", 
                uint2str(NodesByID[NodeIDsByUser[account][x]].lastClaimTime)));
        }        
        return _lastClaimTimes;
    }

    function _getNodeNumberOf(address account) external view returns(uint256) {
        return NodeIDsByUser[account].length;
    }

    function _isNodeOwner(address account) external view returns(bool) {
        return bypassIsNodeOwner ? true : NodeIDsByUser[account].length > 0;
    }

    function _distributeRewards() external view onlyAdmin returns(uint256, uint256, uint256) {
        return (0,0,0);
    }

    /****************/
    /*   MUTATIVE   */
    /****************/

    function createNode(address account, string memory nodeName) external onlyAdmin {
        NodesByID[totalNodesCreated] = NodeEntity({
                name: _getAvailableName(nodeName),
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                rewardAvailable: 0
            });
        NodeIDsByUser[account].push(totalNodesCreated);
        totalNodesCreated++;
    }

    function createNodes(address[] calldata accounts, string[] calldata nodeNames) external onlyAdmin {
        require(accounts.length == nodeNames.length, "INCONSISTENT_LENGTH");
        for(uint256 x; x < accounts.length; x++) {
            NodesByID[totalNodesCreated] = NodeEntity({
                    name: _getAvailableName(nodeNames[x]),
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp,
                    rewardAvailable: 0
                });
            NodeIDsByUser[accounts[x]].push(totalNodesCreated);            
            totalNodesCreated++;
        }
    }    

    function createNodesForAccount(address account, string[] calldata nodeNames) external onlyAdmin {
        for(uint256 x; x < nodeNames.length; x++) {
            NodesByID[totalNodesCreated] = NodeEntity({
                    name: _getAvailableName(nodeNames[x]),
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp,
                    rewardAvailable: 0
                });
            NodeIDsByUser[account].push(totalNodesCreated);   
            totalNodesCreated++;
        }
    }    

    function _cashoutNodeReward(address account, uint256 _creationTime) external onlyAdmin nodeOwner(account) returns(uint256) {
        require(cashoutEnabled, "CASHOUT_DISABLED");
        require(_creationTime > 0, "CREATIONTIME_IS_ZERO");
        NodeEntity storage node = _getNodeWithCreationTime(account, _creationTime);
        require(isNodeClaimable(node), "TOO_EARLY_TO_CLAIM");
        uint256 rewardNode = _availableClaimableAmount(node.lastClaimTime) + node.rewardAvailable;
        node.rewardAvailable = 0;
        node.lastClaimTime = block.timestamp;
        if (vesting.isBeneficiary(account) && vesting.accruedBalanceOf(account) > 0) {
            vesting.claim(account);
        }
        return rewardNode; 
    }    

    function _cashoutAllNodesReward(address account) external onlyAdmin nodeOwner(account) returns(uint256) {
        require(cashoutEnabled, "CASHOUT_DISABLED");
        uint256 rewardsTotal;
        for (uint256 x; x < NodeIDsByUser[account].length; x++) {
            NodeEntity storage _node = NodesByID[NodeIDsByUser[account][x]];
            rewardsTotal += _availableClaimableAmount(_node.lastClaimTime) + _node.rewardAvailable;
            _node.rewardAvailable = 0;
            _node.lastClaimTime = block.timestamp;
        }
        if (vesting.isBeneficiary(account) && vesting.accruedBalanceOf(account) > 0) {
            vesting.claim(account);
        }        
        return rewardsTotal;
    }

    function transferNode(address to, string memory nodeName) external returns (bool) {
        return _transferNode(msg.sender, to, nodeName);
    }    

    function _transferNode(address from, address to, string memory nodeName) public onlyAdmin nodeOwner(from) returns (bool) {
        uint256 index;
        bool found;
        for(uint256 x = 0; x < NodeIDsByUser[from].length; x++) {
            if (keccak256(bytes(NodesByID[NodeIDsByUser[from][x]].name)) == keccak256(bytes(nodeName))) {
                found = true;
                index = x;
                break;
            }            
        }        
        require(found, "NODE_!EXISTS");
        // push ID into receiver
        NodeIDsByUser[to].push(NodeIDsByUser[from][index]);
        // swap ID with last item for sender
        NodeIDsByUser[from][index] = NodeIDsByUser[from][NodeIDsByUser[from].length - 1];
        // remove last ID from sender
        NodeIDsByUser[from].pop();
        return true;        
    }  

    function _renameNode(address account, string memory oldName, string memory newName) external nodeOwner(account) onlyAdmin {
        require(NodeNames[oldName], "NODE_!EXISTS");
        NodesByID[_getNodeIDByName(account, oldName)].name = newName;
        NodeNames[oldName] = false;
        NodeNames[newName] = true;
    }

    /****************/
    /*    ADMIN     */
    /****************/

    function setToken (address token_) external onlyAdmin {
        token = token_;
    }

    function setVesting(address vesting_) external onlyAdmin {
        vesting = IVesting(vesting_);
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyAdmin {
        rewardsPerMinute = newPrice;
    }     

    function toggleCashoutEnabled() external onlyAdmin {
        cashoutEnabled = !cashoutEnabled;
    }

    function _changeNodePrice(uint256 newNodePrice) external onlyAdmin {
        nodePrice = newNodePrice;
    }

    function _changeClaimTime(uint256 newTime) external onlyAdmin {
        claimTime = newTime;
    }    

    function _changeRewardPerNode(uint256 newPrice) external onlyAdmin {
        rewardPerNode = newPrice;
        rewardsPerMinute = newPrice / (24 * 60);
    }  
   
    function addRewardToNode(address account, string memory name, uint256 amount) external onlyAdmin nodeOwner(account) {
        require(NodeNames[name], "NODE_!EXISTS");
        NodesByID[_getNodeIDByName(account, name)].rewardAvailable += amount;
    }

    function setBypassNodeOwner(bool bypass) external onlyAdmin {
        bypassIsNodeOwner = bypass;
    }

    function _changeAutoDistri(bool newMode) external onlyAdmin {}      

    function _changeGasDistri(uint256 newGasDistri) external onlyAdmin {}    

    /**************/
    /*  PRIVATE   */
    /**************/

    function _getNodeIDByName(address account, string memory name) private view returns(uint256) {
        require(NodeNames[name], "NODE_!EXISTS");
        uint256 nodeId;
        bool found;
        for(uint256 x; x < NodeIDsByUser[account].length; x++) {
            if (keccak256(bytes(NodesByID[NodeIDsByUser[account][x]].name)) == keccak256(bytes(name))) {
                nodeId = NodeIDsByUser[account][x];
                found = true;
                break;
            }
        }
        require(found, "NO_NODE_WITH_NAME");
        return nodeId;
    }

    function _pendingClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 timePassed = block.timestamp - nodeLastClaimTime;
        return timePassed / claimTime < 1 
            ? timePassed * rewardsPerMinute / claimTime 
            : 0;
    }

    function _availableClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        return ((block.timestamp - nodeLastClaimTime) / claimTime) * rewardsPerMinute;
    }      

    function _getAvailableName(string memory nodeName) private returns(string memory) {
        string memory newNodeName = nodeName;
        uint256 x;
        while(NodeNames[newNodeName]) {
            newNodeName = string(abi.encodePacked(nodeName, x.toString()));
            x++;
        }
        NodeNames[newNodeName] = true;             
        return newNodeName;
    }

    function _getNodeWithCreationTime(address account, uint256 creationTime) private view returns (NodeEntity storage) {
        uint256 nodeId;
        bool found;
        for(uint256 x; x < NodeIDsByUser[account].length; x++) {
            if (NodesByID[NodeIDsByUser[account][x]].creationTime == creationTime) {
                nodeId = NodeIDsByUser[account][x];
                found = true;
                break;
            }
        }
        require(found, "NO_NODE_WITH_BLOCKTIME");
        return NodesByID[nodeId];
    }

    function _getNodeWithCreatime(NodeEntity[] storage nodes, uint256 _creationTime) private view returns (NodeEntity storage) {
        require(nodes.length > 0, "NO_NODES_FOR_CASHOUT");
        bool found;
        int256 index = _binarysearch(nodes, 0, nodes.length, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NO_NODE_WITH_BLOCKTIME");
        return nodes[validIndex];
    }

    function isNodeClaimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function _binarysearch(NodeEntity[] memory arr, uint256 low, uint256 high, uint256 x) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low) / (2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return _binarysearch(arr, low, mid - 1, x);
            } else {
                return _binarysearch(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setAdmins(address[] memory _Admins) external onlyAdmin {
        _setAdmins(_Admins);
    }

    function _setAdmins(address[] memory _Admins) internal {
        for (uint256 i; i < Admins.length; i++) {
            AdminByAddr[Admins[i]] = false;
        }

        for (uint256 j; j < _Admins.length; j++) {
            AdminByAddr[_Admins[j]] = true;
        }
        Admins = _Admins;
        emit SetAdmins(_Admins);
    }

    function getAdmins() external view returns (address[] memory) {
        return Admins;
    }      

    modifier onlyAdmin() {
        require(msg.sender == token || AdminByAddr[msg.sender] == true || msg.sender == owner(), "Fuck off");
        _;
    }

    modifier nodeOwner(address account) {
        require(NodeIDsByUser[account].length > 0, "NOT_NODE_OWNER");
        _;
    }

    event SetAdmins(address[] Admins);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IRouter {

    function WAVAX() external pure returns (address);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVesting {     
    function claim(address _address) external;
    function accruedBalanceOf(address beneficiaryAddress) external view returns (uint256);
    function isBeneficiary(address beneficiaryAddress) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

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
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
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
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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