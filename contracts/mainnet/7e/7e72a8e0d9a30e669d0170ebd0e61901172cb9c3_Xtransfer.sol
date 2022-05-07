/**
 *Submitted for verification at snowtrace.io on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IERC721 {
	function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
	
	function balanceOf(address owner) external view returns (uint256);
}

contract Xtransfer {
    function xtransfer(address token, address to, uint256[] memory tokenidlist) public {
        for (uint256 i=0; i<tokenidlist.length; i++) {
			IERC721(token).safeTransferFrom(msg.sender, to, tokenidlist[i]);
        }
    }
}