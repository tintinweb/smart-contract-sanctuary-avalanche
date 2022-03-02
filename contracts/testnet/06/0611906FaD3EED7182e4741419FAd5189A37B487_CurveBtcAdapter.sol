// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICurveAPoolForUseOnPolygon} from "../../../interfaces/curve/ICurveAPoolForUseOnPolygon.sol";
import {ICurveLpToken} from "../../../interfaces/curve/ICurveLpToken.sol";
import {CurveBasic} from "./CurveBasic.sol";

contract CurveBtcAdapter is CurveBasic {
    using SafeERC20 for IERC20;

    constructor(address _adapterManager)
        CurveBasic(_adapterManager, "CurveBtcSwap")
    {}

    event CurveBtcExchangeEvent(
        address tokenFrom,
        address tokenTo,
        uint256 amountFrom,
        uint256 amountTo,
        address owner
    );

    event CurveBtcAddLiquidityEvent(
        address lpAddress,
        address[2] tokenAddresses,
        uint256[2] addAmounts,
        uint256 lpAmount,
        address owner
    );
    event CurveBtcRemoveLiquidityEvent(
        address lpAddress,
        uint256 lpRemove,
        address[2] tokenAddresses,
        uint256[2] tokenAmounts,
        address owner
    );

    function exchange(bytes calldata encodedData) external onlyAdapterManager {
        /// @param addresses addresses of [token from, token to, proxy, router]
        /// @param fromNumber 0 for avwbtc; 1 for renbtc.e
        /// @param toNumber 0 for avwbtc; 1 for renbtc.e
        /// @param dx amount to exchange
        /// @param min_dy min amount to be exchanged out
        (
            address[] memory addresses,
            int128 fromNumber,
            int128 toNumber,
            uint256 dx,
            uint256 min_dy
        ) = abi.decode(
                encodedData,
                (address[], int128, int128, uint256, uint256)
            );
        pullAndApprove(addresses[0], addresses[2], addresses[3], dx);
        ICurveAPoolForUseOnPolygon router = ICurveAPoolForUseOnPolygon(
            addresses[3]
        );
        uint256 giveBack = router.exchange(fromNumber, toNumber, dx, min_dy);
        IERC20(addresses[1]).safeTransfer(addresses[2], giveBack);

        emit CurveBtcExchangeEvent(
            addresses[0],
            addresses[1],
            dx,
            giveBack,
            addresses[2]
        );
    }

    function exchangeUnderlying(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        /// @param addresses addresses of [token from, token to, proxy, router]
        /// @param fromNumber 0 for wbtc.e; 1 for renbtc.e
        /// @param toNumber 0 for wbtc.e; 1 for renbtc.e
        /// @param dx amount to exchange
        /// @param min_dy min amount to be exchanged out
        (
            address[] memory addresses,
            int128 fromNumber,
            int128 toNumber,
            uint256 dx,
            uint256 min_dy
        ) = abi.decode(
                encodedData,
                (address[], int128, int128, uint256, uint256)
            );
        pullAndApprove(addresses[0], addresses[2], addresses[3], dx);
        ICurveAPoolForUseOnPolygon router = ICurveAPoolForUseOnPolygon(
            addresses[3]
        );
        uint256 giveBack = router.exchange_underlying(
            fromNumber,
            toNumber,
            dx,
            min_dy
        );
        IERC20(addresses[1]).safeTransfer(addresses[2], giveBack);

        emit CurveBtcExchangeEvent(
            addresses[0],
            addresses[1],
            dx,
            giveBack,
            addresses[2]
        );
    }

    function addLiquidity(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        /// @param addresses addresses of [wbtc.e(or avwbtc), renbtc.e, lp, proxy, router]
        /// @param amountsIn the amounts to add, in the order of wbtc.e(or avwbtc), renbtc.e
        /// @param minMintAmount the minimum lp token amount to be minted and returned to the user
        /// @param useUnderlying true: use wbtc.e; false: use avwbtc
        (
            address[] memory addresses,
            uint256[2] memory amountsIn,
            uint256 minMintAmount,
            bool useUnderlying
        ) = abi.decode(encodedData, (address[], uint256[2], uint256, bool));

        pullAndApprove(addresses[0], addresses[3], addresses[4], amountsIn[0]);
        pullAndApprove(addresses[1], addresses[3], addresses[4], amountsIn[1]);

        ICurveAPoolForUseOnPolygon router = ICurveAPoolForUseOnPolygon(
            addresses[4]
        );
        uint256 giveBack = router.add_liquidity(
            amountsIn,
            minMintAmount,
            useUnderlying
        );
        ICurveLpToken lp = ICurveLpToken(addresses[2]);
        lp.transfer(addresses[3], giveBack);
        emit CurveBtcAddLiquidityEvent(
            addresses[2],
            [addresses[0], addresses[1]],
            amountsIn,
            giveBack,
            addresses[3]
        );
    }

    function removeLiquidity(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        /// @param addresses addresses of [wbtc.e(or avwbtc), renbtc.e, lp, proxy, router]
        /// @param removeAmount amount of the lp token to remove liquidity
        /// @param minAmounts the minimum amounts of the (underlying) tokens to return to the user
        /// @param useUnderlying true: use wbtc.e; false: use avwbtc
        (
            address[] memory addresses,
            uint256 removeAmount,
            uint256[2] memory minAmounts,
            bool useUnderlying
        ) = abi.decode(encodedData, (address[], uint256, uint256[2], bool));
        ICurveAPoolForUseOnPolygon router = ICurveAPoolForUseOnPolygon(
            addresses[4]
        );
        pullAndApprove(addresses[2], addresses[3], addresses[4], removeAmount);
        uint256[2] memory giveBack = router.remove_liquidity(
            removeAmount,
            minAmounts,
            useUnderlying
        );
        IERC20(addresses[0]).safeTransfer(addresses[3], giveBack[0]);
        IERC20(addresses[1]).safeTransfer(addresses[3], giveBack[1]);
        emit CurveBtcRemoveLiquidityEvent(
            addresses[2],
            removeAmount,
            [addresses[0], addresses[1]],
            giveBack,
            addresses[3]
        );
    }

    function removeLiquidityOneCoin(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        /// @param addresses  addresses of [wbtc.e(or avwbtc), renbtc.e, lp, proxy, router]
        /// @param tokenNumber 0 for wbtc.e(or avwbtc); 1 for renbtc.e
        /// @param lpAmount the amount of the lp to remove
        /// @param minAmount the minimum amount to return to the user
        /// @param useUnderlying true: use wbtc.e; false: use avwbtc
        (
            address[] memory addresses,
            int128 tokenNumber,
            uint256 lpAmount,
            uint256 minAmount,
            bool useUnderlying
        ) = abi.decode(
                encodedData,
                (address[], int128, uint256, uint256, bool)
            );
        ICurveAPoolForUseOnPolygon router = ICurveAPoolForUseOnPolygon(
            addresses[4]
        );
        pullAndApprove(addresses[2], addresses[3], addresses[4], lpAmount);
        uint256 giveBack = router.remove_liquidity_one_coin(
            lpAmount,
            tokenNumber,
            minAmount,
            useUnderlying
        );
        IERC20 toToken;
        uint256[2] memory amounts;
        if (tokenNumber == 0) {
            toToken = IERC20(addresses[0]);
            amounts = [giveBack, 0];
        } else if (tokenNumber == 1) {
            toToken = IERC20(addresses[1]);
            amounts = [0, giveBack];
        }
        toToken.safeTransfer(addresses[2], giveBack);

        emit CurveBtcRemoveLiquidityEvent(
            addresses[1],
            lpAmount,
            [addresses[0], addresses[1]],
            amounts,
            addresses[3]
        );
    }
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveAPoolForUseOnPolygon {
    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function dynamic_fee(int128 i, int128 j) external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] memory _min_amounts,
        bool _use_underlying
    ) external returns (uint256[2] memory);

    function remove_liquidity_imbalance(
        uint256[2] memory _amounts,
        uint256 _max_burn_amount
    ) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[2] memory _amounts,
        uint256 _max_burn_amount,
        bool _use_underlying
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function commit_new_fee(
        uint256 new_fee,
        uint256 new_admin_fee,
        uint256 new_offpeg_fee_multiplier
    ) external;

    function apply_new_fee() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function withdraw_admin_fees() external;

    function donate_admin_fees() external;

    function kill_me() external;

    function unkill_me() external;

    function set_aave_referral(uint256 referral_code) external;

    function set_reward_receiver(address _reward_receiver) external;

    function set_admin_fee_receiver(address _admin_fee_receiver) external;

    function coins(uint256 arg0) external view returns (address);

    function underlying_coins(uint256 arg0) external view returns (address);

    function admin_balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function offpeg_fee_multiplier() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function owner() external view returns (address);

    function lp_token() external view returns (address);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function future_offpeg_fee_multiplier() external view returns (uint256);

    function future_owner() external view returns (address);

    function reward_receiver() external view returns (address);

    function admin_fee_receiver() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveLpToken {
    function decimals() external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function increaseAllowance(address _spender, uint256 _added_value)
        external
        returns (bool);

    function decreaseAllowance(address _spender, uint256 _subtracted_value)
        external
        returns (bool);

    function mint(address _to, uint256 _value) external returns (bool);

    function mint_relative(address _to, uint256 frac)
        external
        returns (uint256);

    function burnFrom(address _to, uint256 _value) external returns (bool);

    function set_minter(address _minter) external;

    function set_name(string memory _name, string memory _symbol) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address arg0) external view returns (uint256);

    function allowance(address arg0, address arg1)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);

    function minter() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../../common/Basic.sol";
import "../../base/AdapterBase.sol";
import {ICurveLpToken} from "../../../interfaces/curve/ICurveLpToken.sol";
import {ICurveRewardsOnlyGauge} from "../../../interfaces/curve/ICurveRewardsOnlyGauge.sol";
import {ICurveAtriCrypto} from "../../../interfaces/curve/ICurveAtriCrypto.sol";

/// @dev common part of Curve adapters
abstract contract CurveBasic is AdapterBase, Basic {
    constructor(address _adapterManager, string memory _name)
        AdapterBase(_adapterManager, _name)
    {}

    /// @dev triggered when user deposit some lp token
    /// @param lpToken the address of the lp token to deposit
    /// @param gauge this address is also a token address representing the proof of depositing
    /// @param lpAmount the amount of lp token to deposit
    /// @param gaugeAmount the amount of the farm token giving from the gauge to the user
    /// @param owner user address who own the lp
    event CurveDepositEvent(
        address lpToken,
        address gauge,
        uint256 lpAmount,
        uint256 gaugeAmount,
        address owner
    );

    event CurveWithdrawEvent(
        address lpToken,
        address gauge,
        uint256 lpAmount,
        uint256 gaugeAmount,
        address owner
    );

    event CurveClaimRewardsEvent(
        address lpToken,
        uint256 lpAmount,
        address owner
    );

    function deposit(bytes calldata encodedData) external onlyAdapterManager {
        /// @param addresses  addresses of [lp, proxy, farm]
        /// @param amountDeposit  amount of the lp token to deposit
        (address[] memory addresses, uint256 amountDeposit) = abi.decode(
            encodedData,
            (address[], uint256)
        );
        pullAndApprove(addresses[0], addresses[1], addresses[2], amountDeposit);
        ICurveRewardsOnlyGauge farm = ICurveRewardsOnlyGauge(addresses[2]);
        uint256 gaugeBalanceBefore = farm.balanceOf(address(this));
        farm.deposit(amountDeposit, address(this), false);
        uint256 gaugeBalanceAfter = farm.balanceOf(address(this));
        uint256 gaugeAmount = gaugeBalanceAfter - gaugeBalanceBefore;
        farm.transfer(addresses[1], gaugeAmount);
        emit CurveDepositEvent(
            addresses[0],
            addresses[2],
            amountDeposit,
            gaugeAmount,
            addresses[1]
        );
    }

    function withdraw(bytes calldata encodedData) external onlyAdapterManager {
        /// @param addresses  addresses of [lp, proxy, farm]
        /// @param amountWithdraw  amount of the gauge token to withdraw
        (address[] memory addresses, uint256 amountWithdraw) = abi.decode(
            encodedData,
            (address[], uint256)
        );
        pullAndApprove(
            addresses[2],
            addresses[1],
            addresses[2],
            amountWithdraw
        );
        ICurveLpToken lp = ICurveLpToken(addresses[0]);
        uint256 balanceBefore = lp.balanceOf(address(this));
        ICurveRewardsOnlyGauge farm = ICurveRewardsOnlyGauge(addresses[2]);
        farm.withdraw(amountWithdraw, false);
        uint256 balanceAfter = lp.balanceOf(address(this));
        uint256 lpAmount = balanceAfter - balanceBefore;
        lp.transfer(addresses[1], lpAmount);
        emit CurveDepositEvent(
            addresses[0],
            addresses[2],
            lpAmount,
            amountWithdraw,
            addresses[1]
        );
    }

    function claimRewards(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        /// @param addresses  addresses of [lpAddress, proxy, farm]
        address[] memory addresses = abi.decode(encodedData, (address[]));
        ICurveRewardsOnlyGauge farm = ICurveRewardsOnlyGauge(addresses[2]);
        ICurveLpToken lp = ICurveLpToken(addresses[0]);
        uint256 balanceBefore = lp.balanceOf(addresses[1]);
        // the two params representing msg.sender and receiver
        farm.claim_rewards(address(this), addresses[0]);
        uint256 balanceAfter = lp.balanceOf(addresses[1]);
        uint256 rewardsAmount = balanceAfter - balanceBefore;

        emit CurveClaimRewardsEvent(addresses[0], rewardsAmount, addresses[1]);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Basic {
    using SafeERC20 for IERC20;

    uint256 constant WAD = 10**18;
    /**
     * @dev Return ethereum address
     */
    address internal constant avaxAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped AVAX address
    address internal constant wavaxAddr =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    /// @dev Return call deadline
    uint256 internal constant TIME_INTERVAL = 3600;

    function encodeEvent(string memory eventName, bytes memory eventParam)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(eventName, eventParam);
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (
            _from != address(0) &&
            _from != address(this) &&
            _token != avaxAddr &&
            _amount != 0
        ) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function getBalance(address _tokenAddr, address _acc)
        internal
        view
        returns (uint256)
    {
        if (_tokenAddr == avaxAddr) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "helper::safeTransferAVAX: AVAX transfer failed");
    }

    /// @dev get the token from sender, and approve to the user in one step
    function pullAndApprove(
        address tokenAddress,
        address sender,
        address spender,
        uint256 amount
    ) internal {
        // prevent the token address to be zero address
        IERC20 token = tokenAddress == avaxAddr
            ? IERC20(wavaxAddr)
            : IERC20(tokenAddress);
        // if max amount, get all the sender's balance
        if (amount == type(uint256).max) {
            amount = token.balanceOf(sender);
        }
        // receive token from sender
        token.safeTransferFrom(sender, address(this), amount);
        // approve the token to the spender
        try token.approve(spender, amount) {} catch {
            token.safeApprove(spender, 0);
            token.safeApprove(spender, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../../interfaces/IAdapterManager.sol";

abstract contract AdapterBase {
    address internal immutable ADAPTER_MANAGER;
    address internal immutable ADAPTER_ADDRESS;
    string internal ADAPTER_NAME;

    fallback() external payable {}

    receive() external payable {}

    modifier onlyAdapterManager() {
        require(
            msg.sender == ADAPTER_MANAGER,
            "Only the AdapterManager can call this function"
        );
        _;
    }

    modifier onlyProxy() {
        require(
            ADAPTER_ADDRESS != address(this),
            "Only proxy wallet can delegatecall this function"
        );
        _;
    }

    constructor(address _adapterManager, string memory _name) {
        ADAPTER_MANAGER = _adapterManager;
        ADAPTER_ADDRESS = address(this);
        ADAPTER_NAME = _name;
    }

    function getAdapterManager() external view returns (address) {
        return ADAPTER_MANAGER;
    }

    function identifier() external view returns (string memory) {
        return ADAPTER_NAME;
    }

    function toCallback(
        address _target,
        string memory _callFunc,
        bytes calldata _callData
    ) internal {
        (bool success, bytes memory returnData) = _target.call(
            abi.encodeWithSignature(
                "callback(string,bytes)",
                _callFunc,
                _callData
            )
        );
        require(success, string(returnData));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveRewardsOnlyGauge {
    function decimals() external view returns (uint256);

    function reward_contract() external view returns (address);

    function last_claim() external view returns (uint256);

    function claimed_reward(address _addr, address _token)
        external
        view
        returns (uint256);

    function claimable_reward(address _addr, address _token)
        external
        view
        returns (uint256);

    function claimable_reward_write(address _addr, address _token)
        external
        returns (uint256);

    function set_rewards_receiver(address _receiver) external;

    function claim_rewards() external;

    function claim_rewards(address _addr) external;

    function claim_rewards(address _addr, address _receiver) external;

    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool _claim_rewards) external;

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function increaseAllowance(address _spender, uint256 _added_value)
        external
        returns (bool);

    function decreaseAllowance(address _spender, uint256 _subtracted_value)
        external
        returns (bool);

    function set_rewards(
        address _reward_contract,
        bytes32 _claim_sig,
        address[8] memory _reward_tokens
    ) external;

    function commit_transfer_ownership(address addr) external;

    function accept_transfer_ownership() external;

    function lp_token() external view returns (address);

    function balanceOf(address arg0) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function allowance(address arg0, address arg1)
        external
        view
        returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function reward_tokens(uint256 arg0) external view returns (address);

    function reward_balances(address arg0) external view returns (uint256);

    function rewards_receiver(address arg0) external view returns (address);

    function claim_sig() external view returns (bytes memory);

    function reward_integral(address arg0) external view returns (uint256);

    function reward_integral_for(address arg0, address arg1)
        external
        view
        returns (uint256);

    function admin() external view returns (address);

    function future_admin() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICurveAtriCrypto {
    function add_liquidity(
        uint256[5] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[5] memory _min_amounts,
        address _receiver
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount,
        address _receiver
    ) external;

    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 _dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[5] memory _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IAdapterManager {
    enum SpendAssetsHandleType {
        None,
        Approve,
        Transfer,
        Remove
    }

    function receiveCallFromController(bytes calldata callArgs)
        external
        returns (bytes memory);

    function adapterIsRegistered(address) external view returns (bool);
}