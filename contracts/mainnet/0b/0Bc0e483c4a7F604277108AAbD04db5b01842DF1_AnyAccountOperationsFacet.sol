// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAnyAccountOperationsFacet } from "../interfaces/IAnyAccountOperationsFacet.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";
import { ICerchiaOracle } from "../interfaces/ICerchiaOracle.sol";
import { IGetEntityFacet } from "../interfaces/IGetEntityFacet.sol";

import { LibCommonOperations } from "../libraries/LibCommonOperations.sol";
import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";

import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";
import { LibAccessControlStorage as ACStorage } from "../libraries/LibAccessControlStorage.sol";

/**
 * @title  CerchiaDRT Diamond's AnyAccount Implementation
 */
contract AnyAccountOperationsFacet is IAnyAccountOperationsFacet {
	using LibDealsSet for LibDealsSet.DealsSet;

	/**
	 * @dev     Our project operates with exact timestamps only (think 2022-07-13 00:00:00), sent as Unix Epoch
	 * @param   unixTimestamp  Unix Epoch to be divisible by number of seconds in a day
	 */
	modifier isExactDate(uint64 unixTimestamp) {
		require(LibCommonOperations._isExactDate(unixTimestamp), LibStructStorage.UNIX_TIMESTAMP_IS_NOT_EXACT_DATE);
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
	 * @dev  Prevents calling a function from anyone not being the Oracle Diamond address
	 */
	modifier onlyOracleAddress() {
		require(
			IAccessControl(address(this)).getOracleAddress() == msg.sender,
			LibStructStorage.CALLER_IS_NOT_ORACLE_ADDRESS
		);

		_;
	}

	/**
	 * @dev Prevents calling a function from anyone not being an operator
	 */
	modifier onlyOperator() {
		require(
			IAccessControl(address(this)).hasRole(LibStructStorage.OPERATOR_ROLE, msg.sender),
			LibStructStorage.ONLY_OPERATOR_ALLOWED
		);
		_;
	}

	/**
	 * @dev Prevents calling a function if operators are deactivated
	 */
	modifier isNotDeactivatedForOperator() {
		require(
			!IGetEntityFacet(address(this)).getIsDeactivatedForOperators(),
			LibStructStorage.DEACTIVATED_FOR_OPERATORS
		);
		_;
	}

	/**
	 * @dev     Prevents calling a function from anyone not being a user
	 * @param   callerAddress  The msg.sender that called KYXProvider and was forwarded after KYX
	 */
	modifier onlyUser(address callerAddress) {
		require(IAccessControl(address(this)).isUser(callerAddress), LibStructStorage.SHOULD_BE_END_USER);
		_;
	}

	/**
	 * @dev     Prevents calling a function from anyone that hasn't passed KYX verification
	 * If call reaches here from KYX Provider, it means caller has been verified and forwarded here.
	 * If call reaches here not from KYX Provider, it means it comes from someone that hasn't gone through verification.
	 */
	modifier isKYXWhitelisted() {
		// If caller has not passed KYC/KYB, should not be able to proceed
		require(IAccessControl(address(this)).isKYXProvider(msg.sender), LibStructStorage.NEED_TO_PASS_KYX);
		_;
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev  To be called on-demand by users
	 */
	function initiateIndexDataUpdate(
		address callerAddress,
		bytes32 configurationId,
		uint64 timestamp
	) external isKYXWhitelisted onlyUser(callerAddress) isExactDate(timestamp) isValidBlockTimestamp(timestamp) {
		// Only users can initiate index data update here. They shouldn't be deactivated
		require(!IGetEntityFacet(address(this)).isRestrictedToUserClaimBack(), LibStructStorage.ONLY_CLAIMBACK_ALLOWED);

		// Users should have Matched/Live deals, for the configurationId at hand,
		// otherwise them initiating update doesn't make sense
		require(
			Storage.getStorage()._userActiveDealsCount[callerAddress][configurationId] > 0,
			LibStructStorage.USER_HAS_NO_ACTIVE_DEALS_FOR_CONFIGURATION_ID
		);

		_initiateIndexDataUpdate(callerAddress, configurationId, timestamp);
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev  For each configurationId, to be called daily by operators
	 */
	function operatorInitiateIndexDataUpdate(
		bytes32 configurationId,
		uint64 timestamp
	) external onlyOperator isNotDeactivatedForOperator isExactDate(timestamp) isValidBlockTimestamp(timestamp) {
		_initiateIndexDataUpdate(msg.sender, configurationId, timestamp);
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev     The second part of the Oracle flow. After the Oracle emits event to be picked up off-chain,
	 *          off-chain components call the Oracle with the required data, which calls back into CerchiaDRT Diamond
	 *          to provide the required data and store it for future computation
	 */
	function indexDataCallBack(
		bytes32 configurationId,
		uint64 timestamp,
		int128 level
	) external onlyOracleAddress isExactDate(timestamp) isValidBlockTimestamp(timestamp) {
		// Revert if level was invalid
		if (level == LibStructStorage.INVALID_LEVEL_VALUE) {
			revert(LibStructStorage.ORACLE_DID_NOT_FULLFIL);
		} else {
			// Otherwise, store level and emit succes event
			Storage.CerchiaDRTStorage storage s = Storage.getStorage();

			s._indexLevels[configurationId][timestamp] = LibStructStorage.IndexLevel(level, true);
			s._indexLevelTimestamps[configurationId].push(timestamp);

			emit IndexDataCallBackSuccess(configurationId, timestamp, level);
		}
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 */
	function processContingentSettlement(
		address callerAddress,
		uint64 timestamp,
		uint256 dealId
	) external isKYXWhitelisted onlyUser(callerAddress) isExactDate(timestamp) isValidBlockTimestamp(timestamp) {
		// Only users  can initiate processContingentSettlement. They shouldn't be deactivated
		require(!IGetEntityFacet(address(this)).isRestrictedToUserClaimBack(), LibStructStorage.ONLY_CLAIMBACK_ALLOWED);

		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		LibStructStorage.Deal storage deal = s._dealsSet.getById(dealId);

		// As a user, should only be able to settle your own deal
		require(
			callerAddress == deal.buyer || callerAddress == deal.seller,
			LibStructStorage.CANNOT_SETTLE_SOMEONE_ELSES_DEAL
		);

		_processContingentSettlement(callerAddress, timestamp, deal);
	}

	/**
	 * @inheritdoc IAnyAccountOperationsFacet
	 * @dev     For each deal, to be called daily by operators, and on-demand by users if they want to
	 */
	function operatorProcessContingentSettlement(
		uint64 timestamp,
		uint256 dealId
	) external onlyOperator isNotDeactivatedForOperator isExactDate(timestamp) isValidBlockTimestamp(timestamp) {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		_processContingentSettlement(msg.sender, timestamp, s._dealsSet.getById(dealId));
	}

	/**
	 * @dev     Helper function for the Oracle flow. Emits event if data already exists for timestamp + configurationId,
	 *          otherwise asks Oracle for data if Oracle is working. If not working, dissolutes current smart contract
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function _initiateIndexDataUpdate(address callerAddress, bytes32 configurationId, uint64 timestamp) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Emit event if level already exists
		if (s._indexLevels[configurationId][timestamp].exists) {
			emit AnyAccountInitiateIndexDataUpdateAlreadyAvailable(
				configurationId,
				timestamp,
				s._indexLevels[configurationId][timestamp].value
			);
		} else {
			address oracleAddress = IAccessControl(address(this)).getOracleAddress();
			// If oracle is working, try to get level. Otherwise, dissolute contract
			if (ICerchiaOracle(oracleAddress).isWorking()) {
				ICerchiaOracle(oracleAddress).getLevel(configurationId, timestamp);
			} else {
				_automaticDissolution(callerAddress, configurationId, timestamp);
			}
		}
	}

	/**
	 * @dev     Helper function to delete all standards, in case of AutomaticDissolution
	 */
	function _deleteAllStandards() private {
		Storage.CerchiaDRTStorage storage cerchiaDRTStorage = Storage.getStorage();

		// Cache array length to save gas
		uint256 standardsLength = cerchiaDRTStorage._standardsKeys.length;

		for (uint i; i < standardsLength; ) {
			delete cerchiaDRTStorage._standards[cerchiaDRTStorage._standardsKeys[i]];

			unchecked {
				++i;
			}
		}
		delete cerchiaDRTStorage._standardsKeys;
	}

	/**
	 * @dev     Helper function to deactivate all functions except user claimback, in case of AutomaticDissolution
	 */
	function _disableEverythingExceptClaimback() private {
		ACStorage.AccessControlStorage storage accessControlStorage = ACStorage.getStorage();

		accessControlStorage._isDeactivatedForOwners = true;
		accessControlStorage._isDeactivatedForOperators = true;
		accessControlStorage._usersCanOnlyClaimBack = true;
	}

	/**
	 * @dev     AutomaticDissolution should make all existing deals available to be claimed back by participant parties,
	 *          delete all standards, disable all functions except user claimback, and emit event
	 * @param   sender  Initiator of the Settlement or Index Data Update processes, which triggered AutomaticDissolution
	 * @param   configurationId  Id of the parameter set for off-chain API, to have index level for
	 * @param   timestamp  Exact timestamp for off-chain API, to have index level for
	 */
	function _automaticDissolution(address sender, bytes32 configurationId, uint64 timestamp) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Flag that makes all deals available to be claimed back by participant parties
		s._isInDissolution = true;

		// Delete all standards
		_deleteAllStandards();

		// Disable all functions except user claimback
		_disableEverythingExceptClaimback();

		// Emit event
		emit AutomaticDissolution(sender, configurationId, timestamp);
	}

	/**
	 * @dev     Helper function to try and settle a deal, for an exact timestamp
	 * @dev     BidLive and AskLive deals are like open offers, and can only expire if date is past expiryDate
	 * @dev     Matched deals can become Live, if date is between the standard's startDate and maturityDate
	 * @dev     If a Matched deal has become Live, it could also settle if date is bigger than standard's startDate
	 * @dev     Live deals can settle, if date is after standard's startDate but before standard's maturityDate
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   date  Timestamp to settle deal for
	 * @param   deal  Deal to try and settle
	 */
	function _processContingentSettlement(
		address callerAddress,
		uint64 date,
		LibStructStorage.Deal storage deal
	) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		if (deal.state == LibStructStorage.DealState.BidLive || deal.state == LibStructStorage.DealState.AskLive) {
			// If deal is BidLive or AskLive, and we are past expiration date, expire deal and send back funds to initiator
			// Otherwise, there is nothing to be done
			if (date >= deal.expiryDate) {
				uint256 dealId = deal.id;
				address initiator = deal.initiator;
				LibStructStorage.DealState dealState = deal.state;
				IERC20 token = IERC20(deal.voucher.token);
				uint128 fundsToReturn = deal.funds;

				// No need to check if deal exists, reaching this point means it exists
				// Delete expired deal
				s._dealsSet.deleteById(dealId);

				// Emit the correct event
				if (dealState == LibStructStorage.DealState.BidLive) {
					emit BidLiveDealExpired(dealId, initiator, fundsToReturn);
				} else {
					emit AskLiveDealExpired(dealId, initiator, fundsToReturn);
				}

				// Transfer funds back to initiator of deal, since BidLive/AskLive
				// implies either buyer of seller are involved, but not both
				require(token.transfer(initiator, fundsToReturn), LibStructStorage.TOKEN_TRANSFER_FAILED);
			}
		} else if (deal.state == LibStructStorage.DealState.Matched) {
			// If startDate <= date <= maturityDate, deal should become Live
			if (deal.voucher.startDate <= date && date <= deal.voucher.maturityDate) {
				address oracleAddress = IAccessControl(address(this)).getOracleAddress();
				if (!ICerchiaOracle(oracleAddress).isWorking()) {
					_automaticDissolution(callerAddress, deal.voucher.configurationId, date);
				} else {
					deal.state = LibStructStorage.DealState.Live;
					emit MatchedDealWentLive(deal.id);

					// A Live deal where startDate < date <= maturityDate should attempt to trigger
					if (deal.voucher.startDate < date) {
						_processEoDForLiveDeal(date, deal);
					}
				}
			}
		} else if (deal.state == LibStructStorage.DealState.Live) {
			// A Live deal where startDate < date <= maturityDate should attempt to trigger
			if (deal.voucher.startDate < date && date <= deal.voucher.maturityDate) {
				_processEoDForLiveDeal(date, deal);
			}
		}
	}

	/**
	 * @dev     During Settlement, if a deal is Live and after the standard's startDate, its' strike can be compared
	 *          to the existing levels, which can trigger or mature the deal
	 * @dev     Should revert if there is no index level to compare to, for date + configurationId combination
	 * @dev     If triggered (level >= strike), buyer receives notional without fee, fee address receives fee,
	 *          and deal is deleted
	 * @dev     If matured (date >= standard.maturityDate and level is stil < strike), seller receives notional
	 *          without fee, fee address receives fee, and deal is deleted
	 * @param   date  Timestamp to settle deal for
	 * @param   deal  Deal to try and settle
	 */
	function _processEoDForLiveDeal(uint64 date, LibStructStorage.Deal storage deal) private {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		// Revert if no index level to compare to
		LibStructStorage.IndexLevel storage indexLevel = s._indexLevels[deal.voucher.configurationId][date];
		if (!indexLevel.exists) {
			revert(LibStructStorage.SETTLEMENT_INDEX_LEVEL_DOES_NOT_EXIST);
		}

		int128 strike = deal.voucher.strike;
		int128 level = s._indexLevels[deal.voucher.configurationId][date].value;

		address feeAddress = IAccessControl(address(this)).getFeeAddress();
		uint128 fundsToFeeAddress = (deal.voucher.notional * deal.voucher.feeInBps) / LibStructStorage.MAX_FEE_IN_BPS;
		if (level >= strike) {
			// Triggered
			// Should send (fundsToFeeAddress = funds * feeInBps) to feeAddress
			// Should send (fundstoBuyer = funds - funds * feeInBps) to buyer
			uint256 dealId = deal.id;
			address buyer = deal.buyer;
			uint128 fundsToBuyer = deal.funds - fundsToFeeAddress;
			IERC20 token = IERC20(deal.voucher.token);

			// Both userActiveDealsCount should decrement
			s._userActiveDealsCount[buyer][deal.voucher.configurationId]--;
			s._userActiveDealsCount[deal.seller][deal.voucher.configurationId]--;

			// No need to check if deal exists, reaching this point means it exists
			// Deal is triggered so finished, should be deleted
			s._dealsSet.deleteById(dealId);

			// Emit triggered event
			emit LiveDealTriggered(dealId, buyer, fundsToBuyer, feeAddress, fundsToFeeAddress);

			// Send fee to feeAddress and remainder to buyer
			require(token.transfer(feeAddress, fundsToFeeAddress), LibStructStorage.TOKEN_TRANSFER_FAILED);
			require(token.transfer(buyer, fundsToBuyer), LibStructStorage.TOKEN_TRANSFER_FAILED);
		} else {
			if (date >= deal.voucher.maturityDate) {
				// Matured
				// Should send (fundsToFeeAddress = funds * feeInBps) to feeAddress
				// Should send (fundsToSeller = funds - funds * feeInBps) to seller
				uint256 dealId = deal.id;
				address seller = deal.seller;
				uint128 fundsToSeller = deal.funds - fundsToFeeAddress;
				IERC20 token = IERC20(deal.voucher.token);

				// Both userActiveDealsCount should decrement
				s._userActiveDealsCount[deal.buyer][deal.voucher.configurationId]--;
				s._userActiveDealsCount[seller][deal.voucher.configurationId]--;

				// No need to check if deal exists, reaching this point means it exists
				// Deal is matured so finished, should be deleted
				s._dealsSet.deleteById(dealId);

				// Emit matured event
				emit LiveDealMatured(dealId, seller, fundsToSeller, feeAddress, fundsToFeeAddress);

				// Send fee to feeAddress and remainder to seller
				require(token.transfer(feeAddress, fundsToFeeAddress), LibStructStorage.TOKEN_TRANSFER_FAILED);
				require(token.transfer(seller, fundsToSeller), LibStructStorage.TOKEN_TRANSFER_FAILED);
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
	uint64 private constant SECONDS_IN_A_DAY = 24 * 60 * 60;
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