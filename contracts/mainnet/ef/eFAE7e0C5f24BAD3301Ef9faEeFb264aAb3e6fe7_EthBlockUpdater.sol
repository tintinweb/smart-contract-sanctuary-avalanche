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
    string constant BLS_SIG_DST = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+';

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
        assert(length <= 32);

        for (uint256 i; i < length; ) {
            bytes1 b = data[start + i];
            result = result + (uint8(b) * 2**(8 * (length - i - 1)));
        unchecked {
            ++i;
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
        for (uint256 i; i < 32; ) {
            b0Input[i + 64] = message[i];
        unchecked {
            ++i;
        }
        }
        b0Input[96] = 0x01;
        for (uint256 i; i < 44; ) {
            b0Input[i + 99] = bytes(BLS_SIG_DST)[i];
        unchecked {
            ++i;
        }
        }

        bytes32 b0 = sha256(abi.encodePacked(b0Input));

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(
            abi.encodePacked(b0, bytes1(0x01), bytes(BLS_SIG_DST))
        );
        assembly {
            mstore(add(output, 0x20), chunk)
        }

        for (uint256 i = 2; i < 9; ) {
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
        result[0] = (fp.b & (mask << (55 * 0))) >> (55 * 0);
        result[1] = (fp.b & (mask << (55 * 1))) >> (55 * 1);
        result[2] = (fp.b & (mask << (55 * 2))) >> (55 * 2);
        result[3] = (fp.b & (mask << (55 * 3))) >> (55 * 3);
        result[4] = (fp.b & (mask << (55 * 4))) >> (55 * 4);
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
        vk.alfa1 = Pairing.G1Point(uint256(19180371236082749815412587708897818390419670158646988213724647811772090677132), uint256(14261676101405252929118654635042678084041317874181734843385199439000099176406));
        vk.beta2 = Pairing.G2Point([uint256(15053087832216727031597345008905384784526286328503150102473517090408672544841), uint256(9880039693757340816426368637153772082544831745907958762279056222281963015214)], [uint256(10833276387499671602047363052437905628576810145615795323328460367667442648953), uint256(15771371962193953606658471714098477588374319556564626248002457555511389561294)]);
        vk.gamma2 = Pairing.G2Point([uint256(4100835508626462239584877924131565054342421812258774472933208524684130411585), uint256(3398980272955161939784735835270197569434200207236667564252542314235063840766)], [uint256(19261031285019620043495915140711441925020369911811330250797323807884230134840), uint256(17919604420767494567657275276801177732045508769452625243472122568473698587063)]);
        vk.delta2 = Pairing.G2Point([uint256(4833057268945428524544488207489513032661300079071765599622275532145571123515), uint256(16623277156725942990404175424392854116533139161698904444334806767818314373708)], [uint256(9531449385997855804914387216705801577255381820353171709917746971874270783951), uint256(12556936782917122160636335806257481517635264719313658998253216331010408308404)]);
        vk.IC[0] = Pairing.G1Point(uint256(1744342157045710545875250446998137017122484036776239581963246858413516628261), uint256(20097294504245045729302433061290366086794229217434966570308851357271019482346));
        vk.IC[1] = Pairing.G1Point(uint256(7276575135480447249998948300999186215503113093499012726768846160298538898203), uint256(2040026324204414555177442657609944625594840405656132229493548620699716579892));
        vk.IC[2] = Pairing.G1Point(uint256(8798638556685077227666620579682893584862388872297229894656107762628436544274), uint256(13900143069199507163829952075075174229845922258706229255246379279207589980969));
        vk.IC[3] = Pairing.G1Point(uint256(10168112529015699255258869219080574914311568381060321953267277378259685884652), uint256(19140486934684209644910158769930254044514450358842516803837183042701396114999));
        vk.IC[4] = Pairing.G1Point(uint256(16607283803432884513676857544400066645831516368795359768934897625809365459438), uint256(20272066086629726040559915954678094212748984404346266606274195215333135336303));
        vk.IC[5] = Pairing.G1Point(uint256(12070922938426658619540663575814466864525945500469293863737796810102552459287), uint256(11330220484924506518742421824050726495785275181529314569173938453937051003052));
        vk.IC[6] = Pairing.G1Point(uint256(18200338615449322306644541421135955025568099880888033429309126110550747211679), uint256(2039579805961151001562059796646276731267207624005438238646751056247279531311));
        vk.IC[7] = Pairing.G1Point(uint256(12913315478022401357786800966850409314484325460455624766236003653131876402425), uint256(15333480588607908825827568108865055326043544035254643222952673173851503137282));
        vk.IC[8] = Pairing.G1Point(uint256(4644776237033494300204468335981592684148651508374333017338455877688822756438), uint256(9950563339359170972987475583331016577543507891883214954210697181424994623424));
        vk.IC[9] = Pairing.G1Point(uint256(21321762592585623921203528751443571844332949357826958300226312414756934463318), uint256(21597200714371099168617432508609311537889297128485811760188852120874601977749));
        vk.IC[10] = Pairing.G1Point(uint256(7266292236498465397930820794167897181374633178778309284239209074623183631860), uint256(7174338552857178873898653143238842714402161781761436342987858538604756770278));
        vk.IC[11] = Pairing.G1Point(uint256(18079490907978002513385282774248724728947135796552220824006938058624021641947), uint256(7464617179668737161754133765466287235189611163934465176143443107806332582081));
        vk.IC[12] = Pairing.G1Point(uint256(6245959023130272727159801547669797378280857626096641159526345289451672737514), uint256(19583478442141155123239538171086450788489587324754387302373581530964713991447));
        vk.IC[13] = Pairing.G1Point(uint256(12883317097087827421330318701999319243507671938795167346427673331501374057870), uint256(9742348535150530738793752500456676122464155139361221377222228267731475043161));
        vk.IC[14] = Pairing.G1Point(uint256(15879155086598863675530016237069691774804303280215188039175370437630884933438), uint256(4174823219352603985761211399096260060590266565442133781379207600410438268840));
        vk.IC[15] = Pairing.G1Point(uint256(2565589978204888482540677809655973240164536757188528092980295783806423079985), uint256(17513077925402392092807565034401526595678021876232961123522340450008741707842));
        vk.IC[16] = Pairing.G1Point(uint256(2535599631329788124404410468748497335801952520492199060006037939509735160839), uint256(16801009453259935465274642511832787896738864528911343297864443568728504148089));
        vk.IC[17] = Pairing.G1Point(uint256(21721926834005028966783024001993477700435044713603643588095637143726398431589), uint256(4732984919914009194596927731794113946999419687420257679786360112199333300801));
        vk.IC[18] = Pairing.G1Point(uint256(9066099462571147214764230623507216762311535543786211062369994787577749701481), uint256(5772799521046039021247784822994579762036219505250766788465209153720264931542));
        vk.IC[19] = Pairing.G1Point(uint256(2378375813349033168839203990032001736028204860717288189855224709819262063564), uint256(18716251996974932720983853720107472593086907273749267470382377872674411546707));
        vk.IC[20] = Pairing.G1Point(uint256(9267867879848786217457519653234995377187192786596873990671453017854269960988), uint256(19061630368029917942552895718029089668111374170874107000818631284624181080402));
        vk.IC[21] = Pairing.G1Point(uint256(6040870455351035751680089509282860629339898914865471661446473592592375785110), uint256(18690000380951904164566043609499924971439094550402581052465332286480548307812));
        vk.IC[22] = Pairing.G1Point(uint256(3040053961035594217455014745198177854929152925173228408185940602080660858865), uint256(7190361898336214585676785499002648750245469477573908057602721023702579219225));
        vk.IC[23] = Pairing.G1Point(uint256(20810351846832929437424251430427037947668522176408196084525999478097517038127), uint256(9123908032221788838439870077317711874506469681899386021781764439690881653795));
        vk.IC[24] = Pairing.G1Point(uint256(3264201247277555882867618124888872240510203002828281377978112993366038780567), uint256(10803018202956637919119060171783810189196068953130750566854123246241279291421));
        vk.IC[25] = Pairing.G1Point(uint256(14344888356960606760890380922910970905250530368626884497897335241907028065200), uint256(10897988124560432199310697328323032140978622282390598416174421029455406277462));
        vk.IC[26] = Pairing.G1Point(uint256(13296510115077703407661338509710115232486450956777618437712582903291929034229), uint256(3947762838807364331209291981054036129939690812499385477345442324006578273640));
        vk.IC[27] = Pairing.G1Point(uint256(3375597872357289387277534913588267477067307842919956316808461385108735762156), uint256(10720384256917898832102650752171213260945849567726351323924989406083284474690));
        vk.IC[28] = Pairing.G1Point(uint256(16969344212911063072796145005806302786407420575656213102217953140832407651881), uint256(6445152719330454619427774103237354271085408111779992234650196294203384671424));
        vk.IC[29] = Pairing.G1Point(uint256(6485227748399988281896835960291523025613858088094693390207162973779044157925), uint256(5726154163395175937375861823102857280765281661248727268879206237337907848278));
        vk.IC[30] = Pairing.G1Point(uint256(21317317395275670682368910557126671808192902354229784427428179577706202222453), uint256(7431563658446558680198252767854248698172601344587270376468769161840836928588));
        vk.IC[31] = Pairing.G1Point(uint256(12986713009283675272624134479678883769272262533647625481661126959259452293054), uint256(9836140538426775107634198913145896516049285181935220172685710061172137492150));
        vk.IC[32] = Pairing.G1Point(uint256(156910154540262153462114267735556449178744515314943650917321954422151034951), uint256(10765539948917966676506738583001222137886434920729257286429657668547990666549));
        vk.IC[33] = Pairing.G1Point(uint256(8828590508253940278288046303720069422914742628410918289229823837025763533923), uint256(21317162196608556027107995717615300023093792178825792184542176887864488267784));
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