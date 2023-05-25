// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IClaimBackFacet } from "../interfaces/IClaimBackFacet.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { LibStructStorage } from "../libraries/LibStructStorage.sol";
import { LibDealsSet } from "../libraries/LibDealsSet.sol";
import { LibCerchiaDRTStorage as Storage } from "../libraries/LibCerchiaDRTStorage.sol";
import { LibAccessControlStorage as ACStorage } from "../libraries/LibAccessControlStorage.sol";

/**
 * @title  CerchiaDRT Diamond Claimback Implementation
 */
contract ClaimBackFacet is IClaimBackFacet {
	using LibDealsSet for LibDealsSet.DealsSet;
	using SafeERC20 for IERC20;
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
	 * @inheritdoc IClaimBackFacet
	 * @dev     Only function allowed once AutomaticDissolution happens, so that we don't lock user funds inside
	 * @dev     Deletes deal if all parties involved have claimed back, emits event, and transfers to user the
	 *          correct amount of funds (depending on user being buyer or seller)
	 */
	function claimBack(address callerAddress, uint256 dealId) external isKYXWhitelisted {
		Storage.CerchiaDRTStorage storage s = Storage.getStorage();

		require(s._dealsSet.exists(dealId), LibStructStorage.DEAL_NOT_FOUND);
		LibStructStorage.Deal storage deal = s._dealsSet.getById(dealId);

		// Can only claim back if contract is in dissolution
		require(s._isInDissolution, LibStructStorage.CANNOT_CLAIM_BACK_UNLESS_IN_DISSOLUTION);

		// Only buyer or seller can claim
		require(
			callerAddress == deal.buyer || callerAddress == deal.seller,
			LibStructStorage.CALLER_IS_NOT_VALID_DEAL_CLAIMER
		);

		uint128 fundsToClaimBack;

		// Buyer (if any) claims back premium
		// Seller (if any) claims back notional - premium
		if (callerAddress == deal.buyer && !deal.buyerHasClaimedBack) {
			fundsToClaimBack = deal.voucher.premium;
			deal.buyerHasClaimedBack = true;
		} else if (callerAddress == deal.seller && !deal.sellerHasClaimedBack) {
			fundsToClaimBack = deal.voucher.notional - deal.voucher.premium;
			deal.sellerHasClaimedBack = true;
		}

		// fundsToClaimback being 0 means caller has already claimed back funds,
		// since we didn't enter any of the above if statements
		require(fundsToClaimBack > 0, LibStructStorage.FUNDS_ALREADY_CLAIMED);

		// One less deal in which msg.sender is involved, if deal was Active (Matched/Live)
		if (deal.state == LibStructStorage.DealState.Matched || deal.state == LibStructStorage.DealState.Live) {
			s._userActiveDealsCount[callerAddress][deal.voucher.configurationId]--;
		}

		// We might delete deal but need token later
		IERC20 token = IERC20(deal.voucher.token);

		// Decrease funds remaining inside deal
		deal.funds = deal.funds - fundsToClaimBack;

		// If there are no more funds, it means everyone claimed back and we should delete deal
		if (deal.funds == 0) {
			// No need to check if deal exists, reaching this point means it exists
			s._dealsSet.deleteById(dealId);
		}

		emit Claimed(dealId, callerAddress, fundsToClaimBack);

		SafeERC20.safeTransfer(token, callerAddress, fundsToClaimBack);
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