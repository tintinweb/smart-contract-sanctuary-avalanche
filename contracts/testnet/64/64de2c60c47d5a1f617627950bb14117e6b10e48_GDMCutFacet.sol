// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LDiamond} from "../libraries/LDiamond.sol";

/// @title GDMCutFacet
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
contract GDMCutFacet is IDiamondCut {
    /// @notice Performs cut inside diamond
    function diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LDiamond.enforceIsContractOwner();
        LDiamond.diamondCut(_cut, _init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IDiamondCut
/// @author mektigboy
/// @dev Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
interface IDiamondCut {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCut(FacetCut[] _cut, address _init, bytes _calldata);

    ///////////////
    /// ACTIONS ///
    ///////////////

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

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

error IDiamondCut__AddressMustBeZero();
error IDiamondCut__FunctionAlreadyExists();
error IDiamondCut__ImmutableFunction();
error IDiamondCut__IncorrectAction();
error IDiamondCut__InexistentFacetCode();
error IDiamondCut__InexistentFunction();
error IDiamondCut__InvalidAddressZero();
error IDiamondCut__InvalidReplacementWithSameFunction();
error IDiamondCut__NoSelectors();

error LDiamond__OnlyStorageOwner();

error LDiamond__InitializationFailed(
    address _initializationContractAddress,
    bytes _calldata
);

/// @title LDiamond
/// @author mektigboy
/// @dev Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
library LDiamond {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCutted(
        IDiamondCut.FacetCut[] _cut,
        address _init,
        bytes _calldata
    );

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

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
        address storageOwner;
    }

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

    /////////////////
    /// OWNERSHIP ///
    /////////////////

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();

        address oldOwner = ds.storageOwner;

        ds.storageOwner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    function contractOwner()
        internal
        view
        returns (address storageOwner_)
    {
        storageOwner_ = diamondStorage().storageOwner;
    }

    function enforceIsContractOwner() internal view {
        if (diamondStorage().storageOwner != msg.sender)
            revert LDiamond__OnlyStorageOwner();
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

        emit DiamondCutted(_cut, _init, _calldata);

        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length < 0) revert IDiamondCut__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facetAddress == address(0))
            revert IDiamondCut__InvalidAddressZero();

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

        if (_facetAddress == address(0))
            revert IDiamondCut__InvalidAddressZero();

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

        if (_facetAddress != address(0))
            revert IDiamondCut__AddressMustBeZero();

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
        if (_facetAddress == address(0))
            revert IDiamondCut__InexistentFunction();

        /// @notice An immutable function is defined directly in diamond
        if (_facetAddress == address(this))
            revert IDiamondCut__ImmutableFunction();

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