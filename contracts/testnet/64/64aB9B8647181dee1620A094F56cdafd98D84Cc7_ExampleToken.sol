// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SoulBoundBaseInterface.sol";
import "./SoulBoundSubTokenInterface.sol";

struct ExampleTokenMetaData {
    string s;
}

contract ExampleToken is SoulBoundSubTokenI {
    SoulBoundBaseI _base;

    mapping(address => bool) _claimed;
    mapping(uint256 => address) _owners;

    mapping(uint256 => ExampleTokenMetaData) _metadata;

    constructor(SoulBoundBaseI base_) {
        _base = base_;
    }

    function mint(string memory userDefinedString_) external returns (uint256) {
        require(!_claimed[msg.sender], "already claimed");
        uint256 tokenId = _base.mint(msg.sender);
        _owners[tokenId] = msg.sender;
        _metadata[tokenId] = ExampleTokenMetaData(userDefinedString_);
        _claimed[msg.sender] = true;
        return tokenId;
    }

    function metadata(uint256 tokenId_) external view returns (bytes memory) {
        require(_owners[tokenId_] != address(0x0), "token not found");
        return abi.encode(_metadata[tokenId_].s);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

// this is the interface for subtokens to call from base
// souldboundbase must implement these
interface SoulBoundBaseI {
    function mint(address to_) external returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

// this is the interface for subtokens to call from base
// souldboundbase must implement these
interface SoulBoundSubTokenI {
    // function mint(address to_) external returns (uint256);
    function metadata(uint256 tokenId_) external view returns (bytes memory);
}