// SPDX-License-Identifier: MIT
// Venom-Finance version 3
// https://t.me/VenomFinanceCommunity

pragma solidity >=0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAOfundMultisig {

	using SafeMath for uint256;
	
	// 3 members all are public, and can be viewed from read functions
	address public projectOwner;
	address public teamMember;
	address public daoMember;
	
	// The token are also public, and can be viewed from the red function
    IERC20 public tokenToWithdraw;
    IERC20 public deadAddressToken = IERC20(0x0000000000000000000000000000000000000000);
    address public deadAddressReceiver = 0x0000000000000000000000000000000000000000;
    address public receiver;	

    constructor(address projectOwner_, address teamMember_, address daoMember_) {
            projectOwner = projectOwner_;
            teamMember = teamMember_;
            daoMember = daoMember_;

    }
	
   
	// mapping for allowance
	struct User {mapping(address => uint256) allowance;}
	struct Info {mapping(address => User) users;	}
	Info private info;
	event Approval(address indexed owner, address indexed projectOwner, uint256 tokens,IERC20 tokenToWithdraw);

    // write function, can only be called by a founder
    // approve allowance to a fellow founder, enter the amount of tokens you want to give that founder access to
    // to rewoke allowance set allowance to 0 
	function approve(uint256 _amount, IERC20 token_, address _receiver) external returns (bool) {
        require(tokenToWithdraw == deadAddressToken || token_ == tokenToWithdraw, "One token at the time, you can only approve the same token as the other member");
	    require(receiver == deadAddressReceiver || _receiver == receiver, "only one receiver");
         require(daoMember == msg.sender  || teamMember == msg.sender, "You are not the daoMember");    
		info.users[msg.sender].allowance[projectOwner] = _amount;
        tokenToWithdraw = token_;
        receiver = _receiver;
		emit Approval(msg.sender, projectOwner, _amount,tokenToWithdraw);
		return true;
	}

   
    function setNewProjectOwner(address projectOwner_) external returns (bool) {
         require(projectOwner == msg.sender, "You are not a owner"); 
        projectOwner = projectOwner_;
        return true;
	}

    function setNewDaoMember(address daoMember_) external returns (bool) {
        require(daoMember == msg.sender, "You are not the daoMember"); 
        daoMember = daoMember_;
        return true;
	}

    function setNewTeamMember(address teamMember_) external returns (bool) {
        require(teamMember == msg.sender, "You are not the teamMember"); 
        teamMember = teamMember_;
        return true;
	}
    // read function, you can view how much allowance is granted  from teamMember to projectOwner
	function allowanceTeamMember() public view returns (uint256) {
		return info.users[teamMember].allowance[projectOwner];
	}

        // read function, you can view how much allowance is granted from daoMember to projectOwner
	function allowanceDaoMember() public view returns (uint256) {
		return info.users[daoMember].allowance[projectOwner];
	}

    // write function, can only be called by the founder
    // enter the amount of tokens to withdraw
    // function requires the allowance from each member to be greater or equal to the amount the user tries to withdraw

	function transferTokens(uint256 _tokens) external returns (bool) {
	  	require(projectOwner == msg.sender, "You are not the projectOwner");   
        require(tokenToWithdraw != deadAddressToken, "bad token");
	    require(receiver != deadAddressReceiver, "cant burn tokens");
	  	require(info.users[teamMember].allowance[msg.sender] >= _tokens || msg.sender == teamMember, "insufiencient allowance from teamMember");
	  	require(info.users[daoMember].allowance[msg.sender] >= _tokens || msg.sender == daoMember, "insufiencient allowance from daoMember");
		info.users[teamMember].allowance[msg.sender] = 0;
		info.users[daoMember].allowance[msg.sender] = 0;
		tokenToWithdraw.transfer(receiver, _tokens);
        tokenToWithdraw = deadAddressToken;
        receiver = deadAddressReceiver;
		return true;
	}

    // reset values

    function resetToken() external returns (bool) {
       	require(daoMember == msg.sender  || teamMember == msg.sender ||  projectOwner == msg.sender, "You are not a Member"); 
          require(daoMember == msg.sender  || teamMember == msg.sender ||  projectOwner == msg.sender, "You are not a Member");     
        tokenToWithdraw = deadAddressToken;
        return true;
    }

    function resetreceiver() external returns (bool) {
        require(daoMember == msg.sender  || teamMember == msg.sender ||  projectOwner == msg.sender, "You are not a Member"); 
        receiver = deadAddressReceiver;
        return true;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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