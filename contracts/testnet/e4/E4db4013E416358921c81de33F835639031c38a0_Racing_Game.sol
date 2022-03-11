/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-10
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


// File contracts/Racing_Game.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface INFT_Minter {
    function minter_balanceOf(address owner) external view returns (uint256);
}

interface INFT {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface IStaking {
    function stakes(uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool
        );
}

contract Racing_Game is Ownable {
    using SafeMath for uint256;

    address public devAddress;
    address public addressDEAD = 0x000000000000000000000000000000000000dEaD;
    IERC20 public shady;
    INFT_Minter public nft_minter;
    INFT public nft;
    IStaking public nftStaking;

    uint256 public constant CLAIM_TAX_PERCENTAGE = 2; // 2%

    uint256 public pricePerRace = 5 ether; // amount of $SHADY tokens - ticket
    uint8 public minRacers = 5;
    uint8 public maxRacers = 20; // max number of unique addresses to participate in race
    uint8 public mintedUserNFTs = 1; // min number of minted NFTs required to participate in race

    uint256 public epochId = 0; // each epoch has multiple races, never reuse same epoch
    uint256 public raceId = 0; // when epoch increases, never reuse same raceId !!!

    uint256 public epochDuration;
    uint256 public epochStartTimestamp;
    uint256 public epochRacesWithoutCooldown; // number of races, without cooldown
    uint256 public epochCooldownDelay; // cooldown start delay after epochStartTimestamp
    uint256 public raceCooldownDuration; // when cooldown is active, how long is delay between races
    mapping(uint256 => mapping(address => uint256))
        public epochNoOfRacesPerUser; // counter of races per user
    mapping(address => uint256) public userLastRacingTimestamp; // timestamps of last racing of a user

    mapping(uint256 => mapping(address => uint256)) public booster1Usage;
    mapping(uint256 => mapping(address => uint256)) public booster2Usage;

    /*
     * raceStatus
     * 0 = pending
     * 1 = signups
     * 2 = racing
     */
    uint8 public raceStatus = 0; // max number of unique addresses to participate in race

    uint256 public raceSignupDuration = 60; // TODO: 300
    uint256 public raceDuration = 8; // TODO: 60
    uint256 public delayBeforeAndAfterRacing = 10; // TODO: 20

    uint16 public raceSpeedMIN = 100; // min speed in each quarter
    uint16 public raceSpeedMAX = 240; // max speed in each quarter

    uint256 public raceMAXTotalSpeed = 1000; // max total speed (SUM(quarters) speed)

    uint256 public booster1From = 10001;
    uint256 public booster1To = 10500;
    uint8 public booster1Cooldown = 2;

    uint256 public booster2From = 11001;
    uint256 public booster2To = 11200;
    uint8 public booster2Cooldown = 3;

    struct Race {
        uint256 raceId;
        uint256 startSignupTimestamp;
        uint256 startRacingTimestamp;
        uint256 numberOfRacers;
    }

    struct Participant {
        uint16 quarter1Speed;
        uint16 quarter2Speed;
        uint16 quarter3Speed;
        uint16 quarter4Speed;
        uint256 totalSpeed;
        uint8 booster;
        uint8 quarter;
    }

    mapping(uint256 => Race) public raceDetails; // list of race details
    mapping(uint256 => address[]) public raceAddressList; // list of participants addresses per raceId
    mapping(uint256 => mapping(uint256 => bool)) public raceTotalSpeedList; // list of totalSpeeds per race, each total speed allowed only once!
    mapping(uint256 => mapping(address => Participant))
        public raceAddressDetailsList; // list of participants details by raceId

    mapping(uint256 => uint256[]) public epochRaceIds; // list of raceIds per epoch
    mapping(uint256 => mapping(address => uint256)) public epochPoints; // list of participant points per epoch
    mapping(uint256 => address[]) public epochAddressList; // list of participants addresses per epoch
    mapping(uint256 => mapping(address => bool)) public epochAddressListMap; // list of participants addresses per epoch - mapping

    struct EpochResult {
        address first;
        uint256 firstScore;
        address second;
        uint256 secondScore;
        address third;
        uint256 thirdScore;
        uint256 timestamp;
    }
    mapping(uint256 => EpochResult) public epochResultList; // results of epoch

    constructor(
        address _nftMinter,
        address _shady,
        address _devAddress,
        address _nft,
        address _nftStaking
    ) {
        nft_minter = INFT_Minter(_nftMinter);
        shady = IERC20(_shady);
        devAddress = _devAddress;
        nft = INFT(_nft);
        nftStaking = IStaking(_nftStaking);
    }

    function getEpochAddressListLength(uint256 _epochId)
        external
        view
        returns (uint256)
    {
        return epochAddressList[_epochId].length;
    }

    function getEpochRaceIdsLength(uint256 _epochId)
        external
        view
        returns (uint256)
    {
        return epochRaceIds[_epochId].length;
    }

    // Start new epoch
    function startEpoch(
        uint8 _mintedUserNFTs,
        uint256 _epochDuration,
        uint256 _epochRacesWithoutCooldown,
        uint256 _epochCooldownDelay,
        uint256 _raceCooldownDuration
    ) public onlyOwner {
        require(raceStatus == 0, "Race status not 0 (pending)");
        epochId += 1;
        raceId += 1;
        epochRaceIds[epochId].push(raceId);

        mintedUserNFTs = _mintedUserNFTs;
        epochDuration = _epochDuration;
        epochRacesWithoutCooldown = _epochRacesWithoutCooldown;
        epochCooldownDelay = _epochCooldownDelay;
        raceCooldownDuration = _raceCooldownDuration;

        epochStartTimestamp = block.timestamp;
        raceDetails[raceId] = Race({
            raceId: raceId,
            startSignupTimestamp: block.timestamp,
            numberOfRacers: 0,
            startRacingTimestamp: 0
        });

        raceStatus = 1; // set to Signup
    }

    // Collecting racers
    function signUp(uint256 boosterId, uint16 booster2Threshold) public {
        uint8 booster = 0;
        uint8 quarter = 0;
        uint16 slowestQuarterTime;
        uint8 slowestQuarter = 0;
        if (boosterId > 0) {
            if (nft.ownerOf(boosterId) != msg.sender) {
                (address user, , , bool staked) = nftStaking.stakes(boosterId);
                if (user != msg.sender || !staked) {
                    revert("Not booster owner");
                }
            }

            if (boosterId >= booster1From && boosterId < booster1To) {
                booster = 1;
                require(
                    booster1Usage[epochId][msg.sender] + booster1Cooldown <
                        raceId ||
                        booster1Usage[epochId][msg.sender] == 0
                );
                booster1Usage[epochId][msg.sender] = raceId;
            } else if (boosterId >= booster2From && boosterId < booster2To) {
                booster = 2;
                require(
                    booster2Usage[epochId][msg.sender] + booster2Cooldown <
                        raceId ||
                        booster2Usage[epochId][msg.sender] == 0
                );
            } else {
                revert("Invalid boosterId");
            }
        }
        require(raceStatus == 1, "Race status not 1 (signups).");
        require(
            raceDetails[raceId].numberOfRacers < maxRacers,
            "All places already filled."
        );
        require(
            nft_minter.minter_balanceOf(msg.sender) >= mintedUserNFTs,
            "Minted balance lower then required."
        );
        require(
            shady.transferFrom(msg.sender, address(this), pricePerRace),
            "Payment failed."
        );
        require(!isRacingCooldown(msg.sender), "Racer in cooldown.");

        for (uint256 i; i < raceAddressList[raceId].length; i++) {
            if (raceAddressList[raceId][i] == msg.sender) {
                revert("User already signed up to this race.");
            }
        }

        raceAddressList[raceId].push(msg.sender);
        raceDetails[raceId].numberOfRacers += 1;
        epochNoOfRacesPerUser[epochId][msg.sender] += 1;
        userLastRacingTimestamp[msg.sender] = block.timestamp;

        // Also check if address in epoch, if not add it
        if (epochAddressListMap[epochId][msg.sender] != true) {
            epochAddressListMap[epochId][msg.sender] = true;
            epochAddressList[epochId].push(msg.sender);
        }
        uint16[4] memory quartersSpeed;

        quartersSpeed[0] = semirandomNumber(
            raceDetails[raceId].numberOfRacers,
            raceSpeedMIN,
            raceSpeedMAX
        );
        quartersSpeed[1] = semirandomNumber(
            block.timestamp,
            raceSpeedMIN,
            raceSpeedMAX
        );
        if (quartersSpeed[0] > quartersSpeed[1]) {
            slowestQuarterTime = quartersSpeed[1];
            slowestQuarter = 1;
        } else {
            slowestQuarterTime = quartersSpeed[0];
        }
        quartersSpeed[2] = semirandomNumber(
            nft_minter.minter_balanceOf(msg.sender),
            raceSpeedMIN,
            raceSpeedMAX
        );
        if (slowestQuarterTime > quartersSpeed[2]) {
            slowestQuarterTime = quartersSpeed[2];
            slowestQuarter = 2;
        }
        // if first booster is active regenerate the slowest of first 3 quarters with higher min/max
        if (booster == 1) {
            quartersSpeed[slowestQuarter] = semirandomNumber(
                block.timestamp,
                200,
                230
            );
        }
        uint256 totalSpeed;
        uint8 salt = 0;
        do {
            // it's enough if we recalc only one quarter to affect totalSpeed, in case of booster we
            // only calculate once since another logic makes sure of unique speed.
            if (booster != 2 || (booster == 2 && salt == 0)) {
                quartersSpeed[3] = semirandomNumber(
                    salt,
                    raceSpeedMIN,
                    raceSpeedMAX
                );
            }

            // should only be true once, in subsequential repeats should pass trough
            if (slowestQuarterTime > quartersSpeed[3]) {
                slowestQuarterTime = quartersSpeed[3];
                slowestQuarter = 3;
            }

            // If booster 2 is in usage (is false the first time) and total speed is already used
            // then add salt to the slowest quarter until we get a unique total speed.
            if (booster2Usage[epochId][msg.sender] == raceId) {
                quartersSpeed[slowestQuarter] = 230 + salt;
            }

            totalSpeed =
                quartersSpeed[0] +
                quartersSpeed[1] +
                quartersSpeed[2] +
                quartersSpeed[3];

            // If second booster is active and treshold is meet then set fix speed of 230 to the slowest quarter.
            // And set booster as used this race. If total speed is alredy used then condition above will take care of it.
            if (booster == 2 && totalSpeed < booster2Threshold) {
                quartersSpeed[slowestQuarter] = 230;
                totalSpeed =
                    quartersSpeed[0] +
                    quartersSpeed[1] +
                    quartersSpeed[2] +
                    quartersSpeed[3];

                booster2Usage[epochId][msg.sender] = raceId;
            }

            salt++;
        } while (raceTotalSpeedList[raceId][totalSpeed] == true);

        raceTotalSpeedList[raceId][totalSpeed] = true; // set totalSpeed for this race used

        raceAddressDetailsList[raceId][msg.sender] = Participant({
            quarter1Speed: quartersSpeed[0],
            quarter2Speed: quartersSpeed[1],
            quarter3Speed: quartersSpeed[2],
            quarter4Speed: quartersSpeed[3],
            totalSpeed: totalSpeed,
            booster: booster,
            quarter: quarter
        });

        bool startRace = false;
        if (raceDetails[raceId].numberOfRacers >= maxRacers) {
            // If all spots are filled
            startRace = true;
        } else if (
            raceDetails[raceId].numberOfRacers >= minRacers &&
            (raceDetails[raceId].startSignupTimestamp + raceSignupDuration) <
            block.timestamp
        ) {
            // If enough races have signup && signup time is over
            startRace = true;
        }

        if (startRace) {
            // start race
            raceStatus = 2; // racing
            raceDetails[raceId].startRacingTimestamp =
                block.timestamp +
                delayBeforeAndAfterRacing;
        }
    }

    function isRacingCooldown(address _address) public view returns (bool) {
        if (
            epochNoOfRacesPerUser[epochId][_address] < epochRacesWithoutCooldown
        ) {
            // If user didn't complete base number of races
            return false;
        }
        if (epochStartTimestamp + epochCooldownDelay > block.timestamp) {
            // If cooldown didn't start yet
            return true;
        }
        if (
            userLastRacingTimestamp[_address] + raceCooldownDuration >
            block.timestamp
        ) {
            // User in cooldown
            return true;
        }

        // No cooldown
        return false;
    }

    // Force start race
    function startRaceManually() public {
        require(raceStatus == 1, "Race status not 1 (signups).");
        require(
            raceDetails[raceId].numberOfRacers >= minRacers,
            "Minimum filled spots required."
        );

        // start race
        raceStatus = 2; // racing
        raceDetails[raceId].startRacingTimestamp =
            block.timestamp +
            delayBeforeAndAfterRacing;
    }

    function semirandomNumber(
        uint256 randomKey,
        uint16 min,
        uint16 max
    ) private view returns (uint16) {
        uint256 _randomNumber;
        uint256 _gasleft = gasleft();
        bytes32 _blockhash = blockhash(block.number - 1);
        bytes32 _structHash = keccak256(
            abi.encode(_blockhash, randomKey, _gasleft)
        );
        _randomNumber = uint256(_structHash);
        uint16 offset = min;
        uint16 scope = max - min;
        assembly {
            _randomNumber := add(mod(_randomNumber, scope), offset)
        }
        return uint16(_randomNumber);
    }

    // Reward winner and start new race signing
    function rewardWinnerAndStartNew() public {
        require(raceStatus == 2, "Race status not 2 (racing).");
        require(
            raceDetails[raceId].startRacingTimestamp +
                raceDuration +
                delayBeforeAndAfterRacing <=
                block.timestamp,
            "Race not finished yet."
        );

        uint256 epochMaxPoints = 0;
        address epochMaxPointsAddress;
        for (uint256 i = 0; i < raceAddressList[raceId].length; i++) {
            address participant = raceAddressList[raceId][i];
            epochPoints[epochId][participant] += raceAddressDetailsList[raceId][
                participant
            ].totalSpeed;
            if (epochPoints[epochId][participant] > epochMaxPoints) {
                // it's enough that we only check addresses that race, instead of all addresses in epoch
                epochMaxPoints = epochPoints[epochId][participant];
                epochMaxPointsAddress = participant;
            }
        }

        (address first, address second, ) = _getRaceWinner(raceId);

        uint256 shadyBal = shady.balanceOf(address(this));

        // return ticket-price to winner
        shady.transfer(first, pricePerRace);

        // return half ticket-price (pricePerRace) to 2nd place
        shady.transfer(second, pricePerRace / 2);

        // return quarter ticket-price (pricePerRace) to transaction executor
        shady.transfer(msg.sender, pricePerRace / 4);

        // collect fee
        uint256 taxAmount = (shadyBal * CLAIM_TAX_PERCENTAGE + 99) / 100; // +99 to round the division up
        shady.transfer(devAddress, taxAmount);

        // burn remaining tokens
        shady.transfer(addressDEAD, shady.balanceOf(address(this)));

        // Check if epoch over
        if (epochStartTimestamp + epochDuration < block.timestamp) {
            raceStatus = 0; // pending
            // Racing is BLOCKED until we again call startEpoch();
        } else {
            raceStatus = 1;
            raceId += 1;

            epochRaceIds[epochId].push(raceId);
            raceDetails[raceId] = Race({
                raceId: raceId,
                startSignupTimestamp: block.timestamp,
                numberOfRacers: 0,
                startRacingTimestamp: 0
            });
        }
    }

    function _getRaceWinner(uint256 _raceId)
        private
        view
        returns (
            address first,
            address second,
            address third
        )
    {
        uint256 speedFirst;
        uint256 speedSecond;
        uint256 speedThird;
        for (uint256 i; i < raceAddressList[_raceId].length; i++) {
            address user = raceAddressList[_raceId][i];
            uint256 currentSpeed = raceAddressDetailsList[_raceId][user]
                .totalSpeed;
            if (currentSpeed > speedFirst) {
                third = second;
                speedThird = speedSecond;
                second = first;
                speedSecond = speedFirst;
                first = user;
                speedFirst = currentSpeed;
            } else if (currentSpeed > speedSecond) {
                third = second;
                speedThird = speedSecond;
                second = user;
                speedSecond = currentSpeed;
            } else if (currentSpeed > speedThird) {
                third = user;
                speedThird = currentSpeed;
            }
        }
    }

    function getRaceWinner(uint256 _raceId)
        public
        view
        returns (
            address first,
            address second,
            address third
        )
    {
        require(
            _raceId < raceId || (raceId == _raceId && raceStatus == 0),
            "Race not finished."
        );
        (first, second, third) = _getRaceWinner(_raceId);
    }

    function _getEpochWinner(uint256 _epochId)
        private
        view
        returns (
            address first,
            address second,
            address third
        )
    {
        uint256 speedFirst;
        uint256 speedSecond;
        uint256 speedThird;
        for (uint256 i; i < epochAddressList[_epochId].length; i++) {
            address user = epochAddressList[_epochId][i];
            uint256 currentSpeed = epochPoints[_epochId][user];
            if (currentSpeed > speedFirst) {
                third = second;
                speedThird = speedSecond;
                second = first;
                speedSecond = speedFirst;
                first = user;
                speedFirst = currentSpeed;
            } else if (currentSpeed > speedSecond) {
                third = second;
                speedThird = speedSecond;
                second = user;
                speedSecond = currentSpeed;
            } else if (currentSpeed > speedThird) {
                third = user;
                speedThird = currentSpeed;
            }
        }
    }

    function getEpochWinner(uint256 _epochId)
        public
        view
        returns (
            address first,
            address second,
            address third
        )
    {
        require(
            _epochId < epochId || (_epochId == epochId && raceStatus == 0),
            "Epoch not finished."
        );
        (first, second, third) = _getEpochWinner(_epochId);
    }

    // Setters
    function setPricePerRace(uint256 _pricePerRace) public onlyOwner {
        pricePerRace = _pricePerRace;
    }

    function setMinRacers(uint8 _minRacers) public onlyOwner {
        minRacers = _minRacers;
    }

    function setMaxRacers(uint8 _maxRacers) public onlyOwner {
        maxRacers = _maxRacers;
    }

    function setEpochDuration(uint256 _epochDuration) public onlyOwner {
        epochDuration = _epochDuration;
    }

    function setEpochRacesWithoutCooldown(uint256 _epochRacesWithoutCooldown)
        public
        onlyOwner
    {
        epochRacesWithoutCooldown = _epochRacesWithoutCooldown;
    }

    function setEpochCooldownDelay(uint256 _epochCooldownDelay)
        public
        onlyOwner
    {
        epochCooldownDelay = _epochCooldownDelay;
    }

    function setRaceCooldownDuration(uint256 _raceCooldownDuration)
        public
        onlyOwner
    {
        raceCooldownDuration = _raceCooldownDuration;
    }

    function setRaceSignupDuration(uint256 _raceSignupDuration)
        public
        onlyOwner
    {
        raceSignupDuration = _raceSignupDuration;
    }

    function setRaceDuration(uint256 _raceDuration) public onlyOwner {
        raceDuration = _raceDuration;
    }

    function setRaceSpeedMIN(uint8 _raceSpeedMIN) public onlyOwner {
        raceSpeedMIN = _raceSpeedMIN;
    }

    function setRaceSpeedMAX(uint8 _raceSpeedMAX) public onlyOwner {
        raceSpeedMAX = _raceSpeedMAX;
    }

    function setRaceMAXTotalSpeed(uint256 _raceMAXTotalSpeed) public onlyOwner {
        raceMAXTotalSpeed = _raceMAXTotalSpeed;
    }

    function setBooster1(uint256 _from, uint256 _to, uint8 _cooldown) public onlyOwner {
        booster1From = _from;
        booster1To = _to;
        booster1Cooldown = _cooldown;
    }

    function setBooster2(uint256 _from, uint256 _to, uint8 _cooldown) public onlyOwner {
        booster2From = _from;
        booster2To = _to;
        booster2Cooldown = _cooldown;
    }
}