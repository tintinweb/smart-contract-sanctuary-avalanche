// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IEthereumLightClient {
    function finalizedExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot);

    function optimisticExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../../interfaces/IEthereumLightClient.sol";

interface IMessageBridge {
    enum MessageStatus {
        Null,
        Success,
        Fail
    }

    event MessageSent(
        bytes32 indexed messageId,
        uint256 indexed nonce,
        uint64 dstChainId,
        address sender,
        address receiver,
        bytes message
    );
    event MessageExecuted(
        bytes32 indexed messageId,
        uint256 indexed nonce,
        uint64 srcChainId,
        address sender,
        address receiver,
        bytes message,
        bool success
    );
    event MessageCallReverted(bytes32 messageId, string reason); // help debug

    function lightClients(uint256 chainId) external view returns (IEthereumLightClient);

    function sendMessage(uint64 dstChainId, address receiver, bytes calldata message) external returns (bytes32);

    function executeMessage(
        uint64 srcChainId,
        uint64 nonce,
        address sender,
        address receiver,
        bytes calldata message,
        bytes[] calldata accountProof,
        bytes[] calldata storageProof
    ) external returns (bool);

    function getExecutionStateRootAndSlot(uint64 chainId) external view returns (bytes32 root, uint64 slot);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMessageReceiverApp {
    /**
     * @notice Called by MessageBridge to execute a message
     * @param _srcChainId The source chain ID where the message is originated from
     * @param _sender The address of the source app contract
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBridge execution function
     */
    function executeMessage(
        uint64 _srcChainId,
        address _sender,
        bytes calldata _message,
        address _executor
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./RLPReader.sol";

library MerkleProofTree {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    function _gnaw(uint256 index, bytes32 key) private pure returns (uint256 gnaw) {
        assembly {
            gnaw := shr(mul(sub(63, index), 4), key)
        }
        return gnaw % 16;
    }

    function _pathLength(bytes memory path) private pure returns (uint256, bool) {
        uint256 gnaw = uint256(uint8(path[0])) / 16;
        return ((path.length - 1) * 2 + (gnaw % 2), gnaw > 1);
    }

    function read(bytes32 key, bytes[] memory proof) internal pure returns (bytes memory result) {
        bytes32 root;
        bytes memory node = proof[0];

        uint256 index = 0;
        uint256 pathLength = 0;

        while (true) {
            RLPReader.RLPItem[] memory items = node.toRlpItem().toList();
            if (items.length == 17) {
                uint256 gnaw = _gnaw(pathLength++, key);
                root = bytes32(items[gnaw].toUint());
            } else {
                require(items.length == 2, "MessageBridge: Iinvalid RLP list length");
                (uint256 nodePathLength, bool isLeaf) = _pathLength(items[0].toBytes());
                pathLength += nodePathLength;
                if (isLeaf) {
                    return items[1].toBytes();
                } else {
                    root = bytes32(items[1].toUint());
                }
            }

            node = proof[++index];
            require(root == keccak256(node), "MessageBridge: node hash mismatched");
        }
    }

    function restoreMerkleRoot(bytes32 leaf, uint256 index, bytes32[] memory proof) internal pure returns (bytes32) {
        bytes32 value = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            if ((index / (2 ** i)) % 2 == 1) {
                value = sha256(bytes.concat(proof[i], value));
            } else {
                value = sha256(bytes.concat(value, proof[i]));
            }
        }
        return value;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

library MsgLib {
    string constant ABORT_PREFIX = "MSG::ABORT:";

    function computeMessageId(
        uint64 _nonce,
        address _sender,
        address _receiver,
        uint64 _srcChainId,
        uint64 _dstChainId,
        bytes calldata _message
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_nonce, _sender, _receiver, _srcChainId, _dstChainId, _message));
    }

    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function checkRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        string memory revertMsg = MsgLib.getRevertMsg(_returnData);
        checkAbortPrefix(revertMsg);
        return revertMsg;
    }

    function checkAbortPrefix(string memory _revertMsg) private pure {
        bytes memory prefixBytes = bytes(ABORT_PREFIX);
        bytes memory msgBytes = bytes(_revertMsg);
        if (msgBytes.length >= prefixBytes.length) {
            for (uint256 i = 0; i < prefixBytes.length; i++) {
                if (msgBytes[i] != prefixBytes[i]) {
                    return; // prefix not match, return
                }
            }
            revert(_revertMsg); // prefix match, revert
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity >=0.5.10 <0.9.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param the RLP item.
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
     * @param the RLP item containing the encoded list.
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(uint256 src, uint256 dest, uint256 len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMessageBridge.sol";
import "./interfaces/IMessageReceiverApp.sol";
import "./libraries/RLPReader.sol";
import "./libraries/MerkleProofTree.sol";
import "./libraries/MsgLib.sol";
import "../interfaces/IEthereumLightClient.sol";
import "../verifiers/interfaces/ISlotValueVerifier.sol";

contract MessageBridge is IMessageBridge, ReentrancyGuard, Ownable {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /* Sender side (source chain) storage */
    mapping(uint64 => bytes32) public sentMessages; // nonce -> messageId
    uint256 constant SENT_MESSAGES_STORAGE_SLOT = 2;
    uint64 public nonce;

    /* Receiver side (dest chain) storage */
    mapping(bytes32 => MessageStatus) public receivedMessages; // messageId -> status
    mapping(uint256 => IEthereumLightClient) public lightClients; // chainId -> light client
    mapping(uint256 => address) public remoteMessageBridges; // chainId -> source chain bridge
    mapping(uint256 => bytes32) public remoteMessageBridgeHashes;
    ISlotValueVerifier public slotValueVerifier;
    // minimum amount of gas needed by this contract before it tries to deliver a message to the target.
    uint256 public preExecuteMessageGasUsage;

    /****************************************
     * Sender side (source chain) functions *
     ****************************************/

    function sendMessage(uint64 _dstChainId, address _receiver, bytes calldata _message) external returns (bytes32) {
        bytes32 messageId = MsgLib.computeMessageId(
            nonce,
            msg.sender,
            _receiver,
            uint64(block.chainid),
            _dstChainId,
            _message
        );
        sentMessages[nonce] = messageId;
        emit MessageSent(messageId, nonce++, _dstChainId, msg.sender, _receiver, _message);
        return messageId;
    }

    /****************************************
     * Receiver side (dest chain) functions *
     ****************************************/

    function executeMessage(
        uint64 _srcChainId,
        uint64 _nonce,
        address _sender,
        address _receiver,
        bytes calldata _message,
        bytes[] calldata _accountProof,
        bytes[] calldata _storageProof
    ) external nonReentrant returns (bool success) {
        (bytes32 messageId, bytes32 slotKey) = _getSlotAndMessageId(_srcChainId, _nonce, _sender, _receiver, _message);
        _verifyAccountAndStorageProof(_srcChainId, messageId, slotKey, _accountProof, _storageProof);
        return _executeMessage(messageId, _srcChainId, _nonce, _sender, _receiver, _message);
    }

    function executeMessageWithZkProof(
        uint64 _srcChainId,
        uint64 _nonce,
        address _sender,
        address _receiver,
        bytes calldata _message,
        bytes calldata _zkProofData,
        bytes calldata _blkVerifyInfo
    ) external nonReentrant returns (bool success) {
        (bytes32 messageId, bytes32 slotKey) = _getSlotAndMessageId(_srcChainId, _nonce, _sender, _receiver, _message);
        _verifyZkSlotValueProof(_srcChainId, messageId, slotKey, _zkProofData, _blkVerifyInfo);
        return _executeMessage(messageId, _srcChainId, _nonce, _sender, _receiver, _message);
    }

    function setLightClient(uint64 _chainId, address _lightClient) external onlyOwner {
        lightClients[_chainId] = IEthereumLightClient(_lightClient);
    }

    function setSlotValueVerifier(address _slotValueVerifier) external onlyOwner {
        slotValueVerifier = ISlotValueVerifier(_slotValueVerifier);
    }

    function setRemoteMessageBridge(uint64 _chainId, address _remoteMessageBridge) external onlyOwner {
        remoteMessageBridges[_chainId] = _remoteMessageBridge;
        remoteMessageBridgeHashes[_chainId] = keccak256(abi.encodePacked(_remoteMessageBridge));
    }

    function setPreExecuteMessageGasUsage(uint256 _usage) public onlyOwner {
        preExecuteMessageGasUsage = _usage;
    }

    function getExecutionStateRootAndSlot(uint64 _chainId) public view returns (bytes32 root, uint64 slot) {
        return lightClients[_chainId].optimisticExecutionStateRootAndSlot();
    }

    function _getSlotAndMessageId(
        uint64 _srcChainId,
        uint64 _nonce,
        address _sender,
        address _receiver,
        bytes calldata _message
    ) private view returns (bytes32 messageId, bytes32 slotKey) {
        messageId = MsgLib.computeMessageId(_nonce, _sender, _receiver, _srcChainId, uint64(block.chainid), _message);
        require(receivedMessages[messageId] == MessageStatus.Null, "MessageBridge: message already executed");
        slotKey = keccak256(abi.encode(keccak256(abi.encode(_nonce, SENT_MESSAGES_STORAGE_SLOT))));
    }

    function _verifyAccountAndStorageProof(
        uint64 _srcChainId,
        bytes32 _messageId,
        bytes32 _slotKey,
        bytes[] calldata _accountProof,
        bytes[] calldata _storageProof
    ) private view {
        require(
            _retrieveStorageRoot(_srcChainId, _accountProof) == keccak256(_storageProof[0]),
            "MessageBridge: invalid storage root"
        );
        bytes memory proof = MerkleProofTree.read(_slotKey, _storageProof);
        require(bytes32(proof.toRlpItem().toUint()) == _messageId, "MessageBridge: invalid message hash");
    }

    function _retrieveStorageRoot(uint64 _srcChainId, bytes[] calldata _accountProof) private view returns (bytes32) {
        // verify accountProof and get storageRoot
        (bytes32 executionStateRoot, ) = getExecutionStateRootAndSlot(_srcChainId);
        require(executionStateRoot != bytes32(0), "MessageBridge: execution state root not found");
        require(executionStateRoot == keccak256(_accountProof[0]), "MessageBridge: invalid account proof root");

        // get storageRoot
        bytes memory accountInfo = MerkleProofTree.read(remoteMessageBridgeHashes[_srcChainId], _accountProof);
        RLPReader.RLPItem[] memory items = accountInfo.toRlpItem().toList();
        require(items.length == 4, "MessageBridge: invalid account decoded from RLP");
        return bytes32(items[2].toUint());
    }

    function _verifyZkSlotValueProof(
        uint64 _srcChainId,
        bytes32 _messageId,
        bytes32 _slotKey,
        bytes calldata _zkProofData,
        bytes calldata _blkVerifyInfo
    ) private view {
        ISlotValueVerifier.SlotInfo memory slotInfo = slotValueVerifier.verifySlotValue(
            _srcChainId,
            _zkProofData,
            _blkVerifyInfo
        );
        require(slotInfo.slotKey == _slotKey, "MessageBridge: slot key not match");
        require(slotInfo.slotValue == _messageId, "MessageBridge: slot value not match");
        require(slotInfo.addrHash == remoteMessageBridgeHashes[_srcChainId], "MessageBridge: src contract not match");
    }

    function _executeMessage(
        bytes32 _messageId,
        uint64 _srcChainId,
        uint64 _nonce,
        address _sender,
        address _receiver,
        bytes calldata _message
    ) private returns (bool success) {
        // execute message
        bytes memory recieveCall = abi.encodeWithSelector(
            IMessageReceiverApp.executeMessage.selector,
            _srcChainId,
            _sender,
            _message,
            msg.sender
        );
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = _receiver.call(recieveCall);
        if (ok) {
            success = abi.decode((res), (bool));
        } else {
            _handleExecutionRevert(_messageId, gasLeftBeforeExecution, res);
        }
        receivedMessages[_messageId] = success ? MessageStatus.Success : MessageStatus.Fail;
        emit MessageExecuted(_messageId, _nonce, _srcChainId, _sender, _receiver, _message, success);
        return success;
    }

    function _handleExecutionRevert(
        bytes32 messageId,
        uint256 _gasLeftBeforeExecution,
        bytes memory _returnData
    ) private {
        uint256 gasLeftAfterExecution = gasleft();
        uint256 maxTargetGasLimit = block.gaslimit - preExecuteMessageGasUsage;
        if (_gasLeftBeforeExecution < maxTargetGasLimit && gasLeftAfterExecution <= _gasLeftBeforeExecution / 64) {
            // if this happens, the execution must have not provided sufficient gas limit,
            // then the tx should revert instead of recording a non-retryable failure status
            // https://github.com/wolflo/evm-opcodes/blob/main/gas.md#aa-f-gas-to-send-with-call-operations
            assembly {
                invalid()
            }
        }
        string memory revertMsg = MsgLib.checkRevertMsg(_returnData);
        // otherwiase, emit revert message, return and mark the execution as failed (non-retryable)
        emit MessageCallReverted(messageId, revertMsg);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISlotValueVerifier {
    struct SlotInfo {
        uint64 chainId;
        bytes32 addrHash;
        bytes32 blkHash;
        bytes32 slotKey;
        bytes32 slotValue;
        uint32 blkNum;
    }

    function verifySlotValue(
        uint64 chainId,
        bytes calldata proofData,
        bytes calldata blkVerifyInfo
    ) external view returns (SlotInfo memory slotInfo);
}