//SPDX-License-Identifier:MIT
pragma solidity ^0.8.11;

import "./FrensProtocolClient.sol";

contract FrensGames2048Free2Earn is FrensProtocolClient {
    constructor() {
        fptAddress = address(0x590662109d8BFe37aD3d6f2b95d8F4EBA99Addcb);
        setFrensProtocolToken(fptAddress);
        setFee(0.01 ether);

        /**
        * @notice set the manager to the address that deployed the smartcontract.
        */
        _setManager(_msgSender());
    }

    //@var fptAddress is the address of FPT token.
    address public fptAddress;

    //@var scoreMapReqToScore for each Request ID we map a score of type uint.
    mapping(uint => uint) public scoreMapReqToScore;

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
        bool isGetOracle;
        bool isPatchOracle;
    }

    //@var players is a mapping list of the object Player related to an address.
    mapping(address => Player) public players;

    //@var manager is the address of the smartcontract owner.
    address public manager;

    //@var scoreTarget is the minimum score to achieve to be rewarded.
    uint public scoreTarget = 200;

    //@var rewardPool.
    uint public rewardPool;
    bool public statusPauseReward = false;
    
    //@var addr 
    address private addr;

    //@var rewardPool.
    uint private score;

    
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
        address addrPlayer = toAddress(_addressPlayer);
        require(players[addrPlayer].isPlaying, "The player must enter the Free2earn.");
        require(!players[addrPlayer].isGetOracle, "The player already requested the function.");

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
        scoreMapReqToScore[uint(_requestId)] = _score;
        players[addr].score = _score;

        // @notice Set the bool isOracle to true after the oracle request.
        players[addr].isGetOracle = true;

        players[addr].isPlaying = false;
    }

    function reward(
        address _oracle,
        string memory _queryId,
        string memory _baseURI,
        string calldata _addressPlayer,
        string memory _pathUint,
        string memory _pathAddress 
    ) public {
        address addrPlayer = toAddress(_addressPlayer);
        require(players[addrPlayer].isPlaying, "The player must enter the Free2earn.");
        require(rewardPool > 0.099 ether, "The reward pool is empty.");
        require(players[addrPlayer].score>=scoreTarget, "The player score is under the target score.");
        require(statusPauseReward==false, "The Free2Earn is paused by the manager");

        patchUintRequest(
            _oracle, //FrensProtocol Oracle Address
            _queryId, // The specific jobId to retrieve Uint & String data from your API
            _baseURI, // The base url of the API to fetch
            _addressPlayer, // The user address related to the score
            _pathUint, // The API path of the uint data
            _pathAddress, // The API path of the address data
            this.patchFulfill.selector // The string signature of the achievedRequest function: achevied(bytes32,uint256,string)
        );
    }

    function patchFulfill(bytes32 _requestId, uint256 _score, string calldata _address) external recordAchievedRequest(_requestId) {
        address addrPlayer = toAddress(_address);
        rewardPool = address(this).balance;
        score = _score;
        payable(addrPlayer).transfer(0.1 ether);
        players[addrPlayer].isReward = true;
        players[addrPlayer].isPlaying = false;
    }


    function enter() public {
        if(players[msg.sender].playerAddress == msg.sender){
            players[msg.sender].isPlaying = true;
            players[msg.sender].score = 0;
            players[msg.sender].isReward = false;
            players[msg.sender].isGetOracle = false;
        } else {
            Player memory player = Player({
                id: block.number,
                playerAddress: msg.sender,
                isPlaying: true,
                score: 0,
                isReward: false,
                isGetOracle: false,
                isPatchOracle: false
            });
            players[msg.sender] = player;
        }
    }

    //admin
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

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function getStatusPauseReward() public view returns(bool){
        return statusPauseReward;
    }

    function getRewardPool() public view returns(uint){
        return address(this).balance;
    }

    function getScoreTarget() public view returns(uint){
        return scoreTarget;
    }

    function getPlayerScore() public view returns(uint){
        return players[msg.sender].score;
    }

    function setScoreTarget(uint _scoreTarget) public onlyManager {
        scoreTarget = _scoreTarget;
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

    function addReward() public payable {
        require(msg.value > 0.01 ether, "The minimum value must be higher than 0.01 ether");
        rewardPool = address(this).balance;
    }

    /**
    * @notice OnlyManager is a modifier to limit the use of some critical functions.
    */
    modifier onlyManager {
        require(msg.sender == manager, "Only Manager can trigger the function.");
        _;
    }
}