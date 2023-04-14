//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @author gotbit
 */

library Roles {
    bytes32 public constant MINTER = keccak256('MINTER');
    bytes32 public constant BURNER = keccak256('BURNER');
    bytes32 public constant ADMIN = keccak256('ADMIN');
}