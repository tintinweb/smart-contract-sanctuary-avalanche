// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../Recoverable.sol";
import "../../interfaces/IClaimsProcessor.sol";
import "../../interfaces/ICxToken.sol";
import "../../interfaces/IVault.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/RegistryLibV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/NTransferUtilV2.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/RoutineInvokerLibV1.sol";

/**
 * @title Claims Processor Contract
 *
 * @dev The claims processor contract allows policyholders to file a claim and get instant payouts during the claim period.
 *
 * <br /> <br />
 *
 * There is a lag period before a policy begins coverage.
 * After the next day's UTC EOD timestamp, policies take effect and are valid until the expiration period.
 * Check [ProtoUtilV1.NS_COVERAGE_LAG](ProtoUtilV1.md) and [PolicyAdmin.getCoverageLag](PolicyAdmin.md#getcoveragelag)
 * for more information on the lag configuration.
 *
 * <br /> <br />
 *
 * If a claim isn't made during the claim period, it isn't valid and there is no payout.
 *
 */
contract Processor is IClaimsProcessor, Recoverable {
  using GovernanceUtilV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using NTransferUtilV2 for IERC20;
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using ValidationLibV1 for bytes32;

  /**
   * @dev Constructs this contract
   *
   * @param store Provide an implementation of IStore
   */
  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Enables a policyholder to receive a payout redeeming cxTokens.
   * Only when the active cover is marked as "Incident Happened" and
   * has "Claimable" status is the payout made.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-pausable Pausable logic is implemented inside the `validate` call
   * @custom:suppress-address-trust-issue The `cxToken` address is checked in the `validate` call
   * @custom:suppress-malicious-erc The malicious ERC-20 `cxToken` should only be invoked via `NTransferUtil`
   * @param cxToken Provide the address of the claim token that you're using for this claim.
   *
   * @param coverKey Enter the key of the cover you're claiming
   * @param productKey Enter the key of the product you're claiming
   * @param incidentDate Enter the active cover's date of incident
   * @param amount Enter the amount of cxTokens you want to transfer
   *
   */
  function claim(
    address cxToken,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 amount
  ) external override nonReentrant {
    validate(cxToken, coverKey, productKey, incidentDate, amount);

    IERC20(cxToken).ensureTransferFrom(msg.sender, address(this), amount);
    ICxToken(cxToken).burn(amount);

    IVault vault = s.getVault(coverKey);
    address finalReporter = s.getReporterInternal(coverKey, productKey, incidentDate);

    uint256 stablecoinPrecision = s.getStablecoinPrecision();
    uint256 payout = (amount * stablecoinPrecision) / ProtoUtilV1.CXTOKEN_PRECISION;

    require(payout > 0, "Invalid payout");

    s.addClaimPayoutsInternal(coverKey, productKey, incidentDate, payout);

    // @suppress-zero-value-check Checked side effects. If the claim platform fee is zero
    // or a very small number, platform fee becomes zero due to data loss.
    uint256 platformFee = (payout * s.getPlatformCoverFeeRateInternal()) / ProtoUtilV1.MULTIPLIER;

    // @suppress-zero-value-check Checked side effects. If the claim reporter commission rate is zero
    // or a very small number, reporterFee fee becomes zero due to data loss.
    uint256 reporterFee = (platformFee * s.getClaimReporterCommissionInternal()) / ProtoUtilV1.MULTIPLIER;

    require(payout >= platformFee, "Invalid platform fee");

    uint256 claimed = payout - platformFee;

    // @suppress-zero-value-check If the platform fee rate was 100%,
    // "claimed" can be zero
    if (claimed > 0) {
      vault.transferGovernance(coverKey, msg.sender, claimed);
    }

    if (reporterFee > 0) {
      vault.transferGovernance(coverKey, finalReporter, reporterFee);
    }

    if (platformFee - reporterFee > 0) {
      // @suppress-subtraction The following (or above) subtraction can cause
      // an underflow if `getClaimReporterCommissionInternal` is greater than 100%.
      vault.transferGovernance(coverKey, s.getTreasury(), platformFee - reporterFee);
    }

    s.updateStateAndLiquidity(coverKey);

    emit Claimed(cxToken, coverKey, productKey, incidentDate, msg.sender, finalReporter, amount, reporterFee, platformFee, claimed);
  }

  /**
   * @dev Validates a given claim
   *
   * @param cxToken Provide the address of the claim token that you're using for this claim.
   * @param coverKey Enter the key of the cover you're validating the claim for
   * @param productKey Enter the key of the product you're validating the claim for
   * @param incidentDate Enter the active cover's date of incident
   *
   * @return If the given claim is valid and can result in a successful payout, returns true.
   *
   */
  function validate(
    address cxToken,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 amount
  ) public view override returns (bool) {
    s.mustNotBePaused();
    s.mustBeValidClaim(msg.sender, coverKey, productKey, cxToken, incidentDate, amount);
    require(isBlacklisted(coverKey, productKey, incidentDate, msg.sender) == false, "Access denied");
    require(amount > 0, "Enter an amount");

    require(s.getClaimReporterCommissionInternal() <= ProtoUtilV1.MULTIPLIER, "Invalid claim reporter fee");
    require(s.getPlatformCoverFeeRateInternal() <= ProtoUtilV1.MULTIPLIER, "Invalid platform fee rate");

    return true;
  }

  /**
   * @dev Returns claim expiration date.
   * Even if the policy was still valid, it cannot be claimed after the claims expiry date.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the key of the cover you're checking
   * @param productKey Enter the key of the product you're checking
   *
   */
  function getClaimExpiryDate(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey);
  }

  /**
   * @dev Sets the cover's claim period using its key.
   * If no cover key is specified, the value specified here will be used as a fallback.
   * Covers without a specified claim period default to the fallback value.
   *
   * @param coverKey Enter the coverKey you want to set the claim period for
   * @param value Enter a claim period you want to set
   *
   */
  function setClaimPeriod(bytes32 coverKey, uint256 value) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    require(value > 0, "Please specify value");

    uint256 previous;

    if (coverKey > 0) {
      previous = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_PERIOD, coverKey);
      s.setUintByKeys(ProtoUtilV1.NS_CLAIM_PERIOD, coverKey, value);
      emit ClaimPeriodSet(coverKey, previous, value);
      return;
    }

    previous = s.getUintByKey(ProtoUtilV1.NS_CLAIM_PERIOD);
    s.setUintByKey(ProtoUtilV1.NS_CLAIM_PERIOD, value);

    emit ClaimPeriodSet(coverKey, previous, value);
  }

  /**
   * @dev Accounts that are on a blacklist can't claim their cxTokens.
   * Cover managers can stop an account from claiming their cover by putting it on the blacklist.
   * Usually, this happens when we suspect a policyholder is the attacker.
   *
   * <br /> <br />
   *
   * After performing KYC, we might be able to lift the blacklist.
   *
   * @param coverKey Enter the cover key
   * @param productKey Enter the product key
   * @param incidentDate Enter the incident date of the cover
   * @param accounts Enter list of accounts you want to blacklist
   * @param statuses Enter true if you want to blacklist. False if you want to remove from the blacklist.
   */
  function setBlacklist(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address[] calldata accounts,
    bool[] calldata statuses
  ) external override nonReentrant {
    // @suppress-zero-value-check Checked
    require(accounts.length > 0, "Invalid accounts");
    require(accounts.length == statuses.length, "Invalid args");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);

    for (uint256 i = 0; i < accounts.length; i++) {
      s.setAddressBooleanByKey(CoverUtilV1.getBlacklistKey(coverKey, productKey, incidentDate), accounts[i], statuses[i]);
      emit BlacklistSet(coverKey, productKey, incidentDate, accounts[i], statuses[i]);
    }
  }

  /**
   * @dev Check to see if an account is blacklisted/banned from making a claim.
   *
   * @param coverKey Enter the cover key
   * @param coverKey Enter the product key
   * @param incidentDate Enter the incident date of this cover
   * @param account Enter the account to see if it is blacklisted
   *
   */
  function isBlacklisted(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) public view override returns (bool) {
    return s.getAddressBooleanByKey(CoverUtilV1.getBlacklistKey(coverKey, productKey, incidentDate), account);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_CLAIMS_PROCESSOR;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IRecoverable.sol";
import "../libraries/BaseLibV1.sol";
import "../libraries/ValidationLibV1.sol";

/**
 *
 * @title Recoverable Contract
 * @dev The recoverable contract enables "Recovery Agents" to recover
 * Ether and ERC-20 tokens sent to this address.
 *
 * To learn more about our recovery policy, please refer to the following doc:
 * https://docs.neptunemutual.com/usage/recovering-cryptocurrencies
 *
 */
abstract contract Recoverable is ReentrancyGuard, IRecoverable {
  using ValidationLibV1 for IStore;
  IStore public override s;

  constructor(IStore store) {
    require(address(store) != address(0), "Invalid Store");
    s = store;
  }

  /**
   * @dev Recover all Ether held by the contract.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   */
  function recoverEther(address sendTo) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeRecoveryAgent(s);
    BaseLibV1.recoverEtherInternal(sendTo);
  }

  /**
   * @dev Recover all ERC-20 compatible tokens sent to this address.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   *
   * @custom:suppress-malicious-erc The malicious ERC-20 `token` should only be invoked via `NTransferUtil`.
   * @custom:suppress-address-trust-issue Although the token can't be trusted, the recovery agent has to check the token code manually.
   *
   * @param token ERC-20 The address of the token contract
   */
  function recoverToken(address token, address sendTo) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeRecoveryAgent(s);
    BaseLibV1.recoverTokenInternal(token, sendTo);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface IClaimsProcessor is IMember {
  event Claimed(
    address cxToken,
    bytes32 indexed coverKey,
    bytes32 indexed productKey,
    uint256 incidentDate,
    address indexed account,
    address reporter,
    uint256 amount,
    uint256 reporterFee,
    uint256 platformFee,
    uint256 claimed
  );
  event ClaimPeriodSet(bytes32 indexed coverKey, uint256 previous, uint256 current);
  event BlacklistSet(bytes32 indexed coverKey, bytes32 indexed productKey, uint256 indexed incidentDate, address account, bool status);

  function claim(
    address cxToken,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 amount
  ) external;

  function validate(
    address cxToken,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 amount
  ) external view returns (bool);

  function setClaimPeriod(bytes32 coverKey, uint256 value) external;

  function getClaimExpiryDate(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  function setBlacklist(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address[] calldata accounts,
    bool[] calldata statuses
  ) external;

  function isBlacklisted(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) external view returns (bool);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface ICxToken is IERC20 {
  function mint(
    bytes32 coverKey,
    bytes32 productKey,
    address to,
    uint256 amount
  ) external;

  function burn(uint256 amount) external;

  function createdOn() external view returns (uint256);

  function expiresOn() external view returns (uint256);

  // slither-disable-next-line naming-convention
  function COVER_KEY() external view returns (bytes32); // solhint-disable

  // slither-disable-next-line naming-convention
  function PRODUCT_KEY() external view returns (bytes32); // solhint-disable

  function getCoverageStartsFrom(address account, uint256 date) external view returns (uint256);

  function getClaimablePolicyOf(address account) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IVault is IMember, IERC20 {
  event GovernanceTransfer(address indexed to, uint256 amount);
  event StrategyTransfer(address indexed token, address indexed strategy, bytes32 indexed name, uint256 amount);
  event StrategyReceipt(address indexed token, address indexed strategy, bytes32 indexed name, uint256 amount, uint256 income, uint256 loss);
  event PodsIssued(address indexed account, uint256 issued, uint256 liquidityAdded, bytes32 indexed referralCode);
  event PodsRedeemed(address indexed account, uint256 redeemed, uint256 liquidityReleased);
  event FlashLoanBorrowed(address indexed lender, address indexed borrower, address indexed stablecoin, uint256 amount, uint256 fee);
  event NpmStaken(address indexed account, uint256 amount);
  event NpmUnstaken(address indexed account, uint256 amount);
  event InterestAccrued(bytes32 indexed coverKey);
  event Entered(bytes32 indexed coverKey, address indexed account);
  event Exited(bytes32 indexed coverKey, address indexed account);

  function key() external view returns (bytes32);

  function sc() external view returns (address);

  /**
   * @dev Adds liquidity to the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to supply.
   * @param npmStake Enter the amount of NPM token to stake. Will be locked for a minimum window of one withdrawal period.
   */
  function addLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bytes32 referralCode
  ) external;

  function accrueInterest() external;

  /**
   * @dev Removes liquidity from the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to remove.
   * @param npmStake Enter the amount of NPM stake to remove.
   * @param exit Indicates NPM stake exit.
   */
  function removeLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bool exit
  ) external;

  /**
   * @dev Transfers liquidity to governance contract.
   * @param coverKey Enter the cover key
   * @param to Enter the destination account
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferGovernance(
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev Transfers liquidity to strategy contract.
   * @param coverKey Enter the cover key
   * @param strategyName Enter the strategy's name
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferToStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  /**
   * @dev Receives from strategy contract.
   * @param coverKey Enter the cover key
   * @param strategyName Enter the strategy's name
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function receiveFromStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  function calculatePods(uint256 forStablecoinUnits) external view returns (uint256);

  function calculateLiquidity(uint256 podsToBurn) external view returns (uint256);

  function getInfo(address forAccount) external view returns (uint256[] memory result);

  /**
   * @dev Returns the stablecoin balance of this vault
   * This also includes amounts lent out in lending strategies
   */
  function getStablecoinBalanceOf() external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IProtocol.sol";
import "../interfaces/IERC20Detailed.sol";

library ProtoUtilV1 {
  using StoreKeyUtil for IStore;

  uint256 public constant MULTIPLIER = 10_000;
  uint256 public constant MAX_LIQUIDITY = 45_000_000_000;
  uint256 public constant MAX_PROPOSAL_AMOUNT = 45_000_000_000;
  uint256 public constant MAX_NPM_STAKE = 10_000_000_000;
  uint256 public constant NPM_PRECISION = 1 ether;
  uint256 public constant CXTOKEN_PRECISION = 1 ether;
  uint256 public constant POD_PRECISION = 1 ether;

  /// @dev Protocol contract namespace
  bytes32 public constant CNS_CORE = "cns:core";

  /// @dev The address of NPM token available in this blockchain
  bytes32 public constant CNS_NPM = "cns:core:npm:instance";

  /// @dev Key prefix for creating a new cover product on chain
  bytes32 public constant CNS_COVER = "cns:cover";

  bytes32 public constant CNS_UNISWAP_V2_ROUTER = "cns:core:uni:v2:router";
  bytes32 public constant CNS_UNISWAP_V2_FACTORY = "cns:core:uni:v2:factory";
  bytes32 public constant CNS_PRICE_DISCOVERY = "cns:core:price:discovery";
  bytes32 public constant CNS_TREASURY = "cns:core:treasury";
  bytes32 public constant CNS_NPM_PRICE_ORACLE = "cns:core:npm:price:oracle";
  bytes32 public constant CNS_COVER_REASSURANCE = "cns:cover:reassurance";
  bytes32 public constant CNS_POOL_BOND = "cns:pool:bond";
  bytes32 public constant CNS_COVER_POLICY = "cns:cover:policy";
  bytes32 public constant CNS_COVER_POLICY_MANAGER = "cns:cover:policy:manager";
  bytes32 public constant CNS_COVER_POLICY_ADMIN = "cns:cover:policy:admin";
  bytes32 public constant CNS_COVER_STAKE = "cns:cover:stake";
  bytes32 public constant CNS_COVER_VAULT = "cns:cover:vault";
  bytes32 public constant CNS_COVER_VAULT_DELEGATE = "cns:cover:vault:delegate";
  bytes32 public constant CNS_COVER_STABLECOIN = "cns:cover:sc";
  bytes32 public constant CNS_COVER_CXTOKEN_FACTORY = "cns:cover:cxtoken:factory";
  bytes32 public constant CNS_COVER_VAULT_FACTORY = "cns:cover:vault:factory";
  bytes32 public constant CNS_BOND_POOL = "cns:pools:bond";
  bytes32 public constant CNS_STAKING_POOL = "cns:pools:staking";
  bytes32 public constant CNS_LIQUIDITY_ENGINE = "cns:liquidity:engine";
  bytes32 public constant CNS_STRATEGY_AAVE = "cns:strategy:aave";
  bytes32 public constant CNS_STRATEGY_COMPOUND = "cns:strategy:compound";

  /// @dev Governance contract address
  bytes32 public constant CNS_GOVERNANCE = "cns:gov";

  /// @dev Governance:Resolution contract address
  bytes32 public constant CNS_GOVERNANCE_RESOLUTION = "cns:gov:resolution";

  /// @dev Claims processor contract address
  bytes32 public constant CNS_CLAIM_PROCESSOR = "cns:claim:processor";

  /// @dev The address where `burn tokens` are sent or collected.
  /// The collection behavior (collection) is required if the protocol
  /// is deployed on a sidechain or a layer-2 blockchain.
  /// &nbsp;\n
  /// The collected NPM tokens are will be periodically bridged back to Ethereum
  /// and then burned.
  bytes32 public constant CNS_BURNER = "cns:core:burner";

  /// @dev Namespace for all protocol members.
  bytes32 public constant NS_MEMBERS = "ns:members";

  /// @dev Namespace for protocol contract members.
  bytes32 public constant NS_CONTRACTS = "ns:contracts";

  /// @dev Key prefix for creating a new cover product on chain
  bytes32 public constant NS_COVER = "ns:cover";
  bytes32 public constant NS_COVER_PRODUCT = "ns:cover:product";
  bytes32 public constant NS_COVER_PRODUCT_EFFICIENCY = "ns:cover:product:efficiency";

  bytes32 public constant NS_COVER_CREATION_DATE = "ns:cover:creation:date";
  bytes32 public constant NS_COVER_CREATION_FEE = "ns:cover:creation:fee";
  bytes32 public constant NS_COVER_CREATION_MIN_STAKE = "ns:cover:creation:min:stake";
  bytes32 public constant NS_COVER_REASSURANCE = "ns:cover:reassurance";
  bytes32 public constant NS_COVER_REASSURANCE_PAYOUT = "ns:cover:reassurance:payout";
  bytes32 public constant NS_COVER_REASSURANCE_WEIGHT = "ns:cover:reassurance:weight";
  bytes32 public constant NS_COVER_REASSURANCE_RATE = "ns:cover:reassurance:rate";
  bytes32 public constant NS_COVER_LEVERAGE_FACTOR = "ns:cover:leverage:factor";
  bytes32 public constant NS_COVER_CREATION_FEE_EARNING = "ns:cover:creation:fee:earning";
  bytes32 public constant NS_COVER_INFO = "ns:cover:info";
  bytes32 public constant NS_COVER_OWNER = "ns:cover:owner";
  bytes32 public constant NS_COVER_SUPPORTS_PRODUCTS = "ns:cover:supports:products";

  bytes32 public constant NS_VAULT_STRATEGY_OUT = "ns:vault:strategy:out";
  bytes32 public constant NS_VAULT_LENDING_INCOMES = "ns:vault:lending:incomes";
  bytes32 public constant NS_VAULT_LENDING_LOSSES = "ns:vault:lending:losses";
  bytes32 public constant NS_VAULT_DEPOSIT_HEIGHTS = "ns:vault:deposit:heights";
  bytes32 public constant NS_COVER_LIQUIDITY_LENDING_PERIOD = "ns:cover:liquidity:len:p";
  bytes32 public constant NS_COVER_LIQUIDITY_MAX_LENDING_RATIO = "ns:cover:liquidity:max:lr";
  bytes32 public constant NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW = "ns:cover:liquidity:ww";
  bytes32 public constant NS_COVER_LIQUIDITY_MIN_STAKE = "ns:cover:liquidity:min:stake";
  bytes32 public constant NS_COVER_LIQUIDITY_STAKE = "ns:cover:liquidity:stake";
  bytes32 public constant NS_COVER_LIQUIDITY_COMMITTED = "ns:cover:liquidity:committed";
  bytes32 public constant NS_COVER_STABLECOIN_NAME = "ns:cover:stablecoin:name";
  bytes32 public constant NS_COVER_REQUIRES_WHITELIST = "ns:cover:requires:whitelist";

  bytes32 public constant NS_COVER_HAS_FLASH_LOAN = "ns:cover:has:fl";
  bytes32 public constant NS_COVER_LIQUIDITY_FLASH_LOAN_FEE = "ns:cover:liquidity:fl:fee";
  bytes32 public constant NS_COVER_LIQUIDITY_FLASH_LOAN_FEE_PROTOCOL = "ns:proto:cover:liquidity:fl:fee";

  bytes32 public constant NS_COVERAGE_LAG = "ns:coverage:lag";
  bytes32 public constant NS_COVER_POLICY_RATE_FLOOR = "ns:cover:policy:rate:floor";
  bytes32 public constant NS_COVER_POLICY_RATE_CEILING = "ns:cover:policy:rate:ceiling";
  bytes32 public constant NS_POLICY_DISABLED = "ns:policy:disabled";

  bytes32 public constant NS_COVER_STAKE = "ns:cover:stake";
  bytes32 public constant NS_COVER_STAKE_OWNED = "ns:cover:stake:owned";
  bytes32 public constant NS_COVER_STATUS = "ns:cover:status";
  bytes32 public constant NS_COVER_CXTOKEN = "ns:cover:cxtoken";
  bytes32 public constant NS_VAULT_TOKEN_NAME = "ns:vault:token:name";
  bytes32 public constant NS_VAULT_TOKEN_SYMBOL = "ns:vault:token:symbol";
  bytes32 public constant NS_COVER_CREATOR_WHITELIST = "ns:cover:creator:whitelist";
  bytes32 public constant NS_COVER_USER_WHITELIST = "ns:cover:user:whitelist";
  bytes32 public constant NS_COVER_CLAIM_BLACKLIST = "ns:cover:claim:blacklist";

  /// @dev Resolution timestamp = timestamp of first reporting + reporting period
  bytes32 public constant NS_GOVERNANCE_RESOLUTION_TS = "ns:gov:resolution:ts";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_GOVERNANCE_UNSTAKEN = "ns:gov:unstaken";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_TS = "ns:gov:unstake:ts";

  /// @dev The reward received by the winning camp
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_REWARD = "ns:gov:unstake:reward";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_BURNED = "ns:gov:unstake:burned";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_GOVERNANCE_UNSTAKE_REPORTER_FEE = "ns:gov:unstake:rep:fee";

  bytes32 public constant NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE = "ns:gov:rep:min:first:stake";

  /// @dev An approximate date and time when trigger event or cover incident occurred
  bytes32 public constant NS_GOVERNANCE_REPORTING_INCIDENT_DATE = "ns:gov:rep:incident:date";

  /// @dev A period (in solidity timestamp) configurable by cover creators during
  /// when NPM tokenholders can vote on incident reporting proposals
  bytes32 public constant NS_GOVERNANCE_REPORTING_PERIOD = "ns:gov:rep:period";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who saw incident to have happened
  /// 2. For address --> The address of the first reporter
  bytes32 public constant NS_GOVERNANCE_REPORTING_WITNESS_YES = "ns:gov:rep:witness:yes";

  /// @dev Used as key to flag if a cover was disputed. Cleared when a cover is finalized.
  bytes32 public constant NS_GOVERNANCE_REPORTING_HAS_A_DISPUTE = "ns:gov:rep:has:dispute";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who disagreed with and disputed an incident reporting
  /// 2. For address --> The address of the first disputing reporter (disputer / candidate reporter)
  bytes32 public constant NS_GOVERNANCE_REPORTING_WITNESS_NO = "ns:gov:rep:witness:no";

  /// @dev Stakes guaranteed by an individual witness supporting the "incident happened" camp
  bytes32 public constant NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES = "ns:gov:rep:stake:owned:yes";

  /// @dev Stakes guaranteed by an individual witness supporting the "false reporting" camp
  bytes32 public constant NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO = "ns:gov:rep:stake:owned:no";

  /// @dev The percentage rate (x MULTIPLIER) of amount of reporting/unstake reward to burn.
  /// @custom:note that the reward comes from the losing camp after resolution is achieved.
  bytes32 public constant NS_GOVERNANCE_REPORTING_BURN_RATE = "ns:gov:rep:burn:rate";

  /// @dev The percentage rate (x MULTIPLIER) of amount of reporting/unstake
  /// reward to provide to the final reporter.
  bytes32 public constant NS_GOVERNANCE_REPORTER_COMMISSION = "ns:gov:reporter:commission";

  bytes32 public constant NS_CLAIM_PERIOD = "ns:claim:period";

  bytes32 public constant NS_CLAIM_PAYOUTS = "ns:claim:payouts";

  /// @dev A 24-hour delay after a governance agent "resolves" an actively reported cover.
  bytes32 public constant NS_CLAIM_BEGIN_TS = "ns:claim:begin:ts";

  /// @dev Claim expiry date = Claim begin date + claim duration
  bytes32 public constant NS_CLAIM_EXPIRY_TS = "ns:claim:expiry:ts";

  bytes32 public constant NS_RESOLUTION_DEADLINE = "ns:resolution:deadline";

  /// @dev Claim expiry date = Claim begin date + claim duration
  bytes32 public constant NS_RESOLUTION_COOL_DOWN_PERIOD = "ns:resolution:cdp";

  /// @dev The percentage rate (x MULTIPLIER) of amount deducted by the platform
  /// for each successful claims payout
  bytes32 public constant NS_COVER_PLATFORM_FEE = "ns:cover:platform:fee";

  /// @dev The percentage rate (x MULTIPLIER) of amount provided to the first reporter
  /// upon favorable incident resolution. This amount is a commission of the
  /// 'ns:claim:platform:fee'
  bytes32 public constant NS_CLAIM_REPORTER_COMMISSION = "ns:claim:reporter:commission";

  bytes32 public constant NS_LAST_LIQUIDITY_STATE_UPDATE = "ns:last:snl:update";
  bytes32 public constant NS_LIQUIDITY_STATE_UPDATE_INTERVAL = "ns:snl:update:interval";
  bytes32 public constant NS_LENDING_STRATEGY_ACTIVE = "ns:lending:strategy:active";
  bytes32 public constant NS_LENDING_STRATEGY_DISABLED = "ns:lending:strategy:disabled";
  bytes32 public constant NS_LENDING_STRATEGY_WITHDRAWAL_START = "ns:lending:strategy:w:start";
  bytes32 public constant NS_ACCRUAL_INVOCATION = "ns:accrual:invocation";
  bytes32 public constant NS_LENDING_STRATEGY_WITHDRAWAL_END = "ns:lending:strategy:w:end";

  bytes32 public constant CNAME_PROTOCOL = "Neptune Mutual Protocol";
  bytes32 public constant CNAME_TREASURY = "Treasury";
  bytes32 public constant CNAME_POLICY = "Policy";
  bytes32 public constant CNAME_POLICY_ADMIN = "Policy Admin";
  bytes32 public constant CNAME_POLICY_MANAGER = "Policy Manager";
  bytes32 public constant CNAME_BOND_POOL = "BondPool";
  bytes32 public constant CNAME_STAKING_POOL = "Staking Pool";
  bytes32 public constant CNAME_POD_STAKING_POOL = "PODStaking Pool";
  bytes32 public constant CNAME_CLAIMS_PROCESSOR = "Claims Processor";
  bytes32 public constant CNAME_COVER = "Cover";
  bytes32 public constant CNAME_GOVERNANCE = "Governance";
  bytes32 public constant CNAME_RESOLUTION = "Resolution";
  bytes32 public constant CNAME_VAULT_FACTORY = "Vault Factory";
  bytes32 public constant CNAME_CXTOKEN_FACTORY = "cxToken Factory";
  bytes32 public constant CNAME_COVER_STAKE = "Cover Stake";
  bytes32 public constant CNAME_COVER_REASSURANCE = "Cover Reassurance";
  bytes32 public constant CNAME_LIQUIDITY_VAULT = "Vault";
  bytes32 public constant CNAME_VAULT_DELEGATE = "Vault Delegate";
  bytes32 public constant CNAME_LIQUIDITY_ENGINE = "Liquidity Engine";
  bytes32 public constant CNAME_STRATEGY_AAVE = "Aave Strategy";
  bytes32 public constant CNAME_STRATEGY_COMPOUND = "Compound Strategy";

  function getProtocol(IStore s) external view returns (IProtocol) {
    return IProtocol(getProtocolAddress(s));
  }

  function getProtocolAddress(IStore s) public view returns (address) {
    return s.getAddressByKey(CNS_CORE);
  }

  function getContract(IStore s, bytes32 name) external view returns (address) {
    return _getContract(s, name);
  }

  function isProtocolMember(IStore s, address contractAddress) external view returns (bool) {
    return _isProtocolMember(s, contractAddress);
  }

  /**
   * @dev Reverts if the caller is one of the protocol members.
   */
  function mustBeProtocolMember(IStore s, address contractAddress) external view {
    bool isMember = _isProtocolMember(s, contractAddress);
    require(isMember, "Not a protocol member");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   * @param sender Enter the `msg.sender` value
   */
  function mustBeExactContract(
    IStore s,
    bytes32 name,
    address sender
  ) public view {
    address contractAddress = _getContract(s, name);
    require(sender == contractAddress, "Access denied");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   */
  function senderMustBeExactContract(IStore s, bytes32 name) external view {
    return callerMustBeExactContract(s, name, msg.sender);
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   */
  function callerMustBeExactContract(
    IStore s,
    bytes32 name,
    address caller
  ) public view {
    return mustBeExactContract(s, name, caller);
  }

  function npmToken(IStore s) external view returns (IERC20) {
    return IERC20(getNpmTokenAddress(s));
  }

  function getNpmTokenAddress(IStore s) public view returns (address) {
    address npm = s.getAddressByKey(CNS_NPM);
    return npm;
  }

  function getUniswapV2Router(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_UNISWAP_V2_ROUTER);
  }

  function getUniswapV2Factory(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_UNISWAP_V2_FACTORY);
  }

  function getNpmPriceOracle(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_NPM_PRICE_ORACLE);
  }

  function getTreasury(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_TREASURY);
  }

  function getStablecoin(IStore s) public view returns (address) {
    return s.getAddressByKey(CNS_COVER_STABLECOIN);
  }

  function getStablecoinPrecision(IStore s) external view returns (uint256) {
    return 10**IERC20Detailed(getStablecoin(s)).decimals();
  }

  function getBurnAddress(IStore s) external view returns (address) {
    return s.getAddressByKey(CNS_BURNER);
  }

  function _isProtocolMember(IStore s, address contractAddress) private view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, contractAddress);
  }

  function _getContract(IStore s, bytes32 name) private view returns (address) {
    return s.getAddressByKeys(NS_CONTRACTS, name);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "../interfaces/ICover.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/IBondPool.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/ICxTokenFactory.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IGovernance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";

library RegistryLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getGovernanceContract(IStore s) external view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.CNS_GOVERNANCE));
  }

  function getResolutionContract(IStore s) external view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.CNS_GOVERNANCE_RESOLUTION));
  }

  function getStakingContract(IStore s) external view returns (ICoverStake) {
    return ICoverStake(s.getContract(ProtoUtilV1.CNS_COVER_STAKE));
  }

  function getCxTokenFactory(IStore s) external view returns (ICxTokenFactory) {
    return ICxTokenFactory(s.getContract(ProtoUtilV1.CNS_COVER_CXTOKEN_FACTORY));
  }

  function getPolicyContract(IStore s) external view returns (IPolicy) {
    return IPolicy(s.getContract(ProtoUtilV1.CNS_COVER_POLICY));
  }

  function getReassuranceContract(IStore s) external view returns (ICoverReassurance) {
    return ICoverReassurance(s.getContract(ProtoUtilV1.CNS_COVER_REASSURANCE));
  }

  function getBondPoolContract(IStore s) external view returns (IBondPool) {
    return IBondPool(getBondPoolAddress(s));
  }

  function getProtocolContract(IStore s, bytes32 cns) public view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, cns);
  }

  function getProtocolContract(
    IStore s,
    bytes32 cns,
    bytes32 key
  ) public view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, cns, key);
  }

  function getCoverContract(IStore s) external view returns (ICover) {
    address vault = getProtocolContract(s, ProtoUtilV1.CNS_COVER);
    return ICover(vault);
  }

  function getVault(IStore s, bytes32 coverKey) external view returns (IVault) {
    return IVault(getVaultAddress(s, coverKey));
  }

  function getVaultAddress(IStore s, bytes32 coverKey) public view returns (address) {
    address vault = getProtocolContract(s, ProtoUtilV1.CNS_COVER_VAULT, coverKey);
    return vault;
  }

  function getVaultDelegate(IStore s) external view returns (address) {
    address vaultImplementation = getProtocolContract(s, ProtoUtilV1.CNS_COVER_VAULT_DELEGATE);
    return vaultImplementation;
  }

  function getStakingPoolAddress(IStore s) external view returns (address) {
    address pool = getProtocolContract(s, ProtoUtilV1.CNS_STAKING_POOL);
    return pool;
  }

  function getBondPoolAddress(IStore s) public view returns (address) {
    address pool = getProtocolContract(s, ProtoUtilV1.CNS_BOND_POOL);
    return pool;
  }

  function getVaultFactoryContract(IStore s) external view returns (IVaultFactory) {
    address factory = s.getContract(ProtoUtilV1.CNS_COVER_VAULT_FACTORY);
    return IVaultFactory(factory);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./CoverUtilV1.sol";
import "./GovernanceUtilV1.sol";
import "./AccessControlLibV1.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/ICxToken.sol";

library ValidationLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using CoverUtilV1 for IStore;
  using GovernanceUtilV1 for IStore;
  using RegistryLibV1 for IStore;

  /**
   * @dev Reverts if the protocol is paused
   */
  function mustNotBePaused(IStore s) public view {
    address protocol = s.getProtocolAddress();
    require(IPausable(protocol).paused() == false, "Protocol is paused");
  }

  /**
   * @dev Reverts if the cover or any of the cover's product is not normal.
   * @param coverKey Enter the cover key to check
   */
  function mustEnsureAllProductsAreNormal(IStore s, bytes32 coverKey) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, coverKey), "Cover does not exist");
    require(s.isCoverNormalInternal(coverKey) == true, "Status not normal");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract
   * or if the cover is under governance.
   * @param coverKey Enter the cover key to check
   * @param productKey Enter the product key to check
   */
  function mustHaveNormalProductStatus(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, coverKey), "Cover does not exist");
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.Normal, "Status not normal");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract.
   * @param coverKey Enter the cover key to check
   */
  function mustBeValidCoverKey(IStore s, bytes32 coverKey) external view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, coverKey), "Cover does not exist");
  }

  /**
   * @dev Reverts if the cover does not support creating products.
   * @param coverKey Enter the cover key to check
   */
  function mustSupportProducts(IStore s, bytes32 coverKey) external view {
    require(s.supportsProductsInternal(coverKey), "Does not have products");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid product of a cover contract.
   * @param coverKey Enter the cover key to check
   * @param productKey Enter the cover key to check
   */
  function mustBeValidProduct(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(s.isValidProductInternal(coverKey, productKey), "Product does not exist");
  }

  /**
   * @dev Reverts if the key resolves in an expired product.
   * @param coverKey Enter the cover key to check
   * @param productKey Enter the cover key to check
   */
  function mustBeActiveProduct(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(s.isActiveProductInternal(coverKey, productKey), "Product retired or deleted");
  }

  /**
   * @dev Reverts if the sender is not the cover owner
   * @param coverKey Enter the cover key to check
   * @param sender The `msg.sender` value
   */
  function mustBeCoverOwner(
    IStore s,
    bytes32 coverKey,
    address sender
  ) public view {
    bool isCoverOwner = s.getCoverOwner(coverKey) == sender;
    require(isCoverOwner, "Forbidden");
  }

  /**
   * @dev Reverts if the sender is not the cover owner or the cover contract
   * @param coverKey Enter the cover key to check
   * @param sender The `msg.sender` value
   */
  function mustBeCoverOwnerOrCoverContract(
    IStore s,
    bytes32 coverKey,
    address sender
  ) external view {
    bool isCoverOwner = s.getCoverOwner(coverKey) == sender;
    bool isCoverContract = address(s.getCoverContract()) == sender;

    require(isCoverOwner || isCoverContract, "Forbidden");
  }

  function senderMustBeCoverOwnerOrAdmin(IStore s, bytes32 coverKey) external view {
    if (AccessControlLibV1.hasAccess(s, AccessControlLibV1.NS_ROLES_ADMIN, msg.sender) == false) {
      mustBeCoverOwner(s, coverKey, msg.sender);
    }
  }

  function senderMustBePolicyContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_COVER_POLICY);
  }

  function senderMustBePolicyManagerContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_COVER_POLICY_MANAGER);
  }

  function senderMustBeCoverContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_COVER);
  }

  function senderMustBeVaultContract(IStore s, bytes32 coverKey) external view {
    address vault = s.getVaultAddress(coverKey);
    require(msg.sender == vault, "Forbidden");
  }

  function senderMustBeGovernanceContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_GOVERNANCE);
  }

  function senderMustBeClaimsProcessorContract(IStore s) external view {
    s.senderMustBeExactContract(ProtoUtilV1.CNS_CLAIM_PROCESSOR);
  }

  function callerMustBeClaimsProcessorContract(IStore s, address caller) external view {
    s.callerMustBeExactContract(ProtoUtilV1.CNS_CLAIM_PROCESSOR, caller);
  }

  function senderMustBeStrategyContract(IStore s) external view {
    bool senderIsStrategyContract = s.getBoolByKey(_getIsActiveStrategyKey(msg.sender));
    require(senderIsStrategyContract == true, "Not a strategy contract");
  }

  function callerMustBeStrategyContract(IStore s, address caller) public view {
    bool isActive = s.getBoolByKey(_getIsActiveStrategyKey(caller));
    bool wasDisabled = s.getBoolByKey(_getIsDisabledStrategyKey(caller));

    require(isActive == true || wasDisabled == true, "Not a strategy contract");
  }

  function callerMustBeSpecificStrategyContract(
    IStore s,
    address caller,
    bytes32 strategyName
  ) external view {
    callerMustBeStrategyContract(s, caller);
    require(IMember(caller).getName() == strategyName, "Access denied");
  }

  function _getIsActiveStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, strategyAddress));
  }

  function _getIsDisabledStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED, strategyAddress));
  }

  function senderMustBeProtocolMember(IStore s) external view {
    require(s.isProtocolMember(msg.sender), "Forbidden");
  }

  function mustBeReporting(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.IncidentHappened, "Not reporting");
  }

  function mustBeDisputed(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.FalseReporting, "Not disputed");
  }

  function mustBeClaimable(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.Claimable, "Not claimable");
  }

  function mustBeClaimingOrDisputed(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    CoverUtilV1.ProductStatus status = s.getProductStatusInternal(coverKey, productKey);

    bool claiming = status == CoverUtilV1.ProductStatus.Claimable;
    bool falseReporting = status == CoverUtilV1.ProductStatus.FalseReporting;

    require(claiming || falseReporting, "Not claimable nor disputed");
  }

  function mustBeReportingOrDisputed(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    CoverUtilV1.ProductStatus status = s.getProductStatusInternal(coverKey, productKey);
    bool incidentHappened = status == CoverUtilV1.ProductStatus.IncidentHappened;
    bool falseReporting = status == CoverUtilV1.ProductStatus.FalseReporting;

    require(incidentHappened || falseReporting, "Not reported nor disputed");
  }

  function mustBeBeforeResolutionDeadline(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    uint256 deadline = s.getResolutionDeadlineInternal(coverKey, productKey);

    if (deadline > 0) {
      require(block.timestamp < deadline, "Emergency resolution deadline over"); // solhint-disable-line
    }
  }

  function mustNotHaveResolutionDeadline(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    uint256 deadline = s.getResolutionDeadlineInternal(coverKey, productKey);
    require(deadline == 0, "Resolution already has deadline");
  }

  function mustBeAfterResolutionDeadline(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    uint256 deadline = s.getResolutionDeadlineInternal(coverKey, productKey);
    require(deadline > 0 && block.timestamp > deadline, "Still unresolved"); // solhint-disable-line
  }

  function mustBeValidIncidentDate(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view {
    require(s.getLatestIncidentDateInternal(coverKey, productKey) == incidentDate, "Invalid incident date");
  }

  function mustHaveDispute(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    bool hasDispute = s.getBoolByKey(GovernanceUtilV1.getHasDisputeKeyInternal(coverKey, productKey));
    require(hasDispute == true, "Not disputed");
  }

  function mustNotHaveDispute(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    bool hasDispute = s.getBoolByKey(GovernanceUtilV1.getHasDisputeKeyInternal(coverKey, productKey));
    require(hasDispute == false, "Already disputed");
  }

  function mustBeDuringReportingPeriod(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(s.getResolutionTimestampInternal(coverKey, productKey) >= block.timestamp, "Reporting window closed"); // solhint-disable-line
  }

  function mustBeAfterReportingPeriod(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    require(block.timestamp > s.getResolutionTimestampInternal(coverKey, productKey), "Reporting still active"); // solhint-disable-line
  }

  function mustBeValidCxToken(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address cxToken,
    uint256 incidentDate
  ) public view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER_CXTOKEN, cxToken) == true, "Unknown cxToken");

    bytes32 COVER_KEY = ICxToken(cxToken).COVER_KEY(); // solhint-disable-line
    bytes32 PRODUCT_KEY = ICxToken(cxToken).PRODUCT_KEY(); // solhint-disable-line

    require(coverKey == COVER_KEY && productKey == PRODUCT_KEY, "Invalid cxToken");

    uint256 expires = ICxToken(cxToken).expiresOn();
    require(expires > incidentDate, "Invalid or expired cxToken");
  }

  function mustBeValidClaim(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    address cxToken,
    uint256 incidentDate,
    uint256 amount
  ) external view {
    mustBeSupportedProductOrEmpty(s, coverKey, productKey);
    mustBeValidCxToken(s, coverKey, productKey, cxToken, incidentDate);
    mustBeClaimable(s, coverKey, productKey);
    mustBeValidIncidentDate(s, coverKey, productKey, incidentDate);
    mustBeDuringClaimPeriod(s, coverKey, productKey);
    require(ICxToken(cxToken).getClaimablePolicyOf(account) >= amount, "Claim exceeds your coverage");
  }

  function mustNotHaveUnstaken(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view {
    uint256 withdrawal = s.getReportingUnstakenAmountInternal(account, coverKey, productKey, incidentDate);
    require(withdrawal == 0, "Already unstaken");
  }

  /**
   * @dev Validates your `unstakeWithoutClaim` arguments
   *
   * @custom:note This function is not intended be used and does not produce correct result
   * during a claim period. Please use `validateUnstakeWithClaim` if you are accessing
   * this function during claim period.
   */
  function validateUnstakeWithoutClaim(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view {
    mustNotBePaused(s);
    mustBeSupportedProductOrEmpty(s, coverKey, productKey);
    mustNotHaveUnstaken(s, msg.sender, coverKey, productKey, incidentDate);
    mustBeAfterReportingPeriod(s, coverKey, productKey);

    // Before the deadline, emergency resolution can still happen
    // that may have an impact on the final decision. We, therefore, have to wait.
    mustBeAfterResolutionDeadline(s, coverKey, productKey);
  }

  /**
   * @dev Validates your `unstakeWithClaim` arguments
   *
   * @custom:note This function is only intended be used during a claim period.
   * Please use `validateUnstakeWithoutClaim` if you are accessing
   * this function after claim period expiry.
   */
  function validateUnstakeWithClaim(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view {
    mustNotBePaused(s);
    mustBeSupportedProductOrEmpty(s, coverKey, productKey);
    mustNotHaveUnstaken(s, msg.sender, coverKey, productKey, incidentDate);
    mustBeAfterReportingPeriod(s, coverKey, productKey);

    // If this reporting gets finalized, incident date will become invalid
    // meaning this execution will revert thereby restricting late comers
    // to access this feature. But they can still access `unstake` feature
    // to withdraw their stake.
    mustBeValidIncidentDate(s, coverKey, productKey, incidentDate);

    // Before the deadline, emergency resolution can still happen
    // that may have an impact on the final decision. We, therefore, have to wait.
    mustBeAfterResolutionDeadline(s, coverKey, productKey);

    bool incidentHappened = s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.Claimable;

    if (incidentHappened) {
      // Incident occurred. Must unstake with claim during the claim period.
      mustBeDuringClaimPeriod(s, coverKey, productKey);
      return;
    }
  }

  function mustBeDuringClaimPeriod(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    uint256 beginsFrom = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_BEGIN_TS, coverKey, productKey);
    uint256 expiresAt = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey);

    require(beginsFrom > 0, "Invalid claim begin date");
    require(expiresAt > beginsFrom, "Invalid claim period");

    require(block.timestamp >= beginsFrom, "Claim period hasn't begun"); // solhint-disable-line
    require(block.timestamp <= expiresAt, "Claim period has expired"); // solhint-disable-line
  }

  function mustBeAfterClaimExpiry(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey), "Claim still active"); // solhint-disable-line
  }

  /**
   * @dev Reverts if the sender is not whitelisted cover creator.
   */
  function senderMustBeWhitelistedCoverCreator(IStore s) external view {
    require(s.getAddressBooleanByKey(ProtoUtilV1.NS_COVER_CREATOR_WHITELIST, msg.sender), "Not whitelisted");
  }

  function senderMustBeWhitelistedIfRequired(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address sender
  ) external view {
    bool supportsProducts = s.supportsProductsInternal(coverKey);
    bool required = supportsProducts ? s.checkIfProductRequiresWhitelist(coverKey, productKey) : s.checkIfRequiresWhitelist(coverKey);

    if (required == false) {
      return;
    }

    require(s.getAddressBooleanByKeys(ProtoUtilV1.NS_COVER_USER_WHITELIST, coverKey, productKey, sender), "You are not whitelisted");
  }

  function mustBeSupportedProductOrEmpty(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view {
    bool hasProducts = s.supportsProductsInternal(coverKey);

    hasProducts ? require(productKey > 0, "Specify a product") : require(productKey == 0, "Invalid product");

    if (hasProducts) {
      mustBeValidProduct(s, coverKey, productKey);
      mustBeActiveProduct(s, coverKey, productKey);
    }
  }

  function mustNotHavePolicyDisabled(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view {
    require(!s.isPolicyDisabledInternal(coverKey, productKey), "Policy purchase disabled");
  }

  function mustNotExceedStablecoinThreshold(IStore s, uint256 amount) external view {
    uint256 stablecoinPrecision = s.getStablecoinPrecision();
    require(amount <= ProtoUtilV1.MAX_LIQUIDITY * stablecoinPrecision, "Please specify a smaller amount");
  }

  function mustNotExceedProposalThreshold(IStore s, uint256 amount) external view {
    uint256 stablecoinPrecision = s.getStablecoinPrecision();
    require(amount <= ProtoUtilV1.MAX_PROPOSAL_AMOUNT * stablecoinPrecision, "Please specify a smaller amount");
  }
}

/* solhint-disable */

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

library NTransferUtilV2 {
  using SafeERC20 for IERC20;

  /**
   *
   * @dev Ensures approval of ERC20-like token
   * @custom:suppress-malicious-erc The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * @custom:suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   *
   */
  function ensureApproval(
    IERC20 malicious,
    address spender,
    uint256 amount
  ) external {
    require(address(malicious) != address(0), "Invalid token address");
    require(spender != address(0), "Invalid spender");
    require(amount > 0, "Invalid transfer amount");

    malicious.safeIncreaseAllowance(spender, amount);
  }

  /**
   * @dev Ensures transfer of ERC20-like token
   *
   * @custom:suppress-malicious-erc The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * @custom:suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * The address `recipient` can be trusted as we're not treating (or calling) it as a contract.
   *
   */
  function ensureTransfer(
    IERC20 malicious,
    address recipient,
    uint256 amount
  ) external {
    require(address(malicious) != address(0), "Invalid token address");
    require(recipient != address(0), "Spender can't be zero");
    require(amount > 0, "Invalid transfer amount");

    uint256 balanceBeforeTransfer = malicious.balanceOf(recipient);
    malicious.safeTransfer(recipient, amount);
    uint256 balanceAfterTransfer = malicious.balanceOf(recipient);

    // @suppress-subtraction
    uint256 actualTransferAmount = balanceAfterTransfer - balanceBeforeTransfer;

    require(actualTransferAmount == amount, "Invalid transfer");
  }

  /**
   * @dev Ensures transferFrom of ERC20-like token
   *
   * @custom:suppress-malicious-erc The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * @custom:suppress-address-trust-issue The address `malicious` can't be trusted and therefore we are ensuring that it does not act funny.
   * The address `recipient` can be trusted as we're not treating (or calling) it as a contract.
   *
   */
  function ensureTransferFrom(
    IERC20 malicious,
    address sender,
    address recipient,
    uint256 amount
  ) external {
    require(address(malicious) != address(0), "Invalid token address");
    // @todo: require(sender != address(0), "Invalid sender");
    require(recipient != address(0), "Invalid recipient");
    require(amount > 0, "Invalid transfer amount");

    uint256 balanceBeforeTransfer = malicious.balanceOf(recipient);
    malicious.safeTransferFrom(sender, recipient, amount);
    uint256 balanceAfterTransfer = malicious.balanceOf(recipient);

    // @suppress-subtraction
    uint256 actualTransferAmount = balanceAfterTransfer - balanceBeforeTransfer;

    require(actualTransferAmount == amount, "Invalid transfer");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
// solhint-disable func-order
pragma solidity ^0.8.0;
import "../interfaces/IStore.sol";

library StoreKeyUtil {
  function setUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.setUint(key, value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2, key3), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.setUint(_getKey(key1, key2, account), value);
  }

  function addUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.addUint(key, value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.addUint(_getKey(key1, key2), value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.addUint(_getKey(key1, key2, account), value);
  }

  function subtractUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.subtractUint(key, value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    return s.subtractUint(_getKey(key1, key2), value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    return s.subtractUint(_getKey(key1, key2, account), value);
  }

  function setStringByKey(
    IStore s,
    bytes32 key,
    string calldata value
  ) external {
    require(key > 0, "Invalid key");
    s.setString(key, value);
  }

  function setStringByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    string calldata value
  ) external {
    return s.setString(_getKey(key1, key2), value);
  }

  function setBytes32ByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    s.setBytes32(key, value);
  }

  function setBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    return s.setBytes32(_getKey(key1, key2), value);
  }

  function setBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    return s.setBytes32(_getKey(key1, key2, key3), value);
  }

  function setBoolByKey(
    IStore s,
    bytes32 key,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setBool(key, value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bool value
  ) external {
    return s.setBool(_getKey(key1, key2), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bool value
  ) external {
    return s.setBool(_getKey(key1, key2, key3), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    return s.setBool(_getKey(key, account), value);
  }

  function setAddressByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddress(key, value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.setAddress(_getKey(key1, key2), value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.setAddress(_getKey(key1, key2, key3), value);
  }

  function setAddressArrayByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddressArrayItem(key, value);
  }

  function setAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.setAddressArrayItem(_getKey(key1, key2), value);
  }

  function setAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.setAddressArrayItem(_getKey(key1, key2, key3), value);
  }

  function setAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddressBoolean(key, account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    bool value
  ) external {
    return s.setAddressBoolean(_getKey(key1, key2), account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account,
    bool value
  ) external {
    return s.setAddressBoolean(_getKey(key1, key2, key3), account, value);
  }

  function deleteUintByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteUint(key);
  }

  function deleteUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteUint(_getKey(key1, key2));
  }

  function deleteUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external {
    return s.deleteUint(_getKey(key1, key2, key3));
  }

  function deleteBytes32ByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    s.deleteBytes32(key);
  }

  function deleteBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteBytes32(_getKey(key1, key2));
  }

  function deleteBoolByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteBool(key);
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteBool(_getKey(key1, key2));
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external {
    return s.deleteBool(_getKey(key, account));
  }

  function deleteAddressByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteAddress(key);
  }

  function deleteAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    return s.deleteAddress(_getKey(key1, key2));
  }

  function deleteAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external {
    return s.deleteAddress(_getKey(key1, key2, key3));
  }

  function deleteAddressArrayByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteAddressArrayItem(key, value);
  }

  function deleteAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    return s.deleteAddressArrayItem(_getKey(key1, key2), value);
  }

  function deleteAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    return s.deleteAddressArrayItem(_getKey(key1, key2, key3), value);
  }

  function deleteAddressArrayByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteAddressArrayItemByIndex(key, index);
  }

  function deleteAddressArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external {
    return s.deleteAddressArrayItemByIndex(_getKey(key1, key2), index);
  }

  function deleteAddressArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external {
    return s.deleteAddressArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function getUintByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getUint(key);
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2, key3));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (uint256) {
    return s.getUint(_getKey(key1, key2, account));
  }

  function getStringByKey(IStore s, bytes32 key) external view returns (string memory) {
    require(key > 0, "Invalid key");
    return s.getString(key);
  }

  function getStringByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (string memory) {
    return s.getString(_getKey(key1, key2));
  }

  function getBytes32ByKey(IStore s, bytes32 key) external view returns (bytes32) {
    require(key > 0, "Invalid key");
    return s.getBytes32(key);
  }

  function getBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bytes32) {
    return s.getBytes32(_getKey(key1, key2));
  }

  function getBoolByKey(IStore s, bytes32 key) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getBool(key);
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (bool) {
    return s.getBool(_getKey(key1, key2, key3));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bool) {
    return s.getBool(_getKey(key1, key2));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    return s.getBool(_getKey(key, account));
  }

  function getAddressByKey(IStore s, bytes32 key) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddress(key);
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address) {
    return s.getAddress(_getKey(key1, key2));
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address) {
    return s.getAddress(_getKey(key1, key2, key3));
  }

  function getAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getAddressBoolean(key, account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (bool) {
    return s.getAddressBoolean(_getKey(key1, key2), account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account
  ) external view returns (bool) {
    return s.getAddressBoolean(_getKey(key1, key2, key3), account);
  }

  function countAddressArrayByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.countAddressArrayItems(key);
  }

  function countAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.countAddressArrayItems(_getKey(key1, key2));
  }

  function countAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.countAddressArrayItems(_getKey(key1, key2, key3));
  }

  function getAddressArrayByKey(IStore s, bytes32 key) external view returns (address[] memory) {
    require(key > 0, "Invalid key");
    return s.getAddressArray(key);
  }

  function getAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address[] memory) {
    return s.getAddressArray(_getKey(key1, key2));
  }

  function getAddressArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address[] memory) {
    return s.getAddressArray(_getKey(key1, key2, key3));
  }

  function getAddressArrayItemPositionByKey(
    IStore s,
    bytes32 key,
    address addressToFind
  ) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getAddressArrayItemPosition(key, addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPosition(_getKey(key1, key2), addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPosition(_getKey(key1, key2, key3), addressToFind);
  }

  function getAddressArrayItemByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddressArrayItemByIndex(key, index);
  }

  function getAddressArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndex(_getKey(key1, key2), index);
  }

  function getAddressArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function _getKey(bytes32 key1, bytes32 key2) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key1, key2));
  }

  function _getKey(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key1, key2, key3));
  }

  function _getKey(bytes32 key, address account) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key, account));
  }

  function _getKey(
    bytes32 key1,
    bytes32 key2,
    address account
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(key1, key2, account));
  }

  function setBytes32ArrayByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    return s.setBytes32ArrayItem(key, value);
  }

  function setBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    return s.setBytes32ArrayItem(_getKey(key1, key2), value);
  }

  function setBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    return s.setBytes32ArrayItem(_getKey(key1, key2, key3), value);
  }

  function deleteBytes32ArrayByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteBytes32ArrayItem(key, value);
  }

  function deleteBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    return s.deleteBytes32ArrayItem(_getKey(key1, key2), value);
  }

  function deleteBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    return s.deleteBytes32ArrayItem(_getKey(key1, key2, key3), value);
  }

  function deleteBytes32ArrayByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external {
    require(key > 0, "Invalid key");
    return s.deleteBytes32ArrayItemByIndex(key, index);
  }

  function deleteBytes32ArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external {
    return s.deleteBytes32ArrayItemByIndex(_getKey(key1, key2), index);
  }

  function deleteBytes32ArrayByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external {
    return s.deleteBytes32ArrayItemByIndex(_getKey(key1, key2, key3), index);
  }

  function countBytes32ArrayByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.countBytes32ArrayItems(key);
  }

  function countBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    return s.countBytes32ArrayItems(_getKey(key1, key2));
  }

  function countBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.countBytes32ArrayItems(_getKey(key1, key2, key3));
  }

  function getBytes32ArrayByKey(IStore s, bytes32 key) external view returns (bytes32[] memory) {
    require(key > 0, "Invalid key");
    return s.getBytes32Array(key);
  }

  function getBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bytes32[] memory) {
    return s.getBytes32Array(_getKey(key1, key2));
  }

  function getBytes32ArrayByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (bytes32[] memory) {
    return s.getBytes32Array(_getKey(key1, key2, key3));
  }

  function getBytes32ArrayItemPositionByKey(
    IStore s,
    bytes32 key,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getBytes32ArrayItemPosition(key, bytes32ToFind);
  }

  function getBytes32ArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    return s.getBytes32ArrayItemPosition(_getKey(key1, key2), bytes32ToFind);
  }

  function getBytes32ArrayItemPositionByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    return s.getBytes32ArrayItemPosition(_getKey(key1, key2, key3), bytes32ToFind);
  }

  function getBytes32ArrayItemByIndexByKey(
    IStore s,
    bytes32 key,
    uint256 index
  ) external view returns (bytes32) {
    require(key > 0, "Invalid key");
    return s.getBytes32ArrayItemByIndex(key, index);
  }

  function getBytes32ArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external view returns (bytes32) {
    return s.getBytes32ArrayItemByIndex(_getKey(key1, key2), index);
  }

  function getBytes32ArrayItemByIndexByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external view returns (bytes32) {
    return s.getBytes32ArrayItemByIndex(_getKey(key1, key2, key3), index);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/ILendingStrategy.sol";
import "./PriceLibV1.sol";
import "./ProtoUtilV1.sol";
import "./CoverUtilV1.sol";
import "./RegistryLibV1.sol";
import "./StrategyLibV1.sol";
import "./ValidationLibV1.sol";

library RoutineInvokerLibV1 {
  using PriceLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using StrategyLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;

  enum Action {
    Deposit,
    Withdraw
  }

  function updateStateAndLiquidity(IStore s, bytes32 coverKey) external {
    _invoke(s, coverKey);
  }

  function _invoke(IStore s, bytes32 coverKey) private {
    // solhint-disable-next-line
    if (s.getLastUpdatedOnInternal(coverKey) + _getUpdateInterval(s) > block.timestamp) {
      return;
    }

    PriceLibV1.setNpmPrice(s);

    if (coverKey > 0) {
      _updateWithdrawalPeriod(s, coverKey);
      _invokeAssetManagement(s, coverKey);
      s.setLastUpdatedOn(coverKey);
    }
  }

  function _getUpdateInterval(IStore s) private view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_LIQUIDITY_STATE_UPDATE_INTERVAL);
  }

  function getWithdrawalInfoInternal(IStore s, bytes32 coverKey)
    public
    view
    returns (
      bool isWithdrawalPeriod,
      uint256 lendingPeriod,
      uint256 withdrawalWindow,
      uint256 start,
      uint256 end
    )
  {
    (lendingPeriod, withdrawalWindow) = s.getRiskPoolingPeriodsInternal(coverKey);

    // Get the withdrawal period of this cover liquidity
    start = s.getUintByKey(getNextWithdrawalStartKey(coverKey));
    end = s.getUintByKey(getNextWithdrawalEndKey(coverKey));

    // solhint-disable-next-line
    if (block.timestamp >= start && block.timestamp <= end) {
      isWithdrawalPeriod = true;
    }
  }

  function _isWithdrawalPeriod(IStore s, bytes32 coverKey) private view returns (bool) {
    (bool isWithdrawalPeriod, , , , ) = getWithdrawalInfoInternal(s, coverKey);
    return isWithdrawalPeriod;
  }

  function _updateWithdrawalPeriod(IStore s, bytes32 coverKey) private {
    (, uint256 lendingPeriod, uint256 withdrawalWindow, uint256 start, uint256 end) = getWithdrawalInfoInternal(s, coverKey);

    // Without a lending period and withdrawal window, nothing can be updated
    if (lendingPeriod == 0 || withdrawalWindow == 0) {
      return;
    }

    // The withdrawal period is now over.
    // Deposits can be performed again.
    // Set the next withdrawal cycle
    if (block.timestamp > end) {
      // solhint-disable-previous-line

      // Next Withdrawal Cycle

      // Withdrawals can start after the lending period
      start = block.timestamp + lendingPeriod; // solhint-disable
      // Withdrawals can be performed until the end of the next withdrawal cycle
      end = start + withdrawalWindow;

      s.setUintByKey(getNextWithdrawalStartKey(coverKey), start);
      s.setUintByKey(getNextWithdrawalEndKey(coverKey), end);
      setAccrualCompleteInternal(s, coverKey, false);
    }
  }

  function isAccrualCompleteInternal(IStore s, bytes32 coverKey) external view returns (bool) {
    return s.getBoolByKey(getAccrualInvocationKey(coverKey));
  }

  function setAccrualCompleteInternal(
    IStore s,
    bytes32 coverKey,
    bool flag
  ) public {
    s.setBoolByKey(getAccrualInvocationKey(coverKey), flag);
  }

  function getAccrualInvocationKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_ACCRUAL_INVOCATION, coverKey));
  }

  function getNextWithdrawalStartKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_WITHDRAWAL_START, coverKey));
  }

  function getNextWithdrawalEndKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_WITHDRAWAL_END, coverKey));
  }

  function mustBeDuringWithdrawalPeriod(IStore s, bytes32 coverKey) external view {
    // Get the withdrawal period of this cover liquidity
    uint256 start = s.getUintByKey(getNextWithdrawalStartKey(coverKey));
    uint256 end = s.getUintByKey(getNextWithdrawalEndKey(coverKey));

    require(start > 0 && block.timestamp >= start, "Withdrawal period has not started");
    require(end > 0 && block.timestamp < end, "Withdrawal period has already ended");
  }

  function _executeAndGetAction(
    IStore s,
    ILendingStrategy,
    bytes32 coverKey
  ) private returns (Action) {
    // If the cover is undergoing reporting, withdraw everything
    bool isNormal = s.isCoverNormalInternal(coverKey);

    if (isNormal != true) {
      // Reset the withdrawal window
      s.setUintByKey(getNextWithdrawalStartKey(coverKey), 0);
      s.setUintByKey(getNextWithdrawalEndKey(coverKey), 0);

      return Action.Withdraw;
    }

    if (_isWithdrawalPeriod(s, coverKey) == true) {
      return Action.Withdraw;
    }

    return Action.Deposit;
  }

  function _canDeposit(
    IStore s,
    ILendingStrategy strategy,
    uint256 totalStrategies,
    bytes32 coverKey
  ) private view returns (uint256) {
    IERC20 stablecoin = IERC20(s.getStablecoin());

    uint256 totalBalance = s.getStablecoinOwnedByVaultInternal(coverKey);
    uint256 maximumAllowed = (totalBalance * s.getMaxLendingRatioInternal()) / ProtoUtilV1.MULTIPLIER;
    uint256 allocation = maximumAllowed / totalStrategies;
    uint256 weight = strategy.getWeight();
    uint256 canDeposit = (allocation * weight) / ProtoUtilV1.MULTIPLIER;
    uint256 alreadyDeposited = s.getAmountInStrategy(coverKey, strategy.getName(), address(stablecoin));

    if (alreadyDeposited >= canDeposit) {
      return 0;
    }

    return canDeposit - alreadyDeposited;
  }

  function _invokeAssetManagement(IStore s, bytes32 coverKey) private {
    address vault = s.getVaultAddress(coverKey);
    _withdrawFromDisabled(s, coverKey, vault);

    address[] memory strategies = s.getActiveStrategiesInternal();

    for (uint256 i = 0; i < strategies.length; i++) {
      ILendingStrategy strategy = ILendingStrategy(strategies[i]);
      _executeStrategy(s, strategy, strategies.length, vault, coverKey);
    }
  }

  function _executeStrategy(
    IStore s,
    ILendingStrategy strategy,
    uint256 totalStrategies,
    address vault,
    bytes32 coverKey
  ) private {
    uint256 canDeposit = _canDeposit(s, strategy, totalStrategies, coverKey);
    uint256 balance = IERC20(s.getStablecoin()).balanceOf(vault);

    if (canDeposit > balance) {
      canDeposit = balance;
    }

    Action action = _executeAndGetAction(s, strategy, coverKey);

    if (action == Action.Deposit && canDeposit == 0) {
      return;
    }

    if (action == Action.Withdraw) {
      _withdrawAllFromStrategy(strategy, vault, coverKey);
      return;
    }

    _depositToStrategy(strategy, coverKey, canDeposit);
  }

  function _depositToStrategy(
    ILendingStrategy strategy,
    bytes32 coverKey,
    uint256 amount
  ) private {
    strategy.deposit(coverKey, amount);
  }

  function _withdrawAllFromStrategy(
    ILendingStrategy strategy,
    address vault,
    bytes32 coverKey
  ) private returns (uint256 stablecoinWithdrawn) {
    uint256 balance = IERC20(strategy.getDepositCertificate()).balanceOf(vault);

    if (balance > 0) {
      stablecoinWithdrawn = strategy.withdraw(coverKey);
    }
  }

  function _withdrawFromDisabled(
    IStore s,
    bytes32 coverKey,
    address onBehalfOf
  ) private {
    address[] memory strategies = s.getDisabledStrategiesInternal();

    for (uint256 i = 0; i < strategies.length; i++) {
      ILendingStrategy strategy = ILendingStrategy(strategies[i]);
      uint256 balance = IERC20(strategy.getDepositCertificate()).balanceOf(onBehalfOf);

      if (balance > 0) {
        strategy.withdraw(coverKey);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IStore.sol";

interface IRecoverable {
  function s() external view returns (IStore);

  function recoverEther(address sendTo) external;

  function recoverToken(address token, address sendTo) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ValidationLibV1.sol";
import "./AccessControlLibV1.sol";
import "../interfaces/IProtocol.sol";
import "../interfaces/IPausable.sol";

library BaseLibV1 {
  using ValidationLibV1 for IStore;
  using SafeERC20 for IERC20;

  /**
   * @dev Recover all Ether held by the contract.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   */
  function recoverEtherInternal(address sendTo) external {
    // slither-disable-next-line arbitrary-send
    payable(sendTo).transfer(address(this).balance);
  }

  /**
   * @dev Recover all IERC-20 compatible tokens sent to this address.
   * On success, no event is emitted because the recovery feature does
   * not have any significance in the SDK or the UI.
   *
   * @custom:suppress-malicious-erc Risk tolerable. Although the token can't be trusted, the recovery agent has to check the token code manually.
   * @custom:suppress-address-trust-issue Risk tolerable. Although the token can't be trusted, the recovery agent has to check the token code manually.
   *
   * @param token IERC-20 The address of the token contract
   */
  function recoverTokenInternal(address token, address sendTo) external {
    IERC20 erc20 = IERC20(token);

    uint256 balance = erc20.balanceOf(address(this));

    if (balance > 0) {
      // slither-disable-next-line unchecked-transfer
      erc20.safeTransfer(sendTo, balance);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IStore {
  function setAddress(bytes32 k, address v) external;

  function setAddressBoolean(
    bytes32 k,
    address a,
    bool v
  ) external;

  function setUint(bytes32 k, uint256 v) external;

  function addUint(bytes32 k, uint256 v) external;

  function subtractUint(bytes32 k, uint256 v) external;

  function setUints(bytes32 k, uint256[] calldata v) external;

  function setString(bytes32 k, string calldata v) external;

  function setBytes(bytes32 k, bytes calldata v) external;

  function setBool(bytes32 k, bool v) external;

  function setInt(bytes32 k, int256 v) external;

  function setBytes32(bytes32 k, bytes32 v) external;

  function setAddressArrayItem(bytes32 k, address v) external;

  function setBytes32ArrayItem(bytes32 k, bytes32 v) external;

  function deleteAddress(bytes32 k) external;

  function deleteUint(bytes32 k) external;

  function deleteUints(bytes32 k) external;

  function deleteString(bytes32 k) external;

  function deleteBytes(bytes32 k) external;

  function deleteBool(bytes32 k) external;

  function deleteInt(bytes32 k) external;

  function deleteBytes32(bytes32 k) external;

  function deleteAddressArrayItem(bytes32 k, address v) external;

  function deleteBytes32ArrayItem(bytes32 k, bytes32 v) external;

  function deleteAddressArrayItemByIndex(bytes32 k, uint256 i) external;

  function deleteBytes32ArrayItemByIndex(bytes32 k, uint256 i) external;

  function getAddressValues(bytes32[] calldata keys) external view returns (address[] memory values);

  function getAddress(bytes32 k) external view returns (address);

  function getAddressBoolean(bytes32 k, address a) external view returns (bool);

  function getUintValues(bytes32[] calldata keys) external view returns (uint256[] memory values);

  function getUint(bytes32 k) external view returns (uint256);

  function getUints(bytes32 k) external view returns (uint256[] memory);

  function getString(bytes32 k) external view returns (string memory);

  function getBytes(bytes32 k) external view returns (bytes memory);

  function getBool(bytes32 k) external view returns (bool);

  function getInt(bytes32 k) external view returns (int256);

  function getBytes32(bytes32 k) external view returns (bytes32);

  function countAddressArrayItems(bytes32 k) external view returns (uint256);

  function countBytes32ArrayItems(bytes32 k) external view returns (uint256);

  function getAddressArray(bytes32 k) external view returns (address[] memory);

  function getBytes32Array(bytes32 k) external view returns (bytes32[] memory);

  function getAddressArrayItemPosition(bytes32 k, address toFind) external view returns (uint256);

  function getBytes32ArrayItemPosition(bytes32 k, bytes32 toFind) external view returns (uint256);

  function getAddressArrayItemByIndex(bytes32 k, uint256 i) external view returns (address);

  function getBytes32ArrayItemByIndex(bytes32 k, uint256 i) external view returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./ProtoUtilV1.sol";

library AccessControlLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  bytes32 public constant NS_ROLES_ADMIN = 0x00; // SAME AS "DEFAULT_ADMIN_ROLE"
  bytes32 public constant NS_ROLES_COVER_MANAGER = "role:cover:manager";
  bytes32 public constant NS_ROLES_LIQUIDITY_MANAGER = "role:liquidity:manager";
  bytes32 public constant NS_ROLES_GOVERNANCE_AGENT = "role:governance:agent";
  bytes32 public constant NS_ROLES_GOVERNANCE_ADMIN = "role:governance:admin";
  bytes32 public constant NS_ROLES_UPGRADE_AGENT = "role:upgrade:agent";
  bytes32 public constant NS_ROLES_RECOVERY_AGENT = "role:recovery:agent";
  bytes32 public constant NS_ROLES_PAUSE_AGENT = "role:pause:agent";
  bytes32 public constant NS_ROLES_UNPAUSE_AGENT = "role:unpause:agent";

  /**
   * @dev Reverts if the sender is not the protocol admin.
   */
  function mustBeAdmin(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_ADMIN, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the cover manager.
   */
  function mustBeCoverManager(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_COVER_MANAGER, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the liquidity manager.
   */
  function mustBeLiquidityManager(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_LIQUIDITY_MANAGER, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not a governance agent.
   */
  function mustBeGovernanceAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not a governance admin.
   */
  function mustBeGovernanceAdmin(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_ADMIN, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not an upgrade agent.
   */
  function mustBeUpgradeAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_UPGRADE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not a recovery agent.
   */
  function mustBeRecoveryAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_RECOVERY_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the pause agent.
   */
  function mustBePauseAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_PAUSE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the unpause agent.
   */
  function mustBeUnpauseAgent(IStore s) external view {
    _mustHaveAccess(s, NS_ROLES_UNPAUSE_AGENT, msg.sender);
  }

  /**
   * @dev Reverts if the sender is not the protocol admin.
   */
  function callerMustBeAdmin(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_ADMIN, caller);
  }

  /**
   * @dev Reverts if the sender is not the cover manager.
   */
  function callerMustBeCoverManager(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_COVER_MANAGER, caller);
  }

  /**
   * @dev Reverts if the sender is not the liquidity manager.
   */
  function callerMustBeLiquidityManager(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_LIQUIDITY_MANAGER, caller);
  }

  /**
   * @dev Reverts if the sender is not a governance agent.
   */
  function callerMustBeGovernanceAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not a governance admin.
   */
  function callerMustBeGovernanceAdmin(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_GOVERNANCE_ADMIN, caller);
  }

  /**
   * @dev Reverts if the sender is not an upgrade agent.
   */
  function callerMustBeUpgradeAgent(IStore s, address caller) public view {
    _mustHaveAccess(s, NS_ROLES_UPGRADE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not a recovery agent.
   */
  function callerMustBeRecoveryAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_RECOVERY_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not the pause agent.
   */
  function callerMustBePauseAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_PAUSE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender is not the unpause agent.
   */
  function callerMustBeUnpauseAgent(IStore s, address caller) external view {
    _mustHaveAccess(s, NS_ROLES_UNPAUSE_AGENT, caller);
  }

  /**
   * @dev Reverts if the sender does not have access to the given role.
   */
  function _mustHaveAccess(
    IStore s,
    bytes32 role,
    address caller
  ) private view {
    require(hasAccess(s, role, caller), "Forbidden");
  }

  /**
   * @dev Checks if a given user has access to the given role
   * @param role Specify the role name
   * @param user Enter the user account
   * @return Returns true if the user is a member of the specified role
   */
  function hasAccess(
    IStore s,
    bytes32 role,
    address user
  ) public view returns (bool) {
    address protocol = s.getProtocolAddress();

    // The protocol is not deployed yet. Therefore, no role to check
    if (protocol == address(0)) {
      return false;
    }

    // You must have the same role in the protocol contract if you're don't have this role here
    return IAccessControl(protocol).hasRole(role, user);
  }

  /**
   * @dev Adds a protocol member contract
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param s Enter the store instance
   * @param namespace Enter the contract namespace
   * @param key Enter the contract key
   * @param contractAddress Enter the contract address
   */
  function addContractInternal(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address contractAddress
  ) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));
    _addContract(s, namespace, key, contractAddress);
  }

  function _addContract(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address contractAddress
  ) private {
    if (key > 0) {
      s.setAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, key, contractAddress);
    } else {
      s.setAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, contractAddress);
    }
    _addMember(s, contractAddress);
  }

  function _deleteContract(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address contractAddress
  ) private {
    if (key > 0) {
      s.deleteAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, key);
    } else {
      s.deleteAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace);
    }
    _removeMember(s, contractAddress);
  }

  /**
   * @dev Upgrades a contract at the given namespace and key.
   *
   * The previous contract's protocol membership is revoked and
   * the current immediately starts assuming responsbility of
   * whatever the contract needs to do at the supplied namespace and key.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an upgrade agent.
   * Since adding member to the protocol is a highy risky activity,
   * the role `Upgrade Agent` is considered to be one of the most `Critical` roles.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param s Provide store instance
   * @param namespace Enter a unique namespace for this contract
   * @param key Enter a key if this contract has siblings
   * @param previous Enter the existing contract address at this namespace and key.
   * @param current Enter the contract address which will replace the previous contract.
   */
  function upgradeContractInternal(
    IStore s,
    bytes32 namespace,
    bytes32 key,
    address previous,
    address current
  ) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));

    bool isMember = s.isProtocolMember(previous);
    require(isMember, "Not a protocol member");

    _deleteContract(s, namespace, key, previous);
    _addContract(s, namespace, key, current);
  }

  /**
   * @dev Adds member to the protocol
   *
   * A member is a trusted EOA or a contract that was added to the protocol using `addContract`
   * function. When a contract is removed using `upgradeContract` function, the membership of previous
   * contract is also removed.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an upgrade agent.
   * Since adding member to the protocol is a highy risky activity,
   * the role `Upgrade Agent` is considered to be one of the most `Critical` roles.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param member Enter an address to add as a protocol member
   */
  function addMemberInternal(IStore s, address member) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));

    _addMember(s, member);
  }

  /**
   * @dev Removes a member from the protocol. This function is only accessible
   * to an upgrade agent.
   *
   * @custom:suppress-address-trust-issue This feature can only be accessed internally within the protocol.
   *
   * @param member Enter an address to remove as a protocol member
   */
  function removeMemberInternal(IStore s, address member) external {
    // Not only the msg.sender needs to be an upgrade agent
    // but the contract using this library (and this function)
    // must also be an upgrade agent
    callerMustBeUpgradeAgent(s, address(this));

    _removeMember(s, member);
  }

  function _addMember(IStore s, address member) private {
    require(s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, member) == false, "Already exists");
    s.setBoolByKeys(ProtoUtilV1.NS_MEMBERS, member, true);
  }

  function _removeMember(IStore s, address member) private {
    s.deleteBoolByKeys(ProtoUtilV1.NS_MEMBERS, member);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./IMember.sol";

interface IProtocol is IMember, IAccessControl {
  struct AccountWithRoles {
    address account;
    bytes32[] roles;
  }

  event ContractAdded(bytes32 indexed namespace, bytes32 indexed key, address indexed contractAddress);
  event ContractUpgraded(bytes32 indexed namespace, bytes32 indexed key, address previous, address indexed current);
  event MemberAdded(address member);
  event MemberRemoved(address member);

  function addContract(bytes32 namespace, address contractAddress) external;

  function addContractWithKey(
    bytes32 namespace,
    bytes32 coverKey,
    address contractAddress
  ) external;

  function initialize(address[] calldata addresses, uint256[] calldata values) external;

  function upgradeContract(
    bytes32 namespace,
    address previous,
    address current
  ) external;

  function upgradeContractWithKey(
    bytes32 namespace,
    bytes32 coverKey,
    address previous,
    address current
  ) external;

  function addMember(address member) external;

  function removeMember(address member) external;

  function grantRoles(AccountWithRoles[] calldata detail) external;

  event Initialized(address[] addresses, uint256[] values);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPausable {
  function paused() external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../dependencies/BokkyPooBahsDateTimeLibrary.sol";
import "../interfaces/IStore.sol";
import "./ProtoUtilV1.sol";
import "./AccessControlLibV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./StrategyLibV1.sol";
import "../interfaces/ICxToken.sol";
import "../interfaces/IERC20Detailed.sol";

library CoverUtilV1 {
  using RegistryLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using AccessControlLibV1 for IStore;
  using StrategyLibV1 for IStore;

  uint256 public constant REASSURANCE_WEIGHT_FALLBACK_VALUE = 8000;

  enum ProductStatus {
    Normal,
    Stopped,
    IncidentHappened,
    FalseReporting,
    Claimable
  }

  /**
   * @dev Returns the given cover's owner.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param s Specify store instance
   * @param coverKey Enter cover key
   *
   */
  function getCoverOwner(IStore s, bytes32 coverKey) external view returns (address) {
    return _getCoverOwner(s, coverKey);
  }

  function _getCoverOwner(IStore s, bytes32 coverKey) private view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, coverKey);
  }

  /**
   * @dev Returns cover creation fee information.
   * @param s Specify store instance
   */
  function getCoverCreationFeeInfo(IStore s)
    external
    view
    returns (
      uint256 fee,
      uint256 minCoverCreationStake,
      uint256 minStakeToAddLiquidity
    )
  {
    fee = s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_FEE);
    minCoverCreationStake = getMinCoverCreationStake(s);
    minStakeToAddLiquidity = getMinStakeToAddLiquidity(s);
  }

  /**
   * @dev Returns minimum NPM stake to create a new cover.
   * @param s Specify store instance
   */
  function getMinCoverCreationStake(IStore s) public view returns (uint256) {
    uint256 value = s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_MIN_STAKE);

    if (value == 0) {
      // Fallback to 250 NPM
      value = 250 ether;
    }

    return value;
  }

  /**
   * @dev Returns a cover's creation date
   * @custom:todo check if this used anywhere.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param s Specify store instance
   * @param coverKey Enter cover key
   *
   */
  function getCoverCreationDate(IStore s, bytes32 coverKey) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_CREATION_DATE, coverKey);
  }

  /**
   * @dev Returns minimum NPM stake to add liquidity.
   * @param s Specify store instance
   */
  function getMinStakeToAddLiquidity(IStore s) public view returns (uint256) {
    uint256 value = s.getUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_MIN_STAKE);

    if (value == 0) {
      // Fallback to 250 NPM
      value = 250 ether;
    }

    return value;
  }

  /**
   * @dev Gets claim period/duration of the given cover.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param s Specify store instance
   * @param coverKey Enter cover key
   *
   */
  function getClaimPeriod(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 fromKey = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_PERIOD, coverKey);
    uint256 fallbackValue = s.getUintByKey(ProtoUtilV1.NS_CLAIM_PERIOD);

    return fromKey > 0 ? fromKey : fallbackValue;
  }

  /**
   * @dev Returns a summary of the given cover pool.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] Reassurance amount
   * @param _values[3] Reassurance pool weight
   * @param _values[4] Count of products under this cover
   * @param _values[5] Leverage
   * @param _values[6] Cover product efficiency weight
   */
  function getCoverPoolSummaryInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (uint256[] memory _values) {
    _values = new uint256[](8);

    uint256 precision = s.getStablecoinPrecision();

    _values[0] = s.getStablecoinOwnedByVaultInternal(coverKey); // precision: stablecoin
    _values[1] = getActiveLiquidityUnderProtection(s, coverKey, productKey, precision); // <-- adjusted precision
    _values[2] = getReassuranceAmountInternal(s, coverKey); // precision: stablecoin
    _values[3] = getReassuranceWeightInternal(s, coverKey);
    _values[4] = s.countBytes32ArrayByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey);
    _values[5] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LEVERAGE_FACTOR, coverKey);
    _values[6] = s.getUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT_EFFICIENCY, coverKey, productKey);
  }

  /**
   * @dev Gets the reassurance weight of a given cover key.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param s Provide store instance
   * @param coverKey Enter the cover for which you want to obtain the reassurance weight for.
   *
   * @return If reassurance weight value wasn't set for the specified cover pool,
   * the global value will be returned.
   *
   * If global value, too, isn't available, a fallback value of `REASSURANCE_WEIGHT_FALLBACK_VALUE`
   * is returned.
   */
  function getReassuranceWeightInternal(IStore s, bytes32 coverKey) public view returns (uint256) {
    uint256 setForTheCoverPool = s.getUintByKey(getReassuranceWeightKey(coverKey));

    if (setForTheCoverPool > 0) {
      return setForTheCoverPool;
    }

    // Globally set value: not set for any specifical cover
    uint256 setGlobally = s.getUintByKey(getReassuranceWeightKey(0));

    if (setGlobally > 0) {
      return setGlobally;
    }

    return REASSURANCE_WEIGHT_FALLBACK_VALUE;
  }

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the cover key
   *
   */
  function getReassuranceAmountInternal(IStore s, bytes32 coverKey) public view returns (uint256) {
    return s.getUintByKey(getReassuranceKey(coverKey));
  }

  /**
   * @dev Returns reassurance rate of the specified cover key.
   * @custom:todo improve documentation
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param s Specify store
   * @param coverKey Enter cover key
   *
   */
  function getReassuranceRateInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 rate = s.getUintByKey(getReassuranceRateKey(coverKey));

    if (rate > 0) {
      return rate;
    }

    // Default: 25%
    return 2500;
  }

  /**
   * @dev Computes `reassurance` storage key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter cover key
   *
   */
  function getReassuranceKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE, coverKey));
  }

  /**
   * @dev Computes `reassurance rate` storage key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter cover key
   *
   */
  function getReassuranceRateKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE_RATE, coverKey));
  }

  /**
   * @dev Computes `reassurance weight` storage key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter cover key
   *
   */
  function getReassuranceWeightKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE_WEIGHT, coverKey));
  }

  function isCoverNormalInternal(IStore s, bytes32 coverKey) external view returns (bool) {
    bool supportsProducts = supportsProductsInternal(s, coverKey);

    if (supportsProducts == false) {
      return getProductStatusInternal(s, coverKey, 0) == ProductStatus.Normal;
    }

    bytes32[] memory products = _getProducts(s, coverKey);

    for (uint256 i = 0; i < products.length; i++) {
      bool isNormal = getProductStatusInternal(s, coverKey, products[i]) == ProductStatus.Normal;

      if (!isNormal) {
        return false;
      }
    }

    return true;
  }

  /**
   * @dev Gets product status of the given cover and product keys.
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   * @param s Specify store instance
   * @param coverKey Enter cover key
   * @param productKey Enter product key
   *
   */
  function getProductStatusInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (ProductStatus) {
    return ProductStatus(s.getUintByKey(getProductStatusKey(coverKey, productKey)));
  }

  /**
   * @dev Returns the current status of a given cover product as uint.
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   * @param s Specify store instance
   * @param coverKey Enter cover key
   * @param productKey Enter product key
   *
   */
  function getStatusInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (uint256) {
    return s.getUintByKey(getProductStatusKey(coverKey, productKey));
  }

  /**
   * @dev Returns current status a given cover product as `ProductStatus`.
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   * @param s Specify store instance
   * @param coverKey Enter cover key
   * @param productKey Enter product key
   *
   */
  function getProductStatusOf(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (ProductStatus) {
    return ProductStatus(getStatusOf(s, coverKey, productKey, incidentDate));
  }

  function getStatusOf(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    return s.getUintByKey(getProductStatusOfKey(coverKey, productKey, incidentDate));
  }

  /**
   * @dev Hash key of the product status of the given cover and product
   * to find out the current status. This gets reset during finalization.
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   * @param coverKey Enter cover key
   * @param productKey Enter product key
   *
   */
  function getProductStatusKey(bytes32 coverKey, bytes32 productKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_STATUS, coverKey, productKey));
  }

  /**
   * @dev Hash key of the product status of (the given cover, product, and incident date)
   * for historical significance. This must not be reset during finalization.
   */
  function getProductStatusOfKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_STATUS, coverKey, productKey, incidentDate));
  }

  function getCoverLiquidityStakeKey(bytes32 coverKey) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_STAKE, coverKey));
  }

  function getLastDepositHeightKey(bytes32 coverKey) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_DEPOSIT_HEIGHTS, coverKey));
  }

  function getCoverLiquidityStakeIndividualKey(bytes32 coverKey, address account) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_STAKE, coverKey, account));
  }

  function getBlacklistKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_CLAIM_BLACKLIST, coverKey, productKey, incidentDate));
  }

  function getTotalLiquidityUnderProtection(
    IStore s,
    bytes32 coverKey,
    uint256 precision
  ) external view returns (uint256 total) {
    bool supportsProducts = supportsProductsInternal(s, coverKey);

    if (supportsProducts == false) {
      return getActiveLiquidityUnderProtection(s, coverKey, 0, precision);
    }

    bytes32[] memory products = _getProducts(s, coverKey);

    for (uint256 i = 0; i < products.length; i++) {
      total += getActiveLiquidityUnderProtection(s, coverKey, products[i], precision);
    }
  }

  function _getProducts(IStore s, bytes32 coverKey) private view returns (bytes32[] memory products) {
    return s.getBytes32ArrayByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey);
  }

  function getActiveLiquidityUnderProtection(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 adjustPrecision
  ) public view returns (uint256 total) {
    (uint256 current, uint256 future) = _getLiquidityUnderProtectionInfo(s, coverKey, productKey);
    total = current + future;

    // @caution:
    // Adjusting precision results in truncation and data loss.
    //
    // Can also open a can of worms if the protocol stablecoin
    // address needs to be updated in the future.
    total = (total * adjustPrecision) / ProtoUtilV1.CXTOKEN_PRECISION;
  }

  function _getLiquidityUnderProtectionInfo(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) private view returns (uint256 current, uint256 future) {
    uint256 expiryDate = 0;

    (current, expiryDate) = _getCurrentCommitment(s, coverKey, productKey);
    future = _getFutureCommitments(s, coverKey, productKey, expiryDate);
  }

  function _getCurrentCommitment(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) private view returns (uint256 amount, uint256 expiryDate) {
    uint256 incidentDateIfAny = getActiveIncidentDateInternal(s, coverKey, productKey);

    // There isn't any incident for this cover
    // and therefore no need to pay
    if (incidentDateIfAny == 0) {
      return (0, 0);
    }

    expiryDate = _getMonthEndDate(incidentDateIfAny);
    ICxToken cxToken = ICxToken(getCxTokenByExpiryDateInternal(s, coverKey, productKey, expiryDate));

    if (address(cxToken) != address(0)) {
      amount = cxToken.totalSupply();
    }
  }

  function _getFutureCommitments(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 ignoredExpiryDate
  ) private view returns (uint256 sum) {
    uint256 maxMonthsToProtect = 3;

    for (uint256 i = 0; i < maxMonthsToProtect; i++) {
      uint256 expiryDate = _getNextMonthEndDate(block.timestamp, i); // solhint-disable-line

      if (expiryDate == ignoredExpiryDate || expiryDate <= block.timestamp) {
        // solhint-disable-previous-line
        continue;
      }

      ICxToken cxToken = ICxToken(getCxTokenByExpiryDateInternal(s, coverKey, productKey, expiryDate));

      if (address(cxToken) != address(0)) {
        sum += cxToken.totalSupply();
      }
    }
  }

  function getStake(IStore s, bytes32 coverKey) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE, coverKey);
  }

  /**
   * @dev Sets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function setStatusInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    ProductStatus status
  ) external {
    s.setUintByKey(getProductStatusKey(coverKey, productKey), uint256(status));

    if (incidentDate > 0) {
      s.setUintByKey(getProductStatusOfKey(coverKey, productKey, incidentDate), uint256(status));
    }
  }

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDateInternal(uint256 today, uint256 coverDuration) external pure returns (uint256) {
    // Get the day of the month
    (, , uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(today);

    // Cover duration of 1 month means current month
    // unless today is the 25th calendar day or later
    uint256 monthToAdd = coverDuration - 1;

    if (day >= 25) {
      // Add one month
      monthToAdd += 1;
    }

    return _getNextMonthEndDate(today, monthToAdd);
  }

  // function _getPreviousMonthEndDate(uint256 date, uint256 monthsToSubtract) private pure returns (uint256) {
  //   uint256 pastDate = BokkyPooBahsDateTimeLibrary.subMonths(date, monthsToSubtract);
  //   return _getMonthEndDate(pastDate);
  // }

  function _getNextMonthEndDate(uint256 date, uint256 monthsToAdd) private pure returns (uint256) {
    uint256 futureDate = BokkyPooBahsDateTimeLibrary.addMonths(date, monthsToAdd);
    return _getMonthEndDate(futureDate);
  }

  function _getMonthEndDate(uint256 date) private pure returns (uint256) {
    // Get the year and month from the date
    (uint256 year, uint256 month, ) = BokkyPooBahsDateTimeLibrary.timestampToDate(date);

    // Count the total number of days of that month and year
    uint256 daysInMonth = BokkyPooBahsDateTimeLibrary._getDaysInMonth(year, month);

    // Get the month end date
    return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, daysInMonth, 23, 59, 59);
  }

  function getActiveIncidentDateInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey);
  }

  function getCxTokenByExpiryDateInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 expiryDate
  ) public view returns (address cxToken) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_CXTOKEN, coverKey, productKey, expiryDate));
    cxToken = s.getAddress(k);
  }

  function checkIfProductRequiresWhitelist(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_REQUIRES_WHITELIST, coverKey, productKey);
  }

  function checkIfRequiresWhitelist(IStore s, bytes32 coverKey) external view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_REQUIRES_WHITELIST, coverKey);
  }

  function supportsProductsInternal(IStore s, bytes32 coverKey) public view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_SUPPORTS_PRODUCTS, coverKey);
  }

  function isValidProductInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey);
  }

  function isActiveProductInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey) == 1;
  }

  function disablePolicyInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    bool status
  ) external {
    bytes32 key = getPolicyDisabledKey(coverKey, productKey);
    s.setBoolByKey(key, status);
  }

  function isPolicyDisabledInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (bool) {
    bytes32 key = getPolicyDisabledKey(coverKey, productKey);
    return s.getBoolByKey(key);
  }

  function getPolicyDisabledKey(bytes32 coverKey, bytes32 productKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_POLICY_DISABLED, coverKey, productKey));
  }
}

/* solhint-disable function-max-lines */
// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../interfaces/IStore.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./RoutineInvokerLibV1.sol";
import "./StoreKeyUtil.sol";
import "./CoverUtilV1.sol";

library GovernanceUtilV1 {
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ProtoUtilV1 for IStore;
  using RoutineInvokerLibV1 for IStore;

  function getReportingPeriodInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_PERIOD, coverKey);
  }

  function getReportingBurnRateInternal(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE);
  }

  function getGovernanceReporterCommissionInternal(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION);
  }

  function getPlatformCoverFeeRateInternal(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_COVER_PLATFORM_FEE);
  }

  function getClaimReporterCommissionInternal(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_CLAIM_REPORTER_COMMISSION);
  }

  function getMinReportingStakeInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 fb = s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE);
    uint256 custom = s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, coverKey);

    return custom > 0 ? custom : fb;
  }

  function getLatestIncidentDateInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey);
  }

  function getResolutionTimestampInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, coverKey, productKey);
  }

  function getReporterInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (address) {
    CoverUtilV1.ProductStatus status = s.getProductStatusOf(coverKey, productKey, incidentDate);
    bool incidentHappened = status == CoverUtilV1.ProductStatus.IncidentHappened || status == CoverUtilV1.ProductStatus.Claimable;
    bytes32 prefix = incidentHappened ? ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES : ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO;

    return s.getAddressByKeys(prefix, coverKey, productKey);
  }

  function getStakesInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    yes = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));
    no = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));
  }

  function _getReporterKey(bytes32 coverKey, bytes32 productKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, coverKey, productKey));
  }

  function _getIncidentOccurredStakesKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, coverKey, productKey, incidentDate));
  }

  function _getClaimPayoutsKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_CLAIM_PAYOUTS, coverKey, productKey, incidentDate));
  }

  function _getReassurancePayoutKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_REASSURANCE_PAYOUT, coverKey, productKey, incidentDate));
  }

  function _getIndividualIncidentOccurredStakeKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_YES, coverKey, productKey, incidentDate, account));
  }

  function _getDisputerKey(bytes32 coverKey, bytes32 productKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, coverKey, productKey));
  }

  function _getFalseReportingStakesKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, coverKey, productKey, incidentDate));
  }

  function _getIndividualFalseReportingStakeKey(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_STAKE_OWNED_NO, coverKey, productKey, incidentDate, account));
  }

  function getStakesOfInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    yes = s.getUintByKey(_getIndividualIncidentOccurredStakeKey(coverKey, productKey, incidentDate, account));
    no = s.getUintByKey(_getIndividualFalseReportingStakeKey(coverKey, productKey, incidentDate, account));
  }

  function getResolutionInfoForInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  )
    public
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp
    )
  {
    (uint256 yes, uint256 no) = getStakesInternal(s, coverKey, productKey, incidentDate);
    (uint256 myYes, uint256 myNo) = getStakesOfInternal(s, account, coverKey, productKey, incidentDate);

    CoverUtilV1.ProductStatus decision = s.getProductStatusOf(coverKey, productKey, incidentDate);
    bool incidentHappened = decision == CoverUtilV1.ProductStatus.IncidentHappened || decision == CoverUtilV1.ProductStatus.Claimable;

    totalStakeInWinningCamp = incidentHappened ? yes : no;
    totalStakeInLosingCamp = incidentHappened ? no : yes;
    myStakeInWinningCamp = incidentHappened ? myYes : myNo;
  }

  function getUnstakeInfoForInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  )
    external
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp,
      uint256 toBurn,
      uint256 toReporter,
      uint256 myReward,
      uint256 unstaken
    )
  {
    (totalStakeInWinningCamp, totalStakeInLosingCamp, myStakeInWinningCamp) = getResolutionInfoForInternal(s, account, coverKey, productKey, incidentDate);

    unstaken = getReportingUnstakenAmountInternal(s, account, coverKey, productKey, incidentDate);
    require(myStakeInWinningCamp > 0, "Nothing to unstake");

    uint256 rewardRatio = (myStakeInWinningCamp * ProtoUtilV1.MULTIPLIER) / totalStakeInWinningCamp;

    uint256 reward = 0;

    // Incident dates are reset when a reporting is finalized.
    // This check ensures only the people who come to unstake
    // before the finalization will receive rewards
    if (getLatestIncidentDateInternal(s, coverKey, productKey) == incidentDate) {
      // slither-disable-next-line divide-before-multiply
      reward = (totalStakeInLosingCamp * rewardRatio) / ProtoUtilV1.MULTIPLIER;
    }

    toBurn = (reward * getReportingBurnRateInternal(s)) / ProtoUtilV1.MULTIPLIER;
    toReporter = (reward * getGovernanceReporterCommissionInternal(s)) / ProtoUtilV1.MULTIPLIER;
    myReward = reward - toBurn - toReporter;
  }

  function getReportingUnstakenAmountInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, coverKey, productKey, incidentDate, account));
    return s.getUintByKey(k);
  }

  function updateUnstakeDetailsInternal(
    IStore s,
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 originalStake,
    uint256 reward,
    uint256 burned,
    uint256 reporterFee
  ) external {
    // Unstake timestamp of the account
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_TS, coverKey, productKey, incidentDate, account));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // Last unstake timestamp
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_TS, coverKey, productKey, incidentDate));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // ---------------------------------------------------------------------

    // Amount unstaken by the account
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, coverKey, productKey, incidentDate, account));
    s.setUintByKey(k, originalStake);

    // Amount unstaken by everyone
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKEN, coverKey, productKey, incidentDate));
    s.addUintByKey(k, originalStake);

    // ---------------------------------------------------------------------

    if (reward > 0) {
      // Reward received by the account
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REWARD, coverKey, productKey, incidentDate, account));
      s.setUintByKey(k, reward);

      // Total reward received
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REWARD, coverKey, productKey, incidentDate));
      s.addUintByKey(k, reward);
    }

    // ---------------------------------------------------------------------

    if (burned > 0) {
      // Total burned
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_BURNED, coverKey, productKey, incidentDate));
      s.addUintByKey(k, burned);
    }

    if (reporterFee > 0) {
      // Total fee paid to the final reporter
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_UNSTAKE_REPORTER_FEE, coverKey, productKey, incidentDate));
      s.addUintByKey(k, reporterFee);
    }
  }

  function _updateProductStatusBeforeResolutionInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private {
    require(incidentDate > 0, "Invalid incident date");

    uint256 yes = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));
    uint256 no = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));

    if (no > yes) {
      s.setStatusInternal(coverKey, productKey, incidentDate, CoverUtilV1.ProductStatus.FalseReporting);
      return;
    }

    s.setStatusInternal(coverKey, productKey, incidentDate, CoverUtilV1.ProductStatus.IncidentHappened);
  }

  /**
   * @dev Adds attestation to an incident report
   *
   * @custom:suppress-address-trust-issue The address `who` can be trusted here because we are not treating it like a contract.
   *
   */
  function addAttestationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    mustNotExceedNpmThreshold(stake);

    // Add individual stake of the reporter
    s.addUintByKey(_getIndividualIncidentOccurredStakeKey(coverKey, productKey, incidentDate, who), stake);

    // All "incident happened" camp witnesses combined
    uint256 currentStake = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));

    // No has reported yet, this is the first report
    if (currentStake == 0) {
      s.setAddressByKey(_getReporterKey(coverKey, productKey), msg.sender);
    }

    s.addUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate), stake);
    _updateProductStatusBeforeResolutionInternal(s, coverKey, productKey, incidentDate);

    s.updateStateAndLiquidity(coverKey);
  }

  function getAttestationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    myStake = s.getUintByKey(_getIndividualIncidentOccurredStakeKey(coverKey, productKey, incidentDate, who));
    totalStake = s.getUintByKey(_getIncidentOccurredStakesKey(coverKey, productKey, incidentDate));
  }

  /**
   * @dev Adds refutation to an incident report
   *
   * @custom:suppress-address-trust-issue The address `who` can be trusted here because we are not treating it like a contract.
   *
   */
  function addRefutationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    mustNotExceedNpmThreshold(stake);

    s.addUintByKey(_getIndividualFalseReportingStakeKey(coverKey, productKey, incidentDate, who), stake);

    uint256 currentStake = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));

    if (currentStake == 0) {
      // The first reporter who disputed
      s.setAddressByKey(_getDisputerKey(coverKey, productKey), msg.sender);
      s.setBoolByKey(getHasDisputeKeyInternal(coverKey, productKey), true);
    }

    s.addUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate), stake);
    _updateProductStatusBeforeResolutionInternal(s, coverKey, productKey, incidentDate);

    s.updateStateAndLiquidity(coverKey);
  }

  function getHasDisputeKeyInternal(bytes32 coverKey, bytes32 productKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_HAS_A_DISPUTE, coverKey, productKey));
  }

  function getRefutationInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    myStake = s.getUintByKey(_getIndividualFalseReportingStakeKey(coverKey, productKey, incidentDate, who));
    totalStake = s.getUintByKey(_getFalseReportingStakesKey(coverKey, productKey, incidentDate));
  }

  function getCoolDownPeriodInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 fromKey = s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD, coverKey);
    uint256 fallbackValue = s.getUintByKey(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD);

    return fromKey > 0 ? fromKey : fallbackValue;
  }

  function getResolutionDeadlineInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  ) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_DEADLINE, coverKey, productKey);
  }

  function addClaimPayoutsInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 claimed
  ) external {
    s.addUintByKey(_getClaimPayoutsKey(coverKey, productKey, incidentDate), claimed);
  }

  function getClaimPayoutsInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    return s.getUintByKey(_getClaimPayoutsKey(coverKey, productKey, incidentDate));
  }

  function getReassurancePayoutInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) public view returns (uint256) {
    return s.getUintByKey(_getReassurancePayoutKey(coverKey, productKey, incidentDate));
  }

  function addReassurancePayoutInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 capitalized
  ) external {
    s.addUintByKey(_getReassurancePayoutKey(coverKey, productKey, incidentDate), capitalized);
  }

  function getReassuranceTransferrableInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (uint256) {
    uint256 reassuranceRate = s.getReassuranceRateInternal(coverKey);
    uint256 available = s.getReassuranceAmountInternal(coverKey);
    uint256 reassurancePaid = getReassurancePayoutInternal(s, coverKey, productKey, incidentDate);

    uint256 totalReassurance = available + reassurancePaid;

    uint256 claimsPaid = getClaimPayoutsInternal(s, coverKey, productKey, incidentDate);

    uint256 principal = claimsPaid <= totalReassurance ? claimsPaid : totalReassurance;
    uint256 transferAmount = (principal * reassuranceRate) / ProtoUtilV1.MULTIPLIER;

    return transferAmount - reassurancePaid;
  }

  function mustNotExceedNpmThreshold(uint256 amount) public pure {
    require(amount <= ProtoUtilV1.MAX_NPM_STAKE * 1 ether, "Please specify a smaller amount");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function mint(uint256 amount) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMember {
  /**
   * @dev Version number of this contract
   */
  function version() external pure returns (bytes32);

  /**
   * @dev Name of this contract
   */
  function getName() external pure returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface ICover is IMember {
  event CoverCreated(bytes32 indexed coverKey, bytes32 info, string tokenName, string tokenSymbol, bool indexed supportsProducts, bool indexed requiresWhitelist);
  event ProductCreated(bytes32 indexed coverKey, bytes32 productKey, bytes32 info, bool requiresWhitelist, uint256[] values);
  event CoverUpdated(bytes32 indexed coverKey, bytes32 info);
  event ProductUpdated(bytes32 indexed coverKey, bytes32 productKey, bytes32 info, uint256[] values);
  event ProductStateUpdated(bytes32 indexed coverKey, bytes32 indexed productKey, address indexed stoppedBy, bool status, string reason);
  event VaultDeployed(bytes32 indexed coverKey, address vault);

  event CoverCreatorWhitelistUpdated(address account, bool status);
  event CoverUserWhitelistUpdated(bytes32 indexed coverKey, bytes32 indexed productKey, address indexed account, bool status);
  event CoverCreationFeeSet(uint256 previous, uint256 current);
  event MinCoverCreationStakeSet(uint256 previous, uint256 current);
  event MinStakeToAddLiquiditySet(uint256 previous, uint256 current);
  event CoverInitialized(address indexed stablecoin, bytes32 withName);

  /**
   * @dev Initializes this contract
   * @param stablecoin Provide the address of the token this cover will be quoted against.
   * @param friendlyName Enter a description or ENS name of your liquidity token.
   *
   */
  function initialize(address stablecoin, bytes32 friendlyName) external;

  /**
   * @dev Adds a new coverage pool or cover contract.
   * To add a new cover, you need to pay cover creation fee
   * and stake minimum amount of NPM in the Vault. <br /> <br />
   *
   * Through the governance portal, projects will be able redeem
   * the full cover fee at a later date. <br /> <br />
   *
   * **Apply for Fee Redemption** <br />
   * https://docs.neptunemutual.com/covers/cover-fee-redemption <br /><br />
   *
   * As the cover creator, you will earn a portion of all cover fees
   * generated in this pool. <br /> <br />
   *
   * Read the documentation to learn more about the fees: <br />
   * https://docs.neptunemutual.com/covers/contract-creators
   *
   * @param coverKey Enter a unique key for this cover
   * @param info IPFS info of the cover contract
   * @param values[0] stakeWithFee Enter the total NPM amount (stake + fee) to transfer to this contract.
   * @param values[1] initialReassuranceAmount **Optional.** Enter the initial amount of
   * @param values[2] minStakeToReport A cover creator can override default min NPM stake to avoid spam reports
   * @param values[3] reportingPeriod The period during when reporting happens.
   * reassurance tokens you'd like to add to this pool.
   * @param values[4] cooldownperiod Enter the cooldown period for governance.
   * @param values[5] claimPeriod Enter the claim period.
   * @param values[6] floor Enter the policy floor rate.
   * @param values[7] ceiling Enter the policy ceiling rate.
   */
  function addCover(
    bytes32 coverKey,
    bytes32 info,
    string calldata tokenName,
    string calldata tokenSymbol,
    bool supportsProducts,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external returns (address);

  function addProduct(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external;

  function updateProduct(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256[] calldata values
  ) external;

  /**
   * @dev Updates the cover contract.
   * This feature is accessible only to the cover owner or protocol owner (governance).
   *
   * @param coverKey Enter the cover key
   * @param info Enter a new IPFS URL to update
   */
  function updateCover(bytes32 coverKey, bytes32 info) external;

  function updateCoverCreatorWhitelist(address account, bool whitelisted) external;

  function updateCoverUsersWhitelist(
    bytes32 coverKey,
    bytes32 productKey,
    address[] calldata accounts,
    bool[] calldata statuses
  ) external;

  function disablePolicy(
    bytes32 coverKey,
    bytes32 productKey,
    bool status,
    string calldata reason
  ) external;

  function checkIfWhitelistedCoverCreator(address account) external view returns (bool);

  function checkIfWhitelistedUser(
    bytes32 coverKey,
    bytes32 productKey,
    address account
  ) external view returns (bool);

  function setCoverCreationFee(uint256 value) external;

  function setMinCoverCreationStake(uint256 value) external;

  function setMinStakeToAddLiquidity(uint256 value) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface IPolicy is IMember {
  event CoverPurchased(
    bytes32 coverKey,
    bytes32 productKey,
    address onBehalfOf,
    address indexed cxToken,
    uint256 fee,
    uint256 platformFee,
    uint256 amountToCover,
    uint256 expiresOn,
    bytes32 indexed referralCode,
    uint256 policyId
  );

  /**
   * @dev Purchase cover for the specified amount. <br /> <br />
   * When you purchase covers, you receive equal amount of cxTokens back.
   * You need the cxTokens to claim the cover when resolution occurs.
   * Each unit of cxTokens are fully redeemable at 1:1 ratio to the given
   * stablecoins (like wxDai, DAI, USDC, or BUSD) based on the chain.
   * @param onBehalfOf Enter an address you would like to send the claim tokens (cxTokens) to.
   * @param coverKey Enter the cover key you wish to purchase the policy for
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin to cover.
   */
  function purchaseCover(
    address onBehalfOf,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover,
    bytes32 referralCode
  ) external returns (address, uint256);

  /**
   * @dev Gets the cover fee info for the given cover key, duration, and amount
   * @param coverKey Enter the cover key
   * @param productKey Enter the product key
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin to cover.
   */
  function getCoverFeeInfo(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover
  )
    external
    view
    returns (
      uint256 fee,
      uint256 utilizationRatio,
      uint256 totalAvailableLiquidity,
      uint256 floor,
      uint256 ceiling,
      uint256 rate
    );

  /**
   * @dev Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] Reassurance amount
   * @param _values[3] Reassurance pool weight
   * @param _values[4] Count of products under this cover
   * @param _values[5] Leverage
   * @param _values[6] Cover product efficiency weight
   */
  function getCoverPoolSummary(bytes32 coverKey, bytes32 productKey) external view returns (uint256[] memory _values);

  function getCxToken(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration
  ) external view returns (address cxToken, uint256 expiryDate);

  function getCxTokenByExpiryDate(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 expiryDate
  ) external view returns (address cxToken);

  /**
   * Gets the sum total of cover commitment that haven't expired yet.
   */
  function getCommitment(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  /**
   * Gets the available liquidity in the pool.
   */
  function getAvailableLiquidity(bytes32 coverKey) external view returns (uint256);

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDate(uint256 today, uint256 coverDuration) external pure returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface IBondPool is IMember {
  event BondPoolSetup(address[] addresses, uint256[] values);
  event BondCreated(address indexed account, uint256 lpTokens, uint256 npmToVest, uint256 unlockDate);
  event BondClaimed(address indexed account, uint256 amount);

  function setup(address[] calldata addresses, uint256[] calldata values) external;

  function createBond(uint256 lpTokens, uint256 minNpmDesired) external;

  function claimBond() external;

  function getNpmMarketPrice() external view returns (uint256);

  function calculateTokensForLp(uint256 lpTokens) external view returns (uint256);

  function getInfo(address forAccount) external view returns (address[] calldata addresses, uint256[] calldata values);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface ICoverStake is IMember {
  event StakeAdded(bytes32 indexed coverKey, address indexed account, uint256 amount);
  event StakeRemoved(bytes32 indexed coverKey, address indexed account, uint256 amount);
  event FeeBurned(bytes32 indexed coverKey, uint256 amount);

  /**
   * @dev Increase the stake of the given cover pool
   * @param coverKey Enter the cover key
   * @param account Enter the account from where the NPM tokens will be transferred
   * @param amount Enter the amount of stake
   * @param fee Enter the fee amount. Note: do not enter the fee if you are directly calling this function.
   */
  function increaseStake(
    bytes32 coverKey,
    address account,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @dev Decreases the stake from the given cover pool
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of stake to decrease
   */
  function decreaseStake(bytes32 coverKey, uint256 amount) external;

  /**
   * @dev Gets the stake of an account for the given cover key
   * @param coverKey Enter the cover key
   * @param account Specify the account to obtain the stake of
   * @return Returns the total stake of the specified account on the given cover key
   */
  function stakeOf(bytes32 coverKey, address account) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface ICxTokenFactory is IMember {
  event CxTokenDeployed(bytes32 indexed coverKey, bytes32 indexed productKey, address cxToken, uint256 expiryDate);

  function deploy(
    bytes32 coverKey,
    bytes32 productKey,
    string calldata tokenName,
    uint256 expiryDate
  ) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface ICoverReassurance is IMember {
  event ReassuranceAdded(bytes32 indexed coverKey, uint256 amount);
  event WeightSet(bytes32 indexed coverKey, uint256 weight);
  event PoolCapitalized(bytes32 indexed coverKey, bytes32 indexed productKey, uint256 indexed incidentDate, uint256 amount);

  /**
   * @dev Adds reassurance to the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount you would like to supply
   */
  function addReassurance(
    bytes32 coverKey,
    address account,
    uint256 amount
  ) external;

  function setWeight(bytes32 coverKey, uint256 weight) external;

  function capitalizePool(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external;

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   * @param coverKey Enter the cover key
   */
  function getReassurance(bytes32 coverKey) external view returns (uint256);
}

/* solhint-disable function-max-lines */
// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IReporter.sol";
import "./IWitness.sol";
import "./IMember.sol";

// solhint-disable-next-line
interface IGovernance is IMember, IReporter, IWitness {

}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface IVaultFactory is IMember {
  event VaultDeployed(bytes32 indexed coverKey, address vault);

  function deploy(
    bytes32 coverKey,
    string calldata name,
    string calldata symbol
  ) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IReporter {
  event Reported(bytes32 indexed coverKey, bytes32 indexed productKey, address reporter, uint256 indexed incidentDate, bytes32 info, uint256 initialStake, uint256 resolutionTimestamp);
  event Disputed(bytes32 indexed coverKey, bytes32 indexed productKey, address reporter, uint256 indexed incidentDate, bytes32 info, uint256 initialStake);

  event ReportingBurnRateSet(uint256 previous, uint256 current);
  event FirstReportingStakeSet(bytes32 coverKey, uint256 previous, uint256 current);
  event ReporterCommissionSet(uint256 previous, uint256 current);

  function report(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256 stake
  ) external;

  function dispute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    bytes32 info,
    uint256 stake
  ) external;

  function getActiveIncidentDate(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  function getAttestation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake);

  function getRefutation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake);

  function getReporter(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (address);

  function getResolutionTimestamp(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  function setFirstReportingStake(bytes32 coverKey, uint256 value) external;

  function getFirstReportingStake(bytes32 coverKey) external view returns (uint256);

  function setReportingBurnRate(uint256 value) external;

  function setReporterCommission(uint256 value) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IWitness {
  event Attested(bytes32 indexed coverKey, bytes32 indexed productKey, address witness, uint256 indexed incidentDate, uint256 stake);
  event Refuted(bytes32 indexed coverKey, bytes32 indexed productKey, address witness, uint256 indexed incidentDate, uint256 stake);

  function attest(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function refute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function getStatus(bytes32 coverKey, bytes32 productKey) external view returns (uint256);

  function getStakes(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view returns (uint256, uint256);

  function getStakesOf(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) external view returns (uint256, uint256);
}

/* solhint-disable var-name-mixedcase, private-vars-leading-underscore, reason-string */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint256 internal constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint256 internal constant SECONDS_PER_HOUR = 60 * 60;
  uint256 internal constant SECONDS_PER_MINUTE = 60;
  int256 internal constant OFFSET19700101 = 2440588;

  uint256 internal constant DOW_MON = 1;
  uint256 internal constant DOW_TUE = 2;
  uint256 internal constant DOW_WED = 3;
  uint256 internal constant DOW_THU = 4;
  uint256 internal constant DOW_FRI = 5;
  uint256 internal constant DOW_SAT = 6;
  uint256 internal constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 _days) {
    require(year >= 1970);
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function timestampFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
  }

  function timestampToDate(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > 0 && day <= daysInMonth) {
        valid = true;
      }
    }
  }

  function isValidDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) {
        valid = true;
      }
    }
  }

  function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
    (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
    leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
    (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  function getYear(uint256 timestamp) internal pure returns (uint256 year) {
    (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
    (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint256 timestamp) internal pure returns (uint256 day) {
    (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
    uint256 secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year += _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    month += _months;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    require(newTimestamp >= timestamp);
  }

  function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    require(newTimestamp >= timestamp);
  }

  function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp >= timestamp);
  }

  function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _seconds;
    require(newTimestamp >= timestamp);
  }

  function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year -= _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 yearMonth = year * 12 + (month - 1) - _months;
    year = yearMonth / 12;
    month = (yearMonth % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }

  function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    require(newTimestamp <= timestamp);
  }

  function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp <= timestamp);
  }

  function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _seconds;
    require(newTimestamp <= timestamp);
  }

  function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _years = toYear - fromYear;
  }

  function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
    require(fromTimestamp <= toTimestamp);
    _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
    require(fromTimestamp <= toTimestamp);
    _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
    require(fromTimestamp <= toTimestamp);
    _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
    require(fromTimestamp <= toTimestamp);
    _seconds = toTimestamp - fromTimestamp;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/ILendingStrategy.sol";
import "./PriceLibV1.sol";
import "./ProtoUtilV1.sol";
import "./RegistryLibV1.sol";

library StrategyLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using RegistryLibV1 for IStore;

  uint256 public constant DEFAULT_LENDING_PERIOD = 180 days;
  uint256 public constant DEFAULT_WITHDRAWAL_WINDOW = 7 days;

  event StrategyAdded(address indexed strategy);
  event RiskPoolingPeriodSet(bytes32 indexed key, uint256 lendingPeriod, uint256 withdrawalWindow);
  event MaxLendingRatioSet(uint256 ratio);

  function _getIsActiveStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, strategyAddress));
  }

  function _getIsDisabledStrategyKey(address strategyAddress) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED, strategyAddress));
  }

  /**
   * @dev Disables a strategy
   *
   * @custom:suppress-address-trust-issue The address `toFind` can be trusted since we are not treating it like a contract.
   *
   */
  function disableStrategyInternal(IStore s, address toFind) external {
    _disableStrategy(s, toFind);

    s.setAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED, toFind);
  }

  /**
   * @dev Deletes a strategy
   *
   * @custom:suppress-address-trust-issue The address `toFind` can be trusted since we are not treating it like a contract.
   *
   */
  function deleteStrategyInternal(IStore s, address toFind) external {
    _deleteStrategy(s, toFind);
  }

  function addStrategiesInternal(IStore s, address[] calldata strategies) external {
    for (uint256 i = 0; i < strategies.length; i++) {
      address strategy = strategies[i];
      _addStrategy(s, strategy);
    }
  }

  function getRiskPoolingPeriodsInternal(IStore s, bytes32 coverKey) external view returns (uint256 lendingPeriod, uint256 withdrawalWindow) {
    lendingPeriod = s.getUintByKey(getLendingPeriodKey(coverKey));
    withdrawalWindow = s.getUintByKey(getWithdrawalWindowKey(coverKey));

    if (lendingPeriod == 0) {
      lendingPeriod = s.getUintByKey(getLendingPeriodKey(0));
      withdrawalWindow = s.getUintByKey(getWithdrawalWindowKey(0));
    }

    lendingPeriod = lendingPeriod == 0 ? DEFAULT_LENDING_PERIOD : lendingPeriod;
    withdrawalWindow = withdrawalWindow == 0 ? DEFAULT_WITHDRAWAL_WINDOW : withdrawalWindow;
  }

  function setRiskPoolingPeriodsInternal(
    IStore s,
    bytes32 coverKey,
    uint256 lendingPeriod,
    uint256 withdrawalWindow
  ) external {
    s.setUintByKey(getLendingPeriodKey(coverKey), lendingPeriod);
    s.setUintByKey(getWithdrawalWindowKey(coverKey), withdrawalWindow);

    emit RiskPoolingPeriodSet(coverKey, lendingPeriod, withdrawalWindow);
  }

  function getLendingPeriodKey(bytes32 coverKey) public pure returns (bytes32) {
    if (coverKey > 0) {
      return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_LENDING_PERIOD, coverKey));
    }

    return ProtoUtilV1.NS_COVER_LIQUIDITY_LENDING_PERIOD;
  }

  function getMaxLendingRatioInternal(IStore s) external view returns (uint256) {
    return s.getUintByKey(getMaxLendingRatioKey());
  }

  function setMaxLendingRatioInternal(IStore s, uint256 ratio) external {
    s.setUintByKey(getMaxLendingRatioKey(), ratio);

    emit MaxLendingRatioSet(ratio);
  }

  function getMaxLendingRatioKey() public pure returns (bytes32) {
    return ProtoUtilV1.NS_COVER_LIQUIDITY_MAX_LENDING_RATIO;
  }

  function getWithdrawalWindowKey(bytes32 coverKey) public pure returns (bytes32) {
    if (coverKey > 0) {
      return keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW, coverKey));
    }

    return ProtoUtilV1.NS_COVER_LIQUIDITY_WITHDRAWAL_WINDOW;
  }

  function _addStrategy(IStore s, address deployedOn) private {
    ILendingStrategy strategy = ILendingStrategy(deployedOn);
    require(strategy.getWeight() <= ProtoUtilV1.MULTIPLIER, "Weight too much");

    s.setBoolByKey(_getIsActiveStrategyKey(deployedOn), true);
    s.setAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE, deployedOn);
    emit StrategyAdded(deployedOn);
  }

  function _disableStrategy(IStore s, address toFind) private {
    bytes32 key = ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE;

    uint256 pos = s.getAddressArrayItemPosition(key, toFind);
    require(pos > 0, "Invalid strategy");

    s.deleteAddressArrayItem(key, toFind);
    s.setBoolByKey(_getIsActiveStrategyKey(toFind), false);
    s.setBoolByKey(_getIsDisabledStrategyKey(toFind), true);
  }

  function _deleteStrategy(IStore s, address toFind) private {
    bytes32 key = ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED;

    uint256 pos = s.getAddressArrayItemPosition(key, toFind);
    require(pos > 0, "Invalid strategy");

    s.deleteAddressArrayItem(key, toFind);
    s.setBoolByKey(_getIsDisabledStrategyKey(toFind), false);
  }

  function getDisabledStrategiesInternal(IStore s) external view returns (address[] memory strategies) {
    return s.getAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_DISABLED);
  }

  function getActiveStrategiesInternal(IStore s) external view returns (address[] memory strategies) {
    return s.getAddressArrayByKey(ProtoUtilV1.NS_LENDING_STRATEGY_ACTIVE);
  }

  function getStrategyOutKey(bytes32 coverKey, address token) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_STRATEGY_OUT, coverKey, token));
  }

  function getSpecificStrategyOutKey(
    bytes32 coverKey,
    bytes32 strategyName,
    address token
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_STRATEGY_OUT, coverKey, strategyName, token));
  }

  function getAmountInStrategies(
    IStore s,
    bytes32 coverKey,
    address token
  ) public view returns (uint256) {
    bytes32 k = getStrategyOutKey(coverKey, token);
    return s.getUintByKey(k);
  }

  function getAmountInStrategy(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    address token
  ) public view returns (uint256) {
    bytes32 k = getSpecificStrategyOutKey(coverKey, strategyName, token);
    return s.getUintByKey(k);
  }

  function preTransferToStrategyInternal(
    IStore s,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external {
    if (s.getStablecoin() == address(token) == false) {
      return;
    }

    _addToStrategyOut(s, coverKey, address(token), amount);
    _addToSpecificStrategyOut(s, coverKey, strategyName, address(token), amount);
  }

  function postReceiveFromStrategyInternal(
    IStore s,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 received
  ) external returns (uint256 income, uint256 loss) {
    if (s.getStablecoin() == address(token) == false) {
      return (income, loss);
    }

    uint256 amountInThisStrategy = getAmountInStrategy(s, coverKey, strategyName, address(token));

    income = received > amountInThisStrategy ? received - amountInThisStrategy : 0;
    loss = received < amountInThisStrategy ? amountInThisStrategy - received : 0;

    _reduceStrategyOut(s, coverKey, address(token), amountInThisStrategy);
    _clearSpecificStrategyOut(s, coverKey, strategyName, address(token));

    _logIncomes(s, coverKey, strategyName, income, loss);
  }

  function _addToStrategyOut(
    IStore s,
    bytes32 coverKey,
    address token,
    uint256 amountToAdd
  ) private {
    bytes32 k = getStrategyOutKey(coverKey, token);
    s.addUintByKey(k, amountToAdd);
  }

  function _reduceStrategyOut(
    IStore s,
    bytes32 coverKey,
    address token,
    uint256 amount
  ) private {
    bytes32 k = getStrategyOutKey(coverKey, token);
    s.subtractUintByKey(k, amount);
  }

  function _addToSpecificStrategyOut(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    address token,
    uint256 amountToAdd
  ) private {
    bytes32 k = getSpecificStrategyOutKey(coverKey, strategyName, token);
    s.addUintByKey(k, amountToAdd);
  }

  function _clearSpecificStrategyOut(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    address token
  ) private {
    bytes32 k = getSpecificStrategyOutKey(coverKey, strategyName, token);
    s.deleteUintByKey(k);
  }

  function _logIncomes(
    IStore s,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 income,
    uint256 loss
  ) private {
    // Overall Income
    s.addUintByKey(ProtoUtilV1.NS_VAULT_LENDING_INCOMES, income);

    // By Cover
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_INCOMES, coverKey)), income);

    // By Cover on This Strategy
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_INCOMES, coverKey, strategyName)), income);

    // Overall Loss
    s.addUintByKey(ProtoUtilV1.NS_VAULT_LENDING_LOSSES, loss);

    // By Cover
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_LOSSES, coverKey)), loss);

    // By Cover on This Strategy
    s.addUintByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_LENDING_LOSSES, coverKey, strategyName)), loss);
  }

  function getStablecoinOwnedByVaultInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    address stablecoin = s.getStablecoin();

    uint256 balance = IERC20(stablecoin).balanceOf(s.getVaultAddress(coverKey));
    uint256 inStrategies = getAmountInStrategies(s, coverKey, stablecoin);

    return balance + inStrategies;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IMember.sol";

pragma solidity ^0.8.0;

interface ILendingStrategy is IMember {
  event LogDeposit(bytes32 indexed name, uint256 counter, uint256 amount, uint256 certificateReceived, uint256 depositTotal, uint256 withdrawalTotal);
  event Deposited(bytes32 indexed key, address indexed onBehalfOf, uint256 stablecoinDeposited, uint256 certificateTokenIssued);
  event LogWithdrawal(bytes32 indexed name, uint256 counter, uint256 stablecoinWithdrawn, uint256 certificateRedeemed, uint256 depositTotal, uint256 withdrawalTotal);
  event Withdrawn(bytes32 indexed key, address indexed sendTo, uint256 stablecoinWithdrawn, uint256 certificateTokenRedeemed);
  event Drained(IERC20 indexed asset, uint256 amount);

  function getKey() external pure returns (bytes32);

  function getWeight() external pure returns (uint256);

  function getDepositAsset() external view returns (IERC20);

  function getDepositCertificate() external view returns (IERC20);

  /**
   * @dev Gets info of this strategy by cover key
   * @param coverKey Enter the cover key
   * @param values[0] deposits Total amount deposited
   * @param values[1] withdrawals Total amount withdrawn
   */
  function getInfo(bytes32 coverKey) external view returns (uint256[] memory values);

  function deposit(bytes32 coverKey, uint256 amount) external returns (uint256 certificateReceived);

  function withdraw(bytes32 coverKey) external returns (uint256 stablecoinWithdrawn);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IPriceOracle.sol";
import "../dependencies/uniswap-v2/IUniswapV2RouterLike.sol";
import "../dependencies/uniswap-v2/IUniswapV2PairLike.sol";
import "../dependencies/uniswap-v2/IUniswapV2FactoryLike.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";

library PriceLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getPriceOracleInternal(IStore s) public view returns (IPriceOracle) {
    return IPriceOracle(s.getNpmPriceOracle());
  }

  function setNpmPrice(IStore s) internal {
    getPriceOracleInternal(s).update();
  }

  function convertNpmLpUnitsToStabelcoin(IStore s, uint256 amountIn) external view returns (uint256) {
    return getPriceOracleInternal(s).consultPair(amountIn);
  }

  function getLastUpdatedOnInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    bytes32 key = getLastUpdateKey(coverKey);
    return s.getUintByKey(key);
  }

  function setLastUpdatedOn(IStore s, bytes32 coverKey) external {
    bytes32 key = getLastUpdateKey(coverKey);
    s.setUintByKey(key, block.timestamp); // solhint-disable-line
  }

  function getLastUpdateKey(bytes32 coverKey) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(ProtoUtilV1.NS_LAST_LIQUIDITY_STATE_UPDATE, coverKey));
  }

  function getNpmPriceInternal(IStore s, uint256 amountIn) external view returns (uint256) {
    return getPriceOracleInternal(s).consult(s.getNpmTokenAddress(), amountIn);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPriceOracle {
  function update() external;

  function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);

  function consultPair(uint256 amountIn) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2RouterLike {
  function factory() external view returns (address);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2PairLike {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function totalSupply() external view returns (uint256);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2FactoryLike {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../dependencies/BokkyPooBahsDateTimeLibrary.sol";
import "../../interfaces/IStore.sol";
import "../../interfaces/ICxTokenFactory.sol";
import "../../interfaces/ICxToken.sol";
import "../../interfaces/IPolicy.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../libraries/RegistryLibV1.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/PolicyHelperV1.sol";
import "../../libraries/RoutineInvokerLibV1.sol";
import "../Recoverable.sol";

/**
 * @title Policy Contract
 * @dev The policy contract enables you to a purchase cover
 */
contract Policy is IPolicy, Recoverable {
  using PolicyHelperV1 for IStore;
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using CoverUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using NTransferUtilV2 for IERC20;
  using ValidationLibV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using StrategyLibV1 for IStore;

  uint256 public lastPolicyId;

  constructor(IStore store, uint256 _lastPolicyId) Recoverable(store) {
    lastPolicyId = _lastPolicyId;
  }

  /**
   * @dev Purchase cover for the specified amount. <br /> <br />
   * When you purchase covers, you receive equal amount of cxTokens back.
   * You need the cxTokens to claim the cover when resolution occurs.
   * Each unit of cxTokens are fully redeemable at 1:1 ratio to the given
   * stablecoins (like wxDai, DAI, USDC, or BUSD) based on the chain.
   *
   * https://docs.neptunemutual.com/covers/purchasing-covers
   *
   * ## Payouts and Incident Date
   *
   * @custom:note Please take note of the following key differences:
   *
   * **Event Date or Observed Date**
   *
   * The date and time the event took place in the real world.
   * It is also referred to as the **event date**.
   *
   * **Incident Date**
   *
   * The incident date is the timestamp at which an event report is submitted.
   * Only if the incident date falls within your coverage period
   * and resolution is in your favor, will you receive a claims payout.
   *
   * **Claim Period**
   *
   * In contrast to most DeFi cover protocols, Neptune Mutual has no waiting period
   * between submitting a claim and receiving payout. You can access the claims feature
   * to immediately receive a payout if a cover is successfully resolved as Incident Happened.
   *
   * Please note that after an incident is resolved, there is usually a 7-day claim period.
   * Any claim submitted after the claim period expiry is automatically denied.
   *
   * @custom:warning Warning:
   *
   * Please thoroughly review the cover rules, cover exclusions,
   * and standard exclusions before purchasing a cover.
   *
   * If the resolution does not go in your favour, you will not be able to
   * submit a claim or receive a payout.
   *
   * By using the this function on our UI, directly via a smart contract call,
   * through an explorer service such as Etherscan,
   * through an SDK and/or API, or in any other way,
   * you are fully aware, fully understand, and accept the risk
   * of getting your claim(s) denied.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   *
   * @param onBehalfOf Enter an address you would like to send the claim tokens (cxTokens) to.
   * @param coverKey Enter the cover key you wish to purchase the policy for
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin to cover.
   */
  function purchaseCover(
    address onBehalfOf,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover,
    bytes32 referralCode
  ) external override nonReentrant returns (address, uint256) {
    // @todo: When the POT system is replaced with NPM tokens in the future, upgrade this contract
    // and uncomment the following line
    // require(IERC20(s.getNpmTokenAddress()).balanceOf(msg.sender) >= 1 ether, "No NPM balance");
    require(coverKey > 0, "Invalid cover key");
    require(onBehalfOf != address(0), "Invalid `onBehalfOf`");
    require(amountToCover > 0, "Enter an amount");
    require(coverDuration > 0 && coverDuration <= 3, "Invalid cover duration");

    s.mustNotBePaused();
    s.mustNotExceedProposalThreshold(amountToCover);
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustHaveNormalProductStatus(coverKey, productKey);
    s.mustNotHavePolicyDisabled(coverKey, productKey);
    s.senderMustBeWhitelistedIfRequired(coverKey, productKey, onBehalfOf);

    lastPolicyId += 1;

    (ICxToken cxToken, uint256 fee, uint256 platformFee) = s.purchaseCoverInternal(onBehalfOf, coverKey, productKey, coverDuration, amountToCover);

    emit CoverPurchased(coverKey, productKey, onBehalfOf, address(cxToken), fee, platformFee, amountToCover, cxToken.expiresOn(), referralCode, lastPolicyId);
    return (address(cxToken), lastPolicyId);
  }

  /**
   * @dev Gets cxToken and its expiry address by the supplied arguments.
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   * @param coverKey Enter the cover key
   * @param productKey Enter the cover key
   * @param coverDuration Enter the cover's policy duration. Valid values: 1-3.
   *
   */
  function getCxToken(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration
  ) external view override returns (address cxToken, uint256 expiryDate) {
    require(coverDuration > 0 && coverDuration <= 3, "Invalid cover duration");

    return s.getCxTokenInternal(coverKey, productKey, coverDuration);
  }

  /**
   * @dev Returns cxToken address by the cover and product key and expiry date.
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   * @param coverKey Enter the cover key
   * @param productKey Enter the cover key
   * @param expiryDate Enter the cxToken's expiry date
   *
   */
  function getCxTokenByExpiryDate(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 expiryDate
  ) external view override returns (address cxToken) {
    return s.getCxTokenByExpiryDateInternal(coverKey, productKey, expiryDate);
  }

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDate(uint256 today, uint256 coverDuration) external pure override returns (uint256) {
    return CoverUtilV1.getExpiryDateInternal(today, coverDuration);
  }

  /**
   * @dev Gets the sum total of cover commitment that has not expired yet.
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   */
  function getCommitment(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    uint256 precision = s.getStablecoinPrecision();
    return s.getActiveLiquidityUnderProtection(coverKey, productKey, precision);
  }

  /**
   * @dev Gets the available liquidity in the pool.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   */
  function getAvailableLiquidity(bytes32 coverKey) external view override returns (uint256) {
    return s.getStablecoinOwnedByVaultInternal(coverKey);
  }

  /**
   * @dev Gets the cover fee info for the given cover key, duration, and amount
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the cover key
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin to cover.
   *
   */
  function getCoverFeeInfo(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover
  )
    external
    view
    override
    returns (
      uint256 fee,
      uint256 utilizationRatio,
      uint256 totalAvailableLiquidity,
      uint256 floor,
      uint256 ceiling,
      uint256 rate
    )
  {
    return s.calculatePolicyFeeInternal(coverKey, productKey, coverDuration, amountToCover);
  }

  /**
   * @dev Returns the values of the given cover key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] Reassurance amount
   * @param _values[3] Reassurance pool weight
   * @param _values[4] Count of products under this cover
   * @param _values[5] Leverage
   * @param _values[6] Cover product efficiency weight
   *
   */
  function getCoverPoolSummary(bytes32 coverKey, bytes32 productKey) external view override returns (uint256[] memory _values) {
    return s.getCoverPoolSummaryInternal(coverKey, productKey);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_POLICY;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./ProtoUtilV1.sol";
import "./CoverUtilV1.sol";
import "./ValidationLibV1.sol";
import "./RoutineInvokerLibV1.sol";
import "../interfaces/ICxToken.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IERC20Detailed.sol";
import "../libraries/NTransferUtilV2.sol";

library PolicyHelperV1 {
  using ProtoUtilV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using ValidationLibV1 for IStore;
  using NTransferUtilV2 for IERC20;
  using RegistryLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  uint256 public constant COVER_LAG_FALLBACK_VALUE = 1 days;

  function calculatePolicyFeeInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover
  )
    public
    view
    returns (
      uint256 fee,
      uint256 utilizationRatio,
      uint256 totalAvailableLiquidity,
      uint256 floor,
      uint256 ceiling,
      uint256 rate
    )
  {
    (floor, ceiling) = getPolicyRatesInternal(s, coverKey);
    (uint256 availableLiquidity, uint256 commitment, uint256 reassuranceFund) = _getCoverPoolAmounts(s, coverKey, productKey);

    require(amountToCover > 0, "Please enter an amount");
    require(coverDuration > 0 && coverDuration <= 3, "Invalid duration");
    require(floor > 0 && ceiling > floor, "Policy rate config error");

    require(availableLiquidity - commitment > amountToCover, "Insufficient fund");

    totalAvailableLiquidity = availableLiquidity + reassuranceFund;
    utilizationRatio = (ProtoUtilV1.MULTIPLIER * (commitment + amountToCover)) / totalAvailableLiquidity;

    rate = utilizationRatio > floor ? utilizationRatio : floor;

    rate = rate + (coverDuration * 100);

    if (rate > ceiling) {
      rate = ceiling;
    }

    uint256 expiryDate = CoverUtilV1.getExpiryDateInternal(block.timestamp, coverDuration); // solhint-disable-line
    uint256 daysCovered = BokkyPooBahsDateTimeLibrary.diffDays(block.timestamp, expiryDate); // solhint-disable-line

    fee = (amountToCover * rate * daysCovered) / (365 * ProtoUtilV1.MULTIPLIER);
  }

  function getPolicyFeeInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover
  ) public view returns (uint256 fee, uint256 platformFee) {
    (fee, , , , , ) = calculatePolicyFeeInternal(s, coverKey, productKey, coverDuration, amountToCover);

    uint256 rate = s.getUintByKey(ProtoUtilV1.NS_COVER_PLATFORM_FEE);
    platformFee = (fee * rate) / ProtoUtilV1.MULTIPLIER;
  }

  function _getCoverPoolAmounts(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey
  )
    private
    view
    returns (
      uint256 availableLiquidity,
      uint256 commitment,
      uint256 reassuranceFund
    )
  {
    uint256[] memory values = s.getCoverPoolSummaryInternal(coverKey, productKey);

    /*
     * values[0] stablecoinOwnedByVault --> The total amount in the cover pool
     * values[1] commitment --> The total commitment amount
     * values[2] reassurance
     * values[3] reassurancePoolWeight
     * values[4] count --> Count of products under this cover
     * values[5] leverage
     * values[6] efficiency --> Cover product efficiency weight
     */

    availableLiquidity = values[0];
    commitment = values[1];

    // (reassurance * reassurancePoolWeight) / multiplier
    reassuranceFund = (values[2] * values[3]) / ProtoUtilV1.MULTIPLIER;

    if (s.supportsProductsInternal(coverKey)) {
      require(values[4] > 0, "Misconfigured or retired product");

      // (stablecoinOwnedByVault * leverage * efficiency) / (count * multiplier)
      availableLiquidity = (values[0] * values[5] * values[6]) / (values[4] * ProtoUtilV1.MULTIPLIER);
    }
  }

  function getPolicyRatesInternal(IStore s, bytes32 coverKey) public view returns (uint256 floor, uint256 ceiling) {
    if (coverKey > 0) {
      floor = s.getUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR, coverKey);
      ceiling = s.getUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING, coverKey);
    }

    if (floor == 0) {
      // Fallback to default values
      floor = s.getUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR);
      ceiling = s.getUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING);
    }
  }

  function getCxTokenInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration
  ) public view returns (address cxToken, uint256 expiryDate) {
    expiryDate = CoverUtilV1.getExpiryDateInternal(block.timestamp, coverDuration); // solhint-disable-line
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_CXTOKEN, coverKey, productKey, expiryDate));

    cxToken = s.getAddress(k);
  }

  /**
   * @dev Gets the instance of cxToken or deploys a new one based on the cover expiry timestamp
   * @param coverKey Enter the cover key
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getCxTokenOrDeployInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration
  ) public returns (ICxToken) {
    (address cxToken, uint256 expiryDate) = getCxTokenInternal(s, coverKey, productKey, coverDuration);

    if (cxToken != address(0)) {
      return ICxToken(cxToken);
    }

    ICxTokenFactory factory = s.getCxTokenFactory();
    cxToken = factory.deploy(coverKey, productKey, _getCxTokenName(coverKey, productKey, expiryDate), expiryDate);

    // @warning: Do not uncomment the following line
    // Reason: cxTokens are no longer protocol members
    // as we will end up with way too many contracts
    // s.getProtocol().addMember(cxToken);
    return ICxToken(cxToken);
  }

  /**
   * @dev Returns month name of a given date
   */
  function _getMonthName(uint256 date) private pure returns (bytes3) {
    bytes3[13] memory m = [bytes3(0), "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
    uint256 month = BokkyPooBahsDateTimeLibrary.getMonth(date);

    return m[month];
  }

  /**
   * @dev Returns cxToken name from the supplied inputs.
   *
   * Format:
   *
   * For basket cover pool product
   * --> cxusd:dex:uni:nov (cxUSD)
   *
   * For standalone cover pool
   * --> cxusd:bal:nov (cxUSD)
   */
  function _getCxTokenName(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 expiry
  ) private pure returns (string memory) {
    bytes3 month = _getMonthName(expiry);

    if (productKey > 0) {
      return string(abi.encodePacked("cxusd:", string(abi.encodePacked(coverKey)), ":", string(abi.encodePacked(productKey)), ":", string(abi.encodePacked(month))));
    }

    return string(abi.encodePacked("cxusd:", string(abi.encodePacked(coverKey)), ":", string(abi.encodePacked(month))));
  }

  /**
   *
   * @dev Purchase cover for the specified amount. <br /> <br />
   * When you purchase covers, you receive equal amount of cxTokens back.
   * You need the cxTokens to claim the cover when resolution occurs.
   * Each unit of cxTokens are fully redeemable at 1:1 ratio to the given
   * stablecoins (like wxDai, DAI, USDC, or BUSD) based on the chain.
   *
   * @custom:suppress-malicious-erc The ERC-20 `stablecoin` can't be manipulated via user input.
   *
   * @param onBehalfOf Enter the address where the claim tokens (cxTokens) should be sent.
   * @param coverKey Enter the cover key you wish to purchase the policy for
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin to cover.
   *
   */
  function purchaseCoverInternal(
    IStore s,
    address onBehalfOf,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 coverDuration,
    uint256 amountToCover
  )
    external
    returns (
      ICxToken cxToken,
      uint256 fee,
      uint256 platformFee
    )
  {
    (fee, platformFee) = getPolicyFeeInternal(s, coverKey, productKey, coverDuration, amountToCover);
    require(fee > 0, "Insufficient fee");
    require(platformFee > 0, "Insufficient platform fee");

    address stablecoin = s.getStablecoin();
    require(stablecoin != address(0), "Cover liquidity uninitialized");

    IERC20(stablecoin).ensureTransferFrom(msg.sender, address(this), fee);
    IERC20(stablecoin).ensureTransfer(s.getVaultAddress(coverKey), fee - platformFee);
    IERC20(stablecoin).ensureTransfer(s.getTreasury(), platformFee);

    uint256 stablecoinPrecision = s.getStablecoinPrecision();
    uint256 toMint = (amountToCover * ProtoUtilV1.CXTOKEN_PRECISION) / stablecoinPrecision;

    cxToken = getCxTokenOrDeployInternal(s, coverKey, productKey, coverDuration);
    cxToken.mint(coverKey, productKey, onBehalfOf, toMint);

    s.updateStateAndLiquidity(coverKey);
  }

  function getCoverageLagInternal(IStore s, bytes32 coverKey) external view returns (uint256) {
    uint256 custom = s.getUintByKeys(ProtoUtilV1.NS_COVERAGE_LAG, coverKey);

    // Custom means set for this exact cover
    if (custom > 0) {
      return custom;
    }

    // Global means set for all covers (without specifying a cover key)
    uint256 global = s.getUintByKey(ProtoUtilV1.NS_COVERAGE_LAG);

    if (global > 0) {
      return global;
    }

    // Fallback means the default option
    return COVER_LAG_FALLBACK_VALUE;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity ^0.8.0;
import "../../interfaces/IStore.sol";
import "../../interfaces/IStakingPools.sol";
import "../../libraries/AccessControlLibV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/StakingPoolCoreLibV1.sol";
import "../../libraries/StakingPoolLibV1.sol";
import "../../core/Recoverable.sol";

abstract contract StakingPoolBase is IStakingPools, Recoverable {
  using AccessControlLibV1 for IStore;
  using ValidationLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using StakingPoolCoreLibV1 for IStore;

  constructor(IStore s) Recoverable(s) {} //solhint-disable-line

  /**
   * @dev Adds or edits the pool by key
   * @param key Enter the key of the pool you want to create or edit
   * @param name Enter a name for this pool
   * @param poolType Specify the pool type: TokenStaking or PODStaking
   * @param addresses[0] stakingToken The token which is staked in this pool
   * @param addresses[1] uniStakingTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param addresses[2] rewardToken The token which is rewarded in this pool
   * @param addresses[3] uniRewardTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param values[0] stakingTarget Specify the target amount in the staking token. You can not exceed the target.
   * @param values[1] maxStake Specify the maximum amount that can be staken at a time.
   * @param values[2] platformFee Enter the platform fee which is deducted on reward and on the reward token
   * @param values[3] rewardPerBlock Specify the amount of reward token awarded per block
   * @param values[4] lockupPeriodInBlocks Enter a lockup period during when the staked tokens can't be withdrawn
   * @param values[5] rewardTokenDeposit Enter the value of reward token you are depositing in this transaction.
   */
  function addOrEditPool(
    bytes32 key,
    string calldata name,
    StakingPoolType poolType,
    address[] calldata addresses,
    uint256[] calldata values
  ) external override nonReentrant {
    // @suppress-zero-value-check The uint values are checked in the function `addOrEditPoolInternal`
    s.mustNotBePaused();
    AccessControlLibV1.mustBeAdmin(s);

    s.addOrEditPoolInternal(key, name, addresses, values);
    emit PoolUpdated(key, name, poolType, addresses[0], addresses[1], addresses[2], addresses[3], values[5], values[1], values[3], values[4], values[2]);
  }

  function closePool(bytes32 key) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeAdmin(s);
    require(s.getBoolByKeys(StakingPoolCoreLibV1.NS_POOL, key), "Unknown Pool");

    s.deleteBoolByKeys(StakingPoolCoreLibV1.NS_POOL, key);
    emit PoolClosed(key, s.getStringByKeys(StakingPoolCoreLibV1.NS_POOL, key));
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_STAKING_POOL;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface IStakingPools is IMember {
  enum StakingPoolType {
    TokenStaking,
    PODStaking
  }

  event PoolUpdated(
    bytes32 indexed key,
    string name,
    StakingPoolType poolType,
    address indexed stakingToken,
    address uniStakingTokenDollarPair,
    address indexed rewardToken,
    address uniRewardTokenDollarPair,
    uint256 rewardTokenDeposit,
    uint256 maxStake,
    uint256 rewardPerBlock,
    uint256 lockupPeriodInBlocks,
    uint256 platformFee
  );

  event PoolClosed(bytes32 indexed key, string name);
  event Deposited(bytes32 indexed key, address indexed account, address indexed token, uint256 amount);
  event Withdrawn(bytes32 indexed key, address indexed account, address indexed token, uint256 amount);
  event RewardsWithdrawn(bytes32 indexed key, address indexed account, address indexed token, uint256 rewards, uint256 platformFee);

  /**
   * @dev Adds or edits the pool by key
   * @param coverKey Enter the key of the pool you want to create or edit
   * @param name Enter a name for this pool
   * @param poolType Specify the pool type: TokenStaking or PODStaking
   * @param addresses[0] stakingToken The token which is staked in this pool
   * @param addresses[1] uniStakingTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param addresses[2] rewardToken The token which is rewarded in this pool
   * @param addresses[3] uniRewardTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param values[0] stakingTarget Specify the target amount in the staking token. You can not exceed the target.
   * @param values[1] maxStake Specify the maximum amount that can be staken at a time.
   * @param values[2] platformFee Enter the platform fee which is deducted on reward and on the reward token
   * @param values[3] rewardPerBlock Specify the amount of reward token awarded per block
   * @param values[4] lockupPeriod Enter a lockup period during when the staked tokens can't be withdrawn
   * @param values[5] rewardTokenDeposit Enter the value of reward token you are depositing in this transaction.
   */
  function addOrEditPool(
    bytes32 coverKey,
    string calldata name,
    StakingPoolType poolType,
    address[] calldata addresses,
    uint256[] calldata values
  ) external;

  function closePool(bytes32 coverKey) external;

  function deposit(bytes32 coverKey, uint256 amount) external;

  function withdraw(bytes32 coverKey, uint256 amount) external;

  function withdrawRewards(bytes32 coverKey) external;

  function calculateRewards(bytes32 coverKey, address account) external view returns (uint256);

  /**
   * @dev Gets the info of a given staking pool by key
   * @param coverKey Provide the staking pool key to fetch info for
   * @param you Specify the address to customize the info for
   * @param name Returns the name of the staking pool
   * @param addresses[0] stakingToken --> Returns the address of the token which is staked in this pool
   * @param addresses[1] stakingTokenStablecoinPair --> Returns the pair address of the staking token and stablecoin
   * @param addresses[2] rewardToken --> Returns the address of the token which is rewarded in this pool
   * @param addresses[3] rewardTokenStablecoinPair --> Returns the pair address of the reward token and stablecoin
   * @param values[0] totalStaked --> Returns the total units of staked tokens
   * @param values[1] target --> Returns the target amount to stake (as staking token unit)
   * @param values[2] maximumStake --> Returns the maximum amount of staking token units that can be added at a time
   * @param values[3] stakeBalance --> Returns the amount of staking token currently locked in the pool
   * @param values[4] cumulativeDeposits --> Returns the total amount tokens which were deposited in this pool
   * @param values[5] rewardPerBlock --> Returns the unit of reward tokens awarded on each block for each unit of staking token
   * @param values[6] platformFee --> Returns the % rate (multipled by ProtoUtilV1.PERCENTAGE_DIVISOR) charged by protocol on rewards
   * @param values[7] lockupPeriodInBlocks --> Returns the period until when a stake can't be withdrawn
   * @param values[8] rewardTokenBalance --> Returns the balance of the reward tokens still left in the pool
   * @param values[9] accountStakeBalance --> Returns your stake amount
   * @param values[10] totalBlockSinceLastReward --> Returns the number of blocks since your last reward
   * @param values[11] rewards --> The amount of reward tokens you have accumulated till this block
   * @param values[12] canWithdrawFromBlockHeight --> The block height after which you are allowed to withdraw your stake
   * @param values[13] lastDepositHeight --> Returns the block number of your last deposit
   * @param values[14] lastRewardHeight --> Returns the block number of your last reward
   */
  function getInfo(bytes32 coverKey, address you)
    external
    view
    returns (
      string memory name,
      address[] memory addresses,
      uint256[] memory values
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";
import "./ProtoUtilV1.sol";
import "./NTransferUtilV2.sol";

library StakingPoolCoreLibV1 {
  using StoreKeyUtil for IStore;
  using NTransferUtilV2 for IERC20;

  bytes32 public constant NS_POOL = "ns:pool:staking";
  bytes32 public constant NS_POOL_NAME = "ns:pool:staking:name";
  bytes32 public constant NS_POOL_LOCKED = "ns:pool:staking:locked";
  bytes32 public constant NS_POOL_LOCKUP_PERIOD_IN_BLOCKS = "ns:pool:staking:lockup:period";
  bytes32 public constant NS_POOL_STAKING_TARGET = "ns:pool:staking:target";
  bytes32 public constant NS_POOL_CUMULATIVE_STAKING_AMOUNT = "ns:pool:staking:cum:amount";
  bytes32 public constant NS_POOL_STAKING_TOKEN = "ns:pool:staking:token";
  bytes32 public constant NS_POOL_STAKING_TOKEN_UNI_STABLECOIN_PAIR = "ns:pool:staking:token:uni:pair";
  bytes32 public constant NS_POOL_REWARD_TOKEN = "ns:pool:reward:token";
  bytes32 public constant NS_POOL_REWARD_TOKEN_UNI_STABLECOIN_PAIR = "ns:pool:reward:token:uni:pair";
  bytes32 public constant NS_POOL_STAKING_TOKEN_BALANCE = "ns:pool:staking:token:balance";
  bytes32 public constant NS_POOL_REWARD_TOKEN_DEPOSITS = "ns:pool:reward:token:deposits";
  bytes32 public constant NS_POOL_REWARD_TOKEN_DISTRIBUTION = "ns:pool:reward:token:distrib";
  bytes32 public constant NS_POOL_MAX_STAKE = "ns:pool:reward:token";
  bytes32 public constant NS_POOL_REWARD_PER_BLOCK = "ns:pool:reward:per:block";
  bytes32 public constant NS_POOL_REWARD_PLATFORM_FEE = "ns:pool:reward:platform:fee";
  bytes32 public constant NS_POOL_REWARD_TOKEN_BALANCE = "ns:pool:reward:token:balance";

  bytes32 public constant NS_POOL_DEPOSIT_HEIGHTS = "ns:pool:deposit:heights";
  bytes32 public constant NS_POOL_REWARD_HEIGHTS = "ns:pool:reward:heights";
  bytes32 public constant NS_POOL_TOTAL_REWARD_GIVEN = "ns:pool:reward:total:given";

  /**
   * @dev Reports the remaining amount of tokens that can be staked in this pool
   */
  function getAvailableToStakeInternal(IStore s, bytes32 key) external view returns (uint256) {
    uint256 totalStaked = getTotalStaked(s, key);
    uint256 target = getTarget(s, key);

    if (totalStaked >= target) {
      return 0;
    }

    return target - totalStaked;
  }

  function getTarget(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(NS_POOL_STAKING_TARGET, key);
  }

  function getRewardPlatformFee(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_REWARD_PLATFORM_FEE, key);
  }

  function getTotalStaked(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(NS_POOL_CUMULATIVE_STAKING_AMOUNT, key);
  }

  function getRewardPerBlock(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_REWARD_PER_BLOCK, key);
  }

  function getLockupPeriodInBlocks(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_LOCKUP_PERIOD_IN_BLOCKS, key);
  }

  function getRewardTokenBalance(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_REWARD_TOKEN_BALANCE, key);
  }

  function getMaximumStakeInternal(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(NS_POOL_MAX_STAKE, key);
  }

  function getStakingTokenAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_STAKING_TOKEN, key);
  }

  function getStakingTokenStablecoinPairAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_STAKING_TOKEN_UNI_STABLECOIN_PAIR, key);
  }

  function getRewardTokenAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_REWARD_TOKEN, key);
  }

  function getRewardTokenStablecoinPairAddressInternal(IStore s, bytes32 key) external view returns (address) {
    return s.getAddressByKeys(NS_POOL_REWARD_TOKEN_UNI_STABLECOIN_PAIR, key);
  }

  function ensureValidStakingPool(IStore s, bytes32 key) external view {
    require(checkIfStakingPoolExists(s, key), "Pool invalid or closed");
  }

  function checkIfStakingPoolExists(IStore s, bytes32 key) public view returns (bool) {
    return s.getBoolByKeys(NS_POOL, key);
  }

  function validateAddOrEditPoolInternal(
    IStore s,
    bytes32 key,
    string calldata name,
    address[] calldata addresses,
    uint256[] calldata values
  ) public view returns (bool) {
    require(key > 0, "Invalid key");

    bool exists = checkIfStakingPoolExists(s, key);

    if (exists == false) {
      require(bytes(name).length > 0, "Invalid name");
      require(addresses[0] != address(0), "Invalid staking token");
      // require(addresses[1] != address(0), "Invalid staking token pair"); // A POD doesn't have any pair with stablecion
      require(addresses[2] != address(0), "Invalid reward token");
      require(addresses[3] != address(0), "Invalid reward token pair");
      require(values[4] > 0, "Provide lockup period in blocks");
      require(values[5] > 0, "Provide reward token allocation");
      require(values[3] > 0, "Provide reward per block");
      require(values[0] > 0, "Please provide staking target");
    }

    return exists;
  }

  /**
   * @dev Adds or edits the pool by key
   *
   * @custom:suppress-malicious-erc Risk tolerable. The ERC-20 `addresses[1]`, `addresses[2]`, and `addresses[3]` can be trusted
   * as these can be supplied only by an admin.
   *
   * @param key Enter the key of the pool you want to create or edit
   * @param name Enter a name for this pool
   * @param addresses[0] stakingToken The token which is staked in this pool
   * @param addresses[1] uniStakingTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param addresses[2] rewardToken The token which is rewarded in this pool
   * @param addresses[3] uniRewardTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param values[0] stakingTarget Specify the target amount in the staking token. You can not exceed the target.
   * @param values[1] maxStake Specify the maximum amount that can be staken at a time.
   * @param values[2] platformFee Enter the platform fee which is deducted on reward and on the reward token
   * @param values[3] rewardPerBlock Specify the amount of reward token awarded per block
   * @param values[4] lockupPeriodInBlocks Enter a lockup period during when the staked tokens can't be withdrawn
   * @param values[5] rewardTokenDeposit Enter the value of reward token you are depositing in this transaction.
   */
  function addOrEditPoolInternal(
    IStore s,
    bytes32 key,
    string calldata name,
    address[] calldata addresses,
    uint256[] calldata values
  ) external {
    // @suppress-zero-value-check The uint values are checked in the function `validateAddOrEditPoolInternal`
    bool poolExists = validateAddOrEditPoolInternal(s, key, name, addresses, values);

    if (poolExists == false) {
      _initializeNewPool(s, key, addresses);
    }

    if (bytes(name).length > 0) {
      s.setStringByKeys(NS_POOL, key, name);
    }

    _updatePoolValues(s, key, values);

    // If `values[5] --> rewardTokenDeposit` is specified, the contract
    // pulls the reward tokens to this contract address
    if (values[5] > 0) {
      IERC20(addresses[2]).ensureTransferFrom(msg.sender, address(this), values[5]);
    }
  }

  /**
   * @dev Updates the values of a staking pool by the given key
   * @param s Provide an instance of the store
   * @param key Enter the key of the pool you want to create or edit
   * @param values[0] stakingTarget Specify the target amount in the staking token. You can not exceed the target.
   * @param values[1] maxStake Specify the maximum amount that can be staken at a time.
   * @param values[2] platformFee Enter the platform fee which is deducted on reward and on the reward token
   * @param values[3] rewardPerBlock Specify the amount of reward token awarded per block
   * @param values[4] lockupPeriodInBlocks Enter a lockup period during when the staked tokens can't be withdrawn
   * @param values[5] rewardTokenDeposit Enter the value of reward token you are depositing in this transaction.
   */
  function _updatePoolValues(
    IStore s,
    bytes32 key,
    uint256[] calldata values
  ) private {
    if (values[0] > 0) {
      s.setUintByKeys(NS_POOL_STAKING_TARGET, key, values[0]);
    }

    if (values[1] > 0) {
      s.setUintByKeys(NS_POOL_MAX_STAKE, key, values[1]);
    }

    if (values[2] > 0) {
      s.setUintByKeys(NS_POOL_REWARD_PLATFORM_FEE, key, values[2]);
    }

    if (values[3] > 0) {
      s.setUintByKeys(NS_POOL_REWARD_PER_BLOCK, key, values[3]);
    }

    if (values[4] > 0) {
      s.setUintByKeys(NS_POOL_LOCKUP_PERIOD_IN_BLOCKS, key, values[4]);
    }

    if (values[5] > 0) {
      s.addUintByKeys(NS_POOL_REWARD_TOKEN_DEPOSITS, key, values[5]);
      s.addUintByKeys(NS_POOL_REWARD_TOKEN_BALANCE, key, values[5]);
    }
  }

  /**
   * @dev Initializes a new pool by the given key. Assumes that the pool does not exist.
   *
   * @custom:warning This feature should not be accessible outside of this library.
   *
   * @param s Provide an instance of the store
   * @param key Enter the key of the pool you want to create or edit
   * @param addresses[0] stakingToken The token which is staked in this pool
   * @param addresses[1] uniStakingTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   * @param addresses[2] rewardToken The token which is rewarded in this pool
   * @param addresses[3] uniRewardTokenDollarPair Enter a Uniswap stablecoin pair address of the staking token
   *
   */
  function _initializeNewPool(
    IStore s,
    bytes32 key,
    address[] calldata addresses
  ) private {
    s.setAddressByKeys(NS_POOL_STAKING_TOKEN, key, addresses[0]);
    s.setAddressByKeys(NS_POOL_STAKING_TOKEN_UNI_STABLECOIN_PAIR, key, addresses[1]);
    s.setAddressByKeys(NS_POOL_REWARD_TOKEN, key, addresses[2]);
    s.setAddressByKeys(NS_POOL_REWARD_TOKEN_UNI_STABLECOIN_PAIR, key, addresses[3]);

    s.setBoolByKeys(NS_POOL, key, true);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";
import "./ProtoUtilV1.sol";
import "./NTransferUtilV2.sol";
import "./ValidationLibV1.sol";
import "./StakingPoolCoreLibV1.sol";

library StakingPoolLibV1 {
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using RegistryLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using StakingPoolCoreLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Gets the info of a given staking pool by key
   * @param s Specify the store instance
   * @param key Provide the staking pool key to fetch info for
   * @param you Specify the address to customize the info for
   * @param name Returns the name of the staking pool
   * @param addresses[0] stakingToken --> Returns the address of the token which is staked in this pool
   * @param addresses[1] stakingTokenStablecoinPair --> Returns the pair address of the staking token and stablecoin
   * @param addresses[2] rewardToken --> Returns the address of the token which is rewarded in this pool
   * @param addresses[3] rewardTokenStablecoinPair --> Returns the pair address of the reward token and stablecoin
   * @param values[0] totalStaked --> Returns the total units of staked tokens
   * @param values[1] target --> Returns the target amount to stake (as staking token unit)
   * @param values[2] maximumStake --> Returns the maximum amount of staking token units that can be added at a time
   * @param values[3] stakeBalance --> Returns the amount of staking token currently locked in the pool
   * @param values[4] cumulativeDeposits --> Returns the total amount tokens which were deposited in this pool
   * @param values[5] rewardPerBlock --> Returns the unit of reward tokens awarded on each block for each unit of staking token
   * @param values[6] platformFee --> Returns the % rate (multipled by ProtoUtilV1.MULTIPLIER) charged by protocol on rewards
   * @param values[7] lockupPeriod --> Returns the period until when a stake can't be withdrawn
   * @param values[8] rewardTokenBalance --> Returns the balance of the reward tokens still left in the pool
   * @param values[9] accountStakeBalance --> Returns your stake amount
   * @param values[10] totalBlockSinceLastReward --> Returns the number of blocks since your last reward
   * @param values[11] rewards --> The amount of reward tokens you have accumulated till this block
   * @param values[12] canWithdrawFromBlockHeight --> The block height after which you are allowed to withdraw your stake
   * @param values[13] lastDepositHeight --> Returns the block number of your last deposit
   * @param values[14] lastRewardHeight --> Returns the block number of your last reward
   */
  function getInfoInternal(
    IStore s,
    bytes32 key,
    address you
  )
    external
    view
    returns (
      string memory name,
      address[] memory addresses,
      uint256[] memory values
    )
  {
    addresses = new address[](4);
    values = new uint256[](15);

    bool valid = s.checkIfStakingPoolExists(key);

    if (valid) {
      name = s.getStringByKeys(StakingPoolCoreLibV1.NS_POOL, key);

      addresses[0] = s.getStakingTokenAddressInternal(key);
      addresses[1] = s.getStakingTokenStablecoinPairAddressInternal(key);
      addresses[2] = s.getRewardTokenAddressInternal(key);
      addresses[3] = s.getRewardTokenStablecoinPairAddressInternal(key);

      values[0] = s.getTotalStaked(key);
      values[1] = s.getTarget(key);
      values[2] = s.getMaximumStakeInternal(key);
      values[3] = getPoolStakeBalanceInternal(s, key);
      values[4] = getPoolCumulativeDeposits(s, key);
      values[5] = s.getRewardPerBlock(key);
      values[6] = s.getRewardPlatformFee(key);
      values[7] = s.getLockupPeriodInBlocks(key);
      values[8] = s.getRewardTokenBalance(key);
      values[9] = getAccountStakingBalanceInternal(s, key, you);
      values[10] = getTotalBlocksSinceLastRewardInternal(s, key, you);
      values[11] = calculateRewardsInternal(s, key, you);
      values[12] = canWithdrawFromBlockHeightInternal(s, key, you);
      values[13] = getLastDepositHeight(s, key, you);
      values[14] = getLastRewardHeight(s, key, you);
    }
  }

  function getPoolStakeBalanceInternal(IStore s, bytes32 key) public view returns (uint256) {
    uint256 totalStake = s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key);
    return totalStake;
  }

  function getPoolCumulativeDeposits(IStore s, bytes32 key) public view returns (uint256) {
    uint256 totalStake = s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_CUMULATIVE_STAKING_AMOUNT, key);
    return totalStake;
  }

  function getAccountStakingBalanceInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    return s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, account);
  }

  function getTotalBlocksSinceLastRewardInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    uint256 from = getLastRewardHeight(s, key, account);

    if (from == 0) {
      return 0;
    }

    return block.number - from;
  }

  function canWithdrawFromBlockHeightInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    uint256 lastDepositHeight = getLastDepositHeight(s, key, account);

    if (lastDepositHeight == 0) {
      return 0;
    }

    uint256 lockupPeriod = s.getLockupPeriodInBlocks(key);

    return lastDepositHeight + lockupPeriod;
  }

  function getLastDepositHeight(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    return s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_DEPOSIT_HEIGHTS, key, account);
  }

  function getLastRewardHeight(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    return s.getUintByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_HEIGHTS, key, account);
  }

  function getStakingPoolRewardTokenBalance(IStore s, bytes32 key) public view returns (uint256) {
    IERC20 rewardToken = IERC20(s.getAddressByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_TOKEN, key));
    address stakingPool = s.getStakingPoolAddress();

    return rewardToken.balanceOf(stakingPool);
  }

  function calculateRewardsInternal(
    IStore s,
    bytes32 key,
    address account
  ) public view returns (uint256) {
    uint256 totalBlocks = getTotalBlocksSinceLastRewardInternal(s, key, account);

    if (totalBlocks == 0) {
      return 0;
    }

    uint256 rewardPerBlock = s.getRewardPerBlock(key);
    uint256 myStake = getAccountStakingBalanceInternal(s, key, account);
    uint256 rewards = (myStake * rewardPerBlock * totalBlocks) / 1 ether;

    uint256 poolBalance = getStakingPoolRewardTokenBalance(s, key);

    return rewards > poolBalance ? poolBalance : rewards;
  }

  /**
   * @dev Withdraws the rewards of the caller (if any or if available).
   *
   *
   * @custom:suppress-malicious-erc The ERC-20 `rewardtoken` can't be manipulated via user input.
   *
   */
  function withdrawRewardsInternal(
    IStore s,
    bytes32 key,
    address account
  )
    public
    returns (
      address rewardToken,
      uint256 rewards,
      uint256 platformFee
    )
  {
    require(s.getRewardPlatformFee(key) <= ProtoUtilV1.MULTIPLIER, "Invalid reward platform fee");
    rewards = calculateRewardsInternal(s, key, account);

    s.setUintByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_HEIGHTS, key, account, block.number);

    if (rewards == 0) {
      return (address(0), 0, 0);
    }

    rewardToken = s.getAddressByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_TOKEN, key);

    // Update (decrease) the balance of reward token
    s.subtractUintByKeys(StakingPoolCoreLibV1.NS_POOL_REWARD_TOKEN_BALANCE, key, rewards);

    // Update total rewards given
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_TOTAL_REWARD_GIVEN, key, account, rewards); // To this account
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_TOTAL_REWARD_GIVEN, key, rewards); // To everyone

    // @suppress-division Checked side effects. If the reward platform fee is zero
    // or a very small number, platform fee becomes zero because of data loss
    platformFee = (rewards * s.getRewardPlatformFee(key)) / ProtoUtilV1.MULTIPLIER;

    // @suppress-subtraction If `getRewardPlatformFee` is 100%, the following can result in zero value.
    if (rewards - platformFee > 0) {
      IERC20(rewardToken).ensureTransfer(msg.sender, rewards - platformFee);
    }

    if (platformFee > 0) {
      IERC20(rewardToken).ensureTransfer(s.getTreasury(), platformFee);
    }
  }

  /**
   * @dev Deposit the specified amount of staking token to the specified pool.
   *
   * @custom:suppress-malicious-erc The ERC-20 `stakingToken` can't be manipulated via user input.
   *
   */
  function depositInternal(
    IStore s,
    bytes32 key,
    uint256 amount
  )
    external
    returns (
      address stakingToken,
      address rewardToken,
      uint256 rewards,
      uint256 rewardsPlatformFee
    )
  {
    require(amount > 0, "Enter an amount");
    require(amount <= s.getMaximumStakeInternal(key), "Stake too high");
    require(amount <= s.getAvailableToStakeInternal(key), "Target achieved or cap exceeded");

    stakingToken = s.getStakingTokenAddressInternal(key);

    // First withdraw your rewards
    (rewardToken, rewards, rewardsPlatformFee) = withdrawRewardsInternal(s, key, msg.sender);

    // Individual state
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, msg.sender, amount);
    s.setUintByKeys(StakingPoolCoreLibV1.NS_POOL_DEPOSIT_HEIGHTS, key, msg.sender, block.number);

    // Global state
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, amount);
    s.addUintByKeys(StakingPoolCoreLibV1.NS_POOL_CUMULATIVE_STAKING_AMOUNT, key, amount);

    IERC20(stakingToken).ensureTransferFrom(msg.sender, address(this), amount);
  }

  /**
   * @dev Withdraw the specified amount of staking token from the specified pool.
   *
   * @custom:suppress-malicious-erc The ERC-20 `stakingToken` can't be manipulated via user input.
   *
   */
  function withdrawInternal(
    IStore s,
    bytes32 key,
    uint256 amount
  )
    external
    returns (
      address stakingToken,
      address rewardToken,
      uint256 rewards,
      uint256 rewardsPlatformFee
    )
  {
    require(amount > 0, "Please specify amount");

    require(getAccountStakingBalanceInternal(s, key, msg.sender) >= amount, "Insufficient balance");
    require(block.number > canWithdrawFromBlockHeightInternal(s, key, msg.sender), "Withdrawal too early");

    stakingToken = s.getStakingTokenAddressInternal(key);

    // First withdraw your rewards
    (rewardToken, rewards, rewardsPlatformFee) = withdrawRewardsInternal(s, key, msg.sender);

    // @suppress-subtraction The maximum amount that can be withdrawn is the staked balance
    // and therefore underflow is not possible.
    // Individual state
    s.subtractUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, msg.sender, amount);

    // Global state
    s.subtractUintByKeys(StakingPoolCoreLibV1.NS_POOL_STAKING_TOKEN_BALANCE, key, amount);

    IERC20(stakingToken).ensureTransfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./StakingPoolBase.sol";

abstract contract StakingPoolReward is StakingPoolBase {
  using ValidationLibV1 for IStore;
  using StakingPoolCoreLibV1 for IStore;
  using StakingPoolLibV1 for IStore;

  constructor(IStore s) StakingPoolBase(s) {} //solhint-disable-line

  function calculateRewards(bytes32 key, address account) external view override returns (uint256) {
    return s.calculateRewardsInternal(key, account);
  }

  /**
   * @dev Withdraw your staking reward. Ensure that you preiodically call this function
   * or else you risk receiving no rewards as a result of token depletion in the reward pool.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   */
  function withdrawRewards(bytes32 key) external override nonReentrant {
    s.mustNotBePaused();
    s.ensureValidStakingPool(key);

    (address rewardToken, uint256 rewards, uint256 platformFee) = s.withdrawRewardsInternal(key, msg.sender);

    if (rewards > 0) {
      emit RewardsWithdrawn(key, msg.sender, rewardToken, rewards, platformFee);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./StakingPoolReward.sol";

abstract contract StakingPoolInfo is StakingPoolReward {
  using StakingPoolCoreLibV1 for IStore;
  using StakingPoolLibV1 for IStore;

  constructor(IStore s) StakingPoolReward(s) {} //solhint-disable-line

  /**
   * @dev Gets the info of a given staking pool by key
   * @param key Provide the staking pool key to fetch info for
   * @param you Specify the address to customize the info for
   * @param name Returns the name of the staking pool
   * @param addresses[0] stakingToken --> Returns the address of the token which is staked in this pool
   * @param addresses[1] stakingTokenStablecoinPair --> Returns the pair address of the staking token and stablecoin
   * @param addresses[2] rewardToken --> Returns the address of the token which is rewarded in this pool
   * @param addresses[3] rewardTokenStablecoinPair --> Returns the pair address of the reward token and stablecoin
   * @param values[0] totalStaked --> Returns the total units of staked tokens
   * @param values[1] target --> Returns the target amount to stake (as staking token unit)
   * @param values[2] maximumStake --> Returns the maximum amount of staking token units that can be added at a time
   * @param values[3] stakeBalance --> Returns the amount of staking token currently locked in the pool
   * @param values[4] cumulativeDeposits --> Returns the total amount tokens which were deposited in this pool
   * @param values[5] rewardPerBlock --> Returns the unit of reward tokens awarded on each block for each unit of staking token
   * @param values[6] platformFee --> Returns the % rate (multipled by ProtoUtilV1.MULTIPLIER) charged by protocol on rewards
   * @param values[7] lockupPeriod --> Returns the period until when a stake can't be withdrawn
   * @param values[8] rewardTokenBalance --> Returns the balance of the reward tokens still left in the pool
   * @param values[9] accountStakeBalance --> Returns your stake amount
   * @param values[10] totalBlockSinceLastReward --> Returns the number of blocks since your last reward
   * @param values[11] rewards --> The amount of reward tokens you have accumulated till this block
   * @param values[12] canWithdrawFromBlockHeight --> The block height after which you are allowed to withdraw your stake
   * @param values[13] lastDepositHeight --> Returns the block number of your last deposit
   * @param values[14] lastRewardHeight --> Returns the block number of your last reward
   */
  function getInfo(bytes32 key, address you)
    external
    view
    override
    returns (
      string memory name,
      address[] memory addresses,
      uint256[] memory values
    )
  {
    return s.getInfoInternal(key, you);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./StakingPoolInfo.sol";

contract StakingPools is StakingPoolInfo {
  using ValidationLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using StakingPoolCoreLibV1 for IStore;
  using StakingPoolLibV1 for IStore;

  constructor(IStore s) StakingPoolInfo(s) {} //solhint-disable-line

  /**
   * @dev Deposit your desired amount of tokens to the specified staking pool.
   * When you deposit, you receive rewards if tokens are still available in the reward pool.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   */
  function deposit(bytes32 key, uint256 amount) external override nonReentrant {
    s.mustNotBePaused();
    s.ensureValidStakingPool(key);

    (address stakingToken, address rewardToken, uint256 rewards, uint256 rewardsPlatformFee) = s.depositInternal(key, amount);
    emit Deposited(key, msg.sender, stakingToken, amount);

    if (rewards > 0) {
      emit RewardsWithdrawn(key, msg.sender, rewardToken, rewards, rewardsPlatformFee);
    }
  }

  /**
   * @dev Withdraw your desired amount of tokens from the staking pool.
   * When you withdraw, you receive rewards if tokens are still available in the reward pool.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   */
  function withdraw(bytes32 key, uint256 amount) external override nonReentrant {
    s.mustNotBePaused();
    s.ensureValidStakingPool(key);

    (address stakingToken, address rewardToken, uint256 rewards, uint256 rewardsPlatformFee) = s.withdrawInternal(key, amount);
    emit Withdrawn(key, msg.sender, stakingToken, amount);

    if (rewards > 0) {
      emit RewardsWithdrawn(key, msg.sender, rewardToken, rewards, rewardsPlatformFee);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ValidationLibV1.sol";
import "./NTransferUtilV2.sol";
import "./AccessControlLibV1.sol";
import "./PriceLibV1.sol";
import "../interfaces/IProtocol.sol";
import "../interfaces/IPausable.sol";

library BondPoolLibV1 {
  using AccessControlLibV1 for IStore;
  using NTransferUtilV2 for IERC20;
  using PriceLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;

  bytes32 public constant NS_BOND_TO_CLAIM = "ns:pool:bond:to:claim";
  bytes32 public constant NS_BOND_CONTRIBUTION = "ns:pool:bond:contribution";
  bytes32 public constant NS_BOND_LP_TOKEN = "ns:pool:bond:lq:pair:token";
  bytes32 public constant NS_LQ_TREASURY = "ns:pool:bond:lq:treasury";
  bytes32 public constant NS_BOND_DISCOUNT_RATE = "ns:pool:bond:discount";
  bytes32 public constant NS_BOND_MAX_UNIT = "ns:pool:bond:max:unit";
  bytes32 public constant NS_BOND_VESTING_TERM = "ns:pool:bond:vesting:term";
  bytes32 public constant NS_BOND_UNLOCK_DATE = "ns:pool:bond:unlock:date";
  bytes32 public constant NS_BOND_TOTAL_NPM_ALLOCATED = "ns:pool:bond:total:npm:alloc";
  bytes32 public constant NS_BOND_TOTAL_NPM_DISTRIBUTED = "ns:pool:bond:total:npm:distrib";

  function calculateTokensForLpInternal(IStore s, uint256 lpTokens) public view returns (uint256) {
    uint256 dollarValue = s.convertNpmLpUnitsToStabelcoin(lpTokens);

    uint256 npmPrice = s.getNpmPriceInternal(1 ether);
    uint256 discount = _getDiscountRate(s);
    uint256 discountedNpmPrice = (npmPrice * (ProtoUtilV1.MULTIPLIER - discount)) / ProtoUtilV1.MULTIPLIER;

    uint256 npmForContribution = (dollarValue * 1 ether) / discountedNpmPrice;

    return npmForContribution;
  }

  /**
   * @dev Gets the bond pool information
   * @param s Provide a store instance
   * @param addresses[0] lpToken -> Returns the LP token address
   * @param values[0] marketPrice -> Returns the market price of NPM token
   * @param values[1] discountRate -> Returns the discount rate for bonding
   * @param values[2] vestingTerm -> Returns the bond vesting period
   * @param values[3] maxBond -> Returns maximum amount of bond. To clarify, this means the final NPM amount received by bonders after vesting period.
   * @param values[4] totalNpmAllocated -> Returns the total amount of NPM tokens allocated for bonding.
   * @param values[5] totalNpmDistributed -> Returns the total amount of NPM tokens that have been distributed under bond.
   * @param values[6] npmAvailable -> Returns the available NPM tokens that can be still bonded.
   * @param values[7] bondContribution --> total lp tokens contributed by you
   * @param values[8] claimable --> your total claimable NPM tokens at the end of the vesting period or "unlock date"
   * @param values[9] unlockDate --> your vesting period end or "unlock date"
   */
  function getBondPoolInfoInternal(IStore s, address you) external view returns (address[] memory addresses, uint256[] memory values) {
    addresses = new address[](1);
    values = new uint256[](10);

    addresses[0] = _getLpTokenAddress(s);

    values[0] = s.getNpmPriceInternal(1 ether); // marketPrice
    values[1] = _getDiscountRate(s); // discountRate
    values[2] = _getVestingTerm(s); // vestingTerm
    values[3] = _getMaxBondInUnit(s); // maxBond
    values[4] = _getTotalNpmAllocated(s); // totalNpmAllocated
    values[5] = _getTotalNpmDistributed(s); // totalNpmDistributed
    values[6] = IERC20(s.npmToken()).balanceOf(address(this)); // npmAvailable

    values[7] = _getYourBondContribution(s, you); // bondContribution --> total lp tokens contributed by you
    values[8] = _getYourBondClaimable(s, you); // claimable --> your total claimable NPM tokens at the end of the vesting period or "unlock date"
    values[9] = _getYourBondUnlockDate(s, you); // unlockDate --> your vesting period end or "unlock date"
  }

  function _getLpTokenAddress(IStore s) private view returns (address) {
    return s.getAddressByKey(BondPoolLibV1.NS_BOND_LP_TOKEN);
  }

  function _getYourBondContribution(IStore s, address you) private view returns (uint256) {
    return s.getUintByKey(keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_CONTRIBUTION, you)));
  }

  function _getYourBondClaimable(IStore s, address you) private view returns (uint256) {
    return s.getUintByKey(keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_TO_CLAIM, you)));
  }

  function _getYourBondUnlockDate(IStore s, address you) private view returns (uint256) {
    return s.getUintByKey(keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_UNLOCK_DATE, you)));
  }

  function _getDiscountRate(IStore s) private view returns (uint256) {
    return s.getUintByKey(NS_BOND_DISCOUNT_RATE);
  }

  function _getVestingTerm(IStore s) private view returns (uint256) {
    return s.getUintByKey(NS_BOND_VESTING_TERM);
  }

  function _getMaxBondInUnit(IStore s) private view returns (uint256) {
    return s.getUintByKey(NS_BOND_MAX_UNIT);
  }

  function _getTotalNpmAllocated(IStore s) private view returns (uint256) {
    return s.getUintByKey(NS_BOND_TOTAL_NPM_ALLOCATED);
  }

  function _getTotalNpmDistributed(IStore s) private view returns (uint256) {
    return s.getUintByKey(NS_BOND_TOTAL_NPM_DISTRIBUTED);
  }

  /**
   * @dev Create a new NPM/DAI LP token bond
   * @custom:suppress-malicious-erc The token `BondPoolLibV1.NS_BOND_LP_TOKEN` can't be manipulated via user input
   */
  function createBondInternal(
    IStore s,
    uint256 lpTokens,
    uint256 minNpmDesired
  ) external returns (uint256[] memory values) {
    s.mustNotBePaused();

    values = new uint256[](2);
    values[0] = calculateTokensForLpInternal(s, lpTokens); // npmToVest

    require(values[0] <= _getMaxBondInUnit(s), "Bond too big");
    require(values[0] >= minNpmDesired, "Min bond `minNpmDesired` failed");
    require(_getNpmBalance(s) >= values[0] + _getBondCommitment(s), "NPM balance insufficient to bond");

    // Pull the tokens from the requester's account
    IERC20(s.getAddressByKey(BondPoolLibV1.NS_BOND_LP_TOKEN)).ensureTransferFrom(msg.sender, s.getAddressByKey(BondPoolLibV1.NS_LQ_TREASURY), lpTokens);

    // Commitment: Total NPM to reserve for bond claims
    s.addUintByKey(BondPoolLibV1.NS_BOND_TO_CLAIM, values[0]);

    // Your bond to claim later
    bytes32 k = keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_TO_CLAIM, msg.sender));
    s.addUintByKey(k, values[0]);

    // Amount contributed
    k = keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_CONTRIBUTION, msg.sender));
    s.addUintByKey(k, lpTokens);

    // unlock date
    values[1] = block.timestamp + _getVestingTerm(s); // solhint-disable-line

    // Unlock date
    k = keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_UNLOCK_DATE, msg.sender));
    s.setUintByKey(k, values[1]);
  }

  function _getNpmBalance(IStore s) private view returns (uint256) {
    return IERC20(s.npmToken()).balanceOf(address(this));
  }

  function _getBondCommitment(IStore s) private view returns (uint256) {
    return s.getUintByKey(BondPoolLibV1.NS_BOND_TO_CLAIM);
  }

  /**
   * @dev Enables the caller to claim their bond after the lockup period.
   *
   * @custom:suppress-malicious-erc The token `s.npmToken()` can't be manipulated via user input
   *
   */
  function claimBondInternal(IStore s) external returns (uint256[] memory values) {
    s.mustNotBePaused();

    values = new uint256[](1);

    values[0] = _getYourBondClaimable(s, msg.sender); // npmToTransfer

    // Commitment: Reduce NPM reserved for claims
    s.subtractUintByKey(BondPoolLibV1.NS_BOND_TO_CLAIM, values[0]);

    // Clear the claim amount
    s.deleteUintByKey(keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_TO_CLAIM, msg.sender)));

    uint256 unlocksOn = _getYourBondUnlockDate(s, msg.sender);

    // Clear the unlock date
    s.deleteUintByKey(keccak256(abi.encodePacked(BondPoolLibV1.NS_BOND_UNLOCK_DATE, msg.sender)));

    require(block.timestamp >= unlocksOn, "Still vesting"); // solhint-disable-line
    require(values[0] > 0, "Nothing to claim");

    s.addUintByKey(BondPoolLibV1.NS_BOND_TOTAL_NPM_DISTRIBUTED, values[0]);
    IERC20(s.npmToken()).ensureTransfer(msg.sender, values[0]);
  }

  /**
   * @dev Sets up the bond pool
   *
   * @custom:suppress-malicious-erc The token `s.npmToken()` can't be manipulated via user input
   *
   * @param s Provide an instance of the store
   * @param addresses[0] - LP Token Address
   * @param addresses[1] - Treasury Address
   * @param values[0] - Bond Discount Rate
   * @param values[1] - Maximum Bond Amount
   * @param values[2] - Vesting Term
   * @param values[3] - NPM to Top Up Now
   */
  function setupBondPoolInternal(
    IStore s,
    address[] calldata addresses,
    uint256[] calldata values
  ) external {
    if (addresses[0] != address(0)) {
      s.setAddressByKey(BondPoolLibV1.NS_BOND_LP_TOKEN, addresses[0]);
    }

    if (addresses[1] != address(0)) {
      s.setAddressByKey(BondPoolLibV1.NS_LQ_TREASURY, addresses[1]);
    }

    if (values[0] > 0) {
      s.setUintByKey(BondPoolLibV1.NS_BOND_DISCOUNT_RATE, values[0]);
    }

    if (values[1] > 0) {
      s.setUintByKey(BondPoolLibV1.NS_BOND_MAX_UNIT, values[1]);
    }

    if (values[2] > 0) {
      s.setUintByKey(BondPoolLibV1.NS_BOND_VESTING_TERM, values[2]);
    }

    if (values[3] > 0) {
      IERC20(s.npmToken()).ensureTransferFrom(msg.sender, address(this), values[3]);
      s.addUintByKey(BondPoolLibV1.NS_BOND_TOTAL_NPM_ALLOCATED, values[3]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../interfaces/IStore.sol";
import "../../interfaces/IBondPool.sol";
import "../../libraries/BondPoolLibV1.sol";
import "../../core/Recoverable.sol";

abstract contract BondPoolBase is IBondPool, Recoverable {
  using AccessControlLibV1 for IStore;
  using BondPoolLibV1 for IStore;
  using PriceLibV1 for IStore;
  using ValidationLibV1 for IStore;

  constructor(IStore s) Recoverable(s) {} //solhint-disable-line

  function getNpmMarketPrice() external view override returns (uint256) {
    return s.getNpmPriceInternal(1 ether);
  }

  function calculateTokensForLp(uint256 lpTokens) external view override returns (uint256) {
    return s.calculateTokensForLpInternal(lpTokens);
  }

  /**
   * @dev Gets the bond pool information
   * @param addresses[0] lpToken -> Returns the LP token address
   * @param values[0] marketPrice -> Returns the market price of NPM token
   * @param values[1] discountRate -> Returns the discount rate for bonding
   * @param values[2] vestingTerm -> Returns the bond vesting period
   * @param values[3] maxBond -> Returns maximum amount of bond. To clarify, this means the final NPM amount received by bonders after vesting period.
   * @param values[4] totalNpmAllocated -> Returns the total amount of NPM tokens allocated for bonding.
   * @param values[5] totalNpmDistributed -> Returns the total amount of NPM tokens that have been distributed under bond.
   * @param values[6] npmAvailable -> Returns the available NPM tokens that can be still bonded.
   * @param values[7] bondContribution --> total lp tokens contributed by you
   * @param values[8] claimable --> your total claimable NPM tokens at the end of the vesting period or "unlock date"
   * @param values[9] unlockDate --> your vesting period end or "unlock date"
   */
  function getInfo(address forAccount) external view override returns (address[] memory addresses, uint256[] memory values) {
    return s.getBondPoolInfoInternal(forAccount);
  }

  /**
   * @dev Sets up the bond pool
   * @param addresses[0] - LP Token Address
   * @param addresses[1] - Treasury Address
   * @param values[0] - Bond Discount Rate
   * @param values[1] - Maximum Bond Amount
   * @param values[2] - Vesting Term
   * @param values[3] - NPM to Top Up Now
   */
  function setup(address[] calldata addresses, uint256[] calldata values) external override nonReentrant {
    // @suppress-zero-value-check The uint values are checked in the function `setupBondPoolInternal`
    s.mustNotBePaused();
    AccessControlLibV1.mustBeAdmin(s);

    s.setupBondPoolInternal(addresses, values);

    emit BondPoolSetup(addresses, values);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_BOND_POOL;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";

interface IPolicyAdmin is IMember {
  event PolicyRateSet(uint256 floor, uint256 ceiling);
  event CoverPolicyRateSet(bytes32 indexed coverKey, uint256 floor, uint256 ceiling);
  event CoverageLagSet(bytes32 indexed coverKey, uint256 window);

  /**
   * @dev Sets policy rates. This feature is only accessible by owner or protocol owner.
   * @param floor The lowest cover fee rate fallback
   * @param ceiling The highest cover fee rate fallback
   */
  function setPolicyRates(uint256 floor, uint256 ceiling) external;

  /**
   * @dev Sets policy rates for the given cover key. This feature is only accessible by owner or protocol owner.
   * @param floor The lowest cover fee rate for this cover
   * @param ceiling The highest cover fee rate for this cover
   */
  function setPolicyRatesByKey(
    bytes32 coverKey,
    uint256 floor,
    uint256 ceiling
  ) external;

  /**
   * @dev Gets the cover policy rates for the given cover key
   */
  function getPolicyRates(bytes32 coverKey) external view returns (uint256 floor, uint256 ceiling);

  function setCoverageLag(bytes32 coverKey, uint256 window) external;

  function getCoverageLag(bytes32 coverKey) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IStore.sol";
import "../../interfaces/IPolicyAdmin.sol";
import "../../libraries/PolicyHelperV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../Recoverable.sol";

/**
 * @title Policy Admin Contract
 * @dev The policy admin contract enables the owner (governance)
 * to set the policy rate and fee info.
 */
contract PolicyAdmin is IPolicyAdmin, Recoverable {
  using ProtoUtilV1 for bytes;
  using PolicyHelperV1 for IStore;
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using NTransferUtilV2 for IERC20;
  using RoutineInvokerLibV1 for IStore;

  /**
   * @dev Constructs this contract
   * @param store Provide the store contract instance
   */
  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Sets policy rates. This feature is only accessible by cover manager.
   * @param floor The lowest cover fee rate fallback
   * @param ceiling The highest cover fee rate fallback
   */
  function setPolicyRates(uint256 floor, uint256 ceiling) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    require(floor > 0, "Please specify floor");
    require(ceiling > floor, "Invalid ceiling");

    s.setUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR, floor);
    s.setUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING, ceiling);

    s.updateStateAndLiquidity(0);

    emit PolicyRateSet(floor, ceiling);
  }

  /**
   * @dev Sets policy rates for the given cover key. This feature is only accessible by cover manager.
   * @param floor The lowest cover fee rate for this cover
   * @param ceiling The highest cover fee rate for this cover
   */
  function setPolicyRatesByKey(
    bytes32 coverKey,
    uint256 floor,
    uint256 ceiling
  ) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);
    s.mustBeValidCoverKey(coverKey);

    require(floor > 0, "Please specify floor");
    require(ceiling > 0, "Invalid ceiling");

    s.setUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR, coverKey, floor);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING, coverKey, ceiling);

    s.updateStateAndLiquidity(coverKey);

    emit CoverPolicyRateSet(coverKey, floor, ceiling);
  }

  /**
   * @dev The coverage of a policy begins at the EOD timestamp
   * of the policy purchase date plus the coverage lag.
   *
   * Coverage lag is a specified time period that can be set globally
   * or on a per-cover basis to delay the start of coverage.
   *
   * This allows us to defend against time-based opportunistic attacks,
   * which occur when an attacker purchases coverage after
   * an incident has occurred but before the incident has been reported.
   */
  function setCoverageLag(bytes32 coverKey, uint256 window) external override {
    require(window >= 1 days, "Enter at least 1 day");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    if (coverKey > 0) {
      s.mustBeValidCoverKey(coverKey);
      s.setUintByKeys(ProtoUtilV1.NS_COVERAGE_LAG, coverKey, window);

      emit CoverageLagSet(coverKey, window);
      return;
    }

    s.setUintByKey(ProtoUtilV1.NS_COVERAGE_LAG, window);
    emit CoverageLagSet(coverKey, window);
  }

  /**
   * @dev Gets the cover policy rates for the given cover key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   */
  function getPolicyRates(bytes32 coverKey) external view override returns (uint256 floor, uint256 ceiling) {
    return s.getPolicyRatesInternal(coverKey);
  }

  /**
   * @dev Gets the policy lag for the given cover key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   */
  function getCoverageLag(bytes32 coverKey) external view override returns (uint256) {
    return s.getCoverageLagInternal(coverKey);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_POLICY_ADMIN;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/VaultLibV1.sol";
import "../../libraries/StrategyLibV1.sol";

contract MockVaultLibUser {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using StrategyLibV1 for IStore;
  using VaultLibV1 for IStore;

  IStore public s;

  constructor(IStore store) {
    s = store;
  }

  function setFlashLoanStatus(bytes32 coverKey, bool status) external {
    s.setBoolByKeys(ProtoUtilV1.NS_COVER_HAS_FLASH_LOAN, coverKey, status);
  }

  function getFlashLoanStatus(bytes32 coverKey) external view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_COVER_HAS_FLASH_LOAN, coverKey);
  }

  function preAddLiquidityInternal(
    bytes32 coverKey,
    address pod,
    address account,
    uint256 amount,
    uint256 npmStakeToAdd
  ) external {
    s.preAddLiquidityInternal(coverKey, pod, account, amount, npmStakeToAdd);
  }

  function preRemoveLiquidityInternal(
    bytes32 coverKey,
    address pod,
    address account,
    uint256 podsToRedeem,
    uint256 npmStakeToRemove,
    bool exit
  ) external returns (address stablecoin, uint256 releaseAmount) {
    (stablecoin, releaseAmount) = s.preRemoveLiquidityInternal(coverKey, pod, account, podsToRedeem, npmStakeToRemove, exit);
    require(releaseAmount == 0, "Release amount should be zero");
  }

  function setAmountInStrategies(
    bytes32 coverKey,
    address stablecoin,
    uint256 amount
  ) external {
    // getStrategyOutKey
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_VAULT_STRATEGY_OUT, coverKey, stablecoin));

    s.setUintByKey(k, amount);
  }

  function mustHaveNoBalanceInStrategies(bytes32 coverKey, address stablecoin) external view {
    s.mustHaveNoBalanceInStrategies(coverKey, stablecoin);
  }

  function getMaxFlashLoanInternal(bytes32 coverKey, address token) external view returns (uint256) {
    return s.getMaxFlashLoanInternal(coverKey, token);
  }

  function setAddressByKey(bytes32 key, address value) external {
    s.setAddressByKey(key, value);
  }

  function getAddressByKey(bytes32 key) external view returns (address) {
    return s.getAddressByKey(key);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/interfaces/IERC3156FlashLender.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./CoverUtilV1.sol";
import "./RoutineInvokerLibV1.sol";
import "./StrategyLibV1.sol";
import "./ValidationLibV1.sol";

library VaultLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using RegistryLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using StrategyLibV1 for IStore;

  // Before withdrawing, wait for the following number of blocks after deposit
  uint256 public constant WITHDRAWAL_HEIGHT_OFFSET = 1;

  /**
   * @dev Calculates the amount of PODS to mint for the given amount of liquidity to transfer
   */
  function calculatePodsInternal(
    IStore s,
    bytes32 coverKey,
    address pod,
    uint256 liquidityToAdd
  ) public view returns (uint256) {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER_HAS_FLASH_LOAN, coverKey) == false, "On flash loan, please try again");

    uint256 balance = s.getStablecoinOwnedByVaultInternal(coverKey);
    uint256 podSupply = IERC20(pod).totalSupply();
    uint256 stablecoinPrecision = s.getStablecoinPrecision();

    // This smart contract contains stablecoins without liquidity provider contribution.
    // This can happen if someone wants to create a nuisance by sending stablecoin
    // to this contract immediately after deployment.
    if (podSupply == 0 && balance > 0) {
      revert("Liquidity/POD mismatch");
    }

    if (balance > 0) {
      return (podSupply * liquidityToAdd) / balance;
    }

    return (liquidityToAdd * ProtoUtilV1.POD_PRECISION) / stablecoinPrecision;
  }

  /**
   * @dev Calculates the amount of liquidity to transfer for the given amount of PODs to burn.
   *
   * The Vault contract lends out liquidity to external protocols to maximize reward
   * regularly. But it also withdraws periodically to receive back the loaned amount
   * with interest. In other words, the Vault contract continuously supplies
   * available liquidity to lending protocols and withdraws during a fixed interval.
   * For example, supply during `180-day lending period` and allow withdrawals
   * during `7-day withdrawal period`.
   */
  function calculateLiquidityInternal(
    IStore s,
    bytes32 coverKey,
    address pod,
    uint256 podsToBurn
  ) public view returns (uint256) {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER_HAS_FLASH_LOAN, coverKey) == false, "On flash loan, please try again");

    uint256 balance = s.getStablecoinOwnedByVaultInternal(coverKey);
    uint256 podSupply = IERC20(pod).totalSupply();

    return (balance * podsToBurn) / podSupply;
  }

  /**
   * @dev Gets information of a given vault by the cover key
   * @param s Provide a store instance
   * @param coverKey Specify cover key to obtain the info of.
   * @param pod Provide the address of the POD
   * @param you The address for which the info will be customized
   * @param values[0] totalPods --> Total PODs in existence
   * @param values[1] balance --> Stablecoins held in the vault
   * @param values[2] extendedBalance --> Stablecoins lent outside of the protocol
   * @param values[3] totalReassurance -- > Total reassurance for this cover
   * @param values[4] myPodBalance --> Your POD Balance
   * @param values[5] myShare --> My share of the liquidity pool (in stablecoin)
   * @param values[6] withdrawalOpen --> The timestamp when withdrawals are opened
   * @param values[7] withdrawalClose --> The timestamp when withdrawals are closed again
   */
  function getInfoInternal(
    IStore s,
    bytes32 coverKey,
    address pod,
    address you
  ) external view returns (uint256[] memory values) {
    values = new uint256[](11);

    values[0] = IERC20(pod).totalSupply(); // Total PODs in existence
    values[1] = s.getStablecoinOwnedByVaultInternal(coverKey);
    values[2] = s.getAmountInStrategies(coverKey, s.getStablecoin()); //  Stablecoins lent outside of the protocol
    values[3] = s.getReassuranceAmountInternal(coverKey); // Total reassurance for this cover
    values[4] = IERC20(pod).balanceOf(you); // Your POD Balance
    values[5] = calculateLiquidityInternal(s, coverKey, pod, values[5]); //  My share of the liquidity pool (in stablecoin)
    values[6] = s.getUintByKey(RoutineInvokerLibV1.getNextWithdrawalStartKey(coverKey));
    values[7] = s.getUintByKey(RoutineInvokerLibV1.getNextWithdrawalEndKey(coverKey));
  }

  /**
   * @dev Called before adding liquidity to the specified cover contract
   *
   * @custom:suppress-malicious-erc The address `stablecoin` can be trusted here because we are ensuring it matches with the protocol stablecoin address.
   * @custom:suppress-address-trust-issue The address `stablecoin` can be trusted here because we are ensuring it matches with the protocol stablecoin address.
   *
   * @param coverKey Enter the cover key
   * @param account Specify the account on behalf of which the liquidity is being added.
   * @param amount Enter the amount of liquidity token to supply.
   * @param npmStakeToAdd Enter the amount of NPM token to stake.
   */
  function preAddLiquidityInternal(
    IStore s,
    bytes32 coverKey,
    address pod,
    address account,
    uint256 amount,
    uint256 npmStakeToAdd
  ) external returns (uint256 podsToMint, uint256 myPreviousStake) {
    require(account != address(0), "Invalid account");

    // Update values
    myPreviousStake = _updateNpmStake(s, coverKey, account, npmStakeToAdd);
    podsToMint = calculatePodsInternal(s, coverKey, pod, amount);

    _updateLastBlock(s, coverKey);
  }

  function _updateLastBlock(IStore s, bytes32 coverKey) private {
    s.setUintByKey(CoverUtilV1.getLastDepositHeightKey(coverKey), block.number);
  }

  function _updateNpmStake(
    IStore s,
    bytes32 coverKey,
    address account,
    uint256 amount
  ) private returns (uint256 myPreviousStake) {
    myPreviousStake = _getMyNpmStake(s, coverKey, account);
    require(amount + myPreviousStake >= s.getMinStakeToAddLiquidity(), "Insufficient stake");

    if (amount > 0) {
      s.addUintByKey(CoverUtilV1.getCoverLiquidityStakeKey(coverKey), amount); // Total stake
      s.addUintByKey(CoverUtilV1.getCoverLiquidityStakeIndividualKey(coverKey, account), amount); // Your stake
    }
  }

  function _getMyNpmStake(
    IStore s,
    bytes32 coverKey,
    address account
  ) private view returns (uint256 myStake) {
    (, myStake) = getCoverNpmStake(s, coverKey, account);
  }

  function getCoverNpmStake(
    IStore s,
    bytes32 coverKey,
    address account
  ) public view returns (uint256 totalStake, uint256 myStake) {
    totalStake = s.getUintByKey(CoverUtilV1.getCoverLiquidityStakeKey(coverKey));
    myStake = s.getUintByKey(CoverUtilV1.getCoverLiquidityStakeIndividualKey(coverKey, account));
  }

  function mustHaveNoBalanceInStrategies(
    IStore s,
    bytes32 coverKey,
    address stablecoin
  ) external view {
    require(s.getAmountInStrategies(coverKey, stablecoin) == 0, "Strategy balance is not zero");
  }

  function mustMaintainBlockHeightOffset(IStore s, bytes32 coverKey) external view {
    uint256 lastDeposit = s.getUintByKey(CoverUtilV1.getLastDepositHeightKey(coverKey));
    require(block.number > lastDeposit + WITHDRAWAL_HEIGHT_OFFSET, "Please wait a few blocks");
  }

  /**
   * @dev Removes liquidity from the specified cover contract
   *
   * @custom:suppress-malicious-erc The address `pod` although can only come from VaultBase,
   * we still need to ensure if it is a protocol member. Check `_redeemPodCalculation` for more info.
   * @custom:suppress-address-trust-issue The address `pod` can't be trusted and therefore needs to be checked
   * if it is a protocol member.
   *
   * @param coverKey Enter the cover key
   * @param podsToRedeem Enter the amount of liquidity token to remove.
   */
  function preRemoveLiquidityInternal(
    IStore s,
    bytes32 coverKey,
    address pod,
    address account,
    uint256 podsToRedeem,
    uint256 npmStakeToRemove,
    bool exit
  ) external returns (address stablecoin, uint256 releaseAmount) {
    stablecoin = s.getStablecoin();

    // Redeem the PODs and receive DAI
    releaseAmount = _redeemPodCalculation(s, coverKey, pod, podsToRedeem);

    ValidationLibV1.mustNotExceedStablecoinThreshold(s, releaseAmount);
    GovernanceUtilV1.mustNotExceedNpmThreshold(npmStakeToRemove);

    // Unstake NPM tokens
    if (npmStakeToRemove > 0) {
      _unStakeNpm(s, account, coverKey, npmStakeToRemove, exit);
    }
  }

  function _unStakeNpm(
    IStore s,
    address account,
    bytes32 coverKey,
    uint256 amount,
    bool exit
  ) private {
    uint256 remainingStake = _getMyNpmStake(s, coverKey, account);
    uint256 minStakeToMaintain = s.getMinStakeToAddLiquidity();

    if (exit) {
      require(remainingStake == amount, "Invalid NPM stake to exit");
    } else {
      require(remainingStake - amount >= minStakeToMaintain, "Can't go below min stake");
    }

    s.subtractUintByKey(CoverUtilV1.getCoverLiquidityStakeKey(coverKey), amount); // Total stake
    s.subtractUintByKey(CoverUtilV1.getCoverLiquidityStakeIndividualKey(coverKey, account), amount); // Your stake
  }

  function _redeemPodCalculation(
    IStore s,
    bytes32 coverKey,
    address pod,
    uint256 podsToRedeem
  ) private view returns (uint256) {
    if (podsToRedeem == 0) {
      return 0;
    }

    s.mustBeProtocolMember(pod);

    uint256 precision = s.getStablecoinPrecision();

    uint256 balance = s.getStablecoinOwnedByVaultInternal(coverKey);
    uint256 commitment = s.getTotalLiquidityUnderProtection(coverKey, precision);
    uint256 available = balance - commitment;

    uint256 releaseAmount = calculateLiquidityInternal(s, coverKey, pod, podsToRedeem);

    // You may need to wait till active policies expire
    require(available >= releaseAmount, "Insufficient balance. Lower the amount or wait till policy expiry."); // solhint-disable-line

    return releaseAmount;
  }

  function accrueInterestInternal(IStore s, bytes32 coverKey) external {
    (bool isWithdrawalPeriod, , , , ) = s.getWithdrawalInfoInternal(coverKey);
    require(isWithdrawalPeriod == true, "Withdrawal hasn't yet begun");

    s.updateStateAndLiquidity(coverKey);

    s.setAccrualCompleteInternal(coverKey, true);
  }

  function mustBeAccrued(IStore s, bytes32 coverKey) external view {
    require(s.isAccrualCompleteInternal(coverKey) == true, "Wait for accrual");
  }

  /**
   * @dev The fee to be charged for a given loan.
   * @param s Provide an instance of the store
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @param fee The amount of `token` to be charged for the loan, on top of the returned principal.
   * @param protocolFee The fee received by the protocol
   */
  function getFlashFeesInternal(
    IStore s,
    bytes32 coverKey,
    address token,
    uint256 amount
  ) public view returns (uint256 fee, uint256 protocolFee) {
    address stablecoin = s.getStablecoin();
    require(stablecoin != address(0), "Cover liquidity uninitialized");

    /*
    https://eips.ethereum.org/EIPS/eip-3156

    The flashFee function MUST return the fee charged for a loan of amount token.
    If the token is not supported flashFee MUST revert.
    */
    require(stablecoin == token, "Unsupported token");
    require(IERC20(stablecoin).balanceOf(s.getVaultAddress(coverKey)) > amount, "Amount insufficient");

    uint256 rate = _getFlashLoanFeeRateInternal(s);
    uint256 protocolRate = _getProtocolFlashLoanFeeRateInternal(s);

    fee = (amount * rate) / ProtoUtilV1.MULTIPLIER;
    protocolFee = (fee * protocolRate) / ProtoUtilV1.MULTIPLIER;
  }

  function getFlashFeeInternal(
    IStore s,
    bytes32 coverKey,
    address token,
    uint256 amount
  ) external view returns (uint256) {
    (uint256 fee, ) = getFlashFeesInternal(s, coverKey, token, amount);
    return fee;
  }

  function _getFlashLoanFeeRateInternal(IStore s) private view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_FLASH_LOAN_FEE);
  }

  function _getProtocolFlashLoanFeeRateInternal(IStore s) private view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_FLASH_LOAN_FEE_PROTOCOL);
  }

  /**
   * @dev The amount of currency available to be lent.
   * @param token The loan currency.
   * @return The amount of `token` that can be borrowed.
   */
  function getMaxFlashLoanInternal(
    IStore s,
    bytes32 coverKey,
    address token
  ) external view returns (uint256) {
    address stablecoin = s.getStablecoin();
    require(stablecoin != address(0), "Cover liquidity uninitialized");

    if (stablecoin == token) {
      return IERC20(stablecoin).balanceOf(s.getVaultAddress(coverKey));
    }

    /*
    https://eips.ethereum.org/EIPS/eip-3156

    The maxFlashLoan function MUST return the maximum loan possible for token.
    If a token is not currently supported maxFlashLoan MUST return 0, instead of reverting.    
    */
    return 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../libraries/StrategyLibV1.sol";

contract MockLiquidityEngineUser {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using StrategyLibV1 for IStore;
  using CoverUtilV1 for IStore;

  IStore public s;

  constructor(IStore store) {
    s = store;
  }

  function setMaxLendingRatioInternal(uint256 ratio) external {
    s.setMaxLendingRatioInternal(ratio);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../libraries/StrategyLibV1.sol";

contract MockCoverUtilUser {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using StrategyLibV1 for IStore;
  using CoverUtilV1 for IStore;

  IStore public s;

  constructor(IStore store) {
    s = store;
  }

  function getActiveLiquidityUnderProtection(bytes32 coverKey, bytes32 productKey) external view returns (uint256) {
    uint256 precision = s.getStablecoinPrecision();
    return s.getActiveLiquidityUnderProtection(coverKey, productKey, precision);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../libraries/StoreKeyUtil.sol";

contract MockStoreKeyUtilUser {
  using StoreKeyUtil for IStore;
  IStore public s;

  constructor(IStore store) {
    s = store;
  }

  function setUintByKey(bytes32 key, uint256 value) external {
    s.setUintByKey(key, value);
  }

  function setUintByKeys(
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    s.setUintByKeys(key1, key2, value);
  }

  function setUintByKeys(
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    s.setUintByKeys(key1, key2, account, value);
  }

  function addUintByKey(bytes32 key, uint256 value) external {
    s.addUintByKey(key, value);
  }

  function addUintByKeys(
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    s.addUintByKeys(key1, key2, value);
  }

  function addUintByKeys(
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    s.addUintByKeys(key1, key2, account, value);
  }

  function subtractUintByKey(bytes32 key, uint256 value) external {
    s.subtractUintByKey(key, value);
  }

  function subtractUintByKeys(
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    s.subtractUintByKeys(key1, key2, value);
  }

  function subtractUintByKeys(
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    s.subtractUintByKeys(key1, key2, account, value);
  }

  function setStringByKey(bytes32 key, string calldata value) external {
    s.setStringByKey(key, value);
  }

  function setStringByKeys(
    bytes32 key1,
    bytes32 key2,
    string calldata value
  ) external {
    s.setStringByKeys(key1, key2, value);
  }

  function setBytes32ByKey(bytes32 key, bytes32 value) external {
    s.setBytes32ByKey(key, value);
  }

  function setBytes32ByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    s.setBytes32ByKeys(key1, key2, value);
  }

  function setBoolByKey(bytes32 key, bool value) external {
    s.setBoolByKey(key, value);
  }

  function setBoolByKeys(
    bytes32 key1,
    bytes32 key2,
    bool value
  ) external {
    s.setBoolByKeys(key1, key2, value);
  }

  function setBoolByKeys(
    bytes32 key,
    address account,
    bool value
  ) external {
    s.setBoolByKeys(key, account, value);
  }

  function setAddressByKey(bytes32 key, address value) external {
    s.setAddressByKey(key, value);
  }

  function setAddressByKeys(
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    s.setAddressByKeys(key1, key2, value);
  }

  function setAddressByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    s.setAddressByKeys(key1, key2, key3, value);
  }

  function setAddressArrayByKey(bytes32 key, address value) external {
    s.setAddressArrayByKey(key, value);
  }

  function setAddressArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    s.setAddressArrayByKeys(key1, key2, value);
  }

  function setAddressArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    s.setAddressArrayByKeys(key1, key2, key3, value);
  }

  function setAddressBooleanByKey(
    bytes32 key,
    address account,
    bool value
  ) external {
    s.setAddressBooleanByKey(key, account, value);
  }

  function setAddressBooleanByKeys(
    bytes32 key1,
    bytes32 key2,
    address account,
    bool value
  ) external {
    s.setAddressBooleanByKeys(key1, key2, account, value);
  }

  function setAddressBooleanByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account,
    bool value
  ) external {
    s.setAddressBooleanByKeys(key1, key2, key3, account, value);
  }

  function deleteUintByKey(bytes32 key) external {
    s.deleteUintByKey(key);
  }

  function deleteUintByKeys(bytes32 key1, bytes32 key2) external {
    s.deleteUintByKeys(key1, key2);
  }

  function deleteBytes32ByKey(bytes32 key) external {
    s.deleteBytes32ByKey(key);
  }

  function deleteBytes32ByKeys(bytes32 key1, bytes32 key2) external {
    s.deleteBytes32ByKeys(key1, key2);
  }

  function deleteBytes32ArrayByKey(bytes32 key, bytes32 value) external {
    s.deleteBytes32ArrayByKey(key, value);
  }

  function deleteBytes32ArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    s.deleteBytes32ArrayByKeys(key1, key2, value);
  }

  function deleteBytes32ArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    s.deleteBytes32ArrayByKeys(key1, key2, key3, value);
  }

  function deleteBytes32ArrayByIndexByKey(bytes32 key, uint256 index) external {
    s.deleteBytes32ArrayByIndexByKey(key, index);
  }

  function deleteBytes32ArrayByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external {
    s.deleteBytes32ArrayByIndexByKeys(key1, key2, index);
  }

  function deleteBytes32ArrayByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external {
    s.deleteBytes32ArrayByIndexByKeys(key1, key2, key3, index);
  }

  function deleteBoolByKey(bytes32 key) external {
    s.deleteBoolByKey(key);
  }

  function deleteBoolByKeys(bytes32 key1, bytes32 key2) external {
    s.deleteBoolByKeys(key1, key2);
  }

  function deleteBoolByKeys(bytes32 key, address account) external {
    s.deleteBoolByKeys(key, account);
  }

  function deleteAddressByKey(bytes32 key) external {
    s.deleteAddressByKey(key);
  }

  function deleteAddressByKeys(bytes32 key1, bytes32 key2) external {
    s.deleteAddressByKeys(key1, key2);
  }

  function deleteAddressByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external {
    s.deleteAddressByKeys(key1, key2, key3);
  }

  function deleteAddressArrayByKey(bytes32 key, address value) external {
    s.deleteAddressArrayByKey(key, value);
  }

  function deleteAddressArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    s.deleteAddressArrayByKeys(key1, key2, value);
  }

  function deleteAddressArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    s.deleteAddressArrayByKeys(key1, key2, key3, value);
  }

  function deleteAddressArrayByIndexByKey(bytes32 key, uint256 index) external {
    s.deleteAddressArrayByIndexByKey(key, index);
  }

  function deleteAddressArrayByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external {
    s.deleteAddressArrayByIndexByKeys(key1, key2, index);
  }

  function deleteAddressArrayByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external {
    s.deleteAddressArrayByIndexByKeys(key1, key2, key3, index);
  }

  function getUintByKey(bytes32 key) external view returns (uint256) {
    return s.getUintByKey(key);
  }

  function getUintByKeys(bytes32 key1, bytes32 key2) external view returns (uint256) {
    return s.getUintByKeys(key1, key2);
  }

  function getUintByKeys(
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (uint256) {
    return s.getUintByKeys(key1, key2, account);
  }

  function getStringByKey(bytes32 key) external view returns (string memory) {
    return s.getStringByKey(key);
  }

  function getStringByKeys(bytes32 key1, bytes32 key2) external view returns (string memory) {
    return s.getStringByKeys(key1, key2);
  }

  function getBytes32ByKey(bytes32 key) external view returns (bytes32) {
    return s.getBytes32ByKey(key);
  }

  function getBytes32ByKeys(bytes32 key1, bytes32 key2) external view returns (bytes32) {
    return s.getBytes32ByKeys(key1, key2);
  }

  function getBoolByKey(bytes32 key) external view returns (bool) {
    return s.getBoolByKey(key);
  }

  function getBoolByKeys(bytes32 key1, bytes32 key2) external view returns (bool) {
    return s.getBoolByKeys(key1, key2);
  }

  function getBoolByKeys(bytes32 key, address account) external view returns (bool) {
    return s.getBoolByKeys(key, account);
  }

  function getAddressByKey(bytes32 key) external view returns (address) {
    return s.getAddressByKey(key);
  }

  function getAddressByKeys(bytes32 key1, bytes32 key2) external view returns (address) {
    return s.getAddressByKeys(key1, key2);
  }

  function getAddressByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address) {
    return s.getAddressByKeys(key1, key2, key3);
  }

  function getAddressBooleanByKey(bytes32 key, address account) external view returns (bool) {
    return s.getAddressBooleanByKey(key, account);
  }

  function getAddressBooleanByKeys(
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (bool) {
    return s.getAddressBooleanByKeys(key1, key2, account);
  }

  function getAddressBooleanByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account
  ) external view returns (bool) {
    return s.getAddressBooleanByKeys(key1, key2, key3, account);
  }

  function countAddressArrayByKey(bytes32 key) external view returns (uint256) {
    return s.countAddressArrayByKey(key);
  }

  function countAddressArrayByKeys(bytes32 key1, bytes32 key2) external view returns (uint256) {
    return s.countAddressArrayByKeys(key1, key2);
  }

  function countAddressArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.countAddressArrayByKeys(key1, key2, key3);
  }

  function getAddressArrayByKey(bytes32 key) external view returns (address[] memory) {
    return s.getAddressArrayByKey(key);
  }

  function getAddressArrayByKeys(bytes32 key1, bytes32 key2) external view returns (address[] memory) {
    return s.getAddressArrayByKeys(key1, key2);
  }

  function getAddressArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address[] memory) {
    return s.getAddressArrayByKeys(key1, key2, key3);
  }

  function getAddressArrayItemPositionByKey(bytes32 key, address addressToFind) external view returns (uint256) {
    return s.getAddressArrayItemPositionByKey(key, addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    bytes32 key1,
    bytes32 key2,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPositionByKeys(key1, key2, addressToFind);
  }

  function getAddressArrayItemPositionByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address addressToFind
  ) external view returns (uint256) {
    return s.getAddressArrayItemPositionByKeys(key1, key2, key3, addressToFind);
  }

  function getAddressArrayItemByIndexByKey(bytes32 key, uint256 index) external view returns (address) {
    return s.getAddressArrayItemByIndexByKey(key, index);
  }

  function getAddressArrayItemByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndexByKeys(key1, key2, index);
  }

  function getAddressArrayItemByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external view returns (address) {
    return s.getAddressArrayItemByIndexByKeys(key1, key2, key3, index);
  }

  function setBytes32ArrayByKey(bytes32 key, bytes32 value) external {
    s.setBytes32ArrayByKey(key, value);
  }

  function setBytes32ArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    s.setBytes32ArrayByKeys(key1, key2, value);
  }

  function setBytes32ArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 value
  ) external {
    s.setBytes32ArrayByKeys(key1, key2, key3, value);
  }

  function countBytes32ArrayByKey(bytes32 key) external view returns (uint256) {
    return s.countBytes32ArrayByKey(key);
  }

  function countBytes32ArrayByKeys(bytes32 key1, bytes32 key2) external view returns (uint256) {
    return s.countBytes32ArrayByKeys(key1, key2);
  }

  function countBytes32ArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (uint256) {
    return s.countBytes32ArrayByKeys(key1, key2, key3);
  }

  function getBytes32ArrayByKey(bytes32 key) external view returns (bytes32[] memory) {
    return s.getBytes32ArrayByKey(key);
  }

  function getBytes32ArrayByKeys(bytes32 key1, bytes32 key2) external view returns (bytes32[] memory) {
    return s.getBytes32ArrayByKeys(key1, key2);
  }

  function getBytes32ArrayByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (bytes32[] memory) {
    return s.getBytes32ArrayByKeys(key1, key2, key3);
  }

  function getBytes32ArrayItemPositionByKey(bytes32 key, bytes32 bytes32ToFind) external view returns (uint256) {
    return s.getBytes32ArrayItemPositionByKey(key, bytes32ToFind);
  }

  function getBytes32ArrayItemPositionByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    return s.getBytes32ArrayItemPositionByKeys(key1, key2, bytes32ToFind);
  }

  function getBytes32ArrayItemPositionByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    bytes32 bytes32ToFind
  ) external view returns (uint256) {
    return s.getBytes32ArrayItemPositionByKeys(key1, key2, key3, bytes32ToFind);
  }

  function getBytes32ArrayItemByIndexByKey(bytes32 key, uint256 index) external view returns (bytes32) {
    return s.getBytes32ArrayItemByIndexByKey(key, index);
  }

  function getBytes32ArrayItemByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    uint256 index
  ) external view returns (bytes32) {
    return s.getBytes32ArrayItemByIndexByKeys(key1, key2, index);
  }

  function getBytes32ArrayItemByIndexByKeys(
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    uint256 index
  ) external view returns (bytes32) {
    return s.getBytes32ArrayItemByIndexByKeys(key1, key2, key3, index);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../interfaces/IStore.sol";
import "../interfaces/IProtocol.sol";
import "../libraries/ProtoUtilV1.sol";
import "../libraries/StoreKeyUtil.sol";
import "./ProtoBase.sol";

contract Protocol is IProtocol, ProtoBase {
  using ProtoUtilV1 for bytes;
  using RegistryLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using StoreKeyUtil for IStore;

  uint256 public initialized = 0;

  constructor(IStore store) ProtoBase(store) {} // solhint-disable-line

  /**
   * @dev Initializes the protocol once. There is only one instance of the protocol
   * that can function.
   *
   * @custom:suppress-acl Can only be called by the deployer or an admin
   * @custom:suppress-initialization Can only be initialized by the deployer or an admin
   * @custom:todo Allow price oracle to be zero
   * @custom:note Burner isn't necessarily the zero address. The tokens to be burned are sent to an address,
   * bridged back to the Ethereum mainnet (if on a different chain), and burned on a period but random basis.
   *
   *
   * @param addresses[0] burner
   * @param addresses[1] uniswapV2RouterLike
   * @param addresses[2] uniswapV2FactoryLike
   * @param addresses[3] npm
   * @param addresses[4] treasury
   * @param addresses[5] npm price oracle
   * @param values[0] coverCreationFee
   * @param values[1] minCoverCreationStake
   * @param values[2] firstReportingStake
   * @param values[3] claimPeriod
   * @param values[4] reportingBurnRate
   * @param values[5] governanceReporterCommission
   * @param values[6] claimPlatformFee
   * @param values[7] claimReporterCommission
   * @param values[8] flashLoanFee
   * @param values[9] flashLoanFeeProtocol
   * @param values[10] resolutionCoolDownPeriod
   * @param values[11] state and liquidity update interval
   * @param values[12] max lending ratio
   */
  function initialize(address[] calldata addresses, uint256[] calldata values) external override nonReentrant whenNotPaused {
    s.mustBeProtocolMember(msg.sender);

    require(addresses[0] != address(0), "Invalid Burner");
    require(addresses[1] != address(0), "Invalid Uniswap V2 Router");
    require(addresses[2] != address(0), "Invalid Uniswap V2 Factory");
    // require(addresses[3] != address(0), "Invalid NPM"); // @note: check validation below
    require(addresses[4] != address(0), "Invalid Treasury");
    // @suppress-accidental-zero
    // @check if uniswap v2 contracts can be zero
    require(addresses[5] != address(0), "Invalid NPM Price Oracle");

    // @suppress-zero-value-check Some zero values are allowed
    // These checks are disabled as this function is only accessible to an admin
    // require(values[0] > 0, "Invalid cover creation fee");
    // require(values[1] > 0, "Invalid cover creation stake");
    // require(values[2] > 0, "Invalid first reporting stake");
    // require(values[3] > 0, "Invalid claim period");
    // require(values[4] > 0, "Invalid reporting burn rate");
    // require(values[5] > 0, "Invalid reporter income: NPM");
    // require(values[6] > 0, "Invalid platform fee: claims");
    // require(values[7] > 0, "Invalid reporter income: claims");
    // require(values[8] > 0, "Invalid vault fee: flashloan");
    // require(values[9] > 0, "Invalid platform fee: flashloan");
    // require(values[10] >= 24 hours, "Invalid cooldown period");
    // require(values[11] > 0, "Invalid state update interval");
    // require(values[12] > 0, "Invalid max lending ratio");

    if (initialized == 1) {
      AccessControlLibV1.mustBeAdmin(s);
      require(addresses[3] == address(0), "Can't change NPM");
    } else {
      require(addresses[3] != address(0), "Invalid NPM");

      s.setAddressByKey(ProtoUtilV1.CNS_CORE, address(this));
      s.setBoolByKeys(ProtoUtilV1.NS_CONTRACTS, address(this), true);

      s.setAddressByKey(ProtoUtilV1.CNS_NPM, addresses[3]);
    }

    s.setAddressByKey(ProtoUtilV1.CNS_BURNER, addresses[0]);

    s.setAddressByKey(ProtoUtilV1.CNS_UNISWAP_V2_ROUTER, addresses[1]);
    s.setAddressByKey(ProtoUtilV1.CNS_UNISWAP_V2_FACTORY, addresses[2]);
    s.setAddressByKey(ProtoUtilV1.CNS_TREASURY, addresses[4]);
    s.setAddressByKey(ProtoUtilV1.CNS_NPM_PRICE_ORACLE, addresses[5]);

    s.setUintByKey(ProtoUtilV1.NS_COVER_CREATION_FEE, values[0]);
    s.setUintByKey(ProtoUtilV1.NS_COVER_CREATION_MIN_STAKE, values[1]);
    s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, values[2]);
    s.setUintByKey(ProtoUtilV1.NS_CLAIM_PERIOD, values[3]);
    s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE, values[4]);
    s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION, values[5]);
    s.setUintByKey(ProtoUtilV1.NS_COVER_PLATFORM_FEE, values[6]);
    s.setUintByKey(ProtoUtilV1.NS_CLAIM_REPORTER_COMMISSION, values[7]);
    s.setUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_FLASH_LOAN_FEE, values[8]);
    s.setUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_FLASH_LOAN_FEE_PROTOCOL, values[9]);
    s.setUintByKey(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD, values[10]);
    s.setUintByKey(ProtoUtilV1.NS_LIQUIDITY_STATE_UPDATE_INTERVAL, values[11]);
    s.setUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_MAX_LENDING_RATIO, values[12]);
    s.setUintByKey(ProtoUtilV1.NS_COVERAGE_LAG, 1 days);

    initialized = 1;
    emit Initialized(addresses, values);
  }

  /**
   * @dev Adds member to the protocol
   *
   * A member is a trusted EOA or a contract that was added to the protocol using `addContract`
   * function. When a contract is removed using `upgradeContract` function, the membership of previous
   * contract is also removed.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an upgrade agent.
   * Since adding member to the protocol is a highy risky activity,
   * the role `Upgrade Agent` is considered to be one of the most `Critical` roles.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   * @custom:suppress-address-trust-issue The address `member` can be trusted because this can only come from upgrade agents.
   *
   * @param member Enter an address to add as a protocol member
   */
  function addMember(address member) external override nonReentrant whenNotPaused {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeUpgradeAgent(s);

    AccessControlLibV1.addMemberInternal(s, member);
    emit MemberAdded(member);
  }

  /**
   * @dev Removes a member from the protocol. This function is only accessible
   * to an upgrade agent.
   *
   * @custom:suppress-address-trust-issue This instance of stablecoin can be trusted because of the ACL requirement.
   *
   * @param member Enter an address to remove as a protocol member
   */
  function removeMember(address member) external override nonReentrant whenNotPaused {
    ProtoUtilV1.mustBeProtocolMember(s, member);
    s.mustNotBePaused();
    AccessControlLibV1.mustBeUpgradeAgent(s);

    AccessControlLibV1.removeMemberInternal(s, member);
    emit MemberRemoved(member);
  }

  /**
   * @dev Adds a contract to the protocol. See `addContractWithKey` for more info.
   * @custom:suppress-acl This function is just an intermediate
   * @custom:suppress-pausable This function is just an intermediate
   */
  function addContract(bytes32 namespace, address contractAddress) external override {
    addContractWithKey(namespace, 0, contractAddress);
  }

  /**
   * @dev Adds a contract to the protocol using a namespace and key.
   *
   * The contracts that are added using this function are also added as protocol members.
   * Each contract you add to the protocol needs to also specify the namespace and also
   * key if applicable. The key is useful when multiple instances of a contract can
   * be deployed. For example, multiple instances of cxTokens and Vaults can be deployed on demand.
   *
   * Tip: find out how the `getVaultFactoryContract().deploy` function is being used.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an upgrade agent.
   * Since adding member to the protocol is a highy risky activity,
   * the role `Upgrade Agent` is considered to be one of the most `Critical` roles.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   * @custom:suppress-address-trust-issue Although the `contractAddress` can't be trusted, the upgrade admin has to check the contract code manually.
   *
   * @param namespace Enter a unique namespace for this contract
   * @param key Enter a key if this contract has siblings
   * @param contractAddress Enter the contract address to add.
   *
   */
  function addContractWithKey(
    bytes32 namespace,
    bytes32 key,
    address contractAddress
  ) public override nonReentrant whenNotPaused {
    require(contractAddress != address(0), "Invalid contract");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeUpgradeAgent(s);
    address current = s.getProtocolContract(namespace);

    require(current == address(0), "Please upgrade contract");

    AccessControlLibV1.addContractInternal(s, namespace, key, contractAddress);
    emit ContractAdded(namespace, key, contractAddress);
  }

  /**
   * @dev Upgrades a contract at the given namespace. See `upgradeContractWithKey` for more info.
   *
   * @custom:suppress-acl This function is just an intermediate
   * @custom:suppress-pausable This function is just an intermediate
   *
   */
  function upgradeContract(
    bytes32 namespace,
    address previous,
    address current
  ) external override {
    upgradeContractWithKey(namespace, 0, previous, current);
  }

  /**
   * @dev Upgrades a contract at the given namespace and key.
   *
   * The previous contract's protocol membership is revoked and
   * the current immediately starts assuming responsbility of
   * whatever the contract needs to do at the supplied namespace and key.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an upgrade agent.
   * Since adding member to the protocol is a highy risky activity,
   * the role `Upgrade Agent` is considered to be one of the most `Critical` roles.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   * @custom:suppress-address-trust-issue Can only be invoked by an upgrade agent.
   *
   * @param namespace Enter a unique namespace for this contract
   * @param key Enter a key if this contract has siblings
   * @param previous Enter the existing contract address at this namespace and key.
   * @param current Enter the contract address which will replace the previous contract.
   */
  function upgradeContractWithKey(
    bytes32 namespace,
    bytes32 key,
    address previous,
    address current
  ) public override nonReentrant whenNotPaused {
    require(current != address(0), "Invalid contract");

    ProtoUtilV1.mustBeProtocolMember(s, previous);
    s.mustNotBePaused();
    AccessControlLibV1.mustBeUpgradeAgent(s);

    AccessControlLibV1.upgradeContractInternal(s, namespace, key, previous, current);
    emit ContractUpgraded(namespace, key, previous, current);
  }

  /**
   * @dev Grants roles to the protocol.
   *
   * Individual Neptune Mutual protocol contracts inherit roles
   * defined to this contract. Meaning, the `AccessControl` logic
   * here is used everywhere else.
   *
   * @custom:warning Warning:
   *
   * This feature is only accessible to an admin. Adding any kind of role to the protocol is immensely risky.
   *
   * Using Tenderly War Rooms/Web3 Actions or OZ Defender, the protocol needs to be paused
   * when this function is invoked.
   *
   */
  function grantRoles(AccountWithRoles[] calldata detail) external override nonReentrant whenNotPaused {
    // @suppress-zero-value-check Checked
    require(detail.length > 0, "Invalid args");
    AccessControlLibV1.mustBeAdmin(s);

    for (uint256 i = 0; i < detail.length; i++) {
      for (uint256 j = 0; j < detail[i].roles.length; j++) {
        _grantRole(detail[i].roles[j], detail[i].account);
      }
    }
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_PROTOCOL;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "../libraries/ProtoUtilV1.sol";
import "./Recoverable.sol";

abstract contract ProtoBase is AccessControl, Pausable, Recoverable {
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;

  constructor(IStore store) Recoverable(store) {
    _setAccessPolicy();
  }

  function _setAccessPolicy() private {
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_ADMIN, AccessControlLibV1.NS_ROLES_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_COVER_MANAGER, AccessControlLibV1.NS_ROLES_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_LIQUIDITY_MANAGER, AccessControlLibV1.NS_ROLES_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_GOVERNANCE_ADMIN, AccessControlLibV1.NS_ROLES_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_GOVERNANCE_AGENT, AccessControlLibV1.NS_ROLES_GOVERNANCE_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_UPGRADE_AGENT, AccessControlLibV1.NS_ROLES_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_RECOVERY_AGENT, AccessControlLibV1.NS_ROLES_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_PAUSE_AGENT, AccessControlLibV1.NS_ROLES_ADMIN);
    _setRoleAdmin(AccessControlLibV1.NS_ROLES_UNPAUSE_AGENT, AccessControlLibV1.NS_ROLES_ADMIN);

    _setupRole(AccessControlLibV1.NS_ROLES_ADMIN, msg.sender);
  }

  function setupRole(
    bytes32 role,
    bytes32 adminRole,
    address account
  ) external nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeAdmin(s);

    _setRoleAdmin(role, adminRole);

    if (account != address(0)) {
      _setupRole(role, account);
    }
  }

  /**
   * @dev Pauses this contract.
   *
   * Individual protocol contracts infer to the protocol's "paused state".
   * So, if the protocol is paused, all other contracts are automatically
   * paused without having to do anything special.
   *
   *
   * In Neptune Mutual Protocol, `pause` and `unpause` features are
   * considered to have different risk exposures.
   *
   * The pauser role is considered to be low-risk role while
   * the unpauser is believed to be highly critical.
   *
   * In other words, pausing the protocol is believed to be less riskier than unpausing it.
   *
   * The only (private) key that is ever allowed to be programmatically used is the
   * pause agents.
   */
  function pause() external nonReentrant whenNotPaused {
    AccessControlLibV1.mustBePauseAgent(s);
    super._pause();
  }

  /**
   * @dev Unpauses or resumes this contract.
   *
   * Individual protocol contracts infer to the protocol's "paused state".
   * So, if the protocol is paused, all other contracts are automatically
   * paused without having to do anything special.
   *
   *
   * In Neptune Mutual Protocol, `pause` and `unpause` features are
   * considered to have different risk exposures.
   *
   * The pauser role is considered to be low-risk role while
   * the unpauser is believed to be highly critical.
   *
   * In other words, pausing the protocol is believed to be less riskier than unpausing it.
   *
   * The only (private) key that is ever allowed to be programmatically used is the
   * pause agents.
   */
  function unpause() external whenPaused nonReentrant whenPaused {
    AccessControlLibV1.mustBeUnpauseAgent(s);
    super._unpause();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract WithPausability is Pausable, Ownable {
  /**
   * @dev Pauses or unpauses this contract.
   */
  function pause(bool flag) external onlyOwner {
    if (flag) {
      super._pause();
      return;
    }

    super._unpause();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract WithRecovery is Ownable {
  using SafeERC20 for IERC20;

  /**
   * @dev Recover all Ether held by the contract.
   *
   * @custom:suppress-pausable Risk tolerable because of the ACL
   *
   */
  function recoverEther(address sendTo) external onlyOwner {
    // slither-disable-next-line arbitrary-send
    payable(sendTo).transfer(address(this).balance);
  }

  /**
   * @dev Recover an ERC-20 compatible token sent to this contract.
   * @param malicious ERC-20 The address of the token contract
   * @param sendTo The address that receives the recovered tokens
   *
   * @custom:suppress-pausable Risk tolerable because of the ACL
   *
   */
  function recoverToken(IERC20 malicious, address sendTo) external onlyOwner {
    malicious.safeTransfer(sendTo, malicious.balanceOf(address(this)));
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./WithRecovery.sol";
import "./WithPausability.sol";

contract NPM is WithPausability, WithRecovery, ERC20 {
  uint256 private constant _CAP = 1_000_000_000 ether;
  uint256 private _issued = 0;

  event Minted(bytes32 indexed key, address indexed account, uint256 amount);

  constructor(
    address timelockOrOwner,
    string memory tokenName,
    string memory tokenSymbol
  ) Ownable() Pausable() ERC20(tokenName, tokenSymbol) {
    require(timelockOrOwner != address(0), "Invalid owner");
    require(bytes(tokenName).length > 0, "Invalid token name");
    require(bytes(tokenSymbol).length > 0, "Invalid token symbol");

    super._transferOwnership(timelockOrOwner);
  }

  function _beforeTokenTransfer(
    address,
    address,
    uint256
  ) internal view virtual override whenNotPaused {} // solhint-disable-line

  function issueMany(
    bytes32 key,
    address[] calldata receivers,
    uint256[] calldata amounts
  ) external onlyOwner whenNotPaused {
    require(receivers.length > 0, "No receiver");
    require(receivers.length == amounts.length, "Invalid args");

    _issued += _sumOf(amounts);
    require(_issued <= _CAP, "Cap exceeded");

    for (uint256 i = 0; i < receivers.length; i++) {
      _issue(key, receivers[i], amounts[i]);
    }
  }

  function transferMany(address[] calldata receivers, uint256[] calldata amounts) external onlyOwner whenNotPaused {
    require(receivers.length > 0, "No receiver");
    require(receivers.length == amounts.length, "Invalid args");

    for (uint256 i = 0; i < receivers.length; i++) {
      super.transfer(receivers[i], amounts[i]);
    }
  }

  function _issue(
    bytes32 key,
    address mintTo,
    uint256 amount
  ) private {
    require(amount > 0, "Invalid amount");

    super._mint(mintTo, amount);
    emit Minted(key, mintTo, amount);
  }

  function _sumOf(uint256[] calldata amounts) private pure returns (uint256 total) {
    for (uint256 i = 0; i < amounts.length; i++) {
      total += amounts[i];
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./NPM.sol";
import "../../interfaces/IStore.sol";

/**
 * @title Proof of Authority Tokens (POTs)
 *
 * @dev POTs can't be used outside of the protocol
 * for example in DEXes. Once NPM token is launched, it will replace POTs.
 *
 * For now, Neptune Mutual team and a few others will have access to POTs.
 *
 * POTs aren't conventional ERC-20 tokens; they can't be transferred freely;
 * they don't have any value, and therefore must not be purchased or sold.
 *
 * Agan, POTs are distributed to individuals and companies
 * who particpate in our governance and dispute management portals.
 *
 */
contract POT is NPM {
  IStore public immutable s;
  mapping(address => bool) public whitelist;
  bytes32 public constant NS_MEMBERS = "ns:members";

  event WhitelistUpdated(address indexed updatedBy, address[] accounts, bool[] statuses);

  constructor(address timelockOrOwner, IStore store) NPM(timelockOrOwner, "Neptune Mutual POT", "POT") {
    // require(timelockOrOwner != address(0), "Invalid owner"); // Already checked in `NPM`
    require(address(store) != address(0), "Invalid store");

    s = store;
    whitelist[address(this)] = true;
    whitelist[timelockOrOwner] = true;
  }

  function _throwIfNotProtocolMember(address account) private view {
    bytes32 key = keccak256(abi.encodePacked(NS_MEMBERS, account));
    bool isMember = s.getBool(key);

    // POTs can only be used within the Neptune Mutual protocol
    require(isMember == true, "Access denied");
  }

  /**
   * @dev Updates whitelisted addresses.
   * Provide a list of accounts and list of statuses to add or remove from the whitelist.
   *
   * @custom:suppress-pausable Risk tolerable
   *
   */
  function updateWhitelist(address[] calldata accounts, bool[] memory statuses) external onlyOwner {
    require(accounts.length > 0, "No account");
    require(accounts.length == statuses.length, "Invalid args");

    for (uint256 i = 0; i < accounts.length; i++) {
      whitelist[accounts[i]] = statuses[i];
    }

    emit WhitelistUpdated(msg.sender, accounts, statuses);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256
  ) internal view override whenNotPaused {
    // Token mints
    if (from == address(0)) {
      // aren't restricted
      return;
    }

    // Someone not whitelisted
    // ............................ can still transfer to a whitelisted address
    if (whitelist[from] == false && whitelist[to] == false) {
      // and to the Neptune Mutual Protocol contracts but nowhere else
      _throwIfNotProtocolMember(to);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../interfaces/IStore.sol";

contract FakeStore is IStore {
  mapping(bytes32 => int256) public intStorage;
  mapping(bytes32 => uint256) public uintStorage;
  mapping(bytes32 => uint256[]) public uintsStorage;
  mapping(bytes32 => address) public addressStorage;
  mapping(bytes32 => string) public stringStorage;
  mapping(bytes32 => bytes) public bytesStorage;
  mapping(bytes32 => bytes32) public bytes32Storage;
  mapping(bytes32 => bool) public boolStorage;
  mapping(bytes32 => mapping(address => bool)) public addressBooleanStorage;
  mapping(bytes32 => address[]) public addressArrayStorage;
  mapping(bytes32 => mapping(address => uint256)) public addressArrayPositionMap;
  mapping(bytes32 => bytes32[]) public bytes32ArrayStorage;
  mapping(bytes32 => mapping(bytes32 => uint256)) public bytes32ArrayPositionMap;

  function setAddress(bytes32 k, address v) external override {
    addressStorage[k] = v;
  }

  function setAddressBoolean(
    bytes32 k,
    address a,
    bool v
  ) external override {
    addressBooleanStorage[k][a] = v;
  }

  function setUint(bytes32 k, uint256 v) external override {
    uintStorage[k] = v;
  }

  function addUint(bytes32 k, uint256 v) external override {
    uint256 existing = uintStorage[k];
    uintStorage[k] = existing + v;
  }

  function subtractUint(bytes32 k, uint256 v) external override {
    uint256 existing = uintStorage[k];
    uintStorage[k] = existing - v;
  }

  function setUints(bytes32 k, uint256[] calldata v) external override {
    uintsStorage[k] = v;
  }

  function setString(bytes32 k, string calldata v) external override {
    stringStorage[k] = v;
  }

  function setBytes(bytes32 k, bytes calldata v) external override {
    bytesStorage[k] = v;
  }

  function setBool(bytes32 k, bool v) external override {
    if (v) {
      boolStorage[k] = v;
    }
  }

  function setInt(bytes32 k, int256 v) external override {
    intStorage[k] = v;
  }

  function setBytes32(bytes32 k, bytes32 v) external override {
    bytes32Storage[k] = v;
  }

  function setAddressArrayItem(bytes32 k, address v) external override {
    if (addressArrayPositionMap[k][v] == 0) {
      addressArrayStorage[k].push(v);
      addressArrayPositionMap[k][v] = addressArrayStorage[k].length;
    }
  }

  function deleteAddress(bytes32 k) external override {
    delete addressStorage[k];
  }

  function deleteUint(bytes32 k) external override {
    delete uintStorage[k];
  }

  function deleteUints(bytes32 k) external override {
    delete uintsStorage[k];
  }

  function deleteString(bytes32 k) external override {
    delete stringStorage[k];
  }

  function deleteBytes(bytes32 k) external override {
    delete bytesStorage[k];
  }

  function deleteBool(bytes32 k) external override {
    delete boolStorage[k];
  }

  function deleteInt(bytes32 k) external override {
    delete intStorage[k];
  }

  function deleteBytes32(bytes32 k) external override {
    delete bytes32Storage[k];
  }

  function deleteAddressArrayItem(bytes32 k, address v) public override {
    require(addressArrayPositionMap[k][v] > 0, "Not found");

    uint256 i = addressArrayPositionMap[k][v] - 1;
    uint256 count = addressArrayStorage[k].length;

    if (i + 1 != count) {
      addressArrayStorage[k][i] = addressArrayStorage[k][count - 1];
      address theThenLastAddress = addressArrayStorage[k][i];
      addressArrayPositionMap[k][theThenLastAddress] = i + 1;
    }

    addressArrayStorage[k].pop();
    delete addressArrayPositionMap[k][v];
  }

  function deleteAddressArrayItemByIndex(bytes32 k, uint256 i) external override {
    require(i < addressArrayStorage[k].length, "Invalid index");

    address v = addressArrayStorage[k][i];
    deleteAddressArrayItem(k, v);
  }

  function getAddressValues(bytes32[] calldata keys) external view override returns (address[] memory values) {
    values = new address[](keys.length + 1);

    for (uint256 i = 0; i < keys.length; i++) {
      values[i] = addressStorage[keys[i]];
    }
  }

  function getAddress(bytes32 k) external view override returns (address) {
    return addressStorage[k];
  }

  function getAddressBoolean(bytes32 k, address a) external view override returns (bool) {
    return addressBooleanStorage[k][a];
  }

  function getUintValues(bytes32[] calldata keys) external view override returns (uint256[] memory values) {
    values = new uint256[](keys.length + 1);

    for (uint256 i = 0; i < keys.length; i++) {
      values[i] = uintStorage[keys[i]];
    }
  }

  function getUint(bytes32 k) external view override returns (uint256) {
    return uintStorage[k];
  }

  function getUints(bytes32 k) external view override returns (uint256[] memory) {
    return uintsStorage[k];
  }

  function getString(bytes32 k) external view override returns (string memory) {
    return stringStorage[k];
  }

  function getBytes(bytes32 k) external view override returns (bytes memory) {
    return bytesStorage[k];
  }

  function getBool(bytes32 k) external view override returns (bool) {
    return boolStorage[k];
  }

  function getInt(bytes32 k) external view override returns (int256) {
    return intStorage[k];
  }

  function getBytes32(bytes32 k) external view override returns (bytes32) {
    return bytes32Storage[k];
  }

  function getAddressArray(bytes32 k) external view override returns (address[] memory) {
    return addressArrayStorage[k];
  }

  function getAddressArrayItemPosition(bytes32 k, address toFind) external view override returns (uint256) {
    return addressArrayPositionMap[k][toFind];
  }

  function getAddressArrayItemByIndex(bytes32 k, uint256 i) external view override returns (address) {
    require(addressArrayStorage[k].length > i, "Invalid index");
    return addressArrayStorage[k][i];
  }

  function countAddressArrayItems(bytes32 k) external view override returns (uint256) {
    return addressArrayStorage[k].length;
  }

  function setBytes32ArrayItem(bytes32 k, bytes32 v) external override {
    if (bytes32ArrayPositionMap[k][v] == 0) {
      bytes32ArrayStorage[k].push(v);
      bytes32ArrayPositionMap[k][v] = bytes32ArrayStorage[k].length;
    }
  }

  function deleteBytes32ArrayItem(bytes32 k, bytes32 v) public override {
    require(bytes32ArrayPositionMap[k][v] > 0, "Not found");

    uint256 i = bytes32ArrayPositionMap[k][v] - 1;
    uint256 count = bytes32ArrayStorage[k].length;

    if (i + 1 != count) {
      bytes32ArrayStorage[k][i] = bytes32ArrayStorage[k][count - 1];
      bytes32 theThenLastbytes32 = bytes32ArrayStorage[k][i];
      bytes32ArrayPositionMap[k][theThenLastbytes32] = i + 1;
    }

    bytes32ArrayStorage[k].pop();
    delete bytes32ArrayPositionMap[k][v];
  }

  function deleteBytes32ArrayItemByIndex(bytes32 k, uint256 i) external override {
    require(i < bytes32ArrayStorage[k].length, "Invalid index");

    bytes32 v = bytes32ArrayStorage[k][i];
    deleteBytes32ArrayItem(k, v);
  }

  function getBytes32Array(bytes32 k) external view override returns (bytes32[] memory) {
    return bytes32ArrayStorage[k];
  }

  function getBytes32ArrayItemPosition(bytes32 k, bytes32 toFind) external view override returns (uint256) {
    return bytes32ArrayPositionMap[k][toFind];
  }

  function getBytes32ArrayItemByIndex(bytes32 k, uint256 i) external view override returns (bytes32) {
    require(bytes32ArrayStorage[k].length > i, "Invalid index");
    return bytes32ArrayStorage[k][i];
  }

  function countBytes32ArrayItems(bytes32 k) external view override returns (uint256) {
    return bytes32ArrayStorage[k].length;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../fakes/FakeStore.sol";

contract MockStore is FakeStore {
  function setBool(bytes32 prefix, address a) external {
    bytes32 k = keccak256(abi.encodePacked(prefix, a));
    this.setBool(k, true);
  }

  function unsetBool(bytes32 prefix, address a) external {
    bytes32 k = keccak256(abi.encodePacked(prefix, a));
    this.deleteBool(k);
  }

  function setAddress(
    bytes32 k1,
    bytes32 k2,
    address v
  ) public {
    this.setAddress(keccak256(abi.encodePacked(k1, k2)), v);
  }

  function setAddress(
    bytes32 k1,
    bytes32 k2,
    bytes32 k3,
    address v
  ) external {
    this.setAddress(keccak256(abi.encodePacked(k1, k2, k3)), v);
  }

  function setUint(
    bytes32 k1,
    bytes32 k2,
    uint256 v
  ) external {
    this.setUint(keccak256(abi.encodePacked(k1, k2)), v);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../base/MockStore.sol";
import "../base/MockProtocol.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../fakes/FakePriceOracle.sol";

contract MockCxTokenStore is MockStore {
  function initialize() external returns (address) {
    MockProtocol protocol = new MockProtocol();
    FakePriceOracle oracle = new FakePriceOracle();

    this.setAddress(ProtoUtilV1.CNS_CORE, address(protocol));
    this.setAddress(ProtoUtilV1.CNS_NPM_PRICE_ORACLE, address(oracle));

    return address(protocol);
  }

  function registerPolicyContract(address policy) external {
    super.setAddress(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.CNS_COVER_POLICY, policy);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/access/AccessControl.sol";

// slither-disable-next-line missing-inheritance
contract MockProtocol is AccessControl {
  bool public state = false;

  function setPaused(bool s) external {
    state = s;
  }

  function paused() external view returns (bool) {
    return state;
  }

  function setupRole(
    bytes32 role,
    bytes32 adminRole,
    address account
  ) external {
    _setRoleAdmin(role, adminRole);

    if (account != address(0)) {
      _setupRole(role, account);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../interfaces/IPriceOracle.sol";

contract FakePriceOracle is IPriceOracle {
  uint256 private _counter = 0;

  function update() external override {
    _counter++;
  }

  function consult(address, uint256 amountIn) external pure override returns (uint256) {
    return amountIn * 2;
  }

  function consultPair(uint256 amountIn) external pure override returns (uint256) {
    return amountIn;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../base/MockStore.sol";
import "../base/MockProtocol.sol";
import "./MockVault.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../fakes/FakePriceOracle.sol";

library MockProcessorStoreLib {
  function initialize(
    MockStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address cxToken
  ) external returns (address[] memory values) {
    MockProtocol protocol = new MockProtocol();
    MockVault vault = new MockVault();
    FakePriceOracle oracle = new FakePriceOracle();

    s.setAddress(ProtoUtilV1.CNS_CORE, address(protocol));
    s.setAddress(ProtoUtilV1.CNS_COVER_STABLECOIN, cxToken);
    s.setAddress(ProtoUtilV1.CNS_NPM_PRICE_ORACLE, address(oracle));

    s.setBool(ProtoUtilV1.NS_COVER_CXTOKEN, cxToken);
    s.setBool(ProtoUtilV1.NS_MEMBERS, cxToken);
    s.setUint(keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey)), 1234);

    s.setBool(ProtoUtilV1.NS_MEMBERS, address(vault));
    s.setAddress(ProtoUtilV1.NS_CONTRACTS, "cns:cover:vault", coverKey, address(vault));

    setProductStatus(s, coverKey, productKey, 4);
    setClaimBeginTimestamp(s, coverKey, productKey, block.timestamp - 100 days); // solhint-disable-line
    setClaimExpiryTimestamp(s, coverKey, productKey, block.timestamp + 100 days); // solhint-disable-line

    values = new address[](2);

    values[0] = address(protocol);
    values[1] = address(vault);
  }

  function disassociateCxToken(MockStore s, address cxToken) external {
    s.unsetBool(ProtoUtilV1.NS_COVER_CXTOKEN, cxToken);
  }

  function setProductStatus(
    MockStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 value
  ) public {
    s.setUint(keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_STATUS, coverKey, productKey)), value);
  }

  function setClaimBeginTimestamp(
    MockStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 value
  ) public {
    s.setUint(keccak256(abi.encodePacked(ProtoUtilV1.NS_CLAIM_BEGIN_TS, coverKey, productKey)), value);
  }

  function setClaimExpiryTimestamp(
    MockStore s,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 value
  ) public {
    s.setUint(keccak256(abi.encodePacked(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey)), value);
  }
}

contract MockProcessorStore is MockStore {
  function initialize(
    bytes32 coverKey,
    bytes32 productKey,
    address cxToken
  ) external returns (address[] memory values) {
    return MockProcessorStoreLib.initialize(this, coverKey, productKey, cxToken);
  }

  function disassociateCxToken(address cxToken) external {
    MockProcessorStoreLib.disassociateCxToken(this, cxToken);
  }

  function setProductStatus(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 value
  ) external {
    MockProcessorStoreLib.setProductStatus(this, coverKey, productKey, value);
  }

  function setClaimBeginTimestamp(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 value
  ) external {
    MockProcessorStoreLib.setClaimBeginTimestamp(this, coverKey, productKey, value);
  }

  function setClaimExpiryTimestamp(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 value
  ) external {
    MockProcessorStoreLib.setClaimExpiryTimestamp(this, coverKey, productKey, value);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract MockVault is ERC20 {
  constructor() ERC20("USD Coin", "USDC") {
    super._mint(msg.sender, 100_000 ether);
  }

  function transferGovernance(
    bytes32,
    address sender,
    uint256 amount
  ) external {
    if (sender != address(0)) {
      super._mint(sender, amount);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract MockCxToken is ERC20 {
  constructor() ERC20("Test", "Test") {
    super._mint(msg.sender, 1 ether);
  }

  function burn(uint256 amount) external {
    super._burn(msg.sender, amount);
  }

  function expiresOn() external view returns (uint256) {
    return block.timestamp + 30 days; // solhint-disable-line
  }

  function getClaimablePolicyOf(address) external pure returns (uint256) {
    return 1000 ether;
  }

  // slither-disable-next-line naming-convention
  function COVER_KEY() external pure returns (bytes32) {
    // solhint-disable-previous-line
    return "test";
  }

  // slither-disable-next-line naming-convention
  function PRODUCT_KEY() external pure returns (bytes32) {
    // solhint-disable-previous-line
    return "";
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract MaliciousToken is ERC20 {
  address public constant BAD = 0x0000000000000000000000000000000000000010;

  constructor() ERC20("Malicious Token", "MAL") {} // solhint-disable-line

  function mint(address account, uint256 amount) external {
    super._mint(account, amount);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(msg.sender, BAD, (amount * 10) / 100);
    _transfer(msg.sender, recipient, (amount * 90) / 100);

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    super.transferFrom(sender, BAD, (amount * 10) / 100);
    super.transferFrom(sender, recipient, (amount * 90) / 100);

    return true;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/compound/ICompoundERC20DelegatorLike.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./FakeToken.sol";

contract FaultyCompoundDaiDelegator is ICompoundERC20DelegatorLike, ERC20 {
  FakeToken public dai;
  FakeToken public cDai;
  uint256 public returnValue;

  function setReturnValue(uint256 _returnValue) external {
    returnValue = _returnValue;
  }

  constructor(
    FakeToken _dai,
    FakeToken _cDai,
    uint256 _returnValue
  ) ERC20("cDAI", "cDAI") {
    dai = _dai;
    cDai = _cDai;
    returnValue = _returnValue;
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external override returns (uint256) {
    dai.transferFrom(msg.sender, address(this), mintAmount);
    return returnValue;
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external override returns (uint256) {
    cDai.transferFrom(msg.sender, address(this), redeemTokens);
    return returnValue;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/CErc20Delegator.sol
interface ICompoundERC20DelegatorLike {
  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external returns (uint256);

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract FakeToken is ERC20 {
  address public immutable deployer;
  mapping(address => bool) public minters;
  uint8 private immutable _decimals;

  function addMinter(address account, bool flag) public onlyDeployer {
    minters[account] = flag;
  }

  modifier onlyDeployer() {
    require(msg.sender == deployer, "Forbidden");
    _;
  }

  constructor(
    string memory name,
    string memory symbol,
    uint256 supply,
    uint8 decimalPlaces
  ) ERC20(name, symbol) {
    require(decimalPlaces > 0, "Invalid decimal places value");

    super._mint(msg.sender, supply);
    deployer = msg.sender;
    minters[msg.sender] = true;
    _decimals = decimalPlaces;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function mint(uint256 amount) external {
    if (amount > 2000 * (10**_decimals)) {
      require(minters[msg.sender], "Please specify a smaller value");
    }

    super._mint(msg.sender, amount);
  }

  function burn(uint256 amount) external {
    super._burn(msg.sender, amount);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/aave/IAaveV2LendingPoolLike.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./FakeToken.sol";

contract FaultyAaveLendingPool is IAaveV2LendingPoolLike, ERC20 {
  FakeToken public aToken;

  constructor(FakeToken _aToken) ERC20("aDAI", "aDAI") {
    aToken = _aToken;
  }

  function deposit(
    address asset,
    uint256 amount,
    address,
    uint16
  ) external override {
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
  }

  function withdraw(
    address, /*asset*/
    uint256 amount,
    address /*to*/
  ) external override returns (uint256) {
    aToken.transferFrom(msg.sender, address(this), amount);
    return amount;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

// https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol
interface IAaveV2LendingPoolLike {
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
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/aave/IAaveV2LendingPoolLike.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./FakeToken.sol";

contract FakeAaveLendingPool is IAaveV2LendingPoolLike, ERC20 {
  FakeToken public aToken;

  constructor(FakeToken _aToken) ERC20("aDAI", "aDAI") {
    aToken = _aToken;
  }

  function deposit(
    address asset,
    uint256 amount,
    address,
    uint16
  ) external override {
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    aToken.mint(amount);
    aToken.transfer(msg.sender, amount);
  }

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external override returns (uint256) {
    aToken.transferFrom(msg.sender, address(this), amount);

    FakeToken dai = FakeToken(asset);

    uint256 interest = (amount * 10) / 100;
    dai.mint(interest);

    dai.transfer(to, amount + interest);

    return amount;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/Address.sol";
import "../../Recoverable.sol";
import "../../../interfaces/ILendingStrategy.sol";
import "../../../dependencies/aave/IAaveV2LendingPoolLike.sol";
import "../../../libraries/ProtoUtilV1.sol";
import "../../../libraries/StoreKeyUtil.sol";
import "../../../libraries/NTransferUtilV2.sol";

contract AaveStrategy is ILendingStrategy, Recoverable {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using RegistryLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  bytes32 private constant _KEY = keccak256(abi.encodePacked("lending", "strategy", "aave", "v2"));
  bytes32 public constant NS_DEPOSITS = "deposits";
  bytes32 public constant NS_WITHDRAWALS = "withdrawals";

  address public depositCertificate;
  IAaveV2LendingPoolLike public lendingPool;
  mapping(uint256 => bool) public supportedChains;

  mapping(bytes32 => uint256) private _counters;
  mapping(bytes32 => uint256) private _depositTotal;
  mapping(bytes32 => uint256) private _withdrawalTotal;

  constructor(
    IStore _s,
    IAaveV2LendingPoolLike _lendingPool,
    address _aToken
  ) Recoverable(_s) {
    depositCertificate = _aToken;
    lendingPool = _lendingPool;
  }

  function getDepositAsset() public view override returns (IERC20) {
    return IERC20(s.getStablecoin());
  }

  function getDepositCertificate() public view override returns (IERC20) {
    return IERC20(depositCertificate);
  }

  function _drain(IERC20 asset) private {
    uint256 amount = asset.balanceOf(address(this));

    if (amount > 0) {
      asset.ensureTransfer(s.getTreasury(), amount);
      emit Drained(asset, amount);
    }
  }

  /**
   * @dev Gets info of this strategy by cover key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the cover key
   * @param values[0] deposits Total amount deposited
   * @param values[1] withdrawals Total amount withdrawn
   */
  function getInfo(bytes32 coverKey) external view override returns (uint256[] memory values) {
    values = new uint256[](2);

    values[0] = s.getUintByKey(_getDepositsKey(coverKey));
    values[1] = s.getUintByKey(_getWithdrawalsKey(coverKey));
  }

  function _getCertificateBalance() private view returns (uint256) {
    return getDepositCertificate().balanceOf(address(this));
  }

  /**
   * @dev Lends stablecoin to the Aave protocol
   * Ensure that you `approve` stablecoin before you call this function
   *
   * @custom:suppress-acl This function is only accessible to protocol members
   * @custom:suppress-malicious-erc This tokens `aToken` and `stablecoin` are well-known addresses.
   * @custom:suppress-address-trust-issue The addresses `aToken` or `stablecoin` can't be manipulated via user input.
   *
   */
  function deposit(bytes32 coverKey, uint256 amount) external override nonReentrant returns (uint256 aTokenReceived) {
    s.mustNotBePaused();
    s.senderMustBeProtocolMember();

    IVault vault = s.getVault(coverKey);

    if (amount == 0) {
      return 0;
    }

    IERC20 stablecoin = getDepositAsset();
    IERC20 aToken = getDepositCertificate();

    require(stablecoin.balanceOf(address(vault)) >= amount, "Balance insufficient");

    // This strategy should never have token balances without any exception, especially `aToken` and `DAI`
    _drain(aToken);
    _drain(stablecoin);

    // Transfer DAI to this contract; then approve and deposit it to Aave Lending Pool to receive aToken certificates
    // stablecoin.ensureTransferFrom(fromVault, address(this), amount);

    vault.transferToStrategy(stablecoin, coverKey, getName(), amount);
    stablecoin.ensureApproval(address(lendingPool), amount);
    lendingPool.deposit(address(getDepositAsset()), amount, address(this), 0);

    // Check how many aTokens we received
    aTokenReceived = _getCertificateBalance();
    require(aTokenReceived > 0, "Deposit to Aave failed");

    // Immediately send aTokens to the original vault stablecoin came from
    aToken.ensureApproval(address(vault), aTokenReceived);
    vault.receiveFromStrategy(aToken, coverKey, getName(), aTokenReceived);

    s.addUintByKey(_getDepositsKey(coverKey), amount);

    _counters[coverKey] += 1;
    _depositTotal[coverKey] += amount;

    emit LogDeposit(getName(), _counters[coverKey], amount, aTokenReceived, _depositTotal[coverKey], _withdrawalTotal[coverKey]);
    emit Deposited(coverKey, address(vault), amount, aTokenReceived);
  }

  /**
   * @dev Redeems aToken from Aave to receive stablecoin
   * Ensure that you `approve` aToken before you call this function
   *
   * @custom:suppress-acl This function is only accessible to protocol members
   * @custom:suppress-malicious-erc This tokens `aToken` and `stablecoin` are well-known addresses.
   * @custom:suppress-address-trust-issue The addresses `aToken` or `stablecoin` can't be manipulated via user input.
   *
   */
  function withdraw(bytes32 coverKey) external virtual override nonReentrant returns (uint256 stablecoinWithdrawn) {
    s.mustNotBePaused();
    s.senderMustBeProtocolMember();

    IVault vault = s.getVault(coverKey);

    IERC20 stablecoin = getDepositAsset();
    IERC20 aToken = getDepositCertificate();

    // This strategy should never have token balances
    _drain(aToken);
    _drain(stablecoin);

    uint256 aTokenRedeemed = aToken.balanceOf(address(vault));

    if (aTokenRedeemed == 0) {
      return 0;
    }

    // Transfer aToken to this contract; then approve and send it to the Aave Lending pool get back DAI + rewards
    vault.transferToStrategy(aToken, coverKey, getName(), aTokenRedeemed);

    aToken.ensureApproval(address(lendingPool), aTokenRedeemed);
    lendingPool.withdraw(address(stablecoin), aTokenRedeemed, address(this));

    // Check how many DAI we received
    stablecoinWithdrawn = stablecoin.balanceOf(address(this));

    require(stablecoinWithdrawn > 0, "Redeeming aToken failed");

    // Immediately send DAI to the vault aToken came from
    stablecoin.ensureApproval(address(vault), stablecoinWithdrawn);
    vault.receiveFromStrategy(stablecoin, coverKey, getName(), stablecoinWithdrawn);

    s.addUintByKey(_getWithdrawalsKey(coverKey), stablecoinWithdrawn);

    _counters[coverKey] += 1;
    _withdrawalTotal[coverKey] += stablecoinWithdrawn;

    emit LogWithdrawal(getName(), _counters[coverKey], stablecoinWithdrawn, aTokenRedeemed, _depositTotal[coverKey], _withdrawalTotal[coverKey]);
    emit Withdrawn(coverKey, address(vault), stablecoinWithdrawn, aTokenRedeemed);
  }

  function _getDepositsKey(bytes32 coverKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_KEY, coverKey, NS_DEPOSITS));
  }

  function _getWithdrawalsKey(bytes32 coverKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_KEY, coverKey, NS_WITHDRAWALS));
  }

  function getWeight() external pure virtual override returns (uint256) {
    return 10_000; // 100%
  }

  function getKey() external pure override returns (bytes32) {
    return _KEY;
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() public pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_STRATEGY_AAVE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../core/liquidity/strategies/AaveStrategy.sol";

contract InvalidStrategy is AaveStrategy {
  constructor(
    IStore _s,
    IAaveV2LendingPoolLike _lendingPool,
    address _aToken
  ) AaveStrategy(_s, _lendingPool, _aToken) {} // solhint-disable-line

  function getWeight() external pure override returns (uint256) {
    return 20_000; // 100%
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../Recoverable.sol";
import "../../../interfaces/ILendingStrategy.sol";
import "../../../dependencies/compound/ICompoundERC20DelegatorLike.sol";
import "../../../libraries/ProtoUtilV1.sol";
import "../../../libraries/StoreKeyUtil.sol";
import "../../../libraries/NTransferUtilV2.sol";

contract CompoundStrategy is ILendingStrategy, Recoverable {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using RegistryLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  mapping(bytes32 => uint256) private _counters;
  mapping(bytes32 => uint256) private _depositTotal;
  mapping(bytes32 => uint256) private _withdrawalTotal;

  bytes32 private constant _KEY = keccak256(abi.encodePacked("lending", "strategy", "compound", "v2"));
  bytes32 public constant NS_DEPOSITS = "deposits";
  bytes32 public constant NS_WITHDRAWALS = "withdrawals";

  address public depositCertificate;
  ICompoundERC20DelegatorLike public delegator;
  mapping(uint256 => bool) public supportedChains;

  constructor(
    IStore _s,
    ICompoundERC20DelegatorLike _delegator,
    address _compoundWrappedStablecoin
  ) Recoverable(_s) {
    depositCertificate = _compoundWrappedStablecoin;
    delegator = _delegator;
  }

  function getDepositAsset() public view override returns (IERC20) {
    return IERC20(s.getStablecoin());
  }

  function getDepositCertificate() public view override returns (IERC20) {
    return IERC20(depositCertificate);
  }

  /**
   * @dev Gets info of this strategy by cover key
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the cover key
   * @param values[0] deposits Total amount deposited
   * @param values[1] withdrawals Total amount withdrawn
   */
  function getInfo(bytes32 coverKey) external view override returns (uint256[] memory values) {
    values = new uint256[](2);

    values[0] = s.getUintByKey(_getDepositsKey(coverKey));
    values[1] = s.getUintByKey(_getWithdrawalsKey(coverKey));
  }

  function _getCertificateBalance() private view returns (uint256) {
    return getDepositCertificate().balanceOf(address(this));
  }

  function _drain(IERC20 asset) private {
    uint256 amount = asset.balanceOf(address(this));

    if (amount > 0) {
      asset.ensureTransfer(s.getTreasury(), amount);

      emit Drained(asset, amount);
    }
  }

  /**
   * @dev Deposits the tokens to Compound
   * Ensure that you `approve` stablecoin before you call this function
   *
   * @custom:suppress-acl This function is only accessible to protocol members
   * @custom:suppress-malicious-erc This tokens `aToken` and `stablecoin` are well-known addresses.
   * @custom:suppress-address-trust-issue The addresses `compoundWrappedStablecoin` or `stablecoin` can't be manipulated via user input.
   *
   */
  function deposit(bytes32 coverKey, uint256 amount) external override nonReentrant returns (uint256 compoundWrappedStablecoinMinted) {
    s.mustNotBePaused();
    s.senderMustBeProtocolMember();

    IVault vault = s.getVault(coverKey);

    if (amount == 0) {
      return 0;
    }

    IERC20 stablecoin = getDepositAsset();
    IERC20 compoundWrappedStablecoin = getDepositCertificate();

    require(stablecoin.balanceOf(address(vault)) >= amount, "Balance insufficient");

    // This strategy should never have token balances
    _drain(compoundWrappedStablecoin);
    _drain(stablecoin);

    // Transfer DAI to this contract; then approve and send it to delegator to mint compoundWrappedStablecoin
    vault.transferToStrategy(stablecoin, coverKey, getName(), amount);
    stablecoin.ensureApproval(address(delegator), amount);

    uint256 result = delegator.mint(amount);

    require(result == 0, "Compound delegator mint failed");

    // Check how many compoundWrappedStablecoin we received
    compoundWrappedStablecoinMinted = _getCertificateBalance();

    require(compoundWrappedStablecoinMinted > 0, "Minting cUS$ failed");

    // Immediately send compoundWrappedStablecoin to the original vault stablecoin came from
    compoundWrappedStablecoin.ensureApproval(address(vault), compoundWrappedStablecoinMinted);
    vault.receiveFromStrategy(compoundWrappedStablecoin, coverKey, getName(), compoundWrappedStablecoinMinted);

    s.addUintByKey(_getDepositsKey(coverKey), amount);

    _counters[coverKey] += 1;
    _depositTotal[coverKey] += amount;

    emit LogDeposit(getName(), _counters[coverKey], amount, compoundWrappedStablecoinMinted, _depositTotal[coverKey], _withdrawalTotal[coverKey]);
    emit Deposited(coverKey, address(vault), amount, compoundWrappedStablecoinMinted);
  }

  /**
   * @dev Redeems compoundWrappedStablecoin from Compound to receive stablecoin
   * Ensure that you `approve` compoundWrappedStablecoin before you call this function
   *
   * @custom:suppress-acl This function is only accessible to protocol members
   * @custom:suppress-malicious-erc This tokens `aToken` and `stablecoin` are well-known addresses.
   * @custom:suppress-address-trust-issue The addresses `compoundWrappedStablecoin` or `stablecoin` can't be manipulated via user input.
   *
   */
  function withdraw(bytes32 coverKey) external virtual override nonReentrant returns (uint256 stablecoinWithdrawn) {
    s.mustNotBePaused();
    s.senderMustBeProtocolMember();
    IVault vault = s.getVault(coverKey);

    IERC20 stablecoin = getDepositAsset();
    IERC20 compoundWrappedStablecoin = getDepositCertificate();

    // This strategy should never have token balances without any exception, especially `compoundWrappedStablecoin` and `DAI`
    _drain(compoundWrappedStablecoin);
    _drain(stablecoin);

    uint256 compoundWrappedStablecoinRedeemed = compoundWrappedStablecoin.balanceOf(address(vault));

    if (compoundWrappedStablecoinRedeemed == 0) {
      return 0;
    }

    // Transfer compoundWrappedStablecoin to this contract; then approve and send it to delegator to redeem DAI
    vault.transferToStrategy(compoundWrappedStablecoin, coverKey, getName(), compoundWrappedStablecoinRedeemed);
    compoundWrappedStablecoin.ensureApproval(address(delegator), compoundWrappedStablecoinRedeemed);
    uint256 result = delegator.redeem(compoundWrappedStablecoinRedeemed);

    require(result == 0, "Compound delegator redeem failed");

    // Check how many DAI we received
    stablecoinWithdrawn = stablecoin.balanceOf(address(this));

    require(stablecoinWithdrawn > 0, "Redeeming cUS$ failed");

    // Immediately send DAI to the vault compoundWrappedStablecoin came from
    stablecoin.ensureApproval(address(vault), stablecoinWithdrawn);
    vault.receiveFromStrategy(stablecoin, coverKey, getName(), stablecoinWithdrawn);

    s.addUintByKey(_getWithdrawalsKey(coverKey), stablecoinWithdrawn);

    _counters[coverKey] += 1;
    _withdrawalTotal[coverKey] += stablecoinWithdrawn;

    emit LogWithdrawal(getName(), _counters[coverKey], stablecoinWithdrawn, compoundWrappedStablecoinRedeemed, _depositTotal[coverKey], _withdrawalTotal[coverKey]);
    emit Withdrawn(coverKey, address(vault), stablecoinWithdrawn, compoundWrappedStablecoinRedeemed);
  }

  function _getDepositsKey(bytes32 coverKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_KEY, coverKey, NS_DEPOSITS));
  }

  function _getWithdrawalsKey(bytes32 coverKey) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(_KEY, coverKey, NS_WITHDRAWALS));
  }

  function getWeight() external pure override returns (uint256) {
    return 10_000; // 100%
  }

  function getKey() external pure override returns (bytes32) {
    return _KEY;
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() public pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_STRATEGY_COMPOUND;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/compound/ICompoundERC20DelegatorLike.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./FakeToken.sol";

contract FakeCompoundDaiDelegator is ICompoundERC20DelegatorLike, ERC20 {
  FakeToken public dai;
  FakeToken public cDai;

  constructor(FakeToken _dai, FakeToken _cDai) ERC20("cDAI", "cDAI") {
    dai = _dai;
    cDai = _cDai;
  }

  /**
   * @notice Sender supplies assets into the market and receives cTokens in exchange
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param mintAmount The amount of the underlying asset to supply
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function mint(uint256 mintAmount) external override returns (uint256) {
    dai.transferFrom(msg.sender, address(this), mintAmount);

    cDai.mint(mintAmount);
    cDai.transfer(msg.sender, mintAmount);

    return 0;
  }

  /**
   * @notice Sender redeems cTokens in exchange for the underlying asset
   * @dev Accrues interest whether or not the operation succeeds, unless reverted
   * @param redeemTokens The number of cTokens to redeem into underlying
   * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
   */
  function redeem(uint256 redeemTokens) external override returns (uint256) {
    cDai.transferFrom(msg.sender, address(this), redeemTokens);

    uint256 interest = (redeemTokens * 3) / 100;
    dai.mint(interest);

    dai.transfer(msg.sender, redeemTokens + interest);

    return 0;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
// import "../../interfaces/IVault.sol";
import "../Recoverable.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/StrategyLibV1.sol";
import "../../interfaces/ILendingStrategy.sol";
import "../../interfaces/ILiquidityEngine.sol";

/**
 * @title Liquidity Engine contract
 * @dev The liquidity engine contract enables liquidity manager(s)
 * to add, disable, remove, or manage lending or other income strategies.
 *
 */
contract LiquidityEngine is ILiquidityEngine, Recoverable {
  using RegistryLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using StrategyLibV1 for IStore;
  using ValidationLibV1 for IStore;

  constructor(IStore s) Recoverable(s) {} // solhint-disable-line

  /**
   * @dev Adds an array of strategies to the liquidity engine.
   * @param strategies Enter one or more strategies.
   */
  function addStrategies(address[] calldata strategies) external override nonReentrant {
    require(strategies.length > 0, "No strategy specified");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);

    s.addStrategiesInternal(strategies);
  }

  /**
   * @dev The liquidity state update interval allows the protocol
   * to perform various activies such as NPM token price update,
   * deposits or withdrawals to lending strategies, and more.
   *
   * @param value Specify the update interval value
   *
   */
  function setLiquidityStateUpdateInterval(uint256 value) external override nonReentrant {
    require(value > 0, "Invalid value");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);

    s.setUintByKey(ProtoUtilV1.NS_LIQUIDITY_STATE_UPDATE_INTERVAL, value);
    emit LiquidityStateUpdateIntervalSet(value);
  }

  /**
   * @dev Disables a strategy by address.
   * When a strategy is disabled, it immediately withdraws and cannot lend any further.
   *
   * @custom:suppress-address-trust-issue This instance of stablecoin can be trusted because of the ACL requirement.
   *
   * @param strategy Enter the strategy contract address to disable
   */
  function disableStrategy(address strategy) external override nonReentrant {
    // because this function can only be invoked by a liquidity manager.
    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);

    s.disableStrategyInternal(strategy);
    emit StrategyDisabled(strategy);
  }

  /**
   * @dev Permanently deletes a disabled strategy by address.
   *
   * @custom:suppress-address-trust-issue This instance of strategy can be trusted because of the ACL requirement.
   *
   * @param strategy Enter the strategy contract address to delete
   */
  function deleteStrategy(address strategy) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);

    s.deleteStrategyInternal(strategy);
    emit StrategyDeleted(strategy);
  }

  /**
   * @dev In order to pool risks collectively, liquidity providers
   * may lend their stablecoins to a cover pool of their choosing during "lending periods"
   * and withdraw them during "withdrawal windows." These periods are known as risk pooling periods.
   *
   * <br /> <br />
   *
   * The default lending period is six months, and the withdrawal window is seven days.
   * Specify a cover key if you want to configure or override these periods for a cover.
   * If no cover key is specified, the values entered will be set as global parameters.
   *
   * @param coverKey Enter a cover key to set the periods. Enter `0x` if you want to set the values globally.
   * @param lendingPeriod Enter the lending duration. Example: 180 days.
   * @param withdrawalWindow Enter the withdrawal duration. Example: 7 days.
   *
   */
  function setRiskPoolingPeriods(
    bytes32 coverKey,
    uint256 lendingPeriod,
    uint256 withdrawalWindow
  ) external override nonReentrant {
    require(lendingPeriod > 0, "Please specify lending period");
    require(withdrawalWindow > 0, "Please specify withdrawal window");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);

    s.setRiskPoolingPeriodsInternal(coverKey, lendingPeriod, withdrawalWindow);
    // event emitted in the above function
  }

  /**
   * @dev Specify the maximum lending ratio a strategy can utilize, not to exceed 100 percent.
   *
   * @param ratio. Enter the ratio as a percentage value. Use `ProtoUtilV1.MULTIPLIER` as your divisor.
   *
   */
  function setMaxLendingRatio(uint256 ratio) external override nonReentrant {
    require(ratio > 0, "Please specify lending ratio");
    require(ratio <= ProtoUtilV1.MULTIPLIER, "Invalid lending ratio");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);

    s.setMaxLendingRatioInternal(ratio);
  }

  /**
   * @dev Gets the maximum lending ratio a strategy can utilize.
   */
  function getMaxLendingRatio() external view override returns (uint256 ratio) {
    return s.getMaxLendingRatioInternal();
  }

  /**
   * @dev Returns the risk pooling periods of a given cover key.
   * Global values are returned if the risk pooling period for the given cover key was not defined.
   * If global values are also undefined, fallback value of 180-day lending period
   * and 7-day withdrawal window are returned.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the coverkey to retrieve the lending period of.
   * Warning: this function doesn't check if the supplied cover key is a valid.
   *
   */
  function getRiskPoolingPeriods(bytes32 coverKey) external view override returns (uint256 lendingPeriod, uint256 withdrawalWindow) {
    return s.getRiskPoolingPeriodsInternal(coverKey);
  }

  /**
   * @dev Returns a list of disabled strategies.
   */
  function getDisabledStrategies() external view override returns (address[] memory strategies) {
    return s.getDisabledStrategiesInternal();
  }

  /**
   * @dev Returns a list of actively lending strategies.
   */
  function getActiveStrategies() external view override returns (address[] memory strategies) {
    return s.getActiveStrategiesInternal();
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_LIQUIDITY_ENGINE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IMember.sol";

pragma solidity ^0.8.0;

interface ILiquidityEngine is IMember {
  event StrategyAdded(address indexed strategy);
  event StrategyDisabled(address indexed strategy);
  event StrategyDeleted(address indexed strategy);
  event RiskPoolingPeriodSet(bytes32 indexed coverKey, uint256 lendingPeriod, uint256 withdrawalWindow);
  event LiquidityStateUpdateIntervalSet(uint256 duration);
  event MaxLendingRatioSet(uint256 ratio);

  function addStrategies(address[] calldata strategies) external;

  function disableStrategy(address strategy) external;

  function deleteStrategy(address strategy) external;

  function setRiskPoolingPeriods(
    bytes32 coverKey,
    uint256 lendingPeriod,
    uint256 withdrawalWindow
  ) external;

  function getRiskPoolingPeriods(bytes32 coverKey) external view returns (uint256 lendingPeriod, uint256 withdrawalWindow);

  function setLiquidityStateUpdateInterval(uint256 value) external;

  function setMaxLendingRatio(uint256 ratio) external;

  function getMaxLendingRatio() external view returns (uint256 ratio);

  function getDisabledStrategies() external view returns (address[] memory strategies);

  function getActiveStrategies() external view returns (address[] memory strategies);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/interfaces/IERC3156FlashLender.sol";

contract MockFlashBorrower is IERC3156FlashBorrower {
  IERC20 private _stablecoin;
  IERC3156FlashLender private _provider;
  bytes32 private _returnValue = keccak256("ERC3156FlashBorrower.onFlashLoan");
  bool private _createsApproval = true;

  constructor(IERC20 stablecoin, IERC3156FlashLender provider) {
    _stablecoin = stablecoin;
    _provider = provider;
  }

  function setStablecoin(IERC20 value) external {
    _stablecoin = value;
  }

  function setReturnValue(bytes32 value) external {
    _returnValue = value;
  }

  function setCreateApproval(bool value) external {
    _createsApproval = value;
  }

  function borrow(uint256 amount, bytes calldata data) external {
    uint256 allowance = _stablecoin.allowance(address(this), address(_provider));
    uint256 fee = _provider.flashFee(address(_stablecoin), amount);
    uint256 repayment = amount + fee;

    if (_createsApproval) {
      _stablecoin.approve(address(_provider), allowance + repayment);
    }

    _provider.flashLoan(this, address(_stablecoin), amount, data);
  }

  function onFlashLoan(
    address initiator,
    address, /*token*/
    uint256, /*amount*/
    uint256, /*fee*/
    bytes calldata /*data*/
  ) external view override returns (bytes32) {
    require(msg.sender == address(_provider), "FlashBorrower: Untrusted lender");
    require(initiator == address(this), "FlashBorrower: Untrusted loan initiator"); // solhint-disable-line
    return _returnValue;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/interfaces/IERC3156FlashLender.sol";
import "./VaultStrategy.sol";

abstract contract WithFlashLoan is VaultStrategy, IERC3156FlashLender {
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * Flash loan feature
   * Uses the hooks `preFlashLoan` and `postFlashLoan` on the vault delegate contract.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-malicious-erc This ERC-20 `s.getStablecoin()` is a well-known address.
   * @custom:suppress-pausable
   * @custom:suppress-address-trust-issue The address `stablecoin` can't be manipulated via user input.
   *
   * @param receiver Specify the contract that receives the flash loan.
   * @param token Specify the token you want to borrow.
   * @param amount Enter the amount you would like to borrow.
   */
  function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
  ) external override nonReentrant returns (bool) {
    require(amount > 0, "Please specify amount");

    /******************************************************************************************
      PRE
     ******************************************************************************************/
    (IERC20 stablecoin, uint256 fee, uint256 protocolFee) = delgate().preFlashLoan(msg.sender, key, receiver, token, amount, data);

    /******************************************************************************************
      BODY
     ******************************************************************************************/
    uint256 previousBalance = stablecoin.balanceOf(address(this));
    // require(previousBalance >= amount, "Balance insufficient"); <-- already checked in `preFlashLoan` --> `getFlashFeesInternal`

    stablecoin.ensureTransfer(address(receiver), amount);
    require(receiver.onFlashLoan(msg.sender, token, amount, fee, data) == keccak256("ERC3156FlashBorrower.onFlashLoan"), "IERC3156: Callback failed");
    stablecoin.ensureTransferFrom(address(receiver), address(this), amount + fee);

    uint256 finalBalance = stablecoin.balanceOf(address(this));
    require(finalBalance >= previousBalance + fee, "Access is denied");

    // Transfer protocol fee to the treasury
    stablecoin.ensureTransfer(s.getTreasury(), protocolFee);

    /******************************************************************************************
      POST
     ******************************************************************************************/

    delgate().postFlashLoan(msg.sender, key, receiver, token, amount, data);

    emit FlashLoanBorrowed(address(this), address(receiver), token, amount, fee);

    return true;
  }

  /**
   * @dev Gets the fee required to borrow the spefied token and given amount of the loan.
   */
  function flashFee(address token, uint256 amount) external view override returns (uint256) {
    return delgate().getFlashFee(msg.sender, key, token, amount);
  }

  /**
   * @dev Gets maximum amount in the specified token units that can be borrowed.
   */
  function maxFlashLoan(address token) external view override returns (uint256) {
    return delgate().getMaxFlashLoan(msg.sender, key, token);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "./VaultLiquidity.sol";

pragma solidity ^0.8.0;

abstract contract VaultStrategy is VaultLiquidity {
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  uint256 private _transferToStrategyEntry = 0;
  uint256 private _receiveFromStrategyEntry = 0;

  /**
   * @dev Transfers tokens to strategy contract(s).
   * Uses the hooks `preTransferToStrategy` and `postTransferToStrategy` on the vault delegate contract.
   *
   * @custom:suppress-acl This function is only callable by correct strategy contract as checked in `preTransferToStrategy` and `postTransferToStrategy`
   * @custom:suppress-reentrancy Custom reentrancy guard implemented
   * @custom:suppress-pausable
   *
   */
  function transferToStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external override {
    require(address(token) != address(0), "Invalid token to transfer");
    require(coverKey == key, "Forbidden");
    require(strategyName > 0, "Invalid strategy");
    require(amount > 0, "Please specify amount");

    // Reentrancy check
    require(_transferToStrategyEntry == 0, "Access is denied");

    _transferToStrategyEntry = 1;

    /******************************************************************************************
      PRE
     ******************************************************************************************/
    delgate().preTransferToStrategy(msg.sender, token, coverKey, strategyName, amount);

    /******************************************************************************************
      BODY
     ******************************************************************************************/

    token.ensureTransfer(msg.sender, amount);

    /******************************************************************************************
      POST
     ******************************************************************************************/
    delgate().postTransferToStrategy(msg.sender, token, coverKey, strategyName, amount);

    emit StrategyTransfer(address(token), msg.sender, strategyName, amount);
    _transferToStrategyEntry = 0;
  }

  /**
   * @dev Receives tokens from strategy contract(s).
   * Uses the hooks `preReceiveFromStrategy` and `postReceiveFromStrategy` on the vault delegate contract.
   *
   * @custom:suppress-acl This function is only callable by correct strategy contract as checked in `preReceiveFromStrategy` and `postReceiveFromStrategy`
   * @custom:suppress-reentrancy Custom reentrancy guard implemented
   * @custom:suppress-pausable Validated in `preReceiveFromStrategy` and `postReceiveFromStrategy`
   *
   */
  function receiveFromStrategy(
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external override {
    require(coverKey == key, "Forbidden");
    require(_receiveFromStrategyEntry == 0, "Access is denied");
    require(amount > 0, "Please specify amount");

    _receiveFromStrategyEntry = 1;

    /******************************************************************************************
      PRE
     ******************************************************************************************/
    delgate().preReceiveFromStrategy(msg.sender, token, coverKey, strategyName, amount);

    /******************************************************************************************
      BODY
     ******************************************************************************************/

    token.ensureTransferFrom(msg.sender, address(this), amount);

    /******************************************************************************************
      POST
     ******************************************************************************************/
    (uint256 income, uint256 loss) = delgate().postReceiveFromStrategy(msg.sender, token, coverKey, strategyName, amount);

    emit StrategyReceipt(address(token), msg.sender, strategyName, amount, income, loss);
    _receiveFromStrategyEntry = 0;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "./VaultBase.sol";

pragma solidity ^0.8.0;

abstract contract VaultLiquidity is VaultBase {
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Transfers stablecoins to claims processor contracts for claims payout.
   * Uses the hooks `preTransferGovernance` and `postTransferGovernance` on the vault delegate contract.
   *
   * @custom:suppress-acl This function is only callable by the claims processor as checked in `preTransferGovernance` and `postTransferGovernace`
   * @custom:suppress-pausable
   *
   */
  function transferGovernance(
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external override nonReentrant {
    require(coverKey == key, "Forbidden");
    require(amount > 0, "Please specify amount");

    /******************************************************************************************
      PRE
     ******************************************************************************************/
    address stablecoin = delgate().preTransferGovernance(msg.sender, coverKey, to, amount);

    /******************************************************************************************
      BODY
     ******************************************************************************************/

    IERC20(stablecoin).ensureTransfer(to, amount);

    /******************************************************************************************
      POST
     ******************************************************************************************/
    delgate().postTransferGovernance(msg.sender, coverKey, to, amount);
    emit GovernanceTransfer(to, amount);
  }

  /**
   * @dev Adds liquidity to the specified cover contract.
   * Uses the hooks `preAddLiquidity` and `postAddLiquidity` on the vault delegate contract.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-pausable
   *
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to supply.
   * @param npmStakeToAdd Enter the amount of NPM token to stake.
   *
   */
  function addLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStakeToAdd,
    bytes32 referralCode
  ) external override nonReentrant {
    require(coverKey == key, "Forbidden");
    require(amount > 0, "Please specify amount");

    /******************************************************************************************
      PRE
     ******************************************************************************************/

    (uint256 podsToMint, uint256 previousNpmStake) = delgate().preAddLiquidity(msg.sender, coverKey, amount, npmStakeToAdd);

    require(podsToMint > 0, "Can't determine PODs");

    /******************************************************************************************
      BODY
     ******************************************************************************************/

    IERC20(sc).ensureTransferFrom(msg.sender, address(this), amount);

    if (npmStakeToAdd > 0) {
      IERC20(s.getNpmTokenAddress()).ensureTransferFrom(msg.sender, address(this), npmStakeToAdd);
    }

    super._mint(msg.sender, podsToMint);

    /******************************************************************************************
      POST
     ******************************************************************************************/

    delgate().postAddLiquidity(msg.sender, coverKey, amount, npmStakeToAdd);

    emit PodsIssued(msg.sender, podsToMint, amount, referralCode);

    if (previousNpmStake == 0) {
      emit Entered(coverKey, msg.sender);
    }

    emit NpmStaken(msg.sender, npmStakeToAdd);
  }

  /**
   * @dev Removes liquidity from the specified cover contract
   * Uses the hooks `preRemoveLiquidity` and `postRemoveLiquidity` on the vault delegate contract.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-pausable
   *
   * @param coverKey Enter the cover key
   * @param podsToRedeem Enter the amount of pods to redeem
   * @param npmStakeToRemove Enter the amount of NPM stake to remove.
   */
  function removeLiquidity(
    bytes32 coverKey,
    uint256 podsToRedeem,
    uint256 npmStakeToRemove,
    bool exit
  ) external override nonReentrant {
    require(coverKey == key, "Forbidden");
    require(podsToRedeem > 0, "Please specify amount");

    /******************************************************************************************
      PRE
     ******************************************************************************************/
    (address stablecoin, uint256 stablecoinToRelease) = delgate().preRemoveLiquidity(msg.sender, coverKey, podsToRedeem, npmStakeToRemove, exit);

    /******************************************************************************************
      BODY
     ******************************************************************************************/
    IERC20(address(this)).ensureTransferFrom(msg.sender, address(this), podsToRedeem);
    IERC20(stablecoin).ensureTransfer(msg.sender, stablecoinToRelease);

    super._burn(address(this), podsToRedeem);

    // Unstake NPM tokens
    if (npmStakeToRemove > 0) {
      IERC20(s.getNpmTokenAddress()).ensureTransfer(msg.sender, npmStakeToRemove);
    }

    /******************************************************************************************
      POST
     ******************************************************************************************/
    delgate().postRemoveLiquidity(msg.sender, coverKey, podsToRedeem, npmStakeToRemove, exit);

    emit PodsRedeemed(msg.sender, podsToRedeem, stablecoinToRelease);

    if (exit) {
      emit Exited(coverKey, msg.sender);
    }

    if (npmStakeToRemove > 0) {
      emit NpmUnstaken(msg.sender, npmStakeToRemove);
    }
  }

  /**
   * @dev Calculates the amount of PODS to mint for the given amount of liquidity to transfer
   */
  function calculatePods(uint256 forStablecoinUnits) external view override returns (uint256) {
    return delgate().calculatePodsImplementation(key, forStablecoinUnits);
  }

  /**
   * @dev Calculates the amount of stablecoins to withdraw for the given amount of PODs to redeem
   */
  function calculateLiquidity(uint256 podsToBurn) external view override returns (uint256) {
    return delgate().calculateLiquidityImplementation(key, podsToBurn);
  }

  /**
   * @dev Returns the stablecoin balance of this vault
   * This also includes amounts lent out in lending strategies
   */
  function getStablecoinBalanceOf() external view override returns (uint256) {
    return delgate().getStablecoinBalanceOfImplementation(key);
  }

  /**
   * @dev Accrues interests from external straties
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-pausable Validated in `accrueInterestImplementation`
   *
   */
  function accrueInterest() external override nonReentrant {
    delgate().accrueInterestImplementation(msg.sender, key);
    emit InterestAccrued(key);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../Recoverable.sol";
import "../../interfaces/IVaultDelegate.sol";
import "../../interfaces/IVault.sol";
import "../../libraries/NTransferUtilV2.sol";

pragma solidity ^0.8.0;

/**
 * @title Vault Base Contract
 */
abstract contract VaultBase is ERC20, Recoverable, IVault {
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  bytes32 public override key;
  address public override sc;

  /**
   * @dev Contructs this contract
   *
   * @param store Provide store instance
   * @param coverKey Provide a cover key that doesn't have a vault deployed
   * @param tokenName Enter the token name of the POD. Example: `Uniswap nDAI` or `Uniswap nUSDC`
   * @param tokenSymbol Enter the token symbol of the POD. Example: UNI-NDAI or `UNI-NUSDC`.
   * @param stablecoin Provide an instance of the stablecoin this vault supports.
   *
   */
  constructor(
    IStore store,
    bytes32 coverKey,
    string memory tokenName,
    string memory tokenSymbol,
    IERC20 stablecoin
  ) ERC20(tokenName, tokenSymbol) Recoverable(store) {
    key = coverKey;
    sc = address(stablecoin);
  }

  /**
   * @dev Returns the delegate contract instance
   */
  function delgate() public view returns (IVaultDelegate) {
    address delegate = s.getVaultDelegate();
    return IVaultDelegate(delegate);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IMember.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/interfaces/IERC3156FlashLender.sol";

interface IVaultDelegate is IMember {
  function preAddLiquidity(
    address caller,
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake
  ) external returns (uint256 podsToMint, uint256 previousNpmStake);

  function postAddLiquidity(
    address caller,
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake
  ) external;

  function accrueInterestImplementation(address caller, bytes32 coverKey) external;

  function preRemoveLiquidity(
    address caller,
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bool exit
  ) external returns (address stablecoin, uint256 stableCoinToRelease);

  function postRemoveLiquidity(
    address caller,
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bool exit
  ) external;

  function preTransferGovernance(
    address caller,
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external returns (address stablecoin);

  function postTransferGovernance(
    address caller,
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external;

  function preTransferToStrategy(
    address caller,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  function postTransferToStrategy(
    address caller,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  function preReceiveFromStrategy(
    address caller,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external;

  function postReceiveFromStrategy(
    address caller,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external returns (uint256 income, uint256 loss);

  function preFlashLoan(
    address caller,
    bytes32 coverKey,
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
  )
    external
    returns (
      IERC20 stablecoin,
      uint256 fee,
      uint256 protocolFee
    );

  function postFlashLoan(
    address caller,
    bytes32 coverKey,
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
  ) external;

  function calculatePodsImplementation(bytes32 coverKey, uint256 forStablecoinUnits) external view returns (uint256);

  function calculateLiquidityImplementation(bytes32 coverKey, uint256 podsToBurn) external view returns (uint256);

  function getInfoImplementation(bytes32 coverKey, address forAccount) external view returns (uint256[] memory result);

  function getStablecoinBalanceOfImplementation(bytes32 coverKey) external view returns (uint256);

  function getFlashFee(
    address caller,
    bytes32 coverKey,
    address token,
    uint256 amount
  ) external view returns (uint256);

  function getMaxFlashLoan(
    address caller,
    bytes32 coverKey,
    address token
  ) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IClaimsProcessor.sol";

// @title NPM Store Interface
interface IStoreLike {
  function getAddress(bytes32 k) external view returns (address);
}

/**
 * @title Neptune Mutual Distributor contract
 * @dev The distributor contract enables resellers to interact with
 * the Neptune Mutual protocol and offer policies to their users.
 *
 * This contract demonstrates how a distributor may charge an extra fee
 * and deposit the proceeds in their own treasury account.
 */
contract NpmDistributor is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeERC20 for IVault;

  event PolicySold(
    bytes32 indexed coverKey,
    bytes32 indexed productKey,
    address indexed cxToken,
    address account,
    uint256 duration,
    uint256 protection,
    bytes32 referralCode,
    uint256 fee,
    uint256 premium
  );
  event LiquidityAdded(bytes32 indexed coverKey, address indexed account, bytes32 indexed referralCode, uint256 amount, uint256 npmStake);
  event LiquidityRemoved(bytes32 indexed coverKey, address indexed account, uint256 amount, uint256 npmStake, bool exit);
  event Drained(IERC20 indexed token, address indexed to, uint256 amount);

  bytes32 public constant NS_CONTRACTS = "ns:contracts";
  bytes32 public constant CNS_CLAIM_PROCESSOR = "cns:claim:processor";
  bytes32 public constant CNS_COVER_VAULT = "cns:cover:vault";
  bytes32 public constant CNS_COVER_POLICY = "cns:cover:policy";
  bytes32 public constant CNS_COVER_STABLECOIN = "cns:cover:sc";
  bytes32 public constant CNS_NPM_INSTANCE = "cns:core:npm:instance";

  uint256 public constant MULTIPLIER = 10_000;
  uint256 public immutable feePercentage;
  address public immutable treasury;
  IStoreLike public immutable store;

  /**
   * @dev Constructs this contract
   * @param _store Enter the address of NPM protocol store
   * @param _treasury Enter your treasury wallet address
   * @param _feePercentage Enter distributor fee percentage
   */
  constructor(
    IStoreLike _store,
    address _treasury,
    uint256 _feePercentage
  ) {
    require(address(_store) != address(0), "Invalid store");
    require(_treasury != address(0), "Invalid treasury");
    require(_feePercentage > 0 && _feePercentage < MULTIPLIER, "Invalid fee percentage");

    store = _store;
    treasury = _treasury;
    feePercentage = _feePercentage;
  }

  /**
   * @dev Returns the stablecoin used by the protocol in this blockchain.
   */
  function getStablecoin() public view returns (IERC20) {
    return IERC20(store.getAddress(CNS_COVER_STABLECOIN));
  }

  /**
   * @dev Returns NPM token instance in this blockchain.
   */
  function getNpm() public view returns (IERC20) {
    return IERC20(store.getAddress(CNS_NPM_INSTANCE));
  }

  /**
   * @dev Returns the protocol policy contract instance.
   */
  function getPolicyContract() public view returns (IPolicy) {
    return IPolicy(store.getAddress(keccak256(abi.encodePacked(NS_CONTRACTS, CNS_COVER_POLICY))));
  }

  /**
   * @dev Returns the vault contract instance by the given key.
   */
  function getVaultContract(bytes32 coverKey) public view returns (IVault) {
    return IVault(store.getAddress(keccak256(abi.encodePacked(NS_CONTRACTS, CNS_COVER_VAULT, coverKey))));
  }

  /**
   * @dev Returns the protocol claims processor contract instance.
   */
  function getClaimsProcessorContract() external view returns (IClaimsProcessor) {
    return IClaimsProcessor(store.getAddress(keccak256(abi.encodePacked(NS_CONTRACTS, CNS_CLAIM_PROCESSOR))));
  }

  /**
   * @dev Calculates the premium required to purchase policy.
   * @param coverKey Enter the cover key for which you want to buy policy.
   * @param duration Enter the period of the protection in months.
   * @param protection Enter the stablecoin dollar amount you want to protect.
   */
  function getPremium(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 duration,
    uint256 protection
  ) public view returns (uint256 premium, uint256 fee) {
    IPolicy policy = getPolicyContract();
    require(address(policy) != address(0), "Fatal: Policy missing");

    (premium, , , , , ) = policy.getCoverFeeInfo(coverKey, productKey, duration, protection);

    // Add your fee in addition to the protocol premium
    fee = (premium * feePercentage) / MULTIPLIER;
  }

  /**
   * @dev Purchases a new policy on behalf of your users.
   *
   * Prior to using this method, you must first call the "getPremium" function
   * and approve the policy fees that this contract would spend.
   *
   * In the event that this function succeeds, the recipient's wallet will be
   * credited with "cxToken". Take note that the "claimPolicy" method may be
   * used in the future to reclaim cxTokens and receive payouts
   * after the resolution of an incident.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-pausable
   *
   * @param coverKey Enter the cover key for which you want to buy policy.
   * @param duration Enter the period of the protection in months.
   * @param protection Enter the stablecoin dollar amount you want to protect.
   * @param referralCode Provide a referral code if applicable.
   */
  function purchasePolicy(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 duration,
    uint256 protection,
    bytes32 referralCode
  ) external nonReentrant {
    require(coverKey > 0, "Invalid key");
    require(duration > 0 && duration < 4, "Invalid duration");
    require(protection > 0, "Invalid protection amount");

    IPolicy policy = getPolicyContract();
    require(address(policy) != address(0), "Fatal: Policy missing");

    IERC20 dai = getStablecoin();
    require(address(dai) != address(0), "Fatal: DAI missing");

    // Get fee info
    (uint256 premium, uint256 fee) = getPremium(coverKey, productKey, duration, protection);

    // Transfer DAI to this contract
    dai.safeTransferFrom(msg.sender, address(this), premium + fee);

    // Approve protocol to pull the protocol fee
    dai.safeIncreaseAllowance(address(policy), premium);

    // Purchase protection for this user
    (address cxTokenAt, ) = policy.purchaseCover(msg.sender, coverKey, productKey, duration, protection, referralCode);

    // Send your fee (+ any remaining DAI balance) to your treasury address
    dai.safeTransfer(treasury, dai.balanceOf(address(this)));

    emit PolicySold(coverKey, productKey, cxTokenAt, msg.sender, duration, protection, referralCode, fee, premium);
  }

  function addLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bytes32 referralCode
  ) external nonReentrant {
    require(coverKey > 0, "Invalid key");
    require(amount > 0, "Invalid amount");

    IVault nDai = getVaultContract(coverKey);
    IERC20 dai = getStablecoin();
    IERC20 npm = getNpm();

    require(address(nDai) != address(0), "Fatal: Vault missing");
    require(address(dai) != address(0), "Fatal: DAI missing");
    require(address(npm) != address(0), "Fatal: NPM missing");

    // Before moving forward, first drain all balances of this contract
    _drain(nDai);
    _drain(dai);
    _drain(npm);

    // Transfer DAI from sender's wallet here
    dai.safeTransferFrom(msg.sender, address(this), amount);

    // Approve the Vault (or nDai) contract to spend DAI
    dai.safeIncreaseAllowance(address(nDai), amount);

    if (npmStake > 0) {
      // Transfer NPM from the sender's wallet here
      npm.safeTransferFrom(msg.sender, address(this), npmStake);

      // Approve the Vault (or nDai) contract to spend NPM
      npm.safeIncreaseAllowance(address(nDai), npmStake);
    }

    nDai.addLiquidity(coverKey, amount, npmStake, referralCode);

    nDai.safeTransfer(msg.sender, nDai.balanceOf(address(this)));

    emit LiquidityAdded(coverKey, msg.sender, referralCode, amount, npmStake);
  }

  function removeLiquidity(
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStake,
    bool exit
  ) external nonReentrant {
    require(coverKey > 0, "Invalid key");
    require(amount > 0, "Invalid amount");

    IVault nDai = getVaultContract(coverKey);
    IERC20 dai = getStablecoin();
    IERC20 npm = getNpm();

    require(address(nDai) != address(0), "Fatal: Vault missing");
    require(address(dai) != address(0), "Fatal: DAI missing");
    require(address(npm) != address(0), "Fatal: NPM missing");

    // Before moving forward, first drain all balances of this contract
    _drain(nDai);
    _drain(dai);
    _drain(npm);

    // Transfer nDai from sender's wallet here
    nDai.safeTransferFrom(msg.sender, address(this), amount);

    // Approve the Vault (or nDai) contract to spend nDai
    nDai.safeIncreaseAllowance(address(nDai), amount);

    nDai.removeLiquidity(coverKey, amount, npmStake, exit);

    dai.safeTransfer(msg.sender, nDai.balanceOf(address(this)));

    emit LiquidityRemoved(coverKey, msg.sender, amount, npmStake, exit);
  }

  /**
   * @dev Drains a given token to the treasury address
   */
  function _drain(IERC20 token) private {
    uint256 balance = token.balanceOf(address(this));

    if (balance > 0) {
      token.safeTransfer(treasury, balance);
      emit Drained(token, treasury, balance);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/IStore.sol";
import "../../interfaces/ICoverReassurance.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/NTransferUtilV2.sol";
import "../../libraries/GovernanceUtilV1.sol";
import "../Recoverable.sol";

/**
 * @title Cover Reassurance
 *
 * @dev A covered project can add reassurance fund to exhibit coverage support for their project.
 * This reduces the cover fee and increases the confidence of liquidity providers.
 * A portion of the reassurance fund is awarded to liquidity providers in the event of a cover incident.
 *
 * <br />
 *
 * - [https://docs.neptunemutual.com/sdk/cover-assurance](https://docs.neptunemutual.com/sdk/cover-assurance)
 * - [https://docs.neptunemutual.com/definitions/cover-products](https://docs.neptunemutual.com/definitions/cover-products)
 *
 */
contract CoverReassurance is ICoverReassurance, Recoverable {
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using NTransferUtilV2 for IERC20;
  using CoverUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using RegistryLibV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using GovernanceUtilV1 for IStore;

  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Adds reassurance to the specified cover contract
   *
   * @custom:suppress-acl Reassurance can only be added by cover owner or latest cover contract
   * @custom:suppress-malicious-erc This ERC-20 `s.getStablecoin()` is a well-known address.
   *
   * @param coverKey Enter the cover key
   * @param account Specify the account from which the reassurance fund will be transferred.
   * @param amount Enter the amount you would like to supply
   *
   */
  function addReassurance(
    bytes32 coverKey,
    address account,
    uint256 amount
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeValidCoverKey(coverKey);
    s.mustBeCoverOwnerOrCoverContract(coverKey, msg.sender);

    require(amount > 0, "Provide valid amount");

    IERC20 stablecoin = IERC20(s.getStablecoin());

    s.addUintByKey(CoverUtilV1.getReassuranceKey(coverKey), amount);

    stablecoin.ensureTransferFrom(account, address(this), amount);

    // Do not update state during cover creation
    // s.updateStateAndLiquidity(coverKey);

    emit ReassuranceAdded(coverKey, amount);
  }

  /**
   * @dev Sets the reassurance weight as a percentage value.
   *
   * @custom:note About the Reassurance Weight:
   *
   * When you set a weight to reassurance fund, it used to
   * calculate the adjusted reassurance capital available for a cover pool.
   *
   * ```
   * adjusted reassurance fund = (reassurance balance * reassurancePoolWeight) / multiplier
   * ```
   *
   * Since the reassurance fund gets capitalized to its liquidity pool after an incident resolution,
   * the adjusted amount is therefore regarded as an additional capital available to a cover risks
   * for that pool. This helps lower the policy premium fees.
   *
   * @param coverKey Enter the cover key for which you want to set the weight. You can
   * provide `0x` as cover key if you want to set reassurance weight globally.
   * @param weight Enter the weight value as percentage (see ProtoUtilV1.MULTIPLIER).
   * You can't exceed 100%.
   *
   */
  function setWeight(bytes32 coverKey, uint256 weight) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);
    s.mustBeValidCoverKey(coverKey);

    require(weight > 0 && weight <= ProtoUtilV1.MULTIPLIER, "Please specify weight");

    s.setUintByKey(CoverUtilV1.getReassuranceWeightKey(coverKey), weight);

    s.updateStateAndLiquidity(coverKey);

    emit WeightSet(coverKey, weight);
  }

  /**
   * @dev Capitalizes the cover liquidity pool (or Vault) with whichever
   * is less between 25% of the suffered loss or 25% of the reassurance pool balance.
   *
   * <br /> <br />
   *
   * This function can only be invoked if the specified cover was "claimable"
   * and after "claim period" is over.
   *
   * @param coverKey Enter the cover key that has suffered capital depletion or loss.
   * @param productKey Enter the product key that has suffered capital depletion or loss.
   * @param incidentDate Enter the date of the incident report.
   *
   */
  function capitalizePool(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external override nonReentrant {
    require(incidentDate > 0, "Please specify incident date");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeLiquidityManager(s);
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeAfterResolutionDeadline(coverKey, productKey);
    s.mustBeClaimable(coverKey, productKey);
    s.mustBeAfterClaimExpiry(coverKey, productKey);

    IVault vault = s.getVault(coverKey);
    IERC20 stablecoin = IERC20(s.getStablecoin());

    uint256 toTransfer = s.getReassuranceTransferrableInternal(coverKey, productKey, incidentDate);

    require(toTransfer > 0, "Nothing to capitalize");

    stablecoin.ensureTransfer(address(vault), toTransfer);
    s.subtractUintByKey(CoverUtilV1.getReassuranceKey(coverKey), toTransfer);
    s.addReassurancePayoutInternal(coverKey, productKey, incidentDate, toTransfer);

    emit PoolCapitalized(coverKey, productKey, incidentDate, toTransfer);
  }

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the cover key
   */
  function getReassurance(bytes32 coverKey) external view override returns (uint256) {
    return s.getReassuranceAmountInternal(coverKey);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_COVER_REASSURANCE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../libraries/ValidationLibV1.sol";

contract MockValidationLibUser {
  using ValidationLibV1 for IStore;
  IStore public s;

  constructor(IStore store) {
    s = store;
  }

  function senderMustBePolicyManagerContract() external view {
    s.senderMustBePolicyManagerContract();
  }

  function senderMustBeGovernanceContract() external view {
    s.senderMustBeGovernanceContract();
  }

  function senderMustBeClaimsProcessorContract() external view {
    s.senderMustBeClaimsProcessorContract();
  }

  function senderMustBeStrategyContract() external view {
    s.senderMustBeStrategyContract();
  }

  function mustBeDisputed(bytes32 coverKey, bytes32 productKey) external view {
    s.mustBeDisputed(coverKey, productKey);
  }

  function mustHaveNormalProductStatus(bytes32 coverKey, bytes32 productKey) external view {
    s.mustHaveNormalProductStatus(coverKey, productKey);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/IVault.sol";
import "../../interfaces/IVaultFactory.sol";
import "../../libraries/VaultFactoryLibV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../Recoverable.sol";

/**
 * @title Vault Factory Contract
 *
 * @dev When a new cover is created, an associated liquidity pool or vault is also created.
 * The cover contract deploys new vaults on demand by utilizing the vault factory contract.
 *
 */
contract VaultFactory is IVaultFactory, Recoverable {
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;

  /**
   * @dev Constructs this contract
   * @param store Provide the store contract instance
   */
  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Deploys a new instance of Vault
   *
   * @custom:suppress-acl This function is only accessilbe to the cover contract
   *
   * @param coverKey Enter the cover key related to this Vault instance
   */
  function deploy(
    bytes32 coverKey,
    string calldata tokenName,
    string calldata tokenSymbol
  ) external override nonReentrant returns (address addr) {
    s.mustNotBePaused();
    s.senderMustBeCoverContract();

    (bytes memory bytecode, bytes32 salt) = VaultFactoryLibV1.getByteCode(s, coverKey, tokenName, tokenSymbol, s.getStablecoin());

    // solhint-disable-next-line
    assembly {
      addr := create2(
        callvalue(), // wei sent with current call
        // Actual code starts after skipping the first 32 bytes
        add(bytecode, 0x20),
        mload(bytecode), // Load the size of code contained in the first 32 bytes
        salt // Salt from function arguments
      )

      if iszero(extcodesize(addr)) {
        // @suppress-revert This is correct usage
        revert(0, 0)
      }
    }

    emit VaultDeployed(coverKey, addr);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_VAULT_FACTORY;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../core/liquidity/Vault.sol";

library VaultFactoryLibV1 {
  /**
   * @dev Gets the bytecode of the `Vault` contract
   * @param s Provide the store instance
   * @param coverKey Provide the cover key
   * @param stablecoin Specify the liquidity token for this Vault
   */
  function getByteCode(
    IStore s,
    bytes32 coverKey,
    string calldata tokenName,
    string calldata tokenSymbol,
    address stablecoin
  ) external pure returns (bytes memory bytecode, bytes32 salt) {
    salt = keccak256(abi.encodePacked(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.CNS_COVER_VAULT, coverKey));

    //slither-disable-next-line too-many-digits
    bytecode = abi.encodePacked(type(Vault).creationCode, abi.encode(s, coverKey, tokenName, tokenSymbol, stablecoin));
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/interfaces/IERC3156FlashLender.sol";
import "./WithFlashLoan.sol";

pragma solidity ^0.8.0;

/**
 * @title Vault Contract
 *
 * @dev When a cover is created, a corresponding liquidity pool is also constituted.
 * An instance of this contract represents the liquidity pool of a cover.
 * The vaults are denominated in a single stablecoin and may be less susceptible
 * to underwriting risks associated with cryptocurrency price volatility.
 *
 * <br /> <br />
 *
 * When requested by the Cover Contract, the VaultFactory contract deploys a vault.
 * Per cover, only one vault is permitted. Since the vault contract is not upgradable,
 * some of the validation logic of it is outsourced to the VaultDelegate contract.
 *
 * <br /> <br />
 *
 * The vault contract is also an ERC-20 token, commonly known as POD (or Proof of Deposit).
 * As there is always on-chain stablecoin liquidity available for withdrawal,
 * PODs are fully redeemable and also income or loss bearing certificates
 *  (loss if the cover had an event that resulted in a claims payout).
 *
 * Unlike [cxTokens](cxToken.md), PODs can be freely transferred, staked,
 * and exchanged on secondary marketplaces.
 *
 * <br /> <br />
 *
 * **Disclaimer:**
 * <br /> <br />
 *
 * **The protocol does not provide any warranty, guarantee, or endorsement
 * for the peg of this stablecoin or any other stablecoin we may use on a different chain.**
 *
 * <br /> <br />
 *
 * Both risk poolers (underwriters) and policyholders
 * must agree to utilize the same stablecoin to interfact with the protocol.
 *
 * Note that the Neptune Mutual protocol only covers risks related to smart contracts and,
 * to a certain extent, frontend attacks. We don't cover risks arising from
 * teams losing private keys because of gross misconduct or negligence.
 * We don't cover people who put their money at risk in trading activities
 * like margin calls, leverage trading, or liquidation.
 * We don't cover 51% attack or any other type of consensus attack.
 * We don't cover bridge hacks and a [whole variety of other exclusions](https://docs.neptunemutual.com/usage/standard-exclusions).
 *
 */
contract Vault is WithFlashLoan {
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;

  /**
   * @dev Contructs this contract
   *
   * @param store Provide store instance
   * @param coverKey Provide a cover key that doesn't have a vault deployed
   * @param tokenName Enter the token name of the POD. Example: `Uniswap nDAI` or `Uniswap nUSDC`
   * @param tokenSymbol Enter the token symbol of the POD. Example: UNI-NDAI or `UNI-NUSDC`.
   * @param stablecoin Provide an instance of the stablecoin this vault supports.
   *
   */
  constructor(
    IStore store,
    bytes32 coverKey,
    string memory tokenName,
    string memory tokenSymbol,
    IERC20 stablecoin
  ) VaultBase(store, coverKey, tokenName, tokenSymbol, stablecoin) {} // solhint-disable-line

  /**
   * @dev Gets information of a given vault by the cover key
   *
   * Warning: this function does not validate the input argument.
   *
   * @param you The address for which the info will be customized
   * @param values[0] totalPods --> Total PODs in existence
   * @param values[1] balance --> Stablecoins held in the vault
   * @param values[2] extendedBalance --> Stablecoins lent outside of the protocol
   * @param values[3] totalReassurance -- > Total reassurance for this cover
   * @param values[4] myPodBalance --> Your POD Balance
   * @param values[5] myShare --> My share of the liquidity pool (in stablecoin)
   * @param values[6] withdrawalOpen --> The timestamp when withdrawals are opened
   * @param values[7] withdrawalClose --> The timestamp when withdrawals are closed again
   *
   */
  function getInfo(address you) external view override returns (uint256[] memory values) {
    return delgate().getInfoImplementation(key, you);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_LIQUIDITY_VAULT;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./CoverBase.sol";
import "../../interfaces/ICoverStake.sol";
import "../../interfaces/ICoverStake.sol";
import "../../interfaces/IVault.sol";
import "../liquidity/Vault.sol";

/**
 * @title Cover Contract
 * @dev The cover contract enables you to manage onchain covers.
 *
 */
contract Cover is CoverBase {
  using AccessControlLibV1 for IStore;
  using CoverLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using RoutineInvokerLibV1 for IStore;

  /**
   * @dev Constructs this contract
   * @param store Enter the store
   */
  constructor(IStore store) CoverBase(store) {} // solhint-disable-line

  /**
   * @dev Adds a new coverage pool or cover contract.
   * To add a new cover, you need to pay cover creation fee
   * and stake minimum amount of NPM in the Vault. <br /> <br />
   *
   * Through the governance portal, projects will be able redeem
   * the full cover fee at a later date. <br /> <br />
   *
   * **Apply for Fee Redemption** <br />
   *
   * https://docs.neptunemutual.com/covers/cover-fee-redemption <br /><br />
   *
   * Read the documentation to learn more about the fees: <br />
   * https://docs.neptunemutual.com/covers/contract-creators
   *
   *
   * @custom:suppress-acl This is a publicly accessible feature. Can only be called by a whitelisted address.
   *
   * @param coverKey Enter a unique key for this cover
   * @param info IPFS hash. Check out the [documentation](https://docs.neptunemutual.com/sdk/managing-covers) for more info.
   * @param tokenName Enter the token name of the POD contract that will be deployed.
   * @param tokenSymbol Enter the token name of the POD contract that will be deployed.
   * @param supportsProducts Indicates that this cover supports product(s)
   * @param requiresWhitelist Signifies if this cover only enables whitelisted addresses to purchase policies.
   * @param values[0] stakeWithFee Enter the total NPM amount (stake + fee) to transfer to this contract.
   * @param values[1] initialReassuranceAmount **Optional.** Enter the initial amount of
   * reassurance tokens you'd like to add to this pool.
   * @param values[2] minStakeToReport A cover creator can override default min NPM stake to avoid spam reports
   * @param values[3] reportingPeriod The period during when reporting happens.
   * @param values[4] cooldownperiod Enter the cooldown period for governance.
   * @param values[5] claimPeriod Enter the claim period.
   * @param values[6] floor Enter the policy floor rate.
   * @param values[7] ceiling Enter the policy ceiling rate.
   * @param values[8] reassuranceRate Enter the reassurance rate.
   * @param values[9] leverageFactor Leverage Factor
   */
  function addCover(
    bytes32 coverKey,
    bytes32 info,
    string calldata tokenName,
    string calldata tokenSymbol,
    bool supportsProducts,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external override nonReentrant returns (address) {
    s.mustNotBePaused();
    s.senderMustBeWhitelistedCoverCreator();

    require(values[0] >= s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_MIN_STAKE), "Your stake is too low");

    s.addCoverInternal(coverKey, supportsProducts, info, requiresWhitelist, values);

    emit CoverCreated(coverKey, info, tokenName, tokenSymbol, supportsProducts, requiresWhitelist);

    address vault = s.deployVaultInternal(coverKey, tokenName, tokenSymbol);
    emit VaultDeployed(coverKey, vault);

    return vault;
  }

  /**
   * @dev Updates the cover contract.
   * This feature is accessible only to the cover manager during withdrawal period.
   *
   * @param coverKey Enter the cover key
   * @param info IPFS hash. Check out the [documentation](https://docs.neptunemutual.com/sdk/managing-covers) for more info.
   */
  function updateCover(bytes32 coverKey, bytes32 info) external override nonReentrant {
    s.mustNotBePaused();
    s.mustEnsureAllProductsAreNormal(coverKey);
    AccessControlLibV1.mustBeCoverManager(s);
    s.mustBeDuringWithdrawalPeriod(coverKey);

    require(s.getBytes32ByKeys(ProtoUtilV1.NS_COVER_INFO, coverKey) != info, "Duplicate content");

    s.updateCoverInternal(coverKey, info);
    emit CoverUpdated(coverKey, info);
  }

  /**
   * @dev Adds a product under a diversified cover pool
   *
   * @custom:suppress-acl This function can only be accessed by the cover owner or an admin
   *
   * @param coverKey Enter a cover key
   * @param productKey Enter the product key
   * @param info IPFS hash. Check out the [documentation](https://docs.neptunemutual.com/sdk/managing-covers) for more info.
   * @param values[0] Product status
   * @param values[1] Enter the capital efficiency ratio in percentage value (Check ProtoUtilV1.MULTIPLIER for division)
   *
   */
  function addProduct(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external override {
    // @suppress-zero-value-check The uint values are validated in the function `addProductInternal`
    s.mustNotBePaused();
    s.senderMustBeWhitelistedCoverCreator();
    s.senderMustBeCoverOwnerOrAdmin(coverKey);

    s.addProductInternal(coverKey, productKey, info, requiresWhitelist, values);
    emit ProductCreated(coverKey, productKey, info, requiresWhitelist, values);
  }

  /**
   * @dev Updates a cover product.
   * This feature is accessible only to the cover manager during withdrawal period.
   *
   * @param coverKey Enter the cover key
   * @param productKey Enter the product key
   * @param info Enter a new IPFS URL to update
   * @param values[0] Product status
   * @param values[1] Enter the capital efficiency ratio in percentage value (Check ProtoUtilV1.MULTIPLIER for division)
   *
   */
  function updateProduct(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256[] calldata values
  ) external override {
    // @suppress-zero-value-check The uint values are validated in the function `updateProductInternal`
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    AccessControlLibV1.mustBeCoverManager(s);
    s.mustBeDuringWithdrawalPeriod(coverKey);

    s.updateProductInternal(coverKey, productKey, info, values);
    emit ProductUpdated(coverKey, productKey, info, values);
  }

  /**
   * @dev Allows disabling and enabling the purchase of policy for a product or cover.
   *
   * This function enables governance admin to disable or enable the purchase of policy for a product or cover.
   * A cover contract when stopped restricts new policy purchases
   * and frees up liquidity as policies expires.
   *
   * 1. The policy purchases can be disabled and later enabled after current policies expire and liquidity is withdrawn.
   * 2. The policy purchases can be disabled temporarily to allow liquidity providers a chance to exit.
   *
   * @param coverKey Enter the cover key you want to disable policy purchases
   * @param productKey Enter the product key you want to disable policy purchases
   * @param status Set this to true if you disable or false to enable policy purchases
   * @param reason Provide a reason to disable the policy purchases
   *
   */
  function disablePolicy(
    bytes32 coverKey,
    bytes32 productKey,
    bool status,
    string calldata reason
  ) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeGovernanceAdmin(s);
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);

    require(status != s.isPolicyDisabledInternal(coverKey, productKey), status ? "Already disabled" : "Already enabled");

    s.disablePolicyInternal(coverKey, productKey, status);

    emit ProductStateUpdated(coverKey, productKey, msg.sender, status, reason);
  }

  /**
   * @dev Adds or removes an account to the cover creator whitelist.
   * For the first version of the protocol, a cover creator has to be whitelisted
   * before they can call the `addCover` function.
   * @param account Enter the address of the cover creator
   * @param status Set this to true if you want to add to or false to remove from the whitelist
   *
   */
  function updateCoverCreatorWhitelist(address account, bool status) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeGovernanceAgent(s);

    s.updateCoverCreatorWhitelistInternal(account, status);
    emit CoverCreatorWhitelistUpdated(account, status);
  }

  /**
   * @dev Adds or removes an account to the cover user whitelist.
   * Whitelisting is an optional feature cover creators can enable.
   *
   * @custom:suppress-acl This function is only accessilbe to the cover owner or admin
   *
   * @param accounts Enter a list of accounts you would like to update the whitelist statuses of.
   * @param statuses Enter respective statuses of the specified whitelisted accounts.
   *
   */
  function updateCoverUsersWhitelist(
    bytes32 coverKey,
    bytes32 productKey,
    address[] calldata accounts,
    bool[] calldata statuses
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.senderMustBeCoverOwnerOrAdmin(coverKey);

    s.updateCoverUsersWhitelistInternal(coverKey, productKey, accounts, statuses);
  }

  /**
   * @dev Signifies if the given account is a whitelisted cover creator
   */
  function checkIfWhitelistedCoverCreator(address account) external view override returns (bool) {
    return s.getAddressBooleanByKey(ProtoUtilV1.NS_COVER_CREATOR_WHITELIST, account);
  }

  /**
   * @dev Signifies if the given account is a whitelisted user
   */
  function checkIfWhitelistedUser(
    bytes32 coverKey,
    bytes32 productKey,
    address account
  ) external view override returns (bool) {
    return s.getAddressBooleanByKeys(ProtoUtilV1.NS_COVER_USER_WHITELIST, coverKey, productKey, account);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/IStore.sol";
import "../../interfaces/ICover.sol";
import "../../libraries/CoverLibV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../Recoverable.sol";

/**
 * @title Base Cover Contract
 *
 */
abstract contract CoverBase is ICover, Recoverable {
  using CoverLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;

  /**
   * @dev Constructs this smart contract
   * @param store Provide the address of an eternal storage contract to use.
   * This contract must be a member of the Protocol for write access to the storage
   *
   */
  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Initializes this contract
   *
   * @custom:warning Warning:
   *
   * This is a one-time setup. The stablecoin contract address can't be updated once set.
   *
   * @custom:suppress-address-trust-issue This instance of stablecoin can be trusted because of the ACL requirement.
   * @custom:suppress-initialization Can only be initialized once by a cover manager
   *
   * @param stablecoin Provide the address of the token this cover will be quoted against.
   * @param friendlyName Enter a description or ENS name of your liquidity token.
   *
   */
  function initialize(address stablecoin, bytes32 friendlyName) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    require(s.getAddressByKey(ProtoUtilV1.CNS_COVER_STABLECOIN) == address(0), "Already initialized");

    s.initializeCoverInternal(stablecoin, friendlyName);
    emit CoverInitialized(stablecoin, friendlyName);
  }

  /**
   * @dev Sets the cover creation fee
   *
   * @param value Enter the cover creation fee in NPM token units
   */
  function setCoverCreationFee(uint256 value) external override nonReentrant {
    require(value > 0, "Please specify value");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    uint256 previous = s.setCoverCreationFeeInternal(value);
    emit CoverCreationFeeSet(previous, value);
  }

  /**
   * @dev Sets minimum stake to create a new cover
   *
   * @param value Enter the minimum cover creation stake in NPM token units
   */
  function setMinCoverCreationStake(uint256 value) external override nonReentrant {
    require(value > 0, "Please specify value");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    uint256 previous = s.setMinCoverCreationStakeInternal(value);
    emit MinCoverCreationStakeSet(previous, value);
  }

  /**
   * @dev Sets minimum stake to add liquidity
   *
   * @custom:note Please note that liquidity providers can remove 100% stake
   * and exit their NPM stake position whenever they want to, provided they do it during
   * a "withdrawal window".
   *
   * @param value Enter the minimum stake to add liquidity.
   */
  function setMinStakeToAddLiquidity(uint256 value) external override nonReentrant {
    require(value > 0, "Please specify value");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    uint256 previous = s.setMinStakeToAddLiquidityInternal(value);
    emit MinStakeToAddLiquiditySet(previous, value);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_COVER;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../interfaces/IStore.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./AccessControlLibV1.sol";
import "./CoverUtilV1.sol";
import "./RegistryLibV1.sol";
import "./StoreKeyUtil.sol";
import "./RoutineInvokerLibV1.sol";
import "./StrategyLibV1.sol";

library CoverLibV1 {
  using CoverUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using ProtoUtilV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using AccessControlLibV1 for IStore;
  using ValidationLibV1 for IStore;
  using StrategyLibV1 for IStore;

  event CoverUserWhitelistUpdated(bytes32 indexed coverKey, bytes32 indexed productKey, address indexed account, bool status);

  /**
   * Initializes cover
   *
   * @custom:suppress-address-trust-issue This instance of stablecoin can be trusted because of the ACL requirement.
   * @custom:suppress-initialization Can only be initialized once by a cover manager. Check caller.
   *
   * @param stablecoin Provide the address of the token this cover will be quoted against.
   * @param friendlyName Enter a description or ENS name of your liquidity token.
   *
   */
  function initializeCoverInternal(
    IStore s,
    address stablecoin,
    bytes32 friendlyName
  ) external {
    s.setAddressByKey(ProtoUtilV1.CNS_COVER_STABLECOIN, stablecoin);
    s.setBytes32ByKey(ProtoUtilV1.NS_COVER_STABLECOIN_NAME, friendlyName);

    s.updateStateAndLiquidity(0);
  }

  /**
   * @dev Adds a new coverage pool or cover contract.
   * To add a new cover, you need to pay cover creation fee
   * and stake minimum amount of NPM in the Vault. <br /> <br />
   *
   * Through the governance portal, projects will be able redeem
   * the full cover fee at a later date. <br /> <br />
   *
   * **Apply for Fee Redemption** <br />
   * https://docs.neptunemutual.com/covers/cover-fee-redemption <br /><br />
   *
   * As the cover creator, you will earn a portion of all cover fees
   * generated in this pool. <br /> <br />
   *
   * Read the documentation to learn more about the fees: <br />
   * https://docs.neptunemutual.com/covers/contract-creators
   *
   * @param s Provide store instance
   * @param coverKey Enter a unique key for this cover
   * @param info IPFS info of the cover contract
   * @param values[0] stakeWithFee Enter the total NPM amount (stake + fee) to transfer to this contract.
   * @param values[1] initialReassuranceAmount **Optional.** Enter the initial amount of
   * @param values[2] minStakeToReport A cover creator can override default min NPM stake to avoid spam reports
   * @param values[3] reportingPeriod The period during when reporting happens.
   * reassurance tokens you'd like to add to this pool.
   * @param values[4] cooldownperiod Enter the cooldown period for governance.
   * @param values[5] claimPeriod Enter the claim period.
   * @param values[6] floor Enter the policy floor rate.
   * @param values[7] ceiling Enter the policy ceiling rate.
   * @param values[8] reassuranceRate Enter the reassurance rate.
   */
  function addCoverInternal(
    IStore s,
    bytes32 coverKey,
    bool supportsProducts,
    bytes32 info,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external {
    // First validate the information entered
    (uint256 fee, ) = _validateAndGetFee(s, coverKey, info, values[0]);

    // Set the basic cover info
    _addCover(s, coverKey, supportsProducts, info, requiresWhitelist, values, fee);

    // Stake the supplied NPM tokens and burn the fees
    s.getStakingContract().increaseStake(coverKey, msg.sender, values[0], fee);

    // Add cover reassurance
    if (values[1] > 0) {
      s.getReassuranceContract().addReassurance(coverKey, msg.sender, values[1]);
    }
  }

  function _addCover(
    IStore s,
    bytes32 coverKey,
    bool supportsProducts,
    bytes32 info,
    bool requiresWhitelist,
    uint256[] calldata values,
    uint256 fee
  ) private {
    require(coverKey > 0, "Invalid cover key");
    require(info > 0, "Invalid info");
    require(values[2] > 0, "Invalid min reporting stake");
    require(values[3] > 0, "Invalid reporting period");
    require(values[4] > 0, "Invalid cooldown period");
    require(values[5] > 0, "Invalid claim period");
    require(values[6] > 0, "Invalid floor rate");
    require(values[7] > 0, "Invalid ceiling rate");
    require(values[8] > 0, "Invalid reassurance rate");
    require(values[9] > 0 && values[9] < 25, "Invalid leverage");

    if (supportsProducts == false) {
      // Standalone pools do not support any leverage
      require(values[9] == 1, "Invalid leverage");
    }

    s.setBoolByKeys(ProtoUtilV1.NS_COVER, coverKey, true);

    s.setBoolByKeys(ProtoUtilV1.NS_COVER_SUPPORTS_PRODUCTS, coverKey, supportsProducts);
    s.setAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, coverKey, msg.sender);
    s.setBytes32ByKeys(ProtoUtilV1.NS_COVER_INFO, coverKey, info);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_REASSURANCE_WEIGHT, coverKey, ProtoUtilV1.MULTIPLIER); // 100% weight because it's a stablecoin

    // Set the fee charged during cover creation
    s.setUintByKeys(ProtoUtilV1.NS_COVER_CREATION_FEE_EARNING, coverKey, fee);

    s.setUintByKeys(ProtoUtilV1.NS_COVER_CREATION_DATE, coverKey, block.timestamp); // solhint-disable-line

    s.setBoolByKeys(ProtoUtilV1.NS_COVER_REQUIRES_WHITELIST, coverKey, requiresWhitelist);

    s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, coverKey, values[2]);
    s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_PERIOD, coverKey, values[3]);
    s.setUintByKeys(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD, coverKey, values[4]);
    s.setUintByKeys(ProtoUtilV1.NS_CLAIM_PERIOD, coverKey, values[5]);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR, coverKey, values[6]);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING, coverKey, values[7]);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_REASSURANCE_RATE, coverKey, values[8]);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_LEVERAGE_FACTOR, coverKey, values[9]);
  }

  function addProductInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    bool requiresWhitelist,
    uint256[] calldata values
  ) external {
    s.mustBeValidCoverKey(coverKey);
    s.mustSupportProducts(coverKey);

    require(productKey > 0, "Invalid product key");
    require(info > 0, "Invalid info");

    // Product Status
    // 0 --> Deleted
    // 1 --> Active
    // 2 --> Retired
    require(values[0] == 1, "Status must be active");
    require(values[1] > 0 && values[1] <= 10_000, "Invalid efficiency");

    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey) == false, "Already exists");

    s.setBoolByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey, true);
    s.setBytes32ByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey, info);
    s.setBytes32ArrayByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey);
    s.setBoolByKeys(ProtoUtilV1.NS_COVER_REQUIRES_WHITELIST, coverKey, productKey, requiresWhitelist);

    s.setUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey, values[0]);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT_EFFICIENCY, coverKey, productKey, values[1]);
  }

  function updateProductInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256[] calldata values
  ) external {
    require(values[0] <= 2, "Invalid product status");
    require(values[1] > 0 && values[1] <= 10_000, "Invalid efficiency");

    s.mustBeValidCoverKey(coverKey);
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);

    s.setUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey, values[0]);
    s.setUintByKeys(ProtoUtilV1.NS_COVER_PRODUCT_EFFICIENCY, coverKey, productKey, values[1]);
    s.setBytes32ByKeys(ProtoUtilV1.NS_COVER_PRODUCT, coverKey, productKey, info);
  }

  function deployVaultInternal(
    IStore s,
    bytes32 coverKey,
    string calldata tokenName,
    string calldata tokenSymbol
  ) external returns (address) {
    address vault = s.getProtocolContract(ProtoUtilV1.CNS_COVER_VAULT, coverKey);
    require(vault == address(0), "Vault already deployed");

    // Deploy cover liquidity contract
    address deployed = s.getVaultFactoryContract().deploy(coverKey, tokenName, tokenSymbol);

    s.getProtocol().addContractWithKey(ProtoUtilV1.CNS_COVER_VAULT, coverKey, address(deployed));
    return deployed;
  }

  /**
   * @dev Validation checks before adding a new cover
   */
  function _validateAndGetFee(
    IStore s,
    bytes32 coverKey,
    bytes32 info,
    uint256 stakeWithFee
  ) private view returns (uint256 fee, uint256 minCoverCreationStake) {
    require(info > 0, "Invalid info");
    (fee, minCoverCreationStake, ) = s.getCoverCreationFeeInfo();

    uint256 minStake = fee + minCoverCreationStake;

    require(stakeWithFee > minStake, "NPM Insufficient");
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, coverKey) == false, "Already exists");
  }

  function updateCoverInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 info
  ) external {
    s.setBytes32ByKeys(ProtoUtilV1.NS_COVER_INFO, coverKey, info);
  }

  function updateCoverCreatorWhitelistInternal(
    IStore s,
    address account,
    bool status
  ) external {
    s.setAddressBooleanByKey(ProtoUtilV1.NS_COVER_CREATOR_WHITELIST, account, status);
  }

  function _updateCoverUserWhitelistInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address account,
    bool status
  ) private {
    s.setAddressBooleanByKeys(ProtoUtilV1.NS_COVER_USER_WHITELIST, coverKey, productKey, account, status);
    emit CoverUserWhitelistUpdated(coverKey, productKey, account, status);
  }

  function updateCoverUsersWhitelistInternal(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    address[] calldata accounts,
    bool[] calldata statuses
  ) external {
    require(accounts.length == statuses.length, "Inconsistent array sizes");

    for (uint256 i = 0; i < accounts.length; i++) {
      _updateCoverUserWhitelistInternal(s, coverKey, productKey, accounts[i], statuses[i]);
    }
  }

  function setCoverCreationFeeInternal(IStore s, uint256 value) external returns (uint256 previous) {
    previous = s.getUintByKey(ProtoUtilV1.NS_COVER_CREATION_FEE);
    s.setUintByKey(ProtoUtilV1.NS_COVER_CREATION_FEE, value);

    s.updateStateAndLiquidity(0);
  }

  function setMinCoverCreationStakeInternal(IStore s, uint256 value) external returns (uint256 previous) {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    previous = s.getMinCoverCreationStake();
    s.setUintByKey(ProtoUtilV1.NS_COVER_CREATION_MIN_STAKE, value);

    s.updateStateAndLiquidity(0);
  }

  function setMinStakeToAddLiquidityInternal(IStore s, uint256 value) external returns (uint256 previous) {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    previous = s.getMinStakeToAddLiquidity();
    s.setUintByKey(ProtoUtilV1.NS_COVER_LIQUIDITY_MIN_STAKE, value);

    s.updateStateAndLiquidity(0);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/ICoverStake.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/NTransferUtilV2.sol";
import "../Recoverable.sol";

/**
 * @title Cover Stake
 * @dev When you create a new cover, you have to specify the amount of
 * NPM tokens you wish to stake as a cover creator.
 *
 * <br /> <br />
 *
 * To demonstrate support for a cover pool, anyone can add and remove
 * NPM stakes (minimum required). The higher the sake, the more visibility
 * the contract gets if there are multiple cover contracts with the same name
 * or similar terms. Even when there are no duplicate contract, a higher stake
 * would normally imply a better cover pool commitment.
 *
 */
contract CoverStake is ICoverStake, Recoverable {
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using CoverUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using NTransferUtilV2 for IERC20;
  using RoutineInvokerLibV1 for IStore;

  /**
   * @dev Constructs this contract
   * @param store Provide the store contract instance
   */
  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Increase the stake of the given cover pool
   *
   * @custom:suppress-acl Can only be accessed by the latest cover contract
   *
   * @param coverKey Enter the cover key
   * @param account Enter the account from where the NPM tokens will be transferred
   * @param amount Enter the amount of stake
   * @param fee Enter the fee amount. Note: do not enter the fee if you are directly calling this function.
   *
   */
  function increaseStake(
    bytes32 coverKey,
    address account,
    uint256 amount,
    uint256 fee
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeValidCoverKey(coverKey);
    s.senderMustBeCoverContract();

    require(amount >= fee, "Invalid fee");

    s.npmToken().ensureTransferFrom(account, address(this), amount);

    if (fee > 0) {
      s.npmToken().ensureTransfer(s.getBurnAddress(), fee);
      emit FeeBurned(coverKey, fee);
    }

    // @suppress-subtraction Checked usage. Fee is always less than amount
    // if we reach this far.
    s.addUintByKeys(ProtoUtilV1.NS_COVER_STAKE, coverKey, amount - fee);
    s.addUintByKeys(ProtoUtilV1.NS_COVER_STAKE_OWNED, coverKey, account, amount - fee);

    emit StakeAdded(coverKey, account, amount - fee);
  }

  /**
   * @dev Decreases the stake from the given cover pool.
   * A cover creator can withdraw their full stake after 365 days
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of stake to decrease
   *
   */
  function decreaseStake(bytes32 coverKey, uint256 amount) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeValidCoverKey(coverKey);
    s.mustEnsureAllProductsAreNormal(coverKey);

    uint256 drawingPower = _getDrawingPower(coverKey, msg.sender);
    require(amount > 0, "Please specify amount");
    require(drawingPower >= amount, "Exceeds your drawing power");

    // @suppress-subtraction
    s.subtractUintByKeys(ProtoUtilV1.NS_COVER_STAKE, coverKey, amount);
    s.subtractUintByKeys(ProtoUtilV1.NS_COVER_STAKE_OWNED, coverKey, msg.sender, amount);

    s.npmToken().ensureTransfer(msg.sender, amount);

    s.updateStateAndLiquidity(coverKey);

    emit StakeRemoved(coverKey, msg.sender, amount);
  }

  /**
   * @dev Gets the stake of an account for the given cover key
   * @param coverKey Enter the cover key
   * @param account Specify the account to obtain the stake of
   * @return Returns the total stake of the specified account on the given cover key
   *
   */
  function stakeOf(bytes32 coverKey, address account) public view override returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE_OWNED, coverKey, account);
  }

  /**
   * @dev Gets the drawing power of (the stake amount that can be withdrawn from)
   * an account.
   * @param coverKey Enter the cover key
   * @param account Specify the account to obtain the drawing power of
   * @return Returns the drawing power of the specified account on the given cover key
   *
   */
  function _getDrawingPower(bytes32 coverKey, address account) private view returns (uint256) {
    uint256 createdAt = s.getCoverCreationDate(coverKey);
    uint256 yourStake = stakeOf(coverKey, account);
    bool isOwner = account == s.getCoverOwner(coverKey);

    uint256 minStakeRequired = block.timestamp > createdAt + 365 days ? 0 : s.getMinCoverCreationStake(); // solhint-disable-line

    return isOwner ? yourStake - minStakeRequired : yourStake;
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_COVER_STAKE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../libraries/RegistryLibV1.sol";

contract MockRegistryClient {
  using RegistryLibV1 for IStore;
  IStore public s;

  constructor(IStore store) {
    s = store;
  }

  function getGovernanceContract() external view returns (IGovernance) {
    return s.getGovernanceContract();
  }

  function getPolicyContract() external view returns (IPolicy) {
    return s.getPolicyContract();
  }

  function getBondPoolContract() external view returns (IBondPool) {
    return s.getBondPoolContract();
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../libraries/AccessControlLibV1.sol";
import "../../libraries/ProtoUtilV1.sol";

contract MockAccessControlUser {
  using AccessControlLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  IStore public s;

  constructor(IStore store) {
    s = store;
  }

  function callerMustBeAdmin(address caller) external view {
    s.callerMustBeAdmin(caller);
  }

  function callerMustBeCoverManager(address caller) external view {
    s.callerMustBeCoverManager(caller);
  }

  function callerMustBeGovernanceAgent(address caller) external view {
    s.callerMustBeGovernanceAgent(caller);
  }

  function callerMustBeGovernanceAdmin(address caller) external view {
    s.callerMustBeGovernanceAdmin(caller);
  }

  function callerMustBeRecoveryAgent(address caller) external view {
    s.callerMustBeRecoveryAgent(caller);
  }

  function callerMustBePauseAgent(address caller) external view {
    s.callerMustBePauseAgent(caller);
  }

  function callerMustBeUnpauseAgent(address caller) external view {
    s.callerMustBeUnpauseAgent(caller);
  }

  function hasAccess(bytes32 role, address user) external view returns (bool) {
    return s.hasAccess(role, user);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/governance/TimelockController.sol";
import "./WithRecovery.sol";

contract Delayable is TimelockController, WithRecovery {
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) TimelockController(minDelay, proposers, executors) {} // solhint-disable-line
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/IStore.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract StoreBase is IStore, Pausable, Ownable {
  using SafeERC20 for IERC20;

  mapping(bytes32 => int256) public intStorage;
  mapping(bytes32 => uint256) public uintStorage;
  mapping(bytes32 => uint256[]) public uintsStorage;
  mapping(bytes32 => address) public addressStorage;
  mapping(bytes32 => mapping(address => bool)) public addressBooleanStorage;
  mapping(bytes32 => string) public stringStorage;
  mapping(bytes32 => bytes) public bytesStorage;
  mapping(bytes32 => bytes32) public bytes32Storage;
  mapping(bytes32 => bool) public boolStorage;
  mapping(bytes32 => address[]) public addressArrayStorage;
  mapping(bytes32 => mapping(address => uint256)) public addressArrayPositionMap;
  mapping(bytes32 => bytes32[]) public bytes32ArrayStorage;
  mapping(bytes32 => mapping(bytes32 => uint256)) public bytes32ArrayPositionMap;

  bytes32 private constant _NS_MEMBERS = "ns:members";

  constructor() {
    boolStorage[keccak256(abi.encodePacked(_NS_MEMBERS, msg.sender))] = true;
    boolStorage[keccak256(abi.encodePacked(_NS_MEMBERS, address(this)))] = true;
  }

  /**
   * @dev Recover all Ether held by the contract.
   * @custom:suppress-reentrancy Risk tolerable. Can only be called by the owner.
   * @custom:suppress-pausable Risk tolerable. Can only be called by the owner.
   */
  function recoverEther(address sendTo) external onlyOwner {
    // slither-disable-next-line arbitrary-send
    payable(sendTo).transfer(address(this).balance);
  }

  /**
   * @dev Recover all IERC-20 compatible tokens sent to this address.
   *
   * @custom:suppress-reentrancy Risk tolerable. Can only be called by the owner.
   * @custom:suppress-pausable Risk tolerable. Can only be called by the owner.
   * @custom:suppress-malicious-erc Risk tolerable. Although the token can't be trusted, the owner has to check the token code manually.
   * @custom:suppress-address-trust-issue Risk tolerable. Although the token can't be trusted, the owner has to check the token code manually.
   *
   * @param token IERC-20 The address of the token contract
   */
  function recoverToken(address token, address sendTo) external onlyOwner {
    IERC20 erc20 = IERC20(token);

    uint256 balance = erc20.balanceOf(address(this));

    if (balance > 0) {
      // slither-disable-next-line unchecked-transfer
      erc20.safeTransfer(sendTo, balance);
    }
  }

  /**
   * @dev Pauses the store
   *
   * @custom:suppress-reentrancy Risk tolerable. Can only be called by the owner.
   *
   */
  function pause() external onlyOwner {
    super._pause();
  }

  /**
   * @dev Unpauses the store
   *
   * @custom:suppress-reentrancy Risk tolerable. Can only be called by the owner.
   *
   */
  function unpause() external onlyOwner {
    super._unpause();
  }

  function isProtocolMember(address contractAddress) public view returns (bool) {
    return boolStorage[keccak256(abi.encodePacked(_NS_MEMBERS, contractAddress))];
  }

  function _throwIfPaused() internal view {
    require(!super.paused(), "Pausable: paused");
  }

  function _throwIfSenderNotProtocolMember() internal view {
    require(isProtocolMember(msg.sender), "Forbidden");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./StoreBase.sol";

contract Store is StoreBase {
  function setAddress(bytes32 k, address v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    addressStorage[k] = v;
  }

  function setAddressBoolean(
    bytes32 k,
    address a,
    bool v
  ) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    addressBooleanStorage[k][a] = v;
  }

  function setUint(bytes32 k, uint256 v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    uintStorage[k] = v;
  }

  function addUint(bytes32 k, uint256 v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    uint256 existing = uintStorage[k];
    uintStorage[k] = existing + v;
  }

  function subtractUint(bytes32 k, uint256 v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    uint256 existing = uintStorage[k];
    uintStorage[k] = existing - v;
  }

  function setUints(bytes32 k, uint256[] calldata v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    uintsStorage[k] = v;
  }

  function setString(bytes32 k, string calldata v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    stringStorage[k] = v;
  }

  function setBytes(bytes32 k, bytes calldata v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();
    bytesStorage[k] = v;
  }

  function setBool(bytes32 k, bool v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    if (v) {
      boolStorage[k] = v;
      return;
    }

    delete boolStorage[k];
  }

  function setInt(bytes32 k, int256 v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    intStorage[k] = v;
  }

  function setBytes32(bytes32 k, bytes32 v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    bytes32Storage[k] = v;
  }

  function setAddressArrayItem(bytes32 k, address v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    if (addressArrayPositionMap[k][v] == 0) {
      addressArrayStorage[k].push(v);
      addressArrayPositionMap[k][v] = addressArrayStorage[k].length;
    }
  }

  function setBytes32ArrayItem(bytes32 k, bytes32 v) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    if (bytes32ArrayPositionMap[k][v] == 0) {
      bytes32ArrayStorage[k].push(v);
      bytes32ArrayPositionMap[k][v] = bytes32ArrayStorage[k].length;
    }
  }

  function deleteAddress(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete addressStorage[k];
  }

  function deleteUint(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete uintStorage[k];
  }

  function deleteUints(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete uintsStorage[k];
  }

  function deleteString(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete stringStorage[k];
  }

  function deleteBytes(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete bytesStorage[k];
  }

  function deleteBool(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete boolStorage[k];
  }

  function deleteInt(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete intStorage[k];
  }

  function deleteBytes32(bytes32 k) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    delete bytes32Storage[k];
  }

  function deleteAddressArrayItem(bytes32 k, address v) public override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    require(addressArrayPositionMap[k][v] > 0, "Not found");

    uint256 i = addressArrayPositionMap[k][v] - 1;
    uint256 count = addressArrayStorage[k].length;

    if (i + 1 != count) {
      addressArrayStorage[k][i] = addressArrayStorage[k][count - 1];
      address theThenLastAddress = addressArrayStorage[k][i];
      addressArrayPositionMap[k][theThenLastAddress] = i + 1;
    }

    addressArrayStorage[k].pop();
    delete addressArrayPositionMap[k][v];
  }

  function deleteBytes32ArrayItem(bytes32 k, bytes32 v) public override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    require(bytes32ArrayPositionMap[k][v] > 0, "Not found");

    uint256 i = bytes32ArrayPositionMap[k][v] - 1;
    uint256 count = bytes32ArrayStorage[k].length;

    if (i + 1 != count) {
      bytes32ArrayStorage[k][i] = bytes32ArrayStorage[k][count - 1];
      bytes32 theThenLastBytes32 = bytes32ArrayStorage[k][i];
      bytes32ArrayPositionMap[k][theThenLastBytes32] = i + 1;
    }

    bytes32ArrayStorage[k].pop();
    delete bytes32ArrayPositionMap[k][v];
  }

  function deleteAddressArrayItemByIndex(bytes32 k, uint256 i) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    require(i < addressArrayStorage[k].length, "Invalid index");

    address v = addressArrayStorage[k][i];
    deleteAddressArrayItem(k, v);
  }

  function deleteBytes32ArrayItemByIndex(bytes32 k, uint256 i) external override {
    _throwIfPaused();
    _throwIfSenderNotProtocolMember();

    require(i < bytes32ArrayStorage[k].length, "Invalid index");

    bytes32 v = bytes32ArrayStorage[k][i];
    deleteBytes32ArrayItem(k, v);
  }

  function getAddressValues(bytes32[] calldata keys) external view override returns (address[] memory values) {
    values = new address[](keys.length);

    for (uint256 i = 0; i < keys.length; i++) {
      values[i] = addressStorage[keys[i]];
    }
  }

  function getAddress(bytes32 k) external view override returns (address) {
    return addressStorage[k];
  }

  function getAddressBoolean(bytes32 k, address a) external view override returns (bool) {
    return addressBooleanStorage[k][a];
  }

  function getUintValues(bytes32[] calldata keys) external view override returns (uint256[] memory values) {
    values = new uint256[](keys.length);

    for (uint256 i = 0; i < keys.length; i++) {
      values[i] = uintStorage[keys[i]];
    }
  }

  function getUint(bytes32 k) external view override returns (uint256) {
    return uintStorage[k];
  }

  function getUints(bytes32 k) external view override returns (uint256[] memory) {
    return uintsStorage[k];
  }

  function getString(bytes32 k) external view override returns (string memory) {
    return stringStorage[k];
  }

  function getBytes(bytes32 k) external view override returns (bytes memory) {
    return bytesStorage[k];
  }

  function getBool(bytes32 k) external view override returns (bool) {
    return boolStorage[k];
  }

  function getInt(bytes32 k) external view override returns (int256) {
    return intStorage[k];
  }

  function getBytes32(bytes32 k) external view override returns (bytes32) {
    return bytes32Storage[k];
  }

  function getAddressArray(bytes32 k) external view override returns (address[] memory) {
    return addressArrayStorage[k];
  }

  function getBytes32Array(bytes32 k) external view override returns (bytes32[] memory) {
    return bytes32ArrayStorage[k];
  }

  function getAddressArrayItemPosition(bytes32 k, address toFind) external view override returns (uint256) {
    return addressArrayPositionMap[k][toFind];
  }

  function getBytes32ArrayItemPosition(bytes32 k, bytes32 toFind) external view override returns (uint256) {
    return bytes32ArrayPositionMap[k][toFind];
  }

  function getAddressArrayItemByIndex(bytes32 k, uint256 i) external view override returns (address) {
    require(addressArrayStorage[k].length > i, "Invalid index");
    return addressArrayStorage[k][i];
  }

  function getBytes32ArrayItemByIndex(bytes32 k, uint256 i) external view override returns (bytes32) {
    require(bytes32ArrayStorage[k].length > i, "Invalid index");
    return bytes32ArrayStorage[k][i];
  }

  function countAddressArrayItems(bytes32 k) external view override returns (uint256) {
    return addressArrayStorage[k].length;
  }

  function countBytes32ArrayItems(bytes32 k) external view override returns (uint256) {
    return bytes32ArrayStorage[k].length;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../Recoverable.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../interfaces/IWitness.sol";
import "../../libraries/NTransferUtilV2.sol";
import "../../libraries/GovernanceUtilV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/RegistryLibV1.sol";
import "../../interfaces/IVault.sol";

/**
 * @title Witness Contract
 *
 * @dev The witeness contract enables NPM tokenholders to
 * participate in an active cover incident.
 *
 * <br /><br />
 *
 * The participants can choose to support an incident by `attesting`
 * or they can also disagree by `refuting` the incident. In both cases,
 * the tokenholders can choose to submit any amount of
 * NEP stake during the (7 day, configurable) reporting period.
 *
 * <br /><br />
 *
 * After the reporting period, whichever side loses, loses all their tokens.
 * While each `witness` and `reporter` on the winning side will proportionately
 * receive a portion of these tokens as a reward, some forfeited tokens are
 * burned too.
 *
 * <br /><br />
 *
 * **Warning:**
 *
 * <br /> <br />
 *
 * Please carefully check the cover rules, cover exclusions, and standard exclusion
 * in detail before you interact with the Governace contract(s). You entire stake will be forfeited
 * if resolution does not go in your favor. You will be able to unstake
 * and receive back your NPM only if:
 *
 * - incident resolution is in your favor
 * - after reporting period ends
 *
 * <br /> <br />
 *
 * **By using this contract directly via a smart contract call,
 * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
 * you are completely aware, fully understand, and accept the risk that you may lose all of
 * your stake.**
 *
 */
abstract contract Witness is Recoverable, IWitness {
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using GovernanceUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Support the reported incident by staking your NPM token.
   * Your tokens will be frozen until the incident is fully resolved.
   *
   * <br /> <br />
   *
   * Ensure that you not only thoroughly comprehend the terms, exclusion, standard exclusion, etc of the policy,
   * but that you also have all the necessary proof to verify that the requirement has been met.
   *
   * @custom:warning **Warning:**
   *
   * Although you may believe that the incident did actually occur, you may still be wrong.
   * Even when you are right, the governance participants could outcast you.
   *
   *
   * By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.
   *
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   *
   * @param coverKey Enter the key of the active cover
   * @param incidentDate Enter the active cover's date of incident
   * @param stake Enter the amount of NPM tokens you wish to stake.
   * Note that you cannot unstake this amount if the decision was not in your favor.
   */
  function attest(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustBeReportingOrDisputed(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeDuringReportingPeriod(coverKey, productKey);

    require(stake > 0, "Enter a stake");

    s.addAttestationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Attested(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev Reject the reported incident by staking your NPM token.
   * Your tokens will be frozen until the incident is fully resolved.
   *
   * <br /> <br />
   *
   * Ensure that you not only thoroughly comprehend the terms, exclusion, standard exclusion, etc of the policy,
   * but that you also have all the necessary proof to verify that the requirement has NOT been met.
   *
   * @custom:warning **Warning:**
   *
   * Although you may believe that the incident did not occur, you may still be wrong.
   * Even when you are right, the governance participants could outcast you.
   *
   *
   * By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   *
   * @param coverKey Enter the key of the active cover
   * @param incidentDate Enter the active cover's date of incident
   * @param stake Enter the amount of NPM tokens you wish to stake.
   * Note that you cannot unstake this amount if the decision was not in your favor.
   */
  function refute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustHaveDispute(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeDuringReportingPeriod(coverKey, productKey);

    require(stake > 0, "Enter a stake");

    s.addRefutationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Refuted(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev Gets the status of a given cover
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param coverKey Enter the key of the cover you'd like to check the status of
   * @return Returns the cover status as an integer.
   * For more, check the enum `ProductStatus` on `CoverUtilV1` library.
   *
   */
  function getStatus(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getStatusInternal(coverKey, productKey);
  }

  /**
   * @dev Gets the stakes of each side of a given cover governance pool
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param coverKey Enter the key of the cover you'd like to check the stakes of
   * @param incidentDate Enter the active cover's date of incident
   * @return Returns an array of integers --> [yes, no]
   *
   */
  function getStakes(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view override returns (uint256, uint256) {
    return s.getStakesInternal(coverKey, productKey, incidentDate);
  }

  /**
   * @dev Gets the stakes of each side of a given cover governance pool for the specified account.
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param coverKey Enter the key of the cover you'd like to check the stakes of
   * @param incidentDate Enter the active cover's date of incident
   * @param account Enter the account you'd like to get the stakes of
   * @return Returns an array of integers --> [yes, no]
   *
   */
  function getStakesOf(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    address account
  ) external view override returns (uint256, uint256) {
    return s.getStakesOfInternal(account, coverKey, productKey, incidentDate);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./Reporter.sol";
import "../../interfaces/IGovernance.sol";

/**
 * @title Governance Contract
 *
 * @dev The governance contract permits any NPM tokenholder to submit a report
 * by staking a minimum number of NPM tokens as set in the cover pool.
 *
 * <br /> <br />
 *
 * The reporting procedure begins when an incident report is received and often takes seven days or longer,
 * depending on the configuration of a cover. It also allows subsequent reporters to submit their stakes
 * in support of the initial report or to add stakes to dispute it.
 *
 * <br /> <br />
 *
 * **Warning:**
 *
 * <br /> <br />
 *
 * Please carefully check the cover rules, cover exclusions, and standard exclusion
 * in detail before you interact with the Governace contract(s). You entire stake will be forfeited
 * if resolution does not go in your favor. You will be able to unstake
 * and receive back your NPM only if:
 *
 * - incident resolution is in your favor
 * - after reporting period ends
 *
 * <br /> <br />
 *
 * **By using this contract directly via a smart contract call,
 * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
 * you are completely aware, fully understand, and accept the risk that you may lose all of
 * your stake.**
 *
 */
contract Governance is IGovernance, Reporter {
  using GovernanceUtilV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using ValidationLibV1 for bytes32;

  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_GOVERNANCE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/IReporter.sol";
import "./Witness.sol";

/**
 * @title Reporter Contract
 *
 * @dev This contract allows any NPM tokenholder to report a new incident
 * or dispute a previously recorded incident.
 *
 * <br /> <br />
 *
 * When a cover pool is reporting, additional tokenholders may join in to reach a resolution.
 * The `First Reporter` is the user who initially submits an incident,
 * while `Candidate Reporter` is the user who challenges the submitted report.
 *
 * <br /> <br />
 *
 * Valid reporter is one of the aforementioned who receives a favourable decision
 * when resolution is achieved.
 *
 * <br /> <br />
 *
 * **Warning:**
 *
 * <br /> <br />
 *
 * Please carefully check the cover rules, cover exclusions, and standard exclusion
 * in detail before you interact with the Governace contract(s). You entire stake will be forfeited
 * if resolution does not go in your favor. You will be able to unstake
 * and receive back your NPM only if:
 *
 * - incident resolution is in your favor
 * - after reporting period ends
 *
 * <br /> <br />
 *
 * **By using this contract directly via a smart contract call,
 * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
 * you are completely aware, fully understand, and accept the risk that you may lose all of
 * your stake.**
 *
 */
abstract contract Reporter is IReporter, Witness {
  using GovernanceUtilV1 for IStore;
  using RegistryLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Stake NPM tokens to file an incident report.
   * Check the `[getFirstReportingStake(coverKey) method](#getfirstreportingstake)` to get
   * the minimum amount required to report this cover.
   *
   * <br /> <br />
   *
   * For more info, check out the [documentation](https://docs.neptunemutual.com/covers/cover-reporting)
   *
   * <br /> <br />
   *
   * **Rewards:**
   *
   * <br />
   *
   * If you obtain a favourable resolution, you will enjoy the following benefits:
   *
   * - A proportional commission in NPM tokens on all rewards earned by qualified camp voters (see [Unstakable.unstakeWithClaim](Unstakable.md#unstakewithclaim)).
   * - A proportional commission on the protocol earnings of all stablecoin claim payouts.
   * - Your share of the 60 percent pool of invalid camp participants.
   *
   *
   * @custom:note Please note the differences between the following:
   *
   * **Observed Date**
   *
   * The date an time when incident occurred in the real world.
   *
   * **Incident Date**
   *
   * Instead of observed date or the real date and time of the trigger incident,
   * the timestamp when this report is submitted is "the incident date".
   *
   * Payouts to policyholders is given only if the reported incident date
   * falls within the coverage period.
   *
   *
   * @custom:warning **Warning:**
   *
   * Please carefully check the cover rules, cover exclusions, and standard exclusion
   * in detail before you submit this report. You entire stake will be forfeited
   * if resolution does not go in your favor. You will be able to unstake
   * and receive back your NPM only if:
   *
   * - incident resolution is in your favor
   * - after reporting period ends
   *
   * **By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.**
   *
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   * @param coverKey Enter the cover key you are reporting
   * @param productKey Enter the product key you are reporting
   * @param info Enter IPFS hash of the incident in the following format:
   * <br />
   * <pre>{
   * <br />  incidentTitle: 'Animated Brands Exploit, August 2024',
   * <br />  observed: 1723484937,
   * <br />  proofOfIncident: 'https://twitter.com/AnimatedBrand/status/5739383124571205635',
   * <br />  description: 'In a recent exploit, attackers were able to drain 50M USDC from Animated Brands lending vaults',
   * <br />}
   * </pre>
   * @param stake Enter the amount you would like to stake to submit this report
   *
   */
  function report(
    bytes32 coverKey,
    bytes32 productKey,
    bytes32 info,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);

    s.mustHaveNormalProductStatus(coverKey, productKey);

    uint256 incidentDate = block.timestamp; // solhint-disable-line
    require(stake > 0, "Stake insufficient");
    require(stake >= s.getMinReportingStakeInternal(coverKey), "Stake insufficient");

    s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey, incidentDate);

    // Set the Resolution Timestamp
    uint256 resolutionDate = block.timestamp + s.getReportingPeriodInternal(coverKey); // solhint-disable-line
    s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, coverKey, productKey, resolutionDate);

    // Update the values
    s.addAttestationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    // Transfer the stake to the resolution contract
    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Reported(coverKey, productKey, msg.sender, incidentDate, info, stake, resolutionDate);
    emit Attested(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev If you believe that a reported incident is wrong, you can stake NPM tokens to dispute an incident report.
   * Check the `[getFirstReportingStake(coverKey) method](#getfirstreportingstake)` to get
   * the minimum amount required to report this cover.
   *
   * <br /> <br />
   *
   * **Rewards:**
   *
   * If you get resolution in your favor, you will receive these rewards:
   *
   * - A 10% commission on all reward received by valid camp voters (check `Unstakeable.unstakeWithClaim`) in NPM tokens.
   * - Your proportional share of the 60% pool of the invalid camp.
   *
   * @custom:warning **Warning:**
   *
   * Please carefully check the coverage rules and exclusions in detail
   * before you submit this report. You entire stake will be forfeited
   * if resolution does not go in your favor. You will be able to unstake
   * and receive back your NPM only if:
   *
   *
   * By using this function directly via a smart contract call,
   * through an explorer service such as Etherscan, using an SDK and/or API, or in any other way,
   * you are completely aware, fully understand, and accept the risk that you may lose all of
   * your stake.
   *
   * - incident resolution is in your favor
   * - after reporting period ends
   *
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   * @param coverKey Enter the cover key you are reporting
   * @param productKey Enter the product key you are reporting
   * @param info Enter IPFS hash of the incident in the following format:
   * `{
   *    incidentTitle: 'Wrong Incident Reporting',
   *    observed: 1723484937,
   *    proofOfIncident: 'https://twitter.com/AnimatedBrand/status/5739383124571205635',
   *    description: 'Animated Brands emphasised in its most recent tweet that the report regarding their purported hack was false.',
   *  }`
   * @param stake Enter the amount you would like to stake to submit this dispute
   *
   */
  function dispute(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    bytes32 info,
    uint256 stake
  ) external override nonReentrant {
    s.mustNotBePaused();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustNotHaveDispute(coverKey, productKey);
    s.mustBeReporting(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeDuringReportingPeriod(coverKey, productKey);

    require(stake > 0, "Stake insufficient");
    require(stake >= s.getMinReportingStakeInternal(coverKey), "Stake insufficient");

    s.addRefutationInternal(coverKey, productKey, msg.sender, incidentDate, stake);

    // Transfer the stake to the resolution contract
    s.npmToken().ensureTransferFrom(msg.sender, address(s.getResolutionContract()), stake);

    emit Disputed(coverKey, productKey, msg.sender, incidentDate, info, stake);
    emit Refuted(coverKey, productKey, msg.sender, incidentDate, stake);
  }

  /**
   * @dev Allows a cover manager set first reporting (minimum) stake of a given cover.
   *
   * @param coverKey Provide a coverKey or leave it empty. If empty, the stake is set as
   * fallback value. Covers that do not have customized first reporting stake will infer to the fallback value.
   * @param value Enter the first reporting stake in NPM units
   *
   */
  function setFirstReportingStake(bytes32 coverKey, uint256 value) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);
    require(value > 0, "Please specify value");

    uint256 previous = getFirstReportingStake(coverKey);

    if (coverKey > 0) {
      s.setUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, coverKey, value);
    } else {
      s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_MIN_FIRST_STAKE, value);
    }

    emit FirstReportingStakeSet(coverKey, previous, value);
  }

  /**
   * @dev Returns the minimum amount of NPM tokens required to `report` or `dispute` a cover.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Specify the cover you want to get the minimum stake required value of.
   *
   */
  function getFirstReportingStake(bytes32 coverKey) public view override returns (uint256) {
    return s.getMinReportingStakeInternal(coverKey);
  }

  /**
   * @dev Allows a cover manager set burn rate of the NPM tokens of the invalid camp.
   * The protocol forfeits all stakes of invalid camp voters. During `unstakeWithClaim`,
   * NPM tokens get proportionately burned as configured here.
   *
   * <br /> <br />
   *
   * The unclaimed and thus unburned NPM stakes will be manually pulled
   * and burned on a periodic but not-so-frequent basis.
   *
   * @param value Enter the burn rate in percentage value (Check ProtoUtilV1.MULTIPLIER for division)
   *
   */
  function setReportingBurnRate(uint256 value) external override nonReentrant {
    require(value > 0, "Please specify value");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);

    uint256 previous = s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE);
    s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTING_BURN_RATE, value);

    emit ReportingBurnRateSet(previous, value);
  }

  /**
   * @dev Allows a cover manager set reporter comission of the NPM tokens from the invalid camp.
   * The protocol forfeits all stakes of invalid camp voters. During `unstakeWithClaim`,
   * NPM tokens get proportionately transferred to the **valid reporter** as configured here.
   *
   * <br /> <br />
   *
   * The unclaimed and thus unrewarded NPM stakes will be manually pulled and burned on a periodic but not-so-frequent basis.
   *
   * @param value Enter the valid reporter comission in percentage value (Check ProtoUtilV1.MULTIPLIER for division)
   *
   */
  function setReporterCommission(uint256 value) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeCoverManager(s);
    require(value > 0, "Please specify value");

    uint256 previous = s.getUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION);
    s.setUintByKey(ProtoUtilV1.NS_GOVERNANCE_REPORTER_COMMISSION, value);

    emit ReporterCommissionSet(previous, value);
  }

  /**
   * @dev Gets the latest incident date of a given cover and product
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   * @param coverKey Enter the cover key you want to get the incident of
   * @param productKey Enter the product key you want to get the incident of
   *
   */
  function getActiveIncidentDate(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getActiveIncidentDateInternal(coverKey, productKey);
  }

  /**
   * @dev Gets the reporter of a cover by its incident date
   *
   * Warning: this function does not validate the input arguments.
   *
   * @custom:note Please note that until resolution deadline is over, the returned
   * reporter might keep changing.
   *
   * @param coverKey Enter the cover key you would like to get the reporter of
   * @param productKey Enter the product key you would like to get the reporter of
   * @param productKey Enter the cover's incident date you would like to get the reporter of
   */
  function getReporter(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external view override returns (address) {
    return s.getReporterInternal(coverKey, productKey, incidentDate);
  }

  /**
   * @dev Retuns the resolution date of a given cover
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param coverKey Enter the cover key to get the resolution date of
   * @param productKey Enter the product key to get the resolution date of
   *
   */
  function getResolutionTimestamp(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getResolutionTimestampInternal(coverKey, productKey);
  }

  /**
   * @dev Gets an account's attestation details. Please also check `getRefutation` since an account
   * can submit both `attestations` and `refutations` if they wish to.
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param coverKey Enter the cover key you want to get attestation of
   * @param productKey Enter the product key you want to get attestation of
   * @param who Enter the account you want to get attestation of
   * @param who Enter the specified cover's indicent date for which attestation will be returned
   *
   */
  function getAttestation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view override returns (uint256 myStake, uint256 totalStake) {
    return s.getAttestationInternal(coverKey, productKey, who, incidentDate);
  }

  /**
   * @dev Gets an account's refutation details. Please also check `getAttestation` since an account
   * can submit both `attestations` and `refutations` if they wish to.
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param coverKey Enter the cover key you want to get refutation of
   * @param productKey Enter the product key you want to get refutation of
   * @param who Enter the account you want to get refutation of
   * @param who Enter the specified cover's indicent date for which refutation will be returned
   *
   */
  function getRefutation(
    bytes32 coverKey,
    bytes32 productKey,
    address who,
    uint256 incidentDate
  ) external view override returns (uint256 myStake, uint256 totalStake) {
    return s.getRefutationInternal(coverKey, productKey, who, incidentDate);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../Recoverable.sol";
import "../../interfaces/IVaultDelegate.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../libraries/VaultLibV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/StrategyLibV1.sol";
import "../../libraries/NTransferUtilV2.sol";

/**
 * Important: This contract is not intended to be accessed
 * by anyone/anything except individual vault contracts.
 *
 * @title Vault Delegate Base Contract
 *
 *
 * @dev The vault delegate base contract includes pre and post hooks.
 * The hooks are accessible only to vault contracts.
 *
 */
abstract contract VaultDelegateBase is IVaultDelegate, Recoverable {
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using VaultLibV1 for IStore;
  using ValidationLibV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using StoreKeyUtil for IStore;
  using StrategyLibV1 for IStore;
  using CoverUtilV1 for IStore;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Constructs this contract
   *
   * @param store Provide the store contract instance
   */
  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev This hook runs before `transferGovernance` implementation on vault(s).
   *
   * @custom:suppress-acl This function is only callable by the claims processor contract through the vault contract
   * @custom:note Please note the following:
   *
   * - Governance transfers are allowed via claims processor contract only.
   * - This function's caller must be the vault of the specified coverKey.
   *
   * @param caller Enter your msg.sender value.
   * @param coverKey Provide your vault's cover key.
   *
   * @return stablecoin Returns address of the protocol stablecoin if the hook validation passes.
   *
   */
  function preTransferGovernance(
    address caller,
    bytes32 coverKey,
    address, /*to*/
    uint256 /*amount*/
  ) external override nonReentrant returns (address stablecoin) {
    // @suppress-zero-value-check This function does not transfer any values
    s.mustNotBePaused();
    s.mustBeProtocolMember(caller);
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.callerMustBeClaimsProcessorContract(caller);

    stablecoin = s.getStablecoin();
  }

  /**
   * @dev This hook runs after `transferGovernance` implementation on vault(s)
   * and performs cleanup and/or validation if needed.
   *
   * @custom:suppress-acl This function is only callable by the claims processor contract through the vault contract
   * @custom:note do not update state and liquidity since `transferGovernance` is an internal contract-only function
   * @custom:suppress-reentrancy The `postTransferGovernance` hook is executed under the same context of `preTransferGovernance`.
   *
   * @param caller Enter your msg.sender value.
   * @param coverKey Provide your vault's cover key.
   *
   */
  function postTransferGovernance(
    address caller,
    bytes32 coverKey,
    address, /*to*/
    uint256 /*amount*/
  ) external view override {
    s.mustNotBePaused();
    s.mustBeProtocolMember(caller);
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.callerMustBeClaimsProcessorContract(caller);
  }

  /**
   * @dev This hook runs before `transferToStrategy` implementation on vault(s)
   *
   * @custom:suppress-acl This function is only callable by a strategy contract through vault contract
   * @custom:note Please note the following:
   *
   * - Transfers are allowed to exact strategy contracts only
   * where the strategy can perform lending.
   *
   * @param caller Enter your msg.sender value
   * @param token Provide the ERC20 token you'd like to transfer to the given strategy
   * @param coverKey Provide your vault's cover key
   * @param strategyName Enter the strategy name
   * @param amount Enter the amount to transfer
   *
   */
  function preTransferToStrategy(
    address caller,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external override nonReentrant {
    // @suppress-zero-value-check Checked
    s.mustNotBePaused();
    s.mustBeProtocolMember(caller);
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.callerMustBeSpecificStrategyContract(caller, strategyName);

    s.preTransferToStrategyInternal(token, coverKey, strategyName, amount);
  }

  /**
   * @dev This hook runs after `transferToStrategy` implementation on vault(s)
   * and performs cleanup and/or validation if needed.
   *
   * @custom:suppress-acl This function is only callable by a strategy contract through vault contract
   * @custom:suppress-reentrancy Not required. The `postTransferToStrategy` hook is executed under the same context of `preTransferToStrategy`.
   * @custom:note Do not update state and liquidity since `transferToStrategy` itself is a part of the state update
   *
   * @param caller Enter your msg.sender value
   * @param coverKey Enter the coverKey
   * @param strategyName Enter the strategy name
   *
   */
  function postTransferToStrategy(
    address caller,
    IERC20, /*token*/
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 /*amount*/
  ) external view override {
    s.mustNotBePaused();
    s.mustBeProtocolMember(caller);
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.callerMustBeSpecificStrategyContract(caller, strategyName);
  }

  /**
   * @dev This hook runs before `receiveFromStrategy` implementation on vault(s)
   *
   * @custom:note Please note the following:
   *
   * - Access is allowed to exact strategy contracts only
   * - The caller must be the strategy contract
   * - msg.sender must be the correct vault contract
   *
   * @param caller Enter your msg.sender value
   * @param coverKey Provide your vault's cover key
   * @param strategyName Enter the strategy name
   *
   */
  function preReceiveFromStrategy(
    address caller,
    IERC20, /*token*/
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 /*amount*/
  ) external override nonReentrant {
    // @suppress-zero-value-check This function does not transfer any tokens
    s.mustNotBePaused();
    s.mustBeProtocolMember(caller);
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.callerMustBeSpecificStrategyContract(caller, strategyName);
  }

  /**
   * @dev This hook runs after `receiveFromStrategy` implementation on vault(s)
   * and performs cleanup and/or validation if needed.
   *
   * @custom:note Do not update state and liquidity since `receiveFromStrategy` itself is a part of the state update
   * @custom:suppress-reentrancy Not required. The `postReceiveFromStrategy` hook is executed under the same context of `preReceiveFromStrategy`.
   *
   * @param caller Enter your msg.sender value
   * @param token Enter the token your vault received from strategy
   * @param coverKey Enter the coverKey
   * @param strategyName Enter the strategy name
   * @param amount Enter the amount received
   *
   */
  function postReceiveFromStrategy(
    address caller,
    IERC20 token,
    bytes32 coverKey,
    bytes32 strategyName,
    uint256 amount
  ) external override returns (uint256 income, uint256 loss) {
    // @suppress-zero-value-check This call does not perform any transfers
    s.mustNotBePaused();
    s.mustBeProtocolMember(caller);
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.callerMustBeSpecificStrategyContract(caller, strategyName);

    (income, loss) = s.postReceiveFromStrategyInternal(token, coverKey, strategyName, amount);
  }

  /**
   * @dev This hook runs before `addLiquidity` implementation on vault(s)
   *
   * @custom:suppress-acl No need to define ACL as this function is only accessible to associated vault contract of the coverKey
   * @custom:note Please note the following:
   *
   * - msg.sender must be correct vault contract
   *
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to supply.
   * @param npmStakeToAdd Enter the amount of NPM token to stake.
   *
   */
  function preAddLiquidity(
    address caller,
    bytes32 coverKey,
    uint256 amount,
    uint256 npmStakeToAdd
  ) external override nonReentrant returns (uint256 podsToMint, uint256 previousNpmStake) {
    // @suppress-zero-value-check This call does not transfer any tokens
    s.mustNotBePaused();
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.mustEnsureAllProductsAreNormal(coverKey);

    ValidationLibV1.mustNotExceedStablecoinThreshold(s, amount);
    GovernanceUtilV1.mustNotExceedNpmThreshold(amount);

    address pod = msg.sender;
    (podsToMint, previousNpmStake) = s.preAddLiquidityInternal(coverKey, pod, caller, amount, npmStakeToAdd);
  }

  /**
   * @dev This hook runs after `addLiquidity` implementation on vault(s)
   * and performs cleanup and/or validation if needed.
   *
   * @custom:suppress-acl No need to define ACL as this function is only accessible to associated vault contract of the coverKey
   * @custom:suppress-reentrancy Not required. The `postAddLiquidity` hook is executed under the same context of `preAddLiquidity`.
   *
   * @param coverKey Enter the coverKey
   *
   */
  function postAddLiquidity(
    address, /*caller*/
    bytes32 coverKey,
    uint256, /*amount*/
    uint256 /*npmStakeToAdd*/
  ) external override {
    // @suppress-zero-value-check This function does not transfer any tokens
    s.mustNotBePaused();
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.mustEnsureAllProductsAreNormal(coverKey);
    s.updateStateAndLiquidity(coverKey);
  }

  /**
   * @dev This implemention enables liquidity manages to
   * accrue interests on a vault before withdrawals are allowed.
   *
   * @custom:suppress-acl This function is only accessible to the vault contract
   * @custom:note Please note the following:
   *
   * - Caller must be a liquidity manager
   * - msg.sender must the correct vault contract
   *
   * @param caller Enter your msg.sender value
   * @param coverKey Provide your vault's cover key
   *
   */
  function accrueInterestImplementation(address caller, bytes32 coverKey) external override {
    s.mustNotBePaused();
    s.senderMustBeVaultContract(coverKey);
    AccessControlLibV1.callerMustBeLiquidityManager(s, caller);

    s.accrueInterestInternal(coverKey);
  }

  /**
   * @dev This hook runs before `removeLiquidity` implementation on vault(s)
   *
   * @custom:suppress-acl No need to define ACL as this function is only accessible to associated vault contract of the coverKey
   * @custom:note Please note the following:
   *
   * - msg.sender must be the correct vault contract
   * - Must have at couple of block height offset following a deposit.
   * - Must be done during withdrawal period
   * - Must have no balance in strategies
   * - Cover status should be normal
   * - Interest should already be accrued
   *
   * @param caller Enter your msg.sender value
   * @param coverKey Enter the cover key
   * @param podsToRedeem Enter the amount of pods to redeem
   * @param npmStakeToRemove Enter the amount of NPM stake to remove.
   * @param exit If this is set to true, LPs can remove their entire NPM stake during a withdrawal period. No restriction.
   *
   */
  function preRemoveLiquidity(
    address caller,
    bytes32 coverKey,
    uint256 podsToRedeem,
    uint256 npmStakeToRemove,
    bool exit
  ) external override nonReentrant returns (address stablecoin, uint256 stablecoinToRelease) {
    // @suppress-zero-value-check This call does not transfer any tokens
    s.mustNotBePaused();
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.mustMaintainBlockHeightOffset(coverKey);
    s.mustEnsureAllProductsAreNormal(coverKey);
    s.mustBeDuringWithdrawalPeriod(coverKey);
    s.mustHaveNoBalanceInStrategies(coverKey, stablecoin);
    s.mustBeAccrued(coverKey);

    address pod = msg.sender; // The sender is vault contract
    return s.preRemoveLiquidityInternal(coverKey, pod, caller, podsToRedeem, npmStakeToRemove, exit);
  }

  /**
   * @dev This hook runs after `removeLiquidity` implementation on vault(s)
   * and performs cleanup and/or validation if needed.
   *
   * @custom:suppress-acl No need to define ACL as this function is only accessible to associated vault contract of the coverKey
   * @custom:suppress-reentrancy Not required. The `postRemoveLiquidity` hook is executed under the same context as `preRemoveLiquidity`.
   *
   * @param coverKey Enter the coverKey
   *
   */
  function postRemoveLiquidity(
    address, /*caller*/
    bytes32 coverKey,
    uint256, /*podsToRedeem*/
    uint256, /*npmStakeToRemove*/
    bool /*exit*/
  ) external override {
    // @suppress-zero-value-check The uint values are not used and therefore not checked
    s.mustNotBePaused();
    s.mustBeProtocolMember(msg.sender);
    s.senderMustBeVaultContract(coverKey);
    s.updateStateAndLiquidity(coverKey);
  }

  /**
   * @dev Calculates the amount of PODs to mint for the given amount of stablecoin
   *
   * @param coverKey Enter the cover for which you want to calculate PODs
   * @param stablecoinIn Enter the amount in the stablecoin units
   *
   * @return Returns the units of PODs to be minted if this stablecoin liquidity was supplied.
   * Be warned that this value may change based on the cover vault's usage.
   *
   */
  function calculatePodsImplementation(bytes32 coverKey, uint256 stablecoinIn) external view override returns (uint256) {
    s.senderMustBeVaultContract(coverKey);

    address pod = msg.sender;

    return s.calculatePodsInternal(coverKey, pod, stablecoinIn);
  }

  /**
   * @dev Calculates the amount of stablecoin units to receive for the given amount of PODs to redeem
   *
   * @param coverKey Enter the cover for which you want to calculate PODs
   * @param podsToBurn Enter the amount in the POD units to redeem
   *
   * @return Returns the units of stablecoins to redeem if the specified PODs were burned.
   * Be warned that this value may change based on the cover's vault usage.
   *
   */
  function calculateLiquidityImplementation(bytes32 coverKey, uint256 podsToBurn) external view override returns (uint256) {
    s.senderMustBeVaultContract(coverKey);
    address pod = msg.sender;
    return s.calculateLiquidityInternal(coverKey, pod, podsToBurn);
  }

  /**
   * @dev Returns the stablecoin balance of this vault
   * This also includes amounts lent out in lending strategies by this vault
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param coverKey Enter the cover for which you want to get the stablecoin balance
   */
  function getStablecoinBalanceOfImplementation(bytes32 coverKey) external view override returns (uint256) {
    s.senderMustBeVaultContract(coverKey);
    return s.getStablecoinOwnedByVaultInternal(coverKey);
  }

  /**
   * @dev Gets information of a given vault by the cover key
   *
   * Warning: this function does not validate the cover key and account supplied.
   *
   * @param coverKey Specify cover key to obtain the info of
   * @param you The address for which the info will be customized
   * @param values[0] totalPods --> Total PODs in existence
   * @param values[1] balance --> Stablecoins held in the vault
   * @param values[2] extendedBalance --> Stablecoins lent outside of the protocol
   * @param values[3] totalReassurance -- > Total reassurance for this cover
   * @param values[4] myPodBalance --> Your POD Balance
   * @param values[5] myShare --> My share of the liquidity pool (in stablecoin)
   * @param values[6] withdrawalOpen --> The timestamp when withdrawals are opened
   * @param values[7] withdrawalClose --> The timestamp when withdrawals are closed again
   *
   */
  function getInfoImplementation(bytes32 coverKey, address you) external view override returns (uint256[] memory values) {
    s.senderMustBeVaultContract(coverKey);
    address pod = msg.sender;
    return s.getInfoInternal(coverKey, pod, you);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_VAULT_DELEGATE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./VaultDelegateBase.sol";

/**
 * Important: This contract is not intended to be accessed
 * by anyone/anything except individual vault contracts.
 *
 * @title With Flash Loan Delegate Contract
 *
 * @dev This contract implements [EIP-3156 Flash Loan](https://eips.ethereum.org/EIPS/eip-3156).
 *
 */
abstract contract VaultDelegateWithFlashLoan is VaultDelegateBase {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using VaultLibV1 for IStore;
  using RoutineInvokerLibV1 for IStore;

  /**
   * @dev The fee to be charged for a given loan.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @return The amount of `token` to be charged for the loan, on top of the returned principal.
   *
   */
  function getFlashFee(
    address, /*caller*/
    bytes32 coverKey,
    address token,
    uint256 amount
  ) external view override returns (uint256) {
    s.senderMustBeVaultContract(coverKey);
    return s.getFlashFeeInternal(coverKey, token, amount);
  }

  /**
   * @dev The amount of currency available to be lent.
   *
   * Warning: this function does not validate the cover key supplied.
   *
   * @param token The loan currency.
   * @return The amount of `token` that can be borrowed.
   *
   */
  function getMaxFlashLoan(
    address, /*caller*/
    bytes32 coverKey,
    address token
  ) external view override returns (uint256) {
    s.senderMustBeVaultContract(coverKey);
    return s.getMaxFlashLoanInternal(coverKey, token);
  }

  /**
   * @dev This hook runs before `flashLoan` implementation on vault(s)
   *
   * @custom:suppress-acl This function is only accessible to the vault contract
   * @custom:note Please note the following:
   *
   * - msg.sender must be the correct vault contract
   * - Cover status should be normal
   *
   * @param coverKey Enter the cover key
   * @param token Enter the token you want to borrow
   * @param amount Enter the flash loan amount to receive
   *
   */
  function preFlashLoan(
    address, /*caller*/
    bytes32 coverKey,
    IERC3156FlashBorrower, /*receiver*/
    address token,
    uint256 amount,
    bytes calldata /*data*/
  )
    external
    override
    returns (
      IERC20 stablecoin,
      uint256 fee,
      uint256 protocolFee
    )
  {
    s.mustNotBePaused();
    s.mustEnsureAllProductsAreNormal(coverKey);
    s.senderMustBeVaultContract(coverKey);

    stablecoin = IERC20(s.getStablecoin());

    // require(address(stablecoin) == token, "Unknown token"); <-- already checked in `getFlashFeesInternal`
    // require(amount > 0, "Loan too small"); <-- already checked in `getFlashFeesInternal`

    s.setBoolByKeys(ProtoUtilV1.NS_COVER_HAS_FLASH_LOAN, coverKey, true);

    (fee, protocolFee) = s.getFlashFeesInternal(coverKey, token, amount);

    require(fee > 0, "Loan too small");
    require(protocolFee > 0, "Loan too small");
  }

  /**
   * @dev This hook runs after `flashLoan` implementation on vault(s)
   *
   * @custom:suppress-acl This function is only accessible to the vault contract
   * @custom:note Please note the following:
   *
   * - msg.sender must be the correct vault contract
   * - Cover status should be normal
   *
   * @param coverKey Enter the cover key
   *
   */
  function postFlashLoan(
    address, /*caller*/
    bytes32 coverKey,
    IERC3156FlashBorrower, /*receiver*/
    address, /*token*/
    uint256, /*amount*/
    bytes calldata /*data*/
  ) external override {
    // @suppress-zero-value-check The `amount` value isn't used and therefore not checked
    s.mustNotBePaused();
    s.senderMustBeVaultContract(coverKey);
    s.mustEnsureAllProductsAreNormal(coverKey);

    s.setBoolByKeys(ProtoUtilV1.NS_COVER_HAS_FLASH_LOAN, coverKey, false);
    s.updateStateAndLiquidity(coverKey);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./VaultDelegateWithFlashLoan.sol";

/**
 * @title Vault Delegate
 *
 * @dev Because vaults cannot be upgraded individually, all vaults delegate some logic to this contract.
 *
 * @notice Liquidity providers can earn fees by adding stablecoin liquidity
 * to any cover contract. The cover pool is collectively owned by liquidity providers
 * where fees automatically get accumulated and compounded.
 *
 * <br /> <br />
 *
 * **Fees:**
 *
 * - Cover fees paid in stablecoin get added to the liquidity pool.
 * - The protocol supplies a small portion of idle assets to third-party lending protocols.
 * - Flash loan interest also gets added back to the pool.
 * - Cover creators can donate a small portion of their revenue as a reassurance fund
 * to protect liquidity providers. This assists liquidity providers in the event of an exploit
 * by preventing pool depletion.
 *
 */
contract VaultDelegate is VaultDelegateWithFlashLoan {
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using VaultLibV1 for IStore;

  constructor(IStore store) VaultDelegateBase(store) {} // solhint-disable-line
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/IVault.sol";
import "../../interfaces/ICxTokenFactory.sol";
import "../../libraries/cxTokenFactoryLibV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../Recoverable.sol";

/**
 * @title cxToken Factory Contract
 *
 * @dev Deploys new instances of cxTokens on demand.
 *
 */
// slither-disable-next-line naming-convention
contract cxTokenFactory is ICxTokenFactory, Recoverable {
  // solhint-disable-previous-line
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using StoreKeyUtil for IStore;

  /**
   * @dev Constructs this contract
   * @param store Provide the store contract instance
   */
  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Deploys a new instance of cxTokens
   *
   * @custom:suppress-acl Can only be called by the latest policy contract
   *
   * @param coverKey Enter the cover key related to this cxToken instance
   * @param productKey Enter the product key related to this cxToken instance
   * @param expiryDate Specify the expiry date of this cxToken instance
   *
   */
  function deploy(
    bytes32 coverKey,
    bytes32 productKey,
    string calldata tokenName,
    uint256 expiryDate
  ) external override nonReentrant returns (address deployed) {
    s.mustNotBePaused();
    s.senderMustBePolicyContract();
    s.mustBeValidCoverKey(coverKey);
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);

    require(expiryDate > 0, "Please specify expiry date");

    (bytes memory bytecode, bytes32 salt) = cxTokenFactoryLibV1.getByteCode(s, coverKey, productKey, tokenName, expiryDate);

    require(s.getAddress(salt) == address(0), "Already deployed");

    // solhint-disable-next-line
    assembly {
      deployed := create2(
        callvalue(), // wei sent with current call
        // Actual code starts after skipping the first 32 bytes
        add(bytecode, 0x20),
        mload(bytecode), // Load the size of code contained in the first 32 bytes
        salt // Salt from function arguments
      )

      if iszero(extcodesize(deployed)) {
        // @suppress-revert This is correct usage
        revert(0, 0)
      }
    }

    s.setAddress(salt, deployed);
    s.setBoolByKeys(ProtoUtilV1.NS_COVER_CXTOKEN, deployed, true);
    s.setAddressArrayByKeys(ProtoUtilV1.NS_COVER_CXTOKEN, coverKey, productKey, deployed);

    emit CxTokenDeployed(coverKey, productKey, deployed, expiryDate);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_CXTOKEN_FACTORY;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../core/cxToken/cxToken.sol";

// slither-disable-next-line naming-convention
library cxTokenFactoryLibV1 {
  // solhint-disable-previous-line
  /**
   * @dev Gets the bytecode of the `cxToken` contract
   * @param s Provide the store instance
   * @param coverKey Provide the cover key
   * @param expiryDate Specify the expiry date of this cxToken instance
   */
  function getByteCode(
    IStore s,
    bytes32 coverKey,
    bytes32 productKey,
    string memory tokenName,
    uint256 expiryDate
  ) external pure returns (bytes memory bytecode, bytes32 salt) {
    salt = keccak256(abi.encodePacked(ProtoUtilV1.NS_COVER_CXTOKEN, coverKey, productKey, expiryDate));

    //slither-disable-next-line too-many-digits
    bytecode = abi.encodePacked(type(cxToken).creationCode, abi.encode(s, coverKey, productKey, tokenName, expiryDate));
    require(bytecode.length > 0, "Invalid bytecode");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IStore.sol";
import "../../interfaces/ICxToken.sol";
import "../../libraries/GovernanceUtilV1.sol";
import "../../libraries/PolicyHelperV1.sol";
import "../Recoverable.sol";

/**
 * @title cxToken
 *
 * @dev cxTokens are minted when someone purchases a cover.
 *
 * <br /> <br />
 *
 * The cxTokens can be exchanged for a USD stablecoin at a 1:1 exchange rate
 * after a cover incident is successfully resolved (minus platform fees).
 *  <br /> <br />
 *
 * **Restrictions:**
 *
 * - cxTokens cannot be transferred from one person to another.
 * - Only claims can be submitted with cxTokens
 * - There is a lag period before your cxTokens starts its coverage.
 * cxTokens start coverage the next day (or longer) at the UTC EOD timestamp and remain valid until the expiration date.
 * - The lag configuration can be found in [ProtoUtilV1.NS_COVERAGE_LAG](ProtoUtilV1.md)
 * and [PolicyAdmin.getCoverageLag](PolicyAdmin.md#getcoveragelag) function.
 *
 */
// slither-disable-next-line naming-convention
contract cxToken is ICxToken, Recoverable, ERC20 {
  // solhint-disable-previous-line
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for IStore;
  using PolicyHelperV1 for IStore;
  using GovernanceUtilV1 for IStore;

  // slither-disable-next-line naming-convention
  bytes32 public immutable override COVER_KEY; // solhint-disable-line
  // slither-disable-next-line naming-convention
  bytes32 public immutable override PRODUCT_KEY; // solhint-disable-line
  uint256 public immutable override createdOn = block.timestamp; // solhint-disable-line
  uint256 public immutable override expiresOn;

  /**
   * @dev Constructs this contract.
   *
   * @param store Provide the store contract instance
   * @param coverKey Enter the cover key
   * @param productKey Enter the product key
   * @param tokenName Enter token name for this ERC-20 contract. The token symbol will be `cxUSD`.
   * @param expiry Provide the cover expiry timestamp
   *
   */
  constructor(
    IStore store,
    bytes32 coverKey,
    bytes32 productKey,
    string memory tokenName,
    uint256 expiry
  ) ERC20(tokenName, "cxUSD") Recoverable(store) {
    COVER_KEY = coverKey;
    PRODUCT_KEY = productKey;
    expiresOn = expiry;
  }

  /** @dev Account to coverage start date to amount mapping */
  mapping(address => mapping(uint256 => uint256)) public coverageStartsFrom;

  /**
   * @dev Returns the value of the `coverageStartsFrom` mapping.
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param account Enter an account to get the `coverageStartsFrom` value.
   * @param date Enter a date. Ensure that you supply a UTC EOD value.
   *
   */
  function getCoverageStartsFrom(address account, uint256 date) external view override returns (uint256) {
    return coverageStartsFrom[account][date];
  }

  /**
   * @dev Gets sum of the lagged and, therefore, excluded policy of a given account.
   *
   * <br /><br />
   *
   * Only policies purchased within 24-48 hours (or longer depending on this cover's configuration) are valid.
   * Given the present codebase, the loop that follows may appear pointless and invalid.
   *
   * <br /><br />
   *
   * Since the protocol is upgradable but not cxTokens,
   * erroneous code could be introduced in the future,
   * which is why we go all the way until the resolution deadline.
   *
   * @param account Enter an account.
   *
   */
  function _getExcludedCoverageOf(address account) private view returns (uint256 exclusion) {
    uint256 incidentDate = s.getLatestIncidentDateInternal(COVER_KEY, PRODUCT_KEY);

    uint256 resolutionEOD = _getEOD(s.getResolutionTimestampInternal(COVER_KEY, PRODUCT_KEY));

    for (uint256 i = 0; i < 14; i++) {
      uint256 date = _getEOD(incidentDate + (i * 1 days));

      if (date > resolutionEOD) {
        break;
      }

      exclusion += coverageStartsFrom[account][date];
    }
  }

  /**
   * @dev Gets the claimable policy of an account.
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param account Enter an account.
   *
   */
  function getClaimablePolicyOf(address account) external view override returns (uint256) {
    uint256 exclusion = _getExcludedCoverageOf(account);
    uint256 balance = super.balanceOf(account);

    if (exclusion > balance) {
      return 0;
    }

    return balance - exclusion;
  }

  /**
   * @dev Mints cxTokens when a policy is purchased.
   * This feature can only be accessed by the latest policy smart contract.
   *
   * @custom:suppress-acl Can only be called by the latest policy contract
   *
   * @param coverKey Enter the cover key for which the cxTokens are being minted
   * @param to Enter the address where the minted token will be sent
   * @param amount Specify the amount of cxTokens to mint
   *
   */
  function mint(
    bytes32 coverKey,
    bytes32 productKey,
    address to,
    uint256 amount
  ) external override nonReentrant {
    require(amount > 0, "Please specify amount");
    require(coverKey == COVER_KEY, "Invalid cover");
    require(productKey == PRODUCT_KEY, "Invalid product");

    s.mustNotBePaused();
    s.senderMustBePolicyContract();
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);

    uint256 effectiveFrom = _getEOD(block.timestamp + s.getCoverageLagInternal(coverKey)); // solhint-disable-line
    coverageStartsFrom[to][effectiveFrom] += amount;

    super._mint(to, amount);
  }

  /**
   * @dev Gets the EOD (End of Day) time
   */
  function _getEOD(uint256 date) private pure returns (uint256) {
    (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(date);
    return BokkyPooBahsDateTimeLibrary.timestampFromDateTime(year, month, day, 23, 59, 59);
  }

  /**
   * @dev Burns the tokens held by the sender.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   * @param amount Specify the amount of tokens to burn
   *
   */
  function burn(uint256 amount) external override nonReentrant {
    require(amount > 0, "Please specify amount");

    s.mustNotBePaused();
    super._burn(msg.sender, amount);
  }

  /**
   * @dev Overrides Openzeppelin ERC-20 contract's `_beforeTokenTransfer` hook.
   * This is called during `transfer`, `transferFrom`, `mint`, and `burn` function invocation.
   *
   * <br /><br/>
   *
   * **cxToken Restrictions:**
   *
   * - An expired cxToken can't be transferred.
   * - cxTokens can only be transferred to the claims processor contract.
   *
   * @param from The account sending the cxTokens
   * @param to The account receiving the cxTokens
   *
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256
  ) internal view override {
    // solhint-disable-next-line
    if (block.timestamp > expiresOn) {
      require(to == address(0), "Expired cxToken");
    }

    // cxTokens can only be transferred to the claims processor contract
    if (from != address(0) && to != address(0)) {
      s.mustBeExactContract(ProtoUtilV1.CNS_CLAIM_PROCESSOR, to);
    }
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../interfaces/ICxToken.sol";

contract MockCxTokenPolicy {
  ICxToken public cxToken;

  constructor(ICxToken _cxToken) {
    cxToken = _cxToken;
  }

  function callMint(
    bytes32 key,
    bytes32 productKey,
    address to,
    uint256 amount
  ) external {
    cxToken.mint(key, productKey, to, amount);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./Resolvable.sol";
import "../../../interfaces/IResolution.sol";
import "../../../interfaces/IUnstakable.sol";
import "../../../libraries/GovernanceUtilV1.sol";
import "../../../libraries/ValidationLibV1.sol";
import "../../../libraries/NTransferUtilV2.sol";

/**
 * @title Unstakable Contract
 * @dev Enables voters to unstake their NPM tokens after
 * resolution is achieved on any cover product.
 */
abstract contract Unstakable is Resolvable, IUnstakable {
  using GovernanceUtilV1 for IStore;
  using ProtoUtilV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using ValidationLibV1 for bytes32;
  using NTransferUtilV2 for IERC20;

  /**
   * @dev Reporters on the valid camp can unstake their tokens even after the claim period is over.
   * Unlike `unstakeWithClaim`, stakers can unstake but do not receive any reward if they choose to
   * use this function.
   *
   * @custom:warning Warning:
   *
   * You should instead use `unstakeWithClaim` throughout the claim period.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-pausable
   *
   * @param coverKey Enter the cover key
   * @param productKey Enter the product key
   * @param incidentDate Enter the incident date
   */
  function unstake(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external override nonReentrant {
    require(incidentDate > 0, "Please specify incident date");
    s.validateUnstakeWithoutClaim(coverKey, productKey, incidentDate);

    (, , uint256 myStakeInWinningCamp) = s.getResolutionInfoForInternal(msg.sender, coverKey, productKey, incidentDate);

    // Set the unstake details
    s.updateUnstakeDetailsInternal(msg.sender, coverKey, productKey, incidentDate, myStakeInWinningCamp, 0, 0, 0);

    s.npmToken().ensureTransfer(msg.sender, myStakeInWinningCamp);
    s.updateStateAndLiquidity(coverKey);

    emit Unstaken(coverKey, productKey, msg.sender, myStakeInWinningCamp, 0);
  }

  /**
   * @dev Reporters on the valid camp can unstake their token with a `claim` to receive
   * back their original stake with a portion of the invalid camp's stake
   * as an additional reward.
   *
   * During each `unstake with claim` processing, the protocol distributes reward to
   * the final reporter and also burns some NPM tokens, as described in the documentation.
   *
   * @custom:suppress-acl This is a publicly accessible feature
   * @custom:suppress-pausable Already checked inside `validateUnstakeWithClaim`
   *
   *
   * @param coverKey Enter the cover key
   * @param productKey Enter the product key
   * @param incidentDate Enter the incident date
   */
  function unstakeWithClaim(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external override nonReentrant {
    require(incidentDate > 0, "Please specify incident date");
    s.validateUnstakeWithClaim(coverKey, productKey, incidentDate);

    address finalReporter = s.getReporterInternal(coverKey, productKey, incidentDate);
    address burner = s.getBurnAddress();

    (, , uint256 myStakeInWinningCamp, uint256 toBurn, uint256 toReporter, uint256 myReward, ) = s.getUnstakeInfoForInternal(msg.sender, coverKey, productKey, incidentDate);

    // Set the unstake details
    s.updateUnstakeDetailsInternal(msg.sender, coverKey, productKey, incidentDate, myStakeInWinningCamp, myReward, toBurn, toReporter);

    uint256 myStakeWithReward = myReward + myStakeInWinningCamp;

    s.npmToken().ensureTransfer(msg.sender, myStakeWithReward);

    if (toReporter > 0) {
      s.npmToken().ensureTransfer(finalReporter, toReporter);
    }

    if (toBurn > 0) {
      s.npmToken().ensureTransfer(burner, toBurn);
    }

    s.updateStateAndLiquidity(coverKey);

    emit Unstaken(coverKey, productKey, msg.sender, myStakeInWinningCamp, myReward);
    emit ReporterRewardDistributed(coverKey, productKey, msg.sender, finalReporter, myReward, toReporter);
    emit GovernanceBurned(coverKey, productKey, msg.sender, burner, myReward, toBurn);
  }

  /**
   * @dev Gets the unstake information for the supplied account
   *
   * Warning: this function does not validate the input arguments.
   *
   * @param account Enter account to get the unstake information of
   * @param coverKey Enter the cover key
   * @param incidentDate Enter the incident date
   * @param totalStakeInWinningCamp Returns the sum total of the stakes contributed by the winning camp
   * @param totalStakeInLosingCamp Returns the sum total of the stakes contributed by the losing camp
   * @param myStakeInWinningCamp Returns the sum total of the supplied account's stakes in the winning camp
   * @param toBurn Returns the amount of tokens that will be booked as protocol revenue and immediately burned
   * @param toReporter Returns the amount of tokens that will be sent to the final reporter as the `first reporter` reward
   * @param myReward Returns the amount of tokens that the supplied account will receive as `reporting reward`
   */
  function getUnstakeInfoFor(
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  )
    external
    view
    override
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp,
      uint256 toBurn,
      uint256 toReporter,
      uint256 myReward,
      uint256 unstaken
    )
  {
    return s.getUnstakeInfoForInternal(account, coverKey, productKey, incidentDate);
  }
}

/* solhint-disable function-max-lines */
// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./Finalization.sol";
import "../../../interfaces/IResolvable.sol";
import "../../../libraries/NTransferUtilV2.sol";

/**
 * @title Resolvable Contract
 * @dev Enables governance agents to resolve a contract undergoing reporting.
 * Has a cool-down period of 24-hours (or as overridden) during when governance admins
 * can perform emergency resolution to defend against governance attacks.
 */
abstract contract Resolvable is Finalization, IResolvable {
  using GovernanceUtilV1 for IStore;
  using ProtoUtilV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using RoutineInvokerLibV1 for IStore;
  using ValidationLibV1 for IStore;
  using ValidationLibV1 for bytes32;

  /**
   * @dev Marks as a cover as "resolved" after the reporting period.
   * A resolution has a (configurable) 24-hour cooldown period
   * that enables governance admins to revese decision in case of
   * attack or mistake.
   *
   * @custom:note Please note the following:
   *
   * An incident can be resolved:
   *
   * - by a governance agent
   * - if it was reported
   * - after the reporting period
   * - if it wasn't resolved earlier
   *
   * @param coverKey Enter the cover key you want to resolve
   * @param productKey Enter the product key you want to resolve
   * @param incidentDate Enter the date of this incident reporting
   */
  function resolve(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external override nonReentrant {
    require(incidentDate > 0, "Please specify incident date");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeGovernanceAgent(s);

    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeReportingOrDisputed(coverKey, productKey);
    s.mustBeAfterReportingPeriod(coverKey, productKey);
    s.mustNotHaveResolutionDeadline(coverKey, productKey);

    bool decision = s.getProductStatusInternal(coverKey, productKey) == CoverUtilV1.ProductStatus.IncidentHappened;

    _resolve(coverKey, productKey, incidentDate, decision, false);
  }

  /**
   * @dev Enables governance admins to perform emergency resolution.
   *
   * @custom:note Please note the following:
   *
   * An incident can undergo an emergency resolution:
   *
   * - by a governance admin
   * - if it was reported
   * - after the reporting period
   * - before the resolution deadline
   *
   * @param coverKey Enter the cover key on which you want to perform emergency resolve
   * @param productKey Enter the product key on which you want to perform emergency resolve
   * @param incidentDate Enter the date of this incident reporting
   */
  function emergencyResolve(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    bool decision
  ) external override nonReentrant {
    require(incidentDate > 0, "Please specify incident date");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeGovernanceAdmin(s);
    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeAfterReportingPeriod(coverKey, productKey);
    s.mustBeBeforeResolutionDeadline(coverKey, productKey);

    _resolve(coverKey, productKey, incidentDate, decision, true);
  }

  function _resolve(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    bool decision,
    bool emergency
  ) private {
    // A grace period given to a governance admin(s) to defend
    // against a concensus attack(s).
    uint256 cooldownPeriod = s.getCoolDownPeriodInternal(coverKey);

    // The timestamp until when a governance admin is allowed
    // to perform emergency resolution.
    // After this timestamp, the cover has to be claimable
    // or finalized
    uint256 deadline = s.getResolutionDeadlineInternal(coverKey, productKey);

    // A cover, when being resolved, will either directly go to finalization or have a claim period.
    //
    // Decision: False Reporting
    // 1. A governance admin can still overwrite, override, or reverse this decision before `deadline`.
    // 2. After the deadline and before finalization, the NPM holders
    //    who staked for `False Reporting` camp can withdraw the original stake + reward.
    // 3. After finalization, the NPM holders who staked for this camp will only be able to receive
    // back the original stake. No rewards.
    //
    // Decision: Claimable
    //
    // 1. A governance admin can still overwrite, override, or reverse this decision before `deadline`.
    // 2. All policyholders must claim during the `Claim Period`. Otherwise, claims are not valid.
    // 3. After the deadline and before finalization, the NPM holders
    //    who staked for `Incident Happened` camp can withdraw the original stake + reward.
    // 4. After finalization, the NPM holders who staked for this camp will only be able to receive
    // back the original stake. No rewards.
    CoverUtilV1.ProductStatus status = decision ? CoverUtilV1.ProductStatus.Claimable : CoverUtilV1.ProductStatus.FalseReporting;

    // Status can change during `Emergency Resolution` attempt(s)
    s.setStatusInternal(coverKey, productKey, incidentDate, status);

    if (deadline == 0) {
      // Deadline can't be before claim begin date.
      // In other words, once a cover becomes claimable, emergency resolution
      // can not be performed any longer
      deadline = block.timestamp + cooldownPeriod; // solhint-disable-line
      s.setUintByKeys(ProtoUtilV1.NS_RESOLUTION_DEADLINE, coverKey, productKey, deadline);
    }

    // Claim begins when deadline timestamp is passed
    uint256 claimBeginsFrom = decision ? deadline + 1 : 0;

    // Claim expires after the period specified by the cover creator.
    uint256 claimExpiresAt = decision ? claimBeginsFrom + s.getClaimPeriod(coverKey) : 0;

    s.setUintByKeys(ProtoUtilV1.NS_CLAIM_BEGIN_TS, coverKey, productKey, claimBeginsFrom);
    s.setUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey, claimExpiresAt);

    s.updateStateAndLiquidity(coverKey);

    emit Resolved(coverKey, productKey, incidentDate, deadline, decision, emergency, claimBeginsFrom, claimExpiresAt);
  }

  /**
   * @dev Allows a governance admin to add or update resolution cooldown period for a given cover.
   *
   * @param coverKey Provide a coverKey or leave it empty. If empty, the cooldown period is set as
   * fallback value. Covers that do not have customized cooldown period will infer to the fallback value.
   * @param period Enter the cooldown period duration
   */
  function configureCoolDownPeriod(bytes32 coverKey, uint256 period) external override nonReentrant {
    s.mustNotBePaused();
    AccessControlLibV1.mustBeGovernanceAdmin(s);

    require(period > 0, "Please specify period");

    if (coverKey > 0) {
      s.setUintByKeys(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD, coverKey, period);
    } else {
      s.setUintByKey(ProtoUtilV1.NS_RESOLUTION_COOL_DOWN_PERIOD, period);
    }

    emit CooldownPeriodConfigured(coverKey, period);
  }

  /**
   * @dev Gets the cooldown period of a given cover
   *
   * Warning: this function does not validate the cover key supplied.
   *
   */
  function getCoolDownPeriod(bytes32 coverKey) external view override returns (uint256) {
    return s.getCoolDownPeriodInternal(coverKey);
  }

  /**
   * @dev Gets the resolution deadline of a given cover
   *
   * Warning: this function does not validate the cover and product key supplied.
   *
   */
  function getResolutionDeadline(bytes32 coverKey, bytes32 productKey) external view override returns (uint256) {
    return s.getResolutionDeadlineInternal(coverKey, productKey);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IFinalization.sol";
import "./IResolvable.sol";
import "./IUnstakable.sol";
import "./IMember.sol";

//solhint-disable-next-line
interface IResolution is IFinalization, IResolvable, IUnstakable, IMember {

}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./IStore.sol";

interface IUnstakable {
  event Unstaken(bytes32 indexed coverKey, bytes32 indexed productKey, address indexed caller, uint256 originalStake, uint256 reward);
  event ReporterRewardDistributed(bytes32 indexed coverKey, bytes32 indexed productKey, address caller, address indexed reporter, uint256 originalReward, uint256 reporterReward);
  event GovernanceBurned(bytes32 indexed coverKey, bytes32 indexed productKey, address caller, address indexed burner, uint256 originalReward, uint256 burnedAmount);

  function unstake(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external;

  function unstakeWithClaim(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external;

  function getUnstakeInfoFor(
    address account,
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  )
    external
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp,
      uint256 toBurn,
      uint256 toReporter,
      uint256 myReward,
      uint256 unstaken
    );
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../Recoverable.sol";
import "../../../interfaces/IFinalization.sol";
import "../../../libraries/GovernanceUtilV1.sol";
import "../../../libraries/ValidationLibV1.sol";
import "../../../libraries/RoutineInvokerLibV1.sol";

/**
 * @title Finalization Contract
 * @dev This contract allows governance agents "finalize"
 * a resolved cover product after the claim period.
 *
 * When a cover product is finalized, it resets back to normal
 * state where tokenholders can again supply liquidity
 * and purchase policies.
 */
abstract contract Finalization is Recoverable, IFinalization {
  using GovernanceUtilV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using RoutineInvokerLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using ValidationLibV1 for bytes32;

  /**
   * @dev Finalizes a cover pool or a product contract.
   * Once finalized, the cover resets back to the normal state.
   *
   * @custom:note Please note the following:
   *
   * An incident can be finalized:
   *
   * - by a governance agent
   * - if it was reported and resolved
   * - after claim period
   * - after reassurance fund is capitalized back to the liquidity pool
   *
   * @param coverKey Enter the cover key you want to finalize
   * @param productKey Enter the product key you want to finalize
   * @param incidentDate Enter the date of this incident reporting
   */
  function finalize(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external override nonReentrant {
    require(incidentDate > 0, "Please specify incident date");

    s.mustNotBePaused();
    AccessControlLibV1.mustBeGovernanceAgent(s);

    s.mustBeSupportedProductOrEmpty(coverKey, productKey);
    s.mustBeValidIncidentDate(coverKey, productKey, incidentDate);
    s.mustBeClaimingOrDisputed(coverKey, productKey);
    s.mustBeAfterResolutionDeadline(coverKey, productKey);
    s.mustBeAfterClaimExpiry(coverKey, productKey);

    uint256 transferable = s.getReassuranceTransferrableInternal(coverKey, productKey, incidentDate);
    require(transferable == 0, "Pool must be capitalized");

    _finalize(coverKey, productKey, incidentDate);
  }

  /**
   * @custom:note Do not pass incident date as we need status by key and incident date for historical significance
   * @custom:warning Warning:
   *
   * Do not reset the first reporters **by incident date** as it is needed for historical signification.
   *
   */
  function _finalize(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) private {
    // Reset to normal
    s.setStatusInternal(coverKey, productKey, 0, CoverUtilV1.ProductStatus.Normal);

    s.deleteUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_INCIDENT_DATE, coverKey, productKey);
    s.deleteUintByKeys(ProtoUtilV1.NS_GOVERNANCE_RESOLUTION_TS, coverKey, productKey);
    s.deleteUintByKeys(ProtoUtilV1.NS_CLAIM_BEGIN_TS, coverKey, productKey);
    s.deleteUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, coverKey, productKey);

    s.deleteAddressByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, coverKey, productKey);
    s.deleteUintByKeys(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, coverKey, productKey);
    s.deleteUintByKeys(ProtoUtilV1.NS_RESOLUTION_DEADLINE, coverKey, productKey);
    s.deleteBoolByKey(GovernanceUtilV1.getHasDisputeKeyInternal(coverKey, productKey));

    // @warning: do not uncomment these lines as these vales are required to enable unstaking any time after finalization
    // s.deleteAddressByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_YES, coverKey, incidentDate)));
    // s.deleteAddressByKey(keccak256(abi.encodePacked(ProtoUtilV1.NS_GOVERNANCE_REPORTING_WITNESS_NO, coverKey, incidentDate)));

    s.updateStateAndLiquidity(coverKey);
    emit Finalized(coverKey, productKey, msg.sender, incidentDate);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IResolvable {
  event Resolved(
    bytes32 indexed coverKey,
    bytes32 indexed productKey,
    uint256 incidentDate,
    uint256 resolutionDeadline,
    bool decision,
    bool emergency,
    uint256 claimBeginsFrom,
    uint256 claimExpiresAt
  );
  event CooldownPeriodConfigured(bytes32 indexed coverKey, uint256 period);

  function resolve(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external;

  function emergencyResolve(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate,
    bool decision
  ) external;

  function configureCoolDownPeriod(bytes32 coverKey, uint256 period) external;

  function getCoolDownPeriod(bytes32 coverKey) external view returns (uint256);

  function getResolutionDeadline(bytes32 coverKey, bytes32 productKey) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IFinalization {
  event Finalized(bytes32 indexed coverKey, bytes32 indexed productKey, address finalizer, uint256 indexed incidentDate);

  function finalize(
    bytes32 coverKey,
    bytes32 productKey,
    uint256 incidentDate
  ) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./Unstakable.sol";
import "../../../interfaces/IResolution.sol";

/**
 * @title Resolution Contract
 * @dev This contract enables governance agents or admins to resolve
 * actively-reporting cover products. Once a resolution occurs, the
 * NPM token holders who voted for the valid camp can unstake
 * their staking during the claim period with additional rewards.
 */
contract Resolution is IResolution, Unstakable {
  using GovernanceUtilV1 for IStore;
  using ProtoUtilV1 for IStore;
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using ValidationLibV1 for IStore;
  using ValidationLibV1 for bytes32;

  constructor(IStore store) Recoverable(store) {} // solhint-disable-line

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() external pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_RESOLUTION;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../libraries/NTransferUtilV2.sol";

contract NTransferUtilV2Intermediate {
  using NTransferUtilV2 for IERC20;

  function iTransfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external {
    token.ensureTransfer(recipient, amount);
  }

  function iTransferFrom(
    IERC20 token,
    address sender,
    address recipient,
    uint256 amount
  ) external {
    token.ensureTransferFrom(sender, recipient, amount);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/uniswap-v2/IUniswapV2FactoryLike.sol";

contract FakeUniswapV2FactoryLike is IUniswapV2FactoryLike {
  address public pair;

  constructor(address _pair) {
    pair = _pair;
  }

  function getPair(address, address) external view override returns (address) {
    return pair;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/uniswap-v2/IUniswapV2PairLike.sol";

contract FakeUniswapV2PairLike is IUniswapV2PairLike {
  address public override token0;
  address public override token1;

  constructor(address _token0, address _token1) {
    token0 = _token0;
    token1 = _token1;
  }

  function totalSupply() external pure override returns (uint256) {
    return 100 ether;
  }

  function getReserves()
    external
    view
    override
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    )
  {
    reserve0 = 200 ether;
    reserve1 = 100 ether;
    blockTimestampLast = uint32(block.timestamp); // solhint-disable-line
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/uniswap-v2/IUniswapV2PairLike.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract FakeUniswapPair is IUniswapV2PairLike, ERC20 {
  address public override token0;
  address public override token1;

  constructor(address _token0, address _token1) ERC20("PAIR", "PAIR") {
    token0 = _token0;
    token1 = _token1;

    super._mint(msg.sender, 100000 ether);
  }

  function totalSupply() public view override(ERC20, IUniswapV2PairLike) returns (uint256) {
    return super.totalSupply();
  }

  function getReserves()
    external
    view
    override
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    )
  {
    reserve0 = 100000 ether;
    reserve1 = 50000 ether;
    blockTimestampLast = uint32(block.timestamp - 1 hours); // solhint-disable-line
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../dependencies/uniswap-v2/IUniswapV2RouterLike.sol";

contract FakeUniswapV2RouterLike is IUniswapV2RouterLike {
  address public tokenA;
  address public tokenB;

  function factory() external view override returns (address) {
    return address(this);
  }

  function getAmountOut(
    uint256 amountIn,
    uint256,
    uint256
  ) external pure override returns (uint256) {
    return amountIn * 2;
  }

  function getAmountIn(
    uint256 amountOut,
    uint256,
    uint256
  ) external pure override returns (uint256) {
    return amountOut * 2;
  }

  function getAmountsOut(uint256 multiplier, address[] calldata) external pure override returns (uint256[] memory) {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = multiplier;
    amounts[1] = multiplier;

    return amounts;
  }

  function quote(
    uint256 amountA,
    uint256,
    uint256
  ) public pure virtual override returns (uint256 amountB) {
    return amountA;
  }

  function getAmountsIn(uint256 multiplier, address[] calldata) external pure override returns (uint256[] memory) {
    uint256[] memory amounts = new uint256[](2);

    amounts[0] = multiplier;
    amounts[1] = multiplier;

    return amounts;
  }

  function addLiquidity(
    address _tokenA,
    address _tokenB,
    uint256 _amountADesired,
    uint256 _amountBDesired,
    uint256,
    uint256,
    address,
    uint256
  )
    external
    override
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    tokenA = _tokenA;
    tokenB = _tokenB;

    amountA = _amountADesired;
    amountB = _amountBDesired;
    liquidity = 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BondPoolBase.sol";

contract BondPool is BondPoolBase {
  using BondPoolLibV1 for IStore;
  using ValidationLibV1 for IStore;

  constructor(IStore s) BondPoolBase(s) {} //solhint-disable-line

  /**
   * @dev Create a new bond contract by supplying your LP tokens
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   */
  function createBond(uint256 lpTokens, uint256 minNpmDesired) external override nonReentrant {
    s.mustNotBePaused();

    require(lpTokens > 0, "Please specify `lpTokens`");
    require(minNpmDesired > 0, "Please enter `minNpmDesired`");

    uint256[] memory values = s.createBondInternal(lpTokens, minNpmDesired);
    emit BondCreated(msg.sender, lpTokens, values[0], values[1]);
  }

  /**
   * @dev Claim your bond and receive your NPM tokens after waiting period
   *
   * @custom:suppress-acl This is a publicly accessible feature
   *
   */
  function claimBond() external override nonReentrant {
    s.mustNotBePaused();

    // @suppress-zero-value-check The uint values are validated in the function `claimBondInternal`
    uint256[] memory values = s.claimBondInternal();
    emit BondClaimed(msg.sender, values[0]);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../core/Recoverable.sol";

contract FakeRecoverable is Recoverable {
  constructor(IStore s) Recoverable(s) {} // solhint-disable-line
}