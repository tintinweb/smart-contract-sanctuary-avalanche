// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {KeeperCompatibleInterface} from 'chainlink-brownie-contracts/KeeperCompatible.sol';

import {IProofOfReserveExecutor} from '../interfaces/IProofOfReserveExecutor.sol';

/**
 * @author BGD Labs
 * @dev Aave chainlink keeper-compatible contract for proof of reserve:
 * - checks in simulation whether all reserves are backed
 * - executes emergency action for pool
 */
contract ProofOfReserveKeeper is KeeperCompatibleInterface {
  /**
   * @dev run off-chain, checks if all reserves are backed on passed pool and decides whether to run emergency action on-chain
   * @param checkData address of the ProofOfReserveExecutor contract
   */
  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool, bytes memory)
  {
    address executorAddress = abi.decode(checkData, (address));
    IProofOfReserveExecutor proofOfReserveExecutor = IProofOfReserveExecutor(
      executorAddress
    );

    if (
      !proofOfReserveExecutor.areAllReservesBacked() &&
      proofOfReserveExecutor.isEmergencyActionPossible()
    ) {
      return (true, checkData);
    }

    return (false, checkData);
  }

  /**
   * @dev if not all reserves are backed - executes emergency action for the pool
   * @param performData address of the ProofOfReserveExecutor contract
   */
  function performUpkeep(bytes calldata performData) external override {
    address executorAddress = abi.decode(performData, (address));

    IProofOfReserveExecutor proofOfReserveExecutor = IProofOfReserveExecutor(
      executorAddress
    );

    proofOfReserveExecutor.executeEmergencyAction();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProofOfReserveExecutor {
  /**
   * @dev emitted when new asset is enabled or disabled
   * @param asset the address of the asset
   * @param enabled whether it was enabled or disabled
   */
  event AssetStateChanged(address indexed asset, bool enabled);

  /**
   * @dev emitted when asset is not backed
   * @param asset asset that is not backed
   */
  event AssetIsNotBacked(address indexed asset);

  /**
   * @dev emitted when the emergency action is activated
   */
  event EmergencyActionExecuted();

  /**
   * @dev gets the list of the assets to check
   * @return returns all the assets that were enabled
   */
  function getAssets() external view returns (address[] memory);

  /**
   * @dev enable checking of proof of reserve for the passed list of assets
   * @param assets the addresses of the assets
   */
  function enableAssets(address[] memory assets) external;

  /**
   * @dev delete the assets and the proof of reserve feeds from the registry.
   * @param assets addresses of the assets
   */
  function disableAssets(address[] memory assets) external;

  /**
   * @dev returns if all the assets in the registry are backed.
   * @return bool returns true if all reserves are backed, otherwise false
   */
  function areAllReservesBacked() external view returns (bool);

  /**
   * @dev returns if emergency action parameters are not already adjusted.
   * This is not checked in executeEmergencyAction(), but is used
   * to prevent infinite execution of performUpkeep() inside the Keeper contract.
   * @return bool if it makes sense to execute the emergency action
   */
  function isEmergencyActionPossible() external view returns (bool);

  /**
   * @dev executes pool-specific action when at least
   * one of the assets in the registry is not backed.
   * v2: disable all borrowing and freeze the exploited assets
   * v3: set ltv to 0 for the broken assets and freeze them
   */
  function executeEmergencyAction() external;
}