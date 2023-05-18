// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../Utils/Admin.sol";

contract ImplLib is Admin {
    address public implERC721;
    address public implERC1155;

    mapping (uint256 => mapping(bytes32 => address)) public idAddress; //type => id => address
    mapping (uint256 => mapping(bytes32 => bool)) public idStat; //type => id => stat

    event CollectionCreated(bytes32 indexed id, address indexed collection, uint256 typeCollection, address indexed sender, uint256 timestamp);

    constructor(
        address _implERC721, 
        address _implERC1155

    ){
        implERC721 = _implERC721;
        implERC1155 = _implERC1155;
    }
    
    //1
    function setImplERC721 (address _implERC721) external onlyAdmin {
        implERC721 =  _implERC721;
    }

    //2
    function setImplERC1155 (address _implERC1155) external onlyAdmin {
        implERC1155 =  _implERC1155;
    }

    function addMap(bytes32 _id, address _collection, uint256 _typeCollection, address _creator) public onlyAdmin{
        require(idAddress[_typeCollection][_id] == address(0), "id already used");
        require(idStat[_typeCollection][_id] == false, "id already registered");
        idAddress[_typeCollection][_id] = _collection;
        idStat[_typeCollection][_id] = true;

        emit CollectionCreated(_id, _collection, _typeCollection, _creator, block.timestamp);
    }

    function getMap(bytes32 _id, uint256 _typeCollection) public view returns(address _entity) {
        return idAddress[_typeCollection][_id];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Admin is Ownable{
    event AddAdminLog(address indexed newAdmin);
    event RemoveAdminLog(address indexed removedAdmin);
    address[] admin;
    mapping(address=>bool) records;
    
    /**
    * @dev Modifier to check if function called by registered admins.
    */
    modifier onlyAdmin(){
        require(records[msg.sender]==true, "msg.sender must be admin");
        _;
    }

    /**
    * @dev Constructor. Set the creator of the contract as one of admin.
    */
    constructor() {
        admin.push(msg.sender);
        records[msg.sender] = true;
    }
    
    /**
    * @dev function to add new admin.
    * @param _address Address of new admin.
    */
    function addAdmin(address _address) onlyOwner() external {
        if (!records[_address]) {
            admin.push(_address);
            records[_address] = true;
            emit AddAdminLog(_address);
        }
    }

    /**
    * @dev function to remove an admin
    * @param _address Address of the admin that is going to be removed.
    */
    function removeAdmin(address _address) onlyOwner() external{
        for (uint i = 0; i < admin.length; i++) {
            if (admin[i] == _address) {
                delete admin[i];
                records[_address] = false;
                emit RemoveAdminLog(_address);
            }
        }
    }

    /**
    * @dev function to check whether the address is registered admin or not
    * @param _address Address to be checked.
    */
    function isAdmin(address _address) public view returns(bool) {
        return records[_address];
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