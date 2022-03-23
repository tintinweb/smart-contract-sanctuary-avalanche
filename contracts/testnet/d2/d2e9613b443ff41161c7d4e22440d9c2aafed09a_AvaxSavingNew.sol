/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-22
*/

/** 
 *  SourceUnit: z:\LabTests\avalanche-stake-contracts\contracts\AvaxSavingNew.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: z:\LabTests\avalanche-stake-contracts\contracts\AvaxSavingNew.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




/** 
 *  SourceUnit: z:\LabTests\avalanche-stake-contracts\contracts\AvaxSavingNew.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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




/** 
 *  SourceUnit: z:\LabTests\avalanche-stake-contracts\contracts\AvaxSavingNew.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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


/** 
 *  SourceUnit: z:\LabTests\avalanche-stake-contracts\contracts\AvaxSavingNew.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
////import "@openzeppelin/contracts/utils/math/SafeMath.sol";
////import "@openzeppelin/contracts/utils/Address.sol";
////import "@openzeppelin/contracts/utils/Context.sol";

contract AvaxSavingNew is ReentrancyGuard, Context {
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant INVEST_MIN_AMOUNT = 0.1 ether;
    uint256[] public REFERRAL_PERCENTS = [80, 50, 20];
    uint256[] public STAKE_REWARD_COMMISSION_PERCENTS = [100, 50, 20];
    uint256 public constant PROJECT_DEV = 20;
    uint256 public constant MARKETING_ALLOCATION = 20;
    uint256 public constant RESERVE_ALLOCATION = 60;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    // uint256 public constant TIME_STEP = 1 days;
    uint256 public constant TIME_STEP = 60 seconds;
    uint256 public totalStaked;
    uint256 public TOTAL_COMISSION;
    uint256 public TOTAL_REWARDS;
    uint256 public TOTAL_USERS;

    //Added bool status here for unStake
    struct Deposit {
        uint8 plan;
        bool status;
        bool claimedStatus;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
    }
    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        mapping(uint256 => address[]) downline;
        uint256[3] levels;
        uint256 claimed;
        uint256 bonus;
        uint256 totalBonus;
        uint256 totalStakingCommission;
        uint256 totalStakingRewardCommission;
        uint256 totalProofShare;
        uint256 claimableProofShare;
    }
    //TODO: changed internal to public
    mapping(address => User) public users;

    address payable public _donator;
    address payable _manager;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    event Newbie(address user);
    event NewDeposit(
        address indexed user,
        uint8 plan,
        bool status,
        bool claimedStatus,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish
    );
    event UnStaked(
        address indexed user,
        uint8 plan,
        bool status,
        bool claimedStatus,
        uint256 percent,
        uint256 amount,
        uint256 profit,
        uint256 start,
        uint256 finish,
        uint256 unStakedAt
    );
    event Claim(
        address indexed user,
        uint256 stakeCommision,
        uint256 userProofShare,
        uint256 stakeRewardCommision,
        uint256 totalAmount
    );
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event reserveFundsPaid(address indexed user, uint256 totalAmount);

    constructor(address payable wallet) {
        require(!isContract(wallet), "contract cannot be donator");
        require(!msg.sender.isContract(), "contract cannot be the owner");

        _manager = payable(msg.sender);
        _donator = wallet;
        //TODO:Change days =>minutes/hours accordingly
        plans.push(Plan(10, 20));
        plans.push(Plan(20, 21));
        plans.push(Plan(30, 22));
        plans.push(Plan(60, 23));
        plans.push(Plan(120, 24));
        plans.push(Plan(180, 25));
    }

    function stake(address referrer, uint8 plan) public payable nonReentrant {
        require(msg.value >= INVEST_MIN_AMOUNT, "min amount 0.1 AVAX");
        require(msg.sender != referrer, "cannot reffer to self");
        require(plan < 6, "Incorrect plan");

        uint256 fee = msg.value.mul(PROJECT_DEV + RESERVE_ALLOCATION).div(
            PERCENTS_DIVIDER
        );

        _donator.transfer(fee);
        emit reserveFundsPaid(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length == 0) {
                user.referrer = referrer;
                TOTAL_USERS = TOTAL_USERS.add(1);
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    // bool stat = userAlreadyReffred(upline, msg.sender);
                    // if (stat == false) {
                    //     users[upline].downline[i].push(msg.sender);
                    // }
                    users[upline].downline[i].push(msg.sender);
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            // if (
            //     users[referrer].deposits.length == 0 && referrer != msg.sender
            // ) {
            //     user.referrer = referrer;
            //     TOTAL_USERS = TOTAL_USERS.add(1);
            // }
            address upline = user.referrer;
            require(upline == referrer, "already refered");
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    //Added this line
                    // TOTAL_USERS = TOTAL_USERS.add(1);
                    // bool stat = userAlreadyReffred(upline, msg.sender);
                    // if (stat == false) {
                    //     users[upline].downline[i].push(msg.sender);
                    // }
                    users[upline].downline[i].push(msg.sender);
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );

                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );

                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        (uint256 percent, uint256 profit, , uint256 finish) = getResult(
            plan,
            msg.value
        );
        user.deposits.push(
            Deposit(
                plan,
                true,
                false,
                percent,
                msg.value,
                profit,
                block.timestamp,
                finish
            )
        );

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(
            msg.sender,
            plan,
            true,
            false,
            percent,
            msg.value,
            profit,
            block.timestamp,
            finish
        );
    }

    //Claimable Total reward
    function claimReward() public nonReentrant {
        User storage user = users[msg.sender];
        uint256 totalReward;
        uint256 totalAmount = getUserStakeReward(msg.sender);
        uint256 stakeCommision = getUserStakeCommision(msg.sender);
        uint256 userProofShare = user.claimableProofShare;
        //new
        totalReward = totalAmount;
        uint256 stakeRewardCommision = getUserStakeRewardCommision(msg.sender);

        if (stakeCommision > 0) {
            user.bonus = 0;
            user.totalStakingCommission = user.totalStakingCommission.add(
                stakeCommision
            );
            totalAmount = totalAmount.add(stakeCommision);
        }
        if (stakeRewardCommision > 0) {
            user.bonus = 0;
            user.totalStakingRewardCommission = user
                .totalStakingRewardCommission
                .add(stakeRewardCommision);
            totalAmount = totalAmount.add(stakeRewardCommision);
        }
        if (userProofShare > 0) {
            user.claimableProofShare = 0;
            totalAmount = totalAmount.add(userProofShare);
        }

        require(totalAmount > 0, "User has no claimable rewards");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        user.claimed = user.claimed.add(totalAmount);
        TOTAL_COMISSION = TOTAL_COMISSION.add(stakeCommision).add(
            stakeRewardCommision
        );
        TOTAL_REWARDS = TOTAL_REWARDS.add(totalReward);
        payable(msg.sender).transfer(totalAmount);
        emit Claim(
            msg.sender,
            stakeCommision,
            userProofShare,
            stakeRewardCommision,
            totalAmount
        );
    }

    //TODO: FIX HERE
    function unStake(uint256 investmentIndex)
        public
        nonReentrant
        returns (Deposit[] memory)
    {
        User storage user = users[msg.sender];
        require(
            user.deposits[investmentIndex].status != false,
            "cannot unStake unStaked plan"
        );
        require(
            user.deposits[investmentIndex].claimedStatus != false,
            "cannot unStake Claimed plan"
        );

        if (block.timestamp < user.deposits[investmentIndex].finish) {
            uint256 finalAmount = user
                .deposits[investmentIndex]
                .amount
                .mul(20)
                .div(PERCENTS_DIVIDER);
            finalAmount = user.deposits[investmentIndex].amount - finalAmount;
            user.deposits[investmentIndex].status = false;
            user.deposits[investmentIndex].claimedStatus = true;
            payable(msg.sender).transfer(finalAmount);
            emit UnStaked(
                msg.sender,
                user.deposits[investmentIndex].plan,
                user.deposits[investmentIndex].status,
                user.deposits[investmentIndex].claimedStatus,
                user.deposits[investmentIndex].percent,
                user.deposits[investmentIndex].amount,
                user.deposits[investmentIndex].profit,
                user.deposits[investmentIndex].start,
                user.deposits[investmentIndex].finish,
                block.timestamp
            );
        }
        if (block.timestamp > user.deposits[investmentIndex].finish) {
            user.deposits[investmentIndex].status = false;
            user.deposits[investmentIndex].claimedStatus = true;
            payable(msg.sender).transfer(user.deposits[investmentIndex].amount);
            emit UnStaked(
                msg.sender,
                user.deposits[investmentIndex].plan,
                user.deposits[investmentIndex].status,
                user.deposits[investmentIndex].claimedStatus,
                user.deposits[investmentIndex].percent,
                user.deposits[investmentIndex].amount,
                user.deposits[investmentIndex].profit,
                user.deposits[investmentIndex].start,
                user.deposits[investmentIndex].finish,
                block.timestamp
            );
        }

        return getUserAllDepositsInfo(msg.sender);
    }

    function getUserStakeRewardCommision(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        uint256 totalAmount;
        for (uint256 i = 0; i < 3; i++) {
            if (users[userAddress].downline[i].length > 0) {
                for (
                    uint256 k = 0;
                    k < users[userAddress].downline[i].length;
                    k++
                ) {
                    totalAmount = totalAmount.add(
                        getUserStakeReward(users[userAddress].downline[i][k])
                            .mul(STAKE_REWARD_COMMISSION_PERCENTS[i])
                            .div(PERCENTS_DIVIDER)
                    );
                }
            }
        }
        return totalAmount;
    }

    function getResult(uint8 plan, uint256 deposit)
        public
        view
        returns (
            uint256 percent,
            uint256 profit,
            uint256 apr,
            uint256 finish
        )
    {
        percent = plans[plan].percent;

        profit = deposit.mul(plans[plan].percent).div(PERCENTS_DIVIDER).mul(
            plans[plan].time
        );
        apr = plans[plan].percent.mul(365).mul(PERCENTS_DIVIDER);
        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function userAlreadyReffred(address topAddress, address newAddress)
        public
        view
        returns (bool)
    {
        address[] memory level0;
        address[] memory level1;
        address[] memory level2;
        bool status;
        (level0, level1, level2) = getUserDownlineAddress(topAddress);
        if (level0.length > 0) {
            for (uint256 i = 0; i < level0.length; i++) {
                if (newAddress == level0[i]) {
                    status = true;
                } else {
                    status = false;
                }
            }
        }
        if (level1.length > 0) {
            for (uint256 i = 0; i < level1.length; i++) {
                if (newAddress == level1[i]) {
                    status = true;
                } else {
                    status = false;
                }
            }
        }
        if (level2.length > 0) {
            for (uint256 i = 0; i < level2.length; i++) {
                if (newAddress == level2[i]) {
                    status = true;
                } else {
                    status = false;
                }
            }
        }
        return status;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getUserStakeReward(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            //Only active deposits
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].status == true) {
                    uint256 share = user
                        .deposits[i]
                        .amount
                        .mul(user.deposits[i].percent)
                        .div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint
                        ? user.deposits[i].start
                        : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp
                        ? user.deposits[i].finish
                        : block.timestamp;
                    if (from < to) {
                        totalAmount = totalAmount.add(
                            share.mul(to.sub(from)).div(TIME_STEP)
                        );
                    }
                }
            }
        }

        return totalAmount;
    }

    //TODO:new here
    function getUserStakeRewardArray(address userAddress)
        public
        view
        returns (uint256[] memory)
    {
        User storage user = users[userAddress];
        uint256[] memory planTotalReward;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            //Only active deposits

            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].status == true) {
                    uint256 totalAmount;
                    uint256 share = user
                        .deposits[i]
                        .amount
                        .mul(user.deposits[i].percent)
                        .div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint
                        ? user.deposits[i].start
                        : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp
                        ? user.deposits[i].finish
                        : block.timestamp;
                    if (from < to) {
                        totalAmount = totalAmount.add(
                            share.mul(to.sub(from)).div(TIME_STEP)
                        );
                        planTotalReward[i] = totalAmount;
                    }
                } else {
                    planTotalReward[i] = 0;
                }
            }
        }

        return planTotalReward;
    }

    //TODO:new
    function getUserStakingDetails(address userAddress)
        public
        view
        returns (
            uint256 totalStakeReward,
            uint256 claimableStakeReward,
            uint256 totalExestingStake,
            uint256 claimedStakedReward,
            uint256 claimableProofShare,
            uint256 totalProofShare
        )
    {
        claimableStakeReward = getUserStakeReward(userAddress);
        totalExestingStake = getUserTotalExestingStake(userAddress);
        claimedStakedReward = users[userAddress].claimed;
        totalStakeReward = claimableStakeReward.add(claimedStakedReward);
        claimableProofShare = users[userAddress].claimableProofShare;
        totalProofShare = users[userAddress].totalProofShare;
    }

    function getUserReferalDetails(address userAddress)
        public
        view
        returns (
            uint256 totalCommunity,
            uint256 totalExestingStake,
            uint256 stakingCommission,
            uint256 claimedCommission,
            uint256 stakingRewardCommission,
            uint256 claimableCommision,
            uint256 totalComission
        )
    {
        (, , , totalCommunity) = getUserDownlineCount(userAddress);

        for (uint256 i = 0; i < 3; i++) {
            for (
                uint256 k = 0;
                k < users[userAddress].downline[i].length;
                k++
            ) {
                totalExestingStake = totalExestingStake.add(
                    getUserTotalExestingStake(users[userAddress].downline[i][k])
                );
                stakingCommission = users[userAddress].totalStakingCommission;
                claimedCommission = claimedCommission.add(
                    getUserClaimed(users[userAddress].downline[i][k])
                );

                stakingRewardCommission = users[userAddress]
                    .totalStakingRewardCommission;

                uint256 userTotalClaimable;
                (, , , , userTotalClaimable) = getUserClaimable(
                    users[userAddress].downline[i][k]
                );
                claimableCommision = claimableCommision.add(userTotalClaimable);
                totalComission = stakingCommission.add(stakingRewardCommission);
            }
        }
    }

    function getUserReferalComissionDetails(address userAddress)
        public
        view
        returns (
            uint256 level0StakedAmount,
            uint256 level0StakeComission,
            uint256 level0StakeRewardComission,
            uint256 level1StakedAmount,
            uint256 level1StakeComission,
            uint256 level1StakeRewardComission,
            uint256 level2StakedAmount,
            uint256 level2StakeComission,
            uint256 level2StakeRewardComission
        )
    {
        for (uint256 i = 0; i < 3; i++) {
            for (
                uint256 k = 0;
                k < users[userAddress].downline[i].length;
                k++
            ) {
                if (i == 0) {
                    level0StakedAmount = level0StakedAmount.add(
                        getUserTotalExestingStake(
                            users[userAddress].downline[i][k]
                        )
                    );
                    level0StakeComission = level0StakeComission.add(
                        getUserStakeCommision(users[userAddress].downline[i][k])
                    );

                    uint256 scrNew;
                    (, , , scrNew) = getUserAllStakeRewardCommissions(
                        users[userAddress].downline[i][k]
                    );
                    level0StakeRewardComission =
                        level0StakeRewardComission +
                        scrNew;
                }
                if (i == 1) {
                    level1StakedAmount = level1StakedAmount.add(
                        getUserTotalExestingStake(
                            users[userAddress].downline[i][k]
                        )
                    );
                    level1StakeComission = level1StakeComission.add(
                        getUserStakeCommision(users[userAddress].downline[i][k])
                    );

                    uint256 scrNew;
                    (, , , scrNew) = getUserAllStakeRewardCommissions(
                        users[userAddress].downline[i][k]
                    );
                    level1StakeRewardComission =
                        level1StakeRewardComission +
                        scrNew;
                }
                if (i == 2) {
                    level2StakedAmount = level2StakedAmount.add(
                        getUserTotalExestingStake(
                            users[userAddress].downline[i][k]
                        )
                    );
                    level2StakeComission = level2StakeComission.add(
                        getUserStakeCommision(users[userAddress].downline[i][k])
                    );

                    uint256 scrNew;
                    (, , , scrNew) = getUserAllStakeRewardCommissions(
                        users[userAddress].downline[i][k]
                    );
                    level2StakeRewardComission =
                        level2StakeRewardComission +
                        scrNew;
                }
            }
        }
    }

    function getUserAllStakeRewardCommissions(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 level0;
        uint256 level1;
        uint256 level2;
        uint256 total;

        for (uint256 i = 0; i < 3; i++) {
            if (users[userAddress].downline[i].length > 0) {
                for (
                    uint256 k = 0;
                    k < users[userAddress].downline[i].length;
                    k++
                ) {
                    if (i == 0) {
                        level0 = getUserStakeReward(
                            users[userAddress].downline[i][k]
                        );

                        {
                            level0 = level0.mul(
                                STAKE_REWARD_COMMISSION_PERCENTS[i]
                            );
                        }
                        {
                            level0 = level0.div(PERCENTS_DIVIDER);
                        }
                    }
                    if (i == 1) {
                        level1 = getUserStakeReward(
                            users[userAddress].downline[i][k]
                        );

                        {
                            level1 = level1.mul(
                                STAKE_REWARD_COMMISSION_PERCENTS[i]
                            );
                        }
                        {
                            level1 = level1.div(PERCENTS_DIVIDER);
                        }
                    }
                    if (i == 2) {
                        level2 = getUserStakeReward(
                            users[userAddress].downline[i][k]
                        );

                        {
                            level2 = level2.mul(
                                STAKE_REWARD_COMMISSION_PERCENTS[i]
                            );
                        }
                        {
                            level2 = level2.div(PERCENTS_DIVIDER);
                        }
                    }

                    total = getUserStakeReward(
                        users[userAddress].downline[i][k]
                    );

                    {
                        total = total.mul(STAKE_REWARD_COMMISSION_PERCENTS[i]);
                    }
                    {
                        total = total.div(PERCENTS_DIVIDER);
                    }
                }
            }
        }

        return (level0, level1, level2, total);
    }

    function getUserDownlineCount(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 total = users[userAddress]
            .levels[0]
            .add(users[userAddress].levels[1])
            .add(users[userAddress].levels[2]);
        return (
            users[userAddress].levels[0],
            users[userAddress].levels[1],
            users[userAddress].levels[2],
            total
        );
    }

    function getUserDownlineAddress(address userAddress)
        public
        view
        returns (
            address[] memory,
            address[] memory,
            address[] memory
        )
    {
        return (
            users[userAddress].downline[0],
            users[userAddress].downline[1],
            users[userAddress].downline[2]
        );
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserStakeCommision(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserClaimable(address userAddress)
        public
        view
        returns (
            uint256 myStakingRewards,
            uint256 myAffliateStakeComission,
            uint256 myAffliateStakeRewardComission,
            uint256 myProofShareReward,
            uint256 total
        )
    {
        myStakingRewards = getUserStakeReward(userAddress);
        myAffliateStakeComission = getUserStakeCommision(userAddress);
        myAffliateStakeRewardComission = getUserStakeRewardCommision(
            userAddress
        );
        myProofShareReward = users[userAddress].claimableProofShare;
        total = myStakingRewards
            .add(myAffliateStakeComission)
            .add(myAffliateStakeRewardComission)
            .add(myProofShareReward);
    }

    function getUserTotalExestingStake(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            if (users[userAddress].deposits[i].finish > block.timestamp) {
                if (users[userAddress].deposits[i].status == true) {
                    amount = amount.add(users[userAddress].deposits[i].amount);
                }
            }
        }
    }

    function getUserDepositsCount(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserClaimed(address userAddress) public view returns (uint256) {
        return users[userAddress].claimed;
    }

    function getUserAllDepositsInfo(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        return users[userAddress].deposits;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            bool status,
            bool claimedStatus,
            uint256 percent,
            uint256 amount,
            uint256 profit,
            uint256 start,
            uint256 finish
        )
    {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        status = user.deposits[index].status;
        claimedStatus = user.deposits[index].claimedStatus;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }

    function claimPromotionalReward(address payable userAddress, uint256 amount)
        external
        onlyPromotion
    {
        require(address(this).balance > 0, "Balance is Zero");
        require(amount > 0, "should be NON ZERO");
        payable(userAddress).transfer(amount);
    }

    function claimProofSharingReward(address userAddress, uint256 amount)
        external
        onlyProofSharing
    {
        require(address(this).balance > 0, "Balance is Zero");
        require(amount > 0, "should be NON ZERO");
        users[userAddress].claimableProofShare = amount;
        users[userAddress].totalProofShare = users[userAddress]
            .totalProofShare
            .add(amount);
    }

    modifier onlyProofSharing() {
        require(_manager == _msgSender(), "onlyProofSharing");
        _;
    }

    modifier onlyPromotion() {
        require(_manager == _msgSender(), "onlyPromotion");
        _;
    }
}