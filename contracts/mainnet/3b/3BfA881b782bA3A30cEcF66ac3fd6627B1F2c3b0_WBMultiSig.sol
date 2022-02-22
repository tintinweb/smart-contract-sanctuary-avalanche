// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
 * @author WyndBlast Team
 */
contract WBMultiSig {
  event Deposit(
    address indexed sender,
    uint amount,
    uint balance
  );

  event SubmitTransaction(
    address indexed owner,
    uint indexed txIndex,
    address indexed to,
    uint value,
    bytes data
  );

  event ConfirmTransaction(
    address indexed owner,
    uint indexed txIndex
  );

  event RevokeConfirmation(
    address indexed owner,
    uint indexed txIndex
  );

  event ExecuteTransaction(
    address indexed owner,
    uint indexed txIndex
  );

  event DailyLimitChange(uint dailyLimit);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event RequirementChange(uint required);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  uint public dailyLimit;
  uint public lastDay;
  uint public spentToday;

  address[] public owners;
  address private deployer;

  mapping(address => bool) public isOwner;
  uint public numConfirmationsRequired;

  uint constant public MAX_OWNER_COUNT = 50;

  struct Transaction {
    address to;
    uint value;
    bytes data;
    bool executed;
    uint numConfirmations;
  }

  mapping(uint => mapping(address => bool)) public isConfirmed;

  Transaction[] public transactions;

  modifier validAddress(address _address) {
    require(_address != address(0), "Address is nulled");
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    require(ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0, "Invalid requirement");
    _;
  }

  modifier ownerDoesNotExist(address owner) {
    require(!isOwner[owner], "Owner exists");
    _;
  }
  
  modifier ownerExists(address owner) {
    require(isOwner[owner], "Owner is not exists");
    _;
  }

  modifier onlyDeployer() {
    require(deployer == msg.sender, "Caller is not the deployer");
    _;
  }

  modifier isDeployer(address owner) {
    require(owner != deployer, "Can't remove deployer");
    _;
  }

  modifier onlyOwner() {
    require(isOwner[msg.sender] || deployer == msg.sender, "Unauthorized caller");
    _;
  }

  modifier txExists(uint _txIndex) {
    require(_txIndex < transactions.length, "Transaction does not exist");
    _;
  }
  
  modifier notExecuted(uint _txIndex) {
    require(!transactions[_txIndex].executed, "Transaction already executed");
    _;
  }

  modifier notConfirmed(uint _txIndex) {
    require(!isConfirmed[_txIndex][msg.sender], "Transaction already confirmed");
    _;
  }

  /**
   * @notice Default number of required confirmation is 1.
   * Default daily limit is 1000000000000000000 wei
   */
  constructor() {
    _transferOwnership(msg.sender);
    address owner = msg.sender;
    isOwner[owner] = true;
    owners.push(owner);
    numConfirmationsRequired = 1;
    dailyLimit = 1000000000000000000;
  }

  /**
   * @dev Internal check to make sure that amount is under limit
   * @return boolean
   */
  function _isUnderLimit(uint amount) internal returns (bool) {
    if (block.timestamp > lastDay + 24 hours) {
      lastDay = block.timestamp;
      spentToday = 0;
    }
    
    if (spentToday + amount > dailyLimit || spentToday + amount < spentToday) {
      return false;
    }
    
    return true;
  }

  /**
   * @notice Receive deposit of token
   */
  receive() external payable {
    emit Deposit(msg.sender, msg.value, address(this).balance);
  }

  /**
   * -------------------------------------------------------------------------------------- 
   * -------------------------------- OWNER FUNCTIONS -------------------------------------
   * --------------------------------------------------------------------------------------
   */

  /**
   * @notice Execute transaction, payout to recipient address
   * @param _to Recipient wallet address
   * @param _value Amount of token in wei
   * @param _data Some data that converted in to hex format
   */
  function submitTransaction(
    address _to,
    uint _value,
    bytes memory _data
  ) public onlyOwner {
    uint txIndex = transactions.length;

    transactions.push(
      Transaction({
        to: _to,
        value: _value,
        data: _data,
        executed: false,
        numConfirmations: 0
      })
    );

    emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
  }

  /**
   * @notice Confirm transaction or approve transaction by sender
   * @param _txIndex Transaction index
   */
  function confirmTransaction(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex)
  {
    Transaction storage transaction = transactions[_txIndex];
    transaction.numConfirmations += 1;
    isConfirmed[_txIndex][msg.sender] = true;

    emit ConfirmTransaction(msg.sender, _txIndex);
  }

  /**
   * @notice Execute transaction, payout to recipient address
   * @param _txIndex Transaction index
   */
  function executeTransaction(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
  {
    Transaction storage transaction = transactions[_txIndex];

    require(transaction.numConfirmations >= numConfirmationsRequired, "Cannot execute transaction");
    require(_isUnderLimit(transaction.value), "Maximum daily limit");

    transaction.executed = true;
    spentToday += transaction.value;

    (bool success, ) = transaction.to.call{value: transaction.value}(
      transaction.data
    );

    if (!success) {
      transaction.executed = false;
      spentToday -= transaction.value;
    }

    require(success, "Failed or insufficent funds");

    emit ExecuteTransaction(msg.sender, _txIndex);
  }

  /**
   * @notice Revoke confirmed transaction
   * @param _txIndex Transaction index
   */
  function revokeConfirmation(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
  {
    Transaction storage transaction = transactions[_txIndex];

    require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");

    transaction.numConfirmations -= 1;
    isConfirmed[_txIndex][msg.sender] = false;

    emit RevokeConfirmation(msg.sender, _txIndex);
  }

  /**
   * -------------------------------------------------------------------------------------- 
   * -------------------------------- PUBLIC FUNCTIONS ------------------------------------
   * --------------------------------------------------------------------------------------
   */

  /**
   * @notice Get owner addresses
   */
  function getOwners() public view returns (address[] memory) {
    return owners;
  }

  /**
   * @notice Get transaction count
   */
  function getTransactionCount() public view returns (uint) {
    return transactions.length;
  }

  /**
   * @notice Get transaction details
   * @param _txIndex Transaction index
   */
  function getTransaction(uint _txIndex)
    public
    view
    returns (
      address to,
      uint value,
      bytes memory data,
      bool executed,
      uint numConfirmations
    )
  {
    Transaction storage transaction = transactions[_txIndex];

    return (
      transaction.to,
      transaction.value,
      transaction.data,
      transaction.executed,
      transaction.numConfirmations
    );
  }

  /**
   * @notice Get contract balance
   */
  function getBalance() public view returns (uint) {
    return address(this).balance;
  }

  /**
   * @notice Get maximum withdraw amount.
   * @return Maximum amount today
   */
  function calcMaxWithdraw() public view returns (uint) {
    if (block.timestamp > lastDay + 24 hours) {
      return dailyLimit;
    }
    
    if (dailyLimit < spentToday) {
      return 0;
    }
    
    return dailyLimit - spentToday;
  }

  /**
   * @notice Get current deployer as owner of contract
   */
  function getDeployer() public view returns (address) {
    return deployer;
  }

  /**
   * -------------------------------------------------------------------------------------- 
   * ------------------------------ DEPLOYER FUNCTIONS ------------------------------------
   * --------------------------------------------------------------------------------------
   */
  
  /**
   * @notice Change daily limit
   * @param _dailyLimit Max of amount in wei
   */
  function changeDailyLimit(uint _dailyLimit) public onlyDeployer {
    dailyLimit = _dailyLimit;
    emit DailyLimitChange(_dailyLimit);
  }

  /**
   * @notice Add new owner
   * @param _owner Wallet address
   */
  function addOwner(address _owner) public
    onlyDeployer
    ownerDoesNotExist(_owner)
    validAddress(_owner)
    validRequirement(owners.length + 1, numConfirmationsRequired)
  {
    isOwner[_owner] = true;
    owners.push(_owner);
    emit OwnerAddition(_owner);
  }
  
  /**
   * @notice Remove owner from owners array
   * @param _owner Owner address
   */
  function removeOwner(address _owner)
    public
    onlyDeployer
    ownerExists(_owner)
    isDeployer(_owner)
  {
    isOwner[_owner] = false;
    
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[owners.length - 1];
        break;
      }
    }
    
    owners.pop();
    
    if (numConfirmationsRequired > owners.length) {
      changeRequirement(owners.length);
    }

    emit OwnerRemoval(_owner);
  }

  /**
   * @notice Change number of required confirmation
   * @param _required Number of required confirmation
   */
  function changeRequirement(uint _required)
    public
    onlyDeployer
    validRequirement(owners.length, _required)
  {
    numConfirmationsRequired = _required;
    emit RequirementChange(_required);
  }
  
  /**
   * @notice Leaves the contract without owner. It will not be possible to call 
   * `onlyDeployer` functions anymore. Can only be called by the current owner.
  */
  function renounceOwnership() public onlyDeployer {
    _transferOwnership(address(0));
  }
  
  /**
   * @notice Transfers ownership of the contract to a new account
   * @param newOwner New owner address
   */
  function transferOwnership(address newOwner) public onlyDeployer {
    require(newOwner != address(0), "Invalid new owner");
    _transferOwnership(newOwner);
  }
  
  /**
   * @notice Transfers ownership of the contract to a new account
   * @param newOwner New owner address
   */
  function _transferOwnership(address newOwner) internal {
    address oldOwner = deployer;
    deployer = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}