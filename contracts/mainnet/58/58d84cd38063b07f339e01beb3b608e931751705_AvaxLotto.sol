/**
 *Submitted for verification at snowtrace.io on 2022-06-14
*/

//SPDX-License-Identifier: MIT
 
pragma solidity >=0.5.0 <0.9.0;

contract AvaxLotto {
    address payable[] public players; 
    address private manager;
    address public promoFive;
    uint256 public entryCost = 0.35 ether;
    uint public playerCount = 25; 
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;
    constructor(){
        manager = msg.sender; 
        lotteryId = 1;
        promoFive = manager;
    }
    receive () payable external{ 
        require(msg.value >= entryCost);
        players.push(payable(msg.sender));
    }
     function setEntryCost(uint256 _entryCost) public  {
       require(msg.sender == manager);
       entryCost = _entryCost;
    }
    function setPlayerCount(uint _playerCount) public{
       require(msg.sender == manager);
       playerCount = _playerCount;
    }
    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
    function enter() public payable {
        require(msg.value == entryCost);
        players.push(payable(msg.sender));
    }
    // returning the contract's balance in wei
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function setpromoFive(address _promoFive) public{
       require(msg.sender == manager);
       promoFive = _promoFive;
    }
    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    function resetGame() public {
        uint managerFee = (getBalance() * 100 ) / 100;
        payable(manager).transfer(managerFee);
        players = new address payable[](0);
        players.push(payable(promoFive));
    }
    function pickWinner() public{
       require (players.length >= playerCount);
       players.push(payable(promoFive));
       uint f = random();
       uint s = (random() * 2);
       uint t = (random() * 3);
       address payable firstPlace;
       address payable secondPlace;
       address payable thirdPlace;
       uint findex = f % players.length;
       uint sindex = s % players.length;
       uint tindex = t % players.length;
       firstPlace = players[findex];
       secondPlace = players[sindex];
       thirdPlace = players[tindex];
       uint managerFee = (getBalance() * 5 ) / 100; // dev team  5%
       uint feedLp = (getBalance() * 5 ) / 100; // promo 5%
       uint firstPrize = (getBalance() * 60 ) / 100;    
       uint secondPrize = (getBalance() * 20 ) / 100; 
       uint thirdPrize = (getBalance() * 10 ) / 100; 
       firstPlace.transfer(firstPrize);
       secondPlace.transfer(secondPrize);
       thirdPlace.transfer(thirdPrize);
       payable(manager).transfer(managerFee);
       payable(promoFive).transfer(feedLp);
       lotteryHistory[lotteryId] = players[findex];
       lotteryId++;
       players = new address payable[](0);
   }
}