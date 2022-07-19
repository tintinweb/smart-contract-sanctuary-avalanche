/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    uint256 public publicSaleStartTime;

    function setPublicSaleStartTime(uint256 publicSaleStartTime_) public {
        publicSaleStartTime = publicSaleStartTime_;
    }

    function publicSaleMint(uint256 _quantity) external payable {
        if (block.timestamp < publicSaleStartTime) {
            revert("bad timestamp");
        }
    }
}