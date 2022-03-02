// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../base/AdapterBase.sol";
import "../../common/Basic.sol";
import {IPendleWrapper} from "../../interfaces/pendle/IPendleWrapper.sol";
import {IPendleGenericMarket} from "../../interfaces/pendle/IPendleGenericMarket.sol";
import {IPendleRouter} from "../../interfaces/pendle/IPendleRouter.sol";
import {IPendleFutureYieldToken} from "../../interfaces/pendle/IPendleFutureYieldToken.sol";
import {IJoePair} from "../../interfaces/traderJoe/IJoePair.sol";

contract PendleAdapter is AdapterBase, Basic {
    using SafeERC20 for IERC20;

    constructor(address _adapterManager)
        AdapterBase(_adapterManager, "Pendle")
    {}

    function tokenizeYield(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bytes32 forgeId,
            address routerAddress,
            address underlyingAsset,
            address lp,
            uint256 expiry,
            uint256 amountTokenize,
            address to
        ) = abi.decode(
                encodedData,
                (bytes32, address, address, address, uint256, uint256, address)
            );
        pullAndApprove(lp, to, routerAddress, amountTokenize);

        IPendleRouter router = IPendleRouter(routerAddress);
        (address ot_address, address xyt_address, uint256 amountMinted) = router
            .tokenizeYield(
                forgeId,
                underlyingAsset,
                expiry,
                amountTokenize,
                to
            );
    }

    function redeemUnderlying(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bytes32 forgeId,
            address routerAddress,
            address underlyingAsset,
            address lpAddress,
            address otAddress,
            address ytAddress,
            uint256 expiry,
            uint256 amountRedeem,
            address to
        ) = abi.decode(
                encodedData,
                (
                    bytes32,
                    address,
                    address,
                    address,
                    address,
                    address,
                    uint256,
                    uint256,
                    address
                )
            );
        pullAndApprove(otAddress, to, routerAddress, amountRedeem);
        pullAndApprove(ytAddress, to, routerAddress, amountRedeem);
        IERC20 lp = IERC20(lpAddress);

        IPendleRouter router = IPendleRouter(routerAddress);
        uint256 redeemAmount = router.redeemUnderlying(
            forgeId,
            underlyingAsset,
            expiry,
            amountRedeem
        );
        lp.safeTransfer(to, redeemAmount);
    }

    function redeemDueInterests(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bytes32 forgeId,
            address routerAddress,
            address underlyingAsset,
            uint256 expiry,
            address user
        ) = abi.decode(
                encodedData,
                (bytes32, address, address, uint256, address)
            );
        IPendleRouter router = IPendleRouter(routerAddress);
        uint256 interests = router.redeemDueInterests(
            forgeId,
            underlyingAsset,
            expiry,
            user
        );
    }

    function redeemLpInterests(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address routerAddress, address market_address, address user) = abi
            .decode(encodedData, (address, address, address));
        IPendleRouter router = IPendleRouter(routerAddress);
        uint256 interests = router.redeemLpInterests(market_address, user);
    }

    function addMarketLiquidityDual(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bytes32 marketFactoryId,
            // address routerAddress,
            // address yt_address,
            // address liquidity_token_address,
            // address yt_lp_address,
            // address user,
            address[] memory addresses,
            uint256 desiredXytAmount,
            uint256 desiredTokenAmount,
            uint256 xytMinAmount,
            uint256 tokenMinAmount
        ) = abi.decode(
                encodedData,
                (bytes32, address[], uint256, uint256, uint256, uint256)
            );

        pullAndApprove(
            addresses[1],
            addresses[4],
            addresses[0],
            desiredXytAmount
        );
        pullAndApprove(
            addresses[2],
            addresses[4],
            addresses[0],
            desiredTokenAmount
        );
        IPendleGenericMarket market = IPendleGenericMarket(addresses[3]);
        IERC20 liquidity_token = IERC20(addresses[2]);
        IPendleFutureYieldToken yt = IPendleFutureYieldToken(addresses[1]);

        IPendleRouter router = IPendleRouter(addresses[0]);
        (uint256 amountXytUsed, uint256 amountTokenUsed, uint256 lpOut) = router
            .addMarketLiquidityDual(
                marketFactoryId,
                addresses[1],
                addresses[2],
                desiredXytAmount,
                desiredTokenAmount,
                xytMinAmount,
                tokenMinAmount
            );

        yt.transfer(addresses[4], desiredXytAmount - amountXytUsed);
        liquidity_token.safeTransfer(
            addresses[4],
            desiredTokenAmount - amountTokenUsed
        );
        market.transfer(addresses[4], lpOut);
    }

    function addMarketLiquiditySingle(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bytes32 marketFactoryId,
            // address routerAddress,
            // address yt_address,
            // address liquidity_token_address,
            // address yt_lp_address,
            // address user,
            address[] memory addresses,
            bool forXyt,
            uint256 exactIn,
            uint256 minOutLp
        ) = abi.decode(
                encodedData,
                (bytes32, address[], bool, uint256, uint256)
            );
        if (forXyt) {
            pullAndApprove(addresses[1], addresses[4], addresses[0], exactIn);
        } else {
            pullAndApprove(addresses[2], addresses[4], addresses[0], exactIn);
        }
        IPendleGenericMarket market = IPendleGenericMarket(addresses[3]);

        IPendleRouter router = IPendleRouter(addresses[0]);
        uint256 exactOutLp = router.addMarketLiquiditySingle(
            marketFactoryId,
            addresses[1],
            addresses[2],
            forXyt,
            exactIn,
            minOutLp
        );

        market.transfer(addresses[4], exactOutLp);
    }

    function removeMarketLiquidityDual(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bytes32 marketFactoryId,
            // address routerAddress,
            // address yt_address,
            // address liquidity_token_address,
            // address yt_lp_address,
            // address user,
            address[] memory addresses,
            uint256 exactInLp,
            uint256 minOutXyt,
            uint256 minOutToken
        ) = abi.decode(
                encodedData,
                (bytes32, address[], uint256, uint256, uint256)
            );

        pullAndApprove(addresses[3], addresses[4], addresses[0], exactInLp);

        IERC20 liquidity_token = IERC20(addresses[2]);
        IPendleFutureYieldToken yt = IPendleFutureYieldToken(addresses[1]);

        IPendleRouter router = IPendleRouter(addresses[0]);
        (uint256 exactOutXyt, uint256 exactOutToken) = router
            .removeMarketLiquidityDual(
                marketFactoryId,
                addresses[1],
                addresses[2],
                exactInLp,
                minOutXyt,
                minOutToken
            );

        yt.transfer(addresses[4], exactOutXyt);
        liquidity_token.safeTransfer(addresses[4], exactOutToken);
    }

    function removeMarketLiquiditySingle(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            bytes32 marketFactoryId,
            // address routerAddress,
            // address yt_address,
            // address liquidity_token_address,
            // address yt_lp_address,
            // address user,
            address[] memory addresses,
            bool forXyt,
            uint256 exactInLp,
            uint256 minOutAsset
        ) = abi.decode(
                encodedData,
                (bytes32, address[], bool, uint256, uint256)
            );
        pullAndApprove(addresses[3], addresses[4], addresses[0], exactInLp);

        IERC20 liquidity_token = IERC20(addresses[2]);
        IPendleFutureYieldToken yt = IPendleFutureYieldToken(addresses[1]);

        IPendleRouter router = IPendleRouter(addresses[0]);
        (uint256 exactOutXyt, uint256 exactOutToken) = router
            .removeMarketLiquiditySingle(
                marketFactoryId,
                addresses[1],
                addresses[2],
                forXyt,
                exactInLp,
                minOutAsset
            );

        if (forXyt) {
            yt.transfer(addresses[4], exactOutXyt);
        } else {
            liquidity_token.safeTransfer(addresses[4], exactOutToken);
        }
    }

    function swapExactIn(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            address routerAddress,
            address tokenInAddress,
            address tokenOutAddress,
            address userAddress,
            uint256 inAmount,
            uint256 minOutAmount,
            bytes32 marketFactoryId
        ) = abi.decode(
                encodedData,
                (address, address, address, address, uint256, uint256, bytes32)
            );

        IERC20 tokenOut = IERC20(tokenOutAddress);

        IPendleRouter router = IPendleRouter(routerAddress);
        uint256 outSwapAmount = router.swapExactIn(
            tokenInAddress,
            tokenOutAddress,
            inAmount,
            minOutAmount,
            marketFactoryId
        );
        tokenOut.safeTransfer(userAddress, outSwapAmount);
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
import {IPendleRouter} from "./IPendleRouter.sol";

// import {IAaveV2LendingPool} from "./IAaveV2LendingPool.sol";
// import {IUniswapV2Router02} from "./IUniswapV2Router02.sol";
// import {IDMMLiquidityRouter} from "./IDMMLiquidityRouter.sol";
// import {IJoeBar} from "./IJoeBar.sol";
// import {IWETH} from "./IWETH.sol";

interface IPendleWrapper {
    struct Element {
        address token;
        uint256 amount;
    }

    struct Approval {
        address token;
        address to;
    }

    struct DataTknzSingle {
        address token;
        uint256 amount;
    }

    struct DataTknz {
        DataTknzSingle single;
        DataAddLiqUniFork double;
        address forge;
        uint256 expiryYT;
    }

    struct DataYO {
        address OT;
        address YT;
        uint256 amountYO;
    }

    struct DataAddLiqOT {
        address baseToken;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 deadline;
        address liqMiningAddr;
    }

    struct DataAddLiqYT {
        address baseToken;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        bytes32 marketFactoryId;
        address liqMiningAddr;
    }

    struct DataAddLiqUniFork {
        address tokenA;
        address tokenB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 deadline;
        address kyberPool;
        uint256[2] kybervReserveRatioBounds;
    }

    // struct ConstructorData {
    //     IPendleRouter pendleRouter;
    //     IAaveV2LendingPool aaveLendingPool;
    //     IUniswapV2Router02 uniRouter;
    //     IUniswapV2Router02 sushiRouter;
    //     IDMMLiquidityRouter kyberRouter;
    //     IJoeBar joeBar;
    //     IWETH weth;
    //     bytes32 codeHashUni;
    //     bytes32 codeHashSushi;
    //     bool deployedOnAvax;
    // }

    function infinityApprove(Approval memory approvals) external;

    function insAddDualLiqForOT(
        uint8 mode,
        DataTknz memory dataTknz,
        DataAddLiqOT memory dataAddOT
    )
        external
        returns (
            DataYO memory dataYO,
            uint256 lpOutOT,
            uint256 amountBaseTokenUsedOT
        );

    function insAddDualLiqForOTandYT(
        uint8 mode,
        DataTknz memory dataTknz,
        DataAddLiqOT memory dataAddOT,
        DataAddLiqYT memory dataAddYT
    )
        external
        returns (
            DataYO memory dataYO,
            uint256 lpOutOT,
            uint256 amountBaseTokenUsedOT,
            uint256 lpOutYT,
            uint256 amountBaseTokenUsedYT
        );

    function insAddDualLiqForYT(
        uint8 mode,
        DataTknz memory dataTknz,
        DataAddLiqYT memory dataAddYT
    )
        external
        returns (
            DataYO memory dataYO,
            uint256 lpOut,
            uint256 amountBaseTokenUsed
        );

    function insAddSingleLiq(
        uint8 mode,
        DataTknz memory dataTknz,
        bytes32 marketFactoryId,
        address baseToken,
        uint256 minOutLp,
        address liqMiningAddr
    ) external returns (DataYO memory dataYO, uint256 lpOut);

    function insRealizeFutureYield(
        uint8 mode,
        DataTknz memory dataTknz,
        bytes32 marketFactoryId,
        address baseToken,
        uint256 minOutBaseTokenAmount
    ) external returns (DataYO memory dataYO, uint256 amountBaseTokenOut);

    function insTokenize(uint8 mode, DataTknz memory dataTknz)
        external
        returns (DataYO memory dataYO);

    //   function joeBar() external view returns (address);
    //   function ETH_ADDRESS (  ) external view returns ( address );
    //   function aaveLendingPool (  ) external view returns ( address );
    //   function codeHashSushi (  ) external view returns ( bytes32 );
    //   function codeHashUni (  ) external view returns ( bytes32 );
    //   function deployedOnAvax (  ) external view returns ( bool );
    //   function kyberRouter (  ) external view returns ( address );
    //   function pendleData (  ) external view returns ( address );
    //   function pendleRouter (  ) external view returns ( address );
    //   function sushiRouter (  ) external view returns ( address );
    //   function uniRouter (  ) external view returns ( address );
    //   function weth (  ) external view returns ( address );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPendleGenericMarket {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    //   function addMarketLiquidityDual ( address user, uint256 _desiredXytAmount, uint256 _desiredTokenAmount, uint256 _xytMinAmount, uint256 _tokenMinAmount ) external returns ( tuple[2] transfers, uint256 lpOut );
    //   function addMarketLiquiditySingle ( address user, address _inToken, uint256 _exactIn, uint256 _minOutLp ) external returns ( tuple[2] transfers, uint256 exactOutLp );
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    //   function bootstrap ( address user, uint256 initialXytLiquidity, uint256 initialTokenLiquidity ) external returns ( tuple[2] transfers, uint256 exactOutLp );
    function bootstrapped() external view returns (bool);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function expiry() external view returns (uint256);

    function factoryId() external view returns (bytes32);

    function getReserves()
        external
        view
        returns (
            uint256 xytBalance,
            uint256 xytWeight,
            uint256 tokenBalance,
            uint256 tokenWeight,
            uint256 currentBlock
        );

    function governanceManager() external view returns (address);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function lastCurveShiftBlock() external view returns (uint256);

    function lastNYield() external view returns (uint256);

    function lastParamK() external view returns (uint256);

    function lockStartTime() external view returns (uint256);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function paramL() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function redeemLpInterests(address user)
        external
        returns (uint256 interests);

    //   function removeMarketLiquidityDual ( address user, uint256 _inLp, uint256 _minOutXyt, uint256 _minOutToken ) external returns ( tuple[2] transfers );
    //   function removeMarketLiquiditySingle ( address user, address _outToken, uint256 _inLp, uint256 _minOutAmountToken ) external returns ( tuple[2] transfers );
    function router() external view returns (address);

    function setUpEmergencyMode(address spender) external;

    function start() external view returns (uint256);

    //   function swapExactIn ( address inToken, uint256 inAmount, address outToken, uint256 minOutAmount ) external returns ( uint256 outAmount, tuple[2] transfers );
    //   function swapExactOut ( address inToken, uint256 maxInAmount, address outToken, uint256 outAmount ) external returns ( uint256 inAmount, tuple[2] transfers );
    function symbol() external view returns (string memory);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function withdrawEther(uint256 amount, address sendTo) external;

    function withdrawToken(
        address token,
        uint256 amount,
        address sendTo
    ) external;

    function xyt() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPendleRouter {
    function createMarket(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token
    ) external returns (address market);

    function data() external view returns (address);

    function newYieldContracts(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry
    ) external returns (address ot, address xyt);

    function tokenizeYield(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry,
        uint256 _amountToTokenize,
        address _to
    )
        external
        returns (
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );

    // ================================================== redeem ==================================================

    function redeemAfterExpiry(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry
    ) external returns (uint256 redeemedAmount);

    function redeemDueInterests(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry,
        address _user
    ) external returns (uint256 interests);

    function redeemLpInterests(address market, address user)
        external
        returns (uint256 interests);

    function redeemUnderlying(
        bytes32 _forgeId,
        address _underlyingAsset,
        uint256 _expiry,
        uint256 _amountToRedeem
    ) external returns (uint256 redeemedAmount);

    // ================================================== add liquidity ==================================================
    function addMarketLiquidityDual(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _desiredXytAmount,
        uint256 _desiredTokenAmount,
        uint256 _xytMinAmount,
        uint256 _tokenMinAmount
    )
        external
        returns (
            uint256 amountXytUsed,
            uint256 amountTokenUsed,
            uint256 lpOut
        );

    function addMarketLiquiditySingle(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        bool _forXyt,
        uint256 _exactIn,
        uint256 _minOutLp
    ) external returns (uint256 exactOutLp);

    // ================================================== remove liquidity ==================================================

    function removeMarketLiquidityDual(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _exactInLp,
        uint256 _minOutXyt,
        uint256 _minOutToken
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    function removeMarketLiquiditySingle(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        bool _forXyt,
        uint256 _exactInLp,
        uint256 _minOutAsset
    ) external returns (uint256 exactOutXyt, uint256 exactOutToken);

    // ================================================== swap ==================================================

    function swapExactIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _inAmount,
        uint256 _minOutAmount,
        bytes32 _marketFactoryId
    ) external returns (uint256 outSwapAmount);

    function swapExactOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _outAmount,
        uint256 _maxInAmount,
        bytes32 _marketFactoryId
    ) external returns (uint256 inSwapAmount);

    function weth() external view returns (address);

    function withdrawEther(uint256 amount, address sendTo) external;

    function withdrawToken(
        address token,
        uint256 amount,
        address sendTo
    ) external;

    function bootstrapMarket(
        bytes32 _marketFactoryId,
        address _xyt,
        address _token,
        uint256 _initialXytLiquidity,
        uint256 _initialTokenLiquidity
    ) external;

    function governanceManager() external view returns (address);

    function renewYield(
        bytes32 _forgeId,
        uint256 _oldExpiry,
        address _underlyingAsset,
        uint256 _newExpiry,
        uint256 _renewalRate
    )
        external
        returns (
            uint256 redeemedAmount,
            uint256 amountRenewed,
            address ot,
            address xyt,
            uint256 amountTokenMinted
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPendleFutureYieldToken {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approveRouter(address user) external;

    function balanceOf(address account) external view returns (uint256);

    function burn(address user, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function expiry() external view returns (uint256);

    function forge() external view returns (address);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function mint(address user, uint256 amount) external;

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function router() external view returns (address);

    function start() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function underlyingAsset() external view returns (address);

    function underlyingYieldToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IJoePair {
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