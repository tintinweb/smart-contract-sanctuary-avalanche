/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-21
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-19
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
}

// File @openzeppelin/contracts/utils/math/[email protected]

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// File contracts/squidGameTest.sol
pragma solidity ^0.8.9;

contract BridgesOfFateTestV4 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    IERC20 public token;

    Counters.Counter private _gameIdCounter;

    uint256 public  lastActionAt;
    uint256 public gameIdCounter;
    uint256 private randomNumber;
    uint256 private constant STAGES = 5; // 13 stages
    uint256 private constant TURN_PERIOD = 300; //Now we are use 2 minute //86400; // 24 HOURS
    uint256 private constant THERSHOLD = 5;
    uint256 public  constant Fee = 0.01 ether;
    
    uint256 private constant _winnerRewarsds = 60;
    uint256 private constant _ownerRewarsds = 25;
    uint256 private constant _communityVaultRewarsds = 15;
    bool private _isEnd;

    address[] public winnersList;
    // 0 =========>>>>>>>>> Owner Address
    // 1 =========>>>>>>>>> community vault Address
    address[2] private Contracts = [
        0xBE0c66A87e5450f02741E4320c290b774339cE1C,
        0x1eF17faED13F042E103BE34caa546107d390093F
    ];

    // buyBack price curve /Make the private this variable./
    uint256[11] public buyBackCurve = [
        0.005 ether,
        0.01 ether,
        0.02 ether,
        0.04 ether,
        0.08 ether,
        0.15 ether,
        0.3 ether,
        0.6 ether,
        1.25 ether,
        2.5 ether,
        5 ether
    ];

    struct GameMember {
        uint256 day;
        uint256 stage;
        uint256 startAt;
        uint256 overAt; 
        bool jumpSide;
        address userWalletAddress;
    }
   
    struct GameStatus {
        uint256 startAt;
        uint256 lastJumpAt;
        uint256 stageNumber;
    }

    mapping(bytes32 => GameMember) public Player;
    mapping(uint256 => GameStatus) public GameStatusInitialized;

    mapping(address => uint256) private balances;
    mapping(address => uint256) private winnerbalances;
    mapping(address => uint256) private ownerbalances;
    mapping(address => uint256) private vaultbalances;
    mapping(uint256 => uint256) private RandomNumber;
    mapping(bytes32 => bool)    private PlayerFeeStatusAtStage;
    mapping(uint256 => mapping(bytes32 => bool)) public PlayerJumpStatusInTimeSilot;

    event Initialized(uint256 CurrentGameID, uint256 StartAt);
    event EntryFee(bytes32 PlayerId, uint256 NftId, uint256 NftSeries,uint256 FeeAmount);
    event ParticipateOfPlayerInGame(bytes32 PlayerId, uint256 RandomNo);
    
    constructor(IERC20 _wrappedEther) {
        token = _wrappedEther;
    }
    
    function initialize(uint256 _startAT) public onlyOwner {
        _gameIdCounter.increment();
        gameIdCounter = _gameIdCounter.current();
        GameStatus storage _admin = GameStatusInitialized[gameIdCounter];
        // require(_isEnd == false, "Game in progress");
        require(_startAT > block.timestamp,"Time greater then current time.");
        _admin.startAt      = _startAT;
        _admin.lastJumpAt   = _startAT;
        lastActionAt        = block.timestamp;
        // _isEnd              = true;
        GameStatusInitialized[gameIdCounter] = _admin;
        delete winnersList;
        emit Initialized(gameIdCounter, block.timestamp);
    }

    function entryFeeForSeriesOne(uint256 _nftId)
        public
        GameInitialized
        GameEndRules
    {
        bytes32 playerId = this.computeNextPlayerIdForHolder(
            msg.sender,
            _nftId,
            1
        );

        GameMember memory _member = Player[playerId];
        _member.overAt = 0;
        _member.userWalletAddress = msg.sender;
        if (_member.stage >= 1) {
            _member.stage = _member.stage - 1;
        }
        lastActionAt        = block.timestamp;
        Player[playerId] = _member;
        PlayerFeeStatusAtStage[playerId] = true;
        PlayerJumpStatusInTimeSilot[_member.day][playerId] = false;
        emit EntryFee(playerId, _nftId, 1,0);
    }

    function entryFeeSeriesTwo(uint256 _nftId, uint256 _wrappedAmount)
        public
        GameInitialized
        GameEndRules
    {
        require(balanceOfUser(msg.sender) >= _wrappedAmount, "You have insufficent balance");
        // require(_wrappedAmount == calculateBuyBackIn(),"You have insufficent balance");
        token.transferFrom(msg.sender, address(this), _wrappedAmount);
        bytes32 playerId = this.computeNextPlayerIdForHolder(
            msg.sender,
            _nftId,
            2
        );
        GameMember memory _member = Player[playerId];
        _member.overAt = 0;
        lastActionAt        = block.timestamp;
        _member.userWalletAddress = msg.sender;
        if (_member.stage >= 1) {
            _member.stage = _member.stage - 1;
        }
        Player[playerId] = _member;
        PlayerFeeStatusAtStage[playerId] = true;
        PlayerJumpStatusInTimeSilot[_member.day][playerId] = false;
        emit EntryFee(playerId, _nftId, 2,_wrappedAmount);
    }

    function bulkEntryFeeSeriesTwo(
        uint256[] calldata _nftId,
        uint256[] calldata _wrappedAmount
    ) public GameInitialized {
        for (uint256 i = 0; i < _nftId.length; i++) {
            entryFeeSeriesTwo(_nftId[i], _wrappedAmount[i]);
        }
    }

    /*
        false-- Indicate left side
        true-- Indicate right side
    */
    function participateInGame(bool _jumpSide, bytes32 playerId)
        public
        GameInitialized
        GameEndRules
    {
        GameMember memory _member = Player[playerId];
        GameStatus memory _gameStatus = GameStatusInitialized[_gameIdCounter.current()];
        
        require(PlayerJumpStatusInTimeSilot[this.dayDifferance(_gameStatus.startAt) + 1][playerId] == false, "Already jumped in this Slot");
        require(block.timestamp >= _gameStatus.startAt && PlayerFeeStatusAtStage[playerId] == true,"You have been Failed.");
        require(STAGES >= _member.stage, "Reached maximum");
        lastActionAt        = block.timestamp;

        if (RandomNumber[_member.stage] <= 0) {
            randomNumber = random() * 1e9;
            RandomNumber[_gameStatus.stageNumber] = randomNumber;
            _gameStatus.stageNumber = _gameStatus.stageNumber + 1;
            _gameStatus.lastJumpAt = block.timestamp;
        }else{
            randomNumber = RandomNumber[_member.stage];
        }
        _member.startAt = block.timestamp;
        _member.stage = _member.stage + 1;
        _member.day = _member.day + 1;
        _member.jumpSide = _jumpSide;

        //If Jump Postion Failed the Player
        if ((_member.jumpSide == true && randomNumber >= 50e9) || (_member.jumpSide == false && randomNumber <= 50e9)) {
            PlayerFeeStatusAtStage[playerId] = true;
            if(_member.stage == STAGES){
                winnersList.push(msg.sender);
            }
            if(this.dayDifferance(_gameStatus.startAt) == STAGES || this.dayDifferance(_gameStatus.startAt) == STAGES + THERSHOLD){
                _isEnd = false;
            }
        }else {
            if(this.dayDifferance(_gameStatus.startAt) == STAGES || this.dayDifferance(_gameStatus.startAt) == STAGES + THERSHOLD){
                _isEnd = false;
            }
            PlayerFeeStatusAtStage[playerId] = false;
            _member.overAt = block.timestamp;
        }
        
        Player[playerId] = _member;
        PlayerJumpStatusInTimeSilot[_member.day][playerId] = true; //Next Jump After set silce period. For this reason status change againest Player 
        GameStatusInitialized[gameIdCounter] = _gameStatus;
        emit ParticipateOfPlayerInGame(playerId,randomNumber);
    }

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    function _calculateReward() internal {
        uint256 _treasuryBalance = this.treasuryBalance();
        // 60 % reward goes to winnner.
        uint256 _winners = ((_winnerRewarsds.mul(_treasuryBalance)).div(100))
            .div(winnersList.length);
        // 25% to owner wallet
        uint256 _ownerAmount = (_ownerRewarsds.mul(_treasuryBalance)).div(100);
        ownerbalances[Contracts[0]] = _ownerAmount;
        // 15% goes to community vault
        uint256 _communityVault = (
            _communityVaultRewarsds.mul(_treasuryBalance)
        ).div(100);
        vaultbalances[Contracts[1]] = _communityVault;

        for (uint256 i = 0; i < winnersList.length; i++) {
            winnerbalances[winnersList[i]] = _winners;
        }
    }

    function treasuryBalance() public view returns (uint256) {
        return balanceOfUser(address(this));
    }

    function _withdraw(uint256 withdrawAmount) internal {
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            payable(msg.sender).transfer(withdrawAmount);
        }
    }

    function withdrawWrappedEther(uint8 withdrawtype)
        public
        nonReentrant
        returns (bool)
    {
        // Check enough balance available, otherwise just return false
        if (withdrawtype == 0) {
            //owner
            require(Contracts[0] == msg.sender, "Only Owner use this");
            _withdraw(ownerbalances[msg.sender]);
            return true;
        } else if (withdrawtype == 1) {
            //vault
            require(Contracts[1] == msg.sender, "Only vault use this");
            _withdraw(vaultbalances[msg.sender]);
            return true;
        } else {
            //owners
            _withdraw(winnerbalances[msg.sender]);
            return true;
        }
    }


    function calculateBuyBackIn() public view returns (uint256) {
        GameStatus memory _admin = GameStatusInitialized[gameIdCounter];
        uint256 days_ = this.dayDifferance(_admin.startAt);
        if (days_ > 0) {
            if (days_ <= buyBackCurve.length) {
                return buyBackCurve[days_ - 1];
            } else {
                uint256 lastIndex = buyBackCurve.length - 1;
                return buyBackCurve[lastIndex];
            }
        } else {
            return buyBackCurve[0];
            // return 0;
        }
    }

    function dayDifferance(uint256 dayTimeStamp) public view returns (uint256) {
        // GameStatus memory _admin = GameStatusInitialized[gameIdCounter];
            uint256 day_ = (block.timestamp - dayTimeStamp) / TURN_PERIOD;
            return day_;
    }

    function random() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % 100;
    }

 
    function computeNextPlayerIdForHolder(
        address holder,
        uint256 _nftId,
        uint8 _seriesIndex
    ) public pure returns (bytes32) {
        return computePlayerIdForAddressAndIndex(holder, _nftId, _seriesIndex);
    }

    function computePlayerIdForAddressAndIndex(
        address holder,
        uint256 _nftId,
        uint8 _seriesIndex
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, _nftId, _seriesIndex));
    }

    function balanceOfUser(address _accountOf) public view returns (uint256) {
        return token.balanceOf(_accountOf);
    }

    /*
     * @dev getCurrentStage function returns the current stage
     */
    function getCurrentStage(bytes32 playerId) public view returns (uint256) {
        GameMember memory _member = Player[playerId];

            if (PlayerFeeStatusAtStage[playerId] == false && _member.stage >= 1) {
                return _member.stage - 1;
            } else {
                return _member.stage;
            }
        
    }

    function isSafed(bytes32 playerID) public view returns (bool) {
        GameStatus memory _gameStatus = GameStatusInitialized[gameIdCounter];
        if(this.dayDifferance(_gameStatus.startAt) > 0){
            return PlayerFeeStatusAtStage[playerID];
        }
        return false;
    }
    function getAll() public view returns (uint256[] memory) {
        GameStatus memory _gameStatus   = GameStatusInitialized[gameIdCounter];
        uint256[] memory ret;
        uint256 _stageNumber;
        if(this.dayDifferance(_gameStatus.lastJumpAt) > 0){
            _stageNumber = _gameStatus.stageNumber;
        }else{
            _stageNumber = _gameStatus.stageNumber - 1;
        }
        if (_gameStatus.stageNumber > 0) {
            ret = new uint256[](_stageNumber);
            for (uint256 i = 0; i < _stageNumber; i++) {
                ret[i] = RandomNumber[i];
            }
        }
        return ret;
    }

    modifier GameEndRules() {
        GameStatus memory _gameStatus = GameStatusInitialized[gameIdCounter];
        require(this.dayDifferance(_gameStatus.lastJumpAt) <= 2, "Game Ended !");
        require(this.dayDifferance(_gameStatus.startAt) <= (STAGES + THERSHOLD) - 1, "Game Ended !");
        _;
    }

    modifier GameInitialized() {
        GameStatus memory _gameStatus = GameStatusInitialized[gameIdCounter];
        require((_gameStatus.startAt > 0 && block.timestamp >= _gameStatus.startAt),"Game start after intialized time.");
        _;
    }
}