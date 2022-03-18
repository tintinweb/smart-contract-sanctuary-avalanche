//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EternalStorage is Ownable {
  address public latestVersion;

  string private constant ERROR_LATESTVERSION = "only latestVersion can call this contract";

  mapping(bytes32 => address) AddressStorage;
  mapping(bytes32 => bool) BooleanStorage;
  mapping(bytes32 => bytes) BytesStorage;
  mapping(bytes32 => int256) IntStorage;
  mapping(bytes32 => string) StringStorage;
  mapping(bytes32 => uint256) UIntStorage;

  modifier onlyLatestVersion() {
    require(msg.sender == latestVersion, ERROR_LATESTVERSION);
    _;
  }

  function upgradeVersion(address _newVersion) public onlyOwner {
    latestVersion = _newVersion;
  }

  function getAddressValue(bytes32 record) public view returns (address) {
    return AddressStorage[record];
  }

  function getBooleanValue(bytes32 record) public view returns (bool) {
    return BooleanStorage[record];
  }

  function getBytesValue(bytes32 record) public view returns (bytes memory) {
    return BytesStorage[record];
  }

  function getIntValue(bytes32 record) public view returns (int256) {
    return IntStorage[record];
  }

  function getStringValue(bytes32 record) public view returns (string memory) {
    return StringStorage[record];
  }

  function getUIntValue(bytes32 record) public view returns (uint256) {
    return UIntStorage[record];
  }

  function setAddressValue(bytes32 record, address value) public onlyLatestVersion {
    AddressStorage[record] = value;
  }

  function setBooleanValue(bytes32 record, bool value) public onlyLatestVersion {
    BooleanStorage[record] = value;
  }

  function setBytesValue(bytes32 record, bytes memory value) public onlyLatestVersion {
    BytesStorage[record] = value;
  }

  function setIntValue(bytes32 record, int256 value) public onlyLatestVersion {
    IntStorage[record] = value;
  }

  function setStringValue(bytes32 record, string memory value) public onlyLatestVersion {
    StringStorage[record] = value;
  }

  function setUIntValue(bytes32 record, uint256 value) public onlyLatestVersion {
    UIntStorage[record] = value;
  }

  function deleteUint(bytes32 _key) public onlyLatestVersion {
    delete UIntStorage[_key];
  }

  function deleteString(bytes32 _key) public onlyLatestVersion {
    delete StringStorage[_key];
  }

  function deleteAddress(bytes32 _key) public onlyLatestVersion {
    delete AddressStorage[_key];
  }

  function deleteBytes(bytes32 _key) public onlyLatestVersion {
    delete BytesStorage[_key];
  }

  function deleteBool(bytes32 _key) public onlyLatestVersion {
    delete BooleanStorage[_key];
  }

  function deleteInt(bytes32 _key) public onlyLatestVersion {
    delete IntStorage[_key];
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