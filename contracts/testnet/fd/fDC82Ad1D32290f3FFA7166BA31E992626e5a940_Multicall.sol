// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @notice A fork of Multicall2 specifically tailored for the Uniswap Interface
contract Multicall {
  struct Call {
    address target;
    uint256 gasLimit;
    bytes callData;
  }

  struct Result {
    bool success;
    uint256 gasUsed;
    bytes returnData;
  }

  function multicall(Call[] memory calls) public returns (uint256 blockNumber, Result[] memory returnData) {
    blockNumber = block.number;
    returnData = new Result[](calls.length);
    for (uint256 i = 0; i < calls.length; i++) {
      (address target, uint256 gasLimit, bytes memory callData) = (
        calls[i].target,
        calls[i].gasLimit,
        calls[i].callData
      );
      uint256 gasLeftBefore = gasleft();
      (bool success, bytes memory ret) = target.call{ gas: gasLimit }(callData);
      uint256 gasUsed = gasLeftBefore - gasleft();
      returnData[i] = Result(success, gasUsed, ret);
    }
  }

  function getEthBalance(address addr) public view returns (uint256 balance) {
    balance = addr.balance;
  }

  function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
    blockHash = blockhash(blockNumber);
  }

  function getLastBlockHash() public view returns (bytes32 blockHash) {
    blockHash = blockhash(block.number - 1);
  }

  function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
    timestamp = block.timestamp;
  }

  function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
    difficulty = block.difficulty;
  }

  function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
    gaslimit = block.gaslimit;
  }

  function getCurrentBlockCoinbase() public view returns (address coinbase) {
    coinbase = block.coinbase;
  }
}