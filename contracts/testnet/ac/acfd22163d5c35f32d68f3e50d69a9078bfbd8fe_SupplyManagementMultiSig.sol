/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ERC20 Interface
interface ERC20Interface {
    ////    Standard ERC20    ////

    // transfer
    function transfer(address to_, uint256 amount_) external returns (bool);

    // allowance
    function allowance(address owner_, address spender_)
        external
        view
        returns (uint256);

    // approve
    function approve(address spender_, uint256 amount_) external returns (bool);

    // transferFrom
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external returns (bool);

    // increaseAllowance
    function increaseAllowance(address spender_, uint256 addedValue_)
        external
        returns (bool);

    // decreaseAllowance
    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        external
        returns (bool);

    // name
    function name() external view returns (string memory);

    // symbol
    function symbol() external view returns (string memory);

    // decimals
    function decimals() external view returns (uint8);

    // totalSupply
    function totalSupply() external view returns (uint256);

    // balanceOf
    function balanceOf(address account_) external returns (uint256);

    //// Commodity Token Public Functions   ////

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // update Fee Management Contract Address
    function updateFeeManagementContractAddress(
        address FeeManagementContractAddress_
    ) external;

    // freeze all transactions
    function freezeAllTransactions() external;

    // un-freeze all transactions
    function unFreezeAllTransactions() external;

    // freeze an account
    function freezeAccount(address account_) external;

    // un-freeze and account
    function unFreezeAccount(address account_) external;

    // wipe freezed account
    function wipeFreezedAccount(address account_) external;

    // wipe specific amount freezed account
    function wipeSpecificAmountFreezedAccount(address account_, uint256 amount_)
        external;

    // freeze and wipe an account
    function freezeAndWipeAccount(address account_) external;

    // freeze and wipe specific amount from an account
    function freezeAndWipeSpecificAmountAccount(
        address account_,
        uint256 amount_
    ) external;

    // creation basket
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    ) external returns (bool);

    // authorize Supply Management Multi-Sig for redemption
    function authorizeRedemption(uint256 amount_) external;

    // revoke authorized redemption
    function revokeAuthorizedRedemption(uint256 amount_) external;

    // redemption basket
    function redemptionBasket(uint256 amount_, address senderAddress_)
        external
        returns (bool);

    // withdraw tokens from contract to Treasurer account
    function withdrawContractTokens() external;

    ////   Getters    ////

    // get Address Book
    function getAddressBook() external view returns (address);

    // get Admin Multi-Sign
    function getAdmin() external view returns (address);

    // get Asset Protection
    function getAssetProtection() external view returns (address);

    // get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);

    // get Fee Management Multi-Sign Address
    function getFeeManager() external view returns (address);

    // get token supply manager
    function getTokenSupplyManager() external view returns (address);

    // get redemption approved amount
    function getRedemptionApprovedAmount(address account_)
        external
        view
        returns (uint256);

    // is freeze all transaction
    function isAllTransactionsFreezed() external view returns (bool);

    // is acount freezed
    function isFreezed(address account_) external view returns (bool);

    // get list of freezed accounts
    function getFreezedAccounts() external view returns (address[] memory);

    // get holders
    function getHolders() external view returns (address[] memory);
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

// Supply Management Multi-Sig Interface
interface SupplyManagementMultiSigInterface {
    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_) external;

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // create supply management proposal
    function createSupplyManagementProposal(
        string memory orderType_,
        string memory paymentType_,
        uint256 orderSize_,
        address authorizedParticipant_,
        uint256 expiration_
    ) external;

    // approve Supply Management proposal
    function approveSupplyManagementProposal(
        uint256 supplyManagementProposalIndex_
    ) external;

    // revoke Supply Management proposal (by proposer)
    function revokeSupplyManagementProposal(
        uint256 supplyManagementProposalIndex_
    ) external;

    // get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get Max Supply Management Proposal Index
    function getMaxSupplyManagementProposalIndex()
        external
        view
        returns (uint256);

    // get Supply Management Proposal Detail
    // function getSupplyManagementProposalDetail(uint256 supplyManagementProposalIndex_) external view returns (SupplyManagementProposal memory);

    // IS Supply Management Proposal approver
    function IsSupplyManagementProposalApprover(
        uint256 supplyManagementProposalIndex_,
        address account_
    ) external view returns (bool);
}

// Supply Management Multi-Sig
contract SupplyManagementMultiSig {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // ERC20 Contract Address
    address private _ERC20ContractAddress;

    // ERC20 Contract Interface
    ERC20Interface private _ERC20;

    // Admin Multi-Sig Contract Address
    address private _AdminMultiSigContractAddress;

    // Admin Multi-Sig Contract Interface
    AdminMultiSigInterface private _AdminMultiSig;

    // Supply Management proposal counter
    uint256 private _supplyManagementProposalIndex = 0;

    // Supply Management Proposal struct
    struct SupplyManagementProposal {
        uint256 ID;
        address PROPOSER;
        string ORDERTYPE;
        string PAYMENTTYPE;
        uint256 ORDERSIZE;
        address AUTHORIZEDPARTICIPANT;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of supply management proposals info: proposal ID => proposal detail
    mapping(uint256 => SupplyManagementProposal)
        private _supplyManagementProposals;

    // supply management proposal approvers: admin proposal ID => address => status
    mapping(uint256 => mapping(address => bool))
        private _supplyManagementProposalApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(
        address ERC20ContractAddress_,
        address AdminMultiSigContractAddress_
    ) {
        
        // require account not be the zero address
        require(
            ERC20ContractAddress_ != address(0),
            "Supply Management Multi-Sig: ERC20 Address should not be zero address!"
        );
        
        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // update ERC20 Contract Interface
        _ERC20 = ERC20Interface(ERC20ContractAddress_);

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            address(0),
            ERC20ContractAddress_,
            block.timestamp
        );

        // require account not be the zero address
        require(
            AdminMultiSigContractAddress_ != address(0),
            "Supply Management Multi-Sig: Admin Multi-Sig Address should not be zero address!"
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

    // update ERC20 Contract Address
    event updateERC20ContractAddressEvent(
        address indexed AdminMultiSig,
        address previousERC20ContractAddress,
        address newERC20ContractAddress,
        uint256 indexed timestamp
    );

    // update Admin Multi-Sig Contract Address (only Admin)
    event updateAdminMultiSigContractAddressEvent(
        address indexed AdminMultiSig,
        address previousAdminMultiSigContractAddress,
        address indexed newAdminMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // create supply manager proposal
    event SupplyManagementProposalCreatedEvent(
        address indexed proposer,
        uint256 supplyManagementProposalIndex,
        string orderType,
        string paymentType,
        uint256 orderSize,
        address indexed authorizedParticipant,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute supply management proposal
    event SupplyManagementProposalExecutedEvent(
        address indexed executor,
        uint256 supplyManagementProposalIndex,
        string orderType,
        string paymentType,
        uint256 orderSize,
        address indexed authorizedParticipant,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve supply management proposal
    event ApproveSupplyManagementProposalEvent(
        address indexed approver,
        uint256 supplyManagementProposalIndex,
        string ORDERTYPE,
        string PAYMENTTYPE,
        uint256 ORDERSIZE,
        address indexed AUTHORIZEDPARTICIPANT,
        uint256 EXPIRATION,
        uint256 indexed timestamp
    );

    // revoke supply managment proposal
    event revokeSupplyManagementProposalEvent(
        address indexed proposer,
        uint256 supplyManagementProposalIndex,
        string orderType,
        string paymentType,
        uint256 orderSize,
        address indexed authorizedParticipant,
        uint256 expiration,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Supply Management signatories
    modifier onlySupplyManagers() {
        // require sender be a supply manager
        require(
            _AdminMultiSig.IsSupplyManagementSignatory(msg.sender),
            "Supply Management Multi-Sig: Sender is not a Supply Manager Signatory!"
        );
        _;
    }

    // only Valid Supply Management Proposal Index
    modifier onlyValidSupplyManagementIndex(
        uint256 supplyManagementProposalIndex_
    ) {
        // require valid supply management proposal index
        require(
            supplyManagementProposalIndex_ <= _supplyManagementProposalIndex,
            "Supply Management Multi-Sig: Invalid Supply Management Proposal Index!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Supply Management Multi-Sig: Address should not be zero address!"
        );
        _;
    }

    // only valid signatory group
    modifier onlyValidGroup(string memory signatoryGroup_) {
        // require valid signatory group
        require(
            keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ADMIN")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ASSETPROTECTION")),
            "Supply Management Multi-Sig: Signatory group is not valid!"
        );
        _;
    }

    // only valid signatory update type
    modifier onlyValidUpdateType(string memory updateType_) {
        // require valid update type
        require(
            keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("ADD")) ||
                keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("REMOVE")),
            "Supply Management Multi-Sig: Update type is not valid!"
        );
        _;
    }

    // only Valid Order Type
    modifier onlyValidOrderType(string memory orderType) {
        // valid order types: CREATION or REDEMPTION
        require(
            keccak256(abi.encodePacked(orderType)) ==
                keccak256(abi.encodePacked("CREATION")) ||
                keccak256(abi.encodePacked(orderType)) ==
                keccak256(abi.encodePacked("REDEMPTION")),
            "Supply Management Multi-Sig: Invalid Order Type!"
        );
        _;
    }

    // only Valid Payment Type
    modifier onlyValidPaymentType(string memory paymentType) {
        // valid payment types: ALREADY PAID, DEDUCT TOKEN
        require(
            keccak256(abi.encodePacked(paymentType)) ==
                keccak256(abi.encodePacked("ALREADY PAID")) ||
                keccak256(abi.encodePacked(paymentType)) ==
                keccak256(abi.encodePacked("DEDUCT TOKEN")),
            "Supply Management Multi-Sig: Invalid Payment Type!"
        );
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        require(
            value_ > 0,
            "Supply Management Multi-Sig: Value should be greater than zero!"
        );
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 supplyManagementProposalIndex_) {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _supplyManagementProposals[supplyManagementProposalIndex_]
                    .PROPOSER,
            "Supply Management Multi-Sig: Sender is not the proposer!"
        );
        _;
    }

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        // require sender be the admin multi-sig
        require(
            msg.sender == _AdminMultiSigContractAddress,
            "Sender is not admin!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_)
        public
        notNullAddress(ERC20ContractAddress_)
        onlyAdmin
    {
        // previous ERC20 Contract Address
        address previousERC20ContractAddress = _ERC20ContractAddress;

        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // update ERC20 Contract Interface
        _ERC20 = ERC20Interface(ERC20ContractAddress_);

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            previousERC20ContractAddress,
            ERC20ContractAddress_,
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

    // create supply management proposal
    function createSupplyManagementProposal(
        string memory orderType_,
        string memory paymentType_,
        uint256 orderSize_,
        address authorizedParticipant_,
        uint256 expiration_
    )
        public
        onlySupplyManagers
        notNullAddress(authorizedParticipant_)
        onlyValidOrderType(orderType_)
        onlyValidPaymentType(paymentType_)
        onlyGreaterThanZero(orderSize_)
        onlyGreaterThanZero(expiration_)
    {
        // increment supply managment proposal index
        ++_supplyManagementProposalIndex;

        // create supply management proposal
        _supplyManagementProposals[
            _supplyManagementProposalIndex
        ] = SupplyManagementProposal({
            ID: _supplyManagementProposalIndex,
            PROPOSER: msg.sender,
            ORDERTYPE: orderType_,
            PAYMENTTYPE: paymentType_,
            ORDERSIZE: orderSize_,
            AUTHORIZEDPARTICIPANT: authorizedParticipant_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the proposal by supply manager sender
        _supplyManagementProposalApprovers[_supplyManagementProposalIndex][
            msg.sender
        ] = true;

        // emit creating supply manager proposal event
        emit SupplyManagementProposalCreatedEvent(
            msg.sender,
            _supplyManagementProposalIndex,
            orderType_,
            paymentType_,
            orderSize_,
            authorizedParticipant_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if sender is the only supply manager
        address[] memory _supplyManagementSignatories = _AdminMultiSig
            .getSupplyManagementSignatories();

        if (_supplyManagementSignatories.length == 1) {
            // orderType
            if (
                keccak256(abi.encodePacked(orderType_)) ==
                keccak256(abi.encodePacked("CREATION"))
            ) {
                // execute creation order
                _ERC20.creationBasket(
                    orderSize_,
                    authorizedParticipant_,
                    paymentType_
                );

                // update IS EXECUTED
                _supplyManagementProposals[_supplyManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIME STAMP
                _supplyManagementProposals[_supplyManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing creation proposal
                emit SupplyManagementProposalExecutedEvent(
                    msg.sender,
                    _supplyManagementProposalIndex,
                    orderType_,
                    paymentType_,
                    orderSize_,
                    authorizedParticipant_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(orderType_)) ==
                keccak256(abi.encodePacked("REDEMPTION"))
            ) {
                // execute redemption order
                _ERC20.redemptionBasket(orderSize_, authorizedParticipant_);

                // update IS EXECUTED
                _supplyManagementProposals[_supplyManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIME STAMP
                _supplyManagementProposals[_supplyManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing redemption proposal
                emit SupplyManagementProposalExecutedEvent(
                    msg.sender,
                    _supplyManagementProposalIndex,
                    orderType_,
                    paymentType_,
                    orderSize_,
                    authorizedParticipant_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve Supply Management proposal
    function approveSupplyManagementProposal(
        uint256 supplyManagementProposalIndex_
    )
        public
        onlySupplyManagers
        onlyValidSupplyManagementIndex(supplyManagementProposalIndex_)
    {
        // supply management proposal info
        SupplyManagementProposal storage proposal = _supplyManagementProposals[
            supplyManagementProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION > block.timestamp ||
                _supplyManagementProposalApprovers[
                    supplyManagementProposalIndex_
                ][msg.sender]),
            "Supply Management Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by supply manager sender
        _supplyManagementProposalApprovers[supplyManagementProposalIndex_][
            msg.sender
        ] = true;

        // update supply manager proposal approval count
        proposal.APPROVALCOUNT++;

        // emit Supply Management proposal approved event
        emit ApproveSupplyManagementProposalEvent(
            msg.sender,
            _supplyManagementProposalIndex,
            proposal.ORDERTYPE,
            proposal.PAYMENTTYPE,
            proposal.ORDERSIZE,
            proposal.AUTHORIZEDPARTICIPANT,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (
            _supplyManagementProposals[_supplyManagementProposalIndex]
                .APPROVALCOUNT >=
            _AdminMultiSig.getSupplyManagementMinSignatures()
        ) {
            // sender execute the proposal
            // orderType
            if (
                keccak256(abi.encodePacked(proposal.ORDERTYPE)) ==
                keccak256(abi.encodePacked("CREATION"))
            ) {
                // execute creation order
                _ERC20.creationBasket(
                    proposal.ORDERSIZE,
                    proposal.AUTHORIZEDPARTICIPANT,
                    proposal.PAYMENTTYPE
                );

                // update EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // emit executing creation proposal
                emit SupplyManagementProposalExecutedEvent(
                    msg.sender,
                    _supplyManagementProposalIndex,
                    proposal.ORDERTYPE,
                    proposal.PAYMENTTYPE,
                    proposal.ORDERSIZE,
                    proposal.AUTHORIZEDPARTICIPANT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ORDERTYPE)) ==
                keccak256(abi.encodePacked("REDEMPTION"))
            ) {
                // execute redemption order
                _ERC20.redemptionBasket(
                    proposal.ORDERSIZE,
                    proposal.AUTHORIZEDPARTICIPANT
                );

                // update EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // emit executing redemption proposal
                emit SupplyManagementProposalExecutedEvent(
                    msg.sender,
                    _supplyManagementProposalIndex,
                    proposal.ORDERTYPE,
                    proposal.PAYMENTTYPE,
                    proposal.ORDERSIZE,
                    proposal.AUTHORIZEDPARTICIPANT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke Supply Management proposal (by proposer)
    function revokeSupplyManagementProposal(
        uint256 supplyManagementProposalIndex_
    ) public onlySupplyManagers onlyProposer(supplyManagementProposalIndex_) {
        // admin proposal info
        SupplyManagementProposal storage proposal = _supplyManagementProposals[
            supplyManagementProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Supply Management Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // UPDATE REVOKED TIMESTAMP
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeSupplyManagementProposalEvent(
            msg.sender,
            supplyManagementProposalIndex_,
            proposal.ORDERTYPE,
            proposal.PAYMENTTYPE,
            proposal.ORDERSIZE,
            proposal.AUTHORIZEDPARTICIPANT,
            proposal.EXPIRATION,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() public view returns (address) {
        return _AdminMultiSigContractAddress;
    }

    // get Max Supply Management Proposal Index
    function getMaxSupplyManagementProposalIndex()
        public
        view
        returns (uint256)
    {
        return _supplyManagementProposalIndex;
    }

    // get Supply Management Proposal Detail
    function getSupplyManagementProposalDetail(
        uint256 supplyManagementProposalIndex_
    ) public view returns (SupplyManagementProposal memory) {
        return _supplyManagementProposals[supplyManagementProposalIndex_];
    }

    // IS Supply Management Proposal approver
    function IsSupplyManagementProposalApprover(
        uint256 supplyManagementProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _supplyManagementProposalApprovers[supplyManagementProposalIndex_][
                account_
            ];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}