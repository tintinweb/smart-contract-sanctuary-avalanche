//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import "./UniqueStorage.sol";

contract VestingDiamond is UniqueStorage, IDiamondCut {
    constructor(address _token)
        UniqueStorage(
            keccak256(abi.encodePacked(_token, msg.sender, block.timestamp))
        )
    {
        LibVestingDiamond.setContractOwner(_storagePos, msg.sender);
        LibVestingDiamond.setVesting(_storagePos, _token);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibVestingDiamond.enforceIsContractOwner(_storagePos);
        LibVestingDiamond.diamondCut(
            _storagePos,
            _diamondCut,
            _init,
            _calldata
        );
    }

    // Get Storage Position As Bytes32
    function getStoragePosition() external view returns (bytes32 pos) {
        LibVestingDiamond.enforceIsContractOwner(_storagePos);
        return _storagePos;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibVestingDiamond.DiamondStorage storage ds;

        bytes32 position = _storagePos;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
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
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {LibVestingDiamond} from "./libraries/LibVestingDiamond.sol";

contract UniqueStorage {
    bytes32 internal _storagePos;

    constructor(bytes32 storagePos) {
        _storagePos = storagePos;
    }

    function getDiamondStorage()
        internal
        view
        returns (LibVestingDiamond.DiamondStorage storage)
    {
        return LibVestingDiamond.diamondStorage(_storagePos);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IDiamondCut.sol";

library LibVestingDiamond {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    // Schedule data structure
    struct ScheduleData {
        uint256 sId;
        uint256 startTp;
        uint256 cliff;
        uint256 duration;
        uint256 totalAmt;
        bytes32 merkleRoot;
        uint256 totalCount;
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract & project owner
        address contractOwner;
        // paused of the contract
        bool paused;
        // vesting token address
        address token;
        // maps the vesting ID to the initialized flag
        mapping(uint256 => bool) initializedMap;
        // maps the vesting ID to the schedule ID to the schedule data
        mapping(uint256 => mapping(uint256 => ScheduleData)) schedulesMap;
        // maps the vesting ID to the schedule ID to the revoked flag
        mapping(uint256 => mapping(uint256 => bool)) revokedMap;
        // maps the vesting ID to the schedule ID to the beneficiary to the releasedAmt
        mapping(uint256 => mapping(uint256 => mapping(address => uint256))) benClaimedMap;
        // maps the vesting ID to the account to the blocked flag
        mapping(uint256 => mapping(address => bool)) blockedMap;
        // maps the vesting ID to the schedule ID to the claimed amount
        mapping(uint256 => mapping(uint256 => uint256)) sClaimedMap;
        // maps the vesting ID to the total vesting amount
        mapping(uint256 => uint256) totalVestingAmtMap;
        // maps the vesting ID to the revoked amount
        mapping(uint256 => uint256) withdrawAmtMap;

        // TODO Please add new members from end of struct
    }

    // Vesting Schedule Slice Period : 1 month (30 days)
    // 30 * 24 * 3600 = 2,592,000
    uint256 internal constant VESTING_SLICE_PERIOD = 2592000;

    function diamondStorage(bytes32 position)
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(bytes32 storagePos, address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage(storagePos);
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner(bytes32 storagePos)
        internal
        view
        returns (address contractOwner_)
    {
        contractOwner_ = diamondStorage(storagePos).contractOwner;
    }

    function enforceIsContractOwner(bytes32 storagePos) internal view {
        require(
            msg.sender == diamondStorage(storagePos).contractOwner,
            "LibDiamond: NOT_OWNER"
        );
    }

    // The contract must be paused.
    function whenPaused(bytes32 storagePos) internal view {
        require(diamondStorage(storagePos).paused, "Pausable: not paused");
    }

    // The contract must not be paused.
    function whenNotPaused(bytes32 storagePos) internal view {
        require(!diamondStorage(storagePos).paused, "Pausable: paused");
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        bytes32 storagePos,
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    storagePos,
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    storagePos,
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    storagePos,
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamond: INCORRECT_ACTION");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        bytes32 storagePos,
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LibDiamond: NO_SELECTORS");
        DiamondStorage storage ds = diamondStorage(storagePos);
        require(_facetAddress != address(0), "LibDiamond: ZERO_FACET_ADDRESS");
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamond: FUNCTION_EXIST"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        bytes32 storagePos,
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LibDiamond: NO_SELECTORS");
        DiamondStorage storage ds = diamondStorage(storagePos);
        require(_facetAddress != address(0), "LibDiamond: ZERO_FACET_ADDRESS");
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamond: SAME_FUNCTION"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        bytes32 storagePos,
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LibDiamond: NO_SELECTORS");
        DiamondStorage storage ds = diamondStorage(storagePos);
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamond: ZERO_FACET_ADDRESS");
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
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
        enforceHasContractCode(_facetAddress, "LibDiamond: NO_CODE");
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
        require(_facetAddress != address(0), "LibDiamond: FUNCTION_NOT_EXIST");
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamond: IMMUTABLE_FUNCTION"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
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
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
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
            require(_calldata.length == 0, "LibDiamond: CALLDATA_NOT_EMPTY");
        } else {
            require(_calldata.length > 0, "LibDiamond: CALLDATA_EMPTY");
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamond: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamond: INIT_REVERTED");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function setVesting(bytes32 storagePos, address _token) internal {
        DiamondStorage storage ds = diamondStorage(storagePos);
        ds.token = _token;
    }
}