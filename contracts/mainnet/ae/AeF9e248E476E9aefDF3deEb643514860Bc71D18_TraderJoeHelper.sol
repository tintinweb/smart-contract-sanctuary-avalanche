// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "IJoePair.sol";
import "IMasterChefVTX.sol";
import "IMainStakingJoe.sol";
import "IBoostedMultiRewarder.sol";
import "IJoeFactory.sol";
import "IBribeManager.sol";
import "IMasterChefVTX.sol";
import "ILockerV2.sol";
import "IBribe.sol";
import "IBaseRewardPool.sol";
import "AggregatorV3Interface.sol";
import "IAPRHelper.sol";
import "IBalanceHelper.sol";
import "ISimpleRewarderPerSec.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";

import "IJoeERC20.sol";
import "IJoePair.sol";
import "IJoeFactory.sol";

interface IMasterChef {
    struct PoolInfo {
        IJoeERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. JOE to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that JOE distribution occurs.
        uint256 accJoePerShare; // Accumulated JOE per share, times 1e12. See below.
    }

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function joePerSec() external view returns (uint256);
}

interface IBoostedMasterchef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 factor;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint96 allocPoint;
        uint256 accJoePerShare;
        uint256 accJoePerFactorPerShare;
        uint64 lastRewardTimestamp;
        address rewarder;
        uint32 veJoeShareBp;
        uint256 totalFactor;
        uint256 totalLpSupply;
    }

    function userInfo(uint256 _pid, address user) external view returns (UserInfo memory);

    function pendingTokens(uint256 _pid, address user)
        external
        view
        returns (
            uint256,
            address,
            string memory,
            uint256
        );

    function poolLength() external view returns (uint256);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function joePerSec() external view returns (uint256);
}

contract TraderJoeHelper is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;
    uint256 internal constant ACC_TOKEN_PRECISION = 1e15;
    uint256 public constant AvaxUSDDecimals = 8;
    uint256 public constant precision = 8;
    bytes4 private constant SIG_DECIMALS = 0x313ce567;

    // address public wavax;
    address public aprHelper;

    uint256 public constant FEE_DENOMINATOR = 10000;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 factor;
        uint256 accTokenPerShare;
        uint256 accTokenPerFactorShare;
    }

    struct HelpStack {
        address[] rewardTokens;
        uint256[] amounts;
        uint256 length;
        uint256 pid;
        uint256 balanceOf;
        address vectorRewarder;
        address mainStakingTJ;
    }

    // End of Storage v2
    /// @dev 365 * 86400, hard coding it for gas optimisation
    uint256 public constant SEC_PER_YEAR = 31536000;
    uint256 public constant BP_PRECISION = 10_000;
    uint256 public constant PRECISION = 1e18;
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()

    address public immutable joe; // 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    address public immutable wavax; // 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    IJoePair public immutable wavaxUsdte; // 0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256
    IJoePair public immutable wavaxUsdce; // 0xA389f9430876455C36478DeEa9769B7Ca4E3DDB1
    IJoePair public immutable wavaxUsdc; // 0xf4003f4efbe8691b60249e6afbd307abe7758adb
    IJoeFactory public immutable joeFactory; // 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10
    IMasterChef public immutable chefv2; // 0xd6a4F121CA35509aF06A0Be99093d08462f53052
    IMasterChef public immutable chefv3; // 0x188bED1968b795d5c9022F6a0bb5931Ac4c18F00
    IBoostedMasterchef public immutable bmcj; // Not deployed yet
    bool public immutable isWavaxToken1InWavaxUsdte;
    bool public immutable isWavaxToken1InWavaxUsdce;
    bool public immutable isWavaxToken1InWavaxUsdc;

    struct UserPoolInfo {
        uint256 approvalAmount;
        uint256 balance;
        uint256 balanceUSD;
        uint256[] rewards;
        uint256[] rewardsUSD;
        address[] tokenRewards;
        uint256[] harvestable;
        address[] tokenHarvestable;
        uint256[] harvestableUSD;
    }

    constructor(
        address _joe,
        address _wavax,
        IJoePair _wavaxUsdte,
        IJoePair _wavaxUsdce,
        IJoePair _wavaxUsdc,
        IJoeFactory _joeFactory,
        IMasterChef _chefv2,
        IMasterChef _chefv3,
        IBoostedMasterchef _bmcj,
        address _aprHelper
    ) {
        priceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
        aprHelper = _aprHelper;
        joe = _joe;
        wavax = _wavax;
        wavaxUsdte = _wavaxUsdte;
        wavaxUsdce = _wavaxUsdce;
        wavaxUsdc = _wavaxUsdc;
        joeFactory = _joeFactory;
        chefv2 = _chefv2;
        chefv3 = _chefv3;
        bmcj = _bmcj;

        isWavaxToken1InWavaxUsdte = _wavaxUsdte.token1() == _wavax;
        isWavaxToken1InWavaxUsdce = _wavaxUsdce.token1() == _wavax;
        isWavaxToken1InWavaxUsdc = _wavaxUsdc.token1() == _wavax;
    }

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_DECIMALS)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_SYMBOL)
        );
        return success ? returnDataToString(data) : "???";
    }

    /**
     * Returns the latest price
     */
    function getAvaxLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getJoeLPPrice(address lp) public view returns (uint256 inUSD) {
        address balanceHelper = IAPRHelper(aprHelper).balanceHelper();
        inUSD = IBalanceHelper(balanceHelper).getJoeLPPrice(lp);
    }

    function getJoeLPsPrices(address[] calldata lps) public view returns (uint256[] memory inUSD) {
        uint256 length = lps.length;
        inUSD = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            inUSD[i] = getJoeLPPrice(lps[i]);
        }
    }

    function getTokenPricePairedWithAvax(address token) public view returns (uint256 tokenPrice) {
        address balanceHelper = IAPRHelper(aprHelper).balanceHelper();
        tokenPrice = IBalanceHelper(balanceHelper).getTokenPricePairedWithAvax(token);
    }

    function getTJClaimableRewards(
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
        address mainStakingTJ = IAPRHelper(aprHelper).mainstakingTJ();
        (uint256 pid, , , , address rewarder, address helper) = IMainStakingJoe(mainStakingTJ)
            .getPoolInfo(lp);
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

    function getTJHarvestableRewards(address lp, address user)
        public
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        )
    {
        HelpStack memory helpstack;
        helpstack.mainStakingTJ = IAPRHelper(aprHelper).mainstakingTJ();
        uint256[] memory pidList = new uint256[](1);
        (helpstack.pid, , , , helpstack.vectorRewarder, ) = IMainStakingJoe(helpstack.mainStakingTJ)
            .getPoolInfo(lp);
        pidList[0] = helpstack.pid;
        FarmInfoBMCJ[] memory farmInfos = _getBMCJFarmInfos(
            getAvaxLatestPrice(),
            getTokenPrice(joe),
            helpstack.mainStakingTJ,
            pidList
        );

        IBoostedMasterchef.PoolInfo memory pool = IBoostedMasterchef(bmcj).poolInfo(helpstack.pid);
        helpstack.length = (pool.rewarder == address(0)) ? 1 : 2;
        rewardTokens = new address[](helpstack.length);
        amounts = new uint256[](helpstack.length);
        usdAmounts = new uint256[](helpstack.length);
        rewardTokens[0] = joe;
        amounts[0] =
            (farmInfos[0].userPendingJoe *
                IBaseRewardPool(helpstack.vectorRewarder).balanceOf(user)) /
            IBaseRewardPool(helpstack.vectorRewarder).totalSupply();
        usdAmounts[0] =
            (amounts[0] * getTokenPricePairedWithAvax(rewardTokens[0])) /
            10**ERC20(rewardTokens[0]).decimals();
        if (pool.rewarder != address(0)) {
            rewardTokens[1] = ISimpleRewarderPerSec(pool.rewarder).rewardToken();
            (uint256 balanceOf, , ) = ISimpleRewarderPerSec(pool.rewarder).userInfo(
                helpstack.mainStakingTJ
            );
            amounts[1] =
                (ISimpleRewarderPerSec(pool.rewarder).pendingTokens(helpstack.mainStakingTJ) *
                    IBaseRewardPool(helpstack.vectorRewarder).balanceOf(user)) /
                IBaseRewardPool(helpstack.vectorRewarder).totalSupply();
            usdAmounts[1] =
                (amounts[1] * getTokenPricePairedWithAvax(rewardTokens[1])) /
                10**ERC20(rewardTokens[1]).decimals();
        }
    }

    function getUserInfo(address user, address[] calldata inputRewardTokens)
        public
        view
        returns (UserPoolInfo[] memory usersInfo)
    {
        uint256 length = IAPRHelper(aprHelper).getLengthTJPools();
        address mainStaking = IAPRHelper(aprHelper).mainstakingTJ();
        usersInfo = new UserPoolInfo[](length);
        for (uint256 i; i < length; ++i) {
            UserPoolInfo memory userInfo;
            address pool = IAPRHelper(aprHelper).tjPools(i);
            (, , , , address rewarder, address helper) = IMainStakingJoe(mainStaking).getPoolInfo(
                pool
            );
            userInfo.balance = IBaseRewardPool(rewarder).balanceOf(user);
            if (userInfo.balance > 0) {
                userInfo.balanceUSD = (userInfo.balance * getJoeLPPrice(pool)) / 10**(18);
                (
                    userInfo.tokenRewards,
                    userInfo.rewards,
                    userInfo.rewardsUSD
                ) = getTJClaimableRewards(pool, inputRewardTokens, user);
                (
                    userInfo.tokenHarvestable,
                    userInfo.harvestable,
                    userInfo.harvestableUSD
                ) = getTJHarvestableRewards(pool, user);
            }
            userInfo.approvalAmount = IERC20(pool).allowance(user, helper);
            usersInfo[i] = userInfo;
        }
    }

    struct FarmInfo {
        uint256 id;
        uint256 allocPoint;
        address lpAddress;
        address token0Address;
        address token1Address;
        string token0Symbol;
        string token1Symbol;
        uint256 reserveUsd;
        uint256 totalSupplyScaled;
        address chefAddress;
        uint256 chefBalanceScaled;
        uint256 chefTotalAlloc;
        uint256 chefJoePerSec;
    }

    struct FarmInfoBMCJ {
        uint256 id;
        uint256 allocPoint;
        address lpAddress;
        address token0Address;
        address token1Address;
        string token0Symbol;
        string token1Symbol;
        uint256 reserveUsd;
        uint256 totalSupplyScaled;
        address chefAddress;
        uint256 chefBalanceScaled;
        uint256 chefTotalAlloc;
        uint256 chefJoePerSec;
        uint256 baseApr;
        uint256 averageBoostedApr;
        uint256 veJoeShareBp;
        uint256 joePriceUsd;
        uint256 userLp;
        uint256 userPendingJoe;
        uint256 userBoostedApr;
        uint256 userFactorShare;
    }

    struct AllFarmData {
        uint256 avaxPriceUsd;
        uint256 joePriceUsd;
        uint256 totalAllocChefV2;
        uint256 totalAllocChefV3;
        uint256 totalAllocBMCJ;
        uint256 joePerSecChefV2;
        uint256 joePerSecChefV3;
        uint256 joePerSecBMCJ;
        FarmInfo[] farmInfosV2;
        FarmInfo[] farmInfosV3;
        FarmInfoBMCJ[] farmInfosBMCJ;
    }

    struct GlobalInfo {
        address chef;
        uint256 totalAlloc;
        uint256 joePerSec;
    }

    /// @notice Returns the Usd price of token, it needs to be paired with wavax
    /// @param token The address of the token
    /// @return uint256 the Usd price of token, scaled to 18 decimals
    function getTokenPrice(address token) public view returns (uint256) {
        return _getDerivedAvaxPriceOfToken(token).mul(_getAvaxPrice()) / 1e18;
    }

    /// @notice Returns the farm pairs data for MCV2 and MCV3
    /// @param chef The address of the MasterChef
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function getMCFarmInfos(IMasterChef chef, uint256[] calldata whitelistedPids)
        external
        view
        returns (FarmInfo[] memory)
    {
        require(chef == chefv2 || chef == chefv3, "FarmLensV2: only for MCV2 and MCV3");

        uint256 avaxPrice = _getAvaxPrice();
        return _getMCFarmInfos(chef, avaxPrice, whitelistedPids);
    }

    /// @notice Returns the farm pairs data for BoostedMasterChefJoe
    /// @param chef The address of the MasterChef
    /// @param user The address of the user, if address(0), returns global info
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfoBMCJ The information of all the whitelisted farms of BMCJ
    function getBMCJFarmInfos(
        IBoostedMasterchef chef,
        address user,
        uint256[] calldata whitelistedPids
    ) external view returns (FarmInfoBMCJ[] memory) {
        require(chef == bmcj, "FarmLensV2: Only for BMCJ");

        uint256 avaxPrice = _getAvaxPrice();
        uint256 joePrice = _getDerivedAvaxPriceOfToken(joe).mul(avaxPrice) / PRECISION;
        return _getBMCJFarmInfos(avaxPrice, joePrice, user, whitelistedPids);
    }

    /// @notice Get all data needed for useFarms hook.
    /// @param whitelistedPidsV2 Array of all ids of pools that are whitelisted in chefV2
    /// @param whitelistedPidsV3 Array of all ids of pools that are whitelisted in chefV3
    /// @param whitelistedPidsBMCJ Array of all ids of pools that are whitelisted in BMCJ
    /// @param user The address of the user, if address(0), returns global info
    /// @return AllFarmData The information of all the whitelisted farms of MCV2, MCV3 and BMCJ
    function getAllFarmData(
        uint256[] calldata whitelistedPidsV2,
        uint256[] calldata whitelistedPidsV3,
        uint256[] calldata whitelistedPidsBMCJ,
        address user
    ) external view returns (AllFarmData memory) {
        AllFarmData memory allFarmData;

        uint256 avaxPrice = _getAvaxPrice();
        uint256 joePrice = _getDerivedAvaxPriceOfToken(joe).mul(avaxPrice) / PRECISION;

        allFarmData.avaxPriceUsd = avaxPrice;
        allFarmData.joePriceUsd = joePrice;

        allFarmData.totalAllocChefV2 = chefv2.totalAllocPoint();
        allFarmData.joePerSecChefV2 = chefv2.joePerSec();

        allFarmData.totalAllocChefV3 = chefv3.totalAllocPoint();
        allFarmData.joePerSecChefV3 = chefv3.joePerSec();

        allFarmData.totalAllocBMCJ = bmcj.totalAllocPoint();
        allFarmData.joePerSecBMCJ = bmcj.joePerSec();

        allFarmData.farmInfosV2 = _getMCFarmInfos(chefv2, avaxPrice, whitelistedPidsV2);
        allFarmData.farmInfosV3 = _getMCFarmInfos(chefv3, avaxPrice, whitelistedPidsV3);
        allFarmData.farmInfosBMCJ = _getBMCJFarmInfos(
            avaxPrice,
            joePrice,
            user,
            whitelistedPidsBMCJ
        );

        return allFarmData;
    }

    /// @notice Returns the price of avax in Usd internally
    /// @return uint256 the avax price, scaled to 18 decimals
    function _getAvaxPrice() public view returns (uint256) {
        return
            _getDerivedTokenPriceOfPair(wavaxUsdte, isWavaxToken1InWavaxUsdte)
                .add(_getDerivedTokenPriceOfPair(wavaxUsdce, isWavaxToken1InWavaxUsdce))
                .add(_getDerivedTokenPriceOfPair(wavaxUsdc, isWavaxToken1InWavaxUsdc)) / 3;
    }

    /// @notice Returns the derived price of token in the other token
    /// @param pair The address of the pair
    /// @param derivedtoken0 If price should be derived from token0 if true, or token1 if false
    /// @return uint256 the derived price, scaled to 18 decimals
    function _getDerivedTokenPriceOfPair(IJoePair pair, bool derivedtoken0)
        public
        view
        returns (uint256)
    {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 decimals0 = safeDecimals(IERC20(pair.token0()));
        uint256 decimals1 = safeDecimals(IERC20(pair.token1()));

        if (derivedtoken0) {
            return _scaleTo(reserve0, decimals1.add(18).sub(decimals0)).div(reserve1);
        } else {
            return _scaleTo(reserve1, decimals0.add(18).sub(decimals1)).div(reserve0);
        }
    }

    /// @notice Returns the derived price of token, it needs to be paired with wavax
    /// @param token The address of the token
    /// @return uint256 the token derived price, scaled to 18 decimals
    function _getDerivedAvaxPriceOfToken(address token) public view returns (uint256) {
        if (token == wavax) {
            return PRECISION;
        }
        IJoePair pair = IJoePair(joeFactory.getPair(token, wavax));
        if (address(pair) == address(0)) {
            return 0;
        }
        // instead of testing wavax == pair.token0(), we do the opposite to save gas
        return _getDerivedTokenPriceOfPair(pair, token == pair.token1());
    }

    /// @notice Returns the amount scaled to decimals
    /// @param amount The amount
    /// @param decimals The decimals to scale `amount`
    /// @return uint256 The amount scaled to decimals
    function _scaleTo(uint256 amount, uint256 decimals) public pure returns (uint256) {
        if (decimals == 0) return amount;
        return amount.mul(10**decimals);
    }

    /// @notice Returns the derived avax liquidity, at least one of the token needs to be paired with wavax
    /// @param pair The address of the pair
    /// @return uint256 the derived price of pair's liquidity, scaled to 18 decimals
    function _getDerivedAvaxLiquidityOfPair(IJoePair pair) public view returns (uint256) {
        address _wavax = wavax;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        IERC20 token0 = IERC20(pair.token0());
        IERC20 token1 = IERC20(pair.token1());
        uint256 decimals0 = safeDecimals(token0);
        uint256 decimals1 = safeDecimals(token1);

        reserve0 = _scaleTo(reserve0, uint256(18).sub(decimals0));
        reserve1 = _scaleTo(reserve1, uint256(18).sub(decimals1));

        uint256 token0DerivedAvaxPrice;
        uint256 token1DerivedAvaxPrice;
        if (address(token0) == _wavax) {
            token0DerivedAvaxPrice = PRECISION;
            token1DerivedAvaxPrice = _getDerivedTokenPriceOfPair(pair, true);
        } else if (address(token1) == _wavax) {
            token0DerivedAvaxPrice = _getDerivedTokenPriceOfPair(pair, false);
            token1DerivedAvaxPrice = PRECISION;
        } else {
            token0DerivedAvaxPrice = _getDerivedAvaxPriceOfToken(address(token0));
            token1DerivedAvaxPrice = _getDerivedAvaxPriceOfToken(address(token1));
            // If one token isn't paired with wavax, then we hope that the second one is.
            // E.g, TOKEN/UsdC, token might not be paired with wavax, but UsdC is.
            // If both aren't paired with wavax, return 0
            if (token0DerivedAvaxPrice == 0)
                return reserve1.mul(token1DerivedAvaxPrice).mul(2) / PRECISION;
            if (token1DerivedAvaxPrice == 0)
                return reserve0.mul(token0DerivedAvaxPrice).mul(2) / PRECISION;
        }
        return
            reserve0.mul(token0DerivedAvaxPrice).add(reserve1.mul(token1DerivedAvaxPrice)) /
            PRECISION;
    }

    /// @notice public function to return the farm pairs data for a given MasterChef (V2 or V3)
    /// @param chef The address of the MasterChef
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function _getMCFarmInfos(
        IMasterChef chef,
        uint256 avaxPrice,
        uint256[] calldata whitelistedPids
    ) public view returns (FarmInfo[] memory) {
        uint256 whitelistLength = whitelistedPids.length;
        FarmInfo[] memory farmInfos = new FarmInfo[](whitelistLength);

        uint256 chefTotalAlloc = chef.totalAllocPoint();
        uint256 chefJoePerSec = chef.joePerSec();

        for (uint256 i; i < whitelistLength; i++) {
            uint256 pid = whitelistedPids[i];
            IMasterChef.PoolInfo memory pool = chef.poolInfo(pid);

            farmInfos[i] = _getMCFarmInfo(
                chef,
                avaxPrice,
                pid,
                IJoePair(address(pool.lpToken)),
                pool.allocPoint,
                chefTotalAlloc,
                chefJoePerSec
            );
        }

        return farmInfos;
    }

    /// @notice Helper function to return the farm info of a given pool
    /// @param chef The address of the MasterChef
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param pid The pid of the pool
    /// @param lpToken The lpToken of the pool
    /// @param allocPoint The allocPoint of the pool
    /// @return FarmInfo The information of all the whitelisted farms of MCV2 or MCV3
    function _getMCFarmInfo(
        IMasterChef chef,
        uint256 avaxPrice,
        uint256 pid,
        IJoePair lpToken,
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint256 chefJoePerSec
    ) public view returns (FarmInfo memory) {
        uint256 decimals = lpToken.decimals();
        uint256 totalSupplyScaled = _scaleTo(lpToken.totalSupply(), 18 - decimals);
        uint256 chefBalanceScaled = _scaleTo(lpToken.balanceOf(address(chef)), 18 - decimals);
        uint256 reserveUsd = _getDerivedAvaxLiquidityOfPair(lpToken).mul(avaxPrice) / PRECISION;
        IERC20 token0 = IERC20(lpToken.token0());
        IERC20 token1 = IERC20(lpToken.token1());

        return
            FarmInfo({
                id: pid,
                allocPoint: allocPoint,
                lpAddress: address(lpToken),
                token0Address: address(token0),
                token1Address: address(token1),
                token0Symbol: safeSymbol(token0),
                token1Symbol: safeSymbol(token1),
                reserveUsd: reserveUsd,
                totalSupplyScaled: totalSupplyScaled,
                chefBalanceScaled: chefBalanceScaled,
                chefAddress: address(chef),
                chefTotalAlloc: totalAllocPoint,
                chefJoePerSec: chefJoePerSec
            });
    }

    /// @notice public function to return the farm pairs data for boostedMasterChef
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param joePrice The joe price as a parameter to save gas
    /// @param user The address of the user, if address(0), returns global info
    /// @param whitelistedPids Array of all ids of pools that are whitelisted and valid to have their farm data returned
    /// @return FarmInfoBMCJ The information of all the whitelisted farms of BMCJ
    function _getBMCJFarmInfos(
        uint256 avaxPrice,
        uint256 joePrice,
        address user,
        uint256[] memory whitelistedPids
    ) public view returns (FarmInfoBMCJ[] memory) {
        GlobalInfo memory globalInfo = GlobalInfo(
            address(bmcj),
            bmcj.totalAllocPoint(),
            bmcj.joePerSec()
        );

        uint256 whitelistLength = whitelistedPids.length;
        FarmInfoBMCJ[] memory farmInfos = new FarmInfoBMCJ[](whitelistLength);

        for (uint256 i; i < whitelistLength; i++) {
            uint256 pid = whitelistedPids[i];
            IBoostedMasterchef.PoolInfo memory pool = IBoostedMasterchef(globalInfo.chef).poolInfo(
                pid
            );
            IBoostedMasterchef.UserInfo memory userInfo;
            userInfo = IBoostedMasterchef(globalInfo.chef).userInfo(pid, user);

            farmInfos[i].id = pid;
            farmInfos[i].chefAddress = globalInfo.chef;
            farmInfos[i].chefTotalAlloc = globalInfo.totalAlloc;
            farmInfos[i].chefJoePerSec = globalInfo.joePerSec;
            farmInfos[i].joePriceUsd = joePrice;
            _getBMCJFarmInfo(
                avaxPrice,
                globalInfo.joePerSec.mul(joePrice) / PRECISION,
                user,
                farmInfos[i],
                pool,
                userInfo
            );
        }

        return farmInfos;
    }

    /// @notice Helper function to return the farm info of a given pool of BMCJ
    /// @param avaxPrice The avax price as a parameter to save gas
    /// @param UsdPerSec The Usd per sec emitted to BMCJ
    /// @param userAddress The address of the user
    /// @param farmInfo The farmInfo of that pool
    /// @param user The user information
    function _getBMCJFarmInfo(
        uint256 avaxPrice,
        uint256 UsdPerSec,
        address userAddress,
        FarmInfoBMCJ memory farmInfo,
        IBoostedMasterchef.PoolInfo memory pool,
        IBoostedMasterchef.UserInfo memory user
    ) public view {
        {
            IJoePair lpToken = IJoePair(address(pool.lpToken));
            IERC20 token0 = IERC20(lpToken.token0());
            IERC20 token1 = IERC20(lpToken.token1());

            farmInfo.allocPoint = pool.allocPoint;
            farmInfo.lpAddress = address(lpToken);
            farmInfo.token0Address = address(token0);
            farmInfo.token1Address = address(token1);
            farmInfo.token0Symbol = safeSymbol(token0);
            farmInfo.token1Symbol = safeSymbol(token1);
            farmInfo.reserveUsd =
                _getDerivedAvaxLiquidityOfPair(lpToken).mul(avaxPrice) /
                PRECISION;
            // LP is in 18 decimals, so it's already scaled for JLP
            farmInfo.totalSupplyScaled = lpToken.totalSupply();
            farmInfo.chefBalanceScaled = pool.totalLpSupply;
            farmInfo.userLp = user.amount;
            farmInfo.veJoeShareBp = pool.veJoeShareBp;
            (farmInfo.userPendingJoe, , , ) = bmcj.pendingTokens(farmInfo.id, userAddress);
        }

        if (
            pool.totalLpSupply != 0 &&
            farmInfo.totalSupplyScaled != 0 &&
            farmInfo.chefTotalAlloc != 0 &&
            farmInfo.reserveUsd != 0
        ) {
            uint256 poolUsdPerYear = UsdPerSec.mul(pool.allocPoint).mul(SEC_PER_YEAR) /
                farmInfo.chefTotalAlloc;

            uint256 poolReserveUsd = farmInfo.reserveUsd.mul(farmInfo.chefBalanceScaled) /
                farmInfo.totalSupplyScaled;

            if (poolReserveUsd == 0) return;

            farmInfo.baseApr =
                poolUsdPerYear.mul(BP_PRECISION - pool.veJoeShareBp).mul(PRECISION) /
                poolReserveUsd /
                BP_PRECISION;

            if (pool.totalFactor != 0) {
                farmInfo.averageBoostedApr =
                    poolUsdPerYear.mul(pool.veJoeShareBp).mul(PRECISION) /
                    poolReserveUsd /
                    BP_PRECISION;

                if (user.amount != 0 && user.factor != 0) {
                    uint256 userLpUsd = user.amount.mul(farmInfo.reserveUsd) / pool.totalLpSupply;

                    farmInfo.userBoostedApr =
                        poolUsdPerYear
                            .mul(pool.veJoeShareBp)
                            .mul(user.factor)
                            .div(pool.totalFactor)
                            .mul(PRECISION) /
                        userLpUsd /
                        BP_PRECISION;

                    farmInfo.userFactorShare = user.factor.mul(PRECISION) / pool.totalFactor;
                }
            }
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
pragma solidity 0.8.7;

interface IMasterChefVTX {
    event Add(uint256 allocPoint, address indexed lpToken, address indexed rewarder);
    event Deposit(address indexed user, address indexed lpToken, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed lpToken, uint256 amount);
    event Harvest(address indexed user, address indexed lpToken, uint256 amount);
    event Locked(address indexed user, address indexed lpToken, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Set(
        address indexed lpToken,
        uint256 allocPoint,
        address indexed rewarder,
        address indexed locker,
        bool overwrite
    );
    event Unlocked(address indexed user, address indexed lpToken, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 _vtxPerSec);
    event UpdatePool(
        address indexed lpToken,
        uint256 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accVTXPerShare
    );
    event Withdraw(address indexed user, address indexed lpToken, uint256 amount);

    function PoolManagers(address) external view returns (bool);

    function __MasterChefVTX_init(
        address _vtx,
        uint256 _vtxPerSec,
        uint256 _startTimestamp
    ) external;

    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder,
        address _helper
    ) external;

    function addressToPoolInfo(address)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accVTXPerShare,
            address rewarder,
            address helper,
            address locker
        );

    function allowEmergency() external;

    function authorizeForLock(address _address) external;

    function createRewarder(address _lpToken, address mainRewardToken) external returns (address);

    function deposit(address _lp, uint256 _amount) external;

    function depositFor(
        address _lp,
        uint256 _amount,
        address sender
    ) external;

    function depositInfo(address _lp, address _user)
        external
        view
        returns (uint256 availableAmount);

    function emergencyWithdraw(address _lp) external;

    function emergencyWithdrawWithReward(address _lp) external;

    function getPoolInfo(address token)
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function isAuthorizedForLock(address) external view returns (bool);

    function massUpdatePools() external;

    function migrateEmergency(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external;

    function migrateToNewLocker(bool[] calldata onlyDeposit) external;

    function multiclaim(address[] calldata _lps, address user_address) external;

    function owner() external view returns (address);

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

    function poolLength() external view returns (uint256);

    function realEmergencyWithdraw(address _lp) external;

    function registeredToken(uint256) external view returns (address);

    function renounceOwnership() external;

    function set(
        address _lp,
        uint256 _allocPoint,
        address _rewarder,
        address _locker,
        bool overwrite
    ) external;

    function setPoolHelper(address _lp, address _helper) external;

    function setPoolManagerStatus(address _address, bool _bool) external;

    function setVtxLocker(address newLocker) external;

    function startTimestamp() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateEmissionRate(uint256 _vtxPerSec) external;

    function updatePool(address _lp) external;

    function vtx() external view returns (address);

    function vtxLocker() external view returns (address);

    function vtxPerSec() external view returns (uint256);

    function withdraw(address _lp, uint256 _amount) external;

    function withdrawFor(
        address _lp,
        uint256 _amount,
        address _sender
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IMainStakingJoe {
    event AddFee(address to, uint256 value, bool isJoe, bool isAddress);
    event JoeHarvested(uint256 amount, uint256 callerFee);
    event MasterChiefSet(address _token);
    event MasterJoeSet(address _token);
    event NewJoeStaked(uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PoolAdded(address tokenAddress);
    event PoolHelperSet(address _token);
    event PoolRemoved(address _token);
    event PoolRewarderSet(address token, address _poolRewarder);
    event RemoveFee(address to);
    event RewardPaidTo(address to, address rewardToken, uint256 feeAmount);
    event SetFee(address to, uint256 value);
    event veJoeClaimed(uint256 amount);

    function CALLER_FEE() external view returns (uint256);

    function MAX_CALLER_FEE() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function WAVAX() external view returns (address);

    function __MainStakingJoe_init(
        address _joe,
        address _boostedMasterChefJoe,
        address _masterVtx,
        address _veJoe,
        address _router,
        address _stakingJoe,
        uint256 _callerFee
    ) external;

    function addBonusRewardForAsset(address _asset, address _bonusToken) external;

    function addFee(
        uint256 max,
        uint256 min,
        uint256 value,
        address to,
        bool isJoe,
        bool isAddress
    ) external;

    function assetToBonusRewards(address, uint256) external view returns (address);

    function boostBufferActivated() external view returns (bool);

    function boostEndDate() external view returns (uint256 date);

    function boosterThreshold() external view returns (uint256);

    function bypassBoostWait() external view returns (bool);

    function claimVeJoe() external;

    function deposit(address token, uint256 amount) external;

    function donateTokenRewards(address _token, address _rewarder) external;

    function feeInfos(uint256)
        external
        view
        returns (
            uint256 maxValue,
            uint256 minValue,
            uint256 value,
            address to,
            bool isJoe,
            bool isAddress,
            bool isActive
        );

    function getPendingVeJoe() external view returns (uint256 pending);

    function getPoolInfo(address _address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address receipt,
            address rewardsAddr,
            address helper
        );

    function getStakedJoe() external view returns (uint256 stakedJoe);

    function getVeJoe() external view returns (uint256);

    function harvest(address token, bool isUser) external;

    function joe() external view returns (address);

    function joeBalance() external view returns (uint256);

    function masterJoe() external view returns (address);

    function masterVtx() external view returns (address);

    function owner() external view returns (address);

    function pools(address)
        external
        view
        returns (
            uint256 pid,
            bool isActive,
            address token,
            address receiptToken,
            address rewarder,
            address helper
        );

    function registerPool(
        uint256 _pid,
        address _token,
        string calldata receiptName,
        string calldata receiptSymbol,
        uint256 allocPoints
    ) external;

    function remainingForBoost() external view returns (uint256);

    function removeFee(uint256 index) external;

    function removePool(address token) external;

    function renounceOwnership() external;

    function router() external view returns (address);

    function sendTokenRewards(address _token, address _rewarder) external;

    function setBufferStatus(bool status) external;

    function setBypassBoostWait(bool status) external;

    function setCallerFee(uint256 value) external;

    function setFee(uint256 index, uint256 value) external;

    function setMasterChief(address _masterVtx) external;

    function setMasterJoe(address _masterJoe) external;

    function setPoolHelper(address token, address _poolhelper) external;

    function setPoolRewarder(address token, address _poolRewarder) external;

    function setSmartConvertor(address _smartConvertor) external;

    function setXJoe(address _xJoe) external;

    function smartConvertor() external view returns (address);

    function stakeJoe(uint256 _amount) external;

    function stakeJoeOwner(uint256 _amount) external;

    function stakingJoe() external view returns (address);

    function tokenToAvaxPool(address) external view returns (address);

    function totalFee() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function veJoe() external view returns (address);

    function withdraw(address token, uint256 _amount) external;

    function xJoe() external view returns (address);
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
pragma solidity 0.8.7;

interface IBribeManager {
    event AddPool(address indexed lp, address indexed rewarder);
    event AllVoteReset();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event VoteReset(address indexed lp);

    function __BribeManager_init(
        address _voter,
        address _veptp,
        address _mainStaking,
        address _locker
    ) external;

    function addPool(
        address _lp,
        address _rewarder,
        string calldata _name
    ) external;

    function avaxZapper() external view returns (address);

    function castVotes(bool swapForAvax)
        external
        returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts);

    function castVotesAndHarvestBribes(address[] calldata lps, bool swapForAvax) external;

    function castVotesCooldown() external view returns (uint256);

    function clearPools() external;

    function getLvtxVoteForPools(address[] calldata lps)
        external
        view
        returns (uint256[] memory lvtxVotes);

    function getUserLocked(address _user) external view returns (uint256);

    function getUserVoteForPools(address[] calldata lps, address _user)
        external
        view
        returns (uint256[] memory votes);

    function getVoteForLp(address lp) external view returns (uint256);

    function getVoteForLps(address[] calldata lps) external view returns (uint256[] memory votes);

    function harvestAllBribes(address _for)
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function harvestBribe(address[] calldata lps) external;

    function harvestBribeFor(address[] calldata lps, address _for) external;

    function harvestSinglePool(address[] calldata _lps) external;

    function isPoolActive(address pool) external view returns (bool);

    function lastCastTimer() external view returns (uint256);

    function locker() external view returns (address);

    function lpTokenLength() external view returns (uint256);

    function mainStaking() external view returns (address);

    function owner() external view returns (address);

    function poolInfos(address)
        external
        view
        returns (
            address poolAddress,
            address rewarder,
            bool isActive,
            string memory name
        );

    function poolTotalVote(address) external view returns (uint256);

    function pools(uint256) external view returns (address);

    function previewAvaxAmountForHarvest(address[] calldata _lps) external view returns (uint256);

    function previewBribes(
        address lp,
        address[] calldata inputRewardTokens,
        address _for
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts);

    function remainingVotes() external view returns (uint256);

    function removePool(uint256 _index) external;

    function renounceOwnership() external;

    function routePairAddresses(address) external view returns (address);

    function setAvaxZapper(address newZapper) external;

    function setPoolRewarder(address _pool, address _rewarder) external;

    function setVoter(address _voter) external;

    function totalVotes() external view returns (uint256);

    function totalVtxInVote() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unvote(address _lp) external;

    function usedVote() external view returns (uint256);

    function userTotalVote(address) external view returns (uint256);

    function userVoteForPools(address, address) external view returns (uint256);

    function vePtp() external view returns (address);

    function veptpPerLockedVtx() external view returns (uint256);

    function vote(address[] calldata _lps, int256[] calldata _deltas) external;

    function voteAndCast(
        address[] calldata _lps,
        int256[] calldata _deltas,
        bool swapForAvax
    ) external returns (address[] memory finalRewardTokens, uint256[] memory finalFeeAmounts);

    function voter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILockerV2 {
    struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 unlockingStrategy;
        uint256 alreadyUnstaked;
        uint256 alreadyWithdrawn;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Claim(address indexed user, uint256 indexed timestamp);
    event NewDeposit(address indexed user, uint256 indexed timestamp, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event ResetSlot(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 slotIndex
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Unlock(address indexed user, uint256 indexed timestamp, uint256 amount);
    event UnlockStarts(
        address indexed user,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 strategyIndex
    );
    event Unpaused(address account);

    function DENOMINATOR() external view returns (uint256);

    function VTX() external view returns (address);

    function __LockerV2_init_(
        address _masterchief,
        uint256 _maxSlots,
        address _previousLocker,
        address _rewarder,
        address _stakingToken
    ) external;

    function addNewStrategy(
        uint256 _lockTime,
        uint256 _rewardPercent,
        uint256 _forfeitPercent,
        uint256 _instantUnstakePercent,
        bool _isLinear
    ) external;

    function addToUnlock(uint256 amount, uint256 slotIndex) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function bribeManager() external view returns (address);

    function cancelUnlock(uint256 slotIndex) external;

    function claim()
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function claimFor(address _for)
        external
        returns (address[] memory rewardTokens, uint256[] memory earnedRewards);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount) external;

    function depositFor(address _for, uint256 _amount) external;

    function getAllUserUnlocking(address _user)
        external
        view
        returns (UserUnlocking[] memory slots);

    function getUserNthSlot(address _user, uint256 n)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );

    function getUserRewardPercentage(address _user)
        external
        view
        returns (uint256 rewardPercentage);

    function getUserSlotLength(address _user) external view returns (uint256);

    function getUserTotalDeposit(address _user) external view returns (uint256);

    function harvest() external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function masterchief() external view returns (address);

    function maxSlot() external view returns (uint256);

    function migrate(address user, bool[] calldata onlyDeposit) external;

    function migrateFor(
        address _from,
        address _to,
        bool[] calldata onlyDeposit
    ) external;

    function migrated(address) external view returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function previousLocker() external view returns (address);

    function renounceOwnership() external;

    function rewarder() external view returns (address);

    function setBribeManager(address _address) external;

    function setMaxSlots(uint256 _maxDeposits) external;

    function setPreviousLocker(address _locker) external;

    function setStrategyStatus(uint256 strategyIndex, bool status) external;

    function setWhitelistForTransfer(address _for, bool status) external;

    function stakeInMasterChief() external;

    function stakingToken() external view returns (address);

    function startUnlock(
        uint256 strategyIndex,
        uint256 amount,
        uint256 slotIndex
    ) external;

    function symbol() external view returns (string memory);

    function totalLocked() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalUnlocking() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function transferWhitelist(address) external view returns (bool);

    function unlock(uint256 slotIndex) external;

    function unlockingStrategies(uint256)
        external
        view
        returns (
            uint256 unlockTime,
            uint256 forfeitPercent,
            uint256 rewardPercent,
            uint256 instantUnstakePercent,
            bool isLinear,
            bool isActive
        );

    function unpause() external;

    function userUnlocking(address) external view returns (uint256);

    function userUnlockings(address, uint256)
        external
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 amount,
            uint256 unlockingStrategy,
            uint256 alreadyUnstaked,
            uint256 alreadyWithdrawn
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBribe {
    function balance() external view returns (uint256);

    function emergencyWithdraw() external;

    function isNative() external view returns (bool);

    function lpToken() external view returns (address);

    function onVote(
        address _user,
        uint256 _lpAmount,
        uint256 originalTotalVotes
    ) external returns (uint256);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function pendingTokens(address _user) external view returns (uint256 pending);

    function poolInfo()
        external
        view
        returns (uint128 accTokenPerShare, uint48 lastRewardTimestamp);

    function renounceOwnership() external;

    function rewardToken() external view returns (address);

    function setOperator(address _operator) external;

    function setRewardRate(uint256 _tokenPerSec) external;

    function tokenPerSec() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool() external;

    function userInfo(address)
        external
        view
        returns (
            uint128 amount,
            uint128 rewardDebt,
            uint256 unpaidRewards
        );

    function voter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBaseRewardPool {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardAdded(uint256 reward, address indexed token);
    event RewardPaid(address indexed user, uint256 reward, address indexed token);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address _account) external view returns (uint256);

    function donateRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function earned(address _account, address _rewardToken) external view returns (uint256);

    function getReward(address _account) external returns (bool);

    function getRewardUser() external returns (bool);

    function getStakingToken() external view returns (address);

    function isRewardToken(address) external view returns (bool);

    function mainRewardToken() external view returns (address);

    function operator() external view returns (address);

    function owner() external view returns (address);

    function queueNewRewards(uint256 _amountReward, address _rewardToken) external returns (bool);

    function renounceOwnership() external;

    function rewardDecimals(address _rewardToken) external view returns (uint256);

    function rewardManager() external view returns (address);

    function rewardPerToken(address _rewardToken) external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewards(address)
        external
        view
        returns (
            address rewardToken,
            uint256 rewardPerTokenStored,
            uint256 queuedRewards,
            uint256 historicalRewards
        );

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function stakingDecimals() external view returns (uint256);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateFor(address _account) external;

    function userRewardPerTokenPaid(address, address) external view returns (uint256);

    function userRewards(address, address) external view returns (uint256);

    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external returns (bool);
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
pragma solidity 0.8.7;

interface IAPRHelper {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function AvaxUSDDecimals() external view returns (uint256);

    function FEE_DENOMINATOR() external view returns (uint256);

    function __APRHelper_init(address _wavax, address _mainStaking) external;

    function addPTPPool(address lp) external;

    function addTJPool(address lp) external;

    function balanceHelper() external view returns (address);

    function bribeManager() external view returns (address);

    function factory() external view returns (address);

    function futureVePTPPerVotedVTX(uint256 amount) external view returns (uint256);

    function getAPRforLockerInAdditionalReward(address lp, uint256 feeAmount)
        external
        view
        returns (uint256[] memory APR, address[] memory rewardToken);

    function getAPRforPTPPoolInAdditionalReward(address lp) external view returns (uint256 APR);

    function getAPRforPTPPoolInAdditionalRewardArray(address lp)
        external
        view
        returns (uint256[] memory APR, address[] memory rewardToken);

    function getAPRforPTPPoolInPTP(address lp)
        external
        view
        returns (uint256 baseAPR, uint256 boostedAPR);

    function getAPRforVotingForLVTX(address lp) external view returns (uint256 APR);

    function getAPRforxPTPInAdditionalReward(address lp, uint256 feeAmount)
        external
        view
        returns (uint256[] memory APR, address[] memory rewardToken);

    function getAdditionalRewardsInUSDPerYear(address lp)
        external
        view
        returns (uint256[] memory USDPerYear, address[] memory rewardTokens);

    function getAllPendingBribes(
        address user,
        address[] calldata lps,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory allRewardTokens, uint256[] memory totalAmounts);

    function getAvaxLatestPrice() external view returns (uint256 price);

    function getBribes(address lp) external view returns (uint256 bribesPerYear);

    function getBribesPerAmount(address lp, uint256 vtxAmount)
        external
        view
        returns (uint256 bribesPerYear);

    function getFutureAPRforVotingForLVTX(
        address lp,
        uint256 newVotes,
        int256 delta
    ) external view returns (uint256 APR);

    function getFutureBribesPerAmount(
        address lp,
        uint256 vtxAmount,
        uint256 newVotes,
        int256 delta
    ) external view returns (uint256 bribesPerYear);

    function getJoeClaimableRewards(
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

    function getJoeHarvestableRewards(address lp, address user)
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory amounts,
            uint256[] memory usdAmounts
        );

    function getJoeLPPrice(address lp) external view returns (uint256 inUSD);

    function getJoeLPsPrices(address[] calldata lps) external view returns (uint256[] memory inUSD);

    function getLPPrice(address lp) external view returns (uint256 inUSD);

    function getLPsPrice(address[] calldata lps) external view returns (uint256[] memory inUSD);

    function getLengthPtpPools() external view returns (uint256 length);

    function getLengthTJPools() external view returns (uint256 length);

    function getMultipleAPRforLockerlsInAdditionalReward(
        uint256 feeAmount,
        address[] calldata lps,
        address[] calldata inputRewardTokens
    ) external view returns (uint256[] memory APRs, address[] memory rewardTokens);

    function getMultipleAPRforPTPPoolsInPTP(address[] calldata lp)
        external
        view
        returns (uint256[] memory baseAPR, uint256[] memory boostedAPR);

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

    function getPTPperYear(address lp) external view returns (uint256 ptpPerYearPerToken);

    function getPTPperYearForVector(address lp)
        external
        view
        returns (uint256 pendingBasePtp, uint256 pendingBoostedPtp);

    function getPendingBribes(
        address user,
        address lp,
        address[] calldata inputRewardTokens
    ) external view returns (address[] memory rewardTokens, uint256[] memory amounts);

    function getPendingRewardsFromLocker(address user, address[] calldata inputRewardTokens)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory amounts);

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) external view returns (uint256 ratio);

    function getTVL(address lp) external view returns (uint256 TVLinUSD);

    function getTVLForLocker() external view returns (uint256 lockerTVL);

    function getTVLOfVotedLocker() external view returns (uint256 votedLocker);

    function getTokenPricePairedWithAvax(address token) external view returns (uint256 tokenPrice);

    function getVTXAPRForLocker() external view returns (uint256 APR);

    function getXPTPAPRForLocker(uint256 feeAmount) external view returns (uint256 APR);

    function getXPTPTVL() external view returns (uint256 usdValue);

    function locker() external view returns (address);

    function lp2asset(address) external view returns (address);

    function lp2pid(address) external view returns (uint256);

    function mainStaking() external view returns (address);

    function mainstakingTJ() external view returns (address);

    function masterChief() external view returns (address);

    function masterPlatypus() external view returns (address);

    function owner() external view returns (address);

    function platypusHelper() external view returns (address);

    function pool2pid(address) external view returns (address);

    function pool2token(address) external view returns (address);

    function precision() external view returns (uint256);

    function ptp() external view returns (address);

    function ptpPools(uint256) external view returns (address);

    function renounceOwnership() external;

    function setTraderJoeMainstaking(address _mainStakingTJ) external;

    function setbalanceHelper(address _balanceHelper) external;

    function setlp2asset(address lp, address asset) external;

    function setplatypusHelper(address _platypusHelper) external;

    function setpool2token(address lp, address token) external;

    function settraderJoeHelper(address _traderJoeHelper) external;

    function tjPools(uint256) external view returns (address);

    function traderJoeHelper() external view returns (address);

    function transferOwnership(address newOwner) external;

    function vePTPPerVotedVTX() external view returns (uint256);

    function voter() external view returns (address);

    function vtx() external view returns (address);

    function wavax() external view returns (address);

    function xPTP() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBalanceHelper {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function AvaxUSDDecimals() external view returns (uint256);

    function FEE_DENOMINATOR() external view returns (uint256);

    function aprHelper() external view returns (address);

    function getAvaxLatestPrice() external view returns (uint256);

    function getRatio(
        address numerator,
        address denominator,
        uint256 decimals
    ) external view returns (uint256 ratio);

    function getTVLForLocker() external view returns (uint256 lockerTVL);

    function getJoeLPPrice(address lp) external view returns (uint256 inUSD);

    function getTokenPricePairedWithAvax(address token) external view returns (uint256 tokenPrice);

    function getTokenPricePairedWithStable(address token, address stable)
        external
        view
        returns (uint256 tokenPrice);

    function getVTXAPRForLocker() external view returns (uint256 APR);

    function owner() external view returns (address);

    function precision() external view returns (uint256);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function wavax() external view returns (address);

    function yyAvax() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface ISimpleRewarderPerSec {
    function tokenPerSec() external view returns (uint256);

    function userInfo(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 unpaidRewards
        );

    function rewardToken() external view returns (address);

    /// @notice Sets the distribution reward rate. This will also update the poolInfo.
    /// @param _tokenPerSec The number of tokens to distribute per second
    function setRewardRate(uint256 _tokenPerSec) external;

    /// @notice Function called by MasterChefJoe whenever staker claims JOE harvest. Allows staker to also receive a 2nd reward token.
    /// @param _user Address of user
    /// @param _lpAmount Number of LP tokens the user has
    function onJoeReward(address _user, uint256 _lpAmount) external;

    /// @notice View function to see pending tokens
    /// @param _user Address of user.
    /// @return pending reward for a given user.
    function pendingTokens(address _user) external view returns (uint256 pending);

    /// @notice In case rewarder is stopped before emissions finished, this function allows
    /// withdrawal of remaining tokens.
    function emergencyWithdraw() external;

    /// @notice View function to see balance of reward token.
    function balance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoeERC20 {
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
}