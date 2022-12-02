/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-01
*/

pragma solidity ^0.6.0;

contract ERC20Taxable {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowed;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    uint256 _totalSupply
  ) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _totalSupply;
    balances[msg.sender] = _totalSupply;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);

    // Calculate the transaction tax.
    uint256 transactionTax = _value * 1 / 100;

    // Deduct the transaction tax from the sender's balance.
    balances[msg.sender] = balances[msg.sender] - transactionTax;

    // Transfer the amount without the transaction tax to the recipient.
    balances[_to] = balances[_to] + _value - transactionTax;

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    // Calculate the transaction tax.
    uint256 transactionTax = _value * 1 / 100;

    // Deduct the transaction tax from the sender's balance.
    balances[_from] = balances[_from] - transactionTax;

    // Transfer the amount without the transaction tax to the recipient.
    balances[_to] = balances[_to] + _value - transactionTax;

    allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}