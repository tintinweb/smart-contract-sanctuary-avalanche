/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

/**
    A sample smart contract demostrating the use of Chainlink Proof-of-Reserves functionality.
 */
contract SampleDeFiContract {
    AggregatorV3Interface internal proofOfReserveContract;
    IERC20 internal btcbContract;

    mapping(address => uint256) private _poolBalances;
    event Deposit(address indexed from, uint256 value);
    event Withdrawal(address indexed to, uint256 value);

    constructor() {
        // BTC.b PoR address on Fuji testnet.
        // Full list of Chainlink feeds on Fuji available here: https://docs.chain.link/docs/data-feeds/price-feeds/addresses/?network=avalanche#Avalanche%20Testnet
        proofOfReserveContract = AggregatorV3Interface(0xa284e0aCB9a5F46CE7884D9929Fa573Ff842d7b3);

        // The BTC.b contract address on Fuji testnet.
        btcbContract = IERC20(0x0f2071079315Ba5a1c6d5b532a01a132c157AC83);
    }

    /**
        Returns the current BTC.b supply, and current BTC collateral amount, as reported by Chainlink PoR.
     */
    function getCollateralAmounts() public view returns (uint256, int256) {
        // Get the token supply from the ERC20 contract.
        uint256 totalSupply = btcbContract.totalSupply();

        // Get the collateral amount for the Chainlink PoR feed.
        (uint80 roundId, int256 collateralAmount, , , uint80 answeredInRound) = proofOfReserveContract.latestRoundData();
        require(roundId == answeredInRound, "Stale proof-of-reserves answer.");

        return (totalSupply, collateralAmount);
    }

    /**
        Returns true if and only if the BTC.b token supply is fully backed by native Bitcoin.
     */
    function isFullyCollateralized() public view returns (bool) {
        // Get the token supply and collateral amount, and check that the supply is not greater than the collateral.
        (uint256 totalSupply, int256 collateralAmount) = getCollateralAmounts();
        if (collateralAmount < 0) {
            return false;
        }

        return totalSupply <= uint256(collateralAmount);
    }

    /**
        Mocking functionality of depositing into a DeFi pool.
        Only allowed when bridged asset is fully backed.
        Emits a Deposit event in the success case.
     */
    function depositIntoPool(uint256 amount) public returns (bool) {
        // Check that the BTC.b asset is fully collateralized.
        require(isFullyCollateralized(), "Pools paused while asset under collateralized.");

        // Transfer the tokens into the control of this contract and account for the new balances.
        require(btcbContract.transferFrom(msg.sender, address(this), amount));
        _poolBalances[msg.sender] += amount;

        // Emit the deposit event.
        emit Deposit(msg.sender, amount);

        return true;
    }

    /**
        Mocking functionality of withdrawing from a DeFi pool.
        Only allowed when bridged asset is fully backed.
        Emits a Withdrawal event in the success case.
     */
    function withdrawFromPool(uint256 amount) public returns (bool) {
        // Check that the BTC.b asset is fully collateralized.
        require(isFullyCollateralized(), "Pools paused while asset under collateralized.");

        // Check the address has sufficient balance to withdraw.
        require(_poolBalances[msg.sender] >= amount, "Withdrawal amount exceeds balance.");

        // Deduct the amount from the address balance first (protect against reentrance), then transfer the amount to them.
        _poolBalances[msg.sender] -= amount;
        btcbContract.transfer(msg.sender, amount);

        // Emit the withdrawal event.
        emit Withdrawal(msg.sender, amount);

        return true;
    }
}