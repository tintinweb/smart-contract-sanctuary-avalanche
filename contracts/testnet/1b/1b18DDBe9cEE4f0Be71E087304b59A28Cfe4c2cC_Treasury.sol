/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-04
*/

// File: contracts/interfaces/IAuthority.sol


pragma solidity >=0.7.5;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// File: contracts/libraries/types/AccessControlled.sol



pragma solidity >=0.7.5;


abstract contract AccessControlled {
  /* ========== EVENTS ========== */

  event AuthorityUpdated(IAuthority indexed authority);

  string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

  /* ========== STATE VARIABLES ========== */

  IAuthority public authority;

  /* ========== Constructor ========== */

  constructor(IAuthority _authority) {
    authority = _authority;
    emit AuthorityUpdated(_authority);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernor() {
    require(msg.sender == authority.governor(), UNAUTHORIZED);
    _;
  }

  modifier onlyGuardian() {
    require(msg.sender == authority.guardian(), UNAUTHORIZED);
    _;
  }

  modifier onlyPolicy() {
    require(msg.sender == authority.policy(), UNAUTHORIZED);
    _;
  }

  modifier onlyVault() {
    require(msg.sender == authority.vault(), UNAUTHORIZED);
    _;
  }

  /* ========== GOV ONLY ========== */

  function setAuthority(IAuthority _newAuthority) external onlyGovernor {
    authority = _newAuthority;
    emit AuthorityUpdated(_newAuthority);
  }
}

// File: contracts/interfaces/ITreasury.sol


pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (uint256);

    function baseSupply() external view returns (uint256);
}

// File: contracts/interfaces/IBondingCalculator.sol


pragma solidity 0.8.12;

interface IBondingCalculator {
  function valuation(address pair_, uint256 amount_)
    external
    view
    returns (uint256 _value);
}

// File: contracts/interfaces/IOwnable.sol


pragma solidity 0.8.12;

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}
// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.12;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/interfaces/IsREQ.sol


pragma solidity >=0.8.5;


interface IsREQ is IERC20 {
    function rebase(uint256 reqProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function toG(uint256 amount) external view returns (uint256);

    function fromG(uint256 amount) external view returns (uint256);

    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
}

// File: contracts/interfaces/IREQ.sol


pragma solidity >=0.7.5;


interface IREQ is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// File: contracts/interfaces/ERC20/IERC20Metadata.sol



pragma solidity ^0.8.12;


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
// File: contracts/libraries/SafeERC20.sol



// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.8.12;


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
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   *
   * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    (bool success, bytes memory returndata) = token.call(data);

    // If the low-level call didn't succeed we return whatever was returned from it.
    assembly {
      if eq(success, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
    require(
      returndata.length == 0 || abi.decode(returndata, (bool)),
      "SAFE_ERC20_CALL_FAILED"
    );
  }
}

// File: contracts/Treasury.sol


pragma solidity ^0.8.12;










contract Treasury is AccessControlled, ITreasury {
  /* ========== DEPENDENCIES ========== */

  using SafeERC20 for IERC20;

  /* ========== EVENTS ========== */

  event Deposit(address indexed token, uint256 amount, uint256 value);
  event Withdrawal(address indexed token, uint256 amount, uint256 value);
  event CreateDebt(
    address indexed debtor,
    address indexed token,
    uint256 amount,
    uint256 value
  );
  event RepayDebt(
    address indexed debtor,
    address indexed token,
    uint256 amount,
    uint256 value
  );
  event Managed(address indexed token, uint256 amount);
  event ReservesAudited(uint256 indexed totalReserves);
  event Minted(
    address indexed caller,
    address indexed recipient,
    uint256 amount
  );
  event PermissionQueued(STATUS indexed status, address queued);
  event Permissioned(address addr, STATUS indexed status, bool result);

  /* ========== DATA STRUCTURES ========== */

  enum STATUS {
    RESERVEDEPOSITOR,
    RESERVESPENDER,
    RESERVETOKEN,
    RESERVEMANAGER,
    LIQUIDITYDEPOSITOR,
    LIQUIDITYTOKEN,
    LIQUIDITYMANAGER,
    RESERVEDEBTOR,
    REWARDMANAGER,
    SREQ,
    REQDEBTOR
  }

  struct Queue {
    STATUS managing;
    address toPermit;
    address calculator;
    uint256 timelockEnd;
    bool nullify;
    bool executed;
  }

  /* ========== STATE VARIABLES ========== */

  IREQ public immutable REQ;
  IsREQ public sREQ;

  mapping(STATUS => address[]) public registry;
  mapping(STATUS => mapping(address => bool)) public permissions;
  mapping(address => address) public bondCalculator;

  mapping(address => uint256) public debtLimit;

  uint256 public totalReserves;
  uint256 public totalDebt;
  uint256 public reqDebt;

  Queue[] public permissionQueue;
  uint256 public immutable blocksNeededForQueue;

  bool public timelockEnabled;
  bool public initialized;

  uint256 public onChainGovernanceTimelock;

  string internal notAccepted = "Treasury: not accepted";
  string internal notApproved = "Treasury: not approved";
  string internal invalidToken = "Treasury: invalid token";
  string internal insufficientReserves = "Treasury: insufficient reserves";

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _req,
    uint256 _timelock,
    address _authority
  ) AccessControlled(IAuthority(_authority)) {
    require(_req != address(0), "Zero address: REQ");
    REQ = IREQ(_req);

    timelockEnabled = false;
    initialized = false;
    blocksNeededForQueue = _timelock;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice allow approved address to deposit an asset for REQ
   * @param _amount uint256
   * @param _token address
   * @param _profit uint256
   * @return send_ uint256
   */
  function deposit(
    uint256 _amount,
    address _token,
    uint256 _profit
  ) external override returns (uint256 send_) {
    if (permissions[STATUS.RESERVETOKEN][_token]) {
      require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);
    } else if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
      require(permissions[STATUS.LIQUIDITYDEPOSITOR][msg.sender], notApproved);
    } else {
      revert(invalidToken);
    }

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 value = tokenValue(_token, _amount);
    // mint REQ needed and store amount of rewards for distribution
    send_ = value - _profit;
    REQ.mint(msg.sender, send_);

    totalReserves += value;

    emit Deposit(_token, _amount, value);
  }

  /**
   * @notice allow approved address to burn REQ for reserves
   * @param _amount uint256
   * @param _token address
   */
  function withdraw(uint256 _amount, address _token) external override {
    require(permissions[STATUS.RESERVETOKEN][_token], notAccepted); // Only reserves can be used for redemptions
    require(permissions[STATUS.RESERVESPENDER][msg.sender], notApproved);

    uint256 value = tokenValue(_token, _amount);
    REQ.burnFrom(msg.sender, value);

    totalReserves -= value;

    IERC20(_token).safeTransfer(msg.sender, _amount);

    emit Withdrawal(_token, _amount, value);
  }

  /**
   * @notice allow approved address to withdraw assets
   * @param _token address
   * @param _amount uint256
   */
  function manage(address _token, uint256 _amount) external override {
    if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
      require(permissions[STATUS.LIQUIDITYMANAGER][msg.sender], notApproved);
    } else {
      require(permissions[STATUS.RESERVEMANAGER][msg.sender], notApproved);
    }
    if (
      permissions[STATUS.RESERVETOKEN][_token] ||
      permissions[STATUS.LIQUIDITYTOKEN][_token]
    ) {
      uint256 value = tokenValue(_token, _amount);
      require(value <= excessReserves(), insufficientReserves);
      totalReserves -= value;
    }
    IERC20(_token).safeTransfer(msg.sender, _amount);
    emit Managed(_token, _amount);
  }

  /**
   * @notice mint new REQ using excess reserves
   * @param _recipient address
   * @param _amount uint256
   */
  function mint(address _recipient, uint256 _amount) external override {
    require(permissions[STATUS.REWARDMANAGER][msg.sender], notApproved);
    require(_amount <= excessReserves(), insufficientReserves);
    REQ.mint(_recipient, _amount);
    emit Minted(msg.sender, _recipient, _amount);
  }

  /**
   * DEBT: The debt functions allow approved addresses to borrow treasury assets
   * or REQ from the treasury, using sREQ as collateral. This might allow an
   * sREQ holder to provide REQ liquidity without taking on the opportunity cost
   * of unstaking, or alter their backing without imposing risk onto the treasury.
   * Many of these use cases are yet to be defined, but they appear promising.
   * However, we urge the community to think critically and move slowly upon
   * proposals to acquire these permissions.
   */

  /**
   * @notice allow approved address to borrow reserves
   * @param _amount uint256
   * @param _token address
   */
  function incurDebt(uint256 _amount, address _token) external override {
    uint256 value;
    if (_token == address(REQ)) {
      require(permissions[STATUS.REQDEBTOR][msg.sender], notApproved);
      value = _amount;
    } else {
      require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
      require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
      value = tokenValue(_token, _amount);
    }
    require(value != 0, invalidToken);

    sREQ.changeDebt(value, msg.sender, true);
    require(
      sREQ.debtBalances(msg.sender) <= debtLimit[msg.sender],
      "Treasury: exceeds limit"
    );
    totalDebt += value;

    if (_token == address(REQ)) {
      REQ.mint(msg.sender, value);
      reqDebt += value;
    } else {
      totalReserves -= value;
      IERC20(_token).safeTransfer(msg.sender, _amount);
    }
    emit CreateDebt(msg.sender, _token, _amount, value);
  }

  /**
   * @notice allow approved address to repay borrowed reserves with reserves
   * @param _amount uint256
   * @param _token address
   */
  function repayDebtWithReserve(uint256 _amount, address _token)
    external
    override
  {
    require(permissions[STATUS.RESERVEDEBTOR][msg.sender], notApproved);
    require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 value = tokenValue(_token, _amount);
    sREQ.changeDebt(value, msg.sender, false);
    totalDebt -= value;
    totalReserves += value;
    emit RepayDebt(msg.sender, _token, _amount, value);
  }

  /**
   * @notice allow approved address to repay borrowed reserves with REQ
   * @param _amount uint256
   */
  function repayDebtWithREQ(uint256 _amount) external {
    require(
      permissions[STATUS.RESERVEDEBTOR][msg.sender] ||
        permissions[STATUS.REQDEBTOR][msg.sender],
      notApproved
    );
    REQ.burnFrom(msg.sender, _amount);
    sREQ.changeDebt(_amount, msg.sender, false);
    totalDebt -= _amount;
    reqDebt -= _amount;
    emit RepayDebt(msg.sender, address(REQ), _amount, _amount);
  }

  /* ========== MANAGERIAL FUNCTIONS ========== */

  /**
   * @notice takes inventory of all tracked assets
   * @notice always consolidate to recognized reserves before audit
   */
  function auditReserves() external onlyGovernor {
    uint256 reserves;
    address[] memory reserveToken = registry[STATUS.RESERVETOKEN];
    for (uint256 i = 0; i < reserveToken.length; i++) {
      if (permissions[STATUS.RESERVETOKEN][reserveToken[i]]) {
        reserves += tokenValue(
          reserveToken[i],
          IERC20(reserveToken[i]).balanceOf(address(this))
        );
      }
    }
    address[] memory liquidityToken = registry[STATUS.LIQUIDITYTOKEN];
    for (uint256 i = 0; i < liquidityToken.length; i++) {
      if (permissions[STATUS.LIQUIDITYTOKEN][liquidityToken[i]]) {
        reserves += tokenValue(
          liquidityToken[i],
          IERC20(liquidityToken[i]).balanceOf(address(this))
        );
      }
    }
    totalReserves = reserves;
    emit ReservesAudited(reserves);
  }

  /**
   * @notice set max debt for address
   * @param _address address
   * @param _limit uint256
   */
  function setDebtLimit(address _address, uint256 _limit)
    external
    onlyGovernor
  {
    debtLimit[_address] = _limit;
  }

  /**
   * @notice enable permission from queue
   * @param _status STATUS
   * @param _address address
   * @param _calculator address
   */
  function enable(
    STATUS _status,
    address _address,
    address _calculator
  ) external onlyGovernor {
    require(timelockEnabled == false, "Use queueTimelock");
    if (_status == STATUS.SREQ) {
      sREQ = IsREQ(_address);
    } else {
      permissions[_status][_address] = true;

      if (_status == STATUS.LIQUIDITYTOKEN) {
        bondCalculator[_address] = _calculator;
      }

      (bool registered, ) = indexInRegistry(_address, _status);
      if (!registered) {
        registry[_status].push(_address);

        if (
          _status == STATUS.LIQUIDITYTOKEN || _status == STATUS.RESERVETOKEN
        ) {
          (bool reg, uint256 index) = indexInRegistry(_address, _status);
          if (reg) {
            delete registry[_status][index];
          }
        }
      }
    }
    emit Permissioned(_address, _status, true);
  }

  /**
   *  @notice disable permission from address
   *  @param _status STATUS
   *  @param _toDisable address
   */
  function disable(STATUS _status, address _toDisable) external {
    require(
      msg.sender == authority.governor() || msg.sender == authority.guardian(),
      "Only governor or guardian"
    );
    permissions[_status][_toDisable] = false;
    emit Permissioned(_toDisable, _status, false);
  }

  /**
   * @notice check if registry contains address
   * @return (bool, uint256)
   */
  function indexInRegistry(address _address, STATUS _status)
    public
    view
    returns (bool, uint256)
  {
    address[] memory entries = registry[_status];
    for (uint256 i = 0; i < entries.length; i++) {
      if (_address == entries[i]) {
        return (true, i);
      }
    }
    return (false, 0);
  }

  /* ========== TIMELOCKED FUNCTIONS ========== */

  // functions are used prior to enabling on-chain governance

  /**
   * @notice queue address to receive permission
   * @param _status STATUS
   * @param _address address
   * @param _calculator address
   */
  function queueTimelock(
    STATUS _status,
    address _address,
    address _calculator
  ) external onlyGovernor {
    require(_address != address(0));
    require(timelockEnabled == true, "Timelock is disabled, use enable");

    uint256 timelock = block.number + blocksNeededForQueue;
    if (
      _status == STATUS.RESERVEMANAGER || _status == STATUS.LIQUIDITYMANAGER
    ) {
      timelock = block.number + blocksNeededForQueue * 2;
    }
    permissionQueue.push(
      Queue({
        managing: _status,
        toPermit: _address,
        calculator: _calculator,
        timelockEnd: timelock,
        nullify: false,
        executed: false
      })
    );
    emit PermissionQueued(_status, _address);
  }

  /**
   *  @notice enable queued permission
   *  @param _index uint256
   */
  function execute(uint256 _index) external {
    require(timelockEnabled == true, "Timelock is disabled, use enable");

    Queue memory info = permissionQueue[_index];

    require(!info.nullify, "Action has been nullified");
    require(!info.executed, "Action has already been executed");
    require(block.number >= info.timelockEnd, "Timelock not complete");

    if (info.managing == STATUS.SREQ) {
      // 9
      sREQ = IsREQ(info.toPermit);
    } else {
      permissions[info.managing][info.toPermit] = true;

      if (info.managing == STATUS.LIQUIDITYTOKEN) {
        bondCalculator[info.toPermit] = info.calculator;
      }
      (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
      if (!registered) {
        registry[info.managing].push(info.toPermit);

        if (info.managing == STATUS.LIQUIDITYTOKEN) {
          (bool reg, uint256 index) = indexInRegistry(
            info.toPermit,
            STATUS.RESERVETOKEN
          );
          if (reg) {
            delete registry[STATUS.RESERVETOKEN][index];
          }
        } else if (info.managing == STATUS.RESERVETOKEN) {
          (bool reg, uint256 index) = indexInRegistry(
            info.toPermit,
            STATUS.LIQUIDITYTOKEN
          );
          if (reg) {
            delete registry[STATUS.LIQUIDITYTOKEN][index];
          }
        }
      }
    }
    permissionQueue[_index].executed = true;
    emit Permissioned(info.toPermit, info.managing, true);
  }

  /**
   * @notice cancel timelocked action
   * @param _index uint256
   */
  function nullify(uint256 _index) external onlyGovernor {
    permissionQueue[_index].nullify = true;
  }

  /**
   * @notice disables timelocked functions
   */
  function disableTimelock() external onlyGovernor {
    require(timelockEnabled == true, "timelock already disabled");
    if (
      onChainGovernanceTimelock != 0 &&
      onChainGovernanceTimelock <= block.number
    ) {
      timelockEnabled = false;
    } else {
      onChainGovernanceTimelock = block.number + blocksNeededForQueue * 7; // 7-day timelock
    }
  }

  /**
   * @notice enables timelocks after initilization
   */
  function initialize() external onlyGovernor {
    require(initialized == false, "Already initialized");
    timelockEnabled = true;
    initialized = true;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
   * @notice returns excess reserves not backing tokens
   * @return uint
   */
  function excessReserves() public view override returns (uint256) {
    return totalReserves - (REQ.totalSupply() - totalDebt);
  }

  /**
   * @notice returns REQ valuation of asset
   * @param _token address
   * @param _amount uint256
   * @return value_ uint256
   */
  function tokenValue(address _token, uint256 _amount)
    public
    view
    override
    returns (uint256 value_)
  {
    value_ =
      (_amount * (10**IERC20Metadata(address(REQ)).decimals())) /
      (10**IERC20Metadata(_token).decimals());

    if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
      value_ = IBondingCalculator(bondCalculator[_token]).valuation(
        _token,
        _amount
      );
    }
  }

  /**
   * @notice returns supply metric that cannot be manipulated by debt
   * @dev use this any time you need to query supply
   * @return uint256
   */
  function baseSupply() external view override returns (uint256) {
    return REQ.totalSupply() - reqDebt;
  }
}