// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";
import {IWormhole} from "wormhole-contracts/interfaces/IWormhole.sol";
import {IWormholeRelayerDelivery} from "wormhole-contracts/interfaces/relayer/IWormholeRelayerTyped.sol";

import {IWormholeApplication} from "./interfaces/IWormholeApplication.sol";
import {WormholeApplicationStorage} from "./WormholeApplicationStorage.sol";
import {ApplicationBase} from "ta-base-application/ApplicationBase.sol";
import {WormholeChainId, ReceiptVAAPayload, VaaKey} from "./interfaces/WormholeTypes.sol";
import {RelayerAddress} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";

/// @title WormholeApplication
/// @notice The Wormhole Application module is responsible for executing Wormhole messages and performing transaction allocation.
contract WormholeApplication is IWormholeApplication, ApplicationBase, WormholeApplicationStorage {
    uint256 constant EXPECTED_VM_VERSION = 1;
    uint256 constant SIGNATURE_SIZE = 66;
    uint256 constant VERSION_OFFSET = 0;
    uint256 constant SIGNATURE_LENGTH_OFFSET = 5;
    uint256 constant EMITTER_CHAIN_BODY_OFFSET = 14;
    uint256 constant EMITTER_ADDRESS_BODY_OFFSET = 16;
    uint256 constant SEQUENCE_ID_BODY_OFFSET = 48;

    using BytesLib for bytes;

    /// @inheritdoc IWormholeApplication
    function initializeWormholeApplication(IWormhole _wormhole, IWormholeRelayerDelivery _delivery) external {
        WHStorage storage ws = getWHStorage();
        if (ws.initialized) {
            revert AlreadyInitialized();
        }

        ws.initialized = true;
        ws.wormhole = _wormhole;
        ws.delivery = _delivery;

        emit Initialized(address(_wormhole), address(_delivery));
    }

    /// @inheritdoc IWormholeApplication
    function executeWormhole(
        bytes[] calldata _encodedVMs,
        bytes calldata _encodedDeliveryVAA,
        bytes calldata _deliveryOverrides
    ) external payable override {
        (uint64 deliveryVAASequenceNumber, WormholeChainId emitterChain, bytes32 emitterAddress) =
            _parseVAASelective(_encodedDeliveryVAA);
        _verifyTransaction(_hashSequenceNumber(deliveryVAASequenceNumber));

        // Forward the call the CoreRelayerDelivery with value
        (RelayerAddress relayerAddress,,) = _getCalldataParams();
        WHStorage storage whs = getWHStorage();
        whs.delivery.deliver{value: msg.value}(
            _encodedVMs, _encodedDeliveryVAA, payable(RelayerAddress.unwrap(relayerAddress)), _deliveryOverrides
        );

        // Generate a ReceiptVAA
        bytes memory receiptVAAPayload = abi.encode(
            ReceiptVAAPayload({
                relayerAddress: relayerAddress,
                deliveryVAAKey: VaaKey({
                    sequence: deliveryVAASequenceNumber,
                    chainId: WormholeChainId.unwrap(emitterChain),
                    emitterAddress: emitterAddress
                })
            })
        );
        whs.wormhole.publishMessage(0, receiptVAAPayload, whs.receiptVAAConsistencyLevel);

        emit WormholeDeliveryExecuted(_encodedDeliveryVAA);
    }

    /// @inheritdoc IWormholeApplication
    function allocateWormholeDeliveryVAA(
        RelayerAddress _relayerAddress,
        bytes[] calldata _requests,
        RelayerStateManager.RelayerState calldata _currentState
    ) external view override returns (bytes[] memory, uint256, uint256) {
        return _allocateTransaction(_relayerAddress, _requests, _currentState);
    }

    /// @dev Returns the transaction hash for the given wormhole transaction, by hashing the sequence number of the delivery request.
    /// @param _calldata The calldata of executeWormhole to hash. Ignores any appended data
    /// @return The transaction hash
    function _getTransactionHash(bytes calldata _calldata) internal pure virtual override returns (bytes32) {
        (, bytes memory encodedDeliveryVAA,) = abi.decode(_calldata[4:], (bytes[], bytes, bytes));
        (uint256 sequenceNumber,,) = _parseVAASelective(encodedDeliveryVAA);

        return _hashSequenceNumber(sequenceNumber);
    }

    /// @dev Hashes the sequence number of the delivery request.
    /// @param _sequenceNumber The sequence number of the delivery request
    /// @return The hash
    function _hashSequenceNumber(uint256 _sequenceNumber) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sequenceNumber));
    }

    /// @dev Parses the delivery VAA and returns the sequence number, emitter chain, and emitter address.
    ///      Does not perform signature validation, it is assumed that the VAA has already been validated or that it will be later.
    /// @param _encodedVAA The encoded delivery VAA
    /// @return sequenceNumber The sequence number of the delivery request
    /// @return emitterChain The chain ID of the emitter in wormhole format
    /// @return emitterAddress The address of the emitter in wormhole format
    function _parseVAASelective(bytes memory _encodedVAA)
        internal
        pure
        returns (uint64 sequenceNumber, WormholeChainId emitterChain, bytes32 emitterAddress)
    {
        // VAA Structure
        //
        // Offset (bytes) | Data                  | Size (bytes)
        // -----------------------------------------------------
        // 0              | version               | 1
        // 1              | guardian_set_index    | 4
        // 5              | len_signatures        | 1
        // 6              | signatures[0]         | 66
        // 72             | signatures[1]         | 66
        // ...            | ...                   | ...
        // 6 + 66n        | signatures[n]         | 66
        // (Body starts)
        // 6 + 66x        | timestamp             | 4
        // 10 + 66x       | nonce                 | 4
        // 14 + 66x       | emitter_chain         | 2
        // 16 + 66x       | emitter_address[0]    | 32
        // 48 + 66x       | sequence              | 8
        // 56 + 66x       | consistency_level     | 1
        // 57 + 66x       | payload[0]            | variable
        // ...            | ...                   | ...
        //
        // x = len_signatures
        uint256 version = _encodedVAA.toUint8(VERSION_OFFSET);
        if (version != EXPECTED_VM_VERSION) {
            revert VMVersionIncompatible(EXPECTED_VM_VERSION, version);
        }

        uint256 signersLen = _encodedVAA.toUint8(SIGNATURE_LENGTH_OFFSET);
        emitterChain =
            WormholeChainId.wrap(_encodedVAA.toUint16(EMITTER_CHAIN_BODY_OFFSET + SIGNATURE_SIZE * signersLen));
        emitterAddress = _encodedVAA.toBytes32(EMITTER_CHAIN_BODY_OFFSET + SIGNATURE_SIZE * signersLen + 2);
        sequenceNumber = _encodedVAA.toUint64(SEQUENCE_ID_BODY_OFFSET + SIGNATURE_SIZE * signersLen);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

import "./TypedUnits.sol";

/**
 * @notice VaaKey identifies a wormhole message
 *
 * @custom:member chainId - only specified if `infoType == VaaKeyType.EMITTER_SEQUENCE`
 * @custom:member emitterAddress - only specified if `infoType = VaaKeyType.EMITTER_SEQUENCE`
 * @custom:member sequence - only specified if `infoType = VaaKeyType.EMITTER_SEQUENCE`
 */
struct VaaKey {
    uint16 chainId;
    bytes32 emitterAddress;
    uint64 sequence;
}

interface IWormholeRelayerBase {
    event SendEvent(
        uint64 indexed sequence, LocalNative deliveryQuote, LocalNative paymentForExtraReceiverValue
    );

    function getRegisteredWormholeRelayerContract(uint16 chainId) external view returns (bytes32);
}

/**
 * IWormholeRelayer
 * @notice Users may use this interface to have payloads and/or wormhole VAAs
 *   relayed to destination contract(s) of their choice.
 */
interface IWormholeRelayerSend is IWormholeRelayerBase {
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit
    ) external payable returns (uint64 sequence);

    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable returns (uint64 sequence);

    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        Gas gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function forwardPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit
    ) external payable;

    function forwardVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        Gas gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable;

    function forwardToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        Gas gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    function forward(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        TargetNative receiverValue,
        LocalNative paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable;

    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        TargetNative newReceiverValue,
        Gas newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        TargetNative newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        TargetNative receiverValue,
        Gas gasLimit
    ) external view returns (LocalNative nativePriceQuote, GasPrice targetChainRefundPerGasUnused);

    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        TargetNative receiverValue,
        Gas gasLimit,
        address deliveryProviderAddress
    ) external view returns (LocalNative nativePriceQuote, GasPrice targetChainRefundPerGasUnused);

    function quoteDeliveryPrice(
        uint16 targetChain,
        TargetNative receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    ) external view returns (LocalNative nativePriceQuote, bytes memory encodedExecutionInfo);

    function quoteNativeForChain(
        uint16 targetChain,
        LocalNative currentChainAmount,
        address deliveryProviderAddress
    ) external view returns (TargetNative targetChainAmount);

    /**
     * @notice Returns the address of the current default delivery provider
     * @return deliveryProvider The address of (the default delivery provider)'s contract on this source
     *   chain. This must be a contract that implements IDeliveryProvider.
     */
    function getDefaultDeliveryProvider() external view returns (address deliveryProvider);
}

interface IWormholeRelayerDelivery is IWormholeRelayerBase {
    enum DeliveryStatus {
        SUCCESS,
        RECEIVER_FAILURE,
        FORWARD_REQUEST_FAILURE,
        FORWARD_REQUEST_SUCCESS
    }

    enum RefundStatus {
        REFUND_SENT,
        REFUND_FAIL,
        CROSS_CHAIN_REFUND_SENT,
        CROSS_CHAIN_REFUND_FAIL_PROVIDER_NOT_SUPPORTED,
        CROSS_CHAIN_REFUND_FAIL_NOT_ENOUGH
    }

    /**
     * @custom:member recipientContract - The target contract address
     * @custom:member sourceChain - The chain which this delivery was requested from (in wormhole
     *     ChainID format)
     * @custom:member sequence - The wormhole sequence number of the delivery VAA on the source chain
     *     corresponding to this delivery request
     * @custom:member deliveryVaaHash - The hash of the delivery VAA corresponding to this delivery
     *     request
     * @custom:member gasUsed - The amount of gas that was used to call your target contract (and, if
     *     there was a forward, to ensure that there were enough funds to complete the forward)
     * @custom:member status:
     *   - RECEIVER_FAILURE, if the target contract reverts
     *   - SUCCESS, if the target contract doesn't revert and no forwards were requested
     *   - FORWARD_REQUEST_FAILURE, if the target contract doesn't revert, forwards were requested,
     *       but provided/leftover funds were not sufficient to cover them all
     *   - FORWARD_REQUEST_SUCCESS, if the target contract doesn't revert and all forwards are covered
     * @custom:member additionalStatusInfo:
     *   - If status is SUCCESS or FORWARD_REQUEST_SUCCESS, then this is empty.
     *   - If status is RECEIVER_FAILURE, this is `RETURNDATA_TRUNCATION_THRESHOLD` bytes of the
     *       return data (i.e. potentially truncated revert reason information).
     *   - If status is FORWARD_REQUEST_FAILURE, this is also the revert data - the reason the forward failed.
     *     This will be either an encoded Cancelled, DeliveryProviderReverted, or DeliveryProviderPaymentFailed error
     * @custom:member refundStatus - Result of the refund. REFUND_SUCCESS or REFUND_FAIL are for
     *     refunds where targetChain=refundChain; the others are for targetChain!=refundChain,
     *     where a cross chain refund is necessary
     * @custom:member overridesInfo:
     *   - If not an override: empty bytes array
     *   - Otherwise: An encoded `DeliveryOverride`
     */
    event Delivery(
        address indexed recipientContract,
        uint16 indexed sourceChain,
        uint64 indexed sequence,
        bytes32 deliveryVaaHash,
        DeliveryStatus status,
        Gas gasUsed,
        RefundStatus refundStatus,
        bytes additionalStatusInfo,
        bytes overridesInfo
    );

    /**
     * @notice The relay provider calls `deliver` to relay messages as described by one delivery instruction
     * 
     * The relay provider must pass in the specified (by VaaKeys[]) signed wormhole messages (VAAs) from the source chain
     * as well as the signed wormhole message with the delivery instructions (the delivery VAA)
     *
     * The messages will be relayed to the target address (with the specified gas limit and receiver value) iff the following checks are met:
     * - the delivery VAA has a valid signature
     * - the delivery VAA's emitter is one of these WormholeRelayer contracts
     * - the delivery instruction container in the delivery VAA was fully funded
     * - msg.sender is the permissioned address allowed to execute this instruction
     * - the relay provider passed in at least enough of this chain's currency as msg.value (enough meaning the maximum possible refund)     * - the instruction's target chain is this chain
     * - the relayed signed VAAs match the descriptions in container.messages (the VAA hashes match, or the emitter address, sequence number pair matches, depending on the description given)
     *
     * @param encodedVMs - An array of signed wormhole messages (all from the same source chain
     *     transaction)
     * @param encodedDeliveryVAA - Signed wormhole message from the source chain's WormholeRelayer
     *     contract with payload being the encoded delivery instruction container
     * @param relayerRefundAddress - The address to which any refunds to the delivery provider
     *     should be sent
     * @param deliveryOverrides - Optional overrides field which must be either an empty bytes array or
     *     an encoded DeliveryOverride struct
     */
    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable;
}

interface IWormholeRelayer is IWormholeRelayerDelivery, IWormholeRelayerSend {}

/*
 *  Errors thrown by IWormholeRelayer contract
 */

// Bound chosen by the following formula: `memoryWord * 4 + selectorSize`.
// This means that an error identifier plus four fixed size arguments should be available to developers.
// In the case of a `require` revert with error message, this should provide 2 memory word's worth of data.
uint256 constant RETURNDATA_TRUNCATION_THRESHOLD = 132;

//When msg.value was not equal to (one wormhole message fee) + `maxTransactionFee` + `receiverValue`
error InvalidMsgValue(LocalNative msgValue, LocalNative totalFee);

error RequestedGasLimitTooLow();

error DeliveryProviderDoesNotSupportTargetChain(address relayer, uint16 chainId);
error DeliveryProviderCannotReceivePayment();

//When calling `forward()` on the WormholeRelayer if no delivery is in progress
error NoDeliveryInProgress();
//When calling `delivery()` a second time even though a delivery is already in progress
error ReentrantDelivery(address msgSender, address lockedBy);
//When any other contract but the delivery target calls `forward()` on the WormholeRelayer while a
//  delivery is in progress
error ForwardRequestFromWrongAddress(address msgSender, address deliveryTarget);

error InvalidPayloadId(uint8 parsed, uint8 expected);
error InvalidPayloadLength(uint256 received, uint256 expected);
error InvalidVaaKeyType(uint8 parsed);

error InvalidDeliveryVaa(string reason);
//When the delivery VAA (signed wormhole message with delivery instructions) was not emitted by the
//  registered WormholeRelayer contract
error InvalidEmitter(bytes32 emitter, bytes32 registered, uint16 chainId);
error VaaKeysLengthDoesNotMatchVaasLength(uint256 keys, uint256 vaas);
error VaaKeysDoNotMatchVaas(uint8 index);
//When someone tries to call an external function of the WormholeRelayer that is only intended to be
//  called by the WormholeRelayer itself (to allow retroactive reverts for atomicity)
error RequesterNotWormholeRelayer();

//When trying to relay a `DeliveryInstruction` to any other chain but the one it was specified for
error TargetChainIsNotThisChain(uint16 targetChain);
error ForwardNotSufficientlyFunded(LocalNative amountOfFunds, LocalNative amountOfFundsNeeded);
//When a `DeliveryOverride` contains a gas limit that's less than the original
error InvalidOverrideGasLimit();
//When a `DeliveryOverride` contains a receiver value that's less than the original
error InvalidOverrideReceiverValue();
//When a `DeliveryOverride` contains a refund per gas unused that's less than the original
error InvalidOverrideRefundPerGasUnused();

//When the relay provider doesn't pass in sufficient funds (i.e. msg.value does not cover the
// maximum possible refund to the user)
error InsufficientRelayerFunds(LocalNative msgValue, LocalNative minimum);

//When a bytes32 field can't be converted into a 20 byte EVM address, because the 12 padding bytes
//  are non-zero (duplicated from Utils.sol)
error NotAnEvmAddress(bytes32);

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IWormhole} from "wormhole-contracts/interfaces/IWormhole.sol";
import {IWormholeRelayerDelivery} from "wormhole-contracts/interfaces/relayer/IWormholeRelayerTyped.sol";

import {IWormholeApplicationEventsErrors} from "./IWormholeApplicationEventsErrors.sol";
import {RelayerAddress} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";
import {IApplicationBase} from "ta-base-application/interfaces/IApplicationBase.sol";

/// @title IWormholeApplication
interface IWormholeApplication is IWormholeApplicationEventsErrors, IApplicationBase {
    /// @notice Initialize the configuration on the wormhole application module.
    /// @param _wormhole The Wormhole Core Bridge contract.
    /// @param _delivery The Wormhole Relayer Delivery contract.
    function initializeWormholeApplication(IWormhole _wormhole, IWormholeRelayerDelivery _delivery) external;

    /// @notice Execute a wormhole relayer delivery. This is the primary entrypoint for all wormhole message execution.
    /// @param encodedVMs The encoded VMs corresponding to the DeliveryVAA.
    /// @param encodedDeliveryVAA The DeliveryVAA which contains the delivery instructions to execute.
    /// @param deliveryOverrides The delivery overrides to apply to the delivery.
    function executeWormhole(bytes[] memory encodedVMs, bytes memory encodedDeliveryVAA, bytes memory deliveryOverrides)
        external
        payable;

    /// @notice A helper function to return a list of calldata(executeWormhole()) that can be executed by the relayer.
    /// @param _relayerAddress The relayer address executing the delivery.
    /// @param _requests The list of calldata(executeWormhole()) that can be executed by the relayer.
    /// @param _currentState The current relayer state against which relayer selection is done.
    /// @return The list of calldata(executeWormhole()) that can be executed by the relayer.
    /// @return relayerGenerationIterationBitmap
    /// @return relayerIndex
    function allocateWormholeDeliveryVAA(
        RelayerAddress _relayerAddress,
        bytes[] calldata _requests,
        RelayerStateManager.RelayerState calldata _currentState
    ) external view returns (bytes[] memory, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IWormholeRelayerDelivery} from "wormhole-contracts/interfaces/relayer/IWormholeRelayerTyped.sol";
import {IWormhole} from "wormhole-contracts/interfaces/IWormhole.sol";

/// @title WormholeApplicationStorage
abstract contract WormholeApplicationStorage {
    bytes32 internal constant WORMHOLE_APPLICATION_STORAGE_SLOT = keccak256("WormholeApplication.storage");

    /// @dev The storage slot for the WormholeApplication module.
    /// @custom:member wormhole The Wormhole Core Bridge contract.
    /// @custom:member delivery The Wormhole Relayer Delivery contract.
    /// @custom:member receiptVAAConsistencyLevel The consistency level to use for emitting receipt VAA.
    /// @custom:member initialized Whether the WormholeApplication module has been initialized.
    struct WHStorage {
        IWormhole wormhole;
        IWormholeRelayerDelivery delivery;
        uint8 receiptVAAConsistencyLevel;
        bool initialized;
    }

    /* solhint-disable no-inline-assembly */
    function getWHStorage() internal pure returns (WHStorage storage ms) {
        bytes32 slot = WORMHOLE_APPLICATION_STORAGE_SLOT;
        assembly {
            ms.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IApplicationBase} from "./interfaces/IApplicationBase.sol";
import {RelayerAddress} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";
import {ITATransactionAllocation} from "ta-transaction-allocation/interfaces/ITATransactionAllocation.sol";

/// @title ApplicationBase
/// @dev This contract can be inherited by applications wishing to use BRN's services.
///      In general, an application module is responsible for implementing:
///      1. Transaction Alloction: Given a transaction, which "selected" relayer should process it?
///      2. Payments and refunds: The application should compensate the relayers for their work.
///      3. Provide a way for relayers to know which transactions they should process.
abstract contract ApplicationBase is IApplicationBase {
    /// @dev Verifies that the transaction was allocated to the relayer and other validations.
    ///      This function should be called by the application before processing the transaction.
    ///      Reverts if the transaction was not allocated to the relayer.
    /// @param _txHash Transaction hash of the transaction
    function _verifyTransaction(bytes32 _txHash) internal view {
        if (msg.sender != address(this)) {
            revert ExternalCallsNotAllowed();
        }

        (, uint256 relayerGenerationIterationBitmap, uint256 relayersPerWindow) = _getCalldataParams();

        if (!_verifyTransactionAllocation(_txHash, relayerGenerationIterationBitmap, relayersPerWindow)) {
            revert RelayerNotAssignedToTransaction();
        }
    }

    /// @dev The TransactionAllocator contract will append the some useful data at the end of the calldata. This function
    ///      extracts that data and returns it.
    /// @return relayerAddress Main Address of the relayer processing the transaction (not necessarily tx.origin)
    /// @return relayerGenerationIterationBitmap Bitmap with a set bit indicating a relayer is able to process the transaction
    ///         if the hashmod of the transaction hash falls at that index.
    /// @return relayersPerWindow The number of relayers that were selected to process transactions in the window
    function _getCalldataParams()
        internal
        pure
        virtual
        returns (RelayerAddress relayerAddress, uint256 relayerGenerationIterationBitmap, uint256 relayersPerWindow)
    {
        /*
         * Calldata Map
         * |-------?? bytes--------|------32 bytes-------|---------32 bytes -------------|---------20 bytes -------|
         * |---Original Calldata---|------RGI Bitmap-----|------Relayers Per Window------|-----Relayer Address-----|
         */
        assembly {
            relayerAddress := shr(96, calldataload(sub(calldatasize(), 20)))
            relayersPerWindow := calldataload(sub(calldatasize(), 52))
            relayerGenerationIterationBitmap := calldataload(sub(calldatasize(), 84))
        }
    }

    /// @dev Distributes the transactions evenly b/w 'relayersPerWindow' selected relayers.
    /// @param _txHash Transaction hash of the transaction
    /// @param _relayersPerWindow The number of relayers that were selected to process transactions in the window
    /// @return The index of the relayer that should process the transaction
    function _getAllotedRelayerIndex(bytes32 _txHash, uint256 _relayersPerWindow) private pure returns (uint256) {
        return uint256(_txHash) % _relayersPerWindow;
    }

    /// @dev Verifies that the transaction was allocated to the relayer.
    /// @param _txHash Transaction hash of the transaction
    /// @param _relayerGenerationIterationBitmap see _getCalldataParams
    /// @param _relayersPerWindow see _getCalldataParams
    /// @return True if the transaction was allocated to the relayer, false otherwise
    function _verifyTransactionAllocation(
        bytes32 _txHash,
        uint256 _relayerGenerationIterationBitmap,
        uint256 _relayersPerWindow
    ) private pure returns (bool) {
        uint256 relayerIndex = _getAllotedRelayerIndex(_txHash, _relayersPerWindow);
        return (_relayerGenerationIterationBitmap >> relayerIndex) & 1 == 1;
    }

    /// @dev Given a list of transaction requests and a relayer address, returns the list of transactions that should be
    ///      processed by the relayer in the current window.
    ///      The function is expected to be called off-chain, and as such is not gas optimal
    /// @param _relayerAddress The address of the relayer
    /// @param _requests The list of transaction requests encoded as bytes each
    /// @param _currentState The active relayer state of the TA contract
    /// @return txnAllocated The list of transactions that should be processed by the relayer in the current window
    /// @return relayerGenerationIterations see _getCalldataParams
    /// @return selectedRelayerCdfIndex The index of the relayer in activeState.relayers
    function _allocateTransaction(
        RelayerAddress _relayerAddress,
        bytes[] calldata _requests,
        RelayerStateManager.RelayerState calldata _currentState
    )
        internal
        view
        returns (bytes[] memory txnAllocated, uint256 relayerGenerationIterations, uint256 selectedRelayerCdfIndex)
    {
        (RelayerAddress[] memory relayersAllocated, uint256[] memory relayerStakePrefixSumIndex) =
            ITATransactionAllocation(address(this)).allocateRelayers(_currentState);

        // Filter the transactions
        uint256 length = _requests.length;
        txnAllocated = new bytes[](length);
        uint256 j;
        for (uint256 i; i != length;) {
            bytes32 txHash = _getTransactionHash(_requests[i]);
            uint256 relayerIndex = _getAllotedRelayerIndex(txHash, relayersAllocated.length);

            // If the transaction can be processed by this relayer, store it's info
            if (relayersAllocated[relayerIndex] == _relayerAddress) {
                relayerGenerationIterations |= (1 << relayerIndex);
                txnAllocated[j] = _requests[i];
                selectedRelayerCdfIndex = relayerStakePrefixSumIndex[relayerIndex];
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        // Reduce the array size if needed
        uint256 extraLength = _requests.length - j;
        assembly {
            mstore(txnAllocated, sub(mload(txnAllocated), extraLength))
        }
    }

    /// @dev Application specific logic to get the transaction hash from the calldata.
    /// @param _calldata Calldata of the transaction
    /// @return Transaction hash
    function _getTransactionHash(bytes calldata _calldata) internal pure virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {
    Gas,
    TargetNative,
    LocalNative,
    GasPrice,
    WeiPrice,
    Wei
} from "wormhole-contracts/interfaces/relayer/TypedUnits.sol";
import {IWormholeRelayer, VaaKey} from "wormhole-contracts/interfaces/relayer/IWormholeRelayerTyped.sol";

import {RelayerAddress} from "ta-common/TATypes.sol";

/// @dev The structure defining the payload used to prove "the execution of a delivery request on the destination chain" on the source chain.
/// @custom:member relayerAddress The address of the relayer that executed the delivery request.
/// @custom:member deliveryVAAKey The VAA key of the delivery VAA that was executed.
struct ReceiptVAAPayload {
    RelayerAddress relayerAddress;
    VaaKey deliveryVAAKey;
}

type WormholeChainId is uint16;

function wormholeChainIdEquality(WormholeChainId a, WormholeChainId b) pure returns (bool) {
    return WormholeChainId.unwrap(a) == WormholeChainId.unwrap(b);
}

function wormholeChainIdInequality(WormholeChainId a, WormholeChainId b) pure returns (bool) {
    return WormholeChainId.unwrap(a) != WormholeChainId.unwrap(b);
}

using {wormholeChainIdInequality as !=, wormholeChainIdEquality as ==} for WormholeChainId global;

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//////////////////////////// UDVTS ////////////////////////////

type RelayerAddress is address;

function relayerEquality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) == RelayerAddress.unwrap(b);
}

function relayerInequality(RelayerAddress a, RelayerAddress b) pure returns (bool) {
    return RelayerAddress.unwrap(a) != RelayerAddress.unwrap(b);
}

using {relayerEquality as ==, relayerInequality as !=} for RelayerAddress global;

type DelegatorAddress is address;

function delegatorEquality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) == DelegatorAddress.unwrap(b);
}

function delegatorInequality(DelegatorAddress a, DelegatorAddress b) pure returns (bool) {
    return DelegatorAddress.unwrap(a) != DelegatorAddress.unwrap(b);
}

using {delegatorEquality as ==, delegatorInequality as !=} for DelegatorAddress global;

type RelayerAccountAddress is address;

function relayerAccountEquality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) == RelayerAccountAddress.unwrap(b);
}

function relayerAccountInequality(RelayerAccountAddress a, RelayerAccountAddress b) pure returns (bool) {
    return RelayerAccountAddress.unwrap(a) != RelayerAccountAddress.unwrap(b);
}

using {relayerAccountEquality as ==, relayerAccountInequality as !=} for RelayerAccountAddress global;

type TokenAddress is address;

function tokenEquality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) == TokenAddress.unwrap(b);
}

function tokenInequality(TokenAddress a, TokenAddress b) pure returns (bool) {
    return TokenAddress.unwrap(a) != TokenAddress.unwrap(b);
}

using {tokenEquality as ==, tokenInequality as !=} for TokenAddress global;

//////////////////////////// Enums ////////////////////////////

/// @dev Enum for the status of a relayer.
enum RelayerStatus {
    Uninitialized, // The relayer has not registered in the system, or has successfully unregistered and exited.
    Active, // The relayer is active in the system.
    Exiting, // The relayer has called unregister(), and is waiting for the exit period to end to claim it's stake.
    Jailed // The relayer has been jailed by the system and must wait for the jail time to expire before manually re-entering or exiting.
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "./TATypes.sol";
import {RAArrayHelper} from "src/library/arrays/RAArrayHelper.sol";
import {U256ArrayHelper} from "src/library/arrays/U256ArrayHelper.sol";

/// @title RelayerStateManager
/// @dev Library for managing the state of the relayers.
library RelayerStateManager {
    using RAArrayHelper for RelayerAddress[];
    using U256ArrayHelper for uint256[];

    /// @dev Struct for storing the state of all relayers in the system.
    /// @custom:member cdf The cumulative distribution function of the relayers.
    /// @custom:member relayers The list of relayers.
    struct RelayerState {
        uint256[] cdf;
        RelayerAddress[] relayers;
    }

    /// @dev Appends a new relayer with the given stake to the state.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerAddress The address of the relayer.
    /// @param _stake The stake of the relayer.
    /// @return newState The new state of the relayers.
    function addNewRelayer(RelayerState calldata _prev, RelayerAddress _relayerAddress, uint256 _stake)
        internal
        pure
        returns (RelayerState memory newState)
    {
        newState = RelayerState({
            cdf: _prev.cdf.cd_append(_stake + _prev.cdf[_prev.cdf.length - 1]),
            relayers: _prev.relayers.cd_append(_relayerAddress)
        });
    }

    /// @dev Removes a relayer from the state at the given index
    /// @param _prev The previous state of the relayers.
    /// @param _index The index of the relayer to remove.
    /// @return newState The new state of the relayers.
    function removeRelayer(RelayerState calldata _prev, uint256 _index)
        internal
        pure
        returns (RelayerState memory newState)
    {
        uint256 length = _prev.cdf.length;
        uint256 weightRemoved = _prev.cdf[_index] - (_index == 0 ? 0 : _prev.cdf[_index - 1]);
        uint256 lastWeight = _prev.cdf[length - 1] - (length == 1 ? 0 : _prev.cdf[length - 2]);

        // Copy all the elements except the last one
        uint256[] memory newCdf = new uint256[](length - 1);
        --length;
        for (uint256 i; i != length;) {
            newCdf[i] = _prev.cdf[i];

            unchecked {
                ++i;
            }
        }

        // Update the CDF starting from the index
        if (_index < length) {
            bool elementAtIndexIsIncreased = lastWeight >= weightRemoved;
            uint256 deltaAtIndex = elementAtIndexIsIncreased ? lastWeight - weightRemoved : weightRemoved - lastWeight;

            for (uint256 i = _index; i != length;) {
                if (elementAtIndexIsIncreased) {
                    newCdf[i] += deltaAtIndex;
                } else {
                    newCdf[i] -= deltaAtIndex;
                }

                unchecked {
                    ++i;
                }
            }
        }

        newState = RelayerState({cdf: newCdf, relayers: _prev.relayers.cd_remove(_index)});
    }

    /// @dev Increases the weight of a relayer in the CDF.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerIndex The index of the relayer to update.
    /// @param _value The value to increase the relayer weight by.
    /// @return newCdf The new CDF of the relayers.
    function increaseWeight(RelayerState calldata _prev, uint256 _relayerIndex, uint256 _value)
        internal
        pure
        returns (uint256[] memory newCdf)
    {
        newCdf = _prev.cdf;
        uint256 length = newCdf.length;
        for (uint256 i = _relayerIndex; i != length;) {
            newCdf[i] += _value;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Decreases the weight of a relayer in the CDF.
    /// @param _prev The previous state of the relayers.
    /// @param _relayerIndex The index of the relayer to update.
    /// @param _value The value to decrease the relayer weight by.
    /// @return newCdf The new CDF of the relayers.
    function decreaseWeight(RelayerState calldata _prev, uint256 _relayerIndex, uint256 _value)
        internal
        pure
        returns (uint256[] memory newCdf)
    {
        newCdf = _prev.cdf;
        uint256 length = newCdf.length;
        for (uint256 i = _relayerIndex; i != length;) {
            newCdf[i] -= _value;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given a CDF, calculates an array of individual weights.
    /// @param _cdf The CDF to convert.
    /// @return weights The array of weights.
    function cdfToWeights(uint256[] calldata _cdf) internal pure returns (uint256[] memory weights) {
        uint256 length = _cdf.length;
        weights = new uint256[](length);
        weights[0] = _cdf[0];
        for (uint256 i = 1; i != length;) {
            weights[i] = _cdf[i] - _cdf[i - 1];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Given an array of weights, calculates the CDF.
    /// @param _weights The array of weights to convert.
    /// @return cdf The CDF.
    function weightsToCdf(uint256[] memory _weights) internal pure returns (uint256[] memory cdf) {
        uint256 length = _weights.length;
        cdf = new uint256[](length);
        uint256 sum;
        for (uint256 i; i != length;) {
            sum += _weights[i];
            cdf[i] = sum;
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Hash function used to generate the hash of the relayer state.
    /// @param _cdfHash The hash of the CDF array
    /// @param _relayerArrayHash The hash of the relayer array
    /// @return The hash of the relayer state
    function hash(bytes32 _cdfHash, bytes32 _relayerArrayHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_cdfHash, _relayerArrayHash));
    }

    /// @dev Hash function used to generate the hash of the relayer state.
    /// @param _state The relayer state
    /// @return The hash of the relayer state
    function hash(RelayerState memory _state) internal pure returns (bytes32) {
        return hash(_state.cdf.m_hash(), _state.relayers.m_hash());
    }

    /// @dev Hash function used to generate the hash of the relayer state. This variant is useful when the
    ///      original list of relayers has not changed
    /// @param _cdf The CDF array
    /// @param _relayers The relayer array
    /// @return The hash of the relayer state
    function hash(uint256[] memory _cdf, RelayerAddress[] calldata _relayers) internal pure returns (bytes32) {
        return hash(_cdf.m_hash(), _relayers.cd_hash());
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

type WeiPrice is uint256;

type GasPrice is uint256;

type Gas is uint256;

type Dollar is uint256;

type Wei is uint256;

type LocalNative is uint256;

type TargetNative is uint256;

using {
    addWei as +,
    subWei as -,
    lteWei as <=,
    ltWei as <,
    gtWei as >,
    eqWei as ==,
    neqWei as !=
} for Wei global;
using {addTargetNative as +, subTargetNative as -} for TargetNative global;
using {
    leLocalNative as <,
    leqLocalNative as <=,
    neqLocalNative as !=,
    addLocalNative as +,
    subLocalNative as -
} for LocalNative global;
using {
    ltGas as <,
    lteGas as <=,
    subGas as -
} for Gas global;

using WeiLib for Wei;
using GasLib for Gas;
using DollarLib for Dollar;
using WeiPriceLib for WeiPrice;
using GasPriceLib for GasPrice;

function ltWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) < Wei.unwrap(b);
}

function eqWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) == Wei.unwrap(b);
}

function gtWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) > Wei.unwrap(b);
}

function lteWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) <= Wei.unwrap(b);
}

function subWei(Wei a, Wei b) pure returns (Wei) {
    return Wei.wrap(Wei.unwrap(a) - Wei.unwrap(b));
}

function addWei(Wei a, Wei b) pure returns (Wei) {
    return Wei.wrap(Wei.unwrap(a) + Wei.unwrap(b));
}

function neqWei(Wei a, Wei b) pure returns (bool) {
    return Wei.unwrap(a) != Wei.unwrap(b);
}

function ltGas(Gas a, Gas b) pure returns (bool) {
    return Gas.unwrap(a) < Gas.unwrap(b);
}

function lteGas(Gas a, Gas b) pure returns (bool) {
    return Gas.unwrap(a) <= Gas.unwrap(b);
}

function subGas(Gas a, Gas b) pure returns (Gas) {
    return Gas.wrap(Gas.unwrap(a) - Gas.unwrap(b));
}

function addTargetNative(TargetNative a, TargetNative b) pure returns (TargetNative) {
    return TargetNative.wrap(TargetNative.unwrap(a) + TargetNative.unwrap(b));
}

function subTargetNative(TargetNative a, TargetNative b) pure returns (TargetNative) {
    return TargetNative.wrap(TargetNative.unwrap(a) - TargetNative.unwrap(b));
}

function addLocalNative(LocalNative a, LocalNative b) pure returns (LocalNative) {
    return LocalNative.wrap(LocalNative.unwrap(a) + LocalNative.unwrap(b));
}

function subLocalNative(LocalNative a, LocalNative b) pure returns (LocalNative) {
    return LocalNative.wrap(LocalNative.unwrap(a) - LocalNative.unwrap(b));
}

function neqLocalNative(LocalNative a, LocalNative b) pure returns (bool) {
    return LocalNative.unwrap(a) != LocalNative.unwrap(b);
}

function leLocalNative(LocalNative a, LocalNative b) pure returns (bool) {
    return LocalNative.unwrap(a) < LocalNative.unwrap(b);
}

function leqLocalNative(LocalNative a, LocalNative b) pure returns (bool) {
    return LocalNative.unwrap(a) <= LocalNative.unwrap(b);
}

library WeiLib {
    using {
        toDollars,
        toGas,
        convertAsset,
        min,
        max,
        scale,
        unwrap,
        asGasPrice,
        asTargetNative,
        asLocalNative
    } for Wei;

    function min(Wei x, Wei maxVal) internal pure returns (Wei) {
        return x > maxVal ? maxVal : x;
    }

    function max(Wei x, Wei maxVal) internal pure returns (Wei) {
        return x < maxVal ? maxVal : x;
    }

    function asTargetNative(Wei w) internal pure returns (TargetNative) {
        return TargetNative.wrap(Wei.unwrap(w));
    }

    function asLocalNative(Wei w) internal pure returns (LocalNative) {
        return LocalNative.wrap(Wei.unwrap(w));
    }

    function toDollars(Wei w, WeiPrice price) internal pure returns (Dollar) {
        return Dollar.wrap(Wei.unwrap(w) * WeiPrice.unwrap(price));
    }

    function toGas(Wei w, GasPrice price) internal pure returns (Gas) {
        return Gas.wrap(Wei.unwrap(w) / GasPrice.unwrap(price));
    }

    function scale(Wei w, Gas num, Gas denom) internal pure returns (Wei) {
        return Wei.wrap(Wei.unwrap(w) * Gas.unwrap(num) / Gas.unwrap(denom));
    }

    function unwrap(Wei w) internal pure returns (uint256) {
        return Wei.unwrap(w);
    }

    function asGasPrice(Wei w) internal pure returns (GasPrice) {
        return GasPrice.wrap(Wei.unwrap(w));
    }

    function convertAsset(
        Wei w,
        WeiPrice fromPrice,
        WeiPrice toPrice,
        uint32 multiplierNum,
        uint32 multiplierDenom,
        bool roundUp
    ) internal pure returns (Wei) {
        // console.log("heyo");
        Dollar numerator = w.toDollars(fromPrice).mul(multiplierNum);
        // console.log("numerator", numerator.unwrap());
        // console.log("multiplierDenom", multiplierDenom);
        // console.log("toPrice", toPrice.unwrap());
        WeiPrice denom = toPrice.mul(multiplierDenom);
        // console.log("denom", denom.unwrap());
        Wei res = numerator.toWei(denom, roundUp);
        // console.log("res", res.unwrap());
        return res;
    }
}

library GasLib {
    using {toWei, unwrap} for Gas;

    function min(Gas x, Gas maxVal) internal pure returns (Gas) {
        return x < maxVal ? x : maxVal;
    }

    function toWei(Gas w, GasPrice price) internal pure returns (Wei) {
        return Wei.wrap(w.unwrap() * price.unwrap());
    }

    function unwrap(Gas w) internal pure returns (uint256) {
        return Gas.unwrap(w);
    }
}

library DollarLib {
    using {toWei, mul, unwrap} for Dollar;

    function mul(Dollar a, uint256 b) internal pure returns (Dollar) {
        return Dollar.wrap(a.unwrap() * b);
    }

    function toWei(Dollar w, WeiPrice price, bool roundUp) internal pure returns (Wei) {
        return Wei.wrap((w.unwrap() + (roundUp ? price.unwrap() - 1 : 0)) / price.unwrap());
    }

    function toGas(Dollar w, GasPrice price, WeiPrice weiPrice) internal pure returns (Gas) {
        return w.toWei(weiPrice, false).toGas(price);
    }

    function unwrap(Dollar w) internal pure returns (uint256) {
        return Dollar.unwrap(w);
    }
}

library WeiPriceLib {
    using {mul, unwrap} for WeiPrice;

    function mul(WeiPrice a, uint256 b) internal pure returns (WeiPrice) {
        return WeiPrice.wrap(a.unwrap() * b);
    }

    function unwrap(WeiPrice w) internal pure returns (uint256) {
        return WeiPrice.unwrap(w);
    }
}

library GasPriceLib {
    using {unwrap, priceAsWei} for GasPrice;

    function priceAsWei(GasPrice w) internal pure returns (Wei) {
        return Wei.wrap(w.unwrap());
    }

    function unwrap(GasPrice w) internal pure returns (uint256) {
        return GasPrice.unwrap(w);
    }
}

library TargetNativeLib {
    using {unwrap, asNative} for TargetNative;

    function unwrap(TargetNative w) internal pure returns (uint256) {
        return TargetNative.unwrap(w);
    }

    function asNative(TargetNative w) internal pure returns (Wei) {
        return Wei.wrap(TargetNative.unwrap(w));
    }
}

library LocalNativeLib {
    using {unwrap, asNative} for LocalNative;

    function unwrap(LocalNative w) internal pure returns (uint256) {
        return LocalNative.unwrap(w);
    }

    function asNative(LocalNative w) internal pure returns (Wei) {
        return Wei.wrap(LocalNative.unwrap(w));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title IWormholeApplicationEventsErrors
interface IWormholeApplicationEventsErrors {
    error VMVersionIncompatible(uint256 expected, uint256 actual);
    error AlreadyInitialized();

    event Initialized(address indexed wormhole, address indexed delivery);
    event WormholeDeliveryExecuted(bytes indexed encodedDeliveryVAA);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IApplicationBase
/// @dev Interface for the ApplicationBase contract, which can be inherted by all applications wishing to use BRN's services.
interface IApplicationBase {
    error ExternalCallsNotAllowed();
    error RelayerNotAssignedToTransaction();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ITATransactionAllocationEventsErrors} from "./ITATransactionAllocationEventsErrors.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";
import {ITATransactionAllocationGetters} from "./ITATransactionAllocationGetters.sol";
import {RelayerAddress} from "ta-common/TATypes.sol";
import {RelayerStateManager} from "ta-common/RelayerStateManager.sol";

/// @title ITATransactionAllocation
interface ITATransactionAllocation is ITATransactionAllocationEventsErrors, ITATransactionAllocationGetters {
    /// @dev Data structure to hold the parameters for the execute function.
    /// @custom:member reqs The array of calldata containing the transactions to be executed.
    /// @custom:member forwardedNativeAmounts The array of native amounts to be forwarded to the call with the corresponding transaction.
    /// @custom:member relayerIndex The index of the relayer in the active state calling the execute function.
    /// @custom:member relayerGenerationIterationBitmap A bitmap with set bit indicating the relayer was selected at that iteration.
    /// @custom:member activeState The active state of the relayers.
    /// @custom:member latestState The latest state of the relayers.
    struct ExecuteParams {
        bytes[] reqs;
        uint256[] forwardedNativeAmounts;
        uint256 relayerIndex;
        uint256 relayerGenerationIterationBitmap;
        RelayerStateManager.RelayerState activeState;
        RelayerStateManager.RelayerState latestState;
    }

    /// @notice This function is called by the relayer to execute the transactions.
    /// @param _data The data structure containing the parameters for the execute function.
    function execute(ExecuteParams calldata _data) external payable;

    /// @notice Returns the list of relayers selected in the current window. Expected to be called off-chain.
    /// @param _activeState The active state of the relayers.
    /// @return selectedRelayers list of relayers selected of length relayersPerWindow, but
    ///                          there can be duplicates
    /// @return indices list of indices of the selected relayers in the active state, used for verification
    function allocateRelayers(RelayerStateManager.RelayerState calldata _activeState)
        external
        view
        returns (RelayerAddress[] memory, uint256[] memory);

    /// @notice Convenience function to calculate the miniumum number of transactions required to pass the liveness check.
    /// @param _relayerStake The stake of the relayer calling the execute function.
    /// @param _totalStake The total stake of all the relayers.
    /// @param _totalTransactions The total number of transactions submitted in the current epoch.
    /// @param _zScore A parameter used to calculate the minimum number of transactions required to pass the liveness check.
    function calculateMinimumTranasctionsForLiveness(
        uint256 _relayerStake,
        uint256 _totalStake,
        uint256 _totalTransactions,
        FixedPointType _zScore
    ) external view returns (FixedPointType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";

/// @title Relayer Address Array Helper
/// @dev Helper functions for arrays of RelayerAddress
library RAArrayHelper {
    error IndexOutOfBoundsRA(uint256 index, uint256 length);

    /// @dev Copies the array into memory and appends the value
    /// @param _array The array to append to
    /// @param _value The value to append
    /// @return The new array
    function cd_append(RelayerAddress[] calldata _array, RelayerAddress _value)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        uint256 length = _array.length;
        RelayerAddress[] memory newArray = new RelayerAddress[](
            length + 1
        );

        for (uint256 i; i != length;) {
            newArray[i] = _array[i];
            unchecked {
                ++i;
            }
        }
        newArray[length] = _value;

        return newArray;
    }

    /// @dev Copies the array into memory and removes the value at the index, substituting the last value
    /// @param _array The array to remove from
    /// @param _index The index to remove
    /// @return The new array
    function cd_remove(RelayerAddress[] calldata _array, uint256 _index)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        uint256 newLength = _array.length - 1;
        if (_index > newLength) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        RelayerAddress[] memory newArray = new RelayerAddress[](newLength);

        for (uint256 i; i != newLength;) {
            if (i != _index) {
                newArray[i] = _array[i];
            } else {
                newArray[i] = _array[newLength];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    /// @dev Copies the array into memory and updates the value at the index
    /// @param _array The array to update
    /// @param _index The index to update
    /// @param _value The value to update
    /// @return The new array
    function cd_update(RelayerAddress[] calldata _array, uint256 _index, RelayerAddress _value)
        internal
        pure
        returns (RelayerAddress[] memory)
    {
        if (_index >= _array.length) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        RelayerAddress[] memory newArray = _array;
        newArray[_index] = _value;
        return newArray;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function cd_hash(RelayerAddress[] calldata _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function m_hash(RelayerAddress[] memory _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Removes the value at the index, substituting the last value.
    /// @param _array The array to remove from
    /// @param _index The index to remove
    function m_remove(RelayerAddress[] memory _array, uint256 _index) internal pure {
        uint256 newLength = _array.length - 1;

        if (_index > newLength) {
            revert IndexOutOfBoundsRA(_index, _array.length);
        }

        if (_index != newLength) {
            _array[_index] = _array[newLength];
        }

        // Reduce the array size
        assembly {
            mstore(_array, sub(mload(_array), 1))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title uint256 Array Helper
/// @dev Helper functions for arrays of uint256
library U256ArrayHelper {
    error IndexOutOfBoundsU256(uint256 index, uint256 length);

    /// @dev Copies the array into memory and appends the value
    /// @param _array The array to append to
    /// @param _value The value to append
    /// @return The new array
    function cd_append(uint256[] calldata _array, uint256 _value) internal pure returns (uint256[] memory) {
        uint256 length = _array.length;
        uint256[] memory newArray = new uint256[](
            length + 1
        );

        for (uint256 i; i != length;) {
            newArray[i] = _array[i];
            unchecked {
                ++i;
            }
        }
        newArray[length] = _value;

        return newArray;
    }

    /// @dev Copies the array into memory and removes the value at the index, substituting the last value
    /// @param _array The array to remove from
    /// @param _index The index to remove
    /// @return The new array
    function cd_remove(uint256[] calldata _array, uint256 _index) internal pure returns (uint256[] memory) {
        uint256 newLength = _array.length - 1;
        if (_index > newLength) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        uint256[] memory newArray = new uint256[](newLength);

        for (uint256 i; i != newLength;) {
            if (i != _index) {
                newArray[i] = _array[i];
            } else {
                newArray[i] = _array[newLength];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    /// @dev Copies the array into memory and updates the value at the index
    /// @param _array The array to update
    /// @param _index The index to update
    /// @param _value The value to update
    /// @return The new array
    function cd_update(uint256[] calldata _array, uint256 _index, uint256 _value)
        internal
        pure
        returns (uint256[] memory)
    {
        if (_index >= _array.length) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        uint256[] memory newArray = _array;
        newArray[_index] = _value;
        return newArray;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function cd_hash(uint256[] calldata _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Returns the index of the first element in _array greater than or equal to _target
    ///      The array must be sorted
    /// @param _array The array to find in
    /// @param _target The target value
    /// @return The index of the first element greater than or equal to _target
    function cd_lowerBound(uint256[] calldata _array, uint256 _target) internal pure returns (uint256) {
        uint256 low;
        uint256 high = _array.length;
        unchecked {
            while (low < high) {
                uint256 mid = (low + high) / 2;
                if (_array[mid] < _target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        return low;
    }

    /// @dev Calculate the hash of the array by packing the values and hashing them through keccak256
    /// @param _array The array to hash
    /// @return The hash of the array
    function m_hash(uint256[] memory _array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked((_array)));
    }

    /// @dev Removes the value at the index, substituting the last value.
    /// @param _array The array to remove from
    /// @param _index The index to remove
    function m_remove(uint256[] memory _array, uint256 _index) internal pure {
        uint256 newLength = _array.length - 1;

        if (_index > newLength) {
            revert IndexOutOfBoundsU256(_index, _array.length);
        }

        if (_index != newLength) {
            _array[_index] = _array[newLength];
        }

        // Reduce the array size
        assembly {
            mstore(_array, sub(mload(_array), 1))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";

/// @title ITATransactionAllocationEventsErrors
interface ITATransactionAllocationEventsErrors {
    error RelayerAddressNotFoundInMemoryState(RelayerAddress relayerAddress);
    error RelayerIndexDoesNotPointToSelectedCdfInterval();
    error RelayerAddressDoesNotMatchSelectedRelayer();
    error InvalidRelayerGenerationIteration();
    error NoRelayersRegistered();
    error TransactionExecutionFailed(uint256 index, bytes returndata);
    error InvalidFeeAttached(uint256 totalExpectedValue, uint256 actualValue);
    error RelayerAlreadySubmittedTransaction(RelayerAddress relayerAddress, uint256 windowId);

    event TransactionStatus(uint256 indexed index, bool indexed success, bytes indexed returndata);
    event RelayerPenalized(
        RelayerAddress indexed relayerAddress, uint256 indexed newStake, uint256 indexed penaltyAmount
    );
    event RelayerJailed(RelayerAddress indexed relayerAddress, uint256 jailedUntilTimestamp);
    event LivenessCheckProcessed(uint256 indexed epochEndTimestamp);
    event NoTransactionsSubmittedInEpoch();
    event EpochEndTimestampUpdated(uint256 indexed epochEndTimestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

using Math for uint256;
using Uint256WrapperHelper for uint256;
using FixedPointTypeHelper for FixedPointType;

uint256 constant PRECISION = 24;
uint256 constant MULTIPLIER = 10 ** PRECISION;

FixedPointType constant FP_ZERO = FixedPointType.wrap(0);
FixedPointType constant FP_ONE = FixedPointType.wrap(MULTIPLIER);

type FixedPointType is uint256;

/// @dev Helpers for converting uint256 to FixedPointType
library Uint256WrapperHelper {
    /// @dev Converts a uint256 to a FixedPointType by multiplying by MULTIPLIER
    /// @param _value The value to convert
    /// @return The converted value
    function fp(uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(_value * MULTIPLIER);
    }
}

/// @dev Helpers for FixedPointType
library FixedPointTypeHelper {
    /// @dev Converts a FixedPointType to a uint256 by dividing by MULTIPLIER
    /// @param _value The value to convert
    /// @return The converted value
    function u256(FixedPointType _value) internal pure returns (uint256) {
        return FixedPointType.unwrap(_value) / MULTIPLIER;
    }

    /// @dev Calculates the square root of a FixedPointType
    /// @param _a The value to calculate the square root of
    /// @return The square root
    function sqrt(FixedPointType _a) internal pure returns (FixedPointType) {
        return FixedPointType.wrap((FixedPointType.unwrap(_a) * MULTIPLIER).sqrt());
    }

    /// @dev Multiplies a FixedPointType by a uint256, does not handle overflows
    /// @param _a Multiplicant
    /// @param _value Multiplier
    /// @return The product in FixedPointType
    function mul(FixedPointType _a, uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(FixedPointType.unwrap(_a) * _value);
    }

    /// @dev Divides a FixedPointType by a uint256
    /// @param _a Dividend
    /// @param _value Divisor
    /// @return The result in FixedPointType
    function div(FixedPointType _a, uint256 _value) internal pure returns (FixedPointType) {
        return FixedPointType.wrap(FixedPointType.unwrap(_a) / _value);
    }
}

// Custom operator implementations for FixedPointType
function fixedPointAdd(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(FixedPointType.unwrap(_a) + FixedPointType.unwrap(_b));
}

function fixedPointSubtract(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(FixedPointType.unwrap(_a) - FixedPointType.unwrap(_b));
}

function fixedPointMultiply(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(Math.mulDiv(FixedPointType.unwrap(_a), FixedPointType.unwrap(_b), MULTIPLIER));
}

function fixedPointDivide(FixedPointType _a, FixedPointType _b) pure returns (FixedPointType) {
    return FixedPointType.wrap(Math.mulDiv(FixedPointType.unwrap(_a), MULTIPLIER, FixedPointType.unwrap(_b)));
}

function fixedPointEquality(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) == FixedPointType.unwrap(_b);
}

function fixedPointInequality(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) != FixedPointType.unwrap(_b);
}

function fixedPointGt(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) > FixedPointType.unwrap(_b);
}

function fixedPointGte(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) >= FixedPointType.unwrap(_b);
}

function fixedPointLt(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) < FixedPointType.unwrap(_b);
}

function fixedPointLte(FixedPointType _a, FixedPointType _b) pure returns (bool) {
    return FixedPointType.unwrap(_a) <= FixedPointType.unwrap(_b);
}

using {
    fixedPointAdd as +,
    fixedPointSubtract as -,
    fixedPointMultiply as *,
    fixedPointDivide as /,
    fixedPointEquality as ==,
    fixedPointInequality as !=,
    fixedPointGt as >,
    fixedPointGte as >=,
    fixedPointLt as <,
    fixedPointLte as <=
} for FixedPointType global;

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {RelayerAddress} from "ta-common/TATypes.sol";
import {FixedPointType} from "src/library/FixedPointArithmetic.sol";

/// @title ITATransactionAllocationGetters
interface ITATransactionAllocationGetters {
    function transactionsSubmittedByRelayer(RelayerAddress _relayerAddress) external view returns (uint256);

    function totalTransactionsSubmitted() external view returns (uint256);

    function epochLengthInSec() external view returns (uint256);

    function epochEndTimestamp() external view returns (uint256);

    function livenessZParameter() external view returns (FixedPointType);

    function stakeThresholdForJailing() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}