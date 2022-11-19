//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
contract VotingPoll {
    
    struct Topic {
        uint256 topicid;
        string topic;
        Option[] options;
        uint256 expiry;
    }
    
    struct Option {
        string option;
        uint256 count;
    }
    
    struct Voter {
      address voter;
    }

    struct Request {
        address creator;
        address voter;
        uint256 topicid;
    }

    /*topiclist stores the values of topic created with the keys of Topic Creator
      address and id of the Topic like creator address => Topicid => Topic */
    mapping(address=>mapping(uint256=>Topic)) public topiclist;
    /*voterlist stores the values of address registered by the voter with the keys of Voter
      like msg.sender => Voter Registered Address */
    mapping(address=>Voter) public voterlist;
    /*requestlist stores the values of Request  by the voter with the keys of Voter
      address like msg.sender => Voter Registered Address */
    mapping(address=>Request) public requestlist;
    
    /* Topic validator which validates the existence of the topic  */
    mapping(address=>mapping(uint256=>bool)) private topicvalidator;
    /* Creator validator which validates the existence of the creator by is he create atleast one Topic  */
    mapping(address=>mapping(uint256=>bool)) private creatorvalidator;
    /* Vote validator which validates the Usage of the vote by Voter  */
    mapping(address=>mapping(address=>mapping(uint256=>bool))) private votevalidator;
    /* Voter validator which validates the Allowance of the Voter to Vote  */
    mapping(address=>mapping(uint256=>mapping(address=>bool))) private votervalidator;
    /* Request validator which validates the existence of the request by Voter  */
    mapping(address=>mapping(uint256=>mapping(address=>bool))) private requestvalidator;

    /* CreateTopic function is to create a topic by giving values such as Topicid,Topic and 
        Expiry time in terms of Hours.Intially it checks the existence of Topic using
        Topic Validator.if Everything goes well, it ensures the Topic and Creator existence */
    function createTopic(uint256 _topicid,string calldata _topic,uint256 _expirytime) public {
        
        require(topicvalidator[msg.sender][_topicid]==false,"Topic Already exists");
        
        _expirytime*=1 hours;
        
        topiclist[msg.sender][_topicid].topicid=_topicid;
        topiclist[msg.sender][_topicid].topic=_topic;
        topiclist[msg.sender][_topicid].expiry=block.timestamp+_expirytime;
        
        topicvalidator[msg.sender][_topicid]=true;
        creatorvalidator[msg.sender][_topicid]=true;
    }
     
     /* Create Option function is to create options for the existed Topic by giving values 
        such as Topic id and Option of the topic.Intially it validates the existence of the
        Topic and then Options length Because adding options to a topic is limited  */
    function createOption(uint256 _topicid,string calldata _option) public {
        
        require(topicvalidator[msg.sender][_topicid]==true,"Topic doesnt exist");
        require(topiclist[msg.sender][_topicid].options.length<3,"Only 3 options Allowed");
        
        topiclist[msg.sender][_topicid].options.push(Option(_option,0));

    }
   
      /* Register function is to register the address of the voter who wants to apply.Intially
         it validates the existence of the Voter*/
    function Register() public {

        require(voterlist[msg.sender].voter==address(0),"Voter already registered");

        voterlist[msg.sender].voter=msg.sender;

    }

    /* Request Creator function is to create an request for allowance of vote.Intially it validates
       the existence of topic , registration of voter and request*/
    function RequestCreator(address _creator,uint256 _topicid) public {
        
        require(topicvalidator[_creator][_topicid]==true,"Topic doesnt exist");
        require(msg.sender==voterlist[msg.sender].voter,"Not a Registered Voter");
        require(requestvalidator[_creator][_topicid][msg.sender]==false,"Request alrdy registered or Permitted");
        requestlist[msg.sender] = Request(_creator,msg.sender,_topicid);
        requestvalidator[_creator][_topicid][msg.sender]=true;
    }
    
     /*Permit Voter function is to accept the request of allowance  to vote.Intially it validates
       the existence of request,existence of topic creator and registered voter */
    function PermitVoter(address _voter,uint256 _topicid,bool _allow) public {
        
        require(requestvalidator[msg.sender][_topicid][_voter]==true,"Request not Existed");
        require(creatorvalidator[msg.sender][_topicid]==true,"Not a Topic Creator");
        require(_voter==voterlist[_voter].voter,"Not a Registered Voter");

        votervalidator[msg.sender][_topicid][_voter]=_allow;
        requestvalidator[msg.sender][_topicid][_voter]=false;
    }     

    /* Vote function is to vote the option of an certain topic by giving values such as
      Topicid,address of the creator and the option value in terms of numbers 0,1,2.Intially
      it validates the following conditions :
                 --> Existence of the Topic
                 --> Vote Expiry Time
                 --> Registered Voter
                 --> Allowance of the Voter
                 --> is Voter utilize his vote for topic
                 --> Valid Option*/
    function Vote(uint256 _topicid,address _creator,uint8 _option) public  {

        require(topicvalidator[_creator][_topicid]==true,"Topic doesnt exist");
        require(block.timestamp<topiclist[_creator][_topicid].expiry,"Voting ended");
        require(msg.sender==voterlist[msg.sender].voter,"Not a Registered Voter");
        require(votervalidator[_creator][_topicid][msg.sender]==true,"Topic Creator rejected you");
        require(votevalidator[msg.sender][_creator][_topicid]==false,"Already voted");
        require(_option<3,"Invalid Option");

             topiclist[_creator][_topicid].options[_option].count++;
             votevalidator[msg.sender][_creator][_topicid]=true;
    }

      /* GetTopic function is to Show the Topic to the User and it can done by giving values
        of desired Topicid and address of the creator.Intially it validates the existence of
        Topic */
    
    function getTopic(uint256 _topicid,address _creator) public view returns(Topic memory) {

      require(topicvalidator[_creator][_topicid]==true,"Topic doesnt exist");

        return topiclist[_creator][_topicid];

    }
    /*  Reset count function is to clears the count of the options of topic when it expires
        the function only accessible by the topic creators only so intially it validates the
        existence of the topic creator */
    function ResetCount(uint256 _topicid) public {

       require(creatorvalidator[msg.sender][_topicid]==true,"Not a Topic Creator"); 

        if(topiclist[msg.sender][_topicid].expiry>=block.timestamp){

            for(uint256 i=0;i<topiclist[msg.sender][_topicid].options.length;i++) {

            topiclist[msg.sender][_topicid].options[i].count=0;

            }
        }
    }
}