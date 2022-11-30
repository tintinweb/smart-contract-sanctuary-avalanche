// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Whitelist {
    mapping(address => bool) public isWhitelisted;

    ///@notice bool to make sure contract is initialized only once
    bool private initialized;

    // constructor(address[] memory _whitelistAddresses) {
    //     for (uint256 i; i < _whitelistAddresses.length; i++) {
    //         zeroAddressCheck(_whitelistAddresses[i]);
    //         isWhitelisted[_whitelistAddresses[i]] = true;
    //     }
    // }

    /// @notice constructor to initialize
    /// @param _whitelistAddresses addressed to be whitelisted to receive tokens/ethers
    function initWhitelist(address[] memory _whitelistAddresses) external {
        require(!initialized, "Contract already initialized");
        initialized = true;
        for (uint256 i; i < _whitelistAddresses.length; i++) {
            zeroAddressCheck(_whitelistAddresses[i]);
            isWhitelisted[_whitelistAddresses[i]] = true;
        }
    }

    // TODO : add access control
    function addToWhitelist(address _newWallet) external {
        require(!isWhitelisted[_newWallet], "Already whitelisted");
        isWhitelisted[_newWallet] = true;
    }

    // TODO : add access control
    function removeFromWhitelist(address _addressToRemove) external {
        require(isWhitelisted[_addressToRemove], "Not whitelisted");
        isWhitelisted[_addressToRemove] = false;
    }

    function zeroAddressCheck(address _addr) internal pure {
        require(_addr != address(0x00), "Zero address not allowed");
    }
}