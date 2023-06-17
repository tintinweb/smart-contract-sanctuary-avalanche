/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // Signatory Proposal struct for managing signatories
    struct SignatoryProposal {
        uint256 ID;
        address PROPOSER;
        address MODIFIEDSIGNER;
        string UPDATETYPE; // ADD or REMOVE
        string SIGNATORYGROUP; // ADMIN, FEEMANAGEMENT, SUPPLYMANAGEMENT
        bool ISEXECUTED;
        uint256 EXPIRATION; // expiration timestamp
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // Min Signature Proposal to manage minimum signers
    struct MinSignatureProposal {
        uint256 ID;
        address PROPOSER;
        uint256 MINSIGNATURE;
        string SIGNATORYGROUP; // ADMIN, FEEMANAGEMENT, SUPPLYMANAGEMENT
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // Freeze Management Proposal struct
    struct FreezeManagementProposal {
        uint256 ID;
        address PROPOSER;
        string MANAGEMENTGROUP;
        bool STATUS;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

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

    // create update Address Book Proposal
    function createAddressBookProposal(
        address AddressBookContractAddress_,
        uint256 expiration_
    ) external;

    // approve update Address Book Proposal
    function approveAddressBookProposal(uint256 adminProposalIndex_) external;

    // revoke update Address Book Proposal
    function revokeAddressBookProposal(uint256 adminProposalIndex_) external;

    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // get signatories
    function getAdminSignatories() external view returns (address[] memory);

    // is admin signatory
    function IsAdminSignatory(address account_) external view returns (bool);

    // get admin proposal index
    function getAdminProposalIndex() external view returns (uint256);

    // get admin proposal detail
    function getAdminProposalDetail(uint256 adminProposalIndex_)
        external
        view
        returns (SignatoryProposal memory);

    // is admin proposal approver
    function IsAdminProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get min signature
    function getMinAdminSignatures() external view returns (uint256);

    // get min signature proposal detail
    function getMinSignatureProposalDetail(uint256 adminProposalIndex_)
        external
        view
        returns (MinSignatureProposal memory);

    // is min signature proposal approver?
    function IsMinSignatureProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get number of admin signatories
    function getNumberOfAdminSignatories() external view returns (uint256);

    // get Freeze Management proposal detail
    function getFreezeManagementProposalDetail(uint256 adminProposalIndex_)
        external
        view
        returns (FreezeManagementProposal memory);

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
    function getKYCSignatories() external view returns (address[] memory);

    // is KYC Signatory
    function IsKYCSignatory(address account_) external view returns (bool);

    // get KYC Min Signatures
    function getKYCMinSignatures() external view returns (uint256);
}

// Administrative Multi-Sig
contract AdminMultiSig is AdminMultiSigInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // Address Book Contract Address
    address private _AddressBookContractAddress;

    ///   Administration Signatories   ///

    // list of admin signatories
    address[] private _adminSignatories;

    // check if an address is a signatory: address => status
    mapping(address => bool) private _isAdminSignatory;

    // administration proposal counter
    uint256 private _adminProposalIndex = 0;

    // list of signatory proposals info: admin proposal index => signatory proposal detail
    mapping(uint256 => SignatoryProposal) private _signatoryProposals;

    // signatory proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _signatoryProposalApprovers;

    ///   Minimum Signatures   ///

    // minimum admin signatures required for a proposal
    uint256 private _minAdminSignatures;

    // list of min signature proposals info: admin proposal index => min signatures proposal detail
    mapping(uint256 => MinSignatureProposal) private _minSingatureProposal;

    // min signature propolsal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool)) private _minSignatureApprovers;

    ///   Freeze Managements  ///

    // list of freeze management proposal info: admin proposal index => freeze management proposal detail
    mapping(uint256 => FreezeManagementProposal)
        private _freezeManagementProposal;

    // freeze management proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _freezeManagementApprovers;

    // Global freeze Management Acitivities
    bool private _globalFreezeManagementActivities;

    // Freeze Supply Managemetn Activities
    bool private _freezeSupplyManagementActivities;

    // Freeze Fee Management Activitive
    bool private _freezeFeeManagementActivities;

    // Freeze Asset Protection Activities
    bool private _freezeAssetProtectionActivities;

    ///   Supply Management Signatories   ///

    // list of Supply Management Signatories
    address[] private _supplyManagementSignatories;

    // is a Supply Management Signatory
    mapping(address => bool) private _isSupplyManagementSignatory;

    // minimum Supply Management signature requirement
    uint256 private _minSupplyManagementSignatures;

    ///   Fee Management Signatories   ///

    // minimum Fee Management signature requirement
    uint256 private _minFeeManagementSignatures;

    // list of Fee Managment signatories
    address[] private _feeManagementSignatories;

    // is a Fee Management Signatory
    mapping(address => bool) private _isFeeManagementSignatory;

    ///   KYC Signatories   ///

    // list of KYC Signatories
    address[] private _KYCSignatories;

    // is a KYC Signatory
    mapping(address => bool) private _isKYCSignatory;

    // minimum KYC signature requirement
    uint256 private _minKYCSignatures;

    ///   Address Book Updating   ///

    // update address book proposal struct
    struct AddressBookProposal {
        uint256 ID;
        address PROPOSER;
        address NEWADDRESSBOOK;
        bool ISEXECUTED;
        uint256 EXPIRATION; // expiration timestamp
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of address book proposals info: admin proposal index => address book proposal detail
    mapping(uint256 => AddressBookProposal) private _AddressBookProposals;

    // address book proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool)) private _AddressBookApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor with initialized admin signatories and min admin signatures
    constructor(uint256 minAdminSignatures_, address[] memory adminSignatories_)
    {
        // require valid initialization
        require(
            minAdminSignatures_ <= adminSignatories_.length,
            "Admin Multi-Sig: Invalid initialization!"
        );

        // set min singatures
        _minAdminSignatures = minAdminSignatures_;

        // add signers
        for (uint256 i = 0; i < adminSignatories_.length; i++) {
            // admin signer
            address signatory = adminSignatories_[i];

            // require non-zero address
            require(
                signatory != address(0),
                "Admin Multi-Sig: Invalid admin signatory address!"
            );

            // require no duplicated signatory
            require(
                !_isAdminSignatory[signatory],
                "Admin Multi-Sig: Duplicate admin signatory address!"
            );

            // add admin signatory
            _adminSignatories.push(signatory);

            // update admin signatory status
            _isAdminSignatory[signatory] = true;

            // emit adding admin signatory event with index 0
            emit SingatoryProposalExecutedEvent(
                msg.sender,
                0,
                signatory,
                "ADD",
                "ADMIN",
                0,
                block.timestamp
            );
        }
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

    // create signatory proposal
    event SignatoryProposalCreatedEvent(
        address indexed proposer,
        uint256 adminProposalIndex,
        address indexed proposedAdminSignatory,
        string updateType,
        string signatoryGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute signatory proposal
    event SingatoryProposalExecutedEvent(
        address indexed executor,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string updateType,
        string signatoryGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve signatory proposal
    event ApproveSignatoryProposalEvent(
        address indexed approver,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string UPDATETYPE,
        string SIGNATORYGROUP,
        uint256 indexed timestamp
    );

    // revoke signatory proposal by proposer
    event revokeSignatoryProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string updateType,
        string signatoryGroup,
        uint256 indexed timestamp
    );

    // creatw min signature proposal
    event MinSignaturesProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        uint256 proposedMinSignatures,
        string signatoryGroup_,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute min signatures proposal
    event MinSignaturesProposalExecutedEvent(
        address indexed executor,
        uint256 indexed adminProposalIndex,
        uint256 previousMinAdminSignatures,
        uint256 newMinSignatures_,
        string signatoryGroup_,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve min signature proposal
    event ApproveMinSignaturesProposalEvent(
        address indexed approver,
        uint256 indexed adminProposalIndex,
        uint256 MINSIGNATURE,
        string SIGNATORYGROUP,
        uint256 indexed timestamp
    );

    // revoke min signatures proposal by proposer
    event revokeMinSignaturesProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        uint256 minSignature,
        string signatoryGroup,
        uint256 indexed timestamp
    );

    // create freeze management proposal
    event FreezeManagementProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string managementGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute freeze management proposal
    event FreezeManagementProposalExecutedEvent(
        address indexed executor,
        uint256 indexed adminProposalIndex,
        bool previousFreezeStatus,
        bool newFreezeStatus,
        string managementGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve freeze management proposal
    event ApproveFreezeManagementProposalEvent(
        address indexed approver,
        uint256 indexed adminProposalIndex,
        string MANAGEMENTGROUP,
        bool STATUS,
        uint256 indexed timestamp
    );

    // revoke freeze management proposal
    event revokeFreezeManagementProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string MANAGEMENTGROUP,
        bool STATUS,
        uint256 indexed timestamp
    );

    //  create address book proposal
    event AddressBookProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        address newAddressBookContractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // executing Address Book proposal
    event AddressBookProposalExecutedEvent(
        address indexed executor,
        uint256 indexed adminProposalIndex,
        address previousAddressBook,
        address newAddressBookContractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve updating address book proposal
    event ApproveAddressBookProposalEvent(
        address indexed approver,
        uint256 indexed adminProposalIndex,
        address NEWADDRESSBOOK,
        uint256 indexed timestamp
    );

    // revoke Address Book updating Proposal
    event revokeAddressBookProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        address NEWADDRESSBOOK,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Admin signatories
    modifier onlyAdmins() {
        // require msg.sender be an admin signatory
        _onlyAdmins();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only valid adminProposalIndex
    modifier onlyValidAdminProposalIndex(uint256 adminProposalIndex_) {
        // require a valid admin proposal index ( != 0 and not more than max)
        _onlyValidAdminProposalIndex(adminProposalIndex_);
        _;
    }

    // only valid signatory group
    modifier onlyValidGroup(string memory signatoryGroup_) {
        // require valid signatory group
        _onlyValidGroup(signatoryGroup_);
        _;
    }

    // only valid signatory update type
    modifier onlyValidUpdateType(string memory updateType_) {
        // require valid update type
        _onlyValidUpdateType(updateType_);
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        _onlyGreaterThanZero(value_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 adminProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(adminProposalIndex_);
        _;
    }

    // only valid management groups for freezing
    modifier onlyValidManagementGroups(string memory signatoryGroup_) {
        // require valid signatory group
        _onlyValidManagementGroups(signatoryGroup_);
        _;
    }

    // only Address Book
    modifier onlyAddressBook() {
        _onlyAddressBook();
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) public onlyAddressBook notNullAddress(AddressBookContractAddress_) {
        // previous Address Book Contract Address
        address previousAddressBookContractAddress = _AddressBookContractAddress;

        // update Address Book Contract Address
        _AddressBookContractAddress = AddressBookContractAddress_;

        // emit event
        emit updateAddressBookContractAddressEvent(
            msg.sender,
            previousAddressBookContractAddress,
            AddressBookContractAddress_,
            block.timestamp
        );
    }

    ///   Signatory Proposal   ///

    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory signatoryGroup_,
        string memory updateType_,
        uint256 expiration_
    )
        public
        onlyAdmins
        notNullAddress(signatoryAddress_)
        onlyValidGroup(signatoryGroup_)
        onlyValidUpdateType(updateType_)
        onlyGreaterThanZero(expiration_)
    {
        // check update type
        if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("ADD"))
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // require account not be an admin signatory
                require(
                    !_isAdminSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already an admin signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new admin signatory directly: no need to create proposal
                    // add to the admin signatories
                    _adminSignatories.push(signatoryAddress_);

                    // update admin signatory status
                    _isAdminSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit admin signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // require account not be an supply management signatory
                require(
                    !_isSupplyManagementSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already a Supply Management signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new supply management signatory directly: no need to create proposal
                    // add to the supply management signatories
                    _supplyManagementSignatories.push(signatoryAddress_);

                    // update supply management signatory status
                    _isSupplyManagementSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit admin signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // require account not be an fee management signatory
                require(
                    !_isFeeManagementSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already a Fee Management signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new Fee Management signatory directly: no need to create proposal
                    // add to the Fee Management signatories
                    _feeManagementSignatories.push(signatoryAddress_);

                    // update Fee Management signatory status
                    _isFeeManagementSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // require account not be an KYC signatory
                require(
                    !_isKYCSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already a KYC signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new KYC signatory directly: no need to create proposal
                    // add to the KYC signatories
                    _KYCSignatories.push(signatoryAddress_);

                    // update KYC signatory status
                    _isKYCSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            }
        } else if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // require address be an admin signatory
                // and min signature not less than new number of signatories
                // and after remove a signatory there should be at least one admin signatory left.
                require(
                    (_isAdminSignatory[signatoryAddress_] &&
                        _minAdminSignatures < _adminSignatories.length &&
                        _adminSignatories.length > 1),
                    "Admin Multi-Sig: Either not admin signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove admin signatory
                    _isAdminSignatory[signatoryAddress_] = false;

                    for (uint256 i = 0; i < _adminSignatories.length; i++) {
                        if (_adminSignatories[i] == signatoryAddress_) {
                            _adminSignatories[i] = _adminSignatories[
                                _adminSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _adminSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // require address be a Supply Management signatory
                // and min signature not less than new number of signatories
                require(
                    (_isSupplyManagementSignatory[signatoryAddress_] &&
                        _minSupplyManagementSignatures <
                        _supplyManagementSignatories.length),
                    "Admin Multi-Sig: Either not supply manager signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove Supply Management signatory
                    _isSupplyManagementSignatory[signatoryAddress_] = false;

                    for (
                        uint256 i = 0;
                        i < _supplyManagementSignatories.length;
                        i++
                    ) {
                        if (
                            _supplyManagementSignatories[i] == signatoryAddress_
                        ) {
                            _supplyManagementSignatories[
                                i
                            ] = _supplyManagementSignatories[
                                _supplyManagementSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _supplyManagementSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // require address be a Fee Management signatory
                // and min signature not less than new number of signatories
                require(
                    (_isFeeManagementSignatory[signatoryAddress_] &&
                        _minFeeManagementSignatures <
                        _feeManagementSignatories.length),
                    "Admin Multi-Sig: Either not fee manager signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove signatory
                    _isFeeManagementSignatory[signatoryAddress_] = false;

                    for (
                        uint256 i = 0;
                        i < _feeManagementSignatories.length;
                        i++
                    ) {
                        if (_feeManagementSignatories[i] == signatoryAddress_) {
                            _feeManagementSignatories[
                                i
                            ] = _feeManagementSignatories[
                                _feeManagementSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _feeManagementSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // require address be a KYC signatory
                // and min signature not less than new number of signatories
                require(
                    (_isKYCSignatory[signatoryAddress_] &&
                        _minKYCSignatures < _KYCSignatories.length),
                    "Admin Multi-Sig: Either not KYC signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(
                    msg.sender,
                    signatoryAddress_,
                    signatoryGroup_,
                    updateType_,
                    expiration_
                );

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove signatory
                    _isKYCSignatory[signatoryAddress_] = false;

                    for (uint256 i = 0; i < _KYCSignatories.length; i++) {
                        if (_KYCSignatories[i] == signatoryAddress_) {
                            _KYCSignatories[i] = _KYCSignatories[
                                _KYCSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _KYCSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            }
        }
    }

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                _signatoryProposalApprovers[adminProposalIndex_][msg.sender] ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // if Removing a signatory, require min signatures is not violated (minSignatures > signatories.length)
        if (
            keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // require not violating min signature
                require(
                    (_adminSignatories.length > _minAdminSignatures &&
                        _adminSignatories.length > 1),
                    "Admin Multi-Sig: Minimum admin signatories requirement not met!"
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // require not violating min signature
                require(
                    _supplyManagementSignatories.length >
                        _minSupplyManagementSignatures,
                    "Admin Multi-Sig: Minimum Supply Management signatories requirement not met!"
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // require not violating min signature
                require(
                    _feeManagementSignatories.length >
                        _minFeeManagementSignatures,
                    "Admin Multi-Sig: Minimum Fee Management signatories requirement not met!"
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // require not violating min signature
                require(
                    _KYCSignatories.length > _minKYCSignatures,
                    "Admin Multi-Sig: Minimum KYC signatories requirement not met!"
                );
            }
        }

        // update proposal approved by admin sender status
        _signatoryProposalApprovers[adminProposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        _signatoryProposals[_adminProposalIndex].APPROVALCOUNT++;

        // emit admin signatory proposal approved event
        emit ApproveSignatoryProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MODIFIEDSIGNER,
            proposal.UPDATETYPE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (proposal.APPROVALCOUNT >= _minAdminSignatures) {
            // add the new signatory
            _adminSignatories.push(proposal.MODIFIEDSIGNER);

            // update role
            _isAdminSignatory[proposal.MODIFIEDSIGNER] = true;

            // update is executed proposal
            proposal.ISEXECUTED = true;

            // update proposal EXECUTED TIMESTAMP
            proposal.EXECUTEDTIMESTAMP = block.timestamp;

            // emit executing signatory proposal
            emit SingatoryProposalExecutedEvent(
                msg.sender,
                adminProposalIndex_,
                proposal.MODIFIEDSIGNER,
                proposal.UPDATETYPE,
                proposal.SIGNATORYGROUP,
                proposal.EXPIRATION,
                block.timestamp
            );
        }
    }

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyProposer(adminProposalIndex_)
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired or revoked
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be executed, expired or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeSignatoryProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.UPDATETYPE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );
    }

    ///   Min Signatores Proposals   ///

    // create min singatures requirement proposal
    function createMinSignaturesProposal(
        uint256 minSignatures_,
        string memory signatoryGroup_,
        uint256 expiration_
    )
        public
        onlyAdmins
        onlyValidGroup(signatoryGroup_)
        onlyGreaterThanZero(expiration_)
    {
        // check signatory group
        if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("ADMIN"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _adminSignatories.length) &&
                    (minSignatures_ != _minAdminSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(
                msg.sender,
                minSignatures_,
                signatoryGroup_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous admin min signatures
                uint256 previousMinAdminSignatures = _minAdminSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update admin min signatures (execute the proposal)
                _minAdminSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinAdminSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _supplyManagementSignatories.length) &&
                    (minSignatures_ != _minSupplyManagementSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(
                msg.sender,
                minSignatures_,
                signatoryGroup_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous supply management min signatures
                uint256 previousMinSupplyManagementSignatures = _minSupplyManagementSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update admin min signatures (execute the proposal)
                _minSupplyManagementSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinSupplyManagementSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENT"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _feeManagementSignatories.length) &&
                    (minSignatures_ != _minFeeManagementSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(
                msg.sender,
                minSignatures_,
                signatoryGroup_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous Fee Management min signatures
                uint256 previousMinFeeManagementSignatures = _minFeeManagementSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update Fee Management min signatures (execute the proposal)
                _minFeeManagementSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinFeeManagementSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("KYC"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _KYCSignatories.length) &&
                    (minSignatures_ != _minKYCSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(
                msg.sender,
                minSignatures_,
                signatoryGroup_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous KYC min signatures
                uint256 previousMinKYCSignatures = _minKYCSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update KYC min signatures (execute the proposal)
                _minKYCSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinKYCSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve min signatures requirement proposal
    function approveMinSignaturesProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // min signatures proposal info
        MinSignatureProposal storage proposal = _minSingatureProposal[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED already, EXPIRED, REVOKED OR APPROVED BY SENDER
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED ||
                _minSignatureApprovers[adminProposalIndex_][msg.sender]),
            "Admin Multi-Sig: Proposal should not be approved, expired, revoked or approved by sender!"
        );

        // update proposal approved by admin sender status
        _minSignatureApprovers[adminProposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        proposal.APPROVALCOUNT++;

        // emit min signature proposal approved event
        emit ApproveMinSignaturesProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MINSIGNATURE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (proposal.APPROVALCOUNT >= _minAdminSignatures) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // previous admin min signatures
                uint256 previousMinAdminSignatures = _minAdminSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update admin min signatures
                _minAdminSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinAdminSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // previous Supply Management min signatures
                uint256 previousMinSupplyManagementSignatures = _minSupplyManagementSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update Supply Management min signatures
                _minSupplyManagementSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinSupplyManagementSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // previous Fee Management min signatures
                uint256 previousMinFeeManagementSignatures = _minFeeManagementSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update Fee Management min signatures
                _minFeeManagementSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinFeeManagementSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // previous KYC min signatures
                uint256 previousMinKYCSignatures = _minKYCSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update KYC min signatures
                _minKYCSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinKYCSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke min signatures requirement proposal (by Admin proposer)
    function revokeMinSignaturesProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyProposer(adminProposalIndex_)
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        MinSignatureProposal storage proposal = _minSingatureProposal[
            adminProposalIndex_
        ];

        // require proposal not been approved already, expired, or revoked
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be approved, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // UPDATED REVOKED TIMESTAMP
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeMinSignaturesProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MINSIGNATURE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );
    }

    ///   Freeze Management Proposals   ///

    // create freeze management proposal
    function createFreezeManagementProposal(
        string memory managementGroup_,
        bool updateStatus_,
        uint256 expiration_
    )
        public
        onlyAdmins
        onlyValidManagementGroups(managementGroup_)
        onlyGreaterThanZero(expiration_)
    {
        // check signatory group
        if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
        ) {
            // require update status be different from current status
            require(
                _freezeSupplyManagementActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // create freeze management proposal
            _createFreezeManagementProposal(
                msg.sender,
                managementGroup_,
                updateStatus_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _freezeSupplyManagementActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update supply management freeze status (execute the proposal)
                _freezeSupplyManagementActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENT"))
        ) {
            // require update status be different from current status
            require(
                _freezeFeeManagementActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // create freeze management proposal
            _createFreezeManagementProposal(
                msg.sender,
                managementGroup_,
                updateStatus_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _freezeFeeManagementActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update fee management freeze status (execute the proposal)
                _freezeFeeManagementActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("ASSETPROTECTION"))
        ) {
            // require update status be different from current status
            require(
                _freezeAssetProtectionActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // create freeze management proposal
            _createFreezeManagementProposal(
                msg.sender,
                managementGroup_,
                updateStatus_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _freezeAssetProtectionActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update asset protection freeze status (execute the proposal)
                _freezeAssetProtectionActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("GLOBAL"))
        ) {
            // require update status be different from current status
            require(
                _globalFreezeManagementActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // create freeze management proposal
            _createFreezeManagementProposal(
                msg.sender,
                managementGroup_,
                updateStatus_,
                expiration_
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _globalFreezeManagementActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update global freeze status (execute the proposal)
                _globalFreezeManagementActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve freeze management proposal
    function approveFreezeManagementProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // freeze management proposal info
        FreezeManagementProposal storage proposal = _freezeManagementProposal[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked, or apprved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED ||
                _freezeManagementApprovers[adminProposalIndex_][msg.sender]),
            "Admin Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // update proposal approved by admin sender status
        _freezeManagementApprovers[adminProposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        proposal.APPROVALCOUNT++;

        // emit approve freeze management proposal event
        emit ApproveFreezeManagementProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MANAGEMENTGROUP,
            proposal.STATUS,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (proposal.APPROVALCOUNT >= _minAdminSignatures) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("GLOBAL"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _globalFreezeManagementActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update global freeze status (execute the proposal)
                _globalFreezeManagementActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _freezeSupplyManagementActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update supply management freeze status (execute the proposal)
                _freezeSupplyManagementActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _freezeFeeManagementActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update fee management freeze status (execute the proposal)
                _freezeFeeManagementActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("ASSETPROTECTION"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _freezeAssetProtectionActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update asset protection freeze status (execute the proposal)
                _freezeAssetProtectionActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke freeze management proposal
    function revokeFreezeManagementProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyProposer(adminProposalIndex_)
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        FreezeManagementProposal storage proposal = _freezeManagementProposal[
            adminProposalIndex_
        ];

        // require proposal not been executed already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeFreezeManagementProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MANAGEMENTGROUP,
            proposal.STATUS,
            block.timestamp
        );
    }

    ///   Address Book Proposals   ///

    // create update Address Book Proposal
    function createAddressBookProposal(
        address AddressBookContractAddress_,
        uint256 expiration_
    )
        public
        onlyAdmins
        notNullAddress(AddressBookContractAddress_)
        onlyGreaterThanZero(expiration_)
    {
        // require different address book contract address
        require(
            _AddressBookContractAddress != AddressBookContractAddress_,
            "Admin Multi-Sig: Proposed Address Book is in use!"
        );

        // increment administration proposal ID
        ++_adminProposalIndex;

        // add proposal
        _AddressBookProposals[_adminProposalIndex] = AddressBookProposal({
            ID: _adminProposalIndex,
            PROPOSER: msg.sender,
            NEWADDRESSBOOK: AddressBookContractAddress_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the proposal by admin sender
        _AddressBookApprovers[_adminProposalIndex][msg.sender] = true;

        // emit update address book proposal event
        emit AddressBookProposalCreatedEvent(
            msg.sender,
            _adminProposalIndex,
            AddressBookContractAddress_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if sender is the only Admin signatory
        if (_adminSignatories.length == 1) {
            // previous Address Book
            address previousAddressBook = _AddressBookContractAddress;

            // update is EXECUTED
            _AddressBookProposals[_adminProposalIndex].ISEXECUTED = true;

            // UPDATE EXECUTED TIMESTAMP
            _AddressBookProposals[_adminProposalIndex].EXECUTEDTIMESTAMP = block
                .timestamp;

            //  update supply management freeze status (execute the proposal)
            _AddressBookContractAddress = AddressBookContractAddress_;

            // emit executing Address Book proposal
            emit AddressBookProposalExecutedEvent(
                msg.sender,
                _adminProposalIndex,
                previousAddressBook,
                AddressBookContractAddress_,
                expiration_,
                block.timestamp
            );
        }
    }

    // approve update Address Book Proposal
    function approveAddressBookProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // address book proposal info
        AddressBookProposal storage proposal = _AddressBookProposals[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked, or apprved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED ||
                _AddressBookApprovers[adminProposalIndex_][msg.sender]),
            "Admin Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // update proposal approved by admin sender status
        _AddressBookApprovers[adminProposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        proposal.APPROVALCOUNT++;

        // emit approve address book proposal event
        emit ApproveAddressBookProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.NEWADDRESSBOOK,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (proposal.APPROVALCOUNT >= _minAdminSignatures) {
            // previous Address Book
            address previousAddressBook = _AddressBookContractAddress;

            // update is EXECUTED
            _AddressBookProposals[_adminProposalIndex].ISEXECUTED = true;

            // UPDATE EXECUTED TIMESTAMP
            _AddressBookProposals[_adminProposalIndex].EXECUTEDTIMESTAMP = block
                .timestamp;

            //  update supply management freeze status (execute the proposal)
            _AddressBookContractAddress = proposal.NEWADDRESSBOOK;

            // emit executing Address Book proposal
            emit AddressBookProposalExecutedEvent(
                msg.sender,
                _adminProposalIndex,
                previousAddressBook,
                proposal.NEWADDRESSBOOK,
                proposal.EXPIRATION,
                block.timestamp
            );
        }
    }

    // revoke update Address Book Proposal
    function revokeAddressBookProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyProposer(adminProposalIndex_)
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        AddressBookProposal storage proposal = _AddressBookProposals[
            adminProposalIndex_
        ];

        // require proposal not been executed already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeAddressBookProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.NEWADDRESSBOOK,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get Address Book Contract Address
    function getAddressBookContractAddress() public view returns (address) {
        return _AddressBookContractAddress;
    }

    // get admin signatories
    function getAdminSignatories() public view returns (address[] memory) {
        return _adminSignatories;
    }

    // is admin signatory
    function IsAdminSignatory(address account_) public view returns (bool) {
        return _isAdminSignatory[account_];
    }

    // get admin proposal index
    function getAdminProposalIndex() public view returns (uint256) {
        return _adminProposalIndex;
    }

    // get admin proposal detail
    function getAdminProposalDetail(uint256 adminProposalIndex_)
        public
        view
        returns (SignatoryProposal memory)
    {
        return _signatoryProposals[adminProposalIndex_];
    }

    // is admin proposal approver
    function IsAdminProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) public view returns (bool) {
        return _signatoryProposalApprovers[adminProposalIndex_][account_];
    }

    // get number of admin signatories
    function getNumberOfAdminSignatories() public view returns (uint256) {
        return _adminSignatories.length;
    }

    // get min signature
    function getMinAdminSignatures() public view returns (uint256) {
        return _minAdminSignatures;
    }

    // get min signature proposal detail
    function getMinSignatureProposalDetail(uint256 adminProposalIndex_)
        public
        view
        returns (MinSignatureProposal memory)
    {
        return _minSingatureProposal[adminProposalIndex_];
    }

    // is min signature proposal approver?
    function IsMinSignatureProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) public view returns (bool) {
        return _minSignatureApprovers[adminProposalIndex_][account_];
    }

    // get Freeze Management proposal detail
    function getFreezeManagementProposalDetail(uint256 adminProposalIndex_)
        public
        view
        returns (FreezeManagementProposal memory)
    {
        return _freezeManagementProposal[adminProposalIndex_];
    }

    // is freeze management proposal approver?
    function IsFreezeManagementProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) public view returns (bool) {
        return _freezeManagementApprovers[adminProposalIndex_][account_];
    }

    // get global freeze management status
    function getGlobalFreezeManagementStatus() public view returns (bool) {
        return _globalFreezeManagementActivities;
    }

    // get Supply Management Freeze status
    function getSupplyManagementFreezeStatus() public view returns (bool) {
        return _freezeSupplyManagementActivities;
    }

    // get Fee Management Freeze status
    function getFeeManagementFreezeStatus() public view returns (bool) {
        return _freezeFeeManagementActivities;
    }

    // get Asset Protection Freeze status
    function getAssetProtectionFreezeStatus() public view returns (bool) {
        return _freezeAssetProtectionActivities;
    }

    // get Supply Management Signatories
    function getSupplyManagementSignatories()
        public
        view
        returns (address[] memory)
    {
        return _supplyManagementSignatories;
    }

    // Is Supply Management Signatory
    function IsSupplyManagementSignatory(address account_)
        public
        view
        returns (bool)
    {
        return _isSupplyManagementSignatory[account_];
    }

    // get Min Signature requirement for Supply Management
    function getSupplyManagementMinSignatures() public view returns (uint256) {
        return _minSupplyManagementSignatures;
    }

    // get Fee Management Signatories
    function getFeeManagementSignatories()
        public
        view
        returns (address[] memory)
    {
        return _feeManagementSignatories;
    }

    // is Fee Managemetn Signatory
    function IsFeeManagementSignatory(address account_)
        public
        view
        returns (bool)
    {
        return _isFeeManagementSignatory[account_];
    }

    // get Fee Management Min Singatures
    function getFeeManagementMinSignatures() public view returns (uint256) {
        return _minFeeManagementSignatures;
    }

    // get KYC Signatories
    function getKYCSignatories() public view returns (address[] memory) {
        return _KYCSignatories;
    }

    // is KYC Signatory
    function IsKYCSignatory(address account_) public view returns (bool) {
        return _isKYCSignatory[account_];
    }

    // get KYC Min Signatures
    function getKYCMinSignatures() public view returns (uint256) {
        return _minKYCSignatures;
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // only admin
    function _onlyAdmins() internal view virtual {
        require(
            _isAdminSignatory[msg.sender],
            "Admin Multi-Sig: Sender is not an admin signatory!"
        );
    }

    // not null address
    function _notNullAddress(address account_) internal view virtual {
        require(
            account_ != address(0),
            "Admin Multi-Sig: Address should not be zero address!"
        );
    }

    // only valid admin proposal index
    function _onlyValidAdminProposalIndex(uint256 adminProposalIndex_)
        internal
        view
        virtual
    {
        // require a valid admin proposal index ( != 0 and not more than max)
        require(
            (adminProposalIndex_ != 0 &&
                adminProposalIndex_ <= _adminProposalIndex),
            "Admin Multi-Sig: Invalid admin proposal index!"
        );
    }

    // only valid signatory group
    function _onlyValidGroup(string memory signatoryGroup_)
        internal
        view
        virtual
    {
        // require valid signatory group
        require(
            keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ADMIN")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("KYC")),
            "Admin Multi-Sig: Signatory group is not valid!"
        );
    }

    // only valid contracts
    function _onlyValidContract(string memory contract_) internal pure {
        // require valid signatory group
        require(
            keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("ERC20")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("ADDRESSBOOK")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("ADMINMULTISIG")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENTMULTISIG")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENTMULTISIG")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("ASSETPROTECTIONMULTISIG")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("KYC")) ||
                keccak256(abi.encodePacked(contract_)) ==
                keccak256(abi.encodePacked("KYCMULTISIG")),
            "Admin Multi-Sig: Invalid target contract!"
        );
    }

    // only valid signatory update type
    function _onlyValidUpdateType(string memory updateType_)
        internal
        view
        virtual
    {
        // require valid update type
        require(
            keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("ADD")) ||
                keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("REMOVE")),
            "Admin Multi-Sig: Update type is not valid!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal view virtual {
        // require value be greater than zero
        require(
            value_ > 0,
            "Admin Multi-Sig: Value should be greater than zero!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 adminProposalIndex_) internal view virtual {
        // require sender be the proposer of the proposal
        require(
            msg.sender == _signatoryProposals[adminProposalIndex_].PROPOSER,
            "Admin Multi-Sig: Sender is not the proposer!"
        );
    }

    // only valid management groups for freezing
    function _onlyValidManagementGroups(string memory signatoryGroup_)
        internal
        view
        virtual
    {
        // require valid signatory group
        require(
            keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("GLOBAL")),
            "Admin Multi-Sig: Signatory group is not valid!"
        );
    }

    // create signatory proposal
    function _createSignatoryPropolsa(
        address sender,
        address signatoryAddress_,
        string memory updateType_,
        string memory signatoryGroup_,
        uint256 expiration_
    ) internal {
        // increment administration proposal ID
        ++_adminProposalIndex;

        // add the admin proposal
        _signatoryProposals[_adminProposalIndex] = SignatoryProposal({
            ID: _adminProposalIndex,
            PROPOSER: sender,
            MODIFIEDSIGNER: signatoryAddress_,
            UPDATETYPE: updateType_,
            SIGNATORYGROUP: signatoryGroup_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve proposal by admin sender
        _signatoryProposalApprovers[_adminProposalIndex][sender] = true;

        // emit add admin signatory proposal event
        emit SignatoryProposalCreatedEvent(
            sender,
            _adminProposalIndex,
            signatoryAddress_,
            updateType_,
            signatoryGroup_,
            expiration_,
            block.timestamp
        );
    }

    // create min signature proposal
    function _createMinSignatureProposal(
        address sender,
        uint256 minSignatures_,
        string memory signatoryGroup_,
        uint256 expiration_
    ) internal {
        // increment administration proposal ID
        ++_adminProposalIndex;

        // add proposal
        _minSingatureProposal[_adminProposalIndex] = MinSignatureProposal({
            ID: _adminProposalIndex,
            PROPOSER: sender,
            MINSIGNATURE: minSignatures_,
            SIGNATORYGROUP: signatoryGroup_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the proposal by admin sender
        _minSignatureApprovers[_adminProposalIndex][sender] = true;

        // emit creating min signature proposal event
        emit MinSignaturesProposalCreatedEvent(
            sender,
            _adminProposalIndex,
            minSignatures_,
            signatoryGroup_,
            expiration_,
            block.timestamp
        );
    }

    // create freeze management proposal
    function _createFreezeManagementProposal(
        address sender,
        string memory managementGroup_,
        bool updateStatus_,
        uint256 expiration_
    ) internal {
        // increment administration proposal ID
        ++_adminProposalIndex;

        // add proposal
        _freezeManagementProposal[
            _adminProposalIndex
        ] = FreezeManagementProposal({
            ID: _adminProposalIndex,
            PROPOSER: sender,
            MANAGEMENTGROUP: managementGroup_,
            STATUS: updateStatus_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the proposal by admin sender
        _freezeManagementApprovers[_adminProposalIndex][sender] = true;

        // emit freeze management proposal event
        emit FreezeManagementProposalCreatedEvent(
            sender,
            _adminProposalIndex,
            managementGroup_,
            expiration_,
            block.timestamp
        );
    }

    // only Address Book
    function _onlyAddressBook() internal view {
        // require sender be Address Book ( || == address(0) for initializing)
        require(
            msg.sender == _AddressBookContractAddress || _AddressBookContractAddress == address(0),
            "Admin Multi-Sig: Sender is not Address Book!"
        );
    }
}