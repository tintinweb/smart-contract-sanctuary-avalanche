// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernancePowerDelegationToken {
  enum GovernancePowerType {
    VOTING,
    PROPOSITION
  }

  /**
   * @dev emitted when a user delegates to another
   * @param delegator the user which delegated governance power
   * @param delegatee the delegatee
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   **/
  event DelegateChanged(
    address indexed delegator,
    address indexed delegatee,
    GovernancePowerType delegationType
  );

  // @dev we removed DelegatedPowerChanged event because to reconstruct the full state of the system,
  // is enough to have Transfer and DelegateChanged TODO: document it

  /**
   * @dev delegates the specific power to a delegatee
   * @param delegatee the user which delegated power will change
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   **/
  function delegateByType(address delegatee, GovernancePowerType delegationType) external;

  /**
   * @dev delegates all the governance powers to a specific user
   * @param delegatee the user to which the powers will be delegated
   **/
  function delegate(address delegatee) external;

  /**
   * @dev returns the delegatee of an user
   * @param delegator the address of the delegator
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   * @return address of the specified delegatee
   **/
  function getDelegateeByType(address delegator, GovernancePowerType delegationType)
    external
    view
    returns (address);

  /**
   * @dev returns delegates of an user
   * @param delegator the address of the delegator
   * @return a tuple of addresses the VOTING and PROPOSITION delegatee
   **/
  function getDelegates(address delegator)
    external
    view
    returns (address, address);

  /**
   * @dev returns the current voting or proposition power of a user.
   * @param user the user
   * @param delegationType the type of delegation (VOTING, PROPOSITION)
   * @return the current voting or proposition power of a user
   **/
  function getPowerCurrent(address user, GovernancePowerType delegationType)
    external
    view
    returns (uint256);

  /**
   * @dev returns the current voting or proposition power of a user.
   * @param user the user
   * @return the current voting and proposition power of a user
   **/
  function getPowersCurrent(address user)
    external
    view
    returns (uint256, uint256);

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param delegator the owner of the funds
   * @param delegatee the user to who owner delegates his governance power
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION)
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function metaDelegateByType(
    address delegator,
    address delegatee,
    GovernancePowerType delegationType,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param delegator the owner of the funds
   * @param delegatee the user to who delegator delegates his voting and proposition governance power
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  function metaDelegate(
    address delegator,
    address delegatee,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernancePowerDelegationToken} from 'aave-token-v3/interfaces/IGovernancePowerDelegationToken.sol';
import {IMetaDelegateHelper} from './interfaces/IMetaDelegateHelper.sol';

/**
 * @title MetaDelegateHelper
 * @author BGD Labs
 * @notice The helper contract for the batch governance power delegation across multiple voting assets
 */
contract MetaDelegateHelper is IMetaDelegateHelper {
  /// @inheritdoc IMetaDelegateHelper
  function batchMetaDelegate(MetaDelegateParams[] calldata delegateParams)
    external
  {
    for (uint256 i = 0; i < delegateParams.length; i++) {
      if (delegateParams[i].delegationType == DelegationType.ALL) {
        delegateParams[i].underlyingAsset.metaDelegate(
          delegateParams[i].delegator,
          delegateParams[i].delegatee,
          delegateParams[i].deadline,
          delegateParams[i].v,
          delegateParams[i].r,
          delegateParams[i].s
        );
      } else {
        delegateParams[i].underlyingAsset.metaDelegateByType(
          delegateParams[i].delegator,
          delegateParams[i].delegatee,
          delegateParams[i].delegationType == DelegationType.VOTING
            ? IGovernancePowerDelegationToken.GovernancePowerType.VOTING
            : IGovernancePowerDelegationToken.GovernancePowerType.PROPOSITION,
          delegateParams[i].deadline,
          delegateParams[i].v,
          delegateParams[i].r,
          delegateParams[i].s
        );
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernancePowerDelegationToken} from 'aave-token-v3/interfaces/IGovernancePowerDelegationToken.sol';

/**
 * @title IMetaDelegateHelper
 * @author BGD Labs
 * @notice Interface containing the methods for the batch governance power delegation across multiple voting assets
 */

interface IMetaDelegateHelper {
  enum DelegationType {
    VOTING,
    PROPOSITION,
    ALL
  }

  /**
   * @notice an object including parameters for the delegation change
   * @param underlyingAsset the asset the governance power of which delegator wants to delegate
   * @param delegationType the type of governance power delegation (VOTING, PROPOSITION, ALL)
   * @param delegator the owner of the funds
   * @param delegatee the user to who owner delegates his governance power
   * @param deadline the deadline timestamp, type(uint256).max for no deadline
   * @param v signature param
   * @param s signature param
   * @param r signature param
   */
  struct MetaDelegateParams {
    IGovernancePowerDelegationToken underlyingAsset;
    DelegationType delegationType;
    address delegator;
    address delegatee;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @notice method for the batch upgrade governance power delegation across multiple voting assets with signatures
   * @param delegateParams an array with signatures with the user and assets to interact with
   */
  function batchMetaDelegate(MetaDelegateParams[] calldata delegateParams)
    external;
}