// SPDX-License-Identifier: MIT
// Dragon Crypto Gaming PVP Battle Contract

// ______                               
// |  _  \                              
// | | | |_ __ __ _  __ _  ___  _ __    
// | | | | '__/ _` |/ _` |/ _ \| '_ \   
// | |/ /| | | (_| | (_| | (_) | | | |  
// |___/ |_|  \__,_|\__, |\___/|_| |_|  
//                   __/ |              
//                  |___/               
//  _____                  _            
// /  __ \                | |           
// | /  \/_ __ _   _ _ __ | |_ ___      
// | |   | '__| | | | '_ \| __/ _ \     
// | \__/\ |  | |_| | |_) | || (_) |    
//  \____/_|   \__, | .__/ \__\___/     
//              __/ | |                 
//             |___/|_|                 
//  _____                 _             
// |  __ \               (_)            
// | |  \/ __ _ _ __ ___  _ _ __   __ _ 
// | | __ / _` | '_ ` _ \| | '_ \ / _` |
// | |_\ \ (_| | | | | | | | | | | (_| |
//  \____/\__,_|_| |_| |_|_|_| |_|\__, |
//                                 __/ |
//     

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract LoadPVPBattle is ReentrancyGuard, Ownable, Pausable, EIP712, IERC721Receiver {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    EnumerableSet.UintSet private activeBattles;
    EnumerableSet.UintSet private activeTournaments;
    Counters.Counter private battleCounter;
    Counters.Counter private tournamentCounter;

    /**************** CONSTANTS **********************/

    uint256 public constant WAD = 1 ether;
    uint256 public constant PRECISION = 10_000;
    uint256 public constant MAX_EQUIPMENT = 14;
    uint256 public constant MAX_TREASURY_FEE = 5_000; // 50%
    uint256 public constant MAX_PLAYER_PERCENTAGE = 3_000; // 10%
    uint256 public constant MAX_BURN_PERCENTAGE = 1_000; // 10%
    uint256 public constant MAX_WAGER = 10 ether; // 10 DCAU
    uint256 public constant MIN_WAGER = 0.01 ether; // 0.01 DCAU
    uint256 public constant MAX_TIMEOUT = 1 days;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;


    uint256 public playerPercentage = 1_000; // 10% - percentage of outside bets player receives
    uint256 public treasuryFee = 1_000; // 10%
    uint256 public burnPercentage = 500; // 5%

    address public signer;
    address public treasuryAddress;
    IERC20 public immutable dcau;
    IERC20 public immutable dcar;
    IERC721 public immutable equipment;

    enum BattleType { Wager, Equipment, Tournament }

    /**************** STRUCTS **********************/

    struct Battle {
        uint256 id; // battle id
        address player1; // address(0) if no player1 has joined
        address player2; // address(0) if no player2 has joined
        bool ready1; // true if player1 is ready
        bool ready2; // true if player2 is ready
        uint256 wager; // wager amount
        uint256 joinTime; // time for another player to join
        uint256[MAX_EQUIPMENT] equipment1; // array of equipment items from player1
        uint256[MAX_EQUIPMENT] equipment2; // array of equipment items from player2
        uint256 expiredTime; // time when the second player has joined + 10 minutes
        address winner; // address of the winner
        bool isOpen; // open for player2 to join
        bool betsOpen; // open for bets
        bool hasClaimed; // has the winner claimed the rewards
        BattleType battleType; // type of battle
    }

    struct Tournament {
        uint256 id; // tournament id
        address[] players; // array of players
        uint256 wager; // wager amount
        address winner; // address of the winner
        uint256 joinTime; // time for another player to join
        bool isOpen; // open for players to join
        bool hasClaimed; // true if already claimed
        uint256 size; // number of players
    }

    struct Bet {
        uint256 battleId; // battle id
        address bettor; // address of the bettor
        uint8 player; // 1 or 2
        uint256 wager; // wager amount in DCAR
    }

    /**************** MAPPINGS **********************/

    mapping(uint256 => Battle) public battles;
    mapping(uint256 => Tournament) public tournaments;
    mapping(uint256 => Bet[]) public battleBets;
    mapping(string => bool) public _usedNonces;

    /**************** EVENTS **********************/

    event BattleEntered(uint256 indexed battleId, address indexed player, uint256 wager, uint256[MAX_EQUIPMENT] equipmentIds, BattleType battleType);
    event BattleJoined(uint256 indexed battleId, address indexed player, uint256[MAX_EQUIPMENT] equipmentIds);
    event RewardsClaimed(uint256 indexed battleId, address indexed winner);
    event TreasuryAddressChanged(address indexed treasuryAddress);
    event TreasuryFeeChanged(uint256 indexed treasuryFee);
    event BurnPercentageChanged(uint256 indexed burnPercentage);
    event FightCanceled(uint256 indexed battleId);
    event BetPlaced(uint256 indexed battleId, address indexed bettor, uint8 player, uint256 wager);
    event SignerChanged(address indexed signer);
    event BattleStarted(uint256 indexed battleId);
    event PlayerReady(uint256 indexed battleId, address indexed player);
    event BattleRefunded(uint256 indexed battleId, address indexed player);
    event TournamentCreated(uint256 indexed tournamentId, uint256 indexed wager, uint256 tournamentSize);
    event TournamentEntered(uint256 indexed tournamentId, address indexed player);
    event TournamentRefunded(uint256 indexed tournamentId);
    event TournamentRewardsClaimed(uint256 indexed tournamentId, address indexed winner);
    event TournamentCanceled(uint256 indexed tournamentId);

    /**************** ERRORS **********************/

    error DCGPVP__AddressZero();
    error DCGPVP__TreasuryFeeTooHigh();
    error DCGPVP__BurnPercentageTooHigh();
    error DCGPVP__WagerTooHigh();
    error DCGPVP__WagerTooLow();
    error DCGPVP__EquipmentLimitExceeded();
    error DCGPVP__BattleClosed();
    error DCGPVP__InvalidBattleId();
    error DCGPVP__CannotJoinOwnBattle();
    error DCGPVP__BattleAlreadyJoined();
    error DCGPVP__BattleExpired();
    error DCGPVP__BattleAlreadyClaimed();
    error DCGPVP__InvalidSigner();
    error DCGPVP__BattleNotClosed();
    error DCGPVP__BetsClosed();
    error DCGPVP__CannotBetOnOwnBattle();
    error DCGPVP__BattleDoesNotExist();
    error DCGPVP__InvalidBetAmount();
    error DCGPVP__InvalidPlayerNumber();
    error DCGPVP__BattleAlreadyStarted();
    error DCGPVP__BothPlayersMustBeInBattle();
    error DCGPVP__WrongUser();
    error DCGPVP__BattleNotExpired();
    error DCGPVP__NoEquipmentSubmitted();
    error DCGPVP__BattleNotOpen();
    error DCGPVP__TournamentSizeWrong();
    error DCGPVP__TournamentDoesNotExist();
    error DCGPVP__TournamentNotOpen();
    error DCGPVP__TournamentExpired();
    error DCGPVP__TournamentAlreadyEntered();
    error DCGPVP__TournamentNotExpired();
    error DCGPVP__InvalidTournamentId();
    error DCGPVP__TournamentAlreadyClaimed();
    error DCGPVP__TournamentNotClosed();


    constructor(IERC20 _dcau, IERC20 _dcar, IERC721 _equipment, address _treasuryAddress, address _signer) EIP712("Load PVP Battle", "1.1.0") {
        if (address(_dcau) == address(0)) revert DCGPVP__AddressZero();
        if (address(_dcar) == address(0)) revert DCGPVP__AddressZero();
        if (address(_equipment) == address(0)) revert DCGPVP__AddressZero();
        if (_treasuryAddress == address(0)) revert DCGPVP__AddressZero();
        if (_signer == address(0)) revert DCGPVP__AddressZero();
        dcau = _dcau;
        dcar = _dcar;
        equipment = _equipment;
        treasuryAddress = _treasuryAddress;
        signer = _signer;
    }

    /*
    * @notice Set the treasury address
    * @dev only owner can call this function
    * @param _treasuryAddress The treasury address
    */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        if (_treasuryAddress == address(0)) revert DCGPVP__AddressZero();
        treasuryAddress = _treasuryAddress;
        emit TreasuryAddressChanged(_treasuryAddress);
    }

    /*
    * @notice Set the signer
    * @dev only owner can call this function
    * @param _signer The signer
    */
    function setSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) revert DCGPVP__AddressZero();
        signer = _signer;
        emit SignerChanged(_signer);
    }

    /*
    * @notice Set the treasury fee
    * @dev only owner can call this function
    * @param _treasuryFee The treasury fee
    */
    function setTreasuryFee(uint256 _treasuryFee) external onlyOwner {
        if (_treasuryFee > MAX_TREASURY_FEE) revert DCGPVP__TreasuryFeeTooHigh();
        treasuryFee = _treasuryFee;
        emit TreasuryFeeChanged(_treasuryFee);
    }

    /*
    * @notice Set the burn percentage
    * @dev only owner can call this function
    * @param _burnPercentage The burn percentage
    */
    function setBurnPercentage(uint256 _burnPercentage) external onlyOwner {
        if (_burnPercentage > MAX_BURN_PERCENTAGE) revert DCGPVP__BurnPercentageTooHigh();
        burnPercentage = _burnPercentage;
        emit BurnPercentageChanged(_burnPercentage);
    }

    /*
    * @notice Create a new tournament
    * @param _wager The wager amount
    * @param _tournamentSize The tournament size
    */
    function createTournament(uint256 _wager, uint256 _tournamentSize) external whenNotPaused nonReentrant returns (uint256 tournamentId) {
        if (_wager > MAX_WAGER) revert DCGPVP__WagerTooHigh();
        if (_wager < MIN_WAGER) revert DCGPVP__WagerTooLow();
        if (_tournamentSize != 4 && _tournamentSize != 8 && _tournamentSize != 16) revert DCGPVP__TournamentSizeWrong();

        // Create a new tournament
        tournamentId = tournamentCounter.current();

        // Create the tournament
        tournaments[tournamentId] = Tournament({
            id: tournamentId,
            players: new address[](0),
            wager: _wager,
            joinTime: block.timestamp + 1 hours,
            winner: address(0),
            isOpen: true,
            hasClaimed: false,
            size: _tournamentSize
        });

        activeTournaments.add(tournamentId);

        // Increment the tournament counter
        tournamentCounter.increment();

        emit TournamentCreated(tournamentId, _wager, _tournamentSize);
    }

    /*
    * @notice Enter a tournament
    * @param _tournamentId The tournament id
    */
    function enterTournament(uint256 _tournamentId) external whenNotPaused nonReentrant {
        Tournament storage tournament = tournaments[_tournamentId];
        if (tournament.isOpen == false) revert DCGPVP__TournamentNotOpen();
        if (tournament.joinTime < block.timestamp) revert DCGPVP__TournamentExpired();

        uint256 playersLength = tournament.players.length;

        for (uint256 i = 0; i < playersLength; i++) {
            if (tournament.players[i] == msg.sender) revert DCGPVP__TournamentAlreadyEntered();
        }

        // Add the player to the tournament
        tournament.players.push(msg.sender);

        // Check if the tournament is full
        if (playersLength + 1 == tournament.size) {
            tournament.isOpen = false;
        }

        // Transfer the wager to the contract
        dcau.safeTransferFrom(msg.sender, address(this), tournament.wager);

        emit TournamentEntered(_tournamentId, msg.sender);
    }

    /*
    * @notice Enter a battle
    * @param wager The amount of DCAU to wager
    * @param equipmentIds The ERC721 equipment item IDs
    */
    function enterBattle(uint256 wager, uint256[] calldata equipmentIds, BattleType battleType) external whenNotPaused nonReentrant returns (uint256 battleId) {
        if (wager > MAX_WAGER) revert DCGPVP__WagerTooHigh();
        if (wager < MIN_WAGER) revert DCGPVP__WagerTooLow();
        if (battleType == BattleType.Equipment && equipmentIds.length > MAX_EQUIPMENT) revert DCGPVP__EquipmentLimitExceeded();
        if (battleType == BattleType.Equipment && equipmentIds.length == 0) revert DCGPVP__NoEquipmentSubmitted();

    
        // Create a new battle
        battleId = battleCounter.current();
        uint256 joinTime = block.timestamp + 10 minutes;


        uint256 equipmentLength = equipmentIds.length;
        uint256[MAX_EQUIPMENT] memory equipmentArray;
        for (uint256 i = 0; i < equipmentLength; i++) {
            equipmentArray[i] = equipmentIds[i];
        }
        

        battles[battleId] = Battle({
            id: battleId,
            player1: msg.sender,
            player2: address(0),
            ready1: false,
            ready2: false,
            wager: wager,
            joinTime: joinTime,
            equipment1: equipmentArray,
            equipment2: [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            winner: address(0),
            expiredTime: 0,   
            isOpen: true,     // battle is open for player2 to join
            betsOpen: false,   // bets are open bool
            hasClaimed: false, // battle has been claimed by the winner
            battleType: battleType // set the battle type
        });

        activeBattles.add(battleId);

        if (battleType == BattleType.Equipment) {
            // Transfer ERC721 equipment items from user to the contract
            for (uint256 i = 0; i < equipmentLength; i++) {
                equipment.safeTransferFrom(msg.sender, address(this), equipmentIds[i]);
            }
        }

        dcau.safeTransferFrom(msg.sender, address(this), wager);

        // Increment battle counter
        battleCounter.increment();

        // Emit event for entering battle
        emit BattleEntered(battleId, msg.sender, wager, equipmentArray, battleType);
    }

    /*
    * @notice Join a battle
    * @param battleId The battle ID
    * @param equipmentIds The ERC721 equipment item IDs
    */
    function joinBattle(uint256 battleId, uint256[] calldata equipmentIds) external whenNotPaused nonReentrant {
        if (battleId > battleCounter.current()) revert DCGPVP__InvalidBattleId();
        Battle storage battle = battles[battleId];
        if (battle.player1 == msg.sender) revert DCGPVP__CannotJoinOwnBattle();
        if (battle.player2 != address(0)) revert DCGPVP__BattleAlreadyJoined();
        if (battle.expiredTime != 0) revert DCGPVP__BattleExpired();
        if (battle.isOpen == false) revert DCGPVP__BattleClosed();

        if (battle.battleType == BattleType.Equipment) {
            if (equipmentIds.length > MAX_EQUIPMENT) revert DCGPVP__EquipmentLimitExceeded();
            if (equipmentIds.length == 0) revert DCGPVP__NoEquipmentSubmitted();
        }

        // Update battle information
        battle.player2 = msg.sender;
        battle.expiredTime = block.timestamp + 10 minutes;
        battle.betsOpen = true;

        uint256[MAX_EQUIPMENT] memory equipmentArray;

        if (battle.battleType == BattleType.Equipment) {
            uint256 equipmentLength = equipmentIds.length;
            for (uint256 i = 0; i < equipmentLength; i++) {
                equipmentArray[i] = equipmentIds[i];
                equipment.safeTransferFrom(msg.sender, address(this), equipmentIds[i]);
            }
            battle.equipment2 = equipmentArray;
        }

        dcau.safeTransferFrom(msg.sender, address(this), battle.wager);

        emit BattleJoined(battleId, msg.sender, equipmentArray);
    }


    /*
    * @notice Claim rewards for a battle
    * @param _battleId The battle ID
    * @param _signature The signature of the claim transaction
    * @param _nonce The nonce of the claim transaction
    */  
    function claimRewards(uint256 _battleId, bytes memory _signature, string memory _nonce) external nonReentrant whenNotPaused {
        require(
            matchAddresSigner(
                hashClaimRewardsTransaction(
                    msg.sender,
                    _battleId,
                    _nonce
                ),
                _signature
            ),
            "DIRECT_CLAIM_DISALLOWED"
        );

        if (_battleId > battleCounter.current()) revert DCGPVP__InvalidBattleId();
        Battle storage battle = battles[_battleId];
        if (battle.isOpen == true) revert DCGPVP__BattleNotClosed();
        if (battle.hasClaimed == true) revert DCGPVP__BattleAlreadyClaimed();
        if (battle.expiredTime == 0) revert DCGPVP__BattleExpired();

        _usedNonces[_nonce] = true;

        uint8 winningPlayer = battle.player1 == msg.sender ? 1 : 2;

        // Mark battle as claimed
        battle.hasClaimed = true;
        battle.winner = msg.sender;

        // Remove battle from active battles
        activeBattles.remove(_battleId);

        // Calculate fees and winnings
        uint256 totalWager = battle.wager * 2;
        uint256 treasuryFeeAmount = totalWager * treasuryFee / PRECISION;
        uint256 burnAmount = totalWager * burnPercentage / PRECISION;

        if (battle.battleType == BattleType.Equipment) {
            // Transfer ERC721 equipment items from contract to winner
            for (uint256 i = 0; i < MAX_EQUIPMENT; i++) {
                if (battle.equipment1[i] != 0) {
                    equipment.safeTransferFrom(address(this), msg.sender, battle.equipment1[i]);
                }
                if (battle.equipment2[i] != 0) {
                    equipment.safeTransferFrom(address(this), msg.sender, battle.equipment2[i]);
                }
            }
        }

         // Distribute winnings to outside bettors
        distributeWinnings(_battleId, winningPlayer);

        // Transfer amounts to treasury, burn and winner
        dcau.safeTransfer(treasuryAddress, treasuryFeeAmount);
        dcau.safeTransfer(BURN_ADDRESS, burnAmount);
        dcau.safeTransfer(msg.sender, totalWager - treasuryFeeAmount - burnAmount);

        // Emit event for claiming rewards
        emit RewardsClaimed(_battleId, msg.sender);
    }

    /*
    * @notice Distribute winnings to tournament winner
    * @param _tournamentId The tournament ID
    * @param _signature The signature of the claim transaction
    * @param _nonce The nonce of the claim transaction
    */
    function claimTournamentRewards(uint256 _tournamentId, bytes memory _signature, string memory _nonce) external nonReentrant whenNotPaused {
        require(
            matchAddresSigner(
                hashTournamentRewardsTransaction(
                    msg.sender,
                    _tournamentId,
                    _nonce
                ),
                _signature
            ),
            "DIRECT_CLAIM_DISALLOWED"
        );

        if (_tournamentId > battleCounter.current()) revert DCGPVP__InvalidTournamentId();
        Tournament storage tournament = tournaments[_tournamentId];
        if (tournament.isOpen == true) revert DCGPVP__TournamentNotClosed();
        if (tournament.hasClaimed == true) revert DCGPVP__TournamentAlreadyClaimed();

        _usedNonces[_nonce] = true;

        // Mark tournament as claimed
        tournament.hasClaimed = true;
        tournament.winner = msg.sender;

        // Remove battle from active battles
        activeTournaments.remove(_tournamentId);

        // Calculate payouts
        uint256 totalWager = tournament.wager * tournament.size;
        uint256 treasuryFeeAmount = totalWager * treasuryFee / PRECISION;
        uint256 burnAmount = totalWager * burnPercentage / PRECISION;

        // Transfer amounts to correct addresses
        dcau.safeTransfer(treasuryAddress, treasuryFeeAmount);
        dcau.safeTransfer(BURN_ADDRESS, burnAmount);
        dcau.safeTransfer(msg.sender, totalWager - treasuryFeeAmount - burnAmount);

        // Emit event for claiming rewards
        emit TournamentRewardsClaimed(_tournamentId, msg.sender);
    }

    /*
    * @notice Refund a battle if it has expired
    * @param battleId The battle ID
    */
    function refundExpiredBattle(uint256 _battleId) external nonReentrant {
        Battle storage battle = battles[_battleId];

        if (battle.joinTime > block.timestamp && battle.player2 != address(0)) revert DCGPVP__BattleNotExpired();
        if (battle.isOpen == false) revert DCGPVP__BattleNotOpen();

        // Mark the battle as closed
        battle.isOpen = false;
        battle.betsOpen = false;
        activeBattles.remove(_battleId);

        if (battle.battleType == BattleType.Equipment) {
            // Refund equipment items to player1
            uint256 equipmentLength = battle.equipment1.length;
            for (uint256 i = 0; i < equipmentLength; i++) {
                if (battle.equipment1[i] != 0) {
                    equipment.safeTransferFrom(address(this), battle.player1, battle.equipment1[i]);
                }
            }
        }

        // Refund DCAU tokens to player1
        dcau.safeTransfer(battle.player1, battle.wager);

        emit BattleRefunded(_battleId, battle.player1);
    }

    /*
    * @notice Refund a tournament if it's expired
    * @param _tournamentId The tournament ID
    */
    function refundExpiredTournament(uint256 _tournamentId) external nonReentrant {
        Tournament storage tournament = tournaments[_tournamentId];
        uint256 playerLength = tournament.players.length;

        if (tournament.joinTime > block.timestamp && playerLength < tournament.size) revert DCGPVP__TournamentNotExpired();
        if (tournament.isOpen == false) revert DCGPVP__TournamentNotOpen();

        // Mark the battle as closed
        tournament.isOpen = false;
        activeTournaments.remove(_tournamentId);

        if (playerLength > 0) {
            for (uint256 i = 0; i < playerLength; i++) {
                if (tournament.players[i] != address(0)) {
                    dcau.safeTransfer( tournament.players[i], tournament.wager);
                }
            }
        }

        emit TournamentRefunded(_tournamentId);
    }


    /*
    * @notice Cancel a battle
    * @dev Only the owner can cancel a battle
    * @param battleId The battle ID
    */
    function cancelFight(uint256 _battleId) external nonReentrant onlyOwner {
        if (_battleId > battleCounter.current()) revert DCGPVP__InvalidBattleId();
        Battle storage battle = battles[_battleId];
        if (battle.hasClaimed == true) revert DCGPVP__BattleAlreadyClaimed();

        // Mark battle as closed
        battle.isOpen = false;
        battle.hasClaimed = true;

        // Remove battle from activeBattles set
        activeBattles.remove(_battleId);

        if (battle.battleType == BattleType.Equipment) {
            // Refund ERC721 gear items
            for (uint256 i = 0; i < MAX_EQUIPMENT; i++) {
                if (battle.equipment1[i] != 0) {
                    equipment.safeTransferFrom(address(this), battle.player1, battle.equipment1[i]);
                }
                if (battle.equipment2[i] != 0) {
                    equipment.safeTransferFrom(address(this), battle.player2, battle.equipment2[i]);
                }
            }
        }

        Bet[] storage bets = battleBets[_battleId];
        for (uint256 i = 0; i < bets.length; i++) {
            dcar.safeTransfer(bets[i].bettor, bets[i].wager);
        }

        // Refund DCAU tokens
        dcau.safeTransfer(battle.player1, battle.wager);
        dcau.safeTransfer(battle.player2, battle.wager);

        // Emit event for canceling fight
        emit FightCanceled(_battleId);
    }

    /*
    * @notice Cancel a tournament
    * @dev Only the owner can cancel a tournament
    * @param _tournamentId The tournament ID
    */
    function cancelTournament(uint256 _tournamentId) external nonReentrant onlyOwner {
        if (_tournamentId > tournamentCounter.current()) revert DCGPVP__InvalidTournamentId();
        Tournament storage tournament = tournaments[_tournamentId];
        if (tournament.hasClaimed == true) revert DCGPVP__TournamentAlreadyClaimed();

        // Mark tournament as closed
        tournament.isOpen = false;
        tournament.hasClaimed = true;

        // Remove battle from activeBattles set
        activeTournaments.remove(_tournamentId);

        uint256 playerLength = tournament.players.length;

        if (playerLength > 0) {
            for (uint256 i = 0; i < playerLength; i++) {
                if (tournament.players[i] != address(0)) {
                    dcau.safeTransfer( tournament.players[i], tournament.wager);
                }
            }
        }

        // Emit event for canceling tournament
        emit TournamentCanceled(_tournamentId);
    }

    /*
    * @notice Start a battle
    * @param _battleId The battle ID
    */
    function startBattle(uint256 _battleId) external {
        Battle storage battle = battles[_battleId];
        if (battle.player1 == address(0) || battle.player2 == address(0)) revert DCGPVP__BothPlayersMustBeInBattle();
        if (battle.isOpen == false) revert DCGPVP__BattleAlreadyStarted();
        if (msg.sender != battle.player1 && msg.sender != battle.player2) revert DCGPVP__WrongUser();

        if (msg.sender == battle.player1) {
            battle.ready1 = true;
        } else {
            battle.ready2 = true;
        }

        // Check if both players are ready
        if (battle.ready1 && battle.ready2) {
            battle.isOpen = false;
            battle.betsOpen = false;
            battle.expiredTime = block.timestamp;
            emit BattleStarted(_battleId);
        } else {
            emit PlayerReady(_battleId, msg.sender);
        }
    }

    /*
    * @notice Place a bet on a battle
    * @dev whenNotPaused modifier prevents bets from being placed while the contract is paused
    * @param _battleId The battle ID
    * @param _player The player to bet on 1 or 2
    * @param _wager The amount of DCAR tokens to wager
    */
    function placeBet(uint256 _battleId, uint8 _player, uint256 _wager) external nonReentrant whenNotPaused {
        if (battles[_battleId].expiredTime < block.timestamp) revert DCGPVP__BattleAlreadyStarted();
        if (battles[_battleId].betsOpen == false) revert DCGPVP__BetsClosed();
        if (battles[_battleId].player1 == msg.sender) revert DCGPVP__CannotBetOnOwnBattle();
        if (battles[_battleId].player2 == msg.sender) revert DCGPVP__CannotBetOnOwnBattle();
        if (battles[_battleId].player1 == address(0)) revert DCGPVP__BattleDoesNotExist();
        if (_wager == 0) revert DCGPVP__InvalidBetAmount();
        if (_player != 1 && _player != 2) revert DCGPVP__InvalidPlayerNumber();

        Bet memory newBet = Bet({
            battleId: _battleId,
            bettor: msg.sender,
            wager: _wager,
            player: _player
        });

        battleBets[_battleId].push(newBet);

        // Transfer tokens to the contract
        dcar.safeTransferFrom(msg.sender, address(this), _wager);

        emit BetPlaced(_battleId, msg.sender, _player, _wager);
    }

    /*
    * @notice Get the number of bets for a battle
    * @param _battleId The battle ID
    */
    function getBetLength(uint256 _battleId) public view returns (uint256) {
        return battleBets[_battleId].length;
    }

    /*
    * @notice Get all bets for a battle
    * @param _battleId The battle ID
    */
    function getBattleBets(uint256 _battleId) public view returns (Bet[] memory) {
        return battleBets[_battleId];
    }

    /*
    * @notice Get a specific bet
    * @param _battleId The battle ID
    * @param _betIndex The bet index
    */
    function getSpecificBet(uint256 _battleId, uint256 _betIndex) public view returns (Bet memory) {
        return battleBets[_battleId][_betIndex];
    }

    /*
    * @notice Get the equipment for player 1
    * @param battleId The battle ID
    */
    function getBattleEquipment1(uint256 _battleId) public view returns (uint256[MAX_EQUIPMENT] memory) {
        return battles[_battleId].equipment1;
    }

    /*
    * @notice Get the equipment for player 2
    * @param battleId The battle ID
    */
    function getBattleEquipment2(uint256 _battleId) public view returns (uint256[MAX_EQUIPMENT] memory) {
        return battles[_battleId].equipment2;
    }

    /*
    * @notice Get the players for a tournament
    * @param tournamentId The tournament ID
    */
    function getTournamentPlayers(uint256 _tournamentId) public view returns (address[] memory) {
        return tournaments[_tournamentId].players;
    }

    /*
    * @notice Distribute winnings to outside bettors
    * @param _battleId The battle ID
    * @param _winningPlayer The winning player 1 or 2
    */
    function distributeWinnings(uint256 _battleId, uint8 _winningPlayer) private {
        Battle storage battle = battles[_battleId];
        address playerAddress = _winningPlayer == 1 ? battle.player1 : battle.player2;

        (uint256 winningBetsTotal, uint256 losingBetsTotal, uint8 numOfPlayersWithBets) = calculateTotals(_battleId, _winningPlayer);

        if (numOfPlayersWithBets < 2) {
            refundBets(_battleId);
        } else if (winningBetsTotal > 0) {
            distributeWinningBets(_battleId, _winningPlayer, winningBetsTotal, losingBetsTotal, playerAddress);
        }
    }

    /*
    * @notice Calculate total for winning player
    * @param _battleId The battle ID
    * @param _winningPlayer The winning player 1 or 2
    */
    function calculateTotals(uint256 _battleId, uint8 _winningPlayer) private view returns(uint256 winningBetsTotal, uint256 losingBetsTotal, uint8 numOfPlayersWithBets) {
        Bet[] storage bets = battleBets[_battleId];
        bool[2] memory playersWithBets = [false, false];

        for (uint256 i = 0; i < bets.length; i++) {
            if (bets[i].player == _winningPlayer) {
                winningBetsTotal += bets[i].wager;
            } else {
                losingBetsTotal += bets[i].wager;
            }

            if (!playersWithBets[bets[i].player - 1]) {
                playersWithBets[bets[i].player - 1] = true;
                numOfPlayersWithBets++;
            }
        }
    }

    /*
    * @notice Refund all bets
    * @dev This function is called by distributeWinnings
    * @param _battleId The battle ID
    */
    function refundBets(uint256 _battleId) private {
        Bet[] storage bets = battleBets[_battleId];

        for (uint256 i = 0; i < bets.length; i++) {
            dcar.safeTransfer(bets[i].bettor, bets[i].wager);
        }
    }

    /*
    * @notice Distribute winning bets
    * @dev This function is called by distributeWinnings
    * @param _battleId The battle ID
    * @param _winningPlayer The winning player 1 or 2
    * @param winningBetsTotal The total amount of bets on the winning player
    * @param losingBetsTotal The total amount of bets on the losing player
    * @param playerAddress The address of the winning player
    */
    function distributeWinningBets(uint256 _battleId, uint8 _winningPlayer, uint256 winningBetsTotal, uint256 losingBetsTotal, address playerAddress) private {
        Bet[] storage bets = battleBets[_battleId];

        uint256 playerAmount = 0;
        uint256 treasuryAmount = 0;
        uint256 burnAmount = 0;
        uint256 betsLength = bets.length;

        for (uint256 i = 0; i < betsLength; i++) {
            if (bets[i].player == _winningPlayer) {
                uint256 initialBet = bets[i].wager;
                uint256 winnings = (bets[i].wager * losingBetsTotal) / winningBetsTotal;
                uint256 fee = winnings * treasuryFee / PRECISION;
                uint256 burn = winnings * burnPercentage / PRECISION;
                uint256 player = winnings * playerPercentage / PRECISION;
                playerAmount += player;
                treasuryAmount += fee;
                burnAmount += burn;
                uint256 payout = initialBet + winnings - fee - burn - player;
                dcar.safeTransfer(bets[i].bettor, payout);
            }
        }

        transferPayouts(treasuryAmount, burnAmount, playerAmount, playerAddress);
    }

    /*
    * @notice Transfer the payouts
    * @dev internal called by distributeWinningBets
    * @param treasuryAmount The amount to send to the treasury
    * @param burnAmount The amount to burn
    * @param playerAmount The amount to send to the player
    * @param playerAddress The address of the player
    */
    function transferPayouts(uint256 treasuryAmount, uint256 burnAmount, uint256 playerAmount, address playerAddress) private {
        if (treasuryAmount > 0) {
            dcar.safeTransfer(treasuryAddress, treasuryAmount);
        }

        if (burnAmount > 0) {
            dcar.safeTransfer(BURN_ADDRESS, burnAmount);
        }

        if (playerAmount > 0) {
            dcar.safeTransfer(playerAddress, playerAmount);
        }
    }

    /*
    * @notice Match address signer
    * @dev internal called by claimRewards
    * @param hash The hash of the transaction
    * @param signature The signature of the transaction
    */
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
        if (signer == address(0)) revert DCGPVP__InvalidSigner();
        return signer == hash.recover(signature);
    }

    /*
    * @notice Hash claim rewards transaction
    * @dev internal called by claimRewards
    * @param sender The sender address
    * @param battleId The battle ID
    * @param nonce The nonce of the claim transaction
    */
    function hashClaimRewardsTransaction(address sender, uint256 battleId, string memory nonce) private view returns (bytes32) {
        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "ClaimBattleRewards(address sender,uint256 battleId,string nonce)"
                    ),
                    sender,
                    battleId,
                    keccak256(bytes(nonce))
                )
            )
        );

        return hash;
    }

    /*
    * @notice Hash tournament rewards transaction
    * @dev internal called by claimTournamentRewards
    * @param sender The sender address
    * @param tournamentId The tournament ID
    * @param nonce The nonce of the claim transaction
    */
    function hashTournamentRewardsTransaction(address sender, uint256 tournamentId, string memory nonce) private view returns (bytes32) {
        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "ClaimTournamentRewards(address sender,uint256 tournamentId,string nonce)"
                    ),
                    sender,
                    tournamentId,
                    keccak256(bytes(nonce))
                )
            )
        );

        return hash;
    }

    function onERC721Received(address, address, uint256, bytes calldata) public override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}