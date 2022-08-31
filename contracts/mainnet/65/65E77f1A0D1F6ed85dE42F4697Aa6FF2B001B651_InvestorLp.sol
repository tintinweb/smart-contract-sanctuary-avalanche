/**
 *Submitted for verification at snowtrace.io on 2022-08-30
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File contracts/VectorInterface.sol

pragma solidity 0.8.0;

interface IVector {
    function deposit(uint256 _amount) external;

    function balanceOf(address _address) external view returns (uint256);

    function withdraw(uint256 amount) external;

    function multiclaim(address[] calldata _lps, address user_address) external;
}

pragma solidity 0.8.0;

interface IStakingManager {
    function bankCut() external view returns (uint256);

    function poolStakers(uint256 _poolId, address _wallet)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function pendingRewards(uint256 _poolId, address _stakerAddress)
        external
        view
        returns (uint256);

    function pools(uint256 _poolId)
        external
        view
        returns (
            address,
            uint256,
            uint256
        );

    function deposit(
        uint256 _poolId,
        uint256 _amount,
        uint256 _rewards
    ) external;

    function withdraw(
        uint256 _poolId,
        uint256 _withdrawal,
        uint256 _rewards
    ) external;

    function ownerUpdatePoolRewards(uint256 _poolId, uint256 _rewards) external;
}

pragma solidity 0.8.0;

interface IJoeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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
    ) external payable returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

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

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity 0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 wad) external;
}

pragma solidity 0.8.0;

/**
 * @author King Salvo
 * @dev Purpose of InvestorLp is to act like a 'Smart EOA' that replicates
 *      all intended functions of an EOA when interactng with Trader Joe
 *      and Vector contracts.
 * @notice This is the first stage of Salvo Investor Contracts. There are plans
 *         to provide upgrade capabilities to all contracts.
 */
contract InvestorLp is Ownable, ReentrancyGuard {
    /*
     * 1.
     * Treasury - Wallet to Manage Profits
     */
    address payable public treasury;
    /*
     * 2.
     * StakingManager - Contract address to handle accounting
     */
    address public stakingManager;
    /*
     * 3.
     * Target Token Settings [0] pair, [1] avax
     */
    address[] public targetToken;
    /*
     * 4.
     * Investment Address - staking contract
     */
    address payable public investmentAddress;
    /*
     * 5.
     * Liquidity Pool - Address where pair is held
     */
    address payable public liquidityPool;
    /*
     * 6.
     * @dev Tokens to Be Rewarded by their Contract Address
     */
    address[] public tokensToBeRewardedAddress;
    /*
     * 7.
     * Rewards Snapshot
     * @dev Contains the rewards received from pool
     */
    mapping(address => uint256) public rewardSnapshot;
    /*
     * 8.
     * APR Tracker
     * @dev Contains the rewards received from pool
     */
    uint256 public aprTracker;
    /*
     * 9.
     * Last 24 APR
     * @dev Snapshot of APR total in the past 24 hours
     */
    uint256 public last24Apr;
    /*
     * 10.
     * Last Claim
     * @dev Saves the timestamp for last time owner made a rewards claim
     * NOTE: Prevents abusive accounts from timing their account deposits with
     * rewards claims
     */
    uint256 public lastClaim;
    /*
     * 11.
     * Investor Helper
     * @dev Tools like accounting and calc commission
     */
    address public investorHelper;
    /*
     * 12.
     * @dev poolId that communicates where amount and rewards are stored
     *      in StakingManager contract
     */
    uint256 public poolId;
    /*
     * 13.
     * paused
     * @dev Pauses contract for maintenance
     */
    bool public paused;

    // Modifiers
    modifier verifyPool() {
        (address lp, , ) = IStakingManager(stakingManager).pools(poolId);
        require(
            lp == liquidityPool,
            "Pool on Staking Manager has not be created."
        );
        _;
    }

    event LpEarned(uint256 indexed poolId, uint256 amount);

    event tokensGained(
        uint256 indexed poolId,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 avaxAmount
    );

    constructor(
        address payable _treasury,
        address[] memory _targetToken,
        address _stakingManager,
        address _investmentAddress,
        address _liquidityPool,
        address[] memory _tokensToBeRewardedAddress,
        address _investorHelper,
        uint256 _poolId
    ) {
        treasury = payable(_treasury);
        targetToken = _targetToken;
        stakingManager = _stakingManager;
        investmentAddress = payable(_investmentAddress);
        liquidityPool = payable(_liquidityPool);
        tokensToBeRewardedAddress = _tokensToBeRewardedAddress;
        lastClaim = block.timestamp;
        investorHelper = _investorHelper;
        poolId = _poolId;
        paused = false;
    }

    /**
     * @dev Router Deposit Avax LP
     * @param _tokenAddress - token address for first token, not Avax
     * @param _stakingContract - Vector contract where LP tokens are deposited
     * @param _routerAddr - Trader Joe Router Address
     * @param _avaxAddress - WAVAX ERC20 address
     * @notice - Swaps tokens --> Add Liquidity --> Deposit to Vector --> Credit on
     *           Staking Manager
     */

    function depositAvaxLp(
        address _tokenAddress,
        address _stakingContract,
        address _routerAddr,
        address _avaxAddress
    ) public payable verifyPool nonReentrant {
        require(msg.value > 0, "Amount to Deposit is Zero or Less.");
        require(paused == false, "Contract is Paused.");
        /*
         *
         * 1. Swap AVAX for respective token
         *
         */
        address[] memory _targetToken = targetToken;
        uint256[] memory exchangeRate;
        // 1a. Grab exchange rate for AVAX and token0
        exchangeRate = getExchangeRate(
            msg.value / 2,
            _routerAddr,
            reverseArray(_targetToken)
        );
        // 1b. Conduct Swap
        address[] memory avaxSwapPath = new address[](2);
        avaxSwapPath[0] = _avaxAddress;
        avaxSwapPath[1] = _tokenAddress;
        IJoeRouter(_routerAddr).swapExactAVAXForTokens{value: msg.value / 2}(
            getSlippage(exchangeRate[1], 95),
            avaxSwapPath,
            address(this),
            block.timestamp + 3600
        );
        /*
         *
         * 2. Add Liquidity to TJ & Receive LP Tokens
         *
         */
        (bool successLiquidity, ) = investorHelper.delegatecall(
            abi.encodeWithSignature(
                "addAvaxPairLiquidity(address,address,address,address,uint256,uint256)",
                _tokenAddress,
                _avaxAddress,
                _routerAddr,
                _avaxAddress,
                msg.value / 2,
                90
            )
        );
        require(
            successLiquidity,
            "Delegatecall to addAvaxPairLiquidity Failed."
        );
        /*
         *
         * 3. Deposit LP Tokens into Vector
         *
         */
        // a. Grab initial LP token balance before deposit
        uint256 initBal = IERC20(investmentAddress).balanceOf(address(this));
        // b. Deposit AVAX LP Tokens
        if (IERC20(liquidityPool).balanceOf(address(this)) > 0) {
            (bool successDeposit, ) = investorHelper.delegatecall(
                abi.encodeWithSignature(
                    "depositLPNative(uint256,address,address,address)",
                    IERC20(liquidityPool).balanceOf(address(this)),
                    liquidityPool,
                    _stakingContract,
                    investmentAddress
                )
            );
            require(successDeposit, "depositLPNative helper call failed.");
            /*
             *
             * 4. Credit Depositor on his LP Tokens
             * 4a. Middle param grabs balance difference of LP tokens
             *
             */
            IStakingManager(stakingManager).deposit(
                poolId,
                IERC20(investmentAddress).balanceOf(address(this)) - initBal,
                0
            );
        }
        /*
         *
         * 3. Store New Reward Balances into rewardSnapshot
         * 3a. rewardSnapshot - array tracking rewards harvested from round
         * 3b. Transfer to Treasury
         *
         */
        for (uint8 i = 0; i < tokensToBeRewardedAddress.length; i++) {
            // 3a.
            rewardSnapshot[tokensToBeRewardedAddress[i]] = IERC20(
                tokensToBeRewardedAddress[i]
            ).balanceOf(address(this));
            // 3b.
            if (rewardSnapshot[tokensToBeRewardedAddress[i]] != 0) {
                IERC20(tokensToBeRewardedAddress[i]).transfer(
                    treasury,
                    rewardSnapshot[tokensToBeRewardedAddress[i]] /
                        IStakingManager(stakingManager).bankCut()
                );
            }
        }
    }

    /**
     * @dev WithdrawAvaxLp - EOA Withdraws Desired Balance
     * @param _amount - amount in LP tokens
     * @param _routerAddress - Trader Joe Router Address
     * @param _avaxAddress - WAVAX ERC20 Address
     * @notice - User will have reward tokens converted back into LP for reinvestment
     *           Salvo will receive 25% of rewards and hold for community price stab.
     *           and ability to earn passive revenue from governance tokens.
     */

    function withdrawAvaxLp(
        uint256 _amount,
        address _routerAddress,
        address _avaxAddress
    ) public verifyPool nonReentrant {
        require(paused == false, "Contract is Paused.");
        require(_amount > 0, "Withdraw Amount Equal to Zero.");
        (uint256 stakerAmount, uint256 stakerReward, ) = IStakingManager(
            stakingManager
        ).poolStakers(poolId, tx.origin);

        require(
            stakerAmount +
                stakerReward +
                IStakingManager(stakingManager).pendingRewards(
                    poolId,
                    tx.origin
                ) >=
                _amount,
            "Insufficient Funds from Staking Manager."
        );
        /*
         *
         * 1. Withdraw Specified Amount of LP Tokens
         *
         */
        uint256 initLpBal = IERC20(investmentAddress).balanceOf(address(this));
        IVector(investmentAddress).withdraw(_amount);
        uint256 differenceBal = initLpBal -
            IERC20(investmentAddress).balanceOf(address(this));
        /*
         *
         * 2. Remove Liquidity from Pool
         *
         */
        // a. Calculate number of pair 1 and pair 2 tokens to request at swap
        uint256 lpTotalSupply = IERC20(liquidityPool).totalSupply();
        uint256 token0Entitlement = getSlippage(
            (((differenceBal * 1e12) / lpTotalSupply) *
                IERC20(targetToken[0]).balanceOf(liquidityPool)) / 1e12,
            98
        );
        uint256 token1Entitlement = getSlippage(
            (((differenceBal * 1e12) / lpTotalSupply) *
                IERC20(targetToken[1]).balanceOf(liquidityPool)) / 1e12,
            98
        );
        // b. Using calculated values, request withdrawal of both tokens
        checkAllowance(liquidityPool, _routerAddress);
        IJoeRouter(_routerAddress).removeLiquidityAVAX(
            targetToken[0],
            differenceBal,
            token0Entitlement,
            token1Entitlement,
            tx.origin,
            block.timestamp + 3600
        );
        /*
         *
         * 3. Store New Reward Balances into rewardSnapshot
         * 3a. rewardSnapshot - array tracking rewards harvested from round
         * 3b. Transfer to Treasury
         *
         */
        for (uint8 i = 0; i < tokensToBeRewardedAddress.length; i++) {
            // 3a.
            rewardSnapshot[tokensToBeRewardedAddress[i]] = IERC20(
                tokensToBeRewardedAddress[i]
            ).balanceOf(address(this));
            // 3b.
            if (rewardSnapshot[tokensToBeRewardedAddress[i]] != 0) {
                IERC20(tokensToBeRewardedAddress[i]).transfer(
                    treasury,
                    rewardSnapshot[tokensToBeRewardedAddress[i]] /
                        IStakingManager(stakingManager).bankCut()
                );
            }
        }
        /*
         *
         * 4. Debit Withdrawal from Depositor via StakingManager
         *
         */
        IStakingManager(stakingManager).withdraw(poolId, differenceBal, 0);
    }

    function reinvest(
        address _routerAddress,
        address _avaxAddress,
        uint256 _slippage
    ) external onlyOwner {
        /*
         *
         * 1. Reinvest Rewards Back Into LP
         *
         */

        (bool successSwapRewards, ) = investorHelper.delegatecall(
            abi.encodeWithSignature(
                "swapRewardsForLp(address,address,uint256)",
                _routerAddress,
                _avaxAddress,
                _slippage
            )
        );
        require(successSwapRewards == true, "Swap Rewards for LP Failed.");
        uint256 token0Amount = IERC20(targetToken[0]).balanceOf(address(this));
        uint256 token1Amount = IERC20(targetToken[1]).balanceOf(address(this));
        uint256 avaxAmount = payable(address(this)).balance;
        uint256 joeAmount = IERC20(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd)
            .balanceOf(address(this));

        emit tokensGained(poolId, token0Amount, token1Amount, avaxAmount);
        (bool successReinvest, bytes memory dataReinvest) = investorHelper
            .delegatecall(
                abi.encodeWithSignature(
                    "reinvestLp(address,address,uint256)",
                    _routerAddress,
                    _avaxAddress,
                    _slippage
                )
            );
        require(successReinvest == true, "Reinvesting LP Failed.");
        uint256 lpEarned = IERC20(liquidityPool).balanceOf(address(this));
        emit LpEarned(poolId, lpEarned);
        //EMIT LP EARNED
        IVector(investmentAddress).deposit(
            IERC20(liquidityPool).balanceOf(address(this))
        );
        /*
         *
         * 2. Reinvest Rewards Back Into LP
         *
         */
        if (lastClaim + 1 days < block.timestamp) {
            last24Apr = aprTracker; // Record the grand total over the past 24 hours
            aprTracker = lpEarned; // Restart apr tracker with new lpearned
            lastClaim = block.timestamp; //Set last claim to now to begin new 24 hour window
        } else {
            aprTracker = aprTracker + lpEarned; //Add on to current tracker
        }
        IStakingManager(stakingManager).ownerUpdatePoolRewards(
            poolId,
            lpEarned
        );
    }

    /**
     * @dev Get Exchange Rate
     * @param _amountIn - amount of token to swap for desired token
     * @param _routerAddr - Trader Joe Router Address
     * @param _tokenPath - path to sell and buy token
     * @return - exchangeRate uint256[] - 0 first token, 1 second token etc
     */
    function getExchangeRate(
        uint256 _amountIn,
        address _routerAddr,
        address[] memory _tokenPath
    ) public payable returns (uint256[] memory) {
        uint256[] memory exchangeRate;
        exchangeRate = IJoeRouter(_routerAddr).getAmountsOut(
            _amountIn,
            _tokenPath
        );
        return exchangeRate;
    }

    /**
     * @dev getSlippage
     * @param _amount - amount of token
     * @param _slippage - uint serving as percentage representation
     * @return uint256 discounted amount
     */
    function getSlippage(uint256 _amount, uint256 _slippage)
        internal
        pure
        returns (uint256)
    {
        return ((((_amount * 100) / 100) * _slippage) / 100);
    }

    /**
     * @dev Pause Contract
     */
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Change the stakingManager
     */
    function changeStakingManager(address _newStakingManager)
        external
        onlyOwner
    {
        stakingManager = _newStakingManager;
    }

    /**
     * @dev Changes the order for the target token array
     * @param _array - array intended to be reversed in order
     * @notice Only works for address arrays. Used to reverse my state
     *         storage targetToken when I am swapping pair1 for pair0
     */
    function reverseArray(address[] memory _array)
        public
        pure
        returns (address[] memory)
    {
        uint256 length = _array.length;
        address[] memory reversedArray = new address[](length);
        uint256 j = 0;
        for (uint256 i = length; i >= 1; i--) {
            reversedArray[j] = _array[i - 1];
            j++;
        }
        return reversedArray;
    }

    /**
     * Universal Transfer
     * @dev Owner has the ability to move sitting tokens to the treasury
     *      to put funds to work.
     * @param _tokenAddress - Token Address sitting in wallet
     * @param _amount - Amount of desired token to transfer
     * @notice Funds can only be transferred to owner-specified treasury
     *         which is defined as the state storage variable - 'treasury'
     */
    function universalTransfer(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "Universal Transfer amount cannot be zero.");
        IERC20(_tokenAddress).transfer(treasury, _amount);
    }

    /**
     * @dev Owner has the ability to transfer LP tokens to Treasury in case of emergency
     *      or if investor contracts are being switched to another pool
     * @notice This is not a rug function. I care about my life... -King Salvo
     */
    function evacuateFunds() external onlyOwner {
        require(
            paused == true,
            "Contract must be paused before performing this operation."
        );
        // Withdraw Entire Amount
        uint256 totalAmount = IERC20(investmentAddress).balanceOf(
            address(this)
        );
        IVector(investmentAddress).withdraw(totalAmount);
        IERC20(liquidityPool).transfer(
            treasury,
            IERC20(liquidityPool).balanceOf(address(this))
        );
    }

    function evacuateAvax() external onlyOwner {
        uint256 avaxAmount = payable(address(this)).balance;
        treasury.transfer(avaxAmount);
    }

    /**
     * @dev Check Allowance
     * Checks to make sure contract has extended permissions to other contracts
     * @param _tokenAddress - Token address to seek approval for
     * @param _spender - Designated spender per ERC20 requirements
     */
    function checkAllowance(address _tokenAddress, address _spender) public {
        uint256 permittedFunds = IERC20(_tokenAddress).allowance(
            address(this),
            _spender
        );
        if (
            permittedFunds !=
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        ) {
            IERC20(_tokenAddress).approve(
                _spender,
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            );
        }
    }

    /**
     * @dev Change Helper Address
     * In place to switch address in case I have to replace helper
     * due to faulty code
     * @param _newAddr - new address for helper
     */
    function changeHelperAddress(address _newAddr) external onlyOwner {
        investorHelper = _newAddr;
    }

    fallback() external payable {}

    receive() external payable {}
}