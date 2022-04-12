// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ItemBase.sol";

contract Item01_Food is ItemBase {
  string public constant itemName1 = "Apple";
  string public constant itemDesc1 = "No $energy loss when breed";
  string public constant itemCont1 =
    "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";

  string public constant itemName2 = "Roast Chicken";
  string public constant itemDesc2 = "No $orb fee when breed";
  string public constant itemCont2 =
    "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";

  string public constant itemName3 = "Bread";
  string public constant itemDesc3 = "Fill 25 $energy";
  string public constant itemCont3 =
    "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";

  string public constant itemName4 = "Fried Egg";
  string public constant itemDesc4 = "Fill 50 $energy";
  string public constant itemCont4 =
    "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";

  constructor() {
    name = "Potion";
    itemCount = 4;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IItem.sol";

contract ItemBase is Ownable, IItem {
  string public override name;
  uint16 public override itemCount;

  mapping(bytes32 => string) public extras;

  function getName(uint16 traitId) external view override returns (string memory) {
    bool succ;
    bytes memory ret;
    string memory traitStr = toString(traitId);
    if (traitId > itemCount) {
      bytes32 key = keccak256(abi.encodePacked("itemName", traitStr));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature("extras(bytes32)", key));
    } else {
      string memory key = string(abi.encodePacked("itemName", traitStr, "()"));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature(key, ""));
    }
    require(succ);
    return abi.decode(ret, (string));
  }

  function getDesc(uint16 traitId) external view override returns (string memory) {
    bool succ;
    bytes memory ret;
    string memory traitStr = toString(traitId);
    if (traitId > itemCount) {
      bytes32 key = keccak256(abi.encodePacked("itemDesc", traitStr));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature("extras(bytes32)", key));
    } else {
      string memory key = string(abi.encodePacked("itemDesc", traitStr, "()"));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature(key, ""));
    }
    require(succ);
    return abi.decode(ret, (string));
  }

  function getContent(uint16 traitId) external view override returns (string memory) {
    bool succ;
    bytes memory ret;
    string memory traitStr = toString(traitId);
    if (traitId > itemCount) {
      bytes32 key = keccak256(abi.encodePacked("itemCont", traitStr));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature("extras(bytes32)", key));
    } else {
      string memory key = string(abi.encodePacked("itemCont", traitStr, "()"));
      (succ, ret) = address(this).staticcall(abi.encodeWithSignature(key, ""));
    }
    require(succ);
    return wrapTag(abi.decode(ret, (string)));
  }

  function wrapTag(string memory uri) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<image x="0" y="0" width="320" height="320" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
          uri,
          '"/>'
        )
      );
  }

  function setExtras(string[] calldata keys, string[] calldata data) external onlyOwner {
    for (uint16 i = 0; i < keys.length; i++) {
      extras[keccak256(bytes(keys[i]))] = data[i];
    }
  }

  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "1";
    } else {
      value += 1;
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
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
pragma solidity ^0.8.0;

interface IItem {
  function name() external view returns (string memory);

  function itemCount() external view returns (uint16);

  function getName(uint16 traitId) external view returns (string memory data);

  function getDesc(uint16 traitId) external view returns (string memory data);

  function getContent(uint16 traitId) external view returns (string memory data);
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