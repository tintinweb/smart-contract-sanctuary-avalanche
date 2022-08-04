// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./SimpleStorage.sol";

contract StorageFactory {

    SimpleStorage[] public SimpleStorageArray;

    function CreateSimpleStorage() public {

        SimpleStorage simpleStorage = new SimpleStorage();
        SimpleStorageArray.push(simpleStorage);

    }

}