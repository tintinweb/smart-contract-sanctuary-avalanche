// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ToDoList {
    uint256 public IdUser;
    address public ownerOfContract;


    address[] public creators; //  ToDOListleri Oluşturlan kişilerin array deposunda tutulması
    string[] public message; // Oluşturlan ToDOListleri array deposunda tutulması
    uint256[] public messageId; // Message Numarası

    // Create Obejct keys and take key's value from users
    struct ToDoLists {
        address account;
        uint256 userId;
        string message;
        bool completed;

    }

    event ToDoevent(
        address indexed account,
        uint256 indexed userId,
        string message,
        bool complated
    );

    // Address göre o kişi ait tüm struct verilini alayım
    mapping (address => ToDoLists) public ToDoListApps;

    constructor() {
        ownerOfContract= msg.sender;
    }


    // Contract deploy eden address sayısınca IdUser artıran bir fanction bu function deger functionlarda çagırla bilinir
    function inc() internal {
        IdUser++;
    }

    function createList(string calldata _message) external{
        // Bu functio çağırıldıgında inc function devreye sok
        inc();
        uint256 idNumber = IdUser; //inc function çıktısını idNumbra ata

        ToDoLists storage toDo = ToDoListApps[msg.sender];// Bu function çagırıp ve TodoList değişiklik yapacak  kişin addresini al


        toDo.account = msg.sender;  // Stuct objectin account key sine msg.sender vaule atandı
        toDo.message = _message; //   Stuct objectin account key isine user girdiği değeri ekle
        toDo.completed =  false;
        toDo.userId = idNumber; // userId ile artırlan degeri ekle inc()

        // Alınan bu üç bilgiyi arraylere ekle
        creators.push(msg.sender);
        message.push(_message);
        messageId.push(idNumber);

        emit ToDoevent(msg.sender, toDo.userId, _message, toDo.completed);
        
        
    }
    function  getCreatorData(address _address) public view returns(address,uint256, string memory, bool){
        ToDoLists memory singleUserData = ToDoListApps[_address];

        return (
            singleUserData.account,
            singleUserData.userId,
            singleUserData.message,
            singleUserData.completed
        );
    }

    function getAddress() external view returns(address[] memory){
        return creators;
    }

    function getMessage() external view returns(string[] memory){
        return message;
    }

    function toggle(address _creator) public {
        ToDoLists storage singleUserData = ToDoListApps[_creator];
        singleUserData.completed =! singleUserData.completed;
    }



}