/**
 *Submitted for verification at snowtrace.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IBoldPointItem {

    function onBoxOpened(address caller, uint256 tokenId, uint256 amount) external returns(bool success);

}

pragma solidity 0.8.10;

contract BoldPointBoxHook is IBoldPointItem {

    function onBoxOpened(address caller, uint256 tokenId, uint256 amount) external override returns(bool success) {
        return true;
    }

}