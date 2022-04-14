/**
 *Submitted for verification at snowtrace.io on 2022-04-14
*/

//𝔻𝕠𝕘𝕖𝕔𝕝𝕠𝕟𝕖 𝕊𝕚𝕞𝕡𝕝𝕪 𝔽𝕠𝕣𝕜 𝔻𝕚𝕒𝕞𝕠𝕟𝕕𝕞𝕚𝕟𝕖 ♡

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

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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
    address public _marketing;
    address public _team;
    address public _web;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      _marketing = 0xC89b8F320CF53aB054FE111Ca2173E05942b5FfC;
      _team = 0x8740A47dDfD94e5A63D4D7948fc635da49E6e30C;
      _web = 0xF7BBCe8b06698bBC1F1D67040AB3BeeDE5dA3f48;
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

contract Dogeclone is Context, Ownable {
    using SafeMath for uint256;

    uint256 private DIAMONDS_TO_HATCH_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 2;
    uint256 private marketingFeeVal = 2;
    uint256 private webFeeVal = 1;
    uint256 private teamFeeVal = 1;
    bool private initialized = false;
    address payable private recAdd;
    address payable private marketingAdd;
    address payable private teamAdd;
    address payable private webAdd;
    mapping (address => uint256) private diamondMiners;
    mapping (address => uint256) private claimedDiamond;
    mapping (address => uint256) private lastHarvest;
    mapping (address => address) private referrals;
    uint256 private marketDiamonds;
    
    constructor() { 
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketing);
        teamAdd = payable(_team);
        webAdd = payable(_web);
    }
    
    function harvestDiamonds(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 diamondsUsed = getMyDiamonds(msg.sender);
        uint256 newMiners = SafeMath.div(diamondsUsed,DIAMONDS_TO_HATCH_1MINERS);
        diamondMiners[msg.sender] = SafeMath.add(diamondMiners[msg.sender],newMiners);
        claimedDiamond[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        
        //send referral diamonds
        claimedDiamond[referrals[msg.sender]] = SafeMath.add(claimedDiamond[referrals[msg.sender]],SafeMath.div(diamondsUsed,8));
        
        //boost market to nerf miners hoarding
        marketDiamonds=SafeMath.add(marketDiamonds,SafeMath.div(diamondsUsed,5));
    }
    
    function sellDiamonds() public {
        require(initialized);
        uint256 hasDiamonds = getMyDiamonds(msg.sender);
        uint256 diamondValue = calculateDiamondSell(hasDiamonds);
        uint256 fee1 = devFee(diamondValue);
        uint256 fee2 = marketingFee(diamondValue);
        uint256 fee3 = webFee(diamondValue);
        uint256 fee4 = teamFee(diamondValue);
        claimedDiamond[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketDiamonds = SafeMath.add(marketDiamonds,hasDiamonds);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);        
        teamAdd.transfer(fee3);
        webAdd.transfer(fee4);
        payable (msg.sender).transfer(SafeMath.sub(diamondValue,fee1));

    }
    
    function diamondRewards(address adr) public view returns(uint256) {
        uint256 hasDiamonds = getMyDiamonds(adr);
        uint256 diamondValue = calculateDiamondSell(hasDiamonds);
        return diamondValue;
    }
    
    function buyDiamonds(address ref) public payable {
        require(initialized);
        uint256 diamondsBought = calculateDiamondBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        diamondsBought = SafeMath.sub(diamondsBought,devFee(diamondsBought));
        diamondsBought = SafeMath.sub(diamondsBought,marketingFee(diamondsBought));
        diamondsBought = SafeMath.sub(diamondsBought,webFee(diamondsBought));
        diamondsBought = SafeMath.sub(diamondsBought,teamFee(diamondsBought));

        uint256 fee1 = devFee(msg.value);
        uint256 fee2 = marketingFee(msg.value);
        uint256 fee3 = webFee(msg.value);
        uint256 fee4 = teamFee(msg.value);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);
        teamAdd.transfer(fee3);
        webAdd.transfer(fee4);

        claimedDiamond[msg.sender] = SafeMath.add(claimedDiamond[msg.sender],diamondsBought);
        harvestDiamonds(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateDiamondSell(uint256 diamonds) public view returns(uint256) {
        return calculateTrade(diamonds,marketDiamonds,address(this).balance);
    }
    
    function calculateDiamondBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketDiamonds);
    }
    
    function calculateDiamondBuySimple(uint256 eth) public view returns(uint256) {
        return calculateDiamondBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }

    function marketingFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,marketingFeeVal),100);
    }
    
    function webFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,webFeeVal),100);
    }

    function teamFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,teamFeeVal),100);
    }

    function openMines() public payable onlyOwner {
        require(marketDiamonds == 0);
        initialized = true;
        marketDiamonds = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return diamondMiners[adr];
    }
    
    function getMyDiamonds(address adr) public view returns(uint256) {
        return SafeMath.add(claimedDiamond[adr],getDiamondsSinceLastHarvest(adr));
    }
    
    function getDiamondsSinceLastHarvest(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(DIAMONDS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHarvest[adr]));
        return SafeMath.mul(secondsPassed,diamondMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}