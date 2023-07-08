// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Ownable} from 'solidity-utils/contracts/oz-common/Ownable.sol';
import {IExecutor} from './interfaces/IExecutor.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title Executor
 * @author BGD Labs
 * @notice this contract contains the logic to execute a payload.
 * @dev Same code for all Executor levels.
 */
contract Executor is IExecutor, Ownable {
  /// @inheritdoc IExecutor
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    bool withDelegatecall
  ) public payable onlyOwner returns (bytes memory) {
    require(target != address(0), Errors.INVALID_EXECUTION_TARGET);

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      require(msg.value >= value, Errors.NOT_ENOUGH_MSG_VALUE);
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.delegatecall(callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }

    require(success, Errors.FAILED_ACTION_EXECUTION);

    emit ExecutedAction(
      target,
      value,
      signature,
      data,
      block.timestamp,
      withDelegatecall,
      resultData
    );

    return resultData;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
pragma solidity ^0.8.0;

/**
 * @title IExecutor
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the Executor contract
 */
interface IExecutor {
  /**
   * @notice emitted when an action got executed
   * @param target address of the targeted contract
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param executionTime time at which to execute the transaction
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @param resultData the actual callData used on the target
   **/
  event ExecutedAction(
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 executionTime,
    bool withDelegatecall,
    bytes resultData
  );

  /**
   * @notice Function, called by Governance, that executes a transaction, returns the callData executed
   * @param target smart contract target
   * @param value wei value of the transaction
   * @param signature function signature of the transaction
   * @param data function arguments of the transaction or callData if signature empty
   * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
   * @return result data of the execution call.
   **/
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    bool withDelegatecall
  ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author BGD Labs
 * @notice Defines the error messages emitted by the different contracts of the Aave Governance V3
 */
library Errors {
  string public constant VOTING_PORTALS_COUNT_NOT_0 = '1'; // to be able to rescue voting portals count must be 0
  string public constant AT_LEAST_ONE_PAYLOAD = '2'; // to create a proposal, it must have at least one payload
  string public constant VOTING_PORTAL_NOT_APPROVED = '3'; // the voting portal used to vote on proposal must be approved
  string public constant PROPOSITION_POWER_IS_TOO_LOW = '4'; // proposition power of proposal creator must be equal or higher than the specified threshold for the access level
  string public constant PROPOSAL_NOT_IN_CREATED_STATE = '5'; // proposal should be in the CREATED state
  string public constant PROPOSAL_NOT_IN_ACTIVE_STATE = '6'; // proposal must be in an ACTIVE state
  string public constant PROPOSAL_NOT_IN_QUEUED_STATE = '7'; // proposal must be in a QUEUED state
  string public constant VOTING_START_COOLDOWN_PERIOD_NOT_PASSED = '8'; // to activate a proposal vote, the cool down delay must pass
  string public constant INVALID_VOTING_TOKENS = '9'; // can not vote with more tokens than are allowed
  string public constant CALLER_NOT_A_VALID_VOTING_PORTAL = '10'; // only an allowed voting portal can queue a proposal
  string public constant QUEUE_COOLDOWN_PERIOD_NOT_PASSED = '11'; // to execute a proposal a cooldown delay must pass
  string public constant PROPOSAL_NOT_IN_THE_CORRECT_STATE = '12'; // proposal must be created but not executed yet to be able to be canceled
  string public constant CALLER_NOT_GOVERNANCE = '13'; // caller must be governance
  string public constant VOTER_ALREADY_VOTED_ON_PROPOSAL = '14'; // voter can only vote once per proposal using voting portal
  string public constant WRONG_MESSAGE_ORIGIN = '15'; // received message must come from registered source address, chain id, CrossChainController
  string public constant NO_VOTING_ASSETS = '16'; // Strategy must have voting assets
  string public constant PROPOSAL_VOTE_ALREADY_CREATED = '17'; // vote on proposal can only be created once
  string public constant INVALID_SIGNATURE = '18'; // submitted signature is not valid
  string public constant INVALID_NUMBER_OF_PROOFS_FOR_VOTING_TOKENS = '19'; // Need all the necessary proofs to validate the voting tokens
  string public constant PROOFS_NOT_FOR_VOTING_TOKENS = '20'; // provided proofs must be from the voting tokens selected (bridged from governance chain)
  string public constant PROPOSAL_VOTE_NOT_FINISHED = '21'; // proposal vote must be finished
  string public constant PROPOSAL_VOTE_NOT_IN_ACTIVE_STATE = '22'; // proposal vote must be in active state
  string public constant PROPOSAL_VOTE_ALREADY_EXISTS = '23'; // proposal vote already exists
  string public constant VOTE_ONCE_FOR_ASSET = '24'; // an asset can only be used once per vote
  string public constant USER_BALANCE_DOES_NOT_EXISTS = '25'; // to vote an user must have balance in the token the user is voting with
  string public constant USER_VOTING_BALANCE_IS_ZERO = '26'; // to vote an user must have some balance between all the tokens selected for voting
  string public constant MISSING_AAVE_ROOTS = '27'; // must have AAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_ROOTS = '28'; // must have stkAAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_SLASHING_EXCHANGE_RATE = '29'; // must have stkAAVE slashing exchange rate registered to use strategy
  string public constant UNPROCESSED_STORAGE_ROOT = '30'; // root must be registered beforehand
  string public constant NOT_ENOUGH_MSG_VALUE = '31'; // method was not called with enough value to execute the call
  string public constant FAILED_ACTION_EXECUTION = '32'; // action failed to execute
  string public constant SHOULD_BE_AT_LEAST_ONE_EXECUTOR = '33'; // at least one executor is needed
  string public constant INVALID_EMPTY_TARGETS = '34'; // target of the payload execution must not be empty
  string public constant EXECUTOR_WAS_NOT_SPECIFIED_FOR_REQUESTED_ACCESS_LEVEL =
    '35'; // payload executor must be registered for the specified payload access level
  string public constant PAYLOAD_NOT_IN_QUEUED_STATE = '36'; // payload must be en the queued state
  string public constant TIMELOCK_NOT_FINISHED = '37'; // delay has not passed before execution can be called
  string public constant PAYLOAD_NOT_IN_THE_CORRECT_STATE = '38'; // payload must be created but not executed yet to be able to be canceled
  string public constant PAYLOAD_NOT_IN_CREATED_STATE = '39'; // payload must be in the created state
  string public constant MISSING_A_AAVE_ROOTS = '40'; // must have aAAVE roots registered to use strategy
  string public constant MISSING_PROPOSAL_BLOCK_HASH = '41'; // block hash for this proposal was not bridged before
  string public constant PROPOSAL_VOTE_CONFIGURATION_ALREADY_BRIDGED = '42'; // configuration for this proposal bridged already
  string public constant INVALID_VOTING_PORTAL_ADDRESS = '43'; // voting portal address can't be 0x0
  string public constant INVALID_POWER_STRATEGY = '44'; // 0x0 is not valid as the power strategy
  string public constant INVALID_EXECUTOR_ADDRESS = '45'; // executor address can't be 0x0
  string public constant EXECUTOR_ALREADY_SET_IN_DIFFERENT_LEVEL = '46'; // executor address already being used as executor of a different level
  string public constant INVALID_VOTING_DURATION = '47'; // voting duration can not be bigger than the time it takes to execute a proposal
  string public constant VOTING_DURATION_NOT_PASSED = '48'; // at least votingDuration should have passed since voting started for a proposal to be queued
  string public constant INVALID_PROPOSAL_ACCESS_LEVEL = '49'; // the bridged proposal access level does not correspond with the maximum access level required by the payload
  string public constant PAYLOAD_NOT_CREATED_BEFORE_PROPOSAL = '50'; // payload must be created before proposal
  string public constant INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS = '51';
  string public constant INVALID_MESSAGE_ORIGINATOR_ADDRESS = '51';
  string public constant INVALID_ORIGIN_CHAIN_ID = '52';
  string public constant INVALID_ACTION_TARGET = '54';
  string public constant INVALID_ACTION_ACCESS_LEVEL = '55';
  string public constant INVALID_EXECUTOR_ACCESS_LEVEL = '56';
  string public constant INVALID_VOTING_PORTAL_CROSS_CHAIN_CONTROLLER = '57';
  string public constant INVALID_VOTING_PORTAL_VOTING_MACHINE = '58';
  string public constant INVALID_VOTING_PORTAL_GOVERNANCE = '59';
  string public constant INVALID_VOTING_MACHINE_CHAIN_ID = '60';
  string public constant G_INVALID_CROSS_CHAIN_CONTROLLER_ADDRESS = '61';
  string public constant G_INVALID_IPFS_HASH = '62';
  string public constant G_INVALID_PAYLOAD_ACCESS_LEVEL = '63';
  string public constant G_INVALID_PAYLOADS_CONTROLLER = '64';
  string public constant G_INVALID_PAYLOAD_CHAIN = '65';
  string public constant POWER_STRATEGY_HAS_NO_TOKENS = '66'; // power strategy should at least have
  string public constant INVALID_VOTING_CONFIG_ACCESS_LEVEL = '67';
  string public constant VOTING_DURATION_TOO_SMALL = '68';
  string public constant INVALID_MINIMUM_VOTING_DURATION = '69';
  string public constant NO_BRIDGED_VOTING_ASSETS = '70';
  string public constant VOTE_ALREADY_BRIDGED = '71';
  string public constant INVALID_VOTER = '72';
  string public constant INVALID_DATA_WAREHOUSE = '73';
  string public constant INVALID_VOTING_MACHINE_CROSS_CHAIN_CONTROLLER = '75';
  string public constant INVALID_L1_VOTING_PORTAL = '76';
  string public constant INVALID_VOTING_PORTAL_CHAIN_ID = '77';
  string public constant INVALID_VOTING_STRATEGY = '78';
  string public constant INVALID_VOTING_ASSETS_WITH_SLOT = '79'; // Token slot is not defined on the strategy
  string public constant PROPOSAL_VOTE_CAN_NOT_BE_REGISTERED = '80'; // to register a bridged vote proposal vote must be in NotCreated or Active state
  string public constant INVALID_VOTE_CONFIGURATION_BLOCKHASH = '81';
  string public constant INVALID_VOTE_CONFIGURATION_VOTING_DURATION = '82';
  string public constant INVALID_GAS_LIMIT = '83';
  string public constant INVALID_VOTING_CONFIGS = '84'; // a lvl2 voting configuration must be sent to initializer
  string public constant INVALID_EXECUTOR_DELAY = '85';
  string public constant INVALID_BRIDGED_VOTING_TOKEN = '86'; // A bridged voting token must be on the strategy list
  string public constant BRIDGED_REPEATED_ASSETS = '87'; // bridged voting tokens must be unique
  string public constant CAN_NOT_VOTE_WITH_REPEATED_ASSETS = '88'; // voting tokens to bridge must be unique
  string public constant REPEATED_STRATEGY_ASSET = '89';
  string public constant EMPTY_ASSET_STORAGE_SLOTS = '90';
  string public constant REPEATED_STRATEGY_ASSET_SLOT = '91';
  string public constant INVALID_EXECUTION_TARGET = '92';
  string public constant MISSING_VOTING_CONFIGURATIONS = '93'; // voting configurations for lvl1 and lvl2 must be included on initialization
  string public constant INVALID_PROPOSITION_POWER = '94';
  string public constant INVALID_QUORUM = '95';
  string public constant INVALID_DIFFERENTIAL = '96';
  string public constant ETH_TRANSFER_FAILED = '97';
  string public constant INVALID_INITIAL_VOTING_CONFIGS = '98'; // initial voting configurations can not be of the same level
  string public constant INVALID_ACHIEVABLE_VOTING_PARTICIPATION = '99'; // achievable voting participation can't be 0
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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