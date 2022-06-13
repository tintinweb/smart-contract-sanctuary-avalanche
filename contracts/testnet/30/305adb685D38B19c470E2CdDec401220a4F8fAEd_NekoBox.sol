// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './utils/ECDSA.sol';
import './utils/SafeTransferLib.sol';

interface NekoBox__IGear {
    function mint(
        address to,
        uint256 tokenId,
        uint256 quantity, 
        bytes memory data
    ) external;
}

/**
 * @notice This contract allows the server (contract owner) to fufill orders for NekoBox buyers.
 */
contract NekoBox is Ownable {
    using SafeTransferLib for address;
    using ECDSA for bytes32;

    uint256 public constant RANDOMNESS_CONTRACT_ID = 1;

    /**
     * @dev The purchases for `(buyer, boxType)`.
     * When a purchase is fufilled, it is deleted from this mapping.
     */
    mapping(uint256 => uint256) private _nonces;

    /**
     * @dev Whether the order is pending for `(buyer, boxType, nonce)`.
     */
    mapping(bytes32 => bool) private _pending;

    /**
     * @notice The address of the gear contract.
     */
    address public gearAddress;

    /**
     * @notice The address to send the payments to.
     */
    address public feeAddress;

    /**
     * @notice Emitted when an order is paid for.
     */
    event Purchased(address indexed buyer, uint8 indexed boxType, uint256 indexed nonce);

    /**
     * @notice Emitted when an order is fufilled.
     * Contains the information needed for verification of the random result.
     */
    event Fufilled(
        address indexed buyer,
        uint8 indexed boxType,
        uint256 indexed nonce,
        bytes32 ratesDataHash,
        bytes randomnessSignature,
        uint16 gearTokenId
    );

    /**
     * @dev Returns the key into the `_nonce` mapping for `(buyer, boxType)`.
     */
    function _nonceKey(address buyer, uint8 boxType) private pure returns (uint256) {
        return (uint256(uint160(buyer)) << 8) | uint256(boxType);
    }

    /**
     * @dev Returns the key into the `_pending` mapping for `(buyer, boxType, nonce)`.
     */
    function _pendingKey(
        address buyer,
        uint8 boxType,
        uint256 nonce
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(buyer, boxType, nonce));
    }

    /**
     * @notice Returns the randomness that needs to be signed by the server's private key
     * to create a verifiable `randomnessSignature`.
     *
     * The server can get the `nonce` by calling `currentNonceOf(buyer, boxType)`
     *
     * Then the server will use `<signer>.signMessage(randomnessHash(buyer, boxType, nonce))` to
     * generate the `randomnessSignature`.
     */
    function randomnessHash(
        address buyer,
        uint8 boxType,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(RANDOMNESS_CONTRACT_ID, buyer, boxType, nonce));
    }

    /**
     * @notice Returns current nonce for `(buyer, boxType)`.
     */
    function currentNonceOf(address buyer, uint8 boxType) public view returns (uint256) {
        return _nonces[_nonceKey(buyer, boxType)];
    }

    /**
     * @notice Returns whether the order for `(buyer, boxType, nonce)` is pending.
     */
    function isPending(
        address buyer,
        uint8 boxType,
        uint256 nonce
    ) public view returns (bool) {
        return _pending[_pendingKey(buyer, boxType, nonce)];
    }

    /**
     * @dev Returns whether the `serverSignature` is valid.
     */
    function _isServerSignatureValid(
        uint8 boxType,
        uint256 nonce,
        uint256 price,
        address paymentToken,
        uint256 timestamp,
        bytes calldata serverSignature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encode(msg.sender, boxType, nonce, price, paymentToken, timestamp));
        return hash.toEthSignedMessageHash().recover(serverSignature) == owner();
    }

    /**
     * @dev Returns whether the `timestamp` is still fresh.
     */
    function _isTimestampFresh(uint256 timestamp) private view returns (bool result) {
        unchecked {
            result = block.timestamp >= timestamp && block.timestamp - timestamp < 3600;
        }
    }

    /**
     * @notice To be called by the buyer when purchasing a NekoBox.
     */
    function buy(
        uint8 boxType,
        uint256 price,
        address paymentToken,
        uint256 timestamp,
        bytes calldata serverSignature
    ) external {
        uint256 nonceKey = _nonceKey(msg.sender, boxType);
        uint256 nonce = _nonces[nonceKey];

        // Ensures that the `serverSignature` is not too old.
        require(_isTimestampFresh(timestamp));
        // Ensures that the `serverSignature` is indeed signed by the server,
        // to ensure that the price is correct.
        require(_isServerSignatureValid(boxType, nonce, price, paymentToken, timestamp, serverSignature));

        // Transfers the payment to the `feeAddress`.
        // Will revert if insufficient balance or insufficient balance approved.
        paymentToken.safeTransferFrom(msg.sender, feeAddress, price);

        // Sets the order to pending.
        _pending[_pendingKey(msg.sender, boxType, nonce)] = true;

        // Increment the nonce.
        ++_nonces[nonceKey];

        // Emits the event for the server to listen to.
        emit Purchased(msg.sender, boxType, nonce);
    }

    /**
     * @notice Retuns the reason for failure if the purchase fails.
     */
    function getBuyFailureReason(
        uint8 boxType,
        uint256 price,
        address paymentToken,
        uint256 timestamp,
        bytes calldata serverSignature
    ) external view returns (string memory) {
        uint256 nonceKey = _nonceKey(msg.sender, boxType);
        uint256 nonce = _nonces[nonceKey];

        // Check that the `timestamp` for the `serverSignature` is not too old.
        if (!_isTimestampFresh(timestamp)) {
            return 'NekoBox: timestamp expired.';
        }

        // Check that the `serverSignature` is valid.
        if (!_isServerSignatureValid(boxType, nonce, price, paymentToken, timestamp, serverSignature)) {
            return 'NekoBox: invalid signature.';
        }

        // Check that buyer has enough balance.
        if (IERC20(paymentToken).balanceOf(msg.sender) < price) {
            return 'NekoBox: insufficient payment tokens.';
        }

        // Check that buyer has enough allowance.
        if (IERC20(paymentToken).allowance(msg.sender, address(this)) < price) {
            return 'NekoBox: insufficient payment tokens approved.';
        }

        return 'NekoBox: payment failed.';
    }

    /**
     * @notice To be called by the server when fufilling an order.
     */
    function fufill(
        address buyer,
        uint8 boxType,
        uint256 nonce,
        bytes32 ratesDataHash,
        bytes calldata randomnessSignature,
        uint16 gearTokenId
    ) external onlyOwner {
        // Check order is pending. Then, remove it.
        bytes32 pendingKey = _pendingKey(buyer, boxType, nonce);
        require(_pending[pendingKey], 'NekoBox: order does not exist');
        delete _pending[pendingKey]; // For gas efficiency.

        // Mint the gear. The `mint` function must only allow the MINTER_ROLE.
        NekoBox__IGear(gearAddress).mint(buyer, gearTokenId, 1, '');

        // Last, emit the event.
        emit Fufilled(buyer, boxType, nonce, ratesDataHash, randomnessSignature, gearTokenId);

        // The `buyer` can verify that `randomnessSignature` is indeed fairly generated
        // by the owner of this contract via:
        // `keccak256(abi.encode(RANDOMNESS_CONTRACT_ID, buyer, boxType, nonce))
        //     .toEthSignedMessageHash().recover(signature) == owner()`

        // After ensuring the fairness of `randomnessSignature`, the `buyer` can then
        // verify that `gearTokenId` is indeed fairly generated via:
        // `generateGearTokenId(boxType, randomnessSignature, ratesData, ratesDataHash)`.

        // The `ratesData` is available from the server.
        // The `ratesDataHash` is defined by `keccak256(ratesData)`.
    }

    /**
     * @notice To be called off-chain by the server to generate a `gearTokenId`,
     * or by the buyer to verify the `gearTokenId`.
     */
    function generateGearTokenId(
        uint8 boxType, // Given by the buyer.
        bytes calldata randomnessSignature, // Generated the server.
        bytes calldata ratesData, // Generated by the server.
        bytes32 ratesDataHash // `keccak256(ratesRata)`, for verification.
    ) external pure returns (uint24 gearTokenId) {
        require(keccak256(ratesData) == ratesDataHash, 'NekoBox: invalid rates data.');

        // This is coded for easier translation into other languages.
        // Essentially, this performs a weighted sampling of all the candidates for
        // the `boxType`.
        unchecked {
            // The `ratesData` is packed as such:
            // [
            //   uint8  boxType     (1 chars, offset: 0),
            //   uint24 gearTokenId (3 chars, offset: 1,2,3),
            //   uint32 weight      (4 chars, offset: 4,5,6,7),
            //   ...
            // ]

            uint256 weightsSum;
            uint256 end = ratesData.length;
            for (uint256 offset; offset < end; offset += 8) {
                if (boxType == uint8(ratesData[offset + 0])) {
                    // We reconstruct the `weight` from the unpacked characters.
                    uint256 weight = (uint256(uint8(ratesData[offset + 4])) << 24) |
                        (uint256(uint8(ratesData[offset + 5])) << 16) |
                        (uint256(uint8(ratesData[offset + 6])) << 8) |
                        (uint256(uint8(ratesData[offset + 7])) << 0);
                    // And add the `weight` to the `weightsSum`.
                    weightsSum += weight;
                }
            }
            if (weightsSum == 0) revert('NekoBox: no samples for given `boxType`.');

            // The following does the weighted sampling.
            uint256 randomness = uint256(keccak256(randomnessSignature)) % weightsSum;
            weightsSum = 0;
            for (uint256 offset; offset < end; offset += 8) {
                if (boxType == uint8(ratesData[offset + 0])) {
                    weightsSum +=
                        (uint256(uint8(ratesData[offset + 4])) << 24) |
                        (uint256(uint8(ratesData[offset + 5])) << 16) |
                        (uint256(uint8(ratesData[offset + 6])) << 8) |
                        (uint256(uint8(ratesData[offset + 7])) << 0);

                    if (randomness <= weightsSum) {
                        gearTokenId = uint24(
                            (uint256(uint8(ratesData[offset + 1])) << 16) |
                                (uint256(uint8(ratesData[offset + 2])) << 8) |
                                (uint256(uint8(ratesData[offset + 3])) << 0)
                        );
                        break;
                    }
                }
            }
        }
    }

    /**
     * @dev Allows the contract owner to set the gear's contract address.
     */
    function setGearAddress(address value) public onlyOwner {
        gearAddress = value;
    }

    /**
     * @dev Allows the contract owner to set the receiver's address for the payments.
     */
    function setFeeAddress(address value) public onlyOwner {
        feeAddress = value;
    }
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
pragma solidity >=0.8.0;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
library ECDSA {
    function recover(bytes32 hash, bytes calldata signature) internal view returns (address result) {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            // Directly load `s` from the calldata.
            let s := calldataload(add(signature.offset, 0x20))

            let v := 0

            switch signature.length
            case 64 {
                // Here, `s` is actually `vs` that needs to be recovered into `v` and `s`.
                v := add(shr(255, s), 27)
                // prettier-ignore
                s := and(s, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            }
            case 65 {
                // Directly load `v` from the calldata.
                v := byte(0, calldataload(add(signature.offset, 0x40)))
            }

            // If signature is valid and not malleable.
            if and(
                // `s` in lower half order.
                // prettier-ignore
                lt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a1),
                // `v` is 27 or 28.
                byte(v, 0x0101000000)
            ) {
                mstore(0x00, hash)
                mstore(0x20, v)
                calldatacopy(0x40, signature.offset, 0x20) // Directly copy `r` over.
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes.
            // The next multiple of 32 above 78 + 26 is 128.

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            for {
                let temp := sLength
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                temp := div(temp, 10)
            } {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            // Move the pointer 32 bytes lower to make room for the string.
            // `start` marks the start of the memory which we will compute the keccak256 of.
            let start := sub(ptr, 32)
            // Copy the header over to the memory.
            mstore(start, "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n")
            start := add(start, 6)

            // Compute the keccak256 of the memory.
            result := keccak256(start, sub(end, start))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                mstore(0x00, "\x08\xc3\x79\xa0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 19) // Length of the error string.
                mstore(0x44, "ETH_TRANSFER_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0, 100, 0, 32)
                )
            ) {
                mstore(0x00, "\x08\xc3\x79\xa0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 20) // Length of the error string.
                mstore(0x44, "TRANSFER_FROM_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0, 68, 0, 32)
                )
            ) {
                mstore(0x00, "\x08\xc3\x79\xa0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 15) // Length of the error string.
                mstore(0x44, "TRANSFER_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0, 68, 0, 32)
                )
            ) {
                mstore(0x00, "\x08\xc3\x79\xa0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 14) // Length of the error string.
                mstore(0x44, "APPROVE_FAILED") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
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