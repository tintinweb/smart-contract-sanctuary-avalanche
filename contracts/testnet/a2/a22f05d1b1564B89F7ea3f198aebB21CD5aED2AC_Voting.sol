//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
contract Voting{
    address public Chairperson;
    struct Voter{
      string name;
      address Address;
      uint weight;
      bool voted;
    }
    mapping(address=>Voter) public voters;
    struct Candidate{
        string name;
        address Address;
        uint votecount;
    }
    Candidate[] public candidates;
    enum State{Created,Voting,Ended}
    State internal state;

    constructor(){
       
        Chairperson=msg.sender;
        voters[Chairperson].weight=1;
        state=State.Created;
    }
     modifier OnlyChairperson(){
         require(Chairperson==msg.sender,"Access Denied");
         _;
     }
     modifier CreatedState(){
         require(state==State.Created,"This is in created state");
         _;
     }
     modifier VotingState(){
         require(state==State.Voting,"This is in Voting state");
         _;
     }
     modifier EndedState(){
         require(state==State.Ended,"Voting Ended");
         _;
     }
    function AddCandidates(string calldata _name,address _addr) public OnlyChairperson CreatedState {
        require(_addr==address(0),"Entered zeroaddress");
        candidates.push(Candidate(_name,_addr,0));
    }
    function AddVoters(string calldata _name,address _addr) public OnlyChairperson CreatedState{
           require(_addr==address(0),"Entered zeroaddress");
           voters[_addr]=Voter(_name,_addr,0,false);
    }
    function Righttovote(address _addr) public OnlyChairperson CreatedState {
          require(!voters[_addr].voted,"ALready voted");
          require(voters[_addr].weight==0);
          voters[_addr].weight=1;
     
    }
    
    function startvote() public OnlyChairperson {
          state=State.Voting;
    }
    function vote(uint candidate) public VotingState{
        Voter storage _voter=voters[msg.sender];
        require(_voter.weight!=0,"Not eligible for voting");
        require(!_voter.voted,"Alrdy voted");
        _voter.voted=true;
        candidates[candidate].votecount+=_voter.weight;
        
    }
    function endvote() public OnlyChairperson {
        state=State.Ended;
    }
    function RenounceChairperson(address _addr) public OnlyChairperson EndedState{
        require(_addr==address(0),"Entered zeroaddress");
        Chairperson=_addr;
        state=State.Created;
    }
}