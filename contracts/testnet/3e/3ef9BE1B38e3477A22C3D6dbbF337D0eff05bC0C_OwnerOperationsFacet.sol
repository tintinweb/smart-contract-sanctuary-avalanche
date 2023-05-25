// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IGetEntityFacet } from "../interfaces/IGetEntityFacet.sol";
import { IOwnerOperations } from "../interfaces/IOwnerOperations.sol";

import { LibCommonOperations } from "../libraries/LibCommonOperations.sol";
import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";
import { LibAccessControlStorage as ACStorage } from "../libraries/LibAccessControlStorage.sol";

import { RoleBased } from "../RoleBased.sol";

/**
 * @title  CerchiaDRT Diamond Owner Operations Implementation
 */
contract OwnerOperationsFacet is RoleBased, IOwnerOperations {
	/**
	 * @dev     Our project operates with exact timestamps only (think 2022-07-13 00:00:00), sent as Unix Epoch
	 * @param   unixTimestamp  Unix Epoch to be divisible by number of seconds in a day
	 */
	modifier isExactDate(uint64 unixTimestamp) {
		require(LibCommonOperations._isExactDate(unixTimestamp), LibStructStorage.UNIX_TIMESTAMP_IS_NOT_EXACT_DATE);
		_;
	}

	/**
	 * @param   unixTimestamp  Unix Epoch to be end of date (YYYY/MM/DD 23:59:59)
	 */
	modifier isEndOfDate(uint64 unixTimestamp) {
		require(
			(unixTimestamp + 1) % LibCommonOperations.SECONDS_IN_A_DAY == 0,
			LibStructStorage.UNIX_TIMESTAMP_IS_NOT_END_OF_DATE
		);
		_;
	}

	/**
	 * @dev Prevents calling a function if owners are deactivated
	 */
	modifier isNotDeactivatedForOwner() {
		require(!IGetEntityFacet(address(this)).getIsDeactivatedForOwners(), LibStructStorage.DEACTIVATED_FOR_OWNERS);
		_;
	}

	/**
	 * @inheritdoc IOwnerOperations
	 */
	function ownerAddNewStandard(
		bytes32 configurationId,
		string calldata symbol,
		uint64 startDate,
		uint64 maturityDate,
		uint128 feeInBps,
		int128 strike,
		uint8 exponentOfTenMultiplierForStrike
	) external onlyOwner isNotDeactivatedForOwner isExactDate(startDate) isEndOfDate(maturityDate) {
		// Check calldata is valid (also in modifiers)
		require(LibCommonOperations._isNotEmpty(symbol), LibStructStorage.STANDARD_SYMBOL_IS_EMPTY);
		require(startDate > 0, LibStructStorage.STANDARD_START_DATE_IS_ZERO);
		require(maturityDate > startDate, LibStructStorage.STANDARD_MATURITY_DATE_IS_NOT_BIGGER_THAN_START_DATE);

		// solhint-disable-next-line not-rely-on-time
		require(maturityDate > block.timestamp, LibStructStorage.MATURITY_DATE_SHOULD_BE_IN_THE_FUTURE);

		require(
			feeInBps < LibStructStorage.MAX_FEE_IN_BPS,
			LibStructStorage.STANDARD_FEE_IN_BPS_EXCEEDS_MAX_FEE_IN_BPS
		);

		// Check standard with same symbol doesn't already exist
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();
		require(s._standards[symbol].startDate == 0, LibStructStorage.STANDARD_WITH_SAME_SYMBOL_ALREADY_EXISTS);

		// Store new standard and its symbol
		s._standards[symbol] = LibStructStorage.Standard(
			configurationId,
			strike,
			feeInBps,
			startDate,
			maturityDate,
			exponentOfTenMultiplierForStrike
		);
		s._standardsKeys.push(symbol);

		// Emit event
		_emitOwnerAddNewStandard(symbol, s._standards[symbol]);
	}

	/**
	 * @inheritdoc IOwnerOperations
	 * @dev  On Avalanche Fuji Chain, owner would call this with ("USDC", <REAL_USDC_ADDRESS_ON_FUJI>)
	 */
	function ownerAddNewToken(string calldata denomination, address token) external onlyOwner isNotDeactivatedForOwner {
		// Check calldata is valid
		require(LibCommonOperations._isNotEmpty(denomination), LibStructStorage.TOKEN_DENOMINATION_IS_EMPTY);
		require(token != address(0), LibStructStorage.TOKEN_ADDRESS_CANNOT_BE_EMPTY);

		// Check token doesn't already exist
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();
		require(
			!LibCommonOperations._tokenExists(s._tokens[denomination]),
			LibStructStorage.TOKEN_WITH_DENOMINATION_ALREADY_EXISTS
		);

		// Store new token and its denomination
		s._tokens[denomination] = token;
		s._tokensKeys.push(denomination);

		// Emit event
		emit OwnerAddedNewToken(msg.sender, denomination, token);
	}

	/**
	 * @inheritdoc  IOwnerOperations
	 * @dev         Since we expect a small number of standards, controller by owners, the below "for" loops are
	 *              not a gas or DoS concern
	 */
	function ownerDeleteStandards(string[] calldata symbols) external onlyOwner isNotDeactivatedForOwner {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		uint256 symbolsLength = symbols.length;

		// For each symbol to delete
		for (uint256 symbolIdx; symbolIdx < symbolsLength; ) {
			string calldata symbol = symbols[symbolIdx];

			uint256 standardKeysLength = s._standardsKeys.length;

			// If standard with that symbol exists
			if (s._standards[symbol].startDate > 0) {
				// Delete it from mapping
				delete s._standards[symbol];

				// Find its key in array and delete (use swap-with-last method)
				for (uint256 searchIdx; searchIdx < standardKeysLength; ) {
					if (_compareStrings(s._standardsKeys[searchIdx], symbol)) {
						s._standardsKeys[searchIdx] = s._standardsKeys[standardKeysLength - 1];
						s._standardsKeys.pop();
						break;
					}

					unchecked {
						++searchIdx;
					}
				}

				// Emit event
				emit OwnerDeletedStandard(msg.sender, symbol);
			}

			unchecked {
				++symbolIdx;
			}
		}
	}

	/**
	 * @inheritdoc IOwnerOperations
	 * @dev     Since we expect a small number of tokens, controller by owners, the below "for" loops are
	 *          not a gas or DoS concern
	 */
	function ownerDeleteTokens(string[] calldata symbols) external onlyOwner isNotDeactivatedForOwner {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		uint256 symbolsLength = symbols.length;

		// For each denomination to delete
		for (uint256 symbolIdx; symbolIdx < symbolsLength; ) {
			string calldata symbol = symbols[symbolIdx];

			uint256 tokenKeysLength = s._tokensKeys.length;

			// If token with that denomination exists
			if (s._tokens[symbol] != address(0)) {
				// Delete token from mapping
				delete s._tokens[symbol];

				// Find its key in array and delete (use swap-with-last method)
				for (uint256 searchIdx; searchIdx < tokenKeysLength; ) {
					if (_compareStrings(s._tokensKeys[searchIdx], symbol)) {
						s._tokensKeys[searchIdx] = s._tokensKeys[tokenKeysLength - 1];
						s._tokensKeys.pop();
						break;
					}

					unchecked {
						++searchIdx;
					}
				}

				// Emit event
				emit OwnerDeletedToken(msg.sender, symbol);
			}

			unchecked {
				++symbolIdx;
			}
		}
	}

	/**
	 * @param   a  First string
	 * @param   b  Seconds string
	 * @return  bool  True if strings are equal
	 */
	function _compareStrings(string memory a, string memory b) private pure returns (bool) {
		return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
	}

	/**
	 * @dev     Helper function to emit OwnerAddNewStandard event, to avoid StackTooDeep issue
	 * @param   symbol  Symbol of standard
	 * @param   standard  Whole standard struct
	 */
	function _emitOwnerAddNewStandard(string calldata symbol, LibStructStorage.Standard storage standard) private {
		emit OwnerAddedNewStandard(
			msg.sender,
			symbol,
			standard.configurationId,
			standard.strike,
			standard.feeInBps,
			standard.startDate,
			standard.maturityDate,
			standard.exponentOfTenMultiplierForStrike
		);
	}

	function ownerAddNewKYXProvider(
		address kyxProviderAddress,
		string calldata name
	) external override onlyOwner isNotDeactivatedForOwner {
		require(kyxProviderAddress != address(0), LibStructStorage.KYX_PROVIDER_ADDRESS_CAN_NOT_BE_EMPTY);
		require(LibCommonOperations._isNotEmpty(name), LibStructStorage.MISSING_KYX_PROVIDER_NAME);

		// Check KYX Provider doesn't already exist
		ACStorage.AccessControlStorage storage acStorage = ACStorage.getStorage();
		require(
			bytes(acStorage._kyxProviders[kyxProviderAddress]).length == 0,
			LibStructStorage.KYX_PROVIDER_ALREADY_EXISTS
		);

		acStorage._kyxProviders[kyxProviderAddress] = name;
		acStorage._kyxProvidersKeys.push(kyxProviderAddress);

		// Emit event
		emit OwnerAddedNewKYXProvider(msg.sender, name, kyxProviderAddress);
	}

	function ownerDeleteKYXProviders(
		address[] calldata providersToDelete
	) external override onlyOwner isNotDeactivatedForOwner {
		ACStorage.AccessControlStorage storage acStorage = ACStorage.getStorage();

		uint256 providersToDeleteLength = providersToDelete.length;

		// For each kyxProvider to delete
		for (uint256 providerIndexToDelete; providerIndexToDelete < providersToDeleteLength; ) {
			address providerAddressToDelete = providersToDelete[providerIndexToDelete];
			uint256 kyxProviderKeysLength = acStorage._kyxProvidersKeys.length;

			// Get the name from the address
			string memory name = acStorage._kyxProviders[providerAddressToDelete];

			// If kyxProvider with that name exists
			if (bytes(name).length > 0) {
				// Delete kyxProvider from mapping
				delete acStorage._kyxProviders[providerAddressToDelete];

				// Find its key in array and delete (use swap-with-last method)
				for (uint256 searchIdx; searchIdx < kyxProviderKeysLength; ) {
					if (providerAddressToDelete == acStorage._kyxProvidersKeys[searchIdx]) {
						acStorage._kyxProvidersKeys[searchIdx] = acStorage._kyxProvidersKeys[kyxProviderKeysLength - 1];
						acStorage._kyxProvidersKeys.pop();
						break;
					}

					unchecked {
						++searchIdx;
					}
				}

				// Emit event
				emit OwnerDeletedKYXProvider(msg.sender, name, providerAddressToDelete);
			}

			unchecked {
				++providerIndexToDelete;
			}
		}
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
	 * @notice  Emitted when `sender` (owner) sets `feeAddress`.
	 * @dev     Emitted when `sender` (owner) sets `feeAddress`.
	 * @dev     `sender` is the account that originated the contract call, an admin role
	 *          bearer except when using {AccessControl-_setupRole}.
	 */
	event FeeAddressSet(address indexed feeAddress, address indexed sender);

	/**
	 * @notice  Emitted when `sender` (owner) sets `oracleAddress`.
	 * @dev     Emitted when `sender` (owner) sets `oracleAddress`.
	 * @dev     `sender` is the account that originated the contract call, an admin role
	 *          bearer except when using {AccessControl-_setupRole}.
	 */
	event OracleAddressSet(address indexed oracleAddress, address indexed sender);

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

/**
 * @title   Diamond Storage for CerchiaDRT Diamond's access control functions
 */
library LibAccessControlStorage {
	bytes32 public constant ACCESS_CONTROL_STORAGE_SLOT = keccak256("ACCESS.CONTROL.STORAGE");

	/**
	 * @dev Inspired by OpenZeppelin's AccessControl Roles, but updated to our use case (without RoleAdmin)
	 */
	struct RoleData {
		// members[address] is true if address has role
		mapping(address => bool) members;
	}

	/**
	 * @dev https://dev.to/mudgen/how-diamond-storage-works-90e
	 */
	struct AccessControlStorage {
		// OWNER_ROLE and OPERATOR_ROLE
		mapping(bytes32 => RoleData) _roles;
		// KYX Providers
		// mapping(kyx provider address => kyx provider name)
		mapping(address => string) _kyxProviders;
		// list of all kyx providers addresses
		address[] _kyxProvidersKeys;
		// Address to send fee to
		address _feeAddress;
		// Address to call, for Oracle Diamond's GetLevel
		address _oracleAddress;
		// True if users can only claimback
		bool _usersCanOnlyClaimBack;
		// True if operator functions are deactivated
		bool _isDeactivatedForOperators;
		// True if owner functions are deactivated
		bool _isDeactivatedForOwners;
		// True if AccessControlStorageOracle storage was initialized
		bool _initialized;
	}

	/**
	 * @dev     https://dev.to/mudgen/how-diamond-storage-works-90e
	 * @return  s  Returns a pointer to a specific (arbitrary) location in memory, holding our AccessControlStorage struct
	 */
	function getStorage() internal pure returns (AccessControlStorage storage s) {
		bytes32 position = ACCESS_CONTROL_STORAGE_SLOT;
		assembly {
			s.slot := position
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

/**
 * @title   Diamond Storage for CerchiaDRT Diamond's functions, except access control
 */
library LibCerchiaDRTStorage {
	bytes32 public constant CERCHIA_DRT_STORAGE_SLOT = keccak256("CERCHIA.DRT.STORAGE");

	/**
	 * @dev https://dev.to/mudgen/how-diamond-storage-works-90e
	 */
	struct CerchiaDRTStorage {
		// Standards
		// mapping(standard symbol => Standard)
		mapping(string => LibStructStorage.Standard) _standards;
		// list of all standard symbols
		string[] _standardsKeys;
		// Tokens
		// mapping(token symbol => token's address)
		mapping(string => address) _tokens;
		// list of all token symbols
		string[] _tokensKeys;
		// Deals
		// all the deals, structured so that we can easily do CRUD operations on them
		LibDealsSet.DealsSet _dealsSet;
		// Index levels
		// ConfigurationId (bytes32) -> Day (timestamp as uint64) -> Level
		mapping(bytes32 => mapping(uint64 => LibStructStorage.IndexLevel)) _indexLevels;
		// For each configurationId, stores a list of all the timestamps for which we have indexlevels
		mapping(bytes32 => uint64[]) _indexLevelTimestamps;
		// How many Active (Matched/Live) deals a user is involved in, for a configurationId
		mapping(address => mapping(bytes32 => uint32)) _userActiveDealsCount;
		// True if AutomaticDissolution was triggered
		bool _isInDissolution;
	}

	/**
	 * @dev     https://dev.to/mudgen/how-diamond-storage-works-90e
	 * @return  s  Returns a pointer to an "arbitrary" location in memory
	 */
	function getStorage() external pure returns (CerchiaDRTStorage storage s) {
		bytes32 position = CERCHIA_DRT_STORAGE_SLOT;
		assembly {
			s.slot := position
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library LibCommonOperations {
	uint64 public constant SECONDS_IN_A_DAY = 24 * 60 * 60;
	uint64 private constant VALID_BLOCK_TIMESTAMP_LIMIT = 10;

	// A block with a timestamp more than 10 seconds in the future will not be considered valid.
	// However, a block with a timestamp more than 10 seconds in the past,
	// will still be considered valid as long as its timestamp
	// is greater than or equal to the timestamp of its parent block.
	// https://github.com/ava-labs/coreth/blob/master/README.md#block-timing
	function _isValidBlockTimestamp(uint64 unixTimestamp) internal view returns (bool) {
		// solhint-disable-next-line not-rely-on-time
		return unixTimestamp < (block.timestamp + VALID_BLOCK_TIMESTAMP_LIMIT);
	}

	/**
	 * @dev     Our project operates with exact timestamps only (think 2022-07-13 00:00:00), sent as Unix Epoch
	 * @param   unixTimestamp  Unix Epoch to be divisible by number of seconds in a day
	 * @return  bool  True if unixTimestamp % SECONDS_IN_A_DAY == 0
	 */
	function _isExactDate(uint64 unixTimestamp) internal pure returns (bool) {
		return unixTimestamp % SECONDS_IN_A_DAY == 0;
	}

	/**
	 * @param   token  Address stored in our contract, for a token symbol
	 * @return  bool  True if address is not address(0)
	 */
	function _tokenExists(address token) internal pure returns (bool) {
		return token != address(0);
	}

	/**
	 * @param   valueToVerify  String to check if is not empty
	 * @return  bool  True if string is not empty
	 */
	function _isNotEmpty(string calldata valueToVerify) internal pure returns (bool) {
		return (bytes(valueToVerify).length > 0);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { LibStructStorage } from "../libraries/LibStructStorage.sol";

library LibDealsSet {
	// Data structure for efficient CRUD operations
	// Holds an array of deals, and a mapping pointing from dealId to deal's index in the array
	struct DealsSet {
		// mapping(dealId => _deals array index position)
		mapping(uint256 => uint256) _dealsIndexer;
		// deals array
		LibStructStorage.Deal[] _deals;
		// keeping track of last inserted deal id and increment when adding new items
		uint256 _lastDealId;
	}

	/**
	 * @param   self  Library
	 * @param   deal  Deal to be inserted
	 * @return  returnedDealId  Id of the new deal
	 */
	function insert(
		DealsSet storage self,
		LibStructStorage.Deal memory deal
	) internal returns (uint256 returnedDealId) {
		// First, assign a consecutive new dealId to this object
		uint256 dealId = self._lastDealId + 1;
		// The next row index (0 based) will actually be the count of deals
		uint256 indexInDealsArray = count(self);

		// Store the indexInDealsArray for this newly added deal
		self._dealsIndexer[dealId] = indexInDealsArray;

		// Also store the dealId and row index on the deal object
		deal.indexInDealsArray = self._dealsIndexer[dealId];
		deal.id = dealId;

		// Add the object to the array, and keep track in the mapping, of the array index where we just added the new item
		self._deals.push(deal);

		// Lastly, Increase the counter with the newly added item
		self._lastDealId = dealId;

		// return the new deal id, in case we need it somewhere else
		return dealId;
	}

	/**
	 * @dev     Reverts if deal doesn't exist
	 * @dev     Caller should validate dealId first exists
	 * @param   self  Library
	 * @param   dealId  Id of deal to be deleted
	 */
	function deleteById(DealsSet storage self, uint256 dealId) internal {
		// If we're deleting the last item in the array, there's nothing left to move
		// Otherwise, move the last item in the array, in the position of the item being deleted
		if (count(self) > 1) {
			// Find the row index to delete. We'll also use this for the last item in the array to take its place
			uint256 indexInDealsArray = self._dealsIndexer[dealId];

			// Position of items being deleted, gets replaced by the last item in the list
			self._deals[indexInDealsArray] = self._deals[count(self) - 1];

			// At this point, the last item in the deals array took place of item being deleted
			// so we need to update its index, in the deal object,
			// and also in the mapping of dealId to its corresponding row
			self._deals[indexInDealsArray].indexInDealsArray = indexInDealsArray;
			self._dealsIndexer[self._deals[indexInDealsArray].id] = indexInDealsArray;
		}

		// Remove the association of dealId being deleted to the row
		delete self._dealsIndexer[dealId];

		// Pop an item from the _deals array (last one that we moved)
		// We already have it at position where we did the replace
		self._deals.pop();
	}

	/**
	 * @param   self  Library
	 * @return  uint  Number of deals in the contract
	 */
	function count(DealsSet storage self) internal view returns (uint) {
		return (self._deals.length);
	}

	/**
	 * @param   self  Library
	 * @param   dealId  Id of the deal we want to see if it exists
	 * @return  bool  True if deal with such id exists
	 */
	function exists(DealsSet storage self, uint256 dealId) internal view returns (bool) {
		// If there are no deals, we will be certain item is not there
		if (self._deals.length == 0) {
			return false;
		}

		uint256 arrayIndex = self._dealsIndexer[dealId];

		// To check if an items exists, we first check that the deal id matched,
		// but remember empty objects in solidity would also have dealId equal to zero (default(uint256)),
		// so we also check that the initiator is a non-empty address
		return self._deals[arrayIndex].id == dealId && self._deals[arrayIndex].initiator != address(0);
	}

	/**
	 * @dev     Given a dealId, returns its' index in the _deals array
	 * @dev     Caller should validate dealId first exists
	 * @param   self  Library
	 * @param   dealId  Id of the deal to return index for
	 * @return  uint256  Index of the dealid, in the _deals array
	 */
	function getIndex(DealsSet storage self, uint256 dealId) internal view returns (uint256) {
		return self._dealsIndexer[dealId];
	}

	/**
	 * @dev     Returns a deal, given a dealId
	 * @dev     Caller should validate dealId first exists
	 * @param   self  Library
	 * @param   dealId  Id of the deal to return
	 * @return  LibStructStorage.Deal Deal with dealId
	 */
	function getById(DealsSet storage self, uint256 dealId) internal view returns (LibStructStorage.Deal storage) {
		return self._deals[self._dealsIndexer[dealId]];
	}

	/**
	 * @param   self  Library
	 * @return  lastDealId  The id asssigned to the last inserted deal
	 */
	function getLastDealId(DealsSet storage self) internal view returns (uint256) {
		return self._lastDealId;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IAccessControl } from "./interfaces/IAccessControl.sol";
import { IGetEntityFacet } from "./interfaces/IGetEntityFacet.sol";

import { LibStructStorage } from "./libraries/LibStructStorage.sol";

contract RoleBased {
	/**
	 * @dev     Prevents calling a function from anyone not being a user
	 * @param   callerAddress  The msg.sender that called KYXProvider and was forwarded after KYX
	 */
	modifier onlyUser(address callerAddress) {
		require(IAccessControl(address(this)).isUser(callerAddress), LibStructStorage.SHOULD_BE_END_USER);
		_;
	}

	/**
	 * @dev  Prevents calling a function from anyone not being the owner
	 */
	modifier onlyOwner() {
		require(
			IAccessControl(address(this)).hasRole(LibStructStorage.OWNER_ROLE, msg.sender),
			LibStructStorage.SHOULD_BE_OWNER
		);
		_;
	}

	/**
	 * @dev Prevents calling a function if users are restricted to claimback only
	 */
	modifier notRestrictedToUserClaimBack() {
		require(!IGetEntityFacet(address(this)).isRestrictedToUserClaimBack(), LibStructStorage.ONLY_CLAIMBACK_ALLOWED);

		_;
	}
}