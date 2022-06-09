// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

/**
 * @title Storage Management library for dynamic structs based on data types
 *
 * DataStoreUtils is a storage management tool designed to create a safe and scalable
 * storage layout with the help of ids and keys.
 * Mainly focusing on upgradable contracts with multiple user types to create a
 * sustainable development environment.
 *
 * In summary, extra gas cost that would be saved with Storage packing are
 * ignored to create upgradable structs.
 *
 * IDs are the representation of a user with any given key as properties.
 * Type for ID is not mandatory, not all IDs should have an explicit type.
 * Thus there is no checks of types or keys.
 *
 * @notice distinct id and key pairs return different storage slots
 *
 */
library DataStoreUtils {
  /**
   * @notice Main Struct for reading and writing data to storage for given id+key pairs
   * @param allIdsByType optional categorization for given ID, requires direct access, type => id[]
   * @param uintData keccak(id, key) =>  returns uint256
   * @param bytesData keccak(id, key) => returns bytes
   * @param addressData keccak(id, key) =>  returns address
   * NOTE any other storage type can be expressed as bytes
   */
  struct DataStore {
    mapping(uint256 => uint256[]) allIdsByType;
    mapping(bytes32 => uint256) uintData;
    mapping(bytes32 => bytes) bytesData;
    mapping(bytes32 => address) addressData;
  }

  /**
   * **DATA GETTERS **
   **/
  function readUintForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key
  ) public view returns (uint256 data) {
    data = self.uintData[keccak256(abi.encodePacked(_id, _key))];
  }

  function readBytesForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key
  ) public view returns (bytes memory data) {
    data = self.bytesData[keccak256(abi.encodePacked(_id, _key))];
  }

  function readAddressForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key
  ) public view returns (address data) {
    data = self.addressData[keccak256(abi.encodePacked(_id, _key))];
  }

  /**
   * **DATA SETTERS **
   **/
  function writeUintForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key,
    uint256 data
  ) public {
    self.uintData[keccak256(abi.encodePacked(_id, _key))] = data;
  }

  function writeBytesForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key,
    bytes memory data
  ) public {
    self.bytesData[keccak256(abi.encodePacked(_id, _key))] = data;
  }

  function writeAddressForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key,
    address data
  ) public {
    self.addressData[keccak256(abi.encodePacked(_id, _key))] = data;
  }
}