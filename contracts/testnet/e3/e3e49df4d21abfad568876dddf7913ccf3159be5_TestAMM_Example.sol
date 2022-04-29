/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-28
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

// File: TestAMM_Example.sol


pragma solidity >=0.7.0 <0.9.0;



contract TestAMM_Example {
    using SafeMath for uint256;
    uint256 totalShares;  // Stores the total amount of share issued for the pool
    uint256 REZToken;  // Stores the amount of Token1 locked in the pool
    uint256 ABRToken;  // Stores the amount of Token2 locked in the pool
    uint256 K;            // Algorithmic constant used to determine price (K = REZToken * ABRToken)

    uint256 constant PRECISION = 1_000_000;  // Precision of 6 decimal places

    mapping(address => uint256) shares;  // Stores the share holding of each provider

    mapping(address => uint256) REZTokenBlance;  // Stores the available balance of user outside of the AMM
    mapping(address => uint256) ABRTokenBalance;

    // Ensures that the _qty is non-zero and the user has enough balance
    modifier validAmountCheck(mapping(address => uint256) storage _balance, uint256 _qty) {
        require(_qty > 0, "Amount cannot be zero!");
        require(_qty <= _balance[msg.sender], "Insufficient amount");
        _;
    }

    // Restricts withdraw, swap feature till liquidity is added to the pool
    modifier activePool() {
        require(totalShares > 0, "Zero Liquidity");
        _;
    }

    // Returns the balance of the user
    function getMyHoldings() external view returns(uint256 amountToken1, uint256 amountToken2, uint256 myShare) {
        amountToken1 = REZTokenBlance[msg.sender];
        amountToken2 = ABRTokenBalance[msg.sender];
        myShare = shares[msg.sender];
    }

    // Returns the total amount of tokens locked in the pool and the total shares issued corresponding to it
    function getPoolDetails() external view returns(uint256, uint256, uint256) {
        return (REZToken, ABRToken, totalShares);
    }

    // Sends free token(s) to the invoker
    function faucet(uint256 _amountToken1, uint256 _amountToken2) external {
        REZTokenBlance[msg.sender] = REZTokenBlance[msg.sender].add(_amountToken1);
        ABRTokenBalance[msg.sender] = ABRTokenBalance[msg.sender].add(_amountToken2);
    }

    // Adding new liquidity in the pool
    // Returns the amount of share issued for locking given assets
    function provide(uint256 _amountToken1, uint256 _amountToken2) external validAmountCheck(REZTokenBlance, _amountToken1) validAmountCheck(ABRTokenBalance, _amountToken2) returns(uint256 share) {
        if(totalShares == 0) { // Genesis liquidity is issued 100 Shares
            share = 100*PRECISION;
        } else{
            uint256 share1 = totalShares.mul(_amountToken1).div(REZToken);
            uint256 share2 = totalShares.mul(_amountToken2).div(ABRToken);
            require(share1 == share2, "Equivalent value of tokens not provided...");
            share = share1;
        }

        require(share > 0, "Asset value less than threshold for contribution!");
        REZTokenBlance[msg.sender] -= _amountToken1;
        ABRTokenBalance[msg.sender] -= _amountToken2;

        REZToken += _amountToken1;
        ABRToken += _amountToken2;
        K = REZToken.mul(ABRToken);

        totalShares += share;
        shares[msg.sender] += share;
    }

    // Returns amount of Token1 required when providing liquidity with _amountToken2 quantity of Token2
    function getEquivalentToken1Estimate(uint256 _amountToken2) public view activePool returns(uint256 reqToken1) {
        reqToken1 = REZToken.mul(_amountToken2).div(ABRToken);
    }

    // Returns amount of Token2 required when providing liquidity with _amountToken1 quantity of Token1
    function getEquivalentToken2Estimate(uint256 _amountToken1) public view activePool returns(uint256 reqToken2) {
        reqToken2 = ABRToken.mul(_amountToken1).div(REZToken);
    }

    // Returns the estimate of Token1 & Token2 that will be released on burning given _share
    function getWithdrawEstimate(uint256 _share) public view activePool returns(uint256 amountToken1, uint256 amountToken2) {
        require(_share <= totalShares, "Share should be less than totalShare");
        amountToken1 = _share.mul(REZToken).div(totalShares);
        amountToken2 = _share.mul(ABRToken).div(totalShares);
    }

    // Removes liquidity from the pool and releases corresponding Token1 & Token2 to the withdrawer
    function withdraw(uint256 _share) external activePool validAmountCheck(shares, _share) returns(uint256 amountToken1, uint256 amountToken2) {
        (amountToken1, amountToken2) = getWithdrawEstimate(_share);
        
        shares[msg.sender] -= _share;
        totalShares -= _share;

        REZToken -= amountToken1;
        ABRToken -= amountToken2;
        K = REZToken.mul(ABRToken);

        REZTokenBlance[msg.sender] += amountToken1;
        ABRTokenBalance[msg.sender] += amountToken2;
    }

    // Returns the amount of Token2 that the user will get when swapping a given amount of Token1 for Token2
    function getSwapToken1Estimate(uint256 _amountToken1) public view activePool returns(uint256 amountToken2) {
        uint256 token1After = REZToken.add(_amountToken1);
        uint256 token2After = K.div(token1After);
        amountToken2 = ABRToken.sub(token2After);

        // To ensure that Token2's pool is not completely depleted leading to inf:0 ratio
        if(amountToken2 == ABRToken) amountToken2--;
    }

    // Returns the amount of Token1 that the user should swap to get _amountToken2 in return
    function getSwapToken1EstimateGivenToken2(uint256 _amountToken2) public view activePool returns(uint256 amountToken1) {
        require(_amountToken2 < ABRToken, "Insufficient pool balance");
        uint256 token2After = ABRToken.sub(_amountToken2);
        uint256 token1After = K.div(token2After);
        amountToken1 = token1After.sub(REZToken);
    }

    // Swaps given amount of Token1 to Token2 using algorithmic price determination
    function swapToken1(uint256 _amountToken1) external activePool validAmountCheck(REZTokenBlance, _amountToken1) returns(uint256 amountToken2) {
        amountToken2 = getSwapToken1Estimate(_amountToken1);

        REZTokenBlance[msg.sender] -= _amountToken1;
        REZToken += _amountToken1;
        ABRToken -= amountToken2;
        ABRTokenBalance[msg.sender] += amountToken2;
    }

    // Returns the amount of Token2 that the user will get when swapping a given amount of Token1 for Token2
function getSwapToken2Estimate(uint256 _amountToken2) public view activePool returns(uint256 amountToken1) {
    uint256 token2After = ABRToken.add(_amountToken2);
    uint256 token1After = K.div(token2After);
    amountToken1 = REZToken.sub(token1After);

    // To ensure that Token1's pool is not completely depleted leading to inf:0 ratio
    if(amountToken1 == REZToken) amountToken1--;
}

// Returns the amount of Token2 that the user should swap to get _amountToken1 in return
function getSwapToken2EstimateGivenToken1(uint256 _amountToken1) public view activePool returns(uint256 amountToken2) {
    require(_amountToken1 < REZToken, "Insufficient pool balance");
    uint256 token1After = REZToken.sub(_amountToken1);
    uint256 token2After = K.div(token1After);
    amountToken2 = token2After.sub(ABRToken);
}

    // Swaps given amount of Token2 to Token1 using algorithmic price determination
    function swapToken2(uint256 _amountToken2) external activePool validAmountCheck(ABRTokenBalance, _amountToken2) returns(uint256 amountToken1) {
        amountToken1 = getSwapToken2Estimate(_amountToken2);

        ABRTokenBalance[msg.sender] -= _amountToken2;
        ABRToken += _amountToken2;
        REZToken -= amountToken1;
        REZTokenBlance[msg.sender] += amountToken1;
    }



}