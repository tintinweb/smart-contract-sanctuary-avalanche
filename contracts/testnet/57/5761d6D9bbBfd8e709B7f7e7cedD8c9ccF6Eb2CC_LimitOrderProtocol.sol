// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@1inch/solidity-utils/contracts/OnlyWethReceiver.sol";
import "./OrderMixin.sol";
import "./OrderRFQMixin.sol";

/**
 * @title ##1inch Limit Order Protocol v3
 * @notice Limit order protocol provides two different order types
 * - Regular Limit Order
 * - RFQ Order
 *
 * Both types provide similar order-fulfilling functionality. The difference is that regular order offers more customization options and features, while RFQ order is extremely gas efficient but without ability to customize.
 *
 * Regular limit order additionally supports
 * - Execution predicates. Conditions for order execution are set with predicates. For example, expiration timestamp or block number, price for stop loss or take profit strategies.
 * - Callbacks to notify maker on order execution
 *
 * See [OrderMixin](OrderMixin.md) for more details.
 *
 * RFQ orders supports
 * - Expiration time
 * - Cancelation by order id
 * - Partial Fill (only once)
 *
 * See [OrderRFQMixin](OrderRFQMixin.sol) for more details.
 */
contract LimitOrderProtocol is
    EIP712("1inch Limit Order Protocol", "3"),
    OrderMixin,
    OrderRFQMixin,
    OnlyWethReceiver
{
    // solhint-disable-next-line no-empty-blocks
    constructor(IWETH _weth) OrderRFQMixin(_weth) OrderMixin(_weth) OnlyWethReceiver(_weth) {}

    /// @dev Returns the domain separator for the current chain (EIP-712)
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns(bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

error InvalidMsgValue();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

/// @title A helper contract to execute static calls expecting single uint256 as output
library Callib {
    function staticcallForUint(address target, bytes calldata input) internal view returns(bool success, uint256 res) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            calldatacopy(data, input.offset, input.length)
            success := staticcall(gas(), target, data, input.length, 0x0, 0x20)
            if success {
                success := eq(returndatasize(), 32)
                res := mload(0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

/// @title Library with gas efficient alternatives to `abi.decode`
library ArgumentsDecoder {
    error IncorrectDataLength();

    function decodeUint256(bytes calldata data, uint256 offset) internal pure returns(uint256 value) {
        unchecked { if (data.length < offset + 32) revert IncorrectDataLength(); }
        // no memory ops inside so this insertion is automatically memory safe
        assembly { // solhint-disable-line no-inline-assembly
            value := calldataload(add(data.offset, offset))
        }
    }

    function decodeSelector(bytes calldata data) internal pure returns(bytes4 value) {
        if (data.length < 4) revert IncorrectDataLength();
        // no memory ops inside so this insertion is automatically memory safe
        assembly { // solhint-disable-line no-inline-assembly
            value := calldataload(data.offset)
        }
    }

    function decodeTailCalldata(bytes calldata data, uint256 tailOffset) internal pure returns(bytes calldata args) {
        if (data.length < tailOffset) revert IncorrectDataLength();
        // no memory ops inside so this insertion is automatically memory safe
        assembly {  // solhint-disable-line no-inline-assembly
            args.offset := add(data.offset, tailOffset)
            args.length := sub(data.length, tailOffset)
        }
    }

    function decodeTargetAndCalldata(bytes calldata data) internal pure returns(address target, bytes calldata args) {
        if (data.length < 20) revert IncorrectDataLength();
        // no memory ops inside so this insertion is automatically memory safe
        assembly {  // solhint-disable-line no-inline-assembly
            target := shr(96, calldataload(data.offset))
            args.offset := add(data.offset, 20)
            args.length := sub(data.length, 20)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

// TODO: pass order hash, remaining amount, etc to the arguments

/// @title Interface for interactor which acts between `maker => taker` and `taker => maker` transfers.
interface PreInteractionNotificationReceiver {
    function fillOrderPreInteraction(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 remainingAmount,
        bytes memory interactiveData
    ) external;
}

interface PostInteractionNotificationReceiver {
    /// @notice Callback method that gets called after taker transferred funds to maker but before
    /// the opposite transfer happened
    function fillOrderPostInteraction(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 remainingAmount,
        bytes memory interactiveData
    ) external;
}

interface InteractionNotificationReceiver {
    function fillOrderInteraction(
        address taker,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes memory interactiveData
    ) external returns(uint256 offeredTakingAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../OrderLib.sol";

interface IOrderMixin {
    /**
     * @notice Returns unfilled amount for order. Throws if order does not exist
     * @param orderHash Order's hash. Can be obtained by the `hashOrder` function
     * @return amount Unfilled amount
     */
    function remaining(bytes32 orderHash) external view returns(uint256 amount);

    /**
     * @notice Returns unfilled amount for order
     * @param orderHash Order's hash. Can be obtained by the `hashOrder` function
     * @return rawAmount Unfilled amount of order plus one if order exists. Otherwise 0
     */
    function remainingRaw(bytes32 orderHash) external view returns(uint256 rawAmount);

    /**
     * @notice Same as `remainingRaw` but for multiple orders
     * @param orderHashes Array of hashes
     * @return rawAmounts Array of amounts for each order plus one if order exists or 0 otherwise
     */
    function remainingsRaw(bytes32[] memory orderHashes) external view returns(uint256[] memory rawAmounts);

    /**
     * @notice Checks order predicate
     * @param order Order to check predicate for
     * @return result Predicate evaluation result. True if predicate allows to fill the order, false otherwise
     */
    function checkPredicate(OrderLib.Order calldata order) external view returns(bool result);

    /**
     * @notice Returns order hash according to EIP712 standart
     * @param order Order to get hash for
     * @return orderHash Hash of the order
     */
    function hashOrder(OrderLib.Order calldata order) external view returns(bytes32);

    /**
     * @notice Delegates execution to custom implementation. Could be used to validate if `transferFrom` works properly
     * @param target Addresses that will be delegated
     * @param data Data that will be passed to delegatee
     */
    function simulate(address target, bytes calldata data) external;

    /**
     * @notice Cancels order.
     * @dev Order is cancelled by setting remaining amount to _ORDER_FILLED value
     * @param order Order quote to cancel
     * @return orderRemaining Unfilled amount of order before cancellation
     * @return orderHash Hash of the filled order
     */
    function cancelOrder(OrderLib.Order calldata order) external returns(uint256 orderRemaining, bytes32 orderHash);

    /**
     * @notice Fills an order. If one doesn't exist (first fill) it will be created using order.makerAssetData
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param thresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrder(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount
    ) external payable returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

    /**
     * @notice Same as `fillOrder` but calls permit first,
     * allowing to approve token spending and make a swap in one transaction.
     * Also allows to specify funds destination instead of `msg.sender`
     * @dev See tests for examples
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param thresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount
     * @param target Address that will receive swap funds
     * @param permit Should consist of abiencoded token address and encoded `IERC20Permit.permit` call.
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderToWithPermit(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target,
        bytes calldata permit
    ) external returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

    /**
     * @notice Same as `fillOrder` but allows to specify funds destination instead of `msg.sender`
     * @param order_ Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param thresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount
     * @param target Address that will receive swap funds
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderTo(
        OrderLib.Order calldata order_,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target
    ) external payable returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../libraries/Callib.sol";
import "../libraries/ArgumentsDecoder.sol";
import "./NonceManager.sol";

/// @title A helper contract for executing boolean functions on arbitrary target call results
contract PredicateHelper is NonceManager {
    using Callib for address;
    using ArgumentsDecoder for bytes;

    error ArbitraryStaticCallFailed();
    error InvalidDispatcher();

    uint256 constant private _MAGIC_SALT = 117243;  // https://gist.github.com/k06a/5b6c06faa235e656cc391cb444ea71e8
    uint256 constant private _MAGIC_PRIME = 1337;
    uint256 constant private _DISPACTHER_SELECTORS = 5;

    constructor() {
        if (_calculateIndex(PredicateHelper(address(0)).or.selector) != 0 ||
            _calculateIndex(PredicateHelper(address(0)).and.selector) != 1 ||
            _calculateIndex(PredicateHelper(address(0)).eq.selector) != 2 ||
            _calculateIndex(PredicateHelper(address(0)).lt.selector) != 3 ||
            _calculateIndex(PredicateHelper(address(0)).gt.selector) != 4)
        {
            revert InvalidDispatcher();
        }
    }

    /// @notice Calls every target with corresponding data
    /// @return Result True if call to any target returned True. Otherwise, false
    function or(uint256 offsets, bytes calldata data) public view returns(bool) {
        uint256 current;
        uint256 previous;
        for (uint256 i = 0; (current = uint32(offsets >> i)) != 0; i += 32) {
            (bool success, uint256 res) = _selfStaticCall(data[previous:current]);
            if (success && res == 1) {
                return true;
            }
            previous = current;
        }
        return false;
    }

    /// @notice Calls every target with corresponding data
    /// @return Result True if calls to all targets returned True. Otherwise, false
    function and(uint256 offsets, bytes calldata data) public view returns(bool) {
        uint256 current;
        uint256 previous;
        for (uint256 i = 0; (current = uint32(offsets >> i)) != 0; i += 32) {
            (bool success, uint256 res) = _selfStaticCall(data[previous:current]);
            if (!success || res != 1) {
                return false;
            }
            previous = current;
        }
        return true;
    }

    /// @notice Calls target with specified data and tests if it's equal to the value
    /// @param value Value to test
    /// @return Result True if call to target returns the same value as `value`. Otherwise, false
    function eq(uint256 value, bytes calldata data) public view returns(bool) {
        (bool success, uint256 res) = _selfStaticCall(data);
        return success && res == value;
    }

    /// @notice Calls target with specified data and tests if it's lower than value
    /// @param value Value to test
    /// @return Result True if call to target returns value which is lower than `value`. Otherwise, false
    function lt(uint256 value, bytes calldata data) public view returns(bool) {
        (bool success, uint256 res) = _selfStaticCall(data);
        return success && res < value;
    }

    /// @notice Calls target with specified data and tests if it's bigger than value
    /// @param value Value to test
    /// @return Result True if call to target returns value which is bigger than `value`. Otherwise, false
    function gt(uint256 value, bytes calldata data) public view returns(bool) {
        (bool success, uint256 res) = _selfStaticCall(data);
        return success && res > value;
    }

    /// @notice Checks passed time against block timestamp
    /// @return Result True if current block timestamp is lower than `time`. Otherwise, false
    function timestampBelow(uint256 time) public view returns(bool) {
        return block.timestamp < time;  // solhint-disable-line not-rely-on-time
    }

    /// @notice Performs an arbitrary call to target with data
    /// @return Result Bytes transmuted to uint256
    function arbitraryStaticCall(address target, bytes calldata data) public view returns(uint256) {
        (bool success, uint256 res) = target.staticcallForUint(data);
        if (!success) revert ArbitraryStaticCallFailed();
        return res;
    }

    function timestampBelowAndNonceEquals(uint256 timeNonceAccount) public view returns(bool) {
        uint256 time = uint48(timeNonceAccount >> 208);
        uint256 nonce = uint48(timeNonceAccount >> 160);
        address account = address(uint160(timeNonceAccount));
        return timestampBelow(time) && nonceEquals(account, nonce);
    }

    function _selfStaticCall(bytes calldata data) internal view returns(bool, uint256) {
        bytes4 selector = data.decodeSelector();
        uint256 index = _calculateIndex(selector);
        uint256 arg = data.decodeUint256(4);

        if (selector == [this.or, this.and, this.eq, this.lt, this.gt][index].selector) {
            bytes calldata param = data.decodeTailCalldata(100);
            return (true, [or, and, eq, lt, gt][index](arg, param) ? 1 : 0);
        }

        // Other functions
        if (selector == this.timestampBelowAndNonceEquals.selector) {
            return (true, timestampBelowAndNonceEquals(arg) ? 1 : 0);
        }
        if (selector == this.timestampBelow.selector) {
            return (true, timestampBelow(arg) ? 1 : 0);
        }
        if (selector == this.nonceEquals.selector) {
            uint256 arg2 = data.decodeUint256(0x24);
            return (true, nonceEquals(address(uint160(arg)), arg2) ? 1 : 0);
        }
        if (selector == this.arbitraryStaticCall.selector) {
            bytes calldata param = data.decodeTailCalldata(100);
            return (true, arbitraryStaticCall(address(uint160(arg)), param));
        }

        return address(this).staticcallForUint(data);
    }

    function _calculateIndex(bytes4 selector) private pure returns(uint256 index) {
        unchecked {
            index = ((uint32(selector) ^ _MAGIC_SALT) % _MAGIC_PRIME) % _DISPACTHER_SELECTORS;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

/// @title A helper contract for managing nonce of tx sender
contract NonceManager {
    event NonceIncreased(address indexed maker, uint256 newNonce);

    mapping(address => uint256) public nonce;

    /// @notice Advances nonce by one
    function increaseNonce() external {
        advanceNonce(1);
    }

    /// @notice Advances nonce by specified amount
    function advanceNonce(uint8 amount) public {
        uint256 newNonce = nonce[msg.sender] + amount;
        nonce[msg.sender] = newNonce;
        emit NonceIncreased(msg.sender, newNonce);
    }

    /// @notice Checks if `makerAddress` has specified `makerNonce`
    /// @return Result True if `makerAddress` has specified nonce. Otherwise, false
    function nonceEquals(address makerAddress, uint256 makerNonce) public view returns(bool) {
        return nonce[makerAddress] == makerNonce;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

import "../libraries/Callib.sol";

/// @title A helper contract for calculations related to order amounts
contract AmountCalculator {
    using Callib for address;

    /// @notice Calculates maker amount
    /// @return Result Floored maker amount
    function getMakingAmount(uint256 orderMakerAmount, uint256 orderTakerAmount, uint256 swapTakerAmount) public pure returns(uint256) {
        return swapTakerAmount * orderMakerAmount / orderTakerAmount;
    }

    /// @notice Calculates taker amount
    /// @return Result Ceiled taker amount
    function getTakingAmount(uint256 orderMakerAmount, uint256 orderTakerAmount, uint256 swapMakerAmount) public pure returns(uint256) {
        return (swapMakerAmount * orderTakerAmount + orderMakerAmount - 1) / orderMakerAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import "./helpers/AmountCalculator.sol";
import "./libraries/Errors.sol";
import "./OrderRFQLib.sol";

/// @title RFQ Limit Order mixin
abstract contract OrderRFQMixin is EIP712, AmountCalculator {
    using SafeERC20 for IERC20;
    using OrderRFQLib for OrderRFQLib.OrderRFQ;

    error RFQZeroTargetIsForbidden();
    error RFQPrivateOrder();
    error RFQBadSignature();
    error OrderExpired();
    error MakingAmountExceeded();
    error TakingAmountExceeded();
    error RFQSwapWithZeroAmount();
    error InvalidatedOrder();
    error ETHTransferFailed();

    /**
     * @notice Emitted when RFQ gets filled
     * @param orderHash Hash of the order
     * @param makingAmount Amount of the maker asset that was transferred from maker to taker
     */
    event OrderFilledRFQ(
        bytes32 orderHash,
        uint256 makingAmount
    );

    IWETH private immutable _WETH;  // solhint-disable-line var-name-mixedcase
    mapping(address => mapping(uint256 => uint256)) private _invalidator;

    constructor(IWETH weth) {
        _WETH = weth;
    }

    /**
     * @notice Returns bitmask for double-spend invalidators based on lowest byte of order.info and filled quotes
     * @param maker Maker address
     * @param slot Slot number to return bitmask for
     * @return result Each bit represents whether corresponding was already invalidated
     */
    function invalidatorForOrderRFQ(address maker, uint256 slot) external view returns(uint256 /* result */) {
        return _invalidator[maker][slot];
    }

    /**
     * @notice Cancels order's quote
     * @param orderInfo Order info (only order id in lowest 64 bits is used)
     */
    function cancelOrderRFQ(uint256 orderInfo) external {
        _invalidateOrder(msg.sender, orderInfo, 0);
    }

    /// @notice Cancels multiple order's quotes
    function cancelOrderRFQ(uint256 orderInfo, uint256 additionalMask) public {
        _invalidateOrder(msg.sender, orderInfo, additionalMask);
    }

    /**
     * @notice Fills order's quote, fully or partially (whichever is possible)
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param flagsAndAmount Fill configuration flags with amount packed in one slot
     * @return filledMakingAmount Actual amount transferred from maker to taker
     * @return filledTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderRFQ(
        OrderRFQLib.OrderRFQ memory order,
        bytes calldata signature,
        uint256 flagsAndAmount
    ) external payable returns(uint256 /* filledMakingAmount */, uint256 /* filledTakingAmount */, bytes32 /* orderHash */) {
        return fillOrderRFQTo(order, signature, flagsAndAmount, msg.sender);
    }

    uint256 constant private _MAKER_AMOUNT_FLAG = 1 << 255;
    uint256 constant private _SIGNER_SMART_CONTRACT_HINT = 1 << 254;
    uint256 constant private _IS_VALID_SIGNATURE_65_BYTES = 1 << 253;
    uint256 constant private _UNWRAP_WETH_FLAG = 1 << 252;
    uint256 constant private _AMOUNT_MASK = ~(
        _MAKER_AMOUNT_FLAG |
        _SIGNER_SMART_CONTRACT_HINT |
        _IS_VALID_SIGNATURE_65_BYTES |
        _UNWRAP_WETH_FLAG
    );

    /**
     * @notice Fills order's quote, fully or partially, with compact signature
     * @param order Order quote to fill
     * @param r R component of signature
     * @param vs VS component of signature
     * @param flagsAndAmount Fill configuration flags with amount packed in one slot
     * - Bits 0-252 contain the amount to fill
     * - Bit 253 is used to indicate whether signature is 64-bit (0) or 65-bit (1)
     * - Bit 254 is used to indicate whether smart contract (1) signed the order or not (0)
     * - Bit 255 is used to indicate whether maker (1) or taker amount (0) is given in the amount parameter
     * @return filledMakingAmount Actual amount transferred from maker to taker
     * @return filledTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderRFQCompact(
        OrderRFQLib.OrderRFQ memory order,
        bytes32 r,
        bytes32 vs,
        uint256 flagsAndAmount
    ) external payable returns(uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash) {
        orderHash = order.hash(_domainSeparatorV4());
        if (flagsAndAmount & _SIGNER_SMART_CONTRACT_HINT != 0) {
            if (flagsAndAmount & _IS_VALID_SIGNATURE_65_BYTES != 0) {
                if (!ECDSA.isValidSignature65(order.maker, orderHash, r, vs)) revert RFQBadSignature();
            } else {
                if (!ECDSA.isValidSignature(order.maker, orderHash, r, vs)) revert RFQBadSignature();
            }
        } else {
            if(!ECDSA.recoverOrIsValidSignature(order.maker, orderHash, r, vs)) revert RFQBadSignature();
        }

        (filledMakingAmount, filledTakingAmount) = _fillOrderRFQTo(order, flagsAndAmount, msg.sender);
        emit OrderFilledRFQ(orderHash, filledMakingAmount);
    }

    /**
     * @notice Fills Same as `fillOrderRFQ` but calls permit first.
     * It allows to approve token spending and make a swap in one transaction.
     * Also allows to specify funds destination instead of `msg.sender`
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param flagsAndAmount Fill configuration flags with amount packed in one slot
     * @param target Address that will receive swap funds
     * @param permit Should consist of abiencoded token address and encoded `IERC20Permit.permit` call.
     * @return filledMakingAmount Actual amount transferred from maker to taker
     * @return filledTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     * @dev See tests for examples
     */
    function fillOrderRFQToWithPermit(
        OrderRFQLib.OrderRFQ memory order,
        bytes calldata signature,
        uint256 flagsAndAmount,
        address target,
        bytes calldata permit
    ) external returns(uint256 /* filledMakingAmount */, uint256 /* filledTakingAmount */, bytes32 /* orderHash */) {
        IERC20(order.takerAsset).safePermit(permit);
        return fillOrderRFQTo(order, signature, flagsAndAmount, target);
    }

    /**
     * @notice Same as `fillOrderRFQ` but allows to specify funds destination instead of `msg.sender`
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param flagsAndAmount Fill configuration flags with amount packed in one slot
     * @param target Address that will receive swap funds
     * @return filledMakingAmount Actual amount transferred from maker to taker
     * @return filledTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderRFQTo(
        OrderRFQLib.OrderRFQ memory order,
        bytes calldata signature,
        uint256 flagsAndAmount,
        address target
    ) public payable returns(uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash) {
        orderHash = order.hash(_domainSeparatorV4());
        if (flagsAndAmount & _SIGNER_SMART_CONTRACT_HINT != 0) {
            if (flagsAndAmount & _IS_VALID_SIGNATURE_65_BYTES != 0 && signature.length != 65) revert RFQBadSignature();
            if (!ECDSA.isValidSignature(order.maker, orderHash, signature)) revert RFQBadSignature();
        } else {
            if(!ECDSA.recoverOrIsValidSignature(order.maker, orderHash, signature)) revert RFQBadSignature();
        }
        (filledMakingAmount, filledTakingAmount) = _fillOrderRFQTo(order, flagsAndAmount, target);
        emit OrderFilledRFQ(orderHash, filledMakingAmount);
    }

    function _fillOrderRFQTo(
        OrderRFQLib.OrderRFQ memory order,
        uint256 flagsAndAmount,
        address target
    ) private returns(uint256 makingAmount, uint256 takingAmount) {
        if (target == address(0)) revert RFQZeroTargetIsForbidden();

        address maker = order.maker;

        // Validate order
        if (order.allowedSender != address(0) && order.allowedSender != msg.sender) revert RFQPrivateOrder();

        {  // Stack too deep
            uint256 info = order.info;
            // Check time expiration
            uint256 expiration = uint128(info) >> 64;
            if (expiration != 0 && block.timestamp > expiration) revert OrderExpired(); // solhint-disable-line not-rely-on-time
            _invalidateOrder(maker, info, 0);
        }

        {  // Stack too deep
            uint256 orderMakingAmount = order.makingAmount;
            uint256 orderTakingAmount = order.takingAmount;
            uint256 amount = flagsAndAmount & _AMOUNT_MASK;
            // Compute partial fill if needed
            if (amount == 0) {
                // zero amount means whole order
                makingAmount = orderMakingAmount;
                takingAmount = orderTakingAmount;
            }
            else if (flagsAndAmount & _MAKER_AMOUNT_FLAG != 0) {
                if (amount > orderMakingAmount) revert MakingAmountExceeded();
                makingAmount = amount;
                takingAmount = getTakingAmount(orderMakingAmount, orderTakingAmount, makingAmount);
            }
            else {
                if (amount > orderTakingAmount) revert TakingAmountExceeded();
                takingAmount = amount;
                makingAmount = getMakingAmount(orderMakingAmount, orderTakingAmount, takingAmount);
            }
        }

        if (makingAmount == 0 || takingAmount == 0) revert RFQSwapWithZeroAmount();

        // Maker => Taker
        if (order.makerAsset == address(_WETH) && flagsAndAmount & _UNWRAP_WETH_FLAG != 0) {
            _WETH.transferFrom(maker, address(this), makingAmount);
            _WETH.withdraw(makingAmount);
            (bool success, ) = target.call{value: makingAmount}("");  // solhint-disable-line avoid-low-level-calls
            if (!success) revert ETHTransferFailed();
        } else {
            IERC20(order.makerAsset).safeTransferFrom(maker, target, makingAmount);
        }

        // Taker => Maker
        if (order.takerAsset == address(_WETH) && msg.value > 0) {
            if (msg.value != takingAmount) revert InvalidMsgValue();
            _WETH.deposit{ value: takingAmount }();
            _WETH.transfer(maker, takingAmount);
        } else {
            if (msg.value != 0) revert InvalidMsgValue();
            IERC20(order.takerAsset).safeTransferFrom(msg.sender, maker, takingAmount);
        }
    }

    function _invalidateOrder(address maker, uint256 orderInfo, uint256 additionalMask) private {
        uint256 invalidatorSlot = uint64(orderInfo) >> 8;
        uint256 invalidatorBits = (1 << uint8(orderInfo)) | additionalMask;
        mapping(uint256 => uint256) storage invalidatorStorage = _invalidator[maker];
        uint256 invalidator = invalidatorStorage[invalidatorSlot];
        if (invalidator & invalidatorBits != 0) revert InvalidatedOrder();
        invalidatorStorage[invalidatorSlot] = invalidator | invalidatorBits;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

library OrderRFQLib {
    struct OrderRFQ {
        uint256 info;  // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
        address makerAsset;
        address takerAsset;
        address maker;
        address allowedSender;  // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
    }

    bytes32 constant internal _LIMIT_ORDER_RFQ_TYPEHASH = keccak256(
        "OrderRFQ("
            "uint256 info,"
            "address makerAsset,"
            "address takerAsset,"
            "address maker,"
            "address allowedSender,"
            "uint256 makingAmount,"
            "uint256 takingAmount"
        ")"
    );

    function hash(OrderRFQ memory order, bytes32 domainSeparator) internal pure returns(bytes32 result) {
        bytes32 typehash = _LIMIT_ORDER_RFQ_TYPEHASH;
        bytes32 orderHash;
        // this assembly is memory unsafe :(
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := sub(order, 0x20)

            // keccak256(abi.encode(_LIMIT_ORDER_RFQ_TYPEHASH, order));
            let tmp := mload(ptr)
            mstore(ptr, typehash)
            orderHash := keccak256(ptr, 0x100)
            mstore(ptr, tmp)
        }
        return ECDSA.toTypedDataHash(domainSeparator, orderHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/interfaces/IWETH.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

import "./helpers/AmountCalculator.sol";
import "./helpers/PredicateHelper.sol";
import "./interfaces/IOrderMixin.sol";
import "./interfaces/NotificationReceiver.sol";
import "./libraries/ArgumentsDecoder.sol";
import "./libraries/Callib.sol";
import "./libraries/Errors.sol";
import "./OrderLib.sol";

/// @title Regular Limit Order mixin
abstract contract OrderMixin is IOrderMixin, EIP712, AmountCalculator, PredicateHelper {
    using Callib for address;
    using SafeERC20 for IERC20;
    using ArgumentsDecoder for bytes;
    using OrderLib for OrderLib.Order;

    error UnknownOrder();
    error AccessDenied();
    error AlreadyFilled();
    error PermitLengthTooLow();
    error ZeroTargetIsForbidden();
    error RemainingAmountIsZero();
    error PrivateOrder();
    error BadSignature();
    error ReentrancyDetected();
    error PredicateIsNotTrue();
    error OnlyOneAmountShouldBeZero();
    error TakingAmountTooHigh();
    error MakingAmountTooLow();
    error SwapWithZeroAmount();
    error TransferFromMakerToTakerFailed();
    error TransferFromTakerToMakerFailed();
    error WrongAmount();
    error WrongGetter();
    error GetAmountCallFailed();

    /// @notice Emitted every time order gets filled, including partial fills
    event OrderFilled(
        address indexed maker,
        bytes32 orderHash,
        uint256 remaining
    );

    /// @notice Emitted when order gets cancelled
    event OrderCanceled(
        address indexed maker,
        bytes32 orderHash,
        uint256 remainingRaw
    );

    uint256 constant private _ORDER_DOES_NOT_EXIST = 0;
    uint256 constant private _ORDER_FILLED = 1;

    IWETH private immutable _WETH;  // solhint-disable-line var-name-mixedcase
    /// @notice Stores unfilled amounts for each order plus one.
    /// Therefore 0 means order doesn't exist and 1 means order was filled
    mapping(bytes32 => uint256) private _remaining;

    constructor(IWETH weth) {
        _WETH = weth;
    }

    /**
     * @notice See {IOrderMixin-remaining}.
     */
    function remaining(bytes32 orderHash) external view returns(uint256 /* amount */) {
        uint256 amount = _remaining[orderHash];
        if (amount == _ORDER_DOES_NOT_EXIST) revert UnknownOrder();
        unchecked { amount -= 1; }
        return amount;
    }

    /**
     * @notice See {IOrderMixin-remainingRaw}.
     */
    function remainingRaw(bytes32 orderHash) external view returns(uint256 /* rawAmount */) {
        return _remaining[orderHash];
    }

    /**
     * @notice See {IOrderMixin-remainingsRaw}.
     */
    function remainingsRaw(bytes32[] memory orderHashes) external view returns(uint256[] memory /* rawAmounts */) {
        uint256[] memory results = new uint256[](orderHashes.length);
        for (uint256 i = 0; i < orderHashes.length; i++) {
            results[i] = _remaining[orderHashes[i]];
        }
        return results;
    }

    error SimulationResults(bool success, bytes res);

    /**
     * @notice See {IOrderMixin-simulate}.
     */
    function simulate(address target, bytes calldata data) external {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = target.delegatecall(data);
        revert SimulationResults(success, result);
    }

    /**
     * @notice See {IOrderMixin-cancelOrder}.
     */
    function cancelOrder(OrderLib.Order calldata order) external returns(uint256 orderRemaining, bytes32 orderHash) {
        if (order.maker != msg.sender) revert AccessDenied();

        orderHash = hashOrder(order);
        orderRemaining = _remaining[orderHash];
        if (orderRemaining == _ORDER_FILLED) revert AlreadyFilled();
        emit OrderCanceled(msg.sender, orderHash, orderRemaining);
        _remaining[orderHash] = _ORDER_FILLED;
    }

    /**
     * @notice See {IOrderMixin-fillOrder}.
     */
    function fillOrder(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount
    ) external payable returns(uint256 /* actualMakingAmount */, uint256 /* actualTakingAmount */, bytes32 /* orderHash */) {
        return fillOrderTo(order, signature, interaction, makingAmount, takingAmount, thresholdAmount, msg.sender);
    }

    /**
     * @notice See {IOrderMixin-fillOrderToWithPermit}.
     */
    function fillOrderToWithPermit(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target,
        bytes calldata permit
    ) external returns(uint256 /* actualMakingAmount */, uint256 /* actualTakingAmount */, bytes32 /* orderHash */) {
        if (permit.length < 20) revert PermitLengthTooLow();
        {  // Stack too deep
            (address token, bytes calldata permitData) = permit.decodeTargetAndCalldata();
            IERC20(token).safePermit(permitData);
        }
        return fillOrderTo(order, signature, interaction, makingAmount, takingAmount, thresholdAmount, target);
    }

    /**
     * @notice See {IOrderMixin-fillOrderTo}.
     */
    function fillOrderTo(
        OrderLib.Order calldata order_,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target
    ) public payable returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash) {
        if (target == address(0)) revert ZeroTargetIsForbidden();
        orderHash = hashOrder(order_);

        OrderLib.Order calldata order = order_; // Helps with "Stack too deep"
        actualMakingAmount = makingAmount;
        actualTakingAmount = takingAmount;

        uint256 remainingMakingAmount = _remaining[orderHash];
        if (remainingMakingAmount == _ORDER_FILLED) revert RemainingAmountIsZero();
        if (order.allowedSender != address(0) && order.allowedSender != msg.sender) revert PrivateOrder();
        if (remainingMakingAmount == _ORDER_DOES_NOT_EXIST) {
            // First fill: validate order and permit maker asset
            if (!ECDSA.recoverOrIsValidSignature(order.maker, orderHash, signature)) revert BadSignature();
            remainingMakingAmount = order.makingAmount;

            bytes calldata permit = order.permit(); // Helps with "Stack too deep"
            if (permit.length >= 20) {
                // proceed only if permit length is enough to store address
                (address token, bytes calldata permitCalldata) = permit.decodeTargetAndCalldata();
                IERC20(token).safePermit(permitCalldata);
                if (_remaining[orderHash] != _ORDER_DOES_NOT_EXIST) revert ReentrancyDetected();
            }
        } else {
            unchecked { remainingMakingAmount -= 1; }
        }

        // Check if order is valid
        if (order.predicate().length > 0) {
            if (!checkPredicate(order)) revert PredicateIsNotTrue();
        }

        // Compute maker and taker assets amount
        if ((actualTakingAmount == 0) == (actualMakingAmount == 0)) {
            revert OnlyOneAmountShouldBeZero();
        } else if (actualTakingAmount == 0) {
            if (actualMakingAmount > remainingMakingAmount) {
                actualMakingAmount = remainingMakingAmount;
            }
            actualTakingAmount = _getTakingAmount(order.getTakingAmount(), order.makingAmount, actualMakingAmount, order.takingAmount, remainingMakingAmount, orderHash);
            // check that actual rate is not worse than what was expected
            // actualTakingAmount / actualMakingAmount <= thresholdAmount / makingAmount
            if (actualTakingAmount * makingAmount > thresholdAmount * actualMakingAmount) revert TakingAmountTooHigh();
        } else {
            actualMakingAmount = _getMakingAmount(order.getMakingAmount(), order.takingAmount, actualTakingAmount, order.makingAmount, remainingMakingAmount, orderHash);
            if (actualMakingAmount > remainingMakingAmount) {
                actualMakingAmount = remainingMakingAmount;
                actualTakingAmount = _getTakingAmount(order.getTakingAmount(), order.makingAmount, actualMakingAmount, order.takingAmount, remainingMakingAmount, orderHash);
            }
            // check that actual rate is not worse than what was expected
            // actualMakingAmount / actualTakingAmount >= thresholdAmount / takingAmount
            if (actualMakingAmount * takingAmount < thresholdAmount * actualTakingAmount) revert MakingAmountTooLow();
        }

        if (actualMakingAmount == 0 || actualTakingAmount == 0) revert SwapWithZeroAmount();

        // Update remaining amount in storage
        unchecked {
            remainingMakingAmount = remainingMakingAmount - actualMakingAmount;
            _remaining[orderHash] = remainingMakingAmount + 1;
        }
        emit OrderFilled(order_.maker, orderHash, remainingMakingAmount);

        // Maker can handle funds interactively
        if (order.preInteraction().length >= 20) {
            // proceed only if interaction length is enough to store address
            (address interactionTarget, bytes calldata interactionData) = order.preInteraction().decodeTargetAndCalldata();
            PreInteractionNotificationReceiver(interactionTarget).fillOrderPreInteraction(
                orderHash, order.maker, msg.sender, actualMakingAmount, actualTakingAmount, remainingMakingAmount, interactionData
            );
        }

        // Maker => Taker
        if (!_callTransferFrom(
            order.makerAsset,
            order.maker,
            target,
            actualMakingAmount,
            order.makerAssetData()
        )) revert TransferFromMakerToTakerFailed();

        if (interaction.length >= 20) {
            // proceed only if interaction length is enough to store address
            (address interactionTarget, bytes calldata interactionData) = interaction.decodeTargetAndCalldata();
            uint256 offeredTakingAmount = InteractionNotificationReceiver(interactionTarget).fillOrderInteraction(
                msg.sender, actualMakingAmount, actualTakingAmount, interactionData
            );

            if (offeredTakingAmount > actualTakingAmount &&
                !OrderLib.getterIsFrozen(order.getMakingAmount()) &&
                !OrderLib.getterIsFrozen(order.getTakingAmount()))
            {
                actualTakingAmount = offeredTakingAmount;
            }
        }

        // Taker => Maker
        if (order.takerAsset == address(_WETH) && msg.value > 0) {
            if (msg.value != actualTakingAmount) revert InvalidMsgValue();
            _WETH.deposit{ value: actualTakingAmount }();
            _WETH.transfer(order.receiver == address(0) ? order.maker : order.receiver, actualTakingAmount);
        } else {
            if (msg.value != 0) revert InvalidMsgValue();
            if (!_callTransferFrom(
                order.takerAsset,
                msg.sender,
                order.receiver == address(0) ? order.maker : order.receiver,
                actualTakingAmount,
                order.takerAssetData()
            )) revert TransferFromTakerToMakerFailed();
        }

        // Maker can handle funds interactively
        if (order.postInteraction().length >= 20) {
            // proceed only if interaction length is enough to store address
            (address interactionTarget, bytes calldata interactionData) = order.postInteraction().decodeTargetAndCalldata();
            PostInteractionNotificationReceiver(interactionTarget).fillOrderPostInteraction(
                 orderHash, order.maker, msg.sender, actualMakingAmount, actualTakingAmount, remainingMakingAmount, interactionData
            );
        }
    }

    /**
     * @notice See {IOrderMixin-checkPredicate}.
     */
    function checkPredicate(OrderLib.Order calldata order) public view returns(bool) {
        (bool success, uint256 res) = _selfStaticCall(order.predicate());
        return success && res == 1;
    }

    /**
     * @notice See {IOrderMixin-hashOrder}.
     */
    function hashOrder(OrderLib.Order calldata order) public view returns(bytes32) {
        return order.hash(_domainSeparatorV4());
    }

    function _callTransferFrom(address asset, address from, address to, uint256 amount, bytes calldata input) private returns(bool success) {
        bytes4 selector = IERC20.transferFrom.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            calldatacopy(add(data, 0x64), input.offset, input.length)
            let status := call(gas(), asset, 0, data, add(100, input.length), 0x0, 0x20)
            success := and(status, or(iszero(returndatasize()), and(gt(returndatasize(), 31), eq(mload(0), 1))))
        }
    }

    function _getMakingAmount(
        bytes calldata getter,
        uint256 orderTakingAmount,
        uint256 requestedTakingAmount,
        uint256 orderMakingAmount,
        uint256 remainingMakingAmount,
        bytes32 orderHash
    ) private view returns(uint256) {
        if (getter.length == 0) {
            // Linear proportion
            return getMakingAmount(orderMakingAmount, orderTakingAmount, requestedTakingAmount);
        }
        return _callGetter(getter, orderTakingAmount, requestedTakingAmount, orderMakingAmount, remainingMakingAmount, orderHash);
    }

    function _getTakingAmount(
        bytes calldata getter,
        uint256 orderMakingAmount,
        uint256 requestedMakingAmount,
        uint256 orderTakingAmount,
        uint256 remainingMakingAmount,
        bytes32 orderHash
    ) private view returns(uint256) {
        if (getter.length == 0) {
            // Linear proportion
            return getTakingAmount(orderMakingAmount, orderTakingAmount, requestedMakingAmount);
        }
        return _callGetter(getter, orderMakingAmount, requestedMakingAmount, orderTakingAmount, remainingMakingAmount, orderHash);
    }

    function _callGetter(
        bytes calldata getter,
        uint256 orderExpectedAmount,
        uint256 requestedAmount,
        uint256 orderResultAmount,
        uint256 remainingMakingAmount,
        bytes32 orderHash
    ) private view returns(uint256) {
        if (getter.length == 1) {
            if (OrderLib.getterIsFrozen(getter)) {
                // On "x" getter calldata only exact amount is allowed
                if (requestedAmount != orderExpectedAmount) revert WrongAmount();
                return orderResultAmount;
            } else {
                revert WrongGetter();
            }
        } else {
            (address target, bytes calldata data) = getter.decodeTargetAndCalldata();
            (bool success, bytes memory result) = target.staticcall(abi.encodePacked(data, requestedAmount, remainingMakingAmount, orderHash));
            if (!success || result.length != 32) revert GetAmountCallFailed();
            return abi.decode(result, (uint256));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

library OrderLib {
    struct Order {
        uint256 salt;
        address makerAsset;
        address takerAsset;
        address maker;
        address receiver;
        address allowedSender;  // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
        uint256 offsets;
        // bytes makerAssetData;
        // bytes takerAssetData;
        // bytes getMakingAmount; // this.staticcall(abi.encodePacked(bytes, swapTakerAmount)) => (swapMakerAmount)
        // bytes getTakingAmount; // this.staticcall(abi.encodePacked(bytes, swapMakerAmount)) => (swapTakerAmount)
        // bytes predicate;       // this.staticcall(bytes) => (bool)
        // bytes permit;          // On first fill: permit.1.call(abi.encodePacked(permit.selector, permit.2))
        // bytes preInteraction;
        // bytes postInteraction;
        bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
    }

    bytes32 constant internal _LIMIT_ORDER_TYPEHASH = keccak256(
        "Order("
            "uint256 salt,"
            "address makerAsset,"
            "address takerAsset,"
            "address maker,"
            "address receiver,"
            "address allowedSender,"
            "uint256 makingAmount,"
            "uint256 takingAmount,"
            "uint256 offsets,"
            "bytes interactions"
        ")"
    );

    enum DynamicField {
        MakerAssetData,
        TakerAssetData,
        GetMakingAmount,
        GetTakingAmount,
        Predicate,
        Permit,
        PreInteraction,
        PostInteraction
    }

    function getterIsFrozen(bytes calldata getter) internal pure returns(bool) {
        return getter.length == 1 && getter[0] == "x";
    }

    function _get(Order calldata order, DynamicField field) private pure returns(bytes calldata) {
        if (uint256(field) == 0) {
            return order.interactions[0:uint32(order.offsets)];
        }

        uint256 bitShift = uint256(field) << 5; // field * 32
        return order.interactions[
            uint32((order.offsets << 32) >> bitShift):
            uint32(order.offsets >> bitShift)
        ];
    }

    function makerAssetData(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.MakerAssetData);
    }

    function takerAssetData(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.TakerAssetData);
    }

    function getMakingAmount(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.GetMakingAmount);
    }

    function getTakingAmount(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.GetTakingAmount);
    }

    function predicate(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.Predicate);
    }

    function permit(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.Permit);
    }

    function preInteraction(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.PreInteraction);
    }

    function postInteraction(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.PostInteraction);
    }

    function hash(Order calldata order, bytes32 domainSeparator) internal pure returns(bytes32 result) {
        bytes calldata interactions = order.interactions;
        bytes32 typehash = _LIMIT_ORDER_TYPEHASH;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            // keccak256(abi.encode(_LIMIT_ORDER_TYPEHASH, orderWithoutInteractions, keccak256(order.interactions)));
            calldatacopy(ptr, interactions.offset, interactions.length)
            mstore(add(ptr, 0x140), keccak256(ptr, interactions.length))
            calldatacopy(add(ptr, 0x20), order, 0x120)
            mstore(ptr, typehash)
            result := keccak256(ptr, 0x160)
        }
        result = ECDSA.toTypedDataHash(domainSeparator, result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../libraries/RevertReasonForwarder.sol";

library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            let status := call(gas(), token, 0, data, 100, 0x0, 0x20)
            success := and(status, or(iszero(returndatasize()), and(gt(returndatasize(), 31), eq(mload(0), 1))))
        }
        if (!success) {
            revert SafeTransferFromFailed();
        }
    }

    // Ensures method do not revert or return boolean `true`, admits call to non-smart-contract
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    // If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (!_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value))
            {
                revert ForceApproveFailed();
            }
        }
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    function safePermit(IERC20 token, bytes calldata permit) internal {
        bool success;
        if (permit.length == 32 * 7) {
            success = _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        } else if (permit.length == 32 * 8) {
            success = _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        } else {
            revert SafePermitBadLength();
        }

        if (!success) {
            RevertReasonForwarder.reRevert();
        }
    }

    function _makeCall(IERC20 token, bytes4 selector, address to, uint256 amount) private returns(bool done) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            let success := call(gas(), token, 0, data, 68, 0x0, 0x20)
            done := and(
                success,
                or(
                    iszero(returndatasize()),
                    and(gt(returndatasize(), 31), eq(mload(0), 1))
                )
            )
        }
    }

    function _makeCalldataCall(IERC20 token, bytes4 selector, bytes calldata args) private returns(bool done) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            let success := call(gas(), token, 0, data, len, 0x0, 0x20)
            done := and(
                success,
                or(
                    iszero(returndatasize()),
                    and(gt(returndatasize(), 31), eq(mload(0), 1))
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

library RevertReasonForwarder {
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";

library ECDSA {
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns(address signer) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, hash)
            mstore(add(ptr, 0x20), v)
            mstore(add(ptr, 0x40), r)
            mstore(add(ptr, 0x60), s)
            if staticcall(gas(), 0x1, ptr, 0x80, 0, 0x20) {
                signer := mload(0)
            }
        }
    }

    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns(address signer) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, hash)
            mstore(add(ptr, 0x20), add(27, shr(255, vs)))
            mstore(add(ptr, 0x40), r)
            mstore(add(ptr, 0x60), shr(1, shl(1, vs)))
            if staticcall(gas(), 0x1, ptr, 0x80, 0, 0x20) {
                signer := mload(0)
            }
        }
    }

    function recover(bytes32 hash, bytes calldata signature) internal view returns(address signer) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            // memory[ptr:ptr+0x80] = (hash, v, r, s)
            switch signature.length
            case 65 {
                // memory[ptr+0x20:ptr+0x80] = (v, r, s)
                mstore(add(ptr, 0x20), byte(0, calldataload(add(signature.offset, 0x40))))
                calldatacopy(add(ptr, 0x40), signature.offset, 0x40)
            }
            case 64 {
                // memory[ptr+0x20:ptr+0x80] = (v, r, s)
                let vs := calldataload(add(signature.offset, 0x20))
                mstore(add(ptr, 0x20), add(27, shr(255, vs)))
                calldatacopy(add(ptr, 0x40), signature.offset, 0x20)
                mstore(add(ptr, 0x60), shr(1, shl(1, vs)))
            }
            default {
                ptr := 0
            }

            if ptr {
                if gt(mload(add(ptr, 0x60)), 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                    ptr := 0
                }

                if ptr {
                    // memory[ptr:ptr+0x20] = (hash)
                    mstore(ptr, hash)

                    if staticcall(gas(), 0x1, ptr, 0x80, 0, 0x20) {
                        signer := mload(0)
                    }
                }
            }
        }
    }

    function recoverOrIsValidSignature(address signer, bytes32 hash, bytes calldata signature) internal view returns(bool success) {
        if ((signature.length == 64 || signature.length == 65) && recover(hash, signature) == signer) {
            return true;
        }
        return isValidSignature(signer, hash, signature);
    }

    function recoverOrIsValidSignature(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns(bool success) {
        if (recover(hash, v, r, s) == signer) {
            return true;
        }
        return isValidSignature(signer, hash, v, r, s);
    }

    function recoverOrIsValidSignature(address signer, bytes32 hash, bytes32 r, bytes32 vs) internal view returns(bool success) {
        if (recover(hash, r, vs) == signer) {
            return true;
        }
        return isValidSignature(signer, hash, r, vs);
    }

    function recoverOrIsValidSignature65(address signer, bytes32 hash, bytes32 r, bytes32 vs) internal view returns(bool success) {
        if (recover(hash, r, vs) == signer) {
            return true;
        }
        return isValidSignature65(signer, hash, r, vs);
    }

    function isValidSignature(address signer, bytes32 hash, bytes calldata signature) internal view returns(bool success) {
        // (bool success, bytes memory data) = signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature));
        // return success && data.length >= 4 && abi.decode(data, (bytes4)) == IERC1271.isValidSignature.selector;
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            let len := add(0x64, signature.length)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), signature.length)
            calldatacopy(add(ptr, 0x64), signature.offset, signature.length)
            mstore(0, 0)
            if staticcall(gas(), signer, ptr, len, 0, 0x20) {
                success := eq(selector, mload(0))
            }
        }
    }

    function isValidSignature(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns(bool success) {
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            let len := add(0x64, 65)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), 65)
            mstore(add(ptr, 0x64), r)
            mstore(add(ptr, 0x84), s)
            mstore8(add(ptr, 0xa4), v)
            mstore(0, 0)
            if staticcall(gas(), signer, ptr, len, 0, 0x20) {
                success := eq(selector, mload(0))
            }
        }
    }

    function isValidSignature(address signer, bytes32 hash, bytes32 r, bytes32 vs) internal view returns(bool success) {
        // (bool success, bytes memory data) = signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, abi.encodePacked(r, vs)));
        // return success && data.length >= 4 && abi.decode(data, (bytes4)) == IERC1271.isValidSignature.selector;
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            let len := add(0x64, 64)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), 64)
            mstore(add(ptr, 0x64), r)
            mstore(add(ptr, 0x84), vs)
            mstore(0, 0)
            if staticcall(gas(), signer, ptr, len, 0, 0x20) {
                success := eq(selector, mload(0))
            }
        }
    }

    function isValidSignature65(address signer, bytes32 hash, bytes32 r, bytes32 vs) internal view returns(bool success) {
        // (bool success, bytes memory data) = signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, abi.encodePacked(r, vs & ~uint256(1 << 255), uint8(vs >> 255))));
        // return success && data.length >= 4 && abi.decode(data, (bytes4)) == IERC1271.isValidSignature.selector;
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            let len := add(0x64, 65)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), 65)
            mstore(add(ptr, 0x64), r)
            mstore(add(ptr, 0x84), shr(1, shl(1, vs)))
            mstore8(add(ptr, 0xa4), add(27, shr(255, vs)))
            mstore(0, 0)
            if staticcall(gas(), signer, ptr, len, 0, 0x20) {
                success := eq(selector, mload(0))
            }
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 res) {
        // 32 is the length in bytes of hash, enforced by the type signature above
        // return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            mstore(0, 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000) // "\x19Ethereum Signed Message:\n32"
            mstore(28, hash)
            res := keccak256(0, 60)
        }
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 res) {
        // return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, 0x1901000000000000000000000000000000000000000000000000000000000000) // "\x19\x01"
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            res := keccak256(ptr, 66)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;


interface IDaiLikePermit {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "./interfaces/IWETH.sol";

abstract contract OnlyWethReceiver {
    error EthDepositRejected();

    IWETH internal immutable _WETH;  // solhint-disable-line var-name-mixedcase

    constructor(IWETH weth) {
        _WETH = weth;
    }

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != address(_WETH)) revert EthDepositRejected();
    }
}