// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Token sale.
 * @author Mathieu Bour, Julien Schneider, Charly Mancel, Valentin Pollart and Clarisse Tarrou for the DeepSquare Association.
 * @notice Conduct a token sale in exchange for a stablecoin (STC), e.g. USDC.
 */
contract Sale is Ownable {
    /// @notice The DPS token contract being sold. It must have an owner() function in order to let the sale be closed.
    IERC20Metadata public immutable DPS;

    /// @notice The stablecoin ERC20 contract.
    IERC20Metadata public immutable STC;

    /// @notice The Chainlink AVAX/USD pair aggregator.
    AggregatorV3Interface public aggregator;

    /// @notice How many cents costs a DPS (e.g., 40 means a single DPS token costs 0.40 STC).
    uint8 public immutable rate;

    /// @notice The minimum DPS purchase amount in stablecoin.
    uint256 public immutable minimumPurchaseSTC;

    /// @notice How many DPS tokens were sold during the sale.
    uint256 public sold;

    bool public isPaused;

    /**
     * Token purchase event.
     * @param investor The investor address.
     * @param amountDPS Amount of DPS tokens purchased.
     */
    event Purchase(address indexed investor, uint256 amountDPS);

    /**
     * @param _DPS The DPS contract address.
     * @param _STC The ERC20 stablecoin contract address (e.g, USDT, USDC, etc.).
     * @param _aggregator The Chainlink AVAX/USD pair aggregator contract address.
     * @param _rate The DPS/STC rate in STC cents.
     * @param _initialSold How many DPS tokens were already sold.
     */
    constructor(
        IERC20Metadata _DPS,
        IERC20Metadata _STC,
        AggregatorV3Interface _aggregator,
        uint8 _rate,
        uint256 _minimumPurchaseSTC,
        uint256 _initialSold
    ) {
        require(address(_DPS) != address(0), "Sale: token is zero");
        require(address(_STC) != address(0), "Sale: stablecoin is zero");
        require(address(_aggregator) != address(0), "Sale: aggregator is zero");
        require(_rate > 0, "Sale: rate is not positive");

        DPS = _DPS;
        STC = _STC;
        aggregator = _aggregator;
        rate = _rate;
        minimumPurchaseSTC = _minimumPurchaseSTC;
        sold = _initialSold;
        isPaused = false;
    }

    /**
     * @notice Change the Chainlink AVAX/USD pair aggregator.
     * @param newAggregator The new aggregator contract address.
     */
    function setAggregator(AggregatorV3Interface newAggregator) external onlyOwner {
        aggregator = newAggregator;
    }

    /**
     * @notice Convert an AVAX amount to its equivalent of the stablecoin.
     * This allow to handle the AVAX purchase the same way as the stablecoin purchases.
     * @param amountAVAX The amount in AVAX wei.
     * @return The amount in STC.
     */
    function convertAVAXtoSTC(uint256 amountAVAX) public view returns (uint256) {
        (, int256 answer, , , ) = aggregator.latestRoundData();
        require(answer > 0, "Sale: answer cannot be negative");

        return (amountAVAX * uint256(answer) * 10**STC.decimals()) / 10**(18 + aggregator.decimals());
    }

    /**
     * @notice Convert a stablecoin amount in DPS.
     * @dev Maximum possible working value is 210M DPS * 1e18 * 1e6 = 210e30.
     * Since log2(210e30) ~= 107, this cannot overflow an uint256.
     * @param amountSTC The amount in stablecoin.
     * @return The amount in DPS.
     */
    function convertSTCtoDPS(uint256 amountSTC) public view returns (uint256) {
        return (amountSTC * (10**DPS.decimals()) * 100) / rate / (10**STC.decimals());
    }

    /**
     * @notice Convert a DPS amount in stablecoin.
     * @dev Maximum possible working value is 210M DPS * 1e18 * 1e6 = 210e30.
     * Since log2(210e30) ~= 107,this cannot overflow an uint256.
     * @param amountDPS The amount in DPS.
     * @return The amount in stablecoin.
     */
    function convertDPStoSTC(uint256 amountDPS) public view returns (uint256) {
        return (amountDPS * (10**STC.decimals()) * rate) / 100 / (10**DPS.decimals());
    }

    /**
     * @notice Get the remaining DPS tokens to sell.
     * @return The amount of DPS remaining in the sale.
     */
    function remaining() external view returns (uint256) {
        return DPS.balanceOf(address(this));
    }

    /**
     * @notice Get the raised stablecoin amount.
     * @return The amount of stablecoin raised in the sale.
     */
    function raised() external view returns (uint256) {
        return convertDPStoSTC(sold);
    }

    /**
     * @notice Validate that the account is allowed to buy DPS.
     * @dev Requirements:
     * - the account is not the sale owner.
     * - the account is eligible.
     * @param account The account to check that should receive the DPS.
     * @param amountSTC The amount of stablecoin that will be used to purchase DPS.
     * @return The amount of DPS that should be transferred.
     */
    function _validate(address account, uint256 amountSTC) internal returns (uint256) {
        require(account != owner(), "Sale: investor is the sale owner");

        uint256 amountDPS = convertSTCtoDPS(amountSTC);
        require(DPS.balanceOf(address(this)) >= amountDPS, "Sale: no enough tokens remaining");

        return amountDPS;
    }

    /**
     * @notice Deliver the DPS to the account.
     * @dev Requirements:
     * - there are enough DPS remaining in the sale.
     * @param account The account that will receive the DPS.
     * @param amountDPS The amount of DPS to transfer.
     */
    function _transferDPS(address account, uint256 amountDPS) internal {
        sold += amountDPS;
        DPS.transfer(account, amountDPS);

        emit Purchase(account, amountDPS);
    }

    /**
     * @notice Purchase DPS with AVAX native currency.
     * The invested amount will be msg.value.
     */
    function purchaseDPSWithAVAX() external payable {
        require(!isPaused, "Sale is paused");
        uint256 amountSTC = convertAVAXtoSTC(msg.value);

        require(amountSTC >= minimumPurchaseSTC, "Sale: amount lower than minimum");
        uint256 amountDPS = _validate(msg.sender, amountSTC);

        // Using .transfer() might cause an out-of-gas revert if using gnosis safe as owner
        (bool sent, ) = payable(owner()).call{ value: msg.value }(""); // solhint-disable-line avoid-low-level-calls
        require(sent, "Sale: failed to forward AVAX");
        _transferDPS(msg.sender, amountDPS);
    }

    /**
     * @notice Purchase DPS with stablecoin.
     * @param amountSTC The amount of stablecoin to invest.
     */
    function purchaseDPSWithSTC(uint256 amountSTC) external {
        require(!isPaused, "Sale is paused");
        require(amountSTC >= minimumPurchaseSTC, "Sale: amount lower than minimum");
        uint256 amountDPS = _validate(msg.sender, amountSTC);

        STC.transferFrom(msg.sender, owner(), amountSTC);
        _transferDPS(msg.sender, amountDPS);
    }

    /**
     * @notice Deliver DPS tokens to an investor. Restricted to the sale OWNER.
     * @param amountSTC The amount of stablecoins invested, no minimum amount.
     * @param account The investor address.
     */
    function deliverDPS(uint256 amountSTC, address account) external onlyOwner {
        uint256 amountDPS = _validate(account, amountSTC);
        _transferDPS(account, amountDPS);
    }

    /**
     * @notice Pause the sale so that only the owner can deliverDps.
     */
    function setPause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
     * @notice Close the sale by sending the remaining tokens back to the owner and then renouncing ownership.
     */
    function close() external onlyOwner {
        DPS.transfer(owner(), DPS.balanceOf(address(this))); // Transfer all the DPS back to the owner
        renounceOwnership();
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}