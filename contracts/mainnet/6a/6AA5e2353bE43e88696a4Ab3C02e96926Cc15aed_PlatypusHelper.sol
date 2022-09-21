// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "IJoePair.sol";
import "IVoter.sol";
import "IMasterChefVTX.sol";
import "IMainStaking.sol";
import "IBoostedMultiRewarder.sol";
import "IMasterPlatypusv4.sol";
import "IJoeFactory.sol";
import "IMasterChefVTX.sol";
import "IBaseRewardPool.sol";
import "AggregatorV3Interface.sol";
import "IAPRHelper.sol";
import "IBalanceHelper.sol";
import "IERC20.sol";

contract PlatypusHelper is Ownable {
    AggregatorV3Interface internal priceFeed;
    uint256 internal constant ACC_TOKEN_PRECISION = 1e15;
    uint256 public constant AvaxUSDDecimals = 8;
    uint256 public constant precision = 8;
    address public constant ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8;
    address public constant xPTP = 0x060556209E507d30f2167a101bFC6D256Ed2f3e1;
    address public wavax;
    address public aprHelper;

    uint256 public constant FEE_DENOMINATOR = 10000;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 factor;
        uint256 accTokenPerShare;
        uint256 accTokenPerFactorShare;
    }

    struct UserPoolInfo {
        uint256 balance;
        uint256 balanceUSD;
        uint256[] rewards;
        uint256[] rewardsUSD;
        address[] tokenRewards;
        uint256[] harvestable;
        address[] tokenHarvestable;
        uint256[] harvestableUSD;
    }

    struct HelpStack {
        uint256 pid;
        address masterPlatypus;
        address asset;
        address mainStaking;
        address balanceHelper;
        address masterChief;
        address rewarder;
        uint256 sumOfFactors;
        uint256 accPtpPerShare;
        uint256 accPtpPerFactorShare;
        uint256 pendingPtpForLp;
        uint256 dilutingRepartition;
    }

    constructor(address _wavax, address _aprHelper) {
        priceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
        wavax = _wavax;
        aprHelper = _aprHelper;
    }

    /**
     * Returns the latest price
     */
    function getAvaxLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getPTPperYear(address lp) public view returns (uint256 ptpPerYearPerToken) {
        uint256 _secondsElapsed = 3600 * 24 * 364;
        address voter = IAPRHelper(aprHelper).voter();
        uint256 _delta = (_secondsElapsed * IVoter(voter).ptpPerSec() * ACC_TOKEN_PRECISION) /
            IVoter(voter).totalWeight();
        ptpPerYearPerToken = (IVoter(voter).weights(lp) * _delta) / ACC_TOKEN_PRECISION;
    }

    function getTVL(address lp) public view returns (uint256 TVLinUSD) {
        address masterPlatypus = IAPRHelper(aprHelper).masterPlatypus();
        address mainStaking = IAPRHelper(aprHelper).mainStaking();
        uint256 _pid = IMasterPlatypusv4(masterPlatypus).getPoolId(lp);
        address token = IAPRHelper(aprHelper).pool2token(lp);
        (uint128 amount128, uint128 factor128, , ) = IMasterPlatypusv4(masterPlatypus).userInfo(
            _pid,
            mainStaking
        );
        uint256 amount = uint256(amount128);
        uint256 factor = uint256(factor128);
        TVLinUSD = (amount * getTokenPricePairedWithAvax(token)) / (10**ERC20(lp).decimals());
    }

    function getLPPrice(address lp) public view returns (uint256 inUSD) {
        (inUSD, ) = getLPPriceAndDecimals(lp);
    }

    function getLPPriceAndDecimals(address lp)
        public
        view
        returns (uint256 inUSD, uint256 tokenDecimals)
    {
        address token = IAPRHelper(aprHelper).pool2token(lp);
        inUSD = getTokenPricePairedWithAvax(token);
        tokenDecimals = ERC20(token).decimals();
    }

    function getLPsPrice(address[] calldata lps) public view returns (uint256[] memory inUSD) {
        uint256 length = lps.length;
        inUSD = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            address token = IAPRHelper(aprHelper).pool2token(lps[i]);
            inUSD[i] = getTokenPricePairedWithAvax(token);
        }
    }

    function getPTPperYearForVector(address lp)
        public
        view
        returns (uint256 pendingBasePtp, uint256 pendingBoostedPtp)
    {
        HelpStack memory helpStack;
        helpStack.masterPlatypus = IAPRHelper(aprHelper).masterPlatypus();
        helpStack.mainStaking = IAPRHelper(aprHelper).mainStaking();
        helpStack.pid = IMasterPlatypusv4(helpStack.masterPlatypus).getPoolId(lp);
        // address masterPlatypus = IAPRHelper(aprHelper).masterPlatypus();
        // address mainStaking = IAPRHelper(aprHelper).mainStaking();
        // uint256 _pid = IMasterPlatypusv4(masterPlatypus).getPoolId(lp);
        (
            address lpToken, // Address of LP token contract.
            ,
            uint256 sumOfFactors128, // 20.18 fixed point. The sum of all non dialuting factors by all of the users in the pool
            uint128 accPtpPerShare128, // 26.12 fixed point. Accumulated PTPs per share, times 1e12.
            uint128 accPtpPerFactorShare128
        ) = IMasterPlatypusv4(helpStack.masterPlatypus).poolInfo(helpStack.pid);
        helpStack.sumOfFactors = uint256(sumOfFactors128);
        helpStack.accPtpPerShare = uint256(accPtpPerShare128);
        helpStack.accPtpPerFactorShare = uint256(accPtpPerFactorShare128);
        helpStack.pendingPtpForLp = getPTPperYear(lp);
        helpStack.dilutingRepartition = IMasterPlatypusv4(helpStack.masterPlatypus)
            .dilutingRepartition();

        // calculate accPtpPerShare and accPtpPerFactorShare

        uint256 lpSupply = IERC20(lpToken).balanceOf(helpStack.masterPlatypus);
        if (lpSupply != 0) {
            helpStack.accPtpPerShare =
                (helpStack.pendingPtpForLp * 1e12 * helpStack.dilutingRepartition) /
                (lpSupply * 1000);
        }
        if (helpStack.sumOfFactors > 0) {
            helpStack.accPtpPerFactorShare =
                (helpStack.pendingPtpForLp * 1e12 * (1000 - helpStack.dilutingRepartition)) /
                (helpStack.sumOfFactors * 1000);
        }

        // get pendingPtp
        UserInfo memory userInfo;
        (uint128 amount128, uint128 factor128, , ) = IMasterPlatypusv4(helpStack.masterPlatypus)
            .userInfo(helpStack.pid, helpStack.mainStaking);
        userInfo.amount = uint256(amount128);
        userInfo.factor = uint256(factor128);
        pendingBasePtp = ((userInfo.amount * helpStack.accPtpPerShare) / 1e12);
        pendingBoostedPtp = ((userInfo.factor * helpStack.accPtpPerFactorShare) / 1e12);
    }

    function getAPRforPTPPoolInPTP(address lp)
        public
        view
        returns (uint256 baseAPR, uint256 boostedAPR)
    {
        (uint256 pendingBasePtp, uint256 pendingBoostedPtp) = getPTPperYearForVector(lp);
        baseAPR = (pendingBasePtp * getTokenPricePairedWithAvax(ptp)) / getTVL(lp) / 10**8;
        boostedAPR = (pendingBoostedPtp * getTokenPricePairedWithAvax(ptp)) / getTVL(lp) / 10**8;
    }

    function getMultipleAPRforPTPPoolsInPTP(address[] calldata lp)
        public
        view
        returns (uint256[] memory baseAPR, uint256[] memory boostedAPR)
    {
        uint256 length = lp.length;
        baseAPR = new uint256[](length);
        boostedAPR = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            (uint256 pendingBasePtp, uint256 pendingBoostedPtp) = getPTPperYearForVector(lp[i]);
            baseAPR[i] =
                (pendingBasePtp * getTokenPricePairedWithAvax(ptp)) /
                getTVL(lp[i]) /
                10**8;
            boostedAPR[i] =
                (pendingBoostedPtp * getTokenPricePairedWithAvax(ptp)) /
                getTVL(lp[i]) /
                10**8;
        }
    }

    function getMultipleAPRforLockerlsInAdditionalReward(
        uint256 feeAmount,
        address[] calldata lps,
        address[] calldata inputRewardTokens
    ) public view returns (uint256[] memory APRs, address[] memory rewardTokens) {
        uint256 length = lps.length;
        APRs = new uint256[](inputRewardTokens.length);
        rewardTokens = new address[](inputRewardTokens.length);
        for (uint256 i; i < length; ++i) {
            (
                uint256[] memory APR,
                address[] memory rewardToken
            ) = getAPRforLockerInAdditionalReward(lps[i], feeAmount);
            for (uint256 j; j < inputRewardTokens.length; ++j) {
                for (uint256 k; k < rewardToken.length; ++k)
                    if (rewardToken[k] == inputRewardTokens[j]) {
                        APRs[j] += APR[k];
                        rewardTokens[j] = rewardToken[k];
                    }
            }
        }
    }

    function getAdditionalRewardsInUSDPerYear(address lp)
        public
        view
        returns (uint256[] memory USDPerYear, address[] memory rewardTokens)
    {
        HelpStack memory helpStack;
        helpStack.masterPlatypus = IAPRHelper(aprHelper).masterPlatypus();
        helpStack.mainStaking = IAPRHelper(aprHelper).mainStaking();
        helpStack.pid = IMasterPlatypusv4(helpStack.masterPlatypus).getPoolId(lp);
        uint256 sumOfFactors = IMasterPlatypusv4(helpStack.masterPlatypus).getSumOfFactors(
            helpStack.pid
        );
        (uint128 amount128, uint128 factor128, , ) = IMasterPlatypusv4(helpStack.masterPlatypus)
            .userInfo(helpStack.pid, helpStack.mainStaking);
        UserInfo memory userInfo;
        userInfo.amount = uint256(amount128);
        userInfo.factor = uint256(factor128);
        (, address rewarder, , , ) = IMasterPlatypusv4(helpStack.masterPlatypus).poolInfo(
            helpStack.pid
        );
        if (rewarder != address(0)) {
            uint256 dilutingRepartition = IBoostedMultiRewarder(rewarder).dilutingRepartition();
            uint256 length = IBoostedMultiRewarder(rewarder).poolLength();
            USDPerYear = new uint256[](length);
            rewardTokens = new address[](length);
            for (uint256 i; i < length; ++i) {
                (address rewardToken, uint96 tokenPerSec, , ) = IBoostedMultiRewarder(rewarder)
                    .poolInfo(i);
                rewardTokens[i] = (rewardToken == address(0)) ? wavax : rewardToken;
                userInfo.accTokenPerShare =
                    (3600 *
                        24 *
                        365 *
                        uint256(tokenPerSec) *
                        dilutingRepartition *
                        ACC_TOKEN_PRECISION) /
                    IERC20(lp).balanceOf(helpStack.masterPlatypus) /
                    1000;
                if (sumOfFactors > 0) {
                    userInfo.accTokenPerFactorShare =
                        (3600 *
                            24 *
                            365 *
                            uint256(tokenPerSec) *
                            ACC_TOKEN_PRECISION *
                            (1000 - dilutingRepartition)) /
                        sumOfFactors /
                        1000;
                }
                USDPerYear[i] += (((userInfo.amount *
                    userInfo.accTokenPerShare +
                    userInfo.accTokenPerFactorShare *
                    userInfo.factor) / ACC_TOKEN_PRECISION) *
                    getTokenPricePairedWithAvax(rewardTokens[i]));
            }
        }
    }

    function getAPRforPTPPoolInAdditionalReward(address lp) public view returns (uint256 APR) {
        (
            uint256[] memory APRs,
            address[] memory tempRewardToken
        ) = getAPRforPTPPoolInAdditionalRewardArray(lp);
        uint256 length = APRs.length;
        for (uint256 i; i < length; ++i) {
            APR += APRs[i];
        }
    }

    function getAPRforPTPPoolInAdditionalRewardArray(address lp)
        public
        view
        returns (uint256[] memory APR, address[] memory rewardToken)
    {
        (
            uint256[] memory USDPerYear,
            address[] memory tempRewardToken
        ) = getAdditionalRewardsInUSDPerYear(lp);
        uint256 length = USDPerYear.length;
        rewardToken = tempRewardToken;
        APR = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            APR[i] = USDPerYear[i] / getTVL(lp) / 10**8;
        }
    }

    function getAPRforLockerInAdditionalReward(address lp, uint256 feeAmount)
        public
        view
        returns (uint256[] memory APR, address[] memory rewardToken)
    {
        (
            uint256[] memory USDPerYear,
            address[] memory tempRewardToken
        ) = getAdditionalRewardsInUSDPerYear(lp);
        uint256 length = USDPerYear.length;
        rewardToken = tempRewardToken;
        APR = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            APR[i] = (USDPerYear[i] * feeAmount) / FEE_DENOMINATOR / getTVLForLocker() / 10**8;
        }
    }

    function getAPRforxPTPInAdditionalReward(address lp, uint256 feeAmount)
        public
        view
        returns (uint256[] memory APR, address[] memory rewardToken)
    {
        (
            uint256[] memory USDPerYear,
            address[] memory tempRewardToken
        ) = getAdditionalRewardsInUSDPerYear(lp);
        uint256 length = USDPerYear.length;
        rewardToken = tempRewardToken;
        APR = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            APR[i] = (USDPerYear[i] * feeAmount) / FEE_DENOMINATOR / getXPTPTVL() / 10**8;
        }
    }

    function getTokenPricePairedWithAvax(address token) public view returns (uint256 tokenPrice) {
        address balanceHelper = IAPRHelper(aprHelper).balanceHelper();
        tokenPrice = IBalanceHelper(balanceHelper).getTokenPricePairedWithAvax(token);
    }

    // function getPlatypusFees(uint256 index) public view returns (uint256 feeAmount) {
    //     for (uint256 i; i < index; ++i) {
    //         (, , uint256 value, , , , bool isActive) = IMainStaking(mainStaking).feeInfos(i);
    //         if (isActive) {
    //             feeAmount += value;
    //         }
    //     }
    // }

    function getPTPClaimableRewards(
        address lp,
        address[] calldata inputRewardTokens,
        address user
    )
        public
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        )
    {
        address asset = IAPRHelper(aprHelper).lp2asset(lp);
        address mainStaking = IAPRHelper(aprHelper).mainStaking();
        (, , , , , , , address rewarder, ) = IMainStaking(mainStaking).getPoolInfo(asset);
        uint256 length = inputRewardTokens.length;
        uint256 actualLength;
        for (uint256 i; i < length; ++i) {
            if (IBaseRewardPool(rewarder).isRewardToken(inputRewardTokens[i])) {
                actualLength += 1;
            }
        }
        uint256 index;
        rewardTokens = new address[](actualLength);
        amounts = new uint256[](actualLength);
        usdAmounts = new uint256[](actualLength);
        for (uint256 i; i < length; ++i) {
            if (IBaseRewardPool(rewarder).isRewardToken(inputRewardTokens[i])) {
                rewardTokens[index] = inputRewardTokens[i];
                uint256 amount = IBaseRewardPool(rewarder).earned(user, rewardTokens[index]);
                amounts[index] = amount;
                usdAmounts[index] =
                    (getTokenPricePairedWithAvax(rewardTokens[index]) * amounts[i]) /
                    10**ERC20(rewardTokens[index]).decimals();
                index += 1;
            }
        }
    }

    function getPTPHarvestableRewards(address lp, address user)
        public
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        )
    {
        HelpStack memory helpStack;
        helpStack.asset = IAPRHelper(aprHelper).lp2asset(lp);
        helpStack.masterPlatypus = IAPRHelper(aprHelper).masterPlatypus();
        helpStack.mainStaking = IAPRHelper(aprHelper).mainStaking();
        (, , , , , , , helpStack.rewarder, ) = IMainStaking(helpStack.mainStaking).getPoolInfo(
            helpStack.asset
        );
        rewardTokens = new address[](2);
        amounts = new uint256[](2);
        usdAmounts = new uint256[](2);
        helpStack.pid = IMasterPlatypusv4(helpStack.masterPlatypus).getPoolId(lp);
        (
            uint256 pendingPtp,
            address[] memory bonusTokenAddresses,
            ,
            uint256[] memory pendingBonusTokens
        ) = IMasterPlatypusv4(helpStack.masterPlatypus).pendingTokens(
                helpStack.pid,
                helpStack.mainStaking
            );
        uint256 ratio = (IBaseRewardPool(helpStack.rewarder).balanceOf(user) * 10**precision) /
            IBaseRewardPool(helpStack.rewarder).totalSupply();
        rewardTokens[0] = ptp;
        amounts[0] = (pendingPtp * ratio) / (10**precision);
        usdAmounts[0] =
            (amounts[0] * getTokenPricePairedWithAvax(rewardTokens[0])) /
            10**ERC20(rewardTokens[0]).decimals();
        for (uint256 i; i < bonusTokenAddresses.length; ++i) {
            rewardTokens[i + 1] = bonusTokenAddresses[i];
            amounts[i + 1] = (pendingBonusTokens[i] * ratio) / (10**precision);
            usdAmounts[i + 1] =
                (amounts[i + 1] * getTokenPricePairedWithAvax(rewardTokens[i + 1])) /
                10**ERC20(rewardTokens[i + 1]).decimals();
        }
    }

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) public view returns (uint256 ratio) {
        address balanceHelper = IAPRHelper(aprHelper).balanceHelper();
        ratio = IBalanceHelper(balanceHelper).getRatio(numerator, denominator, decimals);
    }

    function getTVLForLocker() public view returns (uint256 lockerTVL) {
        address balanceHelper = IAPRHelper(aprHelper).balanceHelper();
        lockerTVL = IBalanceHelper(balanceHelper).getTVLForLocker();
    }

    function getXPTPAPRForLocker(uint256 feeAmount) public view returns (uint256 APR) {
        uint256 length = IAPRHelper(aprHelper).getLengthPtpPools();
        uint256 amountPTP;
        for (uint256 i; i < length; ++i) {
            (uint256 base, uint256 boosted) = getPTPperYearForVector(
                IAPRHelper(aprHelper).ptpPools(i)
            );
            amountPTP += ((base + boosted) * feeAmount) / FEE_DENOMINATOR;
        }
        uint256 lockerTVL = getTVLForLocker();
        uint256 xPTPUSDValue = (amountPTP *
            getTokenPricePairedWithAvax(ptp) *
            getRatio(xPTP, ptp, 8)) / 10**(ERC20(ptp).decimals());
        APR = (xPTPUSDValue * 100) / lockerTVL;
    }

    function getXPTPTVL() public view returns (uint256 usdValue) {
        address masterChief = IAPRHelper(aprHelper).masterChief();
        (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        ) = IMasterChefVTX(masterChief).getPoolInfo(xPTP);
        usdValue =
            (sizeOfPool * getTokenPricePairedWithAvax(ptp) * getRatio(xPTP, ptp, 8)) /
            10**(8 + ERC20(xPTP).decimals());
    }

    function getUserInfo(address user, address[] calldata inputRewardTokens)
        public
        view
        returns (UserPoolInfo[] memory usersInfo)
    {
        uint256 length = IAPRHelper(aprHelper).getLengthPtpPools();
        HelpStack memory helpStack;
        helpStack.mainStaking = IAPRHelper(aprHelper).mainStaking();
        usersInfo = new UserPoolInfo[](length);
        for (uint256 i; i < length; ++i) {
            UserPoolInfo memory userInfo;
            address pool = IAPRHelper(aprHelper).ptpPools(i);
            helpStack.asset = IAPRHelper(aprHelper).lp2asset(pool);
            (, , , , , , , address rewarder, ) = IMainStaking(helpStack.mainStaking).getPoolInfo(
                helpStack.asset
            );
            userInfo.balance = IBaseRewardPool(rewarder).balanceOf(user);
            (uint256 price, uint256 decimals) = getLPPriceAndDecimals(pool);
            userInfo.balanceUSD = (userInfo.balance * price) / 10**(decimals);
            (userInfo.tokenRewards, userInfo.rewards, userInfo.rewardsUSD) = getPTPClaimableRewards(
                pool,
                inputRewardTokens,
                user
            );
            (
                userInfo.tokenHarvestable,
                userInfo.harvestable,
                userInfo.harvestableUSD
            ) = getPTPHarvestableRewards(pool, user);
            usersInfo[i] = userInfo;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
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

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

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

interface IVoter {
    struct LpTokenInfo {
        uint128 claimable; // 20.18 fixed point. claimable PTP
        uint128 supplyIndex; // 20.18 fixed point. distributed reward per weight
        address gauge;
        bool whitelist;
    }

    // lpToken => weight, equals to sum of votes for a LP token
    function weights(address _lpToken) external view returns (uint256);

    function ptpPerSec() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function bribes(address _lpToken) external view returns (address);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[] memory bribeRewards);

    // user address => lpToken => votes
    function votes(address _user, address _lpToken) external view returns (uint256);

    function claimBribes(address[] calldata _lpTokens)
        external
        returns (uint256[] memory bribeRewards);

    function lpTokenLength() external view returns (uint256);

    function getUserVotes(address _user, address _lpToken) external view returns (uint256);

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[] memory bribeRewards);
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

    function vtxLocker() external view returns (address);

    function createRewarder(address _lpToken, address mainRewardToken) external returns (address);

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

    function depositInfo(address _lp, address _user) external view returns (uint256 depositAmount);

    function setPoolHelper(address _lp, address _helper) external;

    function authorizeLocker(address _locker) external;

    function lockFor(
        address _lp,
        uint256 _amount,
        uint256 _index,
        address _for,
        bool force
    ) external;

    function vtx() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMainStaking {
    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    ) external returns (address[] memory rewardTokens, uint256[] memory feeAmounts);

    function setXPTP(address _xPTP) external;

    function feeInfos(uint256 index)
        external
        view
        returns (
            uint256 max_value,
            uint256 min_value,
            uint256 value,
            address to,
            bool isPTP,
            bool isAddress,
            bool isActive
        );

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

    function withdrawLP(
        address token,
        uint256 amount,
        address sender
    ) external;

    function withdraw(
        address token,
        uint256 _amount,
        uint256 _slippage,
        address sender
    ) external;

    function withdrawForOverCoveredToken(
        address token,
        address overCoveredToken,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function withdrawWithDifferentAssetForOverCoveredToken(
        address token,
        address overCoveredToken,
        address asset,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function stakePTP(uint256 amount) external;

    function stakeAllPtp() external;

    function claimVePTP() external;

    function getStakedPtp() external view returns (uint256);

    function getVePtp() external view returns (uint256);

    function unstakePTP() external;

    function pendingPtpForPool(address _token) external view returns (uint256 pendingPtp);

    function masterPlatypus() external view returns (address);

    function getLPTokensForShares(uint256 amount, address token) external view returns (uint256);

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
        address _staking,
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

    function depositWithDifferentAsset(
        address token,
        address asset,
        uint256 amount,
        address sender
    ) external;

    function multiHarvest(address token, bool isUser) external;

    function withdrawWithDifferentAsset(
        address token,
        address asset,
        uint256 _amount,
        uint256 minAmount,
        address sender
    ) external;

    function registerPoolWithDifferentAsset(
        uint256 _pid,
        address _token,
        address _lpAddress,
        address _assetToken,
        string memory receiptName,
        string memory receiptSymbol,
        uint256 allocPoints
    ) external;

    function pendingBribeCallerFee(address[] calldata pendingPools)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory callerFeeAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";

interface IBoostedMultiRewarder {
    function dilutingRepartition() external view returns (uint256);

    struct PoolInfo {
        address rewardToken; // if rewardToken is 0, native token is used as reward token
        uint96 tokenPerSec; // 10.18 fixed point
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth. Times 1e12
        uint128 accTokenPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share. Time 1e12
    }

    function poolInfo(uint256 i)
        external
        view
        returns (
            address rewardToken, // Address of LP token contract.
            uint96 tokenPerSec, // How many base allocation points assigned to this pool
            uint128 accTokenPerShare, // Last timestamp that PTPs distribution occurs.
            uint128 accTokenPerFactorShare
        );

    function onPtpReward(
        address _user,
        uint256 _lpAmount,
        uint256 _newLpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external returns (uint256[] memory rewards);

    function onUpdateFactor(
        address _user,
        uint256 _lpAmount,
        uint256 _factor,
        uint256 _newFactor
    ) external;

    function pendingTokens(
        address _user,
        uint256 _lpAmount,
        uint256 _factor
    ) external view returns (uint256[] memory rewards);

    function rewardToken() external view returns (address token);

    function tokenPerSec() external view returns (uint256);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterPlatypusv4 {
    // Info of each user.
    struct UserInfo {
        // 256 bit packed
        uint128 amount; // How many LP tokens the user has provided.
        uint128 factor; // non-dialuting factor = sqrt (lpAmount * vePtp.balanceOf())
        // 256 bit packed
        uint128 rewardDebt; // Reward debt. See explanation below.
        uint128 claimablePtp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of PTPs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accPtpPerShare + user.factor * pool.accPtpPerFactorShare) / 1e12) -
        //        user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPtpPerShare`, `accPtpPerFactorShare` (and `lastRewardTimestamp`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        address rewarder;
        uint128 sumOfFactors; // 20.18 fixed point. The sum of all non dialuting factors by all of the users in the pool
        uint128 accPtpPerShare; // 26.12 fixed point. Accumulated PTPs per share, times 1e12.
        uint128 accPtpPerFactorShare; // 26.12 fixed point. Accumulated ptp per factor share
    }

    function getSumOfFactors(uint256) external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolId(address) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function liquidate(
        uint256 _pid,
        address _user,
        uint256 _amount
    ) external;

    function emergencyWithdraw(uint256 _pid) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function notifyRewardAmount(address _lpToken, uint256 _amount) external;

    function dilutingRepartition() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        );

    function userInfo(uint256 _pid, address _address)
        external
        view
        returns (
            uint128 amount,
            uint128 factor,
            uint128 rewardDebt,
            uint128 claimablePtp
        );

    function migrate(uint256[] calldata _pids) external;

    function poolInfo(uint256 i)
        external
        view
        returns (
            address lpToken,
            address rewarder,
            uint128 sumOfFactors,
            uint128 accPtpPerShare,
            uint128 accPtpPerFactorShare
        );
}

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseRewardPool {
    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 historicalRewards;
    }

    function rewards(address token) external view returns (Reward memory rewardInfo);

    function rewards(uint256 i)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function rewardTokens() external view returns (address[] memory);

    // These are for TraderJoe Rewarder
    function rewardToken() external view returns (address);

    function pendingTokens(address user) external view returns (uint256);

    function balance() external view returns (uint256);

    function userInfo(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 unpaidRewards
        );

    // END
    function getStakingToken() external view returns (address);

    function isRewardToken(address token) external view returns (bool);

    function getReward(address _account) external returns (bool);

    function getReward(address _account, uint256 percentage) external;

    function rewardDecimals(address token) external view returns (uint256);

    function stakingDecimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function updateFor(address account) external;

    function earned(address account, address token) external view returns (uint256);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdrawFor(
        address user,
        uint256 amount,
        bool claim
    ) external;

    function queueNewRewards(uint256 _rewards, address token) external returns (bool);

    function donateRewards(uint256 _amountReward, address _rewardToken) external returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAPRHelper {
    function getPTPperYear(address lp) external view returns (uint256 ptpPerYearPerToken);

    function masterPlatypus() external view returns (address);

    function voter() external view returns (address);

    function mainstakingTJ() external view returns (address);

    function locker() external view returns (address);

    function factory() external view returns (address);

    function mainStaking() external view returns (address);

    function balanceHelper() external view returns (address);

    function masterChief() external view returns (address);

    function vtx() external view returns (address);

    function pool2token(address lp) external view returns (address);

    function lp2asset(address lp) external view returns (address);

    function getLengthTJPools() external view returns (uint256);

    function tjPools(uint256 i) external view returns (address);

    function getLengthPtpPools() external view returns (uint256);

    function ptpPools(uint256 i) external view returns (address);

    function getTVL(address lp) external view returns (uint256 TVLinUSD);

    function getPTPperYearForVector(address lp)
        external
        view
        returns (uint256 pendingBasePtp, uint256 pendingBoostedPtp);

    function getAPRforPTPPoolInPTP(address lp)
        external
        view
        returns (uint256 baseAPR, uint256 boostedAPR);

    function getMultipleAPRforPTPPoolsInPTP(address[] calldata lp)
        external
        view
        returns (uint256[] memory baseAPR, uint256[] memory boostedAPR);

    function getMultipleAPRforPTPPoolsInAdditionalReward(address[] calldata lp)
        external
        view
        returns (uint256[] memory APR);

    function getAPRforPTPPoolInAdditionalReward(address lp) external view returns (uint256 APR);

    function getTokenPricePairedWithAvax(address token) external view returns (uint256 tokenPrice);

    function getPlatypusFees(uint256 index) external view returns (uint256 feeAmount);

    function getPTPClaimableRewards(
        address lp,
        address[] calldata inputRewardTokens,
        address user
    )
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getPTPHarvestableRewards(address lp, address user)
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) external view returns (uint256 ratio);

    function leftVotes(uint256[] calldata percentages)
        external
        view
        returns (int256 left, uint256 totalPercentage);

    function votesInBigNumbers(uint256[] calldata percentages)
        external
        view
        returns (uint256[] memory votes, uint256 totalPercentage);

    function getTVLForLocker() external view returns (uint256 lockerTVL);

    function getXPTPAPRForLocker(uint256 feeAmount) external view returns (uint256 APR);

    function getPendingBribes(
        address user,
        address lp,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts);

    function getAllPendingBribes(
        address user,
        address[] calldata lps,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory allRewardTokens, uint256[] memory totalAmounts);

    function getVTXAPRForLocker() external view returns (uint256 APR);

    function getBribes(address lp) external view returns (uint256 bribesPerYear);

    function getFutureBribes(address lp, uint256 vtxDelta)
        external
        view
        returns (uint256 bribesPerYear);

    function getTVLOfVotedLocker() external view returns (uint256 votedLocker);

    function getAPRforVotingForLVTX(address lp) external view returns (uint256 APR);

    function getAPRPreview(address lp, uint256 vtxDelta) external view returns (uint256 APR);

    function getPendingRewardsFromLocker(address user, address[] calldata inputRewardTokens)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory amounts);

    // function getVePtpPerVTX() public view returns (uint256 votingPower) {
    //     votingPower = IBribeManager(bribeManager).veptpPerLockedVtx();
    // }

    function getBribesPerAmount(address lp, uint256 vtxAmount)
        external
        view
        returns (uint256 bribesPerYear);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBalanceHelper {
    function getPTPperYear(address lp) external view returns (uint256 ptpPerYearPerToken);

    function getTVL(address lp) external view returns (uint256 TVLinUSD);

    function getAvaxLatestPrice() external view returns (uint256);

    function getPTPperYearForVector(address lp)
        external
        view
        returns (uint256 pendingBasePtp, uint256 pendingBoostedPtp);

    function getAPRforPTPPoolInPTP(address lp)
        external
        view
        returns (uint256 baseAPR, uint256 boostedAPR);

    function getMultipleAPRforPTPPoolsInPTP(address[] calldata lp)
        external
        view
        returns (uint256[] memory baseAPR, uint256[] memory boostedAPR);

    function getMultipleAPRforPTPPoolsInAdditionalReward(address[] calldata lp)
        external
        view
        returns (uint256[] memory APR);

    function getAPRforPTPPoolInAdditionalReward(address lp) external view returns (uint256 APR);

    function getTokenPricePairedWithAvax(address token) external view returns (uint256 tokenPrice);

    function getPlatypusFees(uint256 index) external view returns (uint256 feeAmount);

    function getPTPClaimableRewards(
        address lp,
        address[] calldata inputRewardTokens,
        address user
    )
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getPTPHarvestableRewards(address lp, address user)
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) external view returns (uint256 ratio);

    function leftVotes(uint256[] calldata percentages)
        external
        view
        returns (int256 left, uint256 totalPercentage);

    function votesInBigNumbers(uint256[] calldata percentages)
        external
        view
        returns (uint256[] memory votes, uint256 totalPercentage);

    function getTVLForLocker() external view returns (uint256 lockerTVL);

    function getXPTPAPRForLocker(uint256 feeAmount) external view returns (uint256 APR);

    function getPendingBribes(
        address user,
        address lp,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts);

    function getAllPendingBribes(
        address user,
        address[] calldata lps,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory allRewardTokens, uint256[] memory totalAmounts);

    function getVTXAPRForLocker() external view returns (uint256 APR);

    function getBribes(address lp) external view returns (uint256 bribesPerYear);

    function getFutureBribes(address lp, uint256 vtxDelta)
        external
        view
        returns (uint256 bribesPerYear);

    function getTVLOfVotedLocker() external view returns (uint256 votedLocker);

    function getAPRforVotingForLVTX(address lp) external view returns (uint256 APR);

    function getAPRPreview(address lp, uint256 vtxDelta) external view returns (uint256 APR);

    function getPendingRewardsFromLocker(address user, address[] calldata inputRewardTokens)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory amounts);

    // function getVePtpPerVTX() public view returns (uint256 votingPower) {
    //     votingPower = IBribeManager(bribeManager).veptpPerLockedVtx();
    // }

    function getBribesPerAmount(address lp, uint256 vtxAmount)
        external
        view
        returns (uint256 bribesPerYear);
}