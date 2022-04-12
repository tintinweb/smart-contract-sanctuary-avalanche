/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT AND UNLICENSED
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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File contracts/interfaces/IPoolMechanics.sol

pragma solidity 0.8.11;

interface IPoolMechanics {
    struct Tiers {
        uint256 rangeFrom; // in Spark
        uint256 rangeTo; // in Spark
        uint256 poolEntryFee; // in basis points
        uint256 mintFee; // in basis points
        uint8 numberOfPredictions;
        uint8 WLCap; // redundant
        uint8 NFTMintableCap; // 4 (6 for top 10 winners) // ToDo: ???????
    }
    event NewTiersSettled(Tiers[] tiers);

    function setNewTiers(Tiers[] memory _tiers) external;

    function getTier(uint256 _amount) external view returns (uint8);

    function getEntryFee(uint8 tier) external view returns (uint256);

    function getMintFee(uint8 tier) external view returns (uint256);

    function getNumberOfPredictions(uint8 tier)
        external
        view
        returns (uint8 numberOfPredictions);

    function getWLCap(uint8 tier) external view returns (uint8 WLCap);

    function getNFTMintableCap(uint8 tier)
        external
        view
        returns (uint8 NFTMintableCap);
}

// File contracts/FPL/PoolMechanics.sol

pragma solidity 0.8.11;

contract PoolMechanics is IPoolMechanics, Context, Ownable {
    mapping(uint8 => Tiers) tiers;

    /// @dev the last tier's "rangeTo" must be set to the max number

    constructor(Tiers[] memory _tiers) {
        for (uint8 i = 0; i < _tiers.length; i++) {
            tiers[i] = _tiers[i];
        }

        emit NewTiersSettled(_tiers);
    }

    function setNewTiers(Tiers[] memory _tiers) external onlyOwner {
        for (uint8 i = 0; i < _tiers.length; i++) {
            tiers[i] = _tiers[i];
        }

        emit NewTiersSettled(_tiers);
    }

    function getTier(uint256 _amount) external view returns (uint8 tier) {
        for (uint8 i = 0; i < 3; i++) {
            if (_amount >= tiers[i].rangeFrom && _amount <= tiers[i].rangeTo) {
                tier = i;
                break;
            }
        }
    }

    function getNumberOfPredictions(uint8 tier)
        external
        view
        returns (uint8 numberOfPredictions)
    {
        numberOfPredictions = tiers[tier].numberOfPredictions;
    }

    function getEntryFee(uint8 tier)
        external
        view
        returns (uint256 poolEntryFee)
    {
        poolEntryFee = tiers[tier].poolEntryFee;
    }

    function getMintFee(uint8 tier) external view returns (uint256 mintFee) {
        mintFee = tiers[tier].mintFee;
    }

    function getWLCap(uint8 tier) public view returns (uint8 WLCap) {
        WLCap = tiers[tier].WLCap;
    }

    function getNFTMintableCap(uint8 tier)
        public
        view
        returns (uint8 NFTMintablesCap)
    {
        NFTMintablesCap = tiers[tier].NFTMintableCap;
    }
}