/**
 *Submitted for verification at snowtrace.io on 2023-03-23
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: utils/Context.sol


// Ezido Contract
pragma solidity ^0.8.10;

abstract contract Context {
    string private FAILED_AREDIFFERENT = "Aborted, sender and recipient are the same address.";
    string private FAILED_ISZEROADDRESS = "Aborted, sender or recipient is zero address.";
    string private FAILED_ISNOTZERO = "Aborted, amount is lower than 0.";
    string private FAILED_ISBIGGERINT = "Aborted, amount is too big.";

    modifier __validAddress(
        address _address
    ) {
        require(
            _address != _zeroAddress(),
            FAILED_ISZEROADDRESS
        );
        _;
    }

    modifier __differentAddress(
        address _sender,
        address _recipient
    ) {
        require(
            _sender != _recipient,
            FAILED_AREDIFFERENT
        );
        _;
    }

    modifier __validAmount(
        uint256 _amount
    ) {
        require(
             _amount >= 0,
             FAILED_ISNOTZERO
        );
        require(
            _amount != type(uint256).max,
            FAILED_ISBIGGERINT
        );
        _;
    }

    function _msgSender() internal view
        __validAddress(msg.sender)
    returns (
        address payable
    ) {
        return payable(msg.sender);
    }

    function _zeroAddress() internal pure
    returns(
        address
    ) {
        return address(0);
    }

    function _msgData() internal pure
    returns (
        bytes calldata
        ) {
        return msg.data;
    }

    function _msgValue() internal view
    returns (
        uint256
    ) {
        return msg.value;
    }
}
// File: bot.sol


// Template Contract
pragma solidity ^0.8.10;



contract Membership is Context {
    address private _owner;
    address private _bank;

    uint256 private _interests = 300;
    uint256 private _percent = 10000;

    uint32 private subscriptionsID = 1;
    uint32 private membersID = 1;
    uint32 private plansID = 1;
    uint32 private eventsID = 1;
    uint32 private servicesID = 1;
    uint32 private guildsID = 1;

    bool private freeGuilds = true;
    uint256 private guildPrice = 100;
    
    event TranferOwnership (address indexed owner, address indexed recipient, uint256 transfered);
    event TranferBank (address indexed bank, address indexed recipient, uint256 transfered);
    event Guild(address indexed owner, uint256 indexed guild, uint256 created);
    event Register(address indexed wallet, uint256 indexed member, uint256 joined);
    event Join(uint256 indexed member, uint256 indexed guild, uint256 joined);
    event Plan(uint256 indexed guild, uint256 indexed service, uint256 indexed plan, uint256 created);
    event Service(uint256 indexed service, uint256 indexed guild, uint256 created);
    event Subscribe(uint256 indexed member, uint256 indexed plan, uint256 joined);
    event Ban(uint256 indexed guild, uint256 indexed member, uint256 banned);
    event Event(uint256 indexed guild, uint256 indexed service, uint256 indexed evnt, uint256 created);
    event Verified(uint256 indexed guild, uint256 verified);
    event Unverified(uint256 indexed guild, uint256 unverified);

    AggregatorV3Interface private priceFeed;

    constructor(
        address owner_,
        address bank_
    ) {
        _setOwner(owner_);
        _setBank(bank_);

        priceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
    }

    struct Guilds {
        string name;
        string description;
        string continent;
        string logo;
        address payable owner;
        uint256 created;
        uint256 verified;
    }

    struct Services {
        string mode;
        string description;
        string identifier;
        uint256 created;
    }

    struct Members {
        string nickname;
        uint256 joined;
        uint256 lastActivity;
    }

    struct Plans {
        string name;
        string description;
        uint256 price;
        uint256 duration;
        uint256 until;
        string role;        
    }

    struct Events {
        string name;
        string description;
        string banner;
        uint256 price;
        uint256 start;
        uint256 end;
        string role;        
    }

    struct Subscriptions {
        uint32 plan;
        uint256 start;
        uint256 end;
    }

    // ********************************************
    // MAPS
    // ********************************************
    mapping(address => bool) private team;

    mapping(uint32 => Guilds) private guilds;
    mapping(uint32 => Services) private services;
    mapping(uint32 => Plans) private plans;
    mapping(uint32 => Events) private events;
    mapping(uint32 => Members) private members;
    mapping(uint32 => Subscriptions) private subscriptions;

    mapping(uint32 => bool) private guildState;
    mapping(uint32 => bool) private serviceState;
    mapping(uint32 => bool) private planState;
    mapping(uint32 => bool) private eventsState;
    mapping(uint32 => bool) private memberState;
    mapping(uint32 => bool) private subscriptionState;

    mapping(uint32 => uint32[]) private guildServices;
    mapping(uint32 => uint32[]) private servicesPlans;
    mapping(uint32 => uint32[]) private servicesEvents;

    mapping(address => uint32) private wallet;
    mapping(uint32 => mapping(uint32 => bool)) private banned;

    mapping(address => uint32[]) private guildCreators;
    mapping(uint32 => uint32[]) private guildMembers;
    mapping(uint32 => mapping(uint32 => string)) private memberAccounts;
    mapping(uint32 => mapping(uint32 => uint32[])) private activeSubs;
    mapping(uint32 => mapping(uint32 => uint32[])) private eventsParticipants;

    modifier __checkRegisteredWallet(
        uint32 member
    ) {
    require(
        getMemberFromWallet(_msgSender()) == member,
        "1001"
    );
     _;   
    }

    modifier __checkGuildOwnership(
        uint32 guild,
        bool ownership
    ) {
        (,,,,address payable guildOwner,,) = getGuild(guild);
        require(
            (ownership ? _msgSender() == guildOwner : _msgSender() != guildOwner) || _isOwnerOrTeam() == true,
            "1002"
        );
        _;
    }

    modifier __checkGuildState(
        uint32 guild,
        bool state
    ) {
        require(
            guild > 0 && guild < guildsID && _getGuildState(guild) == state,
            "1003"
        );
        _;
    }
    
    modifier __checkServiceState(
        uint32 service,
        bool state
    ) {
        require(
            service > 0 && service < servicesID && _getServiceState(service) == state,
            "1004"
        );
        _;
    }

    modifier __checkServiceInGuild(
        uint32 guild,
        uint32 service,
        bool state
    ) {
        require(
            _isServiceInGuild(guild, service) == state,
            "1005"
        );
        _;
    }

    modifier __checkModeInGuildServices(
        uint32 guild,
        string memory mode,
        bool state
    ) {
        require(
            state ? findGuildService(guild, mode) > 0 : findGuildService(guild, mode) == 0,
            "1006"
        );
        _;
    }

    modifier __checkIdentifierInServiceMode(
        string memory mode,
        string memory identifier,
        bool state
    ) {
        require(
            _isIdentifierInServiceMode(mode, identifier) == state,
            "1007"
        );
        _;
    }

    modifier __checkPlanState(
        uint32 plan,
        bool state
    ) {
        require(
            plan > 0 && plan < plansID && _getPlanState(plan) == state,
            "1008"
        );
        _;
    }

    modifier __checkEventState(
        uint32 evnt,
        bool state
    ) {
        require(
            evnt > 0 && evnt < eventsID && _getEventState(evnt) == state,
            "1007"
        );
        _;
    }

    modifier __checkPlanInService(
        uint32 service,
        uint32 plan,
        bool state
    ) {
        require(
            _isPlanInService(service, plan) == state,
            "1008"
        );
        _;
    }

    modifier __checkEventInService(
        uint32 service,
        uint32 evnt,
        bool state
    ) {
        require(
            _isEventInService(service, evnt) == state,
            "1009"
        );
        _;
    }

    modifier __checkMemberState(
        uint32 member,
        bool state
    ) {
        require(
            member > 0 && member < membersID && _getMemberState(member) == state,
            "1010"
        );
        _;
    }

    modifier __checkMemberInGuild(
        uint32 guild,
        uint32 member,
        bool state
    ) {  
        require(
            _isMemberInGuild(guild, member) == state,
            "1011"
        );
        _;
    }

    modifier __checkMemberBannedFromGuild(
        uint32 guild,
        uint32 member,
        bool state
    ) {  
        require(
            _isBannedFromGuild(guild, member) == state,
            "1012"
        );
        _;
    }

    modifier __checkMemberInService(
        uint32 service,
        uint32 member,
        bool state
    ) {  
        require(
            _isMemberInGuildService(service, member) == state,
            "1013"
        );
        _;
    }

    modifier __checkMemberAccountInService(
        uint32 service,
        string memory account,
        bool state
    ) { 
        require(
            _isMemberAccountInGuildService(service, account) == state,
            "1014"
        );
        _;
    }

    modifier __checkMemberInEvent(
        uint32 service,
        uint32 evnt,
        uint32 member,
        bool state
    ) { 
        require(
            _isMemberInGuildServiceEvent(service, evnt, member) == state,
            "1015"
        );
        _;
    }

    modifier __checkIsSelf(
        uint32 member,
        bool state
    ) { 
        require(
            _isSelf(member) == state,
            "1016"
        );
        _;
    }

    modifier __checkSubscriptionState(
        uint32 subscription,
        bool state
    ) {
        require(
            subscription > 0 && subscription < subscriptionsID && _getSubscriptionState(subscription) == state,
            "1017"
        );
        _;
    }

    modifier __checkNotEmptyString(
        string memory stringToCheck
    ) {
        bytes memory emptyString = bytes(stringToCheck);
        require(
            emptyString.length > 0,
            "1018"
        );
        _;
    }

    modifier __checkHasEnough(
        uint256 required
    ) {
        uint256 conversion = conversionRate(required);

        require(
            _msgValue() >= conversion,
            "1019"
        );
        _;
    }

    modifier __isOwner() {
        require(
            _isOwner(),
            "1020"
        );
        _;
    }

    // BASIC FUNCTIONS

    function getTimestamp(
    ) public view returns (
        uint256
    ) {
        return block.timestamp;
    }
    
    // OWNER FUNCTIONS

    function _getOwner() private view
    returns (
        address payable
    ) {
        return payable(_owner);
    }

    function _isOwner() private view
    returns (
        bool
    ) {
        return _msgSender() == _getOwner();
    }

    function _isOwnerOrTeam() private view
    returns (
        bool
    ) {
        return _isTeam(_msgSender()) == true || _msgSender() == _getOwner();
    }
    
    function setOwner(
        address nextOwner
    ) public payable
        __isOwner()
    {
        _setOwner(nextOwner);
    }

    function _setOwner(
        address nextOwner
    ) private {
        address payable previousOwner = _getOwner();
        _owner = payable(nextOwner);

        emit TranferOwnership(previousOwner, nextOwner, getTimestamp());
    }

    // BANK FUNCTIONS

    function _getBank(
    ) private view
    returns(
        address payable
    ) {
        return payable(_bank);
    }

    function setBank(
        address nextBank
    ) public payable
        __isOwner()
    {
        _setBank(nextBank);
    }

    function _setBank(
        address nextBank
    ) private
    {
        address payable previousBank = _getBank();
        _bank = payable(nextBank);

        emit TranferBank(previousBank, nextBank, getTimestamp());
    }

    // TEAM FUNCTIONS

    function _isTeam(
        address sender
    ) private view returns (
        bool
    ) {
        return team[sender];
    }

    function setTeam(
        address target
    ) public payable 
        __isOwner()
    {
        team[target] = true;
    }

    function revokeTeam(
        address target,
        bool remove
    ) public payable
        __isOwner()
    returns (
        bool
    ) {
        team[target] = false;
        if(remove == true) {
            delete team[target];
        }
        return true;
    }

    // VERIFIERS FUNCTIONS

    function _isSelf(
        uint256 member
    ) private view returns(
        bool
    ) {
        return member == getMemberFromWallet(_msgSender());
    }

    function _isIdentifierInServiceMode(
        string memory mode,
        string memory identifer
    ) private view returns(
        bool
    ) {
        for(uint32 sid = 1; sid < servicesID; sid++) {
            if(_getServiceState(sid)) {
                (string memory serviceMode, , string memory serviceIdentifier, ) = getService(sid);
                if (keccak256(bytes(mode)) == keccak256(bytes(serviceMode)) && keccak256(bytes(identifer)) == keccak256(bytes(serviceIdentifier))) {
                    return true;
                }
            }
        }
        return false;
    }

    function _isMemberInGuild(
        uint32 guild,
        uint32 member
    ) private view returns (
        bool
    ) {
        uint32[] memory servicesInGuild = getGuildsServices(guild);
        for(uint32 sid = 0; sid < servicesInGuild.length; sid++) {
            if(servicesInGuild[sid] != 0 && _getServiceState(servicesInGuild[sid]) == true) {
                uint32[] memory membersInService = getMembersFromGuildService(servicesInGuild[sid]);
                for(uint32 mid = 0; mid < membersInService.length; mid++) {
                    if(membersInService[mid] != 0 && _getMemberState(membersInService[mid]) && member == membersInService[mid]) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function _isMemberInGuildService(
        uint32 service,
        uint32 member
    ) private view returns (
        bool
    ) {
        uint32[] memory membersInService = getMembersFromGuildService(service);
        for(uint32 mid = 0; mid < membersInService.length; mid++) {
            if(membersInService[mid] != 0 && _getMemberState(membersInService[mid]) && member == membersInService[mid]) {
                return true;
            }
        }
        return false;
    }

    function _isMemberInGuildServiceEvent(
        uint32 service,
        uint32 evnt,
        uint32 member
    ) private view returns (
        bool
    ) {
        uint32[] memory membersInEvent = getEventAttendies(service, evnt);
        for(uint32 mid = 0; mid < membersInEvent.length; mid++) {
            if(membersInEvent[mid] != 0 && _getMemberState(membersInEvent[mid]) && member == membersInEvent[mid]) {
                return true;
            }
        }
        return false;
    }

    function _isMemberAccountInGuildService(
        uint32 service,
        string memory account
    ) private view returns (
        bool
    ) {
        uint32[] memory membersInService = getMembersFromGuildService(service);
        for(uint32 mid = 0; mid < membersInService.length; mid++) {
            if(membersInService[mid] != 0 && _getMemberState(membersInService[mid]) == true) {
                string memory memberAccount = getMemberAccount(service, membersInService[mid]);
                if(keccak256(bytes(account)) == keccak256(bytes(memberAccount))) {
                    return true;
                }
            }
        }
        return false;
    }
    
    function _isPlanInService(
        uint32 service, 
        uint32 plan
    ) private view returns(
        bool
    ) {
        uint32[] memory plansInService = getServicesPlans(service);
        for(uint32 pid = 0; pid < plansInService.length; pid++) {
            if(plansInService[pid] != 0 && _getPlanState(plansInService[pid]) == true && plansInService[pid] == plan) {
                return true;
            }
        }
        return false;
    }

    function _isEventInService(
        uint32 service, 
        uint32 evnt
    ) private view returns(
        bool
    ) {
        uint32[] memory eventsInService = getServicesEvents(service);
        for(uint32 pid = 0; pid < eventsInService.length; pid++) {
            if(eventsInService[pid] != 0 && _getEventState(eventsInService[pid]) == true && eventsInService[pid] == evnt) {
                return true;
            }
        }
        return false;
    }

    function _isServiceInGuild(
        uint32 guild, 
        uint32 service
    ) private view returns(
        bool
    ) {
        uint32[] memory servicesInGuild = getGuildsServices(guild);
        for(uint32 sid = 0; sid < servicesInGuild.length; sid++) {
            if(servicesInGuild[sid] != 0 && _getServiceState(servicesInGuild[sid]) == true && servicesInGuild[sid] == service) {
                return true;
            }
        }
        return false;
    }

    // PUBLIC: CUSTOMER ACTIONS

    function register(
        string memory nickname
    ) public payable 
        __checkNotEmptyString(nickname)
        __checkRegisteredWallet(0)
    {
        uint32 newMember = _createMemberStructure(nickname);
        _setWallet(_msgSender(), newMember);

        emit Register(_msgSender(), newMember, getTimestamp());
    }

    function join(
        uint32 guild,
        uint32 service,
        string memory account
    ) public payable
        __checkGuildState(guild, true)
        __checkServiceState(service, true)
        __checkServiceInGuild(guild, service, true)
    {
        uint32 member = getMemberFromWallet(_msgSender());
        _afterStateCheckJoin(guild, service, member, account);
    }

    function subscribe(
        uint32 guild,
        uint32 service,
        uint32 plan
    ) public payable
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, false)
        __checkServiceState(service, true)
        __checkPlanState(plan, true)
        
    {
        _afterStateCheckSubscribe(guild, service, plan);
    }

    function participate(
        uint32 guild,
        uint32 service,
        uint32 evnt
    ) public payable
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, false)
        __checkServiceState(service, true)
        __checkEventState(evnt, true)
        
    {
        _afterStateCheckParticipate(guild, service, evnt);
    }

    // PRIVATE: {JOIN} RELATED FUNCTIONS

    function _afterStateCheckJoin(
        uint32 guild, 
        uint32 service,
        uint32 member,
        string memory account
    ) private 
        __checkMemberState(member, true)
        __checkRegisteredWallet(member)
        __checkGuildOwnership(guild, false)
    {
        _afterMemberCheckJoin(guild, service, member, account);
    }

    function _afterMemberCheckJoin(
        uint32 guild, 
        uint32 service,
        uint32 member,
        string memory account
    ) private 
        __checkMemberBannedFromGuild(guild, member, false)
        __checkMemberInService(service, member, false)
        __checkMemberAccountInService(service, account, false)
    {
        _linkMembers(service, member);
        _linkMemberAccounts(member, service, account);

        _updateMemberActivity(member);

        emit Join(member, guild, getTimestamp());
    }

    // PRIVATE: {SUBSCRIBE} RELATED FUNCTIONS

    function _afterStateCheckSubscribe(
        uint32 guild,
        uint32 service,
        uint32 plan
    ) private
        __checkServiceInGuild(guild, service, true)
        __checkPlanInService(service, plan, true)
    {
        uint32 member = getMemberFromWallet(_msgSender());
        _afterGuildCheckSubscribe(guild, service, plan, member);
    }

    function _afterGuildCheckSubscribe(
        uint32 guild,
        uint32 service,
        uint32 plan,
        uint32 member
    ) private
        __checkMemberState(member, true)
        __checkRegisteredWallet(member)
        __checkMemberBannedFromGuild(guild, member, false)
        __checkMemberInService(service, member, true)
    {
        _afterMemberCheckSubscribe(guild, service, plan, member);
    }

    function _afterMemberCheckSubscribe(
        uint32 guild,
        uint32 service,
        uint32 plan,
        uint32 member
    ) private {
        (,, uint256 price ,, uint256 until,) = getPlan(plan);
        require(until == 0 || getTimestamp() <= until);
        _buy(guild, price);
        _afterMemberBuySubscribe(service, plan, member);
    }

    function _afterMemberBuySubscribe(
        uint32 service,
        uint32 plan,
        uint32 member
    ) private {
        uint32[] memory subs = getMembersSubscriptions(service, member);
        uint256 starter = getTimestamp();
        if(subs.length > 0) {
            for(uint32 subid = 0; subid < subs.length; subid++) {
                (uint32 subPlan, , uint256 subEnd) = getSubscriptions(subs[subid]);
                if(subPlan == plan && subEnd > getTimestamp()) {
                    starter = subEnd;
                }
            }
        }
        
        _newSubscription(service, plan, member, starter);
        _updateMemberActivity(member);
    }

    function _newSubscription(
        uint32 service,
        uint32 plan,
        uint32 member,
        uint256 timer
    ) private {
        uint32 newSub = _createSubscriptionStructure(plan, timer);
        _linkActiveSub(service, member, newSub);

        emit Subscribe(member, plan, timer);
    }

    function _createSubscriptionStructure(
        uint32 plan,
        uint256 timer
    ) private returns (
        uint32
    ) {
        uint32 newId = subscriptionsID;
        uint256 end = timer + (getPlanDuration(plan) * 1 days);
        subscriptions[newId] = Subscriptions(plan, timer, end);
        subscriptionsID++;

        _setSubscriptionState(newId, true);

        return newId;
    }

    // PRIVATE: {PARTICIPATE} RELATED FUNCTIONS

    function _afterStateCheckParticipate(
        uint32 guild,
        uint32 service,
        uint32 evnt
    ) private
        __checkServiceInGuild(guild, service, true)
        __checkEventInService(service, evnt, true)
    {
        uint32 member = getMemberFromWallet(_msgSender());
        _afterGuildCheckParticipate(guild, service, evnt, member);
    }

    function _afterGuildCheckParticipate(
        uint32 guild,
        uint32 service,
        uint32 evnt,
        uint32 member
    ) private
        __checkMemberState(member, true)
        __checkRegisteredWallet(member)
        __checkMemberBannedFromGuild(guild, member, false)
        __checkMemberInService(service, member, true)
    {
        _afterMemberCheckParticipates(guild, service, evnt, member);
    }

    function _afterMemberCheckParticipates(
        uint32 guild,
        uint32 service,
        uint32 evnt,
        uint32 member
    ) private {
        (,,, uint256 price ,,,) = getEvents(evnt);
        _buy(guild, price);
        _afterMemberCheckBuyParticipates(service, evnt, member);
    }

    function _afterMemberCheckBuyParticipates(
        uint32 service,
        uint32 evnt,
        uint32 member
    ) private 
        __checkMemberInEvent(service, evnt, member, false)
    {
        _setEventAttendies(service, evnt, member);
    }

    // PUBLIC: GUILD ACTIONS 
    function createGuild(
        string memory name,
        string memory description,
        string memory continent,
        string memory logo
    ) public payable 
        __checkNotEmptyString(name)
        __checkNotEmptyString(description)
        __checkNotEmptyString(continent)
        __checkNotEmptyString(logo)
    {
        uint32 newId = guildsID;

        if(getFreeGuildState() == false) {
            _buy(newId, getGuildPrice());
        }

        _createGuildStructure(newId, name, description, continent, logo);
        _setGuildCreator(_msgSender(), newId);
    }

    function getGuild(
        uint32 guild
    ) public view returns (
        string memory,
        string memory,
        string memory,
        string memory,
        address payable,
        uint256,
        uint256
    ) {
        return (
            guilds[guild].name,
            guilds[guild].description,
            guilds[guild].continent,
            guilds[guild].logo,
            guilds[guild].owner,
            guilds[guild].created,
            guilds[guild].verified  
        );
    }

    function setGuildPrice(
        uint32 price
    ) public payable
        __isOwner()
    {
        guildPrice = price;
    }
    
    function setFreeGuildState(
        bool state
    ) public payable
        __isOwner()
    {
        freeGuilds = state;
    }

    function setGuildVerification(
        uint32 guild,
        bool verified
    ) public payable 
        __isOwner()
    {
        guilds[guild].verified = verified ? getTimestamp() : 0;
        if(verified) {
            emit Verified(guild, getTimestamp());
        } else {
            emit Unverified(guild, getTimestamp());
        }
    }

    // PRIVATE:  GUILD FUNCTIONS

    function _createGuildStructure(
        uint32 id,
        string memory name,
        string memory description,
        string memory continent,
        string memory logo
    ) private {
        guilds[id] = Guilds(name, description, continent, logo, _msgSender(), getTimestamp(), 0);
        
        _setGuildState(id, true);
        guildsID++;

        emit Guild(_msgSender(), id, getTimestamp());
    }

    function getGuildPrice() public view returns(
        uint256
    ) {
        return guildPrice;
    }

    function getFreeGuildState() private view returns(
        bool
    ) {
        return freeGuilds;
    }

    function getGuildsFromCreator(
        address creator
    ) public view returns(
        uint32[] memory
    ) {
        return guildCreators[creator];
    }

    function _setGuildCreator(
        address sender,
        uint32 guild
    ) private {
        guildCreators[sender].push(guild);
    }

    // PUBLIC: SERVICE ACTIONS
    
    function createService(
        uint32 guild,
        string memory mode,
        string memory description,
        string memory identifier
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true)
        __checkModeInGuildServices(guild, mode, false)
    {
        uint32 newService = _createServiceStructure(mode, description, identifier);
        _linkServices(guild, newService);

        emit Service(newService, guild, getTimestamp());
    }

    // PRIVATE: SERVICE FUNCTIONS

    function _createServiceStructure(
        string memory mode,
        string memory description,
        string memory identifier
    ) private 
        __checkNotEmptyString(mode)
        __checkNotEmptyString(description)
        __checkIdentifierInServiceMode(mode, identifier, false)
    returns (
        uint32
    ) {
        uint32 newId = servicesID;
        services[newId] = Services(mode, description, identifier, getTimestamp());
        servicesID++;

        _setServiceState(newId, true);

        return newId;
    }

    // PUBLIC: PLAN ACTIONS

    function createPlan(
        uint32 guild,
        uint32 service,
        string memory name, 
        string memory description,
        uint256 price,
        uint256 duration,
        uint256 until,
        string memory role
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true) 
    {
        _createPlan(guild, service, name, description, price, duration, until, role);
    }

    function deletePlan(
        uint32 guild,
        uint32 service,
        uint32 plan
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true)
        __checkServiceState(service, true)
        __checkServiceInGuild(guild, service, true)
    {
        _afterCheckDeletePlan(service, plan);
    }

    // PRIVATE: PLAN FUNCTIONS

    function _createPlan(
        uint32 guild,
        uint32 service,
        string memory name, 
        string memory description,
        uint256 price,
        uint256 duration,
        uint256 until,
        string memory role
    ) private 
        __checkServiceInGuild(guild, service, true)
    {
        uint32 newPlan = _createPlanStructure(name, description, price, duration, until, role);
        _linkPlans(service, newPlan);

        emit Plan(guild, service, newPlan, getTimestamp());
    }

    function _createPlanStructure(
        string memory name,
        string memory description, 
        uint256 price,
        uint256 duration,
        uint256 until,
        string memory role
    ) private
        __checkNotEmptyString(name)
        __checkNotEmptyString(description)
        __checkNotEmptyString(role)
    returns (
        uint32
    ) {
        uint32 newId = plansID;
        plans[newId] = Plans(name, description, price, duration, until, role);
        plansID++;

        _setPlanState(newId, true);

        return newId;
    }

    function _afterCheckDeletePlan(
        uint32 service,
        uint32 plan
    ) private
        __checkPlanState(plan, true)
        __checkPlanInService(service, plan, true)
    {
        uint32[] memory membersFromGuildService = getMembersFromGuildService(service);
        if(membersFromGuildService.length > 0) {
            for(uint32 mid = 0; mid < membersFromGuildService.length; mid++) {
                if(_getMemberState(membersFromGuildService[mid])) {
                    uint32[] memory membersSubscriptions = getMembersSubscriptions(service, membersFromGuildService[mid]);
                    if(membersSubscriptions.length > 0) {
                        for(uint32 subid = 0; subid < membersSubscriptions.length; subid++) {
                            if(_getSubscriptionState(membersSubscriptions[subid])) {
                                (uint32 subPlan, , ) = getSubscriptions(membersSubscriptions[subid]);
                                if(subPlan == plan) {
                                    _deleteLinkedActiveSub(service, membersFromGuildService[mid], subid);
                                    _setSubscriptionState(membersSubscriptions[subid], false);
                                    _deleteSubscription(membersSubscriptions[subid]);
                                }
                            }
                        } 
                    }
                }
            }
        }
        uint32[] memory plansInService = getServicesPlans(service);
        if(plansInService.length > 0) {
            for(uint32 pid = 0; pid < plansInService.length; pid++) {
                if(plansInService[pid] == plan) {
                    _deleteLinkedPlan(service, pid);
                }
            }
        }
        
        _deletePlan(plan);
    }
    
    function _deletePlan(
        uint32 plan
    ) private {
        _setPlanState(plan, false);
        _deletePlanStructure(plan);
    }

    function _deleteLinkedPlan(
        uint32 service,
        uint32 row
    ) private {
        delete servicesPlans[service][row]; 
    }

    function _deleteLinkedPlans(
        uint32 service
    ) private {
        delete servicesPlans[service]; 
    }
    
    // PUBLIC: EVENT ACTIONS

    function createEvent(
        uint32 guild,
        uint32 service,
        string memory name, 
        string memory description,
        string memory banner,
        uint256 price,
        uint256 start,
        uint256 end,
        string memory role
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true)
    {
        _createEvent(guild, service, name, description, banner, price, start, end, role);
    }

    function getEventAttendies(
        uint32 service,
        uint32 evnt
    ) public view returns (
        uint32[] memory
    ) {
        return eventsParticipants[service][evnt];
    }

    // PRIVATE: EVENT FUNCTIONS
    
    function _createEvent(
        uint32 guild,
        uint32 service,
        string memory name, 
        string memory description,
        string memory banner,
        uint256 price, 
        uint256 start,
        uint256 end,
        string memory role
    ) private 
        __checkNotEmptyString(name)
        __checkServiceInGuild(guild, service, true)
    {
         _createEventExtraChecks(guild, service, name, description, banner, price, start, end, role);
    }

    function _createEventExtraChecks(
        uint32 guild,
        uint32 service,
        string memory name, 
        string memory description,
        string memory banner,
        uint256 price, 
        uint256 start,
        uint256 end,
        string memory role
    ) private 
        __checkNotEmptyString(description)
        __checkNotEmptyString(banner)
        
    {
        _createEventCountCheck(guild, service, name, description, banner, price, start, end, role);
    }

    function _createEventCountCheck(
        uint32 guild,
        uint32 service,
        string memory name, 
        string memory description,
        string memory banner,
        uint256 price, 
        uint256 start,
        uint256 end,
        string memory role
    ) private 
        __checkNotEmptyString(role)
    {
        uint32 newEvent = _createEventStructure(name, description, banner, price, start, end, role);
        _linkEvents(service, newEvent);

        emit Event(guild, service, newEvent, getTimestamp());
    }
    
    function _createEventStructure(
        string memory name,
        string memory description,
        string memory banner,
        uint256 price, 
        uint256 start,
        uint256 end,
        string memory role
    ) private returns (
        uint32
    ) {
        uint32 newId = eventsID;
        events[newId] = Events(name, description, banner, price, start, end, role);
        eventsID++;

        _setEventsState(newId, true);

        return newId;
    }
    
    function _setEventAttendies(
        uint32 service,
        uint32 evnt,
        uint32 member
    ) private {
        eventsParticipants[service][evnt].push(member);
    }
     
    // PUBLIC VIEWS

    function findGuildService(
        uint32 guild,
        string memory mode
    ) public view returns (
        uint32
    ) {
        uint32[] memory servicesAvailable = getGuildsServices(guild);
        if(servicesAvailable.length > 0) {
            for(uint32 sid = 0; sid < servicesAvailable.length; sid++) {
                if(servicesAvailable[sid] != 0 && _getServiceState(servicesAvailable[sid]) == true) {
                    (string memory name,,,) = getService(servicesAvailable[sid]);
                    if (keccak256(bytes(mode)) == keccak256(bytes(name))) {
                        return servicesAvailable[sid];
                    }
                }
            }
        }
        return 0;
    }

    function findGuild(
        string memory mode,
        string memory matcher
    ) public view returns (
        uint32
    ) {
        for (uint32 gid = 1; gid < guildsID; gid++) {
            if(_getGuildState(gid) == true) {
                uint32[] memory servicesAvailable = getGuildsServices(gid);
                if(servicesAvailable.length > 0) {
                    for(uint32 sid = 0; sid < servicesAvailable.length; sid++) {
                        if(servicesAvailable[sid] != 0 && _getServiceState(servicesAvailable[sid]) == true) {
                            (string memory name,, string memory serviceId,) = getService(servicesAvailable[sid]);
                            if (keccak256(bytes(mode)) == keccak256(bytes(name)) && keccak256(bytes(serviceId)) == keccak256(bytes(matcher))) {
                                return gid;
                            }
                        }
                    }
                }
            }
        }
        return 0;
    }

    function _createMemberStructure(
        string memory nickname
    ) private
    returns (
        uint32
    ) {
        uint32 newId = membersID;
        members[newId] = Members(nickname, getTimestamp(), getTimestamp());
        membersID++;

        _setMemberState(newId, true);

        return newId;
    }

    
    function getMember(
        uint32 member
    ) public view
        __checkMemberState(member, true)
    returns (
        string memory,
        uint256,
        uint256
    ) {
        return (
            members[member].nickname,
            members[member].joined,
            members[member].lastActivity
        );
    }

    function getMemberFromWallet(
        address target
    ) public view returns (
        uint32
    ) {
        
        return wallet[target];
    }

    function getMembersFromGuildService(
        uint32 service
    ) public view returns (
        uint32[] memory
    ) {
        
        return guildMembers[service];
    }

    function getMembersSubscriptions(
        uint32 service,
        uint32 member
    ) public view returns (
        uint32[] memory
    ) {
        return activeSubs[service][member];
    }

    function getServicesPlans(
        uint32 service
    ) public view returns (
        uint32[] memory
    ) {
        return servicesPlans[service];
    }

    function getServicesEvents(
        uint32 service
    ) public view returns (
        uint32[] memory
    ) {
        return servicesEvents[service];
    }

    function getGuildsServices(
        uint32 guild
    ) public view returns (
        uint32[] memory
    ) {
        return guildServices[guild];
    }

    function getGuilds() public view returns (
        uint32
    ) {
        return guildsID;
    }
    
    

    function getService(
        uint32 service
    ) public view returns (
        string memory,
        string memory,
        string memory,
        uint256
    ) {
        return (
            services[service].mode,
            services[service].description,
            services[service].identifier,
            services[service].created  
        );
    }

    function getPlan(
        uint32 plan
    ) public view returns (
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        string memory
    ) {
        return (
            plans[plan].name,
            plans[plan].description,
            plans[plan].price,
            plans[plan].duration,
            plans[plan].until,
            plans[plan].role   
        );
    }

    function getPlanDuration(
        uint32 plan
    ) private view returns (
        uint256
    ) {
        return plans[plan].duration;
    }

    function getSubscriptions(
        uint32 subscription
    ) public view returns (
        uint32,
        uint256,
        uint256
    ) {
        return (
            subscriptions[subscription].plan,
            subscriptions[subscription].start,
            subscriptions[subscription].end
        );
    }

    function getEvents(
        uint32 evnt
    ) public view returns (
        string memory,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        string memory
    ) { 
        return (
            events[evnt].name,
            events[evnt].description,
            events[evnt].banner,
            events[evnt].price,
            events[evnt].start,
            events[evnt].end,
            events[evnt].role
        );
    }

    function _removeMember(
        uint32 applicant
    ) private {
        delete members[applicant];
    }

    function _setWallet(
        address applicant,
        uint32 identifier
    ) private {
        wallet[applicant] = identifier;
    }

    function _linkMembers(
        uint32 service,
        uint32 member
    ) private {
        guildMembers[service].push(member);
    }

    function _linkPlans(
        uint32 service,
        uint32 plan
    ) private {
        servicesPlans[service].push(plan); 
    }

    function _linkEvents(
        uint32 service,
        uint32 evnt
    ) private {
        servicesEvents[service].push(evnt); 
    }

    function _linkServices(
        uint32 guild,
        uint32 service
    ) private {
        guildServices[guild].push(service); 
    }

    function deleteMemberAccount(
        uint32 guild,
        uint32 member,
        uint32 service
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true)
        __checkServiceInGuild(guild, service, true)
        __checkMemberInService(service, member, true)
    {
        _deleteLinkedMemberAccounts(member, service);
    }

    function _linkMemberAccounts(
        uint32 member,
        uint32 service,
        string memory account
    ) private {
        memberAccounts[member][service] = account; 
    }

    function _linkActiveSub(
        uint32 service,
        uint32 member,
        uint32 subscription
    ) private {
        activeSubs[service][member].push(subscription);
    }

    function getMemberAccount(
        uint32 member,
        uint32 service
    ) public view returns(
        string memory
    ) {
        return memberAccounts[member][service]; 
    }

    function _setServiceState(
        uint32 service,
        bool state
    ) private {
        serviceState[service] = state; 
    }

    function _setPlanState(
        uint32 plan,
        bool state
    ) private {
        planState[plan] = state; 
    }

    function _setEventsState(
        uint32 evnt,
        bool state
    ) private {
        eventsState[evnt] = state; 
    }

    function _setMemberState(
        uint32 member,
        bool state
    ) private {
        memberState[member] = state; 
    }

    function _setGuildState(
        uint32 guild,
        bool state
    ) private {
        guildState[guild] = state; 
    }

    function _setSubscriptionState(
        uint32 subscription,
        bool state
    ) private {
        subscriptionState[subscription] = state; 
    }

    function _getServiceState(
        uint32 service
    ) private view returns (
        bool
    ) {
        return serviceState[service] || false; 
    }

    function _getPlanState(
        uint32 plan
    ) private view returns (
        bool
    ) {
        return planState[plan] || false; 
    }

    function _getEventState(
        uint32 evnt
    ) private view returns (
        bool
    ) {
        return eventsState[evnt] || false; 
    }

    function _getMemberState(
        uint32 member
    ) private view returns (
        bool
    ) {
        return memberState[member] || false; 
    }

    function _getGuildState(
        uint32 guild
    ) private view returns (
        bool
    ) {
        return guildState[guild] || false; 
    }

    function _getSubscriptionState(
        uint32 subscription
    ) private view returns (
        bool
    ) {
        return subscriptionState[subscription] || false; 
    }

    function deleteEvent(
        uint32 guild,
        uint32 service,
        uint32 evnt
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true)
        __checkServiceState(service, true)
        __checkServiceInGuild(guild, service, true)
        
    {
        _deleteEvent(service, evnt);
    }

    function _deleteEvent(
        uint32 service, 
        uint32 evnt
    ) private 
        __checkEventState(evnt, true)
        __checkEventInService(service, evnt, true)
    {
        uint32[] memory eventsInService = getServicesEvents(service);
        if(eventsInService.length > 0) {
            for(uint32 eid = 0; eid < eventsInService.length; eid++) {
                if(eventsInService[eid] != 0 && _getEventState(eventsInService[eid]) && evnt == eventsInService[eid]) {
                    _deleteEventStructure(eventsInService[eid]);
                    _deleteEventsAttendies(service, eventsInService[eid]);
                    _deleteEventsFromServicePerRow(service, eid);
                } 
            }
        }
    }

    function _deleteLinkedGuildMembers(
        uint32 service
    ) private {
        delete guildMembers[service];
    }

    function _deleteLinkedMemberAccounts(
        uint32 member,
        uint32 service
    ) private {
        delete memberAccounts[member][service]; 
    }

    function _deleteLinkedActiveSub(
        uint32 service,
        uint32 member,
        uint32 row
    ) private {
        delete activeSubs[service][member][row];
    }

    function _deleteLinkedActiveSubs(
        uint32 service,
        uint32 member
    ) private {
        delete activeSubs[service][member];
    }

    function _deletePlanStructure(
        uint32 plan
    ) private {
        _setPlanState(plan, false);
        delete plans[plan];
    }

    function _deleteSubscription(
        uint32 subscription
    ) private {
        _setSubscriptionState(subscription, false);
        delete subscriptions[subscription];
    }

    function _deleteEventsFromServicePerRow(
        uint32 service,
        uint32 row
    ) private {
        delete servicesEvents[service][row];
    }

    function _deleteEventsAttendies(
        uint32 service,
        uint32 evnt
    ) private {
        delete eventsParticipants[service][evnt];
    }

    function _deleteEventsFromService(
        uint32 service
    ) private {
        delete servicesEvents[service];
    }

    function _deleteEventStructure(
        uint32 evnt
    ) private {
        _setEventsState(evnt, false);
        delete events[evnt];
    }

    function banFromGuild (
        uint32 guild, 
        uint32 member,
        bool state 
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true)
    {
        _banFromGuild(guild, member, state);
    }
    
    function _banFromGuild(
        uint32 guild,
        uint32 member,
        bool state
    ) private 
        __checkMemberState(guild, true)
        __checkMemberBannedFromGuild(guild, member, !state)
        __checkMemberInGuild(guild, member, true)
    {
        banned[guild][member] = state;

        emit Ban(guild, member, getTimestamp());
    }

    function _isBannedFromGuild(
        uint32 guild,
        uint32 member
    ) private view returns (
        bool
    ) {
        return banned[guild][member] || false;
    }

    function _updateMemberActivity(
        uint32 member
    ) private {
        members[member].lastActivity = getTimestamp();
    }

    function updateGuild(
        uint32 guild,
        string memory name,
        string memory description,
        string memory content,
        string memory logo
    ) public payable 
        __checkGuildState(guild, true)
        __checkGuildOwnership(guild, true)
    {
        _updateGuild(guild, name, description, content, logo);
    }

    function _updateGuild(
        uint32 guild,
        string memory name,
        string memory description,
        string memory content,
        string memory logo
    ) private {
        guilds[guild].name = name;
        guilds[guild].description = description;
        guilds[guild].continent = content;
        guilds[guild].logo = logo;
    }

    // PUBLIC VIEWS: TOKENOMICS ACTIONS

    function conversionRate(
        uint256 price
    ) public view
    returns(
        uint256
    ) {
        uint256 fiatValue = price * 10 ** 18;
        uint256 mainNetPrice = uint(getLatestPrice());

        uint256 ratio = (fiatValue/mainNetPrice) * 10 ** 18;

        return ratio / 10 ** 10;
    }

    // PRIVATE: TOKENOMICS FUNCTIONS
    function _buy(
        uint32 guild,
        uint256 price
    ) private 
        __checkHasEnough(price)
    {
        uint256 taxed = _interestRate(_msgValue());
        uint256 remaining = _msgValue() - taxed;

        (,,,,address payable guildOwner,,) = getGuild(guild);

        (bool sentBank, ) = _getBank().call{ value: taxed }("");
        (bool sentGuildOwner, ) = guildOwner.call{ value: remaining }("");
        
        require(
            sentBank && sentGuildOwner
        );
    }

    function _interestRate(
        uint256 amount
    ) private view returns(
        uint256
    ) {
        return _percentage(amount, _interests, _percent);
    }

    function _percentage(
        uint256 a,
        uint256 b,
        uint256 c
    ) private pure returns(
        uint256
    ) {
        return (a / c) * b;
    }

    function getLatestPrice() public view returns (
        int256
    ) {
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return answer;
    }
}