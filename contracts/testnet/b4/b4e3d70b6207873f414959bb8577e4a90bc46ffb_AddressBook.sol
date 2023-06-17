/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ERC20 Interface
interface ERC20Interface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;
}

// Fee Management Interface
interface FeeManagementInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // is admin signatory
    function IsAdminSignatory(address account_) external view returns (bool);

    // get number of admin signatories
    function getNumberOfAdminSignatories() external view returns (uint256);
}

// Supply Management Multi-Sig Interface
interface SupplyManagementMultiSigInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;
}

// Fee Management Multi-Sig Interface
interface FeeManagementMultiSigInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;
}

// Asset Protection Multi-Sig Interface
interface AssetProtectionMultiSigInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;
}

// KYC Interface
interface KYCInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;
}

// KYC Multi-Sig Interface
interface KYCMultiSigInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;
}

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
    function getSupplyManagementMultiSigContractAddress() external view returns (address);

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

    // create update contract address proposal
    function createUpdateContractAddressProposal(
        string memory contractCategory_,
        address contractAddress_,
        uint256 expiration_
    ) external;

    // approve update contract address proposal
    function approveUpdateContractAddressProposal(uint256 proposalIndex_) external;

    // revoke proposed update contract address
    function revokeUpdateContractAddressProposal(uint256 proposalIndex_) external;
}

// Address Book contract
contract AddressBook is AddressBookInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // ERC20 Contract Address
    address private _ERC20ContractAddress;

    // Admin Multi-Sig Contract Address
    address private _AdminMultiSigContractAddress;

    // Supply Management Multi-Sig Contract Address
    address private _SupplyManagementMultiSigContractAddress;

    // Fee Management Contract Address
    address private _FeeManagementContractAddress;

    // Fee Management Multi-Sig Contract Address
    address private _FeeManagementMultiSigContractAddress;

    // Asset Protection Multi-Sig Contract Address
    address private _AssetProtectionMultiSigContractAddress;

    // KYC Compliance Contract Address
    address private _KYCContractAddress;

    // KYC Compliance Multi-Sig Contract Address
    address private _KYCMultiSigContractAddress;

    ///   Update Contract Address   ///

    uint256 private _proposalIndex = 0;

    // Update Contract Address Proposal struct
    struct UpdateContractAddressProposal {
        uint256 ID;
        address PROPOSER;
        string CONTRACTCATEGORY;
        address CONTRACTADDRESS;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of update contract address proposal info: admin proposal index => update contract address proposal detail
    mapping(uint256 => UpdateContractAddressProposal)
        private _updateContractAddressProposal;

    // update contract address proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _updateContractAddressApprovers;

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    // constructor
    constructor(address AdminMultiSigContractAddress_) {
        // require account not be the zero address
        require(
            AdminMultiSigContractAddress_ != address(0),
            "Address Book: Admin Multi-Sig can not be zero address!"
        );

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // emit event
        emit updateAdminMultiSigConractAddressEvent(
            msg.sender,
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
        address indexed executor,
        address previousERC20ContractAddress,
        address newERC20ContractAddress,
        uint256 indexed timestamp
    );

    // update Admin Multi-Sig Contract Address
    event updateAdminMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousAdminMultiSigContractAddress,
        address newAdminMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update Supply Management Multi-Sig Contract Address
    event updateSupplyManagementMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousSupplyManagementMultiSigContractAddress,
        address newSupplyManagementMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update Fee Management Contract Address
    event updateFeeManagementConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousFeeManagementContractAddress,
        address newFeeManagementContractAddress,
        uint256 indexed timestamp
    );

    // update Fee Management Multi-Sig Contract Address
    event updateFeeManagementMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousFeeManagementMultiSigContractAddress,
        address newFeeManagementMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update Asset Protection Multi-Sig Contract Address
    event updateAssetProtectionMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousAssetProtectionMultiSigContractAddress,
        address newAssetProtectionMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update KYC Contract Address
    event updateKYCConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousKYCContractAddress,
        address newKYCContractAddress,
        uint256 indexed timestamp
    );

    // update KYC Multi-Sig Contract Address
    event updateKYCMultiSigConractAddressEvent(
        address indexed AdminMultiSig,
        address indexed executor,
        address previousKYCMulitSigContractAddress,
        address newKYCMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // create update contract address proposal
    event UpdateContractAddressProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string contractCategory,
        address contractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute updating contract address proposal
    event UpdateContractAddressProposalExecutedEvent(
        address indexed executor,
        uint256 indexed adminProposalIndex,
        address previousContractAddress,
        string contractCategory,
        address contractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve update contract address proposal
    event ApproveUpdateContractAddressProposalEvent(
        address indexed approver,
        uint256 indexed adminProposalIndex,
        string contractCategory,
        address contractAddress,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // revoke updating contract address proposal
    event revokeUpdateContractAddressProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string contractCategory,
        address contractAddress,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Admin Signatories
    modifier onlyAdmins() {
        // require sender be the Admin Signatory Contract
        _onlyAdmins();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only valid contract category
    modifier onlyValidContractCategory(string memory contractCategory_) {
        // require valid contract category
        _onlyValidContractCategory(contractCategory_);
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        _onlyGreaterThanZero(value_);
        _;
    }

    // only valid adminProposalIndex
    modifier onlyValidAdminProposalIndex(uint256 adminProposalIndex_) {
        // require a valid admin proposal index ( != 0 and not more than max)
        _onlyValidAdminProposalIndex(adminProposalIndex_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 adminProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(adminProposalIndex_);
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // Update ERC20 Contract Address
    function updateERC20ContractAddress(
        address ERC20ContractAddress_,
        address executor_
    )
        public
        notNullAddress(ERC20ContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous ERC20 Contract Address
        address previousERC20ContractAddress = _ERC20ContractAddress;

        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            executor_,
            previousERC20ContractAddress,
            ERC20ContractAddress_,
            block.timestamp
        );
    }

    // Get ERC20 Contract Address
    function getERC20ContractAddress() public view returns (address) {
        return _ERC20ContractAddress;
    }

    // Update Admin Multi-Sig Contract Address
    function updateAdminMultiSigConractAddress(
        address AdminMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(AdminMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Admin Multi-Sig Contract Address
        address previousAdminMultiSigContractAddress = _AdminMultiSigContractAddress;

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // emit event
        emit updateAdminMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousAdminMultiSigContractAddress,
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() public view returns (address) {
        return _AdminMultiSigContractAddress;
    }

    // Update Supply Management Multi-Sig Contract Address
    function updateSupplyManagementMultiSigConractAddress(
        address SupplyManagementMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(SupplyManagementMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous SupplyManagement Multi-Sig Contract Address
        address previousSupplyManagementMultiSigContractAddress = _SupplyManagementMultiSigContractAddress;

        // update SupplyManagement Multi-Sig Contract Address
        _SupplyManagementMultiSigContractAddress = SupplyManagementMultiSigContractAddress_;

        // emit event
        emit updateSupplyManagementMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousSupplyManagementMultiSigContractAddress,
            SupplyManagementMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Supply Management Multi-Sig Contract Address
    function getSupplyManagementMultiSigContractAddress()
        public
        view
        returns (address)
    {
        return _SupplyManagementMultiSigContractAddress;
    }

    // Update Fee Management Contract Address
    function updateFeeManagementConractAddress(
        address FeeManagementContractAddress_,
        address executor_
    )
        public
        notNullAddress(FeeManagementContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Fee Management Contract Address
        address previousFeeManagementContractAddress = _FeeManagementContractAddress;

        // update Fee Management Contract Address
        _FeeManagementContractAddress = FeeManagementContractAddress_;

        // emit event
        emit updateFeeManagementConractAddressEvent(
            msg.sender,
            executor_,
            previousFeeManagementContractAddress,
            FeeManagementContractAddress_,
            block.timestamp
        );
    }

    // Get Fee Management Contract Address
    function getFeeManagementContractAddress() public view returns (address) {
        return _FeeManagementContractAddress;
    }

    // Update Fee Management Multi-Sig Contract Address
    function updateFeeManagementMultiSigConractAddress(
        address FeeManagementMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(FeeManagementMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Fee Management Multi-Sig Contract Address
        address previousFeeManagementMultiSigContractAddress = _FeeManagementMultiSigContractAddress;

        // update Fee Management Multi-Sig Contract Address
        _FeeManagementMultiSigContractAddress = FeeManagementMultiSigContractAddress_;

        // emit event
        emit updateFeeManagementMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousFeeManagementMultiSigContractAddress,
            FeeManagementMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Fee Management Multi-Sig Contract Address
    function getFeeManagementMultiSigContractAddress()
        public
        view
        returns (address)
    {
        return _FeeManagementMultiSigContractAddress;
    }

    // Update Asset Protection Multi-Sig Contract Address
    function updateAssetProtectionMultiSigConractAddress(
        address AssetProtectionMultiSigContractAddress_,
        address executor_
    )
        public
        notNullAddress(AssetProtectionMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous Asset Protectionn Multi-Sig Contract Address
        address previousAssetProtectionMultiSigContractAddress = _AssetProtectionMultiSigContractAddress;

        // update Asset Protection Multi-Sig Contract Address
        _AssetProtectionMultiSigContractAddress = AssetProtectionMultiSigContractAddress_;

        // emit event
        emit updateAssetProtectionMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousAssetProtectionMultiSigContractAddress,
            AssetProtectionMultiSigContractAddress_,
            block.timestamp
        );
    }

    // Get Asset Protection Multi-Sig Contract Address
    function getAssetProtectionMultiSigContractAddress()
        public
        view
        returns (address)
    {
        return _AssetProtectionMultiSigContractAddress;
    }

    // Get Address Book Contract Address
    function getAddressBookContractAddress() public view returns (address) {
        return address(this);
    }

    // update KYC Contract Address
    function updateKYCContractAddress(address KYCContractAddress_, address executor_)
        public
        notNullAddress(KYCContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous KYC Contract Address
        address previousKYCContractAddress = _KYCContractAddress;

        // update KYC Contract Address
        _KYCContractAddress = KYCContractAddress_;

        // emit event
        emit updateKYCConractAddressEvent(
            msg.sender,
            executor_,
            previousKYCContractAddress,
            KYCContractAddress_,
            block.timestamp
        );
    }

    // get KYC Contract Address
    function getKYCContractAddress() public view returns (address) {
        return _KYCContractAddress;
    }

    // update KYC Multi-Sig Contract Address
    function updateKYCMultiSigContractAddress(address KYCMultiSigContractAddress_, address executor_)
        public
        notNullAddress(KYCMultiSigContractAddress_)
        notNullAddress(executor_)
        onlyAdmins
    {
        // previous KYC Multi-Sig Contract Address
        address previousKYCMulitSigContractAddress = _KYCMultiSigContractAddress;

        // update KYC Multi-Sig Contract Address
        _KYCMultiSigContractAddress = KYCMultiSigContractAddress_;

        // emit event
        emit updateKYCMultiSigConractAddressEvent(
            msg.sender,
            executor_,
            previousKYCMulitSigContractAddress,
            KYCMultiSigContractAddress_,
            block.timestamp
        );
    }

    // get KYC Multi-Sig Contract Address
    function getKYCMultiSigContractAddress() public view returns(address) {
        return _KYCMultiSigContractAddress;
    }

    ///    Update Contract Addresses Proposals    ///

    // create update contract address proposal
    function createUpdateContractAddressProposal(
        string memory contractCategory_,
        address contractAddress_,
        uint256 expiration_
    )
        public
        onlyAdmins
        onlyValidContractCategory(contractCategory_)
        notNullAddress(contractAddress_)
        onlyGreaterThanZero(expiration_)
    {
        // check contract category
        if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ERC20"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _ERC20ContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _ERC20ContractAddress;

                // update contract address
                // update in Address book
                updateERC20ContractAddress(contractAddress_, msg.sender);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENT"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _FeeManagementContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementConractAddress(contractAddress_, msg.sender);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ADDRESSBOOK"))
        ) {
            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = address(this);

                // update contract address        

                // update in Admin Multi-Sig
                AdminMultiSigInterface(_AdminMultiSigContractAddress).updateAddressBookContractAddress(contractAddress_);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ADMINMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _AdminMultiSigContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _AdminMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAdminMultiSigConractAddress(contractAddress_, msg.sender);

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("SUPPLYMANAGEMENTMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _SupplyManagementMultiSigContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _SupplyManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateSupplyManagementMultiSigConractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENTMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _FeeManagementMultiSigContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementMultiSigConractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("ASSETPROTECTIONMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _AssetProtectionMultiSigContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _AssetProtectionMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAssetProtectionMultiSigConractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("KYCCONTRACTADDRESS"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _KYCContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _KYCContractAddress;

                // update contract address
                // update in Address book
                updateKYCContractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(contractCategory_)) ==
            keccak256(abi.encodePacked("KYCMULTISIG"))
        ) {
            // require contract address be different than current address
            require(
                contractAddress_ != _KYCMultiSigContractAddress,
                "Address Book: New contract address should be different from current contract address!"
            );

            // increment administration proposal ID
            ++_proposalIndex;

            // add proposal
            _updateContractAddressProposal[
                _proposalIndex
            ] = UpdateContractAddressProposal({
                ID: _proposalIndex,
                PROPOSER: msg.sender,
                CONTRACTCATEGORY: contractCategory_,
                CONTRACTADDRESS: contractAddress_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _updateContractAddressApprovers[_proposalIndex][msg.sender] = true;

            // emit create update contract address proposal event
            emit UpdateContractAddressProposalCreatedEvent(
                msg.sender,
                _proposalIndex,
                contractCategory_,
                contractAddress_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (
                AdminMultiSigInterface(_AdminMultiSigContractAddress)
                    .getNumberOfAdminSignatories() == 1
            ) {
                // previous contract address
                address previousContractAddress = _KYCMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateKYCMultiSigContractAddress(
                    contractAddress_,
                    msg.sender
                );

                // update is EXECUTED
                _updateContractAddressProposal[_proposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _updateContractAddressProposal[_proposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    contractCategory_,
                    contractAddress_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve update contract address proposal
    function approveUpdateContractAddressProposal(uint256 proposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(proposalIndex_)
    {
        // update contract address proposal info
        UpdateContractAddressProposal
            storage proposal = _updateContractAddressProposal[proposalIndex_];

        // require proposal not been EXECUTED, expired, revoked, or apprved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED ||
                _updateContractAddressApprovers[proposalIndex_][msg.sender]),
            "Address Book: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // update proposal approved by admin sender status
        _updateContractAddressApprovers[proposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        proposal.APPROVALCOUNT++;

        // emit approve update contract address proposal event
        emit ApproveUpdateContractAddressProposalEvent(
            msg.sender,
            _proposalIndex,
            proposal.CONTRACTCATEGORY,
            proposal.CONTRACTADDRESS,
            proposal.EXPIRATION,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (
            _updateContractAddressProposal[_proposalIndex].APPROVALCOUNT >=
            AdminMultiSigInterface(_AdminMultiSigContractAddress)
                .getNumberOfAdminSignatories()
        ) {
            // check contract category
            if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ERC20"))
            ) {
                // previous contract address
                address previousContractAddress = _ERC20ContractAddress;

                // update contract address
                // update in Address book
                updateERC20ContractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ADDRESSBOOK"))
            ) {
                // previous contract address
                address previousContractAddress = address(this);

                // update contract address
                // update in ERC20
                ERC20Interface(_ERC20ContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update in Fee Management
                FeeManagementInterface(_FeeManagementContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update in Admin Multi-Sig
                AdminMultiSigInterface(_AdminMultiSigContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);
                
                // update in Supply Management Multi-Sig
                SupplyManagementMultiSigInterface(_SupplyManagementMultiSigContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);
                
                // update in Fee Management Multi-Sig
                FeeManagementMultiSigInterface(_FeeManagementMultiSigContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update in Asset Protection Multi-Sig
                AssetProtectionMultiSigInterface(_AssetProtectionMultiSigContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update in KYC Contract
                KYCInterface(_KYCContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update in KYC Multi-Sig
                KYCMultiSigInterface(_KYCMultiSigContractAddress).updateAddressBookContractAddress(proposal.CONTRACTADDRESS);

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ADMINMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _AdminMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAdminMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENTMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _SupplyManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateSupplyManagementMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENTMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _FeeManagementMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateFeeManagementMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("ASSETPROTECTIONMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _AssetProtectionMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateAssetProtectionMultiSigConractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("KYCCONTRACTADDRESS"))
            ) {
                // previous contract address
                address previousContractAddress = _KYCContractAddress;

                // update contract address
                // update in Address book
                updateKYCContractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CONTRACTCATEGORY)) ==
                keccak256(abi.encodePacked("KYCMULTISIG"))
            ) {
                // previous contract address
                address previousContractAddress = _KYCMultiSigContractAddress;

                // update contract address
                // update in Address book
                updateKYCMultiSigContractAddress(
                    proposal.CONTRACTADDRESS,
                    msg.sender
                );

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing update contract address proposal
                emit UpdateContractAddressProposalExecutedEvent(
                    msg.sender,
                    _proposalIndex,
                    previousContractAddress,
                    proposal.CONTRACTCATEGORY,
                    proposal.CONTRACTADDRESS,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke proposed update contract address
    function revokeUpdateContractAddressProposal(uint256 proposalIndex_)
        public
        onlyAdmins
        onlyProposer(proposalIndex_)
        onlyValidAdminProposalIndex(proposalIndex_)
    {
        // proposal info
        UpdateContractAddressProposal
            storage proposal = _updateContractAddressProposal[proposalIndex_];

        // require proposal not been executed already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Address Book: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeUpdateContractAddressProposalEvent(
            msg.sender,
            proposalIndex_,
            proposal.CONTRACTCATEGORY,
            proposal.CONTRACTADDRESS,
            block.timestamp
        );
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // only Admin Signatories
    function _onlyAdmins() internal view {
        // require sender be the Admin Signatory Contract
        require(
            AdminMultiSigInterface(_AdminMultiSigContractAddress).IsAdminSignatory(msg.sender),
            "Address Book: Sender is not Admin Signatory!"
        );
    }

    // not Null Address
    function _notNullAddress(address account_) internal pure {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Address Book: Account can not be zero address!"
        );
    }

    // only valid contract category
    function _onlyValidContractCategory(string memory contractCategory_)
        internal
        view
        virtual
    {
        // require valid contract category
        require(
            keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ERC20")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ADDRESSBOOK")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ADMINMULTISIG")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENTMULTISIG")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENTMULTISIG")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("ASSETPROTECTIONMULTISIG"))  ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("KYCCONTRACTADDRESS")) ||
                keccak256(abi.encodePacked(contractCategory_)) ==
                keccak256(abi.encodePacked("KYCMULTISIG")),
            "Address Book: Contract category is not valid!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal view virtual {
        // require value be greater than zero
        require(
            value_ > 0,
            "Address Book: Value should be greater than zero!"
        );
    }

    // only valid admin proposal index
    function _onlyValidAdminProposalIndex(uint256 proposalIndex_)
        internal
        view
        virtual
    {
        // require a valid admin proposal index ( != 0 and not more than max)
        require(
            (proposalIndex_ != 0 && proposalIndex_ <= _proposalIndex),
            "Address Book: Invalid admin proposal index!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 proposalIndex_) internal view virtual {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _updateContractAddressProposal[proposalIndex_].PROPOSER,
            "Address Book: Sender is not the proposer!"
        );
    }
}