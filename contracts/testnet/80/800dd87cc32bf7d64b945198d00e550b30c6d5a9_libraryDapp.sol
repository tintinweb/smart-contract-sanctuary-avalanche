/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract libraryDapp {
    address private owner;

    enum Category{ DEV, NFT, MARKET, PRICE, LAYER2, LAUNCH }

    struct Source {
        string url; 
        string description;
        string header;  
        address from; 
        Category cat;
        uint256 creationDate;
    }

    uint256 SourceCount = 0;

    mapping(uint256 => Source) public Sources;
    mapping(address => bool) public Permissions;

    modifier onlyOwner() {
        require(msg.sender == owner, "sadece kontrat sahibi bu fonksiyonu cagirabilir");
        _;
    }

    modifier validCategory(Category _cat) {
        require(Category.LAUNCH > _cat, "kategori yanlis secildi.");
        _;
    }

    modifier validPermission() {
        require(Permissions[msg.sender] == true, "kaynak girme izni verilmemis");
        _;
    }

    modifier permNotGiven(address _add) {
        require(Permissions[_add] == false, "bu adrese izin verilmis.");
        _;
    }

    modifier permGiven(address _add) {
        require(Permissions[_add] == true, "bu adrese izin verilmemis.");
        _;
    }

    modifier sourceExist(uint256 _id) {
        require(_id < SourceCount, "bu numarali kayit yoktur.");
        _;
    }

    constructor() {
        owner = msg.sender;
        Permissions[owner] = true;
    }

    function AddSource(string memory _url, string memory _description, string memory _header, Category _cat) public 
    validCategory(_cat) validPermission {       
        Source memory tempSource = Source(_url, _description, _header, msg.sender, _cat, block.timestamp);
        Sources[SourceCount] = tempSource;
        SourceCount++;
    }

    function GetSourceByID(uint256 _id) public view sourceExist(_id) returns(Source memory) {
        return Sources[_id];
    }

    function GetSourceByCategory(Category _cat) public view validCategory(_cat) returns(Source[] memory) {
        uint16 returnCount = 0;

        for (uint16 i = 0; i < SourceCount; i++) {
            Source memory tempSource = Sources[i];
            if(tempSource.cat == _cat) {
                returnCount++;
            }
        }

        Source[] memory returnSources = new Source[](returnCount);

        for (uint16 i = 0; i < SourceCount; i++) {
            Source memory tempSource = Sources[i];
            returnSources[i] = tempSource;
        }

        return returnSources;
    }

    function GetSourceByCategoryNotRead(Category _cat) public view validCategory(_cat) returns(Source[] memory) {
        uint16 returnCount = 0;

        for (uint16 i = 0; i < SourceCount; i++) {
            Source memory tempSource = Sources[i];
            if(tempSource.cat == _cat) {
                returnCount++;
            }
        }

        Source[] memory returnSources = new Source[](returnCount);

        for (uint16 i = 0; i < SourceCount; i++) {
            Source memory tempSource = Sources[i];
            returnSources[i] = tempSource;
        }

        return returnSources;
    }

    function SetSourceRead(uint _id) public {

    } 

    function AskPermission() public permNotGiven(msg.sender) {
        Permissions[msg.sender] = false;
    }

    function GivePermission(address permToGive) public onlyOwner permGiven(msg.sender) {
        Permissions[permToGive] = true;
    }

    
}