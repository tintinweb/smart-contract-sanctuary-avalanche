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
    uint256 distributedFeeTotal
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
  ) external {
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

   * @param _opIds all ids of all operators who still collect fees.
   * @param _pBalanceIncreases the amount of avax that has been gained by the operator as POS rewards, respective to _opIds
   * @dev simply the new price is found by (pBALANCE + surplus - fees) / totalSupply)
   * @return price : new price after sanitychecks, might be useful if onchain oracle in the future
   */
  function reportOracle(
    StakePool storage self,
    DataStoreUtils.DataStore storage _DATASTORE,
    uint256 _poolId,
    uint256[] calldata _opIds,
    uint256[] calldata _pBalanceIncreases
  ) external returns (uint256 price) {
    require(msg.sender == self.ORACLE, "StakeUtils: msg.sender NOT oracle");
    require(
      _isOracleActive(_DATASTORE, _poolId),
      "StakeUtils: Oracle is NOT active"
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
    emit OracleUpdate(_poolId, price, newPBalance, totalFees);
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
   // meaning false, importantly length = 0
   return _DATASTORE.readBytesForId(_id, "stakePaused").length == 0;
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
      getgAVAX(self),
      _id,
      string(
        abi.encodePacked(
          "Geode-",
          _DATASTORE.readBytesForId(_id, "name"),
          " WP Token"
        )
      ),
      string(
        abi.encodePacked(_DATASTORE.readBytesForId(_id, "name"), "-GeoWP")
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
      isStakingPausedForPool(_DATASTORE, poolId),
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

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IgAVAX.sol";

interface ISwap {
  // pool data view functions
  function getA() external view returns (uint256);

  function getToken() external view returns (uint256);

  function getTokenBalance(uint8 index) external view returns (uint256);

  function getVirtualPrice() external view returns (uint256);

  function isGuarded() external view returns (bool);

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
    IgAVAX _wETH2Reference,
    uint256 _tokenId,
    string memory lpTokenName,
    string memory lpTokenSymbol,
    uint256 a,
    uint256 fee,
    uint256 adminFee,
    address lpTokenTargetAddress
  ) external returns (address lpToken);

  function getDebt() external view returns (uint256);

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