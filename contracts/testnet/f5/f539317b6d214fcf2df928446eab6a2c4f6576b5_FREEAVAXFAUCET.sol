/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
// Author: Jacob Suchorabski

pragma solidity ^0.8.0 < 0.9.0;


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

pragma solidity ^0.8.0 < 0.9.0;

contract FREEAVAXFAUCET {

    ///storage + variables
    address public owner;
    uint256 public AVAX_BASE_AMOUNT = 1; //Start payout is 0.000000000000000001 AVAX
    uint256 public AVAX_MIN_WITHDRAW = 100000000000000000; //minimum payout is 0.1 AVAX
    uint public BASE_FAUCET_MULTIPLIER = 1; //1 = 1x multiplier
    uint public MAX_FAUCET_MULTIPLIER = 100000000000000000000; //10000 is 10000x multiplier
    uint256 public ONE_DAY_SECONDS = 86400;
    uint256 public ONE_HOUR_SECONDS = 3600;
    uint256 public ONE_MINUTE_SECONDS = 60;
    uint public AVAX_CLAIMS = 0;
    uint256 public AVAX_CLAIMS_TOTAL = 0;
    uint public AVAX_DONATIONS = 0;
    uint256 public AVAX_DONATIONS_TOTAL = 0;
    uint public USERS = 0;

    mapping(address => uint) timeouts;
    mapping(string => uint256) public lastClaim;
    mapping(address => uint256) public payout_multiplier;
    mapping(address => uint256) public balances;
    mapping(address => bool) public approvedOperators;
    mapping(address => bool) public superOperators;
    mapping(address => string) private address_last_ip;



    //MODIFIERS
    modifier isSuperOperator() {
        require(superOperators[msg.sender], "Not super operator");
        _;
    }
    modifier ownerOnly() {
        require(owner == msg.sender, "Not the contract owner");
        _;
    } 

    modifier isApprovedOperator() {
        require(approvedOperators[msg.sender] || superOperators[msg.sender], "Not approved operator");
        _;
    }

   constructor() {
        //Will be called on creation of the smart contract.
        owner = msg.sender;
        payout_multiplier[msg.sender] = BASE_FAUCET_MULTIPLIER;
        approvedOperators[msg.sender] = true;
        superOperators[msg.sender] = true;
        balances[msg.sender] = 0;
    }

    //EVENTS
    event Withdrawal(address indexed to, uint256 amount);
    event Deposit(address indexed from, uint amount);
    event FaucetOn(bool status);
    event FaucetOff(bool status);
    event FaucetDrained(address indexed recipient);
 

    function claimFaucet(address) public returns (uint256) {
        uint256 userbal = balances[msg.sender];
        uint256 payout = (payout_multiplier[msg.sender] * AVAX_BASE_AMOUNT);
        uint256 newbal = userbal + payout;
        balances[msg.sender] = newbal;
        uint newClaimamt = AVAX_CLAIMS + 1;
        AVAX_CLAIMS = newClaimamt;
        uint256 newClaimTotal = AVAX_CLAIMS_TOTAL + payout;
        AVAX_CLAIMS_TOTAL = newClaimTotal;
        return payout;
    }

    function claimCheck(address) public view returns(uint) {
        uint time = timeouts[msg.sender]; 
        return time;
    }

    function clearTimeout(address) ownerOnly public {
        require(msg.sender == owner, "You must be contract owner to clear timeout!");
        timeouts[msg.sender] = block.timestamp;
    }

    //  Sends 0.1 ETH to the sender when the faucet has enough funds
    //  Only allows one withdrawal every 30 mintues
    function withdraw(address payable, uint256 amount) public returns(uint256) {
        require(address(this).balance >= 0.1 ether, "This faucet is empty. Please check back later.");
        require(address(this).balance > amount, "The faucet doesn't have enough funds to withdraw!");
        require(amount > 0, "Withdraw amount must be > 0");
        require(timeouts[msg.sender] <= block.timestamp - 30 minutes, "You can only withdraw once every 30 minutes. Please check back later.");
        timeouts[msg.sender] = block.timestamp;
        balances[msg.sender] = balances[msg.sender] - amount;
        emit Withdrawal(msg.sender, amount);
        return amount;
    }

    //  Sending Tokens to this faucet fills it up
    receive() external payable {
        uint newMulti = msg.value / 10;
        payout_multiplier[msg.sender] = payout_multiplier[msg.sender] * newMulti;
        emit Deposit(msg.sender, msg.value);
    }

    function drain(address _recipient) external ownerOnly {
        // Drain all Ether
        (bool sent,) = _recipient.call{value: address(this).balance}("");
        require(sent, "Failed draining ETH");
        emit FaucetDrained(_recipient);
    }

}