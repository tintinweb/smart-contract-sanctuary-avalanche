/**
 *Submitted for verification at snowtrace.io on 2022-08-28
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

contract InvestorHelper is Ownable, ReentrancyGuard {
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

    constructor() {}

    /**
     * @dev Reinvest LP
     * Reinvest Rewards Back into LP
     * @param _spenderAddress - spender address to move tokens
     * @param _avaxAddress - ERC20 WAVAX Address
     * @notice Before swap, will check if reward amount is enough to swap for big
     *         tokens like BTC. Will use getExchangeRate to determine
     *         if I can get anything for my trade.
     */
    function reinvestLp(
        address _spenderAddress,
        address _avaxAddress,
        uint256 _slippage
    ) public {
        uint256 earnedAvax = payable(address(this)).balance;
        addAvaxPairLiquidity(
            targetToken[0],
            targetToken[1],
            _spenderAddress,
            _avaxAddress,
            earnedAvax,
            _slippage
        );
        checkAllowance(liquidityPool, _spenderAddress);
    }

    /**
     * @dev Swap Rewards For LP
     * Swap Reward Tokens for LP Pair Tokens
     * @param _spenderAddress - spender address to move tokens
     * @param _avaxAddress - ERC20 WAVAX Address
     * @notice Before swap, will check if reward amount is enough to swap for big
     *         tokens like BTC. Will use getExchangeRate to determine
     *         if I can get anything for my trade.
     */
    function swapRewardsForLp(
        address _spenderAddress,
        address _avaxAddress,
        uint256 _slippage
    ) public {
        if (payable(address(this)).balance > 0) {
            payable(treasury).transfer(payable(address(this)).balance);
        }
        if (IERC20(targetToken[0]).balanceOf(address(this)) > 0) {
            IERC20(targetToken[0]).transfer(
                treasury,
                IERC20(targetToken[0]).balanceOf(address(this))
            );
        }
        address[] memory _targetToken = targetToken;
        address[] memory _rewardToken = tokensToBeRewardedAddress;
        // LOOP & Swap Out Rewards to LP Pair Tokens
        for (uint256 i = 0; i < _rewardToken.length; i++) {
            uint256 rewardTokenBalance = IERC20(_rewardToken[i]).balanceOf(
                address(this)
            );

            if (rewardTokenBalance != 0) {
                checkAllowance(_rewardToken[i], _spenderAddress);
                rewardTokenBalance = rewardTokenBalance / 2;
                // PAIR 1 - TOKEN NOT AVAX
                if (_rewardToken[i] != _avaxAddress) {
                    address[] memory pathToken = new address[](
                        _rewardToken[i] == _avaxAddress ? 2 : 3
                    );
                    pathToken[0] = _rewardToken[i];
                    pathToken[1] = _avaxAddress;
                    pathToken[2] = _targetToken[0];
                    // To prevent rewardSellAmount being so small, I can't exchange it for any BTC as ex.
                    uint256 rewardSellAmount = getSlippage(
                        getExchangeRate(
                            rewardTokenBalance,
                            _spenderAddress,
                            pathToken
                        )[2],
                        _slippage
                    );
                    if (rewardSellAmount > 10) {
                        swapExactTokenForToken(
                            rewardTokenBalance,
                            getSlippage(
                                getExchangeRate(
                                    rewardTokenBalance,
                                    _spenderAddress,
                                    pathToken
                                )[2],
                                _slippage
                            ),
                            _targetToken[0], //Pair 1
                            pathToken[0], //Reward Token,
                            _avaxAddress,
                            _spenderAddress
                        );
                    }
                    //PAIR 1 - IF AVAX
                } else {
                    address[] memory pathToken = new address[](
                        _rewardToken[i] == _avaxAddress ? 2 : 3
                    );
                    pathToken[0] = _rewardToken[i];
                    pathToken[1] = _targetToken[0];
                    uint256 rewardSellAmount = getSlippage(
                        getExchangeRate(
                            rewardTokenBalance,
                            _spenderAddress,
                            pathToken
                        )[1],
                        _slippage
                    );
                    if (rewardSellAmount > 10) {
                        swapExactTokenForToken(
                            rewardTokenBalance,
                            rewardSellAmount,
                            _targetToken[0],
                            pathToken[0],
                            _avaxAddress,
                            _spenderAddress
                        );
                    }
                }
                //PAIR 2 (always AVAX) - IF NOT AVAX
                if (_rewardToken[i] != _avaxAddress) {
                    address[] memory pathAvax = new address[](2);
                    pathAvax[0] = _rewardToken[i];
                    pathAvax[1] = _avaxAddress;
                    uint256 rewardSellAmount = getSlippage(
                        getExchangeRate(
                            rewardTokenBalance,
                            _spenderAddress,
                            pathAvax
                        )[1],
                        _slippage
                    );
                    if (rewardSellAmount > 10) {
                        checkAllowance(_rewardToken[i], _spenderAddress);
                        address[] memory path = new address[](2);
                        path[0] = _rewardToken[i];
                        path[1] = _avaxAddress;

                        IJoeRouter(_spenderAddress).swapExactTokensForAVAX(
                            rewardTokenBalance, // Reward Token
                            rewardSellAmount, // WAVAX
                            path,
                            address(this),
                            block.timestamp + 3600
                        );
                    }
                    //PAIR 2 - IF AVAX
                } else {
                    IERC20(_avaxAddress).withdraw(rewardTokenBalance);
                }
            }
        }
    }

    /**
     * @dev add Avax Pair Liquidity
     * Converts token0 and Avax into LP token on TJ
     * @param _pair1Token - Pair 1 Token Address
     * @param _pair2Token - Pari 2 Token Address (Mostly AVAX)
     * @param _routerAddr - Trader Joe Router Address
     * @param _avaxAddr - ERC20 WAVAX Address
     * @param _avaxAmount - Amount of Avax to convert to LP token
     */
    function addAvaxPairLiquidity(
        address _pair1Token,
        address _pair2Token,
        address _routerAddr,
        address _avaxAddr,
        uint256 _avaxAmount,
        uint256 _slippage
    ) public payable {
        checkAllowance(_pair1Token, _routerAddr);
        checkAllowance(_avaxAddr, _routerAddr);
        uint256 pair1Amount = IERC20(_pair1Token).balanceOf(address(this));
        if (
            getSlippage(pair1Amount, 90) > 0 && getSlippage(_avaxAmount, 90) > 0
        ) {
            IJoeRouter(_routerAddr).addLiquidityAVAX{value: _avaxAmount}(
                _pair1Token,
                pair1Amount,
                getSlippage(pair1Amount, _slippage),
                getSlippage(_avaxAmount, _slippage),
                address(this),
                block.timestamp + 3600
            );
        }
    }

    /**
     * @dev Get Slippage
     * @param _amount - Amount in token respective decimal system
     * @param _slippage - Integer to be discounted, 95 == .95
     * @return uint256 a discounted version of intial amount
     */
    function getSlippage(uint256 _amount, uint256 _slippage)
        internal
        pure
        returns (uint256)
    {
        return ((((_amount * 100) / 100) * _slippage) / 100);
    }

    /**
     * @dev getExchangeRate
     * returns an exchang rate from swap helper on specified token
     * @param _amountIn - Amount of token planning to sell
     * @param _routerAddr - Trader Joe Router Address
     * @param _tokenPath - address[] containing all addresses involved in swap
     * @return uint256[] 0 index contains sell token, 1 index avax or sell token
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
     * @dev swapExactTokenForToken
     * Swaps tokens for avax
     * @param _amountIn - Token amount to sell
     * @param _amountOutMin - Min buy token willing to accept
     * @param _buyCurrency - Buy token address
     * @param _sellCurrency - Sell token address
     * @param _avaxAddress - ERC20 WAVAX Address
     * @param _routerAddress - Trader Joe Router Address
     */
    function swapExactTokenForToken(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _buyCurrency,
        address _sellCurrency,
        address _avaxAddress,
        address _routerAddress
    ) internal {
        //Swap Reward Token
        if (_sellCurrency != _avaxAddress) {
            address[] memory path = new address[](3);
            path[0] = _sellCurrency;
            path[1] = _avaxAddress;
            path[2] = _buyCurrency;
            IJoeRouter(_routerAddress).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                address(this),
                block.timestamp + 3600
            );
            // Swap Avax Token
        } else {
            address[] memory path = new address[](2);
            path[0] = _sellCurrency;
            path[1] = _buyCurrency;
            IJoeRouter(_routerAddress).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                address(this),
                block.timestamp + 3600
            );
        }
    }

    /**
     * @dev Deposit for Avax LP
     * @param _lpAmount lp token qty
     * @param _lpAddress lp token address
     * @param _spender spender moving funds to Vector
     * @param _investmentAddress vector staking contract
     */
    function depositLPNative(
        uint256 _lpAmount,
        address _lpAddress,
        address _spender,
        address _investmentAddress
    ) public payable {
        require(_lpAmount > 0, "LP Amount is Equal to Zero.");
        checkAllowance(_lpAddress, _spender);
        IVector(_investmentAddress).deposit(_lpAmount);
    }

    /**
     * @dev Check Allowance
     * @param _tokenAddress - address needing approval
     * @param _spender - address receiving permission
     * @notice Checks to make sure contract has extended permissions to other contracts
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

    fallback() external payable {}

    receive() external payable {}
}