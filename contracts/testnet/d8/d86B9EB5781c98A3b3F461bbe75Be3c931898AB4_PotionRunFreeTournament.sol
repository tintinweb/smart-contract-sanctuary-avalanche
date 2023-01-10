// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

// FrensProtocl
import "./FrensProtocolClient.sol";

// Potion Run Badges
import "./IPotionRunBadges.sol";

/// @title Potion Run Free Tournament (Plague Game).
/// @author Memepanze
/** @notice Free Tournament contract for Potion Run (Plague Game).
* Player Mint ERC1155 if the requested score from the server is higher than a target score.
* The request to the off-chain server is done with @ FrensProtocol Oracle.
*/

contract PotionRunFreeTournament is FrensProtocolClient, ReentrancyGuard, Ownable {
    using Strings for uint256;

    constructor() {
        setFrensProtocolToken(address(0x5E20E033d579091888b276C885eEB76cAB2a0A55));
        potionRunBadgesContract = address(0x5Fa917747C223322583D11d82F82a85A378BD94B);
    }

    /// @notice 
    address public potionRunBadgesContract;

    /**
    * @notice Player is a struct that contains the state data of a player.
    * @param id is the unique id of a player.
    * @param playerAddress is the wallet address of the player.
    * @param score is the score of the player requested from the game server.
    */
    struct Player {
        uint id;
        address playerAddress;
        bool isPlaying;
        uint score;
        bool isReward;
        bool isOracle;
    }

    //@var players is a mapping list of the object Player related to an address.
    mapping(address => Player) public players;
    
    //@var addr 
    address private addr;

    // potionBadgesContract Interface
    IPotionRunBadges potionRunBadges = IPotionRunBadges(potionRunBadgesContract);

    /// @notice Emitted on withdrawBalance() 
    event BalanceWithdraw(address to, uint amount);

    // E R R O R S

    error Chad__Unauthorized();

    error Chad__NotInTheMitingPeriod();

    error Chad__TransferFailed();

    // M O D I F I E R S
    
    /// @notice Check if the minter is an externally owned account
    modifier isEOA() {
        if (tx.origin != msg.sender) {
            revert Chad__Unauthorized();
        }
        _;
    }

    function requestPlayerScoreData(
        address _oracle,
        string memory _queryId,
        string memory _sessionType,
        string memory _sessionId,
        string memory _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress
    ) public nonReentrant isEOA {
        string memory _apiBaseUrl = "https://us-central1-plaguegame-373611.cloudfunctions.net/app/api/sessions/";
        string memory _apiUrlSessionType = concatenate(_apiBaseUrl, _sessionType, "/");
        string memory _apiUrlSessionId = concatenate(_apiUrlSessionType, _sessionId, "/");
        string memory _urlToFetch = concatenate(_apiUrlSessionId, _addressPlayer, "");
        getUintStringRequest(
            _oracle, //FrensProtocol Oracle Address
            _queryId, // The specific queryId to retrieve Uint & String data from your API
            _urlToFetch, // The base url of the API to fetch
            _pathUint, // The API path of the uint data
            _pathAddress, // The API path of the address data
            this.achievedRequest.selector // The string signature of the achievedRequest function: achevied(bytes32,uint256,string)
        );
    }

    // M I N T

    /// @notice The callback function that will be triggered by the Oracle
    /// @param _requestId.
    /// @param _score.
    /// @param _address.
    function achievedRequest(bytes32 _requestId, uint256 _score, string calldata _address) external recordAchievedRequest(_requestId)
    {
        addr = toAddress(_address);
        players[addr].score = _score;

        // @notice Set the bool isOracle to true after the oracle request.
        players[msg.sender].isOracle = true;
        if(_score == 1 ){
            potionRunBadges.mint(addr, 0);
        } else if (_score == 2) {
            potionRunBadges.mint(addr, 1);
        } else if (_score == 3) {
            potionRunBadges.mint(addr, 2);
        }
        
    }
    

    /// @notice Withdraw the contract balance to the contract owner
    /// @param _to Recipient of the withdrawal
    function withdrawBalance(address _to) external onlyOwner nonReentrant {
        uint amount = address(this).balance;
        bool sent;

        (sent, ) = _to.call{value: amount}("");
        if (!sent) {
            revert Chad__TransferFailed();
        }

        emit BalanceWithdraw(_to, amount);
    }
}