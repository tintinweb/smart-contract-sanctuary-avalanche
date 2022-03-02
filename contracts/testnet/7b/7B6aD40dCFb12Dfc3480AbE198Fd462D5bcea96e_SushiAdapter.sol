// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../common/Basic.sol";
import "../base/AdapterBase.sol";
import {ISushiFactory} from "../../interfaces/sushi/ISushiFactory.sol";
import {ISushiRouter} from "../../interfaces/sushi/ISushiRouter.sol";
import {IStakingRewards} from "../../interfaces/sushi/IStakingRewards.sol";

contract SushiAdapter is AdapterBase, Basic {
    using SafeERC20 for IERC20;

    address public constant routerAddr =
        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    ISushiRouter internal router = ISushiRouter(routerAddr);

    constructor(address _adapterManager)
        AdapterBase(_adapterManager, "Sushi")
    {}

    event SushiFarmEvent(address farmAddress, address owner, uint256 amount);

    event SushiUnFarmEvent(address farmAddress, address owner, uint256 amount);
    event SushiAddLiquidityEvent(
        uint256 liquidity,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address owner
    );

    event SushiRemoveLiquidityEvent(
        address token0,
        address token1,
        uint256 amount,
        uint256 amount0,
        uint256 amount1,
        address owner
    );

    /// @dev swap AVAX for fixed amount of tokens
    function swapAVAXForExactTokens(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amountInMax,
            uint256 amountOut,
            address[] memory path,
            address to
        ) = abi.decode(encodedData, (uint256, uint256, address[], address));
        uint256[] memory amounts = router.swapETHForExactTokens{
            value: amountInMax
        }(amountOut, path, to, block.timestamp + TIME_INTERVAL);
        if (amountInMax > amounts[0]) {
            safeTransferAVAX(to, amountInMax - amounts[0]);
        }
    }

    /// @dev swap fixed amount of AVAX for tokens
    function swapExactAVAXForTokens(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path,
            address to
        ) = abi.decode(encodedData, (uint256, uint256, address[], address));
        uint256[] memory amounts = router.swapExactETHForTokens{
            value: amountIn
        }(amountOutMin, path, to, block.timestamp + TIME_INTERVAL);
    }

    /// @dev swap tokens for fixed amount of AVAX
    function swapTokensForExactTokens(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amountOut,
            uint256 amountInMax,
            address[] memory path,
            address to
        ) = abi.decode(encodedData, (uint256, uint256, address[], address));
        pullAndApprove(path[0], to, routerAddr, amountInMax);
        uint256[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            block.timestamp + TIME_INTERVAL
        );
        if (amountInMax > amounts[0]) {
            IERC20(path[0]).safeTransfer(to, amountInMax - amounts[0]);
        }
    }

    /// @dev swap fixed amount of tokens for AVAX
    function swapExactTokensForTokens(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path,
            address to
        ) = abi.decode(encodedData, (uint256, uint256, address[], address));
        pullAndApprove(path[0], to, routerAddr, amountIn);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            block.timestamp + TIME_INTERVAL
        );
    }

    function swapTokensForExactAVAX(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amountOut,
            uint256 amountInMax,
            address[] memory path,
            address to
        ) = abi.decode(encodedData, (uint256, uint256, address[], address));
        pullAndApprove(path[0], to, routerAddr, amountInMax);
        uint256[] memory amounts = router.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            block.timestamp + TIME_INTERVAL
        );
        if (amountInMax > amounts[0]) {
            IERC20(path[0]).safeTransfer(to, amountInMax - amounts[0]);
        }
    }

    function swapExactTokensForAVAX(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path,
            address to
        ) = abi.decode(encodedData, (uint256, uint256, address[], address));
        pullAndApprove(path[0], to, routerAddr, amountIn);

        uint256[] memory amounts = router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            block.timestamp + TIME_INTERVAL
        );
    }

    function addLiquidity(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            address tokenA,
            address tokenB,
            uint256 amountA,
            uint256 amountB,
            uint256 minAmountA,
            uint256 minAmountB,
            address owner
        ) = abi.decode(
                encodedData,
                (address, address, uint256, uint256, uint256, uint256, address)
            );
        pullAndApprove(tokenA, owner, routerAddr, amountA);
        pullAndApprove(tokenB, owner, routerAddr, amountB);
        (uint256 _amountA, uint256 _amountB, uint256 liquidity) = router
            .addLiquidity(
                tokenA,
                tokenB,
                amountA,
                amountB,
                minAmountA,
                minAmountB,
                owner,
                block.timestamp + TIME_INTERVAL
            );
        if (amountA > _amountA) {
            IERC20(tokenA).safeTransfer(owner, amountA - _amountA);
        }
        if (amountB > _amountB) {
            IERC20(tokenB).safeTransfer(owner, amountB - _amountB);
        }
        emit SushiAddLiquidityEvent(
            liquidity,
            tokenA,
            tokenB,
            _amountA,
            _amountB,
            owner
        );
    }

    function removeLiquidity(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            address tokenA,
            address tokenB,
            uint256 amount,
            uint256 minAmountA,
            uint256 minAmountB,
            address owner
        ) = abi.decode(
                encodedData,
                (address, address, uint256, uint256, uint256, address)
            );
        address exchangeAddr = ISushiFactory(router.factory()).getPair(
            tokenA,
            tokenB
        );
        require(exchangeAddr != address(0), "pair-not-found.");
        pullAndApprove(exchangeAddr, owner, routerAddr, amount);
        (uint256 _amountA, uint256 _amountB) = router.removeLiquidity(
            tokenA,
            tokenB,
            amount,
            minAmountA,
            minAmountB,
            owner,
            block.timestamp + TIME_INTERVAL
        );
        emit SushiRemoveLiquidityEvent(
            tokenA,
            tokenB,
            amount,
            _amountA,
            _amountB,
            owner
        );
    }

    function addLiquidityAVAX(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            address tokenAddr,
            uint256 amountAVAXDesired,
            uint256 amountTokenDesired,
            uint256 amountTokenMin,
            uint256 amountAVAXMin,
            address owner
        ) = abi.decode(
                encodedData,
                (address, uint256, uint256, uint256, uint256, address)
            );
        pullAndApprove(tokenAddr, owner, routerAddr, amountTokenDesired);
        (uint256 _amountToken, uint256 _amountAVAX, uint256 _liquidity) = router
            .addLiquidityETH{value: amountAVAXDesired}(
            tokenAddr,
            amountTokenDesired,
            amountTokenMin,
            amountAVAXMin,
            owner,
            block.timestamp + TIME_INTERVAL
        );
        if (amountTokenDesired > _amountToken) {
            IERC20(tokenAddr).safeTransfer(
                owner,
                amountTokenDesired - _amountToken
            );
        }

        if (amountAVAXDesired == _amountAVAX) {
            IERC20 token = IERC20(tokenAddr);
            token.safeTransfer(owner, token.balanceOf(address(this)));
        } else {
            safeTransferAVAX(owner, amountAVAXDesired - _amountAVAX);
        }
        emit SushiAddLiquidityEvent(
            _liquidity,
            tokenAddr,
            avaxAddr,
            _amountToken,
            _amountAVAX,
            owner
        );
    }

    function removeLiquidityAVAX(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            address tokenAddr,
            address lpTokenAddr,
            uint256 liquidity,
            uint256 amountTokenMin,
            uint256 amountAVAXMin,
            address owner
        ) = abi.decode(
                encodedData,
                (address, address, uint256, uint256, uint256, address)
            );
        pullAndApprove(lpTokenAddr, owner, routerAddr, liquidity);
        (uint256 amountToken, uint256 amountAVAX) = router.removeLiquidityETH(
            tokenAddr,
            liquidity,
            amountTokenMin,
            amountAVAXMin,
            owner,
            block.timestamp + TIME_INTERVAL
        );
        emit SushiRemoveLiquidityEvent(
            tokenAddr,
            avaxAddr,
            liquidity,
            amountToken,
            amountAVAX,
            owner
        );
    }

    function depositLpToken(bytes calldata encodedData) external onlyProxy {
        (address stakePoolAddr, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        IStakingRewards(stakePoolAddr).stake(amount);
        emit SushiFarmEvent(stakePoolAddr, address(this), amount);
    }

    function withdrawLpToken(bytes calldata encodedData) external onlyProxy {
        (address stakePoolAddr, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        IStakingRewards(stakePoolAddr).withdraw(amount);
        emit SushiUnFarmEvent(stakePoolAddr, address(this), amount);
    }

    function claim_rewards(bytes calldata encodedData) external onlyProxy {
        address stakePoolAddr = abi.decode(encodedData, (address));
        IStakingRewards(stakePoolAddr).getReward();
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

interface ISushiFactory {
    function allPairs(uint256) external view returns (address);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address, address) external view returns (address);

    function setFeeTo(address _feeTo) external;

    function setFeeToSetter(address _feeToSetter) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface ISushiRouter {
    function WETH() external view returns (address);

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

    function factory() external view returns (address);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

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

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IStakingRewards {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function exit() external;

    function getReward() external;

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function notifyRewardAmount(uint256 reward) external;

    function owner() external view returns (address);

    function periodFinish() external view returns (uint256);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function renounceOwnership() external;

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewards(address) external view returns (uint256);

    function rewardsDuration() external view returns (uint256);

    function rewardsToken() external view returns (address);

    function setRewardsDuration(uint256 _rewardsDuration) external;

    function stake(uint256 amount) external;

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function withdraw(uint256 amount) external;
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