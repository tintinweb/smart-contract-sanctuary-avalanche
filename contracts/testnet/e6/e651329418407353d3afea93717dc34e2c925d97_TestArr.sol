/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-29
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

    function addToStringListArrWithValue(uint256 value, string[] calldata list) external {
        for (uint256 i = 0; i < list.length; ++i) {
            stringList[list[i]] = value;
        }
    }

    function testMultipleUint256Array(uint256[] calldata array1, uint256[] calldata array2) external {
        require (array1.length == array2.length);
    }

    function addToByteList(bytes calldata item) external {
        bytesList[item] = 1;
    }

    function addMultipleToByteList(bytes calldata item, bytes calldata item2) external {
        bytesList[item] = 1;
        bytesList[item2] = 1;
    }

    function addMultipleToStringList(string calldata item, string calldata item2) external {
        stringList[item] = 1;
        stringList[item2] = 1;
    }

    function testMultipleByteArray(bytes[] calldata list1, bytes[] calldata list2) external {
        require(list1.length == list2.length);
    }

    function addToByteListArr(bytes[] calldata list) external {
        for (uint256 i = 0; i < list.length; ++i) {
            bytesList[list[i]] = 1;
        }
    }

}