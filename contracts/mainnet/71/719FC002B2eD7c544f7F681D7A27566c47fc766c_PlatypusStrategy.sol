// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.7.3;

import "../interfaces/IMasterPlatypus.sol";
import "../interfaces/IPlatypusPool.sol";
import "../interfaces/IPlatypusVoterProxy.sol";
import "../interfaces/IPlatypusAsset.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IWAVAX.sol";
import "../lib/DexLibrary.sol";
import "../lib/SafeERC20.sol";
import "../lib/DSMath.sol";
import "../YakStrategyV2.sol";

contract PlatypusStrategy is YakStrategyV2 {
    using SafeMath for uint256;
    using DSMath for uint256;
    using SafeERC20 for IERC20;

    struct SwapPairs {
        address swapPairToken; // swap rewardToken to depositToken
        address swapPairPoolReward;
        address swapPairExtraReward;
    }

    struct StrategySettings {
        uint256 minTokensToReinvest;
        uint256 adminFeeBips;
        uint256 devFeeBips;
        uint256 reinvestRewardBips;
    }

    IWAVAX private constant WAVAX = IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    IMasterPlatypus public immutable masterchef;
    IPlatypusAsset public immutable asset;
    IPlatypusPool public pool;
    IPlatypusVoterProxy public proxy;
    uint256 public maxSlippage;
    address private swapPairToken;
    uint256 public immutable PID;
    address private poolRewardToken;
    IPair private swapPairPoolReward;
    address public swapPairExtraReward;
    address public extraToken;

    constructor(
        string memory _name,
        address _depositToken,
        address _poolRewardToken,
        SwapPairs memory swapPairs,
        uint256 _maxSlippage,
        address _pool,
        address _stakingContract,
        address _voterProxy,
        uint256 _pid,
        address _timelock,
        StrategySettings memory _strategySettings
    ) {
        name = _name;
        depositToken = IERC20(_depositToken);
        rewardToken = IERC20(address(WAVAX));
        PID = _pid;
        devAddr = 0x2D580F9CF2fB2D09BC411532988F2aFdA4E7BefF;

        masterchef = IMasterPlatypus(_stakingContract);
        pool = IPlatypusPool(_pool);
        asset = IPlatypusAsset(pool.assetOf(_depositToken));
        proxy = IPlatypusVoterProxy(_voterProxy);
        maxSlippage = _maxSlippage;

        assignSwapPairSafely(swapPairs.swapPairToken, _poolRewardToken, swapPairs.swapPairPoolReward);
        _setExtraRewardSwapPair(swapPairs.swapPairExtraReward);
        updateMinTokensToReinvest(_strategySettings.minTokensToReinvest);
        updateAdminFee(_strategySettings.adminFeeBips);
        updateDevFee(_strategySettings.devFeeBips);
        updateReinvestReward(_strategySettings.reinvestRewardBips);
        updateDepositsEnabled(true);
        transferOwnership(_timelock);
        emit Reinvest(0, 0);
    }

    function setPlatypusVoterProxy(address _voterProxy) external onlyOwner {
        proxy = IPlatypusVoterProxy(_voterProxy);
    }

    /**
     * @notice Update max slippage for withdrawal
     * @dev Function name matches interface for FeeCollector
     */
    function updateMaxSwapSlippage(uint256 slippageBips) public onlyDev {
        maxSlippage = slippageBips;
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Deprecated; approvals should be handled in context of staking
     */
    function setAllowances() public override onlyOwner {
        revert("setAllowances::deprecated");
    }

    /**
     * @notice Update extra reward swap pair (if applicable)
     * @dev Function name matches interface for FeeCollector
     */
    function setExtraRewardSwapPair(address _extraTokenSwapPair) external onlyDev {
        _setExtraRewardSwapPair(_extraTokenSwapPair);
    }

    function assignSwapPairSafely(
        address _swapPairToken,
        address _poolRewardToken,
        address _swapPairPoolReward
    ) private {
        require(
            DexLibrary.checkSwapPairCompatibility(IPair(_swapPairToken), address(depositToken), address(rewardToken)),
            "swap token does not match deposit and reward token"
        );
        swapPairToken = _swapPairToken;

        if (_poolRewardToken != address(rewardToken)) {
            DexLibrary.checkSwapPairCompatibility(IPair(_swapPairPoolReward), address(rewardToken), _poolRewardToken);
        }
        poolRewardToken = _poolRewardToken;
        swapPairPoolReward = IPair(_swapPairPoolReward);
    }

    function _setExtraRewardSwapPair(address _extraTokenSwapPair) internal {
        if (_extraTokenSwapPair > address(0)) {
            if (IPair(_extraTokenSwapPair).token0() == address(rewardToken)) {
                extraToken = IPair(_extraTokenSwapPair).token1();
            } else if (IPair(_extraTokenSwapPair).token1() == address(rewardToken)) {
                extraToken = IPair(_extraTokenSwapPair).token0();
            } else {
                revert("PlatypusStrategy::_setExtraRewardSwapPair Swap pair does not contain reward token");
            }
            swapPairExtraReward = _extraTokenSwapPair;
        } else {
            swapPairExtraReward = address(0);
            extraToken = address(0);
        }
    }

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param amount Amount of tokens to deposit
     */
    function deposit(uint256 amount) external override {
        _deposit(msg.sender, amount);
    }

    /**
     * @notice Deposit using Permit
     * @param amount Amount of tokens to deposit
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        depositToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _deposit(msg.sender, amount);
    }

    function depositFor(address account, uint256 amount) external override {
        _deposit(account, amount);
    }

    function _deposit(address account, uint256 amount) internal {
        require(DEPOSITS_ENABLED == true, "PlatypusStrategy::_deposit");
        if (MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST > 0) {
            (
                uint256 poolTokenAmount,
                uint256 extraTokenAmount,
                uint256 rewardTokenBalance,
                uint256 estimatedTotalReward
            ) = _checkReward();
            if (estimatedTotalReward > MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST) {
                _reinvest(rewardTokenBalance, poolTokenAmount, extraTokenAmount);
            }
        } else {
            proxy.claimReward(address(masterchef), PID);
        }
        depositToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 depositFee = _calculateDepositFee(amount);
        _mint(account, getSharesForDepositTokens(amount.sub(depositFee)));
        _stakeDepositTokens(amount, depositFee);
        emit Deposit(account, amount.sub(depositFee));
    }

    function _depositMasterchef(
        uint256 _pid,
        uint256 _amount,
        uint256 _depositFee
    ) internal {
        depositToken.safeTransfer(address(proxy), _amount);
        proxy.deposit(
            _pid,
            address(masterchef),
            address(pool),
            address(depositToken),
            address(asset),
            _amount,
            _depositFee
        );
    }

    function withdraw(uint256 amount) external override {
        uint256 depositTokenAmount = getDepositTokensForShares(amount);
        require(depositTokenAmount > 0, "PlatypusStrategy::withdraw");
        proxy.claimReward(address(masterchef), PID);
        uint256 withdrawalAmount = proxy.withdraw(
            PID,
            address(masterchef),
            address(pool),
            address(depositToken),
            address(asset),
            maxSlippage,
            depositTokenAmount
        );
        depositToken.safeTransfer(msg.sender, withdrawalAmount);
        _burn(msg.sender, amount);
        emit Withdraw(msg.sender, depositTokenAmount);
    }

    function reinvest() external override onlyEOA {
        (
            uint256 poolTokenAmount,
            uint256 extraTokenAmount,
            uint256 rewardTokenBalance,
            uint256 estimatedTotalReward
        ) = _checkReward();
        require(estimatedTotalReward >= MIN_TOKENS_TO_REINVEST, "PlatypusStrategy::reinvest");
        _reinvest(rewardTokenBalance, poolTokenAmount, extraTokenAmount);
    }

    function _convertPoolTokensIntoReward(uint256 poolTokenAmount) private returns (uint256) {
        if (address(rewardToken) == poolRewardToken) {
            return poolTokenAmount;
        }
        return DexLibrary.swap(poolTokenAmount, address(poolRewardToken), address(rewardToken), swapPairPoolReward);
    }

    function _convertExtraTokensIntoReward(uint256 rewardTokenBalance, uint256 extraTokenAmount)
        internal
        returns (uint256)
    {
        if (extraTokenAmount > 0) {
            if (swapPairExtraReward > address(0)) {
                return DexLibrary.swap(extraTokenAmount, extraToken, address(rewardToken), IPair(swapPairExtraReward));
            }

            uint256 avaxBalance = address(this).balance;
            if (avaxBalance > 0) {
                WAVAX.deposit{value: avaxBalance}();
            }
            return WAVAX.balanceOf(address(this)).sub(rewardTokenBalance);
        }
        return 0;
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     * @dev Reverts if the expected amount of tokens are not returned from `MasterChef`
     */
    function _reinvest(
        uint256 rewardTokenBalance,
        uint256 poolTokenAmount,
        uint256 extraTokenAmount
    ) private {
        proxy.claimReward(address(masterchef), PID);
        uint256 amount = rewardTokenBalance.add(_convertPoolTokensIntoReward(poolTokenAmount));
        amount.add(_convertExtraTokensIntoReward(rewardTokenBalance, extraTokenAmount));

        uint256 devFee = amount.mul(DEV_FEE_BIPS).div(BIPS_DIVISOR);
        if (devFee > 0) {
            rewardToken.safeTransfer(devAddr, devFee);
        }

        uint256 reinvestFee = amount.mul(REINVEST_REWARD_BIPS).div(BIPS_DIVISOR);
        if (reinvestFee > 0) {
            rewardToken.safeTransfer(msg.sender, reinvestFee);
        }

        uint256 depositTokenAmount = _convertRewardTokenToDepositToken(amount.sub(devFee).sub(reinvestFee));

        uint256 depositFee = _calculateDepositFee(depositTokenAmount);
        _stakeDepositTokens(depositTokenAmount, depositFee);

        emit Reinvest(totalDeposits(), totalSupply);
    }

    function _convertRewardTokenToDepositToken(uint256 fromAmount) internal returns (uint256 toAmount) {
        toAmount = DexLibrary.swap(fromAmount, address(rewardToken), address(depositToken), IPair(swapPairToken));
    }

    function _stakeDepositTokens(uint256 amount, uint256 depositFee) private {
        require(amount.sub(depositFee) > 0, "PlatypusStrategy::_stakeDepositTokens");
        _depositMasterchef(PID, amount, depositFee);
    }

    function checkReward() public view override returns (uint256) {
        (, , , uint256 estimatedTotalReward) = _checkReward();
        return estimatedTotalReward;
    }

    function _checkReward()
        internal
        view
        returns (
            uint256 _poolTokenAmount,
            uint256 _extraTokenAmount,
            uint256 _rewardTokenBalance,
            uint256 _estimatedTotalReward
        )
    {
        uint256 poolTokenBalance = IERC20(poolRewardToken).balanceOf(address(this));
        (uint256 pendingPoolTokenAmount, uint256 pendingExtraTokenAmount, address extraTokenAddress) = _pendingRewards(
            PID
        );
        uint256 poolTokenAmount = poolTokenBalance.add(pendingPoolTokenAmount);

        uint256 pendingRewardTokenAmount = poolRewardToken != address(rewardToken)
            ? DexLibrary.estimateConversionThroughPair(
                poolTokenAmount,
                poolRewardToken,
                address(rewardToken),
                swapPairPoolReward
            )
            : pendingPoolTokenAmount;
        uint256 pendingExtraTokenRewardAmount = 0;
        if (extraTokenAddress > address(0)) {
            if (extraTokenAddress == address(WAVAX)) {
                pendingExtraTokenRewardAmount = pendingExtraTokenAmount;
            } else if (swapPairExtraReward > address(0)) {
                pendingExtraTokenAmount = pendingExtraTokenAmount.add(IERC20(extraToken).balanceOf(address(this)));
                pendingExtraTokenRewardAmount = DexLibrary.estimateConversionThroughPair(
                    pendingExtraTokenAmount,
                    extraTokenAddress,
                    address(rewardToken),
                    IPair(swapPairExtraReward)
                );
            }
        }
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this)).add(pendingExtraTokenRewardAmount);
        uint256 estimatedTotalReward = rewardTokenBalance.add(pendingRewardTokenAmount);
        return (poolTokenAmount, pendingExtraTokenAmount, rewardTokenBalance, estimatedTotalReward);
    }

    function _pendingRewards(uint256 _pid)
        internal
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        (uint256 pendingPtp, uint256 pendingBonusToken, address bonusTokenAddress) = proxy.pendingRewards(
            address(masterchef),
            _pid
        );
        uint256 reinvestFeeBips = proxy.reinvestFeeBips();
        uint256 boostFee = pendingPtp.mul(reinvestFeeBips).div(BIPS_DIVISOR);

        return (pendingPtp.sub(boostFee), pendingBonusToken, bonusTokenAddress);
    }

    function _calculateDepositFee(uint256 amount) internal view returns (uint256 fee) {
        return
            _depositFee(
                pool.getSlippageParamK(),
                pool.getSlippageParamN(),
                pool.getC1(),
                pool.getXThreshold(),
                asset.cash(),
                asset.liability(),
                amount
            );
    }

    function _depositFee(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 cash,
        uint256 liability,
        uint256 amount
    ) internal pure returns (uint256) {
        // cover case where the asset has no liquidity yet
        if (liability == 0) {
            return 0;
        }

        uint256 covBefore = cash.wdiv(liability);
        if (covBefore <= 10**18) {
            return 0;
        }

        uint256 covAfter = (cash.add(amount)).wdiv(liability.add(amount));
        uint256 slippageBefore = _slippageFunc(k, n, c1, xThreshold, covBefore);
        uint256 slippageAfter = _slippageFunc(k, n, c1, xThreshold, covAfter);

        // (Li + Di) * g(cov_after) - Li * g(cov_before)
        return ((liability.add(amount)).wmul(slippageAfter)).sub(liability.wmul(slippageBefore));
    }

    function _slippageFunc(
        uint256 k,
        uint256 n,
        uint256 c1,
        uint256 xThreshold,
        uint256 x
    ) internal pure returns (uint256) {
        if (x < xThreshold) {
            return c1.sub(x);
        } else {
            return k.wdiv((((x.mul(RAY)).div(WAD)).rpow(n).mul(WAD)).div(RAY)); // k / (x ** n)
        }
    }

    /**
     * @notice Estimate recoverable balance after withdraw fee
     * @return deposit tokens after withdraw fee
     */
    function estimateDeployedBalance() external view override returns (uint256) {
        uint256 balance = totalDeposits();
        if (balance == 0) {
            return 0;
        }
        (uint256 expectedAmount, , ) = pool.quotePotentialWithdraw(address(depositToken), balance);
        return expectedAmount;
    }

    function totalDeposits() public view override returns (uint256) {
        uint256 depositBalance = proxy.poolBalance(address(masterchef), PID);
        return depositBalance;
    }

    function rescueDeployedFunds(uint256 minReturnAmountAccepted, bool disableDeposits) external override onlyOwner {
        uint256 balanceBefore = depositToken.balanceOf(address(this));
        proxy.emergencyWithdraw(PID, address(masterchef), address(pool), address(depositToken), address(asset));
        uint256 balanceAfter = depositToken.balanceOf(address(this));
        require(balanceAfter.sub(balanceBefore) >= minReturnAmountAccepted, "PlatypusStrategy::rescueDeployedFunds");
        emit Reinvest(totalDeposits(), totalSupply);
        if (DEPOSITS_ENABLED == true && disableDeposits == true) {
            updateDepositsEnabled(false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IMasterPlatypus {
    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function userInfo(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 _amount,
            uint256 _rewardDebt,
            uint256 _factor
        );

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address _lpToken,
            uint256 _allocPoint,
            uint256 _lastRewardTimestamp,
            uint256 _accPtpPerShare,
            address _rewarder,
            uint256 _sumOfFactors,
            uint256 _accPtpPerFactorShare
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IPlatypusPool {
    function assetOf(address token) external view returns (address);

    function deposit(
        address to,
        uint256 amount,
        address token,
        uint256 deadline
    ) external returns (uint256);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256);

    function getHaircutRate() external view returns (uint256);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );

    function getC1() external view returns (uint256);

    function getXThreshold() external view returns (uint256);

    function getSlippageParamK() external view returns (uint256);

    function getSlippageParamN() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IPlatypusVoter.sol";

interface IPlatypusVoterProxy {
    function withdraw(
        uint256 _pid,
        address _stakingContract,
        address _pool,
        address _token,
        address _asset,
        uint256 _maxSlippage,
        uint256 _amount
    ) external returns (uint256);

    function emergencyWithdraw(
        uint256 _pid,
        address _stakingContract,
        address _pool,
        address _token,
        address _asset
    ) external;

    function deposit(
        uint256 _pid,
        address _stakingContract,
        address _pool,
        address _token,
        address _asset,
        uint256 _amount,
        uint256 _depositFee
    ) external;

    function pendingRewards(address _stakingContract, uint256 _pid)
        external
        view
        returns (
            uint256,
            uint256,
            address
        );

    function poolBalance(address _stakingContract, uint256 _pid) external view returns (uint256);

    function platypusVoter() external view returns (IPlatypusVoter);

    function claimReward(address _stakingContract, uint256 _pid) external;

    function approveStrategy(address _stakingContract, address _strategy) external;

    function reinvestFeeBips() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IPlatypusAsset {
    function cash() external view returns (uint256);

    function liability() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function pool() external view returns (address);

    function underlyingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IERC20.sol";

interface IPair is IERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address owner) external view returns (uint); 
    function withdraw(uint) external;
    function approve(address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./SafeMath.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IWAVAX.sol";

library DexLibrary {
    using SafeMath for uint;
    bytes private constant zeroBytes = new bytes(0);
    IWAVAX private constant WAVAX = IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    /**
     * @notice Swap directly through a Pair
     * @param amountIn input amount
     * @param fromToken address
     * @param toToken address
     * @param pair Pair used for swap
     * @return output amount
     */
    function swap(uint amountIn, address fromToken, address toToken, IPair pair) internal returns (uint) {
        (address token0,) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        uint amountOut1 = 0;
        uint amountOut2 = getAmountOut(amountIn, reserve0, reserve1);
        if (token0 != fromToken) (amountOut1, amountOut2) = (amountOut2, amountOut1);
        safeTransfer(fromToken, address(pair), amountIn);
        pair.swap(amountOut1, amountOut2, address(this), zeroBytes);
        return amountOut2 > amountOut1 ? amountOut2 : amountOut1;
    }

    function checkSwapPairCompatibility(IPair pair, address tokenA, address tokenB) internal pure returns (bool) {
        return (tokenA == pair.token0() || tokenA == pair.token1()) && (tokenB == pair.token0() || tokenB == pair.token1()) && tokenA != tokenB;
    }

    function estimateConversionThroughPair(uint amountIn, address fromToken, address toToken, IPair swapPair) internal view returns (uint) {
        (address token0,) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1,) = swapPair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        return getAmountOut(amountIn, reserve0, reserve1);
    }

    /**
     * @notice Converts reward tokens to deposit tokens
     * @dev No price checks enforced
     * @param amount reward tokens
     * @return deposit tokens
     */
    function convertRewardTokensToDepositTokens(uint amount, address rewardToken, address depositToken, IPair swapPairToken0, IPair swapPairToken1) internal returns (uint) {
        uint amountIn = amount.div(2);
        require(amountIn > 0, "DexLibrary::_convertRewardTokensToDepositTokens");

        address token0 = IPair(depositToken).token0();
        uint amountOutToken0 = amountIn;
        if (rewardToken != token0) {
            amountOutToken0 = DexLibrary.swap(amountIn, rewardToken, token0, swapPairToken0);
        }

        address token1 = IPair(depositToken).token1();
        uint amountOutToken1 = amountIn;
        if (rewardToken != token1) {
            amountOutToken1 = DexLibrary.swap(amountIn, rewardToken, token1, swapPairToken1);
        }

        return DexLibrary.addLiquidity(depositToken, amountOutToken0, amountOutToken1);
    }

    /**
     * @notice Add liquidity directly through a Pair
     * @dev Checks adding the max of each token amount
     * @param depositToken address
     * @param maxAmountIn0 amount token0
     * @param maxAmountIn1 amount token1
     * @return liquidity tokens
     */
    function addLiquidity(address depositToken, uint maxAmountIn0, uint maxAmountIn1) internal returns (uint) {
        (uint112 reserve0, uint112 reserve1,) = IPair(address(depositToken)).getReserves();
        uint amountIn1 = _quoteLiquidityAmountOut(maxAmountIn0, reserve0, reserve1);
        if (amountIn1 > maxAmountIn1) {
            amountIn1 = maxAmountIn1;
            maxAmountIn0 = _quoteLiquidityAmountOut(maxAmountIn1, reserve1, reserve0);
        }

        safeTransfer(IPair(depositToken).token0(), depositToken, maxAmountIn0);
        safeTransfer(IPair(depositToken).token1(), depositToken, amountIn1);
        return IPair(depositToken).mint(address(this));
    }

    /**
     * @notice Quote liquidity amount out
     * @param amountIn input tokens
     * @param reserve0 size of input asset reserve
     * @param reserve1 size of output asset reserve
     * @return liquidity tokens
     */
    function _quoteLiquidityAmountOut(uint amountIn, uint reserve0, uint reserve1) private pure returns (uint) {
        return amountIn.mul(reserve1).div(reserve0);
    }

    /**
     * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
     * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
     * @param tokenA address
     * @param tokenB address
     * @return sorted tokens
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns maximum output amount of the other asset
     * @dev Assumes swap fee is 0.30%
     * @param amountIn input asset
     * @param reserveIn size of input asset reserve
     * @param reserveOut size of output asset reserve
     * @return maximum output amount
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        return numerator.div(denominator);
    }

    /**
     * @notice Safely transfer using an anonymous ERC20 token
     * @dev Requires token to return true on transfer
     * @param token address
     * @param to recipient address
     * @param value amount
     */
    function safeTransfer(address token, address to, uint256 value) internal {
        require(IERC20(token).transfer(to, value), "DexLibrary::TRANSFER_FROM_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";

pragma solidity 0.7.3;

library DSMath {
    using SafeMath for uint256;

    uint256 public constant WAD = 10**18;
    uint256 public constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x.mul(y)).add((WAD.div(2)))).div(WAD);
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x.mul(WAD)).add((y.div(2)))).div(y);
    }

    function reciprocal(uint256 x) internal pure returns (uint256) {
        return wdiv(WAD, x);
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n.mod(2) != 0 ? x : RAY;

        for (n = n.div(2); n != 0; n = n.div(2)) {
            x = rmul(x, x);

            if (n.mod(2) != 0) {
                z = rmul(z, x);
            }
        }
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = ((x.mul(y)).add((RAY.div(2)))).div(RAY);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./lib/SafeMath.sol";
import "./lib/Ownable.sol";
import "./lib/Permissioned.sol";
import "./interfaces/IERC20.sol";
import "./YakERC20.sol";

/**
 * @notice YakStrategy should be inherited by new strategies
 */
abstract contract YakStrategyV2 is YakERC20, Ownable, Permissioned {
    using SafeMath for uint;


    IERC20 public depositToken;
    IERC20 public rewardToken;
    address public devAddr;

    uint public MIN_TOKENS_TO_REINVEST;
    uint public MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST;
    bool public DEPOSITS_ENABLED;

    uint public REINVEST_REWARD_BIPS;
    uint public ADMIN_FEE_BIPS;
    uint public DEV_FEE_BIPS;

    uint constant internal BIPS_DIVISOR = 10000;
    uint constant internal MAX_UINT = uint(-1);

    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);
    event Reinvest(uint newTotalDeposits, uint newTotalSupply);
    event Recovered(address token, uint amount);
    event UpdateAdminFee(uint oldValue, uint newValue);
    event UpdateDevFee(uint oldValue, uint newValue);
    event UpdateReinvestReward(uint oldValue, uint newValue);
    event UpdateMinTokensToReinvest(uint oldValue, uint newValue);
    event UpdateMaxTokensToDepositWithoutReinvest(uint oldValue, uint newValue);
    event UpdateDevAddr(address oldValue, address newValue);
    event DepositsEnabled(bool newValue);

    /**
     * @notice Throws if called by smart contract
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "YakStrategy::onlyEOA");
        _;
    }

    /**
     * @notice Only called by dev
     */
    modifier onlyDev() {
        require(msg.sender == devAddr, "YakStrategy::onlyDev");
        _;
    }

    /**
     * @notice Approve tokens for use in Strategy
     * @dev Should use modifier `onlyOwner` to avoid griefing
     */
    function setAllowances() public virtual;

    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0));
    }

    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint amount) external virtual;

    /**
    * @notice Deposit using Permit
    * @dev Should revert for tokens without Permit
    * @param amount Amount of tokens to deposit
    * @param deadline The time at which to expire the signature
    * @param v The recovery byte of the signature
    * @param r Half of the ECDSA signature pair
    * @param s Half of the ECDSA signature pair
    */
    function depositWithPermit(uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual;

    /**
     * @notice Deposit on behalf of another account
     * @dev Must mint receipt tokens to `account`
     * @param account address to receive receipt tokens
     * @param amount deposit tokens
     */
    function depositFor(address account, uint amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(uint amount) external virtual;

    /**
     * @notice Reinvest reward tokens into deposit tokens
     */
    function reinvest() external virtual;

    /**
     * @notice Estimate reinvest reward
     * @return reward tokens
     */
    function estimateReinvestReward() external view returns (uint) {
        uint unclaimedRewards = checkReward();
        if (unclaimedRewards >= MIN_TOKENS_TO_REINVEST) {
            return unclaimedRewards.mul(REINVEST_REWARD_BIPS).div(BIPS_DIVISOR);
        }
        return 0;
    }

    /**
     * @notice Reward tokens avialable to strategy, including balance
     * @return reward tokens
     */
    function checkReward() public virtual view returns (uint);

    /**
     * @notice Estimated deposit token balance deployed by strategy, excluding balance
     * @return deposit tokens
     */
    function estimateDeployedBalance() external virtual view returns (uint);

    /**
     * @notice Rescue all available deployed deposit tokens back to Strategy
     * @param minReturnAmountAccepted min deposit tokens to receive
     * @param disableDeposits bool
     */
    function rescueDeployedFunds(uint minReturnAmountAccepted, bool disableDeposits) external virtual;

    /**
     * @notice This function returns a snapshot of last available quotes
     * @return total deposits available on the contract
     */
    function totalDeposits() public virtual view returns (uint);
    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint amount) public view returns (uint) {
        if (totalSupply.mul(totalDeposits()) == 0) {
            return amount;
        }
        return amount.mul(totalSupply).div(totalDeposits());
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint amount) public view returns (uint) {
        if (totalSupply.mul(totalDeposits()) == 0) {
            return 0;
        }
        return amount.mul(totalDeposits()).div(totalSupply);
    }

    /**
     * @notice Update reinvest min threshold
     * @param newValue threshold
     */
    function updateMinTokensToReinvest(uint newValue) public onlyOwner {
        emit UpdateMinTokensToReinvest(MIN_TOKENS_TO_REINVEST, newValue);
        MIN_TOKENS_TO_REINVEST = newValue;
    }

    /**
     * @notice Update reinvest max threshold before a deposit
     * @param newValue threshold
     */
    function updateMaxTokensToDepositWithoutReinvest(uint newValue) public onlyOwner {
        emit UpdateMaxTokensToDepositWithoutReinvest(MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST, newValue);
        MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST = newValue;
    }

    /**
     * @notice Update developer fee
     * @param newValue fee in BIPS
     */
    function updateDevFee(uint newValue) public onlyOwner {
        require(newValue.add(ADMIN_FEE_BIPS).add(REINVEST_REWARD_BIPS) <= BIPS_DIVISOR);
        emit UpdateDevFee(DEV_FEE_BIPS, newValue);
        DEV_FEE_BIPS = newValue;
    }

    /**
     * @notice Update admin fee
     * @param newValue fee in BIPS
     */
    function updateAdminFee(uint newValue) public onlyOwner {
        require(newValue.add(DEV_FEE_BIPS).add(REINVEST_REWARD_BIPS) <= BIPS_DIVISOR);
        emit UpdateAdminFee(ADMIN_FEE_BIPS, newValue);
        ADMIN_FEE_BIPS = newValue;
    }

    /**
     * @notice Update reinvest reward
     * @param newValue fee in BIPS
     */
    function updateReinvestReward(uint newValue) public onlyOwner {
        require(newValue.add(ADMIN_FEE_BIPS).add(DEV_FEE_BIPS) <= BIPS_DIVISOR);
        emit UpdateReinvestReward(REINVEST_REWARD_BIPS, newValue);
        REINVEST_REWARD_BIPS = newValue;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(DEPOSITS_ENABLED != newValue);
        DEPOSITS_ENABLED = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Update devAddr
     * @param newValue address
     */
    function updateDevAddr(address newValue) public onlyDev {
        emit UpdateDevAddr(devAddr, newValue);
        devAddr = newValue;
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function recoverERC20(address tokenAddress, uint tokenAmount) external onlyOwner {
        require(tokenAmount > 0);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount));
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Recover AVAX from contract
     * @param amount amount
     */
    function recoverAVAX(uint amount) external onlyOwner {
        require(amount > 0);
        msg.sender.transfer(amount);
        emit Recovered(address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface IPlatypusVoter {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function vePTPBalance() external view returns (uint256);

    function wrapAvaxBalance() external returns (uint256);

    function depositsEnabled() external view returns (bool);

    function depositFromBalance(uint256 _value) external;

    function setVoterProxy(address _voterProxy) external;

    function claimVePTP() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity 0.7.3;

import "./Context.sol";

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract Permissioned is Ownable {
    using SafeMath for uint;

    uint public numberOfAllowedDepositors;
    mapping(address => bool) public allowedDepositors;

    event AllowDepositor(address indexed account);
    event RemoveDepositor(address indexed account);

    modifier onlyAllowedDeposits() {
        if (numberOfAllowedDepositors > 0) {
            require(allowedDepositors[msg.sender] == true, "Permissioned::onlyAllowedDeposits, not allowed");
        }
        _;
    }

    /**
     * @notice Add an allowed depositor
     * @param depositor address
     */
    function allowDepositor(address depositor) external onlyOwner {
        require(allowedDepositors[depositor] == false, "Permissioned::allowDepositor");
        allowedDepositors[depositor] = true;
        numberOfAllowedDepositors = numberOfAllowedDepositors.add(1);
        emit AllowDepositor(depositor);
    }

    /**
     * @notice Remove an allowed depositor
     * @param depositor address
     */
    function removeDepositor(address depositor) external onlyOwner {
        require(numberOfAllowedDepositors > 0, "Permissioned::removeDepositor, no allowed depositors");
        require(allowedDepositors[depositor] == true, "Permissioned::removeDepositor, not allowed");
        allowedDepositors[depositor] = false;
        numberOfAllowedDepositors = numberOfAllowedDepositors.sub(1);
        emit RemoveDepositor(depositor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./lib/SafeMath.sol";
import "./interfaces/IERC20.sol";

abstract contract YakERC20 {
    using SafeMath for uint256;

    string public name = "Yield Yak";
    string public symbol = "YRT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
  
    mapping (address => mapping (address => uint256)) internal allowances;
    mapping (address => uint256) internal balances;

    /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev keccak256("1");
    bytes32 public constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint) public nonces;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {}

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * It is recommended to use increaseAllowance and decreaseAllowance instead
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(amount, "transferFrom: transfer amount exceeds allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }


    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "_approve::owner zero address");
        require(spender != address(0), "_approve::spender zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(address from, address to, uint256 value) internal {
        require(to != address(0), "_transferTokens: cannot transfer to the zero address");

        balances[from] = balances[from].sub(value, "_transferTokens: transfer exceeds from balance");
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balances[from] = balances[from].sub(value, "_burn: burn amount exceeds from balance");
        totalSupply = totalSupply.sub(value, "_burn: burn amount exceeds total supply");
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param value The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "permit::expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @notice Recovers address from signed data and validates the signature
     * @param signer Address that signed the data
     * @param encodeData Data signed by the address
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "Arch::validateSig: invalid signature");
    }

    /**
     * @notice EIP-712 Domain separator
     * @return Separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                VERSION_HASH,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @notice Current id of the chain where this contract is deployed
     * @return Chain id
     */
    function _getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}