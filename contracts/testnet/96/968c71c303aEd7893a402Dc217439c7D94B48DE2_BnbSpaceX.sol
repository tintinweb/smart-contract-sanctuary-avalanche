/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT

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

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract BnbSpaceX is Context, Ownable {
    using SafeMath for uint256;

    uint256 private COIN_TO_HATCH_MINERS = 1080000; //for final version should be seconds in a day 1080000
    uint256 private PSN = 10000;
    uint256 private PSNH; // 4000-5000 || 15-8%
    uint256 private devFeeVal;
    uint256 private refPercent; //percent + dev
    bool private initialized = false;
    address payable private recAdd;

    mapping (address => uint256) private hatcheryMiners;
    mapping (address => uint256) private claimedCoins;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    mapping (address => uint256) private referralsIncome;
    mapping (address => uint) private referralsCount;
    mapping (address => uint256) private depositCoins;
    mapping (address => uint256) private totalClaimed;
    uint256 private marketCoins;

    constructor(uint256 _PSNH, uint256 _devFeeVal, uint256 _refPercent ) {
        recAdd = payable(msg.sender);
        PSNH = _PSNH;
        devFeeVal = _devFeeVal;
        refPercent = _refPercent;
    }
    
    function hatchCoins(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = recAdd;
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
            referralsCount[ref] += 1;
        }
        
        uint256 coinsUsed = getMyCoins(msg.sender);
        uint256 newMiners = coinsUsed.div(COIN_TO_HATCH_MINERS);
        hatcheryMiners[msg.sender] = hatcheryMiners[msg.sender].add(newMiners);
        claimedCoins[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral coins
        claimedCoins[referrals[msg.sender]] = claimedCoins[referrals[msg.sender]].add(coinsUsed.mul(refPercent).div(100));
        referralsIncome[ref] = referralsIncome[ref].add(coinsUsed.mul(refPercent).div(100));
        
        //boost market to nerf miners hoarding
        marketCoins=marketCoins.add(coinsUsed.mul(devFeeVal).div(100));
    }
    
    function sellCoins() public {
        require(initialized);
        uint256 hasCoins = getMyCoins(msg.sender);
        uint256 coinValue = calculateCoinSell(hasCoins);
        uint256 fee = devFee(coinValue);
        claimedCoins[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketCoins = marketCoins.add(hasCoins);
        recAdd.transfer(fee);
        coinValue = coinValue.sub(fee);
        totalClaimed[msg.sender] = totalClaimed[msg.sender].add(coinValue);
        payable (msg.sender).transfer(coinValue);
    }
    
    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasCoins = getMyCoins(adr);
        uint256 coinValue = calculateCoinSell(hasCoins);
        return coinValue;
    }
    
    function buyCoins(address ref) public payable {
        require(initialized);
        uint256 coinsBought = calculateCoinBuy(msg.value,address(this).balance.sub(msg.value));
        depositCoins[msg.sender] = depositCoins[msg.sender].add(msg.value);
        coinsBought = coinsBought.sub(devFee(coinsBought));

        uint256 fee = devFee(msg.value);
        recAdd.transfer(fee);
        claimedCoins[msg.sender] = claimedCoins[msg.sender].add(coinsBought);
        hatchCoins(ref);
    }

    function burnCoins() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        uint256 one = PSNH.mul(rt);
        uint256 two = PSN.mul(rs);
        uint256 three = two.add(one);
        uint256 four = three.div(rt);
        uint256 five = PSNH.add(four);
        uint256 six = PSN.mul(bs);
        return six.div(five);
    }
    
    function calculateCoinSell(uint256 coins) public view returns(uint256) {
        return calculateTrade(coins,marketCoins,address(this).balance);
    }
    
    function calculateCoinBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketCoins);
    }

    function calculateDailyIncome(address adr) public view returns(uint256) {
        uint256 userMiners = getMyMiners(adr);
        uint256 minReturn = calculateCoinSell(userMiners).mul(SafeMath.mul(SafeMath.mul(60, 60), 30));
        uint256 maxReturn = calculateCoinSell(userMiners).mul(SafeMath.mul(SafeMath.mul(60, 60), 25));
        uint256 serReturn = minReturn.add(maxReturn);
        return serReturn.div(2);
    }

    function devFee(uint256 amount) private view returns(uint256) {
        return amount.mul(devFeeVal).div(100);
    }

    function seedMarket() public payable onlyOwner {
        require(marketCoins == 0);
        initialized = true;
        marketCoins = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getMyDepositCoins(address adr) public view returns(uint256) {
        return depositCoins[adr];
    }

    function getMyTotalClaimed(address adr) public view returns(uint256) {
        return totalClaimed[adr];
    }

    function getMyReferrals(address adr) public view returns(address) {
        return referrals[adr];
    }

    function getMyReferralsCount(address adr) public view returns(uint) {
        return referralsCount[adr];
    }

    function getMyReferralsIncome(address adr) public view returns(uint256) {
        return calculateCoinSell(referralsIncome[adr]);
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return hatcheryMiners[adr];
    }
    
    function getMyCoins(address adr) public view returns(uint256) {
        return claimedCoins[adr].add(getCoinsSinceLastHatch(adr));
    }
    
    function getCoinsSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(COIN_TO_HATCH_MINERS,block.timestamp.sub(lastHatch[adr]));
        return secondsPassed.mul(hatcheryMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }


}