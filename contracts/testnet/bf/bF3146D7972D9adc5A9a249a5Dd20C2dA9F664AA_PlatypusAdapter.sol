// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../common/Basic.sol";
import "../base/AdapterBase.sol";
import {IPlatypusRouter} from "../../interfaces/platypus/IPlatypusRouter.sol";
import {IPlatypusFarm} from "../../interfaces/platypus/IPlatypusFarm.sol";
import {Iveptp} from "../../interfaces/platypus/Iveptp.sol";

contract PlatypusAdapter is AdapterBase, Basic {
    constructor(address _adapterManager)
        AdapterBase(_adapterManager, "Platypus")
    {}

    event PlatypusDepositEvent(
        address token,
        address asset,
        uint256 tokenAmount,
        uint256 liquidity,
        address router,
        address owner
    );
    event PlatypusWithdrawEvent(
        address token,
        address asset,
        uint256 tokenAmount,
        uint256 liquidity,
        address router,
        address owner
    );
    event PlatypusSwapEvent(
        address fromToken,
        address toToken,
        uint256 swapAmount,
        uint256 resultAmount,
        address router,
        address owner
    );

    event PlatypusStakeEvent(
        uint256 pid,
        uint256 amount,
        uint256 receivedPTP,
        address farmAddress,
        address owner
    );

    event PlatypusUnstakeEvent(
        uint256 pid,
        uint256 amount,
        uint256 receivedPTP,
        address farmAddress,
        address owner
    );

    function deposit(bytes calldata encodedData) external onlyAdapterManager {
        // addresses: tokenAddress, assetAddress, routerAddress, proxyAddress
        (
            address[] memory addresses,
            uint256 depositAmount,
            uint256 deadline
        ) = abi.decode(encodedData, (address[], uint256, uint256));
        pullAndApprove(addresses[0], addresses[3], addresses[2], depositAmount);
        IPlatypusRouter router = IPlatypusRouter(addresses[2]);
        uint256 liquidity = router.deposit(
            addresses[0],
            depositAmount,
            addresses[3],
            deadline
        );
        emit PlatypusDepositEvent(
            addresses[0],
            addresses[1],
            depositAmount,
            liquidity,
            addresses[2],
            addresses[3]
        );
    }

    function withdraw(bytes calldata encodedData) external onlyAdapterManager {
        // addresses: tokenAddress, assetAddress, routerAddress, proxyAddress
        (
            address[] memory addresses,
            uint256 liquidity,
            uint256 minAmount,
            uint256 deadline
        ) = abi.decode(encodedData, (address[], uint256, uint256, uint256));
        pullAndApprove(addresses[1], addresses[3], addresses[2], liquidity);
        IPlatypusRouter router = IPlatypusRouter(addresses[2]);
        uint256 withdrawAmount = router.withdraw(
            addresses[0],
            liquidity,
            minAmount,
            addresses[3],
            deadline
        );
        emit PlatypusWithdrawEvent(
            addresses[0],
            addresses[1],
            withdrawAmount,
            liquidity,
            addresses[2],
            addresses[3]
        );
    }

    function swap(bytes calldata encodedData) external onlyAdapterManager {
        // addresses: tokenAddress, assetAddress, routerAddress, proxyAddress
        (
            address[] memory addresses,
            uint256 swapAmount,
            uint256 minAmount,
            uint256 deadline
        ) = abi.decode(encodedData, (address[], uint256, uint256, uint256));
        pullAndApprove(addresses[0], addresses[3], addresses[2], swapAmount);
        IPlatypusRouter router = IPlatypusRouter(addresses[2]);
        (uint256 resultAmount, ) = router.swap(
            addresses[0],
            addresses[1],
            swapAmount,
            minAmount,
            addresses[3],
            deadline
        );
        emit PlatypusSwapEvent(
            addresses[0],
            addresses[1],
            swapAmount,
            resultAmount,
            addresses[2],
            addresses[3]
        );
    }

    function stake(bytes calldata encodedData) external {
        (
            address farmAddress,
            address owner,
            uint256 pid,
            uint256 depositAmount
        ) = abi.decode(encodedData, (address, address, uint256, uint256));

        IPlatypusFarm farm = IPlatypusFarm(farmAddress);
        (uint256 receivedPTP, ) = farm.deposit(pid, depositAmount);
        emit PlatypusStakeEvent(
            pid,
            depositAmount,
            receivedPTP,
            farmAddress,
            owner
        );
    }

    function unstake(bytes calldata encodedData) external {
        (
            address farmAddress,
            address owner,
            uint256 pid,
            uint256 unstakeAmount
        ) = abi.decode(encodedData, (address, address, uint256, uint256));

        IPlatypusFarm farm = IPlatypusFarm(farmAddress);
        (uint256 receivedPTP, ) = farm.withdraw(pid, unstakeAmount);
        emit PlatypusUnstakeEvent(
            pid,
            unstakeAmount,
            receivedPTP,
            farmAddress,
            owner
        );
    }

    // ERROR: "Smart contract depositors not allowed"
    function depositPTP(bytes calldata encodedData) external {
        (
            address ptpAddress,
            address veptpAddress,
            address owner,
            uint256 depositAmount
        ) = abi.decode(encodedData, (address, address, address, uint256));
        Iveptp ptp = Iveptp(veptpAddress);
        ptp.deposit(depositAmount);
    }

    function withdrawPTP(bytes calldata encodedData) external {
        (
            address ptpAddress,
            address veptpAddress,
            address owner,
            uint256 withdrawAmount
        ) = abi.decode(encodedData, (address, address, address, uint256));
        Iveptp ptp = Iveptp(veptpAddress);
        ptp.withdraw(withdrawAmount);
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

interface IPlatypusRouter {
    function addAsset(address token, address asset) external;

    function assetOf(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function getC1() external view returns (uint256);

    function getDev() external view returns (address);

    function getHaircutRate() external view returns (uint256);

    function getMaxPriceDeviation() external view returns (uint256);

    function getPriceOracle() external view returns (address);

    function getRetentionRatio() external view returns (uint256);

    function getSlippageParamK() external view returns (uint256);

    function getSlippageParamN() external view returns (uint256);

    function getTokenAddresses() external view returns (address[] memory);

    function getXThreshold() external view returns (uint256);

    function initialize() external;

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function quoteMaxInitialAssetWithdrawable(
        address initialToken,
        address wantedToken
    ) external view returns (uint256 maxInitialAssetAmount);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            bool enoughCash
        );

    function quotePotentialWithdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function removeAsset(address key) external;

    function renounceOwnership() external;

    function setDev(address dev) external;

    function setHaircutRate(uint256 haircutRate_) external;

    function setMaxPriceDeviation(uint256 maxPriceDeviation_) external;

    function setPriceOracle(address priceOracle) external;

    function setRetentionRatio(uint256 retentionRatio_) external;

    function setSlippageParams(
        uint256 k_,
        uint256 n_,
        uint256 c1_,
        uint256 xThreshold_
    ) external;

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address initialToken,
        address wantedToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IPlatypusFarm {
    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function claimablePtp(uint256, address) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256, uint256);

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function dialutingRepartition() external view returns (uint256);

    function emergencyPtpWithdraw() external;

    function emergencyWithdraw(uint256 _pid) external;

    function initialize(
        address _ptp,
        address _vePtp,
        uint256 _ptpPerSec,
        uint256 _dialutingRepartition,
        uint256 _startTimestamp
    ) external;

    function massUpdatePools() external;

    function migrate(uint256[] memory _pids) external;

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        );

    function nonDialutingRepartition() external view returns (uint256);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accPtpPerShare,
            address rewarder,
            uint256 sumOfFactors,
            uint256 accPtpPerFactorShare
        );

    function poolLength() external view returns (uint256);

    function ptp() external view returns (address);

    function ptpPerSec() external view returns (uint256);

    function renounceOwnership() external;

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function setNewMasterPlatypus(address _newMasterPlatypus) external;

    function setVePtp(address _newVePtp) external;

    function startTimestamp() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateEmissionRate(uint256 _ptpPerSec) external;

    function updateEmissionRepartition(uint256 _dialutingRepartition) external;

    function updateFactor(address _user, uint256 _newVePtpBalance) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 factor
        );

    function vePtp() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface Iveptp {
    function balanceOf(address account) external view returns (uint256);

    function claim() external;

    function claimable(address _addr) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 _amount) external;

    function generationRate() external view returns (uint256);

    function getStakedNft(address _addr) external view returns (uint256);

    function getStakedPtp(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);

    function initialize(
        address _ptp,
        address _masterPlatypus,
        address _nft
    ) external;

    function invVoteThreshold() external view returns (uint256);

    function isUser(address _addr) external view returns (bool);

    function masterPlatypus() external view returns (address);

    function maxCap() external view returns (uint256);

    function name() external view returns (string memory);

    function nft() external view returns (address);

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes memory
    ) external returns (bytes4);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function ptp() external view returns (address);

    function renounceOwnership() external;

    function setGenerationRate(uint256 _generationRate) external;

    function setInvVoteThreshold(uint256 _invVoteThreshold) external;

    function setMasterPlatypus(address _masterPlatypus) external;

    function setMaxCap(uint256 _maxCap) external;

    function setNftAddress(address _nft) external;

    function setWhitelist(address _whitelist) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function unstakeNft() external;

    function users(address)
        external
        view
        returns (
            uint256 amount,
            uint256 lastRelease,
            uint256 stakedNftId
        );

    function whitelist() external view returns (address);

    function withdraw(uint256 _amount) external;
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