/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ERC20 IntKerface
interface ERC20Interface {
    // withdraw tokens from contract to Treasurer account
    function withdrawContractTokens() external;
}

// Address Book Interface
interface AddressBookInterface {
    // Get ERC20 Contract Address
    function getERC20ContractAddress() external view returns (address);

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // Get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);
}

// Fee Management Interface
interface FeeManagementInterface {
    // authorize for redemption
    function authorizeRedemption(uint256 redemptionAmount_) external;

    // add account to global whitelist
    function appendToGlobalWhitelist(address account_) external;

    // remove account from global whitelist
    function removeFromGlobalWhitelist(address account_) external;

    // add account to creation/redemption whitelist
    function appendToCRWhitelist(address account_) external;

    // remove account from creation/redemption whitelist
    function removeFromCRWhitelist(address account_) external;

    // add account to transfer whitelist
    function appendToTransferWhitelist(address account_) external;

    // remove account from transfer whitelist
    function removeFromTransferWhitelist(address account_) external;

    // set fee decimals
    function setFeeDecimals(uint256 feeDecimals_) external;

    // set creation fee
    function setCreationFee(uint256 creationFee_) external;

    // set redemption fee
    function setRedemptionFee(uint256 redemptionFee_) external;

    // set transfer fee
    function setTransferFee(uint256 transferFee_) external;

    // set min transfer amount
    function setMinTransferAmount(uint256 amount_) external;

    // set min creation amount
    function setMinCreationAmount(uint256 amount_) external;

    // set min redemption amount
    function setMinRedemptionAmount(uint256 amount_) external;
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

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

    // get Fee Management Freeze status
    function getFeeManagementFreezeStatus() external view returns (bool);
}

// Fee Management Multi-Sig Interface
interface FeeManagementMultiSigInterface {
    // Fee Manager Proposal struct
    struct FeeManagerProposal {
        uint256 ID;
        string PROPOSALNAME;
        address PROPOSER;
        string CATEGORY;
        uint256 AMOUNT;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // create fee update proposal
    function createFeeUpdateProposal(
        string memory feeCategory_,
        uint256 feeAmount_,
        uint256 expiration_
    ) external;

    // approve fee update proposal
    function approveFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        external;

    // revoke fee update proposal
    function revokeFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        external;

    // create fee exemption proposal
    function createFeeExemptionProposal(
        string memory exemptionCategory_,
        string memory updateType_,
        address account_,
        uint256 expiration_
    ) external;

    // approve fee exemption proposal
    function approveFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        external;

    // revoke fee exemption proposal
    function revokeFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        external;

    // get max fee management proposal index
    function getMaxFeeManagementProposalIndex() external view returns (uint256);

    // get Fee Manager Proposal Detail
    function getFeeManagerProposalDetail(uint256 feeManagementProposalIndex_)
        external
        view
        returns (FeeManagerProposal memory);

    // is Fee Manger proposal approver
    function IsFeeMangerProposalApprover(
        uint256 feeManagementProposalIndex_,
        address account_
    ) external view returns (bool);

    // is whitelist manager proposal approvers
    function IsWhitelistManagerProposalApprovers(
        uint256 feeManagementProposalIndex_,
        address account_
    ) external view returns (bool);
}

// Fee Management Multi-Sig
contract FeeManagementMultiSig is FeeManagementMultiSigInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // Admin Multi-Sig Contract Address
    address private _AdminMultiSigContractAddress;

    // Admin Multi-Sig Contract Interface
    AdminMultiSigInterface private _AdminMultiSig;

    // contract version
    uint256 private _contractVersion = 1;

    // Fee Management proposal counter
    uint256 private _feeManagementProposalIndex = 0;

    // list of fee manager proposals info: Fee Management proposal index => proposal detail
    mapping(uint256 => FeeManagerProposal) private _feeManagerProposals;

    // fee manager proposal approvers: Fee Management proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _feeManagerProposalApprovers;

    // Whitelist Manager Proposal struct
    struct WhitelistManagerProposal {
        uint256 ID;
        string PROPOSALNAME;
        address PROPOSER;
        string EXEMPTIOMCATEGORY;
        string UPDATETYPE; // ADD or REMOVE
        address ACCOUNT;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of whitelist manager proposals info: Fee Management proposal index => proposal detail
    mapping(uint256 => WhitelistManagerProposal)
        private _whitelistManagerProposals;

    // whitelist manager proposal approvers: Fee Management proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _whitelistManagerProposalApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(address AdminMultiSigContractAddress_) {
        // require non-zero address
        require(
            AdminMultiSigContractAddress_ != address(0),
            "Fee Management Multi-Sig: Admin Multi-Sig should not be zero-address!"
        );

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // update Address Book Contract Interface
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

    // update Admin Multi-Sig contract address
    event updateAdminMultiSigContractAddressEvent(
        address indexed Admin,
        address previousAdminMultiSigContractAddress,
        address indexed newAdminMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // create fee manager proposal
    event FeeManagerProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string feeCategory,
        uint256 feeAmount,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute updating fee proposal
    event FeeManagerProposalExecutedEvent(
        address indexed executor,
        uint256 indexed feeManagementProposalIndex,
        string feeCategory,
        uint256 feeAmount,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve Fee Manager proposal
    event ApproveFeeManagerProposalEvent(
        address indexed approver,
        uint256 indexed feeManagementProposalIndex,
        string FEECATEGORY,
        uint256 FEEAMOUNT,
        uint256 EXPIRATION,
        uint256 indexed timestamp
    );

    // revoke fee manager proposal
    event revokeFeeManagerProposalEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string FEECATEGORY,
        uint256 FEEAMOUNT,
        uint256 EXPIRATION,
        uint256 indexed timestamp
    );

    // create whitelist manager proposal
    event WhiteListManagerProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute whitelist manager proposal
    event WhitelistManagerProposalExecutedEvent(
        address indexed executor,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // Whitelist Manager proposal approved
    event ApproveWhitelistManagerProposalEvent(
        address indexed approver,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // revoke whitelist manager proposal
    event revokeWhitelistManagerProposalEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Fee Management signatories
    modifier onlyFeeManagers() {
        // require sender be a fee manager
        _onlyFeeManagers();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only Valid Category
    modifier onlyValidCategory(string memory category_) {
        // require valid category
        _onlyValidCategory(category_);
        _;
    }

    // only valid Exemption Category
    modifier onlyValidExemptionCategory(string memory exemptionCategory_) {
        // require valid exemption category
        _onlyValidExemptionCategory(exemptionCategory_);
        _;
    }

    // only valid exemption update type
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

    // only Valid Fee Management Index
    modifier onlyValidFeeManagementIndex(uint256 feeManagementProposalIndex_) {
        // require valid index
        _onlyValidFeeManagementIndex(feeManagementProposalIndex_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 feeManagementProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(feeManagementProposalIndex_);
        _;
    }

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    // only Address Book
    modifier onlyAddressBook() {
        _onlyAddressBook();
        _;
    }

    // only unfreezed fee management
    modifier onlyUnfreezedFeeManagement() {
        _onlyUnfreezedFeeManagement();
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) public onlyAddressBook notNullAddress(AdminMultiSigContractAddress_) {
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

    // create fee update proposal
    function createFeeUpdateProposal(
        string memory category_,
        uint256 amount_,
        uint256 expiration_
    )
        public
        onlyFeeManagers
        onlyValidCategory(category_)
        onlyGreaterThanZero(expiration_)
        onlyUnfreezedFeeManagement
    {
        // increment fee managment proposal index
        ++_feeManagementProposalIndex;

        // create fee manager proposal
        _feeManagerProposals[_feeManagementProposalIndex] = FeeManagerProposal({
            ID: _feeManagementProposalIndex,
            PROPOSALNAME: string.concat("UPDATE ", category_),
            PROPOSER: msg.sender,
            CATEGORY: category_,
            AMOUNT: amount_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the porposal by fee manager sender
        _feeManagerProposalApprovers[_feeManagementProposalIndex][
            msg.sender
        ] = true;

        // emit creating fee manager proposal event
        emit FeeManagerProposalCreatedEvent(
            msg.sender,
            _feeManagementProposalIndex,
            category_,
            amount_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if sender is the only supply manager
        address[] memory _feeManagerSignatories = _AdminMultiSig
            .getFeeManagementSignatories();

        if (_feeManagerSignatories.length == 1) {
            // category
            if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("CREATIONFEE"))
            ) {
                // execute update creation fee order
                _FeeManagementContract().setCreationFee(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("REDEMPTIONFEE"))
            ) {
                // execute update redemption fee order
                _FeeManagementContract().setRedemptionFee(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating redemption fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("TRANSFERFEE"))
            ) {
                // execute update transfer fee order
                _FeeManagementContract().setTransferFee(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("FEEDECIMALS"))
            ) {
                // execute setting fee decimals
                _FeeManagementContract().setFeeDecimals(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing setting fee decimals
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINTRANSFERAMOUNT"))
            ) {
                // execute set min transfer amount order
                _FeeManagementContract().setMinTransferAmount(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINCREATIONAMOUNT"))
            ) {
                // execute set min creation amount order
                _FeeManagementContract().setMinCreationAmount(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min creation amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINREDEMPTIONAMOUNT"))
            ) {
                // execute min redemption amount order
                _FeeManagementContract().setMinRedemptionAmount(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min redemption amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("AUTHORIZEREDEMPTION"))
            ) {
                // execute AUTHORIZE REDEMPTION
                _FeeManagementContract().authorizeRedemption(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing authorize redemption proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("WITHDRAWCONTRACTTOKEN"))
            ) {
                // execute WITHDRAW CONTRACT TOKEN
                _ERC20Contract().withdrawContractTokens();

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing withdraw contract token proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve fee update proposal
    function approveFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyValidFeeManagementIndex(feeManagementProposalIndex_)
        onlyUnfreezedFeeManagement
    {
        // fee manager proposal info
        FeeManagerProposal storage proposal = _feeManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION > block.timestamp ||
                _feeManagerProposalApprovers[feeManagementProposalIndex_][
                    msg.sender
                ]),
            "Fee Management Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by fee manager sender
        _feeManagerProposalApprovers[feeManagementProposalIndex_][
            msg.sender
        ] = true;

        // update fee manager proposal approval count
        proposal.APPROVALCOUNT++;

        // emit Fee Manager proposal approved event
        emit ApproveFeeManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.CATEGORY,
            proposal.AMOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (
            proposal.APPROVALCOUNT >=
            _AdminMultiSig.getFeeManagementMinSignatures()
        ) {
            // sender execute the proposal
            // orderType
            if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("CREATION"))
            ) {
                // execute update creation fee order
                _FeeManagementContract().setCreationFee(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("REDEMPTION"))
            ) {
                // execute update redemption fee order
                _FeeManagementContract().setRedemptionFee(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating redemption fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("TRANSFER"))
            ) {
                // execute update transfer fee order
                _FeeManagementContract().setTransferFee(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("FEEDECIMALS"))
            ) {
                // execute setting fee decimals
                _FeeManagementContract().setFeeDecimals(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing setting fee decimals
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("MINTRANSFERAMOUNT"))
            ) {
                // execute set min transfer amount order
                _FeeManagementContract().setMinTransferAmount(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("MINCREATIONAMOUNT"))
            ) {
                // execute set min creation amount order
                _FeeManagementContract().setMinCreationAmount(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min creation amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("MINREDEMPTIONAMOUNT"))
            ) {
                // execute min redemption amount order
                _FeeManagementContract().setMinRedemptionAmount(
                    proposal.AMOUNT
                );

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min redemption amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("AUTHORIZEREDEMPTION"))
            ) {
                // execute AUTHORIZE REDEMPTION
                _FeeManagementContract().authorizeRedemption(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing authorize redemption proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("WITHDRAWCONTRACTTOKEN"))
            ) {
                // execute WITHDRAW CONTRACT TOKEN
                _ERC20Contract().withdrawContractTokens();

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing withdraw contract token proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke fee update proposal
    function revokeFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyProposer(feeManagementProposalIndex_)
        onlyUnfreezedFeeManagement
    {
        // fee manager proposal info
        FeeManagerProposal storage proposal = _feeManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Fee Management Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update REVOKED TIMESTAMP
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeFeeManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.CATEGORY,
            proposal.AMOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );
    }

    // create fee exemption proposal
    function createFeeExemptionProposal(
        string memory exemptionCategory_,
        string memory updateType_,
        address account_,
        uint256 expiration_
    )
        public
        onlyFeeManagers
        onlyValidExemptionCategory(exemptionCategory_)
        onlyValidUpdateType(updateType_)
        notNullAddress(account_)
        onlyGreaterThanZero(expiration_)
        onlyUnfreezedFeeManagement
    {
        // increment fee managment proposal index
        ++_feeManagementProposalIndex;

        // create whitelist manager proposal
        _whitelistManagerProposals[
            _feeManagementProposalIndex
        ] = WhitelistManagerProposal({
            ID: _feeManagementProposalIndex,
            PROPOSALNAME: string.concat(
                "UPDATE ",
                exemptionCategory_,
                " WHITELIST"
            ),
            PROPOSER: msg.sender,
            EXEMPTIOMCATEGORY: exemptionCategory_,
            UPDATETYPE: updateType_,
            ACCOUNT: account_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the porposal by whitelist manager sender
        _whitelistManagerProposalApprovers[_feeManagementProposalIndex][
            msg.sender
        ] = true;

        // emit creating whitelist manager proposal event
        emit WhiteListManagerProposalCreatedEvent(
            msg.sender,
            _feeManagementProposalIndex,
            exemptionCategory_,
            updateType_,
            account_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if sender is the only fee manager
        address[] memory _feeManagementSignatories = _AdminMultiSig
            .getFeeManagementSignatories();

        if (_feeManagementSignatories.length == 1) {
            // exemption category
            if (
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("GLOBAL"))
            ) {
                // execute global whitelist
                if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagementContract().appendToGlobalWhitelist(account_);
                } else if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagementContract().removeFromGlobalWhitelist(
                        account_
                    );
                }

                // update IS EXECUTED
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    exemptionCategory_,
                    updateType_,
                    account_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("CREATIONREDEMPTION"))
            ) {
                // execute creation | redemption whitelist
                if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagementContract().appendToGlobalWhitelist(account_);
                } else if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagementContract().removeFromCRWhitelist(account_);
                }

                // update IS EXECUTED
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    exemptionCategory_,
                    updateType_,
                    account_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("TRANSFER"))
            ) {
                // execute transfer whitelist
                if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagementContract().appendToTransferWhitelist(
                        account_
                    );
                } else if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagementContract().removeFromTransferWhitelist(
                        account_
                    );
                }

                // update IS EXECUTED
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    exemptionCategory_,
                    updateType_,
                    account_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve fee exemption proposal
    function approveFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyValidFeeManagementIndex(feeManagementProposalIndex_)
        onlyUnfreezedFeeManagement
    {
        // whitelist manager proposal info
        WhitelistManagerProposal storage proposal = _whitelistManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION > block.timestamp ||
                _whitelistManagerProposalApprovers[feeManagementProposalIndex_][
                    msg.sender
                ]),
            "Fee Management Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by whitelist manager sender
        _whitelistManagerProposalApprovers[feeManagementProposalIndex_][
            msg.sender
        ] = true;

        // update fee management proposal approval count
        proposal.APPROVALCOUNT++;

        // emit Fee Manager proposal approved event
        emit ApproveWhitelistManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.EXEMPTIOMCATEGORY,
            proposal.UPDATETYPE,
            proposal.ACCOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (
            proposal.APPROVALCOUNT >=
            _AdminMultiSig.getFeeManagementMinSignatures()
        ) {
            // sender execute the proposal
            // exemption category
            if (
                keccak256(abi.encodePacked(proposal.EXEMPTIOMCATEGORY)) ==
                keccak256(abi.encodePacked("GLOBAL"))
            ) {
                // execute update creation fee order
                if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagementContract().appendToGlobalWhitelist(
                        proposal.ACCOUNT
                    );
                } else if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagementContract().removeFromGlobalWhitelist(
                        proposal.ACCOUNT
                    );
                }

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating global whitelist proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    feeManagementProposalIndex_,
                    proposal.EXEMPTIOMCATEGORY,
                    proposal.UPDATETYPE,
                    proposal.ACCOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.EXEMPTIOMCATEGORY)) ==
                keccak256(abi.encodePacked("CREATIONREDEMPTION"))
            ) {
                // execute update redemption fee order
                if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagementContract().appendToCRWhitelist(
                        proposal.ACCOUNT
                    );
                } else if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagementContract().removeFromCRWhitelist(
                        proposal.ACCOUNT
                    );
                }

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation | redemption whitelist proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    feeManagementProposalIndex_,
                    proposal.EXEMPTIOMCATEGORY,
                    proposal.UPDATETYPE,
                    proposal.ACCOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.EXEMPTIOMCATEGORY)) ==
                keccak256(abi.encodePacked("TRANSFER"))
            ) {
                // execute update transfer fee order
                if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagementContract().appendToTransferWhitelist(
                        proposal.ACCOUNT
                    );
                } else if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagementContract().removeFromTransferWhitelist(
                        proposal.ACCOUNT
                    );
                }

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer whitelist proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    feeManagementProposalIndex_,
                    proposal.EXEMPTIOMCATEGORY,
                    proposal.UPDATETYPE,
                    proposal.ACCOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke fee exemption proposal
    function revokeFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyProposer(feeManagementProposalIndex_)
        onlyUnfreezedFeeManagement
    {
        // whitelist manager proposal info
        WhitelistManagerProposal storage proposal = _whitelistManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Fee Management Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeWhitelistManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.EXEMPTIOMCATEGORY,
            proposal.UPDATETYPE,
            proposal.ACCOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    // get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() public view returns (address) {
        return _AdminMultiSigContractAddress;
    }

    // get max fee management proposal index
    function getMaxFeeManagementProposalIndex() public view returns (uint256) {
        return _feeManagementProposalIndex;
    }

    // get Fee Manager Proposal Detail
    function getFeeManagerProposalDetail(uint256 feeManagementProposalIndex_)
        public
        view
        returns (FeeManagerProposal memory)
    {
        return _feeManagerProposals[feeManagementProposalIndex_];
    }

    // is Fee Manger proposal approver
    function IsFeeMangerProposalApprover(
        uint256 feeManagementProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _feeManagerProposalApprovers[feeManagementProposalIndex_][account_];
    }

    // get whitelist manager proposal detail
    function getWhitelistMangerProposalDetail(
        uint256 feeManagementProposalIndex_
    ) public view returns (WhitelistManagerProposal memory) {
        return _whitelistManagerProposals[feeManagementProposalIndex_];
    }

    // is whitelist manager proposal approvers
    function IsWhitelistManagerProposalApprovers(
        uint256 feeManagementProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _whitelistManagerProposalApprovers[feeManagementProposalIndex_][
                account_
            ];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // get ERC20 Contract Interface
    function _ERC20Contract() internal view returns (ERC20Interface) {
        return ERC20Interface(_AddressBook().getERC20ContractAddress());
    }

    // get Fee Management Contract Interface
    function _FeeManagementContract()
        internal
        view
        returns (FeeManagementInterface)
    {
        return
            FeeManagementInterface(
                _AddressBook().getFeeManagementContractAddress()
            );
    }

    // only Fee Management signatories
    function _onlyFeeManagers() internal view {
        // require sender be a fee manager
        require(
            _AdminMultiSig.IsFeeManagementSignatory(msg.sender),
            "Fee Management Multi-Sig: Sender is not a Fee Manager Signatory!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Fee Management Multi-Sig: Address should not be zero address!"
        );
    }

    // only Valid Category
    function _onlyValidCategory(string memory category_) internal pure {
        // require valid category
        require(
            keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("TRANSFERFEE")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("CREATIONFEE")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("REDEMPTIONFEE")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("FEEDECIMALS")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINTRANSFERAMOUNT")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINCREATIONAMOUNT")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINREDEMPTIONAMOUNT")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("AUTHORIZEREDEMPTION")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("WITHDRAWCONTRACTTOKEN")),
            "Fee Management Multi-Sig: Invalid category!"
        );
    }

    // only valid Exemption Category
    function _onlyValidExemptionCategory(string memory exemptionCategory_)
        internal
        pure
    {
        // require valid exemption category
        require(
            keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("GLOBAL")) ||
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("TRANSFER")) ||
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("CREATIONREDEMPTION")),
            "Fee Management Multi-Sig: Exemption category is not valid!"
        );
    }

    // only valid exemption update type
    function _onlyValidUpdateType(string memory updateType_) internal pure {
        // require valid update type
        require(
            keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("ADD")) ||
                keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("REMOVE")),
            "Fee Management Multi-Sig: Update type is not valid!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal pure {
        // require value be greater than zero
        require(
            value_ > 0,
            "Fee Management Multi-Sig: Value should be greater than zero!"
        );
    }

    // only Valid Fee Management Index
    function _onlyValidFeeManagementIndex(uint256 feeManagementProposalIndex_)
        internal
        view
    {
        // require valid index
        require(
            ((feeManagementProposalIndex_ != 0) &&
                (feeManagementProposalIndex_ <= _feeManagementProposalIndex)),
            "Fee Management Multi-Sig: Invalid fee management proposal index!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 feeManagementProposalIndex_) internal view {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _feeManagerProposals[feeManagementProposalIndex_].PROPOSER,
            "Fee Management Multi-Sig: Sender is not the proposer!"
        );
    }

    // only Admin Multi-Sig
    function _onlyAdmin() internal view {
        // require sender be Admin Multi-Sig
        require(
            msg.sender == _AdminMultiSigContractAddress,
            "Fee Management Multi-Sig: Sender is not Admin Multi-Sig!"
        );
    }

    // only Address Book
    function _onlyAddressBook() internal view {
        // require sender be Address Book
        require(
            msg.sender ==
                AdminMultiSigInterface(
                    _AddressBook().getAdminMultiSigContractAddress()
                ).getAddressBookContractAddress(),
            "Fee Management Multi-Sig: Sender is not Address Book!"
        );
    }

    // get Address Book Contract Interface
    function _AddressBook() internal view returns (AddressBookInterface) {
        return
            AddressBookInterface(
                _AdminMultiSig.getAddressBookContractAddress()
            );
    }

    // only unfreezed fee management
    function _onlyUnfreezedFeeManagement() internal view {
        // require false freeze status
        require(
            !AdminMultiSigInterface(_AdminMultiSigContractAddress)
                .getFeeManagementFreezeStatus(),
            "Fee Management Multi-Sig: Fee Management activities are freezed by Admin!"
        );
    }
}