// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract TodoContract {
    struct Notes {
        uint256 id;
        address owner;
        string note;
        bool completed;
    }

    event addNotes(address owner, uint256 id);
    event deleteNotes(uint256 _id, bool isDeleted);

    Notes[] private notes;

    mapping(uint256 => address) notesMapping;

    modifier onlyOwner(uint256 _id) {
        require(
            notes[_id - 1].owner == msg.sender,
            "Only owner can perform this action"
        );
        _;
    }

    function addNote(string memory _note, address _owner) external {
        uint256 id = notes.length + 1;
        notes.push(Notes(id, _owner, _note, false));
        notesMapping[id] = _owner;
        emit addNotes(_owner, id);
    }

    function getNotes(address _owner) external view returns (Notes[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == _owner) {
                count++;
            }
        }
        Notes[] memory myNotes = new Notes[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == _owner) {
                myNotes[index] = notes[i];
                index++;
            }
        }
        return myNotes;
    }

    function getNumberOfNotes(address _owner) external view returns (uint256) {
        address owner = _owner;
        uint256 count = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner) {
                count++;
            }
        }
        return count;
    }

    function getNotesWithId(uint256 _id, address _owner) external view returns (Notes memory) {
        Notes storage note = notes[_id - 1];
        require(
            note.owner == _owner,
            "Only note owner can access this note"
        );
        return note;
    }

    function toggleComplete(uint256 _id, address _owner) external {
        Notes storage note1 = notes[_id - 1];
        require(
            note1.owner == _owner,
            "Only note owner can toggle completeness of this note"
        );
        note1.completed = !note1.completed;
    }

    function getCompletedNotes(address _owner) external view returns (Notes[] memory) {
        address owner = _owner;
        Notes[] memory temp = new Notes[](notes.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner && notes[i].completed == true) {
                temp[counter] = notes[i];
                counter++;
            }
        }
        Notes[] memory result = new Notes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temp[i];
        }
        return result;
    }

    function getIncompleteNotes(address _owner) external view returns (Notes[] memory) {
        address owner = _owner;
        uint256 counter = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner && notes[i].completed == false) {
                counter++;
            }
        }
        Notes[] memory result = new Notes[](counter);
        counter = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner && notes[i].completed == false) {
                result[counter] = notes[i];
                counter++;
            }
        }
        return result;
    }

    function updateNotes(uint256 _id, string memory content, address _owner) external {
        Notes storage note1 = notes[_id - 1];
        require(
            note1.owner == _owner,
            "Only note owner can update this note"
        );
        note1.note = content;
    }

    function deleteNote(uint256 _id, address _owner) external {
        Notes storage note1 = notes[_id - 1];
        require(
            note1.owner == _owner,
            "Only note owner can delete this note"
        );
        delete notes[_id - 1];
    }
}