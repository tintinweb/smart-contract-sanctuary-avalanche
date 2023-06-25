/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-25
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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

// File: contracts/TT-DAO-US/TTDAOMinter.sol


pragma solidity ^0.8.9;




interface INFTMinter {
    function mint(uint256[] calldata uids, address referrer) external;
    function safeMint(address to) external;
    function safeBatchMint(address to, uint256 quantity) external;
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ITTDAOLiquidity {
    function addInitLiquidity() external;
    function addLiquidity() external;
}

interface ITTDAOBurn {
    function burn() external;
}

interface IERC20Burn {
    function burn(uint256 amount) external;
}

contract TTDAOMinter is Ownable {
    using SafeMath for uint256;

    IERC20  public usdtToken;

    address private constant _ttDaoNodeAddress = 0x33Bec3074F5208aF3d29A15248369f15F26cBAf0 ;
    address private constant _usdtAddress      = 0xE06Cf545922899c8F994B98521e7a396BefB054F;
    address private constant _swapAddress      = 0x66ebB6C775bd13baf09D344d5FB3585090fa34eb;
    address private constant _officalMinterAddress = 0x37Cf8aE67005aD3592E94B847fE95Fcf08B01A77;//TTUidMinter06:	

    mapping(address => address) private _refers;
    mapping(address => uint256) private _referCount;
    mapping(address => uint256) private _referNodeCount;

    uint256 public  constant daySec_7          = 7 * 86400;
    uint256 public  constant basePrice         = 30 * 10 ** 18;
    uint256 public  constant basePower         = 10;
    uint256 public  constant MAX               = ~uint256(0);
    address private constant _marketFd         = 0xEEd805A6cE8705ebeca7Ab8738F77366336337E1;
    address private constant _marketQd         = 0xEEd805A6cE8705ebeca7Ab8738F77366336337E1;
    
    ITTDAOBurn private _burnContract;
    ITTDAOLiquidity private _liquidityContract;

    address private _ttDaoAddress              = address(0);
    address private _burnPool                  = address(0);
    address private _liquidityPool             = address(0);
    uint256 private _mintNodeEndTime           = 1688227199; // 2023-07-01 23:59:59
    uint256 private _mintNodeReferCount        = 50;
    uint256 private _mintedAmount              = 0;
    
    struct MintData {
        bool     live;

        uint256  nftMintCount;

        uint256  totalPower;
        uint256  totalNftPower;
        uint256  totalReferPower;

        uint256  startTime;
        uint256  miningPower;
        uint256  miningNftPower;
        uint256  miningReferPower;
    }
    mapping(address => MintData) public minters;

    event MintPay(address sender, uint256 payAmount, uint256 nftCount, address referrer);
    event MintNodePay(address sender, uint256 payAmount, uint256 nftCount);

    constructor() {
        usdtToken = IERC20(_usdtAddress);
        IERC20(_usdtAddress).approve(_officalMinterAddress, MAX);
    }

    function mint(uint256[] calldata uids, address referrer) public {
        require(uids.length > 0, "need uids");
        require(msg.sender != referrer && referrer != address(0), "error referrer");

        // pay & mint
        uint256 price = getPrice();
        uint256 payAmount = price.mul(uids.length);
        usdtToken.transferFrom(msg.sender, address(this), payAmount);
        INFTMinter(_officalMinterAddress).mint(uids, referrer);

        // refer
        if (_refers[msg.sender] == address(0)) {
            _refers[msg.sender] = referrer;
            _referCount[referrer] = _referCount[referrer].add(uids.length);
        } else {
            address olderRefer = _refers[msg.sender];
            _referCount[olderRefer] = _referCount[olderRefer].add(uids.length);
        }
        
        // calc power
        updateNftPower(msg.sender, uids.length);
        address Lv1 = _refers[msg.sender];
        address Lv2 = _refers[Lv1];
        address Lv3 = _refers[Lv2];
        updateReferPower(Lv1, uids.length, 10);
        updateReferPower(Lv2, uids.length, 7);
        updateReferPower(Lv3, uids.length, 3);

        // transfer
        uint256 payAmount1 = payAmount.mul(40).div(100) - 12 * 10 ** 18 * uids.length;
        usdtToken.transfer(_marketFd, payAmount1);
        uint256 payAmount2 = payAmount.mul(10).div(100);
        usdtToken.transfer(_marketQd, payAmount2);
        usdtToken.transfer(_burnPool, payAmount2);
        uint256 payAmount3 = payAmount.mul(40).div(100);
        usdtToken.transfer(_liquidityPool, payAmount3);

        _burnContract.burn();
        _liquidityContract.addLiquidity();

        emit MintPay(msg.sender, payAmount, uids.length, referrer);
    }

    function mintNode(uint256[] calldata uids) public {
        require(uids.length == 10, "need 10 uids");
        require(block.timestamp < _mintNodeEndTime, "End mint");

        // pay & mint
        uint256 price = getPrice();
        uint256 payAmount = price.mul(uids.length);
        usdtToken.transferFrom(msg.sender, address(this), payAmount);
        INFTMinter(_officalMinterAddress).mint(uids, address(0));

        // calc
        updateNftPower(msg.sender, uids.length);

        // mint node
        INFTMinter(_ttDaoNodeAddress).safeMint(msg.sender);

        // transfer
        uint256 payAmount1 = payAmount.mul(40).div(100) - 12 * 10 ** 18 * uids.length;
        usdtToken.transfer(_marketFd, payAmount1);
        uint256 payAmount2 = payAmount.mul(10).div(100);
        usdtToken.transfer(_marketQd, payAmount2);
        uint256 payAmount3 = payAmount.mul(50).div(100);
        usdtToken.transfer(_liquidityPool, payAmount3);

        emit MintNodePay(msg.sender, payAmount, uids.length);
    }

    function updateNftPower(address account, uint256 nftCount) internal {
        MintData storage user = minters[account];
        user.live = true;
        uint256 addPower = getPrice() * nftCount;
        user.totalPower = user.totalPower.add(addPower);
        user.totalNftPower = user.totalNftPower.add(addPower);
        user.nftMintCount = user.nftMintCount.add(nftCount);

        // sale statistic
        _mintedAmount = _mintedAmount.add(nftCount);
    }

    function updateReferPower(address account, uint256 nftCount, uint256 ratio) internal {
        if (account == address(0)) {
            return;
        }

        // need did
        MintData storage user = minters[account];
        if (!user.live || user.nftMintCount == 0) {
            return;
        }

        uint256 addPower = getPower() * nftCount;
        addPower = addPower.mul(ratio).div(100);
        user.totalPower = user.totalPower.add(addPower);
        user.totalReferPower = user.totalReferPower.add(addPower);
    }

    function getPrice() public view returns(uint256) {
        return basePrice.add(_mintedAmount.div(10000).mul(10 ** 19));
    }

    function getPower() public view returns(uint256) {
        uint256 subPower = _mintedAmount.div(20000);
        if (subPower >= 5) {
            return 5;
        } else {
            return basePower.sub(subPower);
        }
    }

    function getMintedAmount() public view returns(uint256) {
        return _mintedAmount;
    }

    function getReferCount(address account) public view returns(uint256) {
        return _referCount[account];
    }

    function getMintData(address account) public view returns(
        uint256, //  nftMintCount;
        uint256, //  totalPower;
        uint256, //  totalNftPower;
        uint256, //  totalReferPower;
        uint256, //  startTime;
        uint256, //  miningPower;
        uint256, //  miningNftPower;
        uint256, //  miningReferPower;
        uint256  //  refererCount,
        ) {
        uint256 cnt = _referCount[account];
        MintData storage user = minters[account];
        return (user.nftMintCount,
                user.totalPower,
                user.totalNftPower,
                user.totalReferPower,
                user.startTime,
                user.miningPower,
                user.miningNftPower,
                user.miningReferPower,
                cnt);
    }

    function startMine() public {
        MintData storage user = minters[msg.sender];
        require(user.live && user.totalPower > 0, "no power");
        require(user.startTime == 0, "start again");

        user.startTime = block.timestamp;
        user.miningPower = user.totalPower;
        user.miningNftPower = user.totalNftPower;
        user.miningReferPower = user.totalReferPower;
    }

    function claimReward() public {
        MintData storage user = minters[msg.sender];
        require(user.nftMintCount > 0, "no did");
        require(user.live && user.miningPower > 0, "no power");
        require(user.startTime > 0 && block.timestamp > user.startTime + daySec_7, "unripe");

        // claim USDT
        uint256 mintBalance = user.miningPower * 10 ** 18 * 7;
        address[] memory path = new address[](2);
        path[0] = _ttDaoAddress;
        path[1] = _usdtAddress;
        ISwapRouter(_swapAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            mintBalance,
            0,
            path,
            msg.sender,
            block.timestamp
        );

        // burn
        uint256 burnBalance = (block.timestamp - user.startTime - daySec_7) * user.miningPower * 10 ** 18 / 86400;
        IERC20Burn(_ttDaoAddress).burn(burnBalance);

        // restart
        if (user.totalPower > 0) { 
            user.startTime = block.timestamp;
            user.miningPower = user.totalPower;
            user.miningNftPower = user.totalNftPower;
            user.miningReferPower = user.totalReferPower;
        } else {
            user.startTime = 0;
            user.miningPower = 0;
            user.miningNftPower = 0;
            user.miningReferPower = 0;
        }
    }

    function claimNode() public {
        MintData storage user = minters[msg.sender];
        require(user.nftMintCount > 0, "no did");

        uint256 left = (_referCount[msg.sender] - _referNodeCount[msg.sender]) / _mintNodeReferCount;
        if (left > 0) {
            INFTMinter(_ttDaoNodeAddress).safeBatchMint(msg.sender, left);
            _referNodeCount[msg.sender] = _referNodeCount[msg.sender].add(left * _mintNodeReferCount);
        }
    }

    function setAddress(address ttDaoAddr, address liquidityAddr, address burnAddr) public onlyOwner {
        _ttDaoAddress = ttDaoAddr;
        _burnPool = burnAddr;
        _liquidityPool = liquidityAddr;

        IERC20(_ttDaoAddress).approve(_swapAddress, MAX);
        _burnContract = ITTDAOBurn(_burnPool);
        _liquidityContract = ITTDAOLiquidity(_liquidityPool);
    }

    function setMintNodeEndTime(uint256 t) public onlyOwner {
        _mintNodeEndTime = t;
    }

    function setMintNodeReferCount(uint256 c) public onlyOwner {
        _mintNodeReferCount = c;
    }
}