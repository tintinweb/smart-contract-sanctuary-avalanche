// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ContractRegistryInterface {
  function get(string memory contractName) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface NameHashInterface {
  function hashBytes(bytes calldata name) external view returns (uint256 hash);
  function hashString(string calldata name) external view returns (uint256 hash);
  function inputSignalsToString(uint256[] calldata inputSignals) external view returns (string memory name);
  function inputSignalsToBytes(uint256[] calldata inputSignals) external view returns (bytes memory name);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ContractRegistryInterface.sol";
import "./RainbowTableInterface.sol";
import "./NameHashInterface.sol";


contract NameHashV1 is NameHashInterface {
  ContractRegistryInterface immutable public _contractRegistry;

  function reverseEndianness(uint256 input) internal pure returns (uint256 v) {
    // source https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    v = input;

    // swap bytes
    v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
        ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

    // swap 2-byte long pairs
    v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
        ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

    // swap 4-byte long pairs
    v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
        ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

    // swap 8-byte long pairs
    v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
        ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  function bytesToUint(bytes memory _sl) public pure returns (uint256 ret) {
    uint val;
    assembly {
      val := mload(add(_sl, add(0x20, 0)))
    }
    return reverseEndianness(val);
  }

  function uintToBytes(uint256 num) public pure returns (bytes memory b) {
    uint val = reverseEndianness(num);
    uint i;

    // needs to be 32 bytes so we can convert uint256
    bytes memory tmp = new bytes(32);
    assembly {
      mstore(add(tmp, 32), val)
    }

    // our label has a max length of 31 bytes
    uint256 o1 = 31;
    for (i = 0; i < 31; i += 1) {
      if (tmp[i] == 0x00) {
        o1 = i;
        break;
      }
    }
    b = new bytes(o1);
    for (i = 0; i < o1; i += 1) {
      b[i] = tmp[i];
    }
  }

  function labelToUint(bytes calldata _sl) public pure returns (uint256 ret1, uint256 ret2) {
    require(_sl.length <= 62, "NameHashV1: Label cannot be longer than 62 characters");
    bytes memory a1 = new bytes(31);
    bytes memory a2 = new bytes(31);
    for (uint i = 0; i < 31; i += 1) {
      if (i < _sl.length) {
        a1[i] = _sl[i];
      }
    }
    for (uint i = 0; i < 31; i += 1) {
      if (i + 31 < _sl.length) {
        a2[i] = _sl[i+31];
      }
    }

    return (bytesToUint(a1), bytesToUint(a2));
  }

  function uintsToLabel(uint256 i1, uint256 i2) public pure returns (bytes memory) {
    return abi.encodePacked(
      uintToBytes(i1),
      uintToBytes(i2)
    );
  }

  function inputSignalsToBytes(uint256[] calldata inputSignals) public override pure returns (bytes memory name) {
    require(inputSignals.length % 2 == 0, "NameHashV1: Input signals length must be divisible by 2");
    bytes memory tmp;
    for (uint256 i = 0; i < inputSignals.length; i += 2) {
      tmp = uintsToLabel(inputSignals[i], inputSignals[i+1]);
      if (i == 0) {
        name = tmp;
      } else {
        name = abi.encodePacked(tmp, ".", name);
      }
    }
  }
  
  function inputSignalsToString(uint256[] calldata inputSignals) public override pure returns (string memory name) {
    return string(inputSignalsToBytes(inputSignals));
  }

  function hashBytes(bytes calldata name) override public view returns (uint256 hash) {
    uint[] memory labels;
    uint labelIndex;
    uint labelStart = 0;
    uint labelCount = 2; // there must be at least one label, which 
    bytes1 period = 0x2e;
    RainbowTableInterface rainbowTable = RainbowTableInterface(_contractRegistry.get("RainbowTable"));

    for (uint i = 0; i < name.length; i += 1) {
      if (name[i] == period) {
        labelCount += 2;
      }
    }

    labels = new uint[](labelCount);
    labelIndex = labelCount - 2;

    for (uint i = 0; i < name.length; i += 1) {
      if (name[i] == period) {
        (labels[labelIndex], labels[labelIndex+1]) = labelToUint(name[labelStart:i]);
        labelStart = i + 1;
        labelIndex -= 2;
      }
    }
    (labels[labelIndex], labels[labelIndex+1]) = labelToUint(name[labelStart:name.length]);

    return rainbowTable.getHash(0, labels);
  }

  function hashString(string calldata name) override external view returns (uint256 hash) {
    return hashBytes(bytes(name));
  }

  constructor(ContractRegistryInterface contractRegistry) {
    _contractRegistry = contractRegistry;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface RainbowTableInterface {
  function reveal(uint256[] memory preimage, uint256 hash) external;
  function lookup(uint256 hash) external view returns (uint256[] memory preimage);
  function getHash(uint256 hash, uint256[] calldata preimage) external view returns (uint256);
  function isRevealed(uint256 hash) external view returns (bool);
}