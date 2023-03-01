// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern, minimalist, and gas-optimized ERC20 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC20/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// -----------------------------------------------------------------------
    /// Metadata Storage
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /// -----------------------------------------------------------------------
    /// ERC20 Storage
    /// -----------------------------------------------------------------------

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// -----------------------------------------------------------------------
    /// ERC20 Logic
    /// -----------------------------------------------------------------------

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

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
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

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode and decode strings in Base64.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/Base64.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding) internal pure returns (string memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(ptr, end)) { break }
                }

                let r := mod(dataLength, 3)

                switch noPadding
                case 0 {
                    // Offset `ptr` and pad with '='. We can simply write over the end.
                    mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                    mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
                    // Write the length of the string.
                    mstore(result, encodedLength)
                }
                default {
                    // Write the length of the string.
                    mstore(result, sub(encodedLength, add(iszero(iszero(r)), eq(r, 1))))
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe) internal pure returns (string memory result) {
        result = encode(data, fileSafe, false);
    }

    /// @dev Decodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let end := add(data, dataLength)
                let decodedLength := mul(shr(2, dataLength), 3)

                switch and(dataLength, 3)
                case 0 {
                    // If padded.
                    decodedLength := sub(
                        decodedLength,
                        add(eq(and(mload(end), 0xFF), 0x3d), eq(and(mload(end), 0xFFFF), 0x3d3d))
                    )
                }
                default {
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                }

                result := mload(0x40)

                // Write the length of the string.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                // prettier-ignore
                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)
                    
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 32 + 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(add(result, decodedLength), 63), not(31)))

                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/CREATE3.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/CREATE3.sol)
library CREATE3 {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error DeploymentFailed();

    error InitializationFailed();

    /// -----------------------------------------------------------------------
    /// Bytecode Constants
    /// -----------------------------------------------------------------------

    /**
     * -------------------------------------------------------------------+
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 36          | CALLDATASIZE     | cds          |                    |
     * 3d          | RETURNDATASIZE   | 0 cds        |                    |
     * 3d          | RETURNDATASIZE   | 0 0          |                    |
     * 37          | CALLDATACOPY     |              | [0..cds): calldata |
     * 36          | CALLDATASIZE     | cds          | [0..cds): calldata |
     * 3d          | RETURNDATASIZE   | 0 cds        | [0..cds): calldata |
     * 34          | CALLVALUE        | value 0 cds  | [0..cds): calldata |
     * f0          | CREATE           | newContract  | [0..cds): calldata |
     * -------------------------------------------------------------------|
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 67 bytecode | PUSH8 bytecode   | bytecode     |                    |
     * 3d          | RETURNDATASIZE   | 0 bytecode   |                    |
     * 52          | MSTORE           |              | [0..8): bytecode   |
     * 60 0x08     | PUSH1 0x08       | 0x08         | [0..8): bytecode   |
     * 60 0x18     | PUSH1 0x18       | 0x18 0x08    | [0..8): bytecode   |
     * f3          | RETURN           |              | [0..8): bytecode   |
     * -------------------------------------------------------------------+
     */

    uint256 private constant _PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

    bytes32 private constant _PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /// -----------------------------------------------------------------------
    /// Create3 Operations
    /// -----------------------------------------------------------------------

    function deploy(bytes32 salt, bytes memory creationCode, uint256 value) internal returns (address deployed) {
        assembly {
            // Store the `_PROXY_BYTECODE` into scratch space.
            mstore(0x00, _PROXY_BYTECODE)
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            let proxy := create2(0, 0x10, 0x10, salt)

            // If the result of `create2` is the zero address, revert.
            if iszero(proxy) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the proxy's address.
            mstore(0x14, proxy)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)

            // If the `call` fails, revert.
            if iszero(
                call(
                    gas(), // Gas remaining.
                    proxy, // Proxy's address.
                    value, // Ether value.
                    add(creationCode, 0x20), // Start of `creationCode`.
                    mload(creationCode), // Length of `creationCode`.
                    0x00, // Offset of output.
                    0x00 // Length of output.
                )
            ) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If the code size of `deployed` is zero, revert.
            if iszero(extcodesize(deployed)) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    function getDeployed(bytes32 salt) internal view returns (address deployed) {
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, address())
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, _PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x14, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/LibString.sol)
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = uint256(int256(-1));

    /// -----------------------------------------------------------------------
    /// Decimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /// -----------------------------------------------------------------------
    /// Hexadecimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x02 + 0x28) is 0x60.
            str := add(start, 0x60)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /// -----------------------------------------------------------------------
    /// Other String Operations
    /// -----------------------------------------------------------------------

    // For performance and bytecode compactness, all indices of the following operations
    // are byte (ASCII) offsets, not UTF character offsets.

    /// @dev Returns `subject` all occurances of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            result := sub(result, 0x20)
            // Zeroize the slot after the string.
            let last := add(add(result, 0x20), k)
            mstore(last, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
            // Store the length of the result.
            mstore(result, k)
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search, uint256 from) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                if iszero(gt(fromMax, from)) {
                    from := fromMax
                }
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(string memory subject, uint256 start, uint256 end) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(gt(subjectLength, end)) {
                end := subjectLength
            }
            if iszero(gt(subjectLength, start)) {
                start := subjectLength
            }
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), not(31)) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    /// `start` is a byte offset.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Returns all the indices of `search` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(string memory subject, string memory search) internal pure returns (uint256[] memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)

            if iszero(gt(searchLength, subjectLength)) {
                subject := add(subject, 0x20)
                search := add(search, 0x20)
                result := add(mload(0x40), 0x20)

                let subjectStart := subject
                let subjectSearchEnd := add(sub(add(subject, subjectLength), searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Append to `result`.
                        mstore(result, sub(subject, subjectStart))
                        result := add(result, 0x20)
                        // Advance `subject` by `searchLength`.
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                let resultEnd := result
                // Assign `result` to the free memory pointer.
                result := mload(0x40)
                // Store the length of `result`.
                mstore(result, shr(5, sub(resultEnd, add(result, 0x20))))
                // Allocate memory for result.
                // We allocate one more word, so this array can be recycled for {split}.
                mstore(0x40, add(resultEnd, 0x20))
            }
        }
    }

    /// @dev Returns a arrays of strings based on the `delimiter` inside of the `subject` string.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
        uint256[] memory indices = indicesOf(subject, delimiter);
        assembly {
            if mload(indices) {
                let indexPtr := add(indices, 0x20)
                let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
                mstore(sub(indicesEnd, 0x20), mload(subject))
                mstore(indices, add(mload(indices), 1))
                let prevIndex := 0
                // prettier-ignore
                for {} 1 {} {
                    let index := mload(indexPtr)
                    mstore(indexPtr, 0x60)                        
                    if iszero(eq(index, prevIndex)) {
                        let element := mload(0x40)
                        let elementLength := sub(index, prevIndex)
                        mstore(element, elementLength)
                        // Copy the `subject` one word at a time, backwards.
                        // prettier-ignore
                        for { let o := and(add(elementLength, 31), not(31)) } 1 {} {
                            mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                            o := sub(o, 0x20)
                            // prettier-ignore
                            if iszero(o) { break }
                        }
                        // Zeroize the slot after the string.
                        mstore(add(add(element, 0x20), elementLength), 0)
                        // Allocate memory for the length and the bytes,
                        // rounded up to a multiple of 32.
                        mstore(0x40, add(element, and(add(elementLength, 63), not(31))))
                        // Store the `element` into the array.
                        mstore(indexPtr, element)                        
                    }
                    prevIndex := add(index, mload(delimiter))
                    indexPtr := add(indexPtr, 0x20)
                    // prettier-ignore
                    if iszero(lt(indexPtr, indicesEnd)) { break }
                }
                result := indices
                if iszero(mload(delimiter)) {
                    result := add(indices, 0x20)
                    mstore(result, sub(mload(indices), 2))
                }
            }
        }
    }

    /// @dev Returns a concatenated string of `a` and `b`.
    /// Cheaper than `string.concat()` and does not de-align the free memory pointer.
    function concat(string memory a, string memory b) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            let aLength := mload(a)
            // Copy `a` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(mload(a), 32), not(31)) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let bLength := mload(b)
            let output := add(result, mload(a))
            // Copy `b` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(bLength, 32), not(31)) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let totalLength := add(aLength, bLength)
            let last := add(add(result, 0x20), totalLength)
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Stores the length.
            mstore(result, totalLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behaviour is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        assembly {
            // Grab the free memory pointer.
            result := mload(0x40)
            // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(0x40, add(result, 0x40))
            // Zeroize the length slot.
            mstore(result, 0)
            // Store the length and bytes.
            mstore(add(result, 0x1f), packed)
            // Right pad with zeroes.
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        assembly {
            let aLength := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes of `a` and `b`.
                or(shl(shl(3, sub(0x1f, aLength)), mload(add(a, aLength))), mload(sub(add(b, 0x1e), aLength))),
                // `totalLength != 0 && totalLength < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLength, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behaviour is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        assembly {
            // Grab the free memory pointer.
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        assembly {
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(add(a, 0x20), mload(a)), 0)
            // Store the return offset.
            // Assumes that the string does not start from the scratch space.
            mstore(sub(a, 0x20), 0x20)
            // End the transaction, returning the string.
            return(sub(a, 0x20), add(mload(a), 0x40))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// -----------------------------------------------------------------------
    /// ETH Operations
    /// -----------------------------------------------------------------------

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC20 Operations
    /// -----------------------------------------------------------------------

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

address constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
address constant GMX = 0x62edc0692BD897D2295872a9FFCac5425011c661;
address constant EsGMX = 0xFf1489227BbAAC61a9209A08929E4c2a526DdD17;
address constant bonusGMX = 0x8087a341D32D445d9aC8aCc9c14F5781E04A26d2;
address constant bonusGmxTracker = 0x908C4D94D34924765f1eDc22A1DD098397c59dD4;  //Staked + Bonus GMX (sbGMX)
address constant stakedGmxTracker = 0x2bD10f8E93B3669b6d42E74eEedC65dd1B0a1342; //Staked GMX (sGMX)
address constant stakedGlpTracker = 0x9e295B5B976a184B14aD8cd72413aD846C299660; //Fee + Staked GLP (fsGLP)
address constant feeGmxTracker = 0x4d268a7d4C16ceB5a606c173Bd974984343fea13;    //Staked + Bonus + Fee GMX (sbfGMX)
address constant feeGlpTracker = 0xd2D1162512F927a7e282Ef43a362659E4F2a728F;    //Fee GLP (fGLP)
address constant gmxVester = 0x472361d3cA5F49c8E633FB50385BfaD1e018b445;
address constant glpVester = 0x62331A7Bd1dfB3A7642B7db50B5509E57CA3154A;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern, minimalist, and gas-optimized ERC721 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// -----------------------------------------------------------------------
    /// Metadata Storage/Logic
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// -----------------------------------------------------------------------
    /// ERC721 Balance/Owner Storage
    /// -----------------------------------------------------------------------

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = _ownerOf[id]) == address(0)) revert("NotMinted");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert("ZeroAddress");
        return _balanceOf[owner];
    }

    /// -----------------------------------------------------------------------
    /// ERC721 Approval Storage
    /// -----------------------------------------------------------------------

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// -----------------------------------------------------------------------
    /// ERC721 Logic
    /// -----------------------------------------------------------------------

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert("Unauthorized");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public virtual {
        if (from != _ownerOf[id]) revert("WrongFrom");

        if (to == address(0)) revert("InvalidRecipient");

        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[id])
            revert("Unauthorized");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC165 Logic
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert("InvalidRecipient");

        if (_ownerOf[id] != address(0)) revert("AlreadyMinted");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) revert("NotMinted");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /// -----------------------------------------------------------------------
    /// Internal Safe Mint Logic
    /// -----------------------------------------------------------------------

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {RewardRouterV2} from "./interfaces/IRewardRouterV2.sol";
import {ERC721, ERC721TokenReceiver} from "./ERC721.sol";
import {EscrowController} from "./EscrowController.sol";
import {SafeTransferLib} from "@solbase/utils/SafeTransferLib.sol";

contract Escrow is ERC721TokenReceiver
{
    using SafeTransferLib for address;

    uint16 immutable public feeBasisPoints;
    address immutable public seller;
    address immutable public factory;
    address immutable public rewardRouter;
    address immutable public escrowController;
    uint256 immutable public tokenId;

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function escrowOwner() internal view returns (address)
    {
        address nftOwner = ERC721(escrowController).ownerOf(tokenId);
        return nftOwner == address(0) ? factory : (nftOwner == address(this) ? seller : nftOwner);
    }

    modifier onlyEscrowOwner() {
        require(msg.sender == escrowOwner(), "Unauthorized");
        _;
    }

    constructor(uint16 fee, address sellerAddress, address factoryAddress, address router, address controller, uint256 id) {
        require (fee <= 10000, "FEE_TOO_LARGE");
        feeBasisPoints = fee;
        seller = sellerAddress;
        factory = factoryAddress;
        rewardRouter = router;
        escrowController = controller;
        tokenId = id; 
    }

    fallback() external payable { }

    receive() external payable { }

    function acceptTransferIn() external onlyEscrowOwner 
    {
        RewardRouterV2(rewardRouter).acceptTransfer(seller);
        EscrowController(escrowController).safeTransferFrom(address(this), seller, tokenId);
    }

    function signalTransferOut() external onlyEscrowOwner 
    {
        address recipient = escrowOwner();
        EscrowController(escrowController).safeTransferFrom(recipient, address(this), tokenId);
        EscrowController(escrowController).burn(tokenId);
        _claim();
        RewardRouterV2(rewardRouter).signalTransfer(recipient);

    }

    function claim() external onlyEscrowOwner 
    {
        _claim();
    }

    function _claim() internal
    {
        uint256 oldBalance = address(this).balance;
        bytes memory payload = abi.encodeCall(RewardRouterV2(rewardRouter).handleRewards, (false, false, true, true, true, true, true));
        (bool success, ) = address(rewardRouter).call(payload);
        success = success;
        uint256 devFee = (address(this).balance - oldBalance) * feeBasisPoints / 10000;
        factory.safeTransferETH(devFee);
        seller.safeTransferETH(address(this).balance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Owned} from "@solbase/auth/Owned.sol";
import {ERC721} from "./ERC721.sol";
import {Renderer} from "./Renderer.sol";

contract EscrowController is Owned(msg.sender), ERC721 
{
    address renderer;
    address[] public escrows;

    constructor() ERC721("GMX Escrow Ownership", "GEO") {

    }

    function setRenderer(address r) external onlyOwner
    {
        renderer = r;
    }

    function mint(address to, address escrow) external onlyOwner returns (uint256) {
        uint256 id = escrows.length;
        escrows.push(escrow);
        _safeMint(to, id);
        return id;
    }

    function burn(uint256 id) external {
        require(msg.sender == ownerOf(id), "BURN_NOT_ONWER");
        _burn(id);
    }

    function tokenURI(uint256 id) public view override returns (string memory)
    {
        address escrow = escrows[id];
        if (renderer == address(0))
            return "data:,";
        else{
            return Renderer(renderer).tokenURI(id, escrow);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Owned} from "@solbase/auth/Owned.sol";
import {CREATE3} from "@solbase/utils/CREATE3.sol";
import {RewardRouterV2} from "./interfaces/IRewardRouterV2.sol";
import {ERC721TokenReceiver} from "./ERC721.sol";
import {EscrowController} from "./EscrowController.sol";
import {Escrow} from "./Escrow.sol";
import {SafeTransferLib} from "@solbase/utils/SafeTransferLib.sol";

contract EscrowFactory is Owned(tx.origin), ERC721TokenReceiver {
    using SafeTransferLib for address;

    address public rewardRouter;
    address public escrowController;
    uint16 fee = 5000;

    constructor() {
    }

    fallback() external payable { }

    receive() external payable { }

    function setFeeBasisPoints(uint16 newFee) external onlyOwner
    {
        require(newFee <= 10000, "FEE_TOO_LARGE");
        fee = newFee;
    }

    function setRewardRouter(address router) external onlyOwner
    {
        rewardRouter = router;
    }

    function setEscrowController(address controller) external onlyOwner
    {
        escrowController = controller;
    }

    function getSalt(address account) internal pure returns (bytes32)
    {
        return keccak256(abi.encode("gmxotc", account));
    }

    function getEscrow(address account) external view returns (address)
    {
        bytes32 salt = getSalt(account);
        return CREATE3.getDeployed(salt);
    }

    function deployEscrow(address account, uint256 tokenId) internal returns (address)
    {
        bytes32 salt = getSalt(account);
        return CREATE3.deploy(
                salt,
                abi.encodePacked(type(Escrow).creationCode, abi.encode(fee, account, address(this), rewardRouter, escrowController, tokenId)),
                0
            );
    }

    function createEscrow() external returns (address payable) {
        require(rewardRouter != address(0), "REWARD_ROUTER_NOT_SET");
        require(escrowController != address(0), "ESCROW_CONTROLLER_NOT_SET");
        address escrowAddress = this.getEscrow(msg.sender);
        uint256 nftId = EscrowController(escrowController).mint(address(this), escrowAddress);
        address escrow = deployEscrow(msg.sender, nftId);
        EscrowController(escrowController).safeTransferFrom(address(this), escrow, nftId);
        return payable(escrow);
    }

    function withdraw() external onlyOwner
    {
        owner.safeTransferETH(address(this).balance);
    }

    function transferControllerOwnership(address newOwner) external onlyOwner
    {
        EscrowController(escrowController).transferOwnership(newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Base64} from "@solbase/utils/Base64.sol";
import {LibString} from "@solbase/utils/LibString.sol";
import {ERC20} from "@solbase/tokens/ERC20/ERC20.sol";
import {IRewardTracker} from "./interfaces/IRewardTracker.sol";
import {IVester} from "./interfaces/IVester.sol";
import "./AvaxConstants.sol";
//import "./ArbiConstants.sol";

/// @title On-chain renderer
contract Renderer {
    using LibString for uint256;
    using LibString for address;

    struct GMXData {
        uint256 StakedGMXBal;
        uint256 esGMXBal;
        uint256 StakedesGMXBal;
        uint256 esGMXMaxVestGMXBal;
        uint256 esGMXMaxVestGLPBal;
        uint256 GLPBal;
        uint256 MPsBal;
        uint256 PendingWETHBal;
        uint256 PendingesGMXBal;
        uint256 PendingMPsBal;
    }

    function getGMXData(address account) internal view returns (GMXData memory ret) {
       ret.StakedGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(account, GMX);
       ret.esGMXBal = ERC20(EsGMX).balanceOf(account);
       ret.StakedesGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(account, EsGMX);
       ret.esGMXMaxVestGMXBal = IVester(gmxVester).getMaxVestableAmount(account);
       ret.esGMXMaxVestGLPBal = IVester(glpVester).getMaxVestableAmount(account);
       ret.GLPBal = ERC20(stakedGlpTracker).balanceOf(account);
       ret.MPsBal = IRewardTracker(feeGmxTracker).depositBalances(account, bonusGMX);
       ret.PendingWETHBal = IRewardTracker(feeGmxTracker).claimable(account);
       ret.PendingesGMXBal = IRewardTracker(stakedGmxTracker).claimable(account) + IRewardTracker(stakedGlpTracker).claimable(account);
       ret.PendingMPsBal = IRewardTracker(bonusGmxTracker).claimable(account);
       return ret;
    }

    constructor() {}

    function s(uint256 i) internal pure returns (string memory) {
        i /= 10**16;
        uint256 integer = i / 100;        
        uint256 fractional = i % 100;
        string memory amount = string(abi.encodePacked(integer.toString(), ".", fractional.toString()));
        return amount;
    }

    function t(string memory name, uint256 value) internal pure returns (string memory)
    {
        return string(abi.encodePacked('{"display_type": "number", "trait_type": "', name, '", "value": ', s(value),'}'));
    }

    function jsonifyTraits(GMXData memory data) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '"attributes": [', 
                t("Staked esGMX", data.StakedesGMXBal), ',',
                t("MPs", data.MPsBal), ',',
                t("Staked GMX", data.StakedGMXBal), ",",
                t("Unstaked esGMX", data.esGMXBal), ",",
                t("esGMXMaxVestGMXBal", data.esGMXMaxVestGMXBal), ",",
                t("esGMXMaxVestGLPBal", data.esGMXMaxVestGLPBal), ",",
                t("GLPBal", data.GLPBal), ",",
                //t("PendingWETHBal", data.PendingWETHBal), ",",
                //t("PendingesGMXBal", data.PendingesGMXBal), ",",
                t("PendingMPsBal", data.PendingMPsBal),
                ']'
            )
        );
    }

    function tokenURI(
        uint256 tokenId,
        address escrow
    ) external view returns (string memory svgString) {
        GMXData memory data = getGMXData(escrow);
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        "{" '"name": "GMX Escrow Ownership",',
                        '"description": "A fully on-chain NFT for trading GMX accounts (esGMX and MPs)",'
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(getSVG(tokenId, escrow, data))),
                        '",',
                        jsonifyTraits(data),
                        "}"
                    )
                )
            )
        );
    }

    // construct image
    function getSVG(
        uint256 tokenId,
        address escrow,
        GMXData memory /*data*/
    ) internal pure returns (string memory svgString) {
        string memory escrowAddress = string(abi.encodePacked(escrow.toHexString()));

        svgString = string(
            abi.encodePacked(
                "<?xml version='1.0' encoding='UTF-8'?>"
                "<svg xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:svg='http://www.w3.org/2000/svg' xmlns='http://www.w3.org/2000/svg' width='100%' height='100%' viewBox='-100 -150 250 300'>"
                "<style>"
                ".txt { fill: navy; overflow: hidden; font-weight: bold; font-family: Arial, Helvetica, sans-serif; text-shadow: 1px 1px 1px black, 2px 2px 1px grey;}"
                "</style>" "<defs>"
                "<linearGradient id='a' gradientUnits='userSpaceOnUse' x1='-100' x2='-100' y1='-150' y2='100%' gradientTransform='rotate(240)'>"
                "<stop offset='0'  stop-color='#ffffff'/>" "<stop offset='1'  stop-color='hsl(69"
                ", 100%, 63%)'/></linearGradient></defs>"
                "<rect x='-100' y='-150' fill='url(#a)' rx='2%' ry='2%' width='100%' height='100%'/>"
                "<text x='-90' y='-120' class='txt'>",
                escrowAddress,
                "</text><text x='-90' y='130' class='txt'>#",
                tokenId.toString(),
               "</text></svg>"
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface RewardRouterV2 {
    event StakeGlp(address account, uint256 amount);
    event StakeGmx(address account, address token, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);
    event UnstakeGmx(address account, address token, uint256 amount);

    function acceptTransfer(address _sender) external;
    function batchCompoundForAccounts(address[] memory _accounts) external;
    function batchStakeGmxForAccount(address[] memory _accounts, uint256[] memory _amounts) external;
    function bnGmx() external view returns (address);
    function bonusGmxTracker() external view returns (address);
    function claim() external;
    function claimEsGmx() external;
    function claimFees() external;
    function compound() external;
    function compoundForAccount(address _account) external;
    function esGmx() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function glp() external view returns (address);
    function glpManager() external view returns (address);
    function glpVester() external view returns (address);
    function gmx() external view returns (address);
    function gmxVester() external view returns (address);
    function gov() external view returns (address);
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
    function initialize(
        address _weth,
        address _gmx,
        address _esGmx,
        address _bnGmx,
        address _glp,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _feeGlpTracker,
        address _stakedGlpTracker,
        address _glpManager,
        address _gmxVester,
        address _glpVester
    ) external;
    function isInitialized() external view returns (bool);
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
        external
        returns (uint256);
    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function pendingReceivers(address) external view returns (address);
    function setGov(address _gov) external;
    function signalTransfer(address _receiver) external;
    function stakeEsGmx(uint256 _amount) external;
    function stakeGmx(uint256 _amount) external;
    function stakeGmxForAccount(address _account, uint256 _amount) external;
    function stakedGlpTracker() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver)
        external
        returns (uint256);
    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address _receiver)
        external
        returns (uint256);
    function unstakeEsGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _amount) external;
    function weth() external view returns (address);
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface IRewardTracker {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Claim(address receiver, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function BASIS_POINTS_DIVISOR() external view returns (uint256);
    function PRECISION() external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function allowances(address, address) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function averageStakedAmounts(address) external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function balances(address) external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function claimableReward(address) external view returns (uint256);
    function cumulativeRewardPerToken() external view returns (uint256);
    function cumulativeRewards(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function depositBalances(address, address) external view returns (uint256);
    function distributor() external view returns (address);
    function gov() external view returns (address);
    function inPrivateClaimingMode() external view returns (bool);
    function inPrivateStakingMode() external view returns (bool);
    function inPrivateTransferMode() external view returns (bool);
    function initialize(address[] memory _depositTokens, address _distributor) external;
    function isDepositToken(address) external view returns (bool);
    function isHandler(address) external view returns (bool);
    function isInitialized() external view returns (bool);
    function name() external view returns (string memory);
    function previousCumulatedRewardPerToken(address) external view returns (uint256);
    function rewardToken() external view returns (address);
    function setDepositToken(address _depositToken, bool _isDepositToken) external;
    function setGov(address _gov) external;
    function setHandler(address _handler, bool _isActive) external;
    function setInPrivateClaimingMode(bool _inPrivateClaimingMode) external;
    function setInPrivateStakingMode(bool _inPrivateStakingMode) external;
    function setInPrivateTransferMode(bool _inPrivateTransferMode) external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function stakedAmounts(address) external view returns (uint256);
    function symbol() external view returns (string memory);
    function tokensPerInterval() external view returns (uint256);
    function totalDepositSupply(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function updateRewards() external;
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface IVester {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event PairTransfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);

    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
    function balances(address) external view returns (uint256);
    function bonusRewards(address) external view returns (uint256);
    function claim() external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function claimableToken() external view returns (address);
    function claimedAmounts(address) external view returns (uint256);
    function cumulativeClaimAmounts(address) external view returns (uint256);
    function cumulativeRewardDeductions(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function deposit(uint256 _amount) external;
    function depositForAccount(address _account, uint256 _amount) external;
    function esToken() external view returns (address);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getPairAmount(address _account, uint256 _esAmount) external view returns (uint256);
    function getTotalVested(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function gov() external view returns (address);
    function hasMaxVestableAmount() external view returns (bool);
    function hasPairToken() external view returns (bool);
    function hasRewardTracker() external view returns (bool);
    function isHandler(address) external view returns (bool);
    function lastVestingTimes(address) external view returns (uint256);
    function name() external view returns (string memory);
    function pairAmounts(address) external view returns (uint256);
    function pairSupply() external view returns (uint256);
    function pairToken() external view returns (address);
    function rewardTracker() external view returns (address);
    function setBonusRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setGov(address _gov) external;
    function setHandler(address _handler, bool _isActive) external;
    function setHasMaxVestableAmount(bool _hasMaxVestableAmount) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function transferStakeValues(address _sender, address _receiver) external;
    function transferredAverageStakedAmounts(address) external view returns (uint256);
    function transferredCumulativeRewards(address) external view returns (uint256);
    function vestingDuration() external view returns (uint256);
    function withdraw() external;
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}