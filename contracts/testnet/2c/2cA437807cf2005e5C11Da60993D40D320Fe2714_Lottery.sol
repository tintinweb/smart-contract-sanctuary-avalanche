/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-07
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File contracts/libraries/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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


// File contracts/Lottery.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface INFT_Minter {
    function minter_balanceOf(address owner) external view returns (uint256);
}

contract Lottery is Ownable {
    using SafeMath for uint256;

    address public devAddress;
    address public addressDEAD = 0x000000000000000000000000000000000000dEaD;
    IERC20 public shady;
    INFT_Minter public nft_minter;

    uint256 public roundId = 0;
    uint256 public roundStatus = 0; // 0 = pending, 1 = active
    uint256 public roundNoOfPicks = 5; // number of picks
    uint16 public minNumber = 1; // min random number
    uint16 public maxNumber = 9; // max random number

    uint256 public ticketId = 0; // current ticket id, each address can have multiple tickets
    uint256 public ticketPrice = 5 ether; // in shady tokens

    struct Ticket {
        address ticketOwner;
        uint8[] numbers;
    }

    mapping(uint256 => uint256[]) public roundTicketList;
    mapping(uint256 => uint256) public roundDrawTimestamp;
    mapping(uint256 => uint256) public roundReward;
    mapping(uint256 => mapping(uint256 => Ticket)) public roundTicketDetails; // roundId => ticketId => Ticket
    mapping(uint256 => mapping(address => uint256[])) public roundAddressTickets; // roundId => address => ticketId
    mapping(uint256 => mapping(address => uint256)) public roundAddressFreeTickets;

    mapping(uint256 => uint16[]) public roundResult;

    constructor(
        address _nftMinter,
        address _shady,
        address _devAddress
    ) {
        nft_minter = INFT_Minter(_nftMinter);
        shady = IERC20(_shady);
        devAddress = _devAddress;
    }

    function getRoundTicketListLength(uint256 _roundId) external view returns (uint256) {
        return roundTicketList[_roundId].length;
    }

    function getRoundAddressTicketsLength(uint256 _roundId, address _address) external view returns (uint256) {
        return roundAddressTickets[_roundId][_address].length;
    }

    function getRoundTicketDetailsOwner(uint256 _roundId, uint256 _ticketId) external view returns (address) {
        return roundTicketDetails[_roundId][_ticketId].ticketOwner;
    }

    function getRoundTicketDetailsNumbers(uint256 _roundId, uint256 _ticketId, uint256 _index) external view returns (uint8) {
        return roundTicketDetails[_roundId][_ticketId].numbers[_index];
    }

    function getSubmitExpired() public view returns (bool) {
        return block.timestamp >= roundDrawTimestamp[roundId];
    }

    function startRound(
        uint256 _roundReward,
        uint256 _roundDrawTimestamp
    ) public onlyOwner {
        require(roundStatus == 0, 'Round already started.');
        require(_roundReward > 0, '_roundReward needs to be greater than 0.');
        roundId += 1;
        roundStatus = 1; // active
        roundReward[roundId] = _roundReward;
        roundDrawTimestamp[roundId] = _roundDrawTimestamp;
    }

    function submitTicket(uint8[][] calldata _numbers) public {
        require(roundStatus == 1, 'Round not started yet.');
        require(!getSubmitExpired(), 'Time to submit ticket expired.');
        require(_numbers.length > 0, 'No ticket submitted.');

        uint256 shadyRequired = 0;
        for (uint16 iTicket = 0; iTicket < _numbers.length; iTicket ++) {
            require(_numbers[iTicket].length != roundNoOfPicks, 'Invalid number of picks in ticket.');

            // each minter allowed to submit as many free tickets as mints done
            if (roundAddressFreeTickets[roundId][msg.sender] >= nft_minter.minter_balanceOf(msg.sender)) {
                shadyRequired += ticketPrice;
            } else {
                // Free ticket
                roundAddressFreeTickets[roundId][msg.sender] += 1;
            }

            ticketId += 1; // set ticket number
            roundTicketList[roundId].push(ticketId);
            roundAddressTickets[roundId][msg.sender].push(ticketId);

            roundTicketDetails[roundId][ticketId] = Ticket({
               ticketOwner: msg.sender,
               numbers: _numbers[iTicket]
            });
        }

        if (shadyRequired > 0) {
            require(
                shady.transferFrom(msg.sender, addressDEAD, ticketPrice),
                "Payment failed."
            );
        }
    }

    function drawResult() public onlyOwner {
        require(roundStatus == 1, 'Round not started yet.');
        require(getSubmitExpired(), 'Time to submit ticket did NOT expire yet.');

        for (uint16 numberIdx = 0; numberIdx < roundNoOfPicks; numberIdx ++) {
            uint16 randNumber;
            if (numberIdx == 0) {
                randNumber = semirandomNumber(roundTicketList[roundId].length);
            } else if (numberIdx == 1) {
                randNumber = semirandomNumber(block.timestamp);
            } else if (numberIdx == 2) {
                randNumber = semirandomNumber(block.timestamp - roundTicketList[roundId].length);
            } else if (numberIdx == 3) {
                randNumber = semirandomNumber(block.timestamp + roundTicketList[roundId].length);
            } else {
                randNumber = semirandomNumber(numberIdx);
            }
            roundResult[roundId].push(randNumber);
        }

        roundStatus = 0; // pause until owner starts new round
    }

    function semirandomNumber(uint256 randomKey) private view returns (uint16) {
        uint256 _randomNumber;
        uint256 _gasleft = gasleft();
        bytes32 _blockhash = blockhash(block.number - 1);
        bytes32 _structHash = keccak256(
            abi.encode(_blockhash, randomKey, _gasleft)
        );
        _randomNumber = uint256(_structHash);
        uint16 offset = minNumber;
        uint16 scope = maxNumber - minNumber;
        assembly {
            _randomNumber := add(mod(_randomNumber, scope), offset)
        }
        return uint16(_randomNumber);
    }

    // Setters
    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function setMinNumber(uint16 _minNumber) public onlyOwner {
        minNumber = _minNumber;
    }

    function setMaxNumber(uint16 _maxNumber) public onlyOwner {
        maxNumber = _maxNumber;
    }

    function setRoundNoOfPicks(uint256 _roundNoOfPicks) public onlyOwner {
        roundNoOfPicks = _roundNoOfPicks;
    }

    function setRoundReward(uint256 _roundReward) public onlyOwner {
        roundReward[roundId] = _roundReward;
    }

    function setRoundDrawTimestamp(uint256 _roundDrawTimestamp) public onlyOwner {
        roundDrawTimestamp[roundId] = _roundDrawTimestamp;
    }
}