// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";

import { LibDiamond } from "../libraries/LibDiamond.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

/**
 * @title  CerchiaDRT and Oracle Diamonds DiamondInit Implementation
 */
contract DiamondInit {
	// You can add parameters to this function in order to pass in
	// data to set your own state variables

	/**
	 * @dev     Currently called from any of our Diamonds' constructors
	 * @dev     Initializes storage with the correct interfaces supported
	 */
	function init() external {
		// adding ERC165 data
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		ds.supportedInterfaces[type(IERC165).interfaceId] = true;
		ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;

		// add your own state variables
		// EIP-2535 specifies that the `diamondCut` function takes two optional
		// arguments: address _init and bytes calldata _calldata
		// These arguments are used to execute an arbitrary function using delegatecall
		// in order to set state variables in the diamond during deployment or an upgrade
		// More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IDiamondCut {
	enum FacetCutAction {
		Add
		// Replace,
		// Remove
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
	function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

	event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   CerchiaDRT and Oracle Diamond Loupe Interface
 */
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
	bytes32 public constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

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
	}

	event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

	// Internal function version of diamondCut
	function diamondCut(IDiamondCut.FacetCut[] memory diamondCuts, address init, bytes memory calldata_) internal {
		for (uint256 facetIndex; facetIndex < diamondCuts.length; ) {
			IDiamondCut.FacetCutAction action = diamondCuts[facetIndex].action;
			if (action == IDiamondCut.FacetCutAction.Add) {
				addFunctions(diamondCuts[facetIndex].facetAddress, diamondCuts[facetIndex].functionSelectors);
			} else {
				// solhint-disable-next-line reason-string
				revert("LibDiamondCut: Incorrect FacetCutAction");
			}

			unchecked {
				++facetIndex;
			}
		}
		emit DiamondCut(diamondCuts, init, calldata_);
		initializeDiamondCut(init, calldata_);
	}

	function addFunctions(address facetAddress, bytes4[] memory functionSelectors) internal {
		// solhint-disable-next-line reason-string
		require(functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
		DiamondStorage storage ds = diamondStorage();

		// solhint-disable-next-line reason-string
		require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
		uint96 selectorPosition = uint96(ds.facetFunctionSelectors[facetAddress].functionSelectors.length);
		// add new facet address if it does not exist
		if (selectorPosition == 0) {
			addFacet(ds, facetAddress);
		}
		for (uint256 selectorIndex; selectorIndex < functionSelectors.length; ) {
			bytes4 selector = functionSelectors[selectorIndex];
			address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;

			// solhint-disable-next-line reason-string
			require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
			addFunction(ds, selector, selectorPosition, facetAddress);
			selectorPosition++;

			unchecked {
				++selectorIndex;
			}
		}
	}

	function addFacet(DiamondStorage storage ds, address facetAddress) internal {
		enforceHasContractCode(facetAddress, "LibDiamondCut: New facet has no code");
		ds.facetFunctionSelectors[facetAddress].facetAddressPosition = ds.facetAddresses.length;
		ds.facetAddresses.push(facetAddress);
	}

	function addFunction(
		DiamondStorage storage ds,
		bytes4 selector,
		uint96 selectorPosition,
		address facetAddress
	) internal {
		ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
		ds.facetFunctionSelectors[facetAddress].functionSelectors.push(selector);
		ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
	}

	function initializeDiamondCut(address init, bytes memory calldata_) internal {
		if (init == address(0)) {
			return;
		}
		enforceHasContractCode(init, "LibDiamondCut: _init address has no code");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory error) = init.delegatecall(calldata_);
		if (!success) {
			if (error.length > 0) {
				// bubble up error
				/// @solidity memory-safe-assembly
				assembly {
					let returndata_size := mload(error)
					revert(add(32, error), returndata_size)
				}
			} else {
				revert InitializationFunctionReverted(init, calldata_);
			}
		}
	}

	function enforceHasContractCode(address contract_, string memory errorMessage) internal view {
		uint256 contractSize;
		assembly {
			contractSize := extcodesize(contract_)
		}
		require(contractSize > 0, errorMessage);
	}

	function diamondStorage() internal pure returns (DiamondStorage storage ds) {
		bytes32 position = DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
	}
}