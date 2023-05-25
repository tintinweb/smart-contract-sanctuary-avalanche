// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IwhitelistNFT.sol";
/**
 * @title AkruAdminWhitelist
 * @author Umar Mubeen
 * @dev AkruAdminWhitelist to whitlist of AKRU's users
 */
contract AkruNFTAdminWhitelist is
    Ownable
{  
    IwhitelistNFT public NFT; //ERC721 being used in whitelisting
    address public superAdmin;
    address feeAddress;
    bool public accreditationCheck = true;
    address[] public userList;
    //store the prefix of NFT id associated with each role
    mapping(ROLES => uint256) public roleIdPrefix;
    //store the each role struct against id
    mapping(address => uint256) userNftIds; //added mapping
    mapping(address => ROLES) userRoleIndex; //added mapping
    mapping(ROLES => string) userRoleNames; //added mapping

    mapping(address => WhitelistInfo) whitelistUsers;
    mapping(ROLES => uint256) userWhitelistNumber; //added mapping


      /**
     * @dev enum of different roles
     */
    enum ROLES {
        unRegister,
        superAdmin,
        subSuperAdmin,
        admin,
        manager,
        mediaManager,
        propertyOwner,
        propertyAccount,
        propertyManager,
        serviceProvider,
        subServiceProvider,
        bank,
        user_USA, //12
        user_Foreign //13
    }
    /**
    *@dev it takes NFT address and then mint nft to create super admin 
        add and entry to roleInfo mapping. 
    */
    constructor(address nftAddress) {
        NFT =IwhitelistNFT(nftAddress);
        superAdmin = _msgSender();
        initializeRoleIdPrefix();
        whitelistUsers[msg.sender] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: msg.sender,
            kycVerified: true,
            accredationExpiry: 0,
            accredationVerified: true,
            role: ROLES.superAdmin,
            userRoleId: 11,
            isPremium: false
        });
        userRoleIndex[msg.sender] = ROLES.superAdmin;
    }
    struct WhitelistInfo {
        bool valid;
        bool kycVerified;
        bool accredationVerified;
        uint256 accredationExpiry;
        uint256 taxWithholding;
        ROLES role;
        uint256 userRoleId;
        bool isPremium;
        address wallet; // Moved to the end
    }
    event AddWhitelistRole(address user,uint256 nftId,ROLES role,address caller);
    event AddSuperAdmin(address sender,address superAdmin, uint256 nftId, uint256 roleInfoId);
    event SetRoleIdPrefix(ROLES role, uint256 prefix);
    event UpdateAccreditationCheck(bool status, address caller);
    event RemoveWhitelistedRole(address user, ROLES role, uint256 roleInfoId);
    event AddFeeAddress(address feeAddress, address sender);
    /**
     * @dev method works as modifier to allow only super admin
     */
    function onlySuperAdmin() internal view {
        require(
            userRoleIndex[_msgSender()] == ROLES.superAdmin ,
            "W8"
        );
    }
    /**
     * @dev method works as modifier to allow only superAdmin & sub-superAdmin
     */
    function onlySuperAndSubSuperAdmin() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        require(
            (isSuperAdminRange || isSubSuperAdminRange),
            "W9"
        );
    }
    /**
     * @dev method works as modifier to allow only superAdmin, sub-superAdmin and admin
     */
    function onlyAdmin() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        bool isAdminRange = userRoleIndex[_msgSender()] == ROLES.admin;
        // checkAdminRole(_msgSender(), ROLES.admin);
        require(
            (isSuperAdminRange || isSubSuperAdminRange || isAdminRange),
            "W10"
        );
    }
    /**
        * @dev method works as modifier to allow only 
         superAdmin, sub-superAdmin,admin and manager 
    */
    function onlyManager() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        bool isAdminRange = userRoleIndex[_msgSender()] == ROLES.admin;
        bool isManagerRange = userRoleIndex[_msgSender()] == ROLES.manager;

        require(
            (isSuperAdminRange ||
                isSubSuperAdminRange ||
                isAdminRange ||
                isManagerRange),
            "W11"
        );
    }

    /**
        * @dev method works as modifier to allow only 
            superAdmin, sub-superAdmin,admin and media-manager
    */
    function onlyMediaManager() internal view {
        bool isSuperAdminRange = userRoleIndex[_msgSender()] == ROLES.superAdmin; 
        bool isSubSuperAdminRange =  userRoleIndex[_msgSender()] == ROLES.subSuperAdmin;
        bool isAdminRange = userRoleIndex[_msgSender()] == ROLES.admin;
        bool isMediaMan = userRoleIndex[_msgSender()] == ROLES.mediaManager;
        require(
            (isSuperAdminRange ||
                isSubSuperAdminRange ||
                isAdminRange ||
                isMediaMan),
            "W12"
        );
    }
    /**
     *@dev it only allow user with specific role to add other roles.
     *@param user user address to assign role
     *@param nftId to be associated with role.
     *@param role that willbe assigned.
     */
    function addManageralRole(address user, uint256 nftId, ROLES role) public {
        if (role == ROLES.subSuperAdmin) {
            onlySuperAdmin();
        }
        if (role == ROLES.admin) {
            onlySuperAndSubSuperAdmin();
        }
        if (
            role == ROLES.manager ||
            role == ROLES.mediaManager ||
            role == ROLES.bank ||
            role == ROLES.propertyAccount ||
            role == ROLES.propertyOwner ||
            role == ROLES.propertyManager ||
            role == ROLES.serviceProvider ||
            role == ROLES.subServiceProvider
        ) {
            onlyAdmin();
        }
        require(role != ROLES.superAdmin, "W13");
        require(!whitelistUsers[user].valid, "W1");
        uint256 roleToId = getIdPrefix(nftId);
        require(roleIdPrefix[role] == roleToId, "W2");
        require(nftId > 10, "W14");
        whitelistUsers[user] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: user,
            kycVerified: true,
            accredationExpiry: 0,
            accredationVerified: true,
            role: role,
            userRoleId: nftId,
            isPremium: false
        });
        userNftIds[user] = nftId; // storing nft id against the user in mapping
        userRoleIndex[user] = role; //storing role in a mapping
        NFT.mintToken(user, nftId);
        emit AddWhitelistRole(user, nftId, role,_msgSender());
    }
    /**
     *@dev it only allow super admin to remove roles.
     *@param user that need to be removed from role.
     *@param role that will be removed.
     */
    function removeManageralRole(address user, ROLES role) public {
        require(role != ROLES.superAdmin,"W15" );
        if (      
            role == ROLES.subSuperAdmin ||
            role == ROLES.admin
        ) {
            onlySuperAdmin();
        }
        if (
            role == ROLES.manager ||
            role == ROLES.mediaManager ||
            role == ROLES.bank ||
            role == ROLES.propertyAccount ||
            role == ROLES.propertyOwner ||
            role == ROLES.propertyManager ||
            role == ROLES.serviceProvider ||
            role == ROLES.subServiceProvider
        ) {
            onlyAdmin();
        }
        require(userRoleIndex[user] == role, "W4");
        uint256 nftIds =userNftIds[user];//change
        NFT.burnToken(nftIds);
        delete whitelistUsers[user];
        delete userRoleIndex[user];
        emit RemoveWhitelistedRole(user, role, nftIds);
    }
    /**
     *@dev add the super admin role , 
        this method willbe called just after deployment of the whitelisting smart contract
     */
    function renounceSuperAdmin(address newSuperAdmin) external {
        onlySuperAdmin();
        require(NFT.ownerOf(11) == msg.sender,"W7");
         NFT.transferOwnerShip(_msgSender(), newSuperAdmin, 11);
         whitelistUsers[newSuperAdmin] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: newSuperAdmin,
            kycVerified: true,
            accredationExpiry: 0,
            accredationVerified: true,
            role: ROLES.superAdmin,
            userRoleId: 11,
            isPremium: false
        });
        emit AddSuperAdmin(_msgSender(), newSuperAdmin, 11, 11);
    }
    /**
     * @dev Update Accredential Status
     * @param status true/false
     */
    function updateAccreditationCheck(bool status) public {
        onlyManager();
        accreditationCheck = status;
        emit UpdateAccreditationCheck(status, _msgSender());
    }

    /**
     * @dev whitelist the feeAddress in AKRU
     * @param _feeAddress address of new fee address
     */
    function addFeeAddress(address _feeAddress) public {
        onlySuperAndSubSuperAdmin();
        feeAddress = _feeAddress;
        emit AddFeeAddress(_feeAddress, msg.sender);
    }
    /**
     * @dev return the feeAddress in AKRU
     * @return feeAddress
     */
    function getFeeAddress() public view returns (address) {
        return feeAddress;
    }
    /**
     * @dev return the status of admin in AKRU
     * @param calle address of admin
     * @return true/false
     */
    function isAdmin(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.admin;
    }
    /**
     * @dev return the status of super admin in AKRU
     * @param calle address of super admin
     * @return true/false
     */
    function isSuperAdmin(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.superAdmin;
    }
    /**
     * @dev return the status of sub super admin in AKRU
     * @param calle address of sub super admin
     * @return true/false
     */
    function isSubSuperAdmin(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.subSuperAdmin;
    }
    /**
     * @dev return the status of bank in AKRU
     * @param calle address of bank
     * @return true/false
     */
    function isBank(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.bank;
    }
    /**
     * @dev return the status of property owner in AKRU
     * @param calle address of property owner
     * @return true/false
     */
    function isOwner(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.propertyOwner;
    }
    /**
     * @dev return the status of manager in AKRU
     * @param calle address of manager
     * @return true/false
     */
    function isManager(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.manager;
    }
        /**
     * @dev check the media manager role
     * @param calle  Address of manager
     * @return role status
     */
    function isMediaManager(address calle) public view returns (bool) {
        return userRoleIndex[calle] == ROLES.mediaManager;
    }
    /**
     * @dev set the nft ID prefix (2 digits) for specific role.
     * @param IdPrefix nft id prefix value
     * @param role associated role with nft id prefix.
     */
    function setRoleIdPrefix(ROLES role, uint256 IdPrefix) internal {
        roleIdPrefix[role] = IdPrefix;
        emit SetRoleIdPrefix(role, IdPrefix);
    }

    /**
     * @dev return the NFTId prefix of given role
     * @param role to check prefix.
     */
    function getRoleIdPrefix(ROLES role) public view returns (uint256) {
        return roleIdPrefix[role];
    }
    /**
     * @dev it returs the first 2 digit of NFT id.
     * @param id nft id to get first 2 digits
     */
    function getIdPrefix(uint id) internal pure returns (uint) {
        uint divisor = 1;
        while (id / divisor >= 100) {
            divisor *= 10;
        }
        uint result = id / divisor;
        return result % 100;
    }
    /**
     * @dev it initializes and associate the each role with specific ID prefix.
     */
    function initializeRoleIdPrefix() internal {
        setRoleIdPrefix(ROLES.superAdmin, 11);
        setRoleIdPrefix(ROLES.subSuperAdmin, 12);
        setRoleIdPrefix(ROLES.admin, 13);
        setRoleIdPrefix(ROLES.manager, 14);
        setRoleIdPrefix(ROLES.mediaManager, 15);
        setRoleIdPrefix(ROLES.bank, 16);
        setRoleIdPrefix(ROLES.propertyAccount, 17);
        setRoleIdPrefix(ROLES.propertyOwner, 18);
        setRoleIdPrefix(ROLES.propertyManager, 19);
        setRoleIdPrefix(ROLES.user_USA, 21);
        setRoleIdPrefix(ROLES.user_Foreign, 22);
        setRoleIdPrefix(ROLES.serviceProvider, 23);
        setRoleIdPrefix(ROLES.subServiceProvider, 24);
        /// Setting Each role with specific code for users
        userWhitelistNumber[ROLES.superAdmin] = 100;
        userWhitelistNumber[ROLES.subSuperAdmin] = 101;
        userWhitelistNumber[ROLES.admin] = 112;
        userWhitelistNumber[ROLES.manager] = 120;
        userWhitelistNumber[ROLES.mediaManager] = 125;
        userWhitelistNumber[ROLES.propertyAccount] = 132;
        userWhitelistNumber[ROLES.bank] = 130;
        userWhitelistNumber[ROLES.propertyOwner] = 140;
        userWhitelistNumber[ROLES.propertyManager] = 135;
        userWhitelistNumber[ROLES.user_USA] = 200;
        userWhitelistNumber[ROLES.user_Foreign] = 200;
        userWhitelistNumber[ROLES.serviceProvider] = 200;
        userWhitelistNumber[ROLES.subServiceProvider] = 200;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "./AkruNFTAdminWhitelist.sol";
/**
 * @title AkruWhitelist
 * @dev AkruWhitelist to whitlist of AKRU's users
 */
contract AkruNFTWhitelist is AkruNFTAdminWhitelist {
    mapping(string => bool) symbolsDef;
     constructor(address nftAddress) AkruNFTAdminWhitelist(nftAddress) {}
    event RemoveWhitelistedUser(address user, ROLES role, uint256 roleInfoId);
    event AddWhitelistUser(address user,ROLES role,uint256 userId,uint256 accreditationExpire,bool isAccredated,bool isKycVerified);
    event UpdateAccredationWhitelistedUser(address user, uint256 accredation);
    event UpdateTaxWhitelistedUser(address user, uint256 taxWithholding);
    event UpdateUserAccredationStatus(address caller, address user, bool status);
    event UpdateUserType(address caller, address user, bool status);
    event SetRoleNames(address user, ROLES _value, string _name);
    event setWhitelistUserNumber(ROLES _value, uint256 _num);
    event SetWhitelistNumber(address sender,ROLES value, uint256 roleNum);
    event RemoveWhitelistNumber(address caller, ROLES value);

    /**
     * @dev whitelist the user with specfic KYC and accredation verified check and time in AKRU
     * @param _wallet  Address of new user
     * @param _kycVerified is kyc true/false
     * @param _accredationVerified is accredation true/false
     * @param _accredationExpiry accredation expiry date in unix time
     */
    function addWhitelistUser(
        address _wallet,
        bool _kycVerified,
        bool _accredationVerified,
        uint256 _accredationExpiry,
        ROLES role,
        uint256 nftId
    ) public {
        onlyManager();
        require(!whitelistUsers[_wallet].valid, "W1");
        uint256 roleToId = getIdPrefix(nftId);
        require(roleIdPrefix[role] == roleToId, "W2");
        require(
            roleToId > 14,
            "W3"
        );
        NFT.mintToken(_wallet, nftId);
        userList.push(_wallet);
        whitelistUsers[_wallet] = WhitelistInfo({
            valid: true,
            taxWithholding: 0,
            wallet: _wallet,
            kycVerified: _kycVerified,
            accredationExpiry: _accredationExpiry,
            accredationVerified: _accredationVerified,
            role: role,
            userRoleId: nftId,
            isPremium: false
        });
        userNftIds[_wallet] = nftId; // storing nft id against the user in mapping
        userRoleIndex[_wallet] = role; //storing role in a mapping
        emit AddWhitelistUser(
            _wallet,
            role,
            nftId,
            _accredationExpiry,
            _accredationVerified,
            _kycVerified
        );
    }
    /**
     * @dev get the user with specfic KYC and accredation verified check and time in AKRU
     * @param _wallet  Address of  user
     * @return _wallet  Address of  user
     * @return _kycVerified is kyc true/false
     * @return _accredationVerified is accredation true/false
     * @return _accredationExpiry accredation expiry date in unix time
     */
    function getWhitelistedUser(
        address _wallet)
        public
        view
        returns (address, bool, bool, uint256, ROLES, uint256, uint256, bool)
       {
        WhitelistInfo memory u = whitelistUsers[_wallet];
        return (
            u.wallet,
            u.kycVerified,
            u.accredationExpiry >= block.timestamp,
            u.accredationExpiry,
            u.role,
            u.taxWithholding,
            u.userRoleId,
            u.valid
        );
    }
    /**
     * @dev remove the whitelisted user , burn nft and update structs
     * @param user  Address of user being removed
     * @param role role that need to be removed.
     */
    function removeWhitelistedUser(address user, ROLES role) public {
        onlyManager();
        require(userRoleIndex[user] == role, "W4");
        uint256 nftIds = userNftIds[user];
        delete whitelistUsers[user];
        delete userRoleIndex[user];
        NFT.burnToken(nftIds);
        emit RemoveWhitelistedUser(user, role, nftIds);
    }
    /**
     * @dev update the user with specfic accredation expiry date in AKRU
     * @param _wallet  Address of user
     * @param  _accredationExpiry accredation expiry date in unix time
     */
    function updateAccredationWhitelistedUser(
        address _wallet,
        uint256 _accredationExpiry
      ) public {
        onlyManager();
        require(_accredationExpiry >= block.timestamp,"W5");
        WhitelistInfo storage u = whitelistUsers[_wallet];
        u.accredationExpiry = _accredationExpiry;
        u.accredationVerified = true;
        emit UpdateAccredationWhitelistedUser(_wallet, _accredationExpiry);
    }
    /**
     * @dev update the user with new tax holding in AKRU
     * @param _wallet  Address of user
     * @param  _taxWithholding  new taxWithholding
     */
    function updateTaxWhitelistedUser(
        address _wallet,
        uint256 _taxWithholding
    ) public {
        onlyAdmin();
        WhitelistInfo storage u = whitelistUsers[_wallet];
        u.taxWithholding = _taxWithholding;
        emit UpdateTaxWhitelistedUser(_wallet, _taxWithholding);
    }

    /**
     * @dev Symbols Deployed Add to Contract
     * @param _symbols string of new symbol added in AKRU
     */
    function addSymbols(string calldata _symbols) external returns (bool) {
        onlyManager();
        if (symbolsDef[_symbols] == true) return false;
        else {
            symbolsDef[_symbols] = true;
            return true;
        }
    }
    /**
     * @dev removed Symbol from Contract
     * @param _symbols string of already added symbol in AKRU
     */
    function removeSymbols(string calldata _symbols) external returns (bool) {
        onlyManager();
        if (symbolsDef[_symbols] == true) symbolsDef[_symbols] = false;
        return true;
    }
    /**
     * @dev returns the status of kyc of user.
     * @param user address to verify the KYC.
     */
    function isKYCverfied(address user) public view returns (bool) {
        WhitelistInfo memory info = whitelistUsers[user];
        return info.kycVerified;
    }
    /**
     *
     * @dev Update User Type to Premium
     * @param user address of User whose want to update as premium
     * @param status it will update of status premium of user
     */
    function updateUserType(address user, bool status) public {
        onlyManager();
        require(whitelistUsers[user].valid, "W6");
        whitelistUsers[user].isPremium = status;
        emit UpdateUserType(msg.sender, user, status);
    }
    /**
     * @dev returns the status of accredation of user.
     * @param user address to verify the accredation.
     */
    function isAccreditationVerfied(address user) public view returns (bool) {
        WhitelistInfo memory info = whitelistUsers[user];
        return info.accredationExpiry > block.timestamp;
    }
    /**
     * @dev return the status of USA user in AKRU
     * @param user address of sub super admin
     * @return true/false
     */
    function isUserUSA(address user) public view returns (bool) {
        if (userRoleIndex[user] == ROLES.user_USA) {
            if (accreditationCheck) {
                return
                    whitelistUsers[user].accredationExpiry >= block.timestamp;
            } else return true;
        }else{
            return false;
        }
    }
    /**
     * @dev return the status of Foreign user in AKRU
     * @param user address of sub super admin
     * @return true/false
     */
    function isUserForeign(address user) public view returns (bool) {
        return userRoleIndex[user] == ROLES.user_Foreign;
    }
    /**
     * @dev return the type of the user
     * @param caller address of the user
     */
    function isPremiumUser(address caller) public view returns (bool success) {
        return whitelistUsers[caller].isPremium;
    }
    /**
     * @dev return white listed user information
     * @param user address of the user
     */
    function getWhitelistInfo(
        address user
    )
        public
        view
        returns (
            bool valid,
            address wallet,
            bool kycVerified,
            bool accredationVerified,
            uint256 accredationExpiry,
            uint256 taxWithholding,
            ROLES role,
            uint256 userRoleId
        )
    {
        WhitelistInfo memory info = whitelistUsers[user];
        return (
            info.valid,
            info.wallet,
            info.kycVerified,
            info.accredationVerified,
            info.accredationExpiry,
            info.taxWithholding,
            info.role,
            info.userRoleId
        );
    }
    /**
     * @dev return the role and role id hold by the given user
     * @param _userAddress address of the user.
     * function optimised to removed redandant if else statements
     */
    function isWhitelistedUser(
        address _userAddress
    ) public view returns (uint256) {
        if (whitelistUsers[_userAddress].valid) {
            ROLES roleIndex = userRoleIndex[_userAddress];
            return userWhitelistNumber[roleIndex];
        } else {
            return 400;
        }
    }
    /**
     * @dev return the role and role id hold by the given user
     * @param userAddress address of the user.
     * function optimised to remove redundant if else statements
     */
    function getUserRole(
        address userAddress
    ) public view returns (string memory roleName, ROLES value) {
        ROLES roleIs = userRoleIndex[userAddress];
        return (userRoleNames[roleIs], roleIs);
    }
    /**
     * @dev set the role number in mapping against the role id
     * @param value role id  
     * @param roleNum role number of whitelist user

     */
    function setWhitelistNumber(ROLES value, uint256 roleNum) external {
        onlyAdmin();
        userWhitelistNumber[value] = roleNum;
        emit SetWhitelistNumber(msg.sender,value, roleNum);
    }
    /**
     * 
     * @dev Remove code against role from whitelisting
     * @param value Role that passeed to removed 
     */
    function removeWhitelistNumber(ROLES value) external{
        onlyAdmin();
        require(userWhitelistNumber[value] != 0,"There is No any role exist");
        delete userWhitelistNumber[value];
        emit RemoveWhitelistNumber(msg.sender, value);
        
    }
    /**
     * @dev set the role name in mapping against the role id
     * @param name name of user role. 
     * @param value index of ROLES enum.

     */

    function setRoleName(ROLES value, string memory name) external {
        onlyAdmin();
        userRoleNames[value] = name;
        emit SetRoleNames(msg.sender,value, name);
    }
    /**
     * @dev destroy the whitelist contract
     */
    function closeTokenismWhitelist() public {
        onlySuperAdmin();
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IwhitelistNFT {
    event IssueToken(address user, uint256  tokenId, address caller);
    event TokenBurn(uint256 tokenId, address caller, bool status);
    event TokenBurnerAdded(address user, address caller, bool status);
    event TokenMinterAdded(address user, address caller, bool status);
    event TokenMinterRemoved(address user, address caller, bool status);
    event TokenBurnerRemoved(address user,  address caller, bool status);
    event OwnerTokenIds(address  user, uint256[] tokenIds);
    event AdminUpdated(address oldAdmin,address newAdmin, bool status);
    
    function mintToken(address user,uint256 tokenId) external returns (uint256);
    function burnToken(uint256 tokenId) external;
    function addTokenMinter(address minter) external;
    function removeTokenMinter(address minter) external;
    function addTokenBurner(address burner) external;
    function removeTokenBurner(address burner) external;
    function hasMinterRole(address user) external view returns (bool);
    function hasBurnerRole(address user) external view returns (bool);
    function getOwnedTokenIds(address user) external view returns (uint256[] memory);
    function getAdmin()external view returns (address);
    function updateAdmin(address newAdmin) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function transferOwnerShip(address from,address to, uint256 tokenId) external;
    

}