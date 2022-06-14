// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract UserBase is Ownable {

  mapping (bytes32 => address) private _activatedAddresses;
  mapping (address => bytes32) private _activatedUsernameHashes;
  mapping (bytes32 => string) private _activatedUsernames;

  mapping (address => bool) private _allowed;

  function addressFor(string memory username) public view returns (address) {
    return _activatedAddresses[keccak256(abi.encodePacked(username))];
  }

  function usernameFor(address account) public view returns (string memory) {
    bytes32 usernameHash = _activatedUsernameHashes[account];
    return _activatedUsernames[usernameHash];
  }

  function activate(address account, string memory username) public onlyAllowed {
    string memory oldUsername = usernameFor(account);
    deactivate(account, oldUsername);

    bytes32 usernameHash = keccak256(abi.encodePacked(username));
    _activatedAddresses[usernameHash] = account;
    _activatedUsernameHashes[account] = usernameHash;
    _activatedUsernames[usernameHash] = username;
  }

  function deactivate(address account, string memory username) public onlyAllowed {
    bytes32 usernameHash = keccak256(abi.encodePacked(username));
    _activatedAddresses[usernameHash] = address(0);
    _activatedUsernameHashes[account] = bytes32(0);
    _activatedUsernames[usernameHash] = "";
  }

  modifier onlyAllowed {
    require(_allowed[msg.sender]);
    _;
  }

  function setAllowed(address nftNameService, bool allowed_) public onlyOwner {
    _allowed[nftNameService] = allowed_;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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