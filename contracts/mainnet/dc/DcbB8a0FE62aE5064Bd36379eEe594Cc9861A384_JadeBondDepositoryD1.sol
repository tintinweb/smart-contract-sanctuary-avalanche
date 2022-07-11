// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "BaseBond.sol";

contract JadeBondDepositoryD1 is BaseBond {
    using SafeERC20 for IERC20;
    uint256[10][4] public discountRates;

    /* ======== INITIALIZATION ======== */

    constructor(
        address _Jade,
        address _treasury,
        address _amountsTracker,
        uint256 _startDate
    ) BaseBond(_Jade, _treasury, _startDate, _amountsTracker) {}

    /* ======== USER FUNCTIONS ======== */

    function registerDiscounts(uint256 _yearNb, uint256[] calldata _discounts) external onlyOwner {
        for (uint256 i; i < discountRates[0].length; i++) {
            discountRates[_yearNb][i] = _discounts[i];
        }
    }

    function getDiscountRates(address user) public view returns (uint256[4] memory _discounts) {
        (, , , uint256 diamondTier) = IDiamondAccounting(amountsTracker).getUserInfo(user);

        if (diamondTier > 0) {
            for (uint256 year; year < 4; year++) {
                _discounts[year] = discountRates[year][diamondTier - 1];
            }
        }
    }

    function getAllBondedPerYear() public view returns (uint256[4] memory _bonded) {
        for (uint256 year; year < 4; year++) {
            _bonded[year] = bondedTotalPerYear[year];
        }
    }

    function getRemainingDiscountCaps(address user) public view returns (uint256[4] memory _caps) {
        (, , uint256 remainingAllowance, uint256 diamondTier) = IDiamondAccounting(amountsTracker)
            .getUserInfo(user);

        address jlp = IDiamondAccounting(amountsTracker).jlp();
        uint256 jadeEquivalent = payoutFor(jlp, remainingAllowance);

        if (diamondTier > 0) {
            for (uint256 year; year < 4; year++) {
                _caps[year] = applyDiscount(jadeEquivalent, diamondTier, year);
            }
        }
    }

    function getRemainingTotalDiscountCaps() public view returns (uint256[4] memory _caps) {
        for (uint256 year; year < 4; year++) {
            _caps[year] = type(uint256).max;
        }
    }

    function getBondableTotalDiscountCaps(address token)
        external
        view
        returns (uint256[4] memory _caps)
    {
        for (uint256 year; year < 4; year++) {
            _caps[year] = type(uint256).max;
        }
    }

    function applyDiscount(
        uint256 payout,
        uint256 tier,
        uint256 _yearNb
    ) public view returns (uint256) {
        return (payout * percentagePrecision) / discountRates[_yearNb][tier - 1];
    }

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @return uint
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint256 _slippage,
        uint256 _yearNb
    ) external returns (uint256) {
        require(getProgress() == Progress.OPEN, "bonds are closed");
        require(msg.sender != address(0), "Invalid address");
        TokenInformation memory tokenInfo = tokensInfo[_token];
        (
            bool isUserAllowed,
            ,
            uint256 remainingAllowance,
            uint256 diamondTier
        ) = IDiamondAccounting(amountsTracker).getUserInfo(msg.sender);
        require(tokenInfo.authorized, "token not authorized for bonding");
        require(_yearNb < 4, "Must be at 0 to 3 (years-1)");
        require(isUserAllowed, "User not allowed for D1 discount");
        require(diamondTier > 0, "User has not a diamond tier");
        require(_amount <= remainingAllowance, "discount fully used");
        IDiamondAccounting(amountsTracker).lowerRemainingJLP(msg.sender, _amount);

        uint256 payout = payoutFor(_token, _amount); // payout to bonder is computed
        uint256 discountedPayout = applyDiscount(payout, diamondTier, _yearNb);

        require(payout >= 10000000, "Bond too small"); // must be > 0.01 JADE ( underflow protection )

        bondedTotalPerYear[_yearNb] += discountedPayout;
        IMintableERC20(Jade).mint(address(this), discountedPayout);
        IERC20(_token).safeTransferFrom(msg.sender, address(treasury), _amount);

        // depositor info is stored
        bondsBought[_yearNb][msg.sender] = Bond({
            payout: bondsBought[_yearNb][msg.sender].payout + discountedPayout,
            payoutHonored: 0
        });

        require(_slippage <= discountedPayout, "Slippage too low");
        // indexed events are emitted
        emit BondCreated(_amount, payout);

        return discountedPayout;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "Ownable.sol";
import "SafeERC20.sol";
import "IDiamondAccounting.sol";
import "IMintableERC20.sol";

contract BaseBond is Ownable {
    using SafeERC20 for IERC20;

    event BondCreated(uint256 deposit, uint256 indexed payout);
    event BondRedeemed(address indexed recipient, uint256 payout, uint256 remaining);

    struct TokenInformation {
        uint256 priceInStable;
        uint256 decimals;
        bool authorized;
    }
    struct Bond {
        uint256 payout;
        uint256 payoutHonored;
    }
    mapping(address => TokenInformation) public tokensInfo;
    mapping(address => Bond)[4] public bondsBought;
    uint256[4] public bondedTotalPerYear;
    uint256 constant percentagePrecision = 1e4;
    address public immutable Jade; // token given as payment for bond
    address public immutable treasury; // mints JADE when receives principle
    uint256 public jadePriceInUsd;
    uint256 public vestingStartDate;
    uint256 public bondingStartDate;
    address public amountsTracker;
    address public priceMonitor;

    constructor(
        address _Jade,
        address _treasury,
        uint256 _startDate,
        address _amountsTracker
    ) {
        require(_Jade != address(0));
        Jade = _Jade;
        require(_treasury != address(0));
        treasury = _treasury;
        vestingStartDate = _startDate;
        amountsTracker = _amountsTracker;
        bondingStartDate = block.timestamp;
    }

    function registerToken(
        address _tokenAddress,
        uint256 _tokenPrice,
        uint256 _decimals
    ) external {
        require(msg.sender == owner() || msg.sender == priceMonitor, "Not allowed");
        TokenInformation storage info = tokensInfo[_tokenAddress];
        info.authorized = true;
        info.decimals = _decimals;
        info.priceInStable = _tokenPrice;
    }

    enum Progress {
        NOT_OPEN,
        OPEN,
        CLOSED
    }

    function getProgress() public view returns (Progress) {
        if (block.timestamp > vestingStartDate) return Progress.CLOSED;
        if (block.timestamp > bondingStartDate) return Progress.OPEN;
        return Progress.NOT_OPEN;
    }

    function setVestingStart(uint256 _date) external onlyOwner {
        vestingStartDate = _date;
    }

    function setBondingStart(uint256 _date) external onlyOwner {
        bondingStartDate = _date;
    }

    function setJadePrice(uint256 price) external {
        require(msg.sender == owner() || msg.sender == priceMonitor, "Not allowed");
        jadePriceInUsd = price;
    }

    function setPriceMonitor(address _monitor) external onlyOwner {
        priceMonitor = _monitor;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     */
    function redeem(address _recipient, uint256 _yearNb) public {
        require(_yearNb < 4, "Must be at 0 to 3 (years-1)");
        Bond memory info = bondsBought[_yearNb][_recipient];
        // (seconds since last interaction / vesting term remaining)
        uint256 percentVested = percentVestedFor(_yearNb);
        require(percentVested > 0, "Nothing to claim yet");

        if (percentVested >= 10000) {
            // if fully vested
            bondsBought[_yearNb][_recipient] = Bond({
                payout: info.payout,
                payoutHonored: info.payout
            });
            emit BondRedeemed(_recipient, info.payout - info.payoutHonored, 0); // emit bond data
            require(info.payout > info.payoutHonored, "Nothing to claim");
            IERC20(Jade).safeTransfer(_recipient, info.payout - info.payoutHonored); // pay user everything due
        } else {
            // if unfinished
            // calculate payout vested
            uint256 payout = (info.payout * percentVested) / 10000 - info.payoutHonored;
            require(payout > 0, "Nothing to claim");
            // store updated deposit info
            bondsBought[_yearNb][_recipient] = Bond({
                payout: info.payout,
                payoutHonored: info.payoutHonored + payout
            });

            emit BondRedeemed(
                _recipient,
                payout,
                bondsBought[_yearNb][_recipient].payout -
                    bondsBought[_yearNb][_recipient].payoutHonored
            );
            IERC20(Jade).safeTransfer(_recipient, payout);
        }
    }

    /**
     *  @notice calculate amount of Jade available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor, uint256 _yearNb) public view returns (uint256) {
        uint256 percentVested = percentVestedFor(_yearNb);
        Bond memory info = bondsBought[_yearNb][_depositor];
        uint256 payout = info.payout;
        uint256 alreadyHonored = info.payoutHonored;

        if (percentVested >= 10000) {
            return payout - alreadyHonored;
        } else {
            return (payout * percentVested) / 10000 - alreadyHonored;
        }
    }

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or JADE) to the DAO
     *  @return bool
     */
    function recoverLostToken(address _token) external onlyOwner returns (bool) {
        require(_token != Jade);
        IERC20(_token).safeTransfer(treasury, IERC20(_token).balanceOf(address(this)));
        return true;
    }

    function payoutFor(address _token, uint256 _amount) public view returns (uint256) {
        TokenInformation memory tokenInfo = tokensInfo[_token];
        return (_amount * 1e18 * tokenInfo.priceInStable) / jadePriceInUsd / 10**tokenInfo.decimals;
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @return percentVested_ uint
     */
    function percentVestedFor(uint256 _yearNb) public view returns (uint256 percentVested_) {
        if (block.timestamp < vestingStartDate) return 0;
        uint256 daysSinceStarted = (block.timestamp - vestingStartDate) / (1 days);
        uint256 vesting = (_yearNb + 1) * 365;

        if (vesting > 0) {
            percentVested_ = (daysSinceStarted * 10000) / vesting;
        } else {
            percentVested_ = 0;
        }
        if (percentVested_ > 10000) return 10000;
    }

    function redeemAll(address _recipient, bool[4] calldata shouldRedeem) external {
        for (uint256 year; year < 4; year++) {
            if (shouldRedeem[year]) redeem(_recipient, year);
        }
    }

    function getAllPendingPayoutsFor(address _depositor)
        external
        view
        returns (uint256[4] memory pendingPayouts)
    {
        for (uint256 year; year < 4; year++) {
            pendingPayouts[year] = pendingPayoutFor(_depositor, year);
        }
    }

    function getAllHonoredPayoutsFor(address _depositor)
        external
        view
        returns (uint256[4] memory honoredPayouts)
    {
        for (uint256 year; year < 4; year++) {
            honoredPayouts[year] = bondsBought[year][_depositor].payoutHonored;
        }
    }

    function getBondsBought(address user) public view returns (uint256[4] memory bought) {
        for (uint256 year; year < 4; year++) {
            bought[year] = bondsBought[year][user].payout;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IDiamondAccounting {
    function getUserInfo(address user)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256
        );

    function lowerRemainingJLP(address _user, uint256 _amount) external;

    function jlp() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface IMintableERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}