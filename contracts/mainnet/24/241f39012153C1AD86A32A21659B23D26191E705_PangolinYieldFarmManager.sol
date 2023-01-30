// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/vaults/pangolin/IPangolinYieldFarmVault.sol";
import "../../interfaces/swaps/pangolin/IPangolinPair.sol";
import "../../interfaces/swaps/pangolin/IPangolinRouter02.sol";
import "../../interfaces/oracles/IPangolinOracle.sol";
import "../../interfaces/lending/ILendingPool.sol";
import "../../interfaces/staking/pangolin/IMinichefV2.sol";
import "../../interfaces/tokens/IWAVAX.sol";
import "../../utils/OptimalDeposit.sol";
import "../../enum/ManagerAction.sol";
import "../../enum/VaultStrategy.sol";

contract PangolinYieldFarmManager is Ownable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  // Vault contract
  address public vault;
  // LP staking reward token contract
  address public rewardToken;
  // Token A lending pool contract
  address public tokenALendingPool;
  // Token B lending pool contract
  address public tokenBLendingPool;
  // Router contract
  address public router;
  // Staking pool contract
  address public stakePool;
  // Stake pool ID
  uint256 public stakePoolId;
  // joeOracle contract
  address public joeOracle;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _vault Vault contract
    * @param _rewardToken LP staking reward token contract
    * @param _tokenALendingPool Token A lending pool contract
    * @param _tokenBLendingPool Token B lending pool contract
    * @param _router Router contract
    * @param _stakePool Stake pool contract
    * @param _stakePoolId Stake pool ID
    * @param _joeOracle joeOracle contract
  */
  constructor(
    address _vault,
    address _rewardToken,
    address _tokenALendingPool,
    address _tokenBLendingPool,
    address _router,
    address _stakePool,
    uint256 _stakePoolId,
    address _joeOracle
  ) {
    vault = _vault;
    rewardToken = _rewardToken;
    tokenALendingPool = _tokenALendingPool;
    tokenBLendingPool = _tokenBLendingPool;
    router = _router;
    stakePool = _stakePool;
    stakePoolId = _stakePoolId;
    joeOracle = _joeOracle;
  }

  /* ========== MODIFIERS ========== */

  /**
    * Only allow approved address of vault
  */
  modifier onlyVault() {
    require(msg.sender == vault, "Caller is not approved vault");
    _;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Token A of Vault
    * @return address tokenA address
  */
  function tokenA() public view returns (address) {
    return IPangolinYieldFarmVault(vault).tokenA();
  }

  /**
    * Token B of Vault
    * @return address tokenB address
  */
  function tokenB() public view returns (address) {
    return IPangolinYieldFarmVault(vault).tokenB();
  }

  /**
    * Return the contract address of the lpToken
    * @return address lpToken address
  */
  function lpToken() public view returns (address) {
    return IPangolinOracle(joeOracle).lpToken(tokenA(), tokenB());
  }

  /**
    * Return the lp token amount held by manager
    * @return lpTokenAmt lpToken amount
  */
  function lpTokenAmt() public view returns (uint256) {
    (uint256 amt, ) = IMinichefV2(stakePool).userInfo(stakePoolId, address(this));

    return IPangolinPair(lpToken()).balanceOf(address(this)) + amt;
  }

  /**
    * Get token A and B asset amt. Asset = Debt + Equity
    * @return tokenAAssetAmt tokenAAssetAmt
    * @return tokenBAssetAmt tokenBAssetAmt
  */
  function assetInfo() public view returns (uint256, uint256) {
    (uint256 tokenAAssetAmt, uint256 tokenBAssetAmt) = IPangolinOracle(joeOracle).getLpTokenReserves(
      lpTokenAmt(),
      tokenA(),
      tokenB(),
      lpToken()
    );

    return (tokenAAssetAmt, tokenBAssetAmt);
  }

  /**
    * Get token A and B debt amt from lending pools
    * @return tokenADebtAmt tokenADebtAmt
    * @return tokenBDebtAmt tokenBDebtAmt
  */
  function debtInfo() public view returns (uint256, uint256) {
      return (ILendingPool(tokenALendingPool).maxRepay(address(this)), ILendingPool(tokenBLendingPool).maxRepay(address(this)));
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * General function for deposit, withdraw, rebalance, called by vault
    * @param _action Enum, 0 - Deposit, 1 - Withdraw, 2 - AddLiquidity, 3 - RemoveLiquidity
    * @param _lpAmt Amt of LP tokens to sell for repay
    * @param _borrowTokenAAmt Amt of tokens to borrow
    * @param _borrowTokenBAmt Amt of tokens to borrow
    * @param _repayTokenAAmt Amt of tokens to repay
    * @param _repayTokenBAmt Amt of tokens to repay
  */
  function work(
    ManagerAction _action,
    uint256 _lpAmt,
    uint256 _borrowTokenAAmt,
    uint256 _borrowTokenBAmt,
    uint256 _repayTokenAAmt,
    uint256 _repayTokenBAmt
  ) external onlyVault {

    // ********** Deposit Flow **********
    if (_action == ManagerAction.Deposit) {
      // borrow from lending pools
      _borrow(_borrowTokenAAmt,_borrowTokenBAmt);
      // Add tokens to Lp receive Lp tokens
      _addLiquidity();
      // Stake Lp in rewards pool
      _stake();
    }

    // ********** Withdraw Flow **********
    if (_action == ManagerAction.Withdraw) {
      if (_lpAmt > 0) {
        // If estimated LP amount is more than actual LP amount owned
        if (_lpAmt > lpTokenAmt()) {
          _lpAmt = lpTokenAmt();
        }

        // Unstake LP from rewards pool
        _unstake(_lpAmt);
        // remove Lp receive tokenA + B
        _removeLiquidity(_lpAmt);
        // Swap tokens to ensure sufficient balance to repay
        _swapForRepay(_repayTokenAAmt, _repayTokenBAmt);
        // repay lending pools
        _repay(_repayTokenAAmt, _repayTokenBAmt);
        // swap excess tokens
        _swapExcess();
      }
    }

    // ********** Rebalance: Add Liquidity Flow **********
    if (_action == ManagerAction.AddLiquidity) {
      // Borrow from lending pools
      _borrow(_borrowTokenAAmt, _borrowTokenBAmt);
      if (_repayTokenAAmt > (SAFE_MULTIPLIER / 100) || _repayTokenBAmt > (SAFE_MULTIPLIER / 100)) {
        // If required Swap tokens to ensure sufficient balance to repay
         _swapForRepay(_repayTokenAAmt, _repayTokenBAmt);
        // If required, repay lending pools
        _repay(_repayTokenAAmt, _repayTokenBAmt);
      }
      // Add tokens to Lp receive Lp tokens
      _addLiquidity();
      // Stake Lp in rewards pool
      _stake();
    }

    // ********** Rebalance: Remove Liquidity Flow **********
    if (_action == ManagerAction.RemoveLiquidity) {
      if (_lpAmt > 0) {
        // If estimated LP amount is more than actual LP amount owned
        if (_lpAmt > lpTokenAmt()) {
          _lpAmt = lpTokenAmt();
        }
        // Unstake LP from rewards pool
        _unstake(_lpAmt);
        // remove Lp receive tokenA + B
        _removeLiquidity(_lpAmt);
        // If required, borrow from lending pools
        _borrow(_borrowTokenAAmt, _borrowTokenBAmt);
        if (_repayTokenAAmt > (SAFE_MULTIPLIER / 100) || _repayTokenBAmt > (SAFE_MULTIPLIER / 100)) {
          // If required Swap tokens to ensure sufficient balance to repay
          _swapForRepay(_repayTokenAAmt, _repayTokenBAmt);
          // If required, repay lending pools
          _repay(_repayTokenAAmt, _repayTokenBAmt);
        }
      }
    }

    // Send tokens back to vault, also account for any dust cleanup
    IERC20(tokenA()).safeTransfer(msg.sender, IERC20(tokenA()).balanceOf(address(this)));
    IERC20(tokenB()).safeTransfer(msg.sender, IERC20(tokenB()).balanceOf(address(this)));
  }

  /**
    * Compound rewards, convert to more LP; called by vault or keeper
  */
  function compound() external {
    // Depositing 0 to pool id will trigger a harvest
    IMinichefV2(stakePool).deposit(stakePoolId, 0, address(this));

    if (IERC20(rewardToken).balanceOf(address(this)) > 0) {
      _swapRewardWithFee();
      _addLiquidity();
      _stake();
    }
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * Internal function to optimally convert token balances to LP tokens
  */
  function _addLiquidity() internal {
    (uint256 reserveA, uint256 reserveB) = IPangolinOracle(joeOracle).getLpTokenReserves(
      IPangolinPair(lpToken()).totalSupply(),
      tokenA(),
      tokenB(),
      lpToken()
    );

    // Calculate optimal deposit for token0
    (uint256 optimalSwapAmount, bool isReversed) = OptimalDeposit.optimalDeposit(
      IERC20(tokenA()).balanceOf(address(this)),
      IERC20(tokenB()).balanceOf(address(this)),
      reserveA,
      reserveB,
      3 // fee of 0.3%
    );

    address[] memory swapPathForOptimalDeposit = new address[](2);

    if (isReversed) {
      swapPathForOptimalDeposit[0] = tokenB();
      swapPathForOptimalDeposit[1] = tokenA();
    } else {
      swapPathForOptimalDeposit[0] = tokenA();
      swapPathForOptimalDeposit[1] = tokenB();
    }

    // Swap tokens to achieve optimal deposit amount
    if (optimalSwapAmount > 0) {
      IERC20(swapPathForOptimalDeposit[0]).approve(router, optimalSwapAmount);
      IPangolinRouter02(router).swapExactTokensForTokens(
        optimalSwapAmount,
        0,
        swapPathForOptimalDeposit,
        address(this),
        block.timestamp
      );
    }

    // Add liquidity
    IERC20(tokenA()).approve(router, IERC20(tokenA()).balanceOf(address(this)));
    IERC20(tokenB()).approve(router, IERC20(tokenB()).balanceOf(address(this)));

    IPangolinRouter02(router).addLiquidity(
      tokenA(),
      tokenB(),
      IERC20(tokenA()).balanceOf(address(this)),
      IERC20(tokenB()).balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  /**
    * Internal function to withdraw LP tokens
    * @param _lpAmt   amt of lp tokens to withdraw
  */
  function _removeLiquidity(uint256 _lpAmt) internal {
    IPangolinPair(lpToken()).approve(router, _lpAmt);
    IPangolinRouter02(router).removeLiquidity(
      tokenA(),
      tokenB(),
      _lpAmt,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  /**
    * Internal function to stake LP tokens in masterchef
  */
  function _stake() internal {
    // Stake LP to rewards pool
    IERC20(lpToken()).approve(stakePool, IERC20(lpToken()).balanceOf(address(this)));
    IMinichefV2(stakePool).deposit(
      stakePoolId,
      IERC20(lpToken()).balanceOf(address(this)),
      address(this)
    );
  }

  /**
    * Internal function to unstake LP tokens from masterchef
    * @param _lpAmt   amt of lp tokens to unstake
  */
  function _unstake(uint256 _lpAmt) internal {
    IMinichefV2(stakePool).withdraw(stakePoolId, _lpAmt, address(this));
  }

  /**
    * Internal function to swap tokens A/B to ensure sufficient amount for repaying lending pools
    * @param _repayTokenAAmt    amt of token A to repay
    * @param _repayTokenBAmt    amt of token B to repay
  */
  function _swapForRepay(uint256 _repayTokenAAmt, uint256 _repayTokenBAmt) internal {
    uint256 swapAmountIn;
    uint256 swapAmountOut;
    address[] memory swapPathForRepayDifference = new address[](2);

    if (_repayTokenAAmt > IERC20(tokenA()).balanceOf(address(this))) {
      // if insufficient tokenA, swap B for A
      swapPathForRepayDifference[0] = tokenB();
      swapPathForRepayDifference[1] = tokenA();
      swapAmountOut = _repayTokenAAmt - IERC20(tokenA()).balanceOf(address(this));
    } else if (_repayTokenBAmt > IERC20(tokenB()).balanceOf(address(this))) {
      // if insufficient tokenB, swap A for B
      swapPathForRepayDifference[0] = tokenA();
      swapPathForRepayDifference[1] = tokenB();
      swapAmountOut = _repayTokenBAmt - IERC20(tokenB()).balanceOf(address(this));
    }

    swapAmountIn = IPangolinOracle(joeOracle).getAmountsIn(
      swapAmountOut,
      swapPathForRepayDifference[0],
      swapPathForRepayDifference[1],
      lpToken()
    );

    if (swapAmountIn > 0) {
      IERC20(swapPathForRepayDifference[0]).approve(router, swapAmountIn);

      IPangolinRouter02(router).swapExactTokensForTokens(
        swapAmountIn,
        0,
        swapPathForRepayDifference,
        address(this),
        block.timestamp
      );
    }
  }

  /**
    * Internal function to swap excess tokens according to vault strategy. Neutral vault - swap A -> B, Long vault - swap B -> A
  */
  function _swapExcess() internal {
    address[] memory swapPathForRepayDifference = new address[](2);

    if (IPangolinYieldFarmVault(vault).strategy() == VaultStrategy.Neutral) {
      if (IERC20(tokenA()).balanceOf(address(this)) > (SAFE_MULTIPLIER / 10)) {
        IERC20(tokenA()).approve(router, IERC20(tokenA()).balanceOf(address(this)));

        swapPathForRepayDifference[0] = tokenA();
        swapPathForRepayDifference[1] = tokenB();

        IPangolinRouter02(router).swapExactTokensForTokens(
          IERC20(tokenA()).balanceOf(address(this)),
          0,
          swapPathForRepayDifference,
          address(this),
          block.timestamp
        );
      }
    }

    if (IPangolinYieldFarmVault(vault).strategy() == VaultStrategy.Long) {
      if (IERC20(tokenB()).balanceOf(address(this)) > 0) {
        IERC20(tokenB()).approve(router, IERC20(tokenB()).balanceOf(address(this)));

        swapPathForRepayDifference[0] = tokenB();
        swapPathForRepayDifference[1] = tokenA();

        IPangolinRouter02(router).swapExactTokensForTokens(
          IERC20(tokenB()).balanceOf(address(this)),
          0,
          swapPathForRepayDifference,
          address(this),
          block.timestamp
        );
      }
    }
  }

  /**
    * Internal function to swap reward token for Token B; take cut of fees and transfer to treasury
  */
  function _swapRewardWithFee() internal {
    address[] memory swapRewardTokenToBPath = new address[](2);
    swapRewardTokenToBPath[0] = rewardToken;
    swapRewardTokenToBPath[1] = tokenB();

    // Assume tokenB is USDC, swap reward token to USDC
    IERC20(rewardToken).approve(router, IERC20(rewardToken).balanceOf(address(this)));
    IPangolinRouter02(router).swapExactTokensForTokens(
      IERC20(rewardToken).balanceOf(address(this)),
      0,
      swapRewardTokenToBPath,
      address(this),
      block.timestamp
    );

    uint256 fee = IERC20(tokenB()).balanceOf(address(this))
                  * IPangolinYieldFarmVault(vault).perfFee()
                  / SAFE_MULTIPLIER;

    IERC20(tokenB()).safeTransfer(IPangolinYieldFarmVault(vault).treasury(), fee);
  }

  /**
    * Internal function to borrow from lending pools
    * @param _borrowTokenAAmt   Amt of token A to borrow
    * @param _borrowTokenBAmt   Amt of token B to borrow
  */
  function _borrow(uint256 _borrowTokenAAmt, uint256 _borrowTokenBAmt) internal {
    if(_borrowTokenAAmt > 0) {
        ILendingPool(tokenALendingPool).borrow(_borrowTokenAAmt);
      }
    if(_borrowTokenBAmt > 0) {
      ILendingPool(tokenBLendingPool).borrow(_borrowTokenBAmt);
    }
  }

  /**
    * Internal function to repay lending pools
    * @param _repayTokenAAmt   Amt of token A to repay
    * @param _repayTokenBAmt   Amt of token B to repay
  */
  function _repay(uint256 _repayTokenAAmt, uint256 _repayTokenBAmt) internal {
    if(_repayTokenAAmt > 0) {
      IERC20(tokenA()).approve(tokenALendingPool, _repayTokenAAmt);
      ILendingPool(tokenALendingPool).repay(_repayTokenAAmt);
    }
    if(_repayTokenBAmt > 0) {
      IERC20(tokenB()).approve(tokenBLendingPool, _repayTokenBAmt);
      ILendingPool(tokenBLendingPool).repay(_repayTokenBAmt);
    }
  }

  /**
    * Internal function to repay manager's balanceOf to lending pools
  */
  function _repayBalanceOf() internal {
    IERC20(tokenA()).approve(tokenALendingPool, IERC20(tokenA()).balanceOf(address(this)));
    ILendingPool(tokenALendingPool).repay(IERC20(tokenA()).balanceOf(address(this)));

    IERC20(tokenB()).approve(tokenBLendingPool, IERC20(tokenB()).balanceOf(address(this)));
    ILendingPool(tokenBLendingPool).repay(IERC20(tokenB()).balanceOf(address(this)));
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
    * Change router to swap assets against
  */
  function updateRouter(address _router) external onlyOwner {
    router = _router;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/Math.sol";

library OptimalDeposit {
  function optimalDeposit(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 _fee
  ) internal pure returns (uint256, bool) {
    uint256 swapAmt;
    bool isReversed;

    if (_amountA * _reserveB >= _amountB * _reserveA) {
      swapAmt = _optimalDeposit(_amountA, _amountB, _reserveA, _reserveB, _fee);
      isReversed = false;
    } else {
      swapAmt = _optimalDeposit(_amountB, _amountA, _reserveB, _reserveA, _fee);
      isReversed = true;
    }

    return (swapAmt, isReversed);
  }

  function _optimalDeposit(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 _fee
  ) internal pure returns (uint256) {
      require(_amountA * _reserveB >= _amountB * _reserveA, "Reversed");

      uint256 a = 1000 - _fee;
      uint256 b = (2000 - _fee) * _reserveA;
      uint256 _c = (_amountA * _reserveB) - (_amountB * _reserveA);
      uint256 c = _c * 1000 / (_amountB + _reserveB) * _reserveA;
      uint256 d = a * c * 4;
      uint256 e = Math.sqrt(b * b + d);
      uint256 numerator = e - b;
      uint256 denominator = a * 2;

      return numerator / denominator;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum ManagerAction {
  Deposit,
  Withdraw,
  AddLiquidity,
  RemoveLiquidity
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPangolinOracle {
  function lpToken(
    address _token0,
    address _token1
  ) external view returns (address);

  function getAmountsOut(
    uint256 _amountIn,
    address _token0,
    address _token1,
    address _pair
  ) external view returns (uint256);

  function getAmountsIn(
    uint256 _amountOut,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);

  function getLpTokenReserves(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);

  function getLpTokenAmount(
    uint256 _value,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILendingPool {
  function totalValue() external view returns (uint256);
  function totalAvailableSupply() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function exchangeRate() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address _address) external view returns (uint256);
  function deposit(uint256 _assetAmount) external;
  function withdraw(uint256 _ibTokenAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
  function withdrawReserve(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum VaultStrategy {
  Neutral,
  Long,
  Short
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWAVAX {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPangolinPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IPangolinRouter01.sol";

interface IPangolinRouter02 is IPangolinRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../../enum/VaultStrategy.sol";

interface IPangolinYieldFarmVault {
  function strategy() external view returns (VaultStrategy);
  function tokenA() external view returns (address);
  function tokenB() external view returns (address);
  function treasury() external view returns (address);
  function perfFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMinichefV2 {
  function poolInfo(uint256 _id) external view returns (address, uint96, uint256, uint256, uint64, address, uint32, uint256, uint256);
  function pendingTokens(uint256 _id, address _user) external view returns (uint256, address, string memory, uint256);
  function userInfo(uint256 _id, address _user) external view returns (uint256, uint256);
  function deposit(uint256 _id, uint256 _amount, address _to) external;
  function withdraw(uint256 _id, uint256 _amount, address _to) external;
  function joePerSec() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPangolinRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
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
     * IMPORTANT: because control is transferred to `recipient`, care must be
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/enum/ManagerAction.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/enum/VaultStrategy.sol";

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/interfaces/lending/ILendingPool.sol";

abstract contract $ILendingPool is ILendingPool {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/interfaces/oracles/IPangolinOracle.sol";

abstract contract $IPangolinOracle is IPangolinOracle {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/staking/pangolin/IMinichefV2.sol";

abstract contract $IMinichefV2 is IMinichefV2 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/swaps/pangolin/IPangolinPair.sol";

abstract contract $IPangolinPair is IPangolinPair {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/swaps/pangolin/IPangolinRouter01.sol";

abstract contract $IPangolinRouter01 is IPangolinRouter01 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/swaps/pangolin/IPangolinRouter02.sol";

abstract contract $IPangolinRouter02 is IPangolinRouter02 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/interfaces/tokens/IWAVAX.sol";

abstract contract $IWAVAX is IWAVAX {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../../contracts/interfaces/vaults/pangolin/IPangolinYieldFarmVault.sol";

abstract contract $IPangolinYieldFarmVault is IPangolinYieldFarmVault {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/utils/OptimalDeposit.sol";

contract $OptimalDeposit {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $optimalDeposit(uint256 _amountA,uint256 _amountB,uint256 _reserveA,uint256 _reserveB,uint256 _fee) external pure returns (uint256 ret0, bool ret1) {
        (ret0, ret1) = OptimalDeposit.optimalDeposit(_amountA,_amountB,_reserveA,_reserveB,_fee);
    }

    function $_optimalDeposit(uint256 _amountA,uint256 _amountB,uint256 _reserveA,uint256 _reserveB,uint256 _fee) external pure returns (uint256 ret0) {
        (ret0) = OptimalDeposit._optimalDeposit(_amountA,_amountB,_reserveA,_reserveB,_fee);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../../contracts/vaults/pangolin/PangolinYieldFarmManager.sol";

contract $PangolinYieldFarmManager is PangolinYieldFarmManager {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _vault, address _rewardToken, address _tokenALendingPool, address _tokenBLendingPool, address _router, address _stakePool, uint256 _stakePoolId, address _joeOracle) PangolinYieldFarmManager(_vault, _rewardToken, _tokenALendingPool, _tokenBLendingPool, _router, _stakePool, _stakePoolId, _joeOracle) {}

    function $_addLiquidity() external {
        super._addLiquidity();
    }

    function $_removeLiquidity(uint256 _lpAmt) external {
        super._removeLiquidity(_lpAmt);
    }

    function $_stake() external {
        super._stake();
    }

    function $_unstake(uint256 _lpAmt) external {
        super._unstake(_lpAmt);
    }

    function $_swapForRepay(uint256 _repayTokenAAmt,uint256 _repayTokenBAmt) external {
        super._swapForRepay(_repayTokenAAmt,_repayTokenBAmt);
    }

    function $_swapExcess() external {
        super._swapExcess();
    }

    function $_swapRewardWithFee() external {
        super._swapRewardWithFee();
    }

    function $_borrow(uint256 _borrowTokenAAmt,uint256 _borrowTokenBAmt) external {
        super._borrow(_borrowTokenAAmt,_borrowTokenBAmt);
    }

    function $_repay(uint256 _repayTokenAAmt,uint256 _repayTokenBAmt) external {
        super._repay(_repayTokenAAmt,_repayTokenBAmt);
    }

    function $_repayBalanceOf() external {
        super._repayBalanceOf();
    }

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}