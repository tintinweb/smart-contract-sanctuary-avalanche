/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-03
*/

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

// File: contracts/Vesting.sol


pragma solidity ^0.8.0;


interface IPresaleContract {
    function START() external view returns (uint256);
    function PERIOD() external view returns (uint256);
    function totalsold() external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Vesting {
    using SafeMath for uint256;

    struct VestingSchedule {
      uint256 totalAmount; // Total amount of tokens to be vested.
      uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    address private owner;
    address payable public multiSigAdmin; // MultiSig contract address : The address where to withdraw funds

    IPresaleContract public presaleContract; // Presale contract interface
    IERC20 public CCoinToken; //SBC token interface

    mapping(address => VestingSchedule) public recipients;

    uint256 constant MAX_UINT256 = type(uint256).max;
    uint256 public constant TGE_UNLOCK = 100; // 10% * 10: released percent at TGE stage, release token amount when end presale
    uint256 public constant UNLOCK_UNIT = 75; // 7.5% * 10 of the total allocation will be unlocked
    uint256 public constant CLIFF_PERIOD = 1 hours; // cliff period
    uint public vestingPeriod = 12;

    uint256 public vestingAllocation; // Max amount which will be locked in vesting contract
    uint256 private totalAllocated; // The amount of allocated tokens

    event VestingScheduleRegistered(address registeredAddress, uint256 totalAmount);

    /********************** Modifiers ***********************/
    modifier onlyOwner() {
        require(owner == msg.sender, "Requires Owner Role");
        _;
    }

    modifier onlyMultiSigAdmin() {
        require(msg.sender == multiSigAdmin || address(presaleContract) == msg.sender, "Should be multiSig contract");
        _;
    }

    constructor(address _CCoinToken, address _presaleContract) {
        owner = msg.sender;

        CCoinToken = IERC20(_CCoinToken);
        presaleContract = IPresaleContract(_presaleContract);
    }


    /**
     * @dev Get TGE time (TGE_Time = PresaleEnd_Time + 1 hours) token Generate end time
     */
    function getTGETime() public view returns (uint256) {
        //   ///  because blocktime is late than current UTC time 
        // return presaleContract.START().add(presaleContract.PERIOD()).add(1 hours);
        return presaleContract.START().add(presaleContract.PERIOD().mul(1 days));
    }
    /**
     * @dev external function to set vesting allocation
     */
    function setVestingAllocation() external onlyOwner {
        vestingAllocation = CCoinToken.balanceOf(address(this));
    }

    // function setVestingPeriod(uint _days) external onlyOwner {
    //     require(vestingPeriod == 0, "Already set vesting period!!");
    //     vestingPeriod = _days;
    // }
    
    /**
     * @dev Private function to add a recipient to vesting schedule
     * @param _recipient the address to be added
     * @param _totalAmount integer variable to indicate SBC amount of the recipient
     */
    function addRecipient(address _recipient, uint256 _totalAmount, bool isPresaleBuyer) private {
        require(_recipient != address(0x00), "addRecipient: Invalid recipient address");
        require(_totalAmount > 0, "addRecipient: Cannot vest 0");
        require(isPresaleBuyer || (!isPresaleBuyer && recipients[_recipient].totalAmount == 0), "addRecipient: Already allocated");
        require(totalAllocated.sub(recipients[_recipient].totalAmount).add(_totalAmount) <= vestingAllocation, "addRecipient: Total Allocation Overflow");

        totalAllocated = totalAllocated.sub(recipients[_recipient].totalAmount).add(_totalAmount);
        
        recipients[_recipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: recipients[_recipient].amountWithdrawn
        });
    }
    
    /**
     * @dev Add new recipient to vesting schedule
     * @param _newRecipient the address to be added
     * @param _totalAmount integer variable to indicate SBC amount of the recipient
     */
    function addNewRecipient(address _newRecipient, uint256 _totalAmount, bool isPresaleBuyer) external onlyMultiSigAdmin {
        require(block.timestamp < getTGETime().add(CLIFF_PERIOD), "addNewRecipient: Cannot update the receipient after started");

        addRecipient(_newRecipient, _totalAmount, isPresaleBuyer);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount);
    }

    /**
     * @dev Gets the locked SBC amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getLocked(address beneficiary) external view returns (uint256) {
        return recipients[beneficiary].totalAmount.sub(getVested(beneficiary));
    }

    /**
     * @dev Gets the claimable SBC amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getWithdrawable(address beneficiary) public view returns (uint256) {
        return getVested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    /**
     * @dev Claim unlocked SBC tokens of a recipient
     */
    function withdrawToken() external returns (uint256) {
        VestingSchedule storage _vestingSchedule = recipients[msg.sender];
        if (_vestingSchedule.totalAmount == 0) return 0;

        uint256 _vested = getVested(msg.sender);
        uint256 _withdrawable = _vested.sub(recipients[msg.sender].amountWithdrawn);
        _vestingSchedule.amountWithdrawn = _vested;

        require(_withdrawable > 0, "withdraw: Nothing to withdraw");
        require(CCoinToken.transfer(msg.sender, _withdrawable));
        
        return _withdrawable;
    }
    
    /**
     * @dev Claim unlocked SBC tokens of a recipient
     */
     function withrawRemainToken() external onlyOwner () {
         require(CCoinToken.balanceOf(address(this)) > 0, "");
         uint256 _totalTokenAmount = CCoinToken.balanceOf(address(this));
         uint256 _remainToken = _totalTokenAmount.sub(presaleContract.totalsold());
         CCoinToken.transferFrom(address(this), msg.sender, _remainToken);
     }

    /**
     * @dev Get claimable SBC token amount of a beneficiary
     * @param beneficiary address of beneficiary
     */
    function getVested(address beneficiary) public view virtual returns (uint256 _amountVested) {
        require(beneficiary != address(0x00), "getVested: Invalid address");
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];

        if (_vestingSchedule.totalAmount == 0 || block.timestamp < getTGETime()) {
            return 0;
        } else if (block.timestamp <= getTGETime().add(CLIFF_PERIOD)) {
            return (_vestingSchedule.totalAmount).mul(TGE_UNLOCK).div(100);
        }

        uint256 vestedPercent;
        // // /// for main net 
        // uint256 claimPeriodTime = 30;
        // // for test net
        uint256 claimPeriodTime = 1;

        // uint256 firstVestingPoint = getTGETime().add(CLIFF_PERIOD);
        // uint256 secondVestingPoint = firstVestingPoint.add(1 hours);
        // uint256 thirdVestingPoint = secondVestingPoint.add(1 hours);

        // // //// /// // for main net
        // for (uint i = 0; i < 12; i++) {
        //     if (block.timestamp > getTGETime().add(claimPeriodTime.mul(1 days).mul(i)) && block.timestamp <= getTGETime().add(claimPeriodTime.mul(1 days).mul(i.add(1)))) {
        //         vestedPercent = TGE_UNLOCK.add(UNLOCK_UNIT.mul(i));
        //     } else if(block.timestamp > getTGETime().add(claimPeriodTime.mul(1 days).mul(12))) {
        //         vestedPercent = 1000;
        //     }  
        // }

        // /// for test net 
        for (uint i = 0; i < 12; i++) {
            if (block.timestamp > getTGETime().add(claimPeriodTime.mul(1 days).mul(i)) && block.timestamp <= getTGETime().add(claimPeriodTime.mul(1 days).mul(i.add(1)))) {
                vestedPercent = TGE_UNLOCK.add(UNLOCK_UNIT.mul(i));
                break;
            } else if(block.timestamp > getTGETime().add(claimPeriodTime.mul(1 hours).mul(12))) {
                vestedPercent = 1000;
                break;
            }  
        }

        // if (block.timestamp > firstVestingPoint && block.timestamp <= secondVestingPoint) {
        //     vestedPercent = TGE_UNLOCK.add(UNLOCK_UNIT);
        // } else if (block.timestamp > secondVestingPoint && block.timestamp <= thirdVestingPoint) {
        //     vestedPercent = TGE_UNLOCK.add(UNLOCK_UNIT).add(UNLOCK_UNIT);
        // } else if (block.timestamp > thirdVestingPoint) {
        //     vestedPercent = 100;
        // }

        uint256 vestedAmount = _vestingSchedule.totalAmount.mul(vestedPercent).div(1000);
        if (vestedAmount > _vestingSchedule.totalAmount) {
            return _vestingSchedule.totalAmount;
        }

        return vestedAmount;
    }
}