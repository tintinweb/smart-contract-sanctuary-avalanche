/**
 *Submitted for verification at snowtrace.io on 2022-06-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract dogeTraits is Ownable {

    mapping (address => bool) public traitAdmins;

    mapping (uint256 => string) public traitNames;
    // traitId => tokenId => value
    mapping (uint256 => mapping(uint256 => uint256)) public traitValues;
    mapping (uint256 => bool) public traitActive;
    uint256 public traitCount = 0;

    constructor() {
        traitAdmins[msg.sender] = true;
    }

    function setTraitAdmin(
        address account, bool newState
    ) public onlyOwner {
        traitAdmins[account] = newState;
    }

    function addTrait(string memory name) public {
        require(traitAdmins[msg.sender] == true, "Caller is not a trait admin.");
        traitNames[traitCount] = name;
        traitCount++;
    }

    function updateTrait(uint256 traitId, bool newState, string memory name) public {
        require(traitAdmins[msg.sender] == true, "Caller is not a trait admin.");
        traitActive[traitId] = newState;
        traitNames[traitId] = name;
    }

    function setTrait(uint256 traitId, uint256 tokenId, uint256 value) public returns (bool) {
        require(traitAdmins[msg.sender] == true, "Caller is not a trait admin.");
        traitValues[traitId][tokenId] = value;
        return true;
    }

    function bulkSetTrait(uint256 traitId, uint256[] memory tokenIds, uint256[] memory values) public returns (bool) {
        require(traitAdmins[msg.sender] == true, "Caller is not a trait admin.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            traitValues[traitId][tokenIds[i]] = values[i];
        }
        return true;
    }

    function bulkSetTraitSameValue(uint256 traitId, uint256[] memory tokenIds, uint256 value) public returns (bool) {
        require(traitAdmins[msg.sender] == true, "Caller is not a trait admin.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            traitValues[traitId][tokenIds[i]] = value;
        }
        return true;
    }

    function getTrait(uint256 traitId, uint256 tokenId) public view returns (uint256) {
        return traitValues[traitId][tokenId];
    }
}