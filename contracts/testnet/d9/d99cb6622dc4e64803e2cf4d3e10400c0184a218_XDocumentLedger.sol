/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract XDocumentLedger{
    
    event CreateNew(address indexed _owner, uint256 _docuId, uint256 _date);
    event Signed(address indexed _signer, uint256 _docuId, uint256 _date);
    event AddSigner(address indexed _owner, uint256 _docuId, uint256 _date);


    //metadata 
    struct docuInfo{
        address _owner;
        string _fileAddress;
        string _type;
        uint256 _status;
        uint256 _date_created;
    }


    uint256 public DocuId;
    mapping(address => uint256[])  userDocuIds;
    mapping(address => uint256)  userDocuCtr;
    mapping(uint256 => docuInfo) docuById;
    mapping(uint256 => address[]) docuSharedToUser;
    
    mapping(uint256 => uint256) idToOwnerIndex;
    


    address payable owner;
    
    mapping(address => bool) activeAccoutns;
    
    constructor()  {
        owner = payable(msg.sender);

        //stakingIsOpen  = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }
    
    function CreateDoc(string memory _filesource, string memory _filetype) public returns(bool)   {
        DocuId += 1;
        
        docuInfo storage _newDoc = docuById[DocuId];
        _newDoc._owner = msg.sender;
        _newDoc._fileAddress = _filesource;
        _newDoc._type = _filetype;
        _newDoc._date_created = block.timestamp; 
        _newDoc._status = 1; //status integer code {1,2,3,4,5}

        userDocuIds[msg.sender].push(DocuId);
        userDocuCtr[msg.sender] += 1;

        emit CreateNew(msg.sender, DocuId, block.timestamp);

        return true;
    }
    
    
    function Sign(uint256 _docId, address _from) public returns(bool)  {
        address _signer = msg.sender;

        //check document if exist
        docuInfo storage _signDoc = docuById[_docId];
        require(_signDoc._owner == _from, "document not found");

        bool _validate = false;
        for (uint i = 0; i < docuSharedToUser[_docId].length; i++) {
            if (docuSharedToUser[_docId][i] == _signer) {
                _validate = true;
            }
        }

        require(_validate == true, "unauthorized access");
        
        _signDoc._status += 1;

        emit Signed(_signer, _docId, block.timestamp);
        return true;
    }

    function AddSigners(uint256 _docId, address _signer1, address _signer2, address _signer3) public returns(bool)   {
        docuInfo storage _getDoc = docuById[_docId];
        require(_getDoc._owner == msg.sender, "invalid document owner");

        if(_signer1 != address(0)){
            docuSharedToUser[_docId].push(_signer1);
        }
        if(_signer2 != address(0)){
            docuSharedToUser[_docId].push(_signer2);
        }
        if(_signer3 != address(0)){
            docuSharedToUser[_docId].push(_signer3);
        }

        emit AddSigner(msg.sender, _docId, block.timestamp);

        return true;
    }

    
    function userTotalDocuments(address _address) public view returns(uint256){
        return userDocuCtr[_address];
    }

    function getOwnerDocIds(address _owner) public view returns(uint256[] memory)
    {
        return userDocuIds[_owner];
    }


    function docuSharedToUsers(uint256 _docId) public view returns(address[] memory)
    {
        return docuSharedToUser[_docId];
    }

    function getDocuInfo(uint256 _docId) public view returns(address _owner, string memory _Source, string memory _type, uint256 _status,  uint256 _date_created)
    {
        docuInfo storage _doc = docuById[_docId];
        return (_doc._owner, _doc._fileAddress, _doc._type, _doc._status, _doc._date_created);
    }



}