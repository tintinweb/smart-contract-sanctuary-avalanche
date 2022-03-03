// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20Metadata.sol";
import "IJoePair.sol";
import "IMasterChefVTX.sol";
import "IMainStaking.sol";
import "AggregatorV3Interface.sol";

/// @title A contract for managing APR for Vector Protocol
/// @author Vector Team
/// @notice You can use this contract for getting informations about APR for pools
contract ComputeAPR is Ownable {
    AggregatorV3Interface internal priceFeed;
    uint256 constant AvaxUSDDecimals = 8;
    uint256 constant precision = 8;
    // address immutable wavax;
    // address immutable ptp;
    // address immutable xptp;
    // address immutable vtx;
    // address immutable locker;
    // address immutable masterChief;
    // address immutable mainStaking;

    address wavax;
    address ptp;
    address xptp;
    address vtx;
    address locker;
    address masterChief;
    address mainStaking;
    mapping(address => address) public tokenToWavaxPool;
    mapping(address => bool) public tokenIsLP;

    event APRInfo(
        address indexed token,
        uint256 amount,
        uint256 decimals,
        uint256 size,
        uint256 valueOfHarvest,
        uint256 valueOfPool,
        uint256 timestamp,
        address fromPool
    );

    struct Ratio {
        uint256 ratioAvaxUSD;
        uint256 valueOfPool;
        address fromPool;
    }

    constructor(
        address _wavax,
        address _ptp,
        address _xptp,
        address _mainStaking,
        address _masterChief,
        address _locker,
        address _vtx
    ) {
        priceFeed = AggregatorV3Interface(
            0x0A77230d17318075983913bC2145DB16C7366156
        );
        wavax = _wavax;
        ptp = _ptp;
        xptp = _xptp;
        locker = _locker;
        vtx = _vtx;
        mainStaking = _mainStaking;
        masterChief = _masterChief;
        tokenToWavaxPool[_ptp] = 0xCDFD91eEa657cc2701117fe9711C9a4F61FEED23;
    }

    /// @notice Returns latest price of Avax
    /// @dev Pricefeed has 8 decimals
    /// @return Returns latest price of Avax in 8 decimals
    function getAvaxLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    /// @notice Set the traderJoe liquidity pool for a specific token
    /// @param token address of the token
    /// @param wavaxPool address of the TraderJoe Pool
    /// @param isLP If the token is a liquidity Pool token, then there won't be a Wavax poole exchanging it, hence the need to know when setting up
    function setTokenToWavaxPool(
        address token,
        address wavaxPool,
        bool isLP
    ) external onlyOwner {
        require(tokenToWavaxPool[token] == address(0));
        tokenIsLP[token] = isLP;
        tokenToWavaxPool[token] = wavaxPool;
    }

    /// @notice Returns the price of the numerator in denominator, with X number of decimals. To get the price of VTX in Avax, you would call getRatio(VTX,Avax,8).
    /// @param numerator address of the numerator token
    /// @param denominator address of the denominator token
    /// @param decimals number of decimals of the returned value
    /// @return ratio of the numerator on the denominator
    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) public view returns (uint256 ratio) {
        if (
            tokenToWavaxPool[
                (denominator == wavax) ? numerator : denominator
            ] != address(0)
        ) {
            (uint256 tokenAmount0, uint256 tokenAmount1, ) = IJoePair(
                tokenToWavaxPool[
                    (denominator == wavax) ? numerator : denominator
                ]
            ).getReserves();
            return
                (numerator < denominator)
                    ? ((tokenAmount1 *
                        10**(decimals) *
                        10**IERC20Metadata(numerator).decimals()) /
                        (tokenAmount0 *
                            10**IERC20Metadata(denominator).decimals()))
                    : ((tokenAmount0 *
                        10**(decimals) *
                        10**IERC20Metadata(numerator).decimals()) /
                        (tokenAmount1 *
                            10**IERC20Metadata(denominator).decimals()));
        } else {
            return 0;
        }
    }

    /// @notice Returns the value of a liquidity pool.
    /// @param token address of the token
    /// @return valueOfLP the value of the pool with precision
    function getValueLP(address token) public view returns (uint256 valueOfLP) {
        address Pool = tokenToWavaxPool[token];
        (uint256 tokenAmount0, uint256 tokenAmount1, ) = IJoePair(Pool)
            .getReserves();
        address token0 = IJoePair(Pool).token0();
        token0 = (token0 == xptp) ? ptp : token0;
        address token1 = IJoePair(Pool).token1();
        uint256 valueToken = (
            (token0 == wavax)
                ? (tokenAmount0 * 10**precision)
                : (
                    (token1 == wavax)
                        ? (tokenAmount1 * 10**precision)
                        : (tokenAmount0 * getRatio(token0, wavax, precision))
                )
        );
        valueOfLP = (valueToken * 2) / IJoePair(Pool).totalSupply();
    }

    /// @notice Emits an event that we use to calculate the APR for a specific pool that receives fees. Has inline comments to help compute the APR.
    /// @param fromPool address of the pool where this fee has been taken from
    /// @param token address of the token of the pool
    /// @param rewardToken address of the reward token for this pool
    /// @param amountReward Amount, in rewardToken decimals, of the reward
    /// @param sizeOfPool size of the pool where the amount is distributed
    function computeAPR(
        address fromPool,
        address token,
        address rewardToken,
        uint256 amountReward,
        uint256 sizeOfPool
    ) external {
        address proxytoken = (token == locker) ? vtx : token;
        proxytoken = (proxytoken == xptp) ? ptp : proxytoken;
        address proxyRewardToken = (rewardToken == xptp) ? ptp : rewardToken;
        Ratio memory ratio;
        ratio.fromPool = fromPool;
        ratio.ratioAvaxUSD = getAvaxLatestPrice();
        if (tokenIsLP[token]) {
            ratio.valueOfPool = ((getValueLP(proxytoken) *
                ratio.ratioAvaxUSD *
                (10**IERC20Metadata(proxytoken).decimals())) / (10**precision));
        } else {
            ratio.valueOfPool =
                (getRatio(proxytoken, wavax, precision) *
                    ratio.ratioAvaxUSD *
                    sizeOfPool) /
                10**(2 * precision);
        }
        uint256 valueOfHarvest = (ratio.ratioAvaxUSD *
            getRatio(proxyRewardToken, wavax, precision) *
            amountReward) / 10**(2 * precision);
        // To Compute APR :
        // time.ratioTime =
        //         ((60 * 60 * 24 * 365) * (10**precision)) /
        //         (time.timeSinceLastHarvest);
        // APR = (valueOfPool > 0)
        // ? ((valueOfHarvest *
        //     time.ratioTime *
        //     10**IERC20Metadata(token).decimals()) /
        //     (valueOfPool * 10**IERC20Metadata(rewardToken).decimals()))
        // : 0;
        emit APRInfo(
            token,
            amountReward,
            precision,
            sizeOfPool,
            valueOfHarvest,
            ratio.valueOfPool,
            block.timestamp,
            ratio.fromPool
        );
    }

    /// @notice Emits an event that we use to calculate the APR for a satble pool that receives reward from platypus. Has inline comments to help compute the APR.
    /// @param token address of the token of the pool
    /// @param rewardToken address of the reward token for this pool
    /// @param amountReward Amount, in rewardToken decimals, of the reward
    /// @param sizeOfPool size of the pool where the amount is distributed
    function computeAPRStable(
        address token,
        address rewardToken,
        uint256 amountReward,
        uint256 sizeOfPool
    ) external {
        Ratio memory ratio;
        ratio.fromPool = token;
        ratio.ratioAvaxUSD = getAvaxLatestPrice();
        ratio.valueOfPool = sizeOfPool;
        uint256 valueOfHarvest = (ratio.ratioAvaxUSD *
            getRatio(rewardToken, wavax, precision) *
            amountReward) / 10**(2 * precision);
        // To Compute APR :
        // time.timeSinceLastHarvest = block.timestamp - stableLastHarvest[token];
        // if (time.timeSinceLastHarvest > 0) {
        //     time.ratioTime =
        //         ((60 * 60 * 24 * 365) * (10**precision)) /
        //         time.timeSinceLastHarvest;
        //     stableLastHarvest[token] = block.timestamp;
        //     ratio.APR = (ratio.valueOfPool > 0)
        //         ? ((valueOfHarvest *
        //             time.ratioTime *
        //             10**IERC20Metadata(token).decimals()) /
        //             (ratio.valueOfPool * 10**IERC20Metadata(rewardToken).decimals()))
        //         : 0;
        //     poolStableAPR[token] = ratio.APR;
        // }
        emit APRInfo(
            token,
            amountReward,
            precision,
            sizeOfPool,
            valueOfHarvest,
            ratio.valueOfPool,
            block.timestamp,
            ratio.fromPool
        );
    }

    /// @notice Calculates the APR for a pool listed in Masterchief. The rewards are in VTX.
    /// @param token address of the token of the pool
    /// @param isStable Boolean to help compute the value of the pool
    /// @return APR of Pool, decimals of APR
    function computeAPRForVTX(address token, bool isStable)
        external
        view
        returns (uint256, uint256)
    {
        uint256 ratioAvaxUSD = getAvaxLatestPrice();
        uint256 sizeOfPool;
        uint256 valueOfPool;
        if (isStable) {
            (
                ,
                ,
                ,
                ,
                ,
                address receipt,
                uint256 stablePoolSize,
                ,

            ) = IMainStaking(mainStaking).getPoolInfo(token);
            token = receipt;
            sizeOfPool =
                (stablePoolSize * 10**IERC20Metadata(receipt).decimals()) /
                10**IERC20Metadata(token).decimals();
            valueOfPool =
                (stablePoolSize * 10**IERC20Metadata(receipt).decimals()) /
                10**IERC20Metadata(token).decimals();
        }
        (
            uint256 emission,
            uint256 allocation,
            uint256 sizeOfPoolNotStable,
            uint256 totalPoint
        ) = IMasterChefVTX(masterChief).getPoolInfo(token);
        sizeOfPool = sizeOfPoolNotStable;
        token = (token == xptp) ? ptp : token;
        token = (token == locker) ? vtx : token;
        if (!isStable) {
            if (tokenIsLP[token]) {
                // require(0 > 1, "when LP");
                valueOfPool = ((getValueLP(token) * ratioAvaxUSD * sizeOfPool) /
                    (10**(2 * precision)));
            } else {
                valueOfPool =
                    (getRatio(token, wavax, precision) *
                        ratioAvaxUSD *
                        sizeOfPool) /
                    10**(2 * precision);
            }
        }
        // require(0 > 1, "getratio ?");
        uint256 harvestingPerYear = ((emission *
            365 *
            3600 *
            24 *
            (getRatio(vtx, wavax, precision) * ratioAvaxUSD) *
            allocation) / ((10**(2 * precision)) * totalPoint));
        // require(0 > 1, "return ?");
        return (
            (valueOfPool > 0)
                ? (harvestingPerYear *
                    (10**(precision + IERC20Metadata(token).decimals()))) /
                    (valueOfPool * 10**IERC20Metadata(vtx).decimals())
                : 1,
            precision
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterChefVTX {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external;

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external;

    function createRewarder(address _lpToken, address mainRewardToken)
        external
        returns (address);

    // View function to see pending VTXs on frontend.
    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function pendingTokens(
        address _lp,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 pendingVTX,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(address _lp)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(address _lp) external;

    function deposit(address _lp, uint256 _amount) external;

    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external;

    function lock(
        address _lp,
        uint256 _amount,
        uint256 _index,
        bool force
    ) external;

    function unlock(
        address _lp,
        uint256 _amount,
        uint256 _index
    ) external;

    function multiUnlock(
        address _lp,
        uint256[] calldata _amount,
        uint256[] calldata _index
    ) external;

    function withdraw(address _lp, uint256 _amount) external;

    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external;

    function multiclaim(address[] memory _lps, address user_address) external;

    function emergencyWithdraw(address _lp, address sender) external;

    function updateEmissionRate(uint256 _vtxPerSec) external;

    function depositInfo(address _lp, address _user)
        external
        view
        returns (uint256 depositAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMainStaking {
    function setXPTP(address _xPTP) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isPTP,
        bool isAddress
    ) external;

    function setFee(uint256 index, uint256 value) external;

    function setCallerFee(uint256 value) external;

    function deposit(
        address token,
        uint256 amount,
        address sender
    ) external;

    function harvest(address token, bool isUser) external;

    function withdraw(
        address token,
        uint256 _amount,
        uint256 _slippage,
        address sender
    ) external;

    function stakePTP(uint256 amount) external;

    function stakeAllPtp() external;

    function claimVePTP() external;

    function getStakedPtp() external;

    function getVePtp() external;

    function unstakePTP() external;

    function pendingPtpForPool(address _token)
        external
        view
        returns (uint256 pendingPtp);

    function masterPlatypus() external view returns (address);

    function getLPTokensForShares(uint256 amount, address token)
        external
        view
        returns (uint256);

    function getSharesForDepositTokens(uint256 amount, address token)
        external
        view
        returns (uint256);

    function getDepositTokensForShares(uint256 amount, address token)
        external
        view
        returns (uint256);

    function registerPool(
        uint256 _pid,
        address _token,
        address _lpAddress,
        string memory receiptName,
        string memory receiptSymbol,
        uint256 allocpoints
    ) external;

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address lp,
            uint256 sizeLp,
            address receipt,
            uint256 size,
            address rewards_addr,
            address helper
        );

    function removePool(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}