/**
 *Submitted for verification at snowtrace.io on 2022-06-30
*/

// File: contracts/prize/AAVELending/AAVEInterfaces.sol



pragma solidity 0.7.5;

interface AAVELendingPool {
    // balance is erc20
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

interface AAVERewards {
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);
}


// File: contracts/extensions/Reentrancy.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity 0.7.5;

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
// File: interfaces/IExchangeBridge.sol



pragma solidity 0.7.5;

interface IExchangeBridge {
    function exchangeExactTokensForTokens(uint256 amount, address sourceToken, address targetToken) external;
    function exchangeExactTokensForAVAX(uint256 amount, address sourceToken) external;
}

// File: interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.7.5;

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

    function permit(address owner, address spender, uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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
    function mint(address account, uint rawAmount) external;
    function burn(address account, uint rawAmount) external;
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

// File: libraries/math/LowGasSafeMath.sol



pragma solidity 0.7.5;

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "add uint256 overflow");
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x, "add32 uint32 overflow");
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub uint256 overflow");
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x, "sub32 uint32 overflow");
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y, "mul uint256 overflow");
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0), "add int256 overflow");
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0), "sub int256 overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "division by 0");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
// File: contracts/prize/AAVELending/AAVERewardsBridge.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;






contract AAVERewardsBridge is ReentrancyGuard {
    using LowGasSafeMath for uint256;

    IExchangeBridge private constant exchangeBridge = IExchangeBridge(0x2498d70E4a2ED018EEB092101A24827fdfCE7C13);
    AAVERewards private constant rewardsDistributor = AAVERewards(0x929EC64c34a17401F460460D4B9390518E5B473e); 
    IERC20 private constant wavax = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    //must be called with delegated call
    function claimRewardsInTargetToken(address aaveasset, address targetToken) external nonReentrant returns (uint256) {

        uint256 balanceBefore = wavax.balanceOf(address(this));
        // atokens list
        address[] memory assets = new address[](1);
        assets[0] = aaveasset;
        rewardsDistributor.claimRewards(assets, uint256(-1), address(this), address(wavax));
        uint256 balanceAfter = wavax.balanceOf(address(this));
        uint256 balanceTotalToConvert = balanceAfter.sub(balanceBefore);
    
        if (targetToken == address(wavax)) {
            return balanceTotalToConvert;
        }

        // very small amounts cause output errors from joe router
        if (balanceTotalToConvert < 1) {
            return 0;
        }

        wavax.transfer(address(exchangeBridge), balanceTotalToConvert);
        IERC20 targetTokenERC20 = IERC20(targetToken);
        uint256 targetTokenBalanceBefore = targetTokenERC20.balanceOf(address(this));
        exchangeBridge.exchangeExactTokensForTokens(balanceTotalToConvert, address(wavax), targetToken);
        uint256 targetTokenBalanceAfter = targetTokenERC20.balanceOf(address(this));

        return targetTokenBalanceAfter.sub(targetTokenBalanceBefore);
    }
}