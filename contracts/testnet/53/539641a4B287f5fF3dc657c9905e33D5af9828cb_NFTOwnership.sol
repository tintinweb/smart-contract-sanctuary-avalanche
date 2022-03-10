/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-09
*/

// SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.7;

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


contract NFTOwnership is Ownable {

    struct OwnershipUpdate {
        uint chainId;
        address projectAddress;
        uint tokenId;
        address newOwner;
    }
    // Mapping to store owner address for all NFTs (multi-chain) on the contract
    // Inputs to mapping => 
    //      uint is the chainId
    //      address is the NFT project's address
    //      uint is the tokenId of the NFT
    //      address is the owner address
    mapping(uint => mapping(address => mapping(uint => address))) private ownersOfNFTs;

    function setOwnerOfNFT(uint _chainId, address _projectAddress, uint _tokenId, address _newOwner) public onlyOwner {
        ownersOfNFTs[_chainId][_projectAddress][_tokenId] = _newOwner;
    }

    function getOwnerOfNFT(uint _chainId, address _projectAddress, uint _tokenId) external view returns (address ownerOfNFT){
        ownerOfNFT = ownersOfNFTs[_chainId][_projectAddress][_tokenId];
    }

    function setMultipleOwnersOfNFT(uint[] memory _chainId, address[] memory _projectAddress, uint[] memory _tokenIds, address[] memory _newOwners) external onlyOwner {
        require(_tokenIds.length < 50, "Too many NFTs to set owners");
        require(_chainId.length == _projectAddress.length && _chainId.length == _tokenIds.length && _chainId.length == _newOwners.length, "Must have the same length");
        for (uint i = 0; i < _tokenIds.length; i++) {
            ownersOfNFTs[_chainId[i]][_projectAddress[i]][_tokenIds[i]] = _newOwners[i];
        }
    }

    function setMultiple(OwnershipUpdate[] memory _newOwnerships) external onlyOwner {
        require(_newOwnerships.length < 50, "Too many NFTs to set owners");
        for (uint i = 0; i < _newOwnerships.length; i++) {
            // setOwnerOfNFT(_newOwnerships[i].chainId, _newOwnerships[i].projectAddress, _newOwnerships[i].tokenId, _newOwnerships[i].newOwner);
            ownersOfNFTs[_newOwnerships[i].chainId][_newOwnerships[i].projectAddress][_newOwnerships[i].tokenId] = _newOwnerships[i].newOwner;
        }
    }
}