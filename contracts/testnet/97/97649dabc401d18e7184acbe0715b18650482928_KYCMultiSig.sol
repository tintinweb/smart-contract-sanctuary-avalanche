/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Address Book Interface
interface AddressBookInterface {
    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get KYC Contract Address
    function getKYCContractAddress() external view returns (address);
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // get kYC Signatories
    function getKYCSignatories() external view returns (address[] memory);

    // is KYC Signatory
    function IsKYCSignatory(address account_) external view returns (bool);

    // get KYC Min Signatures
    function getKYCMinSignatures() external view returns (uint256);
}

// KYC Interface
interface KYCInterface {
    // add addresses to the authorized addresses
    function authorizeAddresses(address[] memory accounts_) external;

    // remove addresses from mthe authorized addresses
    function unAuthorizeAddresses(address[] memory accounts_) external;
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
    function getProposalDetail(uint256 ProposalIndex_)
        external
        view
        returns (KYCProposal memory);

    // is  proposal approvers
    function IsProposalApprovers(uint256 ProposalIndex_, address account_)
        external
        view
        returns (bool);
}

// KYC Multi-Sig
contract KYCMultiSig is KYCMultiSigInterface {
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

    // KYC proposal counter
    uint256 private _ProposalIndex = 0;

    // list of KYC proposals info: proposal index => proposal detail
    mapping(uint256 => KYCProposal) private _KYCProposals;

    // kyc manager proposal approvers: proposal index => address => status
    mapping(uint256 => mapping(address => bool)) private _KYCProposalApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(address AdminMultiSigContractAddress_) {
        // require non-zero address
        require(
            AdminMultiSigContractAddress_ != address(0),
            "KYC Multi-Sig: Admin Multi-Sig should not be zero-address!"
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
        _onlyAdmin();
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) public onlyAdmin notNullAddress(AdminMultiSigContractAddress_) {
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
        _KYCProposals[_ProposalIndex] = KYCProposal({
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
        _KYCProposalApprovers[_ProposalIndex][msg.sender] = true;

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
        address[] memory _Signatories = _AdminMultiSig.getKYCSignatories();

        if (_Signatories.length == 1) {
            // category
            if (
                keccak256(abi.encodePacked(Category_)) ==
                keccak256(abi.encodePacked("AUTHORIZE"))
            ) {
                // execute authorize
                _KYCContract().authorizeAddresses(accounts_);

                // update IS EXECUTED
                _KYCProposals[_ProposalIndex].ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _KYCProposals[_ProposalIndex].EXECUTEDTIMESTAMP = block
                    .timestamp;

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
                _KYCContract().unAuthorizeAddresses(accounts_);

                // update IS EXECUTED
                _KYCProposals[_ProposalIndex].ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _KYCProposals[_ProposalIndex].EXECUTEDTIMESTAMP = block
                    .timestamp;

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
        KYCProposal storage proposal = _KYCProposals[ProposalIndex_];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION > block.timestamp ||
                _KYCProposalApprovers[ProposalIndex_][msg.sender]),
            "KYC Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by kyc manager sender
        _KYCProposalApprovers[ProposalIndex_][msg.sender] = true;

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
        if (proposal.APPROVALCOUNT >= _AdminMultiSig.getKYCMinSignatures()) {
            // sender execute the proposal
            // category
            if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("AUTHORIZE"))
            ) {
                // execute update creation fee order
                _KYCContract().authorizeAddresses(proposal.ACCOUNTS);

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
                _KYCContract().unAuthorizeAddresses(proposal.ACCOUNTS);

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
        KYCProposal storage proposal = _KYCProposals[ProposalIndex_];

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
        return _KYCProposalApprovers[ProposalIndex_][account_];
    }

    // get proposal detail
    function getProposalDetail(uint256 ProposalIndex_)
        external
        view
        returns (KYCProposal memory)
    {
        return _KYCProposals[ProposalIndex_];
    }

    // is  proposal approvers
    function IsProposalApprovers(uint256 ProposalIndex_, address account_)
        external
        view
        returns (bool)
    {
        return _KYCProposalApprovers[ProposalIndex_][account_];
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
            "KYC Multi-Sig: Address should not be zero address!"
        );
    }

    // not NUll Addresses
    function _notNullAddresses(address[] memory accounts_) internal pure {
        // require all accounts be not zero address
        for (uint256 i = 0; i < accounts_.length; i++) {
            require(
                accounts_[i] != address(0),
                "KYC Multi-Sig: Address zero is not allowed."
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
            "KYC Multi-Sig: Value should be greater than zero!"
        );
    }

    // only Valid Proposal Index
    function _onlyValidProposalIndex(uint256 ProposalIndex_) internal view {
        // require valid index
        require(
            ((ProposalIndex_ != 0) && (ProposalIndex_ <= _ProposalIndex)),
            "KYC Multi-Sig: Invalid proposal index!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 ProposalIndex_) internal view {
        // require sender be the proposer of the proposal
        require(
            msg.sender == _KYCProposals[ProposalIndex_].PROPOSER,
            "KYC Multi-Sig: Sender is not the proposer!"
        );
    }

    // get KYC Contract Interface
    function _KYCContract() internal view returns (KYCInterface) {
        return KYCInterface(_AddressBook().getKYCContractAddress());
    }

    // only Admin Multi-Sig
    function _onlyAdmin() internal view {
        // require sender be Admin Multi-Sig
        require(
            msg.sender == _AdminMultiSigContractAddress,
            "KYC: Sender is not Admin Multi-Sig!"
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