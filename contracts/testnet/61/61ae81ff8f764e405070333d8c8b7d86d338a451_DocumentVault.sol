/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DocumentVault{
    
    event Transaction(address indexed _owner, uint256 _docuId, uint256 _date);
    

    //metadata 
    struct docuInfo{
        address owner;
        string fileChecksum;
        string fileName;
        uint256 date_created;
    }


    uint256 public FileId;
    mapping(uint256 => docuInfo) docuById;
    mapping(address => uint256[])  userDocuIds;
    mapping(address => uint256)  userDocuCtr;

    
    
    address payable owner;
    
    constructor()  {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }

    
    function CreateDoc(string memory _checksum, string memory _filename) public returns(bool)   {
        FileId += 1;
        
        docuInfo storage _newDoc = docuById[FileId];
        _newDoc.owner = msg.sender;
        _newDoc.fileName = _filename;
        _newDoc.fileChecksum = _checksum;
        _newDoc.date_created = block.timestamp;

        //track all file IDs of each user
        userDocuIds[msg.sender].push(FileId);

        //track total files uploaded by user
        userDocuCtr[msg.sender] += 1;

        emit Transaction(msg.sender, FileId, block.timestamp);

        return true;
    }

    function userTotalDocuments(address _address) public view returns(uint256){
        return userDocuCtr[_address];
    }

    function getOwnerDocIds(address _owner) public view returns(uint256[] memory)
    {
        return userDocuIds[_owner];
    }

    function getDocuInfo(uint256 _docId) public view returns(address docOwner, string memory fileName, string memory fileChecksum, uint256 dateCreated)
    {
        docuInfo storage _doc = docuById[_docId];
        return (_doc.owner, _doc.fileName, _doc.fileChecksum, _doc.date_created);
    }



}