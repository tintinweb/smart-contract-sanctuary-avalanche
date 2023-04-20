// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibB {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.storage.facetb");

    struct DiamondStorage {
        address token;
        mapping(address => uint256) balances;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

contract AllocFacet {

    function getAllocation(address _user) external view returns (uint256) {
        return LibB.diamondStorage().balances[_user] * 3;
    }

    function getToken() internal view returns(address) {
        return LibB.diamondStorage().token;
    }
}