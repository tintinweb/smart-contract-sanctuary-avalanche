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