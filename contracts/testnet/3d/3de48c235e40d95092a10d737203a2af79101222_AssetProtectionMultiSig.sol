/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ERC20 Interface
interface ERC20Interface {
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
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);
}

// Address Book Interface
interface AddressBookInterface {
    // Get ERC20 Contract Address
    function getERC20ContractAddress() external view returns (address);

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);
}

// Asset Protection Multi-Sig Interface
interface AssetProtectionMultiSigInterface {
    // Asset Protection Proposal struct
    struct AssetProtectionProposal {
        uint256 ID;
        string PROPOSALNAME;
        address PROPOSER;
        address ACCOUNT;
        string ACTION;
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

    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory updateType_,
        uint256 expiration_
    ) external;

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 assetProtectionProposalIndex_)
        external;

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 assetProtectionProposalIndex_)
        external;

    // create Asset Protection Proposal
    function createAssetProtectionProposal(
        address account_,
        string memory action_,
        uint256 amount_,
        uint256 expiration_
    ) external;

    // approve Asset Protection Proposal
    function approveAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    ) external;

    // revoke Asset Protection Proposal
    function revokeAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    ) external;

    // get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get max asset protection index
    function getMaxAssetProtectionIndex() external view returns (uint256);

    // get asset protection proposal detail
    function getAssetProtectionProposalDetail(
        uint256 assetProtectionProposalIndex_
    ) external view returns (AssetProtectionProposal memory);

    // is asset protection proposal apporver
    function IsAssetProtectionProposalApprover(
        uint256 assetProtectionProposalIndex_,
        address account_
    ) external view returns (bool);
}

// Asset Protection Multi-Sig
contract AssetProtectionMultiSig is AssetProtectionMultiSigInterface {
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

    ///   Asset Protection Signatories   ///

    // list of Asset Protection Signatories
    address[] private _assetProtectionSignatories;

    // is an Asset Protection Signatory
    mapping(address => bool) private _isAssetProtectionSignatory;

    // Asset Protection proposal counter
    uint256 private _assetProtectionProposalIndex = 0;

    // Signatory Proposal struct for managing signatories
    struct SignatoryProposal {
        uint256 ID;
        string PROPOSALNAME;
        address PROPOSER;
        address MODIFIEDSIGNER;
        string UPDATETYPE; // ADD or REMOVE
        bool ISEXECUTED;
        uint256 EXPIRATION; // expiration timestamp
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of signatory proposals info: admin proposal index => signatory proposal detail
    mapping(uint256 => SignatoryProposal) private _signatoryProposals;

    // signatory proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _signatoryProposalApprovers;

    // minimum Asset Protection signature requirement
    uint256 private _minAssetProtectionSignatures;

    // list of asset protection proposals info: Asset Protection proposal index => proposal detail
    mapping(uint256 => AssetProtectionProposal)
        private _assetProtectionProposals;

    // asset protection proposal approvers: Asset Protection proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _assetProtectionProposalApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(
        uint256 minSignatures_,
        address[] memory Signatories_,
        address AdminMultiSigContractAddress_
    ) {
        // require valid initialization
        require(
            minSignatures_ <= Signatories_.length,
            "Asset Protection Multi-Sig: Invalid initialization!"
        );

        // set min singatures
        _minAssetProtectionSignatures = minSignatures_;

        // add signers
        for (uint256 i = 0; i < Signatories_.length; i++) {
            // admin signer
            address signatory = Signatories_[i];

            // add signatory
            _assetProtectionSignatories.push(signatory);

            // update signatory status
            _isAssetProtectionSignatory[signatory] = true;

            // emit adding signatory event with index 0
            emit SingatoryProposalExecutedEvent(
                msg.sender,
                0,
                signatory,
                "ADD",
                0,
                block.timestamp
            );
        }

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

    // create signatory proposal
    event SignatoryProposalCreatedEvent(
        address indexed proposer,
        uint256 adminProposalIndex,
        address indexed proposedAdminSignatory,
        string updateType,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute signatory proposal
    event SingatoryProposalExecutedEvent(
        address indexed executor,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string updateType,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve signatory proposal
    event ApproveSignatoryProposalEvent(
        address indexed approver,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string UPDATETYPE,
        uint256 indexed timestamp
    );

    // revoke signatory proposal by proposer
    event revokeSignatoryProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string updateType,
        uint256 indexed timestamp
    );

    // create asset protection proposal
    event AssetProtectionProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        uint256 amount,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute freeze account proposal
    event AssetProtectionProposalExecutedEvent(
        address indexed executor,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve asset protection proposal
    event ApproveAssetProtectionProposalEvent(
        address indexed approver,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // revoke asset protection proposal
    event revokeAssetProtectionProposalEvent(
        address indexed proposer,
        uint256 indexed assetProtectionProposalIndex,
        address account,
        string action,
        uint256 expiration,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Asset Protection signatories
    modifier onlyAssetProtectors() {
        // require sender be an asset protector
        _onlyAssetProtectors();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only valid actions
    modifier onlyValidAction(string memory action_) {
        // require valid actions
        _onlyValidAction(action_);
        _;
    }

    // only valid adminProposalIndex
    modifier onlyValidAssetProtectionIndex(
        uint256 assetProtectionProposalIndex_
    ) {
        // require a valid admin proposal index ( != 0 and not more than max)
        _onlyValidAssetProtectionIndex(assetProtectionProposalIndex_);
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        _onlyGreaterThanZero(value_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 assetProtectionProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(assetProtectionProposalIndex_);
        _;
    }

    // only valid signatory update type
    modifier onlyValidUpdateType(string memory updateType_) {
        // require valid update type
        _onlyValidUpdateType(updateType_);
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

    ///   Signatory Proposal   ///

    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory updateType_,
        uint256 expiration_
    )
        public
        onlyAssetProtectors
        notNullAddress(signatoryAddress_)
        onlyValidUpdateType(updateType_)
        onlyGreaterThanZero(expiration_)
    {
        // check update type
        if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("ADD"))
        ) {
            // require account not be an Asset Protection signatory
            require(
                !_isAssetProtectionSignatory[signatoryAddress_],
                "Asset Protection Multi-Sig: Account is already an Asset Protection signatory!"
            );

            // increment asset protection proposal index
            ++_assetProtectionProposalIndex;

            // add the admin proposal
            _signatoryProposals[
                _assetProtectionProposalIndex
            ] = SignatoryProposal({
                ID: _assetProtectionProposalIndex,
                PROPOSALNAME: "ADD SIGNATORY",
                PROPOSER: msg.sender,
                MODIFIEDSIGNER: signatoryAddress_,
                UPDATETYPE: updateType_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve proposal by admin sender
            _signatoryProposalApprovers[_assetProtectionProposalIndex][
                msg.sender
            ] = true;

            // emit add admin signatory proposal event
            emit SignatoryProposalCreatedEvent(
                msg.sender,
                _assetProtectionProposalIndex,
                signatoryAddress_,
                updateType_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only signatory.
            if (_assetProtectionSignatories.length == 1) {
                // add the new Asset Protection signatory directly: no need to create proposal
                // add to the Asset Protection signatories
                _assetProtectionSignatories.push(signatoryAddress_);

                // update Asset Protection signatory status
                _isAssetProtectionSignatory[signatoryAddress_] = true;

                // update proposal IS EXECUTED
                _signatoryProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update executed timestamp
                _signatoryProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit signatory added event
                emit SingatoryProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    signatoryAddress_,
                    updateType_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // require address be an Asset Protection signatory
            // and min signature not less than new number of signatories
            require(
                (_isAssetProtectionSignatory[signatoryAddress_] &&
                    _minAssetProtectionSignatures <
                    _assetProtectionSignatories.length),
                "Asset Protection Multi-Sig: Requested account is not an Asset Protection signatory!"
            );

            // increment asset protection proposal index
            ++_assetProtectionProposalIndex;

            // add proposal
            _signatoryProposals[
                _assetProtectionProposalIndex
            ] = SignatoryProposal({
                ID: _assetProtectionProposalIndex,
                PROPOSALNAME: "REMOVE SIGNATORY",
                PROPOSER: msg.sender,
                MODIFIEDSIGNER: signatoryAddress_,
                UPDATETYPE: updateType_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _signatoryProposalApprovers[_assetProtectionProposalIndex][
                msg.sender
            ] = true;

            // emit remove admin signatory proposal event
            emit SignatoryProposalCreatedEvent(
                msg.sender,
                _assetProtectionProposalIndex,
                signatoryAddress_,
                updateType_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only admin signatory.
            if (_assetProtectionSignatories.length == 1) {
                // update proposal IS EXECUTED
                _signatoryProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // remove Asset Protection signatory
                _isAssetProtectionSignatory[signatoryAddress_] = false;

                // update executed timestamp
                _signatoryProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                for (
                    uint256 i = 0;
                    i < _assetProtectionSignatories.length;
                    i++
                ) {
                    if (_assetProtectionSignatories[i] == signatoryAddress_) {
                        _assetProtectionSignatories[
                            i
                        ] = _assetProtectionSignatories[
                            _assetProtectionSignatories.length - 1
                        ];
                        break;
                    }
                }
                _assetProtectionSignatories.pop();

                // emit event
                emit SingatoryProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    signatoryAddress_,
                    updateType_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 assetProtectionProposalIndex_)
        public
        onlyAssetProtectors
        onlyValidAssetProtectionIndex(assetProtectionProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                _signatoryProposalApprovers[assetProtectionProposalIndex_][
                    msg.sender
                ] ||
                proposal.ISREVOKED),
            "Asset Protection Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // if Removing a signatory, require min signatures is not violated (minSignatures > signatories.length)
        if (
            keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // require not violating min signature
            require(
                _assetProtectionSignatories.length >
                    _minAssetProtectionSignatures,
                "Asset Protection Multi-Sig: Minimum Asset Protection signatories requirement not met!"
            );
        }

        // update proposal approved by admin sender status
        _signatoryProposalApprovers[assetProtectionProposalIndex_][
            msg.sender
        ] = true;

        // update proposal approval
        proposal.APPROVALCOUNT++;

        // emit admin signatory proposal approved event
        emit ApproveSignatoryProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.MODIFIEDSIGNER,
            proposal.UPDATETYPE,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (proposal.APPROVALCOUNT >= _minAssetProtectionSignatures) {
            // add the new signatory
            _assetProtectionSignatories.push(proposal.MODIFIEDSIGNER);

            // update role
            _isAssetProtectionSignatory[proposal.MODIFIEDSIGNER] = true;

            // update is executed
            proposal.ISEXECUTED = true;

            // udpate executed timestamp
            proposal.EXECUTEDTIMESTAMP = block.timestamp;

            // emit executing signatory proposal
            emit SingatoryProposalExecutedEvent(
                msg.sender,
                assetProtectionProposalIndex_,
                proposal.MODIFIEDSIGNER,
                proposal.UPDATETYPE,
                proposal.EXPIRATION,
                block.timestamp
            );
        }
    }

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 assetProtectionProposalIndex_)
        public
        onlyAssetProtectors
        onlyProposer(assetProtectionProposalIndex_)
        onlyValidAssetProtectionIndex(assetProtectionProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired or revoked
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Asset Protection Multi-Sig: Proposal should not be executed, expired or revoked!"
        );

        // revoke the proposal
        _signatoryProposals[assetProtectionProposalIndex_].ISREVOKED = true;

        // UPDATE REVOKED TIMESTAMP
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeSignatoryProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.UPDATETYPE,
            block.timestamp
        );
    }

    ///   Asset Protection Proposal   ///

    // create Asset Protection Proposal
    function createAssetProtectionProposal(
        address account_,
        string memory action_,
        uint256 amount_,
        uint256 expiration_
    )
        public
        onlyAssetProtectors
        notNullAddress(account_)
        onlyValidAction(action_)
        onlyGreaterThanZero(expiration_)
    {
        // increment asset protection proposal index
        ++_assetProtectionProposalIndex;

        // create asset protection proposal
        _assetProtectionProposals[
            _assetProtectionProposalIndex
        ] = AssetProtectionProposal({
            ID: _assetProtectionProposalIndex,
            PROPOSALNAME: action_,
            PROPOSER: msg.sender,
            ACCOUNT: account_,
            ACTION: action_,
            AMOUNT: amount_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the porposal by asset protector sender
        _assetProtectionProposalApprovers[_assetProtectionProposalIndex][
            msg.sender
        ] = true;

        // emit creating asset protection proposal event
        emit AssetProtectionProposalCreatedEvent(
            msg.sender,
            _assetProtectionProposalIndex,
            account_,
            amount_,
            action_,
            expiration_,
            block.timestamp
        );

        if (_assetProtectionSignatories.length == 1) {
            // action
            if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZE"))
            ) {
                // execute freeze account proposal
                _ERC20Contract().freezeAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("UNFREEZE"))
            ) {
                // execute unfreeze account proposal
                _ERC20Contract().unFreezeAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing unfreeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPEFREEZED"))
            ) {
                // execute wipe freezed account proposal
                _ERC20Contract().wipeFreezedAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPESPECIFICAMOUNTFREEZED"))
            ) {
                // execute wipe specific amount from freezed account proposal
                _ERC20Contract().wipeSpecificAmountFreezedAccount(
                    account_,
                    amount_
                );

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPE"))
            ) {
                // execute freeze and wipe account proposal
                _ERC20Contract().freezeAndWipeAccount(account_);

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPESPECIFICAMOUNT"))
            ) {
                // execute freeze and wipe specific amount from an account proposal
                _ERC20Contract().freezeAndWipeSpecificAmountAccount(
                    account_,
                    amount_
                );

                // update IS EXECUTED
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _assetProtectionProposals[_assetProtectionProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    account_,
                    action_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve Asset Protection Proposal
    function approveAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    )
        public
        onlyAssetProtectors
        onlyValidAssetProtectionIndex(assetProtectionProposalIndex_)
    {
        // asset protection proposal info
        AssetProtectionProposal storage proposal = _assetProtectionProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION <= block.timestamp ||
                _assetProtectionProposalApprovers[
                    assetProtectionProposalIndex_
                ][msg.sender]),
            "Asset Protection Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by asset protector sender
        _assetProtectionProposalApprovers[assetProtectionProposalIndex_][
            msg.sender
        ] = true;

        // update asset protection proposal approval count
        proposal.APPROVALCOUNT++;

        // emit asset protection proposal approved event
        emit ApproveAssetProtectionProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.ACCOUNT,
            proposal.ACTION,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (proposal.APPROVALCOUNT >= _minAssetProtectionSignatures) {
            // sender execute the proposal
            // action
            if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("FREEZE"))
            ) {
                // execute freeze account proposal
                _ERC20Contract().freezeAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("UNFREEZE"))
            ) {
                // execute unfreeze account proposal
                _ERC20Contract().unFreezeAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing unfreeze account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("WIPEFREEZED"))
            ) {
                // execute wipe freezed account proposal
                _ERC20Contract().wipeFreezedAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("WIPESPECIFICAMOUNTFREEZED"))
            ) {
                // execute wipe specific amount from a freezed account proposal
                _ERC20Contract().wipeSpecificAmountFreezedAccount(
                    proposal.ACCOUNT,
                    proposal.AMOUNT
                );

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing wipe freezed account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPE"))
            ) {
                // execute freeze and wipe account proposal
                _ERC20Contract().freezeAndWipeAccount(proposal.ACCOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.ACTION)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPESPECIFICAMOUNT"))
            ) {
                // execute freeze and wipe specific amount from an account proposal
                _ERC20Contract().freezeAndWipeSpecificAmountAccount(
                    proposal.ACCOUNT,
                    proposal.AMOUNT
                );

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing freeze and account proposal
                emit AssetProtectionProposalExecutedEvent(
                    msg.sender,
                    _assetProtectionProposalIndex,
                    proposal.ACCOUNT,
                    proposal.ACTION,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke Asset Protection Proposal
    function revokeAssetProtectionProposal(
        uint256 assetProtectionProposalIndex_
    ) public onlyAssetProtectors onlyProposer(assetProtectionProposalIndex_) {
        // asset protection proposal info
        AssetProtectionProposal storage proposal = _assetProtectionProposals[
            assetProtectionProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Asset Protection Multi-Sig: Proposal is already approved, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update EXECUTED TIMESTAMP
        proposal.EXECUTEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeAssetProtectionProposalEvent(
            msg.sender,
            assetProtectionProposalIndex_,
            proposal.ACCOUNT,
            proposal.ACTION,
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

    // get asset protection signatories
    function getAssetProtectionSignatories()
        public
        view
        returns (address[] memory)
    {
        return _assetProtectionSignatories;
    }

    // Is asset protection signatory
    function IsAssetProtectionSignatory(address account_)
        public
        view
        returns (bool)
    {
        return _isAssetProtectionSignatory[account_];
    }

    // get singatory proposal detail
    function getSignatoryProposalDetail(uint256 assetProtectionProposalIndex_)
        public
        view
        returns (SignatoryProposal memory)
    {
        return _signatoryProposals[assetProtectionProposalIndex_];
    }

    // is Signatory Proposal Approver
    function IsSignatoryProposalApprover(
        uint256 assetProtectionProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _signatoryProposalApprovers[assetProtectionProposalIndex_][
                account_
            ];
    }

    // get Min Asset Protection Singature
    function getAssetProtectionMinSignature() public view returns (uint256) {
        return _minAssetProtectionSignatures;
    }

    // get max asset protection index
    function getMaxAssetProtectionIndex() public view returns (uint256) {
        return _assetProtectionProposalIndex;
    }

    // get asset protection proposal detail
    function getAssetProtectionProposalDetail(
        uint256 assetProtectionProposalIndex_
    ) public view returns (AssetProtectionProposal memory) {
        return _assetProtectionProposals[assetProtectionProposalIndex_];
    }

    // is asset protection proposal apporver
    function IsAssetProtectionProposalApprover(
        uint256 assetProtectionProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _assetProtectionProposalApprovers[assetProtectionProposalIndex_][
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

    // only Asset Protection signatories
    function _onlyAssetProtectors() internal view {
        // require sender be an asset protector
        require(
            _isAssetProtectionSignatory[msg.sender],
            "Asset Protection Multi-Sig: Sender is not an Asset Protection Signatory!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Asset Protection Multi-Sig: Address should not be zero address!"
        );
    }

    // only valid actions
    function _onlyValidAction(string memory action_) internal pure {
        // require valid actions
        require(
            keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZE")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("UNFREEZE")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPESPECIFICAMOUNTFREEZED")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("WIPEFREEZED")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPE")) ||
                keccak256(abi.encodePacked(action_)) ==
                keccak256(abi.encodePacked("FREEZEANDWIPESPECIFICAMOUNT")),
            "Asset Protection Multi-Sig: Invalid Action!"
        );
    }

    // only valid adminProposalIndex
    function _onlyValidAssetProtectionIndex(
        uint256 assetProtectionProposalIndex_
    ) internal view {
        // require a valid admin proposal index ( != 0 and not more than max)
        require(
            (assetProtectionProposalIndex_ != 0 &&
                assetProtectionProposalIndex_ <= _assetProtectionProposalIndex),
            "Asset Protection Multi-Sig: Invalid proposal index!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal pure {
        // require value be greater than zero
        require(
            value_ > 0,
            "Asset Protection Multi-Sig: Value should be greater than zero!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 assetProtectionProposalIndex_)
        internal
        view
    {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _assetProtectionProposals[assetProtectionProposalIndex_]
                    .PROPOSER,
            "Asset Protection Multi-Sig: Sender is not the proposer!"
        );
    }

    // only valid signatory update type
    function _onlyValidUpdateType(string memory updateType_) internal pure {
        // require valid update type
        require(
            keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("ADD")) ||
                keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("REMOVE")),
            "Asset Protection Multi-Sig: Update type is not valid!"
        );
    }

    // only Admin Multi-Sig
    function _onlyAdmin() internal view {
        // require sender be Admin Multi-Sig
        require(
            msg.sender == _AdminMultiSigContractAddress,
            "Asset Protection Multi-Sig: Sender is not Admin Multi-Sig!"
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
            "Asset Protection Multi-Sig: Sender is not Address Book!"
        );
    }

    // get Address Book Contract Interface
    function _AddressBook() internal view returns (AddressBookInterface) {
        return
            AddressBookInterface(
                _AdminMultiSig.getAddressBookContractAddress()
            );
    }
}