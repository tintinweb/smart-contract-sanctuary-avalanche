// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
 * @author WyndBlast Team Developer
 */
contract WBMultiSigWallet {
  event WalletAdded(
    uint indexed walletIndex,
    address walletContract,
    string name,
    string symbol
  );

  event WalletUpdated(
    uint indexed walletIndex,
    address walletContract,
    string name,
    string symbol
  );

  event Deposit(
    address sender,
    uint indexed amount,
    uint indexed balance
  );

  event SubmitTransaction(
    address owner,
    uint indexed walletIndex,
    uint indexed txIndex,
    address to,
    uint value,
    bytes data
  );

  event ConfirmTransaction(
    address owner,
    uint indexed walletIndex,
    uint indexed txIndex
  );

  event RevokeConfirmation(
    address owner,
    uint indexed walletIndex,
    uint indexed txIndex
  );

  event ExecuteTransaction(
    address indexed owner,
    uint indexed walletIndex,
    uint indexed txIndex
  );

  event DailyLimitChange(uint indexed walletIndex, uint indexed dailyLimit);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event RequirementChange(uint required);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

  mapping(uint => mapping(uint => mapping(address => bool))) public isConfirmed;
  mapping(uint => Transaction[]) public transactions;

  struct Wallet {
    address contractAddress;
    string name;
    string symbol;
    uint256 dailyLimit;
    uint256 lastDay;
    uint256 spentToday;
  }

  Wallet[] public wallets;

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

  modifier txExists(uint _walletIndex, uint _txIndex) {
    require(_txIndex < transactions[_walletIndex].length, "Transaction does not exist");
    _;
  }
  
  modifier notExecuted(uint _walletIndex, uint _txIndex) {
    require(!transactions[_walletIndex][_txIndex].executed, "Transaction already executed");
    _;
  }

  modifier notConfirmed(uint _walletIndex, uint _txIndex) {
    require(!isConfirmed[_walletIndex][_txIndex][msg.sender], "Transaction already confirmed");
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

    /// set default avax wallet
    addWallet(address(this), "Avax C-Chain", "AVAX", 1000);
  }

  /**
   * @dev Internal check to make sure that amount is under limit
   * @return boolean
   */
  function _isUnderLimit(uint walletIndex, uint amount) internal returns (bool) {
    Wallet storage wallet = wallets[walletIndex];
    
    if (block.timestamp > wallet.lastDay + 24 hours) {
      wallet.lastDay = block.timestamp;
      wallet.spentToday = 0;
    }
    
    if (wallet.spentToday + amount > wallet.dailyLimit || wallet.spentToday + amount < wallet.spentToday) {
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
   * @param walletIndex Wallet index
   * @param _to Recipient wallet address
   * @param _value Amount of token in wei
   * @param _data Some data that converted in to hex format
   */
  function submitTransaction(
    uint walletIndex,
    address _to,
    uint _value,
    bytes memory _data
  ) public onlyOwner {
    uint txIndex = transactions[walletIndex].length;

    transactions[walletIndex].push(
      Transaction({
        to: _to,
        value: _value,
        data: _data,
        executed: false,
        numConfirmations: 0
      })
    );

    emit SubmitTransaction(msg.sender, walletIndex, txIndex, _to, _value, _data);
  }

  /**
   * @notice Confirm transaction or approve transaction by sender
   * @param _walletIndex Wallet index
   * @param _txIndex Transaction index
   */
  function confirmTransaction(uint _walletIndex, uint _txIndex)
    public
    onlyOwner
    txExists(_walletIndex, _txIndex)
    notExecuted(_walletIndex, _txIndex)
    notConfirmed(_walletIndex, _txIndex)
  {
    Transaction storage transaction = transactions[_walletIndex][_txIndex];
    transaction.numConfirmations += 1;
    isConfirmed[_walletIndex][_txIndex][msg.sender] = true;

    emit ConfirmTransaction(msg.sender, _walletIndex, _txIndex);
  }

  /**
   * @notice Execute transaction, payout to recipient address
   * @param _walletIndex Wallet index
   * @param _txIndex Transaction index
   */
  function executeTransaction(uint _walletIndex, uint _txIndex)
    public
    onlyOwner
    txExists(_walletIndex, _txIndex)
    notExecuted(_walletIndex, _txIndex)
  {
    Wallet storage wallet = wallets[_walletIndex];
    Transaction storage transaction = transactions[_walletIndex][_txIndex];

    require(transaction.numConfirmations >= numConfirmationsRequired, "Cannot execute transaction");
    require(_isUnderLimit(_walletIndex, transaction.value), "Maximum daily limit");

    transaction.executed = true;
    wallet.spentToday += transaction.value;

    bool paymenStatus = false;

    if (_walletIndex == 0) {
      (bool success, ) = transaction.to.call{value: transaction.value}(
        transaction.data
      );

      paymenStatus = success;
    } else {
      (bool success) = IERC20(wallet.contractAddress).transfer(transaction.to, transaction.value);
      paymenStatus = success;
    }

    if (!paymenStatus) {
      transaction.executed = false;
      wallet.spentToday -= transaction.value;
    }

    require(paymenStatus, "Failed or insufficent funds");

    emit ExecuteTransaction(msg.sender, _walletIndex, _txIndex);
  }

  /**
   * @notice Revoke confirmed transaction
   * @param _walletIndex Wallet index
   * @param _txIndex Transaction index
   */
  function revokeConfirmation(uint _walletIndex, uint _txIndex)
    public
    onlyOwner
    txExists(_walletIndex, _txIndex)
    notExecuted(_walletIndex, _txIndex)
  {
    Transaction storage transaction = transactions[_walletIndex][_txIndex];

    require(isConfirmed[_walletIndex][_txIndex][msg.sender], "Transaction not confirmed");

    transaction.numConfirmations -= 1;
    isConfirmed[_walletIndex][_txIndex][msg.sender] = false;

    emit RevokeConfirmation(msg.sender, _walletIndex, _txIndex);
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
   * @notice Get wallet address
   */
  function getWallets() public view returns (Wallet[] memory) {
    return wallets;
  }

  /**
   * @notice Get transaction count
   */
  function getTransactionCount(uint _walletIndex) public view returns (uint) {
    return transactions[_walletIndex].length;
  }

  /**
   * @notice Get transaction details
   * @param _walletIndex Wallet index
   * @param _txIndex Transaction index
   */
  function getTransaction(uint _walletIndex, uint _txIndex)
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
    Transaction storage transaction = transactions[_walletIndex][_txIndex];

    return (
      transaction.to,
      transaction.value,
      transaction.data,
      transaction.executed,
      transaction.numConfirmations
    );
  }

  /**
   * @notice Get transactions
   * @param _walletIndex Wallet index
   * @return Transaction array
   */
  function getTransactions(uint _walletIndex) public view returns (Transaction[] memory) {
    return transactions[_walletIndex];
  }

  /**
   * @notice Get contract balance
   */
  function getBalance(uint _walletIndex) public view returns (uint256) {
    Wallet storage wallet = wallets[_walletIndex];

    if (_walletIndex == 0) {
      return address(this).balance;
    } else {
      return IERC20(wallet.contractAddress).balanceOf(address(this));
    }
  }

  /**
   * @notice Get maximum withdraw amount.
   * @return Maximum amount today
   */
  function calcMaxWithdraw(uint _walletIndex) public view returns (uint) {
    Wallet storage wallet = wallets[_walletIndex];

    if (block.timestamp > wallet.lastDay + 24 hours) {
      return wallet.dailyLimit;
    }
    
    if (wallet.dailyLimit < wallet.spentToday) {
      return 0;
    }
    
    return wallet.dailyLimit - wallet.spentToday;
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
   * @param _walletIndex Wallet index
   * @param _dailyLimit Max of amount in wei
   */
  function changeDailyLimit(uint _walletIndex, uint _dailyLimit) public onlyDeployer {
    Wallet storage wallet = wallets[_walletIndex];
    wallet.dailyLimit = _dailyLimit;
    emit DailyLimitChange(_walletIndex, _dailyLimit);
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

  /**
   * @notice Add new wallet
   * @param _contractAddress Token contract address
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _dailyLimit Daily limit
   */
  function addWallet(
    address _contractAddress,
    string memory _name,
    string memory _symbol,
    uint256 _dailyLimit
  ) public onlyDeployer {
    uint walletIndex = wallets.length;
    wallets.push(Wallet(_contractAddress, _name, _symbol, _dailyLimit, 0, 0));

    emit WalletAdded(walletIndex, _contractAddress, _name, _symbol);
  }

  /**
   * @notice Update wallet
   * @param _walletIndex Wallet index
   * @param _contractAddress Token contract address
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _dailyLimit Daily limit
   */
  function updateWallet(
    uint _walletIndex,
    address _contractAddress,
    string memory _name,
    string memory _symbol,
    uint256 _dailyLimit
  ) public onlyDeployer {
    uint walletIndex = wallets.length;
    Wallet storage wallet = wallets[_walletIndex];

    wallet.contractAddress = _contractAddress;
    wallet.name = _name;
    wallet.symbol = _symbol;
    wallet.dailyLimit = _dailyLimit;

    emit WalletUpdated(walletIndex, _contractAddress, _name, _symbol);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}