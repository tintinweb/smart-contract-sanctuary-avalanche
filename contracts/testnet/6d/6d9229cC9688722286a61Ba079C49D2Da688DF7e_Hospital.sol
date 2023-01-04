/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-03
*/

// File: contracts/hospital.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Hospital {
    struct Patient {
        string name;
        uint age;
        string disease;
    }
    mapping(uint => Patient) public patients;
    uint public patientCount;

    function addPatient(string memory _name, uint _age, string memory _disease) public {
        patientCount++;
        patients[patientCount] = Patient(_name, _age, _disease);
    }

    function getPatient(uint _id) public view returns (string memory, uint, string memory) {
        Patient memory patient = patients[_id];
        return (patient.name, patient.age, patient.disease);
    }

    function updatePatient(uint _id, string memory _name, uint _age, string memory _disease) public view {
        Patient memory patient = patients[_id];
        patient.name = _name;
        patient.age = _age;
        patient.disease = _disease;
    }

    function deletePatient(uint _id) public {
        delete patients[_id];
    }
}