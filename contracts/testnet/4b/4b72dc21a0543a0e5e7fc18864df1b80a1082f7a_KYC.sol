/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Address Book Interface
interface AddressBookInterface {
    // Update ERC20 Contract Address
    function updateERC20ContractAddress(
        address ERC20ContractAddress_,
        address executor_
    ) external;

    // Get ERC20 Contract Address
    function getERC20ContractAddress() external view returns (address);

    // Update Admin Multi-Sig Contract Address
    function updateAdminMultiSigConractAddress(
        address AdminMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // Update Supply Management Multi-Sig Contract Address
    function updateSupplyManagementMultiSigConractAddress(
        address SupplyManagementMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Supply Management Multi-Sig Contract Address
    function getSupplyManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Update Fee Management Contract Address
    function updateFeeManagementConractAddress(
        address FeeManagementContractAddress_,
        address executor_
    ) external;

    // Get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);

    // Update Fee Management Multi-Sig Contract Address
    function updateFeeManagementMultiSigConractAddress(
        address FeeManagementMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Fee Management Multi-Sig Contract Address
    function getFeeManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Update Asset Protection Multi-Sig Contract Address
    function updateAssetProtectionMultiSigConractAddress(
        address AssetProtectionMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Asset Protection Multi-Sig Contract Address
    function getAssetProtectionMultiSigContractAddress()
        external
        view
        returns (address);

    // Get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // update KYC Contract Address
    function updateKYCContractAddress(
        address KYCContractAddress_,
        address executor_
    ) external;

    // get KYC Contract Address
    function getKYCContractAddress() external view returns (address);

    // update KYC Multi-Sig Contract Address
    function updateKYCMultiSigContractAddress(
        address KYCMultiSigContractAddress_,
        address executor_
    ) external;

    // get KYC Multi-Sig Contract Address
    function getKYCMultiSigContractAddress() external view returns (address);
}

// KYC Multi-Sig Interface
interface KYCMultiSigInterface {

    // KYC Proposal struct
    struct KYCProposal {
        uint256 ID;
        address PROPOSER;
        string CATEGORY;
        address[] ACCOUNTS;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // update KYC Contract Address
    function updateKYCContractAddress(address KYCContractAddress_) external;

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // create proposal
    function createProposal(
        string memory Category_,
        address[] memory accounts_,
        uint256 expiration_
    ) external;

    // approve proposal
    function approveProposal(uint256 ProposalIndex_) external;

    // revoke proposal
    function revokeProposal(uint256 ProposalIndex_) external;

    // get admin multi sig contract address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get max proposal index
    function getMaxProposalIndex() external view returns (uint256);

    // get KYC Proposal Detail
    function getKYCProposalDetail(uint256 ProposalIndex_)
        external
        view
        returns (KYCProposal memory);

    // is KYC Manger proposal approver
    function IsKYCMangerProposalApprover(
        uint256 ProposalIndex_,
        address account_
    ) external view returns (bool);

    // get proposal detail
    function getProposalDetail(
        uint256 ProposalIndex_
    ) external view returns (KYCProposal memory);

    // is  proposal approvers
    function IsProposalApprovers(
        uint256 ProposalIndex_,
        address account_
    ) external view returns (bool);
}

// KYC Interface
interface KYCInterface {
    // authorized account info
    struct AUTHORIZEDACCOUNTINFO {
        // KYC Manager
        address KYCManager;
        // account address
        address account;
        // is authorized
        bool isAuthorized;
        // authorized time
        uint256 authorizedTimestamp;
        // unauthorized time
        uint256 unauthorizeTimestamp;
    }

    // update global authorization
    function updateGlobalAuthorization(bool status_) external;

    // add addresses to the authorized addresses
    function authorizeAddresses(address[] memory accounts_) external;

    // remove addresses from mthe authorized addresses
    function unAuthorizeAddresses(address[] memory accounts_) external;

    // get contract version
    function getContractVersion() external view returns (uint256);

    // get global authorization status
    function getGlobalAuthorizationStatus() external view returns (bool);

    // is authorized address?
    function isAuthorizedAddress(address account_) external view returns (bool);

    // get authorized addresses
    function getAuthorizedAddresses() external view returns (address[] memory);

    // get authorized account info
    function getAuthorizedAccountInfo(address account_)
        external
        view
        returns (AUTHORIZEDACCOUNTINFO memory);

    // get batch authorized accounts info
    function getBatchAuthorizedAccountInfo(address[] memory accounts_)
        external
        view
        returns (AUTHORIZEDACCOUNTINFO[] memory);
}

//  KYC Contract
contract KYC is KYCInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // Address Book Contract Address
    address private _AddressBookContractAddress;

    // Address Book Contract Interface
    AddressBookInterface private _AddressBook;

    // contract version
    uint256 private _contractVersion = 1;

    // global authorization
    bool private _globalAuthorization = true;

    // authorized addresses
    address[] private _authorizedAddresses;

    // authorization status: wallet address => bool
    mapping(address => bool) private _isAuthorized;

    // authorized account info
    mapping(address => AUTHORIZEDACCOUNTINFO) private _authorizedAccountsInfo;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(address AddressBookContractAddress_)
    {
        // require non-zero address
        require(
            AddressBookContractAddress_ != address(0),
            "Address should not be zero-address!"
        );

        // update Address Book Contract Address
        _AddressBookContractAddress = AddressBookContractAddress_;

        // update Address Book Contract Interface
        _AddressBook = AddressBookInterface(AddressBookContractAddress_);

        // emit event
        emit updateAddressBookContractAddressEvent(
            msg.sender,
            address(0),
            AddressBookContractAddress_,
            block.timestamp
        );
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update Address Book contract address
    event updateAddressBookContractAddressEvent(
        address indexed Admin,
        address previousAddressBookContractAddress,
        address indexed newAddressBookContractAddress,
        uint256 indexed timestamp
    );

    // update global authorization status
    event updateGlobalAuthorizationEvent(
        address indexed KYCManager,
        bool previousStatus,
        bool newStatus,
        uint256 indexed timestamp
    );

    // authorize an account
    event authorizeAddressEvent(
        address indexed KYCManager,
        address indexed account,
        uint256 indexed timestamp
    );

    // unauthorize an account
    event unAuthorizeAddressEvent(
        address indexed KYCManager,
        address indexed account,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    // only KYC Manager
    modifier onlyKYCManager() {
        // sender should be the KYC Mangager addresss
        _onlyKYCManager();
        _;
    }

    // not Null Address
    modifier onlyNotNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // not NUll Addresses
    modifier onlyNotNullAddresses(address[] memory accounts_) {
        // require all accounts be not zero address
        _notNullAddresses(accounts_);
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) public onlyAdmin onlyNotNullAddress(AddressBookContractAddress_) {
        // previous Address Book Contract Address
        address previousAddressBookContractAddress = _AddressBookContractAddress;

        // update Address Book Contract Address
        _AddressBookContractAddress = AddressBookContractAddress_;

        // update Address Book Contract Interface
        _AddressBook = AddressBookInterface(AddressBookContractAddress_);

        // emit event
        emit updateAddressBookContractAddressEvent(
            msg.sender,
            previousAddressBookContractAddress,
            AddressBookContractAddress_,
            block.timestamp
        );
    }

    // update global authorization
    function updateGlobalAuthorization(bool status_) public onlyKYCManager {
        // previous status
        bool previousStatus = _globalAuthorization;

        // update status
        _globalAuthorization = status_;

        // emit event
        emit updateGlobalAuthorizationEvent(
            msg.sender,
            previousStatus,
            status_,
            block.timestamp
        );
    }

    // add addresses to the authorized addresses
    function authorizeAddresses(address[] memory accounts_)
        public
        onlyKYCManager
        onlyNotNullAddresses(accounts_)
    {
        for (uint256 i = 0; i < accounts_.length; i++) {
            // add account to authorized addresses
            _addAccountToAuthorizedAddresses(accounts_[i]);

            // update authorized account info
            _authorizedAccountsInfo[accounts_[i]] = AUTHORIZEDACCOUNTINFO({
                KYCManager: msg.sender,
                account: accounts_[i],
                isAuthorized: true,
                authorizedTimestamp: block.timestamp,
                unauthorizeTimestamp: 0
            });

            // emit event
            emit authorizeAddressEvent(
                msg.sender,
                accounts_[i],
                block.timestamp
            );
        }
    }

    // remove address from mthe authorized addresses
    function unAuthorizeAddresses(address[] memory accounts_)
        public
        onlyKYCManager
        onlyNotNullAddresses(accounts_)
    {
        for (uint256 i = 0; i < accounts_.length; i++) {
            // remove account from authorized account
            _removeAccountFromAuthorizedAddresses(accounts_[i]);

            // update authorized account info
            _authorizedAccountsInfo[accounts_[i]].isAuthorized = false;
            _authorizedAccountsInfo[accounts_[i]].unauthorizeTimestamp = block
                .timestamp;

            // emit event
            emit unAuthorizeAddressEvent(
                msg.sender,
                accounts_[i],
                block.timestamp
            );
        }
    }

    /* GETTERS */

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    // get Address Book Contract Address
    function getAddressBookContractAddress() public view returns (address) {
        return _AddressBookContractAddress;
    }

    // get global authorization status
    function getGlobalAuthorizationStatus() public view returns (bool) {
        return _globalAuthorization;
    }

    // is authorized
    function isAuthorizedAddress(address account_)
        public
        view
        onlyNotNullAddress(account_)
        returns (bool)
    {
        // return true if either global authorization or account is authorized
        // return false if both global authorization and account authorization are false
        // global authorization (True ==> every addresses are authorized, False ==> only authorized addresses are permitted)
        return _globalAuthorization || _isAuthorized[account_];
    }

    // get authorized addresses
    function getAuthorizedAddresses() public view returns (address[] memory) {
        // return authorized addresses
        return _authorizedAddresses;
    }

    // get authorized account info
    function getAuthorizedAccountInfo(address account_)
        public
        view
        onlyNotNullAddress(account_)
        returns (AUTHORIZEDACCOUNTINFO memory)
    {
        // return info
        return _authorizedAccountsInfo[account_];
    }

    // get batch authorized accounts info
    function getBatchAuthorizedAccountInfo(address[] memory accounts_)
        public
        view
        onlyNotNullAddresses(accounts_)
        returns (AUTHORIZEDACCOUNTINFO[] memory)
    {
        AUTHORIZEDACCOUNTINFO[] memory infos = new AUTHORIZEDACCOUNTINFO[](
            accounts_.length
        );
        for (uint256 i = 0; i < accounts_.length; i++) {
            infos[i] = getAuthorizedAccountInfo(accounts_[i]);
        }
        return infos;
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    // add account to authorized addresses
    function _addAccountToAuthorizedAddresses(address account_) private {
        if (!_isAuthorized[account_]) {
            // add to the auhorized addresses
            _authorizedAddresses.push(account_);
            // udpate is authorized status
            _isAuthorized[account_] = true;
        }
    }

    // remove account from authorized addresses
    function _removeAccountFromAuthorizedAddresses(address account_) private {
        if (_isAuthorized[account_]) {
            for (uint256 i = 0; i < _authorizedAddresses.length; i++) {
                if (_authorizedAddresses[i] == account_) {
                    _authorizedAddresses[i] = _authorizedAddresses[
                        _authorizedAddresses.length - 1
                    ];
                    _authorizedAddresses.pop();
                    // update status
                    _isAuthorized[account_] = false;
                    break;
                }
            }
        }
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // only Admin Multi-Sig
    function _onlyAdmin() internal view {
        require(
            msg.sender == _AddressBook.getAdminMultiSigContractAddress(),
            "Sender is not the admin address!"
        );
    }

    // only KYC Manager
    function _onlyKYCManager() internal view {
        // sender should be the KYC Mangager addresss
        require(
            msg.sender == _AddressBook.getKYCMultiSigContractAddress(),
            "SegMint KYC: Sender is not the KYC Manager!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(
            account_ != address(0),
            "SegMint KYC: Address should not be zero address!"
        );
    }

    // not NUll Addresses
    function _notNullAddresses(address[] memory accounts_) internal pure {
        // require all accounts be not zero address
        for (uint256 i = 0; i < accounts_.length; i++) {
            require(
                accounts_[i] != address(0),
                "SegMint KYC: Address zero is not allowed."
            );
        }
    }
}