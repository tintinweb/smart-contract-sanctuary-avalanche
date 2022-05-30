// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";

contract Diamond {    

    constructor(address _contractOwner, address _diamondCutFacet) payable {        
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet, 
            action: IDiamondCut.FacetCutAction.Add, 
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");        
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
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
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
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
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibStorage, WithStorage, TreasuryStorage, ManagementStorage, QueueStorage} from "../libraries/LibStorage.sol";

import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IManagement} from "../interfaces/IManagement.sol";
import {IREQ} from "../interfaces/IREQ.sol";
import {ICreditREQ} from "../interfaces/ICreditREQ.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract TreasuryInit is WithStorage {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(
        address _management,
        address _req,
        address _creq
    ) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        TreasuryStorage storage ts = LibStorage.treasuryStorage();
        require(_req != address(0), "Zero address: REQ");
        ts.REQ = IREQ(_req);
        ts.timelockEnabled = true;
        ts.timeNeededForQueue = 0;
        ts.useExcessReserves = false;
        ts.CREQ = ICreditREQ(_creq);

        QueueStorage storage qs = LibStorage.queueStorage();
        qs.currentIndex = 0;

        ManagementStorage storage ms = LibStorage.managementStorage();
        ms.governor = _management;
        ms.guardian = _management;
        ms.policy = _management;
        ms.vault = _management;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import "../interfaces/IREQ.sol";
import "../interfaces/ICreditREQ.sol";
import "./LibDiamond.sol";

// We do ot use an array of stucts to avoid pointer conflicts
// Mappings help us avoid out of bound issues as in arrays,
// particularly if another mapping is added to the struct
struct QueueStorage {
    uint256 currentIndex;
    mapping(uint256 => uint256) managing;
    mapping(uint256 => address) toPermit;
    mapping(uint256 => address) calculator;
    mapping(uint256 => uint256) timelockEnd;
    mapping(uint256 => bool) nullify;
    mapping(uint256 => bool) executed;
}


// Management storage that stores the different DAO roles
struct ManagementStorage {
    address governor;
    address guardian;
    address policy;
    address vault;
    address newGovernor;
    address newGuardian;
    address newPolicy;
    address newVault;
}

// The core Treasury store
struct TreasuryStorage {
    // requiem global assets
    IREQ REQ;
    ICreditREQ CREQ;
    // general registers
    mapping(uint256 => address[]) registry;
    mapping(uint256 => mapping(address => bool)) permissions;
    mapping(address => address) assetPricer;
    mapping(address => uint256) debtLimits;
    // asset data
    mapping(address => uint256) assetReserves;
    mapping(address => uint256) assetDebt;
    // aggregted data
    uint256 totalReserves;
    uint256 totalDebt;
    uint256 reqDebt;
    
    uint256 timeNeededForQueue;
    bool timelockEnabled;
    bool useExcessReserves;
    uint256 onChainGovernanceTimelock;
}

/**
 * All of Requiems's treasury storage is stored in a single TreasuryStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "requiem.treasury.storage")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.treasuryStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.treasuryStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant TREASURY_STORAGE = keccak256("requiem.storage.treasury");
    bytes32 constant QUEUE_STORAGE = keccak256("requiem.storage.queue");
    bytes32 constant MANAGEMENT_STORAGE = keccak256("requiem.storage.authority");

    function treasuryStorage() internal pure returns (TreasuryStorage storage ts) {
        bytes32 position = TREASURY_STORAGE;
        assembly {
            ts.slot := position
        }
    }

    function queueStorage() internal pure returns (QueueStorage storage qs) {
        bytes32 position = QUEUE_STORAGE;
        assembly {
            qs.slot := position
        }
    }

    function managementStorage() internal pure returns (ManagementStorage storage ms) {
        bytes32 position = MANAGEMENT_STORAGE;
        assembly {
            ms.slot := position
        }
    }

    // Authority access control
    function enforcePolicy() internal view {
        require(msg.sender == managementStorage().policy, "Treasury: Must be policy");
    }

    function enforceGovernor() internal view {
        require(msg.sender == managementStorage().governor, "Treasury: Must be governor");
    }

    function enforceGuardian() internal view {
        require(msg.sender == managementStorage().guardian, "Treasury: Must be guardian");
    }

    function enforceVault() internal view {
        require(msg.sender == managementStorage().guardian, "Treasury: Must be vault");
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.treasuryStorage()` to just `ts()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function ts() internal pure returns (TreasuryStorage storage) {
        return LibStorage.treasuryStorage();
    }

    function qs() internal pure returns (QueueStorage storage) {
        return LibStorage.queueStorage();
    }

    function ms() internal pure returns (ManagementStorage storage) {
        return LibStorage.managementStorage();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IManagement {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IREQ is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

interface ICreditREQ {
  function changeDebt(
    uint256 amount,
    address debtor,
    bool add
  ) external;

  function debtBalances(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../MockUpgrade/LibStorageV2.sol";
import "../../utils/SafeERC20.sol";

import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC20Metadata.sol";
import "../../interfaces/ICreditREQ.sol";
import "../../interfaces/IAssetPricer.sol";
import "../../interfaces/ITreasury.sol";

contract TreasuryFacetV2 is ITreasury, WithStorage {
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */
    event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdrawal(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed token, uint256 amount, uint256 value);
    event Managed(address indexed token, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(uint256 indexed status, address queued);
    event Permissioned(address addr, uint256 indexed status, bool result);

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidAsset = "Treasury: invalid asset";
    string internal insufficientReserves = "Treasury: insufficient reserves";

    // administrative
    modifier onlyGovernor() {
        LibStorage.enforceGovernor();
        _;
    }

    modifier onlyPolicy() {
        LibStorage.enforcePolicy();
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice allow approved address to deposit an asset for ts().REQ
     * @param _amount uint256
     * @param _token address
     * @param _profit uint256
     * @return send_ uint256
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external override returns (uint256 send_) {
        if (ts().permissions[1][_token]) {
            require(ts().permissions[0][msg.sender], notApproved);
        } else {
            revert(invalidAsset);
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 value = assetValue(_token, _amount);
        // mint needed and store amount of rewards for distribution
        send_ = value - _profit;
        ts().REQ.mint(msg.sender, send_);

        ts().totalReserves += value;

        emit Deposit(_token, _amount, value);
    }

    /**
     * @notice allow approved address to burn REQ for reserves
     * @param _amount uint256
     * @param _asset address
     */
    function withdraw(uint256 _amount, address _asset) external override {
        require(ts().permissions[1][_asset], notAccepted); // Only reserves can be used for redemptions
        require(ts().permissions[2][msg.sender], notApproved);

        uint256 value = assetValue(_asset, _amount);
        ts().REQ.burnFrom(msg.sender, value);

        ts().totalReserves -= value;

        IERC20(_asset).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_asset, _amount, value);
    }

    /**
     * @notice allow approved address to withdraw assets
     * @param _asset address
     * @param _amount uint256
     */
    function manage(address _asset, uint256 _amount) external override {
        require(ts().permissions[2][msg.sender], notApproved);

        if (ts().permissions[1][_asset]) {
            uint256 value = assetValue(_asset, _amount);
            if (ts().useExcessReserves) require(int256(value) <= excessReserves(), insufficientReserves);

            ts().totalReserves -= value;
        }
        IERC20(_asset).safeTransfer(msg.sender, _amount);
        emit Managed(_asset, _amount);
    }

    /**
     * @notice mint new ts().REQ using excess reserves
     * @param _recipient address
     * @param _amount uint256
     */
    function mint(address _recipient, uint256 _amount) external override {
        require(ts().permissions[3][msg.sender], notApproved);
        if (ts().useExcessReserves) require(int256(_amount) <= excessReserves(), insufficientReserves);

        ts().REQ.mint(_recipient, _amount);
        emit Minted(msg.sender, _recipient, _amount);
    }

    /**
     * DEBT: The debt functions allow approved addresses to borrow treasury assets
     * or ts().REQ from the treasury, using sts().REQ as collateral. This might allow an
     * sts().REQ holder to provide ts().REQ liquidity without taking on the opportunity cost
     * of unstaking, or alter their backing without imposing risk onto the treasury.
     * Many of these use cases are yet to be defined, but they appear promising.
     * However, we urge the community to think critically and move slowly upon
     * proposals to acquire these ts().permissions.
     */

    /**
     * @notice allow approved address to borrow reserves
     * @param _amount uint256
     * @param _token address
     */
    function incurDebt(uint256 _amount, address _token) external override {
        uint256 value;
        require(ts().permissions[5][msg.sender], notApproved);

        if (_token == address(ts().REQ)) {
            value = _amount;
        } else {
            value = assetValue(_token, _amount);
        }
        require(value != 0, invalidAsset);

        ts().CREQ.changeDebt(value, msg.sender, true);
        require(ts().CREQ.debtBalances(msg.sender) <= ts().debtLimits[msg.sender], "Treasury: exceeds limit");
        ts().totalDebt += value;

        if (_token == address(ts().REQ)) {
            ts().REQ.mint(msg.sender, value);
            ts().reqDebt += value;
        } else {
            ts().totalReserves -= value;
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit CreateDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with reserves
     * @param _amount uint256
     * @param _token address
     */
    function repayDebtWithReserve(uint256 _amount, address _token) external override {
        require(ts().permissions[5][msg.sender], notApproved);
        require(ts().permissions[1][_token], notAccepted);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 value = assetValue(_token, _amount);
        ts().CREQ.changeDebt(value, msg.sender, false);
        ts().totalDebt -= value;
        ts().totalReserves += value;
        emit RepayDebt(msg.sender, _token, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with REQ
     * @param _amount uint256
     */
    function repayDebtWithREQ(uint256 _amount) external {
        require(ts().permissions[5][msg.sender], notApproved);
        ts().REQ.burnFrom(msg.sender, _amount);
        ts().CREQ.changeDebt(_amount, msg.sender, false);
        ts().totalDebt -= _amount;
        ts().reqDebt -= _amount;
        emit RepayDebt(msg.sender, address(ts().REQ), _amount, _amount);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice takes inventory of all tracked assets
     * @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyGovernor {
        uint256 reserves;
        address[] memory assets = ts().registry[1];
        for (uint256 i = 0; i < assets.length; i++) {
            if (ts().permissions[1][assets[i]]) {
                reserves += assetValue(assets[i], IERC20(assets[i]).balanceOf(address(this)));
            }
        }
        ts().totalReserves = reserves;
        emit ReservesAudited(reserves);
    }

    /**
     * @notice set max debt for address
     * @param _address address
     * @param _limit uint256
     */
    function setDebtLimit(address _address, uint256 _limit) external onlyGovernor {
        ts().debtLimits[_address] = _limit;
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function enable(
        uint256 _status,
        address _address,
        address _calculator
    ) external {
        require(ts().timelockEnabled == false, "Use queueTimelock");
        if (_status == 7) {
            ts().CREQ = ICreditREQ(_address);
        } else {
            ts().permissions[_status][_address] = true;

            if (_status == 1) {
                ts().assetPricer[_address] = _calculator;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                ts().registry[_status].push(_address);

                if (_status == 1) {
                    (bool reg, uint256 index) = indexInRegistry(_address, _status);
                    if (reg) {
                        delete ts().registry[_status][index];
                    }
                }
            }
        }
        emit Permissioned(_address, _status, true);
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable(uint256 _status, address _toDisable) external {
        require(msg.sender == ms().governor || msg.sender == ms().guardian, "Only governor or guardian");
        ts().permissions[_status][_toDisable] = false;
        emit Permissioned(_toDisable, _status, false);
    }

    /**
     * @notice check if ts().registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, uint256 _status) public view returns (bool, uint256) {
        address[] memory entries = ts().registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @notice changes the use of excess reserves for minting
     */
    function setUseExcessReserves() external {
        ts().useExcessReserves = !ts().useExcessReserves;
    }

    /* ========== TIMELOCKED FUNCTIONS ========== */

    // functions are used prior to enabling on-chain governance

    /**
     * @notice queue address to receive permission
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function queueTimelock(
        uint256 _status,
        address _address,
        address _calculator
    ) external onlyGovernor {
        require(_address != address(0));
        require(ts().timelockEnabled == true, "Timelock is disabled, use enable");

        uint256 timelock = block.number + ts().blocksNeededForQueue;
        if (_status == 2) {
            timelock = block.number + ts().blocksNeededForQueue * 2;
        }
        ts().permissionQueue.push(
            Queue({managing: _status, toPermit: _address, calculator: _calculator, timelockEnd: timelock, nullify: false, executed: false})
        );
        emit PermissionQueued(_status, _address);
    }

    /**
     *  @notice enable queued permission
     *  @param _index uint256
     */
    function execute(uint256 _index) external {
        require(ts().timelockEnabled == true, "Timelock is disabled, use enable");

        Queue memory info = ts().permissionQueue[_index];

        require(!info.nullify, "Action has been nullified");
        require(!info.executed, "Action has already been executed");
        require(block.number >= info.timelockEnd, "Timelock not complete");

        if (info.managing == 7) {
            // 9
            ts().CREQ = ICreditREQ(info.toPermit);
        } else {
            ts().permissions[info.managing][info.toPermit] = true;

            if (info.managing == 1) {
                ts().assetPricer[info.toPermit] = info.calculator;
            }
            (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
            if (!registered) {
                ts().registry[info.managing].push(info.toPermit);

                if (info.managing == 1) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, 1);
                    if (reg) {
                        delete ts().registry[1][index];
                    }
                }
            }
        }
        ts().permissionQueue[_index].executed = true;
        emit Permissioned(info.toPermit, info.managing, true);
    }

    /**
     * @notice cancel timelocked action
     * @param _index uint256
     */
    function nullify(uint256 _index) external onlyGovernor {
        ts().permissionQueue[_index].nullify = true;
    }

    /**
     * @notice disables timelocked functions
     */
    function disableTimelock() external onlyGovernor {
        require(ts().timelockEnabled == true, "timelock already disabled");
        if (ts().onChainGovernanceTimelock != 0 && ts().onChainGovernanceTimelock <= block.number) {
            ts().timelockEnabled = false;
        } else {
            ts().onChainGovernanceTimelock = block.number + ts().blocksNeededForQueue * 7; // 7-day timelock
        }
    }

    /**
     * @notice enables timelocks after initilization
     */
    function enableTimelock(uint256 _blocksNeededForQueue) external onlyGovernor {
        require(!ts().timelockEnabled, "timelock already enabled");
        ts().timelockEnabled = true;
        ts().blocksNeededForQueue = _blocksNeededForQueue;
    }
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns excess reserves not backing tokens
     * @return int
     */
    function excessReserves() public view returns (int256) {
        return int256(ts().totalReserves) - int256(ts().REQ.totalSupply() - ts().totalDebt);
    }

    /**
     * @notice returns REQ valuation of asset
     * @param _token address
     * @param _amount uint256
     * @return value_ uint256
     */
    function assetValue(address _token, uint256 _amount) public view override returns (uint256 value_) {
        if (ts().permissions[1][_token]) {
            value_ = IAssetPricer(ts().assetPricer[_token]).valuation(_token, _amount);
        } else {
            revert(invalidAsset);
        }
    }

    /**
     * @notice returns supply metric that cannot be manipulated by debt
     * @dev use this any time you need to query supply
     * @return uint256
     */
    function baseSupply() external view override returns (uint256) {
        return ts().REQ.totalSupply() - ts().reqDebt;
    }

    // VIEWS FROM STORAGE

    function assetPricer(address _entry) external view returns (address) {
        return ts().assetPricer[_entry];
    }

    function registry(uint256 _status, uint256 _entry) external view returns (address) {
        return ts().registry[_status][_entry];
    }

    function permissions(uint256 _status, address _entry) external view returns (bool) {
        return ts().permissions[_status][_entry];
    }

    function debtLimits(address _asset) public view returns (uint256) {
        return ts().debtLimits[_asset];
    }

    function assetReserves(address _asset) public view returns (uint256) {
        return ts().assetReserves[_asset];
    }

    function totalReserves() public view returns (uint256) {
        return ts().totalReserves;
    }

    function totalDebt() public view returns (uint256) {
        return ts().totalDebt;
    }

    function permissionQueue(uint256 _index) public view returns (Queue memory) {
        return ts().permissionQueue[_index];
    }

    function timelockEnabled() public view returns (bool) {
        return ts().timelockEnabled;
    }

    function useExcessReserves() public view returns (bool) {
        return ts().useExcessReserves;
    }

    function onChainGovernanceTimelock() public view returns (uint256) {
        return ts().onChainGovernanceTimelock;
    }

    function REQ() public view returns (IREQ) {
        return ts().REQ;
    }

    function CCREQ() public view returns (ICreditREQ) {
        return ts().CREQ;
    }

    function newFunction() public pure returns (uint256) {
        return 7;
    }

    function setNewValue(uint256 _newVal) public {
        ns().addedValue = _newVal;
    }

    function newValue() public view returns (uint256) {
        return ns().addedValue;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../../interfaces/IREQ.sol";
import "../../interfaces/ICreditREQ.sol";
import "../../libraries/LibDiamond.sol";

// enum here jsut for reference - uint256 used for upgradability
// enum STATUS {
//     ASSETDEPOSITOR, =0
//     ASSET, = 1
//     ASSETMANAGER, = 2
//     REWARDMANAGER, = 3
//     DEBTMANAGER, = 4
//     DEBTOR, = 5
//     COLLATERAL, = 6
//     CREQ = 7
// }

struct Queue {
    // STATUS managing;
    uint256 managing;
    address toPermit;
    address calculator;
    uint256 timelockEnd;
    bool nullify;
    bool executed;
}

struct ManagementStorage {
    address governor;
    address guardian;
    address policy;
    address vault;
    address newGovernor;
    address newGuardian;
    address newPolicy;
    address newVault;
}

struct TreasuryStorageV2 {
    // requiem global assets
    IREQ REQ;
    ICreditREQ CREQ;
    // general registers
    mapping(uint256 => address[]) registry;
    mapping(uint256 => mapping(address => bool)) permissions;
    mapping(address => address) assetPricer;
    mapping(address => uint256) debtLimits;
    // asset data
    mapping(address => uint256) assetReserves;
    mapping(address => uint256) assetDebt;
    // aggregted data
    uint256 totalReserves;
    uint256 totalDebt;
    uint256 reqDebt;
    Queue[] permissionQueue;
    uint256 blocksNeededForQueue;
    bool timelockEnabled;
    bool useExcessReserves;
    uint256 onChainGovernanceTimelock;
    uint256 testField;
}

struct NewStorage {
    uint256 addedValue;
}

/**
 * All of Requiems's treasury storage is stored in a single TreasuryStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "requiem.treasury.storage")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.treasuryStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.treasuryStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant TREASURY_STORAGE = keccak256("requiem.storage.treasury");
    bytes32 constant MANAGEMENT_STORAGE = keccak256("requiem.storage.authority");

    function treasuryStorage() internal pure returns (TreasuryStorageV2 storage ts) {
        bytes32 position = TREASURY_STORAGE;
        assembly {
            ts.slot := position
        }
    }

    function managementStorage() internal pure returns (ManagementStorage storage ms) {
        bytes32 position = MANAGEMENT_STORAGE;
        assembly {
            ms.slot := position
        }
    }
    // Authority access control
    function enforcePolicy() internal view {
        require(msg.sender == managementStorage().policy, "Treasury: Must be policy");
    }

    function enforceGovernor() internal view {
        require(msg.sender == managementStorage().governor, "Treasury: Must be governor");
    }

    function enforceGuardian() internal view {
        require(msg.sender == managementStorage().guardian, "Treasury: Must be guardian");
    }

    function enforceVault() internal view {
        require(msg.sender == managementStorage().guardian, "Treasury: Must be vault");
    }
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant ADDED_STORAGE = keccak256("requiem.storage.added");

    function newStorage() internal pure returns (NewStorage storage ns) {
        bytes32 position = ADDED_STORAGE;
        assembly {
            ns.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.gameStorage()` to just `gs()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function ts() internal pure returns (TreasuryStorageV2 storage) {
        return LibStorage.treasuryStorage();
    }

    function ms() internal pure returns (ManagementStorage storage) {
        return LibStorage.managementStorage();
    }

    // extended storage
    function ns() internal pure returns (NewStorage storage) {
        return LibStorage.newStorage();
    }
}

// SPDX-License-Identifier: MIT

// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.8.14;

import "../interfaces/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   *
   * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    (bool success, bytes memory returndata) = token.call(data);

    // If the low-level call didn't succeed we return whatever was returned from it.
    assembly {
      if eq(success, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
    require(
      returndata.length == 0 || abi.decode(returndata, (bool)),
      "SAFE_ERC20_CALL_FAILED"
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IAssetPricer {
  function valuation(address _asset, uint256 _amount)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function assetValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (int256);

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "../interfaces/ITreasury.sol";
import "../interfaces/IERC20.sol";

contract MockDepo {
    ITreasury treasury;

    constructor(address _treasury) {
        treasury = ITreasury(_treasury);
    }

    function depositForREQ(address _asset, uint256 _amount) public {
        treasury.deposit(_amount, _asset, 10);
    }

    function mintREQFor(address _asset, uint256 _amount) public {
        uint256 _vl = treasury.assetValue(_asset, _amount);
        IERC20(_asset).transferFrom(msg.sender, address(treasury), _amount);
        treasury.mint(msg.sender, _vl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../interfaces/IERC20.sol";
import "../interfaces/IAssetPricer.sol";

contract MockAssetPricer is IAssetPricer {
    IERC20 public REQ;

    uint256 scalar;

    constructor(address _req, uint256 _scalar) {
        require(_req != address(0), "Cannot be 0 address");
        REQ = IERC20(_req);
        scalar = _scalar;
    }

    function valuation(address _asset, uint256 _amount) external view override returns (uint256) {
        return (scalar * _amount * 10**(REQ.decimals() - IERC20(_asset).decimals())) / 1e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../libraries/LibStorage.sol";
import "../utils/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/ICreditREQ.sol";
import "../interfaces/IAssetPricer.sol";
import "../interfaces/ITreasury.sol";

// the managing / status input is coded as follows:
// enum STATUS {
//     ASSETDEPOSITOR, = 0
//     ASSET, = 1
//     ASSETMANAGER, = 2
//     REWARDMANAGER, = 3
//     DEBTMANAGER, = 4
//     DEBTOR, = 5
//     COLLATERAL, = 6
//     CREQ = 7
// }

// Local Queue struct outside of LibStorage to keep upgradeability
// The managing field uses the indexing according to the commented enum above
// We use uint256 as enums are not upgradeable.
struct Queue {
    uint256 managing;
    address toPermit;
    address calculator;
    uint256 timelockEnd;
    bool nullify;
    bool executed;
}

// Helper library to enable upgradeable queuing
// It just uses the current state of the queue storage and parses it to
// the Queue struct above - which avoids using arrays or mappings of structs
// Gas cost is not too important here as these are only used in rare cases
library QueueStorageLib {
    function push(QueueStorage storage self, Queue memory newEntry) internal {
        uint256 newIndex = self.currentIndex + 1;
        self.currentIndex = newIndex;
        self.managing[newIndex] = newEntry.managing;
        self.toPermit[newIndex] = newEntry.toPermit;
        self.calculator[newIndex] = newEntry.calculator;
        self.timelockEnd[newIndex] = newEntry.timelockEnd;
        self.nullify[newIndex] = newEntry.nullify;
        self.executed[newIndex] = newEntry.executed;
    }

    function get(QueueStorage storage self, uint256 _index) internal view returns (Queue memory) {
        require(_index <= self.currentIndex && _index > 0, "Queue: Invalid index");
        return
            Queue(
                self.managing[_index],
                self.toPermit[_index],
                self.calculator[_index],
                self.timelockEnd[_index],
                self.nullify[_index],
                self.executed[_index]
            );
    }
}

// The treasury facet that contains the logic that changes the storage
// Aligned with EIP-2535, the contract has no constructor or an own state
contract TreasuryFacet is ITreasury, WithStorage {
    using SafeERC20 for IERC20;
    using QueueStorageLib for QueueStorage;

    /* ========== EVENTS ========== */
    event Deposit(address indexed asset, uint256 amount, uint256 value);
    event Withdrawal(address indexed asset, uint256 amount, uint256 value);
    event CreateDebt(address indexed debtor, address indexed asset, uint256 amount, uint256 value);
    event RepayDebt(address indexed debtor, address indexed asset, uint256 amount, uint256 value);
    event Managed(address indexed asset, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(uint256 indexed status, address queued);
    event Permissioned(address addr, uint256 indexed status, bool result);

    // administrative
    modifier onlyGovernor() {
        LibStorage.enforceGovernor();
        _;
    }

    modifier onlyPolicy() {
        LibStorage.enforcePolicy();
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice allow approved address to deposit an asset for ts().REQ
     * @param _amount uint256
     * @param _asset address
     * @param _profit uint256
     * @return send_ uint256
     */
    function deposit(
        uint256 _amount,
        address _asset,
        uint256 _profit
    ) external override returns (uint256 send_) {
        if (ts().permissions[1][_asset]) {
            require(ts().permissions[0][msg.sender], "Treasury: not approved");
        } else {
            revert("Treasury: invalid asset");
        }

        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 value = assetValue(_asset, _amount);
        // mint needed and store amount of rewards for distribution
        send_ = value - _profit;
        ts().REQ.mint(msg.sender, send_);

        ts().totalReserves += value;

        emit Deposit(_asset, _amount, value);
    }

    /**
     * @notice allow approved address to burn REQ for reserves
     * @param _amount uint256
     * @param _asset address
     */
    function withdraw(uint256 _amount, address _asset) external override {
        require(ts().permissions[1][_asset], "Treasury: not accepted");
        require(ts().permissions[2][msg.sender], "Treasury: not approved");

        uint256 value = assetValue(_asset, _amount);
        ts().REQ.burnFrom(msg.sender, value);

        ts().totalReserves -= value;

        IERC20(_asset).safeTransfer(msg.sender, _amount);

        emit Withdrawal(_asset, _amount, value);
    }

    /**
     * @notice allow approved address to withdraw assets
     * @param _asset address
     * @param _amount uint256
     */
    function manage(address _asset, uint256 _amount) external override {
        require(ts().permissions[2][msg.sender], "Treasury: not approved");

        if (ts().permissions[1][_asset]) {
            uint256 value = assetValue(_asset, _amount);
            if (ts().useExcessReserves) require(int256(value) <= excessReserves(), "Treasury: insufficient reserves");

            ts().totalReserves -= value;
        }
        IERC20(_asset).safeTransfer(msg.sender, _amount);
        emit Managed(_asset, _amount);
    }

    /**
     * @notice mint new ts().REQ using excess reserves
     * @param _recipient address
     * @param _amount uint256
     */
    function mint(address _recipient, uint256 _amount) external override {
        require(ts().permissions[3][msg.sender], "Treasury: not approved");
        if (ts().useExcessReserves) require(int256(_amount) <= excessReserves(), "Treasury: insufficient reserves");

        ts().REQ.mint(_recipient, _amount);
        emit Minted(msg.sender, _recipient, _amount);
    }

    /**
     * DEBT: The debt functions allow approved addresses to borrow treasury assets
     * or REQ from the treasury, using CREQ as collateral. This might allow an
     * CREQ holder to provide REQ liquidity without taking on the opportunity cost
     * of unstaking, or alter their backing without imposing risk onto the treasury.
     * Many of these use cases are yet to be defined, but they appear promising.
     * However, we urge the community to think critically and move slowly upon
     * proposals to acquire these permissions.
     */

    /**
     * @notice allow approved address to borrow reserves
     * @param _amount uint256
     * @param _asset address
     */
    function incurDebt(uint256 _amount, address _asset) external override {
        uint256 value;
        require(ts().permissions[5][msg.sender], "Treasury: not approved");

        if (_asset == address(ts().REQ)) {
            value = _amount;
        } else {
            value = assetValue(_asset, _amount);
        }
        require(value != 0, "Treasury: invalid asset");

        ts().CREQ.changeDebt(value, msg.sender, true);
        require(ts().CREQ.debtBalances(msg.sender) <= ts().debtLimits[msg.sender], "Treasury: exceeds limit");
        ts().totalDebt += value;

        if (_asset == address(ts().REQ)) {
            ts().REQ.mint(msg.sender, value);
            ts().reqDebt += value;
        } else {
            ts().totalReserves -= value;
            IERC20(_asset).safeTransfer(msg.sender, _amount);
        }
        emit CreateDebt(msg.sender, _asset, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with reserves
     * @param _amount uint256
     * @param _asset address
     */
    function repayDebtWithReserve(uint256 _amount, address _asset) external override {
        require(ts().permissions[5][msg.sender], "Treasury: not approved");
        require(ts().permissions[1][_asset], "Treasury: not accepted");
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 value = assetValue(_asset, _amount);
        ts().CREQ.changeDebt(value, msg.sender, false);
        ts().totalDebt -= value;
        ts().totalReserves += value;
        emit RepayDebt(msg.sender, _asset, _amount, value);
    }

    /**
     * @notice allow approved address to repay borrowed reserves with REQ
     * @param _amount uint256
     */
    function repayDebtWithREQ(uint256 _amount) external {
        require(ts().permissions[5][msg.sender], "Treasury: not approved");
        ts().REQ.burnFrom(msg.sender, _amount);
        ts().CREQ.changeDebt(_amount, msg.sender, false);
        ts().totalDebt -= _amount;
        ts().reqDebt -= _amount;
        emit RepayDebt(msg.sender, address(ts().REQ), _amount, _amount);
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice takes inventory of all tracked assets
     * @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyGovernor {
        uint256 reserves;
        address[] memory assets = ts().registry[1];
        for (uint256 i = 0; i < assets.length; i++) {
            if (ts().permissions[1][assets[i]]) {
                reserves += assetValue(assets[i], IERC20(assets[i]).balanceOf(address(this)));
            }
        }
        ts().totalReserves = reserves;
        emit ReservesAudited(reserves);
    }

    /**
     * @notice set max debt for address
     * @param _address address
     * @param _limit uint256
     */
    function setDebtLimit(address _address, uint256 _limit) external onlyGovernor {
        ts().debtLimits[_address] = _limit;
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function enable(
        uint256 _status,
        address _address,
        address _calculator
    ) external {
        require(!ts().timelockEnabled, "Use queueTimelock");
        if (_status == 7) {
            ts().CREQ = ICreditREQ(_address);
        } else {
            ts().permissions[_status][_address] = true;

            if (_status == 1) {
                ts().assetPricer[_address] = _calculator;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                ts().registry[_status].push(_address);

                if (_status == 1) {
                    (bool reg, uint256 index) = indexInRegistry(_address, _status);
                    if (reg) {
                        delete ts().registry[_status][index];
                    }
                }
            }
        }
        emit Permissioned(_address, _status, true);
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable(uint256 _status, address _toDisable) external {
        require(msg.sender == ms().governor || msg.sender == ms().guardian, "Only governor or guardian");
        ts().permissions[_status][_toDisable] = false;
        emit Permissioned(_toDisable, _status, false);
    }

    /**
     * @notice check if ts().registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, uint256 _status) public view returns (bool, uint256) {
        address[] memory entries = ts().registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /**
     * @notice changes the use of excess reserves for minting
     */
    function setUseExcessReserves() external {
        ts().useExcessReserves = !ts().useExcessReserves;
    }

    /* ========== TIMELOCKED FUNCTIONS ========== */

    // functions are used prior to enabling on-chain governance

    /**
     * @notice queue address to receive permission
     * @param _status STATUS
     * @param _address address
     * @param _calculator address
     */
    function queueTimelock(
        uint256 _status,
        address _address,
        address _calculator
    ) external onlyGovernor {
        require(_address != address(0));
        require(ts().timelockEnabled, "Timelock is disabled, use enable");
        uint256 timelock = block.timestamp + ts().timeNeededForQueue;
        if (_status == 2) {
            timelock = block.timestamp + ts().timeNeededForQueue * 2;
        }
        qs().push(Queue({managing: _status, toPermit: _address, calculator: _calculator, timelockEnd: timelock, nullify: false, executed: false}));
        emit PermissionQueued(_status, _address);
    }

    /**
     *  @notice enable queued permission
     *  @param _index uint256
     */
    function execute(uint256 _index) external {
        require(ts().timelockEnabled == true, "Timelock is disabled, use enable");

        Queue memory info = qs().get(_index);

        require(!info.nullify, "Action has been nullified");
        require(!info.executed, "Action has already been executed");
        require(block.timestamp >= info.timelockEnd, "Timelock not complete");

        if (info.managing == 7) {
            ts().CREQ = ICreditREQ(info.toPermit);
        } else {
            ts().permissions[info.managing][info.toPermit] = true;

            if (info.managing == 1) {
                ts().assetPricer[info.toPermit] = info.calculator;
            }
            (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
            if (!registered) {
                ts().registry[info.managing].push(info.toPermit);

                if (info.managing == 1) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, 1);
                    if (reg) {
                        delete ts().registry[1][index];
                    }
                }
            }
        }
        qs().executed[_index] = true;
        emit Permissioned(info.toPermit, info.managing, true);
    }

    /**
     * @notice cancel timelocked action
     * @param _index uint256
     */
    function nullify(uint256 _index) external onlyGovernor {
        qs().nullify[_index] = true;
    }

    /**
     * @notice disables timelocked functions
     */
    function disableTimelock() external onlyGovernor {
        require(ts().timelockEnabled, "timelock already disabled");
        if (ts().onChainGovernanceTimelock != 0 && ts().onChainGovernanceTimelock <= block.timestamp) {
            ts().timelockEnabled = false;
        } else {
            ts().onChainGovernanceTimelock = block.timestamp + ts().timeNeededForQueue * 7; // 7-day timelock
        }
    }

    /**
     * @notice enables timelocks after initilization
     */
    function enableTimelock(uint256 _timeNeededForQueue) external onlyGovernor {
        require(!ts().timelockEnabled, "timelock already enabled");
        ts().timelockEnabled = true;
        ts().timeNeededForQueue = _timeNeededForQueue;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns excess reserves not backing assets
     * @return int
     */
    function excessReserves() public view returns (int256) {
        return int256(ts().totalReserves) - int256(ts().REQ.totalSupply() - ts().totalDebt);
    }

    /**
     * @notice returns REQ valuation of asset
     * @param _asset address
     * @param _amount uint256
     * @return value_ uint256
     */
    function assetValue(address _asset, uint256 _amount) public view override returns (uint256 value_) {
        if (ts().permissions[1][_asset]) {
            value_ = IAssetPricer(ts().assetPricer[_asset]).valuation(_asset, _amount);
        } else {
            revert("Treasury: invalid asset");
        }
    }

    /**
     * @notice returns supply metric that cannot be manipulated by debt
     * @dev use this any time you need to query supply
     * @return uint256
     */
    function baseSupply() external view override returns (uint256) {
        return ts().REQ.totalSupply() - ts().reqDebt;
    }

    // VIEWS FROM STORAGE

    function assetPricer(address _entry) external view returns (address) {
        return ts().assetPricer[_entry];
    }

    function registry(uint256 _status, uint256 _entry) external view returns (address) {
        return ts().registry[_status][_entry];
    }

    function permissions(uint256 _status, address _entry) external view returns (bool) {
        return ts().permissions[_status][_entry];
    }

    function debtLimits(address _asset) public view returns (uint256) {
        return ts().debtLimits[_asset];
    }

    function assetReserves(address _asset) public view returns (uint256) {
        return ts().assetReserves[_asset];
    }

    function totalReserves() public view returns (uint256) {
        return ts().totalReserves;
    }

    function totalDebt() public view returns (uint256) {
        return ts().totalDebt;
    }

    function permissionQueue(uint256 _index) public view returns (Queue memory) {
        return qs().get(_index);
    }

    function timelockEnabled() public view returns (bool) {
        return ts().timelockEnabled;
    }

    function useExcessReserves() public view returns (bool) {
        return ts().useExcessReserves;
    }

    function onChainGovernanceTimelock() public view returns (uint256) {
        return ts().onChainGovernanceTimelock;
    }

    function REQ() public view returns (IREQ) {
        return ts().REQ;
    }

    function CCREQ() public view returns (ICreditREQ) {
        return ts().CREQ;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {    

    // You can add parameters to this function in order to pass in 
    // data to set your own state variables
    function init() external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from  "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external override view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC20.sol";
import "../interfaces/IREQ.sol";

contract MockREQ is ERC20, IREQ {
    constructor() ERC20("Requiem", "REQ", 18) {}

    function mint(address to, uint256 value) external override {
        _mint(to, value);
    }

    function burn(uint256 value) external override {
        _burn(_msgSender(), value);
    }

    function burnFrom(address account, uint256 amount) external override {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Context.sol";
import "../interfaces/IERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20, Context {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IManagement.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {WithStorage} from "../libraries/LibStorage.sol";
import {AccessControlled} from "../types/AccessControlled.sol";

contract ManagementFacet is IManagement, AccessControlled, WithStorage {
    /* ========== GOV ONLY ========== */

    function pushGovernor(address _newGovernor, bool _effectiveImmediately) external onlyGovernor {
        if (_effectiveImmediately) ms().governor = _newGovernor;
        ms().newGovernor = _newGovernor;
        emit GovernorPushed(ms().governor, ms().newGovernor, _effectiveImmediately);
    }

    function pushGuardian(address _newGuardian, bool _effectiveImmediately) external onlyGovernor {
        if (_effectiveImmediately) ms().guardian = _newGuardian;
        ms().newGuardian = _newGuardian;
        emit GuardianPushed(ms().guardian, ms().newGuardian, _effectiveImmediately);
    }

    function pushPolicy(address _newPolicy, bool _effectiveImmediately) external onlyGovernor {
        if (_effectiveImmediately) ms().policy = _newPolicy;
        ms().newPolicy = _newPolicy;
        emit PolicyPushed(ms().policy, ms().newPolicy, _effectiveImmediately);
    }

    function pushVault(address _newVault, bool _effectiveImmediately) external onlyGovernor {
        if (_effectiveImmediately) ms().vault = _newVault;
        ms().newVault = _newVault;
        emit VaultPushed(ms().vault, ms().newVault, _effectiveImmediately);
    }

    /* ========== PENDING ROLE ONLY ========== */

    function pullGovernor() external {
        require(msg.sender == ms().newGovernor, "!newGovernor");
        emit GovernorPulled(ms().governor, ms().newGovernor);
        ms().governor = ms().newGovernor;
    }

    function pullGuardian() external {
        require(msg.sender == ms().newGuardian, "!newGuard");
        emit GuardianPulled(ms().guardian, ms().newGuardian);
        ms().guardian = ms().newGuardian;
    }

    function pullPolicy() external {
        require(msg.sender == ms().newPolicy, "!newPolicy");
        emit PolicyPulled(ms().policy, ms().newPolicy);
        ms().policy = ms().newPolicy;
    }

    function pullVault() external {
        require(msg.sender == ms().newVault, "!newVault");
        emit VaultPulled(ms().vault, ms().newVault);
        ms().vault = ms().newVault;
    }

    /* ========== VIEWS ========== */

    function governor() external view returns (address) {
        return ms().governor;
    }

    function guardian() external view returns (address) {
        return ms().guardian;
    }

    function policy() external view returns (address) {
        return ms().policy;
    }

    function vault() external view returns (address) {
        return ms().vault;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.5;

import "../interfaces/IManagement.sol";

abstract contract AccessControlled {
  /* ========== EVENTS ========== */

  event ManagementUpdated(IManagement indexed management);

  string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

  /* ========== STATE VARIABLES ========== */

  IManagement public management;

  /* ========== Constructor ========== */

  function intitalizeManagement(IManagement _management) internal {
    management = _management;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernor() {
    require(msg.sender == management.governor(), UNAUTHORIZED);
    _;
  }

  modifier onlyGuardian() {
    require(msg.sender == management.guardian(), UNAUTHORIZED);
    _;
  }

  modifier onlyPolicy() {
    require(msg.sender == management.policy(), UNAUTHORIZED);
    _;
  }

  modifier onlyVault() {
    require(msg.sender == management.vault(), UNAUTHORIZED);
    _;
  }

  /* ========== GOV ONLY ========== */

  function setManagement(IManagement _newManagement) external onlyGovernor {
    management = _newManagement;
    emit ManagementUpdated(_newManagement);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCutFacet is IDiamondCut {
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
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}