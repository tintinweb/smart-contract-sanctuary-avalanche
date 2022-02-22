// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Address.sol';
import './FlexUSDStorage.sol';

contract FlexUSD is FlexUSDStorage {
  /**
   * Implementation Address
   */
  address private _implementation;

  /**
   * @dev Emitted when the _implementation is upgraded.
   */
  event Upgraded(address indexed implementation);

  constructor(address _logic, bytes memory _data)
    payable
  {
    _upgradeToAndCall(_logic, _data);
  }

  /**
   * @dev receive
   */
  receive() payable external {
    _delegate();
  }

  /** 
   * @dev fallback
   */
  fallback() payable external {
    _delegate();
  }

  function upgrade(address _logic, bytes memory _data)
    public payable onlyOwner
  {
    _upgradeToAndCall(_logic, _data);
  }

  /**
   * @dev Perform implementation upgrade
   *
   * Emits an {Upgraded} event.
   */
  function _upgradeTo(address _logic)
    internal
  {
    require(_logic != address(0), 'flexUSD: new implementation cannot be zero address.');
    require(Address.isContract(_logic), 'flexUSD: new implementation is not a contract.');
    require(_implementation != _logic, 'flexUSD: new implementation cannot be the same address.');
    _implementation = _logic;
    emit Upgraded(_implementation);
  }

  function _upgradeToAndCall(address _logic, bytes memory _data)
    internal
  {
    _upgradeTo(_logic);
    if (_data.length > 0) {
      Address.functionDelegateCall(_implementation, _data);
    }
  }
  
  /**
   * @dev delegate to implementation logic
   */
  function _delegate() internal {
    address target = _implementation;
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())
      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())
      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return (0, returndatasize())
      }
    }
  }
}