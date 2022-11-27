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
import "../libraries/AppStorage.sol";
import "../libraries/LAdmin.sol";
import "../libraries/LERC721.sol";
import "../libraries/LPausable.sol";

error AdminFacet__InvalidAddress();

/// @title AdmindFacet
/// @author mejiasd3v, mektigboy, Thehitesh172
/// @notice Facet in charge of the administration of the airdrops
/// @dev Utilizes 'LDiamond', 'AppStorage', 'LAdmin', 'LERC721' and 'LPausable'
contract AdminFacet {
    ///////////////
    /// STORAGE ///
    ///////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Airdrop node
    /// @param _name Node name
    /// @param _to Recipient
    /// @param _amount Node amount
    function airdropNode(string memory _name, address _to, uint256 _amount) external {
        LDiamond.enforceIsOwner();
        LPausable.enforceIsUnpaused(s);

        if (_to == address(0)) revert AdminFacet__InvalidAddress();

        LAdmin.airdropNode(s, _name, _to, _amount, s.allTokens.length);
    }

    /// @notice Airdrop node amount
    /// @param _id Token ID
    /// @param _amount Node amount
    function airdropNodeAmount(uint256 _id, uint256 _amount) external {
        LDiamond.enforceIsOwner();
        LPausable.enforceIsUnpaused(s);

        if (s.tokenOwners[_id] == address(0)) revert AdminFacet__InvalidAddress();

        LAdmin.airdropNodeAmount(s, _id, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IERC20
/// @author mektigboy
interface IERC20 {
    //////////////
    /// EVENTS ///
    //////////////

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    /////////////
    /// LOGIC ///
    /////////////

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

interface IUniswapRouter02 {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
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
import "./LERC721.sol";
import "./LFees.sol";
import "./LNodeController.sol";
import "./LRewards.sol";

error LAdmin__UnregisteredNode();

/// @title LAdmin
/// @author mejiasd3v, mektigboy, Thehitesh172
library LAdmin {
    //////////////
    /// EVENTS ///
    //////////////

    event AirdropNode(address to, uint256 indexed id, uint256 indexed amount);

    event NodeCreated(uint256 indexed id, uint256 indexed amount);

    event NodeIncreased(uint256 indexed id, uint256 indexed amount);

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Airdrop node
    /// @param s AppStorage
    /// @param _name Node name
    /// @param _amount Node amount
    /// @param _id Token ID
    function airdropNode(
        AppStorage storage s,
        string memory _name,
        address _to,
        uint256 _amount,
        uint256 _id
    ) internal {
        Node memory node;

        node.name = _name;
        node.creation = block.timestamp;
        node.lastClaimTime = block.timestamp;
        node.amount = _amount;
        node.active = true;
        node.lastRewardUpdate = s.txCounter;

        s.nodeByTokenId[_id] = node;

        /// @notice Realistically impossible overflow/underflow
        unchecked {
            s.tvl += _amount;
        }

        LERC721.safeMint(s, _to, _id);

        /// @notice Realistically impossible overflow/underflow
        unchecked {
            ++s.totalNodesCreated;
        }

        emit AirdropNode(_to, _id, _amount);
        emit NodeCreated(_id, _amount);
    }

    /// @notice Airdrop node amount
    /// @param s AppStorage
    /// @param _id Token ID
    /// @param _amount Node amount
    function airdropNodeAmount(AppStorage storage s, uint256 _id, uint256 _amount) internal {
        Node storage node = s.nodeByTokenId[_id];

        if (node.amount == 0) revert LAdmin__UnregisteredNode();

        LNodeController.compound(s, _id);

        /// @notice Realistically impossible overflow/underflow
        unchecked {
            node.amount += _amount;

            s.tvl += _amount;
        }

        node.lastRewardUpdate = s.txCounter;

        emit NodeIncreased(_id, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LAuthorizable__OnlyAuthorized();

/// @title LAuthorizable
/// @author mektigboy
library LAuthorizable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Enforce only authorized address can call a certain function
    /// @param s AppStorage
    /// @param _address Address
    function enforceIsAuthorized(AppStorage storage s, address _address) internal view {
        if (!s.authorized[_address]) revert LAuthorizable__OnlyAuthorized();
    }
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
    function beforeTokenTransfer(AppStorage storage s, address _from, address _to, uint256 _id) internal {
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
    function beforeConsecutiveTokenTransfer(address, address, uint256, uint96 _size) internal pure {
        if (_size > 0) revert LERC721__UnsupportedConsecutiveTransfers();
    }

    /// @notice Add token to owner enumeration
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function addTokenToOwnerEnumeration(AppStorage storage s, address _to, uint256 _id) internal {
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
    function removeTokenFromOwnerEnumeration(AppStorage storage s, address _from, uint256 _id) internal {
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
    function safeTransfer(AppStorage storage s, address _from, address _to, uint256 _id, bytes memory _data) internal {
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
    function isApprovedOrOwner(AppStorage storage s, address _spender, uint256 _id) internal view returns (bool) {
        address owner = ownerOf(s, _id);

        return (_spender == owner || isApprovedForAll(s, owner, _spender) || getApproved(s, _id) == _spender);
    }

    /// @notice Mint token in a safe manner without data
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function safeMint(AppStorage storage s, address _to, uint256 _id) internal {
        safeMint(s, _to, _id, "");
    }

    /// @notice Mint token in a safe manner with data
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    /// @param _data Data
    function safeMint(AppStorage storage s, address _to, uint256 _id, bytes memory _data) internal {
        mint(s, _to, _id);

        if (!checkOnERC721Received(address(0), _to, _id, _data)) revert LERC721__TranferToNonERC721Receiver();
    }

    /// @notice Mint token
    /// @param s AppStorage
    /// @param _to Recipient
    /// @param _id Token ID
    function mint(AppStorage storage s, address _to, uint256 _id) internal {
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
    function transfer(AppStorage storage s, address _from, address _to, uint256 _id) internal {
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
    function approve(AppStorage storage s, address _to, uint256 _id) internal {
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
    function setApprovalForAll(AppStorage storage s, address _account, address _operator, bool _approved) internal {
        if (_account == _operator) revert LERC721__InvalidApproveToCaller();

        s.operatorApprovals[_account][_operator] = _approved;

        emit ApprovalForAll(_account, _operator, _approved);
    }

    /// @notice Get is approved for all
    /// @param s AppStorage
    /// @param _account User account
    /// @param _operator Token operator
    function isApprovedForAll(AppStorage storage s, address _account, address _operator) internal view returns (bool) {
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
    function afterTokenTransfer(address _from, address _to, uint256 _id) internal {}

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
    function afterConsecutiveTokenTransfer(address, address, uint256, uint96) internal {}

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
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapRouter02.sol";

error LFees__AVAXTransaferFailed();
error LFees__InvalidClaimFee();
error LFees__InvalidCompoundFee();
error LFees__InvalidDepositFee();

/// @title LFees
/// @author mektigboy
library LFees {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Enforce claim fee is sent to Treasury
    /// @param s AppStorage
    /// @param _amount Amount
    function enforceClaimFee(AppStorage storage s, uint256 _amount) internal returns (uint256) {
        uint256 fee = claimFee(_amount);

        if (!isQuoteValid(s, fee, msg.value)) revert LFees__InvalidClaimFee();

        (bool success, ) = s.treasury.call{ value: msg.value }("");

        if (!success) revert LFees__AVAXTransaferFailed();

        return fee;
    }

    /// @notice Enforce compound fee is sent to Treasury
    /// @param s AppStorage
    /// @param _amount Amount
    function enforceCompoundFee(AppStorage storage s, uint256 _amount) internal returns (uint256) {
        uint256 fee = (_amount * 15) / 100;

        IERC20(s.vpnd).transfer(s.treasury, fee);

        return fee;
    }

    /// @notice Enforce deposit fee is sent to Treasury
    /// @param s AppStorage
    /// @param _amount Amount
    function enforceDepositFee(AppStorage storage s, uint256 _amount) internal returns (uint256) {
        uint256 userBalance = IERC20(s.vpnd).balanceOf(msg.sender);

        if (userBalance < _amount) revert LFees__InvalidDepositFee();

        uint256 depositFee = (_amount * 5) / 100;

        IERC20(s.vpnd).transferFrom(msg.sender, s.treasury, depositFee);

        return depositFee;
    }

    function claimFee(uint256 _amount) internal pure returns (uint256) {
        return _amount > 0 ? (_amount * 75) / 1000 : 0; // 7.5%
    }

    /// @notice Pure function to get compound fee
    /// @param _amount Amount
    function getCompoundFee(uint256 _amount) internal pure returns (uint256) {
        return (_amount * 15) / 100;
    }

    function claimTaxQuote(AppStorage storage s, uint256 _amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = s.vpnd;
        path[1] = s.wavax;
        uint256[] memory amounts = IUniswapRouter02(s.dexRouter).getAmountsOut(_amount, path);

        return amounts[1];
    }

    function isAvaxQuoteValid(uint256 _quote, uint256 _quoteSlippagePct, uint256 _paid) internal pure returns (bool) {
        return _paid >= _quote - ((_quote * _quoteSlippagePct) / 10000);
    }

    function isQuoteValid(AppStorage storage s, uint256 _amount, uint256 _paid) internal view returns (bool) {
        uint256 quote = claimTaxQuote(s, _amount);
        return isAvaxQuoteValid(quote, s.quoteSlippagePct, _paid);
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
    function mulDiv(uint256 _x, uint256 _y, uint256 _denominator) internal pure returns (uint256 result_) {
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
    function mulDiv(uint256 _x, uint256 _y, uint256 _denominator, Rounding _rounding) internal pure returns (uint256) {
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

        if (_value >= 10 ** 64) {
            _value /= 10 ** 64;
            result += 64;
        }
        if (_value >= 10 ** 32) {
            _value /= 10 ** 32;
            result += 32;
        }
        if (_value >= 10 ** 16) {
            _value /= 10 ** 16;
            result += 16;
        }
        if (_value >= 10 ** 8) {
            _value /= 10 ** 8;
            result += 8;
        }
        if (_value >= 10 ** 4) {
            _value /= 10 ** 4;
            result += 4;
        }
        if (_value >= 10 ** 2) {
            _value /= 10 ** 2;
            result += 2;
        }
        if (_value >= 10 ** 1) {
            result += 1;
        }

        return result;
    }

    /// @notice Return the log in base 10, following the selected rounding direction, of a positive value
    /// @param _value Value
    /// @param _rounding Rounding
    function log10(uint256 _value, Rounding _rounding) internal pure returns (uint256) {
        uint256 result = log10(_value);

        return result + (_rounding == Rounding.Up && 10 ** result < _value ? 1 : 0);
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

import "./AppStorage.sol";
import "./LAuthorizable.sol";
import "./LERC721.sol";
import "./LFees.sol";
import "./LRewards.sol";
import "../interfaces/IERC20.sol";

error LNodeController__InactiveNode();
error LNodeController__UnregistredNode();
error LNodeController__OnlyNodeOwner();

/// @title LNodeController
/// @author mejiasd3v, mektigboy
library LNodeController {
    //////////////
    /// EVENTS ///
    //////////////

    event NodeClaimed(uint256 indexed id, uint256 indexed rewards);

    event NodeCompounded(uint256 indexed id, uint256 indexed rewards);

    event NodeCreated(uint256 indexed id, uint256 indexed amount);

    event NodeIncreased(uint256 indexed id, uint256 indexed amount);

    event NodeReactivated(uint256 indexed id, uint256 indexed expirationDate);

    event NodeRenamed(uint256 indexed id, string indexed name);

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Claim node
    /// @param _ids Node IDs array
    function claim(AppStorage storage s, uint256[] memory _ids) internal returns (uint256 rewards) {
        for (uint256 i = 0; i < _ids.length; ++i) {
            if (s.tokenOwners[_ids[i]] != msg.sender) revert LNodeController__OnlyNodeOwner();

            Node storage node = s.nodeByTokenId[_ids[i]];

            if (node.amount == 0) revert LNodeController__UnregistredNode();

            uint256 pending = LRewards.pendingRewards(s, node);

            if (pending != 0) {
                node.lastRewardUpdate = s.txCounter;
                node.lastClaimTime = block.timestamp;
                node.rewardPaid += pending;

                rewards += pending;

                emit NodeClaimed(_ids[i], pending);
            }
        }
    }

    function createNode(AppStorage storage s, string memory _name, uint256 _amount, uint256 tokenId) internal {
        Node memory node;

        node.name = _name;
        node.creation = block.timestamp;
        node.lastClaimTime = block.timestamp;
        node.amount = _amount;
        node.active = true;
        node.lastRewardUpdate = s.txCounter;

        s.nodeByTokenId[tokenId] = node;
        s.tvl += _amount;

        IERC20(s.vpnd).transferFrom(msg.sender, s.rewardsPool, _amount);

        LERC721.safeMint(s, msg.sender, tokenId);

        ++s.totalNodesCreated;

        emit NodeCreated(tokenId, _amount);
    }

    /// @notice Compound single node
    /// @param _id Node ID
    function compound(AppStorage storage s, uint256 _id) internal {
        Node storage node = s.nodeByTokenId[_id];

        if (node.amount == 0) revert LNodeController__UnregistredNode();

        uint256 pending = LRewards.pendingRewards(s, node);

        if (pending != 0) {
            uint256 compoundFee = LFees.enforceCompoundFee(s, pending);
            uint256 pendingAfterFee = pending - compoundFee;

            node.amount += pendingAfterFee;
            node.lastRewardUpdate = s.txCounter;
            node.rewardPaid += pending;
            IERC20(s.vpnd).transfer(s.rewardsPool, pendingAfterFee);

            s.tvl += pendingAfterFee;

            emit NodeCompounded(_id, pendingAfterFee);
        }
    }

    /// @notice Compound multiple nodes
    /// @param _ids Node IDs arrray
    function compound(AppStorage storage s, uint256[] memory _ids) internal returns (uint256 rewards, uint256 fees) {
        for (uint256 i = 0; i < _ids.length; ++i) {
            if (s.tokenOwners[_ids[i]] != msg.sender) revert LNodeController__OnlyNodeOwner();
            Node storage node = s.nodeByTokenId[_ids[i]];
            if (node.amount == 0) revert LNodeController__UnregistredNode();

            uint256 pending = LRewards.pendingRewards(s, node);

            if (pending != 0) {
                uint256 compoundFee = LFees.getCompoundFee(pending);
                uint256 pendingAfterFee = pending - compoundFee;

                node.amount += pendingAfterFee;
                node.lastClaimTime = block.timestamp;
                node.lastRewardUpdate = s.txCounter;
                node.rewardPaid += pending;

                rewards += pendingAfterFee;
                fees += compoundFee;

                s.tvl += pendingAfterFee;

                emit NodeCompounded(_ids[i], pendingAfterFee);
            }
        }
    }

    /// @notice Increase node amount
    /// @param _id Node ID
    /// @param _amount New deposit amount
    function increaseNodeAmount(AppStorage storage s, uint256 _id, uint256 _amount) internal {
        Node storage node = s.nodeByTokenId[_id];

        if (node.amount == 0) revert LNodeController__UnregistredNode();

        compound(s, _id); // :( haha miss js

        uint256 depositFee = LFees.enforceDepositFee(s, _amount);
        uint256 amountAfterFee = _amount - depositFee;
        IERC20(s.vpnd).transferFrom(msg.sender, s.rewardsPool, amountAfterFee);

        node.amount += amountAfterFee;
        s.tvl += amountAfterFee;

        emit NodeIncreased(_id, amountAfterFee);
    }

    /// @notice Rename node
    /// @param _id Node ID
    /// @param name New name
    function rename(AppStorage storage s, uint256 _id, string memory name) internal {
        Node storage node = s.nodeByTokenId[_id];
        if (node.amount == 0) revert LNodeController__UnregistredNode();
        node.name = name;

        emit NodeRenamed(_id, name);
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

import "../interfaces/IERC20.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LERC721.sol";

error LRewards__DailyReceptionMismatch();
error LRewards__InvalidNode();
error LRewards__TotalValueLockedIsZero();

/// @title LRewards
/// @author mejiasd3v, mektigboy, Thehitesh172
library LRewards {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Update rewards
    /// @param s AppStorage
    function updateRewards(AppStorage storage s) internal {
        if (s.tvl == 0) revert LRewards__TotalValueLockedIsZero();

        /// @notice Realistically impossible overflow/underflow
        unchecked {
            s.accPerShareUpdates[s.txCounter] =
                (s.dailyReceptions[s.txCounter] * s.ACCUMULATED_REWARD_PER_SHARE_PRECISION) /
                s.tvl;
        }
    }

    /// @notice Get pending rewards
    /// @param s AppStorage
    /// @param _node Node
    function pendingRewards(AppStorage storage s, Node memory _node) internal view returns (uint256) {
        ////////////////
        /// OPTION 0 ///
        ////////////////

        // uint256 txCounter = s.txCounter;
        // uint256 daysSinceLastClaim;
        // uint256 nodeLastRewardUpdate = _node.lastRewardUpdate;
        // uint256 nodeAmount = _node.amount;
        // uint256 accPrecision = s.ACCUMULATED_REWARD_PER_SHARE_PRECISION;
        // uint256 pending;

        // // assembly {
        // //     // let sSlot := sload(s.slot)
        // //     daysSinceLastClaim := sub(txCounter, nodeLastRewardUpdate)

        // //     if iszero(daysSinceLastClaim) { revert(0, 0) }

        // //     // for { let i := txCounter } lt(i, sub(txCounter, daysSinceLastClaim)) { i := sub(i, 1) }
        // //     // {
        // //     //     pending := add(pending, div(mul(nodeAmount, sSlot), accPrecision))
        // //     // }
        // // }

        // for (uint256 i = txCounter; i > txCounter - daysSinceLastClaim; --i) {
        //     pending += ((nodeAmount * s.accPerShareUpdates[i]) / accPrecision);
        // }

        // return pending;

        ////////////////
        /// OPTION 1 ///
        ////////////////

        // uint256 txCounter = s.txCounter;
        // uint256 daysSinceLastClaim = (txCounter - _node.lastRewardUpdate);

        // if (daysSinceLastClaim == 0) return 0;

        // uint256 nodeAmount = _node.amount;
        // uint256 accPrecision = s.ACCUMULATED_REWARD_PER_SHARE_PRECISION;
        // uint256 pending;

        // // ie: daysSinceLastClaim = 3
        // // Run 1: i = 3, s.rewardsDailyUpdates[3]
        // // Run 2: i = 2, s.rewardsDailyUpdates[2]
        // // Run 3: i = 1, s.rewardsDailyUpdates[1]
        // for (uint256 i = txCounter; i > txCounter - daysSinceLastClaim; --i) {
        //     pending += ((nodeAmount * s.accPerShareUpdates[i]) / accPrecision);
        // }

        // return pending;

        ////////////////
        /// OPTION 2 ///
        ////////////////

        uint256 daysSinceLastClaim = (s.txCounter - _node.lastRewardUpdate);

        if (daysSinceLastClaim == 0) return 0;

        uint256 nodeAmount = _node.amount;
        // uint256 accPrecision = s.ACCUMULATED_REWARD_PER_SHARE_PRECISION;
        uint256 pending;

        // ie: daysSinceLastClaim = 3
        // Run 1: i = 3, s.rewardsDailyUpdates[3]
        // Run 2: i = 2, s.rewardsDailyUpdates[2]
        // Run 3: i = 1, s.rewardsDailyUpdates[1]
        for (uint256 i = s.txCounter; i > s.txCounter - (s.txCounter - _node.lastRewardUpdate); --i) {
            pending += ((nodeAmount * s.accPerShareUpdates[i]) / s.ACCUMULATED_REWARD_PER_SHARE_PRECISION);
        }

        return pending;
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