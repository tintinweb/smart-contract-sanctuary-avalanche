/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-24
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
// File: BeetradeOrderbook.sol

pragma solidity >=0.5.0;



contract BeeTradeOrderbook {
    using SafeMath for uint256;

    address public admin; // the admin address
    uint256 public fee; //percentage times (1 ether)
    address public feesAccount; //the account that will receive fees
    address public tradesAccount; // the address that can execute trades
    address AVAX = address(0); // using the zero address to represent avax token

    mapping (address => mapping (address => uint256)) public tokensBalances; // mapping of token addresses to mapping of account balances (token=0 means Ether)

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    
    event Trade(
        address indexed maker,
        address indexed taker,
        uint256 amountGet, 
        uint256 amountGive,
        string makeOrderID,
        string takeOrderID,
        string indexed pair,
        uint256 price
    );

    constructor(uint256 _fee){
        admin = msg.sender;
        fee = _fee; 
        feesAccount = msg.sender; 
        tradesAccount = msg.sender;

    }

    function setAdmin(address _newAdmin) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        admin = _newAdmin;
    }

    function setFees(uint256 _newFee) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        fee = _newFee;
    }

    function setFeesAccount(address _feesAccount) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        feesAccount = _feesAccount;
    }

    function setTradesAccount(address _tradesAccount) external {
        require(msg.sender == admin, "BeetradeOrderbook: Caller Must be Admin");
        tradesAccount= _tradesAccount;
    }

    function depositAVAX(uint256 _amount) external payable {
        require(msg.value == _amount, "Beetrade: Please Deposit Right Amount");
        tokensBalances[AVAX][msg.sender] = SafeMath.add(tokensBalances[AVAX][msg.sender], msg.value);
        emit Deposit(AVAX, msg.sender, _amount);
    }

    function depositToken(address _token, uint256 _amount) external {
        // make sure user has called approve() function first
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Beetrade: Transfer Failed");
        tokensBalances[_token][msg.sender] = SafeMath.add(tokensBalances[_token][msg.sender], _amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    function withdrawAVAX(uint256 _amount) external {
        require(tokensBalances[AVAX][msg.sender] <= _amount, "Beetrade: Insufficient Amount");
        tokensBalances[AVAX][msg.sender] = SafeMath.sub(tokensBalances[AVAX][msg.sender], _amount);
        payable(msg.sender).transfer(_amount);
        emit Withdraw(AVAX, msg.sender, _amount);

    }

    function withdrawToken(address _token, uint256 _amount) external {
        require(tokensBalances[_token][msg.sender] <= _amount, "Beetrade: Insufficient Amount");
        tokensBalances[_token][msg.sender] = SafeMath.sub(tokensBalances[_token][msg.sender], _amount);
        IERC20(_token).transfer(msg.sender, _amount);
        emit Withdraw(_token, msg.sender, _amount);
    }

    function getAvailableAVAXBalance() external view returns(uint256) {
        return tokensBalances[AVAX][msg.sender];
    }

    function getAvailableTokenBalance(address _token) external view returns(uint256) {
        return tokensBalances[_token][msg.sender];
    }

    function calculateFee(uint256 amount) internal view returns(uint256) {
        return ((amount * fee) / (100 * 1e18));
    }

    function singleTrade (
        address maker, 
        address taker, 
        address tokenGet, 
        address tokenGive, 
        uint256 amountGet, 
        uint256 amountGive,
        string memory makeOrderID,
        string memory takeOrderID,
        string memory pair,
        uint256 price
    ) external {
        require(msg.sender == tradesAccount, "Beetrade: Only Trades Account can Execute Trades");
        require(tokensBalances[tokenGet][taker] >= amountGet, "Beetrade: Insufficient Balances For Trade"); // Make sure taker has enough balance to cover the trade
        require(tokensBalances[tokenGive][maker] >= amountGive, "Beetrade: Insufficient Balances For Trade"); // Make sure maker has enough balance to cover the trade

        uint256 makerFee = calculateFee(amountGet);
        uint256 takerFee = calculateFee(amountGive);


        // subtract from takers balance and add to makers balance for tokenGet
        tokensBalances[tokenGet][taker] = SafeMath.sub(tokensBalances[tokenGet][taker], amountGet);
        tokensBalances[tokenGet][maker] = SafeMath.add(tokensBalances[tokenGet][maker], SafeMath.sub(amountGet, makerFee));
        tokensBalances[tokenGet][tradesAccount] = SafeMath.add(tokensBalances[tokenGet][tradesAccount], makerFee); //charge trade fees

        // subtract from the makers balance and add to takers balance for tokenGive
        tokensBalances[tokenGive][maker] = SafeMath.sub(tokensBalances[tokenGive][maker], amountGive);
        tokensBalances[tokenGive][taker] = SafeMath.add(tokensBalances[tokenGive][taker], SafeMath.sub(amountGive, takerFee));
        tokensBalances[tokenGive][tradesAccount] = SafeMath.add(tokensBalances[tokenGive][tradesAccount], takerFee);

        emit Trade(maker, taker, amountGet, amountGive, makeOrderID, takeOrderID, pair, price); // charge trade fees
    }

    

}