/**
 *Submitted for verification at snowtrace.io on 2022-03-30
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

/**
 *  @title  DAO Manager Interface
 *
 *  @author 420 DAO Team
 *
 *  @notice Interface of `DaoManager` to be used commonly by multiple other smart contracts.
 *  @notice This interface includes function to get these global properties of the DAO:
 *          - Admin address of the DAO
 *          - Current day
 *          - New tokens emission termination
 *          - Migration status
 */
interface IDaoManager {
    /**
     *  @notice Get the the admin address of the DAO.
     */
    function admin() external view returns (address);

    /**
     *  @notice Get the current day of the DAO.
     */
    function day() external view returns (uint256);

    /**
     *  @notice Check if the DAO has stopped emitting new tokens.
     *
     *  @dev    Once the total supply of Token 420 surpasses the maximum cap, the DAO will stop minting or emitting any
     *          new tokens. Thenceforth, users won't be able to deposit or receive staking rewards anymore.
     */
    function emissionTerminated() external view returns (bool);

    /**
     *  @dev    In order to migrate the DAO system, two stages must be taking place sequentially:
     *          1. Admin switches the DAO state from normal to preparative. The entire community can notice it is the
     *          last day running on the current system as the function `isGoingToMigrate()` will be returning true.
     *          2. When that last auction is ended, the DAO state will be switched from preparative to migrated and the
     *          current system will be frozen permanently. Every method on the old DAO will be blocked and replaced by
     *          new ones on a new DAO with one exception which is the function `withdraw()` of `AuctionManager` can
     *          still be called by users to collect the remaining tokens from ended auctions.
     */

    /**
     *  @notice Check if the DAO is preparing for migration.
     */
    function isGoingToMigrate() external view returns (bool);

    /**
     *  @notice Check if the migration has been done and DAO is blocked permanently.
     */
    function isBlockedForMigration() external view returns (bool);

}

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library MulDiv {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the preconditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

/**
 *  @title  Fixed
 *
 *  @author 420 DAO Team
 *
 *  @notice This struct displays a unsigned fixed-point decimal number.
 */
struct Fixed {
    /**
     *  @dev    The property `value` has 256 bits whose 128 first bits contain the integer part and 128 last bits contain
     *          the fractional part. In other words, `value` will be the truncation of the original decimal times 2^128.
     *  @dev    Its integer part can't also be greater than 2^128.
     */
    uint256 value;
}

/**
 *  @title  Fixed Math
 *
 *  @author 420 DAO Team
 *
 *  @notice This library provides basic operators of `Fixed` utilizing the library `MulDiv`.
 *
 *  @dev    Any of these function can cause revert if the result exceeds `Fixed` boundary.
 */
library FixedMath {
    /**
     *  @notice Quotient of `Fixed`.
     *
     *  @dev    Q = 2^128.
     */
    uint256 private constant Q = 0x100000000000000000000000000000000;

    /**
     *  @notice Get number 1 as `Fixed`.
     *
     *  @dev    Its `value` is equal to `Q`.
     */
    function one() internal pure returns (Fixed memory) {
        return Fixed(Q);
    }

    /**
     *  @notice Get `Fixed` instance of an `uint256`.
     */
    function intToFixed(uint256 _x) internal pure returns (Fixed memory) {
        return Fixed(_x * Q);
    }

    /**
     *  @notice Get truncated value from a `Fixed`.
     */
    function fixedToInt(Fixed memory _x) internal pure returns (uint256) {
        return _x.value / Q;
    }

    /**
     *  @notice Comparison
     *
     *  @dev    Comparison  Result
     *          x < y       -1
     *          x = y       0
     *          x > y       1
     */
    function compare(Fixed memory _x, Fixed memory _y) internal pure returns (int256) {
        if (_x.value < _y.value) return -1;
        if (_x.value > _y.value) return 1;
        return 0;
    }

    /**
     *  @notice Addition
     */
    function add(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value + _b.value);
    }

    /**
     *  @notice Subtraction
     */
    function subtract(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value - _b.value);
    }

    /**
     *  @notice Multiplication
     */
    function multiply(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(MulDiv.mulDiv(_a.value, _b.value, Q));
    }

    function multiply(Fixed memory _a, uint256 _b) internal pure returns (Fixed memory) {
        return Fixed(_a.value * _b);
    }

    function multiply(uint256 _a, Fixed memory _b) internal pure returns (Fixed memory) {
        return Fixed(_a * _b.value);
    }

    function multiplyTruncating(Fixed memory _a, uint256 _b) internal pure returns (uint256) {
        return MulDiv.mulDiv(_a.value, _b, Q);
    }

    function multiplyTruncating(uint256 _a, Fixed memory _b) internal pure returns (uint256) {
        return MulDiv.mulDiv(_a, _b.value, Q);
    }

    /**
     *  @notice Division
     */
    function divide(Fixed memory _a, Fixed memory _b) internal pure returns (Fixed memory) {
        require(_b.value != 0, "FixedMath: Division by zero.");
        return Fixed(MulDiv.mulDiv(_a.value, Q, _b.value));
    }

    function divide(uint256 _a, uint256 _b) internal pure returns (Fixed memory) {
        require(_b != 0, "FixedMath: Division by zero.");
        return Fixed(MulDiv.mulDiv(_a, Q, _b));
    }

    function divide(Fixed memory _a, uint256 _b) internal pure returns (Fixed memory) {
        require(_b != 0, "FixedMath: Division by zero.");
        return Fixed(_a.value / _b);
    }
}

/**
 *  @title  Staking Pool Interface
 *
 *  @author 420 DAO Team
 *
 *  @notice Interface of `StakingPool` to be used in `TokenS420`.
 *  @notice This interface includes functions:
 *          - Get the address of the DAO manager
 *          - Convert between discount factors and staking tokens
 *          - Transfer all token 420 to a new Staking Pool in case of migration
 */
interface IStakingPool {
    /**
     *  @notice Get the address of the DAO Manager.
     */
    function daoAddress() external view returns (address);

    /**
     *  @notice Convert an token amount to the corresponding amount of discount factor.
     */
    function tokenToDiscountFactor(uint256 _token) external view returns (Fixed memory);

    /**
     *  @notice Convert an amount of discount factor to the corresponding token amount.
     */
    function discountFactorToToken(Fixed memory _discountFactor) external view returns (uint256);

    /**
     *  @notice Transfer all token 420 belongs to the current Staking Pool to a new one in case of migration.
     */
    function upgradeTo(address _newAddress) external;
}

/**
 *  @title  Constant
 *
 *  @author 420 DAO Team
 *
 *  @notice This library provides most of constants used in smart contracts among the project.
 */
library Constant {
    /**
     *  @notice Refer to how divisible one token 420 or s420 can be.
     */
    uint8   internal constant TOKEN_DECIMALS = 18;
    uint256 internal constant TOKEN_SCALE = 10**TOKEN_DECIMALS;

    /**
     *  @notice Once total supply surpassed this threshold, auction will stop permanently.
     *          The threshold is 420 million tokens.
     */
    uint256 internal constant TOKEN_MAX_SUPPLY_THRESHOLD = 420000000 * TOKEN_SCALE;

    /**
     *  @notice Cash come to the Treasury are split as following:
     *          - Asset Fund:     50%
     *          - Insurance Fund: 30%
     *          - Operation Fund: 20%
     */
    uint256 internal constant TREASURY_PERCENTAGE_ASSET     = 50;
    uint256 internal constant TREASURY_PERCENTAGE_INSURANCE = 30;

    /**
     *  @notice Tokens come to the Mirror Pool are split as following:
     *          - Development & Marketing: 30%
     *          - Early Supporters:        10%
     *          - Reservation:             60%
     */
    uint256 internal constant MIRROR_PERCENTAGE_EARLY_SUPPORTERS = 10;
    uint256 internal constant MIRROR_PERCENTAGE_RESERVATION      = 60;

    /**
     *  @notice Formula of the staking fee: (1 - i / 787) * 42%
     */
    uint256 internal constant STAKING_FEE_CONVERGENCE_DAY = 787;
    uint256 internal constant STAKING_FEE_BASE_PERCENTAGE = 42;

    /**
     *  @notice Formula of the soft floor price in auctions: 2 * A / Q / 80%
     *          80% is sum of asset fund percentage and insurance fund percentage in the Treasury.
     */
    uint256 internal constant AUCTION_SOFT_FLOOR_PRICE_COEFFICIENT = 200;

    /**
     *  @notice The maximum tokens sold and the maximum cash a member of the whitelist can pay to buy during the
     *          whitelist campaign.
     */
    uint256 public constant WHITELIST_TOKEN_AMOUNT = 50000;
    uint256 public constant WHITELIST_MAX_CASH = 500;
}

/**
 *  @title  Double Halving
 *
 *  @author 420 DAO Team
 *
 *  @notice This library defines the mechanism of each token inflation phase of the DAO. There are 5 phases. The first
 *          phase lasts 420 days, emits at most 100,000 tokens in each auction and rewards at most 220,000 tokens (not
 *          including fee) for stakeholders each day. The next 3 phases sequentially remains half in duration, auction
 *          emission and staking reward, compared to each previous one. The fifth phase has the same auction emission
 *          and staking reward as the fourth but lasts as long as the total supply has never surpassed the maximum
 *          threshold.
 *  @notice Despite having a difference in staking fee, the fourth phase and the fifth phases can be considered the same
 *          for the implementation here.
 */
library DoubleHalving {
    /**
     *  @notice The last date of each phase.
     *          Phase   Duration    Last date
     *          1       420         420
     *          2       210         630
     *          3       105         735
     */
    uint256 internal constant PHASE_1 =  420;
    uint256 internal constant PHASE_2 =  630;
    uint256 internal constant PHASE_3 =  735;

    /**
     *  @notice The maximum token amount emitted to each auction.
     */
    uint256 internal constant AUCTION_EMISSION_1 = 100000;
    uint256 internal constant AUCTION_EMISSION_2 =  50000;
    uint256 internal constant AUCTION_EMISSION_3 =  25000;
    uint256 internal constant AUCTION_EMISSION_4 =  12500;

    /**
     *  @notice The maximum amount of staking reward each day.
     */
    uint256 internal constant STAKING_REWARD_1 = 220000;
    uint256 internal constant STAKING_REWARD_2 = 110000;
    uint256 internal constant STAKING_REWARD_3 =  55000;
    uint256 internal constant STAKING_REWARD_4 =  27000;

    /**
     *  @notice Get the maximum auction emission and the staking reward of a certain day.
     *          Type: tuple(int, int)
     *          Usage: DaoManager
     *
     *          Name    Meaning
     *  @param  _day    The day to query with
     */
    function tokenInflationOf(uint256 _day) internal pure returns (uint256, uint256) {
        if (_day <= PHASE_1) return (AUCTION_EMISSION_1 * Constant.TOKEN_SCALE, STAKING_REWARD_1 * Constant.TOKEN_SCALE);
        if (_day <= PHASE_2) return (AUCTION_EMISSION_2 * Constant.TOKEN_SCALE, STAKING_REWARD_2 * Constant.TOKEN_SCALE);
        if (_day <= PHASE_3) return (AUCTION_EMISSION_3 * Constant.TOKEN_SCALE, STAKING_REWARD_3 * Constant.TOKEN_SCALE);
        return (AUCTION_EMISSION_4 * Constant.TOKEN_SCALE, STAKING_REWARD_4 * Constant.TOKEN_SCALE);
    }
}

/**
 *  @title  Formula
 *
 *  @author 420 DAO Team
 *
 *  @notice Each function of this library is the implementation of a featured mathematical formula used in the system.
 */
library Formula {
    using FixedMath for Fixed;
    using FixedMath for uint256;

    /**
     *  @notice Calculate the truncated value of a certain portion of an integer amount.
     *          Formula:    truncate(x / y * a)
     *          Type:       int
     *          Usage:      AuctionManager, MirrorPool, TreasuryManager
     *
     *  @dev    The proportion (x / y) must be less than or equal to 1.
     *
     *          Name    Symbol  Type    Meaning
     *  @param  _x      x       int     Numerator of the proportion
     *  @param  _y      y       int     Denominator of the proportion
     *  @param  _a      a       int     Whole amount
     */
    function portion(uint256 _x, uint256 _y, uint256 _a) internal pure returns (uint256 res) {
        require(_x <= _y, "Formula: The proportion must be less than or equal to 1.");
        Fixed memory proportion = _x.divide(_y);
        res = _a.multiplyTruncating(proportion);
    }

    /**
     *  @notice Calculate the staking fee rate of a certain day before the fee converges and becomes unchangeable.
     *          Formula:    (1 - i / 787) * 42%
     *          Type:       dec
     *          Usage:      StakingPool
     *
     *  @dev    The day (i) must be less than or equal to the convergent day.
     *  @dev    Constant: STAKING_FEE_CONVERGENCE_DAY = 787
     *  @dev    Constant: STAKING_FEE_BASE_PERCENTAGE = 42
     *
     *          Name    Symbol  Type    Meaning
     *  @param  _day    i       int     integer Day to calculate fee
     */
    function earlyFeeRate(uint256 _day) internal pure returns (Fixed memory res) {
        require(
            _day <= Constant.STAKING_FEE_CONVERGENCE_DAY,
            "Formula: The day is greater than the convergent day."
        );
        // (1 - i / 787) * 42% = (787 - i) * 42 / 78700
        res = FixedMath.divide(
            (Constant.STAKING_FEE_CONVERGENCE_DAY - _day) * Constant.STAKING_FEE_BASE_PERCENTAGE,
            Constant.STAKING_FEE_CONVERGENCE_DAY * 100
        );
    }

    /**
     *  @notice Calculate the accumulated interest rate in the staking pool when an amount of staking reward is emitted.
     *          Formula:    P * (1 + r / a)
     *          Type:       dec
     *          Usage:      StakingPool
     *
     *          Name                    Symbol  Type    Meaning
     *  @param  _productOfInterestRate  P       dec     Accumulated interest rate in the staking pool
     *  @param  _reward                 r       int     Staking reward
     *  @param  _totalCapital           a       int     Total staked capital
     */
    function newProductOfInterestRate(
        Fixed memory _productOfInterestRate,
        uint256 _reward,
        uint256 _totalCapital
    ) internal pure returns (Fixed memory res) {
        Fixed memory interestRate = FixedMath.one().add(_reward.divide(_totalCapital));
        res = _productOfInterestRate.multiply(interestRate);
    }

    /**
     *  @notice Calculate the minimum price of token that the auction must surpass to emit maximum token of the day.
     *          Formula:    2 * A / Q / 80%
     *          Type:       int
     *          Usage:      StakingPool
     *
     *  @dev    Constant: AUCTION_SOFT_FLOOR_PRICE_COEFFICIENT = 200
     *  @dev    Constant: TREASURY_PERCENTAGE_ASSET = 50
     *  @dev    Constant: TREASURY_PERCENTAGE_INSURANCE = 30
     *
     *          Name            Symbol  Type    Meaning
     *  @param  _communityAsset A       int     Total value of the asset fund and the insurance fund in the treasury
     *  @param  _totalSupply    Q       int     Total circulating supply of the token
     */
    function softFloorPrice(
        uint256 _communityAsset,
        uint256 _totalSupply
    ) internal pure returns (Fixed memory res) {
        if (_totalSupply == 0) return Fixed(0);
        // 2 * A / Q / 80% = (200 * A) / (80 * Q)
        res = FixedMath.divide(
            Constant.AUCTION_SOFT_FLOOR_PRICE_COEFFICIENT * _communityAsset,
            (Constant.TREASURY_PERCENTAGE_ASSET + Constant.TREASURY_PERCENTAGE_INSURANCE) * _totalSupply
        );
    }
}

/**
 *  @title  Permission
 *
 *  @author 420 DAO Team
 *
 *  @notice This abstract contract provides a modifier to restrict the permission of functions.
 */
abstract contract Permission {
    modifier permittedTo(address _account) {
        require(msg.sender == _account, "Permission: Unauthorized.");
        _;
    }
}

/**
 *  @title  Token S420
 *
 *  @author 420 DAO Team
 *
 *  @notice Token 420 is fully conformed to the ERC-20 with the remarkable feature of globally inflating the balance of
 *          each token owner.
 *          The token is integrated with the Staking Pool as well as the whole 420 DAO system.
 *
 *  @dev    This contract derives from the implementation of ERC-20 of OpenZeppelin.
 */
contract TokenS420 is ERC20, Permission {
    IStakingPool public pStaking;

    /**
     *  @notice The significant intrinsic value of each address represents its stake in the whole circulating supply of
     *          the token. The distribution of token balances among addresses are proportional to their discount
     *          factors. The ratio between the discount factor and the real balance is the accumulated of the interest
     *          rate from the Staking Pool.
     */
    mapping(address => Fixed) public discountFactors;

    /**
     *  @notice Total minted discount factor.
     */
    Fixed public totalDiscountFactor;

    event StakingPoolRegistration(address indexed account);
    event StakingPoolUpgrade(address indexed oldAddress, address indexed newAddress);
    event DiscountFactorTransfer(address indexed from, address indexed to, Fixed value);
    event DiscountFactorMint(address indexed account, Fixed value);
    event DiscountFactorBurn(address indexed account, Fixed value);

    /**
     *  @dev    Apply the constructor of the superclass contract `ERC20`.
     *          Name:     "Stake s420"
     *          Symbol:   "s420"
     */
    constructor() ERC20("Stake s420", "s420") {}

    /**
     *  @notice Register a DAO Manager for some restricted function.
     *
     *  @dev    This can only be called once.
     */
    function registerStakingPool() external {
        require(address(pStaking) == address(0), "TokenS420: Staking Pool has already been registered.");
        pStaking = IStakingPool(msg.sender);
        emit StakingPoolRegistration(address(pStaking));
    }

    /**
     *  @notice Migrate to a new DAO Manager.
     *
     *  @dev    Only the DAO admin can call this function.
     *
     *          Name            Meaning
     *  @param  _newStakingPool Address of the new Staking Pool
     */
    function upgradeStakingPool(IStakingPool _newStakingPool) external {
        IDaoManager dao = IDaoManager(pStaking.daoAddress());
        require(msg.sender == dao.admin(), "Permission: Unauthorized.");
        require(dao.isBlockedForMigration(), "TokenS420: DAO is not ready for migration.");
        address oldAddress = address(pStaking);
        address newAddress = address(_newStakingPool);
        pStaking.upgradeTo(newAddress);
        pStaking = _newStakingPool;
        emit StakingPoolUpgrade(oldAddress, newAddress);
    }

    /**
     *  @dev    ERC-20: `decimals()`
     */
    function decimals() public pure override returns (uint8) {
        return Constant.TOKEN_DECIMALS;
    }

    /**
     *  @dev    ERC-20: `totalSupply()`
     *  @dev    The result is calculated from `totalDiscountFactor`.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return pStaking.discountFactorToToken(totalDiscountFactor);
    }

    /**
     *  @dev    ERC-20: `balanceOf(address)`
     *  @dev    The result is calculated from `discountFactors`.
     */
    function balanceOf(address _account) public view override returns (uint256) {
        return pStaking.discountFactorToToken(discountFactors[_account]);
    }

    /**
     *  @dev    ERC-20: `transfer(address, uint256)`
     *  @dev    This function actually transfers the `discountFactors`.
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        Fixed memory discountFactor = pStaking.tokenToDiscountFactor(_amount);
        _transfer(msg.sender, _recipient, discountFactor);
        emit Transfer(msg.sender, _recipient, _amount);

        return true;
    }

    /**
     *  @dev    ERC-20: `transferFrom(address, address, uint256)`
     *  @dev    This function actually transfers the `discountFactors`.
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(_sender, _recipient);
        require(currentAllowance >= _amount, "TokenS420: Transfer amount exceeds allowance.");

        // Already check overflow
        unchecked {
            _approve(_sender, msg.sender, currentAllowance - _amount);
        }

        Fixed memory discountFactor = pStaking.tokenToDiscountFactor(_amount);
        _transfer(_sender, _recipient, discountFactor);

        emit Transfer(_sender, _recipient, _amount);

        return true;
    }

    /**
     *  @notice Transfer discount factor from an address to another.
     *
     *          Name            Meaning
     *  @param  _sender         Sending address
     *  @param  _recipient      Receiving address
     *  @param  _discountFactor Transfer discount factor value
     */
    function _transfer(
        address _sender,
        address _recipient,
        Fixed memory _discountFactor
    ) internal {
        require(_sender != address(0), "TokenS420: Transfer from the zero address.");
        require(_recipient != address(0), "TokenS420: Transfer to the zero address.");

        Fixed memory senderDiscountFactor = discountFactors[_sender];
        require(
            FixedMath.compare(senderDiscountFactor, _discountFactor) > -1,
            "TokenS420: Transfer amount exceeds balance."
        );

        discountFactors[_sender] = FixedMath.subtract(discountFactors[_sender], _discountFactor);
        discountFactors[_recipient] = FixedMath.add(discountFactors[_recipient], _discountFactor);

        emit DiscountFactorTransfer(_sender, _recipient, _discountFactor);
    }

    /**
     *  @notice Mint discount factor to an account.
     *
     *  @dev    Only the Staking Pool can call this function.
     *
     *          Name            Meaning
     *  @param  _account        Address of the account that needs to mint token
     *  @param  _discountFactor Discount factor value to mint
     */
    function mintDiscountFactor(address _account, Fixed memory _discountFactor) public permittedTo(address(pStaking)) {
        require(_account != address(0), "TokenS420: Mint to the zero address");

        discountFactors[_account] = FixedMath.add(discountFactors[_account], _discountFactor);
        totalDiscountFactor = FixedMath.add(totalDiscountFactor, _discountFactor);

        emit DiscountFactorMint(_account, _discountFactor);
    }

    /**
     *  @notice Burn discount factor from an account.
     *
     *  @dev    Only the Staking Pool can call this function.
     *
     *          Name            Meaning
     *  @param  _account        Address of the account that needs to burn token
     *  @param  _discountFactor Discount factor value to to burn
     */
    function burnDiscountFactor(address _account, Fixed memory _discountFactor) public permittedTo(address(pStaking)) {
        require(_account != address(0), "TokenS420: Burn from the zero address.");

        Fixed memory accountDiscountFactor = discountFactors[_account];
        require(
            FixedMath.compare(accountDiscountFactor, _discountFactor) > -1,
            "TokenS420: Transfer amount exceeds balance."
        );

        discountFactors[_account] = FixedMath.subtract(discountFactors[_account], _discountFactor);
        totalDiscountFactor = FixedMath.subtract(totalDiscountFactor, _discountFactor);

        emit DiscountFactorBurn(_account, _discountFactor);
    }
}