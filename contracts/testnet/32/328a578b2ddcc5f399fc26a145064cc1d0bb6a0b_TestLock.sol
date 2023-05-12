/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-11
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    mapping(address => bool) private _admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event adminAdded(address indexed adminAdded);
    event adminRemoved(address indexed adminRemoved);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        _admins[0x8964A0A2d814c0e6bF96a373f064a0Af357bb4cE] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Ownable: caller is not an admin");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
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

    function addAdmin(address account) public onlyAdmin {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = true;
        emit adminAdded(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = false;
        emit adminRemoved(account);
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

interface IRouter{
    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function WAVAX() external pure returns (address);
}

interface IWAVAX{
    function deposit() external payable;
}

 contract TestLock is Ownable {
    
    event TokensLocked(address indexed _user, uint256 _amountLocked, uint256 _amountReceived, uint256 _nonce, uint256 _ethBridge);
    event TokensUnlocked(address indexed _user, uint256 _amountUnlocked, uint256 _nonce);

    struct Lock {
        address user;
        uint256 amountLocked;
        uint256 amountReceived;
        uint256 nonceLocked;
        uint256 ethBridge;
        bool processed;
    }

    struct Unlock {
        address user;
        uint256 amountUnlocked;
        uint256 nonceUnlocked;
        bool processed;
    }
    
    using SafeMath for uint256;
    mapping(uint256 => Lock) public lockByNonce;
    mapping(uint256 => Unlock) public unlockByNonce;
    mapping(address => uint256[]) public userLocks;
    mapping(address => uint256[]) public userUnlocks;
    address private router;
    address private networkToken;
    address public token;
    uint256 public nonceLocked;
    uint256 public nonceUnlocked;
    uint256 public bridgeFees;
    uint256 public maxBridge;
    bool public isPaused;

    constructor() {
       nonceLocked = 0;
       nonceUnlocked = 0;
       bridgeFees = 15*10**16;
       networkToken = 0x9668f5f55f2712Dd2dfa316256609b516292D554;
       router = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;
       token = 0x447647bBbCea1716f068114D006a9C8332b49333;
       isPaused = false;
    }
    
    event Received(address, uint);
    event Locked(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawAVAX() external onlyAdmin() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address _token, uint256 _amount, address _to) external onlyAdmin {
        IERC20(_token).transfer(_to, _amount);
    }

    function togglePause() external {
        if(isPaused) {
            require(isAdmin(msg.sender), "Ownable: caller is not an admin");
            isPaused = false;
        } else {
            require(isAdmin(msg.sender) || msg.sender == owner(), "Ownable: caller is not an admin or owner");
            isPaused = true;
        }
    }

    function getLocksByUser(address _user) external view returns (Lock[] memory) {
        
        // create a temporary array in memory
        Lock[] memory tempArray = new Lock[](userLocks[_user].length);

        // copy matching locks to the temporary array in memory
        uint256 index = 0;
        for (uint256 i = 0; i < userLocks[_user].length; i++) {
            tempArray[index] = lockByNonce[userLocks[_user][i]];
            index++;
        }

        // return the temporary array in memory
        return tempArray;
    }

    function getUnlocksByUser(address _user) external view returns (Unlock[] memory) {
        
        // create a temporary array in memory
        Unlock[] memory tempArray = new Unlock[](userUnlocks[_user].length);

        // copy matching locks to the temporary array in memory
        uint256 index = 0;
        for (uint256 i = 0; i < userUnlocks[_user].length; i++) {
            tempArray[index] = unlockByNonce[userUnlocks[_user][i]];
            index++;
        }

        // return the temporary array in memory
        return tempArray;
    }

    function lockTokens(uint256 _amount) external payable{
        require(!isPaused, "bridge is paused");
        require(msg.sender == tx.origin, "Recipient is not an EOA");
        require(msg.value <= maxBridge, "amount exceed max to bridge");
        require(msg.value >= bridgeFees, "not enough for fees");
        require(_amount > 0, "amount is null");
        require(IERC20(token).balanceOf(msg.sender) > _amount, "amount exceeds balance");
        uint256 ethBridge;
        uint256 balanceContractBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        uint256 balanceContractAfter = IERC20(token).balanceOf(address(this));
        uint256 amountReceived = balanceContractAfter.sub(balanceContractBefore);
        //Swap Half -> wETH
        address[] memory path = new address[](2);
        path[0] = IRouter(router).WAVAX();
        path[1] = networkToken;
        IRouter(router).swapExactAVAXForTokens{value : bridgeFees.div(2)}(0, path, address(this), block.timestamp)[1];
        IWAVAX(IRouter(router).WAVAX()).deposit{value : bridgeFees.div(2)}();
        if(msg.value > bridgeFees){
            ethBridge = IRouter(router).swapExactAVAXForTokens{value : msg.value.sub(15*10**16)}(0, path, address(this), block.timestamp)[1];
        }
        else{
            ethBridge = 0;
        }
        //Withdraw
        IERC20(IRouter(router).WAVAX()).transfer(owner(), IERC20(IRouter(router).WAVAX()).balanceOf(address(this)));
        IERC20(networkToken).transfer(owner(), IERC20(networkToken).balanceOf(address(this)));

        userLocks[msg.sender].push(nonceLocked);

        lockByNonce[nonceLocked] = Lock({
            user: msg.sender,
            amountLocked: _amount,
            amountReceived: amountReceived,
            nonceLocked: nonceLocked,
            ethBridge: ethBridge,
            processed: false
        });
        
        emit TokensLocked(msg.sender, _amount, amountReceived, nonceLocked, ethBridge);
        nonceLocked++;
    }

    function unlockTokens(address _user, uint256 _amount) external onlyOwner {
        require(!isPaused, "bridge is paused");
        require(_amount > 0 , "amount is null");
        require(msg.sender == tx.origin, "only EOA allowed");
        uint256 amountUnlocked = _amount.mul(90).div(100);
        require(amountUnlocked <= IERC20(token).balanceOf(address(this)), "unsufficient balance in bridge");
        IERC20(token).transfer(_user, amountUnlocked);
        userUnlocks[msg.sender].push(nonceUnlocked);

        unlockByNonce[nonceUnlocked] = Unlock({
            user: _user,
            amountUnlocked: amountUnlocked,
            nonceUnlocked: nonceUnlocked,
            processed: true
        });
        
        emit TokensUnlocked(msg.sender, amountUnlocked, nonceUnlocked);
        nonceUnlocked++;
    }

    function editLockByNonce(uint256 _nonceLocked, address _user, uint256 _amountLocked, uint256 _amountReceived, uint256 _ethBridge, bool _processed) external onlyAdmin {
        lockByNonce[_nonceLocked] = Lock({
            user: _user,
            amountLocked: _amountLocked,
            amountReceived: _amountReceived,
            nonceLocked: _nonceLocked,
            ethBridge: _ethBridge,
            processed: _processed
        });
    }

    function editUnlockByNonce(uint256 _nonceUnlocked, address _user, uint256 _amountUnlocked, bool _processed) external onlyAdmin {
        unlockByNonce[_nonceUnlocked] = Unlock({
            user: _user,
            amountUnlocked: _amountUnlocked,
            nonceUnlocked: _nonceUnlocked,
            processed: _processed
        });
    }

    function setRouterAndNetworkToken(address _networkToken, address _router) external onlyAdmin {
        router = _router;
        networkToken = _networkToken;
    }

    function setMaxBridgeAndFees(uint256 _fees, uint256 _max) external onlyAdmin {
        bridgeFees = _fees;
        maxBridge = _max;
    }

    function updateProcessed(uint256 _nonceLocked) external onlyOwner {
        require(lockByNonce[_nonceLocked].user != address(0), "nonce doesn't exists");
        require(lockByNonce[_nonceLocked].amountReceived > 0, "amount is null");
        lockByNonce[_nonceLocked].processed = true;
    }

    function setToken(address _token) external onlyAdmin {
        token = _token;
    }
    
}