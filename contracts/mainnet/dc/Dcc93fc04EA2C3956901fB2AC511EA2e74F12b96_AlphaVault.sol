// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/gmx/IGMXRouter.sol";
import "./interface/gmx/IGMXPositionRouter.sol";
import "./interface/gmx/IGMXVault.sol";
import "./interface/stargate/IStargateRouter.sol";
import "./interface/stargate/IStargateLpStaking.sol";
import "./interface/stargate/IStargatePool.sol";
import "./interface/traderjoe/IJoeRouter02.sol";

/// @title AlphaVault
/// @author HedgeFarm
/// @notice A vault with simple epoch gestion for the alpha strategies of HedgeFarm.
contract AlphaVault is ERC20, Ownable {

    /// @notice The token that can be deposited or withdrawn.
    address public token;
    /// @notice The trading manager will get 20% of the funds for longing/shorting assets.
    address public tradingManager;
    // @notice The swap router of TraderJoe
    address public swapRouter = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    /// @notice Boolean to indicate if the strategy is running and has allocated funds in a lending protocol.
    bool public isEpochRunning;
    /// @notice The maximum total balance cap for the strategy.
    uint256 public cap;

    /// @notice When funds are allocated, stores the last relevant price per IOU.
    uint256 public lastPricePerShare;
    /// @notice When funds are allocated, stores the last relevant total balance.
    uint256 public lastTotalBalance;

    /// @notice Percentage of funds moved to Farm
    uint256 public constant SHARE_FOR_FARM = 80;
    /// @notice Percentage
    uint256 public constant PERCENT = 100;

    /// @notice Stargate lending addresses.
    IStargateLpStaking public stargateLpStaking;
    IStargateRouter public stargateRouter = IStargateRouter(0x45A01E4e04F14f7A4a6702c74187c5F6222033cd);
    address public stargateLpToken;
    address public stgToken = address(0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590);
    uint8 public stargateRouterPoolId;
    uint8 public stargateLpStakingPoolId;

    /// @notice GMX's vault.
    address gmxVault = address(0x9ab2De34A33fB459b538c43f251eB825645e8595);
    /// @notice The router of GMX to approve plugins.
    address gmxRouter = address(0x5F719c2F1095F7B9fc68a68e35B51194f4b6abe8);
    /// @notice The router of GMX to interact with positions.
    address gmxPositionRouter = address(0x195256074192170d1530527abC9943759c7167d8);
    /// @notice Chainlink oracle address for {token}/USD
    mapping(address => address) oracles;
    /// @notice Count of long/short positions currently opened.
    uint256 currentOpenPositions = 0;

    /// @notice This event is triggered when a deposit is completed.
    /// @param from The address depositing funds.
    /// @param amount The amount in {token} deposited.
    event Deposit(address indexed from, uint256 amount);

    /// @notice This event is triggered when a withdraw is completed.
    /// @param to The address withdrawing funds.
    /// @param amount The amount in {token} withdrawn.
    event Withdraw(address indexed to, uint256 amount);

    /// @notice This event is triggered when we start an epoch.
    /// @param totalAmount The amount to be allocated in lending and trading.
    event Start(uint256 totalAmount);

    /// @notice This event is triggered when we stop an epoch.
    /// @param totalAmount The amount from the lending, trading and rewards.
    event Stop(uint256 totalAmount);

    /// @notice Creates a new vault with a {token} that can be lent in Stargate.
    /// @param _name The name of the vault token.
    /// @param _symbol The symbol of the vault token.
    /// @param _cap The maximum total balance cap of the vault.
    /// @param _stargateLpStaking The contract to stake the Stargate LP token.
    /// @param _stargateLpToken The contract of the Stargate LP token.
    /// @param _stargateRouterPoolId The pool ID of the token for the Stargate router.
    /// @param _stargateLpStakingPoolId The pool ID of the token for Stargate staking.
    constructor(
        string memory _name,
        string memory _symbol,
        address _token,
        uint256 _cap,
        address _stargateLpStaking,
        address _stargateLpToken,
        uint8 _stargateRouterPoolId,
        uint8 _stargateLpStakingPoolId
    ) ERC20(_name, _symbol) {
        token = _token;
        cap = _cap;
        stargateLpStaking = IStargateLpStaking(_stargateLpStaking);
        stargateLpToken = _stargateLpToken;
        stargateRouterPoolId = _stargateRouterPoolId;
        stargateLpStakingPoolId = _stargateLpStakingPoolId;
        isEpochRunning = false;

        IGMXRouter(gmxRouter).approvePlugin(gmxPositionRouter);

        oracles[0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7] = 0x0A77230d17318075983913bC2145DB16C7366156;
        oracles[0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB] = 0x976B3D034E162d8bD72D6b9C989d545b839003b0;
        oracles[0x50b7545627a5162F82A992c33b87aDc75187B218] = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743;
        oracles[0x152b9d0FdC40C096757F570A51E494bd4b943E50] = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743;
    }

    /// @notice Deposit an amount in the contract.
    /// @param _amount The amount of {want} to deposit.
    function deposit(uint256 _amount) external {
        require(!isEpochRunning, "Disabled when during epoch");
        require(_amount + totalBalance() <= cap, "Cap reached");

        uint256 pool = totalBalance();
        IERC20(token).transferFrom(msg.sender, address(this), _amount);

        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = _amount * totalSupply() / pool;
        }

        _mint(msg.sender, shares);

        emit Deposit(msg.sender, _amount);
    }

    /// @notice Withdraws all the shares of the user.
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    /// @notice Withdraws the amount of {token} represented by the user's shares.
    /// @param _shares The amount of shares to withdraw.
    function withdraw(uint256 _shares) public {
        require(!isEpochRunning, "Disabled when during epoch");
        require(_shares <= balanceOf(msg.sender), "Not enough shares");

        uint256 returnAmount = totalBalance() * _shares / totalSupply();

        _burn(msg.sender, _shares);

        IERC20(token).transfer(msg.sender, returnAmount);

        emit Withdraw(msg.sender, returnAmount);
    }

    /// @notice Starts an epoch and allocates the funds to the lending platform and the trading manager.
    /// It blocks the deposits and withdrawals.
    function start() external onlyOwner {
        lastTotalBalance = totalBalance();
        lastPricePerShare = pricePerShare();

        uint256 lendingAmount = IERC20(token).balanceOf(address(this)) * SHARE_FOR_FARM / PERCENT;

        _stargateDeposit(lendingAmount);

        // Approve GMX for 20% of funds
        IERC20(token).approve(gmxRouter, IERC20(token).balanceOf(address(this)));

        isEpochRunning = true;

        emit Start(lastTotalBalance);
    }

    /// @notice Stops the epoch, withdraws funds from farm, unlocks deposits and withdrawals.
    function stop() external onlyOwner {
        require(currentOpenPositions == 0, "Close all positions on GMX");

        harvest(false);

        uint256 totalLpTokens = _getStargateLpBalance();
        stargateLpStaking.withdraw(stargateLpStakingPoolId, totalLpTokens);
        stargateRouter.instantRedeemLocal(stargateRouterPoolId, totalLpTokens, address(this));

        isEpochRunning = false;

        emit Stop(IERC20(token).balanceOf(address(this)));
    }

    /// @notice Harvests and sells the rewards of the lending farm.
    /// @param autocompound Boolean to indicate if it should auto-compound the rewards.
    function harvest(bool autocompound) public {
        require(isEpochRunning, "No funds in lending");

        // Putting 0 will harvest
        stargateLpStaking.deposit(stargateLpStakingPoolId, 0);

        uint256 stgBalance = IERC20(stgToken).balanceOf(address(this));
        IERC20(stgToken).approve(swapRouter, stgBalance);

        address[] memory path = new address[](3);
        path[0] = stgToken;
        path[1] = IJoeRouter02(swapRouter).WAVAX();
        path[2] = token;
        IJoeRouter02(swapRouter).swapExactTokensForTokens(stgBalance, 0, path, address(this), block.timestamp + 10);

        if (autocompound) {
            _stargateDeposit(IERC20(token).balanceOf(address(this)));
        }
    }

    function openPosition(address indexToken, uint256 tokenAmount, bool isLong) external payable onlyOwner {
        require(isEpochRunning, "Epoch not running");
        require(msg.value == 0.02 ether, "Wrong value");
        require(tokenAmount > 10 * 1e6, "Min amount not met");

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = indexToken;
        uint256 minOut = 0;
        uint256 positionSize = tokenAmount * 110 / 100 * 1e12; // 1.1x leverage
        (,int price,,,) = AggregatorV3Interface(oracles[indexToken]).latestRoundData();
        uint256 acceptablePrice = uint256(price) * 10030 / 10000 * 1e22; // GMX uses 30 bps tolerance
        uint256 executionFee = 20000000000000000;

        IGMXPositionRouter(gmxPositionRouter).createIncreasePosition{value: msg.value}(path, indexToken, tokenAmount, minOut, positionSize, isLong, acceptablePrice, executionFee, 0x0);

        currentOpenPositions += 1;
    }

    /// @notice Closes the GMX position for a token.
    /// @param indexToken The address of the token that is longed or shorted.
    /// @param isLong If we long or if we short.
    function closePosition(address indexToken, bool isLong) external payable onlyOwner {
        require(isEpochRunning, "Epoch not running");
        require(msg.value == 0.02 ether, "Wrong value");

        (uint256 sizeDelta,,,,,,,) = IGMXVault(gmxVault).getPosition(address(this), indexToken, indexToken, isLong);

        address[] memory path = new address[](2);
        path[0] = indexToken;
        path[1] = token;
        (,int price,,,) = AggregatorV3Interface(oracles[indexToken]).latestRoundData();
        uint256 acceptablePrice = uint256(price) * 9970 / 10000 * 1e22; // GMX uses 30 bps tolerance
        uint256 executionFee = 20000000000000000;

        IGMXPositionRouter(gmxPositionRouter).createDecreasePosition{value: msg.value}(path, indexToken, 0, sizeDelta, isLong, address(this), acceptablePrice, 0, executionFee, false);

        currentOpenPositions -= 1;
    }

    /// @notice Returns the total balance of {token} in strategy. When funds are allocated, it returns the last relevant balance.
    /// @return The total balance amount in {token}.
    function totalBalance() public view returns (uint256) {
        if (isEpochRunning) {
            return lastTotalBalance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /// @notice Returns the price of a single share. When funds are allocated, it returns the last relevant price.
    /// @return The price of a single share.
    function pricePerShare() public view returns (uint256) {
        if (isEpochRunning) {
            return lastPricePerShare;
        } else {
            return totalSupply() == 0 ? 1e18 : totalBalance() * 1e18 / totalSupply();
        }
    }

    /// @notice Deposits and stakes funds in Stargate.
    /// @param amount The amount of {token} to deposit.
    function _stargateDeposit(uint256 amount) internal {
        IERC20(token).approve(address(stargateRouter), amount);
        stargateRouter.addLiquidity(stargateRouterPoolId, amount, address(this));
        uint256 receivedLpToken = IERC20(stargateLpToken).balanceOf(address(this));
        IERC20(stargateLpToken).approve(address(stargateLpStaking), receivedLpToken);
        stargateLpStaking.deposit(stargateLpStakingPoolId, receivedLpToken);
    }

    /// @notice Returns the LP balance staked in Stargate.
    /// @return The LP amount staked.
    function _getStargateLpBalance() internal returns (uint256) {
        (uint256 amount, ) = stargateLpStaking.userInfo(stargateLpStakingPoolId, address(this));
        return amount;
    }

    /// @notice Updates the maximum total balance cap.
    /// @param _cap The new cap to apply.
    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

pragma solidity ^0.8.0;

interface IGMXRouter {
    function approvePlugin(address _plugin) external;
}

pragma solidity ^0.8.0;

interface IGMXPositionRouter {
    function createIncreasePosition(address[] memory _path, address _indexToken, uint256 _amountIn, uint256 _minOut, uint256 _sizeDelta, bool _isLong, uint256 _acceptablePrice, uint256 _executionFee, bytes32 _referralCode) external payable;
    function createDecreasePosition(address[] memory _path, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver, uint256 _acceptablePrice, uint256 _minOut, uint256 _executionFee, bool _withdrawETH) external payable;
}

pragma solidity ^0.8.0;

interface IGMXVault {
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external returns (uint256 size, uint256 collateral, uint256 averagePrice, uint256 entryFundingRate, uint256 reserveAmount, uint256 realisedPnl, bool realisedPnLPositive, uint256 lastIncreasedTime);
}

pragma solidity ^0.8.0;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 poolId, uint256 amount, address to) external;
    function instantRedeemLocal(uint16 poolId, uint256 amountLp, address to) external returns (uint256);
    function redeemLocal(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress, uint256 _amountLP, bytes calldata _to, lzTxObj memory _lzTxParams) external payable;
}

pragma solidity ^0.8.0;

interface IStargateLpStaking {
    function pendingStargate(uint256 pid, address user) external view returns (uint256);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 pid, uint256 amount) external;
    function userInfo(uint256 pid, address user) external returns (uint256, uint256);
    function poolInfo(uint256 poolId) external returns(address,  uint256, uint256, uint256);
}

pragma solidity ^0.8.0;

interface IStargatePool {
    function amountLPtoLD(uint256 _amountLP) external view returns (uint256);
    function deltaCredit() external returns (uint256);
    function totalLiquidity() external returns (uint256);
    function totalSupply() external returns (uint256);
}

pragma solidity ^0.8.0;

interface IJoeRouter02 {
    function WAVAX() external pure returns (address);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
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