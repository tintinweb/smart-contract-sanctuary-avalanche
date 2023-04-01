/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-31
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/interface/IERC734.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/**
 * @dev interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {

    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execute operation was called and failed
     *
     * Specification: MUST be triggered when execute call failed
     */
    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity
     * itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution.
    *
    * Triggers Event: `Approved`
    * Triggers on execution successful Event: `Executed`
    * Triggers on execution failure Event: `ExecutionFailed`
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself.
     * If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC734 identity.
     * How the execution is handled is up to the identity implementation:
     * An execution COULD be requested and require `approve` to be called with one or more keys of purpose 1 or 2 to
     * approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     *
     * Triggers Event: ExecutionRequested
     * Triggers on direct execution Event: Executed
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);
}


// File contracts/interface/IERC735.sol

/**
 * @dev interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when addClaim was successfully called on an existing claimId.
     */
    event ClaimChanged(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Add or update a claim from an issuer.
     *
     * _signature is a signed message of the following structure:
     * `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     */
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address issuer,
        bytes calldata _signature,
        bytes calldata _data,
        string calldata _uri)
    external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId)
    external view returns(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);
}


// File contracts/interface/IIdentity.sol


// solhint-disable-next-line no-empty-blocks
interface IIdentity is IERC734, IERC735 {}


// File contracts/interface/IClaimIssuer.sol


interface IClaimIssuer is IIdentity {

    /**
     * @dev Emitted when a claim is revoked.
     *
     * Specification: MUST be triggered when revoking a claim.
     */
    event ClaimRevoked(bytes indexed signature);

    /**
     * @dev Revoke a claim previously issued, the claim is no longer considered as valid after revocation.
     * @notice will fetch the claim from the identity contract (unsafe).
     * @param _claimId the id of the claim
     * @param _identity the address of the identity contract
     * @return isRevoked true when the claim is revoked
     */
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);

    /**
     * @dev Revoke a claim previously issued, the claim is no longer considered as valid after revocation.
     * @param signature the signature of the claim
     */
    function revokeClaimBySignature(bytes calldata signature) external;

    /**
     * @dev Returns revocation status of a claim.
     * @param _sig the signature of the claim
     * @return isRevoked true if the claim is revoked and false otherwise
     */
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);

    /**
     * @dev Checks if a claim is valid.
     * @param _identity the identity contract related to the claim
     * @param claimTopic the claim topic of the claim
     * @param sig the signature of the claim
     * @param data the data field of the claim
     * @return claimValid true if the claim is valid, false otherwise
     */
    function isClaimValid(
        IIdentity _identity,
        uint256 claimTopic,
        bytes calldata sig,
        bytes calldata data)
    external view returns (bool);

    /**
     * @dev returns the address that signed the given data
     * @param sig the signature of the data
     * @param dataHash the data that was signed
     * returns the address that signed dataHash and created the signature sig
     */
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
}


// File contracts/storage/Structs.sol


contract Structs {

   /**
    *  @dev Definition of the structure of a Key.
    *
    *  Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
    *  The structure should be as follows:
    *  key: A public key owned by this identity
    *  purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
    *  keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    *  key: bytes32 The public key. // Its the Keccak256 hash of the key
    */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    /**
    *  @dev Definition of the structure of an Execution
    *
    *  Specification: Executions are requests for transactions to be issued by the ONCHAINID
    *  to: address of contract to interact with, can be address(this)
    *  value: ETH to transfer with the transaction
    *  data: payload of the transaction to execute
    *  approved: approval status of the Execution
    *  executed: execution status of the Execution (set as false when the Execution is created
    *  and updated to true when the Execution is processed)
    */
    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

   /**
    *  @dev Definition of the structure of a Claim.
    *
    *  Specification: Claims are information an issuer has about the identity holder.
    *  The structure should be as follows:
    *  claim: A claim published for the Identity.
    *  topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined:
    *  number schemes, sub topics based on number ranges??))
    *  scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for
    *  different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a
    *  contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc.
    *  (ToBeDefined)
    *  issuer: The issuers identity contract address, or the address used to sign the above signature. If an
    *  identity contract, it should hold the key with which the above message was signed, if the key is not present
    *  anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the
    *  claim can be verified using the call data.
    *  signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it
    *  MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
    *  data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on
    *  the claim scheme.
    *  uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }
}


// File contracts/storage/Storage.sol


contract Storage is Structs {
    // nonce used by the execute/approve function
    uint256 internal _executionNonce;

    // keys as defined by IERC734
    mapping(bytes32 => Key) internal _keys;

    // keys for a given purpose
    // purpose 1 = MANAGEMENT
    // purpose 2 = ACTION
    // purpose 3 = CLAIM
    mapping(uint256 => bytes32[]) internal _keysByPurpose;

    // execution data
    mapping(uint256 => Execution) internal _executions;

    // claims held by the ONCHAINID
    mapping(bytes32 => Claim) internal _claims;

    // array of claims for a given topic
    mapping(uint256 => bytes32[]) internal _claimsByTopic;

    // status on initialization
    bool internal _initialized = false;

    // status on potential interactions with the contract
    bool internal _canInteract = false;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[49] private __gap;
}


// File contracts/version/Version.sol

/**
 * @dev Version contract gives the versioning information of the implementation contract
 */
contract Version {
    /**
     * @dev Returns the string of the current version.
     */
    function version() external pure returns (string memory) {
        // version 2.0.0
        return "2.0.0";
    }
}


// File contracts/Identity.sol

/**
 * @dev Implementation of the `IERC734` "KeyHolder" and the `IERC735` "ClaimHolder" interfaces
 * into a common Identity Contract.
 * This implementation has a separate contract were it declares all storage,
 * allowing for it to be used as an upgradable logic contract.
 */
contract Identity is Storage, IIdentity, Version {

    /**
     * @notice Prevent any direct calls to the implementation contract (marked by _canInteract = false).
     */
    modifier delegatedOnly() {
        require(_canInteract == true, "Interacting with the library contract is forbidden.");
        _;
    }

    /**
     * @notice requires management key to call this function, or internal call
     */
    modifier onlyManager() {
        require(msg.sender == address(this) || keyHasPurpose(keccak256(abi.encode(msg.sender)), 1)
        , "Permissions: Sender does not have management key");
        _;
    }

    /**
     * @notice requires claim key to call this function, or internal call
     */
    modifier onlyClaimKey() {
        require(msg.sender == address(this) || keyHasPurpose(keccak256(abi.encode(msg.sender)), 3)
        , "Permissions: Sender does not have claim signer key");
        _;
    }

    /**
     * @notice constructor of the Identity contract
     * @param initialManagementKey the address of the management key at deployment
     * @param _isLibrary boolean value stating if the contract is library or not
     * calls __Identity_init if contract is not library
     */
    constructor(address initialManagementKey, bool _isLibrary) {
        require(initialManagementKey != address(0), "invalid argument - zero address");

        if (!_isLibrary) {
            __Identity_init(initialManagementKey);
        } else {
            _initialized = true;
        }
    }

    /**
     * @notice When using this contract as an implementation for a proxy, call this initializer with a delegatecall.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the ONCHAINID.
     */
    function initialize(address initialManagementKey) external {
        require(initialManagementKey != address(0), "invalid argument - zero address");
        __Identity_init(initialManagementKey);
    }

    /**
     * @dev See {IERC734-execute}.
     * @notice Passes an execution instruction to the keymanager.
     * If the sender is an ACTION key and the destination address is not the identity contract itself, then the
     * execution is immediately approved and performed.
     * If the destination address is the identity itself, then the execution would be performed immediately only if
     * the sender is a MANAGEMENT key.
     * Otherwise the execution request must be approved via the `approve` method.
     * @return executionId to use in the approve function, to approve or reject this execution.
     */
    function execute(address _to, uint256 _value, bytes memory _data)
    external
    delegatedOnly
    override
    payable
    returns (uint256 executionId)
    {
        uint256 _executionId = _executionNonce;
        _executions[_executionId].to = _to;
        _executions[_executionId].value = _value;
        _executions[_executionId].data = _data;
        _executionNonce++;

        emit ExecutionRequested(_executionId, _to, _value, _data);

        if (keyHasPurpose(keccak256(abi.encode(msg.sender)), 1)) {
            approve(_executionId, true);
        }
        else if (_to != address(this) && keyHasPurpose(keccak256(abi.encode(msg.sender)), 2)){
            approve(_executionId, true);
        }

        return _executionId;
    }

    /**
     * @dev See {IERC734-getKey}.
     * @notice Implementation of the getKey function from the ERC-734 standard
     * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
     * @return purposes Returns the full key data, if present in the identity.
     * @return keyType Returns the full key data, if present in the identity.
     * @return key Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key)
    external
    override
    view
    returns(uint256[] memory purposes, uint256 keyType, bytes32 key)
    {
        return (_keys[_key].purposes, _keys[_key].keyType, _keys[_key].key);
    }

    /**
    * @dev See {IERC734-getKeyPurposes}.
    * @notice gets the purposes of a key
    * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
    * @return _purposes Returns the purposes of the specified key
    */
    function getKeyPurposes(bytes32 _key)
    external
    override
    view
    returns(uint256[] memory _purposes)
    {
        return (_keys[_key].purposes);
    }

    /**
    * @dev See {IERC734-getKeysByPurpose}.
    * @notice gets all the keys with a specific purpose from an identity
    * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    * @return keys Returns an array of public key bytes32 hold by this identity and having the specified purpose
    */
    function getKeysByPurpose(uint256 _purpose)
    external
    override
    view
    returns(bytes32[] memory keys)
    {
        return _keysByPurpose[_purpose];
    }

    /**
    * @dev See {IERC735-getClaimIdsByTopic}.
    * @notice Implementation of the getClaimIdsByTopic function from the ERC-735 standard.
    * used to get all the claims from the specified topic
    * @param _topic The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
    * @return claimIds Returns an array of claim IDs by topic.
    */
    function getClaimIdsByTopic(uint256 _topic)
    external
    override
    view
    returns(bytes32[] memory claimIds)
    {
        return _claimsByTopic[_topic];
    }

    /**
    * @notice implementation of the addKey function of the ERC-734 standard
    * Adds a _key to the identity. The _purpose specifies the purpose of key. Initially we propose four purposes:
    * 1: MANAGEMENT keys, which can manage the identity
    * 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
    * 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
    * 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
    * MUST only be done by keys of purpose 1, or the identity itself.
    * If its the identity itself, the approval process will determine its approval.
    * @param _key keccak256 representation of an ethereum address
    * @param _type type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    * @param _purpose a uint256 specifying the key type, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    * @return success Returns TRUE if the addition was successful and FALSE if not
    */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
    public
    delegatedOnly
    onlyManager
    override
    returns (bool success)
    {
        if (_keys[_key].key == _key) {
            uint256[] memory _purposes = _keys[_key].purposes;
            for (uint keyPurposeIndex = 0; keyPurposeIndex < _purposes.length; keyPurposeIndex++) {
                uint256 purpose = _purposes[keyPurposeIndex];

                if (purpose == _purpose) {
                    revert("Conflict: Key already has purpose");
                }
            }

            _keys[_key].purposes.push(_purpose);
        } else {
            _keys[_key].key = _key;
            _keys[_key].purposes = [_purpose];
            _keys[_key].keyType = _type;
        }

        _keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    /**
     *  @dev See {IERC734-approve}.
     *  @notice Approves an execution.
     *  If the sender is an ACTION key and the destination address is not the identity contract itself, then the
     *  approval is authorized and the operation would be performed.
     *  If the destination address is the identity itself, then the execution would be authorized and performed only
     *  if the sender is a MANAGEMENT key.
     */
    function approve(uint256 _id, bool _approve)
    public
    delegatedOnly
    override
    returns (bool success)
    {
        require(_id < _executionNonce, "Cannot approve a non-existing execution");
        require(!_executions[_id].executed, "Request already executed");

        if(_executions[_id].to == address(this)) {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 1), "Sender does not have management key");
        }
        else {
            require(keyHasPurpose(keccak256(abi.encode(msg.sender)), 2), "Sender does not have action key");
        }

        emit Approved(_id, _approve);

        if (_approve == true) {
            _executions[_id].approved = true;

            // solhint-disable-next-line avoid-low-level-calls
            (success,) = _executions[_id].to.call{value:(_executions[_id].value)}(_executions[_id].data);

            if (success) {
                _executions[_id].executed = true;

                emit Executed(
                    _id,
                    _executions[_id].to,
                    _executions[_id].value,
                    _executions[_id].data
                );

                return true;
            } else {
                emit ExecutionFailed(
                    _id,
                    _executions[_id].to,
                    _executions[_id].value,
                    _executions[_id].data
                );

                return false;
            }
        } else {
            _executions[_id].approved = false;
        }
        return false;
    }

    /**
    * @dev See {IERC734-removeKey}.
    * @notice Remove the purpose from a key.
    */
    function removeKey(bytes32 _key, uint256 _purpose)
    public
    delegatedOnly
    onlyManager
    override
    returns (bool success)
    {
        require(_keys[_key].key == _key, "NonExisting: Key isn't registered");
        uint256[] memory _purposes = _keys[_key].purposes;

        uint purposeIndex = 0;
        while (_purposes[purposeIndex] != _purpose) {
            purposeIndex++;

            if (purposeIndex == _purposes.length) {
                revert("NonExisting: Key doesn't have such purpose");
            }
        }

        _purposes[purposeIndex] = _purposes[_purposes.length - 1];
        _keys[_key].purposes = _purposes;
        _keys[_key].purposes.pop();

        uint keyIndex = 0;
        uint arrayLength = _keysByPurpose[_purpose].length;

        while (_keysByPurpose[_purpose][keyIndex] != _key) {
            keyIndex++;

            if (keyIndex >= arrayLength) {
                break;
            }
        }

        _keysByPurpose[_purpose][keyIndex] = _keysByPurpose[_purpose][arrayLength - 1];
        _keysByPurpose[_purpose].pop();

        uint keyType = _keys[_key].keyType;

        if (_purposes.length - 1 == 0) {
            delete _keys[_key];
        }

        emit KeyRemoved(_key, _purpose, keyType);

        return true;
    }

    /**
    * @dev See {IERC735-addClaim}.
    * @notice Implementation of the addClaim function from the ERC-735 standard
    *  Require that the msg.sender has claim signer key.
    *
    * @param _topic The type of claim
    * @param _scheme The scheme with which this claim SHOULD be verified or how it should be processed.
    * @param _issuer The issuers identity contract address, or the address used to sign the above signature.
    * @param _signature Signature which is the proof that the claim issuer issued a claim of topic for this identity.
    * it MUST be a signed message of the following structure:
    * keccak256(abi.encode(address identityHolder_address, uint256 _ topic, bytes data))
    * @param _data The hash of the claim data, sitting in another
    * location, a bit-mask, call data, or actual data based on the claim scheme.
    * @param _uri The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
    *
    * @return claimRequestId Returns claimRequestId: COULD be
    * send to the approve function, to approve or reject this claim.
    * triggers ClaimAdded event.
    */
    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes memory _signature,
        bytes memory _data,
        string memory _uri
    )
    public
    delegatedOnly
    onlyClaimKey
    override
    returns (bytes32 claimRequestId)
    {
        if (_issuer != address(this)) {
            require(IClaimIssuer(_issuer).isClaimValid(IIdentity(address(this)), _topic, _signature, _data), "invalid claim");
        }

        bytes32 claimId = keccak256(abi.encode(_issuer, _topic));
        _claims[claimId].topic = _topic;
        _claims[claimId].scheme = _scheme;
        _claims[claimId].signature = _signature;
        _claims[claimId].data = _data;
        _claims[claimId].uri = _uri;

        if (_claims[claimId].issuer != _issuer) {
            _claimsByTopic[_topic].push(claimId);
            _claims[claimId].issuer = _issuer;

            emit ClaimAdded(claimId, _topic, _scheme, _issuer, _signature, _data, _uri);
        }
        else {
            emit ClaimChanged(claimId, _topic, _scheme, _issuer, _signature, _data, _uri);
        }
        return claimId;
    }

    /**
    * @dev See {IERC735-removeClaim}.
    * @notice Implementation of the removeClaim function from the ERC-735 standard
    * Require that the msg.sender has management key.
    * Can only be removed by the claim issuer, or the claim holder itself.
    *
    * @param _claimId The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
    *
    * @return success Returns TRUE when the claim was removed.
    * triggers ClaimRemoved event
    */
    function removeClaim(bytes32 _claimId)
    public
    delegatedOnly
    onlyClaimKey
    override
    returns
    (bool success) {
        uint256 _topic = _claims[_claimId].topic;
        if (_topic == 0) {
            revert("NonExisting: There is no claim with this ID");
        }

        uint claimIndex = 0;
        uint arrayLength = _claimsByTopic[_topic].length;
        while (_claimsByTopic[_topic][claimIndex] != _claimId) {
            claimIndex++;

            if (claimIndex >= arrayLength) {
                break;
            }
        }

        _claimsByTopic[_topic][claimIndex] =
        _claimsByTopic[_topic][arrayLength - 1];
        _claimsByTopic[_topic].pop();

        emit ClaimRemoved(
            _claimId,
            _topic,
            _claims[_claimId].scheme,
            _claims[_claimId].issuer,
            _claims[_claimId].signature,
            _claims[_claimId].data,
            _claims[_claimId].uri
        );

        delete _claims[_claimId];

        return true;
    }

    /**
    * @dev See {IERC735-getClaim}.
    * @notice Implementation of the getClaim function from the ERC-735 standard.
    *
    * @param _claimId The identity of the claim i.e. keccak256(abi.encode(_issuer, _topic))
    *
    * @return topic Returns all the parameters of the claim for the
    * specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return scheme Returns all the parameters of the claim for the
    * specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return issuer Returns all the parameters of the claim for the
    * specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return signature Returns all the parameters of the claim for the
    * specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return data Returns all the parameters of the claim for the
    * specified _claimId (topic, scheme, signature, issuer, data, uri) .
    * @return uri Returns all the parameters of the claim for the
    * specified _claimId (topic, scheme, signature, issuer, data, uri) .
    */
    function getClaim(bytes32 _claimId)
    public
    override
    view
    returns(
        uint256 topic,
        uint256 scheme,
        address issuer,
        bytes memory signature,
        bytes memory data,
        string memory uri
    )
    {
        return (
        _claims[_claimId].topic,
        _claims[_claimId].scheme,
        _claims[_claimId].issuer,
        _claims[_claimId].signature,
        _claims[_claimId].data,
        _claims[_claimId].uri
        );
    }

    /**
    * @dev See {IERC734-keyHasPurpose}.
    * @notice Returns true if the key has MANAGEMENT purpose or the specified purpose.
    */
    function keyHasPurpose(bytes32 _key, uint256 _purpose)
    public
    override
    view
    returns(bool result)
    {
        Key memory key = _keys[_key];
        if (key.key == 0) return false;

        for (uint keyPurposeIndex = 0; keyPurposeIndex < key.purposes.length; keyPurposeIndex++) {
            uint256 purpose = key.purposes[keyPurposeIndex];

            if (purpose == 1 || purpose == _purpose) return true;
        }

        return false;
    }

    /**
     * @notice Initializer internal function for the Identity contract.
     *
     * @param initialManagementKey The ethereum address to be set as the management key of the ONCHAINID.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Identity_init(address initialManagementKey) internal {
        require(!_initialized || _isConstructor(), "Initial key was already setup.");
        _initialized = true;
        _canInteract = true;

        bytes32 _key = keccak256(abi.encode(initialManagementKey));
        _keys[_key].key = _key;
        _keys[_key].purposes = [1];
        _keys[_key].keyType = 1;
        _keysByPurpose[1].push(_key);
        emit KeyAdded(_key, 1, 1);
    }

    /**
     * @notice Computes if the context in which the function is called is a constructor or not.
     *
     * @return true if the context is a constructor.
     */
    function _isConstructor() private view returns (bool) {
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


// File contracts/ClaimIssuer.sol


contract ClaimIssuer is IClaimIssuer, Identity {
    mapping (bytes => bool) public revokedClaims;

    // solhint-disable-next-line no-empty-blocks
    constructor(address initialManagementKey) Identity(initialManagementKey, false) {}

    /**
     *  @dev See {IClaimIssuer-revokeClaimBySignature}.
     */
    function revokeClaimBySignature(bytes calldata signature) external override delegatedOnly onlyManager {
        require(!revokedClaims[signature], "Conflict: Claim already revoked");

        revokedClaims[signature] = true;

        emit ClaimRevoked(signature);
    }

    /**
     *  @dev See {IClaimIssuer-revokeClaim}.
     */
    function revokeClaim(bytes32 _claimId, address _identity) external override delegatedOnly onlyManager returns(bool) {
        uint256 foundClaimTopic;
        uint256 scheme;
        address issuer;
        bytes memory sig;
        bytes memory data;

        ( foundClaimTopic, scheme, issuer, sig, data, ) = Identity(_identity).getClaim(_claimId);

        require(!revokedClaims[sig], "Conflict: Claim already revoked");

        revokedClaims[sig] = true;
        emit ClaimRevoked(sig);
        return true;
    }

    /**
     *  @dev See {IClaimIssuer-isClaimValid}.
     */
    function isClaimValid(
        IIdentity _identity,
        uint256 claimTopic,
        bytes memory sig,
        bytes memory data)
    external override view returns (bool claimValid)
    {
        bytes32 dataHash = keccak256(abi.encode(_identity, claimTopic, data));
        // Use abi.encodePacked to concatenate the message prefix and the message to sign.
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));

        // Recover address of data signer
        address recovered = getRecoveredAddress(sig, prefixedHash);

        // Take hash of recovered address
        bytes32 hashedAddr = keccak256(abi.encode(recovered));

        // Does the trusted identifier have they key which signed the user's claim?
        //  && (isClaimRevoked(_claimId) == false)
        if (keyHasPurpose(hashedAddr, 3) && (isClaimRevoked(sig) == false)) {
            return true;
        }

        return false;
    }

    /**
     *  @dev See {IClaimIssuer-isClaimRevoked}.
     */
    function isClaimRevoked(bytes memory _sig) public override view returns (bool) {
        if (revokedClaims[_sig]) {
            return true;
        }

        return false;
    }

    /**
     *  @dev See {IClaimIssuer-getRecoveredAddress}.
     */
    function getRecoveredAddress(bytes memory sig, bytes32 dataHash)
        public override
        pure
        returns (address addr)
    {
        bytes32 ra;
        bytes32 sa;
        uint8 va;

        // Check the signature length
        if (sig.length != 65) {
            return address(0);
        }

        // Divide the signature in r, s and v variables
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ra := mload(add(sig, 32))
            sa := mload(add(sig, 64))
            va := byte(0, mload(add(sig, 96)))
        }

        if (va < 27) {
            va += 27;
        }

        address recoveredAddress = ecrecover(dataHash, va, ra, sa);

        return (recoveredAddress);
    }
}