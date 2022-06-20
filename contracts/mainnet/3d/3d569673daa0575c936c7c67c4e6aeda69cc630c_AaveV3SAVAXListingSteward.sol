/**
 *Submitted for verification at snowtrace.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

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
}

/**
 * @title IPoolConfigurator
 * @author Aave
 * @notice Defines the basic interface for a Pool configurator.
 **/
interface IPoolConfigurator {
    /**
     * @notice Initializes multiple reserves.
     * @param input The array of initialization parameters
     **/
    function initReserves(
        ConfiguratorInputTypes.InitReserveInput[] calldata input
    ) external;

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
     * @notice Updates the reserve factor of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newReserveFactor The new reserve factor of the reserve
     **/
    function setReserveFactor(address asset, uint256 newReserveFactor) external;

    /**
     * @notice Updates the supply cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newSupplyCap The new supply cap of the reserve
     **/
    function setSupplyCap(address asset, uint256 newSupplyCap) external;

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
     * @notice Updates the liquidation protocol fee of reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
     **/
    function setLiquidationProtocolFee(address asset, uint256 newFee) external;
}

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
    function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

    function RISK_ADMIN_ROLE() external view returns (bytes32);

    function addAssetListingAdmin(address admin) external;

    function addRiskAdmin(address admin) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @title IAaveOracle
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IAaveOracle {
    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external;
}

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);
}

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

/**
 * @dev One-time-use helper contract to be used by Aave Guardians (Gnosis Safe generally) to list new assets:
 * - Guardian should be the `owner`, for extra security, even if theoretically `listAssetAddingOracle` could be open.
 * - It pre-requires to have risk admin and asset listings role.
 * - It lists a new price feed on the AaveOracle.
 * - Adds a new e-mode.
 * - Lists the asset using the PoolConfigurator.
 * - Renounces to risk admin and asset listing roles.
 */
contract AaveV3SAVAXListingSteward is Ownable {
    // **************************
    // Protocol's contracts
    // **************************

    IPoolAddressesProvider public constant ADDRESSES_PROVIDER =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    address public constant AAVE_AVALANCHE_TREASURY =
        0x5ba7fd868c40c16f7aDfAe6CF87121E13FC2F7a0;
    address public constant INCENTIVES_CONTROLLER =
        0x929EC64c34a17401F460460D4B9390518E5B473e;

    // **************************
    // New eMode category (AVAX-like)
    // **************************

    uint8 public constant NEW_EMODE_ID = 2;
    uint16 public constant NEW_EMODE_LTV = 9250; // 92.5%
    uint16 public constant NEW_EMODE_LIQ_THRESHOLD = 9500; // 95%
    uint16 public constant NEW_EMODE_LIQ_BONUS = 10100; // 1%
    address public constant NEW_EMODE_ORACLE = address(0); // No custom oracle
    string public constant NEW_EMODE_LABEL = 'AVAX correlated';

    // **************************
    // New asset being listed (SAVAX)
    // **************************

    address public constant SAVAX = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    uint8 public constant SAVAX_DECIMALS = 18;
    string public constant ASAVAX_NAME = 'Aave Avalanche SAVAX';
    string public constant ASAVAX_SYMBOL = 'aAvaSAVAX';
    string public constant VDSAVAX_NAME = 'Aave Avalanche Variable Debt SAVAX';
    string public constant VDSAVAX_SYMBOL = 'variableDebtAvaSAVAX';
    string public constant SDSAVAX_NAME = 'Aave Avalanche Stable Debt SAVAX';
    string public constant SDSAVAX_SYMBOL = 'stableDebtAvaSAVAX';
    address public constant ATOKEN_IMPL =
        0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;
    address public constant VDTOKEN_IMPL =
        0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;
    address public constant SDTOKEN_IMPL =
        0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;
    address public constant RATE_STRATEGY =
        0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;
    address public constant SAVAX_PRICE_FEED =
        0xc9245871D69BF4c36c6F2D15E0D68Ffa883FE1A7;
    uint256 public constant LTV = 2000; // 20%
    uint256 public constant LIQ_THRESHOLD = 3000; // 30%
    uint256 public constant LIQ_BONUS = 11000; // 10%
    uint256 public constant SUPPLY_CAP = 500_000; // ~$8.8m at price of 17/06/2022
    uint256 public constant RESERVE_FACTOR = 1000; // 10%
    uint256 public constant LIQ_PROTOCOL_FEE = 1000; // 10%

    function listAssetAddingOracle() external onlyOwner {
        // ----------------------------
        // 1. New price feed on oracle
        // ----------------------------

        require(SAVAX_PRICE_FEED != address(0), 'INVALID_PRICE_FEED');

        address[] memory assets = new address[](1);
        assets[0] = SAVAX;
        address[] memory sources = new address[](1);
        sources[0] = SAVAX_PRICE_FEED;

        IAaveOracle(ADDRESSES_PROVIDER.getPriceOracle()).setAssetSources(
            assets,
            sources
        );

        // -----------------------------------------
        // 2. Creation of new eMode on the Aave Pool
        // -----------------------------------------

        IPoolConfigurator configurator = IPoolConfigurator(
            ADDRESSES_PROVIDER.getPoolConfigurator()
        );

        configurator.setEModeCategory(
            NEW_EMODE_ID,
            NEW_EMODE_LTV,
            NEW_EMODE_LIQ_THRESHOLD,
            NEW_EMODE_LIQ_BONUS,
            address(0),
            NEW_EMODE_LABEL
        );

        // ------------------------------------------------
        // 3. Listing of sAVAX, with all its configurations
        // ------------------------------------------------

        ConfiguratorInputTypes.InitReserveInput[]
            memory initReserveInputs = new ConfiguratorInputTypes.InitReserveInput[](
                1
            );
        initReserveInputs[0] = ConfiguratorInputTypes.InitReserveInput({
            aTokenImpl: ATOKEN_IMPL,
            stableDebtTokenImpl: SDTOKEN_IMPL,
            variableDebtTokenImpl: VDTOKEN_IMPL,
            underlyingAssetDecimals: SAVAX_DECIMALS,
            interestRateStrategyAddress: RATE_STRATEGY,
            underlyingAsset: SAVAX,
            treasury: AAVE_AVALANCHE_TREASURY,
            incentivesController: INCENTIVES_CONTROLLER,
            aTokenName: ASAVAX_NAME,
            aTokenSymbol: ASAVAX_SYMBOL,
            variableDebtTokenName: VDSAVAX_NAME,
            variableDebtTokenSymbol: VDSAVAX_SYMBOL,
            stableDebtTokenName: SDSAVAX_NAME,
            stableDebtTokenSymbol: SDSAVAX_SYMBOL,
            params: bytes('')
        });

        configurator.initReserves(initReserveInputs);

        configurator.setSupplyCap(SAVAX, SUPPLY_CAP);

        configurator.configureReserveAsCollateral(
            SAVAX,
            LTV,
            LIQ_THRESHOLD,
            LIQ_BONUS
        );

        configurator.setAssetEModeCategory(SAVAX, NEW_EMODE_ID);

        configurator.setReserveFactor(SAVAX, RESERVE_FACTOR);

        configurator.setLiquidationProtocolFee(SAVAX, LIQ_PROTOCOL_FEE);

        // ---------------------------------------------------------------
        // 4. This contract renounces to both listing and risk admin roles
        // ---------------------------------------------------------------
        IACLManager aclManager = IACLManager(
            ADDRESSES_PROVIDER.getACLManager()
        );

        aclManager.renounceRole(
            aclManager.ASSET_LISTING_ADMIN_ROLE(),
            address(this)
        );
        aclManager.renounceRole(aclManager.RISK_ADMIN_ROLE(), address(this));

        // ---------------------------------------------------------------
        // 4. Removal of owner, to disallow any other call of this function
        // ---------------------------------------------------------------

        _transferOwnership(address(0));
    }
}