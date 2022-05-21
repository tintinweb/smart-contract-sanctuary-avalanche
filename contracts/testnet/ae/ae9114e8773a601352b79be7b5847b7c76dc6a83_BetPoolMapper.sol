// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./BetPoolFactory.sol";
import "./Ownable.sol";

// This contract keeps track of which user is part of which betpool.
contract BetPoolMapper is Ownable {
    // Mappings
    // Mapping between user address and pool address(es)
    mapping(address => bytes32[]) private poolUserAddressMapping;

    // Address variables
    BetPoolFactory private factory;

    // constructor
    constructor() {
        factory = new BetPoolFactory();
    }

    function listPoolIdsByUser(address user)
        public
        view
        returns (bytes32[] memory)
    {
        return poolUserAddressMapping[user];
    }

    function createPoolUserMappingIfNotExists(address user, bytes32 poolId)
        external
    {
        bool poolIdExists = false;

        for (uint256 i; i < poolUserAddressMapping[user].length; i++) {
            if (poolUserAddressMapping[user][i] == poolId) {
                poolIdExists = true;
            }
        }

        if (!poolIdExists) {
            poolUserAddressMapping[user].push(poolId);
        }
    }

    function createPoolUserMapping(address user, bytes32 poolId) external {
        poolUserAddressMapping[user].push(poolId);
    }

    // Used for upgrading the contracts
    function setFactory(address _address) external onlyOwner {
        factory = BetPoolFactory(_address);
    }

    function getFactory() external view onlyOwner returns (BetPoolFactory) {
        return factory;
    }
}