/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-26
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

contract BridgesOfFate is Ownable, ReentrancyGuard {
    IERC20 public token;
    uint256 public latestGameId = 0;
    bool public isEnd = false;
    uint256 public lastUpdateTimeStamp;
    uint256 private constant STAGES = 5; // 13 stages
    uint256 private constant TURN_PERIOD = 120; //Now we are use 1 minute //86400; // 24 HOURS
    uint256 private constant THERSHOLD = 5;
    uint256 private constant SERIES_TWO_FEE = 0.01 ether;
    uint256 private constant _winnerRewarsds = 60;
    uint256 private constant _ownerRewarsds = 25;
    uint256 private constant _communityVaultRewarsds = 15;
    address[] internal winnersList;
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
    struct GameStatus {
        //To Handle Latest Stage
        uint256 stageNumber;
        //Game Start Time
        uint256 startAt;
        //Last Update Number
        uint256 lastUpdationDay;
    }

    struct GameMember {
        uint256 day;
        uint256 stage;
        uint256 startAt;
        bool jumpSide;
        address userWalletAddress;
        uint256 lastJumpTime;
        uint256 nftId;
    }

    mapping(uint256 => GameStatus) public GameStatusInitialized;
    mapping(bytes32 => GameMember) public Player;
    mapping(uint256 => uint256) public RandomNumber;
    mapping(uint256 => mapping(bytes32 => bool))
        public PlayerJumpStatusInTimeSilot;

    constructor(IERC20 _wrappedEther) {
        token = _wrappedEther;
    }

    modifier GameEndRules() {
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        require(
            this.dayDifferance(block.timestamp, lastUpdateTimeStamp) <= 2,
            "Game Ended !"
        );
        require(
            this.dayDifferance(block.timestamp, _gameStatus.startAt) <=
                (STAGES + THERSHOLD) - 1,
            "Game Ended !"
        );
        _;
    }

    modifier GameInitialized() {
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        require(
            block.timestamp >= _gameStatus.startAt,
            "Game start after intialized time."
        );
        _;
    }

    function dayDifferance(uint256 timeStampTo, uint256 timeStampFrom)
        public
        pure
        returns (uint256)
    {
        uint256 day_ = (timeStampTo - timeStampFrom) / TURN_PERIOD;
        return day_;
    }

    function currentDayFind() public view returns (uint256) {
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];

        uint256 day_ = (block.timestamp - _gameStatus.startAt) / TURN_PERIOD;
        return day_;
    }

    function initialize(uint256 _startAT) public onlyOwner {
        require(isEnd == false, "Game Already Initilaized");
        require(
            _startAT >= block.timestamp,
            "Time must be greater then current time."
        );
        latestGameId++;
        GameStatus storage _admin = GameStatusInitialized[latestGameId];
        _admin.startAt = _startAT;
        lastUpdateTimeStamp = _startAT;
        isEnd = true;
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

    function checkSide(uint256 stageNumber, bool userSide)
        internal
        view
        returns (bool)
    {
        uint256 stageRandomNumber = RandomNumber[stageNumber];

        if (
            (userSide == true && stageRandomNumber >= 50e9) ||
            (userSide == false && stageRandomNumber < 50e9)
        ) {
            return true;
        } else {
            return false;
        }
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

        GameMember storage _member = Player[playerId];
        if (_member.userWalletAddress != address(0)) {
            bool checkUserSide = checkSide(_member.stage, _member.jumpSide);
            require(checkUserSide == false, "Already Enterd");
            GameStatus storage _admin = GameStatusInitialized[latestGameId];
            uint256 dayPassedAfterJump = this.dayDifferance(
                _member.lastJumpTime,
                _admin.startAt
            );
            uint256 currentDay = this.dayDifferance(
                block.timestamp,
                _admin.startAt
            );
            require(
                dayPassedAfterJump + 1 < currentDay,
                "You Can only use Buy back in 24 hours"
            );
            _member.day = 0;
            _member.stage = 0;
            _member.startAt = 0;
            _member.jumpSide = false;
            _member.userWalletAddress = msg.sender;
            _member.lastJumpTime = 0;
            _member.nftId = _nftId;
        } else {
            _member.userWalletAddress = msg.sender;
            _member.nftId = _nftId;
        }
        lastUpdateTimeStamp = block.timestamp;
    }

    function balanceOfUser(address _accountOf) public view returns (uint256) {
        return token.balanceOf(_accountOf);
    }

    function entryFeeSeriesTwo(uint256 _nftId)
        public
        GameInitialized
        GameEndRules
    {
        require(
            balanceOfUser(msg.sender) >= SERIES_TWO_FEE,
            "You have insufficent balance"
        );

        bytes32 playerId = this.computeNextPlayerIdForHolder(
            msg.sender,
            _nftId,
            2
        );
        GameMember storage _member = Player[playerId];

        if (_member.userWalletAddress != address(0)) {
            bool checkUserSide = checkSide(_member.stage, _member.jumpSide);
            require(checkUserSide == false, "Already Enterd");
            GameStatus storage _admin = GameStatusInitialized[latestGameId];
            uint256 dayPassedAfterJump = this.dayDifferance(
                _member.lastJumpTime,
                _admin.startAt
            );
            uint256 currentDay = this.dayDifferance(
                block.timestamp,
                _admin.startAt
            );
            require(
                dayPassedAfterJump + 1 < currentDay,
                "You Can only use Buy back in 24 hours"
            );
            token.transferFrom(msg.sender, address(this), SERIES_TWO_FEE);
            _member.day = 0;
            _member.stage = 0;
            _member.startAt = 0;
            _member.jumpSide = false;
            _member.userWalletAddress = msg.sender;
            _member.lastJumpTime = 0;
            _member.nftId = _nftId;
        } else {
            token.transferFrom(msg.sender, address(this), SERIES_TWO_FEE);
            _member.userWalletAddress = msg.sender;
            _member.nftId = _nftId;
        }
        lastUpdateTimeStamp = block.timestamp;
    }

    function buyBackInFee(bytes32 playerId)
        external
        GameInitialized
        GameEndRules
    {
        uint256 buyBackFee = calculateBuyBackIn();
        require(
            balanceOfUser(msg.sender) >= buyBackFee,
            "You have insufficent balance"
        );
        
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        GameMember memory _member = Player[playerId];
        require(
            this.dayDifferance(block.timestamp, _member.lastJumpTime) <= 1,
            "Buy Back can be used in 24 hours only"
        );

        token.transferFrom(msg.sender, address(this), buyBackFee);
        if (RandomNumber[_member.stage - 1] >= 50e9) {
            _member.jumpSide = true;
        }
        if (RandomNumber[_member.stage - 1] < 50e9) {
            _member.jumpSide = false;
        }
        _member.stage = _member.stage - 1;
        _member.day = this.dayDifferance(
            block.timestamp,
            _gameStatus.startAt
        );
        _member.lastJumpTime = block.timestamp;
        Player[playerId] = _member;
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

    function participateInGame(bool _jumpSide, bytes32 playerId)
        public
        GameInitialized
        GameEndRules
    {
        GameMember memory _member = Player[playerId];
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        uint256 currentDay = this.dayDifferance(
            block.timestamp,
            _gameStatus.startAt
        );
        if (_member.startAt == 0 && _member.lastJumpTime == 0) {
            //On First Day when current day & member day = 0
            require(currentDay >= _member.day, "Already Jump Once In Slot");
        } else {
            //for other conditions
            require(currentDay > _member.day, "Already Jump Once In Slot");
        }
        if (_member.stage != 0) {
            require(
                (_member.jumpSide == true &&
                    RandomNumber[_member.stage] >= 50e9) ||
                    (_member.jumpSide == false &&
                        RandomNumber[_member.stage] < 50e9),
                "You are Failed"
            );
        }
        require(_member.stage != STAGES, "Reached maximum");
        if (RandomNumber[_member.stage + 1] <= 0) {
            RandomNumber[_gameStatus.stageNumber + 1] = random() * 1e9;
            _gameStatus.stageNumber = _gameStatus.stageNumber + 1;
            _gameStatus.lastUpdationDay = currentDay;
        }
        _member.startAt = block.timestamp;
        _member.stage = _member.stage + 1;
        //Day Count of Member Playing Game
        _member.day = currentDay;
        _member.jumpSide = _jumpSide;
        _member.lastJumpTime = block.timestamp;
        Player[playerId] = _member;
        GameStatusInitialized[latestGameId] = _gameStatus;
        lastUpdateTimeStamp = block.timestamp;
    }

    function getAll() public view returns (uint256[] memory) {
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        uint256[] memory ret;
        uint256 _stageNumber;
        if (_gameStatus.stageNumber > 0) {
            if (
                this.dayDifferance(block.timestamp, _gameStatus.startAt) >
                _gameStatus.lastUpdationDay
            ) {
                _stageNumber = _gameStatus.stageNumber;
            } else {
                _stageNumber = _gameStatus.stageNumber - 1;
            }

            ret = new uint256[](_stageNumber);
            for (uint256 i = 0; i < _stageNumber; i++) {
                ret[i] = RandomNumber[i];
            }
        }
        return ret;
    }

    function calculateBuyBackIn() public view returns (uint256) {
        GameStatus memory _admin = GameStatusInitialized[latestGameId];
        // uint256 days_ = this.dayDifferance(_admin.startAt);
        if (_admin.stageNumber > 0) {
            if (_admin.stageNumber <= buyBackCurve.length) {
                return buyBackCurve[_admin.stageNumber - 1];
            }
        }
        return 0;
    }

    function LateBuyBackInFee(uint256 _nftId, uint8 seriesType)
        public
        GameEndRules
    {   
        require(seriesType == 1 ||seriesType == 2 ,"Invalid seriseType");
        bytes32 playerId = this.computeNextPlayerIdForHolder(
            msg.sender,
            _nftId,
            seriesType
        );
        uint256 buyBackFee = calculateBuyBackIn();
        if(seriesType == 1){
            require(
            balanceOfUser(msg.sender) >= buyBackFee,
            "You have insufficent balance"
        );
            token.transferFrom(msg.sender, address(this), buyBackFee);
        }

        if(seriesType == 2){
            require(
            balanceOfUser(msg.sender) >= buyBackFee + SERIES_TWO_FEE,
            "You have insufficent balance"
        );
            token.transferFrom(msg.sender, address(this), buyBackFee + SERIES_TWO_FEE);
        }
        GameStatus memory _gameStatus = GameStatusInitialized[latestGameId];
        GameMember storage _member = Player[playerId];
        _member.userWalletAddress = msg.sender;
         _member.startAt = block.timestamp;
        _member.stage = _gameStatus.stageNumber - 1;
        //Day Count of Member Playing Game
        _member.day = this.dayDifferance(
            block.timestamp,
            _gameStatus.startAt
        );
        if (RandomNumber[_gameStatus.stageNumber - 1] >= 50e9) {
            _member.jumpSide = true;
        }
        if (RandomNumber[_gameStatus.stageNumber - 1] < 50e9) {
            _member.jumpSide = false;
        }
        _member.lastJumpTime = block.timestamp;
        Player[playerId] = _member;
        lastUpdateTimeStamp = block.timestamp;
    }

    function treasuryBalance() public view returns (uint256) {
        return balanceOfUser(address(this));
    }
}