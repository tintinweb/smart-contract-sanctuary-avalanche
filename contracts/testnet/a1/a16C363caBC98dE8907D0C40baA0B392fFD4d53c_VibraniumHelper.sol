// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IVibranium {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalDepositedEther() external view returns (uint256);

    function safeCollateralRate() external view returns (uint256);

    function redemptionFee() external view returns (uint256);

    function keeperRate() external view returns (uint256);

    function depositedEther(address user) external view returns (uint256);

    function getBorrowedOf(address user) external view returns (uint256);

    function isRedemptionProvider(address user) external view returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferShares(
        address _recipient,
        uint256 _sharesAmount
    ) external returns (uint256);

    function getSharesByMintedVUSD(
        uint256 _VUSDAmount
    ) external view returns (uint256);

    function getMintedVUSDByShares(
        uint256 _sharesAmount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IVibranium.sol";
import "./IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IStakingRewards {
    function rewardRate() external view returns (uint256);
}

contract VibraniumHelper {
    IVibranium public immutable vibranium;
    address public lido;
    AggregatorV3Interface internal priceFeed;

    constructor(address _vibranium, address _lido, address _priceFeed) {
        vibranium = IVibranium(_vibranium);
        lido = _lido;
        priceFeed =
        AggregatorV3Interface(_priceFeed);

    }

    function getEtherPrice() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getCollateralRate(address user) public view returns (uint256) {
        if (vibranium.getBorrowedOf(user) == 0) return 1e22;
        return
            (vibranium.depositedEther(user) * getEtherPrice() * 1e12) /
            vibranium.getBorrowedOf(user);
    }

    function getExcessIncomeAmount()
        external
        view
        returns (uint256 vusdAmount)
    {
        if (
            IERC20(lido).balanceOf(address(vibranium)) < vibranium.totalDepositedEther()
        ) {
            vusdAmount = 0;
        } else {
            vusdAmount =
                ((IERC20(lido).balanceOf(address(vibranium)) -
                    vibranium.totalDepositedEther()) * getEtherPrice()) /
                1e8;
        }
    }

    function getOverallCollateralRate() public view returns (uint256) {
        return
            (vibranium.totalDepositedEther() * getEtherPrice() * 1e12) /
            vibranium.totalSupply();
    }

    function getLiquidateableAmount(address user)
        external
        view
        returns (uint256 etherAmount, uint256 vusdAmount)
    {
        if (getCollateralRate(user) > 150 * 1e18) return (0, 0);
        if (
            getCollateralRate(user) >= 125 * 1e18 ||
            getOverallCollateralRate() >= 150 * 1e18
        ) {
            etherAmount = vibranium.depositedEther(user) / 2;
            vusdAmount = (etherAmount * getEtherPrice()) / 1e8;
        } else {
            etherAmount = vibranium.depositedEther(user);
            vusdAmount = (etherAmount * getEtherPrice()) / 1e8;
            if (getCollateralRate(user) >= 1e20) {
                vusdAmount = (vusdAmount * 1e20) / getCollateralRate(user);
            }
        }
    }

    function getRedeemableAmount(address user) external view returns (uint256) {
        if (!vibranium.isRedemptionProvider(user)) return 0;
        return vibranium.getBorrowedOf(user);
    }

    function getRedeemableAmounts(address[] calldata users)
        external
        view
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            if (!vibranium.isRedemptionProvider(users[i])) amounts[i] = 0;
            amounts[i] = vibranium.getBorrowedOf(users[i]);
        }
    }

    function getLiquidateFund(address user)
        external
        view
        returns (uint256 vusdAmount)
    {
        uint256 appro = vibranium.allowance(user, address(vibranium));
        if (appro == 0) return 0;
        uint256 bal = vibranium.balanceOf(user);
        vusdAmount = appro > bal ? bal : appro;
    }

    function getWithdrawableAmount(address user)
        external
        view
        returns (uint256)
    {
        if (vibranium.getBorrowedOf(user) == 0) return vibranium.depositedEther(user);
        if (getCollateralRate(user) <= 160 * 1e18) return 0;
        return
            (vibranium.depositedEther(user) *
                (getCollateralRate(user) - 160 * 1e18)) /
            getCollateralRate(user);
    }

    function getVusdMintableAmount(address user)
        external
        view
        returns (uint256 vusdAmount)
    {
        if (getCollateralRate(user) <= 160 * 1e18) return 0;
        return
            (vibranium.depositedEther(user) * getEtherPrice()) /
            1e6 /
            160 -
            vibranium.getBorrowedOf(user);
    }

    function getStakingPoolAPR(
        address poolAddress,
        address vib,
        address lpToken
    ) external view returns (uint256 apr) {
        uint256 pool_lp_stake = IERC20(poolAddress).totalSupply();
        uint256 rewardRate = IStakingRewards(poolAddress).rewardRate();
        uint256 lp_vib_amount = IERC20(vib).balanceOf(lpToken);
        uint256 lp_total_supply = IERC20(lpToken).totalSupply();
        apr =
            (lp_total_supply * rewardRate * 86400 * 365 * 1e6) /
            (pool_lp_stake * lp_vib_amount * 2);
    }

    function getTokenPrice(address token, address UniPool, address wethAddress) external view returns (uint256 price) {
        uint256 token_in_pool = IERC20(token).balanceOf(UniPool);
        uint256 weth_in_pool = IERC20(wethAddress).balanceOf(UniPool);
        price = weth_in_pool * getEtherPrice() * 1e10 / token_in_pool;
    }
}