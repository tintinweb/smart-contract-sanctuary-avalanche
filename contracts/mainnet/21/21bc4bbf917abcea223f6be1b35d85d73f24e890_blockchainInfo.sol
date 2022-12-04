/**
 *Submitted for verification at snowtrace.io on 2022-12-03
*/

pragma solidity 0.8.17;

contract blockchainInfo {

    /*
    Source: https://docs.soliditylang.org/en/v0.8.17/units-and-global-variables.html
    */

    // blockhash(uint blockNumber) returns (bytes32): hash of the given block when blocknumber is one of the 256 most recent blocks; otherwise returns zero
    function getBlockBlockhash(uint blockNumber) external view returns (bytes32) {
        return blockhash(blockNumber);
    }

    // block.basefee (uint): current block’s base fee (EIP-3198 and EIP-1559)
    function getBlockBasefee() external view returns (uint) {
        return block.basefee;
    }

    // block.chainid (uint): current chain id
    function getBlockChainID() external view returns (uint) {
        return block.chainid;
    }

    // block.coinbase (address payable): current block miner’s address
    function getBlockCoinbase() external view returns (address) {
        return block.coinbase;
    }

    // block.difficulty (uint): current block difficulty
    function getBlockDifficulty() external view returns (uint) {
        return block.difficulty;
    }

    // block.gaslimit (uint): current block gaslimit
    function getBlockGasLimit() external view returns (uint) {
        return block.gaslimit;
    }

    // block.number (uint): current block number
    function getBlockNumber() external view returns (uint) {
        return block.number;
    }

    // block.timestamp (uint): current block timestamp as seconds since unix epoch
    function getBlockTimestamp() external view returns (uint) {
        return block.timestamp;
    }

    // gasleft() returns (uint256): remaining gas
    function getBlockGasleft() external view returns (uint) {
        return gasleft();
    }

    // msg.data (bytes calldata): complete calldata
    function getMsgData() external pure returns (bytes calldata) {
        return msg.data;
    }

    // msg.sender (address): sender of the message (current call)
    function getMsgSender() external view returns (address) {
        return msg.sender;
    }

    // msg.sig (bytes4): first four bytes of the calldata (i.e. function identifier)
    function getMsgSig() external pure returns (bytes4) {
        return msg.sig;
    }

    // msg.value (uint): number of wei sent with the message
    function getMsgValue() external payable returns (uint) {
        return msg.value;
    }

    // tx.gasprice (uint): gas price of the transaction
    function getTxGasPrice() external view returns (uint) {
        return tx.gasprice;
    }

    // tx.origin (address): sender of the transaction (full call chain)
    function getTxOrigin() external view returns (uint) {
        return tx.gasprice;
    }

}