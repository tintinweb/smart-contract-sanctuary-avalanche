// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Resume {
    string public name;
    string public email;
    string public phone;
    string public summary;
    string public experience;
    string public education;

    constructor(string memory _name, string memory _email, string memory _phone, string memory _summary, string memory _experience, string memory _education) {
        name = _name;
        email = _email;
        phone = _phone;
        summary = _summary;
        experience = _experience;
        education = _education;
    }

    function updateSummary(string memory _summary) public {
        summary = _summary;
    }

    function updateExperience(string memory _experience) public {
        experience = _experience;
    }

    function updateEducation(string memory _education) public {
        education = _education;
    }

    function getResume() public view returns (string memory, string memory, string memory, string memory, string memory, string memory) {
        return (name, email, phone, summary, experience, education);
    }
}