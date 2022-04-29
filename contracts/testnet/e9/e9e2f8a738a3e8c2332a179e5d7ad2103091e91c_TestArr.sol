/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TestArr {


    mapping(bytes => uint256) bytesList;
    mapping(address => uint256) addressList;
    mapping(string => uint256) stringList;

    function addToAddressList(address item) external {
        addressList[item] = 1;
    }

    function addToAddressListArr(address[] calldata list) external {
        for (uint256 i = 0; i < list.length; ++i) {
            addressList[list[i]] = 1;
        }
    }

    function addToStringList(string calldata item) external {
        stringList[item] = 1;
    }

    function addToStringListArr(string[] calldata list) external {
        for (uint256 i = 0; i < list.length; ++i) {
            stringList[list[i]] = 1;
        }
    }

    function addToByteList(bytes calldata item) external {
        bytesList[item] = 1;
    }

    function addToByteListArr(bytes[] calldata list) external {
        for (uint256 i = 0; i < list.length; ++i) {
            bytesList[list[i]] = 1;
        }
    }

}