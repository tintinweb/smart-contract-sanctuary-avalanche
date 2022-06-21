// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "./DataStoreLib.sol";

/**
 * @title GeodeUtils library
 * @notice Exclusively contains functions responsible for administration of Geode Portal,
 * including functions related to "limited upgradability" with Senate & porposals.
 * @dev Contracts relying on this library must initialize GeodeUtils.Universe
 * @dev ALL "fee" variables are limited by FEE_DENOMINATOR = 100%
 * @dev Admin functions are already protected.
 * Note that this library contains both functions called by users(ID) and admins(GOVERNANCE, SENATE )
 * Note refer to DataStoreUtils before reviewing
 */
library GeodeUtils {
  using DataStoreUtils for DataStoreUtils.DataStore;

  event OperationFeeUpdated(uint256 newFee);
  event MaxOperationFeeUpdated(uint256 newMaxFee);
  event ControllerChanged(uint256 id, address newCONTROLLER);
  event Proposed(
    uint256 id,
    address _CONTROLLER,
    uint256 _type,
    uint256 _duration
  );
  event ProposalApproved(uint256 id);
  event NewElectorType(uint256 _type);
  event Vote(uint256 proposalId, uint256 electorId);
  event NewSenate(address senate, uint256 senate_expire_timestamp);

  /**

   * @notice Proposal basically refers to give the control of an ID to a CONTROLLER.
   *
   * @notice A Proposal has 4 specs:
   * @param TYPE: seperates the proposals and related functionality between different ID types.
   * * RESERVED TYPES on GeodeUtils:
   * * * TYPE 0: inactive
   * * * TYPE 1: Senate: controls state of governance, contract updates and other members of A Universe
   * * * TYPE 2: Upgrade: address of the implementation for desired contract upgrade
   * * * TYPE 3: **gap** : formally it represented the admin contract, however since UUPS is being used as a upgrade path,
   * this TYPE is now reserved to make it easier for secondary contracts to add their own type.
   *
   * @param name: id is created by keccak(name)
   *
   * @param CONTROLLER: the address that refers to the change that is proposed by given proposal ID.
   * * This slot can be given the control of an id to a user, a new implementation contract, a new Senate etc.
   *
   * @param deadline: refers to last timestamp until a proposal expires, limited by MAX_PROPOSAL_DURATION
   * * Expired proposals can not be approved by Senate
   * * Expired proposals can be overriden by new proposals
   **/
  struct Proposal {
    address CONTROLLER;
    uint256 TYPE;
    uint256 deadline;
    bytes name;
  }
  /**
   * @notice Universe is A blockchain. In this case, it defines Avalanche
   * @param GOVERNANCE a community that works to improve the core product and ensures its adoption in the DeFi ecosystem
   * Suggests updates, such as new planets, operators, contract upgrades and new Senate, on the Ecosystem _without any permissions to force them_
   * @param SENATE An address that controls the state of governance, updates and other users in the Geode Ecosystem
   * Note SENATE is proposed by Governance and voted by all planets, if 2/3 approves.
   * @param OPERATION_FEE operation fee of the given contract, acquired by GOVERNANCE. Limited by MAX_OPERATION_FEE
   * @param MAX_OPERATION_FEE set by SENATE, limited by FEE_DENOMINATOR
   * @param FEE_DENOMINATOR represents 100%
   * @param SENATE_EXPIRE_TIMESTAMP refers to the last timestamp that SENATE can continue operating. Enforces a new election, limited by MAX_SENATE_PERIOD
   * @param approvedUpgrade only 1(one) implementation contract can be "approved" at any given time. @dev Should set to address(0) after every upgrade
   * @param _electorCount increased when a new id is added with _electorTypes[id] == true
   * @param _electorTypes only given types can vote @dev must only be used at upgrades.
   * @param _proposalForId proposals are kept seperately instead of setting the parameters of id in DATASTORE, and then setting it's type; to allowe surpassing type checks to save gas cost
   **/
  struct Universe {
    address SENATE;
    address GOVERNANCE;
    uint256 OPERATION_FEE;
    uint256 MAX_OPERATION_FEE;
    uint256 FEE_DENOMINATOR;
    uint256 SENATE_EXPIRE_TIMESTAMP;
    address approvedUpgrade;
    uint256 _electorCount;
    mapping(uint256 => bool) _electorTypes;
    mapping(uint256 => Proposal) _proposalForId;
  }

  uint32 public constant MIN_PROPOSAL_DURATION = 1 days;
  uint32 public constant MAX_PROPOSAL_DURATION = 1 weeks;
  uint32 public constant MAX_SENATE_PERIOD = 730 days; // 2 years

  modifier onlySenate(Universe storage self) {
    require(msg.sender == self.SENATE, "GeodeUtils: SENATE role needed");
    require(
      block.timestamp < self.SENATE_EXPIRE_TIMESTAMP,
      "GeodeUtils: SENATE not active"
    );
    _;
  }

  /**
   *                                         ** UNIVERSE GETTERS **
   **/

  /// @return the address of SENATE
  function getSenate(Universe storage self) public view returns (address) {
    return self.SENATE;
  }

  /// @return the address of GOVERNANCE
  function getGovernance(Universe storage self) public view returns (address) {
    return self.GOVERNANCE;
  }

  /// @notice MAX_OPERATION_FEE must limit OPERATION_FEE even if MAX is changed
  /// @return active OPERATION_FEE; limited by MAX_OPERATION_FEE
  function getOperationFee(Universe storage self)
    public
    view
    returns (uint256)
  {
    return
      self.OPERATION_FEE > self.MAX_OPERATION_FEE
        ? self.MAX_OPERATION_FEE
        : self.OPERATION_FEE;
  }

  /// @return MAX_OPERATION_FEE
  function getMaxOperationFee(Universe storage self)
    public
    view
    returns (uint256)
  {
    return self.MAX_OPERATION_FEE;
  }

  /// @return the expiration date of current SENATE as a timestamp
  function getSenateExpireTimestamp(Universe storage self)
    public
    view
    returns (uint256)
  {
    return self.SENATE_EXPIRE_TIMESTAMP;
  }

  /**
   *                                         ** UNIVERSE SETTERS **
   */

  /// @return true if the operation was succesful, might be helpful when governance rights are distributed
  /// @dev can not set a fee more than MAX
  /// @dev no need to check FEE_DENOMINATOR
  function setOperationFee(Universe storage self, uint256 _newFee)
    external
    returns (bool)
  {
    require(_newFee <= self.MAX_OPERATION_FEE, "GeodeUtils: fee more than MAX");
    self.OPERATION_FEE = _newFee;
    emit OperationFeeUpdated(_newFee);
    return true;
  }

  /// @return true if the operation was succesful
  /// @dev can not set a fee more than FEE_DENOMINATOR (100%)
  function setMaxOperationFee(Universe storage self, uint256 _newMaxFee)
    external
    onlySenate(self)
    returns (bool)
  {
    require(
      _newMaxFee <= self.FEE_DENOMINATOR,
      "GeodeUtils: fee more than 100%"
    );
    self.MAX_OPERATION_FEE = _newMaxFee;
    emit MaxOperationFeeUpdated(_newMaxFee);
    return true;
  }

  /**
  @notice only the current CONTROLLER can change
  @dev this operation can not be reverted by old CONTROLLER
  @dev in case the current controller wants to remove the 
  need to upgrade to NO Controller they should provide smt like 0x0..dead
   */
  function changeIdCONTROLLER(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 id,
    address newCONTROLLER
  ) external {
    require(
      newCONTROLLER != address(0),
      "GeodeUtils: CONTROLLER can not be zero"
    );
    require(
      _DATASTORE.readAddressForId(id, "CONTROLLER") == msg.sender,
      "GeodeUtils: not CONTROLLER of given id"
    );
    _DATASTORE.writeAddressForId(id, "CONTROLLER", newCONTROLLER);
    emit ControllerChanged(id, newCONTROLLER);
  }

  /**
   *                                          ** PROPOSALS **
   */

  /**
   * CONTROLLER Proposals
   */

  function getProposal(Universe storage self, uint256 id)
    external
    view
    returns (Proposal memory)
  {
    return self._proposalForId[id];
  }

  /**
   * @notice to ensure the flexibility of Governance-less upgrades in the future, Anyone can create a Proposal.
   * @notice a proposal can be overriden if: expired OR approved. DATASTORE(id) will not be overriden until the proposal is approved.
   * @dev refer to structure of Proposal for explanations of params
   */
  function newProposal(
    Universe storage self,
    address _CONTROLLER,
    uint256 _type,
    uint256 _duration,
    bytes calldata _name
  ) external {
    require(
      _duration >= MIN_PROPOSAL_DURATION,
      "GeodeUtils: duration should be higher than min value"
    );
    require(_duration <= MAX_PROPOSAL_DURATION, "GeodeUtils: duration exceeds");
    uint256 id = uint256(keccak256(abi.encodePacked(_name)));
    require(
      self._proposalForId[id].deadline < block.timestamp,
      "GeodeUtils: name already proposed"
    );
    self._proposalForId[id] = Proposal({
      CONTROLLER: _CONTROLLER,
      TYPE: _type,
      deadline: block.timestamp + _duration,
      name: _name
    });
    emit Proposed(id, _CONTROLLER, _type, _duration);
  }

  /**
   *  @notice type specific changes for reserved_types(1,2,3) are implemented here,
   *  any other addition should take place in Portal, as not related
   *  @param id given ID proposal that has been approved by Senate
   *  @dev Senate should not be able to approve expired proposals
   *  @dev Senate should not be able to approve SENATE proposals :)
   */
  function approveProposal(
    Universe storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 id
  ) external onlySenate(self) {
    require(
      self._proposalForId[id].deadline >= block.timestamp,
      "GeodeUtils: proposal expired"
    );
    require(
      self._proposalForId[id].TYPE != 1,
      "GeodeUtils: Senate can not approve Senate Proposal"
    );
    _DATASTORE.writeBytesForId(id, "name", self._proposalForId[id].name);
    _DATASTORE.writeAddressForId(
      id,
      "CONTROLLER",
      self._proposalForId[id].CONTROLLER
    );
    _DATASTORE.writeUintForId(id, "TYPE", self._proposalForId[id].TYPE);
    _DATASTORE.allIdsByType[self._proposalForId[id].TYPE].push(id);

    if (self._proposalForId[id].TYPE == 2) {
      self.approvedUpgrade = self._proposalForId[id].CONTROLLER;
    }
    self._proposalForId[id].deadline = block.timestamp;
    if (self._electorTypes[_DATASTORE.readUintForId(id, "TYPE")])
      self._electorCount += 1;
    emit ProposalApproved(id);
  }

  /**
   * SENATE Proposals
   */

  /**
   * @notice only selected types can vote for senate
   * @param _type selected type
   * @param _isElector true if selected _type can vote for senate from now on
   * @dev can not set with the same value again, preventing double increment/decrements
   */
  function setElectorType(
    Universe storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _type,
    bool _isElector
  ) external {
    require(
      self._electorTypes[_type] != _isElector,
      "GeodeUtils: type already _isElector"
    );
    require(
      _type != 0 && _type != 1 && _type != 2 && _type != 3,
      "GeodeUtils: 0, Senate, Upgrade, ProxyAdmin cannot be elector!"
    );
    self._electorTypes[_type] = _isElector;
    if (_isElector) {
      self._electorCount += _DATASTORE.allIdsByType[_type].length;
    } else {
      self._electorCount -= _DATASTORE.allIdsByType[_type].length;
    }
    emit NewElectorType(_type);
  }

  /**
   * @notice Proposed CONTROLLER is the new Senate after 2/3 of the electors are approved
   * NOTE mathematically, min 4 elector is needed for (c+1)*2/3 to work properly
   * @notice id can not vote if:
   *- approved already
   *- not its type is not elector
   *- not proposal is expired
   *- not senate proposal
   * @param electorId should have the voting rights, msg.sender should be the CONTROLLER of given ID
   * @dev pins id as "voted" when approved
   * @dev increases "approvalCount" of proposalId by 1 when approved
   */
  function approveSenate(
    Universe storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 proposalId,
    uint256 electorId
  ) external {
    require(
      self._proposalForId[proposalId].TYPE == 1,
      "GeodeUtils: NOT Senate Proposal"
    );
    require(
      self._proposalForId[proposalId].deadline >= block.timestamp,
      "GeodeUtils: proposal expired"
    );
    require(
      _DATASTORE.readAddressForId(electorId, "CONTROLLER") == msg.sender,
      "GeodeUtils: msg.sender should be CONTROLLER of given electorId!"
    );
    require(
      self._electorTypes[_DATASTORE.readUintForId(electorId, "TYPE")],
      "GeodeUtils: NOT an elector"
    );
    require(
      _DATASTORE.readUintForId(
        proposalId,
        bytes32(keccak256(abi.encodePacked(electorId, "voted")))
      ) == 0,
      " GeodeUtils: already approved"
    );
    _DATASTORE.writeUintForId(
      proposalId,
      bytes32(keccak256(abi.encodePacked(electorId, "voted"))),
      1
    );
    emit Vote(proposalId, electorId);
    _DATASTORE.writeUintForId(
      proposalId,
      "approvalCount",
      _DATASTORE.readUintForId(proposalId, "approvalCount") + 1
    );
    if (
      _DATASTORE.readUintForId(proposalId, "approvalCount") >=
      ((self._electorCount + 1) * 2) / 3
    ) {
      self.SENATE = self._proposalForId[proposalId].CONTROLLER;
      self._proposalForId[proposalId].deadline = block.timestamp;
      self.SENATE_EXPIRE_TIMESTAMP = block.timestamp + MAX_SENATE_PERIOD; // 2 years
      emit NewSenate(self.SENATE, self.SENATE_EXPIRE_TIMESTAMP);
    }
  }

  /**
   * @notice Get if it is allowed to change a specific contract with the current version.
   * @return True if it is allowed by senate and false if not.
   * @dev address(0) should return false
   **/
  function isUpgradeAllowed(
    Universe storage self,
    address proposed_implementation
  ) external view returns (bool) {
    return
      self.approvedUpgrade != address(0) &&
      self.approvedUpgrade == proposed_implementation;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

/**
 * @title Storage Management library for dynamic structs based on data types
 *
 * DataStoreUtils is a storage management tool designed to create a safe and scalable
 * storage layout with the help of ids and keys.
 * Mainly focusing on upgradable contracts with multiple user types to create a
 * sustainable development environment.
 *
 * In summary, extra gas cost that would be saved with Storage packing are
 * ignored to create upgradable structs.
 *
 * IDs are the representation of a user with any given key as properties.
 * Type for ID is not mandatory, not all IDs should have an explicit type.
 * Thus there is no checks of types or keys.
 *
 * @notice distinct id and key pairs return different storage slots
 *
 */
library DataStoreUtils {
  /**
   * @notice Main Struct for reading and writing data to storage for given id+key pairs
   * @param allIdsByType optional categorization for given ID, requires direct access, type => id[]
   * @param uintData keccak(id, key) =>  returns uint256
   * @param bytesData keccak(id, key) => returns bytes
   * @param addressData keccak(id, key) =>  returns address
   * NOTE any other storage type can be expressed as bytes
   */
  struct DataStore {
    mapping(uint256 => uint256[]) allIdsByType;
    mapping(bytes32 => uint256) uintData;
    mapping(bytes32 => bytes) bytesData;
    mapping(bytes32 => address) addressData;
  }

  /**
   * **DATA GETTERS **
   **/
  function readUintForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key
  ) public view returns (uint256 data) {
    data = self.uintData[keccak256(abi.encodePacked(_id, _key))];
  }

  function readBytesForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key
  ) public view returns (bytes memory data) {
    data = self.bytesData[keccak256(abi.encodePacked(_id, _key))];
  }

  function readAddressForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key
  ) public view returns (address data) {
    data = self.addressData[keccak256(abi.encodePacked(_id, _key))];
  }

  /**
   * **DATA SETTERS **
   **/
  function writeUintForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key,
    uint256 data
  ) public {
    self.uintData[keccak256(abi.encodePacked(_id, _key))] = data;
  }

  function writeBytesForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key,
    bytes memory data
  ) public {
    self.bytesData[keccak256(abi.encodePacked(_id, _key))] = data;
  }

  function writeAddressForId(
    DataStore storage self,
    uint256 _id,
    bytes32 _key,
    address data
  ) public {
    self.addressData[keccak256(abi.encodePacked(_id, _key))] = data;
  }
}