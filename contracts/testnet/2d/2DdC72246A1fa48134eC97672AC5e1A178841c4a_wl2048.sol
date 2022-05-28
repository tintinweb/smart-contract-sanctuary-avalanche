//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./FrensProtocolClient.sol";

contract wl2048 is FrensProtocolClient {

    //@var manager is the address of the smartcontract owner.
    address public manager;

    uint public targetScoreWlPoints;
    uint public targetScoreAutoWl;
    uint public targetScoreF2E;
    uint public targetScoreFreemint;

    address[] public wlPoints;
    address[] public autoWl;
    address[] public freeminter; 

    //@var rewardPool.
    uint public rewardPool;
    bool public statusPauseReward = false;
    
    //@var addr 
    address private addr;

    //@var rewardPool.
    uint private score;

    /**
    * @notice Player is a struct that contains the state data of a player.
    * @param id is the unique id of a player.
    * @param playerAddress is the wallet address of the player.
    * @param score is the score of the player requested from the game server.
    */
    struct Player {
        address playerAddress;
        uint id;
        uint score;
        bool isPlaying;
        bool isReward;
        bool isGetOracle;
        bool isPatchOracle;
        bool isWlPoints;
        bool isAutoWl;
        bool isFreeminter;
        bool isF2E;
    }

    //@var players is a mapping list of the object Player related to an address.
    mapping(address => Player) public players;

    //@var fptAddress is the address of FPT token.
    address public fptAddress;

    constructor() {
        fptAddress = address(0x590662109d8BFe37aD3d6f2b95d8F4EBA99Addcb);
        setFrensProtocolToken(fptAddress);
        setFee(0.01 ether);

        targetScoreWlPoints=200;
        targetScoreAutoWl=300;
        targetScoreF2E=400;
        targetScoreFreemint=500;

        _setManager(_msgSender());
    }

    function enter(address _addrPlayer) public {
        if(players[_addrPlayer].playerAddress == _addrPlayer){
            players[_addrPlayer].isPlaying = true;
            players[_addrPlayer].score = 0;
            players[_addrPlayer].isReward = false;
            players[_addrPlayer].isGetOracle = false;
            players[_addrPlayer].isPatchOracle = false;
        } else {
            Player memory player = Player({
                id: block.number,
                playerAddress: _addrPlayer,
                isPlaying: true,
                score: 0,
                isReward: false,
                isGetOracle: false,
                isPatchOracle: false,
                isWlPoints: false,
                isAutoWl: false,
                isFreeminter: false,
                isF2E: false
            });
            players[_addrPlayer] = player;
        }
    }

    /**
    * @notice Build the request to the game server to get the player score and set the score to the appropriate wallet on chain.
    * @param _queryId is the id of the oracle job.
    * @param _oracle is the address of the oracle.
    * @param _addressPlayer is a string of the wallet address of the player as registered in the game server.
    * @param _pathUint is the name of the score data in the json tree ex: {"score": 500}.
    * @param _pathAddress is the name of the address data in the json tree ex: {"address": "0x1479B1504e53CcB29045bB121f1E46bb5Ef2817c"}.
    */
    function requestPlayerScoreData(
        address _oracle,
        string memory _queryId,
        string memory _baseURI,
        string calldata _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress
    ) public {
        require(players[msg.sender].isPlaying, "The player must enter the Free2earn.");
        require(!players[msg.sender].isGetOracle, "The player already requested the function.");

        getUintStringRequest(
            _oracle, //FrensProtocol Oracle Address
            _queryId, // The specific jobId to retrieve Uint & String data from your API
            _baseURI, // The base url of the API to fetch
            _addressPlayer, // The user address related to the score
            _pathUint, // The API path of the uint data
            _pathAddress, // The API path of the address data
            this.achievedRequest.selector // The string signature of the achievedRequest function: achevied(bytes32,uint256,string)
        );
    }
    
    function achievedRequest(bytes32 _requestId, uint256 _score, string calldata _address) external recordAchievedRequest(_requestId)
    {
        addr = toAddress(_address);
        players[addr].score = _score;

        // @notice Set the bool isOracle to true after the oracle request.
        players[addr].isGetOracle = true;

        players[addr].isPlaying = false;
    }

    function getBalance() public returns(uint) {
        rewardPool = address(this).balance;
        return rewardPool;
    }

    function addReward() public payable {
        require(msg.value > 0.01 ether, "The minimum value must be higher than 0.01 ether");
        rewardPool = address(this).balance;
    }

    function claimReward() public {
        require(players[msg.sender].score >= targetScoreWlPoints, "Minimum score must be higher than 200.");
        if(players[msg.sender].score >= targetScoreWlPoints && players[msg.sender].score < targetScoreAutoWl && !players[msg.sender].isWlPoints){
            wlPoints.push(address(msg.sender));
            players[msg.sender].isWlPoints = true;
        } else if (players[msg.sender].score>= targetScoreAutoWl && players[msg.sender].score < targetScoreF2E && !players[msg.sender].isAutoWl) {
            autoWl.push(address(msg.sender));
            players[msg.sender].isAutoWl = true;
        } else if (players[msg.sender].score >= targetScoreF2E && players[msg.sender].score < targetScoreFreemint && !players[msg.sender].isAutoWl) {
            autoWl.push(address(msg.sender));
            if(address(this).balance>0 && !players[msg.sender].isF2E){
                payable(address(msg.sender)).transfer(0.5 ether);
                rewardPool = address(this).balance;
                players[msg.sender].isF2E = true;
            }
        } else if (players[msg.sender].score>= targetScoreFreemint) {
            if(rewardPool>0 && !players[msg.sender].isF2E){
                payable(address(msg.sender)).transfer(0.5 ether);
                rewardPool = address(this).balance;
                players[msg.sender].isF2E = true;
            }
            if (freeminter.length <= 10 && !players[msg.sender].isFreeminter) {
                freeminter.push(address(msg.sender));
                players[msg.sender].isFreeminter = true;
            }
        }
    }

    /*function claimWlPoints() public {
        require(players[msg.sender].score >= targetScoreWlPoints, "Minimum score must be higher than 200.");
        require(!players[msg.sender].isWlPoints, "Player already in the WL points array.");
        wlPoints.push(address(msg.sender));
        players[msg.sender].isWlPoints = true;
    }

    function claimWlAuto() public {
        require(players[msg.sender].score >= targetScoreAutoWl, "Minimum score must be higher than 200.");
        require(!players[msg.sender].isAutoWl, "Player already in the Auto WL array.");
        autoWl.push(address(msg.sender));
        players[msg.sender].isAutoWl = true;
    }

    function claimAvax() public {
        require(players[msg.sender].score >= targetScoreF2E, "Minimum score must be higher than 200.");
        require(!players[msg.sender].isF2E, "Player already claimed its avax rewards");
        require(address(this).balance>0, "No avax to claim.");
        payable(address(msg.sender)).transfer(0.5 ether);
        rewardPool = address(this).balance;
        players[msg.sender].isF2E = true;
    }

    function claimFreemint() public {
        require(players[msg.sender].score >= targetScoreFreemint, "Minimum score must be higher than 200.");
        require(freeminter.length <= 10, "All the freemint spots are delivered.");
        require(!players[msg.sender].isFreeminter, "Player already in the freemint spot");
        freeminter.push(address(msg.sender));
        players[msg.sender].isFreeminter = true;
    }*/

    function freeminterLength() public view returns(uint) {
        return freeminter.length;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _setManager(address _address) internal {
        manager = _address;
    }

    function setManager(address _address) public onlyManager {
        manager = _address;
    }

    function setToken(address _fpt) public onlyManager {
        fptAddress = _fpt;
        setFrensProtocolToken(fptAddress);
    }

    function setTargetScores(uint _wlPoints, uint _wlAuto, uint _f2e, uint _freemint) public onlyManager {
        targetScoreWlPoints = _wlPoints;
        targetScoreAutoWl = _wlAuto;
        targetScoreF2E = _f2e;
        targetScoreFreemint = _freemint;
    }

    function collectRewardPool() public onlyManager payable{
        rewardPool = address(this).balance;
        require(rewardPool>0, "The reward pool is empty.");
        payable(manager).transfer(rewardPool);
    }

    function pauseRewardPool() public onlyManager {
        statusPauseReward = true;
    }

    function unPauseRewardPool() public onlyManager {
        statusPauseReward = false;
    }

    /**
    * @notice OnlyManager is a modifier to limit the use of some critical functions.
    */
    modifier onlyManager {
        require(msg.sender == manager, "Only Manager can trigger the function.");
        _;
    }
}