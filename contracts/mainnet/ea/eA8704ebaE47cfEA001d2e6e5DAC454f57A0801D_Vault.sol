/**
 *Submitted for verification at snowtrace.io on 2022-02-17
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

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

contract Vault is Ownable {
  using SafeMath for uint256;

  struct Stake {
    uint256 stakeCycle;
    uint256 lastClaimCycle;
    uint256 unstakeCycle;
    uint256 amount;
    uint256 totalRewards;
  }

  IERC20 public PLAYMATES;
  IERC20 public PAYMENT_TOKEN;
  address public POOL;
  address public TREASURY;
  address public MARKETING;

  string public baseUri;

  mapping(uint256 => uint256) public totalStaked;
  mapping(uint256 => uint256) public payouts;
  mapping(address => Stake) public stakers;
  mapping(address => mapping (uint256 => uint256)) public amountStaked;
  mapping(address => mapping (uint256 => bool)) public payoutClaimed;

  uint256 public firstCycleDate;
  uint256 public  cycleDuration = 864000;
 
  uint256 public minStake = 1 * 10**18;
  uint256 public maxStake = 2000 * 10**18;

  uint256 public  stakeFee = 500;
  uint256[] public  unstakeFees = [7500, 5000, 4000, 3000, 2000, 1000];
  uint256 public  unstakeFeesLength = 6;

  uint256[] public stakeDistribution = [5000, 5000];
  uint256[] public unstakeDistribution = [5000, 3000, 1000, 1000];

  event Staked(address indexed _from, uint256 amount);
  event Claimed(address indexed _from, uint256 amount);
  event Unstaked(address indexed _from, uint256 amount);

  constructor(address _PLAYMATES, address _PAYMENT_TOKEN, address _POOL, address _TREASURY, address _MARKETING, string memory _baseUri) {
    PLAYMATES = IERC20(_PLAYMATES);
    PAYMENT_TOKEN = IERC20(_PAYMENT_TOKEN);
    POOL = _POOL;
    TREASURY = _TREASURY;
    MARKETING = _MARKETING;
    baseUri = _baseUri;
    firstCycleDate = block.timestamp;
  }

  // VIEW FUNCTIONS

  function currentCycle() public view returns (uint256) {
    return (block.timestamp - firstCycleDate) / cycleDuration + 1;
  }

  function getAllRewardsOf(address user) public view returns (uint256) {
    require(currentCycle() > stakers[user].lastClaimCycle, "CLAIM2: You have no share to claim.");
    require(stakers[user].lastClaimCycle >= stakers[user].stakeCycle, "CLAIM3: You have no share to claim.");
    require(stakers[user].amount > 0, "CLAIM: You are not contributing to the pool.");
    uint256 sum = 0;
    for(uint256 i = stakers[user].lastClaimCycle; i < currentCycle(); i++) {
      uint256 share = getShareOf(user, i);
      sum += payouts[i].mul(share) / 10000;
    }
    return sum;
  }

  function getRewardsOf(address user, uint256 cycle) public view returns (uint256) {
    require(currentCycle() > stakers[user].lastClaimCycle, "CLAIM2: You have no share to claim.");
    require(stakers[user].lastClaimCycle >= stakers[user].stakeCycle, "CLAIM3: You have no share to claim.");
    require(stakers[user].amount > 0, "CLAIM: You are not contributing to the pool.");
    uint256 sum = 0;
    uint256 share = getShareOf(user, cycle);
    sum += payouts[cycle].mul(share) / 10000;
    return sum;
  }

  function getShareOf(address user, uint256 cycle) public view returns (uint256) {
    return (amountStaked[user][cycle] / totalStaked[cycle]).mul(10000);
  }

  function getShareOfCurrent(address user) public view returns (uint256) {
    return getShareOf(user, currentCycle());
  }

  function getTotalStakedCurrent() public view returns (uint256) {
    return totalStaked[currentCycle()];
  }

  function getInvestmentUri(uint256 id) public view returns (string memory) {
    return string(abi.encodePacked(baseUri, id));
  }

  function getUnstakeFees(address user) public view returns (uint256) {
    return unstakeFees[currentCycle() - stakers[user].stakeCycle  > unstakeFeesLength ? unstakeFeesLength - 1 : currentCycle() - stakers[user].stakeCycle];
  }

  // PUBLIC FUNCTIONS

  function stake(uint256 amount, bool isAdding) external {
    uint256 amountAfterFees;
    uint256 feesAmount = amount.mul(stakeFee) / 10000;
    if (stakers[msg.sender].amount == 0 || isAdding) {
      amountAfterFees = stakers[msg.sender].unstakeCycle == currentCycle() ? amount.sub(feesAmount) : amountStaked[msg.sender][currentCycle()].add(amount.sub(feesAmount));
      require(amountAfterFees.add(stakers[msg.sender].amount) >= minStake, "STAKE: Below min amount");
      require(amountAfterFees.add(stakers[msg.sender].amount) <= maxStake, "STAKE: Above max amount");
      PLAYMATES.transferFrom(msg.sender, address(this), amount);

      // FEE TRANSFERS
      PLAYMATES.transfer(POOL, feesAmount.mul(stakeDistribution[0]) / 10000);
      PLAYMATES.transfer(address(PLAYMATES), feesAmount.mul(stakeDistribution[1]) / 10000);

    } else {
      require(amountStaked[msg.sender][currentCycle()] == 0, "STAKE: You already merged");
      // amountAfterFees = amountStaked[msg.sender][currentCycle()];
      amountAfterFees = stakers[msg.sender].amount;
    }
    stakers[msg.sender] = Stake({
      stakeCycle: stakers[msg.sender].stakeCycle == 0 ? currentCycle() : stakers[msg.sender].stakeCycle,
      lastClaimCycle: stakers[msg.sender].lastClaimCycle == 0 ? currentCycle() : stakers[msg.sender].lastClaimCycle,
      unstakeCycle: 0,
      amount: amountAfterFees,
      totalRewards: stakers[msg.sender].totalRewards
    });
    amountStaked[msg.sender][currentCycle()] = amountAfterFees;
    totalStaked[currentCycle()] += amountAfterFees;
    emit Staked(msg.sender, amountAfterFees);
  }

  function claimAll() public {
    require(currentCycle() > stakers[msg.sender].lastClaimCycle, "CLAIM2: You have no share to claim.");
    require(stakers[msg.sender].lastClaimCycle >= stakers[msg.sender].stakeCycle, "CLAIM3: You have no share to claim.");
    require(stakers[msg.sender].amount > 0, "CLAIM: You are not contributing to the pool.");
    uint256 sum = 0;
    for(uint256 i = stakers[msg.sender].lastClaimCycle; i < currentCycle(); i++) {
      if (payoutClaimed[msg.sender][i] == false) {
        uint256 share = getShareOf(msg.sender, i);
        sum += payouts[i].mul(share) / 10000;
        payoutClaimed[msg.sender][i] = true;
      }
    }
    require(sum > 0, "CLAIM4: Nothing to claim");

    stakers[msg.sender].lastClaimCycle = currentCycle();
    stakers[msg.sender].totalRewards += sum;
    PAYMENT_TOKEN.transfer(msg.sender, sum);
    emit Claimed(msg.sender, sum);
  }

  function claim(uint256 cycle) public {
    require(currentCycle() > stakers[msg.sender].lastClaimCycle, "CLAIM2: You have no share to claim.");
    require(stakers[msg.sender].lastClaimCycle >= stakers[msg.sender].stakeCycle, "CLAIM3: You have no share to claim.");
    require(stakers[msg.sender].amount > 0, "CLAIM: You are not contributing to the pool.");
    require(payoutClaimed[msg.sender][cycle] == false, "CLAIM4: Nothing to claim");

    uint256 share = getShareOf(msg.sender, cycle);
    uint256 sum = payouts[cycle].mul(share) / 10000;
    require(sum > 0, "CLAIM5: Nothing to claim");
    stakers[msg.sender].lastClaimCycle = currentCycle();
    stakers[msg.sender].totalRewards += sum;
    payoutClaimed[msg.sender][cycle] = true;
    PAYMENT_TOKEN.transfer(msg.sender, sum);
    emit Claimed(msg.sender, sum);
  }

  function unstake() external {
    require(stakers[msg.sender].amount > 0, "UNSTAKE: You have nothing to unstake.");

    if (currentCycle() > stakers[msg.sender].lastClaimCycle) {
      claimAll();
    }
    
    uint256 feesRatio = getUnstakeFees(msg.sender);
    uint256 feesAmount = stakers[msg.sender].amount.mul(feesRatio) / 10000;
    uint256 amountAfterFees = stakers[msg.sender].amount.sub(feesAmount);
    stakers[msg.sender].amount = 0;
    stakers[msg.sender].unstakeCycle = currentCycle();
    amountStaked[msg.sender][currentCycle()] = 0;

    // FEE TRANSFERS
    PLAYMATES.transfer(POOL, feesAmount.mul(unstakeDistribution[0]) / 10000);
    PLAYMATES.transfer(address(PLAYMATES), feesAmount.mul(unstakeDistribution[1]) / 10000);
    PLAYMATES.transfer(TREASURY, feesAmount.mul(unstakeDistribution[2]) / 10000);
    PLAYMATES.transfer(MARKETING, feesAmount.mul(unstakeDistribution[3]) / 10000);

    PLAYMATES.transfer(msg.sender, amountAfterFees);
    emit Unstaked(msg.sender, amountAfterFees);
  }

  // ONLY OWNER FUNCTIONS

  function addPayout(uint256 cycle, uint256 amount) external onlyOwner {
    payouts[cycle] = amount;
  }

  function setBaseUri(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  function setPlaymates(address _PLAYMATES) external onlyOwner {
    PLAYMATES = IERC20(_PLAYMATES);
  }

  function setPaymentToken(address _PAYMENT_TOKEN) external onlyOwner {
    PAYMENT_TOKEN = IERC20(_PAYMENT_TOKEN);
  }

  function setPool(address _POOL) external onlyOwner {
    POOL = _POOL;
  }

  function setTreasury(address _TREASURY) external onlyOwner {
    TREASURY = _TREASURY;
  }

  function setMarketing(address _MARKETING) external onlyOwner {
    MARKETING = _MARKETING;
  }

  function setStakeDistribution(uint256[] memory _stakeDistribution) external onlyOwner {
    stakeDistribution = _stakeDistribution;
  }

  function setUnstakeDistribution(uint256[] memory _unstakeDistribution) external onlyOwner {
    unstakeDistribution = _unstakeDistribution;
  }

  function setCycleDuration(uint256 _cycleDuration) external onlyOwner {
    cycleDuration = _cycleDuration;
  }

  function setStakeFee(uint256 _stakeFee) external onlyOwner {
    stakeFee = _stakeFee;
  }

  function setUnstakeFees(uint256[] memory _unstakeFees, uint256 _unstakeFeesLength) external onlyOwner {
    unstakeFees = _unstakeFees;
    unstakeFeesLength = _unstakeFeesLength;
  }

  function setMinStakeAndMaxStake(uint256 _minStake, uint256 _maxStake) external onlyOwner {
    minStake = _minStake * 10**16;
    maxStake = _maxStake * 10**16;
  }

  function withdrawPlaymates() external onlyOwner {
    PLAYMATES.transfer(msg.sender, PLAYMATES.balanceOf(address(this)));
  }

  function withdrawPayment() external onlyOwner {
    PAYMENT_TOKEN.transfer(msg.sender, PAYMENT_TOKEN.balanceOf(address(this)));
  }
}