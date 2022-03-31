// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TheWheelOfReturns is Ownable {
    using SafeMath for uint256;

    uint256 private constant DAYS_MAX_FOR_RANDOM = 96; // to generate random number from 5 - 100
    uint256 private constant PERC_MAX_FOR_RANDOM = 4;  // to generate random number from 5 - 100

    uint256 private constant TOTAL_PERC = 1000;
    uint256 private constant BENIFICIARY_PERC = 100; //10%
    uint256 private constant MIN_INVESTMENT = 0.1 ether;
    uint256 private constant MAX_SPIN_COUNT = 100;
    uint256[] private REFERRAL_PERCENTS = [50, 30, 15, 5, 5];
    uint256 private constant TOTAL_REF = 105;

    // uint256 private constant TIME_STEP = 1 days;
    uint256 private constant TIME_STEP = 1 minutes; //fast test mode

    address payable benificiaryAddress;

    uint256 public totalInvested;
    uint256 public totalWithdrawal;
    uint256 public totalReferralReward;
    uint256 public totalSpinCount;

    struct Spin {
        uint256 maxDays;
        uint256 percent;
        uint256 amount;
        uint256 totalReturn;
        uint256 start;
        uint256 finish;
    }

    struct Investor {
        address addr;
        address ref;
        uint256[5] refs;
        Spin[] spins;
        uint256 totalInvestment;
        uint256 totalWithdraw;
        uint256 totalRef;
        uint256 investmentCount;
        uint256 investmentTime;
        uint256 lastWithdrawDate;
    }

    mapping(address => Investor) public investors;

    event OnInvest(address investor, uint256 amount);
    event OnWithdraw(address investor, uint256 amount);

    bool public isSpinOpen = false;

    constructor(address payable _benificiaryAddress) {
        require(
            _benificiaryAddress != address(0),
            "Benificiary address cannot be null"
        );
        benificiaryAddress = _benificiaryAddress;
    }

    function changeBenificiary(address payable newAddress) public onlyOwner {
        require(newAddress != address(0), "Address cannot be null");
        benificiaryAddress = newAddress;
    }

    function setIsSpinOpen(bool _newValue) public onlyOwner {
        require(
            _newValue != isSpinOpen,
            "New value cannot be same with previous value"
        );
        isSpinOpen = _newValue;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function invest(address _ref) public payable {
        require(isSpinOpen, "Cannot invest at the moment");
        if (_invest(msg.sender, _ref, msg.value)) {
            emit OnInvest(msg.sender, msg.value);
        }
    }

    function _invest(
        address _addr,
        address _ref,
        uint256 _amount
    ) private returns (bool) {
        require(msg.value >= MIN_INVESTMENT, "Minimum investment is 0.1 AVAX");
        require(_ref != _addr, "Ref address cannot be same with caller");
        require(
            investors[_addr].investmentCount < MAX_SPIN_COUNT,
            "Cannot invest more than 100"
        );

        uint256 day = random(DAYS_MAX_FOR_RANDOM);
        uint256 perc = random(PERC_MAX_FOR_RANDOM).mul(10);

        Investor storage investor = investors[_addr];

        if (investor.addr == address(0)) {
            investor.addr = _addr;
            investor.investmentTime = block.timestamp;
            investor.lastWithdrawDate = block.timestamp;
        }

        if (investor.ref == address(0)) {
            if (investors[_ref].totalInvestment > 0) {
                investor.ref = _ref;
            }

            address upline = investor.ref;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    investors[upline].refs[i] = investors[upline].refs[i].add(
                        1
                    );
                    upline = investors[upline].ref;
                } else break;
            }
        }

        if (investor.ref != address(0)) {
            address upline = investor.ref;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(
                        TOTAL_PERC
                    );
                    investors[upline].totalRef = investors[upline].totalRef.add(
                        amount
                    );
                    totalReferralReward = totalReferralReward.add(amount);
                    payable(upline).transfer(amount);
                    upline = investors[upline].ref;
                } else break;
            }
        } else {
            uint256 amount = _amount.mul(TOTAL_REF).div(TOTAL_PERC);
            benificiaryAddress.transfer(amount);
            totalReferralReward = totalReferralReward.add(amount);
        }

        investor.investmentCount = investor.investmentCount.add(1);
        totalSpinCount = totalSpinCount.add(1);
        uint256 totalReturn = getTotalReturn(_amount, day, perc);
        uint256 startTime = block.timestamp;
        uint256 endTime = block.timestamp.add(day.mul(TIME_STEP));
        investor.spins.push(
            Spin(day, perc, _amount, totalReturn, startTime, endTime)
        );
        investor.totalInvestment = investor.totalInvestment.add(_amount);
        totalInvested = totalInvested.add(_amount);

        _sendRewardOnInvestment(_amount);
        return true;
    }

    function _sendRewardOnInvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBenificiary = _amount.mul(BENIFICIARY_PERC).div(
            TOTAL_PERC
        );
        benificiaryAddress.transfer(rewardForPrimaryBenificiary);
    }

    function getTotalReturn(
        uint256 amount,
        uint256 maxDays,
        uint256 perc
    ) public pure returns (uint256) {
        return amount.mul(perc).div(TOTAL_PERC).mul(maxDays);
    }

    function getContractInformation()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 contractBalance = getBalance();
        return (
            contractBalance,
            totalInvested,
            totalWithdrawal,
            totalSpinCount,
            totalReferralReward
        );
    }

    function getInvestorRefs(address addr)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Investor storage investor = investors[addr];
        return (
            investor.refs[0],
            investor.refs[1],
            investor.refs[2],
            investor.refs[3],
            investor.refs[4]
        );
    }

    function getUserAmountOfSpins(address userAddress)
        public
        view
        returns (uint256)
    {
        return investors[userAddress].spins.length;
    }

    function getUserSpinInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint256 maxDays,
            uint256 percent,
            uint256 amount,
            uint256 totalReturn,
            uint256 start,
            uint256 finish
        )
    {
        Investor storage user = investors[userAddress];

        maxDays = user.spins[index].maxDays;
        percent = user.spins[index].percent;
        amount = user.spins[index].amount;
        totalReturn = user.spins[index].totalReturn;
        start = user.spins[index].start;
        finish = user.spins[index].finish;
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        Investor storage user = investors[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.spins.length; i++) {
            if (user.lastWithdrawDate < user.spins[i].finish) {
                uint256 share = user
                    .spins[i]
                    .amount
                    .mul(user.spins[i].percent)
                    .div(TOTAL_PERC);
                uint256 from = user.spins[i].start > user.lastWithdrawDate
                    ? user.spins[i].start
                    : user.lastWithdrawDate;
                uint256 to = user.spins[i].finish < block.timestamp
                    ? user.spins[i].finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            }
        }

        return totalAmount;
    }

    function withdraw() public {
        require(investors[msg.sender].lastWithdrawDate.add(TIME_STEP) <= block.timestamp,"Withdrawal limit is 1 withdrawal in 24 hours");
        Investor storage user = investors[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        totalWithdrawal = totalWithdrawal.add(totalAmount);
        user.totalWithdraw = user.totalWithdraw.add(totalAmount);
        user.lastWithdrawDate = block.timestamp;

        payable(msg.sender).transfer(totalAmount);

        emit OnWithdraw(msg.sender, totalAmount);
    }

    function random(uint256 number) private view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % number) + 5;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function subz(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
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