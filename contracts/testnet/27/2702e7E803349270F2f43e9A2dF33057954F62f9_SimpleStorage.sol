/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 * @notice CAUTION
 * This version of SafeMath should only be used with Solidity 0.8 or later,
 * because it relies on the compiler's built in overflow checks.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b)
    internal pure returns (bool, uint256)
  {
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
  function trySub(uint256 a, uint256 b)
    internal pure returns (bool, uint256)
  {
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
  function tryMul(uint256 a, uint256 b)
    internal pure returns (bool, uint256)
  {
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
  function tryDiv(uint256 a, uint256 b)
    internal pure returns (bool, uint256)
  {
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
  function tryMod(uint256 a, uint256 b)
    internal pure returns (bool, uint256)
  {
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
  function add(uint256 a, uint256 b)
    internal pure returns (uint256)
  {
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
  function sub(uint256 a, uint256 b)
    internal pure returns (uint256)
  {
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
  function mul(uint256 a, uint256 b)
    internal pure returns (uint256)
  {
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
  function div(uint256 a, uint256 b)
    internal pure returns (uint256)
  {
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
  function mod(uint256 a, uint256 b)
    internal pure returns (uint256)
  {
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
  function sub(uint256 a, uint256 b, string memory errorMessage)
    internal pure returns (uint256)
  {
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
  function div(uint256 a, uint256 b, string memory errorMessage)
    internal pure returns (uint256)
  {
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
  function mod(uint256 a, uint256 b, string memory errorMessage)
    internal pure returns (uint256)
  {
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}
contract SimpleStorage {
    using SafeMath for uint256;
    uint public storedData;
    bytes public data;

    constructor(uint _storeData, bytes memory _data) {
        storedData=_storeData;
        data=_data;
    }
    event ApproveData(bool result, uint256 internalAmount,uint256 externalAmount, uint256 maxApproval);

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return type(uint256).max - storedData;
    }

    function getmaxUint() public pure returns (uint) {
        return type(uint256).max;
    }

    function getminUint() public pure returns (uint) {
        return type(uint256).min;
    }

    function getmaxInt() public pure returns (int) {
        return type(int).max;
    }
    function getminInt() public pure returns (int) {
        return type(int).min;
    }

    function approve( uint256 externalAmt,uint256 multiplier,uint256 deci) public returns (bool) {

        uint256 internalAmt;

        uint256 maxapproval = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        maxapproval = maxapproval.div(multiplier).mul(deci);

        if(externalAmt > maxapproval){
            internalAmt = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        }else{
             internalAmt = externalAmt.mul(deci).div(multiplier);
        }
        
        if (internalAmt > externalAmt){
            emit ApproveData(true,internalAmt,externalAmt,maxapproval);
            return true;
        }

        emit ApproveData(false,internalAmt,externalAmt,maxapproval);
        return false;

    }

    function approve_new(uint256 externalAmt,uint256 multiplier,uint256 DECI) public returns (bool) 
  
    {
   
        uint256 internalAmt;
        uint256 maxUInt = type(uint256).max;
        uint256 maxApproval = maxUInt.div(multiplier).mul(DECI);
        
        if (externalAmt <= maxUInt.div(DECI)) {
        internalAmt = externalAmt.mul(DECI).div(multiplier);
        if (internalAmt > maxApproval)
        {
            internalAmt = maxApproval;
        }
        } else {
        internalAmt = maxApproval;
        }
        
        if (internalAmt > externalAmt){
            emit ApproveData(true,internalAmt,externalAmt,maxApproval);
            return true;
        }

        emit ApproveData(false,internalAmt,externalAmt,maxApproval);
        return false;
  }
}