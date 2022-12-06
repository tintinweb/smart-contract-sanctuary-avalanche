// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "./../Storage.sol";

contract MultiSigWallet is Storage {
    /*
     *  Events
     */
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    /*
     *  s
     */

    /*
     *  Modifiers
     */

    modifier ownerDoesNotExist(address _owner) {
        require(!isOwner[_owner], "owner exists");
        _;
    }

    modifier ownerExists(address _owner) {
        require(isOwner[_owner], "owner not exist");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(
            transactions[transactionId].destination != address(0x00),
            "Tx not exists"
        );
        _;
    }

    modifier confirmed(uint256 transactionId, address _owner) {
        require(confirmations[transactionId][_owner], "Tx not confirmed");
        _;
    }

    modifier notConfirmed(uint256 transactionId, address _owner) {
        require(!confirmations[transactionId][_owner], "Tx already confirmed");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "Tx already executed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x00), "null address");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0,
            "invalid requirements"
        );
        _;
    }

    /*
     * Public functions
     */
    // /// @dev Contract constructor sets initial owners and required number of confirmations.
    // /// @param _owners List of initial owners.
    // /// @param _required Number of required confirmations.
    // constructor(address[] memory _owners, uint256 _required)
    //     validRequirement(_owners.length, _required)
    // {
    //     for (uint256 i = 0; i < _owners.length; i++) {
    //         require(!isOwner[_owners[i]] && _owners[i] != address(0x00));
    //         isOwner[_owners[i]] = true;
    //     }
    //     owners = _owners;
    //     required = _required;
    // }

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function initMultisigModule(address[] memory _owners, uint256 _required)
        external
        onlyOwner
        validRequirement(_owners.length, _required)
    {
        require(!multisigInitialized, "Contract already initialized");
        multisigInitialized = true;
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0x00));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner.
    /// @param _owner Address of new owner.
    function addOwner(address _owner)
        public
        whenMultisigEnabled
        whenNotFreezed
        ownerDoesNotExist(_owner)
        notNull(_owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAddition(_owner);
    }

    /// @dev Allows to remove an owner.
    /// @param _owner Address of owner.
    function removeOwner(address _owner)
        public
        whenMultisigEnabled
        whenNotFreezed
        ownerExists(_owner)
    {
        isOwner[_owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        uint256 ownerLength = owners.length - 1;
        if (required > ownerLength) changeRequirement(ownerLength);
        emit OwnerRemoval(_owner);
    }

    /// @dev Allows to replace an owner with a new owner.
    /// @param _owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address _owner, address newOwner)
        public
        whenMultisigEnabled
        whenNotFreezed
        ownerExists(_owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (owners[i] == _owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(_owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint256 _required)
        public
        whenMultisigEnabled
        whenNotFreezed
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    // / @return Returns transaction ID.
    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    )
        public
        whenMultisigEnabled
        whenNotFreezed
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint256 transactionId)
        public
        whenMultisigEnabled
        whenNotFreezed
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint256 transactionId)
        public
        whenMultisigEnabled
        whenNotFreezed
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint256 transactionId)
        public
        whenMultisigEnabled
        whenNotFreezed
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    // to make external calls
    function external_call(
        address destination,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        (bool result, ) = destination.call{value: value}(data);
        return result;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint256 transactionId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) count += 1;
            if (count == required) return true;
        }
        return false;
    }

    /*
     * Internal functions
     */
    // / @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    // / @return Returns transaction ID.
    function addTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) internal notNull(destination) returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }

    /*
     * Web3 call functions
     */
    /// @param transactionId Transaction ID.
    // / @return Number of confirmations.
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
    }

    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    // / @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++)
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /// @param transactionId Transaction ID.
    // / @return Returns array of owner addresses.
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) _confirmations[i] = confirmationsTemp[i];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Storage {
    /************************************************
     *  Wallet STORAGE
     ***********************************************/

    /// @notice owner of the wallet
    address public owner;

    /// @notice daily withdrawLimit of wallet
    uint256 public dailyWithdrawLimit;
    /// @notice amountWithdrawed in 24 hours
    uint256 public withdrawedToday;
    /// // when 24 hours will be completed (for withdrawal limit)
    uint256 public timeToTodayLimit;

    ///@notice bool to make sure contract is initialized only once
    bool internal walletInitialized;

    /************************************************
     *  Toggle STORAGE
     ***********************************************/

    bool public isAccountFreezed;

    /************************************************
     *  ModuleManager STORAGE
     ***********************************************/

    bool public isMultisigEnabled; // true: multisig is on , false: multisig is off
    address public whitlistModule; // address of whitelistmodule implementation
    address public guardianModule; // address of guardianModule implementation
    address public multisigModule; // address of multisigModule implementation
    // mapping to keep track if wallet uses a module or not
    // mapping(address => bool) public isUsingModule;
    // // to give an address against a module id
    // mapping(uint8 => address) public idToModule;
    // // array to mapp modules, 0=WhitelistModule, 1=MultisigModule, 2=GuardianModule
    // uint8[3] public moduleIds;
    /************************************************
     *  Guardian STORAGE
     ***********************************************/

    /// @notice true if guardian address, else false
    mapping(address => bool) public isGuardian;
    /// @notice keeps track of transactions that requires Guardian approval
    mapping(uint256 => Transaction) public guardianTransactions;
    /// @notice guardian require transaction count
    uint256 public guardianRequiredTxCount;
    //; // TODO: to be removed, just for testing
    // address[] public guardians;

    /// @notice stores the guardian threshold
    uint256 public threshold;

    /// @notice true iff wallet is in recovery mode
    bool public inRecovery;

    /// @notice round of recovery we're in
    uint256 public currRecoveryRound;

    ///@notice bool to make sure contract is initialized only once
    bool internal guardianInitialized;

    /// @notice mapping for bookkeeping when swapping guardians
    mapping(address => uint256) public guardianAddressToRemovalTimestamp;

    /// @notice struct used for bookkeeping during recovery mode
    /// @dev trival struct but can be extended in future (when building for malicious guardians
    /// or when owner key is compromised)
    struct Recovery {
        address proposedOwner;
        uint256 recoveryRound; // recovery round in which this recovery struct was created
        bool usedInExecuteRecovery; // set to true when we see this struct in RecoveryExecute
    }

    /// @notice mapping from guardian address to most recent Recovery struct created by them
    mapping(address => Recovery) public guardianToRecovery;

    /************************************************
     *  Multisig STORAGE
     ***********************************************/

    uint256 public MAX_OWNER_COUNT = 10; // max multisigners

    ///@notice bool to make sure contract is initialized only once
    bool internal multisigInitialized;

    /*
     *  Storage
     */
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    /************************************************
     *  Whitelist STORAGE
     ***********************************************/

    mapping(address => bool) public isWhitelisted;

    ///@notice bool to make sure contract is initialized only once
    bool internal whitelistInitialized;

    /*************************************************
     ******MODIFIERS******
     **********************************************/

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    modifier whenNotFreezed() {
        require(!isAccountFreezed, "Account Already Freezed");
        _;
    }
    modifier whenFreezed() {
        require(isAccountFreezed, "Account not Freezed");
        _;
    }

    modifier whenMultisigDisabled() {
        require(
            !isMultisigEnabled,
            "Multisig is enabled, Please use Multisig Module for transactions"
        );
        _;
    }

    modifier whenMultisigEnabled() {
        require(isMultisigEnabled, "Multisig is disabled");
        _;
    }
}