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
}

contract InvestorHelper is Ownable {
    address private addressRouter;

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
     * Profit Snapshot
     * @dev Save the 24 hour rewards snapshot
     * NOTE: For documentation purposes so front-end can calculate APR on their side
     */
    mapping(address => uint256) public rewardSnapshot;

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

    constructor(address _addressRouter) {
        addressRouter = _addressRouter;
    }

    /*
     * Distributes Received Rewards
     * @dev Clients, Partners and Beneficiares All Benefit
     */
    function distributeRewards(
        uint256 _rewardsLeftover,
        address[] memory _walletArrHolder
    ) public {
        require(
            _walletArrHolder.length > 0,
            "No holders For This Investment Contract."
        );

        for (uint256 i = 0; i < _walletArrHolder.length; i++) {
            uint256 entitlement = (uint256(_rewardsLeftover) *
                ((uint256(accountingLedger[_walletArrHolder[i]]) * 1000000) /
                    uint256(totalInvestment))) / 1000000;
            //Check if Affiliate Exists
            address affiliate = IAddressRouter(addressRouter).clientis(
                _walletArrHolder[i]
            );
            //Check if Referral Exists

            if (affiliate != 0x0000000000000000000000000000000000000000) {
                uint256 affiliateCommission = calculateCommission(
                    entitlement,
                    IAddressRouter(addressRouter).affiliateCut()
                );
                //Reward Beneficiary if exists
                address beneficiary = IAddressRouter(addressRouter)
                    .fraternitasReferral(affiliate);
                if (beneficiary != 0x0000000000000000000000000000000000000000) {
                    uint256 beneficiaryCommission = calculateCommission(
                        affiliateCommission,
                        IAddressRouter(addressRouter).beneficiaryCut()
                    );
                    uint256 finalClientEntitlement = entitlement -
                        affiliateCommission;

                    accountingLedger[beneficiary] =
                        accountingLedger[beneficiary] +
                        beneficiaryCommission; //Reward Beneficiary
                    accumulatedProfit[beneficiary] =
                        accumulatedProfit[beneficiary] +
                        beneficiaryCommission;

                    accountingLedger[affiliate] =
                        accountingLedger[affiliate] +
                        affiliateCommission -
                        beneficiaryCommission; //Reward Affiliate
                    accumulatedProfit[affiliate] =
                        accumulatedProfit[affiliate] +
                        affiliateCommission -
                        beneficiaryCommission;

                    accountingLedger[_walletArrHolder[i]] =
                        accountingLedger[_walletArrHolder[i]] +
                        finalClientEntitlement; //Reward Client
                    accumulatedProfit[_walletArrHolder[i]] =
                        accumulatedProfit[_walletArrHolder[i]] +
                        finalClientEntitlement;
                } else {
                    uint256 finalClientEntitlement = entitlement -
                        affiliateCommission;

                    accountingLedger[affiliate] =
                        accountingLedger[affiliate] +
                        affiliateCommission; //Reward Affiliate
                    accumulatedProfit[affiliate] =
                        accumulatedProfit[affiliate] +
                        affiliateCommission;

                    accountingLedger[_walletArrHolder[i]] =
                        accountingLedger[_walletArrHolder[i]] +
                        finalClientEntitlement; //Reward Client
                    accumulatedProfit[_walletArrHolder[i]] =
                        accumulatedProfit[_walletArrHolder[i]] +
                        finalClientEntitlement;
                }
            } else {
                accountingLedger[_walletArrHolder[i]] =
                    accountingLedger[_walletArrHolder[i]] +
                    entitlement; //Reward Only Client
                accumulatedProfit[_walletArrHolder[i]] =
                    accumulatedProfit[_walletArrHolder[i]] +
                    entitlement;
            }
        }
    }

    /**
     * @dev Calculate Commission
     * Calculate commission using new ratio and multiplier
     * NOTE: Multiplier must be same between `calculateCommission` and `adjustCommissionRatio`
     */
    function calculateCommission(uint256 _rewardAmount, uint256 _ratio)
        public
        pure
        returns (uint256)
    {
        return ((_rewardAmount * (10000000000 / _ratio)) / 10000000000);
    }

    /**
     * @dev Reinvest LP
     * Reinvest Rewards Back into LP
     */

    function reinvestAvaxLP(
        address[] memory _targetToken,
        address[] memory _rewardToken,
        address _spenderAddress
    ) public returns (uint256) {
        address avaxAddress = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        address swapSpender = IAddressRouter(addressRouter)
            .viewAddressDirectory("SwapRouterSpender");

        uint256 initAvaxBal = payable(address(this)).balance;
        //Loop thru each reward address to swap for lp pair

        for (uint256 i = 0; i < _rewardToken.length; i++) {
            uint256 rewardBal = IERC20(_rewardToken[i]).balanceOf(
                address(this)
            );
            if (rewardBal != 0) {
                checkAllowance(_rewardToken[i], swapSpender);
                //Divide by 2 b/c LP Pair
                rewardBal = rewardBal / 2;
                //Swap Reward for Token
                address[] memory pathToken = new address[](3);
                pathToken[0] = _rewardToken[i];
                pathToken[1] = avaxAddress;
                pathToken[2] = _targetToken[0];

                swapExactTokenForToken(
                    rewardBal,
                    setSlippage(getExchangeRate(rewardBal, pathToken)[2], 95),
                    _targetToken[0],
                    pathToken[0]
                );

                //Swap Rewards for AVAX
                address[] memory pathAvax = new address[](2);
                pathAvax[0] = _rewardToken[i];
                pathAvax[1] = avaxAddress;

                swapExactTokenForAvax(
                    rewardBal,
                    setSlippage(getExchangeRate(rewardBal, pathAvax)[1], 95),
                    pathAvax[0]
                );
            }
        }

        uint256 earnedAvax = payable(address(this)).balance - initAvaxBal;
        uint256 lpBalBefore = IERC20(liquidityPool).balanceOf(address(this));

        addLiquidity(targetToken[0], targetToken[1], earnedAvax);

        uint256 vectorLPBalBefore = IERC20(investmentAddress).balanceOf(
            address(this)
        );

        depositLpTokensNative(_spenderAddress);

        return (IERC20(investmentAddress).balanceOf(address(this)) -
            vectorLPBalBefore);
    }

    /**
     * @dev Grabs TJ LP tokens and puts them in corresponding helper
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

    /**
     * @dev Add Liquidity
     * _pair1Token & pair2Token - address for LP Pair Tokens
     * _slippage - sets min value in transaction
     */
    function addLiquidity(
        address _pair1Token,
        address _pair2Token,
        uint256 _avaxAmount
    ) public payable {
        //Determine whether its avax or not
        address avaxAddress = IAddressRouter(addressRouter)
            .viewAddressDirectory("AVAX");
        uint256 pair1Amount = IERC20(_pair1Token).balanceOf(address(this));
        if (_pair2Token == avaxAddress) {
            uint256 pair2Amount = _avaxAmount;
            (bool success, bytes memory data) = swapRouter.delegatecall(
                abi.encodeWithSignature(
                    "addLiquidityAvax(address,uint256,uint256,uint256,uint256)",
                    _pair1Token,
                    pair1Amount,
                    setSlippage(pair1Amount, 95),
                    pair2Amount,
                    setSlippage(pair2Amount, 95)
                )
            );
            require(success, "Unsuccessful adding of liquidity.");
            (uint256 amount1, uint256 amount2, uint256 liquidity) = abi.decode(
                data,
                (uint256, uint256, uint256)
            );
        }
    }

    /**
     * @dev Set Slippage
     * returns a discounted version of intial amount
     */
    function setSlippage(uint256 _amount, uint256 _slippage)
        internal
        pure
        returns (uint256)
    {
        return (_amount - (_amount / _slippage));
    }

    /**
     * @dev getExchangeRate
     * returns an exchang rate from swap helper on specified token
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
     * @dev swapExactTokenForAvax
     * Swaps tokens for avax
     * _amountIn - min sell amount
     * _amountOutMin - min buy amount
     * _sellCurrency - sell token address
     */
    function swapExactTokenForAvax(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _sellCurrency
    ) internal {
        //Claim Rewards
        (bool success, bytes memory data) = swapRouter.delegatecall(
            abi.encodeWithSignature(
                "exchangeExactTokensForAvax(uint256,uint256,address)",
                _amountIn,
                _amountOutMin,
                _sellCurrency
            )
        );
        require(success, "Delegate Call Swapping Tokens for Avax Failed.");
    }

    /**
     * @dev swapExactTokenForToken
     * Swaps tokens for avax
     * _amountIn - min sell amount
     * _amountOutMin - min buy amount
     * _buyCurrency - buy token address
     * _sellCurrency - sell token address
     */
    function swapExactTokenForToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _buyCurrency,
        address _sellCurrency
    ) internal {
        //Claim Rewards
        (bool success, bytes memory data) = swapRouter.delegatecall(
            abi.encodeWithSignature(
                "exchangeExactTokensForTokens(uint256,uint256,address,address)",
                _amountIn,
                _amountOutMin,
                _buyCurrency,
                _sellCurrency
            )
        );
        require(success, "Delegeate Call To Swap Tokens for Tokens Failed.");
    }

    /**
     * @dev Check Allowance
     * _tokenAddress - address needing approval
     * _spender - address receiving permission
     * Checks to make sure contract has extended permissions to other contracts
     */
    function checkAllowance(address _tokenAddress, address _spender) internal {
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
}