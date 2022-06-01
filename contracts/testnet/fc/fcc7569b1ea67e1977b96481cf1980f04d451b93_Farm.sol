// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Farm is Ownable {

    /**
     * @dev Enum variable type
     */
    enum Status{ ACTIVE, DONE }
    enum Network{ BSC, AVAX }

    /**
     * @dev Struct variable type
     */
    struct FarmService {
        string name;
        Network network;
        bool isActive;
    }

    struct FarmPair {
        uint256 farmServiceId;
        uint256 pairId;
        IERC20 contractAddress;
        IERC20 lpAddress;
        IERC20 rewardToken;
        address farmAddress;
        uint256 TVL;
        uint256 APY;
        uint256 maxPoolAmount;
        uint256 minAmount;
        bool isActive;
    }

    struct Pair {
        uint256 farmPairId;
        string name;
        address depositAddress;
        address withdrawAddress;
        bool isActive;
        bool isFarmMoving;
    }

    struct Deposit {
        uint256 amount;
        uint256 profit;
        uint256 startTime;
        uint256 pairId;
        Status status; 
    }

    struct Withdrawal {
        uint256 depositId;
        uint256 amount;
        uint256 date;
        Status status;
    }

    struct User {
        address referral;
        bool isBlocked;
        uint256 depositCount;
        uint256 withdrawCount;
        mapping(uint256 => Deposit) deposits;
        mapping(uint256 => Withdrawal) withdrawals;
    }

    /**
     * @dev Mapping data for quick access by index or address.
     */
    mapping(uint256 => FarmService) public farmServices;
    mapping(uint256 => FarmPair) public farmPairs;
    mapping(uint256 => Pair) public pairs;
    mapping(address => User) public users;

    address[] public usersList;

    /**
     * @dev Counters for mapped data. Used to store the length of the data.
     */
    uint256 public usersCount;
    uint256 public farmPairsCount;
    uint256 public pairsCount;
    uint256 public farmServicesCount;

    /**
     * @dev All events. Used to track changes in the contract
     */
    event AdminIsAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event MINTVLUpdated(uint256 value);
    event CAPYUpdated(uint256 value);
    event MINAPYUpdated(uint256 value);
    event ServiceDisabled();
    event ServiceEnabled();
    event FarmServiceChanged(string name, Network network);
    event PairChanged(string name);
    event FarmPairChanged(uint256 farmPairId, IERC20 indexed contractAddress);
    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdraw(address indexed user, uint256 amount);
    event UserBlocked(address indexed user);
    event UserUnblocked(address indexed user);
    event NewUser(address indexed user, address indexed referral);
    event DepositStatusChanged(address indexed user, uint256 depositId, Status status);
    event WithdrawStatusChanged(address indexed user, uint256 withdrawId, Status status);
    event FarmToFarmMovingStart(uint256 time, uint256 farmPairId);
    event FarmToFarmMovingEnd(uint256 time, uint256 farmPairId);

    /**
     * @dev Admins data
     */
    mapping(address => bool) public isAdmin;
    address[] public adminsList;
    uint256 public adminsCount;

    /**
     * @dev Core data
     */
    bool public serviceDisabled;
    uint256 public MINTVL;
    uint256 public CAPY;
    uint256 public MINAPY;
    uint256 public servicePercent;

    bool private itialized;

    /**
     * @dev Initial setup.
     */
    function initialize() external virtual {
        require(itialized != true, 'FarmContract: already initialized');
        itialized = true;
        initOwner(_msgSender());
        addAdmin(_msgSender());
    }

    /**
     * @dev Throws if called when variable (`serviceDisabled`) is equals (`true`).
     */
    modifier onlyWhenServiceEnabled() {
        require(serviceDisabled == false, "FarmContract: Currently service is disabled. Try again later.");
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Access denied!");
        _;
    }

    /**
     * @dev Set deposit address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function setDepositAddress(uint256 _pairId, address _address) public onlyWhenServiceEnabled onlyOwner {
       pairs[_pairId].depositAddress = _address;
    }

    /**
     * @dev Set service percent.
     *
     * NOTE: Can only be called by the admin.
     */
    function setServicePercent(uint256 _percent) public onlyWhenServiceEnabled onlyAdmin {
       servicePercent = _percent;
    }

    /**
     * @dev Start moving farm to farm.
     *
     * NOTE: Can only be called by the current owner.
     */
    function startFarmToFarm(uint256 _pairId, uint256 _newFarmPairId) public onlyWhenServiceEnabled onlyOwner {
        pairs[_pairId].farmPairId = _newFarmPairId;
        pairs[_pairId].isFarmMoving = true;
        emit FarmToFarmMovingStart(block.timestamp, _pairId);
    }

    /**
     * @dev End moving farm to farm.
     *
     * NOTE: Can only be called by the current owner.
     */
    function endFarmToFarm(uint256 _pairId) public onlyWhenServiceEnabled onlyOwner {
         pairs[_pairId].isFarmMoving = false;
        emit FarmToFarmMovingEnd(block.timestamp, _pairId);
    }

    /**
     * @dev Gives administrator rights to the address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function addAdmin(address _address) public onlyWhenServiceEnabled onlyOwner {
        adminsList.push(_address);
        isAdmin[_address] = true;
        adminsCount++;
        emit AdminIsAdded(_address);
    }

    /**
     * @dev Removes administrator rights from the address.
     *
     * NOTE: Can only be called by the current owner.
     */
    function removeAdmin(address _address, uint256 _index) public onlyWhenServiceEnabled onlyOwner {
        isAdmin[_address] = false;
        adminsList[_index] = adminsList[adminsList.length - 1];
        adminsList.pop();
        adminsCount--;
        emit AdminRemoved(_address);
    }

    /**
     * @dev Block user by address.
     *
     * NOTE: Can only be called by the admin address.
     */
    function blockUser(address _address) public onlyWhenServiceEnabled onlyAdmin {
        users[_address].isBlocked = true;
        emit UserBlocked(_address);
    }

    /**
     * @dev Unblock user by address.
     *
     * NOTE: Can only be called by the admin address.
     */
    function unblockUser(address _address) public onlyWhenServiceEnabled onlyAdmin {
        users[_address].isBlocked = false;
        emit UserUnblocked(_address);
    }

    /**
     * @dev Disable all callable methods of service except (`enableService()`).
     *
     * NOTE: Can only be called by the admin address.
     */
    function disableService() public onlyWhenServiceEnabled onlyAdmin {
        serviceDisabled = true;
        emit ServiceDisabled();
    }

    /**
     * @dev Enable all callable methods of service.
     *
     * NOTE: Can only be called by the admin address.
     */
    function enableService() public onlyAdmin {
        serviceDisabled = false;
        emit ServiceEnabled();
    }

    /**
     * @dev Sets new value for (`MINTVL`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setMINTVL(uint256 _value) public onlyWhenServiceEnabled onlyAdmin {
        MINTVL = _value;
        emit MINTVLUpdated(_value);
    }

    /**
     * @dev Sets new value for (`CAPY`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setCAPY(uint256 _value) public onlyWhenServiceEnabled onlyAdmin {
        CAPY = _value;
        emit CAPYUpdated(_value);
    }

    /**
     * @dev Sets new value for (`CAPY`) variable.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setMINAPY(uint256 _value) public onlyWhenServiceEnabled onlyAdmin {
        MINAPY = _value;
        emit MINAPYUpdated(_value);
    }

    /**
     * @dev Adds or update (`FarmService`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setFarmService(
        uint256 _id,
        string memory _name,
        Network _network,
        bool _isActive
    ) public onlyWhenServiceEnabled onlyAdmin {

        if (bytes(farmServices[_id].name).length == 0) {
            farmServicesCount++;
        }

        farmServices[_id] = FarmService(_name, _network, _isActive);

        emit FarmServiceChanged(_name, _network);
    } 

    /**
     * @dev Adds or update (`FarmService`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setPair(
        uint256 _id,
        uint256 _farmPairId,
        string memory _name,
        address _depositAddress,
        address _withdrawAddress,
        bool _isActive
    ) public onlyWhenServiceEnabled onlyAdmin {

        if (bytes(pairs[_id].name).length == 0) {
            farmServicesCount++;
        }

        pairs[_id] = Pair(
            _farmPairId,
            _name,
            _depositAddress,
            _withdrawAddress,
            _isActive,
            pairs[_id].isFarmMoving
        );

        emit PairChanged(_name);
    } 

    /**
     * @dev Adds or update (`Pair`) object.
     *
     * NOTE: Can only be called by the admin address.
     */
    function setFarmPair(
        uint256 _id,
        uint256 _farmServiceId,
        uint256 _pairId,
        IERC20 _contractAddress,
        IERC20 _lpAddress,
        IERC20 _rewardToken,
        address _farmAddress,
        uint _TVL,
        uint _APY,
        uint256 _maxPoolAmount,
        uint256 _minAmount,
        bool _isActive
    ) public onlyWhenServiceEnabled onlyAdmin {

        require(farmServices[_farmServiceId].isActive == true, "Farm service with this ID does not exist or inactive!");

        if (farmPairs[_id].farmAddress == address(0)) {
            farmPairsCount++;
        }

        farmPairs[_id] = FarmPair(
            _farmServiceId,
            _pairId,
            _contractAddress,
            _lpAddress,
            _rewardToken,
            _farmAddress,
            _TVL,
            _APY,
            _maxPoolAmount,
            _minAmount,
            _isActive
        );

        emit FarmPairChanged(_id, _contractAddress);
    }

    /**
     * @dev Create new (`User`) object by address.
     *
     * Emits a {NewUser} event.
     *
     * NOTE: Only internal call.
     */
    function createNewUser(address _referral) private {
        users[_msgSender()].referral = _referral;
        users[_msgSender()].isBlocked = false;
        users[_msgSender()].depositCount = 0;
        users[_msgSender()].withdrawCount = 0;

        usersList.push(_msgSender());
        usersCount++;

        emit NewUser(_msgSender(), _referral);
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if (`_amount`) is greater than zero;
     * Checks if farm service exists and has active status;
     * Checks if token exists and has active status;
     * Checks if contact has required amount of token for transfer from current caller;
     *
     * Transfers the amount of tokens to the current contract.
     * 
     * If its called by new address then new user will be created.
     * 
     * Creates new object of (`Deposit`) struct.
     *
     * Emits a {NewDeposit} event.
     */
    function deposit(
        uint256 _amount,
        address _referral,
        uint256 _farmServiceId,
        uint256 _pairId
    ) public onlyWhenServiceEnabled {

        require(users[_msgSender()].isBlocked == false, "FarmContract: User blocked");
        require(_amount > 0, "FarmContract: Zero amount");
        require(farmServices[_farmServiceId].isActive, "FarmContract: No active farm service");
        require(pairs[_pairId].isActive, "FarmContract: No active pairs");

        IERC20 token = farmPairs[pairs[_pairId].farmPairId].contractAddress;
        uint256 allowance = token.allowance(_msgSender(), address(this));
        require(allowance >= _amount, "FarmContract: Recheck the token allowance");
        (bool sent) = token.transferFrom(_msgSender(), pairs[_pairId].depositAddress, _amount);
        require(sent, "FarmContract: Failed to send tokens");

        uint256 depositCount = users[_msgSender()].depositCount;
        
        if (depositCount <= 0) {
            createNewUser(_referral);
            users[_msgSender()].deposits[users[_msgSender()].depositCount] = Deposit(_amount, 0, block.timestamp, _pairId, Status.ACTIVE);
            users[_msgSender()].depositCount += 1;
        } else {
            for (uint i = 0; i <= depositCount - 1; i++) {
                if (users[_msgSender()].deposits[i].pairId == _pairId && users[_msgSender()].deposits[i].status == Status.ACTIVE) {
                    users[_msgSender()].deposits[i].amount += _amount;
                }
            }
        }

        emit NewDeposit(_msgSender(), _amount);
    }

    /**
     * @dev To call this method, certain conditions are required, as described below:
     * 
     * Checks if user isn't blocked;
     * Checks if user (`Deposit`) has ACTIVE status;
     * Checks if requested amount is less or equal deposit balance;
     *
     * Creates new object of (`Withdrawal`) struct with status CREATED.
     *
     * Emits a {NewDeposit} event.
     */
    function withdraw(
        uint256 _depositId,
        uint256 _amount
    ) public onlyWhenServiceEnabled {

        require(users[_msgSender()].isBlocked == false, "FarmContract: User blocked");

        Deposit storage userDeposit = users[_msgSender()].deposits[_depositId];

        require(userDeposit.status == Status.ACTIVE, "FarmContract: Deposit has not active status");
        
        uint256 newWithdrawalId = users[_msgSender()].withdrawCount;
        
        users[_msgSender()].withdrawals[newWithdrawalId] = Withdrawal(_depositId, userDeposit.amount, block.timestamp, Status.ACTIVE);
        users[_msgSender()].withdrawCount += 1;

        if (_amount == users[_msgSender()].deposits[_depositId].amount) {
            users[_msgSender()].deposits[_depositId].status = Status.DONE;
        }

        emit NewWithdraw(_msgSender(), userDeposit.amount);
    }

    /**
     * @dev Returns the user (`Deposit`) object.
     */
    function getUserDeposit(
        address _userAddress,
        uint256 _depositId
    ) public view returns (Deposit memory) {
        return users[_userAddress].deposits[_depositId];
    }

    /**
     * @dev Returns the user (`Withdrawal`) object.
     */
    function getUserWithdraw(
        address _userAddress,
        uint256 _withdrawId
    ) public view returns (Withdrawal memory) {
        return users[_userAddress].withdrawals[_withdrawId];
    }
}