/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultContract{
    event Transaction(address indexed _owner, string _docuId, uint256 _date);

    mapping(string => mapping(address => documentInfo)) userDocuments;
    mapping(address => string[])  userDocumentIds;
    mapping(string =>  documentInfo) documents;
    struct documentInfo
    {
        string fileId;
        bool authoritative;
        address owner;
        metaDataDetail[] metadatas;
        bool isDocument;

    }
    struct metaDataDetail
    {
        string key;
        string value;
    }

    address payable owner;
    
    constructor()  {
        owner = payable(msg.sender);
    }

    
    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }
    function addMetaData(string memory _fileId, bool _authoritative, metaDataDetail[] memory metadatas) public returns(bool)   {

        documentInfo storage docInfo = userDocuments[_fileId][msg.sender];
        //if not exist
        if(docInfo.isDocument == true)
        {
            if(docInfo.authoritative)
            {
                require(msg.sender == docInfo.owner, "Owner can only update authoritative files");
            }
            delete docInfo.metadatas;
        }
        else{
            userDocumentIds[msg.sender].push(_fileId);
        }
        docInfo.owner = msg.sender;
        docInfo.isDocument = true;
        docInfo.authoritative = _authoritative;
        docInfo.fileId = _fileId;
        for (uint256 i = 0; i < metadatas.length; i++)
        {
            docInfo.metadatas.push(metadatas[i]);
        }
        documents[_fileId] = docInfo;
        emit Transaction(msg.sender, _fileId, block.timestamp);

        return true;
    }

    function getMetaDataValue(string memory _fileId) public view returns( string memory fileId,address docOwner, bool authoritative, metaDataDetail[] memory metadatas)
    {
        documentInfo storage dataInfo = documents[_fileId];
        return ( dataInfo.fileId, dataInfo.owner, dataInfo.authoritative, dataInfo.metadatas);
    }

    function getUserDocumentIds(address _address) public  view returns (string[] memory fileIds)
    {
        return userDocumentIds[_address];
    }

}