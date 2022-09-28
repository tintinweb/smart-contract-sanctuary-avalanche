//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IFeeReceiver {
    function trigger() external;
}

contract xWalrus is IERC20, Ownable {
    using SafeMath for uint256;

    // total supply
    uint256 private _totalSupply;

    // token data
    string private constant _name = "xWalrus";
    string private constant _symbol = "XWALRUS";
    uint8 private constant _decimals = 18;

    // balances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Amount Burned and Minted
    uint256 public totalBurned;
    uint256 public totalMinted;
    uint256 public totalWalrus;

    // Fee Recipients
    address public feeRecipient;

    // Trigger Fee Recipients
    bool public triggerRecipient = false;

    // Walrus Token Address
    address public immutable walrus;

    // Scale Factor
    uint256 public scaleFactor = 100;
    uint256 public constant denominator = 10**5;

    // Whether Or Not xWalrus Mint Rate Reduces As Supply Is Burned
    bool public haveRateDynamicByTokenSupply = true;

    // events
    event SetFeeRecipient(address recipient);
    event SetAutoTrigger(bool autoTrigger);

    constructor(address walrus_) {
        walrus = walrus_;
        emit Transfer(address(0), msg.sender, 0);
    }

    /////////////////////////////////
    /////    ERC20 FUNCTIONS    /////
    /////////////////////////////////

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** Transfer Function */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
            amount,
            "Insufficient Allowance"
        );
        return _transferFrom(sender, recipient, amount);
    }

    /////////////////////////////////
    /////   PUBLIC FUNCTIONS    /////
    /////////////////////////////////

    function burn(uint256 amount) external returns (bool) {
        return _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        _allowances[account][msg.sender] = _allowances[account][msg.sender].sub(
            amount,
            "Insufficient Allowance"
        );
        return _burn(account, amount);
    }

    function trigger() public {
        require(feeRecipient != address(0), "Zero Receiver");
        IFeeReceiver(feeRecipient).trigger();
    }

    function mint(uint256 amountWalrus) external {
        // take walrus to mint
        uint256 received = _takeWalrus(amountWalrus);

        // amount to mint
        uint256 amountToMint = scaledAmountOut(received);
        require(amountToMint > 0, "Zero To Mint");

        // increment total walrus
        unchecked {
            totalWalrus += received;
        }

        // trigger receiver
        trigger();

        // mint amount to sender
        _mint(msg.sender, amountToMint);
    }

    function scaledAmountOut(uint256 amount) public view returns (uint256) {
        return scale(amountOut(amount));
    }

    function amountOut(uint256 amount) public view returns (uint256) {
        return ((amount * 10**18) / redeemRate());
    }

    function scale(uint256 amount) public view returns (uint256) {
        uint256 scalar = (amount * scaleFactor) / denominator;
        return amount - scalar;
    }

    function redeemRate() public view returns (uint256) {
        if (totalMinted == 0 || totalWalrus == 0 || _totalSupply == 0) {
            return 10**18;
        }

        // average total supply and total minted amount
        uint256 denom = haveRateDynamicByTokenSupply
            ? _totalSupply
            : totalMinted;

        // totalWalrusReceived / averaged minted
        return (totalWalrus * 10**18) / denom;
    }

    /////////////////////////////////
    /////    OWNER FUNCTIONS    /////
    /////////////////////////////////

    function withdraw(address token) external onlyOwner {
        require(token != address(0), "Zero Address");
        bool s = IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
        require(s, "Failure On Token Withdraw");
    }

    function withdrawBNB() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Zero Address");
        feeRecipient = recipient;
        emit SetFeeRecipient(recipient);
    }

    function setAutoTriggers(bool triggerReceiver) external onlyOwner {
        triggerRecipient = triggerReceiver;
        emit SetAutoTrigger(triggerReceiver);
    }

    function setScaleFactor(uint256 newFactor) external onlyOwner {
        require(newFactor <= denominator / 3, "Factor Too Large");
        scaleFactor = newFactor;
    }

    function setHaveRateDynamicByTokenSupply(bool haveDynamicRate)
        external
        onlyOwner
    {
        haveRateDynamicByTokenSupply = haveDynamicRate;
    }

    //////////////////////////////////
    /////   INTERNAL FUNCTIONS   /////
    //////////////////////////////////

    /** Internal Transfer */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(recipient != address(0), "Zero Recipient");
        require(amount > 0, "Zero Amount");
        require(amount <= balanceOf(sender), "Insufficient Balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _burn(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "Zero Address");
        require(amount > 0, "Zero Amount");
        require(amount <= balanceOf(account), "Insufficient Balance");

        // delete from balance and supply
        _balances[account] = _balances[account].sub(
            amount,
            "Balance Underflow"
        );
        _totalSupply = _totalSupply.sub(amount, "Supply Underflow");

        // increment total burned
        unchecked {
            totalBurned += amount;
        }

        // emit transfer
        emit Transfer(account, address(0), amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal returns (bool) {
        require(account != address(0), "Zero Address");
        require(amount > 0, "Zero Amount");

        // delete from balance and supply
        _balances[account] += amount;
        _totalSupply += amount;

        // increment total burned
        unchecked {
            totalMinted += amount;
        }

        // emit transfer
        emit Transfer(address(0), account, amount);
        return true;
    }

    function _takeWalrus(uint256 amount) internal returns (uint256) {
        // ensure allowance is preserved
        require(
            IERC20(walrus).allowance(msg.sender, address(this)) >= amount,
            "Insufficient Allowance"
        );

        // transfer in Walrus
        uint256 before = IERC20(walrus).balanceOf(feeRecipient);
        IERC20(walrus).transferFrom(msg.sender, feeRecipient, amount);
        uint256 After = IERC20(walrus).balanceOf(feeRecipient);
        require(After > before, "Zero Received");

        // verify amount received
        return After - before;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}