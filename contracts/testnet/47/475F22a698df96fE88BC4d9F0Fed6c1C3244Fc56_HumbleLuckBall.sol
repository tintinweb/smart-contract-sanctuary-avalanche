//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./ICyclesManager.sol";
import "./ISafeNumberGenerator.sol";
import "./IProofOfEntry.sol";
import "./IParticipantsVault.sol";

import "./ParticipantVaultStorage.sol";

/// @title Humble Luck Ball Contract
/// @notice This is the main contract acting as a mediator between all the sub-services of the Proof of Entry
contract HumbleLuckBall is ParticipantVaultStorage, Context {
    address                 private         _admin;

    ICyclesManager          private         _cyclesManager;
    ISafeNumberGenerator    private         _rng;
    IProofOfEntry           private         _proofOfEntry;
    IParticipantsVault      private         _participantsVault;

    bytes32[]               private         _hashedSeeds;
    uint256[]               private         _seeds;
    uint256[]               private         _lbcPools;

    event CycleStarted(uint256 indexed cycleID, bytes32 hashedSeed, uint256 poolAmount);
    event CycleEnded(uint256 indexed cycleID, uint256 seed, uint256 entries, uint256 inflationAmount);
    event NewAdmin(address oldAddress, address newAddress);
    event Elected(uint256 indexed cycleID, address indexed electedAddress, uint256 ticketNumber, bool systemHold, uint256 amount);
    event Participated(uint256 indexed cycleID, address indexed participant, uint256 ticketsAllocated, bool fromVault);

    event CyclesManagerContractChanged(address oldAddress, address newAddress);
    event SafeNumberGeneratorContractChanged(address oldAddress, address newAddress);
    event ProofOfEntryContractChanged(address oldAddress, address newAddress);
    event ParticipantsVaultContractChanged(address oldAddress, address newAddress);

    constructor(ICyclesManager cyclesManager,
    ISafeNumberGenerator rng,
    IProofOfEntry proofOfEntry,
    IParticipantsVault participantsVault) {
        _cyclesManager = cyclesManager;
        _rng = rng;
        _proofOfEntry = proofOfEntry;
        _participantsVault = participantsVault;
        _admin = _msgSender();
    }

    function initDelegated()
    public
    onlyAdmin
    {
        (bool success, bytes memory data) = address(_participantsVault).delegatecall(abi.encodeWithSignature("initForDelegator(address)", _participantsVault.getPoolEscrowAddress()));

        require(success, "HumbleLuckBall: Failed to initialize delegatecall data for participantsVault");
    }

    function startCycle(bytes32 hashedSeed) public
    onlyAdmin {
        _cyclesManager.newElection();
        _hashedSeeds.push(hashedSeed);
        uint256 currentPool = _participantsVault.getPool();
        _lbcPools.push(currentPool);

        emit CycleStarted(_cyclesManager.getCurrentElectionID(), hashedSeed, currentPool);
    }

    function participate(uint256 amount) public
    {
        require(_cyclesManager.isParticipationOpen(), "HumbleLuckBall: Participations are closed");
        require(amount > 0 && amount % _proofOfEntry.getMinimumParticipationAmount() == 0, "HumbleLuckBall: Participation amount must be greater and a multiple of the minimum participation amount.");

        uint256 numberOfTickets = amount / _proofOfEntry.getMinimumParticipationAmount();
        
        bytes memory signature = abi.encodeWithSignature("burnAmountFromWallet(uint256)", amount); 

        (bool success, bytes memory data) = address(_participantsVault).delegatecall(signature);

        require(success, "HumbleLuckBall: Failed to initialize delegatecall data for participantsVault");

        _cyclesManager.addParticipant(_msgSender(), numberOfTickets);

        emit Participated(_cyclesManager.getCurrentElectionID(), _msgSender(), numberOfTickets, false);
    }

    function participateFromVault(uint256 amount) public {
        require(_cyclesManager.isParticipationOpen(), "HumbleLuckBall: Participations are closed");
        require(amount > 0 && amount % _proofOfEntry.getMinimumParticipationAmount() == 0, "HumbleLuckBall: Participation amount must be greater and a multiple of the minimum participation amount.");

        uint256 numberOfTickets = amount / _proofOfEntry.getMinimumParticipationAmount();
        
        _participantsVault.burnAmountFromBalance(_msgSender(), amount);

        _cyclesManager.addParticipant(_msgSender(), numberOfTickets);

        emit Participated(_cyclesManager.getCurrentElectionID(), _msgSender(), numberOfTickets, true);
    }

    function _generateInflation(uint256 lbcAmount) internal {
        _participantsVault.inflateFromPoe(lbcAmount);
    }

    function endCycle(uint256 seed) public
    onlyAdmin {
        require(keccak256(abi.encodePacked(seed)) == _hashedSeeds[_hashedSeeds.length - 1], "HumbleLuckBall: Seed verification failed");
    
        _seeds.push(seed);

        _cyclesManager.closeParticipations();

        uint256 nbTickets = _cyclesManager.getNumberOfTickets();

        bytes memory encodedNumberOfTickets = abi.encodePacked(nbTickets);
        bytes32 hashedNumberOfTickets = keccak256(encodedNumberOfTickets);
        seed ^= uint256(hashedNumberOfTickets);

        _rng.setSeed(seed);

        _rng.setNumberMax(uint64(nbTickets - 1));

        uint256 inflationAmount;

        if (nbTickets > 1) {
            _runElections(nbTickets);
            inflationAmount = _proofOfEntry.calculateInflation(nbTickets);
            _generateInflation(inflationAmount);
        }

        emit CycleEnded(_cyclesManager.getCurrentElectionID(), seed, nbTickets, inflationAmount);
    }

    function _runElections(uint256 nbTickets) internal {
        uint256 currentLBCPool = _lbcPools[_lbcPools.length - 1];
        uint256 blockReward = _proofOfEntry.getBlockRewardAmount();
        uint256 blocksRemaining = _proofOfEntry.getMaxNumberBlocks();
        uint256 cycleID = _cyclesManager.getCurrentElectionID();
        uint256 arrayPos = 0;
        address[] memory electedList = new address[](blocksRemaining);

        do {
            uint256 ticketNumber = _rng.safeNext();

            if (ticketNumber != 0) {
                (address elected, bool systemHold) = _cyclesManager.getElected(ticketNumber);

                emit Elected(cycleID, elected, ticketNumber, systemHold, blockReward);

                if (elected != address(0)) {
                    electedList[arrayPos] = elected;
                    arrayPos += 1;
                    nbTickets -= 1;
                }
            } 
            else {
                emit Elected(cycleID, address(0), ticketNumber, true, blockReward);
                nbTickets -= 1;
            }
            

            currentLBCPool -= blockReward;
            blocksRemaining -= 1;

            if (blockReward > currentLBCPool) {
                blockReward = currentLBCPool;
            }

        } while (currentLBCPool > 0 && nbTickets > 0 && blocksRemaining > 0);

        _participantsVault.addToUserListBalanceFromPool(electedList, arrayPos, blockReward);
    }

    function getCyclesManagerAddress()
    public
    view
    returns (address) {
        return address(_cyclesManager);
    }

    function getRngAddress()
    public
    view
    returns (address) {
        return address(_rng);
    }

    function getProofOfEntryAddress()
    public
    view
    returns (address) {
        return address(_proofOfEntry);
    }

    function getParticipantsVaultAddress()
    public
    view
    returns (address) {
        return address(_participantsVault);
    }

    function getPoolByID(uint256 id)
    public
    view
    returns(uint256) {
        require(_lbcPools.length > id, "HumbleLuckBall: Id exceeds number of pools");

        return _lbcPools[id];
    }

    function getHashedSeedByID(uint256 id)
    public
    view
    returns(bytes32) {
        require(_hashedSeeds.length > id, "HumbleLuckBall: Id exceeds number of hashed seeds");
        
        return _hashedSeeds[id];
    }

    function getSeed(uint256 id)
    public
    view
    returns(uint256) {
        require(_seeds.length > id, "HumbleLuckBall: Id exceeds number of hashed seeds");
        
        return _seeds[id];
    }

    function changeCyclesManagerAddress(address newAddr)
    public
    onlyAdmin {
        address oldAddr = address(_cyclesManager);

        _cyclesManager = ICyclesManager(newAddr);
        emit CyclesManagerContractChanged(oldAddr, address(_cyclesManager));
    }

    function changeRngAddress(address newAddr)
    public
    onlyAdmin {
        address oldAddr = address(_rng);

        _rng = ISafeNumberGenerator(newAddr);
        emit SafeNumberGeneratorContractChanged(oldAddr, address(_rng));
    }

    function changeProofOfEntryAddress(address newAddr)
    public
    onlyAdmin {
        address oldAddr = address(_proofOfEntry);

        _proofOfEntry = IProofOfEntry(newAddr);
        emit ProofOfEntryContractChanged(oldAddr, address(_proofOfEntry));
    }

    function changeParticipantsVaultAddress(address newAddr)
    public
    onlyAdmin {
        address oldAddr = address(_participantsVault);

        _participantsVault = IParticipantsVault(newAddr);
        emit ParticipantsVaultContractChanged(oldAddr, address(_participantsVault));
    }

    function transferOwnerShipToNewContract(address newAddr)
    public
    onlyAdmin {
        require(newAddr != address(this), "Humble Luck Ball: new address must be different from this contract");

        bytes memory payload = abi.encodeWithSignature("transferOwnership(address)", newAddr);
        (bool success, bytes memory returnData) = address(_cyclesManager).call(payload);

        require(success, "HumbleLuckBall: Couldn't transfer ownership for CyclesManager");

        (success, returnData) = address(_participantsVault).call(payload);

        require(success, "HumbleLuckBall: Couldn't transfer ownership for ParticipantsVault");


        (success, returnData) = address(_rng).call(payload);

        require(success, "HumbleLuckBall: Couldn't transfer ownership for RNG");
    }

    function changeAdmin(address newAdmin)
    external
    onlyAdmin {
        _admin = newAdmin;
        emit NewAdmin(_msgSender(), _admin);
    }

    modifier onlyAdmin() {
        require(_msgSender() == _admin, "HumbleLuckBall: Only admin can call this method");
        _;
    }
}