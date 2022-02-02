/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-02
*/

pragma solidity ^0.8.11;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "./HurricaneCashDeposit.sol";

contract HurricaneCashFactory {

    address[] public contractList;

    mapping(uint => uint) public encryptedDeposits;
    mapping(address => bool) public allowedWallets;


    function setEncryption(address depositOwner,uint value) external returns(uint){
        require(allowedWallets[msg.sender] == true);
        uint encryptedKey = uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,depositOwner,value,"5")));
        encryptedDeposits[encryptedKey] = value;
        return encryptedKey;
    }

    constructor(){

    }

    function CreateSubContracts() public {
        //for (uint256 index = 0; index < 10; index++) {
            HurricaneCashDeposit newContract = HurricaneCashDeposit(msg.sender);
            contractList.push(address(newContract));
            allowedWallets[address(newContract)] = true;

        //}
    }


}

contract HurricaneCashDeposit {
    //mapping(uint => uint) public encryptedDeposits;

    HurricaneCashFactory Factory;

    constructor(){
        Factory = HurricaneCashFactory(msg.sender);
    }

   function deposit() public payable returns(uint){
       //require(msg.value > 0.01 ether);
     return Factory.setEncryption(msg.sender,msg.value);
   }

   //function withdraw(uint _encryptedValue) public {
    //   uint amount = encryptedDeposits[_encryptedValue];
    //   payable(msg.sender).transfer(amount);
   //    encryptedDeposits[_encryptedValue] = 0;
   //}


}