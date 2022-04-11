// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ItemBase.sol";

contract Item00_Potion is ItemBase {
  string public constant itemName1 = "Blue";
  string public constant itemDesc1 = "Increase hunt rewards by 10%";
  string public constant itemCont1 =
    "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";

  string public constant itemName2 = "Green";
  string public constant itemDesc2 = "Fill 20 $energy";
  string public constant itemCont2 =
    "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";

  string public constant itemName3 = "Purple";
  string public constant itemDesc3 = "Decrease breed count (Huntress Only)";
  string public constant itemCont3 =
    "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";

  string public constant itemName4 = "Pink";
  string public constant itemDesc4 = "Decrease $crystal price by 60%";
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