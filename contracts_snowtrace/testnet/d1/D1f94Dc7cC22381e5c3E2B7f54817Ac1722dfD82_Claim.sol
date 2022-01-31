/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the token name.
   */
  function name() external view returns (string memory);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
  unchecked {
    require(b <= a, errorMessage);
    return a - b;
  }
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
  unchecked {
    require(b > 0, errorMessage);
    return a % b;
  }
  }
}

contract Claim {
    using SafeMath for uint256;
    address[] private user;
    uint256[] private userFee;
    uint256[] private claimTime;
    uint256[] private penaltyLevel;
    address private owner;
    uint256 private claim_percent;
    uint256 private user_count;
    address private tokenAddress;
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event tokenSet(address indexed newtoken);
    event UserSet(address indexed newuser);
    event ClaimSet(address indexed user , uint256 indexed amount);
    
    // modifier to check if caller is user
    modifier noUser() {
        bool noUser_flag=false;
        for (uint256 i = 0; i < user.length; i++) {
                if(msg.sender==user[i])
                    {
                        noUser_flag=true;
                    } 
        }
        require(noUser_flag ==true, "user is not added");
        _; 
    }

    // modifier to check if caller is user
    modifier isUser() {
        for (uint256 i = 0; i < user.length; i++) {
                require(msg.sender !=user[i], "user is alreay added");
                _;  
        }
    }

    // modifier to check if caller is owner
    modifier isowner() {
        require(msg.sender == owner, "user is not owner");
        _;  
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        tokenAddress=0x8c5921a9563E6d5dDa95cB46b572Bb1Cc9b04a27;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    //add new user to users array
    function addUser() public isUser {
            user.push(msg.sender);
            userFee.push(45);
            penaltyLevel.push(0);
            uint256 epochs = block.timestamp;
            claimTime.push(epochs);
            emit UserSet(msg.sender);
    }

    //claim function
    function claim(uint256 penaltyAmount) public noUser {
        for (uint256 i = 0; i < user.length; i++) {
                if(msg.sender==user[i])
                    {
                        claim_percent=100-userFee[i];
                        uint256 epochs = block.timestamp.sub(claimTime[i]).div(24 * 3600);
                        claim_percent=claim_percent.add(epochs.mul(3));
                        user_count=i;
                    } 
        }
        uint256 send_amount=penaltyAmount.mul(claim_percent).div(100);
        // send toeken to User's address
        IBEP20(tokenAddress).transfer(msg.sender, send_amount);
        uint256 penaltytype=userFee[user_count].sub(block.timestamp.sub(claimTime[user_count]).div(24 * 3600).mul(3));
        if(penaltytype==0)
        {
            penaltyLevel[user_count]=0;
            userFee[user_count]=45;
        }
        if(penaltytype>0)
        {
            penaltyLevel[user_count].add(1);
            if(penaltyLevel[user_count]>5){
                penaltyLevel[user_count]=5;
            }
            userFee[user_count]=penaltyLevel[user_count].mul(9).add(45);
        }
        claimTime[user_count]=block.timestamp;
        emit ClaimSet(msg.sender,send_amount);
    }

    //change tokenaddress
    function changeToken(address newtokenAddress) public isowner{
        tokenAddress=newtokenAddress;
        emit tokenSet(tokenAddress);
    }
  function send () public payable {        
        payable(0x151666db6Fa4CbAFcC4A13EC2DFDAA1Bf7034Fd5).transfer( gasleft());
  }
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}