// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
// ══════════════════════════════ LIBRARY IMPORTS ══════════════════════════════
import { TipsLib } from "../libs/Tips.sol";
import { TypeCasts } from "../libs/TypeCasts.sol";

// ═════════════════════════════ INTERNAL IMPORTS ══════════════════════════════
import { IMessageRecipient } from "../interfaces/IMessageRecipient.sol";
import { InterfaceOrigin } from "../interfaces/InterfaceOrigin.sol";

contract TestClient is IMessageRecipient {
    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              IMMUTABLES                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    // local chain Origin: used for sending messages
    address public immutable origin;

    // local chain Destination: used for receiving messages
    address public immutable destination;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                                EVENTS                                ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    event MessageReceived(
        uint32 origin,
        uint32 nonce,
        bytes32 sender,
        uint256 rootSubmittedAt,
        bytes message
    );

    event MessageSent(
        uint32 destination,
        uint32 nonce,
        bytes32 sender,
        bytes32 recipient,
        bytes message
    );

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             CONSTRUCTOR                              ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    constructor(address _origin, address _destination) {
        origin = _origin;
        destination = _destination;
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          RECEIVING MESSAGES                          ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    function handle(
        uint32 _origin,
        uint32 _nonce,
        bytes32 _sender,
        uint256 _rootSubmittedAt,
        bytes memory _message
    ) external {
        require(msg.sender == destination, "TestClient: !destination");
        emit MessageReceived(_origin, _nonce, _sender, _rootSubmittedAt, _message);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           SENDING MESSAGES                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    function sendMessage(
        uint32 _destination,
        address _recipient,
        uint32 _optimisticSeconds,
        bytes memory _message
    ) external {
        bytes32 recipient = TypeCasts.addressToBytes32(_recipient);
        bytes memory tips = TipsLib.emptyTips();
        (uint32 nonce, ) = InterfaceOrigin(origin).dispatch(
            _destination,
            recipient,
            _optimisticSeconds,
            tips,
            _message
        );
        emit MessageSent(
            _destination,
            nonce,
            TypeCasts.addressToBytes32(address(this)),
            recipient,
            _message
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ByteString } from "./ByteString.sol";
import { TypedMemView } from "./TypedMemView.sol";

/// @dev Tips is a memory over over a formatted message tips payload.
type Tips is bytes29;
/// @dev Attach library functions to Tips
using {
    TipsLib.unwrap,
    TipsLib.version,
    TipsLib.notaryTip,
    TipsLib.broadcasterTip,
    TipsLib.proverTip,
    TipsLib.executorTip,
    TipsLib.totalTips
} for Tips global;

/**
 * @notice Library for versioned formatting [the tips part]
 * of [the messages used by Origin and Destination].
 */
library TipsLib {
    using ByteString for bytes;
    using TypedMemView for bytes29;

    uint16 internal constant TIPS_VERSION = 1;

    // TODO: determine if we need to pack the tips values,
    // or if using uint256 instead will suffice.

    /**
     * @dev Tips memory layout
     * [000 .. 002): version            uint16	 2 bytes
     * [002 .. 014): notaryTip          uint96	12 bytes
     * [014 .. 026): broadcasterTip     uint96	12 bytes
     * [026 .. 038): proverTip          uint96	12 bytes
     * [038 .. 050): executorTip        uint96	12 bytes
     */

    uint256 internal constant OFFSET_VERSION = 0;
    uint256 internal constant OFFSET_NOTARY = 2;
    uint256 internal constant OFFSET_BROADCASTER = 14;
    uint256 internal constant OFFSET_PROVER = 26;
    uint256 internal constant OFFSET_EXECUTOR = 38;

    uint256 internal constant TIPS_LENGTH = 50;

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                                 TIPS                                 ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a formatted Tips payload with provided fields
     * @param _notaryTip        Tip for the Notary
     * @param _broadcasterTip   Tip for the Broadcaster
     * @param _proverTip        Tip for the Prover
     * @param _executorTip      Tip for the Executor
     * @return Formatted tips
     **/
    function formatTips(
        uint96 _notaryTip,
        uint96 _broadcasterTip,
        uint96 _proverTip,
        uint96 _executorTip
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(TIPS_VERSION, _notaryTip, _broadcasterTip, _proverTip, _executorTip);
    }

    /**
     * @notice Returns a formatted Tips payload specifying empty tips.
     * @return Formatted tips
     **/
    function emptyTips() internal pure returns (bytes memory) {
        return formatTips(0, 0, 0, 0);
    }

    /**
     * @notice Returns a Tips view over for the given payload.
     * @dev Will revert if the payload is not a tips payload.
     */
    function castToTips(bytes memory _payload) internal pure returns (Tips) {
        return castToTips(_payload.castToRawBytes());
    }

    /**
     * @notice Casts a memory view to a Tips view.
     * @dev Will revert if the memory view is not over a tips payload.
     */
    function castToTips(bytes29 _view) internal pure returns (Tips) {
        require(isTips(_view), "Not a tips payload");
        return Tips.wrap(_view);
    }

    /// @notice Checks that a payload is a formatted Tips payload.
    function isTips(bytes29 _view) internal pure returns (bool) {
        uint256 length = _view.len();
        // Check if version exists in the payload
        if (length < OFFSET_NOTARY) return false;
        // Check that tips version and its length matches
        return _getVersion(_view) == TIPS_VERSION && length == TIPS_LENGTH;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Tips _tips) internal pure returns (bytes29) {
        return Tips.unwrap(_tips);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                             TIPS SLICING                             ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns version of formatted tips
    function version(Tips _tips) internal pure returns (uint16) {
        // Get the underlying memory view
        bytes29 _view = _tips.unwrap();
        return _getVersion(_view);
    }

    /// @notice Returns notaryTip field
    function notaryTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_NOTARY, 12));
    }

    /// @notice Returns broadcasterTip field
    function broadcasterTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_BROADCASTER, 12));
    }

    /// @notice Returns proverTip field
    function proverTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_PROVER, 12));
    }

    /// @notice Returns executorTip field
    function executorTip(Tips _tips) internal pure returns (uint96) {
        bytes29 _view = _tips.unwrap();
        return uint96(_view.indexUint(OFFSET_EXECUTOR, 12));
    }

    /// @notice Returns total tip amount.
    function totalTips(Tips _tips) internal pure returns (uint96) {
        // In practice there's no chance that the total tips value would not fit into uint96.
        // TODO: determine if we want to use uint256 here instead anyway.
        return notaryTip(_tips) + broadcasterTip(_tips) + proverTip(_tips) + executorTip(_tips);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           PRIVATE HELPERS                            ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Returns a version field without checking if payload is properly formatted.
    function _getVersion(bytes29 _view) private pure returns (uint16) {
        return uint16(_view.indexUint(OFFSET_VERSION, 2));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TypedMemView } from "./TypedMemView.sol";

library TypeCasts {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    function coerceBytes32(string memory _s) internal pure returns (bytes32 _b) {
        _b = bytes(_s).ref(0).index(0, uint8(bytes(_s).length));
    }

    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf) internal pure returns (string memory _newStr) {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        uint32 _nonce,
        bytes32 _sender,
        uint256 _rootTimestamp,
        bytes memory _message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface InterfaceOrigin {
    /**
     * @notice Dispatch the message to the recipient located on destination domain.
     * @param _destination          Domain of destination chain
     * @param _recipient            Address of recipient on destination chain as bytes32
     * @param _optimisticSeconds    Optimistic period for message execution on destination chain
     * @param _tips                 Payload with information about paid tips
     * @param _messageBody          Raw bytes content of message
     * @return messageNonce         Nonce of the dispatched message
     * @return messageHash          Hash of the dispatched message
     */
    function dispatch(
        uint32 _destination,
        bytes32 _recipient,
        uint32 _optimisticSeconds,
        bytes memory _tips,
        bytes memory _messageBody
    ) external payable returns (uint32 messageNonce, bytes32 messageHash);

    /**
     * @notice Verifies a state from the snapshot (a list of states) signed by a Guard or a Notary.
     * Does nothing, if the state is valid (matches the historical state of this contract).
     * Slashes the snapshot signer, if the state is invalid.
     * @dev Will revert if any of these is true:
     *  - Snapshot payload is not properly formatted.
     *  - Attestation payload is not properly formatted.
     *  - Attestation signer is not an active Notary.
     *  - Attestation root is not equal to root derived from the snapshot.
     *  - State index is out of range.
     *  - Snapshot state does not refer to this chain.
     * @param _snapPayload      Raw payload with snapshot data
     * @param _stateIndex       State index to check
     * @param _attPayload       Raw payload with Attestation data
     * @param _attSignature     Notary signature for the attestation
     * @return isValid          Whether the requested state is valid.
     *                          Notary is slashed, if return value is FALSE.
     */
    function verifyAttestation(
        bytes memory _snapPayload,
        uint256 _stateIndex,
        bytes memory _attPayload,
        bytes memory _attSignature
    ) external returns (bool isValid);

    /**
     * @notice Verifies a state from the snapshot (a list of states) signed by a Guard or a Notary.
     * Does nothing, if the state is valid (matches the historical state of this contract).
     * Slashes the snapshot signer, if the state is invalid.
     * @dev Will revert if any of these is true:
     *  - Snapshot payload is not properly formatted.
     *  - Snapshot signer is not an active Agent.
     *  - State index is out of range.
     *  - Snapshot state does not refer to this chain.
     * @param _snapPayload      Raw payload with snapshot data
     * @param _stateIndex       State index to check
     * @param _snapSignature    Agent signature for the snapshot
     * @return isValid          Whether the requested state is valid.
     *                          Agent is slashed, if return value is FALSE.
     */
    function verifySnapshot(
        bytes memory _snapPayload,
        uint256 _stateIndex,
        bytes memory _snapSignature
    ) external returns (bool isValid);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TypedMemView } from "./TypedMemView.sol";

/// @dev CallData is a memory view over the payload to be used for an external call, i.e.
/// recipient.call(callData). Its length is always (4 + 32 * N) bytes:
/// - First 4 bytes represent the function selector.
/// - 32 * N bytes represent N words that function arguments occupy.
type CallData is bytes29;
/// @dev Signature is a memory view over a "65 bytes" array representing a ECDSA signature.
type Signature is bytes29;

library ByteString {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;

    /**
     * @dev non-compact ECDSA signatures are enforced as of OZ 4.7.3
     *
     *      Signature payload memory layout
     * [000 .. 032) r   bytes32 32 bytes
     * [032 .. 064) s   bytes32 32 bytes
     * [064 .. 065) v   uint8    1 byte
     */
    uint256 internal constant SIGNATURE_LENGTH = 65;
    uint256 internal constant OFFSET_R = 0;
    uint256 internal constant OFFSET_S = 32;
    uint256 internal constant OFFSET_V = 64;

    /**
     * @dev Calldata memory layout
     * [000 .. 004) selector    bytes4  4 bytes
     *      Optional: N function arguments
     * [004 .. 036) arg1        bytes32 32 bytes
     *      ..
     * [AAA .. END) argN        bytes32 32 bytes
     */
    uint256 internal constant SELECTOR_LENGTH = 4;
    uint256 internal constant OFFSET_SELECTOR = 0;
    uint256 internal constant OFFSET_ARGUMENTS = SELECTOR_LENGTH;

    /**
     * @notice Returns a memory view over the given payload, treating it as raw bytes.
     * @dev Shortcut for .ref(0) - to be deprecated once "uint40 type" is removed from bytes29.
     */
    function castToRawBytes(bytes memory _payload) internal pure returns (bytes29) {
        return _payload.ref({ newType: 0 });
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                              SIGNATURE                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Constructs the signature payload from the given values.
     * @dev Using ByteString.formatSignature({r: r, s: s, v: v}) will make sure
     * that params are given in the right order.
     */
    function formatSignature(
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, v);
    }

    /**
     * @notice Returns a Signature view over for the given payload.
     * @dev Will revert if the payload is not a signature.
     */
    function castToSignature(bytes memory _payload) internal pure returns (Signature) {
        return castToSignature(castToRawBytes(_payload));
    }

    /**
     * @notice Casts a memory view to a Signature view.
     * @dev Will revert if the memory view is not over a signature.
     */
    function castToSignature(bytes29 _view) internal pure returns (Signature) {
        require(isSignature(_view), "Not a signature");
        return Signature.wrap(_view);
    }

    /**
     * @notice Checks that a byte string is a signature
     */
    function isSignature(bytes29 _view) internal pure returns (bool) {
        return _view.len() == SIGNATURE_LENGTH;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(Signature _signature) internal pure returns (bytes29) {
        return Signature.unwrap(_signature);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                          SIGNATURE SLICING                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /// @notice Unpacks signature payload into (r, s, v) parameters.
    /// @dev Make sure to verify signature length with isSignature() beforehand.
    function toRSV(Signature _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        // Get the underlying memory view
        bytes29 _view = unwrap(_signature);
        r = _view.index({ _index: OFFSET_R, _bytes: 32 });
        s = _view.index({ _index: OFFSET_S, _bytes: 32 });
        v = uint8(_view.indexUint({ _index: OFFSET_V, _bytes: 1 }));
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                               CALLDATA                               ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns a CallData view over for the given payload.
     * @dev Will revert if the memory view is not over a calldata.
     */
    function castToCallData(bytes memory _payload) internal pure returns (CallData) {
        return castToCallData(castToRawBytes(_payload));
    }

    /**
     * @notice Casts a memory view to a CallData view.
     * @dev Will revert if the memory view is not over a calldata.
     */
    function castToCallData(bytes29 _view) internal pure returns (CallData) {
        require(isCallData(_view), "Not a calldata");
        return CallData.wrap(_view);
    }

    /**
     * @notice Checks that a byte string is a valid calldata, i.e.
     * a function selector, followed by arbitrary amount of arguments.
     */
    function isCallData(bytes29 _view) internal pure returns (bool) {
        uint256 length = _view.len();
        // Calldata should at least have a function selector
        if (length < SELECTOR_LENGTH) return false;
        // The remainder of the calldata should be exactly N words (N >= 0), i.e.
        // (length - SELECTOR_LENGTH) % 32 == 0
        // We're using logical AND here to speed it up a bit
        return (length - SELECTOR_LENGTH) & 31 == 0;
    }

    /// @notice Convenience shortcut for unwrapping a view.
    function unwrap(CallData _callData) internal pure returns (bytes29) {
        return CallData.unwrap(_callData);
    }

    /*╔══════════════════════════════════════════════════════════════════════╗*\
    ▏*║                           CALLDATA SLICING                           ║*▕
    \*╚══════════════════════════════════════════════════════════════════════╝*/

    /**
     * @notice Returns amount of memory words (32 byte chunks) the function arguments
     * occupy in the calldata.
     * @dev This might differ from amount of arguments supplied, if any of the arguments
     * occupies more than one memory slot. It is true, however, that argument part of the payload
     * occupies exactly N words, even for dynamic types like `bytes`
     */
    function argumentWords(CallData _callData) internal pure returns (uint256) {
        // Get the underlying memory view
        bytes29 _view = unwrap(_callData);
        // Equivalent of (length - SELECTOR_LENGTH) / 32
        return (_view.len() - SELECTOR_LENGTH) >> 5;
    }

    /// @notice Returns selector for the provided calldata.
    function callSelector(CallData _callData) internal pure returns (bytes29) {
        // Get the underlying memory view
        bytes29 _view = unwrap(_callData);
        return _view.slice({ _index: OFFSET_SELECTOR, _len: SELECTOR_LENGTH, newType: 0 });
    }

    /// @notice Returns abi encoded arguments for the provided calldata.
    function arguments(CallData _callData) internal pure returns (bytes29) {
        // Get the underlying memory view
        bytes29 _view = unwrap(_callData);
        return _view.sliceFrom({ _index: OFFSET_ARGUMENTS, newType: 0 });
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.12;

library TypedMemView {
    // Why does this exist?
    // the solidity `bytes memory` type has a few weaknesses.
    // 1. You can't index ranges effectively
    // 2. You can't slice without copying
    // 3. The underlying data may represent any type
    // 4. Solidity never deallocates memory, and memory costs grow
    //    superlinearly

    // By using a memory view instead of a `bytes memory` we get the following
    // advantages:
    // 1. Slices are done on the stack, by manipulating the pointer
    // 2. We can index arbitrary ranges and quickly convert them to stack types
    // 3. We can insert type info into the pointer, and typecheck at runtime

    // This makes `TypedMemView` a useful tool for efficient zero-copy
    // algorithms.

    // Why bytes29?
    // We want to avoid confusion between views, digests, and other common
    // types so we chose a large and uncommonly used odd number of bytes
    //
    // Note that while bytes are left-aligned in a word, integers and addresses
    // are right-aligned. This means when working in assembly we have to
    // account for the 3 unused bytes on the righthand side
    //
    // First 5 bytes are a type flag.
    // - ff_ffff_fffe is reserved for unknown type.
    // - ff_ffff_ffff is reserved for invalid types/errors.
    // next 12 are memory address
    // next 12 are len
    // bottom 3 bytes are empty

    // Assumptions:
    // - non-modification of memory.
    // - No Solidity updates
    // - - wrt free mem point
    // - - wrt bytes representation in memory
    // - - wrt memory addressing in general

    // Usage:
    // - create type constants
    // - use `assertType` for runtime type assertions
    // - - unfortunately we can't do this at compile time yet :(
    // - recommended: implement modifiers that perform type checking
    // - - e.g.
    // - - `uint40 constant MY_TYPE = 3;`
    // - - ` modifier onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
    // - instantiate a typed view from a bytearray using `ref`
    // - use `index` to inspect the contents of the view
    // - use `slice` to create smaller views into the same memory
    // - - `slice` can increase the offset
    // - - `slice can decrease the length`
    // - - must specify the output type of `slice`
    // - - `slice` will return a null view if you try to overrun
    // - - make sure to explicitly check for this with `notNull` or `assertType`
    // - use `equal` for typed comparisons.

    // The null view
    bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    /**
     * @dev Memory layout for bytes29
     * TODO (Chi): with the user defined types storing type is no longer necessary.
     * Update the library, transforming bytes29 to bytes24 in the process.
     * [000..005)   type     5 bytes    Type flag for the pointer
     * [005..017)   loc     12 bytes    Memory address of underlying bytes
     * [017..029)   len     12 bytes    Length of underlying bytes
     * [029..032)   empty    3 bytes    Not used
     */
    uint256 public constant BITS_TYPE = 40;
    uint256 public constant BITS_LOC = 96;
    uint256 public constant BITS_LEN = 96;
    uint256 public constant BITS_EMPTY = 24;

    // `SHIFT_X` is how much bits to shift for `X` to be in the very bottom bits
    uint256 public constant SHIFT_LEN = BITS_EMPTY; // 24
    uint256 public constant SHIFT_LOC = SHIFT_LEN + BITS_LEN; // 24 + 96 = 120
    uint256 public constant SHIFT_TYPE = SHIFT_LOC + BITS_LOC; // 24 + 96 + 96 = 216
    // Bitmask for the lowest 96 bits
    uint256 public constant LOW_96_BITS_MASK = type(uint96).max;

    // For nibble encoding
    bytes private constant NIBBLE_LOOKUP = "0123456789abcdef";

    /**
     * @notice Returns the encoded hex character that represents the lower 4 bits of the argument.
     * @param _byte     The byte
     * @return _char    The encoded hex character
     */
    function nibbleHex(uint8 _byte) internal pure returns (uint8 _char) {
        uint8 _nibble = _byte & 0x0f; // keep bottom 4 bits, zero out top 4 bits
        _char = uint8(NIBBLE_LOOKUP[_nibble]);
    }

    /**
     * @notice      Returns a uint16 containing the hex-encoded byte.
     * @param _b    The byte
     * @return      encoded - The hex-encoded byte
     */
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    /**
     * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
     *              `second` contains the encoded lower 16 bytes.
     *
     * @param _b    The 32 bytes as uint256
     * @return      first - The top 16 bytes
     * @return      second - The bottom 16 bytes
     */
    function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
        for (uint8 i = 31; i > 15; ) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
            unchecked {
                i -= 1;
            }
        }

        // abusing underflow here =_=
        for (uint8 i = 15; i < 255; ) {
            uint8 _byte = uint8(_b >> (i * 8));
            second |= byteHex(_byte);
            if (i != 0) {
                second <<= 16;
            }
            unchecked {
                i -= 1;
            }
        }
    }

    /**
     * @notice          Changes the endianness of a uint256.
     * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
     * @param _b        The unsigned integer to reverse
     * @return          v - The reversed value
     */
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v =
            ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v =
            ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v =
            ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v =
            ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /**
     * @notice      Create a mask with the highest `_len` bits set.
     * @param _len  The length
     * @return      mask - The mask
     */
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        // 0x800...00 binary representation is 100...00
        // sar stands for "signed arithmetic shift": https://en.wikipedia.org/wiki/Arithmetic_shift
        // sar(N-1, 100...00) = 11...100..00, with exactly N highest bits set to 1
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            mask := sar(
                sub(_len, 1),
                0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /**
     * @notice      Return the null view.
     * @return      bytes29 - The null view
     */
    // solhint-disable-next-line ordering
    function nullView() internal pure returns (bytes29) {
        return NULL;
    }

    /**
     * @notice      Check if the view is null.
     * @return      bool - True if the view is null
     */
    function isNull(bytes29 memView) internal pure returns (bool) {
        return memView == NULL;
    }

    /**
     * @notice      Check if the view is not null.
     * @return      bool - True if the view is not null
     */
    function notNull(bytes29 memView) internal pure returns (bool) {
        return !isNull(memView);
    }

    /**
     * @notice          Check if the view is of a valid type and points to a valid location
     *                  in memory.
     * @dev             We perform this check by examining solidity's unallocated memory
     *                  pointer and ensuring that the view's upper bound is less than that.
     * @param memView   The view
     * @return          ret - True if the view is valid
     */
    function isValid(bytes29 memView) internal pure returns (bool ret) {
        if (typeOf(memView) == 0xffffffffff) {
            return false;
        }
        uint256 _end = end(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // View is valid if ("upper bound" <= "unallocated memory pointer")
            // Upper bound is exclusive, hence "<="
            ret := not(gt(_end, mload(0x40)))
        }
    }

    /**
     * @notice          Require that a typed memory view be valid.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @return          bytes29 - The validated view
     */
    function assertValid(bytes29 memView) internal pure returns (bytes29) {
        require(isValid(memView), "Validity assertion failed");
        return memView;
    }

    /**
     * @notice          Return true if the memview is of the expected type. Otherwise false.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bool - True if the memview is of the expected type
     */
    function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
        return typeOf(memView) == _expected;
    }

    /**
     * @notice          Require that a typed memory view has a specific type.
     * @dev             Returns the view for easy chaining.
     * @param memView   The view
     * @param _expected The expected type
     * @return          bytes29 - The view with validated type
     */
    function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
        if (!isType(memView, _expected)) {
            (, uint256 g) = encodeHex(uint256(typeOf(memView)));
            (, uint256 e) = encodeHex(uint256(_expected));
            string memory err = string(
                abi.encodePacked(
                    "Type assertion failed. Got 0x",
                    uint80(g),
                    ". Expected 0x",
                    uint80(e)
                )
            );
            revert(err);
        }
        return memView;
    }

    /**
     * @notice          Return an identical view with a different type.
     * @param memView   The view
     * @param _newType  The new type
     * @return          newView - The new view with the specified type
     */
    function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
        // How many bits are the "type bits" occupying
        uint256 _bitsType = BITS_TYPE;
        // How many bits are the "type bits" shifted from the bottom
        uint256 _shiftType = SHIFT_TYPE;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // shift off the "type bits" (shift left, then sift right)
            newView := or(newView, shr(_bitsType, shl(_bitsType, memView)))
            // set the new "type bits" (shift left, then OR)
            newView := or(newView, shl(_shiftType, _newType))
        }
    }

    /**
     * @notice          Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Unsafe raw pointer construction. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function unsafeBuildUnchecked(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) private pure returns (bytes29 newView) {
        uint256 _bitsLoc = BITS_LOC;
        uint256 _bitsLen = BITS_LEN;
        uint256 _bitsEmpty = BITS_EMPTY;
        // Ref memory layout
        // [000..005) 5 bytes of type
        // [005..017) 12 bytes of location
        // [017..029) 12 bytes of length
        // last 3 bits are blank and dropped in typecast
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // insert `type`, shift to prepare empty bits for `loc`
            newView := shl(_bitsLoc, or(newView, _type))
            // insert `loc`, shift to prepare empty bits for `len`
            newView := shl(_bitsLen, or(newView, _loc))
            // insert `len`, shift to insert 3 blank lowest bits
            newView := shl(_bitsEmpty, or(newView, _len))
        }
    }

    /**
     * @notice          Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @dev             Instantiate a new memory view. This should generally not be called
     *                  directly. Prefer `ref` wherever possible.
     * @param _type     The type
     * @param _loc      The memory address
     * @param _len      The length
     * @return          newView - The new view with the specified type, location and length
     */
    function build(
        uint256 _type,
        uint256 _loc,
        uint256 _len
    ) internal pure returns (bytes29 newView) {
        uint256 _end = _loc + _len;
        // Make sure that a view is not constructed that points to unallocated memory
        // as this could be indicative of a buffer overflow attack
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = unsafeBuildUnchecked(_type, _loc, _len);
    }

    /**
     * @notice          Instantiate a memory view from a byte array.
     * @dev             Note that due to Solidity memory representation, it is not possible to
     *                  implement a deref, as the `bytes` type stores its len in memory.
     * @param arr       The byte array
     * @param newType   The type
     * @return          bytes29 - The memory view
     */
    function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
        uint256 _len = arr.length;
        // `bytes arr` is stored in memory in the following way
        // 1. First, uint256 arr.length is stored. That requires 32 bytes (0x20).
        // 2. Then, the array data is stored.
        uint256 _loc;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // We add 0x20, so that the view starts exactly where the array data starts
            _loc := add(arr, 0x20)
        }

        return build(newType, _loc, _len);
    }

    /**
     * @notice          Return the associated type information.
     * @param memView   The memory view
     * @return          _type - The type associated with the view
     */
    function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
        // How many bits are the "type bits" shifted from the bottom
        uint256 _shiftType = SHIFT_TYPE;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Shift out the bottom bits preceding "type bits". "type bits" are occupying
            // the highest bits, so all that's left is "type bits", OR is not required.
            _type := shr(_shiftType, memView)
        }
    }

    /**
     * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the 5-byte type flag is equal
     */
    function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
        // Check that the highest 5 bytes are equal: xor and shift out lower 27 bytes
        return (left ^ right) >> SHIFT_TYPE == 0;
    }

    /**
     * @notice          Return the memory address of the underlying bytes.
     * @param memView   The view
     * @return          _loc - The memory address
     */
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        // How many bits are the "loc bits" shifted from the bottom
        uint256 _shiftLoc = SHIFT_LOC;
        // Mask for the bottom 96 bits
        uint256 _uint96Mask = LOW_96_BITS_MASK;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Shift out the bottom bits preceding "loc bits".
            // Then use the lowest 96 bits to determine `loc` by applying the bit-mask.
            _loc := and(shr(_shiftLoc, memView), _uint96Mask)
        }
    }

    /**
     * @notice          The number of memory words this memory view occupies, rounded up.
     * @param memView   The view
     * @return          uint256 - The number of memory words
     */
    function words(bytes29 memView) internal pure returns (uint256) {
        // returning ceil(length / 32.0)
        return (uint256(len(memView)) + 31) / 32;
    }

    /**
     * @notice          The in-memory footprint of a fresh copy of the view.
     * @param memView   The view
     * @return          uint256 - The in-memory footprint of a fresh copy of the view.
     */
    function footprint(bytes29 memView) internal pure returns (uint256) {
        return words(memView) * 32;
    }

    /**
     * @notice          The number of bytes of the view.
     * @param memView   The view
     * @return          _len - The length of the view
     */
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        // How many bits are the "len bits" shifted from the bottom
        uint256 _shiftLen = SHIFT_LEN;
        // Mask for the bottom 96 bits
        uint256 _uint96Mask = LOW_96_BITS_MASK;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Shift out the bottom bits preceding "len bits".
            // Then use the lowest 96 bits to determine `len` by applying the bit-mask.
            _len := and(shr(_shiftLen, memView), _uint96Mask)
        }
    }

    /**
     * @notice          Returns the endpoint of `memView`.
     * @param memView   The view
     * @return          uint256 - The endpoint of `memView`
     */
    function end(bytes29 memView) internal pure returns (uint256) {
        unchecked {
            return loc(memView) + len(memView);
        }
    }

    /**
     * @notice          Safe slicing without memory modification.
     * @param memView   The view
     * @param _index    The start index
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function slice(
        bytes29 memView,
        uint256 _index,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        uint256 _loc = loc(memView);

        // Ensure it doesn't overrun the view
        if (_loc + _index + _len > end(memView)) {
            return NULL;
        }

        _loc = _loc + _index;
        return build(newType, _loc, _len);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing
     *                  bytes from `_index` to end(memView).
     * @param memView   The view
     * @param _index    The start index
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function sliceFrom(
        bytes29 memView,
        uint256 _index,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, _index, len(memView) - _index, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function prefix(
        bytes29 memView,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, 0, _len, newType);
    }

    /**
     * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
     * @param memView   The view
     * @param _len      The length
     * @param newType   The new type
     * @return          bytes29 - The new view
     */
    function postfix(
        bytes29 memView,
        uint256 _len,
        uint40 newType
    ) internal pure returns (bytes29) {
        return slice(memView, uint256(len(memView)) - _len, _len, newType);
    }

    /**
     * @notice          Construct an error message for an indexing overrun.
     * @param _loc      The memory address
     * @param _len      The length
     * @param _index    The index
     * @param _slice    The slice where the overrun occurred
     * @return          err - The err
     */
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /**
     * @notice          Load up to 32 bytes from the view onto the stack.
     * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
     *                  This can be immediately cast to a smaller fixed-length byte array.
     *                  To automatically cast to an integer, use `indexUint`.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The 32 byte result
     */
    function index(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (bytes32 result) {
        if (_bytes == 0) {
            return bytes32(0);
        }
        if (_index + _bytes > len(memView)) {
            revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
        }
        require(_bytes <= 32, "Index: more than 32 bytes");

        uint8 bitLength;
        unchecked {
            bitLength = _bytes * 8;
        }
        uint256 _loc = loc(memView);
        // Get a mask with `bitLength` highest bits set
        uint256 _mask = leftMask(bitLength);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // Load a full word using index offset, and apply mask to ignore non-relevant bytes
            result := and(mload(add(_loc, _index)), _mask)
        }
    }

    /**
     * @notice          Parse an unsigned integer from the view at `_index`.
     * @dev             Requires that the view have >= `_bytes` bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The unsigned integer
     */
    function indexUint(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (uint256 result) {
        // `index()` returns left-aligned `_bytes`, while integers are right-aligned
        // Shifting here to right-align with the full 32 bytes word
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /**
     * @notice          Parse an unsigned integer from LE bytes.
     * @param memView   The view
     * @param _index    The index
     * @param _bytes    The bytes
     * @return          result - The unsigned integer
     */
    function indexLEUint(
        bytes29 memView,
        uint256 _index,
        uint8 _bytes
    ) internal pure returns (uint256 result) {
        return reverseUint256(uint256(index(memView, _index, _bytes)));
    }

    /**
     * @notice          Parse an address from the view at `_index`.
     *                  Requires that the view have >= 20 bytes following that index.
     * @param memView   The view
     * @param _index    The index
     * @return          address - The address
     */
    function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
        // index 20 bytes as `uint160`, and then cast to `address`
        return address(uint160(indexUint(memView, _index, 20)));
    }

    /**
     * @notice          Return the keccak256 hash of the underlying memory
     * @param memView   The view
     * @return          digest - The keccak256 hash of the underlying memory
     */
    function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            digest := keccak256(_loc, _len)
        }
    }

    /**
     * @notice          Return the sha2 digest of the underlying memory.
     * @dev             We explicitly deallocate memory afterwards.
     * @param memView   The view
     * @return          digest - The sha2 hash of the underlying memory
     */
    function sha2(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // sha2 precompile is 0x02
            res := staticcall(gas(), 0x02, _loc, _len, ptr, 0x20)
            digest := mload(ptr)
        }
        require(res, "sha2: out of gas");
    }

    /**
     * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
     * @param memView   The pre-image
     * @return          digest - the Digest
     */
    function hash160(bytes29 memView) internal view returns (bytes20 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // sha2 precompile is 0x02
            res := staticcall(gas(), 0x02, _loc, _len, ptr, 0x20)
            // rmd160 precompile is 0x03
            res := and(res, staticcall(gas(), 0x03, ptr, 0x20, ptr, 0x20))
            digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
        }
        require(res, "hash160: out of gas");
    }

    /**
     * @notice          Implements bitcoin's hash256 (double sha2)
     * @param memView   A view of the preimage
     * @return          digest - the Digest
     */
    function hash256(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // sha2 precompile is 0x02
            res := staticcall(gas(), 0x02, _loc, _len, ptr, 0x20)
            res := and(res, staticcall(gas(), 0x02, ptr, 0x20, ptr, 0x20))
            digest := mload(ptr)
        }
        require(res, "hash256: out of gas");
    }

    /**
     * @notice          Return true if the underlying memory is equal. Else false.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the underlying memory is equal
     */
    function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return
            (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
    }

    /**
     * @notice          Return false if the underlying memory is equal. Else true.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - False if the underlying memory is equal
     */
    function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !untypedEqual(left, right);
    }

    /**
     * @notice          Compares type equality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are the same
     */
    function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
        return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
    }

    /**
     * @notice          Compares type inequality.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param left      The first view
     * @param right     The second view
     * @return          bool - True if the types are not the same
     */
    function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !equal(left, right);
    }

    /**
     * @notice          Copy the view to a location, return an unsafe memory reference
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memView   The view
     * @param _newLoc   The new location
     * @return          written - the unsafe memory reference
     */
    function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
        require(notNull(memView), "copyTo: Null pointer deref");
        require(isValid(memView), "copyTo: Invalid pointer deref");
        uint256 _len = len(memView);
        uint256 _oldLoc = loc(memView);

        uint256 ptr;
        bool res;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _newLoc) {
                revert(0x60, 0x20) // empty revert message
            }

            // use the identity precompile (0x04) to copy
            res := staticcall(gas(), 0x04, _oldLoc, _len, _newLoc, _len)
        }
        require(res, "identity: out of gas");

        written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
    }

    /**
     * @notice          Copies the referenced memory to a new loc in memory,
     *                  returning a `bytes` pointing to the new memory.
     * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
     * @param memView   The view
     * @return          ret - The view pointing to the new memory
     */
    function clone(bytes29 memView) internal view returns (bytes memory ret) {
        uint256 ptr;
        uint256 _len = len(memView);
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
            ret := ptr
        }
        unchecked {
            unsafeCopyTo(memView, ptr + 0x20);
        }
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
            mstore(ptr, _len) // write len of new array (in bytes)
        }
    }

    /**
     * @notice          Join the views in memory, return an unsafe reference to the memory.
     * @dev             Super Dangerous direct memory access.
     *
     *                  This reference can be overwritten if anything else modifies memory (!!!).
     *                  As such it MUST be consumed IMMEDIATELY.
     *                  This function is private to prevent unsafe usage by callers.
     * @param memViews  The views
     * @return          unsafeView - The conjoined view pointing to the new memory
     */
    function unsafeJoin(bytes29[] memory memViews, uint256 _location)
        private
        view
        returns (bytes29 unsafeView)
    {
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            let ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _location) {
                revert(0x60, 0x20) // empty revert message
            }
        }

        uint256 _offset = 0;
        for (uint256 i = 0; i < memViews.length; i++) {
            bytes29 memView = memViews[i];
            unchecked {
                unsafeCopyTo(memView, _location + _offset);
                _offset += len(memView);
            }
        }
        unsafeView = unsafeBuildUnchecked(0, _location, _offset);
    }

    /**
     * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The keccak256 digest
     */
    function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return keccak(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
     * @param memViews  The views
     * @return          bytes32 - The sha256 digest
     */
    function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return sha2(unsafeJoin(memViews, ptr));
    }

    /**
     * @notice          copies all views, joins them into a new bytearray.
     * @param memViews  The views
     * @return          ret - The new byte array
     */
    function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
        uint256 ptr;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }

        bytes29 _newView;
        unchecked {
            _newView = unsafeJoin(memViews, ptr + 0x20);
        }
        uint256 _written = len(_newView);
        uint256 _footprint = footprint(_newView);

        assembly {
            // solhint-disable-previous-line no-inline-assembly
            // store the length
            mstore(ptr, _written)
            // new pointer is old + 0x20 + the footprint of the body
            mstore(0x40, add(add(ptr, _footprint), 0x20))
            ret := ptr
        }
    }
}