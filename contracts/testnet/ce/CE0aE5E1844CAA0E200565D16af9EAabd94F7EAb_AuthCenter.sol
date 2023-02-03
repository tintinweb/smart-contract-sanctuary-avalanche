// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IAuthCenter.sol";

contract AuthCenter is IAuthCenter {
    
    address private owner;
    
    mapping (address => bool) private admins;
    mapping (address => bool) private clients;
    mapping (address => bool) private whiteList;
    mapping (address => bool) private contracts;

    // ----------------------------------------------------------------------
    
    constructor () { 
        owner = msg.sender;
        admins[msg.sender] = true;
        clients[msg.sender] = true;
        whiteList[msg.sender] = true;
    }

    function updateOwner(address _address) external returns (bool) {
        require(msg.sender == owner, "AuthCenter: You are not contract owner");
        owner = _address;
        emit UpdateOwner(_address);
        return true;
    }

    function addAdmin(address _address) external override returns (bool) {
        require(msg.sender == owner || admins[msg.sender], "AuthCenter: You are not admin");
        admins[_address] = true;
        emit AddAdmin(_address);
        return true;
    }

    function discardAdmin(address _address) external override returns (bool){
        require(msg.sender == owner || admins[msg.sender], "AuthCenter: You are not admin");
        delete admins[_address];
        emit DiscardAdmin(_address);
        return true;
    }

    function freezeAddress(address _address) external override returns (bool) {
        require(admins[msg.sender], "AuthCenter: You are not admin");
        delete whiteList[_address];
        emit FreezeAddress(_address);
        return true;
    }

    function unfreezeAddress(address _address) external override returns (bool) {
        require(admins[msg.sender], "AuthCenter: You are not admin");
        whiteList[_address] = true;
        emit UnFreezeAddress(_address);
        return true;
    }

    function addClient(address _address) external override returns (bool) {
        require(admins[msg.sender], "AuthCenter: You are not admin");
        clients[_address] = true;
        whiteList[_address] = true;
        emit AddClient(_address);
        return true;
    }

    function removeClient(address _address) external override returns (bool) {
        require(admins[msg.sender], "AuthCenter: You are not admin");
        delete clients[_address];
        delete whiteList[_address];
        emit RemoveClient(_address);
        return true;
    }

    function setContractPaused(address _address) external override returns (bool) {
        require(admins[msg.sender], "AuthCenter: You are not admin");
        contracts[_address] = true;
        emit ContractPausedState(_address, true);
        return true;
    }
    
    function setContractUnpaused(address _address) external override returns (bool) {
        require(admins[msg.sender], "AuthCenter: You are not admin");
        delete contracts[_address];
        emit ContractPausedState(_address, false);
        return true;
    }

    function isAddressFrozen(address _address) external view override returns (bool) {
        return !(whiteList[_address]);
    }

    function isClient(address _address) external view override returns (bool) {
        return clients[_address];
    }

    function isAdmin(address _address) external view override returns (bool) {
        return admins[_address];
    }

    function isContractPaused(address _address) external view override returns (bool) {
        return contracts[_address];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAuthCenter {
    event UpdateOwner(address indexed _address);
    event AddAdmin(address indexed _address);
    event DiscardAdmin(address indexed _address);
    event FreezeAddress(address indexed _address);
    event UnFreezeAddress(address indexed _address);
    event AddClient(address indexed _address);
    event RemoveClient(address indexed _address);
    event ContractPausedState(address indexed _address, bool _value);

    function addAdmin(address _address) external returns (bool);
    function discardAdmin(address _address) external returns (bool);
    function freezeAddress(address _address) external returns (bool);
    function unfreezeAddress(address _address) external returns (bool);
    function addClient(address _address) external returns (bool);
    function removeClient(address _address) external returns (bool);
    function isClient(address _address) external view returns (bool);
    function isAdmin(address _address) external view returns (bool);
    function isAddressFrozen(address _address) external view returns (bool);
    function setContractPaused(address _address) external returns (bool);
    function setContractUnpaused(address _address) external returns (bool);
    function isContractPaused(address _address) external view returns (bool);
}