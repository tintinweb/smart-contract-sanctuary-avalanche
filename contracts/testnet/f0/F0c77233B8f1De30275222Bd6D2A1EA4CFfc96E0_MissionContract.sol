/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-27
*/

/// SPDX-License-Identifier: No license 
//Not allowed to be reused in part or in whole without express consent @[email protected] 
//03272022

pragma solidity >=0.8.0 <0.9.0;


/*
 * @Mission contract
 * @dev Implements method of choosing your side in Islands of AVAX / Avax Navies Missions
 */
contract MissionContract {
   
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted. replaced by votes array
        address delegate; // person delegated to
        uint[] votes; // index of the voted Option
        address[] delegatedAddresses;   
    }
    struct Creator {
        address creatorsAddress; // person who has been autorized to make missions
    }

    struct Option {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        string name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
        uint missionID;
        uint optionID;
    }

    struct Mission {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        string name;   // short name (up to 32 bytes)
        string description;
        uint missionID;
        bool isSecret;
        address creator;
    }

    struct Addresses {

        address[] addresses; 
    }


    address public Owner; 

    //address public AvaxNavies = 0x6b7a1d6094e2d2472168a7903f0ae3681cfdb973;
    //address public IslandsOfAvax = 0xf21a42e203db80593478f2e7ed8f97a8db9b3391;    
    
    mapping(address => Voter) private voters;
    mapping(address => bool) private creatorsRights;  
    mapping(bool => address[]) private creatorList; 
    mapping(uint => string) private missionName;
    mapping(uint => uint) private missionOptionCount;
    mapping(uint => uint) private optionToMission;
    mapping(uint => uint[]) private missionToOption;
    mapping(uint => address[]) private optionToAddress;
    mapping(uint => mapping(uint => address[])) private missionToAddress;
    //mapping(uint => address[]) private missionToAddress;
    mapping(address => uint[]) private addressToMission; //tells me what missions address voted for
    mapping(address => uint[]) private addressToOption; //tells me what options address voted for 
    mapping(address => mapping(uint => bool)) private addressToOptionVotedStatus; //tells me if address voted for a specific option
    mapping(address => mapping(uint => bool)) private addressToMissionVotedStatus; //tells me if address voted for a specific option
    mapping(uint => address) private missionCreatorByID;
    mapping(address => mapping(uint => address)) private addressandMissionToDelegateAddress;
    mapping(address => mapping(uint => address[])) private delegateandMissionToAddresses;


    Option[] private Options;
    Mission[] private Missions;    


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        Owner = msg.sender;
        creatorsRights[msg.sender] = true;
        creatorList[true].push(msg.sender);
    }

    function _transferOwnership(address newOwner) internal {

        Owner = newOwner;
    }



    function createMission(string calldata _missionName, string calldata _description, string[] calldata _optionNames, bool _isSecret) public {

        require(creatorsRights[msg.sender] == true, "You do not have permission to create Missions");

        for (uint i = 0; i < _optionNames.length; i++) {
            // 'Option({...})' creates a temporary
            // Option object and 'Options.push(...)'z
            // appends it to the end of 'Options'.
            optionToMission[Options.length]=Missions.length;
            
            Options.push(Option({
                name: _optionNames[i],//initialize name of option from call data input 
                voteCount: 0, //initialize votes for option as 0
                missionID: Missions.length,
                optionID: Options.length
            }));
        
        }
        missionName[Missions.length]= _missionName;
        missionOptionCount[Missions.length]= _optionNames.length;        
        missionCreatorByID[Missions.length]= msg.sender;        

        Missions.push(Mission({
            name: _missionName,
            description: _description,
            missionID: Missions.length,
            isSecret: _isSecret,
            creator: msg.sender
            }));
               

    }


    function getMissionByID(uint _missionID) external view returns(string memory _missionName, Option[] memory _tempOption, address _creator) 
    {
        

        if(Missions[_missionID].isSecret == true)
        {
            require(missionCreatorByID[_missionID] == msg.sender,"This mission is top secret, you dont have clearance to view results");
        }

        Option[] memory _option = new Option[](missionOptionCount[_missionID]) ; //create temporary option array
        uint counter = 0;
        for (uint i = 0; i < Options.length; i++) 
        {
            if (Options[i].missionID == _missionID) 
            {
                _option[counter] = Options[i]; //inserts options into temp array if it belongs to mission
                counter++;
            }

        }
        return (missionName[_missionID], _option, Missions[_missionID].creator);
    }

    function getOptionAddresses(uint _option) public view returns (address[] memory) 
    {
        return optionToAddress[_option]; 
    }

    function getAddressToMission(address _address) public view returns (uint[] memory) 
    { 
        return addressToMission[_address]; 
    }
    
    function getMyMissionParticipation() public view returns (uint[] memory) 
    { 
        return addressToMission[msg.sender]; 
    }

    function getMyVotesbyOption() public view returns (uint[] memory) 
    {    
        return addressToOption[msg.sender]; 
    }
    function getCreatorList() public view returns (address[] memory) 
    {
        return creatorList[true]; 
    }


    function giveRightToCreateMission(address _creator) public {
        require(msg.sender == Owner, "Only contract Owner can give right to vote.");
        creatorsRights[_creator] = true;
        creatorList[true].push(_creator);
    }

    function revokeRightToCreateMission(address _revokecreatoraddress) public {
        require(msg.sender == Owner, "Only contract Owner can give right to vote.");
        creatorsRights[_revokecreatoraddress] = false;
        for (uint i = 0; i < creatorList[true].length; i++) 
        {
            if(creatorList[true][i] == _revokecreatoraddress)
            {
                delete creatorList[true][i];
            }
        }
    }


    
     /* @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address _to, uint _missionID) public 
    {
        //Voter storage sender = voters[msg.sender]; //not sure i need this since i am using mappings for everything
        require(_missionID <= Missions.length, "Mission doesn't exist");//checks that user choice exists
        require(_to != msg.sender, "Self-delegation is disallowed.");
        
        require(addressandMissionToDelegateAddress[_to][_missionID] == address(0), "Delegate chains are not allowed, '_to' has already delegated to another address");
        require(addressandMissionToDelegateAddress[msg.sender][_missionID] == address(0), "Delegate chains are not allowed, you already have votes delegated to you");

        for (uint i = 0; i < addressToMission[msg.sender].length; i++) 
        {
            require(addressToMission[msg.sender][i] != _missionID, "You already voted in mission you are attempting to delegate to");
               
        }
        
        for (uint j = 0; j < addressToMission[_to].length; j++) 
        {
            require(addressToMission[_to][j] != _missionID, "Delegate already voted in mission you are attempting to delegate to, Choose another Delegate or vote directly");
        }    
        //sender.delegate = _to; //not sure i need this since i am using mappings for everything
        //Voter storage delegate_ = voters[_to]; //not sure i need this since i am using mappings for everything
        addressandMissionToDelegateAddress[msg.sender][_missionID] = _to;
        delegateandMissionToAddresses[_to][_missionID].push(msg.sender);


    }

    function revokedelegate(address _to, uint _missionID) public 
    {
        //Voter storage sender = voters[msg.sender]; //not sure i need this since i am using mappings for everything
        require(_missionID <= Missions.length, "Mission doesn't exist");//checks that user choice exists
        require(addressandMissionToDelegateAddress[msg.sender][_missionID] == _to, "You did not delegate your vote to this address");

        for (uint i = 0; i < addressToMission[msg.sender].length; i++) 
        {
            require(addressToMission[msg.sender][i] != _missionID, "You already voted in mission you are attempting to revoke delegate");
               
        }
        for (uint j = 0; j < addressToMission[_to].length; j++) 
        {
            require(addressToMission[_to][j] != _missionID, "Delegate already voted in mission you are attempting to delegate to, unable to revoke");
        }    
        //sender.delegate = _to; //not sure i need this since i am using mappings for everything
        //Voter storage delegate_ = voters[_to]; //not sure i need this since i am using mappings for everything
        delete addressandMissionToDelegateAddress[msg.sender][_missionID];
        
        for (uint k = 0; k < addressToMission[_to].length; k++) 
        {
            if(delegateandMissionToAddresses[_to][_missionID][k] ==msg.sender)
            {
                delete delegateandMissionToAddresses[_to][_missionID][k];
            }
        }

    }






    /*
     * @dev Give your vote (including votes delegated to you) to Option 'Options[_Option].name'.
     * @param Option index of Option in the Options array
     */
    function vote(uint _Option) public returns(uint[] memory _votes) {
        
        //voters[Owner].weight = 1; //concept of weight replaced by each address has weight of one and use length of mapping to determine.
        //Voter storage sender = voters[msg.sender]; //not sure i need this since i am using mappings for everything
        
        //require(sender.weight != 0, "Has no right to vote");// checks that user has voting rights
        
        
        uint Optioncount = Options.length -1; //calculates highest value that is allowed as a input choice  
        
        require(_Option <= Optioncount, "Option doesn't exist");//checks that user choice exists
        
        require(addressToMissionVotedStatus[msg.sender][optionToMission[_Option]] == false, "Already participated on this mission"); //checks that they havent voted yet
        
        require(addressandMissionToDelegateAddress[msg.sender][optionToMission[_Option]] == address(0),"You Delegated your vote, revoke delegation first");


        //Options[_Option].voteCount += sender.weight;// change to length of mapping and put after updating maps
        
        //add msg sender votes to mappings/options/and missions
        optionToAddress[_Option].push(msg.sender);
        addressToOption[msg.sender].push(_Option);
        addressToOptionVotedStatus[msg.sender][_Option] = true;

        missionToAddress[optionToMission[_Option]][_Option].push(msg.sender);
        addressToMission[msg.sender].push(optionToMission[_Option]);
        addressToMissionVotedStatus[msg.sender][optionToMission[_Option]] = true;

        //add delegated votes to mappings/options/and missions
        for(uint i=0; i < delegateandMissionToAddresses[msg.sender][optionToMission[_Option]].length; i++)
        {
            address _tempaddress = delegateandMissionToAddresses[msg.sender][optionToMission[_Option]][i]; // i think we need to double check here that address is not blank == 0 since we can delete objects from array in revoke delegate
            if (_tempaddress != address(0))
            {
                optionToAddress[_Option].push(_tempaddress);
                addressToOption[_tempaddress].push(_Option);
                addressToOptionVotedStatus[_tempaddress][_Option] = true;

                missionToAddress[optionToMission[_Option]][_Option].push(_tempaddress);
                addressToMission[_tempaddress].push(optionToMission[_Option]);
                addressToMissionVotedStatus[_tempaddress][optionToMission[_Option]] = true;
            }
        }

        Options[_Option].voteCount = optionToAddress[_Option].length;

        return (voters[msg.sender].votes);
    }

    /* 
     * @dev Computes the winning Option taking all previous votes into account.
     * @return winningOption_ index of winning Option in the Options array
     */
    function MissionWinner(uint _missionID) public view
            returns (string memory missionName_, uint winningOptionID_, string memory winnerOptionName_)
    {
        bool winnerFound = false;
        uint winningVoteCount = 0;
        for (uint i = 0; i < Options.length; i++) 
        {
            if ((Options[i].voteCount > winningVoteCount)&&(Options[i].missionID == _missionID)) 
            {
                winningVoteCount = Options[i].voteCount;
                winningOptionID_ = i;
                winnerFound = true;
            }
                       
        }

        require(winnerFound == true, "No winner found"); 
        
        
        winnerOptionName_ = Options[winningOptionID_].name; //output for human readable information
        missionName_= Missions[_missionID].name;//output for human readable information
    }


    function destroySmartContract(address payable _to) public {
        require(msg.sender == Owner, "You are not the owner");
        selfdestruct(_to);
    }

}