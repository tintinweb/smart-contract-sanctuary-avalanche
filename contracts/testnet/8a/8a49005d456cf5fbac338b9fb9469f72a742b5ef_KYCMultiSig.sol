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
    function updateKYCContractAddress(address KYCContractAddress_, address executor_) external;

    // get KYC Contract Address
    function getKYCContractAddress() external view returns (address);

    // update KYC Multi-Sig Contract Address
    function updateKYCMultiSigContractAddress(address KYCMultiSigContractAddress_, address executor_) external;

    // get KYC Multi-Sig Contract Address
    function getKYCMultiSigContractAddress() external view returns(address);
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory signatoryGroup_,
        string memory updateType_,
        uint256 expiration_
    ) external;

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 adminProposalIndex_) external;

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 adminProposalIndex_) external;

    // create min singatures requirement proposal
    function createMinSignaturesProposal(
        uint256 minSignatures_,
        string memory signatoryGroup_,
        uint256 expiration_
    ) external;

    // approve min signatures requirement proposal
    function approveMinSignaturesProposal(uint256 adminProposalIndex_) external;

    // revoke min signatures requirement proposal (by Admin proposer)
    function revokeMinSignaturesProposal(uint256 adminProposalIndex_) external;

    // create freeze management proposal
    function createFreezeManagementProposal(
        string memory managementGroup_,
        bool updateStatus_,
        uint256 expiration_
    ) external;

    // approve freeze management proposal
    function approveFreezeManagementProposal(uint256 adminProposalIndex_)
        external;

    // revoke freeze management proposal
    function revokeFreezeManagementProposal(uint256 adminProposalIndex_)
        external;

    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // get signatories
    function getAdminSignatories() external view returns (address[] memory);

    // is admin signatory
    function IsAdminSignatory(address account_) external view returns (bool);

    // get admin proposal index
    function getAdminProposalIndex() external view returns (uint256);

    // get admin proposal detail
    // function getAdminProposalDetail(uint256 adminProposalIndex_)
    //     external
    //     view
    //     returns (SignatoryProposal memory);

    // is admin proposal approver
    function IsAdminProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get min signature
    function getMinAdminSignatures() external view returns (uint256);

    // get min signature proposal detail
    // function getMinSignatureProposalDetail(uint256 adminProposalIndex_)
    //     public
    //     view
    //     returns (MinSignatureProposal memory);

    // is min signature proposal approver?
    function IsMinSignatureProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get number of admin signatories
    function getNumberOfAdminSignatories() external view returns (uint256);

    // get Freeze Management proposal detail
    // function getFreezeManagementProposalDetail(uint256 adminProposalIndex_)
    //     public
    //     view
    //     returns (FreezeManagementProposal memory);

    // is freeze management proposal approver?
    function IsFreezeManagementProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get global freeze management status
    function getGlobalFreezeManagementStatus() external view returns (bool);

    // get Supply Management Freeze status
    function getSupplyManagementFreezeStatus() external view returns (bool);

    // get Fee Management Freeze status
    function getFeeManagementFreezeStatus() external view returns (bool);

    // get Asset Protection Freeze status
    function getAssetProtectionFreezeStatus() external view returns (bool);

    // get Supply Management Signatories
    function getSupplyManagementSignatories()
        external
        view
        returns (address[] memory);

    // Is Supply Management Signatory
    function IsSupplyManagementSignatory(address account_)
        external
        view
        returns (bool);

    // get Min Signature requirement for Supply Management
    function getSupplyManagementMinSignatures() external view returns (uint256);

    // get Fee Management Signatories
    function getFeeManagementSignatories()
        external
        view
        returns (address[] memory);

    // is Fee Managemetn Signatory
    function IsFeeManagementSignatory(address account_)
        external
        view
        returns (bool);

    // get Fee Management Min Singatures
    function getFeeManagementMinSignatures() external view returns (uint256);

    // get kYC Signatories
    function getKYCSignatories()
        external
        view
        returns (address[] memory);

    // is KYC Signatory
    function IsKYCSignatory(address account_)
        external 
        view
        returns (bool);

    // get KYC Min Signatures
    function getKYCMinSignatures() external view returns (uint256);

    // get Asset Protection Signatories
    function getAssetProtectionSignatories()
        external
        view
        returns (address[] memory);

    // Is Asset Protection Signatory
    function IsAssetProtectionSignatory(address account_)
        external
        view
        returns (bool);

    // get Asset Protection Min Signature requirement
    function getAssetProtectionMinSignatures() external view returns (uint256);
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

// KYC Multi-Sig
contract KYCMultiSig is KYCMultiSigInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // KYC Contract Address
    address private _KYCContractAddress;

    // KYC Interface
    KYCInterface private _KYC;

    // Admin Multi-Sig Contract Address
    address private _AdminMultiSigContractAddress;

    // Admin Multi-Sig Contract Interface
    AdminMultiSigInterface private _AdminMultiSig;

    // KYC proposal counter
    uint256 private _ProposalIndex = 0;

    // list of KYC proposals info: proposal index => proposal detail
    mapping(uint256 => KYCProposal) private _KYCProposals;

    // kyc manager proposal approvers: proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _KYCProposalApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(
        address KYCContractAddress_,
        address AdminMultiSigContractAddress_
    )
        notNullAddress(KYCContractAddress_)
        notNullAddress(AdminMultiSigContractAddress_)
    {
        
        // require account not be the zero address
        require(
            KYCContractAddress_ != address(0),
            "KYC Multi-Sig: KYC Contract Address should not be zero address!"
        );

        // update KYC Contract Address
        _KYCContractAddress = KYCContractAddress_;

        // update KYC Contract Interface
        _KYC = KYCInterface(KYCContractAddress_);

        // emit event
        emit updateKYCContractAddressEvent(
            msg.sender,
            address(0),
            KYCContractAddress_,
            block.timestamp
        );

        // require account not be the zero address
        require(
            AdminMultiSigContractAddress_ != address(0),
            "KYC Multi-Sig: Admin Multi-Sig Address should not be zero address!"
        );

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // update Admin Multi-Sig Contract Interface
        _AdminMultiSig = AdminMultiSigInterface(AdminMultiSigContractAddress_);

        // emit event
        emit updateAdminMultiSigContractAddressEvent(
            msg.sender,
            address(0),
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update KYC Contract Address
    event updateKYCContractAddressEvent(
        address indexed AdminMultiSig,
        address previousKYCContractAddress,
        address newKYCContractAddress,
        uint256 indexed timestamp
    );

    // update Admin Multi-Sig Contract Address (only Admin)
    event updateAdminMultiSigContractAddressEvent(
        address indexed AdminMultiSig,
        address previousAdminMultiSigContractAddress,
        address indexed newAdminMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // create  proposal
    event ProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed ProposalIndex,
        string Category,
        address[] accounts,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute proposal
    event ProposalExecutedEvent(
        address indexed executor,
        uint256 indexed ProposalIndex,
        string Category,
        address[] accounts,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // proposal approved
    event ApproveProposalEvent(
        address indexed approver,
        uint256 indexed ProposalIndex,
        string Category,
        address[] accounts,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // revoke proposal
    event revokeProposalEvent(
        address indexed proposer,
        uint256 indexed ProposalIndex,
        string Category,
        address[] accounts,
        uint256 expiration,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only KYC signatories
    modifier onlyKYCManagers() {
        // require sender be a KYC manager
        _onlyKYCManagers();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // not NUll Addresses
    modifier notNullAddresses(address[] memory accounts_) {
        // require all accounts be not zero address
        _notNullAddresses(accounts_);
        _;
    }

    // only valid Category (Authorize, Unauthorize)
    modifier onlyValidCategory(string memory Category_) {
        // require valid category
        _onlyValidCategory(Category_);
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        _onlyGreaterThanZero(value_);
        _;
    }

    // only Valid Proposal Index
    modifier onlyValidProposalIndex(uint256 ProposalIndex_) {
        // require valid index
        _onlyValidProposalIndex(ProposalIndex_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 ProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(ProposalIndex_);
        _;
    }

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        // require sender be admin multisig contract address
        _onlyAdmin();
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update KYC Contract Address
    function updateKYCContractAddress(address KYCContractAddress_)
        public
        notNullAddress(KYCContractAddress_)
        onlyAdmin
    {
        // previous KYC Contract Address
        address previousKYCContractAddress = _KYCContractAddress;

        // update KYC Contract Address
        _KYCContractAddress = KYCContractAddress_;

        // update KYC Contract Interface
        _KYC = KYCInterface(KYCContractAddress_);

        // emit event
        emit updateKYCContractAddressEvent(
            msg.sender,
            previousKYCContractAddress,
            KYCContractAddress_,
            block.timestamp
        );
    }

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) public notNullAddress(AdminMultiSigContractAddress_) onlyAdmin {
        // previous Admin Multi-Sig Contract Address
        address previousAdminMultiSigContractAddress = _AdminMultiSigContractAddress;

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // update Admin Multi-Sig Contract Interface
        _AdminMultiSig = AdminMultiSigInterface(AdminMultiSigContractAddress_);

        // emit event
        emit updateAdminMultiSigContractAddressEvent(
            msg.sender,
            previousAdminMultiSigContractAddress,
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    // create proposal
    function createProposal(
        string memory Category_,
        address[] memory accounts_,
        uint256 expiration_
    )
        public
        onlyKYCManagers
        onlyValidCategory(Category_)
        notNullAddresses(accounts_)
        onlyGreaterThanZero(expiration_)
    {
        // increment proposal index
        ++_ProposalIndex;

        // create proposal
        _KYCProposals[
            _ProposalIndex
        ] = KYCProposal({
            ID: _ProposalIndex,
            PROPOSER: msg.sender,
            CATEGORY: Category_,
            ACCOUNTS: accounts_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the porposal by KYC manager sender
        _KYCProposalApprovers[_ProposalIndex][
            msg.sender
        ] = true;

        // emit creating KYC manager proposal event
        emit ProposalCreatedEvent(
            msg.sender,
            _ProposalIndex,
            Category_,
            accounts_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if sender is the only KYC manager
        address[] memory _Signatories = _AdminMultiSig
            .getKYCSignatories();

        if (_Signatories.length == 1) {
            // category
            if (
                keccak256(abi.encodePacked(Category_)) ==
                keccak256(abi.encodePacked("AUTHORIZE"))
            ) {
                // execute authorize
                _KYC.authorizeAddresses(accounts_);

                // update IS EXECUTED
                _KYCProposals[_ProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _KYCProposals[_ProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing proposal
                emit ProposalExecutedEvent(
                    msg.sender,
                    _ProposalIndex,
                    Category_,
                    accounts_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(Category_)) ==
                keccak256(abi.encodePacked("UNAUTHORIZE"))
            ) {
                // execute unauthorize
                _KYC.unAuthorizeAddresses(accounts_);

                // update IS EXECUTED
                _KYCProposals[_ProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _KYCProposals[_ProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing proposal
                emit ProposalExecutedEvent(
                    msg.sender,
                    _ProposalIndex,
                    Category_,
                    accounts_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve proposal
    function approveProposal(uint256 ProposalIndex_)
        public
        onlyKYCManagers
        onlyValidProposalIndex(ProposalIndex_)
    {
        // whitelist manager proposal info
        KYCProposal storage proposal = _KYCProposals[
            ProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION > block.timestamp ||
                _KYCProposalApprovers[ProposalIndex_][
                    msg.sender
                ]),
            "KYC Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by kyc manager sender
        _KYCProposalApprovers[ProposalIndex_][
            msg.sender
        ] = true;

        // update proposal approval count
        proposal.APPROVALCOUNT++;

        // emit KYC Manager proposal approved event
        emit ApproveProposalEvent(
            msg.sender,
            ProposalIndex_,
            proposal.CATEGORY,
            proposal.ACCOUNTS,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (
            _KYCProposals[ProposalIndex_]
                .APPROVALCOUNT >= _AdminMultiSig.getKYCMinSignatures()
        ) {
            // sender execute the proposal
            // category
            if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("AUTHORIZE"))
            ) {
                // execute update creation fee order
                _KYC.authorizeAddresses(proposal.ACCOUNTS);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing proposal
                emit ProposalExecutedEvent(
                    msg.sender,
                    ProposalIndex_,
                    proposal.CATEGORY,
                    proposal.ACCOUNTS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("UNAUTHORIZE"))
            ) {
                // execute update redemption fee order
                _KYC.unAuthorizeAddresses(proposal.ACCOUNTS);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing proposal
                emit ProposalExecutedEvent(
                    msg.sender,
                    ProposalIndex_,
                    proposal.CATEGORY,
                    proposal.ACCOUNTS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke proposal
    function revokeProposal(uint256 ProposalIndex_)
        public
        onlyKYCManagers
        onlyProposer(ProposalIndex_)
    {
        // proposal info
        KYCProposal storage proposal = _KYCProposals[
            ProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "KYC Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeProposalEvent(
            msg.sender,
            ProposalIndex_,
            proposal.CATEGORY,
            proposal.ACCOUNTS,
            proposal.EXPIRATION,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get admin multi sig contract address
    function getAdminMultiSigContractAddress() external view returns (address) {
        return _AdminMultiSigContractAddress;
    }

    // get max proposal index
    function getMaxProposalIndex() external view returns (uint256) {
        return _ProposalIndex;
    }

    // get KYC Proposal Detail
    function getKYCProposalDetail(uint256 ProposalIndex_)
        external
        view
        returns (KYCProposal memory)
    {
        return _KYCProposals[ProposalIndex_];
    }

    // is KYC Manger proposal approver
    function IsKYCMangerProposalApprover(
        uint256 ProposalIndex_,
        address account_
    ) external view returns (bool) {
        return
            _KYCProposalApprovers[ProposalIndex_][account_];
    }

    // get proposal detail
    function getProposalDetail(
        uint256 ProposalIndex_
    ) external view returns (KYCProposal memory) {
        return _KYCProposals[ProposalIndex_];
    }

    // is  proposal approvers
    function IsProposalApprovers(
        uint256 ProposalIndex_,
        address account_
    ) external view returns (bool) {
        return
            _KYCProposalApprovers[ProposalIndex_][account_];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // only KYC signatories
    function _onlyKYCManagers() internal view {
        // require sender be a KYC manager
        require(
            _AdminMultiSig.IsKYCSignatory(msg.sender),
            "KYC Multi-Sig: Sender is not a KYC Manager Signatory!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Admin Multi-Sig: Address should not be zero address!"
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

    // only valid Category (Authorize, Unauthorize)
    function _onlyValidCategory(string memory Category_) internal pure {
        // require valid category
        require(
            keccak256(abi.encodePacked(Category_)) ==
                keccak256(abi.encodePacked("AUTHORIZE")) ||
                keccak256(abi.encodePacked(Category_)) ==
                keccak256(abi.encodePacked("UNAUTHORIZE")),
            "KYC Multi-Sig: Invalid Category!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal pure {
        // require value be greater than zero
        require(
            value_ > 0,
            "Admin Multi-Sig: Value should be greater than zero!"
        );
    }

    // only Valid Proposal Index
    function _onlyValidProposalIndex(uint256 ProposalIndex_) internal view {
        // require valid index
        require(
            ((ProposalIndex_ != 0) &&
                (ProposalIndex_ <= _ProposalIndex)),
            "KYC Multi-Sig: Invalid proposal index!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 ProposalIndex_) internal view {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _KYCProposals[ProposalIndex_].PROPOSER,
            "KYC Multi-Sig: Sender is not the proposer!"
        );
    }

    // only Admin Multi-Sig
    function _onlyAdmin() internal view {
        // require sender be admin multisig contract address
        require(
            msg.sender == _AdminMultiSigContractAddress,
            "Sender is not admin!"
        );
    }
}