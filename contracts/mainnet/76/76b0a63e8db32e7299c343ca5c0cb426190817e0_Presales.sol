/**
 *Submitted for verification at snowtrace.io on 2022-05-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

contract Presales is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // distributed token
    IERC20 private presaleToken;
    // payment token
    IERC20 private paymentToken;
    // hardcap to reach
    uint256 private hardcap;
    // private sale num
    uint256 public num;
    // private sale den
    uint256 public den;
    // max token per wallet
    uint256 private MAX_WALLET;
    // current cap
    uint256 public currentCap;
    // deadline for applying to the presales
    uint256 public deadline;
    // vested endtime (second)
    uint256 public vestedDuration;
    // vested datetime
    uint256 public vestedTime;
    // claim launchtime
    uint256 public launchtime;
    // refund trigger bool
    bool public isRFEnabled;
    // keep ownership on opening claim token
    bool public isClaimOpen;
    // open public sales
    bool public isPublicSalesOpen;
    // funds receiver address
    address public receiver;

    struct User {
        uint256 allocAmount;
        uint256 paidAmount;
        uint256 tokenAmount;
        uint256 lastClaim;
    }
    // allocation mapping per address
    mapping(address=>User) private users;

    modifier onlyWL {
        require(users[msg.sender].allocAmount > 0, "User is not whitelisted");
        _;
    }

    event PrivateSaleAttendance(address indexed address_, uint256 amount_);
    event PublicSaleAttendance(address indexed address_, uint256 amount_);

    constructor(
        IERC20 presaleToken_,
        IERC20 paymentToken_,
        uint256 deadline_,
        uint256 num_,
        uint256 den_,
        uint256 vestedDuration_,
        uint256 hardcap_,
        uint256 MAX_WALLET_) {
            require(den_ > 0 && den_ > 0, "Denominators must be greater than 0.");
            presaleToken = presaleToken_;
            paymentToken = paymentToken_;
            vestedDuration = vestedDuration_;
            deadline = deadline_;
            MAX_WALLET = MAX_WALLET_;
            den = den_;
            num = num_;
            hardcap = hardcap_;
            receiver = 0xb1fa879bb723A9dCddE9880D647D79d1F913fAa9;
    }

    function privateSale(uint256 amount_) external onlyWL {
        require(currentCap.add(amount_) <= hardcap, "Hardcap has been reach.");
        require(block.timestamp < deadline, "Presale is closed.");
        require(amount_ > 0, "The minimum amount must be greater than 0.");
        require(users[msg.sender].allocAmount >= users[msg.sender].paidAmount.add(amount_), "You exceeded the authorized amount");
        paymentToken.transferFrom(msg.sender, address(this), amount_);
        users[msg.sender].paidAmount  += amount_;
        users[msg.sender].tokenAmount += amount_.mul(den).div(num);
        currentCap += amount_;
        emit PrivateSaleAttendance(msg.sender, amount_);
    }

    function publicSale(uint256 amount_) external {
        require(isPublicSalesOpen, "Public Sale is closed.");
        require(currentCap.add(amount_) <= hardcap, "Hardcap has been reach.");
        require((users[msg.sender].tokenAmount + amount_.mul(den).div(num)) <= MAX_WALLET,  "Max token per wallet reached.");
        paymentToken.transferFrom(msg.sender, address(this), amount_);
        users[msg.sender].paidAmount  += amount_;
        users[msg.sender].tokenAmount += amount_.mul(den).div(num);
        currentCap += amount_;
        emit PublicSaleAttendance(msg.sender, amount_);
    }

    function claim() external nonReentrant {
        require(isClaimOpen, "Claim is not open yet.");
        uint256 tokenAmount = getVestedAmountToClaim(users[msg.sender].tokenAmount);
        
        users[msg.sender].lastClaim = block.timestamp;
        users[msg.sender].tokenAmount -= tokenAmount;

        presaleToken.approve(address(this), tokenAmount);
        presaleToken.transferFrom(
            address(this),
            msg.sender,
            tokenAmount
        );
    }

    function refund() external nonReentrant {
        require(isRFEnabled, "Refund is not enabled yet.");
        require(users[msg.sender].paidAmount > 0, "The minimum amount must be greater than 0.");
        uint256 paidAmount = users[msg.sender].paidAmount;
        users[msg.sender].allocAmount = 0;
        users[msg.sender].paidAmount = 0;
        users[msg.sender].tokenAmount = 0;
        users[msg.sender].lastClaim = 0;
        if (currentCap >= paidAmount) {
            currentCap -= paidAmount;
        } 
        paymentToken.approve(address(this),paidAmount);
        paymentToken.transferFrom(address(this), msg.sender,paidAmount);
    }

    // START: view functions
    function getPresaleToken() external view returns(IERC20) {
        return presaleToken;
    }

    function getPaymentToken() external view returns(IERC20) {
        return paymentToken;
    }
    
    function getPresaleDeadline() external view returns(uint256) {
        return deadline;
    }

    function getUser(address address_) external view returns(User memory) {
        return users[address_];
    }

    function getHardcap() external view returns(uint256) {
        return hardcap;
    }

    function getMaxWallet() external view returns(uint256) {
        return MAX_WALLET;
    }

    function getVestedAmountToClaim(uint256 amount_) public view returns(uint256) {
        uint256 lastClaim = users[msg.sender].lastClaim;
        require(lastClaim < vestedTime, "you have no more to claim.");
        require(vestedTime > 0, "math error: vestedTime must be greater than 0");
        if (lastClaim < launchtime) {
            lastClaim = launchtime;
        }
        uint256 rps = amount_.div(vestedTime.sub(lastClaim));
        uint256 currentTime = block.timestamp;
        if (currentTime >= vestedTime) {
            currentTime = vestedTime;
        }
        return rps.mul(currentTime.sub(lastClaim));
    }
    // END: view functions

    // START: admin
    /**
     * Withdraw funds. If `all_` is set to `true` then all funds will be withdrawn
     * @param amount_ is the amount user wants to withdraw
     * @param all_ is a boolean value to withdraw all funds
     */
    function __withdraw(uint256 amount_, bool all_) external onlyOwner {
        require(block.timestamp >= deadline, "You can not withdraw funds yet.");
        paymentToken.approve(address(this), 99999999999999999999999999999999999);
        uint256 tmpAmount = amount_;
        if (all_) {
            tmpAmount = paymentToken.balanceOf(address(this));
        }
        paymentToken.transferFrom(address(this),receiver, tmpAmount);
    }

    /**
     * Updates the allocation of an address
     * @param address_ Address of the user who will receive the allocation
     * @param amount_ Amount of the allocation
     */
    function __updateWLAllocation(address address_, uint256 amount_) external onlyOwner {
        users[address_] = User(amount_, 0,0,0);
        users[address_].allocAmount = amount_;
        users[address_].paidAmount = 0;
        users[address_].tokenAmount = 0;
        users[address_].lastClaim = 0;
    }

    /**
     * Add batch of whitelisted addresses
     * @param addresses_ is a list of addresses to wl
     * @param amount_ is the amount of allocation
     */
    function __addWLs(address[] memory addresses_, uint256 amount_) external onlyOwner {
        for(uint256 i=0;i<addresses_.length;i++){
            users[addresses_[i]].allocAmount = amount_;
            users[addresses_[i]].paidAmount = 0;
            users[addresses_[i]].tokenAmount = 0;
            users[addresses_[i]].lastClaim = 0;
        }
    }

    /**
     * Dis/Enable the refund function
     * @param isRFEnabled_ is the value (true: enable | false: disable)
     */
    function __setEnabledRefund(bool isRFEnabled_) external onlyOwner {
        isRFEnabled = isRFEnabled_;
    }
    
    function __setDeadline(uint256 deadline_) external onlyOwner {
        deadline = deadline_;
    }

    function __setOpenPublicSales(bool isPublicSalesOpen_) 
    external
    onlyOwner {
        isPublicSalesOpen = isPublicSalesOpen_;
    }
    
    function __setIsClaimOpen(bool isClaimOpen_) external onlyOwner {
        isClaimOpen = isClaimOpen_;
        isPublicSalesOpen = false;
        launchtime = block.timestamp;
        vestedTime = block.timestamp + vestedDuration;
    }
    
    function __setVestedDuration(uint256 vestedDuration_) external onlyOwner {
        vestedDuration = vestedDuration_;
    }

    function __setHardcap(uint256 hardcap_) external onlyOwner {
        hardcap = hardcap_;
    }

    function __setTokens(IERC20 paymentToken_, IERC20 presaleToken_)
    external
    onlyOwner {
        paymentToken = paymentToken_;
        presaleToken = presaleToken_;
    }

    function __setTokenPrice(uint256 num_, uint256 den_)
    external
    onlyOwner {
        num = num_;
        den = den_;
    }
    // END: admin
}