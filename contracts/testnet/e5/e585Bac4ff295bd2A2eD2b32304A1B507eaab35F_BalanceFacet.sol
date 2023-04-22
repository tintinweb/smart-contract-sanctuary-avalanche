// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibB {

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.storage.facetb");

    struct DiamondStorage {
        address token;
        uint256 allocationPerNft;
        mapping(address => uint256) withdrawn;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

contract BalanceFacet {
    function setToken(address _token) external {
        LibB.DiamondStorage storage ds = LibB.diamondStorage();
        ds.token = _token;
    }

    function setAllocationPerNft(uint256 _allocationPerNft) external {
        LibB.DiamondStorage storage ds = LibB.diamondStorage();
        ds.allocationPerNft = _allocationPerNft;
    }

    function getWithdrawn(address _user) external view returns (uint256) {
        return LibB.diamondStorage().withdrawn[_user];
    }
}