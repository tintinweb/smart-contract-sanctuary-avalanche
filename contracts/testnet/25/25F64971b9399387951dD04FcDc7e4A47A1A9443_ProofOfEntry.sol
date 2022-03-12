//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./IERC20.sol";
import "./IProofOfEntry.sol";

/// @title Proof Of Entry Contract
/// @notice This contract handles inflation of an ERC-20 coin depending on network participation
contract ProofOfEntry is IProofOfEntry {

    uint256 private _difficulty;
    uint256 private _blockReward;
    uint256 private _inflationRate;

    uint256 constant _maxNumberBlocks = 200;

    constructor() {
        _difficulty = 10000000000000000000; // 10 LBCs
        _blockReward = 200000000000000000000; // 200 LBCs
        _inflationRate = 150000000000000000000; // 150 LBCs
    }

    function getMinimumParticipationAmount() 
    override
    public
    view
    returns(uint256) {
        return _difficulty;
    }

    function getBlockRewardAmount()
    override
    public
    view
    returns(uint256) {
        return _blockReward;
    }

    function getInflationRate()
    override
    public
    view
    returns(uint256) {
        return _inflationRate;
    }

    function getMaxNumberBlocks()
    override
    public
    pure
    returns(uint256) {
        return _maxNumberBlocks;
    }

    function calculateInflation(uint256 numberTickets)
    override
    public
    view
    returns(uint256) {
        return numberTickets * _inflationRate;
    }
    
}