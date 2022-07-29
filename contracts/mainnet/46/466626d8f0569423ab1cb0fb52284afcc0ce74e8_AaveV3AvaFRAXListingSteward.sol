/**
 *Submitted for verification at snowtrace.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
    function renounceRole(bytes32 role, address account) external;
}

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

interface IPoolConfigurator {
    /**
     * @notice Initializes multiple reserves.
     * @param input The array of initialization parameters
     **/
    function initReserves(
        ConfiguratorInputTypes.InitReserveInput[] calldata input
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
     * @notice Updates the liquidation protocol fee of reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
     **/
    function setLiquidationProtocolFee(address asset, uint256 newFee) external;

    /**
     * @notice Assign an efficiency mode (eMode) category to asset.
     * @param asset The address of the underlying asset of the reserve
     * @param newCategoryId The new category id of the asset
     **/
    function setAssetEModeCategory(address asset, uint8 newCategoryId) external;

    /**
     * @notice Sets the debt ceiling for an asset.
     * @param newDebtCeiling The new debt ceiling
     */
    function setDebtCeiling(address asset, uint256 newDebtCeiling) external;
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

/**
 * @dev This steward enables FRAX as collateral on AAVE V3 Avalanche
 * - Parameter snapshot: https://snapshot.org/#/aave.eth/proposal/0xa464894c571fecf559fab1f1a8daf514250955d5ed2bc21eb3a153d03bbe67db
 * Opposed to the suggested parameters this proposal will
 * - Lowering the suggested 50M ceiling to a 2M ceiling
 * - Adding a 50M supply cap
 * - The eMode lq treshold will be 97.5, instead of the suggested 98% as the parameters are per emode not per asset
 * - The reserve factor will be 10% instead of 5% to be consistent with other stable coins
 */
contract AaveV3AvaFRAXListingSteward is StewardBase {
    // **************************
    // Protocol's contracts
    // **************************

    address public constant AAVE_TREASURY =
        0x5ba7fd868c40c16f7aDfAe6CF87121E13FC2F7a0;
    address public constant INCENTIVES_CONTROLLER =
        0x929EC64c34a17401F460460D4B9390518E5B473e;

    // **************************
    // New asset being listed (FRAX)
    // **************************

    address public constant FRAX = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64;
    string public constant FRAX_NAME = 'Aave Avalanche FRAX';
    string public constant AFRAX_SYMBOL = 'aAvaFRAX';
    string public constant VDFRAX_NAME = 'Aave Avalanche Variable Debt FRAX';
    string public constant VDFRAX_SYMBOL = 'variableDebtAvaFRAX';
    string public constant SDFRAX_NAME = 'Aave Avalanche Stable Debt FRAX';
    string public constant SDFRAX_SYMBOL = 'stableDebtAvaFRAX';

    address public constant PRICE_FEED_FRAX =
        0xbBa56eF1565354217a3353a466edB82E8F25b08e;

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
    uint256 public constant SUPPLY_CAP = 50_000_000; // 50m FRAX
    uint256 public constant LIQ_PROTOCOL_FEE = 1000; // 10%

    uint256 public constant DEBT_CEILING = 2_000_000_00; // 2m

    uint8 public constant EMODE_CATEGORY = 1; // Stablecoins

    function listAssetAddingOracle()
        external
        withRennounceOfAllAavePermissions(
            IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B)
        )
        withOwnershipBurning
        onlyOwner
    {
        // ----------------------------
        // 1. New price feed on oracle
        // ----------------------------

        require(PRICE_FEED_FRAX != address(0), 'INVALID_PRICE_FEED');

        address[] memory assets = new address[](1);
        assets[0] = FRAX;
        address[] memory sources = new address[](1);
        sources[0] = PRICE_FEED_FRAX;

        IAaveOracle(0xEBd36016B3eD09D4693Ed4251c67Bd858c3c7C9C).setAssetSources(
                assets,
                sources
            );

        // ------------------------------------------------
        // 2. Listing of FRAX, with all its configurations
        // ------------------------------------------------

        ConfiguratorInputTypes.InitReserveInput[]
            memory initReserveInputs = new ConfiguratorInputTypes.InitReserveInput[](
                1
            );
        initReserveInputs[0] = ConfiguratorInputTypes.InitReserveInput({
            aTokenImpl: ATOKEN_IMPL,
            stableDebtTokenImpl: SDTOKEN_IMPL,
            variableDebtTokenImpl: VDTOKEN_IMPL,
            underlyingAssetDecimals: IERC20(FRAX).decimals(),
            interestRateStrategyAddress: RATE_STRATEGY,
            underlyingAsset: FRAX,
            treasury: AAVE_TREASURY,
            incentivesController: INCENTIVES_CONTROLLER,
            aTokenName: FRAX_NAME,
            aTokenSymbol: AFRAX_SYMBOL,
            variableDebtTokenName: VDFRAX_NAME,
            variableDebtTokenSymbol: VDFRAX_SYMBOL,
            stableDebtTokenName: SDFRAX_NAME,
            stableDebtTokenSymbol: SDFRAX_SYMBOL,
            params: bytes('')
        });

        IPoolConfigurator configurator = IPoolConfigurator(
            0x8145eddDf43f50276641b55bd3AD95944510021E
        );

        configurator.initReserves(initReserveInputs);

        configurator.setSupplyCap(FRAX, SUPPLY_CAP);

        configurator.setDebtCeiling(FRAX, DEBT_CEILING);

        configurator.setReserveBorrowing(FRAX, true);

        configurator.setBorrowableInIsolation(FRAX, true);

        configurator.configureReserveAsCollateral(
            FRAX,
            LTV,
            LIQ_THRESHOLD,
            LIQ_BONUS
        );

        configurator.setAssetEModeCategory(FRAX, EMODE_CATEGORY);

        configurator.setReserveFactor(FRAX, RESERVE_FACTOR);

        configurator.setLiquidationProtocolFee(FRAX, LIQ_PROTOCOL_FEE);
    }
}