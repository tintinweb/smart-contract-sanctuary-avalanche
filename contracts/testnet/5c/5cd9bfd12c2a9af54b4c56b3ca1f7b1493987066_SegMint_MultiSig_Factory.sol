/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface MultiSigStruct {
    // Batch Import Strcut
    struct BatchNFTsStruct {
        uint256[] tokenIds;
        address contractAddress;
    }
}

interface SegMintNFTVault is MultiSigStruct {

    function isLocked(address contractAddress, uint256 tokenId) external view returns (bool);

    function batchLockNFTs(BatchNFTsStruct[] memory lockData) external;

    function batchUnlockNFTs(BatchNFTsStruct[] memory lockData) external;
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    value < 0 ? "-" : "",
                    toString(SignedMath.abs(value))
                )
            );
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

contract MultiSig is MultiSigStruct {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    /////    Multi-Sig Administration    ////

    // minimum signatures required for a proposal
    uint256 private _minSignatures;

    // list of signatories
    address[] private _signatories;


    // Signatory Proposal struct for managing signatories
    enum SignerProposalType {
        ADD_SIGNER,
        REMOVE_SIGNER
    }

    enum SignerGroup {
        ADMIN,
        FEEMANAGEMENT,
        SUPPLYMANAGEMENT
    }

    struct SignerProposal {
        uint256 ID;
        address PROPOSER;
        address MODIFIEDSIGNER;
        SignerProposalType UPDATETYPE; // ADD or REMOVE
        SignerGroup SIGNATORYGROUP; // ADMIN, FEEMANAGEMENT, SUPPLYMANAGEMENT
        uint256 EXPIRATION; // expiration timestamp
        uint256 APPROVEDCOUNT;
        uint256 REVOKEDCOUNT;
        bool ISAPPROVED;
        bool ISREVOKED;
    }

    // Min Signature Proposal to manage minimum signers
    struct MinSignatureProposal {
        uint256 ID;
        address PROPOSER;
        uint256 MINSIGNATURE;
        uint256 APPROVEDCOUNT;
        uint256 REVOKEDCOUNT;
        bool ISAPPROVED;
        bool ISREVOKED;
    }

    // administration proposal counter
    uint256 private _signerProposalCount;
    uint256 private _minSignatureProposalCount;

    // contract version
    uint256 private _contractVersion = 1;

    // list of proposals info: proposal ID => proposal detail
    mapping(uint256 => SignerProposal) private _signerProposals;

    mapping(uint256 => MinSignatureProposal) private _minSignatureProposals;


    // signer proposal ID to address to boolean
    mapping(uint256 => mapping(address => bool))
        private _signerProposalApprovers;

    mapping(uint256 => mapping(address => bool))
        private _signerProposalRevokers;
   
    mapping(uint256 => mapping(address => bool))
        private _minSignatureProposalApprovers;

    mapping(uint256 => mapping(address => bool))
        private _minSignatureProposalRevokers;


    // check if an address is a signer: address => status(true/false)
    mapping(address => bool) private _isSigner;

    ////    Multi-Sig Locking and Unlocking    ////

    // Lock Proposal struct for managing locking and unlocking
    enum LockOrUnlockProposalType {
        LOCK, 
        UNLOCK
    }

    struct LockOrUnlockProposal {
        uint256 ID;
        address PROPOSER;
        address SegMintVault;
        LockOrUnlockProposalType PROPOSALTYPE; // LOCK OR UNLOCK
        uint256 APPROVEDCOUNT;
        uint256 REVOKEDCOUNT;
        bool ISAPPROVED;
        bool ISREVOKED;
    }

    // lock or unlock proposal counter
    uint256 private _lockOrUnlockProposalCount;

    // list of lock proposals info: locked proposal ID => lock proposal detail
    mapping(uint256 => LockOrUnlockProposal) private _lockOrUnlockProposals;

    // list of unlock proposal approvers: unlock proposal ID => address => status(true/false)
    mapping(uint256 => mapping(address => bool))
        private _lockOrUnlockProposalApprovers;

    mapping(uint256 => mapping(address => bool))
        private _lockOrUnlockProposalRevokers;

    // locked assets info by lock ID: lock ID => Batch NFTs Struct
    mapping(uint256 => BatchNFTsStruct[]) private _batchLockInfo;

    // unlocked assets info by unlock ID: unlock ID => Batch NFTs Struct
    mapping(uint256 => BatchNFTsStruct[]) private _batchUnlockInfo;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    constructor(address deployer, uint256 minSignatures_, address[] memory signatories_) {
        // require valid initialization
        require(
            minSignatures_ > 0 && minSignatures_ <= signatories_.length,
            "Multi-Sig: Invalid min signatures!"
        );

        // set min singatures
        _minSignatures = minSignatures_;

        // add signers
        for (uint256 i = 0; i < signatories_.length; i++) {
            address signer = signatories_[i];
            require(
                signer != address(0),
                "Multi-Sig: Invalid signer address!"
            );
            require(
                !_isSigner[signer],
                "Multi-Sig: Duplicate signer address!"
            );
            _signatories.push(signer);
            _isSigner[signer] = true;
            emit SignerAdded(deployer, signer, block.timestamp);
        }
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // Min Signer proposal 
    event MinSignatureProposalCreated(
        uint256 indexed proposalId,
        address indexed signer,
        uint256 minSignatures,
        uint256 indexed timestamp
    );

    // add signer
    event MinSignatureUpdated(
        address indexed Sender,
        uint256 newMinSignatures,
        uint256 OldMinSignatures,
        uint256 indexed timestamp
    );


    // add signer
    event SignerAdded(
        address indexed Sender,
        address indexed signer,
        uint256 indexed timestamp
    );

    // remove signer
    event SignerRemoved(
        address indexed Sender,
        address indexed signer,
        uint256 indexed timestamp
    );

    // create proposal
    event ProposalCreated(
        uint256 indexed id,
        address proposer,
        address indexed signerModified,
        SignerProposalType proposalType,
        SignerGroup signerGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approved proposal
    event MinSignatureProposalApproved(
        uint256 indexed id,
        address signer,
        address indexed approver,
        uint256 indexed timestamp
    );

    // approved proposal
    event MinSignatureProposalDisapproved(
        uint256 indexed id,
        address signer,
        address indexed approver,
        uint256 indexed timestamp
    );

    event ProposalApproved(
        uint256 indexed id,
        address signer,
        address indexed approver,
        uint256 indexed timestamp
    );

    // proposal disapprove
    event ProposalDisapproved(
        uint256 indexed id,
        address signer,
        address indexed approver,
        uint256 indexed timestamp
    );
    
    event ProposalExecuted (
        uint256 indexed id,
        uint256 indexed timestamp
    );

    event ProposalRevoked (
        uint256 indexed id, 
        uint256 indexed timestamp
    );

    // create lock proposal
    event LockProposalCreated(
        address indexed Sender,
        uint256 indexed id,
        BatchNFTsStruct[] data,
        uint256 indexed timestamp
    );

    // create unlock proposal
    event unLockProposalCreated(
        address indexed Sender,
        uint256 indexed id,
        BatchNFTsStruct[] data,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only signatories
    modifier onlySignatories() {
        // require msg.sender be a signer
        require(
            _isSigner[msg.sender],
            "Multi-Sig: Sender is not an authorized signer!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Multi-Sig: Address should not be zero address!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // Create a proposal to change the minimum signer requirement
    function proposeMinSignatureChange(uint256 newMinSignature) public onlySignatories {
        require(newMinSignature > 0, "Multi-Sig: Invalid minimum signature value!");
        require(_minSignatures != newMinSignature, "Multi-Sig: Minimum Signatories already set");
        require(newMinSignature <= _signatories.length, "Min SIgnature Cannot exceed signatories");
        // Create a new proposal ID
        uint256 proposalID = _minSignatureProposalCount + 1;

        // Create the proposal
        _minSignatureProposals[proposalID] = MinSignatureProposal({
            ID: proposalID,
            PROPOSER: msg.sender,
            MINSIGNATURE: newMinSignature,
            APPROVEDCOUNT: 1, 
            REVOKEDCOUNT: 0,
            ISAPPROVED: false,
            ISREVOKED: false
        });

        // Approve the proposal by the sender
        _minSignatureProposalApprovers[proposalID][msg.sender] = true;

        // Increment the proposal count
        _minSignatureProposalCount++;

        // Emit event
        emit MinSignatureProposalCreated(proposalID, msg.sender, newMinSignature, block.timestamp);
    }

    // approve administration proposal
    function approveMinSignatureProposal(uint256 ProposalID_) 
        public 
        onlySignatories
    {
        
        // proposal info
        MinSignatureProposal storage proposal = _minSignatureProposals[
            ProposalID_
        ];

        // require a valid proposal ID
        require(proposal.ID != 0, "Multi-Sig: Invalid proposal ID!");

        // require a valid proposer (if by address(0) then this is not valid)
        require(
            proposal.PROPOSER != address(0),
            "Multi-Sig: Not valid proposal!"
        );

        // require proposal not being approved
        require(!proposal.ISAPPROVED, "Multi-Sig: Proposal already approved!");

        // require sender have not already approved the proposal
        require(
            !_minSignatureProposalApprovers[ProposalID_][msg.sender],
            "Multi-Sig: Proposal already approved by this signer!"
        );


        // update proposal approved by sender status

        if(_minSignatureProposalRevokers[ProposalID_][msg.sender] == true) {
            _minSignatureProposalRevokers[ProposalID_][msg.sender] = false;
            proposal.REVOKEDCOUNT--;
        }

        _minSignatureProposalApprovers[ProposalID_][msg.sender] = true;
        proposal.APPROVEDCOUNT++;
        // emit event
        emit MinSignatureProposalApproved(
            ProposalID_,
            proposal.PROPOSER,
            msg.sender,
            block.timestamp
        );

        // check if enough signatories have approved the proposal
        if(proposal.APPROVEDCOUNT >= _minSignatures) {
            
            // old min signatures
            uint256 oldMinSignature = _minSignatures;
            
            // update min signatures
            _minSignatures = proposal.MINSIGNATURE;

            // emit event
            emit MinSignatureUpdated(
                msg.sender,
                proposal.MINSIGNATURE,
                oldMinSignature,
                block.timestamp
            );
        }
    }

    // dissapprove administration proposal
    function disapproveMinSignatureProposal(uint256 ProposalID_) 
        public 
        onlySignatories
    {
        
        // proposal info
        MinSignatureProposal storage proposal = _minSignatureProposals[
            ProposalID_
        ];

        // require a valid proposal ID
        require(proposal.ID != 0, "Multi-Sig: Invalid proposal ID!");

        // require a valid proposer (if by address(0) then this is not valid)
        require(
            proposal.PROPOSER != address(0),
            "Multi-Sig: Not valid proposal!"
        );

        // require proposal not being approved
        require(!proposal.ISAPPROVED, "Multi-Sig: Proposal already approved!");

        // require sender have not already approved the proposal
        require(
            _minSignatureProposalApprovers[ProposalID_][msg.sender],
            "Multi-Sig: Proposal is not approved by this signer!"
        );

        // update proposal approved by sender status
        if(_minSignatureProposalApprovers[ProposalID_][msg.sender] == true) {
            _minSignatureProposalApprovers[ProposalID_][msg.sender] = false;
            proposal.APPROVEDCOUNT--;
        }

        _minSignatureProposalRevokers[ProposalID_][msg.sender] = true;
        proposal.REVOKEDCOUNT++;
        // emit event
        emit MinSignatureProposalDisapproved(
            ProposalID_,
            proposal.PROPOSER,
            msg.sender,
            block.timestamp
        );
    }

    // add a new signer to signatories
    function addSigner(address newSigner_, SignerGroup _signerGroup, uint256 expiration)
        public
        onlySignatories
        notNullAddress(newSigner_)
    {
        // require account not be a signer
        require(
            !_isSigner[newSigner_],
            "Multi-Sig: Signer address already added!"
        );
        if (_signatories.length >= 2) {
            // create a proposal for new signer
            // increment administration proposal ID
            ++_signerProposalCount;
            // uint256 dministrationProposalID = ++_signerProposalCount;

            // add the proposal
            _signerProposals[_signerProposalCount] = SignerProposal({
                ID: _signerProposalCount,
                PROPOSER: msg.sender,
                MODIFIEDSIGNER: newSigner_,
                UPDATETYPE: SignerProposalType.ADD_SIGNER,
                SIGNATORYGROUP: _signerGroup,
                ISAPPROVED: false,
                EXPIRATION: expiration,
                ISREVOKED: false,
                APPROVEDCOUNT: 1,
                REVOKEDCOUNT: 0
            });

            // approve by sender
            _signerProposalApprovers[_signerProposalCount][msg.sender] = true;

            // emit event
            emit ProposalCreated(
                _signerProposalCount,
                msg.sender,
                newSigner_,
                SignerProposalType.ADD_SIGNER,
                _signerGroup,
                expiration,
                block.timestamp
            );
        } else {
            // add the new signer directly: no need to create proposal
            // add to the signatories
            _signatories.push(newSigner_);

            // update signer status
            _isSigner[newSigner_] = true;

            // emit event
            emit SignerAdded(msg.sender, newSigner_, block.timestamp);
            emit ProposalExecuted(_signerProposalCount, block.timestamp);
        }
    }

    // remove a signer from signatories
    function removeSigner(address signer_, SignerGroup _signerGroup, uint256 expiration)
        public
        onlySignatories
        notNullAddress(signer_)
    {
        // require address be a signer
        require(
            _isSigner[signer_],
            "Multi-Sig: Signer address not found!"
        );
        require(_signatories.length - 1 >= _minSignatures, "Min Signatures should be less than the number of signers");
        
        if (_signatories.length >= 2 && _minSignatures > 1) {
            // create a proposal for removing signer
            // increment administration proposal ID
            ++_signerProposalCount;
            // uint256 dministrationProposalID = ++_signerProposalCount;

            // add proposal
            _signerProposals[_signerProposalCount] = SignerProposal({
                ID: _signerProposalCount,
                PROPOSER: msg.sender,
                MODIFIEDSIGNER: signer_,
                UPDATETYPE: SignerProposalType.REMOVE_SIGNER,
                SIGNATORYGROUP: _signerGroup,
                ISAPPROVED: false,
                EXPIRATION: expiration,
                ISREVOKED: false,
                APPROVEDCOUNT: 1,
                REVOKEDCOUNT: 0
            });

            // approve the proposal by sender
            _signerProposalApprovers[_signerProposalCount][msg.sender] = true;

            // emit event
            emit ProposalCreated(
                _signerProposalCount,
                msg.sender,
                signer_,
                SignerProposalType.REMOVE_SIGNER,
                _signerGroup,
                expiration,
                block.timestamp
            );
        } else {
            // require at least 2 signatories
            require(
                _signatories.length >= 2 && _minSignatures  == 1,
                "Multi-Sig: Minimum signatories requirement not met!"
            );

            // remove signer
            _isSigner[signer_] = false;
            for (uint256 i = 0; i < _signatories.length; i++) {
                if (_signatories[i] == signer_) {
                    _signatories[i] = _signatories[_signatories.length - 1];
                    break;
                }
            }
            _signatories.pop();

            // emit event
            emit SignerRemoved(msg.sender, signer_, block.timestamp);
            emit ProposalExecuted(_signerProposalCount, block.timestamp);
        }
    }

    // approve administration proposal
    function approveAdministrationProposal(uint256 administrationProposalID_) 
        public 
        onlySignatories
    {
        
        // proposal info
        SignerProposal storage proposal = _signerProposals[
            administrationProposalID_
        ];

        // require a valid proposal ID
        require(proposal.ID != 0, "Multi-Sig: Invalid proposal ID!");

        // require a valid proposer (if by address(0) then this is not valid)
        require(
            proposal.PROPOSER != address(0),
            "Multi-Sig: Not valid proposal!"
        );

        // require proposal not being approved
        require(!proposal.ISAPPROVED, "Multi-Sig: Proposal already approved!");

        // require sender have not already approved the proposal
        require(
            !_signerProposalApprovers[administrationProposalID_][msg.sender],
            "Multi-Sig: Proposal already approved by this signer!"
        );

        if(_signerProposalRevokers[administrationProposalID_][msg.sender] == true){
            // update proposal approved by sender status
            _signerProposalRevokers[administrationProposalID_][msg.sender] = false;
            proposal.REVOKEDCOUNT--;
        }   

        // update proposal approved by sender status
        _signerProposalApprovers[administrationProposalID_][msg.sender] = true;
        proposal.APPROVEDCOUNT++;
        // emit event
        emit ProposalApproved(
            administrationProposalID_,
            proposal.PROPOSER,
            msg.sender,
            block.timestamp
        );

        // check if enough signatories have approved the proposal
        if(proposal.APPROVEDCOUNT >= _minSignatures) {
            if(proposal.UPDATETYPE == SignerProposalType.ADD_SIGNER){
                // add the new signer
                _signatories.push(proposal.MODIFIEDSIGNER);
                
                // update role
                _isSigner[proposal.MODIFIEDSIGNER] = true;
                
                // emit event
                emit SignerAdded(
                    msg.sender,
                    proposal.PROPOSER,
                    block.timestamp
                );
            } else {
                // remove signer
                _isSigner[proposal.MODIFIEDSIGNER] = false;
                for (uint256 i = 0; i < _signatories.length; i++) {
                    if (_signatories[i] == proposal.MODIFIEDSIGNER) {
                        _signatories[i] = _signatories[_signatories.length - 1];
                        break;
                    }
                }
                _signatories.pop();

                // emit event
                emit SignerRemoved(msg.sender, proposal.MODIFIEDSIGNER, block.timestamp);                
            }
            emit ProposalExecuted(administrationProposalID_, block.timestamp);
        }

    }

    // reject administration proposal
    function rejectAdministrationProposal(uint256 administrationProposalID_) 
        public 
        onlySignatories
    {
        
        // proposal info
        SignerProposal storage proposal = _signerProposals[
            administrationProposalID_
        ];

        // require a valid proposal ID
        require(proposal.ID != 0, "Multi-Sig: Invalid proposal ID!");

        // require a valid proposer (if by address(0) then this is not valid)
        require(
            proposal.PROPOSER != address(0),
            "Multi-Sig: Not valid proposal!"
        );

        // require proposal not being approved
        require(!proposal.ISAPPROVED, "Multi-Sig: Proposal already approved!");
        require(!proposal.ISREVOKED, "Multi-Sig: Proposal already revoked!");


        // require sender have not already approved the proposal
        require(
            _signerProposalRevokers[administrationProposalID_][msg.sender],
            "Multi-Sig: Proposal is already revoked by this signer!"
        );

        if(_signerProposalApprovers[administrationProposalID_][msg.sender] == true){
            // update proposal approved by sender status
            _signerProposalApprovers[administrationProposalID_][msg.sender] = false;
            proposal.APPROVEDCOUNT--;
        }   

        _signerProposalRevokers[administrationProposalID_][msg.sender] = true;
        proposal.REVOKEDCOUNT++;

        // emit event
        emit ProposalDisapproved(
            administrationProposalID_,
            proposal.PROPOSER,
            msg.sender,
            block.timestamp
        );

        // check if enough signatories have approved the proposal
        if(proposal.REVOKEDCOUNT >= _minSignatures) {
            proposal.ISREVOKED = true;    
            emit ProposalRevoked(administrationProposalID_, block.timestamp);
        }
    }

    // create lock proposal
    function createLockProposal(
        BatchNFTsStruct[] memory lockData_,
        address SegMintVault_
    ) 
        public 
        onlySignatories 
    {
        
        // require data be passed
        require(lockData_.length > 0, "Multi-Sig: No unlock data provided!");

        // increment lock or unlock proposal ID
        ++_lockOrUnlockProposalCount;
        // uint256 proposalId = ++_lockOrUnlockProposalCount;

        // create lock proposal
        _lockOrUnlockProposals[_lockOrUnlockProposalCount] = LockOrUnlockProposal({
            ID: _lockOrUnlockProposalCount,
            PROPOSER: msg.sender,
            SegMintVault: SegMintVault_,
            PROPOSALTYPE: LockOrUnlockProposalType.LOCK,
            APPROVEDCOUNT: 1, 
            REVOKEDCOUNT: 0,
            ISAPPROVED: false, 
            ISREVOKED: false
        });

        // add lock proposal
        for (uint256 i = 0; i < lockData_.length; i++) {
            // lockData info
            BatchNFTsStruct memory data = lockData_[i];

            // require non-zero contract address
            require(
                data.contractAddress != address(0),
                "Multi-Sig: Invalid contract address!"
            );

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
                // require entered tokenID
                require(
                    data.tokenIds.length != 0,
                    "Multi-Sig: Invalid token ID!"
                );
                require(!SegMintNFTVault(SegMintVault_).isLocked(data.contractAddress, data.tokenIds[j]), 
                    string.concat(
                        "Multi-Sig : ",
                        "Token Id",
                        Strings.toString(data.tokenIds[j]),
                        "of Contract Address", 
                        Strings.toHexString(data.contractAddress),
                        " is already locked!"
                    )
                );
                // add proposal
                _batchLockInfo[_lockOrUnlockProposalCount].push(lockData_[i]);
            }
        }

        // approve the lock proposal by sender
        _lockOrUnlockProposalApprovers[_lockOrUnlockProposalCount][msg.sender] = true;
        // emit event
        emit LockProposalCreated(
            msg.sender,
            _lockOrUnlockProposalCount,
            lockData_,
            block.timestamp
        );
    }

    // create unlock proposal
    function createUnlockProposal(
        BatchNFTsStruct[] memory lockData_,
        address SegMintVault_
    ) public onlySignatories {
        // require data be passed
        require(lockData_.length > 0, "Multi-Sig: No unlock data provided!");

        // increment lock or unlock proposal ID
        ++_lockOrUnlockProposalCount;
        // uint256 proposalId = ++_lockOrUnlockProposalCount;

        // create lock proposal
        _lockOrUnlockProposals[_lockOrUnlockProposalCount] = LockOrUnlockProposal({
            ID: _lockOrUnlockProposalCount,
            PROPOSER: msg.sender,
            SegMintVault: SegMintVault_,
            PROPOSALTYPE: LockOrUnlockProposalType.UNLOCK,
            APPROVEDCOUNT: 1,
            REVOKEDCOUNT: 0, 
            ISAPPROVED: false, 
            ISREVOKED: false
        });

        // add unlock proposal
        for (uint256 i = 0; i < lockData_.length; i++) {
            // lockData info
            BatchNFTsStruct memory data = lockData_[i];

            // require non-zero contract address
            require(
                data.contractAddress != address(0),
                "Multi-Sig: Invalid contract address!"
            );

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
                // require entered tokenID
                require(
                    data.tokenIds.length != 0,
                    "Multi-Sig: Invalid token ID!"
                );
                require(SegMintNFTVault(SegMintVault_).isLocked(data.contractAddress, data.tokenIds[j]), 
                    string.concat(
                        "Multi-Sig : ",
                        "Token Id",
                        Strings.toString(data.tokenIds[j]),
                        "of Contract Address", 
                        Strings.toHexString(data.contractAddress),
                        " is not locked!"
                    )
                );
                // add proposal
                _batchLockInfo[_lockOrUnlockProposalCount].push(lockData_[i]);
            }
        }

        // approve the ulock proposal by sender
        _lockOrUnlockProposalApprovers[_lockOrUnlockProposalCount][msg.sender] = true;

        // emit event
        emit unLockProposalCreated(
            msg.sender,
            _lockOrUnlockProposalCount,
            lockData_,
            block.timestamp
        );
    }

    // approve lock proposal
    function approveLockorUnlockProposal(uint256 lockorUnlockProposalID_)
        public
        onlySignatories
    {
        // proposal info
        LockOrUnlockProposal storage proposal = _lockOrUnlockProposals[
            lockorUnlockProposalID_
        ];

        // require valid proposal ID
        require(proposal.ID != 0, "Multi-Sig: Invalid proposal ID!");

        // require proposal not been approved
        require(!proposal.ISAPPROVED, "Multi-Sig: Proposal already approved!");

        // require sender not have approved the proposal
        require(
            !_lockOrUnlockProposalApprovers[lockorUnlockProposalID_][msg.sender],
            "Multi-Sig: Already approved by this signer!"
        );

        // sender approve the proposal
        if(_lockOrUnlockProposalRevokers[lockorUnlockProposalID_][msg.sender] == true){
            _lockOrUnlockProposalRevokers[lockorUnlockProposalID_][msg.sender] = false;
            proposal.REVOKEDCOUNT--;
        }

        _lockOrUnlockProposalApprovers[lockorUnlockProposalID_][msg.sender] = true;
        proposal.APPROVEDCOUNT++;

        if(proposal.APPROVEDCOUNT >= _minSignatures){
            // change the approve status
            proposal.ISAPPROVED = true;
            if (proposal.PROPOSALTYPE == LockOrUnlockProposalType.LOCK) {
                // call SegMint Vault and batch lock NFTs
                SegMintNFTVault(proposal.SegMintVault).batchLockNFTs(
                    _batchLockInfo[lockorUnlockProposalID_]
                );
            } else {
                // call SegMint Vault and batch unlock NFTs
                SegMintNFTVault(proposal.SegMintVault).batchUnlockNFTs(
                    _batchUnlockInfo[lockorUnlockProposalID_]
                );
            }
        }
    }

    ///   GETTER FUNCTIONS   ///

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    // get min signature
    function getMinSignature() public view returns (uint256) {
        return _minSignatures;
    }

    // get signatories
    function getSignatories() public view returns (address[] memory) {
        return _signatories;
    }

    // get administration proposal counts
    function getAdministrationProposalCount() public view returns (uint256) {
        return _signerProposalCount;
    }

    // get min signature proposal counts
    function getMinSignatureProposalCount() public view returns (uint256) {
        return _minSignatureProposalCount;
    }

    // get lock or unlock proposal counts
    function getLockOrUnlockProposalCount() public view returns (uint256) {
        return _lockOrUnlockProposalCount;
    }

    // is signer
    function IsSigner(address account_) public view returns (bool) {
        return _isSigner[account_];
    }

    // get adminisration proposal detail
    function getAdministrationProposalDetail(uint256 administrationProposalID_)
        public
        view
        returns (SignerProposal memory)
    {
        return _signerProposals[administrationProposalID_];
    }


    // get MinSignature proposal detail
    function getMinSignatureProposalDetail(uint256 MinSignatureProposalID_)
        public
        view
        returns (MinSignatureProposal memory)
    {
        return _minSignatureProposals[MinSignatureProposalID_];
    }

    // is Min Signature proposal approver
    function isMinSignatureProposalApprover(
        uint256 MinSignatureProposalID_,
        address account_
    ) public view returns (bool) {
        return
            _minSignatureProposalApprovers[MinSignatureProposalID_][
                account_
            ];
    }

    // is administration proposal approver
    function isAdminstrationProposalApprover(
        uint256 administrationProposalID_,
        address account_
    ) public view returns (bool) {
        return
            _signerProposalApprovers[administrationProposalID_][
                account_
            ];
    }

    // get lock or unlock proposal detail
    function getLockOrUnlockProposalDetail(uint256 lockOrUnlockProposalID_)
        public
        view
        returns (LockOrUnlockProposal memory)
    {
        return _lockOrUnlockProposals[lockOrUnlockProposalID_];
    }

    // is lock or unlock proposal approver
    function isLockOrUnlockProposalApprover(uint256 lockOrUnlockProposalID_, address account_)
        public 
        view 
        returns (bool)
    {
        return _lockOrUnlockProposalApprovers[lockOrUnlockProposalID_][account_];
    }

    // get batch lock info
    function getBatchLockInfo(uint256 lockOrUnlockProposalID_) public view returns (BatchNFTsStruct[] memory) {
        return _batchLockInfo[lockOrUnlockProposalID_];
    } 

    // get batch unlock info
    function getBatchUnlockInfo(uint256 lockOrUnlockProposalID_) public view returns (BatchNFTsStruct[] memory) {
        return _batchUnlockInfo[lockOrUnlockProposalID_];
    } 

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}

// SegMint KYC Interface
interface SegMintKYCInterface {
    // set owner address
    function setOwnerAddress(address owner_) external;

    // set KYC Manager
    function setKYCManager(address KYCManager_) external;

    // update global authorization
    function updateGlobalAuthorization(bool status_) external;

    // add address to the authorized addresses
    function authorizeAddress(address account_, string memory userLocation_) external;

    // remove address fro mthe authorized addresses
    function unAuthorizeAddress(address account_) external;

    // get contract version
    function getContractVersion() external view returns (uint256);

    // get owner address
    function getOwnerAddress() external view returns (address);

    // get KYC Manager
    function getKYCManager() external view returns (address);

    // get global authorization status
    function getGlobalAuthorizationStatus() external view returns (bool);

    // is authorized address?
    function isAuthorizedAddress(address account_) external view returns (bool);

    // get geo location
    function getUserLocation(address account_) external view returns (string memory);

    // get authorized addresses
    function getAuthorizedAddresses() external view returns (address[] memory);
}

/**
 * @title MultiSigFactory
 * @dev A factory contract for deploying MultiSig contracts.
 */
contract SegMint_MultiSig_Factory {
    // Fields

    // SegMint Multi Sig Factory Owner Address
    address private _owner;

    // Mapping to track SegMint MultiSig contracts
    mapping(address => bool) private _isSegMintMultiSig;
    mapping(address => address[]) private _deployedSegMintMultiSigByDeployer;
    address[] private _deployedSegMintMultiSigList;
    address[] private _restrictedDeployedSegMintMultiSigList;

    // KYC contract address and interface
    address private SegMintKYCContractAddress;
    SegMintKYCInterface private SegMintKYCContractInterface;

    ////////////////////
    ////   Events   ////
    ////////////////////

    // Event emitted when the owner address is updated
    event updateOwnerAddressEvent(
        address indexed previousOwner,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // Event emitted when a SegMint MultiSig contract is deployed
    event SegMintMultiSigDeployed(
        address indexed deployer,
        address indexed deployed,
        uint256 indexed timestamp
    );

    // Event emitted when a SegMint MultiSig contract is restricted
    event restrictSegMintMultiSigAddressEvent(
        address indexed ownerAddress,
        address indexed SegMintMultiSigAddress,
        uint256 indexed timestamp
    );

    // Event emitted when a SegMint MultiSig contract is added or unrestricted
    event AddSegMintMultiSigAddressEvent(
        address indexed ownerAddress,
        address indexed SegMintMultiSigAddress,
        uint256 indexed timestamp
    );

    // Modifiers

    /**
     * @dev Modifier to only allow the owner to execute a function.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "MultiSigFactory: Sender is not the owner!");
        _;
    }

    /**
     * @dev Modifier to ensure that an address is not the zero address.
     * @param account The address to check.
     * @param accountName The name of the account.
     */
    modifier notNullAddress(address account, string memory accountName) {
        require(account != address(0), string(abi.encodePacked("MultiSigFactory: ", accountName, " cannot be the zero address!")));
        _;
    }

    /**
     * @dev Modifier to only allow KYC authorized accounts to execute a function.
     */
    modifier onlyKYCAuthorized() {
        require(
            SegMintKYCContractInterface.isAuthorizedAddress(msg.sender),
            "SegMint MultiSig Factory: Sender is not an authorized account!"
        );
        _;
    }

    // Constructor

    /**
     * @dev Constructs the MultiSigFactory contract.
     */
    constructor() {
        _owner = msg.sender;
    }

    // Public functions

    /**
     * @dev Retrieves the owner address.
     * @return The owner address.
     */
    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Updates the owner address.
     * @param newOwnerAddress The new owner address.
     */
    function updateOwnerAddress(address newOwnerAddress) public onlyOwner {
        require(newOwnerAddress != address(0), "MultiSigFactory: New owner address cannot be the zero address!");
        _owner = newOwnerAddress;

        // emit event
        emit updateOwnerAddressEvent(
            msg.sender,
            _owner,
            block.timestamp
        );
    }

    /**
     * @dev Sets the SegMintKYC contract address and interface.
     * @param SegMintKYCContractAddress_ The address of the SegMintKYC contract.
     */
    function setSegMintKYCAddress(address SegMintKYCContractAddress_)
        public
        onlyOwner
        notNullAddress(SegMintKYCContractAddress_, "SegMint KYC Address")
    {
        SegMintKYCContractAddress = SegMintKYCContractAddress_;
        SegMintKYCContractInterface = SegMintKYCInterface(SegMintKYCContractAddress_);
    }

    /**
     * @dev Deploys a MultiSig contract.
     * @param owners The addresses of the owners of the MultiSig contract.
     * @param requiredConfirmations The number of required confirmations for a transaction in the MultiSig contract.
     */
    function deployMultiSig(address[] memory owners, uint256 requiredConfirmations) external onlyKYCAuthorized {
        // Deploy the SegMint MultiSig contract and store its address
        address deployedAddress = address(new MultiSig(msg.sender, requiredConfirmations, owners));

        _deployedSegMintMultiSigByDeployer[msg.sender].push(deployedAddress);
        _deployedSegMintMultiSigList.push(deployedAddress);
        _isSegMintMultiSig[deployedAddress] = true;

        emit SegMintMultiSigDeployed(msg.sender, deployedAddress, block.timestamp);
    }

    /**
     * @dev Restricts a SegMint MultiSig contract address.
     * @param SegMintMultiSigAddress_ The address of the SegMint MultiSig contract to restrict.
     */
    function restrictSegMintMultiSigAddress(address SegMintMultiSigAddress_) public onlyOwner {
        // require address be a SegMint MultiSig
        require(
            isSegmintMultiSig(SegMintMultiSigAddress_),
            "SegMint MultiSig Factory: Address is not a SegMint MultiSig Contract!"
        );

        // update is SegMint MultiSig
        _isSegMintMultiSig[SegMintMultiSigAddress_] = false;

        // remove from SegMint MultiSig list
        _removeAddressFromSegMintMultiSig(SegMintMultiSigAddress_);

        // add to restricted SegMint MultiSig
        _restrictedDeployedSegMintMultiSigList.push(SegMintMultiSigAddress_);

        // emit event
        emit restrictSegMintMultiSigAddressEvent(
            msg.sender,
            SegMintMultiSigAddress_,
            block.timestamp
        );
    }

    /**
     * @dev Adds or unrestricts a SegMint MultiSig contract address.
     * @param SegMintMultiSigAddress_ The address of the SegMint MultiSig contract to add or unrestrict.
     */
    function AddOrUnrestrictSegMintMultiSigAddress(address SegMintMultiSigAddress_) public onlyOwner {
        // require address not be in the SegMint MultiSig list
        require(
            !isSegmintMultiSig(SegMintMultiSigAddress_),
            "SegMint MultiSig Factory: Address is already in SegMint"
        );

        // update is SegMint MultiSig
        _isSegMintMultiSig[SegMintMultiSigAddress_] = true;

        // add contract address to all deployed SegMint MultiSig list
        _deployedSegMintMultiSigList.push(SegMintMultiSigAddress_);

        // emit event
        emit AddSegMintMultiSigAddressEvent(
            msg.sender,
            SegMintMultiSigAddress_,
            block.timestamp
        );
    }

    /**
     * @dev Checks if an address is a SegMint MultiSig contract.
     * @param contractAddress The address to check.
     * @return True if the address is a SegMint MultiSig contract, false otherwise.
     */
    function isSegmintMultiSig(address contractAddress) public view returns (bool) {
        return _isSegMintMultiSig[contractAddress];
    }

    /**
     * @dev Retrieves the addresses of all deployed SegMint MultiSig contracts.
     * @return An array of SegMint MultiSig contract addresses.
     */
    function getDeployedSegMintMultiSigContracts() public view returns (address[] memory) {
        return _deployedSegMintMultiSigList;
    }

    /**
     * @dev Retrieves the addresses of all restricted SegMint MultiSig contracts.
     * @return An array of restricted SegMint MultiSig contract addresses.
     */
    function getRestrictedSegMintMultiSigContracts() public view returns (address[] memory) {
        return _restrictedDeployedSegMintMultiSigList;
    }

    /**
     * @dev Retrieves the addresses of deployed SegMint MultiSig contracts by a specific deployer.
     * @param deployer The address of the deployer.
     * @return An array of SegMint MultiSig contract addresses.
     */
    function getSegMintMultiSigDeployedAddressByDeployer(address deployer) public view returns (address[] memory) {
        return _deployedSegMintMultiSigByDeployer[deployer];
    }

    /**
     * @dev Internal function to remove an address from the SegMint MultiSig list.
     * @param MultiSigAddress_ The address to remove.
     */
    function _removeAddressFromSegMintMultiSig(address MultiSigAddress_) private {
        if (_isSegMintMultiSig[MultiSigAddress_]) {
            for (uint256 i = 0; i < _deployedSegMintMultiSigList.length; i++) {
                if (_deployedSegMintMultiSigList[i] == MultiSigAddress_) {
                    _deployedSegMintMultiSigList[i] = _deployedSegMintMultiSigList[_deployedSegMintMultiSigList.length - 1];
                    _deployedSegMintMultiSigList.pop();
                    // update status
                    _isSegMintMultiSig[MultiSigAddress_] = false;
                    break;
                }
            }
        }
    }
}