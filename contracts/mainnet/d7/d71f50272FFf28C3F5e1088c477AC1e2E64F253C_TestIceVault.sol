// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ISicleRouter02.sol";
import "./interface/ISicleFactory.sol";
import "./interface/ISiclePair.sol";
import "./interface/IOracleTWAP.sol";
import "./utils/Proxyable.sol";

contract TestIceVault is Ownable, Proxyable {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt; // Reward debt.
        uint256 lastRewardBlock;
    }

    bool public claimDisabled;
    bool public stakingEnabled;

    address public immutable popsToken; // address of POPS contract
    address public immutable pairAddress; // address of LP
    address public immutable sicleRouter02; // address of reouter to swap token/POP
    bool private immutable isToken0Pops;

    address public stakeToken; // address of stake token token contract
    address public treasury;

    address public oracleTWAP5d;
    address public oracleTWAP5m;

    uint256 public allStaked;
    uint256 public blocksPerDay = 42000;
    uint256 public endBlock; // end of the staking
    uint256 public liquidityMinPercentDesired; // 9500 = 95.00%
    uint256 public minStakePerDeposit; // min stake per deposit
    uint256 public maxStakePerUser; // max stake per user
    uint256 public maxStaked; // max supply of tokens in stake
    uint256 public popsTokenRatioAvgLast5d; // Average of the last 5 days POP/Staking token ratio
    uint256 public rewardPerBlock; //tokens distributed per block * 1e12
    uint256 public rewardPerDay;
    uint256 public allSwapped;
    uint256 public withdrawalFee; // Fees applied when withdraw. 175 = 1.75%

    uint256 private accumulatedFees; // accumulated taxes
    uint256 private diffAcceptablePrice; // difference acceptable on prices. 500 = 5%
    uint256 private totalStaked; // total tokens in stake
    uint256 private withdrawnFees;

    mapping(address => UserInfo) public userInfos; // user stake
    mapping(uint256 => address) public users;
    uint256 public userCount;
    uint256 public currentUserCount;

    event Claim(address indexed user, uint256 indexed pending);
    event Deposit(address indexed user, uint256 indexed amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed popsAmountDesired,
        uint256 indexed sTokenAmount,
        uint256 amountStakeToken,
        uint256 liquidity
    );
    event Withdraw(
        address indexed user,
        uint256 indexed popsAmountDesired,
        uint256 indexed sTokenAmount,
        uint256 amountStakeToken,
        uint256 liquidity
    );
    event WithdrawAccumulatedFees(uint256 indexed pending);
    event WithdrawExcessPOPS(address indexed token, uint256 amount);
    event WithdrawUnassignedRewards(address indexed token, uint256 amount);

    event AddLiquidity(
        uint256 indexed popsAmountDesired,
        uint256 indexed amount,
        uint256 indexed stakeTokenUsedForLiquidity,
        uint256 stakeToken5mAverage,
        uint256 diff
    );
    error AddressIsZero();
    error AfterEndblock();
    error AmountInExceedsMaxSwapAmount();
    error BeforeEndblock();
    error BelowMinimumDeposit();
    error ClaimDisabled();
    error ExceedsMaxStake();
    error ExceedsMaxStakePerUser();
    error InsufficientRewards();
    error InvalidAmount();
    error InvalidMaxRange();
    error InvalidRange();
    error NoPendingFees();
    error PriceVarianceInvalid(uint256 diff);
    error NoStake();
    error OutOfRange(string range);
    error RequiresMinMaxValues();
    error StakingStarted();
    error StakingDisabled();
    error UsersStillStaked(uint256 currentUserCount);

    modifier notZeroAddress(address _address) {
        if (_address == address(0)) revert AddressIsZero();
        _;
    }

    modifier stakingNotStarted() {
        if (totalStaked > 0) revert StakingStarted();
        _;
    }

    constructor(
        address _stakeToken,
        address _popsToken,
        address _sicleRouter02,
        address _pairAddress,
        uint256 _rewardPerDay,
        uint256 _maxStaked,
        uint256 _minStakePerDeposit,
        uint256 _maxStakedPerUser,
        uint256 _stakeLengthInDays
    )
        notZeroAddress(_stakeToken)
        notZeroAddress(_popsToken)
        notZeroAddress(_sicleRouter02)
        notZeroAddress(_pairAddress)
    {
        stakeToken = _stakeToken;
        popsToken = _popsToken;
        sicleRouter02 = _sicleRouter02;
        maxStaked = _maxStaked;
        minStakePerDeposit = _minStakePerDeposit;
        maxStakePerUser = _maxStakedPerUser;
        rewardPerBlock = _rewardPerDay / blocksPerDay;
        rewardPerDay = _rewardPerDay;
        endBlock = block.number + blocksPerDay * _stakeLengthInDays;
        setProxyState(_msgSender(), true);

        // Comment to pass the test in hardhat and Uncomment when deploy
        pairAddress = _pairAddress;
        isToken0Pops = ISiclePair(pairAddress).token0() == popsToken;
    }

    function getAccumulatedFees() external view returns (uint256) {
        return accumulatedFees;
    }

    function getPending(address _user) external view returns (uint256) {
        return _getPending(_user);
    }

    function getPendingAccumulatedFees() external view returns (uint256) {
        return accumulatedFees - withdrawnFees;
    }

    function getTotalPOPsForLP() external view returns (uint256) {
        return _getPopsForLP(totalStaked / 2);
    }

    function getPopsBalance() external view returns (uint256) {
        return _getPopsBalance();
    }

    function getRewardPerDay() external view returns (uint256) {
        return rewardPerDay;
    }

    function getPopsForLP(uint256 amount) external view returns (uint256) {
        return _getPopsForLP(amount);
    }

    function getPopsForLPWithFees(uint256 amount)
        external
        view
        returns (uint256)
    {
        return
            _getPopsForLP(
                isCurrentPopSTokenAboveAvg5d()
                    ? (amount * withdrawalFee) / 1e4
                    : amount
            );
    }

    function getTokenRatio() external view returns (uint256, uint256) {
        return _getTokenRatio();
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function isUserStaked(address _user) external view returns (bool) {
        return (userInfos[_user].amount > 0);
    }

    function claim() external {
        _claim();
    }

    function deposit(uint256 amount) external {
        if (!stakingEnabled) revert StakingDisabled();
        if (block.number > endBlock) revert AfterEndblock();
        if (amount <= minStakePerDeposit) revert BelowMinimumDeposit();

        IERC20(stakeToken).transferFrom(_msgSender(), address(this), amount);

        UserInfo storage userInfo = userInfos[_msgSender()];
        uint256 userAmount = userInfo.amount;
        uint256 total = userAmount + amount;
        if (total > maxStaked) revert ExceedsMaxStake();
        if (total > maxStakePerUser) revert ExceedsMaxStakePerUser();
        if (userAmount > 0) _claim();

        // add user to array, when it's the first time,_users to track the unassigned rewards
        if (userInfo.lastRewardBlock == 0) {
            users[userCount] = _msgSender();
            ++userCount;
            ++currentUserCount;
        }
        userInfo.amount += amount;
        totalStaked += amount;
        allStaked += amount;
        userInfo.lastRewardBlock = block.number;

        emit Deposit(_msgSender(), amount);
    }

    // force withdraw by owner; user receives LP, but no reward
    function emergencyWithdrawByOwner(address user, uint256 popsAmountDesired)
        external
        onlyOwner
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        _updateOracles();
        UserInfo storage userInfo = userInfos[user];
        uint256 userAmount = userInfo.amount;
        if (userAmount == 0) revert NoStake();
        userInfo.amount = 0;
        totalStaked -= userAmount;
        --currentUserCount;

        (
            uint256 amountPopsToken,
            uint256 amountStakeToken,
            uint256 liquidity
        ) = _addLiquidity(popsAmountDesired, userAmount);

        emit EmergencyWithdraw(
            user,
            popsAmountDesired,
            amountPopsToken,
            amountStakeToken,
            liquidity
        );

        return (amountPopsToken, amountStakeToken, liquidity);
    }

    function sendRewards(uint256 amount) external onlyOwner {
        if (amount == 0) revert InvalidAmount();
        IERC20(stakeToken).transferFrom(_msgSender(), address(this), amount);
    }

    function setBlocksPerDay(uint256 _blocksPerDay)
        external
        onlyOwner
        stakingNotStarted
    {
        if (_blocksPerDay < 1000 || _blocksPerDay > 45000)
            revert OutOfRange("1000-45000");
        blocksPerDay = _blocksPerDay;
        rewardPerBlock = rewardPerDay / blocksPerDay;
    }

    function setEndBlock(uint value) external onlyOwner stakingNotStarted {
        endBlock = value;
    }

    function setLiquidityMinPercentDesired(uint256 value) external onlyOwner {
        liquidityMinPercentDesired = value;
    }

    function setMaxStaked(uint256 amount) external onlyOwner {
        maxStaked = amount;
    }

    function setMinStakePerDeposit(uint256 amount) external onlyOwner {
        minStakePerDeposit = amount;
    }

    function setMaxStakePerUser(uint256 amount) external onlyOwner {
        maxStakePerUser = amount;
    }

    function setDiffAcceptablePrice(uint256 value) external onlyProxy {
        diffAcceptablePrice = value;
    }

    function setOracleTWAP5d(address value)
        external
        notZeroAddress(value)
        onlyOwner
    {
        oracleTWAP5d = value;
    }

    function setOracleTWAP5m(address value)
        external
        notZeroAddress(value)
        onlyOwner
    {
        oracleTWAP5m = value;
    }

    function setRewardPerDay(uint256 value)
        external
        onlyOwner
        stakingNotStarted
    {
        rewardPerDay = value;
        rewardPerBlock = rewardPerDay / blocksPerDay;
    }

    function setStakingEnabled(bool enabled) external onlyOwner {
        stakingEnabled = enabled;
    }

    function setStakingToken(address value)
        external
        onlyOwner
        notZeroAddress(value)
        stakingNotStarted
    {
        stakeToken = value;
    }

    function setTreasury(address addr) external onlyOwner {
        treasury = addr;
    }

    function setWithdrawalFee(uint256 amount) external onlyOwner {
        withdrawalFee = amount;
    }

    function swap(uint256 amountIn, uint256 amountOutMin) external onlyOwner {
        if (amountIn > allStaked / 2 - allSwapped)
            revert AmountInExceedsMaxSwapAmount();
        allSwapped += amountIn;
        address[] memory path = new address[](2);
        path[0] = stakeToken;
        path[1] = popsToken;

        IERC20(stakeToken).approve(sicleRouter02, amountIn);
        IERC20(popsToken).approve(sicleRouter02, amountOutMin);
        ISicleRouter02(sicleRouter02).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 5 minutes // deadline
        );
    }

    function updateOracles() external {
        _updateOracles();
    }

    function withdraw(uint256 _amount, uint256 popsAmountDesired)
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        _updateOracles();
        UserInfo storage userInfo = userInfos[_msgSender()];
        uint256 userAmount = userInfo.amount;
        if (userAmount == 0) revert NoStake();
        if (_amount > userAmount) revert InvalidAmount();

        _claim();
        userInfo.amount -= _amount;
        totalStaked -= _amount;
        if (userInfo.amount == 0) --currentUserCount;

        (
            uint256 amountPopsToken,
            uint256 amountStakeToken,
            uint256 liquidity
        ) = _addLiquidity(popsAmountDesired, _amount);

        emit Withdraw(
            _msgSender(),
            popsAmountDesired,
            amountPopsToken,
            amountStakeToken,
            liquidity
        );

        return (amountPopsToken, amountStakeToken, liquidity);
    }

    function withdrawAccumulatedFees() external onlyOwner {
        uint256 pending = accumulatedFees - withdrawnFees;
        if (pending == 0) revert NoPendingFees();
        withdrawnFees -= pending;
        IERC20(stakeToken).transfer(treasury, pending);
        emit WithdrawAccumulatedFees(pending);
    }

    function withdrawExcessPopsToTreasury()
        external
        onlyOwner
        returns (uint256)
    {
        uint256 popsBalance = _getPopsBalance();
        IOracleTWAP(oracleTWAP5m).update();
        uint256 popsRequiredForLP = IOracleTWAP(oracleTWAP5m).consult(
            stakeToken,
            totalStaked / 2
        ); // given by oracle, returns pops amount

        if (popsBalance <= popsRequiredForLP) return 0; // There is no excess of POPS

        uint256 excessPOPS = popsBalance - popsRequiredForLP;
        IERC20(popsToken).transfer(treasury, excessPOPS);
        emit WithdrawExcessPOPS(popsToken, excessPOPS);
        return excessPOPS;
    }

    // get unassigned rewards only when the staking has finished
    // claim will be disabled
    // all stakers must unstake. Owner can call emergencyWithdraw for staked users
    function withdrawUnassignedRewardToTreasury()
        external
        onlyOwner
        returns (uint256)
    {
        if (block.number <= endBlock) revert BeforeEndblock();
        if (currentUserCount > 0) revert UsersStillStaked(currentUserCount);
        if (!claimDisabled) claimDisabled = true;

        uint256 bal = IERC20(stakeToken).balanceOf(address(this));
        if (bal == 0) return 0;
        IERC20(stakeToken).transfer(treasury, bal);

        emit WithdrawUnassignedRewards(stakeToken, bal);
        return bal;
    }

    function isCurrentPopSTokenAboveAvg5d() public view returns (bool) {
        (uint256 popsReserve, uint256 stakeReserve) = _getTokenRatio();
        return (popsReserve * 1e4) / stakeReserve > popsTokenRatioAvgLast5d;
    }

    function _addLiquidity(uint256 popsAmountDesired, uint256 amount)
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 sTokenAmount = _getAmountAfterFees(amount) / 2;
        uint256 minAmountA = (popsAmountDesired * liquidityMinPercentDesired) /
            1e4;
        uint256 minAmountB = (sTokenAmount * liquidityMinPercentDesired) / 1e4;

        IERC20(stakeToken).approve(sicleRouter02, sTokenAmount);
        IERC20(popsToken).approve(sicleRouter02, popsAmountDesired);

        (
            uint256 popsTokenUsedForLiquidity,
            uint256 stakeTokenUsedForLiquidity,
            uint256 liquidity
        ) = ISicleRouter02(sicleRouter02).addLiquidity(
                popsToken,
                stakeToken,
                popsAmountDesired,
                sTokenAmount,
                minAmountA, // minAmountA
                minAmountB, // minAmountB
                _msgSender(), // send to user
                block.timestamp + 5 minutes // deadline
            );

        // Price of POPS token is expressed in terms of {Stake Token}/POPS (ratio)
        uint256 stakeToken5mAverage = IOracleTWAP(oracleTWAP5m).consult(
            popsToken,
            popsAmountDesired
        ); // given by oracle, returns stakeToken amount
        // allow for +/- difference
        uint256 diff = ((
            stakeToken5mAverage > stakeTokenUsedForLiquidity
                ? stakeToken5mAverage - stakeTokenUsedForLiquidity
                : stakeTokenUsedForLiquidity - stakeToken5mAverage
        ) * 1e4) / stakeToken5mAverage;

        // revert if not desired price.
        // if diffAcceptablePrice is 5% -> 500 then diff must be less than or equal to than 5% (500)
        if (diff > diffAcceptablePrice) revert PriceVarianceInvalid(diff);

        emit AddLiquidity(
            popsAmountDesired,
            sTokenAmount,
            stakeTokenUsedForLiquidity,
            stakeToken5mAverage,
            diff
        );

        return (
            popsTokenUsedForLiquidity,
            stakeTokenUsedForLiquidity,
            liquidity
        );
    }

    function _getAmountAfterFees(uint256 amount)
        private
        returns (uint256 sTokenAmount)
    {
        // Price of POPS token is expressed in terms of {Stake Token}/POPS (ratio)
        uint256 priceTWAP5d = IOracleTWAP(oracleTWAP5d).consult(
            popsToken,
            amount
        );
        uint256 priceTWAP5m = IOracleTWAP(oracleTWAP5m).consult(
            popsToken,
            amount
        );

        uint256 fees = priceTWAP5m > priceTWAP5d // If the price rises are because the difference between POPS's and Stake Token's reserve decrease
            ? (amount * withdrawalFee) / 1e4
            : 0;
        accumulatedFees += fees;
        sTokenAmount = amount - fees;
    }

    function _getMultiplier(uint from, uint to) private view returns (uint) {
        if (from < endBlock && to < endBlock) {
            return to - from;
        } else if (from < endBlock && to > endBlock) {
            return endBlock - from;
        }
        return 0;
    }

    function _getPending(address _user) private view returns (uint256) {
        UserInfo memory userInfo = userInfos[_user];
        uint256 userAmount = userInfo.amount;
        if (userAmount > 0 && block.number > userInfo.lastRewardBlock) {
            uint256 multiplier = _getMultiplier(
                userInfo.lastRewardBlock,
                block.number
            );
            if (multiplier == 0) return 0;
            return (userAmount * rewardPerBlock * multiplier) / 1e12;
        }
        return 0;
    }

    function _getPopsBalance() private view returns (uint256) {
        return IERC20(popsToken).balanceOf(address(this));
    }

    // Get POPS tokens according to a ratio POPS/Staking Token
    function _getPopsForLP(uint256 amount) private view returns (uint256) {
        (uint256 popsReserve, uint256 stakingReserve) = _getTokenRatio();
        return (amount * popsReserve) / stakingReserve;
    }

    function _getTokenRatio() private view returns (uint256, uint256) {
        (uint112 _reserve0, uint112 _reserve1, ) = ISiclePair(pairAddress)
            .getReserves();
        if (isToken0Pops) {
            return (_reserve0, _reserve1);
        }
        return (_reserve1, _reserve0);
    }

    function _claim() private {
        UserInfo storage userInfo = userInfos[_msgSender()];
        if (claimDisabled) revert ClaimDisabled();
        if (userInfo.amount == 0) revert NoStake();

        uint256 pending = _getPending(_msgSender());
        if (pending > 0) {
            if (pending < IERC20(stakeToken).balanceOf(address(this)))
                revert InsufficientRewards();
            userInfo.rewardDebt += pending;
            userInfo.lastRewardBlock = block.number;
            IERC20(stakeToken).transfer(_msgSender(), pending);
        }
        emit Claim(_msgSender(), pending);
    }

    function _setPopsTokenRatioAvgLast5d() private {
        popsTokenRatioAvgLast5d = IOracleTWAP(oracleTWAP5d).consult(
            stakeToken,
            1e4
        );
    }

    function _updateOracles() private {
        IOracleTWAP(oracleTWAP5d).update();
        _setPopsTokenRatioAvgLast5d();
        IOracleTWAP(oracleTWAP5m).update();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ISicleFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToStake() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToStake(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IOracleTWAP{
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function update() external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ISiclePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Proxyable is Ownable {

    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()], "Only proxy");
        _;
    }

    function setProxyState(address proxyAddress, bool value) public onlyOwner {
        proxyToApproved[proxyAddress] = value;
    } 
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './ISicleRouter01.sol';

//IUniswapV2Router02
interface ISicleRouter02 is ISicleRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

//IUniswapV2Router01
interface ISicleRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}