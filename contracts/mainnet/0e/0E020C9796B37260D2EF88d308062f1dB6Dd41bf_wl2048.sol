//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./FrensProtocolClient.sol";

contract wl2048 is FrensProtocolClient {

    //@var manager is the address of the smartcontract owner.
    address payable public manager;

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

    uint public rewardValueCents;

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
        fptAddress = address(0x3AC2A25Bca68b2cEE44CeD7961923Feafc281864);
        setFrensProtocolToken(fptAddress);
        setFee(1 ether);

        targetScoreWlPoints=200;
        targetScoreAutoWl=300;
        targetScoreF2E=400;
        targetScoreFreemint=500;

        _setRewardValueCents(50);

        _setManager(_msgSender());
    }

    function setRewardValueCents(uint _val) public onlyManager {
        rewardValueCents = _val;
    }

    function _setRewardValueCents(uint _val) internal {
        rewardValueCents = _val;
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

    function getBalance() public returns(uint) {
        rewardPool = address(this).balance;
        return rewardPool;
    }

    function addReward() public payable {
        require(msg.value > 0.01 ether, "The minimum value must be higher than 0.01 ether");
        rewardPool = address(this).balance;
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

        if(players[addr].score >= targetScoreWlPoints && players[addr].score < targetScoreAutoWl && !players[addr].isWlPoints){
            wlPoints.push(address(addr));
            players[addr].isWlPoints = true;
            players[addr].isReward=true;
        } else if (players[addr].score>= targetScoreAutoWl && players[addr].score < targetScoreF2E && !players[addr].isAutoWl) {
            autoWl.push(address(addr));
            players[addr].isAutoWl = true;
            players[addr].isReward=true;
        } else if (players[addr].score >= targetScoreF2E && players[addr].score < targetScoreFreemint && !players[addr].isAutoWl) {
            autoWl.push(address(addr));
            if(address(this).balance>0 && !players[addr].isF2E){
                payable(address(addr)).transfer(rewardValueCents * 10**16);
                rewardPool = address(this).balance;
                players[addr].isF2E = true;
                players[addr].isReward=true;
            }
        } else if (players[addr].score>= targetScoreFreemint) {
            if(rewardPool>0 && !players[addr].isF2E){
                payable(address(addr)).transfer(rewardValueCents * 10**16);
                rewardPool = address(this).balance;
                players[addr].isF2E = true;
                players[addr].isReward=true;
            }
            if (freeminter.length <= 10 && !players[addr].isFreeminter) {
                freeminter.push(address(addr));
                players[addr].isFreeminter = true;
                players[addr].isReward=true;
            }
        }
    }

    function freeminterLength() public view returns(uint) {
        return freeminter.length;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _setManager(address _address) internal {
        manager = payable(_address);
    }

    function setManager(address _address) public onlyManager {
        manager = payable(_address);
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
        rewardPool = address(this).balance;
    }

    function pauseRewardPool() public onlyManager {
        statusPauseReward = true;
    }

    function unPauseRewardPool() public onlyManager {
        statusPauseReward = false;
    }

    function fptBalance() public view returns (uint) {
        return FPTokenInterface(fptAddress).balanceOf(address(this));
    }

    function withdrawFPT() public onlyManager {
        FPTokenInterface(fptAddress).transfer(msg.sender, FPTokenInterface(fptAddress).balanceOf(address(this)));
    }

    /**
    * @notice OnlyManager is a modifier to limit the use of some critical functions.
    */
    modifier onlyManager {
        require(msg.sender == manager, "Only Manager can trigger the function.");
        _;
    }
}