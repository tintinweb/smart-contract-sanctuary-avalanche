// SPDX-License-Identifier: MIT
import './SafeMath.sol';
import './BEP20.sol';
import './Ownable.sol';

// File: browser/Staking.sol

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

interface JoeLPToken {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface Factory {
    function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);
}

interface IICY {
    function liquidityFee() external view returns (uint256);
    function treasuryFee() external view returns (uint256);
    function reflectionFee() external view returns (uint256);
    function marketingFee() external view returns (uint256);
    function feeDenominator() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function setSwapBackSettings(bool _enabled, uint256 _amount) external;
    function setFees(uint256 _liquidityFee, uint256 _treasuryFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external;
}

pragma solidity ^0.8.0;

contract ICYStaking is Ownable {
    using SafeMath for uint256;

    IBEP20 public stakeToken;
    IBEP20 public WETH;
    IBEP20 public AVAX;

    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    mapping(uint => uint) public totalShares;
    mapping(uint => uint) public dividendsPerShare;

    uint256 public toICYDecimal = 10 ** 12;

    struct Share {
            uint256 amount;
            uint256 stakedTime; //To track no.of days
            uint256 totalExcluded;
            uint256 totalRealised;
            uint256 unstakeStartTime;
            bool inUnstakingPeriod;
        }

    mapping (address => Share) public shares;
    mapping(address => bool) public isOperator;

    mapping(address => uint) shareholderClaims;
    uint public penalityBalance; //Store the total penality balance
    IDEXRouter public router;
    JoeLPToken public ICYAvaxPairAddress;
    JoeLPToken public AvaxWethPairAddress;
    IICY ICY;
    uint256 liquidityFee = 0;
    uint256 treasuryFee = 500;
    uint256 reflectionFee = 1000;
    uint256 marketingFee = 300;
    uint256 feeDenominator = 10000;

    //Data structure to track the reward rate of stake holders.
    mapping(address => mapping(uint => bool)) public isClaimed;

    event Stake(address indexed account, uint indexed amount);
    event UnStake(address indexed account, uint indexed amount, uint indexed penality);
    event ClaimReward(address indexed account, uint indexed amount);

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not authorized!");
        _;
    }

    constructor() {
        stakeToken = IBEP20(0xE18950c8F3b01f549cFc79dC44C3944FBd43fB76);
        ICY = IICY(0xE18950c8F3b01f549cFc79dC44C3944FBd43fB76);
        WETH = IBEP20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);
        initRewards();
        AVAX = IBEP20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        router = IDEXRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        AvaxWethPairAddress = JoeLPToken(0xFE15c2695F1F920da45C30AAE47d11dE51007AF9);
        ICYAvaxPairAddress = JoeLPToken(0xeD4bDe1eA2F93b31F4C03627B0fc2C506201aA91);
    }

    //Initialize reward reates in a mapping variable.
    mapping(uint => uint) rewardRates;
    function initRewards() internal {
        rewardRates[1] =  1e18;
        rewardRates[2] = 1e18 * 1.1;
        rewardRates[3] = 1e18 * 1.2;
        rewardRates[4] = 1e18 * 1.3;
        rewardRates[5] = 1e18 * 1.5;
        rewardRates[6] = 1e18 * 1.7;
        rewardRates[7] = 1e18 * 2;
    }

    function setFees(uint256 _liquidityFee, uint256 _treasuryFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) public onlyOwner {
        liquidityFee = _liquidityFee;
        treasuryFee = _treasuryFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        feeDenominator = _feeDenominator;
    }

    //Function to stake tokens
    function stake(uint amount) public {
        require(!shares[msg.sender].inUnstakingPeriod, "Not allowed to stake during unstake period");
        require(stakeToken.balanceOf(msg.sender) >= amount.div(toICYDecimal), "Insufficient token balance to stake");
        ICY.setFees(0, 0, 0, 0, feeDenominator);

        uint currentRate = getCurrentRewarRate(msg.sender);
        shares[msg.sender].amount += amount;
        if(shares[msg.sender].stakedTime == 0) {
            shares[msg.sender].stakedTime = block.timestamp;
        }

        isClaimed[msg.sender][currentRate] = true;

        stakeToken.transferFrom(msg.sender, address(this), amount.div(toICYDecimal));
        shares[msg.sender].totalExcluded += getCumulativeDividends(amount, currentRate);

        totalShares[rewardRates[currentRate]] += amount;

        ICY.setFees(liquidityFee, treasuryFee, reflectionFee, marketingFee, feeDenominator);
        emit Stake(msg.sender, amount);
    }

    uint dayInterval = 10;
    function setDayInterval(uint _value) public onlyOwner {
        dayInterval = _value;
    }

    //Functoin that returns number of days staked by the user
    function getNumOfDaysStaked (address account) public view returns(uint) {
        uint timeDifference = block.timestamp.sub(shares[account].stakedTime);
        return timeDifference.div(dayInterval);
    }

    function numOfDaysSinceStartedUnstake(address account) public view returns(uint) {
        uint timeDifference = block.timestamp.sub(shares[account].unstakeStartTime);
        return timeDifference.div(dayInterval);
    }

    //Swap the WETH tokens to ICY tokens
    function swapTokens(uint amount) internal returns(uint) {
        address[] memory path = new address[](3);
        path[0] = address(WETH);
        path[1] = address(AVAX);
        path[2] = address(stakeToken);

        WETH.approve(address(router), amount);

        uint currentBalance = stakeToken.balanceOf(address(this)).mul(toICYDecimal);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint newBalance = stakeToken.balanceOf(address(this)).mul(toICYDecimal);
        uint swappedAmount = newBalance.sub(currentBalance, "error in sub");

        return swappedAmount;
    }

    //Internal function that add swapped toknes to the corresponding stakeholder
    function swapAndStake(address shareholder, uint amount, uint rate) internal {
        if(amount > 0) {
            //uint currentRate = getCurrentRewarRate(shareholder);
            shares[shareholder].amount += amount;

            //isClaimed[shareholder][currentRate] = true;

            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount, rate);

            totalShares[rewardRates[rate]] += amount;
        }

    }

    //Distrubite the dividends based on staker's reward rate
    function distributeDividend(address shareholder, bool isToSwap, bool usePenality) internal {
        if(shares[shareholder].amount == 0){ return; }
        //require(!shares[shareholder].isUnstaked, "Not allowed to claim reward on unstaking period");

        uint256 amount = getUnpaidEarnings(shareholder);
        uint swappedAmount;
        uint amountFromPenality;
        if(amount > 0){
            uint currentRate = getCurrentRewarRate(shareholder);
            totalDistributed = totalDistributed.add(amount);
            if(isToSwap) {
                swappedAmount = swapTokens(amount);
            } else if(usePenality) {
                amountFromPenality = getPriceAndTokenAmount(amount);
                penalityBalance -= amountFromPenality;
            } else {
                WETH.transfer(shareholder, amount);
            }

            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount, currentRate);
            uint newRewardRate = getRewardRate(shareholder);
            uint rate = currentRate;
            if(newRewardRate > currentRate) {
                rate = ((currentRate + 1) > 7) ? 7 : (currentRate + 1);
                isClaimed[shareholder][rate] = true;
                totalShares[rewardRates[currentRate]] -= shares[shareholder].amount;
                totalShares[rewardRates[rate]] += shares[shareholder].amount;
                shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount, rate);
            }

            if(isToSwap) {
                swapAndStake(shareholder, swappedAmount, rate);
            }

            if(usePenality) {
                swapAndStake(shareholder, amountFromPenality, rate);
            }

            emit ClaimReward(shareholder, amount);
        }
    }

    //Function that returns the unpaid earnings for the given account
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        if(shares[shareholder].inUnstakingPeriod){return rewardAfterUnstake[shareholder]; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount, getCurrentRewarRate(shareholder));
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share, uint category) internal view returns (uint256) {
        return share.mul(dividendsPerShare[rewardRates[category]]).div(dividendsPerShareAccuracyFactor);
    }

    function getPenalityPct(address account) public view returns (uint256) {
        uint numOfDays = numOfDaysSinceStartedUnstake(account);
        if (numOfDays < 15) {
            uint penalityPercent = 60 - (numOfDays * 4);
            return penalityPercent;
        }
        return 0;
    }

    //Returns the penality amount to pay.
    function getPenality(address account) internal view returns(uint) {
        uint numOfDays = numOfDaysSinceStartedUnstake(account);
        if(numOfDays < 15) {
            uint penalityPercent = 60  - (numOfDays * 4);
            return shares[account].amount.mul(penalityPercent).div(100);
        }
        return 0;
    }

    //Function to unstake the tokens and handle penality
    function unstake() public {
        require(shares[msg.sender].inUnstakingPeriod, "Should be in unstaking period to unstake");
        ICY.setFees(0, 0, 0, 0, feeDenominator);

        uint totalStakedAmount = shares[msg.sender].amount;
        require(totalStakedAmount > 0, "No token staked!");
        uint penality = getPenality(msg.sender);
        penalityBalance += penality;
        claimDuringUnstakingPeriod(msg.sender);

        delete shares[msg.sender];
        stakeToken.transfer(msg.sender, (totalStakedAmount.sub(penality)).div(toICYDecimal));

        ICY.setFees(liquidityFee, treasuryFee, reflectionFee, marketingFee, feeDenominator);
        emit UnStake(msg.sender, totalStakedAmount, penality);
    }

    mapping(address => uint) rewardAfterUnstake;

    function startUnstaking() public {
        //distributeDividend(msg.sender, false, false);
        uint reward = getUnpaidEarnings(msg.sender);
        shares[msg.sender].unstakeStartTime = block.timestamp;
        shares[msg.sender].inUnstakingPeriod = true;
        rewardAfterUnstake[msg.sender] = reward;
        uint rate = getCurrentRewarRate(msg.sender);
        totalShares[rewardRates[rate]] -= shares[msg.sender].amount;
    }

    function claimDuringUnstakingPeriod(address shareholder) internal {
        uint earnings = rewardAfterUnstake[shareholder];
        if(earnings > 0) {
            WETH.transfer(shareholder, earnings);
            rewardAfterUnstake[shareholder] = 0;
        }
    }

    //Function to claiming reward
    function claimReward() public {
        if(shares[msg.sender].inUnstakingPeriod) {
            claimDuringUnstakingPeriod(msg.sender);
        } else {
            distributeDividend(msg.sender, false, false);
        }
    }

    //Returns the total amount staked by the account.
     function balanceOf(address account) public view returns (uint256) {
        return shares[account].amount;
    }

    //Function to deposit the WETH
    function deposit(uint amount) public onlyOperator {
        WETH.transferFrom(msg.sender, address(this), amount);
        totalDividends = totalDividends.add(amount);
        uint totalSharesWithRewardMultiplier;
        for(uint i=1; i <=7; i++) {
            totalSharesWithRewardMultiplier += (totalShares[rewardRates[i]] * rewardRates[i]);
        }
        totalSharesWithRewardMultiplier = totalSharesWithRewardMultiplier.div(1e18, "multiplier: div error");

        for(uint i=1; i <= 7; i++) {
            if(totalShares[rewardRates[i]] > 0) {
                uint amountPerRewardCategoryInPercent = (totalShares[rewardRates[i]]).mul(rewardRates[i]).div(totalSharesWithRewardMultiplier);
                uint amountPerCategory = amount.mul(amountPerRewardCategoryInPercent);
                dividendsPerShare[rewardRates[i]] = dividendsPerShare[rewardRates[i]].add(
                    dividendsPerShareAccuracyFactor.mul(amountPerCategory).div(totalShares[rewardRates[i]]).div(1e18)
                );
            }
        }
    }

    //Returns the reward rate based on number of days staked.
    function getRewardRate(address shareholder) public view returns(uint) {
        uint numOfDaysStaked = getNumOfDaysStaked(shareholder);
        uint rewardRate;
        if(numOfDaysStaked <= 30) {
            rewardRate = 1;//1e18;
        } else if(numOfDaysStaked > 30 && numOfDaysStaked <= 45) {
            rewardRate = 2;// ((1e18) * (1.1));
        } else if(numOfDaysStaked > 45 && numOfDaysStaked <= 60) {
            rewardRate =  3;//((1e18) * (1.2));
        } else if(numOfDaysStaked > 60 && numOfDaysStaked <= 90) {
            rewardRate = 4;// ((1e18) * (1.3));
        } else if(numOfDaysStaked > 90 && numOfDaysStaked <= 180) {
            rewardRate =  5;//((1e18) * (1.5));
        } else if(numOfDaysStaked > 180 && numOfDaysStaked <= 365) {
            rewardRate =  6;//((1e18) * (1.7));
        } else {
            rewardRate = 7;//2 * (1e18);
        }

        return rewardRate;
    }

    //Returns the calculated reward rate based on last claimed reward rate.
    function getCurrentRewarRate(address shareholder) public view returns(uint) {
        uint rewardRate = getRewardRate(shareholder);
        uint j = 0;
        for(uint i = rewardRate; i >= 1; i--) {
            if(isClaimed[shareholder][i]) {
                return i;
            }
            j++;
        }

        return 1;
    }

    //Function that compounds the stake by converting WETH to ICY
    function convertRewardToTokens() public {
        uint reward = getUnpaidEarnings(msg.sender);
        uint tokenAmount = getPriceAndTokenAmount(reward);
        if(tokenAmount >= penalityBalance) {
            distributeDividend(msg.sender, true, false);
        } else {
            distributeDividend(msg.sender, false, true);
        }
    }

    function getPriceAndTokenAmount(uint amount) internal view returns(uint) {

        //IERC20 token1 = IERC20(pair.token1());
        (uint Pair1Res0, uint Pair1Res1,) = AvaxWethPairAddress.getReserves();

        uint avaxAmount =  ((amount*Pair1Res1)/Pair1Res0); // return amount of token0 needed to buy token1

        (uint Pair2Res0, uint Pair2Res1,) = ICYAvaxPairAddress.getReserves();

        return ((avaxAmount*Pair2Res0*toICYDecimal)/Pair2Res1);
    }

    function addPenalityAmount(uint amount) public onlyOwner {
        penalityBalance += amount;
        stakeToken.transferFrom(msg.sender, address(this), amount.div(toICYDecimal));
    }

    function setOperator(address _operator) public onlyOwner {
        isOperator[_operator] = true;
    }

}