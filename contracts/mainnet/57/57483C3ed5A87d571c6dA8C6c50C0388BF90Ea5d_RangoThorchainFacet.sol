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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../../../interfaces/IThorchainRouter.sol";
import "../../../interfaces/IRangoThorchain.sol";
import "../../../interfaces/IRango.sol";
import "../../../libraries/LibSwapper.sol";
import "../../../utils/ReentrancyGuard.sol";

/// @title A contract to handle interactions with Thorchain Router contract on evm chains.
/// @author Thinking Particle
/// @notice This facet interacts with thorchain router.
/// @dev This contract checks for basic validation and also checks that provided thorchain router is whitelisted.
contract RangoThorchainFacet is IRango, IRangoThorchain, ReentrancyGuard {
    /// @notice emitted to notify that a swap to thorchain has been initiated by rango and provides the parameters used for the swap.
    /// @param vault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param token The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param memo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    event ThorchainTxInitiated(address vault, address token, uint amount, string memo, uint expiration);

    receive() external payable {}

    /// @notice Swap tokens if necessary, then pass it to RangoThorchain
    /// @dev Swap tokens if necessary, then pass it to RangoThorchain. If no swap is required (calls.length==0) the provided token is passed to RangoThorchain without change.
    /// @param request The swap information used to check input and output token addresses and balances, as well as the fees if any. Together with calls param, determines the swap logic before passing to Thorchain.
    /// @param calls The contract call data that is used to swap (can be empty if no swap is needed). Together with request param, determines the swap logic before passing to Thorchain.
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function thorchainSwapAndBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable nonReentrant {
        (uint out,) = LibSwapper.onChainSwapsPreBridge(request, calls, 0);
        if (request.toToken != LibSwapper.ETH) {
            LibSwapper.approve(request.toToken, tcRouter, out);
        }

        doSwapInToThorchain(
            request.toToken,
            out,
            tcRouter,
            tcVault,
            thorchainMemo,
            expiration
        );
        // event emission
        emit RangoBridgeInitiated(
            request.requestId,
            request.toToken,
            out,
            LibSwapper.ETH,
            "",
            0,
            false,
            false,
            uint8(BridgeType.Thorchain),
            request.dAppTag
        );
    }

    /// @notice Do a swap through thorchain
    /// @param request The necessary data for bridging
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function thorchainBridge(
        RangoBridgeRequest memory request,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable nonReentrant {
        uint amount = request.amount;
        uint amountWithFee = amount + LibSwapper.sumFees(request);
        address token = request.token;
        if (token == LibSwapper.ETH) {
            require(msg.value >= amountWithFee, "insufficient ETH sent");
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amountWithFee);
            LibSwapper.approve(request.token, tcRouter, amount);
        }
        LibSwapper.collectFees(request);

        doSwapInToThorchain(
            token,
            amount,
            tcRouter,
            tcVault,
            thorchainMemo,
            expiration
        );

        // event emission
        emit RangoBridgeInitiated(
            request.requestId,
            token,
            amount,
            LibSwapper.ETH,
            "",
            0,
            false,
            false,
            uint8(BridgeType.Thorchain),
            request.dAppTag
        );
    }

    /// @notice Defines parameters used for swapIn functionality on thorchain router.
    /// @param token The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function doSwapInToThorchain(
        address token,
        uint amount,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) internal {
        LibSwapper.BaseSwapperStorage storage baseStorage = LibSwapper.getBaseSwapperStorage();
        require(baseStorage.whitelistContracts[tcRouter], "given thorchain router not whitelisted");

        IThorchainRouter(tcRouter).depositWithExpiry{value : token == LibSwapper.ETH ? amount : 0}(
            payable(tcVault), // address payable vault,
            token, // address asset,
            amount, // uint amount,
            thorchainMemo, // string calldata memo,
            expiration  // uint expiration) external payable;
        );
        emit ThorchainTxInitiated(tcVault, token, amount, thorchainMemo, expiration);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IRango {
    struct RangoBridgeRequest {
        string requestId;
        address token;
        uint amount;
        uint platformFee;
        uint affiliateFee;
        address payable affiliatorAddress;
        uint destinationExecutorFee;
        uint16 dAppTag;
    }

    enum BridgeType { Across, CBridge, Hop, Hyphen, Multichain, Stargate, Synapse, Thorchain, Symbiosis, Axelar, Voyager, Poly, OptimismBridge, ArbitrumBridge, Wormhole }

    /// @notice Status of cross-chain swap
    /// @param Created It's sent to bridge and waiting for bridge response
    /// @param Succeeded The whole process is success and end-user received the desired token in the destination
    /// @param RefundInSource Bridge was out of liquidity and middle asset (ex: USDC) is returned to user on source chain
    /// @param RefundInDestination Our handler on dest chain this.executeMessageWithTransfer failed and we send middle asset (ex: USDC) to user on destination chain
    /// @param SwapFailedInDestination Everything was ok, but the final DEX on destination failed (ex: Market price change and slippage)
    enum CrossChainOperationStatus {
        Created,
        Succeeded,
        RefundInSource,
        RefundInDestination,
        SwapFailedInDestination
    }

    event RangoBridgeInitiated(
        string indexed requestId,
        address bridgeToken,
        uint256 bridgeAmount,
        address receiver,
        bytes32 payloadHash,
        uint destinationChainId,
        bool hasInterchainMessage,
        bool hasDestinationSwap,
        uint8 indexed bridgeId,
        uint16 indexed dAppTag
    );

    event RangoBridgeCompleted(
        string indexed requestId,
        address indexed token,
        address indexed originalSender,
        address receiver,
        uint amount,
        CrossChainOperationStatus status
    );

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../libraries/LibSwapper.sol";
import "./IRango.sol";

/// @title Interface to interact with RangoThorchain contract.
/// @author Thinking Particle
interface IRangoThorchain {

    function thorchainSwapAndBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,

        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable;

    function thorchainBridge(
        IRango.RangoBridgeRequest memory request,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @dev based on thorchain router https://gitlab.com/thorchain/ethereum/eth-router/-/blob/29b59c2d6c6fc7a65d6bbc0f80d90694ac4122f8/contracts/THORChain_Aggregator.sol#L12
interface IThorchainRouter {
    /// @param vault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param asset The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param memo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint amount,
        string calldata memo,
        uint expiration
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IRango.sol";

/// @title BaseSwapper
/// @author 0xiden
/// @notice library to provide swap functionality
library LibSwapper {

    /// @dev keccak256("exchange.rango.library.swapper")
    bytes32 internal constant BASE_SWAPPER_NAMESPACE = hex"43da06808a8e54e76a41d6f7b48ddfb23969b1387a8710ef6241423a5aefe64a";

    address payable constant ETH = payable(0x0000000000000000000000000000000000000000);

    struct BaseSwapperStorage {
        address payable feeContractAddress;
        address WETH;
        mapping(address => bool) whitelistContracts;
        mapping(address => mapping(bytes4 => bool)) whitelistMethods;
    }

    /// @notice Emitted if any fee transfer was required
    /// @param token The address of received token, address(0) for native
    /// @param affiliatorAddress The address of affiliate wallet
    /// @param platformFee The amount received as platform fee
    /// @param destinationExecutorFee The amount received to execute transaction on destination (only for cross chain txs)
    /// @param affiliateFee The amount received by affiliate
    /// @param dAppTag Optional identifier to make tracking easier.
    event FeeInfo(
        address token,
        address indexed affiliatorAddress,
        uint platformFee,
        uint destinationExecutorFee,
        uint affiliateFee,
        uint16 indexed dAppTag
    );

    /// @notice A call to another dex or contract done and here is the result
    /// @param target The address of dex or contract that is called
    /// @param success A boolean indicating that the call was success or not
    /// @param returnData The response of function call
    event CallResult(address target, bool success, bytes returnData);

    /// @notice A swap request is done and we also emit the output
    /// @param requestId Optional parameter to make tracking of transaction easier
    /// @param fromToken Input token address to be swapped from
    /// @param toToken Output token address to be swapped to
    /// @param amountIn Input amount of fromToken that is being swapped
    /// @param dAppTag Optional identifier to make tracking easier
    /// @param outputAmount The output amount of the swap, measured by the balance change before and after the swap
    event RangoSwap(
        string indexed requestId,
        address fromToken,
        address toToken,
        uint amountIn,
        uint minimumAmountExpected,
        uint16 indexed dAppTag,
        uint outputAmount
    );

    /// @notice Output amount of a dex calls is logged
    /// @param _token The address of output token, ZERO address for native
    /// @param amount The amount of output
    event DexOutput(address _token, uint amount);

    /// @notice The output money (ERC20/Native) is sent to a wallet
    /// @param _token The token that is sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address
    event SendToken(address _token, uint256 _amount, address _receiver);


    /// @notice Notifies that Rango's fee receiver address updated
    /// @param _oldAddress The previous fee wallet address
    /// @param _newAddress The new fee wallet address
    event FeeContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @dev swapFromToken and amount parameters are only helper params and the actual amount and
    /// token are set in callData
    /// @param spender The contract which the approval is given to if swapFromToken is not native.
    /// @param target The dex contract address that should be called
    /// @param swapFromToken Token address of to be used in the swap.
    /// @param amount The amount to be approved or native amount sent.
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct Call {
        address spender;
        address payable target;
        address swapFromToken;
        address swapToToken;
        bool needsTransferFromUser;
        uint amount;
        bytes callData;
    }

    /// @notice General swap request which is given to us in all relevant functions
    /// @param requestId The request id passed to make tracking transactions easier
    /// @param fromToken The source token that is going to be swapped (in case of simple swap or swap + bridge) or the briding token (in case of solo bridge)
    /// @param toToken The output token of swapping. This is the output of DEX step and is also input of bridging step
    /// @param amountIn The amount of input token to be swapped
    /// @param platformFee The amount of fee charged by platform
    /// @param destinationExecutorFee The amount of fee required for relayer execution on the destination
    /// @param affiliateFee The amount of fee charged by affiliator dApp
    /// @param affiliatorAddress The wallet address that the affiliator fee should be sent to
    /// @param minimumAmountExpected The minimum amount of toToken expected after executing Calls
    /// @param dAppTag An optional parameter
    struct SwapRequest {
        string requestId;
        address fromToken;
        address toToken;
        uint amountIn;
        uint platformFee;
        uint destinationExecutorFee;
        uint affiliateFee;
        address payable affiliatorAddress;
        uint minimumAmountExpected;
        uint16 dAppTag;
    }

    /// @notice initializes the base swapper and sets the init params (such as Wrapped token address)
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    function setWeth(address _weth) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        baseStorage.WETH = _weth;
    }

    /// @notice Sets the wallet that receives Rango's fees from now on
    /// @param _address The receiver wallet address
    function updateFeeContractAddress(address payable _address) internal {
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        address oldAddress = baseSwapperStorage.feeContractAddress;
        baseSwapperStorage.feeContractAddress = _address;

        emit FeeContractAddressUpdated(oldAddress, _address);
    }

    /// Whitelist ///

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    function addWhitelist(address contractAddress) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        baseStorage.whitelistContracts[contractAddress] = true;
    }

    /// @notice Adds a method of contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    /// @param methodIds The method of the DEX
    function addMethodWhitelists(address contractAddress, bytes4[] calldata methodIds) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        baseStorage.whitelistContracts[contractAddress] = true;
        for (uint i = 0; i < methodIds.length; i++)
            baseStorage.whitelistMethods[contractAddress][methodIds[i]] = true;
    }

    /// @notice Adds a method of contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    /// @param methodId The method of the DEX
    function addMethodWhitelist(address contractAddress, bytes4 methodId) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        baseStorage.whitelistContracts[contractAddress] = true;
        baseStorage.whitelistMethods[contractAddress][methodId] = true;
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    function removeWhitelist(address contractAddress) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        require(baseStorage.whitelistContracts[contractAddress], 'Contract not found');
        delete baseStorage.whitelistContracts[contractAddress];
    }

    /// @notice Removes a method of contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    /// @param methodId The method of the DEX
    function removeMethodWhitelist(address contractAddress, bytes4 methodId) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        require(baseStorage.whitelistMethods[contractAddress][methodId], 'Contract not found');
        delete baseStorage.whitelistMethods[contractAddress][methodId];
    }

    function onChainSwapsPreBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        uint extraFee
    ) internal returns (uint out, uint value) {

        bool isNative = request.fromToken == ETH;
        uint minimumRequiredValue = (isNative ? request.platformFee + request.affiliateFee + request.amountIn + request.destinationExecutorFee : 0) + extraFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount + fee');

        (, out) = onChainSwapsInternal(request, calls, extraFee);

        value = (request.toToken == ETH ? (out > 0 ? out : request.amountIn) : 0) + extraFee;
        return (out, value);
    }

    /// @notice Internal function to compute output amount of DEXes
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param extraNativeFee The amount of native tokens to keep and not return to user as excess amount.
    /// @return The response of all DEX calls and the output amount of the whole process
    function onChainSwapsInternal(
        SwapRequest memory request,
        Call[] calldata calls,
        uint256 extraNativeFee
    ) internal returns (bytes[] memory, uint) {

        uint toBalanceBefore = getBalanceOf(request.toToken);
        uint fromBalanceBefore = getBalanceOf(request.fromToken);

        // transfer tokens from user for swaps that require it.
        transferTokensFromUser(calls);

        bytes[] memory result = callSwapsAndFees(request, calls);

        // check if any extra tokens were taken from contract and return excess tokens if any.
        returnExcessAmounts(request, calls);

        // get balance after returning excesses.
        uint fromBalanceAfter = getBalanceOf(request.fromToken);

        // check over-expense of fromToken and return excess if any.
        if (request.fromToken != ETH) {
            require(fromBalanceAfter >= fromBalanceBefore, "Source token balance on contract must not decrease after swap");
            if (fromBalanceAfter > fromBalanceBefore)
                _sendToken(request.fromToken, fromBalanceAfter - fromBalanceBefore, msg.sender);
        }
        else {
            require(fromBalanceAfter >= fromBalanceBefore - msg.value, "Source token balance on contract must not decrease after swap");
            // When we are keeping extraNativeFee for bridgingFee, we should consider it in calculations.
            if (fromBalanceAfter > fromBalanceBefore - msg.value + extraNativeFee)
                _sendToken(request.fromToken, fromBalanceAfter + msg.value - fromBalanceBefore - extraNativeFee, msg.sender);
        }

        uint toBalanceAfter = getBalanceOf(request.toToken);

        uint secondaryBalance = toBalanceAfter - toBalanceBefore;
        require(secondaryBalance >= request.minimumAmountExpected, "Output is less than minimum expected");

        emitSwapEvent(request, secondaryBalance);

        return (result, secondaryBalance);
    }

    /// @notice Private function to handle fetching money from wallet to contract, reduce fee/affiliate, perform DEX calls
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @dev It checks the whitelisting of all DEX addresses + having enough msg.value as input
    /// @return The bytes of all DEX calls response
    function callSwapsAndFees(SwapRequest memory request, Call[] calldata calls) private returns (bytes[] memory) {
        bool isSourceNative = request.fromToken == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        for (uint256 i = 0; i < calls.length; i++) {
            require(baseSwapperStorage.whitelistContracts[calls[i].spender], "Contract spender not whitelisted");
            require(baseSwapperStorage.whitelistContracts[calls[i].target], "Contract target not whitelisted");
            bytes4 sig = bytes4(calls[i].callData[: 4]);
            require(baseSwapperStorage.whitelistMethods[calls[i].target][sig], "Unauthorized call data!");
        }

        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            _sendToken(request.fromToken, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.fromToken, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
        }

        // emit Fee event
        if (hasPlatformFee || hasDestExecutorFee || hasAffiliateFee) {
            emit FeeInfo(
                request.fromToken,
                request.affiliatorAddress,
                request.platformFee,
                request.destinationExecutorFee,
                request.affiliateFee,
                request.dAppTag
            );
        }

        // Execute swap Calls
        bytes[] memory returnData = new bytes[](calls.length);
        address tmpSwapFromToken;
        for (uint256 i = 0; i < calls.length; i++) {
            tmpSwapFromToken = calls[i].swapFromToken;
            bool isTokenNative = tmpSwapFromToken == ETH;
            if (isTokenNative == false)
                approve(tmpSwapFromToken, calls[i].spender, calls[i].amount);

            (bool success, bytes memory ret) = isTokenNative
            ? calls[i].target.call{value : calls[i].amount}(calls[i].callData)
            : calls[i].target.call(calls[i].callData);

            emit CallResult(calls[i].target, success, ret);
            if (!success)
                revert(_getRevertMsg(ret));
            returnData[i] = ret;
        }

        return returnData;
    }

    /// @notice Approves an ERC20 token to a contract to transfer from the current contract
    /// @param token The address of an ERC20 token
    /// @param to The contract address that should be approved
    /// @param value The amount that should be approved
    function approve(address token, address to, uint value) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(token), to, value);
    }

    function _sendToken(address _token, uint256 _amount, address _receiver) internal {
        (_token == ETH) ? _sendNative(_receiver, _amount) : SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
    }

    function sumFees(IRango.RangoBridgeRequest memory request) internal pure returns (uint256) {
        return request.platformFee + request.affiliateFee + request.destinationExecutorFee;
    }

    function collectFees(IRango.RangoBridgeRequest memory request) internal {
        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        bool hasAnyFee = hasPlatformFee || hasDestExecutorFee || hasAffiliateFee;
        if (!hasAnyFee) {
            return;
        }
        bool isSourceNative = request.token == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            _sendToken(request.token, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.token, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
        }

        // emit Fee event
        emit FeeInfo(
            request.token,
            request.affiliatorAddress,
            request.platformFee,
            request.destinationExecutorFee,
            request.affiliateFee,
            request.dAppTag
        );
    }

    function collectFeesFromSender(IRango.RangoBridgeRequest memory request) internal {
        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        bool hasAnyFee = hasPlatformFee || hasDestExecutorFee || hasAffiliateFee;
        if (!hasAnyFee) {
            return;
        }
        bool isSourceNative = request.token == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            if (isSourceNative)
                _sendToken(request.token, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
            else
                SafeERC20.safeTransferFrom(
                    IERC20(request.token),
                    msg.sender,
                    baseSwapperStorage.feeContractAddress,
                    request.platformFee + request.destinationExecutorFee
                );
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            if (isSourceNative)
                _sendToken(request.token, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
            else
                SafeERC20.safeTransferFrom(
                    IERC20(request.token),
                    msg.sender,
                    request.affiliatorAddress,
                    request.affiliateFee
                );
        }

        // emit Fee event
        emit FeeInfo(
            request.token,
            request.affiliatorAddress,
            request.platformFee,
            request.destinationExecutorFee,
            request.affiliateFee,
            request.dAppTag
        );
    }

    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    /// @param _nativeOut means the output is native token
    /// @param _withdraw If true, indicates that we should swap WETH to ETH before sending the money and _nativeOut must also be true
    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw
    ) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        emit SendToken(_token, _amount, _receiver);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.WETH, "token mismatch");
                IWETH(baseStorage.WETH).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
        }
    }

    /// @notice An internal function to send native token to a contract or wallet
    /// @param _receiver The address that will receive the native token
    /// @param _amount The amount of the native token that should be sent
    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent,) = _receiver.call{value : _amount}("");
        require(sent, "failed to send native");
    }


    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseSwapperStorage() internal pure returns (BaseSwapperStorage storage s) {
        bytes32 namespace = BASE_SWAPPER_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice To extract revert message from a DEX/contract call to represent to the end-user in the blockchain
    /// @param _returnData The resulting bytes of a failed call to a DEX or contract
    /// @return A string that describes what was the error
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    function getBalanceOf(address token) internal view returns (uint) {
        return token == ETH ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    function getBalancesList(Call[] calldata calls) internal view returns (uint256[] memory) {
        uint callsLength = calls.length;
        uint256[] memory balancesList = new uint256[](callsLength);
        address token;
        for (uint256 i = 0; i < callsLength; i++) {
            token = calls[i].swapToToken;
            balancesList[i] = getBalanceOf(token);
            if (token == ETH)
                balancesList[i] -= msg.value;
        }
        return balancesList;
    }
    /// This function iterates on calls and if needsTransferFromUser
    function transferTokensFromUser(Call[] calldata calls) internal {
        uint callsLength = calls.length;
        Call calldata call;
        address token;
        for (uint256 i = 0; i < callsLength; i++) {
            call = calls[i];
            token = call.swapFromToken;
            if (call.needsTransferFromUser && token != ETH)
                SafeERC20.safeTransferFrom(IERC20(call.swapFromToken), msg.sender, address(this), call.amount);
        }
    }

    /// @dev returns any excess token left by the contract.
    /// We iterate over `swapToToken`s because each swapToToken is either the request.toToken or is the output of
    /// another `Call` in the list of swaps which itself either has transferred tokens from user,
    /// or is a middle token that is the output of another `Call`.
    function returnExcessAmounts(SwapRequest memory request, Call[] calldata calls) internal {
        uint256[] memory initialBalancesList = getBalancesList(calls);
        uint excessAmountToToken;
        address tmpSwapToToken;
        uint currentBalanceTo;
        for (uint256 i = 0; i < calls.length; i++) {
            tmpSwapToToken = calls[i].swapToToken;
            currentBalanceTo = getBalanceOf(tmpSwapToToken);
            excessAmountToToken = currentBalanceTo - initialBalancesList[i];
            if (excessAmountToToken > 0 && tmpSwapToToken != request.toToken) {
                _sendToken(tmpSwapToToken, excessAmountToToken, msg.sender);
            }
        }
    }

    function emitSwapEvent(SwapRequest memory request, uint output) private {
        emit RangoSwap(
            request.requestId,
            request.fromToken,
            request.toToken,
            request.amountIn,
            request.minimumAmountExpected,
            request.dAppTag,
            output
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/// @title Reentrancy Guard
/// @author 
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    /// @dev keccak256("exchange.rango.reentrancyguard");
    bytes32 private constant NAMESPACE = hex"4fe94118b1030ac5f570795d403ee5116fd91b8f0b5d11f2487377c2b0ab2559";

    /// Types ///

    struct ReentrancyStorage {
        uint256 status;
    }

    /// Errors ///

    error ReentrancyError();

    /// Constants ///

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    /// Modifiers ///

    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function reentrancyStorage() private pure returns (ReentrancyStorage storage data) {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}