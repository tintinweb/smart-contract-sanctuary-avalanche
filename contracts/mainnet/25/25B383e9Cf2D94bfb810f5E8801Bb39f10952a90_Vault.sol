/**
 *Submitted for verification at snowtrace.io on 2022-04-06
*/

/**
 *Submitted for verification at snowtrace.io on 2022-04-06
*/

/**
 *Submitted for verification at snowtrace.io on 2022-02-27
*/

/**
 *Submitted for verification at snowtrace.io on 2022-02-22
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

interface IMansionsHelper {
  function getClaimFee (address sender) external view returns (uint256);
  function newTax () external view returns (uint256);
  function claimUtility(uint64[] calldata _nodes, address whereTo, uint256 neededAmount, address excessAmountReceiver, address nodesOwner) external;
}

interface IMansionManager {
    function getAddressRewards(address account) external view returns (uint);
    function getUserMultiplier(address from) external view returns (uint256);
}

interface ITaxManager {
  function execute(uint256 remainingRewards, address receiver) external;
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

  address public TRUST_V3 = 0x82fdACD535F6EEa710d1ab67746e9e68366Dce8f;

  bool public paused;
  string public baseUri;

  mapping(uint256 => uint256) public totalStaked;
  mapping(uint256 => uint256) public payouts;
  mapping(address => Stake) public stakers;
  mapping(address => mapping (uint256 => uint256)) public amountStaked;
  mapping(address => mapping (uint256 => bool)) public payoutClaimed;
  mapping(address => mapping (uint256 => bool)) public stakedDuringCycle;
  mapping(address => bool) public blacklist;
  mapping(address => bool) public migrated;

  uint256 public firstCycleDate;
  uint256 public  cycleDuration = 864000;
 
  uint256 public minStake = 1 * 10**18;
  uint256 public maxStake = 2000 * 10**18;

  uint256 public  stakeFee = 50000;
  uint256[] public  unstakeFees = [750000, 500000, 400000, 300000, 200000, 100000];
  uint256 public  unstakeFeesLength = 6;

  uint256[] public stakeDistribution = [500000, 500000];
  uint256[] public unstakeDistribution = [500000, 300000, 100000, 100000];

  uint256 public precision = 1000000;

  IMansionsHelper public MANSIONSHEPLER = IMansionsHelper(0x19234452F1005D85FCEa70380AB75EbBF6259f48);
  IMansionManager public MANSIONSMANAGER = IMansionManager(0xc4a25F823582d9ccf5cf8C8BF5338073e7a51676);
  ITaxManager public TAXMANAGER;

  event Staked(address indexed _from, uint256 amount);
  event Migrated(address indexed _from, uint256 amount);
  event Claimed(address indexed _from, uint256 amount);
  event Unstaked(address indexed _from, uint256 amount);

  constructor(address _PLAYMATES, address _PAYMENT_TOKEN, address _POOL, address _TREASURY, address _MARKETING, address _MANSIONSHEPELR, address _TAXMANAGER, string memory _baseUri) {
    PLAYMATES = IERC20(_PLAYMATES);
    PAYMENT_TOKEN = IERC20(_PAYMENT_TOKEN);
    POOL = _POOL;
    TREASURY = _TREASURY;
    MARKETING = _MARKETING;
    MANSIONSHEPLER = IMansionsHelper(_MANSIONSHEPELR);
    TAXMANAGER = ITaxManager(_TAXMANAGER);
    baseUri = _baseUri;
    firstCycleDate = block.timestamp;
  }

  // VIEW FUNCTIONS

  function currentCycle() public view returns (uint256) {
    return (block.timestamp - firstCycleDate) / cycleDuration + 1;
  }

  function getAllRewardsOf(address user) public view returns (uint256) {
    uint256 sum = 0;
    for(uint256 i = stakers[user].lastClaimCycle; i < currentCycle(); i++) {
      if (payoutClaimed[user][i] == true) continue;
      uint256 share = getShareOf(user, i);
      sum += payouts[i].mul(share) / precision;
    }
    return sum;
  }

  function getRewardsOf(address user, uint256 cycle) public view returns (uint256) {
    uint256 sum = 0;
    uint256 share = getShareOf(user, cycle);
    sum += payouts[cycle].mul(share) / precision;
    return sum;
  }

  function getShareOf(address user, uint256 cycle) public view returns (uint256) {
    if (stakedDuringCycle[user][cycle] == false) return 0;
    return amountStaked[user][cycle].mul(precision) / totalStaked[cycle];
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

  function getStakeCycleOfUser(address user) public view returns (uint256) {
    return stakers[user].stakeCycle;
  }

  function getLastClaimCycleOfUser(address user) public view returns (uint256) {
    return stakers[user].lastClaimCycle;
  }

  function getUnstakeCycleOfUser(address user) public view returns (uint256) {
    return stakers[user].unstakeCycle;
  }

  function getAmountStakedOfUser(address user) public view returns (uint256) {
    return stakers[user].amount;
  }

  function getTotalRewardsOfUser(address user) public view returns (uint256) {
    return stakers[user].totalRewards;
  }

  // PUBLIC FUNCTIONS
  function migrate() external {
      require(paused == false, "MIGRATE: Contract is paused");
      require(blacklist[msg.sender] == false, "MIGRATE: You are blacklisted");
      require(migrated[msg.sender] == false, "MIGRATE: You already migrated");
      require(Vault(TRUST_V3).amountStaked(msg.sender, 2) > 0, "MIGRATE: You were not staking.");
      require(Vault(TRUST_V3).stakedDuringCycle(msg.sender, 2) == true, "MIGRATE: You were not staking");
      require(currentCycle() == 1, "MIGRATE: Migration period is over");

      migrated[msg.sender] = true;
      stakers[msg.sender] = Stake({
        stakeCycle: 1,
        lastClaimCycle: 1,
        unstakeCycle: 0,
        amount: Vault(TRUST_V3).amountStaked(msg.sender, 2),
        totalRewards: 0
      });
      amountStaked[msg.sender][currentCycle()] = stakers[msg.sender].amount;
      totalStaked[currentCycle()] += stakers[msg.sender].amount;
      stakedDuringCycle[msg.sender][currentCycle()] = true;
      emit Migrated(msg.sender, stakers[msg.sender].amount);
  }

  function stake(uint256 amount, bool isAdding) external {
    require(paused == false, "STAKE: Contract is paused.");
    require(blacklist[msg.sender] == false, "STAKE: You are blacklisted");
    uint256 amountAfterFees;
    uint256 feesAmount = amount.mul(stakeFee) / precision;
    if (stakers[msg.sender].amount == 0 || isAdding) {
      amountAfterFees = stakers[msg.sender].unstakeCycle == currentCycle() ? amount.sub(feesAmount) : amountStaked[msg.sender][currentCycle()].add(amount.sub(feesAmount));
      require(amount.sub(feesAmount).add(stakers[msg.sender].amount) >= minStake, "STAKE: Below min amount");
      require(amount.sub(feesAmount).add(stakers[msg.sender].amount) <= maxStake, "STAKE: Above max amount");
      PLAYMATES.transferFrom(msg.sender, address(this), amount);

      // FEE TRANSFERS
      PLAYMATES.transfer(POOL, feesAmount.mul(stakeDistribution[0]) / precision);
      PLAYMATES.transfer(address(PLAYMATES), feesAmount.mul(stakeDistribution[1]) / precision);

    } else {
      require(amountStaked[msg.sender][currentCycle()] == 0, "STAKE: You already merged");
      amountAfterFees = stakers[msg.sender].amount;
    }
    stakers[msg.sender] = Stake({
      stakeCycle: currentCycle(),
      lastClaimCycle: stakers[msg.sender].lastClaimCycle == 0 ? currentCycle() : stakers[msg.sender].lastClaimCycle,
      unstakeCycle: 0,
      amount: amountAfterFees,
      totalRewards: stakers[msg.sender].totalRewards
    });
    if (isAdding) totalStaked[currentCycle()] -= amountStaked[msg.sender][currentCycle()];
    amountStaked[msg.sender][currentCycle()] = amountAfterFees;
    totalStaked[currentCycle()] += amountAfterFees;
    stakedDuringCycle[msg.sender][currentCycle()] = true;
    emit Staked(msg.sender, amountAfterFees);
  }

  function compoundAndStake(uint64[] memory userNodes, uint256 amount, bool isAdding) external {
    require(paused == false, "STAKE: Contract is paused.");
    require(blacklist[msg.sender] == false, "STAKE: You are blacklisted");
    uint256 amountAfterFees;
    uint256 feesAmount = amount.mul(stakeFee) / precision;
    if (stakers[msg.sender].amount == 0 || isAdding) {
      amountAfterFees = stakers[msg.sender].unstakeCycle == currentCycle() ? amount.sub(feesAmount) : amountStaked[msg.sender][currentCycle()].add(amount.sub(feesAmount));
      require(amount.sub(feesAmount).add(stakers[msg.sender].amount) >= minStake, "STAKE: Below min amount");
      require(amount.sub(feesAmount).add(stakers[msg.sender].amount) <= maxStake, "STAKE: Above max amount");
      uint256 availableRewards = MANSIONSMANAGER.getAddressRewards(msg.sender) * MANSIONSMANAGER.getUserMultiplier(msg.sender);
      require(availableRewards >= amount, "STAKE: Not enough to compound");

      MANSIONSHEPLER.claimUtility(userNodes, address(this), amount, address(TAXMANAGER), msg.sender);
      TAXMANAGER.execute(availableRewards - amount, msg.sender);

      // FEE TRANSFERS
      PLAYMATES.transfer(POOL, feesAmount.mul(stakeDistribution[0]) / precision);
      PLAYMATES.transfer(address(PLAYMATES), feesAmount.mul(stakeDistribution[1]) / precision);

    } else {
      require(amountStaked[msg.sender][currentCycle()] == 0, "STAKE: You already merged");
      amountAfterFees = stakers[msg.sender].amount;
    }
    stakers[msg.sender] = Stake({
      stakeCycle: currentCycle(),
      lastClaimCycle: stakers[msg.sender].lastClaimCycle == 0 ? currentCycle() : stakers[msg.sender].lastClaimCycle,
      unstakeCycle: 0,
      amount: amountAfterFees,
      totalRewards: stakers[msg.sender].totalRewards
    });
    if (isAdding) totalStaked[currentCycle()] -= amountStaked[msg.sender][currentCycle()];
    amountStaked[msg.sender][currentCycle()] = amountAfterFees;
    totalStaked[currentCycle()] += amountAfterFees;
    stakedDuringCycle[msg.sender][currentCycle()] = true;
    emit Staked(msg.sender, amountAfterFees);
  }

  function claimAll() public {
    require(paused == false, "CLAIM: Contract is paused.");
    require(blacklist[msg.sender] == false, "CLAIM: You are blacklisted");
    require(currentCycle() > stakers[msg.sender].lastClaimCycle, "CLAIM2: You have no share to claim.");
    require(stakers[msg.sender].lastClaimCycle >= stakers[msg.sender].stakeCycle, "CLAIM3: You have no share to claim.");
    require(stakers[msg.sender].amount > 0, "CLAIM: You are not contributing to the pool.");
    uint256 sum = 0;
    for(uint256 i = stakers[msg.sender].lastClaimCycle; i < currentCycle(); i++) {
      if (payoutClaimed[msg.sender][i] == false && stakedDuringCycle[msg.sender][i] == true) {
        uint256 share = getShareOf(msg.sender, i);
        sum += payouts[i].mul(share) / precision;
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
    require(paused == false, "CLAIM: Contract is paused.");
    require(blacklist[msg.sender] == false, "CLAIM: You are blacklisted");
    require(currentCycle() > stakers[msg.sender].lastClaimCycle, "CLAIM2: You have no share to claim.");
    require(stakers[msg.sender].lastClaimCycle >= stakers[msg.sender].stakeCycle, "CLAIM3: You have no share to claim.");
    require(stakers[msg.sender].amount > 0, "CLAIM: You are not contributing to the pool.");
    require(payoutClaimed[msg.sender][cycle] == false, "CLAIM4: Nothing to claim");
    require(stakedDuringCycle[msg.sender][cycle] == true, "CLAIM6: You unstaked");
    uint256 share = getShareOf(msg.sender, cycle);
    uint256 sum = payouts[cycle].mul(share) / precision;
    require(sum > 0, "CLAIM5: Nothing to claim");
    stakers[msg.sender].lastClaimCycle = cycle;
    stakers[msg.sender].totalRewards += sum;
    payoutClaimed[msg.sender][cycle] = true;
    PAYMENT_TOKEN.transfer(msg.sender, sum);
    emit Claimed(msg.sender, sum);
  }

  function unstake(bool bypassClaimAll) external {
    require(paused == false, "UNSTAKE: Contract is paused.");
    require(blacklist[msg.sender] == false, "UNSTAKE: You are blacklisted");
    require(stakers[msg.sender].amount > 0, "UNSTAKE: You have nothing to unstake.");

    if (bypassClaimAll == false) {
      if (getAllRewardsOf(msg.sender) > 0) {
        claimAll();
      }
    }
    
    uint256 feesRatio = getUnstakeFees(msg.sender);
    uint256 feesAmount = stakers[msg.sender].amount.mul(feesRatio) / precision;
    uint256 amountAfterFees = stakers[msg.sender].amount.sub(feesAmount);
    stakers[msg.sender].amount = 0;
    stakers[msg.sender].stakeCycle = 0;
    stakers[msg.sender].unstakeCycle = currentCycle();
    totalStaked[currentCycle()] -= amountStaked[msg.sender][currentCycle()];
    stakedDuringCycle[msg.sender][currentCycle()] = false;

    // FEE TRANSFERS
    PLAYMATES.transfer(POOL, feesAmount.mul(unstakeDistribution[0]) / precision);
    PLAYMATES.transfer(address(PLAYMATES), feesAmount.mul(unstakeDistribution[1]) / precision);
    PLAYMATES.transfer(TREASURY, feesAmount.mul(unstakeDistribution[2]) / precision);
    PLAYMATES.transfer(MARKETING, feesAmount.mul(unstakeDistribution[3]) / precision);

    PLAYMATES.transfer(msg.sender, amountAfterFees);
    emit Unstaked(msg.sender, amountAfterFees);
  }

  // ONLY OWNER FUNCTIONS

  function setPrecision(uint256 _precision) external onlyOwner {
    precision =  _precision;
  }

  function setPaused(bool _val) external onlyOwner {
    paused = _val;
  }

  function setPayout(uint256 cycle, uint256 amount) external onlyOwner {
    payouts[cycle] = amount;
  }

  function setBlacklisted(address user, bool _val) external onlyOwner {
    blacklist[user] = _val;
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