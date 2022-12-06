/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-05
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org
// SPDX-License-Identifier: No License

// File contracts/interfaces/IDiamondCut.sol

pragma solidity ^0.8.0;

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

// File contracts/libraries/LibDiamond.sol

pragma solidity ^0.8.0;

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

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
	}

	function diamondStorage() internal pure returns (DiamondStorage storage ds) {
		bytes32 position = DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
	}

	event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

	// Internal function version of diamondCut
	function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
		for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
			IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
			if (action == IDiamondCut.FacetCutAction.Add) {
				addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
			}
			// else if (action == IDiamondCut.FacetCutAction.Replace) {
			//     replaceFunctions(
			//         _diamondCut[facetIndex].facetAddress,
			//         _diamondCut[facetIndex].functionSelectors
			//     );
			// } else if (action == IDiamondCut.FacetCutAction.Remove) {
			//     removeFunctions(
			//         _diamondCut[facetIndex].facetAddress,
			//         _diamondCut[facetIndex].functionSelectors
			//     );
			// }
			else {
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

	// function replaceFunctions(
	//     address _facetAddress,
	//     bytes4[] memory _functionSelectors
	// ) internal {
	//     require(
	//         _functionSelectors.length > 0,
	//         "LibDiamondCut: No selectors in facet to cut"
	//     );
	//     DiamondStorage storage ds = diamondStorage();
	//     require(
	//         _facetAddress != address(0),
	//         "LibDiamondCut: Add facet can't be address(0)"
	//     );
	//     uint96 selectorPosition = uint96(
	//         ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
	//     );
	//     // add new facet address if it does not exist
	//     if (selectorPosition == 0) {
	//         addFacet(ds, _facetAddress);
	//     }
	//     for (
	//         uint256 selectorIndex;
	//         selectorIndex < _functionSelectors.length;
	//         selectorIndex++
	//     ) {
	//         bytes4 selector = _functionSelectors[selectorIndex];
	//         address oldFacetAddress = ds
	//             .selectorToFacetAndPosition[selector]
	//             .facetAddress;
	//         require(
	//             oldFacetAddress != _facetAddress,
	//             "LibDiamondCut: Can't replace function with same function"
	//         );
	//         removeFunction(ds, oldFacetAddress, selector);
	//         addFunction(ds, selector, selectorPosition, _facetAddress);
	//         selectorPosition++;
	//     }
	// }

	// function removeFunctions(
	//     address _facetAddress,
	//     bytes4[] memory _functionSelectors
	// ) internal {
	//     require(
	//         _functionSelectors.length > 0,
	//         "LibDiamondCut: No selectors in facet to cut"
	//     );
	//     DiamondStorage storage ds = diamondStorage();
	//     // if function does not exist then do nothing and return
	//     require(
	//         _facetAddress == address(0),
	//         "LibDiamondCut: Remove facet address must be address(0)"
	//     );
	//     for (
	//         uint256 selectorIndex;
	//         selectorIndex < _functionSelectors.length;
	//         selectorIndex++
	//     ) {
	//         bytes4 selector = _functionSelectors[selectorIndex];
	//         address oldFacetAddress = ds
	//             .selectorToFacetAndPosition[selector]
	//             .facetAddress;
	//         removeFunction(ds, oldFacetAddress, selector);
	//     }
	// }

	function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
		enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
		ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
		ds.facetAddresses.push(_facetAddress);
	}

	function addFunction(
		DiamondStorage storage ds,
		bytes4 _selector,
		uint96 _selectorPosition,
		address _facetAddress
	) internal {
		ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
		ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
		ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
	}

	// function removeFunction(
	//     DiamondStorage storage ds,
	//     address _facetAddress,
	//     bytes4 _selector
	// ) internal {
	//     require(
	//         _facetAddress != address(0),
	//         "LibDiamondCut: Can't remove function that doesn't exist"
	//     );
	//     // an immutable function is a function defined directly in a diamond
	//     require(
	//         _facetAddress != address(this),
	//         "LibDiamondCut: Can't remove immutable function"
	//     );
	//     // replace selector with last selector, then delete last selector
	//     uint256 selectorPosition = ds
	//         .selectorToFacetAndPosition[_selector]
	//         .functionSelectorPosition;
	//     uint256 lastSelectorPosition = ds
	//         .facetFunctionSelectors[_facetAddress]
	//         .functionSelectors
	//         .length - 1;
	//     // if not the same then replace _selector with lastSelector
	//     if (selectorPosition != lastSelectorPosition) {
	//         bytes4 lastSelector = ds
	//             .facetFunctionSelectors[_facetAddress]
	//             .functionSelectors[lastSelectorPosition];
	//         ds.facetFunctionSelectors[_facetAddress].functionSelectors[
	//                 selectorPosition
	//             ] = lastSelector;
	//         ds
	//             .selectorToFacetAndPosition[lastSelector]
	//             .functionSelectorPosition = uint96(selectorPosition);
	//     }
	//     // delete the last selector
	//     ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
	//     delete ds.selectorToFacetAndPosition[_selector];

	//     // if no more selectors for facet address then delete the facet address
	//     if (lastSelectorPosition == 0) {
	//         // replace facet address with last facet address and delete last facet address
	//         uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
	//         uint256 facetAddressPosition = ds
	//             .facetFunctionSelectors[_facetAddress]
	//             .facetAddressPosition;
	//         if (facetAddressPosition != lastFacetAddressPosition) {
	//             address lastFacetAddress = ds.facetAddresses[
	//                 lastFacetAddressPosition
	//             ];
	//             ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
	//             ds
	//                 .facetFunctionSelectors[lastFacetAddress]
	//                 .facetAddressPosition = facetAddressPosition;
	//         }
	//         ds.facetAddresses.pop();
	//         delete ds
	//             .facetFunctionSelectors[_facetAddress]
	//             .facetAddressPosition;
	//     }
	// }

	function initializeDiamondCut(address _init, bytes memory _calldata) internal {
		if (_init == address(0)) {
			return;
		}
		enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
		(bool success, bytes memory error) = _init.delegatecall(_calldata);
		if (!success) {
			if (error.length > 0) {
				// bubble up error
				/// @solidity memory-safe-assembly
				assembly {
					let returndata_size := mload(error)
					revert(add(32, error), returndata_size)
				}
			} else {
				revert InitializationFunctionReverted(_init, _calldata);
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

// File contracts/interfaces/IDiamondLoupe.sol

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/interfaces/[email protected]

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

// File contracts/facets/DiamondInit.sol

pragma solidity ^0.8.0;

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
		ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;

		// add your own state variables
		// EIP-2535 specifies that the `diamondCut` function takes two optional
		// arguments: address _init and bytes calldata _calldata
		// These arguments are used to execute an arbitrary function using delegatecall
		// in order to set state variables in the diamond during deployment or an upgrade
		// More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
	}
}

// File contracts/libraries/LibStructStorage.sol

pragma solidity 0.8.17;

library LibStructStorage {
	enum DealState {
		BidLive,
		AskLive,
		Matched,
		Live,
		Claimable
	}

	struct Standard {
		int128 strike;
		uint128 feeInBps;
		uint64 startDate;
		uint64 maturityDate;
		uint8 exponentOfTenMultiplierForStrike;
	}

	struct Voucher {
		uint128 notional;
		uint128 premium;
		uint128 feeInBps;
		int128 strike;
		uint64 startDate;
		uint64 maturityDate;
		string denomination;
	}

	struct Deal {
		// Not sure if this is the best way to store deals. Having voucher inside => each deal
		// stores standard information.
		// Another option would be if Standard would have an array of deals according to it,
		// so standard information is only replicated once.
		// This approach would require us to look through the code in detail, and figure out
		// if implementation would work efficiently (what kind of access we need for deals, etc.)
		address initiator;
		address buyer;
		address seller;
		uint128 funds;
		uint64 expiryDate;
		Voucher voucher;
		DealState state;
	}

	// Tested: public variables name size doesn't impact bytecode, as they get replaced.
	string public constant UNIX_TIMESTAMP_IS_NOT_EXACT_DATE = "1";
	string public constant STANDARD_SYMBOL_IS_EMPTY_STRING = "2";
	string public constant STANDARD_WITH_SAME_SYMBOL_ALREADY_EXISTS = "3";
	string public constant STANDARD_START_DATE_IS_ZERO = "4";
	string public constant STANDARD_MATURITY_DATE_IS_NOT_BIGGER_THAN_START_DATE = "5";
	string public constant STANDARD_FEE_IN_BPS_EXCEEDS_MAX_FEE_IN_BPS = "6";
	string public constant ACCOUNT_TO_BE_OWNER_IS_ALREADY_OWNER = "7";
	string public constant ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OWNER = "8";
	string public constant ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OPERATOR = "9";
	string public constant TOKEN_WITH_SYMBOL_ALREADY_EXISTS = "10";
	string public constant TOKEN_ADDRESS_CANNOT_BE_EMPTY = "11";
	string public constant TRANSITION_CALLER_IS_NOT_OWNER = "12";
	string public constant DEACTIVATED_FOR_OWNERS = "13";
	string public constant ACCESS_CONTROL_FACET_ALREADY_INITIALIZED = "14";
	string public constant TOKEN_SYMBOL_IS_EMPTY_STRING = "15";
	string public constant SHOULD_BE_OWNER = "16";
	string public constant ADDRESS_SHOULD_NOT_BE_OWNER = "17";
	string public constant ADDRESS_SHOULD_NOT_BE_OPERATOR = "18";
	string public constant ADDRESS_SHOULD_NOT_BE_FEE_ADDRESS = "19";
	string public constant EMPTY_SYMBOL = "20";
	string public constant EMPTY_DENOMINATION = "21";
	string public constant STANDARD_NOT_FOUND = "22";
	string public constant STANDARD_DOES_NOT_EXIST = "23";
	string public constant TOKEN_DOES_NOT_EXIST = "24";
	string public constant NOTIONAL_SHOULD_BE_GREATER_THAN_ZERO = "25";
	string public constant NOTIONAL_SHOULD_BE_MULTIPLE_OF_10000 = "26";
	string public constant PREMIUM_SHOULD_BE_LESS_THAN_NOTIONAL = "27";
	string public constant INSUFFICIENT_BALANCE = "28";
	string public constant ERROR_TRANSFERRING_TOKEN = "29";
	string public constant INSUFFICIENT_SPEND_TOKEN_ALLOWENCE = "30";
	string public constant EXPIRY_DATE_SHOULD_BE_LESS_THAN_OR_EQUAL_TO_MATURITY_DATE = "31";
	string public constant MISSING_EXPIRY_DATE = "32";
	string public constant PREMIUM_SHOULD_BE_GREATER_THAN_ZERO = "33";
	string public constant USERS_ARE_DEACTIVATED = "34";
	string public constant NO_DEAL_FOR_THIS_DEAL_ID = "35";
	string public constant DEAL_CAN_NOT_BE_CANCELLED = "36";
	string public constant USER_TO_CANCEL_DEAL_IS_NOT_INITIATOR = "37";
	string public constant TOKEN_WITH_DENOMINATION_DOES_NOT_EXIST = "38";
	string public constant TOKEN_TRANSFER_FAILED = "39";
	string public constant ADDRESS = "39";
	string public constant ACCOUNT_TO_BE_FEE_ADDRESS_IS_ALREADY_OWNER = "40";
	string public constant ACCOUNT_TO_BE_FEE_ADDRESS_IS_ALREADY_OPERATOR = "41";
	string public constant DEAL_ID_SHOULD_BE_GREATER_THAN_OR_EQUAL_TO_ZERO = "42";
	string public constant DEAL_NOT_FOUND = "43";
	string public constant DEAL_STATE_IS_NOT_ASK_LIVE = "44";
	string public constant CAN_NOT_MATCH_YOUR_OWN_DEAL = "45";
	string public constant DEAL_SELLER_SHOULD_NOT_BE_EMPTY = "46";
	string public constant DEAL_BUYER_IS_EMPTY = "47";
	string public constant DEAL_STATE_IS_NOT_BID_LIVE = "48";
	string public constant DEAL_BUYER_SHOULD_NOT_BE_EMPTY = "49";
	string public constant STRIKE_IS_NOT_MULTIPLE_OF_TEN_RAISED_TO_EXPONENT = "50";

	uint128 public constant MAX_FEE_IN_BPS = 10 ** 4;
	uint128 public constant ZERO = 0;
	int128 public constant TEN = 10;
	uint128 public constant TEN_THOUSAND = 10000;
	bytes32 public constant OWNER_ROLE = keccak256("OWNER");
	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
}

// File contracts/interfaces/ICerchiaDRTEvents.sol

pragma solidity 0.8.17;

interface ICerchiaDRTEvents {
	event OwnerAddedNewStandard(address indexed owner, string indexed symbol, LibStructStorage.Standard standard);

	event OwnerAddedNewToken(address indexed owner, string indexed symbol, address indexed token);

	event NewBid(uint256 indexed dealId, address indexed origin, uint128 targetAmount, LibStructStorage.Deal deal);

	event NewAsk(uint256 indexed dealId, address indexed origin, uint128 targetAmount, LibStructStorage.Deal deal);

	event UserUpdateDealToCancel(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);

	// | LogMatch of Uint32 ByStr20 Uint128 (* id, _origin, funds received *)
	event Match(uint256 indexed dealId, address indexed origin, uint128 targetAmount);
}

// File contracts/interfaces/ICerchiaDRT.sol

pragma solidity 0.8.17;

// Interface
interface ICerchiaDRT is ICerchiaDRTEvents {
	function ownerAddNewStandard(
		string calldata symbol,
		uint64 startDate,
		uint64 maturityDate,
		uint128 feeInBps,
		int128 strike,
		uint8 exponentOfTenMultiplierForStrike
	) external;

	function ownerAddNewToken(string calldata symbol, address token) external;

	function userUpdateDealToCancel(uint256 dealId) external;

	function getToken(string calldata symbol) external returns (address);

	function getStandard(string calldata symbol) external returns (LibStructStorage.Standard memory standard);

	function getDeal(uint256 dealId) external returns (LibStructStorage.Deal memory deal);

	function userCreateNewDealAsBid(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	function userCreateNewDealAsAsk(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;
}

// File contracts/interfaces/IAccessControl.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

// Since we are using DiamondPattern, one can no longer directly inherit AccessControl from Openzeppelin.
// This happens because DiamondPattern implies a different storage structure,
// but AccessControl handles memory internally.
// Following is the OpenZeppelin work, slightly changed to fit our use-case and needs.
interface IAccessControl {
	/**
	 * @dev Emitted when `account` is granted `role`.
	 *
	 * `sender` is the account that originated the contract call, an admin role
	 * bearer except when using {AccessControl-_setupRole}.
	 */
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

	function initAccessControlFacet(address[3] memory owners, address[3] memory operators, address feeAddress) external;

	/**
	 * @dev Returns `true` if `account` has been granted `role`.
	 */
	function hasRole(bytes32 role, address account) external view returns (bool);

	function isFeeAddress(address account) external view returns (bool);
}

// File contracts/interfaces/IMatchDeal.sol

pragma solidity 0.8.17;

// Interface
interface IMatchDeal is ICerchiaDRTEvents {
	function userUpdateDealFromBidToMatched(uint256 dealId) external;

	function userUpdateDealFromAskToMatched(uint256 dealId) external;
}

// File contracts/Diamond.sol

pragma solidity ^0.8.0;

contract Diamond {
	constructor(
		address _diamondLoupeFacet,
		address _diamondInitFacet,
		address _cerchiaDRTFacet,
		address _accessControlFacet,
		address _matchDealFacet
	) payable {
		// Add the diamondCut external function from the diamondCutFacet
		IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](5);

		// Diamond Loupe Facet
		bytes4[] memory diamondLoupeFacetSelectors = new bytes4[](5);
		diamondLoupeFacetSelectors[0] = IDiamondLoupe.facets.selector;
		diamondLoupeFacetSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
		diamondLoupeFacetSelectors[2] = IDiamondLoupe.facetAddresses.selector;
		diamondLoupeFacetSelectors[3] = IDiamondLoupe.facetAddress.selector;
		diamondLoupeFacetSelectors[4] = IERC165.supportsInterface.selector;

		cuts[0] = IDiamondCut.FacetCut({
			facetAddress: _diamondLoupeFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: diamondLoupeFacetSelectors
		});

		// Diamond Init Facet
		bytes4[] memory diamondInitFacetSelectors = new bytes4[](1);
		diamondInitFacetSelectors[0] = DiamondInit.init.selector;

		cuts[1] = IDiamondCut.FacetCut({
			facetAddress: _diamondInitFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: diamondInitFacetSelectors
		});

		// Cerchia DRT Facet
		bytes4[] memory cerchiaDRTSelectors = new bytes4[](8);
		cerchiaDRTSelectors[0] = ICerchiaDRT.ownerAddNewStandard.selector;
		cerchiaDRTSelectors[1] = ICerchiaDRT.ownerAddNewToken.selector;
		cerchiaDRTSelectors[2] = ICerchiaDRT.getToken.selector;
		cerchiaDRTSelectors[3] = ICerchiaDRT.getStandard.selector;
		cerchiaDRTSelectors[4] = ICerchiaDRT.getDeal.selector;
		cerchiaDRTSelectors[5] = ICerchiaDRT.userCreateNewDealAsBid.selector;
		cerchiaDRTSelectors[6] = ICerchiaDRT.userCreateNewDealAsAsk.selector;
		cerchiaDRTSelectors[7] = ICerchiaDRT.userUpdateDealToCancel.selector;

		cuts[2] = IDiamondCut.FacetCut({
			facetAddress: _cerchiaDRTFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: cerchiaDRTSelectors
		});

		// Access Control Facet
		bytes4[] memory accessControlFacetSelectors = new bytes4[](3);
		accessControlFacetSelectors[0] = IAccessControl.initAccessControlFacet.selector;
		accessControlFacetSelectors[1] = IAccessControl.hasRole.selector;
		accessControlFacetSelectors[2] = IAccessControl.isFeeAddress.selector;

		cuts[3] = IDiamondCut.FacetCut({
			facetAddress: _accessControlFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: accessControlFacetSelectors
		});

		bytes4[] memory matchDealSelectors = new bytes4[](2);
		matchDealSelectors[0] = IMatchDeal.userUpdateDealFromBidToMatched.selector;
		matchDealSelectors[1] = IMatchDeal.userUpdateDealFromAskToMatched.selector;

		cuts[4] = IDiamondCut.FacetCut({
			facetAddress: _matchDealFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: matchDealSelectors
		});

		LibDiamond.diamondCut(cuts, address(0), "");
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
		require(facet != address(0), string(abi.encodePacked("Diamond: Function does not exist: ", msg.sig)));
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