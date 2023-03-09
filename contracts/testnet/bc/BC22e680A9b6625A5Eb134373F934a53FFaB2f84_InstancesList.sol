// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title InstancesList
 * @author Nicolas Milliard
 * @notice Allow a non voter to register voting sessions to follow them through the dApp
 * @dev Store an array of address in a mapping and handle duplication and removing
 */
contract InstancesList {
    /// @dev Store an array of contract addresses for each owner
    mapping(address => address[]) instancesList;

    /**
     * @notice Check if the address is not already registered
     * @param _contractAddress is the address of the contract to register
     */
    modifier checkAddress(address _contractAddress) {
        uint length = instancesList[msg.sender].length;

        for(uint i; i < length;) {
            require(instancesList[msg.sender][i] != _contractAddress, "0x19");
            // Safely optimize gas cost (i can't be overflow)
            unchecked { i++; }
        }
        _;
    }

    /**
     * @notice Register a contract in the array
     * @dev If a previous contract was deleted, the new contract address is store at its index
     * @param _contractAddress is the address of the contract to register
     */
    function b_A6Q(address _contractAddress) external checkAddress(_contractAddress) {
        address[] storage ownerList = instancesList[msg.sender];
        uint length = ownerList.length;
        bool shouldBeRegister;

        // If the array is not empty        
        if(length > 0) {
            for(uint i; i < length;) {
                // Check if a value has been deleted
                if(ownerList[i] == address(0)) {
                    ownerList[i] = _contractAddress;
                    shouldBeRegister = false;
                    break;
                } else {
                    shouldBeRegister = true;
                }
                // Safely optimize gas cost (i can't be overflow)
                unchecked { i++; }
            }
            // If the array does not store any address(0)
            if(shouldBeRegister == true) {
                ownerList.push(_contractAddress);
            }
        } else {
            ownerList.push(_contractAddress);
        }
        instancesList[msg.sender] = ownerList;
    }

    /**
     * Remove a contract in the array
     * @param _contractAddress  is the address of the contract to register
     */
    function removeInstance(address _contractAddress) external {
        uint length = instancesList[msg.sender].length;

        require(length > 0, "0x20");

        for(uint i; i < length;) {
            if(instancesList[msg.sender][i] == _contractAddress) {
                delete instancesList[msg.sender][i];
                break;
            }
            // Safely optimize gas cost (i can't be overflow)
            unchecked { i++; }
        }
    }

    /**
     * @notice Get the list of instances registered by the caller
     * @return An array of addresses representing the registered instances
     */
    function getInstancesList() external view returns(address[] memory) {
        return instancesList[msg.sender];
    }
}