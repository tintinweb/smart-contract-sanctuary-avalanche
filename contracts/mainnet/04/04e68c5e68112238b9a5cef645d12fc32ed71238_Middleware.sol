/**
 *Submitted for verification at snowtrace.io on 2023-03-28
*/

// SPDX-License-Identifier: UNLICENSED
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// File: contracts/middleware.sol


pragma solidity ^0.8.9;



abstract contract VotingContract {
    function createBallot(string memory name,string[] memory _choices,uint256 offset) public virtual;
    function vote(address account, uint256 ballotId, uint256 choiceId, uint256 amount) external virtual;
}

abstract contract MembershipContract {
    function isMember(address member) virtual external view returns (bool);
    function subscribe(address member) external virtual;
    function unSubscribe(address member) external virtual;
}

abstract contract HandlerContract {
    function getTransaction(uint256 _txId) virtual external view 
        returns(address _owner, uint256 _amount, uint256 _timestamp);
    function getLockedFund(address account) virtual external view 
        returns(address _owner, uint256 _amount, uint256 _timestamp);
    function queue(address _owner, uint256 _amount) external virtual returns (uint256);
    function cancel(uint256 _txId, address _owner) external virtual returns(uint256);
    function execute(uint256 _txId) external virtual returns(address, uint256);
    function withdraw(address account) external virtual returns(uint256, uint256);
}

abstract contract VeZeusContract {
    function stake(address account, uint256 amount) external virtual;
    function unStake(address account) external virtual returns(uint256);
    function withdrawVeZeus(address account) external virtual returns(uint256);
    function totalZeusStaked() external view virtual returns(uint256);
    function profitPerSecond(address account) external view virtual returns(uint256);
    function getZeusStaked(address account) external view virtual returns(uint256);
}

contract Middleware {
    using SafeMath for uint;

    address public currentBallotCreator;
    address public admin;
    address public collector = 0x67dD4EA99CE6453f28DA3b08d0257063189121e6;
    address public vzeusCollector = 0x67dD4EA99CE6453f28DA3b08d0257063189121e6;

    uint256 public waitingTime = 60; //1 minute pending time
    uint256 public maxDeposit = 2;
    uint256 public minDeposit = 1;
    uint256 public lastRun;
    mapping(address => uint256) public lastInit;
    uint256[4] public lockupPayoutPercentages = [60,70, 80];
    mapping(address => uint256) public timeBeforeStaking;
    mapping(address => uint256) public userLatestTxId;

    address public votingContractAddress;
    address public membershipContractAddress;
    address public handlerContractAddress;
    address public veZeusContractAddress;
    VotingContract votingContract;
    MembershipContract membershipContract;
    HandlerContract handlerContract;
    VeZeusContract veZeusContract;
    ERC20 USDC = ERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    ERC20 VEZEUS = ERC20(0x13F88dfA55fb50F9BE742869EC5f35D16d6B7a8f);
    ERC20 Zeus = ERC20(0x8C3633eE619a42d3755327C2524E4d108838c47f);

    constructor(address _votingContractAddress, address _membershipContractAddress, 
        address _handlerContractAddress, address _veContractAddress) {
        admin = msg.sender;
        votingContractAddress = _votingContractAddress;
        membershipContractAddress = _membershipContractAddress;
        handlerContractAddress = _handlerContractAddress;
        veZeusContractAddress = _veContractAddress;
        votingContract = VotingContract(_votingContractAddress);
        membershipContract = MembershipContract(_membershipContractAddress);
        handlerContract = HandlerContract(_handlerContractAddress);
        veZeusContract = VeZeusContract(_veContractAddress);
        
    }

    function updateTokens(address _usdc, address _vezeus, address _zeus) external onlyAdmin{
        USDC = ERC20(_usdc);
        VEZEUS = ERC20(_vezeus);
        Zeus = ERC20(_zeus);
    }

    function updateVotingContract(address _votingContractAddress
    ) external onlyAdmin {
        votingContractAddress = _votingContractAddress;
        votingContract = VotingContract(_votingContractAddress);
    }

    function updateMembershipContract(address _membershipContractAddress
    ) external onlyAdmin {
        membershipContractAddress = _membershipContractAddress;
        membershipContract = MembershipContract(_membershipContractAddress);
    }

    function updateHandlerContract(address _handlerContractAddress
    ) external onlyAdmin {
        handlerContractAddress = _handlerContractAddress;
        handlerContract = HandlerContract(_handlerContractAddress);
    }

    function updateVeZeusContract(address _veContractAddress
    ) external onlyAdmin {
        veZeusContractAddress = _veContractAddress;
        veZeusContract = VeZeusContract(_veContractAddress);
    }

    function totalZeusStaked() external view returns(uint256) {
        return veZeusContract.totalZeusStaked();
    }

    function totalVeZeusReward(address account) external view returns(uint256) {
        return veZeusContract.profitPerSecond(account);
    }

     function getZeusStaked(address account) external view returns(uint256) {
        return veZeusContract.getZeusStaked(account);
    }

    function initialize(uint256 amount) external {
        address account = msg.sender;
        uint256 _lastInit = lastInit[account];
        uint256 diff = lastRun - _lastInit;
        if(lastRun > 0 && _lastInit > 0){
            require(lastRun > _lastInit && diff >= 60, "Queue:Existing data"); //prevent multiple queing by users
        }
        uint256 waitTime = timeBeforeStaking[account];
        require(block.timestamp >= waitTime + 180, "Interval error"); //User can only trigger staking every 3 minutes
        require(amount >= minDeposit, "min:Amount not within constraint");
        require(account != address(0), "Invalid address");
        uint256 usdcAmount = amount.mul(10**6);
        USDC.transferFrom(account, collector, usdcAmount);
         //ensure user has not exceeded max stake amount
        (,uint256 _amount,) = handlerContract.getLockedFund(account);
        require(_amount+amount <= maxDeposit, "max:Amount not within constraint");
        uint256 txnId = handlerContract.queue(account, amount);
        userLatestTxId[account] = txnId;
        timeBeforeStaking[account] = block.timestamp;
        lastInit[account] = block.timestamp;
    }

    function userUsdcStaked(address account) external view returns(uint256){
        (,uint256 amount,) = handlerContract.getLockedFund(account);
        return amount;
    }

    function stake(uint256 amount) external {
        address account = msg.sender;
        bool isMember = membershipContract.isMember(account);
        require(amount > 0, "Invalid amount");
        require(isMember, "Not subscribed");
        uint256 zeusAmount = amount.mul(10**18);
        Zeus.transferFrom(account, collector, zeusAmount);
        veZeusContract.stake(account, amount);

    }

     function unStake() external {
        address account = msg.sender;
        uint256 amount = veZeusContract.unStake(account);
        uint256 zeusAmount = amount * 10**18;
        Zeus.transferFrom(collector, account, zeusAmount);
    }

    function subscribed(address account) external view returns(bool){
        return membershipContract.isMember(account);
    }

    function vote(uint ballotId, uint256 choiceId, uint256 amount) external {
        address account = msg.sender;
        bool isMember = membershipContract.isMember(account);
        require(isMember, "Not subscribed");
        uint256 veZeusAmount = amount.mul(10**18);
        VEZEUS.transferFrom(account, vzeusCollector, veZeusAmount);
        votingContract.vote(account,ballotId,choiceId,amount);
    }

    function cancelTransaction(uint256 _txId) public {
        address account = msg.sender;
        uint256 amount = handlerContract.cancel(_txId, account);
        uint256 usdcAmount = amount.mul(10**6);
        USDC.transferFrom(collector, account, usdcAmount);
        lastInit[account] = lastRun - 60;
    }

    function executeTransaction(uint256[] memory _txIds) public {
        for(uint256 i = 0; i < _txIds.length; i++){
            (address account,) = handlerContract.execute(_txIds[i]);
            membershipContract.subscribe(account);
        }
        lastRun = block.timestamp;
    }

    function updateCollector(address _collector) external onlyAdmin{
        collector = _collector;
    }

    function withdrawUSDC() external {
        address account = msg.sender;
        (uint256 amount, uint256 timestamp) = handlerContract.withdraw(account);
        uint256 usdcAmount = amount.mul(10**6);
        uint256 payableAmount;
        if(block.timestamp < (timestamp + 30 days)) {
            payableAmount = usdcAmount - (lockupPayoutPercentages[0].div(100) * usdcAmount);
        }
        if(block.timestamp >= timestamp.add(30 days) && block.timestamp < timestamp.add(60 days)){
            payableAmount = usdcAmount - (lockupPayoutPercentages[1].div(100) * usdcAmount);
        }
        if(block.timestamp >= timestamp.add(60 days) && block.timestamp < timestamp.add(90 days)){
            payableAmount = usdcAmount - (lockupPayoutPercentages[2].div(100) * usdcAmount);
        }
        if(block.timestamp >= timestamp.add(90 days)){
            payableAmount = usdcAmount;
        }
        
        USDC.transferFrom(collector, account, payableAmount);
        membershipContract.unSubscribe(account);
    }

    function withdrawVEZEUS() external {
        address account = msg.sender;
        uint256 amount = veZeusContract.withdrawVeZeus(account);
        VEZEUS.transferFrom(collector, account, amount);
    }

    function getAccountTransactions(uint256 _txId) view public 
        returns(address _owner, uint256 _amount, uint256 _timestamp){
        return handlerContract.getTransaction(_txId);
    }

    function setCurrentBallotCreator(address _creator) external onlyAdmin {
        currentBallotCreator = _creator;
    }

    function setMaxAndMinDeposit(uint256 max, uint256 min) external onlyAdmin{
        maxDeposit = max;
        minDeposit = min;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized");
        _;
    }
    modifier ballotCreator(){
        require(msg.sender == admin || msg.sender == currentBallotCreator, "unauthorized");
        _;
    }
}