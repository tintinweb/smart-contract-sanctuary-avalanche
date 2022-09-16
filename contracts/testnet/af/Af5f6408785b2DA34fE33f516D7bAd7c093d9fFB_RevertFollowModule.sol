// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Errors} from "../../../libraries/Errors.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {FollowValidatorFollowModuleBase} from "./FollowValidatorFollowModuleBase.sol";

/**
 * @title RevertFollowModule
 * @author Lens Protocol
 *
 * @notice This follow module rejects all follow attempts.
 */
contract RevertFollowModule is FollowValidatorFollowModuleBase {
  constructor(address hub) ModuleBase(hub) {}

  /**
   * @notice This follow module works on custom profile owner approvals.
   *
   * @param profileId The profile ID of the profile to initialize this module for.
   * @param data The arbitrary data parameter, which in this particular module initialization will be just ignored.
   *
   * @return bytes Empty bytes.
   */
  function initializeFollowModule(uint256 profileId, bytes calldata data)
    external
    view
    override
    onlyHub
    returns (bytes memory)
  {
    return new bytes(0);
  }

  /**
   * @dev Processes a follow by rejecting it reverting the transaction.
   */
  function processFollow(
    address follower,
    uint256 profileId,
    bytes calldata data
  ) external view override onlyHub {
    revert Errors.FollowInvalid();
  }

  /**
   * @dev We don't need to execute any additional logic on transfers in this follow module.
   */
  function followModuleTransferHook(
    uint256 profileId,
    address from,
    address to,
    uint256 followNFTTokenId
  ) external override {}
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

import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

/**
 * @title ModuleBase
 * @author Lens Protocol
 *
 * @notice This abstract contract adds a public `HUB` immutable to inheriting modules, as well as an
 * `onlyHub` modifier.
 */
abstract contract ModuleBase {
  address public immutable HUB;

  modifier onlyHub() {
    if (msg.sender != HUB) revert Errors.NotHub();
    _;
  }

  constructor(address hub) {
    if (hub == address(0)) revert Errors.InitParamsInvalid();
    HUB = hub;
    emit Events.ModuleBaseConstructed(hub, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IFollowModule} from "../../../interfaces/IFollowModule.sol";
import {ILensHub} from "../../../interfaces/ILensHub.sol";
import {Errors} from "../../../libraries/Errors.sol";
import {ModuleBase} from "../ModuleBase.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title FollowValidatorFollowModuleBase
 * @author Lens Protocol
 *
 * @notice This abstract contract adds the default expected behavior for follow validation in a follow module
 * to inheriting contracts.
 */
abstract contract FollowValidatorFollowModuleBase is ModuleBase, IFollowModule {
  /**
   * @notice Standard function to validate follow NFT ownership. This module is agnostic to follow NFT token IDs
   * and other properties.
   */
  function isFollowing(
    uint256 profileId,
    address follower,
    uint256 followNFTTokenId
  ) external view override returns (bool) {
    address followNFT = ILensHub(HUB).getFollowNFT(profileId);
    if (followNFT == address(0)) {
      return false;
    } else {
      return
        followNFTTokenId == 0
          ? IERC721(followNFT).balanceOf(follower) != 0
          : IERC721(followNFT).ownerOf(followNFTTokenId) == follower;
    }
  }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IFollowModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible FollowModules.
 */
interface IFollowModule {
  /**
   * @notice Initializes a follow module for a given Lens profile. This can only be called by the hub contract.
   *
   * @param profileId The token ID of the profile to initialize this follow module for.
   * @param data Arbitrary data passed by the profile creator.
   *
   * @return bytes The encoded data to emit in the hub.
   */
  function initializeFollowModule(uint256 profileId, bytes calldata data) external returns (bytes memory);

  /**
   * @notice Processes a given follow, this can only be called from the LensHub contract.
   *
   * @param follower The follower address.
   * @param profileId The token ID of the profile being followed.
   * @param data Arbitrary data passed by the follower.
   */
  function processFollow(
    address follower,
    uint256 profileId,
    bytes calldata data
  ) external;

  /**
   * @notice This is a transfer hook that is called upon follow NFT transfer in `beforeTokenTransfer. This can
   * only be called from the LensHub contract.
   *
   * NOTE: Special care needs to be taken here: It is possible that follow NFTs were issued before this module
   * was initialized if the profile's follow module was previously different. This transfer hook should take this
   * into consideration, especially when the module holds state associated with individual follow NFTs.
   *
   * @param profileId The token ID of the profile associated with the follow NFT being transferred.
   * @param from The address sending the follow NFT.
   * @param to The address receiving the follow NFT.
   * @param followNFTTokenId The token ID of the follow NFT being transferred.
   */
  function followModuleTransferHook(
    uint256 profileId,
    address from,
    address to,
    uint256 followNFTTokenId
  ) external;

  /**
   * @notice This is a helper function that could be used in conjunction with specific collect modules.
   *
   * NOTE: This function IS meant to replace a check on follower NFT ownership.
   *
   * NOTE: It is assumed that not all collect modules are aware of the token ID to pass. In these cases,
   * this should receive a `followNFTTokenId` of 0, which is impossible regardless.
   *
   * One example of a use case for this would be a subscription-based following system:
   *      1. The collect module:
   *          - Decodes a follower NFT token ID from user-passed data.
   *          - Fetches the follow module from the hub.
   *          - Calls `isFollowing` passing the profile ID, follower & follower token ID and checks it returned true.
   *      2. The follow module:
   *          - Validates the subscription status for that given NFT, reverting on an invalid subscription.
   *
   * @param profileId The token ID of the profile to validate the follow for.
   * @param follower The follower address to validate the follow for.
   * @param followNFTTokenId The followNFT token ID to validate the follow for.
   *
   * @return true if the given address is following the given profile ID, false otherwise.
   */
  function isFollowing(
    uint256 profileId,
    address follower,
    uint256 followNFTTokenId
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHub {
  /**
   * @notice Initializes the LensHub NFT, setting the initial governance address as well as the name and symbol in
   * the LensNFTBase contract.
   *
   * @param name The name to set for the hub NFT.
   * @param symbol The symbol to set for the hub NFT.
   * @param newGovernance The governance address to set.
   */
  function initialize(
    string calldata name,
    string calldata symbol,
    address newGovernance
  ) external;

  /**
   * @notice Sets the privileged governance role. This function can only be called by the current governance
   * address.
   *
   * @param newGovernance The new governance address to set.
   */
  function setGovernance(address newGovernance) external;

  /**
   * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
   * can only be called by the governance address.
   *
   * @param newEmergencyAdmin The new emergency admin address to set.
   */
  function setEmergencyAdmin(address newEmergencyAdmin) external;

  /**
   * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
   * can only be called by the governance address or the emergency admin address.
   *
   * Note that this reverts if the emergency admin calls it if:
   *      1. The emergency admin is attempting to unpause.
   *      2. The emergency admin is calling while the protocol is already paused.
   *
   * @param newState The state to set, as a member of the ProtocolState enum.
   */
  function setState(DataTypes.ProtocolState newState) external;

  /**
   * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param profileCreator The profile creator address to add or remove from the whitelist.
   * @param whitelist Whether or not the profile creator should be whitelisted.
   */
  function whitelistProfileCreator(address profileCreator, bool whitelist) external;

  /**
   * @notice Adds or removes a follow module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param followModule The follow module contract address to add or remove from the whitelist.
   * @param whitelist Whether or not the follow module should be whitelisted.
   */
  function whitelistFollowModule(address followModule, bool whitelist) external;

  /**
   * @notice Adds or removes a reference module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param referenceModule The reference module contract to add or remove from the whitelist.
   * @param whitelist Whether or not the reference module should be whitelisted.
   */
  function whitelistReferenceModule(address referenceModule, bool whitelist) external;

  /**
   * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param collectModule The collect module contract address to add or remove from the whitelist.
   * @param whitelist Whether or not the collect module should be whitelisted.
   */
  function whitelistCollectModule(address collectModule, bool whitelist) external;

  /**
   * @notice Adds or removes a collect module from the whitelist. This function can only be called by the current
   * governance address.
   *
   * @param readModule The collect module contract address to add or remove from the whitelist.
   * @param whitelist Whether or not the collect module should be whitelisted.
   */
  function whitelistReadModule(address readModule, bool whitelist) external;

  /**
   * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient. This
   * function must be called by a whitelisted profile creator.
   *
   * @param vars A CreateProfileData struct containing the following params:
   *      to: The address receiving the profile.
   *      handle: The handle to set for the profile, must be unique and non-empty.
   *      imageURI: The URI to set for the profile image.
   *      followModule: The follow module to use, can be the zero address.
   *      followModuleInitData: The follow module initialization data, if any.
   *      videoURI The URI to set for the profile video.
   *      metadataURI The URI to set for the profile metadata.
   */
  function createProfile(DataTypes.CreateProfileData calldata vars) external returns (uint256);

  /**
   * @notice Sets the mapping between wallet and its main profile identity.
   *
   * @param profileId The token ID of the profile to set as the main profile identity.
   */
  function setDefaultProfile(uint256 profileId) external;

  /**
   * @notice Sets a profile's follow module, must be called by the profile owner.
   *
   * @param profileId The token ID of the profile to set the follow module for.
   * @param followModule The follow module to set for the given profile, must be whitelisted.
   * @param followModuleInitData The data to be passed to the follow module for initialization.
   */
  function setFollowModule(
    uint256 profileId,
    address followModule,
    bytes calldata followModuleInitData
  ) external;

  /**
   * @notice Sets a profile's dispatcher, giving that dispatcher rights to publish to that profile.
   *
   * @param profileId The token ID of the profile of the profile to set the dispatcher for.
   * @param dispatcher The dispatcher address to set for the given profile ID.
   */
  function setDispatcher(uint256 profileId, address dispatcher) external;

  /**
   * @notice Sets a profile's URI, which is reflected in the `tokenURI()` function.
   *
   * @param profileId The token ID of the profile of the profile to set the URI for.
   * @param imageURI The URI to set for the given profile.
   */
  function setProfileImageURI(uint256 profileId, string calldata imageURI) external;

  /**
   * @notice Sets a followNFT URI for a given profile's follow NFT.
   *
   * @param profileId The token ID of the profile for which to set the followNFT URI.
   * @param followNFTURI The follow NFT URI to set.
   */
  function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external;

  /**
   * @notice Sets a profile's URI, which is reflected in the `tokenURI()` function.
   *
   * @param profileId The token ID of the profile of the profile to set the URI for.
   * @param videoURI The URI to set for the given profile.
   */
  function setProfileVideoURI(uint256 profileId, string calldata videoURI) external;

  /**
   * @notice Sets a profile's URI, which is reflected in the `tokenURI()` function.
   *
   * @param profileId The token ID of the profile of the profile to set the URI for.
   * @param metadataURI The URI to set for the given profile.
   */
  function setProfileMetadataURI(uint256 profileId, string calldata metadataURI) external;

  /**
   * @notice Publishes a post to a given profile, must be called by the profile owner.
   *
   * @param vars A PostData struct containing the needed parameters.
   *
   * @return uint256 An integer representing the post's publication ID.
   */
  function post(DataTypes.PostData calldata vars) external returns (uint256);

  /**
   * @notice Publishes a comment to a given profile, must be called by the profile owner.
   *
   * @param vars A CommentData struct containing the needed parameters.
   *
   * @return uint256 An integer representing the comment's publication ID.
   */
  function comment(DataTypes.CommentData calldata vars) external returns (uint256);

  /**
   * @notice Publishes a mirror to a given profile, must be called by the profile owner.
   *
   * @param vars A MirrorData struct containing the necessary parameters.
   *
   * @return uint256 An integer representing the mirror's publication ID.
   */
  function mirror(DataTypes.MirrorData calldata vars) external returns (uint256);

  /**
   * @notice Follows the given profiles, executing each profile's follow module logic (if any) and minting followNFTs to the caller.
   *
   * NOTE: Both the `profileIds` and `datas` arrays must be of the same length, regardless if the profiles do not have a follow module set.
   *
   * @param profileIds The token ID array of the profiles to follow.
   * @param datas The arbitrary data array to pass to the follow module for each profile if needed.
   *
   * @return uint256[] An array of integers representing the minted follow NFTs token IDs.
   */
  function follow(uint256[] calldata profileIds, bytes[] calldata datas) external returns (uint256[] memory);

  /**
   * @notice Collects a given publication, executing collect module logic and minting a collectNFT to the caller.
   *
   * @param profileId The token ID of the profile that published the publication to collect.
   * @param pubId The publication to collect's publication ID.
   * @param data The arbitrary data to pass to the collect module if needed.
   *
   * @return uint256 An integer representing the minted token ID.
   */
  function collect(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (uint256);

  /**
   * @dev Helper function to emit a detailed followNFT transfer event from the hub, to be consumed by frontends to track
   * followNFT transfers.
   *
   * @param profileId The token ID of the profile associated with the followNFT being transferred.
   * @param followNFTId The followNFT being transferred's token ID.
   * @param from The address the followNFT is being transferred from.
   * @param to The address the followNFT is being transferred to.
   */
  function emitFollowNFTTransferEvent(
    uint256 profileId,
    uint256 followNFTId,
    address from,
    address to
  ) external;

  /**
   * @dev Helper function to emit a detailed collectNFT transfer event from the hub, to be consumed by frontends to track
   * collectNFT transfers.
   *
   * @param profileId The token ID of the profile associated with the collect NFT being transferred.
   * @param pubId The publication ID associated with the collect NFT being transferred.
   * @param collectNFTId The collectNFT being transferred's token ID.
   * @param from The address the collectNFT is being transferred from.
   * @param to The address the collectNFT is being transferred to.
   */
  function emitCollectNFTTransferEvent(
    uint256 profileId,
    uint256 pubId,
    uint256 collectNFTId,
    address from,
    address to
  ) external;

  /// ************************
  /// *****VIEW FUNCTIONS*****
  /// ************************

  /**
   * @notice Returns whether or not a profile creator is whitelisted.
   *
   * @param profileCreator The address of the profile creator to check.
   *
   * @return bool True if the profile creator is whitelisted, false otherwise.
   */
  function isProfileCreatorWhitelisted(address profileCreator) external view returns (bool);

  /**
   * @notice Returns default profile for a given wallet address
   *
   * @param wallet The address to find the default mapping
   *
   * @return uint256 The default profile id, which will be 0 if not mapped.
   */
  function defaultProfile(address wallet) external view returns (uint256);

  /**
   * @notice Returns whether or not a follow module is whitelisted.
   *
   * @param followModule The address of the follow module to check.
   *
   * @return bool True if the the follow module is whitelisted, false otherwise.
   */
  function isFollowModuleWhitelisted(address followModule) external view returns (bool);

  /**
   * @notice Returns whether or not a reference module is whitelisted.
   *
   * @param referenceModule The address of the reference module to check.
   *
   * @return bool True if the the reference module is whitelisted, false otherwise.
   */
  function isReferenceModuleWhitelisted(address referenceModule) external view returns (bool);

  /**
   * @notice Returns whether or not a collect module is whitelisted.
   *
   * @param collectModule The address of the collect module to check.
   *
   * @return bool True if the the collect module is whitelisted, false otherwise.
   */
  function isCollectModuleWhitelisted(address collectModule) external view returns (bool);

  /**
   * @notice Returns whether or not a read module is whitelisted.
   *
   * @param readModule The address of the read module to check.
   *
   * @return bool True if the the read module is whitelisted, false otherwise.
   */
  function isReadModuleWhitelisted(address readModule) external view returns (bool);

  /**
   * @notice Returns the currently configured governance address.
   *
   * @return address The address of the currently configured governance.
   */
  function getGovernance() external view returns (address);

  /**
   * @notice Returns the dispatcher associated with a profile.
   *
   * @param profileId The token ID of the profile to query the dispatcher for.
   *
   * @return address The dispatcher address associated with the profile.
   */
  function getDispatcher(uint256 profileId) external view returns (address);

  /**
   * @notice Returns the publication count for a given profile.
   *
   * @param profileId The token ID of the profile to query.
   *
   * @return uint256 The number of publications associated with the queried profile.
   */
  function getPubCount(uint256 profileId) external view returns (uint256);

  /**
   * @notice Returns the followNFT associated with a given profile, if any.
   *
   * @param profileId The token ID of the profile to query the followNFT for.
   *
   * @return address The followNFT associated with the given profile.
   */
  function getFollowNFT(uint256 profileId) external view returns (address);

  /**
   * @notice Returns the followNFT URI associated with a given profile.
   *
   * @param profileId The token ID of the profile to query the followNFT URI for.
   *
   * @return string The followNFT URI associated with the given profile.
   */
  function getFollowNFTURI(uint256 profileId) external view returns (string memory);

  /**
   * @notice Returns the collectNFT associated with a given publication, if any.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return address The address of the collectNFT associated with the queried publication.
   */
  function getCollectNFT(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the follow module associated witha  given profile, if any.
   *
   * @param profileId The token ID of the profile to query the follow module for.
   *
   * @return address The address of the follow module associated with the given profile.
   */
  function getFollowModule(uint256 profileId) external view returns (address);

  /**
   * @notice Returns the collect module associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return address The address of the collect module associated with the queried publication.
   */
  function getCollectModule(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the reference module associated witha  given profile, if any.
   *
   * @param profileId The token ID of the profile that published the publication to querythe reference module for.
   * @param pubId The publication ID of the publication to query the reference module for.
   *
   * @return address The address of the reference module associated with the given profile.
   */
  function getReferenceModule(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the read module associated witha  given profile, if any.
   *
   * @param profileId The token ID of the profile that published the publication to querythe read module for.
   * @param pubId The publication ID of the publication to query the read module for.
   *
   * @return address The address of the read module associated with the given profile.
   */
  function getReadModule(uint256 profileId, uint256 pubId) external view returns (address);

  /**
   * @notice Returns the handle associated with a profile.
   *
   * @param profileId The token ID of the profile to query the handle for.
   *
   * @return string The handle associated with the profile.
   */
  function getHandle(uint256 profileId) external view returns (string memory);

  /**
   * @notice Returns the publication pointer (profileId & pubId) associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query the pointer for.
   * @param pubId The publication ID of the publication to query the pointer for.
   *
   * @return tuple First, the profile ID of the profile the current publication is pointing to, second, the
   * publication ID of the publication the current publication is pointing to.
   */
  function getPubPointer(uint256 profileId, uint256 pubId) external view returns (uint256, uint256);

  /**
   * @notice Returns the URI associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return string The URI associated with a given publication.
   */
  function getContentURI(uint256 profileId, uint256 pubId) external view returns (string memory);

  /**
   * @notice Returns the profile token ID according to a given handle.
   *
   * @param handle The handle to resolve the profile token ID with.
   *
   * @return uint256 The profile ID the passed handle points to.
   */
  function getProfileIdByHandle(string calldata handle) external view returns (uint256);

  /**
   * @notice Returns the full profile struct associated with a given profile token ID.
   *
   * @param profileId The token ID of the profile to query.
   *
   * @return ProfileStruct The profile struct of the given profile.
   */
  function getProfile(uint256 profileId) external view returns (DataTypes.ProfileStruct memory);

  /**
   * @notice Returns the full publication struct for a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return PublicationStruct The publication struct associated with the queried publication.
   */
  function getPub(uint256 profileId, uint256 pubId) external view returns (DataTypes.PublicationStruct memory);

  /**
   * @notice Returns the publication type associated with a given publication.
   *
   * @param profileId The token ID of the profile that published the publication to query.
   * @param pubId The publication ID of the publication to query.
   *
   * @return PubType The publication type, as a member of an enum (either "post," "comment" or "mirror").
   */
  function getPubType(uint256 profileId, uint256 pubId) external view returns (DataTypes.PubType);

  /**
   * @notice Returns the follow NFT implementation address.
   *
   * @return address The follow NFT implementation address.
   */
  function getFollowNFTImpl() external view returns (address);

  /**
   * @notice Returns the collect NFT implementation address.
   *
   * @return address The collect NFT implementation address.
   */
  function getCollectNFTImpl() external view returns (address);

  /**
   * @notice Adds a new trusted forwarder to use as relayer service.
   *
   * @param newTrustedForwarder The address of the new trusted forwarder.
   */
  function addTrustedForwarder(address newTrustedForwarder) external;

  /**
   * @notice Removes a forwarder form the trusted list, and therefore cannot be to use as relayer service.
   *
   * @param forwarder The address of the forwarder to remove.
   */
  function removeTrustedForwarder(address forwarder) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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