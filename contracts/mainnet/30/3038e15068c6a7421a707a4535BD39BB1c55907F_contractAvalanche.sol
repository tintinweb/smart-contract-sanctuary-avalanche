/**
 *Submitted for verification at snowtrace.io on 2022-02-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract contractAvalanche {
   
address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    uint cooldownTime = 1 minutes;
    uint GuessFee = 0.0024 ether;
    string resultat = "Find my number.";

    struct tentative {
        uint essais;
        uint guessNumber;
        string resultat;
        uint readyTime;
    }

    mapping(address => tentative) Tentatives;

    function NbrTrialsAvailable() public view returns(uint) {
        return Tentatives[msg.sender].essais;
    }

    function viewResultat() public view returns(string memory) {
        return Tentatives[msg.sender].resultat;
    }

    function createNewTentative() public {
        require(Tentatives[msg.sender].readyTime <= block.timestamp);
        Tentatives[msg.sender].essais = 5;
        Tentatives[msg.sender].guessNumber = _generateRandomNumber();
        Tentatives[msg.sender].readyTime = (block.timestamp + cooldownTime);
    }

    function setLevelUpFee(uint _fee) external onlyOwner {
        GuessFee = _fee;
    }

    function _generateRandomNumber() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 100;
    }

    function getTotalBalances() external view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function guessNumber(uint _guessNumber) public payable {
        require(Tentatives[msg.sender].essais != 0, "You no longer have a try");
        require(msg.value >= GuessFee); 
        Tentatives[msg.sender].essais -= 1;
        uint _devLowdura = (GuessFee/100) * 3 ;
        Lowdura(_devLowdura);
        if(Tentatives[msg.sender].guessNumber == _guessNumber) {
            Tentatives[msg.sender].essais = 0;
            Tentatives[msg.sender].resultat = "Congratulation! You find";
            Withdrawl();
        }
        else{}
        if(Tentatives[msg.sender].guessNumber < _guessNumber) {
            Tentatives[msg.sender].resultat = "The number is lower..." ;
        }
        else{}
        if(Tentatives[msg.sender].guessNumber > _guessNumber) {
            Tentatives[msg.sender].resultat = "The number is upper..." ;
        }
        else{
        }
    }

    function Lowdura(uint _devLowdura) internal {
        payable(owner).transfer(_devLowdura);
    }

    function Withdrawl() internal {
            payable(msg.sender).transfer(address(this).balance);
    }
}