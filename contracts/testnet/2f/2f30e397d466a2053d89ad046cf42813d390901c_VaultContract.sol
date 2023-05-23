/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultContract{
    event Transaction(address indexed _owner, string _docuId, uint256 _date);

    mapping(string => mapping(address => documentInfo)) documents;
    struct documentInfo
    {
        string fileId;
        address owner;
        metaDataDetail[] metadatas;

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
    function addMetaData(string memory _fileId, string memory _key, string memory _value) public returns(bool)   {

        documentInfo storage docInfo = documents[_fileId][msg.sender];
        docInfo.owner = msg.sender;
        docInfo.fileId = _fileId;
        docInfo.metadatas.push(metaDataDetail(_key,_value));

        emit Transaction(msg.sender, _fileId, block.timestamp);

        return true;
    }

    function getMetaDataValue(string memory _fileId) public view returns( string memory fileId,address docOwner, metaDataDetail[] memory metadatas)
    {
        documentInfo storage dataInfo = documents[_fileId][msg.sender];
        return ( dataInfo.fileId, dataInfo.owner, dataInfo.metadatas);
    }



}