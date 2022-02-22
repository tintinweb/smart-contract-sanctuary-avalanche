/**
 *Submitted for verification at snowtrace.io on 2022-02-22
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File contracts/range/interfaces/IOSWAP_RangeLiquidityProvider.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOSWAP_RangeLiquidityProvider {

    function factory() external view returns (address);
    function WETH() external view returns (address);
    function govToken() external view returns (address);

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool addingTokenA,
        uint256 staked,
        uint256 amountIn,
        uint256 lowerLimit,
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) external returns (uint256 index);
    function addLiquidityETH(
        address tokenA,
        bool addingTokenA,
        uint256 staked,
        uint256 amountAIn,
        uint256 lowerLimit,
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) external payable returns (uint256 index);

    function updateProviderOffer(
        address tokenA, 
        address tokenB, 
        uint256 replenishAmount, 
        uint256 lowerLimit, 
        uint256 upperLimit, 
        uint256 startDate,
        uint256 expire, 
        bool privateReplenish, 
        uint256 deadline
    ) external;

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool removingTokenA,
        address to,
        uint256 unstake,
        uint256 amountOut,
        uint256 reserveOut,
        uint256 lowerLimit,
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) external;
    function removeLiquidityETH(
        address tokenA,
        bool removingTokenA,
        address to,
        uint256 unstake,
        uint256 amountOut,
        uint256 reserveOut,
        uint256 lowerLimit,
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) external;
    function removeAllLiquidity(
        address tokenA,
        address tokenB,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    function removeAllLiquidityETH(
        address tokenA,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}


// File contracts/commons/interfaces/IOSWAP_PausablePair.sol


pragma solidity =0.6.11;

interface IOSWAP_PausablePair {
    function isLive() external view returns (bool);
    function factory() external view returns (address);

    function setLive(bool _isLive) external;
}


// File contracts/range/interfaces/IOSWAP_RangePair.sol


pragma solidity =0.6.11;

interface IOSWAP_RangePair is IOSWAP_PausablePair {

    struct Offer {
        address provider;
        uint256 amount;
        uint256 reserve;
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 startDate;
        uint256 expire;
        bool privateReplenish;
    } 

    event NewProvider(address indexed provider, uint256 index);
    event AddLiquidity(address indexed provider, bool indexed direction, uint256 staked, uint256 amount, uint256 newStakeBalance, uint256 newAmountBalance, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire);
    event Replenish(address indexed provider, bool indexed direction, uint256 amountIn, uint256 newAmountBalance, uint256 newReserveBalance);
    event UpdateProviderOffer(address indexed provider, bool indexed direction, uint256 replenish, uint256 newAmountBalance, uint256 newReserveBalance, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire, bool privateReplenish);
    event RemoveLiquidity(address indexed provider, bool indexed direction, uint256 unstake, uint256 amountOut, uint256 reserveOut, uint256 newStakeBalance, uint256 newAmountBalance, uint256 newReserveBalance, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire);
    event RemoveAllLiquidity(address indexed provider, uint256 unstake, uint256 amount0Out, uint256 amount1Out);
    event Swap(address indexed to, bool indexed direction, uint256 price, uint256 amountIn, uint256 amountOut, uint256 tradeFee, uint256 protocolFee);
    event SwappedOneProvider(address indexed provider, bool indexed direction, uint256 amountOut, uint256 amountIn, uint256 newAmountBalance, uint256 newCounterReserveBalance);

    function counter() external view returns (uint256);
    function offers(bool direction, uint256 index) external view returns (
        address provider,
        uint256 amount,
        uint256 reserve,
        uint256 lowerLimit,
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        bool privateReplenish
    );
    function providerOfferIndex(address provider) external view returns (uint256 index);
    function providerStaking(address provider) external view returns (uint256 stake);

    function oracleFactory() external view returns (address);
    function governance() external view returns (address);
    function rangeLiquidityProvider() external view returns (address);
    function govToken() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function scaleDirection() external view returns (bool);
    function scaler() external view returns (uint256);

    function lastGovBalance() external view returns (uint256);
    function lastToken0Balance() external view returns (uint256);
    function lastToken1Balance() external view returns (uint256);
    function protocolFeeBalance0() external view returns (uint256);
    function protocolFeeBalance1() external view returns (uint256);
    function stakeBalance() external view returns (uint256);

    function initialize(address _token0, address _token1) external;

    function getOffers(bool direction, uint256 start, uint256 end) external view returns (address[] memory provider, uint256[] memory amountAndReserve, uint256[] memory lowerLimitAndUpperLimit, uint256[] memory startDateAndExpire, bool[] memory privateReplenish);
    function getLastBalances() external view returns (uint256, uint256);
    function getBalances() external view returns (uint256, uint256, uint256);

    function getLatestPrice(bool direction, bytes calldata payload) external view returns (uint256);
    function getAmountOut(address tokenIn, uint256 amountIn, bytes calldata data) external view returns (uint256 amountOut);
    function getAmountIn(address tokenOut, uint256 amountOut, bytes calldata data) external view returns (uint256 amountIn);

    function getProviderOffer(address provider, bool direction) external view returns (uint256 index, uint256 staked, uint256 amount, uint256 reserve, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire, bool privateReplenish);
    function addLiquidity(address provider, bool direction, uint256 staked, uint256 _lowerLimit, uint256 _upperLimit, uint256 startDate, uint256 expire) external returns (uint256 index);
    function updateProviderOffer(address provider, bool direction, uint256 replenish, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire, bool privateReplenish) external;
    function replenish(address provider, bool direction, uint256 amountIn) external;
    function removeLiquidity(address provider, bool direction, uint256 unstake, uint256 amountOut, uint256 reserveOut, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire) external;
    function removeAllLiquidity(address provider) external returns (uint256 amount0, uint256 amount1, uint256 staked);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function redeemProtocolFee() external;
}


// File contracts/interfaces/IERC20.sol


pragma solidity =0.6.11;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/libraries/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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


// File contracts/libraries/Address.sol



pragma solidity =0.6.11;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File contracts/commons/interfaces/IOSWAP_PausableFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_PausableFactory {
    event Shutdowned();
    event Restarted();
    event PairShutdowned(address indexed pair);
    event PairRestarted(address indexed pair);

    function governance() external view returns (address);

    function isLive() external returns (bool);
    function setLive(bool _isLive) external;
    function setLiveForPair(address pair, bool live) external;
}


// File contracts/commons/interfaces/IOSWAP_FactoryBase.sol


pragma solidity =0.6.11;

interface IOSWAP_FactoryBase is IOSWAP_PausableFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint newSize);

    function pairCreator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// File contracts/range/interfaces/IOSWAP_RangeFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_RangeFactory is IOSWAP_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);

    function oracleFactory() external view returns (address);
    function rangeLiquidityProvider() external view returns (address);

    function getCreateAddresses() external view returns (address _governance, address _rangeLiquidityProvider, address _oracleFactory);
    function tradeFee() external view returns (uint256);
    function stakeAmount(uint256) external view returns (uint256);
    function liquidityProviderShare(uint256) external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function setRangeLiquidityProvider(address _rangeLiquidityProvider) external;

    function setTradeFee(uint256) external;
    function setLiquidityProviderShare(uint256[] calldata, uint256[] calldata) external;
    function getAllLiquidityProviderShare() external view returns (uint256[] memory _stakeAmount, uint256[] memory _liquidityProviderShare);
    function getLiquidityProviderShare(uint256 stake) external view returns (uint256 _liquidityProviderShare);
    function setProtocolFeeTo(address) external;

    function checkAndGetSwapParams() external view returns (uint256 _tradeFee);
}


// File contracts/oracle/interfaces/IOSWAP_OracleFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleFactory is IOSWAP_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event OracleAdded(address indexed token0, address indexed token1, address oracle);
    event OracleScores(address indexed oracle, uint256 score);
    event Whitelisted(address indexed who, bool allow);

    function oracleLiquidityProvider() external view returns (address);

    function tradeFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function feePerDelegator() external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function securityScoreOracle() external view returns (address);
    function minOracleScore() external view returns (uint256);

    function oracles(address token0, address token1) external view returns (address oracle);
    function minLotSize(address token) external view returns (uint256);
    function isOracle(address) external view returns (bool);
    function oracleScores(address oracle) external view returns (uint256);

    function whitelisted(uint256) external view returns (address);
    function whitelistedInv(address) external view returns (uint256);
    function isWhitelisted(address) external returns (bool);

    function setOracleLiquidityProvider(address _oracleRouter, address _oracleLiquidityProvider) external;

    function setOracle(address from, address to, address oracle) external;
    function addOldOracleToNewPair(address from, address to, address oracle) external;
    function setTradeFee(uint256) external;
    function setProtocolFee(uint256) external;
    function setFeePerDelegator(uint256 _feePerDelegator) external;
    function setProtocolFeeTo(address) external;
    function setSecurityScoreOracle(address, uint256) external;
    function setMinLotSize(address token, uint256 _minLotSize) external;

    function updateOracleScore(address oracle) external;

    function whitelistedLength() external view returns (uint256);
    function allWhiteListed() external view returns(address[] memory list, bool[] memory allowed);
    function setWhiteList(address _who, bool _allow) external;

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view returns (address oracle, uint256 _tradeFee, uint256 _protocolFee);
    function checkAndGetOracle(address tokenA, address tokenB) external view returns (address oracle);
}


// File contracts/gov/interfaces/IOAXDEX_Governance.sol


pragma solidity =0.6.11;

interface IOAXDEX_Governance {

    struct NewStake {
        uint256 amount;
        uint256 timestamp;
    }
    struct VotingConfig {
        uint256 minExeDelay;
        uint256 minVoteDuration;
        uint256 maxVoteDuration;
        uint256 minOaxTokenToCreateVote;
        uint256 minQuorum;
    }

    event ParamSet(bytes32 indexed name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event AddVotingConfig(bytes32 name, 
        uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    event SetVotingConfig(bytes32 indexed configName, bytes32 indexed paramName, uint256 minExeDelay);

    event Stake(address indexed who, uint256 value);
    event Unstake(address indexed who, uint256 value);

    event NewVote(address indexed vote);
    event NewPoll(address indexed poll);
    event Vote(address indexed account, address indexed vote, uint256 option);
    event Poll(address indexed account, address indexed poll, uint256 option);
    event Executed(address indexed vote);
    event Veto(address indexed vote);

    function votingConfigs(bytes32) external view returns (uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    function votingConfigProfiles(uint256) external view returns (bytes32);

    function oaxToken() external view returns (address);
    function votingToken() external view returns (address);
    function freezedStake(address) external view returns (uint256 amount, uint256 timestamp);
    function stakeOf(address) external view returns (uint256);
    function totalStake() external view returns (uint256);

    function votingRegister() external view returns (address);
    function votingExecutor(uint256) external view returns (address);
    function votingExecutorInv(address) external view returns (uint256);
    function isVotingExecutor(address) external view returns (bool);
    function admin() external view returns (address);
    function minStakePeriod() external view returns (uint256);

    function voteCount() external view returns (uint256);
    function votingIdx(address) external view returns (uint256);
    function votings(uint256) external view returns (address);


	function votingConfigProfilesLength() external view returns(uint256);
	function getVotingConfigProfiles(uint256 start, uint256 length) external view returns(bytes32[] memory profiles);
    function getVotingParams(bytes32) external view returns (uint256 _minExeDelay, uint256 _minVoteDuration, uint256 _maxVoteDuration, uint256 _minOaxTokenToCreateVote, uint256 _minQuorum);

    function setVotingRegister(address _votingRegister) external;
    function votingExecutorLength() external view returns (uint256);
    function initVotingExecutor(address[] calldata _setVotingExecutor) external;
    function setVotingExecutor(address _setVotingExecutor, bool _bool) external;
    function initAdmin(address _admin) external;
    function setAdmin(address _admin) external;
    function addVotingConfig(bytes32 name, uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) external;
    function setVotingConfig(bytes32 configName, bytes32 paramName, uint256 paramValue) external;
    function setMinStakePeriod(uint _minStakePeriod) external;

    function stake(uint256 value) external;
    function unlockStake() external;
    function unstake(uint256 value) external;
    function allVotings() external view returns (address[] memory);
    function getVotingCount() external view returns (uint256);
    function getVotings(uint256 start, uint256 count) external view returns (address[] memory _votings);

    function isVotingContract(address votingContract) external view returns (bool);

    function getNewVoteId() external returns (uint256);
    function newVote(address vote, bool isExecutiveVote) external;
    function voted(bool poll, address account, uint256 option) external;
    function executed() external;
    function veto(address voting) external;
    function closeVote(address vote) external;
}


// File contracts/oracle/interfaces/IOSWAP_OracleAdaptor.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleAdaptor {
    function isSupported(address from, address to) external view returns (bool supported);
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) external view returns (uint256 numerator, uint256 denominator);
    function getLatestPrice(address from, address to, bytes calldata payload) external view returns (uint256 price);
    function decimals() external view returns (uint8);
}


// File contracts/commons/OSWAP_PausablePair.sol


pragma solidity =0.6.11;

contract OSWAP_PausablePair is IOSWAP_PausablePair {
    bool public override isLive;
    address public override immutable factory;

    constructor() public {
        factory = msg.sender;
        isLive = true;
    }
    function setLive(bool _isLive) external override {
        require(msg.sender == factory, 'FORBIDDEN');
        isLive = _isLive;
    }
}


// File contracts/range/OSWAP_RangePair.sol


pragma solidity =0.6.11;









contract OSWAP_RangePair is IOSWAP_RangePair, OSWAP_PausablePair {
    using SafeMath for uint256;

    uint256 constant FEE_BASE = 10 ** 5;
    uint256 constant WEI = 10**18;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyEndUser() {
        require((tx.origin == msg.sender && !Address.isContract(msg.sender)) || IOSWAP_OracleFactory(oracleFactory).isWhitelisted(msg.sender), "Not from user or whitelisted");
        _;
    }

    uint256 public override counter;
    mapping (bool => Offer[]) public override offers;
    mapping (address => uint256) public override providerOfferIndex;
    mapping (address => uint256) public override providerStaking;

    address public override immutable oracleFactory;
    address public override immutable governance;
    address public override immutable rangeLiquidityProvider;
    address public override immutable govToken;
    address public override token0;
    address public override token1;
    bool public override scaleDirection;
    uint256 public override scaler;

    uint256 public override lastGovBalance;
    uint256 public override lastToken0Balance;
    uint256 public override lastToken1Balance;
    uint256 public override protocolFeeBalance0;
    uint256 public override protocolFeeBalance1;
    uint256 public override stakeBalance;

    constructor() public {
        (address _governance, address _rangeLiquidityProvider, address _oracleFactory) = IOSWAP_RangeFactory(msg.sender).getCreateAddresses();
        governance = _governance;
        govToken = IOAXDEX_Governance(_governance).oaxToken();
        rangeLiquidityProvider = _rangeLiquidityProvider;
        oracleFactory = _oracleFactory;

        offers[true].push(Offer({
            provider: address(this),
            amount: 0,
            reserve: 0,
            lowerLimit: 0,
            upperLimit: 0,
            startDate: 0,
            expire: 0,
            privateReplenish: false
        }));
        offers[false].push(Offer({
            provider: address(this),
            amount: 0,
            reserve: 0,
            lowerLimit: 0,
            upperLimit: 0,
            startDate: 0,
            expire: 0,
            privateReplenish: false
        }));
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, 'FORBIDDEN'); // sufficient check

        token0 = _token0;
        token1 = _token1;
        require(token0 < token1, "Invalid token pair order");

        address oracle = IOSWAP_OracleFactory(oracleFactory).oracles(token0, token1);
        require(oracle != address(0), "No oracle found");

        uint8 token0Decimals = IERC20(token0).decimals();
        uint8 token1Decimals = IERC20(token1).decimals();
        if (token0Decimals == token1Decimals) {
            scaler = 1;
        } else {
            scaleDirection = token1Decimals > token0Decimals;
            scaler = 10 ** uint256(scaleDirection ? (token1Decimals - token0Decimals) : (token0Decimals - token1Decimals));
        }
    }

    function getOffers(bool direction, uint256 start, uint256 end) external override view returns (address[] memory provider, uint256[] memory amountAndReserve, uint256[] memory lowerLimitAndUpperLimit, uint256[] memory startDateAndExpire, bool[] memory privateReplenish) {
        if (start <= counter) {
            if (end > counter) 
                end = counter;
            uint256 length = end.add(1).sub(start);
            provider = new address[](length);
            amountAndReserve = new uint256[](length * 2);
            lowerLimitAndUpperLimit = new uint256[](length * 2);
            startDateAndExpire = new uint256[](length * 2);
            privateReplenish = new bool[](length);

            for (uint256 i = 0; i < length ; i++) {
                uint256 j = i.add(length);
                Offer storage offer = offers[direction][i.add(start)];
                provider[i] = offer.provider;
                amountAndReserve[i] = offer.amount;
                amountAndReserve[j] = offer.reserve;
                lowerLimitAndUpperLimit[i] = offer.lowerLimit;
                lowerLimitAndUpperLimit[j] = offer.upperLimit;
                startDateAndExpire[i] = offer.startDate;
                startDateAndExpire[j] = offer.expire;
                privateReplenish[i] = offer.privateReplenish;
            }
        } else {
            provider = new address[](0);
            amountAndReserve = lowerLimitAndUpperLimit = startDateAndExpire = new uint256[](0);
            privateReplenish  = new bool[](0);
        }
    }

    function getLastBalances() external view override returns (uint256, uint256) {
        return (
            lastToken0Balance,
            lastToken1Balance
        );
    }
    function getBalances() public view override returns (uint256, uint256, uint256) {
        return (
            IERC20(govToken).balanceOf(address(this)),
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this))
        );
    }

    function getLatestPrice(bool direction, bytes calldata payload) public view override returns (uint256) {
        address oracle = IOSWAP_OracleFactory(oracleFactory).checkAndGetOracle(token0, token1);
        (address tokenA, address tokenB) = direction ? (token0, token1) : (token1, token0);
        return IOSWAP_OracleAdaptor(oracle).getLatestPrice(tokenA, tokenB, payload);
    }
    function _getSwappedAmount(bool direction, uint256 amountIn, bytes calldata data) internal view returns (uint256 amountOut, uint256 price, uint256 tradeFeeCollected, uint256 tradeFee) {
        address oracle = IOSWAP_OracleFactory(oracleFactory).checkAndGetOracle(token0, token1);
        tradeFee = IOSWAP_RangeFactory(factory).checkAndGetSwapParams();
        tradeFeeCollected = amountIn.mul(tradeFee).div(FEE_BASE);
        amountIn = amountIn.sub(tradeFeeCollected);
        (uint256 numerator, uint256 denominator) = IOSWAP_OracleAdaptor(oracle).getRatio(direction ? token0 : token1, direction ? token1 : token0, amountIn, 0, data);
        amountOut = amountIn.mul(numerator);
        if (scaler > 1)
            amountOut = (direction == scaleDirection) ? amountOut.mul(scaler) : amountOut.div(scaler);
        amountOut = amountOut.div(denominator);
        price = numerator.mul(WEI).div(denominator);
    }
    function getAmountOut(address tokenIn, uint256 amountIn, bytes calldata data) external view override returns (uint256 amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        (amountOut,,,) = _getSwappedAmount(tokenIn == token0, amountIn, data);
    }
    function getAmountIn(address tokenOut, uint256 amountOut, bytes calldata data) external view override returns (uint256 amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        address oracle = IOSWAP_OracleFactory(oracleFactory).checkAndGetOracle(token0, token1);
        uint256 tradeFee = IOSWAP_RangeFactory(factory).checkAndGetSwapParams();
        bool direction = tokenOut == token1;
        address tokenIn = direction ? token0 : token1;
        (uint256 numerator, uint256 denominator) = IOSWAP_OracleAdaptor(oracle).getRatio(tokenIn, tokenOut, 0, amountOut, data);
        amountIn = amountOut.mul(denominator);
        if (scaler > 1)
            amountIn = (direction != scaleDirection) ? amountIn.mul(scaler) : amountIn.div(scaler);
        amountIn = amountIn.div(numerator).add(1);
        amountIn = amountIn.mul(FEE_BASE).div(FEE_BASE.sub(tradeFee)).add(1);
    }

    function getProviderOffer(address provider, bool direction) external view override returns (uint256 index, uint256 staked, uint256 amount, uint256 reserve, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire, bool privateReplenish) {
        index = providerOfferIndex[provider];
        Offer storage offer = offers[direction][index];
        return (index, providerStaking[provider], offer.amount, offer.reserve, offer.lowerLimit, offer.upperLimit, offer.startDate, offer.expire, offer.privateReplenish);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function addLiquidity(address provider, bool direction, uint256 staked, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire) external override lock returns (uint256 index) {
        require(IOSWAP_RangeFactory(factory).isLive(), 'GLOBALLY PAUSED');
        require(msg.sender == rangeLiquidityProvider || msg.sender == provider, "Not from router or owner");
        require(isLive, "PAUSED");
        require(provider != address(0), "Null address");
        require(lowerLimit <= upperLimit, "Invalid limit");
        require(expire >= startDate, "Already expired");
        require(expire >= block.timestamp, "Already expired");
        uint256 amountIn;
        {
        (uint256 newGovBalance, uint256 newToken0Balance, uint256 newToken1Balance) = getBalances();
        require(newGovBalance.sub(lastGovBalance) >= staked, "Invalid feeIn");
        stakeBalance = stakeBalance.add(staked);
        if (direction) {
            amountIn = newToken1Balance.sub(lastToken1Balance);
            if (govToken == token1)
                amountIn = amountIn.sub(staked);
        } else {
            amountIn = newToken0Balance.sub(lastToken0Balance);
            if (govToken == token0)
                amountIn = amountIn.sub(staked);
        }

        lastGovBalance = newGovBalance;
        lastToken0Balance = newToken0Balance;
        lastToken1Balance = newToken1Balance;
        }

        providerStaking[provider] = providerStaking[provider].add(staked);
        uint256 newStakeBalance; uint256 newAmountBalance;
        newStakeBalance = providerStaking[provider];
        index = providerOfferIndex[provider];
        if (index > 0) {
            Offer storage offer = offers[direction][index];
            newAmountBalance = offer.amount = offer.amount.add(amountIn);
            offer.lowerLimit = lowerLimit;
            offer.upperLimit = upperLimit;
            offer.startDate = startDate;
            offer.expire = expire;
        } else {
            index = (++counter);
            providerOfferIndex[provider] = index;
            require(amountIn > 0, "No amount in");

            offers[direction].push(Offer({
                provider: provider,
                amount: amountIn,
                reserve: 0,
                lowerLimit: lowerLimit,
                upperLimit: upperLimit,
                startDate: startDate,
                expire: expire,
                privateReplenish: true
            }));
            offers[!direction].push(Offer({
                provider: provider,
                amount: 0,
                reserve: 0,
                lowerLimit: 0,
                upperLimit: 0,
                startDate: 0,
                expire: 0,
                privateReplenish: true
            }));

            newAmountBalance = amountIn;

            emit NewProvider(provider, index);
        }

        emit AddLiquidity(provider, direction, staked, amountIn, newStakeBalance, newAmountBalance, lowerLimit, upperLimit, startDate, expire);
    }
    function replenish(address provider, bool direction, uint256 amountIn) external override lock {
        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider not found");

        // move funds from internal wallet
        Offer storage offer = offers[direction][index];
        require(!offer.privateReplenish || provider == msg.sender, "Not from provider");

        offer.amount = offer.amount.add(amountIn);
        offer.reserve = offer.reserve.sub(amountIn);

        emit Replenish(provider, direction, amountIn, offer.amount, offer.reserve);
    }
    function updateProviderOffer(address provider, bool direction, uint256 replenishAmount, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire, bool privateReplenish) external override {
        require(msg.sender == rangeLiquidityProvider || msg.sender == provider, "Not from router or owner");
        require(IOSWAP_RangeFactory(factory).isLive(), 'GLOBALLY PAUSED');
        require(isLive, "PAUSED");
        require(lowerLimit <= upperLimit, "Invalid limit");
        require(expire >= startDate, "Already expired");
        require(expire > block.timestamp, "Already expired");
        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider liquidity not found");

        Offer storage offer = offers[direction][index];
        offer.amount = offer.amount.add(replenishAmount);
        offer.reserve = offer.reserve.sub(replenishAmount);
        offer.lowerLimit = lowerLimit;
        offer.upperLimit = upperLimit;
        offer.startDate = startDate;
        offer.expire = expire;
        offer.privateReplenish = privateReplenish;

        emit UpdateProviderOffer(msg.sender, direction, replenishAmount, offer.amount, offer.reserve, lowerLimit, upperLimit, startDate, expire, privateReplenish);
    }
    function removeLiquidity(address provider, bool direction, uint256 unstake, uint256 amountOut, uint256 reserveOut, uint256 lowerLimit, uint256 upperLimit, uint256 startDate, uint256 expire) external override lock {
        require(msg.sender == rangeLiquidityProvider || msg.sender == provider, "Not from router or owner");
        require(expire >= startDate, "Already expired");
        require(expire > block.timestamp, "Already expired");

        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider liquidity not found");

        if (unstake > 0) {
            providerStaking[provider] = providerStaking[provider].sub(unstake);
            stakeBalance = stakeBalance.sub(unstake);
            _safeTransfer(govToken, msg.sender, unstake); // optimistically transfer tokens
        }
        uint256 newStakeBalance = providerStaking[provider];

        Offer storage offer = offers[direction][index]; 
        offer.amount = offer.amount.sub(amountOut);
        offer.reserve = offer.reserve.sub(reserveOut);
        offer.lowerLimit = lowerLimit;
        offer.upperLimit = upperLimit;
        offer.startDate = startDate;
        offer.expire = expire;

        if (amountOut > 0 || reserveOut > 0)
            _safeTransfer(direction ? token1 : token0, msg.sender, amountOut.add(reserveOut)); // optimistically transfer tokens

        emit RemoveLiquidity(provider, direction, unstake, amountOut, reserveOut, newStakeBalance, offer.amount, offer.reserve, lowerLimit, upperLimit, startDate, expire);

        _sync();
    }
    function removeAllLiquidity(address provider) external override lock returns (uint256 amount0, uint256 amount1, uint256 staked) {
        require(msg.sender == rangeLiquidityProvider || msg.sender == provider, "Not from router or owner");

        uint256 reserve0;
        (amount0, reserve0) = _removeAllLiquidityOneSide(provider, false);
        amount0 = amount0.add(reserve0);

        uint256 reserve1;
        (amount1, reserve1) = _removeAllLiquidityOneSide(provider, true);
        amount1 = amount1.add(reserve1);

        staked = providerStaking[provider];
        providerStaking[provider] = 0;
        if (staked > 0) {
            stakeBalance = stakeBalance.sub(staked);
            _safeTransfer(govToken, msg.sender, staked);
        }

        emit RemoveAllLiquidity(provider, staked, amount0, amount1);

        _sync();
    }
    function _removeAllLiquidityOneSide(address provider, bool direction) internal returns (uint256 amount, uint256 reserve) {
        uint256 index = providerOfferIndex[provider];
        require(index > 0, "Provider liquidity not found");

        Offer storage offer = offers[direction][index];
        amount = offer.amount;
        reserve = offer.reserve;
        offer.amount = 0;
        offer.reserve = 0;

        _safeTransfer(direction ? token1 : token0, msg.sender, amount.add(reserve));
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external override lock onlyEndUser {
        require(isLive, "PAUSED");
        uint256 amount0In = IERC20(token0).balanceOf(address(this)).sub(lastToken0Balance);
        uint256 amount1In = IERC20(token1).balanceOf(address(this)).sub(lastToken1Balance);

        uint256 amountOut;
        uint256 protocolFeeCollected;
        if (amount0Out == 0 && amount1Out != 0){
            (amountOut, protocolFeeCollected) = _swap(to, true, amount0In, data);
            require(amountOut >= amount1Out, "INSUFFICIENT_AMOUNT");
            _safeTransfer(token1, to, amountOut); // optimistically transfer tokens
            protocolFeeBalance0 = protocolFeeBalance0.add(protocolFeeCollected);
        } else if (amount0Out != 0 && amount1Out == 0){
            (amountOut, protocolFeeCollected) = _swap(to, false, amount1In, data);
            require(amountOut >= amount0Out, "INSUFFICIENT_AMOUNT");
            _safeTransfer(token0, to, amountOut); // optimistically transfer tokens
            protocolFeeBalance1 = protocolFeeBalance1.add(protocolFeeCollected);
        } else {
            revert("Not supported");
        }

        _sync();
    }
    function _swap(address to, bool direction, uint256 amountIn, bytes calldata data) internal returns (uint256 amountOut, uint256 protocolFeeCollected) {
        uint256 price;
        uint256 amountInMinusProtocolFee;
        uint256 tradeFeeCollected;
        uint256[] memory list;
        {
        uint256 dataRead;
        (list, dataRead) = _getOfferList(0x84);
        (amountOut, price, tradeFeeCollected, /*tradeFee*/) = _getSwappedAmount(direction, amountIn, data[dataRead:]);
        }
        protocolFeeCollected = tradeFeeCollected;
        amountInMinusProtocolFee = amountIn.sub(tradeFeeCollected);

        uint256 remainOut = amountOut;
        {
        bool _direction = direction;
        uint256 index = 0;
        while (remainOut > 0 && index < list.length) {
            require(list[index] <= counter, "Offer not exist");
            Offer storage offer = offers[_direction][list[index]];
            if (((offer.lowerLimit <= price && price <= offer.upperLimit)||
                 (offer.lowerLimit == 0 && offer.upperLimit == 0)) && 
                block.timestamp >= offer.startDate &&  
                block.timestamp <= offer.expire)
            {
                uint256 providerShare;
                uint256 amount = offer.amount;
                uint256 newAmountBalance;

                if (remainOut >= amount) {
                    // amount requested cover whole entry, clear entry
                    remainOut = remainOut.sub(amount);
                    newAmountBalance = offer.amount = 0;
                } else {
                    amount = remainOut;
                    newAmountBalance = offer.amount = offer.amount.sub(remainOut);
                    remainOut = 0;
                }
                providerShare = IOSWAP_RangeFactory(factory).getLiquidityProviderShare(providerStaking[offer.provider]);
                providerShare = tradeFeeCollected.mul(amount).mul(providerShare).div(amountOut.mul(FEE_BASE));
                protocolFeeCollected = protocolFeeCollected.sub(providerShare);
                providerShare = amountInMinusProtocolFee.mul(amount).div(amountOut).add(providerShare);
                offer = offers[!_direction][list[index]];
                offer.reserve = offer.reserve.add(providerShare);
                emit SwappedOneProvider(offer.provider, _direction, amount, providerShare, newAmountBalance, offer.reserve);
            }
            index++;
        }
        }
        require(remainOut == 0, "Amount exceeds available fund");
        emit Swap(to, direction, price, amountIn, amountOut, tradeFeeCollected, protocolFeeCollected);
    }

    function _getOfferList(uint256 offset) internal pure returns(uint256[] memory list, uint256 dataRead) {
        require(msg.data.length >= offset.add(0x40), "Invalid offer list");
        assembly {
            let count := calldataload(add(offset, 0x20))
            let size := mul(count, 0x20)

            if lt(calldatasize(), add(add(offset, 0x40), size)) { // 0x84 (offset) + 0x20 (bytes_size_header) + 0x20 (count) + count*0x20 (list_size)
                revert(0, 0)
            }
            let mark := mload(0x40)
            mstore(0x40, add(mark, add(size, 0x20))) // malloc
            mstore(mark, count) // array length
            calldatacopy(add(mark, 0x20), add(offset, 0x40), size) // copy data to list
            list := mark
            dataRead := add(size, 0x20)
        }
    }

    function sync() external override lock {
        _sync();
    }
    function _sync() internal {
        lastGovBalance = IERC20(govToken).balanceOf(address(this));
        lastToken0Balance = IERC20(token0).balanceOf(address(this));
        lastToken1Balance = IERC20(token1).balanceOf(address(this));
    }

    function redeemProtocolFee() external override lock {
        address protocolFeeTo = IOSWAP_RangeFactory(factory).protocolFeeTo();
        _safeTransfer(token0, protocolFeeTo, protocolFeeBalance0); // optimistically transfer tokens
        _safeTransfer(token1, protocolFeeTo, protocolFeeBalance1); // optimistically transfer tokens
        protocolFeeBalance0 = 0;
        protocolFeeBalance1 = 0;
        _sync();
    }
}


// File contracts/libraries/TransferHelper.sol


pragma solidity =0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/interfaces/IWETH.sol


pragma solidity =0.6.11;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/range/OSWAP_RangeLiquidityProvider.sol


pragma solidity =0.6.11;








contract OSWAP_RangeLiquidityProvider is IOSWAP_RangeLiquidityProvider {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable override govToken;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        govToken = IOAXDEX_Governance(IOSWAP_RangeFactory(_factory).governance()).oaxToken();
    }
    
    receive() external payable {
        require(msg.sender == WETH, 'Transfer failed'); // only accept ETH via fallback from the WETH contract
    }


    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool addingTokenA,
        uint256 staked,
        uint256 amountIn,
        uint256 lowerLimit, 
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 index) {
        // create the pair if it doesn't exist yet
        if (IOSWAP_RangeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IOSWAP_RangeFactory(factory).createPair(tokenA, tokenB);
        }
        address pair = pairFor(tokenA, tokenB);

        if (staked > 0)
            TransferHelper.safeTransferFrom(govToken, msg.sender, pair, staked);
        if (amountIn > 0)
            TransferHelper.safeTransferFrom(addingTokenA ? tokenA : tokenB, msg.sender, pair, amountIn);

        bool direction = (tokenA < tokenB) ? !addingTokenA : addingTokenA;
        index = IOSWAP_RangePair(pair).addLiquidity(msg.sender, direction, staked, lowerLimit, upperLimit, startDate, expire);
    }
    function addLiquidityETH(
        address tokenA,
        bool addingTokenA,
        uint256 staked,
        uint256 amountAIn,
        uint256 lowerLimit, 
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) external virtual override payable ensure(deadline) returns (uint256 index) {
        // create the pair if it doesn't exist yet
        if (IOSWAP_RangeFactory(factory).getPair(tokenA, WETH) == address(0)) {
            IOSWAP_RangeFactory(factory).createPair(tokenA, WETH);
        }
        uint256 ETHIn = msg.value;
        address pair = pairFor(tokenA, WETH);

        if (staked > 0)
            TransferHelper.safeTransferFrom(govToken, msg.sender, pair, staked);

        if (addingTokenA) {
            if (amountAIn > 0)
                TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountAIn);
        } else {
            IWETH(WETH).deposit{value: ETHIn}();
            require(IWETH(WETH).transfer(pair, ETHIn), 'Transfer failed');
        }
        bool direction = (tokenA < WETH) ? !addingTokenA : addingTokenA;
        index = IOSWAP_RangePair(pair).addLiquidity(msg.sender, direction, staked, lowerLimit, upperLimit, startDate, expire);
    }

    function updateProviderOffer(
        address tokenA, 
        address tokenB, 
        uint256 replenishAmount, 
        uint256 lowerLimit, 
        uint256 upperLimit, 
        uint256 startDate,
        uint256 expire, 
        bool privateReplenish, 
        uint256 deadline
    ) external override ensure(deadline) {
        address pair = pairFor(tokenA, tokenB);
        bool direction = (tokenA < tokenB);
        IOSWAP_RangePair(pair).updateProviderOffer(msg.sender, direction, replenishAmount, lowerLimit, upperLimit, startDate, expire, privateReplenish);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool removingTokenA,
        address to,
        uint256 unstake,
        uint256 amountOut,
        uint256 reserveOut,
        uint256 lowerLimit, 
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) public virtual override ensure(deadline) {
        address pair = pairFor(tokenA, tokenB);
        bool direction = (tokenA < tokenB) ? !removingTokenA : removingTokenA;
        IOSWAP_RangePair(pair).removeLiquidity(msg.sender, direction, unstake, amountOut, reserveOut, lowerLimit, upperLimit, startDate, expire);


        if (unstake > 0)
            TransferHelper.safeTransfer(govToken, to, unstake);        
        if (amountOut > 0 || reserveOut > 0) {
            address token = removingTokenA ? tokenA : tokenB;
            TransferHelper.safeTransfer(token, to, amountOut.add(reserveOut));
        }
    }
    function removeLiquidityETH(
        address tokenA,
        bool removingTokenA,
        address to,
        uint256 unstake,
        uint256 amountOut,
        uint256 reserveOut,
        uint256 lowerLimit, 
        uint256 upperLimit,
        uint256 startDate,
        uint256 expire,
        uint256 deadline
    ) public virtual override ensure(deadline) {
        address pair = pairFor(tokenA, WETH);
        bool direction = (tokenA < WETH) ? !removingTokenA : removingTokenA;
        IOSWAP_RangePair(pair).removeLiquidity(msg.sender, direction, unstake, amountOut, reserveOut, lowerLimit, upperLimit, startDate, expire);

        if (unstake > 0)
            TransferHelper.safeTransfer(govToken, to, unstake);

        amountOut = amountOut.add(reserveOut);
        if (amountOut > 0) {
            if (removingTokenA) {
                TransferHelper.safeTransfer(tokenA, to, amountOut);
            } else {
                IWETH(WETH).withdraw(amountOut);
                TransferHelper.safeTransferETH(to, amountOut);
            }
        }
    }
    function removeAllLiquidity(
        address tokenA,
        address tokenB,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(tokenA, tokenB);
        (uint256 amount0, uint256 amount1, uint256 staked) = IOSWAP_RangePair(pair).removeAllLiquidity(msg.sender);
        (amountA, amountB) = (tokenA < tokenB) ? (amount0, amount1) : (amount1, amount0);
        TransferHelper.safeTransfer(tokenA, to, amountA);
        TransferHelper.safeTransfer(tokenB, to, amountB);
        TransferHelper.safeTransfer(govToken, to, staked);
    }
    function removeAllLiquidityETH(
        address tokenA,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        address pair = pairFor(tokenA, WETH);
        (uint256 amount0, uint256 amount1, uint256 staked) = IOSWAP_RangePair(pair).removeAllLiquidity(msg.sender);
        (amountToken, amountETH) = (tokenA < WETH) ? (amount0, amount1) : (amount1, amount0);
        TransferHelper.safeTransfer(tokenA, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
        TransferHelper.safeTransfer(govToken, to, staked);
    }

    // **** LIBRARY FUNCTIONS ****
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint256(keccak256(abi.encodePacked(
                hex'ff',    
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                /*range*/hex'78dc6857442275f34e463f5001ada900e5a91ee4b7a78bf96df0472429dae422' // range init code hash
            ))));
    }
}