// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITalentLayerID} from "./interfaces/ITalentLayerID.sol";
import {ITalentLayerPlatformID} from "./interfaces/ITalentLayerPlatformID.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ServiceRegistry Contract
 * @author TalentLayer Team @ ETHCC22 Hackathon
 */
contract ServiceRegistry is AccessControl {
    // =========================== Enum ==============================

    /// @notice Enum service status
    enum Status {
        Filled,
        Confirmed,
        Finished,
        Rejected,
        Opened
    }

    /// @notice Enum service status
    enum ProposalStatus {
        Pending,
        Validated,
        Rejected
    }

    // =========================== Struct ==============================

    /// @notice Service information struct
    /// @param status the current status of a service
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param initiatorId the talentLayerId of the user who initialized the service
    /// @param serviceDataUri token Id to IPFS URI mapping
    /// @param proposals all proposals for this service
    /// @param countProposals the total number of proposal for this service
    /// @param transactionId the escrow transaction ID linked to the service
    /// @param platformId the platform ID linked to the service
    struct Service {
        Status status;
        uint256 buyerId;
        uint256 sellerId;
        uint256 initiatorId;
        string serviceDataUri;
        uint256 countProposals;
        uint256 transactionId;
        uint256 platformId;
    }

    /// @notice Proposal information struct
    /// @param status the current status of a service
    /// @param sellerId the talentLayerId of the seller
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    /// @param proposalDataUri token Id to IPFS URI mapping
    struct Proposal {
        ProposalStatus status;
        uint256 sellerId;
        address rateToken;
        uint256 rateAmount;
        string proposalDataUri;
    }

    // =========================== Events ==============================

    /// @notice Emitted after a new service is created
    /// @param id The service ID (incremental)
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param initiatorId the talentLayerId of the user who initialized the service
    /// @param platformId platform ID on which the Service token was minted
    /// @dev Events "ServiceCreated" & "ServiceDataCreated" are split to avoid "stack too deep" error
    event ServiceCreated(uint256 id, uint256 buyerId, uint256 sellerId, uint256 initiatorId, uint256 platformId);

    /// @notice Emitted after a new service is created
    /// @param id The service ID (incremental)
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceDataCreated(uint256 id, string serviceDataUri);

    /// @notice Emitted after an seller is assigned to a service
    /// @param id The service ID
    /// @param sellerId the talentLayerId of the seller
    /// @param status service status
    event ServiceSellerAssigned(uint256 id, uint256 sellerId, Status status);

    /// @notice Emitted after a service is confirmed
    /// @param id The service ID
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceConfirmed(uint256 id, uint256 buyerId, uint256 sellerId, string serviceDataUri);

    /// @notice Emitted after a service is rejected
    /// @param id The service ID
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceRejected(uint256 id, uint256 buyerId, uint256 sellerId, string serviceDataUri);

    /// @notice Emitted after a service is finished
    /// @param id The service ID
    /// @param buyerId the talentLayerId of the buyer
    /// @param sellerId the talentLayerId of the seller
    /// @param serviceDataUri token Id to IPFS URI mapping
    event ServiceFinished(uint256 id, uint256 buyerId, uint256 sellerId, string serviceDataUri);

    /**
     * Emit when Cid is updated for a Service
     * @param id The service ID
     * @param newServiceDataUri New service Data URI
     */
    event ServiceDetailedUpdated(uint256 indexed id, string newServiceDataUri);

    /// @notice Emitted after a new proposal is created
    /// @param serviceId The service id
    /// @param sellerId The talentLayerId of the seller who made the proposal
    /// @param proposalDataUri token Id to IPFS URI mapping
    /// @param status proposal status
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    event ProposalCreated(
        uint256 serviceId,
        uint256 sellerId,
        string proposalDataUri,
        ProposalStatus status,
        address rateToken,
        uint256 rateAmount
    );

    /// @notice Emitted after an existing proposal has been updated
    /// @param serviceId The service id
    /// @param sellerId The talentLayerId of the seller who made the proposal
    /// @param proposalDataUri token Id to IPFS URI mapping
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    event ProposalUpdated(
        uint256 serviceId,
        uint256 sellerId,
        string proposalDataUri,
        address rateToken,
        uint256 rateAmount
    );

    /// @notice Emitted after a proposal is validated
    /// @param serviceId The service ID
    /// @param sellerId the talentLayerId of the seller
    event ProposalValidated(uint256 serviceId, uint256 sellerId);

    /// @notice Emitted after a proposal is rejected
    /// @param serviceId The service ID
    /// @param sellerId the talentLayerId of the seller
    event ProposalRejected(uint256 serviceId, uint256 sellerId);

    /// @notice incremental service Id
    uint256 public nextServiceId = 1;

    /// @notice TalentLayerId address
    ITalentLayerID private tlId;

    /// TalentLayer Platform ID registry
    ITalentLayerPlatformID public talentLayerPlatformIdContract;

    /// @notice services mappings index by ID
    mapping(uint256 => Service) public services;

    /// @notice proposals mappings index by service ID and seller TID
    mapping(uint256 => mapping(uint256 => Proposal)) public proposals;

    // @notice
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");

    /**
     * @param _talentLayerIdAddress TalentLayerId address
     */
    constructor(address _talentLayerIdAddress, address _talentLayerPlatformIdAddress) {
        tlId = ITalentLayerID(_talentLayerIdAddress);
        talentLayerPlatformIdContract = ITalentLayerPlatformID(_talentLayerPlatformIdAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================

    /**
     * @notice Return the whole service data information
     * @param _serviceId Service identifier
     */
    function getService(uint256 _serviceId) external view returns (Service memory) {
        require(_serviceId < nextServiceId, "This service doesn't exist");
        return services[_serviceId];
    }

    function getProposal(uint256 _serviceId, uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_serviceId][_proposalId];
    }

    // =========================== User functions ==============================

    /**
     * @notice Allows an buyer to initiate a new Service with an seller
     * @param _platformId platform ID on which the Service token was minted
     * @param _sellerId Handle for the user
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function createServiceFromBuyer(
        uint256 _platformId,
        uint256 _sellerId,
        string calldata _serviceDataUri
    ) public returns (uint256) {
        talentLayerPlatformIdContract.isValid(_platformId);
        tlId.isValid(_sellerId);
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createService(Status.Filled, senderId, senderId, _sellerId, _serviceDataUri, _platformId);
    }

    /**
     * @notice Allows an seller to initiate a new Service with an buyer
     * @param _platformId platform ID on which the Service token was minted
     * @param _buyerId Handle for the user
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function createServiceFromSeller(
        uint256 _platformId,
        uint256 _buyerId,
        string calldata _serviceDataUri
    ) public returns (uint256) {
        talentLayerPlatformIdContract.isValid(_platformId);
        tlId.isValid(_buyerId);
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createService(Status.Filled, senderId, _buyerId, senderId, _serviceDataUri, _platformId);
    }

    /**
     * @notice Allows an buyer to initiate an open service
     * @param _platformId platform ID on which the Service token was minted
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function createOpenServiceFromBuyer(uint256 _platformId, string calldata _serviceDataUri) public returns (uint256) {
        talentLayerPlatformIdContract.isValid(_platformId);
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createService(Status.Opened, senderId, senderId, 0, _serviceDataUri, _platformId);
    }

    /**
     * @notice Allows an seller to propose his service for a service
     * @param _serviceId The service linked to the new proposal
     * @param _rateToken the token choose for the payment
     * @param _rateAmount the amount of token choosed
     * @param _proposalDataUri token Id to IPFS URI mapping
     */
    function createProposal(
        uint256 _serviceId,
        address _rateToken,
        uint256 _rateAmount,
        string calldata _proposalDataUri
    ) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        require(service.status == Status.Opened, "Service is not opened");
        require(
            proposals[_serviceId][senderId].sellerId != senderId,
            "You already created a proposal for this service"
        );
        require(service.countProposals < 40, "Max proposals count reached");
        require(service.buyerId != senderId, "You couldn't create proposal for your own service");
        require(bytes(_proposalDataUri).length > 0, "Should provide a valid IPFS URI");

        service.countProposals++;
        proposals[_serviceId][senderId] = Proposal({
            status: ProposalStatus.Pending,
            sellerId: senderId,
            rateToken: _rateToken,
            rateAmount: _rateAmount,
            proposalDataUri: _proposalDataUri
        });

        emit ProposalCreated(_serviceId, senderId, _proposalDataUri, ProposalStatus.Pending, _rateToken, _rateAmount);
    }

    /**
     * @notice Allows an seller to update his own proposal for a given service
     * @param _serviceId The service linked to the new proposal
     * @param _rateToken the token choose for the payment
     * @param _rateAmount the amount of token choosed
     * @param _proposalDataUri token Id to IPFS URI mapping
     */
    function updateProposal(
        uint256 _serviceId,
        address _rateToken,
        uint256 _rateAmount,
        string calldata _proposalDataUri
    ) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][senderId];
        require(service.status == Status.Opened, "Service is not opened");
        require(proposal.sellerId == senderId, "This proposal doesn't exist yet");
        require(bytes(_proposalDataUri).length > 0, "Should provide a valid IPFS URI");
        require(proposal.status != ProposalStatus.Validated, "This proposal is already updated");

        proposal.rateToken = _rateToken;
        proposal.rateAmount = _rateAmount;
        proposal.proposalDataUri = _proposalDataUri;

        emit ProposalUpdated(_serviceId, senderId, _proposalDataUri, _rateToken, _rateAmount);
    }

    /**
     * @notice Allows the buyer to validate a proposal
     * @param _serviceId Service identifier
     * @param _proposalId Proposal identifier
     */
    function validateProposal(uint256 _serviceId, uint256 _proposalId) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][_proposalId];

        require(proposal.status != ProposalStatus.Validated, "Proposal has already been validated");
        require(senderId == service.buyerId, "You're not the buyer");

        proposal.status = ProposalStatus.Validated;

        emit ProposalValidated(_serviceId, _proposalId);
    }

    /**
     * @notice Allows the buyer to reject a proposal
     * @param _serviceId Service identifier
     * @param _proposalId Proposal identifier
     */
    function rejectProposal(uint256 _serviceId, uint256 _proposalId) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You should have a TalentLayerId");

        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][_proposalId];

        require(proposal.status != ProposalStatus.Validated, "Proposal has already been validated");

        require(proposal.status != ProposalStatus.Rejected, "Proposal has already been rejected");

        require(senderId == service.buyerId, "You're not the buyer");

        proposal.status = ProposalStatus.Rejected;

        emit ProposalRejected(_serviceId, _proposalId);
    }

    /**
     * @notice Allows the user who didn't initiate the service to confirm it. They now consent both to be reviewed each other at the end of service.
     * @param _serviceId Service identifier
     */
    function confirmService(uint256 _serviceId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);

        require(service.status == Status.Filled, "Service has already been confirmed");
        require(senderId == service.buyerId || senderId == service.sellerId, "You're not an actor of this service");
        require(senderId != service.initiatorId, "Only the user who didn't initate the service can confirm it");

        service.status = Status.Confirmed;

        emit ServiceConfirmed(_serviceId, service.buyerId, service.sellerId, service.serviceDataUri);
    }

    /**
     * @notice Allow the escrow contract to upgrade the Service state after a deposit has been done
     * @param _serviceId Service identifier
     * @param _proposalId The choosed proposal id for this service
     * @param _transactionId The escrow transaction Id
     */
    function afterDeposit(
        uint256 _serviceId,
        uint256 _proposalId,
        uint256 _transactionId
    ) external onlyRole(ESCROW_ROLE) {
        Service storage service = services[_serviceId];
        Proposal storage proposal = proposals[_serviceId][_proposalId];

        service.status = Status.Confirmed;
        service.sellerId = proposal.sellerId;
        service.transactionId = _transactionId;
        proposal.status = ProposalStatus.Validated;
    }

    /**
     * @notice Allow the escrow contract to upgrade the Service state after the full payment has been received by the seller
     * @param _serviceId Service identifier
     */
    function afterFullPayment(uint256 _serviceId) external onlyRole(ESCROW_ROLE) {
        Service storage service = services[_serviceId];
        service.status = Status.Finished;
    }

    /**
     * @notice Allows the user who didn't initiate the service to reject it
     * @param _serviceId Service identifier
     */
    function rejectService(uint256 _serviceId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId == service.buyerId || senderId == service.sellerId, "You're not an actor of this service");
        require(service.status == Status.Filled || service.status == Status.Opened, "You can't reject this service");
        service.status = Status.Rejected;

        emit ServiceRejected(_serviceId, service.buyerId, service.sellerId, service.serviceDataUri);
    }

    /**
     * @notice Allows any part of a service to update his state to finished
     * @param _serviceId Service identifier
     */
    function finishService(uint256 _serviceId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId == service.buyerId || senderId == service.sellerId, "You're not an actor of this service");
        require(service.status == Status.Confirmed, "You can't finish this service");
        service.status = Status.Finished;

        emit ServiceFinished(_serviceId, service.buyerId, service.sellerId, service.serviceDataUri);
    }

    /**
     * @notice Allows the buyer to assign an seller to the service
     * @param _serviceId Service identifier
     * @param _sellerId Handle for the user
     */
    function assignSellerToService(uint256 _serviceId, uint256 _sellerId) public {
        Service storage service = services[_serviceId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        tlId.isValid(_sellerId);

        require(
            service.status == Status.Opened || service.status == Status.Rejected,
            "Service has to be Opened or Rejected"
        );

        require(senderId == service.buyerId, "You're not an buyer of this service");

        require(_sellerId != service.buyerId, "Seller and buyer can't be the same");

        service.sellerId = _sellerId;
        service.status = Status.Filled;

        emit ServiceSellerAssigned(_serviceId, _sellerId, service.status);
    }

    /**
     * Update Service URI data
     * @param _serviceId, Service ID to update
     * @param _newServiceDataUri New IPFS URI
     */
    function updateServiceData(uint256 _serviceId, string calldata _newServiceDataUri) public {
        Service storage service = services[_serviceId];
        require(_serviceId < nextServiceId, "This service doesn't exist");
        require(
            service.status == Status.Opened || service.status == Status.Filled,
            "Service status should be opened or filled"
        );
        require(service.initiatorId == tlId.walletOfOwner(msg.sender), "Only the initiator can update the service");
        require(bytes(_newServiceDataUri).length > 0, "Should provide a valid IPFS URI");

        service.serviceDataUri = _newServiceDataUri;

        emit ServiceDetailedUpdated(_serviceId, _newServiceDataUri);
    }

    // =========================== Private functions ==============================

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _senderId the talentLayerId of the msg.sender address
     * @param _buyerId the talentLayerId of the buyer
     * @param _sellerId the talentLayerId of the seller
     * @param _serviceDataUri token Id to IPFS URI mapping
     */
    function _createService(
        Status _status,
        uint256 _senderId,
        uint256 _buyerId,
        uint256 _sellerId,
        string calldata _serviceDataUri,
        uint256 _platformId
    ) private returns (uint256) {
        require(_senderId > 0, "You should have a TalentLayerId");
        require(_sellerId != _buyerId, "Seller and buyer can't be the same");
        require(bytes(_serviceDataUri).length > 0, "Should provide a valid IPFS URI");

        uint256 id = nextServiceId;
        nextServiceId++;

        Service storage service = services[id];
        service.status = _status;
        service.buyerId = _buyerId;
        service.sellerId = _sellerId;
        service.initiatorId = _senderId;
        service.serviceDataUri = _serviceDataUri;
        service.platformId = _platformId;

        emit ServiceCreated(id, _buyerId, _sellerId, _senderId, _platformId);

        emit ServiceDataCreated(id, _serviceDataUri);

        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITalentLayerID {
    struct Profile {
        uint256 id;
        string handle;
        address pohAddress;
        uint256 platformId;
        string dataUri;
    }

    function numberMinted(address _user) external view returns (uint256);

    function isTokenPohRegistered(uint256 _tokenId) external view returns (bool);

    function walletOfOwner(address _owner) external view returns (uint256);

    function mint(string memory _handle) external;

    function mintWithPoh(string memory _handle) external;

    function activatePoh(uint256 _tokenId) external;

    function updateProfileData(uint256 _tokenId, string memory _newCid) external;

    function recoverAccount(
        address _oldAddress,
        uint256 _tokenId,
        uint256 _index,
        uint256 _recoveryKey,
        string calldata _handle,
        bytes32[] calldata _merkleProof
    ) external;

    function isValid(uint256 _tokenId) external view;

    function setBaseURI(string memory _newBaseURI) external;

    function getProfile(uint256 _profileId) external view returns (Profile memory);

    function updateRecoveryRoot(bytes32 _newRoot) external;

    function _afterMint(string memory _handle) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function getOriginatorPlatformIdByAddress(address _address) external view returns (uint256);

    event Mint(address indexed _user, uint256 _tokenId, string _handle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721A} from "../libs/IERC721A.sol";

/**
 * @title Platform ID Interface
 * @author TalentLayer Team
 */
interface ITalentLayerPlatformID is IERC721A {
    function numberMinted(address _platformAddress) external view returns (uint256);

    function getPlatformFee(uint256 _platformId) external view returns (uint16);

    function getPlatformIdFromAddress(address _owner) external view returns (uint256);

    function mint(string memory _platformName) external;

    function updateProfileData(uint256 _platformId, string memory _newCid) external;

    function updateRecoveryRoot(bytes32 _newRoot) external;

    function isValid(uint256 _platformId) external view;

    event Mint(address indexed _platformOwnerAddress, uint256 _tokenId, string _platformName);

    event CidUpdated(uint256 indexed _tokenId, string _newCid);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}