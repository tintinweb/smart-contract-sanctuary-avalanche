// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../interfaces/IController.sol";
import "../../interfaces/IPaymentsManager.sol";
import "../../interfaces/ICompanyManager.sol";
import "../../interfaces/IDebtsManager.sol";
import "../../third_party/uniswap/IUniswapV2Pair.sol";
import "../../openzeppelin/IERC20.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../interfaces/IControllable.sol";
import "../controller/Controllable.sol";
import "../../openzeppelin/Initializable.sol";

/// @notice Contract to pay salary to tetu team
contract PaymentsManager is Initializable, Controllable, IPaymentsManager {
    using SafeERC20 for IERC20;

    function initialize(address controller_) external initializer {
        Controllable.__Controllable_init(controller_);
    }

    /// @notice Pay specified amount of salary tokens to the wallet
    /// @param amountST_ Amount of salary tokens, decimals 10^18
    function pay(address wallet_, uint amountST_, address salaryToken_) external override {
        if (msg.sender != address(IController(_controller()).debtsManager())) {
            revert ErrorAccessDenied();
        }

        if (amountST_ > IERC20(salaryToken_).balanceOf(address(this))) {
            revert ErrorNotEnoughFund();
        }

        if (amountST_ == 0) {
            revert ErrorIncorrectAmount();
        }

        if (wallet_ == address(0)) {
            revert ErrorZeroAddress(0);
        }

        IERC20(salaryToken_).safeTransfer(wallet_, amountST_);
    }

    /// @notice Return available amount of salary token on balance of the payment manager
    function balance(address salaryToken_) external view returns (uint) {
        return IERC20(salaryToken_).balanceOf(address(this));
    }

    /// @dev Move tokens to governance
    ///      This contract should contain only governance funds
    function moveTokensToGovernance(address token_, uint amount) external {
        onlyGovernance();

        uint tokenBalance = IERC20(token_).balanceOf(address(this));
        if (tokenBalance < amount) {
            revert ErrorNotEnoughFund();
        }
        IERC20(token_).safeTransfer(IController(_controller()).governance(), amount);

        emit OnTokenMoved(token_, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IController {
  /// @notice Return governance address
  function governance() external view returns (address);

  /// @notice Return address of CompanyManager-instance
  function companyManager() external view returns (address);

  /// @notice Return address of RequestsManager-instance
  function requestsManager() external view returns (address);

  /// @notice Return address of DebtsManager-instance
  function debtsManager() external view returns (address);

  /// @notice Return address of PriceOracle-instance
  function priceOracle() external view returns (address);
  function setPriceOracle(address priceOracle) external;

  /// @notice Return address of PaymentsManager-instance
  function paymentsManager() external view returns (address);

  /// @notice Return address of Approvals-instance
  function approvalsManager() external view returns (address);

  /// @notice Return address of BatchReader-instance
  function batchReader() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";

/// @notice Interface for RequestManager
interface IPaymentsManager is IClerkTypes {
  event OnTokenMoved(address token, uint amount);

  /// @notice Pay specified amount of salary tokens to the wallet
  /// @param amountST_ Amount of salary tokens, decimals 10^18
  function pay(address wallet_, uint amountST_, address salaryToken_) external;

  /// @notice Return available amount of salary token on balance of the payment manager
  function balance(address salaryToken_) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./ICompanyManagerDepartments.sol";

/// @notice Provides info about workers, budgets, deparments, roles
interface ICompanyManager is ICompanyManagerDepartments {
    function initRoles(
        string[] memory names_
    , CountApprovals[] memory countApprovals_
    ) external;

    function setWeekBudget(AmountST amountST, address salaryToken_) external;
    function setBudgetShares(
        DepartmentUid[] calldata departmentUids_
    , uint[] calldata departmentShares_
    ) external;

    function getBudgetShares()
    external
    view
    returns (
        DepartmentUid[] memory outDepartmentUids
    , uint[] memory outDepartmentShares
    , uint outSumShares
    );

    function setRoleShares(
        DepartmentUid departmentUid_,
        uint[] memory roleShares_
    ) external;

    /// @notice Check if approver is alloed to approve requests of the worker "by nature"
    ///         i.e. without any manually-set approving-permissions.
    ///         The approver is allowed to approve worker's request "by nature" if one of the following
    ///         conditions is true:
    ///         1) the approver is a head of the worker's department (and worker != approver)
    ///         2) if the option approve-low-by-high is enabled for the department
    ///            both approver and worker belong to the same department
    ///            and the approver has higher role then the worker
    function isNatureApprover(address approver_, WorkerUid worker_) external view returns (ApproverKind);

    function getCountRequiredApprovals(RoleUid role) external view returns (CountApprovals);

    /// @notice Get max allowed amount [salary token]
    ///         that can be paid for each role of the department
    /// @return outAmountST Result amounts for all roles
    ///         The length of array is equal to companyManager.countRoles
    function getMaxWeekBudgetForRolesST(DepartmentUid departmentUid)
    external
    view
    returns (
        AmountST[] memory outAmountST
    );

    /// @notice Get week budgets for all departments [in salary token]
    /// @return departments List of departments with not-zero week budget
    /// @return amountsST Week budget for each department
    /// @return outSalaryToken Currently used salary token, week budget is set using it.
    function getWeekBudgetsST()
    external
    view
    returns (
        DepartmentUid[] memory departments
        , AmountST[] memory amountsST
        , address outSalaryToken
    );

    function lengthRoles() external view returns (uint);

    function getRoleByIndex(uint16 index0) external pure returns (RoleUid);

    function lengthDepartmentToWorkers(DepartmentUid uid) external view returns (uint);

    /// ************************************************************
    /// * Direct access to public mapping for BatchReader-purposes *
    /// * All functions below were generated from artifact jsons   *
    /// * using https://gnidan.github.io/abi-to-sol/               *
    /// ************************************************************

    /// @dev Access to the mapping {workersData}
    function workersData(WorkerUid)
    external
    view
    returns (
        WorkerUid uid,
        HourRate hourRate,
        RoleUid role,
        WorkerFlags workerFlags,
        address wallet,
        string memory name
    );

    /// @dev Access to the mapping {workerToDepartment}
    function workerToDepartment(WorkerUid) external view returns (DepartmentUid);

    /// @dev Access to the mapping {departments}
    function departments(uint256) external view returns (DepartmentUid);

    /// @dev Access to the mapping {departmentsData}
    function departmentsData(DepartmentUid)
    external
    view
    returns (
        DepartmentUid uid,
        address head,
        string memory title
    );

    /// @dev Access to public variable {countRoles}
    function countRoles() external view returns (uint16);

    function rolesData(RoleUid)
    external
    view
    returns (
        RoleUid role,
        CountApprovals countApprovals,
        string memory title
    );

    /// @dev Access to the mapping {workers}
    function workers(uint256) external view returns (WorkerUid);

    /// @dev Access to the mapping {departmentToWorkers}
    function departmentToWorkers(DepartmentUid, uint256)
    external
    view
    returns (WorkerUid);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./IDebtsManagerBase.sol";

/// @notice Interface for RequestManager
interface IDebtsManager is IDebtsManagerBase {

    /// @notice Register new request with status "Registered"
    ///         It's allowed to register same request several times
    ///         (user makes several attempts to send request)
    ///         but only most recent version is stored.
    function addRequest(
        RequestUid requestUid_
        , WorkerUid workerUid_
        , uint32 countHours
        , string calldata descriptionUrl
    ) external;

    /// @notice Convert salary-amount of accepted request to company-debt
    ///         Amount of the debt is auto calculated using requests properties: countHours * hourRate
    function addDebt(
        RequestUid requestUid_
    ) external;

    /// @notice Revoke previously created debt
    ///         As result, we can have holes in the sequence of registered debts
    function revokeDebtForRequest(RequestUid requestUid_) external;

    /// @notice Increment epoch counter.
    ///         Initialize week budget available for the payment of all exist debts.
    ///         After that it's possible to make payments for debts registered in the previous epochs
    /// @param paySalaryImmediately If true then call pay() immediately after starting new epoch
    function startEpoch(bool paySalaryImmediately) external;

    function payForRole(DepartmentUid departmentUid, RoleUid role) external;
    function payForDepartment(DepartmentUid departmentUid) external;
    function pay() external;
    function payDebt(DepartmentUid departmentUid, RoleUid role, uint64 indexDebt0) external;

// Functions for Readers

    function getRequestRole(RequestUid requestUid_) external view returns (RoleUid);
    function getRequestWorker(RequestUid requestUid_) external view returns (WorkerUid);
    function lengthDepartments() external view returns (uint);
    function lengthWeekBudgetLimitsForRolesST(DepartmentUid departmentUid) external view returns (uint);
    function wrapToNullableValue64(uint64 value) external pure returns (NullableValue64);

    /// ************************************************************
    /// * Direct access to public mapping for BatchReader-purposes *
    /// * All functions below were generated from artifact jsons   *
    /// * using https://gnidan.github.io/abi-to-sol/               *
    /// ************************************************************

    /// @dev Access to the mapping {requestsData}
    function requestsData(RequestUid)
    external
    view
    returns (
        WorkerUid worker,
        RoleUid role,
        DepartmentUid department,
        HourRate hourRate,
        uint32 countHours,
        EpochType epoch,
        string memory descriptionUrl
    );

    /// @dev Access to the mapping {requestsToDebts}
    function requestsToDebts(RequestUid) external view returns (DebtUid);

    /// @dev Access to the mapping {statForWorkers}
    function statForWorkers(WorkerUid)
    external
    view
    returns (uint32 workedHours, AmountUSD earnedDollars);

    /// @dev Access to the mapping {weekBudgetST}
    function weekBudgetST(DepartmentUid) external view returns (AmountST);

    /// @dev Access to the mapping {weekBudgetLimitsForRolesST}
    function weekBudgetLimitsForRolesST(DepartmentUid, uint256)
    external
    view
    returns (AmountST);

    /// @dev Access to the public variable {weekSalaryToken}
    function weekSalaryToken() external view returns (address);

    /// @dev Access to the mapping {roleDebts}
    function roleDebts(DepartmentUid, RoleUid)
    external
    view
    returns (
        uint64 totalCountDebts,
        uint64 firstUnpaidDebtIndex0,
        AmountUSD amountUnpaidTotalUSD
    );

    /// @dev Access to the mapping {roleDebtsList}
    function roleDebtsList(
        DepartmentUid,
        RoleUid,
        NullableValue64
    ) external view returns (DebtUid);

    /// @dev Access to the public variable {maxRoleValueInAllTimes}
    function maxRoleValueInAllTimes() external view returns (RoleUid);

    /// @dev Access to the public variable {currentEpoch}
    function currentEpoch() external view returns (EpochType);

    /// @dev Access to the public variable {firstEpoch}
    function firstEpoch() external view returns (EpochType);

    function debtsToRequests(DebtUid) external view returns (RequestUid);
    function unpaidAmountsUSD(DebtUid) external view returns (AmountUSD);
    function departments(uint) external view returns (DepartmentUid);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

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
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
  unchecked {
    uint256 oldAllowance = token.allowance(address(this), spender);
    require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
    uint256 newAllowance = oldAllowance - value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.9;

interface IControllable {

  function isController(address _contract) external view returns (bool);

  function isGovernance(address _contract) external view returns (bool);

  function created() external view returns (uint256);

  function createdBlock() external view returns (uint256);

  function controller() external view returns (address);

  function increaseRevision(address oldLogic) external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.9;

import "../../openzeppelin/Initializable.sol";
import "../../lib/SlotsLib.sol";
import "../../interfaces/IControllable.sol";
import "../../interfaces/IController.sol";
//import "hardhat/console.sol";

/// @title Implement basic functionality for any contract that require strict control
/// @dev Can be used with upgradeable pattern.
///      Require call __Controllable_init() in any case.
/// @author belbix
abstract contract Controllable is Initializable, IControllable {
  using SlotsLib for bytes32;

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant CONTROLLABLE_VERSION = "1.0.0";

  bytes32 internal constant _CONTROLLER_SLOT = bytes32(uint(keccak256("eip1967.controllable.controller")) - 1);
  bytes32 internal constant _CREATED_SLOT = bytes32(uint(keccak256("eip1967.controllable.created")) - 1);
  bytes32 internal constant _CREATED_BLOCK_SLOT = bytes32(uint(keccak256("eip1967.controllable.created_block")) - 1);
  bytes32 internal constant _REVISION_SLOT = bytes32(uint(keccak256("eip1967.controllable.revision")) - 1);
  bytes32 internal constant _PREVIOUS_LOGIC_SLOT = bytes32(uint(keccak256("eip1967.controllable.prev_logic")) - 1);

  event ContractInitialized(address controller, uint ts, uint block);
  event RevisionIncreased(uint value, address oldLogic);

  error ErrorGovernanceOnly();
  error ErrorIncreaseRevisionForbidden();

  /// @notice Initialize contract after setup it as proxy implementation
  ///         Save block.timestamp in the "created" variable
  /// @dev Use it only once after first logic setup
  /// @param controller_ Controller address
  function __Controllable_init(address controller_) public initializer {
    require(controller_ != address(0), "Zero controller");
    _CONTROLLER_SLOT.set(controller_);
    _CREATED_SLOT.set(block.timestamp);
    _CREATED_BLOCK_SLOT.set(block.number);
    emit ContractInitialized(controller_, block.timestamp, block.number);
  }

  /// @dev Return true if given address is controller
  function isController(address _value) external override view returns (bool) {
    return _isController(_value);
  }

  function _isController(address _value) internal view returns (bool) {
    return _value == _controller();
  }

  /// @notice Return true if given address is setup as governance in Controller
  function isGovernance(address _value) external override view returns (bool) {
    return _isGovernance(_value);
  }

  function _isGovernance(address _value) internal view returns (bool) {
    return IController(_controller()).governance() == _value;
  }

  /// @dev Contract upgrade counter
  function revision() external view returns (uint){
    return _REVISION_SLOT.getUint();
  }

  /// @dev Previous logic implementation
  function previousImplementation() external view returns (address){
    return _PREVIOUS_LOGIC_SLOT.getAddress();
  }

  // ************* SETTERS/GETTERS *******************

  /// @notice Return controller address saved in the contract slot
  function controller() external view override returns (address) {
    return _controller();
  }

  function _controller() internal view returns (address result) {
    return _CONTROLLER_SLOT.getAddress();
  }

  /// @notice Return creation timestamp
  /// @return Creation timestamp
  function created() external view override returns (uint) {
    return _CREATED_SLOT.getUint();
  }

  /// @notice Return creation block number
  /// @return Creation block number
  function createdBlock() external override view returns (uint) {
    return _CREATED_BLOCK_SLOT.getUint();
  }

  /// @dev Revision should be increased on each contract upgrade
  function increaseRevision(address oldLogic) external override {
    if (msg.sender != address(this)) {
      revert ErrorIncreaseRevisionForbidden();
    }
    uint r = _REVISION_SLOT.getUint() + 1;
    _REVISION_SLOT.set(r);
    _PREVIOUS_LOGIC_SLOT.set(oldLogic);
    emit RevisionIncreased(r, oldLogic);
  }

  // *****************************************************
  // *********** Functions instead of modifiers **********
  // Hardhat sometime doesn't parse correctly custom errors,
  // generated inside modifiers.
  // To reproduce the problem see
  //      git: ac9e9769ea2263dfbb741df7c11b8b5e96b03a4b (31.05.2022)
  // So, modifiers are replaced by ordinal functions
  // *****************************************************

  /// @dev Operations allowed only for Governance address
  function onlyGovernance() internal view {
    if (! _isGovernance(msg.sender)) {
      revert ErrorGovernanceOnly();
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
  /// @notice Initializable: contract is already initialized
  error ErrorAlreadyInitialized();

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
    if (!_initializing && _initialized) {
      revert ErrorAlreadyInitialized();
    }

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/// @notice All common user defined types, enums and custom errors
///         used by Payroll-clerk application contracts
interface IClerkTypes {

  // *****************************************************
  // ************* User defined types ********************
  // *****************************************************

  /// @notice Unique id of the worker, auto-generated using a counter
type WorkerUid is uint64;

  /// @notice Unique id of the departments (manually assigned by the governance)
type DepartmentUid is uint16;

  /// @notice Unique ID of a request
  ///         uint(keccak256(currentEpoch, worker))
type RequestUid is uint;

  /// @notice Unique global id of the registered debt.
  /// @dev This is order number of registered debt: 1,2,3... See _debtUidCounter
type DebtUid is uint64;

  /// @notice Unique id of the epoch.
  ///         Epoch is a period for which salary is paid. Usually it's 1 week.
  ///         Initially the epoch is initialized by some initial value, i.e. 34
  ///         and then it's incremented by one with each week
type EpochType is uint16;

  ///  @notice 1-based unique ID of worker role
  ///          lowest is novice, highest is nomarch
type RoleUid is uint16;

  /// @notice Amount in salary tokens
  ///         The salary token = the token used as a salary token in the current epoch
  ///                            to pay debts of the previous epochs.
type AmountST is uint256;

  /// @notice Amount in USD == countHours * hourRate (no decimals here)
type AmountUSD is uint64;

  /// @notice Hour rate = USD per hour
type HourRate is uint16;

  /// @notice Bitmask with optional features for departments
type DepartmentOptionMask is uint256;

  /// @notice Result of isApprover function
  ///         It can return any code, that explain the reason why
  ///         the particular address is considered as approver or not approver for the worker's requests
  ///         If the bit 0x1 is ON, this is approver
  ///         if the big 0x1 is OFF, this is NOT approver
  ///         CompanyManager and ApprovalsManager have various codes
type ApproverKind is uint256;

  /// @notice Encoded values: (RequestStatus, countPositiveApprovals, countNegativeApprovals)
type RequestStatusValue is uint;

  /// @notice how many approvals are required to approve a request created by the worker with the specified role
type CountApprovals is uint16;

  /// @notice Unique ID of an approval
  ///         uint(keccak256(approver, requestUid))
  ///         The uid is generated in a way that don't allow
  ///         an approver to create several approves for a single request
type ApprovalUid is uint;

  /// @notice uint64 with following characteristics:
  ///         - value 0 is used
  ///         - we need to use this type as a key or value in the mapping
  ///         So, all values are stored in the mapping as (value+1).
  ///         There is special function to wrap/unwrap value to this type.
type NullableValue64 is uint64;

  ///  @notice A hash of following unique data: uint(keccak256(approver-wallet, workerUid))
type ApproverPair is uint;

  ///  @notice Various boolean-attributes of the worker, i.e. "boost-calculator is used"
type WorkerFlags is uint96;

  // *****************************************************
  // ************* Enums and structs *********************
  // *****************************************************
  enum RequestStatus {
    Unknown_0,    //0
    /// @notice Worker has added the request, but the request is not still approved / rejected
    New_1,        //1
    /// @notice The request has got enough approvals to be accepted to payment
    Approved_2,   //2
    /// @notice The request has got at least one disapproval, so it cannot be accepted to payment
    Rejected_3,   //3
    /// @notice Worker has canceled the request
    Canceled_4    //4
  }

  enum ApprovePermissionKind {
    Unknown_0,
    /// @notice Permission to make an approval is given permanently
    Permanent_1,
    /// @notice Permission to make an approval is given temporary
    Delegated_2
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************
  /// @notice Worker not found, the worker ID is not registered
  error ErrorWorkerNotFound(WorkerUid uid);

  /// @notice The department is not registered
  error ErrorUnknownDepartment(DepartmentUid uid);

  /// @notice The address cannot be zero
  /// @param errorCode Some error code to help to identify exact place of the error in the source codes
  error ErrorZeroAddress(uint errorCode);

  /// @notice The amount cannot be zero or cannot exceed some limits
  error ErrorIncorrectAmount();

  /// @notice  A function to change data was called,
  ///          but new data is exactly the same as the stored data
  error ErrorDataNotChanged();

  /// @notice Provided string is empty
  error ErrorEmptyString();

  /// @notice Too long string
  error ErrorTooLongString(uint currentLength, uint maxAllowedLength);

  /// @notice You don't have permissions for such operation
  error ErrorAccessDenied();

  /// @notice Two or more arrays were passed to the function.
  ///         The arrays should have same length, but they haven't
  error ErrorArraysHaveDifferentLengths();

  /// @notice It's not allowed to send empty array to the called function
  error ErrorEmptyArrayNotAllowed();

  /// @notice Provided address is not registered as an approver of the worker
  error ErrorNotApprover(address providedAddress, WorkerUid worker);

  /// @notice You try to make action that is already performed
  ///         i.e. try to move a worker to a department whereas the worker is already a member of the department
  error ErrorActionIsAlreadyDone();

  error ErrorGovernanceOrDepartmentHeadOnly();

  /// @notice Some param has value = 0
  /// @param errorCode allows to identify exact problem place in the code
  error ErrorZeroValueNotAllowed(uint errorCode);

  /// @notice Hour rate must be greater then zero and less or equal then the given threshold (MAX_HOURLY_RATE)
  error ErrorIncorrectRate(HourRate rate);

  /// @notice You try to set new head of a department
  ///         But the account is alreayd the head of the this or other department
  error ErrorAlreadyHead(DepartmentUid);

  /// @notice The request is not registered
  error ErrorUnknownRequest(RequestUid uid);

  error ErrorNotEnoughFund();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./ICompanyManagerWorkers.sol";

/// @notice CompanyManager-functions to work with departments + workers
interface ICompanyManagerDepartments is ICompanyManagerWorkers {
    function addDepartment(
        DepartmentUid uid
    , string calldata departmentTitle
    ) external;

    function getDepartment(DepartmentUid uid)
    external
    view
    returns (address head, string memory departmentTitle);

    function setDepartmentHead(
        DepartmentUid departmentUid_
    , address head_
    ) external;

    function setDepartmentOptionApproveLowByHigh(DepartmentUid departmentUid, bool value) external;

    /// @notice Check if the wallet is a head of the worker's department
    function isDepartmentHead(address wallet, WorkerUid workerUid) external view returns (bool);

    function lengthDepartments() external view returns (uint);

    function moveWorkersToDepartment(
        WorkerUid[] calldata workers_
    , DepartmentUid departmentUid_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./ICompanyManagerBase.sol";

/// @notice CompanyManager-functions to work with workers
interface ICompanyManagerWorkers is ICompanyManagerBase {
  function addWorker(
    address wallet_,
    HourRate hourRate_,
    string calldata name_,
    RoleUid roles_
  ) external;

  function addWorkers(
    address[] calldata wallets_,
    HourRate[] calldata rates,
    string[] calldata names,
    RoleUid[] calldata roles
  ) external;

  function setWorkerName(WorkerUid workerUid, string calldata name_) external;
  function setWorkerRole(WorkerUid workerUid, RoleUid role_) external;
  function setHourlyRate(WorkerUid workerUid, HourRate rate_) external;

  function changeWallet(WorkerUid worker_, address newWallet) external;
  function getWorkerByWallet(address wallet) external view returns (WorkerUid);

  /// @notice Provide info required by RequestManager at the point of request registration
  ///         Return the role of worker. It is taken into account in salary payment algo.
  ///         If the worker has several roles, the role with highest permissions
  ///         will be return (i.e. NOMARCH + EDUCATED => NOMARCH)
  ///
  ///         Revert if the worker is not found
  function getWorkerInfo(WorkerUid worker_)
  external
  view
  returns (
    HourRate hourRate,
    RoleUid role,
    DepartmentUid departmentUid,
    string memory name,
    address wallet
  );

  /// @notice Return true if the worker is registered in workersData
  function isWorkerValid(WorkerUid worker_) external view returns (bool);

  ///  @notice Get active wallet for the given worker
  function getWallet(WorkerUid workerId_) external view returns (address);

  function lengthWorkers() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by CompanyManager and its readers
interface ICompanyManagerBase is IClerkTypes {
  struct RoleData {
    RoleUid role;
    /// @notice how many approvals are required to approve an worker's request with this role
    CountApprovals countApprovals;

    string title;
  }

  struct Department {
    /// @dev Arbitrary custom unique id > 0
    DepartmentUid uid;
    /// @notice A head of the department. Can be unassigned (0)
    address head;
    string title;
  }

  /// @notice Current worker settings
  struct Worker {
    /// @notice Unique permanent identifier of the worker
    /// @dev it's generated using _workerUidCounter. Started from 1
    WorkerUid uid;                        //64 bits
    /// @notice hour rate, $ per hour
    HourRate hourRate;                    //32 bits
    RoleUid role;                         //64 bits
    ///  @notice Various boolean-attributes of the worker, i.e. "boost-calculator is used"
    WorkerFlags workerFlags;              //96 bits
    //                                    //256 bits in total

    /// @notice current wallet of the worker
    /// @dev it can be changed, so it can be different from uid
    address wallet;
    string name;
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************

  error ErrorCannotMoveHeadToAnotherDepartment();

  /// @notice You try to register new worker with a wallet
  ///         that is already registered for some other worker
  error ErrorWalletIsAlreadyUsedByOtherWorker();

  /// @notice Provided list of roles is incorrect (i.e. incomplete or it contains unregistered role)
  error ErrorIncorrectRoles();

  /// @notice Total sum of shared of all departments must be equal to TOTAL_SUM_SHARES
  error ErrorIncorrectSharesSum(uint currentSum, uint requiredSum);

  /// @notice Share must be greater then zero.
  ///         If you need assign share = 0 to a department, just exclude the department from the list
  ///         of the departments passed to setBudgetShares
  error ErrorZeroDepartmentBudgetShare();

  /// @notice The department is already registered, try to use another uid for new department
  error ErrorDepartmentAlreadyRegistered(DepartmentUid uid);

  /// @notice It's not possible to set new wallet for a worker
  ///         if the wallet is used as approver for the worker
  error ErrorNewWalletIsUsedByApprover();

  /// @notice setBudgetShares is not called
  error ErrorUnknownBudgetShares();

  /// @notice companyManager.setWeekBudget was not called
  error ErrorZeroWeekBudget();

  /// @notice The role is not registered
  error ErrorRoleNotFound(RoleUid uid);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";
import "./IRequestsTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by DebtsManager and its readers
interface IDebtsManagerBase is IRequestsTypes {

  /// @notice All registered company-debts for the workers of the specified role
  ///         Unique order number of the debt registered for the specified pair (department, role)
  ///         All debts in the pair are numerated as 1, 2, 3 ...
  ///         and are payed exactly in the same order.
  struct RoleDebts {
    /// @notice Total count debts registered in debts-mapping.
    uint64 totalCountDebts;

    /// @notice 0-based index of first unpaid debt
    ///         Valid values [0...totalCountDebts)
    ///         The range [0...totalCountDebts) can contain revoked debts with unpaid amount = 0
    uint64 firstUnpaidDebtIndex0;

    /// @notice total unpaid amount by all debts in the role
    /// @dev This value can be used to know if there are any really unpaid debts for the (department, role)
    ///      firstUnpaidDebtIndex0 is not reliable for this purpose because of revoke debts
    AmountUSD amountUnpaidTotalUSD;
  }

  // *****************************************************
  // ************* Custom errors *************************
  // *****************************************************
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IClerkTypes.sol";

/// @notice All common user defined types, enums and structs
///         used by both RequestsManager and DebtsManager
interface IRequestsTypes is IClerkTypes {

  /// @notice Request to pay a salary to a worker
  ///         RequestData is stored in DebtsManaget
  ///         because request-data is used both in Debts and in Requests manager.
  struct RequestData {
    WorkerUid worker;           // 64 bit
    RoleUid role;               // 16 bit
    DepartmentUid department;   // 16 bit
    HourRate hourRate;          // 16 bit
    uint32 countHours;          // 32 bit
    EpochType epoch;            // 16 bit
    //                             160 bit in total


    /// @notice URL to the report with description how the hours were spent
    string descriptionUrl;
  }

  struct WorkerStat {
    /// @notice The number of hours an worker has worked during the entire period of work
    uint32 workedHours;

    /// @notice The dollar amount that the worker has earned over the entire period of working,
    ///         including paid salary and the company's current debt to the worker
    AmountUSD earnedDollars;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
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

pragma solidity 0.8.9;

/// @title Library for setting / getting slot variables (used in upgradable proxy contracts)
/// @author bogdoslav
library SlotsLib {

  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string public constant SLOT_LIB_VERSION = "1.0.0";

  // ************* GETTERS *******************

  /// @dev Gets a slot as bytes32
  function getBytes32(bytes32 slot) internal view returns (bytes32 result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as an address
  function getAddress(bytes32 slot) internal view returns (address result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot as uint
  function getUint(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  // ************* ARRAY GETTERS *******************

  /// @dev Gets an array length
  function arrayLength(bytes32 slot) internal view returns (uint result) {
    assembly {
      result := sload(slot)
    }
  }

  /// @dev Gets a slot array by index as address
  /// @notice First slot is array length, elements ordered backward in memory
  /// @notice This is unsafe, without checking array length.
  function addressAt(bytes32 slot, uint index) internal view returns (address result) {
    bytes32 pointer = bytes32(uint(slot) - 1 - index);
    assembly {
      result := sload(pointer)
    }
  }

  // ************* SETTERS *******************

  /// @dev Sets a slot with bytes32
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, bytes32 value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with address
  /// @notice Check address for 0 at the setter
  function set(bytes32 slot, address value) internal {
    assembly {
      sstore(slot, value)
    }
  }

  /// @dev Sets a slot with uint
  function set(bytes32 slot, uint value) internal {
    assembly {
      sstore(slot, value)
    }
  }

}