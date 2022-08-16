// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



import "@openzeppelin/contracts/utils/Context.sol";
import "./TokenismAdminWhitelist.sol";

contract TokenismWhitelist is Context, TokenismAdminWhitelist {
    
    using Roles for Roles.Role;
    Roles.Role private _userWhitelisteds;
    mapping(string => bool) symbolsDef;

    struct whitelistInfo {
        bool valid;
        address wallet;
        bool kycVerified;
        bool accredationVerified;
        uint256 accredationExpiry;
        uint256 taxWithholding;
        string userType;
        bool suspend;
    }
    mapping(address => whitelistInfo) public whitelistUsers;
    address[] public userList;

    // userTypes = Basic || Premium
    function addWhitelistedUser(
        address _wallet,
        bool _kycVerified,
        bool _accredationVerified,
        uint256 _accredationExpiry
    ) public onlyManager {
        if (_accredationVerified)
            require(
                _accredationExpiry >= block.timestamp,
                "accredationExpiry: Accredation Expiry time is before current time"
            );

        _userWhitelisteds.add(_wallet);
        whitelistInfo storage newUser = whitelistUsers[_wallet];

        newUser.valid = true;
        newUser.suspend = false;
        newUser.taxWithholding = 0;

        newUser.wallet = _wallet;
        newUser.kycVerified = _kycVerified;
        newUser.accredationExpiry = _accredationExpiry;
        newUser.accredationVerified = _accredationVerified;
        newUser.userType = "Basic";
        // maintain whitelist user list
        userList.push(_wallet);
    }

    function getWhitelistedUser(address _wallet)
        public
        view
        returns (
            address,
            bool,
            bool,
            uint256,
            uint256
        )
    {
        whitelistInfo memory u = whitelistUsers[_wallet];
        return (
            u.wallet,
            u.kycVerified,
            u.accredationExpiry >= block.timestamp,
            u.accredationExpiry,
            u.taxWithholding
        );
    }

    function updateKycWhitelistedUser(address _wallet, bool _kycVerified)
        public
        onlyManager
    {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.kycVerified = _kycVerified;
    }

    function updateAccredationWhitelistedUser(
        address _wallet,
        uint256 _accredationExpiry
    ) public onlyManager {
        require(
            _accredationExpiry >= block.timestamp,
            "accredationExpiry: Accredation Expiry time is before current time"
        );

        whitelistInfo storage u = whitelistUsers[_wallet];
        u.accredationExpiry = _accredationExpiry;
    }

    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding)
        public
        onlyManager
    {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.taxWithholding = _taxWithholding;
    }

    function suspendUser(address _wallet) public onlyManager {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.suspend = true;
    }

    function activeUser(address _wallet) public onlyManager {
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.suspend = false;
    }

    function updateUserType(address _wallet, string memory _userType)
        public
        onlyManager
    {
        require(
            StringUtils.equal(_userType, "Basic") ||
                StringUtils.equal(_userType, "Premium"),
            "Please Enter Valid User Type"
        );
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.userType = _userType;
    }

    // Check user status
    function isWhitelistedUser(address wallet) public view returns (uint256) {
        whitelistInfo storage u = whitelistUsers[wallet];
        whitelistInfoManager memory m = whitelistManagers[wallet];
        whitelistInfoMediaRoles memory mediaRole = whitelistMediaRoles[wallet];

        /* Wallet is Super Admin */
        if (StringUtils.equal(admins[wallet], "superAdmin")) return 100;
        
        /* Wallet is subSuper Admin */
        if (StringUtils.equal(admins[wallet], "subSuperAdmin")) return 101;

        /* Wallet is Fee Admin */
        if (StringUtils.equal(admins[wallet], "fee")) return 110;

        /* Wallet is Dev Admin */
        if (StringUtils.equal(admins[wallet], "dev")) return 111;

        /* Wallet is Simple Admin */
        if (StringUtils.equal(admins[wallet], "admin")) return 112;

        /* Wallet is Manager Finance */
        if (StringUtils.equal(m.role, "finance")) return 120;

        /* Wallet is Manager asset */
        if (StringUtils.equal(m.role, "assets")) return 121;

        /* Wallet is Manager asset */
        if (StringUtils.equal(m.role, "signer")) return 122;

        /* Wallet is HR Media Role */
        if (StringUtils.equal(mediaRole.role, "HR")) return 123;

         /* Wallet is digitalMedia Role */
        if (StringUtils.equal(mediaRole.role, "digitalMedia")) return 124;

         /* Wallet is marketing Media Role */
        if (StringUtils.equal(mediaRole.role, "marketing")) return 125;

        /* Wallet is Bank  */
        if (StringUtils.equal(banks[wallet], "bank")) return 130;

        /* Wallet is Owner  */
        if (StringUtils.equal(owners[wallet], "owner")) return 140;
        
        /* Wallet is Property Account  */
        if (StringUtils.equal(propertyAccount[wallet], "propertyAccount")) return 150;

        // /* Any type of Manager */
        // if(isWhitelistedManager(wallet)) return 200;
        /* Wallet is not Added */
        else if (!u.valid) return 404;
        /* If User is Suspendid */
        else if (u.suspend) return 401;
        /* Wallet KYC Expired */
        else if (!u.kycVerified) return 400;
        /* If Accredation check is false then Send 200 */
        else if (!accreditationCheck) return 200;
        /* Wallet AML Expired */
        else if (u.accredationExpiry <= block.timestamp) return 201;
        /* Wallet is Whitelisted */
        else return 200;
    }

    function removeWhitelistedUser(address _wallet) public onlyManager {
        _userWhitelisteds.remove(_wallet);
        whitelistInfo storage u = whitelistUsers[_wallet];
        u.valid = false;
    }

    /* Symbols Deployed Add to Contract */
    function addSymbols(string calldata _symbols)
        external
        returns (
            // onlyManager
            bool
        )
    {
        if (symbolsDef[_symbols] == true) return false;
        else {
            symbolsDef[_symbols] = true;
            return true;
        }
    }

    // On destroy Symbol Removed
    function removeSymbols(string calldata _symbols)
        external
        onlyManager
        returns (bool)
    {
        if (symbolsDef[_symbols] == true) symbolsDef[_symbols] = false;
        return true;
    }

    function closeTokenismWhitelist() public {
        require(
            StringUtils.equal(admins[_msgSender()], "superAdmin"),
            "only superAdmin can destroy Contract"
        );
        selfdestruct(payable(msg.sender));
    }

    function storedAllData()
        public
        view
        onlyAdmin
        returns (
            address[] memory _userList,
            bool[] memory _validity,
            bool[] memory _kycVery,
            bool[] memory _accredationVery,
            uint256[] memory _accredationExpir,
            uint256[] memory _taxWithHold,
            uint256[] memory _userTypes
        )
    {
        uint256 size = userList.length;

        bool[] memory validity = new bool[](size);
        bool[] memory kycVery = new bool[](size);
        bool[] memory accredationVery = new bool[](size);
        uint256[] memory accredationExpir = new uint256[](size);
        uint256[] memory taxWithHold = new uint256[](size);
        uint256[] memory userTypes = new uint256[](size);
        uint256 i;
        for (i = 0; i < userList.length; i++) {
            if (whitelistUsers[userList[i]].valid) {
                validity[i] = true;
            } else {
                validity[i] = false;
            }
            if (whitelistUsers[userList[i]].kycVerified) {
                kycVery[i] = true;
            } else {
                kycVery[i] = false;
            }
            if (whitelistUsers[userList[i]].accredationVerified) {
                accredationVery[i] = true;
            } else {
                accredationVery[i] = false;
            }
            accredationExpir[i] = (
                whitelistUsers[userList[i]].accredationExpiry
            );
            taxWithHold[i] = (whitelistUsers[userList[i]].taxWithholding);
            if (
                StringUtils.equal(whitelistUsers[userList[i]].userType, "Basic")
            ) {
                userTypes[i] = 20;
            } else userTypes[i] = 100;
        }
        return (
            userList,
            validity,
            kycVery,
            accredationVery,
            accredationExpir,
            taxWithHold,
            userTypes
        );
    }

    function userType(address _caller) public view returns (bool) {
        if (StringUtils.equal(whitelistUsers[_caller].userType, "Premium"))
            return true;
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../utils/stringUtils.sol";

import "@openzeppelin/contracts/utils/Address.sol";
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract TokenismAdminWhitelist is Context {
    using Roles for Roles.Role;
    Roles.Role private _managerWhitelisteds;
    Roles.Role private _mediaRolesWhitelisteds;


    //  Add multiple admins option
    mapping(address => string) public admins;
    // add Multiple Banks aption
    mapping(address => string) public banks;
    // add Multiple Owners Options
    mapping(address => string) public owners;

    mapping(address=>string) public propertyAccount; 
    
     //  Add multiple media roles option

    address superAdmin;
    address feeAddress;
    address subSuperAdmin;
    //  Setting FeeStatus and fee Percent by Tokenism
    //  uint8 feeStatus;
    //  uint8 feePercent;
    bool public accreditationCheck = true;

    struct whitelistInfoManager {
        address wallet;
        string role;
        bool valid;
    }

    mapping(address => whitelistInfoManager) whitelistManagers;

    struct whitelistInfoMediaRoles {   
        address wallet;
        string role;
        bool valid;
    }
    mapping(address => whitelistInfoMediaRoles) whitelistMediaRoles;

    constructor() {
        // admin = _msgSender();
        require(!Address.isContract(_msgSender()),"Super admin cant be Contract address");
        admins[_msgSender()] = "superAdmin";
        superAdmin = msg.sender;
    }

    function addSuperAdmin(address _superAdmin) public {
        require(!Address.isContract(_superAdmin),"Super admin cant be Contract address");
        require(msg.sender == superAdmin, "Only super admin can add admin");
        admins[_superAdmin] = "superAdmin";
        admins[superAdmin] = "dev";
        superAdmin = _superAdmin;
    }

     function addSubSuperAdmin(address _subSuperAdmin) public {
         require(!Address.isContract(_subSuperAdmin),"Super admin cant be Contract address");
        require(msg.sender == superAdmin, "Only super admin can add sub super admin");
        admins[_subSuperAdmin] = "subSuperAdmin";
        subSuperAdmin = _subSuperAdmin;
    }

    modifier onlyAdmin() {
        require(
            StringUtils.equal(admins[_msgSender()], "superAdmin") ||
                StringUtils.equal(admins[_msgSender()], "dev") ||
                StringUtils.equal(admins[_msgSender()], "fee") ||
                StringUtils.equal(admins[_msgSender()], "admin"),
            "Only admin is allowed"
        );
        _;
    }

    modifier onlyManager() {
        require(
            isWhitelistedManager(_msgSender()) ||
                StringUtils.equal(admins[_msgSender()], "superAdmin") ||
                StringUtils.equal(admins[_msgSender()], "dev") ||
                StringUtils.equal(admins[_msgSender()], "fee") ||
                StringUtils.equal(admins[_msgSender()], "admin"),
            "AKRU_Whitelist: caller does not have the Manager role"
        );
        _;
    }
     modifier onlyMedia() {
        require(
            isWhitelistedMediaRole(_msgSender()) ||
                StringUtils.equal(admins[_msgSender()], "superAdmin") ||
                StringUtils.equal(admins[_msgSender()], "dev") ||
                StringUtils.equal(admins[_msgSender()], "fee") ||
                StringUtils.equal(admins[_msgSender()], "admin"),
            "AKRU_AdminWhitelist: caller does not have the Media role"
        );
        _;
    }

    // Update Accredential Status
    function updateAccreditationCheck(bool status) public onlyManager {
        accreditationCheck = status;
    }

    // Roles
   
    function addWhitelistedMediaRoles(address _wallet, string memory _role)
        public
        onlyAdmin
    {
        require(
            StringUtils.equal(_role, "HR") ||
                StringUtils.equal(_role, "digitalMedia") ||
                StringUtils.equal(_role, "marketing"),
            "AKRU_AdminWhitelist: caller does not have the media role"
        );

        whitelistInfoMediaRoles storage newMediaRole = whitelistMediaRoles[_wallet];

        _mediaRolesWhitelisteds.add(_wallet);
        newMediaRole.wallet = _wallet;
        newMediaRole.role = _role;
        newMediaRole.valid = true;
        
    }
    function getMediaRole(address _wallet)
        public
        view
        returns (string memory)
    {
        whitelistInfoMediaRoles storage m = whitelistMediaRoles[_wallet];
        return m.role;
    }

    function updateMediaRole(address _wallet, string memory _role)
        public
        onlyAdmin
    {
        require(
           StringUtils.equal(_role, "HR") ||
                StringUtils.equal(_role, "digitalMedia") ||
                StringUtils.equal(_role, "marketing"),
            "AKRU_AdminWhitelist: Invalid  Media role"
        );
        whitelistInfoMediaRoles storage m = whitelistMediaRoles[_wallet];
        m.role = _role;
    }

    function isWhitelistedMediaRole(address _wallet) public view returns (bool) {
        whitelistInfoMediaRoles memory m = whitelistMediaRoles[_wallet];

        if (
            StringUtils.equal(admins[_wallet], "superAdmin") ||
            StringUtils.equal(admins[_wallet], "dev") ||
            StringUtils.equal(admins[_wallet], "fee") ||
            StringUtils.equal(admins[_wallet], "admin")
        ) return true;
        else if (!m.valid) return false;
        else return true;
    }

    function removeWhitelistedMediaRole(address _wallet) public onlyAdmin {
        _mediaRolesWhitelisteds.remove(_wallet);
        whitelistInfoMediaRoles storage m = whitelistMediaRoles[_wallet];
        m.valid = false;
    }

     function addWhitelistedManager(address _wallet, string memory _role)
        public
        onlyAdmin
    {
        require(
            StringUtils.equal(_role, "finance") ||
                StringUtils.equal(_role, "signer") ||
                StringUtils.equal(_role, "assets"),
            "AKRU_AdminWhitelist: caller does not have the Manager role"
        );
        whitelistInfoManager storage newManager = whitelistManagers[_wallet];

        _managerWhitelisteds.add(_wallet);
        newManager.wallet = _wallet;
        newManager.role = _role;
        newManager.valid = true;
       
    }

    function getManagerRole(address _wallet)
        public
        view
        returns (string memory)
    {
        whitelistInfoManager storage m = whitelistManagers[_wallet];
        return m.role;
    }

    function updateRoleManager(address _wallet, string memory _role)
        public
        onlyAdmin
    {
        require(
            StringUtils.equal(_role, "finance") ||
                StringUtils.equal(_role, "signer") ||
                StringUtils.equal(_role, "assets"),
            "AKRU_AdminWhitelist: Invalid  Manager role"
        );
        whitelistInfoManager storage m = whitelistManagers[_wallet];
        m.role = _role;
    }

    function isWhitelistedManager(address _wallet) public view returns (bool) {
        whitelistInfoManager memory m = whitelistManagers[_wallet];

        if (
            StringUtils.equal(admins[_wallet], "superAdmin") ||
            StringUtils.equal(admins[_wallet], "dev") ||
            StringUtils.equal(admins[_wallet], "fee") ||
            StringUtils.equal(admins[_wallet], "admin")
        ) return true;
        else if (!m.valid) return false;
        else return true;
    }

    // Only Super Admin
    function removeWhitelistedManager(address _wallet) public onlyAdmin {
        _managerWhitelisteds.remove(_wallet);
        whitelistInfoManager storage m = whitelistManagers[_wallet];
        m.valid = false;
    }

    function transferOwnership(address _newAdmin) public returns (bool) {
        // admin = _newAdmin;
        require(_msgSender() == superAdmin || _msgSender() == subSuperAdmin, "Only super admin can add admin");
        admins[_newAdmin] = "superAdmin";
        admins[superAdmin] = "";
        superAdmin = _newAdmin;

        return true;
    }

    function addAdmin(address _newAdmin, string memory _role)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            _msgSender() == superAdmin || Address.isContract(_newAdmin) || _msgSender() == subSuperAdmin,
            "Only super admin can add admin"
        );
        require(
            StringUtils.equal(_role, "dev") ||
                StringUtils.equal(_role, "fee") ||
                StringUtils.equal(_role, "admin"),
            "undefind admin role"
        );
        admins[_newAdmin] = _role;
        return true;
    }
    function removeAdmin(address _adminAddress) 
        public 
        returns (bool)
    {
         require(
            _msgSender() == superAdmin || _msgSender() == subSuperAdmin,
            "Only super admin can remove admin"
        );
        delete admins[_adminAddress];
        return true;
    }
    function addBank(address _newBank, string memory _role)
        public
        onlyAdmin
        returns (bool)
    {
        require(
            _msgSender() == superAdmin || Address.isContract(_newBank) || _msgSender() == subSuperAdmin,
            "Only super admin can add admin"
        );
        require(StringUtils.equal(_role, "bank"), "undefind bank role");
        banks[_newBank] = _role;
        return true;
    }
    function removeBank(address _bank)
        public
        returns (bool)
    {
        require(
            _msgSender() == superAdmin || _msgSender() == subSuperAdmin,
            "Only super admin can remove admin"
        );
        delete banks[_bank];
        return true;
    }
    //* Property Owner
     function addPropertyOwner(address _newOwner, string memory _role)
        public
        onlyManager
        returns (bool)
    {
        require(StringUtils.equal(_role, "owner"), "undefind owner role");
        owners[_newOwner] = _role;
        return true;
    }
    function removePropertyOwner(address _newOwner)
        public
        returns (bool)
    {
        require(
            _msgSender() == superAdmin || _msgSender() == subSuperAdmin,
            "Only super admin can remove admin"
        );
        delete owners[_newOwner];
        return true;
    }




    function addPropertyAccount( address _newOwner,string memory _role)
        public
        onlyManager
        returns (bool)
    {
        require(StringUtils.equal(_role, "propertyAccount"), "undefind propertyAccount role");
        propertyAccount[_newOwner] = _role;
        return true;
    }
    function removePropertyAccount(address _newOwner)
        public
        returns (bool)
    {
        require(
            _msgSender() == superAdmin || _msgSender() == subSuperAdmin,
            "Only super admin can remove admin"
        );
        delete propertyAccount[_newOwner];
        return true;
    }



    // Function Add Fee Address
    function addFeeAddress(address _feeAddress) public {
        require(
            _msgSender() == superAdmin || _msgSender() == subSuperAdmin,
            "Only super admin can add Fee Address"
        );
        feeAddress = _feeAddress;
    }

    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }

    // // Fee On off functionality
    // function setFeeStatus(uint8 option) public returns(bool){ // Fee option must be 0, 1
    //     require(msg.sender == superAdmin, "Only SuperAdmin on off fee");
    //     require(option == 1 || option == 0, "Wrong option call only 1 for on and 0 for off");
    //     require(feePercent > 0, "addPlatformFee! You must have set platform fee to on fee");
    //     feeStatus = option;
    //     return true;
    // }
    // // Get Fee Status
    //     return feeStatus;
    // }
    // // Add Fee Percent or change Fee Percentage on Tokenism Platform
    // function addPlatformFee(uint8 _fee)public returns(bool){
    //     require(msg.sender == superAdmin, "Only SuperAmin change Platform Fee");
    //     require(_fee > 0 && _fee < 100, "Wrong Percentage!  Fee must be greater 0 and less than 100");
    //     feePercent = _fee;
    //     return true;

    // }
    //  return feePercent;
    // }
    function isAdmin(address _calle) public view returns (bool) {
        if (
            StringUtils.equal(admins[_calle], "superAdmin") ||
            StringUtils.equal(admins[_calle], "dev") ||
            StringUtils.equal(admins[_calle], "fee") ||
            StringUtils.equal(admins[_calle], "admin")
        ) {
            return true;
        }
        return false;
        //  return admins[_calle];
    }

    function isSuperAdmin(address _calle) public view returns (bool) {
        if (StringUtils.equal(admins[_calle], "superAdmin")) {
            return true;
        }
        return false;
    }
    function isSubSuperAdmin(address _calle) public view returns (bool) {
        if (StringUtils.equal(admins[_calle], "subSuperAdmin")) {
            return true;
        }
        return false;
    }

    function isBank(address _calle) public view returns (bool) {
        if (StringUtils.equal(banks[_calle], "bank")) {
            return true;
        }
        return false;
    }
    function isOwner(address _calle) public view returns (bool) {
        if (StringUtils.equal(owners[_calle], "owner")) {
            return true;
        }
        return false;
    }

    function isManager(address _calle) public view returns (bool) {
        whitelistInfoManager memory m = whitelistManagers[_calle];
        return m.valid;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b)
        internal
        pure
        returns (int256)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }

    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle)
        internal
        pure
        returns (int256)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) return -1;
        else if (h.length > (2**128 - 1))
            // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
            return -1;
        else {
            uint256 subindex = 0;
            for (uint256 i = 0; i < h.length; i++) {
                if (h[i] == n[0]) // found the first char of b
                {
                    subindex = 1;
                    while (
                        subindex < n.length &&
                        (i + subindex) < h.length &&
                        h[i + subindex] == n[subindex] // search until the chars don't match or until we reach the end of a or b
                    ) {
                        subindex++;
                    }
                    if (subindex == n.length) return int256(i);
                }
            }
            return -1;
        }
    }

    // function toBytes(address a) 
    //    internal
    //     pure
    //     returns (bytes memory) {
    // return abi.encodePacked(a);
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
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
}