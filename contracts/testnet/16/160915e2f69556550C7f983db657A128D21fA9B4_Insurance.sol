/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Insurance {

enum Status{
    Pending,
    Success
}

struct Person{
    string key;
    string name;
    address owner;
    Status status;
    string[] data;
}

mapping(uint => Person) private PersonData;
event RequiredPerson(uint indexed requestId);
event SentPerson(uint indexed requestId);
event SuccessPerson(uint indexed requestId);
uint public requestId;

modifier onlyOwner(uint _requestId) {
    Person memory person = PersonData[_requestId];
    require(msg.sender == person.owner, "not owner");
    _;
}

modifier onlyPending(uint _requestId) {
    Person memory person = PersonData[_requestId];
    require( Status.Pending == person.status , "not pending");
    _;
}

constructor() {
    requestId = 0;
}

function getPerson(uint _requestId) public view onlyOwner(_requestId) returns(Person memory){
    return PersonData[_requestId];
} 

function requirePersonHistory(string memory _key, string memory _name) public returns(uint) {   
    uint id = requestId; 
    string[] memory data;
    PersonData[id] = Person(_key, _name, msg.sender, Status.Pending, data);
    requestId++;
    emit RequiredPerson(id);
    return id;
} 

function sendPersonHistory(uint _requestId, string memory _data) public onlyPending(_requestId) returns(bool) {    
    Person storage person = PersonData[_requestId];
    person.data.push(_data);
    PersonData[_requestId] = person;
    emit SentPerson(_requestId);
    return true;
} 

function successPersonHistory(uint _requestId) external onlyOwner(_requestId) returns(bool) {    
    Person storage person = PersonData[_requestId];
    person.status = Status.Success;
    PersonData[_requestId] = person;
    emit SuccessPerson(_requestId);
    return true;
} 

}