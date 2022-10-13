// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";
import "clouds/diamond/LDiamond.sol";

error SettingsFacet__InvalidDepositFeePercent();

/// @title SettingsFacet
/// @author mektigboy
/// @notice Facet in charge of ...
/// @dev Only the owner can call the functions inside this facet
contract SettingsFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get 'vpnd' value in 'AppStorage'
    function vpnd() external view returns (address) {
        return s.vpnd;
    }

    /// @notice Get 'rewardsPool' value in 'AppStorage'
    function rewardsPool() external view returns (address) {
        return s.rewardsPool;
    }

    /// @notice Get 'nodeStorage' value in 'AppStorage'
    function nodeStorage() external view returns (address) {
        return s.nodeStorage;
    }

    /// @notice Get 'depositFeePercent' value in 'AppStorage'
    function depositFeePercent() external view returns (uint256) {
        return s.depositFeePercent;
    }

    /// @notice Update address of VPND token contract in 'AppStorage'
    /// @param _vpnd New address of VPND token contract
    function updateVPND(address _vpnd) external {
        LDiamond.enforceIsOwner();

        s.vpnd = _vpnd;
    }

    /// @notice Update address of 'RewardsPool' in 'AppStorage'
    /// @param _rewardsPool New address of 'RewardsPool'
    function updateRewardsPool(address _rewardsPool) external {
        LDiamond.enforceIsOwner();

        s.rewardsPool = _rewardsPool;
    }

    /// @notice Update 'NodeStorage' address
    /// @param _nodeStorage New address of 'NodeStorage'
    function updateNodeStorage(address _nodeStorage) external {
        LDiamond.enforceIsOwner();

        s.nodeStorage = _nodeStorage;
    }

    /// @notice Update deposit fee
    /// @param _depositFeePercent New deposit fee
    function updateDepositFeePercent(uint256 _depositFeePercent) external {
        LDiamond.enforceIsOwner();

        if (_depositFeePercent >= 5e17)
            revert SettingsFacet__InvalidDepositFeePercent();

        s.depositFeePercent = _depositFeePercent;
    }
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
    uint256 lastClaim;
    uint256 lastCompound;
    ///
    uint256 amount;
    uint256 rewardDebt;
    ///
    bool active;
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
    uint256 depositFeePercent;
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address rewardsPool;
    address nodeStorage;
    ///
    uint256 tvl;
    uint256 balance;
    uint256 dailyReception;
    uint256 dailySplit;
    mapping(uint256 => uint256) balances;
    mapping(uint256 => uint256) dailyReceptions;
    mapping(uint256 => uint256) dailySplits;
    uint256 transactionId;
    ///////////////////////
    /// NODE MANAGEMENT ///
    ///////////////////////
    mapping(address => Node[]) userNodes;
    /////////////
    /// NODES ///
    /////////////
    uint256 activeNodes;
    mapping(address => bool) alreadyMigrated;
    mapping(uint256 => Node) nodeByTokenId;
    //////////////
    /// ERC721 ///
    //////////////
    string name;
    string symbol;
    uint256 tokenCounter;
    mapping(uint256 => address) ownerOf;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
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
    bytes _calldata
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

    event DiamondCut(
        IDiamondCut.FacetCut[] _cut,
        address _init,
        bytes _calldata
    );

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
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
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
    /// @param _calldata ...
    function diamondCut(
        IDiamondCut.FacetCut[] memory _cut,
        address _init,
        bytes memory _calldata
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

        emit DiamondCut(_cut, _init, _calldata);

        initializeDiamondCut(_init, _calldata);
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
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facet]
                .functionSelectors[lastSelectorPosition];
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
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
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
    /// @param _calldata ...
    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            return;
        }

        enforceHasContractCode(_init);

        (bool success, bytes memory error) = _init.delegatecall(_calldata);

        if (!success) {
            if (error.length > 0) {
                /// @solidity memory-safe-assembly
                assembly {
                    let dataSize := mload(error)

                    revert(add(32, error), dataSize)
                }
            } else {
                revert LDiamond__InitializationFailed(_init, _calldata);
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

/// @title IDiamondCut
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @dev EIP-2535 "Diamond" standard
interface IDiamondCut {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCut(FacetCut[] _cut, address _init, bytes _calldata);

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
    /// @param _init Address of contract or facet to execute _calldata
    /// @param _calldata Function call, includes function selector and arguments
    function diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    ) external;
}