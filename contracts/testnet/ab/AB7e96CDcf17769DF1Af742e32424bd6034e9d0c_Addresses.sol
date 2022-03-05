/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Addresses {
    address[] contracts;
    mapping(address => bool) verified;

    modifier exists(address contractAddr) {
        require(existingContract(contractAddr), "The contract does not exist");
        _;
    }

    modifier doesNotExist(address contractAddr) {
        require(!existingContract(contractAddr), "The contract already exists");
        _;
    }

    function existingContract(address contractAddr) public view returns (bool) {
        uint256 i;
        uint256 length = contracts.length;
        for (i = 0; i < length; ++i) {
            if (contracts[i] == contractAddr) {
                return true;
            }
        }
        return false;
    }

    function addContract(address contractAddr)
        external
        doesNotExist(contractAddr)
    {
        contracts.push(contractAddr);
    }

    function removeContract(address contractAddr)
        external
        exists(contractAddr)
    {
        uint256 i;
        uint256 length = contracts.length;
        for (i = 0; i < length; ++i) {
            if (contracts[i] == contractAddr) {
                break;
            }
        }
        require(i < length, "Not Found the Contract");
        contracts[i] = contracts[length - 1];
        contracts.pop();
        verified[contractAddr] = false;
    }

    function verify(address contractAddr) external exists(contractAddr) {
        require(
            verified[contractAddr] == false,
            "The contract is already verified"
        );
        verified[contractAddr] = true;
    }

    function getContracts() external view returns (address[] memory) {
        return contracts;
    }
}