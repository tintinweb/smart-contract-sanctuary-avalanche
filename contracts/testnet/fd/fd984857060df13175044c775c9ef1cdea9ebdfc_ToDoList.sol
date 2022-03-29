/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-28
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

contract ToDoList {
    struct item{
        string title;
        string note;
    }

    item[] public notes;

    item newNote;

    function setNote(string memory _title,string memory _note) public{
        newNote = item(_title,_note);
        notes.push(newNote);
    }

    function getNotes() public view returns(item[] memory){
        return notes;
    }

    function updateNote(string memory _title,string memory _note) public returns(bool){
        for(uint i =0 ;i<notes.length;i++){
            if(keccak256(abi.encodePacked(notes[i].title))== keccak256(abi.encodePacked(_title))){
                notes[i].note = _note;
                return true;
            }
        }

        return false;
    }

    function deleteNote(string memory _title) public returns(bool){
        for(uint i=0;i<notes.length;i++){
            if(keccak256(abi.encodePacked(notes[i].title))==keccak256(abi.encodePacked(_title))){
                notes[i] = notes[notes.length - 1];
                notes.pop();
                return true;
            }
        }

        return false;
    }
}