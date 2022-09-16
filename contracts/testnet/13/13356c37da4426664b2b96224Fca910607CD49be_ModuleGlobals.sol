// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";
import {IModuleGlobals} from "../../interfaces/IModuleGlobals.sol";

/**
 * @title ModuleGlobals
 * @author Lens Protocol
 *
 * @notice This contract contains data relevant to Lens modules, such as the module governance address, treasury
 * address and treasury fee BPS.
 *
 * NOTE: The reason we have an additional governance address instead of just fetching it from the hub is to
 * allow the flexibility of using different governance executors.
 */
contract ModuleGlobals is IModuleGlobals {
  uint16 internal constant BPS_MAX = 10000;

  mapping(address => bool) internal _currencyWhitelisted;
  address internal _governance;
  address internal _treasury;
  uint16 internal _treasuryFee;

  modifier onlyGov() {
    if (msg.sender != _governance) revert Errors.NotGovernance();
    _;
  }

  /**
   * @notice Initializes the governance, treasury and treasury fee amounts.
   *
   * @param governance The governance address which has additional control over setting certain parameters.
   * @param treasury The treasury address to direct fees to.
   * @param treasuryFee The treasury fee in BPS to levy on collects.
   */
  constructor(
    address governance,
    address treasury,
    uint16 treasuryFee
  ) {
    _setGovernance(governance);
    _setTreasury(treasury);
    _setTreasuryFee(treasuryFee);
  }

  /// @inheritdoc IModuleGlobals
  function setGovernance(address newGovernance) external override onlyGov {
    _setGovernance(newGovernance);
  }

  /// @inheritdoc IModuleGlobals
  function setTreasury(address newTreasury) external override onlyGov {
    _setTreasury(newTreasury);
  }

  /// @inheritdoc IModuleGlobals
  function setTreasuryFee(uint16 newTreasuryFee) external override onlyGov {
    _setTreasuryFee(newTreasuryFee);
  }

  /// @inheritdoc IModuleGlobals
  function whitelistCurrency(address currency, bool toWhitelist) external override onlyGov {
    _whitelistCurrency(currency, toWhitelist);
  }

  /// @inheritdoc IModuleGlobals
  function isCurrencyWhitelisted(address currency) external view override returns (bool) {
    return _currencyWhitelisted[currency];
  }

  /// @inheritdoc IModuleGlobals
  function getGovernance() external view override returns (address) {
    return _governance;
  }

  /// @inheritdoc IModuleGlobals
  function getTreasury() external view override returns (address) {
    return _treasury;
  }

  /// @inheritdoc IModuleGlobals
  function getTreasuryFee() external view override returns (uint16) {
    return _treasuryFee;
  }

  //@inheritdoc IModuleGlobals
  function getTreasuryData() external view override returns (address, uint16) {
    return (_treasury, _treasuryFee);
  }

  function _setGovernance(address newGovernance) internal {
    if (newGovernance == address(0)) revert Errors.InitParamsInvalid();
    address prevGovernance = _governance;
    _governance = newGovernance;
    emit Events.ModuleGlobalsGovernanceSet(prevGovernance, newGovernance, block.timestamp);
  }

  function _setTreasury(address newTreasury) internal {
    if (newTreasury == address(0)) revert Errors.InitParamsInvalid();
    address prevTreasury = _treasury;
    _treasury = newTreasury;
    emit Events.ModuleGlobalsTreasurySet(prevTreasury, newTreasury, block.timestamp);
  }

  function _setTreasuryFee(uint16 newTreasuryFee) internal {
    if (newTreasuryFee >= BPS_MAX / 2) revert Errors.InitParamsInvalid();
    uint16 prevTreasuryFee = _treasuryFee;
    _treasuryFee = newTreasuryFee;
    emit Events.ModuleGlobalsTreasuryFeeSet(prevTreasuryFee, newTreasuryFee, block.timestamp);
  }

  function _whitelistCurrency(address currency, bool toWhitelist) internal {
    if (currency == address(0)) revert Errors.InitParamsInvalid();
    bool prevWhitelisted = _currencyWhitelisted[currency];
    _currencyWhitelisted[currency] = toWhitelist;
    emit Events.ModuleGlobalsCurrencyWhitelisted(currency, prevWhitelisted, toWhitelist, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
  error CannotInitImplementation();
  error Initialized();
  error SignatureExpired();
  error ZeroSpender();
  error SignatureInvalid();
  error NotOwnerOrApproved();
  error NotHub();
  error TokenDoesNotExist();
  error NotGovernance();
  error NotGovernanceOrEmergencyAdmin();
  error EmergencyAdminCannotUnpause();
  error CallerNotWhitelistedModule();
  error CollectModuleNotWhitelisted();
  error FollowModuleNotWhitelisted();
  error ReferenceModuleNotWhitelisted();
  error ProfileCreatorNotWhitelisted();
  error ReadModuleNotWhitelisted();
  error ModuleNotWhitelisted();
  error NotProfileOwner();
  error NotProfileOwnerOrDispatcher();
  error NotDispatcher();
  error PublicationDoesNotExist();
  error HandleTaken();
  error HandleLengthInvalid();
  error HandleContainsInvalidCharacters();
  error HandleFirstCharInvalid();
  error ProfileImageURILengthInvalid();
  error ProfileVideoURILengthInvalid();
  error ProfileMetadataURILengthInvalid();
  error CallerNotFollowNFT();
  error CallerNotCollectNFT();
  error BlockNumberInvalid();
  error ArrayMismatch();
  error CannotCommentOnSelf();
  error NotWhitelisted();
  error NoChangeToTheState();
  error InvalidAddress();
  error SignatureReplayed();
  error NotCharger();
  error ModuleNotAuthorized();
  error ModuleNotAuthorizedFor(uint256 consumerId);

  // Module Errors
  error InitParamsInvalid();
  error CollectExpired();
  error FollowInvalid();
  error ModuleDataMismatch();
  error FollowNotApproved();
  error MintLimitExceeded();
  error CollectNotAllowed();
  error IncompleteData();

  // MultiState Errors
  error Paused();
  error PublishingPaused();

  // Balance Errors
  error TokenAllowanceTooLow();
  error BalanceInsufficient();
  error NotTreasury();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "./DataTypes.sol";

library Events {
  /**
   * @dev Emitted when the NFT contract's name and symbol are set at initialization.
   *
   * @param name The NFT name set.
   * @param symbol The NFT symbol set.
   * @param timestamp The current block timestamp.
   */
  event BaseInitialized(string name, string symbol, uint256 timestamp);

  /**
   * @dev Emitted when the hub state is set.
   *
   * @param caller The caller who set the state.
   * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
   * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
   * @param timestamp The current block timestamp.
   */
  event StateSet(
    address indexed caller,
    DataTypes.ProtocolState indexed prevState,
    DataTypes.ProtocolState indexed newState,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
   * governance address, as we cannot guarantee this will always be the case due to upgradeability.
   *
   * @param caller The caller who set the governance address.
   * @param prevGovernance The previous governance address.
   * @param newGovernance The new governance address set.
   * @param timestamp The current block timestamp.
   */
  event GovernanceSet(
    address indexed caller,
    address indexed prevGovernance,
    address indexed newGovernance,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
   * governance address, as we cannot guarantee this will always be the case due to upgradeability.
   *
   * @param caller The caller who set the emergency admin address.
   * @param oldEmergencyAdmin The previous emergency admin address.
   * @param newEmergencyAdmin The new emergency admin address set.
   * @param timestamp The current block timestamp.
   */
  event EmergencyAdminSet(
    address indexed caller,
    address indexed oldEmergencyAdmin,
    address indexed newEmergencyAdmin,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the protocol fund address is changed. We emit the caller even though it should be the previous
   * protocol fund address, as we cannot guarantee this will always be the case due to upgradeability.
   *
   * @param caller The caller who set the protocol fund address.
   * @param prevProtocolFund The previous protocol fund address.
   * @param newProtocolFund The new protocol fund address set.
   * @param timestamp The current block timestamp.
   */
  event ProtocolFundSet(
    address indexed caller,
    address indexed prevProtocolFund,
    address indexed newProtocolFund,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the users balances address is changed.
   *
   * @param caller The caller who set the users balances address.
   * @param newUsersBalance The new users balance address set.
   * @param timestamp The current block timestamp.
   */
  event UsersBalancesSet(address indexed caller, address indexed newUsersBalance, uint256 timestamp);

  /**
   * @dev Emitted when the charger address is changed.
   *
   * @param caller The caller who set the protocol fund address.
   * @param newCharger The new charger address set.
   * @param timestamp The current block timestamp.
   */
  event ChargerSet(address indexed caller, address indexed newCharger, uint256 timestamp);

  /**
   * @dev Emitted when a profile creator is added to or removed from the whitelist.
   *
   * @param profileCreator The address of the profile creator.
   * @param whitelisted Whether or not the profile creator is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event ProfileCreatorWhitelisted(address indexed profileCreator, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a follow module is added to or removed from the whitelist.
   *
   * @param followModule The address of the follow module.
   * @param whitelisted Whether or not the follow module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event FollowModuleWhitelisted(address indexed followModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a reference module is added to or removed from the whitelist.
   *
   * @param referenceModule The address of the reference module.
   * @param whitelisted Whether or not the reference module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event ReferenceModuleWhitelisted(address indexed referenceModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a collect module is added to or removed from the whitelist.
   *
   * @param collectModule The address of the collect module.
   * @param whitelisted Whether or not the collect module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event CollectModuleWhitelisted(address indexed collectModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a read module is added to or removed from the whitelist.
   *
   * @param readModule The address of the read module.
   * @param whitelisted Whether or not the collect module is being added to the whitelist.
   * @param timestamp The current block timestamp.
   */
  event ReadModuleWhitelisted(address indexed readModule, bool indexed whitelisted, uint256 timestamp);

  /**
   * @dev Emitted when a profile is created.
   *
   * @param profileId The newly created profile's token ID.
   * @param creator The profile creator, who created the token with the given profile ID.
   * @param vars The CreateProfileData struct containing the following parameters:
   *      to: The address receiving the profile.
   *      handle: The handle to set for the profile, must be unique and non-empty.
   *      imageURI: The URI to set for the profile image.
   *      followModule: The follow module to use, can be the zero address.
   *      followModuleReturnData: The data returned from the follow module's initialization. This is abi encoded
   *      followNFTURI: The URI to set for the follow NFT.
   *      videoURI The URI to set for the profile video.
   *      metadataURI The URI to set for the profile metadata.
   * @param timestamp The current block timestamp.
   */
  event ProfileCreated(
    uint256 indexed profileId,
    address indexed creator,
    DataTypes.CreateProfileEvent vars,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a a default profile is set for a wallet as its main identity
   *
   * @param wallet The wallet which set or unset its default profile.
   * @param profileId The token ID of the profile being set as default, or zero.
   * @param timestamp The current block timestamp.
   */
  event DefaultProfileSet(address indexed wallet, uint256 indexed profileId, uint256 timestamp);

  /**
   * @dev Emitted when a dispatcher is set for a specific profile.
   *
   * @param profileId The token ID of the profile for which the dispatcher is set.
   * @param dispatcher The dispatcher set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event DispatcherSet(uint256 indexed profileId, address indexed dispatcher, uint256 timestamp);

  /**
   * @dev Emitted when a profile's URI is set.
   *
   * @param profileId The token ID of the profile for which the URI is set.
   * @param imageURI The URI set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event ProfileImageURISet(uint256 indexed profileId, string imageURI, uint256 timestamp);

  /**
   * @dev Emitted when a follow NFT's URI is set.
   *
   * @param profileId The token ID of the profile for which the followNFT URI is set.
   * @param followNFTURI The follow NFT URI set.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTURISet(uint256 indexed profileId, string followNFTURI, uint256 timestamp);

  /**
   * @dev Emitted when a profile's URI is set.
   *
   * @param profileId The token ID of the profile for which the URI is set.
   * @param videoURI The URI set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event ProfileVideoURISet(uint256 indexed profileId, string videoURI, uint256 timestamp);

  /**
   * @dev Emitted when a profile's URI is set.
   *
   * @param profileId The token ID of the profile for which the URI is set.
   * @param metadataURI The URI set for the given profile.
   * @param timestamp The current block timestamp.
   */
  event ProfileMetadataURISet(uint256 indexed profileId, string metadataURI, uint256 timestamp);

  /**
   * @dev Emitted when a profile's follow module is set.
   *
   * @param profileId The profile's token ID.
   * @param followModule The profile's newly set follow module. This CAN be the zero address.
   * @param followModuleReturnData The data returned from the follow module's initialization. This is abi encoded
   * and totally depends on the follow module chosen.
   * @param timestamp The current block timestamp.
   */
  event FollowModuleSet(
    uint256 indexed profileId,
    address followModule,
    bytes followModuleReturnData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a "post" is published.
   *
   * @param profileId The profile's token ID.
   * @param pubId The new publication's ID.
   * @param contentURI The URI mapped to this new publication.
   * @param modulesData The data related to the modules that are associated to the post.
   * @param timestamp The current block timestamp.
   */
  event PostCreated(
    uint256 indexed profileId,
    uint256 indexed pubId,
    string contentURI,
    DataTypes.PostModulesData modulesData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a "comment" is published.
   *
   * @param profileId The profile's token ID.
   * @param pubId The new publication's ID.
   * @param contentURI The URI mapped to this new publication.
   * @param profileIdPointed The profile token ID that this comment points to.
   * @param pubIdPointed The publication ID that this comment points to.
   * @param referenceModuleData The data passed to the reference module.
   * @param collectModule The collect module mapped to this new publication. This CANNOT be the zero address.
   * @param collectModuleReturnData The data returned from the collect module's initialization for this given
   * publication. This is abi encoded and totally depends on the collect module chosen.
   * @param referenceModule The reference module set for this publication.
   * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
   * encoded and totally depends on the reference module chosen.
   * @param timestamp The current block timestamp.
   */
  event CommentCreated(
    uint256 indexed profileId,
    uint256 indexed pubId,
    string contentURI,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes referenceModuleData,
    address collectModule,
    bytes collectModuleReturnData,
    address referenceModule,
    bytes referenceModuleReturnData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a "mirror" is published.
   *
   * @param profileId The profile's token ID.
   * @param pubId The new publication's ID.
   * @param profileIdPointed The profile token ID that this mirror points to.
   * @param pubIdPointed The publication ID that this mirror points to.
   * @param referenceModuleData The data passed to the reference module.
   * @param referenceModule The reference module set for this publication.
   * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
   * encoded and totally depends on the reference module chosen.
   * @param timestamp The current block timestamp.
   */
  event MirrorCreated(
    uint256 indexed profileId,
    uint256 indexed pubId,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes referenceModuleData,
    address referenceModule,
    bytes referenceModuleReturnData,
    uint256 timestamp
  );

  /**
   * @dev Emitted when a followNFT clone is deployed using a lazy deployment pattern.
   *
   * @param profileId The token ID of the profile to which this followNFT is associated.
   * @param followNFT The address of the newly deployed followNFT clone.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTDeployed(uint256 indexed profileId, address indexed followNFT, uint256 timestamp);

  /**
   * @dev Emitted when a collectNFT clone is deployed using a lazy deployment pattern.
   *
   * @param profileId The publisher's profile token ID.
   * @param pubId The publication associated with the newly deployed collectNFT clone's ID.
   * @param collectNFT The address of the newly deployed collectNFT clone.
   * @param timestamp The current block timestamp.
   */
  event CollectNFTDeployed(
    uint256 indexed profileId,
    uint256 indexed pubId,
    address indexed collectNFT,
    uint256 timestamp
  );

  /**
   * @dev Emitted upon a successful collect action.
   *
   * @param collector The address collecting the publication.
   * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
   * @param pubId The publication ID that the collect was initiated towards, useful to differentiate mirrors.
   * @param rootProfileId The profile token ID of the profile whose publication is being collected.
   * @param rootPubId The publication ID of the publication being collected.
   * @param collectModuleData The data passed to the collect module.
   * @param timestamp The current block timestamp.
   */
  event Collected(
    address indexed collector,
    uint256 indexed profileId,
    uint256 indexed pubId,
    uint256 rootProfileId,
    uint256 rootPubId,
    bytes collectModuleData,
    uint256 timestamp
  );

  /**
   * @dev Emitted upon a successful follow action.
   *
   * @param follower The address following the given profiles.
   * @param profileIds The token ID array of the profiles being followed.
   * @param followModuleDatas The array of data parameters passed to each follow module.
   * @param timestamp The current block timestamp.
   */
  event Followed(address indexed follower, uint256[] profileIds, bytes[] followModuleDatas, uint256 timestamp);

  /**
   * @dev Emitted via callback when a followNFT is transferred.
   *
   * @param profileId The token ID of the profile associated with the followNFT being transferred.
   * @param followNFTId The followNFT being transferred's token ID.
   * @param from The address the followNFT is being transferred from.
   * @param to The address the followNFT is being transferred to.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTTransferred(
    uint256 indexed profileId,
    uint256 indexed followNFTId,
    address from,
    address to,
    uint256 timestamp
  );

  /**
   * @dev Emitted via callback when a collectNFT is transferred.
   *
   * @param profileId The token ID of the profile associated with the collectNFT being transferred.
   * @param pubId The publication ID associated with the collectNFT being transferred.
   * @param collectNFTId The collectNFT being transferred's token ID.
   * @param from The address the collectNFT is being transferred from.
   * @param to The address the collectNFT is being transferred to.
   * @param timestamp The current block timestamp.
   */
  event CollectNFTTransferred(
    uint256 indexed profileId,
    uint256 indexed pubId,
    uint256 indexed collectNFTId,
    address from,
    address to,
    uint256 timestamp
  );

  // Collect/Follow NFT-Specific

  /**
   * @dev Emitted when a newly deployed follow NFT is initialized.
   *
   * @param profileId The token ID of the profile connected to this follow NFT.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTInitialized(uint256 indexed profileId, uint256 timestamp);

  /**
   * @dev Emitted when delegation power in a FollowNFT is changed.
   *
   * @param delegate The delegate whose power has been changed.
   * @param newPower The new governance power mapped to the delegate.
   * @param timestamp The current block timestamp.
   */
  event FollowNFTDelegatedPowerChanged(address indexed delegate, uint256 indexed newPower, uint256 timestamp);

  /**
   * @dev Emitted when a newly deployed collect NFT is initialized.
   *
   * @param profileId The token ID of the profile connected to the publication mapped to this collect NFT.
   * @param pubId The publication ID connected to the publication mapped to this collect NFT.
   * @param timestamp The current block timestamp.
   */
  event CollectNFTInitialized(uint256 indexed profileId, uint256 indexed pubId, uint256 timestamp);

  // Module-Specific

  /**
   * @notice Emitted when the ModuleGlobals governance address is set.
   *
   * @param prevGovernance The previous governance address.
   * @param newGovernance The new governance address set.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsGovernanceSet(address indexed prevGovernance, address indexed newGovernance, uint256 timestamp);

  /**
   * @notice Emitted when the ModuleGlobals treasury address is set.
   *
   * @param prevTreasury The previous treasury address.
   * @param newTreasury The new treasury address set.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsTreasurySet(address indexed prevTreasury, address indexed newTreasury, uint256 timestamp);

  /**
   * @notice Emitted when the ModuleGlobals treasury fee is set.
   *
   * @param prevTreasuryFee The previous treasury fee in BPS.
   * @param newTreasuryFee The new treasury fee in BPS.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsTreasuryFeeSet(uint16 indexed prevTreasuryFee, uint16 indexed newTreasuryFee, uint256 timestamp);

  /**
   * @notice Emitted when a currency is added to or removed from the ModuleGlobals whitelist.
   *
   * @param currency The currency address.
   * @param prevWhitelisted Whether or not the currency was previously whitelisted.
   * @param whitelisted Whether or not the currency is whitelisted.
   * @param timestamp The current block timestamp.
   */
  event ModuleGlobalsCurrencyWhitelisted(
    address indexed currency,
    bool indexed prevWhitelisted,
    bool indexed whitelisted,
    uint256 timestamp
  );

  /**
   * @notice Emitted when a module inheriting from the `FeeModuleBase` is constructed.
   *
   * @param moduleGlobals The ModuleGlobals contract address used.
   * @param timestamp The current block timestamp.
   */
  event FeeModuleBaseConstructed(address indexed moduleGlobals, uint256 timestamp);

  /**
   * @notice Emitted when a module inheriting from the `ModuleBase` is constructed.
   *
   * @param hub The LensHub contract address used.
   * @param timestamp The current block timestamp.
   */
  event ModuleBaseConstructed(address indexed hub, uint256 timestamp);

  /**
   * @notice Emitted when one or multiple addresses are approved (or disapproved) for following in
   * the `ApprovalFollowModule`.
   *
   * @param owner The profile owner who executed the approval.
   * @param profileId The profile ID that the follow approvals are granted/revoked for.
   * @param addresses The addresses that have had the follow approvals grnated/revoked.
   * @param approved Whether each corresponding address is now approved or disapproved.
   * @param timestamp The current block timestamp.
   */
  event FollowsApproved(
    address indexed owner,
    uint256 indexed profileId,
    address[] addresses,
    bool[] approved,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the user wants to enable or disable follows in the `LensPeriphery`.
   *
   * @param owner The profile owner who executed the toggle.
   * @param profileIds The array of token IDs of the profiles each followNFT is associated with.
   * @param enabled The array of whether each FollowNFT's follow is enabled/disabled.
   * @param timestamp The current block timestamp.
   */
  event FollowsToggled(address indexed owner, uint256[] profileIds, bool[] enabled, uint256 timestamp);

  /**
   * @dev Emitted when the metadata associated with a profile is set in the `LensPeriphery`.
   *
   * @param profileId The profile ID the metadata is set for.
   * @param metadata The metadata set for the profile and user.
   * @param timestamp The current block timestamp.
   */
  event ProfileMetadataSet(uint256 indexed profileId, string metadata, uint256 timestamp);

  /**
   * @dev Emitted when the users balances percentages are set.
   *
   * @param caller The caller who set the protocol fund address.
   * @param creatorPercentage The new distribution percentage that corresponds to the creators.
   * @param protocolPercentage The new distribution percentage that corresponds to the protocol.
   * @param appPercentage The new distribution percentage that corresponds to the applications.
   * @param fansPercentage The new distribution percentage that corresponds to the fans.
   * @param timestamp The current block timestamp.
   */
  event PercentagesSet(
    address caller,
    uint256 creatorPercentage,
    uint256 protocolPercentage,
    uint256 appPercentage,
    uint256 fansPercentage,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the balance is added to a consumer balance.
   *
   * @param to The profile ID the balance is added for.
   * @param amount The amount added to the balance.
   * @param timestamp The current block timestamp.
   */
  event BalanceAdded(uint256 to, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the balance is moved from a consumer to a creator.
   *
   * @param from The profile ID of the consumer that the balance is moved from.
   * @param to The profile ID the balance is added for.
   * @param totalAmount The amount moved away from the consumer balance.
   * @param amountToCreator The amount added to creator balance.
   * @param amountToProtocol The amount added to protocol balance.
   * @param amountToApp The amount added to app balance.
   * @param amountToFans The amount added to fans balance.
   * @param timestamp The current block timestamp.
   */
  event BalanceMoved(
    uint256 from,
    uint256 to,
    uint256 totalAmount,
    uint256 amountToCreator,
    uint256 amountToProtocol,
    uint256 amountToApp,
    uint256 amountToFans,
    uint256 timestamp
  );

  /**
   * @dev Emitted when the consumer withdrew his balance.
   *
   * @param to The address of the consumer where the balance is withdrew.
   * @param profileId The profile ID of the consumer that withdrew the balance.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event ConsumerBalanceWithdrawn(address to, uint256 profileId, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the creator withdrew his balance.
   *
   * @param to The address of the creator where the balance is withdrew.
   * @param profileId The profile ID of the creator that withdrew the balance.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event CreatorBalanceWithdrawn(address to, uint256 profileId, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the protocol withdrew his balance.
   *
   * @param to The address of the protocol fund where the balance is withdrew.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event ProtocolBalanceWithdrawn(address to, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the app withdrew his balance.
   *
   * @param to The address of the app where the balance is withdrew.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event AppBalanceWithdrawn(address to, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when a fan withdrew from the fans balance.
   *
   * @param to The address of the fans where the balance is withdrew.
   * @param profileId The profile ID of the fan that withdrew the balance.
   * @param amount The amount that was withdrew from the balance.
   * @param timestamp The current block timestamp.
   */
  event FansBalanceWithdrawn(address to, uint256 profileId, uint256 amount, uint256 timestamp);

  /**
   * @dev Emitted when the consumer signer address was set.
   *
   * @param signer The address of the consumer signer controller.
   * @param timestamp The current block timestamp.
   */
  event ConsumersSignerSet(address signer, uint256 timestamp);

  /**
   * @dev Emitted when the fans signer address was set.
   *
   * @param signer The address of the fans signer controller.
   * @param timestamp The current block timestamp.
   */
  event FansSignerSet(address signer, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IModuleGlobals
 * @author Lens Protocol
 *
 * @notice This is the interface for the ModuleGlobals contract, a data providing contract to be queried by modules
 * for the most up-to-date parameters.
 */
interface IModuleGlobals {
  /**
   * @notice Sets the governance address. This function can only be called by governance.
   *
   * @param newGovernance The new governance address to set.
   */
  function setGovernance(address newGovernance) external;

  /**
   * @notice Sets the treasury address. This function can only be called by governance.
   *
   * @param newTreasury The new treasury address to set.
   */
  function setTreasury(address newTreasury) external;

  /**
   * @notice Sets the treasury fee. This function can only be called by governance.
   *
   * @param newTreasuryFee The new treasury fee to set.
   */
  function setTreasuryFee(uint16 newTreasuryFee) external;

  /**
   * @notice Adds or removes a currency from the whitelist. This function can only be called by governance.
   *
   * @param currency The currency to add or remove from the whitelist.
   * @param toWhitelist Whether to add or remove the currency from the whitelist.
   */
  function whitelistCurrency(address currency, bool toWhitelist) external;

  /// ************************
  /// *****VIEW FUNCTIONS*****
  /// ************************

  /**
   * @notice Returns whether a currency is whitelisted.
   *
   * @param currency The currency to query the whitelist for.
   *
   * @return bool True if the queried currency is whitelisted, false otherwise.
   */
  function isCurrencyWhitelisted(address currency) external view returns (bool);

  /**
   * @notice Returns the governance address.
   *
   * @return address The governance address.
   */
  function getGovernance() external view returns (address);

  /**
   * @notice Returns the treasury address.
   *
   * @return address The treasury address.
   */
  function getTreasury() external view returns (address);

  /**
   * @notice Returns the treasury fee.
   *
   * @return uint16 The treasury fee.
   */
  function getTreasuryFee() external view returns (uint16);

  /**
   * @notice Returns the treasury address and treasury fee in a single call.
   *
   * @return tuplee First, the treasury address, second, the treasury fee.
   */
  function getTreasuryData() external view returns (address, uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title DataTypes
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library DataTypes {
  /**
   * @notice An enum containing the different states the protocol can be in, limiting certain actions.
   *
   * @param Unpaused The fully unpaused state.
   * @param PublishingPaused The state where only publication creation functions are paused.
   * @param Paused The fully paused state.
   */
  enum ProtocolState {
    Unpaused,
    PublishingPaused,
    Paused
  }

  /**
   * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
   *
   * @param Post A standard post, having a URI, a collect module but no pointer to another publication.
   * @param Comment A comment, having a URI, a collect module and a pointer to another publication.
   * @param Mirror A mirror, having a pointer to another publication, but no URI or collect module.
   * @param Nonexistent An indicator showing the queried publication does not exist.
   */
  enum PubType {
    Post,
    Comment,
    Mirror,
    Nonexistent
  }

  /**
   * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
   *
   * @param v The signature's recovery parameter.
   * @param r The signature's r parameter.
   * @param s The signature's s parameter
   * @param deadline The signature's deadline
   */
  struct EIP712Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 deadline;
  }

  /**
   * @notice A struct containing profile data.
   *
   * @param pubCount The number of publications made to this profile.
   * @param followModule The address of the current follow module in use by this profile, can be empty.
   * @param followNFT The address of the followNFT associated with this profile, can be empty..
   * @param handle The profile's associated handle.
   * @param imageURI The URI to be used for the profile's image.
   * @param followNFTURI The URI to be used for the follow NFT.
   * @param videoURI The URI to be used for the profile's video.
   * @param metadataURI The URI to be used for the profile's metadata.
   * @param metadataHash The hash to be checked for the profile's metadata that is in the URI.
   */
  struct ProfileStruct {
    uint256 pubCount;
    address followModule;
    address followNFT;
    string handle;
    string imageURI;
    string followNFTURI;
    string videoURI;
    string metadataURI;
    string metadataHash;
  }

  /**
   * @notice A struct containing data associated with each new publication.
   *
   * @param profileIdPointed The profile token ID this publication points to, for mirrors and comments.
   * @param pubIdPointed The publication ID this publication points to, for mirrors and comments.
   * @param contentURI The URI associated with this publication.
   * @param referenceModule The address of the current reference module in use by this profile, can be empty.
   * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
   * @param collectNFT The address of the collectNFT associated with this publication, if any.
   * @param readModule The address of the read module associated with this publication, this exists for all publication.
   */
  struct PublicationStruct {
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    string contentURI;
    address referenceModule;
    address collectModule;
    address collectNFT;
    address readModule;
  }

  /**
   * @notice A struct containing the parameters required for the `createProfile()` function.
   *
   * @param to The address receiving the profile.
   * @param handle The handle to set for the profile, must be unique and non-empty.
   * @param imageURI The URI to set for the profile image.
   * @param followModule The follow module to use, can be the zero address.
   * @param followModuleInitData The follow module initialization data, if any.
   * @param followNFTURI The URI to use for the follow NFT.
   * @param videoURI The URI to set for the profile video.
   * @param metadataURI The URI to set for the profile metadata.
   * @param metadataHash The hash of the metadata that is in the URI.
   */
  struct CreateProfileData {
    address to;
    string handle;
    string imageURI;
    address followModule;
    bytes followModuleInitData;
    string followNFTURI;
    string videoURI;
    string metadataURI;
    string metadataHash;
  }

  /**
   * @notice A struct containing profile data.
   *
   * @param followModule The address of the current follow module in use by this profile, can be empty.
   * @param followNFT The address of the followNFT associated with this profile, can be empty..
   * @param handle The profile's associated handle.
   * @param imageURI The URI to be used for the profile's image.
   * @param followNFTURI The URI to be used for the follow NFT.
   * @param videoURI The URI to be used for the profile's video.
   * @param metadataURI The URI to be used for the profile's metadata.
   */
  struct CreateProfileEvent {
    address to;
    string handle;
    string imageURI;
    address followModule;
    bytes followModuleReturnData;
    string followNFTURI;
    string videoURI;
    string metadataURI;
  }

  /**
   * @notice A struct containing the parameters required for the `post()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param contentURI The URI to set for this new publication.
   * @param collectModule The collect module to set for this new publication.
   * @param collectModuleInitData The data to pass to the collect module's initialization.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   * @param readModule The read module to set for the given publication, must be whitelisted.
   * @param readModuleInitData The data to be passed to the read module for initialization.
   */
  struct PostData {
    uint256 profileId;
    string contentURI;
    address collectModule;
    bytes collectModuleInitData;
    address referenceModule;
    bytes referenceModuleInitData;
    address readModule;
    bytes readModuleInitData;
  }

  /**
   * @notice A struct containing the parameters required for the `_initPubReferenceModule()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param pubId The publication ID that is being created.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct ReferencePostData {
    uint256 profileId;
    uint256 pubId;
    address referenceModule;
    bytes referenceModuleInitData;
  }

  /**
   * @notice A struct containing the parameters required for the `_initPubReadModule()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param pubId The publication ID that is being created.
   * @param readModule The read module to set for the given publication, must be whitelisted.
   * @param readModuleInitData The data to be passed to the read module for initialization.
   */
  struct ReadPostData {
    uint256 profileId;
    uint256 pubId;
    address readModule;
    bytes readModuleInitData;
  }

  /**
   * @notice A struct containing the parameters of the modules associated with the Post.
   *
   * @param collectModule The collect module to set for this new publication.
   * @param collectModuleReturnData The data returned after collect module initialization.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleReturnData The data returned after reference module initialization.
   * @param readModule The read module to set for the given publication, must be whitelisted.
   * @param readModuleReturnData The data returned after read module initialization.
   */
  struct PostModulesData {
    address collectModule;
    bytes collectModuleReturnData;
    address referenceModule;
    bytes referenceModuleReturnData;
    address readModule;
    bytes readModuleReturnData;
  }

  /**
   * @notice A struct containing the parameters required for the `comment()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param contentURI The URI to set for this new publication.
   * @param profileIdPointed The profile token ID to point the comment to.
   * @param pubIdPointed The publication ID to point the comment to.
   * @param referenceModuleData The data passed to the reference module.
   * @param collectModule The collect module to set for this new publication.
   * @param collectModuleInitData The data to pass to the collect module's initialization.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct CommentData {
    uint256 profileId;
    string contentURI;
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    bytes referenceModuleData;
    address collectModule;
    bytes collectModuleInitData;
    address referenceModule;
    bytes referenceModuleInitData;
  }

  /**
   * @notice A struct containing the parameters required for the `mirror()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param profileIdPointed The profile token ID to point the mirror to.
   * @param pubIdPointed The publication ID to point the mirror to.
   * @param referenceModuleData The data passed to the reference module.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct MirrorData {
    uint256 profileId;
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    bytes referenceModuleData;
    address referenceModule;
    bytes referenceModuleInitData;
  }

  /**
   * @notice A struct containing the percentages parameters required for the move balances function.
   *
   * @param creatorPercentage The percentage that is given to the content creator.
   * @param protocolPercentage The percentage that is given to the protocol.
   * @param appPercentage The percentage that is given to the app.
   * @param fansPercentage The percentage that is given to the fans.
   */
  struct PercentagesData {
    uint256 creatorPercentage;
    uint256 protocolPercentage;
    uint256 appPercentage;
    uint256 fansPercentage;
  }
}