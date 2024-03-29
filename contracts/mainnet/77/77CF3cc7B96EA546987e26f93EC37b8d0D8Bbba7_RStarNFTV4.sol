// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRule {
    /* State Variables Getter */
    // DISCOUNT higher then fee higher, DISCOUNT lower then fee lower.
    function DISCOUNT() external view returns (uint256);
    function BASE() external view returns (uint256);

    /* View Functions */
    function verify(address) external view returns (bool);
    function calDiscount(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStarNFTV4 {
    function owner() external view returns (address);
    function addMinter(address minter) external;
    function mint(address account, uint256 cid) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getNumMinted() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../RuleBase.sol";
import "./IStarNFTV4.sol";

contract RStarNFTV4 is RuleBase {
    uint256 public immutable DISCOUNT;
    IStarNFTV4 public immutable starNFT;

    constructor(IStarNFTV4 nft_, uint256 discount_) {
        starNFT = nft_;
        DISCOUNT = discount_;
    }

    function verify(address usr_) public view returns (bool) {
        return starNFT.balanceOf(usr_) > 0;
    }

    function calDiscount(address usr_) external view returns (uint256) {
        return verify(usr_) ? DISCOUNT : BASE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IRule.sol";

abstract contract RuleBase is IRule {
    uint256 public constant override BASE = 1e18;
}