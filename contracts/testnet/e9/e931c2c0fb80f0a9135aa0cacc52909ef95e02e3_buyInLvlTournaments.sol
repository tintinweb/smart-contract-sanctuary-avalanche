// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./FrensProtocolClient.sol";

contract buyInLvlTournaments is FrensProtocolClient {

    uint public maxPlayers;
    //uint public minPlayers;

    //@var fptAddress is the address of FPT token.
    address public fptAddress;

    constructor(address _fpt, uint _maxPlayers ) {
        fptAddress = _fpt;
        setFrensProtocolToken(address(_fpt));
        maxPlayers = _maxPlayers;

        buyInLvl["10cts"] = 0.1 ether;
        buyInLvl["20cts"] = 0.2 ether;
        buyInLvl["50cts"] = 0.5 ether;
        buyInLvl["100cts"] = 1 ether;
        buyInLvl["200cts"] = 2 ether;
        buyInLvl["500cts"] = 5 ether;

        _setManager(_msgSender());
    }

    //@var buyInLvl is a mapping of a string (_lvl) to a uint (_buyIn) 
    mapping(string => uint) public buyInLvl;

    //@function setBuyIn 
    function setBuyIn(string memory _lvl, uint _buyIn) public onlyManager{
        buyInLvl[_lvl] = _buyIn;
    }

    //@var manager is the address of the smartcontract owner.
    address payable public manager;

    //@var Session is a struct for one session
    struct Session {
        uint buyIn;
        uint nbPlayers;
        uint prizePool;
        uint fgFees;
        uint payoutPlayers;
        bool isFgFeesWithdraw;
    }

    //@var sessions is a mapping from string (_lvl) to a mapping of uint (sessionId) to the struct of the session
    mapping(string => mapping(uint => Session)) public sessions;

    //@var playerData 
    struct PlayerData {
        bool isRegistered;
        uint rank;
        bool isRewarded;
    }


    mapping (address => mapping(string => mapping(uint => PlayerData))) public sessionsPlayerData;

    uint internal aPayout;

    function getPayoutPlayers(uint _nb) internal returns(uint){
        aPayout = _nb*31/(_nb+110);
        return aPayout;
    }

    function register(uint _id, string memory _buyInLvl) external payable returns(bool) {
        require(msg.value >= buyInLvl[_buyInLvl], "To register you must pay the Buy-in price.");
        require(!sessionsPlayerData[address(msg.sender)][_buyInLvl][_id].isRegistered, "Wallet already registered for the session.");
        require(sessions[_buyInLvl][_id].nbPlayers <= maxPlayers, "Max Player for that session is reached");
        sessions[_buyInLvl][_id].nbPlayers++;
        sessions[_buyInLvl][_id].prizePool += msg.value*17/20;
        sessions[_buyInLvl][_id].fgFees += msg.value*15/100;
        sessions[_buyInLvl][_id].nbPlayers < 16 ? sessions[_buyInLvl][_id].payoutPlayers = 1 + getPayoutPlayers(sessions[_buyInLvl][_id].nbPlayers) : sessions[_buyInLvl][_id].payoutPlayers = sessions[_buyInLvl][_id].nbPlayers*31/(sessions[_buyInLvl][_id].nbPlayers+110);
        return sessionsPlayerData[address(msg.sender)][_buyInLvl][_id].isRegistered = true;
    }

    function mathGetSumOneOnKValues(uint _k) internal pure returns(uint){
        uint thesum = 0;
        for(uint i=1;i<_k+1;i++){
            thesum += 1000/i;
        }

        return thesum;
    }

    event Logreward(uint _rank, uint _payout, uint _prizepool, uint a);
    event Logrank(uint _rank);
    event Logpayout(uint a);
    event Logprizepool(uint a);
    event Logrew(uint a);
    event Logurltofetch(string _urltofetch);

    struct Paths {
        string pathUint1;
        string pathUint2;
        string pathString1;
        string pathAddress;
    }

    function requestRankingReward(
        address _oracle, //0x95E7c5C1E9BeA9849Ef950A0CBAf149E2402dE2F
        uint _id,
        string memory _queryId, //6849959db7d84ab08e55d528ad757f67
        string memory _baseUrl, //https://frensgames-d837d-default-rtdb.europe-west1.firebasedatabase.app/2048/r2e/
        string memory _buyInLvl, // 10cts
        string memory _sessionId, //10
        string memory _addressPlayer, // 0x0D10D780f885bf6A5AF8CE3120d908Ba9a31B2b6
        Paths memory _path
    ) public {

        require(!sessionsPlayerData[address(msg.sender)][_buyInLvl][_id].isRewarded, "Player already rewarded for that session!");
        require(sessionsPlayerData[address(msg.sender)][_buyInLvl][_id].isRegistered, "Player not registered for the session.");

        string memory _jsonext = ".json";
        // @notice concatenate the address of the player and the path in the json.
        string memory _urlBuyInLvl = concatenate(_baseUrl, concatenate(_buyInLvl, "/"));
        string memory _urlSession = concatenate(_urlBuyInLvl, _sessionId);
        string memory _urlPlayer = concatenate(_urlSession, "/players/");
        string memory _api = concatenate(_urlPlayer, _addressPlayer);
        string memory _urlApi = concatenate(_api, _jsonext);

        emit Logurltofetch(_urlApi);

        get2Uint2StringRequest(
            _oracle, //FrensProtocol Oracle Address
            _queryId, // The specific queryId to retrieve Uint & String data from your API
            _urlApi, // The base url of the API to fetch
            _path.pathUint1, // The API path of the uint1 data
            _path.pathUint2, // The API path of the uint2 data
            _path.pathString1, // The API path of the string1 data
            _path.pathAddress, // The API path of the address data
            this.achievedRequest.selector // The string signature of the achievedRequest function: achevied(bytes32,uint256,string)
        );
    }

    uint private ratio;
    
    function getDistributionRation(uint _rank, uint _nbPayout) internal returns(uint){
        ratio = 1000*(10000/_rank)/mathGetSumOneOnKValues(_nbPayout);
        return ratio;
    }

    //@var addr 
    address private addr;
    uint private id;
    uint private rank;
    string private buyLvl;
    uint internal amountTransfer;
    
    function achievedRequest(bytes32 _requestId, uint256 _uint1, uint256 _uint2, string calldata _string1, string calldata _address) external recordAchievedRequest(_requestId)
    {
        addr = toAddress(_address);
        id = _uint2;
        rank = _uint1;
        buyLvl = _string1;
        sessionsPlayerData[address(addr)][buyLvl][id].rank = _uint1;

        require(sessionsPlayerData[address(addr)][buyLvl][id].rank <= sessions[buyLvl][id].payoutPlayers, "Player not in the Payout rankings !");
        
        uint _payout = sessions[buyLvl][id].payoutPlayers;

        amountTransfer = sessions[buyLvl][id].prizePool*getDistributionRation(rank, _payout)/10000;

        payable(address(addr)).transfer(amountTransfer);
        sessionsPlayerData[address(addr)][buyLvl][id].isRewarded = true;
    }

    // M A N G E R   -   F U N C T I O N S

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _setManager(address _address) internal {
        manager = payable(_address);
    }

    function setManager(address _address) public onlyManager {
        manager = payable(_address);
    }

    function setMaxplayers(uint _nb) public onlyManager {
        maxPlayers = _nb;
    }

    function collectFGfees(uint _id, string memory _buyLvl) public onlyManager payable{
        require(sessions[_buyLvl][_id].fgFees>0, "The FG Fees pool is empty for this session.");
        require(!sessions[_buyLvl][_id].isFgFeesWithdraw, "The FG Fees pool already withdrawn for this session.");
        payable(manager).transfer(sessions[_buyLvl][_id].fgFees);
        sessions[_buyLvl][_id].isFgFeesWithdraw = true;
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