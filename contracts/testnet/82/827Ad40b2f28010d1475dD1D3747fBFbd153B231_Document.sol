/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Document {
  // Address of issuer contract
  address private issuer;

  // Document data
  // Data is stored as string array
  // Order and format is determined by "Document Template"
  // First item is date and second item is template id
  string[] private data;

  // A signature that is generated from
  // contract address + issuer contract address + data
  bytes private signature;

  constructor(
    address _issuer,
    string[] memory _data,
    bytes memory _signature
  ) {
    issuer = _issuer;
    data = _data;
    signature = _signature;
  }

  function info()
    external
    view
    returns (
      address,
      string[] memory,
      bytes memory
    )
  {
    return (issuer, data, signature);
  }
}