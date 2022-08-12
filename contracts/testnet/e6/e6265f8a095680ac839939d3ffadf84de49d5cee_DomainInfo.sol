/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-11
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

contract DomainInfo {
    event UpdateDomainInfo(address indexed owner, string indexed domainName, uint8 domainType, string module);
    event UpdateDomainModule(address indexed owner, string indexed domainName, string module);

    mapping(address => mapping(string => string)) public domainModule; // domainModule[owner][domainName] = module IPFS CID
    mapping(address => mapping(string => uint8)) public domainType; // domainType[owner][domainName] = domain type

    function updateDomainInfo(string calldata domainName, uint8 moduleType, string calldata module) external {
        domainModule[msg.sender][domainName] = module;
        domainType[msg.sender][domainName] = moduleType;
        emit UpdateDomainInfo(msg.sender, domainName, moduleType, module);
    }
    function updateDomainModule(string calldata domainName, string calldata module) external {
        domainModule[msg.sender][domainName] = module;        
        emit UpdateDomainModule(msg.sender, domainName, module);
    }
    function getDomainInfo(address owner, string calldata domainName) external view returns (uint8 moduleType, string memory module) {
        moduleType = domainType[owner][domainName];
        module = domainModule[owner][domainName];
    }
}