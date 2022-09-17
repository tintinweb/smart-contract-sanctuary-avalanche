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