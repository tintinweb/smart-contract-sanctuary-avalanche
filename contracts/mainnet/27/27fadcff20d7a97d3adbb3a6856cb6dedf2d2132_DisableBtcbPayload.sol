// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 */
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
   * @notice Removes an address as FlashBorrower
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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPriceOracleGetter} from './IPriceOracleGetter.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IAaveOracle
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
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
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

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
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IReserveInterestRateStrategy} from './IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IDefaultInterestRateStrategy
 * @author Aave
 * @notice Defines the basic interface of the DefaultReserveInterestRateStrategy
 */
interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
  /**
   * @notice Returns the usage ratio at which the pool aims to obtain most competitive borrow rates.
   * @return The optimal usage ratio, expressed in ray.
   */
  function OPTIMAL_USAGE_RATIO() external view returns (uint256);

  /**
   * @notice Returns the optimal stable to total debt ratio of the reserve.
   * @return The optimal stable to total debt ratio, expressed in ray.
   */
  function OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @notice Returns the excess usage ratio above the optimal.
   * @dev It's always equal to 1-optimal usage ratio (added as constant for gas optimizations)
   * @return The max excess usage ratio, expressed in ray.
   */
  function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

  /**
   * @notice Returns the excess stable debt ratio above the optimal.
   * @dev It's always equal to 1-optimal stable to total debt ratio (added as constant for gas optimizations)
   * @return The max excess stable to total debt ratio, expressed in ray.
   */
  function MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO() external view returns (uint256);

  /**
   * @notice Returns the address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the variable rate slope below optimal usage ratio
   * @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The variable rate slope, expressed in ray
   */
  function getVariableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the variable rate slope above optimal usage ratio
   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The variable rate slope, expressed in ray
   */
  function getVariableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope below optimal usage ratio
   * @dev It's the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The stable rate slope, expressed in ray
   */
  function getStableRateSlope1() external view returns (uint256);

  /**
   * @notice Returns the stable rate slope above optimal usage ratio
   * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The stable rate slope, expressed in ray
   */
  function getStableRateSlope2() external view returns (uint256);

  /**
   * @notice Returns the stable rate excess offset
   * @dev It's an additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
   * @return The stable rate excess offset, expressed in ray
   */
  function getStableRateExcessOffset() external view returns (uint256);

  /**
   * @notice Returns the base stable borrow rate
   * @return The base stable borrow rate, expressed in ray
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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   */
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
   */
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   */
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
   */
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

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
   */
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
   */
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
   */
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
   */
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   */
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   */
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
   */
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
   */
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
   */
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @notice Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   * @return The backed amount
   */
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external returns (uint256);

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
   */
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
   */
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
   */
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
   */
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
   */
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
   */
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
   */
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   */
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   */
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   */
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

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
   */
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
   */
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
   */
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
   */
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
   */
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
   */
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   */
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   */
  function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
   * "dynamic" variable index based on time, current stored index and virtual rate at the current
   * moment (approx. a borrower would get if opening a position). This means that is always used in
   * combination with variable debt supply/balances.
   * If using this function externally, consider that is possible to have an increasing normalized
   * variable debt that is not equivalent to how the variable debt index would be updated in storage
   * (e.g. only updates with non-zero variable debt supply)
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

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
   */
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   */
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   */
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
  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

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
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

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
   */
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
   */
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
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
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

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
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

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
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

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
   */
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
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

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
   */
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   */
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   */
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   */
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
   */
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
   */
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   */
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ConfiguratorInputTypes} from '../protocol/libraries/types/ConfiguratorInputTypes.sol';

/**
 * @title IPoolConfigurator
 * @author Aave
 * @notice Defines the basic interface for a Pool configurator.
 */
interface IPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   */
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
   */
  event ReserveBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when flashloans are enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if flashloans are enabled, false otherwise
   */
  event ReserveFlashLoaning(address indexed asset, bool enabled);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   */
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
   */
  event ReserveStableRateBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when a reserve is activated or deactivated
   * @param asset The address of the underlying asset of the reserve
   * @param active True if reserve is active, false otherwise
   */
  event ReserveActive(address indexed asset, bool active);

  /**
   * @dev Emitted when a reserve is frozen or unfrozen
   * @param asset The address of the underlying asset of the reserve
   * @param frozen True if reserve is frozen, false otherwise
   */
  event ReserveFrozen(address indexed asset, bool frozen);

  /**
   * @dev Emitted when a reserve is paused or unpaused
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if reserve is paused, false otherwise
   */
  event ReservePaused(address indexed asset, bool paused);

  /**
   * @dev Emitted when a reserve is dropped.
   * @param asset The address of the underlying asset of the reserve
   */
  event ReserveDropped(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldReserveFactor The old reserve factor, expressed in bps
   * @param newReserveFactor The new reserve factor, expressed in bps
   */
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
   */
  event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

  /**
   * @dev Emitted when the supply cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldSupplyCap The old supply cap
   * @param newSupplyCap The new supply cap
   */
  event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

  /**
   * @dev Emitted when the liquidation protocol fee of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldFee The old liquidation protocol fee, expressed in bps
   * @param newFee The new liquidation protocol fee, expressed in bps
   */
  event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

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
   */
  event EModeAssetCategoryChanged(address indexed asset, uint8 oldCategoryId, uint8 newCategoryId);

  /**
   * @dev Emitted when a new eMode category is added.
   * @param categoryId The new eMode category id
   * @param ltv The ltv for the asset category in eMode
   * @param liquidationThreshold The liquidationThreshold for the asset category in eMode
   * @param liquidationBonus The liquidationBonus for the asset category in eMode
   * @param oracle The optional address of the price oracle specific for this category
   * @param label A human readable identifier for the category
   */
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
   */
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
   */
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
   */
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
   */
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
   */
  event DebtCeilingChanged(address indexed asset, uint256 oldDebtCeiling, uint256 newDebtCeiling);

  /**
   * @dev Emitted when the the siloed borrowing state for an asset is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldState The old siloed borrowing state
   * @param newState The new siloed borrowing state
   */
  event SiloedBorrowingChanged(address indexed asset, bool oldState, bool newState);

  /**
   * @dev Emitted when the bridge protocol fee is updated.
   * @param oldBridgeProtocolFee The old protocol fee, expressed in bps
   * @param newBridgeProtocolFee The new protocol fee, expressed in bps
   */
  event BridgeProtocolFeeUpdated(uint256 oldBridgeProtocolFee, uint256 newBridgeProtocolFee);

  /**
   * @dev Emitted when the total premium on flashloans is updated.
   * @param oldFlashloanPremiumTotal The old premium, expressed in bps
   * @param newFlashloanPremiumTotal The new premium, expressed in bps
   */
  event FlashloanPremiumTotalUpdated(
    uint128 oldFlashloanPremiumTotal,
    uint128 newFlashloanPremiumTotal
  );

  /**
   * @dev Emitted when the part of the premium that goes to protocol is updated.
   * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
   * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
   */
  event FlashloanPremiumToProtocolUpdated(
    uint128 oldFlashloanPremiumToProtocol,
    uint128 newFlashloanPremiumToProtocol
  );

  /**
   * @dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the reserve is borrowable in isolation, false otherwise
   */
  event BorrowableInIsolationChanged(address asset, bool borrowable);

  /**
   * @notice Initializes multiple reserves.
   * @param input The array of initialization parameters
   */
  function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

  /**
   * @dev Updates the aToken implementation for the reserve.
   * @param input The aToken update parameters
   */
  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input) external;

  /**
   * @notice Updates the stable debt token implementation for the reserve.
   * @param input The stableDebtToken update parameters
   */
  function updateStableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external;

  /**
   * @notice Updates the variable debt token implementation for the asset.
   * @param input The variableDebtToken update parameters
   */
  function updateVariableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external;

  /**
   * @notice Configures borrowing on a reserve.
   * @dev Can only be disabled (set to false) if stable borrowing is disabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing needs to be enabled, false otherwise
   */
  function setReserveBorrowing(address asset, bool enabled) external;

  /**
   * @notice Configures the reserve collateralization parameters.
   * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
   * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   */
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
   */
  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  /**
   * @notice Enable or disable flashloans on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if flashloans need to be enabled, false otherwise
   */
  function setReserveFlashLoaning(address asset, bool enabled) external;

  /**
   * @notice Activate or deactivate a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param active True if the reserve needs to be active, false otherwise
   */
  function setReserveActive(address asset, bool active) external;

  /**
   * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
   * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
   * @param asset The address of the underlying asset of the reserve
   * @param freeze True if the reserve needs to be frozen, false otherwise
   */
  function setReserveFreeze(address asset, bool freeze) external;

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
   * borrowed amount will be accumulated in the isolated collateral's total debt exposure
   * @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the asset should be borrowable in isolation, false otherwise
   */
  function setBorrowableInIsolation(address asset, bool borrowable) external;

  /**
   * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
   * swap interest rate, liquidate, atoken transfers).
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if pausing the reserve, false if unpausing
   */
  function setReservePause(address asset, bool paused) external;

  /**
   * @notice Updates the reserve factor of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newReserveFactor The new reserve factor of the reserve
   */
  function setReserveFactor(address asset, uint256 newReserveFactor) external;

  /**
   * @notice Sets the interest rate strategy of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newRateStrategyAddress The address of the new interest strategy contract
   */
  function setReserveInterestRateStrategyAddress(address asset, address newRateStrategyAddress)
    external;

  /**
   * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
   * are suspended.
   * @param paused True if protocol needs to be paused, false otherwise
   */
  function setPoolPause(bool paused) external;

  /**
   * @notice Updates the borrow cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newBorrowCap The new borrow cap of the reserve
   */
  function setBorrowCap(address asset, uint256 newBorrowCap) external;

  /**
   * @notice Updates the supply cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newSupplyCap The new supply cap of the reserve
   */
  function setSupplyCap(address asset, uint256 newSupplyCap) external;

  /**
   * @notice Updates the liquidation protocol fee of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
   */
  function setLiquidationProtocolFee(address asset, uint256 newFee) external;

  /**
   * @notice Updates the unbacked mint cap of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newUnbackedMintCap The new unbacked mint cap of the reserve
   */
  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap) external;

  /**
   * @notice Assign an efficiency mode (eMode) category to asset.
   * @param asset The address of the underlying asset of the reserve
   * @param newCategoryId The new category id of the asset
   */
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
   */
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
   */
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
  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal) external;

  /**
   * @notice Updates the flash loan premium collected by protocol reserves
   * @dev Expressed in bps
   * @dev The premium to protocol is calculated on the total flashloan premium
   * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
   */
  function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol) external;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IPoolDataProvider
 * @author Aave
 * @notice Defines the basic interface of a PoolDataProvider
 */
interface IPoolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  /**
   * @notice Returns the address for the PoolAddressesProvider contract.
   * @return The address for the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the list of the existing reserves in the pool.
   * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
   * @return The list of reserves, pairs of symbols and addresses
   */
  function getAllReservesTokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the list of the existing ATokens in the pool.
   * @return The list of ATokens, pairs of symbols and addresses
   */
  function getAllATokens() external view returns (TokenData[] memory);

  /**
   * @notice Returns the configuration data of the reserve
   * @dev Not returning borrow and supply caps for compatibility, nor pause flag
   * @param asset The address of the underlying asset of the reserve
   * @return decimals The number of decimals of the reserve
   * @return ltv The ltv of the reserve
   * @return liquidationThreshold The liquidationThreshold of the reserve
   * @return liquidationBonus The liquidationBonus of the reserve
   * @return reserveFactor The reserveFactor of the reserve
   * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
   * @return borrowingEnabled True if borrowing is enabled, false otherwise
   * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
   * @return isActive True if it is active, false otherwise
   * @return isFrozen True if it is frozen, false otherwise
   */
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

  /**
   * @notice Returns the efficiency mode category of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The eMode id of the reserve
   */
  function getReserveEModeCategory(address asset) external view returns (uint256);

  /**
   * @notice Returns the caps parameters of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return borrowCap The borrow cap of the reserve
   * @return supplyCap The supply cap of the reserve
   */
  function getReserveCaps(address asset)
    external
    view
    returns (uint256 borrowCap, uint256 supplyCap);

  /**
   * @notice Returns if the pool is paused
   * @param asset The address of the underlying asset of the reserve
   * @return isPaused True if the pool is paused, false otherwise
   */
  function getPaused(address asset) external view returns (bool isPaused);

  /**
   * @notice Returns the siloed borrowing flag
   * @param asset The address of the underlying asset of the reserve
   * @return True if the asset is siloed for borrowing
   */
  function getSiloedBorrowing(address asset) external view returns (bool);

  /**
   * @notice Returns the protocol fee on the liquidation bonus
   * @param asset The address of the underlying asset of the reserve
   * @return The protocol fee on liquidation
   */
  function getLiquidationProtocolFee(address asset) external view returns (uint256);

  /**
   * @notice Returns the unbacked mint cap of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The unbacked mint cap of the reserve
   */
  function getUnbackedMintCap(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The debt ceiling of the reserve
   */
  function getDebtCeiling(address asset) external view returns (uint256);

  /**
   * @notice Returns the debt ceiling decimals
   * @return The debt ceiling decimals
   */
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
   */
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
   */
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   */
  function getTotalDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the user data in a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param user The address of the user
   * @return currentATokenBalance The current AToken balance of the user
   * @return currentStableDebt The current stable debt of the user
   * @return currentVariableDebt The current variable debt of the user
   * @return principalStableDebt The principal stable debt of the user
   * @return scaledVariableDebt The scaled variable debt of the user
   * @return stableBorrowRate The stable borrow rate of the user
   * @return liquidityRate The liquidity rate of the reserve
   * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
   * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
   *         otherwise
   */
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

  /**
   * @notice Returns the token addresses of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return aTokenAddress The AToken address of the reserve
   * @return stableDebtTokenAddress The StableDebtToken address of the reserve
   * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
   */
  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  /**
   * @notice Returns the address of the Interest Rate strategy
   * @param asset The address of the underlying asset of the reserve
   * @return irStrategyAddress The address of the Interest Rate strategy
   */
  function getInterestRateStrategyAddress(address asset)
    external
    view
    returns (address irStrategyAddress);

  /**
   * @notice Returns whether the reserve has FlashLoans enabled or disabled
   * @param asset The address of the underlying asset of the reserve
   * @return True if FlashLoans are enabled, false otherwise
   */
  function getFlashLoanEnabled(address asset) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 */
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   */
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   */
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IReserveInterestRateStrategy
 * @author Aave
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {AaveV2Ethereum} from './AaveV2Ethereum.sol';
import {AaveV3Ethereum} from './AaveV3Ethereum.sol';
import {AaveV2EthereumAMM} from './AaveV2EthereumAMM.sol';
import {AaveV2EthereumArc} from './AaveV2EthereumArc.sol';
import {AaveV2Goerli} from './AaveV2Goerli.sol';
import {AaveV3Goerli} from './AaveV3Goerli.sol';
import {AaveV2Mumbai} from './AaveV2Mumbai.sol';
import {AaveV3Mumbai} from './AaveV3Mumbai.sol';
import {AaveV2Polygon} from './AaveV2Polygon.sol';
import {AaveV3Polygon} from './AaveV3Polygon.sol';
import {AaveV2Fuji} from './AaveV2Fuji.sol';
import {AaveV3Fuji} from './AaveV3Fuji.sol';
import {AaveV2Avalanche} from './AaveV2Avalanche.sol';
import {AaveV3Avalanche} from './AaveV3Avalanche.sol';
import {AaveV3Arbitrum} from './AaveV3Arbitrum.sol';
import {AaveV3ArbitrumGoerli} from './AaveV3ArbitrumGoerli.sol';
import {AaveV3FantomTestnet} from './AaveV3FantomTestnet.sol';
import {AaveV3Fantom} from './AaveV3Fantom.sol';
import {AaveV3Harmony} from './AaveV3Harmony.sol';
import {AaveV3Optimism} from './AaveV3Optimism.sol';
import {AaveV3OptimismGoerli} from './AaveV3OptimismGoerli.sol';

import {AaveGovernanceV2, IGovernanceStrategy} from './AaveGovernanceV2.sol';
import {IAaveEcosystemReserveController, AaveMisc} from './AaveMisc.sol';

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma abicoder v2;

interface IGovernanceStrategy {
  /**
   * @dev Returns the Proposition Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Proposition Power
   * @return Power number
   **/
  function getPropositionPowerAt(address user, uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Proposition Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalPropositionSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the total supply of Outstanding Voting Tokens
   * @param blockNumber Blocknumber at which to evaluate
   * @return total supply at blockNumber
   **/
  function getTotalVotingSupplyAt(uint256 blockNumber) external view returns (uint256);

  /**
   * @dev Returns the Vote Power of a user at a specific block number.
   * @param user Address of the user.
   * @param blockNumber Blocknumber at which to fetch Vote Power
   * @return Vote number
   **/
  function getVotingPowerAt(address user, uint256 blockNumber) external view returns (uint256);
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
  event ProposalQueued(uint256 id, uint256 executionTime, address indexed initiatorQueueing);
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
  event VoteEmitted(uint256 id, address indexed voter, bool support, uint256 votingPower);

  event GovernanceStrategyChanged(address indexed newStrategy, address indexed initiatorChange);

  event VotingDelayChanged(uint256 newVotingDelay, address indexed initiatorChange);

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
  function getProposalById(uint256 proposalId) external view returns (ProposalWithoutVotes memory);

  /**
   * @dev Getter of the Vote of a voter about a proposal
   * Note: Vote is a struct: ({bool support, uint248 votingPower})
   * @param proposalId id of the proposal
   * @param voter address of the voter
   * @return The associated Vote memory object
   **/
  function getVoteOnProposal(uint256 proposalId, address voter) external view returns (Vote memory);

  /**
   * @dev Get the current state of a proposal
   * @param proposalId id of the proposal
   * @return The current state if the proposal
   **/
  function getProposalState(uint256 proposalId) external view returns (ProposalState);
}

library AaveGovernanceV2 {
  IAaveGovernanceV2 internal constant GOV =
    IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);

  IGovernanceStrategy public constant GOV_STRATEGY =
    IGovernanceStrategy(0xb7e383ef9B1E9189Fc0F71fb30af8aa14377429e);

  address public constant SHORT_EXECUTOR = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address public constant LONG_EXECUTOR = 0x79426A1c24B2978D90d7A5070a46C65B07bC4299;

  address public constant ARC_TIMELOCK = 0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218;

  // https://github.com/aave/governance-crosschain-bridges
  address internal constant POLYGON_BRIDGE_EXECUTOR = 0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

  address internal constant OPTIMISM_BRIDGE_EXECUTOR = 0x7d9103572bE58FfE99dc390E8246f02dcAe6f611;

  address internal constant ARBITRUM_BRIDGE_EXECUTOR = 0x7d9103572bE58FfE99dc390E8246f02dcAe6f611;

  // https://github.com/bgd-labs/aave-v3-crosschain-listing-template/tree/master/src/contracts
  address internal constant CROSSCHAIN_FORWARDER_POLYGON =
    0x158a6bC04F0828318821baE797f50B0A1299d45b;

  address internal constant CROSSCHAIN_FORWARDER_OPTIMISM =
    0x5f5C02875a8e9B5A26fbd09040ABCfDeb2AA6711;

  address internal constant CROSSCHAIN_FORWARDER_ARBITRUM =
    0x2e2B1F112C4D79A9D22464F0D345dE9b792705f1;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAaveEcosystemReserveController {
  /**
   * @notice Proxy function for ERC20's approve(), pointing to a specific collector contract
   * @param collector The collector contract with funds (Aave ecosystem reserve)
   * @param token The asset address
   * @param recipient Allowance's recipient
   * @param amount Allowance to approve
   **/
  function approve(
    address collector,
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Proxy function for ERC20's transfer(), pointing to a specific collector contract
   * @param collector The collector contract with funds (Aave ecosystem reserve)
   * @param token The asset address
   * @param recipient Transfer's recipient
   * @param amount Amount to transfer
   **/
  function transfer(
    address collector,
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Proxy function to create a stream of token on a specific collector contract
   * @param collector The collector contract with funds (Aave ecosystem reserve)
   * @param recipient The recipient of the stream of token
   * @param deposit Total amount to be streamed
   * @param tokenAddress The ERC20 token to use as streaming asset
   * @param startTime The unix timestamp for when the stream starts
   * @param stopTime The unix timestamp for when the stream stops
   * @return uint256 The stream id created
   **/
  function createStream(
    address collector,
    address recipient,
    uint256 deposit,
    // IERC20 tokenAddress,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  ) external returns (uint256);

  /**
   * @notice Proxy function to withdraw from a stream of token on a specific collector contract
   * @param collector The collector contract with funds (Aave ecosystem reserve)
   * @param streamId The id of the stream to withdraw tokens from
   * @param funds Amount to withdraw
   * @return bool If the withdrawal finished properly
   **/
  function withdrawFromStream(
    address collector,
    uint256 streamId,
    uint256 funds
  ) external returns (bool);

  /**
   * @notice Proxy function to cancel a stream of token on a specific collector contract
   * @param collector The collector contract with funds (Aave ecosystem reserve)
   * @param streamId The id of the stream to cancel
   * @return bool If the cancellation happened correctly
   **/
  function cancelStream(address collector, uint256 streamId) external returns (bool);
}

library AaveMisc {
  address internal constant ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

  IAaveEcosystemReserveController internal constant AAVE_ECOSYSTEM_RESERVE_CONTROLLER =
    IAaveEcosystemReserveController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

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
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

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
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

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
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

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
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);

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
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

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
  function getUserAccountData(
    address user
  )
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
  function getConfiguration(
    address asset
  ) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(
    address user
  ) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

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
  event BorrowingEnabledOnReserve(address indexed asset, bool stableRateEnabled);

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
  event ReserveInterestRateStrategyChanged(address indexed asset, address strategy);

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

  function batchInitReserve(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

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
  function updateStableDebtToken(address asset, address implementation) external;

  /**
   * @dev Updates the variable debt token implementation for the asset
   * @param asset The address of the underlying asset of the reserve to be updated
   * @param implementation The address of the new aToken implementation
   **/
  function updateVariableDebtToken(address asset, address implementation) external;

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
   **/
  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled) external;

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
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /// @notice Sets the fallbackOracle
  /// - Callable only by the Aave governance
  /// @param fallbackOracle The address of the fallbackOracle
  function setFallbackOracle(address fallbackOracle) external;

  /// @notice Gets an asset price by address
  /// @param asset The asset address
  function getAssetPrice(address asset) external view returns (uint256);

  /// @notice Gets a list of prices from a list of assets addresses
  /// @param assets The list of assets addresses
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

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
  function getReserveConfigurationData(
    address asset
  )
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

  function getReserveTokensAddresses(
    address asset
  )
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );

  function getUserReserveData(
    address asset,
    address user
  )
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
}

interface ILendingRateOracle {
  /**
    @dev returns the market borrow rate in ray
    **/
  function getMarketBorrowRate(address asset) external view returns (uint256);

  /**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
  function setMarketBorrowRate(address asset, uint256 rate) external;
}

interface IDefaultInterestRateStrategy {
  function EXCESS_UTILIZATION_RATE() external view returns (uint256);

  function OPTIMAL_UTILIZATION_RATE() external view returns (uint256);

  function addressesProvider() external view returns (address);

  function baseVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  ) external view returns (uint256, uint256, uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function stableRateSlope1() external view returns (uint256);

  function stableRateSlope2() external view returns (uint256);

  function variableRateSlope1() external view returns (uint256);

  function variableRateSlope2() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2Avalanche {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xb6A86025F0FE1862B372cb0ca18CE3EDe02A318f);

  ILendingPool internal constant POOL = ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x230B618aD4C475393A7239aE03630042281BD86e);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xdC336Cd4769f4cC7E9d726DA53e6d3fC710cEB89);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0xc34254642B504484465F38Cb1CC396d45a9c7c80);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x65285E9dfab318f57051ab2b139ccCf232945451);

  address internal constant POOL_ADMIN = 0x01244E7842254e3FD229CD263472076B1439D1Cd;

  address internal constant EMERGENCY_ADMIN = 0x01244E7842254e3FD229CD263472076B1439D1Cd;

  address internal constant COLLECTOR = 0x467b92aF281d14cB6809913AD016a607b5ba8A36;

  address internal constant COLLECTOR_CONTROLLER = address(0);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x01D83Fe6A10D2f2B7AF17034343746188272cAc9;

  address internal constant EMISSION_MANAGER = 0x5CfCd7E6D055Ba4f7B998914336254aDE3F69f26;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x4235E22d9C3f28DCDA82b58276cb6370B01265C2;

  address internal constant WETH_GATEWAY = 0xC27d4dBefc2C0CE57916a699971b58a3BD9C7d5b;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x2EcF2a2e74B19Aab2a62312167aFF4B78E93B6C5;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x935b362EE3E1f342cc48118C528AAbee5118F6e6;

  address internal constant MIGRATION_HELPER = 0xf50a080aC535e531EC33cC05b227E910De2fb1fA;

  address internal constant WALLET_BALANCE_PROVIDER = 0x73e4898a1Bfa9f710B6A6AB516403A6299e01fc6;

  address internal constant UI_POOL_DATA_PROVIDER = 0x00e50FAB64eBB37b87df06Aa46b8B35d5f1A4e1A;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x11979886A6dBAE27D7a72c49fCF3F23240D647bF;

  address internal constant PROOF_OF_RESERVE = 0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8;

  address internal constant PROOF_OF_RESERVE_AGGREGATOR =
    0x80f2c02224a2E548FC67c0bF705eBFA825dd5439;
}

library AaveV2AvalancheAssets {
  address internal constant WETHe_UNDERLYING = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

  address internal constant WETHe_A_TOKEN = 0x53f7c5869a859F0AeC3D334ee8B4Cf01E3492f21;

  address internal constant WETHe_V_TOKEN = 0x4e575CacB37bc1b5afEc68a0462c4165A5268983;

  address internal constant WETHe_S_TOKEN = 0x60F6A45006323B97d97cB0a42ac39e2b757ADA63;

  address internal constant WETHe_ORACLE = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;

  address internal constant WETHe_INTEREST_RATE_STRATEGY =
    0x6724e923E4bb58fCdF7CEe7A5E7bBb47b99C2647;

  address internal constant DAIe_UNDERLYING = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

  address internal constant DAIe_A_TOKEN = 0x47AFa96Cdc9fAb46904A55a6ad4bf6660B53c38a;

  address internal constant DAIe_V_TOKEN = 0x1852DC24d1a8956a0B356AA18eDe954c7a0Ca5ae;

  address internal constant DAIe_S_TOKEN = 0x3676E4EE689D527dDb89812B63fAD0B7501772B3;

  address internal constant DAIe_ORACLE = 0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300;

  address internal constant DAIe_INTEREST_RATE_STRATEGY =
    0xD96B68638bdbb625A49F5BAC0dC3B66764569d30;

  address internal constant USDTe_UNDERLYING = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

  address internal constant USDTe_A_TOKEN = 0x532E6537FEA298397212F09A61e03311686f548e;

  address internal constant USDTe_V_TOKEN = 0xfc1AdA7A288d6fCe0d29CcfAAa57Bc9114bb2DbE;

  address internal constant USDTe_S_TOKEN = 0x9c7B81A867499B7387ed05017a13d4172a0c17bF;

  address internal constant USDTe_ORACLE = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a;

  address internal constant USDTe_INTEREST_RATE_STRATEGY =
    0xD96B68638bdbb625A49F5BAC0dC3B66764569d30;

  address internal constant USDCe_UNDERLYING = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

  address internal constant USDCe_A_TOKEN = 0x46A51127C3ce23fb7AB1DE06226147F446e4a857;

  address internal constant USDCe_V_TOKEN = 0x848c080d2700CBE1B894a3374AD5E887E5cCb89c;

  address internal constant USDCe_S_TOKEN = 0x5B14679135dbE8B02015ec3Ca4924a12E4C6C85a;

  address internal constant USDCe_ORACLE = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;

  address internal constant USDCe_INTEREST_RATE_STRATEGY =
    0xD96B68638bdbb625A49F5BAC0dC3B66764569d30;

  address internal constant AAVEe_UNDERLYING = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;

  address internal constant AAVEe_A_TOKEN = 0xD45B7c061016102f9FA220502908f2c0f1add1D7;

  address internal constant AAVEe_V_TOKEN = 0x8352E3fd18B8d84D3c8a1b538d788899073c7A8E;

  address internal constant AAVEe_S_TOKEN = 0x66904E4F3f44e3925D22ceca401b6F2DA085c98f;

  address internal constant AAVEe_ORACLE = 0x3CA13391E9fb38a75330fb28f8cc2eB3D9ceceED;

  address internal constant AAVEe_INTEREST_RATE_STRATEGY =
    0x6724e923E4bb58fCdF7CEe7A5E7bBb47b99C2647;

  address internal constant WBTCe_UNDERLYING = 0x50b7545627a5162F82A992c33b87aDc75187B218;

  address internal constant WBTCe_A_TOKEN = 0x686bEF2417b6Dc32C50a3cBfbCC3bb60E1e9a15D;

  address internal constant WBTCe_V_TOKEN = 0x2dc0E35eC3Ab070B8a175C829e23650Ee604a9eB;

  address internal constant WBTCe_S_TOKEN = 0x3484408989985d68C9700dc1CFDFeAe6d2f658CF;

  address internal constant WBTCe_ORACLE = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743;

  address internal constant WBTCe_INTEREST_RATE_STRATEGY =
    0x6724e923E4bb58fCdF7CEe7A5E7bBb47b99C2647;

  address internal constant WAVAX_UNDERLYING = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

  address internal constant WAVAX_A_TOKEN = 0xDFE521292EcE2A4f44242efBcD66Bc594CA9714B;

  address internal constant WAVAX_V_TOKEN = 0x66A0FE52Fb629a6cB4D10B8580AFDffE888F5Fd4;

  address internal constant WAVAX_S_TOKEN = 0x2920CD5b8A160b2Addb00Ec5d5f4112255d4ae75;

  address internal constant WAVAX_ORACLE = 0x0A77230d17318075983913bC2145DB16C7366156;

  address internal constant WAVAX_INTEREST_RATE_STRATEGY =
    0x6724e923E4bb58fCdF7CEe7A5E7bBb47b99C2647;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2Ethereum {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

  ILendingPool internal constant POOL = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0x8A32f49FFbA88aba6EFF96F45D8BD1D4b3f35c7D);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

  address internal constant POOL_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address internal constant EMERGENCY_ADMIN = 0xCA76Ebd8617a03126B6FB84F9b1c1A0fB71C2633;

  address internal constant COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  address internal constant COLLECTOR_CONTROLLER = 0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

  address internal constant EMISSION_MANAGER = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x52D306e36E3B6B02c153d0266ff0f85d18BCD413;

  address internal constant WETH_GATEWAY = 0xEFFC18fC3b7eb8E676dac549E0c693ad50D1Ce31;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x80Aca0C645fEdABaa20fd2Bf0Daf57885A309FE6;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x135896DE8421be2ec868E0b811006171D9df802A;

  address internal constant MIGRATION_HELPER = 0xB748952c7BC638F31775245964707Bcc5DDFabFC;

  address internal constant WALLET_BALANCE_PROVIDER = 0x8E8dAd5409E0263a51C0aB5055dA66Be28cFF922;

  address internal constant UI_POOL_DATA_PROVIDER = 0x00e50FAB64eBB37b87df06Aa46b8B35d5f1A4e1A;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xD01ab9a6577E1D84F142e44D49380e23A340387d;
}

library AaveV2EthereumAssets {
  address internal constant USDT_UNDERLYING = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  address internal constant USDT_A_TOKEN = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;

  address internal constant USDT_V_TOKEN = 0x531842cEbbdD378f8ee36D171d6cC9C4fcf475Ec;

  address internal constant USDT_S_TOKEN = 0xe91D55AB2240594855aBd11b3faAE801Fd4c4687;

  address internal constant USDT_ORACLE = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x515E87cb3fec986050F202a2bbfa362A2188bc3F;

  address internal constant WBTC_UNDERLYING = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

  address internal constant WBTC_A_TOKEN = 0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656;

  address internal constant WBTC_V_TOKEN = 0x9c39809Dec7F95F5e0713634a4D0701329B3b4d2;

  address internal constant WBTC_S_TOKEN = 0x51B039b9AFE64B78758f8Ef091211b5387eA717c;

  address internal constant WBTC_ORACLE = 0xdeb288F737066589598e9214E782fa5A8eD689e8;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0xf41E8F817e6C399d1AdE102059c454093b24f35B;

  address internal constant WETH_UNDERLYING = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant WETH_A_TOKEN = 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;

  address internal constant WETH_V_TOKEN = 0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf;

  address internal constant WETH_S_TOKEN = 0x4e977830ba4bd783C0BB7F15d3e243f73FF57121;

  address internal constant WETH_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x853844459106feefd8C7C4cC34066bFBC0531722;

  address internal constant YFI_UNDERLYING = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;

  address internal constant YFI_A_TOKEN = 0x5165d24277cD063F5ac44Efd447B27025e888f37;

  address internal constant YFI_V_TOKEN = 0x7EbD09022Be45AD993BAA1CEc61166Fcc8644d97;

  address internal constant YFI_S_TOKEN = 0xca823F78C2Dd38993284bb42Ba9b14152082F7BD;

  address internal constant YFI_ORACLE = 0x7c5d4F8345e66f68099581Db340cd65B078C41f4;

  address internal constant YFI_INTEREST_RATE_STRATEGY = 0xfd71623D7F41360aefE200de4f17E20A29e1d58C;

  address internal constant ZRX_UNDERLYING = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

  address internal constant ZRX_A_TOKEN = 0xDf7FF54aAcAcbFf42dfe29DD6144A69b629f8C9e;

  address internal constant ZRX_V_TOKEN = 0x85791D117A392097590bDeD3bD5abB8d5A20491A;

  address internal constant ZRX_S_TOKEN = 0x071B4323a24E73A5afeEbe34118Cd21B8FAAF7C3;

  address internal constant ZRX_ORACLE = 0x2Da4983a622a8498bb1a21FaE9D8F6C664939962;

  address internal constant ZRX_INTEREST_RATE_STRATEGY = 0x1a4babC0e20d892167792AC79618273711afD3e7;

  address internal constant UNI_UNDERLYING = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

  address internal constant UNI_A_TOKEN = 0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1;

  address internal constant UNI_V_TOKEN = 0x5BdB050A92CADcCfCDcCCBFC17204a1C9cC0Ab73;

  address internal constant UNI_S_TOKEN = 0xD939F7430dC8D5a427f156dE1012A56C18AcB6Aa;

  address internal constant UNI_ORACLE = 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e;

  address internal constant UNI_INTEREST_RATE_STRATEGY = 0x24ABFac8dd8f270D752837fDFe3B3C735361f4eE;

  address internal constant AAVE_UNDERLYING = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

  address internal constant AAVE_A_TOKEN = 0xFFC97d72E13E01096502Cb8Eb52dEe56f74DAD7B;

  address internal constant AAVE_V_TOKEN = 0xF7DBA49d571745D9d7fcb56225B05BEA803EBf3C;

  address internal constant AAVE_S_TOKEN = 0x079D6a3E844BcECf5720478A718Edb6575362C5f;

  address internal constant AAVE_ORACLE = 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0xd4cA26F2496195C4F886D464D8578368236bB747;

  address internal constant BAT_UNDERLYING = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;

  address internal constant BAT_A_TOKEN = 0x05Ec93c0365baAeAbF7AefFb0972ea7ECdD39CF1;

  address internal constant BAT_V_TOKEN = 0xfc218A6Dfe6901CB34B1a5281FC6f1b8e7E56877;

  address internal constant BAT_S_TOKEN = 0x277f8676FAcf4dAA5a6EA38ba511B7F65AA02f9F;

  address internal constant BAT_ORACLE = 0x0d16d4528239e9ee52fa531af613AcdB23D88c94;

  address internal constant BAT_INTEREST_RATE_STRATEGY = 0xBdfC85b140edF1FeaFd6eD664027AA4C23b4A29F;

  address internal constant BUSD_UNDERLYING = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

  address internal constant BUSD_A_TOKEN = 0xA361718326c15715591c299427c62086F69923D9;

  address internal constant BUSD_V_TOKEN = 0xbA429f7011c9fa04cDd46a2Da24dc0FF0aC6099c;

  address internal constant BUSD_S_TOKEN = 0x4A7A63909A72D268b1D8a93a9395d098688e0e5C;

  address internal constant BUSD_ORACLE = 0x614715d2Af89E6EC99A233818275142cE88d1Cfd;

  address internal constant BUSD_INTEREST_RATE_STRATEGY =
    0x26D40544447F68a3De69005822195549934624B9;

  address internal constant DAI_UNDERLYING = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  address internal constant DAI_A_TOKEN = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;

  address internal constant DAI_V_TOKEN = 0x6C3c78838c761c6Ac7bE9F59fe808ea2A6E4379d;

  address internal constant DAI_S_TOKEN = 0x778A13D3eeb110A4f7bb6529F99c000119a08E92;

  address internal constant DAI_ORACLE = 0x773616E4d11A78F511299002da57A0a94577F1f4;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xfffE32106A68aA3eD39CcCE673B646423EEaB62a;

  address internal constant ENJ_UNDERLYING = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;

  address internal constant ENJ_A_TOKEN = 0xaC6Df26a590F08dcC95D5a4705ae8abbc88509Ef;

  address internal constant ENJ_V_TOKEN = 0x38995F292a6E31b78203254fE1cdd5Ca1010A446;

  address internal constant ENJ_S_TOKEN = 0x943DcCA156b5312Aa24c1a08769D67FEce4ac14C;

  address internal constant ENJ_ORACLE = 0x24D9aB51950F3d62E9144fdC2f3135DAA6Ce8D1B;

  address internal constant ENJ_INTEREST_RATE_STRATEGY = 0x4a4fb6B26e7F516594b7242240039EA8FAAc897a;

  address internal constant KNC_UNDERLYING = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;

  address internal constant KNC_A_TOKEN = 0x39C6b3e42d6A679d7D776778Fe880BC9487C2EDA;

  address internal constant KNC_V_TOKEN = 0x6B05D1c608015Ccb8e205A690cB86773A96F39f1;

  address internal constant KNC_S_TOKEN = 0x9915dfb872778B2890a117DA1F35F335eb06B54f;

  address internal constant KNC_ORACLE = 0x656c0544eF4C98A6a98491833A89204Abb045d6b;

  address internal constant KNC_INTEREST_RATE_STRATEGY = 0xFDBDa42D2aC1bfbbc10555eb255De8387b8977C4;

  address internal constant LINK_UNDERLYING = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  address internal constant LINK_A_TOKEN = 0xa06bC25B5805d5F8d82847D191Cb4Af5A3e873E0;

  address internal constant LINK_V_TOKEN = 0x0b8f12b1788BFdE65Aa1ca52E3e9F3Ba401be16D;

  address internal constant LINK_S_TOKEN = 0xFB4AEc4Cc858F2539EBd3D37f2a43eAe5b15b98a;

  address internal constant LINK_ORACLE = 0xDC530D9457755926550b59e8ECcdaE7624181557;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0xED6547b83276B076B771B88FcCbD68BDeDb3927f;

  address internal constant MANA_UNDERLYING = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;

  address internal constant MANA_A_TOKEN = 0xa685a61171bb30d4072B338c80Cb7b2c865c873E;

  address internal constant MANA_V_TOKEN = 0x0A68976301e46Ca6Ce7410DB28883E309EA0D352;

  address internal constant MANA_S_TOKEN = 0xD86C74eA2224f4B8591560652b50035E4e5c0a3b;

  address internal constant MANA_ORACLE = 0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9;

  address internal constant MANA_INTEREST_RATE_STRATEGY =
    0x004fC239848D8A8d3304729b78ba81d73d83C99F;

  address internal constant MKR_UNDERLYING = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

  address internal constant MKR_A_TOKEN = 0xc713e5E149D5D0715DcD1c156a020976e7E56B88;

  address internal constant MKR_V_TOKEN = 0xba728eAd5e496BE00DCF66F650b6d7758eCB50f8;

  address internal constant MKR_S_TOKEN = 0xC01C8E4b12a89456a9fD4e4e75B72546Bf53f0B5;

  address internal constant MKR_ORACLE = 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2;

  address internal constant MKR_INTEREST_RATE_STRATEGY = 0xE3a3DE71B827cB73663A24cDB6243bA7F986cC3b;

  address internal constant REN_UNDERLYING = 0x408e41876cCCDC0F92210600ef50372656052a38;

  address internal constant REN_A_TOKEN = 0xCC12AbE4ff81c9378D670De1b57F8e0Dd228D77a;

  address internal constant REN_V_TOKEN = 0xcd9D82d33bd737De215cDac57FE2F7f04DF77FE0;

  address internal constant REN_S_TOKEN = 0x3356Ec1eFA75d9D150Da1EC7d944D9EDf73703B7;

  address internal constant REN_ORACLE = 0x3147D7203354Dc06D9fd350c7a2437bcA92387a4;

  address internal constant REN_INTEREST_RATE_STRATEGY = 0x9B1e3C7483F0f21abFEaE3AeBC9b47b5f23f5bB0;

  address internal constant SNX_UNDERLYING = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

  address internal constant SNX_A_TOKEN = 0x35f6B052C598d933D69A4EEC4D04c73A191fE6c2;

  address internal constant SNX_V_TOKEN = 0x267EB8Cf715455517F9BD5834AeAE3CeA1EBdbD8;

  address internal constant SNX_S_TOKEN = 0x8575c8ae70bDB71606A53AeA1c6789cB0fBF3166;

  address internal constant SNX_ORACLE = 0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c;

  address internal constant SNX_INTEREST_RATE_STRATEGY = 0xCc92073dDe8aE03bAA1812AC5cF22e69b5E76914;

  address internal constant sUSD_UNDERLYING = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

  address internal constant sUSD_A_TOKEN = 0x6C5024Cd4F8A59110119C56f8933403A539555EB;

  address internal constant sUSD_V_TOKEN = 0xdC6a3Ab17299D9C2A412B0e0a4C1f55446AE0817;

  address internal constant sUSD_S_TOKEN = 0x30B0f7324feDF89d8eff397275F8983397eFe4af;

  address internal constant sUSD_ORACLE = 0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757;

  address internal constant sUSD_INTEREST_RATE_STRATEGY =
    0x3082D0a473385Ed2cbd1f16087ab8b7BF79f0355;

  address internal constant TUSD_UNDERLYING = 0x0000000000085d4780B73119b644AE5ecd22b376;

  address internal constant TUSD_A_TOKEN = 0x101cc05f4A51C0319f570d5E146a8C625198e636;

  address internal constant TUSD_V_TOKEN = 0x01C0eb1f8c6F1C1bF74ae028697ce7AA2a8b0E92;

  address internal constant TUSD_S_TOKEN = 0x7f38d60D94652072b2C44a18c0e14A481EC3C0dd;

  address internal constant TUSD_ORACLE = 0x3886BA987236181D98F2401c507Fb8BeA7871dF2;

  address internal constant TUSD_INTEREST_RATE_STRATEGY =
    0x0DdEC679166C367ae45036c8b2c169C5FB2dceE1;

  address internal constant USDC_UNDERLYING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address internal constant USDC_A_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;

  address internal constant USDC_V_TOKEN = 0x619beb58998eD2278e08620f97007e1116D5D25b;

  address internal constant USDC_S_TOKEN = 0xE4922afAB0BbaDd8ab2a88E0C79d884Ad337fcA6;

  address internal constant USDC_ORACLE = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x8Cae0596bC1eD42dc3F04c4506cfe442b3E74e27;

  address internal constant CRV_UNDERLYING = 0xD533a949740bb3306d119CC777fa900bA034cd52;

  address internal constant CRV_A_TOKEN = 0x8dAE6Cb04688C62d939ed9B68d32Bc62e49970b1;

  address internal constant CRV_V_TOKEN = 0x00ad8eBF64F141f1C81e9f8f792d3d1631c6c684;

  address internal constant CRV_S_TOKEN = 0x9288059a74f589C919c7Cf1Db433251CdFEB874B;

  address internal constant CRV_ORACLE = 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e;

  address internal constant CRV_INTEREST_RATE_STRATEGY = 0xE3a3DE71B827cB73663A24cDB6243bA7F986cC3b;

  address internal constant GUSD_UNDERLYING = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;

  address internal constant GUSD_A_TOKEN = 0xD37EE7e4f452C6638c96536e68090De8cBcdb583;

  address internal constant GUSD_V_TOKEN = 0x279AF5b99540c1A3A7E3CDd326e19659401eF99e;

  address internal constant GUSD_S_TOKEN = 0xf8aC64ec6Ff8E0028b37EB89772d21865321bCe0;

  address internal constant GUSD_ORACLE = 0xEc6f4Cd64d28Ef32507e2dc399948aAe9Bbedd7e;

  address internal constant GUSD_INTEREST_RATE_STRATEGY =
    0x2893405d64a7Bc8Db02Fa617351a5399d59eCf8D;

  address internal constant BAL_UNDERLYING = 0xba100000625a3754423978a60c9317c58a424e3D;

  address internal constant BAL_A_TOKEN = 0x272F97b7a56a387aE942350bBC7Df5700f8a4576;

  address internal constant BAL_V_TOKEN = 0x13210D4Fe0d5402bd7Ecbc4B5bC5cFcA3b71adB0;

  address internal constant BAL_S_TOKEN = 0xe569d31590307d05DA3812964F1eDd551D665a0b;

  address internal constant BAL_ORACLE = 0xC1438AA3823A6Ba0C159CfA8D98dF5A994bA120b;

  address internal constant BAL_INTEREST_RATE_STRATEGY = 0xfC0Eace19AA7498e0f36eF1607D282a8d6debbDd;

  address internal constant xSUSHI_UNDERLYING = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

  address internal constant xSUSHI_A_TOKEN = 0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a;

  address internal constant xSUSHI_V_TOKEN = 0xfAFEDF95E21184E3d880bd56D4806c4b8d31c69A;

  address internal constant xSUSHI_S_TOKEN = 0x73Bfb81D7dbA75C904f430eA8BAe82DB0D41187B;

  address internal constant xSUSHI_ORACLE = 0x9b26214bEC078E68a394AaEbfbffF406Ce14893F;

  address internal constant xSUSHI_INTEREST_RATE_STRATEGY =
    0xb49034Ada4BE5c6Bb3823A623C6250267110b06b;

  address internal constant renFIL_UNDERLYING = 0xD5147bc8e386d91Cc5DBE72099DAC6C9b99276F5;

  address internal constant renFIL_A_TOKEN = 0x514cd6756CCBe28772d4Cb81bC3156BA9d1744aa;

  address internal constant renFIL_V_TOKEN = 0x348e2eBD5E962854871874E444F4122399c02755;

  address internal constant renFIL_S_TOKEN = 0xcAad05C49E14075077915cB5C820EB3245aFb950;

  address internal constant renFIL_ORACLE = 0x0606Be69451B1C9861Ac6b3626b99093b713E801;

  address internal constant renFIL_INTEREST_RATE_STRATEGY =
    0x311C866D55456e465e314A3E9830276B438A73f0;

  address internal constant RAI_UNDERLYING = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;

  address internal constant RAI_A_TOKEN = 0xc9BC48c72154ef3e5425641a3c747242112a46AF;

  address internal constant RAI_V_TOKEN = 0xB5385132EE8321977FfF44b60cDE9fE9AB0B4e6b;

  address internal constant RAI_S_TOKEN = 0x9C72B8476C33AE214ee3e8C20F0bc28496a62032;

  address internal constant RAI_ORACLE = 0x4ad7B025127e89263242aB68F0f9c4E5C033B489;

  address internal constant RAI_INTEREST_RATE_STRATEGY = 0xA7d4df837926cD55036175AfeF38395d56A64c22;

  address internal constant AMPL_UNDERLYING = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;

  address internal constant AMPL_A_TOKEN = 0x1E6bb68Acec8fefBD87D192bE09bb274170a0548;

  address internal constant AMPL_V_TOKEN = 0xf013D90E4e4E3Baf420dFea60735e75dbd42f1e1;

  address internal constant AMPL_S_TOKEN = 0x18152C9f77DAdc737006e9430dB913159645fa87;

  address internal constant AMPL_ORACLE = 0x492575FDD11a0fCf2C6C719867890a7648d526eB;

  address internal constant AMPL_INTEREST_RATE_STRATEGY =
    0x84d1FaD9559b8AC1Fda17d073B8542c8Fb6986dd;

  address internal constant USDP_UNDERLYING = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;

  address internal constant USDP_A_TOKEN = 0x2e8F4bdbE3d47d7d7DE490437AeA9915D930F1A3;

  address internal constant USDP_V_TOKEN = 0xFDb93B3b10936cf81FA59A02A7523B6e2149b2B7;

  address internal constant USDP_S_TOKEN = 0x2387119bc85A74e0BBcbe190d80676CB16F10D4F;

  address internal constant USDP_ORACLE = 0x3a08ebBaB125224b7b6474384Ee39fBb247D2200;

  address internal constant USDP_INTEREST_RATE_STRATEGY =
    0x404d396fc42e20d14585A1a10Cd64BDdC6C6574A;

  address internal constant DPI_UNDERLYING = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

  address internal constant DPI_A_TOKEN = 0x6F634c6135D2EBD550000ac92F494F9CB8183dAe;

  address internal constant DPI_V_TOKEN = 0x4dDff5885a67E4EffeC55875a3977D7E60F82ae0;

  address internal constant DPI_S_TOKEN = 0xa3953F07f389d719F99FC378ebDb9276177d8A6e;

  address internal constant DPI_ORACLE = 0x029849bbc0b1d93b85a8b6190e979fd38F5760E2;

  address internal constant DPI_INTEREST_RATE_STRATEGY = 0x9440aEc0795D7485e58bCF26622c2f4A681A9671;

  address internal constant FRAX_UNDERLYING = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

  address internal constant FRAX_A_TOKEN = 0xd4937682df3C8aEF4FE912A96A74121C0829E664;

  address internal constant FRAX_V_TOKEN = 0xfE8F19B17fFeF0fDbfe2671F248903055AFAA8Ca;

  address internal constant FRAX_S_TOKEN = 0x3916e3B6c84b161df1b2733dFfc9569a1dA710c2;

  address internal constant FRAX_ORACLE = 0x14d04Fff8D21bd62987a5cE9ce543d2F1edF5D3E;

  address internal constant FRAX_INTEREST_RATE_STRATEGY =
    0xb0a73aC3B10980A598685d4631c83f5348F5D32c;

  address internal constant FEI_UNDERLYING = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

  address internal constant FEI_A_TOKEN = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3;

  address internal constant FEI_V_TOKEN = 0xC2e10006AccAb7B45D9184FcF5b7EC7763f5BaAe;

  address internal constant FEI_S_TOKEN = 0xd89cF9E8A858F8B4b31Faf793505e112d6c17449;

  address internal constant FEI_ORACLE = 0x7F0D2c2838c6AC24443d13e23d99490017bDe370;

  address internal constant FEI_INTEREST_RATE_STRATEGY = 0xF0bA2a8c12A2354c075b363765EAe825619bd490;

  address internal constant stETH_UNDERLYING = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

  address internal constant stETH_A_TOKEN = 0x1982b2F5814301d4e9a8b0201555376e62F82428;

  address internal constant stETH_V_TOKEN = 0xA9DEAc9f00Dc4310c35603FCD9D34d1A750f81Db;

  address internal constant stETH_S_TOKEN = 0x66457616Dd8489dF5D0AFD8678F4A260088aAF55;

  address internal constant stETH_ORACLE = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

  address internal constant stETH_INTEREST_RATE_STRATEGY =
    0xff04ed5f7a6C3a0F1e5Ea20617F8C6f513D5A77c;

  address internal constant ENS_UNDERLYING = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;

  address internal constant ENS_A_TOKEN = 0x9a14e23A58edf4EFDcB360f68cd1b95ce2081a2F;

  address internal constant ENS_V_TOKEN = 0x176808047cc9b7A2C9AE202c593ED42dDD7C0D13;

  address internal constant ENS_S_TOKEN = 0x34441FFD1948E49dC7a607882D0c38Efd0083815;

  address internal constant ENS_ORACLE = 0xd4641b75015E6536E8102D98479568D05D7123Db;

  address internal constant ENS_INTEREST_RATE_STRATEGY = 0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

  address internal constant UST_UNDERLYING = 0xa693B19d2931d498c5B318dF961919BB4aee87a5;

  address internal constant UST_A_TOKEN = 0xc2e2152647F4C26028482Efaf64b2Aa28779EFC4;

  address internal constant UST_V_TOKEN = 0xaf32001cf2E66C4C3af4205F6EA77112AA4160FE;

  address internal constant UST_S_TOKEN = 0x7FDbfB0412700D94403c42cA3CAEeeA183F07B26;

  address internal constant UST_ORACLE = 0xa20623070413d42a5C01Db2c8111640DD7A5A03a;

  address internal constant UST_INTEREST_RATE_STRATEGY = 0x0dEDCaE8Eb22A2EFB597aBde1834173C47Cff186;

  address internal constant CVX_UNDERLYING = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

  address internal constant CVX_A_TOKEN = 0x952749E07d7157bb9644A894dFAF3Bad5eF6D918;

  address internal constant CVX_V_TOKEN = 0x4Ae5E4409C6Dbc84A00f9f89e4ba096603fb7d50;

  address internal constant CVX_S_TOKEN = 0xB01Eb1cE1Da06179136D561766fc2d609C5F55Eb;

  address internal constant CVX_ORACLE = 0xC9CbF687f43176B302F03f5e58470b77D07c61c6;

  address internal constant CVX_INTEREST_RATE_STRATEGY = 0x1dA981865AE7a0C838eFBF4C7DFecb5c7268E73A;

  address internal constant ONE_INCH_UNDERLYING = 0x111111111117dC0aa78b770fA6A738034120C302;

  address internal constant ONE_INCH_A_TOKEN = 0xB29130CBcC3F791f077eAdE0266168E808E5151e;

  address internal constant ONE_INCH_V_TOKEN = 0xD7896C1B9b4455aFf31473908eB15796ad2295DA;

  address internal constant ONE_INCH_S_TOKEN = 0x1278d6ED804d59d2d18a5Aa5638DfD591A79aF0a;

  address internal constant ONE_INCH_ORACLE = 0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8;

  address internal constant ONE_INCH_INTEREST_RATE_STRATEGY =
    0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

  address internal constant LUSD_UNDERLYING = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

  address internal constant LUSD_A_TOKEN = 0xce1871f791548600cb59efbefFC9c38719142079;

  address internal constant LUSD_V_TOKEN = 0x411066489AB40442d6Fc215aD7c64224120D33F2;

  address internal constant LUSD_S_TOKEN = 0x39f010127274b2dBdB770B45e1de54d974974526;

  address internal constant LUSD_ORACLE = 0x60c0b047133f696334a2b7f68af0b49d2F3D4F72;

  address internal constant LUSD_INTEREST_RATE_STRATEGY =
    0x545Ae1908B6F12e91E03B1DEC4F2e06D0570fE1b;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2EthereumAMM {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xAcc030EF66f9dFEAE9CbB0cd1B25654b82cFA8d5);

  ILendingPool internal constant POOL = ILendingPool(0x7937D4799803FbBe595ed57278Bc4cA21f3bFfCB);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x23A875eDe3F1030138701683e42E9b16A7F87768);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xA50ba011c48153De246E5192C8f9258A2ba79Ca9);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0x8A32f49FFbA88aba6EFF96F45D8BD1D4b3f35c7D);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x0000000000000000000000000000000000000000);

  address internal constant POOL_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address internal constant EMERGENCY_ADMIN = 0xB9062896ec3A615a4e4444DF183F0531a77218AE;

  address internal constant COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  address internal constant COLLECTOR_CONTROLLER = 0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x0000000000000000000000000000000000000000;

  address internal constant EMISSION_MANAGER = 0x0000000000000000000000000000000000000000;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x52D306e36E3B6B02c153d0266ff0f85d18BCD413;

  address internal constant WETH_GATEWAY = 0x1C4a4e31231F71Fc34867D034a9E68f6fC798249;

  address internal constant WALLET_BALANCE_PROVIDER = 0x8E8dAd5409E0263a51C0aB5055dA66Be28cFF922;

  address internal constant UI_POOL_DATA_PROVIDER = 0x00e50FAB64eBB37b87df06Aa46b8B35d5f1A4e1A;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xD01ab9a6577E1D84F142e44D49380e23A340387d;
}

library AaveV2EthereumAMMAssets {
  address internal constant WETH_UNDERLYING = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant WETH_A_TOKEN = 0xf9Fb4AD91812b704Ba883B11d2B576E890a6730A;

  address internal constant WETH_V_TOKEN = 0xA4C273d9A0C1fe2674F0E845160d6232768a3064;

  address internal constant WETH_S_TOKEN = 0x118Ee405c6be8f9BA7cC7a98064EB5DA462235CF;

  address internal constant WETH_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x8d02bac65cd84343eF8239d277794bad455cE889;

  address internal constant DAI_UNDERLYING = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  address internal constant DAI_A_TOKEN = 0x79bE75FFC64DD58e66787E4Eae470c8a1FD08ba4;

  address internal constant DAI_V_TOKEN = 0x3F4fA4937E72991367DC32687BC3278f095E7EAa;

  address internal constant DAI_S_TOKEN = 0x8da51a5a3129343468a63A96ccae1ff1352a3dfE;

  address internal constant DAI_ORACLE = 0x773616E4d11A78F511299002da57A0a94577F1f4;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x79F40CDF9f491f148E522D7845c3fBF61E56c33F;

  address internal constant USDC_UNDERLYING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address internal constant USDC_A_TOKEN = 0xd24946147829DEaA935bE2aD85A3291dbf109c80;

  address internal constant USDC_V_TOKEN = 0xCFDC74b97b69319683fec2A4Ef95c4Ab739F1B12;

  address internal constant USDC_S_TOKEN = 0xE5971a8a741892F3b3ac3E9c94d02588190cE220;

  address internal constant USDC_ORACLE = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x79F40CDF9f491f148E522D7845c3fBF61E56c33F;

  address internal constant USDT_UNDERLYING = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  address internal constant USDT_A_TOKEN = 0x17a79792Fe6fE5C95dFE95Fe3fCEE3CAf4fE4Cb7;

  address internal constant USDT_V_TOKEN = 0xDcFE9BfC246b02Da384de757464a35eFCa402797;

  address internal constant USDT_S_TOKEN = 0x04A0577a89E1b9E8f6c87ee26cCe6a168fFfC5b5;

  address internal constant USDT_ORACLE = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x79F40CDF9f491f148E522D7845c3fBF61E56c33F;

  address internal constant WBTC_UNDERLYING = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

  address internal constant WBTC_A_TOKEN = 0x13B2f6928D7204328b0E8E4BCd0379aA06EA21FA;

  address internal constant WBTC_V_TOKEN = 0x3b99fdaFdfE70d65101a4ba8cDC35dAFbD26375f;

  address internal constant WBTC_S_TOKEN = 0x55E575d092c934503D7635A837584E2900e01d2b;

  address internal constant WBTC_ORACLE = 0xdeb288F737066589598e9214E782fa5A8eD689e8;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x8d02bac65cd84343eF8239d277794bad455cE889;

  address internal constant UNI_DAI_WETH_UNDERLYING = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

  address internal constant UNI_DAI_WETH_A_TOKEN = 0x9303EabC860a743aABcc3A1629014CaBcc3F8D36;

  address internal constant UNI_DAI_WETH_V_TOKEN = 0x23bcc861b989762275165d08B127911F09c71628;

  address internal constant UNI_DAI_WETH_S_TOKEN = 0xE9562bf0A11315A1e39f9182F446eA58002f010E;

  address internal constant UNI_DAI_WETH_ORACLE = 0x66A6b87A18DB78086acda75b7720DC47CdABcC05;

  address internal constant UNI_DAI_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_WBTC_WETH_UNDERLYING = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;

  address internal constant UNI_WBTC_WETH_A_TOKEN = 0xc58F53A8adff2fB4eb16ED56635772075E2EE123;

  address internal constant UNI_WBTC_WETH_V_TOKEN = 0x02aAeB4C7736177242Ee0f71f6f6A0F057Aba87d;

  address internal constant UNI_WBTC_WETH_S_TOKEN = 0xeef7d082D9bE2F5eC73C072228706286dea1f492;

  address internal constant UNI_WBTC_WETH_ORACLE = 0x7004BB6F2013F13C54899309cCa029B49707E547;

  address internal constant UNI_WBTC_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_AAVE_WETH_UNDERLYING = 0xDFC14d2Af169B0D36C4EFF567Ada9b2E0CAE044f;

  address internal constant UNI_AAVE_WETH_A_TOKEN = 0xe59d2FF6995a926A574390824a657eEd36801E55;

  address internal constant UNI_AAVE_WETH_V_TOKEN = 0x859ED7D9E92d1fe42fF95C3BC3a62F7cB59C373E;

  address internal constant UNI_AAVE_WETH_S_TOKEN = 0x997b26eFf106f138e71160022CaAb0AFC5814643;

  address internal constant UNI_AAVE_WETH_ORACLE = 0xB525547968610395B60085bDc8033FFeaEaa5F64;

  address internal constant UNI_AAVE_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_BAT_WETH_UNDERLYING = 0xB6909B960DbbE7392D405429eB2b3649752b4838;

  address internal constant UNI_BAT_WETH_A_TOKEN = 0xA1B0edF4460CC4d8bFAA18Ed871bFF15E5b57Eb4;

  address internal constant UNI_BAT_WETH_V_TOKEN = 0x3Fbef89A21Dc836275bC912849627b33c61b09b4;

  address internal constant UNI_BAT_WETH_S_TOKEN = 0x27c67541a4ea26a436e311b2E6fFeC82083a6983;

  address internal constant UNI_BAT_WETH_ORACLE = 0xB394D8a1CE721630Cbea8Ec110DCEf0D283EDE3a;

  address internal constant UNI_BAT_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_DAI_USDC_UNDERLYING = 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5;

  address internal constant UNI_DAI_USDC_A_TOKEN = 0xE340B25fE32B1011616bb8EC495A4d503e322177;

  address internal constant UNI_DAI_USDC_V_TOKEN = 0x925E3FDd927E20e33C3177C4ff6fb72aD1133C87;

  address internal constant UNI_DAI_USDC_S_TOKEN = 0x6Bb2BdD21920FcB2Ad855AB5d523222F31709d1f;

  address internal constant UNI_DAI_USDC_ORACLE = 0x3B148Fa5E8297DB64262442052b227328730EA81;

  address internal constant UNI_DAI_USDC_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_CRV_WETH_UNDERLYING = 0x3dA1313aE46132A397D90d95B1424A9A7e3e0fCE;

  address internal constant UNI_CRV_WETH_A_TOKEN = 0x0ea20e7fFB006d4Cfe84df2F72d8c7bD89247DB0;

  address internal constant UNI_CRV_WETH_V_TOKEN = 0xF3f1a76cA6356a908CdCdE6b2AC2eaace3739Cd0;

  address internal constant UNI_CRV_WETH_S_TOKEN = 0xd6035f8803eE9f173b1D3EBc3BDE0Ea6B5165636;

  address internal constant UNI_CRV_WETH_ORACLE = 0x10F7078e2f29802D2AC78045F61A69aE0883535A;

  address internal constant UNI_CRV_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_LINK_WETH_UNDERLYING = 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974;

  address internal constant UNI_LINK_WETH_A_TOKEN = 0xb8db81B84d30E2387de0FF330420A4AAA6688134;

  address internal constant UNI_LINK_WETH_V_TOKEN = 0xeDe4052ed8e1F422F4E5062c679f6B18693fEcdc;

  address internal constant UNI_LINK_WETH_S_TOKEN = 0xeb32b3A1De9a1915D2b452B673C53883b9Fa6a97;

  address internal constant UNI_LINK_WETH_ORACLE = 0x30adCEfA5d483284FD79E1eFd54ED3e0A8eaA632;

  address internal constant UNI_LINK_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_MKR_WETH_UNDERLYING = 0xC2aDdA861F89bBB333c90c492cB837741916A225;

  address internal constant UNI_MKR_WETH_A_TOKEN = 0x370adc71f67f581158Dc56f539dF5F399128Ddf9;

  address internal constant UNI_MKR_WETH_V_TOKEN = 0xf36C394775285F89bBBDF09533421E3e81e8447c;

  address internal constant UNI_MKR_WETH_S_TOKEN = 0x6E7E38bB73E19b62AB5567940Caaa514e9d85982;

  address internal constant UNI_MKR_WETH_ORACLE = 0xEBF4A448ff3D835F8FA883941a3E9D5E74B40B5E;

  address internal constant UNI_MKR_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_REN_WETH_UNDERLYING = 0x8Bd1661Da98EBDd3BD080F0bE4e6d9bE8cE9858c;

  address internal constant UNI_REN_WETH_A_TOKEN = 0xA9e201A4e269d6cd5E9F0FcbcB78520cf815878B;

  address internal constant UNI_REN_WETH_V_TOKEN = 0x2A8d5B1c1de15bfcd5EC41368C0295c60D8Da83c;

  address internal constant UNI_REN_WETH_S_TOKEN = 0x312edeADf68E69A0f53518bF27EAcD1AbcC2897e;

  address internal constant UNI_REN_WETH_ORACLE = 0xe2f7C06906A9dB063C28EB5c71B6Ab454e5222dD;

  address internal constant UNI_REN_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_SNX_WETH_UNDERLYING = 0x43AE24960e5534731Fc831386c07755A2dc33D47;

  address internal constant UNI_SNX_WETH_A_TOKEN = 0x38E491A71291CD43E8DE63b7253E482622184894;

  address internal constant UNI_SNX_WETH_V_TOKEN = 0xfd15008efA339A2390B48d2E0Ca8Abd523b406d3;

  address internal constant UNI_SNX_WETH_S_TOKEN = 0xef62A0C391D89381ddf8A8C90Ba772081107D287;

  address internal constant UNI_SNX_WETH_ORACLE = 0x29bfee7E90572Abf1088a58a145a10D051b78E46;

  address internal constant UNI_SNX_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_UNI_WETH_UNDERLYING = 0xd3d2E2692501A5c9Ca623199D38826e513033a17;

  address internal constant UNI_UNI_WETH_A_TOKEN = 0x3D26dcd840fCC8e4B2193AcE8A092e4a65832F9f;

  address internal constant UNI_UNI_WETH_V_TOKEN = 0x0D878FbB01fbEEa7ddEFb896d56f1D3167af919F;

  address internal constant UNI_UNI_WETH_S_TOKEN = 0x6febCE732191Dc915D6fB7Dc5FE3AEFDDb85Bd1B;

  address internal constant UNI_UNI_WETH_ORACLE = 0xC2E93e8121237A885A00627975eB06C7BF9808d6;

  address internal constant UNI_UNI_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_USDC_WETH_UNDERLYING = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;

  address internal constant UNI_USDC_WETH_A_TOKEN = 0x391E86e2C002C70dEe155eAceB88F7A3c38f5976;

  address internal constant UNI_USDC_WETH_V_TOKEN = 0x26625d1dDf520fC8D975cc68eC6E0391D9d3Df61;

  address internal constant UNI_USDC_WETH_S_TOKEN = 0xfAB4C9775A4316Ec67a8223ecD0F70F87fF532Fc;

  address internal constant UNI_USDC_WETH_ORACLE = 0x71c4a2173CE3620982DC8A7D870297533360Da4E;

  address internal constant UNI_USDC_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_WBTC_USDC_UNDERLYING = 0x004375Dff511095CC5A197A54140a24eFEF3A416;

  address internal constant UNI_WBTC_USDC_A_TOKEN = 0x2365a4890eD8965E564B7E2D27C38Ba67Fec4C6F;

  address internal constant UNI_WBTC_USDC_V_TOKEN = 0x36dA0C5dC23397CBf9D13BbD74E93C04f99633Af;

  address internal constant UNI_WBTC_USDC_S_TOKEN = 0xc66bfA05cCe646f05F71DeE333e3229cE24Bbb7e;

  address internal constant UNI_WBTC_USDC_ORACLE = 0x11f4ba2227F21Dc2A9F0b0e6Ea740369d580a212;

  address internal constant UNI_WBTC_USDC_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant UNI_YFI_WETH_UNDERLYING = 0x2fDbAdf3C4D5A8666Bc06645B8358ab803996E28;

  address internal constant UNI_YFI_WETH_A_TOKEN = 0x5394794Be8b6eD5572FCd6b27103F46b5F390E8f;

  address internal constant UNI_YFI_WETH_V_TOKEN = 0xDf70Bdf01a3eBcd0D918FF97390852A914a92Df7;

  address internal constant UNI_YFI_WETH_S_TOKEN = 0x9B054B76d6DE1c4892ba025456A9c4F9be5B1766;

  address internal constant UNI_YFI_WETH_ORACLE = 0x664223b8Bb0934aE0970e601F452f75AaCe9Aa2A;

  address internal constant UNI_YFI_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant BPT_WBTC_WETH_UNDERLYING = 0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5;

  address internal constant BPT_WBTC_WETH_A_TOKEN = 0x358bD0d980E031E23ebA9AA793926857703783BD;

  address internal constant BPT_WBTC_WETH_V_TOKEN = 0xF655DF3832859cfB0AcfD88eDff3452b9Aa6Db24;

  address internal constant BPT_WBTC_WETH_S_TOKEN = 0x46406eCd20FDE1DF4d80F15F07c434fa95CB6b33;

  address internal constant BPT_WBTC_WETH_ORACLE = 0x4CA8D8fC2b4fCe8A2dcB71Da884bba042d48E067;

  address internal constant BPT_WBTC_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant BPT_BAL_WETH_UNDERLYING = 0x59A19D8c652FA0284f44113D0ff9aBa70bd46fB4;

  address internal constant BPT_BAL_WETH_A_TOKEN = 0xd109b2A304587569c84308c55465cd9fF0317bFB;

  address internal constant BPT_BAL_WETH_V_TOKEN = 0xF41A5Cc7a61519B08056176d7B4b87AB34dF55AD;

  address internal constant BPT_BAL_WETH_S_TOKEN = 0x6474d116476b8eDa1B21472a599Ff76A829AbCbb;

  address internal constant BPT_BAL_WETH_ORACLE = 0x2e4e78936b100be6Ef85BCEf7FB25bC770B02B85;

  address internal constant BPT_BAL_WETH_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant GUNI_DAI_USDC_UNDERLYING = 0x50379f632ca68D36E50cfBC8F78fe16bd1499d1e;

  address internal constant GUNI_DAI_USDC_A_TOKEN = 0xd145c6ae8931ed5Bca9b5f5B7dA5991F5aB63B5c;

  address internal constant GUNI_DAI_USDC_V_TOKEN = 0x40533CC601Ec5b79B00D76348ADc0c81d93d926D;

  address internal constant GUNI_DAI_USDC_S_TOKEN = 0x460Fd61bBDe7235C3F345901ad677854c9330c86;

  address internal constant GUNI_DAI_USDC_ORACLE = 0x7843eA2E3e60b24cc12B56C5627Adc7F9f0749D6;

  address internal constant GUNI_DAI_USDC_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;

  address internal constant GUNI_USDC_USDT_UNDERLYING = 0xD2eeC91055F07fE24C9cCB25828ecfEFd4be0c41;

  address internal constant GUNI_USDC_USDT_A_TOKEN = 0xCa5DFDABBfFD58cfD49A9f78Ca52eC8e0591a3C5;

  address internal constant GUNI_USDC_USDT_V_TOKEN = 0x0B7c7d9c5548A23D0455d1edeC541cc2AD955a9d;

  address internal constant GUNI_USDC_USDT_S_TOKEN = 0xFEaeCde9Eb0cd43FDE13427C6C7ef406780a8136;

  address internal constant GUNI_USDC_USDT_ORACLE = 0x399e3bb2BBd49c570aa6edc6ac390E0D0aCbbD5e;

  address internal constant GUNI_USDC_USDT_INTEREST_RATE_STRATEGY =
    0x52E39422cd86a12a13773D86af5FdBF5665989aD;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2EthereumArc {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0x6FdfafB66d39cD72CFE7984D3Bbcc76632faAb00);

  ILendingPool internal constant POOL = ILendingPool(0x37D7306019a38Af123e4b245Eb6C28AF552e0bB0);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x4e1c7865e7BE78A7748724Fa0409e88dc14E67aA);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xB8a7bc0d13B1f5460513040a97F404b4fea7D2f3);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0xfA3c34d734fe0106C87917683ca45dffBe3b3B00);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x71B53fC437cCD988b1b89B1D4605c3c3d0C810ea);

  address internal constant POOL_ADMIN = 0xAce1d11d836cb3F51Ef658FD4D353fFb3c301218;

  address internal constant EMERGENCY_ADMIN = 0x33B09130b035d6D7e57d76fEa0873d9545FA7557;

  address internal constant COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  address internal constant COLLECTOR_CONTROLLER = 0x3d569673dAa0575c936c7c67c4E6AedA69CC630C;

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x0000000000000000000000000000000000000000;

  address internal constant EMISSION_MANAGER = 0x0000000000000000000000000000000000000000;

  address internal constant PERMISSION_MANAGER = 0xF4a1F5fEA79C3609514A417425971FadC10eCfBE;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2Fuji {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0x7fdC1FdF79BE3309bf82f4abdAD9f111A6590C0f);

  ILendingPool internal constant POOL = ILendingPool(0x76cc67FF2CC77821A70ED14321111Ce381C2594D);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x4ceBAFAAcc6Cb26FD90E4cDe138Eb812442bb5f3);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xfa4f5B081632c4709667D467F817C09d9008A46A);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0x76Ec7c83aCb6af821E61F1DF1E0aBE684Bc904F8);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x0668EDE013c1c475724523409b8B6bE633469585);

  address internal constant POOL_ADMIN = 0x1128d177BdaA74Ae68EB06e693f4CbA6BF427a5e;

  address internal constant EMERGENCY_ADMIN = 0x1128d177BdaA74Ae68EB06e693f4CbA6BF427a5e;

  address internal constant COLLECTOR = 0xB45F5C501A22288dfdb897e5f73E189597e09288;

  address internal constant COLLECTOR_CONTROLLER = address(0);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0xa1EF206fb9a8D8186157FC817fCddcC47727ED55;

  address internal constant EMISSION_MANAGER = 0x3b60cABB2C0e9ADe3e364b1F9752342A5D6079e2;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x04A6Fa9999E3C807Ee7b6Ca58eFAb93713d405BF;

  address internal constant WETH_GATEWAY = 0x1648C14DbB6ccdd5846969cE23DeEC4C66a03335;

  address internal constant FAUCET = 0x90E5BAc5A98fff59617080848959f44eACB4Cd7B;

  address internal constant WALLET_BALANCE_PROVIDER = 0x3f5A507B33260a3869878B31FB90F04F451d28e3;

  address internal constant UI_POOL_DATA_PROVIDER = 0x88b4013f8C50e61ab027Cc253ab9a50663e2dF45;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x9842E5B7b7C6cEDfB1952a388e050582Ff95645b;
}

library AaveV2FujiAssets {
  address internal constant WETH_UNDERLYING = 0x9668f5f55f2712Dd2dfa316256609b516292D554;

  address internal constant WETH_A_TOKEN = 0x2B2927e26b433D92fC598EE79Fa351d6591B8F95;

  address internal constant WETH_V_TOKEN = 0xB61CC359E2133b8618cc0319F359F8CA1d3d2b33;

  address internal constant WETH_S_TOKEN = 0x056AaAc3aAf49d00C4fA10bCf9661D2371427ECB;

  address internal constant WETH_ORACLE = 0x86d67c3D38D2bCeE722E601025C25a575021c6EA;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x79bA34079AA04E5d5b25C29df03A3736a8eC7817;

  address internal constant USDT_UNDERLYING = 0x02823f9B469960Bb3b1de0B3746D4b95B7E35543;

  address internal constant USDT_A_TOKEN = 0x5f049c41aF3856cBc171F61FB04D58C1e7445f5F;

  address internal constant USDT_V_TOKEN = 0x6422A7C91A48dD211BF6BdE1Db14d7734f9cbD69;

  address internal constant USDT_S_TOKEN = 0x8c5a8eB9dd4e029c1A5B9e740086eB6Cf4Ba7F13;

  address internal constant USDT_ORACLE = 0x7898AcCC83587C3C55116c5230C17a6Cd9C71bad;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0xC49F727470A367f29Bf4F55B53b4531a26E61E05;

  address internal constant WBTC_UNDERLYING = 0x9C1DCacB57ADa1E9e2D3a8280B7cfC7EB936186F;

  address internal constant WBTC_A_TOKEN = 0xD5B516FDbfb7264676Fd4901B9dD3F707db68733;

  address internal constant WBTC_V_TOKEN = 0xbd0601970fE5b35649Fb92f292cde21f0f52eAE9;

  address internal constant WBTC_S_TOKEN = 0x38A9d8f89Cf87FD4C50dd7B019b9af30c2540512;

  address internal constant WBTC_ORACLE = 0x31CF013A08c6Ac228C94551d535d5BAfE19c602a;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0xC58e46e20B11192Ecb90a8735362e3b633960bf5;

  address internal constant WAVAX_UNDERLYING = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

  address internal constant WAVAX_A_TOKEN = 0xf8C78Ba24DD965487f4472dfb280c46800a0c9B6;

  address internal constant WAVAX_V_TOKEN = 0x333f38B8E76077539Cde1d50Fb5dE0AC6F7E6837;

  address internal constant WAVAX_S_TOKEN = 0xE1c2E4E85d34CAed5c29447135c3ADfaD30364f1;

  address internal constant WAVAX_ORACLE = 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD;

  address internal constant WAVAX_INTEREST_RATE_STRATEGY =
    0xd720420A83FefC64aE9Ff776e5B36621D0989AB7;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2Goerli {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0x5E52dEc931FFb32f609681B8438A51c675cc232d);

  ILendingPool internal constant POOL = ILendingPool(0x4bd5643ac6f66a5237E18bfA7d47cF22f1c9F210);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x88B1D3d97656De3Ec44FEDDfa109AF7fb8C2837D);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x2cb0d5755436ED904D7D0fbBACc6176286c55667);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0x76aFA2b6C29E1B277A3BB1CD320b2756c1674c91);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x0000000000000000000000000000000000000000);

  address internal constant POOL_ADMIN = 0x77c45699A715A64A7a7796d5CEe884cf617D5254;

  address internal constant EMERGENCY_ADMIN = 0x77c45699A715A64A7a7796d5CEe884cf617D5254;

  address internal constant COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  address internal constant COLLECTOR_CONTROLLER = address(0);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x0000000000000000000000000000000000000000;

  address internal constant EMISSION_MANAGER = 0x0000000000000000000000000000000000000000;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x3465454D658019f8A0eABD3bC61d2d1Dd3a0735F;

  address internal constant WETH_GATEWAY = 0x3bd3a20Ac9Ff1dda1D99C0dFCE6D65C4960B3627;

  address internal constant WALLET_BALANCE_PROVIDER = 0xf1E4A6E7FA07421FD5139Ba0848290A27e22db7f;

  address internal constant UI_POOL_DATA_PROVIDER = 0xaaa2872d1F7f5ceb630Cb736BcA34Ff1e121992b;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xA2E05bE2090b3658A264bdf1C39387f5Dba367Ec;

  address internal constant FAUCET = 0x681860075529352da2C94082Eb66c59dF958e89C;
}

library AaveV2GoerliAssets {
  address internal constant AAVE_UNDERLYING = 0x0B7a69d978DdA361Db5356D4Bd0206496aFbDD96;

  address internal constant AAVE_A_TOKEN = 0x5fDF09EE06219f96EffE1b4CC47f44A630C5A358;

  address internal constant AAVE_V_TOKEN = 0x299D037785b53305494A8Ef3e89c47e7E23efe58;

  address internal constant AAVE_S_TOKEN = 0x2ab21c55DAC613a3C2E2D40De0e5df270BaFec4C;

  address internal constant AAVE_ORACLE = 0xA560B50B8f0E581ea78CE298164847aC9BeA4fb6;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x8A813e6D77C81150C105E7d289Dc5C5a978AEC55;

  address internal constant BAT_UNDERLYING = 0x515614aA3d8f09152b1289848383A260c7D053Ff;

  address internal constant BAT_A_TOKEN = 0x41355876CEC93c43cE4e784ce1b5f5e62557D2e2;

  address internal constant BAT_V_TOKEN = 0xE34A49958A50346d9616fB5f8C601A67CD07aC84;

  address internal constant BAT_S_TOKEN = 0x14DA7b36d17812cc5fD8C171D3c573f5E78823e3;

  address internal constant BAT_ORACLE = 0x7B63e2E48aFE0a31B77a81503955B88DCEeB6b4A;

  address internal constant BAT_INTEREST_RATE_STRATEGY = 0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant BUSD_UNDERLYING = 0xa7c3Bf25FFeA8605B516Cf878B7435fe1768c89b;

  address internal constant BUSD_A_TOKEN = 0xabd2878A23cba83F1e9790635e09e494b8E21333;

  address internal constant BUSD_V_TOKEN = 0xD078EAEA33DCA2bE04Ef1511F7c73D78F06f9abe;

  address internal constant BUSD_S_TOKEN = 0xB14F9C379eBeBE76C8881D7104bcb50d50aFC1c2;

  address internal constant BUSD_ORACLE = 0xd24472e139C6f603Cc513115e496e133562aCfDe;

  address internal constant BUSD_INTEREST_RATE_STRATEGY =
    0x91294621A9d131D3224DAE80FAD2b875fd4C72C4;

  address internal constant DAI_UNDERLYING = 0x75Ab5AB1Eef154C0352Fc31D2428Cef80C7F8B33;

  address internal constant DAI_A_TOKEN = 0x31f30d9A5627eAfeC4433Ae2886Cf6cc3D25E772;

  address internal constant DAI_V_TOKEN = 0x40e63a0143da87aC2cd22EC08CE55535cB53ee80;

  address internal constant DAI_S_TOKEN = 0x80bECEc53542B4C85ccf9D51c1cbaB4A5C624637;

  address internal constant DAI_ORACLE = 0x02441b619A76fD597bcd3f9cD29DdFdd30F09831;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xB7c2CE9e6949F64DF5Df67c731cE773C2ACfAA67;

  address internal constant ENJ_UNDERLYING = 0x1057DCaa0b66dFBcEc5241fD51F4326C210f201F;

  address internal constant ENJ_A_TOKEN = 0x3DB016c45090337e989C882F47Cf1Dc51fB6dE1B;

  address internal constant ENJ_V_TOKEN = 0x2861E9f276b82BCbef0e973fF4E17Dd25bCE8346;

  address internal constant ENJ_S_TOKEN = 0x8733524Ca21c3089e787C7972A4DF0d5f50b315b;

  address internal constant ENJ_ORACLE = 0x521d5E72d0Ccc72AE04dF42804d9A81340f653C3;

  address internal constant ENJ_INTEREST_RATE_STRATEGY = 0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant KNC_UNDERLYING = 0x54Bc1D59873A5ABde98cf76B6EcF4075ff65d685;

  address internal constant KNC_A_TOKEN = 0x7D5e39D49Ca107b49Fd4c6cF777B04bdA79a675C;

  address internal constant KNC_V_TOKEN = 0x4758f759257CC24292d90c2c0A1D27Cd7D4f5B19;

  address internal constant KNC_S_TOKEN = 0x62d1Fc8a330F4A01De9770B38695F339bB987164;

  address internal constant KNC_ORACLE = 0x05375D2446593BEA44FEc4247696610aE58c1172;

  address internal constant KNC_INTEREST_RATE_STRATEGY = 0xC2229F23Dccc5472521499F8464e9fe2aa94d600;

  address internal constant LINK_UNDERLYING = 0x7337e7FF9abc45c0e43f130C136a072F4794d40b;

  address internal constant LINK_A_TOKEN = 0x8c8cc9b893b6962409BCEaAFCA95d1044ce809bc;

  address internal constant LINK_V_TOKEN = 0xb0B37762c1d2aa2370D1da9e0276d45240BbD632;

  address internal constant LINK_S_TOKEN = 0x8fc66637ab88f13c92F60D6BD509cc151187D93f;

  address internal constant LINK_ORACLE = 0xE182379be13347F1Ba703080A1Df536E5e26326E;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant MANA_UNDERLYING = 0x8d9EAc6f25470EFfD68f0AD22993CB2813c0c9B9;

  address internal constant MANA_A_TOKEN = 0x71d4C18Ce2bd9889E17099B1552D0b92FAe15731;

  address internal constant MANA_V_TOKEN = 0x6E67bbCE6d126b9B09F974723cC2df83506F2a13;

  address internal constant MANA_S_TOKEN = 0x935bb070195A5cFe2E30890f4D672b1e361a20a6;

  address internal constant MANA_ORACLE = 0xD280748c384C17A4ef96b6c2d06D410C0355dB24;

  address internal constant MANA_INTEREST_RATE_STRATEGY =
    0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant MKR_UNDERLYING = 0x90be02599452FBC1a3D47E9EB62895330cfA05Ed;

  address internal constant MKR_A_TOKEN = 0xd77332d9FA5299010b403bB4f768ACb2d2E8A8a6;

  address internal constant MKR_V_TOKEN = 0x80911c6784E6487A2E5670CAeBa6DdE3c80836A7;

  address internal constant MKR_S_TOKEN = 0x2e5549073cbC537f77393bE12c2e4220bc7146f1;

  address internal constant MKR_ORACLE = 0x209b874eC955659dfD88eB27fBF4B4ECF40C424D;

  address internal constant MKR_INTEREST_RATE_STRATEGY = 0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant REN_UNDERLYING = 0x3160F3f3B55eF85d0D27f04A2d74d426c32de842;

  address internal constant REN_A_TOKEN = 0x2A4B55A3229470BE6Bc78f1b534Cfe8064107407;

  address internal constant REN_V_TOKEN = 0x5e8d588EFf65787657Eb48eBD64E739b1C7eF177;

  address internal constant REN_S_TOKEN = 0xfBf071aDd7414B81E7b6eBF1a4Def16Cc523221f;

  address internal constant REN_ORACLE = 0x36d01Eb525312B1fac515a5a672E4F90b23Ec0Fe;

  address internal constant REN_INTEREST_RATE_STRATEGY = 0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant SNX_UNDERLYING = 0xFc1Ab0379db4B6ad8Bf5Bc1382e108a341E2EaBb;

  address internal constant SNX_A_TOKEN = 0x1Fad08D99F66fe709f4c4d7D81268d6fd380a20f;

  address internal constant SNX_V_TOKEN = 0x50b60ff9591883b14ABCC5395e0218641c8aFFd3;

  address internal constant SNX_S_TOKEN = 0x8E2890B0c234Cea38FDfe7d70E6B496004d81f35;

  address internal constant SNX_ORACLE = 0x9AD6Cf2673954f7c95B7C477760bA36B3208ff60;

  address internal constant SNX_INTEREST_RATE_STRATEGY = 0xF0aE741290d7a7bEC227F60E4A67Fa0030e091b1;

  address internal constant SUSD_UNDERLYING = 0x4e62eB262948671590b8D967BDE048557bdd03eD;

  address internal constant SUSD_A_TOKEN = 0xb997a147657a9295137e54c6C19ECF9e97Eb4b36;

  address internal constant SUSD_V_TOKEN = 0xA2b3b3Bc809d45a535da603485D9CFcE7658BEC1;

  address internal constant SUSD_S_TOKEN = 0x07836D13e93342EA05477244c2f38B9C41C99A0D;

  address internal constant SUSD_ORACLE = 0xde8fe461AC54e86DE63354Fad75182BB5A8974a3;

  address internal constant SUSD_INTEREST_RATE_STRATEGY =
    0x91294621A9d131D3224DAE80FAD2b875fd4C72C4;

  address internal constant TUSD_UNDERLYING = 0xc048C1b6ac47393F073dA2b3d5D1cc43b94891Fd;

  address internal constant TUSD_A_TOKEN = 0x37416BA913324Bc0eEB60f27d5897d8A6A75028b;

  address internal constant TUSD_V_TOKEN = 0x485e3336934d45cC41112D04287ED1f3C9c84B3f;

  address internal constant TUSD_S_TOKEN = 0x5C5B7b4cf294c060204Cf3123502d264C0c88f26;

  address internal constant TUSD_ORACLE = 0x8a3cc8721ef1E190a729487cD86cE13cE4f96b79;

  address internal constant TUSD_INTEREST_RATE_STRATEGY =
    0xB7c2CE9e6949F64DF5Df67c731cE773C2ACfAA67;

  address internal constant UNI_UNDERLYING = 0x981D8AcaF6af3a46785e7741d22fBE81B25Ebf1e;

  address internal constant UNI_A_TOKEN = 0x6Ea7776f7d217b41Dc44684Da6f9FcD4eb9642C3;

  address internal constant UNI_V_TOKEN = 0x111f523Fc4b9451871980324c1A32CA14E90D375;

  address internal constant UNI_S_TOKEN = 0xE36213372341F7422ec42D375EEAd34946420db2;

  address internal constant UNI_ORACLE = 0xb73532a13a2dEB924E341d561E4928A6bba277f8;

  address internal constant UNI_INTEREST_RATE_STRATEGY = 0xF0aE741290d7a7bEC227F60E4A67Fa0030e091b1;

  address internal constant USDC_UNDERLYING = 0x9FD21bE27A2B059a288229361E2fA632D8D2d074;

  address internal constant USDC_A_TOKEN = 0x935c0F6019b05C787573B5e6176681282A3f3E05;

  address internal constant USDC_V_TOKEN = 0xcfc2d9b9498cBd6F71E5E46d46082C76C4F6C695;

  address internal constant USDC_S_TOKEN = 0x82f69F0aa86BC4A2daD63b2DA13A43548F15dE23;

  address internal constant USDC_ORACLE = 0x765ca9DA8d64BeBed5C00f61327a5ED2716d4f76;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x1d53029A5778cfAE0DE1F4e633c94f3878A4A35C;

  address internal constant USDT_UNDERLYING = 0x65E2fe35C30eC218b46266F89847c63c2eDa7Dc7;

  address internal constant USDT_A_TOKEN = 0xDCb84F51dd4BeA1ce4b6118F087B260a71BB656c;

  address internal constant USDT_V_TOKEN = 0x5684765693E499E40BB90d36f8BdEf69B755D740;

  address internal constant USDT_S_TOKEN = 0xe92E940B939a6108C9C4dE3aF29A55286Cd6cC92;

  address internal constant USDT_ORACLE = 0x94a30399Bf8f00e791A92201D8348330b90b73b7;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x1d53029A5778cfAE0DE1F4e633c94f3878A4A35C;

  address internal constant WBTC_UNDERLYING = 0xf4423F4152966eBb106261740da907662A3569C5;

  address internal constant WBTC_A_TOKEN = 0x2f8274ce7fB939014e657e480e9ed3e1131f242B;

  address internal constant WBTC_V_TOKEN = 0xdb2276bAC9F27A7AF8d608fFE21036303aa3486A;

  address internal constant WBTC_S_TOKEN = 0x5744FE36A565637C10911f020779a048fA9ac5d4;

  address internal constant WBTC_ORACLE = 0x6301212A7Bda43a20C1e4C713071612d3f1DC892;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0xC2229F23Dccc5472521499F8464e9fe2aa94d600;

  address internal constant WETH_UNDERLYING = 0xCCa7d1416518D095E729904aAeA087dBA749A4dC;

  address internal constant WETH_A_TOKEN = 0x22404B0e2a7067068AcdaDd8f9D586F834cCe2c5;

  address internal constant WETH_V_TOKEN = 0xE3F7fEe1F71F1227007575931B62B94076549989;

  address internal constant WETH_S_TOKEN = 0x2D9038076C16F152B6Ab5391644DB8e3E88C3723;

  address internal constant WETH_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0xA9464a84A26c439bf721BF2f5E1B14d5dE13bE3B;

  address internal constant YFI_UNDERLYING = 0x6c260F702B6Bb9AC989DA4B0fcbE7fddF8f749c4;

  address internal constant YFI_A_TOKEN = 0xAF299560160896eF72219F0e2Ea67d4653cE8251;

  address internal constant YFI_V_TOKEN = 0xcCef241f5aa65f7344928cF460b7c7703fC8873d;

  address internal constant YFI_S_TOKEN = 0x4D6f1069B958ea197A1e38151e15bB33f403f78F;

  address internal constant YFI_ORACLE = 0x6d6fE84122952bcA8204B357e98DC69fbbC8F6b4;

  address internal constant YFI_INTEREST_RATE_STRATEGY = 0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant ZRX_UNDERLYING = 0xAcFd03DdF9C68015E1943FB02b60c5df56C4CB9e;

  address internal constant ZRX_A_TOKEN = 0x22af6D8C0cD02a4EbdF6f79B6181DcC565f0b18e;

  address internal constant ZRX_V_TOKEN = 0x97431382542b21fe7a2D293737799f5B7afbF0a9;

  address internal constant ZRX_S_TOKEN = 0x1d5094E61854380D458400e1B3f8b323CC87fD6C;

  address internal constant ZRX_ORACLE = 0xf64EBacCce1B7191B3d634E26cD1e867BE81F68b;

  address internal constant ZRX_INTEREST_RATE_STRATEGY = 0x27CB509546d146405bAa546Ad1EFf8Dceb8E6Ab5;

  address internal constant xSUSHI_UNDERLYING = 0x45E18E77b15A02a31507e948A546a509A50a2376;

  address internal constant xSUSHI_A_TOKEN = 0x8C1d95Ed70e16664b0CFF72c31a536a68474A4eA;

  address internal constant xSUSHI_V_TOKEN = 0x710F5Ae6370ebb29c4aF779a5cB22C84C46b682c;

  address internal constant xSUSHI_S_TOKEN = 0xD97DfD88bA230fE7947683B5b5af280FAF6a2E87;

  address internal constant xSUSHI_ORACLE = 0x41cbbA87B91Fcd5160a085E9b0d61bA20667D73b;

  address internal constant xSUSHI_INTEREST_RATE_STRATEGY =
    0x9EB27783621F175DbDc5825873434d250b81C329;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2Mumbai {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0x178113104fEcbcD7fF8669a0150721e231F0FD4B);

  ILendingPool internal constant POOL = ILendingPool(0x9198F13B08E299d85E096929fA9781A1E3d5d827);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0xc3c37E2aA3dc66464fa3C29ce2a6EC85beFC45e1);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xC365C653f7229894F93994CD0b30947Ab69Ff1D5);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0xC661e1445F9a8E5FD3C3dbCa0A0A2e8CBc79725D);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0xFA3bD19110d986c5e5E9DD5F69362d05035D045B);

  address internal constant POOL_ADMIN = 0x943E44157dC0302a5CEb172374d1749018a00994;

  address internal constant EMERGENCY_ADMIN = 0x943E44157dC0302a5CEb172374d1749018a00994;

  address internal constant COLLECTOR = 0x943E44157dC0302a5CEb172374d1749018a00994;

  address internal constant COLLECTOR_CONTROLLER = address(0);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0xd41aE58e803Edf4304334acCE4DC4Ec34a63C644;

  address internal constant EMISSION_MANAGER = 0x943E44157dC0302a5CEb172374d1749018a00994;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0xE6ef11C967898F9525D550014FDEdCFAB63536B5;

  address internal constant WETH_GATEWAY = 0xee9eE614Ad26963bEc1Bec0D2c92879ae1F209fA;

  address internal constant FAUCET = 0x0b3C23243106A69449e79C14c58BB49E358f9B10;

  address internal constant WALLET_BALANCE_PROVIDER = 0xEe7c0172c200e12AFEa3C34837052ec52F3f367A;

  address internal constant UI_POOL_DATA_PROVIDER = 0xb36a91b1deF63B603896290F6a888c774328519A;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x070a7D8F4d7A7A87452C5BaBaB3158e08411907E;
}

library AaveV2MumbaiAssets {
  address internal constant DAI_UNDERLYING = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;

  address internal constant DAI_A_TOKEN = 0x639cB7b21ee2161DF9c882483C9D55c90c20Ca3e;

  address internal constant DAI_V_TOKEN = 0x6D29322ba6549B95e98E9B08033F5ffb857f19c5;

  address internal constant DAI_S_TOKEN = 0x10dec6dF64d0ebD271c8AdD492Af4F5594358919;

  address internal constant DAI_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x1f5Ee28A9BD5810BA9Eb877A555a2C15527D3484;

  address internal constant USDC_UNDERLYING = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e;

  address internal constant USDC_A_TOKEN = 0x2271e3Fef9e15046d09E1d78a8FF038c691E9Cf9;

  address internal constant USDC_V_TOKEN = 0x05771A896327ee702F965FB6E4A35A9A57C84a2a;

  address internal constant USDC_S_TOKEN = 0x83A7bC369cFd55D9F00267318b6D221fb9Fa739F;

  address internal constant USDC_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x63Afbf8a706C23B81ECF892d818170d2A423b01d;

  address internal constant USDT_UNDERLYING = 0xBD21A10F619BE90d6066c941b04e340841F1F989;

  address internal constant USDT_A_TOKEN = 0xF8744C0bD8C7adeA522d6DDE2298b17284A79D1b;

  address internal constant USDT_V_TOKEN = 0x6C0a86573a63672D8a66C037036e441A59086d68;

  address internal constant USDT_S_TOKEN = 0xdD250d4e7ff5f7414F3EBe8fcBbB13583191BDaC;

  address internal constant USDT_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x63Afbf8a706C23B81ECF892d818170d2A423b01d;

  address internal constant WBTC_UNDERLYING = 0x0d787a4a1548f673ed375445535a6c7A1EE56180;

  address internal constant WBTC_A_TOKEN = 0xc9276ECa6798A14f64eC33a526b547DAd50bDa2F;

  address internal constant WBTC_V_TOKEN = 0xc156967272b7177DcE40E3b3E7c4269f750F3160;

  address internal constant WBTC_S_TOKEN = 0x29A36d45e8d9f446EC9529b28907bc850B398154;

  address internal constant WBTC_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x88cf62ff6bDd02ca43840645dE26F8CDb6De2941;

  address internal constant WETH_UNDERLYING = 0x3C68CE8504087f89c640D02d133646d98e64ddd9;

  address internal constant WETH_A_TOKEN = 0x7aE20397Ca327721F013BB9e140C707F82871b56;

  address internal constant WETH_V_TOKEN = 0x0F2656e068b77cdA65213Ef25705B728d5C73340;

  address internal constant WETH_S_TOKEN = 0x35D88812d32b966da90db9F546fbf43553C4F35b;

  address internal constant WETH_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x50a2bf8f96826E9Bfe7fbb94fFbA5790d44B92D1;

  address internal constant WMATIC_UNDERLYING = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;

  address internal constant WMATIC_A_TOKEN = 0xF45444171435d0aCB08a8af493837eF18e86EE27;

  address internal constant WMATIC_V_TOKEN = 0x11b884339E453E3d66A8E22246782D40E62cB5F2;

  address internal constant WMATIC_S_TOKEN = 0xfeedbD76ac61616f270911CCaBb43a36380f40ae;

  address internal constant WMATIC_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WMATIC_INTEREST_RATE_STRATEGY =
    0x8A3Cc6F77BE0a10b60A34bE2316707555Fd634dF;

  address internal constant AAVE_UNDERLYING = 0x341d1f30e77D3FBfbD43D17183E2acb9dF25574E;

  address internal constant AAVE_A_TOKEN = 0x7ec62b6fC19174255335C8f4346E0C2fcf870a6B;

  address internal constant AAVE_V_TOKEN = 0x5A6659794E3Fe10eee90833B36a4819953AaB9A1;

  address internal constant AAVE_S_TOKEN = 0x14bD9790e15294608Df4160dcF45B64adBFdCBaA;

  address internal constant AAVE_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x624dCF5e81a0aA7fE0096447c63113c984DDC0F8;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {ILendingPoolAddressesProvider, ILendingPool, ILendingPoolConfigurator, IAaveOracle, IAaveProtocolDataProvider, ILendingRateOracle} from './AaveV2.sol';

library AaveV2Polygon {
  ILendingPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    ILendingPoolAddressesProvider(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);

  ILendingPool internal constant POOL = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

  ILendingPoolConfigurator internal constant POOL_CONFIGURATOR =
    ILendingPoolConfigurator(0x26db2B833021583566323E3b8985999981b9F1F3);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x0229F777B0fAb107F9591a41d5F02E4e98dB6f2d);

  ILendingRateOracle internal constant lendingRateOracle =
    ILendingRateOracle(0x17F73aEaD876CC4059089ff815EDA37052960dFB);

  IAaveProtocolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IAaveProtocolDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);

  address internal constant POOL_ADMIN = 0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

  address internal constant EMERGENCY_ADMIN = 0x1450F2898D6bA2710C98BE9CAF3041330eD5ae58;

  address internal constant COLLECTOR = 0x7734280A4337F37Fbf4651073Db7c28C80B339e9;

  address internal constant COLLECTOR_CONTROLLER = 0xDB89487A449274478e984665b8692AfC67459deF;

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x357D51124f59836DeD84c8a1730D72B749d8BC23;

  address internal constant EMISSION_MANAGER = 0x2bB25175d9B0F8965780209EB558Cc3b56cA6d32;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x3ac4e9aa29940770aeC38fe853a4bbabb2dA9C19;

  address internal constant WETH_GATEWAY = 0xAeBF56223F044a73A513FAD7E148A9075227eD9b;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x35784a624D4FfBC3594f4d16fA3801FeF063241c;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0xE84cF064a0a65290Ae5673b500699f3753063936;

  address internal constant MIGRATION_HELPER = 0x3db487975aB1728DB5787b798866c2021B24ec52;

  address internal constant WALLET_BALANCE_PROVIDER = 0x34aa032bC416Cf2CdC45c0C8f065b1F19463D43e;

  address internal constant UI_POOL_DATA_PROVIDER = 0x204f2Eb81D996729829debC819f7992DCEEfE7b1;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x645654D59A5226CBab969b1f5431aA47CBf64ab8;
}

library AaveV2PolygonAssets {
  address internal constant DAI_UNDERLYING = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

  address internal constant DAI_A_TOKEN = 0x27F8D03b3a2196956ED754baDc28D73be8830A6e;

  address internal constant DAI_V_TOKEN = 0x75c4d1Fb84429023170086f06E682DcbBF537b7d;

  address internal constant DAI_S_TOKEN = 0x2238101B7014C279aaF6b408A284E49cDBd5DB55;

  address internal constant DAI_ORACLE = 0xFC539A559e170f848323e19dfD66007520510085;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xbE889f70c89f36eB34680b26162Fd84ffd6fE355;

  address internal constant USDC_UNDERLYING = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

  address internal constant USDC_A_TOKEN = 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F;

  address internal constant USDC_V_TOKEN = 0x248960A9d75EdFa3de94F7193eae3161Eb349a12;

  address internal constant USDC_S_TOKEN = 0xdeb05676dB0DB85cecafE8933c903466Bf20C572;

  address internal constant USDC_ORACLE = 0xefb7e6be8356cCc6827799B6A7348eE674A80EaE;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xe7a516f340a3f794a3B2fd0f74A7242b326b9f33;

  address internal constant USDT_UNDERLYING = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

  address internal constant USDT_A_TOKEN = 0x60D55F02A771d515e077c9C2403a1ef324885CeC;

  address internal constant USDT_V_TOKEN = 0x8038857FD47108A07d1f6Bf652ef1cBeC279A2f3;

  address internal constant USDT_S_TOKEN = 0xe590cfca10e81FeD9B0e4496381f02256f5d2f61;

  address internal constant USDT_ORACLE = 0xf9d5AAC6E5572AEFa6bd64108ff86a222F69B64d;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0xe7a516f340a3f794a3B2fd0f74A7242b326b9f33;

  address internal constant WBTC_UNDERLYING = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;

  address internal constant WBTC_A_TOKEN = 0x5c2ed810328349100A66B82b78a1791B101C9D61;

  address internal constant WBTC_V_TOKEN = 0xF664F50631A6f0D72ecdaa0e49b0c019Fa72a8dC;

  address internal constant WBTC_S_TOKEN = 0x2551B15dB740dB8348bFaDFe06830210eC2c2F13;

  address internal constant WBTC_ORACLE = 0xA338e0492B2F944E9F8C0653D3AD1484f2657a37;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0xD10e8A63EC6CfC6FE74B369d29D2765944d23505;

  address internal constant WETH_UNDERLYING = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

  address internal constant WETH_A_TOKEN = 0x28424507fefb6f7f8E9D3860F56504E4e5f5f390;

  address internal constant WETH_V_TOKEN = 0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5;

  address internal constant WETH_S_TOKEN = 0xc478cBbeB590C76b01ce658f8C4dda04f30e2C6f;

  address internal constant WETH_ORACLE = 0x0000000000000000000000000000000000000000;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0xcDAC94de1cf4e8E25B6C61Df6481C344c5E88f44;

  address internal constant WMATIC_UNDERLYING = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  address internal constant WMATIC_A_TOKEN = 0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4;

  address internal constant WMATIC_V_TOKEN = 0x59e8E9100cbfCBCBAdf86b9279fa61526bBB8765;

  address internal constant WMATIC_S_TOKEN = 0xb9A6E29fB540C5F1243ef643EB39b0AcbC2e68E3;

  address internal constant WMATIC_ORACLE = 0x327e23A4855b6F663a28c5161541d69Af8973302;

  address internal constant WMATIC_INTEREST_RATE_STRATEGY =
    0x553b64567dE5392f6B189F6AC89581342DaD12F9;

  address internal constant AAVE_UNDERLYING = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;

  address internal constant AAVE_A_TOKEN = 0x1d2a0E5EC8E5bBDCA5CB219e649B565d8e5c3360;

  address internal constant AAVE_V_TOKEN = 0x1c313e9d0d826662F5CE692134D938656F681350;

  address internal constant AAVE_S_TOKEN = 0x17912140e780B29Ba01381F088f21E8d75F954F9;

  address internal constant AAVE_ORACLE = 0xbE23a3AA13038CfC28aFd0ECe4FdE379fE7fBfc4;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0xae9b3Eb616ed753dcE96C75B6AE30A60Ff9290B4;

  address internal constant GHST_UNDERLYING = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;

  address internal constant GHST_A_TOKEN = 0x080b5BF8f360F624628E0fb961F4e67c9e3c7CF1;

  address internal constant GHST_V_TOKEN = 0x36e988a38542C3482013Bb54ee46aC1fb1efedcd;

  address internal constant GHST_S_TOKEN = 0x6A01Db46Ae51B19A6B85be38f1AA102d8735d05b;

  address internal constant GHST_ORACLE = 0xe638249AF9642CdA55A92245525268482eE4C67b;

  address internal constant GHST_INTEREST_RATE_STRATEGY =
    0xBb480ae4e2cf28FBE80C9b61ab075f6e7C4dB468;

  address internal constant BAL_UNDERLYING = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;

  address internal constant BAL_A_TOKEN = 0xc4195D4060DaEac44058Ed668AA5EfEc50D77ff6;

  address internal constant BAL_V_TOKEN = 0x773E0e32e7b6a00b7cA9daa85dfba9D61B7f2574;

  address internal constant BAL_S_TOKEN = 0xbC30bbe0472E0E86b6f395f9876B950A13B23923;

  address internal constant BAL_ORACLE = 0x03CD157746c61F44597dD54C6f6702105258C722;

  address internal constant BAL_INTEREST_RATE_STRATEGY = 0x9025C2d672afA29f43cB59b3035CaCfC401F5D62;

  address internal constant DPI_UNDERLYING = 0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369;

  address internal constant DPI_A_TOKEN = 0x81fB82aAcB4aBE262fc57F06fD4c1d2De347D7B1;

  address internal constant DPI_V_TOKEN = 0x43150AA0B7e19293D935A412C8607f9172d3d3f3;

  address internal constant DPI_S_TOKEN = 0xA742710c0244a8Ebcf533368e3f0B956B6E53F7B;

  address internal constant DPI_ORACLE = 0xC70aAF9092De3a4E5000956E672cDf5E996B4610;

  address internal constant DPI_INTEREST_RATE_STRATEGY = 0x6405F880E431403588e92b241Ca15603047ef8a4;

  address internal constant CRV_UNDERLYING = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;

  address internal constant CRV_A_TOKEN = 0x3Df8f92b7E798820ddcCA2EBEA7BAbda2c90c4aD;

  address internal constant CRV_V_TOKEN = 0x780BbcBCda2cdb0d2c61fd9BC68c9046B18f3229;

  address internal constant CRV_S_TOKEN = 0x807c97744e6C9452e7C2914d78f49d171a9974a0;

  address internal constant CRV_ORACLE = 0x1CF68C76803c9A415bE301f50E82e44c64B7F1D4;

  address internal constant CRV_INTEREST_RATE_STRATEGY = 0xBD67eB7e00f43DAe9e3d51f7d509d4730Fe5988e;

  address internal constant SUSHI_UNDERLYING = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;

  address internal constant SUSHI_A_TOKEN = 0x21eC9431B5B55c5339Eb1AE7582763087F98FAc2;

  address internal constant SUSHI_V_TOKEN = 0x9CB9fEaFA73bF392C905eEbf5669ad3d073c3DFC;

  address internal constant SUSHI_S_TOKEN = 0x7Ed588DCb30Ea11A54D8a5E9645960262A97cd54;

  address internal constant SUSHI_ORACLE = 0x17414Eb5159A082e8d41D243C1601c2944401431;

  address internal constant SUSHI_INTEREST_RATE_STRATEGY =
    0x835699Bf98f6a7fDe5713c42c118Fb80fA059737;

  address internal constant LINK_UNDERLYING = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;

  address internal constant LINK_A_TOKEN = 0x0Ca2e42e8c21954af73Bc9af1213E4e81D6a669A;

  address internal constant LINK_V_TOKEN = 0xCC71e4A38c974e19bdBC6C0C19b63b8520b1Bb09;

  address internal constant LINK_S_TOKEN = 0x9fb7F546E60DDFaA242CAeF146FA2f4172088117;

  address internal constant LINK_ORACLE = 0xb77fa460604b9C6435A235D057F7D319AC83cb53;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x5641Bb58f4a92188A6F16eE79C8886Cf42C561d3;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import {DataTypes} from 'aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol';
import {ConfiguratorInputTypes} from 'aave-v3-core/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol';
import {IPoolAddressesProvider} from 'aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';
import {IPoolConfigurator} from 'aave-v3-core/contracts/interfaces/IPoolConfigurator.sol';
import {IPriceOracleGetter} from 'aave-v3-core/contracts/interfaces/IPriceOracleGetter.sol';
import {IAaveOracle} from 'aave-v3-core/contracts/interfaces/IAaveOracle.sol';
import {IACLManager as BasicIACLManager} from 'aave-v3-core/contracts/interfaces/IACLManager.sol';
import {IPoolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';
import {IDefaultInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IDefaultInterestRateStrategy.sol';
import {IReserveInterestRateStrategy} from 'aave-v3-core/contracts/interfaces/IReserveInterestRateStrategy.sol';
import {IPoolDataProvider as IAaveProtocolDataProvider} from 'aave-v3-core/contracts/interfaces/IPoolDataProvider.sol';

/**
 * @title ICollector
 * @notice Defines the interface of the Collector contract
 * @author Aave
 **/
interface ICollector {
  /**
   * @dev Emitted during the transfer of ownership of the funds administrator address
   * @param fundsAdmin The new funds administrator address
   **/
  event NewFundsAdmin(address indexed fundsAdmin);

  /**
   * @dev Retrieve the current implementation Revision of the proxy
   * @return The revision version
   */
  function REVISION() external view returns (uint256);

  /**
   * @dev Retrieve the current funds administrator
   * @return The address of the funds administrator
   */
  function getFundsAdmin() external view returns (address);

  /**
   * @dev Approve an amount of tokens to be pulled by the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity allowed to pull tokens
   * @param amount The amount allowed to be pulled. If zero it will revoke the approval.
   */
  function approve(
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer an amount of tokens to the recipient.
   * @param token The address of the asset
   * @param recipient The address of the entity to transfer the tokens.
   * @param amount The amount to be transferred.
   */
  function transfer(
    // IERC20 token,
    address token,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Transfer the ownership of the funds administrator role.
          This function should only be callable by the current funds administrator.
   * @param admin The address of the new funds administrator
   */
  function setFundsAdmin(address admin) external;
}

interface IACLManager is BasicIACLManager {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);

  function renounceRole(bytes32 role, address account) external;

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Arbitrum {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  IPool internal constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xb56c2F0B653B2e0b10C9b928C8580Ac5Df02C7C7);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

  address internal constant ACL_ADMIN = 0xbbd9f90699c1FA0D7A65870D241DD1f1217c96Eb;

  address internal constant COLLECTOR = 0x053D55f9B5AF8694c503EB288a1B7E552f590710;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xC3301b30f4EcBfd59dE0d74e89690C1a70C6f21B);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;

  address internal constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x770ef9f4fe897e59daCc474EF11238303F9552b6;

  address internal constant WETH_GATEWAY = 0xB5Ee21786D28c5Ba61661550879475976B707099;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0xAE9f94BD98eC2831a1330e0418bE0fDb5C95C2B9;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x32FdC26aFFA1eB331263Bcdd59F2e46eCbCC2E24;

  address internal constant WALLET_BALANCE_PROVIDER = 0xBc790382B3686abffE4be14A030A96aC6154023a;

  address internal constant UI_POOL_DATA_PROVIDER = 0x145dE30c929a065582da84Cf96F88460dB9745A7;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xDA67AF3403555Ce0AE3ffC22fDb7354458277358;

  address internal constant L2_ENCODER = 0x9abADECD08572e0eA5aF4d47A9C7984a5AA503dC;
}

library AaveV3ArbitrumAssets {
  address internal constant DAI_UNDERLYING = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

  address internal constant DAI_A_TOKEN = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

  address internal constant DAI_V_TOKEN = 0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC;

  address internal constant DAI_S_TOKEN = 0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B;

  address internal constant DAI_ORACLE = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xA9F3C3caE095527061e6d270DBE163693e6fda9D;

  address internal constant LINK_UNDERLYING = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;

  address internal constant LINK_A_TOKEN = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

  address internal constant LINK_V_TOKEN = 0x953A573793604aF8d41F306FEb8274190dB4aE0e;

  address internal constant LINK_S_TOKEN = 0x89D976629b7055ff1ca02b927BA3e020F22A44e4;

  address internal constant LINK_ORACLE = 0x86E53CF1B870786351Da77A57575e79CB55812CB;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f;

  address internal constant USDC_UNDERLYING = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

  address internal constant USDC_A_TOKEN = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

  address internal constant USDC_V_TOKEN = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  address internal constant USDC_S_TOKEN = 0x307ffe186F84a3bc2613D1eA417A5737D69A7007;

  address internal constant USDC_ORACLE = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant WBTC_UNDERLYING = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

  address internal constant WBTC_A_TOKEN = 0x078f358208685046a11C85e8ad32895DED33A249;

  address internal constant WBTC_V_TOKEN = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;

  address internal constant WBTC_S_TOKEN = 0x633b207Dd676331c413D4C013a6294B0FE47cD0e;

  address internal constant WBTC_ORACLE = 0x6ce185860a4963106506C203335A2910413708e9;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f;

  address internal constant WETH_UNDERLYING = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

  address internal constant WETH_A_TOKEN = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;

  address internal constant WETH_V_TOKEN = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;

  address internal constant WETH_S_TOKEN = 0xD8Ad37849950903571df17049516a5CD4cbE55F6;

  address internal constant WETH_ORACLE = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f;

  address internal constant USDT_UNDERLYING = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

  address internal constant USDT_A_TOKEN = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;

  address internal constant USDT_V_TOKEN = 0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7;

  address internal constant USDT_S_TOKEN = 0x70eFfc565DB6EEf7B927610155602d31b670e802;

  address internal constant USDT_ORACLE = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant AAVE_UNDERLYING = 0xba5DdD1f9d7F570dc94a51479a000E3BCE967196;

  address internal constant AAVE_A_TOKEN = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;

  address internal constant AAVE_V_TOKEN = 0xE80761Ea617F66F96274eA5e8c37f03960ecC679;

  address internal constant AAVE_S_TOKEN = 0xfAeF6A702D15428E588d4C0614AEFb4348D83D48;

  address internal constant AAVE_ORACLE = 0xaD1d5344AaDE45F43E596773Bcc4c423EAbdD034;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x9b34E3e183c9b0d1a08fF57a8fb59c821616295f;

  address internal constant EURS_UNDERLYING = 0xD22a58f79e9481D1a88e00c343885A588b34b68B;

  address internal constant EURS_A_TOKEN = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  address internal constant EURS_V_TOKEN = 0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;

  address internal constant EURS_S_TOKEN = 0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E;

  address internal constant EURS_ORACLE = 0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84;

  address internal constant EURS_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3ArbitrumGoerli {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0x4EEE0BB72C2717310318f27628B3c8a708E4951C);

  IPool internal constant POOL = IPool(0xeAA2F46aeFd7BDe8fB91Df1B277193079b727655);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8bf6ed3FDa90c4111E491D2BDdd57589Ffb0c161);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xaEA17ddD7cEDD233f851e1cFd2cBca42F488772d);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x2Fc0604AE02FA8AB833f135B0C01dFa45f88DAa2);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xb8141857d82eC821141c17FA74dfeF062EB8594D);

  address internal constant ACL_ADMIN = 0xfA0e305E0f46AB04f00ae6b5f4560d61a2183E00;

  address internal constant COLLECTOR = 0x0b6d37C5dCC56c50EA13991C8B95f9c898aA2172;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xe7999aBDF90cD4b040C1107C14F2F430E818FE45);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x82F8904357Ba2fb7e7Cf6dcAA277289bF4481D7D;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0x0aAFea73B7099a3C612dEDAACeB861FAE15fd207;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x9734b9BE76885FF2806963cE49c6a74dBF166EE3;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x0D1CB66809dC0044f91816065eF45B6CbCF70a11;

  address internal constant EMISSION_MANAGER = 0x9BDf15A56a03A542eA588137233013aBC5A4B98a;

  address internal constant WETH_GATEWAY = 0xBCca2fc5F30A65cE2155d739364f3fc8F57E6999;

  address internal constant FAUCET = 0x0E0effeEFD42C108288b0EcDDc901222a4149e08;

  address internal constant WALLET_BALANCE_PROVIDER = 0x39fDBFDBF1127F31F485a1228D44010F5130cCAC;

  address internal constant UI_POOL_DATA_PROVIDER = 0x583F04c0C4BDE3D7706e939F3Ea890Be9A20A5CF;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xB9107870a2e22b9cd4B51ED5483212Cb9eAE0329;

  address internal constant L2_ENCODER = 0xE8BA4db946a310A1Aca92571A53D3bdE834B5409;
}

library AaveV3ArbitrumGoerliAssets {
  address internal constant DAI_UNDERLYING = 0xf556C102F47d806E21E8E78438E58ac06A14A29E;

  address internal constant DAI_A_TOKEN = 0x951ce0CFd38b4ADd03272C458Cc2973D77E2C000;

  address internal constant DAI_V_TOKEN = 0x4BB83caC4133EaB064c1C46dd871cc0E564C8520;

  address internal constant DAI_S_TOKEN = 0x2411E8B87BeC832a9ff3C6544b2FD2dA0ec00947;

  address internal constant DAI_ORACLE = 0x04dD9334B4Ad4d2F0b951f7f51fB109E7fB01f1d;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x1Cec5527d9C7513a9e06BC54e107d286E62fa75F;

  address internal constant LINK_UNDERLYING = 0x56033E114c61183590d39BA847400F02022Ebe47;

  address internal constant LINK_A_TOKEN = 0x0da29C753f866f2E751167f38EE093C70fB1683C;

  address internal constant LINK_V_TOKEN = 0x212f692eA944a9DA3706c13911B1a3adFC1444E3;

  address internal constant LINK_S_TOKEN = 0x8E0aC61ad093555055d0814F3cf00721E0622286;

  address internal constant LINK_ORACLE = 0xEAFc1f877975232727a2775BfbDe9396891B67F7;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x70488f326010c740f4DfAF4Fe1aD94969aCb7Af4;

  address internal constant USDC_UNDERLYING = 0x72A9c57cD5E2Ff20450e409cF6A542f1E6c710fc;

  address internal constant USDC_A_TOKEN = 0xd9933e10d6d9453FFaCF1236aF7ea1a61EA4D2c5;

  address internal constant USDC_V_TOKEN = 0x853382Ba681B4EF27c10403F736c43f9F558a600;

  address internal constant USDC_S_TOKEN = 0x51B9bb42Bebe98774277Bb4099b19F390F13A90F;

  address internal constant USDC_ORACLE = 0xA0b016F750490B91F5Ba7e31e6e7fcCd5aE6d42A;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xEaC5EbD74Ff5111E18eBc0bbFCc8eA5786685D5A;

  address internal constant WBTC_UNDERLYING = 0xD2f5680976c86ADd3978b7ad3422Ee5c7690ddb4;

  address internal constant WBTC_A_TOKEN = 0xa6133BaA380826F716cAa419240a353B58d545A2;

  address internal constant WBTC_V_TOKEN = 0x84A490de9fd110963C807d633527e86B9D11cb34;

  address internal constant WBTC_S_TOKEN = 0xb2b7b68e4A69dBBD9e82fa3f63A299313C727102;

  address internal constant WBTC_ORACLE = 0x33243c56Da27b872Df10Ed25Bf7b19454daf492E;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x70488f326010c740f4DfAF4Fe1aD94969aCb7Af4;

  address internal constant WETH_UNDERLYING = 0xb83C277172198E8Ec6b841Ff9bEF2d7fa524f797;

  address internal constant WETH_A_TOKEN = 0xBA3a852aDB46C8AD31A03397CD22b2E896625548;

  address internal constant WETH_V_TOKEN = 0x79368C3D6DD074d5ed750Fd37ba8A868F01df058;

  address internal constant WETH_S_TOKEN = 0xc33F04D3052808730b7D3aB5822CD327f30f346D;

  address internal constant WETH_ORACLE = 0xacc654E338cAd72475f6B1495D5C12A114F341fe;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x70488f326010c740f4DfAF4Fe1aD94969aCb7Af4;

  address internal constant USDT_UNDERLYING = 0x8F30ec9Fb348513494cCC1710528E744Efa71003;

  address internal constant USDT_A_TOKEN = 0xF62eA0cAcbC414f0D442F98C850044Ece4c4b10A;

  address internal constant USDT_V_TOKEN = 0x77ADE1D54628fFEF2c7151fB124f4F5058D14c91;

  address internal constant USDT_S_TOKEN = 0x2aa9c410145CDb3c22A187370eCdD766991de8f6;

  address internal constant USDT_ORACLE = 0xe460babCe2c3B02364C1F1ec14bbA002860319F8;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0xEaC5EbD74Ff5111E18eBc0bbFCc8eA5786685D5A;

  address internal constant AAVE_UNDERLYING = 0xC481B290d55E4866DA8b543685deD142A6170636;

  address internal constant AAVE_A_TOKEN = 0x3DD09707E1017A449343120C6424B029CBC76356;

  address internal constant AAVE_V_TOKEN = 0xc2e94545E9217BE1909df8Bb00cF75898615ce22;

  address internal constant AAVE_S_TOKEN = 0x568D3db42a5A4935cEF1a8f34cD0aB69e087B3CD;

  address internal constant AAVE_ORACLE = 0xCDB7e57F7E2b6902A677315D8D4309A11631BbB8;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x70488f326010c740f4DfAF4Fe1aD94969aCb7Af4;

  address internal constant EURS_UNDERLYING = 0xe898C3C5185C35c00b5eaBea4713E2dBadD82879;

  address internal constant EURS_A_TOKEN = 0xb79438f6263a9f68BE57a7EDb0CD5AFC405bF80d;

  address internal constant EURS_V_TOKEN = 0xbad5FD368002F8A7BEFEd286c09Ae9c4Cf0cE0D6;

  address internal constant EURS_S_TOKEN = 0xA8ba625437d2467Ad8427abD6ADfba3b1B144E11;

  address internal constant EURS_ORACLE = 0x463A8358982eEfA3D8d49cd6a63d6a5Ec409406d;

  address internal constant EURS_INTEREST_RATE_STRATEGY =
    0xEaC5EbD74Ff5111E18eBc0bbFCc8eA5786685D5A;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Avalanche {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  IPool internal constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xEBd36016B3eD09D4693Ed4251c67Bd858c3c7C9C);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

  address internal constant ACL_ADMIN = 0xa35b76E4935449E33C56aB24b23fcd3246f13470;

  address internal constant COLLECTOR = 0x5ba7fd868c40c16f7aDfAe6CF87121E13FC2F7a0;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xaCbE7d574EF8dC39435577eb638167Aca74F79f0);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;

  address internal constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x770ef9f4fe897e59daCc474EF11238303F9552b6;

  address internal constant WETH_GATEWAY = 0x6F143FE2F7B02424ad3CaD1593D6f36c0Aab69d7;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x8a743090e9759E758d15a4CFd18408fb6332c625;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0xF7fC20D9D1D8DFE55F5F2c3180272a5747dD327F;

  address internal constant WALLET_BALANCE_PROVIDER = 0xBc790382B3686abffE4be14A030A96aC6154023a;

  address internal constant UI_POOL_DATA_PROVIDER = 0xF71DBe0FAEF1473ffC607d4c555dfF0aEaDb878d;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x265d414f80b0fca9505710e6F16dB4b67555D365;

  address internal constant PROOF_OF_RESERVE = 0xab22988D93d5F942fC6B6c6Ea285744809D1d9Cc;

  address internal constant PROOF_OF_RESERVE_AGGREGATOR =
    0x80f2c02224a2E548FC67c0bF705eBFA825dd5439;
}

library AaveV3AvalancheAssets {
  address internal constant DAIe_UNDERLYING = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

  address internal constant DAIe_A_TOKEN = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

  address internal constant DAIe_V_TOKEN = 0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC;

  address internal constant DAIe_S_TOKEN = 0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B;

  address internal constant DAIe_ORACLE = 0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300;

  address internal constant DAIe_INTEREST_RATE_STRATEGY =
    0xfab05a6aF585da2F96e21452F91E812452996BD3;

  address internal constant LINKe_UNDERLYING = 0x5947BB275c521040051D82396192181b413227A3;

  address internal constant LINKe_A_TOKEN = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

  address internal constant LINKe_V_TOKEN = 0x953A573793604aF8d41F306FEb8274190dB4aE0e;

  address internal constant LINKe_S_TOKEN = 0x89D976629b7055ff1ca02b927BA3e020F22A44e4;

  address internal constant LINKe_ORACLE = 0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a;

  address internal constant LINKe_INTEREST_RATE_STRATEGY =
    0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;

  address internal constant USDC_UNDERLYING = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

  address internal constant USDC_A_TOKEN = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

  address internal constant USDC_V_TOKEN = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  address internal constant USDC_S_TOKEN = 0x307ffe186F84a3bc2613D1eA417A5737D69A7007;

  address internal constant USDC_ORACLE = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant WBTCe_UNDERLYING = 0x50b7545627a5162F82A992c33b87aDc75187B218;

  address internal constant WBTCe_A_TOKEN = 0x078f358208685046a11C85e8ad32895DED33A249;

  address internal constant WBTCe_V_TOKEN = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;

  address internal constant WBTCe_S_TOKEN = 0x633b207Dd676331c413D4C013a6294B0FE47cD0e;

  address internal constant WBTCe_ORACLE = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743;

  address internal constant WBTCe_INTEREST_RATE_STRATEGY =
    0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;

  address internal constant WETHe_UNDERLYING = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;

  address internal constant WETHe_A_TOKEN = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;

  address internal constant WETHe_V_TOKEN = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;

  address internal constant WETHe_S_TOKEN = 0xD8Ad37849950903571df17049516a5CD4cbE55F6;

  address internal constant WETHe_ORACLE = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;

  address internal constant WETHe_INTEREST_RATE_STRATEGY =
    0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;

  address internal constant USDt_UNDERLYING = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;

  address internal constant USDt_A_TOKEN = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;

  address internal constant USDt_V_TOKEN = 0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7;

  address internal constant USDt_S_TOKEN = 0x70eFfc565DB6EEf7B927610155602d31b670e802;

  address internal constant USDt_ORACLE = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a;

  address internal constant USDt_INTEREST_RATE_STRATEGY =
    0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant AAVEe_UNDERLYING = 0x63a72806098Bd3D9520cC43356dD78afe5D386D9;

  address internal constant AAVEe_A_TOKEN = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;

  address internal constant AAVEe_V_TOKEN = 0xE80761Ea617F66F96274eA5e8c37f03960ecC679;

  address internal constant AAVEe_S_TOKEN = 0xfAeF6A702D15428E588d4C0614AEFb4348D83D48;

  address internal constant AAVEe_ORACLE = 0x3CA13391E9fb38a75330fb28f8cc2eB3D9ceceED;

  address internal constant AAVEe_INTEREST_RATE_STRATEGY =
    0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;

  address internal constant WAVAX_UNDERLYING = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

  address internal constant WAVAX_A_TOKEN = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  address internal constant WAVAX_V_TOKEN = 0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;

  address internal constant WAVAX_S_TOKEN = 0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E;

  address internal constant WAVAX_ORACLE = 0x0A77230d17318075983913bC2145DB16C7366156;

  address internal constant WAVAX_INTEREST_RATE_STRATEGY =
    0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;

  address internal constant sAVAX_UNDERLYING = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;

  address internal constant sAVAX_A_TOKEN = 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf;

  address internal constant sAVAX_V_TOKEN = 0x77CA01483f379E58174739308945f044e1a764dc;

  address internal constant sAVAX_S_TOKEN = 0x08Cb71192985E936C7Cd166A8b268035e400c3c3;

  address internal constant sAVAX_ORACLE = 0xc9245871D69BF4c36c6F2D15E0D68Ffa883FE1A7;

  address internal constant sAVAX_INTEREST_RATE_STRATEGY =
    0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;

  address internal constant FRAX_UNDERLYING = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64;

  address internal constant FRAX_A_TOKEN = 0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA;

  address internal constant FRAX_V_TOKEN = 0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907;

  address internal constant FRAX_S_TOKEN = 0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841;

  address internal constant FRAX_ORACLE = 0xbBa56eF1565354217a3353a466edB82E8F25b08e;

  address internal constant FRAX_INTEREST_RATE_STRATEGY =
    0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant MAI_UNDERLYING = 0x5c49b268c9841AFF1Cc3B0a418ff5c3442eE3F3b;

  address internal constant MAI_A_TOKEN = 0x8Eb270e296023E9D92081fdF967dDd7878724424;

  address internal constant MAI_V_TOKEN = 0xCE186F6Cccb0c955445bb9d10C59caE488Fea559;

  address internal constant MAI_S_TOKEN = 0x3EF10DFf4928279c004308EbADc4Db8B7620d6fc;

  address internal constant MAI_ORACLE = 0x5D1F504211c17365CA66353442a74D4435A8b778;

  address internal constant MAI_INTEREST_RATE_STRATEGY = 0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant BTCb_UNDERLYING = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;

  address internal constant BTCb_A_TOKEN = 0x8ffDf2DE812095b1D19CB146E4c004587C0A0692;

  address internal constant BTCb_V_TOKEN = 0xA8669021776Bc142DfcA87c21b4A52595bCbB40a;

  address internal constant BTCb_S_TOKEN = 0xa5e408678469d23efDB7694b1B0A85BB0669e8bd;

  address internal constant BTCb_ORACLE = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743;

  address internal constant BTCb_INTEREST_RATE_STRATEGY =
    0x79a906e8c998d2fb5C5D66d23c4c5416Fe0168D6;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Ethereum {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);

  IPool internal constant POOL = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x64b761D848206f447Fe2dd461b0c635Ec39EbB27);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x54586bE62E3c3580375aE3723C145253060Ca0C2);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xc2aaCf6553D20d1e9d78E365AAba8032af9c85b0);

  address internal constant ACL_ADMIN = 0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;

  address internal constant COLLECTOR = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x15C5620dfFaC7c7366EED66C20Ad222DDbB1eD57;

  address internal constant EMISSION_MANAGER = 0x223d844fc4B006D67c0cDbd39371A9F73f69d974;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0xbaA999AC55EAce41CcAE355c77809e68Bb345170;

  address internal constant WETH_GATEWAY = 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x1809f186D680f239420B56948C58F8DbbCdf1E18;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x872fBcb1B582e8Cd0D0DD4327fBFa0B4C2730995;

  address internal constant LISTING_ENGINE = 0xC51e6E38d406F98049622Ca54a6096a23826B426;

  address internal constant WALLET_BALANCE_PROVIDER = 0xC7be5307ba715ce89b152f3Df0658295b3dbA8E2;

  address internal constant UI_POOL_DATA_PROVIDER = 0x91c0eA31b49B69Ea18607702c5d9aC360bf3dE7d;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x162A7AC02f547ad796CA549f757e2b8d1D9b10a6;
}

library AaveV3EthereumAssets {
  address internal constant WETH_UNDERLYING = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  address internal constant WETH_A_TOKEN = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

  address internal constant WETH_V_TOKEN = 0xeA51d7853EEFb32b6ee06b1C12E6dcCA88Be0fFE;

  address internal constant WETH_S_TOKEN = 0x102633152313C81cD80419b6EcF66d14Ad68949A;

  address internal constant WETH_ORACLE = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x53F57eAAD604307889D87b747Fc67ea9DE430B01;

  address internal constant wstETH_UNDERLYING = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

  address internal constant wstETH_A_TOKEN = 0x0B925eD163218f6662a35e0f0371Ac234f9E9371;

  address internal constant wstETH_V_TOKEN = 0xC96113eED8cAB59cD8A66813bCB0cEb29F06D2e4;

  address internal constant wstETH_S_TOKEN = 0x39739943199c0fBFe9E5f1B5B160cd73a64CB85D;

  address internal constant wstETH_ORACLE = 0xA9F30e6ED4098e9439B2ac8aEA2d3fc26BcEbb45;

  address internal constant wstETH_INTEREST_RATE_STRATEGY =
    0x7b8Fa4540246554e77FCFf140f9114de00F8bB8D;

  address internal constant WBTC_UNDERLYING = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

  address internal constant WBTC_A_TOKEN = 0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8;

  address internal constant WBTC_V_TOKEN = 0x40aAbEf1aa8f0eEc637E0E7d92fbfFB2F26A8b7B;

  address internal constant WBTC_S_TOKEN = 0xA1773F1ccF6DB192Ad8FE826D15fe1d328B03284;

  address internal constant WBTC_ORACLE = 0x230E0321Cf38F09e247e50Afc7801EA2351fe56F;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;

  address internal constant USDC_UNDERLYING = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  address internal constant USDC_A_TOKEN = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;

  address internal constant USDC_V_TOKEN = 0x72E95b8931767C79bA4EeE721354d6E99a61D004;

  address internal constant USDC_S_TOKEN = 0xB0fe3D292f4bd50De902Ba5bDF120Ad66E9d7a39;

  address internal constant USDC_ORACLE = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xD6293edBB2E5E0687a79F01BEcd51A778d59D1c5;

  address internal constant DAI_UNDERLYING = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  address internal constant DAI_A_TOKEN = 0x018008bfb33d285247A21d44E50697654f754e63;

  address internal constant DAI_V_TOKEN = 0xcF8d0c70c850859266f5C338b38F9D663181C314;

  address internal constant DAI_S_TOKEN = 0x413AdaC9E2Ef8683ADf5DDAEce8f19613d60D1bb;

  address internal constant DAI_ORACLE = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x694d4cFdaeE639239df949b6E24Ff8576A00d1f2;

  address internal constant LINK_UNDERLYING = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

  address internal constant LINK_A_TOKEN = 0x5E8C8A7243651DB1384C0dDfDbE39761E8e7E51a;

  address internal constant LINK_V_TOKEN = 0x4228F8895C7dDA20227F6a5c6751b8Ebf19a6ba8;

  address internal constant LINK_S_TOKEN = 0x63B1129ca97D2b9F97f45670787Ac12a9dF1110a;

  address internal constant LINK_ORACLE = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;

  address internal constant AAVE_UNDERLYING = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

  address internal constant AAVE_A_TOKEN = 0xA700b4eB416Be35b2911fd5Dee80678ff64fF6C9;

  address internal constant AAVE_V_TOKEN = 0xBae535520Abd9f8C85E58929e0006A2c8B372F74;

  address internal constant AAVE_S_TOKEN = 0x268497bF083388B1504270d0E717222d3A87D6F2;

  address internal constant AAVE_ORACLE = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x24701A6368Ff6D2874d6b8cDadd461552B8A5283;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Fantom {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  IPool internal constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xfd6f3c1845604C8AE6c6E402ad17fb9885160754);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

  address internal constant ACL_ADMIN = 0x39CB97b105173b56b5a2b4b33AD25d6a50E6c949;

  address internal constant COLLECTOR = 0xBe85413851D195fC6341619cD68BfDc26a25b928;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xc0F0cFBbd0382BcE3B93234E4BFb31b2aaBE36aD);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;

  address internal constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x770ef9f4fe897e59daCc474EF11238303F9552b6;

  address internal constant WETH_GATEWAY = 0x1DcDA4de2Bf6c7AD9a34788D22aE6b7d55016e1f;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0xE387c6053CE8EC9f8C3fa5cE085Af73114a695d3;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x1408401B2A7E28cB747b3e258D0831Fc926bAC51;

  address internal constant WALLET_BALANCE_PROVIDER = 0xBc790382B3686abffE4be14A030A96aC6154023a;

  address internal constant UI_POOL_DATA_PROVIDER = 0xddf65434502E459C22263BE2ed7cF0f1FaFD44c0;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x67Da261c14fd94cE7fDd77a0A8476E5b244089A9;
}

library AaveV3FantomAssets {
  address internal constant DAI_UNDERLYING = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;

  address internal constant DAI_A_TOKEN = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

  address internal constant DAI_V_TOKEN = 0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC;

  address internal constant DAI_S_TOKEN = 0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B;

  address internal constant DAI_ORACLE = 0x91d5DEFAFfE2854C7D02F50c80FA1fdc8A721e52;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xA9F3C3caE095527061e6d270DBE163693e6fda9D;

  address internal constant LINK_UNDERLYING = 0xb3654dc3D10Ea7645f8319668E8F54d2574FBdC8;

  address internal constant LINK_A_TOKEN = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

  address internal constant LINK_V_TOKEN = 0x953A573793604aF8d41F306FEb8274190dB4aE0e;

  address internal constant LINK_S_TOKEN = 0x89D976629b7055ff1ca02b927BA3e020F22A44e4;

  address internal constant LINK_ORACLE = 0x221C773d8647BC3034e91a0c47062e26D20d97B4;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x4aa694e6c06D6162d95BE98a2Df6a521d5A7b521;

  address internal constant USDC_UNDERLYING = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;

  address internal constant USDC_A_TOKEN = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

  address internal constant USDC_V_TOKEN = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  address internal constant USDC_S_TOKEN = 0x307ffe186F84a3bc2613D1eA417A5737D69A7007;

  address internal constant USDC_ORACLE = 0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant BTC_UNDERLYING = 0x321162Cd933E2Be498Cd2267a90534A804051b11;

  address internal constant BTC_A_TOKEN = 0x078f358208685046a11C85e8ad32895DED33A249;

  address internal constant BTC_V_TOKEN = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;

  address internal constant BTC_S_TOKEN = 0x633b207Dd676331c413D4C013a6294B0FE47cD0e;

  address internal constant BTC_ORACLE = 0x8e94C22142F4A64b99022ccDd994f4e9EC86E4B4;

  address internal constant BTC_INTEREST_RATE_STRATEGY = 0x4aa694e6c06D6162d95BE98a2Df6a521d5A7b521;

  address internal constant ETH_UNDERLYING = 0x74b23882a30290451A17c44f4F05243b6b58C76d;

  address internal constant ETH_A_TOKEN = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;

  address internal constant ETH_V_TOKEN = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;

  address internal constant ETH_S_TOKEN = 0xD8Ad37849950903571df17049516a5CD4cbE55F6;

  address internal constant ETH_ORACLE = 0x11DdD3d147E5b83D01cee7070027092397d63658;

  address internal constant ETH_INTEREST_RATE_STRATEGY = 0x4aa694e6c06D6162d95BE98a2Df6a521d5A7b521;

  address internal constant fUSDT_UNDERLYING = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;

  address internal constant fUSDT_A_TOKEN = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;

  address internal constant fUSDT_V_TOKEN = 0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7;

  address internal constant fUSDT_S_TOKEN = 0x70eFfc565DB6EEf7B927610155602d31b670e802;

  address internal constant fUSDT_ORACLE = 0xF64b636c5dFe1d3555A847341cDC449f612307d0;

  address internal constant fUSDT_INTEREST_RATE_STRATEGY =
    0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant AAVE_UNDERLYING = 0x6a07A792ab2965C72a5B8088d3a069A7aC3a993B;

  address internal constant AAVE_A_TOKEN = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;

  address internal constant AAVE_V_TOKEN = 0xE80761Ea617F66F96274eA5e8c37f03960ecC679;

  address internal constant AAVE_S_TOKEN = 0xfAeF6A702D15428E588d4C0614AEFb4348D83D48;

  address internal constant AAVE_ORACLE = 0xE6ecF7d2361B6459cBb3b4fb065E0eF4B175Fe74;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x4aa694e6c06D6162d95BE98a2Df6a521d5A7b521;

  address internal constant WFTM_UNDERLYING = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

  address internal constant WFTM_A_TOKEN = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  address internal constant WFTM_V_TOKEN = 0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;

  address internal constant WFTM_S_TOKEN = 0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E;

  address internal constant WFTM_ORACLE = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc;

  address internal constant WFTM_INTEREST_RATE_STRATEGY =
    0x4aa694e6c06D6162d95BE98a2Df6a521d5A7b521;

  address internal constant CRV_UNDERLYING = 0x1E4F97b9f9F913c46F1632781732927B9019C68b;

  address internal constant CRV_A_TOKEN = 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf;

  address internal constant CRV_V_TOKEN = 0x77CA01483f379E58174739308945f044e1a764dc;

  address internal constant CRV_S_TOKEN = 0x08Cb71192985E936C7Cd166A8b268035e400c3c3;

  address internal constant CRV_ORACLE = 0xa141D7E3B44594cc65142AE5F2C7844Abea66D2B;

  address internal constant CRV_INTEREST_RATE_STRATEGY = 0x4aa694e6c06D6162d95BE98a2Df6a521d5A7b521;

  address internal constant SUSHI_UNDERLYING = 0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC;

  address internal constant SUSHI_A_TOKEN = 0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA;

  address internal constant SUSHI_V_TOKEN = 0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907;

  address internal constant SUSHI_S_TOKEN = 0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841;

  address internal constant SUSHI_ORACLE = 0xCcc059a1a17577676c8673952Dc02070D29e5a66;

  address internal constant SUSHI_INTEREST_RATE_STRATEGY =
    0x4aa694e6c06D6162d95BE98a2Df6a521d5A7b521;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3FantomTestnet {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xC809bea009Ca8DAA680f6A1c4Ca020D550210736);

  IPool internal constant POOL = IPool(0x95b1B6470eAF8cC4A03d2D44C6b54eBB8ede8C30);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x91ce34267F11EcB54b2601Ed1C43188cE465dabB);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xDd6BCF7EF3dbA79b03D61De36Cc292661c664efD);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x221b58772526669172acCA8B68f6905086c81569);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xbB27a8D0D19fB0c43364Bd26AEB8Fc131F4dA40F);

  address internal constant ACL_ADMIN = 0xaDdfe0b2342800ebD67C30d1c2Bd479E4D498BD5;

  address internal constant COLLECTOR = 0xE4A880b56B4790632753c7393cC51FefFd965678;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0x03766578530956F5f9d7726ED71d55277093cA20);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0xa45B99c552a2D576B272cc9bFbEB131427ae5148;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xd116069eaBD82DA3A18CA9c5231c1DbB3279Dc0b;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x7074f39fb7A91C251798DAF614dB4e9893c89349;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x7533eACa1cfea1Ade1df6D3fa662E98CFC85cBB9;

  address internal constant EMISSION_MANAGER = 0xAf2E5b5cf4aCae5E670eE9619eEd7B90669215f5;

  address internal constant WETH_GATEWAY = 0x87770f04Bbece8092d777860907798138825f303;

  address internal constant FAUCET = 0x77523cB4402d241e324Bcf1EcEa91C4f63033B1b;

  address internal constant WALLET_BALANCE_PROVIDER = 0x4E2e1F992A2ba1137fB6e1FcfbEdcaC95cA788e5;

  address internal constant UI_POOL_DATA_PROVIDER = 0x9a00043F98941DD4e02E1c7e78676df64F5e37a6;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xFBBdDFfFFcFBD55a6DF325d2be47077875Ef9eB9;
}

library AaveV3FantomTestnetAssets {
  address internal constant DAI_UNDERLYING = 0xe55C8c2c23Ad6953FD672b527b2A6d919Acf1834;

  address internal constant DAI_A_TOKEN = 0x65501cE215b85373D41ad0E6ACA30610F00a6492;

  address internal constant DAI_V_TOKEN = 0x5ad7c16C19df1fe482dec5166641CCAD5A49bf6F;

  address internal constant DAI_S_TOKEN = 0xB300d9ff57b78eD7650971700228f791c63b789d;

  address internal constant DAI_ORACLE = 0xe3c1FEBf477D5C181C6A3F15D36Ef2a0bB32B524;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xF444aB2ecdF7267B2A179BD2e9291A6f09D0235F;

  address internal constant LINK_UNDERLYING = 0x4Ba8C22516d707C0cf1aC8825fc0eD87e5D3A8D3;

  address internal constant LINK_A_TOKEN = 0x40aA1a9eB67175148287F632264270de52fABf03;

  address internal constant LINK_V_TOKEN = 0x892e27a1E2dBffa5B3118b0E1d19f97409f1af64;

  address internal constant LINK_S_TOKEN = 0x24Ef8065bd2edFa1cC1A44337829ABE3a5962d55;

  address internal constant LINK_ORACLE = 0x628FE388A163697892a6fBBfdaf8C3984e25B08f;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x036cd658D892512d403bFB12b1E724e801D36888;

  address internal constant USDC_UNDERLYING = 0x382E773695e6877B0BDc9d02DFe1594061879fE5;

  address internal constant USDC_A_TOKEN = 0x8dAC4Da226Cc4569d47d0fB32bb4dF1CB21dbEA4;

  address internal constant USDC_V_TOKEN = 0xe51e534C5811Ee58eA4783AdD6151DE8E4AeEc4e;

  address internal constant USDC_S_TOKEN = 0x5B57ed717B5996AE21785c931ADDc7Dd99FFe2dC;

  address internal constant USDC_ORACLE = 0xD0068361952af0466E3E9049DE656052ea66C334;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x6E93A90455ca48d673DC983fC15A7a9a18c57A9E;

  address internal constant WBTC_UNDERLYING = 0xe981B1B879698E4Fc1ECcD0534cC1814e9D28A8E;

  address internal constant WBTC_A_TOKEN = 0x73c882e0d7D70BCa0a3b8AE383521d9F87C55c05;

  address internal constant WBTC_V_TOKEN = 0x9B972Ab5cF3abd0E0c5F06390348bfc61813487c;

  address internal constant WBTC_S_TOKEN = 0x4F6494592DC18DC039Bc380C296b86e2840eDF27;

  address internal constant WBTC_ORACLE = 0xC1f47cBBe62440007b40156599f402640b8928dC;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x036cd658D892512d403bFB12b1E724e801D36888;

  address internal constant WETH_UNDERLYING = 0xF8069ef8a91c5a189b96B293eE4Fc4F9f6CC351b;

  address internal constant WETH_A_TOKEN = 0x58f3B0F787b91b76CA6ae7c22D20C6c8D70356DA;

  address internal constant WETH_V_TOKEN = 0xc0cB95ee730E0a678Ffac6BAA4c94247b3b58a30;

  address internal constant WETH_S_TOKEN = 0x588ba3a432E8707a73a37f8c6CF8638fb9e3b51A;

  address internal constant WETH_ORACLE = 0xF89FaD9575bc3aEC9cC7F3970e16cCEDfe7e75b9;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x036cd658D892512d403bFB12b1E724e801D36888;

  address internal constant USDT_UNDERLYING = 0x6e642065B9976FbDF94aB373a4833A48F040BfF3;

  address internal constant USDT_A_TOKEN = 0x898c11bc7EdB1a65c34DC93EbB6E4083dF22070a;

  address internal constant USDT_V_TOKEN = 0x44008ff9524Ab2f3b772D3DF6d4ae102D868252C;

  address internal constant USDT_S_TOKEN = 0x1dE9819c72A3108cbD040af1A18eB2091f5a8eA4;

  address internal constant USDT_ORACLE = 0xa4D1912eE5e1728E2F79a9485AEFf2F2717cadFc;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x6E93A90455ca48d673DC983fC15A7a9a18c57A9E;

  address internal constant AAVE_UNDERLYING = 0x84a38cc4B26238EAeDaCfE6AbB66d61631692Bad;

  address internal constant AAVE_A_TOKEN = 0x80777Cf31Db46A3e290424357ccAA1D4FC5FD354;

  address internal constant AAVE_V_TOKEN = 0xDAe0cB3acb8c4c6943856A8236b0E1e5Ec77D78E;

  address internal constant AAVE_S_TOKEN = 0x66420b7dDe16409e097478d49F618EbF9B0Ea002;

  address internal constant AAVE_ORACLE = 0x5bC954f4D73AB2aFe159D6D77C26FbD94629F48D;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x036cd658D892512d403bFB12b1E724e801D36888;

  address internal constant WFTM_UNDERLYING = 0x654a628265B614E50BBd79a2FD8A804637DBedd8;

  address internal constant WFTM_A_TOKEN = 0xF98e0E2cd0FC052117ae33Bde94491657E51067A;

  address internal constant WFTM_V_TOKEN = 0x563C34C6e663EE037663c6F0e785cBFB2EB7E123;

  address internal constant WFTM_S_TOKEN = 0xAd3d7B7f740D51Df415d2EC9378a26515ad7c247;

  address internal constant WFTM_ORACLE = 0x75b0A71497a99EaCee17682Bb9F5A36988a6314c;

  address internal constant WFTM_INTEREST_RATE_STRATEGY =
    0x036cd658D892512d403bFB12b1E724e801D36888;

  address internal constant CRV_UNDERLYING = 0x16606e1F5fCb4726C4f90eD45285ae46c828AE2F;

  address internal constant CRV_A_TOKEN = 0xc4C39544C18b021e41d9cbC1A455c00633a6d814;

  address internal constant CRV_V_TOKEN = 0x5Cab370F5853f4d3B91055d4F282D5a2f3ad35a3;

  address internal constant CRV_S_TOKEN = 0x5cb952a42a247ADB95e0d00245870CA922b1CC4B;

  address internal constant CRV_ORACLE = 0x490f3CA1A10B291644cE2c8b9c343577DF8f1d6f;

  address internal constant CRV_INTEREST_RATE_STRATEGY = 0x036cd658D892512d403bFB12b1E724e801D36888;

  address internal constant SUSHI_UNDERLYING = 0x09898A842B07A48dCfaA3D3D8BE6A229798b07C1;

  address internal constant SUSHI_A_TOKEN = 0xA17871b422c084669cf66f4F38F9Bf640Cac6d73;

  address internal constant SUSHI_V_TOKEN = 0x2600d237C29a6b1d21de55f8a48823587DA0dCBE;

  address internal constant SUSHI_S_TOKEN = 0xb46bD847CeE2b28d0372cd4f3618bEaE0e5Ea283;

  address internal constant SUSHI_ORACLE = 0x9dfbb146d9e2b74d8E5C0Db543c9b9CFB4BFD65e;

  address internal constant SUSHI_INTEREST_RATE_STRATEGY =
    0x036cd658D892512d403bFB12b1E724e801D36888;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Fuji {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0x220c6A7D868FC38ECB47d5E69b99e9906300286A);

  IPool internal constant POOL = IPool(0xf319Bb55994dD1211bC34A7A26A336C6DD0B1b00);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8F3433F242C852916Bd1850916De1C0767E88DDf);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xB9107870a2e22b9cd4B51ED5483212Cb9eAE0329);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x0B59871DF373136bB7753A7A2675b47ffA0ccC86);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0x2faBdE81944E97D6dbAAa71BEDAF36229F51bC12);

  address internal constant ACL_ADMIN = 0xfA0e305E0f46AB04f00ae6b5f4560d61a2183E00;

  address internal constant COLLECTOR = 0x7768248E1Ff75612c18324bad06bb393c1206980;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xA63d1Ee9043Ba6Ae6608A87DaE082826b586eAE1);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0xe39e0498cB9df939b992f935f95936eAEdA7431c;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0x4C2A4fD3686701AFb38d8722256eF52F519c179e;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x960B582cbc9B25865B1bcc301057089348dF75A9;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x7CCea089F3BFd4A4bc40d1262741586138250f13;

  address internal constant EMISSION_MANAGER = 0xfc2a90fB867d5562D8a9270632d1afF8AfD3952a;

  address internal constant WETH_GATEWAY = 0x8f57153F18b7273f9A814b93b31Cb3f9b035e7C2;

  address internal constant FAUCET = 0x66B3b92Fb1b2635504Cd5f878E26ABD8826aAf1E;

  address internal constant WALLET_BALANCE_PROVIDER = 0xd2495B9f9F78092858e09e294Ed5c17Dbc5fCfA8;

  address internal constant UI_POOL_DATA_PROVIDER = 0x08D07a855306400c8e499664f7f5247046274C77;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xD764968BdAAdD2120F0E48a16fB29a6c73c13340;
}

library AaveV3FujiAssets {
  address internal constant DAI_UNDERLYING = 0xE8BA4db946a310A1Aca92571A53D3bdE834B5409;

  address internal constant DAI_A_TOKEN = 0x7021eB315AD2Ce787E3A6FD1c4a136c9722457Cc;

  address internal constant DAI_V_TOKEN = 0x8EBEFA6B010d394F18F92F0d24f6e5B69BdED45d;

  address internal constant DAI_S_TOKEN = 0x4F54278bA65C52Aa23ca248ddcE4a0b31Dd2Fb03;

  address internal constant DAI_ORACLE = 0x52788e5ad08fCD33C8D2f5dcF796B3418BB35b9a;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x6aa4E1d86AE50e0D8Bc25b4A5F579c32b922B398;

  address internal constant LINK_UNDERLYING = 0x1410420D603293cc0Eec6eC0234a5c4b4061f4B1;

  address internal constant LINK_A_TOKEN = 0x5e49dd6BDF18bc83Dec41268E7A9663Fe5161C33;

  address internal constant LINK_V_TOKEN = 0x007a7a7db86d1E463450FF694925Fd852A3B3B2A;

  address internal constant LINK_S_TOKEN = 0xC0E73A262D8814fA2345f8edb7824D5B252DbF1e;

  address internal constant LINK_ORACLE = 0x0D1CB66809dC0044f91816065eF45B6CbCF70a11;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x0C180A0174Bf93aa0FE70B7AA6dB536a87e74A20;

  address internal constant USDC_UNDERLYING = 0x6a17716Ce178e84835cfA73AbdB71cb455032456;

  address internal constant USDC_A_TOKEN = 0x2c4a078f1FC5B545f3103c870d22f9AC5F0F673E;

  address internal constant USDC_V_TOKEN = 0xc4f306cf363eE810FDe59F95Ed8a14404B4A0349;

  address internal constant USDC_S_TOKEN = 0x6982F4511E411D3Aaf11070D578c04F95CBa2839;

  address internal constant USDC_ORACLE = 0x0158dA745DfEbF261933FF8374BEFa13d7748A3f;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x1e02E865c9B6a416858354cd809d5Ea945c53B99;

  address internal constant WBTC_UNDERLYING = 0x9BDf15A56a03A542eA588137233013aBC5A4B98a;

  address internal constant WBTC_A_TOKEN = 0xfe89d04dF1764d93283cd0c9D301fda50c725908;

  address internal constant WBTC_V_TOKEN = 0x3Ba320135f8A9Da1cAbb8365adD602D8bB0Ff678;

  address internal constant WBTC_S_TOKEN = 0x65BE738D88E19aA49fF929C4CD8eCf46b976734C;

  address internal constant WBTC_ORACLE = 0x9734b9BE76885FF2806963cE49c6a74dBF166EE3;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x0C180A0174Bf93aa0FE70B7AA6dB536a87e74A20;

  address internal constant WETH_UNDERLYING = 0x4288C8fa6A7Dd3fD62cc8306883df6E68e0627A0;

  address internal constant WETH_A_TOKEN = 0x35295b2935930E1c2dBD9dcf93A905F49Df83DDb;

  address internal constant WETH_V_TOKEN = 0x131a0894F00b839dCea1321330699ce3e05Cc0CF;

  address internal constant WETH_S_TOKEN = 0x11Bb67Ed88A7a9DceD0d8E13cb43673B187da109;

  address internal constant WETH_ORACLE = 0x5Ced27e6b7D0b089E12c07aFCFaAB0Ea9A7E9dA9;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x0C180A0174Bf93aa0FE70B7AA6dB536a87e74A20;

  address internal constant USDT_UNDERLYING = 0x0343A9099f42868C1E8Ae9e501Abc043FD5fD816;

  address internal constant USDT_A_TOKEN = 0x6392E5A601620aC1E28747f3428861dc4562CFfA;

  address internal constant USDT_V_TOKEN = 0x02760687443C9a7dE06908d5D0293a6129C93966;

  address internal constant USDT_S_TOKEN = 0xE4387DeEc42FB2376A3DC787F61B14b56590E6C1;

  address internal constant USDT_ORACLE = 0x70488f326010c740f4DfAF4Fe1aD94969aCb7Af4;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x1e02E865c9B6a416858354cd809d5Ea945c53B99;

  address internal constant AAVE_UNDERLYING = 0x6B07B2dD6879E56f522C79531cAa2A9306304F05;

  address internal constant AAVE_A_TOKEN = 0xC5dEA83EF977aFD4725f9d16936a049eD59F2D2e;

  address internal constant AAVE_V_TOKEN = 0xE40C53385bf5DEeBB51f9cD1381A84455f9B3efd;

  address internal constant AAVE_S_TOKEN = 0xD3b761A76c07bB68C2eA69260ffF73D6DF086973;

  address internal constant AAVE_ORACLE = 0xEaC5EbD74Ff5111E18eBc0bbFCc8eA5786685D5A;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x0C180A0174Bf93aa0FE70B7AA6dB536a87e74A20;

  address internal constant WAVAX_UNDERLYING = 0x8d3d33232bfcb7B901846AE7B8E84aE282ee2882;

  address internal constant WAVAX_A_TOKEN = 0xe4EAaBB239E68e567611087b46A43984A4376EA6;

  address internal constant WAVAX_V_TOKEN = 0xf264EEDB24a78Df11e0ABDcf050e2f864F1726E5;

  address internal constant WAVAX_S_TOKEN = 0x049eE05d9F1475B70f1620DeF48A263f60e8e24b;

  address internal constant WAVAX_ORACLE = 0x1Cec5527d9C7513a9e06BC54e107d286E62fa75F;

  address internal constant WAVAX_INTEREST_RATE_STRATEGY =
    0x0C180A0174Bf93aa0FE70B7AA6dB536a87e74A20;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Goerli {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xC911B590248d127aD18546B186cC6B324e99F02c);

  IPool internal constant POOL = IPool(0x7b5C526B7F8dfdff278b4a3e045083FBA4028790);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x3b35da485b4daceFf52d499aa6C14dFE233a51CD);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x9F616c65b5298E24e155E4486e114516BC635b63);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0xa41E284482F9923E265832bE59627d91432da76C);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0x30417E3105a111c4e8C697Df66d26fC68d43656F);

  address internal constant ACL_ADMIN = 0xfA0e305E0f46AB04f00ae6b5f4560d61a2183E00;

  address internal constant COLLECTOR = 0xF45122b5fcfA72550B8Ed2D48f3aEeFcA1167415;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0x2DA49A23658d231b129F43bea4903C3682ab0Ed6);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0xbE540b86E7b61624458ca928e9065e2133dBCA3a;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0x1a80eF9C6a2eAD07E8F42FB1CBb426587EEe0D7D;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xB5024bED4fb5ca8D9ea5E8b016FC4dbe50e94a32;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xB8A83A393F08F35A65dF96B3Ca6b1B8841765c8A;

  address internal constant EMISSION_MANAGER = 0xF2F4146c7478f0B0285AdbcB4AcC1EfcAc7564C7;

  address internal constant WETH_GATEWAY = 0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;

  address internal constant FAUCET = 0xA70D8aD6d26931d0188c642A66de3B6202cDc5FA;

  address internal constant WALLET_BALANCE_PROVIDER = 0xe0bb4593f74B804B9aBd9a2Ec6C71663cEE64E29;

  address internal constant UI_POOL_DATA_PROVIDER = 0xb00A75686293Fea5DA122E8361f6815A0B0AF48E;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xf4Ce3624c8D047aF8b069D044f00bF6774B4dEc0;
}

library AaveV3GoerliAssets {
  address internal constant DAI_UNDERLYING = 0xBa8DCeD3512925e52FE67b1b5329187589072A55;

  address internal constant DAI_A_TOKEN = 0xADD98B0342e4094Ec32f3b67Ccfd3242C876ff7a;

  address internal constant DAI_V_TOKEN = 0xEAEc6590FDA7981b7DE06Bae7C1De27cFc262818;

  address internal constant DAI_S_TOKEN = 0xF918faA5A5Ab892DbEa5D15Ef4a4F846f8826AA5;

  address internal constant DAI_ORACLE = 0x73221008d4d6908f4120d99b0Dd66D5F24095f6f;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x5F36b9d15edf703C03F840f21Bb7aF6B9534DC84;

  address internal constant LINK_UNDERLYING = 0xe9c4393a23246293a8D31BF7ab68c17d4CF90A29;

  address internal constant LINK_A_TOKEN = 0x493DC51c35F7ddD891262b8733C63eABaf14786f;

  address internal constant LINK_V_TOKEN = 0x76a79F46329a8EB7d7d1c50F45a4090707588864;

  address internal constant LINK_S_TOKEN = 0xc810906266Fcfca25CC8E41CAc029cdCF3687611;

  address internal constant LINK_ORACLE = 0xd541Fa63f253b04BBc2e3E134a4Ac32814bc5558;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x93AFC6dCB110F064a152E55B10b91B743ea56234;

  address internal constant USDC_UNDERLYING = 0x65aFADD39029741B3b8f0756952C74678c9cEC93;

  address internal constant USDC_A_TOKEN = 0x8Be59D90A7Dc679C5cE5a7963cD1082dAB499918;

  address internal constant USDC_V_TOKEN = 0x4DAe67e69aCed5ca8f99018246e6476F82eBF9ab;

  address internal constant USDC_S_TOKEN = 0x4A1504b9E88DFF2651dD0E18eF7b8A1bc41f182E;

  address internal constant USDC_ORACLE = 0x6078279E3f3F09D49c21bdCD87906da4CBCd4f5b;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x3B772b892A1025a990800F878Fe46A7aF4b23D14;

  address internal constant WBTC_UNDERLYING = 0x45AC379F019E48ca5dAC02E54F406F99F5088099;

  address internal constant WBTC_A_TOKEN = 0x005B0d11379c4c04C0B726eE0BE55feb50b59f81;

  address internal constant WBTC_V_TOKEN = 0xB2353aB4dcbEBa08EB7Ea0F098E90aEC41008BB5;

  address internal constant WBTC_S_TOKEN = 0x87448E7219E0a0D8E226Ae61120110590366Be33;

  address internal constant WBTC_ORACLE = 0x2cCBfB7333c331F8Bba569c17172C45D704a3234;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x93AFC6dCB110F064a152E55B10b91B743ea56234;

  address internal constant WETH_UNDERLYING = 0xCCB14936C2E000ED8393A571D15A2672537838Ad;

  address internal constant WETH_A_TOKEN = 0x7649e0d153752c556b8b23DB1f1D3d42993E83a5;

  address internal constant WETH_V_TOKEN = 0xff3284Be0C687C21cCB18a8e61a27AeC72C520bc;

  address internal constant WETH_S_TOKEN = 0xaf082611873a9b99E5e3A7C5Bea3bdb93AfA044C;

  address internal constant WETH_ORACLE = 0xCaD38d22431460c5c4C71F4a0f4896E895dc8907;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x93AFC6dCB110F064a152E55B10b91B743ea56234;

  address internal constant USDT_UNDERLYING = 0x2E8D98fd126a32362F2Bd8aA427E59a1ec63F780;

  address internal constant USDT_A_TOKEN = 0xf3368D1383cE079006E5D1d56878b92bbf08F1c2;

  address internal constant USDT_V_TOKEN = 0xF2C9Aa2B0Fc747fC0327B335541FD34D180f8A30;

  address internal constant USDT_S_TOKEN = 0x5Da3eF536274B97f88AAB30a54f0cC7604E347f3;

  address internal constant USDT_ORACLE = 0xBF1a17E93c04B1DA5F49d23DBB0811F6D14429a1;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x3B772b892A1025a990800F878Fe46A7aF4b23D14;

  address internal constant AAVE_UNDERLYING = 0x8153A21dFeB1F67024aA6C6e611432900FF3dcb9;

  address internal constant AAVE_A_TOKEN = 0xB7a80Aff22D3dA5dbfd109f33D8305A34A696D1c;

  address internal constant AAVE_V_TOKEN = 0x1ef9ae399F3C4738677A9BfC5d561765392dd333;

  address internal constant AAVE_S_TOKEN = 0x54Ecb7FAfe1c30906B7d0c6b1C5f0f3941072bfe;

  address internal constant AAVE_ORACLE = 0x2845bAE57dA6Ca97031b4816eC566a048B7a282F;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x93AFC6dCB110F064a152E55B10b91B743ea56234;

  address internal constant EURS_UNDERLYING = 0xBC33cfbD55EA6e5B97C6da26F11160ae82216E2b;

  address internal constant EURS_A_TOKEN = 0x5a6Ba5e8e7091F64D4bb6729830E5EAf00Bb943d;

  address internal constant EURS_V_TOKEN = 0x166C9CbE2E31Ae3C26cE4C18278BF5dbED82484C;

  address internal constant EURS_S_TOKEN = 0xf4874d1d69E07aDdB8807150ba33AC4d59C8dA3f;

  address internal constant EURS_ORACLE = 0x2437ec93F3491d57B32850827903262e44281Da4;

  address internal constant EURS_INTEREST_RATE_STRATEGY =
    0x3B772b892A1025a990800F878Fe46A7aF4b23D14;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Harmony {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  IPool internal constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x3C90887Ede8D65ccb2777A5d577beAb2548280AD);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

  address internal constant ACL_ADMIN = 0xb2f0C5f37f4beD2cB51C44653cD5D84866BDcd2D;

  address internal constant COLLECTOR = 0x8A020d92D6B119978582BE4d3EdFdC9F7b28BF31;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xeaC16519923774Fd7723d3D5E442a1e2E46BA962);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;

  address internal constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x770ef9f4fe897e59daCc474EF11238303F9552b6;

  address internal constant WETH_GATEWAY = 0xE387c6053CE8EC9f8C3fa5cE085Af73114a695d3;

  address internal constant WALLET_BALANCE_PROVIDER = 0xBc790382B3686abffE4be14A030A96aC6154023a;

  address internal constant UI_POOL_DATA_PROVIDER = 0x1DcDA4de2Bf6c7AD9a34788D22aE6b7d55016e1f;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xf7a60467aBb8A3240A0382b22E1B03c7d4F59Da5;
}

library AaveV3HarmonyAssets {
  address internal constant ONE_DAI_UNDERLYING = 0xEf977d2f931C1978Db5F6747666fa1eACB0d0339;

  address internal constant ONE_DAI_A_TOKEN = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

  address internal constant ONE_DAI_V_TOKEN = 0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC;

  address internal constant ONE_DAI_S_TOKEN = 0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B;

  address internal constant ONE_DAI_ORACLE = 0xF8326D22b2CaFF4880115E92161c324AbC5e0395;

  address internal constant ONE_DAI_INTEREST_RATE_STRATEGY =
    0xfab05a6aF585da2F96e21452F91E812452996BD3;

  address internal constant LINK_UNDERLYING = 0x218532a12a389a4a92fC0C5Fb22901D1c19198aA;

  address internal constant LINK_A_TOKEN = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

  address internal constant LINK_V_TOKEN = 0x953A573793604aF8d41F306FEb8274190dB4aE0e;

  address internal constant LINK_S_TOKEN = 0x89D976629b7055ff1ca02b927BA3e020F22A44e4;

  address internal constant LINK_ORACLE = 0xD54F119D10901b4509610eA259A63169647800C4;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x145dE30c929a065582da84Cf96F88460dB9745A7;

  address internal constant ONE_USDC_UNDERLYING = 0x985458E523dB3d53125813eD68c274899e9DfAb4;

  address internal constant ONE_USDC_A_TOKEN = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

  address internal constant ONE_USDC_V_TOKEN = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  address internal constant ONE_USDC_S_TOKEN = 0x307ffe186F84a3bc2613D1eA417A5737D69A7007;

  address internal constant ONE_USDC_ORACLE = 0xA45A41be2D8419B60A6CE2Bc393A0B086b8B3bda;

  address internal constant ONE_USDC_INTEREST_RATE_STRATEGY =
    0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant ONE_WBTC_UNDERLYING = 0x3095c7557bCb296ccc6e363DE01b760bA031F2d9;

  address internal constant ONE_WBTC_A_TOKEN = 0x078f358208685046a11C85e8ad32895DED33A249;

  address internal constant ONE_WBTC_V_TOKEN = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;

  address internal constant ONE_WBTC_S_TOKEN = 0x633b207Dd676331c413D4C013a6294B0FE47cD0e;

  address internal constant ONE_WBTC_ORACLE = 0x3C41439Eb1bF3BA3b2C3f8C921088b267f8d11f4;

  address internal constant ONE_WBTC_INTEREST_RATE_STRATEGY =
    0xb023e699F5a33916Ea823A16485e259257cA8Bd1;

  address internal constant ONE_ETH_UNDERLYING = 0x6983D1E6DEf3690C4d616b13597A09e6193EA013;

  address internal constant ONE_ETH_A_TOKEN = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;

  address internal constant ONE_ETH_V_TOKEN = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;

  address internal constant ONE_ETH_S_TOKEN = 0xD8Ad37849950903571df17049516a5CD4cbE55F6;

  address internal constant ONE_ETH_ORACLE = 0xbaf7C8149D586055ed02c286367A41E0aDA96b7C;

  address internal constant ONE_ETH_INTEREST_RATE_STRATEGY =
    0xb023e699F5a33916Ea823A16485e259257cA8Bd1;

  address internal constant ONE_USDT_UNDERLYING = 0x3C2B8Be99c50593081EAA2A724F0B8285F5aba8f;

  address internal constant ONE_USDT_A_TOKEN = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;

  address internal constant ONE_USDT_V_TOKEN = 0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7;

  address internal constant ONE_USDT_S_TOKEN = 0x70eFfc565DB6EEf7B927610155602d31b670e802;

  address internal constant ONE_USDT_ORACLE = 0x5CaAeBE5C69a8287bffB9d00b5231bf7254145bf;

  address internal constant ONE_USDT_INTEREST_RATE_STRATEGY =
    0xf4a0039F2d4a2EaD5216AbB6Ae4C4C3AA2dB9b82;

  address internal constant ONE_AAVE_UNDERLYING = 0xcF323Aad9E522B93F11c352CaA519Ad0E14eB40F;

  address internal constant ONE_AAVE_A_TOKEN = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;

  address internal constant ONE_AAVE_V_TOKEN = 0xE80761Ea617F66F96274eA5e8c37f03960ecC679;

  address internal constant ONE_AAVE_S_TOKEN = 0xfAeF6A702D15428E588d4C0614AEFb4348D83D48;

  address internal constant ONE_AAVE_ORACLE = 0x6EE1EfCCe688D5B79CB8a400870AF471c5282992;

  address internal constant ONE_AAVE_INTEREST_RATE_STRATEGY =
    0xb023e699F5a33916Ea823A16485e259257cA8Bd1;

  address internal constant WONE_UNDERLYING = 0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a;

  address internal constant WONE_A_TOKEN = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  address internal constant WONE_V_TOKEN = 0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;

  address internal constant WONE_S_TOKEN = 0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E;

  address internal constant WONE_ORACLE = 0xdCD81FbbD6c4572A69a534D8b8152c562dA8AbEF;

  address internal constant WONE_INTEREST_RATE_STRATEGY =
    0x145dE30c929a065582da84Cf96F88460dB9745A7;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Mumbai {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xeb7A892BB04A8f836bDEeBbf60897A7Af1Bf5d7F);

  IPool internal constant POOL = IPool(0x0b913A76beFF3887d35073b8e5530755D60F78C7);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x1147c3fE425bB6596D08Baba106167b190897821);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xf0E6744a59177014738e1eF920dc676fb3b8CB62);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0xacB5aDd3029C5004f726e8411033E6202Bc3dd01);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0x18e94ec692587dEb6f64c3c8e234dB076aAf8A35);

  address internal constant ACL_ADMIN = 0xfA0e305E0f46AB04f00ae6b5f4560d61a2183E00;

  address internal constant COLLECTOR = 0x270EfFE95AE74FF6a6d839Ca1E7f89d1ddbdb920;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xCF5D1aB9C3bfE512b86BBA04cba8d21D842Aa656);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x67D1846E97B6541bA730f0C24899B0Ba3Be0D087;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xfaf04252248861B759709e10B1b746269370F0aa;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xF347E9FC8bD0a1Ad70F1AE6c1A499bbBaf4Cce6D;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xECA6044716E7489D58954FD68f709133E6cf65ce;

  address internal constant EMISSION_MANAGER = 0xC7C6294502d6f9d17A0023627D2417c9408D083A;

  address internal constant WETH_GATEWAY = 0x2a58E9bbb5434FdA7FF78051a4B82cb0EF669C17;

  address internal constant FAUCET = 0xB00b414F9E45ba73B44fFC3E3Ce64a806552cD02;

  address internal constant WALLET_BALANCE_PROVIDER = 0xdbaeF5FC90a979426E2cE5C3F0125430d0e2023e;

  address internal constant UI_POOL_DATA_PROVIDER = 0x928d9A76705aA6e4a6650BFb7E7912e413Fe7341;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0xf7Dd602B3Cf90B2A20FC0F84E0419BeE104BdF16;
}

library AaveV3MumbaiAssets {
  address internal constant DAI_UNDERLYING = 0xF14f9596430931E177469715c591513308244e8F;

  address internal constant DAI_A_TOKEN = 0xFAF6a49b4657D9c8dDa675c41cB9a05a94D3e9e9;

  address internal constant DAI_V_TOKEN = 0xBc4Fbe180979181f84209497320A03c65E1dc64B;

  address internal constant DAI_S_TOKEN = 0x7df8918f0DA9a9FB286E3dA272C33645b6812582;

  address internal constant DAI_ORACLE = 0x965D4174AE001261588e05DA5cF76328F840649C;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xfdCd171C0E8Ef10323Ee78a116320211aBeb9fFc;

  address internal constant LINK_UNDERLYING = 0x4e2f1E0dC4EAD962d3c3014e582d974b3cedF743;

  address internal constant LINK_A_TOKEN = 0x60f42c880B61D9114251882fC144395843D9839d;

  address internal constant LINK_V_TOKEN = 0x97BDaa1fD8bdb266f73C0E6095F39aa168d4509c;

  address internal constant LINK_S_TOKEN = 0x08FCe88114f6A89FcEe58EB16a0C1C90e74403f5;

  address internal constant LINK_ORACLE = 0xA15d000aA92Fa0633E612085B100516a1188dD0A;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant USDC_UNDERLYING = 0xe9DcE89B076BA6107Bb64EF30678efec11939234;

  address internal constant USDC_A_TOKEN = 0x9daBC9860F8792AeE427808BDeF1f77eFeF0f24E;

  address internal constant USDC_V_TOKEN = 0xdbFB1eE219CA788B02d50bA687a927ABf58A8fC0;

  address internal constant USDC_S_TOKEN = 0xe336CbD5416CDB6CE70bA16D9952A963a81A918d;

  address internal constant USDC_ORACLE = 0x8d5bFc1cA4f5623Bdbca8860537bF45B5C0347b6;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x03a06e4478b52cE3D378b8942712a623f06a4E8B;

  address internal constant WBTC_UNDERLYING = 0x97e8dE167322a3bCA28E8A49BC46F6Ce128FEC68;

  address internal constant WBTC_A_TOKEN = 0x7aF0Df3DD1b8ee7a70549bd3E3C902e7B24D32F9;

  address internal constant WBTC_V_TOKEN = 0x6b447f753e08a07f108A835A70E3bdBE1F6233e2;

  address internal constant WBTC_S_TOKEN = 0xAbF216E1640848B4eFFe9D23f283a12e96227C83;

  address internal constant WBTC_ORACLE = 0xbA3Eb31c99a9109Ad3702DbABF67983aD9Edb388;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant WETH_UNDERLYING = 0xD087ff96281dcf722AEa82aCA57E8545EA9e6C96;

  address internal constant WETH_A_TOKEN = 0xAA02A95942Cb7d48Ac8ad8C3b5D65E546eC3Ecd3;

  address internal constant WETH_V_TOKEN = 0x71Cf6ef87a3b0B7ceaacA66daB39b81972466B83;

  address internal constant WETH_S_TOKEN = 0xF2CFFd2c2f6c86E10a8Ab346d96DF5F30Ee2C53A;

  address internal constant WETH_ORACLE = 0x94DE72C71cA24f39779EbF9EB2c3BFe1096Ce629;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant USDT_UNDERLYING = 0xAcDe43b9E5f72a4F554D4346e69e8e7AC8F352f0;

  address internal constant USDT_A_TOKEN = 0xEF4aEDfD3552db80E8F5133ed5c27cebeD2fE015;

  address internal constant USDT_V_TOKEN = 0xbe9B550142De795A54d5BBec50ab562a95b303B4;

  address internal constant USDT_S_TOKEN = 0x776Ba5F425008977b27dcB9ab4859eFFb461ff9d;

  address internal constant USDT_ORACLE = 0x9B0E14C22410E7dBDc748Db5452Acc4ce0Ca8927;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x03a06e4478b52cE3D378b8942712a623f06a4E8B;

  address internal constant AAVE_UNDERLYING = 0x2020b82569721DF47393505eeEDF2863D6A0504f;

  address internal constant AAVE_A_TOKEN = 0xB695309240e72Fc0244E8aF58b2f6A13b2930502;

  address internal constant AAVE_V_TOKEN = 0xe4Fd5bEe63f91e784da0C1f7C1Dc243305f65bBd;

  address internal constant AAVE_S_TOKEN = 0x22A3039fD1B3fCe323A1F09efc03704E3698b7d0;

  address internal constant AAVE_ORACLE = 0x89911766ec46ED4D8dDf7E389AAb03635390D026;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant WMATIC_UNDERLYING = 0xf237dE5664D3c2D2545684E76fef02A3A58A364c;

  address internal constant WMATIC_A_TOKEN = 0xC0e5f125D33732aDadb04134dB0d351E9bB5BCf6;

  address internal constant WMATIC_V_TOKEN = 0x3062CEfc74220dcB7341d268653F9ACAe8fB1107;

  address internal constant WMATIC_S_TOKEN = 0x4cEF60a947598A62118172fd451Eb1862A3531d8;

  address internal constant WMATIC_ORACLE = 0xa1f96443878E78BF5ac64b7995C66189BEF40f86;

  address internal constant WMATIC_INTEREST_RATE_STRATEGY =
    0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant CRV_UNDERLYING = 0x0799ea468F812e40DBABe77B381cac105Da500Cd;

  address internal constant CRV_A_TOKEN = 0x4582d6B1c50345d9CF74d2cF5F130141d0BBA595;

  address internal constant CRV_V_TOKEN = 0xef7dF8bc0F410a620Fe730fCA028b9322f8e501b;

  address internal constant CRV_S_TOKEN = 0x1c30ad29089d5b5d5c256B98B88C979112981B8e;

  address internal constant CRV_ORACLE = 0x37F95471bce0d497E471Fe646F04c9478912c1F3;

  address internal constant CRV_INTEREST_RATE_STRATEGY = 0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant SUSHI_UNDERLYING = 0x69d6444016CBE7f60f02A476B1832a36010c22e4;

  address internal constant SUSHI_A_TOKEN = 0xD9EB7E2FEcA3132A1bd8EB259C26717935488f04;

  address internal constant SUSHI_V_TOKEN = 0x2FB450BAec43498198aA615E184c54Dc4E62B640;

  address internal constant SUSHI_S_TOKEN = 0x4E2eFce50eFc1c982162c7f6458a745043257Da3;

  address internal constant SUSHI_ORACLE = 0x3fabfCf8321f90794DDf0a6D7C22A01755FBdb33;

  address internal constant SUSHI_INTEREST_RATE_STRATEGY =
    0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant GHST_UNDERLYING = 0xA13F6C1047f90642039EF627C66B758BCEC513Ba;

  address internal constant GHST_A_TOKEN = 0x1687666e4ffA0f45c1B6701720E32f79b1B24036;

  address internal constant GHST_V_TOKEN = 0x8B422A12C2CD22a9F0FE84E97B6D7e51AA09bDD4;

  address internal constant GHST_S_TOKEN = 0x6B6475a50b2275AE3E20751cfcE670B769076DbF;

  address internal constant GHST_ORACLE = 0xbAaCc599ef096c496765C0f1CB473685B4e99Bd4;

  address internal constant GHST_INTEREST_RATE_STRATEGY =
    0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant BAL_UNDERLYING = 0x332Ef44Ece256E4d99838f2AD4E63DB4754E0876;

  address internal constant BAL_A_TOKEN = 0x85c530cf815F842Bd7F9f1C41Ed81a6a54719375;

  address internal constant BAL_V_TOKEN = 0x53590ef864856C156e1D403e238746EE3a2824e5;

  address internal constant BAL_S_TOKEN = 0x87B6A061a921115dfaB18841735f69D00F0adf0e;

  address internal constant BAL_ORACLE = 0x8c6B6f82fc99ed2531bcDEB6E397bBbe8E3002e9;

  address internal constant BAL_INTEREST_RATE_STRATEGY = 0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant DPI_UNDERLYING = 0x521C69B654d1e6EAC55d95EfccEa839fE3cb92Af;

  address internal constant DPI_A_TOKEN = 0x3Ae14a7486b3c7bfB93C1368249368a4458Fd557;

  address internal constant DPI_V_TOKEN = 0x6ECCb955323B6C25a4D20f98b0Daed670ef302d4;

  address internal constant DPI_S_TOKEN = 0x7ec80e834C261A2f087EEFD59691EAB4c7B7213E;

  address internal constant DPI_ORACLE = 0xC8F704c55369AFea0Db42D6cc02D5FAB55224a5B;

  address internal constant DPI_INTEREST_RATE_STRATEGY = 0x686b20cfF45bA9fa14709957D0F1f9B5572F4419;

  address internal constant EURS_UNDERLYING = 0xF6379c02780AB48f55EE5F79dC5083C5a15583b9;

  address internal constant EURS_A_TOKEN = 0x7948efE934B6a7D24B17032D81cB9CD489C68Df0;

  address internal constant EURS_V_TOKEN = 0x61328728b2efd74224E9e524b50ef36a557f98Ec;

  address internal constant EURS_S_TOKEN = 0xDdF01A1391372cE42fd9ae622aB8b5bc5C8EAd1F;

  address internal constant EURS_ORACLE = 0xB69D639a7D77bB571D0e873b6d3B8cdDAd2f3862;

  address internal constant EURS_INTEREST_RATE_STRATEGY =
    0x03a06e4478b52cE3D378b8942712a623f06a4E8B;

  address internal constant JEUR_UNDERLYING = 0x6bF2BC4BD4277737bd50cF377851eCF81B62e320;

  address internal constant JEUR_A_TOKEN = 0x07931E5fA73f30Ae626C5809A736A7a7374a1320;

  address internal constant JEUR_V_TOKEN = 0x3048572a85336A4c74B9B7e51ebf08f6bBD6B7f9;

  address internal constant JEUR_S_TOKEN = 0x576CDE647d09a9C394898de6A18aF6d5Ca9EAC22;

  address internal constant JEUR_ORACLE = 0x5f90A557B00db159EE1cD302574ED0958E261653;

  address internal constant JEUR_INTEREST_RATE_STRATEGY =
    0x03a06e4478b52cE3D378b8942712a623f06a4E8B;

  address internal constant AGEUR_UNDERLYING = 0x1870299d37aa5992850156516DD81DcBf98f2b1C;

  address internal constant AGEUR_A_TOKEN = 0x605d3B24D146d202E15f55139c160c492D9F945e;

  address internal constant AGEUR_V_TOKEN = 0x928fD606dDD48C199462B5D12f4693e5E6F5010B;

  address internal constant AGEUR_S_TOKEN = 0x52b7f2d743d858D2377398220671f2D3BC8da56A;

  address internal constant AGEUR_ORACLE = 0x586A3e843863082b0804E3d67ed4D4cCEb37a4A6;

  address internal constant AGEUR_INTEREST_RATE_STRATEGY =
    0x03a06e4478b52cE3D378b8942712a623f06a4E8B;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Optimism {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  IPool internal constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xD81eb3728a631871a7eBBaD631b5f424909f0c77);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

  address internal constant ACL_ADMIN = 0xE50c8C619d05ff98b22Adf991F17602C774F785c;

  address internal constant COLLECTOR = 0xB2289E329D2F85F1eD31Adbb30eA345278F21bcf;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xA77E4A084d7d4f064E326C0F6c0aCefd47A5Cb21);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;

  address internal constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x770ef9f4fe897e59daCc474EF11238303F9552b6;

  address internal constant WETH_GATEWAY = 0x76D3030728e52DEB8848d5613aBaDE88441cbc59;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0xC7524B08101dBe695d7ad671a332760b5d967Cbd;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0x70371a494f73A8Df658C5cd29E2C1601787e1009;

  address internal constant WALLET_BALANCE_PROVIDER = 0xBc790382B3686abffE4be14A030A96aC6154023a;

  address internal constant UI_POOL_DATA_PROVIDER = 0xbd83DdBE37fc91923d59C8c1E0bDe0CccCa332d5;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x6F143FE2F7B02424ad3CaD1593D6f36c0Aab69d7;

  address internal constant L2_ENCODER = 0x9abADECD08572e0eA5aF4d47A9C7984a5AA503dC;
}

library AaveV3OptimismAssets {
  address internal constant DAI_UNDERLYING = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

  address internal constant DAI_A_TOKEN = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

  address internal constant DAI_V_TOKEN = 0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC;

  address internal constant DAI_S_TOKEN = 0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B;

  address internal constant DAI_ORACLE = 0x8dBa75e83DA73cc766A7e5a0ee71F656BAb470d6;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xA9F3C3caE095527061e6d270DBE163693e6fda9D;

  address internal constant LINK_UNDERLYING = 0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6;

  address internal constant LINK_A_TOKEN = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

  address internal constant LINK_V_TOKEN = 0x953A573793604aF8d41F306FEb8274190dB4aE0e;

  address internal constant LINK_S_TOKEN = 0x89D976629b7055ff1ca02b927BA3e020F22A44e4;

  address internal constant LINK_ORACLE = 0xCc232dcFAAE6354cE191Bd574108c1aD03f86450;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C;

  address internal constant USDC_UNDERLYING = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

  address internal constant USDC_A_TOKEN = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

  address internal constant USDC_V_TOKEN = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  address internal constant USDC_S_TOKEN = 0x307ffe186F84a3bc2613D1eA417A5737D69A7007;

  address internal constant USDC_ORACLE = 0x16a9FA2FDa030272Ce99B29CF780dFA30361E0f3;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant WBTC_UNDERLYING = 0x68f180fcCe6836688e9084f035309E29Bf0A2095;

  address internal constant WBTC_A_TOKEN = 0x078f358208685046a11C85e8ad32895DED33A249;

  address internal constant WBTC_V_TOKEN = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;

  address internal constant WBTC_S_TOKEN = 0x633b207Dd676331c413D4C013a6294B0FE47cD0e;

  address internal constant WBTC_ORACLE = 0xD702DD976Fb76Fffc2D3963D037dfDae5b04E593;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C;

  address internal constant WETH_UNDERLYING = 0x4200000000000000000000000000000000000006;

  address internal constant WETH_A_TOKEN = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;

  address internal constant WETH_V_TOKEN = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;

  address internal constant WETH_S_TOKEN = 0xD8Ad37849950903571df17049516a5CD4cbE55F6;

  address internal constant WETH_ORACLE = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C;

  address internal constant USDT_UNDERLYING = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;

  address internal constant USDT_A_TOKEN = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;

  address internal constant USDT_V_TOKEN = 0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7;

  address internal constant USDT_S_TOKEN = 0x70eFfc565DB6EEf7B927610155602d31b670e802;

  address internal constant USDT_ORACLE = 0xECef79E109e997bCA29c1c0897ec9d7b03647F5E;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant AAVE_UNDERLYING = 0x76FB31fb4af56892A25e32cFC43De717950c9278;

  address internal constant AAVE_A_TOKEN = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;

  address internal constant AAVE_V_TOKEN = 0xE80761Ea617F66F96274eA5e8c37f03960ecC679;

  address internal constant AAVE_S_TOKEN = 0xfAeF6A702D15428E588d4C0614AEFb4348D83D48;

  address internal constant AAVE_ORACLE = 0x338ed6787f463394D24813b297401B9F05a8C9d1;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C;

  address internal constant sUSD_UNDERLYING = 0x8c6f28f2F1A3C87F0f938b96d27520d9751ec8d9;

  address internal constant sUSD_A_TOKEN = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  address internal constant sUSD_V_TOKEN = 0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;

  address internal constant sUSD_S_TOKEN = 0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E;

  address internal constant sUSD_ORACLE = 0x7f99817d87baD03ea21E05112Ca799d715730efe;

  address internal constant sUSD_INTEREST_RATE_STRATEGY =
    0xA9F3C3caE095527061e6d270DBE163693e6fda9D;

  address internal constant OP_UNDERLYING = 0x4200000000000000000000000000000000000042;

  address internal constant OP_A_TOKEN = 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf;

  address internal constant OP_V_TOKEN = 0x77CA01483f379E58174739308945f044e1a764dc;

  address internal constant OP_S_TOKEN = 0x08Cb71192985E936C7Cd166A8b268035e400c3c3;

  address internal constant OP_ORACLE = 0x0D276FC14719f9292D5C1eA2198673d1f4269246;

  address internal constant OP_INTEREST_RATE_STRATEGY = 0xeE1BAc9355EaAfCD1B68d272d640d870bC9b4b5C;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3OptimismGoerli {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0x0b8FAe5f9Bf5a1a5867FB5b39fF4C028b1C2ebA9);

  IPool internal constant POOL = IPool(0xCAd01dAdb7E97ae45b89791D986470F3dfC256f7);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x98EC9f3e5A0E5aDB16BAAdEB96a110BceeaC0067);

  IAaveOracle internal constant ORACLE = IAaveOracle(0x2366d0cE3f44D81f7b2D40C64288b5eAA7593049);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x861d7d4A46C63b92461631CC77a9f2aeAcFfA10d);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0x3e965db7b1BaA260B65208e3F508eD84344ebd75);

  address internal constant ACL_ADMIN = 0xaDdfe0b2342800ebD67C30d1c2Bd479E4D498BD5;

  address internal constant COLLECTOR = 0x026E3e3363843e16e3D6d21e068c981A4F55e5d2;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xD7eFB74039B8f2B4Eb08C2a6bef64B40F196395B);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x062BB55A42875366DB1B7D227B73621C33a6cB6b;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0x7675E8C3e91A11D721D0292331c5ee28ed8996ee;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xF8707057529639A3da9D951054DE89f66d01B3e9;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0xf12460DD042d7F143c6c5ab7A0C5CeA24F7a20b7;

  address internal constant EMISSION_MANAGER = 0x936fF44bb41Fe8d6c3028A016D3255cB3296ECA0;

  address internal constant WETH_GATEWAY = 0x6f7f2440006221F893c587b88f01afc42B6F8d2e;

  address internal constant FAUCET = 0x777A5810352302A2D6d79d5B7323237c467845d9;

  address internal constant WALLET_BALANCE_PROVIDER = 0xb463057Eb60E1575e2a69aa17C63CCd2F3161a5f;

  address internal constant UI_POOL_DATA_PROVIDER = 0x9277eFbB991536a98a1aA8b735E9D26d887104C1;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x4157398c5abB5211F51F5B551E3e240c5568dbD4;

  address internal constant L2_ENCODER = 0x14AA09449fac437b5c0110614be2C08610e38f62;
}

library AaveV3OptimismGoerliAssets {
  address internal constant DAI_UNDERLYING = 0xD9662ae38fB577a3F6843b6b8EB5af3410889f3A;

  address internal constant DAI_A_TOKEN = 0x844f622596D061B8AeB0bf265bDfbdafd5Fb7856;

  address internal constant DAI_V_TOKEN = 0x52FdB081Bba0B6Cf64AEC0fD78127EE07462B51e;

  address internal constant DAI_S_TOKEN = 0x68D2a5be0A4d0Fd6B4e3d2ff7544BDc4B227717B;

  address internal constant DAI_ORACLE = 0xfAe9463b2dEf2AbAF908d0697e7CCEe0407185f1;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0x62527eDa8EC3E3a0ff8DcbA4625fA2dce5829da6;

  address internal constant LINK_UNDERLYING = 0x14cd1A7b8c547bD4A2f531ba1BF11B6c4f2b96db;

  address internal constant LINK_A_TOKEN = 0x29C81A0F7791733E99EC723D30C4f5d77dd5740C;

  address internal constant LINK_V_TOKEN = 0xd22D39EB883995964CaB0e7e1210c2A4310cd18f;

  address internal constant LINK_S_TOKEN = 0x540346baF4b1eBf176673aeFc45a492F248B5613;

  address internal constant LINK_ORACLE = 0x5A04220725D3479A910c9712159b576A19947eC9;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x32BB31484151627da35C460c60f6Bb309cAdA06e;

  address internal constant USDC_UNDERLYING = 0xcbce2891F86b69b3eF61dF8CE69e3522a0483FB3;

  address internal constant USDC_A_TOKEN = 0x1FE5C2C6e1e0207D0Bd5Ee7B8C83b7c5e51D5e49;

  address internal constant USDC_V_TOKEN = 0x45b3190E739E26f44cEB115558c08B76a6831fA5;

  address internal constant USDC_S_TOKEN = 0x80b54134B96C9C2716995068c208Bf174b4116D1;

  address internal constant USDC_ORACLE = 0x6ADC023eEDbD7d55809b7f021425415FF7e4B3dB;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x3A1ED60315BEF296ad37CcFc01fA4698C7F31f73;

  address internal constant WBTC_UNDERLYING = 0xe786Ce31c4c68B1aa004fCed5066775a788993CB;

  address internal constant WBTC_A_TOKEN = 0x1eEC581e03B87a1C1B2c2900d0d83FF39eA4e240;

  address internal constant WBTC_V_TOKEN = 0x2D8044e5A9CFB5b86f8a49823f84fe67AD7013b7;

  address internal constant WBTC_S_TOKEN = 0xD32dFf72F217a56e2d1E36ac9e22052285aE3B2a;

  address internal constant WBTC_ORACLE = 0x3d14c2Bb0C02A992046217283768109d800a2423;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x32BB31484151627da35C460c60f6Bb309cAdA06e;

  address internal constant WETH_UNDERLYING = 0xc5Bf9eb35c7d3a90816436E2a124bdd136e09fFD;

  address internal constant WETH_A_TOKEN = 0xF8793d992E2f4De3Eaf7cE65c71e81Bcc0f235Af;

  address internal constant WETH_V_TOKEN = 0x44c178F854738dAeE97CE3739060d8BFBf2d844c;

  address internal constant WETH_S_TOKEN = 0xa9D767984631B9C3EE28b4568121fC70dC312883;

  address internal constant WETH_ORACLE = 0x22437f5745838DBea26Aa3c439cC137fc5C2E56F;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x32BB31484151627da35C460c60f6Bb309cAdA06e;

  address internal constant USDT_UNDERLYING = 0x8a06022A41B6b64dAefC68260371472fcB351081;

  address internal constant USDT_A_TOKEN = 0x93439F0BF30Bd85385087068dd9D958Dcb9f32d5;

  address internal constant USDT_V_TOKEN = 0xdc22Bae995EFC48af7B364B672AdB02F6BD0F632;

  address internal constant USDT_S_TOKEN = 0x73b3AE5A8316223560E3dC29ae97F19a402c3aa3;

  address internal constant USDT_ORACLE = 0x0707F6C1B4281EB5580bec1dA1cEa2ddAb6E91e6;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x3A1ED60315BEF296ad37CcFc01fA4698C7F31f73;

  address internal constant AAVE_UNDERLYING = 0x7B16EB8CE4143B1bEA183082E1D50e7519980F79;

  address internal constant AAVE_A_TOKEN = 0x3A94d605ebC265Aa57Ce6dD01dD532dceeb5Cd87;

  address internal constant AAVE_V_TOKEN = 0x5a51cBAba718c5ad13A5BedAD096fc0E4414E7F5;

  address internal constant AAVE_S_TOKEN = 0xF133c5B244c95f108b549C6eB768797e2Ea83605;

  address internal constant AAVE_ORACLE = 0x443C1A5D8d2C5E87d7d1Cc9BB21Dbb2787BE5dD0;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x32BB31484151627da35C460c60f6Bb309cAdA06e;

  address internal constant SUSD_UNDERLYING = 0x4f8758F0e15d62426D36cA6c08f6b30ab678cEC7;

  address internal constant SUSD_A_TOKEN = 0xDFABA2957a78f91dadd1F467059EaeaD01c0B0A7;

  address internal constant SUSD_V_TOKEN = 0x806ce529eECb69E09a365d2728793317644A23DD;

  address internal constant SUSD_S_TOKEN = 0x51c0f4A1ED8C2986f29Ef853e60F493C872E701B;

  address internal constant SUSD_ORACLE = 0x04d339Ac1A4A2e830ea54750c248e489b82C392D;

  address internal constant SUSD_INTEREST_RATE_STRATEGY =
    0x3A1ED60315BEF296ad37CcFc01fA4698C7F31f73;
}

// SPDX-License-Identifier: MIT
// AUTOGENERATED - DON'T MANUALLY CHANGE
pragma solidity >=0.6.0;

import {IPoolAddressesProvider, IPool, IPoolConfigurator, IAaveOracle, IPoolDataProvider, IACLManager, ICollector} from './AaveV3.sol';

library AaveV3Polygon {
  IPoolAddressesProvider internal constant POOL_ADDRESSES_PROVIDER =
    IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

  IPool internal constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);

  IPoolConfigurator internal constant POOL_CONFIGURATOR =
    IPoolConfigurator(0x8145eddDf43f50276641b55bd3AD95944510021E);

  IAaveOracle internal constant ORACLE = IAaveOracle(0xb023e699F5a33916Ea823A16485e259257cA8Bd1);

  IPoolDataProvider internal constant AAVE_PROTOCOL_DATA_PROVIDER =
    IPoolDataProvider(0x69FA688f1Dc47d4B5d8029D5a35FB7a548310654);

  IACLManager internal constant ACL_MANAGER =
    IACLManager(0xa72636CbcAa8F5FF95B2cc47F3CDEe83F3294a0B);

  address internal constant ACL_ADMIN = 0xdc9A35B16DB4e126cFeDC41322b3a36454B1F772;

  address internal constant COLLECTOR = 0xe8599F3cc5D38a9aD6F3684cd5CEa72f10Dbc383;

  ICollector internal constant COLLECTOR_CONTROLLER =
    ICollector(0xDB89487A449274478e984665b8692AfC67459deF);

  address internal constant DEFAULT_INCENTIVES_CONTROLLER =
    0x929EC64c34a17401F460460D4B9390518E5B473e;

  address internal constant DEFAULT_A_TOKEN_IMPL_REV_1 = 0xa5ba6E5EC19a1Bf23C857991c857dB62b2Aa187B;

  address internal constant DEFAULT_VARIABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x81387c40EB75acB02757C1Ae55D5936E78c9dEd3;

  address internal constant DEFAULT_STABLE_DEBT_TOKEN_IMPL_REV_1 =
    0x52A1CeB68Ee6b7B5D13E0376A1E0E4423A8cE26e;

  address internal constant EMISSION_MANAGER = 0x048f2228D7Bf6776f99aB50cB1b1eaB4D1d4cA73;

  address internal constant POOL_ADDRESSES_PROVIDER_REGISTRY =
    0x770ef9f4fe897e59daCc474EF11238303F9552b6;

  address internal constant WETH_GATEWAY = 0x1e4b7A6b903680eab0c5dAbcb8fD429cD2a9598c;

  address internal constant REPAY_WITH_COLLATERAL_ADAPTER =
    0xA125561fca253f19eA93970534Bb0364ea74187a;

  address internal constant SWAP_COLLATERAL_ADAPTER = 0x301F221bc732907E2da2dbBFaA8F8F6847c170c3;

  address internal constant WALLET_BALANCE_PROVIDER = 0xBc790382B3686abffE4be14A030A96aC6154023a;

  address internal constant UI_POOL_DATA_PROVIDER = 0xC69728f11E9E6127733751c8410432913123acf1;

  address internal constant UI_INCENTIVE_DATA_PROVIDER = 0x874313A46e4957D29FAAC43BF5Eb2B144894f557;
}

library AaveV3PolygonAssets {
  address internal constant DAI_UNDERLYING = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

  address internal constant DAI_A_TOKEN = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;

  address internal constant DAI_V_TOKEN = 0x8619d80FB0141ba7F184CbF22fd724116D9f7ffC;

  address internal constant DAI_S_TOKEN = 0xd94112B5B62d53C9402e7A60289c6810dEF1dC9B;

  address internal constant DAI_ORACLE = 0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D;

  address internal constant DAI_INTEREST_RATE_STRATEGY = 0xA9F3C3caE095527061e6d270DBE163693e6fda9D;

  address internal constant LINK_UNDERLYING = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;

  address internal constant LINK_A_TOKEN = 0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530;

  address internal constant LINK_V_TOKEN = 0x953A573793604aF8d41F306FEb8274190dB4aE0e;

  address internal constant LINK_S_TOKEN = 0x89D976629b7055ff1ca02b927BA3e020F22A44e4;

  address internal constant LINK_ORACLE = 0xd9FFdb71EbE7496cC440152d43986Aae0AB76665;

  address internal constant LINK_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant USDC_UNDERLYING = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

  address internal constant USDC_A_TOKEN = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

  address internal constant USDC_V_TOKEN = 0xFCCf3cAbbe80101232d343252614b6A3eE81C989;

  address internal constant USDC_S_TOKEN = 0x307ffe186F84a3bc2613D1eA417A5737D69A7007;

  address internal constant USDC_ORACLE = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;

  address internal constant USDC_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant WBTC_UNDERLYING = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;

  address internal constant WBTC_A_TOKEN = 0x078f358208685046a11C85e8ad32895DED33A249;

  address internal constant WBTC_V_TOKEN = 0x92b42c66840C7AD907b4BF74879FF3eF7c529473;

  address internal constant WBTC_S_TOKEN = 0x633b207Dd676331c413D4C013a6294B0FE47cD0e;

  address internal constant WBTC_ORACLE = 0xc907E116054Ad103354f2D350FD2514433D57F6f;

  address internal constant WBTC_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant WETH_UNDERLYING = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

  address internal constant WETH_A_TOKEN = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;

  address internal constant WETH_V_TOKEN = 0x0c84331e39d6658Cd6e6b9ba04736cC4c4734351;

  address internal constant WETH_S_TOKEN = 0xD8Ad37849950903571df17049516a5CD4cbE55F6;

  address internal constant WETH_ORACLE = 0xF9680D99D6C9589e2a93a78A04A279e509205945;

  address internal constant WETH_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant USDT_UNDERLYING = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

  address internal constant USDT_A_TOKEN = 0x6ab707Aca953eDAeFBc4fD23bA73294241490620;

  address internal constant USDT_V_TOKEN = 0xfb00AC187a8Eb5AFAE4eACE434F493Eb62672df7;

  address internal constant USDT_S_TOKEN = 0x70eFfc565DB6EEf7B927610155602d31b670e802;

  address internal constant USDT_ORACLE = 0x0A6513e40db6EB1b165753AD52E80663aeA50545;

  address internal constant USDT_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant AAVE_UNDERLYING = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;

  address internal constant AAVE_A_TOKEN = 0xf329e36C7bF6E5E86ce2150875a84Ce77f477375;

  address internal constant AAVE_V_TOKEN = 0xE80761Ea617F66F96274eA5e8c37f03960ecC679;

  address internal constant AAVE_S_TOKEN = 0xfAeF6A702D15428E588d4C0614AEFb4348D83D48;

  address internal constant AAVE_ORACLE = 0x72484B12719E23115761D5DA1646945632979bB6;

  address internal constant AAVE_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant WMATIC_UNDERLYING = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  address internal constant WMATIC_A_TOKEN = 0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97;

  address internal constant WMATIC_V_TOKEN = 0x4a1c3aD6Ed28a636ee1751C69071f6be75DEb8B8;

  address internal constant WMATIC_S_TOKEN = 0xF15F26710c827DDe8ACBA678682F3Ce24f2Fb56E;

  address internal constant WMATIC_ORACLE = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;

  address internal constant WMATIC_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant CRV_UNDERLYING = 0x172370d5Cd63279eFa6d502DAB29171933a610AF;

  address internal constant CRV_A_TOKEN = 0x513c7E3a9c69cA3e22550eF58AC1C0088e918FFf;

  address internal constant CRV_V_TOKEN = 0x77CA01483f379E58174739308945f044e1a764dc;

  address internal constant CRV_S_TOKEN = 0x08Cb71192985E936C7Cd166A8b268035e400c3c3;

  address internal constant CRV_ORACLE = 0x336584C8E6Dc19637A5b36206B1c79923111b405;

  address internal constant CRV_INTEREST_RATE_STRATEGY = 0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant SUSHI_UNDERLYING = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;

  address internal constant SUSHI_A_TOKEN = 0xc45A479877e1e9Dfe9FcD4056c699575a1045dAA;

  address internal constant SUSHI_V_TOKEN = 0x34e2eD44EF7466D5f9E0b782B5c08b57475e7907;

  address internal constant SUSHI_S_TOKEN = 0x78246294a4c6fBf614Ed73CcC9F8b875ca8eE841;

  address internal constant SUSHI_ORACLE = 0x49B0c695039243BBfEb8EcD054EB70061fd54aa0;

  address internal constant SUSHI_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant GHST_UNDERLYING = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;

  address internal constant GHST_A_TOKEN = 0x8Eb270e296023E9D92081fdF967dDd7878724424;

  address internal constant GHST_V_TOKEN = 0xCE186F6Cccb0c955445bb9d10C59caE488Fea559;

  address internal constant GHST_S_TOKEN = 0x3EF10DFf4928279c004308EbADc4Db8B7620d6fc;

  address internal constant GHST_ORACLE = 0xDD229Ce42f11D8Ee7fFf29bDB71C7b81352e11be;

  address internal constant GHST_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant BAL_UNDERLYING = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;

  address internal constant BAL_A_TOKEN = 0x8ffDf2DE812095b1D19CB146E4c004587C0A0692;

  address internal constant BAL_V_TOKEN = 0xA8669021776Bc142DfcA87c21b4A52595bCbB40a;

  address internal constant BAL_S_TOKEN = 0xa5e408678469d23efDB7694b1B0A85BB0669e8bd;

  address internal constant BAL_ORACLE = 0xD106B538F2A868c28Ca1Ec7E298C3325E0251d66;

  address internal constant BAL_INTEREST_RATE_STRATEGY = 0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant DPI_UNDERLYING = 0x85955046DF4668e1DD369D2DE9f3AEB98DD2A369;

  address internal constant DPI_A_TOKEN = 0x724dc807b04555b71ed48a6896b6F41593b8C637;

  address internal constant DPI_V_TOKEN = 0xf611aEb5013fD2c0511c9CD55c7dc5C1140741A6;

  address internal constant DPI_S_TOKEN = 0xDC1fad70953Bb3918592b6fCc374fe05F5811B6a;

  address internal constant DPI_ORACLE = 0x2e48b7924FBe04d575BA229A59b64547d9da16e9;

  address internal constant DPI_INTEREST_RATE_STRATEGY = 0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant EURS_UNDERLYING = 0xE111178A87A3BFf0c8d18DECBa5798827539Ae99;

  address internal constant EURS_A_TOKEN = 0x38d693cE1dF5AaDF7bC62595A37D667aD57922e5;

  address internal constant EURS_V_TOKEN = 0x5D557B07776D12967914379C71a1310e917C7555;

  address internal constant EURS_S_TOKEN = 0x8a9FdE6925a839F6B1932d16B36aC026F8d3FbdB;

  address internal constant EURS_ORACLE = 0x73366Fe0AA0Ded304479862808e02506FE556a98;

  address internal constant EURS_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant jEUR_UNDERLYING = 0x4e3Decbb3645551B8A19f0eA1678079FCB33fB4c;

  address internal constant jEUR_A_TOKEN = 0x6533afac2E7BCCB20dca161449A13A32D391fb00;

  address internal constant jEUR_V_TOKEN = 0x44705f578135cC5d703b4c9c122528C73Eb87145;

  address internal constant jEUR_S_TOKEN = 0x6B4b37618D85Db2a7b469983C888040F7F05Ea3D;

  address internal constant jEUR_ORACLE = 0x73366Fe0AA0Ded304479862808e02506FE556a98;

  address internal constant jEUR_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant agEUR_UNDERLYING = 0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4;

  address internal constant agEUR_A_TOKEN = 0x8437d7C167dFB82ED4Cb79CD44B7a32A1dd95c77;

  address internal constant agEUR_V_TOKEN = 0x3ca5FA07689F266e907439aFd1fBB59c44fe12f6;

  address internal constant agEUR_S_TOKEN = 0x40B4BAEcc69B882e8804f9286b12228C27F8c9BF;

  address internal constant agEUR_ORACLE = 0x73366Fe0AA0Ded304479862808e02506FE556a98;

  address internal constant agEUR_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant miMATIC_UNDERLYING = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;

  address internal constant miMATIC_A_TOKEN = 0xeBe517846d0F36eCEd99C735cbF6131e1fEB775D;

  address internal constant miMATIC_V_TOKEN = 0x18248226C16BF76c032817854E7C83a2113B4f06;

  address internal constant miMATIC_S_TOKEN = 0x687871030477bf974725232F764aa04318A8b9c8;

  address internal constant miMATIC_ORACLE = 0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428;

  address internal constant miMATIC_INTEREST_RATE_STRATEGY =
    0x41B66b4b6b4c9dab039d96528D1b88f7BAF8C5A4;

  address internal constant stMATIC_UNDERLYING = 0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4;

  address internal constant stMATIC_A_TOKEN = 0xEA1132120ddcDDA2F119e99Fa7A27a0d036F7Ac9;

  address internal constant stMATIC_V_TOKEN = 0x6b030Ff3FB9956B1B69f475B77aE0d3Cf2CC5aFa;

  address internal constant stMATIC_S_TOKEN = 0x1fFD28689DA7d0148ff0fCB669e9f9f0Fc13a219;

  address internal constant stMATIC_ORACLE = 0x97371dF4492605486e23Da797fA68e55Fc38a13f;

  address internal constant stMATIC_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;

  address internal constant MaticX_UNDERLYING = 0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6;

  address internal constant MaticX_A_TOKEN = 0x80cA0d8C38d2e2BcbaB66aA1648Bd1C7160500FE;

  address internal constant MaticX_V_TOKEN = 0xB5b46F918C2923fC7f26DB76e8a6A6e9C4347Cf9;

  address internal constant MaticX_S_TOKEN = 0x62fC96b27a510cF4977B59FF952Dc32378Cc221d;

  address internal constant MaticX_ORACLE = 0x5d37E4b374E6907de8Fc7fb33EE3b0af403C7403;

  address internal constant MaticX_INTEREST_RATE_STRATEGY =
    0x03733F4E008d36f2e37F0080fF1c8DF756622E6F;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes as DataTypesV2} from 'aave-address-book/AaveV2.sol';
import {DataTypes as DataTypesV3} from 'aave-address-book/AaveV3.sol';

library ReserveConfiguration {
  uint256 internal constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 internal constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant EMODE_CATEGORY_MASK =        0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  /// @dev bit 63 reserved
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
  uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

  /**
   * @dev Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypesV2.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getIsFrozen(DataTypesV2.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing frozen state
   **/
  function getReserveParams(DataTypesV3.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
        LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >>
        LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~FROZEN_MASK) != 0
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveExecutor {
  /**
   * @dev emitted when new asset is enabled or disabled
   * @param asset the address of the asset
   * @param enabled whether it was enabled or disabled
   */
  event AssetStateChanged(address indexed asset, bool enabled);

  /**
   * @dev emitted when asset is not backed
   * @param asset asset that is not backed
   */
  event AssetIsNotBacked(address indexed asset);

  /**
   * @dev emitted when the emergency action is activated
   */
  event EmergencyActionExecuted();

  /**
   * @dev gets the list of the assets to check
   * @return returns all the assets that were enabled
   */
  function getAssets() external view returns (address[] memory);

  /**
   * @dev enable checking of proof of reserve for the passed list of assets
   * @param assets the addresses of the assets
   */
  function enableAssets(address[] memory assets) external;

  /**
   * @dev delete the assets and the proof of reserve feeds from the registry.
   * @param assets addresses of the assets
   */
  function disableAssets(address[] memory assets) external;

  /**
   * @dev returns if all the assets in the registry are backed.
   * @return bool returns true if all reserves are backed, otherwise false
   */
  function areAllReservesBacked() external view returns (bool);

  /**
   * @dev returns if emergency action parameters are not already adjusted.
   * This is not checked in executeEmergencyAction(), but is used
   * to prevent infinite execution of performUpkeep() inside the Keeper contract.
   * @return bool if it makes sense to execute the emergency action
   */
  function isEmergencyActionPossible() external view returns (bool);

  /**
   * @dev executes pool-specific action when at least
   * one of the assets in the registry is not backed.
   * v2: disable all borrowing and freeze the exploited assets
   * v3: set ltv to 0 for the broken assets and freeze them
   */
  function executeEmergencyAction() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes, IPoolAddressesProvider, IPool, IPoolConfigurator} from 'aave-address-book/AaveV3.sol';
import {AaveV2Avalanche, AaveV3Avalanche} from 'aave-address-book/AaveAddressBook.sol';
import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';
import {ReserveConfiguration} from '../helpers/ReserveConfiguration.sol';

/**
 * @title DisableBtcbPayload
 * @author BGD Labs
 * @dev Payload to unfreeze btc.b asset and disable it on both executors.
 */

contract DisableBtcbPayload {
  IProofOfReserveExecutor public constant EXECUTOR_V2 =
    IProofOfReserveExecutor(0x7fc3FCb14eF04A48Bb0c12f0c39CD74C249c37d8);
  IProofOfReserveExecutor public constant EXECUTOR_V3 =
    IProofOfReserveExecutor(0xab22988D93d5F942fC6B6c6Ea285744809D1d9Cc);

  address public constant BTCB = 0x152b9d0FdC40C096757F570A51E494bd4b943E50;
  uint256 public constant LTV = 7000;

  function execute() external {
    address[] memory assetsToDisable = new address[](1);
    assetsToDisable[0] = BTCB;

    // disable BTCB on the V2 executor
    EXECUTOR_V2.disableAssets(assetsToDisable);

    // disable BTCB on the V3 executor
    EXECUTOR_V3.disableAssets(assetsToDisable);

    // get asset configuration
    DataTypes.ReserveConfigurationMap memory configuration = AaveV3Avalanche
      .POOL
      .getConfiguration(BTCB);
    (
      ,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,

    ) = ReserveConfiguration.getReserveParams(configuration);

    // set LTV back to normal
    AaveV3Avalanche.POOL_CONFIGURATOR.configureReserveAsCollateral(
      BTCB,
      LTV,
      liquidationThreshold,
      liquidationBonus
    );

    // unfreeze reserve
    AaveV3Avalanche.POOL_CONFIGURATOR.setReserveFreeze(BTCB, false);
  }
}