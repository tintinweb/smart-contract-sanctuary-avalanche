/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ERC20 Interface
interface ERC20Interface {
    // creation basket
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    ) external returns (bool);

    // redemption basket
    function redemptionBasket(uint256 amount_, address senderAddress_)
        external
        returns (bool);
}

// Address Book Interface
interface AddressBookInterface {
    // Get ERC20 Contract Address
    function getERC20ContractAddress() external view returns (address);

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

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

    // get Supply Management Freeze status
    function getSupplyManagementFreezeStatus() external view returns (bool);
}

// Supply Management Multi-Sig Interface
interface SupplyManagementMultiSigInterface {
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

    // get Max Supply Management Proposal Index
    function getMaxSupplyManagementProposalIndex()
        external
        view
        returns (uint256);

    // IS Supply Management Proposal approver
    function IsSupplyManagementProposalApprover(
        uint256 supplyManagementProposalIndex_,
        address account_
    ) external view returns (bool);
}

// Supply Management Multi-Sig
contract SupplyManagementMultiSig is SupplyManagementMultiSigInterface {
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

    // Supply Management proposal counter
    uint256 private _supplyManagementProposalIndex = 0;

    // Supply Management Proposal struct
    struct SupplyManagementProposal {
        uint256 ID;
        string PROPOSALNAME;
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
    constructor(address AdminMultiSigContractAddress_) {
        // require non-zero address
        require(
            AdminMultiSigContractAddress_ != address(0),
            "Supply Management Multi-Sig: Admin Multi-Sig should not be zero-address!"
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
        _onlySupplyManagers();
        _;
    }

    // only Valid Supply Management Proposal Index
    modifier onlyValidSupplyManagementIndex(
        uint256 supplyManagementProposalIndex_
    ) {
        // require valid supply management proposal index
        _onlyValidSupplyManagementIndex(supplyManagementProposalIndex_);
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only Valid Order Type
    modifier onlyValidOrderType(string memory orderType) {
        // valid order types: CREATION or REDEMPTION
        _onlyValidOrderType(orderType);
        _;
    }

    // only Valid Payment Type
    modifier onlyValidPaymentType(string memory paymentType) {
        // valid payment types: ALREADY PAID, DEDUCT TOKEN
        _onlyValidPaymentType(paymentType);
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        _onlyGreaterThanZero(value_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 supplyManagementProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(supplyManagementProposalIndex_);
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

    // only unfreezed supply management
    modifier onlyUnfreezedSupplyManagement() {
        _onlyUnfreezedSupplyManagement();
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
        onlyUnfreezedSupplyManagement
    {
        // increment supply managment proposal index
        ++_supplyManagementProposalIndex;

        // create supply management proposal
        _supplyManagementProposals[
            _supplyManagementProposalIndex
        ] = SupplyManagementProposal({
            ID: _supplyManagementProposalIndex,
            PROPOSALNAME: string.concat(orderType_, " BASKET"),
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
                _ERC20Contract().creationBasket(
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
                _ERC20Contract().redemptionBasket(
                    orderSize_,
                    authorizedParticipant_
                );

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
        onlyUnfreezedSupplyManagement
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
            proposal.APPROVALCOUNT >=
            _AdminMultiSig.getSupplyManagementMinSignatures()
        ) {
            // sender execute the proposal
            // orderType
            if (
                keccak256(abi.encodePacked(proposal.ORDERTYPE)) ==
                keccak256(abi.encodePacked("CREATION"))
            ) {
                // execute creation order
                _ERC20Contract().creationBasket(
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
                _ERC20Contract().redemptionBasket(
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
    )
        public
        onlySupplyManagers
        onlyProposer(supplyManagementProposalIndex_)
        onlyUnfreezedSupplyManagement
    {
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

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

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

    // get ERC20 Contract Interface
    function _ERC20Contract() internal view returns (ERC20Interface) {
        return ERC20Interface(_AddressBook().getERC20ContractAddress());
    }

    // only Supply Management signatories
    function _onlySupplyManagers() internal view {
        // require sender be a supply manager
        require(
            _AdminMultiSig.IsSupplyManagementSignatory(msg.sender),
            "Supply Management Multi-Sig: Sender is not a Supply Manager Signatory!"
        );
    }

    // only Valid Supply Management Proposal Index
    function _onlyValidSupplyManagementIndex(
        uint256 supplyManagementProposalIndex_
    ) internal view {
        // require valid supply management proposal index
        require(
            supplyManagementProposalIndex_ <= _supplyManagementProposalIndex,
            "Supply Management Multi-Sig: Invalid Supply Management Proposal Index!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Supply Management Multi-Sig: Address should not be zero address!"
        );
    }

    // only Valid Order Type
    function _onlyValidOrderType(string memory orderType) internal pure {
        // valid order types: CREATION or REDEMPTION
        require(
            keccak256(abi.encodePacked(orderType)) ==
                keccak256(abi.encodePacked("CREATION")) ||
                keccak256(abi.encodePacked(orderType)) ==
                keccak256(abi.encodePacked("REDEMPTION")),
            "Supply Management Multi-Sig: Invalid Order Type!"
        );
    }

    // only Valid Payment Type
    function _onlyValidPaymentType(string memory paymentType) internal pure {
        // valid payment types: ALREADY PAID, DEDUCT TOKEN
        require(
            keccak256(abi.encodePacked(paymentType)) ==
                keccak256(abi.encodePacked("PAID")) ||
                keccak256(abi.encodePacked(paymentType)) ==
                keccak256(abi.encodePacked("DEDUCT")),
            "Supply Management Multi-Sig: Invalid Payment Type!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal pure {
        // require value be greater than zero
        require(
            value_ > 0,
            "Supply Management Multi-Sig: Value should be greater than zero!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 supplyManagementProposalIndex_)
        internal
        view
    {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _supplyManagementProposals[supplyManagementProposalIndex_]
                    .PROPOSER,
            "Supply Management Multi-Sig: Sender is not the proposer!"
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
            "Supply Management: Sender is not Address Book!"
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
    function _onlyUnfreezedSupplyManagement() internal view {
        // require false freeze status
        require(
            !AdminMultiSigInterface(_AdminMultiSigContractAddress)
                .getSupplyManagementFreezeStatus(),
            "Supply Management: Supply Management activities are freezed by Admin!"
        );
    }
}