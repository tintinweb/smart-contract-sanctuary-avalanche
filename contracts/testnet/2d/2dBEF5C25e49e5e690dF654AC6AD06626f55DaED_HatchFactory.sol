// SPDX-License-Identifier: MIT
// @author salky
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./HatchRegistry.sol";

contract HatchFactory is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    HatchRegistry public registry;
    Counters.Counter public trackIds;
    Counters.Counter public trackPackIds;

    address public hatchTokenAddress;

    event PacksCreated(
        string packName,
        uint256 packId,
        address[][] packArtistsWallets,
        address packAdminWallet
    );

    event TracksCreated(
        Track trackEvent,
        uint256 packId,
        address[] artistsWallets,
        address trackAdminWallet
    );

    event TrackUpdated(uint256 id, Track trackEvent);

    event NewFeaturedPacks(uint256 packId, uint256 price);

    struct Track {
        uint256 id;
        uint256 packId;
        string packName;
        string trackName;
        string trackUri;
        string fullTrack;
        uint256 trackCost;
        address trackAdminWallet;
        address[] artistsWallets;
        uint256[] artistsShares;
        string[] artistsNames;
    }

    mapping(uint256 => Track) private track;
    mapping(uint256 => bool) public existingTrackId;
    mapping(uint256 => bool) public existingPackId;
    mapping(uint256 => bool) public featuredPackIds;

    modifier maxAmmount(uint256 ammount) {
        require(ammount <= registry.getMaxPerTransaction());
        _;
    }

    constructor(HatchRegistry _registry) {
        registry = _registry;
    }

    function createTrackPack(
        string memory _packName,
        string[] memory _trackNames,
        address _trackAminWallet,
        string[] memory _uris,
        string[] memory _fullTracks,
        uint256[] memory _costs,
        address[][] memory _artistsWallets,
        uint256[][] memory _artistsShares,
        string[][] memory _artistsNames,
        bytes32[] calldata _merkleProof,
        uint256 _rootId
    ) external {
        require(
            registry.getIsCreateTrackPackActive(),
            "Create track packs is closed"
        );
        require(
            _artistsWallets.length <= registry.getMaxArtistsPerTrack(),
            "Too many artists"
        );
        require(
            _artistsWallets.length == _artistsShares.length,
            "Wallets and shares format is not correct"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, registry.getRoots(_rootId), leaf),
            "Invalid Merkle Proof."
        );
        for (uint256 i = 0; i < _costs.length; ++i) {
            require(
                _costs[i] >= registry.minCreateTrackCost(),
                "Track price is too low"
            );
            uint256 totalShares = 0;
            for (uint256 j = 0; j < _artistsShares[i].length; ++j) {
                totalShares += _artistsShares[i][j];
            }
            require(totalShares == 10000, "Shares are not equal to 100%");
            totalShares = 0;
        }
        createTrackInternal(
            _packName,
            _trackNames,
            _trackAminWallet,
            _uris,
            _fullTracks,
            _costs,
            _artistsWallets,
            _artistsShares,
            _artistsNames
        );
    }

    function createTrackInternal(
        string memory _packName,
        string[] memory _trackNames,
        address _trackAminWallet,
        string[] memory _uris,
        string[] memory _fullTracks,
        uint256[] memory _costs,
        address[][] memory _artistsWallets,
        uint256[][] memory _artistsShares,
        string[][] memory _artistsNames
    ) internal maxAmmount(_trackNames.length) {
        trackPackIds.increment();
        uint256 currentPackId = trackPackIds.current();
        for (uint256 i = 0; i < _trackNames.length; ++i) {
            trackIds.increment();
            uint256 currentTrackId = trackIds.current();
            track[currentTrackId] = Track({
                id: currentTrackId,
                packId: currentPackId,
                packName: _packName,
                trackName: _trackNames[i],
                trackUri: _uris[i],
                fullTrack: _fullTracks[i],
                trackCost: _costs[i],
                trackAdminWallet: _trackAminWallet,
                artistsWallets: _artistsWallets[i],
                artistsShares: _artistsShares[i],
                artistsNames: _artistsNames[i]
            });
            existingTrackId[currentTrackId] = true;
            emit TracksCreated(
                track[currentTrackId],
                currentPackId,
                _artistsWallets[i],
                _trackAminWallet
            );
        }
        existingPackId[currentPackId] = true;
        emit PacksCreated(
            _packName,
            currentPackId,
            _artistsWallets,
            _trackAminWallet
        );
    }

    function updateTrack(
        uint256 id,
        string memory _trackName,
        string memory _uri,
        string memory _fullTrack,
        uint256 _cost
    ) external {
        require(
            track[id].trackAdminWallet == msg.sender,
            "Not the admin of this track"
        );
        track[id].trackName = _trackName;
        track[id].trackUri = _uri;
        track[id].fullTrack = _fullTrack;
        track[id].trackCost = _cost;
        emit TrackUpdated(id, track[id]);
    }

    function featurePack(uint256 _packId) external payable nonReentrant {
        require(
            registry.getIsFeaturePackActive(),
            "Feature collections is not active"
        );
        require(existingPackId[_packId], "This collection doesn't exist");
        require(
            !featuredPackIds[_packId],
            "This collection is already featured"
        );
        require(
            msg.value >= registry.getFeaturePackPrice(),
            "Invalid ammount sent"
        );
        featuredPackIds[_packId] = true;
        emit NewFeaturedPacks(_packId, msg.value);
    }

    function getExistingTrackId(uint256 _id) public view returns (bool) {
        return existingTrackId[_id];
    }

    function getTrack(uint256 _id) public view returns (Track memory) {
        require(msg.sender == hatchTokenAddress, "You don't own this track");
        return track[_id];
    }

    function setHatchTokenAddress(address _hatchTokenAddress) public onlyOwner {
        hatchTokenAddress = _hatchTokenAddress;
    }

    function sendEth(address _destination, uint256 _amount) internal {
        (bool sent, ) = _destination.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawAll(address _destination) public onlyOwner nonReentrant {
        sendEth(_destination, address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// @author salky
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HatchRegistry is Ownable {
    uint256 private rootIndex = 0;
    uint256 public hatchMintingFee;
    uint256 public maxPerTransaction;
    uint256 public featurePackPrice;
    uint256 public minCreateTrackCost;
    uint256 public maxArtistsPerTrack;
    address public hatchWallet;
    bool public areSalesActive = true;
    bool isFeaturePackActive = true;
    bool isCreateTrackPackActive = true;

    mapping(uint256 => bytes32) private roots;

    constructor(
        uint256 _hatchMintingFee,
        address _hatchWallet,
        uint256 _featurePackPrice,
        uint256 _minCreateTrackCost,
        uint256 _maxPerTransaction,
        uint256 _maxArtistsPerTrack
    ) {
        hatchMintingFee = _hatchMintingFee;
        hatchWallet = _hatchWallet;
        featurePackPrice = _featurePackPrice;
        minCreateTrackCost = _minCreateTrackCost;
        maxPerTransaction = _maxPerTransaction;
        maxArtistsPerTrack = _maxArtistsPerTrack;
    }

    function getHatchMintingFee() public view returns (uint256) {
        return hatchMintingFee;
    }

    function getMaxPerTransaction() public view returns (uint256) {
        return maxPerTransaction;
    }

    function getFeaturePackPrice() public view returns (uint256) {
        return featurePackPrice;
    }

    function getMinCreateTrackCost() public view returns (uint256) {
        return minCreateTrackCost;
    }

    function getMaxArtistsPerTrack() public view returns (uint256) {
        return maxArtistsPerTrack;
    }

    function getHatchWallet() public view returns (address) {
        return hatchWallet;
    }

    function getAreSalesActive() public view returns (bool) {
        return areSalesActive;
    }

    function getIsFeaturePackActive() public view returns (bool) {
        return isFeaturePackActive;
    }

    function getIsCreateTrackPackActive() public view returns (bool) {
        return isCreateTrackPackActive;
    }

    function getRoots(uint256 _id) public view returns (bytes32) {
        return roots[_id];
    }

    function newMusicRoot(uint256 _newIndex, bytes32 _newRoot)
        external
        onlyOwner
    {
        require(_newIndex == rootIndex + 1, "Cannot rewrite an older root!");
        rootIndex = _newIndex;
        roots[rootIndex] = _newRoot;
    }

    function setHatchMintingFee(uint256 _hatchMintingFee) public onlyOwner {
        hatchMintingFee = _hatchMintingFee;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) public onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setFeaturePackPrice(uint256 _featurePackPrice) public onlyOwner {
        featurePackPrice = _featurePackPrice;
    }

    function setMinCreateTrackCost(uint256 _minCreateTrackCost)
        public
        onlyOwner
    {
        minCreateTrackCost = _minCreateTrackCost;
    }

    function setMaxArtistsPerTrack(uint256 _maxArtistsPerTrack)
        public
        onlyOwner
    {
        maxArtistsPerTrack = _maxArtistsPerTrack;
    }

    function setNewHatchWallet(address _hatchWallet) public onlyOwner {
        hatchWallet = _hatchWallet;
    }

    function setSaleActive() public onlyOwner {
        areSalesActive = !areSalesActive;
    }

    function setIsFeaturePackActive() public onlyOwner {
        isFeaturePackActive = !isFeaturePackActive;
    }

    function setIsCreateTrackPackActive() public onlyOwner {
        isCreateTrackPackActive = !isCreateTrackPackActive;
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
library MerkleProof {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}