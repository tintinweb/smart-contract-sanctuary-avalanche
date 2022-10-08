// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface APIConsumer {

    function requestData() external returns (bytes32 requestId);
    function value() external returns (uint256);
}

contract ViewChainlinkCall {

    APIConsumer ChainlinkCallContract = APIConsumer(0xb3AeFB914a7C174f132A1D8eE35A1774F239aAC6);

    function request() public {
        ChainlinkCallContract.requestData();
    }


    function viewValue() public returns(uint256) {
        return ChainlinkCallContract.value();
    }
}