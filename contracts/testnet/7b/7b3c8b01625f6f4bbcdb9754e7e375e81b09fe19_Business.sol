// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./HamsaToken.sol";
import "./IERC20.sol";
import "./libs/SafeMath.sol";

contract Business {
  HamsaToken public token;
  address public originator;
  address public usdcAddress;
  address[] public investors;
  enum State {Created, Initialized, Ready, Booking, Settlement, Trading, Repaid}
  State public tokenStatus = State.Created;
  using SafeMath for uint256;
  uint256 public remainingRepayment; // 剩余应还本金
  uint256 public installments; // 分期期数
  mapping(address => uint256) public bookingLenders;   // 意向lender和投资资金
  mapping(address => uint256) public listingTokens; // 保存挂牌出售的token信息

  struct Repayment {
    uint principal;
    uint interest;
  }

  mapping(uint256 => Repayment) public installmentRepayments; // 每期的还款金额和利息

  function initialize(
    address tokenAddress,
    address _originator,
    address _usdcAddress
  ) external {
    require(tokenStatus == State.Created, "can only initialize once");
    require(tokenAddress != address(0), "token is zero address");
    require(_originator != address(0), "originator is zero address");
    require(_usdcAddress != address(0), "usdc is zero address");
    token = HamsaToken(tokenAddress);
    originator = _originator;
    usdcAddress = _usdcAddress;
    tokenStatus = State.Initialized;
  }

  // booking 投资人意向投资，只有在Ready状态下才能预约
  function booking(uint256 amount) public {
    require(tokenStatus == State.Ready, "can only booking when in Ready state");
    require(amount > 0, "amount is less than 0");
    // 将usdc转入business合约
    IERC20 usdc = IERC20(usdcAddress);
    usdc.transferFrom(msg.sender, address(this), amount);
    bookingLenders[msg.sender] = amount;
    investors.push(msg.sender);
  }

  // lender反悔将usdc转回自己的账户
  function cancelBooking(uint256 amount) external {
    require(tokenStatus == State.Ready, "can only cancel booking when in Ready state");
    require(bookingLenders[msg.sender] >= amount, "bookingLenders is less than 0");
    // 将amount usdc转入business合约
    IERC20 usdc = IERC20(usdcAddress);
    usdc.transfer(msg.sender, amount);
    bookingLenders[msg.sender] = bookingLenders[msg.sender].sub(amount);
  }

  // settlement,将池子状态设置为Settlement，将booking的lender转入investors数组
  function settlement() external {
    require(tokenStatus == State.Booking, "can only settlement when in Booking state");
    require(msg.sender == originator, "only originator can settlement");
    IERC20 usdc = IERC20(usdcAddress);
    // 遍历investors，将lender意向金额大于0的账户，转入investors数组
    // 将token转给investors，将usdc转给originator
    for (uint256 i = 0; i < investors.length; i++) {
      if (bookingLenders[investors[i]] > 0) {
        token.transfer(address(this), bookingLenders[investors[i]]);
        usdc.transfer(originator, bookingLenders[investors[i]]);
        remainingRepayment = remainingRepayment.add(bookingLenders[investors[i]]);
      }else{
        delete investors[i];
      }
    }
    tokenStatus = State.Settlement;
  }

  // 设置分期方案，每期还款本金和利息，数组长度决定了还款的期数
  function setInstallmentRepayment(uint256[] memory principals, uint256[] memory interests) external {
    require(tokenStatus == State.Settlement, "can only set installment repayment when in Settlement state");
    require(msg.sender == originator, "only originator can set installment repayment");
    require(principals.length > 0, "principals length is less than 0");
    require(principals.length == interests.length, "principals and interests length is not equal");
    uint256 totalPrincipal = 0;
    for (uint256 i = 0; i < principals.length; i++) {
      Repayment memory info = Repayment(principals[i], interests[i]);
      installmentRepayments[i + 1] = info;
      totalPrincipal = totalPrincipal.add(principals[i]);
    }
    require(totalPrincipal == token.totalSupply(), "total principal is not equal to total supply");
  }

  // 让投资者挂牌出售部分token
  function sell(uint256 amount) external {
    require(tokenStatus == State.Trading, "can only sell when in Sold or Settlement state");
    require(token.balanceOf(msg.sender) >= amount, "insufficient token balance");

    // 更新挂牌出售的token数量
    listingTokens[msg.sender] = listingTokens[msg.sender].add(amount);
  }

  // 通过卖家的地址购买token,价格1:1
  function buy(address seller) external {
    require(tokenStatus == State.Trading, "can only buy when in Sold or Settlement state");
    require(seller != address(0) && seller != msg.sender, "invalid seller address");
    require(listingTokens[seller] > 0, "seller does not have enough tokens listed for sale");

    // 获取卖家挂牌出售的token数量
    uint256 amount = listingTokens[seller];

    // 从买家转移USDC到卖家
    require(
      IERC20(usdcAddress).transferFrom(msg.sender, seller, amount),
      "usdc transfer failed"
    );

    // 从卖家转移Token到买家
    require(token.transferFrom(seller, msg.sender, amount), "token transfer failed");

    // 更新挂牌出售的token数量
    listingTokens[seller] = listingTokens[seller].sub(amount);

    // 如果买家不在投资者列表中，将其添加到投资者列表
    if (!this.isInvestor(msg.sender)) {
      investors.push(msg.sender);
    }
  }

  // 判断investor是否已经投资过
  function isInvestor(address investor) external view returns (bool) {
    for (uint256 i = 0; i < investors.length; i++) {
      if (investors[i] == investor) {
        return true;
      }
    }
    return false;
  }

  // 按照分期期数还款，还完最后一期后，token标记为已还款状态。
  function repayment(uint256 installment) external {
    require(msg.sender == originator, "only originator can repayment");
    require(installment > 0 && installmentRepayments[installment].principal > 0, "invalid installment");

    // 获取当期本金和利息
    Repayment memory info = installmentRepayments[installment];
    uint256 repaymentAmount = info.principal.add(info.interest);
    require(repaymentAmount > 0, "amount is less than 0");
    uint256 balance = IERC20(usdcAddress).balanceOf(address(this));
    require(balance >= repaymentAmount, "no usdc to repayment");

    // 计算实际还款金额
    uint256 actualRepaymentPrincipal = 0;

    for (uint256 i = 0; i < investors.length; i++) {
      uint256 investorTokenBalance = token.balanceOf(investors[i]);
      uint256 principalAmount = getAmountInRepayment(investorTokenBalance, info.principal);
      uint256 interestAmount = getAmountInRepayment(investorTokenBalance, info.interest);
      uint256 totalAmount = principalAmount.add(interestAmount);
      uint256 allowance = token.allowance(investors[i], address(this));
      require(allowance >= principalAmount, "token allowance is less than investor amount");
      token.burn(investors[i], principalAmount);
      require(
        IERC20(usdcAddress).transfer(investors[i], totalAmount),
        "usdc transfer failed"
      );
      actualRepaymentPrincipal = actualRepaymentPrincipal.add(principalAmount);
    }

    // 更新剩余的应还本金
    remainingRepayment = remainingRepayment.sub(actualRepaymentPrincipal);

    // 清除已还款分期款项
    delete installmentRepayments[installment];

    if (remainingRepayment == 0) {
      tokenStatus = State.Repaid;
    }
  }


  // 计算用户按比例应获得的usdc金额。
  function getAmountInRepayment(uint256 investorTokenBalance, uint256 amount) internal view returns (uint256) {
    // 向下取整
    uint256 amountInRepayment = amount.mul(investorTokenBalance).div(remainingRepayment);
    return amountInRepayment;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract HamsaToken is ERC20 {
    address owner;
    uint256 public nativeId;

    constructor(address _owner, uint256 _nativeId, uint256 _totalSupply)
        ERC20("HamsaToken", "Hamsa")
    {
        require(_owner != address(0), "Owner is zero address");
        require(_totalSupply > 0, "totalSupply is less than 0");
        require(_nativeId > 0, "nativeId is less than 0");
        nativeId = _nativeId;
        owner = _owner;
        _setupDecimals(6);
        _mint(owner, _totalSupply);
    }

    // 重新erc20 burn方法, business有权限调用
    function burn(address account ,uint256 amount) public virtual {
        require(msg.sender == owner, "only owner can burn");
        require(amount > 0, "amount is less than 0");
        _burn(account, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "./Context.sol";
import "./IERC20.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
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