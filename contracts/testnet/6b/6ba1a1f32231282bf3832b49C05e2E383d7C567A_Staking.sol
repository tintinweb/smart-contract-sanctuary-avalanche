/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-03
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

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPool {
      function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
      function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

contract Staking is Ownable{
    using SafeMath for uint256;

    IERC20 public token;
    uint256 private minimumDeposit;
    uint256 private maximumDeposit;
    address asssetToken = 0xB6dA6Bf94De1462AEAFd8494219DD51eb3B64012;
    IPool public Pool = IPool(0x8f04821360dF3D74dfd385168EFFb144aFcf6627);
    uint256 private constant MAX = ~uint256(0);

    address Owner;
    uint Time = 120 seconds;

    struct StakerInfo{
        uint256  Totalstaked;
        uint256 start_time;
        uint256 withdrawTime;
        bool withdrawStatus;
        bool isStaker;

    }


    struct Lottery{
        uint256 lotteryBalance;
        uint256 totalUsersAmount;
        bool islotteryActive;

    }

        mapping(address=>StakerInfo) public _stakerInfo;
        mapping(uint256 => Lottery) public _lotteryInfo;
        uint256 public _lotteryCounter;
        mapping (uint256 =>address[]) public Users;
        mapping(address=>uint256) public  winners;
    


    constructor(){
        Owner = msg.sender;
        token = IERC20(0xB6dA6Bf94De1462AEAFd8494219DD51eb3B64012);
    }


    function Stake(uint256 _tokenAmount) public {
        require(_tokenAmount > 0,"invalid Amount");
         StakerInfo memory _user = _stakerInfo[msg.sender];
        if(_stakerInfo[msg.sender].isStaker == true){
                _user.Totalstaked += _tokenAmount;
                _user.start_time += block.timestamp;
                _user.withdrawTime = block.timestamp + Time;
                _user.withdrawStatus = false;
                _user.isStaker = true;
        }

        _user = StakerInfo({
            Totalstaked: _tokenAmount ,
            start_time:block.timestamp,
            withdrawTime:block.timestamp + Time,
            withdrawStatus:false,
            isStaker:true

        });
        _lotteryInfo[_lotteryCounter].totalUsersAmount += _tokenAmount;
        _lotteryInfo[_lotteryCounter].islotteryActive = true;
        token.transferFrom(msg.sender,address(this), _tokenAmount);
        Pool.deposit(asssetToken, _tokenAmount,address(this), 0);

    } 

        function random(address[] memory _array) private view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(_array, block.timestamp)
                )
            );
    }


    function runLottery() public onlyOwner {

        address[] memory array = Users[_lotteryCounter];
        Lottery memory _lottery = _lotteryInfo[_lotteryCounter];

        uint256 finalAmount = Pool.withdraw(asssetToken,MAX,address(this));
        uint256 rewardAmount = finalAmount.sub(_lottery.totalUsersAmount);
        _lottery.lotteryBalance = rewardAmount;

        uint8[3] memory Taxes = [50,30,20];
        uint8[3] memory ownerShare = [10,6,4];
        

        for (uint i = 0;i<3;i++){
            uint256 index = random(array) % array.length;
            address _user = array[index];

            uint256 userReward  = _lottery.lotteryBalance.mul(Taxes[i]).div(100);
            uint256 ownerReward = userReward.mul(ownerShare[i]).div(100);
            uint256 userSendingAmount = userReward.sub(ownerReward);

            token.transfer(_user,userSendingAmount);
            token.transfer(Owner, ownerReward); 
        } 
         _lottery.islotteryActive = false;
         _lotteryCounter++;

    }  


    function withdraw_(uint256 lotteryCounter_) public {
        Lottery memory _lottery = _lotteryInfo[lotteryCounter_];
        StakerInfo memory _user = _stakerInfo[msg.sender];

       require(_lottery.islotteryActive == true,"you cannot Withdraw When Lottery is Active");
       require(_user.withdrawStatus == false,"you are Eligible to withdraw");

       uint256 _amount = _user.Totalstaked;
       _user.Totalstaked = 0;
        _user.withdrawStatus = true;
        _user.isStaker = false;
        token.transfer(msg.sender, _amount);
    }


    
}