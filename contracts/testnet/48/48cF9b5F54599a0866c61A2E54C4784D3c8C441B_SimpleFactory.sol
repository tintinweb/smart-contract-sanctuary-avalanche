// SPDX-License-Identifier: UNLICENSED
// Last deployed from commit: c5c938a0524b45376dd482cd5c8fb83fa94c2fcc;
pragma solidity 0.6.6;

import "../mock/SimpleContract.sol";


/**
 * @title PoolFactory
 * @dev Contract factory allowing anyone to deploy a pool contract
 */
contract SimpleFactory {
  function deployPool() public {
    SimpleContract pool = new SimpleContract();
    emit SimpleContractDeployed(address(pool));
  }

  /**
   * @dev emitted after pool is deployed by any user
   * @param poolAddress of deployed pool
   **/
  event SimpleContractDeployed(address poolAddress);
}

// SPDX-License-Identifier: UNLICENSED
// Last deployed using commit: ;
pragma solidity ^0.6.6;

/**
 * @title SimpleContract
 * @dev A mock implementation of a SmartLoan to check if upgrade mechanism correctly update contract logic
 */
contract SimpleContract {
  function getHello() public view  returns (string memory) {
    return "Hello world";
  }
}