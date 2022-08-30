// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '../common/StewardBase.sol';
import {AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';

/**
 * @dev This steward lists MAI as borrowing asset and collateral in isolation on Aave V3 Avalanche
 * - Parameter snapshot: https://snapshot.org/#/aave.eth/proposal/0x751b8fd1c77677643e419d327bdf749c29ccf0a0269e58ed2af0013843376051
 * The proposal is, as agreed with the proposer, more conservative than the approved parameters:
 * - Enabled as collateral in isolation, with 2m debt ceiling
 * - Adding a 50M supply cap
 * - The eMode lq treshold will be 97.5, instead of the suggested 98% as the parameters are per emode not per asset
 * - The reserve factor will be 10% instead of 5% to be consistent with other stable coins
 */
contract AaveV3AvaMAIListingSteward is StewardBase {
    // **************************
    // Protocol's contracts
    // **************************

    address public constant AAVE_TREASURY =
        0x5ba7fd868c40c16f7aDfAe6CF87121E13FC2F7a0;
    address public constant INCENTIVES_CONTROLLER =
        0x929EC64c34a17401F460460D4B9390518E5B473e;

    // **************************
    // New asset being listed (MAI)
    // **************************

    address public constant UNDERLYING =
        0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b;
    string public constant ATOKEN_NAME = 'Aave Avalanche MAI';
    string public constant ATOKEN_SYMBOL = 'aAvaMAI';
    string public constant VDTOKEN_NAME =
        'Aave Avalanche Variable Debt MAI';
    string public constant VDTOKEN_SYMBOL = 'variableDebtAvaMAI';
    string public constant SDTOKEN_NAME = 'Aave Avalanche Stable Debt MAI';
    string public constant SDTOKEN_SYMBOL = 'stableDebtAvaMAI';

    address public constant PRICE_FEED =
        0x5D1F504211c17365CA66353442a74D4435A8b778;

    address public constant ATOKEN_IMPL =
        0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;
    address public constant VDTOKEN_IMPL =
        0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;
    address public constant SDTOKEN_IMPL =
        0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;
    address public constant RATE_STRATEGY =
        0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;
    
    uint256 public constant LTV = 7500; // 75%
    uint256 public constant LIQ_THRESHOLD = 8000; // 80%
    uint256 public constant RESERVE_FACTOR = 1000; // 10%

    uint256 public constant LIQ_BONUS = 10500; // 5%
    uint256 public constant SUPPLY_CAP = 50_000_000; // 50m MAI
    uint256 public constant LIQ_PROTOCOL_FEE = 1000; // 10%

    uint256 public constant DEBT_CEILING = 2_000_000_00; // 2m (USD denominated)

    uint8 public constant EMODE_CATEGORY = 1; // Stablecoins

    function listAssetAddingOracle()
        external
        withRennounceOfAllAavePermissions(AaveV3Avalanche.ACL_MANAGER)
        withOwnershipBurning
        onlyOwner
    {
        // ----------------------------
        // 1. New price feed on oracle
        // ----------------------------

        require(PRICE_FEED != address(0), 'INVALID_PRICE_FEED');

        address[] memory assets = new address[](1);
        assets[0] = UNDERLYING;
        address[] memory sources = new address[](1);
        sources[0] = PRICE_FEED;

        AaveV3Avalanche.ORACLE.setAssetSources(assets, sources);

        // ------------------------------------------------
        // 2. Listing of MAI, with all its configurations
        // ------------------------------------------------

        ConfiguratorInputTypes.InitReserveInput[]
            memory initReserveInputs = new ConfiguratorInputTypes.InitReserveInput[](
                1
            );
        initReserveInputs[0] = ConfiguratorInputTypes.InitReserveInput({
            aTokenImpl: ATOKEN_IMPL,
            stableDebtTokenImpl: SDTOKEN_IMPL,
            variableDebtTokenImpl: VDTOKEN_IMPL,
            underlyingAssetDecimals: IERC20(UNDERLYING).decimals(),
            interestRateStrategyAddress: RATE_STRATEGY,
            underlyingAsset: UNDERLYING,
            treasury: AAVE_TREASURY,
            incentivesController: INCENTIVES_CONTROLLER,
            aTokenName: ATOKEN_NAME,
            aTokenSymbol: ATOKEN_SYMBOL,
            variableDebtTokenName: VDTOKEN_NAME,
            variableDebtTokenSymbol: VDTOKEN_SYMBOL,
            stableDebtTokenName: SDTOKEN_NAME,
            stableDebtTokenSymbol: SDTOKEN_SYMBOL,
            params: bytes('')
        });

        IPoolConfigurator configurator = AaveV3Avalanche.POOL_CONFIGURATOR;

        configurator.initReserves(initReserveInputs);

        configurator.setSupplyCap(UNDERLYING, SUPPLY_CAP);

        configurator.setDebtCeiling(UNDERLYING, DEBT_CEILING);

        configurator.setReserveBorrowing(UNDERLYING, true);

        configurator.configureReserveAsCollateral(
            UNDERLYING,
            LTV,
            LIQ_THRESHOLD,
            LIQ_BONUS
        );

        configurator.setAssetEModeCategory(UNDERLYING, EMODE_CATEGORY);

        configurator.setReserveFactor(UNDERLYING, RESERVE_FACTOR);

        configurator.setLiquidationProtocolFee(UNDERLYING, LIQ_PROTOCOL_FEE);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPoolConfigurator, ConfiguratorInputTypes, IACLManager} from 'aave-address-book/AaveV3.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {Ownable} from '../dependencies/Ownable.sol';

abstract contract StewardBase is Ownable {
    modifier withRennounceOfAllAavePermissions(IACLManager aclManager) {
        _;

        bytes32[] memory allRoles = getAllAaveRoles();

        for (uint256 i = 0; i < allRoles.length; i++) {
            aclManager.renounceRole(allRoles[i], address(this));
        }
    }

    modifier withOwnershipBurning() {
        _;
        _transferOwnership(address(0));
    }

    function getAllAaveRoles() public pure returns (bytes32[] memory) {
        bytes32[] memory roles = new bytes32[](6);
        roles[
            0
        ] = 0x19c860a63258efbd0ecb7d55c626237bf5c2044c26c073390b74f0c13c857433; // asset listing
        roles[
            1
        ] = 0x08fb31c3e81624356c3314088aa971b73bcc82d22bc3e3b184b4593077ae3278; // bridge
        roles[
            2
        ] = 0x5c91514091af31f62f596a314af7d5be40146b2f2355969392f055e12e0982fb; // emergency admin
        roles[
            3
        ] = 0x939b8dfb57ecef2aea54a93a15e86768b9d4089f1ba61c245e6ec980695f4ca4; // flash borrower
        roles[
            4
        ] = 0x12ad05bde78c5ab75238ce885307f96ecd482bb402ef831f99e7018a0f169b7b; // pool admin
        roles[
            5
        ] = 0x8aa855a911518ecfbe5bc3088c8f3dda7badf130faaf8ace33fdc33828e18167; // risk admin

        return roles;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {AaveV2Ethereum} from "./AaveV2Ethereum.sol";
import {AaveV2EthereumAMM} from "./AaveV2EthereumAMM.sol";
import {AaveV2EthereumArc} from "./AaveV2EthereumArc.sol";
import {AaveV2Mumbai} from "./AaveV2Mumbai.sol";
import {AaveV3Mumbai} from "./AaveV3Mumbai.sol";
import {AaveV2Polygon} from "./AaveV2Polygon.sol";
import {AaveV3Polygon} from "./AaveV3Polygon.sol";
import {AaveV2Fuji} from "./AaveV2Fuji.sol";
import {AaveV3Fuji} from "./AaveV3Fuji.sol";
import {AaveV2Avalanche} from "./AaveV2Avalanche.sol";
import {AaveV3Avalanche} from "./AaveV3Avalanche.sol";
import {AaveV3Arbitrum} from "./AaveV3Arbitrum.sol";
import {AaveV3FantomTestnet} from "./AaveV3FantomTestnet.sol";
import {AaveV3Fantom} from "./AaveV3Fantom.sol";
import {AaveV3HarmonyTestnet} from "./AaveV3HarmonyTestnet.sol";
import {AaveV3Harmony} from "./AaveV3Harmony.sol";
import {AaveV3OptimismKovan} from "./AaveV3OptimismKovan.sol";
import {AaveV3Optimism} from "./AaveV3Optimism.sol";

import {AaveAddressBookV2Testnet} from "./AaveAddressBookV2Testnet.sol";
import {AaveAddressBookV2} from "./AaveAddressBookV2.sol";
import {AaveAddressBookV3Testnet} from "./AaveAddressBookV3Testnet.sol";
import {AaveAddressBookV3} from "./AaveAddressBookV3.sol";

import {Token} from "./Common.sol";
import {AaveGovernanceV2, IGovernanceStrategy} from "./AaveGovernanceV2.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint256 amount;
    uint256 totalPremium;
    uint256 flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    InterestRateMode interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(
    bytes32 indexed id,
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress)
    external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
  event BackUnbacked(
    address indexed reserve,
    address indexed backer,
    uint256 amount,
    uint256 fee
  );

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(
    address indexed reserve,
    address indexed user,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(
    uint8 id,
    DataTypes.EModeCategory memory config
  ) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id)
    external
    view
    returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
    external
    view
    returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

interface IPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing is enabled, false otherwise
   **/
  event ReserveBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled or disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing is enabled, false otherwise
   **/
  event ReserveStableRateBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when a reserve is activated or deactivated
   * @param asset The address of the underlying asset of the reserve
   * @param active True if reserve is active, false otherwise
   **/
  event ReserveActive(address indexed asset, bool active);

  /**
   * @dev Emitted when a reserve is frozen or unfrozen
   * @param asset The address of the underlying asset of the reserve
   * @param frozen True if reserve is frozen, false otherwise
   **/
  event ReserveFrozen(address indexed asset, bool frozen);

  /**
   * @dev Emitted when a reserve is paused or unpaused
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if reserve is paused, false otherwise
   **/
  event ReservePaused(address indexed asset, bool paused);

  /**
   * @dev Emitted when a reserve is dropped.
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDropped(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldReserveFactor The old reserve factor, expressed in bps
   * @param newReserveFactor The new reserve factor, expressed in bps
   **/
  event ReserveFactorChanged(
    address indexed asset,
    uint256 oldReserveFactor,
    uint256 newReserveFactor
  );

  /**
   * @dev Emitted when the borrow cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldBorrowCap The old borrow cap
   * @param newBorrowCap The new borrow cap
   **/
  event BorrowCapChanged(
    address indexed asset,
    uint256 oldBorrowCap,
    uint256 newBorrowCap
  );

  /**
   * @dev Emitted when the supply cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldSupplyCap The old supply cap
   * @param newSupplyCap The new supply cap
   **/
  event SupplyCapChanged(
    address indexed asset,
    uint256 oldSupplyCap,
    uint256 newSupplyCap
  );

  /**
   * @dev Emitted when the liquidation protocol fee of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldFee The old liquidation protocol fee, expressed in bps
   * @param newFee The new liquidation protocol fee, expressed in bps
   **/
  event LiquidationProtocolFeeChanged(
    address indexed asset,
    uint256 oldFee,
    uint256 newFee
  );

  /**
   * @dev Emitted when the unbacked mint cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldUnbackedMintCap The old unbacked mint cap
   * @param newUnbackedMintCap The new unbacked mint cap
   */
  event UnbackedMintCapChanged(
    address indexed asset,
    uint256 oldUnbackedMintCap,
    uint256 newUnbackedMintCap
  );

  /**
   * @dev Emitted when the category of an asset in eMode is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldCategoryId The old eMode asset category
   * @param newCategoryId The new eMode asset category
   **/
  event EModeAssetCategoryChanged(
    address indexed asset,
    uint8 oldCategoryId,
    uint8 newCategoryId
  );

  /**
   * @dev Emitted when a new eMode category is added.
   * @param categoryId The new eMode category id
   * @param ltv The ltv for the asset category in eMode
   * @param liquidationThreshold The liquidationThreshold for the asset category in eMode
   * @param liquidationBonus The liquidationBonus for the asset category in eMode
   * @param oracle The optional address of the price oracle specific for this category
   * @param label A human readable identifier for the category
   **/
  event EModeCategoryAdded(
    uint8 indexed categoryId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    address oracle,
    string label
  );

  /**
   * @dev Emitted when a reserve interest strategy contract is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldStrategy The address of the old interest strategy contract
   * @param newStrategy The address of the new interest strategy contract
   **/
  event ReserveInterestRateStrategyChanged(
    address indexed asset,
    address oldStrategy,
    address newStrategy
  );

  /**
   * @dev Emitted when an aToken implementation is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   **/
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the debt ceiling of an asset is set.
   * @param asset The address of the underlying asset of the reserve
   * @param oldDebtCeiling The old debt ceiling
   * @param newDebtCeiling The new debt ceiling
   **/
  event DebtCeilingChanged(
    address indexed asset,
    uint256 oldDebtCeiling,
    uint256 newDebtCeiling
  );

  /**
   * @dev Emitted when the the siloed borrowing state for an asset is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldState The old siloed borrowing state
   * @param newState The new siloed borrowing state
   **/
  event SiloedBorrowingChanged(
    address indexed asset,
    bool oldState,
    bool newState
  );

  /**
   * @dev Emitted when the bridge protocol fee is updated.
   * @param oldBridgeProtocolFee The old protocol fee, expressed in bps
   * @param newBridgeProtocolFee The new protocol fee, expressed in bps
   */
  event BridgeProtocolFeeUpdated(
    uint256 oldBridgeProtocolFee,
    uint256 newBridgeProtocolFee
  );

  /**
   * @dev Emitted when the total premium on flashloans is updated.
   * @param oldFlashloanPremiumTotal The old premium, expressed in bps
   * @param newFlashloanPremiumTotal The new premium, expressed in bps
   **/
  event FlashloanPremiumTotalUpdated(
    uint128 oldFlashloanPremiumTotal,
    uint128 newFlashloanPremiumTotal
  );

  /**
   * @dev Emitted when the part of the premium that goes to protocol is updated.
   * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
   * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
   **/
  event FlashloanPremiumToProtocolUpdated(
    uint128 oldFlashloanPremiumToProtocol,
    uint128 newFlashloanPremiumToProtocol
  );

  /**
   * @dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the reserve is borrowable in isolation, false otherwise
   **/
  event BorrowableInIsolationChanged(address asset, bool borrowable);

  /**
   * @notice Initializes multiple reserves.
   * @param input The array of initialization parameters
   **/
  function initReserves(
    ConfiguratorInputTypes.InitReserveInput[] calldata input
  ) external;

  /**
   * @dev Updates the aToken implementation for the reserve.
   * @param input The aToken update parameters
   **/
  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input)
    external;

  /**
   * @notice Updates the stable debt token implementation for the reserve.
   * @param input The stableDebtToken update parameters
   **/
  function updateStableDebtToken(
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) external;

  /**
   * @notice Updates the variable debt token implementation for the asset.
   * @param input The variableDebtToken update parameters
   **/
  function updateVariableDebtToken(
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) external;

  /**
   * @notice Configures borrowing on a reserve.
   * @dev Can only be disabled (set to false) if stable borrowing is disabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing needs to be enabled, false otherwise
   **/
  function setReserveBorrowing(address asset, bool enabled) external;

  /**
   * @notice Configures the reserve collateralization parameters.
   * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
   * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @notice Enable or disable stable rate borrowing on a reserve.
   * @dev Can only be enabled (set to true) if borrowing is enabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing needs to be enabled, false otherwise
   **/
  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  /**
   * @notice Activate or deactivate a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param active True if the reserve needs to be active, false otherwise
   **/
  function setReserveActive(address asset, bool active) external;

  /**
   * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
   * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
   * @param asset The address of the underlying asset of the reserve
   * @param freeze True if the reserve needs to be frozen, false otherwise
   **/
  function setReserveFreeze(address asset, bool freeze) external;

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
   * borrowed amount will be accumulated in the isolated collateral's total debt exposure
   * @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the asset should be borrowable in isolation, false otherwise
   **/
  function setBorrowableInIsolation(address asset, bool borrowable) external;

  /**
   * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
   * swap interest rate, liquidate, atoken transfers).
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if pausing the reserve, false if unpausing
   **/
  function setReservePause(address asset, bool paused) external;

  /**
   * @notice Updates the reserve factor of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newReserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 newReserveFactor) external;

  /**
   * @notice Sets the interest rate strategy of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newRateStrategyAddress The address of the new interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address newRateStrategyAddress
  ) external;

  /**
   * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
   * are suspended.
   * @param paused True if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool paused) external;

  /**
   * @notice Updates the borrow cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newBorrowCap The new borrow cap of the reserve
   **/
  function setBorrowCap(address asset, uint256 newBorrowCap) external;

  /**
   * @notice Updates the supply cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newSupplyCap The new supply cap of the reserve
   **/
  function setSupplyCap(address asset, uint256 newSupplyCap) external;

  /**
   * @notice Updates the liquidation protocol fee of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
   **/
  function setLiquidationProtocolFee(address asset, uint256 newFee) external;

  /**
   * @notice Updates the unbacked mint cap of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newUnbackedMintCap The new unbacked mint cap of the reserve
   **/
  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap)
    external;

  /**
   * @notice Assign an efficiency mode (eMode) category to asset.
   * @param asset The address of the underlying asset of the reserve
   * @param newCategoryId The new category id of the asset
   **/
  function setAssetEModeCategory(address asset, uint8 newCategoryId) external;

  /**
   * @notice Adds a new efficiency mode (eMode) category.
   * @dev If zero is provided as oracle address, the default asset oracles will be used to compute the overall debt and
   * overcollateralization of the users using this category.
   * @dev The new ltv and liquidation threshold must be greater than the base
   * ltvs and liquidation thresholds of all assets within the eMode category
   * @param categoryId The id of the category to be configured
   * @param ltv The ltv associated with the category
   * @param liquidationThreshold The liquidation threshold associated with the category
   * @param liquidationBonus The liquidation bonus associated with the category
   * @param oracle The oracle associated with the category
   * @param label A label identifying the category
   **/
  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
    address oracle,
    string calldata label
  ) external;

  /**
   * @notice Drops a reserve entirely.
   * @param asset The address of the reserve to drop
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the bridge fee collected by the protocol reserves.
   * @param newBridgeProtocolFee The part of the fee sent to the protocol treasury, expressed in bps
   */
  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external;

  /**
   * @notice Updates the total flash loan premium.
   * Total flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra balance
   * - A part is collected by the protocol reserves
   * @dev Expressed in bps
   * @dev The premium is calculated on the total amount borrowed
   * @param newFlashloanPremiumTotal The total flashloan premium
   */
  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal)
    external;

  /**
   * @notice Updates the flash loan premium collected by protocol reserves
   * @dev Expressed in bps
   * @dev The premium to protocol is calculated on the total flashloan premium
   * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
   */
  function updateFlashloanPremiumToProtocol(
    uint128 newFlashloanPremiumToProtocol
  ) external;

  /**
   * @notice Sets the debt ceiling for an asset.
   * @param newDebtCeiling The new debt ceiling
   */
  function setDebtCeiling(address asset, uint256 newDebtCeiling) external;

  /**
   * @notice Sets siloed borrowing for an asset
   * @param siloed The new siloed borrowing state
   */
  function setSiloedBorrowing(address asset, bool siloed) external;
}

interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   **/
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   **/
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

interface IAaveOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
  function setAssetSources(
    address[] calldata assets,
    address[] calldata sources
  ) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets)
    external
    view
    returns (uint256[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);
}

struct TokenData {
  string symbol;
  address tokenAddress;
}

// TODO: add better documentation
interface IAaveProtocolDataProvider {
  
  function getAllReservesTokens() external view returns (TokenData[] memory);

  function getAllATokens() external view returns (TokenData[] memory);

  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getReserveEModeCategory(address asset)
    external
    view
    returns (uint256);

  function getReserveCaps(address asset)
    external
    view
    returns (uint256 borrowCap, uint256 supplyCap);

  function getPaused(address asset) external view returns (bool isPaused);

  function getSiloedBorrowing(address asset) external view returns (bool);

  function getLiquidationProtocolFee(address asset)
    external
    view
    returns (uint256);

  function getUnbackedMintCap(address asset) external view returns (uint256);

  function getDebtCeiling(address asset) external view returns (uint256);

  function getDebtCeilingDecimals() external pure returns (uint256);

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   **/
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   **/
  function getTotalDebt(address asset) external view returns (uint256);

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );
  
    function getInterestRateStrategyAddress(address asset)
      external
      view
      returns (address irStrategyAddress);
}

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Bridge role
   * @return The id of the Bridge role
   */
  function BRIDGE_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an admin as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  // Parent Access Control Interface
  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {AccessControl-_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been granted `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;
}

interface IInterestRateStrategy {
  /**
   * @dev This constant represents the usage ratio at which the pool aims to obtain most competitive borrow rates.
   * Expressed in ray
   */
  function OPTIMAL_USAGE_RATIO() external view returns (uint256);

  /**
   * @dev This constant represents the optimal stable debt to total debt ratio of the reserve.
   * Expressed in ray
   */
  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @dev This constant represents the excess usage ratio above the optimal. It's always equal to
   * 1-optimal usage ratio. Added as a constant here for gas optimizations.
   * Expressed in ray
   */
  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

  /**
   * @dev This constant represents the excess stable debt ratio above the optimal. It's always equal to
   * 1-optimal stable to total debt ratio. Added as a constant here for gas optimizations.
   * Expressed in ray
   */
  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the variable rate slope below optimal usage ratio
   * @dev Its the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The variable rate slope
   */
  function getVariableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the variable rate slope above optimal usage ratio
   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The variable rate slope
   */
  function getVariableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope below optimal usage ratio
   * @dev Its the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The stable rate slope
   */
  function getStableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope above optimal usage ratio
   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The stable rate slope
   */
  function getStableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate excess offset
   * @dev An additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
   * @return The stable rate excess offset
   */
  function getStableRateExcessOffset() external view returns (uint256);

  /**
   * @notice Returns the base stable borrow rate
   * @return The base stable borrow rate
   */
  function getBaseStableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the base variable borrow rate
   * @return The base variable borrow rate, expressed in ray
   */
  function getBaseVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the maximum variable borrow rate
   * @return The maximum variable borrow rate, expressed in ray
   */
  function getMaxVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Calculates the interest rates depending on the reserve's state and configurations
   * @param params The parameters needed to calculate interest rates
   * @return liquidityRate The liquidity rate expressed in rays
   * @return stableBorrowRate The stable borrow rate expressed in rays
   * @return variableBorrowRate The variable borrow rate expressed in rays
   */
  function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the decimals of the token
     */
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _transferOwnership(msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
            'Ownable: new owner is the zero address'
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveV2Ethereum {
    ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );

    ILendingPool internal constant POOL =
        ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
        ILendingPoolConfigurator(0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    address internal constant POOL_ADMIN =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    address internal constant EMERGENCY_ADMIN =
        0xCA76Ebd8617a03126B6FB84F9b1c1A0fB71C2633;

    address internal constant COLLECTOR =
        0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    address internal constant COLLECTOR_CONTROLLER =
        0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDT")))
        ) {
            return
                Token(
                    0xdAC17F958D2ee523a2206206994597C13D831ec7,
                    0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811,
                    0xe91D55AB2240594855aBd11b3faAE801Fd4c4687,
                    0x531842cEbbdD378f8ee36D171d6cC9C4fcf475Ec
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WBTC")))
        ) {
            return
                Token(
                    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
                    0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656,
                    0x51B039b9AFE64B78758f8Ef091211b5387eA717c,
                    0x9c39809Dec7F95F5e0713634a4D0701329B3b4d2
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WETH")))
        ) {
            return
                Token(
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                    0x030bA81f1c18d280636F32af80b9AAd02Cf0854e,
                    0x4e977830ba4bd783C0BB7F15d3e243f73FF57121,
                    0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("YFI")))
        ) {
            return
                Token(
                    0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
                    0x5165d24277cD063F5ac44Efd447B27025e888f37,
                    0xca823F78C2Dd38993284bb42Ba9b14152082F7BD,
                    0x7EbD09022Be45AD993BAA1CEc61166Fcc8644d97
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("ZRX")))
        ) {
            return
                Token(
                    0xE41d2489571d322189246DaFA5ebDe1F4699F498,
                    0xDf7FF54aAcAcbFf42dfe29DD6144A69b629f8C9e,
                    0x071B4323a24E73A5afeEbe34118Cd21B8FAAF7C3,
                    0x85791D117A392097590bDeD3bD5abB8d5A20491A
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI")))
        ) {
            return
                Token(
                    0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
                    0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1,
                    0xD939F7430dC8D5a427f156dE1012A56C18AcB6Aa,
                    0x5BdB050A92CADcCfCDcCCBFC17204a1C9cC0Ab73
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("AAVE")))
        ) {
            return
                Token(
                    0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
                    0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B,
                    0x079D6a3E844BcECf5720478A718Edb6575362C5f,
                    0xF7DBA49d571745D9d7fcb56225B05BEA803EBf3C
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("BAT")))
        ) {
            return
                Token(
                    0x0D8775F648430679A709E98d2b0Cb6250d2887EF,
                    0x05Ec93c0365baAeAbF7AefFb0972ea7ECdD39CF1,
                    0x277f8676FAcf4dAA5a6EA38ba511B7F65AA02f9F,
                    0xfc218A6Dfe6901CB34B1a5281FC6f1b8e7E56877
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("BUSD")))
        ) {
            return
                Token(
                    0x4Fabb145d64652a948d72533023f6E7A623C7C53,
                    0xA361718326c15715591c299427c62086F69923D9,
                    0x4A7A63909A72D268b1D8a93a9395d098688e0e5C,
                    0xbA429f7011c9fa04cDd46a2Da24dc0FF0aC6099c
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("DAI")))
        ) {
            return
                Token(
                    0x6B175474E89094C44Da98b954EedeAC495271d0F,
                    0x028171bCA77440897B824Ca71D1c56caC55b68A3,
                    0x778A13D3eeb110A4f7bb6529F99c000119a08E92,
                    0x6C3c78838c761c6Ac7bE9F59fe808ea2A6E4379d
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("ENJ")))
        ) {
            return
                Token(
                    0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c,
                    0xaC6Df26a590F08dcC95D5a4705ae8abbc88509Ef,
                    0x943DcCA156b5312Aa24c1a08769D67FEce4ac14C,
                    0x38995F292a6E31b78203254fE1cdd5Ca1010A446
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("KNC")))
        ) {
            return
                Token(
                    0xdd974D5C2e2928deA5F71b9825b8b646686BD200,
                    0x39C6b3e42d6A679d7D776778Fe880BC9487C2EDA,
                    0x9915dfb872778B2890a117DA1F35F335eb06B54f,
                    0x6B05D1c608015Ccb8e205A690cB86773A96F39f1
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("LINK")))
        ) {
            return
                Token(
                    0x514910771AF9Ca656af840dff83E8264EcF986CA,
                    0xa06bC25B5805d5F8d82847D191Cb4Af5A3e873E0,
                    0xFB4AEc4Cc858F2539EBd3D37f2a43eAe5b15b98a,
                    0x0b8f12b1788BFdE65Aa1ca52E3e9F3Ba401be16D
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("MANA")))
        ) {
            return
                Token(
                    0x0F5D2fB29fb7d3CFeE444a200298f468908cC942,
                    0xa685a61171bb30d4072B338c80Cb7b2c865c873E,
                    0xD86C74eA2224f4B8591560652b50035E4e5c0a3b,
                    0x0A68976301e46Ca6Ce7410DB28883E309EA0D352
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("MKR")))
        ) {
            return
                Token(
                    0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
                    0xc713e5E149D5D0715DcD1c156a020976e7E56B88,
                    0xC01C8E4b12a89456a9fD4e4e75B72546Bf53f0B5,
                    0xba728eAd5e496BE00DCF66F650b6d7758eCB50f8
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("REN")))
        ) {
            return
                Token(
                    0x408e41876cCCDC0F92210600ef50372656052a38,
                    0xCC12AbE4ff81c9378D670De1b57F8e0Dd228D77a,
                    0x3356Ec1eFA75d9D150Da1EC7d944D9EDf73703B7,
                    0xcd9D82d33bd737De215cDac57FE2F7f04DF77FE0
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("SNX")))
        ) {
            return
                Token(
                    0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
                    0x35f6B052C598d933D69A4EEC4D04c73A191fE6c2,
                    0x8575c8ae70bDB71606A53AeA1c6789cB0fBF3166,
                    0x267EB8Cf715455517F9BD5834AeAE3CeA1EBdbD8
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("sUSD")))
        ) {
            return
                Token(
                    0x57Ab1ec28D129707052df4dF418D58a2D46d5f51,
                    0x6C5024Cd4F8A59110119C56f8933403A539555EB,
                    0x30B0f7324feDF89d8eff397275F8983397eFe4af,
                    0xdC6a3Ab17299D9C2A412B0e0a4C1f55446AE0817
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("TUSD")))
        ) {
            return
                Token(
                    0x0000000000085d4780B73119b644AE5ecd22b376,
                    0x101cc05f4A51C0319f570d5E146a8C625198e636,
                    0x7f38d60D94652072b2C44a18c0e14A481EC3C0dd,
                    0x01C0eb1f8c6F1C1bF74ae028697ce7AA2a8b0E92
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDC")))
        ) {
            return
                Token(
                    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                    0xBcca60bB61934080951369a648Fb03DF4F96263C,
                    0xE4922afAB0BbaDd8ab2a88E0C79d884Ad337fcA6,
                    0x619beb58998eD2278e08620f97007e1116D5D25b
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("CRV")))
        ) {
            return
                Token(
                    0xD533a949740bb3306d119CC777fa900bA034cd52,
                    0x8dAE6Cb04688C62d939ed9B68d32Bc62e49970b1,
                    0x9288059a74f589C919c7Cf1Db433251CdFEB874B,
                    0x00ad8eBF64F141f1C81e9f8f792d3d1631c6c684
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("GUSD")))
        ) {
            return
                Token(
                    0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd,
                    0xD37EE7e4f452C6638c96536e68090De8cBcdb583,
                    0xf8aC64ec6Ff8E0028b37EB89772d21865321bCe0,
                    0x279AF5b99540c1A3A7E3CDd326e19659401eF99e
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("BAL")))
        ) {
            return
                Token(
                    0xba100000625a3754423978a60c9317c58a424e3D,
                    0x272F97b7a56a387aE942350bBC7Df5700f8a4576,
                    0xe569d31590307d05DA3812964F1eDd551D665a0b,
                    0x13210D4Fe0d5402bd7Ecbc4B5bC5cFcA3b71adB0
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("xSUSHI")))
        ) {
            return
                Token(
                    0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272,
                    0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a,
                    0x73Bfb81D7dbA75C904f430eA8BAe82DB0D41187B,
                    0xfAFEDF95E21184E3d880bd56D4806c4b8d31c69A
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("renFIL")))
        ) {
            return
                Token(
                    0xD5147bc8e386d91Cc5DBE72099DAC6C9b99276F5,
                    0x514cd6756CCBe28772d4Cb81bC3156BA9d1744aa,
                    0xcAad05C49E14075077915cB5C820EB3245aFb950,
                    0x348e2eBD5E962854871874E444F4122399c02755
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("RAI")))
        ) {
            return
                Token(
                    0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919,
                    0xc9BC48c72154ef3e5425641a3c747242112a46AF,
                    0x9C72B8476C33AE214ee3e8C20F0bc28496a62032,
                    0xB5385132EE8321977FfF44b60cDE9fE9AB0B4e6b
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("AMPL")))
        ) {
            return
                Token(
                    0xD46bA6D942050d489DBd938a2C909A5d5039A161,
                    0x1E6bb68Acec8fefBD87D192bE09bb274170a0548,
                    0x18152C9f77DAdc737006e9430dB913159645fa87,
                    0xf013D90E4e4E3Baf420dFea60735e75dbd42f1e1
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDP")))
        ) {
            return
                Token(
                    0x8E870D67F660D95d5be530380D0eC0bd388289E1,
                    0x2e8F4bdbE3d47d7d7DE490437AeA9915D930F1A3,
                    0x2387119bc85A74e0BBcbe190d80676CB16F10D4F,
                    0xFDb93B3b10936cf81FA59A02A7523B6e2149b2B7
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("DPI")))
        ) {
            return
                Token(
                    0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b,
                    0x6F634c6135D2EBD550000ac92F494F9CB8183dAe,
                    0xa3953F07f389d719F99FC378ebDb9276177d8A6e,
                    0x4dDff5885a67E4EffeC55875a3977D7E60F82ae0
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("FRAX")))
        ) {
            return
                Token(
                    0x853d955aCEf822Db058eb8505911ED77F175b99e,
                    0xd4937682df3C8aEF4FE912A96A74121C0829E664,
                    0x3916e3B6c84b161df1b2733dFfc9569a1dA710c2,
                    0xfE8F19B17fFeF0fDbfe2671F248903055AFAA8Ca
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("FEI")))
        ) {
            return
                Token(
                    0x956F47F50A910163D8BF957Cf5846D573E7f87CA,
                    0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3,
                    0xd89cF9E8A858F8B4b31Faf793505e112d6c17449,
                    0xC2e10006AccAb7B45D9184FcF5b7EC7763f5BaAe
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("stETH")))
        ) {
            return
                Token(
                    0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
                    0x1982b2F5814301d4e9a8b0201555376e62F82428,
                    0x66457616Dd8489dF5D0AFD8678F4A260088aAF55,
                    0xA9DEAc9f00Dc4310c35603FCD9D34d1A750f81Db
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("ENS")))
        ) {
            return
                Token(
                    0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72,
                    0x9a14e23A58edf4EFDcB360f68cd1b95ce2081a2F,
                    0x34441FFD1948E49dC7a607882D0c38Efd0083815,
                    0x176808047cc9b7A2C9AE202c593ED42dDD7C0D13
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UST")))
        ) {
            return
                Token(
                    0xa693B19d2931d498c5B318dF961919BB4aee87a5,
                    0xc2e2152647F4C26028482Efaf64b2Aa28779EFC4,
                    0x7FDbfB0412700D94403c42cA3CAEeeA183F07B26,
                    0xaf32001cf2E66C4C3af4205F6EA77112AA4160FE
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("CVX")))
        ) {
            return
                Token(
                    0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B,
                    0x952749E07d7157bb9644A894dFAF3Bad5eF6D918,
                    0xB01Eb1cE1Da06179136D561766fc2d609C5F55Eb,
                    0x4Ae5E4409C6Dbc84A00f9f89e4ba096603fb7d50
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveV2EthereumAMM {
    ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0xAcc030EF66f9dFEAE9CbB0cd1B25654b82cFA8d5
        );

    ILendingPool internal constant POOL =
        ILendingPool(0x7937D4799803FbBe595ed57278Bc4cA21f3bFfCB);

    ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
        ILendingPoolConfigurator(0x23A875eDe3F1030138701683e42E9b16A7F87768);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x0000000000000000000000000000000000000000);

    address internal constant POOL_ADMIN =
        0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

    address internal constant EMERGENCY_ADMIN =
        0xB9062896ec3A615a4e4444DF183F0531a77218AE;

    address internal constant COLLECTOR =
        0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    address internal constant COLLECTOR_CONTROLLER =
        0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WETH")))
        ) {
            return
                Token(
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                    0xf9Fb4AD91812b704Ba883B11d2B576E890a6730A,
                    0x118Ee405c6be8f9BA7cC7a98064EB5DA462235CF,
                    0xA4C273d9A0C1fe2674F0E845160d6232768a3064
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("DAI")))
        ) {
            return
                Token(
                    0x6B175474E89094C44Da98b954EedeAC495271d0F,
                    0x79bE75FFC64DD58e66787E4Eae470c8a1FD08ba4,
                    0x8da51a5a3129343468a63A96ccae1ff1352a3dfE,
                    0x3F4fA4937E72991367DC32687BC3278f095E7EAa
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDC")))
        ) {
            return
                Token(
                    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                    0xd24946147829DEaA935bE2aD85A3291dbf109c80,
                    0xE5971a8a741892F3b3ac3E9c94d02588190cE220,
                    0xCFDC74b97b69319683fec2A4Ef95c4Ab739F1B12
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDT")))
        ) {
            return
                Token(
                    0xdAC17F958D2ee523a2206206994597C13D831ec7,
                    0x17a79792Fe6fE5C95dFE95Fe3fCEE3CAf4fE4Cb7,
                    0x04A0577a89E1b9E8f6c87ee26cCe6a168fFfC5b5,
                    0xDcFE9BfC246b02Da384de757464a35eFCa402797
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WBTC")))
        ) {
            return
                Token(
                    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
                    0x13B2f6928D7204328b0E8E4BCd0379aA06EA21FA,
                    0x55E575d092c934503D7635A837584E2900e01d2b,
                    0x3b99fdaFdfE70d65101a4ba8cDC35dAFbD26375f
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11,
                    0x9303EabC860a743aABcc3A1629014CaBcc3F8D36,
                    0xE9562bf0A11315A1e39f9182F446eA58002f010E,
                    0x23bcc861b989762275165d08B127911F09c71628
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xBb2b8038a1640196FbE3e38816F3e67Cba72D940,
                    0xc58F53A8adff2fB4eb16ED56635772075E2EE123,
                    0xeef7d082D9bE2F5eC73C072228706286dea1f492,
                    0x02aAeB4C7736177242Ee0f71f6f6A0F057Aba87d
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f,
                    0xe59d2FF6995a926A574390824a657eEd36801E55,
                    0x997b26eFf106f138e71160022CaAb0AFC5814643,
                    0x859ED7D9E92d1fe42fF95C3BC3a62F7cB59C373E
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xB6909B960DbbE7392D405429eB2b3649752b4838,
                    0xA1B0edF4460CC4d8bFAA18Ed871bFF15E5b57Eb4,
                    0x27c67541a4ea26a436e311b2E6fFeC82083a6983,
                    0x3Fbef89A21Dc836275bC912849627b33c61b09b4
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5,
                    0xE340B25fE32B1011616bb8EC495A4d503e322177,
                    0x6Bb2BdD21920FcB2Ad855AB5d523222F31709d1f,
                    0x925E3FDd927E20e33C3177C4ff6fb72aD1133C87
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0x3dA1313aE46132A397D90d95B1424A9A7e3e0fCE,
                    0x0ea20e7fFB006d4Cfe84df2F72d8c7bD89247DB0,
                    0xd6035f8803eE9f173b1D3EBc3BDE0Ea6B5165636,
                    0xF3f1a76cA6356a908CdCdE6b2AC2eaace3739Cd0
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974,
                    0xb8db81B84d30E2387de0FF330420A4AAA6688134,
                    0xeb32b3A1De9a1915D2b452B673C53883b9Fa6a97,
                    0xeDe4052ed8e1F422F4E5062c679f6B18693fEcdc
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xC2aDdA861F89bBB333c90c492cB837741916A225,
                    0x370adc71f67f581158Dc56f539dF5F399128Ddf9,
                    0x6E7E38bB73E19b62AB5567940Caaa514e9d85982,
                    0xf36C394775285F89bBBDF09533421E3e81e8447c
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0x8Bd1661Da98EBDd3BD080F0bE4e6d9bE8cE9858c,
                    0xA9e201A4e269d6cd5E9F0FcbcB78520cf815878B,
                    0x312edeADf68E69A0f53518bF27EAcD1AbcC2897e,
                    0x2A8d5B1c1de15bfcd5EC41368C0295c60D8Da83c
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0x43AE24960e5534731Fc831386c07755A2dc33D47,
                    0x38E491A71291CD43E8DE63b7253E482622184894,
                    0xef62A0C391D89381ddf8A8C90Ba772081107D287,
                    0xfd15008efA339A2390B48d2E0Ca8Abd523b406d3
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xd3d2E2692501A5c9Ca623199D38826e513033a17,
                    0x3D26dcd840fCC8e4B2193AcE8A092e4a65832F9f,
                    0x6febCE732191Dc915D6fB7Dc5FE3AEFDDb85Bd1B,
                    0x0D878FbB01fbEEa7ddEFb896d56f1D3167af919F
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc,
                    0x391E86e2C002C70dEe155eAceB88F7A3c38f5976,
                    0xfAB4C9775A4316Ec67a8223ecD0F70F87fF532Fc,
                    0x26625d1dDf520fC8D975cc68eC6E0391D9d3Df61
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0x004375Dff511095CC5A197A54140a24eFEF3A416,
                    0x2365a4890eD8965E564B7E2D27C38Ba67Fec4C6F,
                    0xc66bfA05cCe646f05F71DeE333e3229cE24Bbb7e,
                    0x36dA0C5dC23397CBf9D13BbD74E93C04f99633Af
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("UNI-V2")))
        ) {
            return
                Token(
                    0x2fDbAdf3C4D5A8666Bc06645B8358ab803996E28,
                    0x5394794Be8b6eD5572FCd6b27103F46b5F390E8f,
                    0x9B054B76d6DE1c4892ba025456A9c4F9be5B1766,
                    0xDf70Bdf01a3eBcd0D918FF97390852A914a92Df7
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("BPT")))
        ) {
            return
                Token(
                    0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5,
                    0x358bD0d980E031E23ebA9AA793926857703783BD,
                    0x46406eCd20FDE1DF4d80F15F07c434fa95CB6b33,
                    0xF655DF3832859cfB0AcfD88eDff3452b9Aa6Db24
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("BPT")))
        ) {
            return
                Token(
                    0x59A19D8c652FA0284f44113D0ff9aBa70bd46fB4,
                    0xd109b2A304587569c84308c55465cd9fF0317bFB,
                    0x6474d116476b8eDa1B21472a599Ff76A829AbCbb,
                    0xF41A5Cc7a61519B08056176d7B4b87AB34dF55AD
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("G-UNI")))
        ) {
            return
                Token(
                    0x50379f632ca68D36E50cfBC8F78fe16bd1499d1e,
                    0xd145c6ae8931ed5Bca9b5f5B7dA5991F5aB63B5c,
                    0x460Fd61bBDe7235C3F345901ad677854c9330c86,
                    0x40533CC601Ec5b79B00D76348ADc0c81d93d926D
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("G-UNI")))
        ) {
            return
                Token(
                    0xD2eeC91055F07fE24C9cCB25828ecfEFd4be0c41,
                    0xCa5DFDABBfFD58cfD49A9f78Ca52eC8e0591a3C5,
                    0xFEaeCde9Eb0cd43FDE13427C6C7ef406780a8136,
                    0x0B7c7d9c5548A23D0455d1edeC541cc2AD955a9d
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveV2EthereumArc {
    ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0x6FdfafB66d39cD72CFE7984D3Bbcc76632faAb00
        );

    ILendingPool internal constant POOL =
        ILendingPool(0x37D7306019a38Af123e4b245Eb6C28AF552e0bB0);

    ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
        ILendingPoolConfigurator(0x4e1c7865e7BE78A7748724Fa0409e88dc14E67aA);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xB8a7bc0d13B1f5460513040a97F404b4fea7D2f3);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x71B53fC437cCD988b1b89B1D4605c3c3d0C810ea);

    address internal constant POOL_ADMIN =
        0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218;

    address internal constant EMERGENCY_ADMIN =
        0x33B09130b035d6D7e57d76fEa0873d9545FA7557;

    address internal constant COLLECTOR =
        0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    address internal constant COLLECTOR_CONTROLLER =
        0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDC")))
        ) {
            return
                Token(
                    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                    0xd35f648C3C7f17cd1Ba92e5eac991E3EfcD4566d,
                    0x2a278CDA70D2Fa3eC52B50D9cB84a309CE13A308,
                    0xe8D876034F96081063cD57Cd87b94a156b4E03E1
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WBTC")))
        ) {
            return
                Token(
                    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
                    0xe6d6E7dA65A2C18109Ff56B7CBBdc7B706Fc13F8,
                    0x8975Aa9d57a40796001Ae98d8C54336cA7Ebe7f1,
                    0xc371FB4513c23Fc962fe23B12cFBD75E1D37ED91
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WETH")))
        ) {
            return
                Token(
                    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                    0x319190E3Bbc595602A9E63B2bCfB61c6634355b1,
                    0x1c2921BA94b8C15daa8458905460B70e41127296,
                    0x932167279A4ed3b879bA7eDdC85Aa83551f3989D
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("AAVE")))
        ) {
            return
                Token(
                    0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
                    0x89eFaC495C65d43619c661df654ec64fc10C0A75,
                    0x5166F949e8658d743D5b9fb1c5c61CDFd6398058,
                    0x0ac4c7790BC96923b71BfCee44a6923fd085E0c8
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveV2Mumbai {
    ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0x178113104fEcbcD7fF8669a0150721e231F0FD4B
        );

    ILendingPool internal constant POOL =
        ILendingPool(0x9198F13B08E299d85E096929fA9781A1E3d5d827);

    ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
        ILendingPoolConfigurator(0xc3c37E2aA3dc66464fa3C29ce2a6EC85beFC45e1);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xC365C653f7229894F93994CD0b30947Ab69Ff1D5);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0xFA3bD19110d986c5e5E9DD5F69362d05035D045B);

    address internal constant POOL_ADMIN =
        0x943E44157dC0302a5CEb172374d1749018a00994;

    address internal constant EMERGENCY_ADMIN =
        0x943E44157dC0302a5CEb172374d1749018a00994;

    address internal constant COLLECTOR =
        0x943E44157dC0302a5CEb172374d1749018a00994;

    address internal constant COLLECTOR_CONTROLLER = address(0);

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("DAI")))
        ) {
            return
                Token(
                    0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F,
                    0x639cB7b21ee2161DF9c882483C9D55c90c20Ca3e,
                    0x10dec6dF64d0ebD271c8AdD492Af4F5594358919,
                    0x6D29322ba6549B95e98E9B08033F5ffb857f19c5
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDC")))
        ) {
            return
                Token(
                    0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e,
                    0x2271e3Fef9e15046d09E1d78a8FF038c691E9Cf9,
                    0x83A7bC369cFd55D9F00267318b6D221fb9Fa739F,
                    0x05771A896327ee702F965FB6E4A35A9A57C84a2a
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDT")))
        ) {
            return
                Token(
                    0xBD21A10F619BE90d6066c941b04e340841F1F989,
                    0xF8744C0bD8C7adeA522d6DDE2298b17284A79D1b,
                    0xdD250d4e7ff5f7414F3EBe8fcBbB13583191BDaC,
                    0x6C0a86573a63672D8a66C037036e441A59086d68
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WBTC")))
        ) {
            return
                Token(
                    0x0d787a4a1548f673ed375445535a6c7A1EE56180,
                    0xc9276ECa6798A14f64eC33a526b547DAd50bDa2F,
                    0x29A36d45e8d9f446EC9529b28907bc850B398154,
                    0xc156967272b7177DcE40E3b3E7c4269f750F3160
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WETH")))
        ) {
            return
                Token(
                    0x3C68CE8504087f89c640D02d133646d98e64ddd9,
                    0x7aE20397Ca327721F013BB9e140C707F82871b56,
                    0x35D88812d32b966da90db9F546fbf43553C4F35b,
                    0x0F2656e068b77cdA65213Ef25705B728d5C73340
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WMATIC")))
        ) {
            return
                Token(
                    0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889,
                    0xF45444171435d0aCB08a8af493837eF18e86EE27,
                    0xfeedbD76ac61616f270911CCaBb43a36380f40ae,
                    0x11b884339E453E3d66A8E22246782D40E62cB5F2
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("AAVE")))
        ) {
            return
                Token(
                    0x341d1f30e77D3FBfbD43D17183E2acb9dF25574E,
                    0x7ec62b6fC19174255335C8f4346E0C2fcf870a6B,
                    0x14bD9790e15294608Df4160dcF45B64adBFdCBaA,
                    0x5A6659794E3Fe10eee90833B36a4819953AaB9A1
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Mumbai {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6);

    IPool internal constant POOL =
        IPool(0x6C9fB0D5bD9429eb9Cd96B85B81d872281771E6B);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x7b47e727eC539CB74A744ae5259ef26743294fca);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0x520D14AE678b41067f029Ad770E2870F85E76588);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x8f57153F18b7273f9A814b93b31Cb3f9b035e7C2);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0x6437b6E14D7ECa1Fa9854df92eB067253D5f683A);

    address internal constant ACL_ADMIN =
        0x77c45699A715A64A7a7796d5CEe884cf617D5254;

    address internal constant COLLECTOR =
        0x3B6E7a4750e478D7f7d6A5d464099A02ef164bCC;

    address internal constant COLLECTOR_CONTROLLER =
        0x810d913542D399F3680F0E806DEDf6EACf0e3383;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0x9A753f0F7886C9fbF63cF59D0D4423C5eFaCE95B,
                    0xDD4f3Ee61466C4158D394d57f3D4C397E91fBc51,
                    0x333C04243D048836d53b4ACB3c9aE64875699375,
                    0xB18041Ce2439774c4c7BF611a2a635824cE99032
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0xD9E7e5dd6e122dDE11244e14A60f38AbA93097f2,
                    0x3e1608F4Db4b37DDf86536ef441890fE3AA9F2Ea,
                    0x27908f7216Efe649706B68b6a443623D9aaF16D0,
                    0x292f1Cc1BcedCd22E860c7C92D21877774B44C16
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2,
                    0xCdc2854e97798AfDC74BC420BD5060e022D14607,
                    0x01dBEdcb2437c79341cfeC4Cae765C53BE0E6EF7,
                    0xA24A380813FB7E283Acb8221F5E1e3C01052Bc93
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0x85E44420b6137bbc75a85CAB5c9A3371af976FdE,
                    0xde230bC95a03b695be69C44b9AA6C0e9dAc1B143,
                    0x5BcBF666e14eCFe6e21686601c5cA7c7fbe674Cf,
                    0xFDf3B7af2Cb32E5ADca11cf54d53D02162e8d622
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0xd575d4047f8c667E064a4ad433D04E25187F40BB,
                    0x685bF4eab23993E94b4CFb9383599c926B66cF57,
                    0xC9Ac53b6ae1C653A54ab0E9D44693E807429aF1F,
                    0xb0c924f61B27cf3C114CBD70def08c62843ebb3F
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0x21C561e551638401b937b03fE5a0a0652B99B7DD,
                    0x6Ca4abE253bd510fCA862b5aBc51211C1E1E8925,
                    0xc601b4d43aF91fE4EAe327a2d2B12f37a568E05B,
                    0x444672831D8E4A2350667C14E007F56BEfFcB79f
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0x0AB1917A0cf92cdcf7F7b637EaC3A46BBBE41409,
                    0x50434C5Da807189622Db5fff66379808c58574aD,
                    0x26Df87542C50326A5085764b1F650EF2514776B6,
                    0xb571dcf478E2cC6c0871402fa3Dd4a3C8f6BE66E
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WMATIC"))
        ) {
            return
                Token(
                    0xb685400156cF3CBE8725958DeAA61436727A30c3,
                    0x89a6AE840b3F8f489418933A220315eeA36d11fF,
                    0xEC59F2FB4EF0C46278857Bf2eC5764485974D17B,
                    0x02a5680AE3b7383854Bf446b1B3Be170E67E689C
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("CRV"))
        ) {
            return
                Token(
                    0x3e4b51076d7e9B844B92F8c6377087f9cf8C8696,
                    0x4e752fB98b0dCC90b6772f23C52aD33b795dc758,
                    0x4a6F74A19f05529aF7E7e9f00923FFB990aeBE7B,
                    0xB6704e124997030cE773BB35C1Cc154CF5cE06fB
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("SUSHI"))
        ) {
            return
                Token(
                    0xdDc3C9B8614092e6188A86450c8D597509893E20,
                    0xb7EA2d40B845A1B49E59c9a5f8B6F67b3c48fA04,
                    0x169E542d769137E82E704477aDdfFe89e7FB9b90,
                    0x95230060256d957F852db649B381045ace7983Cc
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("GHST"))
        ) {
            return
                Token(
                    0x8AaF462990dD5CC574c94C8266208996426A47e7,
                    0x128cB3720f5d220e1E35512917c3c7fFf064A858,
                    0x03d6be9Bc91956A0bc39f515CaA77C8C0f81c3fC,
                    0x1170823EA41B03e2258f228f617cB549C1faDf28
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("BAL"))
        ) {
            return
                Token(
                    0xE3981f4840843D67aF50026d34DA0f7e56A02D69,
                    0x6236bfBfB3b6CDBFC311399BE346d61Ab8ab1094,
                    0xf28E16644C6389b1B6cF03b3120726b1FfAeDC6E,
                    0xB70013Bde95589330F87cE9a5bD06a89Bc26e38d
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DPI"))
        ) {
            return
                Token(
                    0x56e0507A53Ee252947a1E55D84Dc4032F914DD98,
                    0xf815E724973ff3f5Eedc243eAE1a34D1f2a45e0C,
                    0x2C64B0ef18bC0616291Dc636b1738DbC675C3f0d,
                    0x6bB285977693F47AC6799F0B3B159130018f4c9c
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("EURS"))
        ) {
            return
                Token(
                    0x302567472401C7c7B50ee7eb3418c375D8E3F728,
                    0xf6AeDD279Aae7361e70030515f56c22A16d81433,
                    0xaB7cDf4C6053873650695352634987BbEe472c05,
                    0x6Fb76894E171eEDF94BB33E650Af90DfdA2c37FC
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("JEUR"))
        ) {
            return
                Token(
                    0xBaaCc99123133851Ba2D6d34952aa08CBDf5A4E4,
                    0x04cdAA74B111b49EF4044455324C0dDb1C2aa783,
                    0xdAc793dc4A6850765F0f55224CC77425e67C2b6e,
                    0x97CD2BA205ff6FF09332892AB216B665793fc39E
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AGEUR"))
        ) {
            return
                Token(
                    0xFCadBDefd30E11258559Ba239C8a5A8A8D28CB00,
                    0xbC456dc7E6F882DBc7b11da1048eD253F5DB021D,
                    0x706E3AD3F2745722152acc71Da3C76330c2aa258,
                    0x290F8118AAf61e129646F03791227434DFe39669
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveV2Polygon {
    ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0xd05e3E715d945B59290df0ae8eF85c1BdB684744
        );

    ILendingPool internal constant POOL =
        ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
        ILendingPoolConfigurator(0x26db2B833021583566323E3b8985999981b9F1F3);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);

    address internal constant POOL_ADMIN =
        0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

    address internal constant EMERGENCY_ADMIN =
        0x1450F2898D6bA2710C98BE9CAF3041330eD5ae58;

    address internal constant COLLECTOR =
        0x7734280A4337F37Fbf4651073Db7c28C80B339e9;

    address internal constant COLLECTOR_CONTROLLER = address(0);

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("DAI")))
        ) {
            return
                Token(
                    0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                    0x27F8D03b3a2196956ED754baDc28D73be8830A6e,
                    0x2238101B7014C279aaF6b408A284E49cDBd5DB55,
                    0x75c4d1Fb84429023170086f06E682DcbBF537b7d
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDC")))
        ) {
            return
                Token(
                    0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
                    0x1a13F4Ca1d028320A707D99520AbFefca3998b7F,
                    0xdeb05676dB0DB85cecafE8933c903466Bf20C572,
                    0x248960A9d75EdFa3de94F7193eae3161Eb349a12
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDT")))
        ) {
            return
                Token(
                    0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
                    0x60D55F02A771d515e077c9C2403a1ef324885CeC,
                    0xe590cfca10e81FeD9B0e4496381f02256f5d2f61,
                    0x8038857FD47108A07d1f6Bf652ef1cBeC279A2f3
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WBTC")))
        ) {
            return
                Token(
                    0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6,
                    0x5c2ed810328349100A66B82b78a1791B101C9D61,
                    0x2551B15dB740dB8348bFaDFe06830210eC2c2F13,
                    0xF664F50631A6f0D72ecdaa0e49b0c019Fa72a8dC
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WETH")))
        ) {
            return
                Token(
                    0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619,
                    0x28424507fefb6f7f8E9D3860F56504E4e5f5f390,
                    0xc478cBbeB590C76b01ce658f8C4dda04f30e2C6f,
                    0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WMATIC")))
        ) {
            return
                Token(
                    0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
                    0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4,
                    0xb9A6E29fB540C5F1243ef643EB39b0AcbC2e68E3,
                    0x59e8E9100cbfCBCBAdf86b9279fa61526bBB8765
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("AAVE")))
        ) {
            return
                Token(
                    0xD6DF932A45C0f255f85145f286eA0b292B21C90B,
                    0x1d2a0E5EC8E5bBDCA5CB219e649B565d8e5c3360,
                    0x17912140e780B29Ba01381F088f21E8d75F954F9,
                    0x1c313e9d0d826662F5CE692134D938656F681350
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("GHST")))
        ) {
            return
                Token(
                    0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7,
                    0x080b5BF8f360F624628E0fb961F4e67c9e3c7CF1,
                    0x6A01Db46Ae51B19A6B85be38f1AA102d8735d05b,
                    0x36e988a38542C3482013Bb54ee46aC1fb1efedcd
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("BAL")))
        ) {
            return
                Token(
                    0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3,
                    0xc4195D4060DaEac44058Ed668AA5EfEc50D77ff6,
                    0xbC30bbe0472E0E86b6f395f9876B950A13B23923,
                    0x773E0e32e7b6a00b7cA9daa85dfba9D61B7f2574
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("DPI")))
        ) {
            return
                Token(
                    0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369,
                    0x81fB82aAcB4aBE262fc57F06fD4c1d2De347D7B1,
                    0xA742710c0244a8Ebcf533368e3f0B956B6E53F7B,
                    0x43150AA0B7e19293D935A412C8607f9172d3d3f3
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("CRV")))
        ) {
            return
                Token(
                    0x172370d5Cd63279eFa6d502DAB29171933a610AF,
                    0x3Df8f92b7E798820ddcCA2EBEA7BAbda2c90c4aD,
                    0x807c97744e6C9452e7C2914d78f49d171a9974a0,
                    0x780BbcBCda2cdb0d2c61fd9BC68c9046B18f3229
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("SUSHI")))
        ) {
            return
                Token(
                    0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a,
                    0x21eC9431B5B55c5339Eb1AE7582763087F98FAc2,
                    0x7Ed588DCb30Ea11A54D8a5E9645960262A97cd54,
                    0x9CB9fEaFA73bF392C905eEbf5669ad3d073c3DFC
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("LINK")))
        ) {
            return
                Token(
                    0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39,
                    0x0Ca2e42e8c21954af73Bc9af1213E4e81D6a669A,
                    0x9fb7F546E60DDFaA242CAeF146FA2f4172088117,
                    0xCC71e4A38c974e19bdBC6C0C19b63b8520b1Bb09
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Polygon {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IPool internal constant POOL =
        IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xb023e699F5a33916Ea823A16485e259257cA8Bd1);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

    address internal constant ACL_ADMIN =
        0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

    address internal constant COLLECTOR =
        0xe8599F3cc5D38a9aD6F3684cd5CEa72f10Dbc383;

    address internal constant COLLECTOR_CONTROLLER =
        0x73D435AFc15e35A9aC63B2a81B5AA54f974eadFe;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                    0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                    0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                    0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39,
                    0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                    0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                    0x953A573793604aF8d41F306FEb8274190dB4aE0e
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
                    0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                    0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                    0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6,
                    0x078f358208685046a11C85e8ad32895DED33A249,
                    0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                    0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619,
                    0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                    0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                    0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
                    0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                    0x70eFfc565DB6EEf7B927610155602d31b670e802,
                    0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0xD6DF932A45C0f255f85145f286eA0b292B21C90B,
                    0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                    0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                    0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WMATIC"))
        ) {
            return
                Token(
                    0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
                    0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                    0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                    0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("CRV"))
        ) {
            return
                Token(
                    0x172370d5Cd63279eFa6d502DAB29171933a610AF,
                    0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf,
                    0x08Cb71192985E936C7Cd166A8b268035e400c3c3,
                    0x77CA01483f379E58174739308945f044e1a764dc
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("SUSHI"))
        ) {
            return
                Token(
                    0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a,
                    0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA,
                    0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841,
                    0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("GHST"))
        ) {
            return
                Token(
                    0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7,
                    0x8Eb270e296023E9D92081fdF967dDd7878724424,
                    0x3EF10DFf4928279c004308EbADc4Db8B7620d6fc,
                    0xCE186F6Cccb0c955445bb9d10C59caE488Fea559
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("BAL"))
        ) {
            return
                Token(
                    0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3,
                    0x8ffDf2DE812095b1D19CB146E4c004587C0A0692,
                    0xa5e408678469d23efDB7694b1B0A85BB0669e8bd,
                    0xA8669021776Bc142DfcA87c21b4A52595bCbB40a
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DPI"))
        ) {
            return
                Token(
                    0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369,
                    0x724dc807b04555b71ed48a6896b6F41593b8C637,
                    0xDC1fad70953Bb3918592b6fCc374fe05F5811B6a,
                    0xf611aEb5013fD2c0511c9CD55c7dc5C1140741A6
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("EURS"))
        ) {
            return
                Token(
                    0xE111178A87A3BFf0c8d18DECBa5798827539Ae99,
                    0x38d693cE1dF5AaDF7bC62595A37D667aD57922e5,
                    0x8a9FdE6925a839F6B1932d16B36aC026F8d3FbdB,
                    0x5D557B07776D12967914379C71a1310e917C7555
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("jEUR"))
        ) {
            return
                Token(
                    0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c,
                    0x6533afac2E7BCCB20dca161449A13A32D391fb00,
                    0x6B4b37618D85Db2a7b469983C888040F7F05Ea3D,
                    0x44705f578135cC5d703b4c9c122528C73Eb87145
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("agEUR"))
        ) {
            return
                Token(
                    0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4,
                    0x8437d7C167dFB82ED4Cb79CD44B7a32A1dd95c77,
                    0x40B4BAEcc69B882e8804f9286b12228C27F8c9BF,
                    0x3ca5FA07689F266e907439aFd1fBB59c44fe12f6
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveV2Fuji {
    ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0x7fdC1FdF79BE3309bf82f4abdAD9f111A6590C0f
        );

    ILendingPool internal constant POOL =
        ILendingPool(0x76cc67FF2CC77821A70ED14321111Ce381C2594D);

    ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
        ILendingPoolConfigurator(0x4ceBAFAAcc6Cb26FD90E4cDe138Eb812442bb5f3);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xfa4f5B081632c4709667D467F817C09d9008A46A);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x0668EDE013c1c475724523409b8B6bE633469585);

    address internal constant POOL_ADMIN =
        0x1128d177BdaA74Ae68EB06e693f4CbA6BF427a5e;

    address internal constant EMERGENCY_ADMIN =
        0x1128d177BdaA74Ae68EB06e693f4CbA6BF427a5e;

    address internal constant COLLECTOR =
        0xB45F5C501A22288dfdb897e5f73E189597e09288;

    address internal constant COLLECTOR_CONTROLLER = address(0);

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WETH")))
        ) {
            return
                Token(
                    0x9668f5f55f2712Dd2dfa316256609b516292D554,
                    0x2B2927e26b433D92fC598EE79Fa351d6591B8F95,
                    0x056AaAc3aAf49d00C4fA10bCf9661D2371427ECB,
                    0xB61CC359E2133b8618cc0319F359F8CA1d3d2b33
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDT")))
        ) {
            return
                Token(
                    0x02823f9B469960Bb3b1de0B3746D4b95B7E35543,
                    0x5f049c41aF3856cBc171F61FB04D58C1e7445f5F,
                    0x8c5a8eB9dd4e029c1A5B9e740086eB6Cf4Ba7F13,
                    0x6422A7C91A48dD211BF6BdE1Db14d7734f9cbD69
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WBTC")))
        ) {
            return
                Token(
                    0x9C1DCacB57ADa1E9e2D3a8280B7cfC7EB936186F,
                    0xD5B516FDbfb7264676Fd4901B9dD3F707db68733,
                    0x38A9d8f89Cf87FD4C50dd7B019b9af30c2540512,
                    0xbd0601970fE5b35649Fb92f292cde21f0f52eAE9
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WAVAX")))
        ) {
            return
                Token(
                    0xd00ae08403B9bbb9124bB305C09058E32C39A48c,
                    0xf8C78Ba24DD965487f4472dfb280c46800a0c9B6,
                    0xE1c2E4E85d34CAed5c29447135c3ADfaD30364f1,
                    0x333f38B8E76077539Cde1d50Fb5dE0AC6F7E6837
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Fuji {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0x1775ECC8362dB6CaB0c7A9C0957cF656A5276c29);

    IPool internal constant POOL =
        IPool(0xb47673b7a73D78743AFF1487AF69dBB5763F00cA);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x01743372F0F0318AaDF690f960A4c6c4eab58782);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xAc6D153BF94aFBdC296e72163735B0f94581F736);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x8e0988b28f9CdDe0134A206dfF94111578498C63);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xAa6Fd640173bcA58e5a5CC373531F9038eF3F9e1);

    address internal constant ACL_ADMIN =
        0x77c45699A715A64A7a7796d5CEe884cf617D5254;

    address internal constant COLLECTOR =
        0xBaaCc99123133851Ba2D6d34952aa08CBDf5A4E4;

    address internal constant COLLECTOR_CONTROLLER =
        0xFCadBDefd30E11258559Ba239C8a5A8A8D28CB00;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0xFc7215C9498Fc12b22Bc0ed335871Db4315f03d3,
                    0xC42f40B7E22bcca66B3EE22F3ACb86d24C997CC2,
                    0xf5934275da36A067CE00b415F0b876fA403A7198,
                    0xCB19d2C32cB4340C67273A5a4f5dD02BCceBbF97
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0x73b4C0C45bfB90FC44D9013FA213eF2C2d908D0A,
                    0x210a3f864812eAF7f89eE7337EAA1FeA1830C57e,
                    0x0DDD3C8dfA22d4B5e5Dc086f87d94e4180dAC38D,
                    0x1f59c8D4C97E172e42dc3cF62E75464b7e0205bf
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f,
                    0xA79570641bC9cbc6522aA80E2de03bF9F7fd123a,
                    0xC168dB86f93F97652462ded450B3Ad5eA9669df2,
                    0x796eF05488765B4DeAd23B3C7b9F295139049879
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0x09C85Ef96e93f0ae892561052B48AE9DB29F2458,
                    0x07B2C0b69c70e89C94A20A555Ab376E5a6181eE6,
                    0xdfBa66e02c4915708e7Df3C26843D5A3492727d9,
                    0x9731B6e01222a0772926455e4aEBa3d1ef690F24
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0x28A8E6e41F84e62284970E4bc0867cEe2AAd0DA4,
                    0x618922b15a1a92652818473741531eE255f68741,
                    0xBA932F4F400204c7a05bDF06c6fcA8c114e39d8c,
                    0x800408b3a399d50fAbB064CB04C205910194017C
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0xD90db1ca5A6e9873BCD9B0279AE038272b656728,
                    0x3a7e85a86F952CB61485e2D20BDDb6e15204744f,
                    0xB66d28fd0FF446aB504dEF6C2BCd0ef5c0AADdD3,
                    0x5CC87B358742407E563A6cB665Ce28a6937eAe29
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0xCcbBaf8D40a5C34bf1c836e8dD33c7B7646706C5,
                    0xE9C1731e1186362E2ba233BC16614b2a53ecb3F2,
                    0x118369DcFb3Dfaa36Ad424AF26247c2D91CA1262,
                    0x1447a3924BE947CE32b1d4045DAE8F99B894CC61
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WAVAX"))
        ) {
            return
                Token(
                    0x407287b03D1167593AF113d32093942be13A535f,
                    0xC50E6F9E8e6CAd53c42ddCB7A42d616d7420fd3e,
                    0xaB73C7267347a8dc4d34f9969663E7a64B578C69,
                    0xE21840302317b265dB7E530667ACb31188655cA2
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveV2Avalanche {
    ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f
        );

    ILendingPool internal constant POOL =
        ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);

    ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
        ILendingPoolConfigurator(0x230B618aD4C475393A7239aE03630042281BD86e);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xdC336Cd4769f4cC7E9d726DA53e6d3fC710cEB89);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x65285E9dfab318f57051ab2b139ccCf232945451);

    address internal constant POOL_ADMIN =
        0x01244E7842254e3FD229CD263472076B1439D1Cd;

    address internal constant EMERGENCY_ADMIN =
        0x01244E7842254e3FD229CD263472076B1439D1Cd;

    address internal constant COLLECTOR =
        0x467b92aF281d14cB6809913AD016a607b5ba8A36;

    address internal constant COLLECTOR_CONTROLLER = address(0);

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WETH.e")))
        ) {
            return
                Token(
                    0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB,
                    0x53f7c5869a859F0AeC3D334ee8B4Cf01E3492f21,
                    0x60F6A45006323B97d97cB0a42ac39e2b757ADA63,
                    0x4e575CacB37bc1b5afEc68a0462c4165A5268983
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("DAI.e")))
        ) {
            return
                Token(
                    0xd586E7F844cEa2F87f50152665BCbc2C279D8d70,
                    0x47AFa96Cdc9fAb46904A55a6ad4bf6660B53c38a,
                    0x3676E4EE689D527dDb89812B63fAD0B7501772B3,
                    0x1852DC24d1a8956a0B356AA18eDe954c7a0Ca5ae
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDT.e")))
        ) {
            return
                Token(
                    0xc7198437980c041c805A1EDcbA50c1Ce5db95118,
                    0x532E6537FEA298397212F09A61e03311686f548e,
                    0x9c7B81A867499B7387ed05017a13d4172a0c17bF,
                    0xfc1AdA7A288d6fCe0d29CcfAAa57Bc9114bb2DbE
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("USDC.e")))
        ) {
            return
                Token(
                    0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664,
                    0x46A51127C3ce23fb7AB1DE06226147F446e4a857,
                    0x5B14679135dbE8B02015ec3Ca4924a12E4C6C85a,
                    0x848c080d2700CBE1B894a3374AD5E887E5cCb89c
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("AAVE.e")))
        ) {
            return
                Token(
                    0x63a72806098Bd3D9520cC43356dD78afe5D386D9,
                    0xD45B7c061016102f9FA220502908f2c0f1add1D7,
                    0x66904E4F3f44e3925D22ceca401b6F2DA085c98f,
                    0x8352E3fd18B8d84D3c8a1b538d788899073c7A8E
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WBTC.e")))
        ) {
            return
                Token(
                    0x50b7545627a5162F82A992c33b87aDc75187B218,
                    0x686bEF2417b6Dc32C50a3cBfbCC3bb60E1e9a15D,
                    0x3484408989985d68C9700dc1CFDFeAe6d2f658CF,
                    0x2dc0E35eC3Ab070B8a175C829e23650Ee604a9eB
                );
        } else if (
            keccak256(abi.encodePacked((symbol))) ==
            keccak256(abi.encodePacked(("WAVAX")))
        ) {
            return
                Token(
                    0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
                    0xDFE521292EcE2A4f44242efBcD66Bc594CA9714B,
                    0x2920CD5b8A160b2Addb00Ec5d5f4112255d4ae75,
                    0x66A0FE52Fb629a6cB4D10B8580AFDffE888F5Fd4
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Avalanche {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IPool internal constant POOL =
        IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xEBd36016B3eD09D4693Ed4251c67Bd858c3c7C9C);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

    address internal constant ACL_ADMIN =
        0xa35b76E4935449E33C56aB24b23fcd3246f13470;

    address internal constant COLLECTOR =
        0x5ba7fd868c40c16f7aDfAe6CF87121E13FC2F7a0;

    address internal constant COLLECTOR_CONTROLLER =
        0xaCbE7d574EF8dC39435577eb638167Aca74F79f0;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI.e"))
        ) {
            return
                Token(
                    0xd586E7F844cEa2F87f50152665BCbc2C279D8d70,
                    0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                    0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                    0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK.e"))
        ) {
            return
                Token(
                    0x5947BB275c521040051D82396192181b413227A3,
                    0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                    0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                    0x953A573793604aF8d41F306FEb8274190dB4aE0e
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E,
                    0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                    0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                    0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC.e"))
        ) {
            return
                Token(
                    0x50b7545627a5162F82A992c33b87aDc75187B218,
                    0x078f358208685046a11C85e8ad32895DED33A249,
                    0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                    0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH.e"))
        ) {
            return
                Token(
                    0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB,
                    0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                    0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                    0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDt"))
        ) {
            return
                Token(
                    0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7,
                    0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                    0x70eFfc565DB6EEf7B927610155602d31b670e802,
                    0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE.e"))
        ) {
            return
                Token(
                    0x63a72806098Bd3D9520cC43356dD78afe5D386D9,
                    0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                    0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                    0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WAVAX"))
        ) {
            return
                Token(
                    0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
                    0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                    0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                    0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("sAVAX"))
        ) {
            return
                Token(
                    0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE,
                    0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf,
                    0x08Cb71192985E936C7Cd166A8b268035e400c3c3,
                    0x77CA01483f379E58174739308945f044e1a764dc
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Arbitrum {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IPool internal constant POOL =
        IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

    address internal constant ACL_ADMIN =
        0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

    address internal constant COLLECTOR =
        0x053D55f9B5AF8694c503EB288a1B7E552f590710;

    address internal constant COLLECTOR_CONTROLLER =
        0xC3301b30f4EcBfd59dE0d74e89690C1a70C6f21B;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
                    0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                    0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                    0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
                    0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                    0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                    0x953A573793604aF8d41F306FEb8274190dB4aE0e
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8,
                    0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                    0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                    0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
                    0x078f358208685046a11C85e8ad32895DED33A249,
                    0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                    0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
                    0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                    0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                    0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
                    0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                    0x70eFfc565DB6EEf7B927610155602d31b670e802,
                    0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0xba5DdD1f9d7F570dc94a51479a000E3BCE967196,
                    0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                    0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                    0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("EURS"))
        ) {
            return
                Token(
                    0xD22a58f79e9481D1a88e00c343885A588b34b68B,
                    0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                    0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                    0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3FantomTestnet {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xE339D30cBa24C70dCCb82B234589E3C83249e658);

    IPool internal constant POOL =
        IPool(0x771A45a19cE333a19356694C5fc80c76fe9bc741);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x59B84a6C943dD655D9E3B4024fC6AdC0E3f4Ff60);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xA840C768f7143495790eC8dc2D5f32B71B6Dc113);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0xCbAcff915f2d10727844ab0f2A4D9768954981e4);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0x94f154aba287b3024fb32386463FC52d488bb09B);

    address internal constant ACL_ADMIN =
        0x77c45699A715A64A7a7796d5CEe884cf617D5254;

    address internal constant COLLECTOR =
        0xF49dA7a22463D140f9f8dc7C91468C8721215496;

    address internal constant COLLECTOR_CONTROLLER =
        0x7aaB2c2CC186131851d6B1876D16eDc849846042;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0xc469ff24046779DE9B61Be7b5DF91dbFfdF1AE02,
                    0xfb08e04E9c7AfFE693290F739d11D5C3Dd2e19B5,
                    0x87d62612a58a806B926a0A1276DF5C9c6DbE8a5e,
                    0x78243313999d4582cfEE48bD5B4466efF6c90fE1
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0x42Dc50EB0d35A62eac61f4E4Bc81875db9F9366e,
                    0x1A7e068f35B19Ff89B7d646D83Ae15C2Db1D93c5,
                    0x475e4C43caE948578685462F17FB7fedB85E3F79,
                    0x57066BC9569260e9dEC8d224BeB9A8a56209Ff64
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0x06f0790c687A1bED6186ce3624EDD9806edf9F4E,
                    0xf1090cB4f56fDb659D24DDbC4972bE9D379A6E8c,
                    0x7e90CE7a0463cc5656c38B5a85C33dF4C8F2523C,
                    0x946765C86B534D8114475BFec8De8De481bA4d1F
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0xd0404A349A76CD2a4B7AB322B9a6C993dbC3A7E7,
                    0xd2ecf7aA363A9dE20088eF1a92D76D4147828B58,
                    0x7e72682d8c90A1eeE1403730f31DCf81551C5aFA,
                    0x68C3E2eb8F2550E13328B4a9cccac65Ba6C200Be
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0x2aF63215417F90bd45608115452d86D0a1bEAE5E,
                    0xd29fF48d6Fc110fe227286D5A509a4CB6503732E,
                    0xfD7D3f98aF173B18e5A98fE3b1aE530edab1a988,
                    0x27dF3D6eF22A6aC1c8744Fd7A4516a4C8B22084f
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0x1b901d3C9D4ce153326BEeC60e0D4A2e8a9e3cE3,
                    0x1364B761d75E348B861D7EFaEB64A5b3a37965ec,
                    0xCcE4E4c5327870EfD280645B5a24A50dC01125a4,
                    0x81Ed0a1D00841B68C6F3956E4E210EFaaeBEBAF1
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0x2a6202B83Bd2562d7460F91E9298abC27a2F0a95,
                    0xeCbA9a45fDb849548F3e7a621fcBa4f11b3BBDcF,
                    0x460d55849094CDcc8c9582Cf4B58485C08405Ae7,
                    0xe90400D7D8acdCcC8c335883097A722AB653890D
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WFTM"))
        ) {
            return
                Token(
                    0xF7475b635EbE06d9C5178CC40D50856Fa98C7332,
                    0x22FDD5F19C49fe954847A6424E4a24C2742fD9EF,
                    0x67196249e5fE6c2f532ff456E342Abf8eE19D4E3,
                    0x812388F32346e99078B987e84f60dA68348Ac665
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("CRV"))
        ) {
            return
                Token(
                    0xAC1a9503D1438B56BAa99939D44555FC2dC286Fc,
                    0x552f5C364090B954ADA025f0D7963D0a7A60d52b,
                    0x48Cf4cA307f321f0FC24bfAe3119f9abF6B32Ff5,
                    0xe4CFEa97831CB0d95CA22597e02dD793bB8f45ae
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("SUSHI"))
        ) {
            return
                Token(
                    0x484b87Aa284f51e71F15Eba1aEb06dFD202D5511,
                    0x6cC739A29b8Eb06981B8bbF22464E4F3f082bBA5,
                    0x5f933d8c8fbc9651f3E6bC0652d94fdd09EA139a,
                    0x5522dFE4b4056BA819D8e675e6999011A31BAf7a
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Fantom {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IPool internal constant POOL =
        IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xfd6f3c1845604C8AE6c6E402ad17fb9885160754);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

    address internal constant ACL_ADMIN =
        0x39CB97b105173b56b5a2b4b33AD25d6a50E6c949;

    address internal constant COLLECTOR =
        0xBe85413851D195fC6341619cD68BfDc26a25b928;

    address internal constant COLLECTOR_CONTROLLER =
        0xc0F0cFBbd0382BcE3B93234E4BFb31b2aaBE36aD;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E,
                    0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                    0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                    0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8,
                    0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                    0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                    0x953A573793604aF8d41F306FEb8274190dB4aE0e
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0x04068DA6C83AFCFA0e13ba15A6696662335D5B75,
                    0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                    0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                    0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("BTC"))
        ) {
            return
                Token(
                    0x321162Cd933E2Be498Cd2267a90534A804051b11,
                    0x078f358208685046a11C85e8ad32895DED33A249,
                    0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                    0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("ETH"))
        ) {
            return
                Token(
                    0x74b23882a30290451A17c44f4F05243b6b58C76d,
                    0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                    0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                    0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("fUSDT"))
        ) {
            return
                Token(
                    0x049d68029688eAbF473097a2fC38ef61633A3C7A,
                    0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                    0x70eFfc565DB6EEf7B927610155602d31b670e802,
                    0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0x6a07A792ab2965C72a5B8088d3a069A7aC3a993B,
                    0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                    0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                    0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WFTM"))
        ) {
            return
                Token(
                    0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83,
                    0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                    0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                    0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("CRV"))
        ) {
            return
                Token(
                    0x1E4F97b9f9F913c46F1632781732927B9019C68b,
                    0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf,
                    0x08Cb71192985E936C7Cd166A8b268035e400c3c3,
                    0x77CA01483f379E58174739308945f044e1a764dc
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("SUSHI"))
        ) {
            return
                Token(
                    0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC,
                    0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA,
                    0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841,
                    0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3HarmonyTestnet {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xd19443202328A66875a51560c28276868B8C61C2);

    IPool internal constant POOL =
        IPool(0x85C1F3f1bB439180f7Bfda9DFD61De82e10bD554);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0xdb903B5a28260E87cF1d8B56740a90Dba1c8fe15);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0x29Ff3c19C6853A0b6544b3CC241c360f422aBaD1);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0xFc7215C9498Fc12b22Bc0ed335871Db4315f03d3);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0x1758d4e6f68166C4B2d9d0F049F33dEB399Daa1F);

    address internal constant ACL_ADMIN =
        0x77c45699A715A64A7a7796d5CEe884cf617D5254;

    address internal constant COLLECTOR =
        0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2;

    address internal constant COLLECTOR_CONTROLLER =
        0x85E44420b6137bbc75a85CAB5c9A3371af976FdE;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0x302567472401C7c7B50ee7eb3418c375D8E3F728,
                    0xF5C62a60A2065D34b601CAfF8775F5A2857A9088,
                    0x88d8a116C758C782985DAD67798666e270F0F1a8,
                    0xDD81Dec96a2e4c5221fe11854a32F37C49C1a72A
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0xBaaCc99123133851Ba2D6d34952aa08CBDf5A4E4,
                    0xd5Bc03707A290BAaB91FeFBAf397Fe90EE48Cc39,
                    0xE052c9c02cd4949832cAC20A91B8cf7C59cDd93b,
                    0x2DE29943BbFA3740C1C3C9532E61e3489b2f742A
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0xFCadBDefd30E11258559Ba239C8a5A8A8D28CB00,
                    0xf58153a81DbC7118a8Ad128024996E68dcDEE8B2,
                    0x7C50b2Fb765D77547B7a9F44364308FeEE7526D6,
                    0x6bA6869B3B16a2478EAc78010e4c0DB534Fd79F2
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0xc1eB89DA925cc2Ae8B36818d26E12DDF8F8601b0,
                    0x9D6a5051882C1DFA7d26Cb862a13843c1fe0EF0A,
                    0x478FE510965e607C95EB52c91FB711c8006483B9,
                    0x4953fFBeD89EfE9DC6B4Fe51f74924D6A9b7Ce4e
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6,
                    0x7916c8E4d5B3C998B7e8d94bEE3625D0996dA3CC,
                    0x348d1F7BC7FF6803AB96e51B846069Fc1F74F8E5,
                    0x87c271682553fBe445331C872D991c463091f625
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0x2A9534682aF7e07bA9615e15dd9d88968173F6c3,
                    0xAe8c5CfF5D96c36372378A4eFEBcaE78e3552AD9,
                    0xd6D10CEfD2E8A94B5B4Bd3D7B3F2d1cE39c0508c,
                    0xAe2A7BCEF650E798c8911a375bDcec248acbeEC9
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0x407287b03D1167593AF113d32093942be13A535f,
                    0xAf16e6F087bb99aEf830409228CCcf8B039C758D,
                    0xCd5327194e4e95C4AECf863904FA80a8522c7C97,
                    0x0F8801a7a8964EA79a504EBa454CbAfF793feED7
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WONE"))
        ) {
            return
                Token(
                    0x3e4b51076d7e9B844B92F8c6377087f9cf8C8696,
                    0xA6a1ec235B90e0b5567521F52e5418B9BA189334,
                    0xdBb47093f92090Ec0E1B3CDC48fAFB52Ea185403,
                    0xB344989ff1717549221AF8525110421e4955857b
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Harmony {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IPool internal constant POOL =
        IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0x3C90887Ede8D65ccb2777A5d577beAb2548280AD);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

    address internal constant ACL_ADMIN =
        0xb2f0C5f37f4beD2cB51C44653cD5D84866BDcd2D;

    address internal constant COLLECTOR =
        0x8A020d92D6B119978582BE4d3EdFdC9F7b28BF31;

    address internal constant COLLECTOR_CONTROLLER =
        0xeaC16519923774Fd7723d3D5E442a1e2E46BA962;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("1DAI"))
        ) {
            return
                Token(
                    0xEf977d2f931C1978Db5F6747666fa1eACB0d0339,
                    0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                    0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                    0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0x218532a12a389a4a92fC0C5Fb22901D1c19198aA,
                    0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                    0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                    0x953A573793604aF8d41F306FEb8274190dB4aE0e
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("1USDC"))
        ) {
            return
                Token(
                    0x985458E523dB3d53125813eD68c274899e9DfAb4,
                    0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                    0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                    0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("1WBTC"))
        ) {
            return
                Token(
                    0x3095c7557bCb296ccc6e363DE01b760bA031F2d9,
                    0x078f358208685046a11C85e8ad32895DED33A249,
                    0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                    0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("1ETH"))
        ) {
            return
                Token(
                    0x6983D1E6DEf3690C4d616b13597A09e6193EA013,
                    0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                    0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                    0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("1USDT"))
        ) {
            return
                Token(
                    0x3C2B8Be99c50593081EAA2A724F0B8285F5aba8f,
                    0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                    0x70eFfc565DB6EEf7B927610155602d31b670e802,
                    0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("1AAVE"))
        ) {
            return
                Token(
                    0xcF323Aad9E522B93F11c352CaA519Ad0E14eB40F,
                    0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                    0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                    0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WONE"))
        ) {
            return
                Token(
                    0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a,
                    0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                    0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                    0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3OptimismKovan {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xD15d36975A0200D11B8a8964F4F267982D2a1cFe);

    IPool internal constant POOL =
        IPool(0x139d8F557f70D1903787e929D7C42165c4667229);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x12F6E19b968e34fEE34763469c7EAf902Af6914B);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xce87225e5A0ABFe6241C6A60158840d509a84B47);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x2f733c0389bfF96a3f930Deb2f6DB1d767Cd3215);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0x552626e2E6e35566d53CE0C5Ad97d72E95bC3fc3);

    address internal constant ACL_ADMIN =
        0x77c45699A715A64A7a7796d5CEe884cf617D5254;

    address internal constant COLLECTOR =
        0x733DC8C72B189791B28Dc8c6Fb09D9201b01eF2f;

    address internal constant COLLECTOR_CONTROLLER =
        0x9b791f6A34B2C87c360902F050dA5e0075b7A567;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0xd6B095c27bDf158C462AaB8Cb947BdA9351C0e1d,
                    0x4cdb5D85687Fa162446c7Cf263f9be9614E6314B,
                    0xF7f1a6f7A614b12F2f3bcc8a2e0952B2c6bF283d,
                    0x4F02eD54a25CD9D5bc3432f4bD82f39655A9F4bD
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0xFbBCcCCA95b5F676D8f044Ec75e7eA5899280efF,
                    0x70713F22F01f0053803F1520d526a2C7b26b318a,
                    0x2074341b6880f6B7FC4f3B2B3B15ef91712182E6,
                    0x36B43B427a618cb2Dda78bEc36B7ed7d0b193071
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0x9cCc44Aa7C301b6655ec9891BdaD20fa6eb2b552,
                    0x0849Cd326DC590bF313a0b1E5a04790CBb4eE387,
                    0xE953b08a7908921e179187bAf7dFb4e36f9b40CA,
                    0x3cB29D1F440d7ffADACCd57762c1332CF7Db9e6c
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0xfF5b900f020d663719EEE1731C21778632e6C424,
                    0x2D89bE7Cfbe21ed728A5AeDdA03cACFCAf04aA08,
                    0x4c9D6192E7920b2C56400aBFa8909EC7A572a315,
                    0x5a9BaC403F9034852Ed18613Ecac81A1FaE2AdF3
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0x46e213C62d4734C64986879af00eEc5128395776,
                    0xCb5Df0b49BCa05B2478a606074ec39e3fa181a6f,
                    0x52B61cD2CbC22A386a8F5d2Cec685e938A0379BB,
                    0x90De0e1eBDBfDb421F79D26EccE37cE1Aa84bbA6
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0xeE6b5ad81c7d88a632b24Bcdac055D6f5F469495,
                    0x98A978662670A35cA2b4aD12319486a3F294a78b,
                    0x1b187f0e91934c94aFb324cD9cd03FBa0C7a8B71,
                    0x163F2F60F99090E1fF7d7eC768dA0BA77Dd50547
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0xb532118d86765Eb544958e47df77bb8bDDe2F096,
                    0x5994ce8E7F595AFE3115D72854e0EAeCbD902ea7,
                    0xBe7c6a35A2932411A379081a745bcb99d83574EC,
                    0xb45966470789847E7bC73E2aEdFefff96c86F821
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("SUSD"))
        ) {
            return
                Token(
                    0x6883D765088f90bAE62048dE45f2202D72985B01,
                    0xE603E221fa3a858BdAE91FB51cE09BA6C53B19A5,
                    0xF864A79eE389859A33DA2CDec69fb1d723dB319B,
                    0xd3a31fD51e6F0Ca6b4a083e05893bfC6e294cb30
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveV3Optimism {
    IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IPool internal constant POOL =
        IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

    IPoolConfigurator internal constant POOL_CONFIGURATOR =
        IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

    IAaveOracle internal constant ORACLE =
        IAaveOracle(0xD81eb3728a631871a7eBBaD631b5f424909f0c77);

    IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
        IAaveProtocolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

    IACLManager internal constant ACL_MANAGER =
        IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

    address internal constant ACL_ADMIN =
        0xE50c8C619d05ff98b22Adf991F17602C774F785c;

    address internal constant COLLECTOR =
        0xB2289E329D2F85F1eD31Adbb30eA345278F21bcf;

    address internal constant COLLECTOR_CONTROLLER =
        0xA77E4A084d7d4f064E326C0F6c0aCefd47A5Cb21;

    function getToken(string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("DAI"))
        ) {
            return
                Token(
                    0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
                    0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                    0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                    0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("LINK"))
        ) {
            return
                Token(
                    0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6,
                    0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                    0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                    0x953A573793604aF8d41F306FEb8274190dB4aE0e
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDC"))
        ) {
            return
                Token(
                    0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
                    0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                    0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                    0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WBTC"))
        ) {
            return
                Token(
                    0x68f180fcCe6836688e9084f035309E29Bf0A2095,
                    0x078f358208685046a11C85e8ad32895DED33A249,
                    0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                    0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("WETH"))
        ) {
            return
                Token(
                    0x4200000000000000000000000000000000000006,
                    0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                    0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                    0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("USDT"))
        ) {
            return
                Token(
                    0x94b008aA00579c1307B0EF2c499aD98a8ce58e58,
                    0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                    0x70eFfc565DB6EEf7B927610155602d31b670e802,
                    0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            return
                Token(
                    0x76FB31fb4af56892A25e32cFC43De717950c9278,
                    0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                    0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                    0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                );
        } else if (
            keccak256(abi.encodePacked(symbol)) ==
            keccak256(abi.encodePacked("sUSD"))
        ) {
            return
                Token(
                    0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9,
                    0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                    0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                    0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                );
        } else revert("Token does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveAddressBookV2Testnet {
    string public constant AaveV2Mumbai = "AaveV2Mumbai";
    string public constant AaveV2Fuji = "AaveV2Fuji";

    struct Market {
        ILendingPoolAddressesProvider POOL_ADDRESSES_PROVIDER;
        ILendingPool POOL;
        ILendingPoolConfigurator POOL_CONFIGURATOR;
        IAaveOracle ORACLE;
        IAaveProtocolDataProvider AAVE_PROTOCOL_DATA_PROVIDER;
        address POOL_ADMIN;
        address EMERGENCY_ADMIN;
        address COLLECTOR;
        address COLLECTOR_CONTROLLER;
    }

    function getMarket(string calldata market)
        public
        pure
        returns (Market memory m)
    {
        if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Mumbai))
        ) {
            return
                Market(
                    ILendingPoolAddressesProvider(
                        0x178113104fEcbcD7fF8669a0150721e231F0FD4B
                    ),
                    ILendingPool(0x9198F13B08E299d85E096929fA9781A1E3d5d827),
                    ILendingPoolConfigurator(
                        0xc3c37E2aA3dc66464fa3C29ce2a6EC85beFC45e1
                    ),
                    IAaveOracle(0xC365C653f7229894F93994CD0b30947Ab69Ff1D5),
                    IAaveProtocolDataProvider(
                        0xFA3bD19110d986c5e5E9DD5F69362d05035D045B
                    ),
                    0x943E44157dC0302a5CEb172374d1749018a00994,
                    0x943E44157dC0302a5CEb172374d1749018a00994,
                    0x943E44157dC0302a5CEb172374d1749018a00994,
                    address(0)
                );
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Fuji))
        ) {
            return
                Market(
                    ILendingPoolAddressesProvider(
                        0x7fdC1FdF79BE3309bf82f4abdAD9f111A6590C0f
                    ),
                    ILendingPool(0x76cc67FF2CC77821A70ED14321111Ce381C2594D),
                    ILendingPoolConfigurator(
                        0x4ceBAFAAcc6Cb26FD90E4cDe138Eb812442bb5f3
                    ),
                    IAaveOracle(0xfa4f5B081632c4709667D467F817C09d9008A46A),
                    IAaveProtocolDataProvider(
                        0x0668EDE013c1c475724523409b8B6bE633469585
                    ),
                    0x1128d177BdaA74Ae68EB06e693f4CbA6BF427a5e,
                    0x1128d177BdaA74Ae68EB06e693f4CbA6BF427a5e,
                    0xB45F5C501A22288dfdb897e5f73E189597e09288,
                    address(0)
                );
        } else revert("Market does not exist");
    }

    function getToken(string calldata market, string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Mumbai))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F,
                        0x639cB7b21ee2161DF9c882483C9D55c90c20Ca3e,
                        0x10dec6dF64d0ebD271c8AdD492Af4F5594358919,
                        0x6D29322ba6549B95e98E9B08033F5ffb857f19c5
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e,
                        0x2271e3Fef9e15046d09E1d78a8FF038c691E9Cf9,
                        0x83A7bC369cFd55D9F00267318b6D221fb9Fa739F,
                        0x05771A896327ee702F965FB6E4A35A9A57C84a2a
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xBD21A10F619BE90d6066c941b04e340841F1F989,
                        0xF8744C0bD8C7adeA522d6DDE2298b17284A79D1b,
                        0xdD250d4e7ff5f7414F3EBe8fcBbB13583191BDaC,
                        0x6C0a86573a63672D8a66C037036e441A59086d68
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x0d787a4a1548f673ed375445535a6c7A1EE56180,
                        0xc9276ECa6798A14f64eC33a526b547DAd50bDa2F,
                        0x29A36d45e8d9f446EC9529b28907bc850B398154,
                        0xc156967272b7177DcE40E3b3E7c4269f750F3160
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x3C68CE8504087f89c640D02d133646d98e64ddd9,
                        0x7aE20397Ca327721F013BB9e140C707F82871b56,
                        0x35D88812d32b966da90db9F546fbf43553C4F35b,
                        0x0F2656e068b77cdA65213Ef25705B728d5C73340
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WMATIC"))
            ) {
                return
                    Token(
                        0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889,
                        0xF45444171435d0aCB08a8af493837eF18e86EE27,
                        0xfeedbD76ac61616f270911CCaBb43a36380f40ae,
                        0x11b884339E453E3d66A8E22246782D40E62cB5F2
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x341d1f30e77D3FBfbD43D17183E2acb9dF25574E,
                        0x7ec62b6fC19174255335C8f4346E0C2fcf870a6B,
                        0x14bD9790e15294608Df4160dcF45B64adBFdCBaA,
                        0x5A6659794E3Fe10eee90833B36a4819953AaB9A1
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Fuji))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x9668f5f55f2712Dd2dfa316256609b516292D554,
                        0x2B2927e26b433D92fC598EE79Fa351d6591B8F95,
                        0x056AaAc3aAf49d00C4fA10bCf9661D2371427ECB,
                        0xB61CC359E2133b8618cc0319F359F8CA1d3d2b33
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0x02823f9B469960Bb3b1de0B3746D4b95B7E35543,
                        0x5f049c41aF3856cBc171F61FB04D58C1e7445f5F,
                        0x8c5a8eB9dd4e029c1A5B9e740086eB6Cf4Ba7F13,
                        0x6422A7C91A48dD211BF6BdE1Db14d7734f9cbD69
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x9C1DCacB57ADa1E9e2D3a8280B7cfC7EB936186F,
                        0xD5B516FDbfb7264676Fd4901B9dD3F707db68733,
                        0x38A9d8f89Cf87FD4C50dd7B019b9af30c2540512,
                        0xbd0601970fE5b35649Fb92f292cde21f0f52eAE9
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WAVAX"))
            ) {
                return
                    Token(
                        0xd00ae08403B9bbb9124bB305C09058E32C39A48c,
                        0xf8C78Ba24DD965487f4472dfb280c46800a0c9B6,
                        0xE1c2E4E85d34CAed5c29447135c3ADfaD30364f1,
                        0x333f38B8E76077539Cde1d50Fb5dE0AC6F7E6837
                    );
            } else revert("Token does not exist");
        } else revert("Market does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider} from "./AaveV2.sol";
import {Token} from "./Common.sol";

library AaveAddressBookV2 {
    string public constant AaveV2Ethereum = "AaveV2Ethereum";
    string public constant AaveV2EthereumAMM = "AaveV2EthereumAMM";
    string public constant AaveV2EthereumArc = "AaveV2EthereumArc";
    string public constant AaveV2Polygon = "AaveV2Polygon";
    string public constant AaveV2Avalanche = "AaveV2Avalanche";

    struct Market {
        ILendingPoolAddressesProvider POOL_ADDRESSES_PROVIDER;
        ILendingPool POOL;
        ILendingPoolConfigurator POOL_CONFIGURATOR;
        IAaveOracle ORACLE;
        IAaveProtocolDataProvider AAVE_PROTOCOL_DATA_PROVIDER;
        address POOL_ADMIN;
        address EMERGENCY_ADMIN;
        address COLLECTOR;
        address COLLECTOR_CONTROLLER;
    }

    function getMarket(string calldata market)
        public
        pure
        returns (Market memory m)
    {
        if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Ethereum))
        ) {
            return
                Market(
                    ILendingPoolAddressesProvider(
                        0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
                    ),
                    ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9),
                    ILendingPoolConfigurator(
                        0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756
                    ),
                    IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9),
                    IAaveProtocolDataProvider(
                        0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d
                    ),
                    0xEE56e2B3D491590B5b31738cC34d5232F378a8D5,
                    0xCA76Ebd8617a03126B6FB84F9b1c1A0fB71C2633,
                    0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c,
                    0x3d569673dAa0575c936c7c67c4E6AedA69CC630C
                );
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2EthereumAMM))
        ) {
            return
                Market(
                    ILendingPoolAddressesProvider(
                        0xAcc030EF66f9dFEAE9CbB0cd1B25654b82cFA8d5
                    ),
                    ILendingPool(0x7937D4799803FbBe595ed57278Bc4cA21f3bFfCB),
                    ILendingPoolConfigurator(
                        0x23A875eDe3F1030138701683e42E9b16A7F87768
                    ),
                    IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9),
                    IAaveProtocolDataProvider(
                        0x0000000000000000000000000000000000000000
                    ),
                    0xEE56e2B3D491590B5b31738cC34d5232F378a8D5,
                    0xB9062896ec3A615a4e4444DF183F0531a77218AE,
                    0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c,
                    0x3d569673dAa0575c936c7c67c4E6AedA69CC630C
                );
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2EthereumArc))
        ) {
            return
                Market(
                    ILendingPoolAddressesProvider(
                        0x6FdfafB66d39cD72CFE7984D3Bbcc76632faAb00
                    ),
                    ILendingPool(0x37D7306019a38Af123e4b245Eb6C28AF552e0bB0),
                    ILendingPoolConfigurator(
                        0x4e1c7865e7BE78A7748724Fa0409e88dc14E67aA
                    ),
                    IAaveOracle(0xB8a7bc0d13B1f5460513040a97F404b4fea7D2f3),
                    IAaveProtocolDataProvider(
                        0x71B53fC437cCD988b1b89B1D4605c3c3d0C810ea
                    ),
                    0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218,
                    0x33B09130b035d6D7e57d76fEa0873d9545FA7557,
                    0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c,
                    0x3d569673dAa0575c936c7c67c4E6AedA69CC630C
                );
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Polygon))
        ) {
            return
                Market(
                    ILendingPoolAddressesProvider(
                        0xd05e3E715d945B59290df0ae8eF85c1BdB684744
                    ),
                    ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf),
                    ILendingPoolConfigurator(
                        0x26db2B833021583566323E3b8985999981b9F1F3
                    ),
                    IAaveOracle(0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d),
                    IAaveProtocolDataProvider(
                        0x7551b5D2763519d4e37e8B81929D336De671d46d
                    ),
                    0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772,
                    0x1450F2898D6bA2710C98BE9CAF3041330eD5ae58,
                    0x7734280A4337F37Fbf4651073Db7c28C80B339e9,
                    address(0)
                );
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Avalanche))
        ) {
            return
                Market(
                    ILendingPoolAddressesProvider(
                        0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f
                    ),
                    ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C),
                    ILendingPoolConfigurator(
                        0x230B618aD4C475393A7239aE03630042281BD86e
                    ),
                    IAaveOracle(0xdC336Cd4769f4cC7E9d726DA53e6d3fC710cEB89),
                    IAaveProtocolDataProvider(
                        0x65285E9dfab318f57051ab2b139ccCf232945451
                    ),
                    0x01244E7842254e3FD229CD263472076B1439D1Cd,
                    0x01244E7842254e3FD229CD263472076B1439D1Cd,
                    0x467b92aF281d14cB6809913AD016a607b5ba8A36,
                    address(0)
                );
        } else revert("Market does not exist");
    }

    function getToken(string calldata market, string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Ethereum))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xdAC17F958D2ee523a2206206994597C13D831ec7,
                        0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811,
                        0xe91D55AB2240594855aBd11b3faAE801Fd4c4687,
                        0x531842cEbbdD378f8ee36D171d6cC9C4fcf475Ec
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
                        0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656,
                        0x51B039b9AFE64B78758f8Ef091211b5387eA717c,
                        0x9c39809Dec7F95F5e0713634a4D0701329B3b4d2
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                        0x030bA81f1c18d280636F32af80b9AAd02Cf0854e,
                        0x4e977830ba4bd783C0BB7F15d3e243f73FF57121,
                        0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("YFI"))
            ) {
                return
                    Token(
                        0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
                        0x5165d24277cD063F5ac44Efd447B27025e888f37,
                        0xca823F78C2Dd38993284bb42Ba9b14152082F7BD,
                        0x7EbD09022Be45AD993BAA1CEc61166Fcc8644d97
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("ZRX"))
            ) {
                return
                    Token(
                        0xE41d2489571d322189246DaFA5ebDe1F4699F498,
                        0xDf7FF54aAcAcbFf42dfe29DD6144A69b629f8C9e,
                        0x071B4323a24E73A5afeEbe34118Cd21B8FAAF7C3,
                        0x85791D117A392097590bDeD3bD5abB8d5A20491A
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI"))
            ) {
                return
                    Token(
                        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
                        0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1,
                        0xD939F7430dC8D5a427f156dE1012A56C18AcB6Aa,
                        0x5BdB050A92CADcCfCDcCCBFC17204a1C9cC0Ab73
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
                        0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B,
                        0x079D6a3E844BcECf5720478A718Edb6575362C5f,
                        0xF7DBA49d571745D9d7fcb56225B05BEA803EBf3C
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BAT"))
            ) {
                return
                    Token(
                        0x0D8775F648430679A709E98d2b0Cb6250d2887EF,
                        0x05Ec93c0365baAeAbF7AefFb0972ea7ECdD39CF1,
                        0x277f8676FAcf4dAA5a6EA38ba511B7F65AA02f9F,
                        0xfc218A6Dfe6901CB34B1a5281FC6f1b8e7E56877
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BUSD"))
            ) {
                return
                    Token(
                        0x4Fabb145d64652a948d72533023f6E7A623C7C53,
                        0xA361718326c15715591c299427c62086F69923D9,
                        0x4A7A63909A72D268b1D8a93a9395d098688e0e5C,
                        0xbA429f7011c9fa04cDd46a2Da24dc0FF0aC6099c
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x6B175474E89094C44Da98b954EedeAC495271d0F,
                        0x028171bCA77440897B824Ca71D1c56caC55b68A3,
                        0x778A13D3eeb110A4f7bb6529F99c000119a08E92,
                        0x6C3c78838c761c6Ac7bE9F59fe808ea2A6E4379d
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("ENJ"))
            ) {
                return
                    Token(
                        0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c,
                        0xaC6Df26a590F08dcC95D5a4705ae8abbc88509Ef,
                        0x943DcCA156b5312Aa24c1a08769D67FEce4ac14C,
                        0x38995F292a6E31b78203254fE1cdd5Ca1010A446
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("KNC"))
            ) {
                return
                    Token(
                        0xdd974D5C2e2928deA5F71b9825b8b646686BD200,
                        0x39C6b3e42d6A679d7D776778Fe880BC9487C2EDA,
                        0x9915dfb872778B2890a117DA1F35F335eb06B54f,
                        0x6B05D1c608015Ccb8e205A690cB86773A96F39f1
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0x514910771AF9Ca656af840dff83E8264EcF986CA,
                        0xa06bC25B5805d5F8d82847D191Cb4Af5A3e873E0,
                        0xFB4AEc4Cc858F2539EBd3D37f2a43eAe5b15b98a,
                        0x0b8f12b1788BFdE65Aa1ca52E3e9F3Ba401be16D
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("MANA"))
            ) {
                return
                    Token(
                        0x0F5D2fB29fb7d3CFeE444a200298f468908cC942,
                        0xa685a61171bb30d4072B338c80Cb7b2c865c873E,
                        0xD86C74eA2224f4B8591560652b50035E4e5c0a3b,
                        0x0A68976301e46Ca6Ce7410DB28883E309EA0D352
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("MKR"))
            ) {
                return
                    Token(
                        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
                        0xc713e5E149D5D0715DcD1c156a020976e7E56B88,
                        0xC01C8E4b12a89456a9fD4e4e75B72546Bf53f0B5,
                        0xba728eAd5e496BE00DCF66F650b6d7758eCB50f8
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("REN"))
            ) {
                return
                    Token(
                        0x408e41876cCCDC0F92210600ef50372656052a38,
                        0xCC12AbE4ff81c9378D670De1b57F8e0Dd228D77a,
                        0x3356Ec1eFA75d9D150Da1EC7d944D9EDf73703B7,
                        0xcd9D82d33bd737De215cDac57FE2F7f04DF77FE0
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("SNX"))
            ) {
                return
                    Token(
                        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
                        0x35f6B052C598d933D69A4EEC4D04c73A191fE6c2,
                        0x8575c8ae70bDB71606A53AeA1c6789cB0fBF3166,
                        0x267EB8Cf715455517F9BD5834AeAE3CeA1EBdbD8
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("sUSD"))
            ) {
                return
                    Token(
                        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51,
                        0x6C5024Cd4F8A59110119C56f8933403A539555EB,
                        0x30B0f7324feDF89d8eff397275F8983397eFe4af,
                        0xdC6a3Ab17299D9C2A412B0e0a4C1f55446AE0817
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("TUSD"))
            ) {
                return
                    Token(
                        0x0000000000085d4780B73119b644AE5ecd22b376,
                        0x101cc05f4A51C0319f570d5E146a8C625198e636,
                        0x7f38d60D94652072b2C44a18c0e14A481EC3C0dd,
                        0x01C0eb1f8c6F1C1bF74ae028697ce7AA2a8b0E92
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                        0xBcca60bB61934080951369a648Fb03DF4F96263C,
                        0xE4922afAB0BbaDd8ab2a88E0C79d884Ad337fcA6,
                        0x619beb58998eD2278e08620f97007e1116D5D25b
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("CRV"))
            ) {
                return
                    Token(
                        0xD533a949740bb3306d119CC777fa900bA034cd52,
                        0x8dAE6Cb04688C62d939ed9B68d32Bc62e49970b1,
                        0x9288059a74f589C919c7Cf1Db433251CdFEB874B,
                        0x00ad8eBF64F141f1C81e9f8f792d3d1631c6c684
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("GUSD"))
            ) {
                return
                    Token(
                        0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd,
                        0xD37EE7e4f452C6638c96536e68090De8cBcdb583,
                        0xf8aC64ec6Ff8E0028b37EB89772d21865321bCe0,
                        0x279AF5b99540c1A3A7E3CDd326e19659401eF99e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BAL"))
            ) {
                return
                    Token(
                        0xba100000625a3754423978a60c9317c58a424e3D,
                        0x272F97b7a56a387aE942350bBC7Df5700f8a4576,
                        0xe569d31590307d05DA3812964F1eDd551D665a0b,
                        0x13210D4Fe0d5402bd7Ecbc4B5bC5cFcA3b71adB0
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("xSUSHI"))
            ) {
                return
                    Token(
                        0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272,
                        0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a,
                        0x73Bfb81D7dbA75C904f430eA8BAe82DB0D41187B,
                        0xfAFEDF95E21184E3d880bd56D4806c4b8d31c69A
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("renFIL"))
            ) {
                return
                    Token(
                        0xD5147bc8e386d91Cc5DBE72099DAC6C9b99276F5,
                        0x514cd6756CCBe28772d4Cb81bC3156BA9d1744aa,
                        0xcAad05C49E14075077915cB5C820EB3245aFb950,
                        0x348e2eBD5E962854871874E444F4122399c02755
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("RAI"))
            ) {
                return
                    Token(
                        0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919,
                        0xc9BC48c72154ef3e5425641a3c747242112a46AF,
                        0x9C72B8476C33AE214ee3e8C20F0bc28496a62032,
                        0xB5385132EE8321977FfF44b60cDE9fE9AB0B4e6b
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AMPL"))
            ) {
                return
                    Token(
                        0xD46bA6D942050d489DBd938a2C909A5d5039A161,
                        0x1E6bb68Acec8fefBD87D192bE09bb274170a0548,
                        0x18152C9f77DAdc737006e9430dB913159645fa87,
                        0xf013D90E4e4E3Baf420dFea60735e75dbd42f1e1
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDP"))
            ) {
                return
                    Token(
                        0x8E870D67F660D95d5be530380D0eC0bd388289E1,
                        0x2e8F4bdbE3d47d7d7DE490437AeA9915D930F1A3,
                        0x2387119bc85A74e0BBcbe190d80676CB16F10D4F,
                        0xFDb93B3b10936cf81FA59A02A7523B6e2149b2B7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DPI"))
            ) {
                return
                    Token(
                        0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b,
                        0x6F634c6135D2EBD550000ac92F494F9CB8183dAe,
                        0xa3953F07f389d719F99FC378ebDb9276177d8A6e,
                        0x4dDff5885a67E4EffeC55875a3977D7E60F82ae0
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("FRAX"))
            ) {
                return
                    Token(
                        0x853d955aCEf822Db058eb8505911ED77F175b99e,
                        0xd4937682df3C8aEF4FE912A96A74121C0829E664,
                        0x3916e3B6c84b161df1b2733dFfc9569a1dA710c2,
                        0xfE8F19B17fFeF0fDbfe2671F248903055AFAA8Ca
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("FEI"))
            ) {
                return
                    Token(
                        0x956F47F50A910163D8BF957Cf5846D573E7f87CA,
                        0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3,
                        0xd89cF9E8A858F8B4b31Faf793505e112d6c17449,
                        0xC2e10006AccAb7B45D9184FcF5b7EC7763f5BaAe
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("stETH"))
            ) {
                return
                    Token(
                        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
                        0x1982b2F5814301d4e9a8b0201555376e62F82428,
                        0x66457616Dd8489dF5D0AFD8678F4A260088aAF55,
                        0xA9DEAc9f00Dc4310c35603FCD9D34d1A750f81Db
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("ENS"))
            ) {
                return
                    Token(
                        0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72,
                        0x9a14e23A58edf4EFDcB360f68cd1b95ce2081a2F,
                        0x34441FFD1948E49dC7a607882D0c38Efd0083815,
                        0x176808047cc9b7A2C9AE202c593ED42dDD7C0D13
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UST"))
            ) {
                return
                    Token(
                        0xa693B19d2931d498c5B318dF961919BB4aee87a5,
                        0xc2e2152647F4C26028482Efaf64b2Aa28779EFC4,
                        0x7FDbfB0412700D94403c42cA3CAEeeA183F07B26,
                        0xaf32001cf2E66C4C3af4205F6EA77112AA4160FE
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("CVX"))
            ) {
                return
                    Token(
                        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B,
                        0x952749E07d7157bb9644A894dFAF3Bad5eF6D918,
                        0xB01Eb1cE1Da06179136D561766fc2d609C5F55Eb,
                        0x4Ae5E4409C6Dbc84A00f9f89e4ba096603fb7d50
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2EthereumAMM))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                        0xf9Fb4AD91812b704Ba883B11d2B576E890a6730A,
                        0x118Ee405c6be8f9BA7cC7a98064EB5DA462235CF,
                        0xA4C273d9A0C1fe2674F0E845160d6232768a3064
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x6B175474E89094C44Da98b954EedeAC495271d0F,
                        0x79bE75FFC64DD58e66787E4Eae470c8a1FD08ba4,
                        0x8da51a5a3129343468a63A96ccae1ff1352a3dfE,
                        0x3F4fA4937E72991367DC32687BC3278f095E7EAa
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                        0xd24946147829DEaA935bE2aD85A3291dbf109c80,
                        0xE5971a8a741892F3b3ac3E9c94d02588190cE220,
                        0xCFDC74b97b69319683fec2A4Ef95c4Ab739F1B12
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xdAC17F958D2ee523a2206206994597C13D831ec7,
                        0x17a79792Fe6fE5C95dFE95Fe3fCEE3CAf4fE4Cb7,
                        0x04A0577a89E1b9E8f6c87ee26cCe6a168fFfC5b5,
                        0xDcFE9BfC246b02Da384de757464a35eFCa402797
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
                        0x13B2f6928D7204328b0E8E4BCd0379aA06EA21FA,
                        0x55E575d092c934503D7635A837584E2900e01d2b,
                        0x3b99fdaFdfE70d65101a4ba8cDC35dAFbD26375f
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11,
                        0x9303EabC860a743aABcc3A1629014CaBcc3F8D36,
                        0xE9562bf0A11315A1e39f9182F446eA58002f010E,
                        0x23bcc861b989762275165d08B127911F09c71628
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xBb2b8038a1640196FbE3e38816F3e67Cba72D940,
                        0xc58F53A8adff2fB4eb16ED56635772075E2EE123,
                        0xeef7d082D9bE2F5eC73C072228706286dea1f492,
                        0x02aAeB4C7736177242Ee0f71f6f6A0F057Aba87d
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f,
                        0xe59d2FF6995a926A574390824a657eEd36801E55,
                        0x997b26eFf106f138e71160022CaAb0AFC5814643,
                        0x859ED7D9E92d1fe42fF95C3BC3a62F7cB59C373E
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xB6909B960DbbE7392D405429eB2b3649752b4838,
                        0xA1B0edF4460CC4d8bFAA18Ed871bFF15E5b57Eb4,
                        0x27c67541a4ea26a436e311b2E6fFeC82083a6983,
                        0x3Fbef89A21Dc836275bC912849627b33c61b09b4
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5,
                        0xE340B25fE32B1011616bb8EC495A4d503e322177,
                        0x6Bb2BdD21920FcB2Ad855AB5d523222F31709d1f,
                        0x925E3FDd927E20e33C3177C4ff6fb72aD1133C87
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0x3dA1313aE46132A397D90d95B1424A9A7e3e0fCE,
                        0x0ea20e7fFB006d4Cfe84df2F72d8c7bD89247DB0,
                        0xd6035f8803eE9f173b1D3EBc3BDE0Ea6B5165636,
                        0xF3f1a76cA6356a908CdCdE6b2AC2eaace3739Cd0
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974,
                        0xb8db81B84d30E2387de0FF330420A4AAA6688134,
                        0xeb32b3A1De9a1915D2b452B673C53883b9Fa6a97,
                        0xeDe4052ed8e1F422F4E5062c679f6B18693fEcdc
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xC2aDdA861F89bBB333c90c492cB837741916A225,
                        0x370adc71f67f581158Dc56f539dF5F399128Ddf9,
                        0x6E7E38bB73E19b62AB5567940Caaa514e9d85982,
                        0xf36C394775285F89bBBDF09533421E3e81e8447c
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0x8Bd1661Da98EBDd3BD080F0bE4e6d9bE8cE9858c,
                        0xA9e201A4e269d6cd5E9F0FcbcB78520cf815878B,
                        0x312edeADf68E69A0f53518bF27EAcD1AbcC2897e,
                        0x2A8d5B1c1de15bfcd5EC41368C0295c60D8Da83c
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0x43AE24960e5534731Fc831386c07755A2dc33D47,
                        0x38E491A71291CD43E8DE63b7253E482622184894,
                        0xef62A0C391D89381ddf8A8C90Ba772081107D287,
                        0xfd15008efA339A2390B48d2E0Ca8Abd523b406d3
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xd3d2E2692501A5c9Ca623199D38826e513033a17,
                        0x3D26dcd840fCC8e4B2193AcE8A092e4a65832F9f,
                        0x6febCE732191Dc915D6fB7Dc5FE3AEFDDb85Bd1B,
                        0x0D878FbB01fbEEa7ddEFb896d56f1D3167af919F
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc,
                        0x391E86e2C002C70dEe155eAceB88F7A3c38f5976,
                        0xfAB4C9775A4316Ec67a8223ecD0F70F87fF532Fc,
                        0x26625d1dDf520fC8D975cc68eC6E0391D9d3Df61
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0x004375Dff511095CC5A197A54140a24eFEF3A416,
                        0x2365a4890eD8965E564B7E2D27C38Ba67Fec4C6F,
                        0xc66bfA05cCe646f05F71DeE333e3229cE24Bbb7e,
                        0x36dA0C5dC23397CBf9D13BbD74E93C04f99633Af
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("UNI-V2"))
            ) {
                return
                    Token(
                        0x2fDbAdf3C4D5A8666Bc06645B8358ab803996E28,
                        0x5394794Be8b6eD5572FCd6b27103F46b5F390E8f,
                        0x9B054B76d6DE1c4892ba025456A9c4F9be5B1766,
                        0xDf70Bdf01a3eBcd0D918FF97390852A914a92Df7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BPT"))
            ) {
                return
                    Token(
                        0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5,
                        0x358bD0d980E031E23ebA9AA793926857703783BD,
                        0x46406eCd20FDE1DF4d80F15F07c434fa95CB6b33,
                        0xF655DF3832859cfB0AcfD88eDff3452b9Aa6Db24
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BPT"))
            ) {
                return
                    Token(
                        0x59A19D8c652FA0284f44113D0ff9aBa70bd46fB4,
                        0xd109b2A304587569c84308c55465cd9fF0317bFB,
                        0x6474d116476b8eDa1B21472a599Ff76A829AbCbb,
                        0xF41A5Cc7a61519B08056176d7B4b87AB34dF55AD
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("G-UNI"))
            ) {
                return
                    Token(
                        0x50379f632ca68D36E50cfBC8F78fe16bd1499d1e,
                        0xd145c6ae8931ed5Bca9b5f5B7dA5991F5aB63B5c,
                        0x460Fd61bBDe7235C3F345901ad677854c9330c86,
                        0x40533CC601Ec5b79B00D76348ADc0c81d93d926D
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("G-UNI"))
            ) {
                return
                    Token(
                        0xD2eeC91055F07fE24C9cCB25828ecfEFd4be0c41,
                        0xCa5DFDABBfFD58cfD49A9f78Ca52eC8e0591a3C5,
                        0xFEaeCde9Eb0cd43FDE13427C6C7ef406780a8136,
                        0x0B7c7d9c5548A23D0455d1edeC541cc2AD955a9d
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2EthereumArc))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                        0xd35f648C3C7f17cd1Ba92e5eac991E3EfcD4566d,
                        0x2a278CDA70D2Fa3eC52B50D9cB84a309CE13A308,
                        0xe8D876034F96081063cD57Cd87b94a156b4E03E1
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
                        0xe6d6E7dA65A2C18109Ff56B7CBBdc7B706Fc13F8,
                        0x8975Aa9d57a40796001Ae98d8C54336cA7Ebe7f1,
                        0xc371FB4513c23Fc962fe23B12cFBD75E1D37ED91
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                        0x319190E3Bbc595602A9E63B2bCfB61c6634355b1,
                        0x1c2921BA94b8C15daa8458905460B70e41127296,
                        0x932167279A4ed3b879bA7eDdC85Aa83551f3989D
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
                        0x89eFaC495C65d43619c661df654ec64fc10C0A75,
                        0x5166F949e8658d743D5b9fb1c5c61CDFd6398058,
                        0x0ac4c7790BC96923b71BfCee44a6923fd085E0c8
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Polygon))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                        0x27F8D03b3a2196956ED754baDc28D73be8830A6e,
                        0x2238101B7014C279aaF6b408A284E49cDBd5DB55,
                        0x75c4d1Fb84429023170086f06E682DcbBF537b7d
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
                        0x1a13F4Ca1d028320A707D99520AbFefca3998b7F,
                        0xdeb05676dB0DB85cecafE8933c903466Bf20C572,
                        0x248960A9d75EdFa3de94F7193eae3161Eb349a12
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
                        0x60D55F02A771d515e077c9C2403a1ef324885CeC,
                        0xe590cfca10e81FeD9B0e4496381f02256f5d2f61,
                        0x8038857FD47108A07d1f6Bf652ef1cBeC279A2f3
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6,
                        0x5c2ed810328349100A66B82b78a1791B101C9D61,
                        0x2551B15dB740dB8348bFaDFe06830210eC2c2F13,
                        0xF664F50631A6f0D72ecdaa0e49b0c019Fa72a8dC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619,
                        0x28424507fefb6f7f8E9D3860F56504E4e5f5f390,
                        0xc478cBbeB590C76b01ce658f8C4dda04f30e2C6f,
                        0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WMATIC"))
            ) {
                return
                    Token(
                        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
                        0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4,
                        0xb9A6E29fB540C5F1243ef643EB39b0AcbC2e68E3,
                        0x59e8E9100cbfCBCBAdf86b9279fa61526bBB8765
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0xD6DF932A45C0f255f85145f286eA0b292B21C90B,
                        0x1d2a0E5EC8E5bBDCA5CB219e649B565d8e5c3360,
                        0x17912140e780B29Ba01381F088f21E8d75F954F9,
                        0x1c313e9d0d826662F5CE692134D938656F681350
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("GHST"))
            ) {
                return
                    Token(
                        0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7,
                        0x080b5BF8f360F624628E0fb961F4e67c9e3c7CF1,
                        0x6A01Db46Ae51B19A6B85be38f1AA102d8735d05b,
                        0x36e988a38542C3482013Bb54ee46aC1fb1efedcd
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BAL"))
            ) {
                return
                    Token(
                        0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3,
                        0xc4195D4060DaEac44058Ed668AA5EfEc50D77ff6,
                        0xbC30bbe0472E0E86b6f395f9876B950A13B23923,
                        0x773E0e32e7b6a00b7cA9daa85dfba9D61B7f2574
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DPI"))
            ) {
                return
                    Token(
                        0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369,
                        0x81fB82aAcB4aBE262fc57F06fD4c1d2De347D7B1,
                        0xA742710c0244a8Ebcf533368e3f0B956B6E53F7B,
                        0x43150AA0B7e19293D935A412C8607f9172d3d3f3
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("CRV"))
            ) {
                return
                    Token(
                        0x172370d5Cd63279eFa6d502DAB29171933a610AF,
                        0x3Df8f92b7E798820ddcCA2EBEA7BAbda2c90c4aD,
                        0x807c97744e6C9452e7C2914d78f49d171a9974a0,
                        0x780BbcBCda2cdb0d2c61fd9BC68c9046B18f3229
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("SUSHI"))
            ) {
                return
                    Token(
                        0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a,
                        0x21eC9431B5B55c5339Eb1AE7582763087F98FAc2,
                        0x7Ed588DCb30Ea11A54D8a5E9645960262A97cd54,
                        0x9CB9fEaFA73bF392C905eEbf5669ad3d073c3DFC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39,
                        0x0Ca2e42e8c21954af73Bc9af1213E4e81D6a669A,
                        0x9fb7F546E60DDFaA242CAeF146FA2f4172088117,
                        0xCC71e4A38c974e19bdBC6C0C19b63b8520b1Bb09
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV2Avalanche))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH.e"))
            ) {
                return
                    Token(
                        0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB,
                        0x53f7c5869a859F0AeC3D334ee8B4Cf01E3492f21,
                        0x60F6A45006323B97d97cB0a42ac39e2b757ADA63,
                        0x4e575CacB37bc1b5afEc68a0462c4165A5268983
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI.e"))
            ) {
                return
                    Token(
                        0xd586E7F844cEa2F87f50152665BCbc2C279D8d70,
                        0x47AFa96Cdc9fAb46904A55a6ad4bf6660B53c38a,
                        0x3676E4EE689D527dDb89812B63fAD0B7501772B3,
                        0x1852DC24d1a8956a0B356AA18eDe954c7a0Ca5ae
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT.e"))
            ) {
                return
                    Token(
                        0xc7198437980c041c805A1EDcbA50c1Ce5db95118,
                        0x532E6537FEA298397212F09A61e03311686f548e,
                        0x9c7B81A867499B7387ed05017a13d4172a0c17bF,
                        0xfc1AdA7A288d6fCe0d29CcfAAa57Bc9114bb2DbE
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC.e"))
            ) {
                return
                    Token(
                        0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664,
                        0x46A51127C3ce23fb7AB1DE06226147F446e4a857,
                        0x5B14679135dbE8B02015ec3Ca4924a12E4C6C85a,
                        0x848c080d2700CBE1B894a3374AD5E887E5cCb89c
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE.e"))
            ) {
                return
                    Token(
                        0x63a72806098Bd3D9520cC43356dD78afe5D386D9,
                        0xD45B7c061016102f9FA220502908f2c0f1add1D7,
                        0x66904E4F3f44e3925D22ceca401b6F2DA085c98f,
                        0x8352E3fd18B8d84D3c8a1b538d788899073c7A8E
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC.e"))
            ) {
                return
                    Token(
                        0x50b7545627a5162F82A992c33b87aDc75187B218,
                        0x686bEF2417b6Dc32C50a3cBfbCC3bb60E1e9a15D,
                        0x3484408989985d68C9700dc1CFDFeAe6d2f658CF,
                        0x2dc0E35eC3Ab070B8a175C829e23650Ee604a9eB
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WAVAX"))
            ) {
                return
                    Token(
                        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
                        0xDFE521292EcE2A4f44242efBcD66Bc594CA9714B,
                        0x2920CD5b8A160b2Addb00Ec5d5f4112255d4ae75,
                        0x66A0FE52Fb629a6cB4D10B8580AFDffE888F5Fd4
                    );
            } else revert("Token does not exist");
        } else revert("Market does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveAddressBookV3Testnet {
    string public constant AaveV3Mumbai = "AaveV3Mumbai";
    string public constant AaveV3Fuji = "AaveV3Fuji";
    string public constant AaveV3FantomTestnet = "AaveV3FantomTestnet";
    string public constant AaveV3HarmonyTestnet = "AaveV3HarmonyTestnet";
    string public constant AaveV3OptimismKovan = "AaveV3OptimismKovan";

    struct Market {
        IPoolAddressesProvider POOL_ADDRESSES_PROVIDER;
        IPool POOL;
        IPoolConfigurator POOL_CONFIGURATOR;
        IAaveOracle ORACLE;
        IAaveProtocolDataProvider POOL_DATA_PROVIDER;
        IACLManager ACL_MANAGER;
        address ACL_ADMIN;
        address COLLECTOR;
        address COLLECTOR_CONTROLLER;
    }

    function getMarket(string calldata market)
        public
        pure
        returns (Market memory m)
    {
        if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Mumbai)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6
                    ),
                    IPool(0x6C9fB0D5bD9429eb9Cd96B85B81d872281771E6B),
                    IPoolConfigurator(
                        0x7b47e727eC539CB74A744ae5259ef26743294fca
                    ),
                    IAaveOracle(0x520D14AE678b41067f029Ad770E2870F85E76588),
                    IAaveProtocolDataProvider(
                        0x8f57153F18b7273f9A814b93b31Cb3f9b035e7C2
                    ),
                    IACLManager(0x6437b6E14D7ECa1Fa9854df92eB067253D5f683A),
                    0x77c45699A715A64A7a7796d5CEe884cf617D5254,
                    0x3B6E7a4750e478D7f7d6A5d464099A02ef164bCC,
                    0x810d913542D399F3680F0E806DEDf6EACf0e3383
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Fuji)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0x1775ECC8362dB6CaB0c7A9C0957cF656A5276c29
                    ),
                    IPool(0xb47673b7a73D78743AFF1487AF69dBB5763F00cA),
                    IPoolConfigurator(
                        0x01743372F0F0318AaDF690f960A4c6c4eab58782
                    ),
                    IAaveOracle(0xAc6D153BF94aFBdC296e72163735B0f94581F736),
                    IAaveProtocolDataProvider(
                        0x8e0988b28f9CdDe0134A206dfF94111578498C63
                    ),
                    IACLManager(0xAa6Fd640173bcA58e5a5CC373531F9038eF3F9e1),
                    0x77c45699A715A64A7a7796d5CEe884cf617D5254,
                    0xBaaCc99123133851Ba2D6d34952aa08CBDf5A4E4,
                    0xFCadBDefd30E11258559Ba239C8a5A8A8D28CB00
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3FantomTestnet)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xE339D30cBa24C70dCCb82B234589E3C83249e658
                    ),
                    IPool(0x771A45a19cE333a19356694C5fc80c76fe9bc741),
                    IPoolConfigurator(
                        0x59B84a6C943dD655D9E3B4024fC6AdC0E3f4Ff60
                    ),
                    IAaveOracle(0xA840C768f7143495790eC8dc2D5f32B71B6Dc113),
                    IAaveProtocolDataProvider(
                        0xCbAcff915f2d10727844ab0f2A4D9768954981e4
                    ),
                    IACLManager(0x94f154aba287b3024fb32386463FC52d488bb09B),
                    0x77c45699A715A64A7a7796d5CEe884cf617D5254,
                    0xF49dA7a22463D140f9f8dc7C91468C8721215496,
                    0x7aaB2c2CC186131851d6B1876D16eDc849846042
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3HarmonyTestnet)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xd19443202328A66875a51560c28276868B8C61C2
                    ),
                    IPool(0x85C1F3f1bB439180f7Bfda9DFD61De82e10bD554),
                    IPoolConfigurator(
                        0xdb903B5a28260E87cF1d8B56740a90Dba1c8fe15
                    ),
                    IAaveOracle(0x29Ff3c19C6853A0b6544b3CC241c360f422aBaD1),
                    IAaveProtocolDataProvider(
                        0xFc7215C9498Fc12b22Bc0ed335871Db4315f03d3
                    ),
                    IACLManager(0x1758d4e6f68166C4B2d9d0F049F33dEB399Daa1F),
                    0x77c45699A715A64A7a7796d5CEe884cf617D5254,
                    0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2,
                    0x85E44420b6137bbc75a85CAB5c9A3371af976FdE
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3OptimismKovan)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xD15d36975A0200D11B8a8964F4F267982D2a1cFe
                    ),
                    IPool(0x139d8F557f70D1903787e929D7C42165c4667229),
                    IPoolConfigurator(
                        0x12F6E19b968e34fEE34763469c7EAf902Af6914B
                    ),
                    IAaveOracle(0xce87225e5A0ABFe6241C6A60158840d509a84B47),
                    IAaveProtocolDataProvider(
                        0x2f733c0389bfF96a3f930Deb2f6DB1d767Cd3215
                    ),
                    IACLManager(0x552626e2E6e35566d53CE0C5Ad97d72E95bC3fc3),
                    0x77c45699A715A64A7a7796d5CEe884cf617D5254,
                    0x733DC8C72B189791B28Dc8c6Fb09D9201b01eF2f,
                    0x9b791f6A34B2C87c360902F050dA5e0075b7A567
                );
        } else revert("Market does not exist");
    }

    function getToken(string calldata market, string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Mumbai))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x9A753f0F7886C9fbF63cF59D0D4423C5eFaCE95B,
                        0xDD4f3Ee61466C4158D394d57f3D4C397E91fBc51,
                        0x333C04243D048836d53b4ACB3c9aE64875699375,
                        0xB18041Ce2439774c4c7BF611a2a635824cE99032
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0xD9E7e5dd6e122dDE11244e14A60f38AbA93097f2,
                        0x3e1608F4Db4b37DDf86536ef441890fE3AA9F2Ea,
                        0x27908f7216Efe649706B68b6a443623D9aaF16D0,
                        0x292f1Cc1BcedCd22E860c7C92D21877774B44C16
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2,
                        0xCdc2854e97798AfDC74BC420BD5060e022D14607,
                        0x01dBEdcb2437c79341cfeC4Cae765C53BE0E6EF7,
                        0xA24A380813FB7E283Acb8221F5E1e3C01052Bc93
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x85E44420b6137bbc75a85CAB5c9A3371af976FdE,
                        0xde230bC95a03b695be69C44b9AA6C0e9dAc1B143,
                        0x5BcBF666e14eCFe6e21686601c5cA7c7fbe674Cf,
                        0xFDf3B7af2Cb32E5ADca11cf54d53D02162e8d622
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0xd575d4047f8c667E064a4ad433D04E25187F40BB,
                        0x685bF4eab23993E94b4CFb9383599c926B66cF57,
                        0xC9Ac53b6ae1C653A54ab0E9D44693E807429aF1F,
                        0xb0c924f61B27cf3C114CBD70def08c62843ebb3F
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0x21C561e551638401b937b03fE5a0a0652B99B7DD,
                        0x6Ca4abE253bd510fCA862b5aBc51211C1E1E8925,
                        0xc601b4d43aF91fE4EAe327a2d2B12f37a568E05B,
                        0x444672831D8E4A2350667C14E007F56BEfFcB79f
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x0AB1917A0cf92cdcf7F7b637EaC3A46BBBE41409,
                        0x50434C5Da807189622Db5fff66379808c58574aD,
                        0x26Df87542C50326A5085764b1F650EF2514776B6,
                        0xb571dcf478E2cC6c0871402fa3Dd4a3C8f6BE66E
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WMATIC"))
            ) {
                return
                    Token(
                        0xb685400156cF3CBE8725958DeAA61436727A30c3,
                        0x89a6AE840b3F8f489418933A220315eeA36d11fF,
                        0xEC59F2FB4EF0C46278857Bf2eC5764485974D17B,
                        0x02a5680AE3b7383854Bf446b1B3Be170E67E689C
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("CRV"))
            ) {
                return
                    Token(
                        0x3e4b51076d7e9B844B92F8c6377087f9cf8C8696,
                        0x4e752fB98b0dCC90b6772f23C52aD33b795dc758,
                        0x4a6F74A19f05529aF7E7e9f00923FFB990aeBE7B,
                        0xB6704e124997030cE773BB35C1Cc154CF5cE06fB
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("SUSHI"))
            ) {
                return
                    Token(
                        0xdDc3C9B8614092e6188A86450c8D597509893E20,
                        0xb7EA2d40B845A1B49E59c9a5f8B6F67b3c48fA04,
                        0x169E542d769137E82E704477aDdfFe89e7FB9b90,
                        0x95230060256d957F852db649B381045ace7983Cc
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("GHST"))
            ) {
                return
                    Token(
                        0x8AaF462990dD5CC574c94C8266208996426A47e7,
                        0x128cB3720f5d220e1E35512917c3c7fFf064A858,
                        0x03d6be9Bc91956A0bc39f515CaA77C8C0f81c3fC,
                        0x1170823EA41B03e2258f228f617cB549C1faDf28
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BAL"))
            ) {
                return
                    Token(
                        0xE3981f4840843D67aF50026d34DA0f7e56A02D69,
                        0x6236bfBfB3b6CDBFC311399BE346d61Ab8ab1094,
                        0xf28E16644C6389b1B6cF03b3120726b1FfAeDC6E,
                        0xB70013Bde95589330F87cE9a5bD06a89Bc26e38d
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DPI"))
            ) {
                return
                    Token(
                        0x56e0507A53Ee252947a1E55D84Dc4032F914DD98,
                        0xf815E724973ff3f5Eedc243eAE1a34D1f2a45e0C,
                        0x2C64B0ef18bC0616291Dc636b1738DbC675C3f0d,
                        0x6bB285977693F47AC6799F0B3B159130018f4c9c
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("EURS"))
            ) {
                return
                    Token(
                        0x302567472401C7c7B50ee7eb3418c375D8E3F728,
                        0xf6AeDD279Aae7361e70030515f56c22A16d81433,
                        0xaB7cDf4C6053873650695352634987BbEe472c05,
                        0x6Fb76894E171eEDF94BB33E650Af90DfdA2c37FC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("JEUR"))
            ) {
                return
                    Token(
                        0xBaaCc99123133851Ba2D6d34952aa08CBDf5A4E4,
                        0x04cdAA74B111b49EF4044455324C0dDb1C2aa783,
                        0xdAc793dc4A6850765F0f55224CC77425e67C2b6e,
                        0x97CD2BA205ff6FF09332892AB216B665793fc39E
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AGEUR"))
            ) {
                return
                    Token(
                        0xFCadBDefd30E11258559Ba239C8a5A8A8D28CB00,
                        0xbC456dc7E6F882DBc7b11da1048eD253F5DB021D,
                        0x706E3AD3F2745722152acc71Da3C76330c2aa258,
                        0x290F8118AAf61e129646F03791227434DFe39669
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Fuji))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0xFc7215C9498Fc12b22Bc0ed335871Db4315f03d3,
                        0xC42f40B7E22bcca66B3EE22F3ACb86d24C997CC2,
                        0xf5934275da36A067CE00b415F0b876fA403A7198,
                        0xCB19d2C32cB4340C67273A5a4f5dD02BCceBbF97
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0x73b4C0C45bfB90FC44D9013FA213eF2C2d908D0A,
                        0x210a3f864812eAF7f89eE7337EAA1FeA1830C57e,
                        0x0DDD3C8dfA22d4B5e5Dc086f87d94e4180dAC38D,
                        0x1f59c8D4C97E172e42dc3cF62E75464b7e0205bf
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x3E937B4881CBd500d05EeDAB7BA203f2b7B3f74f,
                        0xA79570641bC9cbc6522aA80E2de03bF9F7fd123a,
                        0xC168dB86f93F97652462ded450B3Ad5eA9669df2,
                        0x796eF05488765B4DeAd23B3C7b9F295139049879
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x09C85Ef96e93f0ae892561052B48AE9DB29F2458,
                        0x07B2C0b69c70e89C94A20A555Ab376E5a6181eE6,
                        0xdfBa66e02c4915708e7Df3C26843D5A3492727d9,
                        0x9731B6e01222a0772926455e4aEBa3d1ef690F24
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x28A8E6e41F84e62284970E4bc0867cEe2AAd0DA4,
                        0x618922b15a1a92652818473741531eE255f68741,
                        0xBA932F4F400204c7a05bDF06c6fcA8c114e39d8c,
                        0x800408b3a399d50fAbB064CB04C205910194017C
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xD90db1ca5A6e9873BCD9B0279AE038272b656728,
                        0x3a7e85a86F952CB61485e2D20BDDb6e15204744f,
                        0xB66d28fd0FF446aB504dEF6C2BCd0ef5c0AADdD3,
                        0x5CC87B358742407E563A6cB665Ce28a6937eAe29
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0xCcbBaf8D40a5C34bf1c836e8dD33c7B7646706C5,
                        0xE9C1731e1186362E2ba233BC16614b2a53ecb3F2,
                        0x118369DcFb3Dfaa36Ad424AF26247c2D91CA1262,
                        0x1447a3924BE947CE32b1d4045DAE8F99B894CC61
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WAVAX"))
            ) {
                return
                    Token(
                        0x407287b03D1167593AF113d32093942be13A535f,
                        0xC50E6F9E8e6CAd53c42ddCB7A42d616d7420fd3e,
                        0xaB73C7267347a8dc4d34f9969663E7a64B578C69,
                        0xE21840302317b265dB7E530667ACb31188655cA2
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3FantomTestnet))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0xc469ff24046779DE9B61Be7b5DF91dbFfdF1AE02,
                        0xfb08e04E9c7AfFE693290F739d11D5C3Dd2e19B5,
                        0x87d62612a58a806B926a0A1276DF5C9c6DbE8a5e,
                        0x78243313999d4582cfEE48bD5B4466efF6c90fE1
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0x42Dc50EB0d35A62eac61f4E4Bc81875db9F9366e,
                        0x1A7e068f35B19Ff89B7d646D83Ae15C2Db1D93c5,
                        0x475e4C43caE948578685462F17FB7fedB85E3F79,
                        0x57066BC9569260e9dEC8d224BeB9A8a56209Ff64
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x06f0790c687A1bED6186ce3624EDD9806edf9F4E,
                        0xf1090cB4f56fDb659D24DDbC4972bE9D379A6E8c,
                        0x7e90CE7a0463cc5656c38B5a85C33dF4C8F2523C,
                        0x946765C86B534D8114475BFec8De8De481bA4d1F
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0xd0404A349A76CD2a4B7AB322B9a6C993dbC3A7E7,
                        0xd2ecf7aA363A9dE20088eF1a92D76D4147828B58,
                        0x7e72682d8c90A1eeE1403730f31DCf81551C5aFA,
                        0x68C3E2eb8F2550E13328B4a9cccac65Ba6C200Be
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x2aF63215417F90bd45608115452d86D0a1bEAE5E,
                        0xd29fF48d6Fc110fe227286D5A509a4CB6503732E,
                        0xfD7D3f98aF173B18e5A98fE3b1aE530edab1a988,
                        0x27dF3D6eF22A6aC1c8744Fd7A4516a4C8B22084f
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0x1b901d3C9D4ce153326BEeC60e0D4A2e8a9e3cE3,
                        0x1364B761d75E348B861D7EFaEB64A5b3a37965ec,
                        0xCcE4E4c5327870EfD280645B5a24A50dC01125a4,
                        0x81Ed0a1D00841B68C6F3956E4E210EFaaeBEBAF1
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x2a6202B83Bd2562d7460F91E9298abC27a2F0a95,
                        0xeCbA9a45fDb849548F3e7a621fcBa4f11b3BBDcF,
                        0x460d55849094CDcc8c9582Cf4B58485C08405Ae7,
                        0xe90400D7D8acdCcC8c335883097A722AB653890D
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WFTM"))
            ) {
                return
                    Token(
                        0xF7475b635EbE06d9C5178CC40D50856Fa98C7332,
                        0x22FDD5F19C49fe954847A6424E4a24C2742fD9EF,
                        0x67196249e5fE6c2f532ff456E342Abf8eE19D4E3,
                        0x812388F32346e99078B987e84f60dA68348Ac665
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("CRV"))
            ) {
                return
                    Token(
                        0xAC1a9503D1438B56BAa99939D44555FC2dC286Fc,
                        0x552f5C364090B954ADA025f0D7963D0a7A60d52b,
                        0x48Cf4cA307f321f0FC24bfAe3119f9abF6B32Ff5,
                        0xe4CFEa97831CB0d95CA22597e02dD793bB8f45ae
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("SUSHI"))
            ) {
                return
                    Token(
                        0x484b87Aa284f51e71F15Eba1aEb06dFD202D5511,
                        0x6cC739A29b8Eb06981B8bbF22464E4F3f082bBA5,
                        0x5f933d8c8fbc9651f3E6bC0652d94fdd09EA139a,
                        0x5522dFE4b4056BA819D8e675e6999011A31BAf7a
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3HarmonyTestnet))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x302567472401C7c7B50ee7eb3418c375D8E3F728,
                        0xF5C62a60A2065D34b601CAfF8775F5A2857A9088,
                        0x88d8a116C758C782985DAD67798666e270F0F1a8,
                        0xDD81Dec96a2e4c5221fe11854a32F37C49C1a72A
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0xBaaCc99123133851Ba2D6d34952aa08CBDf5A4E4,
                        0xd5Bc03707A290BAaB91FeFBAf397Fe90EE48Cc39,
                        0xE052c9c02cd4949832cAC20A91B8cf7C59cDd93b,
                        0x2DE29943BbFA3740C1C3C9532E61e3489b2f742A
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0xFCadBDefd30E11258559Ba239C8a5A8A8D28CB00,
                        0xf58153a81DbC7118a8Ad128024996E68dcDEE8B2,
                        0x7C50b2Fb765D77547B7a9F44364308FeEE7526D6,
                        0x6bA6869B3B16a2478EAc78010e4c0DB534Fd79F2
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0xc1eB89DA925cc2Ae8B36818d26E12DDF8F8601b0,
                        0x9D6a5051882C1DFA7d26Cb862a13843c1fe0EF0A,
                        0x478FE510965e607C95EB52c91FB711c8006483B9,
                        0x4953fFBeD89EfE9DC6B4Fe51f74924D6A9b7Ce4e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6,
                        0x7916c8E4d5B3C998B7e8d94bEE3625D0996dA3CC,
                        0x348d1F7BC7FF6803AB96e51B846069Fc1F74F8E5,
                        0x87c271682553fBe445331C872D991c463091f625
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0x2A9534682aF7e07bA9615e15dd9d88968173F6c3,
                        0xAe8c5CfF5D96c36372378A4eFEBcaE78e3552AD9,
                        0xd6D10CEfD2E8A94B5B4Bd3D7B3F2d1cE39c0508c,
                        0xAe2A7BCEF650E798c8911a375bDcec248acbeEC9
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x407287b03D1167593AF113d32093942be13A535f,
                        0xAf16e6F087bb99aEf830409228CCcf8B039C758D,
                        0xCd5327194e4e95C4AECf863904FA80a8522c7C97,
                        0x0F8801a7a8964EA79a504EBa454CbAfF793feED7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WONE"))
            ) {
                return
                    Token(
                        0x3e4b51076d7e9B844B92F8c6377087f9cf8C8696,
                        0xA6a1ec235B90e0b5567521F52e5418B9BA189334,
                        0xdBb47093f92090Ec0E1B3CDC48fAFB52Ea185403,
                        0xB344989ff1717549221AF8525110421e4955857b
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3OptimismKovan))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0xd6B095c27bDf158C462AaB8Cb947BdA9351C0e1d,
                        0x4cdb5D85687Fa162446c7Cf263f9be9614E6314B,
                        0xF7f1a6f7A614b12F2f3bcc8a2e0952B2c6bF283d,
                        0x4F02eD54a25CD9D5bc3432f4bD82f39655A9F4bD
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0xFbBCcCCA95b5F676D8f044Ec75e7eA5899280efF,
                        0x70713F22F01f0053803F1520d526a2C7b26b318a,
                        0x2074341b6880f6B7FC4f3B2B3B15ef91712182E6,
                        0x36B43B427a618cb2Dda78bEc36B7ed7d0b193071
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x9cCc44Aa7C301b6655ec9891BdaD20fa6eb2b552,
                        0x0849Cd326DC590bF313a0b1E5a04790CBb4eE387,
                        0xE953b08a7908921e179187bAf7dFb4e36f9b40CA,
                        0x3cB29D1F440d7ffADACCd57762c1332CF7Db9e6c
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0xfF5b900f020d663719EEE1731C21778632e6C424,
                        0x2D89bE7Cfbe21ed728A5AeDdA03cACFCAf04aA08,
                        0x4c9D6192E7920b2C56400aBFa8909EC7A572a315,
                        0x5a9BaC403F9034852Ed18613Ecac81A1FaE2AdF3
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x46e213C62d4734C64986879af00eEc5128395776,
                        0xCb5Df0b49BCa05B2478a606074ec39e3fa181a6f,
                        0x52B61cD2CbC22A386a8F5d2Cec685e938A0379BB,
                        0x90De0e1eBDBfDb421F79D26EccE37cE1Aa84bbA6
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xeE6b5ad81c7d88a632b24Bcdac055D6f5F469495,
                        0x98A978662670A35cA2b4aD12319486a3F294a78b,
                        0x1b187f0e91934c94aFb324cD9cd03FBa0C7a8B71,
                        0x163F2F60F99090E1fF7d7eC768dA0BA77Dd50547
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0xb532118d86765Eb544958e47df77bb8bDDe2F096,
                        0x5994ce8E7F595AFE3115D72854e0EAeCbD902ea7,
                        0xBe7c6a35A2932411A379081a745bcb99d83574EC,
                        0xb45966470789847E7bC73E2aEdFefff96c86F821
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("SUSD"))
            ) {
                return
                    Token(
                        0x6883D765088f90bAE62048dE45f2202D72985B01,
                        0xE603E221fa3a858BdAE91FB51cE09BA6C53B19A5,
                        0xF864A79eE389859A33DA2CDec69fb1d723dB319B,
                        0xd3a31fD51e6F0Ca6b4a083e05893bfC6e294cb30
                    );
            } else revert("Token does not exist");
        } else revert("Market does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, IACLManager} from "./AaveV3.sol";
import {Token} from "./Common.sol";

library AaveAddressBookV3 {
    string public constant AaveV3Polygon = "AaveV3Polygon";
    string public constant AaveV3Avalanche = "AaveV3Avalanche";
    string public constant AaveV3Arbitrum = "AaveV3Arbitrum";
    string public constant AaveV3Fantom = "AaveV3Fantom";
    string public constant AaveV3Harmony = "AaveV3Harmony";
    string public constant AaveV3Optimism = "AaveV3Optimism";

    struct Market {
        IPoolAddressesProvider POOL_ADDRESSES_PROVIDER;
        IPool POOL;
        IPoolConfigurator POOL_CONFIGURATOR;
        IAaveOracle ORACLE;
        IAaveProtocolDataProvider POOL_DATA_PROVIDER;
        IACLManager ACL_MANAGER;
        address ACL_ADMIN;
        address COLLECTOR;
        address COLLECTOR_CONTROLLER;
    }

    function getMarket(string calldata market)
        public
        pure
        returns (Market memory m)
    {
        if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Polygon)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
                    ),
                    IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD),
                    IPoolConfigurator(
                        0x8145eddDf43f50276641b55bd3AD95944510021E
                    ),
                    IAaveOracle(0xb023e699F5a33916Ea823A16485e259257cA8Bd1),
                    IAaveProtocolDataProvider(
                        0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654
                    ),
                    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B),
                    0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772,
                    0xe8599F3cc5D38a9aD6F3684cd5CEa72f10Dbc383,
                    0x73D435AFc15e35A9aC63B2a81B5AA54f974eadFe
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Avalanche)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
                    ),
                    IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD),
                    IPoolConfigurator(
                        0x8145eddDf43f50276641b55bd3AD95944510021E
                    ),
                    IAaveOracle(0xEBd36016B3eD09D4693Ed4251c67Bd858c3c7C9C),
                    IAaveProtocolDataProvider(
                        0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654
                    ),
                    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B),
                    0xa35b76E4935449E33C56aB24b23fcd3246f13470,
                    0x5ba7fd868c40c16f7aDfAe6CF87121E13FC2F7a0,
                    0xaCbE7d574EF8dC39435577eb638167Aca74F79f0
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Arbitrum)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
                    ),
                    IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD),
                    IPoolConfigurator(
                        0x8145eddDf43f50276641b55bd3AD95944510021E
                    ),
                    IAaveOracle(0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7),
                    IAaveProtocolDataProvider(
                        0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654
                    ),
                    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B),
                    0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb,
                    0x053D55f9B5AF8694c503EB288a1B7E552f590710,
                    0xC3301b30f4EcBfd59dE0d74e89690C1a70C6f21B
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Fantom)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
                    ),
                    IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD),
                    IPoolConfigurator(
                        0x8145eddDf43f50276641b55bd3AD95944510021E
                    ),
                    IAaveOracle(0xfd6f3c1845604C8AE6c6E402ad17fb9885160754),
                    IAaveProtocolDataProvider(
                        0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654
                    ),
                    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B),
                    0x39CB97b105173b56b5a2b4b33AD25d6a50E6c949,
                    0xBe85413851D195fC6341619cD68BfDc26a25b928,
                    0xc0F0cFBbd0382BcE3B93234E4BFb31b2aaBE36aD
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Harmony)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
                    ),
                    IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD),
                    IPoolConfigurator(
                        0x8145eddDf43f50276641b55bd3AD95944510021E
                    ),
                    IAaveOracle(0x3C90887Ede8D65ccb2777A5d577beAb2548280AD),
                    IAaveProtocolDataProvider(
                        0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654
                    ),
                    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B),
                    0xb2f0C5f37f4beD2cB51C44653cD5D84866BDcd2D,
                    0x8A020d92D6B119978582BE4d3EdFdC9F7b28BF31,
                    0xeaC16519923774Fd7723d3D5E442a1e2E46BA962
                );
        } else if (
            keccak256(abi.encodePacked((market))) ==
            keccak256(abi.encodePacked((AaveV3Optimism)))
        ) {
            return
                Market(
                    IPoolAddressesProvider(
                        0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
                    ),
                    IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD),
                    IPoolConfigurator(
                        0x8145eddDf43f50276641b55bd3AD95944510021E
                    ),
                    IAaveOracle(0xD81eb3728a631871a7eBBaD631b5f424909f0c77),
                    IAaveProtocolDataProvider(
                        0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654
                    ),
                    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B),
                    0xE50c8C619d05ff98b22Adf991F17602C774F785c,
                    0xB2289E329D2F85F1eD31Adbb30eA345278F21bcf,
                    0xA77E4A084d7d4f064E326C0F6c0aCefd47A5Cb21
                );
        } else revert("Market does not exist");
    }

    function getToken(string calldata market, string calldata symbol)
        public
        pure
        returns (Token memory m)
    {
        if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Polygon))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                        0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                        0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39,
                        0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                        0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                        0x953A573793604aF8d41F306FEb8274190dB4aE0e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
                        0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                        0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                        0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6,
                        0x078f358208685046a11C85e8ad32895DED33A249,
                        0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                        0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619,
                        0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                        0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                        0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
                        0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                        0x70eFfc565DB6EEf7B927610155602d31b670e802,
                        0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0xD6DF932A45C0f255f85145f286eA0b292B21C90B,
                        0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                        0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                        0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WMATIC"))
            ) {
                return
                    Token(
                        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
                        0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                        0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                        0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("CRV"))
            ) {
                return
                    Token(
                        0x172370d5Cd63279eFa6d502DAB29171933a610AF,
                        0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf,
                        0x08Cb71192985E936C7Cd166A8b268035e400c3c3,
                        0x77CA01483f379E58174739308945f044e1a764dc
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("SUSHI"))
            ) {
                return
                    Token(
                        0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a,
                        0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA,
                        0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841,
                        0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("GHST"))
            ) {
                return
                    Token(
                        0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7,
                        0x8Eb270e296023E9D92081fdF967dDd7878724424,
                        0x3EF10DFf4928279c004308EbADc4Db8B7620d6fc,
                        0xCE186F6Cccb0c955445bb9d10C59caE488Fea559
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BAL"))
            ) {
                return
                    Token(
                        0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3,
                        0x8ffDf2DE812095b1D19CB146E4c004587C0A0692,
                        0xa5e408678469d23efDB7694b1B0A85BB0669e8bd,
                        0xA8669021776Bc142DfcA87c21b4A52595bCbB40a
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DPI"))
            ) {
                return
                    Token(
                        0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369,
                        0x724dc807b04555b71ed48a6896b6F41593b8C637,
                        0xDC1fad70953Bb3918592b6fCc374fe05F5811B6a,
                        0xf611aEb5013fD2c0511c9CD55c7dc5C1140741A6
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("EURS"))
            ) {
                return
                    Token(
                        0xE111178A87A3BFf0c8d18DECBa5798827539Ae99,
                        0x38d693cE1dF5AaDF7bC62595A37D667aD57922e5,
                        0x8a9FdE6925a839F6B1932d16B36aC026F8d3FbdB,
                        0x5D557B07776D12967914379C71a1310e917C7555
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("jEUR"))
            ) {
                return
                    Token(
                        0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c,
                        0x6533afac2E7BCCB20dca161449A13A32D391fb00,
                        0x6B4b37618D85Db2a7b469983C888040F7F05Ea3D,
                        0x44705f578135cC5d703b4c9c122528C73Eb87145
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("agEUR"))
            ) {
                return
                    Token(
                        0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4,
                        0x8437d7C167dFB82ED4Cb79CD44B7a32A1dd95c77,
                        0x40B4BAEcc69B882e8804f9286b12228C27F8c9BF,
                        0x3ca5FA07689F266e907439aFd1fBB59c44fe12f6
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Avalanche))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI.e"))
            ) {
                return
                    Token(
                        0xd586E7F844cEa2F87f50152665BCbc2C279D8d70,
                        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                        0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                        0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK.e"))
            ) {
                return
                    Token(
                        0x5947BB275c521040051D82396192181b413227A3,
                        0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                        0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                        0x953A573793604aF8d41F306FEb8274190dB4aE0e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E,
                        0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                        0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                        0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC.e"))
            ) {
                return
                    Token(
                        0x50b7545627a5162F82A992c33b87aDc75187B218,
                        0x078f358208685046a11C85e8ad32895DED33A249,
                        0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                        0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH.e"))
            ) {
                return
                    Token(
                        0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB,
                        0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                        0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                        0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDt"))
            ) {
                return
                    Token(
                        0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7,
                        0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                        0x70eFfc565DB6EEf7B927610155602d31b670e802,
                        0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE.e"))
            ) {
                return
                    Token(
                        0x63a72806098Bd3D9520cC43356dD78afe5D386D9,
                        0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                        0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                        0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WAVAX"))
            ) {
                return
                    Token(
                        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,
                        0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                        0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                        0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("sAVAX"))
            ) {
                return
                    Token(
                        0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE,
                        0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf,
                        0x08Cb71192985E936C7Cd166A8b268035e400c3c3,
                        0x77CA01483f379E58174739308945f044e1a764dc
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Arbitrum))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
                        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                        0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                        0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
                        0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                        0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                        0x953A573793604aF8d41F306FEb8274190dB4aE0e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8,
                        0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                        0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                        0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
                        0x078f358208685046a11C85e8ad32895DED33A249,
                        0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                        0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
                        0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                        0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                        0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
                        0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                        0x70eFfc565DB6EEf7B927610155602d31b670e802,
                        0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0xba5DdD1f9d7F570dc94a51479a000E3BCE967196,
                        0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                        0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                        0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("EURS"))
            ) {
                return
                    Token(
                        0xD22a58f79e9481D1a88e00c343885A588b34b68B,
                        0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                        0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                        0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Fantom))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E,
                        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                        0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                        0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8,
                        0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                        0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                        0x953A573793604aF8d41F306FEb8274190dB4aE0e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x04068DA6C83AFCFA0e13ba15A6696662335D5B75,
                        0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                        0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                        0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("BTC"))
            ) {
                return
                    Token(
                        0x321162Cd933E2Be498Cd2267a90534A804051b11,
                        0x078f358208685046a11C85e8ad32895DED33A249,
                        0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                        0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("ETH"))
            ) {
                return
                    Token(
                        0x74b23882a30290451A17c44f4F05243b6b58C76d,
                        0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                        0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                        0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("fUSDT"))
            ) {
                return
                    Token(
                        0x049d68029688eAbF473097a2fC38ef61633A3C7A,
                        0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                        0x70eFfc565DB6EEf7B927610155602d31b670e802,
                        0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x6a07A792ab2965C72a5B8088d3a069A7aC3a993B,
                        0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                        0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                        0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WFTM"))
            ) {
                return
                    Token(
                        0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83,
                        0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                        0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                        0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("CRV"))
            ) {
                return
                    Token(
                        0x1E4F97b9f9F913c46F1632781732927B9019C68b,
                        0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf,
                        0x08Cb71192985E936C7Cd166A8b268035e400c3c3,
                        0x77CA01483f379E58174739308945f044e1a764dc
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("SUSHI"))
            ) {
                return
                    Token(
                        0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC,
                        0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA,
                        0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841,
                        0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Harmony))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("1DAI"))
            ) {
                return
                    Token(
                        0xEf977d2f931C1978Db5F6747666fa1eACB0d0339,
                        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                        0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                        0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0x218532a12a389a4a92fC0C5Fb22901D1c19198aA,
                        0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                        0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                        0x953A573793604aF8d41F306FEb8274190dB4aE0e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("1USDC"))
            ) {
                return
                    Token(
                        0x985458E523dB3d53125813eD68c274899e9DfAb4,
                        0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                        0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                        0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("1WBTC"))
            ) {
                return
                    Token(
                        0x3095c7557bCb296ccc6e363DE01b760bA031F2d9,
                        0x078f358208685046a11C85e8ad32895DED33A249,
                        0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                        0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("1ETH"))
            ) {
                return
                    Token(
                        0x6983D1E6DEf3690C4d616b13597A09e6193EA013,
                        0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                        0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                        0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("1USDT"))
            ) {
                return
                    Token(
                        0x3C2B8Be99c50593081EAA2A724F0B8285F5aba8f,
                        0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                        0x70eFfc565DB6EEf7B927610155602d31b670e802,
                        0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("1AAVE"))
            ) {
                return
                    Token(
                        0xcF323Aad9E522B93F11c352CaA519Ad0E14eB40F,
                        0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                        0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                        0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WONE"))
            ) {
                return
                    Token(
                        0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a,
                        0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                        0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                        0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                    );
            } else revert("Token does not exist");
        } else if (
            keccak256(abi.encodePacked(market)) ==
            keccak256(abi.encodePacked(AaveV3Optimism))
        ) {
            if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("DAI"))
            ) {
                return
                    Token(
                        0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
                        0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE,
                        0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B,
                        0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("LINK"))
            ) {
                return
                    Token(
                        0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6,
                        0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530,
                        0x89D976629b7055ff1ca02b927BA3e020F22A44e4,
                        0x953A573793604aF8d41F306FEb8274190dB4aE0e
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDC"))
            ) {
                return
                    Token(
                        0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
                        0x625E7708f30cA75bfd92586e17077590C60eb4cD,
                        0x307ffe186F84a3bc2613D1eA417A5737D69A7007,
                        0xFCCf3cAbbe80101232d343252614b6A3eE81C989
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WBTC"))
            ) {
                return
                    Token(
                        0x68f180fcCe6836688e9084f035309E29Bf0A2095,
                        0x078f358208685046a11C85e8ad32895DED33A249,
                        0x633b207Dd676331c413D4C013a6294B0FE47cD0e,
                        0x92b42c66840C7AD907b4BF74879FF3eF7c529473
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("WETH"))
            ) {
                return
                    Token(
                        0x4200000000000000000000000000000000000006,
                        0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8,
                        0xD8Ad37849950903571df17049516a5CD4cbE55F6,
                        0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("USDT"))
            ) {
                return
                    Token(
                        0x94b008aA00579c1307B0EF2c499aD98a8ce58e58,
                        0x6ab707Aca953eDAeFBc4fD23bA73294241490620,
                        0x70eFfc565DB6EEf7B927610155602d31b670e802,
                        0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("AAVE"))
            ) {
                return
                    Token(
                        0x76FB31fb4af56892A25e32cFC43De717950c9278,
                        0xf329e36C7bF6E5E86ce2150875a84Ce77f477375,
                        0xfAeF6A702D15428E588d4C0614AEFb4348D83D48,
                        0xE80761Ea617F66F96274eA5e8c37f03960ecC679
                    );
            } else if (
                keccak256(abi.encodePacked(symbol)) ==
                keccak256(abi.encodePacked("sUSD"))
            ) {
                return
                    Token(
                        0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9,
                        0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97,
                        0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E,
                        0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8
                    );
            } else revert("Token does not exist");
        } else revert("Market does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

struct Token {
  address underlyingAsset;
  address aTokenAddress;
  address stableDebtTokenAddress;
  address variableDebtTokenAddress;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IGovernanceStrategy {
  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber)
    external
    view
    returns (uint256);
}

interface IExecutorWithTimelock {
  /**
   * @dev emitted when a new pending admin is set
   * @param newPendingAdmin address of the new pending admin
   **/
  event NewPendingAdmin(address newPendingAdmin);

  /**
   * @dev emitted when a new admin is set
   * @param newAdmin address of the new admin
   **/
  event NewAdmin(address newAdmin);

  /**
   * @dev emitted when a new delay (between queueing and execution) is set
   * @param delay new delay
   **/
  event NewDelay(uint256 delay);

  /**
   * @dev emitted when a new (trans)action is Queued.
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event QueuedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  event CancelledAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall
  );

  /**
   * @dev emitted when an action is Cancelled
   * @param actionHash hash of the action
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    bytes32 actionHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @dev Getter of the current admin address (should be governance)
   * @return The address of the current admin
   **/
  function getAdmin() external view returns (address);

  /**
   * @dev Getter of the current pending admin address
   * @return The address of the pending admin
   **/
  function getPendingAdmin() external view returns (address);

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view returns (uint256);

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);

  /**
   * @dev Checks whether a proposal is over its grace period
   * @param governance Governance contract
   * @param proposalId Id of the proposal against which to test
   * @return true of proposal is over grace period
   **/
  function isProposalOverGracePeriod(
    IAaveGovernanceV2 governance,
    uint256 proposalId
  ) external view returns (bool);

  /**
   * @dev Getter of grace period constant
   * @return grace period in seconds
   **/
  function GRACE_PERIOD() external view returns (uint256);

  /**
   * @dev Getter of minimum delay constant
   * @return minimum delay in seconds
   **/
  function MINIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Getter of maximum delay constant
   * @return maximum delay in seconds
   **/
  function MAXIMUM_DELAY() external view returns (uint256);

  /**
   * @dev Function, called by Governance, that queue a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external payable returns (bytes memory);

  /**
   * @dev Function, called by Governance, that cancels a transaction, returns action hash
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   **/
  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) external returns (bytes32);
}

interface IAaveGovernanceV2 {
  enum ProposalState {
    Pending,
    Canceled,
    Active,
    Failed,
    Succeeded,
    Queued,
    Expired,
    Executed
  }

  struct Vote {
    bool support;
    uint248 votingPower;
  }

  struct Proposal {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
    mapping(address => Vote) votes;
  }

  struct ProposalWithoutVotes {
    uint256 id;
    address creator;
    IExecutorWithTimelock executor;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 startBlock;
    uint256 endBlock;
    uint256 executionTime;
    uint256 forVotes;
    uint256 againstVotes;
    bool executed;
    bool canceled;
    address strategy;
    bytes32 ipfsHash;
  }

  /**
   * @dev emitted when a new proposal is created
   * @param id Id of the proposal
   * @param creator address of the creator
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   * @param startBlock block number when vote starts
   * @param endBlock block number when vote ends
   * @param strategy address of the governanceStrategy contract
   * @param ipfsHash IPFS hash of the proposal
   **/
  event ProposalCreated(
    uint256 id,
    address indexed creator,
    IExecutorWithTimelock indexed executor,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 startBlock,
    uint256 endBlock,
    address strategy,
    bytes32 ipfsHash
  );

  /**
   * @dev emitted when a proposal is canceled
   * @param id Id of the proposal
   **/
  event ProposalCanceled(uint256 id);

  /**
   * @dev emitted when a proposal is queued
   * @param id Id of the proposal
   * @param executionTime time when proposal underlying transactions can be executed
   * @param initiatorQueueing address of the initiator of the queuing transaction
   **/
  event ProposalQueued(
    uint256 id,
    uint256 executionTime,
    address indexed initiatorQueueing
  );
  /**
   * @dev emitted when a proposal is executed
   * @param id Id of the proposal
   * @param initiatorExecution address of the initiator of the execution transaction
   **/
  event ProposalExecuted(uint256 id, address indexed initiatorExecution);
  /**
   * @dev emitted when a vote is registered
   * @param id Id of the proposal
   * @param voter address of the voter
   * @param support boolean, true = vote for, false = vote against
   * @param votingPower Power of the voter/vote
   **/
  event VoteEmitted(
    uint256 id,
    address indexed voter,
    bool support,
    uint256 votingPower
  );

  event GovernanceStrategyChanged(
    address indexed newStrategy,
    address indexed initiatorChange
  );

  event VotingDelayChanged(
    uint256 newVotingDelay,
    address indexed initiatorChange
  );

  event ExecutorAuthorized(address executor);

  event ExecutorUnauthorized(address executor);

  /**
   * @dev Creates a Proposal (needs Proposition Power of creator > Threshold)
   * @param executor The ExecutorWithTimelock contract that will execute the proposal
   * @param targets list of contracts called by proposal's associated transactions
   * @param values list of value in wei for each propoposal's associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls if true, transaction delegatecalls the taget, else calls the target
   * @param ipfsHash IPFS hash of the proposal
   **/
  function create(
    IExecutorWithTimelock executor,
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls,
    bytes32 ipfsHash
  ) external returns (uint256);

  /**
   * @dev Cancels a Proposal,
   * either at anytime by guardian
   * or when proposal is Pending/Active and threshold no longer reached
   * @param proposalId id of the proposal
   **/
  function cancel(uint256 proposalId) external;

  /**
   * @dev Queue the proposal (If Proposal Succeeded)
   * @param proposalId id of the proposal to queue
   **/
  function queue(uint256 proposalId) external;

  /**
   * @dev Execute the proposal (If Proposal Queued)
   * @param proposalId id of the proposal to execute
   **/
  function execute(uint256 proposalId) external payable;

  /**
   * @dev Function allowing msg.sender to vote for/against a proposal
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   **/
  function submitVote(uint256 proposalId, bool support) external;

  /**
   * @dev Function to register the vote of user that has voted offchain via signature
   * @param proposalId id of the proposal
   * @param support boolean, true = vote for, false = vote against
   * @param v v part of the voter signature
   * @param r r part of the voter signature
   * @param s s part of the voter signature
   **/
  function submitVoteBySignature(
    uint256 proposalId,
    bool support,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Set new GovernanceStrategy
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param governanceStrategy new Address of the GovernanceStrategy contract
   **/
  function setGovernanceStrategy(address governanceStrategy) external;

  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in seconds
   **/
  function setVotingDelay(uint256 votingDelay) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors) external;

  /**
   * @dev Let the guardian abdicate from its priviledged rights
   **/
  function __abdicate() external;

  /**
   * @dev Getter of the current GovernanceStrategy address
   * @return The address of the current GovernanceStrategy contracts
   **/
  function getGovernanceStrategy() external view returns (address);

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in seconds
   **/
  function getVotingDelay() external view returns (uint256);

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

  /**
   * @dev Getter the address of the guardian, that can mainly cancel proposals
   * @return The address of the guardian
   **/
  function getGuardian() external view returns (address);

  /**
   * @dev Getter of the proposal count (the current number of proposals ever created)
   * @return the proposal count
   **/
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev Getter of a proposal by id
   * @param proposalId id of the proposal to get
   * @return the proposal as ProposalWithoutVotes memory object
   **/
  function getProposalById(uint256 proposalId)
    external
    view
    returns (ProposalWithoutVotes memory);

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({bool support, uint248 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter)
    external
    view
    returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId)
    external
    view
    returns (ProposalState);
}

library AaveGovernanceV2 {
  IAaveGovernanceV2 internal constant GOV =
    IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);

  address public constant SHORT_EXECUTOR =
    0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address public constant LONG_EXECUTOR =
    0x61910EcD7e8e942136CE7Fe7943f956cea1CC2f7;

  address public constant ARC_TIMELOCK =
    0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }
}

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string underlyingAssetName;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(
    address indexed reserve,
    address indexed user,
    address indexed to,
    uint256 amount
  );

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(
    address reserve,
    address rateStrategyAddress
  ) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider()
    external
    view
    returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

interface ILendingPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableRateEnabled True if stable rate borrowing is enabled, false otherwise
   **/
  event BorrowingEnabledOnReserve(
    address indexed asset,
    bool stableRateEnabled
  );

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when stable rate borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated
   * @param asset The address of the underlying asset of the reserve
   * @param factor The new reserve factor
   **/
  event ReserveFactorChanged(address indexed asset, uint256 factor);

  /**
   * @dev Emitted when the reserve decimals are updated
   * @param asset The address of the underlying asset of the reserve
   * @param decimals The new decimals
   **/
  event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

  /**
   * @dev Emitted when a reserve interest strategy contract is updated
   * @param asset The address of the underlying asset of the reserve
   * @param strategy The new address of the interest strategy contract
   **/
  event ReserveInterestRateStrategyChanged(
    address indexed asset,
    address strategy
  );

  /**
   * @dev Emitted when an aToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   **/
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Initializes a reserve
   * @param aTokenImpl  The address of the aToken contract implementation
   * @param stableDebtTokenImpl The address of the stable debt token contract
   * @param variableDebtTokenImpl The address of the variable debt token contract
   * @param underlyingAssetDecimals The decimals of the reserve underlying asset
   * @param interestRateStrategyAddress The address of the interest rate strategy contract for this reserve
   **/
  function initReserve(
    address aTokenImpl,
    address stableDebtTokenImpl,
    address variableDebtTokenImpl,
    uint8 underlyingAssetDecimals,
    address interestRateStrategyAddress
  ) external;

  function batchInitReserve(
    ConfiguratorInputTypes.InitReserveInput[] calldata input
  ) external;

  /**
   * @dev Updates the aToken implementation for the reserve
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateAToken(address asset, address implementation) external;

  /**
   * @dev Updates the stable debt token implementation for the reserve
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateStableDebtToken(address asset, address implementation)
    external;

  /**
   * @dev Updates the variable debt token implementation for the asset
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateVariableDebtToken(address asset, address implementation)
    external;

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
   **/
  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled)
    external;

  /**
   * @dev Disables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableBorrowingOnReserve(address asset) external;

  /**
   * @dev Configures the reserve collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset. The values is always above 100%. A value of 105%
   * means the liquidator will receive a 5% bonus
   **/
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @dev Enable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function enableReserveStableRate(address asset) external;

  /**
   * @dev Disable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableReserveStableRate(address asset) external;

  /**
   * @dev Activates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function activateReserve(address asset) external;

  /**
   * @dev Deactivates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function deactivateReserve(address asset) external;

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap
   *  but allows repayments, liquidations, rate rebalances and withdrawals
   * @param asset The address of the underlying asset of the reserve
   **/
  function freezeReserve(address asset) external;

  /**
   * @dev Unfreezes a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function unfreezeReserve(address asset) external;

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external;

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @dev pauses or unpauses all the actions of the protocol, including aToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external;
}

interface IAaveOracle {
  event WethSet(address indexed weth);
  event AssetSourceUpdated(address indexed asset, address indexed source);
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /// @notice Returns the WETH address (reference asset of the oracle)
  function WETH() external returns (address);

  /// @notice External function called by the Aave governance to set or replace sources of assets
  /// @param assets The addresses of the assets
  /// @param sources The address of the source of each asset
  function setAssetSources(
    address[] calldata assets,
    address[] calldata sources
  ) external;

  /// @notice Sets the fallbackOracle
  /// - Callable only by the Aave governance
  /// @param fallbackOracle The address of the fallbackOracle
  function setFallbackOracle(address fallbackOracle) external;

  /// @notice Gets an asset price by address
  /// @param asset The asset address
  function getAssetPrice(address asset) external view returns (uint256);

  /// @notice Gets a list of prices from a list of assets addresses
  /// @param assets The list of assets addresses
  function getAssetsPrices(address[] calldata assets)
    external
    view
    returns (uint256[] memory);

  /// @notice Gets the address of the source for an asset address
  /// @param asset The address of the asset
  /// @return address The address of the source
  function getSourceOfAsset(address asset) external view returns (address);

  /// @notice Gets the address of the fallback oracle
  /// @return address The addres of the fallback oracle
  function getFallbackOracle() external view returns (address);
}

struct TokenData {
  string symbol;
  address tokenAddress;
}

// TODO: incomplete interface
interface IAaveProtocolDataProvider {
  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getAllReservesTokens() external view returns (TokenData[] memory);

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );
}