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

import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./interfaces/IDiamondLoupe.sol";
import { ICerchiaDRT } from "./interfaces/ICerchiaDRT.sol";
import { IAccessControl } from "./interfaces/IAccessControl.sol";
import { IMatchDeal } from "./interfaces/IMatchDeal.sol";
import { IAnyAccountOperationsFacet } from "./interfaces/IAnyAccountOperationsFacet.sol";
import { IGetEntityFacet } from "./interfaces/IGetEntityFacet.sol";
import { IClaimBackFacet } from "./interfaces/IClaimBackFacet.sol";
import { IOwnerOperations } from "./interfaces/IOwnerOperations.sol";

import { LibDiamond } from "./libraries/LibDiamond.sol";

import { DiamondInit } from "./facets/DiamondInit.sol";

/**
 * @title CerchiaDRT Diamond
 * @notice Encapsulates core DRT functionality (creating deals, cancelling, matching, settling, etc.)
 * @dev Should be 1-1 implementation of Nick Mudgen's Diamond 3
 */
contract Diamond {
	constructor(
		address diamondLoupeFacet,
		address diamondInitFacet,
		address cerchiaDRTFacet,
		address accessControlFacet,
		address matchDealFacet,
		address anyAccountOperationsFacet,
		address getEntityFacet,
		address claimBackFacet,
		address ownerOperationsFacet
	) {
		// Add the diamondCut external function from the diamondCutFacet
		IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](9);

		// Diamond Loupe Facet
		bytes4[] memory diamondLoupeFacetSelectors = new bytes4[](5);
		diamondLoupeFacetSelectors[0] = IDiamondLoupe.facets.selector;
		diamondLoupeFacetSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
		diamondLoupeFacetSelectors[2] = IDiamondLoupe.facetAddresses.selector;
		diamondLoupeFacetSelectors[3] = IDiamondLoupe.facetAddress.selector;
		diamondLoupeFacetSelectors[4] = IERC165.supportsInterface.selector;

		cuts[0] = IDiamondCut.FacetCut({
			facetAddress: diamondLoupeFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: diamondLoupeFacetSelectors
		});

		// Diamond Init Facet
		bytes4[] memory diamondInitFacetSelectors = new bytes4[](1);
		diamondInitFacetSelectors[0] = DiamondInit.init.selector;

		cuts[1] = IDiamondCut.FacetCut({
			facetAddress: diamondInitFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: diamondInitFacetSelectors
		});

		// Cerchia DRT Facet
		bytes4[] memory cerchiaDRTSelectors = new bytes4[](3);
		cerchiaDRTSelectors[0] = ICerchiaDRT.userCreateNewDealAsBid.selector;
		cerchiaDRTSelectors[1] = ICerchiaDRT.userCreateNewDealAsAsk.selector;
		cerchiaDRTSelectors[2] = ICerchiaDRT.userUpdateDealToCancel.selector;

		cuts[2] = IDiamondCut.FacetCut({
			facetAddress: cerchiaDRTFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: cerchiaDRTSelectors
		});

		// Access Control Facet
		bytes4[] memory accessControlFacetSelectors = new bytes4[](10);
		accessControlFacetSelectors[0] = IAccessControl.initAccessControlFacet.selector;
		accessControlFacetSelectors[1] = IAccessControl.ownerDeactivateAllFunctions.selector;
		accessControlFacetSelectors[2] = IAccessControl.ownerDeactivateUserFunctions.selector;
		accessControlFacetSelectors[3] = IAccessControl.ownerDeactivateOperatorFunctions.selector;
		accessControlFacetSelectors[4] = IAccessControl.ownerActivateOperatorFunctions.selector;
		accessControlFacetSelectors[5] = IAccessControl.getFeeAddress.selector;
		accessControlFacetSelectors[6] = IAccessControl.getOracleAddress.selector;
		accessControlFacetSelectors[7] = IAccessControl.hasRole.selector;
		accessControlFacetSelectors[8] = IAccessControl.isKYXProvider.selector;
		accessControlFacetSelectors[9] = IAccessControl.isUser.selector;

		cuts[3] = IDiamondCut.FacetCut({
			facetAddress: accessControlFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: accessControlFacetSelectors
		});

		// MatchDeal Facet
		bytes4[] memory matchDealSelectors = new bytes4[](2);
		matchDealSelectors[0] = IMatchDeal.userUpdateDealFromBidToMatched.selector;
		matchDealSelectors[1] = IMatchDeal.userUpdateDealFromAskToMatched.selector;

		cuts[4] = IDiamondCut.FacetCut({
			facetAddress: matchDealFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: matchDealSelectors
		});

		// Any account operations facet
		bytes4[] memory anyAccountOperationsSelectors = new bytes4[](5);
		anyAccountOperationsSelectors[0] = IAnyAccountOperationsFacet.initiateIndexDataUpdate.selector;
		anyAccountOperationsSelectors[1] = IAnyAccountOperationsFacet.operatorInitiateIndexDataUpdate.selector;
		anyAccountOperationsSelectors[2] = IAnyAccountOperationsFacet.indexDataCallBack.selector;
		anyAccountOperationsSelectors[3] = IAnyAccountOperationsFacet.processContingentSettlement.selector;
		anyAccountOperationsSelectors[4] = IAnyAccountOperationsFacet.operatorProcessContingentSettlement.selector;

		cuts[5] = IDiamondCut.FacetCut({
			facetAddress: anyAccountOperationsFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: anyAccountOperationsSelectors
		});

		// GetEntityFacet
		bytes4[] memory getEntityFacetSelectors = new bytes4[](16);
		getEntityFacetSelectors[0] = IGetEntityFacet.getStandardSymbols.selector;
		getEntityFacetSelectors[1] = IGetEntityFacet.getStandard.selector;
		getEntityFacetSelectors[2] = IGetEntityFacet.getTokenSymbols.selector;
		getEntityFacetSelectors[3] = IGetEntityFacet.getTokenAddress.selector;
		getEntityFacetSelectors[4] = IGetEntityFacet.getDeal.selector;
		getEntityFacetSelectors[5] = IGetEntityFacet.getDealIds.selector;
		getEntityFacetSelectors[6] = IGetEntityFacet.getIndexLevelTimestamps.selector;
		getEntityFacetSelectors[7] = IGetEntityFacet.getUserActiveDealsCount.selector;
		getEntityFacetSelectors[8] = IGetEntityFacet.isRestrictedToUserClaimBack.selector;
		getEntityFacetSelectors[9] = IGetEntityFacet.getIsDeactivatedForOwners.selector;
		getEntityFacetSelectors[10] = IGetEntityFacet.getIsDeactivatedForOperators.selector;
		getEntityFacetSelectors[11] = IGetEntityFacet.isInDissolution.selector;
		getEntityFacetSelectors[12] = IGetEntityFacet.isLevelSet.selector;
		getEntityFacetSelectors[13] = IGetEntityFacet.getLevel.selector;
		getEntityFacetSelectors[14] = IGetEntityFacet.getKYXProvidersAddresses.selector;
		getEntityFacetSelectors[15] = IGetEntityFacet.getKYXProviderName.selector;

		cuts[6] = IDiamondCut.FacetCut({
			facetAddress: getEntityFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: getEntityFacetSelectors
		});

		// ClaimBack Facet
		bytes4[] memory claimBackFacetSelectors = new bytes4[](1);
		claimBackFacetSelectors[0] = IClaimBackFacet.claimBack.selector;

		cuts[7] = IDiamondCut.FacetCut({
			facetAddress: claimBackFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: claimBackFacetSelectors
		});

		// Owner Operations Facet
		bytes4[] memory ownerOperationsFacetSelectors = new bytes4[](6);
		ownerOperationsFacetSelectors[0] = IOwnerOperations.ownerAddNewStandard.selector;
		ownerOperationsFacetSelectors[1] = IOwnerOperations.ownerAddNewToken.selector;
		ownerOperationsFacetSelectors[2] = IOwnerOperations.ownerDeleteStandards.selector;
		ownerOperationsFacetSelectors[3] = IOwnerOperations.ownerDeleteTokens.selector;
		ownerOperationsFacetSelectors[4] = IOwnerOperations.ownerAddNewKYXProvider.selector;
		ownerOperationsFacetSelectors[5] = IOwnerOperations.ownerDeleteKYXProviders.selector;

		cuts[8] = IDiamondCut.FacetCut({
			facetAddress: ownerOperationsFacet,
			action: IDiamondCut.FacetCutAction.Add,
			functionSelectors: ownerOperationsFacetSelectors
		});

		LibDiamond.diamondCut(cuts, address(0), "");
	}

	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}

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

// Since we are using DiamondPattern, one can no longer directly inherit AccessControl from Openzeppelin.
// This happens because DiamondPattern implies a different storage structure,
// but AccessControl handles memory internally.
// Following is the OpenZeppelin work, slightly changed to fit our use-case and needs.
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/IAccessControl.sol

/**
 * @title  CerchiaDRT Diamond Access Control Interface
 * @notice Used to control what functions an address can call
 */
interface IAccessControl {
	/**
	 * @notice  Emitted when `account` is granted `role`.
	 * @dev     Emitted when `account` is granted `role`.
	 * @dev     `sender` is the account that originated the contract call, an admin role
	 *          bearer except when using {AccessControl-_setupRole}.
	 */
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

	/**
	 * @param  owners  The 3 addresses to have the OWNER_ROLE role
	 * @param  operators  The 3 addresses to have the OPERATOR_ROLE role
	 * @param  feeAddress  Address to send fees to
	 * @param  oracleAddress  Address of the Oracle Diamond
	 */
	function initAccessControlFacet(
		address[3] memory owners,
		address[3] memory operators,
		address feeAddress,
		address oracleAddress
	) external;

	/**
	 * @notice  For owners, to deactivate all functions except user claimback
	 */
	function ownerDeactivateAllFunctions() external;

	/**
	 * @notice  For owners, to deactivate user functions except user claimback
	 */
	function ownerDeactivateUserFunctions() external;

	/**
	 * @notice  For owners, to deactivate operator functions
	 */
	function ownerDeactivateOperatorFunctions() external;

	/**
	 * @notice  For owners, to activate operator functions
	 */
	function ownerActivateOperatorFunctions() external;

	/**
	 * @notice  Returns fee address
	 */
	function getFeeAddress() external view returns (address);

	/**
	 * @notice  Returns oracle's address
	 */
	function getOracleAddress() external view returns (address);

	/**
	 * @notice Returns `true` if `account` has been granted `role`.
	 * @dev Returns `true` if `account` has been granted `role`.
	 */
	function hasRole(bytes32 role, address account) external view returns (bool);

	function isKYXProvider(address caller) external view returns (bool);

	function isUser(address caller) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond AnyAccount Interface
 */
interface IAnyAccountOperationsFacet is ICerchiaDRTEvents {
	/**
	 * @notice     For users, to initiate Oracle flow, to get data for index + parameter configuration + timestamp
	 * @dev     Not callable directly by users, but through KYXProvider first
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function initiateIndexDataUpdate(address callerAddress, bytes32 configurationId, uint64 timestamp) external;

	/**
	 * @notice     For operators, to initiate Oracle flow, to get data for index + parameter configuration + timestamp
	 * @dev     Callable directly by operators
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function operatorInitiateIndexDataUpdate(bytes32 configurationId, uint64 timestamp) external;

	/**
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @param   level  The index level provided by the off-chain API
	 */
	function indexDataCallBack(bytes32 configurationId, uint64 timestamp, int128 level) external;

	/**
	 * @notice     For users, to settle a deal (expire/trigger/mature), comparing to index level for given exact timestamp
	 * @dev     Not callable directly by users, but through KYXProvider first
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   timestamp  Exact timestamp to try to settle deal for
	 * @param   dealId  Deal to settle
	 */
	function processContingentSettlement(address callerAddress, uint64 timestamp, uint256 dealId) external;

	/**
	 * @notice     For operators, to settle a deal (expire/trigger/mature), comparing to
	 *              index level for given exact timestamp
	 * @dev         Callable directly by operators
	 * @param       timestamp  Exact timestamp to try to settle deal for
	 * @param       dealId  Deal to settle
	 */
	function operatorProcessContingentSettlement(uint64 timestamp, uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Create/Cancel Deal Interface
 */
interface ICerchiaDRT is ICerchiaDRTEvents {
	/**
	 * @notice  Callable by a user, to create a new BidLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   symbol  Symbol of the standard this deal is based on
	 * @param   denomination  Symbol of the token this deal is based on
	 * @param   notional  Notional of the deal (how much buyer wins if deal triggers, minus fee)
	 * @param   premium  Premium of the deal (how much seller wins if deal matures, minus fee))
	 * @param   expiryDate  Date after which this deal, if not Matched, will expire
	 */
	function userCreateNewDealAsBid(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	/**
	 * @notice  Callable by a user, to create a new AskLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   symbol  Symbol of the standard this deal is based on
	 * @param   denomination  Symbol of the token this deal is based on
	 * @param   notional  Notional of the deal (how much buyer wins if deal triggers, minus fee)
	 * @param   premium  Premium of the deal (how much seller wins if deal matures, minus fee))
	 * @param   expiryDate  Date after which this deal, if not Matched, will expire
	 */
	function userCreateNewDealAsAsk(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	/**
	 * @notice  Callable by a user, to cancel a BidLive/AskLive deal, if user was the initiator
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Deal user wants to cancel
	 */
	function userUpdateDealToCancel(address callerAddress, uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICerchiaDRTEvents {
	// When an owner adds a new standard
	event OwnerAddedNewStandard(
		address indexed owner,
		string symbol,
		bytes32 configurationId,
		int128 strike,
		uint128 feeInBps,
		uint64 startDate,
		uint64 maturityDate,
		uint8 exponentOfTenMultiplierForStrike
	);

	// When an owner adds a new token
	event OwnerAddedNewToken(address indexed owner, string symbol, address token);

	// When an owner adds a new approved KYX Provider
	event OwnerAddedNewKYXProvider(address indexed owner, string name, address indexed kyxProviderAddress);

	// When a user creates a BidLive deal
	event NewBid(
		uint256 indexed dealId,
		address indexed initiator,
		string standardSymbol,
		string tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	);

	// When a user creates an AskLive deal
	event NewAsk(
		uint256 indexed dealId,
		address indexed initiator,
		string standardSymbol,
		string tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	);

	// When a user cancels their own deal
	event UserUpdateDealToCancel(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);

	// When a user matches another user's deal, turning the deal's state into Matched
	event Match(uint256 indexed dealId, address indexed matcher, uint128 fundsSent);

	// When AnyAccountInitiateIndexDataUpdate was called, but level already exists for configurationId + timestamp
	event AnyAccountInitiateIndexDataUpdateAlreadyAvailable(bytes32 configurationId, uint64 timestamp, int128 level);

	// When data is successfully returned to CerchiaDRT Diamond, from Oracle Diamond
	event IndexDataCallBackSuccess(bytes32 configurationId, uint64 timestamp, int128 level);

	// When AutomaticDissolution triggers, because of faulty oracle during index data update or settlement
	event AutomaticDissolution(address indexed sender, bytes32 indexed configurationId, uint64 timestamp);

	// When a user claims their funds from a deal, after AutomaticDissolution happens
	event Claimed(uint256 indexed dealId, address claimer, uint128 fundsClaimed);

	// Emmited by AnyAccountProcessContingentSettlement
	event BidLiveDealExpired(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);
	event AskLiveDealExpired(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);
	event MatchedDealWentLive(uint256 indexed dealId);

	event LiveDealTriggered(
		uint256 indexed dealId,
		address indexed buyer,
		uint128 buyerReceived,
		address indexed feeAddress,
		uint128 feeAddressReceived
	);

	event LiveDealMatured(
		uint256 indexed dealId,
		address indexed seller,
		uint128 sellerReceived,
		address indexed feeAddress,
		uint128 feeAddressReceived
	);

	// When an owner deletes one of the standards
	event OwnerDeletedStandard(address indexed owner, string symbol);

	// When an owner deletes one of the tokens
	event OwnerDeletedToken(address indexed owner, string symbol);

	// When an owner adds an approved KYX Provider
	event OwnerDeletedKYXProvider(address indexed owner, string name, address indexed kyxProviderAddress);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Claimback Interface
 */
interface IClaimBackFacet is ICerchiaDRTEvents {
	/**
	 * @notice  User can claimback their side of a deal, if contract has been dissoluted
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Deal to claimback funds from
	 */
	function claimBack(address callerAddress, uint256 dealId) external;
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

import { LibStructStorage } from "../libraries/LibStructStorage.sol";

/**
 * @title  CerchiaDRT Diamond Getters Interface
 */
interface IGetEntityFacet {
	/**
	 * @notice  Returns the symbols of all standards
	 * @return  string[]  Array of symbols of all the standards in the smart contract
	 */
	function getStandardSymbols() external view returns (string[] memory);

	/**
	 * @notice  Returns a standard, given a symbol
	 * @param   symbol  Symbol of the standard to return all information for
	 * @return  LibStructStorage.Standard  Whole standard matching supplied symbol
	 */
	function getStandard(string calldata symbol) external view returns (LibStructStorage.Standard memory);

	/**
	 * @notice  Returns the symbols of all tokens
	 * @return  string[]  Array of symbols of all the tokens registered in the smart contract
	 */
	function getTokenSymbols() external view returns (string[] memory);

	/**
	 * @notice  Returns a stored token's address, given a symbol
	 * @param   symbol  Symbol of the token to return address for
	 * @return  address  Address of the token matching supplied symbol
	 */
	function getTokenAddress(string calldata symbol) external view returns (address);

	/**
	 * @notice  Returns a deal, given the dealId
	 * @return  uint256[]  Array of ids of all the deals
	 */
	function getDeal(uint256 dealId) external view returns (LibStructStorage.Deal memory);

	/**
	 * @notice  Returns a list of all the deals ids
	 * @return  uint256[]  Array of ids of all the deals
	 */
	function getDealIds() external view returns (uint256[] memory);

	/**
	 * @notice  Returns all the timestamps for which index levels exist, given a parameter set configuration
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @return  uint64[]  For supplied configurationId, all the exact timestamps for which there is data present
	 */
	function getIndexLevelTimestamps(bytes32 configurationId) external view returns (uint64[] memory);

	/**
	 * @notice  Returns the number active (Matched/Live) deals for a user
	 * @param   userAddress  Address of the user to query for
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @return  uint32  How many active deals (Matched/Live) is used involved in?
	 */
	function getUserActiveDealsCount(address userAddress, bytes32 configurationId) external view returns (uint32);

	/**
	 */
	function isRestrictedToUserClaimBack() external view returns (bool);

	/**
	 * @notice  Returns True if owner functions are deactivated
	 */
	function getIsDeactivatedForOwners() external view returns (bool);

	/**
	 * @notice  Returns True if operator functions are deactivated
	 */
	function getIsDeactivatedForOperators() external view returns (bool);

	/**
	 * @notice  Returns True if contract is in dissolution
	 */
	function isInDissolution() external view returns (bool);

	/**
	 * @notice  Returns True if we have an index level for date + configurationId combination
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @return  bool  True if there is index level data for the exact timestamp + configurationId combination
	 */
	function isLevelSet(bytes32 configurationId, uint64 timestamp) external view returns (bool);

	/**
	 * @notice  Returns index level for date + configurationId combination
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @return  int128 Index level for the exact timestamp + configurationId combination
	 */
	function getLevel(bytes32 configurationId, uint64 timestamp) external view returns (int128);

	/**
	 * @return  kyxProviderAddresses  List of all approved KYX Providers
	 */
	function getKYXProvidersAddresses() external view returns (address[] memory kyxProviderAddresses);

	/**
	 * @param   kyxProviderAddress  Address to recover name for
	 * @return  kyxProviderName  The name of the KYX Provider under the provided address
	 */
	function getKYXProviderName(address kyxProviderAddress) external view returns (string memory kyxProviderName);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Match Interface
 */
interface IMatchDeal is ICerchiaDRTEvents {
	/**
	 * @notice  Callable by a user, to match another user's BidLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Id of the deal user wants to match
	 */
	function userUpdateDealFromBidToMatched(address callerAddress, uint256 dealId) external;

	/**
	 * @notice  Callable by a user, to match another user's AskLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Id of the deal user wants to match
	 */
	function userUpdateDealFromAskToMatched(address callerAddress, uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Owner Operations Interface
 */
interface IOwnerOperations is ICerchiaDRTEvents {
	/**
	 * @dev     Callable by owners, to add a new standard linked to a parameter configuration for the off-chain api
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   symbol Symbol Standard will be denoted by
	 * @param   startDate  The date to start tracking index levels and doing settlement for linked deals
	 * @param   maturityDate  The date to stop tracking index levels and doing settlement for linked deals
	 * @param   feeInBps Fee in basis points of deal's notional, to be sent to the fee address upon deal triggers/matures
	 * @param   strike  Number that if index level is higher or equal, deal should trigger
	 * @param   exponentOfTenMultiplierForStrike  Similar to ERC20's decimals. Off-chain API data is of float type.
	 *          On the blockchain, we sent it multiplied by 10 ** exponentOfTenMultiplierForStrike, to make it integer
	 */
	function ownerAddNewStandard(
		bytes32 configurationId,
		string calldata symbol,
		uint64 startDate,
		uint64 maturityDate,
		uint128 feeInBps,
		int128 strike,
		uint8 exponentOfTenMultiplierForStrike
	) external;

	/**
	 * @dev     Callable by owners, to add a new token that users can create deals based on
	 * @param   denomination The name that the token will have inside our smart contract
	 * @param   token  The address to find the token at
	 */
	function ownerAddNewToken(string calldata denomination, address token) external;

	/**
	 * @dev     Callable by owners, to delete some of the existing standards
	 * @param   symbols  Symbols of standards to delete
	 */
	function ownerDeleteStandards(string[] calldata symbols) external;

	/**
	 * @dev     Callable by owners, to delete some of the existing tokens
	 * @param   symbols  Symbols of tokens to delete
	 */
	function ownerDeleteTokens(string[] calldata symbols) external;

	function ownerAddNewKYXProvider(address kyxProviderAddress, string calldata name) external;

	function ownerDeleteKYXProviders(address[] calldata providerNames) external;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Wrapper library storing constants and structs of CerchiaDRT Diamond
 */
library LibStructStorage {
	enum DealState {
		BidLive, // if deal only has Bid side
		AskLive, // if deal only has Ask side
		Matched, // if deal has both sides, but it can't yet be triggered/matured
		Live // if deal has both sides, and it can be triggered/matured
	}

	struct Standard {
		// keccak256 of JSON containing parameter set for off-chain API
		bytes32 configurationId;
		// value under which deal doesn't trigger
		int128 strike;
		// fee to send to fee address, represented in basis points
		uint128 feeInBps;
		// start date for the time of protection
		uint64 startDate;
		// end date for the time of protection
		uint64 maturityDate;
		// Similar to ERC20's decimals. Off-chain API data is of float type.
		// On the blockchain, we sent it multiplied by 10 ** exponentOfTenMultiplierForStrike, to make it integer
		uint8 exponentOfTenMultiplierForStrike;
	}

	struct Voucher {
		// units won by either side, when deal triggers/matures
		uint128 notional;
		// units paid by Bid side
		uint128 premium;
		// is copied over from Standard
		bytes32 configurationId;
		// is copied over from Standard
		uint128 feeInBps;
		// is copied over from Standard
		int128 strike;
		// is copied over from Standard
		uint64 startDate;
		// is copied over from Standard
		uint64 maturityDate;
		// token that deal operates on
		address token;
	}

	struct Deal {
		// address that created the deal
		address initiator;
		// address of the Bid side
		address buyer;
		// address of the Ask side
		address seller;
		// funds currently in the deal: premium if BidLive, (notional - premium) if AskLive, notional if Matched/Live
		uint128 funds;
		// timestamp after which deal will expire, if still in BidLive/AskLive state
		uint64 expiryDate;
		Voucher voucher;
		DealState state;
		// true if buyer claimed back funds, if dissolution happened
		bool buyerHasClaimedBack;
		// true if seller claimed back funds, if dissolution happened
		bool sellerHasClaimedBack;
		// for LibDealsSet.sol implementation of a CRUD interface
		uint256 id;
		uint256 indexInDealsArray;
	}

	struct IndexLevel {
		// value of the off-chain observation, for a date + parameter set configuration
		int128 value;
		// since a value of 0 is valid, we need a flag to check if an index level was set or not
		bool exists;
	}

	// Error codes with descriptive names
	string public constant UNIX_TIMESTAMP_IS_NOT_EXACT_DATE = "1";
	string public constant STANDARD_SYMBOL_IS_EMPTY = "2";
	string public constant STANDARD_WITH_SAME_SYMBOL_ALREADY_EXISTS = "3";
	string public constant STANDARD_START_DATE_IS_ZERO = "4";
	string public constant STANDARD_MATURITY_DATE_IS_NOT_BIGGER_THAN_START_DATE = "5";
	string public constant STANDARD_FEE_IN_BPS_EXCEEDS_MAX_FEE_IN_BPS = "6";
	string public constant ACCOUNT_TO_BE_OWNER_IS_ALREADY_OWNER = "7";
	string public constant ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OWNER = "8";
	string public constant ACCOUNT_TO_BE_OPERATOR_IS_ALREADY_OPERATOR = "9";
	string public constant TOKEN_WITH_DENOMINATION_ALREADY_EXISTS = "10";
	string public constant TOKEN_ADDRESS_CANNOT_BE_EMPTY = "11";
	string public constant TRANSITION_CALLER_IS_NOT_OWNER = "12";
	string public constant DEACTIVATED_FOR_OWNERS = "13";
	string public constant ACCESS_CONTROL_FACET_ALREADY_INITIALIZED = "14";
	string public constant TOKEN_DENOMINATION_IS_EMPTY = "15";
	string public constant SHOULD_BE_OWNER = "16";
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
	string public constant EXPIRY_DATE_CANT_BE_IN_THE_PAST = "32";
	string public constant PREMIUM_SHOULD_BE_GREATER_THAN_ZERO = "33";
	string public constant ONLY_CLAIMBACK_ALLOWED = "34";
	string public constant NO_DEAL_FOR_THIS_DEAL_ID = "35";
	string public constant DEAL_CAN_NOT_BE_CANCELLED = "36";
	string public constant USER_TO_CANCEL_DEAL_IS_NOT_INITIATOR = "37";
	string public constant TOKEN_WITH_DENOMINATION_DOES_NOT_EXIST = "38";
	string public constant TOKEN_TRANSFER_FAILED = "39";
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
	string public constant CONFIGURATION_ID_IS_EMPTY = "51";
	string public constant USER_HAS_NO_ACTIVE_DEALS_FOR_CONFIGURATION_ID = "52";
	string public constant CALLER_IS_NOT_ORACLE_ADDRESS = "53";
	string public constant TIMESTAMP_SHOULD_BE_VALID_BLOCK_TIMESTAMP = "54";
	string public constant ORACLE_DID_NOT_FULLFIL = "55";
	string public constant SETTLEMENT_INDEX_LEVEL_DOES_NOT_EXIST = "56";
	string public constant MATURITY_DATE_SHOULD_BE_IN_THE_FUTURE = "57";
	string public constant CONTRACT_IS_IN_DISSOLUTION = "58";
	string public constant CANNOT_CLAIM_BACK_UNLESS_IN_DISSOLUTION = "59";
	string public constant CALLER_IS_NOT_VALID_DEAL_CLAIMER = "60";
	string public constant FUNDS_ALREADY_CLAIMED = "61";
	string public constant THERE_ARE_STILL_DEALS_LEFT = "62";
	string public constant DEACTIVATED_FOR_OPERATORS = "63";
	string public constant NEED_TO_PASS_KYX = "64";
	string public constant ONLY_OPERATOR_ALLOWED = "65";
	string public constant SHOULD_BE_END_USER = "66";
	string public constant MISSING_KYX_PROVIDER_NAME = "67";
	string public constant KYX_PROVIDER_ADDRESS_CAN_NOT_BE_EMPTY = "68";
	string public constant KYX_PROVIDER_ALREADY_EXISTS = "69";
	string public constant CANNOT_SETTLE_SOMEONE_ELSES_DEAL = "70";
	string public constant UNIX_TIMESTAMP_IS_NOT_END_OF_DATE = "71";

	// Value representing invalid index level from off-chain API
	int128 public constant INVALID_LEVEL_VALUE = type(int128).min;

	// Commonly used constants
	uint128 public constant TEN_THOUSAND = 10000;
	uint128 public constant MAX_FEE_IN_BPS = TEN_THOUSAND;
	uint128 public constant ZERO = 0;

	// Used by AccessControlFacet's OpenZeppelin Roles implementation
	bytes32 public constant OWNER_ROLE = keccak256("OWNER");
	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
}