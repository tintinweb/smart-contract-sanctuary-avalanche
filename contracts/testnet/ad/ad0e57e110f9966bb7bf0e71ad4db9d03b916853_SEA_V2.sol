/**
 *Submitted for verification at Etherscan.io on 2022-10-13
 */

/**
 *Submitted for verification at Etherscan.io on 2022-10-12
 */

//................................................................
//.....SSSSSSSSSSS......EEEEEEEEEEEEEEEEEE........AAAAAAAA........
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE........AAAAAAAA........
//...SSSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE.......AAAAAAAAA........
//...SSSSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEEE.......AAAAAAAAAA.......
//..SSSSSSSS.SSSSSSSS...EEEEEE...................AAAAAAAAAA.......
//..SSSSSS.....SSSSSS...EEEEEE..................AAAAAAAAAAA.......
//..SSSSSSS.............EEEEEE..................AAAAAAAAAAAA......
//..SSSSSSSSS...........EEEEEE.................AAAAAA.AAAAAA......
//..SSSSSSSSSSSS........EEEEEE.................AAAAAA.AAAAAA......
//...SSSSSSSSSSSSSS.....EEEEEEEEEEEEEEEEE......AAAAAA..AAAAAA.....
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEE.....AAAAAA...AAAAAA.....
//.....SSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEE.....AAAAAA...AAAAAAA....
//.......SSSSSSSSSSSSS..EEEEEEEEEEEEEEEEE.....AAAAAA....AAAAAA....
//...........SSSSSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAA....
//.............SSSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAAA...
//.SSSSSS.......SSSSSS..EEEEEE...............AAAAAAAAAAAAAAAAAA...
//..SSSSSS......SSSSSS..EEEEEE..............AAAAAAAAAAAAAAAAAAA...
//..SSSSSSSS..SSSSSSSS..EEEEEE..............AAAAAA.......AAAAAAA..
//..SSSSSSSSSSSSSSSSSS..EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//...SSSSSSSSSSSSSSSS...EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//....SSSSSSSSSSSSSS....EEEEEEEEEEEEEEEEEE.AAAAAA.........AAAAAA..
//.....SSSSSSSSSSSS.....EEEEEEEEEEEEEEEEEE.AAAAA...........AAAAA..
//................................................................

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Initializable {
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;
}

interface ISEA{
     function user(address _user) external view returns(string memory name , address userAddress , uint256 amountDeposit);
     function registered(address _user) external view returns(string memory name , address userAddress , bool alreadyExists);
     function approvedAmount(address _user) external view returns(uint _approvedAmount);
}

contract SEA_V2 is Initializable, OwnableUpgradeable {
    IERC20 public usdt ;
    ISEA oldContract;

    address admin;
    address public registerer;
    address BOT_A ;
    address BOT_B ;
    address public companyWallet ;

    uint256 public totalUsers;
    uint256 public registrationFee1;
    uint256 public registrationFee2;

    mapping(address => User) public user;
    mapping(address => Register) public registered;
    mapping(address => bool) public isAuthorized;
    mapping(address => uint256) public approvedAmount;
    mapping(address => bool) public paid;

    mapping(string => uint256) public plan;
    string[] plannames;

    uint[] planvalues;

    struct Register {
        string name;
        address UserAddress;
        bool alreadyExists;
    }

    struct User {
        string name;
        address userAddress;
        uint256 amountDeposit;
    }
    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender] == true, "Not an Authorized");
        _;
    }
    modifier onlyRegisterer() {
        require(msg.sender == registerer, "Not an Authorized");
        _;
    }
    event Deposit(address user, uint256 amount);

    function initialize(
        // address _admin,
        // address _registerer,
        // address _usdt,
        // address _BOT_A,
        // address _BOT_B,
        // address _Company
    )
        public
        initializer
    
    {
        plannames = [
            "BASIC0250",
            "BASIC0500",
            "BASIC01000",
            "MIX02000",
            "MIX04000",
            "MIX06000",
            "MIX08000",
            "BUSINESS010000",
            "BUSINESS015000",
            "BUSINESS020000",
            "BUSINESS025000",
            "EMPIRE01000",
            "EMPIRE02000",
            "EMPIRE04000",
            "EMPIRE06000",
            "EMPIRE08000",
            "EMPIRE010000",
            "EMPIRE015000",
            "EMPIRE020000",
            "EMPIRE025000",
            "POSEIDON01000",
            "POSEIDON02000",
            "POSEIDON04000",
            "POSEIDON06000",
            "POSEIDON08000",
            "POSEIDON010000",
            "POSEIDON015000",
            "POSEIDON020000",
            "POSEIDON025000",
            "POSEIDON050000",
            "POSEIDON0100000",
            "BASIC100250",
            "BASIC100500",
            "BASIC1001000",
            "BASIC250250",
            "BASIC250500",
            "BASIC2501000",
            "MIX20002000",
            "MIX20004000",
            "MIX20006000",
            "MIX20008000",
            "BUSINESS1000010000",
            "BUSINESS1000015000",
            "BUSINESS1000020000",
            "BUSINESS1000025000",
            "EMPIRE10001000",
            "EMPIRE10002000",
            "EMPIRE10004000",
            "EMPIRE10006000",
            "EMPIRE10008000",
            "EMPIRE100010000",
            "EMPIRE100015000",
            "EMPIRE100020000",
            "EMPIRE100025000",
            "POSEIDON10001000",
            "POSEIDON10002000",
            "POSEIDON10004000",
            "POSEIDON10006000",
            "POSEIDON10008000",
            "POSEIDON100010000",
            "POSEIDON100015000",
            "POSEIDON100020000",
            "POSEIDON100025000",
            "POSEIDON100050000",
            "POSEIDON1000100000"
        ];
        planvalues = [
            250,
            500,
            1000,
            2000,
            4000,
            6000,
            8000,
            10000,
            15000,
            20000,
            25000,
            1000,
            2000,
            4000,
            6000,
            8000,
            10000,
            15000,
            20000,
            25000,
            1000,
            2000,
            4000,
            6000,
            8000,
            10000,
            15000,
            20000,
            25000,
            50000,
            100000,
            250,
            500,
            1000,
            250,
            500,
            1000,
            2000,
            4000,
            6000,
            8000,
            10000,
            15000,
            20000,
            25000,
            1000,
            2000,
            4000,
            6000,
            8000,
            10000,
            15000,
            20000,
            25000,
            1000,
            2000,
            4000,
            6000,
            8000,
            10000,
            15000,
            20000,
            25000,
            50000,
            100000
        ];
        __Ownable_init();
        admin = 0xE4a5c6730Bc5a2eEcA95bEe21b44c075Db02A892;
        registerer = 0xD6a4E44ED60D96701041Ee2f1E00B3E0069F6616;
        isAuthorized[admin] = true;
        isAuthorized[registerer] = true;
        BOT_A = 0xAe67CE453947501fe35365D54CD91B0cE883954c;
        BOT_B = 0xD92f1Ed3FE687eB7D447017eD154827A77F6a91A;
        companyWallet = 0x276BB2894F30898fD6f3DdA3BA5cd752C0FF205e;
        usdt = IERC20(0x3eBDeaA0DB3FfDe96E7a0DBBAFEC961FC50F725F);
        registrationFee1 = 45 * 10 ** usdt.decimals();
        registrationFee2 = 27 * 10 ** usdt.decimals();

        for (uint i; i < plannames.length; i++) {
            plan[plannames[i]] = planvalues[i];
        }

        // oldContract = ISEA(0x77fA9AFB9B2BF01E4A947B9A71651560586453dC);
    }


    function register(
        string memory _name,
        address users
    ) public onlyRegisterer {
        require(!registered[users].alreadyExists, "User already registered");
        registered[users].name = _name;
        registered[users].UserAddress = users;
        registered[users].alreadyExists = true;
    }

    function registerMultipleUsers(
        string[] memory _names,
        address[] memory users
    ) public onlyRegisterer {
        require(
            _names.length == users.length,
            "Names and users length is not equal"
        );

        for (uint256 i = 0; i < users.length; i++) {
            require(
                !registered[users[i]].alreadyExists,
                "User already registered"
            );
            registered[users[i]].name = _names[i];
            registered[users[i]].UserAddress = users[i];
            registered[users[i]].alreadyExists = true;
        }
    }

    function addRegisterData(
        string memory _name,
        address users
    ) public onlyAuthorized {
        require(!registered[users].alreadyExists, "User already registered");
        registered[users].name = _name;
        registered[users].UserAddress = users;
        registered[users].alreadyExists = true;
    }

    function updateRegisterData2(string memory _name, address newUser) public {
        require(registered[msg.sender].alreadyExists, "User not registered");
        require(!registered[newUser].alreadyExists, "User already registered");
        registered[newUser].name = _name;
        registered[newUser].UserAddress = newUser;
        registered[newUser].alreadyExists = true;
        user[newUser] = user[msg.sender];
        approvedAmount[newUser] = approvedAmount[msg.sender];
        isAuthorized[newUser] = isAuthorized[msg.sender];
        paid[newUser] = paid[msg.sender];
        delete registered[msg.sender];
        delete user[msg.sender];
        delete approvedAmount[msg.sender];
        delete isAuthorized[msg.sender];
        delete paid[msg.sender];
    }

    function DeletRegisterData(address users) public onlyAuthorized {
        delete registered[users];
        paid[users] = false;
    }

    function deposit(
        uint256 amount,
        string memory _name,
        string memory _planname
    ) public {
        require(plan[_planname] > 0, "plan not found");
        require(amount >= 0, "amount should be more than 0");
        require(
            amount == plan[_planname] * (10 ** usdt.decimals()),
            "amount should be according to the plan"
        );
        require(registered[msg.sender].alreadyExists, "User not registered");
        uint256 trasnferamount;
        if (!paid[msg.sender]) {
            trasnferamount = registrationFee1;
            paid[msg.sender] = true;
        } else {
            trasnferamount = registrationFee2;
        }
        usdt.transferFrom(msg.sender, BOT_A, amount);
        usdt.transferFrom(msg.sender, companyWallet, trasnferamount);

        user[msg.sender].name = _name;
        user[msg.sender].userAddress = msg.sender;
        user[msg.sender].amountDeposit =
            user[msg.sender].amountDeposit +
            (amount);
        emit Deposit(msg.sender, amount);
    }

    function AuthorizeUser(address _user, bool _state) public {
        require(admin == msg.sender, "Only admin can authorize user");
        isAuthorized[_user] = _state;
    }

    function distribute(
        address[] memory recivers,
        uint256[] memory amount
    ) public onlyAuthorized {
        require(recivers.length == amount.length, "unMatched Data");

        for (uint256 i; i < recivers.length; i++) {
            require(
                registered[recivers[i]].alreadyExists,
                "User not registered"
            );
            approvedAmount[recivers[i]] += amount[i];
        }
    }

    function undoDistribute(
        address[] memory recivers,
        uint256[] memory amount
    ) public onlyAuthorized {
        require(recivers.length == amount.length, "unMatched Data");

        for (uint256 i; i < recivers.length; i++) {
            require(
                registered[recivers[i]].alreadyExists,
                "User not registered"
            );
            if (
                approvedAmount[recivers[i]] >= 0 &&
                approvedAmount[recivers[i]] >= amount[i]
            ) {
                approvedAmount[recivers[i]] -= amount[i];
            } else {
                approvedAmount[recivers[i]] = 0;
            }
        }
    }

    function claim() public {
        require(approvedAmount[msg.sender] > 0, "not authorized");
        uint256 amount = approvedAmount[msg.sender];
        usdt.transfer(msg.sender, amount);
        approvedAmount[msg.sender] = 0;
    }

    function migerateData(address[] memory _users) onlyRegisterer external {   
        for (uint256 i = 0; i < _users.length; i++) {
             (string memory name , address userAddress , uint256 amountDeposit)=oldContract.user(_users[i]);
             (,,bool alreadyExist)=oldContract.registered(_users[i]);
             (uint256 _approvedAmount)=oldContract.approvedAmount(_users[i]);
             
             if(alreadyExist && amountDeposit>0){
                user[_users[i]].name = name;
                user[_users[i]].userAddress = userAddress;
                user[_users[i]].amountDeposit = amountDeposit;
             
             if(_approvedAmount>0){
                approvedAmount[_users[i]] = _approvedAmount;
             }
             }  
        }
    }

    function changeOldContractAddress(ISEA _contractAddress) onlyAuthorized external {
        oldContract = ISEA(_contractAddress);
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin, "Not an admin");
        admin = newAdmin;
    }

    function changeToken(address newToken) public onlyAuthorized {
        usdt = IERC20(newToken);
    }

    function changeBOT_A(address newBOT_A) public onlyAuthorized {
        BOT_A = newBOT_A;
    }

    function changeBOT_B(address newBOT_B) public onlyAuthorized {
        BOT_B = newBOT_B;
    }

    function changeCompanyWallet(address newCompany) public onlyAuthorized {
        companyWallet = newCompany;
    }

    function changeregistrer(address newRegistrar) public onlyAuthorized {
        registerer = newRegistrar;
    }

    function setplan(
        string calldata _planname,
        uint256 amount
    ) public onlyAuthorized {
        require(plan[_planname] > 0, "plan not found");
        plan[_planname] = amount;
    }

    function addplan(
        string calldata _planname,
        uint256 amount
    ) public onlyAuthorized {
        require(!checkplanexists(_planname), "plan already exists");
        plan[_planname] = amount;
        plannames.push(_planname);
    }

    // For adding multiple plans at once
    function addMultiplePlans(
        string[] calldata _plannames,
        uint256[] memory _amounts
    ) public onlyAuthorized {
        require(
            _plannames.length == _plannames.length,
            "Plan names and amounts length is not equal"
        );
        for (uint256 i = 0; i < _plannames.length; i++) {
            plan[_plannames[i]] = _amounts[i];
            if (!checkplanexists(_plannames[i])) {
                plannames.push(_plannames[i]);
            }
        }
    }

    function changeregiestrationFee1(uint256 amount) public onlyAuthorized {
        registrationFee1 = amount;
    }

    function changeregiestrationFee2(uint256 amount) public onlyAuthorized {
        registrationFee2 = amount;
    }

    function checkplanexists(
        string memory _planname
    ) public view returns (bool val) {
        for (uint256 i = 0; i < plannames.length; i++) {
            if (keccak256(bytes(plannames[i])) == keccak256(bytes(_planname))) {
                return true;
            }
        }
    }

    function getplannames() public view returns (string[] memory names) {
        return plannames;
    }

    function removeplan(string memory _planname) public onlyAuthorized {
        require(checkplanexists(_planname), "plan not found");
        for (uint256 i = 0; i < plannames.length; i++) {
            if (keccak256(bytes(plannames[i])) == keccak256(bytes(_planname))) {
                delete plannames[i];
                delete plan[_planname];
                return;
            }
        }
    }

    function withdrawStukFunds(IERC20 token) public onlyAuthorized {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function withdrawStuckFunds() public onlyAuthorized {
        payable(msg.sender).transfer(address(this).balance);
    }
}