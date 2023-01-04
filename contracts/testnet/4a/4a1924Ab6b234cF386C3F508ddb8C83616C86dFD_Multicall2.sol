/**
 *Submitted for verification at Etherscan.io on 2021-04-29
 */

/**
 *Submitted for verification at Etherscan.io on 2021-03-23
 */

pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

/// @title Multicall2 - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall2 {
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(
        Call[] calldata calls
    ) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        uint256 length = calls.length;
        returnData = new bytes[](length);
        bool success;
        for (uint256 i; i < length; ) {
            (success, returnData[i]) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            unchecked {
                ++i;
            }
        }
    }

    function blockAndAggregate(
        Call[] calldata calls
    )
        public
        returns (
            uint256 blockNumber,
            bytes32 blockHash,
            Result[] memory returnData
        )
    {
        (blockNumber, blockHash, returnData) = tryBlockAndAggregate(
            true,
            calls
        );
    }

    function getBlockHash(
        uint256 blockNumber
    ) external view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    function getBlockNumber() external view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    function getCurrentBlockCoinbase()
        external
        view
        returns (address coinbase)
    {
        coinbase = block.coinbase;
    }

    function getCurrentBlockDifficulty()
        external
        view
        returns (uint256 difficulty)
    {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit()
        external
        view
        returns (uint256 gaslimit)
    {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockTimestamp()
        external
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function getEthBalance(
        address addr
    ) external view returns (uint256 balance) {
        balance = addr.balance;
    }

    function getLastBlockHash() external view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function tryAggregate(
        bool requireSuccess,
        Call[] calldata calls
    ) public returns (Result[] memory returnData) {
        uint256 length = calls.length;
        returnData = new Result[](length);
        bool success;
        for (uint256 i; i < length; ) {
            (success, returnData[i].returnData) = calls[i].target.call(
                calls[i].callData
            );

            if (requireSuccess)
                require(success, "Multicall2 aggregate: call failed");

            returnData[i].success = success;

            unchecked {
                ++i;
            }
        }
    }

    function tryBlockAndAggregate(
        bool requireSuccess,
        Call[] calldata calls
    )
        public
        returns (
            uint256 blockNumber,
            bytes32 blockHash,
            Result[] memory returnData
        )
    {
        blockNumber = block.number;
        blockHash = blockhash(block.number);
        returnData = tryAggregate(requireSuccess, calls);
    }
}