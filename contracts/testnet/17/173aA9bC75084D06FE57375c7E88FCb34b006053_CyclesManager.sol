//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ICyclesManager.sol";
import "./AElectionManager.sol";

/// @title Cycles Manager contract
/// @notice Contract handling cycles for the PoE
contract CyclesManager is AElectionManager, ICyclesManager, Ownable {
    bool _isParticipationOpen;

    constructor(uint256 electionIDStart)
    AElectionManager(electionIDStart) {
    }

    /// @notice Opens participations and triggers a new election for the new cycle
    function newElection()
    override
    public
    participationsNotOpen
    onlyOwner
    returns(uint256) {
        openParticipations();

        return _newElection();
    }

    /// @notice Opens participations to the cycle
    function openParticipations()
    override
    public
    onlyOwner
    participationsNotOpen {
        _isParticipationOpen = true;
    }

    /// @notice Closes participations and effectively, the cycle
    function closeParticipations()
    override
    public
    onlyOwner
    participationsOpen {
        _isParticipationOpen = false;
    }

    /// @notice Adds a participant and allocates their tickets if participations are open
    /// @param participant Participant address to allocate tickets to
    /// @param tickets Number of tickets to allocate to the participant
    function    addParticipant(address participant, uint256 tickets)
    override
    public
    onlyOwner
    participationsOpen {
        _addParticipant(participant, tickets);
    }

    ///
    function    getElected(uint256 ticketNumber)
    override
    public
    onlyOwner
    participationsNotOpen
    returns(address, bool) {
        return _getElected(ticketNumber);
    }

    function isParticipationOpen()
    override
    external
    view
    returns(bool) {
        return _isParticipationOpen;
    }

    modifier participationsOpen() {
        require(_isParticipationOpen == true, "CyclesManager: Participations aren't open");
        _;
    }

    modifier participationsNotOpen() {
        require(_isParticipationOpen == false, "CyclesManager: Participations are already open");
        _;
    }
}