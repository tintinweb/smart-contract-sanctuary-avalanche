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

abstract contract Manageable is Ownable {
  mapping(address => bool) private _managers;

  event ManagerRemoved(address indexed manager_);
  event ManagerAdded(address indexed manager_);

  constructor() {}

  function managers(address manager_) public view virtual returns (bool) {
    return _managers[manager_];
  }

  modifier onlyManager() {
    require(_managers[_msgSender()], "Manageable: caller is not the owner");
    _;
  }

  function removeManager(address manager_) public virtual onlyOwner {
    _managers[manager_] = false;
    emit ManagerRemoved(manager_);
  }

  function addManager(address manager_) public virtual onlyOwner {
    require(manager_ != address(0), "Manageable: new owner is the zero address");
    _managers[manager_] = true;
    emit ManagerAdded(manager_);
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

interface IRouter01 {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IMansionsHelper {
  function getClaimFee(address sender) external view returns (uint256);
  function newTax() external view returns (uint256);
}

contract TaxManager is Ownable, Manageable {
  struct ClaimRatios {
      uint16 poolClaimFee;
      uint16 marketingFee;
      uint16 total;
  }

  ClaimRatios public _claimRatios = ClaimRatios({
      poolClaimFee: 80,
      marketingFee: 20,
      total: 100
  });

  struct NewTaxRatios {
      uint16 rewards;
      uint16 liquidity;
      uint16 marketing;
      uint16 treasury;
      uint16 total;
  }

  NewTaxRatios public _newTaxRatios = NewTaxRatios({
      rewards: 50,
      liquidity: 30,
      marketing: 10,
      treasury: 10,
      total: 100
  });

  IMansionsHelper public MANSIONSHEPLER;
  IERC20 public PLAYMATES;
  address public POOL;
  address public TREASURY;
  address public MARKETING;
  address public ROUTER;
  IRouter02 public dexRouter;

  uint256 public baseFee = 15;
  uint256 public newTax = 0;

  uint256 public claimLiquidityAmount = 0;
  uint256 public claimLiquidityThreshold = 10;

  constructor(address _MANSIONSHEPLER, address _PLAYMATES, address _POOL, address _TREASURY, address _MARKETING, address _ROUTER) {
    MANSIONSHEPLER = IMansionsHelper(_MANSIONSHEPLER);
    PLAYMATES = IERC20(_PLAYMATES);
    POOL = _POOL;
    TREASURY = _TREASURY;
    MARKETING = _MARKETING;
    ROUTER = _ROUTER;
    dexRouter = IRouter02(ROUTER);
    PLAYMATES.approve(ROUTER, type(uint256).max);
  }

  function claimContractSwap(uint256 numTokensToSwap) internal {
    address[] memory path = new address[](2);
    path[0] = address(PLAYMATES);
    path[1] = dexRouter.WAVAX();

    dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
      numTokensToSwap / 2,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 amountAVAX = address(this).balance;

    dexRouter.addLiquidityAVAX{value: amountAVAX}(
      address(PLAYMATES),
      numTokensToSwap / 2,
      0,
      0,
      MARKETING,
      block.timestamp
    );
    claimLiquidityAmount = 0;
  }

  function execute(uint256 remainingRewards, address receiver) external onlyManager {
    uint256 feeAmount = remainingRewards * MANSIONSHEPLER.getClaimFee(receiver)  / 100;
    uint256 newFeeAmount = remainingRewards * MANSIONSHEPLER.newTax() / 100;
    uint256 excessRewards = remainingRewards - feeAmount - newFeeAmount;

    uint256 amountToMarketingWallet = (feeAmount * _claimRatios.marketingFee) / (_claimRatios.total) + (newFeeAmount * _newTaxRatios.marketing) / _newTaxRatios.total;
    address[] memory path = new address[](2);
    path[0] = address(PLAYMATES);
    path[1] = dexRouter.WAVAX();
    dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        amountToMarketingWallet,
        0,
        path,
        MARKETING,
        block.timestamp
    );

    if (newTax > 0) {
      uint256 amountToTreasury = (newFeeAmount * _newTaxRatios.treasury) / _newTaxRatios.total;
      dexRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
          amountToTreasury,
          0,
          path,
          TREASURY,
          block.timestamp
      );

      uint256 amountToLiquidity = (newFeeAmount * _newTaxRatios.liquidity) / _newTaxRatios.total;
      claimLiquidityAmount += amountToLiquidity;
      if (claimLiquidityAmount >= claimLiquidityThreshold) {
        claimContractSwap(claimLiquidityAmount);
      }
    }

    PLAYMATES.transfer(msg.sender, excessRewards);
  }

  // ONLY OWNER FUNCTIONS

  function setMansionsHelper(address _MANSIONSHEPLER) external onlyOwner {
    MANSIONSHEPLER = IMansionsHelper(_MANSIONSHEPLER);
  }

  function setPlaymates(address _PLAYMATES) external onlyOwner {
    PLAYMATES = IERC20(_PLAYMATES);
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

  function setRouter(address _ROUTER) external onlyOwner {
    ROUTER = _ROUTER;
    dexRouter = IRouter02(ROUTER);
  }

  function updateBaseFee(uint256 _baseFee) external onlyOwner {
    baseFee = _baseFee;
  }

  function updateNewTax(uint256 _newTax) external onlyOwner {
    newTax = _newTax;
  }

  function setClaimRatios(uint16 _poolClaimFee, uint16 _marketingFee) external onlyOwner {
    _claimRatios.poolClaimFee = _poolClaimFee;
    _claimRatios.marketingFee = _marketingFee;
    _claimRatios.total = _poolClaimFee + _marketingFee;
  }

  function setNewTaxRatios(uint16 _rewardsFee, uint16 _marketingFee, uint16 _liquidityFee, uint16 _treasuryFee) external onlyOwner {
    _newTaxRatios.rewards = _rewardsFee;
    _newTaxRatios.marketing = _marketingFee;
    _newTaxRatios.liquidity = _liquidityFee;
    _newTaxRatios.treasury = _treasuryFee;
    _newTaxRatios.total = _rewardsFee + _marketingFee + _liquidityFee + _treasuryFee;
  }

  function setClaimLiquidityThreshold(uint256 _amount) external onlyOwner {
    claimLiquidityThreshold = _amount;
  }

  function withdrawPlaymates() external onlyOwner {
    PLAYMATES.transfer(msg.sender, PLAYMATES.balanceOf(address(this)));
  }
}