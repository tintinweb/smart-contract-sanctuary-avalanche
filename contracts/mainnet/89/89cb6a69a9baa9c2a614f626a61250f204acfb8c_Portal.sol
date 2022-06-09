// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IERC20InterfaceUpgradable {
  function initialize(
    uint256 id_,
    string memory name_,
    address _1155
  ) external;
}

// SPDX-License-Identifier: MIT

//   ██████╗ ███████╗ ██████╗ ██████╗ ███████╗    ██████╗  ██████╗ ██████╗ ████████╗ █████╗ ██╗
//  ██╔════╝ ██╔════╝██╔═══██╗██╔══██╗██╔════╝    ██╔══██╗██╔═══██╗██╔══██╗╚══██╔══╝██╔══██╗██║
//  ██║  ███╗█████╗  ██║   ██║██║  ██║█████╗      ██████╔╝██║   ██║██████╔╝   ██║   ███████║██║
//  ██║   ██║██╔══╝  ██║   ██║██║  ██║██╔══╝      ██╔═══╝ ██║   ██║██╔══██╗   ██║   ██╔══██║██║
//  ╚██████╔╝███████╗╚██████╔╝██████╔╝███████╗    ██║     ╚██████╔╝██║  ██║   ██║   ██║  ██║███████╗
//   ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝
//

pragma solidity =0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/DataStoreLib.sol";
import "./utils/GeodeUtilsLib.sol";
import "./utils/StakeUtilsLib.sol";
import "../interfaces/IPortal.sol";
import "../interfaces/IERC20InterfaceUpgradable.sol";

/**
 * @title Geode Finance Avalanche Portal: Avax Liquid Staking
 *
 * Geode Portal is a first of its kind Decentralized Minter that builds
 * a trustless staking Ecosystem for any service provider.
 *
 * @dev refer to DataStoreUtils before reviewing
 * @dev refer to GeodeUtils > Includes the logic for management of Geode Portal with Senate.
 * @dev refer to StakeUtils > Includes the logic for staking functionality with Withdrawal Pools
 * @notice TYPE: seperates the proposals and related functionality between different ID types.
 * * RESERVED TYPES on Portalv1:
 * * * TYPE 4: Operator
 * * * TYPE 5: Planet
 */

contract Portal is
  IPortal,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  ERC1155HolderUpgradeable,
  UUPSUpgradeable
{
  event ContractVersionSet(uint256 version);
  event DefaultInterfaceSet(address DefaultInterface);
  event pBankSet(uint256 id, bytes pBank);

  using DataStoreUtils for DataStoreUtils.DataStore;
  using GeodeUtils for GeodeUtils.Universe;
  using StakeUtils for StakeUtils.StakePool;

  DataStoreUtils.DataStore private DATASTORE;
  GeodeUtils.Universe private GEODE;
  StakeUtils.StakePool private STAKEPOOL;

  /// @notice Default erc1155 interface, currently allows every id to be act as ERC20
  address public DEFAULT_INTERFACE;
  uint256 public CONTRACT_VERSION;

  function initialize(
    address _GOVERNANCE,
    address _ORACLE,
    address _gAVAX,
    address _DEFAULT_SWAP_POOL,
    address _DEFAULT_INTERFACE,
    address _DEFAULT_LP_TOKEN
  ) public virtual override initializer {
    __ReentrancyGuard_init();
    __Pausable_init();
    __ERC1155Holder_init();
    __UUPSUpgradeable_init();

    require(_GOVERNANCE != address(0), "Portal: _GOVERNANCE can not be zero");
    require(_ORACLE != address(0), "Portal: _ORACLE can not be zero");
    require(_gAVAX != address(0), "Portal: _gAVAX can not be zero");
    require(
      _DEFAULT_SWAP_POOL != address(0),
      "Portal: _DEFAULT_SWAP_POOL can not be zero"
    );
    require(
      _DEFAULT_INTERFACE != address(0),
      "Portal: _DEFAULT_INTERFACE can not be zero"
    );
    require(
      _DEFAULT_LP_TOKEN != address(0),
      "Portal: _DEFAULT_LP_TOKEN can not be zero"
    );
    /**
     * since it is deployment of v1 contracts senate is currently the governance
     * A vote can be proposed when electorCount > 4
     */
    GEODE.GOVERNANCE = _GOVERNANCE;
    GEODE.SENATE = GEODE.GOVERNANCE;
    GEODE.SENATE_EXPIRE_TIMESTAMP =
      block.timestamp +
      GeodeUtils.MAX_SENATE_PERIOD;
    GEODE.OPERATION_FEE = 0;
    GEODE.MAX_OPERATION_FEE = 0;
    GEODE.FEE_DENOMINATOR = 10**10;
    // allow Planets to vote for Senate
    GEODE.setElectorType(DATASTORE, 5, true);

    DEFAULT_INTERFACE = _DEFAULT_INTERFACE;

    STAKEPOOL.FEE_DENOMINATOR = GEODE.FEE_DENOMINATOR;
    STAKEPOOL.gAVAX = _gAVAX;
    STAKEPOOL.ORACLE = _ORACLE;
    STAKEPOOL.DEFAULT_SWAP_POOL = _DEFAULT_SWAP_POOL;
    STAKEPOOL.DEFAULT_LP_TOKEN = _DEFAULT_LP_TOKEN;
    STAKEPOOL.DEFAULT_A = 60;
    STAKEPOOL.DEFAULT_FEE = 4e6;
    STAKEPOOL.DEFAULT_ADMIN_FEE = 5e9;
    STAKEPOOL.PERIOD_PRICE_INCREASE_LIMIT = (2 * GEODE.FEE_DENOMINATOR) / 1e3; // 0.2%
    STAKEPOOL.MAX_MAINTAINER_FEE = (10 * GEODE.FEE_DENOMINATOR) / 1e2; //10%

    GEODE.approvedUpgrade = address(0);

    CONTRACT_VERSION = 1;
    emit ContractVersionSet(1);
  }

  modifier onlyGovernance() {
    require(msg.sender == GEODE.GOVERNANCE, "Portal: sender not GOVERNANCE");
    _;
  }

  /**
   *                                    ** Contract specific functions **
   **/

  ///@dev required by the OZ UUPS module
  function _authorizeUpgrade(address proposed_implementation)
    internal
    virtual
    override
  {
    require(proposed_implementation != address(0));
    require(
      GEODE.isUpgradeAllowed(proposed_implementation),
      "Portal: is not allowed to upgrade"
    );
  }

  function pause() external virtual override onlyGovernance {
    _pause();
  }

  function unpause() external virtual override onlyGovernance {
    _unpause();
  }

  function getVersion() external view virtual override returns (uint256) {
    return CONTRACT_VERSION;
  }

  function gAVAX() external view virtual override returns (address) {
    return address(STAKEPOOL.getgAVAX());
  }

  /**
   *                                          ** GETTERS **
   */

  /**
   *                                    ** GOVERNANCE GETTERS **
   */

  function getSenate() external view virtual override returns (address) {
    return GEODE.getSenate();
  }

  function getGovernance() external view virtual override returns (address) {
    return GEODE.getGovernance();
  }

  function getOperationFee() external view virtual override returns (uint256) {
    return GEODE.getOperationFee();
  }

  function getMaxOperationFee()
    external
    view
    virtual
    override
    returns (uint256)
  {
    return GEODE.getMaxOperationFee();
  }

  function getSenateExpireTimestamp()
    external
    view
    virtual
    override
    returns (uint256)
  {
    return GEODE.getSenateExpireTimestamp();
  }

  function getFeeDenominator()
    external
    view
    virtual
    override
    returns (uint256)
  {
    return GEODE.FEE_DENOMINATOR;
  }

  function getStakePoolParams()
    external
    view
    virtual
    override
    returns (StakeUtils.StakePool memory)
  {
    return STAKEPOOL;
  }

  /*
   *                                          **ID GETTERS **
   */

  /// @return allIdsByType array of DatastoreUtilsLib
  function getIdsByType(uint256 _type)
    external
    view
    virtual
    override
    returns (uint256[] memory)
  {
    return DATASTORE.allIdsByType[_type];
  }

  /// @notice id is keccak(name)
  function getIdFromName(string calldata _name)
    external
    pure
    virtual
    override
    returns (uint256 _id)
  {
    _id = uint256(keccak256(abi.encodePacked(_name)));
  }

  /// @notice returns bytes(0) for empty ids, mandatory
  function getNameFromId(uint256 _id)
    external
    view
    virtual
    override
    returns (bytes memory)
  {
    return DATASTORE.readBytesForId(_id, "name");
  }

  /// @notice returns address(0) for empty ids, mandatory
  function getCONTROLLERFromId(uint256 _id)
    external
    view
    virtual
    override
    returns (address)
  {
    return DATASTORE.readAddressForId(_id, "CONTROLLER");
  }

  /**
   * @notice returns address(0) if NOT set, NOT mandatory
   * @dev maintainer operates the id: claims the fee, pays the debt, signs the messages for verification etc.
   */
  function getMaintainerFromId(uint256 _id)
    external
    view
    virtual
    override
    returns (address)
  {
    return DATASTORE.readAddressForId(_id, "maintainer");
  }

  /// @notice even if MAX_MAINTAINER_FEE is decreased later, it returns limited maximum
  function getMaintainerFeeFromId(uint256 _id)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return STAKEPOOL.getMaintainerFee(DATASTORE, _id);
  }

  /**
   *                                          ** Planet GETTERS **
   **/

  /// @dev not reliable => refer setPlanetInterface
  function planetCurrentInterface(uint256 _id)
    external
    view
    virtual
    override
    returns (address)
  {
    return DATASTORE.readAddressForId(_id, "currentInterface");
  }

  /// @notice pool that maintains the price of the staking derivative
  function planetWithdrawalPool(uint256 _id)
    external
    view
    virtual
    override
    returns (address)
  {
    return address(StakeUtils.withdrawalPoolById(DATASTORE, _id));
  }

  /// @notice LP token of the Withdrawal pool of given ID
  function planetLPToken(uint256 _id)
    external
    view
    virtual
    override
    returns (address)
  {
    return address(StakeUtils.LPTokenById(DATASTORE, _id));
  }

  /**
   * @notice ActiveOperator can claim the surplus of the given staking pool to create validators,
   * @notice There can be only one active operator for an ID. However old active operators can still
   * continue operating until activationExpiration timestamp and acquire fees.
   **/
  function planetActiveOperator(uint256 _id)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return DATASTORE.readUintForId(_id, "activeOperator");
  }

  /**
   *                                              ** Operator GETTERS **
   **/

  function operatorActivationExpiration(uint256 planetId, uint256 operatorId)
    public
    view
    returns (uint256)
  {
    return
      DATASTORE.readUintForId(
        planetId,
        bytes32(keccak256(abi.encodePacked(operatorId, "activationExpiration")))
      );
  }

  /**
   *                                          ** SETTERS **
   */

  /**
   * @notice only CONTROLLER is allowed to change the CONTROLLER of the pool
   * check is done inside the library.
   * @dev this action can not be overwritten by the old CONTROLLER after set.
   */
  function changeIdCONTROLLER(uint256 _id, address _newCONTROLLER)
    external
    virtual
    override
    whenNotPaused
  {
    GeodeUtils.changeIdCONTROLLER(DATASTORE, _id, _newCONTROLLER);
  }

  /**
   * @notice only CONTROLLER is allowed to change the maintainer of the pool
   * check is done inside the library.
   */
  function changeIdMaintainer(uint256 _id, address _newMaintainer)
    external
    virtual
    override
    whenNotPaused
  {
    StakeUtils.changeMaintainer(DATASTORE, _id, _newMaintainer);
  }

  function setMaintainerFee(uint256 _id, uint256 _newFee)
    external
    virtual
    override
  {
    STAKEPOOL.setMaintainerFee(DATASTORE, _id, _newFee);
  }

  /**
   * ** GOVERNANCE/SENATE SETTERS **
   */

  function setOperationFee(uint256 _newFee)
    external
    virtual
    override
    onlyGovernance
    returns (bool success)
  {
    success = GEODE.setOperationFee(_newFee);
  }

  /// @dev onlySenate CHECKED inside
  function setMaxOperationFee(uint256 _newFee)
    external
    virtual
    override
    returns (bool success)
  {
    success = GEODE.setMaxOperationFee(_newFee);
  }

  function setMaxMaintainerFee(uint256 _newMaxFee)
    external
    virtual
    override
    onlyGovernance
  {
    STAKEPOOL.setMaxMaintainerFee(_newMaxFee);
  }

  function setDefaultInterface(address _newDefault)
    external
    virtual
    override
    whenNotPaused
    onlyGovernance
  {
    DEFAULT_INTERFACE = _newDefault;
    emit DefaultInterfaceSet(_newDefault);
  }

  /**
   * ** Planet SETTERS **
   */

  /**
   * @notice When a pool maintainer wants another operator's maintainer to be able to start claiming surplus and
   * creating validators
   */
  function activateOperator(uint256 _id, uint256 _activeId)
    external
    virtual
    override
    whenNotPaused
    returns (bool)
  {
    return StakeUtils.activateOperator(DATASTORE, _id, _activeId);
  }

  /**
   * @notice deactivates an old operator for the given staking pool
   * @dev when activationExpiration is up, operator will NOT be able generate fees from pool,
   * it is expected for them to return the assets as surplus with payDebt function
   * @dev _deactivateAfter seconds until activation expires,
   */
  function deactivateOperator(uint256 _id, uint256 _deactivedId)
    external
    virtual
    override
    returns (bool)
  {
    return StakeUtils.deactivateOperator(DATASTORE, _id, _deactivedId);
  }

  function _setInterface(
    uint256 _id,
    address _Interface,
    bool isSet
  ) internal {
    STAKEPOOL.getgAVAX().setInterface(_Interface, _id, isSet);
    if (isSet) DATASTORE.writeAddressForId(_id, "currentInterface", _Interface);
    else if (DATASTORE.readAddressForId(_id, "currentInterface") == _Interface)
      DATASTORE.writeAddressForId(_id, "currentInterface", address(0));
  }

  /**
   *  @notice if a planet did not unset an old Interface, before setting a new one;
   *  & if new interface is unsetted, the old one will not be remembered!!
   *  use gAVAX.isInterface(interface,  id)
   * @param _Interface address of the new gAVAX ERC1155 interface for given ID
   * @param isSet true if new interface is going to be set, false if old interface is being unset
   */
  function setPlanetInterface(
    uint256 _id,
    address _Interface,
    bool isSet
  ) external virtual override whenNotPaused{
    require(
      DATASTORE.readAddressForId(_id, "maintainer") == msg.sender,
      "Portal: sender not maintainer"
    );
    _setInterface(_id, _Interface, isSet);
  }

  /**
   * ** Operator SETTERS/GETTERS**
   */

  /**
   * @notice pBank is the only address on the P subchain that interacts with tokens that is claimed by
   * operator as surplus.
   * @dev this logic makes the operator-planet interactions more reliable and transparent
   * when used by oracle to detect the token flow between different subchains.
   */
  function setOperatorPBank(uint256 id, bytes memory pBank)
    external
    virtual
    override
    whenNotPaused
  {
    require(
      DATASTORE.readAddressForId( id, "maintainer") == msg.sender,
      "Portal: sender not maintainer"
    );
    DATASTORE.writeBytesForId(id, "pBank", pBank);
    emit pBankSet(id, pBank);
  }

  function operatorPBank(uint256 id)
    external
    view
    virtual
    override
    whenNotPaused
    returns (bytes memory)
  {
    return DATASTORE.readBytesForId(id, "pBank");
  }

  /**
   *                                          ** PROPOSALS **
   */

  function getProposal(uint256 id)
    external
    view
    virtual
    override
    returns (GeodeUtils.Proposal memory)
  {
    return GEODE.getProposal(id);
  }

  /**
   * @notice creates a new proposal as id = keccak(name),
   * @param _CONTROLLER address of the
   * @param _type of the proposal is seperator between different user experiences
   * it can be upgrade proposal, senate election, operator/planet proposal etc.
   * @param _proposalDuration proposal can not approved after expiration but can be override
   * @param _name unique, id = keccak(name)
   * @dev "name already claimed check" is being made here as override can be a wanted feature in the future
   */
  function newProposal(
    address _CONTROLLER,
    uint256 _type,
    uint256 _proposalDuration,
    bytes calldata _name
  ) external virtual override whenNotPaused onlyGovernance {
    require(
      DATASTORE
        .readBytesForId(uint256(keccak256(abi.encodePacked(_name))), "name")
        .length == 0,
      "PORTAL: name already claimed"
    );
    GEODE.newProposal(_CONTROLLER, _type, _proposalDuration, _name);
  }

  /**
   * @dev only Senate is checked in GEODE.approveProposal
   */
  function approveProposal(uint256 _id)
    external
    virtual
    override
    whenNotPaused
  {
    /**
     * RESERVED GeodeUtilsLib
     * TYPE 0: inactive
     * TYPE 1: Senate
     * TYPE 2: Upgrade
     * TYPE 3: **deprecated**
     * RESERVED PORTALv1.0
     * TYPE 4: operator
     * TYPE 5: planet(public Staking pool)
     * RESERVED PORTALv1.3:
     * TYPE 6:  TODO :: private Staking pool (only maintainer)
     **/
    GEODE.approveProposal(DATASTORE, _id);
    if (DATASTORE.readUintForId(_id, "TYPE") == 4) {
      // operator
      DATASTORE.writeAddressForId(
        _id,
        "maintainer",
        DATASTORE.readAddressForId(_id, "CONTROLLER")
      );
    } else if (DATASTORE.readUintForId(_id, "TYPE") == 5) {
      // planet
      DATASTORE.writeAddressForId(
        _id,
        "maintainer",
        DATASTORE.readAddressForId(_id, "CONTROLLER")
      );
      address currentInterface = StakeUtils._clone(DEFAULT_INTERFACE);
      IERC20InterfaceUpgradable(currentInterface).initialize(
        _id,
        string(DATASTORE.readBytesForId(_id, "name")),
        address(STAKEPOOL.getgAVAX())
      );
      _setInterface(_id, currentInterface, true);
      address WithdrawalPool = STAKEPOOL.deployWithdrawalPool(DATASTORE, _id);
      Ownable(WithdrawalPool).transferOwnership(GEODE.GOVERNANCE);
    }
  }

  function approveSenate(uint256 proposalId, uint256 electorId)
    external
    virtual
    override
    whenNotPaused
  {
    GEODE.approveSenate(DATASTORE, proposalId, electorId);
  }

  /**
   *                                          ** ORACLE **
   */

  /**
   * @notice oraclePrice is a reliable source for any contract operation on-chain
   * @dev also the *mint price* as gAVAX.pricePerShare(id)
   * @dev TotalStakedAvax can be estimated by: TotalSupply(id) * planetOraclePrice(id)
   */
  function planetOraclePrice(uint256 _id)
    public
    view
    virtual
    override
    returns (uint256 _pricePershare)
  {
    _pricePershare = STAKEPOOL.oraclePrice(_id);
  }

  /**
   * @notice Oracle is only allowed for a period every day & pool operations are stopped then
   * @dev returns false after oracle update for the given pool.
   */
  function isOracleActive(uint256 _planetId)
    external
    view
    virtual
    override
    returns (bool)
  {
    return StakeUtils._isOracleActive(DATASTORE, _planetId);
  }

  /**
   * @notice only Oracle can report a new price. However price is not purely calculated by it.
   * the balance on P subchain is estimated by it, including the unrealized staking rewards.
   * Oracle has a pessimistic approach to make sure price will not decrease by a lot even in the case of loss of funds.

   * @param _opIds all ids of all operators who still collect fees.
   * @param _pBalanceIncreases the amount of avax that has been gained by the operator as POS rewards, respective to _opIds
   * @dev simply the new price is found by (pBALANCE + surplus - fees) / totalSupply)
   * @return price : new price after sanitychecks, might be useful if onchain oracle in the future
   */
  function reportOracle(
    uint256 _reportedTimeStamp,
    uint256 _planetId,
    uint256[] memory _opIds,
    uint256[] memory _pBalanceIncreases
  )
    external
    virtual
    override
    nonReentrant
    whenNotPaused
    returns (uint256 price)
  {
    price = STAKEPOOL.reportOracle(
      DATASTORE,
      _reportedTimeStamp,
      _planetId,
      _opIds,
      _pBalanceIncreases
    );
  }

  /**
   *                                          ** DEBT & SURPLUS **
   */

  /// @notice total amount of staked Avax that has been waiting to be staked
  function planetSurplus(uint256 planetId)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return DATASTORE.readUintForId(planetId, "surplus");
  }

  /// @notice total amount of staked Avax that can be claimed, as Fees are not claimable to be staked
  function planetClaimableSurplus(uint256 planetId)
    external
    view
    virtual
    override
    returns (uint256)
  {
    if (
      DATASTORE.readUintForId(planetId, "surplus") >
      DATASTORE.readUintForId(planetId, "unclaimedFees")
    ) {
      return
        DATASTORE.readUintForId(planetId, "surplus") -
        DATASTORE.readUintForId(planetId, "unclaimedFees");
    } else {
      return 0;
    }
  }

  /**
   * @notice When a debt is calculated, it also takes the unclaimed Fees into consideration for the Planet 
   * since payDebt pays that -if it is more than surplus- first and then covers the withdrawal Pool.
   * @return debtInAvax is the current debt amount that pays for fees and provides a stable price to withdrawalPool
   */
  function planetDebt(uint256 planetId)
    external
    view
    virtual
    override
    returns (uint256 debtInAvax)
  {
    debtInAvax = StakeUtils.withdrawalPoolById(DATASTORE, planetId).getDebt();
    if(DATASTORE.readUintForId(planetId, "unclaimedFees") > DATASTORE.readUintForId(planetId, "surplus")){
      uint256 debtInFees = DATASTORE.readUintForId(planetId, "unclaimedFees") - DATASTORE.readUintForId(planetId, "surplus");
      debtInAvax += debtInFees;
    }
  }

  /**
   * @notice Debt of the planet is found by approaching to it's price within WithdrawalPool
   * @return debtInAvax is the first guess that provides a withdrtawalPool price
   * that is between limits of slippage when buyback&burn.
   */
  function planetPBalance(uint256 planetId)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return DATASTORE.readUintForId(planetId, "pBalance");
  }

  /**
   * @notice amount of fee (as AVAX) that has been distributed to the maintainer so far
   * @dev for planet's maintainer's accumulatedFee (planetId,planetId)
   */
  function accumulatedFee(uint256 planetId, uint256 claimerId)
    external
    view
    virtual
    override
    returns (uint256)
  {
    (uint256 fee, ) = StakeUtils.accumulatedFee(DATASTORE, planetId, claimerId);
    return fee;
  }

  /**
   * @notice An Operator is expected to pay for the DEBT of a staking pool
   * @dev msg.value-debt is put to surplus, this can be used to increase surplus without minting new tokens!! useful to claim fees
   */
  function payDebt(uint256 planetId, uint256 operatorId)
    external
    payable
    virtual
    override
    nonReentrant
    whenNotPaused
  {
    STAKEPOOL.payDebt(DATASTORE, planetId, operatorId);
  }

  /**
   * @notice operators can not claim fees if: expired OR deactivated
   * @notice current unclaimedFees are not allowed to be claimed as surplus
   * @return success if transfer of funds is succesful
   */
  function claimSurplus(uint256 planetId)
    external
    virtual
    override
    whenNotPaused
    nonReentrant
    returns (bool success)
  {
    success = StakeUtils.claimSurplus(
      DATASTORE,
      planetId,
      DATASTORE.readUintForId(planetId, "activeOperator")
    );
    require(success, "Portal: Failed to send surplus");
  }

  /**
   * @notice anyone can call this function, but it sends AVAX only to maintainer.
   * @notice reverts if there are not enough surplus.
   */
  function claimFee(uint256 planetId, uint256 claimerId)
    external
    virtual
    override
    whenNotPaused
    nonReentrant
    returns (uint256 feeSent)
  {
    feeSent = StakeUtils.claimFee(DATASTORE, planetId, claimerId);
  }

  /**
   *                                          ** Staking Pools **
   */
  function isStakingPausedForPool(uint256 _id)
    external
    view
    virtual
    override
    returns (bool)
  {
    return StakeUtils.isStakingPausedForPool(DATASTORE, _id);
  }

  /// @notice when a pool is paused there are NO new funds to be minted, NO surplus.
  function pauseStakingForPool(uint256 _id)
    external
    virtual
    override
  {
    StakeUtils.pauseStakingForPool(DATASTORE, _id);
  }

  function unpauseStakingForPool(uint256 _id)
    external
    virtual
    override
  {
    StakeUtils.unpauseStakingForPool(DATASTORE, _id);
  }

  function stake(
    uint256 planetId,
    uint256 minGavax,
    uint256 deadline
  )
    external
    payable
    virtual
    override
    whenNotPaused
    nonReentrant
    returns (uint256 totalgAvax)
  {
    totalgAvax = STAKEPOOL.stake(DATASTORE, planetId, minGavax, deadline);
    require(totalgAvax > 0, "Portal: unsuccesful deposit");
  }

  uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../interfaces/ISwap.sol";
import "../../interfaces/IgAVAX.sol";
import "../../WithdrawalPool/LPToken.sol";
import "./DataStoreLib.sol";

/**
 * @title StakeUtils library
 * @notice Exclusively contains functions related to Avax Liquid Staking designed by Geode Finance
 * @notice biggest part of the functionality is related to Withdrawal Pools
 * which relies on continuous buybacks for price peg with DEBT/SURPLUS calculations
 * @dev Contracts relying on this library must initialize StakeUtils.StakePool
 * @dev ALL "fee" variables are limited by FEE_DENOMINATOR = 100%
 * Note *suggested* refer to GeodeUtils before reviewing
 * Note refer to DataStoreUtils before reviewing
 * Note beware of the staking pool and operator implementations:
 * Operatores have properties like accumulatedFee, fee(as a percentage), maintainer.
 * Every staking pool(aka planet) is also an operator by design.
 * Planets(type 5) inherit operators (type 4), with additional properties like staking pools -relates to
 * params: pBalance, surplus, unclaimedFees-, withdrawal pool - relates to debt - and liquid asset(gAvax).
 */
library StakeUtils {
  using DataStoreUtils for DataStoreUtils.DataStore;
  
  event MaintainerFeeUpdated(uint256 id, uint256 fee);
  event MaxMaintainerFeeUpdated(uint256 newMaxFee);
  event PriceChanged(uint256 id, uint256 pricePerShare);
  event OracleUpdate(
    uint256 id,
    uint256 price,
    uint256 newPBalance,
    uint256 distributedFeeTotal,
    uint256 updateTimeStamp
  );
  event OperatorActivated(uint256 id, uint256 activeOperator);
  event OperatorDeactivated(uint256 id, uint256 deactiveOperator);
  event debtPaid(uint256 id, uint256 operatorId, uint256 paidDebt);
  event SurplusClaimed(uint256 id, uint256 newSurplus);
  event FeeClaimed(uint256 id, uint256 claimerId, uint256 newSurplus);
  event PausedPool(uint256 id);
  event UnpausedPool(uint256 id);

  /**
   * @notice StakePool includes the parameters related to Staking Pool Contracts.
   * @notice A staking pool works with a *bound* Withdrawal Pool to create best pricing
   * for the staking derivative. Withdrawal Pools uses StableSwap algorithm.
   * @param gAVAX ERC1155 contract that keeps the totalSupply, pricepershare and balances of all StakingPools by ID
   * @dev  gAVAX should not be changed ever!
   * @param DEFAULT_SWAP_POOL STABLESWAP pool that will be cloned to be used as Withdrawal Pool of given ID
   * @param DEFAULT_LP_TOKEN LP token implementation that will be cloned to be used for Withdrawal Pool of given ID
   * @param ORACLE https://github.com/Geodefi/Telescope
   * @param DEFAULT_A Withdrawal Pool parameter
   * @param DEFAULT_FEE Withdrawal Pool parameter
   * @param DEFAULT_ADMIN_FEE Withdrawal Pool parameter
   * @param FEE_DENOMINATOR represents 100% ALSO Withdrawal Pool parameter
   * @param MAX_MAINTAINER_FEE : limits operator.fee and planet.fee, set by GOVERNANCE
   * @dev changing any of address parameters (gAVAX, ORACLE, DEFAULT_SWAP_POOL, DEFAULT_LP_TOKEN) MUST require a contract upgrade to ensure security
   **/
  struct StakePool {
    address gAVAX;
    address DEFAULT_SWAP_POOL;
    address DEFAULT_LP_TOKEN;
    address ORACLE;
    uint256 DEFAULT_A;
    uint256 DEFAULT_FEE;
    uint256 DEFAULT_ADMIN_FEE;
    uint256 FEE_DENOMINATOR;
    uint256 PERIOD_PRICE_INCREASE_LIMIT;
    uint256 MAX_MAINTAINER_FEE;
  }

  /**
   * @notice gAVAX lacks *decimals*,
   * @dev gAVAX_DENOMINATOR makes sure that we are taking care of decimals on calculations related to gAVAX
   */
  uint256 constant gAVAX_DENOMINATOR = 1e18;

  /// @notice Oracle is active for the first 30 min for a day
  uint256 constant ORACLE_PERIOD = 1 days;
  uint256 constant ORACLE_ACTIVE_PERIOD = 30 minutes;
  uint256 constant DEACTIVATION_PERIOD = 15 days;
  uint256 constant IGNORABLE_DEBT = 1e15;

  /**
   * @notice whenever an operator is activated for a staking pool, it sets an activationExpiration date, which
   * means the op pay debt by burning gAvax tokens and collect fee from their validators.
   * While this implementation allows any two different ids to cooperate, with multiple interactions at any given time,
   * there can only be "1" activeOperator who can also claimSurplus to create new validators.
   */
  modifier beforeActivationExpiration(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _poolId,
    uint256 _claimerId
  ) {
    require(
      _DATASTORE.readUintForId(
        _poolId,
        bytes32(keccak256(abi.encodePacked(_claimerId, "activationExpiration")))
      ) > block.timestamp,
      "StakeUtils: operatorId activationExpiration has past"
    );
    _;
  }

  modifier onlyMaintainer(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id
    ) {
    require(
      _DATASTORE.readAddressForId(_id, "maintainer") == msg.sender,
      "StakeUtils: sender not maintainer"
    );
    _;
  }

  function _clone(address target) public returns (address) {
    return Clones.clone(target);
  }

  function getgAVAX(StakePool storage self) public view returns (IgAVAX) {
    return IgAVAX(self.gAVAX);
  }

  /**
   * @notice                      ** Maintainer specific functions **
   *
   * @note "Maintainer" is a shared logic like "fee" by both operator and pools.
   * Maintainers have permissiones to maintain the given id like setting a new fee or interface as
   * well as paying debt etc. for operators.
   * @dev maintainer is set by CONTROLLER of given id
   */

  /// @notice even if MAX_MAINTAINER_FEE is decreased later, it returns limited maximum
  function getMaintainerFee(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id
  ) public view returns (uint256) {
    return
      _DATASTORE.readUintForId(_id, "fee") > self.MAX_MAINTAINER_FEE
        ? self.MAX_MAINTAINER_FEE
        : _DATASTORE.readUintForId(_id, "fee");
  }

  function setMaintainerFee(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id,
    uint256 _newFee
  ) 
  external 
  onlyMaintainer(_DATASTORE, _id)
  {
    require(
      _newFee <= self.MAX_MAINTAINER_FEE,
      "StakeUtils: MAX_MAINTAINER_FEE ERROR"
    );
    _DATASTORE.writeUintForId(_id, "fee", _newFee);
    emit MaintainerFeeUpdated(_id, _newFee);
  }

  function setMaxMaintainerFee(StakePool storage self, uint256 _newMaxFee)
    external
  {
    require(
      _newMaxFee <= self.FEE_DENOMINATOR,
      "StakeUtils: fee more than 100%"
    );
    self.MAX_MAINTAINER_FEE = _newMaxFee;
    emit MaxMaintainerFeeUpdated(_newMaxFee);
  }

  function changeMaintainer(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id,
    address _newMaintainer
  ) external {
    require(
      _DATASTORE.readAddressForId(_id, "CONTROLLER") == msg.sender,
      "StakeUtils: not CONTROLLER of given id"
    );
    require(
      _newMaintainer != address(0),
      "StakeUtils: maintainer can not be zero"
    );

    _DATASTORE.writeAddressForId(_id, "maintainer", _newMaintainer);
  }

  /**
   * @notice                      ** Staking Pool specific functions **
   */

  /// @notice mints gAVAX tokens with given ID and amount.
  /// @dev shouldn't be accesible publicly
  function _mint(
    address _gAVAX,
    address _to,
    uint256 _id,
    uint256 _amount
  ) internal {
    require(_id > 0, "StakeUtils: _mint id should be > 0");
    IgAVAX(_gAVAX).mint(_to, _id, _amount, "");
  }

  /**
   * @notice conducts a buyback using the given withdrawal pool,
   * @param to address to send bought gAVAX(id). burns the tokens if to=address(0), transfers if not
   * @param poolId id of the gAVAX that will be bought
   * @param sellAvax AVAX amount to sell
   * @param minToBuy TX is expected to revert by Swap.sol if not meet
   * @param deadline TX is expected to revert by Swap.sol if deadline has past
   * @dev this function assumes that pool is deployed by deployWithdrawalPool
   * as index 0 is avax and index 1 is Gavax
   */
  function _buyback(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    address to,
    uint256 poolId,
    uint256 sellAvax,
    uint256 minToBuy,
    uint256 deadline
  ) internal returns (uint256 outAmount) {
    // SWAP in WP
    outAmount = withdrawalPoolById(_DATASTORE, poolId).swap{ value: sellAvax }(
      0,
      1,
      sellAvax,
      minToBuy,
      deadline
    );
    if (to == address(0)) {
      // burn
      getgAVAX(self).burn(address(this), poolId, outAmount);
    } else {
      // send back to user
      getgAVAX(self).safeTransferFrom(address(this), to, poolId, outAmount, "");
    }
  }

  /**
   * @notice                      ** ORACLE specific functions **
   */

  /**
   * @notice sets pricePerShare parameter of gAVAX(id)
   * @dev only ORACLE should be able to reach this after sanity checks on new price
   */
  function _setPricePerShare(
    StakePool storage self,
    uint256 pricePerShare_,
    uint256 _id
  ) internal {
    require(_id > 0, "StakeUtils: id should be > 0");
    getgAVAX(self).setPricePerShare(pricePerShare_, _id);
    emit PriceChanged(_id, pricePerShare_);
  }

  /**
   * @notice Oracle is only allowed for a period every day & pool operations are stopped then
   * @return false if the last oracle update happened already (within the current daily period)
   */
  function _isOracleActive(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _poolId
  ) internal view returns (bool) {
    return (
				block.timestamp % ORACLE_PERIOD <= ORACLE_ACTIVE_PERIOD
			) && (
	      _DATASTORE.readUintForId(_poolId, "oracleUpdateTimeStamp") <
	      block.timestamp - ORACLE_ACTIVE_PERIOD
	    );
  }

  /**
   * @notice oraclePrice is a reliable source for any contract operation
   * @dev also the *mint price* when there is a no debt
   */
  function oraclePrice(StakePool storage self, uint256 _id)
    public
    view
    returns (uint256 _oraclePrice)
  {
    _oraclePrice = getgAVAX(self).pricePerShare(_id);
  }

  /**
   * @notice in order to prevent attacks from malicious Oracle there are boundaries to price & fee updates.
   * @dev checks:
   * 1. Price should be increased & it should not be increased more than PERIOD_PRICE_INCREASE_LIMIT
   *  with the factor of how many days since oracleUpdateTimeStamp has past.
   *  To encourage report oracle each day, price increase limit is not calculated by considering compound effect
   *  for multiple days.
   */
  function _sanityCheck(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id,
    uint256 _newPrice
  ) internal view {
    // need to put the lastPriceUpdate to DATASTORE to check if price is updated already for that day
    uint256 periodsSinceUpdate = (block.timestamp + ORACLE_ACTIVE_PERIOD - _DATASTORE.readUintForId(
      _id,
      "oracleUpdateTimeStamp"
    )) / ORACLE_PERIOD;
    uint256 curPrice = oraclePrice(self, _id);
    uint256 maxPrice = curPrice +
      ((curPrice * self.PERIOD_PRICE_INCREASE_LIMIT * periodsSinceUpdate) /
      self.FEE_DENOMINATOR);

    require(
      _newPrice <= maxPrice && _newPrice >= curPrice,
      "StakeUtils: price did NOT met"
    );
  }

  /**
   * @notice distribute fees to given operator Ids, by related to their fees.
   * Finally, distribute the fee of maintainer of the pool from total amounts.
   *
   * @dev fees can be higher than current MAX, if MAX is changed afterwards, we check that condition.
   */
  function _distributeFees(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _poolId,
    uint256[] calldata _opIds,
    uint256[] calldata _pBalanceIncreases
  ) internal returns (uint256 totalPBalanceIncrease, uint256 totalFees) {
    require(
      _opIds.length == _pBalanceIncreases.length,
      "StakeUtils: Array lengths doesn't match"
    );

    for (uint256 i = 0; i < _opIds.length; i++) {
      // do not double spend if pool maintainer is also maintaining the validators
      if (_opIds[i] != _poolId) {
        // check IdCooperation[keccak256(abi.encodePacked(_id, operator))]
        require(
          _DATASTORE.readUintForId(
            _poolId,
            bytes32(
              keccak256(abi.encodePacked(_opIds[i], "activationExpiration"))
            )
          ) > block.timestamp - ORACLE_PERIOD,
          "StakeUtils: _opId activationExpiration has past"
        );
        uint256 opFee = getMaintainerFee(self, _DATASTORE, _opIds[i]);
        (uint256 _fee, bytes32 _key) = accumulatedFee(
          _DATASTORE,
          _poolId,
          _opIds[i]
        );
        uint256 gainedOpFee = (opFee * _pBalanceIncreases[i]) /
          self.FEE_DENOMINATOR;
        _DATASTORE.writeUintForId(_poolId, _key, _fee + gainedOpFee);
        totalFees += gainedOpFee;
      }
      totalPBalanceIncrease += _pBalanceIncreases[i];
    }

    // op_fee * _pBalanceIncrease[i] to calculate respective fee from the gained increase
    uint256 poolFee = getMaintainerFee(self, _DATASTORE, _poolId);
    uint256 gainedPoolFee = (poolFee * totalPBalanceIncrease) /
      self.FEE_DENOMINATOR;

    (uint256 fee, bytes32 key) = accumulatedFee(_DATASTORE, _poolId, _poolId);
    totalFees += gainedPoolFee;
    _DATASTORE.writeUintForId(_poolId, key, fee + gainedPoolFee);
  }

  /**
   * @notice only Oracle can report a new price. However price is not purely calculated by it.
   * the balance on P subchain is estimated by it, including the unrealized staking rewards.
   * Oracle has a pessimistic approach to make sure price will not decrease by a lot even in the case of loss of funds.

   * @param _reportedTimeStamp ensures prepeared report is prepeared within last activation period, prevent previous reports to be accepted. 
   * @param _opIds all ids of all operators who still collect fees.
   * @param _pBalanceIncreases the amount of avax that has been gained by the operator as POS rewards, respective to _opIds
   * @dev simply the new price is found by (pBALANCE + surplus - fees) / totalSupply)
   * @return price : new price after sanitychecks, might be useful if onchain oracle in the future
   */
  function reportOracle(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _reportedTimeStamp,
    uint256 _poolId,
    uint256[] calldata _opIds,
    uint256[] calldata _pBalanceIncreases
  ) external returns (uint256 price) {
    require(msg.sender == self.ORACLE, "StakeUtils: msg.sender NOT oracle");
    require(
      _isOracleActive(_DATASTORE, _poolId),
      "StakeUtils: Oracle is NOT active"
    );
    require(
      _reportedTimeStamp >= block.timestamp - ORACLE_ACTIVE_PERIOD,
      "StakeUtils: Reported timestamp is NOT valid"
    );

    // distribute fees
    (uint256 totalPBalanceIncrease, uint256 totalFees) = _distributeFees(
      self,
      _DATASTORE,
      _poolId,
      _opIds,
      _pBalanceIncreases
    );

    uint256 newPBalance = _DATASTORE.readUintForId(_poolId, "pBalance") +
      totalPBalanceIncrease;
    _DATASTORE.writeUintForId(_poolId, "pBalance", newPBalance);

    uint256 unclaimed = _DATASTORE.readUintForId(_poolId, "unclaimedFees") +
      totalFees;
    _DATASTORE.writeUintForId(_poolId, "unclaimedFees", unclaimed);

    // deduct unclaimed fees from surplus
    price =
      ((newPBalance +
        _DATASTORE.readUintForId(_poolId, "surplus") -
        unclaimed) * gAVAX_DENOMINATOR) /
      (getgAVAX(self).totalSupply(_poolId));
    _sanityCheck(self, _DATASTORE, _poolId, price);
    _setPricePerShare(self, price, _poolId);

    _DATASTORE.writeUintForId(
      _poolId,
      "oracleUpdateTimeStamp",
      block.timestamp
    );
    emit OracleUpdate(_poolId, price, newPBalance, totalFees, _reportedTimeStamp);
  }

  /**
   * @notice                      ** DEBT/SURPLUS/FEE specific functions **
   */

  /**
   * @notice When a pool maintainer wants another operator's maintainer to be able to start claiming surplus and
   * creating validators, it activates the validator.
   * @notice Changes activeOperator of the given ID; old activeOperator can NOT claim surplus anymore
   * @dev However it can still continue holding its old balance until activationExpiration, and gain fees
   * @dev activationExpiration timestamp until new activeoperator continues getting fees from id's staking pool
   */
  function activateOperator(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id,
    uint256 _activeId
  ) external onlyMaintainer(_DATASTORE,_id) returns (bool) {
    _DATASTORE.writeUintForId(_id, "activeOperator", _activeId);
    _DATASTORE.writeUintForId(
      _id,
      bytes32(keccak256(abi.encodePacked(_activeId, "activationExpiration"))),
      type(uint256).max
    );
    emit OperatorActivated(_id, _activeId);
    return true;
  }

  /**
   * @notice deactivates an old operator for the given staking pool
   * @dev when activationExpiration is up, operator will NOT be able generate fees from pool,
   * it is expected for them to return the assets as surplus with payDebt function
   * @dev _deactivateAfter seconds until activation expires,
   */
  function deactivateOperator(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id,
    uint256 _deactivedId
  ) external onlyMaintainer(_DATASTORE,_id) returns (bool) {
    if (_DATASTORE.readUintForId(_id, "activeOperator") == _deactivedId)
      _DATASTORE.writeUintForId(_id, "activeOperator", 0);

    _DATASTORE.writeUintForId(
      _id,
      bytes32(
        keccak256(abi.encodePacked(_deactivedId, "activationExpiration"))
      ),
      block.timestamp + DEACTIVATION_PERIOD //15 days
    );
    emit OperatorDeactivated(_id, _deactivedId);
    return true;
  }

  /**
   * @notice Only an Operator is expected to pay for the DEBT of a staking pool.
   * When it is paid, p subChain balance decreases, effectively changing the price calculations!
   */
  function payDebt(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _poolId,
    uint256 _operatorId
  ) 
  external
  onlyMaintainer(_DATASTORE, _operatorId)
  beforeActivationExpiration(_DATASTORE, _poolId, _operatorId) 
  {
    require(
      !_isOracleActive(_DATASTORE, _poolId),
      "StakeUtils: Oracle is active"
    );

    //mgs.value should be bigger than 0 for everything to make sense
    require(msg.value > 0, "StakeUtils: no avax is sent");

    // msg.value is assined to value, value is the variable to keep how much left in my hand to continue
    // paying the rest of the debts and or how much left after paying the debts to put the rest in to surplus
    uint256 value = msg.value;
    uint256 surplus = _DATASTORE.readUintForId(_poolId, "surplus");

    // this if statement checks if there is a operation fee that needs to be paid.
    // If distributed fee exceeds the surplus, there is a gap between fees and surplus
    // so we check if the unclaimedFees are bigger than surplus.
    if(_DATASTORE.readUintForId(_poolId, "unclaimedFees") > _DATASTORE.readUintForId(_poolId, "surplus")){

      // the difference between unclaimedFees and the surplus is the debt for the fees.
      uint256 debtInFees = _DATASTORE.readUintForId(_poolId, "unclaimedFees") - _DATASTORE.readUintForId(_poolId, "surplus");

      // need to check if the debtInFees is bigger than the value, if not, can only pay value amount of debtInFees
      // if not, we are paying all debtInFees by adding it to the surplus so that the difference might be 0(zero) after this action. 
      if(debtInFees > value){
        debtInFees = value;
      }
      
      // we pay for the debtInFees as we can
      surplus += debtInFees;
      
      // we substract the debtInFees from value since we cannot use that amount to pay the rest, it is already gone.
      value -= debtInFees;
    }

    // we check if remaining value is bigger than 0 to save gas, because it may be already used
    if(value > 0){
      
      // we get the debt from the withdrawal pool
      uint256 debtToBurn = withdrawalPoolById(_DATASTORE, _poolId).getDebt();
      // to save the gas we make sure that it is bigger then an ignorably low amount while we are doing a buyback
      if(debtToBurn > IGNORABLE_DEBT){

        // same idea with the fee debt and values
        if (debtToBurn > value) {
          debtToBurn = value;
        }   
        
        // burns
        _buyback(self, _DATASTORE, address(0), _poolId, debtToBurn, 0, type(uint256).max);
        
        // we substract the debt from value to see how much left if there is any left to put it on surplus
        value -= debtToBurn; 
      }

      // to save gas we are making sure that value is bigger than zero and if so, we add it to the surplus.
      if(value > 0) {
        surplus += value;
      }
    }
    
    _DATASTORE.writeUintForId(
        _poolId,
        "surplus",
        surplus + value
      );

    // in all cases, if we pass the require msg.value > 0, that money is coming from the p chain
    // and we need to decrease the pBalance for msg.value amount
    uint256 pBalance = _DATASTORE.readUintForId(_poolId, "pBalance");
    if (pBalance > msg.value) {
      _DATASTORE.writeUintForId(
        _poolId,
        "pBalance",
        pBalance - msg.value
      );
    } else {
      _DATASTORE.writeUintForId(_poolId, "pBalance", 0);
    }

    emit debtPaid(_poolId, _operatorId, msg.value);
  }

  /**
   * @notice only authorized Operator is expected to claim the surplus of a staking pool
   * @notice current fees are not allowed to be claimed from surplus,
   * however oracle update can also make it hard since it increases unclaimedFees without touching the surplus
   */
  function claimSurplus(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _poolId,
    uint256 _claimerId
  )
    external
    onlyMaintainer(_DATASTORE, _claimerId)
    beforeActivationExpiration(_DATASTORE, _poolId, _claimerId)
    returns (bool)
  {
    require(
      !_isOracleActive(_DATASTORE, _poolId),
      "StakeUtils: Oracle is active"
    );
    uint256 fees = _DATASTORE.readUintForId(_poolId, "unclaimedFees");
    uint256 surplus = _DATASTORE.readUintForId(_poolId, "surplus");
    require(surplus > fees, "StakeUtils: pool fees exceed surplus");
    _DATASTORE.writeUintForId(_poolId, "surplus", fees);

    uint256 currentPBal = _DATASTORE.readUintForId(_poolId, "pBalance");
    _DATASTORE.writeUintForId(
      _poolId,
      "pBalance",
      currentPBal + surplus - fees
    );

    (bool sent, ) = payable(
      _DATASTORE.readAddressForId(_claimerId, "maintainer")
    ).call{ value: surplus - fees }("");
    require(sent, "StakeUtils: Failed to send Avax");
    emit SurplusClaimed(_poolId, surplus - fees);
    return sent;
  }

  /**
   * @notice accumulatedFee is stored with a key combines the poolId, claimerId & "accumulatedFee"
   * @dev function also returns the key for ease of use, please use.
   */
  function accumulatedFee(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 poolId,
    uint256 claimerId
  ) public view returns (uint256 fee, bytes32 key) {
    key = bytes32(keccak256(abi.encodePacked(claimerId, "accumulatedFee")));
    fee = _DATASTORE.readUintForId(poolId, key);
  }

  /**
   * @notice anyone can call this function, but it sends AVAX to maintainer.
   * @notice reverts if there are not enough surplus.
   */
  function claimFee(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 poolId,
    uint256 claimerId
  )
    external
    beforeActivationExpiration(_DATASTORE, poolId, claimerId)
    returns (uint256 feeToSend)
  {
    require(
      !_isOracleActive(_DATASTORE, poolId),
      "StakeUtils: Oracle is active"
    );
    (uint256 fee, bytes32 key) = accumulatedFee(_DATASTORE, poolId, claimerId);

    uint256 surplus = _DATASTORE.readUintForId(poolId, "surplus");
    require(
      fee > 0 && surplus > 0,
      "StakeUtils: fee and surplus should be bigger than zero"
    );

    feeToSend = fee > surplus ? surplus : fee;
    _DATASTORE.writeUintForId(poolId, "surplus", surplus - feeToSend);
    uint256 _unclaimedFees = _DATASTORE.readUintForId(poolId, "unclaimedFees");

    _DATASTORE.writeUintForId(
      poolId,
      "unclaimedFees",
      _unclaimedFees - feeToSend
    );

    address receiver = payable(
      _DATASTORE.readAddressForId(claimerId, "maintainer")
    );

    // set the accumulatedFee to zero
    _DATASTORE.writeUintForId(poolId, key, fee - feeToSend);

    (bool sent, ) = receiver.call{ value: feeToSend }("");
    require(sent, "StakeUtils: Failed to send Avax");
    emit FeeClaimed(poolId, claimerId, feeToSend);
  }

  /**
   * @notice                      ** WITHDRAWAL POOL specific functions **
   */

  function isStakingPausedForPool(DataStoreUtils.DataStore storage _DATASTORE, uint256 _id)
    public 
    view
    returns(bool)
  {
   // minting is paused when length != 0
   return _DATASTORE.readBytesForId(_id, "stakePaused").length != 0;
  }

  /**
   * @notice pausing only prevents new staking operations.
   * when a pool is paused for staking there are NO new funds to be minted, NO surplus.
   */ 
  function pauseStakingForPool(DataStoreUtils.DataStore storage _DATASTORE, uint256 _id)
    external
    onlyMaintainer(_DATASTORE, _id)
  {
    _DATASTORE.writeBytesForId(_id, "stakePaused", bytes("1")); // meaning true, importantly length > 0
    emit PausedPool(_id);
  }

  function unpauseStakingForPool(DataStoreUtils.DataStore storage _DATASTORE, uint256 _id)
    external
    onlyMaintainer(_DATASTORE, _id)
  {
    _DATASTORE.writeBytesForId(_id, "stakePaused", bytes("")); // meaning false, importantly length = 0
    emit UnpausedPool(_id);
  }

  function withdrawalPoolById(
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id
  ) public view returns (ISwap) {
    return ISwap(_DATASTORE.readAddressForId(_id, "withdrawalPool"));
  }

  function LPTokenById(DataStoreUtils.DataStore storage _DATASTORE, uint256 _id)
    public
    view
    returns (LPToken)
  {
    return LPToken(_DATASTORE.readAddressForId(_id, "LPToken"));
  }

  /**
   * @notice deploys a new withdrawal pool using DEFAULT_SWAP_POOL
   * @dev sets the withdrawal pool with respective
   */
  function deployWithdrawalPool(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _id
  ) external returns (address WithdrawalPool) {
    require(_id > 0, "StakeUtils: id should be > 0");
    require(
      _DATASTORE.readAddressForId(_id, "withdrawalPool") == address(0),
      "StakeUtils: withdrawalPool already exists"
    );

    WithdrawalPool = _clone(self.DEFAULT_SWAP_POOL);

    address _LPToken = ISwap(WithdrawalPool).initialize(
      address(getgAVAX(self)),
      _id,
      string(
        abi.encodePacked(
          _DATASTORE.readBytesForId(_id, "name"),
          "-Geode WP Token"
        )
      ),
      string(
        abi.encodePacked(_DATASTORE.readBytesForId(_id, "name"), "-WP")
      ),
      self.DEFAULT_A,
      self.DEFAULT_FEE,
      self.DEFAULT_ADMIN_FEE,
      self.DEFAULT_LP_TOKEN
    );

    // initially 1 AVAX = 1 AVAX
    _setPricePerShare(self, 1 ether, _id);
    _DATASTORE.writeAddressForId(_id, "withdrawalPool", WithdrawalPool);
    _DATASTORE.writeAddressForId(_id, "LPToken", _LPToken);

    // approve token so we can use it in buybacks
    getgAVAX(self).setApprovalForAll(WithdrawalPool, true);
    LPTokenById(_DATASTORE, _id).approve(WithdrawalPool, type(uint256).max);
  }

  /**
   * @notice staking function. buys if price is low, mints new tokens if a surplus is sent (extra avax through msg.value)
   * @param poolId id of the staking pool, withdrawal pool and gAVAX to be used.
   * @param minGavax swap op param
   * @param deadline swap op param
    // d  m.v
    // 100 10 => buyback
    // 100 100  => buyback
    // 10 100  =>  buyback + mint
    // 0 x => mint
   */
  function stake(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 poolId,
    uint256 minGavax,
    uint256 deadline
  ) external returns (uint256 totalgAvax) {
    require(msg.value > 0, "GeodePortal: no avax given");
    require(
      !isStakingPausedForPool(_DATASTORE, poolId),
      "StakeUtils: minting is paused"
    );
    uint256 debt = withdrawalPoolById(_DATASTORE, poolId).getDebt();
    if (debt >= msg.value) {
      return
        _buyback(
          self,
          _DATASTORE,
          msg.sender,
          poolId,
          msg.value,
          minGavax,
          deadline
        );
    } else {
      uint256 boughtGavax = 0;
      if (debt > IGNORABLE_DEBT) {
        boughtGavax = _buyback(
          self,
          _DATASTORE,
          msg.sender,
          poolId,
          debt,
          0,
          deadline
        );
      }
      uint256 remAvax = msg.value - debt;
      uint256 mintGavax = (
        ((remAvax * gAVAX_DENOMINATOR) / oraclePrice(self, poolId))
      );
      _mint(self.gAVAX, msg.sender, poolId, mintGavax);
      _DATASTORE.writeUintForId(
        poolId,
        "surplus",
        _DATASTORE.readUintForId(poolId, "surplus") + remAvax
      );
      require(
        boughtGavax + mintGavax >= minGavax,
        "StakeUtils: less than minGavax"
      );
      return boughtGavax + mintGavax;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "../Portal/utils/DataStoreLib.sol";
import "../Portal/utils/GeodeUtilsLib.sol";
import "../Portal/utils/StakeUtilsLib.sol";
import "../interfaces/IgAVAX.sol";

interface IPortal {
  function initialize(
    address _GOVERNANCE,
    address _ORACLE,
    address _gAVAX,
    address _DEFAULT_SWAP_POOL,
    address _DEFAULT_INTERFACE,
    address _DEFAULT_LP_TOKEN
  ) external;

  function pause() external;

  function unpause() external;

  function getVersion() external view returns (uint256);

  function gAVAX() external view returns (address);

  function getSenate() external view returns (address);

  function getGovernance() external view returns (address);

  function getOperationFee() external view returns (uint256);

  function getMaxOperationFee() external view returns (uint256);

  function getSenateExpireTimestamp() external view returns (uint256);

  function getFeeDenominator() external view returns (uint256);

  function getStakePoolParams()
    external
    view
    returns (StakeUtils.StakePool memory);

  function getIdsByType(uint256 _type) external view returns (uint256[] memory);

  function getIdFromName(string calldata _name)
    external
    pure
    returns (uint256 _id);

  function getNameFromId(uint256 _id) external view returns (bytes memory);

  function getCONTROLLERFromId(uint256 _id) external view returns (address);

  function getMaintainerFromId(uint256 _id) external view returns (address);

  function getMaintainerFeeFromId(uint256 _id) external view returns (uint256);

  function setMaintainerFee(uint256 _id, uint256 _newFee) external;

  function planetCurrentInterface(uint256 _id) external view returns (address);

  function planetWithdrawalPool(uint256 _id) external view returns (address);

  function planetLPToken(uint256 _id) external view returns (address);

  function planetActiveOperator(uint256 _id) external view returns (uint256);

  function changeIdCONTROLLER(uint256 _id, address _newCONTROLLER) external;

  function changeIdMaintainer(uint256 _id, address _newMaintainer) external;

  function setOperationFee(uint256 _newFee) external returns (bool success);

  function setMaxOperationFee(uint256 _newFee) external returns (bool success);

  function setMaxMaintainerFee(uint256 _newFee) external;

  function setDefaultInterface(address _newDefault) external;

  function activateOperator(uint256 _id, uint256 _activeId)
    external
    returns (bool);

  function deactivateOperator(uint256 _id, uint256 _deactivedId)
    external
    returns (bool);

  function setPlanetInterface(
    uint256 _id,
    address _Interface,
    bool isSet
  ) external;

  function setOperatorPBank(uint256 id, bytes memory pBank) external;

  function operatorPBank(uint256 id) external view returns (bytes memory);

  function getProposal(uint256 id)
    external
    view
    returns (GeodeUtils.Proposal memory);

  function newProposal(
    address _CONTROLLER,
    uint256 _type,
    uint256 _proposalDuration,
    bytes calldata _name
  ) external;

  function approveProposal(uint256 _id) external;

  function approveSenate(uint256 proposalId, uint256 electorId) external;

  function planetOraclePrice(uint256 _id)
    external
    view
    returns (uint256 _pricePershare);

  function isOracleActive(uint256 _planetId) external view returns (bool);

  function reportOracle(
    uint256 _reportedTimeStamp,
    uint256 _planetId,
    uint256[] memory _opIds,
    uint256[] memory _pBalanceIncreases
  ) external returns (uint256 price);

  function planetSurplus(uint256 planetId) external view returns (uint256);

  function planetClaimableSurplus(uint256 planetId) external returns (uint256);

  function planetDebt(uint256 planetId)
    external
    view
    returns (uint256 debtInAvax);

  function planetPBalance(uint256 planetId) external view returns (uint256);

  function payDebt(uint256 planetId, uint256 operatorId) external payable;

  function claimSurplus(uint256 planetId) external returns (bool success);

  function accumulatedFee(uint256 planetId, uint256 claimerId)
    external
    view
    returns (uint256);

  function claimFee(uint256 planetId, uint256 claimerId)
    external
    returns (uint256 feeToSend);
    
  function isStakingPausedForPool(uint256 _id)
    external
    view
    returns (bool);

  function pauseStakingForPool(uint256 id) external;

  function unpauseStakingForPool(uint256 id) external;

  function stake(
    uint256 planetId,
    uint256 minGavax,
    uint256 deadline
  ) external payable returns (uint256 totalgAvax);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "./IgAVAX.sol";

interface ISwap {
    // pool data view functions
    function getERC1155() external view returns (address);

    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getToken() external view returns (uint256);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function getDebt() external view returns (uint256);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        address _gAvax,
        uint256 _pooledTokenId,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        address lpTokenTargetAddress
    ) external returns (address lpToken);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external payable returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external payable returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IgAVAX {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function uri(uint256) external view returns (string memory);

  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    external
    view
    returns (uint256[] memory);

  function isInterface(address operator, uint256 id)
    external
    view
    returns (bool);

  function setApprovalForAll(address operator, bool approved) external;

  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) external;

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) external;

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function pause() external;

  function unpause() external;

  function exists(uint256 id) external view returns (bool);

  function pricePerShare(uint256 _id) external view returns (uint256);

  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function setPricePerShare(uint256 pricePerShare_, uint256 _id) external;

  function setInterface(
    address _Interface,
    uint256 id,
    bool isSet
  ) external;

  function totalSupply(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/ISwap.sol";

/**
 * @title Liquidity Provider Token
 * @notice This token is an ERC20 detailed token with added capability to be minted by the owner.
 * It is used to represent user's shares when providing liquidity to swap contracts.
 * @dev Only Swap contracts should initialize and own LPToken contracts.
 */
contract LPToken is ERC20BurnableUpgradeable, OwnableUpgradeable {
  /**
   * @notice Initializes this LPToken contract with the given name and symbol
   * @dev The caller of this function will become the owner. A Swap contract should call this
   * in its initializer function.
   * @param name name of this token
   * @param symbol symbol of this token
   */
  function initialize(string memory name, string memory symbol)
    external
    initializer
    returns (bool)
  {
    __Context_init_unchained();
    __ERC20_init_unchained(name, symbol);
    __Ownable_init_unchained();
    return true;
  }

  /**
   * @notice Mints the given amount of LPToken to the recipient.
   * @dev only owner can call this mint function
   * @param recipient address of account to receive the tokens
   * @param amount amount of tokens to mint
   */
  function mint(address recipient, uint256 amount) external onlyOwner {
    require(amount != 0, "LPToken: cannot mint 0");
    _mint(recipient, amount);
  }

  /**
   * @dev Overrides ERC20._beforeTokenTransfer() which get called on every transfers including
   * minting and burning. This ensures that Swap.updateUserWithdrawFees are called everytime.
   * This assumes the owner is set to a Swap contract's address.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable) {
    super._beforeTokenTransfer(from, to, amount);
    require(to != address(this), "LPToken: cannot send to itself");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "../../interfaces/IgAVAX.sol";
import "./AmplificationUtils.sol";
import "../LPToken.sol";
import "./MathUtils.sol";

/**
 * @title SwapUtils library
 * @notice A library to be used within Swap.sol. Contains functions responsible for custody and AMM functionalities.
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 */
library SwapUtils {
  using MathUtils for uint256;

  /*** EVENTS ***/

  event TokenSwap(
    address indexed buyer,
    uint256 tokensSold,
    uint256 tokensBought,
    uint128 soldId,
    uint128 boughtId
  );
  event AddLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event RemoveLiquidity(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256 lpTokenSupply
  );
  event RemoveLiquidityOne(
    address indexed provider,
    uint256 lpTokenAmount,
    uint256 lpTokenSupply,
    uint256 boughtId,
    uint256 tokensBought
  );
  event RemoveLiquidityImbalance(
    address indexed provider,
    uint256[] tokenAmounts,
    uint256[] fees,
    uint256 invariant,
    uint256 lpTokenSupply
  );
  event NewAdminFee(uint256 newAdminFee);
  event NewSwapFee(uint256 newSwapFee);

  struct Swap {
    // variables around the ramp management of A,
    // the amplification coefficient * n * (n - 1)
    // see https://curve.fi/stableswap-paper.pdf for details
    uint256 initialA;
    uint256 futureA;
    uint256 initialATime;
    uint256 futureATime;
    // fee calculation
    uint256 swapFee;
    uint256 adminFee;
    LPToken lpToken;
    uint256 pooledTokenId;
    // wETH2 contract reference
    IgAVAX referenceForPooledTokens;
    // the pool balance of each token
    // the contract's actual token balance might differ
    uint256[] balances;
  }

  // Struct storing variables used in calculations in the
  // calculateWithdrawOneTokenDY function to avoid stack too deep errors
  struct CalculateWithdrawOneTokenDYInfo {
    uint256 d0;
    uint256 d1;
    uint256 newY;
    uint256 feePerToken;
    uint256 preciseA;
  }

  // Struct storing variables used in calculations in the
  // {add,remove}Liquidity functions to avoid stack too deep errors
  struct ManageLiquidityInfo {
    uint256 d0;
    uint256 d1;
    uint256 d2;
    uint256 preciseA;
    LPToken lpToken;
    uint256 totalSupply;
    uint256[] balances;
  }

  // the precision all pools tokens will be converted to
  uint8 public constant POOL_PRECISION_DECIMALS = 18;

  // the denominator used to calculate admin and LP fees. For example, an
  // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
  uint256 private constant FEE_DENOMINATOR = 10**10;

  // Max swap fee is 1% or 100bps of each swap
  uint256 public constant MAX_SWAP_FEE = 10**8;

  // Max adminFee is 100% of the swapFee
  // adminFee does not add additional fee on top of swapFee
  // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
  // users but only on the earnings of LPs
  uint256 public constant MAX_ADMIN_FEE = 10**10;

  // Constant value used as max loop limit
  uint256 private constant MAX_LOOP_LIMIT = 256;

  /*** VIEW & PURE FUNCTIONS ***/

  function _getAPrecise(Swap storage self) internal view returns (uint256) {
    return AmplificationUtils._getAPrecise(self);
  }

  /// @dev this function assumes prices are sent with the indexes that [avax,Gavax]
  function _pricedInBatch(Swap storage self, uint256[] memory balances)
    internal
    view
    returns (uint256[] memory)
  {
    uint256[] memory _p = new uint256[](balances.length);
    _p[0] = balances[0];
    _p[1] = balances[1]
      * IgAVAX(self.referenceForPooledTokens).pricePerShare(self.pooledTokenId)/1e18;
    return _p;
  }

  function _pricedOut(
    Swap storage self,
    uint256 balance,
    uint256 i
  ) internal view returns (uint256) {
    return i == 1 ? balance * 1e18 / IgAVAX(self.referenceForPooledTokens).pricePerShare(self.pooledTokenId) : balance;
  }

  function _pricedIn(
    Swap storage self,
    uint256 balance,
    uint256 i
  ) internal view returns (uint256) {
    return i == 1 ? balance * IgAVAX(self.referenceForPooledTokens).pricePerShare(self.pooledTokenId) / 1e18 : balance;
  }

  /// @dev this function assumes prices are sent with the indexes that [avax,Gavax]
  function _pricedOutBatch(Swap storage self, uint256[] memory balances)
    internal
    view
    returns (uint256[] memory)
  {
    uint256[] memory _p = new uint256[](balances.length);
    _p[0] = balances[0];
    _p[1] = balances[1] * 1e18 /
      IgAVAX(self.referenceForPooledTokens).pricePerShare(self.pooledTokenId);
    return _p;
  }

  /**
   * @notice Calculate the dy, the amount of selected token that user receives and
   * the fee of withdrawing in one token
   * @param tokenAmount the amount to withdraw in the pool's precision
   * @param tokenIndex which token will be withdrawn
   * @param self Swap struct to read from
   * @return the amount of token user will receive
   */
  function calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex
  ) external view returns (uint256) {
    (uint256 availableTokenAmount, ) = _calculateWithdrawOneToken(
      self,
      tokenAmount,
      tokenIndex,
      self.lpToken.totalSupply()
    );
    return availableTokenAmount;
  }

  function _calculateWithdrawOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 totalSupply
  ) internal view returns (uint256, uint256) {
    uint256 dy;
    uint256 newY;
    uint256 currentY;

    (dy, newY, currentY) = calculateWithdrawOneTokenDY(
      self,
      tokenIndex,
      tokenAmount,
      totalSupply
    );

    // dy_0 (without fees)
    // dy, dy_0 - dy

    uint256 dySwapFee = currentY - newY - dy;

    return (dy, dySwapFee);
  }

  /**
   * @notice Calculate the dy of withdrawing in one token
   * @param self Swap struct to read from
   * @param tokenIndex which token will be withdrawn
   * @param tokenAmount the amount to withdraw in the pools precision
   * @return the d and the new y after withdrawing one token
   */
  function calculateWithdrawOneTokenDY(
    Swap storage self,
    uint8 tokenIndex,
    uint256 tokenAmount,
    uint256 totalSupply
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Get the current D, then solve the stableswap invariant
    // y_i for D - tokenAmount

    require(tokenIndex < 2, "Token index out of range");

    CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(
      0,
      0,
      0,
      0,
      0
    );
    v.preciseA = _getAPrecise(self);
    v.d0 = getD(_pricedInBatch(self, self.balances), v.preciseA);
    v.d1 = v.d0 - ((tokenAmount * v.d0) / totalSupply);

    require(
      tokenAmount <= self.balances[tokenIndex],
      "Withdraw exceeds available"
    );

    v.newY = _pricedOut(
      self,
      getYD(v.preciseA, tokenIndex, _pricedInBatch(self, self.balances), v.d1),
      tokenIndex
    );

    uint256[] memory xpReduced = new uint256[](2);

    v.feePerToken = self.swapFee / 2;
    for (uint256 i = 0; i < 2; i++) {
      uint256 xpi = self.balances[i];
      // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
      // else dxExpected = xp[i] - (xp[i] * d1 / d0)
      // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
      xpReduced[i] =
        xpi -
        (((
          (i == tokenIndex)
            ? (xpi * v.d1) / v.d0 - v.newY
            : xpi - ((xpi * v.d1) / (v.d0))
        ) * (v.feePerToken)) / (FEE_DENOMINATOR));
    }

    uint256 dy = xpReduced[tokenIndex] -
      _pricedOut(
        self,
        (getYD(v.preciseA, tokenIndex, _pricedInBatch(self, xpReduced), v.d1)),
        tokenIndex
      );
    dy = dy - 1;

    return (dy, v.newY, self.balances[tokenIndex]);
  }

  /**
   * @notice Get Debt, The amount of buyback for stable pricing.
   * @param xp a  set of pool balances. Array should be the same cardinality
   * as the pool.
   * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
   * See the StableSwap paper for details
   * @return debt the half of the D StableSwap invariant when debt is needed to be payed.
   */
  function _getDebt(Swap storage self, uint256[] memory xp, uint256 a)
    internal
    view
    returns (uint256)
  {
    uint256 halfD = getD(xp, a) / 2;
    if (xp[0] >= halfD) {
      return 0;
    } else {
      uint256 dy = xp[1] - halfD;
      uint256 feeHalf = (dy * self.swapFee )/ FEE_DENOMINATOR / 2;
      uint256 debt =halfD - xp[0] + feeHalf ;
      return debt;
    }
  }

  /**
   * @return debt the half of the D StableSwap invariant when debt is needed to be payed.
   */
  function getDebt(Swap storage self) external view returns (uint256) {
    // might change when price is in.
    return _getDebt(self, _pricedInBatch(self, self.balances), _getAPrecise(self));
  }

  /**
   * @notice Calculate the price of a token in the pool with given
   *  balances and a particular D.
   *
   * @dev This is accomplished via solving the invariant iteratively.
   * See the StableSwap paper and Curve.fi implementation for further details.
   *
   * x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
   * x_1**2 + b*x_1 = c
   * x_1 = (x_1**2 + c) / (2*x_1 + b)
   *
   * @param a the amplification coefficient * n * (n - 1). See the StableSwap paper for details.
   * @param tokenIndex Index of token we are calculating for.
   * @param xp a  set of pool balances. Array should be
   * the same cardinality as the pool.
   * @param d the stableswap invariant
   * @return the price of the token, in the same precision as in xp
   */
  function getYD(
    uint256 a,
    uint8 tokenIndex,
    uint256[] memory xp,
    uint256 d
  ) internal pure returns (uint256) {
    uint256 numTokens = 2;
    require(tokenIndex < numTokens, "Token not found");

    uint256 c = d;
    uint256 s;
    uint256 nA = a * numTokens;

    for (uint256 i = 0; i < numTokens; i++) {
      if (i != tokenIndex) {
        s = s + xp[i];
        c = (c * d) / (xp[i] * (numTokens));
        // If we were to protect the division loss we would have to keep the denominator separate
        // and divide at the end. However this leads to overflow with large numTokens or/and D.
        // c = c * D * D * D * ... overflow!
      }
    }
    c = (c * d * AmplificationUtils.A_PRECISION) / (nA * numTokens);

    uint256 b = s + ((d * AmplificationUtils.A_PRECISION) / nA);
    uint256 yPrev;
    uint256 y = d;
    for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
      yPrev = y;
      y = ((y * y) + c) / (2 * y + b - d);
      if (y.within1(yPrev)) {
        return y;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
   * @param xp a  set of pool balances. Array should be the same cardinality
   * as the pool.
   * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
   * See the StableSwap paper for details
   * @return the invariant, at the precision of the pool
   */
  function getD(uint256[] memory xp, uint256 a)
    internal
    pure
    returns (uint256)
  {
    uint256 numTokens = 2;
    uint256 s = xp[0] + xp[1];
    if (s == 0) {
      return 0;
    }

    uint256 prevD;
    uint256 d = s;
    uint256 nA = a * numTokens;

    for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
      uint256 dP = (d**(numTokens + 1)) /
        (numTokens**numTokens * xp[0] * xp[1]);
      prevD = d;
      d =
        ((((nA * s) / AmplificationUtils.A_PRECISION) + dP * numTokens) * (d)) /
        (((nA - AmplificationUtils.A_PRECISION) * (d)) /
          (AmplificationUtils.A_PRECISION) +
          ((numTokens + 1) * dP));

      if (d.within1(prevD)) {
        return d;
      }
    }

    // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
    // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
    // function which does not rely on D.
    revert("D does not converge");
  }

  /**
   * @notice Get the virtual price, to help calculate profit
   * @param self Swap struct to read from
   * @return the virtual price, scaled to precision of POOL_PRECISION_DECIMALS
   */
  function getVirtualPrice(Swap storage self) external view returns (uint256) {
    uint256 d = getD(_pricedInBatch(self, self.balances), _getAPrecise(self));
    LPToken lpToken = self.lpToken;
    uint256 supply = lpToken.totalSupply();
    if (supply > 0) {
      return (d * 10**uint256(POOL_PRECISION_DECIMALS)) / supply;
    }
    return 0;
  }

  /**
   * @notice Calculate the new balances of the tokens given the indexes of the token
   * that is swapped from (FROM) and the token that is swapped to (TO).
   * This function is used as a helper function to calculate how much TO token
   * the user should receive on swap.
   *
   * @param preciseA precise form of amplification coefficient
   * @param tokenIndexFrom index of FROM token
   * @param tokenIndexTo index of TO token
   * @param x the new total amount of FROM token
   * @param xp balances of the tokens in the pool
   * @return the amount of TO token that should remain in the pool
   */
  function getY(
    uint256 preciseA,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 x,
    uint256[] memory xp
  ) internal pure returns (uint256) {
    uint256 numTokens = 2;
    require(tokenIndexFrom != tokenIndexTo, "Can't compare token to itself");
    require(
      tokenIndexFrom < numTokens && tokenIndexTo < numTokens,
      "Tokens must be in pool"
    );

    uint256 d = getD(xp, preciseA);
    uint256 c = d;
    uint256 s = x;
    uint256 nA = numTokens * (preciseA);

    c = (c * d) / (x * numTokens);
    c = (c * d * (AmplificationUtils.A_PRECISION)) / (nA * numTokens);
    uint256 b = s + ((d * AmplificationUtils.A_PRECISION) / nA);

    uint256 yPrev;
    uint256 y = d;
    for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
      yPrev = y;
      y = ((y * y) + c) / (2 * y + b - d);
      if (y.within1(yPrev)) {
        return y;
      }
    }
    revert("Approximation did not converge");
  }

  /**
   * @notice Externally calculates a swap between two tokens.
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get
   */
  function calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx
  ) external view returns (uint256 dy) {
    (dy, ) = _calculateSwap(
      self,
      tokenIndexFrom,
      tokenIndexTo,
      dx,
      self.balances
    );
  }

  /**
   * @notice Internally calculates a swap between two tokens.
   *
   * @dev The caller is expected to transfer the actual amounts (dx and dy)
   * using the token contracts.
   *
   * @param self Swap struct to read from
   * @param tokenIndexFrom the token to sell
   * @param tokenIndexTo the token to buy
   * @param dx the number of tokens to sell. If the token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @return dy the number of tokens the user will get
   * @return dyFee the associated fee
   */
  function _calculateSwap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256[] memory balances
  ) internal view returns (uint256 dy, uint256 dyFee) {
    require(
      tokenIndexFrom < balances.length && tokenIndexTo < balances.length,
      "Token index out of range"
    );
    uint256 x = _pricedIn(self, dx + balances[tokenIndexFrom], tokenIndexFrom);

    uint256[] memory pricedBalances = _pricedInBatch(self, balances);

    uint256 y = _pricedOut(
      self,
      getY(_getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, pricedBalances),
      tokenIndexTo // => not id, index !!!
    );
    dy = balances[tokenIndexTo] - y - 1;
    dyFee = (dy * self.swapFee) / (FEE_DENOMINATOR);
    dy = dy - dyFee;
  }

  /**
   * @notice A simple method to calculate amount of each underlying
   * tokens that is returned upon burning given amount of
   * LP tokens
   *
   * @param amount the amount of LP tokens that would to be burned on
   * withdrawal
   * @return array of amounts of tokens user will receive
   */
  function calculateRemoveLiquidity(Swap storage self, uint256 amount)
    external
    view
    returns (uint256[] memory)
  {
    return
      _pricedOutBatch(
        self,
        _calculateRemoveLiquidity(
          _pricedInBatch(self, self.balances),
          amount,
          self.lpToken.totalSupply()
        )
      );
  }

  function _calculateRemoveLiquidity(
    uint256[] memory balances,
    uint256 amount,
    uint256 totalSupply
  ) internal pure returns (uint256[] memory) {
    require(amount <= totalSupply, "Cannot exceed total supply");

    uint256[] memory amounts = new uint256[](2);

    amounts[0] = (balances[0] * amount) / totalSupply;
    amounts[1] = (balances[1] * amount) / totalSupply;

    return amounts;
  }

  /**
   * @notice A simple method to calculate prices from deposits or
   * withdrawals, excluding fees but including slippage. This is
   * helpful as an input into the various "min" parameters on calls
   * to fight front-running
   *
   * @dev This shouldn't be used outside frontends for user estimates.
   *
   * @param self Swap struct to read from
   * @param amounts an array of token amounts to deposit or withdrawal,
   * corresponding to pooledTokens. The amount should be in each
   * pooled token's native precision. If a token charges a fee on transfers,
   * use the amount that gets transferred after the fee.
   * @param deposit whether this is a deposit or a withdrawal
   * @return if deposit was true, total amount of lp token that will be minted and if
   * deposit was false, total amount of lp token that will be burned
   */
  function calculateTokenAmount(
    Swap storage self,
    uint256[] calldata amounts,
    bool deposit
  ) external view returns (uint256) {
    uint256 a = _getAPrecise(self);
    uint256[] memory balances = self.balances;

    uint256 d0 = getD(_pricedInBatch(self, balances), a);
    for (uint256 i = 0; i < balances.length; i++) {
      if (deposit) {
        balances[i] = balances[i] + amounts[i];
      } else {
        require(
          amounts[i] <= balances[i],
          "Cannot withdraw more than available"
        );
        balances[i] = balances[i] - amounts[i];
      }
    }
    uint256 d1 = getD(_pricedInBatch(self, balances), a);
    uint256 totalSupply = self.lpToken.totalSupply();

    if (deposit) {
      return ((d1 - d0) * totalSupply) / d0;
    } else {
      return ((d0 - d1) * totalSupply) / d0;
    }
  }

  /**
   * @notice return accumulated amount of admin fees of the token with given index
   * @param self Swap struct to read from
   * @param index Index of the pooled token
   * @return admin balance in the token's precision
   */
  function getAdminBalance(Swap storage self, uint256 index)
    external
    view
    returns (uint256)
  {
    require(index < 2, "Token index out of range");
    if (index == 0) return address(this).balance - (self.balances[index]);

    if (index == 1)
      return
        self.referenceForPooledTokens.balanceOf(
          address(this),
          self.pooledTokenId
        ) - (self.balances[index]);
    return 0;
  }

  /*** STATE MODIFYING FUNCTIONS ***/

  /**
   * @notice swap two tokens in the pool
   * @param self Swap struct to read from and write to
   * @param tokenIndexFrom the token the user wants to sell
   * @param tokenIndexTo the token the user wants to buy
   * @param dx the amount of tokens the user wants to sell
   * @param minDy the min amount the user would like to receive, or revert.
   * @return amount of token user received on swap
   */
  function swap(
    Swap storage self,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy
  ) external returns (uint256) {
    IgAVAX wETH2Reference = self.referenceForPooledTokens;
    if (tokenIndexFrom == 0) {
      require(dx == msg.value, "Cannot swap more/less than you sent");
    }
    if (tokenIndexFrom == 1) {
      uint256 tokenId = self.pooledTokenId;
      require(
        dx <= wETH2Reference.balanceOf(msg.sender, tokenId),
        "Cannot swap more than you own"
      );

      // Transfer tokens first
      uint256 beforeBalance = wETH2Reference.balanceOf(address(this), tokenId);
      wETH2Reference.safeTransferFrom(
        msg.sender,
        address(this),
        tokenId,
        dx,
        ""
      );

      // Use the actual transferred amount for AMM math
      dx = wETH2Reference.balanceOf(address(this), tokenId) - beforeBalance;
    }

    uint256 dy;
    uint256 dyFee;
    uint256[] memory balances = self.balances;
    (dy, dyFee) = _calculateSwap(
      self,
      tokenIndexFrom,
      tokenIndexTo,
      dx,
      balances
    );

    require(dy >= minDy, "Swap didn't result in min tokens");

    uint256 dyAdminFee = (dyFee * self.adminFee) / FEE_DENOMINATOR;

    self.balances[tokenIndexFrom] = balances[tokenIndexFrom] + dx;
    self.balances[tokenIndexTo] = balances[tokenIndexTo] - dy - dyAdminFee;

    if (tokenIndexTo == 0) {
      (bool sent, ) = payable(msg.sender).call{ value: dy }("");
      require(sent, "SwapUtils: Failed to send Avax");
    }
    if (tokenIndexTo == 1) {
      wETH2Reference.safeTransferFrom(
        address(this),
        msg.sender,
        self.pooledTokenId,
        dy,
        ""
      );
    }
    emit TokenSwap(msg.sender, dx, dy, tokenIndexFrom, tokenIndexTo);

    return dy;
  }

  /**
   * @notice Add liquidity to the pool
   * @param self Swap struct to read from and write to
   * @param amounts the amounts of each token to add, in their native precision
   * @param minToMint the minimum LP tokens adding this amount of liquidity
   * should mint, otherwise revert. Handy for front-running mitigation
   * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
   * @return amount of LP token user received
   */
  function addLiquidity(
    Swap storage self,
    uint256[] memory amounts,
    uint256 minToMint
  ) external returns (uint256) {
    require(amounts.length == 2, "Amounts must match pooled tokens");
    require(
      amounts[0] == msg.value,
      "SwapUtils: received less or more AVAX than expected"
    );
    IgAVAX wETH2Reference = self.referenceForPooledTokens;
    // current state
    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      0,
      0,
      0,
      _getAPrecise(self),
      self.lpToken,
      0,
      self.balances
    );
    v.totalSupply = v.lpToken.totalSupply();
    if (v.totalSupply != 0) {
      v.d0 = getD(_pricedInBatch(self, v.balances), v.preciseA);
    }

    uint256[] memory newBalances = new uint256[](2);
    newBalances[0] = v.balances[0] + msg.value;

    for (uint256 i = 0; i < 2; i++) {
      require(
        v.totalSupply != 0 || amounts[i] > 0,
        "Must supply all tokens in pool"
      );
    }

    {
      // Transfer tokens first
      uint256 beforeBalance = wETH2Reference.balanceOf(
        address(this),
        self.pooledTokenId
      );
      wETH2Reference.safeTransferFrom(
        msg.sender,
        address(this),
        self.pooledTokenId,
        amounts[1],
        ""
      );

      // Update the amounts[] with actual transfer amount
      amounts[1] =
        wETH2Reference.balanceOf(address(this), self.pooledTokenId) -
        beforeBalance;

      newBalances[1] = v.balances[1] + amounts[1];
    }

    // invariant after change
    v.d1 = getD(_pricedInBatch(self, newBalances), v.preciseA);
    require(v.d1 > v.d0, "D should increase");

    // updated to reflect fees and calculate the user's LP tokens
    v.d2 = v.d1;
    uint256[] memory fees = new uint256[](2);

    if (v.totalSupply != 0) {
      uint256 feePerToken = self.swapFee / 2;
      for (uint256 i = 0; i < 2; i++) {
        uint256 idealBalance = (v.d1 * v.balances[i]) / v.d0;
        fees[i] =
          (feePerToken * (idealBalance.difference(newBalances[i]))) /
          (FEE_DENOMINATOR);
        self.balances[i] =
          newBalances[i] -
          ((fees[i] * (self.adminFee)) / (FEE_DENOMINATOR));
        newBalances[i] = newBalances[i] - (fees[i]);
      }
      v.d2 = getD(_pricedInBatch(self, newBalances), v.preciseA);
    } else {
      // the initial depositor doesn't pay fees
      self.balances = newBalances;
    }

    uint256 toMint;
    if (v.totalSupply == 0) {
      toMint = v.d1;
    } else {
      toMint = ((v.d2 - v.d0) * v.totalSupply) / v.d0;
    }

    require(toMint >= minToMint, "Couldn't mint min requested");

    // mint the user's LP tokens
    v.lpToken.mint(msg.sender, toMint);

    emit AddLiquidity(msg.sender, amounts, fees, v.d1, v.totalSupply + toMint);
    return toMint;
  }

  /**
   * @notice Burn LP tokens to remove liquidity from the pool.
   * @dev Liquidity can always be removed, even when the pool is paused.
   * @param self Swap struct to read from and write to
   * @param amount the amount of LP tokens to burn
   * @param minAmounts the minimum amounts of each token in the pool
   * acceptable for this burn. Useful as a front-running mitigation
   * @return amounts of tokens the user received
   */
  function removeLiquidity(
    Swap storage self,
    uint256 amount,
    uint256[] calldata minAmounts
  ) external returns (uint256[] memory) {
    LPToken lpToken = self.lpToken;
    IgAVAX wETH2Reference = self.referenceForPooledTokens;
    require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    require(minAmounts.length == 2, "minAmounts must match poolTokens");

    uint256[] memory balances = self.balances;
    uint256 totalSupply = lpToken.totalSupply();

    uint256[] memory amounts = _pricedOutBatch(
      self,
      _calculateRemoveLiquidity(
        _pricedInBatch(self, balances),
        amount,
        totalSupply
      )
    );

    for (uint256 i = 0; i < amounts.length; i++) {
      require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
      self.balances[i] = balances[i] - amounts[i];
    }

    lpToken.burnFrom(msg.sender, amount);
    (bool sent, ) = payable(msg.sender).call{ value: amounts[0] }("");
    require(sent, "SwapUtils: Failed to send Avax");
    wETH2Reference.safeTransferFrom(
      address(this),
      msg.sender,
      self.pooledTokenId,
      amounts[1],
      ""
    );

    emit RemoveLiquidity(msg.sender, amounts, totalSupply - amount);
    return amounts;
  }

  /**
   * @notice Remove liquidity from the pool all in one token.
   * @param self Swap struct to read from and write to
   * @param tokenAmount the amount of the lp tokens to burn
   * @param tokenIndex the index of the token you want to receive
   * @param minAmount the minimum amount to withdraw, otherwise revert
   * @return amount chosen token that user received
   */
  function removeLiquidityOneToken(
    Swap storage self,
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount
  ) external returns (uint256) {
    LPToken lpToken = self.lpToken;
    IgAVAX wETH2Reference = self.referenceForPooledTokens;

    require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
    require(tokenIndex < 2, "Token not found");

    uint256 totalSupply = lpToken.totalSupply();

    (uint256 dy, uint256 dyFee) = _calculateWithdrawOneToken(
      self,
      tokenAmount,
      tokenIndex,
      totalSupply
    );

    require(dy >= minAmount, "dy < minAmount");

    self.balances[tokenIndex] =
      self.balances[tokenIndex] -
      (dy + ((dyFee * (self.adminFee)) / (FEE_DENOMINATOR)));
    lpToken.burnFrom(msg.sender, tokenAmount);

    if (tokenIndex == 0) {
      (bool sent, ) = payable(msg.sender).call{ value: dy }("");
      require(sent, "SwapUtils: Failed to send Avax");
    }
    if (tokenIndex == 1) {
      wETH2Reference.safeTransferFrom(
        address(this),
        msg.sender,
        self.pooledTokenId,
        dy,
        ""
      );
    }

    emit RemoveLiquidityOne(
      msg.sender,
      tokenAmount,
      totalSupply,
      tokenIndex,
      dy
    );

    return dy;
  }

  /**
   * @notice Remove liquidity from the pool, weighted differently than the
   * pool's current balances.
   *
   * @param self Swap struct to read from and write to
   * @param amounts how much of each token to withdraw
   * @param maxBurnAmount the max LP token provider is willing to pay to
   * remove liquidity. Useful as a front-running mitigation.
   * @return actual amount of LP tokens burned in the withdrawal
   */
  function removeLiquidityImbalance(
    Swap storage self,
    uint256[] memory amounts,
    uint256 maxBurnAmount
  ) public returns (uint256) {
    IgAVAX wETH2Reference = self.referenceForPooledTokens;

    ManageLiquidityInfo memory v = ManageLiquidityInfo(
      0,
      0,
      0,
      _getAPrecise(self),
      self.lpToken,
      0,
      self.balances
    );
    v.totalSupply = v.lpToken.totalSupply();

    require(amounts.length == 2, "Amounts should match pool tokens");

    require(
      maxBurnAmount <= v.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0,
      ">LP.balanceOf"
    );

    uint256 feePerToken = self.swapFee / 2;
    uint256[] memory fees = new uint256[](2);

    {
      uint256[] memory balances1 = new uint256[](2);

      v.d0 = getD(_pricedInBatch(self, v.balances), v.preciseA);
      for (uint256 i = 0; i < 2; i++) {
        require(
          amounts[i] <= v.balances[i],
          "Cannot withdraw more than available"
        );
        balances1[i] = v.balances[i] - amounts[i];
      }
      v.d1 = getD(_pricedInBatch(self, balances1), v.preciseA);

      for (uint256 i = 0; i < 2; i++) {
        uint256 idealBalance = (v.d1 * v.balances[i]) / v.d0;
        uint256 difference = idealBalance.difference(balances1[i]);
        fees[i] = (feePerToken * difference) / FEE_DENOMINATOR;
        uint256 adminFee = self.adminFee;
        {
          self.balances[i] =
            balances1[i] -
            ((fees[i] * adminFee) / FEE_DENOMINATOR);
        }
        balances1[i] = balances1[i] - fees[i];
      }

      v.d2 = getD(_pricedInBatch(self, balances1), v.preciseA);
    }

    uint256 tokenAmount = ((v.d0 - v.d2) * (v.totalSupply)) / v.d0;
    require(tokenAmount != 0, "Burnt amount cannot be zero");
    tokenAmount = tokenAmount + 1;

    require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

    v.lpToken.burnFrom(msg.sender, tokenAmount);

    (bool sent, ) = payable(msg.sender).call{ value: amounts[0] }("");
    require(sent, "SwapUtils: Failed to send Avax");
    wETH2Reference.safeTransferFrom(
      address(this),
      msg.sender,
      self.pooledTokenId,
      amounts[1],
      ""
    );

    emit RemoveLiquidityImbalance(
      msg.sender,
      amounts,
      fees,
      v.d1,
      v.totalSupply - tokenAmount
    );

    return tokenAmount;
  }

  /**
   * @notice withdraw all admin fees to a given address
   * @param self Swap struct to withdraw fees from
   * @param to Address to send the fees to
   */
  function withdrawAdminFees(Swap storage self, address to) external {
    IgAVAX wETH2Reference = self.referenceForPooledTokens;
    uint256 tokenBalance = wETH2Reference.balanceOf(
      address(this),
      self.pooledTokenId
    ) - self.balances[1];
    if (tokenBalance != 0) {
      wETH2Reference.safeTransferFrom(
        address(this),
        to,
        self.pooledTokenId,
        tokenBalance,
        ""
      );
    }

    uint256 avaxBalance = address(this).balance - self.balances[0];
    if (avaxBalance != 0) {
      (bool sent, ) = payable(msg.sender).call{ value: avaxBalance }("");
      require(sent, "SwapUtils: Failed to send Avax");
    }
  }

  /**
   * @notice Sets the admin fee
   * @dev adminFee cannot be higher than 100% of the swap fee
   * @param self Swap struct to update
   * @param newAdminFee new admin fee to be applied on future transactions
   */
  function setAdminFee(Swap storage self, uint256 newAdminFee) external {
    require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
    self.adminFee = newAdminFee;

    emit NewAdminFee(newAdminFee);
  }

  /**
   * @notice update the swap fee
   * @dev fee cannot be higher than 1% of each swap
   * @param self Swap struct to update
   * @param newSwapFee new swap fee to be applied on future transactions
   */
  function setSwapFee(Swap storage self, uint256 newSwapFee) external {
    require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
    self.swapFee = newSwapFee;

    emit NewSwapFee(newSwapFee);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "./SwapUtils.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
  event RampA(
    uint256 oldA,
    uint256 newA,
    uint256 initialTime,
    uint256 futureTime
  );
  event StopRampA(uint256 currentA, uint256 time);

  // Constant values used in ramping A calculations
  uint256 public constant A_PRECISION = 100;
  uint256 public constant MAX_A = 10**6;
  uint256 private constant MAX_A_CHANGE = 2;
  uint256 private constant MIN_RAMP_TIME = 14 days;

  /**
   * @notice Return A, the amplification coefficient * n * (n - 1)
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter
   */
  function getA(SwapUtils.Swap storage self) external view returns (uint256) {
    return _getAPrecise(self) / (A_PRECISION);
  }

  /**
   * @notice Return A in its raw precision
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter in its raw precision form
   */
  function getAPrecise(SwapUtils.Swap storage self)
    external
    view
    returns (uint256)
  {
    return _getAPrecise(self);
  }

  /**
   * @notice Return A in its raw precision
   * @dev See the StableSwap paper for details
   * @param self Swap struct to read from
   * @return A parameter in its raw precision form
   */
  function _getAPrecise(SwapUtils.Swap storage self)
    internal
    view
    returns (uint256)
  {
    uint256 t1 = self.futureATime; // time when ramp is finished
    uint256 a1 = self.futureA; // final A value when ramp is finished

    if (block.timestamp < t1) {
      uint256 t0 = self.initialATime; // time when ramp is started
      uint256 a0 = self.initialA; // initial A value when ramp is started
      if (a1 > a0) {
        // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
        return a0 + ((a1 - a0) * (block.timestamp - t0)) / (t1 - t0);
      } else {
        // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
        return a0 - ((a0 - a1) * (block.timestamp - t0)) / (t1 - t0);
      }
    } else {
      return a1;
    }
  }

  /**
   * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
   * Checks if the change is too rapid, and commits the new A value only when it falls under
   * the limit range.
   * @param self Swap struct to update
   * @param futureA_ the new A to ramp towards
   * @param futureTime_ timestamp when the new A should be reached
   */
  function rampA(
    SwapUtils.Swap storage self,
    uint256 futureA_,
    uint256 futureTime_
  ) external {
    require(
      block.timestamp >= self.initialATime + 1 days,
      "Wait 1 day before starting ramp"
    );
    require(
      futureTime_ >= block.timestamp + MIN_RAMP_TIME,
      "Insufficient ramp time"
    );
    require(
      futureA_ > 0 && futureA_ < MAX_A,
      "futureA_ must be > 0 and < MAX_A"
    );

    uint256 initialAPrecise = _getAPrecise(self);
    uint256 futureAPrecise = futureA_ * A_PRECISION;

    if (futureAPrecise < initialAPrecise) {
      require(
        futureAPrecise * MAX_A_CHANGE >= initialAPrecise,
        "futureA_ is too small"
      );
    } else {
      require(
        futureAPrecise <= initialAPrecise * MAX_A_CHANGE,
        "futureA_ is too large"
      );
    }

    self.initialA = initialAPrecise;
    self.futureA = futureAPrecise;
    self.initialATime = block.timestamp;
    self.futureATime = futureTime_;

    emit RampA(initialAPrecise, futureAPrecise, block.timestamp, futureTime_);
  }

  /**
   * @notice Stops ramping A immediately. Once this function is called, rampA()
   * cannot be called for another 24 hours
   * @param self Swap struct to update
   */
  function stopRampA(SwapUtils.Swap storage self) external {
    require(self.futureATime > block.timestamp, "Ramp is already stopped");

    uint256 currentA = _getAPrecise(self);
    self.initialA = currentA;
    self.futureA = currentA;
    self.initialATime = block.timestamp;
    self.futureATime = block.timestamp;

    emit StopRampA(currentA, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

/**
 * @title MathUtils library
 * @notice  Contains functions for calculating differences between two uint256.
 */
library MathUtils {
  /**
   * @notice Compares a and b and returns true if the difference between a and b
   *         is less than 1 or equal to each other.
   * @param a uint256 to compare with
   * @param b uint256 to compare with
   * @return True if the difference between a and b is less than 1 or equal,
   *         otherwise return false
   */
  function within1(uint256 a, uint256 b) internal pure returns (bool) {
    return (difference(a, b) <= 1);
  }

  /**
   * @notice Calculates absolute difference between a and b
   * @param a uint256 to compare with
   * @param b uint256 to compare with
   * @return Difference between a and b
   */
  function difference(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a > b) {
      return a - b;
    }
    return b - a;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "../../utils/MathUtils.sol";

contract TestMathUtils {
  using MathUtils for uint256;

  function difference(uint256 a, uint256 b) public pure returns (uint256) {
    return a.difference(b);
  }

  function within1(uint256 a, uint256 b) public pure returns (bool) {
    return a.within1(b);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IgAVAX.sol";
import "./helpers/OwnerPausableUpgradeable.sol";
import "./utils/SwapUtils.sol";
import "./utils/AmplificationUtils.sol";
import "../interfaces/ISwap.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract Swap is
    ISwap,
    OwnerPausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155HolderUpgradeable
{
    using SwapUtils for SwapUtils.Swap;
    using AmplificationUtils for SwapUtils.Swap;

    // Struct storing data responsible for automatic market maker functionalities. In order to
    // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
    SwapUtils.Swap public swapStorage;

    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients
    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);
    event RampA(
        uint256 oldA,
        uint256 newA,
        uint256 initialTime,
        uint256 futureTime
    );
    event StopRampA(uint256 currentA, uint256 time);

    /**
     * @notice Initializes this Swap contract with the given parameters.
     * This will also clone a LPToken contract that represents users'
     * LP positions. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint/burn tokens.
     *
     * @param _gAvax reference of the wETH2 ERC1155 contract
     * @param _pooledTokenId gAvax ID that the Pool is operating with
     * @param lpTokenName the long-form name of the token to be deployed
     * @param lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param lpTokenTargetAddress the address of an existing LPToken contract to use as a target
     */
    function initialize(
        address _gAvax,
        uint256 _pooledTokenId,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        address lpTokenTargetAddress
    ) public virtual override initializer returns (address) {
        __OwnerPausable_init();
        __ReentrancyGuard_init();
        __ERC1155Holder_init();

        require(
            lpTokenTargetAddress != address(0),
            "Swap: lpTokenTargetAddress can not be zero"
        );
        require(_gAvax != address(0), "Swap: _gAvax can not be zero");

        // Check _a, _fee, _adminFee, _withdrawFee parameters
        require(_a < AmplificationUtils.MAX_A, "Swap: _a exceeds maximum");
        require(_fee < SwapUtils.MAX_SWAP_FEE, "Swap: _fee exceeds maximum");
        require(
            _adminFee < SwapUtils.MAX_ADMIN_FEE,
            "Swap: _adminFee exceeds maximum"
        );

        // Clone and initialize a LPToken contract
        LPToken lpToken = LPToken(Clones.clone(lpTokenTargetAddress));
        require(
            lpToken.initialize(lpTokenName, lpTokenSymbol),
            "Swap: could not init lpToken clone"
        );

        // Initialize swapStorage struct
        swapStorage.lpToken = lpToken;
        swapStorage.referenceForPooledTokens = IgAVAX(_gAvax);
        swapStorage.pooledTokenId = _pooledTokenId;
        swapStorage.balances = new uint256[](2);
        swapStorage.initialA = _a * AmplificationUtils.A_PRECISION;
        swapStorage.futureA = _a * AmplificationUtils.A_PRECISION;
        swapStorage.swapFee = _fee;
        swapStorage.adminFee = _adminFee;
        return address(lpToken);
    }

    /*** MODIFIERS ***/

    /**
     * @notice Modifier to check deadline against current timestamp
     * @param deadline latest timestamp to accept this transaction
     */
    modifier deadlineCheck(uint256 deadline) {
        require(block.timestamp <= deadline, "Swap: Deadline not met");
        _;
    }

    /*** VIEW FUNCTIONS ***/
    function getERC1155() external view virtual override returns (address) {
        return address(swapStorage.referenceForPooledTokens);
    }

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @return A parameter
     */
    function getA() external view virtual override returns (uint256) {
        return swapStorage.getA();
    }

    /**
     * @notice Return A in its raw precision form
     * @dev See the StableSwap paper for details
     * @return A parameter in its raw precision form
     */
    function getAPrecise() external view virtual override returns (uint256) {
        return swapStorage.getAPrecise();
    }

    /**
     * @notice Return id of the pooled token
     * @return id of the pooled gAvax token
     */
    function getToken() external view virtual override returns (uint256) {
        return swapStorage.pooledTokenId;
    }

    /**
     * @notice Return current balance of the pooled token at given index
     * @param index the index of the token
     * @return current balance of the pooled token at given index with token's native precision
     */
    function getTokenBalance(uint8 index)
        external
        view
        virtual
        override
        returns (uint256)
    {
        require(index < 2, "Swap: Index out of range");
        return swapStorage.balances[index];
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return swapStorage.getVirtualPrice();
    }

    /**
     * @notice Get Debt, The amount of buyback for stable pricing (1=1).
     * @return debt the half of the D StableSwap invariant when debt is needed to be payed.
     */
    function getDebt() external view virtual override returns (uint256) {
        // might change when price is in.
        return swapStorage.getDebt();
    }

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return amount of tokens the user will receive
     */
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view virtual override returns (uint256) {
        return swapStorage.calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return token amount the user will receive
     */
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return swapStorage.calculateTokenAmount(amounts, deposit);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of LP tokens
     * @param amount the amount of LP tokens that would be burned on withdrawal
     * @return array of token balances that the user will receive
     */
    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        virtual
        override
        returns (uint256[] memory)
    {
        return swapStorage.calculateRemoveLiquidity(amount);
    }

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param tokenAmount the amount of LP token to burn
     * @param tokenIndex index of which token will be withdrawn
     * @return availableTokenAmount calculated amount of underlying token
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view virtual override returns (uint256 availableTokenAmount) {
        return swapStorage.calculateWithdrawOneToken(tokenAmount, tokenIndex);
    }

    /**
     * @notice This function reads the accumulated amount of admin fees of the token with given index
     * @param index Index of the pooled token
     * @return admin's token balance in the token's precision
     */
    function getAdminBalance(uint256 index)
        external
        view
        virtual
        returns (uint256)
    {
        return swapStorage.getAdminBalance(index);
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice Swap two tokens using this pool
     * @param tokenIndexFrom the token the user wants to swap from
     * @param tokenIndexTo the token the user wants to swap to
     * @param dx the amount of tokens the user wants to swap from
     * @param minDy the min amount the user would like to receive, or revert.
     * @param deadline latest timestamp to accept this transaction
     */
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.swap(tokenIndexFrom, tokenIndexTo, dx, minDy);
    }

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP token user minted and received
     */
    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.addLiquidity(amounts, minToMint);
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     * @param deadline latest timestamp to accept this transaction
     * @return amounts of tokens user received
     */
    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        deadlineCheck(deadline)
        returns (uint256[] memory)
    {
        return swapStorage.removeLiquidity(amount, minAmounts);
    }

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param tokenAmount the amount of the token you want to receive
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @param deadline latest timestamp to accept this transaction
     * @return amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return
            swapStorage.removeLiquidityOneToken(
                tokenAmount,
                tokenIndex,
                minAmount
            );
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances.
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param deadline latest timestamp to accept this transaction
     * @return amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    )
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        deadlineCheck(deadline)
        returns (uint256)
    {
        return swapStorage.removeLiquidityImbalance(amounts, maxBurnAmount);
    }

    /*** ADMIN FUNCTIONS ***/

    /**
     * @notice Withdraw all admin fees to the contract owner
     */
    function withdrawAdminFees() external onlyOwner nonReentrant {
        swapStorage.withdrawAdminFees(owner());
    }

    /**
     * @notice Update the admin fee. Admin fee takes portion of the swap fee.
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(uint256 newAdminFee) external onlyOwner {
        swapStorage.setAdminFee(newAdminFee);
    }

    /**
     * @notice Update the swap fee to be applied on swaps
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(uint256 newSwapFee) external onlyOwner {
        swapStorage.setSwapFee(newSwapFee);
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA and futureTime
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param futureA the new A to ramp towards
     * @param futureTime timestamp when the new A should be reached
     */
    function rampA(uint256 futureA, uint256 futureTime) external onlyOwner {
        swapStorage.rampA(futureA, futureTime);
    }

    /**
     * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
     */
    function stopRampA() external onlyOwner {
        swapStorage.stopRampA();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title OwnerPausable
 * @notice An ownable contract allows the owner to pause and unpause the
 * contract without a delay.
 * @dev Only methods using the provided modifiers will be paused.
 */
abstract contract OwnerPausableUpgradeable is
  OwnableUpgradeable,
  PausableUpgradeable
{
  function __OwnerPausable_init() internal onlyInitializing {
    __Context_init_unchained();
    __Ownable_init_unchained();
    __Pausable_init_unchained();
  }

  /**
   * @notice Pause the contract. Revert if already paused.
   */
  function pause() external onlyOwner {
    PausableUpgradeable._pause();
  }

  /**
   * @notice Unpause the contract. Revert if already unpaused.
   */
  function unpause() external onlyOwner {
    PausableUpgradeable._unpause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/IgAVAX.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20InterfaceUpgradable is
  Initializable,
  ContextUpgradeable,
  IERC20Upgradeable,
  IERC20MetadataUpgradeable
{
  /**
   * @dev gAVAX ERC20 interface doesn't use balance info, catches it from ERC1155.
   * mapping(address => uint256) private _balances;
   **/

  /**
   * @dev gAVAX ERC20 interface doesn't use totalSupply info, catches it from ERC1155.
   * uint256 private _totalSupply;
   **/

  mapping(address => mapping(address => uint256)) private _allowances;
  string private _name;
  string private _symbol;
  uint256 private _id;
  IgAVAX private _ERC1155;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   */
  function initialize(
    uint256 id_,
    string memory name_,
    address gAVAX_1155
  ) public virtual initializer {
    _id = id_;
    _name = string(abi.encodePacked(name_, " gAVAX"));
    _symbol = string(abi.encodePacked("yyAVAX"));
    _ERC1155 = IgAVAX(gAVAX_1155);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _ERC1155.totalSupply(_id);
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _ERC1155.balanceOf(account, _id);
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function pricePerShare() public view returns (uint256) {
    // shows the u underlying ETH for 1 staked ether for a given Registerer as 1e18
    return _ERC1155.pricePerShare(_id);
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = balanceOf(sender);
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _ERC1155.safeTransferFrom(sender, recipient, _id, amount, "");
    }

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "../../utils/DataStoreLib.sol";
import "../../utils/StakeUtilsLib.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract TestStakeUtils is ERC1155Holder {
  using DataStoreUtils for DataStoreUtils.DataStore;
  using StakeUtils for StakeUtils.StakePool;
  DataStoreUtils.DataStore private DATASTORE;
  StakeUtils.StakePool private STAKEPOOL;

  constructor(
    address _gAVAX,
    address _ORACLE,
    address _DEFAULT_SWAP_POOL,
    address _DEFAULT_LP_TOKEN
  ) {
    STAKEPOOL.ORACLE = _ORACLE;
    STAKEPOOL.gAVAX = _gAVAX;
    STAKEPOOL.FEE_DENOMINATOR = 10**10;
    STAKEPOOL.DEFAULT_SWAP_POOL = _DEFAULT_SWAP_POOL;
    STAKEPOOL.DEFAULT_LP_TOKEN = _DEFAULT_LP_TOKEN;
    STAKEPOOL.DEFAULT_A = 60;
    STAKEPOOL.DEFAULT_FEE = 4e6;
    STAKEPOOL.DEFAULT_ADMIN_FEE = 5e9;
    STAKEPOOL.PERIOD_PRICE_INCREASE_LIMIT =
      (5 * STAKEPOOL.FEE_DENOMINATOR) /
      1e3;
    STAKEPOOL.MAX_MAINTAINER_FEE = (10 * STAKEPOOL.FEE_DENOMINATOR) / 1e2; //10%
  }

  function getStakePoolParams()
    external
    view
    virtual
    returns (StakeUtils.StakePool memory)
  {
    return STAKEPOOL;
  }

  function getgAVAX() public view virtual returns (IgAVAX) {
    return STAKEPOOL.getgAVAX();
  }

  function setPricePerShare(uint256 pricePerShare_, uint256 _id)
    public
    virtual
  {
    STAKEPOOL._setPricePerShare(pricePerShare_, _id);
  }

  function mint(
    address _gAVAX,
    address _to,
    uint256 _id,
    uint256 _amount
  ) external {
    StakeUtils._mint(_gAVAX, _to, _id, _amount);
  }

  function findDEBT(uint256 id) external view returns (uint256) {
    return StakeUtils.withdrawalPoolById(DATASTORE, id).getDebt();
  }

  function buyback(
    address to,
    uint256 planetId,
    uint256 minToBuy,
    uint256 deadline
  ) external payable returns (uint256) {
    return
      STAKEPOOL._buyback(
        DATASTORE,
        to,
        planetId,
        msg.value,
        minToBuy,
        deadline
      );
  }

  /**
  * Maintainer

  */
  function getMaintainerFromId(uint256 _id)
    external
    view
    virtual
    returns (address)
  {
    return DATASTORE.readAddressForId(_id, "maintainer");
  }

  function changeIdMaintainer(uint256 _id, address _newMaintainer)
    external
    virtual
  {
    StakeUtils.changeMaintainer(DATASTORE, _id, _newMaintainer);
  }

  function setMaintainerFee(uint256 _id, uint256 _newFee) external virtual {
    STAKEPOOL.setMaintainerFee(DATASTORE, _id, _newFee);
  }

  function setMaxMaintainerFee(uint256 _newMaxFee) external virtual {
    STAKEPOOL.setMaxMaintainerFee(_newMaxFee);
  }

  function getMaintainerFee(uint256 _id)
    external
    view
    virtual
    returns (uint256)
  {
    return STAKEPOOL.getMaintainerFee(DATASTORE, _id);
  }

  // ORACLE FUNCTIONS

  function isOracleActive(uint256 _id) external view returns (bool) {
    return StakeUtils._isOracleActive(DATASTORE, _id);
  }

  function setOracleTime(uint256 _id) external {
    DATASTORE.writeUintForId(_id, "oracleUpdateTimeStamp", block.timestamp);
  }

  function beController(uint256 _id) external {
    DATASTORE.writeAddressForId(_id, "CONTROLLER", msg.sender);
  }

  function oraclePrice(uint256 _id) external view returns (uint256) {
    return STAKEPOOL.oraclePrice(_id);
  }

  function distributeFees(
    uint256 _planetId,
    uint256[] calldata _opIds,
    uint256[] calldata _pBalanceIncreases
  ) external {
    STAKEPOOL._distributeFees(DATASTORE, _planetId, _opIds, _pBalanceIncreases);
  }

  function reportOracle(
    uint256 _planetId,
    uint256[] calldata _opIds,
    uint256[] calldata _pBalanceIncreases
  ) external returns (uint256 price) {
    price = STAKEPOOL.reportOracle(
      DATASTORE,
      block.timestamp,
      _planetId,
      _opIds,
      _pBalanceIncreases
    );
  }

  // DEBT AND SURPLUS RELATED
  function withdrawalPoolById(uint256 _id)
    external
    view
    virtual
    returns (address)
  {
    return address(StakeUtils.withdrawalPoolById(DATASTORE, _id));
  }

  function LPTokenById(uint256 _id) external view virtual returns (address) {
    return address(StakeUtils.LPTokenById(DATASTORE, _id));
  }

  function payDebt(uint256 _planetId, uint256 claimerId) external payable {
    STAKEPOOL.payDebt(DATASTORE, _planetId, claimerId);
  }

  function surplusById(uint256 _planetId) external view returns (uint256) {
    return DATASTORE.readUintForId(_planetId, "surplus");
  }

  function putSurplus(uint256 _planetId, uint256 newsurplus) external {
    DATASTORE.writeUintForId(_planetId, "surplus", newsurplus);
  }

  function pBalanceById(uint256 _planetId) external view returns (uint256) {
    return DATASTORE.readUintForId(_planetId, "pBalance");
  }

  function unclaimedFeesById(uint256 _planetId)
    external
    view
    returns (uint256)
  {
    return DATASTORE.readUintForId(_planetId, "unclaimedFees");
  }

  function claimSurplus(uint256 _planetId, uint256 claimerId)
    external
    returns (bool)
  {
    return StakeUtils.claimSurplus(DATASTORE, _planetId, claimerId);
  }

  function accumulatedFee(uint256 planetId, uint256 claimerId)
    external
    view
    returns (uint256)
  {
    (uint256 fee, ) = StakeUtils.accumulatedFee(DATASTORE, planetId, claimerId);
    return fee;
  }

  function unclaimedFees(uint256 _poolId) external view returns (uint256) {
    return DATASTORE.readUintForId(_poolId, "unclaimedFees");
  }

  function setMaintainer(uint256 _id, address _maintainer) external {
    DATASTORE.writeAddressForId(_id, "maintainer", _maintainer);
  }

  function claimFee(uint256 planetId, uint256 claimerId) external virtual {
    StakeUtils.claimFee(DATASTORE, planetId, claimerId);
  }

  /**  FUNCTIONS ABOUT SWAP & ROUTING */

  function deployWithdrawalPool(uint256 id)
    external
    returns (address WithdrawalPool)
  {
    return STAKEPOOL.deployWithdrawalPool(DATASTORE, id);
  }

  function activateOperator(uint256 _id, uint256 _activeId)
    external
    virtual
    returns (bool)
  {
    return StakeUtils.activateOperator(DATASTORE, _id, _activeId);
  }

  function deactivateOperator(uint256 _id, uint256 _deactivedId)
    external
    virtual
    returns (bool)
  {
    return StakeUtils.deactivateOperator(DATASTORE, _id, _deactivedId);
  }

  function pausePool(uint256 id) external {
    StakeUtils.pauseStakingForPool(DATASTORE, id);
  }

  function unpausePool(uint256 id) external {
    StakeUtils.unpauseStakingForPool(DATASTORE, id);
  }

  function stake(
    uint256 planetId,
    uint256 minGavax,
    uint256 deadline
  ) external payable returns (uint256 totalgAvax) {
    return STAKEPOOL.stake(DATASTORE, planetId, minGavax, deadline);
  }

  function Receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../../../interfaces/ISwap.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TestSwapReturnValues is ERC1155Holder {
  using SafeMath for uint256;

  ISwap public swap;
  IERC1155 public wETH2;
  IERC20 public lpToken;
  uint8 public n;

  uint256 public constant MAX_INT = 2**256 - 1;

  constructor(
    ISwap swapContract,
    IERC1155 wETH2Reference,
    IERC20 lpTokenContract,
    uint8 numOfTokens
  ) {
    swap = swapContract;
    wETH2 = wETH2Reference;
    lpToken = lpTokenContract;
    n = numOfTokens;

    // Pre-approve tokens
    wETH2.setApprovalForAll(address(swap), true);
    lpToken.approve(address(swap), MAX_INT);
  }

  function test_swap(
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 dx,
    uint256 minDy
  ) public payable {

    uint256 avaxbalanceBefore = address(this).balance;
    uint256 gavaxbalanceBefore = wETH2.balanceOf(address(this), swap.getToken());

    if(tokenIndexFrom == 0){
      // If avax to gavax
    uint256 returnValue = swap.swap{ value: msg.value }(
      tokenIndexFrom,
      tokenIndexTo,
      dx,
      minDy,
      block.timestamp
    );

    uint256 gavaxbalanceAfter = wETH2.balanceOf(address(this), swap.getToken());

    require(
      returnValue == gavaxbalanceAfter.sub(gavaxbalanceBefore),
      "swap()'s return value does not match received gavax amount"
    );

    }else{
      uint256 returnValue = swap.swap(
      tokenIndexFrom,
      tokenIndexTo,
      dx,
      minDy,
      block.timestamp
    );

    uint256 avaxbalanceAfter = address(this).balance;

    require(
      returnValue == avaxbalanceAfter.sub(avaxbalanceBefore),
      "swap()'s return value does not match received avax amount"
    );

    }
  }

  function test_addLiquidity(uint256[] calldata amounts, uint256 minToMint)
    public
    payable
  {
    require(
      msg.value == amounts[0],
      "The update of about AVAX amount -0xCypher"
    );
    uint256 balanceBefore = lpToken.balanceOf(address(this));
    uint256 returnValue = swap.addLiquidity{ value: msg.value }(
      amounts,
      minToMint,
      MAX_INT
    );
    uint256 balanceAfter = lpToken.balanceOf(address(this));

    console.log(
      "addLiquidity: Expected %s, got %s",
      balanceAfter.sub(balanceBefore),
      returnValue
    );

    require(
      returnValue == balanceAfter.sub(balanceBefore),
      "addLiquidity()'s return value does not match minted amount"
    );
  }

  function test_removeLiquidity(uint256 amount, uint256[] memory minAmounts)
    public
  {
    uint256[] memory balanceBefore = new uint256[](n);
    uint256[] memory balanceAfter = new uint256[](n);

    balanceBefore[0] = address(this).balance;
    balanceBefore[1] = wETH2.balanceOf(address(this), swap.getToken());

    uint256[] memory returnValue = swap.removeLiquidity(
      amount,
      minAmounts,
      MAX_INT
    );
    balanceAfter[0] = address(this).balance;
    balanceAfter[1] = wETH2.balanceOf(address(this), swap.getToken());

    for (uint8 i = 0; i < n; i++) {
      console.log(
        "removeLiquidity: Expected %s, got %s",
        balanceAfter[i].sub(balanceBefore[i]),
        returnValue[i]
      );
      require(
        balanceAfter[i].sub(balanceBefore[i]) == returnValue[i],
        "removeLiquidity()'s return value does not match received amounts of tokens"
      );
    }
  }

  function test_removeLiquidityImbalance(
    uint256[] calldata amounts,
    uint256 maxBurnAmount
  ) public {
    uint256 balanceBefore = lpToken.balanceOf(address(this));
    uint256 returnValue = swap.removeLiquidityImbalance(
      amounts,
      maxBurnAmount,
      MAX_INT
    );
    uint256 balanceAfter = lpToken.balanceOf(address(this));

    console.log(
      "removeLiquidityImbalance: Expected %s, got %s",
      balanceBefore.sub(balanceAfter),
      returnValue
    );

    require(
      returnValue == balanceBefore.sub(balanceAfter),
      "removeLiquidityImbalance()'s return value does not match burned lpToken amount"
    );
  }

  function test_removeLiquidityOneToken(
    uint256 tokenAmount,
    uint8 tokenIndex,
    uint256 minAmount
  ) public {
    uint256 balanceBefore;
    if (tokenIndex == 0) {
      balanceBefore = address(this).balance;
    } else {
      balanceBefore = wETH2.balanceOf(address(this), swap.getToken());
    }
    uint256 returnValue = swap.removeLiquidityOneToken(
      tokenAmount,
      tokenIndex,
      minAmount,
      MAX_INT
    );

    uint256 balanceAfter;
    if (tokenIndex == 0) {
      balanceAfter = address(this).balance;
    } else {
      balanceAfter = wETH2.balanceOf(address(this), swap.getToken());
    }
    console.log(
      "removeLiquidityOneToken: Expected %s, got %s",
      balanceAfter.sub(balanceBefore),
      returnValue
    );

    require(
      returnValue == balanceAfter.sub(balanceBefore),
      "removeLiquidityOneToken()'s return value does not match received token amount"
    );
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity =0.8.7;
/**
 * @dev only difference between ERC1155SupplyMinterPauser and Openzeppelin's implementation is
 * _doSafeTransferAcceptanceCheck is being virtual:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52eeebecda140ebaf4ec8752ed119d8288287fac/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol#L1
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52eeebecda140ebaf4ec8752ed119d8288287fac/contracts/token/ERC1155/extensions/ERC1155Supply.sol#L1
 *
 * diffchecker link: https://www.diffchecker.com/W9Am9Owk
 */
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
  using Address for address;

  // Mapping from token ID to account balances
  mapping(uint256 => mapping(address => uint256)) private _balances;

  // Mapping from account to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
  string private _uri;

  /**
   * @dev See {_setURI}.
   */
  constructor(string memory uri_) {
    _setURI(uri_);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC1155MetadataURI-uri}.
   *
   * This implementation returns the same URI for *all* token types. It relies
   * on the token type ID substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * Clients calling this function must replace the `\{id\}` substring with the
   * actual token type ID.
   */
  function uri(uint256) public view virtual override returns (string memory) {
    return _uri;
  }

  /**
   * @dev See {IERC1155-balanceOf}.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      account != address(0),
      "ERC1155: balance query for the zero address"
    );
    return _balances[id][account];
  }

  /**
   * @dev See {IERC1155-balanceOfBatch}.
   *
   * Requirements:
   *
   * - `accounts` and `ids` must have the same length.
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    returns (uint256[] memory)
  {
    require(
      accounts.length == ids.length,
      "ERC1155: accounts and ids length mismatch"
    );

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @dev See {IERC1155-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC1155-isApprovedForAll}.
   */
  function isApprovedForAll(address account, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[account][operator];
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );
    _safeTransferFrom(from, to, id, amount, data);
  }

  /**
   * @dev See {IERC1155-safeBatchTransferFrom}.
   */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override {
    require(
      from == _msgSender() || isApprovedForAll(from, _msgSender()),
      "ERC1155: transfer caller is not owner nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  /**
   * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `from` must have a balance of tokens of type `id` of at least `amount`.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    uint256 fromBalance = _balances[id][from];
    require(
      fromBalance >= amount,
      "ERC1155: insufficient balance for transfer"
    );
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _afterTokenTransfer(operator, from, to, ids, amounts, data);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
   *
   * Emits a {TransferBatch} event.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(
      ids.length == amounts.length,
      "ERC1155: ids and amounts length mismatch"
    );
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(
        fromBalance >= amount,
        "ERC1155: insufficient balance for transfer"
      );
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _afterTokenTransfer(operator, from, to, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * substitution mechanism
   * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
   *
   * By this mechanism, any occurrence of the `\{id\}` substring in either the
   * URI or any of the amounts in the JSON file at said URI will be replaced by
   * clients with the token type ID.
   *
   * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
   * interpreted by clients as
   * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
   * for token type ID 0x4cce0.
   *
   * See {uri}.
   *
   * Because these URIs cannot be meaningfully represented by the {URI} event,
   * this function emits no events.
   */
  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
  }

  /**
   * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
   *
   * Emits a {TransferSingle} event.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   */
  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");

    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    _balances[id][to] += amount;
    emit TransferSingle(operator, address(0), to, id, amount);

    _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(
      ids.length == amounts.length,
      "ERC1155: ids and amounts length mismatch"
    );

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(
      operator,
      address(0),
      to,
      ids,
      amounts,
      data
    );
  }

  /**
   * @dev Destroys `amount` tokens of token type `id` from `from`
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `from` must have at least `amount` tokens of token type `id`.
   */
  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");

    address operator = _msgSender();
    uint256[] memory ids = _asSingletonArray(id);
    uint256[] memory amounts = _asSingletonArray(amount);

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    uint256 fromBalance = _balances[id][from];
    require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }

    emit TransferSingle(operator, from, address(0), id, amount);

    _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
   *
   * Requirements:
   *
   * - `ids` and `amounts` must have the same length.
   */
  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(from != address(0), "ERC1155: burn from the zero address");
    require(
      ids.length == amounts.length,
      "ERC1155: ids and amounts length mismatch"
    );

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
    }

    emit TransferBatch(operator, from, address(0), ids, amounts);

    _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC1155: setting approval status for self");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  /**
   * @dev Hook that is called after any token transfer. This includes minting
   * and burning, as well as batched variants.
   *
   * The same hook is called on both single and batched variants. For single
   * transfers, the length of the `id` and `amount` arrays will be 1.
   *
   * Calling conditions (for each `id` and `amount` pair):
   *
   * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * of token type `id` will be  transferred to `to`.
   * - When `from` is zero, `amount` tokens of token type `id` will be minted
   * for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
   * will be burned.
   * - `from` and `to` are never both zero.
   * - `ids` and `amounts` have the same, non-zero length.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    if (to.isContract()) {
      try
        IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data)
      returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try
        IERC1155Receiver(to).onERC1155BatchReceived(
          operator,
          from,
          ids,
          amounts,
          data
        )
      returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _asSingletonArray(uint256 element)
    private
    pure
    returns (uint256[] memory)
  {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );

    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );

    _burnBatch(account, ids, values);
  }
}

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    require(!paused(), "ERC1155Pausable: token transfer while paused");
  }
}

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC1155PresetMinterPauser is
  Context,
  AccessControlEnumerable,
  ERC1155Burnable,
  ERC1155Pausable
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
   * deploys the contract.
   */
  constructor(string memory uri) ERC1155(uri) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
  }

  /**
   * @dev Creates `amount` new tokens for `to`, of token type `id`.
   *
   * See {ERC1155-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      "ERC1155PresetMinterPauser: must have minter role to mint"
    );

    _mint(to, id, amount, data);
  }

  /**
   * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
   */
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      "ERC1155PresetMinterPauser: must have minter role to mint"
    );

    _mintBatch(to, ids, amounts, data);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC1155Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC1155PresetMinterPauser: must have pauser role to pause"
    );
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC1155Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC1155PresetMinterPauser: must have pauser role to unpause"
    );
    _unpause();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC1155)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
contract ERC1155SupplyMinterPauser is ERC1155PresetMinterPauser {
  constructor(string memory uri) ERC1155PresetMinterPauser(uri) {}

  mapping(uint256 => uint256) private _totalSupply;

  /**
   * @dev Total amount of tokens in with a given id.
   */
  function totalSupply(uint256 id) public view virtual returns (uint256) {
    return _totalSupply[id];
  }

  /**
   * @dev Indicates whether any token exist with a given id, or not.
   */
  function exists(uint256 id) public view virtual returns (bool) {
    return ERC1155SupplyMinterPauser.totalSupply(id) > 0;
  }

  /**
   * @dev See {ERC1155-_beforeTokenTransfer}.
   */
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        _totalSupply[ids[i]] += amounts[i];
      }
    }

    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; ++i) {
        uint256 id = ids[i];
        uint256 amount = amounts[i];
        uint256 supply = _totalSupply[id];
        require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
        unchecked {
          _totalSupply[id] = supply - amount;
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ERC1155ReceiverMock is ERC165, IERC1155Receiver {
  bytes4 private _recRetval;
  bool private _recReverts;
  bytes4 private _batRetval;
  bool private _batReverts;

  event Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes data,
    uint256 gas
  );
  event BatchReceived(
    address operator,
    address from,
    uint256[] ids,
    uint256[] values,
    bytes data,
    uint256 gas
  );

  constructor(
    bytes4 recRetval,
    bool recReverts,
    bytes4 batRetval,
    bool batReverts
  ) {
    _recRetval = recRetval;
    _recReverts = recReverts;
    _batRetval = batRetval;
    _batReverts = batReverts;
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    require(!_recReverts, "ERC1155ReceiverMock: reverting on receive");
    emit Received(operator, from, id, value, data, gasleft());
    return _recRetval;
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external override returns (bytes4) {
    require(!_batReverts, "ERC1155ReceiverMock: reverting on batch receive");
    emit BatchReceived(operator, from, ids, values, data, gasleft());
    return _batRetval;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../../interfaces/IgAVAX.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Interface is Context, IERC20, IERC20Metadata {
  /**
   * @dev gAVAX ERC20 interface doesn't use balance info, catches it from ERC1155.
   * mapping(address => uint256) private _balances;
   **/

  /**
   * @dev gAVAX ERC20 interface doesn't use totalSupply info, catches it from ERC1155.
   * uint256 private _totalSupply;
   **/

  mapping(address => mapping(address => uint256)) private _allowances;
  string private _name;
  string private _symbol;
  uint256 private immutable _id;
  IgAVAX private immutable _ERC1155;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(
    uint256 id_,
    string memory name_,
    address gAVAX_1155
  ) {
    //requires
    _id = id_;
    _name = string(abi.encodePacked(name_, " Geode AVAX 2"));
    _symbol = string(abi.encodePacked(name_, "-gAVAX"));
    _ERC1155 = IgAVAX(gAVAX_1155);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _ERC1155.totalSupply(_id);
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _ERC1155.balanceOf(account, _id);
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      "ERC20: transfer amount exceeds allowance"
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function pricePerShare() public view returns (uint256) {
    // shows the u underlying ETH for 1 staked ether for a given Registerer as 1e18
    return _ERC1155.pricePerShare(_id);
  }

  /**
   * @dev Moves `amount` of tokens from `sender` to `recipient`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 senderBalance = balanceOf(sender);
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _ERC1155.safeTransferFrom(sender, recipient, _id, amount, "");
    }

    emit Transfer(sender, recipient, amount);

    _afterTokenTransfer(sender, recipient, amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "./helpers/ERC1155SupplyMinterPauser.sol";

/**
 * @title Geode Finance geode-Avax: gAVAX
 *
 * gAVAX is an ERC1155 implementation that inherites two openzeppelin preset
 * contracts: ERC1155PresetMinterPauser and ERC1155Supply with some unique functionality.
 *
 * One of the unique functionalities are the included price logic that tracks the underlaying ratio with
 * staked asset, Avax.
 * Other and most important change is the implementation of ERC1155Interfaces.
 * This addition effectively result in changes in safeTransferFrom(), burn(), _doSafeTransferAcceptanceCheck()
 * functions, reasoning is in comments.
 *
 * @dev only difference between ERC1155SupplyMinterPauser and Openzeppelin's implementation is
 * _doSafeTransferAcceptanceCheck is being virtual:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52eeebecda140ebaf4ec8752ed119d8288287fac/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol#L1
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52eeebecda140ebaf4ec8752ed119d8288287fac/contracts/token/ERC1155/extensions/ERC1155Supply.sol#L1
 *
 * diffchecker link: https://www.diffchecker.com/W9Am9Owk
 */

contract gAVAX is ERC1155SupplyMinterPauser {
  using Address for address;
  event InterfaceChanged(address indexed newInterface, uint256 ID);
  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
  string public constant name = "Geode Staked Avax";
  string public constant symbol = "gAVAX";

  /**
   * @dev ADDED for gAVAX
   * @notice Mapping from planet IDs to ERC1155ınterface implementation addresses
   * There can be multiple Interfaces for 1 planet(staking pool).
   **/
  mapping(uint256 => mapping(address => bool)) private _interfaces;

  /**
   * @dev ADDED for gAVAX
   * @notice shows the underlying AVAX for 1 staked gAvax for a given asset id
   * @dev give id get 1e18 for starter
   **/
  mapping(uint256 => uint256) private _pricePerShare;

  constructor(string memory uri) ERC1155SupplyMinterPauser(uri) {
    _setupRole(ORACLE_ROLE, _msgSender());
  }

  /**
   * @dev ADDED for gAVAX
   * @notice checks if an address is defined as an interface for given Planet id.
   */
  function isInterface(address _interface, uint256 id)
    public
    view
    virtual
    returns (bool)
  {
    require(
      _interface != address(0),
      "ERC1155: interface query for the zero address"
    );
    return _interfaces[id][_interface];
  }

  /**
   * @dev ADDED for gAVAX
   * @dev only authorized parties should set the interface as this is super crucial.
   */
  function _setInterface(
    address _Interface,
    uint256 _id,
    bool isSet
  ) internal virtual {
    require(
      _Interface != address(0),
      "ERC1155: interface query for the zero address"
    );
    _interfaces[_id][_Interface] = isSet;
  }

  /**
   * @dev ADDED for gAVAX
   * @notice to be used to set an an address of a contract that will
   * be behaved as an interface by gAVAX contract for a spesific ID
   */
  function setInterface(
    address _Interface,
    uint256 _id,
    bool isSet
  ) external virtual {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      "gAVAX: must have MINTER_ROLE to set"
    );
    require(_Interface.isContract(), "gAVAX: _Interface must be a contract");
    _setInterface(_Interface, _id, isSet);
    emit InterfaceChanged(_Interface, _id);
  }

  /**
   * @dev ADDED for gAVAX
   */
  function pricePerShare(uint256 _id) external view returns (uint256) {
    return _pricePerShare[_id];
  }

  /**
   * @dev ADDED for gAVAX
   */
  function _setPricePerShare(uint256 pricePerShare_, uint256 _id)
    internal
    virtual
  {
    _pricePerShare[_id] = pricePerShare_;
  }

  function setPricePerShare(uint256 pricePerShare_, uint256 _id)
    external
    virtual
  {
    require(
      hasRole(ORACLE_ROLE, _msgSender()),
      "gAVAX: must have ORACLE to set"
    );
    _setPricePerShare(pricePerShare_, _id);
  }

  /**
   * @notice updates the authorized party for all crucial operations related to
   * minting, pricing and interfaces.
   * @dev MinterPauserOracle is basically a superUser, there can be only 1 at a given time,
   * intended as "Portal"
   */
  function updateMinterPauserOracle(address Minter) external virtual {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      "gAVAX: must have MINTER_ROLE to set"
    );
    renounceRole(MINTER_ROLE, _msgSender());
    renounceRole(PAUSER_ROLE, _msgSender());
    renounceRole(ORACLE_ROLE, _msgSender());

    _setupRole(MINTER_ROLE, Minter);
    _setupRole(PAUSER_ROLE, Minter);
    _setupRole(ORACLE_ROLE, Minter);
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   * @dev CHANGED for gAVAX
   * @dev interfaces can move your tokens without asking you.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override {
    require(
      from == _msgSender() ||
        (isApprovedForAll(from, _msgSender()) || isInterface(_msgSender(), id)),
      // ADDED || isInterface(_msgSender(),id))
      "ERC1155: caller is not owner nor approved"
    );
    _safeTransferFrom(from, to, id, amount, data);
  }

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual override {
    require(
      account == _msgSender() ||
        (isApprovedForAll(account, _msgSender()) ||
          isInterface(_msgSender(), id)),
      // ADDED || isInterface(_msgSender(),id))
      "ERC1155: caller is not owner nor interface nor approved"
    );

    super.burn(account, id, value);
  }

  /**
   * @dev See {IERC1155-safeTransferFrom}.
   * @dev CHANGED for gAVAX
   * interfaces can move your tokens without checking the compatibility of the receiver contract.
   */
  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    if (to.isContract() && !isInterface(operator, id)) {
      // ADDED !isInterface(_msgSender(),id))
      try
        IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data)
      returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "../../utils/DataStoreLib.sol";
import "../../utils/GeodeUtilsLib.sol";

contract TestGeodeUtils {
  using DataStoreUtils for DataStoreUtils.DataStore;
  using GeodeUtils for GeodeUtils.Universe;
  DataStoreUtils.DataStore private DATASTORE;
  GeodeUtils.Universe private GEODE;

  constructor(
    address _GOVERNANCE,
    address _SENATE,
    uint256 _OPERATION_FEE,
    uint256 _MAX_OPERATION_FEE
  ) {
    GEODE.GOVERNANCE = _GOVERNANCE;
    GEODE.SENATE = _SENATE;
    GEODE.SENATE_EXPIRE_TIMESTAMP = block.timestamp + 1 days;
    GEODE.OPERATION_FEE = _OPERATION_FEE;
    GEODE.MAX_OPERATION_FEE = _MAX_OPERATION_FEE;
    GEODE.FEE_DENOMINATOR = 10**10;

    GEODE.setElectorType(DATASTORE, 5, true); // allow type4 to vote for Senate

    GEODE.approvedUpgrade = address(0);
  }

  function getSenate() external view virtual returns (address) {
    return GEODE.getSenate();
  }

  function getGovernance() external view virtual returns (address) {
    return GEODE.getGovernance();
  }

  function getOperationFee() external view virtual returns (uint256) {
    return GEODE.getOperationFee();
  }

  function getFeeDenominator() external view virtual returns (uint256) {
    return GEODE.FEE_DENOMINATOR;
  }

  function getMaxOperationFee() external view virtual returns (uint256) {
    return GEODE.getMaxOperationFee();
  }

  function getSenateExpireTimestamp() external view virtual returns (uint256) {
    return GEODE.getSenateExpireTimestamp();
  }

  /**
   **  ID GETTERS **
   */
  function getIdsByType(uint256 _type)
    external
    view
    virtual
    returns (uint256[] memory)
  {
    return DATASTORE.allIdsByType[_type];
  }

  function getIdFromName(string calldata _name)
    external
    pure
    virtual
    returns (uint256 _id)
  {
    _id = uint256(keccak256(abi.encodePacked(_name)));
  }

  function getCONTROLLERFromId(uint256 _id)
    external
    view
    virtual
    returns (address)
  {
    return DATASTORE.readAddressForId(_id, "CONTROLLER");
  }

  /**
   *                                          ** SETTERS **
   */
  function changeIdCONTROLLER(uint256 _id, address _newCONTROLLER)
    external
    virtual
  {
    GeodeUtils.changeIdCONTROLLER(DATASTORE, _id, _newCONTROLLER);
  }

  /**
   * ** GOVERNANCE/SENATE SETTERS **
   */
  function setOperationFee(uint256 _newFee)
    external
    virtual
    returns (bool success)
  {
    // onlyGovernance CHECKED inside
    success = GEODE.setOperationFee(_newFee);
  }

  function setMaxOperationFee(uint256 _newFee)
    external
    virtual
    returns (bool success)
  {
    // onlySenate CHECKED inside
    success = GEODE.setMaxOperationFee(_newFee);
  }

  /**
   *                                          ** PROPOSALS **
   */

  function getProposal(uint256 id)
    external
    view
    virtual
    returns (GeodeUtils.Proposal memory)
  {
    return GEODE.getProposal(id);
  }

  function newProposal(
    address _CONTROLLER,
    uint256 _type,
    uint256 _proposalDuration,
    bytes calldata _name
  ) external virtual {
    require(
      DATASTORE
        .readBytesForId(uint256(keccak256(abi.encodePacked(_name))), "name")
        .length == 0,
      "GeodeUtils: name already claimed"
    );
    GEODE.newProposal(_CONTROLLER, _type, _proposalDuration, _name);
  }

  function approveProposal(uint256 _id) external virtual {
    GEODE.approveProposal(DATASTORE, _id);
  }

  function approveSenate(uint256 proposalId, uint256 electorId)
    external
    virtual
  {
    GEODE.approveSenate(DATASTORE, proposalId, electorId);
  }

  /// @dev DO NOT TOUCH, EVER! WHATEVER YOU DEVELOP IN FUCKING 3022.
  function isUpgradeAllowed(address proposed_implementation)
    external
    view
    virtual
    returns (bool)
  {
    return GEODE.isUpgradeAllowed(proposed_implementation);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "../../utils/DataStoreLib.sol";

contract DataStoreUtilsTest {
  using DataStoreUtils for DataStoreUtils.DataStore;
  DataStoreUtils.DataStore private DATASTORE;

  function readUintForId(uint256 _id, bytes32 _key)
    public
    view
    returns (uint256 data)
  {
    data = DATASTORE.readUintForId(_id, _key);
  }

  function readBytesForId(uint256 _id, bytes32 _key)
    public
    view
    returns (bytes memory data)
  {
    data = DATASTORE.readBytesForId(_id, _key);
  }

  function readAddressForId(uint256 _id, bytes32 _key)
    public
    view
    returns (address data)
  {
    data = DATASTORE.readAddressForId(_id, _key);
  }

  function writeUintForId(
    uint256 _id,
    bytes32 _key,
    uint256 data
  ) public {
    DATASTORE.writeUintForId(_id, _key, data);
  }

  function writeBytesForId(
    uint256 _id,
    bytes32 _key,
    bytes memory data
  ) public {
    DATASTORE.writeBytesForId(_id, _key, data);
  }

  function writeAddressForId(
    uint256 _id,
    bytes32 _key,
    address data
  ) public {
    DATASTORE.writeAddressForId(_id, _key, data);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

import "../../Portal.sol";

contract PortalV2 is Portal {
  using DataStoreUtils for DataStoreUtils.DataStore;
  using GeodeUtils for GeodeUtils.Universe;
  using StakeUtils for StakeUtils.StakePool;
  uint256 private newParam;
  uint256 private constant newConstParam = 42;

  function initializeV2(uint256 _versionNumber) public virtual {
    require(CONTRACT_VERSION == 1);
    // getVersion
    CONTRACT_VERSION = _versionNumber;
    emit ContractVersionSet(CONTRACT_VERSION);
  }

  function setNewParam(uint256 value) public {
    newParam = value;
  }

  function getNewParam() public view returns (uint256) {
    return newParam;
  }

  function getNewConstParam() public pure returns (uint256) {
    return newConstParam;
  }

  function setNewParamOnlyGovernance(uint256 value) public onlyGovernance {
    newParam = value;
  }

  function getNewParamOnlyGovernance() public view onlyGovernance returns (uint256) {
    return newParam;
  }

  uint256[43] private __gap;
}