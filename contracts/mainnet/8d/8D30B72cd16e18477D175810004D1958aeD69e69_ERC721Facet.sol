// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IDiamondCut
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @dev EIP-2535 "Diamond" standard
interface IDiamondCut {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCut(FacetCut[] _cut, address _init, bytes _data);

    ///////////////
    /// STORAGE ///
    ///////////////

    /// ACTIONS

    /// Add     - 0
    /// Replace - 1
    /// Remove  - 2

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @param _cut Facet addreses and function selectors
    /// @param _init Address of contract or facet to execute _data
    /// @param _data Function call, includes function selector and arguments
    function diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IDiamondCut.sol";

error IDiamondCut__AddressMustBeZero();
error IDiamondCut__FunctionAlreadyExists();
error IDiamondCut__ImmutableFunction();
error IDiamondCut__IncorrectAction();
error IDiamondCut__InexistentFacetCode();
error IDiamondCut__InexistentFunction();
error IDiamondCut__InvalidAddressZero();
error IDiamondCut__InvalidReplacementWithSameFunction();
error IDiamondCut__NoSelectors();

error LDiamond__InitializationFailed(
  address _initializationContractAddress,
  bytes _data
);
error LDiamond__OnlyOwner();

/// @title LDiamond
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Diamond library
/// @dev EIP-2535 "Diamond" standard
library LDiamond {
  //////////////
  /// EVENTS ///
  //////////////

  event DiamondCut(IDiamondCut.FacetCut[] _cut, address _init, bytes _data);

  event OwnershipTransferred(
    address indexed pastOwner,
    address indexed newOwner
  );

  ///////////////
  /// STORAGE ///
  ///////////////

  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    /// @notice Facet address
    address facetAddress;
    /// @notice Facet position in 'facetFunctionSelectors.functionSelectors' array
    uint96 functionSelectorPosition;
  }

  struct FacetFunctionSelectors {
    /// @notice Function selectors
    bytes4[] functionSelectors;
    /// @notice Position of 'facetAddress' in 'facetAddresses' array
    uint256 facetAddressPosition;
  }

  struct DiamondStorage {
    /// @notice Position of selector in 'facetFunctionSelectors.selectors' array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    /// @notice Facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    /// @notice Facet addresses
    address[] facetAddresses;
    /// @notice Query if contract implements an interface
    mapping(bytes4 => bool) supportedInterfaces;
    /// @notice Owner of contract
    address owner;
  }

  /////////////
  /// LOGIC ///
  /////////////

  /// @notice ...
  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;

    assembly {
      ds.slot := position
    }
  }

  /// @notice ...
  /// @param _owner New owner
  function updateContractOwner(address _owner) internal {
    DiamondStorage storage ds = diamondStorage();

    address oldOwner = ds.owner;

    ds.owner = _owner;

    emit OwnershipTransferred(oldOwner, _owner);
  }

  /// @notice ...
  function contractOwner() internal view returns (address owner_) {
    owner_ = diamondStorage().owner;
  }

  /// @notice ...
  function enforceIsOwner() internal view {
    if (diamondStorage().owner != msg.sender) revert LDiamond__OnlyOwner();
  }

  /// @notice ...
  /// @param _cut ...
  /// @param _init ...
  /// @param _data ...
  function diamondCut(
    IDiamondCut.FacetCut[] memory _cut,
    address _init,
    bytes memory _data
  ) internal {
    for (uint256 facetIndex; facetIndex < _cut.length; ++facetIndex) {
      IDiamondCut.FacetCutAction action = _cut[facetIndex].action;

      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(
          _cut[facetIndex].facetAddress,
          _cut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(
          _cut[facetIndex].facetAddress,
          _cut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(
          _cut[facetIndex].facetAddress,
          _cut[facetIndex].functionSelectors
        );
      } else {
        revert IDiamondCut__IncorrectAction();
      }
    }

    emit DiamondCut(_cut, _init, _data);

    initializeDiamondCut(_init, _data);
  }

  /// @notice ...
  /// @param _facet Facet address
  /// @param _selectors Facet selectors
  function addFunctions(address _facet, bytes4[] memory _selectors) internal {
    if (_selectors.length == 0) revert IDiamondCut__NoSelectors();

    DiamondStorage storage ds = diamondStorage();

    if (_facet == address(0)) revert IDiamondCut__InvalidAddressZero();

    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facet].functionSelectors.length
    );

    /// @notice Add new facet address if it does not exists already

    if (selectorPosition == 0) {
      addFacet(ds, _facet);
    }

    for (
      uint256 selectorIndex;
      selectorIndex < _selectors.length;
      ++selectorIndex
    ) {
      bytes4 selector = _selectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      if (oldFacetAddress != address(0))
        revert IDiamondCut__FunctionAlreadyExists();

      addFunction(ds, selector, selectorPosition, _facet);

      ++selectorPosition;
    }
  }

  /// @notice ...
  /// @param _facet Facet address
  /// @param _selectors Facet selectors
  function replaceFunctions(address _facet, bytes4[] memory _selectors)
    internal
  {
    if (_selectors.length == 0) revert IDiamondCut__NoSelectors();

    DiamondStorage storage ds = diamondStorage();

    if (_facet == address(0)) revert IDiamondCut__InvalidAddressZero();

    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facet].functionSelectors.length
    );

    /// @notice Add new facet address if it does not exists already

    if (selectorPosition == 0) {
      addFacet(ds, _facet);
    }
    for (
      uint256 selectorIndex;
      selectorIndex < _selectors.length;
      ++selectorIndex
    ) {
      bytes4 selector = _selectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      if (oldFacetAddress == _facet)
        revert IDiamondCut__InvalidReplacementWithSameFunction();

      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facet);

      ++selectorPosition;
    }
  }

  /// @notice ...
  /// @param _facet Facet address
  /// @param _selectors Facet selectors
  function removeFunctions(address _facet, bytes4[] memory _selectors)
    internal
  {
    if (_selectors.length == 0) revert IDiamondCut__NoSelectors();

    DiamondStorage storage ds = diamondStorage();

    if (_facet != address(0)) revert IDiamondCut__AddressMustBeZero();

    for (
      uint256 selectorIndex;
      selectorIndex < _selectors.length;
      ++selectorIndex
    ) {
      bytes4 selector = _selectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  /// @notice ...
  /// @param ds DiamondStorage
  /// @param _facet Facet address
  function addFacet(DiamondStorage storage ds, address _facet) internal {
    enforceHasContractCode(_facet);

    ds.facetFunctionSelectors[_facet].facetAddressPosition = ds
      .facetAddresses
      .length;
    ds.facetAddresses.push(_facet);
  }

  /// @notice ...
  /// @param ds DiamondStorage
  /// @param _selector Facet selector
  /// @param _positon Selector position
  /// @param _facet Facet address
  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _positon,
    address _facet
  ) internal {
    ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition = _positon;
    ds.facetFunctionSelectors[_facet].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facet;
  }

  /// @notice ...
  /// @param ds DiamondStorage
  /// @param _facet Facet address
  /// @param _selector Facet address
  function removeFunction(
    DiamondStorage storage ds,
    address _facet,
    bytes4 _selector
  ) internal {
    if (_facet == address(0)) revert IDiamondCut__InexistentFunction();

    /// @notice An immutable function is defined directly in diamond
    if (_facet == address(this)) revert IDiamondCut__ImmutableFunction();

    /// @notice Replaces selector with last selector, then deletes last selector
    uint256 selectorPosition = ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition;
    uint256 lastSelectorPosition = ds
      .facetFunctionSelectors[_facet]
      .functionSelectors
      .length - 1;

    /// @notice Replaces '_selector' with 'lastSelector' if not they are not the same
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facet].functionSelectors[
        lastSelectorPosition
      ];
      ds.facetFunctionSelectors[_facet].functionSelectors[
        selectorPosition
      ] = lastSelector;
      ds
        .selectorToFacetAndPosition[lastSelector]
        .functionSelectorPosition = uint96(selectorPosition);
    }

    /// @notice Deletes last selector

    ds.facetFunctionSelectors[_facet].functionSelectors.pop();

    delete ds.selectorToFacetAndPosition[_selector];

    /// @notice Deletes facet address if there are no more selectors for facet address
    if (lastSelectorPosition == 0) {
      /// @notice Replaces facet address with last facet address, deletes last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds
        .facetFunctionSelectors[_facet]
        .facetAddressPosition;

      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds
          .facetFunctionSelectors[lastFacetAddress]
          .facetAddressPosition = facetAddressPosition;
      }

      ds.facetAddresses.pop();

      delete ds.facetFunctionSelectors[_facet].facetAddressPosition;
    }
  }

  /// @notice ...
  /// @param _init ...
  /// @param _data ...
  function initializeDiamondCut(address _init, bytes memory _data) internal {
    if (_init == address(0)) {
      return;
    }

    enforceHasContractCode(_init);

    (bool success, bytes memory error) = _init.delegatecall(_data);

    if (!success) {
      if (error.length > 0) {
        /// @solidity memory-safe-assembly
        assembly {
          let dataSize := mload(error)

          revert(add(32, error), dataSize)
        }
      } else {
        revert LDiamond__InitializationFailed(_init, _data);
      }
    }
  }

  /// @notice ...
  /// @param _contract Contract address
  function enforceHasContractCode(address _contract) internal view {
    uint256 contractSize;

    assembly {
      contractSize := extcodesize(_contract)
    }

    if (contractSize == 0) revert IDiamondCut__InexistentFacetCode();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/contracts/LDiamond.sol";
import "../interfaces/IERC721Metadata.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LERC721.sol";
import "../libraries/LPausable.sol";

error ERC721Facet__ApproveCallerNotOwnerOrApproved();
error ERC721Facet__GlobalIndexOutOfBounds();
error ERC721Facet__InvalidApprovalToCurrentOwner();
error ERC721Facet__InvalidBaseURI();
error ERC721Facet__OnlyApprovedOrOwner();
error ERC721Facet__OwnerIndexOutOfBounds();
error ERC721Facet__NonTransferrable();

/// @title ERC721Facet
/// @author mektigboy
/// @notice Facet in charge of the administration of the token
/// @dev Utilizes 'AppStorage', 'LERC721' and 'LPausable'
contract ERC721Facet is IERC721Metadata {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get token name
    function name() external view returns (string memory) {
        return s.name;
    }

    /// @notice Get token symbol
    function symbol() external view returns (string memory) {
        return s.symbol;
    }

    /// @notice Get token URI
    /// @param _id Token ID
    function tokenURI(uint256 _id) external view returns (string memory) {
        return LERC721.tokenURI(s, _id);
    }

    /// @notice Get token balance
    /// @param _account User account
    function balanceOf(address _account) public view returns (uint256) {
        return LERC721.balanceOf(s, _account);
    }

    /// @notice Get token owner
    /// @param _id Token ID
    function ownerOf(uint256 _id) external view returns (address) {
        return LERC721.ownerOf(s, _id);
    }

    /// @notice Get total token supply
    function totalSupply() public view returns (uint256) {
        return s.allTokens.length;
    }

    /// @notice Update base URI
    /// @param _baseURI New base URI
    function updateBaseURI(string memory _baseURI) external {
        LDiamond.enforceIsOwner();

        if (!(bytes(_baseURI).length > 0)) revert ERC721Facet__InvalidBaseURI();

        LERC721.updateBaseURI(s, _baseURI);
    }

    /// @notice Get token ID owned by user at a given index of its token list
    /// @param _account User account
    /// @param _index Token index
    function tokenOfOwnerByIndex(address _account, uint256 _index) external view returns (uint256) {
        if (_index > balanceOf(_account)) revert ERC721Facet__OwnerIndexOutOfBounds();

        return s.ownedTokens[_account][_index];
    }

    /// @notice Get token ID at a given index of all the tokens stored by the contract
    /// @param _index Token index
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        if (_index > totalSupply()) revert ERC721Facet__GlobalIndexOutOfBounds();

        return s.allTokens[_index];
    }

    /// @notice Approve token
    /// @param _to Recipient
    /// @param _id Token ID
    function approve(address _to, uint256 _id) external {
        address owner = LERC721.ownerOf(s, _id);

        if (_to == owner) revert ERC721Facet__InvalidApprovalToCurrentOwner();

        if (owner != msg.sender || isApprovedForAll(owner, msg.sender))
            revert ERC721Facet__ApproveCallerNotOwnerOrApproved();

        LERC721.approve(s, _to, _id);
    }

    /// @notice Get account from token ID
    /// @param _id Token ID
    function getApproved(uint256 _id) external view returns (address) {
        return s.tokenApprovals[_id];
    }

    /// @notice Set approval for all
    /// @param _operator Token operator
    /// @param _approved Approved value
    function setApprovalForAll(address _operator, bool _approved) external {
        LERC721.setApprovalForAll(s, msg.sender, _operator, _approved);
    }

    /// @notice Get is approved for all
    /// @param _account User account
    /// @param _operator Token operator
    function isApprovedForAll(address _account, address _operator) public view returns (bool) {
        return s.operatorApprovals[_account][_operator];
    }

    /// @notice Transfer token from sender to recipient
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external {
        if (!s.isTransferable) revert ERC721Facet__NonTransferrable();
        if (!LERC721.isApprovedOrOwner(s, msg.sender, _id)) revert ERC721Facet__OnlyApprovedOrOwner();

        LERC721.transfer(s, _from, _to, _id);
    }

    /// @notice Transfer token from sender to recipient in a safe manner without data
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external {
        if (!s.isTransferable) revert ERC721Facet__NonTransferrable();
        safeTransferFrom(_from, _to, _id, "");
    }

    /// @notice Transfer token from sender to recipient in a safe manner with data
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) public {
        if (!s.isTransferable) revert ERC721Facet__NonTransferrable();
        if (!LERC721.isApprovedOrOwner(s, msg.sender, _id)) revert ERC721Facet__OnlyApprovedOrOwner();

        LERC721.safeTransfer(s, _from, _to, _id, _data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.17;

/// @title IERC721
/// @author mejiasd3v, mektigboy
interface IERC721 {
    /////////////
    /// EVENT ///
    /////////////

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /////////////
    /// LOGIC ///
    /////////////

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC721.sol";

/// @title IERC721Metadata
/// @author mejiasd3v, mektigboy
interface IERC721Metadata is IERC721 {
    /////////////
    /// LOGIC ///
    /////////////

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC721Receiver
/// @author mektigboy
interface IERC721Receiver {
    /////////////
    /// LOGIC ///
    /////////////

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

////////////
/// NODE ///
////////////

struct Node {
    string name;
    ///
    uint256 creation;
    uint256 lastClaimTime;
    ///
    uint256 amount;
    uint256 rewardPaid;
    ///
    bool active;
    ///
    uint256 lastRewardUpdate;
}

///////////////
/// ROYALTY ///
///////////////

struct RoyaltyInfo {
    address recipient;
    uint256 bps;
}

////////////
/// MATH ///
////////////

enum Rounding {
    Down,
    Up,
    Zero
}

///////////////////
/// APP STORAGE ///
///////////////////

struct AppStorage {
    ////////////////////
    /// AUTHORIZABLE ///
    ////////////////////
    mapping(address => bool) authorized;
    ////////////////
    /// PAUSABLE ///
    ////////////////
    bool paused;
    ///////////////
    /// REWARDS ///
    ///////////////
    uint256 _accumulatedRewardPerShare; // DEPRECATED
    uint256 ACCUMULATED_REWARD_PER_SHARE_PRECISION;
    uint256 _lastRewardBalance; // DEPRECATED
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address wavax;
    address stratosphere;
    address rewardsPool;
    address nodeStorage;
    address treasury;
    address referralController;
    ///
    uint256 deployedAt;
    uint256 tvl;
    uint256 _balance; // DEPRECATED
    uint256 _dailyReception; // DEPRECATED
    uint256 txCounter;
    mapping(uint256 => uint256) balances;
    mapping(uint256 => uint256) dailyReceptions;
    /////////////
    /// NODES ///
    /////////////
    uint256 minNodeAmount;
    uint256 maxNodesPerWallet;
    mapping(uint256 => Node) nodeByTokenId;
    /////////////////
    /// MIGRATION ///
    /////////////////
    uint256 totalNodesCreated;
    uint256 totalNodesMigrated;
    mapping(address => bool) alreadyMigrated;
    /////////////
    /// TAXES ///
    /////////////
    uint256 claimFee;
    uint256 compoundFee;
    uint256 depositFee;
    uint256 quoteSlippagePct;
    address dexRouter;
    //////////////
    /// ERC721 ///
    //////////////
    string baseURI;
    string name;
    string symbol;
    bool isTransferable;
    mapping(address => uint256) tokenBalances;
    mapping(uint256 => address) tokenOwners;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    /////////////////////////
    /// ERC721 ENUMERABLE ///
    /////////////////////////
    mapping(address => mapping(uint256 => uint256)) ownedTokens;
    mapping(uint256 => uint256) ownedTokensIndex;
    uint256[] allTokens;
    mapping(uint256 => uint256) allTokensIndex;
    /////////////////
    /// ROYALTIES ///
    /////////////////
    address royaltyRecipient;
    uint16 royaltyBps;
    mapping(uint256 => RoyaltyInfo) royaltyInfoForToken;
    //////////////////////
    /// REWARDS UPDATE ///
    //////////////////////
    mapping(uint256 => uint256) accPerShareUpdates;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AppStorage.sol";
import "./LStrings.sol";
import "../interfaces/IERC721Receiver.sol";

error LERC721__AlreadyMintedToken();
error LERC721__InvalidAddress();
error LERC721__InvalidApproveToCaller();
error LERC721__InvalidMintToAddressZero();
error LERC721__InvalidToken();
error LERC721__InvalidTransferToAddressZero();
error LERC721__OnlyOwnerOrApproved();
error LERC721__SenderIsNotOwner();
error LERC721__TranferToNonERC721Receiver();
error LERC721__UnsupportedConsecutiveTransfers();

/// @title LERC721
/// @author mektigboy
/// @notice ERC721 library
/// @dev Internal use
library LERC721 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get token owner
    /// @param s AppStorage
    /// @param _id Token ID
    function ownerOf(AppStorage storage s, uint256 _id) internal view returns (address) {
        address owner = s.tokenOwners[_id];

        // if (owner == address(0)) revert LERC721__InvalidToken();

        return owner;
    }

    /// @notice Get token balance
    /// @param s AppStorage
    /// @param _account User account
    function balanceOf(AppStorage storage s, address _account) internal view returns (uint256) {
        if (_account == address(0)) revert LERC721__InvalidAddress();

        return s.tokenBalances[_account];
    }

    function tokenURI(AppStorage storage s, uint256 tokenId) internal view returns (string memory) {
        if (!exists(s, tokenId)) revert LERC721__InvalidToken();
        string memory baseURI = s.baseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, LStrings.toString(tokenId))) : "";
    }

    function updateBaseURI(AppStorage storage s, string memory _baseURI) internal {
        s.baseURI = _baseURI;
    }

    /// @notice Hook called before any token transfer
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function beforeTokenTransfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id
    ) internal {
        if (_from == address(0)) {
            addTokenToAllTokensEnumeration(s, _id);
        } else if (_from != _to) {
            removeTokenFromOwnerEnumeration(s, _from, _id);
        }
        if (_to == address(0)) {
            removeTokenFromAllTokensEnumeration(s, _id);
        } else if (_to != _from) {
            addTokenToOwnerEnumeration(s, _to, _id);
        }
    }

    /// @notice Hook called before any consecutive token transfer
    /// @param _size Size
    function beforeConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96 _size
    ) internal pure {
        if (_size > 0) revert LERC721__UnsupportedConsecutiveTransfers();
    }

    /// @notice Add token to owner enumeration
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function addTokenToOwnerEnumeration(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        uint256 length = balanceOf(s, _to);

        s.ownedTokens[_to][length] = _id;
        s.ownedTokensIndex[_id] = length;
    }

    /// @notice Add token to all tokens enumeration
    /// @param s AppStorage
    /// @param _id Token ID
    function addTokenToAllTokensEnumeration(AppStorage storage s, uint256 _id) internal {
        s.allTokensIndex[_id] = s.allTokens.length;

        s.allTokens.push(_id);
    }

    /// @notice Remove token from owner enumeration
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _id Token ID
    function removeTokenFromOwnerEnumeration(
        AppStorage storage s,
        address _from,
        uint256 _id
    ) internal {
        uint256 lastTokenIndex = balanceOf(s, _from) - 1;
        uint256 tokenIndex = s.ownedTokensIndex[_id];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s.ownedTokens[_from][lastTokenIndex];

            s.ownedTokens[_from][tokenIndex] = lastTokenId;
            s.ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete s.ownedTokensIndex[_id];
        delete s.ownedTokens[_from][lastTokenIndex];
    }

    /// @notice Remove token from all tokens enumeration
    /// @param s AppStorage
    /// @param _id Token ID
    function removeTokenFromAllTokensEnumeration(AppStorage storage s, uint256 _id) private {
        uint256 lastTokenIndex = s.allTokens.length - 1;
        uint256 tokenIndex = s.allTokensIndex[_id];

        uint256 lastTokenId = s.allTokens[lastTokenIndex];

        s.allTokens[tokenIndex] = lastTokenId;
        s.allTokensIndex[lastTokenId] = tokenIndex;

        delete s.allTokensIndex[_id];

        s.allTokens.pop();
    }

    /// @notice Transfer token in a safe manner
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function safeTransfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) internal {
        transfer(s, _from, _to, _id);

        if (!checkOnERC721Received(_from, _to, _id, _data)) revert LERC721__TranferToNonERC721Receiver();
    }

    /// @notice Get if token exists
    /// @param s AppStorage s
    /// @param _id Token ID
    function exists(AppStorage storage s, uint256 _id) internal view returns (bool) {
        return ownerOf(s, _id) != address(0);
    }

    /// @notice Check if it is approved or owner
    /// @param _spender Token spender
    /// @param _id Token ID
    function isApprovedOrOwner(
        AppStorage storage s,
        address _spender,
        uint256 _id
    ) internal view returns (bool) {
        address owner = ownerOf(s, _id);

        return (_spender == owner || isApprovedForAll(s, owner, _spender) || getApproved(s, _id) == _spender);
    }

    /// @notice Mint token in a safe manner without data
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function safeMint(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        safeMint(s, _to, _id, "");
    }

    /// @notice Mint token in a safe manner with data
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function safeMint(
        AppStorage storage s,
        address _to,
        uint256 _id,
        bytes memory _data
    ) internal {
        mint(s, _to, _id);

        if (!checkOnERC721Received(address(0), _to, _id, _data)) revert LERC721__TranferToNonERC721Receiver();
    }

    /// @notice Mint token
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function mint(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        if (_to == address(0)) revert LERC721__InvalidMintToAddressZero();

        if (exists(s, _id)) revert LERC721__AlreadyMintedToken();

        beforeTokenTransfer(s, address(0), _to, _id);

        if (exists(s, _id)) revert LERC721__AlreadyMintedToken();

        s.tokenBalances[_to] += 1;
        s.tokenOwners[_id] = _to;

        emit Transfer(address(0), _to, _id);

        afterTokenTransfer(address(0), _to, _id);
    }

    /// @notice Burn token
    /// @param s AppStorage
    /// @param _id Token ID
    function burn(AppStorage storage s, uint256 _id) internal {
        address owner = ownerOf(s, _id);

        beforeTokenTransfer(s, owner, address(0), _id);

        owner = ownerOf(s, _id);

        delete s.tokenApprovals[_id];

        s.tokenBalances[owner] -= 1;

        delete s.tokenOwners[_id];

        emit Transfer(owner, address(0), _id);

        afterTokenTransfer(owner, address(0), _id);
    }

    /// @notice Transfer token
    /// @param s AppStorage
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function transfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256 _id
    ) internal {
        if (_from != ownerOf(s, _id)) revert LERC721__SenderIsNotOwner();

        if (_to == address(0)) revert LERC721__InvalidTransferToAddressZero();

        beforeTokenTransfer(s, _from, _to, _id);

        if (_from != ownerOf(s, _id)) revert LERC721__SenderIsNotOwner();

        delete s.tokenApprovals[_id];

        s.tokenBalances[_from] -= 1;
        s.tokenBalances[_to] += 1;
        s.tokenOwners[_id] = _to;

        emit Transfer(_from, _to, _id);

        afterTokenTransfer(_from, _to, _id);
    }

    /// @notice Approve token
    /// @param s AppStorage
    /// @param _to Spender
    /// @param _id Token ID
    function approve(
        AppStorage storage s,
        address _to,
        uint256 _id
    ) internal {
        s.tokenApprovals[_id] = _to;

        emit Approval(ownerOf(s, _id), _to, _id);
    }

    /// @notice Get account from token ID
    /// @param s AppStorage
    /// @param _id Token ID
    function getApproved(AppStorage storage s, uint256 _id) internal view returns (address) {
        return s.tokenApprovals[_id];
    }

    /// @notice Set approval for all
    /// @param s AppStorage
    /// @param _account User account
    /// @param _operator Token operator
    /// @param _approved Approved value
    function setApprovalForAll(
        AppStorage storage s,
        address _account,
        address _operator,
        bool _approved
    ) internal {
        if (_account == _operator) revert LERC721__InvalidApproveToCaller();

        s.operatorApprovals[_account][_operator] = _approved;

        emit ApprovalForAll(_account, _operator, _approved);
    }

    /// @notice Get is approved for all
    /// @param s AppStorage
    /// @param _account User account
    /// @param _operator Token operator
    function isApprovedForAll(
        AppStorage storage s,
        address _account,
        address _operator
    ) internal view returns (bool) {
        return s.operatorApprovals[_account][_operator];
    }

    /// @notice Require that token is minted
    /// @param s AppStorage
    /// @param _id Token ID
    function requireMinted(AppStorage storage s, uint256 _id) internal view {
        if (!exists(s, _id)) revert LERC721__InvalidToken();
    }

    /// @notice Hook called after any token transfer
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    function afterTokenTransfer(
        address _from,
        address _to,
        uint256 _id
    ) internal {}

    /// @notice Hook called before any consecutive token transfer
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _size Size
    function beforeConsecutiveTokenTransfer(
        AppStorage storage s,
        address _from,
        address _to,
        uint256,
        uint96 _size
    ) internal {
        if (_from != address(0)) s.tokenBalances[_from] -= _size;

        if (_to != address(0)) s.tokenBalances[_to] += _size;
    }

    /// @notice Hook called after any consecutive token transfer
    function afterConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96
    ) internal {}

    /// @notice Check on ERC721 Received
    /// @param _from Sender
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function checkOnERC721Received(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) internal returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _id, _data) returns (bytes4 returnValue) {
                return returnValue == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert LERC721__TranferToNonERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AppStorage.sol";

/// @title LMath
/// @author mejiasd3v, mektigboy
library LMath {
    /////////////
    /// LOGIC ///
    /////////////

    ///@notice Return the biggest of two numbers
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a > _b ? _a : _b;
    }

    /// @notice Return the smallest of two numbers
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    /// @notice Return the average of two numbers. The result is roundend towards zero
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function average(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a & _b) + (_a ^ _b) / 2;
    }

    /// @notice Return the ceiling of the division of two numbers
    /// @param _a Value 'a'
    /// @param _b Value 'b'
    function ceilDiv(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a == 0 ? 0 : (_a - 1) / _b + 1;
    }

    /// @notice Calculate floor(_x * _y / _denominator) with full precision
    /// @param _x Value 'x'
    /// @param _y Value 'y'
    /// @param _denominator Denominator
    function mulDiv(
        uint256 _x,
        uint256 _y,
        uint256 _denominator
    ) internal pure returns (uint256 result_) {
        uint256 prod0;
        uint256 prod1;

        assembly {
            let mm := mulmod(_x, _y, not(0))

            prod0 := mul(_x, _y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            return prod0 / _denominator;
        }

        require(_denominator > prod1);

        uint256 remainder;

        assembly {
            remainder := mulmod(_x, _y, _denominator)
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        uint256 twos = _denominator & (~_denominator + 1);

        assembly {
            _denominator := div(_denominator, twos)
            prod0 := div(prod0, twos)
            twos := add(div(sub(0, twos), twos), 1)
        }

        prod0 |= prod1 * twos;

        uint256 inverse = (3 * _denominator) ^ 2;

        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;
        inverse *= 2 - _denominator * inverse;

        result_ = prod0 * inverse;

        return result_;
    }

    /// @notice Calculate x * y / denominator with full precision
    /// @param _x Value 'x'
    /// @param _y Value 'y'
    /// @param _denominator Denominator
    /// @param _rounding Rounding
    function mulDiv(
        uint256 _x,
        uint256 _y,
        uint256 _denominator,
        Rounding _rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(_x, _y, _denominator);

        if (_rounding == Rounding.Up && mulmod(_x, _y, _denominator) > 0) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the square root of a number
    /// @param _a Value 'a'

    function sqrt(uint256 _a) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 result = 1 << (log2(_a) >> 1);

        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;
        result = (result + _a / result) >> 1;

        return min(result, _a / result);
    }

    /// @notice Calculate sqrt(a), following the selected rounding direction
    /// @param _a Value 'a'
    /// @param _rounding Rounding
    function sqrt(uint256 _a, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = sqrt(_a);

        return result + (_rounding == Rounding.Up && result * result < _a ? 1 : 0);
    }

    /// @notice Return the log in base 2, rounded down, of a positive value
    /// @param _value Value
    function log2(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;

        if (_value >> 128 > 0) {
            _value >>= 128;
            result += 128;
        }
        if (_value >> 64 > 0) {
            _value >>= 64;
            result += 64;
        }
        if (_value >> 32 > 0) {
            _value >>= 32;
            result += 32;
        }
        if (_value >> 16 > 0) {
            _value >>= 16;
            result += 16;
        }
        if (_value >> 8 > 0) {
            _value >>= 8;
            result += 8;
        }
        if (_value >> 4 > 0) {
            _value >>= 4;
            result += 4;
        }
        if (_value >> 2 > 0) {
            _value >>= 2;
            result += 2;
        }
        if (_value >> 1 > 0) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the log in base 2, following the selected rounding direction, of a positive value
    /// @param _value Value
    /// @param _rounding Rounding
    function log2(uint256 _value, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = log2(_value);

        return result + (_rounding == Rounding.Up && 1 << result < _value ? 1 : 0);
    }

    /// @notice Return the log in base 10, rounded down, of a positive value
    /// @param _value Value
    function log10(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;

        if (_value >= 10**64) {
            _value /= 10**64;
            result += 64;
        }
        if (_value >= 10**32) {
            _value /= 10**32;
            result += 32;
        }
        if (_value >= 10**16) {
            _value /= 10**16;
            result += 16;
        }
        if (_value >= 10**8) {
            _value /= 10**8;
            result += 8;
        }
        if (_value >= 10**4) {
            _value /= 10**4;
            result += 4;
        }
        if (_value >= 10**2) {
            _value /= 10**2;
            result += 2;
        }
        if (_value >= 10**1) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the log in base 10, following the selected rounding direction, of a positive value
    /// @param _value Value
    /// @param _rounding Rounding
    function log10(uint256 _value, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = log10(_value);

        return result + (_rounding == Rounding.Up && 10**result < _value ? 1 : 0);
    }

    /// @notice Return the log in base 256, rounded down, of a positive value
    /// @param _value Value
    function log256(uint256 _value) internal pure returns (uint256) {
        uint256 result = 0;

        if (_value >> 128 > 0) {
            _value >>= 128;
            result += 16;
        }
        if (_value >> 64 > 0) {
            _value >>= 64;
            result += 8;
        }
        if (_value >> 32 > 0) {
            _value >>= 32;
            result += 4;
        }
        if (_value >> 16 > 0) {
            _value >>= 16;
            result += 2;
        }
        if (_value >> 8 > 0) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the log in base 10, following the selected rounding direction, of a positive value
    /// @param _value Value
    /// @param _rounding Rounding
    function log256(uint256 _value, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = log256(_value);

        return result + (_rounding == Rounding.Up && 1 << (result << 3) < _value ? 1 : 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LPausable__AlreadyPaused();
error LPausable__AlreadyUnpaused();
error LPausable__PausedFeature();

/// @title LPausable
/// @author mektigboy
library LPausable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Enforce feauture is paused
    /// @param s AppStorage
    function enforceIsUnpaused(AppStorage storage s) internal view {
        if (s.paused) revert LPausable__PausedFeature();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./LMath.sol";

error LStrings__InsufficientHexLength();

/// @title LStrings
/// @author mejiasd3v, mektigboy
library LStrings {
    bytes16 private constant SYMBOLS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /// @notice Convert a 'uint256' to its ASCII 'string' decimal representation
    /// @param _value Value
    function toString(uint256 _value) internal pure returns (string memory) {
        uint256 length = LMath.log10(_value) + 1;
        string memory buffer = new string(length);
        uint256 ptr;

        assembly {
            ptr := add(buffer, add(32, length))
        }

        while (true) {
            ptr--;

            assembly {
                mstore8(ptr, byte(mod(_value, 10), SYMBOLS))
            }

            _value /= 10;

            if (_value == 0) break;
        }
        return buffer;
    }

    /// @notice Convert a 'uint256' to its ASCII 'string' hexadecimal representation
    function toHexString(uint256 _value) internal pure returns (string memory) {
        return toHexString(_value, LMath.log256(_value) + 1);
    }

    /// @notice Convert a 'uint256' to its ASCII 'string' hexadecimal representation with fixed length
    function toHexString(uint256 _value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);

        buffer[0] = "0";
        buffer[1] = "x";

        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = SYMBOLS[_value & 0xf];
            _value >>= 4;
        }

        if (_value != 0) revert LStrings__InsufficientHexLength();

        return string(buffer);
    }

    /// @notice Convert an 'address' with fixed length of 20 bytes to its not checksummed ASCII 'string' hexadecimal representation
    function toHexString(address _address) internal pure returns (string memory) {
        return toHexString(uint256(uint160(_address)), ADDRESS_LENGTH);
    }
}