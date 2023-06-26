// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IHamsaToken.sol";
import "./IERC20.sol";
import "./libs/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Business {
  IHamsaToken public token;
  address public originator;
  address public usdcAddress;
  address public borrower;
  address public platform;
  address[] public investors;
  enum State {
    Created,
    Booking,
    Settlement,
    Trading,
    Repaid
  }
  State public tokenStatus = State.Created;
  using SafeMath for uint256;
  uint256 public remainingRepayment; // 剩余应还本金
  uint256 public installments; // 分期期数
  mapping(address => uint256) public bookingLenders; // 意向lender和投资资金
  uint256 public totalBookingAmount;
  uint256 internal constant INTEREST_RATIO_DECIMALS = 1e6;
  struct Repayment {
    uint principal;
    uint interest;
    bool isRepayment;
  }// 本金、利息、是否已还
  mapping(uint256 => Repayment) public installmentRepayments;// 每期的还款金额和利息
  struct MarketOrder {
    address seller;
    uint256 amount;
    uint256 price;
  }// 二级市场订单结构
  MarketOrder[] public marketOrders;// 所有挂单信息
  mapping(address => uint256) public marketAmounts;// 用户挂单总量

  // 事件：链上计算的还款本金、利息、是否已还款
  event RepaymentCalcEvent(
    uint256 installment,
    uint256 principal,
    uint256 interest,
    bool isRepayment
  );
  // 还款事件：还款期数，投资者，收款利息，收款本金
  event RepaymentEvent(
    uint256 installment,
    address investor,
    uint256 interest,
    uint256 principal
  );
  // 还款事件：还款期数，originator手续费，平台管理费
  event RepaymentFeeEvent(
    uint256 installment,
    uint256 originatorFee,
    uint256 platformFee
  );
  // 出售事件：卖家，数量，价格
  event SellEvent(uint256 id, address seller, uint256 amount, uint256 price);
  // 购买事件：id,买家，卖家，数量，价格
  event BuyEvent(
    uint256 id,
    address buyer,
    address seller,
    uint256 amount,
    uint256 price
  );

  function initialize(
    address tokenAddress,
    address _platform,
    address _borrower,
    address _originator,
    address _usdcAddress
  ) external {
    require(tokenStatus == State.Created, "can only initialize once");
    require(tokenAddress != address(0), "token is zero address");
    require(_originator != address(0), "originator is zero address");
    require(_usdcAddress != address(0), "usdc is zero address");
    token = IHamsaToken(tokenAddress);
    platform = _platform;
    borrower = _borrower;
    originator = _originator;
    usdcAddress = _usdcAddress;
    tokenStatus = State.Booking;
  }

  // booking 投资人意向投资，只有在Booking状态下才能预约
  function booking(uint256 amount) public {
    require(
      tokenStatus == State.Booking,
      "can only booking when in Booking state"
    );
    require(amount > 0, "amount is less than 0");
    // 检查usdc授权金额
    IERC20 usdc = IERC20(usdcAddress);
    require(
      usdc.allowance(msg.sender, address(this)) >= amount,
      "usdc allowance is less than amount"
    );
    // booking数量不能超过剩余可booking的数量
    totalBookingAmount = totalBookingAmount.add(amount);
    require(
      totalBookingAmount <= token.balanceOf(address(this)),
      "amount is more than balance"
    );
    bookingLenders[msg.sender] = bookingLenders[msg.sender].add(amount);
    if (!this.isInvestor(msg.sender)) {
      investors.push(msg.sender);
    }
  }

  // bookingWithPermit
  function bookingWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    // 获取历史的booking金额
    IERC20Permit(usdcAddress).permit(
      msg.sender,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );
    booking(amount);
  }

  // lender反悔将usdc转回自己的账户
  function cancelBooking(address lender, uint256 amount) external {
    require(msg.sender == originator, "only originator can cancel booking");
    require(
      tokenStatus == State.Booking,
      "can only cancel booking when in Ready state"
    );
    require(
      bookingLenders[lender] >= amount,
      "bookingLenders is less than 0"
    );
    bookingLenders[lender] = bookingLenders[lender].sub(amount);
    totalBookingAmount = totalBookingAmount.sub(amount);
  }

  // settlement,将池子状态设置为Settlement，将booking的lender转入investors数组
  function settlement() external {
    require(
      tokenStatus == State.Booking,
      "can only settlement when in Booking state"
    );
    require(msg.sender == originator, "only originator can settlement");
    IERC20 usdc = IERC20(usdcAddress);
    // 遍历investors，将lender意向金额大于0的账户，转入investors数组
    // 将token转给investors，将usdc转给borrower
    for (uint256 i = 0; i < investors.length; i++) {
      if (bookingLenders[investors[i]] > 0) {
        token.transfer(investors[i], bookingLenders[investors[i]]);
        usdc.transferFrom(investors[i], address(this), bookingLenders[investors[i]]);
        remainingRepayment = remainingRepayment.add(
          bookingLenders[investors[i]]
        );
      } else {
        delete investors[i];
      }
    }
    usdc.transfer(borrower, remainingRepayment);
    tokenStatus = State.Settlement;
  }

  // 判断所有booking成员的授权金额是否大于等于booking金额，以及其余额是否大于等于booking金额
  function checkSettlement() public view {
    IERC20 usdc = IERC20(usdcAddress);
    for (uint256 i = 0; i < investors.length; i++) {
      string memory addressStr = Strings.toHexString(uint256(uint160(investors[i])), 20);
      require(usdc.allowance(investors[i], address(this)) >= bookingLenders[investors[i]], string(abi.encodePacked("investor ", addressStr, " usdc allowance is less than booking amount")));
      require(usdc.balanceOf(investors[i]) >= bookingLenders[investors[i]], string(abi.encodePacked("investor ", addressStr, " usdc balance is less than booking amount")));
    }
  }

  // 设置分期方案，每期还款本金和利息，数组长度决定了还款的期数
//  function setInstallmentRepayment(
//    uint256[] memory principals,
//    uint256[] memory interests
//  ) external {
//    require(
//      msg.sender == originator,
//      "only platform can set installment repayment"
//    );
//    require(principals.length > 0, "principals length is less than 0");
//    require(
//      principals.length == interests.length,
//      "principals and interests length is not equal"
//    );
//    uint256 totalPrincipal = 0;
//    for (uint256 i = 0; i < principals.length; i++) {
//      Repayment memory info = Repayment(principals[i], interests[i], false);
//      installmentRepayments[i + 1] = info;
//      totalPrincipal = totalPrincipal.add(principals[i]);
//    }
//    require(
//      totalPrincipal == token.totalSupply(),
//      "total principal is not equal to total supply"
//    );
//    tokenStatus = State.Trading;
//  }

  // 让投资者挂牌出售部分token
  function sell(uint256 amount, uint256 price) external {
    require(
      tokenStatus == State.Trading,
      "can only sell when in Sold or Settlement state"
    );
    require(
      token.balanceOf(msg.sender) >= amount,
      "insufficient token balance"
    );
    require(amount > 0, "amount is less than 0");
    // 将单子挂到市场上
    MarketOrder memory order = MarketOrder(msg.sender, amount, price);
    marketOrders.push(order);
    marketAmounts[msg.sender] = marketAmounts[msg.sender].add(amount);
    // 订单id、卖家地址、挂牌数量、挂牌价格
    emit SellEvent(marketOrders.length - 1, msg.sender, amount, price);
  }

  // 买家购买挂牌的token。
  // id 为订单在marketOrders中的index
  function buy(uint256 id, uint256 amount) public {
    require(
      tokenStatus == State.Trading,
      "can only buy when in Sold or Settlement state"
    );
    MarketOrder memory order = marketOrders[id];
    require(order.seller != msg.sender, "invalid seller address");
    require(
      order.amount > 0 && order.amount >= amount,
      "seller does not have enough tokens listed for sale"
    );

    // 从买家转移USDC到卖家
    require(
      IERC20(usdcAddress).transferFrom(
        msg.sender,
        order.seller,
        amount.mul(order.price).div(1e2)
      ),
      "usdc transfer failed"
    );

    // 从卖家转移Token到买家
    require(
      token.transferFrom(order.seller, msg.sender, amount),
      "token transfer failed"
    );

    // 从卖家的总挂牌数量中减去该订单购买的数量
    marketAmounts[order.seller] = marketAmounts[order.seller].sub(amount);
    marketOrders[id].amount = marketOrders[id].amount.sub(amount);

    // 如果卖完了，删除订单
    if (marketOrders[id].amount == 0) {
      delete marketOrders[id];
    }

    // 如果买家不在投资者列表中，将其添加到投资者列表
    if (!this.isInvestor(msg.sender)) {
      investors.push(msg.sender);
    }

    // 发送买家购买事件
    emit BuyEvent(id, msg.sender, order.seller, amount, order.price);
  }

  // buyWithPermit
  function buyWithPermit(
    uint256 id,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    MarketOrder memory order = marketOrders[id];
    uint256 usdcAmount = amount.mul(order.price).div(1e2);
    IERC20Permit(usdcAddress).permit(
      msg.sender,
      address(this),
      usdcAmount,
      deadline,
      v,
      r,
      s
    );
    buy(id, amount);
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

  // 按照分期期数还款，扣除平台和originator的手续费0.1%，还完最后一期后，token标记为已还款状态。
  function repayment(uint256 installment) external {
    require(installment > 0, "invalid installment");

//    console.log("installment: %s", installment);

    // 获取当期本金和利息
    Repayment memory info = installmentRepayments[installment];
    require(!info.isRepayment, "already repaid");
//    console.log(info.principal);
//    console.log(info.interest);
    uint256 repaymentAmount = info.principal.add(info.interest);
    require(repaymentAmount > 0, "amount is less than 0");
    uint256 balance = IERC20(usdcAddress).balanceOf(address(this));
    require(balance >= repaymentAmount, "no usdc to repayment");

    // 计算实际还款金额
    uint256 actualRepaymentPrincipal = 0;

    // 扣除originator和平台的手续费，计算剩余利息
    uint256 remainingInterest = info.interest;
    if (info.interest > 0) {
      uint256 originatorFee = info.interest.mul(1).div(1000);
      uint256 platformFee = originatorFee;
      remainingInterest = remainingInterest.sub(originatorFee).sub(
        platformFee
      );
      // 将手续费转给originator和平台
      require(
        IERC20(usdcAddress).transfer(originator, originatorFee),
        "usdc transfer failed"
      );
      require(
        IERC20(usdcAddress).transfer(platform, platformFee),
        "usdc transfer failed"
      );
      emit RepaymentFeeEvent(installment, originatorFee, platformFee);
    }
    for (uint256 i = 0; i < investors.length; i++) {
      uint256 principalAmount = 0;
      uint256 interestAmount = 0;
      uint256 investorTokenBalance = token.balanceOf(investors[i]);
      if (info.principal > 0) {
        principalAmount = getAmountInRepayment(
          investorTokenBalance,
          info.principal
        );
      }
      if (remainingInterest > 0) {
        interestAmount = getAmountInRepayment(
          investorTokenBalance,
          remainingInterest
        );
      }
      uint256 totalAmount = principalAmount.add(interestAmount);
//      console.log(
//        "investor: %s, investorTokenBalance: %s",
//        investors[i],
//        investorTokenBalance
//      );
      if (principalAmount > 0) {
        token.burn(investors[i], principalAmount);
      }
      require(
        IERC20(usdcAddress).transfer(investors[i], totalAmount),
        "usdc transfer failed"
      );
      actualRepaymentPrincipal = actualRepaymentPrincipal.add(
        principalAmount
      );
      emit RepaymentEvent(
        installment,
        investors[i],
        interestAmount,
        principalAmount
      );
    }
    // 标记已还
    installmentRepayments[installment].isRepayment = true;
    // 更新剩余的应还本金
    remainingRepayment = remainingRepayment.sub(actualRepaymentPrincipal);
    if (remainingRepayment == 0) {
      tokenStatus = State.Repaid;
    }
  }

  // 计算用户按比例应获得的usdc金额。
  function getAmountInRepayment(
    uint256 investorTokenBalance,
    uint256 amount
  ) internal view returns (uint256) {
    // 向下取整
    amount = amount.add(marketAmounts[msg.sender]);
    uint256 amountInRepayment = amount.mul(investorTokenBalance).div(
      remainingRepayment
    );
    return amountInRepayment;
  }

  // 设置还款计划，利息由链上计算，支持提前还款和改变还款利率，本金最后还。
  // dayArray 计息天数，数组长度为期数，数组内容为天数，如[6,30,31,30]表示第一期6天，第二期30天，第三期31天，第四期30天
  // interestRate 利率，2%用20000表示，支持6位小数。
  function setRepaymentSchedule(
    uint256[] memory dayArray,
    uint256 interestRate
  ) external {
    require(
      msg.sender == originator,
      "only platform can set installment repayment"
    );
    require(dayArray.length > 0, "schedule length is less than 0");
    for (uint256 i = 0; i < dayArray.length; i++) {
      if (installmentRepayments[i.add(1)].isRepayment) {
        emit RepaymentCalcEvent(
          i.add(1),
          installmentRepayments[i.add(1)].principal,
          installmentRepayments[i.add(1)].interest,
          installmentRepayments[i.add(1)].isRepayment
        );
        continue;
      }
      uint256 interest = remainingRepayment.mul(dayArray[i]).mul(interestRate).div(INTEREST_RATIO_DECIMALS).div(360);
      Repayment memory info = Repayment(0, interest, false);
      if (i == dayArray.length.sub(1)) {
        info.principal = remainingRepayment;
      }
      installmentRepayments[i.add(1)] = info;
      emit RepaymentCalcEvent(
        i.add(1),
        installmentRepayments[i.add(1)].principal,
        installmentRepayments[i.add(1)].interest,
        installmentRepayments[i.add(1)].isRepayment
      );
    }
    tokenStatus = State.Trading;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IHamsaToken {
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

    function burn(address account, uint256 amount) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}