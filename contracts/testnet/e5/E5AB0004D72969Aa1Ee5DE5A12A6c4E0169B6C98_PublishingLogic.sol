// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Helpers} from "./Helpers.sol";
import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";
import {Events} from "./Events.sol";
import {Constants} from "./Constants.sol";
import {IFollowModule} from "../interfaces/IFollowModule.sol";
import {ICollectModule} from "../interfaces/ICollectModule.sol";
import {IReferenceModule} from "../interfaces/IReferenceModule.sol";
import {IReadModule} from "../interfaces/IReadModule.sol";

/**
 * @title PublishingLogic
 * @author Lens Protocol
 *
 * @notice This is the library that contains the logic for profile creation & publication.
 *
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood. Furthermore,
 * expected events are emitted from this library instead of from the hub to alleviate code size concerns.
 */
library PublishingLogic {
  /**
   * @notice Executes the logic to create a profile with the given parameters to the given address.
   *
   * @param vars The CreateProfileData struct containing the following parameters:
   *      to: The address receiving the profile.
   *      handle: The handle to set for the profile, must be unique and non-empty.
   *      imageURI: The URI to set for the profile image.
   *      followModule: The follow module to use, can be the zero address.
   *      followModuleInitData: The follow module initialization data, if any
   *      followNFTURI: The URI to set for the follow NFT.
   *      videoURI The URI to set for the profile video.
   *      metadataURI The URI to set for the profile metadata.
   *      metadataHash The hash of the metadata that is in the URI.
   * @param profileId The profile ID to associate with this profile NFT (token ID).
   * @param _profileIdByHandleHash The storage reference to the mapping of profile IDs by handle hash.
   * @param _profileById The storage reference to the mapping of profile structs by IDs.
   * @param _followModuleWhitelisted The storage reference to the mapping of whitelist status by follow module address.
   */
  function createProfile(
    DataTypes.CreateProfileData calldata vars,
    uint256 profileId,
    mapping(bytes32 => uint256) storage _profileIdByHandleHash,
    mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
    mapping(address => bool) storage _followModuleWhitelisted
  ) external {
    _validateHandle(vars.handle);

    if (bytes(vars.imageURI).length > Constants.MAX_PROFILE_IMAGE_URI_LENGTH)
      revert Errors.ProfileImageURILengthInvalid();

    bytes32 handleHash = keccak256(bytes(vars.handle));

    if (_profileIdByHandleHash[handleHash] != 0) revert Errors.HandleTaken();

    _profileIdByHandleHash[handleHash] = profileId;
    _profileById[profileId].handle = vars.handle;
    _profileById[profileId].imageURI = vars.imageURI;
    _profileById[profileId].followNFTURI = vars.followNFTURI;
    _profileById[profileId].videoURI = vars.videoURI;
    _profileById[profileId].metadataURI = vars.metadataURI;
    _profileById[profileId].metadataHash = vars.metadataHash;

    bytes memory followModuleReturnData;
    if (vars.followModule != address(0)) {
      _profileById[profileId].followModule = vars.followModule;
      followModuleReturnData = _initFollowModule(
        profileId,
        vars.followModule,
        vars.followModuleInitData,
        _followModuleWhitelisted
      );
    }

    _emitProfileCreated(profileId, vars, followModuleReturnData);
  }

  /**
   * @notice Sets the follow module for a given profile.
   *
   * @param profileId The profile ID to set the follow module for.
   * @param followModule The follow module to set for the given profile, if any.
   * @param followModuleInitData The data to pass to the follow module for profile initialization.
   * @param _profile The storage reference to the profile struct associated with the given profile ID.
   * @param _followModuleWhitelisted The storage reference to the mapping of whitelist status by follow module address.
   */
  function setFollowModule(
    uint256 profileId,
    address followModule,
    bytes calldata followModuleInitData,
    DataTypes.ProfileStruct storage _profile,
    mapping(address => bool) storage _followModuleWhitelisted
  ) external {
    if (followModule != _profile.followModule) {
      _profile.followModule = followModule;
    }

    bytes memory followModuleReturnData;
    if (followModule != address(0))
      followModuleReturnData = _initFollowModule(
        profileId,
        followModule,
        followModuleInitData,
        _followModuleWhitelisted
      );
    emit Events.FollowModuleSet(profileId, followModule, followModuleReturnData, block.timestamp);
  }

  /**
   * @notice Creates a post publication mapped to the given profile.
   *
   * @dev To avoid a stack too deep error, reference parameters are passed in memory rather than calldata.
   *
   * @param vars A PostData struct containing the needed parameters.
   * @param pubId The publication ID to associate with this publication.
   * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
   * @param _collectModuleWhitelisted The storage reference to the mapping of whitelist status by collect module address.
   * @param _referenceModuleWhitelisted The storage reference to the mapping of whitelist status by reference module address.
   * @param _readModuleWhitelisted The storage reference to the mapping of whitelist status by read module address.
   */
  function createPost(
    DataTypes.PostData calldata vars,
    uint256 pubId,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _collectModuleWhitelisted,
    mapping(address => bool) storage _referenceModuleWhitelisted,
    mapping(address => bool) storage _readModuleWhitelisted
  ) external {
    _pubByIdByProfile[vars.profileId][pubId].contentURI = vars.contentURI;

    // Collect module initialization
    bytes memory collectModuleReturnData = _initPubCollectModule(
      vars.profileId,
      pubId,
      vars.collectModule,
      vars.collectModuleInitData,
      _pubByIdByProfile,
      _collectModuleWhitelisted
    );

    // Reference module initialization
    bytes memory referenceModuleReturnData = _initPubReferenceModule(
      vars.profileId,
      pubId,
      vars.referenceModule,
      vars.referenceModuleInitData,
      _pubByIdByProfile,
      _referenceModuleWhitelisted
    );

    DataTypes.ReadPostData memory readPostData = DataTypes.ReadPostData({
      profileId: vars.profileId,
      pubId: pubId,
      readModule: vars.readModule,
      readModuleInitData: vars.readModuleInitData
    });
    bytes memory readModuleReturnData = _initPubReadModule(readPostData, _pubByIdByProfile, _readModuleWhitelisted);

    DataTypes.PostModulesData memory postModulesData = DataTypes.PostModulesData({
      collectModule: vars.collectModule,
      collectModuleReturnData: collectModuleReturnData,
      referenceModule: vars.referenceModule,
      referenceModuleReturnData: referenceModuleReturnData,
      readModule: vars.readModule,
      readModuleReturnData: readModuleReturnData
    });

    emit Events.PostCreated(vars.profileId, pubId, vars.contentURI, postModulesData, block.timestamp);
  }

  /**
   * @notice Creates a comment publication mapped to the given profile.
   *
   * @dev This function is unique in that it requires many variables, so, unlike the other publishing functions,
   * we need to pass the full CommentData struct in memory to avoid a stack too deep error.
   *
   * @param vars The CommentData struct to use to create the comment.
   * @param pubId The publication ID to associate with this publication.
   * @param _profileById The storage reference to the mapping of profile structs by IDs.
   * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
   * @param _collectModuleWhitelisted The storage reference to the mapping of whitelist status by collect module address.
   * @param _referenceModuleWhitelisted The storage reference to the mapping of whitelist status by reference module address.
   */
  function createComment(
    DataTypes.CommentData memory vars,
    uint256 pubId,
    mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _collectModuleWhitelisted,
    mapping(address => bool) storage _referenceModuleWhitelisted
  ) external {
    // Validate existence of the pointed publication
    uint256 pubCount = _profileById[vars.profileIdPointed].pubCount;
    if (pubCount < vars.pubIdPointed || vars.pubIdPointed == 0) revert Errors.PublicationDoesNotExist();

    // Ensure the pointed publication is not the comment being created
    if (vars.profileId == vars.profileIdPointed && vars.pubIdPointed == pubId) revert Errors.CannotCommentOnSelf();

    _pubByIdByProfile[vars.profileId][pubId].contentURI = vars.contentURI;
    _pubByIdByProfile[vars.profileId][pubId].profileIdPointed = vars.profileIdPointed;
    _pubByIdByProfile[vars.profileId][pubId].pubIdPointed = vars.pubIdPointed;

    // Collect Module Initialization
    bytes memory collectModuleReturnData = _initPubCollectModule(
      vars.profileId,
      pubId,
      vars.collectModule,
      vars.collectModuleInitData,
      _pubByIdByProfile,
      _collectModuleWhitelisted
    );

    // Reference module initialization
    bytes memory referenceModuleReturnData = _initPubReferenceModule(
      vars.profileId,
      pubId,
      vars.referenceModule,
      vars.referenceModuleInitData,
      _pubByIdByProfile,
      _referenceModuleWhitelisted
    );

    // Reference module validation
    address refModule = _pubByIdByProfile[vars.profileIdPointed][vars.pubIdPointed].referenceModule;
    if (refModule != address(0)) {
      IReferenceModule(refModule).processComment(
        vars.profileId,
        vars.profileIdPointed,
        vars.pubIdPointed,
        vars.referenceModuleData
      );
    }

    // Prevents a stack too deep error
    _emitCommentCreated(vars, pubId, collectModuleReturnData, referenceModuleReturnData);
  }

  /**
   * @notice Creates a mirror publication mapped to the given profile.
   *
   * @param vars The MirrorData struct to use to create the mirror.
   * @param pubId The publication ID to associate with this publication.
   * @param _pubByIdByProfile The storage reference to the mapping of publications by publication ID by profile ID.
   * @param _referenceModuleWhitelisted The storage reference to the mapping of whitelist status by reference module address.
   */
  function createMirror(
    DataTypes.MirrorData memory vars,
    uint256 pubId,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _referenceModuleWhitelisted
  ) external {
    (uint256 rootProfileIdPointed, uint256 rootPubIdPointed, ) = Helpers.getPointedIfMirror(
      vars.profileIdPointed,
      vars.pubIdPointed,
      _pubByIdByProfile
    );

    _pubByIdByProfile[vars.profileId][pubId].profileIdPointed = rootProfileIdPointed;
    _pubByIdByProfile[vars.profileId][pubId].pubIdPointed = rootPubIdPointed;

    // Reference module initialization
    bytes memory referenceModuleReturnData = _initPubReferenceModule(
      vars.profileId,
      pubId,
      vars.referenceModule,
      vars.referenceModuleInitData,
      _pubByIdByProfile,
      _referenceModuleWhitelisted
    );

    // Reference module validation
    address refModule = _pubByIdByProfile[rootProfileIdPointed][rootPubIdPointed].referenceModule;
    if (refModule != address(0)) {
      IReferenceModule(refModule).processMirror(
        vars.profileId,
        rootProfileIdPointed,
        rootPubIdPointed,
        vars.referenceModuleData
      );
    }

    emit Events.MirrorCreated(
      vars.profileId,
      pubId,
      rootProfileIdPointed,
      rootPubIdPointed,
      vars.referenceModuleData,
      vars.referenceModule,
      referenceModuleReturnData,
      block.timestamp
    );
  }

  function _initPubCollectModule(
    uint256 profileId,
    uint256 pubId,
    address collectModule,
    bytes memory collectModuleInitData,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _collectModuleWhitelisted
  ) private returns (bytes memory) {
    if (!_collectModuleWhitelisted[collectModule]) revert Errors.CollectModuleNotWhitelisted();
    _pubByIdByProfile[profileId][pubId].collectModule = collectModule;
    return ICollectModule(collectModule).initializePublicationCollectModule(profileId, pubId, collectModuleInitData);
  }

  function _initPubReferenceModule(
    uint256 profileId,
    uint256 pubId,
    address referenceModule,
    bytes memory referenceModuleInitData,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _referenceModuleWhitelisted
  ) private returns (bytes memory) {
    if (referenceModule == address(0)) return new bytes(0);
    if (!_referenceModuleWhitelisted[referenceModule]) revert Errors.ReferenceModuleNotWhitelisted();
    _pubByIdByProfile[profileId][pubId].referenceModule = referenceModule;
    return IReferenceModule(referenceModule).initializeReferenceModule(profileId, pubId, referenceModuleInitData);
  }

  function _initFollowModule(
    uint256 profileId,
    address followModule,
    bytes memory followModuleInitData,
    mapping(address => bool) storage _followModuleWhitelisted
  ) private returns (bytes memory) {
    if (!_followModuleWhitelisted[followModule]) revert Errors.FollowModuleNotWhitelisted();
    return IFollowModule(followModule).initializeFollowModule(profileId, followModuleInitData);
  }

  function _initPubReadModule(
    DataTypes.ReadPostData memory vars,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile,
    mapping(address => bool) storage _readModuleWhitelisted
  ) private returns (bytes memory) {
    if (vars.readModule == address(0)) return new bytes(0);
    if (!_readModuleWhitelisted[vars.readModule]) revert Errors.ReadModuleNotWhitelisted();
    _pubByIdByProfile[vars.profileId][vars.pubId].readModule = vars.readModule;
    return
      IReadModule(vars.readModule).initializePublicationReadModule(vars.profileId, vars.pubId, vars.readModuleInitData);
  }

  function _emitCommentCreated(
    DataTypes.CommentData memory vars,
    uint256 pubId,
    bytes memory collectModuleReturnData,
    bytes memory referenceModuleReturnData
  ) private {
    emit Events.CommentCreated(
      vars.profileId,
      pubId,
      vars.contentURI,
      vars.profileIdPointed,
      vars.pubIdPointed,
      vars.referenceModuleData,
      vars.collectModule,
      collectModuleReturnData,
      vars.referenceModule,
      referenceModuleReturnData,
      block.timestamp
    );
  }

  function _emitProfileCreated(
    uint256 profileId,
    DataTypes.CreateProfileData calldata vars,
    bytes memory followModuleReturnData
  ) internal {
    DataTypes.CreateProfileEvent memory eventVars = DataTypes.CreateProfileEvent({
      to: vars.to,
      handle: vars.handle,
      imageURI: vars.imageURI,
      followModule: vars.followModule,
      followModuleReturnData: followModuleReturnData,
      followNFTURI: vars.followNFTURI,
      videoURI: vars.videoURI,
      metadataURI: vars.metadataURI
    });

    emit Events.ProfileCreated(
      profileId,
      msg.sender, // Creator is always the msg sender
      eventVars,
      block.timestamp
    );
  }

  function _validateHandle(string calldata handle) private pure {
    bytes memory byteHandle = bytes(handle);
    if (byteHandle.length == 0 || byteHandle.length > Constants.MAX_HANDLE_LENGTH) revert Errors.HandleLengthInvalid();

    uint256 byteHandleLength = byteHandle.length;
    for (uint256 i = 0; i < byteHandleLength; ) {
      if (
        (byteHandle[i] < "0" || byteHandle[i] > "z" || (byteHandle[i] > "9" && byteHandle[i] < "a")) &&
        byteHandle[i] != "." &&
        byteHandle[i] != "-" &&
        byteHandle[i] != "_"
      ) revert Errors.HandleContainsInvalidCharacters();
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {DataTypes} from "./DataTypes.sol";
import {Errors} from "./Errors.sol";

/**
 * @title Helpers
 * @author Lens Protocol
 *
 * @notice This is a library that only contains a single function that is used in the hub contract as well as in
 * both the publishing logic and interaction logic libraries.
 */
library Helpers {
  /**
   * @notice This helper function just returns the pointed publication if the passed publication is a mirror,
   * otherwise it returns the passed publication.
   *
   * @param profileId The token ID of the profile that published the given publication.
   * @param pubId The publication ID of the given publication.
   * @param _pubByIdByProfile A pointer to the storage mapping of publications by pubId by profile ID.
   *
   * @return tuple First, the pointed publication's publishing profile ID, second, the pointed publication's ID, and third, the
   * pointed publication's collect module. If the passed publication is not a mirror, this returns the given publication.
   */
  function getPointedIfMirror(
    uint256 profileId,
    uint256 pubId,
    mapping(uint256 => mapping(uint256 => DataTypes.PublicationStruct)) storage _pubByIdByProfile
  )
    internal
    view
    returns (
      uint256,
      uint256,
      address
    )
  {
    address collectModule = _pubByIdByProfile[profileId][pubId].collectModule;
    if (collectModule != address(0)) {
      return (profileId, pubId, collectModule);
    } else {
      uint256 pointedTokenId = _pubByIdByProfile[profileId][pubId].profileIdPointed;
      // We validate existence here as an optimization, so validating in calling contracts is unnecessary
      if (pointedTokenId == 0) revert Errors.PublicationDoesNotExist();

      uint256 pointedPubId = _pubByIdByProfile[profileId][pubId].pubIdPointed;

      address pointedCollectModule = _pubByIdByProfile[pointedTokenId][pointedPubId].collectModule;

      return (pointedTokenId, pointedPubId, pointedCollectModule);
    }
  }
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

library Constants {
  string internal constant FOLLOW_NFT_NAME_SUFFIX = "-Follower";
  string internal constant FOLLOW_NFT_SYMBOL_SUFFIX = "-Fl";
  string internal constant COLLECT_NFT_NAME_INFIX = "-Collect-";
  string internal constant COLLECT_NFT_SYMBOL_INFIX = "-Cl-";
  uint8 internal constant MAX_HANDLE_LENGTH = 31;
  uint16 internal constant MAX_PROFILE_IMAGE_URI_LENGTH = 6000;
  uint16 internal constant MAX_PROFILE_VIDEO_URI_LENGTH = 6000;
  uint16 internal constant MAX_PROFILE_METADATA_URI_LENGTH = 6000;
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

/**
 * @title ICollectModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible CollectModules.
 */
interface ICollectModule {
  /**
   * @notice Initializes data for a given publication being published. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile publishing the publication.
   * @param pubId The associated publication's LensHub publication ID.
   * @param data Arbitrary data __passed from the user!__ to be decoded.
   *
   * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
   * hub alongside the collect module's address and should be consumed by front ends.
   */
  function initializePublicationCollectModule(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (bytes memory);

  /**
   * @notice Processes a collect action for a given publication, this can only be called by the hub.
   *
   * @param referrerProfileId The LensHub profile token ID of the referrer's profile (only different in case of mirrors).
   * @param collector The collector address.
   * @param profileId The token ID of the profile associated with the publication being collected.
   * @param pubId The LensHub publication ID associated with the publication being collected.
   * @param data Arbitrary data __passed from the collector!__ to be decoded.
   */
  function processCollect(
    uint256 referrerProfileId,
    address collector,
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IReferenceModule
 * @author Lens Protocol
 *
 * @notice This is the standard interface for all Lens-compatible ReferenceModules.
 */
interface IReferenceModule {
  /**
   * @notice Initializes data for a given publication being published. This can only be called by the hub.
   * @param profileId The token ID of the profile publishing the publication.
   * @param pubId The associated publication's LensHub publication ID.
   * @param data Arbitrary data passed from the user to be decoded.
   *
   * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
   * hub alongside the collect module's address and should be consumed by front ends.
   */
  function initializeReferenceModule(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (bytes memory);

  /**
   * @notice Processes a comment action referencing a given publication. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile associated with the publication being published.
   * @param profileIdPointed The profile ID of the profile associated the publication being referenced.
   * @param pubIdPointed The publication ID of the publication being referenced.
   * @param data Arbitrary data __passed from the commenter!__ to be decoded.
   */
  function processComment(
    uint256 profileId,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes calldata data
  ) external;

  /**
   * @notice Processes a mirror action referencing a given publication. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile associated with the publication being published.
   * @param profileIdPointed The profile ID of the profile associated the publication being referenced.
   * @param pubIdPointed The publication ID of the publication being referenced.
   * @param data Arbitrary data __passed from the mirrorer!__ to be decoded.
   */
  function processMirror(
    uint256 profileId,
    uint256 profileIdPointed,
    uint256 pubIdPointed,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IReadModule
 * @author
 *
 * @notice This is the standard interface for all ReadModules.
 */
interface IReadModule {
  /**
   * @notice Initializes data for a given publication being published. This can only be called by the hub.
   *
   * @param profileId The token ID of the profile publishing the publication.
   * @param pubId The associated publication's LensHub publication ID.
   * @param data Arbitrary data __passed from the user!__ to be decoded.
   *
   * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
   * hub alongside the collect module's address and should be consumed by front ends.
   */
  function initializePublicationReadModule(
    uint256 profileId,
    uint256 pubId,
    bytes calldata data
  ) external returns (bytes memory);

  /**
   * @notice Authorize the module to move the profile's balance.
   *
   * @param profileId The token ID of the profile authorizing the module.
   * @param authorized If the module is authorized or not.
   */
  function authorizeModule(uint256 profileId, bool authorized) external;

  /**
   * @notice Processes a collect action for a given publication, this can only be called by the hub.
   *
   * @param creatorId The token ID of the profile that is reading the publication.
   * @param creatorId The token ID of the profile associated with the publication being read.
   * @param pubId The LensHub publication ID associated with the publication being read.
   * @param data Arbitrary data __passed to be decoded.
   */
  function processRead(
    uint256 consumerId,
    uint256 creatorId,
    uint256 pubId,
    bytes calldata data
  ) external;
}