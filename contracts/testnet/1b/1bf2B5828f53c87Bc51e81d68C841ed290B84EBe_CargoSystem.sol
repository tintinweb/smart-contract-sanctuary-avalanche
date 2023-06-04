/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CargoSystem {

    struct Person {
        string nameSurname;
        uint256 phone;
        uint256 tckn;
        string eposta;
        string homeAddress;
    }

    struct Cargo {
        string company;
        string[] status;
    }

    address public owner;
    uint256 public personKeyMod = 10**16;
    uint256 public cargoMod = 10**10;

    // phone => person data(struct)
    mapping(uint256 => Person) public personData;
    // phone => person private key
    mapping(uint256 => uint256) public personPrivateKey;
    // phone => cargos
    mapping(uint256 => uint256[]) public personCargos;
    // cargoKey private key => cargo data(struct)
    mapping(uint256 => Cargo) public cargoData;

    constructor() { //sözleşme sahibi belirlendi.
        owner = msg.sender;
    }

    function getPerson(uint256 _phone) public view returns(Person memory) {
        return personData[_phone];
    }

    function getPersonPrivateKey(uint256 _phone) public view returns(uint256) {
        return personPrivateKey[_phone];
    }

    function getCargoData(uint256 _cargoKey) public view returns(Cargo memory) {
        return cargoData[_cargoKey];
    }

    function getPersonCargos(uint256 _phone) public view returns(uint256[] memory) {
        return personCargos[_phone];
    }

    //yeni kayıt oluştur
    function createNewPerson(
    string memory _nameSurname,
    uint256 _phone,
    uint256 _tckn,
    string memory _eposta,
    string memory _homeAddress) public {
        require(personData[_phone].phone != _phone, "Kayitli hesap var.");
        personData[_phone] = Person(_nameSurname, _phone, _tckn, _eposta, _homeAddress);
    }

    //mevcut kayıt güncelle
    function updatePerson(
    string memory _nameSurname,
    uint256 _phone,
    uint256 _tckn,
    string memory _eposta,
    string memory _homeAddress) public {
        require(personData[_phone].phone == _phone, "Kayitli hesap yok.");
        Person storage person = personData[_phone];
        person.nameSurname = _nameSurname;
        person.tckn = _tckn;
        person.eposta = _eposta;
        person.homeAddress = _homeAddress;
    }

    //kayıt olduktan sonra telefon numarasını şifreleyerek KTN oluştur
    function createKeccak(uint256 _phone) public {
        require(personData[_phone].phone == _phone, "Kayitli hesap yok.");
        require(personPrivateKey[_phone] <= 0, "Daha once olusturuldu.");
        uint256 rand = uint256(keccak256(abi.encodePacked(_phone)));
        uint256 key = rand % personKeyMod;
        personPrivateKey[_phone] = key;
    }

    //yeni kargo oluşturduktan sonra gösterilen "gönderi numarası"nı oluştur
    function createCargoNo(uint256 _phone, uint256 _personPrivateKey) public returns(uint256){
        require(personData[_phone].phone == _phone, "Kayitli hesap yok.");
        require(personPrivateKey[_phone] > 0, "Kisisel Takip Numarasi bulunamadi.");
        uint256 rand = uint256(keccak256(abi.encodePacked(_phone, _personPrivateKey)));
        uint256 key = rand % cargoMod;
        personCargos[_phone].push(key);
        return key;
    }
    //yeni kargo oluştur 
    function createCargo(uint256 _phone, uint256 _personPrivateKey, string memory _company) public {
        require(personData[_phone].phone == _phone, "Kayitli hesap yok.");
        require(personPrivateKey[_phone] > 0, "Kisisel Takip Numarasi bulunamadi.");
        uint256 cargoKey = createCargoNo(_phone, _personPrivateKey);
        Cargo storage cargo = cargoData[cargoKey];
        cargo.company = _company;
        cargo.status.push("Kargo Alindi.");
    }

    //kargo durumunu güncelle
    function updateCargoStatus(uint256 _cargoKey, string memory _status) public {
        require(cargoData[_cargoKey].status.length > 0, "Kisisel Takip Numarasi bulunamadi.");
        Cargo storage cargo = cargoData[_cargoKey];
        cargo.status.push(_status);
    }

}