// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract squidGameTest is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    IERC20 public token;

    Counters.Counter private _daysCounter;
    Counters.Counter private _hybirdLevel;
    Counters.Counter private _adminCounter;

    uint256 private constant TURN_PERIOD = 30; //86400; // 24 HOURS
    uint256 public start_period = 0; //
    uint256 private constant STAGES = 2; // 13 stages
    uint256 private constant LEVELSTAGES = 2; // 5 Level 2 stages
    // use this private variable to check this (STAGES + LEVELSTAGES) constant value reach or not if reach then
    //use  start the hybird Level
    uint256 private _level; // 5 Level 2 stages
    uint256 private constant _winnerRewarsds = 60;
    uint256 private constant _ownerRewarsds = 25;
    uint256 private constant _communityVaultRewarsds = 15;
    uint256 public constant Fee = 0.01 ether;
    // buyback price curve

    uint256[] public buy_back = [
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

    constructor(IERC20 _wrappedEther) {
        token = _wrappedEther;
    }

    // uint256 public start_period = 0; // beacuse start_period period are noted in when Admin Game

    uint256 public randomNumber;
    uint256 public hybirdLevelCounter;
    uint256 public adminCounter;
    uint8 private clientCount;

    address[] private winnersArray;

    // 0 =========>>>>>>>>> Owner Address
    // 1 =========>>>>>>>>> community vault Address
    address[] private Contracts = [
        0xBE0c66A87e5450f02741E4320c290b774339cE1C,
        0x1eF17faED13F042E103BE34caa546107d390093F
    ];

    event initialized(uint256 counter, uint256 startAt);
    event EntryFee(bytes32 playerId, uint256 nftId, uint256 nftSeries);

    struct GameMember {
        uint256 day;
        uint256 stage;
        uint256 level;
        uint256 score;
        uint256 startAt;
        bool feeStatus;
        bool chooes_side;
        bool resumeStatus;
    }
    /*
     * Admin Use Struct
     */
    struct GameStatus {
        uint256 startAt;
        uint256 day;
        uint256 GameLevel;
        bool dynamic_hybirdLevelStatus;
    }

    /*
     * Admin Use Struct
     */
    mapping(uint256 => GameStatus) public GameStatusInitialized;
    // Nft Owner Hash
    mapping(bytes32 => GameMember) public Player;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private winnerbalances;
    mapping(address => uint256) private ownerbalances;
    mapping(address => uint256) private vaultbalances;
    mapping(uint256 => uint256) public RandomNumber;
    //Series One && Series Two Nft Holder Count's.(****Make Seperate Count if require)
    mapping(address => uint256) public nftHoldersCount;

    /*
     * @notice Admin initialize Game into Smart contract
     */

    function initialize(
        uint256 _startAT,
        uint256 _gameLevel,
        bool _dynamicHybirdStatus
    ) public onlyOwner {
        adminCounter = _adminCounter.current();
        GameStatus memory _admin = GameStatusInitialized[adminCounter];
        _admin.startAt = _startAT;
        _admin.dynamic_hybirdLevelStatus = _dynamicHybirdStatus;
        _admin.GameLevel = _gameLevel;
        if (_gameLevel == 2 && _dynamicHybirdStatus == true) {
            randomNumber = 0;
        }
        _admin.day += 1;
        GameStatusInitialized[adminCounter] = _admin;
        emit initialized(adminCounter, block.timestamp);
    }

    /*
     * @dev Entery Fee for series one.
     * @param _nftId
     */
    function enteryFee(uint256 _nftId) public {
        bytes32 playerId = this.computeNextPlayerIdForHolder(
            msg.sender,
            _nftId,
            1
        );
        GameMember memory _member = Player[playerId];
        uint256 currentVestingCount = nftHoldersCount[msg.sender];
        nftHoldersCount[msg.sender] = currentVestingCount.add(1);
        _member.day += 1;
        _member.feeStatus = true;
        _member.resumeStatus = true;
        Player[playerId] = _member;
        emit EntryFee(playerId, _nftId, 1);
    }

    /**
     * @dev Entery Fee for series Two.
     */
    function enteryFeeSeriesTwo(uint256 _nftId, uint256 _wrappedAmount) public {
        require(balanceOfUser(msg.sender) > 0, "You have insufficent balance");
        require(
            _wrappedAmount == calculateBuyBackIn(),
            "You have insufficent balance"
        );
        //Ether Deposit Amount transfer to smart contract
        transferBalance(_wrappedAmount);

        bytes32 playerId = this.computeNextPlayerIdForHolder(
            msg.sender,
            _nftId,
            2
        );
        //Create Mapping for the Player which was paid the Fee
        GameMember memory _member = Player[playerId];
        uint256 currentVestingCount = nftHoldersCount[msg.sender];
        nftHoldersCount[msg.sender] = currentVestingCount.add(1);
        _member.day += 1;
        _member.feeStatus = true;
        _member.resumeStatus = true;
        Player[playerId] = _member;
        emit EntryFee(playerId, _nftId, 2);
    }

    /*
     * @dev Entery Fee for series one.
     * @param _nftId
     */
    function bulkEnteryFeeSeriesTwo(
        uint256[] calldata _nftId,
        uint256[] calldata _wrappedAmount
    ) public {
        for (uint256 i = 0; i < _nftId.length; i++) {
            enteryFeeSeriesTwo(_nftId[i], _wrappedAmount[i]);
        }
    }

    /*
        0 --false-- Indicate left side
        1 --true-- Indicate right side
    */
    function participateInGame(bool _chooes_side, bytes32 playerId)
        public
        GameInitialized
        After24Hours(playerId)
    {
        adminCounter = _adminCounter.current();
        GameMember memory _member = Player[playerId];

        GameStatus memory _gameStatus = GameStatusInitialized[adminCounter];
        start_period = block.timestamp;

        require(
            _member.day >= 1 && _member.resumeStatus == true,
            "You are Fail"
        );

        if (_gameStatus.GameLevel == 1) {
            require(STAGES >= _member.stage, "Reached maximum");
            if (randomNumber <= 0) {
                randomNumber = random() * 1e9;
                _member.score = randomNumber;
            }

            _member.level = 1;
            _member.startAt = block.timestamp;
        } else if (
            _gameStatus.GameLevel == 2 &&
            _gameStatus.dynamic_hybirdLevelStatus == true
        ) {
            if (LEVELSTAGES <= _member.stage) {
                if (hybirdLevelCounter > 0) {
                    require(
                        hybirdLevelCounter != 0 && hybirdLevelCounter < 50e9,
                        "Hybird Game End"
                    );
                }
                hybirdLevelCounter = random() * 1e9;
            }

            if (randomNumber <= 0) {
                randomNumber = random() * 1e9;
                _member.score = randomNumber;
            }
            _member.level = 2;
        } else if (
            _gameStatus.GameLevel == 3 &&
            _gameStatus.dynamic_hybirdLevelStatus == true
        ) {}

        // use this private variable to check this (STAGES + LEVELSTAGES) constant value reach or not if reach then
        //use  start the hybird Level
        _level += 1;
        _member.stage += 1;
        _member.day += 1;
        _member.chooes_side = _chooes_side;
        Player[playerId] = _member;
    }

    //UpdateAdmin
    function updateAdmin() internal {
        GameStatus memory _admin = GameStatusInitialized[adminCounter];
        _admin.day += 1;
        GameStatusInitialized[adminCounter] = _admin;
    }

    function checkProgres(bytes32 playerId)
        public
        returns (string memory, uint256)
    {
        uint256 period_differance = block.timestamp - start_period;
        // GameStatus memory _admin = GameStatusInitialized[_adminMappingCounter];
        if (period_differance > TURN_PERIOD) {
            if (randomNumber > 50e9) {
                uint256 daysCounter = _daysCounter.current();
                _daysCounter.increment();
                RandomNumber[daysCounter] = randomNumber = 0;
                return ("Complete with safe :)", 0);
            } else {
                randomNumber = 0;
                GameMember memory _member = Player[playerId];
                _member.resumeStatus = false;
                _member.stage -= 1;
                Player[playerId] = _member;
                return ("Complete with unsafe :)", 0);
            }
        } else {
            return ("You are in progress.Please Wait !", 0);
        }
    }

    /*
     * @notice Only owner set the reward currency (like wrapped ether token address set).
     * @dev setTokem function use to set the wrapped token.
     */

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    /*
     * @notice calculate the winner reward and withdraw rewards
     * @dev Internal func check the total deposit and calculate the reward
     * and distribute to the winner and vault and owner
     */

    function _calculateReward() internal {
        uint256 _treasuryBalance = this.treasuryBalance();
        // 60 % reward goes to winnner.
        uint256 _winners = ((_winnerRewarsds.mul(_treasuryBalance)).div(100))
            .div(winnersArray.length);
        // 25% to ownerΓÇÖs wallet
        uint256 _ownerAmount = (_ownerRewarsds.mul(_treasuryBalance)).div(100);
        ownerbalances[Contracts[0]] = _ownerAmount;
        // 15% goes to community vault
        uint256 _communityVault = (
            _communityVaultRewarsds.mul(_treasuryBalance)
        ).div(100);
        vaultbalances[Contracts[1]] = _communityVault;

        for (uint256 i = 0; i < winnersArray.length; i++) {
            winnerbalances[winnersArray[i]] = _winners;
        }
    }

    // @return The balance of the Simple Smart contract contract
    function treasuryBalance() public view returns (uint256) {
        return balanceOfUser(address(this));
    }

    // @notice Withdraw ether from Smart contract
    // @return The balance remaining for the user
    function _withdraw(uint256 withdrawAmount) internal {
        // Check enough balance available, otherwise just return balance
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            payable(msg.sender).transfer(withdrawAmount);
        }
        // return balances[msg.sender];
    }

    function withdrawWrappedEther(uint8 withdrawtype) public returns (bool) {
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

    /*
     * @notice Calculate the numebr of days after initialize the game into Smart contract
     * @dev if user enter into the advance stage mediun way after game start.
     * @return They return buyback price curve price in eth
     * This fucntion is use to determined how many ether payed to enter into the game
     */

    function calculateBuyBackIn() public view returns (uint256) {
        uint256 days_ = this.dayDifferance();
        if (days_ <= buy_back.length) {
            return buy_back[days_ - 1];
        } else {
            uint256 lastIndex = buy_back.length - 1;
            return buy_back[lastIndex];
        }
    }

    /*
     * @notice Calculate the numebr of days.
     * @dev Read functon.
     * @return They return number of days
     */
    function dayDifferance() public view returns (uint256) {
        // adminCounter = _adminCounter.current();
        GameStatus memory _admin = GameStatusInitialized[adminCounter];
        if (_admin.startAt > 0) {
            uint256 day_ = (block.timestamp - _admin.startAt) / 50;
            //86400;
            return day_;
        } else {
            return 0;
        }
    }

    /*
     * Generate a randomish number between 0 and 10.
     */
    // Warning: It is trivial to know the number this function returns BEFORE calling it.

    function random() public view returns (uint256) {
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

    /**
     * @dev Computes NFT the Next Game Partipcate identifier for a given Player address.
     */
    function computeNextPlayerIdForHolder(
        address holder,
        uint256 _nftId,
        uint8 _sersionIndex
    ) public pure returns (bytes32) {
        return computePlayerIdForAddressAndIndex(holder, _nftId, _sersionIndex);
    }

    /**
     * @dev Computes NFT the Game Partipcate identifier for an address and an index.
     */
    function computePlayerIdForAddressAndIndex(
        address holder,
        uint256 _nftId,
        uint8 _sersionIndex
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, _nftId, _sersionIndex));
    }

    function balanceOfUser(address _accountOf) public view returns (uint256) {
        return token.balanceOf(_accountOf);
    }

    function transferBalance(uint256 _amount) public {
        token.approve(address(this), _amount);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /*
     * @dev getCurrentTime function returns the current block.timestamp
     */
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    modifier After24Hours(bytes32 playerId) {
        GameMember memory _member = Player[playerId];
        uint256 calTimer = block.timestamp - _member.startAt;
        // Jump after 24 hours.
        require(calTimer >= 50, "Jump after 1 mintues.");
        _;
    }

    /*
     * Paused
     */

    modifier Resume(bytes32 playerId) {
        GameMember memory _member = Player[playerId];
        require(_member.resumeStatus, "Player is Resume Status.");
        _;
    }

    modifier GameInitialized() {
        //Check Admin time start = ?
        GameStatus memory _admin = GameStatusInitialized[adminCounter];
        require(
            (_admin.startAt > 0 && block.timestamp >= _admin.startAt),
            "Game start after intialized time."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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