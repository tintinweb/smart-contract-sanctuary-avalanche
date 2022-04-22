/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-21
*/

// SPDX-License-Identifier: GNU General Public License v3.0
// File @openzeppelin/contracts/utils/[email protected]

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


// File Contracts/App/Authentication.sol

pragma solidity ^0.8.7;

interface IAuthentication {
    function isOwnerOfNFT(address _account, uint _chainId, address _projectAddress, uint _tokenId) external view returns (bool);
    function isProjectWhitelisted(uint _chainId, address _projectAddress) external view returns (bool);
}

contract Authentication is Ownable, IAuthentication {
    // Event to be emitted when owner of a NFT changes
    event NFTTransfers(Transfer[] _transfer);
    // Event to be emmited when whitelist status of a project changes
    event WhitelistStatusUpdate(uint chainId, address projectAddress, bool status);

    // Data that should be send to update the NFT ownership
    struct OwnershipUpdate {
        uint chainId;
        address projectAddress;
        uint tokenId;
        address newOwner;
        string image;
    }

    // Data that will be emited with event to describe NFTTransfer
    struct Transfer {
        address from;
        address to;
        uint chainId;
        address projectAddress;
        uint tokenId;
        string image;
    }

    // Data of a project
    struct WhitelistedProject {
        uint chainId;
        address projectAddress;
    }

    // Adding or a deleting a project from whitelist will be called by owner and it will be called much less compared to "isProjectWhitelisted" 
    // So we choose to optimize "isProjectWhitelisted" while not losing the ability to return all of the whitelisted projects
    // Therefore, we use mapping to have O(1) operations for "isProjectWhitelisted" which will be used inside other contract many times by users.
    
    // Mapping to store if a projectAddress is whitelisted for the chainId
    // Inputs to mapping =>
    //      uint is the chainId
    //      address is the project address
    mapping(uint => mapping(address => bool)) private _whitelistedProjects;
    // In addition, we update the array every time when we add/delete a project so that we can return all whitelisted projects for backend
    WhitelistedProject[] private _whitelistedProjectsArray;

    // Mapping to store owner address for all NFTs (multi-chain) on the contract
    // Inputs to mapping => 
    //      uint is the chainId
    //      address is the NFT project's address
    //      uint is the tokenId of the NFT
    //      address is the owner address
    mapping(uint => mapping(address => mapping(uint => address))) private _ownersOfNFTs;

    // Returns if an address owns the NFT
    function isOwnerOfNFT(address _account, uint _chainId, address _projectAddress, uint _tokenId) external view override returns (bool) {
        return _account == _ownersOfNFTs[_chainId][_projectAddress][_tokenId];
    }

    function setMultipleOwnersOfNFTs(OwnershipUpdate[] memory _newOwnerships) external onlyOwner {
        require(_newOwnerships.length <= 200, "Too many NFTs to set owners");
        Transfer[] memory transfers = new Transfer[](_newOwnerships.length);
        for (uint i = 0; i < _newOwnerships.length; i++) {
            // Hold old owner's address in the 'from' variable 
            address from = _ownersOfNFTs[_newOwnerships[i].chainId][_newOwnerships[i].projectAddress][_newOwnerships[i].tokenId];
            // Update the ownership of NFT
            _ownersOfNFTs[_newOwnerships[i].chainId][_newOwnerships[i].projectAddress][_newOwnerships[i].tokenId] = _newOwnerships[i].newOwner;
            // Create Transfer struct to be emitted with event
            transfers[i] = Transfer({from: from, to: _newOwnerships[i].newOwner, chainId: _newOwnerships[i].chainId, projectAddress: _newOwnerships[i].projectAddress, tokenId: _newOwnerships[i].tokenId, image: _newOwnerships[i].image});
        }
        emit NFTTransfers(transfers);
    }

    function getWhitelistedProjects() external view returns (WhitelistedProject[] memory) {
        return _whitelistedProjectsArray;
    }

    // Update if a project address is whitelisted or not. Only owner can call this function
    function changeStatusOfWhitelistedProject(uint _chainId, address _projectAddress, bool _status) public onlyOwner {
        WhitelistedProject memory whitelistedProject = WhitelistedProject(_chainId, _projectAddress);
        if (_status) {
            _addWhitelistedProject(whitelistedProject);
        } else {
            _deleteWhitelistedProject(whitelistedProject);
        }
        
    }

    // Costs O(n) but this cost is only for the owner
    function _addWhitelistedProject(WhitelistedProject memory _whitelistedProject) internal {
        require(_whitelistedProjects[_whitelistedProject.chainId][_whitelistedProject.projectAddress] == false, "Project is already whitelisted");
        _whitelistedProjects[_whitelistedProject.chainId][_whitelistedProject.projectAddress] = true;
        _whitelistedProjectsArray.push(_whitelistedProject);
        emit WhitelistStatusUpdate(_whitelistedProject.chainId, _whitelistedProject.projectAddress, true);
    }

    // Costs O(n) but this cost is only for the owner
    function _deleteWhitelistedProject(WhitelistedProject memory _whitelistedProject) internal {
        // require(_whitelistedProjects[_chainId][_projectAddress], "Project is not whitelisted");
        (bool found, uint index) = _getWhitelistedProjectIndex(_whitelistedProject.chainId, _whitelistedProject.projectAddress);
        require(found, "Project is not whitelisted");
        // Remove from mapping
        _whitelistedProjects[_whitelistedProject.chainId][_whitelistedProject.projectAddress] = false;
        // Replace deleted whitelistedProjects' index with the last project and pop the last element
        _whitelistedProjectsArray[index] = _whitelistedProjectsArray[_whitelistedProjectsArray.length - 1];
        _whitelistedProjectsArray.pop();
        emit WhitelistStatusUpdate(_whitelistedProject.chainId, _whitelistedProject.projectAddress, false);
    }

    // Returns the index of the projects inside the _whitelistedProjectsArray
    function _getWhitelistedProjectIndex(uint _chainId, address _projectAddress) internal view returns (bool, uint) {
        for (uint i; i < _whitelistedProjectsArray.length; i++) {
            if (_whitelistedProjectsArray[i].chainId == _chainId && _whitelistedProjectsArray[i].projectAddress == _projectAddress ) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    // Returns if a project address is whitelisted or not.
    function isProjectWhitelisted(uint _chainId, address _projectAddress) external view override returns (bool) {
        return _whitelistedProjects[_chainId][_projectAddress];
    }
}