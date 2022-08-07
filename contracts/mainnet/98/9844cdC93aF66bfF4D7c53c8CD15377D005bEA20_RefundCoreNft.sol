// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

// interface CoreNFT {
//     function balanceOf(address owner) external view returns (uint256 balance);

//     function tokenOfOwnerByIndex(address owner, uint256 index)
//         external
//         view
//         returns (uint256);
// }

contract RefundCoreNft is Ownable {
    address private nftManager = 0x5e865fe971185Fcd763C92cC7C788a45a2a195fB;
    address private seedNFT = 0x42ecA91e6AA2aB734b476108167ad71396db564d;
    address private saplingNFT = 0x37Cc7304DB8Fc9b01E81352dcEF4e05abE4D180D;
    address private treeNFT = 0x8f07f8D305423F790099b3AF58743a0D2E21Ba4D;

    mapping(address => EligibleNfts) addressToEligibleNfts;
    mapping(address => bool) addressToHasClaimed;

    ///We use these mappings in the future to give extra bonuses to those that do not have claimed their NFTs yet.
    mapping(uint => bool) isSeedNftIdClaimed;
    mapping(uint => bool) isSaplingNftIdClaimed;
    mapping(uint => bool) isTreeNftIdClaimed;

    struct EligibleNfts {
        uint[] seedNfts;
        uint[] saplingNfts;
        uint[] treeNfts;
    }

    ///Returns the TreeNFTs that are eligible to be claimed.
    ///This does not know if any of the NFTs are already claimed.
    function getEligibleTreeNfts(address _address) public view returns (uint[] memory) {
        EligibleNfts memory eligibleNfts = addressToEligibleNfts[_address];

        return eligibleNfts.treeNfts;
    }

    function addEligibleTreeNfts(address _address, uint[] memory treeNftIdsToAdd)
        public onlyOwner
    {
        require(
            treeNftIdsToAdd.length > 0,
            "At least 1 index in idsToAdd must be passed!"
        );

        EligibleNfts memory eligibleNfts = addressToEligibleNfts[_address];

        for (uint i = 0; i < treeNftIdsToAdd.length; i++) {
            bool exists = false;
            //Loop through the eligibleNfts and if the treenft is not added, do so
            for(uint j = 0; j < eligibleNfts.treeNfts.length; j++) {
                if(eligibleNfts.treeNfts[j] == treeNftIdsToAdd[i]) {
                    exists = true;
                }
            }

            //If doesnt exist yet, add
            if(exists == false) {
                addressToEligibleNfts[_address].treeNfts.push(treeNftIdsToAdd[i]);
            }
        }
    }

    ///Checks if the inputted address has already claimed or not
    function hasAddressClaimed(address _address) public view returns (bool) {
        return addressToHasClaimed[_address];
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