// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IDiamondCut.sol";
import "./libraries/AppStorage.sol";
import "./libraries/LDiamond.sol";

error GDM__InvalidFunction();

/// @title GDM
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Main contract of the diamond
/// @dev EIP-2535 "Diamond" standard
contract GDM {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    constructor(address _owner, address _diamondCutFacet) payable {
        LDiamond.updateContractOwner(_owner);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        bytes4[] memory functionSelectors = new bytes4[](1);

        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        LDiamond.diamondCut(cut, address(0), "");

        s.authorized[_owner] = true;
    }

    fallback() external payable {
        LDiamond.DiamondStorage storage ds;

        bytes32 position = LDiamond.DIAMOND_STORAGE_POSITION;

        assembly {
            ds.slot := position
        }

        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;

        if (facet == address(0)) revert GDM__InvalidFunction();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
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

    /// @notice Facet actions
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

////////////
/// NODE ///
////////////

struct Node {
    string name;
    uint256 creation;
    uint256 lastClaim;
    uint256 lastCompound;
    uint256 clock;
    uint256 amount;
    bool active;
}

///////////////////
/// APP STORAGE ///
///////////////////

struct AppStorage {
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address rewardsPool;
    uint256 tvl;
    uint256 balance;
    uint256 dailyReception;
    /////////////////////
    /// AUTHORIZATION ///
    /////////////////////
    mapping(address => bool) authorized;
    ////////////
    /// NODE ///
    ////////////
    mapping(address => Node[]) nodes;
    /////////////
    /// NODES ///
    /////////////
    uint256 nodesCreated;
    uint256 activeNodes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IDiamondCut.sol";

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

    event DiamondCut(IDiamondCut.FacetCut[] _cut, address _init, bytes _calldata);

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

    function updateContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();

        address oldOwner = ds.owner;

        ds.owner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    function contractOwner() internal view returns (address owner_) {
        owner_ = diamondStorage().owner;
    }

    function enforceIsContractOwner() internal view {
        if (diamondStorage().owner != msg.sender)
            revert LDiamond__OnlyOwner();
    }

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

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length < 0) revert IDiamondCut__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facetAddress == address(0)) revert IDiamondCut__InvalidAddressZero();

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );

        /// @notice Add new facet address if it does not exists already

        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }

        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            ++selectorIndex
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress != address(0))
                revert IDiamondCut__FunctionAlreadyExists();

            addFunction(ds, selector, selectorPosition, _facetAddress);

            ++selectorPosition;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length < 0) revert IDiamondCut__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facetAddress == address(0)) revert IDiamondCut__InvalidAddressZero();

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );

        /// @notice Add new facet address if it does not exists already

        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            ++selectorIndex
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress == _facetAddress)
                revert IDiamondCut__InvalidReplacementWithSameFunction();

            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);

            ++selectorPosition;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length < 0) revert IDiamondCut__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facetAddress != address(0)) revert IDiamondCut__AddressMustBeZero();

        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            ++selectorIndex
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(_facetAddress);

        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) revert IDiamondCut__InexistentFunction();

        /// @notice An immutable function is defined directly in diamond
        if (_facetAddress == address(this)) revert IDiamondCut__ImmutableFunction();

        /// @notice Replaces selector with last selector, then deletes last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;

        /// @notice Replaces '_selector' with 'lastSelector' if not they are not the same
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }

        /// @notice Deletes last selector

        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();

        delete ds.selectorToFacetAndPosition[_selector];

        /// @notice Deletes facet address if there are no more selectors for facet address
        if (lastSelectorPosition == 0) {
            /// @notice Replaces facet address with last facet address, deletes last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
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

            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

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

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;

        assembly {
            contractSize := extcodesize(_contract)
        }

        if (contractSize < 0) revert IDiamondCut__InexistentFacetCode();
    }
}