/**
 *Submitted for verification at snowtrace.io on 2022-08-11
*/

//SPDX-License-Identifier: MIT
 
pragma solidity >=0.5.0 <0.9.0;

contract CryptoBroskiLuck{
    address payable[] public players; 
    address private manager;
    address public cbPool;
    uint256 public entryCost = 0.1 ether;
    uint256 public playerCount = 5; 
    uint256 public lotteryId;
    mapping (uint256 => address payable) public lotteryHistory;
    constructor(){
        manager = msg.sender; 
        lotteryId = 1;
        cbPool = manager;
    }
    receive () payable external{    
    }
    function setEntryCost(uint256 _entryCost) public  {
       require(msg.sender == manager);
       entryCost = _entryCost;
    }
    function setPlayerCount(uint256 _playerCount) public{
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
    function enterPlayer(address player) public payable{
        require(msg.sender == manager);
        players.push(payable(player));
    }
    // returning the contract's balance in wei
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function setCbPool(address _cbPool) public{
       require(msg.sender == manager);
       cbPool = _cbPool;
    }
    function getWinnerByLottery(uint256 lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function random() internal view returns(uint256){
       return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    function resetGame() public {
        require(msg.sender == manager);
        uint256 managerFee = (getBalance() * 100 ) / 100;
        payable(manager).transfer(managerFee);
        players = new address payable[](0);
        players.push(payable(cbPool));
    }
    function size() public view returns(uint256){
            return players.length;
    }
   
    function pickWinner() public{
       require (players.length >= playerCount);
       players.push(payable(cbPool));
       uint256 f = random();
       uint256 s = (random() * 2);
       uint256 t = (random() * 3);
       address payable firstPlace;
       address payable secondPlace;
       address payable thirdPlace;
       uint256 findex = f % players.length;
       uint256 sindex = s % players.length;
       uint256 tindex = t % players.length;
       firstPlace = players[findex];
       secondPlace = players[sindex];
       thirdPlace = players[tindex];
       uint256 managerFee = (getBalance() * 5 ) / 100; // Dev/Marketin/LottoReload 5%
       uint256 feedLp = (getBalance() * 5 ) / 100; // LP/ Equiptment 5%
       uint256 firstPrize = (getBalance() * 60 ) / 100;   
       uint256 secondPrize = (getBalance() * 20 ) / 100; 
       uint256 thirdPrize = (getBalance() * 10 ) / 100; 
       firstPlace.transfer(firstPrize);
       secondPlace.transfer(secondPrize);
       thirdPlace.transfer(thirdPrize);
       payable(manager).transfer(managerFee);
       payable(cbPool).transfer(feedLp);
       lotteryHistory[lotteryId] = players[findex];
       lotteryId++;
       players = new address payable[](0);
   }
}