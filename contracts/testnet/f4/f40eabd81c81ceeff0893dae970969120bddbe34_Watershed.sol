/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-27
*/

pragma solidity ^0.8.0;

contract Watershed {

  // The total supply of Watershed tokens
  uint256 public totalSupply;

  // The mapping from addresses to the number of Watershed tokens they hold
  mapping(address => uint256) public balances;

  // The address that receives the transfer tax
  address public transferTaxRecipient;

  // The constructor sets the initial supply of Watershed tokens
  constructor(uint256 initialSupply) {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
  }

  // Function to burn Watershed tokens
  function burn(uint256 amount) public {
    require(amount <= balances[msg.sender]);
    balances[msg.sender] -= amount;
    totalSupply -= amount;
    emit Burn(msg.sender, amount);
  }

  // Function to set the transfer tax
  function setTransferTax(address recipient) public {
    require(msg.sender == address(this));
    transferTaxRecipient = recipient;
  }

  // Function to whitelist a wallet that does not have to pay the transfer tax
  function whitelist(address wallet) public {
    require(msg.sender == address(this));
    whitelists[wallet] = true;
  }

  // Function to pause the contract
  function pause() public {
    require(msg.sender == address(this));
    paused = true;
  }

  // Function to resume the contract
  function resume() public {
    require(msg.sender == address(this));
    paused = false;
  }

  // Function to transfer Watershed tokens
  function transfer(address to, uint256 amount) public returns (bool success) {
    require(!paused);
    require(to != address(0));
    require(amount <= balances[msg.sender]);

    // Calculate the transfer tax
    uint256 tax = amount * 0.25e16;

    // If the recipient is whitelisted, they do not have to pay the transfer tax
    if (whitelists[to]) {
      tax = 0;
    }

    // Transfer the tokens
    balances[msg.sender] -= amount;
    balances[to] += amount;

    // Send the transfer tax to the recipient
    address payable taxRecipient = payable(transferTaxRecipient);
    taxRecipient.transfer(tax);

    emit Transfer(msg.sender, to, amount);
    return true;
  }

  // Events to track changes to the contract
  event Burn(address indexed burner, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Modifiers to prevent certain actions from being performed when the contract is paused
  modifier onlyWhenNotPaused() {
    require(!paused);
    _;
  }

  // Modifier to prevent only the contract owner from performing certain actions
  modifier onlyOwner() {
    require(msg.sender == address(this));
    _;
  }

  // Mapping of addresses to whether they are whitelisted
  mapping(address => bool) public whitelists;

  // Boolean flag to indicate whether the contract is paused
  bool public paused;

}