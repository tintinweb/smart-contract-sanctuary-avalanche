/**
 *Submitted for verification at snowtrace.io on 2022-04-04
*/

// File: bava/IDMMRouter.sol



pragma solidity ^0.8.0;

interface IDMMRouter {
    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param amountADesired the amount of tokenA users want to add to the pool
     * @param amountBDesired the amount of tokenB users want to add to the pool
     * @param amountAMin bounds to the extents to which amountB/amountA can go up
     * @param amountBMin bounds to the extents to which amountB/amountA can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        address pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPool(
        address tokenA,
        address tokenB,
        uint32 ampBps,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityNewPoolETH(
        address token,
        uint32 ampBps,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param amountTokenDesired the amount of token users want to add to the pool
     * @dev   msg.value equals to amountEthDesired
     * @param amountTokenMin bounds to the extents to which WETH/token can go up
     * @param amountETHMin bounds to the extents to which WETH/token can go down
     * @param vReserveRatioBounds bounds to the extents to which vReserveB/vReserveA can go (precision: 2 ** 112)
     * @param to Recipient of the liquidity tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function addLiquidityETH(
        address token,
        address pool,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256[2] calldata vReserveRatioBounds,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param tokenA address of token in the pool
     * @param tokenB address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountAMin the minimum token retuned after burning
     * @param amountBMin the minimum token retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param approveMax whether users permit the router spending max lp token or not.
     * @param r s v Signature of user to permit the router spending lp token
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        address pool,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum eth in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     */
    function removeLiquidityETH(
        address token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param token address of token in the pool
     * @param pool the address of the pool
     * @param liquidity the amount of lp token users want to burn
     * @param amountTokenMin the minimum token retuned after burning
     * @param amountETHMin the minimum eth in wei retuned after burning
     * @param to Recipient of the returned tokens.
     * @param deadline Unix timestamp after which the transaction will revert
     * @param approveMax whether users permit the router spending max lp token
     * @param r s v signatures of user to permit the router spending lp token.
     */
    function removeLiquidityETHWithPermit(
        address token,
        address pool,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @param amountA amount of 1 side token added to the pool
     * @param reserveA current reserve of the pool
     * @param reserveB current reserve of the pool
     * @return amountB amount of the other token added to the pool
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata poolsPath,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata poolsPath,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata poolsPath,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}
// File: bava/IRouter.sol



pragma solidity ^0.8.0;

interface IRouter {
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(address token, uint amountTokenDesired, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountAVAX);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}
// File: bava/IKyberRewardLockerV2.sol


pragma solidity ^0.8.0;

interface IKyberRewardLockerV2 {

  struct VestingSchedule {
    uint64 startTime;
    uint64 endTime;
    uint128 quantity;
    uint128 vestedQuantity;
  }

  /**
   * @dev queue a vesting schedule starting from now
   */
  function lock(
    address token,
    address account,
    uint256 amount,
    uint32 vestingDuration
  ) external payable;

  /**
   * @dev queue a vesting schedule
   */
  function lockWithStartTime(
    address token,
    address account,
    uint256 quantity,
    uint256 startTime,
    uint32 vestingDuration
  ) external payable;

  /**
   * @dev vest all completed schedules for multiple tokens
   */
  function vestCompletedSchedulesForMultipleTokens(address[] calldata tokens)
    external
    returns (uint256[] memory vestedAmounts);

  /**
   * @dev claim multiple tokens for specific vesting schedule,
   *      if schedule has not ended yet, claiming amounts are linear with vesting times
   */
  function vestScheduleForMultipleTokensAtIndices(
    address[] calldata tokens,
    uint256[][] calldata indices
  ) external returns (uint256[] memory vestedAmounts);

  /**
   * @dev for all completed schedule, claim token
   */
  function vestCompletedSchedules(address token) external returns (uint256);

  /**
   * @dev claim token for specific vesting schedule,
   * @dev if schedule has not ended yet, claiming amount is linear with vesting times
   */
  function vestScheduleAtIndices(address token, uint256[] calldata indexes)
    external
    returns (uint256);

  /**
   * @dev claim token for specific vesting schedule from startIndex to endIndex
   */
  function vestSchedulesInRange(
    address token,
    uint256 startIndex,
    uint256 endIndex
  ) external returns (uint256);

  function accountEscrowedBalance(address account, address token) external view returns (
      uint256 totalEscrowedBalance
  );

  /**
   * @dev length of vesting schedules array
   */
  function numVestingSchedules(address account, address token) external view returns (uint256);

  /**
   * @dev get detailed of each vesting schedule
   */
  function getVestingScheduleAtIndex(
    address account,
    address token,
    uint256 index
  ) external view returns (VestingSchedule memory);

  /**
   * @dev get vesting shedules array
   */
  function getVestingSchedules(address account, address token)
    external
    view
    returns (VestingSchedule[] memory schedules);
}
// File: bava/IKyberFairLaunchV2.sol


pragma solidity ^0.8.0;


interface IKyberFairLaunchV2 {

  /**
   * @dev deposit to tokens to accumulate rewards
   * @param _pid: id of the pool
   * @param _amount: amount of stakeToken to be deposited
   * @param _shouldHarvest: whether to harvest the reward or not
   */
  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _shouldHarvest
  ) external;

  /**
   * @dev withdraw token (of the sender) from pool, also harvest reward
   * @param _pid: id of the pool
   * @param _amount: amount of stakeToken to withdraw
   */
  function withdraw(uint256 _pid, uint256 _amount) external;

  /**
   * @dev withdraw all tokens (of the sender) from pool, also harvest reward
   * @param _pid: id of the pool
   */
  function withdrawAll(uint256 _pid) external;

  /**
   * @dev emergency withdrawal function to allow withdraw all deposited token (of the sender)
   *   without harvesting the reward
   * @param _pid: id of the pool
   */
  function emergencyWithdraw(uint256 _pid) external;

  /**
   * @dev harvest reward from pool for the sender
   * @param _pid: id of the pool
   */
  function harvest(uint256 _pid) external;

  /**
   * @dev harvest rewards from multiple pools for the sender
   */
  function harvestMultiplePools(uint256[] calldata _pids) external;

  /**
   * @dev update reward for one pool
   */
  function updatePoolRewards(uint256 _pid) external;

  /**
   * @dev return full details of a pool
   */
  function getPoolInfo(uint256 _pid)
    external
    view
    returns (
      uint256 totalStake,
      address stakeToken,
      address generatedToken,
      uint32 startTime,
      uint32 endTime,
      uint32 lastRewardSecond,
      uint32 vestingDuration,
      uint256[] memory rewardPerSeconds,
      uint256[] memory rewardMultipliers,
      uint256[] memory accRewardPerShares
    );

  /**
   * @dev get user's info
   */
  function getUserInfo(uint256 _pid, address _account)
    external
    view
    returns (
      uint256 amount,
      uint256[] memory unclaimedRewards,
      uint256[] memory lastRewardPerShares
    );

  /**
   * @dev return list reward tokens
   */
  function getRewardTokens() external view returns (address[] memory);

  /**
   * @dev get pending reward of a user from a pool, mostly for front-end
   * @param _pid: id of the pool
   * @param _user: user to check for pending rewards
   */
  function pendingRewards(uint256 _pid, address _user)
    external
    view
    returns (uint256[] memory rewards);
}
// File: bava/IBavaToken.sol



pragma solidity ^0.8.0;

interface IBavaToken {
    function transfer(address to, uint tokens) external returns (bool success);

    function mint(address to, uint tokens) external;

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function cap() external view returns (uint capSuppply);

    function totalSupply() external view returns (uint _totalSupply);

    function lock(address _holder, uint256 _amount) external;
}
// File: bava/IBavaMasterFarm.sol



pragma solidity ^0.8.0;

interface IBAVAMasterFarm {
    function updatePool(uint256 _pid) external;

    function poolInfo(uint256 _pid) external view returns (
        address lpToken,
        address poolContract,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accBavaPerShare
    );

    function getPoolReward(uint256 _from, uint256 _to, uint256 _allocPoint) external view returns (
        uint256 forDev, 
        uint256 forFarmer, 
        uint256 forFT, 
        uint256 forAdr, 
        uint256 forFounders
    );
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: bava/IWAVAX.sol


pragma solidity ^0.8.0;

interface IWAVAX is IERC20{
    function deposit() external payable;

    function withdraw(uint256) external;
}
// File: bava/IPair.sol



pragma solidity ^0.8.0;


interface IPair is IERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
}
// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
}

// File: bava/BRTERC20.sol


pragma solidity ^0.8.4;





abstract contract BRTERC20 is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Baklava: DMM LP USDC-USDC.e", "BRT") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// File: bava/BavaCompoundPool_KyberFairV2.sol



pragma solidity ^0.8.0;












// BavaCompoundPool is the compoundPool of BavaMasterFarmer. It will autocompound user LP.
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Bava is sufficiently
// distributed and the community can show to govern itself.

contract BavaCompoundPool_KyberFairV2 is BRTERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPair;
    using SafeERC20 for IWAVAX;

    // Info of each user.
    struct UserInfo {
        uint256 receiptAmount;      // user receipt tokens.
        uint256 rewardDebt;         // Reward debt. See explanation below.
        uint256 rewardDebtAtBlock;  // the last block user stake
		uint256 lastWithdrawBlock;  // the last block a user withdrew at.
		uint256 firstDepositBlock;  // the first block a user deposited at.
		uint256 blockdelta;         // time passed since withdrawals
		uint256 lastDepositBlock;   // the last block a user deposited at.
    }

    // Info of pool.
    struct PoolInfo {
        IPair lpToken;             // Address of LP token contract.
        uint256 depositAmount;      // Total deposit amount
        bool deposits_enabled;
    }
    
    // Info of 3rd party restaking farm 
    struct PoolRestakingInfo {
        IKyberFairLaunchV2 stakingContract; // Kyber LP Staking contract
        IKyberRewardLockerV2 rewardLocker;  // Kyber reward locker
        uint256 restakingFarmID;            // RestakingFarm ID
    }

    IWAVAX private constant WAVAX = IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);     // 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
    IERC20 private constant USDCE = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);     // 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664
    IPair private constant KNC_WAVAX = IPair(0x4797D61A80FBb90Aa060c6d8Fe9991c41C4868BF);     // 0x4797D61A80FBb90Aa060c6d8Fe9991c41C4868BF

    uint256 public MIN_TOKENS_TO_REINVEST;
    uint256 public DEV_FEE_BIPS;
    uint256 public REINVEST_REWARD_BIPS;
    uint256 constant internal BIPS_DIVISOR = 10000;

    IRouter public router;                  // Router1 for swap token
    IDMMRouter public router2;              // Router2 for add and remove liquidity
    IBAVAMasterFarm public BavaMasterFarm;  // MasterFarm to mint BAVA token.
    IBavaToken public Bava;                 // The Bava TOKEN!
    uint256 public bavaPid;                 // BAVA Master Farm Pool Id
    address public devaddr;                 // Developer/Employee address.
    address public liqaddr;                 // Liquidate address

    IERC20 public rewardToken;
    IERC20[] public bonusRewardTokens;
    uint256[] public blockDeltaStartStage;
    uint256[] public blockDeltaEndStage;
    uint256[] public userFeeStage;
    uint256 public userDepFee;
    uint256 public PERCENT_LOCK_BONUS_REWARD;           // lock xx% of bounus reward in 3 year

    PoolInfo public poolInfo;                           // Info of each pool.
    PoolRestakingInfo public poolRestakingInfo;         // Info of each pool restaking farm.
    mapping (address => UserInfo) public userInfo;      // Info of each user that stakes LP tokens. pid => user address => info

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 devAmount);
    event SendBavaReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);
    event DepositsEnabled(bool newValue);
    event Liquidate(address indexed userAccount, uint256 amount);

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender);
        _;
    }

    constructor(
        IBavaToken _IBava,
        IBAVAMasterFarm _BavaMasterFarm,
        address _devaddr,
        address _liqaddr,
        uint256 _userDepFee,
        uint256 _newlock,
        uint256 _bavaPid,
        uint256[] memory _blockDeltaStartStage,
        uint256[] memory _blockDeltaEndStage,
        uint256[] memory _userFeeStage
    ) {
        Bava = _IBava;
        BavaMasterFarm = _BavaMasterFarm;
        devaddr = _devaddr;
        liqaddr = _liqaddr;
	    userDepFee = _userDepFee;
        PERCENT_LOCK_BONUS_REWARD = _newlock; 
        bavaPid = _bavaPid;
	    blockDeltaStartStage = _blockDeltaStartStage;
	    blockDeltaEndStage = _blockDeltaEndStage;
	    userFeeStage = _userFeeStage;
    }

    receive() external payable {}

    /******************************************* INITIAL SETUP START ******************************************/
    // Init the pool. Can only be called by the owner. Support LP from kyber fair launch.
    function initPool(
        IPair _lpToken,
        IKyberFairLaunchV2 _stakingContract,
        IKyberRewardLockerV2 _rewardLocker,
        uint256 _restakingFarmID,
        IERC20 _rewardToken,
        IERC20[] memory _bonusRewardTokens,
        IRouter _router,
        IDMMRouter _router2,
        uint256 _MIN_TOKENS_TO_REINVEST,
        uint256 _DEV_FEE_BIPS,
        uint256 _REINVEST_REWARD_BIPS
    ) external onlyOwner {
        // require(address(_lpToken) != address(0));
        // require(address(_stakingContract) != address(0));
        poolInfo = PoolInfo({
            lpToken : _lpToken,
            depositAmount : 0,
            deposits_enabled : true
        });
        poolRestakingInfo = PoolRestakingInfo({
            stakingContract : _stakingContract,
            rewardLocker : _rewardLocker,
            restakingFarmID : _restakingFarmID
        });
        rewardToken = _rewardToken;
        bonusRewardTokens = _bonusRewardTokens;
        router = _router;
        router2 = _router2;
        MIN_TOKENS_TO_REINVEST = _MIN_TOKENS_TO_REINVEST;
        DEV_FEE_BIPS = _DEV_FEE_BIPS;
        REINVEST_REWARD_BIPS = _REINVEST_REWARD_BIPS;
    }

    /**
     * @notice Approve tokens for use in Strategy, Restricted to avoid griefing attacks
     */

    function setAllowances(uint256 _amount) external onlyOwner {  
        poolInfo.lpToken.approve(address(poolRestakingInfo.stakingContract), _amount);

        if (address(router) != address(0)) {
            WAVAX.approve(address(router), _amount);
            IERC20(poolInfo.lpToken.token0()).approve(address(router), _amount);
            IERC20(poolInfo.lpToken.token1()).approve(address(router), _amount);
        }
        if (address(router2) != address(0)) {
            WAVAX.approve(address(router2), _amount);
            IERC20(poolInfo.lpToken.token0()).approve(address(router2), _amount);
            IERC20(poolInfo.lpToken.token1()).approve(address(router2), _amount);
            (poolInfo.lpToken).approve(address(router2), _amount);
            rewardToken.approve(address(router2), _amount);
        }
    }
    /******************************************** INITIAL SETUP END ********************************************/

    /****************************************** FARMING CORE FUNCTION ******************************************/
    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        ( , , , uint256 lastRewardBlock, ) = BavaMasterFarm.poolInfo(bavaPid);
        if (block.number <= lastRewardBlock) {
            return;
        }
        BavaMasterFarm.updatePool(bavaPid);
    }

    function claimReward() external nonReentrant {
        updatePool();
        _harvest(msg.sender);
    }

    // lock 95% of reward
    function _harvest(address account) private {
        UserInfo storage user = userInfo[account];
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);
        if (user.receiptAmount > 0) {
            uint256 pending = user.receiptAmount*(accBavaPerShare)/(1e12)-(user.rewardDebt);
            uint256 masterBal = Bava.balanceOf(address(this));

            if (pending > masterBal) {
                pending = masterBal;
            }
            
            if(pending > 0) {
                Bava.transfer(account, pending);
                uint256 lockAmount = 0;
                lockAmount = pending*(PERCENT_LOCK_BONUS_REWARD)/(100);
                Bava.lock(account, lockAmount);

                user.rewardDebtAtBlock = block.number;

                emit SendBavaReward(account, bavaPid, pending, lockAmount);
            }
            user.rewardDebt = user.receiptAmount*(accBavaPerShare)/(1e12);
        }
    }
    
    // Deposit LP tokens to BavaMasterFarmer for $Bava allocation.
    function deposit(uint256 _amount) external nonReentrant {
        // require(_amount > 0, "#<0");
        require(poolInfo.deposits_enabled == true, "Fal");

        UserInfo storage user = userInfo[msg.sender];
        UserInfo storage devr = userInfo[devaddr];
        
        (uint256 estimatedTotalReward, uint256 estimatedAVAXReward, uint256 rewardBalance, uint256 avaxBalance) = checkLockerReward();
        if (estimatedTotalReward + estimatedAVAXReward + rewardBalance + avaxBalance > MIN_TOKENS_TO_REINVEST) {
            _reinvest(estimatedTotalReward, estimatedAVAXReward);
        }

        updatePool();
        _harvest(msg.sender);
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);
        
        poolInfo.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint poolReceiptAmount = getSharesForDepositTokens(_amount);
        poolInfo.depositAmount += _amount;

        if (user.receiptAmount == 0) {
            user.rewardDebtAtBlock = block.number;
        }
        uint userReceiptAmount = poolReceiptAmount - (poolReceiptAmount * userDepFee / BIPS_DIVISOR);  
        uint devrReceiptAmount = poolReceiptAmount - userReceiptAmount;

        user.receiptAmount += userReceiptAmount;
        user.rewardDebt = user.receiptAmount * (accBavaPerShare) / (1e12);
        devr.receiptAmount += devrReceiptAmount;
        devr.rewardDebt = devr.receiptAmount * (accBavaPerShare) / (1e12);
        _mint(msg.sender, userReceiptAmount);
        _mint(devaddr, devrReceiptAmount);

        // _stakeDepositTokens(_amount);
        poolRestakingInfo.stakingContract.deposit(poolRestakingInfo.restakingFarmID, _amount, true);
        
        emit Deposit(msg.sender, bavaPid, _amount);
		if(user.firstDepositBlock > 0){
		} else {
			user.firstDepositBlock = block.number;
		}
		user.lastDepositBlock = block.number;
    }
    
  // Withdraw LP tokens from BavaMasterFarmer. argument "_amount" is receipt amount.
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint depositTokenAmount = getDepositTokensForShares(_amount);
        require(poolInfo.depositAmount >= depositTokenAmount, "#>B");
        require(user.receiptAmount >= _amount, "#>N");
        updatePool();
        _harvest(msg.sender);
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);

        if(depositTokenAmount > 0) {
            _withdrawDepositTokens(depositTokenAmount);
            user.receiptAmount = user.receiptAmount-(_amount);
            _burn(msg.sender, _amount);
			if(user.lastWithdrawBlock > 0){
				user.blockdelta = block.number - user.lastWithdrawBlock; 
            } else {
                user.blockdelta = block.number - user.firstDepositBlock;
			}
            poolInfo.depositAmount -= depositTokenAmount;
            user.rewardDebt = user.receiptAmount*(accBavaPerShare)/(1e12);
            user.lastWithdrawBlock = block.number;
			if(user.blockdelta == blockDeltaStartStage[0] || block.number == user.lastDepositBlock){
				//25% fee for withdrawals of LP tokens in the same block this is to prevent abuse from flashloans
                _withdrawLPTokens(depositTokenAmount, userFeeStage[0]);
			} else if (user.blockdelta >= blockDeltaStartStage[1] && user.blockdelta <= blockDeltaEndStage[0]){
				//8% fee if a user deposits and withdraws in under between same block and 59 minutes.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[1]);
			} else if (user.blockdelta >= blockDeltaStartStage[2] && user.blockdelta <= blockDeltaEndStage[1]){
				//4% fee if a user deposits and withdraws after 1 hour but before 1 day.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[2]);
			} else if (user.blockdelta >= blockDeltaStartStage[3] && user.blockdelta <= blockDeltaEndStage[2]){
				//2% fee if a user deposits and withdraws between after 1 day but before 3 days.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[3]);
			} else if (user.blockdelta >= blockDeltaStartStage[4] && user.blockdelta <= blockDeltaEndStage[3]){
				//1% fee if a user deposits and withdraws after 3 days but before 5 days.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[4]);
			}  else if (user.blockdelta >= blockDeltaStartStage[5] && user.blockdelta <= blockDeltaEndStage[4]){
				//0.5% fee if a user deposits and withdraws if the user withdraws after 5 days but before 2 weeks.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[5]);
			} else if (user.blockdelta >= blockDeltaStartStage[6] && user.blockdelta <= blockDeltaEndStage[5]){
				//0.25% fee if a user deposits and withdraws after 2 weeks.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[6]);
			} else if (user.blockdelta > blockDeltaStartStage[7]) {
				//0.1% fee if a user deposits and withdraws after 4 weeks.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[7]);
			}
            emit Withdraw(msg.sender, bavaPid, depositTokenAmount);
		}
    }

    // EMERGENCY ONLY. Withdraw without caring about rewards.  
    // This has the same 25% fee as same block withdrawals and ucer receipt record set to 0 to prevent abuse of thisfunction.
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 userBRTAmount = balanceOf(msg.sender);
        uint depositTokenAmount = getDepositTokensForShares(userBRTAmount);

        require(poolInfo.depositAmount >= depositTokenAmount, "#>B");      //  pool.lpToken.balanceOf(address(this))
        _withdrawDepositTokens(depositTokenAmount);
        _burn(msg.sender, userBRTAmount);
        // Reordered from Sushi function to prevent risk of reentrancy
        uint256 amountToSend = depositTokenAmount*(75)/(100);
        uint256 devToSend = depositTokenAmount - amountToSend;  //25% penalty
        user.receiptAmount = 0;
        user.rewardDebt = 0;
        poolInfo.depositAmount -= depositTokenAmount;
        poolInfo.lpToken.safeTransfer(address(msg.sender), amountToSend);
        poolInfo.lpToken.safeTransfer(address(devaddr), devToSend);

        emit EmergencyWithdraw(msg.sender, bavaPid, amountToSend, devToSend);
    }

    // Withdraw LP token from this farm
    function _withdrawLPTokens(uint _depositTokenAmount, uint _userFeeStage) private {
        uint256 userWithdrawFee = _depositTokenAmount * _userFeeStage / BIPS_DIVISOR;
        poolInfo.lpToken.safeTransfer(address(msg.sender), userWithdrawFee);
        poolInfo.lpToken.safeTransfer(address(devaddr), _depositTokenAmount - userWithdrawFee);
    }

    // Withdraw LP token from 3rd party restaking farm
    function _withdrawDepositTokens(uint amount) private {
        (uint256 depositAmount,,) = poolRestakingInfo.stakingContract.getUserInfo(poolRestakingInfo.restakingFarmID, address(this));
        if(depositAmount >= amount) {
            poolRestakingInfo.stakingContract.withdraw(poolRestakingInfo.restakingFarmID, amount);
        } else {
            poolRestakingInfo.stakingContract.withdraw(poolRestakingInfo.restakingFarmID, depositAmount);
        }
    }

    // Claim LP restaking reward from 3rd party restaking contract
    function _getReinvestReward(uint256 estimatedTotalReward, uint256 estimatedAVAXReward) private {
        if (estimatedTotalReward > 0) {
            poolRestakingInfo.rewardLocker.vestCompletedSchedules(address(rewardToken));
        }
        if (estimatedAVAXReward > 0) {
            poolRestakingInfo.rewardLocker.vestCompletedSchedules(address(0));
        }
    }

    function harvestKyberReward() external {
        poolRestakingInfo.stakingContract.harvest(poolRestakingInfo.restakingFarmID);
        (uint256 estimatedTotalReward, uint256 estimatedAVAXReward, , ) = checkLockerReward();
        _getReinvestReward(estimatedTotalReward, estimatedAVAXReward);        
    }

    function reinvest() external nonReentrant {
        (uint256 estimatedTotalReward, uint256 estimatedAVAXReward, uint256 rewardBalance, uint256 avaxBalance) = checkLockerReward();
        require((estimatedTotalReward + estimatedAVAXReward + rewardBalance + avaxBalance) >= MIN_TOKENS_TO_REINVEST, "#<M");
        _reinvest(estimatedTotalReward, estimatedAVAXReward);
    }

    // Emergency withdraw LP token from 3rd party restaking contract
    function emergencyWithdrawDepositTokens(bool disableDeposits) external onlyOwner {
        poolRestakingInfo.stakingContract.emergencyWithdraw(poolRestakingInfo.restakingFarmID);
        if (poolInfo.deposits_enabled == true && disableDeposits == true) {
            updateDepositsEnabled(false);
        }
    }
    
    function liquidateCollateral(address userAccount, uint256 amount) external onlyAuthorized {
        _liquidateCollateral(userAccount, amount);
    }


    /**************************************** VIEW FUNCTIONS ****************************************/
    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint amount) public view returns (uint) {
        if (totalSupply() * poolInfo.depositAmount == 0) {
            return amount;
        }
        return (amount*totalSupply() / poolInfo.depositAmount);
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint amount) public view returns (uint) {
        if (totalSupply() * poolInfo.depositAmount == 0) {
            return 0;
        }
        return (amount * poolInfo.depositAmount / totalSupply());
    }

    // View function to see pending Bavas on frontend.
    function pendingReward(address _user) external view returns (uint) {
        UserInfo storage user = userInfo[_user];
        (, , uint256 allocPoint, uint256 lastRewardBlock, uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);

        if (block.number > lastRewardBlock && totalSupply() > 0) {
            (, uint256 BavaForFarmer, , ,) = BavaMasterFarm.getPoolReward(lastRewardBlock, block.number, allocPoint);
            accBavaPerShare = accBavaPerShare+(BavaForFarmer*(1e12)/(totalSupply()));
        }
        return user.receiptAmount*(accBavaPerShare)/(1e12)-(user.rewardDebt);
    }

    // View function to see pending 3rd party reward
    function checkReward() public view returns (uint, uint[] memory) {
        uint256[] memory pending = poolRestakingInfo.stakingContract.pendingRewards(poolRestakingInfo.restakingFarmID, address(this));

        return (pending[1], pending);
    }

    function checkLockerReward() public view returns (uint, uint, uint, uint) {
        return (
            _checkLockerReward(address(rewardToken)),
            _checkLockerReward(address(0)),
            rewardToken.balanceOf(address(this)),
            address(this).balance
            );
    }

    function _checkLockerReward(address token) internal view returns (uint) {
        IKyberRewardLockerV2.VestingSchedule[] memory schedules = poolRestakingInfo.rewardLocker.getVestingSchedules(address(this), token);
        uint256 schedulesLength = schedules.length;
        uint256 totalVesting;

        for (uint256 i = 0; i < schedulesLength; i++) {
            IKyberRewardLockerV2.VestingSchedule memory schedule = schedules[i];
            if (block.timestamp < schedule.endTime) {
                continue;
            }
            uint256 vestQuantity = uint256(schedule.quantity) - (schedule.vestedQuantity);
            if (vestQuantity == 0) {
                continue;
            }
            schedules[i].vestedQuantity = schedule.quantity;
            totalVesting = totalVesting + vestQuantity;
        }
        return (totalVesting);
    }

    /**************************************** ONLY OWNER FUNCTIONS ****************************************/
    // Rescue any token function, just in case if any user not able to withdraw token from the smart contract.
    function rescueDeployedFunds(address token, uint256 amount, address _to) external onlyOwner {
        require(_to != address(0), "0A");
        IERC20(token).safeTransfer(_to, amount);
    }

    // Update the given pool's Bava restaking contract. Can only be called by the owner.
    function setPoolRestakingInfo(IKyberFairLaunchV2 _stakingContract, IKyberRewardLockerV2 _rewardLocker, uint256 _restakingFarmID, IERC20 _rewardToken, IERC20[] memory _bonusRewardTokens, IRouter _router, IDMMRouter _router2, bool _withUpdate) external onlyOwner {      
        if (_withUpdate) {
            updatePool();
        }
        poolRestakingInfo = PoolRestakingInfo({
            stakingContract : _stakingContract,
            rewardLocker : _rewardLocker,
            restakingFarmID : _restakingFarmID
        });
        rewardToken = _rewardToken;
        bonusRewardTokens = _bonusRewardTokens;
        router = _router;
        router2 = _router2;
    }

    function setBavaMasterFarm(IBAVAMasterFarm _BavaMasterFarm, uint256 _bavaPid) external onlyOwner {
        BavaMasterFarm = _BavaMasterFarm;
        bavaPid = _bavaPid;
    }

    function devAddrUpdate(address _devaddr, address _liqaddr) public onlyOwner {
        devaddr = _devaddr;
        liqaddr = _liqaddr;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(poolInfo.deposits_enabled != newValue);
        poolInfo.deposits_enabled = newValue;
        emit DepositsEnabled(newValue);
    }

    /**************************************** ONLY AUTHORIZED FUNCTIONS ****************************************/
    // Update % lock for general users & percent for other roles
    function percentUpdate(uint _newlock) public onlyAuthorized {
       PERCENT_LOCK_BONUS_REWARD = _newlock;
    }

	function setStageStarts(uint[] memory _blockStarts, uint[] memory _blockEnds) public onlyAuthorized {
        blockDeltaStartStage = _blockStarts;
        blockDeltaEndStage = _blockEnds;
    }
    
    function setUserFeeStage(uint _usrDepFees, uint[] memory _userFees) public onlyAuthorized {
        userDepFee = _usrDepFees;
        userFeeStage = _userFees;
    }

    function setMinReinvestToken(uint _MIN_TOKENS_TO_REINVEST) public onlyAuthorized {
        MIN_TOKENS_TO_REINVEST = _MIN_TOKENS_TO_REINVEST;
    }

    function setDevFeeBips(uint _DEV_FEE_BIPS, uint _REINVEST_REWARD_BIPS) public onlyAuthorized {
        DEV_FEE_BIPS = _DEV_FEE_BIPS;
        REINVEST_REWARD_BIPS = _REINVEST_REWARD_BIPS;
    }

    /*********************** Autocompound Strategy ******************
    * Swap all reward tokens to WAVAX and swap half/half WAVAX token to both LP  token0 & token1, Add liquidity to LP token
    ****************************************/
    function _reinvest(uint256 estimatedTotalReward, uint256 estimatedAVAXReward) private {
        _getReinvestReward(estimatedTotalReward, estimatedAVAXReward);
        uint wavaxAmount = _convertRewardIntoWAVAX();
        uint liquidity = _convertWAVAXTokenToDepositToken(wavaxAmount);

        poolRestakingInfo.stakingContract.deposit(poolRestakingInfo.restakingFarmID, liquidity, true);
        poolInfo.depositAmount += liquidity;
    }

    function _convertRewardIntoWAVAX() private returns (uint) {
        uint pathLength = 2;
        address[] memory path = new address[](pathLength);
        uint256 avaxAmount;

        path[0] = address(rewardToken);
        path[1] = address(WAVAX);
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (rewardBal > 0) {
            _convertExactTokentoToken(path, rewardBal, 1);
        }

        uint256 avaxBal =  address(this).balance;
        if (avaxBal > 0) {
            WAVAX.deposit{value: avaxBal}();
        }

        avaxAmount = WAVAX.balanceOf(address(this));
        uint256 devFee = avaxAmount*(DEV_FEE_BIPS)/(BIPS_DIVISOR);
        uint256 reinvestFee = avaxAmount*(REINVEST_REWARD_BIPS)/(BIPS_DIVISOR);
        if (devFee > 0) {
            WAVAX.safeTransfer(devaddr, devFee);
            WAVAX.safeTransfer(msg.sender, reinvestFee);
        }

        return (avaxAmount-reinvestFee-devFee);
    }

    function _convertWAVAXTokenToDepositToken(uint256 amount) private returns (uint) {
        require(amount > 0, "#<0");
        uint amountIn = amount / 2;

        (address[] memory path0, uint amountOutToken0) = _convertWAVAXtoLpOriginalToken(amountIn, poolInfo.lpToken.token0());
        (address[] memory path1, uint amountOutToken1) = _convertWAVAXtoLpOriginalToken(amountIn, poolInfo.lpToken.token1());

        // swap to deposit(LP) Token
        (,,uint liquidity) = router2.addLiquidity(
            path0[path0.length - 1], path1[path1.length - 1], address(poolInfo.lpToken),
            amountOutToken0, amountOutToken1,
            0, 0, [1,115792089237316195423570985008687907853269984665640564039457584007913129639935],
            address(this),
            block.timestamp+1200
        );
        return liquidity;
    }

    // Liquidate user collateral when user LP token value lower than user borrowed fund.
    function _liquidateCollateral(address userAccount, uint256 amount) private onlyAuthorized {
        UserInfo storage user = userInfo[userAccount];
        uint depositTokenAmount = getDepositTokensForShares(amount);
        updatePool();
        _harvest(userAccount);
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);
       
        require(poolInfo.depositAmount >= depositTokenAmount, "#>B");
        _burn(msg.sender, amount);
        _withdrawDepositTokens(depositTokenAmount);
        // Reordered from Sushi function to prevent risk of reentrancy
        user.receiptAmount -= amount;
        user.rewardDebt = user.receiptAmount * (accBavaPerShare) / (1e12);
        poolInfo.depositAmount -= depositTokenAmount;

        (uint balance0, uint balance1) = poolInfo.lpToken.getReserves();
        uint _totalSupply = poolInfo.lpToken.totalSupply();                     // gas savings, must be defined here since totalSupply can update in _mintFee
        uint amount0 = depositTokenAmount * (balance0) / _totalSupply * 8/10;   // using balances ensures pro-rata distribution
        uint amount1 = depositTokenAmount * (balance1) / _totalSupply * 8/10;   // using balances ensures pro-rata distribution
        // swap to original Tokens
        (uint amountA, uint amountB) = router2.removeLiquidity(poolInfo.lpToken.token0(), poolInfo.lpToken.token1(), address(poolInfo.lpToken), depositTokenAmount, amount0, amount1, address(this), block.timestamp+1200);

        uint liquidateAmountA = _convertTokentoUSDCE(amountA, 0);
        uint liquidateAmountB = _convertTokentoUSDCE(amountB, 1);

        USDCE.safeTransfer(address(liqaddr), (liquidateAmountA + liquidateAmountB));
        emit Liquidate(userAccount, amount);
    }

    function _convertWAVAXtoLpOriginalToken(uint amountIn, address token) private returns (address[] memory, uint) {
        uint pathLength = 2;
        address[] memory path = new address[](pathLength);
        path[0] = address(WAVAX);
        path[1] = token;

        uint amountOutToken = amountIn;
        // Check if path[1] equal to WAVAX 
        if (path[0] != path[pathLength - 1]) {
            amountOutToken = _convertExactTokentoToken(path, amountIn, 0);
        }

        return (path, amountOutToken);
    }

    function _convertTokentoUSDCE(uint amount, uint token) private returns (uint) {
        address oriToken;
        if (token == 0) {
            oriToken = poolInfo.lpToken.token0();
        } else if (token == 1) {
            oriToken = poolInfo.lpToken.token1();
        }
        // swap tokenA to USDC
        uint amountUSDCE;
        if (oriToken == address(USDCE)) {
            amountUSDCE = amount;
        } else {
            address[] memory path;
            uint pathLength = 2;
            path = new address[](pathLength);
            path[0] = oriToken;
            path[1] = address(USDCE);
            
            amountUSDCE = _convertExactTokentoToken(path, amount, 0);
        }
        return amountUSDCE;
    }

    // routerIndex 0 for pangolin/traderjoe router, 1 for kyber DMMrouter02
    function _convertExactTokentoToken(address[] memory path, uint amount, uint routerIndex) private returns (uint) {
        uint swapAmount;
        uint[] memory amountOut;

        if (routerIndex == 0) {
            uint[] memory amountsOutToken = router.getAmountsOut(amount, path);
            uint amountOutToken = amountsOutToken[amountsOutToken.length - 1];
            amountOut = router.swapExactTokensForTokens(amount, amountOutToken, path, address(this), block.timestamp+1200);
        } else if(routerIndex == 1) {
            address[] memory poolsPath = new address[](1);
            poolsPath[0] = address(KNC_WAVAX);

            uint[] memory amountsOutToken = router2.getAmountsOut(amount, poolsPath, path);
            uint amountOutToken = amountsOutToken[amountsOutToken.length - 1];
            amountOut = router2.swapExactTokensForTokens(amount, amountOutToken, poolsPath, path, address(this), block.timestamp+1200);
        }
        swapAmount = amountOut[amountOut.length - 1];
        return swapAmount;
    }
}