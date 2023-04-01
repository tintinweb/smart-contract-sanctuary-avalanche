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