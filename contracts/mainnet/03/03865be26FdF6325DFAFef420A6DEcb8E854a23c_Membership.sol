// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.10;

contract Membership {  


  // mapping of player wallet => name of player (in bytes32, may show up as hexidecimal in javascript)
  mapping(address => bytes32) public nameOfAddress;
  mapping(bytes32 => address) public addressOfName;

  // error for when the user already has a name or when the name is already taken
  error NameAlreadyExists();

  // error for invalid names (not lowercase alphanumeric)
  error InvalidName();

  // event for tracking addresses to names
  event Registered(address indexed user, bytes32 indexed name);


  /////////////////////////////////////////////////////////////////////////////////
  //                                USER INTERFACE                               //
  /////////////////////////////////////////////////////////////////////////////////


  // assign a bytes32 username to the players wallet. Can only be called once. Names are immutable.
  function register(bytes32 name_) external {
    
    // if the player already has a name, throw an error
    if ( nameOfAddress[msg.sender] != bytes32(0) ) { revert NameAlreadyExists(); }

    // if the name is already taken, throw an error
    if ( addressOfName[name_] != address(0) ) { revert NameAlreadyExists(); }

    // throw an error if a character in the name is not 0-9 or a-z (lowercase alphanumeric)
    for(uint i = 0; i < 32; i++){
        bytes1 char = name_[i];
        if( !(char >= 0x30 && char <= 0x39) || !(char >= 0x61 && char <= 0x7A) ) { revert InvalidName(); }
    }       

        // register the player's name in the name map
    nameOfAddress[msg.sender] = name_;
    addressOfName[name_] = msg.sender;

    // name has been registered
    emit Registered(msg.sender, name_);
  }
}