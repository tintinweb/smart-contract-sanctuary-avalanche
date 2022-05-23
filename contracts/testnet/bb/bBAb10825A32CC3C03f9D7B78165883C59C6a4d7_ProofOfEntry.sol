//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import "./IERC20.sol";
import "./IProofOfEntry.sol";

/// @title Proof Of Entry Contract
/// @notice This contract handles inflation of an ERC-20 coin depending on network participation
contract ProofOfEntry is IProofOfEntry {

    uint256 private _difficulty;
    uint256 private _blockReward;
    uint256 private _inflationRate;

    uint256 constant _maxNumberBlocks = 100;

    constructor() {
        _difficulty = 10000000000000000000;
        _blockReward = 200000000000000000000;
        _inflationRate = 75000000000000000000;
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
        console.log("Inflation number : %s", numberTickets * _inflationRate);
        return numberTickets * _inflationRate;
    }
    
}