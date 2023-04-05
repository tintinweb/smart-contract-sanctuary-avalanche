// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./client/BLS12381.sol";
import "./EthVerifier.sol";

interface ILightClient {
    function getCommitteeRoot(uint64 slot) external view returns (bytes32);
}

contract EthBlockUpdater is EthVerifier, Initializable, OwnableUpgradeable, BLS12381 {
    event ImportBlock(uint256 slot, bytes32 singingRoot, bytes32 receiptHash);

    struct ParsedInput {
        uint64 slot;
        bytes32 syncCommitteeRoot;
        bytes32 receiptHash;
    }

    // signingRoot=>receiptsRoot
    mapping(bytes32 => bytes32) public blockInfos;

    ILightClient public lightClient;

    function initialize(address _lightClient) public initializer {
        lightClient = ILightClient(_lightClient);
        __Ownable_init();
    }

    function importBlock(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[5] calldata inputs,
        bytes32 signingRoot
    ) external {
        uint256[33] memory verifyInputs;
        ParsedInput memory parsedInput = _parseInput(inputs);
        uint256[28] memory fieldElement = hashToField(signingRoot);
        for (uint i = 0; i < 28; i++) {
            verifyInputs[i] = fieldElement[i];
        }
        verifyInputs[28] = inputs[0];
        verifyInputs[29] = inputs[1];
        verifyInputs[30] = inputs[2];
        verifyInputs[31] = inputs[3];
        verifyInputs[32] = inputs[4];

        bytes32 committeeRoot = lightClient.getCommitteeRoot(parsedInput.slot);
        require(committeeRoot == parsedInput.syncCommitteeRoot, "invalid committeeRoot");

        require(verifyProof(a, b, c, verifyInputs), "invalid proof");

        blockInfos[signingRoot] = parsedInput.receiptHash;
        emit ImportBlock(
            parsedInput.slot,
            signingRoot,
            parsedInput.receiptHash
        );
    }

    function checkBlock(bytes32 signingRoot, bytes32 receiptHash) external view returns (bool) {
        bytes32 _receiptsHash = blockInfos[signingRoot];
        if (_receiptsHash != bytes32(0) && _receiptsHash == receiptHash) {
            return true;
        }
        return false;
    }

    function _parseInput(uint256[5] memory inputs) internal pure returns (ParsedInput memory) {
        ParsedInput memory result;
        result.syncCommitteeRoot = bytes32((inputs[1] << 128) | inputs[0]);
        result.slot = uint64(inputs[2]);
        result.receiptHash = bytes32((inputs[4] << 128) | inputs[3]);
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BLS12381 {
    struct Fp {
        uint256 a;
        uint256 b;
    }

    uint8 constant MOD_EXP_PRECOMPILE_ADDRESS = 0x5;


    // Reduce the number encoded as the big-endian slice of data[start:end] modulo the BLS12-381 field modulus.
    // Copying of the base is cribbed from the following:
    // https://github.com/ethereum/solidity-examples/blob/f44fe3b3b4cca94afe9c2a2d5b7840ff0fafb72e/src/unsafe/Memory.sol#L57-L74
    function reduceModulo(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (bytes memory) {
        uint256 length = end - start;
        assert(length <= data.length);

        bytes memory result = new bytes(48);

        bool success;
        assembly {
            let p := mload(0x40)
        // length of base
            mstore(p, length)
        // length of exponent
            mstore(add(p, 0x20), 0x20)
        // length of modulus
            mstore(add(p, 0x40), 48)
        // base
        // first, copy slice by chunks of EVM words
            let ctr := length
            let src := add(add(data, 0x20), start)
            let dst := add(p, 0x60)
            for {

            } or(gt(ctr, 0x20), eq(ctr, 0x20)) {
                ctr := sub(ctr, 0x20)
            } {
                mstore(dst, mload(src))
                dst := add(dst, 0x20)
                src := add(src, 0x20)
            }
        // next, copy remaining bytes in last partial word
            let mask := sub(exp(256, sub(0x20, ctr)), 1)
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dst), mask)
            mstore(dst, or(destpart, srcpart))
        // exponent
            mstore(add(p, add(0x60, length)), 1)
        // modulus
            let modulusAddr := add(p, add(0x60, add(0x10, length)))
            mstore(
            modulusAddr,
            or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7)
            ) // pt 1
            mstore(
            add(p, add(0x90, length)),
            0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
            ) // pt 2
            success := staticcall(
            sub(gas(), 2000),
            MOD_EXP_PRECOMPILE_ADDRESS,
            p,
            add(0xB0, length),
            add(result, 0x20),
            48
            )
        // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'call to modular exponentiation precompile failed');
        return result;
    }

    function sliceToUint(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private pure returns (uint256 result) {
        uint256 length = end - start;
        require(length <= 32, "Invalid slice length");

        assembly {
            let dataPtr := add(add(data, 0x20), start)
            let dataEnd := add(dataPtr, length)

            for {
                let i := dataPtr
            } lt(i, dataEnd) {
                i := add(i, 1)
            } {
                result := shl(8, result)
                result := or(result, byte(0, mload(i)))
            }
        }
    }


    function convertSliceToFp(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (Fp memory) {
        bytes memory fieldElement = reduceModulo(data, start, end);
        uint256 a = sliceToUint(fieldElement, 0, 16);
        uint256 b = sliceToUint(fieldElement, 16, 48);
        return Fp(a, b);
    }

    function expandMessage(bytes32 message) private pure returns (bytes memory) {
        bytes memory b0Input = new bytes(143);
        bytes memory BLS_SIG_DST = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+';
        //0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f535357555f524f5f504f505f2b

        //   for (uint256 i; i < 32; ) {
        //       b0Input[i + 64] = message[i];
        //   unchecked {
        //       ++i;
        //   }
        //   }
        //   b0Input[96] = 0x01;
        //   for (uint256 i; i < 44; ) {
        //       b0Input[i + 99] = bytes(BLS_SIG_DST)[i];
        //   unchecked {
        //       ++i;
        //   }
        //   }
        assembly {
            mstore(add(b0Input, 0x60), message)
            mstore8(add(b0Input, 0x80), 0x01)
        // Load BLS_SIG_DST
            mstore(add(b0Input, 0x83), 0x424c535f5349475f424c53313233383147325f584d443a5348412d3235365f53)
            mstore8(add(b0Input, 0xa3), 0x53)
            mstore8(add(b0Input, 0xa4), 0x57)
            mstore8(add(b0Input, 0xa5), 0x55)
            mstore8(add(b0Input, 0xa6), 0x5f)
            mstore8(add(b0Input, 0xa7), 0x52)
            mstore8(add(b0Input, 0xa8), 0x4f)
            mstore8(add(b0Input, 0xa9), 0x5f)
            mstore8(add(b0Input, 0xaa), 0x50)
            mstore8(add(b0Input, 0xab), 0x4f)
            mstore8(add(b0Input, 0xac), 0x50)
            mstore8(add(b0Input, 0xad), 0x5f)
            mstore8(add(b0Input, 0xae), 0x2b)
        }


        bytes32 b0 = sha256(b0Input);

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(
            abi.encodePacked(b0, bytes1(0x01), bytes(BLS_SIG_DST))
        );
        assembly {
            mstore(add(output, 0x20), chunk)
        }

        for (uint256 i = 2; i < 9;) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(
                abi.encodePacked(input, bytes1(uint8(i)), bytes(BLS_SIG_DST))
            );
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        unchecked {
            ++i;
        }
        }

        return output;
    }

    function FpToArray55_7(Fp memory fp) private pure returns (uint256[7] memory) {
        uint256[7] memory result;
        uint256 mask = ((1 << 55) - 1);
        result[0] = (fp.b & mask);
        result[1] = ((fp.b >> 55) & mask);
        result[2] = ((fp.b >> 110) & mask);
        result[3] = ((fp.b >> 165) & mask);
        result[4] = ((fp.b >> 220) & mask);
        uint256 newMask = (1 << 19) - 1;
        result[4] = result[4] | ((fp.a & newMask) << 36);
        result[5] = (fp.a & (mask << 19)) >> 19;
        result[6] = (fp.a & (mask << (55 + 19))) >> (55 + 19);

        return result;
    }

    function hashToField(bytes32 message)
    internal
    view
    returns (uint256[28] memory input)
    {
        bytes memory some_bytes = expandMessage(message);
        uint256[7][2][2] memory result;
        result[0][0] = FpToArray55_7(convertSliceToFp(some_bytes, 0, 64));
        result[0][1] = FpToArray55_7(convertSliceToFp(some_bytes, 64, 128));
        result[1][0] = FpToArray55_7(convertSliceToFp(some_bytes, 128, 192));
        result[1][1] = FpToArray55_7(convertSliceToFp(some_bytes, 192, 256));
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2; j++) {
                for (uint256 k = 0; k < 7; k++) {
                    input[i * 14 + j * 7 + k] = result[i][j][k];
                }
            }
        }
        return input;
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract EthVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[34] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(2254158071052761736910316097502950094991780620054993239351022377414371599402), uint256(14004147208856646248370189963890936839847438517364725496153239271556989632649));
        vk.beta2 = Pairing.G2Point([uint256(1320919437770655013931879098085065938402477810078669079814997495771040902516), uint256(19806087833652203703216447605519806010900374109422123220501147437704809915941)], [uint256(11874922693740206901244975410488938744103845947381990305089356502783483556307), uint256(7503428108589985550308011100362264031920948089040521308394757068865600084729)]);
        vk.gamma2 = Pairing.G2Point([uint256(16499681784651369984030317301667292606167122014372342387037188379359884089094), uint256(6071631371002374082272610169520023861653646179809405418658431866439776450781)], [uint256(2431186002504802994218529505138649294389683446902506106102012164522002911142), uint256(160164874265222602088833003513669143312501673650876901168245126542627468157)]);
        vk.delta2 = Pairing.G2Point([uint256(7068885507504621260964521891322423142042435982096153601983589496683305512324), uint256(12136019388400060723475420437728398416890599404094921484552603911769398820159)], [uint256(403169760465322643666042316575823760845419519322590541804268347822596919788), uint256(3585368097573864067625720634414517831037639468720508398596674277532398232773)]);
        vk.IC[0] = Pairing.G1Point(uint256(2388153524912525356657897083418877030125160428728066685556394639646311688857), uint256(4572256011040247880146636279254511000751335789050895430513034462930158243374));
        vk.IC[1] = Pairing.G1Point(uint256(13392797143874764650951545948357841380771417723456874635770813803965184468306), uint256(12572149751727516152907789080294861932232691465018213332107039613838341509559));
        vk.IC[2] = Pairing.G1Point(uint256(15751530053180516306059704617714729675543369005734846418094346352954700845890), uint256(18839476012608041232035045453461743280757744041568108863334376830320908330073));
        vk.IC[3] = Pairing.G1Point(uint256(3939448844792982770387998139227627828652323406115820886820989942298564487343), uint256(6348078189017487819859846444768561244172592900589215634318728528284385544904));
        vk.IC[4] = Pairing.G1Point(uint256(10400582653535394881587015919672619024002128600766608641996266230216335950339), uint256(626783285846110621821119690591144458467069321047607004822135656674098519830));
        vk.IC[5] = Pairing.G1Point(uint256(242242192843643923802600670078940949490448115071275092792091624721773529421), uint256(626217643267482855612005581053331939250436572687235854546564175770392502824));
        vk.IC[6] = Pairing.G1Point(uint256(6318771424126559912946069259091521739197877612867154762563324834876020530460), uint256(17524746623141888438720918143663532682536588394527004752425936461004393357710));
        vk.IC[7] = Pairing.G1Point(uint256(1426543336454909431087100771343936637870447292622846315407228662705670702447), uint256(6969045039093149618240675195923900711151069705656240738391470734090894958105));
        vk.IC[8] = Pairing.G1Point(uint256(10889006397017423694143730725159289956239344013795280986433258975957793447176), uint256(11019314529943560185667467840213257450521610521492794767988749213898527397962));
        vk.IC[9] = Pairing.G1Point(uint256(7089632688021214784074746301313598458634646829690685907177284359383184591525), uint256(18949627437778760332093331591412750076904705782377955573673226410514839597163));
        vk.IC[10] = Pairing.G1Point(uint256(2764021073367343819925989336692195590922876759520198707000900128859081335794), uint256(14083741015234672332025049538210067849286693165866181961087117949768094131485));
        vk.IC[11] = Pairing.G1Point(uint256(8911648184560952928719131417068151125602981889616361704454182804653505424727), uint256(16454022078593101534032036927166240160093072486977405774867820536690040014385));
        vk.IC[12] = Pairing.G1Point(uint256(6291026285400496857314874679757539356123689315843545048603416091480620824390), uint256(17621362057160467572683695539473273483802599720933146116377184751406087944544));
        vk.IC[13] = Pairing.G1Point(uint256(15151018247789840826922103704383771709741683672467298651276663058705805219217), uint256(7324758496079327811079926972614651766168890253655416925710695284314461016018));
        vk.IC[14] = Pairing.G1Point(uint256(12763487706484471677757552665021845365526534901668611435553652064726064499145), uint256(10087224857573167632855153775887799513500859951836627477185216671177227022736));
        vk.IC[15] = Pairing.G1Point(uint256(18567006548252342962233670560414437104174141515594423696913893507095166150969), uint256(5247453233796803242822012211808849630510624540345673796168720132226595180850));
        vk.IC[16] = Pairing.G1Point(uint256(21293703080540111998732750331516645435850181541297350925354485517493552168616), uint256(13783891268093170705878748915448268568505076851947170403403270385996438667006));
        vk.IC[17] = Pairing.G1Point(uint256(16335706434397234843567151154427788437906178414891589409453718554221781559480), uint256(5324335722425396065490997266223884327208192263559818748598837726290701279887));
        vk.IC[18] = Pairing.G1Point(uint256(16081878268087022539236839075606273229794264474634748743393684696577489403092), uint256(11152017842730962668310672154893400890963305440204711897176672307824631982971));
        vk.IC[19] = Pairing.G1Point(uint256(8943847656003038437441991028164417588447361405950720760204271418481024684743), uint256(20356049412679574856810477700546090927811447413574293042397165026704999589418));
        vk.IC[20] = Pairing.G1Point(uint256(16008517181203765380638410887901753332329582383359361680680363520994888662773), uint256(11433403950255995834083625412007128392121932661856672622842600996041870272254));
        vk.IC[21] = Pairing.G1Point(uint256(6609575687494299420717424226795616310396584238340059609374767372582388786882), uint256(1022434538364957627351607335850534232631607616914958578221880317956464039925));
        vk.IC[22] = Pairing.G1Point(uint256(18192067173555454021387552622052288493062022801815405851731113728064284360099), uint256(18856567199566236944604426436342272286345266516820541633117683725393232558166));
        vk.IC[23] = Pairing.G1Point(uint256(2567646352344353728075326143096507711301449780087699403669091899581074983738), uint256(15726455362069176263937182785179890416157520713108828001880054741906214415082));
        vk.IC[24] = Pairing.G1Point(uint256(1284379584475247794855076499284894712288248930989233567632296939829204279936), uint256(15247913908185137509714729357735588378866203401661128342252852971254885406362));
        vk.IC[25] = Pairing.G1Point(uint256(15460036084581423692846658291140337164344913476628520521536012153936910128509), uint256(8831696050554739787749368056210588258493437088464275940108692391017473736558));
        vk.IC[26] = Pairing.G1Point(uint256(7346215306723337312152111873697806275625834263027415176204620021005173224916), uint256(13282268681557635783529167008481497398048524485292578531949738020358048680974));
        vk.IC[27] = Pairing.G1Point(uint256(10168490080364414825741809899569195096879050842559260830468477807264017776853), uint256(11708916822285232333362478287315686093418095292729806700203579062798363013285));
        vk.IC[28] = Pairing.G1Point(uint256(10095854212388485781481639588684959789411019949429338562312580486563607904055), uint256(6257318135147863455919319357022704400976011257147780356866761693203454893909));
        vk.IC[29] = Pairing.G1Point(uint256(12419568662190842468412985373327179436287565609791699866311527863882451696348), uint256(14830628944606212214093617354019245568450010597105274278350542044400035646189));
        vk.IC[30] = Pairing.G1Point(uint256(19977511370649248022799743839663637544402821569963556026591491691896528065092), uint256(7621500226239576788129454457475988689157036597233777903068181154195600025327));
        vk.IC[31] = Pairing.G1Point(uint256(1353109995393619229674659864569888286575265366153158613978732172863197326285), uint256(19899101251707795779614245566116292222232251137550422663792275097827348508928));
        vk.IC[32] = Pairing.G1Point(uint256(5048164920079136417574580728820930257153026416505529290588877290561357523406), uint256(14239843703486510919883711996540036801062517033342306935267786539324844023631));
        vk.IC[33] = Pairing.G1Point(uint256(7412870380536200130975778509737029598224903407023245188876280779171214757937), uint256(20965165644098479385967255682070066722877164250297361070395129456165865906193));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[33] memory input
    ) public view returns (bool r) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}