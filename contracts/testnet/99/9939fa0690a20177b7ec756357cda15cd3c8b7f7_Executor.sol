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
 * @title Errors library
 * @author BGD Labs
 * @notice Defines the error messages emitted by the different contracts of the Aave Governance V3
 */
library Errors {
  string public constant VOTING_PORTALS_COUNT_NOT_0 = '1'; // to be able to rescue voting portals count must be 0
  string public constant AT_LEAST_ONE_PAYLOAD = '2'; // to create a proposal, it must have at least one payload
  string public constant VOTING_PORTAL_NOT_APPROVED = '3'; // the voting portal used to vote on proposal must be approved
  string public constant VOTING_CONFIG_IS_NOT_ACTIVE = '4'; // to create proposal the configuration associated with the access level must be active
  string public constant PROPOSITION_POWER_IS_TOO_LOW = '5'; // proposition power of proposal creator must be equal or higher than the specified threshold for the access level
  string public constant REQUESTED_ACCESS_LEVEL_IS_TOO_LOW = '6'; // access level should be at least as high as the level required to execute the proposal payload
  string public constant PROPOSAL_NOT_IN_CREATED_STATE = '7'; // proposal should be in the CREATED state
  string public constant PROPOSAL_NOT_IN_ACTIVE_STATE = '8'; // proposal must be in an ACTIVE state
  string public constant PROPOSAL_NOT_IN_QUEUED_STATE = '9'; // proposal must be in a QUEUED state
  string public constant VOTING_START_COOLDOWN_PERIOD_NOT_PASSED = '10'; // to activate a proposal vote, the cool down delay must pass
  string public constant TO_MANY_TOKENS_FOR_VOTING = '11'; // can not vote with more tokens than are allowed
  string public constant CALLER_NOT_A_VALID_VOTING_PORTAL = '12'; // only an allowed voting portal can queue a proposal
  string public constant QUEUE_COOLDOWN_PERIOD_NOT_PASSED = '13'; // to execute a proposal a cooldown delay must pass
  string public constant PROPOSAL_NOT_IN_THE_CORRECT_STATE = '14'; // proposal must be created but not executed yet to be able to be canceled
  string public constant CALLER_NOT_GOVERNANCE = '15'; // caller must be governance
  string public constant VOTER_ALREADY_VOTED_ON_PROPOSAL = '16'; // voter can only vote once per proposal using voting portal
  string public constant WRONG_MESSAGE_ORIGIN = '17'; // received message must come from registered source address, chain id, CrossChainController
  string public constant NO_VOTING_ASSETS = '18'; // Strategy must have voting assets
  string public constant WRONG_ENCODED_PROPOSAL_MESSAGE = '19'; // bridged proposal message is not following the appropriate format
  string public constant WRONG_ENCODED_VOTE_MESSAGE = '20'; // bridged vote message is not following the correct format
  string public constant WRONG_ENCODED_MESSAGE_RECEIVED = '21'; // the type of the bridged message is not accepted. Should be PROPOSAL or VOTE
  string public constant PROPOSAL_VOTE_ALREADY_CREATED = '22'; // vote on proposal can only be created once
  string public constant INVALID_SIGNATURE = '23'; // submitted signature is not valid
  string public constant PORTAL_VOTE_WITH_NO_VOTING_TOKENS = '24'; // voting portal vote needs to specify which voting tokens to use
  string public constant PROOFS_NOT_FOR_VOTING_TOKENS = '25'; // provided proofs must be from the voting tokens selected (bridged from governance chain)
  string public constant PROPOSAL_VOTE_NOT_FINISHED = '26'; // proposal vote must be finished
  string public constant PROPOSAL_VOTE_NOT_IN_ACTIVE_STATE = '27'; // proposal vote must be in active state
  string public constant PROPOSAL_VOTE_ALREADY_EXISTS = '28'; // proposal vote already exists
  string public constant VOTE_ONCE_FOR_ASSET = '29'; // an asset can only be used once per vote
  string public constant USER_BALANCE_DOES_NOT_EXISTS = '30'; // to vote an user must have balance in the token the user is voting with
  string public constant USER_VOTING_BALANCE_IS_ZERO = '31'; // to vote an user must have some balance between all the tokens selected for voting
  string public constant MISSING_AAVE_ROOTS = '32'; // must have AAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_ROOTS = '33'; // must have stkAAVE roots registered to use strategy
  string public constant MISSING_STK_AAVE_EXCHANGE_RATE = '34'; // must have stkAAVE exchange rate registered to use strategy
  string public constant UNPROCESSED_STORAGE_ROOT = '35'; // root must be registered beforehand
  string public constant NOT_ENOUGH_MSG_VALUE = '36'; // method was not called with enough value to execute the call
  string public constant FAILED_ACTION_EXECUTION = '37'; // action failed to execute
  string public constant SHOULD_BE_AT_LEAST_ONE_EXECUTOR = '38'; // at least one executor is needed
  string public constant INVALID_EMPTY_TARGETS = '39'; // target of the payload execution must not be empty
  string public constant EXECUTOR_WAS_NOT_SPECIFIED_FOR_REQUESTED_ACCESS_LEVEL =
    '40'; // payload executor must be registered for the specified payload access level
  string public constant PAYLOAD_NOT_IN_QUEUED_STATE = '41'; // payload must be en the queued state
  string public constant TIMELOCK_NOT_FINISHED = '42'; // delay has not passed before execution can be called
  string public constant GRACE_PERIOD_FINISHED = '43'; // time frame for execution has passed
  string public constant PAYLOAD_NOT_IN_THE_CORRECT_STATE = '44'; // payload must be created but not executed yet to be able to be canceled
  string public constant PAYLOAD_NOT_IN_CREATED_STATE = '45'; // payload must be in the created state
  string public constant PAYLOAD_EXPIRED = '46'; // delay after payload creation has passed so payload can not be queued
  string public constant MISSING_A_AAVE_ROOTS = '34'; // must have aAAVE roots registered to use strategy
}

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