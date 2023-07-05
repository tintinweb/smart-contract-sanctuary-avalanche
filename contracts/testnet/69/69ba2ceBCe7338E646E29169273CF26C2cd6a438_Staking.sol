/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library SafeMath {
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

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IPool {
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

interface IWAVAX {
    function deposit() external payable;

    function transfer(address user, uint256 wad) external returns (bool);

    function withdraw(uint256 Wad) external;

    function approve(address user, uint256 Wad) external;
}

interface IDataProvider {
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );
}

contract Staking is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 private minimumDeposit;
    uint256 private maximumDeposit;
    uint256 public contractBalance;

    address asssetToken = 0x8d3d33232bfcb7B901846AE7B8E84aE282ee2882;
    IPool public Pool = IPool(0xf319Bb55994dD1211bC34A7A26A336C6DD0B1b00);
    IWAVAX public WAVAX = IWAVAX(0x8d3d33232bfcb7B901846AE7B8E84aE282ee2882);
    IDataProvider public DataProvider =
        IDataProvider(0x0B59871DF373136bB7753A7A2675b47ffA0ccC86);

    uint256 private constant MAX = ~uint256(0);

    address Owner;
    uint256 Time = 120 seconds;

    struct StakerInfo {
        uint256 Totalstaked;
        uint256 start_time;
        bool withdrawStatus;
        bool isStaker;
    }

    struct Lottery {
        uint256 lotteryBalance;
        uint256 totalUsersAmount;
        bool islotteryActive;
    }

    mapping(uint256 =>mapping(address => StakerInfo)) public _stakerInfo;
    mapping(uint256 => Lottery) public _lotteryInfo;
    mapping(uint256 => address[]) public Users;
    mapping(uint256 => address[]) public winners;
    mapping(uint256 => bool) selectedIndexes;
    uint256 public _lotteryCounter;

    constructor() {
        Owner = msg.sender;
        token = IERC20(0xB6dA6Bf94De1462AEAFd8494219DD51eb3B64012);
    }

    receive() external payable {}

    function Stake() public payable {
        require(msg.value >= 0.00001 ether, "invalid Amount");
        StakerInfo memory _user = _stakerInfo[_lotteryCounter][msg.sender];
        if (_stakerInfo[_lotteryCounter][msg.sender].isStaker == true) {
            _user.Totalstaked += msg.value;
            _user.start_time += block.timestamp;
            _user.withdrawStatus = false;
            _user.isStaker = true;
        }

        _stakerInfo[_lotteryCounter][msg.sender] = StakerInfo({
            Totalstaked: msg.value,
            start_time: block.timestamp,
            withdrawStatus: false,
            isStaker: true
        });
        _lotteryInfo[_lotteryCounter].totalUsersAmount += msg.value;
        _lotteryInfo[_lotteryCounter].islotteryActive = true;
        Users[_lotteryCounter].push(msg.sender);
        WAVAX.deposit{value: msg.value}();
        WAVAX.approve(address(Pool), msg.value);
        Pool.supply(asssetToken, msg.value, address(this), 0);
    }

    function runLottery() public onlyOwner {
        address[] memory _users = Users[_lotteryCounter];
        address[] storage _winners = winners[_lotteryCounter];

        (uint256 tokenBalance, , , , , , , , ) = DataProvider
            .getUserReserveData(asssetToken, address(this));
        uint256 rewardAmount = tokenBalance.sub(_lotteryInfo[_lotteryCounter].totalUsersAmount);

        uint256 finalAmount = Pool.withdraw(
            asssetToken,
            rewardAmount,
            address(this)
        );
        WAVAX.withdraw(finalAmount);

        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );

        for (uint256 i = 0; i < _users.length; i++) {
            uint256 randomIndex = (seed + i) % _users.length;
            // Check if the index has already been selected
            if(_winners.length >=3){
                break ;
            }else {

            if (!selectedIndexes[randomIndex]) {
                _winners.push(_users[randomIndex]) ;
                selectedIndexes[randomIndex] = true;
            }
            }
        }

       _lotteryInfo[_lotteryCounter].lotteryBalance = address(this).balance;

        uint8[3] memory Taxes = [50, 30, 20];
        uint8[3] memory ownerShare = [10, 6, 4];

        for (uint256 i = 0; i < _winners.length; i++) {
            address _user = _winners[i];

            // uint256 userReward  = _lottery.lotteryBalance.mul(Taxes[i]).div(100);
            uint256 userReward = _lotteryInfo[_lotteryCounter].lotteryBalance.mul(Taxes[i]).div(100);
            uint256 _ownerShare = userReward.mul(ownerShare[i]).div(100);
            uint256 userSendingAmount = userReward.sub(_ownerShare);


            payable(_user).transfer(userSendingAmount);
            payable(Owner).transfer(_ownerShare);

        }
        payable(Owner).transfer(address(this).balance);
        _lotteryInfo[_lotteryCounter].islotteryActive = false;
        _lotteryCounter++;
    }

    function withdraw_(uint256 lotteryCounter_) public {

        require(
            _lotteryInfo[lotteryCounter_].islotteryActive == false,
            "you cannot Withdraw When Lottery is Active"
        );
        require(
            _stakerInfo[_lotteryCounter][msg.sender].withdrawStatus == false,
            "you are not Eligible to withdraw"
        );

        uint256 _amount = _stakerInfo[_lotteryCounter][msg.sender].Totalstaked;

        _stakerInfo[_lotteryCounter][msg.sender].Totalstaked = 0;
        _stakerInfo[_lotteryCounter][msg.sender].withdrawStatus = true;
        _stakerInfo[_lotteryCounter][msg.sender].isStaker = false;

        (uint256 sendingAmount) = Pool.withdraw(
            asssetToken,
            _amount,
            address(this)
        );
        WAVAX.withdraw(sendingAmount);
        payable(msg.sender).transfer(_amount);
    }
}
// 0x3C39dc9156aa5e00936cE32cb717eE4a8814C77C
// 0x9cd70e1DBd1dd51b4538965Af49142ed338c59b6
// 0xF4bFe95211a6542c3b32D31F912363e6b95d09E9
// 0x042A4818e7C27e76538cece2ac34f61185058112