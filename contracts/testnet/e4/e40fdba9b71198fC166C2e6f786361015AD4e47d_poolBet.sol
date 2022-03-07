/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract poolBet {
  //Add state variables
  uint counter;

  //Add mappings
  mapping(address => uint) public amount;
  mapping(address => uint[]) public poolAddressMapping;
  mapping(uint => Pool) public poolMapping;

  //Add events
  event CreatePool(uint indexed id, string poolName, address moderator, uint betAmount);
  event Deposit(address indexed user, uint amount, uint poolId);
  event RecognizeWinner(address indexed user, address indexed winningAddress, uint poolId);
  event UndoRecognizeWinner(address indexed user, address indexed winningAddress, uint poolId);
  event ProposeWinner(address indexed winningAddress, address moderator, uint poolId);
  event WithdrawDeposit(address indexed user, uint amount, uint poolId);
  event WithdrawWins(address indexed user, uint amount, uint poolId);

  //constructor
  constructor() {
  }

  enum BetState {
    UNLOCKED,
    LOCKED,
    WINNER_PROPOSED,
    SETTLED
  }

  struct Pool {
    uint id;
    uint betAmount;
    uint totalAmount;
    bool isWinnerRecognized;
    bool isLocked;
    bool isActive;
    string name;
    address moderator;
    address winner;
    address[] depositors;
    mapping(address => bool) isApproved;
    mapping(address => bool) isDeposited;
  }

  struct ActionSet {
    bool canDeposit;
    bool canWithdraw;
    bool canLock;
    bool canUnlock;
    bool canRecognizeWinner;
    bool canUndoRecognizeWinner;
    bool canProposeWinner;
    bool canWithdrawWins;
  }

  /**
  --- Key interactions
  createPool(name, moderator, betAmount)
  createUser(username)
  addToPool payable (pool, address)
  lockPool(pool)
  unlockPool(pool)
  listAllPools()
  listUsersByPool(pool)
  recognizeWinner(address, pool)
  proposeWinner(pool)
  withdrawFunds
  withdrawWins
  --- Interactions for enabling buttons in GUI
  canDeposit()
  canWithdraw()
  canLock()
  canUnlock()
  canRecognizeWinner()
  canUndoRecognizeWinner()
  canProposeWinner()
  canWithdrawWins()
  **/

  function getId() private returns(uint) {
    return ++counter; 
  }

  function createPool(string memory name, uint betAmount) public {
    uint id = getId();
    Pool storage newPool = poolMapping[id];
    newPool.id = id;
    newPool.name = name;
    newPool.moderator = msg.sender;
    newPool.betAmount = betAmount;
    newPool.totalAmount = 0;
    newPool.isWinnerRecognized = false;
    newPool.isActive = true;
    newPool.isLocked = false;
    newPool.isApproved[msg.sender] = false;
    newPool.isDeposited[msg.sender] = false;
    poolAddressMapping[msg.sender].push(newPool.id);

    emit CreatePool(newPool.id, newPool.name, newPool.moderator, newPool.betAmount);
  }
  
  /*----------------------------------------
  -- Modifiers
  ----------------------------------------*/
  modifier onlyModerator(uint poolId) {
    Pool storage currentPool = poolMapping[poolId];
    require(msg.sender == currentPool.moderator, "Error, only the moderator can call this function");
    _;
  }

  modifier onlyWhenPoolActive(uint poolId) {
    Pool storage currentPool = poolMapping[poolId];
    require(true == currentPool.isActive, "Error, only the moderator can call this function");
    _;
  }

  /*----------------------------------------
  -- View functions: list
  ----------------------------------------*/
  function listPoolsByUser(address user) public view returns (uint[] memory) {
    return poolAddressMapping[user];
  }

  function listUsersByPool(uint poolId) public view returns (address[] memory) {
    Pool storage currentPool = poolMapping[poolId];
    return currentPool.depositors;
  }

  function fetchActions(uint poolId, address proposedWinnerAddress) public view returns (ActionSet memory) {
    Pool storage currentPool = poolMapping[poolId];
    
    bool canDepositAction = !currentPool.isLocked
    && !currentPool.isDeposited[msg.sender]
    && !currentPool.isWinnerRecognized
    && currentPool.isActive;

    bool canWithdrawAction = !currentPool.isLocked
    && currentPool.isDeposited[msg.sender]
    && !currentPool.isWinnerRecognized
    && currentPool.isActive;

    bool canLockAction = msg.sender == currentPool.moderator
    && !currentPool.isLocked
    && currentPool.isActive
    && currentPool.winner == address(0);

    bool canUnlockAction = msg.sender == currentPool.moderator
    && currentPool.isLocked
    && currentPool.isActive
    && currentPool.winner == address(0);

    bool canRecognizeWinnerAction = !currentPool.isWinnerRecognized
    && proposedWinnerAddress != address(0)
    && currentPool.winner == proposedWinnerAddress
    && currentPool.isDeposited[msg.sender]
    && !currentPool.isApproved[msg.sender]
    && currentPool.isActive;

    bool canUndoRecognizeWinnerAction = !currentPool.isWinnerRecognized
    && proposedWinnerAddress != address(0)
    && currentPool.winner == proposedWinnerAddress
    && currentPool.isDeposited[msg.sender]
    && currentPool.isApproved[msg.sender]
    && currentPool.isActive;

    bool canProposeWinnerAction = msg.sender == currentPool.moderator
    && currentPool.winner == address(0)
    && !currentPool.isWinnerRecognized
    && currentPool.isActive
    && currentPool.isLocked
    && currentPool.depositors.length > 0;

    bool canWithdrawWinsAction = currentPool.isWinnerRecognized
    && currentPool.isActive
    && msg.sender == currentPool.winner
    && currentPool.winner != address(0)
    && amount[msg.sender] > 0
    && currentPool.totalAmount > 0;

    ActionSet memory actions;
    actions.canDeposit = canDepositAction;
    actions.canWithdraw = canWithdrawAction;
    actions.canLock = canLockAction;
    actions.canUnlock = canUnlockAction;
    actions.canRecognizeWinner = canRecognizeWinnerAction;
    actions.canUndoRecognizeWinner = canUndoRecognizeWinnerAction;
    actions.canProposeWinner = canProposeWinnerAction;
    actions.canWithdrawWins = canWithdrawWinsAction;

    return actions;
  }

  function fetchIsApprovedStatusForAddress(uint poolId, address bettorAddress) public view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    return currentPool.isApproved[bettorAddress];
  }

  function lockPool(uint poolId) public virtual onlyModerator(poolId) onlyWhenPoolActive(poolId) {
    Pool storage currentPool = poolMapping[poolId];
    require(!currentPool.isLocked, 'Error, pool is already locked!');
    //Add all validations here
    currentPool.isLocked = true;
  }

  function unlockPool(uint poolId) public virtual onlyModerator(poolId) onlyWhenPoolActive(poolId) {
    Pool storage currentPool = poolMapping[poolId];
    require(currentPool.isLocked, 'Error, pool is already unlocked!');
    //Add all validations here
    currentPool.isLocked = false;
  }

  function deposit(uint poolId) payable public virtual onlyWhenPoolActive(poolId) {
    
    Pool storage currentPool = poolMapping[poolId];

    //Check if pool is unlocked
    //Depositing only allowed when the pool is unlocked
    require(!currentPool.isLocked, 'Error, pool needs to be unlocked before depositing funds!');

    //Check to see if the winner has not already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been set! Cannot deposit now!');

    //Check if msg.sender didn't already deposited funds to the pool
    //Only 1 deposit per wallet allowed
    require(currentPool.isDeposited[msg.sender] == false, 'Error, deposit already found for the current user! Cannot deposit again!');

    //Check if msg.value is == betAmount
    require(msg.value == currentPool.betAmount, 'Error, deposit must be equal to betAmount!');

    currentPool.depositors.push(msg.sender);
    currentPool.isDeposited[msg.sender] = true;
    currentPool.totalAmount = currentPool.totalAmount + msg.value;

    amount[msg.sender] = amount[msg.sender] + msg.value;

    bool poolIdExists = false;
    for(uint i; i< poolAddressMapping[msg.sender].length; i++) {
      if(poolAddressMapping[msg.sender][i] == poolId) {
        poolIdExists = true;
      }
    }

    if(!poolIdExists) {
      poolAddressMapping[msg.sender].push(poolId);
    }

    if(currentPool.isActive || currentPool.totalAmount > 0) {
      currentPool.isActive = true;
    }

    emit Deposit(msg.sender, msg.value, poolId);
  }

  function recognizeWinner(address user, uint poolId) public virtual onlyWhenPoolActive(poolId) {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the msg.sender is a depositor in the pool.
    require(currentPool.isDeposited[msg.sender], 'Error, you need to be a depositor in this pool to recognize a winner!');

    //Check that the address is not the default address but a real addreses
    require(currentPool.winner != address(0), 'Error, the winner is currently address zero and therefore invalid!');

    //Check that the address sent in the request is the same as the one proposed in the pool by the moderator
    require(currentPool.winner == user, 'Error, the winner requested to be recognized does not match the winner proposed by the moderator!');

    //Check to see if the depositor has already recognized the winner previously
    require(!currentPool.isApproved[msg.sender], 'Error, the winner has already been recognized by you!');

    //Check to see if the winner has already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been decided!');

    currentPool.isApproved[msg.sender] = true; 

    if(isWinnerRecognizedByAll(poolId)) {
      currentPool.isWinnerRecognized = true;
    }

    emit RecognizeWinner(msg.sender, user, poolId);
  }

  function undoRecognizeWinner(address user, uint poolId) public virtual onlyWhenPoolActive(poolId) {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the msg.sender is a depositor in the pool.
    require(currentPool.isDeposited[msg.sender], 'Error, you need to be a depositor in this pool to undo recognizing a winner!');

     //Check that the msg.sender is a depositor in the pool.
    require(currentPool.isApproved[msg.sender], 'Error, you need to be a depositor in this pool to undo recognizing a winner!');

    //Check that the address is not the default address but a real addreses
    require(currentPool.winner != address(0), 'Error, the winner is currently address zero and therefore invalid!');

    //Check that the address sent in the request is the same as the one proposed in the pool by the moderator
    require(currentPool.winner == user, 'Error, the winner requested to be recognized does not match the winner proposed by the moderator!');

    //Check to see if the winner has already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been decided!');

    currentPool.isApproved[msg.sender] = false;

    emit UndoRecognizeWinner(msg.sender, user, poolId);
  }

  function proposeWinner(address proposedWinnerAddress, uint poolId) public virtual onlyModerator(poolId) onlyWhenPoolActive(poolId) {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the address is not the default address but a real addreses
    require(currentPool.winner == address(0), 'Error, the winner is currently address zero and therefore invalid!');

    //Check to see if the winner has not already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been set!');

    //Check to see if the winner is a depositor in the pool.
    require(currentPool.isDeposited[proposedWinnerAddress], 'Error, The winner must be a depositor in the bet pool!');

    //Check to see if the pool is locked.
    require(currentPool.isLocked, 'Error, The pool must be locked in order to propose a winner!');

    //Check to see if there is atleast one depositors in the pool.
    require(currentPool.depositors.length > 0, 'Error, There are no depositors in the pool!');

    currentPool.winner = proposedWinnerAddress;

    setIsApprovedForProposedWinnerAndModerator(poolId);

    emit ProposeWinner(proposedWinnerAddress, currentPool.moderator, poolId);
  }

  //Set moderator and winner isApproved to true.
  function setIsApprovedForProposedWinnerAndModerator(uint poolId) private {
    Pool storage currentPool = poolMapping[poolId];
    for (uint i; i< currentPool.depositors.length; i++) {
      if (currentPool.depositors[i] == currentPool.winner || currentPool.depositors[i] == currentPool.moderator) {
        currentPool.isApproved[currentPool.depositors[i]] = true;
      }
    }
  }

  //Check if all depositors have recognized the winner here for the pool.
  function isWinnerRecognizedByAll(uint poolId) private view returns(bool) {
    Pool storage currentPool = poolMapping[poolId];
    for (uint i; i< currentPool.depositors.length; i++) {
      if (!currentPool.isApproved[currentPool.depositors[i]]) {
        return false;
      }
    }
    return true;
  }

  function withdrawDeposit(uint poolId) public virtual onlyWhenPoolActive(poolId) {
    Pool storage currentPool = poolMapping[poolId];

    //Check that the pool must be active and unlocked for a withdraw of deposit to be successful
    require(!currentPool.isLocked && currentPool.isActive, 'Error, pool is either locked or inactive! Cannot withdraw now!');

    //Check to see if the winner has not already been recognized by all.
    require(!currentPool.isWinnerRecognized, 'Error, the winner has already been set! Cannot withdraw now!');

    //User must have had a deposit in the pool to withdraw
    require(currentPool.isDeposited[msg.sender] = true, 'Error, only depositors can withdraw their deposited funds!');

    //User must have had an amount in the amount mapping
    require(amount[msg.sender] > 0 wei);

    payable(msg.sender).transfer(currentPool.betAmount);
    currentPool.totalAmount = currentPool.totalAmount - currentPool.betAmount;

    //Iterate and remove depositor from depositors list in pool
    for (uint i; i< currentPool.depositors.length; i++) {
      if (currentPool.depositors[i] == msg.sender) {
        currentPool.depositors[i] = currentPool.depositors[currentPool.depositors.length - 1];
        currentPool.depositors.pop();
      }
    }

    currentPool.isDeposited[msg.sender] = false;

    //Check if user has funds and remove funds from user amount mapping
    if(amount[msg.sender] > 0 wei) {
      amount[msg.sender] = amount[msg.sender] - currentPool.betAmount;
    }

    /**
    TODO: Review if this step is really required and practical.
    if(currentPool.totalAmount <= 0) {
      currentPool.isActive = false;
    }
    */

    emit WithdrawDeposit(msg.sender, currentPool.betAmount, poolId);
  }

  function withdrawWins(uint poolId) public onlyWhenPoolActive(poolId){
    Pool storage currentPool = poolMapping[poolId];
    //Check that the pool must be active and unlocked for a withdraw of deposit to be successful
    require(currentPool.isActive, 'Error, pool is inactive! Cannot withdraw now!');

    //Check that the msg.sender is the winner. The check that the winner is a depositor is done in proposeWinner
    require(msg.sender == currentPool.winner, 'Error, only the winner can withdraw funds!');

    //Check that the winner is recognized by all bet pool participants
    require(currentPool.isWinnerRecognized, 'Error, The winner must be recognized by all bet pool particiapants!');

    //Should it be greater than 0 or greater than 0 wei?
    require(amount[msg.sender] > 0 && currentPool.totalAmount > 0, 'Error, No wins to withdraw!');

    payable(msg.sender).transfer(currentPool.totalAmount);
    currentPool.totalAmount = 0;

    address depositorAddress;
    //Remove amount for each depositor from amount mapping
    //Remove isDeposited for each user for pool
    for(uint i; i< currentPool.depositors.length; i++) {
      depositorAddress = currentPool.depositors[i];
      amount[depositorAddress] =  amount[depositorAddress] - currentPool.betAmount;
      currentPool.isDeposited[depositorAddress] = false;
    }

    //Deactivate pool
    currentPool.isActive = false;

    emit WithdrawWins(msg.sender, currentPool.totalAmount, poolId);
  }
}