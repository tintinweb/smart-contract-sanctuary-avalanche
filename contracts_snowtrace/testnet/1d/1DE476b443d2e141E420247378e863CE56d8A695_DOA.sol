/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.20;
// pragma experimental ABIEncoderV2;
// Higher gas price
// Contract Name: DOA
contract CreateProposal {
  uint private countYesVoters;
  uint private countNoVoters;

  struct Proposal{
    string proposalTitle;
    uint256 startDate;
    uint256 endDate;
    uint256 postedDate;
    string description;
    string documentURLs;
    bool status;
    address submittedBy;
    address[] whiteList;
  }

  struct VoteStruct{
    address voter;
    bool option;
    string votingTime;
  } 

  bool private value = false;
  Proposal private prop1;
  mapping (address => VoteStruct) private voterList;
  address[] private voter_result;
  VoteStruct[] private voterArray;
  address[] private yesVoters;
  address[] private noVoters;

  constructor(string memory _title,uint256 _startDate, uint256 _endDate, uint256 _postedDate, string memory _description,string memory _documentURLs, bool _status, address _submittedBy, address[] memory _whiteList) public {
    prop1 = Proposal(_title,_startDate, _endDate,_postedDate, _description,_documentURLs,_status,_submittedBy, _whiteList);
  }

  function proposalInfo()public view returns (string memory, uint256 ,uint256 , uint256 , string memory,string memory,bool ,address ) {
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    return(prop1.proposalTitle, prop1.startDate, prop1.endDate, prop1.postedDate, prop1.description, prop1.documentURLs,prop1.status,prop1.submittedBy);
  }
  
  //changed REMOVED
  function whiteLists() public view returns(address[] memory) {
    return (prop1.whiteList);
  }

  function validation_of_whitelist_addr() internal view returns(bool) {
    uint256 i = 0;
    address[] storage whiteListedAddr =  prop1.whiteList;
    for(i = 0; i < whiteListedAddr.length; i++ ) {
      if (whiteListedAddr[i] == msg.sender){
        return true;
      }
    }
    return false;
  }

  function cast_vote_for_proposal(bool _option, string memory _votingTime) public {
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    uint count = 0;
    for(uint i = 0; i < voter_result.length; i++ ) {
      if (voter_result[i] == msg.sender) {
        count++;
      }
    }
    if (count > 0){
      revert("Voting address already exists");
    }
    else {
      address votedBy = msg.sender;
      VoteStruct storage voter = voterList[votedBy];
      voter.option = _option;
      if (_option == true) {
        yesVoters.push(votedBy);
        countYesVoters = countYesVoters + 1;
        // if (countNum >= voter_result.length/2){
        // value = true;
        // }
      }
      else if (_option == false) {
        noVoters.push(votedBy);
        countNoVoters = countNoVoters + 1;
        // if (countNewNum voter_result.length/2){
        // value = false;
        // }
        }
        voter.votingTime = _votingTime;
        voterArray.push(VoteStruct(votedBy,_option,_votingTime));
        voter_result.push(votedBy) -1;
    }
    if (countNoVoters >= countYesVoters){
      value = false;
    }
    else{
      value = true;
    }
  }

  function proposalStatus() public view returns(bool) {
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    return value;
  }

  // function get_list_of_voters_for_proposal() view public returns (VoteStruct[] ) {
  // return voterArray;
  // }

  function get_yes_voter_list() public view returns (address[] memory){
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    return yesVoters;
  }

  function get_no_voter_list() public view returns (address[] memory){
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    return noVoters;
  }

  // function voter_info(address _address) view public returns (bool, string memory) {
  // return (voterList[_address].option, voterList[_address].votingTime);
  // }

  function get_total_casted_votes() public view returns (uint){
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    return voter_result.length;
  }

  function get_vote_percentage_on_proposal() public view returns(uint) {
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    uint count = 0;
    uint percentage = 0;
    for (uint i = 0; i < voter_result.length; i++) {
      address addr = voter_result[i];
      if (voterList[addr].option == true) {
        count++;
      }
    }
    percentage = count/voter_result.length;
    return percentage;
  }

  // function getValue() view public returns(bool) {
  // return value;
  // }

  function get_count_of_yes_voters() public view returns(uint) {
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    return countYesVoters;
  }

  function get_count_of_no_voters() public view returns(uint) {
    require(validation_of_whitelist_addr() == true, "Not a Whitelist Address");
    return countNoVoters;
  }  
}

contract DOA {
  struct ProposalStruct{
    string proposalTitle;
    uint256 startDate;
    uint256 endDate;
    uint256 postedDate;
    string description;
    string documentURLs;
    bool status;
    address submittedBy;
    address[] whiteList;
    // bool whiteLabelAddressCreateProposalPermission;
    // bool whiteLabelAddressVotePermission;
  }

  mapping(string => address) private allow;

  CreateProposal[] private createProposal;
  address[] private whiteLabelAddress;
  mapping (address => bool) private whiteLabelAddressCreateProposalPermission;
  mapping (address => bool) private whiteLabelAddressVotePermission;
  bool private isContractPaused = false;
  address private adminAddress;
  address[] private proposalList;
  mapping (address => uint256) private arrayIndexes;
  mapping (address => ProposalStruct) private proposalStruct;
  address[] private proposal_Info;

  constructor() public {
    adminAddress = msg.sender;
  }

  //follow naming conventions as per solidity
  function create_New_Proposal(string memory _title,uint256 _startDate, uint256 _endDate,uint256 _postedDate, string memory _description,string memory _documentURLs, bool _status, address _submittedBy) public {
    require(!isContractPaused, "Contract paused, no new proposals are accepted.");
    uint256 i = 0;
    while(i <= whiteLabelAddress.length) {
      if (msg.sender == whiteLabelAddress[i]) {
        if(whiteLabelAddressCreateProposalPermission[whiteLabelAddress[i]]==true) {
          CreateProposal prop = new CreateProposal(_title, _startDate, _endDate, _postedDate, _description,_documentURLs, _status, _submittedBy, get_list_of_whitelisted_address());
          ProposalStruct storage proposal = proposalStruct[prop];
          proposal.proposalTitle = _title;
          proposal.startDate = _startDate;
          proposal.endDate = _endDate;
          proposal.postedDate = _postedDate;
          proposal.description = _description;
          proposal.documentURLs = _documentURLs;
          proposal.status = _status;
          proposal.submittedBy = _submittedBy;
          proposal.whiteList = get_list_of_whitelisted_address();
          proposal_Info.push(prop) - 1;
          proposalList.push(prop);
          createProposal.push(prop);

          return;
        }
      }
      i++;
    }
  }

  function add_whitelist_address(address _address, bool canCreateProposal, bool canVote) public returns(bool) {
    require(msg.sender == adminAddress, "Only owner can do this");
    require(!isContractPaused, "Only owner can do this");
    uint count = 0;
    //change this array to mapping {address: boolean} //0 - no permission, 1 - can vote, 2 - can canCreateProposal, 3 - both
    for(uint i = 0; i < whiteLabelAddress.length; i++ ) {
      if (whiteLabelAddress[i] == _address){
        count++;
      }
    }
    if (count > 0) {
      revert("Address already exists");
    }
    else {
      uint id = whiteLabelAddress.length;
      arrayIndexes[_address] = id;
      whiteLabelAddress.push(_address);
      whiteLabelAddressCreateProposalPermission[_address] = canCreateProposal;
      whiteLabelAddressVotePermission[_address] = canVote;
    }
    return true;
  }

  function edit_whitelist_address(address _oldAddress, address _newAddress, bool canCreateProposal, bool canVote) public {
    require(msg.sender == adminAddress, "Only owner can do this");
    require(!isContractPaused, "Only owner can do this");
    uint count = 0;
    uint index;
    for(uint i = 0; i < whiteLabelAddress.length; i++ ) {
      if (whiteLabelAddress[i] == _oldAddress) {
        count++;
        index = i;
      }
    }
    if (count <= 0) {
      revert("Address not present");
    }
    else{
      whiteLabelAddress[index] = _newAddress;
      whiteLabelAddressCreateProposalPermission[_newAddress] = canCreateProposal;
      whiteLabelAddressVotePermission[_newAddress] = canVote;
    }
  }

  function delete_whitelist_address(address _address) public returns(bool) {
    require(msg.sender == adminAddress, "Only owner can do this");
    require(!isContractPaused, "Only owner can do this");
    uint count = 0;
    uint index;
    for(uint i = 0; i < whiteLabelAddress.length; i++ ) {
      if (whiteLabelAddress[i] == _address){
        count++;
        index = i;
      }
    }
    if (count <= 0){
      revert("Address not present");
    }
    else{
      delete whiteLabelAddress[index];
      delete whiteLabelAddressCreateProposalPermission[_address];
      delete whiteLabelAddressVotePermission[_address];
    }
    return true;
  }

  function pauseContract() public {
    require(msg.sender == adminAddress, "Only owner can do this");
    isContractPaused = true;
  }

  function resumeContract() public {
    require(msg.sender == adminAddress, "Only owner can do this");
    isContractPaused = false;
  }

  function get_list_of_whitelisted_address() view public returns(address[] memory) {
    return whiteLabelAddress;
  }

  // function get_proposal_details_by_proposal_address(address _address) view public returns (string memory, uint256 ,uint256 , uint256 , string memory,string memory,bool ,address ) {
  // return (proposalStruct[_address].proposalTitle,proposalStruct[_address].startDate, proposalStruct[_address].endDate,proposalStruct[_address].postedDate,proposalStruct[_address].description,proposalStruct[_address].documentURLs,proposalStruct[_address].status,proposalStruct[_address].submittedBy);
  // }

  function get_proposal_details_by_proposal_address(address addr) view public returns(string, uint,uint,uint,string,string,bool,address) {
    ProposalStruct memory u = proposalStruct[addr];
    return (
          u.proposalTitle,
          u.startDate,
          u.endDate,
          u.postedDate,
          u.description,
          u.documentURLs,
          u.status,//remove this key
          u.submittedBy
      );
  }

  function created_Proposal_list() public view returns(address[] memory) {//change name to getProposals
    return proposalList;
  }

  function is_super_admin(address add) public view returns(bool) {
    if(adminAddress == add) {
        return true;
    }else {
        return false;
    }
  } 

  //can be removed
  function checkOf(address add) public view returns(bool, bool) {
    return(whiteLabelAddressCreateProposalPermission[add], whiteLabelAddressVotePermission[add]);
  }

  //Remove this function
  // function delete_whitelisted_address(address addr) public {
  //     require(msg.sender == adminAddress, "Only owner can do this");
  //     require(!isContractPaused, "Only owner can do this");
  // uint id = arrayIndexes[addr];
  // delete whiteLabelAddress[id];
  // }


  //remove this
  // function get_total_passed_proposals() public view returns(uint) {
  // uint i;
  // uint count;
  // for(i = 0; i < proposalList.length; i++){
  // address addr = proposalList[i];

  // CreateProposal c = CreateProposal(addr);
  // if (c.proposalStatus() == true){
  // count++;
  // }
  // }
  // return count;
  // }
  // function get_passed_proposals(address addr) public view returns(bool){
  // CreateProposal c = CreateProposal(addr);
  // value = c.proposalStatus();
  // return value;
  // }
}