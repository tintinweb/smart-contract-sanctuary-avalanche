// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './utils/ECDSA.sol';

pragma solidity ^0.8.4;

interface ERC20Claimer__IClaimToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/**
 * @notice A contract that allows an authorized signer to let users claim ERC20 tokens.
 *
 * 1. A user submits a withdraw request `(account, nonce, amount)` to the server.
 *
 * 2. Server checks that:
 *
 *    a) `currentNonceOf(account) == nonce`. If false, terminate.
 *
 *    b) If `nonce != 0` and `(account, nonce - 1)` is NOT in the server's database:
 *         get `lastClaimedAmountOf(account)` from the smart contract,
 *         subtract the value from the `account`'s balance on the server's database,
 *         and store `(account, nonce - 1)` into the server's database.
 *
 *    c) The `account` has enough balance on the server's database.
 *       This MUST be done after step b), which will update the account's balance.
 *
 *    If all checks passes, the server creates a signature from
 *    `(address account, uint256 nonce, uint256 amount)`.
 *
 * 3. The user calls `claim(amount, signature)`.
 *    If the `msg.sender` is not `account`, the transaction will revert.
 *
 * 4. The server will listen to the `Claimed(account, amount, nonce)` event.
 *    Upon receiving it, the server
 *    deducts `amount` from the `account`'s balance on the server's database,
 *    and stores `(account, nonce - 1)` into the server's database.
 *
 *    If the event somehow is missed, step 2.b) will ensure that the data can be
 *    kept in sync.
 */
contract ERC20Claimer is Ownable {
    using ECDSA for bytes32;

    /**
     * @notice Contains information pertaining to the claim state of an account.
     */
    struct ClaimState {
        uint256 lastClaimedAmount;
        uint256 nonce;
    }

    /**
     * @notice The address of the signer.
     */
    address public claimSigner;

    /**
     * @notice The ERC20 token for claiming.
     */
    address public claimToken;

    /**
     * @dev The claim states of the accounts.
     */
    mapping(address => ClaimState) private _states;

    /**
     * @notice Emitted when a claim is done.
     */
    event Claimed(address indexed account, uint256 indexed amount, uint256 indexed nonce);

    /**
     * @notice Sets the address of the token to be claimed.
     * Can only be called by the contract's owner.
     */
    function setClaimToken(address value) external onlyOwner {
        claimToken = value;
    }

    /**
     * @notice Sets the address of the signer of the claims.
     * This is also the public key of the signer.
     * Can only be called by the contract's owner.
     */
    function setClaimSigner(address value) external onlyOwner {
        claimSigner = value;
    }

    /**
     * @notice Returns the current nonce for the `account`.
     */
    function currentNonceOf(address account) external view returns (uint256) {
        return _states[account].nonce;
    }

    /**
     * @notice Returns the last claimed amount for the `account`.
     */
    function lastClaimedAmountOf(address account) external view returns (uint256) {
        return _states[account].lastClaimedAmount;
    }

    /**
     * @notice Returns the claim state for the `account`.
     */
    function claimStateOf(address account) external view returns (ClaimState memory) {
        return _states[account];
    }

    /**
     * @dev Claims `amount` tokens to `msg.sender` authorized by the `signature`.
     */
    function _claim(
        uint256 amount,
        bytes calldata signature,
        bool useMint
    ) private {
        ClaimState storage state = _states[msg.sender];
        // Get the current nonce, and increment the stored value.
        uint256 nonce = state.nonce++;
        // Sets the `lastClaimedAmount` in state.
        state.lastClaimedAmount = amount;

        // Verify that `(msg.sender, amount, nonce)` is approved.
        bytes32 hash = keccak256(abi.encode(msg.sender, amount, nonce));
        hash = hash.toEthSignedMessageHash();
        require(hash.recover(signature) == claimSigner, 'ERC20Claimer: Signature mismatch.');

        if (useMint) {
            // Mints `amount` tokens over to the msg.sender.
            ERC20Claimer__IClaimToken(claimToken).mint(msg.sender, amount);
        } else {
            // Transfer `amount` tokens over to the msg.sender.
            bool success = ERC20Claimer__IClaimToken(claimToken).transfer(msg.sender, amount);
            require(success, 'ERC20Claimer: Transfer failed.');
        }

        // Emits the event so that the server can keep the database in sync promptly.
        emit Claimed(msg.sender, amount, nonce);
    }

    /**
     * @notice Transfers `amount` tokens to `msg.sender` authorized by the `signature`.
     */
    function claimWithTransfer(uint256 amount, bytes calldata signature) external {
        _claim(amount, signature, false);
    }

    /**
     * @notice Mints `amount` tokens to `msg.sender` authorized by the `signature`.
     */
    function claimWithMint(uint256 amount, bytes calldata signature) external {
        _claim(amount, signature, true);
    }
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