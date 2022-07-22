pragma solidity ^0.6.12;

import './Storage.sol';

contract Registry is Storage {

  address public logic_contract;

  function setLogicContract(address _c) public returns (bool success){
    logic_contract = _c;
    return true;
  } 

  fallback () payable external {
    address target = logic_contract;
    assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize())
        let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
        let size := returndatasize()
        returndatacopy(ptr, 0, size)
        switch result
        case 0 { revert(ptr, size) }
        case 1 { return(ptr, size) }
    }
  }
}