/**
 *Submitted for verification at snowtrace.io on 2022-09-13
*/

pragma experimental ABIEncoderV2;

// File: Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: IERC20.sol

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: IWavax.sol

interface IWavax {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address guy, uint256 wad) external returns (bool);
}

// File: Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: QIComptroller.sol

/// @notice Got the methods from https://github.com/Benqi-fi/BENQI-Smart-Contracts/blob/master/Comptroller.sol
interface QIComptroller {
    function claimReward(uint8 rewardType, address payable holder) external;

    function enterMarkets(address[] memory qiTokens)
        external
        returns (uint256[] memory);
}

// File: SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: comppriceoracle.sol

interface ICompPriceOracle {
    function isPriceOracle() external view returns (bool);

    /**
     * @notice Get the underlying price of a cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// File: comptroller.sol

interface IComptroller {
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function claimComp(address holder) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);
}

interface UnitrollerAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    // address external admin;
    function admin() external view returns (address);

    /**
     * @notice Pending administrator for this contract
     */
    // address external pendingAdmin;
    function pendingAdmin() external view returns (address);

    /**
     * @notice Active brains of Unitroller
     */
    // address external comptrollerImplementation;
    function comptrollerImplementation() external view returns (address);

    /**
     * @notice Pending brains of Unitroller
     */
    // address external pendingComptrollerImplementation;
    function pendingComptrollerImplementation() external view returns (address);
}

interface ComptrollerV1Storage is UnitrollerAdminStorage {
    /**
     * @notice Oracle which gives the price of any given asset
     */
    // PriceOracle external oracle;
    function oracle() external view returns (address);

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    // uint external closeFactorMantissa;
    function closeFactorMantissa() external view returns (uint256);

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    // uint external liquidationIncentiveMantissa;
    function liquidationIncentiveMantissa() external view returns (uint256);

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    // uint external maxAssets;
    function maxAssets() external view returns (uint256);

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    // mapping(address => CToken[]) external accountAssets;
    // function accountAssets(address) external view returns (CToken[]);
}

interface ComptrollerV2Storage is ComptrollerV1Storage {
    enum Version {VANILLA, COLLATERALCAP, WRAPPEDNATIVE}

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
        mapping(address => bool) accountMembership;
        bool isComped;
        Version version;
    }

    /**
     * @notice Official mapping of cTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    // mapping(address => Market) external markets;
    // function markets(address) external view returns (Market);

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    // address external pauseGuardian;
    // bool external _mintGuardianPaused;
    // bool external _borrowGuardianPaused;
    // bool external transferGuardianPaused;
    // bool external seizeGuardianPaused;
    // mapping(address => bool) external mintGuardianPaused;
    // mapping(address => bool) external borrowGuardianPaused;
}

interface ComptrollerV3Storage is ComptrollerV2Storage {
    // struct CompMarketState {
    //     /// @notice The market's last updated compBorrowIndex or compSupplyIndex
    //     uint224 index;
    //     /// @notice The block number the index was last updated at
    //     uint32 block;
    // }
    // /// @notice A list of all markets
    // CToken[] external allMarkets;
    // /// @notice The rate at which the flywheel distributes COMP, per block
    // uint external compRate;
    // /// @notice The portion of compRate that each market currently receives
    // mapping(address => uint) external compSpeeds;
    // /// @notice The COMP market supply state for each market
    // mapping(address => CompMarketState) external compSupplyState;
    // /// @notice The COMP market borrow state for each market
    // mapping(address => CompMarketState) external compBorrowState;
    // /// @notice The COMP borrow index for each market for each supplier as of the last time they accrued COMP
    // mapping(address => mapping(address => uint)) external compSupplierIndex;
    // /// @notice The COMP borrow index for each market for each borrower as of the last time they accrued COMP
    // mapping(address => mapping(address => uint)) external compBorrowerIndex;
    // /// @notice The COMP accrued but not yet transferred to each user
    // mapping(address => uint) external compAccrued;
}

interface ComptrollerV4Storage is ComptrollerV3Storage {
    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    // address external borrowCapGuardian;
    function borrowCapGuardian() external view returns (address);

    // @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
    // mapping(address => uint) external borrowCaps;
    function borrowCaps(address) external view returns (uint256);
}

interface ComptrollerV5Storage is ComptrollerV4Storage {
    // @notice The supplyCapGuardian can set supplyCaps to any number for any market. Lowering the supply cap could disable supplying to the given market.
    // address external supplyCapGuardian;
    function supplyCapGuardian() external view returns (address);

    // @notice Supply caps enforced by mintAllowed for each cToken address. Defaults to zero which corresponds to unlimited supplying.
    // mapping(address => uint) external supplyCaps;
    function supplyCaps(address) external view returns (uint256);

    function _setPriceOracle(address newOracle) external returns (uint);
    function getAllMarkets() external view returns (address[] calldata cTokens);
}

// File: farm.sol

struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt.
}

interface IFarmMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function harvestFromMasterChef() external;

    function userInfo(uint256 _pid, address user)
        external
        view
        returns (UserInfo calldata);
}

// File: ipriceoracle.sol

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

// File: uniswap.sol

// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    /// added in to support with JOE integrations
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
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

    function addLiquidityETH(
        address token,
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
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

    function removeLiquidityETHWithPermit(
        address token,
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: vector.sol

// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;

interface IVectorChef {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function balanceOf(address _address) external view returns (uint256);

    function getReward() external;
}

interface IBaseRewardPool {
    function earned(address _account, address _token)
        external
        view
        returns (uint256);
}

// File: SafeERC20.sol

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: ctoken.sol

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
    /**
     * @dev Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @dev Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amnount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

interface ICTokenStorage {
    /**
     * @dev Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }
}

interface ICToken is ICTokenStorage {
    /*** Market Events ***/

    /**
     * @dev Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );

    /**
     * @dev Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @dev Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @dev Event emitted when underlying is borrowed
     */
    event Borrow(
        address borrower,
        uint256 borrowAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @dev Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @dev Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @dev Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @dev Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @dev Event emitted when comptroller is changed
     */
    event NewComptroller(
        IComptroller oldComptroller,
        IComptroller newComptroller
    );

    /**
     * @dev Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(
        InterestRateModel oldInterestRateModel,
        InterestRateModel newInterestRateModel
    );

    /**
     * @dev Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(
        uint256 oldReserveFactorMantissa,
        uint256 newReserveFactorMantissa
    );

    /**
     * @dev Event emitted when the reserves are added
     */
    event ReservesAdded(
        address benefactor,
        uint256 addAmount,
        uint256 newTotalReserves
    );

    /**
     * @dev Event emitted when the reserves are reduced
     */
    event ReservesReduced(
        address admin,
        uint256 reduceAmount,
        uint256 newTotalReserves
    );

    /**
     * @dev EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev EIP20 Approval event
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @dev Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    /*** User Interface ***/
    function totalBorrows() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    /*** CCap Interface ***/

    function totalCollateralTokens() external view returns (uint256);

    function accountCollateralTokens(address account)
        external
        view
        returns (uint256);

    function isCollateralTokenInit(address account)
        external
        view
        returns (bool);

    function collateralCap() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin)
        external
        returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller)
        external
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(InterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICTokenErc20 is ICToken {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        ICToken cTokenCollateral
    ) external returns (uint256);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

interface ICCapableErc20 {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        ICToken cTokenCollateral
    ) external returns (uint256);

    function gulp() external;

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

interface CCollateralCapStorage {
    /**
     * @notice Total number of tokens used as collateral in circulation.
     */
    // uint256 public totalCollateralTokens;
    function totalCollateralTokens() external view returns (uint256);

    /**
     * @notice Record of token balances which could be treated as collateral for each account.
     *         If collateral cap is not set, the value should be equal to accountTokens.
     */
    // mapping(address => uint256) public accountCollateralTokens;
    function accountCollateralTokens(address account)
        external
        view
        returns (uint256);

    /**
     * @notice Check if accountCollateralTokens have been initialized.
     */
    // mapping(address => bool) public isCollateralTokenInit;
    function isCollateralTokenInit(address account)
        external
        view
        returns (bool);

    /**
     * @notice Collateral cap for this CToken, zero for no cap.
     */
    // uint256 public collateralCap;
    function collateralCap() external view returns (uint256);
}

interface ICAvax is ICToken {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower) external payable;
}

// File: screampriceoracle.sol

contract ScreamPriceOracle is IPriceOracle {
    using SafeMath for uint256;

    address cTokenQuote;
    address cTokenBase;
    ComptrollerV5Storage comptroller;

    constructor(
        address _comptroller,
        address _cTokenQuote,
        address _cTokenBase
    ) public {
        cTokenQuote = _cTokenQuote;
        cTokenBase = _cTokenBase;
        comptroller = ComptrollerV5Storage(_comptroller);
    }

    function getPrice() external view override returns (uint256) {
        ICompPriceOracle oracle = ICompPriceOracle(comptroller.oracle());

        // If price returns 0, the price is not available
        uint256 quotePrice = oracle.getUnderlyingPrice(cTokenQuote);
        require(quotePrice != 0);

        uint256 basePrice = oracle.getUnderlyingPrice(cTokenBase);
        require(basePrice != 0);

        return basePrice.mul(1e18).div(quotePrice);
    }
}

// File: BaseStrategyRedux.sol

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    function revokeStrategy() external;

    function governance() external view returns (address);

    function management() external view returns (address);

    function guardian() external view returns (address);
}

interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );
}

interface HealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
}

/**
 * @title BaseStrategyRedux
 * @author HeroBorg
 * @notice
 * This is an exact copy of BaseStrategy 0.4.3 from yearn, but i removed `ethToWant()` because we always override it and make it return 0
 * Also, I've removed some require error messages
 * This is a solution until we completely revamp the corestrat
 */

abstract contract BaseStrategyRedux {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public metadataURI;

    bool public doHealthCheck;
    address public healthCheck;

    function apiVersion() public pure returns (string memory) {
        return "0.4.3";
    }

    function name() external view virtual returns (string memory);

    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    event Harvested(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding
    );

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedProfitFactor(uint256 profitFactor);

    event UpdatedDebtThreshold(uint256 debtThreshold);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    uint256 public minReportDelay;

    uint256 public maxReportDelay;

    uint256 public profitFactor;

    uint256 public debtThreshold;

    bool public emergencyExit;

    modifier onlyAuthorized() {
        require(msg.sender == strategist || msg.sender == governance());
        _;
    }

    modifier onlyEmergencyAuthorized() {
        require(
            msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
        _;
    }

    modifier onlyStrategist() {
        require(msg.sender == strategist);
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance());
        _;
    }

    modifier onlyKeepers() {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
        _;
    }

    modifier onlyVaultManagers() {
        require(msg.sender == vault.management() || msg.sender == governance());
        _;
    }

    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        //Already initialized
        require(address(want) == address(0));

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, uint256(-1));
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;

        vault.approve(rewards, uint256(-1));
    }

    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        healthCheck = _healthCheck;
    }

    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        doHealthCheck = _doHealthCheck;
    }

    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    function setRewards(address _rewards) external onlyStrategist {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, uint256(-1));
        emit UpdatedRewards(_rewards);
    }

    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }

    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }

    function setMetadataURI(string calldata _metadataURI)
        external
        onlyAuthorized
    {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    function governance() internal view returns (address) {
        return vault.governance();
    }

    // Removing ethToWant() because we always override it and put it to 0
    //function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    function estimatedTotalAssets() public view virtual returns (uint256);

    function isActive() public view returns (bool) {
        return
            vault.strategies(address(this)).debtRatio > 0 ||
            estimatedTotalAssets() > 0;
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    function liquidatePosition(uint256 _amountNeeded)
        internal
        virtual
        returns (uint256 _liquidatedAmount, uint256 _loss);

    function liquidateAllPositions()
        internal
        virtual
        returns (uint256 _amountFreed);

    function tendTrigger(uint256 callCostInWei)
        public
        view
        virtual
        returns (bool)
    {
        return false;
    }

    function tend() external onlyKeepers {
        adjustPosition(vault.debtOutstanding());
    }

    /// @notice the only change is that we set callCost to 0. The behaviour is exactly the same as before, since ethToWant always returned 0
    function harvestTrigger(uint256 callCostInWei)
        public
        view
        virtual
        returns (bool)
    {
        //OLD VERSION
        //uint256 callCost = ethToWant(callCostInWei);
        //NEW VERSION
        uint256 callCost = 0;
        StrategyParams memory params = vault.strategies(address(this));

        if (params.activation == 0) return false;

        if (block.timestamp.sub(params.lastReport) < minReportDelay)
            return false;

        if (block.timestamp.sub(params.lastReport) >= maxReportDelay)
            return true;

        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;

        uint256 total = estimatedTotalAssets();

        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt);

        uint256 credit = vault.creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }

    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
        } else {
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);

        adjustPosition(debtOutstanding);

        if (doHealthCheck && healthCheck != address(0)) {
            require(
                HealthCheck(healthCheck).check(
                    profit,
                    loss,
                    debtPayment,
                    debtOutstanding,
                    totalDebt
                ),
                "!h"
            );
        } else {
            doHealthCheck = true;
        }

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault));
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        want.safeTransfer(msg.sender, amountFreed);
    }

    function prepareMigration(address _newStrategy) internal virtual;

    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategyRedux(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();

        emit EmergencyExitEnabled();
    }

    function protectedTokens() internal view virtual returns (address[] memory);

    function sweep(address _token) external onlyGovernance {
        require(_token != address(want));
        require(_token != address(vault));

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++)
            require(_token != _protectedTokens[i]);

        IERC20(_token).safeTransfer(
            governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }
}

// NOTE: we do not use it, if you need it, just use the one from yearn
// abstract contract BaseStrategyInitializable is BaseStrategy {
//     bool public isOriginal = true;
//     event Cloned(address indexed clone);

//     constructor(address _vault) public BaseStrategy(_vault) {}

//     function initialize(
//         address _vault,
//         address _strategist,
//         address _rewards,
//         address _keeper
//     ) external virtual {
//         _initialize(_vault, _strategist, _rewards, _keeper);
//     }

//     function clone(address _vault) external returns (address) {
//         require(isOriginal, "!clone");
//         return this.clone(_vault, msg.sender, msg.sender, msg.sender);
//     }

//     function clone(
//         address _vault,
//         address _strategist,
//         address _rewards,
//         address _keeper
//     ) external returns (address newStrategy) {
//         bytes20 addressBytes = bytes20(address(this));

//         assembly {
//             let clone_code := mload(0x40)
//             mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
//             mstore(add(clone_code, 0x14), addressBytes)
//             mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
//             newStrategy := create(0, clone_code, 0x37)
//         }

//         BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

//         emit Cloned(newStrategy);
//     }
// }

// File: StrategyInsurance.sol

// Feel free to change the license, but this is what we use

interface StrategyAPIExt is StrategyAPI {
    function strategist() external view returns (address);

    function insurance() external view returns (address);
}

interface IStrategyInsurance {
    function reportProfit(uint256 _totalDebt, uint256 _profit)
        external
        returns (uint256 _payment, uint256 _compensation);

    function reportLoss(uint256 _totalDebt, uint256 _loss)
        external
        returns (uint256 _compensation);

    function migrateInsurance(address newInsurance) external;
}

/**
 * @title Strategy Generic Insurrance
 * @author Robovault
 * @notice
 *  StrategyInsurance provides an issurrance fund for strategy losses
 *  A portion of all profits are sent to the insurrance fund untill
 *  it reaches its target insurrance percentage. When a loss is realised
 *  by the strategy the inssurance fund will return the funds to the
 *  strategy to fully compensate or soften the loss.
 */
contract StrategyInsurance {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    StrategyAPIExt public strategy;
    IERC20 want;
    uint256 constant BPS_MAX = 10000;
    uint256 public lossSum = 0;

    event InsurancePayment(
        uint256 indexed strategyDebt,
        uint256 indexed harvestProfit,
        uint256 indexed wantPayment
    );
    event InsurancePayout(uint256 indexed wantPayout);

    // Bips - Proportion of totalDebt the inssurance fund is targeting to grow
    uint256 public targetFundSize = 50; // 0.5% default

    // Rate of the profits that go to insurrance while it's below target
    uint256 public profitTakeRate = 1000; // 10% default

    // The maximum compensation rate the insurrance fund will return funds to the strategy
    // proportional to the TotalDebt of the strategy
    uint256 public maximumCompenstionRate = 5; // 5 bips per harvest default

    function _onlyAuthorized() internal {
        require(
            msg.sender == strategy.strategist() || msg.sender == governance()
        );
    }

    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }

    function _onlyStrategy() internal {
        require(msg.sender == address(strategy));
    }

    constructor(address _strategy) public {
        strategy = StrategyAPIExt(_strategy);
        want = IERC20(strategy.want());
    }

    function setTargetFundSize(uint256 _targetFundSize) external {
        _onlyAuthorized();
        require(_targetFundSize < 500); // Must be less than 5%
        targetFundSize = _targetFundSize;
    }

    function setProfitTakeRate(uint256 _profitTakeRate) external {
        _onlyAuthorized();
        require(_profitTakeRate < 4000); // Must be less than 40%
        profitTakeRate = _profitTakeRate;
    }

    function setmaximumCompenstionRate(uint256 _maximumCompenstionRate)
        external
    {
        _onlyAuthorized();
        require(_maximumCompenstionRate < 50); // Must be less than 0.5%
        maximumCompenstionRate = _maximumCompenstionRate;
    }

    /**
     * @notice
     *  Strategy reports profits to the insurrance find and informs the strategy
     *  of how much want is requested for insurrance.
     * @param _totalDebt Debt the strategy has with the vault.
     * @param _profit The profit the strategy is reporting this harvest
     * @return _payment amount requested for insurrance
     * @return _compensation amount paid out in latent insurance
     */
    function reportProfit(uint256 _totalDebt, uint256 _profit)
        external
        returns (uint256 _payment, uint256 _compensation)
    {
        _onlyStrategy();

        // if there has been a loss that is yet to be paid fully compensated, continue
        // to compensate
        if (lossSum > _profit) {
            lossSum = lossSum.sub(_profit);
            _compensation = compensate(_totalDebt);
            return (0, _compensation);
        }

        // no pending losses to pay out
        lossSum = 0;

        // Has the insurrance hit the insurrance target
        uint256 balance = want.balanceOf(address(this));
        uint256 targetBalance = _totalDebt.mul(targetFundSize).div(BPS_MAX);
        if (balance >= targetBalance) {
            return (0, 0);
        }

        _payment = _profit.mul(profitTakeRate).div(BPS_MAX);
        emit InsurancePayment(_totalDebt, _profit, _payment);
    }

    /**
     * @notice
     *  Strategy reports loss. The insurrance fund will decide weather or not to
     *  send want back to the strategy to soften the loss
     * @param _totalDebt Debt the strategy has with the vault.
     * @param _loss The loss realised by the this harvest
     * @return _compensation amount sent back to the strategy.
     */
    function reportLoss(uint256 _totalDebt, uint256 _loss)
        external
        returns (uint256 _compensation)
    {
        _onlyStrategy();

        lossSum = lossSum.add(_loss);
        _compensation = compensate(_totalDebt);
    }

    /**
     * @notice
     *  Processes insurance payouot
     * @param _totalDebt Debt the strategy has with the vault.
     * @return _compensation amount sent back to the strategy.
     */
    function compensate(uint256 _totalDebt)
        internal
        returns (uint256 _compensation)
    {
        uint256 balance = want.balanceOf(address(this));

        // Reserves are empties, we cannot compensate
        if (balance == 0) {
            lossSum = 0;
            return 0;
        }

        // Calculat what the payout will be
        uint256 maxComp = maximumCompenstionRate.mul(_totalDebt).div(BPS_MAX);
        _compensation = Math.min(Math.min(balance, lossSum), maxComp);

        if (_compensation > 0) {
            SafeERC20.safeTransfer(want, address(strategy), _compensation);
            emit InsurancePayout(_compensation);
        }
        lossSum = lossSum.sub(_compensation);
    }

    function governance() public view returns (address) {
        return VaultAPI(strategy.vault()).governance();
    }

    /**
     * @notice
     *  Sends balance to gov for the purpose of migrating to a new strategy at the
     *  disgression of governance.
     */
    function withdraw() external {
        _onlyGovernance();
        SafeERC20.safeTransfer(
            want,
            governance(),
            want.balanceOf(address(this))
        );
    }

    /**
     * @notice
     *  Sets the lossSum. Adds some flexibility with payouts to cover edge-case
     *  scenarios
     */
    function setLossSum(uint256 newLossSum) external {
        _onlyGovernance();
        lossSum = newLossSum;
    }

    /**
     * @notice
     *  called by the strategy when updating the insurance contract
     */
    function migrateInsurance(address newInsurance) external {
        _onlyStrategy();
        SafeERC20.safeTransfer(
            want,
            newInsurance,
            want.balanceOf(address(this))
        );
    }

    /**
     * @notice
     * Called by goverannace when updating the strategy
     */
    function migrateStrategy(address newStrategy) external {
        _onlyGovernance();
        SafeERC20.safeTransfer(
            want,
            StrategyAPIExt(newStrategy).insurance(),
            want.balanceOf(address(this))
        );
    }
}

// File: CoreStrategyBenqi.sol

// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;

// These are the core Yearn libraries

struct CoreStrategyBenqiConfig {
    // A portion of want token is depoisited into a lending platform to be used as
    // collateral. Short token is borrowed and compined with the remaining want token
    // and deposited into LP and farmed.
    address want;
    address short;
    /*****************************/
    /*             Farm           */
    /*****************************/
    // Liquidity pool address for base <-> short tokens
    address wantShortLP;
    // Address for farming reward token - eg Spirit/BOO
    address farmToken;
    // Liquidity pool address for farmToken <-> wFTM
    address farmTokenLP;
    // Farm address for reward farming
    address farmMasterChef;
    /*****************************/
    /*        Money Market       */
    /*****************************/
    // Base token cToken @ MM
    address cTokenLend;
    // Short token cToken @ MM
    address cTokenBorrow;
    // Lend/Borrow rewards
    address compToken;
    address compTokenLP;
    // address compLpAddress;
    address comptroller;
    /*****************************/
    /*            AMM            */
    /*****************************/
    // Liquidity pool address for base <-> short tokens @ the AMM.
    // @note: the AMM router address does not need to be the same
    // AMM as the farm, in fact the most liquid AMM is prefered to
    // minimise slippage.
    address router;
    address compRouter;
    uint256 minDeploy;
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

abstract contract CoreStrategyBenqi is BaseStrategyRedux {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event DebtRebalance(
        uint256 indexed debtRatio,
        uint256 indexed swapAmount,
        uint256 indexed slippage
    );
    event CollatRebalance(
        uint256 indexed collatRatio,
        uint256 indexed adjAmount
    );

    uint256 public collatUpper = 6700;
    uint256 public collatTarget = 6000;
    uint256 public collatLower = 5300;
    uint256 public debtUpper = 10190;
    uint256 public debtLower = 9810;
    uint256 public rebalancePercent = 10000; // 100% (how far does rebalance of debt move towards 100% from threshold)

    // protocal limits & upper, target and lower thresholds for ratio of debt to collateral
    uint256 public collatLimit = 7500;

    bool public doPriceCheck = true;

    // ERC20 Tokens;
    IERC20 public short;
    IUniswapV2Pair wantShortLP; // This is public because it helps with unit testing
    IERC20 farmTokenLP;
    IERC20 farmToken;
    IERC20 compToken;

    // Contract Interfaces
    ICTokenErc20 cTokenLend;
    ICAvax cTokenBorrow;
    address farm;
    IUniswapV2Router01 router;
    IUniswapV2Router01 compRouter;
    QIComptroller comptroller;
    IPriceOracle public oracle;
    IStrategyInsurance public insurance;

    uint256 public slippageAdj = 9900; // 99%

    uint256 constant BASIS_PRECISION = 10000;
    uint256 public priceSourceDiffKeeper = 500; // 5% Default
    uint256 public priceSourceDiffUser = 200; // 2% Default

    uint256 constant STD_PRECISION = 1e18;
    address wavax;
    uint256 public minDeploy;
    uint256 SHORT_DUST = 1e14;

    constructor(address _vault, CoreStrategyBenqiConfig memory _config)
        public
        BaseStrategyRedux(_vault)
    {
        // config = _config;

        // initialise token interfaces
        short = IERC20(_config.short);
        wantShortLP = IUniswapV2Pair(_config.wantShortLP);
        farmTokenLP = IERC20(_config.farmTokenLP);
        farmToken = IERC20(_config.farmToken);
        compToken = IERC20(_config.compToken);

        // initialise other interfaces
        cTokenLend = ICTokenErc20(_config.cTokenLend);
        cTokenBorrow = ICAvax(_config.cTokenBorrow);
        farm = (_config.farmMasterChef);
        router = IUniswapV2Router01(_config.router);
        compRouter = IUniswapV2Router01(_config.compRouter);
        comptroller = QIComptroller(_config.comptroller);
        wavax = router.WAVAX();

        enterMarket();
        approveContracts();

        maxReportDelay = 21600;
        minReportDelay = 14400;
        profitFactor = 1500;
        minDeploy = _config.minDeploy;
    }

    function name() external view override returns (string memory) {
        return "StrategyHedgedFarmingBQI";
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 totalAssets = estimatedTotalAssets();
        uint256 totalDebt = _getTotalDebt();
        if (totalAssets > totalDebt) {
            _profit = totalAssets.sub(totalDebt);
            (uint256 amountFreed, ) = _withdraw(_debtOutstanding.add(_profit));
            if (_debtOutstanding > amountFreed) {
                _debtPayment = amountFreed;
                _profit = 0;
            } else {
                _debtPayment = _debtOutstanding;
                _profit = amountFreed.sub(_debtOutstanding);
            }
        } else {
            _withdraw(_debtOutstanding);
            _debtPayment = balanceOfWant();
            _loss = totalDebt.sub(totalAssets);
        }

        _profit += _harvestInternal();

        // Check if we're net loss or net profit
        if (_loss >= _profit) {
            _profit = 0;
            _loss = _loss.sub(_profit);
            _loss = _loss.sub(insurance.reportLoss(totalDebt, _loss));
        } else {
            _profit = _profit.sub(_loss);
            _loss = 0;
            (uint256 insurancePayment, uint256 compensation) =
                insurance.reportProfit(totalDebt, _profit);
            _profit = _profit.sub(insurancePayment).add(compensation);

            // double check insurance isn't asking for too much or zero
            if (insurancePayment > 0 && insurancePayment < _profit) {
                SafeERC20.safeTransfer(
                    want,
                    address(insurance),
                    insurancePayment
                );
            }
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 _wantAvailable = balanceOfWant();
        if (_debtOutstanding >= _wantAvailable) {
            return;
        }
        uint256 toInvest = _wantAvailable.sub(_debtOutstanding);
        if (toInvest > 0) {
            _deploy(toInvest);
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        liquidateAllPositionsInternal();
    }

    function getTokenOutPath(address _token_in, address _token_out)
        internal
        view
        returns (address[] memory _path)
    {
        bool is_weth = _token_in == wavax || _token_out == wavax;
        _path = new address[](is_weth ? 2 : 3);
        _path[0] = _token_in;
        if (is_weth) {
            _path[1] = _token_out;
        } else {
            _path[1] = wavax;
            _path[2] = _token_out;
        }
    }

    function approveContracts() internal {
        want.safeApprove(address(cTokenLend), uint256(-1));
        short.safeApprove(address(cTokenBorrow), uint256(-1));
        want.safeApprove(address(router), uint256(-1));
        short.safeApprove(address(router), uint256(-1));
        farmToken.safeApprove(address(router), uint256(-1));
        compToken.safeApprove(address(compRouter), uint256(-1));
        IWavax(wavax).approve(address(router), uint256(-1));
        IERC20(address(wantShortLP)).safeApprove(address(router), uint256(-1));
        IERC20(address(wantShortLP)).safeApprove(address(farm), uint256(-1));
    }

    function setSlippageConfig(
        uint256 _slippageAdj,
        uint256 _priceSourceDiffUser,
        uint256 _priceSourceDiffKeeper,
        bool _doPriceCheck
    ) external onlyAuthorized {
        slippageAdj = _slippageAdj;
        priceSourceDiffKeeper = _priceSourceDiffKeeper;
        priceSourceDiffUser = _priceSourceDiffUser;
        doPriceCheck = _doPriceCheck;
    }

    function setInsurance(address _insurance) external onlyAuthorized {
        require(address(insurance) == address(0));
        insurance = IStrategyInsurance(_insurance);
    }

    function migrateInsurance(address _newInsurance) external onlyGovernance {
        require(address(_newInsurance) == address(0));
        insurance.migrateInsurance(_newInsurance);
        insurance = IStrategyInsurance(_newInsurance);
    }

    function setDebtThresholds(
        uint256 _lower,
        uint256 _upper,
        uint256 _rebalancePercent
    ) external onlyAuthorized {
        require(_lower <= BASIS_PRECISION);
        require(_rebalancePercent <= BASIS_PRECISION);
        require(_upper >= BASIS_PRECISION);
        rebalancePercent = _rebalancePercent;
        debtUpper = _upper;
        debtLower = _lower;
    }

    function setCollateralThresholds(
        uint256 _lower,
        uint256 _target,
        uint256 _upper,
        uint256 _limit
    ) external onlyAuthorized {
        require(_limit <= BASIS_PRECISION);
        collatLimit = _limit;
        require(collatLimit > _upper);
        require(_upper >= _target);
        require(_target >= _lower);
        collatUpper = _upper;
        collatTarget = _target;
        collatLower = _lower;
    }

    function liquidatePositionAuth(uint256 _amount) external onlyAuthorized {
        liquidatePosition(_amount);
    }

    function liquidateAllToLend() internal {
        _withdrawAllPooled();
        _removeAllLp();
        _repayDebt();
        _lendWant(balanceOfWant());
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        (_amountFreed, ) = liquidateAllPositionsInternal();
    }

    function liquidateAllPositionsInternal()
        internal
        returns (uint256 _amountFreed, uint256 _loss)
    {
        _withdrawAllPooled();
        _removeAllLp();

        uint256 debtInShort = balanceDebtInShortCurrent();
        uint256 balShort = balanceShort();
        if (balShort >= debtInShort) {
            _repayDebt();
            if (balanceShortWantEq() > 0) {
                (, _loss) = _swapExactShortWant(short.balanceOf(address(this)));
            }
        } else {
            uint256 debtDifference = debtInShort.sub(balShort);
            if (convertShortToWantLP(debtDifference) > 0) {
                (_loss) = _swapWantShortExact(debtDifference);
            } else {
                _swapExactWantShort(uint256(1));
            }
            _repayDebt();
        }

        _redeemWant(balanceLend());
        _amountFreed = balanceOfWant();
    }

    /// rebalances RoboVault strat position to within target collateral range
    function rebalanceCollateral() external onlyKeepers {
        // ratio of amount borrowed to collateral
        uint256 collatRatio = calcCollateral();
        require(collatRatio <= collatLower || collatRatio >= collatUpper);
        _rebalanceCollateralInternal();
    }

    /// rebalances RoboVault holding of short token vs LP to within target collateral range
    function rebalanceDebt() external onlyKeepers {
        uint256 debtRatio = calcDebtRatio();
        require(debtRatio < debtLower || debtRatio > debtUpper);
        require(_testPriceSource(priceSourceDiffKeeper));
        _rebalanceDebtInternal();
    }

    function claimHarvest() internal virtual;

    /// called by keeper to harvest rewards and either repay debt
    function _harvestInternal() internal returns (uint256 _wantHarvested) {
        uint256 wantBefore = balanceOfWant();
        /// harvest from farm & wantd on amt borrowed vs LP value either -> repay some debt or add to collateral
        claimHarvest();
        comptroller.claimReward(0, payable(address(this))); //claim QI

        comptroller.claimReward(1, payable(address(this))); //claim WAVAX

        _sellToToken(address(router), address(farmToken), address(wavax));
        _sellToToken(address(compRouter), address(compToken), address(wavax));
        if (IERC20(wavax).balanceOf(address(this)) > SHORT_DUST)
            _sellToToken(address(router), address(wavax), address(want));
        _wantHarvested = balanceOfWant().sub(wantBefore);
    }

    function _rebalanceCollateralInternal() internal {
        uint256 collatRatio = calcCollateral();
        uint256 shortPos = balanceDebt();
        uint256 lendPos = balanceLend();
        uint256 adjAmount;
        if (collatRatio > collatTarget) {
            adjAmount = (
                shortPos.sub(lendPos.mul(collatTarget).div(BASIS_PRECISION))
            )
                .mul(BASIS_PRECISION)
                .div(BASIS_PRECISION.add(collatTarget));
            /// remove some LP use 50% of withdrawn LP to repay debt and half to add to collateral
            _withdrawLpRebalanceCollateral(adjAmount.mul(2));
        } else if (collatRatio < collatTarget) {
            adjAmount = (
                (lendPos.mul(collatTarget).div(BASIS_PRECISION)).sub(shortPos)
            )
                .mul(BASIS_PRECISION)
                .div(BASIS_PRECISION.add(collatTarget));
            uint256 borrowAmt = _borrowWantEq(adjAmount);
            _redeemWant(adjAmount);
            _addToLP(borrowAmt);
            _depositLp();
        }
        emit CollatRebalance(collatRatio, adjAmount);
    }

    // deploy assets according to vault strategy
    function _deploy(uint256 _amount) internal {
        if (_amount < minDeploy) {
            return;
        }

        uint256 oPrice = oracle.getPrice();
        uint256 lpPrice = getLpPrice();
        uint256 borrow =
            collatTarget.mul(_amount).mul(1e18).div(
                BASIS_PRECISION.mul(
                    (collatTarget.mul(lpPrice).div(BASIS_PRECISION).add(oPrice))
                )
            );

        uint256 debtAllocation = borrow.mul(lpPrice).div(1e18);

        uint256 lendNeeded = _amount.sub(debtAllocation);

        _lendWant(lendNeeded);
        _borrow(borrow);
        _addToLP(borrow);
        _depositLp();
    }

    function getLpPrice() internal view returns (uint256) {
        (uint256 wantInLp, uint256 shortInLp) = getLpReserves();
        return wantInLp.mul(1e18).div(shortInLp);
    }

    /**
     * @notice
     *  Reverts if the difference in the price sources are >  priceSourceDiff
     */
    function _testPriceSource(uint256 priceDiff) internal returns (bool) {
        if (doPriceCheck) {
            uint256 oPrice = oracle.getPrice();
            uint256 lpPrice = getLpPrice();
            uint256 priceSourceRatio = oPrice.mul(BASIS_PRECISION).div(lpPrice);
            return (priceSourceRatio > BASIS_PRECISION.sub(priceDiff) &&
                priceSourceRatio < BASIS_PRECISION.add(priceDiff));
        }
        return true;
    }

    /**
     * @notice
     *  Assumes all balance is in Lend outside of a small amount of debt and short. Deploys
     *  capital maintaining the collatRatioTarget
     *
     * @dev
     *  Some crafty maths here:
     *  B: borrow amount in short (Not total debt!)
     *  L: Lend in want
     *  Cr: Collateral Target
     *  Po: Oracle price (short * Po = want)
     *  Plp: LP Price
     *  Di: Initial Debt in short
     *  Si: Initial short balance
     *
     *  We want:
     *  Cr = BPo / L
     *  T = L + Plp(B + 2Si - Di)
     *
     *  Solving this for L finds:
     *  B = (TCr - Cr*Plp(2Si-Di)) / (Po + Cr*Plp)
     */
    function _calcDeployment(uint256 _amount)
        internal
        returns (uint256 _lendNeeded, uint256 _borrow)
    {
        uint256 oPrice = oracle.getPrice();
        uint256 lpPrice = getLpPrice();
        uint256 Si2 = balanceShort().mul(2);
        uint256 Di = balanceDebtInShort();
        uint256 CrPlp = collatTarget.mul(lpPrice);
        uint256 numerator;

        // NOTE: may throw if _amount * CrPlp > 1e70
        if (Di > Si2) {
            numerator = (
                collatTarget.mul(_amount).mul(1e18).add(CrPlp.mul(Di.sub(Si2)))
            )
                .sub(oPrice.mul(BASIS_PRECISION).mul(Di));
        } else {
            numerator = (
                collatTarget.mul(_amount).mul(1e18).sub(CrPlp.mul(Si2.sub(Di)))
            )
                .sub(oPrice.mul(BASIS_PRECISION).mul(Di));
        }

        _borrow = numerator.div(
            BASIS_PRECISION.mul(oPrice.add(CrPlp.div(BASIS_PRECISION)))
        );
        _lendNeeded = _amount.sub(
            (_borrow.add(Si2).sub(Di)).mul(lpPrice).div(1e18)
        );
    }

    function _deployFromLend(uint256 _amount) internal {
        (uint256 _lendNeeded, uint256 _borrowAmt) = _calcDeployment(_amount);
        _redeemWant(balanceLend().sub(_lendNeeded));
        _borrow(_borrowAmt);
        _addToLP(balanceShort());
        _depositLp();
    }

    function _rebalanceDebtInternal() internal {
        uint256 swapAmountWant;
        uint256 slippage;
        uint256 debtRatio = calcDebtRatio();

        // Liquidate all the lend, leaving some in debt or as short
        liquidateAllToLend();

        uint256 debtInShort = balanceDebtInShort();
        uint256 balShort = balanceShort();

        if (debtInShort > balShort) {
            uint256 debt = convertShortToWantLP(debtInShort);
            // If there's excess debt, we swap some want to repay a portion of the debt
            swapAmountWant = debt.mul(rebalancePercent).div(BASIS_PRECISION);
            _redeemWant(swapAmountWant);
            slippage = _swapExactWantShort(swapAmountWant);
            _repayDebt();
        } else {
            // If there's excess short, we swap some to want which will be used
            // to create lp in _deployFromLend()
            (swapAmountWant, slippage) = _swapExactShortWant(
                balanceShort().mul(rebalancePercent).div(BASIS_PRECISION)
            );
        }

        _deployFromLend(estimatedTotalAssets());
        emit DebtRebalance(debtRatio, swapAmountWant, slippage);
    }

    /**
     * Withdraws and removes `_deployedPercent` percentage if LP from farming and pool respectively
     *
     * @param _deployedPercent percentage multiplied by BASIS_PRECISION of LP to remove.
     */
    function _removeLpPercent(uint256 _deployedPercent) internal {
        uint256 lpPooled = countLpPooled();
        uint256 lpUnpooled = wantShortLP.balanceOf(address(this));
        uint256 lpCount = lpUnpooled.add(lpPooled);
        uint256 lpReq = lpCount.mul(_deployedPercent).div(BASIS_PRECISION);
        uint256 lpWithdraw;
        if (lpReq - lpUnpooled < lpPooled) {
            lpWithdraw = lpReq.sub(lpUnpooled);
        } else {
            lpWithdraw = lpPooled;
        }

        // Finnally withdraw the LP from farms and remove from pool
        _withdrawSomeLp(lpWithdraw);
        _removeAllLp();
    }

    function _getTotalDebt() internal view returns (uint256) {
        return vault.strategies(address(this)).totalDebt;
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 balanceWant = balanceOfWant();
        uint256 totalAssets = estimatedTotalAssets();

        // if estimatedTotalAssets is less than params.debtRatio it means there's
        // been a loss (ignores pending harvests). This type of loss is calculated
        // proportionally
        // This stops a run-on-the-bank if there's IL between harvests.
        uint256 newAmount = _amountNeeded;
        uint256 totalDebt = _getTotalDebt();
        if (totalDebt > totalAssets) {
            uint256 ratio = totalAssets.mul(STD_PRECISION).div(totalDebt);
            newAmount = _amountNeeded.mul(ratio).div(STD_PRECISION);
            _loss = _amountNeeded.sub(newAmount);
        }

        // Liquidate the amount needed
        (, uint256 _slippage) = _withdraw(newAmount);
        _loss = _loss.add(_slippage);

        // NOTE: Maintain invariant `want.balanceOf(this) >= _liquidatedAmount`
        // NOTE: Maintain invariant `_liquidatedAmount + _loss <= _amountNeeded`
        _liquidatedAmount = balanceOfWant();
        if (_liquidatedAmount.add(_loss) > _amountNeeded) {
            _liquidatedAmount = _amountNeeded.sub(_loss);
        } else {
            _loss = _amountNeeded.sub(_liquidatedAmount);
        }
    }

    /**
     * function to remove funds from strategy when users withdraws funds in excess of reserves
     *
     * withdraw takes the following steps:
     * 1. Removes _amountNeeded worth of LP from the farms and pool
     * 2. Uses the short removed to repay debt (Swaps short or base for large withdrawals)
     * 3. Redeems the
     * @param _amountNeeded `want` amount to liquidate
     */
    function _withdraw(uint256 _amountNeeded)
        internal
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 balanceWant = balanceOfWant();
        require(_testPriceSource(priceSourceDiffUser));
        if (_amountNeeded <= balanceWant) {
            return (_amountNeeded, 0);
        }

        uint256 balanceDeployed = balanceDeployed();

        // stratPercent: Percentage of the deployed capital we want to liquidate.
        uint256 stratPercent =
            _amountNeeded.sub(balanceWant).mul(BASIS_PRECISION).div(
                balanceDeployed
            );

        if (stratPercent > 9500) {
            // If this happened, we just undeploy the lot
            // and it'll be redeployed during the next harvest.
            (, _loss) = liquidateAllPositionsInternal();
            _liquidatedAmount = balanceOfWant().sub(balanceWant);
        } else {
            // liquidate all to lend
            liquidateAllToLend();

            // Only rebalance if more than 5% is being liquidated
            // to save on gas
            uint256 slippage = 0;
            if (stratPercent > 500) {
                // swap to ensure the debt ratio isn't negatively affected
                uint256 shortInShort = balanceShort();
                uint256 debtInShort = balanceDebtInShort();
                if (debtInShort > shortInShort) {
                    uint256 debt = convertShortToWantLP(debtInShort);
                    uint256 swapAmountWant =
                        debt.mul(stratPercent).div(BASIS_PRECISION);
                    _redeemWant(swapAmountWant);
                    slippage = _swapExactWantShort(swapAmountWant);
                    _repayDebt();
                } else {
                    (, slippage) = _swapExactShortWant(
                        balanceShort().mul(stratPercent).div(BASIS_PRECISION)
                    );
                }
            }

            // Redeploy the strat
            _deployFromLend(balanceDeployed.sub(_amountNeeded).add(slippage));
            _liquidatedAmount = balanceOfWant().sub(balanceWant);
            _loss = slippage;
        }
    }

    function enterMarket() internal {
        address[] memory cTokens = new address[](2);
        cTokens[0] = address(cTokenLend);
        cTokens[1] = address(cTokenBorrow);
        comptroller.enterMarkets(cTokens);
    }

    /**
     * This method is often farm specific so it needs to be declared elsewhere.
     */
    function _farmPendingRewards(address _user)
        internal
        view
        virtual
        returns (uint256);

    // calculate total value of vault assets
    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant().add(balanceDeployed());
    }

    // calculate total value of vault assets
    function balanceDeployed() public view returns (uint256) {
        return
            balanceLend().add(balanceLp()).add(balanceShortWantEq()).sub(
                balanceDebt()
            );
    }

    // debt ratio - used to trigger rebalancing of debt
    function calcDebtRatio() public view returns (uint256) {
        return (balanceDebt().mul(BASIS_PRECISION).mul(2).div(balanceLp()));
    }

    // calculate debt / collateral - used to trigger rebalancing of debt & collateral
    function calcCollateral() public view returns (uint256) {
        return balanceDebtOracle().mul(BASIS_PRECISION).div(balanceLend());
    }

    function getLpReserves()
        public
        view
        returns (uint256 _wantInLp, uint256 _shortInLp)
    {
        (uint112 reserves0, uint112 reserves1, ) = wantShortLP.getReserves();
        if (wantShortLP.token0() == address(want)) {
            _wantInLp = uint256(reserves0);
            _shortInLp = uint256(reserves1);
        } else {
            _wantInLp = uint256(reserves1);
            _shortInLp = uint256(reserves0);
        }
    }

    function convertShortToWantLP(uint256 _amountShort)
        internal
        view
        returns (uint256)
    {
        (uint256 wantInLp, uint256 shortInLp) = getLpReserves();
        return (_amountShort.mul(wantInLp).div(shortInLp));
    }

    function convertShortToWantOracle(uint256 _amountShort)
        internal
        view
        returns (uint256)
    {
        return _amountShort.mul(oracle.getPrice()).div(1e18);
    }

    function convertWantToShortLP(uint256 _amountWant)
        internal
        view
        returns (uint256)
    {
        (uint256 wantInLp, uint256 shortInLp) = getLpReserves();
        return _amountWant.mul(shortInLp).div(wantInLp);
    }

    function balanceLpInShort() public view returns (uint256) {
        return countLpPooled().add(wantShortLP.balanceOf(address(this)));
    }

    /// get value of all LP in want currency
    function balanceLp() public view returns (uint256) {
        (uint256 wantInLp, ) = getLpReserves();
        return
            balanceLpInShort().mul(wantInLp).mul(2).div(
                wantShortLP.totalSupply()
            );
    }

    // value of borrowed tokens in value of want tokens
    function balanceDebtInShort() public view returns (uint256) {
        return cTokenBorrow.borrowBalanceStored(address(this));
    }

    // value of borrowed tokens in value of want tokens
    // Uses current exchange price, not stored
    function balanceDebtInShortCurrent() internal returns (uint256) {
        return cTokenBorrow.borrowBalanceCurrent(address(this));
    }

    // value of borrowed tokens in value of want tokens
    function balanceDebt() public view returns (uint256) {
        return convertShortToWantLP(balanceDebtInShort());
    }

    /**
     * Debt balance using price oracle
     */
    function balanceDebtOracle() public view returns (uint256) {
        return convertShortToWantOracle(balanceDebtInShort());
    }

    function balancePendingHarvest() public view virtual returns (uint256) {
        uint256 rewardsPending =
            _farmPendingRewards(address(this)).add(
                farmToken.balanceOf(address(this))
            );
        uint256 harvestLP_A = farmToken.balanceOf(address(farmTokenLP));
        uint256 shortLP_A = short.balanceOf(address(farmTokenLP));
        (uint256 wantLP_B, uint256 shortLP_B) = getLpReserves();

        uint256 balShort = rewardsPending.mul(shortLP_A).div(harvestLP_A);
        uint256 balRewards = balShort.mul(wantLP_B).div(shortLP_B);
        return (balRewards);
    }

    // reserves
    function balanceOfWant() public view returns (uint256) {
        return (want.balanceOf(address(this)));
    }

    function balanceShort() public view returns (uint256) {
        return (short.balanceOf(address(this)));
    }

    function balanceShortWantEq() public view returns (uint256) {
        return (convertShortToWantLP(short.balanceOf(address(this))));
    }

    function balanceLend() public view returns (uint256) {
        return (
            cTokenLend
                .balanceOf(address(this))
                .mul(cTokenLend.exchangeRateStored())
                .div(1e18)
        );
    }

    function countLpPooled() internal view virtual returns (uint256);

    // lend want tokens to lending platform
    function _lendWant(uint256 amount) internal {
        cTokenLend.mint(amount);
    }

    // borrow tokens woth _amount of want tokens
    function _borrowWantEq(uint256 _amount)
        internal
        returns (uint256 _borrowamount)
    {
        _borrowamount = convertWantToShortLP(_amount);
        _borrow(_borrowamount);
    }

    function _borrow(uint256 borrowAmount) internal {
        cTokenBorrow.borrow(borrowAmount);
        IWavax(payable(wavax)).deposit{value: address(this).balance}();
    }

    // automatically repays debt using any short tokens held in wallet up to total debt value
    function _repayDebt() internal {
        uint256 _bal = short.balanceOf(address(this));
        if (_bal == 0) return;

        uint256 _debt = balanceDebtInShort();
        if (_bal < _debt) {
            _debt = _bal;
        }
        IWavax(wavax).withdraw(_debt);
        cTokenBorrow.repayBorrow{value: _debt}();
    }

    function _redeemWant(uint256 _redeem_amount) internal {
        cTokenLend.redeemUnderlying(_redeem_amount);
    }

    // withdraws some LP worth _amount, converts all withdrawn LP to short token to repay debt
    function _withdrawLpRebalance(uint256 _amount)
        internal
        returns (uint256 swapAmountWant, uint256 slippageWant)
    {
        uint256 lpUnpooled = wantShortLP.balanceOf(address(this));
        uint256 lpPooled = countLpPooled();
        uint256 lpCount = lpUnpooled.add(lpPooled);
        uint256 lpReq = _amount.mul(lpCount).div(balanceLp());
        uint256 lpWithdraw;
        if (lpReq - lpUnpooled < lpPooled) {
            lpWithdraw = lpReq - lpUnpooled;
        } else {
            lpWithdraw = lpPooled;
        }
        _withdrawSomeLp(lpWithdraw);
        _removeAllLp();
        swapAmountWant = Math.min(
            _amount.div(2),
            want.balanceOf(address(this))
        );
        slippageWant = _swapExactWantShort(swapAmountWant);

        _repayDebt();
    }

    //  withdraws some LP worth _amount, uses withdrawn LP to add to collateral & repay debt
    function _withdrawLpRebalanceCollateral(uint256 _amount) internal {
        uint256 lpUnpooled = wantShortLP.balanceOf(address(this));
        uint256 lpPooled = countLpPooled();
        uint256 lpCount = lpUnpooled.add(lpPooled);
        uint256 lpReq = _amount.mul(lpCount).div(balanceLp());
        uint256 lpWithdraw;
        if (lpReq - lpUnpooled < lpPooled) {
            lpWithdraw = lpReq - lpUnpooled;
        } else {
            lpWithdraw = lpPooled;
        }
        _withdrawSomeLp(lpWithdraw);
        _removeAllLp();
        uint256 wantBal = balanceOfWant();
        if (_amount.div(2) <= wantBal) {
            _lendWant(_amount.div(2));
        } else {
            _lendWant(wantBal);
        }
        _repayDebt();
    }

    function _addToLP(uint256 _amountShort) internal {
        uint256 _amountWant = convertShortToWantLP(_amountShort);

        uint256 balWant = want.balanceOf(address(this));
        if (balWant < _amountWant) {
            _amountWant = balWant;
        }
        router.addLiquidity(
            address(short),
            address(want),
            _amountShort,
            _amountWant,
            _amountShort.mul(slippageAdj).div(BASIS_PRECISION),
            _amountWant.mul(slippageAdj).div(BASIS_PRECISION),
            address(this),
            now
        );
    }

    function _depositLp() internal virtual;

    function _withdrawFarm(uint256 _amount) internal virtual;

    function _withdrawSomeLp(uint256 _amount) internal {
        require(_amount <= countLpPooled());
        _withdrawFarm(_amount);
    }

    function _withdrawAllPooled() internal {
        uint256 lpPooled = countLpPooled();
        _withdrawFarm(lpPooled);
    }

    // all LP currently not in Farm is removed.
    function _removeAllLp() internal {
        uint256 _amount = wantShortLP.balanceOf(address(this));
        if (_amount > 0) {
            (uint256 wantLP, uint256 shortLP) = getLpReserves();
            uint256 lpIssued = wantShortLP.totalSupply();

            uint256 amountAMin =
                _amount.mul(shortLP).mul(slippageAdj).div(BASIS_PRECISION).div(
                    lpIssued
                );
            uint256 amountBMin =
                _amount.mul(wantLP).mul(slippageAdj).div(BASIS_PRECISION).div(
                    lpIssued
                );
            router.removeLiquidity(
                address(short),
                address(want),
                _amount,
                amountAMin,
                amountBMin,
                address(this),
                now
            );
        }
    }

    /**
     * @notice
     *  Swaps token to want using router
     *
     * @param router univ2 router address
     * @param from token to sell
     * @param to token to swap to
     */
    function _sellToToken(
        address router,
        address from,
        address to
    ) internal {
        uint256 balance = IERC20(from).balanceOf(address(this));
        if (balance == 0) return;
        IUniswapV2Router01(router).swapExactTokensForTokens(
            balance,
            0,
            getTokenOutPath(from, to),
            address(this),
            now
        );
    }

    /**
     * @notice
     *  Swaps _amount of want for short
     *
     * @param _amount The amount of want to swap
     *
     * @return slippageWant Returns the cost of fees + slippage in want
     */
    function _swapExactWantShort(uint256 _amount)
        internal
        returns (uint256 slippageWant)
    {
        uint256 amountOutMin = convertWantToShortLP(_amount);
        uint256[] memory amounts =
            router.swapExactTokensForTokens(
                _amount,
                amountOutMin.mul(slippageAdj).div(BASIS_PRECISION),
                getTokenOutPath(address(want), address(short)),
                address(this),
                now
            );
        slippageWant = convertShortToWantLP(
            amountOutMin.sub(amounts[amounts.length - 1])
        );
    }

    /**
     * @notice
     *  Swaps _amount of short for want
     *
     * @param _amountShort The amount of short to swap
     *
     * @return _amountWant Returns the want amount minus fees
     * @return _slippageWant Returns the cost of fees + slippage in want
     */
    function _swapExactShortWant(uint256 _amountShort)
        internal
        returns (uint256 _amountWant, uint256 _slippageWant)
    {
        _amountWant = convertShortToWantLP(_amountShort);
        uint256[] memory amounts =
            router.swapExactTokensForTokens(
                _amountShort,
                _amountWant.mul(slippageAdj).div(BASIS_PRECISION),
                getTokenOutPath(address(short), address(want)),
                address(this),
                now
            );
        _slippageWant = _amountWant.sub(amounts[amounts.length - 1]);
    }

    function _swapWantShortExact(uint256 _amountOut)
        internal
        returns (uint256 _slippageWant)
    {
        uint256 amountInWant = convertShortToWantLP(_amountOut);
        uint256 amountInMax =
            (amountInWant.mul(BASIS_PRECISION).div(slippageAdj)).add(10); // add 1 to make up for rounding down
        uint256[] memory amounts =
            router.swapTokensForExactTokens(
                _amountOut,
                amountInMax,
                getTokenOutPath(address(want), address(short)),
                address(this),
                now
            );
        _slippageWant = amounts[0].sub(amountInWant);
    }

    // Required for BenQi interface
    receive() external payable {}

    /**
     * @notice
     *  Intentionally not implmenting this. The justification being:
     *   1. It doesn't actually add any additional security because gov
     *      has the powers to do the same thing with addStrategy already
     *   2. Being able to sweep tokens from a strategy could be helpful
     *      incase of an unexpected catastropic failure.
     */
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}
}

// File: USDTAVAXBQIVTX.sol

contract USDTAVAXBQIVTX is CoreStrategyBenqi {
    // Find rewarder farmMasterChef -> masterVtx.addressToPoolInfo(farmMasterChef.stakingToken).rewarder
    address constant rewarder = 0xcFCE02bA8373Fd986088c5003B2f67FEc00f8D82;

    constructor(address _vault)
        public
        CoreStrategyBenqi(
            _vault,
            CoreStrategyBenqiConfig(
                0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7, // want
                0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7, // short
                0xbb4646a764358ee93c2a9c4a147d5aDEd527ab73, // wantShortLP
                0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd, // farmToken -> JOE
                0x454E67025631C065d3cFAD6d71E6892f74487a15, // farmTokenLp -> JOE/WAVAX
                0x9448e1Aec49Fe041643AEd614F04b0F7eB391126, // farmMasterChef
                0xd8fcDa6ec4Bdc547C0827B8804e89aCd817d56EF, // cTokenLend
                0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c, // cTokenBorrow
                0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5, // compToken
                0xE530dC2095Ef5653205CF5ea79F8979a7028065c, // compTokenLP
                0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4, // comptroller
                0x60aE616a2155Ee3d9A68541Ba4544862310933d4, // router
                0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106, // compRouter
                1e4 //mindeploy
            )
        )
    {
        oracle = new ScreamPriceOracle(
            address(comptroller),
            address(cTokenLend),
            address(cTokenBorrow)
        );
    }

    function _farmPendingRewards(address _user)
        internal
        view
        override
        returns (uint256)
    {
        return
            IBaseRewardPool(rewarder)
                .earned(address(this), address(farmToken))
                .add(farmToken.balanceOf(address(this)));
    }

    function _depositLp() internal override {
        uint256 lpBalance = wantShortLP.balanceOf(address(this));
        IVectorChef(farm).deposit(lpBalance);
    }

    function _withdrawFarm(uint256 _amount) internal override {
        if (_amount > 0) IVectorChef(farm).withdraw(_amount);
    }

    function claimHarvest() internal override {
        IVectorChef(farm).getReward();
    }

    function countLpPooled() internal view override returns (uint256) {
        return IVectorChef(farm).balanceOf(address(this));
    }
}