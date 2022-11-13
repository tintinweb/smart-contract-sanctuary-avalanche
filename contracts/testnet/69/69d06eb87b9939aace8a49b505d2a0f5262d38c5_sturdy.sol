/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error AccessDenied();
error PersonNotExist();

contract sturdy {
    //citiziens
    uint64 public citizienCount;
    mapping(address => string[]) private diagnoses;
    mapping(address => bool[]) private isHided;

    //admins
    mapping(address => bool) public isAdmin;

    //doctor
    mapping(address => bool) public isDoctor;

    constructor() payable {
        isAdmin[msg.sender] = true;
    }

    //events
    event newDiagnosis(address indexed patient);

    //modifiers
    modifier onlyAdmin() {
        checkAdmin();
        _;
    }

    modifier onlyDoctor() {
        checkDoctor();
        _;
    }

    //modifier functions
    function checkAdmin() internal view {
        if (!isAdmin[msg.sender]) {
            revert AccessDenied();
        }
    }

    function checkDoctor() internal view {
        if (!isDoctor[msg.sender]) {
            revert AccessDenied();
        }
    }

    //admin functions
    function assignAdmin(address personAddress) public onlyAdmin {
        isAdmin[personAddress] = true;
    }

    function dismissAdmin(address personAddress) public onlyAdmin {
        isAdmin[personAddress] = false;
    }

    function assignDoctor(address personAddress) public onlyAdmin {
        isDoctor[personAddress] = true;
    }

    function dismissDoctor(address personAddress) public onlyAdmin {
        isDoctor[personAddress] = false;
    }

    // doctor functions
    function addDiagnose(address patientAddress, string calldata diagnose)
        public
        onlyDoctor
    {
        diagnoses[patientAddress].push(diagnose);
        isHided[patientAddress].push(false);
        emit newDiagnosis(patientAddress);
    }

    function getPatientDiagnoses(address patientAddress)
        public
        view
        onlyDoctor
        returns (string[] memory)
    {
        return diagnoses[patientAddress];
    }

    // citizien functions
    function hideOrShowDiagnose(uint256 index, bool _isHided) public {
        isHided[msg.sender][index] = _isHided;
    }

    function getSelfDiagnoses() public view returns (string[] memory) {
        return diagnoses[msg.sender];
    }
}