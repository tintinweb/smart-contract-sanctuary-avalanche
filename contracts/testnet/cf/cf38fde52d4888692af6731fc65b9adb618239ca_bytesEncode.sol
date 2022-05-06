/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-05
*/

// SPDX-License-Identifier : MIT

pragma solidity ^0.8.10;

contract bytesEncode {
    
    function getCallDatas(
        uint amountOutMin, 
        address[] calldata path,
        address to,
        uint deadline
    ) external pure returns (bytes memory callDatas) {

       return callDatas = abi.encodeWithSignature("swapAVAXForExactTokens(uint256,address[],address,uint256)", amountOutMin, path, to, deadline);

    }

    
    

}