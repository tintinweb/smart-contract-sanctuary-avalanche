// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDiamondCut.sol";

error LDiamond__AddressMustBeZero();
error LDiamond__FunctionAlreadyExists();
error LDiamond__ImmutableFunction();
error LDiamond__IncorrectAction();
error LDiamond__InexistentFacetCode();
error LDiamond__InexistentFunction();
error LDiamond__InitializationFailed(address init, bytes data);
error LDiamond__InvalidAddressZero();
error LDiamond__InvalidReplacementWithSameFunction();
error LDiamond__NoSelectors();
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
        address indexed oldOwner,
        address indexed newOwner
    );

    ///////////////
    /// STORAGE ///
    ///////////////

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        /// @notice Address of the facet
        address facetAddress;
        /// @notice Position of the facet in `facetFunctionSelectors.functionSelectors` array
        uint96 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        /// @notice Selectors of functions
        bytes4[] functionSelectors;
        /// @notice Position of `facetAddress` in `facetAddresses` array
        uint256 facetAddressPosition;
    }

    struct DiamondStorage {
        /// @notice Position of selector in `facetFunctionSelectors.selectors` array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        /// @notice Addresses of the facets to selectors of the functions
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        /// @notice Facet addresses
        address[] facetAddresses;
        /// @notice Query if contract implements an interface
        mapping(bytes4 => bool) supportedInterfaces;
        /// @notice Owner of the contract
        address owner;
    }

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Set the storage of the diamond
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;

        /// @solidity memory-safe-assembly
        assembly {
            ds.slot := position
        }
    }

    /// @notice Update the owner of the diamond
    /// @param _owner New owner
    function updateContractOwner(address _owner) internal {
        DiamondStorage storage ds = diamondStorage();

        address oldOwner = ds.owner;

        ds.owner = _owner;

        emit OwnershipTransferred(oldOwner, _owner);
    }

    /// @notice Get the owner of the diamond
    function contractOwner() internal view returns (address owner_) {
        owner_ = diamondStorage().owner;
    }

    /// @notice Enforce is the owner of the diamond
    function enforceIsOwner() internal view {
        if (diamondStorage().owner != msg.sender) revert LDiamond__OnlyOwner();
    }

    /// @notice Perform a diamond cut
    /// @param _cut Diamond cut
    /// @param _init Address of the initialization contract
    /// @param _data Data
    function diamondCut(
        IDiamondCut.FacetCut[] memory _cut,
        address _init,
        bytes memory _data
    ) internal {
        for (uint256 facetIndex; facetIndex < _cut.length; ) {
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
                revert LDiamond__IncorrectAction();
            }
            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++facetIndex;
            }
        }

        emit DiamondCut(_cut, _init, _data);

        initializeDiamondCut(_init, _data);
    }

    /// @notice Add functions to the diamond
    /// @param _facet Address of the facet
    /// @param _selectors Selectors of the facet
    function addFunctions(address _facet, bytes4[] memory _selectors) internal {
        if (_selectors.length == 0) revert LDiamond__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facet == address(0)) revert LDiamond__InvalidAddressZero();

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facet].functionSelectors.length
        );

        /// @notice Add a new facet address if it does not exists already

        if (selectorPosition == 0) addFacet(ds, _facet);

        for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
            bytes4 selector = _selectors[selectorIndex];

            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress != address(0))
                revert LDiamond__FunctionAlreadyExists();

            addFunction(ds, selector, selectorPosition, _facet);

            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++selectorIndex;
                ++selectorPosition;
            }
        }
    }

    /// @notice Replace functions inside the diamond
    /// @param _facet Address of the facet
    /// @param _selectors Selectors of the facet
    function replaceFunctions(address _facet, bytes4[] memory _selectors)
        internal
    {
        if (_selectors.length == 0) revert LDiamond__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facet == address(0)) revert LDiamond__InvalidAddressZero();

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facet].functionSelectors.length
        );

        /// @notice Add a new facet address if it does not exists already

        if (selectorPosition == 0) addFacet(ds, _facet);

        for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
            bytes4 selector = _selectors[selectorIndex];

            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress == _facet)
                revert LDiamond__InvalidReplacementWithSameFunction();

            removeFunction(ds, oldFacetAddress, selector);
            
            addFunction(ds, selector, selectorPosition, _facet);

            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++selectorIndex;
                ++selectorPosition;
            }
        }
    }

    /// @notice Remove functions inside the diamond
    /// @param _facet Address of the facet
    /// @param _selectors Selectors of the facet
    function removeFunctions(address _facet, bytes4[] memory _selectors)
        internal
    {
        if (_selectors.length == 0) revert LDiamond__NoSelectors();

        DiamondStorage storage ds = diamondStorage();

        if (_facet != address(0)) revert LDiamond__AddressMustBeZero();

        for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
            bytes4 selector = _selectors[selectorIndex];

            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            removeFunction(ds, oldFacetAddress, selector);

            /// @notice Realistically impossible to overflow/underflow
            unchecked {
                ++selectorIndex;
            }

        }
    }

    /// @notice Add facet to the diamond
    /// @param ds DiamondStorage
    /// @param _facet Address of the diamond
    function addFacet(DiamondStorage storage ds, address _facet) internal {
        enforceHasContractCode(_facet);

        ds.facetFunctionSelectors[_facet].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facet);
    }

    /// @notice Add a function to the diamond
    /// @param ds DiamondStorage
    /// @param _selector Selector of the function
    /// @param _positon Position of the selector
    /// @param _facet Address of the function
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

    /// @notice Remove a function from the diamond
    /// @param ds DiamondStorage
    /// @param _facet Address of the facet
    /// @param _selector Selector of the function
    function removeFunction(
        DiamondStorage storage ds,
        address _facet,
        bytes4 _selector
    ) internal {
        if (_facet == address(0)) revert LDiamond__InexistentFunction();

        /// @notice An immutable function is defined directly inside the diamond
        if (_facet == address(this)) revert LDiamond__ImmutableFunction();

        /// @notice Replaces selector with the last selector, then deletes the last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facet]
            .functionSelectors
            .length - 1;

        /// @notice Replaces `_selector` with `lastSelector`, if not, they are not the same
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

        /// @notice Deletes the last selector

        ds.facetFunctionSelectors[_facet].functionSelectors.pop();

        delete ds.selectorToFacetAndPosition[_selector];

        /// @notice Deletes the facet address if there are no more selectors for the facet address
        if (lastSelectorPosition == 0) {
            /// @notice Replaces facet address with the last facet address, then deletes the last facet address
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

    /// @notice Initialize diamond cut
    /// @param _init Address of the initialization contract
    /// @param _data Data
    function initializeDiamondCut(address _init, bytes memory _data) internal {
        if (_init == address(0)) return;

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

    /// @notice Enforce contract has code
    /// @param _contract Address of the contract
    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;

        /// @solidity memory-safe-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }

        if (contractSize == 0) revert LDiamond__InexistentFacetCode();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDiamondCut
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @dev EIP-2535 "Diamond" standard
interface IDiamondCut {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCut(FacetCut[] cut, address init, bytes data);

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

    /////////////
    /// LOGIC ///
    /////////////

    function diamondCut(
        FacetCut[] calldata cut,
        address init,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC173
/// @author mektigboy
interface IERC173 {
    //////////////
    /// EVENTS ///
    //////////////

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    /////////////
    /// LOGIC ///
    /////////////

    function owner() external view returns (address owner);

    function transferOwnership(address owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/interfaces/IERC173.sol";
import "clouds/diamond/LDiamond.sol";

/// @title OwnershipFacet
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Facet in charge of administrating the ownership of the contract
/// @notice Utilizes 'IERC173' and 'LDiamond'
contract OwnershipFacet is IERC173 {
    /// @notice Get contract owner
    function owner() external view returns (address owner_) {
        owner_ = LDiamond.contractOwner();
    }

    /// @notice Transfer ownership
    /// @param _owner New owner
    function transferOwnership(address _owner) external {
        LDiamond.enforceIsOwner();
        LDiamond.updateContractOwner(_owner);
    }
}