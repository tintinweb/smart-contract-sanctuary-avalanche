/**
 *Submitted for verification at snowtrace.io on 2022-08-03
*/

// File: gladiator-finance-contracts/contracts/glad_core/roman_nft/IEntropy.sol


pragma solidity ^0.8.0;

interface IEntropy {
    function random(uint256 seed) external view returns (uint256);
}
// File: gladiator-finance-contracts/contracts/glad_core/roman_nft/Entropy.sol



pragma solidity =0.8.9;


contract Entropy is IEntropy {
    // TODO: update restaurant contract address
    mapping (address => bool) allowed;
    address owner;

    constructor () {
        owner = msg.sender;
    }

    function setAllowed(address _caller, bool _allowed) external {
        require(msg.sender == owner, "Only owner should call this");
        allowed[_caller] = _allowed;
    }

    function random(uint256 seed) external view returns (uint256) {
        require(allowed[msg.sender], "Must be whitelisted to call function");
        uint256 blockNumber = block.number;
        if (blockNumber < 4) blockNumber = 4;
        return uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number,
            blockhash(blockNumber - 4),
            tx.origin,
            blockhash(blockNumber - 2),
            blockhash(blockNumber - 3),
            blockhash(blockNumber - 1),
            seed,
            block.timestamp
        )));
    }
}