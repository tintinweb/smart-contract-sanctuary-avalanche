/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract XDocumentLedger{
    
    event CreateNew(address indexed _owner, uint256 _docuId, uint256 _date);
    event Signed(address indexed _signer, uint256 _docuId, uint256 _date);
    event AddSigner(address indexed _owner, uint256 _docuId, uint256 _date);
    event Transaction(address indexed _owner, uint256 _docuId, uint256 _date);


    //metadata 
    struct docuInfo{
        address _owner;
        string _fileAddress;
        string _type;
        uint256 _date_created;
        uint256 _totalSigners;
        uint256 _totalSigned;
        bool _is_completed;
        uint256 _date_completed;
    }


    uint256 public DocuId;
    mapping(address => uint256[])  userDocuIds;
    mapping(address => uint256)  userDocuCtr;

    mapping(uint256 => address)  docOwnerById;
    mapping(uint256 => docuInfo) docuById;

    //add signer data tracker
    mapping(uint256 => mapping(address => bool)) docWhitelistedOwners;
    mapping(uint256 => mapping(address => bool)) docSignersTracker;
    //mapping(uint256 => uint8) docSignerCount;
    
    //mapping(uint256 => uint256) idToOwnerIndex;

    mapping(uint256 => mapping(uint256 => string)) docTxRecord;
    mapping(address => string)  userPasscode;
    mapping(uint256 => uint256)  docTxCounter;


    address payable owner;
    
    mapping(address => bool) activeAccoutns;
    
    constructor()  {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }


    function _addTransaction(uint256 _docId,  string memory _txData) internal returns(bool)   {

        //get...document transaction count
        uint256 _docCtr = docTxCounter[_docId] + 1;
        
        //set...latest transaction count
        docTxCounter[_docId] = _docCtr;

        //add transaction for document  
        docTxRecord[_docId][_docCtr] = _txData;


        //emit CreateNew(msg.sender, DocuId, block.timestamp);

        return true;
    }


    function AddTransaction(uint256 _docId, string memory _txData) public returns(bool)  {
        address _signer = msg.sender;

        //require(docWhitelistedOwners[_docId][_signer] == true, "invalid access");
        //require(docSignersTracker[_docId][_signer] == false, "already signed");


        _addTransaction(_docId, _txData);

        emit Transaction(_signer, _docId, block.timestamp);
        return true;
    }


    function viewDocumentReport(uint256 _docId, address _owner) public view returns(string[] memory history)   {

        //validate owner
        require(docOwnerById[DocuId] == _owner, "ivalid owner");

        //get...document transaction count
        uint256 _docCtr = docTxCounter[_docId];
        
        string[] memory _data = new string[](_docCtr);

        //add transaction for document  
        for(uint x=1; x <= _docCtr; x++){
            string storage _txData = docTxRecord[_docId][x];
            _data[x-1] = _txData;
        }

        return _data;
    }




    
    function CreateDoc(string memory _filesource, string memory _fileData) public returns(bool)   {
        DocuId += 1;
        
        docuInfo storage _newDoc = docuById[DocuId];
        _newDoc._owner = msg.sender;
        _newDoc._fileAddress = _filesource;
        _newDoc._type = "pdf";
        _newDoc._date_created = block.timestamp; 
        //_newDoc._status = 1; //status integer code {1,2,3,4,5}

        userDocuIds[msg.sender].push(DocuId);
        userDocuCtr[msg.sender] += 1;

        docOwnerById[DocuId] = msg.sender;

        //add transaction
        _addTransaction(DocuId, _fileData);

        emit CreateNew(msg.sender, DocuId, block.timestamp);

        return true;
    }

 
    
    function Sign(uint256 _docId, string memory _txData) public returns(bool)  {
        address _signer = msg.sender;

        //require(docWhitelistedOwners[_docId][_signer] == true, "invalid access");
        //require(docSignersTracker[_docId][_signer] == false, "already signed");

        docuInfo storage _signDoc = docuById[_docId];
        uint256 _ctr = _signDoc._totalSigned + 1;
        _signDoc._totalSigned = _ctr;

        _addTransaction(_docId, _txData);

        if(_ctr >= _signDoc._totalSigners){
            _signDoc._is_completed = true; //complete
            _signDoc._date_completed = block.timestamp;

            _addTransaction(_docId, "process completed");
        }



        emit Signed(_signer, _docId, block.timestamp);
        return true;
    }

    function AddSigners(uint256 _docId, string memory _txData, address _signer1, address _signer2, address _signer3) public returns(bool)   {
        
        require(docOwnerById[_docId] == msg.sender, "invalid document owner");

        docuInfo storage _docInfo = docuById[_docId];
        uint256 _ctr = _docInfo._totalSigners;


        if(_signer1 != address(0)){
            if(docWhitelistedOwners[_docId][_signer1] == false){
                _ctr += 1;
                docWhitelistedOwners[_docId][_signer1] = true;
            }
        }
        if(_signer2 != address(0)){
            if(docWhitelistedOwners[_docId][_signer2] == false){
                _ctr += 1;
                docWhitelistedOwners[_docId][_signer2] = true;
            }
        }
        if(_signer3 != address(0)){
            if(docWhitelistedOwners[_docId][_signer3] == false){
                _ctr += 1;
                docWhitelistedOwners[_docId][_signer3] = true;
            }
        }

        _docInfo._totalSigners = _ctr;

        _addTransaction(_docId, _txData);

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


    function getDocuInfo(uint256 _docId) public view returns(address docOwner, string memory fileSource, string memory fileType, uint256 dateCreated, uint256 totalSigners, uint256 totalSigned, bool isCompleted,  uint256 dateCompleted)
    {
        docuInfo storage _doc = docuById[_docId];
        return (_doc._owner, _doc._fileAddress, _doc._type, _doc._date_created, _doc._totalSigners, _doc._totalSigned, _doc._is_completed, _doc._date_completed);
    }



}