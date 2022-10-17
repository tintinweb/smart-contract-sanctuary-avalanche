// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;

import "./Forwarder.sol";

contract Factory {

    address public immutable owner;
    address[] private _forwarderAddresses;
    mapping(address => uint) private _addressIndex;
    mapping(address => bool) private _addressStates;

    constructor() {
        owner = msg.sender;

        /* since _addressIndex is a uint mapping default value is 0, which would affect any 
        valid forwarder at Zero position. To avoid we need to have filler value at zero position
        */ 
        _forwarderAddresses.push(address(0));
    }
      
    modifier ownerOnly(){
        require(msg.sender == owner);
        _;
    }

    

    function createForwarder() external ownerOnly returns (address) {

        Forwarder forwarder = new Forwarder();
        _forwarderAddresses.push(address(forwarder));
        _addressIndex[address(forwarder)] = _forwarderAddresses.length - 1; 
        _addressStates[address(forwarder)] = true;
         return address(forwarder);
    }

    function getAllForwarders() public view ownerOnly returns (address[] memory)
    {
        return _forwarderAddresses;
    }

    function permanentDisableForwarder(address payable _address) external ownerOnly {

        uint index = _addressIndex[_address];
        require(index < _forwarderAddresses.length);

        address lastIndexForwarder = _forwarderAddresses[_forwarderAddresses.length-1];
        
        // replace current index with value at lastIndex and remove last entry
        _forwarderAddresses[index] = lastIndexForwarder;
        _forwarderAddresses.pop();

        _addressIndex[_address] = 0;
        _addressIndex[lastIndexForwarder] = index;

        // call the contract and disable it permanently
        Forwarder forwarder = Forwarder(_address);
        forwarder.permanentDisable();
    }

    function toggleForwarderState(address payable _address, bool status) external ownerOnly {

        _addressStates[_address] = status;

        Forwarder forwarder = Forwarder(_address);
        forwarder.toggleDepositStatus(status);
    }

}