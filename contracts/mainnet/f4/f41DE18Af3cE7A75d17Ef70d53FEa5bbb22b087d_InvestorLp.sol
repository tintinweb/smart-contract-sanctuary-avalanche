/**
 *Submitted for verification at snowtrace.io on 2022-08-18
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

interface IAddressRouter {
    function viewAddressDirectory(string memory _name)
        external
        view
        returns (address);

    function beneficiaryCut() external view returns (uint8);

    function affiliateCut() external view returns (uint8);

    function bankCut() external view returns (uint8);

    function clientis(address _client) external view returns (address);

    function fraternitasReferral(address _referral)
        external
        view
        returns (address);
}

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
}

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
}

contract InvestorLp is Ownable {
    /*
     * 1.
     * Router Settings - permanent address delegatecalled to here
     */
    address public addressRouter;
    /*
     * 2.
     * StakingManager - Contract address to handle accounting
     */
    address public stakingManager;
    /*
     * 3.
     * @dev Helper Router points to the address containing the helper contract
     */
    address payable public helperRouter;
    /*
     * 4.
     * @dev Swap Router points to the address containing swap operations
     */
    address payable public swapRouter;
    /*
     * 5.
     * Target Token Settings [0] pair, [1] avax
     */
    address[] public targetToken;
    /*
     * 6.
     * Investment Address - staking contract
     */
    address payable public investmentAddress;
    /*
     * 7.
     * Liquidity Pool - Address where pair is held
     */
    address payable public liquidityPool;
    /*
     * 8.
     * @dev Tokens to Be Rewarded by their Contract Address
     */
    address[] public tokensToBeRewardedAddress;
    /*
     * 9.
     * @dev Token Names - Helps determine source
     *
     */
    string[] public tokensToBeRewardedName;

    /*
     * 10.
     * Rewards Snapshot
     * @dev Contains the rewards received from pool
     */
    mapping(address => uint256) public rewardSnapshot;

    /*
     * 11.
     * APR Tracker
     * @dev Contains the rewards received from pool
     */
    uint256 public aprTracker;

    /*
     * 12.
     * Last Claim
     * @dev Saves the timestamp for last time owner made a rewards claim
     * NOTE: Prevents abusive accounts from timing their account deposits with
     * rewards claims
     */
    uint256 public lastClaim;

    /*
     * 13.
     * Investor Helper
     * @dev Tools like accounting and calc commission
     */
    address public investorHelper;

    /*
     * 14.
     * @dev poolId that communicates where amount and rewards are stored
     *      in StakingManager contract
     */
    uint256 public poolId;

    /*
     * 15.
     * Mutex
     * @dev Prevents reentry on withdrawal
     */
    bool public mutex;

    /*
     * 16.
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

    constructor(
        address _helper,
        address _swap,
        address[] memory _targetToken,
        address _addressRouter,
        address _stakingManager,
        address _investmentAddress,
        address _liquidityPool,
        address[] memory _tokensToBeRewardedAddress,
        string[] memory _tokensToBeRewardedName,
        address _investorHelper,
        uint256 _poolId
    ) {
        helperRouter = payable(_helper);
        swapRouter = payable(_swap);
        targetToken = _targetToken;
        addressRouter = _addressRouter;
        stakingManager = _stakingManager;
        investmentAddress = payable(_investmentAddress);
        liquidityPool = payable(_liquidityPool);
        tokensToBeRewardedAddress = _tokensToBeRewardedAddress;
        tokensToBeRewardedName = _tokensToBeRewardedName;
        lastClaim = block.timestamp;
        investorHelper = _investorHelper;
        poolId = _poolId;
        mutex = false;
        paused = false;
    }

    /**
     * @dev Router Deposit Avax LP
     * _tokenName - name of token that will serve as pair1
     * _spender - spender is the staking contract giving it permission to move your JLP tokens
     */
    function routerDepositAvaxLp(
        string memory _tokenName,
        string memory _spender
    ) public payable verifyPool {
        require(msg.value > 0, "Amount to Deposit is Zero or Less.");
        require(paused == false, "Contract is Paused.");
        require(mutex == false, "Reentry Detected.");
        mutex = true;
        address tokenAddress = IAddressRouter(addressRouter)
            .viewAddressDirectory(_tokenName);
        address avaxAddress = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        /*
         *
         * 1. Swap AVAX for respective token
         *
         */
        address[] memory _targetToken = targetToken;
        (bool successSwapAvax, ) = swapRouter.delegatecall(
            abi.encodeWithSignature(
                "exchangeExactAvaxForTokens(uint256,uint256,address)",
                setSlippage(
                    getExchangeRate(msg.value / 2, reverseArray(_targetToken))[
                        1
                    ],
                    98
                ),
                msg.value / 2,
                tokenAddress
            )
        );
        require(successSwapAvax, "Could not swap AVAX for desired token.");
        /*
         *
         * 2. Add Liquidity & Receive LP Tokens in Return
         *
         */
        (bool successLiquidity, ) = investorHelper.delegatecall(
            abi.encodeWithSignature(
                "addLiquidity(address,address,uint256)",
                tokenAddress,
                avaxAddress,
                msg.value / 2
            )
        );
        require(successLiquidity, "Delegatecall to addLiquidity Failed.");
        /*
         *
         * 3. Deposit LP Tokens into Vector
         *
         */
        // a. Grab initial LP token balance before deposit
        uint256 initBal = IERC20(investmentAddress).balanceOf(address(this));
        // b. Deposit AVAX LP Tokens
        if (IERC20(liquidityPool).balanceOf(address(this)) > 0) {
            (bool successDeposit, ) = helperRouter.delegatecall(
                abi.encodeWithSignature(
                    "depositLPNative(uint256,address,address,address)",
                    IERC20(liquidityPool).balanceOf(address(this)),
                    liquidityPool,
                    IAddressRouter(addressRouter).viewAddressDirectory(
                        _spender
                    ),
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
        mutex = false;
    }

    /**
     * @dev routerWithdraw - EOA Withdraw Balance
     * @notice User will have reward tokens converted back into LP for reinvestment
     *         Salvo will receive 25% of rewards and hold for community price stab.
     *         and ability to earn passive revenue from governance tokens.
     */
    function routerWithdraw(uint256 _amount, address _spenderAddress)
        public
        payable
        verifyPool
    {
        require(paused == false, "Contract is Paused.");
        require(mutex == false, "Reentry Detected");
        require(_amount > 0, "Withdraw Amount Equal to Zero.");
        (uint256 stakerAmount, uint256 stakerReward, ) = IStakingManager(
            stakingManager
        ).poolStakers(poolId, msg.sender);
        require(stakerAmount + stakerReward >= _amount);

        mutex = true;
        /*
         *
         * 1. Withdraw Specified Amount of LP Tokens
         *
         */
        uint256 initLpBal = IERC20(investmentAddress).balanceOf(address(this));
        (bool successWithdraw, ) = helperRouter.delegatecall(
            abi.encodeWithSignature(
                "withdrawLp(uint256,address)",
                _amount,
                investmentAddress
            )
        );
        require(successWithdraw, "Delegate Call Withdrawing from Lp Failed.");
        uint256 differenceBal = initLpBal -
            IERC20(investmentAddress).balanceOf(address(this));
        /*
         *
         * 2. Remove Liquidity from Pool
         *
         */
        // a. Calculate number of pair 1 and pair 2 tokens to request at swap
        uint256 PRECISION = 1e12;

        uint256 token0Entitlement = setSlippage(
            (((differenceBal * PRECISION) /
                IERC20(liquidityPool).totalSupply()) *
                IERC20(targetToken[0]).balanceOf(liquidityPool)) / PRECISION,
            98
        );
        uint256 token1Entitlement = setSlippage(
            (((differenceBal * PRECISION) /
                IERC20(liquidityPool).totalSupply()) *
                IERC20(targetToken[1]).balanceOf(liquidityPool)) / PRECISION,
            98
        );
        // b. Using calculated values, request withdrawal of both tokens
        (bool successRemove, ) = swapRouter.delegatecall(
            abi.encodeWithSignature(
                "removeAvaxLiquidity(address,address,uint256,uint256,uint256)",
                targetToken[0],
                liquidityPool,
                differenceBal,
                token0Entitlement,
                token1Entitlement
            )
        );
        require(
            successRemove == true,
            "Delegate Call Removing Liquidity Failed"
        );
        /*
         *
         * 3. Store New Reward Balances into rewardSnapshot
         * 3a. rewardSnapshot - array tracking rewards harvested from round
         *
         */
        for (uint8 i = 0; i < tokensToBeRewardedAddress.length; i++) {
            rewardSnapshot[tokensToBeRewardedAddress[i]] = IERC20(
                tokensToBeRewardedAddress[i]
            ).balanceOf(address(this));
        }
        /*
         *
         * 4. Transfer to Treasury
         * 4a. Grabs reward value from rewardSnapshot &
         *     transfers 25% to Salvo treasury
         *
         */
        for (uint8 i = 0; i < tokensToBeRewardedAddress.length; i++) {
            if (rewardSnapshot[tokensToBeRewardedAddress[i]] != 0) {
                IERC20(tokensToBeRewardedAddress[i]).transfer(
                    IAddressRouter(addressRouter).viewAddressDirectory(
                        "Treasury"
                    ),
                    rewardSnapshot[tokensToBeRewardedAddress[i]] /
                        IStakingManager(stakingManager).bankCut()
                );
            }
        }
        /*
         *
         * 5. Reinvest Rewards Back Into LP
         *
         */
        (bool successReinvest, bytes memory dataReinvest) = investorHelper
            .delegatecall(
                abi.encodeWithSignature(
                    "reinvestAvaxLP(address[],address[],address)",
                    targetToken,
                    tokensToBeRewardedAddress,
                    _spenderAddress
                )
            );
        require(successReinvest == true, "Delegate Call Reinvest to LP Failed");
        uint256 lpEarned = abi.decode(dataReinvest, (uint256));
        /*
         *
         * 6. Reinvest Rewards Back Into LP
         *
         */
        if (lastClaim + 1 days < block.timestamp) {
            aprTracker = lpEarned;
            lastClaim = block.timestamp;
        } else {
            aprTracker = aprTracker + lpEarned;
        }
        /*
         *
         * 7. Debit Withdrawal from Depositor via StakingManager
         *
         */
        IStakingManager(stakingManager).withdraw(
            poolId,
            differenceBal,
            lpEarned
        );

        mutex = false;
    }

    /**
     * @dev Get Exchange RATE
     * _amountIn - amount of token to swap for
     * _tokenPath - path to sell and buy token
     * returns exchangeRate - 0 first token, 1 second token etc
     */
    function getExchangeRate(uint256 _amountIn, address[] memory _tokenPath)
        public
        payable
        returns (uint256[] memory)
    {
        (bool success, bytes memory data) = swapRouter.delegatecall(
            abi.encodeWithSignature(
                "calculateExchangeRate(uint256,address[])",
                _amountIn,
                _tokenPath
            )
        );
        uint256[] memory exchangeRate = abi.decode(data, (uint256[]));
        return exchangeRate;
    }

    /**
     * @dev setSlippage
     * _amount - amount of token
     * _slippage - uint serving as percentage representation
     * returns discounted amount
     */
    function setSlippage(uint256 _amount, uint256 _slippage)
        internal
        pure
        returns (uint256)
    {
        uint256 PRECISION = 10000;
        return (((_amount * PRECISION) / 100) * _slippage) / PRECISION;
    }

    /**
     * @dev Switches mutex to false
     */
    function disengageMutex() external onlyOwner {
        if (mutex == true) {
            mutex = false;
        }
    }

    /**
     * @dev Pause Contract
     */
    function togglePause() external onlyOwner {
        if (paused == true) {
            paused = false;
        } else {
            paused = true;
        }
    }

    /**
     * @dev Change the poolId
     */
    function changePoolId(uint256 _newId) external onlyOwner {
        poolId = _newId;
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
     * @notice Only works for address arrays
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
     * @notice Funds can only be transferred by owner-specified treasury
     */
    function universalTransfer(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "Universal Transfer amount cannot be zero.");
        address _treasury = IAddressRouter(addressRouter).viewAddressDirectory(
            "Treasury"
        );
        IERC20(_tokenAddress).transfer(_treasury, _amount);
    }

    /**
     * @dev Owner has the ability to transfer LP tokens to Treasury in case of emergency
     *      or if investor contracts are being switched to another pool
     * @notice This is not a rug function. I care about my life... -King Salvo
     */
    function evacuateFunds() public onlyOwner {
        require(
            paused == true,
            "Contract must be paused before performing this operation."
        );
        //Withdraw Entire Amount
        (bool successWithdraw, bytes memory dataWithdraw) = helperRouter
            .delegatecall(
                abi.encodeWithSignature(
                    "withdrawLp(uint256,address)",
                    IERC20(investmentAddress).balanceOf(address(this)),
                    investmentAddress
                )
            );
        require(
            successWithdraw,
            "Delegate Call for Evacuation Withdrawing from Lp Failed."
        );
        IERC20(liquidityPool).transfer(
            IAddressRouter(addressRouter).viewAddressDirectory("Treasury"),
            IERC20(liquidityPool).balanceOf(address(this))
        );
    }

    function secondWithdrawal(uint256 _amount, address _spenderAddress)
        public
        payable
        verifyPool
    {
        //Withdraw Entire Amount
        (bool successWithdraw, bytes memory dataWithdraw) = investorHelper
            .delegatecall(
                abi.encodeWithSignature(
                    "routerWithdraw1(uint256,address)",
                    _amount,
                    _spenderAddress
                )
            );
        require(successWithdraw, "Delegate Call Second Withdrawal Failed");
    }

    fallback() external payable {}

    receive() external payable {}
}