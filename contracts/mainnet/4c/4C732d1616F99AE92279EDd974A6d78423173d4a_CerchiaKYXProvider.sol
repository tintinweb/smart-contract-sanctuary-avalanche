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

import { ICerchiaDRT } from "../interfaces/ICerchiaDRT.sol";
import { IMatchDeal } from "../interfaces/IMatchDeal.sol";
import { IClaimBackFacet } from "../interfaces/IClaimBackFacet.sol";
import { IAnyAccountOperationsFacet } from "../interfaces/IAnyAccountOperationsFacet.sol";
import { ICerchiaKYXProvider } from "./ICerchiaKYXProvider.mock.sol";

contract CerchiaKYXProvider is ICerchiaKYXProvider {
	address private immutable _cerchiaDiamondAddress;

	constructor(address cerchiaDiamondAddress) {
		_cerchiaDiamondAddress = cerchiaDiamondAddress;
	}

	function userCreateNewDealAsBid(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external override {
		return
			ICerchiaDRT(_cerchiaDiamondAddress).userCreateNewDealAsBid(
				msg.sender,
				symbol,
				denomination,
				notional,
				premium,
				expiryDate
			);
	}

	function userCreateNewDealAsAsk(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external override {
		return
			ICerchiaDRT(_cerchiaDiamondAddress).userCreateNewDealAsAsk(
				msg.sender,
				symbol,
				denomination,
				notional,
				premium,
				expiryDate
			);
	}

	function userUpdateDealToCancel(uint256 dealId) external override {
		return ICerchiaDRT(_cerchiaDiamondAddress).userUpdateDealToCancel(msg.sender, dealId);
	}

	function userUpdateDealFromBidToMatched(uint256 dealId) external override {
		return IMatchDeal(_cerchiaDiamondAddress).userUpdateDealFromBidToMatched(msg.sender, dealId);
	}

	function userUpdateDealFromAskToMatched(uint256 dealId) external override {
		return IMatchDeal(_cerchiaDiamondAddress).userUpdateDealFromAskToMatched(msg.sender, dealId);
	}

	function initiateIndexDataUpdate(bytes32 configurationId, uint64 timestamp) external override {
		return
			IAnyAccountOperationsFacet(_cerchiaDiamondAddress).initiateIndexDataUpdate(
				msg.sender,
				configurationId,
				timestamp
			);
	}

	function processContingentSettlement(uint64 timestamp, uint256 dealId) external override {
		return
			IAnyAccountOperationsFacet(_cerchiaDiamondAddress).processContingentSettlement(
				msg.sender,
				timestamp,
				dealId
			);
	}

	function claimBack(uint256 dealId) external override {
		return IClaimBackFacet(_cerchiaDiamondAddress).claimBack(msg.sender, dealId);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICerchiaKYXProvider {
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

	function userUpdateDealToCancel(uint256 dealId) external;

	function userUpdateDealFromBidToMatched(uint256 dealId) external;

	function userUpdateDealFromAskToMatched(uint256 dealId) external;

	function initiateIndexDataUpdate(bytes32 configurationId, uint64 timestamp) external;

	function processContingentSettlement(uint64 timestamp, uint256 dealId) external;

	function claimBack(uint256 dealId) external;
}