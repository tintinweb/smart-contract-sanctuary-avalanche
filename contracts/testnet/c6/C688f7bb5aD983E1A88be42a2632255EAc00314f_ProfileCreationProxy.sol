// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ILensHub} from "../interfaces/ILensHub.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ProfileCreationProxy
 * @author Lens Protocol
 *
 * @notice This is an ownable proxy contract that enforces ".lens" handle suffixes at profile creation.
 * Only the owner can create profiles.
 */
contract ProfileCreationProxy is Ownable {
  ILensHub immutable LENS_HUB;

  constructor(address owner, ILensHub hub) {
    _transferOwnership(owner);
    LENS_HUB = hub;
  }

  function proxyCreateProfile(DataTypes.CreateProfileData memory vars) external onlyOwner {
    uint256 handleLength = bytes(vars.handle).length;
    if (handleLength < 5) revert Errors.HandleLengthInvalid();

    bytes1 firstByte = bytes(vars.handle)[0];
    if (firstByte == "-" || firstByte == "_" || firstByte == ".") revert Errors.HandleFirstCharInvalid();

    for (uint256 i = 1; i < handleLength; ) {
      if (bytes(vars.handle)[i] == ".") revert Errors.HandleContainsInvalidCharacters();
      unchecked {
        ++i;
      }
    }

    vars.handle = string(abi.encodePacked(vars.handle, ".lens"));
    LENS_HUB.createProfile(vars);
  }
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
   * @notice Publishes a reaction to a given profile, must be called by the profile owner.
   *
   * @param vars A ReactionData struct containing the necessary parameters.
   *
   * @return uint256 An integer representing the reaction's publication ID.
   */
  function react(DataTypes.ReactionData calldata vars) external returns (uint256);

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
   * @param Reaction A reaction, having a pointer to another publication, with URI but no collect module.
   * @param Nonexistent An indicator showing the queried publication does not exist.
   */
  enum PubType {
    Post,
    Comment,
    Mirror,
    Reaction,
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
   * @param readModule The read module to set for the given publication, must be whitelisted.
   * @param readModuleInitData The data to be passed to the read module for initialization.
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
    address readModule;
    bytes readModuleInitData;
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

  /**
   * @notice A struct containing the parameters required for the `reaction()` function.
   *
   * @param profileId The token ID of the profile to publish to.
   * @param contentURI The URI to set for this new publication.
   * @param profileIdPointed The profile token ID to point the comment to.
   * @param pubIdPointed The publication ID to point the comment to.
   * @param referenceModuleData The data passed to the reference module.
   * @param referenceModule The reference module to set for the given publication, must be whitelisted.
   * @param referenceModuleInitData The data to be passed to the reference module for initialization.
   */
  struct ReactionData {
    uint256 profileId;
    string contentURI;
    uint256 profileIdPointed;
    uint256 pubIdPointed;
    bytes referenceModuleData;
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
  error CannotReactOnSelf();
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