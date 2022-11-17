// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract SimpleRetrieve { 
 
  struct People {    
    string  name;
    string country; 
    string city; 
    uint age;
    string gender; 
    string profession;

  }


  // An array is a list, below is a dynamic array:
  People[] internal people; 

  mapping(string => string) public NameToCountry; 
  mapping(string => string) public NameToCity; 
  mapping(string => uint) public NameToAge;
  mapping(string => string) public NameToGender;
  mapping(string => string)public NameToProfession; 


  

function addPerson (
  string memory _name, 
  string memory _country, 
  string memory _city,
  uint   _age, 
  string  memory _gender,
  string memory  _profession) 
  external  { 
  people.push(People(_name, _country, _city, _age, _gender, _profession)); 
  NameToCountry[_name]  = _country; 
  NameToCity[_name] = _city; 
  NameToAge[_name] = _age; 
  NameToGender[_name] = _gender; 
  NameToProfession[_name] = _profession;




}

}