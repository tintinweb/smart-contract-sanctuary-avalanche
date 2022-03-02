// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {AxialBasic} from "./AxialBasic.sol";

contract AxialAm3dAdapter is AxialBasic {
    /// @dev the params are adapter manager address, router address, lptoken address, farm id, adapter name
    constructor(address _adapterManager)
        AxialBasic(
            _adapterManager,
            0x90c7b96AD2142166D001B27b5fbc128494CDfBc8,
            0xc161E4B11FaF62584EFCD2100cCB461A2DdE64D1,
            3,
            "AxialAm3d"
        )
    {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/Basic.sol";
import "../base/AdapterBase.sol";
import {ISwapFlashLoan} from "../../interfaces/axial/ISwapFlashLoan.sol";
import {IMasterChefAxialV3} from "../../interfaces/axial/IMasterChefAxialV3.sol";

/// @dev common part of Axial adapters
contract AxialBasic is AdapterBase, Basic {
    using SafeERC20 for IERC20;

    address public immutable routerAddr;
    address public immutable lpTokenAddr;
    address public immutable stakingPoolAddr =
        0x958C0d0baA8F220846d3966742D4Fb5edc5493D3;
    uint256 public immutable stakingPid;

    event AxialAddLiquidity(
        address adapterAddress,
        uint256[] amounts,
        uint256 minLpAmount,
        address owner
    );

    event AxialRemoveLiquidity(
        address adapterAddress,
        uint256[] amountsMin,
        uint256 lpAmount,
        address owner
    );

    event AxialRemoveLiquidityOneToken(
        address adapterAddress,
        uint8 tokenIndex,
        uint256 lpAmount,
        uint256 minAmount,
        address owner
    );

    event AxialFarmEvent(
        address farmAddress,
        address owner,
        uint256 amount,
        uint256 pid
    );

    event AxialUnFarmEvent(
        address farmAddress,
        address owner,
        uint256 amount,
        uint256 pid
    );

    constructor(
        address _adapterManager,
        address _routerAddr,
        address _lpTokenAddr,
        uint256 _pid,
        string memory _name
    ) AdapterBase(_adapterManager, _name) {
        routerAddr = _routerAddr;
        lpTokenAddr = _lpTokenAddr;
        stakingPid = _pid;
    }

    function swap(bytes calldata encodedData) external onlyAdapterManager {
        (
            address owner,
            uint8 tokenIndexFrom,
            uint8 tokenIndexTo,
            uint256 dx,
            uint256 minDy
        ) = abi.decode(encodedData, (address, uint8, uint8, uint256, uint256));
        uint256[2] memory amounts;
        ISwapFlashLoan router = ISwapFlashLoan(routerAddr);
        address tokenFrom = router.getToken(tokenIndexFrom);
        address tokenTo = router.getToken(tokenIndexTo);
        pullAndApprove(tokenFrom, owner, routerAddr, dx);
        amounts[0] = dx;
        amounts[1] = router.swap(
            tokenIndexFrom,
            tokenIndexTo,
            dx,
            minDy,
            block.timestamp + TIME_INTERVAL
        );
        IERC20(tokenTo).safeTransfer(owner, amounts[1]);
    }

    function addLiquidity(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address owner, uint256[] memory amounts, uint256 minToMint) = abi
            .decode(encodedData, (address, uint256[], uint256));

        ISwapFlashLoan router = ISwapFlashLoan(routerAddr);
        for (uint8 i = 0; i < amounts.length; i++) {
            address tokenAddr = router.getToken(i);
            pullAndApprove(tokenAddr, owner, routerAddr, amounts[i]);
        }

        uint256 amount = router.addLiquidity(
            amounts,
            minToMint,
            block.timestamp + TIME_INTERVAL
        );

        IERC20(lpTokenAddr).safeTransfer(owner, amount);
        emit AxialAddLiquidity(address(this), amounts, minToMint, owner);
    }

    function removeLiquidity(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address owner, uint256 lpAmount, uint256[] memory amountsMin) = abi
            .decode(encodedData, (address, uint256, uint256[]));

        ISwapFlashLoan router = ISwapFlashLoan(routerAddr);
        pullAndApprove(lpTokenAddr, owner, routerAddr, lpAmount);
        uint256[] memory amountsOut = router.removeLiquidity(
            lpAmount,
            amountsMin,
            block.timestamp + TIME_INTERVAL
        );
        for (uint8 i = 0; i < amountsOut.length; i++) {
            address tokenAddr = router.getToken(i);
            IERC20(tokenAddr).safeTransfer(owner, amountsOut[i]);
        }
        emit AxialRemoveLiquidity(address(this), amountsMin, lpAmount, owner);
    }

    function removeLiquidityOneToken(bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            address owner,
            uint256 lpAmount,
            uint8 tokenIndex,
            uint256 minAmount
        ) = abi.decode(encodedData, (address, uint256, uint8, uint256));

        ISwapFlashLoan router = ISwapFlashLoan(routerAddr);
        pullAndApprove(lpTokenAddr, owner, routerAddr, lpAmount);
        uint256 amount = router.removeLiquidityOneToken(
            lpAmount,
            tokenIndex,
            minAmount,
            block.timestamp + TIME_INTERVAL
        );
        address tokenAddr = router.getToken(tokenIndex);
        IERC20(tokenAddr).safeTransfer(owner, amount);
        emit AxialRemoveLiquidityOneToken(
            address(this),
            tokenIndex,
            lpAmount,
            minAmount,
            owner
        );
    }

    function deposit(bytes calldata encodedData) external onlyProxy {
        uint256 amount = abi.decode(encodedData, (uint256));

        IMasterChefAxialV3(stakingPoolAddr).deposit(stakingPid, amount);
        emit AxialFarmEvent(stakingPoolAddr, address(this), amount, stakingPid);
    }

    function withdraw(bytes calldata encodedData) external onlyProxy {
        uint256 amount = abi.decode(encodedData, (uint256));

        IMasterChefAxialV3(stakingPoolAddr).withdraw(stakingPid, amount);
        emit AxialUnFarmEvent(
            stakingPoolAddr,
            address(this),
            amount,
            stakingPid
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

interface ISwapFlashLoan {
    // function MAX_BPS() external view returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata params
    ) external;

    function flashLoanFeeBPS() external view returns (uint256);

    function getA() external view returns (uint256);

    function getAPrecise() external view returns (uint256);

    function getToken(uint8 index) external view returns (address);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMasterChefAxialV3 {
    function deposit(uint256 pid, uint256 amount) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 pid, uint256 amount) external;
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