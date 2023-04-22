// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaOracle } from "./interfaces/ICerchiaOracle.sol";
import { IAnyAccountOperationsFacet } from "./interfaces/IAnyAccountOperationsFacet.sol";
import { IAccessControlOracle } from "./interfaces/IAccessControlOracle.sol";

import { LibStructStorage } from "./libraries/LibStructStorage.sol";
import { LibCerchiaOracleStorage } from "./libraries/LibCerchiaOracleStorage.sol";
import { LibOracleStructStorage } from "./libraries/LibOracleStructStorage.sol";
import { LibCommonOperations } from "./libraries/LibCommonOperations.sol";

contract CerchiaOracle is ICerchiaOracle {
	/**
	 * @dev  Prevents calling a function from anyone not being the owner
	 */
	modifier onlyOwner() {
		require(msg.sender == IAccessControlOracle(address(this)).getOwner(), LibOracleStructStorage.SHOULD_BE_OWNER);
		_;
	}

	/**
	 * @dev Prevents calling a function from anyone but CerchiaDRT Diamond
	 */
	modifier onlyCerchiaDRT() {
		require(
			msg.sender == IAccessControlOracle(address(this)).getCerchiaDRTAddress(),
			LibOracleStructStorage.ORACLE_CALLER_CAN_ONLY_BE_CERCHIA_DRT
		);

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
	 * @dev     Settlement and Index levels related functions should only be called for exact timestamps not in the future
	 * @param   unixTimestamp  Unix Epoch to be checked against the current time on the blockchain
	 */
	modifier isValidBlockTimestamp(uint64 unixTimestamp) {
		require(
			LibCommonOperations._isValidBlockTimestamp(unixTimestamp),
			LibStructStorage.TIMESTAMP_SHOULD_BE_VALID_BLOCK_TIMESTAMP
		);
		_;
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function getLevel(
		bytes32 configurationId,
		uint64 timestamp
	) external onlyCerchiaDRT isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		LibCerchiaOracleStorage.CerchiaOracleStorage storage s = LibCerchiaOracleStorage.getStorage();
		uint256 id = s.requestId;

		s.requests[id] = msg.sender;
		s.requestId++;

		emit GetLevel(msg.sender, id, configurationId, timestamp);
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function ownerSetLevel(
		bytes32 configurationId,
		int128 level,
		uint256 requestId,
		uint64 timestamp,
		bool isValid
	) external onlyOwner isEndOfDate(timestamp) isValidBlockTimestamp(timestamp) {
		LibCerchiaOracleStorage.CerchiaOracleStorage storage s = LibCerchiaOracleStorage.getStorage();

		// Check that request for level hasn't somehow already been fulfilled
		require(s.requests[requestId] != address(0), LibOracleStructStorage.INVALID_REQUEST_ID);

		int128 levelToSend = level;

		// If oracle is not working, or off-chain value received was not value, transmit invalid value to CerchiaDRT
		if (!LibCerchiaOracleStorage.getStorage()._isWorking || !isValid) {
			levelToSend = LibOracleStructStorage.INVALID_LEVEL_VALUE;
		}

		// Request was fulfilled, should delete
		delete s.requests[requestId];

		// Return index level to CerchiaDRT
		IAnyAccountOperationsFacet(IAccessControlOracle(address(this)).getCerchiaDRTAddress()).indexDataCallBack(
			configurationId,
			timestamp,
			levelToSend
		);
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function ownerSetStatus(bool isWorking_) external onlyOwner {
		LibCerchiaOracleStorage.getStorage()._isWorking = isWorking_;
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function isWorking() external view returns (bool) {
		return LibCerchiaOracleStorage.getStorage()._isWorking;
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function getLastRequestIndex() external view returns (uint256 lastRequestId) {
		return LibCerchiaOracleStorage.getStorage().requestId;
	}

	/**
	 * @inheritdoc ICerchiaOracle
	 */
	function getRequestor(uint256 requestId) external view returns (address requestor) {
		return LibCerchiaOracleStorage.getStorage().requests[requestId];
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title  Oracle Diamond Access Control Interface
 * @notice Used to control what functions an address can call
 */
interface IAccessControlOracle {
	/**
	 * @notice Emitted when ownership was transfered to someone else
	 */
	event OwnershipTransfered(address indexed previousOwner, address indexed newOwner);

	/**
	 * @notice Emitted when a new owner was proposed
	 */
	event RequestOwnershipTransfer(address indexed owner, address indexed proposedNewOwner);

	/**
	 * @notice Emitted when a new owner proposal was canceled
	 */
	event CancelOwnershipTransfer(address indexed owner, address indexed canceledProposedNewOwner);

	/**
	 * @param  owner  Address to be the owner of the Oracle Diamond
	 * @param  cerchiaDRT  Address of the CerchiaDRT Diamond
	 */
	function initAccessControlFacet(address owner, address cerchiaDRT) external;

	/**
	 * @notice  For owner, to propose a new owner
	 */
	function requestOwnershipTransfer(address newOwner) external;

	/**
	 * @notice  For proposed new owner, to accept ownership
	 */
	function confirmOwnershipTransfer() external;

	/**
	 * @notice  For owner, to cancel the new owner proposal
	 */
	function cancelOwnershipTransfer() external;

	/**
	 * @notice Returns address of owner
	 */
	function getOwner() external view returns (address);

	/**
	 * @notice Returns address of proposed new owner
	 */
	function getProposedNewOwner() external view returns (address);

	/**
	 * @notice Returns address of CerchiaDRT
	 */
	function getCerchiaDRTAddress() external view returns (address);
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

/**
 * @title  Oracle Diamond's functions, except access control
 */
interface ICerchiaOracle {
	// Emitted by Oracle Diamond, to be picked up by off-chain
	event GetLevel(address sender, uint256 request_id, bytes32 configurationId, uint64 timestamp);

	/**
	 * @dev     Emits GetLevel event, to be picked-up by off-chain listeners and initiate off-chain oracle flow
	 * @dev     Only callable by CerchiaDRT Diamond
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function getLevel(bytes32 configurationId, uint64 timestamp) external;

	/**
	 * @dev     Only callable by Oracle Diamond's owner, to set level for a configurationId + date combination
	 * @dev     Calls back into CerchiaDRT Diamond, to supply requested index level
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   level  Index level gotten from off-chain API
	 * @param   requestId  Request Id to fulfill
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @param   isValid  True if data from off-chain API was valid
	 */
	function ownerSetLevel(
		bytes32 configurationId,
		int128 level,
		uint256 requestId,
		uint64 timestamp,
		bool isValid
	) external;

	/**
	 * @dev     Only callable by Oracle Diamond's owner, to set status for the Oracle
	 * @param   isWorking_  True if off-chain API is working,
	 *                      False otherwise, as Oracle Diamond won't be able to supply data
	 */
	function ownerSetStatus(bool isWorking_) external;

	/**
	 * @return  bool  True if Oracle is working
	 */
	function isWorking() external view returns (bool);

	/**
	 * @return  lastRequestId  The id of the last request
	 */
	function getLastRequestIndex() external view returns (uint256 lastRequestId);

	/**
	 * @param   requestId  Id of a request, to get the address who requested index level
	 * @return  requestor  Address that requested index level, for a given requestId
	 */
	function getRequestor(uint256 requestId) external view returns (address requestor);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @title   Diamond Storage for Oracle Diamond's functions, except access control
 */
library LibCerchiaOracleStorage {
	bytes32 public constant CERCHIA_ORACLE_STORAGE_SLOT = keccak256("CERCHIA.ORACLE.STORAGE");

	/**
	 * @dev https://dev.to/mudgen/how-diamond-storage-works-90e
	 */
	struct CerchiaOracleStorage {
		// Mapping from requestId, to who initiated it. It should always be CerchiaDRT Diamond
		mapping(uint256 => address) requests;
		// Counter for the next requestId to assign to an incoming request
		uint256 requestId;
		// True if Oracle is working
		bool _isWorking;
	}

	/**
	 * @dev     https://dev.to/mudgen/how-diamond-storage-works-90e
	 * @return  s  Returns a pointer to an "arbitrary" location in memory
	 */
	function getStorage() external pure returns (CerchiaOracleStorage storage s) {
		bytes32 position = CERCHIA_ORACLE_STORAGE_SLOT;
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
		return true;
		// return unixTimestamp < (block.timestamp + VALID_BLOCK_TIMESTAMP_LIMIT);
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

/**
 * @title   Wrapper library storing constants and structs of Oracle Diamond
 */
library LibOracleStructStorage {
	// Error codes with descriptive names
	string public constant SHOULD_BE_OWNER = "16";
	string public constant LIB_ORACLE_STORAGE_ALREADY_INITIALIZED = "501";
	string public constant INVALID_REQUEST_ID = "502";
	string public constant LEVEL_DATA_IS_NOT_VALID = "503";
	string public constant ORACLE_IS_NOT_WORKING = "504";
	string public constant ACCOUNT_TO_BE_OWNER_IS_ALREADY_OWNER = "505";
	string public constant ORACLE_CALLER_CAN_ONLY_BE_CERCHIA_DRT = "506";
	string public constant SHOULD_BE_PROPOSED_NEW_OWNER = "507";
	string public constant OWNER_CAN_NOT_BE_CERCHIA_DRT = "508";

	// Value representing invalid index level from off-chain API
	int128 public constant INVALID_LEVEL_VALUE = type(int128).min;
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