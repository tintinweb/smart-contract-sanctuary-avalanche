// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CertificateAvalanche {
    struct Certificate {
        address owner;
        string adminAddress;
        string studentAddress;
        string studentFirstName;
        string studentLastName;
        string category;
        string title;
        string description;
        string image;
        string released;
        string signature;
    }

    mapping(uint256 => Certificate) public certificates;

    uint256 public numberOfCertificates = 0;

    function createCertificate(
        address _owner,
        string memory _adminAddress,
        string memory _studentAddress,
        string memory _studentFirstName,
        string memory _studentLastName,
        string memory _category,
        string memory _title,
        string memory _description,
        string memory _image,
        string memory _signature,
        string memory _released
    ) public returns (uint256) {
        Certificate storage certificate = certificates[numberOfCertificates];

        certificate.owner = _owner;
        certificate.adminAddress = _adminAddress;
        certificate.studentAddress = _studentAddress;
        certificate.studentFirstName = _studentFirstName;
        certificate.studentLastName = _studentLastName;
        certificate.category = _category;
        certificate.title = _title;
        certificate.description = _description;
        certificate.image = _image;
        certificate.signature = _signature;
        certificate.released = _released;

        numberOfCertificates++;

        return numberOfCertificates - 1;
    }

    function getCertificates() public view returns (Certificate[] memory) {
        Certificate[] memory allCertificates = new Certificate[](
            numberOfCertificates
        );

        for (uint i = 0; i < numberOfCertificates; i++) {
            Certificate storage item = certificates[i];

            allCertificates[i] = item;
        }
        return allCertificates;
    }
}