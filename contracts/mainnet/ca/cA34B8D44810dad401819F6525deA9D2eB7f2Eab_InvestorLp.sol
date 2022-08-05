/**
 *Submitted for verification at snowtrace.io on 2022-08-04
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

interface IJoe {
    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external;
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

contract InvestorLp is Ownable {
    //LEAVE BLANK for OWNER VARIABLE - Delegatecall variables need to match
    /*
     * Router Settings - permanent address delegatecalled to here
     */
    address public addressRouter;
    /*
     * @dev Helper Router points to the address containing the helper contract
     */
    address payable public helperRouter;
    /*
     * @dev Swap Router points to the address containing swap operations
     */
    address payable public swapRouter;
    /*
     * Target Token Settings [0] pair, [1] avax
     */
    address[] public targetToken;
    /*
     * Target Token Settings - Inverted
     */
    address[] public targetTokenReversed;
    /*
     * Investment Address - staking contract
     */
    address payable public investmentAddress;
    /*
     * Liquidity Pool - Address where pair is held
     */
    address payable public liquidityPool;
    /*
     * @dev Tokens to Be Rewarded by their Contract Address
     */
    address[] public tokensToBeRewardedAddress;
    /*
     * @dev Token Names - Helps determine source

     */
    string[] public tokensToBeRewardedName;
    /*
     * totalInvestment - Keeps track of totalInvestment held by smart contract
     */
    uint256 public totalInvestment;

    /*
     * Accounting Ledger
     * @dev Keeps track of amount in respective currency held by a wallet
     * NOTE: Absolute terms, not percentage stored as means of accounting
     */
    mapping(address => uint256) public accountingLedger;

    /*
     * WalletArr
     * @dev Keeps track of wallets stored to determine reward distribution
     * NOTE: If user withdraws full amount, it must be removed from array
     */
    address[] public walletArr;

    /*
     * Accumulated Profit
     * @dev Keeps track of outstanding profits
     * NOTE: Profits are automatically recompounded but this will keep track
     * of gross gains
     * NOTE: accounting ledger is still the absolute truth of fund allocation
     */
    mapping(address => uint256) public accumulatedProfit;
    /*
     * Rewards Snapshot
     * @dev Contains the rewards received from pool
     */
    mapping(address => uint256) public rewardSnapshot;

    /*
     * APR Tracker
     * @dev Contains the rewards received from pool
     */
    uint256 public aprTracker;

    /*
     * Last Claim
     * @dev Saves the timestamp for last time owner made a rewards claim
     * NOTE: Prevents abusive accounts from timing their account deposits with
     * rewards claims
     */
    uint256 public lastClaim;

    /*
     * Last Wallet Arr
     * @dev Saves wallets that have had their deposits
     * NOTE: Prevents abusive accounts from timing their account deposits with
     * rewards claims
     */
    address[] public lastWalletArr;

    /*
     * Investor Helper
     * @dev Tools like accounting and calc commission
     */
    address public investorHelper;

    /*
     * Mutex
     * @dev Prevents reentry on withdrawal
     */
    bool public mutex;

    /*
     * paused
     * @dev Pauses contract for maintenance
     */
    bool public paused;

    constructor(
        address _helper,
        address _swap,
        address[] memory _targetToken,
        address[] memory _targetTokenReversed,
        address _addressRouter,
        address _investmentAddress,
        address _liquidityPool,
        address[] memory _tokensToBeRewardedAddress,
        string[] memory _tokensToBeRewardedName,
        address _investorHelper
    ) {
        helperRouter = payable(_helper);
        swapRouter = payable(_swap);
        targetToken = _targetToken;
        targetTokenReversed = _targetTokenReversed;
        addressRouter = _addressRouter;
        investmentAddress = payable(_investmentAddress);
        liquidityPool = payable(_liquidityPool);
        tokensToBeRewardedAddress = _tokensToBeRewardedAddress;
        tokensToBeRewardedName = _tokensToBeRewardedName;
        lastClaim = block.timestamp;
        investorHelper = _investorHelper;
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
    ) public payable {
        require(msg.value > 0, "Amount to Deposit is Zero or Less.");
        require(paused == false, "Contract is Paused.");
        require(mutex == false, "Reentry Detected.");
        mutex = true;
        address tokenAddress = IAddressRouter(addressRouter)
            .viewAddressDirectory(_tokenName);
        address avaxAddress = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        //1. Swap AVAX for respective token
        swapExactAvaxForToken(
            setSlippage(
                getExchangeRate(msg.value / 2, targetTokenReversed)[1],
                98
            ),
            msg.value / 2,
            tokenAddress
        );
        //2. Add Liquidity & Receive LP Token in Return
        (bool successLiquidity, bytes memory dataLiquidity) = investorHelper
            .delegatecall(
                abi.encodeWithSignature(
                    "addLiquidity(address,address,uint256)",
                    tokenAddress,
                    avaxAddress,
                    msg.value / 2
                )
            );
        require(successLiquidity, "Delegatecall to addLiquidity Failed.");
        //3. Deposit LP Tokens into Vector
        //a. Grab initial balance before deposit
        uint256 initBal = IERC20(investmentAddress).balanceOf(address(this));
        address spender = IAddressRouter(addressRouter).viewAddressDirectory(
            _spender
        );
        depositLpTokensNative(spender);
        //b. Grab balance after deposit
        uint256 differenceBal = IERC20(investmentAddress).balanceOf(
            address(this)
        ) - initBal;
        //4. Perform Accounting on depositors share
        accountingLedger[msg.sender] =
            accountingLedger[msg.sender] +
            differenceBal;
        if (findElementInArray(msg.sender, walletArr) == -1) {
            walletArr.push(msg.sender);
        }
        totalInvestment = totalInvestment + differenceBal;
        //Deposits are disqualifications for next claim round
        /*
        if (lastWalletArr.length > 0) {
            int256 index = findElementInArray(msg.sender, lastWalletArr);
            if (index != -1) {
                removeFromLastWalletArr(index);
            }
        }
        */
        mutex = false;
    }

    /**
     * @dev Claim Pending Rewards for LP Staking
     */
    uint256 public cyp;

    function routerWithdraw(uint256 _amount, address _spenderAddress) public {
        require(paused == false, "Contract is Paused.");
        require(mutex == false, "Reentry Detected");
        require(_amount > 0, "Withdraw Amount Equal to Zero.");
        require(accountingLedger[msg.sender] >= _amount);

        mutex = true;
        //1. Withdraw

        uint256 initLpBal = IERC20(investmentAddress).balanceOf(address(this));
        (bool successWithdraw, bytes memory dataWithdraw) = helperRouter
            .delegatecall(
                abi.encodeWithSignature(
                    "withdrawLp(uint256,address)",
                    _amount,
                    investmentAddress
                )
            );
        require(successWithdraw, "Delegate Call Withdrawing from Lp Failed.");

        //2. Accounting
        uint256 differenceBal = initLpBal -
            IERC20(investmentAddress).balanceOf(address(this));
        accountingLedger[msg.sender] =
            accountingLedger[msg.sender] -
            differenceBal;
        if (accountingLedger[msg.sender] == 0) {
            int256 index = findElementInArray(msg.sender, walletArr);
            removeFromWalletArr(index);
        }
        if (accumulatedProfit[msg.sender] < differenceBal) {
            accumulatedProfit[msg.sender] = 0;
        } else {
            accumulatedProfit[msg.sender] =
                accumulatedProfit[msg.sender] -
                differenceBal;
        }
        totalInvestment = totalInvestment - differenceBal;

        //3. Transfer funds to client
        address avaxAddress = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");

        uint256 jlpRatio = IERC20(liquidityPool).totalSupply() / differenceBal;
        uint256 token0Entitlement = setSlippage(
            IERC20(targetToken[0]).balanceOf(liquidityPool) / jlpRatio,
            98
        );
        uint256 token1Entitlement = setSlippage(
            IERC20(targetToken[1]).balanceOf(liquidityPool) / jlpRatio,
            98
        );

        //CONDUCT SWAP BACK TO WALLET
        IERC20(liquidityPool).approve(
            0x60aE616a2155Ee3d9A68541Ba4544862310933d4,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );

        IJoe(0x60aE616a2155Ee3d9A68541Ba4544862310933d4).removeLiquidityAVAX(
            targetToken[0],
            differenceBal,
            token0Entitlement,
            token1Entitlement,
            msg.sender,
            block.timestamp + 3600
        );

        //4. Store End Reward Balance into rewardSnapshot
        for (uint8 i = 0; i < tokensToBeRewardedAddress.length; i++) {
            rewardSnapshot[tokensToBeRewardedAddress[i]] = IERC20(
                tokensToBeRewardedAddress[i]
            ).balanceOf(address(this));
        }

        //5. Transfer to Treasury
        for (uint8 i = 0; i < tokensToBeRewardedAddress.length; i++) {
            if (rewardSnapshot[tokensToBeRewardedAddress[i]] != 0) {
                IERC20(tokensToBeRewardedAddress[i]).transfer(
                    IAddressRouter(addressRouter).viewAddressDirectory(
                        "Treasury"
                    ),
                    rewardSnapshot[tokensToBeRewardedAddress[i]] /
                        IAddressRouter(addressRouter).bankCut()
                );
            }
        }
        //6. Reinvest Rewards Back Into LP

        (bool successReinvest, bytes memory dataReinvest) = investorHelper
            .delegatecall(
                abi.encodeWithSignature(
                    "reinvestAvaxLP(address[],address[],address)",
                    targetToken,
                    tokensToBeRewardedAddress,
                    _spenderAddress
                )
            );
        uint256 lpEarned = abi.decode(dataReinvest, (uint256));
        cyp = lpEarned;
        /*
        if (lastClaim + 1 days > block.timestamp) {
            aprTracker = 0;
            lastClaim = block.timestamp;
        } else {
            aprTracker = aprTracker + lpEarned;
        }
        //7. Distribute Rewards via accounting
        (bool successRewards, bytes memory dataRewards) = investorHelper
            .delegatecall(
                abi.encodeWithSignature(
                    "distributeRewards(uint256,address[])",
                    lpEarned,
                    lastWalletArr.length > 0 ? lastWalletArr : walletArr
                )
            );
        require(successRewards, "Delegate Call to Distribute Rewards Failed.");
        mutex = false;
        */
    }

    /**
     * @dev Deposit LP Native
     * _pair1Token & pair2Token - address for LP Pair Tokens
     * _slippage - sets min value in transaction
     */
    function depositLpTokensNative(address _spender) internal {
        (bool success, bytes memory data) = helperRouter.delegatecall(
            abi.encodeWithSignature(
                "depositLPNative(uint256,address,address,address)",
                IERC20(liquidityPool).balanceOf(address(this)),
                liquidityPool,
                _spender,
                investmentAddress
            )
        );
        require(success, "depositLPNative helper call failed.");
    }

    function swapExactAvaxForToken(
        uint256 _amountOutMin,
        uint256 _avaxAmount,
        address _buyTokenContract
    ) public payable {
        //Claim Rewards
        (bool success, bytes memory data) = swapRouter.delegatecall(
            abi.encodeWithSignature(
                "exchangeExactAvaxForTokens(uint256,uint256,address)",
                _amountOutMin,
                _avaxAmount,
                _buyTokenContract
            )
        );
        require(success, "Could not swap AVAX for desired token.");
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

    function setSlippage(uint256 _amount, uint256 _slippage)
        internal
        pure
        returns (uint256)
    {
        return (_amount - (_amount / _slippage));
    }

    /**
     * @dev Shows index of requested element
     * _element - item to search for in array
     * returns index || -1 if nothing was found
     */
    function findElementInArray(address _element, address[] memory arr)
        internal
        returns (int256)
    {
        for (int256 i = 0; i < int256(arr.length); i++) {
            if (_element == arr[uint256(i)]) {
                return i;
            }
        }
        return -1;
    }

    /**
     * @dev Remove From Last Wallet Arr
     * _index - will remove address from Last Wallet
     * Note: Prevents deposit abusers from claiming higher rewards
     */
    function removeFromLastWalletArr(int256 _index) internal {
        uint256 castedIndex = uint256(_index);
        require(lastWalletArr.length > castedIndex, "Out of bounds");
        // move all elements to the left, starting from the `index + 1`
        for (uint256 i = castedIndex; i < lastWalletArr.length - 1; i++) {
            lastWalletArr[i] = lastWalletArr[i + 1];
        }
        lastWalletArr.pop(); // delete the last item
    }

    /**
     * @dev Delete element by index in array
     * _index - index to delete respective element
     */
    function removeFromWalletArr(int256 _index) internal {
        uint256 castedIndex = uint256(_index);
        require(walletArr.length > castedIndex, "Out of bounds");
        // move all elements to the left, starting from the `index + 1`
        for (uint256 i = castedIndex; i < walletArr.length - 1; i++) {
            walletArr[i] = walletArr[i + 1];
        }
        walletArr.pop(); // delete the last item
    }

    function disengageMutex() public onlyOwner {
        if (mutex == true) {
            mutex = false;
        }
    }

    function togglePause() public onlyOwner {
        if (paused == true) {
            paused = false;
        } else {
            paused = true;
        }
    }

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

    /*
     * @dev 4 change functions shift addresses in case of contract changes
     *
     */
    function changeInvestmentAddress(address _newAddress) public onlyOwner {
        require(
            _newAddress != 0x0000000000000000000000000000000000000000,
            "Invalid address."
        );
        investmentAddress = payable(_newAddress);
    }

    function changeHelperRouter(address _newAddress) public onlyOwner {
        require(
            _newAddress != 0x0000000000000000000000000000000000000000,
            "Invalid address."
        );
        helperRouter = payable(_newAddress);
    }

    function changeInvestorHelper(address _newAddress) public onlyOwner {
        require(
            _newAddress != 0x0000000000000000000000000000000000000000,
            "Invalid address."
        );
        investorHelper = _newAddress;
    }

    function changeswapRouter(address _newAddress) public onlyOwner {
        require(
            _newAddress != 0x0000000000000000000000000000000000000000,
            "Invalid address."
        );
        swapRouter = payable(_newAddress);
    }

    fallback() external payable {}

    receive() external payable {}
}