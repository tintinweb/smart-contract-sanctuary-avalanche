// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {ExcessivelySafeCall} from "./messaging/libraries/ExcessivelySafeCall.sol";
import {MessageLib} from "./messaging/libraries/MessageLib.sol";

import {SubIndexLib} from "./libraries/SubIndexLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IVaultDeployer} from "./vaults/interfaces/IVaultDeployer.sol";
import {IVault} from "./vaults/interfaces/IVault.sol";
import {GasAllocationViewer} from "./messaging/interfaces/GasAllocationViewer.sol";
import {IReserveVault} from "./interfaces/IReserveVault.sol";

import {RedeemRouter} from "./RedeemRouter.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {MessageRouter} from "./messaging/MessageRouter.sol";

interface TradingModuleErrors {
    error TradingModuleAlreadyInitialized();
    error TradingModuleForbidden();
    error TradingModuleEmptyQuote();
    error TradingModuleInvalid();
}

contract TradingModule is TradingModuleErrors, Initializable {
    using Address for address;
    using SafeTransferLib for ERC20;
    using ExcessivelySafeCall for address;
    using FixedPointMathLib for *;

    uint16 internal constant MAX_RETURN_DATA_SIZE = 150;

    // @dev Address of the vault deployer
    address internal immutable vaultDeployer;

    // @dev Message router address
    address internal immutable messageRouter;

    // @dev Index this action handler is for
    address internal index;

    // @dev Address of the user this trading module is for
    address internal user;

    event AssetsEscrowed(address indexed user, address indexed index, address indexed asset, uint256 amount);

    constructor(address _vaultDeployer, address _messageRouter) {
        vaultDeployer = _vaultDeployer;
        messageRouter = _messageRouter;
        _disableInitializers();
    }

    receive() external payable {}

    function initialize(address _index, address _user) external initializer {
        index = _index;
        user = _user;
    }

    function withdraw(address asset, uint256 amount, address to) external {
        if (msg.sender != user) {
            revert TradingModuleForbidden();
        }
        ERC20(asset).safeTransfer(to, amount);
    }

    function trade(
        GasAllocationViewer.GasAllocation calldata gasAllocation,
        SubIndexLib.SubIndex calldata subIndex,
        RedeemRouter.QuoteParams[] calldata quotes,
        uint256 burnAmount,
        uint256 srcChainId,
        address reserveAssetOnDst
    ) external payable {
        if (msg.sender != MessageRouter(messageRouter).actionHandlers(MessageLib.ACTION_REMOTE_VAULT_BURN)) {
            revert TradingModuleForbidden();
        }

        address _user = user;
        address _index = index;

        address reserveAssetOnHome = MessageRouter(messageRouter).reserveAsset();

        uint256 totalGasAllocation = gasAllocation.fixedGas + quotes.length * gasAllocation.gasPerMessage;

        for (uint256 i; i < subIndex.assets.length;) {
            RedeemRouter.QuoteParams calldata quote = quotes[i];
            // TODO: amount should be calculated out of this contract
            uint256 amountToWithdraw = subIndex.balances[i].mulDivDown(burnAmount, SubIndexLib.TOTAL_SUPPLY);
            // First withdraw all the assets from the vault
            IVault(IVaultDeployer(vaultDeployer).vaultOf(_index, subIndex.assets[i])).withdraw(
                amountToWithdraw, address(this)
            );
            address(this).excessivelySafeCall(
                gasleft() > totalGasAllocation ? gasleft() - totalGasAllocation : 0, // If a single trade spent too much we just pass 0 here and cache the remaining trades.
                MAX_RETURN_DATA_SIZE, // the max length of returned bytes data
                abi.encodeWithSelector(this.executeSwap.selector, reserveAssetOnHome, quote)
            );

            // emit an event with the new amount of assets in this escrow account. If the trading has failed it will be previously escrowed +  new amount
            emit AssetsEscrowed(_user, _index, quote.inputAsset, ERC20(quote.inputAsset).balanceOf(address(this)));

            totalGasAllocation -= gasAllocation.gasPerMessage;

            unchecked {
                i++;
            }
        }

        uint256 reserveAmount = ERC20(reserveAssetOnHome).balanceOf(address(this));
        if (reserveAmount == 0) {
            return;
        }

        MessageLib.Target[] memory targets = MessageRouter(messageRouter).generateTargets(
            MessageLib.Payload({
                body: abi.encode(srcChainId, reserveAmount, reserveAssetOnDst, reserveAssetOnHome, address(this), _user),
                action: MessageLib.ACTION_RESERVE_TRANSFER
            })
        );

        // This implementation assumes that there is only one target or we are sending reserve asset back to a single chain.
        assert(targets.length == 1);
        MessageLib.Target memory t = targets[0];

        ERC20(reserveAssetOnHome).safeTransfer(t.target, reserveAmount);
        uint256 valueToSend = t.value > address(this).balance ? address(this).balance : t.value; // TODO: don't invoke if it is not enough
        (bool success,) = t.target.call{value: valueToSend, gas: gasleft() > 2000 ? gasleft() - 2000 : 0}(t.data); // 2k gas is to emit an event below, TBD!
        assert(success); // Since the sgSend is wrapped inside try/catch, this should never fail. If it fails it means that the reserve asset is stuck in the target contract.
        emit AssetsEscrowed(_user, _index, reserveAssetOnHome, ERC20(reserveAssetOnHome).balanceOf(address(this)));
    }

    function executeSwap(address reserveAsset, RedeemRouter.QuoteParams memory quote) public {
        if (msg.sender != address(this)) {
            revert TradingModuleForbidden();
        }
        if (quote.assetQuote.length == 0) {
            revert TradingModuleEmptyQuote();
        }

        uint256 outputAssetBalanceBefore = ERC20(reserveAsset).balanceOf(address(this));

        ERC20(quote.inputAsset).safeApprove(quote.swapTarget, ERC20(quote.inputAsset).balanceOf(address(this)));
        quote.swapTarget.functionCall(quote.assetQuote);
        ERC20(quote.inputAsset).safeApprove(quote.swapTarget, 0);

        if (ERC20(reserveAsset).balanceOf(address(this)) - outputAssetBalanceBefore < quote.buyAssetMinAmount) {
            revert TradingModuleInvalid();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success :=
                call(
                    _gas, // gas
                    _target, // recipient
                    0, // ether value
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        view
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success :=
                staticcall(
                    _gas, // gas
                    _target, // recipient
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library MessageLib {
    struct Message {
        uint8 action;
        bytes messageBody;
    }

    struct Target {
        uint256 value;
        address target;
        bytes data;
    }

    struct Payload {
        bytes body;
        uint8 action;
    }

    struct RemoteAssetBalance {
        uint128 newBalance;
        uint128 delta;
        address asset;
    }

    struct RemoteOrderBookEmptyMessage {
        RemoteAssetBalance[] balances;
    }

    uint8 internal constant ACTION_REMOTE_VAULT_MINT = 0;
    uint8 internal constant ACTION_REMOTE_VAULT_BURN = 1;
    uint8 internal constant ACTION_REMOTE_VAULT_ESCROW = 2;
    uint8 internal constant ACTION_RESERVE_TRANSFER = 3;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library SubIndexLib {
    struct SubIndex {
        // TODO: make it uint128 ?
        uint256 id;
        uint256 chainId;
        address[] assets;
        uint256[] balances;
    }

    // TODO: increase precision
    uint32 internal constant TOTAL_SUPPLY = type(uint32).max;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

interface IVaultDeployer {
    struct Params {
        address asset; // The address of the asset the vault will hold
        address router; // The address of the router used to trade the asset
        address strategySetter; // The address that will be able to set the vault's strategy
    }

    /// @notice Deploys a new vault contract
    /// @param index The address of the index contract
    /// @param asset The address of the asset the vault will hold
    /// @return vault The address of the newly deployed vault contract
    function deploy(address index, address asset) external returns (address vault);

    /// @notice Returns the address of the vault for the specified index and asset
    /// @param index The address of the index contract
    /// @param asset The address of the asset the vault holds
    /// @return The address of the vault contract
    function vaultOf(address index, address asset) external view returns (address);

    /// @notice Returns the parameters used to deploy a vault contract
    /// @return asset The address of the asset the vault will hold
    /// @return router The address of the router used to communicate in OMNI
    /// @return strategySetter The address that will be able to set the vault's strategy
    function params() external view returns (address asset, address router, address strategySetter);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IVault
/// @notice Interface for a contract that manages the storage of a single asset.
interface IVault {
    /// @notice Set the strategy for the Vault
    /// @dev Can only be called by the strategySetter
    /// @param newStrategy The new strategy contract address
    function setStrategy(address newStrategy) external;

    /// @notice Set the strategy setter for the Vault
    /// @dev Can only be called by the current strategySetter
    /// @param newStrategySetter The new strategy setter address
    function setStrategySetter(address newStrategySetter) external;

    /// @notice Increase the balance of the Vault
    /// @dev Can only be called by authorized parties
    /// @param amount The amount of assets to increase the balance by.
    function increaseBalance(uint256 amount) external;

    /// @notice Transfers assets from this contract to the specified address.
    /// @dev Can only be called by authorized parties
    /// @param amount The amount of assets to transfer.
    /// @param to The address to transfer the assets to.
    function withdraw(uint256 amount, address to) external;

    /// @notice Returns the ERC20 asset managed by this contract.
    /// @return The ERC20 asset managed by this contract.
    function asset() external view returns (address);

    /// @notice Returns the address of the strategy setter
    /// @return The address of the strategy setter
    function strategySetter() external view returns (address);

    /// @notice Returns the Strategy contract attached to this vault.
    /// @return The Strategy contract attached to this vault.
    function strategy() external view returns (address);

    /// @notice Returns the Strategy contract attached to this vault.
    /// @return The Strategy contract attached to this vault.
    function balance() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

abstract contract GasAllocationViewer {
    /// @dev Gas allocation per message
    /// Gas allocation per messages consists of three parts:
    /// 1. Fixed gas portion (i.e. For burning this would be updating accounting and sending the callback)
    /// 2. Gas per byte of message - This is for cases where we have a dynamic payload so we need to approximate the gas cost.
    /// 3. Gas per message - This is the additional gas for instance to cache a failed message on the remote chain.
    struct GasAllocation {
        uint64 fixedGas;
        uint64 gasPerByte;
        uint64 gasPerMessage;
    }

    bytes32 internal constant ZERO_GAS_ALLOCATION_HASH =
        0x46700b4d40ac5c35af2c22dda2787a91eb567b06c924a8fb8ae9a05b20c08c21;

    mapping(uint256 => mapping(uint8 => GasAllocation)) internal minGasAllocation;

    function setGasAllocation(uint256 chainId, uint8 action, GasAllocation memory gas) external virtual;

    function getGasAllocation(uint8 action, uint256 chainId) external view virtual returns (GasAllocation memory);
    function defaultGasAllocation(uint8 action) external pure virtual returns (GasAllocation memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IReserveVault interface
/// @notice Contains logic for reserve management
interface IReserveVault {
    function withdraw(uint256 assets, address recipient) external;

    function asset() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IIndexClient} from "./interfaces/IIndexClient.sol";

import {SubIndexLib} from "./libraries/SubIndexLib.sol";
import {MessageLib} from "./messaging/libraries/MessageLib.sol";

import {MessageRouter} from "./messaging/MessageRouter.sol";

contract RedeemRouter {
    using Address for address;
    using FixedPointMathLib for *;
    using SafeTransferLib for ERC20;

    struct QuoteParams {
        address swapTarget;
        address inputAsset;
        uint256 inputAmount;
        uint256 buyAssetMinAmount;
        uint256 additionalGas;
        bytes assetQuote;
    }

    struct LocalQuotes {
        QuoteParams[] quotes;
    }

    struct Batch {
        QuoteParams[] quotes;
        uint256 chainId;
        bytes payload; // This payload is bridging implementation specific data.
    }

    struct EscrowParams {
        uint256 subIndexId;
        uint256 remoteChainId;
        uint256 homeChainId;
        uint256 balance;
        address recipient;
    }

    struct RedeemData {
        LocalQuotes[] localData;
        Batch[] remoteData;
    }

    struct IndexInfo {
        address index;
        address reserveAsset;
        address receiver;
        uint256 subIndexesBurnAmount;
    }

    address public immutable messageRouter;

    constructor(address _messageRouter) {
        messageRouter = _messageRouter;
    }

    function redeem(
        address index,
        uint256 indexShares,
        address receiver,
        address owner,
        uint96 reserveCached,
        RedeemData calldata redeemData,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) external payable {
        ERC20(index).safeTransferFrom(msg.sender, address(this), indexShares);
        (uint256 reserveBefore, uint32 subIndexesBurnBalance) =
            IIndexClient(index).redeem(indexShares, owner, receiver, subIndexes);

        if (subIndexes.length != 0) {
            if (reserveCached == reserveBefore) {
                _burnSubIndexes(
                    index, receiver, subIndexesBurnBalance, subIndexes, /*, redeemData.localData*/ redeemData.remoteData
                );
            } else {
                // TODO: will be replaced with another approach
                //         _enqueueSubIndexes(
                //             indexShares - indexBurnt, state.totalSupply + feeAUM - indexBurnt, receiver, subIndexes
                //         );
            }
        }
    }

    function estimateRedeemFee(Batch[] calldata batches) external view returns (uint256) {
        return MessageRouter(messageRouter).estimateFee(
            MessageLib.Payload({
                body: abi.encode(
                    batches,
                    IndexInfo({
                        index: address(this),
                        // TODO: don't use hardcoded value
                        reserveAsset: 0x6aAd876244E7A1Ad44Ec4824Ce813729E5B6C291,
                        receiver: msg.sender,
                        // TODO: extend method to account for subIndex amount
                        subIndexesBurnAmount: 0
                    })
                    ),
                action: MessageLib.ACTION_REMOTE_VAULT_BURN
            })
        );
    }

    function _burnSubIndexes(
        address index,
        address receiver,
        uint32 subIndexesBurnBalance,
        SubIndexLib.SubIndex[] calldata subIndexes,
        // LocalQuotes[] calldata localQuotes,
        Batch[] calldata batches
    ) internal {
        // uint256 localIndex;
        uint256 batchIndex;
        for (uint256 i; i < subIndexes.length;) {
            if (subIndexes[i].chainId == block.chainid) {
                // _validate(subIndexesBurnBalance, subIndexes[i], localQuotes[localIndex].quotes);

                // // _handleLocalSwap(reserveAsset, receiver, localQuotes[localIndex].quotes);

                // unchecked {
                //     localIndex = localIndex + 1;
                // }
            } else {
                uint256 quoteIndex;

                uint256 length = subIndexes[i].assets.length;
                for (uint256 j; j < length;) {
                    if (subIndexes[i].chainId != batches[batchIndex].chainId) {
                        revert();
                    }

                    // TODO: uncomment code
                    bool isCorrectAsset = true;
                    bool isCorrectAmount = true;
                    // bool isCorrectAsset = batches[batchIndex].quotes[quoteIndex].inputAsset == subIndexes[i].assets[j];
                    // bool isCorrectAmount =
                    //     batches[batchIndex].quotes[quoteIndex].inputAmount == subIndexes[i].balances[j].mulDivDown(subIndexesBurnBalance, SubIndexLib.TOTAL_SUPPLY);

                    if (!isCorrectAsset || !isCorrectAmount) {
                        revert();
                    }

                    if (quoteIndex == batches[batchIndex].quotes.length - 1) {
                        quoteIndex = 0;
                        unchecked {
                            batchIndex = batchIndex + 1;
                        }
                    } else {
                        if (j == length - 1) {
                            revert();
                        }
                        unchecked {
                            quoteIndex = quoteIndex + 1;
                        }
                    }

                    unchecked {
                        j = j + 1;
                    }
                }
            }

            unchecked {
                i = i + 1;
            }
        }

        if (batchIndex != batches.length) {
            revert();
        }

        if (batches.length != 0) {
            _handleRemoteSwap(
                MessageLib.Payload({
                    body: abi.encode(
                        batches,
                        IndexInfo({
                            index: index,
                            reserveAsset: MessageRouter(messageRouter).reserveAsset(),
                            receiver: receiver,
                            subIndexesBurnAmount: subIndexesBurnBalance
                        })
                        ),
                    action: MessageLib.ACTION_REMOTE_VAULT_BURN
                })
            );
        }
    }

    function _escrowSubIndexes(
        address receiver,
        uint32 subIndexesBurnBalance,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) internal {
        uint256 length = subIndexes.length;
        EscrowParams[] memory escrowParams = new EscrowParams[](
            length
        );

        for (uint256 i; i < length;) {
            escrowParams[i] =
                EscrowParams(subIndexes[i].id, subIndexes[i].chainId, block.chainid, subIndexesBurnBalance, receiver);

            unchecked {
                i = i + 1;
            }
        }

        _handleRemoteEscrow(receiver, escrowParams);
    }

    function _handleLocalSwap(address outputAsset, address receiver, QuoteParams[] calldata params) internal {
        uint256 outputAssetBalanceBefore = ERC20(outputAsset).balanceOf(address(this));

        uint256 length = params.length;
        for (uint256 i; i < length;) {
            // TODO: withdraw assets from Vault
            _swap(
                outputAsset,
                params[i].inputAsset,
                params[i].inputAmount,
                params[i].buyAssetMinAmount,
                params[i].swapTarget,
                params[i].assetQuote
            );
            unchecked {
                i = i + 1;
            }
        }

        ERC20(outputAsset).safeTransfer(
            receiver, ERC20(outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore
        );
    }

    function _swap(
        address outputAsset,
        address inputAsset,
        uint256 assets,
        uint256 buyAssetMinAmount,
        address swapTarget,
        bytes memory assetQuote
    ) internal {
        uint256 outputAssetBalanceBefore = ERC20(outputAsset).balanceOf(address(this));

        ERC20(inputAsset).safeApprove(swapTarget, assets);
        swapTarget.functionCall(assetQuote);

        ERC20(inputAsset).safeApprove(swapTarget, 0);
        if (ERC20(outputAsset).balanceOf(address(this)) - outputAssetBalanceBefore < buyAssetMinAmount) {
            revert(); //IndexLogicInvalidSwap();
        }
    }

    function _handleRemoteSwap(MessageLib.Payload memory payload) internal {
        MessageLib.Target[] memory targets = MessageRouter(messageRouter).generateTargets(payload);
        _sendMessages(targets);
    }

    function _handleRemoteEscrow(address receiver, EscrowParams[] memory escrowParams) internal {
        //        MessageLib.Target[] memory targets = MessageRouter(messageRouter).generateTargets(
        //            MessageLib.Payload({body: abi.encode(escrowParams), action: MessageLib.ACTION_REMOTE_VAULT_ESCROW}),
        //            receiver
        //        );
        //        _sendMessages(targets);
    }

    function _sendMessages(MessageLib.Target[] memory targets) internal {
        uint256 msgValue = msg.value;
        for (uint256 i; i < targets.length; ++i) {
            MessageLib.Target memory t = targets[i];
            uint256 value = t.value;
            t.target.functionCallWithValue(t.data, value);
            msgValue -= value;
        }
        // In case user has sent more than needed, return the excess
        if (msgValue != 0) {
            Address.sendValue(payable(msg.sender), msgValue);
        }
    }

    function _validate(uint256 balance, SubIndexLib.SubIndex calldata subIndex, QuoteParams[] calldata quotes)
        internal
        pure
    {
        // TODO: uncomment code
        // uint256 length = quotes.length;
        // if (subIndex.assets.length != length) {
        //     revert();
        // }

        // for (uint256 i; i < length;) {
        //     bool isCorrectAsset = quotes[i].inputAsset == subIndex.assets[i];
        //     bool isCorrectAmount =
        //         quotes[i].inputAmount == subIndex.balances[i].mulDivDown(balance, SubIndexLib.TOTAL_SUPPLY);

        //     if (!isCorrectAsset || !isCorrectAmount) {
        //         revert();
        //     }

        //     unchecked {
        //         i = i + 1;
        //     }
        // }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";

import {MessageLib} from "./libraries/MessageLib.sol";

import {BridgingExecutor} from "./interfaces/BridgingExecutor.sol";
import {ActionHandler} from "./interfaces/ActionHandler.sol";

interface MessageRouterErrors {
    error MessageRouterBridgingImplementationNotFound(uint8 action);
    error MessageRouterActionHandlerNotFound(uint8 action);
}

contract MessageRouter is MessageRouterErrors, Owned {
    struct MessageRouterInfo {
        uint8 action;
        address actor;
    }

    /// @dev reserveAsset for the chain
    address public reserveAsset;

    /// @dev action => MessageHandler
    mapping(uint8 => address) public actionHandlers;

    /// @dev action => BridgingImplementation
    mapping(uint8 => address) internal bridgingImplementations;

    constructor(address _owner, address _reserveAsset) Owned(_owner) {
        reserveAsset = _reserveAsset;
    }

    function setReserveAsset(address _reserveAsset) external onlyOwner {
        reserveAsset = _reserveAsset;
    }

    function setBridgingImplementations(MessageRouterInfo[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length; i++) {
            MessageRouterInfo calldata info = infos[i];
            bridgingImplementations[info.action] = info.actor;
        }
    }

    function setActionHandlers(MessageRouterInfo[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length; i++) {
            MessageRouterInfo calldata info = infos[i];
            actionHandlers[info.action] = info.actor;
        }
    }

    /// @dev routeMessage routes the message to the correct handler,
    /// for now it have no access control for testing purposes, but in the future it will be restricted to only the bridge contract
    function routeMessage(MessageLib.Message calldata message, bytes calldata data) external payable {
        address handler = actionHandlers[message.action];
        if (handler == address(0)) {
            revert MessageRouterActionHandlerNotFound(message.action);
        }

        ActionHandler(handler).handleAction{value: address(this).balance}(message, data);
    }

    function generateTargets(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory targets)
    {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        targets = BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload);
    }

    function estimateFee(MessageLib.Payload calldata payload) external view returns (uint256 gasFee) {
        address bridgingImplementation = getBridgingImplementation(payload.action);
        MessageLib.Target[] memory targets = BridgingExecutor(bridgingImplementation).getTargetExecutionData(payload);
        uint256 length = targets.length;
        for (uint256 i; i < length;) {
            gasFee += targets[i].value;
            unchecked {
                i = i + 1;
            }
        }
    }

    function getBridgingImplementation(uint8 action) internal view returns (address) {
        address bridgingImplementation = bridgingImplementations[action];
        if (bridgingImplementation == address(0)) {
            revert MessageRouterBridgingImplementationNotFound(action);
        }

        return bridgingImplementation;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {SubIndexLib} from "../libraries/SubIndexLib.sol";

/// @title IIndexClient interface
/// @notice Contains index minting and burning logic
interface IIndexClient {
    /// @notice Emits each time when index is minted
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /// @notice Emits each time when index is burnt
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 withdrawnReserveAssets,
        uint256 shares
    );

    /// @notice Deposits reserve assets and mints index
    ///
    /// @param reserveAssets Amount of reserve asset
    /// @param receiver Address of index receiver
    ///
    /// @param indexShares Amount of minted index
    function deposit(uint256 reserveAssets, address receiver, SubIndexLib.SubIndex[] calldata subIndexes)
        external
        returns (uint256 indexShares);

    /// @notice Burns index and withdraws reserveAssets
    ///
    /// @param indexShares Amount of index to burn
    /// @param owner Address of index owner
    /// @param receiver Address of assets receiver
    /// @param subIndexes List of SubIndexes
    ///
    /// @param reserveBefore Reserve value before withdraw
    /// @param subIndexBurnBalances SubIndex balances to burn
    function redeem(uint256 indexShares, address owner, address receiver, SubIndexLib.SubIndex[] calldata subIndexes)
        external
        returns (uint256 reserveBefore, uint32 subIndexBurnBalances);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {MessageLib} from "../libraries/MessageLib.sol";

interface BridgingExecutor {
    function getTargetExecutionData(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory targets);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {MessageLib} from "../libraries/MessageLib.sol";
import {GasAllocationViewer} from "./GasAllocationViewer.sol";

interface ActionHandler {
    function handleAction(MessageLib.Message calldata message, bytes calldata data) external payable;
}