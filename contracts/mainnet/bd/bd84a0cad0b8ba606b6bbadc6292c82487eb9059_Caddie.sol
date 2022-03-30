/**
 *Submitted for verification at snowtrace.io on 2022-03-30
*/

pragma solidity ^0.4.16;
  

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Caddie is owned {
    
    string public name = "Caddie";
    string public symbol = "CVX-CU";
    address public t1 = 0xf693248F96Fe03422FEa95aC0aFbBBc4a8FdD172 ;
    address public t2 = 0xA32608e873F9DdEF944B24798db69d80Bbb4d1ed ;
    address[] public ingame;
    uint256 public cPlayers;
    uint256 public maxPlayers = 1;
    address public treasury;
    uint256 public registredPlayers = 0;
    address[] public hubs = [0x457e4858553C5A72398B08EeF686cb55441bdD00,0xE22B8bd01F7c7B69F3fc82ef22753AB4E3Df2636];
    uint256 hcount = 2;
    uint256 public workPeriod;


    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public tmprod;
    mapping (address => uint256) public cmprod;
    mapping (address => string) public info;
    mapping (address => uint256) public lastIn;
    mapping (address => uint256) public lastOut;
    mapping (address => bool) public isIn;

    
    event LogIn(address indexed player, uint256 timestamp);
    event LogOut(address indexed player, uint256 timestamp);
    event CommitProduction(address indexed player, uint256 timestamp, uint256 TUS, uint256 CRA);
    event PlayerAdded(address indexed player, uint256 timestamp);
    event PlayerRemoved(address indexed player, uint256 timestamp);
    event ForcedCollection(uint256 timestamp, string reason);
    
    constructor(
        address initialTreasury,
        uint256 periodh
    ) public {
        treasury = initialTreasury;
        workPeriod = periodh*3600;
    }

    function _popAddress(address[] aarray, address aelement) pure internal {
        for (uint256 i = 0; i < aarray.length ; i++) {
            if (aarray[i] == aelement) {
                aarray[i] = aarray[aarray.length - 1];
                delete aarray[aarray.length - 1];
            }
        }
    }

    function _collect(address player) internal {
        pERC20 tus = pERC20(t1);
        pERC20 cra = pERC20(t2);
        uint256 tb;
        uint256 cb;
        uint256 tp = 0;
        uint256 cp = 0;
        for (uint256 i = 0; i < hcount; i++) {
            tb = tus.balanceOf(hubs[i]);
            cb = cra.balanceOf(hubs[i]);
            require(tb >= 0);
            require(cb >= 0);
            tp += tb;
            cp += cb;
            tus.transferFrom(hubs[i],treasury,tb);
            cra.transferFrom(hubs[i],treasury,cb);
        }
        tmprod[player] += tp;
        cmprod[player] += cp;
        emit CommitProduction(player, now, tp, cp);        
    }
    
    function register(address _player, string _info) public onlyOwner returns (bool success) {
        require(balanceOf[_player] == 0);
        balanceOf[_player] = 1;
        info[_player] = _info;
        registredPlayers += 1;
        emit PlayerAdded(_player, now);
        return true;
    }

    function remove(address _player) public onlyOwner returns (bool success) {
        require(balanceOf[_player] > 0);   
        balanceOf[_player] = 0;            
        registredPlayers -= 1;                      
        emit PlayerRemoved(_player, now);
        return true;
    }

    function checkIn() public returns (bool success) {
        pERC20 tus = pERC20(t1);
        pERC20 cra = pERC20(t2);
        require(balanceOf[msg.sender] > 0);
        require(cPlayers < maxPlayers);
        for (uint256 i = 0; i < hcount; i++) {
            require(tus.balanceOf(hubs[i]) == 0);
            require(cra.balanceOf(hubs[i]) == 0);
        }
        ingame.push(msg.sender);
        isIn[msg.sender] = true;
        cPlayers += 1;
        lastIn[msg.sender] = now;
        emit LogIn(msg.sender,now);
        return true;
    }

    function checkOut() public returns (bool success) {       
        require(balanceOf[msg.sender] > 0);
        require(isIn[msg.sender]);
        require(now > lastIn[msg.sender] + workPeriod);
        _collect(msg.sender);       
        _popAddress(ingame,msg.sender);
        cPlayers -= 1;
        lastOut[msg.sender] = now;
        emit LogOut(msg.sender,now);
        return true;
    }

    function forceOut(address player) public onlyOwner returns (bool success) {
        require(balanceOf[player] > 0);
        require(isIn[player]);
         _collect(player);       
        _popAddress(ingame,player);
        cPlayers -= 1;
        lastOut[player] = now;
        emit LogOut(player,now);
        return true;
    }

    function forceCollection(string reason) public onlyOwner returns (bool success) {
        _collect(msg.sender);
        emit ForcedCollection(now,reason);
        return true;
    }

    function changet1(address _t1) public onlyOwner returns (bool success) {
        t1 = _t1;
        return true;
    }

    function changet2(address _t2) public onlyOwner returns (bool success) {
        t2 = _t2;
        return true;
    }

    function changeTreasury(address _treasury) public onlyOwner returns (bool success) {
        treasury = _treasury;
        return true;
    }

    function changeMaxPlayers(uint256 newNumber) public onlyOwner returns (bool success) {
        maxPlayers = newNumber;
        return true;
    }

     function changePeriod(uint256 newPeriodh) public onlyOwner returns (bool success) {
        workPeriod = newPeriodh*3600;
        return true;
    }

    function addHub(address newHub) public onlyOwner returns (bool success) {
        hubs.push(newHub);
        hcount += 1;
        return true;
    }

    function removeHub(address quitHub) public onlyOwner returns (bool success) {
        _popAddress(hubs,quitHub);
        hcount -= 1;
        return true;
    }

    function hubsFullApproval() public returns (bool success) {
        pERC20 tus = pERC20(t1);
        pERC20 cra = pERC20(t2);
        tus.approve(this, tus.totalSupply());
        cra.approve(this, cra.totalSupply());
        return true;
    }

}

interface pERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}