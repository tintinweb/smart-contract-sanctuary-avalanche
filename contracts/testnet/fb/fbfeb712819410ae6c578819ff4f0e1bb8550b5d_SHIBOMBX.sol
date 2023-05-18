/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-14
*/

// SPDX-License-Identifier: MIT
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

    function burn(address from, uint256 amount) external;

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

interface IUnbridge {
    function editUnbridgeByNonce(uint256 _nonceUnbridged, address _user, uint256 _amountUnbridged, bool _processed) external;
    function nonceUnbridged() external view returns (uint256);
}

contract SHIBOMBX is Ownable {
    using SafeMath for uint256;
    struct UserInfos {
        address user;
        uint256 amount;
        uint256 endOfTimer;
    }

    bool public isStarted;
    bool public isEnded;
    address public token;
    address public bridge;
    uint256 private _balanceLocked;
    uint256 private _balanceRewards;
    uint256 private _balanceBurnt;
    uint256 private _balanceTeam;
    uint256 timer;
    uint256 endDate;
    mapping(address => UserInfos) public userInfos;
    address[] public users;
    

    constructor() {
       token = 0xcCA536eB0BD0d80474C4e9b144CA5758aF464f8E;
       bridge = 0x9829637570DA98Fae61f1f3CebC559E70e6D7b9d;
       isStarted = false;
       isEnded = false;
       timer = 600;
    }
    
    event Received(address, uint);
    event Locked(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawAVAX() external onlyAdmin() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address _token, uint256 _amount, address _to) external onlyAdmin() {
        IERC20(_token).transfer(_to, _amount);
    }

    function startGame() external onlyAdmin {
        require(isStarted == false, "game started");
        require(isEnded == false, "game is ended");
        isStarted = true;
    }
    
    function endGame() external onlyAdmin {
        require(isStarted == true, "game started");
        require(block.timestamp > endDate, "game will continue until the end");
        isEnded = true;
    }

    function getBalanceLocked() external view returns (uint256 balanceLocked){
        return _balanceLocked;
    }

    function getBalanceRewards() external view returns (uint256 balanceRewards){
        return _balanceRewards;
    }

    function getBalanceBurnt() external view returns (uint256 balanceLost){
        return _balanceBurnt;
    }

    function getBalanceTeam() external view returns (uint256 balanceLost){
        return _balanceTeam;
    }

    function setTokenBridgeAndTimer(address _newToken, address _newBridge, uint256 _newTimer) external onlyAdmin {
        token = _newToken;
        timer = _newTimer;
        bridge = _newBridge;
    }

    /////
    function updateDeath() external {

        for(uint256 i=0; i<users.length; i++){
            if(userInfos[users[i]].endOfTimer < block.timestamp){
                //he is dead, update userInfos
                uint256 amountToBlock = userInfos[users[i]].amount;
                uint256 amountToRewards = amountToBlock.div(3);
                uint256 amountToBurn = amountToBlock.div(3);
                uint256 amountToTeam = amountToBlock.sub(amountToRewards).sub(amountToBurn);
                _balanceRewards += amountToRewards;
                _balanceBurnt += amountToBurn;
                _balanceTeam += amountToTeam;
                _balanceLocked = _balanceLocked.sub(amountToBlock);
                userInfos[users[i]].amount = 0;
            }
        }
    
    }

    function updateDeathForUsers(address[] memory _users) external onlyOwner {
        for(uint256 i=0; i<_users.length; i++){
            if(userInfos[_users[i]].endOfTimer < block.timestamp){
                //he is dead, update userInfos
                uint256 amountToBlock = userInfos[_users[i]].amount;
                uint256 amountToRewards = amountToBlock.div(3);
                uint256 amountToBurn = amountToBlock.div(3);
                uint256 amountToTeam = amountToBlock.sub(amountToRewards).sub(amountToBurn);
                _balanceRewards += amountToRewards;
                _balanceBurnt += amountToBurn;
                _balanceTeam += amountToTeam;
                _balanceLocked = _balanceLocked.sub(amountToBlock);
                userInfos[_users[i]].amount = 0;
            }
        }
    }

    function testLockTokens(address[] memory _users, uint256 amount) external onlyOwner {
        require(isStarted, "game not started");
        require(!isEnded, "game is ended");
        
        for(uint256 i=0; i<_users.length; i++){
        IERC20(token).transferFrom(owner(), address(this), amount);
        
        if(userInfos[_users[i]].user == address(0)){
            //new player is coming
            userInfos[_users[i]] = UserInfos({
                user: _users[i],
                amount: amount,
                endOfTimer: block.timestamp+timer
            });
            users.push(_users[i]);
            _balanceLocked += amount;
        }
        
        else if(userInfos[_users[i]].endOfTimer < block.timestamp){
            //You are already dead, play again
            if(userInfos[_users[i]].amount > 0){
                uint256 amountToBlock = userInfos[_users[i]].amount;
                uint256 amountToRewards = amountToBlock.div(3);
                uint256 amountToBurn = amountToBlock.div(3);
                uint256 amountToTeam = amountToBlock.sub(amountToRewards).sub(amountToBurn);
                _balanceRewards += amountToRewards;
                _balanceBurnt += amountToBurn;
                _balanceTeam += amountToTeam;
                _balanceLocked = _balanceLocked.sub(amountToBlock);
                userInfos[_users[i]].amount = 0;
            }
            userInfos[_users[i]] = UserInfos({
                user: _users[i],
                amount: amount,
                endOfTimer: block.timestamp+timer
            });
            _balanceLocked += amount;
        }

        else{
            userInfos[_users[i]] = UserInfos({
                user: _users[i],
                amount: userInfos[_users[i]].amount += amount,
                endOfTimer: block.timestamp+timer
            });
            _balanceLocked += amount;
        }
        }
    }
    /////
    function lockTokens(uint256 amount) external {
        require(isStarted, "game not started");
        require(!isEnded, "game is ended");
        require (amount <= IERC20(token).balanceOf(msg.sender), "unsufficient balance");
        require(msg.sender == tx.origin, "EOA only");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        if(userInfos[msg.sender].user == address(0)){
            //new player is coming
            userInfos[msg.sender] = UserInfos({
                user: msg.sender,
                amount: amount,
                endOfTimer: block.timestamp+timer
            });
            users.push(msg.sender);
            _balanceLocked += amount;
        }
        
        else if(userInfos[msg.sender].endOfTimer < block.timestamp){
            //You are already dead, play again
            if(userInfos[msg.sender].amount > 0){
                uint256 amountToBlock = userInfos[msg.sender].amount;
                uint256 amountToRewards = amountToBlock.div(3);
                uint256 amountToBurn = amountToBlock.div(3);
                uint256 amountToTeam = amountToBlock.sub(amountToRewards).sub(amountToBurn);
                _balanceRewards += amountToRewards;
                _balanceBurnt += amountToBurn;
                _balanceTeam += amountToTeam;
                _balanceLocked = _balanceLocked.sub(amountToBlock);
                userInfos[msg.sender].amount = 0;
            }
            userInfos[msg.sender] = UserInfos({
                user: msg.sender,
                amount: amount,
                endOfTimer: block.timestamp+timer
            });
            _balanceLocked += amount;
        }

        else{
            userInfos[msg.sender] = UserInfos({
                user: msg.sender,
                amount: userInfos[msg.sender].amount += amount,
                endOfTimer: block.timestamp+timer
            });
            _balanceLocked += amount;
        }

    }

    function saveMe() external {
        require(isStarted, "game not started");
        require(!isEnded, "game is ended");
        require(userInfos[msg.sender].endOfTimer > block.timestamp, "you are dead");
        userInfos[msg.sender].endOfTimer = block.timestamp+timer;
    }

    function isDead(address account) public view returns (bool) {
        return userInfos[account].endOfTimer < block.timestamp;
    }
    
    function getSecondsLeft(address account) public view returns (uint256) {
        if(userInfos[account].endOfTimer > block.timestamp){
            return userInfos[account].endOfTimer.sub(block.timestamp);
        }
        else{
            return 0;
        }
    }

    function returnOnAvalanche() external {
        require(isStarted, "game not started");
        require(!isEnded, "game is ended");
        require(userInfos[msg.sender].endOfTimer > block.timestamp, "you are dead");
        require(userInfos[msg.sender].amount > 0, "you don't have locked tokens");

        IERC20(token).burn(address(this), userInfos[msg.sender].amount);
        uint256 actualUnbridgedNonce = IUnbridge(bridge).nonceUnbridged();
        IUnbridge(bridge).editUnbridgeByNonce(actualUnbridgedNonce, msg.sender, userInfos[msg.sender].amount, false);
        _balanceLocked = _balanceLocked.sub(userInfos[msg.sender].amount);
        //reset userInfos
        userInfos[msg.sender] = UserInfos({
            user: msg.sender,
            amount: 0,
            endOfTimer: 0
        });
    }

    
}